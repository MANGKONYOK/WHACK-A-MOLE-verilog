module input_sync (
    input wire clk,             // Low-frequency clock (e.g., 1kHz from clk_divider)
    input wire btn_raw,         // Raw button input from the board (Asynchronous)
    input wire [8:0] sw_raw,    // Raw switch inputs from the board (Asynchronous)
    
    output reg btn_clean,       // Debounced and synchronized button signal (to FSM)
    output reg [8:0] sw_clean   // Debounced and synchronized switch signals (to Hit Detect)
);

    // Button Debounce Logic (Shift Register)
    // Shift register to store the last 3 samples of the button state
    reg [2:0] btn_shift;

    always @(posedge clk) begin
        // Shift the raw input into the register (Shift Left)
        btn_shift <= {btn_shift[1:0], btn_raw};

        // Decision Logic 
        // If all 3 samples are 1, consider it PRESSED.
        // If all 3 samples are 0, consider it RELEASED.
        if (btn_shift == 3'b111)
            btn_clean <= 1'b1;
        else if (btn_shift == 3'b000)
            btn_clean <= 1'b0;
        // Else
    end


    // Switch Debounce Logic
    // Uses the same logic as the button but looped for all 9 switches
    integer i;
    reg [2:0] sw_shift [8:0]; // Array of 3-bit shift registers for 9 switches

    always @(posedge clk) begin
        for (i = 0; i < 9; i = i + 1) begin
            // Shift the raw input into the specific register
            sw_shift[i] <= {sw_shift[i][1:0], sw_raw[i]};

            // Decision Logic for each switch
            if (sw_shift[i] == 3'b111)
                sw_clean[i] <= 1'b1;
            else if (sw_shift[i] == 3'b000)
                sw_clean[i] <= 1'b0;
            // Maintain previous state
        end
    end

endmodule