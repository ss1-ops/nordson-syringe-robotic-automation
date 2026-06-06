# UV Curing System & Profilometry Calibration

## UV Cure Requirements
Each dielectric dot must receive a full 395 nm cure before the next dot is printed on the same tag (to prevent smearing and to lock in the precise geometry needed for RF performance). Cure time and intensity were determined experimentally with the materials team.

**Implementation:**
- 395 nm LED array (~$15 per emitter) mounted in a custom 3D-printed finned head.
- Head attached to Nordson x-slide via laser-cut + 3D-printed bracket (allows the cure position to be reached with existing axes).
- Triggered by the Nordson .SRC after each successful circle: Output Ch2 = HIGH for 5 s, then LOW.
- The PLC protocol maps this to the physical output; the .SRC simply drives the channel high/low with a Wait Point.

**Cure positions:**
Hard-coded per tag in the .SRC (derived from first fiducial + fixed offset, e.g. X = fiducial_x – 145.8 mm, Y offset by row, Z = 23 mm). This keeps the UV head at a consistent working distance and avoids collisions with the just-printed tag.

**Thermal management:**
Fins on the LED mount + short 5 s pulses kept the array and substrate well below any damage threshold. Multiple iterations of the fin geometry were printed and tested.

## Profilometry Calibration Loop (Keyence)
Dot height, diameter, and volume directly affect the radar cross-section modulation. Target: 5 µm height tolerance (and corresponding volume) across all 10 possible dot locations and all 8 fixture positions.

**Process:**
1. Print test dots (single bit or full tag patterns) using current dispense parameters (pressure, line speed, dispense time, needle height).
2. Scan with Keyence profilometer (non-contact laser height mapping).
3. Measure center height, diameter at multiple thresholds, volume under the surface.
4. Adjust dispense recipe (primarily time and pressure; secondary: speed and Z height).
5. Re-print, re-scan, iterate.
6. Once stable, run full 8-up first-article set and confirm position-to-position and tag-to-tag consistency.
7. Lock parameters; use the same recipe for production jobs.

**Example data (representative from commissioning):**
- Target height: ~XX µm (process-specific value).
- Achieved: within ±5 µm on >95 % of measured dots after tuning.
- Outliers traced to local substrate flatness or magnet seating → fixed with fixture V3/V4 revisions and operator loading procedure.

The profilometer was also used to qualify new FR4 batches and to correlate dot geometry with downstream RF read performance (worked closely with the RF/chemist team on rheology and cure energy).

## Integration with Automation
- The PLC/Nordson protocol guarantees that UV cure happens after every dot (except the "complete" code 0).
- No operator intervention required between dots on a tag.
- LaserMode input on the PLC allows the same hardware to run in a "laser-only" mode (bypassing UV) for process development.

## Files & Hardware
- UV mount CAD: `Nordson Curing/` and `8-Tag System/Laser Cut x-slide Mount Curing Lamp.*`
- Profilometer screenshots: `images/` (Keyence height maps and 2D/3D views of actual dots).
- Dispense parameter logs and iteration sheets live in the broader project folder (not reproduced here for confidentiality).

The combination of in-house fixture iteration, fiducial compensation in the .SRC, and closed-loop profilometer tuning was what moved us from "occasional good dots" to a repeatable, auditable process capable of supporting the target RF encoding.