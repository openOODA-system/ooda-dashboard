# `ooda-dashboard` Agent Rules

1. **Repository Scope**:
   - Canonical package: `ooda-dashboard` (`v0.1.0`, `layer=system`, organization `openOODA-system`).
   - Core subsystems:
     - `core/store/`: Reactive `RxDashboardStore` (`Signal`/`Memo`/`Effect`/`Node`), firewall/airgap/A-B slot/container/realm/OODA-Pool/OOFN1/GPU transitions, `ooda-health` SSE and `ooda-panel` JSON ingest.
     - `core/connect/`: `ooda-connect` home resolver, `services.oot` catalog loader/writer, identity readiness, and `TcpCap` port prober.
     - `core/interact/`: Allowlisted zero-shell system query and control dispatcher (`overview`, `telemetry`, `services`, `airgap-on`, `regime`, `rollback`, etc.).
     - `core/http/` & `core/ui/`: HTTP/1.1 + SSE (`dashboard-delta`) + `ooda-standard/net/websocket_grp` RFC 6455 WebSocket router, dark-phosphor HTML dashboard, WebGPU SDF `/wui`, and `OOFEEDBACK 1`.
     - `core/wasm/` -> `dist/dashboard_ui.wasm`: Wasm32 shared library with `oo_dash_*` and `oo_wui_*` exports.
   - CLI entrypoints: `cli/main.oo`, `cli/cmd.oo`, `cli/connect_cli.oo`, `cli/about.oo`, `cli/guard.oo`, `cli/version.oo`.

2. **Language, Toolchain & Imports**:
   - Pure `.oo`/`.oot` source only (`~/.openooda/bin/ooda-compiler`, `~/.openooda/ooda-standard`, `~/.openooda/bin/ooda-verify`). Zero `.c`, `.h`, `.py`, `.html`, symlinks, or hardlinks.
   - Always import `ooda-standard/` (`import "ooda-standard/..."`), and unset `OODA_OOSTD_ROOT` on external builds.
   - Keep every declared capability explicitly exercised (`TcpCap`, `BindCap`, `FsReadCap`, `FsWriteCap`, `ProcessCap`, `TimeCap`, `EnvCap`) with zero unused caps.

3. **Power-of-2 Shape & Security Laws**:
   - `16..256` lines per `.oo` page (pure-import shims exempt from floor), `<= 8` `.oo` pages/directory, `<= 8` functions/page, `<= 8` parameters/function, `<= 64` SLOC/function, `<= 4` nesting depth, `<= 128` code columns, `<= 1` semicolon/line, zero raw tabs.
   - 4-element Academy headers (`// # `, `// Logline:`, `// Setup:`, `// Beats:`) at top of every `.oo` page.
   - Exit `2` fail-closed on unknown flags, retired `--persona`/`--mode`/`--personas`/`--list-personas`, bad `about`/`inspect`/`theme` targets, unknown `argv[0]`, `-- -x` flag-as-operand, `..` / `%2e%2e` traversal, shell metacharacters, and control bytes.

4. **Verification Gate**:
   - Run `make clean all test det` and `~/.openooda/bin/ooda-verify cycle . --json` (`quorum_mask=255`).
   - Do not modify `~/.openooda/` or external `.github/workflows/*.yml` outside authorized tasks.
