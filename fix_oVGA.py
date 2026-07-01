import sys

file_path = r'C:\Lab_project\VGA_Demo_restored\RTL\VGA\TOP_VGA_DEMO_KBD.bdf'

with open(file_path, 'r') as f:
    lines = f.readlines()

new_lines = []
skip_until = -1
for i, line in enumerate(lines):
    if i < skip_until:
        continue
    
    # Skip connector (pt -4200 600) (pt -4200 616) (bus)
    if i <= len(lines) - 5 and "(connector" in lines[i] and "(pt -4200 600)" in lines[i+1] and "(pt -4200 616)" in lines[i+2] and "(bus)" in lines[i+3]:
        skip_until = i + 5
        continue
    
    # Skip connector (pt -4104 600) (pt -4088 600)
    if i <= len(lines) - 4 and "(connector" in lines[i] and "(pt -4104 600)" in lines[i+1] and "(pt -4088 600)" in lines[i+2]:
        skip_until = i + 4
        continue
        
    # Skip connector (pt -4208 600) (pt -4200 600)
    if i <= len(lines) - 4 and "(connector" in lines[i] and "(pt -4208 600)" in lines[i+1] and "(pt -4200 600)" in lines[i+2]:
        skip_until = i + 4
        continue

    # Skip connector "startOfFrame" (pt -4104 600) (pt -4200 600) (bus)
    if i <= len(lines) - 6 and "(connector" in lines[i] and "startOfFrame" in lines[i+1] and "(pt -4104 600)" in lines[i+2] and "(pt -4200 600)" in lines[i+3] and "(bus)" in lines[i+4]:
        skip_until = i + 6
        continue
        
    # Skip junctions
    if "(junction (pt -4104 600))" in line or "(junction (pt -4200 600))" in line:
        continue

    new_lines.append(line)
    
new_lines.append("""(connector
	(text "startOfFrame" (rect -4198 584 -4135 601)(font "Intel Clear" ))
	(pt -4200 600)
	(pt -4208 600)
)
""")

new_lines.append("""(connector
	(text "OVGA[28..0]" (rect -4190 584 -4131 601)(font "Intel Clear" ))
	(pt -4120 600)
	(pt -4104 600)
	(bus)
)
""")

with open(file_path, 'w') as f:
    f.writelines(new_lines)

print("BDF successfully patched!")
