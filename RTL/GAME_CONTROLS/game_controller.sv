// Game Controller (Gold Miner Architecture)
// Detects pixel-perfect overlaps between VGA drawing requests

module game_controller (    
    input  logic clk,
    input  logic resetN,
    input  logic startOfFrame,             // Pulse every start of frame (e.g., 60Hz) 
    
    // VGA Pipeline Drawing Requests
    input  logic drawing_request_hook,     // The line itself
    input  logic drawing_request_web,      // The tip of the hook
    input  logic drawing_request_objects,  // The background targets (Gold, Rocks, etc.)
        
    // Collision Outputs
    output logic collision_web_object,     // Active if the web tip touches an object
//    output logic collision_hook_object,    // Active if the line itself touches an object
    output logic SingleHitPulse            // A single 1-clock pulse per frame upon web collision 
);

    logic flag; // Semaphore to ensure only one hit pulse is generated per frame

    // -------------------------------------------------------------------------
    // 1. Pixel-Perfect Collision Detection
    // Active exactly when the VGA beam tries to draw two elements at the same pixel
    // -------------------------------------------------------------------------
    assign collision_web_object  = (drawing_request_web  && drawing_request_objects);
    
    // Optional: If you want the line itself to trigger hits or break objects
//    assign collision_hook_object = (drawing_request_hook && drawing_request_objects);


    // -------------------------------------------------------------------------
    // 2. Single Pulse Generation
    // Translates the rapid 25MHz pixel overlaps into a single clean pulse 
    // for your game logic state machines to read safely.
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin 
            flag           <= 1'b0;
            SingleHitPulse <= 1'b0; 
        end else begin 
            SingleHitPulse <= 1'b0; // Default to 0 unless triggered
            
            if (startOfFrame) begin
                flag <= 1'b0;       // Reset the semaphore at the start of a new screen draw
            end
            
            // If the web hits an object, and we haven't pulsed yet this frame...
            if (collision_web_object && (flag == 1'b0)) begin 
                flag           <= 1'b1; // Lock the semaphore
                SingleHitPulse <= 1'b1; // Send the pulse
            end 
        end 
    end

endmodule