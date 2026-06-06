# Nordson Syringe Robotic Automation (Pascal Tags)

End-to-end automation of a Nordson ProPlus4 robotic syringe printer for high-precision dielectric dot deposition on chipless RFID tags (70 × 100 mm FR4 substrates).

**Role:** Head of Automation (contractor)  
**Client:** [Client – specialty RFID manufacturer]  
**Duration:** 2025  
**Outcome:** Scaled from 42 tags/hour semi-manual operation to fully automated, traceable 8-up batch production with web HMI, custom 8-channel binary protocol, fiducial-compensated printing at 5 µm tolerances, and integrated UV curing.

**Featured on [my portfolio](https://ss1-ops.github.io#projects).**  
**Source of truth / full details (sanitized for public):** This `gh-repo` directory in the Pascal Tags Dropbox project.

## Problem
The Nordson ProPlus4 had no native network interface — only 8 digital I/O channels. Manual loading/unloading and lack of job tracking limited throughput and traceability. The system needed deterministic control over which of 8 tags in a custom fixture received which of up to 10 circular dielectric dots, with fiducial correction, precise dispense, 5-second UV cure per dot, and production logging.

## Solution Overview
- Custom binary multiplexed protocol over the printer's 8 I/O channels (3-bit tag position + 4-bit sparse bit index).
- Allen-Bradley Micro 820 PLC executing time-critical state machines and output encoding.
- FastAPI + WebSocket HMI for job upload (CSV up to 1,999 tags), real-time monitoring, start/reset, and printed-status tracking.
- 8-up magnetic fixture system (laser-cut base + 3D-printed magnet frames) for rapid load/unload and flat registration.
- Nordson .SRC program using fiducial marks (2× per tag), arc-point circle generation, and channel-driven UV trigger.
- Keyence profilometer-based calibration loop for dispense parameters targeting 5 µm dot height tolerance.
- Supporting automation: automated FR4 card dispenser and tag applier (Arduino + vacuum + linear actuator).

The hybrid architecture keeps hard-real-time logic on the PLC while the server handles sequencing, CSV parsing, and operator UI. The printer continues running even if the HMI server is restarted.

## Key Results

![Profilometry / HMI / hardware screenshot](images/Screenshot%202025-11-24%20071157.png)

- **Throughput:** 42 tags/hour (semi-manual baseline) → automated 8-up cycles with deterministic bit-by-bit sequencing.
- **Tolerance:** Dielectric dot deposition at 5 µm tolerances via fiducial compensation and profilometer-tuned dispense.
- **Traceability:** Web-driven jobs with per-tag printed status (resume support across 2,000-tag runs); full batch windowing (8 tags at a time) to fit PLC memory limits.
- **Hardware:** Designed and fabricated 8-tag magnet fixtures (multiple iterations V1–V4), UV LED cure mounts with heat fins, Nordson twist clamps, and x-slide mount. All produced in-house via 3D printing (FDM/SLA) and laser cutting.
- **Prototyping capability:** Established 10–20 tags/month R&D rate with path to 50–100/month via fixtures and process documentation. Production scaling models completed for 1 M / 5 M / 10 M tags/year using custom inkjet UV lines (A2/A1 beds, Epson/Ricoh heads).
- **Process control:** Closed-loop bit handshake (ReadyForNextBit rising edge), 500 ms run pulse + 2 s settle, 5 s UV cure per dot, automatic skip of pre-printed tags.

## Why this stands out (portfolio highlights)
- **Hybrid real-time control + modern HMI pattern:** Hard real-time on PLC (Structured Text), higher-level sequencing/UI on FastAPI/WebSocket. Printer keeps running autonomously if the server restarts.
- **Custom binary protocol over raw I/O:** Deterministic 8-channel multiplexed protocol (3-bit position + 4-bit bit index) with run pulse, fiducial integration, and UV cure handshakes — no Ethernet/IP on the printer itself.
- **Production DFM/DFA on fixtures:** Multiple iterations of 3D-printed + laser-cut 8-up magnetic fixtures, UV cure heads with heat fins, Nordson clamps. Designed for rapid changeover and flat registration at 5 µm.
- **Scaling models + CapEx:** Full rate modeling (5M–10M tags/year) and process documentation for future lines.
- **End-to-end ownership:** PLC logic ↔ device protocol ↔ web HMI ↔ custom mechanical tooling ↔ calibration loop.

See the new **[Full Scope, System Architecture & Components](docs/full-scope-architecture.md)** document for diagrams, component breakdowns, data flows, physical layout, and the complete (sanitized) project scope including supporting sub-systems (card dispenser, tag applier, scaling concepts).

## Repository Contents
- `docs/` — Detailed technical documentation (sanitized)
  - `full-scope-architecture.md` — **New: comprehensive scope + architecture with diagrams**
  - `system-architecture.md`
  - `plc-implementation.md`
  - `nordson-src.md`
  - `web-hmi.md`
  - `hardware-fixtures.md`
  - `uv-curing-and-calibration.md`
  - `results-metrics.md`
  - `overview.md`
  - `source-nordson-print-circles.md`
  - `scaling-strategy.md` (copied from full project)
  - `card-dispensing-system.md` (copied from full project)
- `code/`
  - `plc/Nordson-8up-PLC.ST` — Sanitized production Structured Text (Micro 820)
  - `nordson/8up-nordson-protocol.src` + test-logic — Nordson .SRC binary decode + print logic (sanitized)
  - `hmi/` — Key excerpts from FastAPI + pycomm3 WebSocket interface (sanitized)
- `hardware/` — Fixture design notes and BOM references
- `images/` — Representative screenshots (profilometry, HMI, hardware)

All code and designs were developed and commissioned on-site. CAD sources (SolidWorks, DXF, STL) and full HMI repository live in the parent project tree (see `Models/` and `8-Tag System/` in the Pascal Tags Dropbox project).

## Technology Stack
- **PLC:** Allen-Bradley Micro 820 (Structured Text + relay expansion module), pycomm3 Ethernet/IP
- **Printer:** Nordson ProPlus4 (custom .SRC with Input/Label/Arc Point/Fiducial/Output)
- **HMI/Server:** Python, FastAPI, Uvicorn, WebSocket, Tailwind + vanilla JS
- **Hardware:** SolidWorks, 3D printing (PETG/CF, SLA), laser cutting, 8020 extrusion, magnets, Keyence profilometer
- **Supporting:** Arduino (tag applier + card dispenser), custom vacuum tooling

## How to Use These Materials
These docs and code samples are provided for portfolio and technical discussion purposes. The actual production system contains additional proprietary process parameters (dispense recipes, exact fiducial coordinates, RF encoding maps) that are not included.

For questions on the protocol design, fixture DFM, or scaling models, see the individual docs (especially the new full-scope architecture document).

## License
MIT License — see [LICENSE](LICENSE).

---

**Sam Snyder**  
Head of Automation — Pascal Tags (2025)  
sam@samhsnyder.com | Austin, TX / Louisville, KY (project site)

Related: [Full portfolio](https://ss1-ops.github.io#projects) | Other automation & robotics projects on this profile.

**Note for maintainers**: This `gh-repo` directory in the Dropbox is the curated source for the public GitHub repo. Apply redactions from the Obsidian vault note (`nordson-syringe-robotic-automation-edits-redactions.md`) before any push. Add visuals (see assets todo) to `images/`.
