# Report — W0-TEXTSCALE — `text_scale` becomes real through one door

Unit: wave 0, 00-plan.md §1 "W0-TEXTSCALE". Findings closed: RULES-02 (P1), CRITIC-G15 (the door half).
Owned: game/ui/Theme.gd, game/ui/Type.gd, the fifteen game/screens/*.gd, game/ui/Boot.gd, tests/unit/test_text_scale.gd (new).
Handoff: build/plan/handoff-W0-TEXTSCALE.md (empty by design — every edit is in an owned file).

## Acceptance

- [x] `Theme_.current(who)` exists in Theme.gd, reads `text_scale` via `Services.find(who, "GameSettings")` (absent → 100) and returns `get_theme(pct)`.
- [x] Every one of the thirteen screens' `build()` and Boot's overlay set `theme = Theme_.current(self)`; no bare `Theme_.get_theme()` call remains outside Theme.gd.
- [x] Settings' Apply rebuilds the current screen at the new scale.
- [x] Theme.gd:34's citation of `tests/unit/test_text_scale.gd` points at a real file.
- [x] `tests/unit/test_text_scale.gd`: set 150 on the autoload, mount Town through the real router host, a Label measures `Type.at(Type.BODY, 150)`; identity at 100.
- [x] `test_a11y_legibility.gd:256-317` still green (identity at 100).
- [x] Shot `Town --fixture --set=text_scale=150` taken, viewed, described here.
- [x] `verify.sh --fast` green; `lint_motion.sh` prints `MOTION LINT OK`; summary lines pasted below.

## Judgement calls

1. **Apply re-mounts by pop+push, not `goto(current_path())`.** The plan's build note says
   `router.goto(router.current_path())`; the router's `goto` sets `_stack = [path]`, so on a
   PUSHED Settings (Esc from the camp — the common case) it would turn Back into a trip to the
   main menu. The first agent chose: depth >= 2 → `pop()` then `push(here)`; depth 1 → `goto`.
   Same visible result, stack preserved. Kept; `test_apply_rebuilds_settings_at_the_new_scale_and_keeps_the_stack`
   pins `depth() == 2` after Apply and Back landing on Town at the applied scale.
2. **No re-mount when the scale did not change.** `_mounted_scale` is recorded in `build()`;
   Apply with only a volume/aspect change leaves the page alone (a second Apply at the same
   scale is asserted not to restart the screen).
3. **Restore defaults takes the same exit (added this run).** It calls `save_to_disk()` like
   Apply, so a page still drawn at 150 over a saved 100 would be RULES-02 in miniature. One
   line (`_remount_if_rescaled()` after `_refresh()`) + one test. Within the unit's goal
   ("Settings rebuilds the current screen"), in an owned file.
4. **`scale_of(who)` is a second public door beside `current(who)`.** The plan names only
   `current`; the 14 hand-set font-size sites (below) need the pct, not the Theme, so
   `Type.at(size, Theme_.scale_of(self))` is the route later units use. Additive, no caller yet.
5. **Facilities.gd / Roster.gd are not themed separately.** They are Guildhall's tab bodies
   (no .tscn, mounted under the Guildhall root) and inherit its theme; a second assignment
   would be redundant. `DOOR_FILES` in the test lists the 13 routed screens + Boot.
6. **`tools/probe/Kit.gd` and `Chips.gd` keep the bare `get_theme()`.** Not owned (Kit.gd is
   modified by another unit right now), not screens, and the probe deliberately shows the
   unscaled kit; the source-text test guards only the 14 door files.

## Left for the screen units (CRITIC-G15's other half — NOT this unit's per the build notes)

Fourteen sites bypass the theme with `add_theme_font_size_override("font_size", <const>)` and
so stay at 100 whatever the player chose. The door for each is
`Type.at(<const>, Theme_.scale_of(self))`; the owning unit per 00-plan.md's tables:

| File:line | Const | Owner |
|---|---|---|
| Market.gd:685 | Type.STACK | W2-MARKET |
| RaiderDetail.gd:363, :488 | Widgets.SIZE_META | W3-DETAIL |
| RaidPrep.gd:326, :414 | Widgets.SIZE_META | W4-PREP |
| RaidView.gd:480 | Type.SMALL | W2-RAIDVIEW |
| RaidView.gd:1076, :1098 (wipe stamp) | Type.FIGURE_XL | W3-RAIDVIEW2 |
| Results.gd:337, :588 | Type.SECTION / Type.SMALL | W2-RESULTS |
| Roster.gd:312, :517, :530 | Widgets.SIZE_META | W3-ROSTER |
| Roster.gd:478 | Type.SMALL | W3-ROSTER |

## Town at 150 — what the shot shows (filed per screen, not fixed here)

`build/shots/Town_text150.png` vs `Town_text100.png` (both `--fixture`, 1536x1024): the door
is live — every Label the theme owns is visibly larger at 150: header chips, rail labels,
callout titles/subtitles, the speech bubble, the right panel, card names/levels/classes, the
morale line, "Recent Events". Layout at 150 clips in five places, all Town-owned (W2-TOWN):
- Header chip strip overflows right: "Day 23 · Unknown" is cut to "Day 23" at the frame edge.
- Right panel: no autowrap on its lines, so "Reputation decides what appears here. Raids
  raise reputation." and every "X — Y" description run off the panel's right edge; the panel
  grows past the bottom of its region and "Back to menu" is pushed out of view.
- Market callout: the title is hidden behind the Blacksmith callout (only "M" shows).
- Card strip: "Warrior — Very Happ" truncates the state word (docs/13 §4.4 forbids exactly
  this); the "Available 12" count is pushed off the panel; the fifth card ("Recent Events")
  keeps its width so the four raider cards squeeze.
- Rail: "Adventure's Board" overruns the rail's 210px and is clipped by the scene.
At 100 the shot is unchanged from the pre-door baseline (same theme object, identity by
construction).

## Log

(one entry per landed item: what was done, what was seen)

### Resume (2026-09-14 08:30) — second agent
The first agent was killed by a usage limit with no box ticked. `git diff` on every owned file
shows its edits landed: Theme.gd `current(who)` + `scale_of(who)` (+35), the thirteen screens'
and Boot's one-line `theme = Theme_.current(self)`, Settings.gd `_mounted_scale` +
`_remount_if_rescaled()` (+37), and tests/unit/test_text_scale.gd (5 tests). Boxes below are
ticked only as each is re-verified against the tree in this run.

### Verified this run (08:30-08:50)
- Theme.gd: `static func current(who: Node) -> Theme` = `get_theme(scale_of(who))`; `scale_of` uses
  `Services.find(who, "GameSettings")`, null → `Type.SCALE_DEFAULT` (100), else `Type.step(int(get_value("text_scale")))`.
  Doc comment at :34 now cites test_a11y_legibility.gd (arithmetic) and test_text_scale.gd (mounted) — both real.
- `grep -rn "get_theme(\|Theme_.current" game/`: 13 screens + Boot.gd set `theme = Theme_.current(self)`; no bare
  `Theme_.get_theme(` left under game/ (the two remaining are tools/probe/Kit.gd and Chips.gd — not screens, not owned).
  Indentation checked per file: Market/RaidPrep/Results/Boot spaces, the rest tabs (diff shows one line each).
- Settings.gd: `_mounted_scale` set in build(); Apply → `save_to_disk()` + `_remount_if_rescaled()`; added the same
  call to Restore defaults (judgement call 3). `_remount_if_rescaled`: no-op when scale unchanged; depth>=2 pop+push,
  else goto. Router's `_clear_current` detaches then `queue_free`s, so re-mounting from inside the button's own
  handler is safe (LESSONS "never free from a signal handler").
- Parse check: `PARSE_CHECK scanned 151 script(s) / PARSE_CHECK OK` (08:42).
- Shots retaken under the lock: `SHOT OK build/shots/Town_text150.png 1536x1024` and `Town_text100.png`
  (`SETTINGS defaults + { "text_scale": "150" }` / `"100"` printed by shot.gd). Both viewed with Read; described
  above under "Town at 150". The 150 shot is unmistakably scaled (rail labels, chips, callouts, cards, side panel);
  the 100 shot is the familiar baseline.
- Unit suite (whole, no filter): `TESTS PASSED   1604 test(s) in 72 file(s)  [32489 ms]` — 1603 before +
  `test_restore_defaults_rebuilds_settings_at_100_and_keeps_the_stack`. test_text_scale.gd now has 6 tests:
  door reads autoload/falls back to 100; mounted Town at 150 measures `Type.at(BODY,150)` on every BODY Label;
  mounted Town at 100 holds the very unscaled theme object; every door file names `Theme_.current(self)` and none
  `Theme_.get_theme(` (source-text guard); Apply re-mounts at 125 keeping depth 2, second Apply is a no-op,
  Back lands on Town at 125; Restore defaults re-mounts at 100 keeping depth 2.
- test_a11y_legibility.gd is in the 72 files and green (identity at 100 preserved: `get_theme()` and
  `get_theme(100)` are one cache entry, asserted in test_the_door_reads_the_autoload_and_falls_back_to_100).
- `tools/lint_motion.sh` (08:50): `MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)`.
- `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (08:50):
  ```
  == 0/8  lint  PASS  LINT OK / PASS  MOTION LINT OK
  == 1/8  script parse  PASS  PARSE_CHECK scanned 151 script(s)
  == 2/8  generated content  PASS  16 generated file(s) agree with tools/gen_items.gd
  == 2b/8 generated art  PASS  ART CHECK  generators=5  runtime files: 76 agree  0 DIFFERS  0 MISSING
  == 3/8  unit tests  PASS  TESTS PASSED   1604 test(s) in 72 file(s)  [32643 ms]
  == 4/8..7/8  SKIP  --fast
  VERIFY OK  (full log: .verify.log)
  ```

## Done / not done
All eight acceptance lines hold. Nothing in the unit was impossible as written. Not done by
design (plan's build notes): the 14 hand-set font-size sites (table above) and the per-screen
clipping at 150 (Town list above; the `--sheet=text150` sweep is W0-GATE's instrument and each
screen unit's acceptance). `tools/shot_all.sh --sheet=text150` was not run here — it belongs to
W0-GATE, which is editing shot_all.sh in this same wave.
