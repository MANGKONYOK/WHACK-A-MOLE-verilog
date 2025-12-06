module clk_divider (
    input wire clk_in,          // 100MHz System Clock
    output reg clk_1kHz,        // 1kHz clock (for Display Multiplexing & Debounce)
    output reg clk_1Hz          // 1Hz clock (for Game Timer)
);

    // Logic to generate 1kHz (1ms)
    // 100MHz / 1kHz = 100,000 cycles
    // Toggle every 50,000 cycles
    reg [16:0] count_1kHz;
    localparam DIV_1KHZ = 50000;

    always @(posedge clk_in) begin
        if (count_1kHz == DIV_1KHZ - 1) begin
            count_1kHz <= 0;
            clk_1kHz <= ~clk_1kHz;
        end else begin
            count_1kHz <= count_1kHz + 1;
        end
    end

    // Logic to generate 1Hz (1s)
    // 100MHz / 1Hz = 100,000,000 cycles
    // Toggle every 50,000,000 cycles
    reg [26:0] count_1Hz;
    localparam DIV_1HZ = 50000000;

    always @(posedge clk_in) begin
        if (count_1Hz == DIV_1HZ - 1) begin
            count_1Hz <= 0;
            clk_1Hz <= ~clk_1Hz;
        end else begin
            count_1Hz <= count_1Hz + 1;
        end
    end

    // Initialize
    initial begin
        clk_1kHz = 0;
        clk_1Hz = 0;
        count_1kHz = 0;
        count_1Hz = 0;
    end

endmodule