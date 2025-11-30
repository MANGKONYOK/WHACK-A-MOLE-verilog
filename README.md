# 🐹 Whack-a-Mole FPGA (Basys 3)

> **CPE 222 Digital Electronics and Logic Design Project** - A reaction-based game implemented on the Digilent Basys 3 Artix-7 FPGA board using Verilog HDL.

## 👥 Team Members
* **Panjapon Poobancheun** (ID: 67070503423)
* **Sorawit Chaithong** (ID: 67070503442)
* **Kittiphat Noikate** (ID: 67070503459)
* **Piti Srisongkram** (ID: 67070503467)

## 🎮 Project Overview
This project simulates the classic **Whack-a-Mole** arcade game completely in digital logic hardware. The system tests the player's reaction time by lighting up random LEDs (moles), which must be *hit* by toggling the corresponding switches (hammers) within a time limit.

### Key Features
* **Real-time Logic:** Zero-latency response using FPGA hardware parallel processing.
* **Randomized Gameplay:** Uses Linear Feedback Shift Register (LFSR) for unpredictable mole patterns.
* **Dynamic Scoring and Timing:** Score and time tracking displayed on 4-digit 7-Segment displays.

## 🛠 Architecture & Modules

The project is structured into modular Verilog files for ease of testing and integration.

| Module Name | File Name | Description |
| :--- | :--- | :--- |
| **Top Module** | `top_module.v` | Connects all sub-modules and maps I/O ports. |
| **Clock Divider** | `clk_divider.v` | Down-scales 100MHz clock to 1kHz (Display) and 1Hz (Game Timer). |
| **Game FSM** | `game_fsm.v` | The brain of the system. Controls states: IDLE, PLAY, GAME OVER. |
| **Mole Generator** | `mole_gen.v` | Contains LFSR (Linear Feedback Shift Register) and Mole Timer logic. |
| **Hit Detector** | `hit_detect.v` | Compares Switch Input vs LED Output. |
| **Input Handler** | `input_sync.v` | Debounces buttons and synchronizes switch inputs. |
| **Display Driver** | `seven_seg.v` | Multiplexes the 4-digit 7-segment display for score and time output. |

## 🔌 Pin Mapping (Basys 3 Constraint)

> **Note for Team:** Always check `constraints.xdc` before testing on hardware.

### Inputs
* **CLK:** `W5` (100 MHz System Clock)
* **Reset / Start:** `U18` (Center Button - BTNC)
* **Hammers (9-Switches):**
    * `SW[0]` to `SW[8]`

### Outputs
* **Moles (LEDs):**
    * `LED[0]` to `LED[8]`
* **Scoreboard & Time Countdown (7-Segment):**
    * `score_out[1:0]`
    * `time_out[1:0]`
    * `seg[6:0]` (A-G)

## 🚀 How to Develop (Workflow)

Since we have **one board** but **4 members**, we follow the **"Simulation First"** workflow:

1.**Clone the Repo:** `git clone <repo_url> `               
2.**Code in VS Code:** Use Verilog extensions for syntax highlighting.\
3.**Simulate:**
* Open **Vivado** (or EDA Playground).
* Add your `.v` file and its corresponding `_tb.v` (Testbench).
* Run Behavioral Simulation. **Verify the waveform first!**         
4.**Push:** Only push code that compiles and simulates correctly.  
5.**Hardware Test:** The hardware lead pulls the latest code to generate bitstream (`.bit`) and tests on Basys 3.

### 📝 Notes
* *Please do not push the entire Vivado project folder (`.xpr`, `.log`, `.jou`). Only push Source (`src/`) and Constraints (`const/`).*

### 🗃️ Module Structure

__WHACK-A-MOLE__
```
top_module.v            (Top level: Link every modules)
│
├── clk_divider.v       (Clock management: Hz convert)
│
├── input_sync.v        (Input Handler: Debounce button and Synchronize switch)
│
├── game_fsm.v          (Game Brain: Control State (IDLE / PLAY / GAME OVER))
│
├── mole_gen.v          (Mole Generator: Random a moles)
│   ├── lfsr_core       (Random with Linear Feedback Shift Register)
│   └── mole_timer      (Countdown each of moles)
│
├── hit_detect.v        (Collision Check: Compare a position Switch vs LED)
│
└── seven_seg.v         (Display Controller: Display scoreboard & timing)
    ├── bin_to_bcd      (Convert binary to decimal)
    └── segment_mux     (Switch display)
```