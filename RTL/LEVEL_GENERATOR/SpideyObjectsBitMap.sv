// Spidey Objects Matrix Bitmap 
// Replaces HartsMatrixBitMap.sv
// (c) Technion IIT, Department of Electrical Engineering 2026

module SpideyObjectsBitMap #(
    parameter int NUM_TOTAL_OBJECTS = 15 // How many items to spawn per level
)(  
    input  logic        clk,
    input  logic        resetN,
    input  logic [10:0] offsetX,         // offset from top left position of the play area
    input  logic [10:0] offsetY,
    input  logic        InsideRectangle, // input that the pixel is within the main play area
    input  logic        start_level,     // Pulse to generate level
    input  logic        collision_Web_Object, // Collision input
	
    output logic        objectsDrawingRequest,  // output that the pixel should be displayed
    output logic [7:0]  objectsRGB           	// rgb value from the bitmap 
);

    localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF;

    // -----------------------------------------------------------------------
    // Memory Pointers directly to .mif files
    // -----------------------------------------------------------------------
    (* ram_init_file = "MIF/cop.mif" *)         	logic [7:0] mem_cop1 [0:255];
    (* ram_init_file = "MIF/robber_stand.mif" *) 	logic [7:0] mem_rob_stand [0:255];
    (* ram_init_file = "MIF/robber_run.mif" *)   	logic [7:0] mem_rob_run [0:255];
    (* ram_init_file = "MIF/maryjane.mif" *)     	logic [7:0] mem_maryjane [0:255];
    
    // -----------------------------------------------------------------------
    // Sprite List Arrays for Hardware Scaling
    // -----------------------------------------------------------------------
    logic [10:0] obj_x [0:14];
    logic [10:0] obj_y [0:14];
    logic [2:0]  obj_type [0:14];
    logic [1:0]  obj_scale [0:14]; // 0=16x16, 1=32x32, 2=64x64
    logic        obj_active [0:14];

    // -----------------------------------------------------------------------
    // LFSR (Linear-Feedback Shift Register) & Random Generation Logic
    // -----------------------------------------------------------------------
    logic [15:0] lfsr;
    logic [7:0]  objects_placed;
    
    // Wires to extract raw binary values from the LFSR
    logic [5:0] rand_x;    // Values 0 to 63
    logic [5:0] rand_y;    // Values 0 to 63

    assign rand_x = lfsr[5:0];
    assign rand_y = lfsr[11:6];

    typedef enum logic [1:0] {INIT_CLEAR, INIT_SCATTER, PLAY} state_t;
    state_t state;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            state <= INIT_CLEAR;
            objects_placed <= 0;
            lfsr <= 16'hACE1; // Seed MUST be non-zero for LFSR to work
            objectsRGB <= TRANSPARENT_ENCODING;
            objectsDrawingRequest <= 1'b0;
            for (int i=0; i<15; i++) obj_active[i] <= 1'b0;
            
        end else begin
            // 1. Shift the LFSR every clock cycle for continuous randomness
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

            // 2. VGA Output Logic (Pipeline)
            objectsRGB <= TRANSPARENT_ENCODING; 
            objectsDrawingRequest <= 1'b0;

            if (state == PLAY && InsideRectangle) begin
                logic hit_found;
                logic [3:0] hit_index;
                hit_found = 1'b0;
                hit_index = 0;
                
                // Find if we are inside any active object
                // Loop backwards so lower index = drawn on top
                for (int i=14; i>=0; i--) begin
                    if (obj_active[i]) begin
                        int size;
                        size = (obj_scale[i] == 0) ? 16 : ((obj_scale[i] == 1) ? 32 : 64);
                        if (offsetX >= obj_x[i] && offsetX < obj_x[i] + size &&
                            offsetY >= obj_y[i] && offsetY < obj_y[i] + size) begin
                            hit_found = 1'b1;
                            hit_index = i[3:0];
                        end
                    end
                end
                
                if (hit_found) begin
                    logic [10:0] local_x;
                    logic [10:0] local_y;
                    logic [3:0]  tex_x, tex_y;
                    logic [7:0]  tex_addr;
                    logic [7:0]  hit_color;
                    
                    local_x = offsetX - obj_x[hit_index];
                    local_y = offsetY - obj_y[hit_index];
                    
                    // Hardware Scaling logic
                    if (obj_scale[hit_index] == 0) begin
                        tex_x = local_x[3:0]; tex_y = local_y[3:0];
                    end else if (obj_scale[hit_index] == 1) begin
                        tex_x = local_x[4:1]; tex_y = local_y[4:1];
                    end else begin
                        tex_x = local_x[5:2]; tex_y = local_y[5:2];
                    end
                    
                    // Combine 4-bit Y and 4-bit X into an 8-bit memory pointer (0 to 255)
                    tex_addr = {tex_y, tex_x}; 
                    
                    // Pull the exact color from the appropriate .mif memory
                    case (obj_type[hit_index])
                        3'd1: hit_color = mem_cop1[tex_addr];
                        3'd2: hit_color = mem_rob_stand[tex_addr];
                        3'd3: hit_color = mem_rob_run[tex_addr];
                        3'd4: hit_color = mem_maryjane[tex_addr];
                        default: hit_color = TRANSPARENT_ENCODING;
                    endcase
                    
                    if (hit_color != TRANSPARENT_ENCODING) begin
                        objectsRGB <= hit_color;
                        objectsDrawingRequest <= 1'b1;
                    end
                end
            end

            // 3. Object Management State Machine
            case (state)
                INIT_CLEAR: begin
                    objects_placed <= 0;
                    for (int i=0; i<15; i++) obj_active[i] <= 1'b0;
                    state <= INIT_SCATTER;
                end
                
                INIT_SCATTER: begin
                    if (objects_placed < NUM_TOTAL_OBJECTS) begin
                        // Target type and scale LUT
                        logic [2:0] t_type;
                        logic [1:0] t_scale;
                        logic [5:0] max_x, max_y;
                        logic overlap;
                        int size_t, size_i;
                        
                        // =====================================================================
                        // 🎮 LEVEL DESIGNER CONFIGURATION 🎮
                        // This case statement is where you decide exactly how many of each 
                        // object spawn on the screen! You can change t_type to spawn different 
                        // characters, and t_scale to make them bigger or smaller.
                        // Make sure you have exactly NUM_TOTAL_OBJECTS (15) cases!
                        // =====================================================================
                        case (objects_placed)
                            8'd0:  begin t_type = 3'd4; t_scale = 2'd0; end // Maryjane
                            8'd1:  begin t_type = 3'd1; t_scale = 2'd0; end // Cop
                            8'd2:  begin t_type = 3'd1; t_scale = 2'd0; end // Cop
                            8'd3:  begin t_type = 3'd1; t_scale = 2'd0; end // Cop
                            8'd4:  begin t_type = 3'd2; t_scale = 2'd0; end // Robber Stand
                            8'd5:  begin t_type = 3'd2; t_scale = 2'd0; end // Robber Stand
                            8'd6:  begin t_type = 3'd2; t_scale = 2'd0; end // Robber Stand
                            8'd7:  begin t_type = 3'd3; t_scale = 2'd0; end // Robber Run
                            8'd8:  begin t_type = 3'd3; t_scale = 2'd2; end // Robber Run
                            8'd9:  begin t_type = 3'd3; t_scale = 2'd0; end // Robber Run
                            8'd10: begin t_type = 3'd1; t_scale = 2'd0; end // Cop
                            8'd11: begin t_type = 3'd1; t_scale = 2'd0; end // Cop
                            8'd12: begin t_type = 3'd3; t_scale = 2'd0; end // Robber Run
                            8'd13: begin t_type = 3'd3; t_scale = 2'd1; end // Robber Run
                            8'd14: begin t_type = 3'd2; t_scale = 2'd0; end // Robber Stand
                            default: begin t_type = 3'd1; t_scale = 2'd0; end
                        endcase
                        
                        // Check screen bounds based on scale
                        max_x = (t_scale == 2) ? 6'd36 : ((t_scale == 1) ? 6'd38 : 6'd39);
                        max_y = (t_scale == 2) ? 6'd26 : ((t_scale == 1) ? 6'd28 : 6'd29);
                        
                        if ((rand_x <= 12 || rand_x >= 27) && rand_x <= max_x && rand_y >= 15 && rand_y <= max_y) begin
                            // Check overlap with already placed objects
                            overlap = 1'b0;
                            size_t = (t_scale == 0) ? 16 : ((t_scale == 1) ? 32 : 64);
                            
                            for (int i=0; i<15; i++) begin
                                if (i < objects_placed) begin
                                    size_i = (obj_scale[i] == 0) ? 16 : ((obj_scale[i] == 1) ? 32 : 64);
                                    if ((rand_x*16) < obj_x[i] + size_i && 
                                        (rand_x*16) + size_t > obj_x[i] &&
                                        (rand_y*16) < obj_y[i] + size_i && 
                                        (rand_y*16) + size_t > obj_y[i]) begin
                                        overlap = 1'b1;
                                    end
                                end
                            end
                            
                            if (!overlap) begin
                                obj_x[objects_placed] <= rand_x * 16;
                                obj_y[objects_placed] <= rand_y * 16;
                                obj_type[objects_placed] <= t_type;
                                obj_scale[objects_placed] <= t_scale;
                                obj_active[objects_placed] <= 1'b1;
                                objects_placed <= objects_placed + 1;
                            end
                        end
                    end else begin
                        state <= PLAY;
                    end
                end

                PLAY: begin
                    if (start_level) begin
                        state <= INIT_CLEAR;
                    end
                    
                    if (collision_Web_Object && InsideRectangle) begin
                        // Inactivate the object being collided with
                        for (int i=0; i<15; i++) begin
                            if (obj_active[i]) begin
                                int size;
                                size = (obj_scale[i] == 0) ? 16 : ((obj_scale[i] == 1) ? 32 : 64);
                                if (offsetX >= obj_x[i] && offsetX < obj_x[i] + size &&
                                    offsetY >= obj_y[i] && offsetY < obj_y[i] + size) begin
                                    obj_active[i] <= 1'b0;
                                end
                            end
                        end
                    end
                end
            endcase
        end
    end
endmodule