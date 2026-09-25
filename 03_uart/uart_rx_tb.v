`timescale 1ns/1ps

module uart_rx_tb;

reg clk;
reg rst_n;
reg rx;

wire [7:0] data_out;
wire data_valid;

// DUT
uart_rx dut (
    .clk(clk),
    .rst_n(rst_n),
    .rx(rx),
    .data_out(data_out),
    .data_valid(data_valid)
);

// 50 MHz clock
initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

// stimulus
initial begin
    rst_n = 0;
    rx = 1;              // UART idle

    #80;
    rst_n = 1;

    // wait before sending
    #200;

    // Start bit
    rx = 0;
    #8680;

    // Send 8'b1010_0101, LSB first
    // bit0 = 1
    rx = 1;
    #8680;

    // bit1 = 0
    rx = 0;
    #8680;

    // bit2 = 1
    rx = 1;
    #8680;

    // bit3 = 0
    rx = 0;
    #8680;

    // bit4 = 0
    rx = 0;
    #8680;

    // bit5 = 1
    rx = 1;
    #8680;

    // bit6 = 0
    rx = 0;
    #8680;

    // bit7 = 1
    rx = 1;
    #8680;

    // Stop bit
    rx = 1;
    #8680;

    // return to idle
    rx = 1;

    #20000;
    $finish;
end

// waveform
initial begin
    $dumpfile("uart_rx.vcd");
    $dumpvars(0, uart_rx_tb);
end

endmodule