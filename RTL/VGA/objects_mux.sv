
// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018

//-- Eyal Lev 31 Jan 2021

module	objects_mux	(	
//		--------	Clock Input	 	
					input		logic	clk,
					input		logic	resetN,
			
			// spider-web hook tip
					input		logic	webDrawingRequest, 
					input		logic	[7:0] webRGB,
			
			// hook
					input		logic	hookDrawingRequest, 
					input		logic	[7:0] hookRGB,
					
			// pulled object
					input		logic	pulledDrawingRequest, 
					input		logic	[7:0] pulledRGB,
			  
		  ////////////////////////
		  // background 
					input    logic objectsDrawingRequest, 
					input		logic	[7:0] objectsRGB,
					input		logic	[7:0] RGB_MIF, 
			  
				   output	logic	[7:0] RGBOut
);

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
			RGBOut	<= 8'b0;
	end
	
	else begin
		 
//--- logic for spider-web drawing (hook tip) -------------------------------------
		
		if (webDrawingRequest == 1'b1 )   
			RGBOut <= webRGB;  //2nd priority 
		 
//--- logic for hook drawing ------------------------------------------------------		
		
		else if (hookDrawingRequest == 1'b1 )   
			RGBOut <= hookRGB;  //3rd priority 
			
//--- logic for pulled object drawing ------------------------------------------------------		
		
		else if (pulledDrawingRequest == 1'b1 )   
			RGBOut <= pulledRGB;  //4th priority 
//---------------------------------------------------------------------------------		
 		else if (objectsDrawingRequest == 1'b1)
				RGBOut <= objectsRGB;
				
		else RGBOut <= RGB_MIF ;// last priority 
		end ; 
	end

endmodule


