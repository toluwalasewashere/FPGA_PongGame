`timescale 1ns / 1ps
/* Button debouncer circuit for button input used in v1.0 of the Pong Game project
 * Counter based design:
 * Button input -> Synchronizer -> Counter logic -> Debounced Output
 *
 * Reference(s):
 * "Verilog Debounce Circuit."ChipVerify. Accessed: 22 Jun. 2026. [Online] Available: https://chipverify.com/verilog/verilog-debounce-circuit
*/


module btn_debouncer #(
    parameter CLK_FREQ = 100_000_000, //Input Clock frequency in Hz
    parameter DEBOUNCE_TIME = 20 //Debounce time in ms
    )(
    input wire i_clk, //Clock signal input
    input wire i_rst, //System Reset -- Active high
    input wire i_btn_in, //Input button press (before debouncing)
    output logic o_btn_out //Debounced button press
    );
    
    //Calculation of counter value from clock frequency and debounce time
    localparam COUNTER_MAX = (CLK_FREQ/1000) * DEBOUNCE_TIME; //mHz * ms 
    localparam COUNTER_WIDTH = $clog2(COUNTER_MAX+1); //Not sure why we add 1 to counter max here :(
    
    //Internal Registers
    reg [COUNTER_WIDTH-1:0] counter;
    reg btn_sync0, btn_sync1; //Registers for the Synchronizers
    
    //Double Flip-Flop Synchronizer -- Prevents metastability
    always @ (posedge i_clk or posedge i_rst) begin
        if (i_rst) begin //Asynchronous reset behaviour
            btn_sync0 <= 1'b0;
            btn_sync1 <= 1'b0;
        end
        else begin
            btn_sync0 <= i_btn_in;
            btn_sync1 <= btn_sync0;
        end
    end
    
    /* Debounce logic:
     * The counter is used to monitor if the synchronized input differs from the current output.
     * It does this by counting the number of clock cycles while the input stays stable, resetting if the input
     * changes before the threshhold (COUNTER_MAX). 
     * The stable debounced signal is stored in the output register and only updated after the counter reaches the
     * threshhold(COUNTER_MAX) - which is also after the debounce period has ended. 
    */
    
    always @ (posedge i_clk or posedge i_rst) begin
        if (i_rst) begin //Asynchronous reset behaviour
            counter <= 0; 
            o_btn_out <= 1'b0;
        end
        else begin
            if (btn_sync1 != o_btn_out) begin
                //Input differs from output -> start or continue counting
                counter <= counter + 1'd1;
                if (counter >= COUNTER_MAX) begin
                    o_btn_out <= btn_sync1;
                    counter <= 0;
                end
            end
            else counter <= 0; //Input matches output -> reset counter
        end
    end
    
endmodule
