# Review — W2-RAIDVIEW (adversarial)

Reviewer: wave-2 review agent, 2026-09-14. Verifies the TREE, not the report.
Owned files under review: `game/screens/RaidView.gd`, `tests/unit/test_raid_overlays.gd` (+ `.uid`), `build/plan/report-W2-RAIDVIEW.md`, `build/plan/handoff-W2-RAIDVIEW.md`.

## 1. Tree state (git status / diff)

- `git status --porcelain`: owned files present — ` M game/screens/RaidView.gd`, `?? tests/unit/test_raid_overlays.gd`, `?? tests/unit/test_raid_overlays.gd.uid`, `?? build/plan/report-W2-RAIDVIEW.md`, `?? build/plan/handoff-W2-RAIDVIEW.md`.
- `git diff -- game/screens/RaidView.gd`: 963 diff lines, read in full (scratchpad/raidview.diff). Whole file is TAB-indented (`grep -c '^ ' RaidView.gd` = 0); test file is SPACE-indented (0 tabs); both LF, UTF-8. `.uid` sidecar present (`uid://bqvsm5tgxuopd`).
- Changed files NOT in this unit's ownership (other wave-2 units own them; nothing in their diffs or in this report attributes them to W2-RAIDVIEW): `game/assets/bg/camp_plate.png(+.import)`, `guildhall_plate.png(+.import)`, `game/assets/scenes/camp.json`, `guildhall.json` (deleted), `stage_camp/market/tavern/town.json`, `game/ui/SceneStage.gd`, `tests/unit/test_scene_stage.gd`, `tools/art/patch_bubbles.py` (W2-STAGE2); `AdventureBoard.gd` (W2-BOARD); `Market.gd` (W2-MARKET); `Results.gd` (W2-RESULTS); `Tavern.gd` (W2-TAVERN); `Town.gd` (W2-TOWN); the other units' report/handoff/test files; `aguildstory.zip` (untracked, unattributable). Grep of the other diffs for `W2-RAIDVIEW`/`RaidView` finds only W2-RESULTS' own comments. No unowned file shows this unit's hand.
- Diff content in RaidView.gd is confined to: Icons preload, new consts (SKIP_*, PAGER_Y, EXIT_*, STATUS_ROW, STATUS_GLYPH, BLOT_PITCH, LOG_AGE_ALPHA, WIPE_STAMP_Y), new members, `_header` → `Frame.draw_lockup(self, "33_compact")`, `_controls` skip → `Widgets.reasoned`, `_bar_button` → `Type.at`, mech cells via `Icons.at("mech")`, footer exit x's, `_pager` → `Widgets.pager`, HpGlyph, `_status_row`/`_blot_texture`/`_fill_blots`, face fallback by band, `_raider_blots` fold + `blots_of`, `_refresh_status`/`_refresh_overheads`/`_class_glyph`/`_target_sprite`, the effects block (`_effects_allowed`/`_line_effects`/`_rim_panel`/`_rerim`/`_lift`/`_settle_lifts`), `_wipe_stamp` → `stamp_box`, `_on_skip` `_live` + `_scroll_pending`, `_append_line` (glyph, blot, MISTAKE stamp, age, bubble, bar ids, number, effects), `_log_kind`, `_age_rows`, `_number`, `_bubble`, `_scroll_to_end`. The `_run_wipe_sequence` body, WIPE_* constants and wipe members are untouched by the diff.

## 2. Gate runs observed

- `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (18:28-18:33, log in scratchpad/verify_fast.log, full in `.verify.log`): 0/5 PASS LINT OK · 0/8 PASS MOTION LINT OK · 1/8 PASS PARSE_CHECK scanned 166 script(s) · 2/8 PASS 16 generated file(s) · 2b/8 PASS ART CHECK 184 agree 0 DIFFERS 0 MISSING · **3/8 FAIL unit tests — `TESTS FAILED 1/1801 failing [42391 ms]`**, the only failure `test_town_layout.gd :: test_the_locked_blacksmith_is_the_same_height_dimmed_with_a_one_line_reason` ("locked plate 85 tall vs 58") — W2-TOWN's new test against Town.gd; nothing in it touches RaidView.gd. 4-7 SKIP (--fast). `VERIFY FAILED`, EXIT=1. Observed, not the report's number (1/1800).
- `tests/unit/test_raid_overlays.gd` (17 `func test_`) ran inside the suite (its backtraces appear in the log at :99/:108/:116); none of the 17 is in the failure list → 17/17 green. The `!is_inside_tree()` ERROR lines under `test_a_skipped_account_lands_no_numbers`, `test_the_fold_counts_blots…`, `test_the_wipe_stamp…` are the same `_wipe_exits` grab_focus noise test_wipe_sequence.gd and test_log_player.gd already print. The `p_child->data.parent != this` errors are in test_raid_plan.gd's `_mount` and already appear in wave-1 logs (build/shots/W1STAGE_tests3.log) — not this unit's.
- `test_wipe_sequence.gd`, `test_log_player.gd`, `test_full_loop.gd`, `test_scene_stage.gd` boss rows: all absent from the failure list → green.
- Instrument note (not the unit's): my first shot batch printed `godot-lock: breaking stale lock (1789428863s old)` — `stat -c %Y` on the lock dir raced with another agent's release and returned 0, so the script "broke" a lock; worth a line to the orchestrator (with_godot_lock.sh:31 should treat a failed stat as fresh, not stale).

## 3. Shots re-taken

All through the lock with §0.3's grammar (`"$GODOT" --path . --script res://tools/shot.gd -- res://game/screens/RaidView.tscn <out> <frames> 1536x1024 <flags>`; the first batch with `--headless` produced no image — the grammar has no `--headless`). Every one viewed with Read.

- `build/shots/review-W2-RAIDVIEW-adv10.png` (40 frames, `--fixture=raid --advance=10`, `ADVANCE 10 revealed=10/160`): two red "-30" (DANGER, outlined) stacked 14px apart over Bork (the crossed-swords badge at ~(430,300)); a body-cream "-4" over the maw at (1210,360); three joke bubbles with tails over Tiny, Greg (hidden under Cindy's) and Cindy; badges (class glyph on a plate) on the figures, red blot pips beside the badges of the offenders; a 62x7 red HP bar beside the dagger badge of a two-blot rogue at (370,275) — Bork's bar is under Greg's bubble plate; no rim on the strip's page 2 (Pip/Cindy/Steve/Hal — the strip followed Cindy; line 10's actor is not on this page). Party crop at 2x: `review-W2-RAIDVIEW-adv10_party_x2.png`. Strip crop: red shield HpGlyph left of each 182px bar, "34 <face>" morale rows in the face font, Cindy's row with one blot, pager "‹ Party of 12 · page 2/3 ›" under the panels at (28,988). Log crop at 2x: margin blot + red frown disc + rotated MISTAKE stamp box + ellipsized header per mistake, joke in italics, purple eye disc on "Main Boss hits Bork for 30.", blue disc on "Bork hits Main Boss for 4"; the log is NOT scrolled to its bottom (scrollbar thumb at the top; lines 8-10 out of view) — `--advance=N` feeds `_process` 178 times in one frame so the deferred `_follow_bottom` finds the reader "not at the bottom"; pre-existing logic (identical at HEAD), the `_scroll_pending` fix was applied to `_on_skip` only.
- `review-W2-RAIDVIEW-adv10-f6.png` (6 frames): the same composition, numbers lower on their rise.
- `review-W2-RAIDVIEW-reduced-f6.png` (`--set=reduced_motion=true --advance=10`, 6 frames): same composition; the two "-30" already at their risen position; figures held; no stamp tilt.
- `review-W2-RAIDVIEW-all.png` (`--advance=all`): twelve grey figures each with a maroon `state_dead` skull plate + blot pips; the "WIPE." stamp box (double rule, red word, leaning) pressed on the ink blot mid-stage with the cost line under it; 12% dim; wax seal on the log panel at (1380,835); "Back to the board" focused; panels "Dead" top-right + skull glyph + blots + "34/34/20/3" morale faces; the log ends on "[R11] WIPE." (the `_scroll_pending` fix works). The red word on the red blot reads at low contrast (COMBAT-15 / W3-RAIDVIEW2 per the plan).
- `review-W2-RAIDVIEW-emoji.png` (`--set=emoji_free=true`, 40 frames = 2 lines at 1x): Greg's panel (page 1) rimmed 2px gold, its status row "34 ||||...... " + one blot (Greg has one MISTAKE entry so far); Bork "74 |||||||...", Gruk "43 |||||....." — pip strings in Label.text, no emoji; the joke bubble with a tail over Greg's figure whose badge carries a blot pip and the HP bar (the actor); every other figure a bare badge. Wordmark measured: rightmost cream pixel x=327 (≤ 344).
- `review-W2-RAIDVIEW-t150.png` (`--set=text_scale=150`): bar buttons scale to 20px; the reason line whole above the skip; "Back to the board"/"The report" whole; morale rows whole; pager caption whole; the objective title ellipsizes ("E5 — Raid 1 — Enco…"); **the three tier buttons overlap: "Play-by-play" is painted over by "Numbers" and reads "Play-by-pla"** (crop `review-W2-RAIDVIEW-t150_bar_x2.png`; the implementer's own `W2RV_t150.png` shows the identical clip — crop `review-W2-RAIDVIEW-implementer_t150_bar_x2.png`). Cause: `_bar_button` now scales the font through `Type.at` (this unit's edit, RaidView.gd:579) while `_place_in_bar(b, x, 64|108|64)` (RaidView.gd:574) keeps the 100% widths; at HEAD the font was fixed so nothing overflowed.

## 4. Acceptance lines (00-plan §W2-RAIDVIEW, verbatim order)

| # | Line | Met | Evidence |
|---|------|-----|----------|
| 1 | `--advance=10` shows a Label matching `^-\d+$` within 120px of the struck figure | yes | review-W2-RAIDVIEW-adv10.png: two "-30" (DANGER) over Bork's badge, "-4" over the maw; test_raid_overlays.gd:170-190 asserts `text == "-317"`, parent "Overlay", centre ≤ 120px of `head_of` |
| 2 | a bubble with the joke over the offender | yes | adv10 + emoji shots: tailed plates over Tiny/Greg/Cindy carrying the corpus lines; test `test_the_joke_lands_in_a_bubble…` (Say_<name> with the joke as a Label, the quoted line still in the log) |
| 3 | a bar on the acting figure | yes | emoji shot: Greg (the MISTAKE's actor) wears the 62x7 bar, every other figure a bare badge; adv10: the bar on the line-10 actor; test `test_the_struck_figure_wears_the_bar_and_the_rest_a_badge` |
| 4 | Greg's panel with as many blots as his MISTAKE entries | yes | emoji shot: Greg's status row one blot after his one MISTAKE; wipe shot: 2/1/2/2 blots on Nev/Clive/Spoof/Tiny; test `test_the_fold_counts_blots_per_actor…` (per-actor == MISTAKE entries, sum == `mistakes_seen()`, panel host meta == fold). In the adv10 shot itself Greg's panel is off-page (strip on page 2) |
| 5 | a `state_downed` glyph on any fallen panel | yes | test `test_a_downed_figure_wears_the_state_plate_with_a_label_bang` (`_panel_glyphs[id].visible`, "Downed" word printed, "!" Label named Bang); wipe shot: `state_dead` skull glyph on every panel next to the "Dead" word. No raider is downed by line 10 of this seed, so no shot shows the downed glyph itself |
| 6 | the actor's panel rimmed | yes | emoji shot: Greg's panel with the 2px gold rim; test `test_the_actors_panel_wears_the_rim_at_one_x` (StyleBox override moves with the actor) |
| 7 | no Label whose text starts "Unlocks once" outside the reasoned control | yes | test `test_the_skip_reason_is_a_label_inside_the_reasoned_box` (exactly one, named Reason, sibling of Button "Skip" in a VBoxContainer); RaidView.gd:557-566 |
| 8 | wordmark's rightmost pixel ≤ 344 | yes | measured on review-W2-RAIDVIEW-emoji.png: rightmost cream pixel x=327; test `test_the_compact_header_is_frames_33_lockup_inside_its_plate` (`wordmark_33` right edge ≤ 344, no `wordmark_44`) |
| 9 | test_raid_overlays: one ATTACK line → child Label "DamageNumber", `text == "-N"`, never changes | yes | test 1; the text is set once in `Widgets.damage_number`, `_number()` never touches it |
| 10 | the fold's blot count per actor | yes | `_fold_to` MISTAKE branch RaidView.gd:1033-1037, `blots_of()`; test |
| 11 | test_wipe_sequence.gd green unchanged | yes | file unmodified (`git status`), green in the suite; WIPE_* constants/members untouched by the diff; `_wipe_stamp_label = stamp_box(...).get_child(0)`, box a direct child after `_wipe_blot` (RaidView.gd:1524-1536) |
| 12 | test_log_player.gd green (the row's first Label carries the whole line) | yes (note) | green in the suite. Note: a MISTAKE row's FIRST Label is now the stamp's "MISTAKE" Word (RaidView.gd:1724-1728 inserts the box before the header); the header is the row's LAST child. test_log_player reads RaidView rows by `contains`, so nothing asserts the index; recorded as an observation, not a break |
| 13 | test_full_loop.gd green | yes | suite |
| 14 | refdiff RaidView vs 2 masked recorded | yes | report records 33.815/0.1163/26.13 → 34.031/0.1187/24.74; reproduced on my shot: 34.027/0.1186/24.74 (mae +0.21, IoU +0.002, within-8 −1.4pp — the strip/log fill; recorded, not chased, per §0.3) |
| Shot list | adv10, all, reduced+adv10, emoji_free, text150 all taken and viewed | yes (see §3) | but see finding F1 on the text150 shot |
| Wave-2 header: text150 shot, "fixes any clipped Label it owns" (G15) | **no** | "Play-by-play" clipped to "Play-by-pla" by the overlapping "Numbers" button at 150 (finding F1); the objective title ellipsizes (pre-existing OVERRUN_TRIM_ELLIPSIS, minor) |

## 5. Green line / §0.5 contracts

- Label/Button texts read by tests unchanged: "Skip to the end", "Back to the board", "The report", "Mistakes this attempt", "Nobody went…", "WIPE.", the mistake header, the quoted joke — all present (shots + suite green). No node a test names was renamed (`_wipe_stamp_label`, `_wipe_blot`, `_wax_seal`, `_wipe_dim`, `Bar_*`, `Say_*`, `Overlay`).
- Indentation: RaidView.gd all tabs, test file all spaces (§1). LF endings.
- `create_tween` / `create_timer`: none in RaidView.gd; new motion is `Widgets.number_rise`, `Widgets.stamp_press` (kit doors) and the pre-existing `Widgets.tween(box)` wipe press with `motion_duration(WIPE_STAMP_MS, WIPE_STAMP_FLOOR_MS)`. `lint_motion.sh` → MOTION LINT OK (gate stage 0/8).
- `reduced_motion`: no branch (the only mention is a comment). `reduced_effects` gates the effects layer only, as the plan says.
- No `class_name` refs; `_ready()` only calls `build()` (pre-existing harness pattern).
- FOCUS_ALL: new focusables are the kit's (`Widgets.icon_button` Button default FOCUS_ALL; `Widgets.pager` arrows FOCUS_ALL). a11y_smoke observed: `ok empty RaidView owner='1x' … disabled=1`, `ok fixture … disabled=1`, `A11Y SMOKE PASSED 26 screen mount(s)`, no warn line.
- Disabled control's reason adjacent: the Reason Label is a sibling in the reasoned VBox (index 0).
- Overlays MOUSE_FILTER_IGNORE: Bang, Glyph, Blot_*, WipeCost, the stamp box (kit), numbers/bubbles/bars (stage). The panel's Blots host and HpGlyph are PASS — they carry tooltips inside a panel, not overlays.
- No pure black/white paint added: new colours are Palette tokens (CAUTION, TEXT_BODY, ACCENT_GOLD, SURFACE_CARD); `Color(1.15,…)`/`Color.WHITE`/`Color(1,1,1,a)` are modulates. The pre-existing `Color(0,0,0,WIPE_DIM)` scrim is HEAD's.
- No new PNG, so no baked text / .import question. No `$GODOT` call in anything the unit added. Nothing parented to the router host (test_screens' one-child check green).
- Handoff: §1 `game/ui/Palette.gd:77` old block matches the file byte-for-byte (`const CRIT := Color("F1750E")             ## critical damage numbers`); top-level const, no indentation question. The new block's comment carries double-encoded UTF-8 ("Â§" for "§") — applying it verbatim writes mojibake into a Palette comment (minor, F5).
- `_run_wipe_sequence` untouched (no diff hunk covers it); W1-STAGE's composition symbols (`_formation_rank`, placement) untouched — `_resolve_data` only gains `_raider_by_id`.

## 6. Judgement calls vs the plan

- J1 `Icons.at("blot","a")` / `("lock","16")` / `("bar","hp")` for the plan's `("ui","blot_12_a")` / `("ui","lock_16")` / `("ui","bar_hp")`: correct — Icons.gd:39-53 defines those roles; the plan's spellings were shorthand. OK.
- J2 `Widgets.pager` instead of `Cards.roster_strip` paging: RaidView draws its own four panels, not a roster strip; Widgets.gd:490-496 names this row for RaidView. OK.
- J3 `LabelMorale` + `Cards.morale_glyph` instead of `Widgets.chip`: the plan's COMBAT-13 says "morale chip via `Widgets.chip` with the face font"; the chip is 96x45 and the band is 26px tall. The one door (`Cards.morale_glyph`) is kept and the pips stay in `Label.text`. A kit-shape choice, not a §6 question. OK.
- J4 Reason above the button: `move_child(why, 0)` on the kit's box; the sentence stays the kit's "Reason" Label. OK.
- J5 `Palette.CAUTION` for the "!" and `Palette.TEXT_BODY` for the flash pending `HIT_FLASH`: tokens, never hex, with the handoff filed. OK.
- J6 the stamp rests on `stamp_box`'s own lean; the press tweens from lean+tilt·motion_scale to lean: under reduced motion no rotation MOTION. Consistent with W1-KIT's ruling. OK.
- J7 G08 coalescing (per line 1x, per round 2x, off 4x/Instant/skip/reduced_effects) is the plan's rule verbatim. OK.
- Q07 landed as the plan's default (badge+pips on all, bar on acting/struck) — nothing reserved for the designer was decided.

## 7. Findings

- **F1 (major) — text_scale 150: the log-tier buttons overlap and "Play-by-play" is clipped.** RaidView.gd:579 now scales the bar-button font through `Type.at(Type.SMALL, Theme_.scale_of(self))` (correct per §0.5) but RaidView.gd:574 keeps the 100% slot widths `64 | 108 | 64` in `_place_in_bar`, so at 150 "Play-by-play" (20px) overflows its 108px slot and "Numbers" paints over it → "Play-by-pla" (review-W2-RAIDVIEW-t150_bar_x2.png; identical in the implementer's own W2RV_t150.png). Introduced by this unit; the wave-2 header's G15 line ("fixes any clipped Label it owns") and the unit's A14 are not met; the report's "No clipped Label this screen owns" is contradicted by its own shot. Fix is the same the unit applied to the exits: scale the three widths (and the 86/84 speed/pause slots) by `Theme_.scale_of(self) / 100.0`, or lay the row out with a HBox.
- F2 (minor) — an UNLOCKED skip wears the padlock: `Widgets.reasoned(skip, "", Icons.at("lock","16"))` sets the icon whenever the glyph is non-null (Widgets.gd:624-626), so after a first clear "Skip to the end" is enabled and still shows a lock. Pass the glyph only when `not _skip_unlocked`. No fixture reaches this state, so no shot shows it.
- F3 (minor, instrument) — `--advance=N` shots leave the log scrolled to the top (lines 8-10 out of view in adv10): shot.gd feeds `_process` 178 times in one frame, so the deferred `_follow_bottom` sees the reader "not at the bottom". Pre-existing logic (identical at HEAD); the unit's `_scroll_pending` fix covers `_on_skip` only. Worth extending the same two-frame scroll to the N-advance path, or noting for W0-SHOT.
- F4 (minor) — the handoff's "raid-advanced tile cannot show a damage number at 40 frames" observation is unfounded: my 40-frame `--advance=10` shot shows both "-30" and the "-4" (the number top moved 2px between 6 and 40 frames). W0-GATE need not act on it.
- F5 (minor) — report and handoff carry double-encoded UTF-8 ("Â§", "â†'", "Â·"); the handoff §1 new-block comment would land as `## docs/12 Â§5.2: …` if applied verbatim. Code files are clean.
- F6 (observation) — a MISTAKE row's first Label is now the stamp's "MISTAKE" Word, the header Label last (RaidView.gd:1724-1728). No test reads a RaidView row by index; RULES' "first Label" wording is about Results' `_story_row`. Recorded for W3-KIT2/W3-RAIDVIEW2 in case a test ever does.
- F7 (observation, not the unit's) — `with_godot_lock.sh` printed `breaking stale lock (1789428863s old)` when `stat` on a just-released lock failed; a failed stat should read as fresh.

## Verdict

**FAIL** — on F1 alone: an acceptance line the unit could have met (the G15 text150 line / its own A14) is not met, the clip was introduced by this unit's own edit, and the report claims the opposite while its own shot shows it. Everything else on the contract is met and verified against the tree: 17/17 new tests green, every RaidView test green, the only red in `verify.sh --fast` is W2-TOWN's `test_town_layout.gd`, a11y smoke passed with the '1x' owner, lint OK, refdiff recorded and reproduced, wipe contract intact, no unowned file touched, handoff exact. Minors F2-F5 should ride along with the F1 fix.

---

# Repair-pass review — W2-RAIDVIEW (adversarial, second pass)

Reviewer: wave-2 review agent, 2026-09-14 (after the implementer's repair of F1-F6 above). Verifies the TREE, not the report. Written as it goes.

## R1. Tree state

- `git status --porcelain`: owned files — ` M game/screens/RaidView.gd`, `?? tests/unit/test_raid_overlays.gd` (+ `.uid`), `?? build/plan/report-W2-RAIDVIEW.md`, `?? build/plan/handoff-W2-RAIDVIEW.md`. Unowned changed files are the same set the first pass listed (W2-STAGE2's scene/bg/SceneStage/test_scene_stage/patch_bubbles, W2-BOARD/MARKET/RESULTS/TAVERN/TOWN screens and their report/handoff/test files, `aguildstory.zip`); nothing in this unit's report or diff attributes any of them to W2-RAIDVIEW.
- `git diff -- game/screens/RaidView.gd`: 1102 diff lines (was 963), read in full (scratchpad/raidview.diff). RaidView.gd 1997 lines, 0 space-indented lines; test file 543 lines, 0 tab-indented lines; `file` reports both UTF-8 text. Report and handoff: UTF-8 text.
- Repair diff content vs the first pass: `_controls` gains `s = Theme_.scale_of(self)/100`, every slot `* s`, `SKIP_W * s`, `custom_minimum_size`, the reasoned box bottom-pinned (`BAR_Y + BAR_H - box.size.y`), `x += maxf(SKIP_W*s, skip min) + 6`; `_place_in_bar` returns `x + maxf(w, maxf(b.size.x, min.x)) + 6`; `lock` glyph gated on `not _skip_unlocked`; `_combat_log` connects the v-scrollbar's `changed`/`value_changed`; `_stick`/`_follow_queued` members; `_autoscroll`/`_at_bottom`/`_scroll_to_end`/`_follow_bottom`/`_settle_follow`/`_on_log_range_changed`/`_on_log_value_changed`; `_reset_player` clears `_stick`. `_run_wipe_sequence` still untouched by any hunk.

## R2. Gate runs observed (this pass)

- `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (19:03-19:06, scratchpad/verify_fast.log): 0/5 PASS class cache · 0/8 PASS LINT OK · PASS MOTION LINT OK · 1/8 PASS PARSE_CHECK 166 scripts · 2/8 PASS 16 generated · 2b/8 PASS ART CHECK 184 agree 0 DIFFERS · **3/8 FAIL unit tests — `TESTS FAILED 1/1805 failing [41069 ms]`**, the single failure `test_town_layout.gd :: test_the_locked_blacksmith_is_the_same_height_dimmed_with_a_one_line_reason` (W2-TOWN's test on Town.gd; nothing in it reads RaidView) · 4-7 SKIP · `VERIFY FAILED`, EXIT=1. The suite count is 1805 (the report says 1803 — other units' tests landed since; the report's number was true when written, not now). `.verify.log` was overwritten by another agent's run within a minute, so the per-test lines come from my own suite run below.

## R3. Shots re-taken (this pass)

All five through one lock (scratchpad/shots.sh: `"$GODOT" --path . --script res://tools/shot.gd -- res://game/screens/RaidView.tscn build/shots/review-W2-RAIDVIEW-r2-<name>.png 40 1536x1024 <flags>`, every one `SHOT OK`, exit 0). Every one viewed with Read.

- `review-W2-RAIDVIEW-r2-t150.png` (`--fixture=raid --set=text_scale=150`) + the 2x bar crop `…-r2-t150_bar_x2.png`: **F1 is repaired.** The row reads "» 1x | Pause | 🔒 Skip to the end | Story | Play-by-play | Numbers" with every word whole inside its own plate — "Play-by-play" is complete and "Numbers" begins after it; dark plate runs measured on y=697 end at x 788 (last tier plate right edge ~890 incl. rim), the exits begin at 1108. The reason line "Unlocks once you have cleared this one." sits whole above the dimmed padlocked skip; "Back to the board"/"The report" whole; morale rows "74 😊" etc. whole; pager whole. The objective title still ellipsizes ("E5 — Raid 1 — Enco…") — the pre-existing designed OVERRUN_TRIM_ELLIPSIS on the 283px slot the first pass called minor.
- `review-W2-RAIDVIEW-r2-adv10.png` (`--fixture=raid --advance=10`, `ADVANCE 10 revealed=10/160 in 178 steps`) + `…-r2-adv10_log_x2.png` + `…-r2-adv10_party_x2.png`: **F3 is repaired.** The log's thumb is at the BOTTOM and the last visible row is line 10 — Tiny's MISTAKE row and its italic joke — after "Bork hits Main Boss for 4." / Greg's mistake + joke / "Pip hits Main Boss for 4." / Cindy's mistake + joke; the top row ("Main Boss hits Bork for 30.") is cut by the viewport, which is what a scrolled log looks like. The age ramp is visible (the two newest rows full, older ones at 0.75). Stage: two red outlined "-30" stacked ~14px apart over Bork's crossed-swords badge, a cream "-4" over the maw at (1210,360), three tailed joke bubbles (Tiny's, Greg's under Cindy's, Cindy's), badges with class glyphs on every figure, red blot pips beside the offenders' badges (Tiny 2, Greg 2, Cindy 1 visible), the 62x7 HP bar under Tiny's badge (line 10's actor); strip on page 2 with Cindy's one blot in her status row; "Mistakes this attempt 5".
- `review-W2-RAIDVIEW-r2-all.png` (`--advance=all` via `_on_skip`): twelve grey figures each with the maroon skull `state_dead` plate + blot pips; the "WIPE." stamp box on the ink blot mid-stage with the cost line under it; 12% dim; wax seal on the log panel; "Back to the board" focused; panels "Dead" top-right + skull glyph + blots + "34/34/20/3" morale faces; the log ends on "[R11] WIPE." with the thumb at the bottom. (The red word on the red blot is still low-contrast — COMBAT-15 / W3-RAIDVIEW2, as the first pass noted.)
- `review-W2-RAIDVIEW-r2-reduced.png` (`--set=reduced_motion=true --advance=10`): same composition as adv10; the two "-30" at their risen position; figures held; stamps untilted; the log on line 10 with the thumb at the bottom.
- `review-W2-RAIDVIEW-r2-emoji.png` (`--set=emoji_free=true`, 40 frames): Greg's panel rimmed 2px gold with one blot; morale rows "74 |||||||…", "43 |||||…..", "34 ||||……" — checked against `GameSettings.morale_glyph` (band+1 pipes + the rest dots, 10 chars): the 3x crop `…-r2-emoji_morale_x3.png` shows 7 pipes + 3 dots for 74 and 5 + 5 for 43, i.e. the whole string, not an ellipsis. The joke bubble with a tail over Greg's figure, whose badge carries a blot pip and the HP bar.

## R4. Unit suite, a11y and lint observed directly (one lock, scratchpad/tests.sh → tests.log, 19:08-19:10)

- `run_tests.gd`: **`TESTS PASSED 1806 test(s) in 86 file(s) [38376 ms]`**, exit 0 — by the time my own suite ran (four minutes after the verify above) W2-TOWN's red had gone and one more test had landed; the tree is moving under all of us. `tests/unit/test_raid_overlays.gd` has 19 `func test_` (17 + `test_an_unlocked_skip_is_enabled_and_wears_no_padlock` + `test_the_bar_buttons_do_not_overlap_at_text_scale_150`); none in any failure list → 19/19. The only RaidView.gd frames in the log are the pre-existing `_wipe_exits` grab_focus `!is_inside_tree()` noise (HEAD:1274, now :1685) under three of its tests, exactly as the first pass saw. The eight `Must be an ancestor of the control` errors at exit are `ensure_control_visible` — only AdventureBoard.gd calls it (W2-BOARD's).
- `a11y_smoke.gd`: `ok empty RaidView.tscn owner='1x' tab ring=8 focusable=7 reachable=8 disabled=1`, `ok fixture RaidView.tscn owner='1x' tab ring=10 focusable=9 reachable=10 disabled=1`, no `warn` line anywhere, `A11Y SMOKE PASSED 26 screen mount(s)`. The focus owner stays the speed button.
- `tools/lint_motion.sh`: `MOTION LINT OK  tweens and morale glyphs each go through one door`.
- `PARSE_CHECK scanned 166 script(s)` PASS inside the verify run.

## R5. Acceptance lines (00-plan §W2-RAIDVIEW, verbatim order) — this pass

| # | Line | Met | Evidence |
|---|------|-----|----------|
| 1 | `--advance=10` shows a Label matching `^-\d+$` within 120px of the struck figure | yes | r2-adv10 party crop: two "-30" over Bork's badge, "-4" over the maw; test 1 asserts `"-317"`, parent "Overlay", centre ≤ 120px of `head_of` — passed |
| 2 | a bubble with the joke over the offender | yes | r2-adv10: three tailed plates over Tiny/Greg/Cindy with the corpus lines; r2-emoji: one over Greg; `test_the_joke_lands_in_a_bubble…` passed |
| 3 | a bar on the acting figure | yes | r2-adv10 party crop: the 62x7 bar under Tiny's badge (line 10's actor), bare badges elsewhere; r2-emoji: on Greg; `test_the_struck_figure_wears_the_bar…` passed |
| 4 | Greg's panel with as many blots as his MISTAKE entries | yes | r2-emoji: Greg's status row one blot after his one MISTAKE; r2-all: Nev/Clive/Spoof/Tiny 2/1/2/2; `test_the_fold_counts_blots_per_actor…` passed |
| 5 | a `state_downed` glyph on any fallen panel | yes | `test_a_downed_figure_wears_the_state_plate_with_a_label_bang` passed (glyph visible, "Downed" printed, "!" Label named Bang); r2-all shows the `state_dead` skull on every panel; no raider is downed by line 10 of this seed so no shot shows `state_downed` itself |
| 6 | the actor's panel rimmed | yes | r2-emoji and r2-t150: Greg's panel with the 2px gold rim; `test_the_actors_panel_wears_the_rim_at_one_x` passed |
| 7 | no Label whose text starts "Unlocks once" outside the reasoned control | yes | `test_the_skip_reason_is_a_label_inside_the_reasoned_box` passed (exactly one, named Reason, in the VBox with Button "Skip"); RaidView.gd `_controls` |
| 8 | wordmark's rightmost pixel ≤ 344 | yes | measured on r2-emoji: rightmost cream pixel in the header band x=326; `test_the_compact_header…` passed |
| 9 | test_raid_overlays: one ATTACK line → "DamageNumber", `text == "-N"`, never changes | yes | test 1 passed; `_number()` never writes `text` |
| 10 | the fold's blot count per actor | yes | `_fold_to` MISTAKE branch + `blots_of()`; test passed |
| 11 | test_wipe_sequence.gd green unchanged | yes | file unmodified (`git status`), suite green; `_run_wipe_sequence` has no diff hunk; box direct child after `_wipe_blot` (this unit's own test asserts it too) |
| 12 | test_log_player.gd green (the row's first Label carries the whole line) | yes (note) | suite green. As the first pass noted (F6): a MISTAKE row's first Label is now the stamp's "MISTAKE" word; test_log_player reads RaidView by `contains` and its `texts[0]` assertion is on Results' `_story_row`. Left as built (J9) — minor, carried |
| 13 | test_full_loop.gd green | yes | suite green |
| 14 | refdiff RaidView vs 2 masked recorded | yes | report records before/after (33.815/0.1163/26.13 → 34.031/0.1187/24.74); the first pass reproduced it (34.027/0.1186/24.74); nothing in the repair touches the masked arena |
| Shot list | adv10, all, reduced+adv10, emoji_free, text150 taken and viewed | yes | R3 above, all five re-taken and read |
| Wave-2 header G15: text150 shot, "fixes any clipped Label it owns" | **yes (was no)** | r2-t150 bar crop: every bar word whole; the new test asserts no two bar spans overlap and each tier button ≥ its minimum width, the row ends before `EXIT_BACK_X`, both exits fit — passed. The objective title's ellipsis is the pre-existing designed clip (minor, unchanged) |

## R6. Green line / §0.5 contracts — this pass

- Texts and names read by tests unchanged: "Skip to the end", "Back to the board", "The report", "Mistakes this attempt", "WIPE.", the mistake header and quoted joke, `Bar_*`/`Say_*`/`Overlay`, `_wipe_stamp_label`/`_wipe_blot`/`_wax_seal`/`_wipe_dim`, "Skip"/"Reason" (this unit's own). Suite green.
- Indentation: RaidView.gd 0 space-led lines; test 0 tab-led lines; LF; UTF-8 (`file`).
- `create_tween`/`create_timer`: none in RaidView.gd; lint OK. `reduced_motion`: no branch (one comment mention at :1510). No `class_name` refs; `_ready()` only calls `build()` (HEAD's).
- FOCUS_ALL: the only new focusables are kit Buttons (`icon_button`, pager arrows) — a11y smoke owner '1x', no warn. The disabled skip's reason is the adjacent "Reason" Label in the same VBox (index 0).
- Overlays MOUSE_FILTER_IGNORE: Bang, Glyph, Blot_*, WipeCost, the stamp box; numbers/bubbles/bars in the stage's Overlay. HpGlyph/Blots hosts are PASS for tooltips inside a panel, not overlays.
- Colours: tokens only (CAUTION, TEXT_BODY, ACCENT_GOLD, SURFACE_CARD, DANGER); the `Color(1.15,…)`/`Color(1.6,…)`/`Color(1,1,1,a)` literals are modulates, not paint. No hex in the file. Every font size on a route this unit added goes through `Type.at(…, Theme_.scale_of(self))` or a variation; the one raw `Type.FIGURE_XL` (:1528, `_wipe_line`) is HEAD's own line inside the wipe sequence the unit was told not to touch (observation for W3-RAIDVIEW2).
- No new PNG → no baked-text / .import question. No `$GODOT` call in anything the unit added (the test file and the report's commands all go through the lock). Nothing parented to the router host (test_screens' one-child check green).
- Handoff: `## 1. game/ui/Palette.gd:77` old block matches the file byte-for-byte (line 77 confirmed); the new block is clean UTF-8 ("§" is a real section sign now — 0 `C3 82`/`C3 A2` pairs in either plan file); observations are labelled as such; the W0-GATE note is under a "Withdrawn" heading with the evidence. Nothing applied by the unit (`HIT_FLASH` absent from Palette.gd, as it should be).
- `_run_wipe_sequence` untouched; W1-STAGE's composition symbols untouched.

## R7. Judgement calls vs the plan — this pass

- J1-J7: as the first pass found — kit-shape choices inside the plan's text; Q07 landed as §0.6's default; nothing in §6 was decided by the unit (no boss scale, no EXITS_GATED, no copy change, no fixture level, no morale-face route change — `Cards.morale_glyph` stays the one door).
- J8 (repair): explicit placement scaled by `Theme_.scale_of(self)/100` with the drawn width read back rather than an HBox — the first pass offered either; the LESSONS reason (containers re-lay positioned children) is a fair one and the shot proves it.
- J9 (F6 left as built): a defensible reading of RULES §1's row (its cited lines are Results' `_story_row`), and the first pass itself filed it as an observation; a future test that reads a RaidView mistake row by index would see "MISTAKE" first. Minor, carried for W3-KIT2/W3-RAIDVIEW2.

## R8. Findings — this pass

- F1 (major, first pass) — **repaired and verified**: the 150% bar has no overlap (shot + the new test).
- F2 (minor) — **repaired and verified**: `lock` is null when `_skip_unlocked`; `test_an_unlocked_skip_is_enabled_and_wears_no_padlock` mounts with `st.cleared["t1_raid_e5"] = 1` and passed.
- F3 (minor) — **repaired and verified**: `--advance=10` and `--advance=all` shots both end on the newest line with the thumb at the bottom; reduced-motion `--advance=10` likewise. Sticky-follow logic read: `_stick` set from the pre-measure "at bottom" reading, one coalesced deferred pin + a second after the container's sort, the scrollbar's `changed` re-pins while stuck, a `value_changed` below the bottom (only a drag can produce one — `_scroll_to_end` clamps to `max - page`, which never satisfies `< max - page - 24`) releases it, `_reset_player` clears it before freeing the rows. No engine errors from it in any run.
- F4 (minor) — **repaired**: the W0-GATE note is withdrawn in the handoff.
- F5 (minor) — **repaired**: both plan files clean UTF-8 (0 double-encoded pairs).
- F6 (observation) — carried, not changed (J9). Minor.
- New, minor (report accuracy, not a false claim): the report's "unit suite 1/1803 failing" and "verify.sh --fast … FAIL 1/1803" were true at its clock; at mine the suite is 1806/1806 green and the verify count was 1805. Nothing for the unit to do.
- New, observation (not this unit's edit): `_wipe_line` sets a raw `Type.FIGURE_XL` (HEAD's line inside the wipe sequence) — a G15 site for W3-RAIDVIEW2.
- No unowned file touched by this unit; no §6 question decided; no asserted string or node name changed; handoff exact.

## Verdict (repair pass)

**PASS** — F1 (the one blocker of the first pass) is repaired in the tree and proven by both a re-taken shot and a test; F2-F5 are repaired; the only remaining items are minors/observations (F6 carried as J9, the objective title's pre-existing ellipsis at 150, the raw FIGURE_XL in the untouched wipe line). Observed directly: `verify.sh --fast` red only on W2-TOWN's test at 19:06 and the full unit suite 1806/1806 green at 19:10; test_raid_overlays 19/19; a11y smoke 26 mounts with the '1x' owner and no warn; MOTION LINT OK; PARSE_CHECK 166 OK; all five acceptance shots re-taken, read and matching the contract.
