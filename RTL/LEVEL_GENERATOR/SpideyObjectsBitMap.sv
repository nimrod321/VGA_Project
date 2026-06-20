// Spidey Objects Matrix Bitmap 
// Replaces HartsMatrixBitMap.sv
// (c) Technion IIT, Department of Electrical Engineering 2026

module SpideyObjectsBitMap #(
    parameter int NUM_TOTAL_OBJECTS = 15 // How many items to spawn per level
)(  
    input  logic        clk,
    input  logic        resetN,
    input  logic        play_enable,
    input  logic [10:0] offsetX,         // offset from top left position of the play area
    input  logic [10:0] offsetY,
    input  logic        InsideRectangle, // input that the pixel is within the main play area
    input  logic        start_level,     // Pulse to generate level
    input  logic        startOfFrame,    // Trigger to update animation/movement
    input  logic [3:0]  current_level,   // From game_state_controller
    input  logic        collision_Web_Object, // Collision input
	
    output logic        objectsDrawingRequest,  // output that the pixel should be displayed
    output logic [7:0]  objectsRGB,          	// rgb value from the bitmap 
    output logic [2:0]  id_code,
    output logic [1:0]  weight
);

    localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF;

    // -----------------------------------------------------------------------
    // Memory Pointers directly to .mif files
    // -----------------------------------------------------------------------
    (* ram_init_file = "MIF/cop.mif" *)         	logic [7:0] mem_cop1 [0:1023];
    (* ram_init_file = "MIF/robber_stand.mif" *) 	logic [7:0] mem_rob_stand [0:1023];
    (* ram_init_file = "MIF/maryjane.mif" *)     	logic [7:0] mem_maryjane [0:1023];
    (* ram_init_file = "MIF/riddler.mif" *)      	logic [7:0] mem_riddler [0:1023];
    (* ram_init_file = "MIF/goblin.mif" *)       	logic [7:0] mem_goblin [0:1023];
    
    // Level loading memory (16 levels, 16 objects max = 256 addresses)
    (* ram_init_file = "MIF/levels.mif" *)          logic [7:0] mem_levels [0:255];
    
    // -----------------------------------------------------------------------
    // Sprite List Arrays for Hardware Scaling & Movement
    // -----------------------------------------------------------------------
    logic [10:0] obj_x [0:14];
    logic [10:0] obj_y [0:14];
    logic [2:0]  obj_type [0:14];
    logic [1:0]  obj_scale [0:14]; // 0=16x16, 1=32x32, 2=64x64
    logic        obj_active [0:14];
    logic        obj_dir [0:14];   // 0=right, 1=left

    // -----------------------------------------------------------------------
    // LFSR & Random Generation Logic
    // -----------------------------------------------------------------------
    logic [15:0] lfsr;
    logic [7:0]  objects_placed;
    
    logic [5:0] rand_x; 
    logic [5:0] rand_y; 
    assign rand_x = lfsr[5:0];
    assign rand_y = lfsr[11:6];

    // Read level data synchronously
    logic [7:0] level_data;
    always_ff @(posedge clk) begin
        level_data <= mem_levels[{current_level - 4'd1, objects_placed[3:0]}];
    end

    typedef enum logic [2:0] {INIT_CLEAR, INIT_READ_ROM, INIT_SCATTER, PLAY} state_t;
    state_t state;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            state <= INIT_CLEAR;
            objects_placed <= 0;
            lfsr <= 16'hACE1; // Seed MUST be non-zero
            objectsRGB <= TRANSPARENT_ENCODING;
            objectsDrawingRequest <= 1'b0;
            id_code <= 3'd0;
            weight <= 2'd0;
            for (int i=0; i<15; i++) begin
                obj_active[i] <= 1'b0;
                obj_dir[i] <= 1'b0;
            end
        end else if (!play_enable) begin
            state <= INIT_CLEAR;
            objects_placed <= 0;
            lfsr <= 16'hACE1; // Seed MUST be non-zero
            objectsRGB <= TRANSPARENT_ENCODING;
            objectsDrawingRequest <= 1'b0;
            id_code <= 3'd0;
            weight <= 2'd0;
            for (int i=0; i<15; i++) begin
                obj_active[i] <= 1'b0;
                obj_dir[i] <= 1'b0;
            end
        end else begin
            // 1. Shift the LFSR
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

            // 2. VGA Output Logic (Pipeline)
            objectsRGB <= TRANSPARENT_ENCODING; 
            objectsDrawingRequest <= 1'b0;
            id_code <= 3'd0;
            weight <= 2'd0;

            if (state == PLAY && InsideRectangle) begin
                logic hit_found;
                logic [3:0] hit_index;
                hit_found = 1'b0;
                hit_index = 0;
                
                // Find if we are inside any active object
                for (int i=14; i>=0; i--) begin
                    if (obj_active[i]) begin
                        int size;
                        size = (obj_scale[i] == 0) ? 32 : ((obj_scale[i] == 1) ? 64 : 128);
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
                    logic [4:0]  tex_x, tex_y;
                    logic [9:0]  tex_addr;
                    logic [7:0]  hit_color;
                    logic [7:0]  color_cop, color_robber, color_maryjane, color_riddler, color_goblin;
                    
                    local_x = offsetX - obj_x[hit_index];
                    local_y = offsetY - obj_y[hit_index];
                    
                    if (obj_scale[hit_index] == 0) begin
                        tex_x = local_x[4:0]; tex_y = local_y[4:0];
                    end else if (obj_scale[hit_index] == 1) begin
                        tex_x = local_x[5:1]; tex_y = local_y[5:1];
                    end else begin
                        tex_x = local_x[6:2]; tex_y = local_y[6:2];
                    end
                    
                    // If moving left, flip the X coordinate horizontally for the sprite so he faces left!
                    if (obj_dir[hit_index] == 1'b1) begin
                        tex_x = 5'd31 - tex_x;
                    end
                    
                    tex_addr = {tex_y, tex_x}; 
                    
                    color_cop    = mem_cop1[tex_addr];
                    color_robber = mem_rob_stand[tex_addr];
                    color_maryjane = mem_maryjane[tex_addr];
                    color_riddler = mem_riddler[tex_addr];
                    color_goblin = mem_goblin[tex_addr];

                    case (obj_type[hit_index])
                        3'd1: hit_color = color_cop;
                        3'd2: hit_color = color_robber;
                        3'd3: hit_color = color_maryjane;
                        3'd4: hit_color = color_riddler;
                        3'd5: hit_color = color_goblin;
                        default: hit_color = TRANSPARENT_ENCODING;
                    endcase
                    
                    if (hit_color != TRANSPARENT_ENCODING) begin
                        objectsRGB <= hit_color;
                        objectsDrawingRequest <= 1'b1;
                        id_code <= obj_type[hit_index];
                        weight <= obj_scale[hit_index] + 2'd1; // ALWAYS output pure visual scale
                    end
                end
            end

            // 3. Object Management State Machine
            case (state)
                INIT_CLEAR: begin
                    objects_placed <= 0;
                    for (int i=0; i<15; i++) obj_active[i] <= 1'b0;
                    state <= INIT_READ_ROM;
                end
                
                INIT_READ_ROM: begin
                    // Wait one clock cycle for level_data to become valid
                    if (objects_placed < NUM_TOTAL_OBJECTS) begin
                        state <= INIT_SCATTER;
                    end else begin
                        state <= PLAY;
                    end
                end
                
                INIT_SCATTER: begin
                    logic [2:0] t_type;
                    logic [1:0] t_scale;
                    logic t_active;
                    logic [5:0] max_x, max_y;
                    logic overlap;
                    int size_t, size_i;
                    
                    t_type = level_data[2:0];
                    t_scale = level_data[4:3];
                    t_active = level_data[5];
                    
                    if (!t_active) begin
                        objects_placed <= objects_placed + 1;
                        state <= INIT_READ_ROM;
                    end else begin
                        max_x = (t_scale == 2) ? 6'd36 : ((t_scale == 1) ? 6'd38 : 6'd39);
                        max_y = (t_scale == 2) ? 6'd26 : ((t_scale == 1) ? 6'd28 : 6'd29);
                        
                        // Spawn zones logic
                        if ( ((rand_x <= 16 && rand_y >= 14) || 
                              (rand_x >= 17 && rand_x <= 23 && rand_y >= 19) || 
                              (rand_x >= 24 && rand_y >= 14)) && 
                             rand_x <= max_x && rand_y <= max_y ) begin
                             
                            overlap = 1'b0;
                            size_t = (t_scale == 0) ? 32 : ((t_scale == 1) ? 64 : 128);
                            
                            for (int i=0; i<15; i++) begin
                                if (i < objects_placed) begin
                                    size_i = (obj_scale[i] == 0) ? 32 : ((obj_scale[i] == 1) ? 64 : 128);
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
                                obj_dir[objects_placed] <= lfsr[0]; // Random initial direction
                                objects_placed <= objects_placed + 1;
                                state <= INIT_READ_ROM;
                            end
                        end
                    end
                end

                PLAY: begin
                    if (start_level) begin
                        state <= INIT_CLEAR;
                    end
                    
                    // GOBLIN MOVEMENT AND DESTRUCTION
                    if (startOfFrame) begin
                        for (int i=0; i<15; i++) begin
                            if (obj_active[i] && obj_type[i] == 3'd6) begin // Goblin ID is 6
                                // Move Horizontal
                                if (obj_dir[i] == 1'b0) begin // Right
                                    obj_x[i] <= obj_x[i] + 2;
                                    if (obj_x[i] >= 640 - 32) obj_dir[i] <= 1'b1; // Bounce left
                                end else begin // Left
                                    obj_x[i] <= obj_x[i] - 2;
                                    if (obj_x[i] <= 2) obj_dir[i] <= 1'b0; // Bounce right
                                end
                                
                                // Destroy other items
                                for (int j=0; j<15; j++) begin
                                    if (i != j && obj_active[j]) begin
                                        int size_i, size_j;
                                        size_i = (obj_scale[i] == 0) ? 32 : ((obj_scale[i] == 1) ? 64 : 128);
                                        size_j = (obj_scale[j] == 0) ? 32 : ((obj_scale[j] == 1) ? 64 : 128);
                                        
                                        // Overlap detection
                                        if (obj_x[i] < obj_x[j] + size_j && obj_x[i] + size_i > obj_x[j] &&
                                            obj_y[i] < obj_y[j] + size_j && obj_y[i] + size_i > obj_y[j]) begin
                                            obj_active[j] <= 1'b0; // BOOM!
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    if (collision_Web_Object && InsideRectangle) begin
                        // Hook collision
                        for (int i=0; i<15; i++) begin
                            if (obj_active[i]) begin
                                int size;
                                size = (obj_scale[i] == 0) ? 32 : ((obj_scale[i] == 1) ? 64 : 128);
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
