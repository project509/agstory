# Report — W2-TOWN (the hub's callouts, sidebar and hotspots)

Started 2026-09-14. Owns `game/screens/Town.gd` and `tests/unit/test_town_layout.gd` (new).
Contract: build/plan/artaudit/00-plan.md §W2-TOWN; RULES.md §1 Town rows; findings TOWN-01/02/05/06/07/16/23/31,
KIT-03/08, CRITIC-C14/G15. Written as it goes (rule 3).

## Acceptance (ticked as each lands)

- [x] A1. Five callouts each carry an icon (`Icons.at("building", id)`), a tail whose apex sits on the building
      (`BUILDINGS` gains `anchor`; the plate derives from it), no plate crosses x=1141 — Town --fixture shot.
- [x] A2. Blacksmith plate: same height as the others, dimmed, ONE-line reason; the sentence containing "maybe"
      stays a Label verbatim; the padlock (`Icons.at("lock","16")`) is its glyph.
- [x] A3. `test_town_layout.gd` (new): no callout rect intersects any stage_camp actor body box at CAMP_OFFSET.
- [x] A4. Sidebar = next-mission panel (encounter art + name + facts of the pinned/first-uncleared rung),
      `_town_unlock_line()` verbatim, a compact "Today" block, ONE crimson control (`HUB_CTA := "board"` →
      "Open the board"), "Level N of 3 — reputation raises this, not gold." kept; sidebar ends at x 1519
      (the unwrapped "Next at Known…" Label capped/autowrapped).
- [x] A5. "Back to menu" → `ButtonQuiet` (still a Button); dead `_chips()` / `_standing_tip()` and the inert
      `tagline` opt deleted; `Cards.event_log(..., hint "Raids and rests write here.")`; the strip pages itself.
- [x] A6. Shots viewed: `Town --fixture`, `Town --fixture --focus` (ring on Nav_home), `Town --fixture
      --set=text_scale=150` (no clipped Label I own), `Town` (no fixture — Day 1 sidebar).
- [x] A7. test_screens.gd Town assertions green; `verify.sh --fast` green; `lint_motion.sh` OK; refdiff Town vs 3
      (mask 0,77,1536,649) recorded before/after; callout region (386,115,224,57) vs Concept 3 recorded.

## Judgement calls (recorded as the plan asks)

(appended as they are made)

## Log

(appended as work lands)

- 17:58 Town.gd rewritten (tabs kept): `BUILDINGS` gains `anchor` (screen px, the tail apex) and an optional
  `band` (screen px, the part of the scene the plate may occupy); `at` is gone. Icons through
  `Icons.at("building", id)`; the locked plate gets `Icons.at("lock", "16")` and hides its Subtitle so it is
  two rows like its neighbours; the reason is the one sentence "Canon lists this one as a maybe." The
  inert `tagline` opt, `_chips()` and `_standing_tip()` are deleted. Sidebar rebuilt as the next-mission
  panel (`_next_mission` / `_mission_card` / `_hub_cta` / `_today_lines`), `HUB_CTA := "board"`, "Back to
  menu" is `ButtonQuiet`. `Cards.event_log(host, _state, 7, "Raids and rests write here.")`.
  tests/unit/test_town_layout.gd written (5 tests). Both parse (`parse_check`: the two failures are
  SceneStage.gd and test_raid_overlays.gd — other units' files mid-edit).

### Judgement calls made so far
- J1. Anchors are the buildings' FEET as the plan says, but every plate sits ABOVE its anchor (the kit's
  tail points down) and four of the five buildings have a figure standing in their doorway at 2x, so a
  plate straight above a foot would cover that figure. `BUILDINGS[].band` (screen px) slides the plate
  sideways/up off the figure and the kit's tail slants to keep pointing at the anchor — a plate beside the
  building with its tail on the building's foot, which is Concept 3's own composition (plates on the open
  ground beside the tents). Measured against the 2x boxes in handoff-W1-STAGE with ≥ 8px air (the test's
  AIR); the aim was 12px.
- J2. The locked plate's "same height as the others" (TOWN-02) is done by hiding the kit's Subtitle Label
  on the Town's side (the verb "Improve gear" is asserted by nothing; the reason takes its row). The kit
  keeps three rows for a locked callout — a W3-KIT2 candidate, recorded in the handoff as an observation.
- J3. [WITHDRAWN in the repair pass — Q13's copy is restored verbatim] "Disabled in this build." is dropped from the flag-off reason (test_screens :353 asserts it absent
  only when the flag is ON; the flag-off tests assert "maybe" only). The sentence with "maybe" is verbatim.
- J4. Sidebar text width is 310 (378 − 2×(14 rim + 18 pad) = 314): the W1-FRAME 1533px overflow was the
  330px caps every hub sidebar uses, not only the unwrapped promise line.
- J5. KIT-08's `Icons.at("empty", "quill")` cannot be passed: `Cards.event_log(host, state, rows, hint)` has
  no glyph parameter (Cards.gd has no owner this wave). Handoff §1/§2 add the parameter and the Town call.

- 18:50 Unit suite green: `TESTS PASSED   1806 test(s) in 86 file(s)  [38837 ms]` — the five new
  test_town_layout cases and every test_screens Town assertion. Two engine facts found on the way (probe
  scratchpad/probe_town.gd, kept out of the tree):
  (a) under tests/run_tests.gd nothing is `is_inside_tree()` (the runner works inside `_initialize`, before
      the root has a tree), so a Control's minimum-size cache, filled by the kit during construction under
      the DEFAULT theme, is never invalidated: `get_combined_minimum_size()` answers 150x58 for a plate the
      game settles at 166x84. The test walks the plate's stock containers (`_fresh_min`) over the leaves'
      uncached `get_minimum_size()` after a THEME_CHANGED propagate, and checks the subtitle's line against
      the theme's LabelSmall metrics so a default-theme walk cannot pass.
  (b) in the game the locked plate settled 17px taller than its minimum (101 vs 84): the reason row measures
      taller under the default theme than under ours on the first pass, and a Control never shrinks back.
      Town._settle_callouts (one deferred pass after the theme lands) sets each plate back to its minimum;
      the Reason Label is also unwrapped (one line, TOWN-02) so a first pass at width 0 cannot stack words.
- Anchors landed (screen px, 100%): Guildhall plate 358..524 x 166..250 (tail apex 405,258 — the big
  tent's right foot, ranger 13px left); Tavern 769..916 x 150..234 (apex 866,242 — the mess tent's left-foot
  crates; knight 12px right); Market 977..1127 x 312..396 (apex 1052,404 — the beds' top corner); Blacksmith
  624..900 x 395..479 (apex 893,498 — the stone forge's left foot; brown variant's head 12px below; the
  plate ends at the forge's edge so the forge is seen); Board 561..803 x 570..654 (apex 601,662 — the
  bridge's right railing post; rogue_b 12px left). No plate crosses x=1141 (max right edge 1127).
- [x] A3 — test_town_layout.gd: no callout rect intersects (or comes within 8px of) any of the 12 figure
  boxes at CAMP_OFFSET; every tail apex == its anchor; every plate inside the scene band; icons present;
  Blacksmith disabled + dimmed + one-line "Canon lists this one as a maybe." + same height as the Guildhall
  plate; sidebar: NextMission card with Art, exactly one ButtonCta ("Open the board", enabled with
  content), "Next at Known", "Level 1 of 3 — reputation raises this, not gold.", "Today", Back to menu is
  ButtonQuiet, the sidebar's walked minimum fits 378 wide and the panel's height; contentless guild prints
  "Nothing pinned yet" and keeps both Buttons.

- 19:20 Shots (build/shots/, all viewed with the Read tool):
  - `W2-TOWN-Town.png` (`Town --fixture`): five plates, each with its grid icon (banner, tankard, scales,
    padlock, notice board), the chamfered two-line rim and a tail; tails land on the crates at the big tent's
    foot, the crate stack at the mess tent's foot, the beds' top fence, the forge's left foot (a 7px-right,
    19px-down slant) and the bridge's right post. The Blacksmith plate is two rows like the others (84px),
    dimmed, "Canon lists this one as a maybe." in CAUTION on its second row. Rightmost plate edge x=1127.
    Sidebar: guild name, the mission card (art well with a "Next mission" tag, "Adventure 0", "Trash · 1
    enemies · about 6 rounds"), the one crimson "Open the board", the gold promise line, "Today: 12 raiders ·
    morale 46 · slightly annoyed", "Nothing on the log yet.", "Board: Level 1 of 3 — reputation raises this,
    not gold.", a rule, the quiet "Back to menu"; the panel's right rim at x≈1515. The strip pages (◄ ►,
    "1/3"); the empty log shows "Nothing has happened yet." + "Raids and rests write here." (no glyph — the
    Cards.gd handoff). `W2-TOWN-Town-callouts2x.png` is the five plates at 2x.
  - `W2-TOWN-Town-focus.png` (`--fixture --focus`): the 2px steel ring on `Nav_home` ("Camp") — crop in
    `W2-TOWN-Town-focus-day1-crops.png` (left).
  - `W2-TOWN-Town-t150.png` (`--fixture --set=text_scale=150`): no clipped Label in the sidebar — "Back to
    menu" at y≈646 inside the 726 panel; the guild name whole (the caption moved onto the art so the name
    keeps its row); the card's facts trim to one line with an ellipsis by design (the same facts are on the
    Board) [superseded by R2 below: two rows, no ellipsis]. Plates grow to 104 tall / up to 367 wide and stay inside the band; the Tavern plate's left edge
    comes within 3px of the rogue at this scale (no overlap; the layout test pins 8px air at 100).
  - `W2-TOWN-Town-day1.png` (no fixture — no guild): "A Guild Story" heading, "Nothing pinned yet / The guild
    has no content loaded to pin.", "Open the board" enabled, "Today: no raiders yet — the Tavern is up the
    road." — crop in `W2-TOWN-Town-focus-day1-crops.png` (right); the three sidebars side by side in
    `W2-TOWN-Town-sidebars.png`.
- Refdiff Town vs 3, mask 0,77,1536,649 (chrome only): BEFORE (build/shots/review-W1-KIT-fix-Town.png)
  mae 35.857 · rmse 67.431 · structure 0.2055 · layout_iou 0.1106 · within-8 50.72% · DIFFERENT;
  AFTER (W2-TOWN-Town.png) mae 35.934 · rmse 67.487 · structure 0.2067 · layout_iou 0.1110 · within-8
  50.60% · DIFFERENT — within noise (the sidebar is the only chrome that changed), no regression.
- Callout region vs Concept 3 (386,115,224,57 is the reference's Tavern plate; ours sits elsewhere because
  the buildings do, so the Tavern plate was pasted at the reference's origin and the region scored —
  build/diff/W2-TOWN/plate_{before,after}.png): BEFORE mae 43.73 · structure 0.2168 · layout_iou 0.1514 ·
  within-8 23.94%; AFTER mae 43.05 · structure 0.2474 · layout_iou 0.1787 · within-8 17.67%. Structure,
  IoU and MAE improve (the icon); within-8 drops (the glyph's light pixels differ from the reference's).
  `W2-TOWN-plate-vs-ref.png` shows the three plates: the reference's fill is 52-57 tall, ours 84 — the
  kit's title is a full Button with the theme's button margins (handoff observation for W3-KIT2).
- Gates: `tools/verify.sh --fast` → `VERIFY OK` (LINT OK · MOTION LINT OK · PARSE_CHECK scanned 166
  script(s) · 16 generated file(s) agree · ART CHECK 184 agree 0 DIFFERS 0 MISSING · TESTS PASSED 1806
  test(s) in 86 file(s) [38209 ms]); `tools/lint_motion.sh` → MOTION LINT OK; `a11y_smoke.gd` → A11Y SMOKE
  PASSED 26 screen mount(s), Town `ok` on both sweeps (empty: focusable 12 reachable 12; fixture: 14/14; no
  warn).

## Left undone / for others
- KIT-08's `Icons.at("empty", "quill")` on the Town's empty log: `Cards.event_log` takes no glyph — handoff
  §1-§3 (Cards.gd + the Town call). Nothing else of the unit is open.
- Not mine, observed: the locked/enabled plate is 84px tall against the reference's 52-57 (W3-KIT2, in
  the handoff); at text_scale 150 the Tavern plate sits 3px from the rogue's box (the anchors were placed for
  100; a 150 pass would move the anchor 4px right or the knight).

## Repair pass (review-W2-TOWN.md, 2026-09-14)

- [x] R1 (blocker F10). `_unlock_reason()` returns Q13's string verbatim again:
      "Canon lists this one as a maybe. Disabled in this build." (Town.gd); the Reason Label stays
      AUTOWRAP_OFF so it is still one line (TOWN-02). test_town_layout.gd asserts `contains("maybe")` +
      AUTOWRAP_OFF instead of the exact text, and the "build note is gone" assertion is deleted.
      J3 above is WITHDRAWN — the copy was the designer's to change, not the unit's.
- [x] R2 (minor F4a). The card's facts line reflows to a second row at 150 instead of trimming.
- [x] R3 (minor F4b). At 150 the "Next mission" caption no longer hides the encounter thumbnail.
- [x] R4 (minor F9). handoff §3's line number corrected (Town.gd:525, re-checked after the edits).
- [x] R5. test_town_layout green, `verify.sh --fast` green, `lint_motion.sh` OK; shots re-taken and
      viewed: `--fixture`, `--fixture --set=text_scale=150` (the two the fixes touch).

- Town.gd:554 restored (patch applied, string byte-identical to HEAD's); test :346/:353 relaxed/removed.
- R2/R3 landed in Town.gd: `facts.max_lines_visible = 2` at every scale (was 1 at 150); the caption
  tag is `LabelSmall` (was `LabelLabel`) so at 150 it ends ~x 139 of the 314 well, left of the centred
  thumbnail; `facts.name = "Facts"` and the sidebar test asserts the reflow + the tag's variation.
  Probe after R2 alone (scratchpad probe_town.gd, 150): the card's text box 81 -> 113 (+32, the second
  facts row), "Back to menu" bottom 697 vs the column's 694 — 3px over the content box (inside the pad,
  but not a fit). Paid for by the 150 gap 6 -> 5 (9 gaps) and the card's bottom margin 8 -> 6 at 150.
- R4: handoff §3 says Town.gd:532 (the call moved with the edits above; `old:` block re-checked
  byte-for-byte against the tree: a tab then `Cards.event_log(host, _state, 7, "Raids and rests write here.")`).
- Repair shots (build/shots/, viewed with the Read tool):
  - `W2-TOWN-Town.png` (`Town --fixture`, retaken): the Blacksmith plate is now 397 wide (503..900 x
    395..479, probe) with "Canon lists this one as a maybe. Disabled in this build." on ONE line in
    CAUTION, the padlock and title dimmed, the same 84px as the other four plates (crop
    `W2-TOWN-plate-smith-q13.png` at 2x); its tail still lands on the forge's foot. Checked against
    the twelve figure boxes at 100 (python, the test's formula): no hit, none within 8px — the same
    result the reviewer measured. Its left edge now meets the right edge of the "I think I'm ready…"
    speech bubble (W2-STAGE2's, transient) with no air — see the observation below. Sidebar unchanged
    at 100 except the caption tag, now the small type (13px) at the well's top-left; the thumbnail is
    where it was. Probe at 100: 456 of 586, unchanged.
  - `W2-TOWN-Town-t150.png` (`--fixture --set=text_scale=150`, retaken): the facts read "Trash · 1
    enemies · about / 6 rounds" on two rows, no ellipsis; the tag ends at well-x ~130 and the thumbnail
    (well-x 152..161, y 7..39 of 48, measured from the PNG) stands whole to its right
    (`W2-TOWN-Town-t150-card3x.png`); "Back to menu" 648..686 inside the column's 694 (probe: 578 of
    586). The Blacksmith plate at 150 is 570 wide (330..900): no figure box hit (warrior_0 within 8px,
    as the Tavern plate already was with rogue_3 at 150 — 150 was never the anchoring scale, noted
    in "Left undone"); it does cover the "I think I'm ready…" bubble at this scale.
  - `W2-TOWN-Town-sidebars.png` rebuilt: the 100 and 150 sidebars side by side at 2x.
- Gates after the repair: `tools/verify.sh --fast` → VERIFY OK (LINT OK · MOTION LINT OK ·
  PARSE_CHECK scanned 166 script(s) · 16 generated file(s) agree · ART CHECK 184 agree 0 DIFFERS 0
  MISSING · `TESTS PASSED   1806 test(s) in 86 file(s)  [39877 ms]`); `tools/lint_motion.sh` →
  MOTION LINT OK. Refdiff Town vs 3 (mask 0,77,1536,649) on the retaken shot: mae 35.934 · structure
  0.2067 · layout_iou 0.1110 · within-8 50.60 — identical to the pre-repair AFTER numbers (the
  caption tag is the only chrome pixel that moved), no regression.

### Judgement calls in the repair
- J6. The caption stays ON the art at every scale rather than becoming a row at 150: the probe shows
  a caption row costs 28px at 150 and the second facts row 32px against 29px of slack — a row for
  both would have pushed "Back to menu" off the column by ~30px, and the art well is the only other
  thing that gives. The fix for F4b is the tag's type (LabelSmall, 13/19.5px): `encounter_art`
  centres the thumbnail, so a tag that ends in the well's left 45% cannot sit on it. Viewed at 150:
  the tag is still ~34 of the well's 48px tall on the left — the picture is a strip with a tag on it —
  but the thumbnail reads whole, which is what F4b asked for.
- J7. The 150 budget: the second facts row (+32) overran the column by 3px on the probe; paid with the
  150 gap 6 -> 5 (nine gaps, 9px) and the card's bottom margin 8 -> 6 at 150 — 8px slack, the art
  well kept at 48. 100 is untouched (gap 8, margin 8).
- J8. `facts.name = "Facts"` (a name, no text change) so the test can pin the reflow; the tag panel
  was already "Caption".

### Observation (not this unit's, for the designer / Q13)
The verbatim two-sentence string makes the locked plate 397px wide at 100 and 570 at 150 (the one-
sentence version was 276 / ~400). At 100 it abuts the transient speech bubble above the lantern-tent
figure; at 150 it covers that bubble. Q13's answer decides the plate's width; whichever string the
designer keeps, the anchor (893,498) and band (210,77,690,410) stay as they are and the kit clamps.
