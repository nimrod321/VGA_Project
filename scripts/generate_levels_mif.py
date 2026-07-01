import os
import random

MIF_PATH = r"C:\Lab_project\VGA_Demo_restored\MIF\levels.mif"
SV_PATH = r"C:\Lab_project\VGA_Demo_restored\RTL\GAME_CONTROLS\threshold_rom.sv"

# 256 entries in levels.mif (16 levels * 16 objects)
mif_data = [0] * 256

thresholds = [0] * 16 # index 0 is level 1, index 15 is level 16 (unused)
cumulative_score = 0

random.seed(42) # Ensure reproducible results!

def get_points(obj_type, scale):
    if obj_type == 2: # Robber
        return 50 * ((scale + 1) ** 2)
    elif obj_type == 3: # Maryjane
        return 500
    elif obj_type == 4: # Riddler
        return 0
    elif obj_type == 5: # Goblin
        return 1000
    return 0

for level in range(1, 16):
    
    # User requested to swap level 12 and 14 logic completely
    logic_level = level
    if level == 12: logic_level = 14
    elif level == 14: logic_level = 12

    # Scale object count from 5 to 12 as levels progress
    num_objects = 4 + (logic_level // 2)
    if num_objects > 12: num_objects = 12
    
    level_positive_points = 0
    
    for obj_idx in range(16):
        mif_idx = ((level - 1) * 16) + obj_idx
        
        if obj_idx < num_objects:
            # Active object
            t_active = 1
            
            # Determine type
            if logic_level in [5, 10, 15] and obj_idx == 0:
                # Force at least 1 Goblin boss on boss levels
                t_type = 5
            else:
                rand_val = random.randint(0, 100)
                if rand_val < 30: t_type = 1 # Cop (30%)
                elif rand_val < 65: t_type = 2 # Robber (35%)
                elif rand_val < 80: t_type = 3 # Maryjane (15%)
                else: # 20%
                    if logic_level >= 3:
                        t_type = 4 # Riddler
                    else:
                        t_type = 2 # Robber fallback
            
            # Special restriction: Goblins ONLY on 5, 10, 15
            if t_type == 5 and logic_level not in [5, 10, 15]:
                t_type = 2
            
            # Determine scale
            if t_type == 3:
                t_scale = 0 # Maryjane MUST be small (0)
            elif t_type == 4:
                t_scale = 1 # Riddler MUST be medium (1)
            elif t_type == 5:
                t_scale = 0 # Goblin MUST be small (0)
            else:
                scale_rand = random.randint(0, 100)
                if scale_rand < 60: t_scale = 0 # Small
                elif scale_rand < 90: t_scale = 1 # Medium
                else: t_scale = 2 # Large
            
            # Accumulate positive points for threshold calculation
            level_positive_points += get_points(t_type, t_scale)
            
            # Pack data
            val = (t_active << 5) | (t_scale << 3) | t_type
            mif_data[mif_idx] = val
        else:
            # Inactive object
            mif_data[mif_idx] = 0

    # Calculate 90% of available positive points
    required_points_for_level = int(level_positive_points * 0.90)
    
    # Cumulative threshold
    cumulative_score += required_points_for_level
    thresholds[level - 1] = cumulative_score

# --- Write MIF File ---
with open(MIF_PATH, "w") as f:
    f.write("DEPTH = 256;\n")
    f.write("WIDTH = 8;\n")
    f.write("ADDRESS_RADIX = DEC;\n")
    f.write("DATA_RADIX = HEX;\n")
    f.write("CONTENT\nBEGIN\n")
    for i in range(256):
        f.write(f"{i:03d} : {mif_data[i]:02X};\n")
    f.write("END;\n")

# --- Write SV ROM ---
sv_content = f"""// Auto-generated Threshold ROM
module threshold_rom (
    input  logic [3:0]  current_level,
    output logic [15:0] threshold
);
    always_comb begin
        case (current_level)
"""
for i in range(15):
    # current_level is 1-indexed in game
    sv_content += f"            4'd{i+1}: threshold = 16'd{thresholds[i]};\n"

sv_content += """            default: threshold = 16'd0;
        endcase
    end
endmodule
"""

with open(SV_PATH, "w") as f:
    f.write(sv_content)

print(f"Generated {MIF_PATH}")
print(f"Generated {SV_PATH}")
