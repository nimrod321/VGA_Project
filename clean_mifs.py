import os

def clean_mif(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    cleaned_lines = []
    for line in lines:
        if ':' in line and ';' in line:
            # Parse the address and value
            parts = line.split(':')
            addr = parts[0].strip()
            val_str = parts[1].split(';')[0].strip()
            try:
                val = int(val_str, 16)
                
                # 3-3-2 RGB decoding
                r = val >> 5
                g = (val >> 2) & 0x7
                b = val & 0x3
                
                # If the pixel is very close to white (anti-aliasing artifacts)
                # Max R=7, G=7, B=3.
                if r >= 5 and g >= 5 and b >= 2:
                    val_str = "FF" # Force to transparent
                    
                cleaned_lines.append(f"{addr} : {val_str};\n")
            except ValueError:
                cleaned_lines.append(line)
        else:
            cleaned_lines.append(line)
            
    with open(filepath, 'w') as f:
        f.writelines(cleaned_lines)

if __name__ == "__main__":
    mif_dir = "MIF"
    for filename in os.listdir(mif_dir):
        if filename.endswith(".mif") and filename != "background.mif" and filename != "levels.mif":
            print(f"Cleaning {filename}...")
            clean_mif(os.path.join(mif_dir, filename))
    print("Done cleaning all sprite MIFs!")
