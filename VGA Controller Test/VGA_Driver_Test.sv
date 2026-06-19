`timescale 1ns / 1ps
/* This module serves as a testbench "of sorts" for the VGA Driver module 
 * Resources:
 * Chu, Pong P. Wiley, 2008. "FPGA Prototyping by Verilog Examples: Xilinx Spartan-3 Version." Ch. 13 VGA Controller I: Graphic.
 * Github Repo: FPGADude/Digital-Design
*/

module VGA_Driver_Test(
    input logic i_sys_clk,
    input logic i_sys_rst,
    input logic [11:0] SW, //12-bit switch input for display color
    output logic o_VGA_HS,
    output logic o_VGA_VS,
    output logic [3:0] o_VGA_R,
    output logic [3:0] o_VGA_G,
    output logic [3:0] o_VGA_B
    );
    
    logic clk, rst;
    logic locked;
    
    logic video_on;
    reg [11:0] RGB_reg;
    
    //Clocking Wizard IP Instantiation
    clk_wiz_0 clk_gen(
        .clk_in1(i_sys_clk),
        .reset(i_sys_rst),
        .locked (locked),
        .clk_out1(clk)
    );
    
    //Processor System Reset instantiation
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
        .o_p_tick(),
        .o_counter_x(),
        .o_counter_y()
    );
    
    //ILA instantiation
    ila_0 ila_ist (
	.clk(clk), // input wire clk


	.probe0(rst), // input wire rst  
	.probe1(video_on), // input wire video_on 
	.probe2(o_VGA_HS), // input wire o_VGA_HS 
	.probe3(o_VGA_VS) // input wire o_VGA_VS
);
    
    //RGB Buffer
    always @ (posedge clk) begin
        if (rst) RGB_reg <= 0;
        else RGB_reg <= SW;
    end
    
    assign o_VGA_R = (video_on) ? RGB_reg[3:0]: 4'b0; //While in display area red color. Otherwise, red OFF.
    assign o_VGA_G = (video_on) ? RGB_reg[7:4]: 4'b0; //While in display area green color. Otherwise, green OFF.
    assign o_VGA_B = (video_on) ? RGB_reg[11:8]: 4'b0; //While in display area blue color. Otherwise, blue OFF.
    
endmodule
