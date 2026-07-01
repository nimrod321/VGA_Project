// Auto-generated Threshold ROM
module threshold_rom (
    input  logic [3:0]  current_level,
    output logic [15:0] threshold
);
    always_comb begin
        case (current_level)
            4'd1: threshold = 16'd90;
            4'd2: threshold = 16'd1035;
            4'd3: threshold = 16'd1215;
            4'd4: threshold = 16'd1935;
            4'd5: threshold = 16'd2925;
            4'd6: threshold = 16'd3375;
            4'd7: threshold = 16'd4185;
            4'd8: threshold = 16'd4545;
            4'd9: threshold = 16'd4725;
            4'd10: threshold = 16'd6750;
            4'd11: threshold = 16'd7335;
            4'd12: threshold = 16'd9810;
            4'd13: threshold = 16'd10845;
            4'd14: threshold = 16'd11970;
            4'd15: threshold = 16'd13410;
            default: threshold = 16'd0;
        endcase
    end
endmodule
