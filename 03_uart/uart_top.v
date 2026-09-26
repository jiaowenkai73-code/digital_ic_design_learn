module uart_top(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start_tx,
    input  wire [7:0] data_in,

    output wire [7:0] data_out,
    output wire       data_valid
);

//the line between the rx and tx.
wire uart_line;

//instantiation
uart_tx u_tx(
    .clk(clk),
    .rst_n(rst_n),
    .data(data_in),
    .start_tx(start_tx),
    .tx(uart_line)
);

uart_rx u_rx(
    .clk(clk),
    .rst_n(rst_n),
    .rx(uart_line),
    .data_valid(data_valid),
    .data_out(data_out)

);

endmodule