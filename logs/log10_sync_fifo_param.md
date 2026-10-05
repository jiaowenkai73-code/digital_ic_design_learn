# Log 10 - FIFO Parameterization and Removing Count

Date: 2026-10-05

## What I Did

Over the past few days, I extended the basic synchronous FIFO from [Log 9](log9_sync_fifo.md) in two steps: parameterizing the design, then replacing the occupancy counter with extended read/write pointers. The current implementation is saved in [sync_fifo_param.v](../04_fifo/sync_fifo_param.v), with [sync_fifo_param_tb.v](../04_fifo/sync_fifo_param_tb.v) for simulation. The original count-based version remains available for comparison.

The RTL uses `fifo_depth` and `data_width` parameters, with defaults of 16 entries and 10 bits. `localparam depth_bit = $clog2(fifo_depth)` derives the address width. The testbench overrides these defaults with `FIFO_DEPTH = 8` and `DATA_WIDTH = 8`, and passes them into the DUT through named parameter connections.

The input, output, and `write_data` array widths follow `DATA_WIDTH`; the memory depth and write/read loop bounds follow `FIFO_DEPTH`. Instead of repeating individual write statements, the testbench stores test patterns in an array and uses `integer i` with a `for` loop to send them on successive cycles. The final RTL removes the `count` declaration, reset assignment, and update logic, and the testbench no longer references `dut.count` in its monitor.

## What I Learned

Parameterization requires more than replacing constants: port widths, memory dimensions, pointer widths, and testbench stimulus must remain consistent. `$clog2` gives the number of address bits, while `localparam` expresses a value derived from the selected parameters. A `for` loop does not advance simulation time on its own; an event control such as `@(negedge clk)` is needed to separate stimulus across clock cycles.

Ordinary address pointers cannot distinguish empty from full because both conditions can have the same read and write address. Adding one extra bit solves this for a power-of-two FIFO depth. For depth 8, each pointer is 4 bits wide: the low 3 bits address memory and the high bit tracks the wrap phase. The write pointer advances from `0_111` to `1_000` when the eighth entry is written.

The new flag equations are:

```verilog
assign empty = (rd_pointer == wr_pointer);
assign full =
    (rd_pointer[depth_bit-1:0] == wr_pointer[depth_bit-1:0]) &&
    (rd_pointer[depth_bit] != wr_pointer[depth_bit]);
```

Empty means the complete pointers match; full means the address bits match but the wrap bits differ. Memory accesses must use only the low address bits, such as `data[wr_pointer[depth_bit-1:0]]`, rather than the whole extended pointer. During the edits, I corrected the mistaken name `data_bit` to `depth_bit` and removed the remaining counter references.

Read and write remain separate operations gated by `!empty` and `!full`. In a middle state, simultaneous accepted operations advance both pointers and leave occupancy unchanged without storing a counter. At full, simultaneous requests accept only the read; at empty, they accept only the write. Boundary throughput optimization has not been added.

This implementation assumes a positive data width and a power-of-two depth of at least 2. Natural binary wraparound does not support arbitrary depths, and depth 1 would require special handling for the address slices. The testbench is also only partly parameterized: it still explicitly initializes eight entries with 8-bit patterns. Other configurations require suitable test data and verification.

## Simulation Status

The existing testbench compiles with Icarus Verilog and runs to `$finish` at 365 ns, producing `sync_fifo_param_tb.vcd`. The compiler reports a timescale inheritance warning for the RTL. This run uses the 8-entry, 8-bit testbench configuration; it does not validate the default 16-entry, 10-bit configuration or a parameter sweep.

The simulation output shows:

- At 130 ns, the eighth write makes `wr_pointer = 8` (`1_000`) while `rd_pointer = 0` (`0_000`), asserting `full`.
- The attempted write of `AA` while full leaves the write pointer unchanged and does not replace the stored data.
- Reads return `B3 35 F0 55 CC 0F 81` from 170 ns through 230 ns. The read enable drops at 235 ns, leaving one unread entry.
- The section intended to test an empty read actually reads the final `7E` at 250 ns. Both pointers then equal 8 and `empty` asserts. This run therefore does not demonstrate a rejected read while already empty.
- After writing `A1`, `A2`, and `A3`, simultaneous read/write at 310 ns returns `A1` and advances the pointers from 11/8 to 12/9, maintaining an occupancy of three entries.

The read-loop timing is an important follow-up: `rd_en` is assigned after a fixed delay that coincides with a falling edge, then the loop immediately waits for falling edges. In this run, the first wait resumes at the same timestamp, so eight loop iterations cover only seven rising-edge reads. Driving the enable explicitly after `@(negedge clk)` and holding it across eight sampling edges will make the intended duration clear.

Data stimulus is now placed at falling-edge times, improving on the previous testbench, but reset assertion at 20 ns still coincides with a rising edge. The DUT state is unknown before the first effective reset. The testbench currently provides monitoring and waveform output without automatic pass/fail checks. Only comments and trailing whitespace were cleaned up for upload; stimulus timing and RTL behavior were preserved.

Run from `04_fifo`:

```sh
iverilog -Wall -s sync_fifo_param_tb -o sync_fifo_param_sim sync_fifo_param_tb.v sync_fifo_param.v
vvp sync_fifo_param_sim
gtkwave sync_fifo_param_tb.vcd
```

Simulation binaries and waveforms remain local and are not uploaded.

## Next Steps

Make reset and read-enable timing explicit with clock-edge controls, complete all eight reads before testing empty protection, and add automatic data-order and pointer checks. Generate test patterns for each supported width/depth and test repeated wraparound, simultaneous requests at full/empty, and reset recovery. Then explore full-boundary read/write throughput, followed by CDC fundamentals, Gray-code pointers, and asynchronous FIFO design.
