# Log 4 - FSM Testbench and Simulation

## What I Learned

Over the past two days, I completed the testbench and simulation flow for a Moore-type traffic light finite state machine.

## RTL Design

Design file: [fsm.v](../02_fsm/fsm.v). The design learning process is recorded in [Log 3](log3_fsm.md).

The FSM cycles through three states:

```text
RED -> GREEN -> YELLOW -> RED
```

The intended state durations are:

```text
RED:     10 clock cycles
GREEN:   20 clock cycles
YELLOW:   3 clock cycles
```

A 5-bit counter controls the duration of each state and is reset when a transition is detected. I also corrected the state-transition comparisons to use decimal literals (`5'd9`, `5'd19`, and `5'd2`) and made `next_state` default to `current_state` so that the FSM remains in the current state until its terminal count is reached.

## Testbench

Testbench file: [fsm_tb.v](../02_fsm/fsm_tb.v). It:

- generates a 10 ns clock with `forever #5 clk = ~clk`;
- applies an active-low reset at startup and again during operation;
- instantiates the DUT with named port connections;
- dumps signals to `traffic_light.vcd` for GTKWave; and
- monitors the reset, internal state, counter, and three light outputs.

This exercise also clarified Verilog signal roles. Signals driven by the testbench, such as `clk` and `rst_n`, are declared as `reg`, while DUT outputs observed by the testbench are declared as `wire`. In a named connection such as `.clk(clk)`, the name on the left is the DUT port and the name on the right is the testbench signal.

## Questions and Understanding

Other questions I clarified:

- In `traffic_light dut(...)`, the module name must match the design, while the instance name `dut` can be chosen freely.
- `%0t` formats simulation time without minimum-width padding. With this testbench's `1ns/1ps` timescale, 35000 in the monitor output represents 35 ns.
- A binary literal contains only 0 and 1. Decimal 19 is `5'd19`, not `5'b19`.

### Counter timing after reset

Waveform inspection exposed an off-by-one concern in the initial RED interval. While reset is asserted, `count` remains at zero. At the first rising edge after reset is released, `current_state` and `next_state` are both RED, so the counter immediately increments from 0 to 1. As a result, the initial `count = 0` value does not occupy a full normal operating cycle.

Later states behave differently because a state transition explicitly loads `count <= 0`, allowing zero to remain stable for a complete cycle before the next increment. This led to an important design question: should the first active cycle after reset keep the counter at zero before counting begins?

The measurement needs a defined starting point. Reset releases at 30 ns, the counter increments to one at 35 ns, and GREEN begins at 125 ns. That is 95 ns from reset release, or nine complete periods from the first active edge. Counting rising edges inclusively from 35 ns to 125 ns gives ten edges, which is a different measurement. Therefore, calling this a missing cycle depends on the intended specification.

If the specification requires ten full periods starting at the first active edge, keeping the counter at zero on that edge would provide the behavior I proposed. This startup behavior has not been implemented.

The observation is a useful reminder that implementing a state duration of N cycles depends not only on comparing against N - 1, but also on exactly when zero is loaded and when the first increment occurs.

## Simulation

The design and testbench can be compiled and run with:

```sh
iverilog -Wall -o traffic_light_sim fsm.v fsm_tb.v
vvp traffic_light_sim
```

Run these commands from `02_fsm`. The generated `traffic_light.vcd` can be inspected in GTKWave. Compilation and simulation completed, with a non-fatal warning because the DUT has no explicit `timescale`.

The trace shows GREEN from 125 to 325 ns (20 periods), YELLOW from 325 to 355 ns (3 periods), and a second reset asserted at 430 ns and sampled at 435 ns. The reset remains asserted until the simulation ends at 550 ns.

This is a stimulus-and-monitor testbench, not an automated assertion-based test. The second reset interrupts the next RED interval, so the run does not demonstrate a complete later 10-period RED interval or recovery after the second reset.

Simulation binaries and waveform files are local artifacts and are not included in the repository.

## Next Steps

- Define precisely when initial RED timing begins after reset.
- Add checks for complete state durations and recovery after the second reset.
- Continue learning about reset timing and synchronization in hardware.
