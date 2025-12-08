`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: random
// Description: 
//     Linear Feedback Shift Register (LFSR) based pseudo-random number generator.
//     Outputs random number from 0 to 9.
//     Uses 16-bit LFSR with taps at bits 16, 15, 13, 4 (maximal length sequence).
//////////////////////////////////////////////////////////////////////////////////

module random(
    input         clk,
    input         reset,
    input         next,           // Pulse to get next random number
    input  [3:0]  max_num,        // Maximum number (typically 9 for 0-9 range)
    output reg [3:0] rand_num = 4'd0,
    output reg    rand_valid = 1'b0
);

    // 16-bit LFSR for pseudo-random sequence
    reg [15:0] lfsr = 16'hACE1;  // Non-zero seed
    wire feedback;
    
    // LFSR feedback polynomial: x^16 + x^15 + x^13 + x^4 + 1
    assign feedback = lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3];
    
    // Continuously shift LFSR for more randomness
    always @(posedge clk) begin
        if (reset) begin
            lfsr <= 16'hACE1;
        end else begin
            // Always shift to create more entropy
            lfsr <= {lfsr[14:0], feedback};
        end
    end
    
    // Generate random number when requested
    reg next_prev = 1'b0;
    
    always @(posedge clk) begin
        if (reset) begin
            rand_num <= 4'd0;
            rand_valid <= 1'b0;
            next_prev <= 1'b0;
        end else begin
            next_prev <= next;
            
            // Detect rising edge of next signal
            if (next && !next_prev) begin
                // Use modulo to get number in range 0 to max_num
                // For max_num = 9, we want 0-9 (10 values)
                rand_num <= lfsr[3:0] % (max_num + 1);
                rand_valid <= 1'b1;
            end else begin
                rand_valid <= 1'b0;
            end
        end
    end

endmodule