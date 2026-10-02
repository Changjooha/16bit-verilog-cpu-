# 16-bit Verilog CPU

A 16-bit educational CPU implemented in Verilog as part of a Computer Architecture course project.

This repository contains the original CPU implementation developed for the course assignment, along with standalone ALU and Register File modules implemented during an earlier project stage.

The goal of this repository is to preserve the original implementation while documenting its architecture, supported instructions, design decisions, and verification process.

---

## Overview

The CPU implements a small 16-bit instruction set and executes instructions supplied through a simple memory interface.

The CPU supports:

- Program Counter management
- Instruction fetching through a memory interface
- Instruction decoding
- Four 16-bit general-purpose registers
- Immediate arithmetic
- Register-to-register arithmetic
- Jump control
- Output through the `WWD` instruction
- Executed instruction counting

### Supported Instructions

| Instruction | Description |
|---|---|
| `ADD` | Adds two registers and stores the result in a destination register |
| `ADI` | Adds a sign-extended 8-bit immediate value to a register |
| `LHI` | Loads an 8-bit immediate value into the upper byte of a register |
| `JMP` | Jumps to a 12-bit target address |
| `WWD` | Sends the value of a register to the output port |

---

## Architecture

![CPU Architecture](docs/architecture.png)

The CPU is implemented mainly inside `cpu.v`.

The main internal state consists of:

- 16-bit Program Counter (`pc`)
- Four 16-bit registers (`regfile[0:3]`)
- 16-bit instruction register
- 16-bit instruction counter
- 16-bit output port register

Instruction decoding and datapath control are implemented using combinational logic inside `cpu.v`.

---

## Datapath

![CPU Datapath](docs/datapath.png)

The fetched 16-bit instruction is divided into the following fields depending on the instruction format:

```text
opcode : instruction[15:12]
rs     : instruction[11:10]
rt     : instruction[9:8]
rd     : instruction[7:6]
func   : instruction[5:0]

imm    : instruction[7:0]
target : instruction[11:0]
```

The combinational logic calculates values such as:

```text
next_pc
write_enable
write_addr
write_data
output_enable
next_output_port
```

The processor state is then updated on the positive clock edge.

---

## Instruction Behavior

### ADD

```text
rd <- regfile[rs] + regfile[rt]
```

`ADD` is an R-type instruction.

The CPU recognizes it when:

```text
opcode = 1111
func   = 000000
```

---

### ADI

```text
rt <- regfile[rs] + sign_extend(immediate)
```

The 8-bit immediate value is sign-extended to 16 bits before the addition.

For example:

```text
imm = 11111111
```

is interpreted as:

```text
1111111111111111
```

which represents `-1` in two's complement.

---

### LHI

```text
rt <- { immediate, 8'h00 }
```

For example:

```text
LHI R0, 0x12
```

produces:

```text
R0 = 0x1200
```

---

### JMP

```text
next_pc <- { pc[15:12], target }
```

The upper four bits of the current Program Counter are preserved, while the lower twelve bits are replaced with the jump target.

---

### WWD

```text
output_port <- regfile[rs]
```

`WWD` is used by the test environment to observe values produced by the processor.

---

## Memory Interface

The CPU communicates with the provided memory environment using the following signals:

```text
readM
address
data
inputReady
```

The processor continuously requests instruction reads:

```verilog
assign readM = 1'b1;
assign address = pc;
```

Because `data` is an `inout` bus, the CPU places the bus in a high-impedance state while receiving instruction data:

```verilog
assign data = {`WORD_SIZE{1'bz}};
```

When the memory system asserts `inputReady`, the instruction on the data bus is latched into the CPU.

```text
Memory
   |
   | instruction
   v
data bus
   |
   | inputReady
   v
Instruction Register
```

---

## Original Assignment Timing Model

This repository intentionally preserves the CPU implementation used for the original course assignment.

The original test environment provides instruction data through the memory interface and signals the availability of a new instruction using `inputReady`.

The CPU sets `instruction_valid` when an instruction is received.

In the original implementation, `instruction_valid` remains asserted after the first valid instruction is received. Therefore, the implementation assumes the assignment's memory/testbench timing model, where the processor continuously receives valid instructions as execution progresses.

This behavior is preserved intentionally instead of modifying the original submission for this portfolio repository.

As a result, this project should be understood as an implementation designed for the provided educational simulation environment rather than a general-purpose asynchronous memory protocol.

---

## CPU State Update

Processor state is updated on the positive edge of the clock.

Conceptually:

```text
if reset:
    PC = 0
    num_inst = 0
    output_port = 0
    registers = 0

else if instruction is valid:
    PC = next_pc

    if register write enabled:
        register[write_addr] = write_data

    if output enabled:
        output_port = next_output_port

    num_inst = num_inst + 1
```

The reset signal is active-low.

---

## Standalone ALU

`src/ALU.v` was implemented as a separate component during an earlier stage of the Computer Architecture project.

It supports 16 operations:

| OP | Operation |
|---|---|
| `0000` | ADD |
| `0001` | SUB |
| `0010` | ID |
| `0011` | NAND |
| `0100` | NOR |
| `0101` | XNOR |
| `0110` | NOT |
| `0111` | AND |
| `1000` | OR |
| `1001` | XOR |
| `1010` | Logical Right Shift |
| `1011` | Arithmetic Right Shift |
| `1100` | Rotate Right |
| `1101` | Logical Left Shift |
| `1110` | Arithmetic Left Shift |
| `1111` | Rotate Left |

The ALU handles arithmetic carry and subtraction borrow using an additional temporary bit.

### Important Implementation Note

The standalone `ALU.v` module is included to document the earlier hardware-design stage of the project.

The final `cpu.v` does **not** instantiate this ALU module directly.

Arithmetic operations required by the supported CPU instructions are implemented directly inside the combinational logic of `cpu.v`.

---

## Standalone Register File

`src/RF.v` implements four 16-bit registers.

Features:

- 4 × 16-bit registers
- Two read ports
- One write port
- Asynchronous reads
- Synchronous writes
- Synchronous reset

Conceptually:

```text
         +-------------------+
addr1 -->|                   |--> data1
addr2 -->|  4 x 16-bit RF    |--> data2
         |                   |
addr3 -->| write address     |
data3 -->| write data        |
write -->| write enable      |
         +-------------------+
```

As with the standalone ALU, this module represents an earlier stage of the course project.

The final CPU contains its own internal register array:

```verilog
reg [15:0] regfile [0:3];
```

and does not instantiate `RF.v`.

---

## Repository Structure

```text
16bit-verilog-cpu/
│
├── README.md
├── .gitignore
│
├── src/
│   ├── cpu.v
│   ├── ALU.v
│   └── RF.v
│
├── tests/
│   ├── ALU_tb.v
│   ├── RF_tb.v
│   └── cpu_tb.v
│
└── docs/
    ├── architecture.png
    └── datapath.png
```

---

## Verification

Separate testbenches are provided for the CPU, ALU, and Register File.

### ALU Test

The ALU testbench verifies:

- Arithmetic operations
- Carry behavior
- Borrow behavior
- Boolean operations
- Logical shifts
- Arithmetic shifts
- Rotate operations

Run with Icarus Verilog:

```bash
iverilog -o alu_test src/ALU.v tests/ALU_tb.v
vvp alu_test
```

---

### Register File Test

The Register File testbench verifies:

- Reset behavior
- Register writes
- Write disable behavior
- Asynchronous reads

Run:

```bash
iverilog -o rf_test src/RF.v tests/RF_tb.v
vvp rf_test
```

---

### CPU Test

The CPU testbench verifies execution of:

```text
LHI
ADI
ADD
WWD
JMP
```

It also verifies:

- Program Counter updates
- Immediate sign extension
- Register-to-register arithmetic
- Output port behavior
- Instruction counting
- Jump target calculation

Run:

```bash
iverilog -o cpu_test src/cpu.v tests/cpu_tb.v
vvp cpu_test
```

---

## Design Approach

The project separates combinational next-state calculation from sequential state updates.

The combinational portion determines:

```text
next_pc
write_data
write_addr
write_enable
next_output_port
output_enable
```

The sequential portion updates the processor state on a clock edge.

This structure helped distinguish:

```text
Current State
     |
     v
Combinational Logic
     |
     v
Next State
     |
     v
Clock Edge
     |
     v
Updated State
```

---

## What I Learned

Through this project, I practiced:

- Designing digital hardware using Verilog HDL
- Understanding instruction formats and instruction decoding
- Implementing register files
- Implementing arithmetic and logic operations
- Managing synchronous processor state
- Handling a shared memory data bus
- Implementing a Program Counter
- Implementing immediate and register-based instructions
- Building Verilog testbenches
- Debugging timing-dependent hardware behavior
- Connecting ISA-level behavior with RTL implementation

---

## Project Background

This project originated from coursework in Computer Architecture.

The repository preserves the original assignment implementation while reorganizing the source code, documentation, architecture diagrams, and verification environment into a portfolio-friendly structure.

The emphasis of this repository is on understanding and documenting the hardware implementation rather than presenting the design as a production-ready processor.
