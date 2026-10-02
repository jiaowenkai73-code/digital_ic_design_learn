# Log 9 - Synchronous FIFO RTL and Testbench

Date: 2026-10-02

## What I Did

Implemented an 8-bit-wide, 8-entry synchronous FIFO in [sync_fifo.v](../04_fifo/sync_fifo.v) and wrote [sync_fifo_tb.v](../04_fifo/sync_fifo_tb.v). Read and write operations share one clock. An active-high synchronous reset clears the pointers, output register, and occupancy counter.

The design uses an eight-entry memory, 3-bit read/write pointers, and a 4-bit `count` that represents 0 through 8 valid entries. `empty` is asserted when `count == 0`, and `full` when `count == 8`. The 3-bit pointers naturally wrap from 7 to 0.

## What I Learned

Reading an entry does not require clearing its memory location. Advancing the read pointer and updating the occupancy is enough to track which entries are valid. Equal read and write addresses alone cannot distinguish empty from full after pointer wraparound, so this version uses `count`.

Read and write logic use two independent `if` statements so both operations can succeed on the same rising clock edge. The counter is updated once according to the accepted operations: `wr_en && !full` and `rd_en && !empty`. A write alone increments it, a read alone decrements it, and both or neither leave it unchanged. Two separate nonblocking assignments to `count` would not automatically cancel each other: in the same sequential block, the last executed assignment determines the scheduled value.

Boundary decisions use the state before the clock edge. When full and both enables are high, only the read is accepted; when empty and both enables are high, only the write is accepted. This basic version has no full-boundary replacement or empty-boundary bypass. `data_out` updates on an accepted read and retains its value otherwise, except during reset.

I also reviewed `assign`, `wire`, and `reg`: `reg` identifies a procedurally assigned variable in Verilog, while the surrounding logic determines the inferred hardware. NBA means nonblocking assignment (`<=`). Clocked state changes become visible after the sampling edge; they do not require waiting an additional whole clock cycle.

## Simulation Status

The testbench uses a 10 ns clock and exercises writing eight bytes (`11` through `88`), attempting a write while full, reading the eight entries, attempting a read while empty, and simultaneous reading/writing after loading three more bytes. Module names, DUT instantiation, waveform filename, and dump scope use `sync_fifo` / `sync_fifo_tb`.

The renamed sources compile with Icarus Verilog and run to `$finish` at 385 ns, producing `sync_fifo.vcd`. In this run, `count` reaches 8 at 135 ns; the full write attempt leaves it unchanged; reads return `11 22 33 44 55 66 77 88` and reach empty at 245 ns. The empty read attempt retains `data_out = 88`. At 325 ns, simultaneous read/write returns `A1` and keeps `count = 3`. The compiler reports a timescale inheritance warning for the RTL module.

The existing testbench uses fixed delays, with reset release and several input changes coinciding with rising edges. It also leaves `rst` uninitialized until 20 ns. These are testbench limitations: a completed simulation does not establish race-free functional correctness. The testbench currently monitors signals and generates a waveform without automatic pass/fail checks.

Run from `04_fifo`:

```sh
iverilog -Wall -s sync_fifo_tb -o sync_fifo_sim sync_fifo_tb.v sync_fifo.v
vvp sync_fifo_sim
gtkwave sync_fifo.vcd
```

Simulation binaries and waveforms remain local and are not uploaded.

## Next Steps

Initialize reset explicitly, drive stimulus on `negedge clk`, and add automatic checks for data order, full/empty protection, pointer wraparound, and simultaneous operations at both boundaries. Then parameterize width/depth, study extra-bit pointers as an alternative to `count`, and explore boundary throughput improvements. Asynchronous FIFO design, Gray-code pointers, and clock-domain crossing are later learning topics rather than features of this version.
