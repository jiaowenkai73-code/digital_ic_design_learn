`timescale 1ns/1ps

module sync_fifo_tb;

reg       clk;
reg       rst;
reg [7:0] data_in;
reg       wr_en;
reg       rd_en;

wire       empty;
wire       full;
wire [7:0] data_out;

sync_fifo dut(
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
   clk = 0;
   forever #5 clk = ~clk;
end

initial begin
      data_in  = 8'b0;
      wr_en    = 1'b0;
      rd_en    = 1'b0;

  #20 rst = 1'b1;

  #35 rst = 1'b0;

    // --------------------------------
    // 2. Write 8 data -> FIFO full
    // --------------------------------
    #10;
    wr_en = 1'b1;

    data_in = 8'h11;
    #10;

    data_in = 8'h22;
    #10;

    data_in = 8'h33;
    #10;

    data_in = 8'h44;
    #10;

    data_in = 8'h55;
    #10;

    data_in = 8'h66;
    #10;

    data_in = 8'h77;
    #10;

    data_in = 8'h88;
    #10;

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
    // 4. Read all 8 data
    // Expected:
    // 11 22 33 44 55 66 77 88
    // --------------------------------
    #10;
    rd_en = 1'b1;

    #80;

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
    // count should stay unchanged
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
    $dumpfile("sync_fifo.vcd");
    $dumpvars(0, sync_fifo_tb);
end

initial begin
    $monitor(
        "time=%0t rst=%b wr_en=%b rd_en=%b data_in=%h data_out=%h empty=%b full=%b count=%d wr_ptr=%d rd_ptr=%d",
        $time,
        rst,
        wr_en,
        rd_en,
        data_in,
        data_out,
        empty,
        full,
        dut.count,
        dut.wr_pointer,
        dut.rd_pointer
    );
end

endmodule
