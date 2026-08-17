import sys

file_path = 'Scenes/Ships/Phoenix_heavy.tscn'

with open(file_path, 'r') as f:
    lines = f.readlines()

total = len(lines)
print(f"Total lines in {file_path}: {total}")

count = 60
if len(sys.argv) > 1:
    try:
        count = int(sys.argv[1])
    except ValueError:
        pass

print(f"=== Last {count} lines ===")
for i, line in enumerate(lines[-count:]):
    print(f"{total - count + i + 1}: {line}", end="")
