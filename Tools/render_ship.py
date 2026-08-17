import subprocess
import os

script_content = '''extends SceneTree

func _init():
    var viewport = Viewport.new()
    viewport.size = Vector2(1280, 960)
    viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
    viewport.render_target_v_flip = true
    root.add_child(viewport)
    
    # Load Environment for proper tonemapping and ambient levels
    var env_node = WorldEnvironment.new()
    var env_res = load("res://Assets/Environments/Environment_default.tres")
    env_node.environment = env_res
    viewport.add_child(env_node)
    
    # Instance ship scene
    var scene = load("res://Scenes/Ships/Phoenix_heavy.tscn").instance()
    scene.visible = true
    scene.get_node("Models/Ship_model").visible = true
    viewport.add_child(scene)
    
    # Use the ship scene's own DirectionalLight
    var ship_light = scene.get_node_or_null("DirectionalLight")
    if ship_light:
        ship_light.editor_only = false
        ship_light.visible = true
    else:
        var dlight = DirectionalLight.new()
        dlight.light_energy = 1.0
        dlight.transform = Transform(Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(0, -1, 0), Vector3(0, 50, 0))
        viewport.add_child(dlight)
    
    var cam = Camera.new()
    cam.current = true
    cam.far = 1000.0
    viewport.add_child(cam)
    
    var shots = [
        {
            "name": "Tools/renders/ship_front_34.png",
            "cam_pos": Vector3(35, 18, -45),
            "look_at": Vector3(0, 0, -15),
            "up": Vector3(0, 1, 0)
        },
        {
            "name": "Tools/renders/ship_rear_34.png",
            "cam_pos": Vector3(35, 18, 45),
            "look_at": Vector3(0, 0, 15),
            "up": Vector3(0, 1, 0)
        },
        {
            "name": "Tools/renders/ship_top.png",
            "cam_pos": Vector3(0, 65, 0),
            "look_at": Vector3(0, 0, 0),
            "up": Vector3(0, 0, -1)
        },
        {
            "name": "Tools/renders/ship_bottom.png",
            "cam_pos": Vector3(0, -65, 0),
            "look_at": Vector3(0, 0, 0),
            "up": Vector3(0, 0, 1)
        },
        {
            "name": "Tools/renders/ship_side.png",
            "cam_pos": Vector3(50, 5, 0),
            "look_at": Vector3(0, 0, 0),
            "up": Vector3(0, 1, 0)
        },
        {
            "name": "Tools/renders/ship_angle_top.png",
            "cam_pos": Vector3(35, 25, 20),
            "look_at": Vector3(0, 0, 0),
            "up": Vector3(0, 1, 0)
        },
        {
            "name": "Tools/renders/ship_angle_bottom.png",
            "cam_pos": Vector3(35, -25, 20),
            "look_at": Vector3(0, 0, 0),
            "up": Vector3(0, 1, 0)
        }
    ]
    
    for shot in shots:
        cam.transform.origin = shot["cam_pos"]
        cam.look_at(shot["look_at"], shot["up"])
        
        for i in range(4):
            yield(self, "idle_frame")
            
        var tex = viewport.get_texture()
        var img = tex.get_data()
        img.save_png(shot["name"])
        print("Saved: " + shot["name"])
        
    quit()
'''

worker_file = 'Tools/ship_tools/render_worker.gd'
with open(worker_file, 'w') as f:
    f.write(script_content)

subprocess.run(['godot', '-s', worker_file, '--no-window'], capture_output=True, text=True)
if os.path.exists(worker_file):
    os.remove(worker_file)
print("Ship renders successfully updated using scene environment and lighting.")
