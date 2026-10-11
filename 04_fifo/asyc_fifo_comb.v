`timescale 1ns/1ps

module asyc_fifo_comb #(
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
    output wire full,
    output wire empty
);

localparam depth_bit = $clog2(fifo_depth);

//fifo memory
reg [data_width - 1:0] memory [0:fifo_depth - 1];

//pointer
reg [depth_bit:0] wr_pointer_binary;
reg [depth_bit:0] rd_pointer_binary;
wire [depth_bit:0] wr_pointer_gray;
wire [depth_bit:0] rd_pointer_gray;

reg [depth_bit:0] rd_ff1_gray;
reg [depth_bit:0] rd_ff2_gray;
reg [depth_bit:0] wr_ff1_gray;
reg [depth_bit:0] wr_ff2_gray;

assign wr_pointer_gray = wr_pointer_binary ^ (wr_pointer_binary >> 1);
assign rd_pointer_gray = rd_pointer_binary ^ (rd_pointer_binary >> 1);

//determine whether full or empty
assign full =
    (wr_pointer_gray == {
        ~rd_ff2_gray[depth_bit:depth_bit-1],
         rd_ff2_gray[depth_bit-2:0]
    });

assign empty =
     (wr_ff2_gray == rd_pointer_gray
     );

//wr_clk_domain
always @(posedge clk_wr) begin
    if (!rst_n) begin
        wr_pointer_binary <= 0;
        rd_ff1_gray       <= 0;
        rd_ff2_gray       <= 0;
    end

//rd_pointer_gray 2 FF
    else begin
        rd_ff1_gray <= rd_pointer_gray;
        rd_ff2_gray <= rd_ff1_gray;

        if ((wr_en) && (!full)) begin
             memory[wr_pointer_binary[depth_bit - 1:0]] <= data_in;
             wr_pointer_binary <= wr_pointer_binary + 1;
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
    end

    //wr_pointer_gray 2 FF
    else begin
        wr_ff1_gray <= wr_pointer_gray;
        wr_ff2_gray <= wr_ff1_gray;

        if((rd_en) && (!empty)) begin
              data_out <= memory[rd_pointer_binary[depth_bit - 1:0]];
              rd_pointer_binary <= rd_pointer_binary + 1;
        end
    end

end
endmodule
