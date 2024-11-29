extends Node

onready var viewport_container_3D = ViewportContainer3d
onready var viewport_3D = viewport_container_3D.get_node("Viewport3D")
onready var global_space = viewport_3D.get_node("Global_space")

onready var player: RigidBody = viewport_3D.get_node("Player")
onready var camera_rig = player.get_node("Camera_rig")
onready var camera = camera_rig.get_node("GameCamera")
