# Review — W0-TEXTSCALE — `text_scale` becomes real through one door

Reviewer: adversarial, wave 0 (resumed). Verified against the tree, not the report.
Started 2026-09-14. Findings are appended as they land.

## 1. Diff audit (owned files)

`git diff` read in full for every owned file:
- `game/ui/Theme.gd` (+35/-3): new `const Services = preload(...)`; header comment rewritten; `:34` citation now names `test_a11y_legibility.gd` (arithmetic) and `test_text_scale.gd` (mounted) — both exist on disk; `static func current(who: Node) -> Theme` = `get_theme(scale_of(who))`; `static func scale_of(who: Node) -> int` = `Type.step(int(settings.get_value("text_scale")))` with `Services.find(who,"GameSettings") == null -> Type.SCALE_DEFAULT`. Tabs throughout (cat -A: `^I`). No preload cycle: Services.gd preloads nothing.
- `game/ui/Boot.gd` (1 line): `_overlay.theme = Theme_.current(self)` — four spaces, matches the file.
- 12 screens (AdventureBoard, Completion, Guildhall, LoadSave, MainMenu, Market, RaidPrep, RaidView, RaiderDetail, Results, Tavern, Town): exactly one line each, `theme = Theme_.get_theme()` -> `theme = Theme_.current(self)`, inside `build()`. Market/RaidPrep/Results four spaces, the rest tabs — verified with cat -A and a per-file tab/space count (every owned file is single-style: e.g. Market tabs=0 spaces=517, Town tabs=173 spaces=0).
- `game/screens/Settings.gd` (+40/-3): `var _mounted_scale: int = 100`; `build()` sets `theme = Theme_.current(self)` then `_mounted_scale = Theme_.scale_of(self)`; Restore-defaults lambda gains `_remount_if_rescaled()` after `_refresh()`; Apply lambda gains `_remount_if_rescaled()` after `save_to_disk()`; new `_remount_if_rescaled()` (no-op if `_router == null` or scale unchanged or `current_path()` empty; depth>=2 -> `pop()` then `push(here)`; else `goto(here)`). Tabs throughout. No Label/Button text touched; no node name touched.
- `game/ui/Type.gd`, `game/screens/Facilities.gd`, `game/screens/Roster.gd`: no diff (owned, untouched). Facilities/Roster are `RosterView.new()`/`FacilitiesView.new()` views under Guildhall (Guildhall.gd:237/247), have no `theme =` line and no `.tscn`, so they inherit Guildhall's theme — judgement call 5 checks out against the tree.
- `tests/unit/test_text_scale.gd` (new, 4-space, 6 tests) + Godot-generated `.uid`. Tests: door fallback; mounted Town at 150 measures `Type.at(BODY,150)` on every BODY-variation Label without a font_size override; identity at 100 (same Theme object as `get_theme()`); source-text guard over 14 DOOR_FILES + Theme.gd signatures; Apply at 125 re-mounts keeping depth 2, second Apply no-op, Back lands on Town at 125; Restore defaults at 150 -> 100 re-mount keeping depth 2.

Grep of the tree: `Theme_.get_theme(` survives only in Theme.gd itself (definition + comments) and in `tools/probe/Kit.gd:64` / `tools/probe/Chips.gd:6` (not owned, not screens). `Theme_.current(self)` appears in the 13 routed screens + Boot. Diff adds no `reduced_motion`, `create_tween`, `class_name`, or `_ready` lines.

Files changed in the tree that are NOT in this unit's list (cannot be attributed to this unit by content; other wave-0 units own them): BACKLOG.md, BUILD_STATE.md, README.md, art/ref/manifests/all.json, art/src/vfx/fire_*.aseprite (x3), export_presets.cfg, project.godot, tests/unit/test_{consumables,export,game_state,raider_detail,reputation,rest,savegame,tavern,tutorials}.gd, tools/art/contact_sheet.py, tools/art/gen_icons.lua (D), tools/art/gen_wordmark.py, tools/aseprite/{_libtest,gen_fire,gen_items,gen_wipe,lib}.lua, tools/build_art.sh, tools/diff_all.sh, tools/fixture_reference.gd, tools/probe/Kit.gd, tools/shot.gd, tools/shot_all.sh, tools/verify.sh; untracked: aguildstory.zip, other units' report/handoff/review files, game/assets/enemies/enemies.json, game/assets/ui/{icon.ico,icon_256.png(.import),splash.png(.import)}, tests/unit/test_art_sources.gd(.uid), tools/art/place_enemies.py, tools/aseprite/gen_icons.lua. None of these carry a `Theme_.current`/text_scale change; nothing in the report claims them. Kit.gd/Chips.gd keeping the bare call is consistent with W0-GATE owning Kit.gd this wave.

## 2. Tests and verify --fast (observed)

Run by the reviewer, `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (queued ~4.5 min behind other agents' engine runs; log in scratchpad `verify_fast.log`):
```
== 0/8  lint  PASS  LINT OK / PASS  MOTION LINT OK  tweens and morale glyphs each go through one door
== 1/8  script parse  PASS  PARSE_CHECK scanned 151 script(s)
== 2/8  generated content  PASS  16 generated file(s) agree with tools/gen_items.gd
== 2b/8 generated art  PASS  ART CHECK  generators=5  runtime files: 76 agree  0 DIFFERS  0 MISSING
== 3/8  unit tests  PASS  TESTS PASSED   1604 test(s) in 72 file(s)  [32270 ms]
== 4/8..7/8  SKIP  --fast
VERIFY OK   EXIT=0
```
The runner prints no per-file lines, so the new tests' presence is placed arithmetically: `ls tests/unit/test_*.gd` = 72 files (the runner's 72), `grep -h '^func test_' tests/unit/test_*.gd | wc -l` = 1604 (the runner's 1604), and `test_text_scale.gd` holds 6 of them — the suite has no filter, so a red among the six would have shown as `TESTS FAILED`. `test_a11y_legibility.gd` is one of the 72 (identity-at-100 still green).

`tests/unit/a11y_smoke.gd` (stage 5 is skipped under `--fast`, so run separately through the lock): `A11Y SMOKE PASSED   26 screen mount(s)`; the single `warn fixture AdventureBoard.tscn 10 pointer-only gesture target(s)` is the pre-existing RULES.md:233 / RULES-07 baseline, not new.

## 3. Shots (reviewer-taken)

All through the lock, §0.3's grammar, `SHOT OK ... 1536x1024` printed for each:
- `build/shots/review-W0-TEXTSCALE-Town_text150.png` (`Town --fixture --set=text_scale=150`; shot.gd printed `SETTINGS defaults + { "text_scale": "150" }`). Viewed: the rail labels, header chips, callout titles/subtitles, the speech bubble, the whole right panel, card names/levels/classes, the morale lines and "Recent Events" are all visibly larger than at 100 — the door is live. Clipping, as the report filed (all Town/Frame-owned, W2-TOWN): header chip "Day 23 · Unknown" cut to "Day 23" at x≈1520; right panel lines run off its right edge ("Reputation decides what appears here. R…", "Canon lists this one as a maybe. Disable…") and "Back to menu" is pushed below y=720 out of view; Market callout title reduced to "M" behind the Blacksmith callout (x≈880,y≈450); "Warrior — Very Happ" (x≈155,y≈903); "Available" loses its "12"; rail "Adventure's Board" reaches the rail's edge at x≈210.
- `build/shots/review-W0-TEXTSCALE-Town_text100.png` (`--fixture`, `SETTINGS defaults`). Viewed: the familiar baseline — "Day 23 · Unknown" whole, "Back to menu" at y≈570, "Warrior — Very Happy", "Available 12", the panel's full text. Identity at 100 holds visually.
- `build/shots/review-W0-TEXTSCALE-Settings_text150.png` (`Settings --fixture --set=text_scale=150`). Viewed: the Options page scaled, "Text scale … 150%" on its own row, 17 rows in the ScrollContainer (Language partly below the fold — that is the scroll working, spec 10 §2 R15), sidebar "Save / Load / Back / Restore defaults / Apply" all whole; the same header-chip cut at the right edge as Town (Frame-owned). Readable.
- The implementer's `build/shots/Town_text150.png` was also viewed: identical content to my 150 shot; the report's description of it is accurate.

## 4. Acceptance lines

Plan (`### W0-TEXTSCALE`, 00-plan.md:86-95) and the report's eight boxes, each against the tree:

| # | Line | Verdict | Evidence |
|---|---|---|---|
| 1 | `test_text_scale.gd`: set 150 on the autoload, mount Town via the real router host, assert a Label's `get_theme_font_size("font_size") == Type.at(Type.BODY, 150)` | MET | tests/unit/test_text_scale.gd `test_a_mounted_town_at_150_measures_150` does exactly that (`_router_with_host()` registers a host on the `ScreenRouter` autoload, `r.goto(TOWN)`, every BODY-variation Label asserted `== Type.at(Type.BODY, 150)`); inside `TESTS PASSED 1604` (reviewer run) |
| 2 | identity at 100 (`test_a11y_legibility.gd:256-317` still green) | MET | test_a11y_legibility.gd is one of the 72 files in the green run; `test_a_mounted_town_at_100_is_the_unscaled_theme` additionally pins `screen.theme == Theme_.get_theme()` (same object) and BODY == `Type.BODY`; reviewer's Town_text100 shot is the baseline |
| 3 | `shot_all.sh --sheet=text150` (after W0-GATE) is readable; clipping filed per screen, not fixed | MET (readable) — see note | Reviewer ran W0-GATE's in-tree sheet: `sheet text150: 13 ok, 0 skipped, 0 failed`, `_sheet_1/2/3.png` viewed: every screen renders at 150 with legible, visibly scaled text. Per-screen clipping seen (recorded here because the unit, per §0.2, could not run another unit's in-wave instrument): Town (the five sites in §3); RaidPrep — right panel "~58.5 mistakes" and "Expected mistakes -58.5 / encount…" cut at the panel edge, "Raid 1 — Encounter 5" title cut, bench card "Warrior — Very Happ"; Tavern — "At the bar" panel lines run off the right edge, "Ask around again — 50…" and "Take the room next door — 120 G,…" buttons cut, seat cards' flavour lines overflow; Guildhall — roster cards squeeze so "Shaman — Slightly A…", second card row cut at the panel bottom, tab strip "Records — There is nothing to rec…"; Market — "Consumables in, salvage out" subtitle collides with the header, sell rows cut; RaidView — "E5 — Raid 1 — Enco…" title truncates; Results — fallen names abbreviated ("Sham"); every screen — header chip "Day 23 · Unknown" cut to "Day 23" (Frame-owned). All are layout, not theme; the door works on every screen. |
| 4 | Goal: every screen builds its theme through `Theme_.current(self)` | MET | 13 routed screens + Boot (§1 grep); `Theme_.get_theme(` absent from game/ outside Theme.gd |
| 5 | Settings' Apply rebuilds the current screen | MET | Settings.gd:471-475 Apply -> `save_to_disk()` + `_remount_if_rescaled()`; `test_apply_rebuilds_settings_at_the_new_scale_and_keeps_the_stack` asserts a new instance themed at 125 and depth 2; reviewer's Settings_text150 shot shows the page mounted at 150 |
| 6 | Theme.gd:34's dead citation now points at a real file | MET | Theme.gd:35-36 cites `tests/unit/test_a11y_legibility.gd` and `tests/unit/test_text_scale.gd`, both on disk |
| 7 | Shot `Town --fixture --set=text_scale=150` taken and viewed | MET | Implementer's `build/shots/Town_text150.png` viewed (matches its description); reviewer's retake in §3 |
| 8 | `verify.sh --fast` green; `lint_motion.sh` prints `MOTION LINT OK` | MET | §2 (reviewer run) |

Green line: "no Label text changes; theme assignment does not alter tree order or names; no tween" — MET (§1/§5). `a11y_smoke` both sweeps: 26 mounts, no new warn — MET (§2).

## 7. Report-vs-tree claims

Every factual claim in the report was checked: diff contents (§1), test count and names (§2), verify/lint lines (§2), the Town clipping list (§3), the 14 override sites (spot-checked two). No false claim found. The report's "shot_all.sh --sheet=text150 was not run here — it belongs to W0-GATE" is accurate and plan-conformant (§0.2 forbids relying on another unit's in-wave edit); the reviewer ran it as evidence, not as a requirement.

## 5. Green / §0.5 contracts

- Label/Button texts and node names: the diff touches no string literal a test reads; Settings' `"Apply"` / `"Restore defaults"` buttons keep their text (Settings.gd:461/471), only their `pressed` lambdas grew a call. `test_settings.gd` reads Buttons by text and never presses Apply; `test_a11y.gd` mounts Settings and reads `Nav_*` — unchanged. MET.
- Indentation per file: verified with cat -A on every inserted line and a whole-file tab/space census (§1). MET.
- No `create_tween` outside Widgets, no `reduced_motion` branch: the diff adds neither (grep of `+` lines is empty); `lint_motion` runs in verify stage 0 (observed below). MET.
- No `class_name` references, no `_ready()` logic added: none in the diff. Settings.gd's pre-existing `_ready() -> build()` (:121, guarded by `_built`) is not this unit's. MET.
- No `$GODOT` call outside the lock in any script the unit added: the unit added only `tests/unit/test_text_scale.gd` (no engine invocation). MET.
- New PNGs: the unit produced no game asset; `build/shots/Town_text150.png` / `Town_text100.png` are shots under the gitignored `build/*`. No `.import` needed, no baked text question. MET (n/a).
- Nothing parented to the router host: the re-mount goes through `pop()`/`push()`/`goto()`, each of which runs `_clear_current()` (remove_child + queue_free) before `add_child` (ScreenRouter.gd:289-329), so the host keeps one child. MET.
- Every visible BaseButton FOCUS_ALL / disabled-reason Labels: no button added or altered. MET (n/a).
- Handoff: `build/plan/handoff-W0-TEXTSCALE.md` exists, empty by design, and says why; plan §1 expected "Wave 0 handoffs: none". MET.
- Theme_ door as §0.5 words it ("Every font size passes through Type.at/Theme_.current(self) once W0-TEXTSCALE lands"): the 14 `add_theme_font_size_override` sites the report tables are real (spot-checked Market.gd:685 `Type.STACK`, RaidView.gd:1076 `Type.FIGURE_XL`); the plan's build note explicitly leaves them to their owning units, and the report names each owner. Not a gap in this unit.

## 6. Judgement calls vs plan §6

§6's designer-reserved questions that touch Settings or text: Q14 (Settings control widgets — untouched here, the cycle buttons stay), Q16 (text floor / Type sizes — Type.gd untouched, no size changed). Nothing the unit decided is on the §6 list.

1. pop+push instead of `goto(current_path())`: a build-note detail, not a §6 ruling. Verified against the router: `goto` sets `_stack = [path]` (ScreenRouter.gd:78), so the plan's literal call would leave a pushed Settings at depth 1 and turn Back into `back()`'s root behaviour. pop+push = the two moves the player can make by hand; the screen beneath is re-mounted once on Apply and once more on Back, which is the same idempotent `build()` the router already requires ("Screens expose an idempotent build()", :292-294). No screen defines `on_enter`/`on_exit` (grep is empty), and the only state write in a `build()` on the pop path is `Completion._mark_seen()` (:93, idempotent). Recorded in the report as JC1. Acceptable.
2. No re-mount when the scale is unchanged (`_mounted_scale`): within "Apply rebuilds the current screen" — a volume-only Apply not restarting the page is the conservative reading. Acceptable, and tested.
3. Restore defaults also re-mounts: it writes the file (`reset_all()` + `save_to_disk()`) exactly as Apply does, so the same RULES-02 hole would have stayed open. In an owned file, additive, tested. Acceptable.
4. `scale_of(who)` as a second static: additive; the plan's `current` exists verbatim. Acceptable.
5. Facilities/Roster not themed separately: verified (§1). Acceptable.
6. Kit.gd/Chips.gd keep the bare call: not owned (Kit.gd is W0-GATE's this wave); tools/probe is not a screen. Acceptable; the source-text test's DOOR_FILES is the 13 routed screens + Boot, which is the plan's set.

Note (minor, pre-existing practice): `test_text_scale.gd`'s Apply/Restore tests call `save_to_disk()`/`reset_all()` on the GameSettings node, which writes the real `user://settings.cfg` — `test_settings.gd` already writes, corrupts and deletes that file, so the suite as a whole never respected it; not new.

## Verdict

**PASS.** No blocker, no unmet acceptance line, no unowned file touched, no false claim, no §6 ruling taken. Minors (none needs a fix before the wave merges):

1. Settings.gd:116 `var _mounted_scale: int = 100` hard-codes the default a second time; `Type.SCALE_DEFAULT` would keep one copy. Cosmetic — `build()` overwrites it before any read.
2. Apply at depth >= 2 mounts the screen beneath once (`pop()`) and again on the player's Back — an idempotent extra mount, plan-conformant (the router's `build()` contract), but W3-OPTIONS could add a router `replace()` if a screen beneath ever grows a costly `build()`.
3. The text150 sweep's per-screen clipping outside Town is filed only in this review (§4 row 3), not in the unit's report — the unit could not run W0-GATE's in-wave instrument, so the orchestrator should hand §4 row 3's list to W2-TOWN / W4-PREP / W2-TAVERN / W1-HALL-W3-ROSTER / W2-MARKET / W2-RAIDVIEW / W2-RESULTS / W1-FRAME when those units start.
4. `test_text_scale.gd`'s Apply and Restore-defaults tests write the developer's real `user://settings.cfg` (as `test_settings.gd` already does) — pre-existing suite behaviour, noted for W4-HYGIENE.

Reviewer-produced files (all under gitignored `build/shots/`): `review-W0-TEXTSCALE-Town_text150.png`, `review-W0-TEXTSCALE-Town_text100.png`, `review-W0-TEXTSCALE-Settings_text150.png`, `review-W0-TEXTSCALE-all/text150/`. Scratch logs in the session scratchpad. This file is the only tree edit.
