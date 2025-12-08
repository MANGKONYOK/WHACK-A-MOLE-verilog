`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: countdown
// Description: 
//     Countdown timer module.
//     Counts down from time_seconds to 0.
//     Outputs current count and done signal when reaches 0.
//     Can be started/stopped and reset.
//////////////////////////////////////////////////////////////////////////////////

module countdown(
    input         clk,
    input         reset,
    input         start,          // Start/enable countdown
    input         stop,           // Stop/pause countdown
    input  [5:0]  time_seconds,   // Initial time in seconds (0-63)
    input         reload,         // Reload timer with time_seconds
    output reg [5:0] count = 6'd0,  // Current count value
    output reg    done = 1'b0     // Countdown reached 0
);

    // 100MHz clock -> 1 second = 100,000,000 cycles
    localparam CYCLES_PER_SECOND = 100_000_000;
    
    reg [26:0] cycle_counter = 27'd0;
    reg running = 1'b0;
    
    always @(posedge clk) begin
        if (reset) begin
            count <= 6'd0;
            cycle_counter <= 27'd0;
            done <= 1'b0;
            running <= 1'b0;
        end else begin
            // Handle reload
            if (reload) begin
                count <= time_seconds;
                cycle_counter <= 27'd0;
                done <= 1'b0;
                running <= 1'b1;
            end
            // Handle start
            else if (start && !running) begin
                if (count == 6'd0) begin
                    count <= time_seconds;
                end
                cycle_counter <= 27'd0;
                done <= 1'b0;
                running <= 1'b1;
            end
            // Handle stop
            else if (stop) begin
                running <= 1'b0;
            end
            // Countdown logic
            else if (running && !done) begin
                if (cycle_counter >= CYCLES_PER_SECOND - 1) begin
                    cycle_counter <= 27'd0;
                    if (count > 6'd0) begin
                        count <= count - 1'b1;
                        if (count == 6'd1) begin
                            done <= 1'b1;
                            running <= 1'b0;
                        end
                    end
                end else begin
                    cycle_counter <= cycle_counter + 1'b1;
                end
            end
        end
    end

endmodule