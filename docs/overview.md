# Project Overview — Nordson Syringe Robotic Automation

This repository contains the core technical artifacts from the automation of a Nordson ProPlus4 robotic syringe printer for chipless RFID tag production at Pascal Tags (2025).

The work established a repeatable, traceable, 8-up automated printing process using only the printer's native 8 digital I/O channels, a PLC, a web HMI, and in-house designed and fabricated fixturing and cure hardware.

## Scope
- Custom deterministic protocol between PLC and printer
- Full Structured Text implementation on Allen-Bradley Micro 820
- Nordson .SRC motion/dispense/cure program
- FastAPI + WebSocket operator interface with job management
- 8-up magnetic fixture system (3D printed + laser cut)
- UV LED cure integration (x-slide mounted, protocol triggered)
- Profilometer-based process calibration to 5 µm tolerances
- Supporting automation (card dispensing, tag application)

## Non-Goals (Out of Scope for This Repo)
- Full RF encoding maps or exact dispense recipes (proprietary)
- Complete SolidWorks assemblies (referenced but not duplicated here)
- The higher-volume custom inkjet printer designs (separate program)

See README.md for quick metrics and the `docs/` folder for deep dives. All materials are presented as developed and used on the project.

## Credits
Designed, built, commissioned, and documented by Sam Snyder in the role of Head of Automation.