// (c) Technion IIT, Department of Electrical Engineering 2026
// HUD Drawer - Manages on-screen displays for Score, Goal, Timer, Level, and Floating Pop-up Score

module hud_drawer (
    input  logic        clk,
    input  logic        resetN,
    
    // VGA Beam Coordinates
    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,
    input  logic        startOfFrame,
    
    // Game State Data
    input  logic [1:0]  current_state,
    input  logic [15:0] score,
    input  logic [15:0] threshold,     // Goal
    input  logic [7:0]  time_left,
    input  logic [3:0]  current_level,
    input  logic        score_pulse,
    input  logic [15:0] added_score,
    input  logic        is_penalty,
    input  logic [1:0]  saved_powerup,
    input  logic [2:0]  slowdown_cooldown,
    
    // Outputs
    output logic        hudDrawingRequest,
    output logic [7:0]  hudRGB
);

    // -------------------------------------------------------------------------
    // 1. Pop-up Animation logic
    // -------------------------------------------------------------------------
    logic        pop_active;
    logic [10:0] pop_x;
    logic [10:0] pop_y;
    logic [5:0]  pop_timer;
    logic [15:0] pop_val;

    logic        pop_is_penalty;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            pop_active <= 1'b0;
            pop_x      <= 11'd0;
            pop_y      <= 11'd0;
            pop_timer  <= 6'd0;
            pop_val    <= 16'd0;
            pop_is_penalty <= 1'b0;
        end else begin
            if (score_pulse && added_score > 0) begin
                pop_active <= 1'b1;
                pop_timer  <= 6'd60;        // Display for 60 frames (1 second at 60Hz)
                pop_x      <= 11'd288;      // Centered (320 - 32)
                pop_y      <= 11'd80;       // Floating start point Y
                pop_val    <= added_score;
                pop_is_penalty <= is_penalty;
            end else if (pop_active && startOfFrame) begin
                if (pop_timer > 0) begin
                    pop_timer <= pop_timer - 1'b1;
                    pop_y     <= pop_y - 1'b1; // Float upwards
                end else begin
                    pop_active <= 1'b0;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // 2. Instantiate display units
    // -------------------------------------------------------------------------
    
    // Score Display (Top Left, Cyan, 4 Digits, 16x32 Size)
    logic        score_draw;
    logic [7:0]  score_rgb;
    number_display_unit #(
        .NUM_DIGITS(5),
        .DIGIT_COLOR(8'h1F), // Cyan
        .START_X(20),
        .START_Y(16),
        .SCALE_BY_2(1'b0)
    ) score_disp (
        .clk(clk),
        .resetN(resetN),
        .pixelX(pixelX),
        .pixelY(pixelY),
        .value(score),
        .enable(1'b1),
        .drawingRequest(score_draw),
        .RGBout(score_rgb)
    );

    // Goal Display (Top Left underneath Score, Cyan, 4 Digits, 16x32 Size)
    logic        goal_draw;
    logic [7:0]  goal_rgb;
    number_display_unit #(
        .NUM_DIGITS(5),
        .DIGIT_COLOR(8'h1F), // Cyan
        .START_X(20),
        .START_Y(56),       // 16 + 32 + 8 gap
        .SCALE_BY_2(1'b0)
    ) goal_disp (
        .clk(clk),
        .resetN(resetN),
        .pixelX(pixelX),
        .pixelY(pixelY),
        .value(threshold),
        .enable(1'b1),
        .drawingRequest(goal_draw),
        .RGBout(goal_rgb)
    );

    // Timer Display (Top Right, Cyan, 2 Digits, 16x32 Size)
    logic        timer_draw;
    logic [7:0]  timer_rgb;
    number_display_unit #(
        .NUM_DIGITS(2),
        .DIGIT_COLOR(8'h1F), // Cyan
        .START_X(588),
        .START_Y(16),
        .SCALE_BY_2(1'b0)
    ) timer_disp (
        .clk(clk),
        .resetN(resetN),
        .pixelX(pixelX),
        .pixelY(pixelY),
        .value({8'd0, time_left}),
        .enable(1'b1),
        .drawingRequest(timer_draw),
        .RGBout(timer_rgb)
    );

    // Level Display (Top Right underneath Timer, Cyan, 2 Digits, 16x32 Size)
    logic        level_draw;
    logic [7:0]  level_rgb;
    number_display_unit #(
        .NUM_DIGITS(2),
        .DIGIT_COLOR(8'h1F), // Cyan
        .START_X(588),
        .START_Y(56),       // 16 + 32 + 8 gap
        .SCALE_BY_2(1'b0)
    ) level_disp (
        .clk(clk),
        .resetN(resetN),
        .pixelX(pixelX),
        .pixelY(pixelY),
        .value({12'd0, current_level}),
        .enable(1'b1),
        .drawingRequest(level_draw),
        .RGBout(level_rgb)
    );

    // Pop-up display (Green)
    logic        pop_draw_green;
    logic [7:0]  pop_rgb_green;
    logic [10:0] pop_offset_y;
    assign pop_offset_y = 11'd80 - pop_y;

    number_display_unit #(
        .NUM_DIGITS(4),
        .DIGIT_COLOR(8'h1C), // Green
        .START_X(288),
        .START_Y(80),
        .SCALE_BY_2(1'b0)
    ) pop_disp_green (
        .clk(clk),
        .resetN(resetN),
        .pixelX(pixelX),
        .pixelY(pixelY + pop_offset_y),
        .value(pop_val),
        .enable(pop_active && !pop_is_penalty),
        .drawingRequest(pop_draw_green),
        .RGBout(pop_rgb_green)
    );

    // Pop-up display (Red)
    logic        pop_draw_red;
    logic [7:0]  pop_rgb_red;

    number_display_unit #(
        .NUM_DIGITS(4),
        .DIGIT_COLOR(8'hE0), // Red
        .START_X(288),
        .START_Y(80),
        .SCALE_BY_2(1'b0)
    ) pop_disp_red (
        .clk(clk),
        .resetN(resetN),
        .pixelX(pixelX),
        .pixelY(pixelY + pop_offset_y),
        .value(pop_val),
        .enable(pop_active && pop_is_penalty),
        .drawingRequest(pop_draw_red),
        .RGBout(pop_rgb_red)
    );

    // -------------------------------------------------------------------------
    // 2b. HUD Inventory Icon ROMs & Display Logic (Top Left Offset, X=250, Y=16)
    // -------------------------------------------------------------------------
    logic [7:0] q_clock, q_bomb, q_scissors;
    logic [9:0] icon_addr;
    
    // Address mapping for 32x32 icon centered at X=250, Y=16
    assign icon_addr = ((pixelY - 16) << 5) + (pixelX - 250);
    
    altsyncram #(.operation_mode("ROM"), .width_a(8), .widthad_a(10), .numwords_a(1024), .init_file("MIF/icon_clock_32x32.mif"), .intended_device_family("Cyclone V"))
        rom_hud_clock (.clock0(clk), .address_a(icon_addr), .q_a(q_clock));

    altsyncram #(.operation_mode("ROM"), .width_a(8), .widthad_a(10), .numwords_a(1024), .init_file("MIF/icon_bomb_32x32.mif"), .intended_device_family("Cyclone V"))
        rom_hud_bomb (.clock0(clk), .address_a(icon_addr), .q_a(q_bomb));

    altsyncram #(.operation_mode("ROM"), .width_a(8), .widthad_a(10), .numwords_a(1024), .init_file("MIF/icon_scissors_32x32.mif"), .intended_device_family("Cyclone V"))
        rom_hud_scissors (.clock0(clk), .address_a(icon_addr), .q_a(q_scissors));

    logic [7:0] active_icon_rgb;
    always_comb begin
        case (saved_powerup)
            2'd1:    active_icon_rgb = q_clock;
            2'd2:    active_icon_rgb = q_bomb;
            2'd3:    active_icon_rgb = q_scissors;
            default: active_icon_rgb = 8'h00;
        endcase
    end
    
    logic draw_hud_icon;
    assign draw_hud_icon = (current_state == 2'd1 && // Only draw in PLAY state (hidden in STORE)
                            saved_powerup != 2'd0 &&
                            pixelX >= 250 && pixelX < 282 &&
                            pixelY >= 16 && pixelY < 48 &&
                            active_icon_rgb != 8'hFF); // Skip white background

    // Shrunk Slowdown Timer Display (Below icon, Yellow/Gold, 2 Digits, 8x16 Size)
    logic        slowdown_timer_draw;
    logic [7:0]  slowdown_timer_rgb;
    number_display_unit #(
        .NUM_DIGITS(2),
        .DIGIT_COLOR(8'hFC), // Yellow/Gold
        .START_X(258),       // Centered under the 32px icon (250 + 8)
        .START_Y(52),        // Just below the icon (16 + 32 + 4 gap)
        .SHRINK_BY_2(1'b1)   // Small size!
    ) slowdown_timer_disp (
        .clk(clk),
        .resetN(resetN),
        .pixelX(pixelX),
        .pixelY(pixelY),
        .value({13'd0, slowdown_cooldown}),
        .enable(slowdown_cooldown > 0),
        .drawingRequest(slowdown_timer_draw),
        .RGBout(slowdown_timer_rgb)
    );

    // -------------------------------------------------------------------------
    // 3. Priority Multiplexer
    // -------------------------------------------------------------------------
    always_comb begin
        hudDrawingRequest = 1'b0;
        hudRGB = 8'h00;
        
        if (current_state == 2'd1 || current_state == 2'd2) begin
            if (score_draw) begin
                hudDrawingRequest = 1'b1;
                hudRGB = score_rgb;
            end else if (goal_draw) begin
                hudDrawingRequest = 1'b1;
                hudRGB = goal_rgb;
            end else if (timer_draw) begin
                hudDrawingRequest = 1'b1;
                hudRGB = timer_rgb;
            end else if (level_draw) begin
                hudDrawingRequest = 1'b1;
                hudRGB = level_rgb;
            end else if (slowdown_timer_draw) begin
                hudDrawingRequest = 1'b1;
                hudRGB = slowdown_timer_rgb;
            end else if (draw_hud_icon) begin
                hudDrawingRequest = 1'b1;
                hudRGB = active_icon_rgb;
            end else if (pop_is_penalty ? pop_draw_red : pop_draw_green) begin
                hudDrawingRequest = 1'b1;
                hudRGB = pop_is_penalty ? pop_rgb_red : pop_rgb_green;
            end
        end
    end

endmodule
