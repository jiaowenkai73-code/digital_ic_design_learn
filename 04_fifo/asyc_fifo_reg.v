`timescale 1ns/1ps

module asyc_fifo_reg #(
    parameter fifo_depth = 8,
    parameter data_width = 8
)(
    input wire clk_wr,
    input wire clk_rd,
    input wire rst_n,
    input wire wr_en,
    input wire rd_en,
    input wire [data_width - 1:0] data_in,
    output reg [data_width - 1:0] data_out,
    output reg full,
    output reg empty
);

localparam depth_bit = $clog2(fifo_depth);

//fifo memory
reg [data_width - 1:0] memory [0:fifo_depth - 1];

//pointer
reg [depth_bit:0] wr_pointer_binary;
reg [depth_bit:0] rd_pointer_binary;
reg [depth_bit:0] wr_pointer_gray;
reg [depth_bit:0] rd_pointer_gray;

reg [depth_bit:0] rd_ff1_gray;
reg [depth_bit:0] rd_ff2_gray;
reg [depth_bit:0] wr_ff1_gray;
reg [depth_bit:0] wr_ff2_gray;

wire [depth_bit:0] wr_binary_next;
wire [depth_bit:0] wr_gray_next;
wire full_next;

wire [depth_bit:0] rd_binary_next;
wire [depth_bit:0] rd_gray_next;
wire empty_next;


//the data in next clk period
assign wr_binary_next = wr_pointer_binary + (wr_en && !full);
assign wr_gray_next = wr_binary_next ^ (wr_binary_next >> 1);
assign full_next = (wr_gray_next == {~rd_ff2_gray[depth_bit:depth_bit-1],rd_ff2_gray[depth_bit-2:0]});

assign rd_binary_next = rd_pointer_binary + (rd_en && !empty);
assign rd_gray_next = rd_binary_next ^ (rd_binary_next >> 1);
assign empty_next =(wr_ff2_gray == rd_gray_next);


//wr_clk_domain
always @(posedge clk_wr) begin
    if (!rst_n) begin
        wr_pointer_binary <= 0;
        rd_ff1_gray       <= 0;
        rd_ff2_gray       <= 0;
        wr_pointer_gray   <= 0;
        full              <= 0;
    end

 //rd_pointer_gray 2 FF
    else begin
        rd_ff1_gray       <= rd_pointer_gray;
        rd_ff2_gray       <= rd_ff1_gray;
        wr_pointer_binary <= wr_binary_next;
        wr_pointer_gray   <= wr_gray_next;
        full              <= full_next;

        if ((wr_en) && (!full)) begin
             memory[wr_pointer_binary[depth_bit - 1:0]] <= data_in;
        end
    end
end

//rd_clk_domain
always @(posedge clk_rd) begin
    if (!rst_n) begin
        rd_pointer_binary <= 0;
        data_out          <= 0;
        wr_ff1_gray       <= 0;
        wr_ff2_gray       <= 0;
        rd_pointer_gray   <= 0;
        empty             <= 1;
    end

    //wr_pointer_gray 2 FF
    else begin
        wr_ff1_gray       <= wr_pointer_gray;
        wr_ff2_gray       <= wr_ff1_gray;
        rd_pointer_binary <= rd_binary_next;
        rd_pointer_gray   <= rd_gray_next;
        empty             <= empty_next;


        if((rd_en) && (!empty)) begin
           data_out <= memory[rd_pointer_binary[depth_bit - 1:0]];
        end
    end
end
endmodule
