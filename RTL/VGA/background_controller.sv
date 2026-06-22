// (c) Technion IIT, Department of Electrical Engineering 2026
// Background Controller - Switches between normal play background and store background

module background_controller (
    input  logic        clk,
    input  logic [18:0] address,            // 19-bit address for 640x480 resolution (307,200 words)
    input  logic [10:0] pixelX,             
    input  logic [10:0] pixelY,             
    input  logic [1:0]  current_state,      // 0=LOBBY, 1=PLAY, 2=STORE, 3=GAME_OVER
    input  logic        show_instructions_en, // From game_state_controller
    output logic [7:0]  bg_rgb              // 8-bit composite background color output
);

    logic [7:0] play_bg_rgb;

    // Play Background ROM (background.mif)
    altsyncram #(
        .operation_mode("ROM"),
        .width_a(8),
        .widthad_a(19),
        .numwords_a(307200),
        .init_file("MIF/background.mif"),
        .intended_device_family("Cyclone V")
    ) play_rom_inst (
        .clock0(clk),
        .address_a(address),
        .q_a(play_bg_rgb)
    );

    // Start Text ROM (512x64 = 32768 words, 1-bit wide)
    logic [0:0] start_text_bit;
    logic [14:0] start_text_address;
    
    // Position text centered X, 2/3 down Y
    localparam int START_X = 64;   // (640 - 512) / 2 = 64
    localparam int START_Y = 320;  // 480 * (2/3) = 320
    
    assign start_text_address = ((pixelY - START_Y) * 512) + (pixelX - START_X);
    
    altsyncram #(
        .operation_mode("ROM"),
        .width_a(1),
        .widthad_a(15),
        .numwords_a(32768),
        .init_file("MIF/start_text.mif"),
        .intended_device_family("Cyclone V")
    ) start_rom_inst (
        .clock0(clk),
        .address_a(start_text_address),
        .q_a(start_text_bit)
    );
    
    logic inside_start_text;
    assign inside_start_text = (current_state == 2'd0) && 
                         (pixelX >= START_X) && (pixelX < START_X + 512) &&
                         (pixelY >= START_Y) && (pixelY < START_Y + 64);

    // Game Over Text ROM (512x64 = 32768 words, 1-bit wide)
    logic [0:0] gameover_text_bit;
    logic [14:0] gameover_text_address;
    
    // Position text centered X and Y
    localparam int GAMEOVER_X = 64;   // (640 - 512) / 2 = 64
    localparam int GAMEOVER_Y = 208;  // (480 - 64) / 2 = 208
    
    assign gameover_text_address = ((pixelY - GAMEOVER_Y) * 512) + (pixelX - GAMEOVER_X);
    
    altsyncram #(
        .operation_mode("ROM"),
        .width_a(1),
        .widthad_a(15),
        .numwords_a(32768),
        .init_file("MIF/game_over_text.mif"),
        .intended_device_family("Cyclone V")
    ) gameover_rom_inst (
        .clock0(clk),
        .address_a(gameover_text_address),
        .q_a(gameover_text_bit)
    );
    
    logic inside_gameover_text;
    assign inside_gameover_text = (current_state == 2'd3) && 
                                  (pixelX >= GAMEOVER_X) && (pixelX < GAMEOVER_X + 512) &&
                                  (pixelY >= GAMEOVER_Y) && (pixelY < GAMEOVER_Y + 64);

    // Calculate 320x240 pixel-doubled address using shift-add to save DSP blocks
    // 320 = 256 + 64 = (1<<8) + (1<<6)
    logic [16:0] address_320;
    logic [9:0] py_half;
    logic [9:0] px_half;
    assign py_half = pixelY[10:1];
    assign px_half = pixelX[10:1];
    assign address_320 = (py_half << 8) + (py_half << 6) + px_half;

    // -------------------------------------------------------------
    // NEW UI BACKGROUND ROMS (Memory Efficient 320x240 pixel doubled)
    // -------------------------------------------------------------
    logic [7:0] lobby_bg_rgb;
    logic [7:0] store_bg_rgb;
    logic [7:0] instructions_bg_rgb;

    altsyncram #(
        .operation_mode("ROM"),
        .width_a(8),
        .widthad_a(17),
        .numwords_a(76800),
        .init_file("MIF/lobby_bg.mif"),
        .intended_device_family("Cyclone V")
    ) lobby_rom_inst (
        .clock0(clk),
        .address_a(address_320),
        .q_a(lobby_bg_rgb)
    );

    altsyncram #(
        .operation_mode("ROM"),
        .width_a(8),
        .widthad_a(17),
        .numwords_a(76800),
        .init_file("MIF/store_bg.mif"),
        .intended_device_family("Cyclone V")
    ) store_rom_inst (
        .clock0(clk),
        .address_a(address_320),
        .q_a(store_bg_rgb)
    );

    altsyncram #(
        .operation_mode("ROM"),
        .width_a(8),
        .widthad_a(17),
        .numwords_a(76800),
        .init_file("MIF/instructions_bg.mif"),
        .intended_device_family("Cyclone V")
    ) instructions_rom_inst (
        .clock0(clk),
        .address_a(address_320),
        .q_a(instructions_bg_rgb)
    );

    // Select background: 
    // - SHOW INSTRUCTIONS if enabled in LOBBY
    // - STORE background if in STORE state
    // - LOBBY background if in LOBBY state
    // - Overlay START text in LOBBY (black color)
    // - Overlay GAME OVER text in GAME_OVER (black color)
    // - Default to level background (play_bg_rgb)
    always_comb begin
        if (current_state == 2'd0) begin
            if (show_instructions_en) begin
                bg_rgb = instructions_bg_rgb;
            end else if (inside_start_text && start_text_bit == 1'b1) begin
                bg_rgb = 8'h00; // Black text overlay
            end else begin
                bg_rgb = lobby_bg_rgb;
            end
        end else if (current_state == 2'd2) begin
            bg_rgb = store_bg_rgb;
        end else if (inside_gameover_text && gameover_text_bit == 1'b1) begin
            bg_rgb = 8'h00; // Black text
        end else begin
            bg_rgb = play_bg_rgb;
        end
    end

endmodule
