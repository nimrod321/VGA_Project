module game_state_controller (
    input  logic        clk,
    input  logic        resetN,
    
    // Game events
    input  logic [3:0]  keyPad,      // From KBD module
    input  logic        keyPadValid,
    input  logic        time_out,
    input  logic        threshold_met,
    
    // Outputs to other managers
    output logic [3:0]  current_level,
    output logic [1:0]  current_state, // 0=LOBBY, 1=PLAY, 2=STORE, 3=GAME_OVER
    output logic        start_level_pulse, // Trigger to Bitmap Generator
    output logic        start_timer_pulse,
    output logic        reset_score_pulse
);

    typedef enum logic [1:0] {LOBBY=2'd0, PLAY=2'd1, STORE=2'd2, GAME_OVER=2'd3} state_t;
    state_t state;
    
    // Convert keyboard press (assuming Key 3 or 5 is Enter/Start) to a single pulse
    logic start_game;
    assign start_game = ((keyPad == 4'd5 || keyPad == 4'd3) && keyPadValid);
    
    // Edge detector for start_game button
    logic start_game_last;
    logic start_game_edge;
    
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            start_game_last <= 1'b0;
        end else begin
            start_game_last <= start_game;
        end
    end
    assign start_game_edge = start_game & ~start_game_last;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            state <= LOBBY;
            current_level <= 1;
            start_level_pulse <= 1'b0;
            start_timer_pulse <= 1'b0;
            reset_score_pulse <= 1'b0;
        end else begin
            start_level_pulse <= 1'b0; 
            start_timer_pulse <= 1'b0;
            reset_score_pulse <= 1'b0;
            
            case (state)
                LOBBY: begin
                    if (start_game_edge) begin
                        state <= PLAY;
                        start_level_pulse <= 1'b1;
                        start_timer_pulse <= 1'b1;
                        reset_score_pulse <= 1'b1;
                        current_level <= 1;
                    end
                end
                
                PLAY: begin
                    if (time_out) begin
                        if (threshold_met) begin
                            state <= STORE;
                        end else begin
                            state <= GAME_OVER;
                        end
                    end
                end
                
                STORE: begin
                    if (start_game_edge) begin
                        state <= PLAY;
                        start_level_pulse <= 1'b1;
                        start_timer_pulse <= 1'b1;
                        current_level <= current_level + 1;
                    end
                end
                
                GAME_OVER: begin
                    if (start_game_edge) begin 
                        state <= LOBBY;
                    end
                end
            endcase
        end
    end
    
    assign current_state = state;

endmodule
