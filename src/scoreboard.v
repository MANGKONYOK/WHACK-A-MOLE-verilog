`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: scoreboard
// Description: 
//     7-segment display scoreboard for Basys3.
//     Displays score from 0000 to 9999.
//     Uses multiplexed display to drive 4 digits.
//     Score increases by 1 on each 'score_inc' pulse.
//////////////////////////////////////////////////////////////////////////////////

module scoreboard(
    input         clk,
    input         reset,
    input         score_inc,      // Pulse to increment score
    output reg [6:0] seg = 7'b1111111,  // 7-segment: {g,f,e,d,c,b,a} active low
    output reg [3:0] an = 4'b1111,      // Anode control, active low
    output reg [13:0] score = 14'd0     // Current score (0-9999)
);

    // Score digits
    reg [3:0] digit0 = 4'd0;  // Ones
    reg [3:0] digit1 = 4'd0;  // Tens
    reg [3:0] digit2 = 4'd0;  // Hundreds
    reg [3:0] digit3 = 4'd0;  // Thousands
    
    // Multiplexing counter and digit selector
    reg [16:0] refresh_counter = 17'd0;  // ~763Hz refresh rate at 100MHz
    wire [1:0] digit_select;
    
    assign digit_select = refresh_counter[16:15];  // Use top 2 bits for digit selection
    
    // Edge detection for score_inc
    reg score_inc_prev = 1'b0;
    wire score_inc_pulse;
    
    assign score_inc_pulse = score_inc && !score_inc_prev;
    
    // Refresh counter
    always @(posedge clk) begin
        if (reset) begin
            refresh_counter <= 17'd0;
        end else begin
            refresh_counter <= refresh_counter + 1'b1;
        end
    end
    
    // Score increment logic
    always @(posedge clk) begin
        if (reset) begin
            digit0 <= 4'd0;
            digit1 <= 4'd0;
            digit2 <= 4'd0;
            digit3 <= 4'd0;
            score <= 14'd0;
            score_inc_prev <= 1'b0;
        end else begin
            score_inc_prev <= score_inc;
            
            if (score_inc_pulse) begin
                // Check if not at max score (9999)
                if (score < 14'd9999) begin
                    score <= score + 1'b1;
                    
                    // Increment with carry
                    if (digit0 == 4'd9) begin
                        digit0 <= 4'd0;
                        if (digit1 == 4'd9) begin
                            digit1 <= 4'd0;
                            if (digit2 == 4'd9) begin
                                digit2 <= 4'd0;
                                if (digit3 < 4'd9) begin
                                    digit3 <= digit3 + 1'b1;
                                end
                            end else begin
                                digit2 <= digit2 + 1'b1;
                            end
                        end else begin
                            digit1 <= digit1 + 1'b1;
                        end
                    end else begin
                        digit0 <= digit0 + 1'b1;
                    end
                end
            end
        end
    end
    
    // Current digit to display
    reg [3:0] current_digit;
    
    // Digit multiplexer
    always @(*) begin
        case (digit_select)
            2'b00: begin
                an = 4'b1110;  // Enable digit 0 (rightmost)
                current_digit = digit0;
            end
            2'b01: begin
                an = 4'b1101;  // Enable digit 1
                current_digit = digit1;
            end
            2'b10: begin
                an = 4'b1011;  // Enable digit 2
                current_digit = digit2;
            end
            2'b11: begin
                an = 4'b0111;  // Enable digit 3 (leftmost)
                current_digit = digit3;
            end
            default: begin
                an = 4'b1111;
                current_digit = 4'd0;
            end
        endcase
    end
    
    // 7-segment decoder (active low)
    // Segment mapping: seg[6:0] = {g,f,e,d,c,b,a}
    //
    //    aaaa
    //   f    b
    //   f    b
    //    gggg
    //   e    c
    //   e    c
    //    dddd
    //
    always @(*) begin
        case (current_digit)
            4'd0: seg = 7'b1000000;  // 0
            4'd1: seg = 7'b1111001;  // 1
            4'd2: seg = 7'b0100100;  // 2
            4'd3: seg = 7'b0110000;  // 3
            4'd4: seg = 7'b0011001;  // 4
            4'd5: seg = 7'b0010010;  // 5
            4'd6: seg = 7'b0000010;  // 6
            4'd7: seg = 7'b1111000;  // 7
            4'd8: seg = 7'b0000000;  // 8
            4'd9: seg = 7'b0010000;  // 9
            default: seg = 7'b1111111;  // All off
        endcase
    end

endmodule