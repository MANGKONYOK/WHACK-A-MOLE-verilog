`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: led_display
// Description: 
//     Takes a number (0-9) as input and turns on the corresponding LED.
//     LED mapping: led[0] for num=0, led[1] for num=1, etc.
//     LED pins are remapped in constraints:
//     L1 -> led[0], P1 -> led[1], N3 -> led[2], P3 -> led[3], etc.
//////////////////////////////////////////////////////////////////////////////////

module led_display(
    input         clk,
    input  [3:0]  num,
    input         num_valid,
    output reg [15:0] led = 16'h0000
);

    always @(posedge clk) begin
        if (num_valid) begin
            // Turn on LED corresponding to the number pressed
            // Only show LEDs 0-9 for number keys
            case (num)
                4'd0: led <= 16'b0000_0000_0000_0001;  // led[0]
                4'd1: led <= 16'b0000_0000_0000_0010;  // led[1]
                4'd2: led <= 16'b0000_0000_0000_0100;  // led[2]
                4'd3: led <= 16'b0000_0000_0000_1000;  // led[3]
                4'd4: led <= 16'b0000_0000_0001_0000;  // led[4]
                4'd5: led <= 16'b0000_0000_0010_0000;  // led[5]
                4'd6: led <= 16'b0000_0000_0100_0000;  // led[6]
                4'd7: led <= 16'b0000_0000_1000_0000;  // led[7]
                4'd8: led <= 16'b0000_0001_0000_0000;  // led[8]
                4'd9: led <= 16'b0000_0010_0000_0000;  // led[9]
                default: led <= 16'h0000;
            endcase
        end
    end

endmodule