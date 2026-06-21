`timescale 1ns / 1ps


module PongGame_top(
    input wire i_sys_clk,
    input wire i_sys_rst,
    input wire BTNU,
    input wire BTND,
    output logic o_VGA_HS,
    output logic o_VGA_VS,
    output logic [3:0] o_VGA_R,
    output logic [3:0] o_VGA_G,
    output logic [3:0] o_VGA_B
    );
    
    logic clk, rst;
    logic locked;
    logic [9:0] x, y;
    logic video_on;
    wire pixel_tick;
    logic [11:0] RGB_reg, rgb_next;
    logic UP,DOWN;
    
    //Clocking Wizard IP Instantiation
    clk_wiz_0 clk_gen(
        .clk_in1(i_sys_clk),
        .reset(i_sys_rst),
        .locked (locked),
        .clk_out1(clk)
    );
    
    //Processor System Reset instantiation
    proc_sys_reset_0 test_rst_gen(
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
    
    //Button Debouncer instantation
    debouncer db_BTNU (
        .i_clk(clk),
        .i_rst(rst),
        .i_btn_in(BTNU),
        .o_btn_out (UP)
    );
    
    debouncer db_BTND (
        .i_clk(clk),
        .i_rst(rst),
        .i_btn_in(BTND),
        .o_btn_out (DOWN)
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
    
    //Graphics Circuit instantiation
    PongGame_Graphics graphics_gen (
        .i_clk(clk),
        .i_rst(rst),
        .i_btnUP(UP),
        .i_btnDWN(DOWN),
        .i_video_on(video_on),
        .i_pixel_x(x),
        .i_pixel_y(y),
        .o_graph_rgb(rgb_next)
    );
    
    
    //RGB Buffer
    always @ (posedge clk) begin
         if (pixel_tick)  RGB_reg <= rgb_next;
    end
    assign o_VGA_R = RGB_reg[3:0];
    assign o_VGA_G = RGB_reg[7:4];
    assign o_VGA_B = RGB_reg[11:8];
    
endmodule
