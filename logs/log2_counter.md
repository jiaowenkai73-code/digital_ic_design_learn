# Log 2 - 4-bit Counter and Testbench

## What I Learned

Today I reviewed some basic Verilog concepts and completed my first small RTL design and simulation flow.

### Verilog Review

- Reviewed the difference between `net`, `wire`, and `reg`
- Reviewed signal drivers and how to determine whether a signal should be declared as `wire` or `reg`
- Reviewed blocking assignment `=` and non-blocking assignment `<=`
- Understood why sequential logic usually uses non-blocking assignment
- Reviewed `always @(*)` for combinational logic
- Reviewed `always @(posedge clk)` for sequential logic
- Reviewed module instantiation and port connection

## RTL Design

Implemented a 4-bit up counter with:

- Clock input `clk`
- Synchronous reset `rst`
- Enable signal `en`
- 4-bit output `count`

Behavior:

- When `rst = 1`, `count` is reset to `0000`
- When `rst = 0` and `en = 1`, `count` increases by 1 on every rising edge of `clk`
- When `en = 0`, `count` keeps its current value
- After `1111`, the 4-bit counter overflows back to `0000`

## Testbench

For the first time, I wrote a basic Verilog testbench by myself.

The testbench includes:

- Clock generation using `initial` and `forever`
- Reset stimulus
- Enable signal stimulus
- DUT instantiation
- Signal monitoring using `$monitor`
- VCD waveform generation using `$dumpfile` and `$dumpvars`
- `$dumpfile` specifies the waveform output file, while `$dumpvars` specifies which signals are recorded
- Simulation termination using `$finish`


