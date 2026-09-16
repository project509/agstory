# Review — W2-RESULTS (adversarial, against the tree)

Reviewer edits nothing but this file. Findings landed as they were made; everything below was observed
by the reviewer (commands run through the lock, shots viewed with the Read tool), not copied from the report.

## 1. Ownership / git status

`git status --porcelain` at review time:
- Owned and changed: `game/screens/Results.gd` (M, +513/-137), `tests/unit/test_results_report.gd` (??, 355 lines),
  `build/plan/report-W2-RESULTS.md`, `build/plan/handoff-W2-RESULTS.md`.
- `tests/unit/test_results_report.gd.uid` (??) — Godot's generated sidecar for the new test; expected, not a violation.
- Changed files NOT in this unit's list (all belong to other wave-2 units per the §3 ownership table):
  `game/screens/AdventureBoard.gd` (W2-BOARD), `Market.gd` (W2-MARKET), `RaidView.gd` (W2-RAIDVIEW), `Tavern.gd`
  (W2-TAVERN), `Town.gd` (W2-TOWN), `game/ui/SceneStage.gd`, `game/assets/scenes/stage_*.json`, deleted
  `camp.json`/`guildhall.json`/`camp_plate.png(.import)`/`guildhall_plate.png(.import)`, `tests/unit/test_scene_stage.gd`,
  `tools/art/patch_bubbles.py` (all W2-STAGE2); the other units' new tests/reports/handoffs; `aguildstory.zip` (untracked,
  not a unit file). `git diff` of those screen/ui files contains no line mentioning Results; nothing attributes any of
  them to this unit. No unowned file touched by W2-RESULTS.
- The kit files Results.gd now calls (`Widgets.stamp_box/reasoned/log_row(…, icon)`, `Cards.roster_strip` with
  `card_builder/available_label/on_page`, `Cards.PAGER_NEXT_X/PAGER_W`, `Frame.draw_lockup("33_compact")`,
  `Theme_.scale_of`, `Type.gold`, `Icons.at/size/exists`) are all unmodified in git status and present at HEAD —
  the unit referenced only what existed at the wave's start (§0.2). `tools/fixture_reference.gd:109 apply_clear`
  and `tools/shot.gd:159 --fixture=raid:clear` likewise exist at HEAD.

## 2. Diff read (Results.gd, in full)

- Indentation: 0 tab-led lines, 839 four-space-led lines — the file stays SPACES (RULES §5).
- `const COMEDY_LINE := "as_built"` with a `_shows_comedy_line` reader implementing "promise" behind it (Q12b default,
  §0.6). Options (b)/(c) not switched — correctly left to the designer.
- `Frame.draw_lockup(self, "33_compact")` replaces the hand-placed emblem + `wordmark_44` (COMBAT-12).
- Report block: three lines now a `Filing` VBox at (20,96); `RankSigil` TextureRect (`Icons.at("rank", rank.to_lower())`,
  native 28px) in a `Filed` row before the `"Day %d  ·  %s"` Label — Label text untouched (COMBAT-18). All six rank
  files exist under `game/assets/ui/icons/rank_*.png` (legacy dir; `Icons.path` falls back to it).
- Headline: `Widgets.stamp_box(word, "danger")` named `Headline`, SHRINK_BEGIN, child(0) Label text unchanged;
  font size through `Type.at(Type.SECTION, Theme_.scale_of(self))` (COMBAT-08, G15).
- Loot: `Suggested` and `SellAll` rebuilt in `_refresh_loot` inside `Widgets.reasoned` with reasons
  "Nothing dropped — nothing was cleared." / "Nothing dropped." / "Nothing left to hand out." /
  "Everything here fits somebody."; the wipe's separate `"No payout — nothing was cleared."` faint line removed
  (no test reads it — grep of tests/ and tools/ confirms); a clear with no payout prints "No payout this time.".
  Sell-all not drawn when nothing is pending. `Sell all unusable  (+%d G)` → `(+%s)" % Type.gold(n)` — identical output
  below four digits ("+0 G"; test_results_report asserts the absence of that exact text on the wipe).
- `_by_raider_section` / `_refresh_by_raider` / `_by_raider` / `_morale_delta_of` / `_tally_row` / `_figure`: one row
  per `_party()` entry — 24px `Portrait`, `Name` Label (LabelSmall, muted when fallen), `Blot` TextureRect
  (`Icons.at("blot", a|b|c)` by id hash, visible only when mistakes > 0), `Mistakes` figure, `Morale` figure
  (signed, "—" when null), `State` Label "Fallen"/"Stood"; sorted mistakes desc then name asc; counts from
  `result.log.mistakes()` by `actor_id`. Delta source order: `_state.get("last_attempt_morale")` (null-safe until the
  handoff lands) → `last_wipe_penalty` → own `morale_log` day delta → null.
- Cause chain: `_index_mistakes` / `_mistake_id` ("actor:rN:TYPE") / `_cascade_depth` / `_cause_line`
  ("→ set up by X's Y") — cascaded rows indented `18 * depth` via `_indented`. `caused_by` is never set by the sim
  today (RaidSim's own comment), so the path is proven only by the unit test with a synthetic cascade — honestly
  recorded in the report.
- Story rows: `Widgets.log_row(text, tone, badge, _log_icon(e))` with `Icons.at("log", kind)` / `Icons.at("state",
  key)` (COMBAT-06). All the log_/state_ files named exist in `icons/grid/`.
- Strip: `Cards.roster_strip(_card_host, _state, _page, opts)` with `card_builder` → `_strip_card` (kit card,
  FALLEN_TINT, `Widgets.stamp_box("FALLEN")` at card-local (14,58)); `_pager`, `CARD_X0/CARD_PITCH/CARD_W/PAGE/PAGER_X`
  deleted (COMBAT-19). `Kit.gd:217` references `Widgets.CARD_X0` (the kit's own constant) — unaffected.
- Panel: `PANEL_RECT` (358,100,820,616) → (358,88,820,634), `PANEL_PAD` 14; right column = `RightColumn` VBox holding
  the ScrollContainer + rule + exits (exits pinned); `_exit_row` is an HFlowContainer; `_fallen` scales the cell width
  through `Type.at(metrics.x, scale)` (identity at 100 — `fallen_metrics()` static contract untouched).
- Forbidden patterns: `grep create_tween|reduced_motion|class_name` → none (the two `class_name` hits are
  `Enums.class_name_of`, a method). `_ready()` → `build()` is the pre-existing one-liner every screen uses (Town.gd:127).
- Minor code observations (not defects): `_refresh_morale()` now calls `_refresh_by_raider()`, and `_morale_section()`
  runs `_refresh_morale()` at build, so the tally is built twice on first build (queue_free + rebuild; harmless).
  `Results.gd:715` `pick.add_theme_font_size_override("font_size", Type.SMALL)` (pre-existing, untouched) bypasses
  `Type.at` scaling on the loot row's OptionButton — the clear branch was not shot at 150 (the plan's shot list
  only names the wipe at 150), so this is unobserved; belongs to whoever next touches the loot row.

## 3. Tests observed (through the lock)

- `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` → **exit 1**, `TESTS FAILED 1/1801`:
  the only failure is `test_town_layout.gd :: test_the_locked_blacksmith_is_the_same_height_dimmed_with_a_one_line_reason`
  ("expected ~58, got 85; locked plate 85 tall") — W2-TOWN's new test against Town.gd, in flight; no Results code
  or test in the trace. LINT OK, MOTION LINT OK, PARSE_CHECK 166 scripts, gen check PASS, ART CHECK 0 DIFFERS.
  `.verify.log` also carries 8× `ERROR: Must be an ancestor of the control. (scroll_container.cpp:366)` — the
  one-file Results run below (11 mounts through a Router into a TestHost) produces none, so they are another
  screen's.
- One-file scratch runner (scratchpad, not the repo) over `tests/unit/test_results_report.gd`: **12 tests, 0 failing**,
  no engine errors — tally names/sort/sum/Fallen-Stood, signed deltas, reasoned Suggested on wipe + enabled and
  hand-out on clear (`FIXTURE raid:clear A0 seed=25`), exits enabled/FOCUS_ALL + asserted strings, Headline stamp
  rotated 2-7°, four FALLEN stamps, pager pair, RankSigil + untouched day Label, cascade indent, log glyph, COMEDY_LINE.
- `tests/unit/a11y_smoke.gd` through the lock → `A11Y SMOKE PASSED 26 screen mount(s)`; Results rows:
  empty `owner='Back to the board' ring=2 focusable=2 reachable=2 disabled=0`; fixture `owner='<Button PagerPrev>'
  ring=5 focusable=4 reachable=5 disabled=1`; no `warn` for Results.

## 4. Shots re-taken (§0.3 grammar, one lock hold, all viewed with Read)

- `build/shots/review-W2-RESULTS-wipe.png` (`--fixture=raid`): lockup inside the 352 plate — measured rightmost
  wordmark ink x = **327** (≤ 344); grey shield sigil before "Day 24 · Unknown"; "It's a wipe!" in a red-rimmed box
  visibly leaning; right column: Loot → dimmed "Suggested — give everything" with the caution-coloured reason under
  it; "By raider" twelve rows portrait · name · blot · count · -11 · Fallen, sorted 4/3/3/2/2/2/2/2/2/1/1/1 (sum 25 =
  "Mistakes 25"); "The mood afterwards" + flask hint; exits "Back to the board" / "Return to town" at y ≈ 662-692,
  no scrollbar. Measured: lowest inked y in x 806-1150 = **692** (≥ 650); mean luminance of that region 29. Strip:
  "Party 12" roll-call (eight faces — the kit's cap), four grey cards with a leaning red FALLEN stamp across each
  portrait's lower half, ◄ at x ≈ 131 and ► at x ≈ 1035 on one line with "1/3" under the right gutter — a pair,
  not a stack. Story rows carry the system/mistake glyphs.
- `build/shots/review-W2-RESULTS-clear.png` (`--fixture=raid:clear`, seed 25): "Cleared.", "A0 — Adventure 0",
  blurb; "Payout 4 G" + sell note; Suggested LIT; "Sell all unusable (+0 G)" dimmed with "Everything here fits
  somebody."; the hand-out row — Cracked Charm of Power · Trinket · "Sell 1 G" · "Bork · Warrior (+1)" dropdown ·
  "Give"; By raider — Rhona 3, Gruk 2, Bork 0, Greg 0, morale "—", all Stood; "Morale has already settled from this
  one."; both exits. Gold rank sigil before "Day 24 · Known".
- `build/shots/review-W2-RESULTS-t150.png` (`--fixture=raid --set=text_scale=150`): panel keeps 820 wide; the filing
  block's three lines stack inside the 106px plate; both columns scroll with a visible bar; the fallen grid four to a
  row with whole class names; loot button wraps to two lines and its reason wraps; tally rows tight ("4 -11 Fallen")
  but every Label whole; exits stack. The kit card's band line ("Warrior — Quite Hap", "Cleric — Slightly Ann")
  overruns the card — Cards.gd's, filed in the handoff for W3-KIT2. No Label Results owns is clipped.
- `build/shots/review-W2-RESULTS-completed.png` (`--fixture=raid --completed`): the crimson "See how it ended" is the
  only exit, pinned under the column; the column above scrolls with its bar and the flask line sits at the fold;
  "Fallen" in the tally is pressed against the bar but whole. As the report says.
- `build/shots/W2R_wipe_crops.png` (the unit's 3x crop) viewed: "Bork — 74" carries the authored pixel face glyph,
  not a system emoji — COMBAT-10 verified as claimed.
- refdiff Results vs 2, mask 210,77,928,640, run by the reviewer: unit's before shot `W2R_before_Results.png`
  mae 32.015 · iou 0.0745 · palette 0.6322 · within_8 24.76; reviewer's wipe shot mae **32.297** · iou 0.0750 ·
  palette 0.6211 · within_8 24.73. Matches the report's numbers (32.294) to the third decimal; flat within noise,
  palette improved, recorded.

## 5. Acceptance lines (plan §3 W2-RESULTS)

| Line | Verdict | Evidence |
|---|---|---|
| `test_results_report.gd` asserts a "By raider" Label and one name Label per party member | met | test_results_report.gd:146-160; 12/12 green in the one-file run and inside the suite |
| "Suggested — give everything" disabled with its reason on the wipe fixture and enabled on the clear fixture | met | :204-233 (reason "Nothing dropped…", enabled on `apply_clear`, press empties `pending_loot`); wipe/clear shots |
| `test_screens.gd:606-632` (Return to town / See how it ended) green | met | in the 1800 passing of verify --fast; completed shot shows the CTA alone |
| `test_full_loop.gd:265-268` (Cracked Charm) green | met | in the suite; the clear shot's loot row names "Cracked Charm of Power" |
| wipe shot's right column filled to ≥ y 650 | met | measured lowest inked y 692 on review-W2-RESULTS-wipe.png |
| the pager reads as a pair | met | ◄ x≈131 / ► x≈1035 on one y; test_the_pager_is_the_kit_pair… green |
| stamps rotated | met | headline and four FALLEN boxes visibly leaning; test asserts 2-7° |
| the clear shot shows the hand-out rows | met | review-W2-RESULTS-clear.png: Cracked Charm row with Sell/Give/dropdown |
| refdiff Results vs 2 masked recorded | met | report has before/after; reviewer reproduced both numbers |
| Shots: raid / raid:clear / raid --completed / text_scale=150 | met | all four re-taken and viewed above |
| Green: the seven strings stay; both exits enabled; spaces indentation | met | grep of Results.gd for each string; a11y fixture sweep disabled=1 (Suggested only); 0 tab-led lines |

## 6. §0.5 / Green checks

- Label/Button texts read by tests unchanged: "Return to town", "Back to the board", "See how it ended",
  "No attempt to report", "Rounds", "Mistakes", "What happened", "It's a wipe!", "FALLEN", "Day %d  ·  %s",
  `fallen_metrics/fallen_gap/FALLEN_CELL*/PANEL_RECT/LEFT_COL_W` statics — all present; test_results_screen,
  test_raid_plan's Results block, test_log_player, test_full_loop green in the suite.
- No `create_tween`, no `reduced_motion` branch, no `class_name` in Results.gd; MOTION LINT OK.
- Every visible BaseButton FOCUS_ALL: `Widgets.button` is a plain `Button` (default FOCUS_ALL); pager arrows FOCUS_ALL
  (test asserts); OptionButton default FOCUS_ALL; a11y reachable == ring on both sweeps.
- Disabled controls state their reason: Suggested and Sell-all both through `Widgets.reasoned` (a `Reason` Label).
- Overlays MOUSE_FILTER_IGNORE: stamp boxes (kit), Filing/Filed containers, sigil/portrait/blot TextureRects.
- No new PNG, no `.import` needed, no baked text; no `$GODOT` call in any script the unit added (the test is a
  TestCase; no shell script added).
- Nothing parented to the router host (test_screens' router test green; the screen adds to itself only).
- No new theme variation; no font size set outside `Type.at` in the unit's new code (the pre-existing :715 note in §2).
- Handoff: four `## N. game/core/GameState.gd:<line>` edits, each an `old:`/`new:` fenced pair; every `old:` block
  matches the tree verbatim at the cited lines (352, 612, 1251, 2361), four-space indentation like the file;
  `_apply_morale` returns `float` so the typed `net`/`ko` assignments parse. Applies cleanly.

## 7. Judgement calls vs §6

- COMEDY_LINE "as_built" (Q12b) — the §0.6 default; nothing decided for the designer.
- Rank sigil at native 28px instead of the plan's 16px — a unit-level deviation, recorded in the report with a
  reason (no 16px rank role exists in the grid; a downscale would blur). Not §6. Minor.
- Copy: the mood sentence reworded ("That cost the party N points of morale between them." → "That cost N morale
  between them."), the wipe's "No payout — nothing was cleared." folded into the reason, "No payout this time." added.
  §6 Q12 reserves combat copy (a)/(b)/(c) only, none of which this touches; no test reads the old strings. Minor —
  an unrequested copy change the designer may want to see.
- FALLEN stamp across the portrait rather than top-right — placement is the unit's; recorded. Fine.
- The morale ledger handoff adds a display-only GameState dictionary; no canon number moves. Fine.

## Minor issues (none blocking)

1. Tally rounding vs the sentence: twelve rows read "-11" (sum 132) while "The mood afterwards" says "That cost 130
   morale between them." — per-row rounding of a ~-10.8 hit vs rounding the total. The report's line
   "-11 × 12 = 130" is arithmetically wrong; the number on screen is a rounding artefact, not a wrong source.
2. The a11y fixture-sweep owner is `PagerPrev` (strip precedes the panel in tree order), so keyboard entry lands on
   the strip's arrow rather than an exit — same as before the change (the old `_pager` lived in the same host);
   the plan pins only "both exits enabled". Worth a look in W3.
3. "Return to town" is not `ButtonQuiet` — the wave-2 blanket says every screen unit turns its "Back to town/menu"
   quiet, but TOWN-31's index names only Town/Board/Tavern/Market, Results' contract does not cite it, and Results'
   two exits are both secondary by design (comment at :1260). Ambiguous; recorded.
4. `Results.gd:715` (pre-existing) sets the loot dropdown's font size to `Type.SMALL` un-scaled; unobserved because the
   clear branch is not in the plan's 150 shot list.
5. The "Party 12" roll-call shows eight faces (kit cap) — filed in the handoff as an observation, correct.

## Verdict

**PASS** — every acceptance line met on the tree; verify --fast's single red is W2-TOWN's test against Town.gd,
not this unit's; minors listed above.
