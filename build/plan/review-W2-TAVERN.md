# review-W2-TAVERN — adversarial review of "candidate cards carry their gear, the sidebar fits, the caption is a plate"

Reviewer: adversarial reviewer (wave 2). 2026-09-14. Verified against the TREE, not the report.
Owned files: `game/screens/Tavern.gd`, `tests/unit/test_tavern_layout.gd` (new).

## 1. Working tree and ownership

`git status --porcelain` at review time: modified `game/screens/Tavern.gd`; untracked `tests/unit/test_tavern_layout.gd` (+ `.uid`), `build/plan/report-W2-TAVERN.md`, `build/plan/handoff-W2-TAVERN.md`. All owned.

Changed files NOT in this unit's owned list (attributed to other wave-2 units by the ownership table, nothing in this unit's diff/report claims them): `game/assets/bg/camp_plate.png(.import)`, `guildhall_plate.png(.import)`, `game/assets/scenes/camp.json`, `guildhall.json` (deleted), `stage_camp/market/tavern/town.json`, `game/ui/SceneStage.gd`, `tests/unit/test_scene_stage.gd`, `tools/art/patch_bubbles.py` (W2-STAGE2); `AdventureBoard.gd` (W2-BOARD); `Market.gd` (W2-MARKET); `RaidView.gd` (W2-RAIDVIEW); `Results.gd` (W2-RESULTS); `Town.gd` (W2-TOWN); the other units' report/handoff/review/test files; `aguildstory.zip` (untracked, not a unit's). Nothing in Tavern.gd's diff reaches outside the two owned files.

Diff of `game/screens/Tavern.gd` read in full (+509/-201): the caption plate (`_plate`, `_build_tabs`, `_build_plate`, `_floor_line`, `_place_manage`), the strip (`Cards.event_log` + `Footer`), the card (`_gear_slots`, `_rarity_rim`, `PanelRoundSelected`, class row + stamp, `Morale` column), the sidebar (`SidebarScroll` built by the screen inside `Frame.sidebar`'s panel, `_wrapped`, `_reasoned`, `Widgets.cta`), `confirm_pair`, `ButtonQuiet`, `_chips()` deleted, `Frame.refresh_chips` on refresh, focus re-wire (`_focus_region/_regrab/_first_focusable/_rewire_focus`).

Kit APIs the screen calls (`Widgets.tab_row/tabs_of/slot_rarity/MINI_CELL/cta/reasoned/confirm_pair/empty_state`, `Cards.event_log/gear_icon/roster_strip/SCREEN_FOCUS_META/PAGER_NEXT_X`, `Frame.refresh_chips/standard_chips`, `Icons.at("empty","bench")`, `Type.gold`, `Reputation.recruit_tiers`, `Recruitment.modal_rarity/cost_of`, `Enums.slot_name_of`, `Palette.TEXT_MUTED_WARM`, theme variations `PanelCallout/PanelRoundSelected/SlotMini/NavItemActive/ButtonQuiet`) all exist in HEAD (`git status` shows Widgets/Cards/Frame/Icons/Type/Theme/Palette/Reputation/Enums unmodified) — no same-wave dependency.

Indentation: Tavern.gd has 0 lines starting with a space and no tab-then-space runs; test_tavern_layout.gd has 0 tabs (spaces throughout). `_ready() -> build()` is pre-existing (HEAD:62-63) and the pattern every screen uses.

## 2. Tests and verify --fast as observed

`GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (18:51, exit 1):
- 0/8 LINT OK · MOTION LINT OK — PASS
- 1/8 PARSE_CHECK scanned 166 script(s) — PASS
- 2/8 16 generated files agree — PASS · 2b/8 ART CHECK 184 agree 0 DIFFERS 0 MISSING — PASS
- 3/8 `TESTS FAILED 1/1801` — the only failure is `test_town_layout.gd :: test_the_locked_blacksmith_is_the_same_height_dimmed_with_a_one_line_reason` ("locked plate 85 tall vs 58"). That is W2-TOWN's test on Town.gd's callout plates; Tavern.gd is not on its path. No line mentioning tavern/Tavern anywhere in `.verify.log`; 0 SCRIPT ERRORs. The one engine ERROR after the summary ("Must be an ancestor of the control" at `ensure_control_visible`) comes from `AdventureBoard.gd:890/920` (W2-BOARD), not this unit — Tavern.gd never calls `ensure_control_visible`.
- 4-7 SKIP (--fast).
So verify_fast is RED, but not because of this unit's files; test_tavern_layout.gd's 11 tests, test_tavern.gd, test_screens.gd and test_a11y_legibility.gd all passed inside the 1800.

`tools/lint_motion.sh` run alone: `MOTION LINT OK`.
`a11y_smoke.gd` run through the lock (build/shots/review-W2-TAVERN-a11y.log): `A11Y SMOKE PASSED 26 screen mount(s)`; Tavern empty sweep `ok … focusable=9 reachable=12 disabled=3`, fixture sweep `ok … tab ring=4 focusable=20 reachable=20 disabled=2`; no `warn` line for Tavern.

## 3. Shots retaken and viewed

All through the lock with §0.3's grammar (one lock hold, `build/shots/review-W2-TAVERN-shot{1..5}.log`, every `SHOT OK`):

- `review-W2-TAVERN-Tavern.png` (`--fixture`), viewed + 2x crop `review-W2-TAVERN-crop-cards.png`: ONE plate top-left (Board lit with a gold underline, Manage quiet; "house 1 of 4 · 4 seats"; "At Unknown the room is mostly Common adventurers."; "Legendaries 0 of 9"; "Ask around again — 50 G" + its rule; "Take the room next door — 120 G, one more seat" dimmed with "Unknown guilds cannot commission this. Reach Known." under it). Four cards each with the portrait, THREE empty mini slots beside the name, a 2px grey rim on cards 2-4 (Common's colour), the selected card in the steel `PanelRoundSelected` rim with "Looking" in the active-tab plate; class line full width; two-line morale row; bullets scrolling with a visible bar; Recent Events panel in the strip's corner; footer "Roster 12 of 15 · Hiring Linda leaves 12,420 G". Measured with PIL: sidebar rim's bright row at x=1300 is y=712 (inner line 706; the strip's top rim at 717-718) — bottom ≤ 714 holds. Log panel rim: x 1045..1518, y 734..995 on screen (= strip-local 1032..1505, the plan's rect).
- `review-W2-TAVERN-Tavern_Manage.png` (`--press=Manage`): Manage lit; the roster list hangs under the plate (top ≈268, bottom ≈695) with a visible 8px bar; each row portrait · "Name — morale glyph" · "Class — band · rarity" · Dismiss; the strip keeps the board + log + footer; the sidebar carries "Manage", the warning sentence and "Back to town" — sparse, as the report says.
- `review-W2-TAVERN-Tavern_text150.png` (`--set=text_scale=150`): the plate grows (~1040x300) with nothing clipped; the sidebar column scrolls with its bar INSIDE the rim (x≈1517), "Back to town" below the fold; the cards hold 262 — "Wizard — Common" wraps to two lines on card 2, and on that card the bullet scroll region is squeezed to ~0-5px (no bullet text visible at all; cards 1/3/4 show one bullet line). Compared against the pre-unit sheet `build/shots/all/text150/Tavern.png` (08:47): there the sidebar overflowed the frame's right edge and the cards bled text past their rims — the after is strictly better on clipping, but the card-2 sliver is a real readability gap at 150 (see Findings).
- `review-W2-TAVERN-Tavern_emoji.png` (`--set=emoji_free=true`) + crop `review-W2-TAVERN-crop-cards-emoji.png`: "starts at 46 |||||....." and the band word "Slightly Annoyed" on every card.
- `review-W2-TAVERN-Tavern_focus.png` (`--fixture --focus --tab=3`): TAB 1 → `Tab0` (Board, on the plate at 240,107), TAB 2 → the Hire CTA (1174,407), TAB 3 → the first seat slot (25,775) where the steel ring shows. Region hopping is Frame's Tab semantics (arrows step within a region).
- Before/after of the sidebar foot (`review-W2-TAVERN-sidebar-foot-before-after.png`, from the 17:39 fixture sheet vs my shot): before, the sidebar's rim ran to y≈775 and painted over the strip's Recent Events panel (bright rows at x=1300: 748/749/775/781); after, the rim stops at 712 and the log panel is whole. TOWN-17 is a real fix, not a pre-existing pass.

### Probe: a candidate who carries gear
No shot and no test shows a FILLED slot: the sim grants no equipment at recruitment today (`Recruitment.gear_plan` exists but nothing calls it outside its own test; `Raider.equip` is called only from `GameState:1960`, the loot hand-out), so every recruit's `equipped_items` is empty and the sidebar prints "arrives with nothing anyone would call armour" for all four. That is sim/, not this unit's. I ran a scratch SceneTree probe through the lock (equipped the warrior starting set on candidate 0, set him Epic, built `_candidate_card(who, 1)`): `gear cells=3 filled=3 textured=3`, tooltips "Head — Worn Iron Cap" / "Chest — Damaged Chainmail" / "Legs — Worn Leggings", rim border (0.61,0.37,0.80) width 2 (Epic purple), `card min=(215, 262)` — exactly the cap, no overflow. The filled path works; the fourth piece (boots) is not shown, which is the plan's "three slots".

The same probe printed the numbers `test_a_common_candidate_fits_the_sidebar_without_scrolling` compares: `sidebar col min before settle=384 after=384` — `_settle_wraps` changes NOTHING headless; a wrapped Label whose text spans two lines on the shot ("starts at 46 morale · misses about 30% of the time · 0 raids behind them") reports `lines=1 min=(330, 23)` after `size = (330, 0)`. And `panel.get_combined_minimum_size().y = 0` (Frame's sidebar panel is a positioned Control whose minimum never carries the column), so test 1's second assertion and test 4's assertion are true by construction.

## 4. Acceptance lines

| Line | Met | Evidence |
|---|---|---|
| Tavern shot: cards show three gear slots | yes | `review-W2-TAVERN-crop-cards.png`: three `SlotMini` cells beside every portrait; probe: 3 filled cells with textures when a candidate carries gear |
| … and a coloured rim | yes | Common's grey 2px rim on cards 2-4 (`_rarity_rim`, `border_width_all(2)`, `Palette.rarity_color`); probe: Epic rim purple; the selected card `PanelRoundSelected` (test asserts) |
| … one plate top-left | yes | `Caption` (`PanelCallout`) at scene (14,14), the only plate in the scene region; tabs, house, floor, meter, reroll+rule, upgrade+reason, notice all inside it (shot + test 7) |
| … Recent Events at (1032..1506, 734..996) | yes | measured rim x 1045..1518 / y 734..995 on screen = strip-local 1032..1505 (the kit's `event_log` rect); on both tabs (Manage shot; test 8) |
| … sidebar bottom at y ≤ 714 | yes | measured rim's bright row y=712 at x=1300 (before: 775); at 150 the column scrolls inside that rim |
| `test_tavern_layout.gd` asserts the sidebar panel's `size.y <= sidebar_host.size.y` on Tavern | yes | test 1 (`panel.size.y <= host.size.y`, 635 ≤ 635) — passes in the suite; see Findings 1 for the two assertions that are vacuous |
| `test_tavern.gd` and `test_screens.gd:856-931` (emoji-free band word) green | yes | verify --fast 1800/1801 with the one red in test_town_layout.gd; emoji shot shows "\|\|\|\|\|....." + "Slightly Annoyed" |
| "Ask around again", "Take the room next door", "Not tonight", "Hire — " remain Button text | yes | Tavern.gd:821 `Widgets.button("Ask around again — %d G")`, :845 `Widgets.button("Take the room next door — …")`, :747 `Widgets.button("Not tonight")`, :736 `Widgets.cta("Hire — %d G")`; test 7 finds the first two as Buttons on the plate |
| refdiff Tavern vs 3 masked recorded | yes (mixed) | re-run by me: before (17:39 sheet) mae 34.913 / iou 0.1038 / palette 0.3498 / within-8 52.53; after (my shot) mae 36.938 / iou 0.1116 / palette 0.2826 / within-8 48.63 — identical to the report's numbers. Per-region mae vs concept (PIL): header 92.8→92.8, rail 18.6→18.6, sidebar 41.7→42.0, strip-log 19.9→19.9, strip-cards 21.9→26.1, footer 8.1→11.0 — the move is the card's slot placement and the new footer text, as the report says |
| Shots: `--fixture`, `--press=Manage`, `--set=emoji_free=true`, `--set=text_scale=150` | yes | all four in build/shots/W2-TAVERN-*.png (18:34) and retaken by me (18:52) |
| Green: every bullet printed before the Hire button exists | yes | `_candidate_card` builds the bullet block before `_build_sidebar` builds Hire; test_tavern's `test_every_backstory_bullet_is_face_up` green |
| Green: `_candidate_card(who, index)` returns a Control with a v-scrolling ScrollContainer under `CARD_SIZE.y` | yes | Tavern.gd:566-572; test_a11y_legibility.gd:793-848 green; probe min 262 with three filled slots |

## 5. Green line and §0.5 contracts

- Label/Button texts read by tests unchanged: "Hire — ", "let them go", "Keep them", "Nobody to manage", "Legendaries 0 of N", "Back to town", "Nobody is drinking." all present in the tree (grep of tests/unit vs Tavern.gd); the confirm texts are byte-identical inside `Widgets.confirm_pair(...)`.
- Node names tests read: `Confirm/Yes/No` (kit), `Sidebar/SidebarHost/StripHost/SceneHost` (Frame) — none renamed. New names (`Caption`, `Notice`, `ManagePanel`, `Gear`, `Morale`, `Footer`, `SidebarScroll`, `SidebarCol`) are additions.
- Indentation: tabs only in Tavern.gd; spaces only in the test. Parse check 166 scripts PASS.
- `create_tween`: none in Tavern.gd; no tween at all; `reduced_motion`/`reduced_effects`: not mentioned. `MOTION LINT OK`.
- `$GODOT` outside the lock: no script added by the unit (two .gd files only).
- New PNGs: none; `.import`: n/a; baked text: n/a.
- Router host: the test mounts `TavernView.new()` under `root`, and parents probe cards to the view — nothing to the router host.
- Overlays `MOUSE_FILTER_IGNORE`: the `Footer` Label has it; the plate is interactive (holds Buttons) so it is not an overlay; the tab row's underline is the kit's (IGNORE).
- Disabled controls with a reason: reroll/upgrade/Hire through `Widgets.reasoned` (+ a wrapped Reason Label); a11y_smoke fixture `disabled=2`, empty `disabled=3`, no warn. "Looking" is enabled (judgement 4) so it owes no reason.
- Every visible BaseButton FOCUS_ALL: a11y fixture sweep `focusable=20 reachable=20`.
- No hex colours (`Color("` absent), no `class_name`, no `_ready` logic beyond the pre-existing `build()` call, `Type.gold` for the footer's numeral, no font sizes set by hand.
- Handoff: "No edits" plus two notes for W3-KIT2 — nothing to apply, so no old/new blocks to check.

## 6. Judgement calls vs §6

The ten calls in the report (rarity rim vs selected rim, mini slots beside the name, band word placement, "Looking" enabled in `NavItemActive`, two-column plate, meter on the plate, board kept on Manage, screen-built sidebar ScrollContainer, wrapped reason, focus re-grab) are all inside Tavern.gd's own layout and none touches Q01-Q18: the card shows no level (Q11), "Pauline_4" stays (Q13), the morale face goes through `Cards.morale_glyph` (Q17), the rarity-floor sentence is composed from `Reputation.recruit_tiers` with no typed rarity except the plan's own quoted "Common" line. The mini-slot placement against Concept 3's bottom row is the memory rule (design wins where the reference's UI does not fit) and is recorded with numbers. No blocker here.

## Findings

1. **minor — two of the new test's size assertions are vacuous, and the report overstates them.** `_settle_wraps` (test_tavern_layout.gd:143-149) sets `size = (w, 0)` on wrapped Labels, but headless nothing reshapes: my probe shows a two-line sentence still reporting `lines=1`, min 23px, column min 384 before AND after settling. So `test_a_common_candidate_fits_the_sidebar_without_scrolling` compares one-line heights (384) against the room (~570), not "wrapped Labels shaped at 330" as the report and the test's own comment say; the true need is roughly 480 and it still fits, so the conclusion is right for the wrong reason. Likewise `panel.get_combined_minimum_size().y` is 0 by Frame's construction (tests 1, 2, 4), so "its MINIMUM must not exceed the host" cannot fail. The load-bearing guard is test 1's `panel.size.y <= host.size.y` plus the shots. Evidence: probe output above; test_tavern_layout.gd:143-149 (`_settle_wraps`), :177, :193, :198, :242 (the `get_combined_minimum_size().y <= host.size.y` assertions).
2. **minor — at text_scale 150 the busiest card's bullets vanish into a ~0-5px scroll sliver** (`review-W2-TAVERN-Tavern_text150.png`, card 2: "Wizard —"/"Common" wrap, "starts at 42", "Slightly Annoyed", then "Look" with no bullet row visible). Disclosed in the report as "reduced to a scrolling sliver". It is not a clipped Label (the ScrollContainer reflows) and the 215x262 card at 150 cannot hold a wrapped class line + morale + bullets — the conflict is already filed in build/plan/q-a11y-legible.md — but a keyboard user cannot read those bullets on that card at 150 without the sidebar. A note in the handoff (a `Cards`/`Widgets` card variant for 150, or a shorter class line at 150) would have been the right place; none was written.
3. **minor — the "filled" gear-slot path is never exercised by a shot or the test.** No recruit carries equipment today (sim), so `filled == mini(3, worn)` in test 5 is 0 == 0 and every shot shows empty cells. The report's "empty on the fixture's Common recruits, filled … when a recruit arrives with gear" reads as if rarer recruits would show gear; none do until `Recruitment.gear_plan` is wired (not this unit's file). The test could have equipped a starting piece on the candidate (`who.equip(db, item)`) to exercise the path; my probe did and it works.
4. **note — refdiff is mixed**: mae +2.0 and within-8 -3.9pt against iou/structure/palette improving; the whole move is the card region (+4.2) and the new footer line (+2.9). Recorded per the plan's acceptance wording; not chased, per the memory rule.
5. **note — Manage's sidebar is sparse** (section, one sentence, Back to town) — acknowledged by the report, not a finding of this unit.

Nothing outside the two owned files was touched by this unit; no §6 ruling was taken; no asserted string or node name changed; no canon number moved.

## Verdict

**pass** — every acceptance line is met in the tree and in my own shots; verify --fast is red only on `test_town_layout.gd` (W2-TOWN), which Tavern.gd cannot influence; a11y smoke 26 mounts PASSED; MOTION LINT OK. Minors 1-3 above (a weak test mechanism the report oversells, a 150% sliver disclosed but not filed onward, and an unexercised filled-slot path) — none the unit was required to fix by the plan's text.
