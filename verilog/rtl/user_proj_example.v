// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire reset;


    // IO
    assign clk = wb_clk_i;
    assign reset = wb_rst_i;
    assign io_out[37:26] = {direction,complete,door_alert,weight_alert,out_current_floor};
    assign io_oeb = 0;
    assign {request_floor,in_current_floor,over_time,over_weight} = io_in[37:20]; 

    // IRQ
    assign irq = 3'b000;	// Unused

    wire [7:0]request_floor;
    wire [7:0]in_current_floor;
    wire complete;
    wire direction;
    wire over_time;
    wire over_weight;
    wire weight_alert;
    wire door_alert;
    wire [7:0]request_floor;
    
    iiitb_elc dut (.clk(clk), .reset(reset), .request_floor(request_floor), .in_current_floor(in_current_floor), .complete(complete), .direction(direction), .over_time(over_time), 
                   .over_weight(over_weight), .weight_alert(weight_alert), .door_alert(door_alert), .request_floor(request_floor));   
    
    

endmodule

module iiitb_elc (request_floor, in_current_floor, clk, reset, complete, direction,
over_time, over_weight, weight_alert, door_alert, out_current_floor) ;

//input pins
input [7:0]request_floor; // the 8 bit input request floor
input [7:0]in_current_floor; // the 8 bit input floor,
input clk; //-ve generate = low Frequency clock
input reset; // the 1 bit input reset
input over_time; //the 1 bit input which indicates the door keep open for 3 ninutes
input over_weight; // the 1 bit input which indicates the weight in the elevator is larger than 900kgs


//output pins
output direction; // the 1 bit output which indicates the direction of the elevator
output complete;// the 1 bit output vhich indicates whether elevalor is running or stopped
output door_alert;// the 1 bit output vhich indicates the door keep open for 3 nimutes
output weight_alert;// the 1 bit output which nficates the weight in the elevator is larger than 900kgs
output [7:0] out_current_floor; // the 8 bit output which shows the current floor

//register parameters
reg r_direction;// 1 bit register connected to the output direction
reg r_complete;// 1 bit register connected to the output complete
reg r_door_alert;// 1 bit register connected to the output door_slert
reg r_weight_alert; // 1 bit register connected to the output veigh alert
reg [7:0] r_out_current_floor;// 8 bit register connected to the output out_current_floor;

/*
//Clock generator register
reg [12:0] clk_count;
// reg clk_200;
reg clk_trigger;
*/


//initialization
/*
always@(negedge reset)
begin
clk_200=1'b0;
clk_count=0;
clk_trigger=1'b0;

//reset clock registers
r_direction=1'b0;
r_complete=1'b0; // set the default value to 0
r_door_alert=1'b0;//set the default value to 0
r_weight_alert=1'b0; //set the default value to 0
r_out_current_floor <= in_current_floor;
end
*/
/*
//clock generator block
always@(posedge clk)
begin
if(clk_trigger)
clk_count=clk_count+1;
if(clk_count==5000)
begin
clk_200=~clk_200;
clk_count=0;
end
end
*/

//if request floor occurs
/*
always@(request_floor)
begin
//clk_trigger=1'b1;
//clk_200=~clk_200;
r_out_current_floor <= in_current_floor;
end
*/
//normal running case of elevator



always@(posedge clk)
begin
r_complete= 0;
r_direction = 1;
r_weight_alert = 0;
r_door_alert = 0;
if(reset)
r_out_current_floor <= in_current_floor;

else if(!reset && !over_time && !over_weight)
begin
//Case 1: normal movement of elevator
if (request_floor > r_out_current_floor) begin
r_direction <= 1'b1;
r_out_current_floor <= r_out_current_floor << 1;
end

else if (request_floor < r_out_current_floor) begin
r_direction <= 1'b0;
r_out_current_floor = r_out_current_floor >> 1;
end

else if (request_floor == r_out_current_floor) begin
r_complete <= 1;
r_direction <= 0;
end
end

 //Case 2: the door is kept open for more than 3 minutes
else if (!reset && over_time)
begin
r_door_alert <= 1;
r_complete <= 0;
r_weight_alert <= 0;
r_direction <= 0;
r_out_current_floor <= r_out_current_floor;
end

//Case 3: the total weight in the elevator is more than 900kgs
else if(!reset && over_weight)begin
r_door_alert <= 0;
r_weight_alert <= 1;
r_complete <= 0;
r_direction <= 0;
r_out_current_floor <= r_out_current_floor;
end
end

//match pins and registers
assign direction=r_direction;
assign complete=r_complete;
assign door_alert=r_door_alert;
assign weight_alert=r_weight_alert;
assign out_current_floor= r_out_current_floor;
endmodule
`default_nettype wire
