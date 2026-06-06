# PLC Implementation (Allen-Bradley Micro 820)

## Overview
The PLC executes the real-time side of the custom 8-channel protocol. All bit encoding, timer sequencing, edge detection, and output latching happen here in Structured Text. The server only supplies the high-level job list and start pulses.

## Core Data Structures (Bitwise, Not Arrays)
Instead of maintaining 10-element BOOL arrays for the tag bitmask and processed flags, the implementation uses two INT masks:

- `CurrentTagMask` — the raw value from the job list (0–1023). Bit N set means "print circle N+1".
- `ProcessedMask` — subset of bits already sent and acknowledged via ReadyForNextBit handshake.

Finding the next bit to send:
```st
FOR i := 0 TO 9 DO
    IF ((CurrentTagMask AND SHL(1, i)) <> 0) AND ((ProcessedMask AND SHL(1, i)) = 0) THEN
        BitIndex := i;
        EXIT;
    END_IF;
END_FOR;
```

All-done test (no inner loop required):
```st
AllBitsProcessed := ((CurrentTagMask AND (NOT ProcessedMask AND 1023)) = 0);
```

This eliminates ~20 variables and several FOR loops that existed in earlier versions while remaining fully deterministic in a cyclic scan.

## State Machines

### SetState (Batch / Window Lifecycle)
- 0: Idle. Wait for `Web_UpdateFlag` (new 8-tag window) or physical/web start edge.
- 1: Processing current tag in window. Drives the per-bit TagState machine. Handles skip of already-printed tags via `Web_PrintedStatus`.
- 2: Window complete. On `EightDoneBuzzer` + printer idle, advance `EightIndex`, load next 8 tags, reset state.

### TagState (Per-Tag Sparse Bit Sequencing)
- 0: Idle. Wait for start edge (physical, web, or AutoAdvance) before firing the RunPulse sequence.
- 1: Assert RunPulse (500 ms TON) + 2 s settle Delay. Nordson program runs, performs fiducials for the current position, reads the 4-bit code, prints the circle, cures, signals ready.
- 2: Wait for `ReadyForNextBit` rising edge. On edge, OR the current bit into `ProcessedMask`, clear the 4-bit outputs, re-evaluate `AllBitsProcessed`. If more bits remain, return to state 1; else return to 0 so the outer SetState logic can advance the tag.

Position bits (3-bit) are set once when a new tag is started and remain stable for the entire tag (fiducials + all dots on that tag).

## Output Encoding
4-bit binary on Bit1–4 exactly matches the decoder tree in the Nordson .SRC (labels 1–10 for active dots, 0 for End Program). The CASE statement is exhaustive for channels 1–10; anything else forces all bits false.

Position encoding is simple bit tests:
```st
PositionBit0 := (TagPosition AND 1) <> 0;
PositionBit1 := (TagPosition AND 2) <> 0;
PositionBit2 := (TagPosition AND 4) <> 0;
```

## Web / PLC Handshake
- Server writes master list + `Web_NumTags`, sets `Web_UpdateFlag`.
- PLC copies window on flag, clears flag.
- `Web_PrintedStatus` is both read (skip logic) and written (mark complete) by PLC.
- `Web_EightIndex` is mirrored so server always knows which window the PLC is on.
- `Web_StartBtn` (pulsed from UI) and physical `StartBtn` (DI02) are OR'd with debounced rising edges.

## Safety & Initialization
- `StartupFlag` forces RunPulse and LaserPower off until `Web_InitComplete`.
- Full array zeroing and state reset on first init or web reset.
- Multiple bounds checks with `IndexOutOfBounds` flag + buzzers (never trust array index from job data).
- `Hello` diagnostic counter for timing / AutoAdvance verification during commissioning.

## Timer Usage
- `PulseTimer`: 500 ms RunPulse generator.
- `Delay`: 2 s post-pulse settle before advancing TagState (gives Nordson time to read codes and begin motion).
- `RunDelay`: 2 s AutoAdvance sequencer between tags when printer is idle.

All timers are level-triggered from state bits so they restart cleanly on state changes.

## File
See `code/plc/Nordson-8up-PLC.ST` for the complete, production-hardenend listing (sanitized variable names and comments for portfolio distribution). The version in the actual machine includes additional diagnostic tags and HMI mirror points not shown here.

## Lessons Applied Elsewhere
The same "address + command over limited parallel I/O + rising-edge handshake" pattern was later reused for FANUC robot integration work. The bitwise mask approach for sparse selection is reusable anywhere you have a bitfield command that must be serialized over a narrow bus.