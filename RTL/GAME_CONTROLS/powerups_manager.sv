// (c) Technion IIT, Department of Electrical Engineering 2026
// Powerups Manager - Tracks inventory, active states, slowdown duration, and keypad overrides

module powerups_manager (
    input  logic        clk,
    input  logic        resetN,
    
    // Game events
    input  logic [1:0]  current_state,      // 0=LOBBY, 1=PLAY, 2=STORE, 3=GAME_OVER
    input  logic        start_level_pulse,  // Clears/latches powerups
    input  logic        startOfFrame,       // 60Hz tick for slowdown timer
    
    // Keypad input for manual purchase/triggers
    input  logic [3:0]  keyPad,
    input  logic        keyPadValid,
    
    // Purchase inputs from store_manager
    input  logic        speed_purchased,
    input  logic        radius_purchased,
    input  logic        time_purchased,
    input  logic        slowdown_purchased,
    
    // Outputs to Hook System
    output logic [1:0]  speed_multiplier,
    output logic        longer_radius_en,
    
    // Outputs to Timer Manager
    output logic        passive_extra_time,
    output logic        add_time_pulse,
    
    // Output to physics/rotation (Slowdown)
    output logic        slowdown_active,
    
    // Powerups Unlocking and Triggering
    input  logic        score_pulse,
    input  logic [2:0]  pulled_id,
    output logic        web_bomb_pulse
);


    
    // Active Level Registers (active during PLAY state)
    logic active_speed;
    logic active_radius;
    logic active_time;
    logic active_slowdown_unlocked;
    
    // Slowdown State
    logic [5:0] slowdown_timer;
    logic active_slowdown;

    // Edge detector for keypad
    logic keyPadValid_d;
    logic key_pulse;
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            keyPadValid_d <= 1'b0;
        end else begin
            keyPadValid_d <= keyPadValid;
        end
    end
    assign key_pulse = keyPadValid && !keyPadValid_d;

    // Output assignments
    assign speed_multiplier    = active_speed  ? 2'd2 : 2'd1;
    assign longer_radius_en    = active_radius;
    // Forward time_purchased instantly when level starts, since timer manager samples it immediately
    assign passive_extra_time  = start_level_pulse ? time_purchased : active_time;
    assign slowdown_active     = active_slowdown;

    // Powerup Tracking
    logic [1:0] saved_powerup; // 0=None, 1=Slowdown, 2=WebBomb, 3=Scissors
    logic [7:0] random_counter; // Cheap PRNG
    logic       web_bomb_req;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            active_speed    <= 1'b0;
            active_radius   <= 1'b0;
            active_time     <= 1'b0;
            active_slowdown_unlocked <= 1'b0;
            add_time_pulse  <= 1'b0;
            slowdown_timer  <= 6'd0;
            active_slowdown <= 1'b0;
            saved_powerup   <= 2'd0;
            random_counter  <= 8'd0;
            web_bomb_req    <= 1'b0;
            web_bomb_pulse  <= 1'b0;
        end else begin
            add_time_pulse <= 1'b0; // Default pulse to 0
            web_bomb_pulse <= 1'b0;
            random_counter <= random_counter + 1'b1;
            
            // Web Bomb Sync logic
            if (web_bomb_req && startOfFrame) begin
                web_bomb_pulse <= 1'b1;
                web_bomb_req <= 1'b0;
            end
            
            // Purchase/Manual Trigger logic via keypad
            if (key_pulse) begin
                if (current_state == 2'd1) begin // PLAY state
                    case (keyPad)
                        4'd0: begin // Press 0/ENTER to use saved powerup!
                            if (saved_powerup == 2'd1 && slowdown_timer == 0 && !active_slowdown) begin
                                active_slowdown <= 1'b1;
                                slowdown_timer  <= 6'd60; // 60 frames = 1 second
                                saved_powerup <= 2'd0;
                            end else if (saved_powerup == 2'd2 && !web_bomb_req) begin
                                web_bomb_req <= 1'b1;
                                saved_powerup <= 2'd0;
                            end else if (saved_powerup == 2'd3) begin
                                // Scissors logic goes here later!
                                saved_powerup <= 2'd0;
                            end
                        end
                        4'd8: begin // Press 8 to dynamically add 10 seconds (for testing)
                            add_time_pulse <= 1'b1;
                        end
                        default: ;
                    endcase
                end
            end
            
            // Riddler Capture Logic -> Gives Random Powerup
            if (score_pulse && pulled_id == 3'd4 && saved_powerup == 2'd0) begin
                if (random_counter[1:0] == 2'd0) saved_powerup <= 2'd1; // Slowdown
                else if (random_counter[1:0] == 2'd1) saved_powerup <= 2'd2; // Web Bomb
                else saved_powerup <= 2'd3; // Scissors
            end
            
            // Latch and clear logic on start of next level
            if (start_level_pulse) begin
                // Latch bought upgrades to active registers
                active_speed  <= speed_purchased;
                active_radius <= radius_purchased;
                active_time   <= time_purchased;
                active_slowdown_unlocked <= slowdown_purchased;
                saved_powerup <= 2'd0; // Reset powerups between levels
            end
            
            // Clear active upgrades when level is not in PLAY state
            if (current_state != 2'd1) begin // If not in PLAY (e.g. LOBBY, STORE, GAME_OVER)
                active_speed    <= 1'b0;
                active_radius   <= 1'b0;
                active_time     <= 1'b0;
                active_slowdown_unlocked <= 1'b0;
                active_slowdown <= 1'b0;
                slowdown_timer  <= 6'd0;
                saved_powerup   <= 2'd0;
            end else if (startOfFrame && active_slowdown) begin
                // Decrement slowdown timer
                if (slowdown_timer > 0) begin
                    slowdown_timer <= slowdown_timer - 1'b1;
                end else begin
                    active_slowdown <= 1'b0;
                end
            end
        end
    end

endmodule
