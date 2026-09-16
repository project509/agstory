# report-W7-PREP — the party on the prep band, one risk sentence, icons on the provisions

Wave 7 of `build/plan/ship/00-plan.md`. Contract: the "### W7-PREP" block (UI-16, LOOP-09, UI-17, LOOP-08, UI-39, LOOP-29, CRITIC-R6, UI-14's prep half, UI-18, LOOP's "Depart always available").
Owns: `game/screens/RaidPrep.gd` (SPACES), `game/core/RaidPlan.gd` (SPACES), `game/screens/RaiderDetail.gd` (TABS — Quarters buttons' `icon` only), `tests/unit/test_prep_layout.gd`, `tests/unit/test_raid_plan.gd`.
Written as I go (rule 3). Handoff: `build/plan/handoff-W7-PREP.md`.

## Acceptance

- [x] A1 `test_prep_layout.gd`: after `build()` on the fixture the stage has 12 `Actor_*` children named by raider id; `_toggle()` on one leaves 11; an empty chalkboard has 0 and the strip's empty state shows.
- [x] A2 every provision Button has a non-null `icon` and its `text` unchanged (`icon_alignment = LEFT`, `expand_icon = false`); the same icon on RaiderDetail's Quarters furnishing buttons.
- [x] A3 the rewards row has exactly `n` cells for every Tier-1 notice (`n == 0` prints "Nothing worth carrying.").
- [x] A4 the verdict callout's headline is one of Ready/Risky/Reckless/Suicidal and its figure starts with "+" or "−" (expected − baseline); the `"Verdict:"` readout Label keeps its literal prefix.
- [x] A5 the risk meter is DRAWN (a `Control._draw()` inside RaidPrep, 4px diagonal stripes in the band's tone), the word beside it as caption; `RaidPlan.risk_hatch()` kept for the log/test text.
- [x] A6 the fifth "+N" `ButtonMini` tile on the Raid Team row scrolls the strip to the first unseen card (UI-18).
- [x] A7 the rim is a focus outline only while the strip has focus; no caption.
- [x] A8 `test_raid_plan.gd` green (the delta, `risk_fill`, the strings kept).
- [x] A9 shot `RaidPrep --fixture` viewed: twelve figures on the band, a drawn hatch; `--fixture=play` viewed: icons on the provision buttons.
- [x] A10 "Depart" stays the crimson `ButtonCta`; "Bench" in-card action kept; `test_full_loop.gd` green; SPACES; `lint_motion.sh` OK; `verify.sh --fast` run and every failing line attributed — none in a file this unit owns or touched (see "verify.sh --fast" below; the tree is four other units deep in their own edits).

## Judgement calls

- **Empty seats are floor marks, not stand-in figures.** UI-16 says "greyed figures for empty slots" and the plan says "`party_state_style` greying empty seats"; the acceptance says an empty chalkboard has 0 `Actor_*` children. A grey figure of a class nobody picked would be a lie on the floor (and an `Actor_*`), so an empty mark is `Seat_<n>`: the figure's contact-shadow ellipse alone (`SceneStage.LIGHT_TEX`, the shadow's own scale rule) in `party_state_style("downed")`'s grey at `SEAT_ALPHA 0.7`, inserted under the figures. 0.34 with the "dead" grey was invisible on the dimmed plate (shot, then re-shot).
- **Taking a figure off the stage.** SceneStage has no `remove_actor`; `add_actor` appends to its private `_actors`, which `apply_settings` walks. `_clear_party` removes the sprite and its `Shadow_` sibling and erases the sprite from `stage.get("_actors")` so a later reduced-motion pass never meets a freed object (a test asserts the list stays valid and `apply_settings(true, false)` after a bench does not throw). A `SceneStage.remove_actor(spr)` is in the handoff for the file's owner; nothing here calls it.
- **The boss stays off the prep band.** `Cards.encounter_sprite` at the boss mark was optional; the mark (x 1210) lands under/behind the readout column after `arena_view`'s shift, so it would fight the look. Left out.
- **The callout's words.** Headline = the verdict word alone; figure = `RaidPlan.signed(expected − baseline) + " mistakes"` ("+14.2 mistakes"); a third LabelSmall "over a content guild" (the plan's phrase verbatim) / "under a content guild" when the delta is negative. A delta that rounds to 0.0 prints "+0.0", never "−0.0". The readout's own `Widgets.section("Verdict: %s")` Label is kept verbatim.
- **The hatch's caption is always the band word** (LOW too), because docs/13 §10.3 wants "a word AND a hatch density" and the greyscale reading needs the word; SEVERE keeps its DANGER tint, the stripes take the verdict band's tone through `Palette.band_color(band)` — the same band that colours the callout.
- **The "+N" tile** turns the strip to the page holding card index `TEAM_FACES` (page 1 of 3 for twelve) and rebuilds; five 56px tiles at a 6px gap are 304 of the 306 the G15 test allows the scrolling block.
- **Quarters icons:** furnishing rows get `Icons.at("furnishing", id)` (the Market's own); the Hot Bath Token row gets none, because the Market says "the indulgence has no slot art (it is a token)" and `Icons.at` push_errors a missing name.
- **Shots:** `--fixture` has a bare cupboard (the reference), so the provision icons are looked at on `--fixture=play` (W6-SHEETS' stocked guild); the party and the hatch on `--fixture`.

## Log

- RaidPlan: `risk_fill`, `risk_delta`, `signed`; `risk_hatch` cut from `risk_fill`; analyse gains `risk_fill` / `risk_delta` / `risk_delta_text`. Parse-check OK.
- RaidPrep: `_stage`/`_marks` held from `_scene`; `_place_party` (+ `_clear_party`, `_party_layout`, `_formation_rank`, `_place_seats`, `_first_figure_index`) on every `_refresh`; rim hidden until `_on_focus_changed` sees the focus inside the strip (viewport `gui_focus_changed`, guarded off-tree); `RiskHatch` inner class + `_hatch_row`; the callout re-worded; rewards row exactly `n` / "Nothing worth carrying."; `TeamRow` + `_more_tile`; `_provision_button` gets `icon`. RaiderDetail `_furnishing_row`: `b.icon`. Parse-check OK, no tabs in the SPACES files.
- Shot `build/shots/W7PREP_RaidPrep.png` (viewed): twelve figures on the cave floor in three ranks, the drawn red hatch + "ELEVATED", "Reckless / +14.2 mistakes / over a content guild", the "+8" tile, two reward cells. `W7PREP_RaidPrep_bench.png` (two benched, viewed) and `W7PREP_RaidPrep_empty.png` (all benched, viewed: twelve pale seat ellipses on the floor, band otherwise bare, strip empty state).
- test_prep_layout.gd: 9 new tests (party on the band / stage forgets a benched figure / rim as focus outline / provision icons / Quarters icon / rewards exactly n / callout one word one signed number / hatch drawn and captioned / +N tile) — 25/25 green. test_raid_plan.gd: 2 new tests (fill+hatch agree, delta signed) — green; its 5 Depart tests are red ONLY because `sim/core/RaidSim.gd` is mid-edit by W7-SIM-EFFECTS (`_phase_healers()` arity parse error → `RaidSim.run` nonexistent); re-run at the end.

## Resume — 2026-09-15 21:15 (the session the usage limit killed at ~16:30)

Appended, not rewritten (rule 3). What I verified against the tree before continuing, and then the two
lines that were still open.

- **Verified, not taken on trust.** `git diff` on the five owned files: `RaidPlan.gd` +38 (`risk_fill`,
  `risk_delta`, `signed`, `risk_hatch` re-expressed through `risk_fill`, the three new `analyse` keys),
  `RaidPrep.gd` +364, `RaiderDetail.gd` +5 (`b.icon = Icons.at("furnishing", id)`, `icon_alignment`,
  `expand_icon` — nothing else in the file), `test_prep_layout.gd` +341, `test_raid_plan.gd` +51. The
  functions the log claims are all present (`RiskHatch` class :168, `_place_party` :484, `_clear_party`
  :497, `_party_layout` :528, `_formation_rank` :560, `_place_seats` :577, `_first_figure_index` :618,
  `_on_focus_changed` :470, `_more_tile` :1034, `_hatch_row` :1163, `_provision_button` :828).
  Indentation re-checked per file: no leading TAB anywhere in the four SPACES files, no leading
  four-space line in `RaiderDetail.gd` (TABS). `parse_check` 190 scripts OK.
- **A9 — the shots were STALE and were re-taken.** The 16:12/16:20 PNGs predated `RaidPrep.gd`'s last
  edit (16:24), so a shot nobody could trust is not evidence either. Re-shot at 21:23 and viewed with
  the Read tool:
  - `build/shots/W7PREP_RaidPrep.png` (`--fixture`, the contract's one look): twelve figures standing
    on the cave floor inside the band, the drawn red hatch with "ELEVATED" beside it, the callout
    "Reckless / +14.2 mistakes / over a content guild", the "+8" tile fifth on the Raid Team row, two
    reward cells, "Verdict: Reckless" keeping its literal prefix, Depart crimson and reasoned
    ("12 of 12 chalked"). The formation is still crowded at the marks' 38px rank pitch — W7-STAGE's
    party spread, noted in the handoff.
  - `build/shots/W7PREP_RaidPrep_play.png` (`--fixture=play`, the stocked cupboard): all five provision
    buttons carry their Market icon in the leading slot with the text verbatim ("Minor Healing Potion
    0/2", "Potion of Steady Hands 0/2", "Whetstone Kit 0/2", "Mana Draught 0/2", "Guild Feast 0/2"); six
    figures on the band, the LOW hatch empty in the band's tone, and the negative case of the callout
    reading "Ready / −1.1 mistakes / under a content guild" in the ready green — the real minus sign.
- **A10 — the tests.** `RUN_TESTS_ONLY=prep_layout,raid_plan,full_loop` → **TESTS PASSED 67 test(s) in
  3 file(s) [28493 ms]**. `test_raid_plan.gd`'s five Depart tests, red at 16:16 only because
  `sim/core/RaidSim.gd` was mid-edit by W7-SIM-EFFECTS, are green now that its file parses. The
  `ensure_control_visible` ERROR lines in that run come from `AdventureBoard.gd:945/979` and
  `RaidView.gd:1899` (not this unit's files, not new).
- `tools/lint_motion.sh` → MOTION LINT OK.
- `verify.sh --fast` — the summary is pasted below.

### verify.sh --fast

`GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast`, 21:26-21:38, log kept at
`build/plan/.w7prep_verify.log` (the run's own `.verify.log` has the per-test lines):

```
== 0/5  rebuilding global class cache ==   PASS  class cache regenerated
== 0/8  lint: no cross-file class_name refs ==
  PASS  LINT OK  no cross-file class_name references in sim/ or game/
  PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
== 1/8  script parse ==
  PASS  PARSE_CHECK scanned 190 script(s)
  PASS  COPY LINT OK  no player-facing string under game/ admits an unfinished feature
== 2/8  generated content matches its generator ==  PASS  16 generated file(s) agree
== 2b/8  generated art matches its generator ==     PASS  204 agree  0 DIFFERS  0 MISSING
== 3/8  unit tests ==                               FAIL  TESTS FAILED 44/2241 failing [317843 ms]
== 4/8 .. 8/8 ==                                    SKIP  --fast
VERIFY FAILED
```

The 44 are a snapshot of a working tree four other units are mid-file in, and NONE is in a file this
unit owns. By file, with the wave-7 owner from the plan's ownership table:

- `test_golden.gd` 306 assertions, `test_legendaries.gd` 2 — **W7-SIM-EFFECTS**, mid-regeneration of the
  goldens (its own contract regenerates all four).
- `test_results_layout.gd` 54, `test_results_report.gd` 32, `test_results_screen.gd` 2,
  `test_wipe_sequence.gd` 2, `test_tutorials.gd` 3, `test_screens.gd` 4, `test_text_scale*.gd` 3 —
  **W7-REPORT**, whose `Results.gd` was mid-edit: the run caught it between two edits and the parse
  errors say so (`Identifier "LOOT_ACT_W" not declared`, `Too many arguments for "_wrapped_reason()"` —
  both constants are present in the file now, at `Results.gd:154-155`).
- `test_full_loop.gd` 23 — the same Results.gd parse failure; the loop cannot reach the report screen.
  With `Results.gd` parseable at 21:28 this file is green (67/67 in the isolated run above).
- `test_raid_plan.gd` 5 — MINE by ownership, but every one of them is a pre-existing Results test
  (`test_results_reports_the_attempt` ×4, `test_results_without_an_attempt_is_an_empty_state_not_a_crash`)
  that mounts `Results.tscn` through the router. Not one of the seven risk/delta/Depart tests this unit
  wrote or touched failed. Re-run on its own with a parseable tree: green.
- `test_scene_stage.gd` 1 — **W7-STAGE** (its marks/boss-scale pass).
- `test_docs_links.gd` 1 — **W7-DOCS** (a register citation it is still writing).

## Audit closures

- **`m4t-04` — re-read at the resume, and the row can now close WHOLE except its one test clause.** The
  row's remaining_work (dated 2026-09-11) names five clauses. (1) `Cards.consumable_icon(sku_id)` was
  superseded before this wave: `Icons.at("item", sku_id)` is the door the plan's UI-39 names and the one
  all three screens use — the row's clause 1 is obsolete, not open. (2) Market: `Market.gd:852`
  `var icon := Icons.at("item", sku_id)` — done before this wave. (3) RaidPrep: `RaidPrep.gd:839`
  `b.icon = Icons.at("item", sku_id)` — this unit, with the text verbatim. (4) Results' rally-flask row:
  `Results.gd:1402` `b.icon = Icons.at("item", "rally_flask")` — landed by **W7-REPORT** in this same
  wave (read at 21:5x; not this unit's edit). (5) `tests/unit/test_market.gd` still asserts no texture at
  all; that file is in no wave-7 unit's ownership table, so it is the ONE clause left. When it is
  written, note that the icons are `Button.icon`, not child TextureRects, so the row's "six TextureRects"
  wording should become "six non-null `Button.icon`s" — and that only three of the six SKUs have drawn
  art, so `item_unknown.png` is load-bearing for `whetstone_kit`, `mana_draught` and `guild_feast`
  (all six do come back non-null: the five on the chalkboard are visible in
  `build/shots/W7PREP_RaidPrep_play.png`).
- **`m4t-04`** — the prep half is done: `RaidPrep._provision_button` sets `b.icon = Icons.at("item", sku_id)`, `icon_alignment = LEFT`, `expand_icon = false`, text verbatim ("<name>  chosen/held"); held by `test_prep_layout.gd::test_every_provision_button_carries_its_icon_and_keeps_its_text` (five raid-day buttons, each icon the Market shelf's, the press still chalks and spends nothing). The Market half was already done (`Market.gd:852`). RaiderDetail's Quarters furnishing buttons carry `Icons.at("furnishing", id)` too (LOOP-29; `test_the_quarters_furnishing_buttons_carry_the_market_icon`). LEFT for the row to close: the Results rally-flask row — W7-REPORT's line per the plan (`00-plan.md` §8.1 row `m4t-04`). The orchestrator closes the row after W7-REPORT lands; until then its remaining_work should read "the Results rally row only".
- **UI-16 / LOOP-09** (STAGE-01's prep half, M4B-ACT-05's "partial" note): the party stands on the band — `test_the_chalked_party_stands_on_the_band_and_benching_takes_a_figure_off`, `test_the_stage_forgets_a_benched_figure`, `test_the_rim_is_a_focus_outline_for_the_strip`.
- **UI-17** (KIT-12's hatch note): drawn — `test_the_risk_meter_is_drawn_and_captioned_not_typed`; `test_raid_plan.gd::test_the_fill_is_zero_at_baseline_and_one_at_severe_and_the_hatch_reads_it`.
- **LOOP-08**: one word, one signed number — `test_the_verdict_callout_is_one_word_and_one_signed_number`; `test_raid_plan.gd::test_the_delta_is_expected_less_baseline_and_always_signed`.
- **UI-14 (prep half, TOWN-11)**: `test_the_rewards_row_shows_exactly_the_drops_there_are` walks every Tier-1 notice.
- **UI-18 (COMBAT-19's prep note)**: `test_the_raid_team_row_says_how_many_more_and_turns_the_strip`.

## Left

- The Results rally-flask row's icon (m4t-04's last SCREEN site) — W7-REPORT owns `Results.gd` and has
  now landed it (`Results.gd:1402`), so what is left of the row is only `tests/unit/test_market.gd`'s
  texture assertion, which no wave-7 unit owns.
- `SceneStage.remove_actor()` — proposed in the handoff (§1) for the file's owner; RaidPrep keeps its own `_clear_party` (with the `get("_actors")` scrub) this wave under same-wave isolation.
- The boss on the prep band — optional in the contract; left out because the boss mark sits under the readout column after the band shift (judgement call above).
- 150% on RaidPrep with a STOCKED cupboard: five icon buttons wrap to one per row and the panel clips the loadout line (pre-existing at 150% with stock, unrelated to the icon; the bare-cupboard 150% test still passes) — W8-SCALE-1's "150% on Results and RaidPrep".
- The formation is crowded at the marks' 38px rank pitch and 2x figures (the twelve overlap into one mass) — that is the cave's `marks`, W7-STAGE's "party spread" this wave; RaidPrep reads the marks live, so it follows.
- `verify.sh --fast` is NOT green on this tree, and none of it is this unit's: the wave's other units are
  mid-file beside me (§ "verify.sh --fast" above names each failing file and its owner). The unit's own
  gate — `test_prep_layout.gd`, `test_raid_plan.gd`, `test_full_loop.gd` — is green in isolation, and
  `lint_motion.sh`, the copy lint, the parse check and the two generator checks are green in the verify
  run itself. Nothing in this unit's files needs another pass; the orchestrator's close-of-wave run is
  where the shared gate goes green.
