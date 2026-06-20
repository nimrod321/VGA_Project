// (c) Technion IIT, Department of Electrical Engineering 2026
// Store Drawer - Renders prices, text labels, and the store title

module store_drawer (
    input  logic        clk,
    input  logic        resetN,
    
    // VGA Beam Coordinates
    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,
    input  logic [1:0]  current_state,
    
    // Purchase states (to hide prices when bought)
    input  logic        bought_speed,
    input  logic        bought_time,
    input  logic        bought_radius,
    input  logic        bought_slowdown,
    
    // Prices
    input  logic [15:0] speed_price,
    input  logic [15:0] time_price,
    input  logic [15:0] radius_price,
    input  logic [15:0] slow_price,
    
    // Outputs
    output logic        storeDrawingRequest,
    output logic [7:0]  storeRGB
);

    // -------------------------------------------------------------------------
    // Store Title ROM (256x64 = 16384 words, 1-bit wide)
    // -------------------------------------------------------------------------
    logic [0:0] title_bit;
    logic [13:0] title_addr;
    
    localparam int TITLE_X = 192; // (640 - 256) / 2
    localparam int TITLE_Y = 50;  // Up on the screen
    
    assign title_addr = ((pixelY - TITLE_Y) * 256) + (pixelX - TITLE_X);
    
    altsyncram #(
        .operation_mode("ROM"),
        .width_a(1),
        .widthad_a(14),
        .numwords_a(16384),
        .init_file("MIF/store_title.mif"),
        .intended_device_family("Cyclone V")
    ) rom_title (
        .clock0(clk),
        .address_a(title_addr),
        .q_a(title_bit)
    );
    
    logic draw_title;
    assign draw_title = (current_state == 2'd2 && 
                         pixelX >= TITLE_X && pixelX < TITLE_X + 256 &&
                         pixelY >= TITLE_Y && pixelY < TITLE_Y + 64 && 
                         title_bit == 1'b1);

    // -------------------------------------------------------------------------
    // Instantiate price display units & text labels
    // -------------------------------------------------------------------------
    
    // Addresses for 128x32 text ROMs
    logic [11:0] text_addr_speed;
    logic [11:0] text_addr_time;
    logic [11:0] text_addr_radius;
    logic [11:0] text_addr_slow;
    
    assign text_addr_speed  = ((pixelY - 260) * 128) + (pixelX - 50);
    assign text_addr_time   = ((pixelY - 260) * 128) + (pixelX - 190);
    assign text_addr_radius = ((pixelY - 260) * 128) + (pixelX - 330);
    assign text_addr_slow   = ((pixelY - 260) * 128) + (pixelX - 470);
    
    logic [0:0] bit_speed, bit_time, bit_radius, bit_slow;
    
    // 1. SPEED
    logic        speed_draw;
    logic [7:0]  speed_rgb;
    number_display_unit #(.NUM_DIGITS(3), .DIGIT_COLOR(8'h1C), .START_X(90), .START_Y(220), .SCALE_BY_2(1'b0)) speed_disp (
        .clk(clk), .resetN(resetN), .pixelX(pixelX), .pixelY(pixelY),
        .value(speed_price), .enable(current_state == 2'd2 && !bought_speed),
        .drawingRequest(speed_draw), .RGBout(speed_rgb)
    );
    altsyncram #(.operation_mode("ROM"), .width_a(1), .widthad_a(12), .numwords_a(4096), .init_file("MIF/store_text_speed.mif"), .intended_device_family("Cyclone V"))
        rom_speed (.clock0(clk), .address_a(text_addr_speed), .q_a(bit_speed));
    logic draw_text_speed;
    assign draw_text_speed = (current_state == 2'd2 && !bought_speed && pixelX >= 50 && pixelX < 178 && pixelY >= 260 && pixelY < 292 && bit_speed == 1'b1);

    // 2. TIME
    logic        time_draw;
    logic [7:0]  time_rgb;
    number_display_unit #(.NUM_DIGITS(3), .DIGIT_COLOR(8'hFC), .START_X(230), .START_Y(220), .SCALE_BY_2(1'b0)) time_disp (
        .clk(clk), .resetN(resetN), .pixelX(pixelX), .pixelY(pixelY),
        .value(time_price), .enable(current_state == 2'd2 && !bought_time),
        .drawingRequest(time_draw), .RGBout(time_rgb)
    );
    altsyncram #(.operation_mode("ROM"), .width_a(1), .widthad_a(12), .numwords_a(4096), .init_file("MIF/store_text_time.mif"), .intended_device_family("Cyclone V"))
        rom_time (.clock0(clk), .address_a(text_addr_time), .q_a(bit_time));
    logic draw_text_time;
    assign draw_text_time = (current_state == 2'd2 && !bought_time && pixelX >= 190 && pixelX < 318 && pixelY >= 260 && pixelY < 292 && bit_time == 1'b1);

    // 3. RADIUS
    logic        radius_draw;
    logic [7:0]  radius_rgb;
    number_display_unit #(.NUM_DIGITS(3), .DIGIT_COLOR(8'h1F), .START_X(370), .START_Y(220), .SCALE_BY_2(1'b0)) radius_disp (
        .clk(clk), .resetN(resetN), .pixelX(pixelX), .pixelY(pixelY),
        .value(radius_price), .enable(current_state == 2'd2 && !bought_radius),
        .drawingRequest(radius_draw), .RGBout(radius_rgb)
    );
    altsyncram #(.operation_mode("ROM"), .width_a(1), .widthad_a(12), .numwords_a(4096), .init_file("MIF/store_text_radius.mif"), .intended_device_family("Cyclone V"))
        rom_radius (.clock0(clk), .address_a(text_addr_radius), .q_a(bit_radius));
    logic draw_text_radius;
    assign draw_text_radius = (current_state == 2'd2 && !bought_radius && pixelX >= 330 && pixelX < 458 && pixelY >= 260 && pixelY < 292 && bit_radius == 1'b1);

    // 4. SLOWDOWN
    logic        slow_draw;
    logic [7:0]  slow_rgb;
    number_display_unit #(.NUM_DIGITS(3), .DIGIT_COLOR(8'hE0), .START_X(510), .START_Y(220), .SCALE_BY_2(1'b0)) slow_disp (
        .clk(clk), .resetN(resetN), .pixelX(pixelX), .pixelY(pixelY),
        .value(slow_price), .enable(current_state == 2'd2 && !bought_slowdown),
        .drawingRequest(slow_draw), .RGBout(slow_rgb)
    );
    altsyncram #(.operation_mode("ROM"), .width_a(1), .widthad_a(12), .numwords_a(4096), .init_file("MIF/store_text_slow.mif"), .intended_device_family("Cyclone V"))
        rom_slow (.clock0(clk), .address_a(text_addr_slow), .q_a(bit_slow));
    logic draw_text_slow;
    assign draw_text_slow = (current_state == 2'd2 && !bought_slowdown && pixelX >= 470 && pixelX < 598 && pixelY >= 260 && pixelY < 292 && bit_slow == 1'b1);


    // Combine drawing requests
    always_comb begin
        storeDrawingRequest = 1'b0;
        storeRGB = 8'h00;
        if (current_state == 2'd2) begin
            if (draw_title) begin
                storeDrawingRequest = 1'b1;
                storeRGB = 8'h00; // Black title text
            end else if (speed_draw) begin
                storeDrawingRequest = 1'b1;
                storeRGB = speed_rgb;
            end else if (time_draw) begin
                storeDrawingRequest = 1'b1;
                storeRGB = time_rgb;
            end else if (radius_draw) begin
                storeDrawingRequest = 1'b1;
                storeRGB = radius_rgb;
            end else if (slow_draw) begin
                storeDrawingRequest = 1'b1;
                storeRGB = slow_rgb;
            end else if (draw_text_speed || draw_text_time || draw_text_radius || draw_text_slow) begin
                storeDrawingRequest = 1'b1;
                storeRGB = 8'h00; // Black label text
            end
        end
    end

endmodule
