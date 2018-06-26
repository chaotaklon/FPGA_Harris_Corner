`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:58:29 02/20/2014 
// Design Name: 
// Module Name:    cv_top 
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
//(* use_dsp48 = "yes" *) module cv_top(
module cv_top(
    input pclk,
    input [18:0] addr_in,
    input [15:0] data_in,
    input en_in,
	 
    output reg [18:0] addr_out,
    output reg [7:0] data_out,
    output en_out
    );

	 // RGB565 to 8bit grey
	 wire [7:0]R;
	 wire [7:0]G;
	 wire [7:0]B;
	 assign R = {data_in[15:11], data_in[15:13]};
	 assign G = {data_in[10:5], data_in[10:9]};
	 assign B = {data_in[4:0], data_in[4:2]};
	 
	 wire [7:0]grey;
	 assign grey = {1'b0,G[7:1]} + {2'b00, R[7:2]} + {2'b00, B[7:2]};


	 
	 
	 
	 // Harris
	 reg [7:0]rowBuffer1_4[633:0];
	 reg [7:0]rowBuffer1_3[633:0];
	 reg [7:0]rowBuffer1_2[633:0];
	 reg [7:0]rowBuffer1_1[633:0];
	 reg [7:0]rowBuffer1_0[633:0];
	 reg [7:0]window1[5:0][5:0];
	 reg [9:0]rowBuffer_writeAddrHandler1;
	 reg [9:0]rowBuffer_readAddrHandler1;
	 
	 // Harris-address handler
	 always@(posedge pclk) begin
		if(en_in) begin
			if(rowBuffer_writeAddrHandler1 == 10'd633)
				rowBuffer_writeAddrHandler1 <= 10'd0;
			else
				rowBuffer_writeAddrHandler1 <= rowBuffer_writeAddrHandler1 + 1'b1;
				
			if(rowBuffer_writeAddrHandler1 == 10'd0)
				rowBuffer_readAddrHandler1 <= 10'd2;
			else if(rowBuffer_writeAddrHandler1 == 10'd632)
				rowBuffer_readAddrHandler1 <= 10'd0;
			else
				rowBuffer_readAddrHandler1 <= rowBuffer_readAddrHandler1 + 1'b1;
		end
	 end
	 
	 // Harris-window
	 always@(posedge pclk) begin
		if(en_in) begin
			window1[5][5] <= grey;
			window1[5][4] <= window1[5][5];
			window1[5][3] <= window1[5][4];
			window1[5][2] <= window1[5][3];
			window1[5][1] <= window1[5][2];
			window1[5][0] <= window1[5][1];
			
			rowBuffer1_4[rowBuffer_writeAddrHandler1] <= window1[5][0];
			window1[4][5] <= rowBuffer1_4[rowBuffer_readAddrHandler1];
			window1[4][4] <= window1[4][5];
			window1[4][3] <= window1[4][4];
			window1[4][2] <= window1[4][3];
			window1[4][1] <= window1[4][2];
			window1[4][0] <= window1[4][1];
			
			rowBuffer1_3[rowBuffer_writeAddrHandler1] <= window1[4][0];
			window1[3][5] <= rowBuffer1_3[rowBuffer_readAddrHandler1];
			window1[3][4] <= window1[3][5];
			window1[3][3] <= window1[3][4];
			window1[3][2] <= window1[3][3];
			window1[3][1] <= window1[3][2];
			window1[3][0] <= window1[3][1];
			
			rowBuffer1_2[rowBuffer_writeAddrHandler1] <= window1[3][0];
			window1[2][5] <= rowBuffer1_2[rowBuffer_readAddrHandler1];
			window1[2][4] <= window1[2][5];
			window1[2][3] <= window1[2][4];
			window1[2][2] <= window1[2][3];
			window1[2][1] <= window1[2][2];
			window1[2][0] <= window1[2][1];
			
			rowBuffer1_1[rowBuffer_writeAddrHandler1] <= window1[2][0];
			window1[1][5] <= rowBuffer1_1[rowBuffer_readAddrHandler1];
			window1[1][4] <= window1[1][5];
			window1[1][3] <= window1[1][4];
			window1[1][2] <= window1[1][3];
			window1[1][1] <= window1[1][2];
			window1[1][0] <= window1[1][1];
			
			rowBuffer1_0[rowBuffer_writeAddrHandler1] <= window1[1][0];
			window1[0][5] <= rowBuffer1_0[rowBuffer_readAddrHandler1];
			window1[0][4] <= window1[0][5];
			window1[0][3] <= window1[0][4];
			window1[0][2] <= window1[0][3];
			window1[0][1] <= window1[0][2];
			window1[0][0] <= window1[0][1];
		end
	 end
	 
	 // further delay the grey image to sync with feature points
	 reg [7:0]feat_background[10:0];
	 always@(posedge pclk) begin
		if(en_in) begin
			feat_background[10] <= window1[0][0];
			feat_background[9] <= feat_background[10];
			feat_background[8] <= feat_background[9];
			feat_background[7] <= feat_background[8];
			feat_background[6] <= feat_background[7];
			feat_background[5] <= feat_background[6];
			feat_background[4] <= feat_background[5];
			feat_background[3] <= feat_background[4];
			feat_background[2] <= feat_background[3];
			feat_background[1] <= feat_background[2];
			feat_background[0] <= feat_background[1];
		end
	 end
	 
	 // Harris diff
	 reg signed [8:0]dx1[4:0][4:0];
	 reg signed [8:0]dy1[4:0][4:0];
	 genvar i;
	 generate
		for(i=0; i<=4; i=i+1) begin:HRd
			 always@(posedge pclk) begin
				if(en_in) begin
					dx1[0][i] <= $signed({1'b0, window1[1][i+1]}) - $signed({1'b0, window1[1][i]});  // unsigned number add a 0 sign bit and treat it as signed number
					dx1[1][i] <= $signed({1'b0, window1[2][i+1]}) - $signed({1'b0, window1[2][i]});
					dx1[2][i] <= $signed({1'b0, window1[3][i+1]}) - $signed({1'b0, window1[3][i]});
					dx1[3][i] <= $signed({1'b0, window1[4][i+1]}) - $signed({1'b0, window1[4][i]});
					dx1[4][i] <= $signed({1'b0, window1[5][i+1]}) - $signed({1'b0, window1[5][i]});
					
					dy1[i][0] <= $signed({1'b0, window1[i+1][1]}) - $signed({1'b0, window1[i][1]});
					dy1[i][1] <= $signed({1'b0, window1[i+1][2]}) - $signed({1'b0, window1[i][2]});
					dy1[i][2] <= $signed({1'b0, window1[i+1][3]}) - $signed({1'b0, window1[i][3]});
					dy1[i][3] <= $signed({1'b0, window1[i+1][4]}) - $signed({1'b0, window1[i][4]});
					dy1[i][4] <= $signed({1'b0, window1[i+1][5]}) - $signed({1'b0, window1[i][5]});
				end
			 end
		end
	 endgenerate
	 
	 reg signed [17:0]dx2_1[4:0][4:0];
	 reg signed [17:0]dy2_1[4:0][4:0];
	 reg signed [17:0]dxdy_1[4:0][4:0];
	 genvar j;
	 generate
		for(j=0; j<=4; j=j+1) begin: HRsq
			always@(posedge pclk) begin
				if(en_in) begin
					dx2_1[0][j] <= dx1[0][j]*dx1[0][j];
					dx2_1[1][j] <= dx1[1][j]*dx1[1][j];
					dx2_1[2][j] <= dx1[2][j]*dx1[2][j];
					dx2_1[3][j] <= dx1[3][j]*dx1[3][j];
					dx2_1[4][j] <= dx1[4][j]*dx1[4][j];
					
					dy2_1[0][j] <= dy1[0][j]*dy1[0][j];
					dy2_1[1][j] <= dy1[1][j]*dy1[1][j];
					dy2_1[2][j] <= dy1[2][j]*dy1[2][j];
					dy2_1[3][j] <= dy1[3][j]*dy1[3][j];
					dy2_1[4][j] <= dy1[4][j]*dy1[4][j];
					
					dxdy_1[0][j] <= dx1[0][j]*dy1[0][j];
					dxdy_1[1][j] <= dx1[1][j]*dy1[1][j];
					dxdy_1[2][j] <= dx1[2][j]*dy1[2][j];
					dxdy_1[3][j] <= dx1[3][j]*dy1[3][j];
					dxdy_1[4][j] <= dx1[4][j]*dy1[4][j];
				end
			end
		end
	 endgenerate
	 
	 reg signed [22:0]A00_mid1_1[12:0];
	 reg signed [22:0]A11_mid1_1[12:0];
	 reg signed [22:0]A01_mid1_1[12:0];
	 
	 reg signed [22:0]A00_mid2_1[6:0];
	 reg signed [22:0]A11_mid2_1[6:0];
	 reg signed [22:0]A01_mid2_1[6:0];
	 
	 reg signed [22:0]A00_mid3_1[3:0];
	 reg signed [22:0]A11_mid3_1[3:0];
	 reg signed [22:0]A01_mid3_1[3:0];
	 
	 reg signed [22:0]A00_mid4_1[1:0];
	 reg signed [22:0]A11_mid4_1[1:0];
	 reg signed [22:0]A01_mid4_1[1:0];
	 
	 reg signed [22:0]A00_1;
	 reg signed [22:0]A11_1;
	 reg signed [22:0]A01_1;
	 
	 always@(posedge pclk) begin
		if(en_in) begin
			// s1
			A00_mid1_1[0] <= dx2_1[0][0] + dx2_1[0][1];
			A00_mid1_1[1] <= dx2_1[0][2] + dx2_1[0][3];
			A00_mid1_1[2] <= dx2_1[0][4] + dx2_1[1][0];
			A00_mid1_1[3] <= dx2_1[1][1] + dx2_1[1][2];
			A00_mid1_1[4] <= dx2_1[1][3] + dx2_1[1][4];
			A00_mid1_1[5] <= dx2_1[2][0] + dx2_1[2][1];
			A00_mid1_1[6] <= dx2_1[2][2] + dx2_1[2][3];
			A00_mid1_1[7] <= dx2_1[2][4] + dx2_1[3][0];
			A00_mid1_1[8] <= dx2_1[3][1] + dx2_1[3][2];
			A00_mid1_1[9] <= dx2_1[3][3] + dx2_1[3][4];
			A00_mid1_1[10] <= dx2_1[4][0] + dx2_1[4][1];
			A00_mid1_1[11] <= dx2_1[4][2] + dx2_1[4][3];
			A00_mid1_1[12] <= dx2_1[4][4];
			
			A11_mid1_1[0] <= dy2_1[0][0] + dy2_1[0][1];
			A11_mid1_1[1] <= dy2_1[0][2] + dy2_1[0][3];
			A11_mid1_1[2] <= dy2_1[0][4] + dy2_1[1][0];
			A11_mid1_1[3] <= dy2_1[1][1] + dy2_1[1][2];
			A11_mid1_1[4] <= dy2_1[1][3] + dy2_1[1][4];
			A11_mid1_1[5] <= dy2_1[2][0] + dy2_1[2][1];
			A11_mid1_1[6] <= dy2_1[2][2] + dy2_1[2][3];
			A11_mid1_1[7] <= dy2_1[2][4] + dy2_1[3][0];
			A11_mid1_1[8] <= dy2_1[3][1] + dy2_1[3][2];
			A11_mid1_1[9] <= dy2_1[3][3] + dy2_1[3][4];
			A11_mid1_1[10] <= dy2_1[4][0] + dy2_1[4][1];
			A11_mid1_1[11] <= dy2_1[4][2] + dy2_1[4][3];
			A11_mid1_1[12] <= dy2_1[4][4];
			
			A01_mid1_1[0] <= dxdy_1[0][0] + dxdy_1[0][1];
			A01_mid1_1[1] <= dxdy_1[0][2] + dxdy_1[0][3];
			A01_mid1_1[2] <= dxdy_1[0][4] + dxdy_1[1][0];
			A01_mid1_1[3] <= dxdy_1[1][1] + dxdy_1[1][2];
			A01_mid1_1[4] <= dxdy_1[1][3] + dxdy_1[1][4];
			A01_mid1_1[5] <= dxdy_1[2][0] + dxdy_1[2][1];
			A01_mid1_1[6] <= dxdy_1[2][2] + dxdy_1[2][3];
			A01_mid1_1[7] <= dxdy_1[2][4] + dxdy_1[3][0];
			A01_mid1_1[8] <= dxdy_1[3][1] + dxdy_1[3][2];
			A01_mid1_1[9] <= dxdy_1[3][3] + dxdy_1[3][4];
			A01_mid1_1[10] <= dxdy_1[4][0] + dxdy_1[4][1];
			A01_mid1_1[11] <= dxdy_1[4][2] + dxdy_1[4][3];
			A01_mid1_1[12] <= dxdy_1[4][4];
			
			// s2
			A00_mid2_1[0] <= A00_mid1_1[0] + A00_mid1_1[1];
			A00_mid2_1[1] <= A00_mid1_1[2] + A00_mid1_1[3];
			A00_mid2_1[2] <= A00_mid1_1[4] + A00_mid1_1[5];
			A00_mid2_1[3] <= A00_mid1_1[6] + A00_mid1_1[7];
			A00_mid2_1[4] <= A00_mid1_1[8] + A00_mid1_1[9];
			A00_mid2_1[5] <= A00_mid1_1[10] + A00_mid1_1[11];
			A00_mid2_1[6] <= A00_mid1_1[12];
			
			A11_mid2_1[0] <= A11_mid1_1[0] + A11_mid1_1[1];
			A11_mid2_1[1] <= A11_mid1_1[2] + A11_mid1_1[3];
			A11_mid2_1[2] <= A11_mid1_1[4] + A11_mid1_1[5];
			A11_mid2_1[3] <= A11_mid1_1[6] + A11_mid1_1[7];
			A11_mid2_1[4] <= A11_mid1_1[8] + A11_mid1_1[9];
			A11_mid2_1[5] <= A11_mid1_1[10] + A11_mid1_1[11];
			A11_mid2_1[6] <= A11_mid1_1[12];
			
			A01_mid2_1[0] <= A01_mid1_1[0] + A01_mid1_1[1];
			A01_mid2_1[1] <= A01_mid1_1[2] + A01_mid1_1[3];
			A01_mid2_1[2] <= A01_mid1_1[4] + A01_mid1_1[5];
			A01_mid2_1[3] <= A01_mid1_1[6] + A01_mid1_1[7];
			A01_mid2_1[4] <= A01_mid1_1[8] + A01_mid1_1[9];
			A01_mid2_1[5] <= A01_mid1_1[10] + A01_mid1_1[11];
			A01_mid2_1[6] <= A01_mid1_1[12];
			
			// s3
			A00_mid3_1[0] <= A00_mid2_1[0] + A00_mid2_1[1];
			A00_mid3_1[1] <= A00_mid2_1[2] + A00_mid2_1[3];
			A00_mid3_1[2] <= A00_mid2_1[4] + A00_mid2_1[5];
			A00_mid3_1[3] <= A00_mid2_1[6];
			
			A11_mid3_1[0] <= A11_mid2_1[0] + A11_mid2_1[1];
			A11_mid3_1[1] <= A11_mid2_1[2] + A11_mid2_1[3];
			A11_mid3_1[2] <= A11_mid2_1[4] + A11_mid2_1[5];
			A11_mid3_1[3] <= A11_mid2_1[6];
			
			A01_mid3_1[0] <= A01_mid2_1[0] + A01_mid2_1[1];
			A01_mid3_1[1] <= A01_mid2_1[2] + A01_mid2_1[3];
			A01_mid3_1[2] <= A01_mid2_1[4] + A01_mid2_1[5];
			A01_mid3_1[3] <= A01_mid2_1[6];
			
			// s4
			A00_mid4_1[0] <= A00_mid3_1[0] + A00_mid3_1[1];
			A00_mid4_1[1] <= A00_mid3_1[2] + A00_mid3_1[3];
			
			A11_mid4_1[0] <= A11_mid3_1[0] + A11_mid3_1[1];
			A11_mid4_1[1] <= A11_mid3_1[2] + A11_mid3_1[3];
			
			A01_mid4_1[0] <= A01_mid3_1[0] + A01_mid3_1[1];
			A01_mid4_1[1] <= A01_mid3_1[2] + A01_mid3_1[3];
			
			// s5
			A00_1 <= A00_mid4_1[0] + A00_mid4_1[1];
			A11_1 <= A11_mid4_1[0] + A11_mid4_1[1];
			A01_1 <= A01_mid4_1[0] + A01_mid4_1[1];
		end
	 end

	 reg signed [45:0]A00mulA11_1;
	 reg signed [45:0]A01mulA10_1;
	 reg signed [23:0]A00plusA11_1;
	 always@(posedge pclk) begin
		if(en_in) begin
			A00mulA11_1 <= A00_1 * A11_1;
			A01mulA10_1 <= A01_1 * A01_1; // A01 and A10 are the same
			A00plusA11_1 <= A00_1 + A11_1;
		end
	 end
	 
	 // Adaptive Harris Threshold
	 reg [13:0]feature_counter;
	 always@(posedge pclk) begin
		if(en_in) begin
			if(addr_in == 19'd3215)
				feature_counter <= 14'd0;
			else if (is_feat && (~|featWindow1))
				feature_counter <= feature_counter + 1'b1;
		end
	 end
	 
	 reg signed [47:0]Harris_threshold;
	 always@(posedge pclk) begin
		if(en_in & (addr_in == 19'd3215)) begin	
			if(Harris_threshold < $signed(48'h40000000) & feature_counter > 14'd40)  // 40 point  
				Harris_threshold <= (Harris_threshold <<< 1); // signed shift to *2
			else if (Harris_threshold > $signed(48'h800000) & feature_counter < 14'd24)  // 24 point  // 12-20, 24-40
				Harris_threshold <= (Harris_threshold >>> 1);  // divided by 2
			else if (Harris_threshold == $signed(48'h0))
				Harris_threshold <= $signed(48'h10000000); // initialize  // 48'h2000000
		end
	 end

	//wire signed [47:0]Harris_threshold;
	//assign Harris_threshold = $signed(48'h10000000);
	
	 // end of adp threshold
	 
	 reg signed [46:0]A00mulA11_sub_A01mulA10_1;
	 reg signed [19:0]A00plusA11_div25_1;
	 reg signed [47:0]Harris_R;
	 reg is_feat;
	 wire signed [26:0]A00plusA11_1_mul5;
	 assign A00plusA11_1_mul5 = A00plusA11_1 * $signed(3'd5);
	 always@(posedge pclk) begin
		if(en_in) begin
			A00mulA11_sub_A01mulA10_1 <= A00mulA11_1 - A01mulA10_1;
			//A00plusA11_div25_1 <= A00plusA11_1 / $signed(5'd25);
			A00plusA11_div25_1 <= A00plusA11_1_mul5[26:7];  // 5/128 = 0.39
			
			Harris_R <= A00mulA11_sub_A01mulA10_1 - A00plusA11_div25_1;  // det(A) - 0.04*trace(A)
			
			is_feat <= (Harris_R >= Harris_threshold) ? 1'b1 : 1'b0;  // Harris Threshold  48'h40000000  48'h2000000  48'h800000
		end
	 end
	 
	 // delete features that are too close
	 reg featBuffer1_5[633:0];
	 reg featBuffer1_4[633:0];
	 reg featBuffer1_3[633:0];
	 reg featBuffer1_2[633:0];
	 reg featBuffer1_1[633:0];
	 reg featBuffer1_0[633:0];
	 reg [34:0]featWindow1;
	 reg [7:0]dis_data;
	 always@(posedge pclk) begin
		if(en_in) begin
			featWindow1[34] <= is_feat;
			featWindow1[33] <= featWindow1[34];
			
			featBuffer1_4[rowBuffer_writeAddrHandler1] <= featWindow1[33];
			featWindow1[32] <= featBuffer1_4[rowBuffer_readAddrHandler1];
			featWindow1[31] <= featWindow1[32];
			featWindow1[30] <= featWindow1[31];
			featWindow1[29] <= featWindow1[30];
			featWindow1[28] <= featWindow1[29];
			featWindow1[27] <= featWindow1[28];
			
			featBuffer1_3[rowBuffer_writeAddrHandler1] <= featWindow1[27];
			featWindow1[26] <= featBuffer1_3[rowBuffer_readAddrHandler1];
			featWindow1[25] <= featWindow1[26];
			featWindow1[24] <= featWindow1[25];
			featWindow1[23] <= featWindow1[24];
			featWindow1[22] <= featWindow1[23];
			featWindow1[21] <= featWindow1[22];
			
			featBuffer1_2[rowBuffer_writeAddrHandler1] <= featWindow1[21];
			featWindow1[20] <= featBuffer1_2[rowBuffer_readAddrHandler1];
			featWindow1[19] <= featWindow1[20];
			featWindow1[18] <= featWindow1[19];
			featWindow1[17] <= featWindow1[18];
			featWindow1[16] <= featWindow1[17];
			featWindow1[15] <= featWindow1[16];
			
			featBuffer1_1[rowBuffer_writeAddrHandler1] <= featWindow1[15];
			featWindow1[14] <= featBuffer1_1[rowBuffer_readAddrHandler1];
			featWindow1[13] <= featWindow1[14];
			featWindow1[12] <= featWindow1[13];
			featWindow1[11] <= featWindow1[12];
			featWindow1[10] <= featWindow1[11];
			featWindow1[9] <= featWindow1[10];
			
			featBuffer1_0[rowBuffer_writeAddrHandler1] <= featWindow1[9];
			featWindow1[8] <= featBuffer1_0[rowBuffer_readAddrHandler1];
			featWindow1[7] <= featWindow1[8];
			featWindow1[6] <= featWindow1[7];
			featWindow1[5] <= featWindow1[6];
			featWindow1[4] <= featWindow1[5];
			featWindow1[3] <= featWindow1[4];
			
			featBuffer1_5[rowBuffer_writeAddrHandler1] <= featWindow1[3];
			featWindow1[2] <= featBuffer1_5[rowBuffer_readAddrHandler1];
			featWindow1[1] <= featWindow1[2];
			featWindow1[0] <= featWindow1[1];
			
			dis_data <= (is_feat && (~|featWindow1)) ? 8'd255 : feat_background[0]; // window[0][0] + 11 state = is feat state
		end
	 end
	 
	 
	 
	 
	 // address delay
	 always@(posedge pclk) begin
		if(en_in) begin
			if(addr_in >= 19'd3218) // 3218  // 4507
				addr_out <= addr_in - 19'd3218; // 3218  // 4507
			else
				addr_out <= 19'd303982 + addr_in; // 303982  // 302693
			
			data_out <= dis_data;
		end
	 end
	 
	 assign en_out = en_in;

endmodule

