// (c) Technion IIT - Gold Miner Project
// Spider Web Sprite Module (16x16, 8-bit color)
// Unified Synchronous Pipeline (No always_comb)

module spider_web_object (
    input  logic        clk,
    input  logic        resetN,
    input  logic        play_enable,
    input  logic [10:0] pixelX,      
    input  logic [10:0] pixelY,      
    input  logic [10:0] hook_x,      
    input  logic [10:0] hook_y,      
    input  logic        web_bomb_pulse,
    input  logic        is_hooked,
    input  logic [5:0]  web_bomb_timer,

    output logic        webDrawingRequest,
    output logic [7:0]  webRGB
);

    logic [10:0] sprite_width;
    logic [10:0] sprite_height;
    logic [10:0] offset_x;
    logic [10:0] offset_y;
    logic [1:0]  shift_amount;

    logic        web_bomb_active;

    // ====================================================
    // Bounding Box Math (Continuous Assignment)
    // ====================================================
    logic [10:0] raw_local_x;
    logic [10:0] raw_local_y;
    
    assign raw_local_x = pixelX - hook_x + offset_x;
    assign raw_local_y = pixelY - hook_y + offset_y;

    logic in_zone;
    assign in_zone = (raw_local_x < sprite_width) && (raw_local_y < sprite_height);

    always_comb begin
        sprite_width  = 11'd16;
        sprite_height = 11'd16;
        offset_x      = 11'd8;
        offset_y      = 11'd8;
        shift_amount  = 2'd0;

        if (web_bomb_active) begin
            if (web_bomb_timer >= 50) begin
                sprite_width  = 11'd32;
                sprite_height = 11'd32;
                offset_x      = 11'd16;
                offset_y      = 11'd16;
                shift_amount  = 2'd1;
            end else if (web_bomb_timer >= 20) begin
                sprite_width  = 11'd64;
                sprite_height = 11'd64;
                offset_x      = 11'd32;
                offset_y      = 11'd32;
                shift_amount  = 2'd2;
            end else if (web_bomb_timer >= 1) begin
                sprite_width  = 11'd32;
                sprite_height = 11'd32;
                offset_x      = 11'd16;
                offset_y      = 11'd16;
                shift_amount  = 2'd1;
            end
        end
    end

    logic [3:0] scaled_y;
    logic [3:0] scaled_x;
    always_comb begin
        case (shift_amount)
            2'd1: begin
                scaled_y = raw_local_y[4:1];
                scaled_x = raw_local_x[4:1];
            end
            2'd2: begin
                scaled_y = raw_local_y[5:2];
                scaled_x = raw_local_x[5:2];
            end
            default: begin
                scaled_y = raw_local_y[3:0];
                scaled_x = raw_local_x[3:0];
            end
        endcase
    end

    // ====================================================
    // M10K ROM Instantiation (16x16 layout)
    // ====================================================
    // Depth: 16. Width: 128 (16 pixels * 8 bits)
    (* ram_init_file = "MIF/spider_web.mif" *) logic [127:0] memory [0:15];
    
    // Internal registers
    logic [127:0] current_row;
    logic [3:0]   local_x_d;    // 4 bits covers 0-15
    logic         in_zone_d;

    // ====================================================
    // ONE Unified Synchronous Block
    // ====================================================
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            current_row       <= 128'b0;
            local_x_d         <= 4'b0;
            in_zone_d         <= 1'b0;
            webDrawingRequest <= 1'b0;
            webRGB            <= 8'h00;
            web_bomb_active   <= 1'b0;
        end else if (!play_enable) begin
            current_row       <= 128'b0;
            local_x_d         <= 4'b0;
            in_zone_d         <= 1'b0;
            webDrawingRequest <= 1'b0;
            webRGB            <= 8'h00;
            web_bomb_active   <= 1'b0;
        end else begin
            
            // ------------------------------------------------
            // Control logic for web_bomb_active
            // ------------------------------------------------
            if (web_bomb_pulse) begin
                web_bomb_active <= 1'b1;
            end else if (!is_hooked || web_bomb_timer <= 0) begin
                web_bomb_active <= 1'b0;
            end

            // ------------------------------------------------
            // PIPELINE STAGE 1: Memory Fetch
            // ------------------------------------------------
            current_row <= memory[scaled_y];
            local_x_d   <= scaled_x;
            in_zone_d   <= in_zone;

            // ------------------------------------------------
            // PIPELINE STAGE 2: Output Generation
            // ------------------------------------------------
            // Slicing adjusted for 16 pixels: ((15 - X) * 8)
            if (in_zone_d && (current_row[ ((15 - local_x_d) * 8) +: 8 ] != 8'hFF)) begin
                webDrawingRequest <= 1'b1;
                webRGB            <= current_row[ ((15 - local_x_d) * 8) +: 8 ];
            end else begin
                webDrawingRequest <= 1'b0;
                webRGB            <= 8'h00; 
            end
            
        end
    end

endmodule