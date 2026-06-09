module timer_manager (
    input  logic        clk,
    input  logic        resetN,
    
    // Inputs from Game State Controller
    input  logic        start_timer_pulse,
    
    // Outputs
    output logic [7:0]  time_left,
    output logic        time_out
);

    logic [25:0] clk_div_count;
    logic timer_tick;

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            clk_div_count <= 0;
            timer_tick <= 1'b0;
        end else begin
            if (clk_div_count >= 50000000 - 1) begin
                clk_div_count <= 0;
                timer_tick <= 1'b1;
            end else begin
                clk_div_count <= clk_div_count + 1;
                timer_tick <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            time_left <= 0;
            time_out <= 1'b1;
        end else begin
            if (start_timer_pulse) begin
                time_left <= 60; // 60 seconds per level
                time_out <= 1'b0;
            end else if (timer_tick && time_left > 0) begin
                time_left <= time_left - 1;
            end
            
            time_out <= (time_left == 0);
        end
    end

endmodule
