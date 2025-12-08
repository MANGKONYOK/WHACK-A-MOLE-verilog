`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: key2input
// Description: 
//     Converts PS/2 keyboard scancode to number (0-9) and player ID.
//     Player 0: Number row keys (1-0)
//         1 -> 16h -> num 0, 2 -> 1Eh -> num 1, ..., 0 -> 45h -> num 9
//     Player 1: Numpad keys (1-0)
//         Numpad 1 -> 69h -> num 0, Numpad 2 -> 72h -> num 1, ..., Numpad 0 -> 70h -> num 9
//////////////////////////////////////////////////////////////////////////////////

module key2input(
    input         clk,
    input  [7:0]  key,
    input         key_valid,
    output reg [3:0] num = 4'h0,
    output reg       player = 1'b0,   // 0 = Player 0, 1 = Player 1
    output reg       input_valid = 1'b0
);

    always @(posedge clk) begin
        if (key_valid) begin
            case (key)
                // Player 0: Number row keys (1-0)
                8'h16: begin  // Key 1 -> num 0
                    num <= 4'd0;
                    player <= 1'b0;
                    input_valid <= 1'b1;
                end
                8'h1E: begin  // Key 2 -> num 1
                    num <= 4'd1;
                    player <= 1'b0;
                    input_valid <= 1'b1;
                end
                8'h26: begin  // Key 3 -> num 2
                    num <= 4'd2;
                    player <= 1'b0;
                    input_valid <= 1'b1;
                end
                8'h25: begin  // Key 4 -> num 3
                    num <= 4'd3;
                    player <= 1'b0;
                    input_valid <= 1'b1;
                end
                8'h2E: begin  // Key 5 -> num 4
                    num <= 4'd4;
                    player <= 1'b0;
                    input_valid <= 1'b1;
                end
                8'h36: begin  // Key 6 -> num 5
                    num <= 4'd5;
                    player <= 1'b0;
                    input_valid <= 1'b1;
                end
                8'h3D: begin  // Key 7 -> num 6
                    num <= 4'd6;
                    player <= 1'b0;
                    input_valid <= 1'b1;
                end
                8'h3E: begin  // Key 8 -> num 7
                    num <= 4'd7;
                    player <= 1'b0;
                    input_valid <= 1'b1;
                end
                8'h46: begin  // Key 9 -> num 8
                    num <= 4'd8;
                    player <= 1'b0;
                    input_valid <= 1'b1;
                end
                8'h45: begin  // Key 0 -> num 9
                    num <= 4'd9;
                    player <= 1'b0;
                    input_valid <= 1'b1;
                end
                
                // Player 1: Numpad keys (1-0)
                8'h69: begin  // Numpad 1 -> num 0
                    num <= 4'd0;
                    player <= 1'b1;
                    input_valid <= 1'b1;
                end
                8'h72: begin  // Numpad 2 -> num 1
                    num <= 4'd1;
                    player <= 1'b1;
                    input_valid <= 1'b1;
                end
                8'h7A: begin  // Numpad 3 -> num 2
                    num <= 4'd2;
                    player <= 1'b1;
                    input_valid <= 1'b1;
                end
                8'h6B: begin  // Numpad 4 -> num 3
                    num <= 4'd3;
                    player <= 1'b1;
                    input_valid <= 1'b1;
                end
                8'h73: begin  // Numpad 5 -> num 4
                    num <= 4'd4;
                    player <= 1'b1;
                    input_valid <= 1'b1;
                end
                8'h74: begin  // Numpad 6 -> num 5
                    num <= 4'd5;
                    player <= 1'b1;
                    input_valid <= 1'b1;
                end
                8'h6C: begin  // Numpad 7 -> num 6
                    num <= 4'd6;
                    player <= 1'b1;
                    input_valid <= 1'b1;
                end
                8'h75: begin  // Numpad 8 -> num 7
                    num <= 4'd7;
                    player <= 1'b1;
                    input_valid <= 1'b1;
                end
                8'h7D: begin  // Numpad 9 -> num 8
                    num <= 4'd8;
                    player <= 1'b1;
                    input_valid <= 1'b1;
                end
                8'h70: begin  // Numpad 0 -> num 9
                    num <= 4'd9;
                    player <= 1'b1;
                    input_valid <= 1'b1;
                end
                
                default: begin
                    input_valid <= 1'b0;
                end
            endcase
        end else begin
            input_valid <= 1'b0;
        end
    end

endmodule