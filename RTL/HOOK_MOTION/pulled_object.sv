// (c) Technion IIT, Department of Electrical and Computer Engineering 2026
// Pulled Object Module for Gold Miner (Scalable & Inline ROM Version)

module pulled_object (
    input  logic        clk,
    input  logic        resetN,
    
    // VGA Beam Coordinates
    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,
    
    // Hook Coordinates (to anchor the sprite)
    input  logic [10:0] hook_x,
    input  logic [10:0] hook_y,
    
    // Game Logic Triggers
    input  logic        is_hooked,     // 1 when a collision happened
    input  logic [1:0]  id_code,       // Determines WHICH object is drawn (0 to 3)
    input  logic [1:0]  weight,        // Determines SCALE: 1=16x16, 2=32x32, 3=64x64
    
    // Outputs to the VGA Multiplexer
    output logic        pulledDrawingRequest,
    output logic [7:0]  pulledRGBout,
    
    // Output back to the Hook System to affect pull_speed
    output logic [1:0]  pulled_weight  
);

    localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF;

    // -------------------------------------------------------------------------
    // 1. Dynamic Boundary & Offset Calculation
    // -------------------------------------------------------------------------
    logic [6:0] current_size;
    logic [5:0] current_offset;

    // Translate the weight input into physical pixel dimensions and centering offsets
    always_comb begin
        case (weight)
            2'd1: begin current_size = 7'd16; current_offset = 6'd8;  end // Base size
            2'd2: begin current_size = 7'd32; current_offset = 6'd16; end // Scaled x2
            2'd3: begin current_size = 7'd64; current_offset = 6'd32; end // Scaled x4
            default: begin current_size = 7'd16; current_offset = 6'd8; end
        endcase
    end

    // -------------------------------------------------------------------------
    // 2. Centering & Boundary Math
    // -------------------------------------------------------------------------
    logic signed [11:0] local_x;
    logic signed [11:0] local_y;
    
    // Computes the pixel's distance relative to the hook tip using the dynamic offset
    assign local_x = pixelX - hook_x + current_offset;
    assign local_y = pixelY - hook_y + current_offset;
    
    logic inside_sprite;
    // Only flag as inside if we are within the scaled box AND an object is actually hooked
    assign inside_sprite = (local_x >= 0 && local_x < current_size && 
                            local_y >= 0 && local_y < current_size && 
                            is_hooked);

    // -------------------------------------------------------------------------
    // 3. Dynamic Scaling (Downsampling back to the 16x16 ROM address)
    // -------------------------------------------------------------------------
    logic [3:0] rom_x;
    logic [3:0] rom_y;
    
    // Bit-shift the coordinates to trick the ROM into drawing blocks of identical pixels
    always_comb begin
        case (weight)
            2'd1: begin rom_x = local_x[3:0]; rom_y = local_y[3:0]; end // No shift
            2'd2: begin rom_x = local_x[4:1]; rom_y = local_y[4:1]; end // Shift >> 1 (Divide by 2)
            2'd3: begin rom_x = local_x[5:2]; rom_y = local_y[5:2]; end // Shift >> 2 (Divide by 4)
            default: begin rom_x = local_x[3:0]; rom_y = local_y[3:0]; end
        endcase
    end

    logic [7:0] rom_address;
    assign rom_address = {rom_y, rom_x}; // Concatenate into an 8-bit address (0 to 255)

    // -------------------------------------------------------------------------
    // 4. Inline M10K ROM Declarations
    // -------------------------------------------------------------------------
    (* ram_init_file = "MIF/cop.mif" *)    				logic [7:0] mem_cop [0:255];
    (* ram_init_file = "MIF/robber_stand.mif" *)    	logic [7:0] mem_robber [0:255];
    (* ram_init_file = "MIF/robber_run.mif" *) 			logic [7:0] mem_robber_run [0:255];
    (* ram_init_file = "MIF/maryjane.mif" *) 			logic [7:0] mem_maryjane [0:255];

    logic [7:0] color_cop, color_robber, color_robber_run, color_maryjane;
    logic [7:0] selected_pixel_color;

    // Read from all ROMs simultaneously every clock cycle
    always_ff @(posedge clk) begin
        color_cop    <= mem_cop[rom_address];
        color_robber    <= mem_robber[rom_address];
        color_robber_run <= mem_robber_run[rom_address];
        color_maryjane <= mem_maryjane[rom_address];
    end

    // Multiplexer to choose the correct color wire based on the id_code
    always_comb begin
        case (id_code)
            2'd0: selected_pixel_color = color_cop;
            2'd1: selected_pixel_color = color_robber;
            2'd2: selected_pixel_color = color_robber_run;
            2'd3: selected_pixel_color = color_maryjane;
            default: selected_pixel_color = TRANSPARENT_ENCODING;
        endcase
    end

    // -------------------------------------------------------------------------
    // 5. Output Pipeline
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            pulledRGBout         <= 8'h00;
            pulledDrawingRequest <= 1'b0;
            pulled_weight  <= 2'd0;
        end 
        else begin
				
            if (is_hooked) begin
                pulled_weight <= weight; 
            end else begin
                pulled_weight <= 2'd0; // Empty hook = 0 weight
				end

            // Handle the VGA Drawing Request
            if (inside_sprite && selected_pixel_color != TRANSPARENT_ENCODING) begin
                pulledRGBout         <= selected_pixel_color;
                pulledDrawingRequest <= 1'b1;
            end else begin
                pulledRGBout         <= TRANSPARENT_ENCODING;
                pulledDrawingRequest <= 1'b0;
            end
        end
    end

endmodule