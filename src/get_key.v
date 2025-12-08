`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: get_key
// Description: 
//     Receives PS/2 keyboard input and outputs the key scancode.
//     Outputs key_valid pulse when a new key is pressed (not released).
//////////////////////////////////////////////////////////////////////////////////

module get_key(
    input         clk,
    input         PS2Data,
    input         PS2Clk,
    output reg [7:0] key = 8'h00,
    output reg    key_valid = 1'b0
);
    reg         CLK50MHZ = 0;
    wire [15:0] keycode;
    wire        flag;
    reg  [15:0] keycodev = 0;
    reg         cn = 0;
    
    // Generate 50MHz clock from 100MHz
    always @(posedge clk) begin
        CLK50MHZ <= ~CLK50MHZ;
    end
    
    // PS2 Receiver instance
    PS2Receiver ps2_inst (
        .clk(CLK50MHZ),
        .kclk(PS2Clk),
        .kdata(PS2Data),
        .keycode(keycode),
        .oflag(flag)
    );
    
    // Detect new key press (not release)
    always @(keycode) begin
        if (keycode[7:0] == 8'hF0) begin
            // Break code prefix - key release starting
            cn <= 1'b0;
        end else if (keycode[15:8] == 8'hF0) begin
            // This is a key release (F0 + scancode)
            cn <= 1'b0;
        end else begin
            // This is a key press (new key or different from previous)
            cn <= (keycode[7:0] != keycodev[7:0]) || (keycodev[15:8] == 8'hF0);
        end
    end
    
    // Output key and valid signal on new key press
    always @(posedge clk) begin
        if (flag == 1'b1 && cn == 1'b1) begin
            key <= keycode[7:0];
            key_valid <= 1'b1;
            keycodev <= keycode;
        end else begin
            key_valid <= 1'b0;
        end
    end

endmodule