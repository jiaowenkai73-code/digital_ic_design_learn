# Traffic Light FSM — Testbench and Simulation

Over the past two days, I completed the testbench and simulation flow for a Moore-type traffic light finite state machine.

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

The testbench is stored in `02_fsm/fsm_tb.v`. It:

- generates a 10 ns clock with `forever #5 clk = ~clk`;
- applies an active-low reset at startup and again during operation;
- instantiates the DUT with named port connections;
- dumps signals to `traffic_light.vcd` for GTKWave; and
- monitors the reset, internal state, counter, and three light outputs.

This exercise also clarified Verilog signal roles. Signals driven by the testbench, such as `clk` and `rst_n`, are declared as `reg`, while DUT outputs observed by the testbench are declared as `wire`. In a named connection such as `.clk(clk)`, the name on the left is the DUT port and the name on the right is the testbench signal.

## Counter timing question

Waveform inspection exposed an off-by-one concern in the initial RED interval. While reset is asserted, `count` remains at zero. At the first rising edge after reset is released, `current_state` and `next_state` are both RED, so the counter immediately increments from 0 to 1. As a result, the initial `count = 0` value does not occupy a full normal operating cycle.

Later states behave differently because a state transition explicitly loads `count <= 0`, allowing zero to remain stable for a complete cycle before the next increment. This led to an important design question: should the first active cycle after reset keep the counter at zero before counting begins?

The observation is a useful reminder that implementing a state duration of N cycles depends not only on comparing against N - 1, but also on exactly when zero is loaded and when the first increment occurs. A future refinement could add an explicit post-reset condition or reorganize the state and counter update logic to make the intended cycle count unambiguous.

## Simulation

The design and testbench can be compiled and run with:

```sh
iverilog -o traffic_light_sim fsm.v fsm_tb.v
vvp traffic_light_sim
```

The generated `traffic_light.vcd` file can then be inspected in GTKWave. Simulation binaries and waveform files are local artifacts and are not included in the repository.
