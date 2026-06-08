// (c) Technion IIT, Department of Electrical Engineering 2025 
module hook_motion_controller (
    input  logic        clk,
    input  logic        resetN,
    input  logic        startOfFrame,
    input  logic        shoot_key,     		// Pulse when '2' is pressed
    input  logic        object_collision,    // Pulse when hook tip touches an object
	 input  logic        wall_collision,    	// Pulse when hook tip touches the screen edges 
    input  logic [1:0]  grabbed_weight,		// 0 for empty, >0 for heavy objects
	 input  logic [1:0]	speed_multiplier,
    
    output logic [10:0] current_R,
    output logic        freeze_angle,   	// Tells circular_motion to stop swinging
	 output logic 			is_hooked			// Tells the pulled_object it is hooked
);

// Constants
localparam int INITIAL_R = 20;
localparam int BASE_SPEED = 4;

// States
enum logic [1:0] {ST_SWING, ST_SHOOT, ST_RETRACT} state;

// Internal variables
logic [4:0] shoot_speed;
logic [4:0] pull_speed;

assign shoot_speed = BASE_SPEED * speed_multiplier;
assign pull_speed = (BASE_SPEED - grabbed_weight) * speed_multiplier;

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        state        <= ST_SWING;
        current_R    <= INITIAL_R;
        freeze_angle <= 1'b0;
		  is_hooked    <= 1'b0;
    end else begin
        case (state)
            
            // --------------------------------
            ST_SWING: begin
            // --------------------------------
                current_R    <= INITIAL_R;
                freeze_angle <= 1'b0;
					 is_hooked    <= 1'b0;
                
                if (shoot_key) begin
                    state        <= ST_SHOOT;
                    freeze_angle <= 1'b1;
                end
            end
            
            // --------------------------------
            ST_SHOOT: begin
            // --------------------------------
               freeze_angle <= 1'b1;
					
					if (object_collision) begin
						state     <= ST_RETRACT;
						is_hooked <= 1'b1; // We caught a sprite!
					end 
					else if (wall_collision) begin
						state     <= ST_RETRACT;
						is_hooked <= 1'b0; // Hit a wall, do NOT hook anything
					end
					
               if (startOfFrame) begin
                   current_R <= current_R + shoot_speed; 
					end
            end
            
            // --------------------------------
            ST_RETRACT: begin
            // --------------------------------
                freeze_angle <= 1'b1;
                if (startOfFrame) begin
                    current_R <= current_R - pull_speed;
                    
                    // Transition back to swing when fully retracted
                    if (current_R <= INITIAL_R) begin
                        current_R <= INITIAL_R; // Snap exactly to base radius
                        state     <= ST_SWING;
								is_hooked <= 1'b0;
                    end
                end
            end
            
        endcase
    end
end

endmodule