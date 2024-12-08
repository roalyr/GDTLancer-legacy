extends Node

# PROJECT NAME
const game_name = "GDTLancer"
const version = "v0.10-alpha"

var system_time = Time.get_date_dict_from_system()
var project_name = game_name + "-"  \
	+ version + "-" \
	+ str(system_time["year"]) + "." \
	+ str(system_time["month"]) + "." \
	+ str(system_time["day"])

# CONSTANTS
const physics_fps = 120
const graphic_fps = 60

# Space damp values.
const global_linear_damp = 1.2
const global_angular_damp = 5

# Map limiter (boundary to prevent player from flying away too much).
const boundary_force_strength = 1e10
const boundary_max_distance = 3e5
const boundary_soft_margin = 1e4

# Ship
const velocity_limiter_states = 3

# Other
# TODO: revivew what goes where.
const maximum_systems_spawned_on_visiting = 3

# CONSTANTS
const camera_far = 1e6 #
const camera_near = 1.0 # 
const camera_fov = 60 # Value at zero velocity
const camera_fov_max = 90 # Hard limit
const camera_fov_velocity_factor = 0.5

const camera_turret_roll_vert_limit = 70 # Deg +\-
# Zoom out times is multiplied by minimum ship camera distance to define maximum.
# Sync with touchscreen control slider (max_val = camera_zoom_out_times/camera_zoom_step).
const camera_zoom_ticks_max = 100
#const camera_zoom_out_max = 1e3 # For sandnbox mode
const camera_zoom_step = 1 # 0.05 ... 0.2



func _ready():
	print(project_name)
	#ProjectSettings.set_setting('application/config/name', project_name)
