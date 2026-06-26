// (c) Technion IIT, Department of Electrical Engineering 2026 
module hook_system (
    input  logic        clk,
    input  logic        resetN,
    input  logic        startOfFrame,
    input  logic [3:0]  keyPad,             // From KBD module
	 input  logic        keyPadValid,
    input  logic        object_collision,   // From your game's object hit detection
    input  logic [1:0]  grabbed_weight,
    input  logic [1:0]  speed_multiplier,
	 input  logic 			longer_radius_en,
	 input  logic 			slowdown_active,
    input  logic 			play_enable,
    input  logic        scissors_pulse,
    input  logic        web_bomb_pulse,
    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,
    
    output logic [10:0] hook_x,             // Exported so your game knows where the hook tip is
    output logic [10:0] hook_y,
    output logic        hookDrawingRequest,
    output logic [7:0]  hookRGB,
	 output logic 			is_hooked,
    output logic        hook_in_flight,
    output logic        hook_is_shooting,
    output logic [5:0]  web_bomb_timer
);


// -------------------------------------------------------------------------
// Internal Routing Wires
// -------------------------------------------------------------------------
logic        shoot_key_wire;
logic        any_collision_wire;
logic        wall_collision;
logic [10:0] current_R_wire;
logic        freeze_angle_wire;
logic [10:0] x_e_wire;
logic [10:0] y_e_wire;

// -------------------------------------------------------------------------
// Helper & Control Logic
// -------------------------------------------------------------------------
assign shoot_key_wire = ((keyPad == 4'd2) && (keyPadValid) && play_enable);

// Boundary Collission Detection
assign wall_collision = (x_e_wire <= 0) || (x_e_wire >= 639) || (y_e_wire >= 479);

assign hook_x = x_e_wire;
assign hook_y = y_e_wire;

// -------------------------------------------------------------------------
// Module Instantiations
// -------------------------------------------------------------------------

// 1. The Brain
hook_motion_controller brain_inst (
    .clk(clk),
    .resetN(resetN),
    .play_enable(play_enable),
    .startOfFrame(startOfFrame),
    .shoot_key(shoot_key_wire),
    .object_collision(object_collision),
	 .wall_collision(wall_collision),
    .grabbed_weight(grabbed_weight),
    .speed_multiplier(speed_multiplier),
	 .longer_radius_en(longer_radius_en),
     .slowdown_active(slowdown_active),
     .scissors_pulse(scissors_pulse),
     .web_bomb_pulse(web_bomb_pulse),
    .current_R(current_R_wire),
    .freeze_angle(freeze_angle_wire),
	 .is_hooked(is_hooked),
    .hook_in_flight(hook_in_flight),
    .hook_is_shooting(hook_is_shooting),
    .web_bomb_timer(web_bomb_timer)
);

// 2. The Physics
circular_motion physics_inst (
    .clk(clk),
    .resetN(resetN),
    .play_enable(play_enable),
    .freeze_angle(freeze_angle_wire),
    .startOfFrame(startOfFrame),
    .current_R(current_R_wire),
    .slowdown_active(slowdown_active),
    .topLeftX(x_e_wire),
    .topLeftY(y_e_wire)
);

// 3. The Renderer
line_drawing renderer_inst (
    .clk(clk),
    .resetN(resetN),
    .enable(play_enable), // Disabled outside of play state
    .pixelX(pixelX),
    .pixelY(pixelY),
    .x_e(x_e_wire),
    .y_e(y_e_wire),
    .current_R(current_R_wire),
    .lineDrawingRequest(hookDrawingRequest),
    .lineRGB(hookRGB)
);

endmodule