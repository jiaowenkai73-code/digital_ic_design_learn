# Log 7 - UART RX RTL and Testbench

Date: 2026-09-25

## What I Did

Implemented [uart_rx.v](../03_uart/uart_rx.v) and simulated it with [uart_rx_tb.v](../03_uart/uart_rx_tb.v). Unlike TX, the receiver must detect the start of a frame and decide when to sample each incoming bit.

- Used four FSM states: `IDLE`, `START_BIT`, `DATA`, and `STOP_BIT`.
- Detected a low `rx` level in IDLE and checked it again at `baud_counter == 217` to reject a false start. A valid start bit completes at count 433.
- Sampled each data bit near its center at count 217, storing it in `data_out[data_counter]`. The bit index advances at count 433, receiving bits 0 through 7 in LSB-first order.
- Checked for a high stop bit at count 217 to assert `data_valid`, then returned to IDLE after the stop bit ended.
- Used a 50 MHz clock and an initial active-low reset in the testbench. Sent `8'b1010_0101` (`8'hA5`) as an 8N1 frame, holding each bit for 8680 ns.

## What I Learned

At 50 MHz and a target baud rate of 115200, one bit takes approximately 434 clock cycles, or 8.68 us. Sampling near the middle of a bit keeps the sample away from bit boundaries and provides timing margin. The FSM makes start validation, data sampling, and stop-bit checking easier to organize.

`data_out` is assembled one bit at a time; downstream logic should use `data_valid` to identify a completed valid byte. In this version, `data_valid` is combinational and stays high for one clock period in the nominal test when the stop bit is stable.

## Simulation Status

The existing testbench compiles with Icarus Verilog and runs to `$finish` at 107.08 us, producing `uart_rx.vcd`. Waveform data confirms that the received byte is `8'hA5`, `data_valid` pulses high once for 20 ns, and the FSM returns to IDLE. The compiler reports a timescale inheritance warning for `uart_rx`.

The testbench currently provides one nominal frame without automatic pass/fail checks. False starts, invalid stop bits, consecutive frames, and reset during reception still need verification. The external `rx` input is used directly in this learning version; input synchronization remains a future hardware improvement.

## Next Steps

Connect TX and RX in a top-level module for a loopback test, then compare the transmitted and received bytes. Review how a child module's registered output connects to a `wire` at the top level, and add checks for more data patterns and reset recovery.
