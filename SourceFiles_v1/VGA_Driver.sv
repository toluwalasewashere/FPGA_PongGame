`timescale 1ns/ 1ps
/* This VGA controller module generates signals for VGA Display
 * Resources:
 * Chu, Pong P. Wiley, 2008. "FPGA Prototyping by Verilog Examples: Xilinx Spartan-3 Version." Ch. 13 VGA Controller I: Graphic.
 * Github Repo: FPGADude/Digital-Design
 * R. Ewetz, "Lecture 14 - VGA Timing and Pixel Coordinates," Lecture, EEL4712 Digital Design, University of Florida,  Florida, United States of America, 2026, [Powerpoint] https://eel4712.ece.ufl.edu/wp-content/uploads/2026/02/EEL4712-14-VGA-Timing-Pixel-Coordinates-1.pdf 
 * N. Ickes. "VGA Video." Massachusetts Institute of Technology. https://web.mit.edu/6.111/www/s2004/NEWKIT/vga.shtml (accessed: Jun. 18, 2026).
 *
*/
module VGA_Driver(
    input wire i_clk, //Input clock signal
    input wire i_rst, //Input reset signal
    output logic o_video_on, //This signal is ON while pixel counts for x and y are within the display area and OFF otherwise.
    
    /*The sync siganals ensure the display knows when to start a new line or frame*/
    output logic o_hsync, //Horizontal synchronization signal
    output logic o_vsync, //Vertical synchronization signal
    
    output logic o_p_tick,//The 25 MHz pixel rate signal
    
    /*The o_counter_x and o_counter_y signals indicate the relative positions of the scans, basically specifying the location of the current pixel.*/
    output logic [9:0] o_counter_x, //pixel count/position of pixel on x-axis(ranges from 0 - 799) 
    output logic [9:0] o_counter_y //pixel count/ position of pixel on y-axis(ranges from 0 - 524)
    );

    /*For the standard 640 x 480 VGA video signal, the frequency of the HSync and VSync signal pulses should be:
    * Vertical Freq. (VS) = 60 Hz (60 pulses per second)
    * Horizontal Freq. (HS) = 31.5 kHz (31,500 pulses per second)
    * However, VGA monitors are often multisync - they can properly synchronize with multiple horizontal and 
    * vertical scan rates - so there may not be a need to generate exactly 60 Hz and 31.5 KHz pulses. 
    */
 
    //Constant Declaration
    //Based on VGA 640-by-480 sync parameters
    
    //Total Horizontal width of screen = 800 pixels, segmented into 4 regions.
    localparam HORIZONTAL_DISPLAY_AREA = 640; //Horizontal Display region width in pixels
    localparam HORIZONTAL_BACK_PORCH = 48; //Horizontal Back Porch region (left border) width in pixels
    localparam HORIZONTAL_FRONT_PORCH = 16; //Horizontal Front Porch region (right border) width in pixels
    localparam HORIZONTAL_RETRACE = 96; //Horizontal Retrace region width in pixels
    localparam HORIZONTAL_MAX = HORIZONTAL_DISPLAY_AREA+HORIZONTAL_BACK_PORCH+HORIZONTAL_FRONT_PORCH+HORIZONTAL_RETRACE-1;
 
    //Total Vertical height of screen = 525 pixels, segmented into 4 regions. 
    localparam VERTICAL_DISPLAY_AREA = 480; //Vertical Display region height in pixels
    localparam VERTICAL_FRONT_PORCH = 10; //Vertical Front Porch region (Bottom border) height in pixels
    localparam VERTICAL_BACK_PORCH = 33; //Vertical Back Porch region (Top border) height in pixels
    localparam VERTICAL_RETRACE = 2; //Vertical Retrace region height in pixels
    localparam VERTICAL_MAX = VERTICAL_DISPLAY_AREA+VERTICAL_FRONT_PORCH+VERTICAL_BACK_PORCH+VERTICAL_RETRACE-1;
    
    
    //mod-4 counter used to generate 25 MHz pixel rate signal from the 100 MHz input clock signal.
    /* Counter has 4 states, transitioning from one to the next at each positive clock edge.
     * Our output signal is only HIGH in one. In other words, the output signal is high once every four positive clock edges.
     * Thus, the output signal divides the input clock signal frequency by four. 
     */
    reg [1:0] r_25MHz;
    wire w_25MHz;
    
    always @ (posedge i_clk or posedge i_rst) begin
        if (i_rst) r_25MHz <= 0; //Asynchronous reset behaviour
        else r_25MHz <= r_25MHz + 1'b1;
    end
    assign w_25MHz = (r_25MHz == 0) ? 1:0; 
    
    //Sync Counter Registers
    /*Using two for each counter for buffering so we can avoid glitches*/
    reg [9:0] h_count_reg, h_count_next;
    reg [9:0] v_count_reg, v_count_next;
    
    
    //Output Buffers
    reg v_sync_reg, h_sync_reg;
    wire v_sync_next, h_sync_next;
    
    //Status signals
    wire h_end, v_end;
    assign h_end = (h_count_reg == HORIZONTAL_MAX); //End of horizontal counter (799)
    assign v_end = (v_count_reg == VERTICAL_MAX); // End of vertical counter (524)
    
    //Register Control
    always @ (posedge i_clk or posedge i_rst) begin
        if (i_rst) begin //Asynchronous reset behaviour
            v_count_reg <= 0;
            h_count_reg <= 0;
            v_sync_reg <= 0;
            h_sync_reg <= 0;
        end
        else begin
            v_count_reg <= v_count_next;
            h_count_reg <= h_count_next;
            v_sync_reg <= v_sync_next;
            h_sync_reg <= h_sync_next;
        end
    end
    
    //Logic for Mod-800 horizontal counter
    always @(posedge w_25MHz or posedge i_rst) begin
        if (i_rst) h_count_next <= 0; //Asynchronous reset behaviour
        else begin
            if (h_end) h_count_next <= 0; //If counter has hit maximum value, roll over to 0.
            else h_count_next <= h_count_reg + 1'b1; //Otherwise, increase the current count by 1.
        end
    end
    
    //Logic for mod-525 vertical counter
    always @(posedge w_25MHz or posedge i_rst) begin
        if (i_rst) v_count_next <= 0; //Asynchrounous reset behaviour
        else begin
            if (h_end) begin //End of horizontal scan
                if (v_end) v_count_next <= 0; //If counter has reached maximum value, roll over to 0. (At this point, we've reached the end of the last scan(Horizontal or Vertical))
                else v_count_next <= v_count_reg + 1'b1; //Otherwise, increment the current count by 1.
            end
        end
    end
    
    //Assert h_sync_next within the horizontal retrace area
    assign h_sync_next = (h_count_reg >= (HORIZONTAL_DISPLAY_AREA+HORIZONTAL_BACK_PORCH) && h_count_reg <= (HORIZONTAL_DISPLAY_AREA+HORIZONTAL_BACK_PORCH+HORIZONTAL_RETRACE-1));
    
    //Assert v_sync_next within the vertical retrace area
    assign v_sync_next = (v_count_reg >= (VERTICAL_DISPLAY_AREA+VERTICAL_BACK_PORCH) && v_count_reg <= (VERTICAL_DISPLAY_AREA+VERTICAL_BACK_PORCH+VERTICAL_RETRACE-1));
    
    //Assert o_video_on only while the pixel counts are within the display area
    assign o_video_on = ((h_count_reg < HORIZONTAL_DISPLAY_AREA) && (v_count_reg < VERTICAL_DISPLAY_AREA)); //0 to 639 and 0 to 479 respectively.
    
    //OUTPUT SIGNALS
    assign o_h_sync = h_sync_reg;
    assign o_v_sync = v_sync_reg;
    assign o_counter_x = h_count_reg;
    assign o_counter_y = v_count_reg;
    assign o_p_tick = w_25MHz;
    
    
endmodule 