# VHDL Elevator Control System Project

This project implements a control system for 3 elevators in a 32-story building using VHDL. The architecture is divided into two levels:

1.  **Local Controller (`elevator_controller.vhd`):** An FSM (Finite State Machine) per elevator that manages the motor, doors, and individual state.
2.  **Scheduler (`elevator_scheduler.vhd`):** A central supervisor module that receives external calls and allocates the most appropriate elevator based on a cost algorithm.

## 🛠️ Tools and Requirements

To simulate this project, you will need the following tools installed:

- **GHDL:** An open-source VHDL simulator.
- **GTKWave:** A waveform viewer.
- **Make**: To use the provided Makefile.

## 🚀 Simulation Instructions

The provided `Makefile` automates the entire process. Open a terminal in the project root and execute the following commands:

### 1. Compile and Run Simulation

This is the main command. It will compile all VHDL files, run the full simulation, and generate the waveform file (`elevator_system_tb.ghw`).

```bash
make run
```

### 2. View Results

After running the simulation, use this command to open the generated waveform file (.ghw) in GTKWave:

```bash
make wave
```

### 3. Clean Generated Files

To remove the `work/` directory, the testbench executable, and the `.ghw` file, execute:

```bash
make clean
```
