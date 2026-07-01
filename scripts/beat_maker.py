import sys

# Mapping standard musical notes to the FPGA's JukeBox1.sv enums
note_map = {
    'c': 'do_',
    'c#': 'doD',
    'd': 're',
    'd#': 'reD',
    'e': 'mi',
    'f': 'fa',
    'f#': 'faD',
    'g': 'sol',
    'g#': 'solD',
    'a': 'la',
    'a#': 'laD',
    'b': 'si',
    'c_h': 'do_H', # High C
    'c#_h': 'doDH', # High C#
    'd_h': 're_H', # High D
    'rest': 'silence'
}

def generate_sv_beat(melody_string):
    """
    Parses a melody string and generates SystemVerilog code for JukeBox1.sv
    Example input: "c:2 d:2 e:4 rest:1 c_h:4"
    Format is note:length (where length is the number of beats)
    """
    notes = melody_string.strip().lower().split()
    
    if len(notes) > 50:
        print("WARNING: JukeBox1.sv only supports up to 50 notes! Truncating...")
        notes = notes[:50]
        
    print(f"// Generated {len(notes)} notes")
    
    for i, token in enumerate(notes):
        try:
            note_str, length_str = token.split(':')
            sv_note = note_map[note_str]
            sv_len = int(length_str)
            print(f"    frq[{i:<2}] = {sv_note:<7}; len[{i:<2}] = {sv_len:<2} ;")
        except Exception as e:
            print(f"// ERROR parsing token '{token}': {e}")
            return
            
    # Always append the end-of-melody marker
    end_idx = len(notes)
    if end_idx < 50:
        print(f"    frq[{end_idx:<2}] = do_     ; len[{end_idx:<2}] = 0  ; // End of melody marker")
    else:
        print(f"// Warning: Max capacity reached. Set len[49] = 0 manually to end melody early if needed.")

if __name__ == "__main__":
    print("=== FPGA Beat Maker ===")
    print("Available notes: " + ", ".join(note_map.keys()))
    print("Format: <note>:<beats> (e.g., c:4 d:2 e:2 rest:4 c_h:8)")
    print("Type 'exit' to quit.\n")
    
    while True:
        try:
            user_input = input("Enter your beat string: ")
            if user_input.lower() in ['exit', 'quit']:
                break
            if user_input.strip():
                print("\n--- Copy this into JukeBox1.sv ---")
                generate_sv_beat(user_input)
                print("----------------------------------\n")
        except KeyboardInterrupt:
            break
