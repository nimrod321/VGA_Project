import sys
import re

old_bdf = open('old.bdf', 'r').read()

# Find the symbol block for hud_drawer
symbol_match = re.search(r'\(symbol[\s\S]*?\"hud_drawer\"[\s\S]*?\(drawing[\s\S]*?\)\n\)', old_bdf)
if symbol_match:
    symbol_str = symbol_match.group(0)
    # Add current_state port
    new_port = """	(port
		(pt 0 104)
		(input)
		(text "current_state[1..0]" (rect 0 0 94 12)(font "Arial" ))
		(text "current_state[1..0]" (rect 21 99 115 111)(font "Arial" ))
		(line (pt 0 104)(pt 16 104)(line_width 3))
	)"""
    # Insert new_port before score[15..0]
    symbol_str = symbol_str.replace('\t(port\n\t\t(pt 0 112)', new_port + '\n\t(port\n\t\t(pt 0 112)')
    # Also adjust the size of the drawing rect from 208 to 224 to make room? (Optional)
    
    with open('hud_symbol.txt', 'w') as f:
        f.write(symbol_str)

# Find the inst block for hud_drawer
inst_match = re.search(r'\(inst[^\)]*\"hud_drawer\"[\s\S]*?\(pt \d+ \d+\)\n\t\)\n\)', old_bdf)
if inst_match:
    print('Found inst block')
    inst_str = inst_match.group(0)
    # Add current_state port to inst
    new_inst_port = """		(port
			(pt 0 104)
			(input)
			(text "current_state[1..0]" (rect 0 0 94 12)(font "Arial" ))
			(text "current_state[1..0]" (rect 21 99 115 111)(font "Arial" ))
			(line (pt 0 104)(pt 16 104)(line_width 3))
		)"""
    inst_str = inst_str.replace('\t\t(port\n\t\t\t(pt 0 112)', new_inst_port + '\n\t\t(port\n\t\t\t(pt 0 112)')
    with open('hud_inst.txt', 'w') as f:
        f.write(inst_str)

