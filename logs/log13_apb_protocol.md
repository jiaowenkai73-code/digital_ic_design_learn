# Log 13 - APB Protocol Fundamentals

Date: 2026-10-23

## What I Studied

After learning FIFO design, I started studying APB (Advanced Peripheral Bus) and how a bus transaction accesses peripheral registers. This entry records the protocol concepts separately from the RTL implementation in [Log 14](log14_apb_slave_rtl.md).

My first implementation targets a simple register interface. The controller supplies the address, selection, transfer direction, and write data; the peripheral returns read data, readiness, and an error response. I focused on connecting these signal roles to the actual clock edge at which a transfer completes.

## What I Learned

An APB transfer has a one-cycle SETUP phase followed by an ACCESS phase. For the selected peripheral, SETUP uses `PSEL = 1` and `PENABLE = 0`; ACCESS uses both high. A transfer completes on a rising `PCLK` edge with `PSEL`, `PENABLE`, and `PREADY` high. If `PREADY` is low, ACCESS continues. Address, direction, selection, and write data remain stable until completion. A following transfer needs another SETUP phase, even if the same peripheral stays selected. These timing rules were checked against the [Arm AMBA APB Protocol Specification](https://documentation-service.arm.com/static/64257f64314e245d086bc8b7).

`PWRITE = 1` selects a write using `PWDATA`; `PWRITE = 0` selects a read using `PRDATA`. In a zero-wait-state peripheral, `PREADY` can remain high. This removes extra ACCESS wait cycles, but SETUP is still required.

One question I raised was whether the read-enable condition becomes true as soon as ACCESS begins. It does: a combinational expression such as `psel && penable && pready && !pwrite` can assert during the ACCESS cycle. However, that level becoming high is not itself the transaction-completion event. The controller samples the read result at the completing clock edge. This distinction helped me separate combinational signal changes from clocked state updates.

For my zero-wait-state register interface, the read mux can present the addressed value during ACCESS, while a write updates the addressed register at the completing rising edge. Registering the read result only at that same completion edge would make the new value too late for a controller sampling it on that edge, unless the interface timing were redesigned.

I also reviewed byte addressing. In the planned 32-bit register map, one register occupies four bytes, so successive register offsets are `0x00`, `0x04`, and `0x08`. Address decoding identifies a register; it does not mean that the design needs a separate physical register for every byte address.

## Next Steps

Implement a small APB slave with control and data registers plus a read-only status value. Keep the first version always ready, then build a testbench that explicitly separates SETUP from ACCESS and checks register updates at the correct sampling edge.
