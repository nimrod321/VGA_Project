import re

old_bdf = open('old.bdf', 'r').read()

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

connectors_str = ""

for name, dx, dy in ports:
    abs_x = -5016 + dx
    abs_y = -184 + dy
    match = re.search(r'\(connector[\s\S]*?\(pt ' + str(abs_x) + ' ' + str(abs_y) + r'\)[\s\S]*?\)', old_bdf)
    if match:
        connectors_str += match.group(0) + "\n"

new_connector = """(connector
	(text "current_state[1..0]" (rect -5116 -88 -5029 -71)(font "Intel Clear" ))
	(pt -5016 -80)
	(pt -5120 -80)
	(bus)
)
"""

connectors_str += new_connector

hud_symbol = open('hud_symbol.txt', 'r').read()

current_bdf = open(r'c:\Lab_project\VGA_Demo_restored\RTL\VGA\TOP_VGA_DEMO_KBD.bdf', 'r').read()
with open(r'c:\Lab_project\VGA_Demo_restored\RTL\VGA\TOP_VGA_DEMO_KBD.bdf', 'w') as f:
    f.write(current_bdf + "\n" + hud_symbol + "\n" + connectors_str)

print("Successfully patched BDF with hud_drawer and all 14 connectors!")
