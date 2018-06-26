`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:11:03 02/19/2014 
// Design Name: 
// Module Name:    frame_buffer 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module frame_buffer(
    input [7:0] data,
    input [18:0] rdaddress,
    input rdclock,
    input [18:0] wraddress,
    input wrclock,
    input wren,
    output reg [7:0] q
    );
	 
	 reg [7:0]ram[307199:0];
	 
	 always@(posedge wrclock) begin
		if(wren)
			ram[wraddress] <= data;
	 end

	 always@(posedge rdclock) begin
		q <= ram[rdaddress];
	 end

endmodule
