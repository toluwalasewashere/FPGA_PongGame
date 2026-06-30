`timescale 1ns / 1ps
/*
 * References:
 * Github Repository: FPGADude/Digital-Design
 * Chu, Pong P. Wiley, 2008. "FPGA Prototyping by Verilog Examples: Xilinx Spartan-3 Version." Ch. 14 VGA Controller II: Text.
*/

module PongGame_text(
    input wire i_clk,
    input wire i_rst,
    input logic [1:0] i_ball_count, //Number of balls player has left
    input logic [3:0] i_dig0, i_dig1, //BCD inputs for display
    input logic [9:0] i_pixel_x, i_pixel_y, //Pixel counts for X and Y
    output logic [3:0] o_text_on, //Status signal 
    output reg [3:0] o_text_RGB //Red, Green, and Blue color intensities of the text
    );
    
    //Signal Declaration
    wire [10:0] rom_addr; //Address in font ROM
    reg [6:0] char, char_s, char_l, char_addr_o; // 7-bit registers for ASCII-character/pattern ROM address components (S - score, L - Logo, O - Game Over)
    reg [3:0] row, row_s, row_l, row_o; //4-bit registers for row ROM address components (S - score, L - Logo, O - Game Over)
    reg [2:0] bit_addr, bit_addr_s, bit_addr_l, bit_addr_o; //
    wire [7:0] ascii_word;
    wire ascii_bit, score_on, logo_on, over_on; //Status signals 
    
    //Font ROM Instantiation
    font_rom font_unit (.i_clk(clk), .i_addr(rom_addr), .o_data(ascii_word));
    
    /*----- SCORE REGION -----*/
    /* Display two digit score and number of balls on top left
     * Scale to 16-by-32 text size
     * Line 1, 16 characters: "Score: DD Ball: D"
    */
    assign score_on = ( i_pixel_y >= 32) && ( i_pixel_y < 64) && (i_pixel_x[9:4] < 16);
    assign row_s = i_pixel_y[4:1];
    assign bit_addr_s = i_pixel_x[3:1];
    always @ (*) begin
        case (i_pixel_x[7:4])
            4'h0 : char_s = 7'h53;     // S
            4'h1 : char_s = 7'h43;     // C
            4'h2 : char_s = 7'h4F;     // O
            4'h3 : char_s = 7'h52;     // R
            4'h4 : char_s = 7'h45;     // E
            4'h5 : char_s = 7'h3A;     // :
            4'h6 : char_s = {3'b011, i_dig1};    // tens digit
            4'h7 : char_s = {3'b011, i_dig0};    // ones digit
            4'h8 : char_s = 7'h00;     //
            4'h9 : char_s = 7'h00;     //
            4'hA : char_s = 7'h42;     // B
            4'hB : char_s = 7'h41;     // A
            4'hC : char_s = 7'h4c;     // L
            4'hD : char_s = 7'h4c;     // L
            4'hE : char_s = 7'h3A;     // :
            4'hF : char_s = {5'b01100, i_ball_count};
        endcase
    end
    
    /*----- LOGO REGION -----*/
    /* Display logo "PONG" at bottom center
     * In reference design, the logo is scaled to 64-by-128. However, I don't like this design.
     * I'm choosing to scale mine to 16-by-32 
    */
    assign logo_on = (i_pixel_y >= 457 && i_pixel_y < 480) && (i_pixel_x >= 256 && i_pixel_x < 384);
    assign row_l = i_pixel_y[4:1];
    assign bit_addr_l = i_pixel_x[3:1];
    always @ (*) begin
        /*case (i_pixel_x[7:4])
            4'h0:
        endcase*/
    end
    
    /*----- GAME OVER REGION -----*/
endmodule
