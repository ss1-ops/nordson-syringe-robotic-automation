# Full Project Scope, System Architecture & Components

**Pascal Tags – Nordson ProPlus4 Chipless RFID Tag Printer Automation (2025)**

This document provides the full (sanitized for public portfolio) scope, high-level architecture, and component breakdown of the end-to-end automation system developed for chipless RFID production. It is intended as the primary reference for the [public GitHub portfolio repo](https://github.com/ss1-ops/nordson-syringe-robotic-automation).

**Important**: All specific production parameters, exact coordinates, dispense recipes, fiducial locations, machine IP addresses, and other proprietary details have been redacted or generalized per standard confidentiality practices. See the main [README](../README.md) and individual docs for sanitization notes.

## Project Scope & Objectives

**Client**: Pascal Tags (Louisville, KY) – manufacturer of chipless RFID tags using dielectric dot printing on pre-traced FR4 substrates.

**Role**: Head of Automation (contractor)

**Core Problem**:
- Nordson ProPlus4 robotic syringe printer had only 8 native digital I/O channels (no Ethernet/IP or native networking).
- Production was semi-manual: 42 tags/hour, operator loading/unloading, no traceability, limited to single-tag operation.
- Needed deterministic automation for 8-up batch processing, job management for up to ~2,000 tags, fiducial compensation, integrated UV curing, and production logging/traceability.

**Key Outcomes**:
- Scaled to fully automated, traceable 8-up production.
- Custom 8-channel binary protocol (3-bit tag position + 4-bit bit index) over raw I/O.
- Hybrid PLC + modern web HMI architecture.
- In-house 3D-printed + laser-cut fixturing with magnetic hold-down and quick changeover.
- Closed-loop process calibration to 5 µm dielectric dot height tolerance using profilometry.
- Supporting automation: automated FR4 card dispenser and post-print tag applier.
- Production scaling roadmap and CapEx models for 1M–10M tags/year.

**Non-Goals / Out of Scope for Public Version**:
- Full RF encoding maps or exact dielectric rheology parameters.
- Complete SolidWorks source assemblies (high-level references only).
- Higher-volume custom multi-head inkjet printer designs (separate program).
- Internal quality system data or exact yields.

**Broader Impact**:
- Enabled traceable production supporting DoD and commercial applications.
- Established repeatable processes, fixturing approach, and control patterns reusable for future lines.
- Proved the hybrid real-time (PLC) + modern UI (FastAPI/WebSocket) pattern for machines with limited native interfaces.

## High-Level System Architecture

The system follows a **hybrid real-time + modern software pattern** forced by the printer's hardware constraints (only 8 I/O, no network).

```
[Operator / Job System]
          |
          v
[Web HMI (FastAPI + WebSocket + pycomm3)]
          |  (CSV jobs, status, start pulses, Web_PrintedStatus mirroring)
          v
[Allen-Bradley Micro 820 PLC]  <--- Time-critical logic only
          |  (8 I/O binary protocol, state machines, timers, edge detection)
          v
[Nordson ProPlus4 Printer]  (executes motion/dispense/cure via .SRC)
          |
          +-- [Custom 8-up Magnetic Fixtures] (laser-cut base + 3D-printed frames/magnets)
          |
          +-- [UV Cure System] (x-slide mounted 395nm LED array, protocol-triggered)
          |
          v
[Supporting Sub-Systems]
  - Automated FR4 Card Dispenser (elevator + photogate + servo trap door)
  - Post-Print Tag Applier (Arduino + vacuum + linear actuator + TPU head)
  - QC / Future Scaling (profilometer integration, vision, higher-volume inkjet concepts)
```

**Core Design Principles**:
- **PLC owns determinism**: All timing (500 ms RunPulse, 2 s settle, 5 s UV, 1 s completion handshake), bit encoding, and safety. Machine can run autonomously if HMI/server is down.
- **Server owns intelligence & UX**: Job management (up to ~2,000 tags), CSV handling, status broadcasting, operator controls. 8-tag windowing due to PLC memory limits.
- **Protocol over I/O**: Custom sparse binary encoding (3-bit position select + 4-bit bit index). Fiducials per tag for compensation. Rising-edge ReadyForNextBit handshake.
- **In-house DFM/DFA**: All fixturing, UV mounts, and supporting mechanics designed for quick iteration with 3D printing + laser cutting. Magnetic registration for flatness and <0.2 mm repeatability.
- **Traceability by design**: `PrintedStatus` array + window management allows mid-job resume and duplicate prevention.
- **Process control via feedback**: Keyence profilometer closed-loop tuning of dispense parameters (pressure, speed, time, Z) to achieve 5 µm height tolerance.

**Data Flow (Simplified)**:
1. Web HMI uploads CSV (tag values 0–1023, where each bit = one dielectric circle).
2. Server writes windowed `Web_TagList[]` + `Web_NumTags` + sets `Web_UpdateFlag`.
3. PLC copies to local `TagList[]`, clears flag.
4. Start (physical or web) → PLC drives 3-bit position + 4-bit command → asserts RunPulse.
5. Nordson .SRC: reads codes → two fiducials per tag → prints circle(s) using Arc Point approximations → triggers UV (Ch2) → signals completion (Ch1 rising edge).
6. PLC marks bit complete in masks + `Web_PrintedStatus`, advances or signals batch done.
7. Status pushed via WebSocket; operator sees live I/O, progress, and can pause/resume.

## Key Components & Sub-Systems

### 1. Printer & Protocol Layer
- **Nordson ProPlus4**: Robotic syringe dispenser. Limited .SRC language (labels, inputs, arc points, outputs, waits). No native networking.
- **Custom Protocol** (8 I/O channels):
  - Outputs (PLC → Nordson): 3-bit position (0–7), 4-bit bit index (0 = complete, 1–10 = dots), RunPulse (500 ms trigger).
  - Inputs (Nordson → PLC): PrinterRunning status, ReadyForNextBit (rising edge completion + cure done).
- **Nordson .SRC**: Fiducial marks (2× per tag), Line Dispense Setup + 3× Arc Point circle approximation (1 mm radius), UV trigger, completion handshake. Layered for different dot sizes.
- **Redacted in public version**: Exact fiducial X/Y/Z per tag, circle centers/offsets/radii per bit, layer speeds, UV station points, dispense setup values.

### 2. Real-Time Controller (PLC)
- **Allen-Bradley Micro 820** (Structured Text + expansion).
- Responsibilities: Bitwise tag mask processing (`CurrentTagMask` / `ProcessedMask`), TON timers, rising-edge detection, output latching, 8-tag window management, `Web_PrintedStatus` mirroring, safety interlocks, auto-advance between tags.
- Key patterns: Sparse bit iteration without inner loops, hybrid handshake so server can restart without stopping the machine.
- Redacted: Exact I/O tag names beyond high-level mapping, full variable declarations, some diagnostic counters.

### 3. Operator Interface & Job Management (HMI/Server)
- **FastAPI + Uvicorn + WebSocket** (Python).
- **pycomm3** for Ethernet/IP to PLC.
- Features: CSV upload/validation (0–1023 range), job progress, real-time status table (color-coded I/O), mode toggle (Individual vs Duplicated for R&D), start/reset, resume via `PrintedStatus`.
- Architecture: Server handles high-level sequencing and UI; PLC handles all timing-critical work.
- Redacted: Specific PLC IP, full source (excerpts only in public repo), any production job examples.

### 4. Fixturing & Mechanical (In-House DFM)
- **8-up Magnetic Fixture System**:
  - Laser-cut base plate (registered to Nordson via dowels + custom twist clamps).
  - 3D-printed top magnet frames (V1–V4 iterations for registration, ergonomics, heat relief).
  - Bottom/top magnet pairs for repeatable Z/flatness on thin FR4 without over-constraining.
  - Modular quarter plates for mixed R&D/production.
- **UV Cure Head**: 395 nm LED array in custom 3D-printed finned mount on Nordson x-slide. Protocol-triggered (5 s per dot). Passive cooling.
- **Supporting Automation**:
  - Automated FR4 Card Dispenser: 1.5 m tower, elevator/rollers, photogate verification, servo trap door.
  - Post-Print Tag Applier: Arduino-controlled (master/slave), linear actuator, vacuum solenoid, TPU vacuum head, limit switches for open-hold-close style cycle on tags.
- Redacted: Exact DXF/STL dimensions, specific magnet pull forces, full BOMs with supplier SKUs (references only).

### 5. Process Control & Metrology
- **Keyence Profilometer**: Non-contact laser scanning for dot height, diameter, volume. Used in closed-loop tuning of dispense parameters.
- **Fiducial Compensation**: Two marks per tag in .SRC; PLC/Nordson stores adjusted coordinates.
- **Calibration Loop**: Print → scan → measure → adjust (primarily time/pressure, secondary speed/Z) → repeat until ±5 µm tolerance achieved across positions.
- Redacted: Specific target heights, exact adjustment deltas, rheology details, batch qualification data.

### 6. Broader System & Future Scaling
- **Production Scaling Models** (see `docs/scaling-strategy.md` copied in):
  - Roadmap from current Nordson bottleneck to multi-printer custom inkjet UV lines (A2/A1 beds, Epson/Ricoh heads).
  - CapEx estimates and throughput models for 1 M / 5 M / 10 M tags/year.
- **Quality & Traceability**: Every tag explicitly tracked; resume support; integration points for future vision QC or RF testing.
- **Related Sub-Projects**: Card dispensing system, tag application automation, initial R&D on higher-rate processes.

## Physical Layout (4×2 Fixture)
- 4 columns × 2 rows on 70 × 100 mm FR4 tags.
- Column spacing ~120 mm, row spacing 80 mm.
- Numbering top-to-bottom, left-to-right (0–7).
- Position binary directly maps to physical slots for fiducial jumps.

## Software & Control Philosophy
- **Determinism where it matters** (PLC cyclic scan).
- **Flexibility & UX where it doesn't** (server).
- **Sparse command encoding** to work within 8 I/O.
- **Feedback-driven process** (profilometer + fiducials + handshake).
- **Resilience** (machine continues on HMI fault; printed status for recovery).

## Files & References in This Repo (Portfolio Version)
- `docs/system-architecture.md`, `plc-implementation.md`, `nordson-src.md`, `uv-curing-and-calibration.md`, `hardware-fixtures.md`, `web-hmi.md`, `results-metrics.md` – detailed (sanitized) views.
- `docs/scaling-strategy.md`, `docs/card-dispensing-system.md` – copied from full project for broader scope.
- `code/` – sanitized excerpts of PLC (.ST), Nordson (.src), HMI.
- `hardware/` – fixture BOM notes and references (full CAD in parent project).
- `images/` – representative screenshots (profilometry, HMI, hardware).

For the complete unsanitized project tree (SolidWorks, full gcode, internal logs, exact production parameters), see the parent `Models/` or `8-Tag System/` directories in the Pascal Tags project folder (not part of the public GH repo).

## How This Maps to the Public GitHub Portfolio Repo
This `gh-repo` directory in Dropbox serves as the curated source for what is published at https://github.com/ss1-ops/nordson-syringe-robotic-automation. 

All content here has been prepared with portfolio goals in mind:
- Demonstrate end-to-end ownership (mechanical DFM → controls protocol → software HMI → process calibration → scaling models).
- Highlight reusable patterns (hybrid PLC + web, limited-I/O protocol, in-house fixturing, feedback loops).
- Provide enough technical depth for technical discussions while respecting confidentiality (see redactions in individual files and the main README).

**Visuals & Demos**: Place photos, build images, HMI screenshots, cycle videos, and profilometer scans in `images/` and reference them in the docs above. (See the assets todo note in the Obsidian vault for a full list of recommended captures.)

---

*This document expands the public-facing scope while maintaining the sanitization approach documented in the repo's main README and the associated Obsidian portfolio todo notes (NDA redactions, etc.).*
