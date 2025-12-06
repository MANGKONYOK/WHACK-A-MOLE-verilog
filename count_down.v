module tb;
    reg clk = 0, rst = 0, start = 0;
    wire [6:0] count;

    countdown60 uut(clk, rst, start, count);

    // Clock 1 Hz (toggle every 1 second)
    always #1 clk = ~clk;

    initial begin
        $monitor("Time=%0t | count=%0d", $time, count);

        rst = 1; #2; rst = 0;
        start = 1; // Start countdown

        #200; // Wait for count completion
        $finish;
    end
endmodule

module countdown60 (
    input wire clk,       // clock
    input wire rst,       // reset
    input wire start,     // input=1 => Start countdown
    output reg [6:0] count // Count 60..0
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 7'd60;   // Load 60 seconds
        end
        else begin
            if (start) begin
                if (count > 0)
                    count <= count - 1;
            end
        end
    end

endmodule