import subprocess
import os

script = '''extends SceneTree

func _init():
    var scene = load("res://Scenes/Environment/Global_space.tscn")
    var instance = scene.instance()
    print("=== Nodes in Global_space.tscn ===")
    print_tree(instance, "")
    quit()

func print_tree(node, indent):
    var extra = ""
    if node is DirectionalLight:
        extra = " [energy=" + str(node.light_energy) + ", color=" + str(node.light_color) + ", transform=" + str(node.transform) + "]"
    elif node is WorldEnvironment:
        extra = " [env=" + str(node.environment.resource_path if node.environment else "null") + "]"
    elif node is Camera:
        extra = " [fov=" + str(node.fov) + ", far=" + str(node.far) + "]"
    print(indent + "- " + node.name + " (" + node.get_class() + ")" + extra)
    for child in node.get_children():
        print_tree(child, indent + "  ")
'''

worker_path = 'Tools/ship_tools/worker_inspect_env.gd'
with open(worker_path, 'w') as f:
    f.write(script)

subprocess.run(['godot', '-s', worker_path, '--no-window'], text=True)
if os.path.exists(worker_path):
    os.remove(worker_path)
