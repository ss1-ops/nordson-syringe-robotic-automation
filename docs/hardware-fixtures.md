# Custom Fixture Design & Production

## Requirements
- Hold eight 70 × 100 × 0.8 mm FR4 tags in a precise 4×2 grid.
- Repeatable registration (< 0.2 mm) so fiducial marks in the Nordson .SRC can compensate the remaining error.
- Fast load/unload by one operator (no screws, minimal alignment).
- Flatness across the entire array so dispense height is consistent (critical for 5 µm dot height tolerance).
- Compatibility with existing Nordson build plate and twist-clamp interface.
- In-house manufacturable with 3D printers + laser cutter (no external machine shop for prototypes).

## 8-up Fixture Architecture
**Base plate (laser-cut acrylic or similar, DXF driven):**
- Registered to Nordson plate via dowels + twist clamps (custom 3D-printed clamp).
- Magnet pockets or mounting features for the bottom magnet halves.
- Quarter-base variants for process development on smaller runs.

**Top magnet frames (3D printed, multiple iterations V1–V4):**
- V1: Single-tag test frames.
- V2/V3: 4-frame and full 8-up frames with improved magnet retention and edge registration.
- Magnets (top + bottom pairs) pull the FR4 flat against the base. TPU or soft features prevent cracking the thin substrate.
- Handles or finger reliefs for quick removal.

**Magnet Holder Assembly:**
- Bottom magnet (Base + Lid) — sits in the base plate pockets.
- Top magnet frames register to the same datums.

**Nordson Twist Clamp:**
- Secures the entire fixture stack to the printer arm with a single motion.

**UV / x-slide mount:**
- Separate 3D-printed block + finned head for the 395 nm LED array. Mounts to the printer's x-slide so the cure head can be positioned over each tag after printing without extra axes.

All parts were designed in SolidWorks with DFM in mind: minimal supports, self-aligning features, tolerance stack analysis for the magnet + FR4 + base stack.

## Iteration History
- Early single-tag and quarter-plate tests validated magnet hold-down force and fiducial visibility.
- Full 8-up V2 frame improved edge datum location after first production runs showed row-to-row variation.
- V4 added better heat relief around magnets and more ergonomic lift points.
- Laser-cut "half" base plates allowed mixed R&D + production loads on the same machine.

## Manufacturing
- Laser cutting (in-house or quick-turn): base plates, some alignment jigs.
- 3D printing: FDM (PETG, CF-filled for stiffness on frames) + SLA for fine features on UV mounts and TPU vacuum heads (used on the separate tag applier).
- Assembly: magnets epoxied or press-fit, minimal fasteners.

## Impact on Process Capability
The fixture + two fiducials per tag (one primary, one secondary) gave enough compensation that we could hold the 5 µm dielectric height target across all eight positions even with manual placement of the FR4 blanks. Profilometer scans (Keyence) on first-article dots from each position were used to close the loop on both fixture flatness and dispense parameters.

See `hardware/` folder for DXF/STL references and the parent `8-Tag System/` directory for the complete SolidWorks tree and print logs.