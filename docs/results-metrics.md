# Results & Metrics

## Throughput
- Baseline (semi-manual, single tag at a time, operator loading): 42 tags/hour.
- Automated 8-up configuration: full fixture loads with deterministic bit-by-bit sequencing and no manual intervention between dots or tags within a window.
- Effective rate improvement came from both the 8× parallelism of the fixture and the elimination of per-tag setup time.

## Tolerances & Process Capability
- Dielectric dot deposition held to 5 µm height tolerance (and corresponding volume) after profilometer-driven dispense tuning and fixture iterations.
- Fiducial Mark (two per tag) + stored coordinate compensation handled the majority of placement variation from manual loading of FR4 blanks.
- Position-to-position consistency across the 4×2 grid verified with Keyence scans on first-article parts.

## Traceability & Job Management
- Web HMI supports CSV jobs up to 1,999 tags.
- 8-tag windowing + `Web_PrintedStatus` array allows the system to resume mid-job after power loss, PLC restart, or operator pause.
- Every tag is explicitly marked printed only after AllBitsProcessed + printer idle confirmation.
- Two modes (Individual / Duplicated) supported for production vs. process development runs.

## Hardware & Commissioning
- Designed, printed, and iterated three generations of 8-up magnet fixtures (plus single/quarter variants) plus UV cure mounts, twist clamps, and x-slide hardware — all manufactured in-house.
- Tag applier (Arduino DC motor + vacuum + limit switch + TPU head) and card dispenser (1.5 m tower, photogate verified) brought additional steps in the line under automation.
- Initial R&D prototyping rate established at 10–20 tags/month; process documentation and fixtures demonstrated path to 50–100/month on the same Nordson platform.

## Production Scaling Models
Detailed CapEx and throughput models were delivered for moving beyond the Nordson bottleneck:

| Annual Volume | Printers | Bed Size | Est. One-Time CapEx |
|---------------|----------|----------|---------------------|
| 1 M tags      | 5        | A2       | $81K–$208K          |
| 5 M tags      | 8        | A2       | $130K–$333K         |
| 10 M tags     | 12       | A1       | $330K–$572K         |

Recommended path: 8× A2 custom inkjet UV printers + robotic loading + vision = 5 M/year target at FR4 pricing of $0.03–$0.05 per tag.

## Key Technical Achievements
- Reverse-engineered and productionized a reliable 8-channel binary protocol (3-bit position + 4-bit sparse bit index) that the limited Nordson .SRC could execute.
- Hybrid PLC + server architecture that kept the machine running through HMI or network faults.
- In-house DFM loop that turned 3D printing and laser cutting into production-grade fixturing with measurable impact on yield and setup time.
- Closed-loop calibration (profilometer ↔ dispense parameters ↔ fiducial compensation) that delivered the 5 µm geometry control required for the chipless RF encoding.

## Limitations of This Nordson Platform
The 8-up, one-dot-at-a-time, syringe approach remains fundamentally serial per tag. The real scale jump requires the custom multi-head inkjet architecture described in the scaling models. The automation work on the Nordson proved the process, the fixturing approach, the protocol pattern, and the HMI/traceability needs that any higher-volume solution must satisfy.

All metrics above are from on-site commissioning and early production runs in 2025. Exact per-job first-pass yields and final RF test fallout are tracked in the company's internal quality system. The automation layer (printed status, fiducial compensation, process-locked recipes) was the primary lever for improving those yields versus the prior manual process.