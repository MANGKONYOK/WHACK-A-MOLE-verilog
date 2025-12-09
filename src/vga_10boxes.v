//////////////////////////////////////////////////////////////////////////////
// screen_10boxes.v
// VGA controller displaying 10 boxes (0-9) in a row
// - All boxes are RED by default
// - Box at index = selected_box is GREEN
// 
// VGA 640x480 @ 60Hz timing (25MHz pixel clock)
//////////////////////////////////////////////////////////////////////////////

module screen_10boxes (
    input  wire       clk,           // 100MHz system clock
    input  wire       rst,           // Active high reset
    input  wire [3:0] selected_box,  // 0-9: which box to highlight green
    
    // VGA outputs
    output reg  [3:0] vgaRed,
    output reg  [3:0] vgaGreen,
    output reg  [3:0] vgaBlue,
    output wire       Hsync,
    output wire       Vsync
);

    //=========================================================================
    // VGA 640x480 @ 60Hz Timing Parameters
    //=========================================================================
    // Pixel clock = 25MHz (derived from 100MHz)
    
    // Horizontal timing (in pixels)
    localparam H_DISPLAY    = 640;
    localparam H_FRONT      = 16;
    localparam H_SYNC       = 96;
    localparam H_BACK       = 48;
    localparam H_TOTAL      = H_DISPLAY + H_FRONT + H_SYNC + H_BACK; // 800
    
    // Vertical timing (in lines)
    localparam V_DISPLAY    = 480;
    localparam V_FRONT      = 10;
    localparam V_SYNC       = 2;
    localparam V_BACK       = 33;
    localparam V_TOTAL      = V_DISPLAY + V_FRONT + V_SYNC + V_BACK; // 525

    //=========================================================================
    // Box Layout Parameters
    //=========================================================================
    // 10 boxes horizontally centered on screen
    localparam BOX_WIDTH    = 50;       // Width of each box
    localparam BOX_HEIGHT   = 50;       // Height of each box
    localparam BOX_GAP      = 5;        // Gap between boxes
    localparam NUM_BOXES    = 10;
    
    // Total width of all boxes + gaps = 10*50 + 9*5 = 545
    localparam TOTAL_WIDTH  = (NUM_BOXES * BOX_WIDTH) + ((NUM_BOXES - 1) * BOX_GAP);
    
    // Starting X position (centered)
    localparam BOX_START_X  = (H_DISPLAY - TOTAL_WIDTH) / 2;  // ~47
    
    // Y position (vertically centered)
    localparam BOX_START_Y  = (V_DISPLAY - BOX_HEIGHT) / 2;   // 215
    
    // Border thickness for box outline
    localparam BORDER       = 3;

    //=========================================================================
    // Clock Divider: 100MHz -> 25MHz
    //=========================================================================
    reg [1:0] clk_div;
    wire      pixel_clk_en;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            clk_div <= 2'b00;
        else
            clk_div <= clk_div + 1'b1;
    end
    
    assign pixel_clk_en = (clk_div == 2'b11);

    //=========================================================================
    // Horizontal and Vertical Counters
    //=========================================================================
    reg [9:0] h_count;  // 0 to 799
    reg [9:0] v_count;  // 0 to 524
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end
        else if (pixel_clk_en) begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 1'b1;
            end
            else begin
                h_count <= h_count + 1'b1;
            end
        end
    end

    //=========================================================================
    // Sync Signals (directly active low for VGA)
    //=========================================================================
    assign Hsync = ~((h_count >= (H_DISPLAY + H_FRONT)) && 
                     (h_count < (H_DISPLAY + H_FRONT + H_SYNC)));
    assign Vsync = ~((v_count >= (V_DISPLAY + V_FRONT)) && 
                     (v_count < (V_DISPLAY + V_FRONT + V_SYNC)));

    //=========================================================================
    // Display Active Region
    //=========================================================================
    wire display_active;
    assign display_active = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

    //=========================================================================
    // Box Detection Logic
    //=========================================================================
    wire [9:0] pixel_x = h_count;
    wire [9:0] pixel_y = v_count;
    
    // Check if we're in the vertical band where boxes are drawn
    wire in_box_row;
    assign in_box_row = (pixel_y >= BOX_START_Y) && (pixel_y < BOX_START_Y + BOX_HEIGHT);
    
    // Calculate which box we might be in (0-9)
    // Each box occupies BOX_WIDTH + BOX_GAP pixels (except last box)
    wire [9:0] rel_x;
    assign rel_x = pixel_x - BOX_START_X;
    
    // Box index calculation
    wire [3:0] box_index;
    assign box_index = rel_x / (BOX_WIDTH + BOX_GAP);
    
    // Position within the box+gap unit
    wire [9:0] pos_in_unit;
    assign pos_in_unit = rel_x % (BOX_WIDTH + BOX_GAP);
    
    // Check if we're inside a box (not in the gap)
    wire in_box_x;
    assign in_box_x = (pixel_x >= BOX_START_X) && 
                      (pixel_x < BOX_START_X + TOTAL_WIDTH) &&
                      (pos_in_unit < BOX_WIDTH);
    
    // Final check: are we drawing a box?
    wire in_box;
    assign in_box = in_box_row && in_box_x && (box_index < NUM_BOXES);
    
    // Check if we're on the border of the box
    wire [9:0] rel_y;
    assign rel_y = pixel_y - BOX_START_Y;
    
    wire on_border;
    assign on_border = in_box && (
        (pos_in_unit < BORDER) ||                           // Left border
        (pos_in_unit >= BOX_WIDTH - BORDER) ||              // Right border
        (rel_y < BORDER) ||                                 // Top border
        (rel_y >= BOX_HEIGHT - BORDER)                      // Bottom border
    );
    
    // Check if this box is the selected one
    wire is_selected;
    assign is_selected = (box_index == selected_box) && (selected_box < NUM_BOXES);

    //=========================================================================
    // Color Output Logic
    //=========================================================================
    // Colors (4-bit per channel)
    localparam [3:0] RED_R   = 4'hF, RED_G   = 4'h0, RED_B   = 4'h0;  // Pure red
    localparam [3:0] GREEN_R = 4'h0, GREEN_G = 4'hF, GREEN_B = 4'h0;  // Pure green
    localparam [3:0] WHITE_R = 4'hF, WHITE_G = 4'hF, WHITE_B = 4'hF;  // White border
    localparam [3:0] BG_R    = 4'h1, BG_G    = 4'h1, BG_B    = 4'h2;  // Dark background
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            vgaRed   <= 4'h0;
            vgaGreen <= 4'h0;
            vgaBlue  <= 4'h0;
        end
        else if (pixel_clk_en) begin
            if (!display_active) begin
                // Blanking period - output black
                vgaRed   <= 4'h0;
                vgaGreen <= 4'h0;
                vgaBlue  <= 4'h0;
            end
            else if (on_border) begin
                // Box border - white
                vgaRed   <= WHITE_R;
                vgaGreen <= WHITE_G;
                vgaBlue  <= WHITE_B;
            end
            else if (in_box) begin
                if (is_selected) begin
                    // Selected box - GREEN
                    vgaRed   <= GREEN_R;
                    vgaGreen <= GREEN_G;
                    vgaBlue  <= GREEN_B;
                end
                else begin
                    // Non-selected box - RED
                    vgaRed   <= RED_R;
                    vgaGreen <= RED_G;
                    vgaBlue  <= RED_B;
                end
            end
            else begin
                // Background
                vgaRed   <= BG_R;
                vgaGreen <= BG_G;
                vgaBlue  <= BG_B;
            end
        end
    end

endmodule