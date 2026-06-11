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
    input  logic [2:0]  id_code,       // Determines WHICH object is drawn (1 to 6)
    input  logic [1:0]  weight,        // Determines SCALE: 1=16x16, 2=32x32, 3=64x64
    
    // Outputs to the VGA Multiplexer
    output logic        pulledDrawingRequest,
    output logic [7:0]  pulledRGBout,
    
    // Output back to the Hook System to affect pull_speed
    output logic [1:0]  pulled_weight,
    
    // Output to Score Manager
    output logic        score_pulse,
    output logic [2:0]  pulled_id  
);

    localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF;

    // -------------------------------------------------------------------------
    // 1. Dynamic Boundary & Offset Calculation
    // -------------------------------------------------------------------------
    logic [7:0] current_size;
    logic [6:0] current_offset;

    // Translate the VISUAL SCALE into physical pixel dimensions and centering offsets
    always_comb begin
        case (pulled_visual_weight)
            2'd1: begin current_size = 8'd32; current_offset = 7'd16;  end // Base size
            2'd2: begin current_size = 8'd64; current_offset = 7'd32; end // Scaled x2
            2'd3: begin current_size = 8'd128; current_offset = 7'd64; end // Scaled x4
            default: begin current_size = 8'd32; current_offset = 7'd16; end
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
    logic [4:0] rom_x;
    logic [4:0] rom_y;
    
    // Bit-shift the coordinates to trick the ROM into drawing blocks of identical pixels
    always_comb begin
        case (pulled_visual_weight)
            2'd1: begin rom_x = local_x[4:0]; rom_y = local_y[4:0]; end // No shift
            2'd2: begin rom_x = local_x[5:1]; rom_y = local_y[5:1]; end // Shift >> 1 (Divide by 2)
            2'd3: begin rom_x = local_x[6:2]; rom_y = local_y[6:2]; end // Shift >> 2 (Divide by 4)
            default: begin rom_x = local_x[4:0]; rom_y = local_y[4:0]; end
        endcase
    end

    logic [9:0] rom_address;
    assign rom_address = {rom_y, rom_x}; // Concatenate into an 8-bit address (0 to 255)

    // -------------------------------------------------------------------------
    // 4. Inline M10K ROM Declarations
    // -------------------------------------------------------------------------
    (* ram_init_file = "MIF/cop.mif" *)    				logic [7:0] mem_cop [0:1023];
    (* ram_init_file = "MIF/robber_stand.mif" *)    	logic [7:0] mem_robber [0:1023];
    (* ram_init_file = "MIF/maryjane.mif" *) 			logic [7:0] mem_maryjane [0:1023];
    (* ram_init_file = "MIF/riddler.mif" *) 			logic [7:0] mem_riddler [0:1023];
    (* ram_init_file = "MIF/goblin.mif" *) 				logic [7:0] mem_goblin [0:1023];

    logic [7:0] color_cop, color_robber, color_maryjane, color_riddler, color_goblin;
    logic [7:0] selected_pixel_color;

    // Read from all ROMs simultaneously every clock cycle
    always_ff @(posedge clk) begin
        color_cop    <= mem_cop[rom_address];
        color_robber    <= mem_robber[rom_address];
        color_maryjane <= mem_maryjane[rom_address];
        color_riddler <= mem_riddler[rom_address];
        color_goblin <= mem_goblin[rom_address];
    end

    // Multiplexer to choose the correct color wire based on the pulled_id
    always_comb begin
        case (pulled_id)
            3'd1: selected_pixel_color = color_cop;
            3'd2: selected_pixel_color = color_robber;
            3'd3: selected_pixel_color = color_robber; // Fallback to avoid transparency 
            3'd4: selected_pixel_color = color_maryjane;
            3'd5: selected_pixel_color = color_riddler;
            3'd6: selected_pixel_color = color_goblin;
            default: selected_pixel_color = TRANSPARENT_ENCODING;
        endcase
    end

    // -------------------------------------------------------------------------
    // 5. Output Pipeline & Edge Detection
    // -------------------------------------------------------------------------
    logic is_hooked_d;
    logic [1:0] last_seen_weight; // This is the VISUAL SCALE
    logic [2:0] last_seen_id;
    logic [1:0] pulled_visual_weight; // Latched visual scale!
    
    // Calculate the Physics Weight that gets exported to the Hook System!
    logic [1:0] physics_weight_calc;
    always_comb begin
        case (last_seen_id)
            3'd4: physics_weight_calc = 2'd1; // Maryjane is always light!
            3'd5: begin // Riddler has random weight (1 to 3) based on the X coordinate grab point!
                if (hook_x[2:1] == 2'd0) physics_weight_calc = 2'd1;
                else physics_weight_calc = hook_x[2:1];
            end
            3'd6: physics_weight_calc = 2'd3; // Goblin is always heavy!
            default: physics_weight_calc = last_seen_weight; // Robber/Cop weigh exactly their size
        endcase
    end
    
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            pulledRGBout         <= 8'h00;
            pulledDrawingRequest <= 1'b0;
            pulled_weight  <= 2'd0;
            is_hooked_d <= 1'b0;
            score_pulse <= 1'b0;
            pulled_id <= 3'd0;
            last_seen_weight <= 2'd0;
            last_seen_id <= 3'd0;
            pulled_visual_weight <= 2'd0;
        end 
        else begin
            is_hooked_d <= is_hooked;
            
            // Constantly track the last valid object scanned by the VGA beam (this gives us the ID and Visual Scale)
            if (id_code != 0 && weight != 0) begin
                last_seen_weight <= weight;
                last_seen_id <= id_code;
            end
            
            // Latch the exact object we hit on the rising edge of the hook!
            if (is_hooked && !is_hooked_d) begin
                pulled_weight <= physics_weight_calc; // Output the physics weight to the Hook!
                pulled_id <= last_seen_id;
                pulled_visual_weight <= last_seen_weight; // Lock in the visual size!
            end 
            else if (!is_hooked) begin
                pulled_weight <= 2'd0; // Empty hook = 0 weight
                pulled_id <= 3'd0;
                pulled_visual_weight <= 2'd0;
            end
            
            // Generate score pulse exactly when hook fully retracts (falling edge)
            if (is_hooked_d && !is_hooked) begin
                score_pulse <= 1'b1;
            end else begin
                score_pulse <= 1'b0;
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