import os
from PIL import Image

def rgb_to_8bit(r, g, b):
    # 3 bits red, 3 bits green, 2 bits blue
    return ((r >> 5) << 5) | ((g >> 5) << 2) | (b >> 6)

def convert_to_mif(img_path, mif_path, width, height):
    try:
        img = Image.open(img_path).convert('RGBA')
    except Exception as e:
        print(f"Error opening {img_path}: {e}")
        return
        
    img = img.resize((width, height), Image.Resampling.NEAREST)
    
    # Identify background color (assume top-left pixel)
    bg_color = img.getpixel((0, 0))
    
    mif_data = []
    
    # Depth is width*height, Width is 8 bits
    depth = width * height
    
    mif_str = f"DEPTH = {depth};\nWIDTH = 8;\nADDRESS_RADIX = DEC;\nDATA_RADIX = HEX;\nCONTENT\nBEGIN\n"
    
    for y in range(height):
        for x in range(width):
            r, g, b, a = img.getpixel((x, y))
            
            # If pixel is fully transparent or matches background color exactly, make it 0xFF
            if a < 128 or (r, g, b) == bg_color[:3]:
                val = 0xFF
            else:
                val = rgb_to_8bit(r, g, b)
                if val == 0xFF:
                    # Prevent character pixels from becoming transparent by shifting to FE
                    val = 0xFE 
                    
            idx = y * width + x
            mif_str += f"{idx:04d} : {val:02X};\n"
            
    mif_str += "END;\n"
    
    with open(mif_path, "w") as f:
        f.write(mif_str)
    print(f"Created {mif_path}")

convert_to_mif(r'C:\Users\рошег амещ\.gemini\antigravity\brain\04961d19-aecd-4ed9-86da-ebc58777ed70\riddler_sprite_1781009334946.png', r'MIF\riddler.mif', 32, 32)
convert_to_mif(r'C:\Users\рошег амещ\.gemini\antigravity\brain\04961d19-aecd-4ed9-86da-ebc58777ed70\maryjane_sprite_1781009386144.png', r'MIF\maryjane.mif', 32, 32)
convert_to_mif(r'C:\Users\рошег амещ\.gemini\antigravity\brain\04961d19-aecd-4ed9-86da-ebc58777ed70\cop_sprite_1781009351734.png', r'MIF\cop.mif', 16, 16)
convert_to_mif(r'C:\Users\рошег амещ\.gemini\antigravity\brain\04961d19-aecd-4ed9-86da-ebc58777ed70\robber_sprite_1781009368800.png', r'MIF\robber_stand.mif', 16, 16)
convert_to_mif(r'C:\Users\рошег амещ\.gemini\antigravity\brain\04961d19-aecd-4ed9-86da-ebc58777ed70\robber_sprite_1781009368800.png', r'MIF\robber_run.mif', 16, 16)
