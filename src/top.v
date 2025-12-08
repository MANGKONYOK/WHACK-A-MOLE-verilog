`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: top
// Description: 
//     Top module for Basys3 2-Player Reaction Game.
//     - Press btnC to start game (60 second game)
//     - sw[1:0] sets difficulty: 00=Easy(4s), 01=Medium(3s), 10=Hard(2s), 11=Pro(1s)
//     - Random LED lights up (0-9)
//     - Player 0: Number row keys (1-0) - Score on left (digits 2,3)
//     - Player 1: Numpad keys (1-0) - Score on right (digits 0,1)
//     - Correct press: +1 point, Wrong press: -1 point (min 0)
//     - UART outputs key codes for debugging
//////////////////////////////////////////////////////////////////////////////////

module top(
    input         clk,
    input         PS2Data,
    input         PS2Clk,
    input         btnC,          // Center button - Start game
    input  [1:0]  sw,            // sw[1:0] - Difficulty level
    output        tx,
    output [15:0] led,
    output [6:0]  seg,           // 7-segment display segments
    output [3:0]  an             // 7-segment display anodes
);
    // Internal wires
    wire [7:0]  key;
    wire        key_valid;
    wire [3:0]  num;
    wire        player;
    wire        input_valid;
    wire        game_active;
    wire [6:0]  score_p0;
    wire [6:0]  score_p1;
    
    // Reset signal (active for first cycles)
    reg [3:0] reset_cnt = 4'hF;
    wire reset = (reset_cnt != 4'd0);
    
    always @(posedge clk) begin
        if (reset_cnt != 4'd0)
            reset_cnt <= reset_cnt - 1'b1;
    end
    
    // Button debouncing
    wire btnC_debounced;
    
    debouncer #(
        .COUNT_MAX(1000000),    // ~10ms debounce at 100MHz
        .COUNT_WIDTH(20)
    ) btn_debounce (
        .clk(clk),
        .I(btnC),
        .O(btnC_debounced)
    );
    
    // UART signals (for debugging)
    wire        tready;
    wire        ready;
    wire        tstart;
    reg         start = 0;
    wire [31:0] tbuf;
    reg  [15:0] keycodev = 0;
    reg  [2:0]  bcount = 0;
    wire [7:0]  tbus;
    reg         cn = 0;
    
    //=========================================================================
    // Get Key Module - PS2 Keyboard Input
    //=========================================================================
    get_key get_key_inst (
        .clk(clk),
        .PS2Data(PS2Data),
        .PS2Clk(PS2Clk),
        .key(key),
        .key_valid(key_valid)
    );
    
    //=========================================================================
    // Key to Input Conversion
    // Number row (1-0) -> Player 0, Numpad (1-0) -> Player 1
    //=========================================================================
    key2input key2input_inst (
        .clk(clk),
        .key(key),
        .key_valid(key_valid),
        .num(num),
        .player(player),
        .input_valid(input_valid)
    );
    
    //=========================================================================
    // Game Controller (includes random, LED display, scoreboard, timers)
    //=========================================================================
    game game_inst (
        .clk(clk),
        .reset(reset),
        .btn_start(btnC_debounced),
        .difficulty(sw[1:0]),      // Difficulty from switches
        .num(num),
        .player(player),
        .input_valid(input_valid),
        .led(led),
        .seg(seg),
        .an(an),
        .score_p0(score_p0),
        .score_p1(score_p1),
        .game_active(game_active)
    );
    
    //=========================================================================
    // UART Output (for debugging - outputs key codes)
    //=========================================================================
    
    // Detect key changes for UART output
    always @(key or key_valid) begin
        if (key_valid) begin
            cn <= 1'b1;
            bcount <= 3'd2;
        end else begin
            cn <= 1'b0;
            bcount <= 3'd0;
        end
    end
    
    always @(posedge clk) begin
        if (key_valid && cn) begin
            start <= 1'b1;
            keycodev <= {8'h00, key};
        end else begin
            start <= 1'b0;
        end
    end
    
    // Binary to ASCII conversion for UART
    bin2ascii #(
        .NBYTES(2)
    ) conv (
        .I(keycodev),
        .O(tbuf)
    );
    
    // UART buffer controller
    uart_buf_con tx_con (
        .clk(clk),
        .bcount(bcount),
        .tbuf(tbuf),
        .start(start),
        .ready(ready),
        .tstart(tstart),
        .tready(tready),
        .tbus(tbus)
    );
    
    // UART transmitter
    uart_tx get_tx (
        .clk(clk),
        .start(tstart),
        .tbus(tbus),
        .tx(tx),
        .ready(tready)
    );

endmodule