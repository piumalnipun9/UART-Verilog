# UART Communication System in Verilog

This project implements a complete **UART (Universal Asynchronous Receiver/Transmitter)** system using **Verilog HDL**. It includes transmitter and receiver modules, a top-level integration module, comprehensive testbenches, simulation waveforms, and FPGA implementation details.

> 🏫 Developed by undergraduates at the Department of Electronic & Telecommunication Engineering, University of Moratuwa  
> 📘 Course: EN2111 - Electronic Circuit Design  
> 📅 Submitted: May 23, 2025

---

## 🔧 Features

- Fully functional UART Transmitter & Receiver
- Configurable clock and baud rates (default: 50 MHz / 115200 bps)
- State-machine-based architecture
- Loopback test capability
- Complete testbench suite
- Synthesizable on Altera/Intel FPGAs (Cyclone IV/V)
- Resource-efficient (< 200 logic elements)

---

## 🧠 System Overview

### UART Architecture

- **Transmitter (TX)**: Converts 8-bit parallel data into serial format.
- **Receiver (RX)**: Converts serial data back into 8-bit parallel format.
- **Top Module**: Integrates both TX and RX, enables loopback testing.

### UART Frame Format

- 1 Start bit
- 8 Data bits (LSB first)
- 1 Stop bit
- Idle line state: HIGH

---

## 🔬 Testbench and Simulation

### Verification Strategy

- Unit tests for TX and RX modules
- Loopback testbench for full system verification
- Sample input patterns: 0x00, 0xFF, 0xA5, 0xF0, 0x55

### Tools

- ModelSim / QuestaSim / Vivado Simulator
- Simulation timescale: `1ns / 1ps`
- Waveform-based analysis for validation

---

## 📈 Performance Summary

| Metric              | Value                          |
|---------------------|--------------------------------|
| Baud Rate           | 115200 bps                     |
| Bit Period          | ~8.68 µs                       |
| Frame Size          | 10 bits (1+8+1)                |
| Effective Throughput| ~92,160 bits/sec              |
| Latency             | ~86.8 µs per byte              |
| Clock Frequency     | 50 MHz                         |

---

## 🖥️ FPGA Implementation

- **Target Devices**: Intel Altera Cyclone IV / V
- **Clock**: 50 MHz
- **I/O Standard**: LVTTL for UART pins
- **Estimated Usage**:
  - < 200 Logic Elements
  - ~50 Registers
  - No RAM blocks required
- **Pin Assignments**:
  - `clk`: Clock input
  - `rst_n`: Active-low reset
  - `uart_rx_pin`: RX GPIO
  - `uart_tx_pin`: TX GPIO
  - `rx_data_out`: Debug LEDs
  - `tx_busy`: LED indicator

---

## ✅ Results Summary

- Successfully transmitted and received all test data.
- Functional verification passed with no errors.
- Timing matches theoretical baud rate.
- System proved robust under loopback testing.
- Easy to integrate into larger FPGA projects.

---

## 🎓 Lessons Learned

1. Precise timing control is critical in UART systems.
2. FSM design should be simple and well-encoded.
3. Comprehensive simulation detects edge-case bugs early.
4. Modular, parameterized design increases reusability.

---

## 🔄 Applications

- Microcontroller/FPGA serial interfaces
- IoT communication bridges
- Serial terminal interfaces
- Debugging tools for embedded systems
- Educational demos in digital communication

---

## 👨‍💻 Authors

- **220562U** - Samuditha H.K.P.  
- **220577U** - Sanjeewa P.M.G.P.N.  
- **220596C** - Senaweera S.A.H.D.

---

## 📄 License

This project is intended for educational use only. Please cite or credit the authors if reused.

