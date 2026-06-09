import os
from PIL import Image

def rgb_to_8bit(r, g, b):
    return ((r >> 5) << 5) | ((g >> 5) << 2) | (b >> 6)

def convert_to_mif(img_path, mif_path, width, height):
    try:
        img = Image.open(img_path).convert('RGBA')
    except Exception as e:
        print(f"Error opening {img_path}: {e}")
        return
        
    img = img.resize((width, height), Image.Resampling.NEAREST)
    bg_color = img.getpixel((0, 0))
    depth = width * height
    mif_str = f"DEPTH = {depth};\nWIDTH = 8;\nADDRESS_RADIX = DEC;\nDATA_RADIX = HEX;\nCONTENT\nBEGIN\n"
    
    for y in range(height):
        for x in range(width):
            r, g, b, a = img.getpixel((x, y))
            if a < 128 or (r, g, b) == bg_color[:3]:
                val = 0xFF
            else:
                val = rgb_to_8bit(r, g, b)
                if val == 0xFF:
                    val = 0xFE 
            idx = y * width + x
            mif_str += f"{idx:04d} : {val:02X};\n"
    mif_str += "END;\n"
    with open(mif_path, "w") as f:
        f.write(mif_str)
    print(f"Created {mif_path}")

base = os.path.join(os.environ['USERPROFILE'], '.gemini', 'antigravity', 'brain', '04961d19-aecd-4ed9-86da-ebc58777ed70')
convert_to_mif(os.path.join(base, 'goblin_sprite_1781015220918.png'), os.path.join('MIF', 'goblin.mif'), 16, 16)
