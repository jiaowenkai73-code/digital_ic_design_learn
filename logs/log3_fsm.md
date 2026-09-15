# Log 3 - Traffic Light FSM and Counter

## What I Learned

Today I mainly focused on learning how to describe a finite state machine (FSM) in Verilog, and then combined it with a counter to build the basic control logic for a traffic light.

Before today, I was already familiar with the basic concepts of FSMs. I knew the difference between Moore and Mealy state machines, and I could draw state diagrams, create state transition tables, and derive logic expressions. However, when I tried to implement an FSM in Verilog, I still did not know how to start.

Today I gradually built the design in the following order:

```text
State encoding
↓
Current state register
↓
Next-state logic
↓
Output logic
↓
Counter
↓
Using the counter as a state transition condition
```

## RTL Design

Design file: [fsm.v](../02_fsm/fsm.v)

The first step was to assign binary codes to the three traffic-light states:

```verilog
parameter RED    = 2'b00;
parameter GREEN  = 2'b01;
parameter YELLOW = 2'b10;
```

This helped me understand the purpose of `parameter` more clearly.

`parameter` is not simply used to assign a value to a register. Instead, it is used to define a constant or configurable parameter inside a module.

Using names such as `RED`, `GREEN`, and `YELLOW` is much easier to understand than directly writing values such as `2'b00`, `2'b01`, and `2'b10` throughout the code.

Then I defined the current state and the next state:

```verilog
reg [1:0] current_state;
reg [1:0] next_state;
```

At this point, I also reviewed the difference between `reg` and `wire`.

My current understanding is that `wire` is mainly used to represent connections between hardware components and does not store values by itself.

`reg`, on the other hand, can be assigned inside an `always` block.

However, an important point is that a Verilog `reg` does not necessarily mean that an actual hardware register will be generated. The synthesized hardware depends on how the signal is described in the code.

The state register is written using sequential logic:

```verilog
always @(posedge clk) begin
    if (!rst_n)
        current_state <= RED;
    else
        current_state <= next_state;
end
```

This block answers an important question:

> When does the current state actually change?

The answer is that `current_state` is updated to `next_state` only on the rising edge of the clock.

If reset is active, the FSM returns to the `RED` state.

Then I started writing the combinational logic for the outputs and state transitions:

```verilog
always @(*) begin
    next_state   = current_state;

    red_light    = 1'b0;
    green_light  = 1'b0;
    yellow_light = 1'b0;

    case (current_state)

        RED: begin
            red_light = 1'b1;
        end

        GREEN: begin
            green_light = 1'b1;
        end

        YELLOW: begin
            yellow_light = 1'b1;
        end

    endcase
end
```

At this stage, I realized that an FSM can be broken down into several simple questions:

1. What state am I currently in?
2. What should the next state be?
3. What should the outputs be in the current state?

If the FSM simply follows:

```text
RED → GREEN → YELLOW → RED
```

then the state transition itself is quite simple.

However, a real traffic light should not change state on every clock cycle.

For example, the red light may need to stay on for several clock cycles before switching to green.

This introduced the next important part of the design: the counter.

For example, durations could be expressed with parameters like this. These snippets illustrate the idea; the current RTL uses `count` and explicit terminal counts of 9, 19, and 2.

```verilog
parameter RED_TIME    = 10;
parameter GREEN_TIME  = 20;
parameter YELLOW_TIME = 3;
```

The purpose of the counter is to record how many clock cycles the FSM has stayed in the current state.

A basic implementation is:

```verilog
always @(posedge clk) begin
    if (!rst_n)
        counter <= 0;
    else if (current_state != next_state)
        counter <= 0;
    else
        counter <= counter + 1'b1;
end
```

If the FSM stays in the same state, the counter continues to increase.

When the state changes, the counter is cleared and starts counting again for the new state.

The counter can then be used as part of the state transition condition:

```verilog
case (current_state)

    RED: begin
        red_light = 1'b1;

        if (counter == RED_TIME - 1)
            next_state = GREEN;
    end

    GREEN: begin
        green_light = 1'b1;

        if (counter == GREEN_TIME - 1)
            next_state = YELLOW;
    end

    YELLOW: begin
        yellow_light = 1'b1;

        if (counter == YELLOW_TIME - 1)
            next_state = RED;
    end

endcase
```

Now the FSM no longer changes state every clock cycle.

Instead, each state remains active until the counter reaches the required value.

## Questions and Understanding

During today’s study, I mainly asked and thought about the following questions:

- Why should state values be defined using `parameter`?
- Is `parameter RED = 2'b00` considered an assignment?
- What is the difference between a parameter and a normal variable?
- What is the difference between `reg` and `wire`?
- Why do we need both `current_state` and `next_state`?
- When does the FSM actually change state?
- If there is no external input and the output only depends on the current state, is the FSM Moore or Mealy?
- Why does a traffic-light FSM need a counter?
- When should the counter be reset?
- Why do we usually write:

```verilog
counter == RED_TIME - 1
```

instead of:

```verilog
counter == RED_TIME
```

## Summary

The biggest improvement today was that I started to understand how a state diagram can be translated into actual Verilog code.

Previously, I understood FSMs mainly from the perspective of digital logic and state diagrams.

Now I am beginning to see how the same structure is implemented in RTL.

## Next Steps

The next step after this design session was:

```text
Testbench
↓
Compilation
↓
Simulation
↓
Waveform analysis
↓
Checking state transitions and counter behavior
```

The testbench and simulation work is recorded in [Log 4](log4_fsm_tb.md). After that, I want to try implementing another FSM completely by myself, starting from only the state diagram.
