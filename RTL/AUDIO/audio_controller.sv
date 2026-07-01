// Audio Controller
// Arbitrates SFX and BGM and sends signals to melody_player_1.sv

module audio_controller (
    input logic clk,
    input logic resetN,
    
    // Game State Inputs
    input logic [1:0] current_state, // 0: Lobby, 1: Play, 2: Store, 3: Game Over
    input logic [3:0] current_level,
    input logic       threshold_met,
    
    // Pulse Inputs from Game Events
    input logic       score_pulse,            // Item Grabbed
    input logic       deduct_score_pulse,     // Cha Ching (Store Purchase)
    input logic       web_bomb_bonus_pulse,   // Explosion
    
    // Feedback from melody_player_1
    input logic       melodyEnded,
    
    // Outputs to melody_player_1
    output logic [3:0] melodySelect,
    output logic       startMelodyKey
);

    logic last_threshold_met;
    logic [1:0] last_state;
    
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            last_threshold_met <= 1'b0;
            last_state <= 2'b00;
        end else begin
            last_threshold_met <= threshold_met;
            last_state <= current_state;
        end
    end
    
    logic level_complete_edge;
    assign level_complete_edge = (threshold_met && !last_threshold_met);
    
    logic store_exit_edge;
    assign store_exit_edge = (last_state == 2'd2 && current_state == 2'd1);

    logic state_changed;
    assign state_changed = (last_state != current_state);

    // Audio Arbitration logic
    // We only have one audio channel, so SFX (pulses) interrupt Background Music (BGM).
    // BGM loops by checking the melodyEnded pulse.
    
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            melodySelect <= 4'd6; // Default to Lobby
            startMelodyKey <= 1'b0;
        end else begin
            startMelodyKey <= 1'b0; // Default to no pulse
            
            // PRIORITY 1: High Priority SFX (One-shots)
            if (web_bomb_bonus_pulse) begin
                melodySelect <= 4'd8; // Explosion
                startMelodyKey <= 1'b1;
            end else if (score_pulse) begin
                melodySelect <= 4'd7; // Grab Item
                startMelodyKey <= 1'b1;
            end else if (deduct_score_pulse) begin
                melodySelect <= 4'd9; // Cha Ching
                startMelodyKey <= 1'b1;
            end else if (store_exit_edge) begin
                melodySelect <= 4'd10; // Door bell
                startMelodyKey <= 1'b1;
            end else if (level_complete_edge) begin
                melodySelect <= 4'd11; // Level Complete
                startMelodyKey <= 1'b1;
            end else if (state_changed && current_state == 2'd3) begin
                melodySelect <= 4'd12; // Game Over
                startMelodyKey <= 1'b1;
            end
            
            // PRIORITY 2: Background Music (Looping)
            // Starts exactly when state changes, or when the previous melody finished
            else if (melodyEnded || state_changed) begin
                if (current_state == 2'd0) begin // Lobby
                    melodySelect <= 4'd6;
                    startMelodyKey <= 1'b1;
                end else if (current_state == 2'd2) begin // Store
                    melodySelect <= 4'd4;
                    startMelodyKey <= 1'b1;
                end else if (current_state == 2'd1 && (current_level == 4'd5 || current_level == 4'd10 || current_level == 4'd15)) begin // Boss Level
                    melodySelect <= 4'd5;
                    startMelodyKey <= 1'b1;
                end
                // Normal gameplay has no looping BGM, allowing SFX to stand out cleanly
            end
        end
    end

endmodule
