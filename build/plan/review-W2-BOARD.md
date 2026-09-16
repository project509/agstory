# review-W2-BOARD — adversarial review of "the Adventure's Board becomes a board and a keyboard can pin a notice"

Reviewer: wave-2 adversarial reviewer. Verified against the TREE, not the report. Written as I go.

## 1. Ownership / diff

- `git status --porcelain`: owned files changed: `game/screens/AdventureBoard.gd` (M, +444/-98), `tests/unit/test_board_rows.gd` (new, 425 lines) + its `.uid`. Report and handoff present.
- Other changed files in the tree (NOT owned by this unit; other wave-2 units own them): stage_*.json x4, camp/guildhall plates + camp.json/guildhall.json deletions, Market.gd, RaidView.gd, Results.gd, Tavern.gd, Town.gd, SceneStage.gd, test_scene_stage.gd, patch_bubbles.py, plus the other units' test files and plan files, `aguildstory.zip` (untracked, pre-existing). Nothing in the AdventureBoard diff or the report attributes any of those to this unit. No `Frame.gd`/`Theme.gd`/`Widgets.gd`/`Icons.gd`/`Cards.gd` change in the tree (all clean).
- Indentation: `AdventureBoard.gd` 597 tab-led lines, zero space-led lines (grep `^ +\S` empty). `test_board_rows.gd` 0 tab-led, 308 space-led. Correct per file.
- Every kit symbol the screen names exists at wave start (committed in 8f400f9): `Theme_.current/scale_of`, `Frame.standard_chips/focus_order/sidebar`, `Widgets.stamp/empty_state(text, glyph)/button/secondary/panel/content_of`, `Cards.encounter_art(enc, size)`, `Icons.at` with roles `lock` (grid/lock_16.png) and `empty` (grid/empty_quill.png), theme `ButtonNotice` (via `_button`, Theme.gd:433), `PanelCork` (:329), `PanelPaper` icon `pin` (:331).
- Scans of the owned screen: no `create_tween`, no `reduced_motion`, no `class_name`, no `.png` path (the old `ICON` const and `_chips()` deleted), no tooltip-only text, no `_ready()` logic beyond the pre-existing `build()` call, nothing parented to the router host, no new PNG (Assets: none), no `$GODOT` call in either file. `LOCKED_DIM = Color(1,1,1,0.7)` is a modulate multiplier, not a painted white.
- Handoff: one observation (grid tick), zero edits — nothing to apply.

## 2. Runs (all through `tools/with_godot_lock.sh`)

- `verify.sh --fast` → exit 1. LINT OK, MOTION LINT OK, PARSE_CHECK 166 scripts, gen 16 agree, ART CHECK 184 agree 0 DIFFERS; unit tests `TESTS FAILED 1/1801`: the only failure is `test_town_layout.gd :: test_the_locked_blacksmith_is_the_same_height_dimmed_with_a_one_line_reason` (expected ~58, got 85) — W2-TOWN's file, reads Town.gd, does not mount the Board. Same as the report claims.
- Per-test runner (scratchpad, same setup as run_tests.gd) over test_board_rows + test_raid_plan + test_screens + test_full_loop + test_a11y: `REVIEW RUN 140 test(s), 0 failing`; all 11 test_board_rows cases printed PASS by name.
- `a11y_smoke.gd`: `ok empty AdventureBoard.tscn owner='Camp' tab ring=2 rail=6 focusable=7 reachable=8 disabled=1`, `ok fixture AdventureBoard.tscn owner='Camp' tab ring=4 focusable=22 reachable=22 disabled=10`, no `warn` line, `A11Y SMOKE PASSED 26 screen mount(s)`.
- shot.gd `--focus --tab=N` printed the live ring: `TAB 1 -> Notice_t1_tut_a0<Button> at 274,198 412x207`, `TAB 2 -> @Button@280` (sidebar "Go to prep" 1174,402), `TAB 3 -> PagerPrev`, `TAB 4 -> Nav_home` (ring closes). With `--fixture=raid:clear`: `TAB 1 -> Notice_t1_tut_a0 412x111` (no skip block on a cleared paper).
- Harness noise: 8 `ERROR: Must be an ancestor of the control. ensure_control_visible` lines at exit — deferred `ensure_control_visible` on rows a later `_refresh` detached (the harness never runs a frame). Only AdventureBoard.gd:890/:920 call it; the old file had the same deferral in `_refresh`. Not a live-play error path (see minors).

## 3. Shots taken and viewed (build/shots/review-W2-BOARD-*.png)

- `fixture.png` (viewed + list crop x2): cork tile (dark speckled brown, sampled (48,33,25)) at 228..718; "Tier 1" LabelLabel divider; four papers each with the red pin head top-centre; the ladder line (2px, sampled (128,111,100) at x 257-258) down the left with the pin glyph on A0 and padlocks on TR/A1; A0 selected with the steel rim; "LOCKED" stamps in CAUTION; the bronze bar grabber at x 690-699 y 175..345 inside the rim; the A1 row's last line "spellbook." dimmed into the 24px fade at the list foot. The skip warning + "Skip the tutorial" on A0's paper. Sidebar: bronze side rims x=1143 end at y=707 (host bottom 714), "Back to town" whole at y≈561.
- `focus_tab1.png` (viewed crop + pixel samples): 3px of (75,131,163) EDGE_STEEL around Notice_t1_tut_a0 (1px selected rim + 2px focus ring, same colour) — ring on the paper, outside its rim, right edge clear of the bar.
- `focus_tab3.png`/`tab4`/`tab5`: ring on PagerPrev / Nav_home / back on the notice (region step, ring closes).
- `cleared.png` (`--fixture=raid:clear`, viewed crop): gold tick on A0's rung, green "CLEARED" stamp, green facts "· CLEARED"; TR now open with the pin on its rung; A1/A2 padlocked with "Clear TR first."
- `text150.png` (viewed): papers stay inside the cork (right edge 685, bar at 695), rung title and facts wrap and grow the row; skip block on A0's paper; sidebar without the quip teaser; rims end y=712; "Back to town" whole at y≈667; no clipped Label owned by this screen.
- `completed.png` (viewed): "The campaign is finished. The guild is not." + "Legendaries 0 of 9 · Records 0 of 40" under the subtitle; list shrinks and still scrolls; rims end y=707.
- `empty.png` (no fixture, viewed + crop): cork, "Nothing is pinned…" Label at the TOP of the cork void with no visible glyph (see minor M1); the sidebar's empty state shows the quill glyph centred with its sentence; "Back to town" at y≈667.
- Implementer's `W2B_AdventureBoard.png` vs my `fixture.png`: the list region (470..720 x 175..431) has zero pixels differing by >8 — the report's shots are the tree's output.
- refdiff `fixture.png` vs concept 1: mae 27.426 / iou 0.140 / within-8 41.52 (report: 27.431 / 0.14 / 41.52; BUILD_STATE wave-1 baseline board vs 1: 28.63 / 0.143 / 39.2). mae and within-8 improve, iou −0.003 (jitter). No regression.

## 4. Acceptance lines (00-plan §3 W2-BOARD)

| Line | Verdict | Evidence |
|---|---|---|
| a11y_smoke prints no `warn` for AdventureBoard and the Tab ring includes `Notice_A0` | met | smoke: two `ok` lines, no `warn`; shot.gd `TAB 1 -> Notice_t1_tut_a0` (the node is `Notice_<id>`, id `t1_tut_a0`; nothing reads the literal `Notice_A0`) |
| `test_board_rows.gd`: Tab through rows updates the selected id | met | `test_the_scene_region_opens_on_the_first_notice_and_the_arrows_walk_the_rows` walks `focus_neighbor_bottom` and emits `focus_entered`, asserting `_selected` per stop; `test_focusing_a_notice_pins_it…` — all 11 PASS |
| `test_raid_plan.gd`, `test_screens.gd:256-288`, `:689-723`, `test_full_loop.gd` green | met | per-test run 140/140 green; verify --fast lists none of them |
| shot shows cork, pinned papers, rung icons, a scrollbar or fade at the list bottom, "Back to town" whole inside the sidebar | met | §3 fixture.png: cork sampled, pins, pin/padlock/tick glyphs, bar at x 690-699 + fade dimming "spellbook.", sidebar rims end 707 ≤ 714, back button at y 561 |
| refdiff AdventureBoard vs 1 recorded | met | report: before 28.868 / after 27.431; reproduced 27.426 on my shot |
| Green: rung Button text "<slot> — <name>" unchanged; "tutorial · skippable", "Skip the tutorial", "Go to prep", "Selected Notice" Labels/Buttons; `ButtonNotice` with the focus ring | met | AdventureBoard.gd:343 `"%s — %s" % [e.slot, e.display_name]`, :528, :698, :628, :560; Theme.gd:433 `_button(t, "ButtonNotice", …)`; ring visible in focus_tab1.png |

§0.5 checks: Label/Button texts and names read by tests unchanged (test_full_loop presses "A0"/"A1"/"Skip the tutorial" by fragment — green); every visible BaseButton FOCUS_ALL (smoke focusable=22 reachable=22); disabled rung and disabled "Go to prep" each have an adjacent CAUTION Label with the reason (:388-392, :640-648); no tween at all in the file (lint OK); no `reduced_motion` branch; Fade/Pin/Words/Ladder all MOUSE_FILTER_IGNORE; no baked text, no new PNG; handoff has no edits to check.

## 5. Judgement calls vs §6

J1-J9 checked against §6's Q01-Q18: none of them touches a designer-reserved question (Q15 is about surfacing tutorial lessons on RaidView/Results; the unit kept the Board blurbs). J5 (skip block moved from the sidebar onto the selected tutorial's paper) is a layout choice inside the unit's own screen; docs/13 pins no location, docs/10 §9.3's two copy requirements are still met verbatim, and test_full_loop still finds exactly one "Skip the tutorial". Not a blocker; see M3 for the stale build-plan sentence it leaves behind.

## 6. Issues

No blockers. No unmet acceptance line. Minors:

- M1 (minor, unit-owned, one line): the LIST-side empty state is not KIT-08's outcome — `_list_host` (`Rows`) has only `size_flags_horizontal = EXPAND_FILL` (AdventureBoard.gd:216), so inside the ScrollContainer it takes its minimum height; the `empty_state` Label sits at the top of the 500px cork void and its quill glyph (anchored above the Label's centre) is clipped out of view (empty.png crop). Fix: `_list_host.size_flags_vertical = Control.SIZE_EXPAND_FILL`. Reachable only when no content is loaded (Boot always loads content; the sidebar's empty state in the same shot is correct), which is why this is minor — but report line A8 is ticked without an empty shot having been looked at.
- M2 (minor, unrecorded): the wave-2 header asks every screen unit to adopt `Widgets.reasoned` where it has a disabled control; the locked rung Button (:388-392: own CAUTION `why` Label, LOCKED stamp, 0.7 dim on quip/facts) and the locked "Go to prep" (:640-648: the pre-existing `note` LabelCtaCost) keep bespoke treatments. §0.5's contract (reason in an adjacent Label) is met and both are defensible on this layout, but the choice is not in the report's judgement calls.
- M3 (minor, doc debt): `build/plan/q-tutorials.md:124-126` still says the skip lives "in the Selected Notice sidebar, beneath the existing Go to prep CTA"; J5 moved it to the paper. Not canon (a build decision doc), not the unit's file, but the handoff should have flagged the sentence for the orchestrator.
- M4 (minor, design note for W3/the designer): because focus pins (as the plan asked) and Frame's region entry is always `members[0]`, Shift+Tab from the sidebar or Tab from the rail lands on `Notice_t1_tut_a0` and re-pins A0 — a rung the player pinned with the arrows is un-pinned by region navigation. Inherent to `Frame._wire_regions` + the plan's own request; not fixable inside AdventureBoard.gd alone.
- M5 (minor, theme-level): the selected paper's rim (`notice_p`, EDGE_STEEL) and the focus ring (EDGE_STEEL) are the same colour, so selected-and-focused differs from selected only by a 1px→3px line (focus_tab1.png samples). Theme.gd's decision (W1-CHROME), consumed as-is.
- M6 (minor): the hand-rolled deferred `ensure_control_visible` (:890, :920) prints 8 `Must be an ancestor` errors at harness exit; `ScrollContainer.follow_focus = true` would follow the arrows for free (including the rung/skip Buttons inside a row, which `_select`'s early return never scrolls to). Harness-only noise; no live path found where the scroll is alive and the row detached in the same frame except an arrow-pin immediately followed by a skip press.
- M7 (note): `Notice_A0` in the acceptance is shorthand — the node is `Notice_t1_tut_a0` per the plan's own `Notice_<id>`; a11y_smoke does not read names.

## 7. Report claims checked

- "all 11 test_board_rows cases … green" — observed. "1/1801 failing, test_town_layout" — observed, and it is W2-TOWN's file. "a11y_smoke no warn, PASSED 26" — observed. "refdiff 28.87→27.43 / 0.142→0.140 / 39.1→41.5" — reproduced (27.426). "sidebar fits inside 714 at 100 and 150" — measured 707 / 712. "Shots viewed" — the W2B_* files exist and their list region is pixel-identical (≤8) to my re-take. No false claim found.

## Verdict: PASS (minors only)

verify --fast observed: FAIL — one test outside this unit (`test_town_layout.gd`, W2-TOWN). Every test this unit owns or is contracted to keep green is green.
