extends Spatial

#TODO: make this scene instance to any object that is focused on in game.

# Higher damp value - more restricted camera motion in given direction.
const camera_chase_tilt_horiz_damp_up = 6 # Can't be zero
const camera_chase_tilt_horiz_damp_down = 1.8 # Can't be zero
const camera_chase_tilt_vert_damp_left = 2 # Can't be zero
const camera_chase_tilt_vert_damp_right = 2 # Can't be zero
const camera_inertial_movement_threshold_low = 1e-3
# Higher values - more responsive camera.
const camera_tilt_velocity_factor = 1
const camera_push_velocity_factor = 2.0 # Small ship - 2.5
const camera_push_max_factor = 1700.0 # Small ship - 1000
const camera_push_velocity_power = 3.0
const camera_push_visibility_velocity = 1e8
# Do not edit, this compensates for near plane offset and prevents flickering.
const camera_z_near_velocity_factor = 1e-5
# Those numbers are made to create a warp effect.
const camera_fov_velocity_factor = 1e-4
const camera_fov_derivative = 2
const camera_fov_max_delta = 140 - Constants.camera_fov
const camera_brightness_velocity_factor = 2e-4
const camera_brightness_derivative = 0.1
const camera_brightness_max_delta = 1.2
# TODO: adjust background colors separatenly?

# Values.
var camera_min_zoom = 0
var camera_max_zoom = 0
var current_zoom = 0
var current_zoom_extra = 0
var camera_vert = 0
var camera_horiz = 0
var zoom_ticks = 0
var camera_push_z = 0
var camera_push_y = 0
# Chase camera positions.
var vert = 0
var horiz = 0
# Camera velocity-related effects.
var init_push = Vector2(0.0, 0.0)
var init_fov = Vector2(0.0, 0.0)
var init_brightness = Vector2(0.0, 0.0)
var init_near = Vector2(0.0, 0.0)
# Objects.
var camera_vector = Vector2(0,0)
var control_held = false

func _ready():
	# ============================ Connect signals ============================
	Signals.connect_checked("sig_turret_mode_on", self, "is_turret_mode_on")
	Signals.connect_checked("sig_zoom_value_changed", self, "is_zoom_value_changed")
	# =========================================================================
	
	# Init
	reset_camera_zoom()
	reset_chase_camera()
	
func _physics_process(_delta):
	# Common camera behavior, independent from the camera mode.
	camera_common_behavior()
	
	# Due to difference in handling LMB and stick actuation, check those separately for
	# different game modes. Needed for detection camera orbiting.
	if not GameState.touchscreen_mode and GlobalInput.LMB_held:
		control_held = true
	elif GameState.touchscreen_mode and GlobalInput.stick_held:
		control_held = true
	else: 
		control_held = false
	
	# ORBIT CAMERA
	# Track the change in camera mode and update mouse vector when controls are held.
	# When the control is released proceed with a little of inertia for smoothness.
	if PlayerState.turret_mode and (control_held or PlayerState.mouse_flight):
		camera_vector = GlobalInput.mouse_vector
		orbit_camera(camera_vector)
	elif PlayerState.turret_mode and (not control_held or not PlayerState.mouse_flight):
		# Small inertia camera movement after releasing the controls.
		if abs(camera_vector.x) > camera_inertial_movement_threshold_low:
			camera_vector /= GameOptions.camera_inertia_factor
			orbit_camera(camera_vector)
	
	# CHASE CAMERA
	if not PlayerState.turret_mode and (control_held or PlayerState.mouse_flight):
		camera_vector = GlobalInput.mouse_vector
		chase_camera(camera_vector)
	# Return to initial position and update camera based on velocity only.
	elif not PlayerState.turret_mode and not (control_held or PlayerState.mouse_flight):
		camera_vector = Vector2(0,0)
		chase_camera(camera_vector)
	
# ================================== Other ====================================
func orbit_camera(mv):
	# Compensate camera roll speed by camera altitude.
	var phi = abs(cos(self.rotation.x))
	var roll_vert = -mv.y * GameOptions.camera_sensitivity
	var roll_horiz = -mv.x * GameOptions.camera_sensitivity*phi
	camera_vert = self.rotation_degrees.x
	camera_horiz = self.rotation_degrees.y
	if camera_vert + roll_vert >= Constants.camera_turret_roll_vert_limit:
		self.rotation_degrees.x = Constants.camera_turret_roll_vert_limit
	elif camera_vert + roll_vert <= -Constants.camera_turret_roll_vert_limit:
		self.rotation_degrees.x = -Constants.camera_turret_roll_vert_limit
	else:
		self.rotate_object_local(Vector3(1,0,0), deg2rad(roll_vert))
	self.rotate_object_local(Vector3(0,1,0), deg2rad(roll_horiz))
	self.rotation.z = 0
	

func chase_camera(mv):
	# Calculating camera tilt amount.
	# $GameCamera.rotation.x - vertical, $GameCamera.rotation.y - horizontal
	# UP - DOWN
	if mv.y < 0:
		vert = -mv.y*cos($GameCamera.rotation.x)/(camera_chase_tilt_horiz_damp_up)
	else:
		vert = -mv.y*cos($GameCamera.rotation.x)/(camera_chase_tilt_horiz_damp_down)
	
	# LEFT - RIGHT
	if mv.x < 0:
		horiz = -mv.x*cos($GameCamera.rotation.y)/(camera_chase_tilt_vert_damp_left)
	else:
		horiz = -mv.x*cos($GameCamera.rotation.y)/(camera_chase_tilt_vert_damp_right)
	
	# Initial and final camera modifier values.
	var init_tilt = Vector2($GameCamera.rotation.x, $GameCamera.rotation.y)
	var fin_tilt = Vector2(vert, horiz)
	# Temporary interpolated values.
	var tmp_tilt = init_tilt.linear_interpolate(fin_tilt, 
		get_physics_process_delta_time() * camera_tilt_velocity_factor)
	
	# Tilt motion in chase camera.
	$GameCamera.rotation.x = tmp_tilt.x
	$GameCamera.rotation.y = tmp_tilt.y
	self.rotation.x = -tmp_tilt.x
	self.rotation.y = -tmp_tilt.y

	
func camera_common_behavior():
	# Common behavior for different camera modes.
	# Final interpolation values.
	var fin_push = Vector2(PlayerState.ship_linear_velocity, 0.0)
	var fin_fov = Vector2(PlayerState.ship_linear_velocity, 0.0)
	var fin_brightness = Vector2(PlayerState.ship_linear_velocity, 0.0)
	# Intermediate interpolation values.
	var tmp_push = init_push.linear_interpolate(fin_push, 
		pow(get_physics_process_delta_time() * camera_push_velocity_factor, camera_push_velocity_power))
	var tmp_fov = init_fov.linear_interpolate(fin_fov, 
		get_physics_process_delta_time() * camera_fov_velocity_factor)
	var tmp_brightness = init_brightness.linear_interpolate(fin_brightness, 
		get_physics_process_delta_time() * camera_brightness_velocity_factor)
	# Needed to prevent artifacts.
	
	# Prevent camera from sliding forward.
	tmp_push.x = camera_min_zoom + tmp_push.x
	
	# Vertical camera push to hide the jitter from the engine trail.
	# Normalize value here and add it to default offset at 0 speed.
	camera_push_y = Paths.player.camera_vert_offset \
		+ clamp(3*log(tmp_push.x/camera_min_zoom), 
			1e-6, camera_push_max_factor)
	
	# Vertical push to hide overall jittering model.
	camera_push_z = clamp(tmp_push.x, 1e-6, camera_push_max_factor)
	
	# Camera rolling back and down.
	if PlayerState.turret_mode:
		$GameCamera.translation.z = camera_push_z + current_zoom_extra
		$GameCamera.translation.y = 0
	else:
		$GameCamera.translation.z = camera_push_z
		$GameCamera.translation.y = camera_push_y
	
	
	# This simulates warp effect and hides Paths.player model.
	$GameCamera.fov = Constants.camera_fov \
		+ clamp(camera_fov_derivative*log(tmp_fov.x), 1e-6, camera_fov_max_delta)
	
	# Brightness adjustment for velocity.
	Paths.environment.warp_brightness_variation = clamp(
		camera_brightness_derivative*log(tmp_brightness.x), 
		1e-6, 
		camera_brightness_max_delta)
	




# Initial position for turret camera
func reset_orbit_camera():
	$GameCamera.translation.y = 0
	$GameCamera.translation.z = camera_min_zoom
	zoom_ticks = 0
	current_zoom = camera_min_zoom
	current_zoom_extra = 0

# Initial position for chase camera
func reset_chase_camera():
	self.rotation_degrees.x = 0
	self.rotation_degrees.y = 0
	self.rotation_degrees.z = 0
	$GameCamera.rotation_degrees.x = 0
	$GameCamera.rotation_degrees.y = 0
	$GameCamera.rotation_degrees.z = 0
	$GameCamera.translation.y = Paths.player.camera_vert_offset
	$GameCamera.translation.z = camera_min_zoom
	zoom_ticks = 0
	current_zoom = camera_min_zoom
	current_zoom_extra = 0
	
func zoom_camera(mouse_event):
	if mouse_event.is_pressed():
#		var delta = get_physics_process_delta_time()
		#print(camera_min_zoom," | ",  current_zoom, " | ", camera_max_zoom)
		if mouse_event.button_index == BUTTON_WHEEL_UP and zoom_ticks < Constants.camera_zoom_ticks_max:
			zoom_ticks += 1
			current_zoom_extra = get_extra_zoom(zoom_ticks)
			
		elif mouse_event.button_index == BUTTON_WHEEL_DOWN and zoom_ticks > 0:
			zoom_ticks -= 1
			current_zoom_extra = get_extra_zoom(zoom_ticks)

func get_extra_zoom(zoom_ticks_extra):
	return Constants.camera_zoom_step*pow(zoom_ticks_extra, 2)

func reset_camera_zoom():
	camera_min_zoom = max(0.1, Paths.player.camera_horiz_offset)
	camera_max_zoom = camera_min_zoom \
					* Constants.camera_zoom_ticks_max \
					* Constants.camera_zoom_step
	current_zoom = camera_min_zoom
	current_zoom_extra = 0
	zoom_ticks = 0
	
# SIGNAL PROCESSING
func is_turret_mode_on(flag):
	if flag:
		# Reset camera first.
		reset_chase_camera()
		reset_orbit_camera()
	else:
		reset_chase_camera()

# Connect with GUI slider or control.
func is_zoom_value_changed(value):
	# print(camera_min_zoom," | ",  current_zoom, " | ", camera_max_zoom)
	zoom_ticks = value
	if zoom_ticks > Constants.camera_zoom_ticks_max:
		zoom_ticks = Constants.camera_zoom_ticks_max
	current_zoom_extra = get_extra_zoom(zoom_ticks)


func is_fov_value_changed(value):
	$GameCamera.fov = value
