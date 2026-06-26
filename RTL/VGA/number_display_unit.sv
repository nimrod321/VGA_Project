// (c) Technion IIT, Department of Electrical Engineering 2026
// Reusable Multi-Digit Number Display Unit with Parameterized Coordinates, Scaling, and Leading-Zero Suppression

module number_display_unit #(
    parameter int NUM_DIGITS = 4,
    parameter logic [7:0] DIGIT_COLOR = 8'hFF,
    parameter int START_X = 20,
    parameter int START_Y = 16,
    parameter bit SCALE_BY_2 = 1'b0,
    parameter bit SHRINK_BY_2 = 1'b0
)(
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,
    input  logic [15:0] value,
    input  logic        enable,
    
    output logic        drawingRequest,
    output logic [7:0]  RGBout
);

    // BCD digits (up to 5 digits supported)
    logic [3:0] digit_vals [0:4];
    assign digit_vals[0] = value % 10;
    assign digit_vals[1] = (value / 10) % 10;
    assign digit_vals[2] = (value / 100) % 10;
    assign digit_vals[3] = (value / 1000) % 10;
    assign digit_vals[4] = (value / 10000) % 10;

    // Define size based on SCALE_BY_2/SHRINK_BY_2
    localparam int DIGIT_W = SCALE_BY_2 ? 32 : (SHRINK_BY_2 ? 8 : 16);
    localparam int DIGIT_H = SCALE_BY_2 ? 64 : (SHRINK_BY_2 ? 16 : 32);

    // Coordinate Math
    logic [2:0] col_idx;
    assign col_idx = (pixelX - START_X) / DIGIT_W;
    
    logic inside_digit;
    logic [3:0] active_digit;
    logic [10:0] local_offsetX;
    logic [10:0] local_offsetY;

    // Leading Zero Suppression logic
    logic [4:0] leading_zero_mask;
    
    always_comb begin
        leading_zero_mask = 5'b00000;
        if (NUM_DIGITS >= 2) begin
            // The most significant digit is a leading zero if it equals 0
            leading_zero_mask[NUM_DIGITS - 1] = (digit_vals[NUM_DIGITS - 1] == 4'd0);
            
            // Other digits are leading zeroes if they are 0 AND the digit to their left is also a leading zero
            for (int i = NUM_DIGITS - 2; i >= 1; i--) begin
                leading_zero_mask[i] = leading_zero_mask[i + 1] && (digit_vals[i] == 4'd0);
            end
        end
    end

    logic [2:0] active_digit_idx;
    
    always_comb begin
        inside_digit = 1'b0;
        active_digit = 4'd0;
        local_offsetX = 11'd0;
        local_offsetY = 11'd0;
        active_digit_idx = 3'd0;
        
        if (enable && 
            pixelY >= START_Y && pixelY < START_Y + DIGIT_H &&
            pixelX >= START_X && pixelX < START_X + (NUM_DIGITS * DIGIT_W)) begin
            
            active_digit_idx = NUM_DIGITS - 1 - col_idx;
            
            // Draw only if it's not a suppressed leading zero
            if (!leading_zero_mask[active_digit_idx]) begin
                inside_digit = 1'b1;
                local_offsetX = (pixelX - START_X) % DIGIT_W;
                local_offsetY = pixelY - START_Y;
                active_digit = digit_vals[active_digit_idx];
            end
        end
    end

    NumbersBitMap #(
        .digit_color(DIGIT_COLOR),
        .SCALE_BY_2(SCALE_BY_2),
        .SHRINK_BY_2(SHRINK_BY_2)
    ) bitmap_inst (
        .clk(clk),
        .resetN(resetN),
        .offsetX(local_offsetX),
        .offsetY(local_offsetY),
        .InsideRectangle(inside_digit),
        .digit(active_digit),
        .drawingRequest(drawingRequest),
        .RGBout(RGBout)
    );

endmodule
