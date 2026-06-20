// (c) Technion IIT, Department of Electrical Engineering 2026
// Store Manager - TOP LEVEL WRAPPER
// Connects store_logic and store_drawer together without altering BDF pins.

module store_manager (
    input  logic        clk,
    input  logic        resetN,
    
    // Game state and timing
    input  logic [1:0]  current_state,      // 0=LOBBY, 1=PLAY, 2=STORE, 3=GAME_OVER
    input  logic        start_level_pulse,  // Transition to next level
    input  logic [3:0]  current_level,
    
    // Keyboard inputs
    input  logic [3:0]  keyPad,
    input  logic        keyPadValid,
    
    // Score validation and deduction
    input  logic [15:0] score,
    output logic        deduct_score_pulse,
    output logic [15:0] deduct_score_amount,
    
    // Purchase outputs to powerups_manager
    output logic        speed_purchased,
    output logic        radius_purchased,
    output logic        time_purchased,
    output logic        slowdown_purchased,
    
    // VGA Beam Coordinates for drawing prices
    input  logic [10:0] pixelX,
    input  logic [10:0] pixelY,
    
    // Output drawing requests
    output logic        storeDrawingRequest,
    output logic [7:0]  storeRGB
);

    // Internal wires connecting logic and drawer
    logic [15:0] speed_price_wire;
    logic [15:0] time_price_wire;
    logic [15:0] radius_price_wire;
    logic [15:0] slow_price_wire;
    
    // We already have output ports for purchased flags, so we can just read from them!
    // Wait, in SystemVerilog, reading from an output port is allowed.

    store_logic inst_logic (
        .clk(clk),
        .resetN(resetN),
        .current_state(current_state),
        .start_level_pulse(start_level_pulse),
        .current_level(current_level),
        .keyPad(keyPad),
        .keyPadValid(keyPadValid),
        .score(score),
        .deduct_score_pulse(deduct_score_pulse),
        .deduct_score_amount(deduct_score_amount),
        .speed_purchased(speed_purchased),
        .radius_purchased(radius_purchased),
        .time_purchased(time_purchased),
        .slowdown_purchased(slowdown_purchased),
        .speed_price_out(speed_price_wire),
        .time_price_out(time_price_wire),
        .radius_price_out(radius_price_wire),
        .slow_price_out(slow_price_wire)
    );
    
    store_drawer inst_drawer (
        .clk(clk),
        .resetN(resetN),
        .pixelX(pixelX),
        .pixelY(pixelY),
        .current_state(current_state),
        .bought_speed(speed_purchased),
        .bought_time(time_purchased),
        .bought_radius(radius_purchased),
        .bought_slowdown(slowdown_purchased),
        .speed_price(speed_price_wire),
        .time_price(time_price_wire),
        .radius_price(radius_price_wire),
        .slow_price(slow_price_wire),
        .storeDrawingRequest(storeDrawingRequest),
        .storeRGB(storeRGB)
    );

endmodule
