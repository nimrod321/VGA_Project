// (c) Technion IIT, Department of Electrical Engineering 2026
// Store Logic - Handles prices, purchases, and score deductions

module store_logic (
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
    
    // Purchase outputs to powerups_manager and drawer
    output logic        speed_purchased,
    output logic        radius_purchased,
    output logic        time_purchased,
    output logic        slowdown_purchased,
    
    // Price outputs to drawer
    output logic [15:0] speed_price_out,
    output logic [15:0] time_price_out,
    output logic [15:0] radius_price_out,
    output logic [15:0] slow_price_out
);

    // Purchase Registers (latched until next level starts)
    logic bought_speed;
    logic bought_radius;
    logic bought_time;
    logic bought_slowdown;
    
    assign speed_purchased  = bought_speed;
    assign radius_purchased = bought_radius;
    assign time_purchased   = bought_time;
    assign slowdown_purchased = bought_slowdown;

    // Price Registers
    logic [15:0] speed_price;
    logic [15:0] radius_price;
    logic [15:0] time_price;
    logic [15:0] slow_price;
    
    assign speed_price_out = speed_price;
    assign time_price_out = time_price;
    assign radius_price_out = radius_price;
    assign slow_price_out = slow_price;

    // LFSR for pseudo-random prices
    logic [15:0] lfsr;
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            lfsr <= 16'hACE1; // Seed must be non-zero
        end else begin
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
        end
    end

    // Detect entering STORE state (rising edge)
    logic [1:0] state_d;
    logic enter_store_pulse;
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            state_d <= 2'd0;
        end else begin
            state_d <= current_state;
        end
    end
    assign enter_store_pulse = (current_state == 2'd2 && state_d != 2'd2);

    // Keypad press detection (rising edge)
    logic keypad_valid_d;
    logic key_press_pulse;
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            keypad_valid_d <= 1'b0;
        end else begin
            keypad_valid_d <= keyPadValid;
        end
    end
    assign key_press_pulse = keyPadValid && !keypad_valid_d;

    // Handle prices and purchases
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            bought_speed        <= 1'b0;
            bought_radius       <= 1'b0;
            bought_time         <= 1'b0;
            bought_slowdown     <= 1'b0;
            speed_price         <= 16'd150;
            time_price          <= 16'd100;
            radius_price        <= 16'd150;
            slow_price          <= 16'd200;
            deduct_score_pulse  <= 1'b0;
            deduct_score_amount <= 16'd0;
        end else begin
            deduct_score_pulse  <= 1'b0;
            
            // Randomize prices on entering the store
            if (enter_store_pulse) begin
                logic [15:0] s_price, t_price, r_price, sl_price;
                s_price = (16'd100 * current_level) + {8'd0, lfsr[7:0]};
                t_price = (16'd50  * current_level) + {9'd0, lfsr[14:8]};
                r_price = (16'd100 * current_level) + {8'd0, lfsr[7:0] ^ lfsr[15:8]};
                sl_price = (16'd150 * current_level) + {8'd0, lfsr[15:8]};
                
                // Cap at 999 so they don't overflow the 3-digit display
                speed_price  <= (s_price > 999) ? 16'd999 : s_price;
                time_price   <= (t_price > 999) ? 16'd999 : t_price;
                radius_price <= (r_price > 999) ? 16'd999 : r_price;
                slow_price   <= (sl_price > 999)? 16'd999 : sl_price;
            end

            // Purchase Logic
            if (current_state == 2'd2 && key_press_pulse) begin
                case (keyPad)
                    4'd1: begin // Buy Speed Multiplier
                        if (!bought_speed && score >= speed_price) begin
                            bought_speed <= 1'b1;
                            deduct_score_pulse <= 1'b1;
                            deduct_score_amount <= speed_price;
                        end
                    end
                    4'd2: begin // Buy Added Time
                        if (!bought_time && score >= time_price) begin
                            bought_time <= 1'b1;
                            deduct_score_pulse <= 1'b1;
                            deduct_score_amount <= time_price;
                        end
                    end
                    4'd3: begin // Buy Longer Radius
                        if (!bought_radius && score >= radius_price) begin
                            bought_radius <= 1'b1;
                            deduct_score_pulse <= 1'b1;
                            deduct_score_amount <= radius_price;
                        end
                    end
                    4'd4: begin // Buy Slowdown
                        if (!bought_slowdown && score >= slow_price) begin
                            bought_slowdown <= 1'b1;
                            deduct_score_pulse <= 1'b1;
                            deduct_score_amount <= slow_price;
                        end
                    end
                    default: ;
                endcase
            end

            // Reset purchases when transitioning out of store to next level
            if (start_level_pulse) begin
                bought_speed  <= 1'b0;
                bought_time   <= 1'b0;
                bought_radius <= 1'b0;
                bought_slowdown <= 1'b0;
            end
        end
    end

endmodule
