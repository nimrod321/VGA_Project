module game_state_controller (
    input  logic        clk,
    input  logic        resetN,
    
    // Game events
    input  logic [3:0]  keyPad,      
    input  logic        keyPadValid,
    input  logic        enter_key,   
    input  logic        time_out,
    input  logic        threshold_met,
    
    // Outputs to other managers
    output logic [3:0]  current_level,
    output logic [1:0]  current_state, // 0=LOBBY, 1=PLAY, 2=STORE, 3=GAME_OVER
    output logic        start_level_pulse, // Trigger to Bitmap Generator
    output logic        start_timer_pulse,
    output logic        reset_score_pulse,
    output logic        play_enable,
    output logic        show_instructions_en
);

    typedef enum logic [1:0] {LOBBY=2'd0, PLAY=2'd1, STORE=2'd2, GAME_OVER=2'd3} state_t;
    state_t state;
    
    logic start_timer_pulse_d;
    
    logic start_game;
    assign start_game = enter_key;
    // Edge detector for start_game button
    logic start_game_last;
    logic start_game_edge;
    
    // Add skip button (Key 9)
    logic skip_level;
    logic skip_level_last;
    logic skip_level_edge;
    assign skip_level = ((keyPad == 4'd9) && keyPadValid);
    
    // Add key 0 edge detection for Instructions Menu
    logic key_zero;
    logic key_zero_last;
    logic key_zero_edge;
    assign key_zero = ((keyPad == 4'd0) && keyPadValid);

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            start_game_last <= 1'b0;
            skip_level_last <= 1'b0;
            key_zero_last <= 1'b0;
        end else begin
            start_game_last <= start_game;
            skip_level_last <= skip_level;
            key_zero_last <= key_zero;
        end
    end
    assign start_game_edge = start_game & ~start_game_last;
    assign skip_level_edge = skip_level & ~skip_level_last;
    assign key_zero_edge = key_zero & ~key_zero_last;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            state <= LOBBY;
            current_level <= 0;
            start_level_pulse <= 1'b0;
            start_timer_pulse <= 1'b0;
            start_timer_pulse_d <= 1'b0;
            reset_score_pulse <= 1'b0;
            show_instructions_en <= 1'b0;
        end else begin
            start_level_pulse <= 1'b0; 
            start_timer_pulse <= 1'b0;
            start_timer_pulse_d <= start_timer_pulse;
            reset_score_pulse <= 1'b0;
            
            case (state)
                LOBBY: begin
                    if (key_zero_edge) begin
                        show_instructions_en <= ~show_instructions_en; // Toggle instructions
                    end else if (start_game_edge && !show_instructions_en) begin
                        state <= PLAY;
                        start_level_pulse <= 1'b1;
                        start_timer_pulse <= 1'b1;
                        reset_score_pulse <= 1'b1;
                        current_level <= 1;
                        show_instructions_en <= 1'b0;
                    end
                end
                
                PLAY: begin
                    if (((threshold_met && time_out) || skip_level_edge) && !start_timer_pulse && !start_timer_pulse_d) begin
                        state <= STORE;
                    end else if (time_out && !start_timer_pulse && !start_timer_pulse_d) begin
                        state <= GAME_OVER;
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
    assign play_enable = (state == PLAY);

endmodule
