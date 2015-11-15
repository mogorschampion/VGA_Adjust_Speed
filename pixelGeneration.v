`timescale 1ns / 1ps

module pixelGeneration(clk, rst, push, switch, pixel_x, pixel_y, video_on, rgb);

input clk, rst;
input [1:0] push;
input [2:0] switch;
input [9:0] pixel_x, pixel_y;
input video_on;
output reg [2:0] rgb;

wire square_on, refr_tick;

//define screen size max values.
localparam MAX_X = 640;
localparam MAX_Y = 480;
//define square size and square velocity
localparam SQUARE_SIZE = 40;
//localparam SQUARE_VEL_P = 55;
//localparam SQUARE_VEL_N = -55;

//registers for direction info
reg [9:0]vel_next, vel_reg;
reg direction_next, direction_reg;
// detect posedge of button
reg push_reg0, push_reg1;

//boundaries of the square
wire [9:0] square_x_left, square_x_right;//, square_y_top, square_y_bottom;
//reg [9:0] square_y_reg, square_y_next;
reg [9:0] square_x_reg, square_x_next;

//registers
always @(posedge clk) begin
	if(rst) begin
//		square_y_reg <= 240;
		square_x_reg <= 320;
		vel_reg <= 1;
		direction_reg <= 0;
	end
	else begin
//		square_y_reg <= #1 square_y_next;
		square_x_reg <= #1 square_x_next;
		vel_reg <= #1 vel_next;
		direction_reg <= #1 direction_next;
		push_reg0 <= #1 push[0];
		push_reg1 <= #1 push[1];
	end
end
//check screen refresh
assign refr_tick = (pixel_y ==481) && (pixel_x ==0);

//boundary circuit: assign stored values of y_top and x_left and calculate the y_bottom and x_right values by adding square size.
//assign square_y_top = square_y_reg;
assign square_x_left = square_x_reg;
//assign square_y_bottom = square_y_top + SQUARE_SIZE - 1;
assign square_x_right = square_x_left + SQUARE_SIZE - 1;
assign posPush0 = ~push_reg0 && push[0];
assign posPush1 = ~push_reg1 && push[1];  
//rgb circuit
always @(*) begin
	rgb = 3'b000;
	if(video_on) begin
		if(square_on)
			rgb = switch;
		else
			rgb = 3'b110;
	end
end

assign square_on = ((pixel_x > square_x_left) && (pixel_x < square_x_right)) && ((pixel_y > 220) && (pixel_y < 260));

//object animation circuit
always @(*) begin
	//square_y_next = square_y_reg;
	square_x_next = square_x_reg;
	vel_next = vel_reg;
	direction_next = direction_reg;
	if ((square_x_right > MAX_X)) begin // make sure that it stays on the screen
		direction_next = 1; // move to left
	end
	else if (square_x_reg < 1) begin 
		direction_next = 0;
	end
	if (posPush0 /* && (vel_reg < 4)*/) begin
		vel_next = vel_reg + 1;  
	end
	else if (posPush1 && (0 < vel_reg)) begin
		vel_next = vel_reg - 1;
	end
	if(refr_tick) begin
		case (direction_reg)
		0: square_x_next = square_x_reg + vel_reg;
		1: begin 
			if (square_x_reg < vel_reg)// protection for high deltas
			square_x_next = 0;
			else
			square_x_next = square_x_reg - vel_reg;
			end
		endcase
	end
end

endmodule