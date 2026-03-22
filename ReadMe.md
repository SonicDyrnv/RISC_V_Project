"""
RISC-V 5-Stage Pipelined CPU
This project contains a fully functional 5-stage pipelined processor based on the RISC-V RV32I instruction set architecture. 

Instruction Support
R-type: ADD, SUB, AND, OR, XOR, SLT, SLL, SRL, SRA
I-type: ADDI, ANDI, ORI, XORI, SLTI, SLLI, SRLI, SRAI
Memory: LW, SW
Branch: BEQ, BNE, BLT, BGE, BLTU, BGEU
Jump: JAL

Pipeline Design

Implements a 5-stage pipeline:

IF – Instruction Fetch
ID – Instruction Decode
EX – Execute
MEM – Memory Access
WB – Write Back

Hazard Handling

Data Forwarding
-EX/MEM → EX
-MEM/WB → EX
Load-Use Hazard Detection (Stalling)
Write-back bypass (WB → ID)

Branch Prediction

2-bit Saturating Counter Predictor
16-entry table indexed by PC[5:2]
Reduces pipeline stalls due to branches
Handles misprediction with pipeline flush

RISC_V_Project/
│
├── alu.v               
├── control_unit.v    
├── cpu.v              
├── forwarding_unit.v  
├── predictor.v        
├── reg_file.v         
├── top.v              
├── tb.v               
├── program.hex       
├── Images_GTKWave/   
└── .gitignore

How to Run

iverilog -o simv top.v cpu.v alu.v control_unit.v forwarding_unit.v predictor.v reg_file.v tb.v
vvp simv

View Waveforms (GTKWave)

gtkwave dump.vcd

Key Design Highlights 

Fully pipelined architecture
Efficient hazard resolution
Dynamic branch prediction
Modular Verilog design
Clean testbench validation

Waveforms and execution traces are available in:
Images_GTKWave/

## Connect

-  GitHub: https://github.com/SonicDyrnv
-  Chess.com: https://www.chess.com/member/dyrnv 
  (Current: 1427 | Peak: 1517)

Plays chess to Train Brain from Childhood  
"""