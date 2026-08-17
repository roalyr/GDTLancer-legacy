import subprocess
import os

script = '''extends SceneTree

func _init():
    var scene = load("res://Scenes/Ships/Phoenix_heavy.tscn")
    var instance = scene.instance()
    print("=== Nodes in Phoenix_heavy.tscn ===")
    print_tree(instance, "")
    quit()

func print_tree(node, indent):
    var mat_info = ""
    if node is MeshInstance:
        var mo = node.material_override
        var m0 = node.get_surface_material(0)
        mat_info = " [MeshInstance: override=" + str(mo.resource_path if mo else "null") + ", mat0=" + str(m0.resource_path if m0 else "null") + "]"
    print(indent + "- " + node.name + " (" + node.get_class() + ")" + mat_info)
    for child in node.get_children():
        print_tree(child, indent + "  ")
'''

worker_path = 'Tools/ship_tools/worker_inspect_scene.gd'
with open(worker_path, 'w') as f:
    f.write(script)

subprocess.run(['godot', '-s', worker_path, '--no-window'], text=True)
if os.path.exists(worker_path):
    os.remove(worker_path)
