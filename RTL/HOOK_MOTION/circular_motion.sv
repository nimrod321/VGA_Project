// (c) Technion IIT, Department of Electrical Engineering 2025 
module circular_motion 	
 ( 
	input logic 			clk,
	input logic 			resetN,
	input	logic	 			freeze_angle,
	input logic 			startOfFrame,
	input logic  [10:0] 	current_R,
	output logic [10:0] 	topLeftX,
	output logic [10:0] 	topLeftY
  ) ;

parameter int OBJ_SIZE = 16;       // Width/height of the rendering object

// Create circular motion using sin and cos MIF files  
(* ram_init_file = "RTL/HOOK_MOTION/sin_table.mif" *)	logic [10:0] sin_rom [0:90];
(* ram_init_file = "RTL/HOOK_MOTION/cos_table.mif" *)	logic [10:0] cos_rom [0:90];

enum logic [1:0] {IDLE_ST, UPDATE_ANGLE_ST, WAIT_ROM_ST, CALC_POS_ST} SM_Motion;
enum logic [1:0] {MOVE_LEFT_Q1, MOVE_LEFT_Q2, MOVE_RIGHT_Q1, MOVE_RIGHT_Q2} dir;

//local variables
localparam  [10:0] 	x_c = 320;
localparam  [10:0] 	y_c = 60;

// Internal registers
logic [7:0]  angle_reg; 
logic        subtract_x; // Flag to tell the math state to add or subtract

logic [10:0] Xposition;
logic [10:0] Yposition;

logic [21:0] x_offset;
logic [21:0] y_offset;
assign x_offset = current_R * cos_rom[angle_reg];
assign y_offset = current_R * sin_rom[angle_reg];

always_ff @(posedge clk or negedge resetN) begin
    if (!resetN) begin
        SM_Motion  <= IDLE_ST;
        dir        <= MOVE_LEFT_Q1;
        angle_reg  <= 8'd10;
        subtract_x <= 1'b0;
        Xposition  <= 11'd0;
        Yposition  <= 11'd0;
    end 
	 
	 else begin
	 
	 case(SM_Motion)
	 
		//------------
			IDLE_ST: begin
		//------------
			  if (startOfFrame) begin
					if (!freeze_angle)
						 SM_Motion <= UPDATE_ANGLE_ST; // Swinging: Update the angle
					else
						 SM_Motion <= WAIT_ROM_ST;     // Shooting: Skip angle update, jump to math
			  end
		 end
			
		//------------
			UPDATE_ANGLE_ST: begin
		//------------
				if (dir == MOVE_LEFT_Q1) begin
					angle_reg <= angle_reg + 1'b1;
					subtract_x <= 1'b0;
					if (angle_reg == 8'd89) begin
						 dir <= MOVE_LEFT_Q2;
					end
				end
		  
				if (dir == MOVE_LEFT_Q2) begin
					angle_reg <= angle_reg - 1'b1;
					subtract_x <= 1'b1;
					if (angle_reg == 8'd11) begin
						 dir <= MOVE_RIGHT_Q2;
					end
				end
			  
				if (dir == MOVE_RIGHT_Q2) begin
					angle_reg <= angle_reg + 1'b1;
					subtract_x <= 1'b1;
					if (angle_reg == 8'd89) begin
						 dir <= MOVE_RIGHT_Q1;
					end
				end
		  
				if (dir == MOVE_RIGHT_Q1) begin
					angle_reg <= angle_reg - 1'b1;
					subtract_x <= 1'b0;
					if (angle_reg == 8'd11) begin
						 dir <= MOVE_LEFT_Q1;
					end
				end
				
				SM_Motion <= WAIT_ROM_ST;	// Fetch angle vakues in rad
				
			end
		
		//------------
			WAIT_ROM_ST: begin
		//------------
			// The ROM address (angle_reg) was updated last clock cycle.
			// We must wait here for 1 cycle so sin_rom[angle_reg] becomes valid.
				 SM_Motion <= CALC_POS_ST;
			end
			
		//------------
			CALC_POS_ST: begin
		//------------		
				 
				if (subtract_x) 	// in Q2
					Xposition <= x_c - (x_offset >> 10) ;
				else					// in Q1
					Xposition <= x_c + (x_offset >> 10);
				  
				Yposition <= y_c + (y_offset >> 10);

				SM_Motion <= IDLE_ST;
			end
		
		endcase
	end		
end

assign topLeftX = Xposition;
assign topLeftY = Yposition;

endmodule
