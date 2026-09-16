# Handoff — W2-MARKET (key `W2-MARKET`)

Edits needed in files this unit does not own. Shape: `## N. <path>:<line>` then an `old:`
block and a `new:` block, one edit per heading. Observations (no edit) are labelled as such.

(appended as the unit goes; empty means nothing was needed so far)

## Observation (no edit) — W2-STAGE2 / orchestrator: the band the Market shows, in plate pixels

`Market.gd` composes the scene as TOWN-22 asks: the ledger is `LEDGER_RECT = Rect2(18, 14, 560, 610)`
(scene-local; the Board's inset) and the plate sits at `PLATE_OFFSET = Vector2(-420, -300)` — the plan's
number, and the one W2-STAGE2's re-placed crowd (handoff-W2-STAGE2.md, "where the market's crowd now stands")
was measured for. The two units agree; nothing to apply.

What the screen shows of the plate (1536x1024 plate pixels): the band right of the ledger is
**x 998..1348, y 300..940**; a 14px strip above the ledger (y 300..314) and a 16px strip below it
(y 924..940) at x 438..998 are scenery only; under the ledger (x 438..998, y 314..924) is hidden.
A figure planted at `pos` is whole when `pos.x - frame_w/2 >= 998`, `pos.x + frame_w/2 <= 1348`,
`pos.y - frame_h >= 300` and `pos.y <= 940`. All five right-hand shoppers of the committed JSON —
(1040,432), (1130,572), (1020,650), (1108,874), (1248,632) — are whole, and the speaker (index 5,
variant_r01_brown) stands at scene (600,350), inside the band beside the ledger.
`tests/unit/test_market_grid.gd` reads the JSON against `PLATE_OFFSET` and asserts >= 4 whole and the
speaker in the band, so a later re-placement that leaves the band fails there, by name.

ORCHESTRATOR — one plan line is NOT met and cannot be at the plan's own offset: W2-MARKET's acceptance
says the fixture shot shows "the fountain shimmer". The fountain (stage_market.json shimmer rect
[700,440,180,120]) is under the ledger at (-420,-300); TOWN-22's Fix wrote "framed on the fountain and two
stalls (offset ≈(-420,-300))" and the two halves of that sentence exclude each other on this plate. The band
shows the three right-hand stalls (green awning top-cut, white stall and red tent whole) and five shoppers
instead. If the fountain matters more than the crowd: `PLATE_OFFSET = Vector2(-250, -300)` shows 52px of
the shimmer's right edge beside the ledger with FOUR of the five shoppers whole (the one at (1248,632)
falls off the host's edge) and the white stall / red tent cut by the host's right edge — one constant, no
other edit; the market_grid tests hold at either value. THE COST THE FIRST DRAFT OMITTED (review-W2-MARKET.md
§3): at (-250,-300) the band ends at plate x 1179 and W2-STAGE2's speech plate (182 wide, centred on
speaker 4's head at plate x 1130 → x 1039..1221) is cut by 42px at the host's right edge, so the market's
line would read "That is a lot of gold for a h". No offset gives more than ~10px of shimmer together with a
whole speech plate and four whole figures (the interval is ox ∈ (-302,-292]). The real choice is therefore
fountain-with-a-cut-line versus crowd-with-a-whole-line, and the plan's own number gives the second;
a third road — moving the speaker to a shopper further right, or the shimmer rect on the plate — is
W2-STAGE2's JSON, not this unit's.

## Observation (no edit) — W3-KIT2: `Widgets.tab_row`'s active plate hugs its word
`tab_row` builds its Buttons with no minimum size, so the `NavItemActive` 9-slice (content margin 0)
draws a plate the size of the word — "Sell" sat in a 30x18 tab. Market.gd sizes each tab to 110x32 after
`tabs_of()`; if the Guildhall/Tavern adopt the row the size belongs in the kit (a `TAB_MIN` in Widgets, or
a content margin on the variation in Theme.gd).

## 1. game/assets/scenes/stage_market.json:66 (owner this wave: W2-STAGE2) — ALREADY IN THE TREE, skip

W2-STAGE2 made this same change in the working tree while this unit was shooting (the JSON reads
`"speaker": 4` as of 19:00); build/shots/W2M_Market_confirm.png shows the plate whole over the knight. The
`old:` block below no longer matches — nothing to apply. Kept for the record.

The speaking plate is centred on its speaker's head (`SceneStage._anchor_speech`: `head_of - size.x/2`,
182 wide). Speaker 5 (variant_r01_brown at plate x 1020) puts the plate at plate x 929..1111, and the
Market's ledger covers plate x < 998 at `PLATE_OFFSET (-420,-300)` — the fixture shot
(build/shots/W2M_Market.png) shows "…of gold for a" with the plate's left third under the ledger.
Speaker 4 (knight_unlabelled at (1130,572)) puts the plate at plate x 1039..1221, y 440..516 —
scene (619..801, 140..216), on the cobbles between the green awning and the white stall, whole, and
nothing else in the JSON moves. (Moving the brown shopper to x >= 1089 is the other one-number fix.)

old:
```
  "speaker": 5,
```
new:
```
  "speaker": 4,
```
