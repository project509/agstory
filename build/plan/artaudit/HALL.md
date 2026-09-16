# HALL — Art/UI audit of the hall family (Guildhall, Roster, Facilities, RaiderDetail, LoadSave, Settings)

Date: 2026-09-13. Key: HALL. Read-only audit; no tree edits.

## Scope

Shots read (1536x1024, scratchpad/shots/): Guildhall.png, RaiderDetail.png, LoadSave.png, Settings.png.
Plates read: game/assets/bg/guildhall_plate.png (929x637), game/assets/bg/stage_camp.png (1536x1024).
Scenes read: game/assets/scenes/stage_camp.json, game/assets/scenes/guildhall.json.
Code: game/screens/Guildhall.gd, Roster.gd, Facilities.gd, RaiderDetail.gd, LoadSave.gd, Settings.gd, Town.gd (plate method), game/ui/SceneStage.gd, kit; tests/unit/test_screens.gd, tests/a11y_smoke.gd (contracts).
Specs/docs: art/ref/specs/09, 10, 06, 00; docs/13-ui-ux.md §8 §9.1 §15.1; docs/02 §9; BUILD_STATE.md art directive; build/plan/audit.json M4B-CONV-01/03, M3-SAVE-04.

### Raw shot notes (written first so they survive)

**guildhall_plate.png** — 929x637 crop of Concept 1's hall. Baked in: ~18 painted patrons (bartender + barmaid at the bar 240..420,270..350; five on the balcony 240..640,90..160; two at the round table 440..620,380..480; guard at 20..60,330..400; walkers at 280..330,450..520 / 730..790,400..480 / 300..330,540..600; group at 330..420,510..600; 760..800,540..600). Painted hearth flame at 120..170,320..380 (guildhall.json overlays fire_hearth on top of it). No baked speech bubbles or label pills in this crop (guildhall.json renders bubbles at runtime), but the painted figures alone violate the 09-11 directive.

**Guildhall.png** — plate only shows as slivers: x210..232 y76..720 (22px) and x1140..1146 (6px), dimmed to 0.5. Tabs 232,102,320,30. Stray full-width helper line 232,140,906,18 ("Raid Group — Chalk tonight's twelve… Records — There is nothing to record…"). Sort/Filter chips y172..200. Card grid 4 x N, card 214x260 at 232,210 / 456 / 680 / 904; row 2 at y537 clipped at y700. Card action row (Cheer up / Manage) at y478..505 sits BELOW the card border (card border ends y468), with "They are fine." at y518 under it. Level shown only on Tiny/Spoof (Lv. 11/10); Rhona/Greg/Pip/Cindy/Steve/Hal show no level. Three identical Rogue portraits (Tiny/Greg/Pip), two identical Mage (Spoof/Steve), Rhona (Shaman) has a knight portrait with mage gear icons. Morale glyphs are colour-emoji font glyphs (😡 😥 😐). Right column 1146,84,370,630: Rest / Rest a day / Rest until recovered (crimson) / Roster summary / Back to town. Bottom strip 14,735,1018,260 "Lowest morale first": 7 plain text rows (dot + name — morale + glyph + class — word), rows for Hal…(12 raiders) cut off after Steve. "Recent Events" 1046,735,475,260 empty.

**RaiderDetail.png** — plate slivers x210..228, 688..706, 1121..1146, dim 0.42. Kit panel 228,92,460,610: portrait 250,145,88,96; stat boxes "7 AC / 0 HP / 0 Power / 0 Mana / 0 Damage" (zeros). Slot column 250,262,420,380: 7 rows (Main Hand empty, Off Hand empty, Head, Chest, Legs, Feet, Trinket empty), 44x44 icon boxes, plain labels; no doll. Quarters panel 706,92,415,610: formula line, "Settled, or better.", "Slots: empty", two furnishing chips; "On record" plain prose x4 lines. Right column: Raider card (Bork — 87 💗, Warrior — Very Happy, Common · misses about 15%), Cheer up disabled, Dismiss, Back to the roster. Bottom strip: "Available 12" pager (2x4 thumbnails, page 1/3, < >) + 4 raider cards w/ Open + Recent Events.

**LoadSave.png** — nav rail lights "Options". Header day chip icon is a grey shield (1272,37) where other shots show a sun. Main panel 232,96,885,890 with double copper frame (outer + inset line), single title row "Guild Slots" + helper. Slot 1 row: 3 tight buttons (Load — Slot 1 105px, Save to Slot 1 107px, Delete Slot 1 100px). Slots 2/3: Load/Delete disabled and stretched to 238px, Save tight — widths differ per row. "Slot 2 is empty." printed twice per empty row (under Load and under Delete). Panel empty from y450 to y985. Right panel 1146,84,370,912 prose + Back at y938.

**Settings.png** — same double-frame panel 232,96,885,890. Title "Options  13 of 17 live in this build". 17 rows, each: label (x260) / description (x466, wraps to 2 lines on 4 rows so row heights vary 36..40) / value button 941,y,148,32. Every control is the same secondary button (toggle On/Off, cycle 1x, Keep, 100%, sliders as "100"/"80"). Disabled rows: label grey, reason line in steel-blue under description, button greyed. Rows end y792; panel empty y800..985. Right panel: prose, Save / Load, Back, Restore defaults, Apply (crimson, tall).

## Summary

All five hall screens (and the Facilities sidebar card) still load `guildhall_plate.png`, a Concept 1 crop with ~18 painted patrons — the one P0. Today's message lifts M4B-CONV-03: they go on `stage_camp` at Town's offset (-46,-62), dim 0.62; Settings inherits the previous screen's stage via a new `ScreenRouter.previous_path()`. The honest catch is that archetype C hides the plate behind opaque panels (6-18px margins), so LoadSave should narrow its panel to expose the fire ring and the designer must say whether Guildhall/RaiderDetail drop to three columns to show a camp column (HALL-02).
Below the plate, the family is functionally complete but visibly below the reference finish: card actions hang outside the card border and halve the visible rows; the "Lowest morale first" strip flattens canon's two-line row into one and stops at seven; morale glyphs are system colour-emoji while the authored 24px face sheet is unused; same-class raiders share one bust; RaiderDetail's paper doll is a column, not Concept 2's slot grid. Twenty-four findings: 1 P0, 6 P1, 11 P2, 6 P3; five need a designer ruling (camp column, variant busts vs drawn busts, hall level art, Raid Group's fate, display levels).

Verifier pass (2026-09-13): all 24 findings CONFIRMED against the cited lines and shot regions (HALL-05 and HALL-12 carry corrections in their Verdict lines — HALL-05's faces.json/Enums "Very Happy" clause is wrong and its generator is tools/art/gen_icons.lua; HALL-12's "font colour only" half is overstated); 0 REFUTED, 0 UNVERIFIABLE; HALL-25 and HALL-26 added by the verifier (P3 polish). HALL-19's Fix needs a tooltip hook for Town's `_standing_tip()` before the hand-rolled chips are deleted.

## Plate plan per screen

Geometry the plan is chosen against (game/ui/Frame.gd:277-297): the framed scene window is 928x640 at screen (210,77) when the strip is present, 928x930 when the frame is `tall` (LoadSave, Settings). The camp plate is 1536x1024; its fire ring is at plate (620..820, 340..470) with the fire light at (720,400), the four seated actors at (648,432)/(797,427)/(668,372)/(784,368), the bridge at y 762, the big tent at (230..470,110..330), the stream/shimmer at (430,800,210,224) (game/assets/scenes/stage_camp.json). Converted screens mount `SceneStage.load(name)` at a per-screen offset and dim with `stage.modulate = SCENE_DIM` (Tavern.gd:107-124, Market.gd:150-153, RaidPrep.gd:45-50,150-154, AdventureBoard.gd:139-142). The hall family must do the same; the offset belongs to the screen, not the JSON (Town.gd:120-134).

What the opaque panels leave visible today — this is the honest constraint: the hall family is archetype C, so the plate shows only in margins unless a panel is narrowed.

| Screen | Panel rects in the window | Plate visible today | Plan: scene · offset · dim | Layers to keep | Why |
|---|---|---|---|---|---|
| Guildhall (Roster / Facilities / Records tabs) | one PanelWarm at (6,8) 916x624 (Guildhall.gd:78-79) | 6px left/right, 8px top/bottom | `stage_camp` · **(-46,-62)** = Town.CAMP_OFFSET · `Color(0.62,0.62,0.68)` (RaidPrep's dim; the bare plate is darker than the crop and carries its own lights, so 0.5 is too much) | plate, lights, campfire prop, embers, actors; call `stage.set_lines([])` and drop bubbles (they would render under the panel) | Same framing as Town so Town → Guildhall reads as a panel sliding over the SAME camp (docs/13 §2.3 M5 "the desk does not move"). The grid needs the full 888 inner width (Guildhall.gd:75-77), so no band can be freed without dropping to 3 columns — see HALL-24 |
| RaiderDetail | two PanelWarm: (14,12) 466x616 and (492,12) 423x616 (RaiderDetail.gd:59-65) | 14px left, 12px between, 13px right, 12px top/bottom | `stage_camp` · **(-46,-62)** · `Color(0.62,0.62,0.68)` | as above, no speech | Continuity with Guildhall (pushed from it, returns to it); the 12px seam between the panels then shows camp ground rather than the hall's painted floor |
| Facilities tab | inside Guildhall's panel | — | inherits Guildhall | — | Its sidebar "hall card" must stop cropping the baked bar (Facilities.gd:476): crop the bare camp's big tent `Rect2(230,110,337,104)` of stage_camp.png until HALL-18's level art exists |
| Records tab | inside Guildhall's panel | — | inherits Guildhall | — | — |
| LoadSave (tall) | one PanelWarm at (18,14) 892x902 (LoadSave.gd:123-127) | an 18px frame | `stage_camp` · **(-10,-62)** · `Color(0.70,0.70,0.76)` with the panel narrowed to **(18,14) 572x902** so a **928x930 window band at x 600..928** stays open | plate, fire prop, fire light + the two tent lanterns at (404,230)/(1112,237) fall outside the band — keep all, cost is nil; embers on; actors on; speech bubble at (560,484) → window (550,422) sits under the panel edge, so `set_lines([])` | The three slot rows need ~560px (Slot 1's three buttons span 260..595 in the shot). With offset x -10 the fire ring lands at window x 610..810, i.e. wholly inside the freed band, with its four seated raiders, the embers and the breathing fire light — the liveliest 330px of the camp, framed the way Market chose its 928x66 band (M4B-CONV-01). If the designer wants the full-width panel kept, use (-46,-62) and dim 0.62 like the rest of the family |
| Settings (tall) | one PanelWarm at (18,14) 892x902 (Settings.gd:168-173) | an 18px frame | **inherits the stage of the screen it opened from**, dimmed `Color(0.55,0.55,0.62)` (spec 09 §4.5's value, kept) | all, no speech | Table needs 190+458+150 + gaps ≈ 830px (Settings.gd:106-108), so no band; the panel could end at the last row (y≈830) to free a 928x100 band at the bottom — that band with offset (-46,-62) shows plate rows 892..992 = the stream shimmer at window x 384..594, which is animated water and worth the 100px (HALL-15). Mechanism: `ScreenRouter` gains `previous_path()` (`_stack[-2]`, game/core/ScreenRouter.gd:38-98) and Settings maps it through a const table `STAGE_FOR := {Town: [stage_camp,(-46,-62)], Guildhall/RaiderDetail: same, AdventureBoard: [stage_camp,(-20,-80)], Tavern: [stage_tavern,(-320,-130)], Market: [stage_market,(-330,-240)], RaidPrep/RaidView/Results: [SceneStage.DEFAULT_ARENA,(-30,-120)], MainMenu: [stage_town, MainMenu's offset]}`; default `stage_camp (-46,-62)` when the stack has no previous screen |

Acceptance for the whole plan: `grep -rn guildhall_plate game/` is empty; `python tools/art/preview_scene.py stage_camp` with each offset shows what the table claims; the four fixture shots show no painted human; test_screens.gd, test_rest.gd, test_comfort.gd, test_raider_detail.gd, test_loadsave_screen.gd unchanged; a11y_smoke.gd unchanged (SceneStage adds no focusable); lint_motion.sh unchanged (SceneStage already gates on reduced_motion, SceneStage.gd:619-651).

## Findings

### HALL-01 · P0 · baked-bg · Five hall screens still stand on the Concept 1 crop with its painted patrons
Evidence: game/screens/Guildhall.gd:163-169 (`load("res://game/assets/bg/guildhall_plate.png")`, modulate 0.5/0.5/0.56); RaiderDetail.gd:138-144 (modulate 0.42/0.42/0.5); LoadSave.gd:42,115-121 (0.55/0.55/0.62); Settings.gd:160-166 (0.55/0.55/0.62); Facilities.gd:476 (AtlasTexture region 296,250,337,104 of the same crop — the bar with the painted bartender and barmaid — used as the sidebar "hall card"). Roster.gd has no ground of its own (it is a tab inside Guildhall's panel). Plate content: game/assets/bg/guildhall_plate.png carries ~18 painted figures (bar 240..420,270..350; balcony 240..640,90..160; round table 440..620,380..480; floor 280..800,400..600) and a painted hearth flame that guildhall.json:props[0] overlays with fire_hearth.png. Shot: Guildhall.png x210..232,y76..720 shows the crop's left wall through the dim; RaiderDetail.png x688..706 and x1121..1146 show its floor.
Why it matters: this is the exact thing the 2026-09-11 directive removes ("painted people … baked speech"), and today's message names the hall family as the remaining offenders. BUILD_STATE.md:74 already assigns `stage_camp.png` to "Guildhall family (Guildhall, Roster, Facilities, RaiderDetail, LoadSave)"; today's message lifts M4B-CONV-03.
Fix: replace each `TextureRect` plate block with `SceneStage.load("stage_camp")` positioned by a per-screen offset constant (Town.gd:134 `CAMP_OFFSET` is the pattern; M4B-CONV-01's method: choose the offset for the band the opaque panels leave visible). Dim with a `ColorRect` (or SceneStage's own dim if it has one — see Plate plan) rather than `modulate` on a TextureRect. Facilities' sidebar card: crop the bare camp plate (the campfire ring 620..820,340..470 or the big tent 230..470,110..330) instead of the bar with the painted staff, or drop the card until the per-level plates exist (docs/02 §9). Per-screen offsets and dims are in "Plate plan per screen" below.
Assets: none new — stage_camp.png + stage_camp.json exist. Optional: a `tools/art/preview_scene.py` run per offset to check what each panel leaves visible.
Acceptance: `grep -rn guildhall_plate game/screens` returns nothing; fixture shots of Guildhall/RaiderDetail/LoadSave/Settings show the camp (trees, tents, fire glow) in the slivers and behind any translucent panel; no painted human figure anywhere in the four shots; tests/unit/test_screens.gd unchanged (no Label/Button text touched); a11y_smoke.gd unchanged (SceneStage adds no focusables); lint_motion passes because SceneStage already gates on reduced_motion.
Needs designer: no (today's message decides the plate). One sub-question in Open questions: whether Settings should dim the plate of the screen it opened from (Town → stage_town, Guildhall → stage_camp) or always camp.
Verdict: CONFIRMED — Every cited load is at the cited line (Guildhall.gd:164, RaiderDetail.gd:139, LoadSave.gd:42/116, Settings.gd:161, Facilities.gd:476 region 296,250,337,104), `grep -rn guildhall_plate game/` returns exactly those five plus a retired comment at AdventureBoard.gd:126, guildhall_plate.png viewed carries ~18 painted figures and a painted hearth flame, and the Guildhall/RaiderDetail slivers show the hall wall/floor; the only uncheckable clause is "today's message lifts M4B-CONV-03" (audit.json still reads blocked-needs-human), and note BUILD_STATE.md:73 assigns Settings to stage_town while the plan's inherit-with-default-camp follows spec 09 §4.5 (09:234) instead.

### HALL-02 · P1 · composition · The camp will be invisible behind the hall panels unless a band is freed
Evidence: Guildhall.gd:78-79 (panel (6,8) 916x624 in a 928x640 window); RaiderDetail.gd:59-65 (14/12/13px seams); LoadSave.gd:125-127 and Settings.gd:170-173 (18px frame). Shot Guildhall.png: the only plate pixels are x210..232,y76..720 and x1140..1146. Compare Market (M4B-CONV-01: a 928x66 band chosen for two shoppers) and RaidPrep (a 536x640 column chosen for five lantern flames).
Why it matters: today's directive is about "actually design in the real graphics of the game"; a conversion that swaps a texture nobody can see satisfies the rule but not the intent. Concept 1's dashboard is 60% scene; the hall family is 2%.
Fix: LoadSave — narrow the panel to 572px and expose the fire ring (Plate plan). Settings — end the panel at the last row (free a 100px bottom band). Guildhall/RaiderDetail — cannot free a band at 4 columns; two options for the designer: (a) accept margins-only on those two, (b) drop the Roster grid to 3 columns x 4 rows (3x224+215 = 663px panel; the freed 928-663-gaps ≈ 250px right column shows the fire ring at offset (-10,-62)) — 12 raiders then need 4 rows of 270 = 1080px, i.e. scrolling either way. Option (b) costs a row of visible cards; the reference shows four across.
Assets: none.
Acceptance: the LoadSave fixture shot shows the fire ring and four seated actors in x 810..1138; Settings shot shows water shimmer in y 907..1007. Both screens still pass a11y_smoke (no focusable moves off-screen).
Needs designer: yes — Guildhall/RaiderDetail: margins-only (a) or 3-column grid with a camp column (b)?
Verdict: CONFIRMED — Frame.gd:277-297 with SCENE_LEFT 210 / RAIL_TOP 77 / RULE_Y 717 / SIDEBAR_W 378 / GUTTER 16 (Frame.gd:30-41) gives the 928x640 window (928x930 tall), the panel rects at Guildhall.gd:78-79, RaiderDetail.gd:59-65, LoadSave.gd:125-127 and Settings.gd:170-173 are as cited, the shot shows plate only in the x210..232 sliver, and the 3-column arithmetic (2x224+215 = 663) checks.

### HALL-03 · P1 · polish · Roster card actions hang below the card border and halve the visible rows
Evidence: Roster.gd:56-59 (`ACTIONS_H 58`, `CELL_H = CARD_H + 58`, `ROW_PITCH = CELL_H + 8` = 328) and :485-494 (action row placed at `CARD_H + 4`); shot Guildhall.png: card border ends y468, "Cheer up / Manage" at 232,478,214,30, "They are fine." at 680,512,100,14; second row starts y537 and is clipped at y700. Spec 10 §2 R2 planned 262+8 pitch → 3 rows visible; the shot shows 1.8.
Why it matters: the reference card (01 §3) is a closed frame; buttons floating under it read as a layout accident, and the roster — the screen players live on — shows fewer than half its raiders.
Fix: put the two actions INSIDE the card. `Cards.card()` already takes an `action` dict rendered along the bottom edge (Cards.gd:135-140); extend it to accept `actions: Array` (two Buttons in a row, Cheer up expand + Manage shrink) and drop `ACTIONS_H` so `ROW_PITCH` = 270. The reason label ("They are fine.", asserted by test_raider_detail via `_joined`) stays as the `button_with_reason` child inside the card. Alternatively make the card body a flat Button whose text is the raider's name (docs/13 S04 primary action "Select a raider") and keep a small "Manage" Button too — the `_button_named(view, "Manage")` press at test_raider_detail.gd:333 needs a Button with that text.
Assets: none.
Acceptance: shot shows no control outside a card border; ≥ 2 full rows + the third row's tops visible at 12 raiders; test_raider_detail.gd:302-333 ("Cheer up", "Manage") pass.
Needs designer: no.
Verdict: CONFIRMED — Roster.gd:56-59 (ACTIONS_H 58, ROW_PITCH = 262+58+8 = 328) and :485-494 place the action row at CARD_H+4 outside the PanelRound; the Guildhall shot shows Cheer up/Manage under the card border with "They are fine." below and row 2 clipped at the panel bottom; the Fix keeps "Cheer up"/"Manage" as Button.text and "They are fine." in a Label, which is what test_raider_detail.gd:302-333 reads.

### HALL-04 · P1 · bug · The strip's "Lowest morale first" list flattens canon's two-line morale row into one line and stops at seven
Evidence: Guildhall.gd:453-459 (`for i in mini(7, roster.size())`, format `"%s — %d %s      %s — %s"` in one `log_row`); shot Guildhall.png 30,775,340,190: seven single-line rows, Hal and four others missing, 660px of the 1020px panel empty. docs/13 §8.1: "line 1 is Name — value glyph, line 2 is Class — State … never abbreviated"; §8.6: name every at-risk raider in two seconds.
Why it matters: this list exists to be the two-second read (Guildhall.gd:430-432 says so) and it is the most-read information in the game; a one-line, space-padded rendering with the list cut off is neither canon's shape nor the reference's finish.
Fix: two columns of six entries (12 = the raid size; 20-cap → "+N more, all above X" trailing Label), each entry a 2-line stack: `LabelMorale` "Name — 14 😡" coloured by `Palette.morale_color` over `LabelClass` "Rogue — Upset", with the 24px face sprite (HALL-05) at left instead of the Badge dot; pitch 36 → 6 x 36 + title 30 = 246 < STRIP_H 262. Keep the glyph in `Label.text` (test_screens.gd:869-928 reads `_joined()` for emoji presence/absence).
Assets: none new.
Acceptance: shot shows all 12 fixture raiders in two lines each; `test_no_screen_shows_an_emoji_once_the_option_is_on` and `test_the_emoji_come_back_when_the_option_is_off` pass.
Needs designer: no.
Verdict: CONFIRMED — Guildhall.gd:454 `for i in mini(7, roster.size())` and the one-line format at :456-459 are as cited, the strip crop shows seven single-line rows ending at Steve with Hal absent and the lower ~60% of the panel empty, docs/13:282 (§8.1) forbids collapsing the two-line format, and the Fix keeps the glyph in Label.text so test_screens.gd:869-928 still read it.

### HALL-05 · P1 · missing-asset · Morale glyphs are system colour-emoji while the authored 24px face sheet sits unused
Evidence: Cards.gd:41-45 → GameSettings.gd:194-198 returns `Enums.MORALE_BAND_EMOJI` characters; rendered by the emoji fallback font (shot Guildhall.png 372,325,22,22 — a Noto-style 😡; RaiderDetail.png 1290,200,20,20 💗). The authored set exists: game/assets/ui/faces.png + faces.json (ten 24x24 frames, bands 0-9) and icons/face_0..9.png, generated by tools/aseprite/gen_ui.lua; the only consumer is RaidView.gd:795, which picks a face by `raider.id.hash() % 10` — a random expression, not morale. docs/13 §8.3: "doc 12 ships all ten as authored sprites, not system emoji"; docs/12-art-direction.md.
Why it matters: a colour-emoji font glyph is the one element on the screen that is not pixel art; it breaks the 2D-HD finish on every card, the strip, the sidebar and the quarters block.
Fix: build a bitmap `FontFile` from faces.png at boot (`FontFile.set_texture_image`, `set_glyph_uv_rect`, `set_glyph_advance` for the ten codepoints in `Enums.MORALE_BAND_EMOJI`, size 24) and add it as a fallback in game/ui/Fonts.gd for the label variations that carry a glyph (LabelMorale, LabelLog, LabelBody, LabelClass). `Label.text` still contains the emoji character, so the walker, `_emoji_in()`, the emoji-free substitution (pips) and tools/lint_motion.sh's morale_glyph door are untouched. Fix RaidView.gd:795 in the RAID cluster to use the band (cross-cluster note). faces.json band 7 is named "Quite Happy" where Enums/docs say "Very Happy" — correct the manifest string.
Assets: none new (faces.png exists); a small generator tools/art/gen_face_font.py is optional if a pre-baked .fontdata is preferred to runtime construction.
Acceptance: shot shows pixel faces at 24px in place of emoji; test_screens.gd:856-928 pass unchanged; `GameSettings.emoji_free` still yields pips.
Needs designer: no.
Verdict: CONFIRMED — the glyph path (Cards.gd:41-45 → GameSettings.gd:194-198 → Enums.MORALE_BAND_EMOJI at sim/model/Enums.gd:385) and the colour-emoji rendering in both shots are as cited and RaidView.gd:795 is the only face_*.png consumer, but two clauses are wrong and must be corrected: faces.png/faces.json are generated by tools/art/gen_icons.lua:229-239 (not tools/aseprite/gen_ui.lua), and sim/model/Enums.gd:370-371 names band 7 "Quite Happy" and band 8 "Very Happy" exactly as faces.json does, so strike the "correct the manifest string" clause from the Fix.

### HALL-06 · P1 · missing-asset · Same-class raiders share one bust, so the grid repeats faces
Evidence: Cards.gd:51-77 (`REFERENCE_BUST_FOR_CLASS` → every rogue is tiny.png, every mage spoof.png, every warrior bork.png, every cleric gruk.png; the other five classes each have one derived `class_*.png` from tools/art/derive_busts.py). Shot Guildhall.png: Tiny 250,222 / Greg 922,222 / Pip 250,550 identical; Spoof 474,222 / Steve 698,550 identical. Concept 1 shows four distinct faces on four cards. docs/13 §8.6 (two-second recall) assumes faces differ.
Why it matters: on a twelve-card grid the player tells raiders apart by face first; three Tinys defeat the roster's one job and read as placeholder art.
Fix: per-raider variant busts. Extend tools/art/derive_busts.py to emit `class_<key>_<variant>.png` (hair/skin/cloth re-hue in HSV, the technique it already uses, keyed the same way tools/art/gen_actors.py keys its `variant_rNN_<hair>` strips, actors.json has 56), and have `Cards.portrait_for()` choose the variant by `raider.id.hash()` — the same hash SceneStage/RaidView use for the actor, so the card's face and the figure's hair agree. Named reference busts (bork/tiny/gruk/spoof) still win by name.
Assets: ~4 variants x 9 classes = 36 busts at 90x94 (generated, not hand-drawn); the four reference busts unchanged.
Acceptance: no two fixture raiders share a bust in the Guildhall shot; `portrait_for` returns tiny.png for Tiny; `test_canon_guard` nine-class checks unchanged.
Needs designer: yes — is a re-hued variant set acceptable at the bar, or should 2-3 busts per class be drawn in Aseprite (which would be a much larger commission)?
Verdict: CONFIRMED — Cards.gd:51-77 and REFERENCE_BUST_FOR_CLASS are as cited, game/assets/portraits/ holds only bork/tiny/gruk/spoof plus class_bard/druid/monk/shaman/wizard (derive_busts.py docstring confirms the HSV technique), the Guildhall shot shows three identical Tiny busts (Tiny/Greg/Pip) and two Spoof (Spoof/Steve), actors.json has 56 actors (44 variant_r), and no test pins `portrait_for` output beyond test_project_hygiene's grep.

### HALL-07 · P1 · missing-widget · RaiderDetail's paper doll is a list of slot rows, not Concept 2's slot grid
Evidence: RaiderDetail.gd:437-498 (`for slot in cd.available_slots(): col.add_child(_slot_row(...))` — a vertical column); shot RaiderDetail.png 250,262,420,380: seven 44px slot boxes stacked with labels. Reference Concept 2 combatant panel 20,745,235,240: a tall weapon slot ~62x74 left of a 3x2 grid of ~40px slots; spec 06 §2 "Weapon slot (C2) 62x74 … a taller instance of the ability slot"; spec 10 §3.5 target "paper-doll using the reference item slot component laid out as the combatant panel's slot grid (Concept 2)"; docs/13 §5 S05 "gear paper-doll". The portrait is 90x94 (RaiderDetail.gd:412-413) where 10 §3.5 says "big portrait".
Why it matters: this is the one screen about a single raider's kit; a list reads as an inventory table, not a character.
Fix: a `Widgets.paper_doll()` composite: portrait at 2x nearest (180x188) in a PortraitFrame well top-left; to its right the main-hand as the 62x74 weapon slot and a 3x2 grid of 47px slots (off hand, head, chest, legs, feet, trinket — a class whose off-hand is hidden shows five plus a blank, per docs/13 §9.1 "hidden, not empty"); each slot is `Widgets.slot_button` with `text` = slot name (walker-readable) and the gear icon; beneath the grid a compact legend of `LabelSmall` rows "Head — Worn Iron Cap · worth 1 G" so the strings `worth`, `empty`, `(+` survive; the "Equip <name> (+N)" Buttons (test_raider_detail.gd:217,239) attach to the legend row. Weapon-slot chrome is a StyleBoxFlat per 06 §2 (1px steel rim, radius 4) added to Theme.gd as "SlotWeapon".
Assets: none new — gear icons come from tools/aseprite/gen_items.lua via Cards.gear_icon.
Acceptance: shot shows the grid beside a 2x portrait; test_raider_detail.gd passes (Equip, "empty", "(+", "Kit").
Needs designer: no.
Verdict: CONFIRMED — RaiderDetail.gd:437-438 adds one `_slot_row` per slot to a VBox and :412-413 sizes the portrait 90x94, the kit-panel crop shows seven stacked rows (the slot boxes are Widgets.SLOT = 47px, not the raw note's 44), the Concept 2 crop shows the tall weapon slot beside a 3x2 grid and spec 06:62 gives it as 62x74; the Fix keeps "Equip …", "empty", "(+" and "worth" in Buttons/Labels as test_raider_detail.gd:190/217/219/239 require.

### HALL-08 · P2 · bug · Kit stat cells print "0 HP / 0 Power / 0 Mana / 0 Damage"
Evidence: RaiderDetail.gd:424-432 (`gear_stats(db)` is gear-only; cells printed as bare totals); shot RaiderDetail.png 350,145,316,90.
Why it matters: "0 HP" on a living raider reads as a bug even when the arithmetic is right; the reference combatant panel shows 48/128-style figures, never zeros.
Fix: label the cells as gear bonuses ("+7 AC", "+0 HP" → or hide zero cells and print "no weapon" under Damage); if a base stat exists in the sim (Combatant.gd), show base + gear. Strings "AC" etc. are not asserted (checked tests/unit/test_raider_detail.gd).
Assets: none.
Acceptance: no bare "0 <stat>" on the fixture shot.
Needs designer: no.
Verdict: CONFIRMED — RaiderDetail.gd:424-432 prints `"%d HP" % stats.hp` etc. from the gear-only `gear_stats(db)`, the kit crop shows "7 AC / 0 HP / 0 Power / 0 Mana / 0 Damage", and no test asserts those cell strings.

### HALL-09 · P2 · polish · The Roster and RaiderDetail sidebars are half empty
Evidence: shot Guildhall.png 1174,440,330,190 (blank between "Tanks 1 · Healers 2 · DPS 8" and the rule at y635); RaiderDetail.png 1174,390,330,270 (blank between Dismiss and Back). Roster.gd:164-192 and RaiderDetail.gd:283-311 fill only the top third. Concept 1's sidebar (1150,84,370,630) is dense: image well, subtitle, rewards row, callout, team row, CTA.
Why it matters: the sidebar is the reference's densest region; an empty one makes the whole screen look unfinished.
Fix: Roster sidebar — under the summary add a morale-band histogram well (ten bars, `Palette.morale_color`, count Labels) and the hall level card (moved here from Facilities' sidebar once HALL-18's art exists). RaiderDetail sidebar — move "On record" (trend Label + `MoraleChart`, RaiderDetail.gd:658-691) under the raider card so the right panel keeps Quarters alone; keep the asserted strings ("Ran 0 raids", "climbing", "over 4 days", "Nothing is written down…", "Wants nothing in particular") in Labels wherever they land.
Assets: none.
Acceptance: no sidebar shows > 120px of empty run between content and the footer buttons.
Needs designer: no.
Verdict: CONFIRMED — Roster.gd:164-192 and RaiderDetail.gd:283-311 are the whole sidebar fill, the two sidebar crops show ~190px and ~270px of empty run above the footer buttons against Concept 1's dense sidebar, and the strings the Fix promises to keep are at RaiderDetail.gd:628-691 as claimed.

### HALL-10 · P2 · bug · Disabled-tab reasons print as a stray full-width sentence under the tab row
Evidence: Guildhall.gd:199-207 (a `row(18)` of two `LabelSmall` reasons); shot Guildhall.png 232,140,906,18 "Raid Group — Chalk tonight's twelve… Records — There is nothing to record…".
Why it matters: it reads as a log line that belongs to nothing; docs/13 §7 wants the reason printed, not a sentence across the panel.
Fix: one VBox per tab (Button over a 12px muted caption with its reason) so each reason sits under its own tab; texts unchanged ("Raid Group", "nothing to record", "Records" are asserted by test_screens.gd:634-808 through `_joined`/`_find_button`).
Assets: none.
Acceptance: no reason text extends past its tab's column.
Needs designer: no.
Verdict: CONFIRMED — Guildhall.gd:199-207 builds one `Widgets.row(18)` of LabelSmall reasons and the tab-row crop shows both reasons running as one sentence across the panel; the docs/13 rule is at docs/13:700 ("a reason string adjacent"), which the per-tab caption satisfies and test_screens.gd:644-808 keep reading via `_joined`/`_find_button`.

### HALL-11 · P2 · polish · The four sub-tabs are four identical buttons, not tabs
Evidence: Guildhall.gd:182-192 (`Widgets.button` per tab; active = gold font + modulate); shot Guildhall.png 232,102,320,30. Spec 10 §4 W18 "in-panel sub-tabs"; game/assets/ui/nav_tab_active.png exists (used by the rail).
Fix: a `Widgets.tab_row()` composite — flat Buttons on a shared baseline rule; the active one carries a 2px gold underline and the nav_tab_active plate; inactive muted; disabled greyed with the caption from HALL-10. Button texts unchanged.
Assets: none new.
Acceptance: shot shows one lit tab with an underline and a baseline rule under the row.
Needs designer: no.
Verdict: CONFIRMED — Guildhall.gd:182-192 makes each tab a `Widgets.button`, the shot shows four identical secondary buttons, spec 10:219 (W18) asks for in-panel sub-tabs and game/assets/ui/nav_tab_active.png exists.

### HALL-12 · P2 · polish · Sort/Filter chips signal state by font colour only, and the filter state is not printed
Evidence: Roster.gd:307-326 (`toggle_mode` Buttons; `_light` changes only `font_color`); :417 prints "Showing %d of %d" with no filter name; shot Guildhall.png 268,172,220,28 and 880,172,258,28. docs/13 §8.5: "Filter state always visible as text: Showing 6 of 17 · At risk".
Fix: a "ButtonChip" theme variation with a real pressed StyleBox (gold rim + lit plate) for toggle buttons; append " · <filter>" to the count Label when a filter other than All is active ("Showing 12 of 12" is asserted by test_rest/test_starting_roster — keep the prefix exact).
Assets: none.
Acceptance: with At risk pressed the shot shows a lit chip and "Showing 1 of 12 · At risk".
Needs designer: no.
Verdict: CONFIRMED — for the filter-name half only: Roster.gd:417 prints "Showing %d of %d" with no filter word against docs/13:339; the "font colour only" half is overstated because `_light` also calls `set_pressed_no_signal` (Roster.gd:323) and Theme.gd:134 gives Buttons a pressed StyleBox, and the tab-row crop shows Morale/All with a lighter rim as well as gold text — the Fix still stands and "Showing 12 of 12" (test_starting_roster.gd:210) survives since the suffix only appears for a non-All filter.

### HALL-13 · P2 · polish · AT RISK is a small caption on a translucent bar, not docs/13 §8.4's stamp
Evidence: Roster.gd:462-483 (88x22 ColorRect + `Widgets.stamp` = a `LabelSectionSm` with a colour, Widgets.gd:116-119); shot Guildhall.png 258,296,60,14. docs/13 §8.4: "StampBadge AT RISK across the row… a stamp carrying a word survives greyscale".
Fix: a stamp composite — PanelContainer with 2px DANGER/CAUTION rim, radius 3, rotation -6°, ink texture (game/assets/ui/wipe_blot.png at low alpha) behind the Label — 100x26 across the portrait's lower edge; Label text stays "AT RISK" / "MAY LEAVE". Static (no tween), so lint_motion is untouched.
Assets: none new (wipe_blot.png exists); optionally a 3-frame stamp texture from tools/aseprite/gen_wipe.lua.
Acceptance: stamp legible when the shot is converted to greyscale (tools/art/cvd.py).
Needs designer: no.
Verdict: CONFIRMED — Roster.gd:471-483 draws an 88x22 ColorRect under `Widgets.stamp`, which Widgets.gd:116-119 shows is a plain LabelSectionSm with a colour override; the card crop shows the small "AT RISK" caption on a translucent bar; docs/13:323 asks for a StampBadge across the row; wipe_blot.png, gen_wipe.lua and tools/art/cvd.py exist and a static stamp leaves lint_motion untouched.

### HALL-14 · P2 · bug · The roster grid scrolls with no visible affordance
Evidence: Roster.gd:140-151 (ScrollContainer, vertical only, default theme bar); shot Guildhall.png x1120..1138,y210..700 shows no scrollbar while 4 of 12 raiders are below the fold. Spec 10 §2 R2: "vertical scroll (or pager in twelves)".
Fix: either theme the VScrollBar in Theme.gd (grabber = bronze rim, 8px) or page in twelves with `Widgets.pager_button` and a "page 1 / 2" Label as RaiderDetail's strip does (RaiderDetail.gd:800-823). With HALL-03 the fold moves to row 3.
Assets: none.
Acceptance: shot shows a bar or a pager whenever rows > visible.
Needs designer: no.
Verdict: CONFIRMED — Roster.gd:140-151 is a vertical ScrollContainer on the default theme and the grid does get a min-size (Roster.gd:433) so it scrolls, yet the x1095..1150 crop shows no bar while row 3 sits below the fold; RaiderDetail.gd:800-823's pager exists as the cited alternative.

### HALL-15 · P2 · bug · LoadSave rows have unequal button widths and print the empty reason twice
Evidence: LoadSave.gd:286-290 `_wrap_reason` sets the reason Label `custom_minimum_size.x = 240`, which widens the `button_with_reason` VBox and stretches only the DISABLED buttons; :219 and :255 give Load and Delete the same reason. Shot LoadSave.png: Slot 1 buttons 260,218,335,34 (tight) vs Slot 2 Load 260,292,238,34 and Delete 630,292,238,34; "Slot 2 is empty." at 260,337 and again at 630,337.
Fix: one fixed width for all nine Buttons (e.g. 200x36); the reason as ONE Label per row under the button row ("Slot 2 is empty." stays — test_loadsave_screen.gd:175 asserts it; the nine Buttons stay — :165); Delete keeps `disabled` with a tooltip rather than a second Label.
Assets: none.
Acceptance: three rows with identical button geometry; each empty-slot phrase appears once; test_loadsave_screen.gd passes.
Needs designer: no.
Verdict: CONFIRMED — LoadSave.gd:286-290 widens every reason Label to 240px inside the `button_with_reason` VBox (Widgets.gd:223-232) and :219/:255 give Load and Delete the same "Slot N is empty."; the LoadSave crop shows tight Slot 1 buttons against 238px disabled Load/Delete on slots 2/3 with the reason printed twice per row; the Fix keeps the nine Button texts and one reason Label (test_loadsave_screen.gd:162-176) — keep that one Label adjacent to both disabled buttons (docs/13:700) rather than tooltip-only for Delete.

### HALL-16 · P2 · polish · LoadSave and Settings panels run the full tall frame with a double rim and large empty runs
Evidence: shot LoadSave.png 260,450,830,530 empty (55% of the panel); Settings.png 260,800,830,185 empty; both show two frame lines at x232..240 (the Frame seam plus PanelWarm's rim at 18px inset — LoadSave.gd:125, Settings.gd:170). M3-SAVE-04 asked for archetype C on the frame, which this is; the finish is what is below the bar.
Fix: see Plate plan — LoadSave panel 572 wide beside a camp band; Settings panel ends at its last row. Collapse the double rim by placing the panel at (0,0) full-window (the seam is the rim) or by dropping the seam for tall screens.
Assets: none.
Acceptance: no more than one rim line at the panel edge; empty run under content ≤ 60px.
Needs designer: no.
Verdict: CONFIRMED — the LoadSave crop shows ~530px of empty panel below the third row and two rim lines at the left edge, the Settings crop shows rows ending ~y792 with the panel running to y985, and both panels are `Widgets.panel("PanelWarm", 18)` at (18,14) sized to the tall host (LoadSave.gd:123-127, Settings.gd:168-173).

### HALL-17 · P2 · polish · Settings value buttons show no state; volume is a bare number; row heights vary
Evidence: Settings.gd:293-355 (`Widgets.button("On"/"Off")`, `"%d"` volume); shot Settings.png 941,164,148,32 … 941,760,148,32 (identical chrome for On, Off, 1x, Keep, 100%, 100, 80); rows 36..40px as notes wrap (y164..792). Spec 06 §7.2: the reference has no switch, so the cycle button is per spec (not a conflict), but the reference's engaged control is tinted warm (06 §7.2 cog/ff row: "icon #E0C8B0 when engaged").
Fix: "On" (and any non-default value) uses the ButtonChip pressed state from HALL-12 (gold text on lit plate); volume rows draw `Widgets.bar()` (Widgets.gd:347) as a 6-step pip strip beside the number Label (the number stays `Button.text` — Settings.gd:340-344's contract); `CTRL_H`/row min-height 40 for every row so the pitch is even. "On"/"Off" exact texts asserted (spec 10 §3.12) — unchanged.
Assets: none.
Acceptance: On rows visibly lit; every row the same pitch; test_settings* pass.
Needs designer: no.
Verdict: CONFIRMED — Settings.gd:293-355 builds every control as `Widgets.button` with the value as its text (VOLUME_STEPS comment at :340-344 states the Button.text contract), the two Settings crops show identical chrome for On/Off/1x/Keep/100%/100/80 and rows of unequal height where notes wrap, spec 06:177 gives the engaged-control tint, and the Fix keeps "On"/"Off"/"%d" as Button.text for tests/unit/test_settings.gd.

### HALL-18 · P2 · missing-asset · Facilities has no picture of the hall's four levels, and its card crops the baked bar
Evidence: Facilities.gd:8-14 (admits the per-level art does not exist), :471-481 (AtlasTexture region 296,250,337,104 of guildhall_plate.png = the bartender and barmaid); sim/core/Comfort.gd:44-50 defines four levels (Leaking / Repaired / Proper / Renowned Guildhall, names asserted by test_comfort.gd). docs/02 §9 Rule of Visible Change; docs/02 §4.5 "exterior before/after thumbnails satisfy R1".
Why it matters: the only purchase on this tab is a building upgrade whose whole pitch is "you will see it"; there is nothing to see.
Fix: a 4-frame strip `game/assets/bg/hall_levels.png` (337x104 each) painted headless in Aseprite (tools/aseprite/lib.lua + a new gen_hall_levels.lua, or hand-painted by the designer), current frame in the sidebar card and next frame under "Next:"; until it exists, crop the bare camp's big tent `Rect2(230,110,337,104)` of stage_camp.png (no figures). Longer term the same four states should appear on the camp plate itself (docs/02 §9.2's obligation table) — that is a Town-cluster item.
Assets: hall_levels.png (4 x 337x104).
Acceptance: the card image changes when `facility_tier` changes; no painted human in the crop.
Needs designer: yes — on the camp plate, WHAT is the guildhall (the big tent? a building that appears at Known?), and what do its four levels look like?
Verdict: CONFIRMED — Facilities.gd:6-14 admits the per-level art does not exist and :476-477 crops guildhall_plate.png at (296,250,337,104), which on the viewed plate is the bar with the painted bartender and barmaid; Comfort.gd:44-51 has the four level names test_comfort.gd:160-163 assert; docs/02:177 (§4.5 thumbnails) and :358-366 (§9.2 obligation table) are as cited, though the Rule of Visible Change itself is docs/02 §2.1 not §9; the big tent sits at stage_camp.png ~(230..470,110..340) as the plan's crop assumes.

### HALL-19 · P3 · bug · The header day chip's icon differs between screens
Evidence: Frame.gd:431-433 (`standard_chips` uses `rank_<name>.png` when present, else sun.png) — used by LoadSave (LoadSave.gd:86); Guildhall.gd:408-409, RaiderDetail.gd:183-184, Settings.gd:400-401, Town.gd:189-190 hand-roll the same four chips with sun.png. Shot LoadSave.png 1272,37,24,24 shows a grey shield; the other three shots show a sun.
Fix: every screen calls `Frame.standard_chips(f, _state)`; delete the five copies. Chip texts ("60 G", "Day 1", "Roster 0 of 15") are unchanged.
Assets: none.
Acceptance: identical chip row on all hall shots.
Needs designer: no.
Verdict: CONFIRMED — Frame.gd:431-433 prefers `rank_<name>.png` (rank_unknown.png exists in icons/) over sun.png and LoadSave.gd:86 calls it, while Guildhall.gd:408-409, RaiderDetail.gd:183-184, Settings.gd:400-401 and Town.gd:189-190 hand-roll sun.png; the LoadSave chip crop shows the grey shield and the other three shots a sun. Fix caveat: Town.gd:191 attaches `_standing_tip()` as the chip's tooltip, so `Frame.standard_chips` needs a tooltip hook (or Town keeps its copy) before the five copies are deleted.

### HALL-20 · P3 · polish · Records rows are text-only
Evidence: Guildhall.gd:296-318 (state word LabelSmall + name + blurb + reward + Claim); Concept 1's Recent Events rows each carry a 24px badge (1060..1080,795..975); game/assets/ui/icons/badge_0..6.png exist and `Cards.badge_icon` maps kinds.
Fix: `log_row`-style icon per state (locked / earned / claimed → badge_x), name in LabelName, and — if Achievements exposes a count toward the record — a thin `Widgets.bar`; state word Label kept (docs/13 §13 two channels; test_screens.gd:728-808 read the wall's strings).
Assets: none new.
Acceptance: each record row has an icon; strings unchanged.
Needs designer: no.
Verdict: CONFIRMED — Guildhall.gd:296-318 builds text-only rows (state LabelSmall, LabelName, blurb, claim control), the Concept 1 strip crop shows a 24px badge on every Recent Events row, icons/badge_0..6.png and `Cards.badge_icon` (Cards.gd:302) exist, and test_screens.gd:741-809 read the wall through `_joined`/`_find_button` so the strings must stay as the Fix says.

### HALL-21 · P3 · polish · The Raid Group tab renders nothing
Evidence: Guildhall.gd:44-45 (disabled with reason); spec 10 §3.2 retires it into RaidPrep but keeps the text; docs/13 §5 S03 lists it as one of four tabs.
Fix (buildable today): make the tab live when `_state.chalked_ids` is non-empty and show the chalked twelve read-only via `Cards.roster_strip`/`Cards.card` with an "Open the board" Button that pushes AdventureBoard; when nothing is chalked keep the current reason. "Raid Group" text stays a Button.
Assets: none.
Acceptance: with a chalked plan the tab shows twelve cards; without, the reason.
Needs designer: yes (small) — keep Raid Group as a read-only view, or delete the tab and record the retirement in docs/13 §5?
Verdict: CONFIRMED — Guildhall.gd:44-45 disables the tab with the chalk-from-the-board reason, spec 10:83 (§3.2) says "Raid Group is retired (its content is RaidPrep)" while 10:262 keeps `Raid Group` as an asserted text, and docs/13:189 still lists it as one of four tabs.

### HALL-22 · P3 · polish · Facilities picker: selected tile has no rim state
Evidence: Facilities.gd:263-288 (GridContainer, 10 columns, ButtonMini 44px — spec 10 R6 is already fixed here; the HBox overflow described in the brief no longer exists in this file), :276 hides the name with an alpha-0 font, :280 dims unselected tiles to 0.55. Spec 06 §2 bronze-bordered portrait slot; selected = gold rim.
Fix: ButtonMini pressed/selected StyleBox with a gold rim (`Palette.rarity_color` chrome reused as state, 06 §2 "Ability-icon… ready abilities carry a gold rim"); keep `Button.text` = name for test_comfort's `_button_named`.
Assets: none.
Acceptance: the chosen tile shows a gold rim in a Facilities shot (no fixture shot exists for this tab — add `Facilities` to tools/shot's fixture list).
Needs designer: no.
Verdict: CONFIRMED — Facilities.gd:263-288 is a GridContainer with PICKER_COLUMNS = 10 (:40) of ButtonMini `slot_button`s, :276 sets an alpha-0 font colour and :280 modulates unselected tiles to 0.55; by code only, since tools/shot_all.sh:22-35 lists Guildhall but no Facilities tab shot; test_comfort presses tiles through `_buttons()` + text (test_comfort.gd:605-614), so keeping Button.text = name is the right constraint.

### HALL-23 · P3 · polish · RaiderDetail's empty record reads as body prose
Evidence: RaiderDetail.gd:628-651 (four `_note` sentences in LabelSmall); shot RaiderDetail.png 726,373,380,120.
Fix: render the "not yet" sentences with `Widgets.empty_state` (faint, centred) and collapse to one block; keep both asserted sentences ("Nothing is written down about them yet", "Wants nothing in particular") verbatim in Labels.
Assets: none.
Acceptance: the block reads as an empty state, not a paragraph.
Needs designer: no.
Verdict: CONFIRMED — RaiderDetail.gd:267-271 `_note` is a LabelSmall and :633-651 emit the "not yet" sentences through it; the Quarters crop shows them as a prose block under "On record"; the Fix keeps both asserted sentences verbatim.

### HALL-24 · P3 · canon-conflict · "Lv. N" appears on four cards and not the other eight
Evidence: Cards.gd:93-95 (line shown only when `level > 0`, per 00 §2.3 "this game has no levels"); tools/fixture_reference.gd:24-29 gives levels only to the four reference raiders; shot Guildhall.png: Tiny "Lv. 11" at 346,255, Spoof "Lv. 10" at 570,255, none on Rhona/Greg/Pip/Cindy/Steve/Hal.
Fix: a ruling, not a copy — either the fixture drops the four levels (cards uniform, canon) or the design adopts a display-only level for everyone. Recorded in art/ref/specs/00-canon-reconciliation.md.
Assets: none.
Acceptance: all cards agree.
Needs designer: yes — keep display-only levels (reference) or none (canon)?
Verdict: CONFIRMED — Cards.gd:92-93 gates "Lv. N" on `level > 0`, tools/fixture_reference.gd:26-29 gives levels only to Bork/Tiny/Gruk/Spoof, the card crop shows Lv. 11/Lv. 10 on Tiny/Spoof and none on the other six, and art/ref/specs/00:51 (§2.3) says canon has no raider levels with `Raider.level` display-only.

### HALL-25 · P3 · polish · LoadSave prints a raw ISO-8601 timestamp and the save-format integer to the player (Added by verifier)
Evidence: LoadSave.gd:201-206 `"Written %s  ·  save format v%d" % [String(row["created_at"]), int(row["save_version"])]` where `created_at` is the UTC `Time.get_datetime_string_from_system(true)` string; shot LoadSave.png 260,105,400,16 reads "Written 2026-09-12T18:37:59 · save format v16" directly under "Slot 1 — A Guild Story, just started".
Why it matters: a T-separated UTC stamp with no timezone plus a format version reads as debug output on the one screen whose rows SaveGame already humanises ("just started"); it is the only machine string on any hall shot.
Fix: format `created_at` as a local date and time ("Written 12 Sep, 18:37") and move "save format v16" to the row's tooltip, or print it only on a blocked/damaged row where the version is the reason. No test asserts "Written" or "save format" (grep of tests/unit/test_loadsave_screen.gd); the row label, the nine Button texts and "Slot N is empty." are untouched.
Assets: none.
Acceptance: no ISO-8601 string on the LoadSave fixture shot; test_loadsave_screen.gd passes.
Needs designer: no.
Verdict: CONFIRMED — added by verifier from LoadSave.gd:201-206 and the LoadSave shot.

### HALL-26 · P3 · polish · The Quarters formula line wraps its last word onto a second line (Added by verifier)
Evidence: RaiderDetail.gd:536-542 builds `"%s  =  %d baseline"` as one autowrapped LabelBody at RIGHT_TEXT_W (423 − 2·24 = 375px, RaiderDetail.gd:67); shot RaiderDetail.png 726,140,380,40 shows "50 base  -5 Common  +0 Guildhall  +0 furnishings  =  45" with "baseline" alone on the next line.
Why it matters: the formula is the panel's headline sentence and its result is the one word that breaks off; the Facilities tab prints the same string (test_comfort.gd:706 asserts "45 baseline").
Fix: keep the whole string in ONE Label (test_raider_detail.gd:252 and test_comfort.gd:706 read it through `_printed`), drop the double spaces around the terms and set the Label to `Widgets.SIZE_META`, or split the terms onto a LabelSmall line above a LabelBody "= 45 baseline" — but only if the two Labels still join to contain "45 baseline".
Assets: none.
Acceptance: the formula and its result sit on one line at 100% text scale in the RaiderDetail and Facilities shots; test_raider_detail.gd and test_comfort.gd pass.
Needs designer: no.
Verdict: CONFIRMED — added by verifier from RaiderDetail.gd:536-542 and the RaiderDetail shot.

## Open questions

1. (HALL-02) Guildhall and RaiderDetail cannot free a camp band at four columns. Margins-only (the plate is a 6-14px frame), or a 3-column roster with a ~250px camp column showing the fire ring? The reference shows four across; the directive wants the real graphics visible.
2. (Plate plan) Settings: inherit the opener's stage (Town → stage_town? — note Town itself stands on stage_camp, so only MainMenu/Tavern/Market/arena screens differ) or always camp? Recommended: inherit, default camp.
3. (HALL-06) Are HSV-derived variant busts (the derive_busts.py technique, 36 generated files) acceptable at the bar, or should 2-3 busts per class be drawn in Aseprite?
4. (HALL-18) What IS the guildhall on the camp plate, and what do its four levels (Leaking / Repaired / Proper / Renowned) look like? docs/02 §9.2 obliges an exterior delta per level; nothing is drawn.
5. (HALL-21) Raid Group tab: read-only view of the chalked twelve, or delete the tab and record it in docs/13 §5?
6. (HALL-24) Display-only levels on every card (reference) or none (canon 00 §2.3)? The fixture currently gives four raiders levels and eight none.
7. (HALL-05, cross-cluster) RaidView.gd:795 picks a morale face by `id.hash() % 10` — the RAID report should own that fix once the face font lands.
8. No fixture shot exists for the Facilities or Records tabs; tools/shot's fixture list should add both so the next audit can see them.

## Files read

game/screens/Guildhall.gd, Roster.gd, Facilities.gd, RaiderDetail.gd, LoadSave.gd (100-299), Settings.gd (150-469), Town.gd (110-230), Tavern.gd (105-135), Market.gd (145-172), RaidPrep.gd (44-52,148-166), AdventureBoard.gd (136-150,180-192), MainMenu.gd (grep); game/ui/Frame.gd (1-62, 277-326, 421-440), SceneStage.gd (outline, 619-651), Cards.gd (27-160), Widgets.gd (40-62, 116-125, 223-252, 309-336, 385-415), Theme.gd (157-217); game/core/GameSettings.gd (194-203), ScreenRouter.gd (outline); game/assets/scenes/stage_camp.json, guildhall.json; game/assets/ui/faces.json; game/assets/actors/actors.json (keys); game/assets/bg/guildhall_plate.png, stage_camp.png; tools/fixture_reference.gd (24-29); sim/core/Comfort.gd (44-62); tools/art/derive_busts.py (docstring); tests/unit/test_screens.gd (grep), a11y_smoke.gd (40-80), test_comfort.gd / test_raider_detail.gd / test_loadsave_screen.gd / test_rest.gd (asserted strings), tools/lint_motion.sh (1-40); art/ref/specs/10-screen-audit.md (§2 R2/R6, §3.2, §3.4, §3.5, §3.12), 09-background-plates.md (§4-§5), 06-ui-component-kit.md (§2, §7), 01-concept1-home-layout.md (§3); docs/13-ui-ux.md (§5, §8, §9.1, §15.1); docs/02 §9; BUILD_STATE.md (55-110); build/plan/audit.json (M3-SAVE-04, M4B-CONV-01, M4B-CONV-03); LESSONS.md (container traps); ideaboard/Reference Concepts/Reference Concept 1/2/3.png; shots Guildhall/RaiderDetail/LoadSave/Settings.png.
