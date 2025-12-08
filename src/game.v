`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: game
// Description: 
//     2-Player Reaction Game Controller with Countdown Timers.
//     - Game timer: 60 seconds total game time
//     - LED timer: Configurable by difficulty level (sw[1:0])
//       00=Easy(4s), 01=Medium(3s), 10=Hard(2s), 11=Pro(1s)
//     - Press btnC to start game
//     - Correct answer: +1 point, Wrong answer: -1 point (min 0)
//     - Game ends when 60s timer expires
//     - Score display: Player 0 (digits 2,3 - left), Player 1 (digits 0,1 - right)
//////////////////////////////////////////////////////////////////////////////////

module game(
    input         clk,
    input         reset,
    input         btn_start,      // Button to start game
    input  [1:0]  difficulty,     // sw[1:0]: 00=Easy, 01=Medium, 10=Hard, 11=Pro
    input  [3:0]  num,            // Number from key press (0-9)
    input         player,         // Player ID (0 or 1)
    input         input_valid,    // Key press valid signal
    output reg [15:0] led = 16'h0000,  // LED output
    output reg [6:0]  seg = 7'b1111111, // 7-segment segments
    output reg [3:0]  an = 4'b1111,     // 7-segment anodes
    output reg [6:0]  score_p0 = 7'd0,  // Player 0 final score (0-99)
    output reg [6:0]  score_p1 = 7'd0,  // Player 1 final score (0-99)
    output reg        game_active = 1'b0  // Game is running
);

    //=========================================================================
    // Game States
    //=========================================================================
    localparam STATE_IDLE     = 3'd0;  // Waiting for start button
    localparam STATE_INIT     = 3'd1;  // Initialize game
    localparam STATE_DISPLAY  = 3'd2;  // Get random and display LED
    localparam STATE_WAIT_KEY = 3'd3;  // Wait for player input
    localparam STATE_CHECK    = 3'd4;  // Check if correct
    localparam STATE_END      = 3'd5;  // Game ended, show scores
    
    reg [2:0] state = STATE_IDLE;
    reg [3:0] target_num = 4'd0;       // Current target number to match
    
    //=========================================================================
    // Difficulty Level -> LED Timer Duration
    //=========================================================================
    reg [5:0] led_timer_duration = 6'd4;  // Default: Easy (4 seconds)
    
    always @(*) begin
        case (difficulty)
            2'b00: led_timer_duration = 6'd4;   // Easy: 4 seconds
            2'b01: led_timer_duration = 6'd3;   // Medium: 3 seconds
            2'b10: led_timer_duration = 6'd2;   // Hard: 2 seconds
            2'b11: led_timer_duration = 6'd1;   // Pro: 1 second
            default: led_timer_duration = 6'd4;
        endcase
    end
    
    //=========================================================================
    // Random Number Generator (LFSR)
    //=========================================================================
    reg [15:0] lfsr = 16'hACE1;
    wire feedback;
    
    assign feedback = lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3];
    
    always @(posedge clk) begin
        if (reset) begin
            lfsr <= 16'hACE1;
        end else begin
            lfsr <= {lfsr[14:0], feedback};
        end
    end
    
    //=========================================================================
    // Game Countdown Timer (60 seconds)
    //=========================================================================
    reg game_timer_start = 1'b0;
    reg game_timer_stop = 1'b0;
    reg game_timer_reload = 1'b0;
    wire [5:0] game_time_left;
    wire game_timer_done;
    
    countdown game_timer (
        .clk(clk),
        .reset(reset),
        .start(game_timer_start),
        .stop(game_timer_stop),
        .time_seconds(6'd60),      // 60 second game
        .reload(game_timer_reload),
        .count(game_time_left),
        .done(game_timer_done)
    );
    
    //=========================================================================
    // LED Display Countdown Timer (variable based on difficulty)
    //=========================================================================
    reg led_timer_start = 1'b0;
    reg led_timer_stop = 1'b0;
    reg led_timer_reload = 1'b0;
    wire [5:0] led_time_left;
    wire led_timer_done;
    
    countdown led_timer (
        .clk(clk),
        .reset(reset),
        .start(led_timer_start),
        .stop(led_timer_stop),
        .time_seconds(led_timer_duration),  // Based on difficulty
        .reload(led_timer_reload),
        .count(led_time_left),
        .done(led_timer_done)
    );
    
    //=========================================================================
    // Scoreboard - Player Scores (signed to handle subtraction logic)
    //=========================================================================
    reg [6:0] p0_score = 7'd0;   // Player 0 score (0-99)
    reg [6:0] p1_score = 7'd0;   // Player 1 score (0-99)
    
    // Score digits for display
    // Player 0: digits 2,3 (left side)
    // Player 1: digits 0,1 (right side)
    reg [3:0] p0_ones = 4'd0;    // Player 0 ones digit
    reg [3:0] p0_tens = 4'd0;    // Player 0 tens digit
    reg [3:0] p1_ones = 4'd0;    // Player 1 ones digit
    reg [3:0] p1_tens = 4'd0;    // Player 1 tens digit
    
    //=========================================================================
    // 7-Segment Display Multiplexing
    //=========================================================================
    reg [16:0] refresh_counter = 17'd0;
    wire [1:0] digit_select;
    reg [3:0] current_digit;
    
    assign digit_select = refresh_counter[16:15];
    
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1'b1;
    end
    
    // Digit multiplexer
    // Display format: [P0 tens][P0 ones][P1 tens][P1 ones]
    //                   an[3]    an[2]    an[1]    an[0]
    // Player 0 on left (an[3:2]), Player 1 on right (an[1:0])
    always @(*) begin
        case (digit_select)
            2'b00: begin
                an = 4'b1110;  // Digit 0: Player 1 ones (rightmost)
                current_digit = p1_ones;
            end
            2'b01: begin
                an = 4'b1101;  // Digit 1: Player 1 tens
                current_digit = p1_tens;
            end
            2'b10: begin
                an = 4'b1011;  // Digit 2: Player 0 ones
                current_digit = p0_ones;
            end
            2'b11: begin
                an = 4'b0111;  // Digit 3: Player 0 tens (leftmost)
                current_digit = p0_tens;
            end
            default: begin
                an = 4'b1111;
                current_digit = 4'd0;
            end
        endcase
    end
    
    // 7-segment decoder (active low)
    always @(*) begin
        case (current_digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end
    
    //=========================================================================
    // Button Edge Detection
    //=========================================================================
    reg btn_start_prev = 1'b0;
    reg btn_start_sync1 = 1'b0;
    reg btn_start_sync2 = 1'b0;
    wire btn_start_pulse;
    
    // Synchronize button input
    always @(posedge clk) begin
        btn_start_sync1 <= btn_start;
        btn_start_sync2 <= btn_start_sync1;
        btn_start_prev <= btn_start_sync2;
    end
    
    assign btn_start_pulse = btn_start_sync2 && !btn_start_prev;
    
    //=========================================================================
    // LED Display Logic
    //=========================================================================
    reg [3:0] display_num = 4'd0;
    
    always @(*) begin
        led = 16'h0000;
        if (game_active && (state == STATE_WAIT_KEY || state == STATE_CHECK)) begin
            case (display_num)
                4'd0: led = 16'b0000_0000_0000_0001;
                4'd1: led = 16'b0000_0000_0000_0010;
                4'd2: led = 16'b0000_0000_0000_0100;
                4'd3: led = 16'b0000_0000_0000_1000;
                4'd4: led = 16'b0000_0000_0001_0000;
                4'd5: led = 16'b0000_0000_0010_0000;
                4'd6: led = 16'b0000_0000_0100_0000;
                4'd7: led = 16'b0000_0000_1000_0000;
                4'd8: led = 16'b0000_0001_0000_0000;
                4'd9: led = 16'b0000_0010_0000_0000;
                default: led = 16'h0000;
            endcase
        end
    end
    
    //=========================================================================
    // Score to Digits Conversion
    //=========================================================================
    always @(posedge clk) begin
        // Convert Player 0 score to digits
        p0_ones <= p0_score % 10;
        p0_tens <= (p0_score / 10) % 10;
        
        // Convert Player 1 score to digits
        p1_ones <= p1_score % 10;
        p1_tens <= (p1_score / 10) % 10;
    end
    
    //=========================================================================
    // Initialization Delay Counter
    //=========================================================================
    reg [23:0] init_counter = 24'd0;
    localparam INIT_DELAY = 24'd10_000_000;  // ~100ms at 100MHz
    
    //=========================================================================
    // Input Edge Detection
    //=========================================================================
    reg input_valid_prev = 1'b0;
    wire input_pulse;
    
    assign input_pulse = input_valid && !input_valid_prev;
    
    // Store which player pressed
    reg check_player = 1'b0;
    reg [3:0] check_num = 4'd0;
    
    //=========================================================================
    // Game State Machine
    //=========================================================================
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_IDLE;
            target_num <= 4'd0;
            display_num <= 4'd0;
            p0_score <= 7'd0;
            p1_score <= 7'd0;
            score_p0 <= 7'd0;
            score_p1 <= 7'd0;
            game_active <= 1'b0;
            init_counter <= 24'd0;
            input_valid_prev <= 1'b0;
            game_timer_start <= 1'b0;
            game_timer_stop <= 1'b0;
            game_timer_reload <= 1'b0;
            led_timer_start <= 1'b0;
            led_timer_stop <= 1'b0;
            led_timer_reload <= 1'b0;
            check_player <= 1'b0;
            check_num <= 4'd0;
        end else begin
            input_valid_prev <= input_valid;
            
            // Default: clear one-shot signals
            game_timer_start <= 1'b0;
            game_timer_stop <= 1'b0;
            game_timer_reload <= 1'b0;
            led_timer_start <= 1'b0;
            led_timer_stop <= 1'b0;
            led_timer_reload <= 1'b0;
            
            case (state)
                STATE_IDLE: begin
                    game_active <= 1'b0;
                    // Wait for start button
                    if (btn_start_pulse) begin
                        state <= STATE_INIT;
                        p0_score <= 7'd0;
                        p1_score <= 7'd0;
                        init_counter <= 24'd0;
                    end
                end
                
                STATE_INIT: begin
                    game_active <= 1'b1;
                    // Wait for LFSR entropy
                    if (init_counter < INIT_DELAY) begin
                        init_counter <= init_counter + 1'b1;
                    end else begin
                        // Start game timer (60 seconds)
                        game_timer_reload <= 1'b1;
                        state <= STATE_DISPLAY;
                    end
                end
                
                STATE_DISPLAY: begin
                    // Check if game time is up
                    if (game_timer_done) begin
                        state <= STATE_END;
                        led_timer_stop <= 1'b1;
                    end else begin
                        // Get random number and display
                        target_num <= lfsr[3:0] % 10;
                        display_num <= lfsr[3:0] % 10;
                        // Start LED timer (based on difficulty)
                        led_timer_reload <= 1'b1;
                        state <= STATE_WAIT_KEY;
                    end
                end
                
                STATE_WAIT_KEY: begin
                    // Check if game time is up
                    if (game_timer_done) begin
                        state <= STATE_END;
                        led_timer_stop <= 1'b1;
                    end
                    // Check if LED timer expired (timeout, no one pressed correctly)
                    else if (led_timer_done) begin
                        // Timeout! Display new random LED
                        state <= STATE_DISPLAY;
                    end
                    // Check for player input
                    else if (input_pulse) begin
                        // Store the input for checking
                        check_player <= player;
                        check_num <= num;
                        state <= STATE_CHECK;
                    end
                end
                
                STATE_CHECK: begin
                    // Check if game time is up
                    if (game_timer_done) begin
                        state <= STATE_END;
                        led_timer_stop <= 1'b1;
                    end else begin
                        // Check if pressed key matches target
                        if (check_num == target_num) begin
                            // Correct! Give point to the player who pressed
                            if (check_player == 1'b0) begin
                                // Player 0 scored +1
                                if (p0_score < 7'd99) begin
                                    p0_score <= p0_score + 1'b1;
                                end
                            end else begin
                                // Player 1 scored +1
                                if (p1_score < 7'd99) begin
                                    p1_score <= p1_score + 1'b1;
                                end
                            end
                            // Target hit -> display new random LED
                            state <= STATE_DISPLAY;
                        end else begin
                            // Wrong key! Penalize the player who pressed (-1, min 0)
                            if (check_player == 1'b0) begin
                                // Player 0 penalty
                                if (p0_score > 7'd0) begin
                                    p0_score <= p0_score - 1'b1;
                                end
                            end else begin
                                // Player 1 penalty
                                if (p1_score > 7'd0) begin
                                    p1_score <= p1_score - 1'b1;
                                end
                            end
                            // Go back to waiting (same LED still active)
                            state <= STATE_WAIT_KEY;
                        end
                    end
                end
                
                STATE_END: begin
                    game_active <= 1'b0;
                    game_timer_stop <= 1'b1;
                    led_timer_stop <= 1'b1;
                    // Store final scores
                    score_p0 <= p0_score;
                    score_p1 <= p1_score;
                    // Wait for start button to begin new game
                    if (btn_start_pulse) begin
                        state <= STATE_INIT;
                        p0_score <= 7'd0;
                        p1_score <= 7'd0;
                        init_counter <= 24'd0;
                    end
                end
                
                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule