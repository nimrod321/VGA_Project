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
    input  logic        grant_powerup_pulse,
    output logic        web_bomb_pulse,
    output logic [1:0]  saved_powerup,
    output logic [2:0]  slowdown_cooldown_sec
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
    assign slowdown_cooldown_sec = (slowdown_cooldown + 9'd59) / 60;

    // Powerup Tracking
    logic [7:0] random_counter; // Cheap PRNG
    logic       web_bomb_req;
    logic [8:0] slowdown_cooldown; // 5-second cooldown at 60Hz = 300 frames

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
            slowdown_cooldown <= 9'd0;
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
                            if (saved_powerup == 2'd1) begin
                                add_time_pulse  <= 1'b1; // Added Time
                                saved_powerup   <= 2'd0;
                            end else if (saved_powerup == 2'd2 && !web_bomb_req) begin
                                web_bomb_req    <= 1'b1;
                                saved_powerup   <= 2'd0;
                            end else if (saved_powerup == 2'd3) begin
                                // Scissors logic goes here later!
                                saved_powerup   <= 2'd0;
                            end
                        end
                        4'd4: begin // Press 4 to use active slowdown (from store upgrade)
                            if (active_slowdown_unlocked && slowdown_cooldown == 0 && slowdown_timer == 0 && !active_slowdown) begin
                                active_slowdown   <= 1'b1;
                                slowdown_timer    <= 6'd60; // 60 frames = 1 second
                                slowdown_cooldown <= 9'd300; // 5 seconds cooldown at 60Hz
                            end
                        end
                        default: ;
                    endcase
                end
            end
            
            // Riddler Capture Logic -> Gives Random Powerup
            if (grant_powerup_pulse) begin
                if (random_counter[1:0] == 2'd0) saved_powerup <= 2'd1; // Added Time
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
            end
            
            // Clear active upgrades when level is not in PLAY state
            if (current_state != 2'd1) begin // If not in PLAY (e.g. LOBBY, STORE, GAME_OVER)
                active_speed    <= 1'b0;
                active_radius   <= 1'b0;
                active_time     <= 1'b0;
                active_slowdown_unlocked <= 1'b0;
                active_slowdown <= 1'b0;
                slowdown_timer  <= 6'd0;
                slowdown_cooldown <= 9'd0;
            end else begin
                // Decrement slowdown cooldown on 60Hz tick
                if (startOfFrame && slowdown_cooldown > 0) begin
                    slowdown_cooldown <= slowdown_cooldown - 1'b1;
                end
                
                // Decrement active slowdown timer
                if (startOfFrame && active_slowdown) begin
                    if (slowdown_timer > 0) begin
                        slowdown_timer <= slowdown_timer - 1'b1;
                    end else begin
                        active_slowdown <= 1'b0;
                    end
                end
            end
        end
    end

endmodule
