# Log 14 - APB Slave RTL Implementation

Date: 2026-10-23

## What I Did

Implemented [apb_slave_32bit.v](../05_apb/apb_slave_32bit.v), following the APB concepts recorded in [Log 13](log13_apb_protocol.md). The module is named `apb_slave`, with default parameters `data_width = 32` and `address_width = 8`.

The initial register map is:

| Byte offset | Register | Access | Reset value / read value |
| --- | --- | --- | --- |
| `0x00` | `ctrl_reg` | Read/write | Resets to zero |
| `0x04` | `data_reg` | Read/write | Resets to zero |
| `0x08` | `status` | Read-only | Constant value 1 |

The design is a standalone register interface. Although a source comment mentions UART registers, no UART module is connected yet, and `status` is a constant placeholder rather than a live peripheral status signal.

## What I Learned

The transfer conditions are expressed as:

```verilog
assign write_enable = psel && penable && pready && pwrite;
assign read_enable  = psel && penable && pready && !pwrite;
```

The slave sets `pready = 1'b1` and `pslverr = 1'b0`, so it inserts no wait states and reports no errors. Writes to unrecognized addresses, including the read-only status address, leave the writable registers unchanged. Unrecognized reads return zero. These are the behaviors of this learning implementation, not error-detection features.

Writes use a sequential block triggered by `posedge pclk` or `negedge preset_n`. The active-low asynchronous reset clears `ctrl_reg` and `data_reg`. During a valid write, a `case (paddr)` statement selects the register to update with a nonblocking assignment. SETUP alone does not update the registers.

Reads use a combinational `always @(*)` block with blocking assignments. The block first assigns zero to `prdata`, then overrides it when a valid read selects a mapped address. This default assignment covers inactive reads as well as unknown addresses and prevents unintended latch inference. Declaring `prdata` as `reg` allows procedural assignment; it does not by itself make the read path a clocked register.

The chat drafts helped me identify several practical RTL issues: inconsistent spellings such as `crtl_reg` and `ctrl_reg`, `wirte_enable` versus `write_enable`, using `clk` instead of the declared `pclk`, missing `endcase` statements, and a malformed hexadecimal literal. I also changed the read mux from nonblocking assignments to blocking assignments and supplied a default value for every combinational path. The current saved source contains those corrections.

Another useful distinction was the timing of `read_enable`. It can become high during ACCESS, allowing `prdata` to settle before the completion edge. The clocked write block, in contrast, acts only when its clock event occurs and the write condition is true.

## Validation Status

The saved RTL passes the following Icarus Verilog compile and elaboration check without compiler warnings:

```sh
iverilog -g2012 -Wall -tnull -s apb_slave 05_apb/apb_slave_32bit.v
```

Run this command from the repository root. The `-tnull` check does not execute transactions or produce a waveform. There is currently no APB testbench in `05_apb`, so functional simulation, readback checks, and reset testing have not yet been performed. Compilation alone does not prove protocol correctness or absence of synthesis issues.

The module exposes width parameters, but the register map still uses fixed four-byte offsets, and some zero literals are explicitly 32 bits. Other parameter configurations have not been verified. The design also has no byte-write strobes, programmable wait states, or error responses. Only trailing whitespace was cleaned up for upload; the RTL behavior was preserved.

## Next Steps

Write an APB testbench to check reset, writes and readback of both writable registers, the constant status value, ignored writes to read-only or unmapped addresses, and zero-valued unmapped reads. Check that SETUP does not modify state and that back-to-back transfers include a new SETUP cycle. Add automatic comparisons before extending the design with wait states or an actual peripheral connection.
