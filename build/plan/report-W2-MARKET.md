# Report — W2-MARKET (the Market becomes a shop)

Unit: 00-plan.md §3 "W2-MARKET". Owns `game/screens/Market.gd` (SPACES) and
`tests/unit/test_market_grid.gd` (new). Written as the unit goes (LESSONS: write-as-you-go).

## Acceptance (from the plan; ticked as each lands)

- [x] Sell tab is a 6-column grid of 47px `Widgets.slot_button`s with `Cards.gear_icon` and a rarity rim (visible on every crop since the repair pass — `expand_icon = false`); `Button.text` unchanged ("Sell Worn Iron Cap — 1 G") so `test_market.gd`'s fragment presses hold
- [x] Selection populates a sidebar item card: icon 2x, name, "worn by X", price, a crimson "Sell — N G" (`Widgets.cta`) as the one crimson commit on the Sell tab; a worn row's press swaps it for `Widgets.confirm_pair("Yes — take it off X and sell it", "Keep it")`, in which state there is NO crimson control (Yes is DANGER ink) — review issue 5 wording fix
- [x] Two groups: "In the window" then "Worn by the roster"; the worn group defaults OPEN when the window is empty (TOWN-28; `test_market.gd:478` unchanged)
- [x] Buy: `slot_button(caption, Icons.at("item", key))` with a corner numeral badge Label; "(N held)" kept in Button.text
- [x] Comfort keeps the mini-grid picker; furnishing rows carry `Icons.at("furnishing", key)`
- [x] Ledger panel 560px wide on the left; title + subtitle in the panel's title bar; no text on the plate; the square visible on the right with 5 whole actors and three stalls — **the fountain shimmer is NOT in the band** (judgement call 1: unreachable at the plan's own offset; one-constant alternative recorded)
- [x] `_chips()` deleted; `Frame.standard_chips(f, _state)` / `Frame.refresh_chips(_frame, _state)`
- [x] "Back to town" -> `ButtonQuiet` (a Button)
- [x] Disabled controls state their reason in an adjacent Label — every one through `Widgets.reasoned` (the `_reasoned` wrapper adds the wrap width); `slot_with_reason` / `button_with_reason` are NOT called (review issue 4 wording fix)
- [x] `tests/unit/test_market_grid.gd`: selection populates the sidebar; Day-1 opens with an empty window and the worn group open
- [x] `test_market.gd` green unchanged
- [x] Shots (viewed): `Market --fixture`, `--fixture --press=Buy`, `--fixture --press=Comfort`, `Market` (Day 1), `--fixture --set=text_scale=150`
- [x] `verify.sh --fast`: every stage of mine green — the one red is `test_town_layout.gd` (W2-TOWN's new file, mid-wave); `lint_motion.sh` MOTION LINT OK; refdiff recorded (no regression)

## Judgement calls

1. **PLATE_OFFSET = (-420, -300) — the plan's number — and the fountain is NOT in the shot.** First pass
   measured (-85,-150) against the twelve shoppers committed at the wave's start: fountain beside the ledger,
   five whole figures. Then W2-STAGE2's re-placement landed in the working tree (their handoff: eight
   shoppers, five of them at plate x 1020..1248 "for the layout the plan gives W2-MARKET ... (-420,-300)",
   speaker index 5 among them). At (-85,-150) that crowd is off the host (2 whole) and the speaker is cut;
   at (-420,-300) all five are whole and the speaker stands beside the ledger — but the fountain shimmer
   (plate x 700..880) is under the ledger, so TOWN-22's "framed on the fountain and two stalls
   (≈(-420,-300))" is self-contradicting on this plate. Both bands were rendered and compared
   (scratchpad w2m_band_plan.png / w2m_band_mid.png): the plan's band reads as a market row (three stalls,
   five shoppers, the speaking one in view); the compromise (-250,-300) shows the fountain's rim plus four
   shoppers with two stalls cut by the host's edge. Took the plan's number so the two units agree on commit;
   the one-constant alternative is written in the code comment and in handoff-W2-MARKET.md for the
   orchestrator. The "fountain shimmer" clause of my acceptance line is therefore the one thing left unmet.
2. **Item "rarity" rim = the item's tier.** Canon items carry no rarity (that is a raider field; `Item.gd`
   has `tier`); docs/09 grades gear by tier, so the rim reads `Palette.rarity_color(clamp(tier, 0, 4))` —
   starting gear (tier 0) on the common rim.
3. **The worn group keeps the roster's order; only the window sorts by price desc.** TOWN-28's "sort by price
   desc" applied to both would break `test_market.gd:475` ("worn by <roster[0]>" printed before any press):
   the default selection is the first row of the open worn group, and that must be roster[0]'s. A raider's
   kit also reads as a set in roster order.
4. **A worn item selected BY THE SCREEN (the Day-1 default) shows the crimson "Sell — N G" first; a worn
   slot PRESSED by the player asks at once.** test_market.gd:478-485 presses "Sell <chest>" once and expects
   "take it off", so the press is the ask; the default selection was not an act by the player, so the screen
   does not open on a confirm nobody asked for. One crimson control in either state (the confirm's "Yes"
   is DANGER ink, not crimson).
5. **The slot Button's text is hidden by transparent font colours + clip_text** (the mechanism the
   Comfort picker already used for its portrait tiles); the visible caption is a Label under the slot.
   `Button.text` stays the row's whole sentence for the fragment presses.
6. **Buy cells are 47px squares (6 x 78px cells fit the 528px ledger; 6 x 136px TIER_CELLs do not).** The
   count held is a corner numeral (06 §2's stack numeral, `Type.STACK` through `Type.at`) AND stays in
   `Button.text` as "(N held)" for test_market.gd:524.
7. **The indulgence stays a wide reasoned button** — it has no furnishing icon (`Icons.at` on a missing key
   is a push_error by design) and it is a token, not a thing in the quarters.
8. **The tabs are `Widgets.tab_row`**, rebuilt on every refresh so the active plate follows `_active`;
   the tab Buttons keep their texts ("Sell", "Comfort", "Buy").

## Log

- 17:47 report + handoff created. Baseline refdiff (build/shots/W1STAGE_Market.png vs 3, mask 0,77,1536,649):
  mae 36.766 · rmse 69.209 · structure 0.1895 · layout_iou 0.10 · palette 0.3094 · within_8 50.81% · DIFFERENT.
- 17:58 Market.gd rewritten (895 lines, spaces): ledger 560 left, PLATE_OFFSET (-85,-150), tab_row, sell
  grids + sidebar card + confirm_pair, buy cells with numeral, comfort cells with furnishing icons,
  standard_chips/refresh_chips, ButtonQuiet escape, reasoned everywhere. PARSE_CHECK OK (160 scripts).
- 18:02 tests/unit/test_market_grid.gd written (11 cases). Parse check now reports SceneStage.gd and
  test_board_rows.gd failing — both other units' files mid-edit (W2-STAGE2 / W2-BOARD), not mine; Market
  preloads SceneStage so the unit suite cannot run until that file parses again. Waiting/retrying.

- 18:40 Shots taken (build/shots/W2M_*.png) and VIEWED with the Read tool:
  - `W2M_Market.png` (--fixture): ledger 560 on the left (x 228..788), "Market" + subtitle in its bar, the
    kit's tab row with Sell lit, "Sell all nobody can wear — 0 G (12480 → 12480)" reasoned, "In the window · 0"
    with the shelf glyph and "Nothing found yet — raid first.", "Worn by the roster · 48" as a 6-column grid of
    47px slots with item art, names under them, the first slot (Worn Iron Cap) on a gold rim; sidebar card:
    icon at 2x, "Worn Iron Cap / Head / worn by Bork / Sells for 1 G", crimson "Sell — 1 G"; "The Stall ·
    Level 1 of 4", the reasoned rung, "Next: …", quiet "Back to town"; header chips "12,480 G" with the
    separator and the rank sigil. Band right of the ledger: green awning (top-cut), white stall, red tent,
    five whole shoppers, the "…" bubble. First pass had the speaking plate cut by the ledger (speaker 5) —
    W2-STAGE2 moved the speaker to 4 in the tree while this ran; the later shots show it whole.
  - `W2M_Market_confirm.png` (--press="Sell Damaged Chainmail — 1 G"): ~~the chest slot takes the gold rim~~
    FALSE as first written (review §3: the opaque chest crop covered the rim; fixed in the repair pass below),
    the card shows the DANGER-rimmed confirm pair, "Yes — take it off Bork and sell it" wrapped on two lines
    in DANGER ink, "Keep it" with the focus ring (the pair's safe default).
  - `W2M_Market_buy.png` / `W2M_Market_buy_held.png`: potion icons in 47px slots, "Minor" / "8 G" captions,
    "An Unknown guild's custom reaches grade Minor."; after one press the slot carries the "1" numeral
    bottom-right and the notice reads "Wrapped and put in the pack."
  - `W2M_Market_comfort.png`: the portrait picker (Bork lit), "Bork — 87 <glyph>", furnishing slots with the
    cot/bed/meal icons, the two unstocked ones dimmed with their reason under them in CAUTION.
  - `W2M_Market_day1.png` (no flag = no guild): "No guild loaded." chip, "Nothing to sell…" empty state, the
    square beside the ledger. (shot.gd has no "new game" flag; the Day-1 shape — empty window + open worn
    group — is the fixture shot above and test_market_grid's first case.)
  - `W2M_Market_text150.png`: the grid reflows to 4 columns with whole words; the sidebar fits with "Back to
    town" at y 672 (< 714) after the stall block folded its level into the title row; nothing clips.
- 18:55 Unit suite: 1801 tests, only `test_town_layout.gd` red (W2-TOWN's). test_market.gd + test_market_grid.gd
  (12 cases) green; no Market push_error in the log.
- 19:05 `verify.sh --fast` (build/shots/W2M_verify_fast.log):
    PASS  LINT OK  no cross-file class_name references in sim/ or game/
    PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
    PASS  PARSE_CHECK scanned 166 script(s)
    PASS  16 generated file(s) agree with tools/gen_items.gd
    PASS  ART CHECK  generators=6  runtime files: 184 agree  0 DIFFERS  0 MISSING
    FAIL  unit tests — test_town_layout.gd :: test_the_locked_blacksmith_is_the_same_height_dimmed_with_a_one_line_reason (W2-TOWN, not this unit)
    TESTS FAILED   1/1801 failing  [46607 ms]
  a11y_smoke (both sweeps, 26 mounts): `ok empty Market.tscn owner='Camp' tab ring=3 rail=6 focusable=10
  reachable=12 disabled=2` · `ok fixture Market.tscn owner='Camp' tab ring=4 rail=6 focusable=61 reachable=61
  disabled=3` · A11Y SMOKE PASSED. No warn on Market.
- refdiff Market vs 3 (mask 0,77,1536,649): before mae 36.766 · iou 0.10 · within_8 50.81% · DIFFERENT;
  after mae 36.73 · rmse 69.142 · structure 0.1918 · iou 0.1013 · within_8 50.9% · DIFFERENT — no regression.

## Left undone, and why

- The "fountain shimmer" clause of the acceptance shot: unreachable at the plan's own PLATE_OFFSET (judgement
  call 1); the alternative (-250,-300) is one constant away and documented in the code comment and the handoff.
- The `Market` (Day 1) shot: shot.gd has no new-game flag, so the no-flag shot is the no-guild state; the Day-1
  shape is asserted by test_market_grid.gd and visible in the fixture shot (empty window, worn group open).

## Handoff

build/plan/handoff-W2-MARKET.md: the band in plate pixels for W2-STAGE2 (nothing to apply — the crowd was
placed for the same offset), the fountain/offset switch for the orchestrator, the speaker edit (already
applied by W2-STAGE2 in the tree), and a `tab_row` sizing observation for W3-KIT2.
Repair pass: the fountain/offset paragraph now states the (-250,-300) cost the review found (speech plate
cut 42px at the host edge; no offset gives >10px of shimmer with a whole plate and four whole figures).
The fountain clause stays unmet at the plan's own constant — the review escalates it to the orchestrator
and this pass does not re-litigate it.

## Repair pass (review-W2-MARKET.md)

- [x] R1 (blocker) sell slot rim hidden under the opaque reference crops: `b.expand_icon = false` in `_sell_cell`; re-shoot `--fixture` and `--press="Sell Damaged Chainmail — 1 G"`, check the chainmail edge
  - Market.gd `_sell_cell`: `b.expand_icon = false` after `Widgets.slot_button(...)` (the reviewer's first option; every gear crop is 39x39 — PIL scan of game/assets/ui/icons/item_*.png — so 1:1 it sits 4px inside the 47px slot, inside the 2px rim, on every state; no hover jump). Buy/Comfort cells untouched (their 32px icons are transparent round the art; not in the review).
  - Pixel check (scratchpad script, tolerance 8 of the reviewer's (237,168,70)): W2M_Market.png gold rim bbox 268,435..314,481 = 47x47, 352 px = a whole 2px perimeter on Worn Iron Cap; W2M_Market_confirm.png gold rim bbox 352,435..398,481 = the Damaged Chainmail slot, 352 px, inside-rim pixel (237,168,68). The reviewer's review-W2-MARKET-confirm.png has 0 gold px below the tab underline. Viewed at 3x (scratchpad grid_W2M_Market{,_confirm}_3x.png): gold rim on the selected slot, the chainmail's opaque navy square inside it with the slot fill showing as a thin band, grey common rims on every other slot.
- [x] R2 (major, orchestrator's ruling) handoff: the (-250,-300) alternative also cuts the speech plate by 42px at the host edge — say so
  - handoff-W2-MARKET.md's fountain paragraph now carries the cost: band end 1179 vs speech plate 1039..1221 (cut 42px, the line reads "…for a h"), the (-302,-292] interval, and that the third road (speaker / shimmer on the plate) is W2-STAGE2's JSON. Code unchanged: PLATE_OFFSET stays (-420,-300), the ruling is the orchestrator's.
- [x] R3 (minor) sell-all Button wraps instead of trimming at text scale 150; re-shoot `--set=text_scale=150`
  - Market.gd `_sell_all_row`: `clip_text` + `OVERRUN_TRIM_ELLIPSIS` replaced by `autowrap_mode = AUTOWRAP_WORD_SMART` (the Board's CRITIC-G15 idiom, AdventureBoard.gd:350 — wrapping zeroes the claimed width and grows the row; no fixed height needed, unlike the card's Yes).
  - W2M_Market_text150.png (viewed, ledger top at 2x): "Sell all nobody can wear — 0 G  (12480 →" / "12480)" on two lines inside the 508px column, the reason under it, "In the window · 0" below; the ledger did not widen. At 100 (W2M_Market.png top crop) it is one line as before.
- [x] R4 (minor) report wording: only `Widgets.reasoned` is called; the confirm shot claim was false; "one crimson commit" is the Sell state only
  - Acceptance lines 2 and 9 reworded; the 18:40 confirm-shot bullet struck through and marked false (grep: `reasoned` 1 call, `slot_with_reason` 0, `button_with_reason` 0).
- [x] tests: `test_market_grid.gd` guards R1 and R3; suite + `verify.sh --fast` re-run
  - `test_a_sell_slot_keeps_its_rim_clear_of_the_icon` (every WornGrid Button: `expand_icon` false, a >= 2px StyleBoxFlat rim, icon width + 2*rim < slot; after pressing roster[0]'s chest exactly one slot carries `Palette.ACCENT_GOLD` and it is that chest) and `test_the_sell_all_button_wraps_rather_than_trimming_its_arithmetic` (autowrap WORD_SMART, OVERRUN_NO_TRIMMING, clip_text false, "(12480 → 12480)" in Button.text). 14 cases now.
  - Unit suite (scratchpad batch1.log): `TESTS FAILED 1/1805` — test_town_layout.gd (W2-TOWN) only; no Market line. `verify.sh --fast` (build/shots/W2M_verify_fast.log):
      PASS  LINT OK  no cross-file class_name references in sim/ or game/
      PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
      PASS  PARSE_CHECK scanned 166 script(s)
      PASS  16 generated file(s) agree with tools/gen_items.gd
      PASS  ART CHECK  generators=6  runtime files: 184 agree  0 DIFFERS  0 MISSING
      FAIL  unit tests — TESTS FAILED 3/1806: test_town_layout.gd x3 (W2-TOWN's file, changing under the wave; 1 → 3 between my two runs), nothing of Market's
    `tools/lint_motion.sh`: MOTION LINT OK. a11y_smoke through the lock: `ok empty Market.tscn … focusable=10 reachable=12 disabled=2` · `ok fixture Market.tscn … focusable=61 reachable=61 disabled=3` · A11Y SMOKE PASSED 26 mounts (unchanged counts).
  - refdiff W2M_Market.png vs 3 (mask 0,77,1536,649): mae 36.73 · rmse 69.142 · structure 0.1918 · iou 0.1013 · palette 0.306 · within_8 50.9 — identical to the pre-review numbers (the ledger is inside the masked band).
  - Indentation: 0 tab-led lines in both owned files. PARSE_CHECK OK before the shots.
