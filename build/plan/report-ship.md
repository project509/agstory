# report-ship.md — M6 ship-readiness (export, playtest sweep, balance report)

Agent key: `ship`. Items: M6-EXP-01, M6-EXP-02, M6-EXP-05, M6-PLAY-01, M6-PLAY-02,
M6-BAL-01, M6-BAL-02 (+ the M6-BAL-03 proposal the audit asked to be *prepared*).

Written as each item finished, not at the end.

---

## M6-EXP-01 — `export_presets.cfg` (DONE)

`export_presets.cfg` (new). Two presets:

- `[preset.0]` **Windows Desktop** / `x86_64`, `export_path="build/exports/TheWorstGuild.exe"`,
  `binary_format/embed_pck=false`, `application/icon="res://game/assets/ui/emblem.png"`,
  product/company/file-version strings set. docs/14 §10.1 (target + command), §10.3
  (committed, no secrets).
- `[preset.1]` **Linux x86_64**, `export_path="build/exports/TheWorstGuild.x86_64"`.
  docs/14 §10.1's "second target from day one". Templates are present
  (`4.7.1.stable.mono/linux_release.x86_64`), so it cost one preset. It is
  **export-only** — nothing here can launch a Linux binary, and the script says so
  rather than implying it was verified.

Two findings the audit did not have:

1. **`debug/export_console_wrapper` must be `2`, not `1`.** The audit specifies `1`.
   Measured: `1` is "Debug only" and this script only runs `--export-release`, so `1`
   produced **no** `TheWorstGuild.console.exe` and the launch check had nothing to run.
   Recorded at `export_presets.cfg:23-30`. First auditor detail that was wrong.
2. **The icon question was already settled by another wave.** M6-EXP-04 says
   `project.godot:8` points at a non-existent `res://icon.svg`. It now reads
   `config/icon="res://game/assets/ui/emblem.png"` (project.godot:14). The preset
   matches that path rather than inventing an app icon. The Windows `.exe` resource
   icon still wants a real `.ico`; that gap stays in `build/plan/q-housekeeping.md`.

Audit acceptance: `grep -c '^\[preset\.0\]'` == 1; no `password`/`keystore` string;
`.gitignore` ignores `/build/*` only, so the file is committable.
`.gdignore` coverage (M6-EXP-03, not mine) is already complete.
