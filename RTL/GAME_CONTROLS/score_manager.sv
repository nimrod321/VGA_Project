module score_manager (
    input  logic        clk,
    input  logic        resetN,
    
    // Inputs from Hook/Game
    input  logic        score_pulse,
    input  logic [2:0]  pulled_id,
    input  logic [1:0]  pulled_weight,
    input  logic [3:0]  current_level,
    input  logic        reset_score_pulse, // From Game State Controller when starting from level 1
    input  logic        deduct_score_pulse,
    input  logic [15:0] deduct_score_amount,
    
    // Web Bomb bonus inputs from SpideyObjectsBitMap
    input  logic        web_bomb_bonus_pulse,
    input  logic [15:0] web_bomb_bonus_amount,
    
    // Outputs
    output logic [15:0] score,
    output logic        threshold_met,
    output logic [15:0] added_score,
    output logic [15:0] threshold
);

    assign threshold = current_level * 100;
    assign threshold_met = (score >= threshold);
    
    logic subtract_flag;
    always_comb begin
        subtract_flag = 1'b0;
        case (pulled_id)
            3'd1: begin 
                added_score = (100 * pulled_weight * pulled_weight); // Cop penalty
                subtract_flag = 1'b1;
            end
            3'd2: added_score = (50 * pulled_weight * pulled_weight); // Robber Stand
            3'd3: added_score = 16'd500;  // Maryjane
            3'd4: added_score = 16'd1000; // Riddler
            3'd5: added_score = 16'd1000; // Goblin
            default: added_score = 16'd0;
        endcase
    end
    
    logic [15:0] accumulated_web_bonus;
    
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            score <= 0;
            accumulated_web_bonus <= 0;
        end else begin
            if (reset_score_pulse) begin
                score <= 0;
                accumulated_web_bonus <= 0;
            end else begin
                // Accumulate web bomb points if it explodes
                if (web_bomb_bonus_pulse) begin
                    accumulated_web_bonus <= accumulated_web_bonus + web_bomb_bonus_amount;
                end
                
                // Add regular score + web bomb accumulated score
                if (score_pulse) begin
                    if (subtract_flag) begin
                        // If penalty, still add the bonus!
                        score <= (score + accumulated_web_bonus >= added_score) ? 
                                 (score + accumulated_web_bonus - added_score) : 16'd0;
                    end else begin
                        score <= score + added_score + accumulated_web_bonus;
                    end
                    accumulated_web_bonus <= 0; // Clear after applying
                end else if (deduct_score_pulse) begin
                    score <= (score >= deduct_score_amount) ? (score - deduct_score_amount) : 16'd0;
                end
            end
        end
    end

endmodule
