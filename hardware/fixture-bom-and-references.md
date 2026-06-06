# Hardware — Fixture & Cure BOM / References

This directory contains notes and references for the custom fixturing and UV cure hardware developed for the 8-up Nordson process.

## Primary Components (8-up System)
- 8-up Base Plate (full and half variants) — laser cut
- 8-up Tag Fixing Frame V2 — laser cut / 3D printed hybrid
- Top Magnet frames V1–V4 (single, 4-up, 8-up) — 3D printed (PETG/CF + SLA details)
- Bottom Magnet V1 (Base + Lid)
- Magnet Holder Assembly
- Nordson Twist Clamp
- Laser Cut x-slide Mount (Curing Lamp)
- UV LED Head Cure Mount (Block + Fins + Head) — 3D printed with heat sinking
- Quarter Base Plate 70-1x100-2

All CAD (SolidWorks .SLDPRT/.SLDASM, DXF, STL) and gcode files are in the parent `8-Tag System/` and `Nordson Curing/` directories.

## Key DFM Features
- Magnet pull-down for repeatable Z and flatness without over-constraining thin FR4.
- Self-aligning datums between base, frames, and printer plate.
- Quick-release via twist clamps (no tools for daily operation).
- Finned UV mount for passive cooling during repeated 5 s pulses.
- Modular quarter plates for mixed R&D/production loads.

## Related Sub-Systems (same project)
- Tag Applier: linear actuator, vacuum solenoid, TPU vacuum head, 8020 frame, Arduino control (master/slave).
- Card Dispenser: 24 V elevator/rollers, photogate, servo trap door, 1.5 m tower capacity.

Print settings, material choices (PETG for durability, SLA for fine UV features), and assembly instructions are in the original project tree.

## References in This Repo
- `docs/hardware-fixtures.md` — design rationale and iteration history.
- `docs/uv-curing-and-calibration.md` — cure hardware + profilometer loop.
- `images/` — profilometry scans showing dot geometry achieved with the fixtures.

For the actual production files, start from the `8-Tag System/` folder in the broader Pascal Tags project.