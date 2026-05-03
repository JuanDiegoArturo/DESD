# Digital Electronic System Design - Group Project
Final delivery: 7-June 

## Workload split (23 pts)

0. Common (3 pts)
    - AXIS handling (2 pts)
    - Clock frequency (1 pt)

### Path 1
1. Person A (4 pts)
    - Float compressor (2.5 pts)
    - Generic in float compressor (0.5 pts)
    - Binary to decimal (1 pt)

2. Person B (4 pts)
    - Depacketizer (1.5 pts)
    - Send controller (1 pt)
    - 7 Segment controller (0.5 pts)
    - Reports (1 pt)

### Path 2
3. Person C (4.5 pts)
    - Reverb (2 pts)
    - Effect selector (0.5 pts)
    - Volume (2 pts)

4. Person D (4 pts)
    - Moving average (2 pts)
    - Led level controller (1 pt)
    - Balance (1 pt)

5. Person E (3.5 pts)
    - Output selector (2 pts)
    - Digilent JSTK2 (1.5 pts)

## To do  
-  Ask for missing files:
    - delay.vhd
    - bram_controller.vhd
    - division_lut.vhd
    - volume_multiplier.vhd
    - volume_saturator.vhd
    - edge_detector_trigger.vhd

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


