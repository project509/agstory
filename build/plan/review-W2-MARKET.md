# Review — W2-MARKET (the Market becomes a shop) — PASS 2 (after the repair pass)

Adversarial review of the tree (not the report). Written as findings land. Pass 1 (below, kept
for the record) found one blocker (the sell slot's rim hidden under the seven opaque gear crops),
one major escalated to the orchestrator (the fountain clause vs PLATE_OFFSET) and three minors.
This pass re-verifies the repair against the tree: `git diff`, the suite, `verify --fast`, re-shot
acceptance shots viewed with the Read tool, every acceptance line, the §0.5 contracts, §6.

Owned files: game/screens/Market.gd (SPACES), tests/unit/test_market_grid.gd (new).
Plan: build/plan/artaudit/00-plan.md "### W2-MARKET"; RULES.md §1 test_market.gd row.

## 1. Ownership (git status / diff) — pass 2

- `git status --porcelain`: ` M game/screens/Market.gd` (+576/-243, 1107 lines), `?? tests/unit/test_market_grid.gd` (418 lines, 14 `func test_`) + its `.gd.uid`, `?? build/plan/{report,handoff,review}-W2-MARKET.md`.
- Changed files NOT in the owned list: `game/screens/{AdventureBoard,RaidView,Results,Tavern,Town}.gd`, `game/ui/SceneStage.gd`, `game/assets/scenes/stage_{camp,market,tavern,town}.json`, deletions of `game/assets/bg/{camp,guildhall}_plate.png(.import)` and `game/assets/scenes/{camp,guildhall}.json`, `tests/unit/test_scene_stage.gd`, `tools/art/patch_bubbles.py`, the other units' `test_*.gd`/reports/handoffs/reviews, `aguildstory.zip` (untracked). Every one is in another W2 unit's ownership row (00-plan.md:224) or is orchestration output; nothing in the Market diff, the report or the handoff shows this unit wrote any of them. `handoff-W2-MARKET.md §1` (stage_market.json speaker 5→4) is a handoff marked "already in the tree, skip" — attributed to W2-STAGE2, whose own handoff describes the re-placement.
- `tests/unit/test_market.gd`: not in `git status` — unchanged.
- Read the whole of Market.gd (1107 lines) and test_market_grid.gd (418 lines) in this pass.
- Repair-pass diff points, verified in the tree: `b.expand_icon = false` at Market.gd:696 (after `Widgets.slot_button` at :689, whose own body sets `expand_icon = true` when an icon is given — Widgets.gd:830); `_sell_all_row` :640 `b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART`, no `clip_text`/`OVERRUN_TRIM_ELLIPSIS` left in the file (grep: 0 hits for `TRIM_ELLIPSIS`); two new tests at test_market_grid.gd:244 and :268.

## 2. Static contract checks (pass 2)

- Indentation: 0 tab-led lines in Market.gd and test_market_grid.gd; 0 trailing-whitespace lines.
- `create_tween`: 0. `reduced_motion`: 0. `class_name`: only `Enums.class_name_of` (:966), a method. `RichTextLabel`/`LinkButton`/`await`/`MORALE_BAND_EMOJI`/`$GODOT`: 0. `_ready()` → `build()` guarded by `_built` — HEAD:105 had the same pattern.
- `Widgets.reasoned` is the only reason door (1 call, :370); `slot_with_reason`/`button_with_reason`: 0 (HEAD:574 called `slot_with_reason`; the tree's `_reasoned` wrapper only adds the wrap width). `_chips`: gone (HEAD:217); `Frame.standard_chips` :186, `Frame.refresh_chips` :532.
- Every kit symbol Market.gd names exists in the (unmodified) kit files: Widgets `slot_button/tab_row/tabs_of/reasoned/confirm_pair/cta/slot/empty_state/label_as/panel/content_of/rule/column/row/button`, Frame `build/sidebar/standard_chips/refresh_chips`, Theme_ `flat/scale_of/current`, Cards `gear_icon/morale_glyph/portrait_for/roster_strip/event_log`, Palette `rarity_color/morale_color/RARITY/SURFACE_SLOT(_LIT)/ACCENT_GOLD/CAUTION/TEXT_*`, Type `at/gold/STACK/SCALES`, `Icons.at`. No same-wave function is called.


- Repair R1 mechanism checked against the assets: every `Cards.gear_icon` route resolves to a 39x39 `item_*.png` (35 files) or a 32x32 `slot_*.png` fallback (PIL scan); the seven opaque crops (`item_gear_0/1/2`, `item_reward_0..3`) are alpha 255 everywhere. At 1:1 the widest icon (39) + 2x2px rim = 43 < 47, so the rim shows on every route — `test_a_sell_slot_keeps_its_rim_clear_of_the_icon` (test_market_grid.gd:259) asserts exactly that inequality per WornGrid Button. `clip_text = true` (`_mute_text`, :739) keeps the transparent sentence out of the min-size, so the Button stays 47 with `expand_icon = false`.
- Implementer's own shots re-measured (scratchpad/rim.py, gold (237,168,70) ±8, y 300..720, x 200..800): `W2M_Market.png` 352 gold px, bbox (268,435)..(314,481) = 47x47 (Worn Iron Cap); `W2M_Market_confirm.png` 352 gold px, bbox (352,435)..(398,481) = the second slot (Damaged Chainmail); pass 1's `review-W2-MARKET-confirm.png` 0 gold px. The report's pixel claims for R1 reproduce.
- Geometry re-derived from the tree's JSON (`stage_market.json` speaker 4, shimmer [700,440,180,120]; `actors.json` frames) at PLATE_OFFSET (-420,-300): band = plate x 998..1349, y 300..940; actors 3-7 whole (5), speaker 4 at 1130 → speech plate 1039..1221 inside the band (`SceneStage._anchor_speech` :1713 centres on `head_of`); shimmer x 700..880 under the ledger. At (-250,-300): 4 whole, plate cut 42px at band end 1179. The handoff's stated trade is arithmetically right.
- RULES §1 test_market.gd strings each grep to a source: "Sell all nobody can wear" (Market.gd:634), "(%d → %d)" (:634), "worn by %s" (:418), "take it off" (:436), "Minor — 8 G" (:848 caption format), "(1 held)" (:851), "Nothing to sell" (:570), "Nobody to buy for" (:901), "better stall" (:348); "One trestle table" (Consumables.gd:309), "does not carry the" (Consumables.gd:355), "Straw Cot" (Comfort.gd), "Costs %d G" (Buildings.gd:170). test_market.gd reads no node names (only GameState/ScreenRouter on the root).
- Overlays: spacer/CenterContainer/TextureRect/captions/numeral `MOUSE_FILTER_IGNORE` (:302, :472, :478, :732, :881). Font sizes: the two overrides go through `Type.at` (:875, :983). Colour literals: `SCENE_DIM` modulate (HEAD:86 had it), `Color(0,0,0,0)` transparent font (HEAD:663), `Color.WHITE`/`(1,1,1,0.7)` modulate (HEAD:334/337) — nothing new, no painted pure black/white.

## 3. Tests, verify --fast, a11y, lint (observed, pass 2)

All through `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh …` in one sequential batch (scratchpad/batch.sh, 19:12-19:14).

- `./tools/verify.sh --fast` (scratchpad/verify_fast2.log): `PASS class cache regenerated` · `PASS LINT OK` · `PASS MOTION LINT OK` · `PASS PARSE_CHECK scanned 166 script(s)` · `PASS 16 generated file(s) agree` · `PASS ART CHECK 184 agree 0 DIFFERS 0 MISSING` · `PASS TESTS PASSED 1806 test(s) in 86 file(s) [38977 ms]` · **VERIFY OK**. The test_town_layout.gd failures the implementer saw are gone from the tree (W2-TOWN's later edit); **verify --fast observed: PASS.**
- 1806 = the sum of `func test_` across the 86 `tests/unit/test_*.gd` (counted), so `test_market_grid.gd` (14) and `test_market.gd` (34, unchanged in git) are in the passing set; the runner prints only failures and printed none. No `SCRIPT ERROR`/`push_error` in any log of the batch.
- `tests/unit/a11y_smoke.gd` (scratchpad/a11y2.log): `ok empty Market.tscn owner='Camp' tab ring=3 rail=6 focusable=10 reachable=12 disabled=2` · `ok fixture Market.tscn owner='Camp' tab ring=4 rail=6 focusable=61 reachable=61 disabled=3` · `A11Y SMOKE PASSED 26 screen mount(s)`; 0 `warn` lines.
- refdiff on my re-shot vs 3, mask 0,77,1536,649 (scratchpad/diff): mae 36.73 · rmse 69.142 · structure 0.1918 · iou 0.1013 · within_8 50.9 — identical to the report's; baseline build/diff/W1STAGE_Market_diff.json 36.766 / 0.10 / 50.81. No regression.

## 4. Shots re-taken and viewed (pass 2)

`tools/with_godot_lock.sh "$GODOT" --path . --script res://tools/shot.gd -- res://game/screens/Market.tscn build/shots/review-W2-MARKET-p2-<name>.png 40 1536x1024 <flags>` — all four `SHOT OK`, presses `PRESS ok`; each viewed with the Read tool (full frame and 2x/3x crops in the scratchpad).

- **review-W2-MARKET-p2-fixture.png** (`--fixture`): as pass 1 — ledger 560 on the left with "Market" / "Consumables in, salvage out." in its bar, Sell lit, the dimmed sell-all with its CAUTION reason, "In the window · 0" + shelf glyph + "Nothing found yet — raid first.", "Worn by the roster · 48" as a 6-column grid of 47px slots with names under them; sidebar card (icon on a 94px rimmed slot, "Worn Iron Cap / Head / worn by Bork / Sells for 1 G", crimson "Sell — 1 G"), the stall block, quiet "Back to town". **The R1 fix is visible:** at 3x (scratchpad/p2_grid_3x.png) the Damaged Chainmail slot now shows its grey common rim around the opaque navy chest crop with a thin band of slot fill between them; every slot has a rim; Worn Iron Cap's is gold. Pixel count (rim.py): 352 gold px, bbox (268,435)..(314,481) = 47x47 on Worn Iron Cap. Band right of the ledger (scratchpad/p2_band_2x.png): five whole shoppers (grey-haired top-left, the knight under the whole speech plate "That is a lot of gold for a hat.", one at the ledger's edge, the hooded one with the "…" emote by the cream stall, the dark-haired one before the red tent), three stalls, the cart; **no fountain** (unchanged from pass 1; the JSON arithmetic in §2).
- **review-W2-MARKET-p2-confirm.png** (`--fixture --press="Sell Damaged Chainmail — 1 G"`): **the pressed slot now carries the gold rim** — 352 gold px at bbox (352,435)..(398,481), the second slot; Worn Iron Cap back on grey (scratchpad/p2_confirm_grid_3x.png). The card reads "Damaged Chainmail / Chest / worn by Bork / Sells for 1 G" over the DANGER-rimmed pair: "Yes — take it off Bork and sell it" on two lines in DANGER ink, "Keep it" with the focus ring (scratchpad/p2_confirm_card_2x.png). **Pass 1's blocker is fixed in the tree and seen.**
- **review-W2-MARKET-p2-text150.png** (`--fixture --set=text_scale=150`): the sell-all Button now wraps — "Sell all nobody can wear — 0 G  (12480 →" / "12480)" — the arithmetic whole, the reason under it; the grid reflows to 4 columns with whole captions; the sidebar card, stall, wrapped reason, "Next: …" and "Back to town" all inside the sidebar. **Pass 1's minor 3 is fixed.** (Rail label "Adventure's Board" small and the strip's "Very Happ" are Frame's and Cards' — not this unit.)
- **review-W2-MARKET-p2-buy_held.png** (`--fixture --press=Buy --press="Minor — 8 G"`, scratchpad/p2_buy_2x.png): Buy lit; the potion/flask/whetstone/draught slots with "Minor" / price captions; the Minor Healing Potion slot carries the "1" numeral bottom-right; "Wrapped and put in the pack." in the notice line. Buy untouched by the repair, still right.
- Not re-shot this pass: `--press=Comfort` and the no-flag "Day 1" shot — neither path changed in the repair (the diff touches `_sell_cell` and `_sell_all_row` only); pass 1 viewed both; `test_a_furnishing_cell_carries_its_icon_and_the_reason_it_is_shut` and the a11y fixture sweep cover Comfort. `grep new_game tools/shot.gd` still finds nothing: the plan's "Market (Day 1)" is still not takeable as written.
- One thing seen at 4x that pass 1 did not measure (scratchpad/p2_card_icon_4x.png): the card's icon is soft-edged. `CARD_ICON_PX = 64` with the comment "the 32px icon drawn at exactly 2x" (:119, :463) — but every `Cards.gear_icon` texture the card can show is a 39x39 crop (all 35 `item_*.png` gear files), so the card draws it at 64/39 = 1.64x, a non-integer scale that resamples the pixels. Legible, and the acceptance line says only "a sidebar item card"; the Findings text says "icon 2x". Minor; a 78px box (39 x 2) inside the 94px slot would be the integer scale the comment promises.

## 5. Acceptance lines (pass 2)

| Line (00-plan.md "### W2-MARKET") | Verdict | Evidence |
|---|---|---|
| Market shot shows a slot grid with one selected slot | **met** | p2-fixture: 6-col WornGrid, one gold rim (352 px, 47x47 bbox on Worn Iron Cap); p2-confirm: exactly one gold rim, on the pressed Damaged Chainmail; `test_a_sell_slot_keeps_its_rim_clear_of_the_icon` asserts `lit == 1` on the pressed chest. Pass 1's caveat (no cue on the opaque crops) is gone. |
| … a sidebar item card with a crimson commit | met | p2-fixture: PanelRound card, "Worn Iron Cap / Head / worn by Bork / Sells for 1 G", ButtonCta "Sell — 1 G" (Market.gd:445); `test_the_sell_tab_has_exactly_one_crimson_commit_and_the_buy_tab_none` green. |
| … >= 4 whole actors | met | 5 whole in the band (p2_band_2x.png; JSON: actors 3-7 inside plate x 998..1349 x y 300..940); `test_five_shoppers_stand_whole_in_the_visible_band` asserts >= 4 from the JSON. |
| … and the fountain shimmer | **not met — escalated, not charged to the unit** | Shimmer rect x 700..880 lies under the ledger at the plan's own (-420,-300) (TOWN-22's number). The alternative (-250,-300) shows 52px of shimmer, 4 whole figures, and cuts W2-STAGE2's speech plate 42px at the host edge; no offset gives >10px of shimmer with a whole plate and 4 whole figures. Code comment (:84-92), report (call 1) and handoff now state the full trade. The orchestrator's ruling, as pass 1 said; the unit could not meet this clause without breaking another unit's scene or the plan's constant. |
| … no text drawn directly on the plate | met | Title/subtitle in the ledger's bar (:212-216); the band is bare plate + SceneStage's speech plate (a Widgets plate over the scene, not pixels in the PNG). |
| `test_market.gd` green unchanged (the nine strings) | met | Not in `git status`; 1806/1806 with the runner printing no failure; every string traced to its source (§2). |
| `test_market_grid.gd` asserts selection populates the sidebar and Day-1 opens with an empty window and the worn group | met | `test_the_window_item_is_selected_by_default_and_the_card_describes_it` (:182), `test_pressing_a_worn_slot_selects_it_and_asks` (:199), `test_day_one_opens_with_an_empty_window_and_the_worn_group_open` (:144); 14 cases, all in the passing 1806. |
| refdiff Market vs 3 masked recorded | met | Reproduced on p2-fixture: 36.73 / 0.1013 / 50.9 vs baseline 36.766 / 0.10 / 50.81; in the report's log. |
| Shots: `--fixture`, `--press=Buy`, `--press=Comfort`, Day 1, `text_scale=150` | met / Day-1 unverifiable | Implementer's W2M_*.png (all six, re-measured where it matters) + my p2 set; "Market (Day 1)" is not takeable — shot.gd has no new-game flag; the Day-1 shape is the fixture's empty window + open worn group and the test above. |
| Green: every slot a Button (FOCUS_ALL) with the row's full text; reasons adjacent Labels; spaces | met | `test_every_grid_slot_is_a_focusable_button_carrying_the_rows_sentence`; a11y both sweeps ok, 26 mounts PASSED, 0 warn; reasons via `Widgets.reasoned` -> Label "Reason" (comfort test :326-328); 0 tab-led lines. |
| Findings: `_chips()` deleted + `Frame.standard_chips`/`refresh_chips`; `ButtonQuiet` escape; `Widgets.reasoned`/`confirm_pair`; tab_row; TOWN-28 groups; Buy `Icons.at("item")` + numeral + "(N held)"; Comfort `Icons.at("furnishing")`; `Cards.gear_icon` + rarity rim | met | :186/:532, :309, :370/:435, :258, :594-615, :827/:851/:858, :1015/:1062, :689-703; p2-buy_held numeral; the rim now visible on every crop (p2_grid_3x.png). |

## 6. Green line and §0.5 contracts (pass 2)

- Label/Button texts and node names tests read: unchanged (tab Buttons "Sell"/"Comfort"/"Buy" verbatim :59-63; "Back to town" a Button with `ButtonQuiet` :308-309; the RULES strings in §2). test_market.gd reads no node names.
- Indentation spaces in both owned files (0 tab-led lines); Godot parsed 166 scripts.
- No `create_tween`; no `reduced_motion`; no `class_name` reference; no RichTextLabel/LinkButton; no `await`; no `_ready()` logic beyond the guarded `build()` (HEAD's pattern).
- No script the unit added calls `$GODOT`; the test file has no engine call. MOTION LINT OK observed.
- New PNGs: none. `.import` files: n/a. Every `Icons.at` key the screen names resolved at shot time (no `Failed to load` in any log).
- Router host: the stage and ledger go under Frame's SceneHost (`_frame.scene`, :185/:199/:206); card/stall under the sidebar; strip under `_frame.strip`. a11y "owner='Camp'" on both mounts, one screen child.
- Overlays `MOUSE_FILTER_IGNORE` (§2). Font sizes via `Type.at` (§2). No painted pure black/white.
- Handoff: §1 is an exact `old:`/`new:` pair at the JSON's 2-space indent (already in the tree as `"speaker": 4`, marked skip); the two observations are labelled as such and carry no edit. Well-formed; the (-250,-300) cost is now stated (§2 arithmetic agrees).
- Same-wave calls: none (§2 symbol check against the unmodified kit files).

## 7. Judgement calls vs §6 (pass 2)

The repair pass added no new decision: `expand_icon = false` (the reviewer's first option; a rendering fix) and the sell-all wrap (CRITIC-G15's "fix any clipped Label it owns"; docs/13 §4.4 reflow-never-truncate, the Board's idiom). The eight calls of pass 1 stand as reviewed: none touches Q01-Q18 (figure scale, boss, bubble chrome, levels, copy, CVD, faces, asset scope); the rim reads an existing Palette ramp; the worn order is forced by test_market.gd:475; the default-selection-vs-press behaviour reconciles TOWN-21 with test_market.gd:478-485. PLATE_OFFSET stays the plan's number — the fountain question is escalated, not decided. Nothing reserved for the designer was decided.

## Issues (pass 2)

1. **MAJOR (escalated, unchanged from pass 1; not charged to the unit) — "the fountain shimmer" is not in the shot** at the plan's own PLATE_OFFSET; the handoff now states the whole trade including the 42px speech-plate cut at (-250,-300). Orchestrator's ruling: fountain-with-a-cut-line, crowd-with-a-whole-line (as built), or a W2-STAGE2 JSON change (speaker or shimmer rect).
2. minor — the sidebar card's icon is drawn at 64/39 = 1.64x, not the "exactly 2x" the code says (:119, :463-464; every gear texture is a 39px crop): soft, resampled edges at 4x (scratchpad/p2_card_icon_4x.png). One constant (`CARD_ICON_PX = 78`) would make it integer.
3. minor — the plan's "Market (Day 1)" shot is not takeable with shot.gd's flags (no new-game flag); covered by the test and the fixture's empty window. An instrument gap, not the unit's.

Pass 1's blocker (rim under the opaque crops) — **fixed and seen**. Pass 1's minor 3 (sell-all ellipsis at 150) — **fixed and seen**. Minors 4/5 (report wording) — fixed in the report (the false confirm-rim claim struck through and labelled; only `Widgets.reasoned` named; "one crimson commit" scoped to the Sell state).

## False claims in the report (pass 2)

- None found this pass. Re-measured: the R1 pixel claims (352 gold px, bboxes) reproduce on the implementer's shots and on mine; the refdiff numbers reproduce exactly; a11y counts match; "test_town_layout.gd x3, nothing of Market's" was true of its run (the file is green now); "every gear crop is 39x39" is true of all 35 `item_*.png`. The struck-through 18:40 claim is correctly labelled false.

## Verdict (pass 2)

**PASS** — the one blocker is fixed in the owned file (Market.gd:696) and verified on re-shot pixels and by eye; the suite is 1806/1806 and `verify --fast` is VERIFY OK in my run; a11y both sweeps ok; MOTION LINT OK; refdiff unchanged; ownership, indentation, contracts and §6 clean. Remaining: the fountain clause (an escalated plan inconsistency the unit could not meet without breaking another unit's scene or the plan's own constant) and two minors.

Files: build/plan/review-W2-MARKET.md (this), build/shots/review-W2-MARKET-p2-{fixture,confirm,text150,buy_held}.png (+ pass 1's review-W2-MARKET-{fixture,buy,comfort,text150,day1,confirm,buy_held}.png).

---

# Pass 1 (kept for the record — superseded by pass 2 above)

## P1.1. Ownership (git status / diff)

- `git status --porcelain`: owned files present — ` M game/screens/Market.gd` (+571/-243, a rewrite: 774 → 1102 lines), `?? tests/unit/test_market_grid.gd` (+ `.gd.uid`, Godot-generated), `?? build/plan/report-W2-MARKET.md`, `?? build/plan/handoff-W2-MARKET.md`, `?? build/plan/review-W2-MARKET.md` (this file).
- Other changed files in the tree, NOT this unit's: `game/screens/{AdventureBoard,RaidView,Results,Tavern,Town}.gd`, `game/ui/SceneStage.gd`, `game/assets/scenes/*.json` (+ two deletions each of scenes/bg), `tests/unit/test_scene_stage.gd`, `tools/art/patch_bubbles.py`, the other units' `test_*.gd` + reports/handoffs, and `aguildstory.zip` (untracked, pre-existing). Each is owned by another W2 unit (ownership table, 00-plan.md §3); nothing in the Market diff or report shows this unit touching them. `handoff-W2-MARKET.md §1` (stage_market.json speaker 5→4) is written as a handoff and the report says W2-STAGE2 applied it itself — `git diff game/assets/scenes/stage_market.json` is attributed to W2-STAGE2 (its own report/handoff cover the re-placement).
- Read the whole of the new `Market.gd` (1102 lines) and `test_market_grid.gd` (12 cases). HEAD's `_chips()` (HEAD:217) is gone; `Frame.standard_chips` (:186) / `Frame.refresh_chips` (:532) replace it. HEAD already called `Widgets.slot_with_reason` (HEAD:574) — no private copy remained to delete; the tree calls `Widgets.reasoned` (:341) via a `_reasoned` wrapper that adds the wrap width. The report's line "(`Widgets.reasoned` / `slot_with_reason` / `button_with_reason`)" over-names: only `Widgets.reasoned` is called (grep). Minor wording, same mechanism (CRITIC-G06's one door).

## P1.2. Tests and verify --fast (observed)

- `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (my run, scratchpad/verify_fast.log): LINT OK · MOTION LINT OK · PARSE_CHECK 166 scripts · gen_items 16 agree · ART CHECK 184 agree 0 DIFFERS 0 MISSING · **unit tests FAIL 1/1801** — `test_town_layout.gd :: test_the_locked_blacksmith_is_the_same_height_dimmed_with_a_one_line_reason` ("expected ~58, got 85; locked plate 85 tall vs 58"). That test measures Town.gd's locked callout (W2-TOWN's screen and test file); Market.gd is not on its path. **verify --fast observed: fail, not caused by this unit.**
- Unit suite run directly (`run_tests.gd`, scratchpad/tests.log): `TESTS FAILED 1/1801` — the same single Town failure. The runner discovers `tests/unit/test_*.gd` by directory scan and prints only failures, so `test_market_grid.gd` (12 `func test_`) and `test_market.gd` (34, file unchanged in git) are among the 1800 passing. No `SCRIPT ERROR`, no `Icons.at(...)` push_error, no line mentioning Market anywhere in the 316-line log.
- `.verify.log` in the repo root was 17 lines when I read it (another agent's run had restarted it) — I did not rely on it.
- a11y_smoke: both sweeps ok, A11Y SMOKE PASSED (run through the lock in my batch).

## P1.3. Shots re-taken and viewed

All through `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh "$GODOT" --path . --script res://tools/shot.gd -- res://game/screens/Market.tscn build/shots/review-W2-MARKET-<name>.png 40 1536x1024 <flags>`; each viewed with the Read tool.

- **review-W2-MARKET-fixture.png** (`--fixture`, SHOT OK): the ledger is a 560px PanelWarm on the left of the scene (screen x ≈232..790), "Market" + "Consumables in, salvage out." in its own bar, the kit tab row (Sell lit on the NavItemActive plate with the gold underline, Comfort, Buy). "Sell all nobody can wear — 0 G (12480 → 12480)" dimmed with the CAUTION reason "Nothing in the window is useless to everyone." under it. "In the window · 0" with the shelf glyph + "Nothing found yet — raid first."; "Worn by the roster · 48" is a 6-column grid of 47px slots with gear art and names under them; the first slot (Worn Iron Cap) carries the gold selected rim, the rest a common rim. Sidebar: PanelRound card — icon at 2x on a rimmed 94px slot, "Worn Iron Cap / Head / worn by Bork (CAUTION) / Sells for 1 G (gold)", crimson "Sell — 1 G" (ButtonCta) — then "The Stall  Level 1 of 4", "One trestle table, one vendor, canvas awning", dimmed "Pay for a better stall — 130 G" with "Unknown guilds cannot commission this. Reach Known.", "Next: Second stall, crates, two shoppers.", quiet "Back to town". Header chips "12,480 G · 320 · Roster 12 of 15 · Day 23 · Unknown" from Frame. NOTHING is drawn on the plate but the plate.
  - Band right of the ledger (cropped 788..1139 × 77..717, viewed at 2x): five whole figures — grey-haired by the green awning (top-cut), the knight under the whole speech plate "That is a lot of gold for a hat." with the tail on his head, the brown-haired one just right of the ledger's edge, the one with the "…" emote by the cream stall, the dark-haired one by the red tent. Three stalls (green awning top-cut, cream stall whole, red tent whole) + a produce cart top-right. **No fountain anywhere in the band** — matches the JSON arithmetic below.
  - Geometry check from the JSON (`actors.json` frames, `stage_market.json` positions): at (-420,-300) the band is plate x 998..1349, 5 of 8 actors whole, fountain shimmer [700,440,180,120] 0px visible, speech plate (182 wide on x 1130) inside the band. At the handoff's alternative (-250,-300): 4 whole, 52px of the shimmer's right edge visible, **speech plate x 1039..1221 vs band end 1179 → cut by 42px by the host's edge** (the handoff did not mention this cost). No offset shows a meaningful fountain AND a whole speech plate AND ≥4 whole figures (the interval is ox ∈ (-302,-292], ≤10px of shimmer).
- **review-W2-MARKET-buy.png** (`--fixture --press=Buy`, PRESS ok): Buy lit; "Six goods, six grades. An Unknown guild's custom reaches grade Minor."; one row per SKU (name + rule line) with one 47px slot per stocked grade — at Unknown that is one "Minor" cell each — potion/flask/whetstone/draught icons in the slots, "Minor" and "8 G"/"30 G"/"35 G" captioned under them, no numeral (nothing held). Sidebar: no card (nothing selected on Buy), the stall block, quiet "Back to town".
- **review-W2-MARKET-comfort.png** (`--fixture --press=Comfort`): "The stall carries what an Unknown guild's custom is worth."; "For" + the portrait picker (2×6 tiles, Bork lit on the orange ButtonPortrait rim); "Bork — 87 💚" / "Warrior — Very Happy"; "Furnishings for Bork": Straw Cot (icon, "+3 · 40 G", live), Feather Bed and Hot Meal Standing Order dimmed with "A one trestle table stall does not carry the … yet." in CAUTION wrapped at the cell's width. Three cells to a row, more below the scroll.
- **review-W2-MARKET-text150.png** (`--fixture --set=text_scale=150`): the worn grid reflows to 4 columns; every caption whole ("Worn Iron / Cap", "Damaged / Chainmail"); the sidebar card, "The Stall / Level 1 of 4" on one row, the rung, its wrapped reason, "Next: …" and "Back to town" all fit inside the sidebar. The one trimmed thing this unit owns: the sell-all Button reads "Sell all nobody can wear — 0 G (12480 → 124…" — `clip_text` + `OVERRUN_TRIM_ELLIPSIS` (then Market.gd:639-640) cuts docs/02 §6.3's after-number at 150. (Bork's "Warrior — Very Happ" in the strip is Cards.roster_strip, not this unit.)
- **review-W2-MARKET-day1.png** (no flags, byte-identical to the implementer's W2M_Market_day1.png): the no-guild state — "No guild loaded." chip, "Nothing to sell. Everything the guild owns is being worn or was never found.", the stall block, the square beside the ledger. `grep new_game tools/shot.gd` → nothing: the instrument has no new-game flag, so the plan's "Market (Day 1)" shot is not takeable as written; the Day-1 shape is what the fixture shot shows (empty window, worn group open) and what `test_day_one_opens_with_an_empty_window_and_the_worn_group_open` asserts.
- **review-W2-MARKET-confirm.png** (`--fixture --press="Sell Damaged Chainmail — 1 G"`, PRESS ok): the card now reads "Damaged Chainmail / Chest / worn by Bork / Sells for 1 G" and holds the DANGER-rimmed confirm pair — "Yes — take it off Bork and sell it" on two lines in DANGER ink, "Keep it" with the focus ring (the safe default). Zero crimson controls in this state.
  - **DEFECT (pixel-verified):** the pressed slot showed NO gold rim. Sampling the slot edges: Worn Iron Cap's rim was (237,168,70) gold when selected (fixture) and (155,155,166) grey when not (confirm); Damaged Chainmail's edge was (19,27,37) navy in BOTH shots — no rim, selected or not, and no rarity rim in the fixture shot either. Cause: `Cards.gear_icon` returns `item_gear_1.png` for a plate chest — a 39×39 sliced reference crop that is 100% opaque (likewise `item_gear_0/2`, `item_reward_0..3`) — and `_sell_cell` styled the slot with `Theme_.flat(fill, rim, 2, 4, 0)` (content margin 0) on a `slot_button` whose `expand_icon = true`, so the icon filled the 47px button and painted over its own 2px rim. The implementer's report said of its own confirm shot "the chest slot takes the gold rim" — its W2M_Market_confirm.png had the same navy (19,27,37) edge: that claim was false.
- **review-W2-MARKET-buy_held.png** (`--fixture --press=Buy --press="Minor — 8 G"`, both PRESS ok): the Minor Healing Potion slot carries a "1" numeral bottom-right inside the slot with a dark outline; "Minor / 8 G" captions unchanged. The corner numeral is real.

## P1.4. Acceptance lines — as of pass 1

Slot grid with one selected slot: met with a caveat (no cue on the opaque crops) · sidebar card with a crimson commit: met · ≥4 whole actors: met (5) · fountain shimmer: **not met** (plan inconsistency, escalated) · no text on the plate: met · test_market.gd unchanged and green: met · test_market_grid.gd's two assertions: met · refdiff recorded: met (36.73 / 0.1013 / 50.9, no regression) · shots: met / Day-1 unverifiable · Green line: met · `Cards.gear_icon` + rarity rim: **partly met** (rim hidden on seven crops).

## P1.5. Green line and §0.5 contracts

- Label/Button texts and node names the tests read: unchanged; `test_market.gd` untouched in git; tab Buttons keep "Sell"/"Comfort"/"Buy"; "Back to town" is a Button (`Widgets.button` + `ButtonQuiet`).
- Indentation: both owned files 0 tab-led lines. No trailing whitespace. No `create_tween`; no `reduced_motion` branch; the only `class_name` hit is `Enums.class_name_of`; no RichTextLabel/LinkButton; no `MORALE_BAND_EMOJI`; no `await`. `$GODOT`: the unit added no scripts. MOTION LINT OK observed. New PNGs: none; every `Icons.at` key resolves (13 checked). Router host: nothing parented to it. Overlays `MOUSE_FILTER_IGNORE` (5 sites). Font sizes through `Type.at`; colours Palette tokens; the transparent font colour is HEAD:663's idiom. Every kit symbol exists at HEAD (40+ symbols, 16 variations); no kit file modified. `_ready()` → `build()` guarded (HEAD:105). Handoff §1 exact old/new at the JSON's 2-space indent. Same-wave function calls: none.

## P1.6. Judgement calls vs §6

None of the eight judgement calls touches a §6 question. Q01/Q02 — untouched (`figure_scale` is the JSON's). Q04 — the speech plate is SceneStage's. Q11 — the strip is Cards'. The rim = item tier (call 2) reads an existing Palette ramp. The worn group's roster order (call 3) is forced by test_market.gd:475. Call 4 reconciles TOWN-21's "one crimson CTA" with test_market.gd:478-485's press-asks contract. Call 6 (47px Buy cells) is the plan's own `slot_button`. Call 7 (indulgence stays a wide button) is sound. Nothing reserved for the designer was decided.

## P1 Issues

1. **BLOCKER — the Sell grid's rim (rarity and selection) invisible on the seven opaque reference crops** (`_sell_cell`, content margin 0 + `expand_icon = true`). Fix offered: `b.expand_icon = false` after `Widgets.slot_button(...)` — or margin 4 on the styleboxes. → fixed in the repair pass (Market.gd:696), verified in pass 2.
2. **MAJOR (escalated) — "the fountain shimmer" is not in the shot**; the handoff should state the 42px speech-plate cut at (-250,-300). → stated in the repair pass; orchestrator's ruling.
3. minor — sell-all Button trimmed with an ellipsis at text_scale 150. → fixed (autowrap), verified in pass 2.
4. minor — report named `slot_with_reason` / `button_with_reason`; only `Widgets.reasoned` is called. → fixed in the report.
5. minor — "the one crimson commit" wording vs the confirm state's zero ButtonCta. → fixed in the report.

## P1 False claims in the report

- "W2M_Market_confirm.png: the chest slot takes the gold rim" — false at the time (edge (19,27,37) navy). → struck through and labelled in the report; true of the re-shot.
- "(`Widgets.reasoned` / `slot_with_reason` / `button_with_reason`)" — only `Widgets.reasoned` is called. → fixed.

## P1 Verdict

**FAIL** — one blocker (issue 1), fixed since; see pass 2.
