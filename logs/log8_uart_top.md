# Log 8 - UART TX/RX Top-Level Loopback

Date: 2026-09-26

## What I Did

Created [uart_top.v](../03_uart/uart_top.v) to connect the existing [UART TX](../03_uart/uart_tx.v) and [UART RX](../03_uart/uart_rx.v). Both modules share `clk` and `rst_n`, and an internal `wire uart_line` connects TX's serial output to RX's serial input.

```text
data_in -> uart_tx -> uart_line -> uart_rx -> data_out / data_valid
```

Wrote [uart_top_tb.v](../03_uart/uart_top_tb.v) with a 50 MHz clock and an initial active-low reset. The first request sends `8'b10011110` (`8'h9E`) as a complete frame. The second sends `8'b00001111` (`8'h0F`), then asserts reset about 50 us into transmission to deliberately interrupt the frame. Each `start_tx` pulse lasts 20 ns.

## What I Learned

The top-level module organizes and connects existing modules. `data_out` is a `reg` inside RX because clocked logic assigns it, but a `wire` in the top level because it is driven by the child module's output. `uart_line` is an internal connection rather than an external port.

After a completed frame, `data_out` retains the received value during idle; it does not need to be cleared when STOP_BIT returns to IDLE. `data_valid` identifies when a complete valid byte is available. In the current RX implementation, the next frame updates `data_out` bit by bit, so downstream logic should capture the byte when `data_valid` is asserted rather than assume the previous byte remains unchanged throughout reception.

Reset clears the modules' internal state and registers on a rising clock edge. It does not change the testbench-driven `data_in`: that input remains `8'h0F` after the second reset.

## Simulation Status

The existing testbench compiles with Icarus Verilog and runs to `$finish` at 151.4 us. Inspection of the generated VCD confirms:

- The first frame is received as `8'h9E`. `data_valid` is high from 82.83 us to 82.85 us, a single 20 ns clock period.
- Both FSMs return to IDLE after the first frame, while `data_out` retains `8'h9E` during idle.
- The second reset is asserted at 150.38 us while both FSMs are in DATA. At the next rising edge, 150.39 us, both FSMs return to IDLE, the baud and bit counters clear, TX's data register and RX's `data_out` clear, and `uart_line` returns high.
- The interrupted second frame produces no additional `data_valid` pulse.

The compiler reports timescale inheritance warnings for the three RTL modules. The testbench provides stimulus and waveform output without automatic pass/fail checks. It verifies one complete loopback frame and interruption by reset; successful transmission of a fresh frame after reset remains to be tested.

## Next Steps

Add automatic checks and more complete frames, including a new transmission after reset. Review registered `data_valid` timing and synchronization for an external asynchronous RX input, then continue learning FIFO design.
