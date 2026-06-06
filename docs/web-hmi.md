# Web HMI & Job Management

## Purpose
Provide operators and engineers a browser-based interface for:
- Uploading CSV job files (list of tag values 0–1023).
- Starting, stopping, and resetting runs.
- Real-time visibility into current tag position, bit, printed status, and machine I/O.
- Switching between Individual and Duplicated print modes.
- Monitoring large jobs (up to 1,999 tags) without loading everything into the PLC at once.

## Stack & Architecture
- Backend: FastAPI + Uvicorn.
- PLC communication: pycomm3 (Ethernet/IP to Micro 820 at 192.168.1.100).
- Frontend: Single-file HTML + Tailwind CSS + vanilla JavaScript WebSocket client.
- Update rate: 1 s status poll + WebSocket push.
- Threading: `ThreadPoolExecutor` + custom `@with_timeout` decorator (3 retries, 2 s backoff) to work around pycomm3's lack of native timeouts.

## Key Design Decision: Hybrid Split
Time-critical, deterministic logic (bit encoding, pulse generation, handshake) lives entirely in the PLC Structured Text.

The Python server owns:
- CSV parsing and validation (0–1023 range, length checks).
- High-level sequencing (which 8-tag window to load next).
- `Web_PrintedStatus` mirroring for resume.
- UI state and multi-client WebSocket broadcasting.

If the server or network dies, the printer finishes the current 8-tag window and waits safely for the next start pulse. This was essential for a production environment where the HMI PC might be rebooted or the wireless network might glitch.

## PLC Tags Exposed to HMI
See `system-architecture.md` for the full list. Important ones:
- `Web_StartBtn` (BOOL, pulsed 300 ms from UI).
- `Web_TagList[0..1999]`, `Web_NumTags`, `Web_UpdateFlag`.
- `Web_PrintedStatus[0..1999]` (read/write from both sides).
- `Web_EightIndex`, `Web_TagPosition`, `Web_TagIndex` (read-only mirrors).
- Status bits: `PrinterRunning`, `LaserPower`, all the BitX / PositionBitX outputs.

## PLCComm Class (Core Abstraction)
Methods:
- `connect()`
- `read_status()` — returns dict of all mirrored tags.
- `set_start_button(pulse=True)`
- `write_tag_list(tags: list[int])`
- `set_print_mode(mode: "individual" | "duplicated")`
- `reset_all()`
- `set_init_complete()`

All PLC writes that affect the state machine go through the update-flag handshake so the PLC sees a consistent snapshot.

## Frontend Features
- Live status table with color-coded I/O bits and current tag/bit.
- CSV upload with client-side validation before POST.
- Big Start / Reset buttons (also work with physical panel buttons).
- Job progress bar derived from `PrintedStatus` count.
- Mode toggle (Individual vs Duplicated) that the server translates into how it populates the current 8-tag window.
- Connection status indicator + automatic reconnection logic on WebSocket close.

## Limitations & Workarounds
- pycomm3 is synchronous and has no timeout parameter → wrapped every read/write.
- PLC memory limits → 8-tag window + server-side master list + printed status.
- No authentication in the deployed version (local network only, physical interlock on the machine).

## Files
Representative (sanitized) excerpts are in `code/hmi/`. The full development tree with templates, multiple save points, and test scripts lives in the parent `PLCWebInterface/` directory.

The HMI was the primary operator interface for all production and process development runs after the initial bring-up.