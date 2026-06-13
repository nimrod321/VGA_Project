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
    input  logic [15:0] score,
    input  logic [15:0] threshold,     // Goal
    input  logic [7:0]  time_left,
    input  logic [3:0]  current_level,
    input  logic        score_pulse,
    input  logic [15:0] added_score,
    
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

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            pop_active <= 1'b0;
            pop_x      <= 11'd0;
            pop_y      <= 11'd0;
            pop_timer  <= 6'd0;
            pop_val    <= 16'd0;
        end else begin
            if (score_pulse && added_score > 0) begin
                pop_active <= 1'b1;
                pop_timer  <= 6'd60;        // Display for 60 frames (1 second at 60Hz)
                pop_x      <= 11'd288;      // Centered (320 - 32)
                pop_y      <= 11'd80;       // Floating start point Y
                pop_val    <= added_score;
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
        .NUM_DIGITS(4),
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
        .NUM_DIGITS(4),
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

    // Timer Display (Top Right, Yellow, 2 Digits, 16x32 Size)
    logic        timer_draw;
    logic [7:0]  timer_rgb;
    number_display_unit #(
        .NUM_DIGITS(2),
        .DIGIT_COLOR(8'hFC), // Yellow
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

    // Level Display (Top Right underneath Timer, Yellow, 2 Digits, 16x32 Size)
    logic        level_draw;
    logic [7:0]  level_rgb;
    number_display_unit #(
        .NUM_DIGITS(2),
        .DIGIT_COLOR(8'hFC), // Yellow
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

    // Pop-up display (Dynamic floating position, Green, 4 Digits, 16x32 Size)
    logic        pop_draw;
    logic [7:0]  pop_rgb;
    logic [10:0] pop_offset_y;
    assign pop_offset_y = 11'd80 - pop_y;

    number_display_unit #(
        .NUM_DIGITS(4),
        .DIGIT_COLOR(8'h1C), // Green
        .START_X(288),
        .START_Y(80),
        .SCALE_BY_2(1'b0)
    ) pop_disp (
        .clk(clk),
        .resetN(resetN),
        .pixelX(pixelX),
        .pixelY(pixelY + pop_offset_y),
        .value(pop_val),
        .enable(pop_active),
        .drawingRequest(pop_draw),
        .RGBout(pop_rgb)
    );

    // -------------------------------------------------------------------------
    // 3. Priority Multiplexer
    // -------------------------------------------------------------------------
    always_comb begin
        hudDrawingRequest = 1'b0;
        hudRGB = 8'h00;
        
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
        end else if (pop_draw) begin
            hudDrawingRequest = 1'b1;
            hudRGB = pop_rgb;
        end
    end

endmodule
