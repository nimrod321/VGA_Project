// (c) Technion IIT, Department of Electrical Engineering 2025 
module hook_motion_controller (
    input  logic        clk,
    input  logic        resetN,
    input  logic        play_enable,
    input  logic        startOfFrame,
    input  logic        shoot_key,     		// Pulse when '2' is pressed
    input  logic        object_collision,    // Pulse when hook tip touches an object
	 input  logic        wall_collision,    	// Pulse when hook tip touches the screen edges 
    input  logic [1:0]  grabbed_weight,		// 0 for empty, >0 for heavy objects
	 input  logic [1:0]	speed_multiplier,
	 input  logic 			longer_radius_en, 
    input  logic        slowdown_active,
    input  logic        scissors_pulse,
    input  logic        web_bomb_pulse,
    
    output logic [10:0] current_R,
    output logic        freeze_angle,   	// Tells circular_motion to stop swinging
	 output logic 			is_hooked,			// Tells the pulled_object it is hooked
    output logic        hook_in_flight,
    output logic        hook_is_shooting,
    output logic [5:0]  web_bomb_timer
);

// Constants
localparam int INITIAL_R = 20;
localparam int BASE_SPEED = 4;

// States
enum logic [1:0] {ST_SWING, ST_SHOOT, ST_RETRACT} state;

// Internal variables
logic [7:0] shoot_speed_fp;
logic [7:0] pull_speed_fp;
logic [8:0] base_radius;	 
logic play_enable_d;
logic [5:0] pause_timer;

logic [7:0] calc_shoot_fp;
logic [7:0] calc_pull_fp;
logic [7:0] base_pull_fp;

// Fixed point math: 3 fractional bits (1.0 = 8)
assign calc_shoot_fp = ((BASE_SPEED * 8) * speed_multiplier) >> slowdown_active;

always_comb begin
    case (grabbed_weight)
        2'd0: base_pull_fp = 8'd32; // Empty: 4.0 speed
        2'd1: base_pull_fp = 8'd24; // Small: 3.0 speed
        2'd2: base_pull_fp = 8'd8;  // Medium: 1.0 speed (Old Large speed)
        2'd3: base_pull_fp = 8'd4;  // Large: 0.5 speed (Twice as slow as Medium)
    endcase
end

assign calc_pull_fp = (base_pull_fp * speed_multiplier) >> slowdown_active;

assign shoot_speed_fp = (calc_shoot_fp == 0) ? 8'd8 : calc_shoot_fp; // min 1.0
assign pull_speed_fp  = (calc_pull_fp == 0)  ? 8'd1 : calc_pull_fp;  // min 0.125

assign base_radius = INITIAL_R << longer_radius_en;

logic [13:0] current_R_fp; // 11 integer bits + 3 fractional bits
assign current_R = current_R_fp[13:3];

assign hook_in_flight = (state != ST_SWING);
assign hook_is_shooting = (state == ST_SHOOT);
assign web_bomb_timer = pause_timer;

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        state        <= ST_SWING;
        current_R_fp <= {base_radius, 3'b000};
        freeze_angle <= 1'b0;
		is_hooked    <= 1'b0;
        play_enable_d <= 1'b0;
        pause_timer  <= 6'd0;
    end else begin
        play_enable_d <= play_enable;
        
        if (play_enable && !play_enable_d) begin	// New level started --> Reset hook state
            state        <= ST_SWING;
            current_R_fp <= {base_radius, 3'b000};
            freeze_angle <= 1'b0;
            is_hooked    <= 1'b0;
            pause_timer  <= 6'd0;
        end else if (scissors_pulse && state == ST_RETRACT && is_hooked) begin // Scissors cut!
            state        <= ST_SWING;
            current_R_fp <= {base_radius, 3'b000};
            freeze_angle <= 1'b0;
            is_hooked    <= 1'b0;
            pause_timer  <= 6'd0;
        end else if (web_bomb_pulse && (state == ST_SHOOT || state == ST_RETRACT)) begin // Web Bomb trigger!
            state        <= ST_RETRACT;
            is_hooked    <= 1'b1;
            pause_timer  <= 6'd60;
        end else begin
        case (state)
            
            // --------------------------------
            ST_SWING: begin
            // --------------------------------
                current_R_fp <= {base_radius, 3'b000};
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
					
               if (startOfFrame && play_enable) begin
                   current_R_fp <= current_R_fp + shoot_speed_fp; 
               end
            end
            
            // --------------------------------
            ST_RETRACT: begin
            // --------------------------------
                freeze_angle <= 1'b1;
                if (startOfFrame && play_enable) begin
                    if (pause_timer > 0) begin
                        pause_timer <= pause_timer - 1'b1;
                    end else begin
                        current_R_fp <= current_R_fp - pull_speed_fp;
                        
                        // Transition back to swing when fully retracted
                        if (current_R_fp <= {base_radius, 3'b000}) begin
                            current_R_fp <= {base_radius, 3'b000}; // Snap exactly to base radius
                            state     <= ST_SWING;
							is_hooked <= 1'b0;
                        end
                    end
                end
            end
            
        endcase
        end 
    end
end

endmodule