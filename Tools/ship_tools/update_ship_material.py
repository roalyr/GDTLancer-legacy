import sys
import re

file_path = 'Scenes/Ships/Phoenix_heavy.tscn'

def update_node_material(node_name, ext_resource_id):
    with open(file_path, 'r') as f:
        content = f.read()

    pattern = rf'(\[node name="{re.escape(node_name)}"[^\]]*\][\s\S]*?material_override = )ExtResource\( \d+ \)'
    match = re.search(pattern, content)
    if match:
        print(f"Found node '{node_name}':\n{match.group(0)}")
        new_content = re.sub(pattern, rf'\g<1>ExtResource( {ext_resource_id} )', content)
        with open(file_path, 'w') as f:
            f.write(new_content)
        print(f"Updated '{node_name}' to ExtResource( {ext_resource_id} ) successfully.")
    else:
        print(f"Node '{node_name}' with material_override not found in {file_path}")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python3 update_ship_material.py <node_name> <ext_resource_id>")
        print("Example: python3 update_ship_material.py \"hull compartments front\" 4")
    else:
        update_node_material(sys.argv[1], int(sys.argv[2]))
