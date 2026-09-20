# Log 6 - UART TX Testbench

## What I Did

Today I wrote [uart_tb.v](../03_uart/uart_tb.v) to simulate the UART transmitter.

- Generated a 50 MHz clock with a 20 ns period and applied an initial active-low reset.
- Sent `8'b11110000`, then requested `8'b10100101` after the first frame had time to finish. Each `start_tx` pulse lasts one clock cycle.
- Applied a 40 ns reset during the second transmission to exercise reset behavior.
- Used `$dumpfile` and `$dumpvars` to generate `uart_tx.vcd`, and ended the simulation at 160 us.

## What I Learned

At 434 clock cycles per bit, each UART bit lasts 8.68 us and a complete 8N1 frame takes 86.8 us. The testbench needs to leave enough time between transmission requests. Data is sent LSB first, and the synchronous reset takes effect on a rising clock edge.

## Simulation Status

The testbench compiles with Icarus Verilog and runs to `$finish`, producing a VCD waveform. The compiler reports a timescale inheritance warning for `uart_tx`. This testbench currently provides stimulus without automatic pass/fail checks.

## Next Steps

Inspect the waveform for bit timing, LSB-first ordering, and reset recovery, then add automatic checks for the transmitted frame.
