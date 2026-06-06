# System Architecture

## High-Level Flow
1. Web HMI (operator or automated job) uploads CSV of tag values (0–1023, each bit representing one dielectric circle).
2. Server writes `Web_TagList[0..N]` and `Web_NumTags` to PLC, pulses `Web_UpdateFlag`.
3. PLC copies current 8-tag window into local `TagList[]` and `NumTags`.
4. Operator presses physical Start or web Start button → PLC begins SetState machine.
5. For each tag in window:
   - Set 3-bit position code (PositionBit0–2) on DO04–06.
   - Convert tag bitmask to sparse sequence of 4-bit codes (Bit1–4 on DO00–03).
   - Assert 500 ms RunPulse on P1DO00.
   - Nordson .SRC starts, reads position + first bit code, performs two fiducial marks, prints circle, triggers 5 s UV cure (via Ch2), signals completion on Ch1.
   - PLC waits for `ReadyForNextBit` rising edge on DI04.
   - On edge, mark bit processed, advance to next set bit in mask or signal tag complete (code 0000).
6. After 8 tags or job end: EightDoneBuzzer, advance `EightIndex`, load next window if more tags remain.
7. PrintedStatus array tracks progress for mid-job resume and duplicate prevention.

## Hybrid Split (Critical for Reliability)
- **PLC (Micro 820):** All timing-critical logic — bit encoding, TON timers, edge detection, output latching, state machines. Runs autonomously.
- **Server (FastAPI):** CSV parsing/validation, job management, WebSocket broadcast of status (1 s updates), operator controls. Can restart without stopping the printer.

This split was chosen because the Nordson has no network stack and the PLC has limited memory (hence the 8-tag window + 2000-tag master list on server).

## Channel Protocol (8 I/O Total)
**Outputs (PLC → Nordson):**
- Bits 0–3 (DO00–03): 4-bit binary for current dot index (1–10). 0 = tag complete / end program.
- Bits 4–6 (DO04–06): 3-bit binary for tag position in 4×2 fixture (0–7).
- Bit 7 (P1DO00): RunPulse (500 ms) — triggers Nordson program start.

**Inputs (Nordson → PLC):**
- DI01: PrinterRunning (status).
- DI04: ReadyForNextBit (rising edge = Nordson finished current dot + cure, ready for next code).

Full encoding tables and state diagrams live in `nordson-src.md` and `plc-implementation.md`.

## Data Model
- Master list lives on server (Web_TagList[0..1999]).
- PLC sees only current window of 8.
- `Web_PrintedStatus[0..1999]` (INT) mirrors progress; PLC marks 1 after successful AllBitsProcessed + printer idle.
- Two print modes supported via server logic:
  - Individual: 8 unique tags per fixture load.
  - Duplicated: 4 unique tags mirrored across columns (for process development).

## Error & Edge Handling
- Index bounds guards with buzzer + fault flags.
- Pre-printed tag skip (no RunPulse wasted).
- Zero-value tags treated as immediate complete.
- StartupFlag + init handshake prevents motion until arrays and web sync are stable.
- Manual StartBtn + Web_StartBtn both supported with debounced rising edges.
- LaserMode input switches UV behavior.

## Physical Layout (4×2 Fixture)
Columns spaced 120 mm, rows 80 mm vertical. Numbering top-to-bottom, left-to-right:
- 0 1
- 2 3
- 4 5
- 6 7

Position binary matches this ordering so Nordson fiducial jumps land on the correct physical slot.

## Supporting Sub-Systems
- **Automated Scanning System (QC) (ESP32):** 1.5 m FR4 stack → elevator + dual rollers + 0.8 mm gate + photogate verification → scan slot → servo trap door.
- **Tag Applier (Arduino master/slave):** Linear actuator + vacuum solenoid + TPU head + limit switch for post-print application to product.
- **UV Cure:** Custom 395 nm LED array on Nordson x-slide (finned heat sink, 3D-printed mount). Triggered for 5 s per dot via protocol Ch2.

All mechanical components designed for DFM/DFA: quick-change magnets, repeatable datums, minimal operator intervention.

See individual docs for implementation depth.
