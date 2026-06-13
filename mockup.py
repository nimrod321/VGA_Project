import os
from PIL import Image, ImageDraw

def create_mockups():
    base_img_path = r"c:\Lab_project\VGA_Demo_restored\empty_background_edited.png"
    out_dir = r"C:\Users\נמרוד אלוש\.gemini\antigravity\brain\04961d19-aecd-4ed9-86da-ebc58777ed70"
    
    if not os.path.exists(base_img_path):
        print("Base image not found!")
        return

    img = Image.open(base_img_path).convert("RGB")
    img = img.resize((640, 480)) # Ensure it's exactly 640x480
    
    # --- MOCKUP 1: Pixel Doubling (Nearest Neighbor) ---
    # Shrink to 320x240
    small_img = img.resize((320, 240), Image.Resampling.NEAREST)
    # Scale back up to 640x480 using Nearest Neighbor to simulate 2x hardware scaling
    doubled_img = small_img.resize((640, 480), Image.Resampling.NEAREST)
    doubled_img.save(os.path.join(out_dir, "pixel_doubled_mockup.png"))
    
    # --- MOCKUP 2: Procedural Bottom Half ---
    procedural_img = img.copy()
    draw = ImageDraw.Draw(procedural_img)
    
    # The top half (y: 0 to 240) stays exactly the same.
    # We will draw over the bottom half (y: 240 to 480).
    # Fill bottom half with "procedural" grass (solid green)
    draw.rectangle([0, 240, 640, 480], fill=(70, 160, 50))
    
    # Draw "procedural" vertical road
    draw.rectangle([280, 240, 360, 480], fill=(100, 100, 100))
    
    # Draw "procedural" horizontal road at the bottom
    draw.rectangle([0, 400, 640, 480], fill=(100, 100, 100))
    
    # Add some white procedural lane lines
    for y in range(250, 400, 40):
        draw.rectangle([315, y, 325, y+20], fill=(255, 255, 255))
        
    for x in range(0, 640, 40):
        if not (280 <= x <= 360): # Don't draw over intersection
            draw.rectangle([x, 435, x+20, 445], fill=(255, 255, 255))
    
    procedural_img.save(os.path.join(out_dir, "procedural_bottom_mockup.png"))
    
    print("Mockups generated successfully!")

if __name__ == "__main__":
    create_mockups()
