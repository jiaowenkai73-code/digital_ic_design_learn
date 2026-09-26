`timescale 1ns/1ps

module uart_top_tb;

reg        clk;
reg        rst_n;
reg        start_tx;
reg  [7:0] data_in;
wire [7:0] data_out;
wire       data_valid;

uart_top dut(
    .clk(clk),
    .rst_n(rst_n),
    .start_tx(start_tx),
    .data_in(data_in),
    .data_valid(data_valid),
    .data_out(data_out)
);

//50MHz
initial begin
     clk = 0;
     forever #10 clk = ~clk;
end
 
//stimulus
initial begin
      rst_n = 0;
      start_tx = 0;
      data_in = 8'b0;

      #40  rst_n = 1;

    #300 begin
            start_tx = 1;
            data_in = 8'b10011110;
        end
      
      #20   start_tx = 0;

    #100000 begin 
              start_tx = 1;
              data_in = 8'b00001111;
              end

     #20 start_tx = 0;
     
     #50000 rst_n = 0;

     #20 rst_n = 1;
    
     #1000 

      $finish;
end

initial begin
    $dumpfile("uart_top.vcd");
    $dumpvars(0, uart_top_tb);
end

endmodule
