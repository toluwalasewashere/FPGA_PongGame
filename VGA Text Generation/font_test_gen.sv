`timescale 1ns / 1ps
/* This is a simple font display circuit used to verify operation of the font ROM and display all font patterns on the screen. 
 * 
*/


module font_test_gen(
    input wire i_clk,
    input wire i_video_on,
    input logic [9:0] i_pixel_x, i_pixel_y,
    output wire o_text_bit_on, //status signal for ROM bit 
    output wire [7:0] o_rom_data,
    output wire [2:0] o_bit_addr,
    output wire o_font_bit,
    output wire [7:0] o_ascii_char, 
    output logic [11:0] o_RGB
    );
    
    //Signal declaration
    wire [10:0] rom_addr; //11-bit font ROM address
    wire [6:0] ascii_char; //7-bit ASCII character code
    wire [3:0] char_row; //4-bit row of ASCII character
    wire [2:0] bit_addr; //Column number of ROM data
    wire [7:0] rom_data; // 8-bit row data from font ROM
    wire font_bit,text_bit_on; //ROM bit -- font_bit is one pixel of font_data specified by bit_addr
    
    //Font ROM instantiation
    font_rom font_unit (.i_clk(i_clk), .i_addr(rom_addr), .o_data(rom_data));
    
    //Font ROM interface
    assign rom_addr = {ascii_char, char_row};
    assign font_bit = rom_data[~bit_addr]; //Reverse bit order -- Why? 
    
    assign ascii_char = {i_pixel_y[5:4], i_pixel_x[7:3]};
    /* i_pixel_x[7:3 forms the 5 LSBs of the ASCII code, thus 32 consecutive font patterns will be displayed in a row. 
     * i_pixel_y [5:4] forms the 2 MSBs of the ASCII code, thus 4 rows of patterns will be displayed.
     * The upper bits of the i_pixel_x and i_pixel_y are left unspecified so the 32 by 4 region will be displayed repetitively
    */
    assign char_row = i_pixel_y[3:0]; //Row number of the ASCII character in the font ROM
    assign bit_addr = i_pixel_x[2:0]; //Column number of the ASCII character in the font ROM
    
    assign text_bit_on = ((i_pixel_x >= 192 && i_pixel_x < 448) && (i_pixel_y >= 208 && i_pixel_y < 272))? font_bit : 1'b0 ; //"ON" region is in the center of display
    
    always @ (*) begin
        if (~i_video_on) o_RGB = 12'h000; //Black screen where video isn't on
        else begin
            if (text_bit_on) o_RGB = 12'h00F; //Make the text RED
            else o_RGB = 12'hFFF; //Background is White
        end
    end
    
    assign o_text_bit_on = text_bit_on;
    assign o_rom_data = rom_data;
    assign o_bit_addr = bit_addr;
    assign o_font_bit = font_bit;
    assign o_ascii_char = ascii_char;
endmodule
