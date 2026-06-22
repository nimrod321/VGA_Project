from PIL import Image, ImageDraw, ImageFont

def create_instructions():
    # 320x240 image, black background
    img = Image.new("RGB", (320, 240), (0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    box_left = 10
    box_right = 310
    box_top = 10
    box_bottom = 230
    
    # Draw blue filled box with white border
    draw.rectangle([box_left, box_top, box_right, box_bottom], fill=(0, 0, 100), outline=(255, 255, 255), width=2)
    # Inner border
    draw.rectangle([box_left+2, box_top+2, box_right-2, box_bottom-2], outline=(170, 170, 170), width=1)
    
    # Try to load a generic PIL font
    try:
        font = ImageFont.truetype("arial.ttf", 10)
        title_font = ImageFont.truetype("arial.ttf", 14)
    except:
        font = ImageFont.load_default()
        title_font = ImageFont.load_default()
        
    def draw_text_centered(text, y, f, color=(255, 255, 0)):
        # Calculate approximate width
        text_width = draw.textlength(text, font=f) if hasattr(draw, 'textlength') else len(text)*6
        x = (320 - text_width) // 2
        draw.text((x, y), text, fill=color, font=f)

    draw_text_centered("INSTRUCTIONS MENU", 15, title_font, (255, 255, 0))
    
    # Draw the rules!
    rules = [
        "SPIDEY'S CATCH - HOW TO PLAY:",
        "-----------------------------",
        "Your hook spins automatically.",
        "Press Key 5 to shoot hook!",
        "Press ENTER to use saved powerups.",
        "Catch Robbers & Mary Jane for Score.",
        "Avoid Cops! They cost you points.",
        "Catch the Riddler for random powerups.",
        "",
        "STORE CONTROLS:",
        "Press Keys 1, 2, 3, 4 to buy upgrades.",
        "",
        "POWERUPS:",
        "Clock: Slows time.",
        "Web Bomb: Catch everything in radius."
    ]
    
    y = 40
    for line in rules:
        draw_text_centered(line, y, font, (255, 255, 255))
        y += 11
        
    draw_text_centered("PRESS 0 TO EXIT", 210, title_font, (0, 255, 0))
    
    # Quantize
    img = img.quantize(colors=16, method=2)
    img.save("NEW_ASSETS_TO_CONVERT/instructions_320x240_FINAL.png")
    print("Saved perfect pixel-art instructions_320x240_FINAL.png")

create_instructions()
