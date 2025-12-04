module seven_seg (

    input wire clk,             // 1kHz clock (from clk_divider)
    input wire [6:0] score_in,  // Score input (from Data Storage)
    input wire [6:0] time_in,   // Time input (from Data Storage)
    output reg [6:0] seg,       // Cathode pins (a-g)
    output reg [3:0] an         // Anode pins

);

    // Binary to BCD Conversion (Simple division for small numbers)
    // Note: This assumes inputs are 0-99. If >99, it wraps
    wire [3:0] time_tens, time_units;
    wire [3:0] score_tens, score_units;

    assign time_tens = (time_in / 10) % 10;
    assign time_units = time_in % 10;
    assign score_tens = (score_in / 10) % 10;
    assign score_units = score_in % 10;

    // Multiplexing Counter
    // Counts 0->1->2->3 to switch between the 4 digits
    reg [1:0] digit_select;
    always @(posedge clk) begin
        digit_select <= digit_select + 1;
    end

    // Digit Selection Logic (Active Low Anodes)
    reg [3:0] current_digit_val;
    
    always @(*) begin
        case (digit_select)
            2'b00: begin // Digit 0 (Rightmost) -> Score Units
                an = 4'b1110; 
                current_digit_val = score_units;
            end
            2'b01: begin // Digit 1 -> Score Tens
                an = 4'b1101; 
                current_digit_val = score_tens;
            end
            2'b10: begin // Digit 2 -> Time Units
                an = 4'b1011; 
                current_digit_val = time_units;
            end
            2'b11: begin // Digit 3 (Leftmost) -> Time Tens
                an = 4'b0111; 
                current_digit_val = time_tens;
            end
            default: begin
                an = 4'b1111;
                current_digit_val = 0;
            end
        endcase
    end

    // 7-Segment Decoder (Active Low Segments for Basys3)
    // Pattern: gfedcba (0 = ON)
    always @(*) begin
        case (current_digit_val)
            4'h0: seg = 7'b1000000; // 0
            4'h1: seg = 7'b1111001; // 1
            4'h2: seg = 7'b0100100; // 2
            4'h3: seg = 7'b0110000; // 3
            4'h4: seg = 7'b0011001; // 4
            4'h5: seg = 7'b0010010; // 5
            4'h6: seg = 7'b0000010; // 6
            4'h7: seg = 7'b1111000; // 7
            4'h8: seg = 7'b0000000; // 8
            4'h9: seg = 7'b0010000; // 9
            default: seg = 7'b1111111; // OFF
        endcase
    end

endmodule