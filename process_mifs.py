from PIL import Image, ImageDraw, ImageFont
import os
import random

def image_to_mif(img_path, mif_path, width=32, height=32, transparent_color=(0,0,0)):
    try:
        img = Image.open(img_path).convert('RGB')
    except Exception as e:
        print(f"Error loading {img_path}: {e}")
        return
    img = img.resize((width, height), Image.NEAREST)
    
    with open(mif_path, 'w') as f:
        f.write(f"DEPTH = {width * height};\n")
        f.write("WIDTH = 8;\n")
        f.write("ADDRESS_RADIX = DEC;\n")
        f.write("DATA_RADIX = HEX;\n")
        f.write("CONTENT\nBEGIN\n")
        
        for y in range(height):
            for x in range(width):
                r, g, b = img.getpixel((x, y))
                
                # Check for transparency
                if (r,g,b) == transparent_color or (r < 10 and g < 10 and b < 10):
                    hex_val = "FF"
                else:
                    # Convert to 3-bit R, 3-bit G, 2-bit B
                    r3 = (r * 7) // 255
                    g3 = (g * 7) // 255
                    b2 = (b * 3) // 255
                    
                    val = (r3 << 5) | (g3 << 2) | b2
                    hex_val = f"{val:02X}"
                
                addr = y * width + x
                f.write(f"{addr} : {hex_val};\n")
        f.write("END;\n")

# Process Slowdown and Bomb icons
image_to_mif("C:\\Users\\נמרוד אלוש\\.gemini\\antigravity\\brain\\04961d19-aecd-4ed9-86da-ebc58777ed70\\icon_slowdown_1782750490465.png", 
             "C:\\Lab_project\\VGA_Demo_restored\\MIF\\icon_slowdown_32x32.mif")
image_to_mif("C:\\Users\\נמרוד אלוש\\.gemini\\antigravity\\brain\\04961d19-aecd-4ed9-86da-ebc58777ed70\\icon_bomb_1782750501562.png", 
             "C:\\Lab_project\\VGA_Demo_restored\\MIF\\icon_bomb_32x32.mif")

# Fix Speed icon
def fix_speed_icon():
    mif_path = "C:\\Lab_project\\VGA_Demo_restored\\MIF\\icon_speed_32x32.mif"
    with open(mif_path, 'r') as f:
        content = f.read()
    # Replace black background (00) with FF
    # The content is usually lines like "addr : 00;"
    import re
    new_content = re.sub(r': 00;', r': FF;', content)
    with open(mif_path, 'w') as f:
        f.write(new_content)

fix_speed_icon()

print("Icons processed!")

# Create levels.mif
def random_scale():
    r = random.random()
    if r < 0.6: return 0 # 60% Small
    elif r < 0.9: return 1 # 30% Medium
    else: return 2 # 10% Large

def create_levels():
    mif_path = "C:\\Lab_project\\VGA_Demo_restored\\MIF\\levels.mif"
    
    # Types: 1=Cop, 2=Robber, 3=Maryjane, 4=Riddler, 5=Goblin
    # Bit 5 = active (32), Bits 4:3 = scale (0,1,2 * 8), Bits 2:0 = type
    
    levels = []
    
    for lvl in range(1, 16):
        level_objects = []
        if lvl == 5:
            # Level 5: 1 Goblin, 5 Maryjanes, 9 Robbers
            level_objects.append(32 | (0<<3) | 5) # Goblin
            for _ in range(5): level_objects.append(32 | (0<<3) | 3) # Maryjane
            for _ in range(9): level_objects.append(32 | (random_scale()<<3) | 2) # Robber
        elif lvl == 10:
            # Level 10: 2 Goblins, 5 Maryjanes, 8 Robbers
            level_objects.append(32 | (0<<3) | 5)
            level_objects.append(32 | (0<<3) | 5)
            for _ in range(5): level_objects.append(32 | (0<<3) | 3)
            for _ in range(8): level_objects.append(32 | (random_scale()<<3) | 2)
        elif lvl == 15:
            # Level 15: 1 Goblin, 7 Riddlers, 7 Maryjanes
            level_objects.append(32 | (0<<3) | 5)
            for _ in range(7): level_objects.append(32 | (0<<3) | 4)
            for _ in range(7): level_objects.append(32 | (0<<3) | 3)
        else:
            # Normal levels
            num_cops = random.randint(1, 3)
            num_maryjanes = random.randint(3, 6)
            
            has_riddler = 1 if lvl >= 3 else 0
            
            num_robbers = 15 - num_cops - num_maryjanes - has_riddler
            
            if has_riddler:
                level_objects.append(32 | (0<<3) | 4)
            for _ in range(num_cops): level_objects.append(32 | (random_scale()<<3) | 1)
            for _ in range(num_maryjanes): level_objects.append(32 | (0<<3) | 3)
            for _ in range(num_robbers): level_objects.append(32 | (random_scale()<<3) | 2)
            
            random.shuffle(level_objects)
        
        # Pad to 16
        while len(level_objects) < 16:
            level_objects.append(0)
            
        levels.extend(level_objects)
        
    # Pad up to 256
    while len(levels) < 256:
        levels.append(0)
        
    with open(mif_path, 'w') as f:
        f.write(f"DEPTH = 256;\n")
        f.write("WIDTH = 8;\n")
        f.write("ADDRESS_RADIX = DEC;\n")
        f.write("DATA_RADIX = HEX;\n")
        f.write("CONTENT\nBEGIN\n")
        for i, val in enumerate(levels):
            f.write(f"{i:04d} : {val:02X};\n")
        f.write("END;\n")

create_levels()
print("levels.mif generated!")

# Generate instructions_bg.mif
def create_instructions():
    img = Image.new('RGB', (320, 240), color=(30, 30, 40))
    d = ImageDraw.Draw(img)
    
    try:
        font_title = ImageFont.truetype("arial.ttf", 20)
        font_text = ImageFont.truetype("arial.ttf", 10)
    except:
        font_title = ImageFont.load_default()
        font_text = ImageFont.load_default()
        
    d.text((100, 15), "INSTRUCTIONS", fill=(255, 200, 50), font=font_title)
    
    instructions = [
        "Welcome to Spiderman!",
        "",
        "CONTROLS:",
        "- Key 2: Drop Web (Catch enemies!)",
        "- Key 0: Use powerup / Toggle Instructions (in lobby)",
        "- Key 4: Use store upgrades",
        "- Key 9: Skip Level",
        "- Keys 1-4: Select item in store (Left to Right)",
        "",
        "RULES:",
        "- Catch Robbers & Goblins for Points.",
        "- Avoid Cops (Penalty!).",
        "- Catch Mary Jane for bonus points!",
        "- BIGGER objects give MORE points/penalty!"
    ]
    
    y = 45
    for line in instructions:
        d.text((20, y), line, fill=(255, 255, 255), font=font_text)
        y += 13
        
    # Convert to 8-bit color for MIF
    mif_path = "C:\\Lab_project\\VGA_Demo_restored\\MIF\\instructions_bg.mif"
    with open(mif_path, 'w') as f:
        f.write(f"DEPTH = {320 * 240};\n")
        f.write("WIDTH = 8;\n")
        f.write("ADDRESS_RADIX = DEC;\n")
        f.write("DATA_RADIX = HEX;\n")
        f.write("CONTENT\nBEGIN\n")
        
        for py in range(240):
            for px in range(320):
                r, g, b = img.getpixel((px, py))
                r3 = (r * 7) // 255
                g3 = (g * 7) // 255
                b2 = (b * 3) // 255
                val = (r3 << 5) | (g3 << 2) | b2
                addr = py * 320 + px
                f.write(f"{addr} : {val:02X};\n")
        f.write("END;\n")

create_instructions()
print("instructions_bg.mif generated!")

