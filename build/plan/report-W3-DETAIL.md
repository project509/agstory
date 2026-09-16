# report-W3-DETAIL — one raider, one kit, one character

Unit: W3-DETAIL (00-plan.md §4). Owns `game/screens/RaiderDetail.gd`, `game/ui/PaperDoll.gd` (new),
`tests/unit/test_paper_doll.gd` (new). Started 2026-09-14.
Findings: HALL-07, HALL-08, HALL-09 (detail half), HALL-23, HALL-26, CRITIC-G05, CRITIC-G06, KIT-12,
RULES-12, KIT-22 (the tooltip text; the `tooltip_for` switch is a handoff).
Handoff: `build/plan/handoff-W3-DETAIL.md`.
(This file was first written at 21:53 and vanished at 22:17 with every other untracked wave-3 plan file —
see the handoff's last observation; re-created from context at 22:30.)

## Acceptance (00-plan.md "### W3-DETAIL")

- [x] RaiderDetail shot shows Concept 2's slot grid beside a 2x portrait (HALL-07: `PaperDoll.gd`; portrait 2x nearest in a PortraitFrame well, main-hand as the 62x74 SlotWeapon, a 3x2 grid of 47px `slot_button`s with `text` = slot name and the gear icon; a hidden off-hand shows five + a blank)
- [x] a legend of LabelSmall rows under the grid so "worth", "empty", "(+" survive; "Equip <name> (+N)" Buttons attach to the legend
- [x] no bare "0 <stat>" on the fixture shot (HALL-08: "120 HP" = base + gear via `Raider.max_hp`, "+7 AC" / "+0 Power" / "+0 Mana" as gear bonuses, "no weapon" under Damage)
- [x] "On record" + `Widgets.sparkline` under the raider card in the sidebar; the sidebar shows <= 120px of empty run (HALL-09) — 121px on the first shot; after the gap 10→12 and the two record facts the final fixture shot measures 105px (rows 543..647, PIL scan of x 1176..1486 for any pixel > 60 from the panel's median)
- [x] the empty record is a `Widgets.empty_state` block with both asserted sentences verbatim (HALL-23) — text + hint (judgement call 3)
- [x] the formula and its result on one line at 100% (HALL-26: one LabelSmall, single-spaced; "50 base -5 Common +0 Guildhall +0 furnishings = 45 baseline" measured 358px of 375 with the real FiraSans at 13px; "Uncommon" is 374 — noted below)
- [x] `_dismiss_block` is `Widgets.confirm_pair` ("Yes — let them go (+cost)" / "Keep them" kept; "Keep them" the default focus) (CRITIC-G05)
- [x] the disabled Cheer up goes through `Widgets.reasoned` with the padlock `Icons.at("lock", "16")` (CRITIC-G06)
- [x] pager via `Cards.roster_strip` paging only (KIT-12) — no private classes left in RaiderDetail.gd (RULES-12; W1-KIT's §1-§2/§8-§9 were already applied)
- [x] two-line title+body tooltips on the slots (KIT-22) — composed locally (`_tip`); the `Widgets.tooltip_for` switch is handoff §1
- [x] every slot a FOCUS_ALL Button (Button default; asserted); reasons adjacent (`reasoned`'s "Reason" Label); tabs in both game files, spaces in the test (checked: 0 space-indented lines in the two .gd files)
- [x] `test_paper_doll.gd` asserts seven slot Buttons (or six + blank) with their slot names (13 tests)
- [x] `test_raider_detail.gd` green unchanged (29 tests, run with test_paper_doll through a one-file runner kept OUTSIDE the repo: 42 passed at 22:12)
- [x] shots viewed: `RaiderDetail --fixture`, `--fixture --focus --tab=4` (+ `--tab=1`), `--fixture --set=text_scale=150`, `RaiderDetail` (empty), plus `--fixture --press=Dismiss` — two rounds, all viewed and described below
- [x] refdiff RaiderDetail vs 3 masked (`0,77,1536,649`): before mae 37.817 / structure 0.1855 / layout_iou 0.0992 / within-8 47.84% → after mae 37.968 / structure 0.185 / layout_iou 0.0995 / within-8 47.65% (verdict DIFFERENT both; flat within noise — the unmasked strip also carries W3-KIT2's new card glyphs in the after shot)
- [x] `verify.sh --fast`: lint / MOTION LINT OK / parse (173 scripts) / generated content / ART CHECK 0 DIFFERS 0 MISSING all PASS; unit tests 8/1908 failing, none in this unit's files (test_menu_lockup ×1 → W3-MENU, test_options_layout ×1 → W3-OPTIONS, test_roster_layout ×2 + test_text_scale's Guildhall.gd door ×1 → W3-ROSTER, test_scene_stage ×1 → W3-ENEMIES, test_widgets_kit ×2 → W3-KIT2 — all mid-edit in this wave); `test_paper_doll.gd` (13) + `test_raider_detail.gd` (29) pass inside the suite and alone; `a11y_smoke.gd` A11Y SMOKE PASSED, 26 mounts, RaiderDetail ok on both sweeps (fixture: focusable 31, reachable 31, disabled 2, no warn); `tools/lint_motion.sh` → MOTION LINT OK

## Judgement calls (recorded as made)

1. **Slot captions are hidden behind the icons** (the Market's picker-tile idiom, `Market._portrait_tile`):
   every slot Button's `.text` IS the slot name (walker-readable, `test_paper_doll.gd` reads it) but its font
   colour is transparent when the slot carries an icon — and every slot does (the worn item's picture, or the
   slot's own glyph dimmed to 0.35 for an empty one). A visible caption does not fit: "Off Hand" at Type.STACK
   (11px) measures 45px against a 47px cell's 43px interior, and a 32/39px icon plus a caption line would
   force the icon down to ~28px and resample it. Concept 2's slots are icon-only; the legend under the doll
   prints every slot's name in a LabelSmall, and the tooltip repeats it (title line). Empty-slot glyphs lift
   to 0.7 on hover/focus so a keyboard user sees the focused slot answer.
2. **Where the record went (HALL-09/HALL-23).** The plan's literal line — the whole "On record" under the
   raider card, "Quarters keeps the right panel" — leaves the right panel 350px empty, which is the defect
   HALL-09 exists to close. Split instead: the sidebar gets "On record" (counters, joined-at rank, the trend
   sentence + `Widgets.sparkline` + turning points; `test_raider_detail`'s "falling"/"a wipe"/"over 4 days"/
   "climbing" all read from there), the right panel gets Quarters over a "Backstory" block whose empty state
   is ONE `Widgets.empty_state` (quill glyph) filling the panel's remaining height. Every asserted string
   stays in a Label; HALL-09's own wording allows it ("keep the asserted strings … wherever they land").
3. **The empty state's second sentence is its hint line.** `Widgets.empty_state` places the glyph and the
   hint around a ONE-line text; both sentences in the text wrap to two lines at 375px and the hint overlapped
   line two (seen in the first shot). So the text is "Nothing is written down about them yet." and the hint
   (a Label named "Hint", KIT-08) is "Wants nothing in particular. Backstories arrive with the Tavern;
   wishlists with the loot module." — one block, both sentences verbatim, both Labels. Noted for W3-KIT2 in
   the handoff (a hint offset that measures the wrapped text would let a two-line text carry a hint).
4. **HP is base + gear; the rest are signed gear bonuses.** `Raider.max_hp(db)` exists, so "120 HP" is the
   real number; AC/Power/Mana print "+7 AC"/"+0 Power" (test_raider_detail's `"%d AC" % stats.ac` still
   matches inside "+7 AC"); an empty main hand prints "no weapon" in the Damage cell. The strip is an
   HFlowContainer so at 150% the five cells take two rows rather than clipping ("no we…" in the first 150%
   shot).
5. **Two facts added to the record and one to the kit** so the sidebar's empty run is under 120px with real
   content, not padding: "Joined while the guild was <rank>." (`recruited_at_rank`; "Benched for the last N
   runs." / "Went on the last run." from `consecutive_benched`/`runs_attended`, docs/04 §12.2) and, under the
   legend, "4 of 7 slots filled · the whole kit would fetch 4 G at the Market" (`Economy.sell_price`, the
   legend's own number). The sidebar column's gap is 12 (was 10).
6. **The legend and the record scroll past their panels at 150%** (`_scrolled`: a ScrollContainer that takes
   the height left, W1-CHROME's visible 8px bar, `follow_focus`). At 100% nothing scrolls and no bar shows;
   at 150% the first shot lost "Back to the roster" under the sidebar's rim and the kit summary under the
   left panel's — a footer button vanishing is worse than a list that says it scrolls (LESSONS: a scroll is
   a real fix only where the bar can be seen; here it is inside the panel's text width).
7. **`--tab=4` lands back on `Nav_home`.** The frame Tabs by REGION (rail → scene → sidebar → strip → rail;
   RULES §1 test_a11y: "Tab from ANY rail item leaves the rail", arrows step within), so the fourth Tab wraps
   to the rail; the slot ring is seen with `--tab=1` (`Slot_main_hand`, logged "TAB 1 -> Slot_main_hand<Button>
   at 440,144 62x74"). Both shots are in the Shots section; the plan's 4 predates the region model.
8. **The weapon slot is a `ButtonSlot` wearing the theme's `SlotWeapon` panel box** as its normal/hover/
   pressed/disabled overrides — no new Button-family variation (those must go through Theme.gd's `_button()`,
   which this unit does not own), and the focus ring is still `ButtonSlot`'s from `_button()`.
9. **The formula's one-line claim is measured, not assumed:** with FiraSans-Regular at 13px (PIL, the
   shipped TTF) the fixture line is 358px against RIGHT_TEXT_W 375; "Uncommon" makes it 374 and a
   "their past" term pushes any rarity past 375 and onto two lines. Autowrap stays on so the fallback is a
   wrap, never a clipped "baselin". The alternative (a LabelSmall of terms over a LabelBody "= 45 baseline")
   would split "45 baseline" from "50 base" — test_raider_detail reads them separately, so it would pass,
   but HALL-26 asks for the result on the formula's line.

## Left undone / notes for later units

- `Widgets.tooltip_for` switch: handoff §1 (applies inside PaperDoll.gd once KIT2 lands).
- The faint disc visible through the right panel at ~(880,440) on every RaiderDetail shot is the camp
  stage's lantern glow bleeding through PanelWarm's 9-slice — present on the wave-2 shot too; not this unit's
  (the panel texture is W1-CHROME's, the light is the stage's).
- At 150% the formula wraps (expected: the acceptance is at 100%) and the roster strip's card class line
  ("Warrior — Very Happ") clips — `Cards.card`, W3-KIT2's.

## Shots

(each viewed with the Read tool; what it shows)

- `build/shots/W3-DETAIL-before.png` = the wave-2 sweep's fixture shot (20:55): the seven-row slot list,
  "7 AC / 0 HP / 0 Power / 0 Mana / 0 Damage", the formula wrapping "baseline" onto a second line, the
  sidebar empty from Dismiss (y≈395) to Back (y≈650), the "not yet" sentences as prose under "On record".
- `build/shots/W3-DETAIL-ref-c2-panel.png` (Concept 2, 20,745,235,240 at 2x): the tall weapon slot left of
  a 3x2 grid of icon-only slots under the bust and the two bars — the target.
- `W3-DETAIL-fixture.png` (22:05, first round): the doll — Bork's bust at 2x in the PortraitFrame well
  (184x192), the 62x74 weapon slot with the dim sword glyph, the 3x2 grid (shield/helm/chainmail over
  leggings/boots/ring; worn ones bright, empties dim) — over "120 HP | +7 AC | +0 Power | +0 Mana | no
  weapon", a rule, seven legend rows ("Head — Worn Iron Cap · worth 1 G", "Trinket — empty" in CAUTION).
  Right panel: "50 base -5 Common +0 Guildhall +0 furnishings = 45 baseline" on ONE line, Settled, Slots,
  Straw Cot / Hot Bath Token, rule, "Backstory" with the quill and the sentences centred — the hint drawn
  over the wrapped second line (fixed, call 3). Sidebar: card, the reasoned Cheer up (padlock, dimmed,
  "They are fine." in CAUTION under it), Dismiss, rule, "On record" / "Ran 0 raids · saw 0 wipes · took 0
  drops" / "No history yet…", Back. Crops `W3-DETAIL-fixture_doll2x.png`, `_backstory2x.png`.
- `W3-DETAIL-focus-tab4.png` (22:05, retaken 22:35): the ring back on Camp (call 7).
- `W3-DETAIL-focus-tab1.png` (22:35): the 2px steel ring around the 62x74 weapon slot, its sword glyph
  lifted from 0.35 to 0.7 by the focus colour; the rest of the screen as the fixture shot.
- `W3-DETAIL-text150.png` (22:05, first round): the stat strip clipped "no we" (fixed: HFlow), the formula
  wrapping (expected), the sidebar's Back pushed under the rim (fixed: call 6).
- `W3-DETAIL-empty.png` (22:05): "Nobody selected" + the sentence + "Back to the roster" in the sidebar;
  Kit / On record panels each a glyphed empty state (bench, quill); "No guild loaded." chip; strip empty.
- `W3-DETAIL-sidebars150-before.png`: the wave-2 sweep's RaiderDetail / Tavern / Guildhall sidebars at 150%
  side by side — the family's baseline for what 150% tolerates.

- `W3-DETAIL-fixture.png` (final, 22:40) and its crop `W3-DETAIL-fixture_sidebar.png`: as the first round
  plus the fixes — the stat strip a flow, the Backstory block = quill / "Nothing is written down about them
  yet." / the hint "Wants nothing in particular. Backstories arrive with the Tavern; wishlists with the loot
  module." in two muted lines, no overlap; the legend closed by a rule and "4 of 7 slots filled · the whole
  kit would fetch 4 G at the Market"; the sidebar's record = "Ran 0 raids · saw 0 wipes · took 0 drops" /
  "Joined while the guild was Unknown." / "No history yet…", then 105px of air, then Back. W3-KIT2's class
  glyphs on the strip cards and the quill in the event log are theirs and landed between the two rounds.
- `W3-DETAIL-text150.png` (final) + crop `_sidebar.png`: the five stat cells on two rows ("no weapon"
  alone on the second, full width), the legend scrolling under the totals with the kit's bronze 8px bar
  visible at the panel's right, the record scrolling likewise in the sidebar and "Back to the roster"
  still on the panel; the formula wraps after "+0" (expected at 150%); the sidebar keeps its width.
- `W3-DETAIL-dismiss.png` + crop `_sidebar.png` (`--press=Dismiss`): the note "Letting somebody go costs
  the people who stay. It always does." wrapped at the column, then the DANGER-rimmed Confirm plate with
  "Yes — let them go (-2 morale to everyone else)" in DANGER on two lines and "Keep them" beside it
  wearing the focus ring (the default focus); the record and Back beneath, unmoved. The first take of this
  shot (22:35) had the pair widening the column and clipping both "Keep them" and the note — fixed by
  wrapping the yes text inside its plate (Button.autowrap, as `Widgets.cta` does).
- `W3-DETAIL-empty.png` (retaken 22:35): unchanged from the first round.

## Log

- 21:20 read 00-plan §0/§4 (W3-DETAIL), RULES.md in full, HALL-07/08/09/23/26, CRITIC-G05/G06, KIT-12/22,
  RULES-12, LESSONS.md, report/handoff-W1-KIT, handoff-W2-TAVERN, RaiderDetail.gd + test_raider_detail.gd
  in full, the Widgets/Theme/Cards/Icons APIs at the wave's start. W1-KIT's handoff §1-§2/§8-§9 are
  already applied in RaiderDetail.gd (`Widgets.sparkline`, `on_page` pager). `Widgets.tooltip_for` does
  not exist yet (grep) — KIT2's, same wave — so the tooltip text is composed locally.
- 21:55 before number recorded: `build/shots/W3-DETAIL-before.png` vs concept 3 masked `0,77,1536,649`:
  mae 37.817, rmse 69.894, structure 0.1855, layout_iou 0.0992, palette_divergence 0.2835, within-8
  47.84% — DIFFERENT.
- 22:05 `game/ui/PaperDoll.gd` (new, tabs): `build(portrait, cells, who)` → HBox "PaperDoll" = PortraitFrame
  well 184x192 (bust 180x188, nearest) + weapon Button 62x74 (`ButtonSlot` with the theme's `SlotWeapon`
  panel box as its normal state; focus ring untouched) + GridContainer "Grid" 3x2 of 47px
  `Widgets.slot_button`s named `Slot_<key>`, text = slot name, icon native-size centred, caption hidden
  behind the icon; a slot absent from `cells` is a dimmed `Widgets.slot` well named `Blank_<key>`, not a
  Button. `slots_of(doll)` → {slot: Button}. WIDTH = 184+8+62+8+151 = 413 ≤ LEFT_TEXT_W 418.
- 22:20 `RaiderDetail.gd` rewritten around it: `_kit` = doll + `_totals` (HALL-08) + rule + a scrolled
  legend (`_legend_row` per available slot + rule + `_kit_summary`); `_quick_apply` →
  `Widgets.reasoned(b, reason, Icons.at("lock","16"))`; `_dismiss_block` → `Widgets.confirm_pair` (texts
  kept); the sidebar = card → notice → Cheer up → Dismiss → rule → scrolled "On record" (counters, joined,
  trend, sparkline, turning points) → Back; the right panel = Quarters (formula one LabelSmall,
  single-spaced) → rule → "Backstory" (one `empty_state` with quill + hint when nothing is written;
  bullets/wants otherwise); `_right` fills the scroll so the empty state centres. Seams: `slot_buttons()`.
- 22:08 `tests/unit/test_paper_doll.gd` (new, spaces, 13 tests). Parse check green for the three files
  (RaidView.gd and Widgets.gd failed in the same runs — RAIDVIEW2's / KIT2's mid-edits, not mine).
- 22:12 `test_paper_doll.gd` + `test_raider_detail.gd`: 42 passed (a one-file runner mirroring
  tests/run_tests.gd, kept in the OS temp dir so no unowned file enters the tree).
- 22:05-22:15 shots (see Shots); fixes for the four things they showed (judgement calls 3-7).
- 22:15 third shot batch and test run hit W3-KIT2's mid-edit `Cards.gd` (5 SCRIPT ERRORs, RaiderDetail
  cannot compile) — 23 of 42 tests red for that reason alone; the three shots of that batch are blank and
  will be retaken.
- 22:17 every file under build/plan/ rewritten by something outside this unit; this report, the handoff
  and build/diff/ vanished. 22:30 both files re-created from context.
- 22:35 tree whole again (PARSE_CHECK OK, 172-173 scripts); 42 tests green; all shots retaken and viewed.
  Found the confirm pair widening the sidebar (LESSONS' uncapped-control trap) — yes text now wraps inside
  its plate at two lines of `Type.at(SIZE_META, scale)`; and the two scrolled columns widening their panels
  by the bar's width at 150% — `LEGEND_TEXT_W` / `RECORD_TEXT_W` = the column minus 10.
- 22:45 `verify.sh --fast` (log `build/shots/W3-DETAIL-verify.log`): lint, MOTION LINT OK, parse, generated
  content, ART CHECK 0 DIFFERS 0 MISSING pass; 8/1908 unit failures, every one in another wave-3 unit's
  file (listed in the acceptance line); none names RaiderDetail, PaperDoll or test_paper_doll.
  `a11y_smoke.gd`: A11Y SMOKE PASSED 26 mounts (`build/shots/W3-DETAIL-a11y.log`). `tools/lint_motion.sh`:
  MOTION LINT OK. After refdiff recorded (flat). Done; the one open item is handoff §1 (tooltip_for).
