`timescale 1ns/1ps

module traffic_light_tb;

reg clk;
reg rst_n;
wire red_light;
wire green_light;
wire yellow_light;

traffic_light dut(
    .clk(clk),
    .rst_n(rst_n),
    .red_light(red_light),
    .green_light(green_light),
    .yellow_light(yellow_light)
);

initial begin
   clk = 0;
   forever #5 clk = ~clk;
end

initial begin
    rst_n = 0;
    #30 rst_n = 1;
    #400 rst_n =0;
    #120
    $finish;
end

initial begin
    $dumpfile("traffic_light.vcd");
    $dumpvars(0, traffic_light_tb);
end

initial begin
   $monitor(
    "time=%0t rst_n=%b state=%b count=%d red=%b green=%b yellow=%b",
    $time,
    rst_n,
    dut.current_state,
    dut.count,
    red_light,
    green_light,
    yellow_light
);
end

endmodule