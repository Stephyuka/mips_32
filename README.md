# implementation of mips with verilog

Rui Tian 


The verilog programs is based on The **Nexys 4 DDR** board.
All reports were written in Chinese.
Including code and report of three different phase:

### Single-Cycle MIPS
* Implement MIPS CPU with single circle.
* Support instructions:
	* reg: subu, addu, sltu, add, sub, nor, or, xor, slt, sll, srl, sra, sllv, srlv, srav, nop, jr
	* imm: addi, lui, ori, xori, sw, lw, beq, bne, bgz, slti, blez
	* jump: j, jal
* User can use a  Nexys 4 DDR board to testify all the functions.

### Multiple-Cycle MIPS:
* Implement MIPS CPU with multiple circles:
	* My FSM set 23 different states:
<div style="text-align:center">
<img src="multi_circle/fsm.png" height=800>
</div>
*  Including a simple Cache

### Pipeline MIPS:
* Implement MIPS CPU with multipipeline.
* Using separate cache for instruction memory and data memory.
