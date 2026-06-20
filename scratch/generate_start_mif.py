text = [
"                                                                ",
"  SSS  TTTTT   A   RRRR  TTTTT                                  ",
" S       T    A A  R   R   T                                    ",
"  SSS    T   AAAAA RRRR    T                                    ",
"     S   T   A   A R R     T                                    ",
"  SSS    T   A   A R  R    T                                    ",
"                                                                ",
"  PPPPP RRRR  EEEEE  SSS   SSS    EEEEE N   N TTTTT EEEEE RRRR  ",
"  P   P R   R E     S     S       E     NN  N   T   E     R   R ",
"  PPPPP RRRR  EEEE   SSS   SSS    EEEE  N N N   T   EEEE  RRRR  ",
"  P     R R   E         S     S   E     N  NN   T   E     R R   ",
"  P     R  R  EEEEE  SSS   SSS    EEEEE N   N   T   EEEEE R  R  ",
"                                                                ",
"            TTTTT  OOO     SSS  TTTTT   A   RRRR  TTTTT         ",
"              T   O   O   S       T    A A  R   R   T           ",
"              T   O   O    SSS    T   AAAAA RRRR    T           ",
"              T   O   O       S   T   A   A R R     T           ",
"              T    OOO     SSS    T   A   A R  R    T           ",
"                                                                "
]

# The array above is 19 lines. Each string is 64 characters long.
# Let's scale it by 4x in width and 2x in height to get a 256 x 38 resolution.
# We'll pad the height to 64 so it's 256x64.
# Depth = 256 * 64 = 16384.

WIDTH = 256
HEIGHT = 64
DEPTH = WIDTH * HEIGHT

with open("MIF/start_text.mif", "w") as f:
    f.write(f"DEPTH = {DEPTH};\n")
    f.write("WIDTH = 8;\n")
    f.write("ADDRESS_RADIX = HEX;\n")
    f.write("DATA_RADIX = HEX;\n")
    f.write("CONTENT BEGIN\n")
    
    addr = 0
    for y in range(HEIGHT):
        text_y = y // 2
        for x in range(WIDTH):
            text_x = x // 4
            
            if text_y < len(text) and text_x < len(text[text_y]):
                char = text[text_y][text_x]
                if char != ' ':
                    # Bright red color
                    f.write(f"{addr:04X} : E0;\n")
                else:
                    # Transparent/background indicator (00)
                    f.write(f"{addr:04X} : 00;\n")
            else:
                f.write(f"{addr:04X} : 00;\n")
            addr += 1
            
    f.write("END;\n")

print("Created start_text.mif successfully!")
