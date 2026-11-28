<div align="center">

# RetroOS Shell (CSE210 Operating Systems Lab Edition)

[![CI](https://github.com/SaKin32/RetroOS/actions/workflows/ci.yml/badge.svg)](https://github.com/SaKin32/RetroOS/actions/workflows/ci.yml)
![Language](https://img.shields.io/badge/Language-Bash_4.0+-blue?style=for-the-badge&logo=gnubash&logoColor=white)
![Kernel](https://img.shields.io/badge/Kernel-Linux_VFS-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Platform](https://img.shields.io/badge/Platform-WSL%20%7C%20Linux%20%7C%20Docker-0078D6?style=for-the-badge&logo=docker&logoColor=white)
![Course](https://img.shields.io/badge/Course-CSE210-purple?style=for-the-badge)
![License](https://img.shields.io/badge/Academic%20Project-Personal%20Use-ec4899?style=for-the-badge)

**A Custom Unix Shell & Interactive Operating Systems Laboratory**

*POSIX Core · CPU Scheduling · Deadlock Management & Banker's Algorithm · Virtual Memory Demand Paging*

</div>

---

> RetroOS is an interactive Unix shell and operating systems simulation laboratory developed entirely in GNU Bash (4.0+). It bridges standard POSIX shell utilities (REPL, command pipelines, I/O redirection, job control) with comprehensive demonstrations of foundational Operating System concepts—including CPU Scheduling, Process Control Blocks (PCB), Deadlock Detection and Prevention, Dijkstra's Banker's Algorithm, and Virtual Memory Management.

---

## Tools and Technologies Used

| Technology / Tool | Category | Role in RetroOS Shell |
| :--- | :--- | :--- |
| **GNU Bash (4.0+)** | Primary Language | Interactive shell REPL, syntax parser, and entire algorithm implementation |
| **Linux `/proc` VFS** | Kernel Interface | Reading live process descriptors (`task_struct`), RAM, CPU stats, and uptime |
| **POSIX Primitives** | System Calls | `fork()`, `exec()`, `wait()`, anonymous pipes, and signal handling (`SIGINT`, `SIGTERM`) |
| **Atomic File Locks** | Synchronization | Mutual exclusion primitive using `set -o noclobber` for deadlock simulation |
| **`strace`** | Kernel Telemetry | Tracing live program system calls (`execve`, `openat`, `clone3`, `exit_group`) |
| **ANSI 24-bit TrueColor** | Terminal Engine | Custom color themes (`cyber`, `dracula`, `retro`, `matrix`) and Gantt chart graphics |
| **WSL2 / Git Bash** | Host Environment | Windows cross-platform execution compatibility layer |

---

## Table of Contents
1. [Tools and Technologies Used](#tools-and-technologies-used)
2. [Academic Overview](#academic-overview)
3. [System Architecture](#system-architecture)
4. [Core Operating System Modules](#core-operating-system-modules)
   - [1. CPU Scheduling and Gantt Chart](#1-cpu-scheduling-and-gantt-chart-schedsh)
   - [2. Process Control Block and Process Lifecycle](#2-process-control-block-and-process-lifecycle-pcbsh--forkdemosh)
   - [3. Deadlock Detection, Prevention and Avoidance](#3-deadlock-detection-prevention-and-avoidance-deadlocksh--bankerssh)
   - [4. Virtual Memory and Page Replacement](#4-virtual-memory-and-page-replacement-memorysh)
   - [5. Kernel Interface and Hardware Monitoring](#5-kernel-interface-and-hardware-monitoring-sysinfosh)
5. [Shell Environment Features](#shell-environment-features)
6. [Directory Structure](#directory-structure)
7. [Getting Started and Installation](#getting-started-and-installation)
   - [Running on Linux or WSL (Recommended)](#running-on-linux-or-wsl-recommended)
   - [Running on Windows (Git Bash)](#running-on-windows-git-bash)
8. [Command Reference Cheatsheet](#command-reference-cheatsheet)
9. [Academic Metadata](#academic-metadata)

---

## Academic Overview

The objective of this project is to provide a rigorous, interactive bridge between operating system theory and execution behavior. Designed for CSE210 (Operating Systems), RetroOS provides empirical verification for:

- Process State Transitions and Schedulers: Dynamic queue simulation of New, Ready, Running, and Terminated states alongside visual Gantt charts.
- Deadlock Theory: Practical demonstration of the four Coffman conditions, cycle detection in Wait-For Graphs, and proactive avoidance using Dijkstra's Banker's Algorithm.
- Demand Paging and Memory Hierarchy: Simulation of FIFO, LRU, and Optimal page replacement with formal proof of Belady's Anomaly.
- Kernel Telemetry: Direct inspection of the Linux `/proc` pseudo-filesystem to extract live task structures (`task_struct`), scheduling parameters, and hardware statistics.

---

## System Architecture & Execution Flow

### 1. Master Shell Architecture & REPL Loop

```mermaid
flowchart TD
    Start([Shell Launched: retroos.sh]) --> Init[Load Core Libraries: ui.sh, theme.sh, banner.sh]
    Init --> Modules[Source Lab Modules: sched, pcb, memory, deadlock, bankers, sysinfo]
    Modules --> Banner[Display Fastfetch Telemetry & ASCII Art Banner]
    
    subgraph REPL ["The Master REPL Loop"]
        Prompt["1. Render Dynamic Prompt: user@retros (theme) >"]
        Read["2. Readline Input with Session History Buffer"]
        Parse{"3. Tokenize & Dispatch Input"}
        
        Prompt --> Read --> Parse
        
        Parse -- "Internal Function (sched, bankers, meminfo, etc.)" --> ExecFunc[Execute In-Memory Function in Current Shell Context]
        Parse -- "Standard Unix Tool (ls, grep, cat, vim)" --> ForkExec["POSIX fork() & exec() Child Subshell"]
        Parse -- "Pipeline / Redirection (| , > , &)" --> PipeCtrl["Setup anonymous pipe() & background job control"]
        
        ExecFunc --> UpdateLast["Update Exit Code & History Buffer"]
        ForkExec --> UpdateLast
        PipeCtrl --> UpdateLast
        UpdateLast --> Prompt
    end
```

### 2. Core OS Simulation Algorithm Loops

```mermaid
flowchart LR
    subgraph SchedLoop ["CPU Scheduling Engine (sched.sh)"]
        direction TB
        S1[Ready Queue: arrival:burst:priority] --> S2{Preemptive or Non-preemptive?}
        S2 -- Round Robin --> S3["Time Quantum Slice (q)"]
        S2 -- FCFS/SJF/Prio --> S4["Priority / Burst Sort"]
        S3 & S4 --> S5["Dispatch to Live Animated Gantt Pill Stream"]
        S5 --> S6["Compute Metrics: TAT = CT - AT, WT = TAT - BT"]
    end

    subgraph BankerLoop ["Banker's Safety Engine (bankers.sh)"]
        direction TB
        B1["Initialize: Work = Available, Finish = False"] --> B2{"Find Process Pi where Finish[i]==0 and Need[i] <= Work"}
        B2 -- Found Pi --> B3["Work = Work + Allocation[Pi], Finish[Pi]=1"]
        B3 --> B2
        B2 -- None Found --> B4{"All Finish == 1?"}
        B4 -- Yes --> B5["SAFE State: Generate Safe Sequence"]
        B4 -- No --> B6["UNSAFE State: Deadlock Imminent, Deny Request"]
    end

    subgraph MemoryLoop ["Demand Paging Engine (memory.sh)"]
        direction TB
        M1[Next Page Reference] --> M2{"Page in RAM Frames?"}
        M2 -- Yes --> M3["Page HIT: Update LRU timestamp"]
        M2 -- No --> M4["Page FAULT: Increment Fault Counter"]
        M4 --> M5{"Any Free Frame Available?"}
        M5 -- Yes --> M6["Allocate to Empty Frame"]
        M5 -- No --> M7["Victim Selection: FIFO / LRU / Optimal"]
        M7 --> M8["Evict Victim & Load Requested Page"]
    end
```

---

## Academic Textbook Alignment

RetroOS is structurally mapped to the definitive undergraduate textbook **"Operating System Concepts" (Silberschatz, Galvin & Gagne)**:

| Textbook Chapter | Operating System Theory | RetroOS Implementation | Key Command |
| :--- | :--- | :--- | :--- |
| **Chapter 3: Processes** | Process Creation, PCB Structure, `task_struct`, State Transitions | `lab/modules/pcb.sh`, `forkdemo.sh` | `pcb sim`, `pcb self`, `forkdemo` |
| **Chapter 5: CPU Scheduling** | Preemptive vs Non-preemptive, Gantt Chart, FCFS, SJF, RR, Priority | `lab/modules/sched.sh` | `sched rr 2 ...`, `sched compare` |
| **Chapter 8: Deadlocks** | 4 Coffman Conditions, Wait-For Graph Cycles, Banker's Avoidance | `lab/modules/deadlock.sh`, `bankers.sh` | `deadlock`, `bankers` |
| **Chapter 9: Virtual Memory** | Demand Paging, Page Faults, FIFO, LRU, Optimal, Belady's Anomaly | `lab/modules/memory.sh` | `memory compare`, `memory belady` |
| **Chapter 1: OS Structures** | Dual-mode Operation (User Ring 3 vs Kernel Ring 0), Syscalls, `/proc` | `lab/modules/sysinfo.sh` | `kinfo`, `meminfo`, `mode-switch` |

---

## Core Operating System Modules

### 1. CPU Scheduling and Gantt Chart (`sched.sh`)
Implements non-preemptive and preemptive scheduling algorithms with interactive graphical Gantt charts, computing Turnaround Time (TAT = Completion Time - Arrival Time) and Waiting Time (WT = Turnaround Time - Burst Time).

- Supported Algorithms:
  - FCFS (First-Come, First-Served): Non-preemptive execution scheduled strictly by arrival timestamp.
  - SJF (Shortest Job First): Non-preemptive algorithm that minimizes average waiting time.
  - Priority Scheduling: Non-preemptive execution prioritized by integer weight (smaller integer = higher priority).
  - Round Robin (RR): Time-sliced preemptive execution with customizable quantum (q).
- Comparative Benchmark (`sched compare`):
  Executes all four scheduling policies side-by-side against an identical workload to empirically verify theoretical performance metrics.

```bash
# Syntax: arrival:burst[:priority]
sched rr 2 0:5 1:3 2:8             # Round Robin with time quantum = 2
sched compare 0:5:2 1:3:1 2:8:3    # Side-by-side comparative analysis
```

---

### 2. Process Control Block and Process Lifecycle (`pcb.sh` & `forkdemo.sh`)
- Live PCB Extraction (`pcb [PID]`):
  Reads live Linux kernel data structures from `/proc/$PID/status` and `/proc/$PID/stat`:
  - Process ID (PID), Parent Process ID (PPID), User ID (UID), and State.
  - Virtual Memory (`VmSize`) and Resident Set Size (`VmRSS`).
  - Open File Descriptors count.
  - Voluntary and Non-voluntary Context Switches.
- Discrete State Simulator (`pcb sim`):
  Traces clock ticks under Round Robin to display exact process lifecycle transitions:
  ```
  New --(admit)--> Ready --(dispatch)--> Running --(finish)--> Terminated
                     ^                      |
                     +---(time slice)-------+
  ```
- Process Subsystem Primitives (`forkdemo`):
  Walkthrough of POSIX process calls: `fork()` memory duplication, `exec()` image overlay, `wait()` status collection, anonymous pipes, zombie process observation (state Z), and signal handling (`SIGTERM`, `SIGINT`).

---

### 3. Deadlock Detection, Prevention and Avoidance (`deadlock.sh` & `bankers.sh`)
- Deadlock Simulation (`deadlock`):
  - Spawns concurrent threads requesting resources in inverted order (T1 takes A then B vs T2 takes B then A).
  - Visualizes the circular wait condition on a Wait-For Graph (WFG): T1 -> Resource B -> T2 -> Resource A -> T1.
  - Demonstrates deadlock prevention strategies:
    1. Lock Ordering (prevents Circular Wait).
    2. Try-Lock Back-off (prevents Hold and Wait).
  - Explains the four Coffman Conditions (Mutual Exclusion, Hold and Wait, No Preemption, Circular Wait).
- Dijkstra's Banker's Algorithm (`bankers`):
  - Maintains state vectors and matrices: Available, Allocation, Max, and derives Need = Max - Allocation.
  - Runs the safety algorithm step-by-step to identify a safe sequence (e.g., <P1, P3, P4, P0, P2>).
  - Evaluates live resource requests, granting resources only if the resulting state remains safe, thereby preventing deadlock proactively.

---

### 4. Virtual Memory and Page Replacement (`memory.sh`)
Simulates page frame allocation and demand paging mechanisms when physical memory frames are saturated:

- Algorithms Implemented:
  - FIFO (First-In, First-Out): Replaces the page resident in memory the longest.
  - LRU (Least Recently Used): Replaces the page unreferenced for the longest elapsed duration.
  - OPT (Belady's Optimal): Theoretical benchmark replacing the page not referenced for the longest interval in the future.
- Belady's Anomaly Demonstration (`memory belady`):
  Empirically proves that increasing allocated frames from 3 to 4 on reference string `1 2 3 4 1 2 5 1 2 3 4 5` increases page faults from 9 to 10 under FIFO, demonstrating why stack algorithms (LRU) are superior.

---

### 5. Kernel Interface and Hardware Monitoring (`sysinfo.sh`)
- Simulated Dual-Mode Switching (`mode-switch`):
  Toggles simulated privilege levels between Ring 3 (User Mode, prompt `>`) and Ring 0 (Kernel Mode, prompt `#`) to illustrate system call traps and privilege separation.
- Hardware and Memory Telemetry (`meminfo`, `kinfo`, `monitor`):
  Displays live RAM allocation bars, CPU utilization sampling from `/proc/stat`, context switch counters, and system uptime.
- System Call Tracing (`trace <cmd>`):
  Attaches `strace` to display underlying syscall requests (`execve`, `openat`, `clone3`, `exit_group`).

---

## Shell Environment Features

RetroOS functions as a full POSIX-compatible command shell:
- Interactive REPL: Command prompt displaying previous command exit status `[st] user@retros path >`.
- Theme Engine: Four color palettes (`cyber`, `retro`, `matrix`, `dracula`) rendered with TrueColor 24-bit ANSI escapes.
- POSIX Compliant: Supports command pipelines (`|`), file descriptors (`>`, `>>`, `<`), logic chains (`&&`, `||`, `;`), background jobs (`&`), and subshells.
- Process and Session Control: Native support for `jobs`, `kill`, `alias`, and `history`.

---

## Directory Structure

```
RetroOS_Shell/
├── .github/
│   └── workflows/ci.yml   # GitHub Actions continuous integration workflow
├── Dockerfile             # Containerized reproducible execution environment
├── retroos.sh             # Main shell entry point and interactive REPL loop
├── run.bat                # Windows 1-click launcher (Git Bash auto-detect)
├── README.md              # Project documentation and academic lab manual
├── test/
│   └── test_all.sh        # Automated CI/CD regression verification test suite
└── lab/
    ├── lib/               # Shared libraries and utilities
    │   ├── ui.sh          # Terminal colors, atomic lock primitives, input parsing
    │   ├── theme.sh       # Prompt builder and theme definitions
    │   └── banner.sh      # Fastfetch-style system banner and responsive layout
    └── modules/           # OS Laboratory Simulation Modules
        ├── sched.sh       # CPU scheduling algorithms and Gantt chart generation
        ├── pcb.sh         # Live /proc PCB reader and tick-by-tick state simulator
        ├── memory.sh      # Page replacement algorithms and Belady's anomaly
        ├── deadlock.sh    # Deadlock simulation, WFG, and Coffman conditions
        ├── bankers.sh     # Dijkstra's Banker's Algorithm (Deadlock avoidance)
        ├── sysinfo.sh     # Memory, CPU monitoring, privilege mode toggle
        ├── forkdemo.sh    # fork, exec, wait, pipe, zombie, and signal demo
        └── demo.sh        # Comprehensive automated laboratory tour
```

---

## Getting Started and Installation

### Option 1: Running on Linux or WSL (Recommended)

**First-Time Setup:**
```bash
# Clone the repository
git clone https://github.com/SaKin32/RetroOS.git
cd RetroOS

# Launch the interactive shell
bash retroos.sh
```

**Automated CI/CD Test Suite:**
```bash
# Execute the full automated regression test suite
bash test/test_all.sh
```

**Automated Demonstration Tour:**
```bash
# Run the automated end-to-end lab demonstration directly
bash retroos.sh -c "demo"
```

### Option 2: Running with Docker (Zero Dependencies)

```bash
# Build the lightweight Docker image
docker build -t retroos .

# Run RetroOS interactively
docker run -it --rm retroos
```

### Option 3: Running on Windows (Git Bash)
- Direct: Double-click `run.bat` in the root directory. It automatically locates Git Bash and initializes the shell.
- Terminal: Open Git Bash inside the project directory and execute `bash retroos.sh`.

---

## Command Reference Cheatsheet

| Category | Command | Description |
| :--- | :--- | :--- |
| Lab Tour | `demo` | Executes an automated 7-part demonstration across all modules |
| CPU Scheduling | `sched rr 2 0:5 1:3 2:8` | Round Robin scheduling with quantum = 2 |
| | `sched compare 0:5 1:3 2:8` | Side-by-side benchmark of FCFS, SJF, Priority, and RR |
| Process Control | `pcb self` | Live PCB analysis of the shell process from `/proc` |
| | `pcb sim 2 0:5 1:3` | Tick-by-tick discrete simulation of process state queues |
| | `forkdemo` | Demonstration of `fork()`, `exec()`, `wait()`, zombies, and signals |
| Deadlock Management | `deadlock` | Circular wait simulation, lock ordering, and back-off fixes |
| | `bankers` | Interactive Banker's algorithm and safe sequence finder |
| Memory Management | `memory lru 3 7 0 1 2 0 3` | LRU Page replacement simulation with 3 frames |
| | `memory belady` | Demonstrates Belady's Anomaly in FIFO (3 vs 4 frames) |
| | `memory compare 3 ...` | Side-by-side comparison of FIFO, LRU, and OPT |
| Kernel and Telemetry | `meminfo` | Displays RAM allocation and disk caching statistics |
| | `monitor 5` | Live CPU and Memory usage bars (5 refreshes) |
| | `mode-switch` | Simulates privilege transition between Ring 3 and Ring 0 |
| | `trace ls` | Traces system calls using `strace` |
| Shell Configuration | `theme <cyber\|retro\|...>`| Changes the active shell color theme |
| | `user <name>` | Sets custom username for prompt and state |
| | `help` | Displays built-in command documentation |

---

## Academic Metadata
- Course: CSE210 - Operating Systems
- Project Title: RetroOS Shell - Interactive OS Lab in Bash
- Description: Interactive Unix Shell and Operating System Laboratory Simulation Suite.
