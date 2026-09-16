# review-W6-SETTINGS — brief review (2026-09-15)

## Shots
- `build/shots/review-W6-SETTINGS.png` (`Settings --fixture=new`, 1536x1024, viewed): header reads "Options" alone, no "N of M"; fifteen rows at one pitch, no padlock, no reason text anywhere; the sidebar's second paragraph is the F11 / Alt+Enter / Esc line (no "data/tuning" sentence). "Colour-safe morale ramp" row with ten swatches beside its chip (Off = red→green), "Window" row (Fullscreen), V-sync live, "Audio — music and ambience" with an empty note column. Nothing overlaps, nothing off the frame, no blank panel.
- `build/shots/review-W6-SETTINGS-cvd.png` + `-cvd-crop.png` (`--set=colourblind_safe=true`, viewed): the ramp row's swatches turn dark red → ochre → olive → teal and the chip reads "On". The headline change shows.

## Tests (this unit's files only)
- `RUN_TESTS_ONLY=test_settings,test_options_layout,test_a11y_legibility` → `TESTS PASSED 79 test(s) in 3 file(s)`, 0 failing. The two event-log sign tests the report listed as red (`test_a11y_legibility.gd:657-690`) are green on the tree as of this run.
- Shot runs parsed and mounted Settings cleanly (only the usual RID-leak-at-exit noise).

## Ownership
- `git status --porcelain`: changed files are exactly the owned set (Settings.gd, GameSettings.gd, Boot.gd, Palette.gd, ScreenRouter.gd, project.godot, test_settings.gd, test_options_layout.gd, test_a11y_legibility.gd) plus the unit's three plan files (report/handoff/q). No unowned file touched. `project.godot` diff is additive (`window/size/mode=3`, `nav_fullscreen` F11 + Alt+Enter).

## Audit closures
- **M6-EXP-07** — yes: the row exists in audit.json (W6-LEDGER filed it); `project.godot` opens fullscreen, `GameSettings.apply_window_mode()`/`windowed_size()`, `Boot._apply_window_mode()`, the Window and V-sync rows are live, `ScreenRouter.toggle_fullscreen()` on `nav_fullscreen`; held by test_settings.gd's four SHIP-06 tests (all green). docs/14 §10.4 residue is correctly parked in q-W6-SETTINGS.md.
- **M6-A11Y-06** — not claimed closed; the report's "switch built, ruling pending" status is accurate (option + row + `Palette.cvd_safe()` + tests exist; plate call sites are handoff §1-§2).

## Notes (minors)
- Judgement call 1 (HIDDEN_ROWS as a second const rather than a `hidden` flag) diverges from the Build note's letter but keeps `test_text_scale_layout.gd:1255`'s ROWS walk green without a cross-file edit — reasonable.
- The Music row's description cell is empty until W7-AUD-AMB; the contract says "no note", so as specified.
- Handoff §5-§7 (`-w` on shot_all/diff_all/verify.sh:322) is worth applying at the close: without it every non-headless tool run now flashes a fullscreen window.

## Verdict
**pass** — headline change visible in both shots, 79/79 own tests green, tree parses, only owned files changed.
