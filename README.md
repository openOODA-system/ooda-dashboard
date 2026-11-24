# `ooda-dashboard` (`v0.1.0`)

Capability-bounded web, TCP port, and `ooda-connect`-facing system dashboard for [openOODA](https://openOODA.org) (`layer=system` • `openOODA-system`). Observe live host and daemon telemetry, manage system controls, and interact safely with the host and service mesh over a browser UI (`Wasm32` + `EventSource` SSE + RFC 6455 WebSocket + WebGPU `/wui`), HTTP/JSON APIs, or `ooda-connect` tunnels.

- **Web & Port Server (`serve`)**: Zero-CDN dark-phosphor UI, `dist/dashboard_ui.wasm` (`--target wasm32-unknown-unknown --shared`), live `EventSource` `dashboard-delta` SSE stream, RFC 6455 WebSocket upgrade, WebGPU SDF/MSDF `/wui`, and token-authenticated control/interact endpoints.
- **`ooda-connect` Bridge (`connect`)**: Reads `$OODA_CONNECT_HOME` / `$OOH_HOME/services.oot` (`name\tkind\ttarget\tcaps_csv`), inspects mesh key readiness, exposes `/api/dashboard/services`, registers `ooda-dashboard` into `services.oot`, and probes TCP service ports.
- **Interactive System Control (`interact`)**: Allowlisted, zero-shell system observation (`overview`, `telemetry`, `services`, `containers`, `realms`, `storage`, `gpu`, `slots`, `connect`) and control transitions (`airgap-on`, `airgap-off`, `regime`, `rollback`, `container-start|stop`, `realm-start|stop|quarantine`, `pool-scrub`, `pool-drain`, `share-revoke`, `gpu-profile`).
- **Privacy-Scrubbed Feedback (`feedback`)**: Built-in `OOFEEDBACK 1` CLI and authenticated `/api/dashboard/feedback` route.

## Usage

```sh
ooda-dashboard [serve] [--host H] [--port N] [--wasm P] [--token T] [--connect-home D] [--once]
ooda-dashboard snapshot | sse [--health-file P] [--panel-file P] [--connect-home D] [--json]
ooda-dashboard connect [status|register|probe] [--host H] [--port N] [--connect-home D] [--json]
ooda-dashboard interact [list|<verb> [target]] [--connect-home D] [--json]
ooda-dashboard status | verify | inspect [subcommand] | theme [name] | about [subcommand] [--json]
```

## Build & Test

```sh
make clean all test det
ooda-verify cycle . --json
```
