# Card Dispensing System Specification

## Overview
This document outlines the design and operation of a card dispensing system for FR4 cards (70mm x 100mm x 0.8mm). The system dispenses cards from a stacked tower, verifies their dispensing, and manages card disposal post-scanning via an automated process.

## System Components

### 1. Card Stack and Elevator
- **Tower Enclosure**: 1.5m tall, houses a stack of FR4 cards.
- **Elevator Platform**: Lifts the card stack using a lead screw driven by a 24V motor.
- **Operation**: Raises the stack to maintain contact with the dispensing head when pressure drops below a threshold.

### 2. Dispensing Head
- **Structure**: Two roller bars with yellow rubber wheels, each powered by a 24V motor.
- **Pressure Sensor**: 5mm variable resistance sensor under the head, triggered by a pressure button to monitor stack pressure.
- **Gate**: Restricts output to a single card (0.8mm thickness).
- **Dispensing Mechanism**:
  1. Both rollers rotate forward to advance the top card.
  2. Back roller reverses to retract any card below, preventing multiple dispenses.

### 3. Card Verification
- **Ramp**: Cards slide down post-dispensing.
- **Photo Gate Detector**: Laser beam detects card passage, confirming successful dispensing.

### 4. Card Scanning and Disposal
- **Scanning Slot**: Cards fall into a slot for scanning by an external system.
- **Trap Door Mechanism**:
  - **Plate**: Servo-driven, slides back to open a discard slot after scanning completion signal.
  - **Operation**: Servo reverses to close the slot after card disposal, preparing for the next card.
- **External Signal**: Scanning system signals completion to trigger trap door activation.

### 5. Reload Mechanism
- **Reload Button**: Reverses the elevator motor to lower the platform to the bottom for card stack reloading.

## Operational Workflow
1. **Initialization**:
   - Elevator raises the stack until the pressure sensor registers adequate force.
2. **Dispensing**:
   - Front and back rollers rotate forward to dispense the top card.
   - Back roller reverses to prevent multiple card dispensing.
   - Card passes through the 0.8mm gate.
3. **Verification**:
   - Card slides down the ramp, breaking the laser beam to confirm dispensing.
4. **Scanning**:
   - Card lands in the scanning slot.
   - External system scans and sends a completion signal.
5. **Disposal**:
   - Servo slides the plate to open the discard slot, dropping the card.
   - Servo returns the plate to the closed position.
6. **Stack Adjustment**:
   - If pressure sensor reading drops below threshold, the elevator raises the stack.
7. **Reloading**:
   - On reload button press, the elevator lowers to the bottom for stack replenishment.

## Key Specifications
- **Card Dimensions**: 70mm x 100mm x 0.8mm (FR4 material).
- **Tower Height**: 1.5m.
- **Motors**: 24V (elevator lead screw and roller bars).
- **Servo**: Controls trap door plate.
- **Sensors**:
  - 5mm variable resistance pressure sensor.
  - Photo gate with laser beam for card detection.
- **Gate Clearance**: 0.8mm to ensure single-card dispensing.

## Safety and Maintenance
- **Pressure Monitoring**: Ensures consistent card feed without jamming.
- **Gate Design**: Prevents multiple card dispensing, reducing errors.
- **Reload Mode**: Safe and accessible for operators to restock cards.
- **Motor Protection**: Ensure motors have overcurrent protection to prevent damage.

## Future Considerations
- **Error Handling**: Add sensors to detect jams or misfeeds.
- **Feedback System**: Visual or auditory indicators for successful dispensing or errors.
- **Calibration**: Periodic adjustment of pressure sensor threshold and gate clearance.