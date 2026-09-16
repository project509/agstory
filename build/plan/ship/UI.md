# Ship report — UI (art and UI as shown)

_Reporter: UI. Read-only pass over the tree during wave 5, 2026-09-15. Evidence is file:line or sheet/tile coordinates; nothing here was measured with a Godot run._

## Executive summary

1. **Shippable today:** the frame, the chrome, the six bare plates with their living scenes, the icon grid, the header, the rail, the roster cards, the paper doll, the Load/Save and Settings shells, both wide modes (Keep is clean on all 13 routes; Expand clips nothing) and the 100% fixture on nine of thirteen routes — the game LOOKS like the references' dashboard and nothing at 100% overlaps a rim.
2. **Not shippable today:** the dialogue surfaces. The wipe report ellipsizes every joke (UI-23), the live log cuts the mistake's name (UI-19) and slices its top row (UI-35), the Board's sidebar trims the notice's punchline (UI-13), the tavern card slices a bullet mid-glyph (UI-05) — the comedy this game is about is the thing the UI cuts.
3. **Not shippable today:** 150% on RaidView, Results, RaidPrep, Market and RaiderDetail after W5-SCALE's contract (UI-32), plus the rail's 14px "Adventure's Board" (UI-30) and the "Shama"/"Warri" class trim (UI-31) on every framed screen.
4. **Not shippable today:** developer copy on player screens — "Canon lists this one as a maybe. Disabled in this build." on the hub (UI-01), "wishlists with the loot module" (UI-27), Options' "13 of 17 live in this build" with four dead rows and "those live in data/tuning" (UI-28), the ending's "recorded as docs/15 Q-21 and audit M5-END-4" (UI-48).
5. **Biggest gap 1 — the report and the log as reading surfaces** (UI-19/23/24/35): one M unit in wave 6; it changes spec 02 §2.1 from "rows never wrap" to "LIVE rows never wrap".
6. **Biggest gap 2 — the fight's picture** (UI-16/20/21/22/34/38): the prep band is an empty rectangle, the twelve 2x figures overlap into one mass with the joke plate over their heads, the boss is 1x behind a fence, the dead stand as statues, damage numbers overlap. Two M units in wave 7; the scale half waits on Q01/Q02 but every fix here ships at the built defaults.
7. **Biggest gap 3 — copy and empty states** (UI-01/02/03/06/09/11/12/14/27/28/51): a dozen S fixes plus a copy lint; the Market opening on "Sell your tank's hat for 1 G" (UI-09) is the one mental-model hazard.
8. One cause under four screens: the camp's PointLight2D lanterns light the panels drawn over them — a disc in RaiderDetail's Quarters, the Facilities panel, the Records wall (UI-26, one line).
9. Records: three audit rows are stale as written (m4t-12 done under BL-78, M4B-VFX-01's airship plate no longer exists, M6-A11Y-07 done by the icon grid — UI-42/43/44); m4t-04 is half done (UI-39); M6-JUICE-07 is a WARN stage (UI-45); the CVD switch BUILD_STATE claims is unreachable (UI-47).
10. Of the eighteen designer questions, every one has a built or S-sized shippable default (the table before the bar); only Q01/Q02 (figure density — 2x integer scale vs an XL re-author) changes the finish, and that is the single question worth the designer's time. 56 findings: 44 CONFIRMED, 9 BLOCKED-designer with a default, 3 REFUTED; 28 land in wave 6, 13 in 7, 10 in 8, 4 in 9, one at the wave-5 close (UI-49, the 180x571 tooltip — a pending handoff).

## Findings

### UI-01 — The locked Blacksmith callout speaks developer-English to the player
**Status** BLOCKED-designer (Q13), but a shippable default exists in the tree.
**Evidence** `build/shots/all/fixture/Town.png` tile (505..900, 400..478): the callout reads "Blacksmith / Canon lists this one as a maybe. Disabled in this build." — `game/screens/Town.gd:567` returns that string when the flag is off; the designer's own blurb "Under construction." (`Town.gd:110`, commit cfd2c29) is never drawn because `Widgets.building_callout` (`Widgets.gd:1685`) prints `reason` on the second row in place of the subtitle. `tests/unit/test_screens.gd:290/311/371` pin the word "maybe".
**Doc** docs/15 has no Q- row; 00-plan §6 Q13 ("the strings stay verbatim"). The designer already answered the blurb half; the reason half is the open one.
**Fix** Draw the designer's blurb on the callout's second row ("Under construction.") and keep the maybe-string as the a11y/tooltip reason (`Widgets.tooltip_for`), or shorten it to a player sentence that keeps the pinned word ("Maybe someday. Not in this build."). Either way the words "Canon" and "this build" leave the screen. Test edit: the `printed.contains("maybe")` pin reads the reason wherever it lands.
**Owns** `game/screens/Town.gd` (`_unlock_reason`, BUILDINGS), `tests/unit/test_screens.gd` (:290-371).
**Size** S.
**Wave** 6 — copy the player reads on the first screen; zero risk; no designer needed if the tooltip route is taken.
**Audit** relates to TOWN-02/TOWN-20 (00-plan §7); no audit.json row.

### UI-02 — "1 enemies": the mission facts line does not pluralise
**Status** CONFIRMED.
**Evidence** `build/shots/all/fixture/Town.png` sidebar (1174,270): "Trash · 1 enemies · about 6 rounds" (crop `build/plan/ship/crops/town_mission.png`). `game/screens/Town.gd:468` and `game/screens/AdventureBoard.gd:523` both format `"%d enemies"`; `AdventureBoard.gd:582`'s comment even quotes the wrong string as expected. A0 and every single-enemy adventure show it.
**Doc** docs/13 §4.4 (copy never abbreviated or malformed) — no row needed.
**Fix** One `Widgets.plural(n, "enemy", "enemies")` (or inline `"enemy" if n == 1`) at both sites; the board's comment fixed with it; a test in test_town_layout that A0's facts read "1 enemy".
**Owns** `game/screens/Town.gd`, `game/screens/AdventureBoard.gd`, `tests/unit/test_town_layout.gd`.
**Size** S.
**Wave** 6 — trivial, visible on the first screen.
**Audit** none.

### UI-03 — The Town sidebar ends 145px early; the events panel is a day-one empty state on the reference fixture
**Status** CONFIRMED (layout), partly by design.
**Evidence** `build/shots/all/fixture/Town.png`: the mission panel's last control "Back to menu" sits at y=549; the panel runs to y=715 — ~145px of bare navy under it (Concept 3's panel ends at its CTA, 1160..1520 x 80..660, because it is sized to content). The "Recent Events" panel (1045..1520 x 734..996) shows "Nothing has happened yet." with the fixture at Day 23 / 12 raiders, because the feed is a non-persisted ring buffer (`Cards.recent_events`, W3-KIT2) and `tools/fixture_reference.gd` seeds no events.
**Doc** spec 01 §4 / spec 03 §1 (panel is content-sized); docs/13 §5.3 (the hub's feed).
**Fix** (a) Size the mission panel to its content or move "Back to menu" to the rail (spec 00 §2.6 maps Options→Settings; a menu exit belongs in Settings/Options, as Concept 3 shows no "Back to menu" on the hub). (b) The fixture seeds six feed rows so every sheet shows the log as a player will see it after one raid (the empty sheet already covers day one).
**Owns** `game/screens/Town.gd` (sidebar build, :326-:481), `tools/fixture_reference.gd`, `tests/unit/test_town_layout.gd`.
**Size** S.
**Wave** 6 — the panel's dead run is the largest visual debt on the hub.
**Audit** TOWN-05/TOWN-16 (00-plan §7).

### UI-04 — The joke plate abuts the locked Blacksmith callout on the hub
**Status** CONFIRMED (near-collision, not an overlap).
**Evidence** `build/shots/all/fixture/Town.png`: the speech plate "I think I'm ready for a real raid this time!" spans x 310..503, the Blacksmith callout starts at x 505 (crop `crops/town_joke.png`) — a 2px gap; with a longer corpus line (`Widgets.speech_plate` wraps at its fixed width, so height grows, not width) the plate stays clear horizontally but its tail figure (the hooded raider at 410,530) stands under the callout's band. The callout is fixed by `Town.BUILDINGS` anchors; the speaker is whichever figure `SceneStage.say_at` picks.
**Doc** spec 03 §3 (callouts clear of figure body boxes); docs/13 §7.
**Fix** `Town.gd`'s speaker pick excludes figures whose head lies inside a callout's band ± plate width, or the joke plate is placed by `SceneStage.head_of` with a "keep-out" list of callout rects (SceneStage already gets `marks`). A test builds Town with the fixture and asserts no speech plate rect intersects a callout rect.
**Owns** `game/screens/Town.gd`, `game/ui/SceneStage.gd` (`say_at` keep-out), `tests/unit/test_town_layout.gd`.
**Size** S.
**Wave** 7 — after the dialogue-surface pass (UI-2x) decides the speech plate's final chrome (Q04).
**Audit** STAGE-10, KIT-02.

### UI-05 — Tavern candidate cards slice their trait lines mid-glyph and hide the third bullet
**Status** CONFIRMED.
**Evidence** `build/shots/all/fixture/Tavern.png` cards 2-4 (crop `crops/tav_cards.png`): "boots. It was not kind." and "point. Means it." are cut through the x-height at y≈942 by the card's inner ScrollContainer (`game/screens/Tavern.gd:589-590`, `card.clip_contents = true` at :494); the theme's tan scrollbar (~10px) covers the right edge of the trait column. The card has room for two bullets of two lines; a third bullet (Legendaries carry three, docs/04 §11) is never visible without scrolling a card the player does not know scrolls.
**Doc** docs/13 §4.4 (no text cut), spec 10 §3.3 (candidate card: traits as bullets).
**Fix** Snap the trait scroll's fold to a line boundary the way W5-SCALE's `Guildhall._snap_fold()` does for the sidebar (a `FoldSpacer`), or size the trait block to two whole bullets and put the rest in the sidebar (which already prints every bullet); hide the scrollbar (`ScrollContainer.vertical_scroll_mode = SCROLL_MODE_SHOW_NEVER`) and give the card a "+1 more" caption. Test: with a three-bullet Legendary in the seats, no bullet Label's rect straddles the scroll's clip edge.
**Owns** `game/screens/Tavern.gd` (`_candidate_card`, :560-612), `tests/unit/test_tavern.gd`.
**Size** S.
**Wave** 6 — a cut line on a hiring decision.
**Audit** TOWN-18/TOWN-19 (00-plan §7); M6-A11Y-08 (done) adjacent.

### UI-06 — Three blank squares beside every Common recruit
**Status** CONFIRMED (cosmetic; by construction).
**Evidence** `Tavern.gd:632-634` pads the "arrives with" row to three `Widgets.slot(null, …)` cells; the fixture's four candidates are Common and arrive with nothing, so every card shows three empty 9-slices (`fixture/Tavern.png` 220..340 x 770..805 on each card). The sidebar says "arrives with nothing anyone would call armour" — the cards say nothing.
**Doc** docs/02 §5.3 (recruits arrive with gear by rarity); Q-29 (does the rolled gear price the recruit) at its recommended default.
**Fix** An empty row collapses to one muted caption ("no gear") or the cells draw a dimmed slot glyph (`Icons.at("slot", <kind>)` at 40% alpha — the paper doll already has per-slot silhouettes, `PaperDoll.gd`); keep the three cells when any item exists so the strip's cards stay one height.
**Owns** `game/screens/Tavern.gd` (`_gear_slots`), `game/ui/PaperDoll.gd` (silhouette lookup, read-only).
**Size** S.
**Wave** 8 — polish; after Q-29's answer could change what the row means.
**Audit** TOWN-18.

### UI-07 — The tavern speaker stands on a bench and the joke plate is five times its height
**Status** CONFIRMED; Q01 (tavern figure scale) is the designer half.
**Evidence** `fixture/Tavern.png` (crop `crops/tav_scene.png`): the speaker at (680,640) is a 1x figure ~40px tall whose feet mark sits on the bench-top of the long table, not the floor; the speech plate (585..780 x 542..616, 195x74) is drawn for the 2x camp figures. `game/assets/scenes/stage_tavern.json` `figure_scale` 1 (spec 00 §2.7 row 1); `SceneStage.say_at` sizes the plate from the text only.
**Doc** spec 00 §2.7 Q01; docs/12 §3.3 (the tavern may take a 1.5x exception); spec 09 §4 (tavern layers).
**Fix** (a) Move that figure's mark to the floor beside the table (a JSON edit, `stage_tavern.json`), with a test that no actor mark lies inside a furniture rect listed in the scene (add a `furniture` rect list to the JSON — the plate's tables and bar are measurable). (b) Speech plates on a 1x scene use `Type.at(Type.SMALL)` and a 140px wrap (a `plate_scale` argument on `say_at` keyed off `figure_scale`). (c) The designer's Q01 answer may make (b) moot.
**Owns** `game/assets/scenes/stage_tavern.json`, `game/ui/SceneStage.gd` (`say_at` plate size), `tests/unit/test_scene_stage.gd`.
**Size** S (a), S (b).
**Wave** 7 — with the dialogue-surface pass; (a) can go in 6.
**Audit** STAGE-02, STAGE-10, PIPE-04 (Q01).

### UI-08 — The recruit facts line wraps on the number: "… · 0 / raids behind them"
**Status** CONFIRMED.
**Evidence** `fixture/Tavern.png` sidebar (1174,248): "starts at 46 morale · misses about 30% of the time · 0" then "raids behind them" on the next line — a wrapping Label with " · "-joined facts, the break falls after the "0". Same shape at 150% (`text150/Tavern.png`).
**Doc** docs/13 §4.4.
**Fix** One fact per line (a VBox of three Labels — the cards already do "starts at N" / band on two lines), or join with non-breaking spaces inside each fact (`"0\u00A0raids\u00A0behind\u00A0them"`). Test: no fact Label's line break splits a number from its noun.
**Owns** `game/screens/Tavern.gd` (sidebar `_bar_panel`, ~:700-760), `tests/unit/test_tavern.gd`.
**Size** S.
**Wave** 6.
**Audit** none.

### UI-09 — The Market opens with a raider's WORN helmet pre-selected under the crimson "Sell" CTA
**Status** CONFIRMED (UX / mental model).
**Evidence** `fixture/Market.png`: the Sell tab is the default, the window is empty ("In the window · 0"), and `Market.gd:587-588` falls back to `worn[0]` — Bork's Worn Iron Cap is lit in the grid and the sidebar's only primary control reads "Sell — 1 G" over "worn by Bork". The worn-by confirm (`_confirming`, :589) guards the click, but the screen's first impression is "sell your tank's hat for 1 G". Concept 1/3's sidebar CTA is always the *commit the mission* act; here it is the screen's most destructive one.
**Doc** docs/13 §7 (the crimson CTA is the one commit), docs/11 §4 (sell flow: window first, worn gear behind a confirm).
**Fix** With an empty window, select nothing: the sidebar shows the stall panel first and a muted "Pick something to sell" empty state where the item card goes; the "Sell" CTA appears only once a row is picked. Keep the worn-by confirm. Alternatively default to the Buy tab when the window is empty (the shopper's purpose on arrival is provisions). Test: mount Market on the fixture, assert `_selected == ""` and no Button text starts with "Sell —".
**Owns** `game/screens/Market.gd` (:578-592, the sidebar builder), `tests/unit/test_market.gd`.
**Size** S.
**Wave** 6 — a first-impression hazard on a core screen.
**Audit** TOWN-22/TOWN-28.

### UI-10 — The Market's "Worn by the roster" grid slices its third row of slots at the panel fold
**Status** CONFIRMED.
**Evidence** `fixture/Market.png` (255..760, 640..655): a row of slot tops cut through their 9-slice by the scroll's clip; the panel bottom is at y=690 with an empty band below the clip. The Guildhall's `_snap_fold` (W5-SCALE) is the pattern; the Market has no equivalent.
**Doc** spec 06 §2 (slot grid), docs/13 §4.4.
**Fix** Snap the grid scroll's fold to a whole row (rows are `SLOT + name lines` tall — the name wraps to one, two or three lines so compute per row after layout, or fix the name to two lines with `OVERRUN_TRIM_ELLIPSIS` off and a tooltip); hide the scrollbar until hover. Test: no `SlotMini`/`Slot` rect straddles the ScrollContainer's clip edge on the fixture (48 worn items).
**Owns** `game/screens/Market.gd` (`_sell_tab`, ~:560-660), `tests/unit/test_market.gd`.
**Size** S.
**Wave** 6 — same fold pattern as UI-05; do the three folds (Tavern card, Market grid, Results?) in one unit.
**Audit** TOWN-21.

### UI-11 — The stall panel and the mission panel both leave a 150px dead run above "Back to town"
**Status** CONFIRMED (pattern; Town UI-03, Tavern, Market, Guildhall's sidebar fits).
**Evidence** `fixture/Market.png` sidebar: last content "Next: Second stall, crates, two shoppers." at y=486, "Back to town" at y=667, the panel to 715. `fixture/Tavern.png`: "Back to town" at 545, panel to 715. `fixture/Town.png`: "Back to menu" at 549. Concept 1/3 size the sidebar panel to its content (Concept 3: 1160..1520 x 80..660 with the CTA as its last row).
**Doc** spec 01 §4, spec 03 §1.
**Fix** `Frame`'s sidebar host sizes its PanelContainer to content (a `shrink_end` VBox with the back button pinned at the bottom of the CONTENT, not the frame), or the panel gains a second block that earns the space: the Market's "Next: …" preview as a 337x104 thumbnail (m4t-10's facility thumbs pattern), the Tavern's "house" rules, the Town's "Today" facts. One decision for all four screens so the sidebar reads as one component.
**Owns** `game/ui/Frame.gd` (sidebar host), `game/screens/Town.gd`, `Tavern.gd`, `Market.gd` (sidebar builders), `tests/unit/test_sidebar_fit.gd`.
**Size** M.
**Wave** 7 — after the fold/clip fixes; one unit, four screens.
**Audit** KIT-03, TOWN-16, m4t-10 (thumbnails).

### UI-12 — Two empty-state voices for the same events panel
**Status** CONFIRMED (copy consistency).
**Evidence** `fixture/Town.png` events panel: "Nothing has happened yet. / Raids and rests write here."; `fixture/Market.png` and `fixture/Tavern.png`: "Nothing has happened yet." alone — `Cards.event_log(host, state, rows, hint, glyph)` (`Cards.gd:603`) takes the hint per screen and only Town passes one.
**Doc** docs/13 §5.3.
**Fix** Default `hint` to the hub's line inside `Cards.event_log` so every framed screen reads the same; screens override only with a better line.
**Owns** `game/ui/Cards.gd` (:603), `tests/unit/test_kit3.gd` or `test_widgets_kit.gd`.
**Size** S.
**Wave** 6.
**Audit** KIT-08, TOWN-23.

### UI-13 — The Board's "Selected Notice" truncates the notice's punchline and its facts line with an ellipsis
**Status** CONFIRMED.
**Evidence** `fixture/AdventureBoard.png` sidebar (crop `crops/board_side.png`): "Trash · 1 enemies · about 6 rounds ·..." (the separator survives, the facts "tutorial · skippable" do not) and "…somebody will do something stupid, and that is..." — the tutorial's lesson sentence loses its last three words. Both are single Labels: the facts `sub_label` with `max_lines_visible = 1` + `OVERRUN_TRIM_ELLIPSIS` (`AdventureBoard.gd:592-593`) and the blurb `quip` capped at two lines (`:613-614`), inside `_sidebar()` (:554). The full text is on the cork notice to the left, but the sidebar is the focused element for a keyboard player.
**Doc** docs/13 §4.4 ("never abbreviated"), spec 10 §2 R3 (the sidebar mirrors the notice).
**Fix** The facts line wraps to two lines (SIDEBAR_TEXT_W is 314; the facts are ~380px at 100%); the blurb gets its full line count (the panel has 150px spare below "Back to town" — see UI-11) or the blurb is dropped from the sidebar (the notice already carries it) in favour of the rewards/party facts. Test: no Label on the Board sidebar ends in "…" for any of the 13 Tier-1 notices.
**Owns** `game/screens/AdventureBoard.gd` (`_sidebar`, :554-620), `tests/unit/test_board_rows.gd`.
**Size** S.
**Wave** 6.
**Audit** TOWN-10.

### UI-14 — "Potential Rewards" shows one blank slot for a one-drop notice
**Status** CONFIRMED.
**Evidence** `AdventureBoard.gd:621-626` builds `range(max(2, n))`-style padded cells (`Widgets.slot(... if i < n else null)`); A0's single `loot_slots` entry renders a purple gem plus an empty 9-slice (`crops/board_side.png`, 140..235 x 245..335). Concept 3 shows five filled reward icons — the design's row is "what may drop", never "how many holes".
**Doc** spec 10 §2 R3; docs/10 §9 (A0's guaranteed trinket).
**Fix** Build exactly `n` cells; when `n == 0` print the muted caption "Nothing worth carrying." A0's row then shows the trinket icon alone — and the trinket icon should be the trinket family's (`Cards.gear_icon(Slot.TRINKET, …)` — the charm), not the reputation gem, unless the gem is the deliberate "trinket" family icon (spec 00 §2.5 records canon has no gems; the gem stays only as the Reputation chip).
**Owns** `game/screens/AdventureBoard.gd` (:618-627), `game/ui/Cards.gd` (`loot_slot_icon`), `tests/unit/test_board_rows.gd`.
**Size** S.
**Wave** 6.
**Audit** TOWN-11.

### UI-15 — The reference fixture is not self-consistent (320 RP at Unknown; day 23 with an empty log; levels on four cards)
**Status** CONFIRMED (instrument, not the game).
**Evidence** `tools/fixture_reference.gd:38` `REPUTATION_POINTS := 320` with rank Unknown (Known is `rp_threshold` 120, `data/reputation.json:28`), so the Board sidebar prints "0 more to Known" (`AdventureBoard.gd:733`, the `maxi(0, …)` clamp); the events feed is empty on Day 23 (UI-03); four cards carry `Lv. N` and eight do not (Q11). Every sheet the wave reviews inherit these oddities, so reviewers keep re-noticing them.
**Doc** 00-plan §0.3 (the fixture reproduces the reference for the diff).
**Fix** A `--fixture=play` variant (or a second seam in `fixture_reference.gd`) that is a legal save: rank Known at 320 RP, six feed rows, `level` 0 everywhere unless Q11 says otherwise, one raid behind the guild. Keep `--fixture` byte-identical for `diff_all.sh`'s baselines.
**Owns** `tools/fixture_reference.gd`, `tools/shot.gd` (flag), `tools/shot_all.sh` (a `play` sheet).
**Size** S.
**Wave** 6 — first, so waves 7-10 review against a truthful fixture.
**Audit** RULES-13, G04.

### UI-16 — Prep shows an empty bronze rectangle captioned "The party stands here" instead of the party
**Status** CONFIRMED.
**Evidence** `fixture/RaidPrep.png` (285..672 x 305..500): a 1px bronze rim (`RaidPrep.gd:366-380`, `FightBand`) and a small caption over a dimmed, empty arena; the twelve chalked raiders exist in `_plan` and `SceneStage.place_party` (`SceneStage.gd`, M4B-ACT-05) can stand them on those very marks (`SceneStage.marks(DEFAULT_ARENA)`, :205). The comment at :199-204 says "the preview and the fight are one picture" — the picture is missing its people. Reads as wireframe.
**Doc** docs/13 §10.2 (the prep view previews the fight), spec 09 §4.3 row 5, spec 10 §2 R7.
**Fix** `stage.place_party(chalked)` under the dim (no breath, `motion_held`), greyed figures for empty slots; benching a card removes its figure; keep the rim as a focus outline only when the strip has focus. Test: after `build()` with the fixture the stage has 12 actor children named by raider id; benching one leaves 11.
**Owns** `game/screens/RaidPrep.gd` (`_scene`, `_frame_band`, `_refresh`), `tests/unit/test_prep_layout.gd`.
**Size** M.
**Wave** 7 — the prep screen's identity; after Q01/Q02 scale sign-off ideally, but the default (2x cave) is already what RaidView shows.
**Audit** STAGE-01, W4-PREP leftovers.

### UI-17 — The risk meter is typed ASCII ("///////.................  ELEVATED")
**Status** CONFIRMED.
**Evidence** `fixture/RaidPrep.png` (777,398); `game/core/RaidPlan.gd:205-209` builds `"/".repeat(filled) + ".".repeat(width - filled)` and `RaidPrep.gd:770` prints it through `Widgets.meta`. Under the dashboard chrome it reads as a placeholder. The Guildhall's morale chart, `Widgets.bar` and the new `Widgets.pips` (W5-KIT3) all exist.
**Doc** docs/13 §10.3 ("a word AND a hatch density, never colour alone") — the hatch is the a11y requirement; it need not be typed.
**Fix** Draw the hatch: `Widgets.bar` with a hatched fill stylebox (the theme's `BarHatch`, a 4px diagonal-stripe texture from `gen_ui.lua`), the word beside it; keep `risk_hatch()` for the log/test text (it is asserted). Greyscale test unchanged.
**Owns** `game/screens/RaidPrep.gd` (:765-775), `game/ui/Widgets.gd` (a `hatch_bar`), `tools/aseprite/gen_ui.lua` (stripe tile), `tests/unit/test_prep_layout.gd`.
**Size** S.
**Wave** 7.
**Audit** KIT-12.

### UI-18 — "Raid Team" shows four heads for a party of twelve, with no "+8"
**Status** CONFIRMED (minor).
**Evidence** `fixture/RaidPrep.png` sidebar (1174..1420 x 495..545): four portrait slots under "Raid Team"; the CTA says "12 of 12 chalked". Concept 3's row is four heads + an "Edit" tile; the party there is 4. With 12 the row needs an overflow tile ("+8") or three rows of four (spec 10 §2 R8's answer for the reference's four-vs-twelve).
**Doc** spec 00 §2.4, spec 10 §2 R8.
**Fix** A fifth tile "+N" (ButtonMini) that scrolls the strip to the first unseen card, or a 3x4 mini grid (the "Available" column already draws 4x2 minis at `Widgets.MINI_CELL`).
**Owns** `game/screens/RaidPrep.gd` (sidebar `_team_row`), `tests/unit/test_prep_layout.gd`.
**Size** S.
**Wave** 8.
**Audit** COMBAT-19.

### UI-19 — The combat log's MISTAKE row loses the mistake's name to an ellipsis
**Status** CONFIRMED.
**Evidence** `fixture/RaidView.png` log (crop `crops/raid_log.png`): "MISTAKE  Greg (Rogue) — Severe — Dropped a Mecha…" — the type name, the one fact the row exists to say, is cut at 100% on the first mistake of the fixture. `RaidView.gd:1978-1981` sets `clip_text` + `OVERRUN_TRIM_ELLIPSIS` citing spec 02 §2.1 ("a long row ellipsizes, never wraps"); the blot (18px) + face (18px) + stamp (~85px) + the header at Type.BODY leave ~300px for the text in the 474px panel. The tooltip carries the full text, but tooltips are not a11y-reachable from a log.
**Doc** spec 02 §2.1 (one-line rows) vs docs/13 §4.4 (never abbreviated) and docs/13 §11.3 (the mistake is "the loudest single event in the game's UI"). The spec was measured from a reference row with no stamp; the stamp is ours (COMBAT-08).
**Fix** Reorder the header so the type leads: "Dropped a Mechanic — Greg, Severe" (class is on the card and in the quote's voice); allow exactly the MISTAKE row to wrap to two lines when the stamp is present (the quote line is already a second line, so the row's pitch is known); keep other kinds one-line. Test: for every `MistakeLines` type name, the header Label's string width at BODY fits `474 - 28 - blot - face - stamp`.
**Owns** `game/screens/RaidView.gd` (`_mistake_header`, `_append_line`), `tests/unit/test_log_player.gd`.
**Size** S.
**Wave** 6 — the comedy's delivery surface.
**Audit** COMBAT-08, M5-COMEDY-05.

### UI-20 — The speaker's plate covers the party's heads and their overhead badges
**Status** CONFIRMED.
**Evidence** `fixture/RaidView.png` (crop `crops/raid_party.png`): the plate "The boss did the thing the boss does…" (432..640 x 235..320) sits over the back two ranks (heads at y≈260-300) and over four of the overhead class badges; `RaidView.gd:2328` calls `SceneStage.say_at(spr, line, Motion.BUBBLE)`, which anchors the plate at `head_of(speaker)` with no keep-out for neighbours. On the 2x cave party (three ranks of four, ~50px pitch) any speaker in the front rank speaks over the ranks behind.
**Doc** spec 02 §3 (the bubble sits above the speaker, clear of other figures), docs/13 §11.2.
**Fix** `say_at` takes a `clear_above` rect (the party band from `marks`) and lifts the plate to sit above the crowd's topmost head + 8px, with the tail lengthened down to the speaker (the tail is a drawn triangle in `Widgets.speech_plate`; make its length a parameter); when the speaker is the boss, anchor to the boss plate's bottom-left. Test: in `test_scene_stage.gd`, after `place_party` + `say_at(front-rank id)`, the plate rect intersects no actor's head rect but the speaker's tail column.
**Owns** `game/ui/SceneStage.gd` (`say_at`, `head_of`), `game/ui/Widgets.gd` (`speech_plate` tail length), `tests/unit/test_scene_stage.gd`.
**Size** M.
**Wave** 7 — the dialogue-surface pass (with UI-04, UI-07).
**Audit** STAGE-10, COMBAT-02, KIT-02 (Q04).

### UI-21 — Twelve 2x figures on a 340px plateau overlap into one mass; the overhead badges float at four heights
**Status** CONFIRMED; the scale half is Q01/Q02.
**Evidence** `fixture/RaidView.png` (355..700 x 260..400): three ranks of four at ~48px horizontal pitch and ~30px rank pitch with ~90px-tall figures — the back ranks are two-thirds hidden; the class-badge tiles (`RaidView._bar_ids` / `SceneStage.bar_for`, the Q07 default "badge + pips on every figure") land at y=230/240/265/315 for four different figures, so they read as loose chips on the rock, not as labels on people. Concept 2 shows four figures at ~100px pitch.
**Doc** spec 02 §2 (party spacing), spec 09 §4.3 row 5 ("three ranks of four on the plateau"), Q01/Q07 (00-plan §6).
**Fix** (a) Widen the party marks: the plateau in `stage_arena_cave.json` runs ~360px; spread the front rank across it (4 at 84px pitch), stagger ranks by half a pitch and raise the rank pitch to 40px so every head is visible (the reference's density); (b) the overhead badge stack sits at a fixed offset above each figure's head AND the whole stack hides for figures in the back ranks except the acting/struck one (Q07's "safe default" already has that rule for the HP bar — extend it to the badge); (c) if Q01 rules 1x for the cave, (a) is unnecessary. Test: no two actor body rects overlap by more than 25% of the narrower one.
**Owns** `game/assets/scenes/stage_arena_cave.json` (+ dungeon), `game/ui/SceneStage.gd` (`place_party`, `bar_for`), `game/screens/RaidView.gd` (`_bar_ids`), `tests/unit/test_scene_stage.gd`.
**Size** M.
**Wave** 7.
**Audit** COMBAT-01, COMBAT-03, STAGE-04, Q01/Q02/Q07.

### UI-22 — The boss at 1x reads as a different medium from the 2x party, and stands behind a fence
**Status** BLOCKED-designer (Q02); a shippable default exists.
**Evidence** `fixture/RaidView.png` (crop `crops/raid_boss.png`): the Main Boss (~150px, painted density, `marks.boss.scale` 1) beside a party whose single figures are ~90px of 2x pixels — the party is crunchier than its enemy; the boss's lower third is behind the plateau fence and its right-hand tentacle runs under the lantern sprite. Concept 2's boss is ~580px and in front of everything.
**Doc** spec 00 §2.7 row 2; docs/12 §4.1 ("2x reads as chunky"); docs/07 §4.1; Q02.
**Fix (default if unanswered)** Keep 1x (docs/12's warning is canon-adjacent) but move the boss mark forward of the fence (a `stage_arena_cave.json` edit: the mark's y below the fence line, its x clear of the lantern) and give it a contact shadow scaled to its footprint; the party's scale (Q01) is the lever that closes the density gap, not the boss's. If the designer rules "re-author", it is an XL art unit (`gen_boss_anims.lua` derives idle/hit/death from a still — the still would be repainted at ~2x canvas).
**Owns** `game/assets/scenes/stage_arena_cave.json`, `stage_arena_dungeon.json`, `game/ui/SceneStage.gd` (`place_boss` shadow).
**Size** S (default) / XL (re-author).
**Wave** 7 (default); the re-author waits on Q02.
**Audit** PIPE-03, STAGE-01, COMBAT-07.

### UI-23 — The wipe report cuts every joke with an ellipsis and slices its last row
**Status** CONFIRMED — the single biggest dialogue-surface defect.
**Evidence** `fixture/Results.png` "What happened" (crop `crops/res_log.png`): "The boss did the thing the boss does, and Greg was sti…", "Tiny was behind the boss, and behind the boss is wher…", "Greg is now the most interesting person in the room a…" — three of three quips truncated at 100% in a 474px column, and the fourth row sliced through its glyphs at the panel's clip (y≈975). `Results.gd:1180-1183` sets `OVERRUN_TRIM_ELLIPSIS` on the joke Label citing spec 02 §2.1 (a rule measured on the reference's short factual rows); `:1164` the same on the header. The corpus's lines (`data/mistake_lines.json`, M5-COMEDY-03) are one to two sentences — none fits 440px at Type.BODY italic. The player reads the report with the mouse only if they discover the tooltip.
**Doc** docs/13 §11.3 (the mistake and its line are the game's loudest UI), docs/07 §10 (the wipe report is the comedy's primary surface), docs/13 §4.4; spec 02 §2.1 is the conflicting measurement.
**Fix** In the report (not the live log) the quote WRAPS (`autowrap_mode = WORD_SMART`, `LabelQuote`, indent 30) — the post-mortem is a reading surface, docs/13 §11.4 calls it "the page"; the header stays one line but leads with the type (UI-19); the scroll's fold snaps to a whole row (`_snap_fold` pattern); the 52-line count moves to a "Show all" that opens the log in the centre panel at full width if it wants more room. Amend spec 02 §2.1 to say "the LIVE log's rows"; record the reversal as a BL row. Test: with the fixture's raid, no `LabelQuote` in Results ends with "…" and no row rect straddles the clip.
**Owns** `game/screens/Results.gd` (:1080-1200), `art/ref/specs/02-concept2-raid-layout.md` §2.1 (one sentence), `docs/15` (a BL row; W5-DOCS's file — a handoff), `tests/unit/test_results_layout.gd` (new or `test_wipe_sequence.gd`).
**Size** M.
**Wave** 6 — first; it is what the player is meant to laugh at.
**Audit** M5-COMEDY-05, COMBAT-11, COMBAT-22.

### UI-24 — "By raider" has three unlabeled columns; the -12 column is a wall of the same number
**Status** CONFIRMED.
**Evidence** `fixture/Results.png` (795..1160 x 240..530, crop `crops/res_byraider.png`): rows "Cindy  [claw]  4  -12  Fallen" — no header names the columns (mistakes, morale delta, state); every raider's morale delta is -12 (the wipe penalty is flat, docs/05 §8), so the column carries no information twelve times; the claw glyph before the count is the boss-attack log icon, which here means "mistakes".
**Doc** docs/13 §11.4 (the report reconciles the party — "who cost what"), spec 10 §2.
**Fix** A `LabelSmall` header row ("Raider · Mistakes · Morale · State"); the claw replaced by the `log_mistake` glyph; when every delta is equal, print it once in "The mood afterwards" ("-12 each, 130 between them") and drop the column; sort by mistakes descending (it already is) and colour the top row's count DANGER only.
**Owns** `game/screens/Results.gd` (`_by_raider_section` :773, `_by_raider` :809), `tests/unit/test_results_layout.gd` (new).
**Size** S.
**Wave** 6.
**Audit** COMBAT-18, COMBAT-11.

### UI-25 — The Results' left column is a heading and 500px of dimmed cave
**Status** CONFIRMED.
**Evidence** `fixture/Results.png` (0..350 x 90..715): "Raid report / Day 24 · Unknown / • Attempt 1 at E5" then nothing to the strip; the report panel is centred (362..1175) and the right third is bare arena. On Concept 2 the left column is the objective block over the scene and the scene IS the content; here the scene is dimmed to a backdrop and the report floats in the middle. On a clear (`raid-clear/Results_clear.png`) the same.
**Doc** spec 02 §1 (the raid frame), spec 10 §2 (Results on the raid frame — R4), docs/13 §11.4.
**Fix** Either widen the report to the frame (left column becomes the tally, centre the fallen/by-raider, right the loot and mood — the dashboard reading the designer's "wipe report" implies), or keep the page and make the scene under it the settled fight (the fallen figures on the floor via `SceneStage.place_party` in their end state, no dim), so the picture behind the page is the evidence. The second is cheaper and keeps the "page" idea of docs/13 §11.4.
**Owns** `game/screens/Results.gd` (`_scene`, `_layout`), `tests/unit/test_results_layout.gd`.
**Size** M.
**Wave** 8 — after the report's text fixes (UI-23/24) and the party-scale answer.
**Audit** COMBAT-12, COMBAT-16.

### UI-26 — The camp's lantern lights shine THROUGH the hall family's opaque panels
**Status** CONFIRMED.
**Evidence** `fixture/RaiderDetail.png` and `empty/RaiderDetail.png` (crops `crops/detail_backstory.png`, `crops/detail_backstory_empty.png`): a ~190px disc centred at (880,410) inside the Quarters panel — pixel (880,410) = (6,18,25) against the panel's (6,13,28). `SceneStage.gd:2295-2304` builds `PointLight2D` with `BLEND_MODE_ADD` and the default `range_item_cull_mask`, and no panel or Frame node sets `light_mask` (grep: no hit in game/ui or game/screens), so every Control drawn later in the same canvas — the Quarters panel, the sidebar, the strip — is lit by the camp's eleven lanterns wherever one sits under it. The hall's `stage.modulate = dim` (`Guildhall.gd:268`) darkens the plate but not the light.
**Doc** spec 09 §4 (lights are a stage layer), spec 06 §1 (panels are opaque surfaces).
**Fix** Give the stage's lights `range_item_cull_mask = 2` and the stage's own plate/actor/prop CanvasItems `light_mask = 2` (one line in `add_actor`/`_build_layer`), so no Control outside the stage is ever lit; or `light_mask = 0` on `Frame`'s panel hosts. Test: in `test_scene_stage.gd`, every PointLight2D under a loaded stage has cull mask 2 and every non-stage Control in a mounted hall screen has light_mask 0 — and a pixel test through `shot.gd`'s SubViewport is not needed.
**Owns** `game/ui/SceneStage.gd` (lights, `add_actor`, layer builders), `game/ui/Frame.gd` (panel hosts), `tests/unit/test_scene_stage.gd`.
**Size** S.
**Wave** 6 — a one-line cause, visible on four screens.
**Audit** STAGE-04, HALL-02 (Q03 framing) — independent of the ruling.

### UI-27 — "wishlists with the loot module": player copy that names an unbuilt module
**Status** CONFIRMED.
**Evidence** `RaiderDetail.gd:760` and `:773` — the empty Backstory hint reads "Backstories arrive with the Tavern; wishlists with the loot module." (`fixture/RaiderDetail.png` 730..1100 x 505..560). "The loot module" is docs/05 §12 Q6's production term; a player has no loot module. The Quarters line "50 base -5 Common +0 Guildhall +0 furnishings = 45 baseline" (`:` ~700) is an equation in the sim's vocabulary on the same panel.
**Doc** docs/13 §4.4 (voice: the guild's own paperwork, never the developer's), docs/05 §12 Q6 (wishlists optional, after the loop ships).
**Fix** "Nothing is written down about them yet. Wants nothing in particular — yet." (one sentence; the second arrives with the feature); the Quarters arithmetic becomes "Settles at 45 — Common, no furnishings." with the breakdown as the tooltip. Also audit every `empty_state`/`_note` string in `game/screens/*.gd` for the words module, build, canon, fixture, test: a lint (`tools/lint_copy.sh`) that greps `Label`/`Button` string literals for that list.
**Owns** `game/screens/RaiderDetail.gd` (:700-775), `tools/lint_copy.sh` (new), `tests/unit/test_raider_detail.gd`.
**Size** S.
**Wave** 6 — with UI-01 (same lint).
**Audit** HALL-23, HALL-26.

### UI-28 — The Options screen ships four dead rows and eight lines of build-status copy
**Status** CONFIRMED.
**Evidence** `fixture/Settings.png`: "Options — 13 of 17 live in this build" (`Settings.gd:290`); rows Prose font swap / V-sync / Language / Controller glyphs are locked with "The type pass ships the second family." (:95), "Display options arrive with the export build." (:102), "One language so far." (:112), "Gamepad support is not in this build." (:115); the audio rows say "The bus is here and waiting; no music is written yet." (:106) and "…nothing is voiced yet." (:110); the sidebar says "Nothing here is a build flag; those live in data/tuning." (:617). This is the loop's status board rendered as the player's options.
**Doc** docs/13 §9 (Settings: only live options; a disabled row says WHY in the player's terms), docs/13 §4.4; Q16 (`prose_font_swap`'s meaning) and 00-plan §6 Q14 (control idiom).
**Fix** Before ship: (a) delete rows that will not exist at v1 (Prose font swap unless Q16 says otherwise; Controller glyphs; Language — one language ships silently); (b) V-sync becomes live (a `DisplayServer.window_set_vsync_mode` call is S) or is removed; (c) the audio notes become player sentences ("Music." / "The scribe's voice.") or the rows hide until the bus has content (M6-AUD owns the content; the ROW is mine); (d) the "N of M live" subtitle and the "build flag" sentence go. A test pins that no `ROWS` entry has a `reason` containing "build", "pass", "export" or "so far".
**Owns** `game/screens/Settings.gd` (`ROWS` :77-120, :290, :617), `tests/unit/test_settings.gd`, `tests/unit/test_options_layout.gd`.
**Size** S (copy + row removal) / M (with V-sync live).
**Wave** 9 — last, once audio and Q16 have settled what the rows are.
**Audit** HALL-15, HALL-17, KIT-20, M6-AUD-02 (adjacent).

### UI-29 — Settings' panel ends 125px above the sidebar's bottom, over a strip of waterfall
**Status** CONFIRMED (minor).
**Evidence** `fixture/Settings.png`: the options panel spans y 85..880, the sidebar 85..1000, the camp plate shows through 880..1000 at the bottom of the centre column with the frame's bottom rule at 1005 under it. Every other framed screen's centre panel meets the shared rule. The seventeen rows fit at 100; at 150 (`text150/Settings.png`) the panel scrolls and still ends at 880.
**Doc** spec 01 §1 (the frame's rects), spec 10 §3 (Settings on the tall frame).
**Fix** Size the options panel to the sidebar's height (both are children of the tall Frame's hosts — set the centre host's `size.y` to the sidebar's) so the rule under both is one line; the extra 120px absorbs the 150% scroll.
**Owns** `game/screens/Settings.gd` (`_layout`), `game/ui/Frame.gd` (tall preset), `tests/unit/test_options_layout.gd`.
**Size** S.
**Wave** 8.
**Audit** HALL-16.

### UI-30 — At 150% the rail's "Adventure's Board" is a 14px label between 24px neighbours
**Status** CONFIRMED.
**Evidence** `text150/Guildhall.png` and every `text150/*.png` rail (y=351): "Adventure's Board" renders at ~14px while Camp/Tavern/Roster/Market/Options are ~24px. `Frame.gd:507-513` steps the size down until the string fits `RAIL_W - RAIL_LABEL_X` (145px) with the floor `RAIL_LABEL_FLOOR := Type.NAV - 2` (:57) — an unscaled floor, so at 150 the label falls the whole way. At 125 it is ~18px. The canon name is not shortenable (spec 00 §2.6, the test pins the spelling).
**Doc** docs/13 §4.4, spec 03 §2 (rail pitch), M6-A11Y-05 (text_scale's layout half — W5-SCALE's file list does not include Frame.gd).
**Fix** Scale the floor (`Type.at(Type.NAV - 2, pct)`) and let the label wrap to two lines inside the 56px item when it still does not fit (`autowrap_mode = WORD`, `RAIL_ITEM_H` at 150 is 84 — two lines of 24 fit); or widen the rail at 150 (`RAIL_W` scaled by the same ladder; the scene host gives up the difference — spec 11's wide-safe rule already lets the rail float). Test in `test_text_scale_layout.gd`: every RailLabel's font size >= Type.at(NAV-2, pct).
**Owns** `game/ui/Frame.gd` (:51-60, :474-513), `tests/unit/test_text_scale_layout.gd` (W5-SCALE's — extend after the wave).
**Size** S.
**Wave** 6 — with the 150% leftovers W5-SCALE hands off.
**Audit** M6-A11Y-05, KIT-04, TOWN-04.

### UI-31 — At 125/150 the card's class word trims to "Shama" / "Warri"
**Status** CONFIRMED (W5-KIT3 "Left" item; not in any unit's contract).
**Evidence** `text150/Guildhall.png` Rhona's card (700..900 x 245..270): "Shama" beside the class glyph; `build/plan/report-W5-KIT3.md` "Left" bullet 2 names it (KIT-19's `OVERRUN_TRIM_ELLIPSIS` on the ClassRow Label, an 85px names column). A class name cut is what docs/13 §4.4 forbids.
**Doc** docs/13 §4.4, §8.1.
**Fix** The same ladder `Cards.fit_band_line` (W5-KIT3) applies to the ClassRow Label: the variation's size, then CLASS-2, then the glyph alone with the word as tooltip is NOT acceptable — so the third rung is a wider names column (the portrait column can give 10px at 150; the card is 215/262 wide and the portrait 2x is 94). Test: the ten class names whole on both card widths at 100/125/150.
**Owns** `game/ui/Cards.gd` (`card`, ClassRow), `tests/unit/test_kit3.gd`.
**Size** S.
**Wave** 6.
**Audit** KIT-19, HALL-03.

### UI-32 — 150% is not shippable on five screens after W5-SCALE's contract is met
**Status** CONFIRMED (against the 10:53 sheets; W5-SCALE's owned fixes — Guildhall chart, Tavern seat card, Completion CTA, Settings CTRL_H — are excluded here; re-check at the wave-5 close).
**Evidence** `text150/*.png`:
- RaidView (`text150/RaidView.png`): the header "E5 — Raid 1 — Enco…" (y=115) trims; the log's MISTAKE row is "Greg (Rogue) — Severe …" and the quote "…and …" — the comedy is gone at 150 (UI-19 at 100 becomes total here); "The report" button text fills its plate to the rim.
- Results (`text150/Results.png`): the report scrolls in two columns with the fallen grid sliced at the fold (y≈690); "What happened" rows are "[R00] Raid 1 — Encounter 5 begi…", "…Severe · Dr…" — every row unreadable; the strip cards clip their gear row at y=1000.
- RaidPrep (`text150/RaidPrep.png`): the Verdict box's "mistakes" word is cut behind the Depart plate (1180..1480 x 470..545); "Raid 1 — Encou…" in the sidebar; the comp panel's contributor rows sliced at the fold ("Spoof Mage Annoyed" y≈680); the strip's "Bench" buttons half off-screen (y 1000..1024).
- Market (`text150/Market.png`, sheet 2): the worn grid shows one row and the tops of a second; "Sell all nobody can wear — 0 G (12480 → 12480)" wraps into the reason.
- RaiderDetail (`text150/RaiderDetail.png`, sheet 2): the kit's gear list is cut at "Trinket — …"; the six small slots crowd the weapon slot; "no weapon" drops to a second row.
- Every framed screen: the rail label (UI-30) and the card class word (UI-31).
**Doc** docs/13 §13.1 (text scale 100/125/150 is a shipped option), M6-A11Y-05.
**Fix** Per screen, in this order: RaidView (the header gets `autowrap` in its 350px column; the log at 150 drops the blot column and wraps the quote — UI-19's rule), Results (at 150 the report becomes ONE column with the strip hidden behind a "Party" toggle — a layout switch keyed off `Theme_.scale_of(self) >= 150`), RaidPrep (the verdict figure at `Type.at(FIGURE_XL)` only when it fits, else FIGURE; the strip card's action band folds into the card's "Manage" pattern), Market (two name lines max + tooltip), RaiderDetail (the doll's small slots on two rows of three under the weapon at 150). Each lands in `test_text_scale_layout.gd`'s allow-list as "fixed" — the list must be EMPTY for every route at every scale before ship.
**Owns** `game/screens/RaidView.gd`, `Results.gd`, `RaidPrep.gd`, `Market.gd`, `RaiderDetail.gd`, `tests/unit/test_text_scale_layout.gd`.
**Size** L (one unit per two screens; RaidView+Results is the M-heavy pair).
**Wave** 6 (RaidView, Results) and 7 (RaidPrep, Market, RaiderDetail).
**Audit** M6-A11Y-05, G15.

### UI-33 — Focus enters Results on the strip's "<" pager and RaidView on the fast-forward chevron
**Status** CONFIRMED.
**Evidence** `focus/Results.png` (crop `crops/focus_results.png`): the 2px ring sits on the party strip's left pager (x≈130,y≈870); `focus/RaidView.png`: on the ">>" speed button (bottom-left). `Frame.focus_entry` (`Frame.gd:804-809`) walks `FOCUS_REGIONS` ["rail","header","scene","sidebar","strip"] and returns the first focusable; no screen defines a `default_focus()` hook (grep: none in game/screens). docs/13 §11.4 names "Try again" as the wipe page's default focus (`RaidView.gd:1910` cites it for the RaidView wipe overlay; Results has no equivalent).
**Doc** docs/13 §11.4, §13.2; 00-plan Q10 (Town entry rail-first vs hotspot-first — a different question; this one has a doc answer).
**Fix** `Results.default_focus()` returns "Back to the board" on a wipe (or "Return to town" when attempts are limited by Q-53) and the loot "Suggested" button on a clear; `RaidView.default_focus()` returns Pause (the one control a watching player needs); the Town/Board/etc. keep the rail. Test in `a11y_smoke.gd`: the entry control's text for those two routes.
**Owns** `game/screens/Results.gd`, `game/screens/RaidView.gd`, `tests/unit/a11y_smoke.gd`.
**Size** S.
**Wave** 6.
**Audit** M6-A11Y-02, RULES-06.

### UI-34 — Damage numbers on one target overlap (14px stagger under a 28px glyph) and land 60px from the boss
**Status** CONFIRMED.
**Evidence** `raid-advanced/RaidView_10.png` (crops `crops/adv_party.png`, `crops/adv_bossnum.png`): two "-30" on the same raider half-overlap — `SceneStage.number_at` (`SceneStage.gd:1293-1311`) stacks by `NUMBER_STAGGER := 14.0` (:155) while the label is Type.DAMAGE 28 (~34px tall); two "-4" on the boss render in `Palette.TEXT_BODY` grey at (1200,345), ~60px left of and above the boss's head — `RaidView.gd:2322-2323` overrides the DANGER tone to TEXT_BODY for any hit whose target is the boss (empty `target_id`), so the party's own damage is the least visible thing on the floor and lands off the boss's body. Concept 2 shows "-317" in white-hot on the raider hit and "-842" in orange on the boss.
**Doc** spec 02 §5.2 (damage numbers: raider-dealt in the warm crit tone, boss-dealt in DANGER), docs/13 §11.2.
**Fix** `NUMBER_STAGGER` = the label's `sz.y + 4` (computed per label, not a constant); the boss's `head_of` returns the top of the AnimatedSprite2D's frame rect (it is returning the 1x still's anchor); raider-dealt damage on the boss uses `LabelDamageDealt` (a warm CTA_TOP tone at Type.DAMAGE) so the two directions read as two colours. Test: two `number_at` calls on one sprite give rects that do not intersect; `head_of(boss)` lies inside the boss's frame rect's top 10px.
**Owns** `game/ui/SceneStage.gd` (`number_at`, `head_of` for AnimatedSprite2D), `game/ui/Theme.gd` (one Label variation), `game/screens/RaidView.gd` (:2300-2330 the kind switch), `tests/unit/test_scene_stage.gd`.
**Size** S.
**Wave** 7.
**Audit** M6-JUICE-05 (done — this is its polish), COMBAT-04, PIPE-01.

### UI-35 — The live log slices its top row as it scrolls and the speaker's plate drifts over the header
**Status** CONFIRMED.
**Evidence** `raid-advanced/RaidView_10.png`: the log's first visible row "Main Boss hits Bork for 30." is cut through its glyphs at y=745 (the panel's top clip after auto-scroll); the joke plate "Nobody asked Tiny to go first…" (275..480 x 160..240) overlaps the header block's bottom-right corner (the header ends at x=350, y=195). Ten lines in; every subsequent line scrolls the same way.
**Doc** spec 02 §2.1 (the log's rows), docs/13 §11.2.
**Fix** Scroll the log by whole rows (`ScrollContainer.scroll_vertical` snapped to the row pitch `LOG_ROW_PITCH` — the rows are fixed-pitch already) so the fold never slices; the plate keep-out (UI-20) includes the header rect and the boss plate rect.
**Owns** `game/screens/RaidView.gd` (`_append_line`, the log scroll), `game/ui/SceneStage.gd` (`say_at` keep-out), `tests/unit/test_log_player.gd`.
**Size** S.
**Wave** 6 (the log) / 7 (the plate, with UI-20).
**Audit** COMBAT-02, COMBAT-08.

### UI-36 — The clear branch has no stamp, no crimson commit and a bare "Cleared." heading
**Status** CONFIRMED.
**Evidence** `raid-clear/Results_clear.png`: "Cleared." is a plain section title where the wipe gets the pressed "It's a wipe!" stamp; the loot act "Suggested — give everything" is a secondary plate (804..1148 x 218..246), so the page's ONE commit (distribute the drop) has no crimson; the "+8" morale column repeats four times (UI-24). docs/13 §7's StampBadge word list includes CLEARED. The Records wall (`tabs/Guildhall_Records`) has a "First Blood" achievement; nothing on the clear page says the guild just did something.
**Doc** docs/13 §7 (CLEARED stamp), §11.4 (the wipe page's tone — the clear is its mirror: a filed report with a stamp), spec 06 §4 (the crimson CTA is the commit).
**Fix** `Widgets.stamp("CLEARED", Palette.READY_GOLD)` pressed over the heading with the same 180ms press (reduced_motion holds it); the loot's suggested split as the crimson CTA ("Give as suggested — 1 drop") with "Sell all unusable" beside it; the wax seal in READY_GOLD in the corner; the payout line "Payout 4 G" at Type.FIGURE. Test: `test_wipe_sequence.gd` gains the clear twin (stamp text "CLEARED", CTA variation ButtonCta).
**Owns** `game/screens/Results.gd` (`_clear_page`), `game/ui/Widgets.gd` (stamp tone param exists), `tests/unit/test_wipe_sequence.gd`.
**Size** S.
**Wave** 7.
**Audit** COMBAT-20 (Q12b adjacent), COMBAT-22, M6-JUICE-03 (its clear twin).

### UI-37 — The wipe page has no "Try again"; the doc's default-focused button is missing
**Status** BLOCKED-designer (Q-53) at its recommended default — which says build it.
**Evidence** `raid-advanced/RaidView_all.png` and `fixture/Results.png`: the buttons are "Back to the board" and "Return to town"; docs/13 §11.4's row t=2,400 is "`Try again` (paper) and `Return to town` (wax) … `Try again` is left and default-focused"; `RaidView.gd:1910` quotes the row and does not build it. docs/15 Q-53's recommended default is "Unlimited attempts with a per-attempt economic cost; resume from the stored seed" — under that default "Try again" is legal and is the wipe's natural next act (re-chalk and depart from prep).
**Doc** docs/13 §11.4; docs/15 Q-53 (recommended default), docs/01 §6 (attempt cost).
**Fix** "Try again" routes to RaidPrep with the same encounter pinned (the plan is still in `GameState`), lit as the default focus; behind `Results.TRY_AGAIN` (default true, the Q-53 default) so a "limited attempts" ruling flips it to hidden. The cost text under it: "costs a day and the provisions you chalk" (docs/01's ledger).
**Owns** `game/screens/Results.gd`, `game/screens/RaidView.gd` (the wipe overlay's buttons), `game/core/ScreenRouter.gd` (a route with a pinned plan — exists for Board→Prep), `tests/unit/test_wipe_sequence.gd`, `a11y_smoke.gd`.
**Size** S.
**Wave** 7.
**Audit** COMBAT-14/Q12c adjacent, M6-JUICE-03.

### UI-38 — Fallen raiders stand as grey statues; nobody lies down
**Status** CONFIRMED.
**Evidence** `raid-advanced/RaidView_all.png` (355..700 x 260..400): twelve greyed figures upright at the wipe, each with a skull badge and a row of red claw blots beside it; `SceneStage.set_fallen` (M4B-ACT-05: "a fallen raider greys and stops breathing") has no pose. Concept 2 has a raider face-down on the flagstones; `tools/aseprite/gen_boss_anims.lua` derives a death strip for bosses but `tools/art/gen_actors.py` writes only idle/breath/walk for the party.
**Doc** spec 09 §4.3 row 5, docs/13 §11.4 ("every remaining animation halts on frame" — halting is not the same as standing), docs/12 §5.3 (poses).
**Fix** A `down` frame per actor family from `gen_actors.py` (the idle frame rotated 90° onto its back with the 2-frame breath removed, feet toward the boss, plus the contact shadow stretched to the body length — derived art, no new painting), shown by `set_fallen`; the skull badge stays, the claw-blot row moves to the card (it is already there) so the floor loses twelve tally rows.
**Owns** `tools/art/gen_actors.py`, `game/assets/actors/*` (regenerated), `game/ui/SceneStage.gd` (`set_fallen`), `tests/unit/test_scene_stage.gd`, `tests/unit/test_art_sources.gd`.
**Size** M.
**Wave** 8 — art derivation; after Q01's scale is signed off so the frames are cut once.
**Audit** COMBAT-03, COMBAT-07, STAGE-09 (fumble flavours — Q18).

### UI-39 — m4t-04 is half done: the Market's shelves carry icons, the prep chalkboard and the Results rally row do not
**Status** CONFIRMED (audit row `m4t-04` "not-started" is PARTLY REFUTED).
**Evidence** `tabs/Market_Buy.png` (sheet, 130..180 x 690..870): every SKU row shows its icon — `Market.gd:827` `Icons.at("item", sku_id)`; `RaidPrep.gd:566-574` `_provision_button` builds a bare `Widgets.button("%s  %d/%d")` with no icon (the fixture's `fixture/RaidPrep.png` shows the empty cupboard; with stock the buttons are text-only); `Results.gd:682-697`'s rally-flask row likewise. The audit's step (1) `Cards.consumable_icon` does not exist because the grid door `Icons.at("item", …)` replaced it — the entry predates W1-ICONS.
**Doc** docs/11 §7 (provisions on the chalkboard), spec 10 §2 R5.
**Fix** `b.icon = Icons.at("item", sku_id)` with `icon_alignment = LEFT` and `expand_icon = false` on the prep button (the text stays verbatim — a test reads it), the same slot on the Results rally row; update `m4t-04`'s remaining_work to the two sites left and close it when they land. Fixture: `--fixture` gives the guild two of each consumable so the chalkboard is shot with stock (UI-15).
**Owns** `game/screens/RaidPrep.gd` (:566-585), `game/screens/Results.gd` (:682-697), `tools/fixture_reference.gd`, `tests/unit/test_prep_layout.gd`, `build/plan/audit.json` (row m4t-04).
**Size** S.
**Wave** 6.
**Audit** m4t-04 (closes), m4t-03 (done).

### UI-40 — The Facilities tab's "Next" level has no picture; only level 1's tent exists as a crop
**Status** CONFIRMED (audit `m4t-10` partial — still true).
**Evidence** `tabs/Guildhall_Facilities.png` (sheet 580..760 x 95..160): the sidebar shows one thumbnail (the camp's big tent, a live crop of `stage_camp`'s plate) under "The Guildhall / Leaking Guildhall / Level 1 of 4"; "Next: Repaired Guildhall — 150 G / Roof patched, door replaced, 3 lit windows" is a sentence. The four-level ladder (Leaking / Repaired / Proper / Renowned) is listed as text. `m4t-10`'s remaining_work names a `tools/art/gen_facility_thumbs.py` deriving four 337x104 thumbs from the (now deleted) guildhall_plate crop; the hall is the CAMP now (BL-78), so the base is the camp tent at `Guildhall.FRAMINGS.tight`.
**Doc** docs/02 §9.1 (visible town change per rank), docs/11 §8 (facility levels), Q18/HALL-18 (what the guildhall IS on the camp plate — designer).
**Fix (default)** Derive four tent states from the camp plate's big tent through `tools/art/patch_plate.py` (W4-LIFE's tool): L1 as is; L2 a patched roof (lighter canvas, a lantern lit); L3 a banner and a brazier; L4 a stone wall band and two guard figures from the actor strips — the audit's recipe on the new base — shown as the "Next" thumbnail in the sidebar AND applied to the live camp scene (a `facility_level` key on `stage_camp.json`'s tent prop, so the town itself changes with the level — docs/02 §9's mechanism). Designer sign-off on the four looks is HALL-18; the default ships derived art rather than nothing.
**Owns** `tools/art/gen_facility_thumbs.py` (new) or `patch_plate.py`, `game/assets/bg/facility_l1..l4.png`, `game/screens/Facilities.gd` (sidebar), `game/ui/SceneStage.gd` (tent prop by level), `game/assets/scenes/stage_camp.json`, `tests/unit/test_art_sources.gd`.
**Size** M.
**Wave** 8.
**Audit** m4t-10, M3-LOOP-05/06 (the mechanism), HALL-18 (Q18).

### UI-41 — Emotes are 16px pictograms in a 1x frame over 2x figures; "sweat" reads as a blue blob
**Status** CONFIRMED (BUILD_STATE 'Next task' (4): "the emote glyphs still pictograms").
**Evidence** `fixture/Town.png` (612,250) and `fixture/AdventureBoard.png` (848,312): the "sweat" emote is a 16px `emote_sweat.png` (grid, `crops/icons_sheet.png` row 2 col 1) in the 1x `emote_frame.png` over 2x camp figures — the drop is ~6px of blue and the frame is smaller than a figure's head; `Widgets.speech_bubble` (`Widgets.gd:1574-1581`) sizes the bubble to the frame texture with no scene scale. The ten keys (anger/dots/exclaim/heart/mug/note/question/skull/sweat/zzz) exist; Q04's vocabulary mapping (which band or event drives which) is the designer half.
**Doc** spec 07 §3 (emote bubbles as sheet assets), 00-plan Q04, docs/12 §5.2.
**Fix (default)** Author the emote glyphs at 24px in `gen_icons.lua` (a second cell size, like the 32px items) and scale the bubble frame by the scene's `figure_scale` (2x on the camp → a 32px frame + 24px glyph — the size of a 2x figure's head); keep the 16px set for 1x scenes. The mapping default: dots = idle, zzz = resting, mug = tavern, sweat = at-risk raider present, skull = after a wipe (the JSON's "wipe" mood already exists), heart = morale >= 80 in the roster, question = a locked building nearby, anger = morale < 30, note = market, exclaim = a new notice on the board — recorded as a 🔷 PROPOSED table in spec 07.
**Owns** `tools/aseprite/gen_icons.lua`, `game/assets/ui/icons/grid/emote_*.png`, `game/ui/Widgets.gd` (`speech_bubble` scale), `game/ui/SceneStage.gd` (bubble scale by `figure_scale`; mood → key), `art/ref/specs/07-assets-sheet-a.md` (the table), `tests/unit/test_icons.gd`.
**Size** M.
**Wave** 8.
**Audit** TOWN-26, PIPE-05, STAGE-10 (Q04).

### UI-42 — M4B-VFX-01's "airship" is owed against a plate that no longer exists
**Status** REFUTED (the airship half); the rest of the row is done.
**Evidence** The airship lived on Concept 3's camp crop (spec 09 §2.1 C3-CAMP "a moored airship at right (x 1000–1160, y 560–700)"); the shipping plate is the designer's bare `game/assets/bg/stage_camp.png` (spec 09 §3, W5-TOOLS's rewrite), which has no airship — `fixture/Town.png`, `fixture/Completion.png`, `fixture/LoadSave.png` show a hillside camp with a waterfall and no harbour; `stage_town.json` (the aerial) has `flyers` (gulls), `rotor` (the windmill), `scroll` and `shimmer` and no airship prop either. `M4B-VFX-01.remaining_work` still says "STILL OWED, art not code: spec 09 §5 row 8's airship". Row 3's "rotating core" waits on a scene with a core (none ships in Tier 1 — the dungeon has none).
**Doc** spec 09 §5 row 8 (obsolete), BUILD_STATE 'Next task' (4) "M4B-VFX-01's airship".
**Fix** Close `M4B-VFX-01` with the layer list W4-LIFE shipped (`paths`, `rotor`, `flyers`, `banner`, `flame_lantern`, `shimmer`, `scroll`) and a note that the airship row was retired with the crop; strike the BUILD_STATE line. Nothing to draw.
**Owns** `build/plan/audit.json` (row M4B-VFX-01), `BUILD_STATE.md` (one line), `art/ref/specs/09-background-plates.md` §5 row 8 (mark retired).
**Size** S.
**Wave** 6 (records).
**Audit** M4B-VFX-01 (closes), TOWN-27, STAGE-14.

### UI-43 — m4t-12 (the hall living scene) is done under another name
**Status** REFUTED (as written) — the hall family plays `stage_camp` with its actors, walkers, lights and speech.
**Evidence** `m4t-12.remaining_work` asks the four hall screens to replace their bare TextureRect with `SceneStage.load("guildhall")`; `guildhall.json` and `guildhall_plate.png` were deleted (W2-STAGE2, M4B-CONV-03 note) and `Guildhall.bare_stage(self, CAMP_SCENE)` (`Guildhall.gd:223-238`) mounts the camp stage under Guildhall/Roster/Facilities, RaiderDetail (`RaiderDetail.gd:160-164`) and LoadSave; Settings inherits it (`Settings.STAGE_FOR`). `fixture/LoadSave.png` shows the fire, twelve figures and a walker on the bridge behind the slots panel. The only thing `bare_stage` strips is the bubbles and the speech (`:230-231`) — deliberate under a dimmed panel.
**Doc** BL-78, spec 00 §2.7 (HALL_FRAMING), 00-plan Q03.
**Fix** Close `m4t-12` citing the code above; leave the Q03 framing switch as the open half.
**Owns** `build/plan/audit.json` (row m4t-12).
**Size** S.
**Wave** 6 (records).
**Audit** m4t-12 (closes), HALL-02, TOWN-14.

### UI-44 — M6-A11Y-07 (the hue-only log badge) is done in the tree and the row is stale
**Status** REFUTED (row `M6-A11Y-07` "not-started").
**Evidence** `RaidView.gd:2266-2281` `_log_kind(e)` types every account line and `Widgets.log_row` (`Widgets.gd:1375-1392`) draws `Icons.at("log", kind)` — the grid's 22px glyphs (`log_mistake` a red face, `log_heal` a green cross, `log_raider_attack` a sword, `log_boss_attack` a claw, `log_mechanic` an eye, `log_phase` an hourglass, `log_system` a scroll; `crops/icons_sheet.png` row 3-4) — with `Badge.gd:96/169`'s `glyph_for_kind` + `draw_char` as the a11y fallback, exactly option (b) of the row. `fixture/RaidView.png`'s log shows the glyphs. Greyscale: the seven glyphs differ in shape.
**Doc** docs/13 §13 (never colour alone), §8.3.
**Fix** Close the row citing W1-ICONS + W3-KIT2 + W2-RAIDVIEW; add the greyscale assertion the row asked for to `test_a11y_legibility.gd` if it is not there (grep `log_` in that file first).
**Owns** `build/plan/audit.json` (row M6-A11Y-07), `tests/unit/test_a11y_legibility.gd`.
**Size** S.
**Wave** 6 (records).
**Audit** M6-A11Y-07 (closes), COMBAT-06, KIT-07.

### UI-45 — M6-JUICE-07's perf test exists as a WARN-only stage; the row is half-stale
**Status** CONFIRMED (partly stale).
**Evidence** `tools/perf_probe.gd` runs as `verify.sh` stage 8 (`verify.sh:255-272`, WARN-only) and prints MOUNT/frame per screen — BUILD_STATE 'Next task' (1) quotes its numbers (90-270 ms on 12 of 14 screens); the row's `tests/unit/test_latency.gd` with a 3x-budget assert does not exist (`ls tests/unit | grep latency` is empty); W5-MOUNT (`_w5_args.json`) is bringing mount under 140 ms right now.
**Doc** docs/13 §12.1.
**Fix** After W5-MOUNT lands: promote the probe's WARN to a FAIL at 3x budget (the row's "generous multiple") and add the roster/market sort timing (< 100 ms on a 40-raider roster — the case docs/14 §11 item 4 warns about; the probe measures mount only). Close the row on that commit.
**Owns** `tools/perf_probe.gd`, `tools/verify.sh` (stage 8 threshold), `tests/unit/test_perf_mount.gd` (W5-MOUNT's new file — extend after the wave).
**Size** S.
**Wave** 9 — once the mount numbers are stable.
**Audit** M6-JUICE-07, RULES-15.

### UI-46 — The two motion rulings still block their beats: the 110 ms dissolve (Q09) and the wipe's t=1,800 slide
**Status** BLOCKED-designer (Q09) — a shippable default exists: no transition.
**Evidence** `ScreenRouter.gd` mounts screens with no transition (the docstring's "never will"); docs/13 §11.4 row t=1,800 (the post-mortem slides out from under the ledger) is unbuilt because it is a slide (`M6-JUICE-03` note); `M6-JUICE-02` names the switch shape (`TRANSITION_MS`, default 0). `M6-JUICE-04` ("screen shake on wipes" in BACKLOG:168) is a contradiction with docs/13 §11.4 the loop must not build — the strike needs a person's nod.
**Doc** docs/13 §2.3 M5 ("the desk does not move"), §12.2 motion table, §11.4; 00-plan Q09.
**Fix (default if unanswered)** Ship with `TRANSITION_MS = 0` and no slide: the desk does not move is the doc's own material rule and the references show no transition (spec 00 §1 row 4 "Kept"). Land the switch anyway (S) so a "yes" is a constant flip, and strike the screen-shake line from BACKLOG with the docs/13 citation. What it costs if never answered: nothing visible — screens cut; the wipe's page appears in place of the log (already how `_run_wipe_sequence` does it).
**Owns** `game/core/ScreenRouter.gd` (`TRANSITION_MS`, `_load_into_host`), `BACKLOG.md:168`, `docs/15` (a Q row — W5-DOCS's file; handoff), `tests/unit/test_screens.gd` (the router pins live there).
**Size** S.
**Wave** 9.
**Audit** M6-JUICE-02, M6-JUICE-04, RULES-03.

### UI-47 — The CVD ramp is unreachable: `colourblind_safe` is not a setting
**Status** BLOCKED-designer (Q16) at a shippable default: add the row, default off.
**Evidence** `Palette.cvd_safe()` (`Palette.gd:272-282`) returns false unless `GameSettings.DEFAULTS` has `colourblind_safe`; `GameSettings.gd` and `Settings.ROWS` have no such key (grep: only Palette.gd names it), so `band_color_cvd` never draws. BUILD_STATE HANDOFF ("a CVD switch") overstates it — REFUTED as a shipped switch. docs/13 §8.3 promises a ΔL* ramp; the ten hexes are in `Palette.band_color_cvd`.
**Doc** docs/13 §8.3, §13; 00-plan Q16 (a player option vs the only ramp).
**Fix (default)** Add `colourblind_safe` (bool, off) to `GameSettings.DEFAULTS` and one Settings row "Colour-safe morale — the morale ramp uses blue/orange and lightness, not red/green."; every morale colour site already routes through `Palette.morale_color(who, value)`. If Q16 rules "the only ramp", the row is deleted and the default flips — S either way. Cost if unanswered: a red/green-blind player cannot read the roster's colour channel — the state word and glyph still carry it (canon §8.1), so it is a legibility loss, not a blocker.
**Owns** `game/core/GameSettings.gd`, `game/screens/Settings.gd` (ROWS), `tests/unit/test_settings.gd`, `tests/unit/test_a11y_legibility.gd`, `BUILD_STATE.md` (HANDOFF line).
**Size** S.
**Wave** 6.
**Audit** M6-A11Y-06, RULES-09, CRITIC-G10.

### UI-48 — The ending's camp says "I think I'm ready for a real raid this time!"; the credits block is a placeholder sentence
**Status** CONFIRMED (the lines) / BLOCKED-designer (the names, M5-END-4 / Q-21).
**Evidence** `fixture/Completion.png`: the speech plate reads the camp's generic line 0; `Completion.gd:194-205` `_camp_speaks` feeds the roster's backstory bullets and falls back to `stage_camp.json`'s seven lines when the roster has none — Common recruits have no backstory (docs/03; `RaiderDetail.gd:760` says so), so most guilds reach the ending with the fallback the code's own comment calls "the wrong ones". The credits column prints "The credits are not written yet. Who this game credits — … recorded as docs/15 Q-21 and audit M5-END-4." (`Completion.gd:104`, `data/credits.json` deliberately empty). "Gold in the strongbox 12480 G" lacks the header's thousands separator.
**Doc** docs/13 §9.5 (S17), docs/10 §13; docs/15 Q-21, BL-73.
**Fix** (a) An `ending` line set in `stage_camp.json` (`"speech_sets": {"ending": [...]}`, 8 lines in the corpus voice: "So that was the last one." / "Do we still get paid?" …) chosen by `set_lines(stage.lines_for("ending"))`; Town keeps the default set. (b) The credits block's shippable default without a person: the DERIVABLE attributions only — engine (Godot, MIT), the two font families (`game/assets/fonts/`: Fira Sans and Grenze Gotisch, both OFL — `OFL-FiraSans.txt` / `OFL-GrenzeGotisch.txt` already sit beside them and must be in the export's PCK or beside the .exe) and the tools; names stay blank and the placeholder sentence becomes "Credits" over that list. The person supplies names (M5-END-4) — the screen must not ship a sentence that cites an audit id. (c) `Type.gold()` for the strongbox figure.
**Owns** `game/assets/scenes/stage_camp.json`, `game/ui/SceneStage.gd` (`lines_for`), `game/screens/Completion.gd`, `data/credits.json` (the derivable rows), `tools/export_build.sh` (copy the two OFL files beside the .exe), `tests/unit/test_completion.gd`.
**Size** S (a, c) / S (b, minus the names).
**Wave** 9 — the ending is unreachable in play until tier 5 is named (BL-69); polish it last but before ship.
**Audit** M5-END-2, M5-END-4, STAGE-13.

### UI-49 — Every two-line tooltip in play is a 180x571 plate (found by W5-TOOLS's `--hover`)
**Status** CONFIRMED (by another unit's instrument; the fix is a pending handoff).
**Evidence** `build/shots/w5tools/RaiderDetail_hover.png` (crop `crops/tooltip_hover.png`): "Head — Worn Iron Cap / worth 1 G" on a plate that runs to y=748; `build/plan/handoff-W5-TOOLS.md` §2 has the cause (Godot sizes the tooltip Window from `get_contents_minimum_size()` before layout; a never-laid-out autowrap Label is 0 wide and reports one grapheme per line) and the three-line fix at `Widgets.gd:381` (`build_tooltip`). No test reads the Window, so it has been shipping since W3-KIT2's TooltipHost.
**Doc** docs/13 §7 (tooltips carry the slot's item name and worth), spec 06 §5.
**Fix** Apply the handoff; add the assertion the handoff describes to `test_widgets_kit.gd` (a PopupPanel given `build_tooltip()`'s VBox reports `get_contents_minimum_size().y < 80`); shoot `RaiderDetail --fixture --hover=584,167` after and paste it in the report. Then sweep every `tooltip_text` site the same way (the Tavern's gear cells, the Market's slots, the Board's rewards, the RaidView cards' slots) with one `--hover` each on the `hover` sheet W5-TOOLS's `shot_all.sh` can now shoot.
**Owns** `game/ui/Widgets.gd` (:370-390), `tests/unit/test_widgets_kit.gd`, `tools/shot_all.sh` (a `hover` sheet).
**Size** S.
**Wave** 5 close (the handoff) / 6 (the sweep and the sheet).
**Audit** KIT-22, G06.

### UI-50 — The Guildhall ships a permanently disabled "Raid Group" tab
**Status** BLOCKED-designer (Q18 / HALL-21) — shippable default: retire it.
**Evidence** `fixture/Guildhall.png` tab row (230..1120 x 100..140): "Raid Group" greyed with the reason "Chalk tonight's twelve from the Adventure's Board." — `Guildhall.gd:48` TABS entry with a static `reason`; there is no branch in which it opens (the party is chalked on RaidPrep, docs/13 OQ-4's reversal). A control that can never enable is not "disabled with a reason", it is a dead menu item; on `text150/Guildhall.png` its reason line takes a second row and pushes the roster down 24px.
**Doc** docs/13 §7 (disabled says why — for things that CAN open), §6.2 (the tab rail), 00-plan Q18 (read-only view or retired).
**Fix (default)** Drop the entry from `TABS` (three tabs: Roster / Facilities / Records) and keep the reason sentence as the Roster tab's subtitle on a day with a pinned mission ("Tonight's twelve are chalked on the board."). If the designer wants a read-only view, it is a Roster filter "Chalked" (the filter chips exist — `At risk / Tanks / Healers / DPS`), not a tab. Test: `test_screens.gd`'s tab pins updated.
**Owns** `game/screens/Guildhall.gd` (:40-60 TABS), `tests/unit/test_screens.gd`, `tests/unit/test_roster_layout.gd`.
**Size** S.
**Wave** 6.
**Audit** HALL-21 (Q18), HALL-04.

### UI-51 — After one clear the events feed is four rows of "Bork: cleared"
**Status** CONFIRMED.
**Evidence** `build/shots/w5tools/all/tabs/Guildhall_Records.png` "Recent Events": "Cleared Adventure 0 — 4 G." then "Bork: cleared / Gruk: cleared / Rhona: cleared / Greg: cleared" — `Cards.recent_events` (`Cards.gd:805-834`) turns every raider's `morale_log` note into a feed row as `"%s: %s" % [name, note]`, and the sim's note for a clear is the bare word "cleared" (a morale-log tag, not a sentence). A 12-raider clear fills the six visible rows with twelve tags and the raid's own line is gone. Concept 3's feed is one sentence per event ("Tiny disarmed a trap and found 120 gold.").
**Doc** docs/13 §5.3, spec 01 §4 (the feed).
**Fix** Collapse morale-log rows by note and day into one sentence ("Twelve raiders came home happier." / "Tiny is still upset about E5.") through a small note→sentence table in `Cards.gd` (the notes are a closed set — `Morale.gd`'s tags), and never more than two morale rows per day; the raid's line stays first. Test: after a 12-raider clear the feed has <= 3 rows for that day and none reads "<name>: cleared".
**Owns** `game/ui/Cards.gd` (`recent_events`, :780-840), `tests/unit/test_kit3.gd` or `test_widgets_kit.gd`.
**Size** S.
**Wave** 6.
**Audit** KIT-07, TOWN-23.

### UI-52 — Every empty main-hand slot is a sword silhouette, on every class
**Status** CONFIRMED (minor).
**Evidence** `fixture/RaidView.png` party cards (37..92 x 900..965 on each card): Gruk (Cleric), Rhona (Shaman) and Greg (Rogue) all show the same faint longsword outline in the big weapon slot, meaning "no weapon"; `fixture/RaiderDetail.png` shows it beside "no weapon" and "+0 Power · +0 Mana" chips. Reads as "everyone carries a sword".
**Doc** spec 06 §2 (slot silhouettes per slot kind), docs/09 §4 (weapon families per class).
**Fix** The empty main-hand silhouette per armour family (`data/classes.json` groups four: sword / staff / dagger / mace — the icon grid has the four class-glyph shapes already) via `PaperDoll.silhouette_for(slot, family)`; drop the "+0 Power / +0 Mana" chips when zero (print only non-zero bonuses — the report already does "+7 AC").
**Owns** `game/ui/PaperDoll.gd`, `game/screens/RaiderDetail.gd` (:330-360 the chip row), `game/screens/RaidView.gd` (card doll), `tests/unit/test_raider_detail.gd`.
**Size** S.
**Wave** 8.
**Audit** HALL-07, HALL-08.

### UI-53 — The Reputation chip wears the reference's gem in a game canon says has no gems
**Status** BLOCKED-designer (Q06) — shippable default: the rank sigil.
**Evidence** `Frame.gd:602` loads `icons/gem.png` for chip 2 ("320", purple); spec 00 §2.5 records the choice ("the gem icon stays") as a placeholder reading of Concept 3's purple gem; chip 4 already carries the rank sigil (a shield at Unknown, a chevron plate at Known — `w5tools/all/tabs/Guildhall_Records.png` (1290,36)). Two chips for the same stat (points and rank) with unrelated icons; nothing in the game explains what the gem is. The Board's "Potential Rewards" uses the same gem for a trinket (UI-14), so the gem means two things.
**Doc** spec 00 §2.5, docs/03 §1 (reputation is the single guild stat), 00-plan Q06.
**Fix (default)** Chip 2 = the rank sigil family's "points" glyph (a laurel or a scroll — `gen_icons.lua` has the sigil set) with the word "Rep" only in the tooltip ("320 reputation · 80 more to Known"); the gem file stays for a "yes, keep it" flip (`Frame.REP_ICON = "sigil" | "gem"`). Cost if unanswered: none — either icon is legible; the point is that the two chips and the reward row stop sharing one glyph.
**Owns** `game/ui/Frame.gd` (:595-610), `tools/aseprite/gen_icons.lua` (one glyph), `tests/unit/test_frame_header.gd`.
**Size** S.
**Wave** 8.
**Audit** KIT-14 (Q06).

### UI-54 — The dungeon arena is authored, marked, lit and never shown
**Status** BLOCKED-designer (Q-96 / Q18) — shippable default: raids in the dungeon, adventures in the cave.
**Evidence** `game/assets/bg/stage_arena_dungeon.png` (1536x1024, `crops/dungeon_plate.png`) with `stage_arena_dungeon.json` (16 brazier sprites, 19 lights, a `pulse` on the core, party marks at 64px pitch — wider than the cave's 48 — and a boss floor); `SceneStage.DEFAULT_ARENA := "stage_arena_cave"` (`SceneStage.gd:140`) is the only arena RaidPrep/RaidView/Results load (`RaidView.gd:453-498`). Every fight in Tier 1 — five raid encounters and four adventures — happens on one plateau. docs/15 Q-96 asks whether the backdrop belongs to the encounter or the raid.
**Doc** spec 09 §3 (six plates, two arenas), docs/15 Q-96, 00-plan Q18 (STAGE-06).
**Fix (default)** `SceneStage.arena_for(encounter)`: `kind == RAID → dungeon`, else cave — a mapping by the encounter's existing `slot` prefix (A*/TR vs E*), no content edit, behind `ARENA_BY_KIND := true`; a `backdrop` key on the record overrides when Q-96 lands. `boss_feet_y`/`marks` already take the scene name. The dungeon's core `pulse` is M4B-VFX-01 row 3's "rotating core" — a 2-frame glow on the crystal closes that row too. Cost if unanswered: half the art the designer supplied never appears.
**Owns** `game/ui/SceneStage.gd` (`arena_for`), `game/screens/RaidPrep.gd`, `RaidView.gd`, `Results.gd` (the three `DEFAULT_ARENA` sites), `tests/unit/test_scene_stage.gd`, `tests/unit/test_raid_beats.gd`.
**Size** S.
**Wave** 7.
**Audit** M4B-CONV-04 (Q-96), STAGE-06, M4B-VFX-01 row 3.

### UI-55 — The tutorial's lesson is never said on the screen where it happens
**Status** BLOCKED-designer (Q15) — shippable default: one callout band.
**Evidence** A0's notice on the Board (`fixture/AdventureBoard.png`) says "On the third round somebody will do something stupid, and that is the lesson."; RaidView on A0 shows nothing at round 3 (W5-SIM is landing `force_mistake_round` now) and Results on the Tutorial Raid never says "read the wipe report" — the Board blurb is the only teaching surface, and it is behind a scroll (UI-13 trims it). Q15's row: "nothing lands; if 'no', record it in q-tutorials.md".
**Doc** docs/10 §9 (the two tutorials' lessons), docs/13 §11.2; 00-plan Q15.
**Fix (default)** A one-line `Widgets.callout_band` over the log on tutorial encounters (`Reputation.is_tutorial_slot`): A0 at the scripted round — "That was the lesson: somebody always does something stupid. Watch the log for the MISTAKE stamp." — and TR at the wipe — "Read the wipe report. You will be seeing a lot of it." Behind `RaidView.TUTORIAL_BAND := true`. Cost if unanswered: a player who skips the notice text learns nothing from the tutorials, which exist to teach.
**Owns** `game/screens/RaidView.gd`, `game/screens/Results.gd` (the TR line), `game/ui/Widgets.gd` (`callout_band`), `tests/unit/test_tutorials.gd` (a screen clause).
**Size** S.
**Wave** 7.
**Audit** CRITIC-G14 (Q15), M5-TUT-12.

### UI-56 — In wide "Expand" the hall family leaves a 290px column of bare camp between its panel and the sidebar
**Status** CONFIRMED (minor; wide mode is otherwise clean).
**Evidence** `wide-expand/_sheet_2.png` Guildhall / RaiderDetail tiles: the roster panel keeps its 1536-frame width (right edge ≈ x 1130) while the sidebar rides the new right edge (x ≈ 1420..1810), so a bare, dimmed strip of camp shows between them; Town/Tavern/Market/LoadSave/Settings widen their centre (Settings' options panel fills; the scene hosts fill). `wide-keep` is bars-at-the-sides on all 13 routes and clean (pixel samples at x=50/140 and 1700/1780 are the ground colour on every screen checked). Nothing clips or overlaps in either mode.
**Doc** spec 11 §1 (the 16:9 logical canvas), m4t-07 (the expand-mode check — not built as a test).
**Fix** The hall family's centre panel takes the scene host's width (`Frame.relayout` already hands the widened rect; `Guildhall._layout` sizes the panel from a constant) — five cards per roster row at 1820. Land `m4t-07`'s pure `Frame.relayout` test (A/B halves of its remaining_work) at the same time; it is the regression guard for both modes.
**Owns** `game/screens/Guildhall.gd` (panel width), `game/screens/RaiderDetail.gd`, `tests/unit/test_frame_wide.gd` (new — m4t-07's test).
**Size** S.
**Wave** 8.
**Audit** m4t-07, G03.

## The eighteen designer questions (00-plan §6) — a shippable default for each, and what silence costs

Numbering is 00-plan §6's. "Ships as" = the switch's value if the designer never answers; every one is already built or is a constant flip except where marked.

| Q | Ships as (default) | What it costs if never answered | Finding |
|---|---|---|---|
| Q01 figure scale | camp/cave/dungeon 2x, tavern/market 1x (built) | The 2x figures are half the plate's pixel density (chunky beside painted rock); the 1x tavern patrons are ~30px and the joke plate dwarfs the speaker. Playable; not the reference's finish. A re-author at 2x canvas is XL and waits on this answer. | UI-07, UI-21, UI-22 |
| Q02 boss mass | 1x on its floor, moved in front of the fence (UI-22's S) | The boss is smaller than four raiders together; the fight's silhouette is inverted from Concept 2. Re-author = XL. | UI-22 |
| Q03 hall framing | `HALL_FRAMING = "same"` (built) | The hall is the hub with a panel over it — the player has no visual "I am inside now"; acceptable because the panel is the place. Zero cost to ship. | UI-26 (independent) |
| Q04 bubble chrome / emote vocabulary | one chrome; the ten glyphs with the mapping in UI-41 recorded as PROPOSED | None visible — the mapping is a table edit later. | UI-41 |
| Q05 header lockup | 44 + tagline (built) | none | — |
| Q06 reputation chip | the rank sigil (UI-53's S) with a `REP_ICON` flip | none | UI-53 |
| Q07 overhead bars | badge + pips on all, HP bar on acting/struck (built); UI-21 hides the stack on back ranks | none | UI-21 |
| Q08 depth of field / grade | no DOF, vignette on, no grade (built) | The references show no blur; docs/12's tilt-shift is a PROPOSED aesthetic — shipping without it matches the concepts. Zero. | — |
| Q09 screen change | `TRANSITION_MS = 0`, no wipe slide (built) | Screens cut. The wipe page appears in place. Matches M5 and the references. Zero. | UI-46 |
| Q10 Town focus entry | rail-first (built, tested) | none | UI-33 (other screens) |
| Q11 levels on cards | none in play (`level` is only set by saves and the fixture) | none; the fixture stops showing them (UI-15) | UI-15 |
| Q12a/b/c combat copy | "Main Boss" stays; `COMEDY_LINE = "as_built"`; `EXITS_GATED = false` | (a) the boss plate says "Raid 1 — Encounter 5 / Main Boss" — a creature name is content, not UI; (b) the comedy line beside the tally reads fine; (c) the player can leave mid-account — docs/15 Q-53's default agrees. Zero. | UI-36, UI-37 |
| Q13 hub copy | blurb "Under construction." (the designer's); reason reworded off-screen (UI-01); "Pauline_4" stays | the handle joke either lands or reads as a bug — a one-word answer | UI-01 |
| Q14 Settings controls | lit cycle buttons (built) | none | UI-28 |
| Q15 tutorial lesson surfaced | one callout band per tutorial (UI-55's S), `TUTORIAL_BAND = true` | without it the tutorials teach only through the Board's notice text | UI-55 |
| Q16 a11y rulings | `colourblind_safe` as an OFF option (UI-47); Type floors as built; the `prose_font_swap` row deleted (UI-28); the logotype stays exempt | CVD players lose the colour channel (the word and glyph remain); nothing else visible | UI-47, UI-28 |
| Q17 morale faces | sprite font (built) | none | — |
| Q18 asset scope | swords glyph; `HUB_CTA = "board"`; Raid Group tab retired (UI-50); raids in the dungeon (UI-54); the aerial town stays an establishing shot with gulls and sails (M4B-ACT-04 — accept); HSV busts as built; facility thumbs derived (UI-40); role-based VFX; the 64x80 canvas untouched | The visible-change tranche on the camp (TOWN-15) and what the guildhall IS at four levels (HALL-18) ship as derived tent states — enough to read progression, not the designer's drawing. | UI-40, UI-50, UI-54 |

## Shippable bar

A reviewer ticks these for the UI area before ship. Each names the instrument.

1. `shot_all.sh --sheet=all` (fixture, empty, focus, text125, text150, emoji, reduced, wide-keep, wide-expand, tabs, raid-advanced, raid-clear, hover, play) is clean on every route: no Label ends in "…" unless it is a live log row with a tooltip; no ScrollContainer fold slices a row, a card or a slot; nothing overlaps a panel rim; no control is off-screen — `tests/unit/test_text_scale_layout.gd` with an EMPTY allow-list at 100/125/150 (UI-30/31/32).
2. Every dialogue surface is legible at 100/125/150: the camp/tavern/market speech plate clear of callouts, header and figures (UI-04/07/20/35); the live log's MISTAKE row shows the type name (UI-19); the wipe report's quotes wrap and the report never truncates a joke (UI-23); the emote bubble is head-sized on its scene (UI-41).
3. No developer copy on any screen: a `tools/lint_copy.sh` over `game/screens` and `game/ui` finds none of "canon", "this build", "module", "fixture", "audit", "docs/", "export build", "type pass" in a Label/Button literal (UI-01/27/28/48).
4. Every figure alive or deliberately still: camp/tavern/market crowds breathe or walk, fires flame, the boss idles; at a wipe the party lies down (UI-38); nothing is a statue without `reduced_motion`; `reduced_motion` twins are frame-identical across two captures (a `--frames=2` shot pair per route — an instrument gap, see Coverage).
5. No light or effect crosses a panel: stage lights cull-masked to the stage (UI-26); the vignette and glow only under `reduced_effects` off.
6. No placeholder art: no bare `Widgets.slot(null)` in a row that means "nothing" (UI-06/14); the risk hatch drawn, not typed (UI-17); the prep band shows the party (UI-16); the four facility states exist (UI-40); the dungeon arena is reachable (UI-54); the clear page has its stamp (UI-36).
7. Focus: every route's entry control is the one docs/13 names or the first primary act, the 2px ring visible on it in `focus/*.png` (UI-33); every tooltip a two-line plate of its own size (UI-49) on the `hover` sheet.
8. Mental model: the Market opens with nothing selected under "Sell" (UI-09); the Board's sidebar shows the whole notice (UI-13); the feed reads as sentences (UI-51); the Options screen lists only what exists (UI-28); the wipe page offers "Try again" under Q-53's default (UI-37).
9. The fixture is a legal save (UI-15) so every sheet above is shot on a state a player can reach.
10. The art gate's 14 numbers are recorded per wave (`docs/_log/progress.md` "Art gate baselines") and no target regresses more than the 0.07 jitter — the gate stays a no-regression record, not a resemblance bar (the design wins over the mockups; `m4t-06`'s region scoring is not required to ship).
11. The switch register (spec 00 §2.7) lists every default above with its flip and a test pinning it; the eighteen rows of §6 each carry a "ships as" line in docs/15.

## Questions for the designer

Only the ones a build loop cannot settle and the defaults above do not cover:

1. Figure density (Q01/Q02, the one that changes the finish): accept 2x integer-scaled figures and a 1x boss for v1, or commission a 2x-canvas re-author of the 12 party families and 6 bosses (XL, art only)? Everything in this report ships on the first answer; the second is the only path to the references' finish.
2. Q13's second half: does "Pauline_4" stay as the handle joke? (One word.)
3. The credits (M5-END-4 / Q-21): the names and roles, and whether the derivable attributions alone may ship at v1 under a "Credits" heading with no names (UI-48).
4. S13 (encounter interstitial) and S16 (codex): docs/13 §5 lists both; BL-24 chunks the raid one encounter per rung and neither screen exists. Are they cut for v1 (docs/13 marks them cut) or is one of them in waves 8-10? The UI plan cannot size an unnamed screen.
5. Q-53's "Try again": the recommended default puts a "Try again" on the wipe page (UI-37); confirm, or rule attempts limited so it never appears.
6. The Raid Group tab (Q18/HALL-21): retire (default) or a read-only "Chalked" filter? (One word.)
7. Which arena (Q-96): by raid (dungeon) vs adventure (cave) — the default — or per encounter record?

## Coverage

Read: BUILD_STATE.md (Current focus, HANDOFF, binding decisions); `build/plan/artaudit/00-plan.md` §0, §6, §7; `art/ref/specs/00-canon-reconciliation.md` in full, spec 09 §2-§5 (grep), docs/13 §5, §11.4, §12-§13 (grep); `build/shots/_w5_args.json` (all seven contracts); `report-W5-KIT3.md`, `report-W5-SCALE.md`, `report-W5-TOOLS.md` and `handoff-W5-TOOLS.md` §2; `docs/_log/progress.md`'s ART WAVE 0-4 entries and the art-gate baselines; the 31 audit rows in my scope (m4t-01..13, M4B-*, M6-JUICE-01..08, M6-A11Y-07) in full; code at the cited lines in Town/Tavern/Market/AdventureBoard/RaidPrep/RaidView/Results/RaiderDetail/Settings/Completion/Guildhall, Widgets/Cards/Frame/SceneStage/Palette/Theme/Badge/Boot, RaidPlan, fixture_reference, the six scene JSONs and `data/credits.json`.

Viewed at full size: all 13 `fixture/*.png`; `text150/` Guildhall, RaidView, RaidPrep, Results and sheets 1-2; `focus/_sheet_1` + two crops; `empty/_sheet_1-2`; `emoji/` two crops; `wide-expand/_sheet_1-2`; `wide-keep/_sheet_1` + pixel samples; `tabs/_sheet_1`; `raid-advanced/RaidView_10.png`, `RaidView_all.png`; `raid-clear/Results_clear.png`; `w5tools/all/tabs/Guildhall_Records.png`, `w5tools/RaiderDetail_hover.png`; reference concepts 2 and 3; the icon grid at 6x (`crops/icons_sheet.png`); the dungeon plate. 24 crops under `build/plan/ship/crops/`.

Not done: no Godot run (the mutex is held), so motion was judged from single frames — the `reduced` twins were pixel-diffed against the fixture shots (they differ only by animation phase and glow, as expected) but "held still" needs a two-frame capture; hover states beyond the two W5-TOOLS shots; a 125% sheet (none was shot after wave 4); Concept 1 was not re-read (the Board/Completion graded against it looked clean on the sheets); the VFX strips (`fx_*.png`) and the boss idle/hit/death strips were not viewed frame by frame — the advanced shot shows no VFX mid-flight, so their read at 2x is unverified; the Settings/LoadSave 150% and the Records tab at 150 were seen only on the half-size sheet; audio and the sim's copy (`MistakeLines`) belong to other reporters. W5-KIT3 and W5-SCALE were mid-flight on the 10:53 sheets — UI-31/32 must be re-checked at the wave-5 close against fresh sheets.
