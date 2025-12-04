module game_fsm (

    input wire clk,
    input wire reset,          // Active High (Button BTNC)
    input wire start_btn,      // start button (MUST BE DEBOUNCED EXTERNALLY)
    input wire game_time_up,   // from timer module (Must be Synchronous to clk)
    
    output reg game_active,    // 1 = start game
    output reg sys_reset       // 1 = reset system
    output wire [1:0] current_state_debug // for debugging
);

    // State Encoding (Moore Machine) 
    localparam S_IDLE = 2'b00;
    localparam S_PLAY = 2'b01;
    localparam S_DONE = 2'b10;

    reg [1:0] current_state, next_state;

    // Edge Detection Logic
    reg btn_prev;
    wire btn_pressed; // signal Pulse 1 cycle

    always @(posedge clk) begin
        btn_prev <= start_btn;
    end

    // Rising Edge
    assign btn_pressed = (start_btn == 1'b1) && (btn_prev == 1'b0);

    // State Register
    always @(posedge clk or posedge reset) begin
        if (reset) 
            current_state <= S_IDLE;
        else       
            current_state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        // Default assignment
        next_state = current_state;

        case (current_state)
            S_IDLE: begin
                // wait for start button (Pulse)
                if (btn_pressed) 
                    next_state = S_PLAY;
            end

            S_PLAY: begin
                // reset if press button again (Optional)
                if (btn_pressed)
                    next_state = S_IDLE;
                // if time up, go to done state
                else if (game_time_up)
                    next_state = S_DONE;
            end

            S_DONE: begin
                // reset if press button again (DONE -> IDLE -> PLAY)
                if (btn_pressed)
                    next_state = S_IDLE;
            end
            
            default: next_state = S_IDLE;
        endcase
    end

    // Output Logic (Moore: depends only on State)
    always @(*) begin
        // Default outputs
        game_active = 0;
        sys_reset = 0;

        case (current_state)
            S_IDLE: begin
                sys_reset = 1;      // reset score
            end
            S_PLAY: begin
                game_active = 1;    // allow to play
            end
            S_DONE: begin
                // do nothing (show score)
            end
        endcase
    end

    assign current_state_debug = current_state; // for debugging

endmodule