# HMI Code Excerpts (Sanitized)

This folder contains representative, redacted excerpts from the FastAPI + pycomm3 WebSocket HMI developed for the Nordson automation cell.

Full source (including multiple save points, test scripts, HTML templates, and plc_comm.py) lives in the parent project under `Models/PLCWebInterface/`.

## Key Files (in the full tree)
- plc_comm.py — PLCComm class with timeout wrapper, tag read/write, start pulse, CSV handling.
- main_websocket.py / websocket_handler.py — FastAPI app + WS broadcast.
- data_models.py — Pydantic models for status, job upload, etc.
- Auto Tag Printing.html (or 3.html) — single-page frontend with Tailwind + JS client.

## Sanitization Notes
- IP addresses, exact tag names that could reveal process details, and any credentials removed.
- The `@with_timeout` decorator and ThreadPool pattern are shown because they were a critical workaround for the pycomm3 library.
- The hybrid PLC/server split philosophy is the reusable takeaway.

See `docs/web-hmi.md` for architecture and usage description.