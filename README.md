# 4-bit Array Multiplier: RTL to GDSII (SkyWater SKY130, open-source flow)

Digital VLSI Design (DVD) assignment, team of two. Submitted to Prof. Zia Abbas.

| Team member | Roll number |
|---|---|
| Dheerendra Singh | 2026203017 |
| Nandish P | 2026203002 |

Design: 4-bit x 4-bit unsigned array multiplier (8-bit product), 16 AND gates, 12 `full_adder` instances, 16 flip-flops, latency of 2 clock cycles.
Technology: SkyWater SKY130 (130 nm), standard cell library `sky130_fd_sc_hd`.

## Repository structure

```
mult4_2026203017/
|-- README.md
|-- .gitignore               (mult.vcd, sim, gls, runs/ are not committed)
|-- rtl/
|   |-- full_adder.v
|   `-- mult_array.v
|-- tb/
|   `-- tb_mult.v
|-- synth/
|   |-- synth.tcl
|   |-- mult_array_netlist.v (generated)
|   `-- mult_array_stat.rpt  (generated)
|-- sta/
|   |-- sta.tcl
|   `-- mult_array_timing.rpt (generated, T = 2.59 ns)
|-- pnr/
|   |-- config.json
|   |-- metrics.json          (copied from the final run)
|   `-- mult_array.gds        (copied from the final run)
`-- report/
    `-- report.pdf
```

## Environment

Everything ran in the IIC-OSIC-TOOLS Docker image (`hpretl/iic-osic-tools`), PDK `sky130A`.

| Tool | Version |
|---|---|
| Icarus Verilog | 14.0 (devel) |
| Yosys | 0.69 |
| OpenSTA | 3.1.0 |
| LibreLane | v3.1.0.dev3 |
| KLayout | 0.30.12 |

The project folder `C:\Users\DS BAIS\eda\designs\mult4_2026203017` on Windows is `/foss/designs/mult4_2026203017` inside the container.

## Commands, in the order they were run

### Step 0: Start the container (Windows PowerShell)

```powershell
git clone --depth=1 https://github.com/iic-jku/iic-osic-tools.git
cd "C:\Users\DS BAIS\iic-osic-tools"
.\start_vnc.bat
docker start iic-osic-tools_xvnc
```

The container already existed (status "exited"), so it was restarted with `docker start`. The desktop is opened in a browser at `http://localhost/?password=abc123`, and all following commands run in the terminal of that desktop.

### Step 1: Check tools and select the PDK (container terminal)

The PDK must be selected again in every new terminal.

```bash
iverilog -V | head -1
yosys -V
sta -version
librelane --version
sak-pdk sky130A
echo $PDK_ROOT $PDK
cd /foss/designs/mult4_2026203017
mkdir -p rtl tb synth sta pnr report
```

### Part A: RTL simulation and error test

```bash
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim
```

Result: `PASS: 256 vectors checked, 0 errors`.

Error test (`sum` temporarily changed to `a^b`, then restored):

```bash
sed -i 's/a^b^cin/a^b/' rtl/full_adder.v
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim | grep -E "PASS|FAIL"
sed -i 's/a^b;/a^b^cin;/' rtl/full_adder.v
cat rtl/full_adder.v
iverilog -g2012 -o sim tb/tb_mult.v rtl/full_adder.v rtl/mult_array.v
vvp sim | grep -E "PASS|FAIL"
```

Result with the error: `FAIL: 256 vectors checked, 95 errors`. After restoring: `PASS: 256 vectors checked, 0 errors`.

Waveform:

```bash
gtkwave mult.vcd
```

Example (roll number 2026203017, last digit 7): A = 7 + 5 = 12 (1100), B = 7 (0111), product 84 (01010100). The inputs are applied at 6000 ns and the product 84 appears at the second rising clock edge, at 6015 ns.

### Part B: Logic synthesis and netlist simulation

```bash
yosys -c synth/synth.tcl
cat synth/mult_array_stat.rpt
CELLS=$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/verilog
iverilog -g2012 -DFUNCTIONAL -DUNIT_DELAY=#1 -o gls tb/tb_mult.v $CELLS/primitives.v $CELLS/sky130_fd_sc_hd.v synth/mult_array_netlist.v
vvp gls | grep -E "PASS|FAIL"
```

Result: `PASS: 256 vectors checked, 0 errors` on the synthesized netlist.

### Part C: Static timing analysis

`sta/sta.tcl` takes the clock period from the environment variable `CLK_PERIOD` (default 2.59 ns).

```bash
CLK_PERIOD=10 sta -exit sta/sta.tcl
CLK_PERIOD=2.59 sta -exit sta/sta.tcl
cat sta/mult_array_timing.rpt
```

At T = 10 ns the worst slack is 7.415 ns (printed as 7.42), so T_min = 10 - 7.415 = 2.585 ns, rounded to 2.59 ns. At T = 2.59 ns the slack is +0.005 ns. The committed `mult_array_timing.rpt` is the report of the T = 2.59 ns run.

### Part D: Place and route (LibreLane)

The flow was run three times. After each failed run, `CLOCK_PERIOD` in `pnr/config.json` was raised.

```bash
cd /foss/designs/mult4_2026203017/pnr

# Attempt 1: CLOCK_PERIOD = 3.5 ns (1.2 x 2.59 ns, rounded up to the next 0.5 ns)
librelane config.json 2>&1 | tee /tmp/run1.log
ls runs
R=runs/RUN_2026-10-23_14-26-28/final
grep -E "setup__ws|setup_vio|drc_errors|lvs_error" $R/metrics.json

# Attempt 2: CLOCK_PERIOD = 6.0 ns
sed -i -E 's/"CLOCK_PERIOD": [0-9.]+/"CLOCK_PERIOD": 6.0/' config.json
grep CLOCK_PERIOD config.json
librelane config.json 2>&1 | tee /tmp/run2.log
ls runs
R=runs/RUN_2026-10-23_14-47-42/final
grep -E "setup__ws\": |setup_vio_count\": |drc_error|lvs_error" $R/metrics.json

# Attempt 3: CLOCK_PERIOD = 6.5 ns (final)
sed -i -E 's/"CLOCK_PERIOD": [0-9.]+/"CLOCK_PERIOD": 6.5/' config.json
grep CLOCK_PERIOD config.json
librelane config.json 2>&1 | tee /tmp/run3.log
ls runs
R=runs/RUN_2026-10-23_15-13-05/final
grep -E "setup__ws\": |hold__ws\": |drc_error|lvs_error|route__wirelength\": |design__core__area|design__die__area" $R/metrics.json
grep -E "instance__count|instance__area\"" $R/metrics.json
grep -E "core__area|core__bbox" $R/metrics.json

# Copy the deliverables of the final run and view the layout
cp $R/metrics.json .
cp $R/gds/mult_array.gds .
ls
klayout mult_array.gds &
```

#### LibreLane attempts

| Attempt | CLOCK_PERIOD | Run folder | Worst setup slack | DRC / LVS | Outcome |
|---|---|---|---|---|---|
| 1 | 3.5 ns | `RUN_2026-10-23_14-26-28` | -2.050 ns | 0 / 0 | failed: setup violations in `ss_100C_1v60` |
| 2 | 6.0 ns | `RUN_2026-10-23_14-47-42` | -0.119 ns | 0 / 0 | failed: setup violations in `ss_100C_1v60` |
| 3 | 6.5 ns | `RUN_2026-10-23_15-13-05` | +1.519 ns | 0 / 0 | passed |

### Git (Windows PowerShell, in the project folder)

```powershell
cd "C:\Users\DS BAIS\eda\designs\mult4_2026203017"
git init -b main
git config user.name "Dheerendra Singh"
git config user.email "<email>"
git remote add origin <repository-url>

git add .gitignore rtl tb
git commit -m "Part A: full_adder, mult_array, exhaustive testbench (256 vectors PASS)"
git add synth
git commit -m "Part B: Yosys synthesis script, netlist and stat report"
git add sta
git commit -m "Part C: OpenSTA script and timing report at T=2.59 ns"
git push -u origin main

git add pnr/config.json pnr/metrics.json pnr/mult_array.gds
git commit -m "Part D: LibreLane run at 6.5 ns, DRC 0, LVS 0, setup slack +1.52 ns"
git push

git add README.md report/report.pdf
git commit -m "Add README and report"
git push
```

The `runs/` folder of LibreLane is not committed (see `.gitignore`).

## Results summary

### Part B: synthesis (Yosys, typical corner)

| Metric | Value |
|---|---|
| Total number of cells | 65 |
| Number of flip-flops (`dfrtp_1`) | 16 |
| Total cell area | 746.966 um^2 |
| Flip-flop area | 400.384 um^2 |
| Flip-flop area (% of total) | 53.60 % |
| 3 most-used cell types | `dfrtp_1` x 16, `nand2_1` x 12, `xnor2_1` x 5 |
| Netlist simulation result | PASS: 256 vectors checked, 0 errors |

### Part C: static timing analysis (OpenSTA, typical corner)

| Metric | Value |
|---|---|
| Worst slack at T = 10 ns | 7.415 ns |
| T_min | 2.59 ns |
| F_max | 386 MHz |
| Slack at T = T_min | +0.005 ns |
| Critical path start point | `_102_` (input register `b_reg[0]`) |
| Critical path end point | `_096_` (output register `p[6]`) |
| Number of cells on the critical path | 8 logic cells (10 including the two flip-flops) |
| Latency (2 x T_min) | 5.18 ns |
| Throughput | 386 million results/s |

### Part D: physical design (LibreLane, final run)

| Metric | Value |
|---|---|
| CLOCK_PERIOD used | 6.5 ns |
| Number of runs needed | 3 |
| Core area | 16199 um^2 (die 22500 um^2) |
| Cells after synthesis (Part B) | 65 |
| Cells after place and route | 1317 (114 excluding fill cells) |
| Kinds of cells added | 35 timing-repair buffers (16 hold buffers), 5 clock buffers, 1203 fill cells |
| Wirelength | 2803 um |
| Setup slack | +1.519 ns |
| Post-route F_max = 1000 / (6.5 - 1.519) | 200.8 MHz |
| F_max from Part C | 386 MHz |
| DRC errors | 0 |
| LVS errors | 0 |

The report with all figures and the answers to Questions 1-6 is in `report/report.pdf`.
