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
    
    // Outputs
    output logic [15:0] score,
    output logic        threshold_met,
    output logic [15:0] added_score,
    output logic [15:0] threshold
);

    assign threshold = current_level * 100;
    assign threshold_met = (score >= threshold);
    
    always_comb begin
        case (pulled_id)
            3'd1: added_score = (10 * pulled_weight * pulled_weight); // Cop
            3'd2: added_score = (50 * pulled_weight * pulled_weight); // Robber Stand
            3'd3: added_score = 16'd500;  // Maryjane
            3'd4: added_score = 16'd1000; // Riddler
            3'd5: added_score = 16'd1000; // Goblin
            default: added_score = 16'd0;
        endcase
    end
    
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            score <= 0;
        end else begin
            if (reset_score_pulse) begin
                score <= 0;
            end else if (score_pulse) begin
                score <= score + added_score;
            end else if (deduct_score_pulse) begin
                score <= (score >= deduct_score_amount) ? (score - deduct_score_amount) : 16'd0;
            end
        end
    end

endmodule
