extends RigidBody

onready var ui = get_node("/root/Main/UI")


# rate of change of acceleration.
const accel_damp_factor = 0.3

var velocity_limiter_state = 0
const velocity_limmiter_1 = 1e2
const velocity_limmiter_2 = 1e5
const velocity_limmiter_3 = 1e10
const velocity_limmiter_4 = 1e17


const accel_max = 1e23

const engine_delay_time_base = 0.05
# const engine_delay_lag_factor = 1

var engine_delay_timer = 0
var engine_delay_time = 0.1

const tick_step = 1

# Allowed angle deviation for autopilot to engage.
const autopilot_angle_deviation = 0.8

# Lesser is more precise, aim at ration 1:2 for decel being larger
# Higher numbers mean more agressive AP velocity handling.
const autopilot_accel_factor = 0.2 # 0.22
const autopilot_deccel_factor = 0.4 # 0.44

# Orbiting factor allows to approach not at a straight line, but slightly orbiting.
var autopilot_orbiting_factor = 0.0

# Vars.
# Ship data to be loaded,
var ship_mass = 0
var idle_engine_ticks = 0
var torque_factor = Vector3(0,0,0)
var autopilot_torque_factor = 0
var camera_vert_offset = 0.0
var camera_horiz_offset = 0.0
var exhaust_shape_size_xy_max = 0
var current_ship = Node

var default_linear_damp = 0
var tx = 0
var ty = 0
var tz = 0
var engine_delay = false

var target_origin = Vector3(0,0,0)
var autopilot_range = 0

var dist_val = 0
var steering_vector = Vector3(0,0,0)
var control_held = false

# Objects.
var torque = Vector3(0,0,0)

# Load ship scenes.
# Camera ship as default.
onready var player_camera_ship = load("res://Scenes/Ships/Player_camera.tscn")
# Load other ships.
onready var ship_phoenix_heavy = load("res://Scenes/Ships/Phoenix_heavy.tscn")




# Called when the node enters the scene tree for the first time.
func _ready():
	# ============================= Connect signals ===========================
	Signals.connect_checked("sig_accelerate", self, "is_accelerating")
	Signals.connect_checked("sig_engine_kill", self, "is_engine_kill")
	Signals.connect_checked("sig_autopilot_start", self, "is_autopilot_start")
	Signals.connect_checked("sig_autopilot_disable", self, "is_autopilot_disable")
	Signals.connect_checked("sig_target_autopilot_locked", self, "is_target_autopilot_locked")
	Signals.connect_checked("sig_velocity_limiter_set", self, "is_velocity_limiter_set")
	# =========================================================================
	
	# Initialize the vessel params.
	# First initialize the camera "ship".
	init_specific_ship(player_camera_ship.instance())
	init_specific_ship(ship_phoenix_heavy.instance())
	


func _integrate_forces(state):
	
	# TODO: arrange for proper signs for accel and torque.
	var vel = state.linear_velocity.length()
	PlayerState.ship_linear_velocity = vel
	
	state.add_central_force(-global_transform.basis.z * PlayerState.acceleration)


	# AUTOPILOT
	
	# Coordinates must be within physics process because they are updating.
	if PlayerState.autopilot_target_locked:
		# Fail-safety
		if PlayerState.autopilot_target.is_class("GDScriptNativeClass"):
			return
		target_origin = PlayerState.autopilot_target.global_transform.origin
		autopilot_range = PlayerState.autopilot_target.autopilot_range

	
	# Acceleration control.
	if PlayerState.autopilot:

		var ship_origin = self.global_transform.origin
		dist_val = round(ship_origin.distance_to(target_origin))
		var ship_forward = -self.global_transform.basis.z
		var dir_vector = ship_origin.direction_to(target_origin)
		var dot_product = ship_forward.dot(dir_vector)

		steering_vector = ship_forward.cross(dir_vector)
		
		if (vel < dist_val*autopilot_accel_factor) and (dot_product > autopilot_angle_deviation)\
			and (dist_val > autopilot_range):
			is_accelerating(true)
		elif (vel > dist_val*autopilot_deccel_factor) or (dot_product < autopilot_angle_deviation)\
			or (dist_val < autopilot_range): 
			is_accelerating(false)
	
	if PlayerState.autopilot and dist_val < autopilot_range:
		Signals.emit_signal("sig_autopilot_disable")
		
	
	
	# Steering.
	var autopilot_factor_x = clamp(autopilot_torque_factor*steering_vector.x+autopilot_orbiting_factor, -1.0, 1.0)
	var autopilot_factor_y = clamp(autopilot_torque_factor*steering_vector.y+autopilot_orbiting_factor, -1.0, 1.0)
	var autopilot_factor_z = clamp(autopilot_torque_factor*steering_vector.z+autopilot_orbiting_factor, -1.0, 1.0)

	
	# Due to difference in handling LMB and stick actuation, check those separately for
	# different game modes.
	if not GameState.touchscreen_mode and GlobalInput.LMB_held:
		control_held = true
	elif GameState.touchscreen_mode and GlobalInput.stick_held:
		control_held = true
	else: 
		control_held = false
	
	# If AP is on, controls are not engaged, but allow camera orbit.
	if PlayerState.autopilot and \
		((not PlayerState.turret_mode and not (control_held or PlayerState.mouse_flight)) \
		or PlayerState.turret_mode):

		# Fix directions being flipped

		tx = self.torque_factor.x* autopilot_factor_x
		ty = self.torque_factor.y* autopilot_factor_y
		tz = self.torque_factor.z* autopilot_factor_z

		state.add_torque(Vector3(tx, ty, tz))
	
	
	
	
	
	# AUTOPILOT




	
	if not PlayerState.turret_mode and (control_held or PlayerState.mouse_flight):

		tx = -transform.basis.y*self.torque_factor.x* GlobalInput.mouse_vector.x
		ty = -transform.basis.x*self.torque_factor.y* GlobalInput.mouse_vector.y
		
		state.add_torque(tx+ty)
	



	# DAMPING

	var damp_linear = 1.0 - state.step * Constants.global_linear_damp

	if (damp_linear < 0):
		damp_linear = 0


	var damp_angular = 1.0 - state.step * Constants.global_angular_damp 

	if (damp_angular < 0):
		damp_angular = 0
	
	state.linear_velocity *= damp_linear
	state.angular_velocity *= damp_angular



# ================================== Other ====================================
# TODO: Split it off to self's specific properties later on.
func init_specific_ship(ship_ref):
	# Remove previously existing collision bodies and package.
	clear_previous_data()
	# Load ship data.
	current_ship = ship_ref.duplicate()
	ship_mass = current_ship.get_node("Ship_data").ship_mass
	idle_engine_ticks = current_ship.get_node("Ship_data").idle_engine_ticks
	torque_factor = current_ship.get_node("Ship_data").torque_factor
	autopilot_torque_factor = current_ship.get_node("Ship_data").autopilot_torque_factor
	camera_vert_offset = current_ship.get_node("Ship_data").camera_vert_offset
	camera_horiz_offset = current_ship.get_node("Ship_data").camera_horiz_offset
	exhaust_shape_size_xy_max = current_ship.get_node("Ship_data").exhaust_shape_size_xy_max
	autopilot_orbiting_factor = current_ship.get_node("Ship_data").autopilot_orbiting_factor
	# Add the ship to scene.
	self.add_child(current_ship)
	
	# Add collisions.
	# TODO: When switching to another ship - clear all collision shapes first.
	for shape in current_ship.get_node("Collision_shapes").get_children():
		self.add_child(shape.duplicate())
	
	
	# Reset camera offsets.
	get_node("Camera_rig").reset_camera_zoom()
	
	# Init the rigid body.
	init_ship()
	

func clear_previous_data():
	for child in self.get_children():
		if child.is_class("CollisionShape"):
			child.queue_free()

		if child.has_method("is_ship_package"):
			child.queue_free()

func init_ship():

	self.continuous_cd = true
	self.custom_integrator = true
	self.can_sleep = false
	self.mass = self.ship_mass
	PlayerState.acceleration = 0
	PlayerState.accel_ticks = idle_engine_ticks
	adjust_exhaust()


func adjust_exhaust():
	
	var accel_val = 100
	var engines = current_ship.get_node("Engines")
	for i in engines.get_children():
		
		var albedo = accel_val

		# Adjust light intensity
		if PlayerState.acceleration > 0:
			i.get_node("Engine_exhaust_shapes").scale.z = accel_val
			i.get_node("Engine_exhaust_shapes").scale.x = accel_val*1e-1
			i.get_node("Engine_exhaust_shapes").scale.y = accel_val*1e-1
			if i.get_node("Engine_exhaust_shapes").scale.x >= exhaust_shape_size_xy_max:
				i.get_node("Engine_exhaust_shapes").scale.x = exhaust_shape_size_xy_max
				i.get_node("Engine_exhaust_shapes").scale.y = exhaust_shape_size_xy_max
			albedo = accel_val
		else:
			i.get_node("Engine_exhaust_shapes").scale.z = 0
			albedo = 0
			
			
		# Get and modify sprite intensity.
		var shapes = i.get_node("Engine_exhaust_shapes")
		for shape in shapes.get_children():
			var m = shape.get_child(0).get_surface_material(0)
			
			m["shader_param/albedo"].r = clamp(albedo*0.4, 1e-6, 0.6)
			m["shader_param/albedo"].g = clamp(albedo*0.1, 1e-6, 0.2)
			m["shader_param/albedo"].b = clamp(albedo*0.05, 1e-6, 0.8)
		
				# Get and modify sprite intensity.
		shapes = i.get_node("Engine_static_shapes")
		for shape in shapes.get_children():
			var m = shape.get_child(0).get_surface_material(0)
			
			m["shader_param/albedo"].r = clamp(albedo*0.4, 1e-6, 0.6)
			m["shader_param/albedo"].g = clamp(albedo*0.1, 1e-6, 0.2)
			m["shader_param/albedo"].b = clamp(albedo*0.05, 1e-6, 0.8)

func is_accelerating(accelerating):

	if accelerating:
			
		PlayerState.acceleration = 9e9
			
	
	else:
		
		PlayerState.acceleration = 0
	
	# Adjust visuals.
	adjust_exhaust()


func is_engine_kill():
	PlayerState.acceleration = 0
	PlayerState.accel_ticks = idle_engine_ticks
	adjust_exhaust()
		
func is_target_autopilot_locked(target):
	PlayerState.autopilot_target = target
	PlayerState.autopilot_target_locked = true
	
func is_autopilot_start():
	PlayerState.autopilot = true
	# Slightly randomize spinning when on autopilot.
	autopilot_orbiting_factor *= sign(rand_range(-1,1))

func is_autopilot_disable():
	is_engine_kill()
	PlayerState.autopilot = false

func is_velocity_limiter_set(value):
	velocity_limiter_state = value
