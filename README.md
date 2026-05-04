# Digital Electronic System Design - Group Project
Final delivery: 7-June 

## To do  

## Green blocks / encripted files
- delay.vhd
- bram_controller.vhd
- division_lut.vhd
- volume_multiplier.vhd
- volume_saturator.vhd
- edge_detector_trigger.vhd

## Xilinx catalog IPs
- axis_fifo.vhd
- axis_dwidth_converter
- axis_broadcaster
- clk_wiz
- proc_sys_reset

## Workload split (23 pts)

0. Common (3 pts)
    - AXIS handling (2 pts)
    - Clock frequency (1 pt)

### Path 1
1. Juan Camilo (6 pts)
    - Float compressor (2.5 pts)
    - Generic in float compressor (0.5 pts)
    - Depacketizer (1.5 pts)
    - Send controller (1 pt)
    - 7 Segment controller (0.5 pts)    

### Path 2
2. Juan Diego (5 pts)
    - Reverb (2 pts)
    - Volume (2 pts)
    - Binary to decimal (1 pt)

3. Jesus & Markel (5 pts)
    - Moving average (2 pts)
    - Led level controller (1 pt)
    - Balance (1 pt)
    - Reports (1 pt)

4. Sara (4 pts)
    - Output selector (2 pts)
    - Effect selector (0.5 pts)
    - Digilent JSTK2 (1.5 pts)

## How to rebuild vivado projects
1. **Open the Vivado Tcl Shell** from the Start menu:
   ```
   Xilinx Design Tools → Vivado 2020.2 → Vivado 2020.2 Tcl Shell
   ```

2. **Navigate to the cloned repo folder** in the Tcl Shell:
   ```tcl
   cd C:/path/to/lab_solution
   ```

3. **Run the build script:**
   ```tcl
   source build.tcl
   ```

4. Vivado will automatically recreate the project, import all sources and IPs, and restore the block design. When it finishes, the project can be opened normally in the Vivado GUI.

## How to generate the build.tcl

1. Open the project in Vivado
2. Go to **File → Write Project to Tcl**
3. Set the output path to your repo root
4. Select the following options:
   - ✅ **Copy sources to new project** — ensures all sources are bundled
   - ☐ Write all properties — leave unchecked
   - ☐ Recreate Block Designs using Tcl — leave unchecked
   - ☐ Write object values — leave unchecked
   - ☐ Ignore command errors — leave unchecked
5. Click **OK**