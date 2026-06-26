import re

bdf = open('old.bdf', 'r').read()

# hud_drawer rect: (rect -5016 -184 -4784 40)
# Base X = -5016
# Base Y = -184

ports = [
    ("clk", 0, 32),
    ("resetN", 0, 48),
    ("pixelX[10..0]", 0, 64),
    ("pixelY[10..0]", 0, 80),
    ("startOfFrame", 0, 96),
    ("score[15..0]", 0, 112),
    ("threshold[15..0]", 0, 128),
    ("time_left[7..0]", 0, 144),
    ("current_level[3..0]", 0, 160),
    ("score_pulse", 0, 176),
    ("added_score[15..0]", 0, 192),
    ("hudDrawingRequest", 232, 32),
    ("hudRGB[7..0]", 232, 48)
]

print("Looking for connectors...")
for name, dx, dy in ports:
    abs_x = -5016 + dx
    abs_y = -184 + dy
    # Search for connector ending at abs_x, abs_y
    # (pt abs_x abs_y)
    match = re.search(r'\(connector[\s\S]*?\(pt ' + str(abs_x) + ' ' + str(abs_y) + r'\)[\s\S]*?\)', bdf)
    if match:
        print(f"Port {name}: Found connector!")
        print(match.group(0))
    else:
        print(f"Port {name}: NO CONNECTOR FOUND")

