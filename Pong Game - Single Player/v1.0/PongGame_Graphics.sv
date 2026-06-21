`timescale 1ns / 1ps
/* This module incorporates both an object-mapped scheme and a bit-mapped scheme to generate the display for the pong game.
 * An object-mapped scheme uses several object generation circuits instead of storing the data to be displayed in video memory.
 * A bit-mapped scheme uses video memory to store the data to be displayed on the screen. Each pixel is associated with a specific memory word, and 
 * the i_pixel_x(o_counter_x in the VGA_Driver module) and i_pixel_y signals (o_counter_y in the VGA_Driver module) form the address of that memory word. 
 * A graphics processing circuit constantly updates the screen and writes data to the video memory while a retrieval circuit constantly reads the video
 * memory and directs the data to the RGB signal. 
 *
 * References:
 * Chu, Pong P. Wiley, 2008. "FPGA Prototyping by Verilog Examples: Xilinx Spartan-3 Version." Ch. 13 VGA Controller I: Graphic.
 * Github Repo: FPGADude/Digital-Design
*/


module PongGame_Graphics(
    input wire i_clk, //Input clock signal
    input wire i_rst, //Input reset signal
    input wire i_btnUP, //UP Button signal
    input wire i_btnDWN,//DOWN Button signal
    input logic i_video_on, //Input signal - ON while the pixel counts for X and Y are within the display area (see VGA_Driver module)
    input logic [9:0] i_pixel_x, i_pixel_y, //Input signals - Pixel counts for X and Y
    output logic [11:0] o_graph_rgb //The output RGB signals for the display
    );
    
    /*----- Display Area constants -----*/
    localparam MAX_X = 639; //x-coordinates range from 0 to 639 in the display area
    localparam MAX_Y = 479; //y-coordinates range from 0 to 479 in the display area
    
    /*----- 60Hz Refresh Rate Tick Signal -----*/
    wire refresh_tick;
    assign refresh_tick = ((i_pixel_y == 481) && (i_pixel_x == 0)); //Signal should pulse at the start of vsync pulse(during the vertical retrace period)
    
    /*----- Vertical Stripe as wall -----*/
    localparam WALL_L = 32;
    localparam WALL_R = 40; //8 pixels wide
    
    /*----- Vertical bar used as a paddle -----*/
    localparam BAR_L = 600; //Paddle left boundary
    localparam BAR_R = 603; //Paddle right boundary
    localparam BAR_Y_SIZE = 72; //Paddle height
    wire [9:0] y_bar_t, y_bar_b; //Paddle top and bottom boundary signals -- In case I ever forget ... These registers are 10 bits because that's the number required to store the x and y coords
    reg [9:0] y_bar_reg = 10'd204;//Paddle starting positon
    reg [9:0] y_bar_next; //Next position of bar
    localparam BAR_VELOCITY = 3; //Velocity of the paddle when button is pressed
    
    
    /*----- Round Ball -----*/
    localparam BALL_SIZE = 8; // Ball size - the name makes this fairly obvious - size is linked to the size of the ROM we use for the ball.
    wire [9:0] x_ball_l, x_ball_r; //Ball left and right boundary signals
    wire [9:0] y_ball_t, y_ball_b; //Ball top and bottom boundary signals
    reg [9:0] y_ball_reg, x_ball_reg; //Registers to track the y-position and x-position of the top left "corner" of the ball
    reg [9:0] y_ball_next, x_ball_next; //Registers for y-position and x-position buffering.
    reg [9:0] x_delta_reg, x_delta_next; //Registers to track ball speed and buffers (x-axis)
    reg [9:0] y_delta_reg, y_delta_next; //Registers for track ball speed and buffers (y-axis)
    
    localparam BALL_VELOCITY_POS = 2; //The ball speed in the positive pixel direction (down, right)
    localparam BALL_VELOCITY_NEG = -2; //The ball speed in the negative pixel direction (up, left)
    
    wire [2:0] rom_addr, rom_col; // 3-bit ROM address and ROM Column
    reg [7:0] rom_data; //Data at current ROM address
    wire rom_bit; //Denotes when ROM Data is 1 or 0 for ball RGB control
    
    
    /*----- Register Control -----*/
    always @ (posedge i_clk) begin
        if (i_rst) begin//Synchronous reset behaviour
            y_bar_reg <= 10'd204;
            x_ball_reg <= 0;
            y_ball_reg <= 0;
            x_delta_reg <= 10'd2;
            y_delta_reg <= 10'd2;
        end
        else begin
            y_bar_reg <= y_bar_next;
            x_ball_reg <= x_ball_next;
            y_ball_reg <= y_ball_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
        end
    end
    
    /*----- Ball ROM -----*/
    always @ (*) begin
        case (rom_addr)
            3'o0: rom_data = 8'b00111100; //  **** 
            3'o1: rom_data = 8'b01111110; // ******
            3'o2: rom_data = 8'b11111111; //********
            3'o3: rom_data = 8'b11111111; //********
            3'o4: rom_data = 8'b11111111; //********
            3'o5: rom_data = 8'b11111111; //********
            3'o6: rom_data = 8'b01111110; // ******
            3'o7: rom_data = 8'b00111100; //  ****  
        endcase
    end
     
    
    /*----- Object Status signals -----*/
    wire wall_on, bar_on, sq_ball_on, ball_on;
    wire [11:0] wall_rgb, bar_rgb, ball_rgb, bg_rgb;
    
   
    
    //Assign object colors
    assign wall_rgb = 12'hFFF; //White walls
    assign bar_rgb = 12'hFFF; //White Paddle
    assign ball_rgb = 12'h00F;//Red Ball
    assign bg_rgb = 12'h000;//Black background
    
    //Assign paddle signals 
    assign y_bar_t = y_bar_reg; //Paddle top position
    assign y_bar_b = y_bar_t + BAR_Y_SIZE - 1;//Paddle bottom position
    assign bar_on = ((BAR_L <= i_pixel_x) && (i_pixel_x <= BAR_R) && (y_bar_t <= i_pixel_y) && (i_pixel_y <= y_bar_b));
    
    //Paddle Control
    always @ (*) begin
        /**/
        y_bar_next = y_bar_reg; // No move -- Not sure I understand why this is here yet
        if (refresh_tick) begin
            if (i_btnDWN && (y_bar_b < MAX_Y - BAR_VELOCITY)) y_bar_next = y_bar_reg + BAR_VELOCITY; //Move paddle DOWN
            else if (i_btnUP && (y_bar_t > BAR_VELOCITY)) y_bar_next = y_bar_reg - BAR_VELOCITY; //Move paddle UP
        end  
    end
    
    //ROM data square boundaries
    assign x_ball_l = x_ball_reg;
    assign y_ball_t = y_ball_reg;
    assign x_ball_r = x_ball_l + BALL_SIZE - 1;
    assign y_ball_b = y_ball_t + BALL_SIZE - 1;
    
    //Assert square ball status signals while the pixel is within ROM square boundaries
    assign sq_ball_on = (x_ball_l <= i_pixel_x) && (i_pixel_x <= x_ball_r) && (y_ball_t <= i_pixel_y) && (i_pixel_y <= y_ball_b);
    
    //Map current pixel location to ROM address/column
    assign rom_addr = i_pixel_y[2:0] - y_ball_t[2:0];//3-bit ROM addres
    assign rom_col = i_pixel_x[2:0] - x_ball_l[2:0]; //3-bit Column index
    assign rom_bit = rom_data [rom_col]; // 1-bit signal ROM Data by Column
    
    //Assign wall status signal while the pixel is within the wall
    assign wall_on = (WALL_L <= i_pixel_x) && (i_pixel_x <= WALL_R);
    //Assert ball status signal while the pixel is within the round ball
    assign ball_on = sq_ball_on && rom_bit;
    
    //New ball position
    assign x_ball_next = (refresh_tick) ? x_ball_reg+x_delta_reg : x_ball_reg; //Ball is in center if we display the still graphic
    assign y_ball_next = (refresh_tick) ? y_ball_reg+y_delta_reg : y_ball_reg; // Ball is in center if we display the still graphic
    
    //Change ball direction after collision
    always @ (*) begin
        x_delta_next = x_delta_reg;
        y_delta_next = y_delta_reg;
     
        if (y_ball_t < 1) y_delta_next = BALL_VELOCITY_POS; //If the ball hits the top, send it down
        else if (y_ball_b > MAX_Y) y_delta_next = BALL_VELOCITY_NEG; //If the ball hits the bottom, send it up
        else if (x_ball_l <= WALL_R) x_delta_next = BALL_VELOCITY_POS; //If the ball hits the wall, send it right
        else if ((BAR_L <= x_ball_r) && (x_ball_r <= BAR_R) && (y_bar_t <= y_ball_b) && (y_ball_t <= y_bar_b)) begin
             //If the ball hits the paddle, send it right
             x_delta_next = BALL_VELOCITY_NEG;
        end
    end
    
    
    //RGB multiplexing circuit
    always @ (*) begin
        if (~i_video_on) o_graph_rgb = 12'h000;
        else begin
            if (wall_on) o_graph_rgb = wall_rgb;
            else if (bar_on) o_graph_rgb = bar_rgb;
            else if (ball_on) o_graph_rgb = ball_rgb;
            else o_graph_rgb = bg_rgb;
        end
    end
    
endmodule
