# ================================================================
# BMPConverter_V21.py
# (c) Technion IIT 2025 - Leroy Dokhanian
#
# Features kept from previous fixes:
#   - Preset affects WORK resolution (64x32)
#   - Reset, Undo/Redo, full filters
#   - Create Output Files generates PNG + MIF + SV + log and exits
#   - 2-bit is dominant color only
#   - MIF: ADDRESS_RADIX=HEX, DATA_RADIX=HEX, WIDTH = bits (1/2/8)
# ================================================================

import sys, os
from tkinter import *
from tkinter import filedialog
from PIL import ImageTk, Image, ImageFilter
from datetime import datetime

# ================= Globals =================
root = None

imgFromFile = None
imgOriginal = None
imgBMP = None

FileName = ""
PathToFile = ""

# preview on screen (constant size)
PREVIEW_SIZE = (256, 256)

# "work base size" (resolution we want before scale down)
work_base_size = (256, 256)

SingleBitBitMap = 8

history_stack = []
redo_stack = []
HISTORY_LIMIT = 30

# GUI handles
lbl_left = None
lbl_right = None
lbl_workinfo = None

bmpScale = None
ResizeScale = None
Rlambda = None
Glambda = None
Blambda = None
grayThreshold = None

# layout
root_geometry_size = "900x650+150+50"
Original_Position = (100, 50)
TL_BMP_Position = (400, 50)
CONTROLS_Y = 300


# ================= Helpers =================
def push_history():
    global history_stack, redo_stack, imgOriginal
    if imgOriginal is None:
        return
    if len(history_stack) >= HISTORY_LIMIT:
        history_stack.pop(0)
    history_stack.append(imgOriginal.copy())
    redo_stack.clear()

def undo_action():
    global imgOriginal, history_stack, redo_stack
    if not history_stack:
        return
    redo_stack.append(imgOriginal.copy())
    imgOriginal = history_stack.pop()
    picModify(0)

def redo_action():
    global imgOriginal, history_stack, redo_stack
    if not redo_stack:
        return
    history_stack.append(imgOriginal.copy())
    imgOriginal = redo_stack.pop()
    picModify(0)

def ensure_output_dir():
    global PathToFile, FileName
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    safe_name = FileName.replace(" ", "_")
    out_dir = os.path.join(PathToFile, f"output_{safe_name}_{timestamp}")
    os.makedirs(out_dir, exist_ok=True)
    return out_dir


# ================= Image Open =================
def open_img():
    global FileName, PathToFile, imgOriginal, imgFromFile, imgBMP, work_base_size

    path = filedialog.askopenfilename(
        filetypes=[("Images", "*.jpg *.bmp *.png"), ("All", "*.*")]
    )
    if not path:
        sys.exit()

    img = Image.open(path).convert("RGB")
    imgFromFile = img.copy()
    imgOriginal = img.copy()
    imgBMP = img.copy()

    PathToFile, fname = os.path.split(path)
    FileName = os.path.splitext(fname)[0]

    work_base_size = (256, 256)

    update_previews()
    OpenGUIKeys()
    picModify(0)


# ================= GUI =================
def OpenGUIKeys():
    global bmpScale, ResizeScale, Rlambda, Glambda, Blambda, grayThreshold, lbl_workinfo

    # label changed: "Scale"
    bmpScale = Scale(root, from_=-1, to=6, label="Scale", command=picModify)
    bmpScale.set(0)
    bmpScale.place(x=0, y=80)

    Button(root, text="Preset 64x32", command=lambda: set_preset(64, 32)).place(x=0, y=220)

    # label changed: "MODE"
    ResizeScale = Scale(root, from_=0, to=5, label="MODE", command=picModify)
    ResizeScale.set(0)
    ResizeScale.place(x=0, y=300)

    # Status label
    lbl_workinfo = Label(root, text="", anchor="nw", justify=LEFT)
    lbl_workinfo.place(x=TL_BMP_Position[0] + PREVIEW_SIZE[0] + 20, y=TL_BMP_Position[1])

    grayThreshold = Scale(root, from_=0, to=255, label="Gray threshold", command=picModify)
    grayThreshold.set(128)
    grayThreshold.place(x=550, y=CONTROLS_Y + 50)

    Rlambda = Scale(root, from_=0, to=200, label="R", orient=HORIZONTAL, command=picModify)
    Rlambda.set(100)
    Rlambda.place(x=400, y=CONTROLS_Y + 10)

    Glambda = Scale(root, from_=0, to=200, label="G", orient=HORIZONTAL, command=picModify)
    Glambda.set(100)
    Glambda.place(x=400, y=CONTROLS_Y + 70)

    Blambda = Scale(root, from_=0, to=200, label="B", orient=HORIZONTAL, command=picModify)
    Blambda.set(100)
    Blambda.place(x=400, y=CONTROLS_Y + 130)


    Button(root, text="Reset To Original", command=ResetToOriginal).place(x=35, y=CONTROLS_Y + 30)

    Button(root, text="UNDO", bg="red", command=undo_action).place(x=200, y=CONTROLS_Y + 20)
    Button(root, text="REDO", bg="orange", command=redo_action).place(x=260, y=CONTROLS_Y + 20)

    filters = [
        ("BLUR", ImageFilter.BLUR),
        ("CONTOUR", ImageFilter.CONTOUR),
        ("DETAIL", ImageFilter.DETAIL),
        ("EDGE_ENHANCE", ImageFilter.EDGE_ENHANCE),
        ("EMBOSS", ImageFilter.EMBOSS),
        ("FIND_EDGES", ImageFilter.FIND_EDGES),
        ("SMOOTH", ImageFilter.SMOOTH),
        ("SHARPEN", ImageFilter.SHARPEN),
    ]
    x_positions = [100, 250]
    for idx, (name, filt) in enumerate(filters):
        x = x_positions[idx // 4]
        y = CONTROLS_Y + 60 + (idx % 4) * 30
        Button(root, text=name, command=lambda f=filt: apply_filter(f)).place(x=x, y=y)

    Button(root, text="8-bit", bg="green", command=lambda: set_mode(8)).place(x=50, y=CONTROLS_Y + 200)
    Button(root, text="2-bit", bg="orange", command=lambda: set_mode(2)).place(x=180, y=CONTROLS_Y + 200)
    Button(root, text="1-bit", bg="gray", command=lambda: set_mode(1)).place(x=300, y=CONTROLS_Y + 200)

    Button(root, text="Create Output Files", bg="light blue", command=write_outputs).place(x=500, y=CONTROLS_Y + 200)


def set_preset(w, h):
    global work_base_size
    work_base_size = (w, h)
    bmpScale.set(0)
    picModify(0)


# ================= Display =================
def init_preview_labels():
    global lbl_left, lbl_right
    lbl_left = Label(root)
    lbl_left.place(x=Original_Position[0], y=Original_Position[1])

    lbl_right = Label(root)
    lbl_right.place(x=TL_BMP_Position[0], y=TL_BMP_Position[1])

def update_previews():
    global lbl_left, lbl_right, imgOriginal, imgBMP
    if lbl_left is None or lbl_right is None:
        init_preview_labels()

    left_img = imgOriginal.resize(PREVIEW_SIZE, Image.Resampling.NEAREST)
    right_img = imgBMP.resize(PREVIEW_SIZE, Image.Resampling.NEAREST)

    left_tk = ImageTk.PhotoImage(left_img)
    right_tk = ImageTk.PhotoImage(right_img)

    lbl_left.configure(image=left_tk)
    lbl_left.image = left_tk

    lbl_right.configure(image=right_tk)
    lbl_right.image = right_tk


# ================= Processing =================
def Quantize_8(v):
    return [0,0,48,48,96,96,128,128,160,160,192,192,224,224,255,255][int(v/16)]

def Quantize_4(v):
    return [0,0,96,96,160,160,255,255][int(v/32)]

def ResetToOriginal():
    global imgOriginal, imgFromFile
    if imgFromFile is None:
        return
    push_history()
    imgOriginal = imgFromFile.copy()
    picModify(0)

def apply_filter(filt):
    global imgOriginal
    push_history()
    imgOriginal = imgOriginal.filter(filt)
    picModify(0)

def set_mode(bits):
    global SingleBitBitMap
    SingleBitBitMap = bits
    root.title(f"BMPConverter V21 | Mode: {bits}-bit")
    picModify(0)

def picModify(_):
    global imgBMP, lbl_workinfo

    if imgOriginal is None:
        return

    base_w, base_h = work_base_size
    scale_val = bmpScale.get()

    if scale_val == -1:
        target_w, target_h = (640, 480)
    else:
        ratio = max(1, 2 ** scale_val)
        target_w = max(1, base_w // ratio)
        target_h = max(1, base_h // ratio)

    # Status text 
    if lbl_workinfo is not None and imgFromFile is not None:
        orig_w, orig_h = imgFromFile.size
        lbl_workinfo.configure(
            text=f"Base Size: {orig_w}x{orig_h}\n"
                 f"Output Size: {target_w}x{target_h}\n"
                 f"Mode: {SingleBitBitMap}-bit"
        )

    imgBMP = imgOriginal.resize((target_w, target_h), resample=ResizeScale.get())

    r, g, b = imgBMP.split()
    r = r.point(lambda i: int(i * Rlambda.get() / 100))
    g = g.point(lambda i: int(i * Glambda.get() / 100))
    b = b.point(lambda i: int(i * Blambda.get() / 100))
    imgBMP = Image.merge("RGB", (r, g, b))

    pixels = imgBMP.load()
    w, h = imgBMP.size

    if SingleBitBitMap == 1:
        th = grayThreshold.get()
        for x in range(w):
            for y in range(h):
                rr, gg, bb = pixels[x, y]
                gray = int(rr*0.2126 + gg*0.7152 + bb*0.0722)
                pixels[x, y] = (255, 0, 0) if gray > th else (0, 0, 0)

    elif SingleBitBitMap == 2:
        for x in range(w):
            for y in range(h):
                rr, gg, bb = pixels[x, y]
                maxc = max(rr, gg, bb)
                if maxc == rr:
                    pixels[x, y] = (255, 0, 0)
                elif maxc == gg:
                    pixels[x, y] = (0, 255, 0)
                else:
                    pixels[x, y] = (0, 0, 255)

    else:
        for x in range(w):
            for y in range(h):
                rr, gg, bb = pixels[x, y]
                pixels[x, y] = (Quantize_8(rr), Quantize_8(gg), Quantize_4(bb))

    update_previews()


# ================= Output Files =================
def _sv_pixel_literal(mode_bits, rr, gg, bb):
    """
    Returns a SystemVerilog literal string matching the chosen mode.
    1-bit: 1'h1 (red) / 1'h0 (black)
    2-bit: 2'h1 (red), 2'h2 (green), 2'h3 (blue)
    8-bit: 8'hXX (packed RGB as earlier)
    """
    if mode_bits == 1:
        return "1'h1" if rr == 255 else "1'h0"

    if mode_bits == 2:
        if rr == 255:
            return "2'h1"
        elif gg == 255:
            return "2'h2"
        else:
            return "2'h3"

    # 8-bit
    colorbyte = (rr//32)*32 + (gg//32)*4 + (bb//64)
    return f"8'h{colorbyte:02X}"

def write_outputs():
    global imgBMP

    out_dir = ensure_output_dir()

    w, h = imgBMP.size
    px = imgBMP.load()

    # PNG
    imgBMP.save(os.path.join(out_dir, f"{FileName}_out.png"))

    # -------- MIF --------
    mif_path = os.path.join(out_dir, f"{FileName}.mif")
    with open(mif_path, "w", encoding="utf-8") as f:
        f.write("--\n")
        f.write(f"-- Generated automatically by BMPConverter_V21.py ({datetime.now().strftime('%Y-%m-%d %H:%M:%S')})\n")
        f.write("--\n")
        f.write(f"DEPTH = {w*h};\n")
        f.write(f"WIDTH = {SingleBitBitMap};\n")
        f.write("ADDRESS_RADIX = HEX;\n")
        f.write("DATA_RADIX = HEX;\n")
        f.write("CONTENT BEGIN\n")

        digits = ((w*h - 1).bit_length() + 3) // 4

        for y in range(h):
            for x in range(w):
                addr = hex(y*w + x)[2:].upper().zfill(digits)

                if SingleBitBitMap == 1:
                    val = 1 if px[x, y][0] == 255 else 0
                    f.write(f"{addr}: {val:01X};\n")

                elif SingleBitBitMap == 2:
                    rr, gg, bb = px[x, y]
                    if rr == 255:
                        code = 0x1
                    elif gg == 255:
                        code = 0x2
                    else:
                        code = 0x3
                    f.write(f"{addr}: {code:01X};\n")

                else:
                    rr, gg, bb = px[x, y]
                    colorbyte = (rr//32)*32 + (gg//32)*4 + (bb//64)
                    f.write(f"{addr}: {colorbyte:02X};\n")

        f.write("END;\n")

    # -------- SV (REAL bitmap array) --------
    sv_path = os.path.join(out_dir, f"{FileName}BitMap.SV")
    with open(sv_path, "w", encoding="utf-8") as f:
        f.write("// Auto-generated bitmap\n")
        f.write(f"// Mode: {SingleBitBitMap}-bit\n\n")

        f.write(f"localparam int OBJECT_WIDTH_X = {w};\n")
        f.write(f"localparam int OBJECT_HEIGHT_Y = {h};\n\n")
        if SingleBitBitMap != 1:
            f.write(f"logic [0:OBJECT_HEIGHT_Y-1][0:OBJECT_WIDTH_X-1][{SingleBitBitMap-1}:0] object_colors = {{\n")
        else:
            f.write(f"logic [0:OBJECT_HEIGHT_Y-1][0:OBJECT_WIDTH_X-1] object_colors = {{\n")
        for y in range(h):
            row_vals = []
            for x in range(w):
                rr, gg, bb = px[x, y]
                row_vals.append(_sv_pixel_literal(SingleBitBitMap, rr, gg, bb))
            row_str = ",".join(row_vals)

            if y < h - 1:
                f.write(f"\t{{{row_str}}},\n")
            else:
                f.write(f"\t{{{row_str}}}\n")

        f.write("};\n")

    # -------- LOG --------
    log_path = os.path.join(out_dir, "log.txt")
    with open(log_path, "w", encoding="utf-8") as log:
        log.write(f"File: {FileName}\n")
        log.write(f"Time: {datetime.now()}\n")
        log.write(f"Mode: {SingleBitBitMap}-bit\n")
        log.write(f"Resolution: {w}x{h}\n")
        log.write(f"Output dir: {out_dir}\n")

    # close program as requested
    root.destroy()


# ================= Main =================
root = Tk()
root.geometry(root_geometry_size)
root.title("BMPConverter V21")
Label(root, text="BMPConverter V21\n(c) Technion IIT 2025").pack()

init_preview_labels()
open_img()

root.mainloop()
