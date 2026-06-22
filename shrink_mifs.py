import os
from PIL import Image

def Quantize_8(v):
    return [0,0,48,48,96,96,128,128,160,160,192,192,224,224,255,255][int(v/16)]

def Quantize_4(v):
    return [0,0,96,96,160,160,255,255][int(v/32)]

files = {
    r"C:\Lab_project\VGA_Demo_restored\NEW_ASSETS_TO_CONVERT\output_lobby_320x240_FINAL_20260621_163729\lobby_320x240_FINAL_out.png": r"C:\Lab_project\VGA_Demo_restored\MIF\lobby_bg.mif",
    r"C:\Lab_project\VGA_Demo_restored\NEW_ASSETS_TO_CONVERT\output_store_320x240_FINAL_20260621_163755\store_320x240_FINAL_out.png": r"C:\Lab_project\VGA_Demo_restored\MIF\store_bg.mif",
    r"C:\Lab_project\VGA_Demo_restored\NEW_ASSETS_TO_CONVERT\output_instructions_320x240_FINAL_20260621_163536\instructions_320x240_FINAL_out.png": r"C:\Lab_project\VGA_Demo_restored\MIF\instructions_bg.mif"
}

for in_f, out_f in files.items():
    if not os.path.exists(in_f):
        print(f"File not found: {in_f}")
        continue
        
    print(f"Processing {os.path.basename(in_f)}...")
    img = Image.open(in_f).convert("RGB")
    # Force strictly to 320x240
    img = img.resize((320, 240), Image.Resampling.NEAREST)
    w, h = img.size
    px = img.load()
    
    with open(out_f, "w", encoding="utf-8") as f:
        f.write("-- Memory efficient 320x240 MIF\n")
        f.write("DEPTH = 76800;\n")
        f.write("WIDTH = 8;\n")
        f.write("ADDRESS_RADIX = HEX;\n")
        f.write("DATA_RADIX = HEX;\n")
        f.write("CONTENT BEGIN\n")
        
        digits = 5
        for y in range(h):
            for x in range(w):
                rr, gg, bb = px[x, y]
                # Quantize the exact same way as BMPConverter
                rq = Quantize_8(rr)
                gq = Quantize_8(gg)
                bq = Quantize_4(bb)
                
                colorbyte = (rq//32)*32 + (gq//32)*4 + (bq//64)
                addr = hex(y*w + x)[2:].upper().zfill(digits)
                f.write(f"{addr}: {colorbyte:02X};\n")
                
        f.write("END;\n")
        print(f"Saved optimized MIF: {out_f}")

print("All conversions complete!")
