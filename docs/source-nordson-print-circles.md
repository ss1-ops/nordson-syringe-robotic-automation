# Nordson ProPlus4 Syringe Printer Program: Circular Bit Patterns

This document outlines the logical flow and implementation for automating the printing of circular patterns (bits) on tags using a Nordson ProPlus4 syringe printer. The setup includes 8 tags in a 4x2 grid (2 columns, 4 rows, numbered vertically), with up to 10 circular bits per tag. The program is driven by a .src file, responding to PLC inputs via 8 channels. Fiducial checks are performed once per tag using **Fiducial Mark**, and **Output** commands control signals. Bit values 11–15 are ignored, and the program starts via a 200ms Run Pulse on Channel 8 through the Nordson UI.

## Logical Flow

### Program Start
1. **Run Pulse Trigger**:
   - A 200ms Run Pulse on **Channel 8** (PLC output `_IO_P1_DO_00` mapped to `RunPulse`) triggers the program when open in the Nordson UI.
   - No initialization or **Stop Point** command is required, as the Run Pulse directly initiates execution.

### Step 1: Read Position Bits (Channels 5–7)
2. **Check Position Bits**:
   - Read **Channels 5–7** (Position Bits 0–2, mapped to PLC outputs `_IO_EM_DO_04`, `_IO_EM_DO_05`, `_IO_EM_DO_06` as `PositionBit0`, `PositionBit1`, `PositionBit2`).
   - Interpret as a 3-bit binary number (0–7) to select the tag in the 4x2 grid (2 columns, 4 rows, numbered vertically top to bottom, left to right):
     - 000 (0): Tag 1 ([1,1])
     - 001 (1): Tag 2 ([2,1])
     - 010 (2): Tag 3 ([3,1])
     - 011 (3): Tag 4 ([4,1])
     - 100 (4): Tag 5 ([1,2])
     - 101 (5): Tag 6 ([2,2])
     - 110 (6): Tag 7 ([3,2])
     - 111 (7): Tag 8 ([4,2])
   - **Commands**: Use **Set** and **Var** to compute the binary value into `tag_pos`. Use **Jump Label** to branch to the tag’s fiducial check.

### Step 2: Fiducial Check for Selected Tag
3. **Perform Fiducial Check**:
   - Move to predefined fiducial locations for the selected tag.
   - Use **Fiducial Mark** to verify tag position, compensating for placement inaccuracies.
   - Store adjusted coordinates (X, Y, Z) in variables using **Var** for all bit prints on this tag.
   - **Commands**: Execute **Fiducial Mark**, followed by **Var** to store coordinates. Performed once per tag.

### Step 3: Read Print Bits (Channels 1–4)
4. **Check Print Bits**:
   - Read **Channels 1–4** (Bit1–Bit4, mapped to PLC outputs `_IO_EM_DO_00`–`_IO_EM_DO_03` as `Bit1`–`Bit4`).
   - Interpret as a 4-bit binary number (0–15) to determine the bit to print:
     - 0000 (0): Tag Complete (no bit)
     - 0001 (1): Bit 1 (circle)
     - 0010 (2): Bit 2 (circle)
     - 0011 (3): Bit 3 (circle)
     - 0100 (4): Bit 4 (circle)
     - 0101 (5): Bit 5 (circle)
     - 0110 (6): Bit 6 (circle)
     - 0111 (7): Bit 7 (circle)
     - 1000 (8): Bit 8 (circle)
     - 1001 (9): Bit 9 (circle)
     - 1010 (10): Bit 10 (circle)
     - 1011–1111 (11–15): Ignored
   - **Commands**: Use **Set** and **Var** to compute the binary value into `bit_num`. Use **Jump Label** to branch to the bit’s circle pattern, **End Program** if `bit_num` is 0, or back to bit check if `bit_num` is 11–15.

### Step 4: Print the Circular Bit or End Program
5. **Handle Bit Printing**:
   - **If `bit_num` = 0 (0000)**:
     - Tag complete; execute **End Program** to reset and wait for the next Run Pulse.
   - **If `bit_num` = 1–10**:
     - Move to the bit’s center coordinates, adjusted by the fiducial offset.
     - Print a circular pattern using **Arc Point** commands to define the circle.
   - **If `bit_num` = 11–15**:
     - Ignore and jump back to Step 3.
   - **Commands**: Use **Line Dispense Setup** for dispensing parameters, followed by **Line Start**, **Arc Point**, and **Line End** to draw a circle at the bit’s coordinates.

### Step 5: UV Curing (if Bit Printed)
6. **Move to UV Curing Position**:
   - After printing a circle (`bit_num` = 1–10), move to a specific curing position for the selected tag.
   - **Command**: Use **Point** to move to the curing position.
7. **Activate UV Curing Signal**:
   - Set **Channel 2** (PLC input `_IO_EM_DO_01` as `Bit2`) to HIGH (1) for 5 seconds to trigger UV curing.
   - Set Channel 2 to LOW (0) after 5 seconds.
   - **Commands**: Use **Output** to set Channel 2 to 1, **Wait Point** for 5 seconds, then **Output** to set Channel 2 to 0.

### Step 6: Signal Completion to PLC
8. **Signal Bit Completion**:
   - Set **Channel 1** (PLC input `_IO_EM_DO_00` as `Bit1`) to HIGH (1) for 1 second, then LOW (0), to signal completion of printing and curing.
   - **Commands**: Use **Output** to set Channel 1 to 1, **Wait Point** for 1 second, then **Output** to set Channel 1 to 0.

### Step 7: Loop for Next Bit on Same Tag
9. **Return to Bit Check**:
   - Jump to Step 3 to check Channels 1–4 for the next bit on the same tag, skipping position and fiducial checks.
   - **Command**: Use **Jump Label** to return to the bit-checking binary tree.

### Program Reset
10. **End Program**:
    - When `bit_num` = 0, **End Program** resets the Nordson to wait for a new Run Pulse.
    - The PLC updates Channels 1–4 for the next bit/tag and sends a new Run Pulse.

## Logical Flow Diagram
```plaintext
[Program Start: Triggered by Run Pulse on Channel 8]
        ↓
[Step 1: Read Channels 5–7 (Position Bits)]
        ↓ (Calculate tag_pos: 0–7)
[Step 2: Fiducial Mark for Tag at tag_pos]
        ↓ (Store fiducial-adjusted coordinates)
[Step 3: Read Channels 1–4 (Print Bits)]
        ↓ (Calculate bit_num: 0–15)
[Step 4: Check bit_num]
    ↓
    +→ [bit_num = 0] → [End Program] → [Wait for next Run Pulse]
    +→ [bit_num = 11–15] → [Jump to Step 3]
    +→ [bit_num = 1–10]
        ↓
[Step 5: Print Circular Pattern for bit_num]
        ↓
[Step 6: Move to UV Curing Position]
        ↓
[Step 7: Output Channel 2 = 1 for 5s, then 0]
        ↓
[Step 8: Output Channel 1 = 1 for 1s, then 0]
        ↓
[Step 9: Jump to Step 3 (Read Print Bits)]
```

## Key Nordson Commands
- **Set/Var**: Compute binary values for `tag_pos` and `bit_num`.
- **Jump Label**: Implement binary tree and loop logic.
- **Fiducial Mark**: Verify tag position (once per tag).
- **Line Dispense Setup/Line Start/Arc Point/Line End**: Print circular patterns.
- **Point**: Move to UV curing position.
- **Output**: Control Channels 2 (UV) and 1 (completion).
- **Wait Point**: Implement 5-second (UV) and 1-second (completion) delays.
- **End Program**: Reset program.

## Notes and Assumptions
- **Channel Mapping**: `_IO_EM_DO_00`–`_IO_EM_DO_03` map to Channels 1–4 (Bit1–Bit4), `_IO_EM_DO_04`–`_IO_EM_DO_06` map to Channels 5–7 (PositionBit0–2), `_IO_P1_DO_00` maps to Channel 8 (RunPulse).
- **Tag Spacing**: Tags are arranged in a 4x2 grid with 80mm vertical y offset between tags within each column (e.g., Tag 1 to Tag 2, Tag 2 to Tag 3, etc.) and 120mm x offset between columns (e.g., Tag 1 to Tag 5).
- **Fiducial Check**: Each tag has two fiducial locations; **Fiducial Mark** adjusts coordinates.
- **Circular Patterns**: Each bit is a circle with a fixed radius (e.g., 1mm), centered at unique coordinates relative to the tag. Uses three **Arc Point** commands to approximate a circle.
- **UV Curing Position**: Specific coordinates are used for each tag, derived from the first fiducial with an offset of (-145.8, 20.5, -7.989).
- **Bit Values 11–15**: Ignored by jumping back to bit check.
- **PLC Coordination**: PLC updates Channels 1–4 after Channel 1 signal and sends Run Pulse for next tag.
- **Program Trigger**: Run Pulse starts the program via Nordson UI.

## Nordson .src File Implementation
Below is the .src file implementing the flow. Fiducial coordinates are specified for each tag, and bit centers (e.g., tag_x+1, tag_y+1 for Bit 1) are relative to the fiducial-adjusted coordinates. Circular patterns are approximated using three **Arc Point** commands with a 1mm radius. Adjust dispensing parameters (e.g., pressure, speed) based on your setup.

```plaintext
Z Clearance Setup 5 1  ; 5mm relative clearance
Set tag_pos 0
Var tag_pos (Channel5*4 + Channel6*2 + Channel7*1)  ; Position Bits (0–7)
Jump Label Tag[tag_pos]

[Tag0]  ; Tag 1 ([1,1], 000)
Fiducial Mark 157 57 30.989 11  ; First fiducial
Fiducial Mark 207 57 30.989 12  ; Second fiducial
Var tag_x adjusted_x
Var tag_y adjusted_y
Var tag_z adjusted_z
Jump Label BitCheck

[Tag1]  ; Tag 2 ([2,1], 001)
Fiducial Mark 157 137 30.989 13
Fiducial Mark 207 137 30.989 14
Var tag_x adjusted_x
Var tag_y adjusted_y
Var tag_z adjusted_z
Jump Label BitCheck

[Tag2]  ; Tag 3 ([3,1], 010)
Fiducial Mark 157 217 30.989 15
Fiducial Mark 207 217 30.989 16
Var tag_x adjusted_x
Var tag_y adjusted_y
Var tag_z adjusted_z
Jump Label BitCheck

[Tag3]  ; Tag 4 ([4,1], 011)
Fiducial Mark 157 297 30.989 17
Fiducial Mark 207 297 30.989 18
Var tag_x adjusted_x
Var tag_y adjusted_y
Var tag_z adjusted_z
Jump Label BitCheck

[Tag4]  ; Tag 5 ([1,2], 100)
Fiducial Mark 277 57 30.989 19
Fiducial Mark 327 57 30.989 20
Var tag_x adjusted_x
Var tag_y adjusted_y
Var tag_z adjusted_z
Jump Label BitCheck

[Tag5]  ; Tag 6 ([2,2], 101)
Fiducial Mark 277 137 30.989 21
Fiducial Mark 327 137 30.989 22
Var tag_x adjusted_x
Var tag_y adjusted_y
Var tag_z adjusted_z
Jump Label BitCheck

[Tag6]  ; Tag 7 ([3,2], 110)
Fiducial Mark 277 217 30.989 23
Fiducial Mark 327 217 30.989 24
Var tag_x adjusted_x
Var tag_y adjusted_y
Var tag_z adjusted_z
Jump Label BitCheck

[Tag7]  ; Tag 8 ([4,2], 111)
Fiducial Mark 277 297 30.989 25
Fiducial Mark 327 297 30.989 26
Var tag_x adjusted_x
Var tag_y adjusted_y
Var tag_z adjusted_z
Jump Label BitCheck

[BitCheck]
Set bit_num 0
Var bit_num (Channel1*8 + Channel2*4 + Channel3*2 + Channel4*1)  ; Bit number (0–15)
Jump Label Bit[bit_num]

[Bit0]  ; Tag Complete
End Program

[Bit1]  ; Bit 1 (Circle)
Line Dispense Setup 0.2 0 0 0 0.1 0.1  ; Example parameters
Line Start tag_x+1 tag_y+1 tag_z
Arc Point tag_x+2 tag_y+1 tag_z
Arc Point tag_x+1 tag_y+2 tag_z
Arc Point tag_x+0 tag_y+1 tag_z
Line End tag_x+1 tag_y+1 tag_z
Jump Label Cure

[Bit2]  ; Bit 2
Line Dispense Setup 0.2 0 0 0 0.1 0.1
Line Start tag_x+2 tag_y+1 tag_z
Arc Point tag_x+3 tag_y+1 tag_z
Arc Point tag_x+2 tag_y+2 tag_z
Arc Point tag_x+1 tag_y+1 tag_z
Line End tag_x+2 tag_y+1 tag_z
Jump Label Cure

[Bit3]  ; Bit 3
Line Dispense Setup 0.2 0 0 0 0.1 0.1
Line Start tag_x+3 tag_y+1 tag_z
Arc Point tag_x+4 tag_y+1 tag_z
Arc Point tag_x+3 tag_y+2 tag_z
Arc Point tag_x+2 tag_y+1 tag_z
Line End tag_x+3 tag_y+1 tag_z
Jump Label Cure

[Bit4]  ; Bit 4
Line Dispense Setup 0.2 0 0 0 0.1 0.1
Line Start tag_x+4 tag_y+1 tag_z
Arc Point tag_x+5 tag_y+1 tag_z
Arc Point tag_x+4 tag_y+2 tag_z
Arc Point tag_x+3 tag_y+1 tag_z
Line End tag_x+4 tag_y+1 tag_z
Jump Label Cure

[Bit5]  ; Bit 5
Line Dispense Setup 0.2 0 0 0 0.1 0.1
Line Start tag_x+5 tag_y+1 tag_z
Arc Point tag_x+6 tag_y+1 tag_z
Arc Point tag_x+5 tag_y+2 tag_z
Arc Point tag_x+4 tag_y+1 tag_z
Line End tag_x+5 tag_y+1 tag_z
Jump Label Cure

[Bit6]  ; Bit 6
Line Dispense Setup 0.2 0 0 0 0.1 0.1
Line Start tag_x+6 tag_y+1 tag_z
Arc Point tag_x+7 tag_y+1 tag_z
Arc Point tag_x+6 tag_y+2 tag_z
Arc Point tag_x+5 tag_y+1 tag_z
Line End tag_x+6 tag_y+1 tag_z
Jump Label Cure

[Bit7]  ; Bit 7
Line Dispense Setup 0.2 0 0 0 0.1 0.1
Line Start tag_x+7 tag_y+1 tag_z
Arc Point tag_x+8 tag_y+1 tag_z
Arc Point tag_x+7 tag_y+2 tag_z
Arc Point tag_x+6 tag_y+1 tag_z
Line End tag_x+7 tag_y+1 tag_z
Jump Label Cure

[Bit8]  ; Bit 8
Line Dispense Setup 0.2 0 0 0 0.1 0.1
Line Start tag_x+8 tag_y+1 tag_z
Arc Point tag_x+9 tag_y+1 tag_z
Arc Point tag_x+8 tag_y+2 tag_z
Arc Point tag_x+7 tag_y+1 tag_z
Line End tag_x+8 tag_y+1 tag_z
Jump Label Cure

[Bit9]  ; Bit 9
Line Dispense Setup 0.2 0 0 0 0.1 0.1
Line Start tag_x+9 tag_y+1 tag_z
Arc Point tag_x+10 tag_y+1 tag_z
Arc Point tag_x+9 tag_y+2 tag_z
Arc Point tag_x+8 tag_y+1 tag_z
Line End tag_x+9 tag_y+1 tag_z
Jump Label Cure

[Bit10]  ; Bit 10
Line Dispense Setup 0.2 0 0 0 0.1 0.1
Line Start tag_x+10 tag_y+1 tag_z
Arc Point tag_x+11 tag_y+1 tag_z
Arc Point tag_x+10 tag_y+2 tag_z
Arc Point tag_x+9 tag_y+1 tag_z
Line End tag_x+10 tag_y+1 tag_z
Jump Label Cure

[Bit11]  ; Ignored
Jump Label BitCheck

[Bit12]  ; Ignored
Jump Label BitCheck

[Bit13]  ; Ignored
Jump Label BitCheck

[Bit14]  ; Ignored
Jump Label BitCheck

[Bit15]  ; Ignored
Jump Label BitCheck

[Cure]
Point 11.2 77.5 23  ; UV curing position for Tag 1
Point 11.2 157.5 23  ; UV curing position for Tag 2
Point 11.2 237.5 23  ; UV curing position for Tag 3
Point 11.2 317.5 23  ; UV curing position for Tag 4
Point 131.2 77.5 23  ; UV curing position for Tag 5
Point 131.2 157.5 23  ; UV curing position for Tag 6
Point 131.2 237.5 23  ; UV curing position for Tag 7
Point 131.2 317.5 23  ; UV curing position for Tag 8
Output 2 1  ; Channel 2 HIGH
Wait Point 5
Output 2 0  ; Channel 2 LOW
Output 1 1  ; Channel 1 HIGH
Wait Point 1
Output 1 0  ; Channel 1 LOW
Jump Label BitCheck
```

## Implementation Notes
- **Coordinates**: Fiducial coordinates are specified for each tag based on an 80mm vertical y offset within columns and a 120mm x offset between columns. Bit centers (e.g., tag_x+1, tag_y+1) are relative to fiducial-adjusted coordinates.
- **Circle Radius**: The circle is approximated with a 1mm radius using three **Arc Point** commands. Adjust coordinates for desired radius or add more **Arc Point** commands for smoother circles.
- **Dispensing Parameters**: **Line Dispense Setup** parameters (e.g., 0.2s, 0) are placeholders. Configure based on material and syringe settings.
- **Channel Syntax**: **Output** command uses `Output <port> <state>` (e.g., `Output 2 1` for Channel 2 HIGH). Verify compatibility with your Nordson firmware.
- **Jump Label**: The **Jump Label** command is used in this pseudocode to represent branching logic. In the actual Nordson system, this may need to be implemented using **Call Subroutine** or another flow control mechanism supported by the firmware, as **Jump Label** is not a defined command in the Nordson command reference.
- **Testing**: Validate fiducial coordinates, UV curing positions, circle patterns, and timing (5s UV, 1s completion signal) in a test run.

This program ensures efficient printing of circular patterns, with fiducial checks only once per tag, and proper coordination with the PLC. For further assistance, provide specific dispensing parameters or additional firmware details for a tailored .src file.