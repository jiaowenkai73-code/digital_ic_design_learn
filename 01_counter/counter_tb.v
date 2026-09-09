`timescale 1ns/1ps

module counter_tb;

reg clk;
reg rst;
reg en;
wire [3:0] count;

// 实例化被测试模块
counter_4bit dut (
    .clk(clk),
    .rst(rst),
    .en(en),
    .count(count)
);

// 产生时钟
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// 产生测试激励
initial begin
    $monitor("time=%0t rst=%b en=%b count=%b", $time, rst, en, count);
    rst = 1;
    en  = 0;

    #20;
    rst = 0;
    en  = 1;
    #170;
    en  = 0;
    #30
    $finish;
end
initial begin
    $dumpfile("counter.vcd");
    $dumpvars(0, counter_tb);
end

endmodule