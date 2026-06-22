import os
import glob
from PIL import Image, ImageDraw

def process_bg_clean(input_path, output_path):
    img = Image.open(input_path).convert("RGB")
    # Resize to 320x240 cleanly
    img = img.resize((320, 240), Image.Resampling.LANCZOS)
    
    # Quantize to 16-color palette to force a true retro pixel-art look
    img = img.quantize(colors=16, method=2)
    img.save(output_path)
    print(f"Saved {output_path}")

def process_icon(input_path, output_path, size=32):
    img = Image.open(input_path).convert("RGBA")
    # Resize to 32x32
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    
    # Make background transparent (assuming the generated image has a solid background)
    # We will pick the top-left pixel as the transparent color
    bg_color = img.getpixel((0,0))
    data = img.getdata()
    new_data = []
    for item in data:
        # If it's close to the bg color, make it transparent
        if abs(item[0]-bg_color[0]) < 20 and abs(item[1]-bg_color[1]) < 20 and abs(item[2]-bg_color[2]) < 20:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
    img.putdata(new_data)
    
    img = img.quantize(colors=255)
    img.save(output_path)
    print(f"Saved {output_path}")

def create_bomb():
    img = Image.new("RGBA", (16, 16), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    # White circle
    draw.ellipse([2, 2, 13, 13], fill=(255, 255, 255, 255))
    # Red dot in center
    draw.rectangle([7, 7, 8, 8], fill=(255, 0, 0, 255))
    
    img = img.quantize(colors=255)
    img.save("goblin_bomb_16x16.png")
    print("Saved goblin_bomb_16x16.png")

if __name__ == "__main__":
    # Process backgrounds
    lobby_files = glob.glob(r"C:\Users\נמרוד אלוש\.gemini\antigravity\brain\04961d19-aecd-4ed9-86da-ebc58777ed70\lobby_v3_base_*.png")
    if lobby_files:
        process_bg_clean(lobby_files[0], "NEW_ASSETS_TO_CONVERT/lobby_320x240_FINAL.png")
        
    store_files = glob.glob(r"C:\Users\נמרוד אלוש\.gemini\antigravity\brain\04961d19-aecd-4ed9-86da-ebc58777ed70\store_v6_base_*.png")
    if store_files:
        process_bg_clean(store_files[0], "NEW_ASSETS_TO_CONVERT/store_320x240_FINAL.png")

    # Process icons
    clock_files = glob.glob(r"C:\Users\נמרוד אלוש\.gemini\antigravity\brain\04961d19-aecd-4ed9-86da-ebc58777ed70\icon_clock_*.png")
    if clock_files:
        process_icon(clock_files[0], "icon_clock_32x32.png")
        
    web_files = glob.glob(r"C:\Users\נמרוד אלוש\.gemini\antigravity\brain\04961d19-aecd-4ed9-86da-ebc58777ed70\icon_web_*.png")
    if web_files:
        process_icon(web_files[0], "icon_web_32x32.png")
        
    scissors_files = glob.glob(r"C:\Users\נמרוד אלוש\.gemini\antigravity\brain\04961d19-aecd-4ed9-86da-ebc58777ed70\icon_scissors_*.png")
    if scissors_files:
        process_icon(scissors_files[0], "icon_scissors_32x32.png")

    create_bomb()
