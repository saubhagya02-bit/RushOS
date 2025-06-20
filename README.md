RushOS: A Simple Assembly Kernel

Welcome to RushOS — a minimalist, 16-bit operating system kernel built entirely in Assembly language. Designed for educational purposes, RushOS provides clear insights into how real-mode systems interact with hardware at a low level.

Features

Hardware Information Display
RushOS detects and shows:
- Base, Extended and Total Memory
- CPU Vendor and Brand String
- Number of Hard Drives
- Mouse Connection Status
- Number of Serial Ports + Base I/O Address for COM1
- CPU Features: FPU, MMX, SSE, SSE2

Built-in CLI (Command Line Interface)
Includes a few simple commands:
- info — Displays system hardware information
- help — Lists all available commands
- clear — Clears the screen

Built With
- Assembly Language — 16-bit real mode, written using NASM syntax
- Flat Binary Format — Fully handcrafted without higher-level abstractions

Project Inspiration & Thanks

This OS project is heavily inspired by [MikeOS](http://mikeos.sourceforge.net/) — a fantastic educational system for understanding low-level OS development.

Huge thanks to:
- Mike McLaren and the MikeOS Developers for open-source inspiration
- NASM and QEMU communities for powerful tooling

Getting Started

Prerequisites

Ensure you have the following tools installed:

- NASM — Netwide Assembler  
- QEMU 

Build & Run

bash
sudo ./build-linux.sh && sudo ./test-linux.sh

Screenshots
Here's a glimpse of NashOS running in an emulator:


![1](https://github.com/user-attachments/assets/d91a8d45-0a5c-4dc7-baf7-42cf2f5a9a61)


![2](https://github.com/user-attachments/assets/9e1e66f4-4e3b-443a-90e8-df218a86a895)


![3](https://github.com/user-attachments/assets/317cafc7-e4d9-4624-b511-954c5295b72e)

![4](https://github.com/user-attachments/assets/69ab5b92-6a41-426b-831c-643a7cca938d)


