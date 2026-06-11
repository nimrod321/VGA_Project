import os

# Aligning ID Codes with obj_type in SpideyObjectsBitMap.sv
ID_COP          = 1
ID_ROBBER_STAND = 2
ID_ROBBER_RUN   = 3
ID_MARYJANE     = 4
ID_RIDDLER      = 5
ID_GOBLIN       = 6

SCALE_SMALL  = 0
SCALE_MEDIUM = 1
SCALE_LARGE  = 2

def make_obj(id_code, scale=SCALE_SMALL):
    return (1 << 5) | ((scale & 0x3) << 3) | (id_code & 0x7)

def empty_slot():
    return 0x00

LEVELS = {
    1: [
        make_obj(ID_GOBLIN, SCALE_SMALL),
        make_obj(ID_ROBBER_RUN, SCALE_LARGE),
        make_obj(ID_ROBBER_STAND, SCALE_MEDIUM),
        make_obj(ID_COP, SCALE_LARGE),
        make_obj(ID_MARYJANE, SCALE_SMALL)
    ],
    2: [
        make_obj(ID_COP, SCALE_SMALL),
        make_obj(ID_COP, SCALE_SMALL),
        make_obj(ID_COP, SCALE_SMALL),
        make_obj(ID_ROBBER_STAND, SCALE_SMALL),
        make_obj(ID_ROBBER_RUN, SCALE_SMALL),
        make_obj(ID_ROBBER_RUN, SCALE_MEDIUM),
        make_obj(ID_MARYJANE, SCALE_MEDIUM)
    ],
    3: [
        make_obj(ID_COP, SCALE_SMALL),
        make_obj(ID_COP, SCALE_SMALL),
        make_obj(ID_ROBBER_STAND, SCALE_MEDIUM),
        make_obj(ID_ROBBER_RUN, SCALE_MEDIUM),
        make_obj(ID_MARYJANE, SCALE_MEDIUM),
        make_obj(ID_RIDDLER, SCALE_MEDIUM)
    ],
    4: [
        make_obj(ID_COP, SCALE_SMALL),
        make_obj(ID_COP, SCALE_SMALL),
        make_obj(ID_ROBBER_STAND, SCALE_MEDIUM),
        make_obj(ID_ROBBER_RUN, SCALE_MEDIUM),
        make_obj(ID_MARYJANE, SCALE_MEDIUM),
        make_obj(ID_RIDDLER, SCALE_MEDIUM),
        make_obj(ID_RIDDLER, SCALE_MEDIUM)
    ],
    5: [
        # BOSS BATTLE LEVEL!
        make_obj(ID_GOBLIN, SCALE_MEDIUM),
        make_obj(ID_COP, SCALE_SMALL),
        make_obj(ID_ROBBER_RUN, SCALE_SMALL),
        make_obj(ID_MARYJANE, SCALE_MEDIUM)
    ],
    6: [
        make_obj(ID_COP, SCALE_SMALL),
        make_obj(ID_COP, SCALE_SMALL),
        make_obj(ID_COP, SCALE_SMALL),
        make_obj(ID_COP, SCALE_SMALL),
        make_obj(ID_COP, SCALE_SMALL),
        make_obj(ID_ROBBER_STAND, SCALE_SMALL),
        make_obj(ID_ROBBER_RUN, SCALE_SMALL)
    ],
    7: [
        make_obj(ID_ROBBER_STAND, SCALE_MEDIUM),
        make_obj(ID_ROBBER_STAND, SCALE_MEDIUM),
        make_obj(ID_ROBBER_RUN, SCALE_MEDIUM),
        make_obj(ID_ROBBER_RUN, SCALE_MEDIUM),
        make_obj(ID_ROBBER_RUN, SCALE_MEDIUM),
        make_obj(ID_MARYJANE, SCALE_SMALL),
        make_obj(ID_MARYJANE, SCALE_SMALL)
    ],
    8: [
        make_obj(ID_RIDDLER, SCALE_SMALL),
        make_obj(ID_RIDDLER, SCALE_SMALL),
        make_obj(ID_RIDDLER, SCALE_SMALL),
        make_obj(ID_RIDDLER, SCALE_SMALL),
        make_obj(ID_COP, SCALE_SMALL),
        make_obj(ID_MARYJANE, SCALE_SMALL),
        make_obj(ID_MARYJANE, SCALE_SMALL)
    ],
    9: [
        make_obj(ID_COP, SCALE_SMALL),
        make_obj(ID_ROBBER_STAND, SCALE_MEDIUM),
        make_obj(ID_ROBBER_RUN, SCALE_LARGE),
        make_obj(ID_MARYJANE, SCALE_SMALL),
        make_obj(ID_RIDDLER, SCALE_SMALL),
        make_obj(ID_GOBLIN, SCALE_SMALL)
    ],
    10: [
        make_obj(ID_GOBLIN, SCALE_SMALL),
        make_obj(ID_GOBLIN, SCALE_SMALL),
        make_obj(ID_MARYJANE, SCALE_SMALL),
        make_obj(ID_MARYJANE, SCALE_SMALL),
        make_obj(ID_MARYJANE, SCALE_SMALL)
    ]
}

def generate_mif():
    mif_path = os.path.join("MIF", "levels.mif")
    depth = 256
    mif_str = f"DEPTH = {depth};\nWIDTH = 8;\nADDRESS_RADIX = DEC;\nDATA_RADIX = HEX;\nCONTENT\nBEGIN\n"
    
    for level_idx in range(1, 17):
        base_addr = (level_idx - 1) * 16
        level_objects = LEVELS.get(level_idx, [])
        for obj_idx in range(15):
            addr = base_addr + obj_idx
            if obj_idx < len(level_objects):
                val = level_objects[obj_idx]
            else:
                val = empty_slot()
            mif_str += f"{addr:04d} : {val:02X};\n"
    mif_str += "END;\n"
    with open(mif_path, "w") as f:
        f.write(mif_str)

if __name__ == "__main__":
    generate_mif()
