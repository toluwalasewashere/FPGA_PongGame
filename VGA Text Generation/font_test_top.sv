`timescale 1ns / 1ps

module font_test_top(
    input wire i_sys_clk,
    input wire i_sys_rst,
    output wire o_VGA_HS,
    output wire o_VGA_VS,
    output wire [3:0] o_VGA_R,
    output wire [3:0] o_VGA_G,
    output wire [3:0] o_VGA_B
    );
    
    logic clk, rst;
    logic locked;
     
    logic [9:0] x, y;
    logic video_on;
    logic pixel_tick;
    logic text_bit_on, font_bit;
    logic [2:0] bit_addr;
    logic [7:0] rom_data, char;
    reg [11:0] RGB_reg, RGB_next;
    
    //Clocking Wizard IP instantiation
    clk_wiz_0 clk_gen(
        .clk_in1(i_sys_clk),
        .reset(i_sys_rst),
        .locked (locked),
        .clk_out1(clk)
    );
    
    //Processor System Reset IP instantiation
     proc_sys_reset_0 rst_gen(
      .slowest_sync_clk(clk),
      .ext_reset_in(i_sys_rst),
      .aux_reset_in('0),
      .mb_debug_sys_rst('0),
      .dcm_locked(locked),    
      .mb_reset(),
      .bus_struct_reset(),
      .peripheral_reset(rst),
      .interconnect_aresetn(), 
      .peripheral_aresetn() 
    );
    
     //VGA Driver instantiation
    VGA_Driver vga_control(
        .i_clk(clk),
        .i_rst(rst),
        .o_video_on(video_on),
        .o_hsync(o_VGA_HS),
        .o_vsync(o_VGA_VS),
        .o_p_tick(pixel_tick),
        .o_counter_x(x),
        .o_counter_y(y)
    );
    
    //Font Generation Circuit instantation
    font_test_gen font_gen_unit (
        .i_clk(clk),
        .i_video_on(video_on),
        .i_pixel_x(x),
        .i_pixel_y(y),
        .o_text_bit_on(text_bit_on),
        .o_rom_data(rom_data),
        .o_bit_addr(bit_addr),
        .o_font_bit(font_bit),
        .o_ascii_char(char),
        .o_RGB(RGB_next)
    );
    
    //Ingegrated Logic Analyzer (ILA) instantiation
    ila_0 ila_inst (
	   .clk(clk), // input wire clk


	   .probe0(x), // input wire [9:0]  probe0  
	   .probe1(y), // input wire [9:0]  probe1 
	   .probe2(text_bit_on), // input wire [0:0]  probe2
	   .probe3(rom_data),
	   .probe4(bit_addr),
	   .probe5(font_bit),
	   .probe6(char)
    );
    always @ (posedge clk) begin
        if (pixel_tick) RGB_reg <= RGB_next;
    end
    
    //Output signals
    assign o_VGA_R = RGB_reg[3:0];
    assign o_VGA_G = RGB_reg[7:4];
    assign o_VGA_B = RGB_reg[11:8];
endmodule
