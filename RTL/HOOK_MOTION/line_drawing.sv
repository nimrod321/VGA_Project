// (c) Technion IIT, Department of Electrical Engineering 2025 
module line_drawing	
 ( 
	input logic 			clk,
	input logic 			resetN,
	input	logic	 			enable,
	input	logic  [10:0] 	pixelX,	
	input	logic  [10:0] 	pixelY, 	
	input	logic  [10:0] 	x_e,		// end of line
	input	logic  [10:0] 	y_e, 		// end of line
	input logic  [10:0]	current_R,
	output logic 			lineDrawingRequest,
	output logic [7:0] 	lineRGB
  ) ;

// Fixed start points
localparam int x_s = 320;
localparam int y_s = 92;

// Internal variables for signed coordinate math
logic signed [12:0] dx, dy, px, py;
logic signed [24:0] a, b;
logic signed [24:0] margin;

assign dx = $signed({1'b0, x_e}) - x_s;
assign dy = $signed({1'b0, y_e}) - y_s;
assign px = $signed({1'b0, pixelX}) - x_s;
assign py = $signed({1'b0, pixelY}) - y_s;

assign a = py * dx;
assign b = dy * px;
assign margin = current_R >> 1;

always_comb 
begin
    lineDrawingRequest = 1'b0;
    lineRGB = 8'hFF;

    if (enable && (pixelY >= y_s) && (pixelY <= y_e)) begin
        if ((a - b <= margin) && (b - a <= margin)) begin
            lineDrawingRequest = 1'b1;
            lineRGB = 8'h92; 
        end
    end
end

endmodule