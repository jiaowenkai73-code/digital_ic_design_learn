`timescale 1ns/1ps

module uart_tx_tb;

reg clk;
reg rst_n;
reg [7:0] data;
reg start_tx;
wire tx;

uart_tx dut(
    .clk(clk),
    .rst_n(rst_n),
    .data(data),
    .start_tx(start_tx),
    .tx(tx)
);

initial begin
    clk = 0;
    forever #10 clk = ~clk; //产生50MHz的时钟周期
end

initial begin
    data = 8'b11110000;
    rst_n = 0;
    start_tx = 0;

    #80 rst_n = 1;

  #120 start_tx = 1;

    #20 start_tx = 0;

    #87000  data = 8'b10100101;
    start_tx = 1;

    #20 start_tx = 0;

    #60000 rst_n = 0;
    
    #40 rst_n = 1;
end

initial begin
    $dumpfile("uart_tx.vcd");
    $dumpvars(0, uart_tx_tb);

    #160000;
    $finish;
end
    
endmodule