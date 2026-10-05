`timescale 1ns/1ps

module sync_fifo_param_tb;

parameter FIFO_DEPTH = 8;
parameter DATA_WIDTH = 8;

reg       clk;
reg       rst;
reg [DATA_WIDTH - 1:0] data_in;
reg       wr_en;
reg       rd_en;
reg [DATA_WIDTH - 1:0] write_data [0:FIFO_DEPTH - 1];

integer i;

wire       empty;
wire       full;
wire [DATA_WIDTH - 1:0] data_out;

sync_fifo_param #(
    .fifo_depth(FIFO_DEPTH),
    .data_width(DATA_WIDTH)
) dut(
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_out(data_out),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .empty(empty),
    .full(full)
);

initial begin
   clk = 1;
   forever #5 clk = ~clk;
end

initial begin
      data_in  = 8'b0;
      wr_en    = 1'b0;
      rd_en    = 1'b0;
      rst      = 1'b0;
      write_data[0] = 8'b10110011;
      write_data[1] = 8'b00110101;
      write_data[2] = 8'b11110000;
      write_data[3] = 8'b01010101;
      write_data[4] = 8'b11001100;
      write_data[5] = 8'b00001111;
      write_data[6] = 8'b10000001;
      write_data[7] = 8'b01111110;
  #20 rst = 1'b1;

  #35 rst = 1'b0;
  @(negedge clk);
  wr_en = 1'b1;

for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
    data_in = write_data[i];
    @(negedge clk);
end

    wr_en = 1'b0;




    // --------------------------------
    // 3. Try writing when FULL
    // Should NOT write
    // --------------------------------
    #10;
    wr_en   = 1'b1;
    data_in = 8'hAA;

    #10;
    wr_en = 1'b0;


    // --------------------------------
    // 4. Attempt to read FIFO_DEPTH entries (see Log 10 for timing)
    // Expected:
    // B3 35 F0 55 CC 0F 81 7E (default TB configuration)
    // --------------------------------
    #10;
    rd_en = 1'b1;

    for ( i = 0 ; i < FIFO_DEPTH ; i = i + 1) begin
          @(negedge clk);
    end


    rd_en = 1'b0;


    // --------------------------------
    // 5. Try reading when EMPTY
    // Should NOT read
    // --------------------------------
    #10;
    rd_en = 1'b1;

    #10;
    rd_en = 1'b0;


    // --------------------------------
    // 6. Write 3 data
    // Prepare middle state
    // --------------------------------
    #10;
    wr_en   = 1'b1;
    data_in = 8'hA1;

    #10;
    data_in = 8'hA2;

    #10;
    data_in = 8'hA3;

    #10;
    wr_en = 1'b0;


    // --------------------------------
    // 7. Simultaneous read + write
    // FIFO is neither empty nor full
    // Occupancy should stay unchanged; both pointers advance
    // --------------------------------
    #10;

    data_in = 8'hB1;
    wr_en   = 1'b1;
    rd_en   = 1'b1;

    #10;

    wr_en = 1'b0;
    rd_en = 1'b0;


    // --------------------------------
    // 8. Finish
    // --------------------------------
    #50;

    $finish;

end

initial begin
    $dumpfile("sync_fifo_param_tb.vcd");
    $dumpvars(0, sync_fifo_param_tb);
end


initial begin
    $monitor(
        "time=%0t rst=%b wr_en=%b rd_en=%b data_in=%h data_out=%h empty=%b full=%b  wr_ptr=%d rd_ptr=%d",
        $time,
        rst,
        wr_en,
        rd_en,
        data_in,
        data_out,
        empty,
        full,
        dut.wr_pointer,
        dut.rd_pointer
    );
end

endmodule
