extends Node

var mouse_flight = false
var turret_mode = false

var thrust = 0
var accel_ticks = 0
var ship_linear_velocity = 0

var aim_target = Position3D
var aim_target_locked = false

var autopilot_target = Position3D
var autopilot_target_locked = false
var autopilot = false

var velocity_limiter = 0
