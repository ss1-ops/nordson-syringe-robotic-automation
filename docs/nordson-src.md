# Nordson ProPlus4 .SRC Program

The printer has no network capability. All coordination happens through its 8 digital I/O channels using a binary tree of Input/Label/Call Subroutine commands. The PLC drives the "address" (which tag + which dot), the Nordson executes the motion and dispense, then signals completion back.

## High-Level Program Flow (8-up version)
1. Z Clearance and Line Dispense Setup (global parameters for the job).
2. Read position bits (Ch5–7) into `tag_pos` via Var + arithmetic.
3. Jump to the Tag[label] subroutine for that position (0–7).
4. Inside tag subroutine:
   - Two **Fiducial Mark** commands (primary + secondary) to compensate for substrate placement error on the FR4.
   - Store adjusted `tag_x`, `tag_y`, `tag_z`.
   - Call into BitCheck subroutine.
5. BitCheck:
   - Read bits (Ch1–4) into `bit_num`.
   - Jump to Bit[label].
6. Bit 0 → **End Program** (tag complete, wait for next Run Pulse).
7. Bit 1–10 → dispense the corresponding circle using **Line Start / Arc Point ×3 / Line End** (1 mm radius approximation).
8. Jump to Cure label.
9. Cure:
   - Move to tag-specific UV position (hard-coded offsets from fiducial).
   - Output 2 = 1 (UV LED on via PLC Ch2 mapping).
   - Wait Point 5 s.
   - Output 2 = 0.
   - Output 1 = 1 (completion signal to PLC ReadyForNextBit).
   - Wait Point 1 s.
   - Output 1 = 0.
   - Jump back to BitCheck for next dot on same tag.
10. Bits 11–15 → ignored, jump straight back to BitCheck (reserved).

## Position Decoding (3-bit)
The .SRC uses a cascade of Input/Label to build the 3-bit value:

```
Input,7,1,...   ; MSB
...
Input,5,1,...   ; LSB
```

Result selects one of eight Tag subroutines. Each subroutine has its own pair of fiducial locations (different X/Y for the two columns, 80 mm row spacing).

Example fiducials (Tag 0 / position 0):
- Fiducial Mark 156.933, 83.192, 27.655, 11
- Fiducial Mark 231.828, 143.075, 27.655, 12
- Fiducial Mark Adjust
- Store tag_x / tag_y / tag_z from adjusted values

All eight tags follow the same pattern with their grid offsets.

## Bit Decoding (4-bit) + Circle Generation
Similar Input/Label tree for the 4-bit code. Each active bit has a **Line Dispense Setup**, then three **Arc Point** commands that approximate a 1 mm radius circle centered at an offset from the fiducial-adjusted tag origin.

Circle approximation (typical for Bit 1):
```
Line Start tag_x+1, tag_y+1, tag_z
Arc Point  tag_x+2, tag_y+1, tag_z
Arc Point  tag_x+1, tag_y+2, tag_z
Arc Point  tag_x+0, tag_y+1, tag_z
Line End   tag_x+1, tag_y+1, tag_z
```

Different bits have different (dx, dy) offsets so the 10 possible dots are spaced across the tag surface without overlap.

## UV Cure Positions
After each successful circle, the program moves to a tag-specific UV station point (hard-coded 11.2 / 131.2 X, varying Y by 80 mm row, Z = 23). The 5 s cure is performed with the LED array mounted on the x-slide (custom 3D-printed finned block).

The completion handshake (Ch1 high 1 s) tells the PLC "this dot is done, send the next code or 0000".

## Why This Architecture?
The Nordson .SRC language is extremely limited (no loops, limited variables, label-based flow). The PLC therefore owns all the intelligence:
- Sparse iteration over the 10-bit tag mask (only send the bits that are actually set).
- Tracking which bits have been acknowledged.
- 8-tag window management and printed-status array.
- Job resume after power cycle or fault.

The .SRC only has to:
- Decode the two binary fields.
- Execute fiducials once per tag.
- Draw one circle + cure + signal.
- Loop back for the next code on the same tag.

This division of labor was forced by the hardware constraints and turned out to be robust.

## Source Files
- `code/nordson/8up-nordson-protocol.src` — Main production program with full 8-tag grid and binary decode tree.
- `code/nordson/test-logic.src` — Earlier test version used during bring-up (simpler label structure).

Exact fiducial coordinates, circle offsets, and UV points are process parameters and are not reproduced in the portfolio version.

## Commissioning Notes
- Line speed reduced to 10 mm/s during dot printing for control.
- Multi-needle setup and backtrack parameters tuned with the chemist for the specific dielectric rheology.
- Fiducial lighting and threshold adjusted per substrate batch.
- UV intensity verified with radiometer; 5 s exposure at the chosen height gave full cure without overheating the FR4.

The combination of two fiducials per tag + profilometer feedback on dot geometry gave us the 5 µm height tolerance required for consistent RF modulation.