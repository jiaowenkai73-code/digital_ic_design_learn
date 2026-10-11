# Log 11 - Asynchronous FIFO and Dual-Clock Simulation

Date: 2026-10-11

## What I Did

Over the past few days, I moved from the parameterized, count-free synchronous FIFO in [Log 10](log10_sync_fifo_param.md) to an asynchronous FIFO with separate write and read clocks. I implemented two versions for comparison: [asyc_fifo_comb.v](../04_fifo/asyc_fifo_comb.v), with combinational Gray-code conversion and full/empty flags, and [asyc_fifo_reg.v](../04_fifo/asyc_fifo_reg.v), with registered Gray pointers and flags driven by next-state logic. The existing `asyc_fifo` filenames and module names are retained.

Both versions use binary pointers for local memory addressing, Gray pointers for crossing clock domains, and two-stage synchronizers for the opposite domain's pointer. Each pointer has one extra wrap bit. Both modules default to 8 entries of 8-bit data and use an active-low reset sampled synchronously in each clock domain.

I wrote [asyc_fifo_tb.v](../04_fifo/asyc_fifo_tb.v) to instantiate both versions with the same stimulus. The write clock runs at 100 MHz (`#5` half-period), and the read clock at 80 MHz (`#6.25` half-period), under a `1ns/1ps` timescale. The testbench covers filling the FIFO, attempting a full write, draining it, attempting empty reads, loading three more entries, and overlapping read/write activity.

While preparing the testbench, I corrected module-instantiation punctuation, the read-clock signal name, loop punctuation, missing statement terminators, and the hexadecimal literal for `AA`. The final testbench passes its parameters to both DUTs, changes write/read stimulus on the respective falling edges, and includes waits for pointer synchronization. All three source files now include an explicit timescale.

## What I Learned

A synchronous FIFO can compare pointers within one clock domain. An asynchronous FIFO must first transfer information about the remote pointer into the local domain. The write side owns its write pointer and full flag; the read side owns its read pointer and empty flag. A single shared occupancy counter does not fit these independently clocked updates.

Binary pointers are useful for addressing memory, but incrementing a binary number can change several bits at once. Gray encoding is calculated as:

```verilog
gray = binary ^ (binary >> 1);
```

Adjacent encoded pointer values differ in one bit. Each domain samples the remote Gray pointer through two registers and uses the second stage for its flag comparison. This introduces a delay before one side observes progress on the other side. Gray coding does not eliminate metastability, and the destination may skip intermediate pointer values when the source advances faster.

For empty detection, the local read Gray pointer is compared with the synchronized write Gray pointer. For full detection with these extended pointers, the local write Gray pointer is compared with the synchronized read Gray pointer after inverting its top two bits. In Gray code, this is the full-distance relationship; simply copying the binary-pointer rule and inverting only one bit would be incorrect.

The combinational version compares the current pointers. The registered version first calculates whether a transfer will be accepted, then computes the next binary pointer, next Gray pointer, and next flag. For example:

```verilog
assign wr_binary_next = wr_pointer_binary + (wr_en && !full);
assign wr_gray_next = wr_binary_next ^ (wr_binary_next >> 1);
```

Using the next pointer lets the registered full flag assert on the edge accepting the last available entry. The read side applies the same idea when consuming the last entry. Memory accesses still use the current binary address on that edge. Nonblocking assignments update the pointer and flag together afterward.

The two versions need not release their flags at the same time. A registered flag uses the synchronized value available before the edge, so a remote-pointer update reaching the second synchronizer stage can take one additional local clock to affect the flag. Delayed visibility can conservatively block a transfer until the remote progress has propagated.

The `comb` version is useful for studying behavior, but its Gray pointer is an XOR network driven by a binary register. Physical bit-to-bit delays can produce glitches during a binary transition, even though stable Gray values have the one-bit property. Registering the source Gray pointer, as in the `reg` version, avoids exposing that combinational conversion directly to the crossing. RTL simulation alone does not establish CDC safety; synchronizer implementation, pointer-bus timing constraints, and reset behavior still need hardware-level review.

## Simulation Status

Both RTL versions and the existing testbench compile with Icarus Verilog using `-g2012 -Wall`, without warnings in this run. Simulation reaches `$finish` at 510 ns and produces `asyc_fifo.vcd`. Inspection of the generated waveform confirms:

- Both versions assert full at 125 ns after eight writes, with binary write/read pointers 8/0. The attempted `AA` writes at 145 ns and 155 ns do not advance the write pointer.
- Both return `B3 35 F0 55 CC 0F 81 7E`, in order, from 206.25 ns through 293.75 ns. After the final read, both pointers equal 8 and empty asserts.
- The later empty-read attempts leave the read pointer at 8 and retain `data_out = 7E`. Unlike the previous synchronous testbench run, this test actually reaches empty before attempting extra reads.
- After the first write, `empty_comb` clears at 68.75 ns and `empty_reg` at 81.25 ns, one read-clock period later. After reading from full, `full_comb` clears at 225 ns and `full_reg` at 235 ns, one write-clock period later.
- During overlapping activity, both versions read `A1 A2 A3 B1`. The write enable remains high for five accepted writes of `B1`; it does not represent a single write pulse. The extended write pointer wraps from 15 to 0 at 485 ns. Final binary pointers are 0/12, representing four unread entries; the test ends without draining them.

A separate check of the saved waveform confirmed the initial eight-byte order and selected blocked-pointer states for both DUTs. The uploaded testbench itself remains a stimulus-and-waveform testbench without assertions or a scoreboard. Only trailing whitespace and a missing final newline were cleaned up for upload; RTL logic and stimulus were preserved.

These results cover one 8-entry, 8-bit configuration and one deterministic clock ratio. They do not verify analog metastability, all clock phases, stopped clocks, repeated resets, or every supported parameter. The current full-comparison slice requires a power-of-two depth of at least 4; smaller depths and non-power-of-two depths need additional handling. The testbench also explicitly initializes only eight 8-bit patterns.

Run from `04_fifo`:

```sh
iverilog -g2012 -Wall -s asyc_fifo_tb -o asyc_fifo_sim asyc_fifo_comb.v asyc_fifo_reg.v asyc_fifo_tb.v
vvp asyc_fifo_sim
gtkwave asyc_fifo.vcd
```

Simulation binaries and waveforms remain local and are not uploaded.

## Next Steps

Add a separate accepted-transfer scoreboard for each DUT, because their flag timing can differ. Drain and check every remaining entry, then test repeated pointer wraparound, different clock ratios and phases, simultaneous activity near full/empty, and reset recovery in both domains. Review source-registered Gray pointers, synchronizer implementation and timing constraints, and a reset strategy that works reliably for both clocks before treating the design as hardware-ready.
