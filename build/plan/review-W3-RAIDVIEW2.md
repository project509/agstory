# review-W3-RAIDVIEW2 — adversarial review (verify against the tree)

Reviewer: subagent, 2026-09-14. Unit: W3-RAIDVIEW2 (game/screens/RaidView.gd, tests/unit/test_raid_beats.gd).
Written as I go; findings in order of discovery, verdict at the end.

## 1. Ownership (git status / diff)

- `git status --porcelain`: owned files changed: `M game/screens/RaidView.gd` (+513/-56), `?? tests/unit/test_raid_beats.gd` (599 lines, spaces). Plan files `report-W3-RAIDVIEW2.md`, `handoff-W3-RAIDVIEW2.md` untracked (new).
- Files changed that are NOT in the owned list (other units own them; not attributable to this unit unless the diff says so): GameState.gd, Completion.gd, Facilities.gd, Guildhall.gd, LoadSave.gd, MainMenu.gd, RaiderDetail.gd, Roster.gd, Settings.gd, Town.gd, Badge.gd, Boot.gd, Cards.gd, SceneStage.gd, Widgets.gd, test_scene_stage.gd, test_widgets_kit.gd, gen_actors.py, enemies.json, actors/**, docs/13-ui-ux.md, bg/boss_sludge_maw.png (D), new PaperDoll.gd, gen_boss_anims.lua, art/src/enemies, game/assets/enemies/anim — all match other wave-3 units' ownership rows. Nothing in RaidView's diff touches them.
- The ` M` on 12 wave-0/1 plan files + docs/13: `git diff --stat -- build/plan/` is EMPTY (line endings only, as the report says). `build/.gdignore` exists (0 bytes).
- `build/shots/w3rv2_*.sh/.py` helper scripts: `/build/*` is gitignored, so not in status; checked below for direct `$GODOT` calls.

## 2. Diff read (game/screens/RaidView.gd, +513/-56; tests/unit/test_raid_beats.gd, 599 lines)

Read in full. What the diff actually does:
- `_boss_sprite: Sprite2D` -> `Node2D` (:162-165). New members `_dying`, `_boss_fallen`, `_paused_stamp`, `_dwelling`, `_back_button/_onward_button/_exit_boxes/_exits_gated`.
- Header docstring block (:238-254) rewritten: names `wipe_blot.png`, `wax_seal.png`, `gen_wipe.lua`, `build_art.sh --check`; the t=1,800 slide is tied to Q09. `grep -nE "has no blot|art that does not exist|pending|owed|placeholder"` over RaidView.gd -> 0 hits (only `_scroll_pending`, a variable).
- `WAX_SEAL_INSET`/`WIPE_STAMP_Y` replaced by `WAX_SEAL_REST := Vector2(1440, 946)` and `WIPE_STAMP_RECT := Rect2(1044, 781, 474, 90)` (inside LOG_RECT 1044,741,474,240). Neither was a RULES §1 contract name (the contract list is WIPE_BEAT_*, WIPE_STAMP_MS/FROM/TILT_DEG/FLOOR_MS, WIPE_DIM, WIPE_BLEED_MS, WIPE_BLOT, WAX_SEAL, FRAME — all present and unchanged).
- `EXITS_GATED := false`, `EXITS_REASON`, `PAUSED_STAMP_AT`, `BOSS_AFFIX_CELL 30`, `BOSS_AFFIX_PITCH 34`, `VFX_FAMILY` (9 rows keyed by `Enums.ROLE_KEYS`), `BOSS_FAMILY`, `MECHANIC_BURST := "void"`.
- `_boss_plate`: sigil = `Icons.at("sigil", rank)` guarded by `Icons.exists`, rank from `_boss_rank_key()` = basename of `Cards.encounter_sprite(_encounter).resource_path` (`boss_main_2` -> `sigil_boss_main_2.png`; the five sigil PNGs exist under game/assets/ui/icons/grid/, no `sigil_boss_trash` so the body fallback covers trash); cells 30px at `1001 + 34*i, 122`. Name Label stays `_encounter.display_name` (Q12a).
- `_footer`: keeps `_retry_button = back`; adds `_back_button/_onward_button`; `_gate_exits()`/`_release_exits()` through `Widgets.reasoned`/`Widgets.button_of` (both at HEAD Widgets.gd:617/:687); gate called only under `EXITS_GATED`; `_process` and `_on_skip` call `_release_exits()`.
- `_refresh_party_sprites`/`_settle_lifts`: skip the tint while `_dying_now(id)`.
- `_line_effects`: the W2 interim one-frame `_lift(target, TEXT_BODY, 0)` on ATTACK is REMOVED (the stage's `hit` flashes now); the actor's 1.15 lift is skipped for a fallen actor.
- `_reset_player`: clears `_dying`, `_boss_fallen`, zeroes every figure's and the boss's rotation (a replay stands the toppled up).
- `_sync_controls`: drops `_dwelling` when unpaused; shows `_paused_stamp` iff paused and dwelling.
- `_dwell_on`: on a mistake sets `_dwelling`, `_paused_stamp_up()` (a `Widgets.stamp("PAUSED — mistake", Palette.CAUTION)` Label named `PausedStamp`, MOUSE_FILTER_IGNORE, direct child of the screen, right edge at x 1506, y 745), grabs focus on Pause guarded by `is_inside_tree()`.
- `_wipe_stamp`: stamp box centred in WIPE_STAMP_RECT, blot first (`_bleed_under` before `add_child(box)`), 3px GROUND_PAGE outline on the word, a `WipeCostPlate` ColorRect strip + `WipeCost` Label beneath. `_drop_seal`: rest = WAX_SEAL_REST. `_wipe_exits`: grab_focus guarded by `is_inside_tree()`.
- `_append_line`: `_round_marker()` (HBox: "Round N" Label + `Rule` ColorRect EDGE_SLATE 1px, SIZE_EXPAND_FILL); PHASE lines become a slate LabelSmall heading (no settle/age/verb/bar switch) and return early after `_fold_to`; every row and joke indent goes through `_settle()` (a `Settle` MarginContainer, margin_top 1->0 via `Widgets.tween(wrap).tween_method(...)` over `_settings.motion_duration(Widgets.Motion.LOG_SETTLE)`; null tween or not `_live` -> 0 at once); `_stage_verbs(e)` after `_fold_to`/`_follow`, before `_refresh_bars`.
- `_stage_verbs` and beats: ATTACK -> `act(attacker,"attack",{toward})` + slash(+burst) or bolt per family + `hit(target,{from})` (boss always; raider only if not fallen), then `_boss_death_beat()`; HEAL -> `act(healer,"cast")` + burst(support kind) on the target; MECHANIC -> burst("void") at `_eye_of(boss)`; STATE_CHANGE death -> `act(spr,"death")` and `_dying[id] = _clock + ACTS.death.ms`; MISTAKE -> `act(spr,"fumble",{toward: boss body})`. Flourishes only while `_live`; deaths always.

Rule 7 check — every SceneStage function the screen calls, against `git show HEAD:game/ui/SceneStage.gd` (the wave's start):
`place_boss` :419, `head_of` :500, `hit` :760, `act` :809 (returns bool; ACTS const :146 with `death.ms = 400`), `add_fx` :1010, `burst(pos, kind, opts)` :1090, `slash(pos, opts)` :1145, `bolt(from, to, kind, opts)` :1156, `apply_settings` :1813, `motion_held` :457. All exist at HEAD with the same arity the screen uses. `Icons` "sigil" group at HEAD Icons.gd:45/:55; `Widgets.Motion.LOG_SETTLE = 90` at HEAD Widgets.gd:102; `Widgets.stamp(text, Color)` :325, `stamp_box` :346, `reasoned` :617, `button_of` :687, `slot` :808, `tween` :1376 at HEAD; `LogPlayer.is_death` (LogPlayer.gd:198, file unchanged); `Enums.Verb.PHASE`, `Enums.ROLE_KEYS`, `Enums.role_key` in sim/model/Enums.gd. No function another wave-3 unit is adding is named. PASS.

## 3. §0.5 / Green-line checks (tree, not report)

- Indentation: RaidView.gd 0 space-led lines (2454 lines, tabs); test_raid_beats.gd 0 tab-led lines (spaces). PASS.
- `create_tween` in RaidView.gd: 0. `await get_tree` : 0. `reduced_motion` : 1 hit, a comment (:1707). PASS.
- `"WIPE."` string: exactly one construction site (:1758 `Widgets.stamp_box("WIPE.", "danger")`). PASS.
- WIPE contract literals present: `func _run_wipe_sequence(elapsed_ms: float)`, `_run_wipe_sequence(float(WIPE_BEAT_EXITS_MS))`, `if _wipe_beats.has(method)`; members `_wipe_shown/_wipe_dim/_wipe_blot/_wax_seal/_wipe_stamp_label` unchanged; blot added before the box on the SCREEN (`_bleed_under` at :1767 precedes `add_child(box)` :1768). PASS.
- `_ready()` unchanged from HEAD (`build()` only). No `class_name`. New overlays (`PausedStamp`, `WipeCostPlate`, `WipeCost`, `Rule`, round marker) are MOUSE_FILTER_IGNORE; `Settle` wrapper is PASS (a container in the column, not an overlay). PASS.
- Label/Button texts read by tests: "Back to the board", "The report", "Pause"/"Resume", "Round %d", "Mistakes this attempt  %d", "Skip to the end" reasons untouched; "WIPE." kept; the cost line verbatim. New texts are additive ("PAUSED — mistake", "The account is still being read" only under the false switch). PASS.
- Disabled controls with reasons: the gated exits (behind the switch) go through `Widgets.reasoned` — reason Label adjacent. PASS.
- No new PNGs, no .import needed. Assets: none (as the plan says). PASS.
- Nothing parented to the router host: everything new is `add_child` on the screen or `_log_col`. PASS.
- Handoff: two observations, no edits; `python tools/apply_handoff.py build/plan/handoff-W3-RAIDVIEW2.md --dry-run` -> "no edits found" (exit 1, the tool's nothing-to-apply answer; parses). PASS.
- Helper scripts `build/shots/w3rv2_batch1.sh` / `w3rv2_batch2.sh` call `"$GODOT"` directly inside the script; they are batch files meant to be run under ONE `with_godot_lock.sh` (the report says "one lock" per batch and the lock's `holder` is not on the tree, so unverifiable). MINOR: the scripts carry no guard of their own, so a re-run by hand without the wrapper would run unguarded. `w3rv2_restore_plan.py` uses `git ls-files --deleted` + `git show` only (read-only; no checkout/reset/clean). PASS on rule 1.


## 4. verify --fast, run by the reviewer (22:53-23:03, through the lock; log build/shots/review-W3-RAIDVIEW2-verify.log)

PASS class cache · PASS LINT OK · PASS MOTION LINT OK · PASS PARSE_CHECK 173 scripts · PASS 16 generated files agree · PASS ART CHECK 197 agree 0 DIFFERS 0 MISSING · **FAIL unit tests `TESTS FAILED 7/1908`** · SKIP x4 (--fast) · VERIFY FAILED.
The 7 reds: test_menu_lockup.gd (W3-MENU), test_options_layout.gd (W3-OPTIONS), test_roster_layout.gd x2 (W3-ROSTER), test_text_scale.gd `test_every_screen_builds_its_theme_through_the_door` (Guildhall.gd:347 `Theme_.get_theme()` — W3-ROSTER; RaidView.gd:381 uses `theme = Theme_.current(self)` and has no bare call), test_widgets_kit.gd x2 (W3-KIT2). Zero FAIL rows for test_raid_beats (24 tests), test_wipe_sequence, test_log_player, test_raid_overlays; no SCRIPT ERROR naming RaidView. The unit-test stage is red only on other units' in-flight files — noted, not charged. (test_scene_stage's manifest test, red in the unit's run, is green now: W3-ENEMIES moved on.)
verify_fast_observed = fail (other units' files).

## 5. Shots re-taken by the reviewer (§0.3 grammar, one lock per batch; all viewed with Read)

- `review-W3-RAIDVIEW2-adv10.png` (40 frames, `--fixture=raid --advance=10`; ADVANCE 10 revealed=10/160): two staggered "-4" numbers over the boss (the last ATTACK "Pip hits Main Boss for 4"), "-30/-30" over Bork, a "!" over Tiny at the right of the front rank; at frame 40 the bursts had already dispersed. `review-W3-RAIDVIEW2-adv10_f8.png` (8 frames, same flags) + `_f8_crops.png` (2x): a pink additive impact starburst over the boss's maw AND one over Bork, "!" over the mid-fumble figure, five affix cells at pitch 34, the 48px jaw sigil in the plate slot. S1 met (the beat is real; the 40-frame grammar is simply past the burst's life in this run — the unit's own 40-frame take caught it, mine did not).
- `review-W3-RAIDVIEW2-all.png` (`--advance=all` via `_on_skip()`) + `_all_log_x2.png`: WIPE. box across the log panel (centre ~1281,826 inside LOG_RECT), the blot bleeding under it inside the panel, the cost line on its 0.92 strip beneath, the seal straddling the panel's lower-right corner (1440,946 -> its bottom past the panel's 981), "[R11] WIPE." as the last row, "Round 11" with the hairline rule to the panel's right edge, twelve grey toppled figures under skull plates, "Back to the board" focused. S2 met. The word reads through its GROUND_PAGE outline on the red blot — legible, low contrast at 1x (minor, below).
- `review-W3-RAIDVIEW2-paused.png` (`--set=log_manual_advance=true --advance=3`; ADVANCE 3 revealed=2/160 — the account stops on Greg's mistake at line 2) + `_paused_strip.png`: "PAUSED — mistake" in CAUTION, leaning, top-right of the log panel; the Pause button reads "Resume" and wears the steel focus ring; Greg's panel rimmed. S3 met.
- `review-W3-RAIDVIEW2-rm_all.png` (`--set=reduced_motion=true --advance=all`) + `_rm_all_log_x2.png`: the same page; PIL diff vs the motion take inside the log panel region is confined to the stamp's own rect (bbox (125,18)-(354,147) in panel space) — the press's end state vs the direct set; static lean present, no tilt motion. S4 met.
- refdiff (python, no engine) on the unit's `W3RV2_fixture.png` vs 2 masked 210,77,928,640: mae 34.058 / layout_iou 0.1185 / within-8 24.77 — the numbers the report states; W2's recorded 34.031 -> no regression.

## 6. Acceptance lines (00-plan §W3-RAIDVIEW2)

| Line | Met | Evidence |
|---|---|---|
| `--advance=10` shows a slash or burst over the last ATTACK's target and a mid-fumble figure with "!" | yes | review-…-adv10_f8_crops.png (burst on the boss's maw; "!" over Tiny); code `_attack_beat` :2142-2167, `_fumble_beat` :2229 |
| `--advance=all` shows the stamp across the log panel, the blot under it, the seal at the panel's lower-right | yes | review-…-all_log_x2.png; `WIPE_STAMP_RECT` :286, `WAX_SEAL_REST` :280, `_bleed_under` before `add_child(box)` :1767-1768 |
| `--set=log_manual_advance=true --advance=3` shows the PAUSED stamp with Pause focused | yes | review-…-paused_strip.png; `_dwell_on` :1618-1630, `_paused_stamp_up` :1635 |
| test_raid_beats.gd: trigger table fires a stage verb per Verb through `from_data` stubs; flash-rate test; paused Label exists | yes | 24 tests, 0 FAIL rows in the reviewer's verify (TESTS 7/1908 failing, none in this file); `_probe()` uses `SceneStage.from_data`; `test_at_two_x_no_panel_swaps…` counts add/remove of the "panel" override (the rim really is add/remove, :1441-1450, so the count is meaningful); `test_the_dwell_raises_the_paused_stamp…` |
| test_wipe_sequence.gd green unchanged; test_log_player.gd green | yes | no FAIL rows for either in the reviewer's verify; `git status` shows neither file modified |
| RaidView.gd contains no "has no blot" and no "art that does not exist" | yes | grep 0/0; the header block :238-254 names wipe_blot.png / wax_seal.png / gen_wipe.lua (all three exist: tools/aseprite/gen_wipe.lua writes art/src/ui/{wipe_blot,wax_seal}.aseprite and game/assets/ui/*.png) |
| Shot `--set=reduced_motion=true --advance=all`: stamp instantly, no rotation, 60 ms floor | yes | review-…-rm_all_log_x2.png; `_wipe_stamp` :1799-1803 (`motion_duration(WIPE_STAMP_MS, WIPE_STAMP_FLOOR_MS)`, tilt × `motion_scale()`) unchanged from W2 |
| Green: WIPE_* constants/members, `_run_wipe_sequence` literals, no `await create_timer`, one "WIPE." Label; a11y focus owner unchanged; Motion constants through Widgets.tween | yes | §3 above; `MOTION LINT OK` in the reviewer's verify; a11y: unit's log build/shots/w3rv2_a11y.log `owner='1x'` both sweeps, 26 mounts (reviewer's --fast skips a11y; no new focusable at mount — PausedStamp is a Label, the gate is off) |
| COMBAT-05: `Icons.at("sigil", rank)` in the 48px slot; affix cells 30 @ pitch 34; name stays display_name | yes | :694-702, :733-736; adv10 crops show the jaw glyph and five cells; test_the_boss_sigil…, test_the_affix_cells… |
| COMBAT-14: `const EXITS_GATED := false`; when true, exits disabled with "The account is still being read" until `is_finished()` | yes | :293-294; `_gate_exits`/`_release_exits` :800-840; `_process` :1671 and `_on_skip` :1930 release; two tests |
| COMBAT-17: MarginContainer margin_top 1→0 over Motion.LOG_SETTLE via Widgets.tween; 1px EDGE_SLATE rule right of the round divider | yes | `_settle` :2071-2088 (`Widgets.tween(wrap)` + `_settings.motion_duration(Widgets.Motion.LOG_SETTLE)`), `_round_marker` :2041-2067; the rule is visible in the paused strip and the all crop |
| CRITIC-G13: one finding per verbosity mode recorded, fixed where it is in RaidView.gd | yes | report J8 (Story: nothing to fix; Play-by-play: J3; Numbers: PHASE rows now headings :1952-1964 + test_a_phase_row_is_a_heading…) |
| COMBAT-07: boss consumed through `stage.place_boss` only, typed Node2D; no same-wave SceneStage function named | yes | :165, :480; §2 rule-7 table against HEAD |
| Q18 / Q12a / Q12c stay behind switches at the recommended defaults, recorded not resolved | yes | `VFX_FAMILY` docstring :304-315 + report J1; `EXITS_GATED := false`; `display_name` :709-712 |

## 7. Issues

MINOR
1. `test_every_stage_call_here_existed_at_the_waves_start` (test_raid_beats.gd:589-599) greps the CURRENT `game/ui/SceneStage.gd`, not the wave-start file, so it would pass for a function W3-ENEMIES added this wave; the name overstates the check. The rule-7 property is true anyway (verified against `git show HEAD:` in §2), so nothing is wrong in the tree — the test just does not pin what it says.
2. The WIPE. word on the blot reads through a 3px GROUND_PAGE outline — legible at 2x, low contrast at 1x (review-…-all.png). The unit's J9 is the right device given the plan's red-on-red geometry; a designer may want a lighter ink for the pressed word later. Not a contract.
3. `build/shots/w3rv2_batch1.sh` / `w3rv2_batch2.sh` call `"$GODOT"` directly and rely on being invoked under one `with_godot_lock.sh`; they carry no guard of their own. The report says each batch ran under one lock and the runs happened without incident; unverifiable from the tree. Harmless as long as nobody re-runs them bare.
4. The 40-frame `--advance=10` acceptance shot is timing-sensitive: the burst's life is shorter than 40 SubViewport frames in this run (my 40-frame take shows only the numbers and the "!"; the 8-frame take shows both bursts). The plan's grammar, not the unit's fault; noted so the orchestrator's sheet does not read a missing burst as a regression.
5. `_gate_exits` reparents the exits into `Widgets.reasoned` boxes named "Gate" — under the (off) switch the footer's two Buttons change parent; `_retry_button` still points at the same Button so `_wipe_exits`' focus holds (the test asserts it). Behind the switch only.

BLOCKERS: none. False claims in the report: none found (verify numbers, a11y owner, refdiff numbers, test counts, grep results, asset/generator names all reproduce from the tree).

## 8. Verdict

**PASS** (minors only). verify --fast observed FAIL, charged to other units' in-flight files (test_menu_lockup, test_options_layout, test_roster_layout, test_text_scale via Guildhall.gd:347, test_widgets_kit) — none in RaidView.gd or test_raid_beats.gd.
