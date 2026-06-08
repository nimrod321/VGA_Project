// (c) Technion IIT - Gold Miner Project
// Spider Web Sprite Module (16x16, 8-bit color)
// Unified Synchronous Pipeline (No always_comb)

module spider_web_object (
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] pixelX,      
    input  logic [10:0] pixelY,      
    input  logic [10:0] hook_x,      
    input  logic [10:0] hook_y,      

    output logic        webDrawingRequest,
    output logic [7:0]  webRGB
);

    localparam int SPRITE_WIDTH  = 16;
    localparam int SPRITE_HEIGHT = 16;
    localparam int OFFSET_X      = 8; 
    localparam int OFFSET_Y      = 8; 

    // ====================================================
    // Bounding Box Math (Continuous Assignment)
    // ====================================================
    logic [10:0] raw_local_x;
    logic [10:0] raw_local_y;
    
    assign raw_local_x = pixelX - hook_x + OFFSET_X;
    assign raw_local_y = pixelY - hook_y + OFFSET_Y;

    logic in_zone;
    assign in_zone = (raw_local_x < SPRITE_WIDTH) && (raw_local_y < SPRITE_HEIGHT);

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
        end else begin
            
            // ------------------------------------------------
            // PIPELINE STAGE 1: Memory Fetch
            // ------------------------------------------------
            current_row <= memory[raw_local_y[3:0]];
            local_x_d   <= raw_local_x[3:0];
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