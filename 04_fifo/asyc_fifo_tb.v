
`timescale 1ns/1ps

module asyc_fifo_tb;

parameter FIFO_DEPTH = 8;
parameter DATA_WIDTH = 8;

reg clk_wr;
reg clk_rd;
reg rst_n;
reg wr_en;
reg rd_en;
reg [DATA_WIDTH - 1:0] data_in;
reg [DATA_WIDTH - 1:0] write_data [0:FIFO_DEPTH - 1];

wire [DATA_WIDTH - 1:0] data_out_comb;
wire full_comb;
wire empty_comb;

wire [DATA_WIDTH - 1:0] data_out_reg;
wire full_reg;
wire empty_reg;

integer i;

asyc_fifo_comb #(
    .fifo_depth(FIFO_DEPTH),
    .data_width(DATA_WIDTH)
) dut_comb (
    .clk_wr(clk_wr),
    .clk_rd(clk_rd),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out_comb),
    .full(full_comb),
    .empty(empty_comb)
);

asyc_fifo_reg #(
    .fifo_depth(FIFO_DEPTH),
    .data_width(DATA_WIDTH)
) dut_reg (
    .clk_wr(clk_wr),
    .clk_rd(clk_rd),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out_reg),
    .full(full_reg),
    .empty(empty_reg)
);

// clk_wr T=10ns 100MHz
initial begin
    clk_wr = 0;
    forever #5 clk_wr = ~clk_wr;
end

// clk_rd T=12.5ns 80MHz
initial begin
    clk_rd = 0;
    forever #6.25 clk_rd = ~clk_rd;
end

// VCD
initial begin
    $dumpfile("asyc_fifo.vcd");
    $dumpvars(0, asyc_fifo_tb);
end

initial begin
    data_in = 8'b0;
    wr_en   = 1'b0;
    rd_en   = 1'b0;
    rst_n   = 1'b0;

    write_data[0] = 8'b10110011;
    write_data[1] = 8'b00110101;
    write_data[2] = 8'b11110000;
    write_data[3] = 8'b01010101;
    write_data[4] = 8'b11001100;
    write_data[5] = 8'b00001111;
    write_data[6] = 8'b10000001;
    write_data[7] = 8'b01111110;

    // Reset
    repeat(4) @(negedge clk_wr);
    rst_n = 1;

    // Full test
    @(negedge clk_wr);
    wr_en = 1;

    for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
        data_in = write_data[i];
        @(negedge clk_wr);
    end

    wr_en = 0;

    // Trying to write when full
    // Pay attention to write pointer
    @(negedge clk_wr);
    wr_en = 1;
    data_in = 8'hAA;

    repeat(2) @(negedge clk_wr);
    wr_en = 0;

    // Wait for pointer synchronization
    repeat(4) @(negedge clk_rd);

    // Empty test
    rd_en = 1;

    for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
        @(negedge clk_rd);
    end

    rd_en = 0;

    // Trying to read when empty
    // Pay attention to read pointer
    @(negedge clk_rd);
    rd_en = 1;

    repeat(3) @(negedge clk_rd);
    rd_en = 0;

    // Write 3 data
    @(negedge clk_wr);
    wr_en = 1;
    data_in = 8'hA1;

    @(negedge clk_wr);
    data_in = 8'hA2;

    @(negedge clk_wr);
    data_in = 8'hA3;

    @(negedge clk_wr);
    wr_en = 0;

    // Wait for pointer synchronization
    repeat(4) @(negedge clk_rd);

    // Reading when writing
    @(negedge clk_wr);
    data_in = 8'hB1;
    wr_en = 1;

    @(negedge clk_rd);
    rd_en = 1;

    repeat(4) @(negedge clk_wr);
    wr_en = 0;

    @(negedge clk_rd);
    rd_en = 0;

    #10;
    $finish;
end

endmodule
