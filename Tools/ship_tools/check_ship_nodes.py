import subprocess
import os

script = '''extends SceneTree

func _init():
    var scene = load("res://Scenes/Ships/Phoenix_heavy.tscn")
    var instance = scene.instance()
    var model = instance.get_node("Models/Ship_model")
    print("=== Phoenix_heavy.tscn Ship_model child nodes ===")
    for i in range(model.get_child_count()):
        var child = model.get_child(i)
        var mo = child.material_override
        print("Child " + str(i) + ": \\"" + child.name + "\\" -> override: " + (mo.resource_path if mo else "NONE"))
    quit()
'''

worker_path = 'Tools/ship_tools/worker_check_nodes.gd'
with open(worker_path, 'w') as f:
    f.write(script)

subprocess.run(['godot', '-s', worker_path, '--no-window'], text=True)
if os.path.exists(worker_path):
    os.remove(worker_path)
