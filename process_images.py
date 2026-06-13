import os
import glob
from PIL import Image

artifact_dir = r"C:\Users\נמרוד אלוש\.gemini\antigravity\brain\04961d19-aecd-4ed9-86da-ebc58777ed70"
project_dir = r"C:\Lab_project\VGA_Demo_restored"

def process_sprite(filepath, outname):
    img = Image.open(filepath).convert("RGBA")
    # Resize exactly to 32x32 using nearest neighbor to preserve pixel art blocks
    img_small = img.resize((32, 32), resample=Image.NEAREST)
    
    # Process pixels: pure white background
    pixels = img_small.load()
    width, height = img_small.size
    
    # Flood fill background from edges to identify what is "outside" vs "inside"
    # Actually, AI generates pure white background. We will just convert near-white to pure white.
    # But if there's white inside the character, we want to tint it slightly so it doesn't become transparent.
    # We assume edge pixels are background.
    
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if r > 240 and g > 240 and b > 240:
                # If it's a border pixel or near edge, make it pure white (transparent)
                if x < 4 or x > 28 or y < 4 or y > 28:
                    pixels[x, y] = (255, 255, 255, 255)
                else:
                    # Inside the character, tint it slightly to avoid transparency
                    pixels[x, y] = (254, 254, 254, 255)
            elif a < 255:
                # Any transparent pixels become pure white
                pixels[x, y] = (255, 255, 255, 255)
                
    outpath = os.path.join(project_dir, outname)
    img_small.save(outpath)
    print(f"Saved {outname} to {outpath}")

def process_background():
    bg_path = os.path.join(project_dir, "empty_background_640x480.png")
    if not os.path.exists(bg_path):
        print("Background not found.")
        return
        
    img = Image.open(bg_path).convert("RGB")
    pixels = img.load()
    
    # Fill bottom half (y >= 240) with asphalt color
    asphalt_color = (40, 45, 50)
    for y in range(240, 480):
        for x in range(640):
            pixels[x, y] = asphalt_color
            
    outpath = os.path.join(project_dir, "new_background_fixed.png")
    img.save(outpath)
    print(f"Saved background to {outpath}")

if __name__ == "__main__":
    sprites = {
        "sprite_cop_*.png": "cop_32x32.png",
        "sprite_robber_stand_*.png": "robber_stand_32x32.png",
        "sprite_robber_run_*.png": "robber_run_32x32.png",
        "sprite_maryjane_*.png": "maryjane_32x32.png",
        "sprite_riddler_*.png": "riddler_32x32.png",
        "sprite_goblin_*.png": "goblin_32x32.png"
    }
    
    for pattern, outname in sprites.items():
        files = glob.glob(os.path.join(artifact_dir, pattern))
        if files:
            # Get latest
            files.sort(key=os.path.getmtime, reverse=True)
            process_sprite(files[0], outname)
            
    process_background()
