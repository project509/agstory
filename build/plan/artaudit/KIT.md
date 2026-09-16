# KIT — Shared UI kit and chrome audit (2026-09-13)

Report key: KIT. Cluster: game/ui/Frame.gd, Widgets.gd, Theme.gd, Cards.gd, Badge.gd, Bar.gd, Type.gd, Fonts.gd, Palette.gd, game/theme/, game/assets/ui/ and generators tools/aseprite/gen_ui.lua, tools/art/gen_icons.lua, tools/art/gen_wordmark.py.

## Scope

Read in full: game/ui/Frame.gd, Widgets.gd, Theme.gd, Cards.gd, Palette.gd, Type.gd, Fonts.gd, Badge.gd, Bar.gd; SceneStage.gd bubble section (552-611, 718-722). Skimmed with citations: Town.gd, Guildhall.gd, Roster.gd, RaiderDetail.gd, Market.gd, Settings.gd, AdventureBoard.gd, Tavern.gd, RaidPrep.gd, RaidView.gd, Results.gd. Assets: every PNG in game/assets/ui/ and icons/ (montaged at 4x and viewed). Generators: tools/aseprite/gen_ui.lua, tools/art/gen_icons.lua, tools/art/gen_wordmark.py (headers + output lists). Specs: 00 §2, 01 §4.2/§5/§6/§8, 03 §3/§7/§8, 04 §5, 05 (full), 06 (full); docs/13 §3, §4, §7, §8, §12.3; BUILD_STATE "art directive"; audit.json kit-related ids; test contracts (test_screens.gd `_texts`, a11y_smoke.gd, lint_motion.sh).
Shots (1536x1024): MainMenu, Town, AdventureBoard, RaidPrep, RaidView, Results, Guildhall, RaiderDetail, Tavern, Market, LoadSave, Settings, Completion. References: Concept 1, 2, 3.

## Summary

The kit is architecturally right (one Theme, role-named variations, tests read Labels/Buttons) and the textured pieces that exist (CTA, secondary, icon button, nav tab, panels, wordmark) are close to the references. What is below the bar is everything spec 06 §8 calls a composite: the building callout and the speech plate are flat dark rectangles with no icon, chamfer, tail or shadow (P0 on the Town family, the screen the designer looks at first); the header chip row is built five different ways so the day-chip icon flips between a sun and a sigil on every navigation; the widest rail label overruns the rail; the CTA has no overflow guard and clips on Completion. Below that: log badges are vector discs, stamps are plain labels, panels and callouts lack their ornaments, empty states are bare text, pagers are hand-placed per screen and collide with cards, and 45 hex literals live outside Palette.gd. Twenty-two findings: 2 P0, 6 P1, 11 P2, 3 P3. Nine need an asset from gen_ui.lua / gen_icons.lua; three need a designer ruling (rail label, header lockup, reputation icon).

## Kit component inventory

| Component | Where | Exists | Textured / flat | Matches spec 06 | States implemented |
|---|---|---|---|---|---|
| Panel warm / steel | Widgets.panel; Theme.gd:190-195 | yes | textured 9-slice (panel_warm/steel.png 48x48) | §1 partial: no corner ornament, no 6px scene shadow | n/a |
| PanelRound (cards, logs) | Theme.gd:199 | yes | flat 1px #514D4C r6 | §8 partial: reference card rim is a 2px light-outer bevel | n/a |
| PanelInset / PanelCard / well | Theme.gd:203, 207 | yes | flat | §7.1 yes | n/a |
| Item slot (slot / slot_button / slot_rarity) | Widgets.gd:309-340; Theme.gd:232-243, 303-307 | yes | flat | §2 partial: single 2px rim, no bottom/right lit lip (2-box bevel) | ButtonSlot hover only; pressed = normal |
| Portrait slot / ButtonPortrait | Theme.gd:235-247, 288-292 | yes | flat | §2 bronze variant approx (2px vs 3px dark/light/dark) | hover; pressed/disabled = normal |
| Mini slot / ButtonMini | Theme.gd:249-251, 309-313 | yes | flat grey 1px | 01 §4.1 wants the bronze portrait rim | hover/pressed |
| Primary CTA (cta / wax_button, ButtonCta/CtaCost) | Widgets.gd:137-157; Theme.gd:255-271 | yes | textured cta_plate.png 48x48 | §3 partial: states by modulate only (no glow, no inverted gradient, no 1px press offset); no text overflow guard | normal/hover/pressed/disabled/focus |
| Secondary button | Theme.gd:273-279 | yes | textured btn_secondary.png | §7.2 yes | all five |
| Icon button | Widgets.gd:181-188; Theme.gd:281-286 | yes | textured btn_icon.png | §7.2 yes | no disabled style (Theme.gd:284 reuses normal) |
| Text link | Widgets.gd:207-218; Theme.gd:321-326 | yes | theme colours | §7.3 yes; "View All" never placed | hover/focus (underline on focus) |
| Nav rail item | Frame.gd:327-376; Theme.gd:294-301 | yes | textured nav_tab_active.png | §5.1 yes; label overruns the rail | active/hover(40%)/disabled; ink hardcoded |
| Resource chip | Widgets.gd:415-437; Theme.gd:219-221 | yes | textured chip_chamfer.png (all four) | §5.2 deviates by recorded choice (03 §1 chamfer); no thousands separator | n/a |
| Bar (hp/mana/boss) | Bar.gd | yes | _draw | §4 yes | n/a |
| Callout box (verdict) | Widgets.gd:362-378; Theme.gd:209-217 | yes | flat 2px rim | §6 partial: no gradient sweep, no corner flourish | 3 bands |
| Building callout | Widgets.gd:468-502; Theme.gd:227-229 | yes | flat r6 | §8 / 03 §3 NO: no icon, no chamfer, no tail, no shadow | title Button hover/disabled + reason |
| Speech plate (text bubble) | Widgets.gd:452-460; Theme.gd:223-225 | yes | flat r3 | §8 / 03 §7 NO: no tail, no chamfer, no anchor | n/a |
| Emote bubble | Widgets.gd:444-449; speech_bubble.png; SceneStage.gd:552-578 | yes | sprite 33x32 | §8 partial: one sprite, dots drawn by draw_rect, no mug/sweat/skull set | shuffled visibility |
| Log row | Widgets.gd:385-408; Cards.gd:264-300 | yes | HBox + Badge disc or 18px face | §8 partial: reference rows carry pixel icons; Table A log_badges.png not produced | tone colour |
| Badge | Badge.gd | yes | _draw vector disc + typed glyph | n/a (a11y fallback) | n/a |
| Stamp | Widgets.gd:116-119 | yes | plain Label | docs/13 §7 StampBadge NO (no rotation, no worn frame) | n/a |
| Tooltip | Theme.gd:329-331 | theme only | flat | §8 partial: single-string default tooltip, no title+body | n/a |
| Pager | Widgets.gd:162-170 | button only | textured mini | no composite; each screen hand-places | hover/pressed |
| Empty state | Widgets.gd:108-112 | yes | Label | docs/13 §7 partial: no glyph, no hint line, not vertically centred | n/a |
| Roster card | Cards.gd:79-143 | yes | composite on PanelRound | 00 §2.1 morale row yes; class glyph missing; rim flat | action Button inside card (optional) |
| Candidate card (Tavern) | Tavern.gd:270-300 | screen-built | flat | selected rim hand-rolled (Tavern.gd:278) | selected |
| Combatant panel (RaidView) | RaidView.gd:700-760 | screen-built | PanelSteel | §8 partial: "HP" text instead of 24px glyphs; no second bar (canon question DW-C1) | n/a |
| Wordmark / tagline / emblem | Frame.gd:173-208; gen_wordmark.py | yes | pre-rendered PNG | 05 §5 yes | lockup flips per screen |
| Focus ring | Theme.gd:99-102 | yes | flat 2px outside, steel | §12.3 yes (steel by recorded ruling) | every Button family + LinkButton |
| Scrollbar | Theme.gd:332-336 | yes | flat | 01 §4.2 yes | hover/pressed |
| Rank sigils | icons/rank_*.png (gen_icons.lua) | yes (6) | flat silhouettes | 00 §2.5 yes in intent; illegible on the chip | n/a |
| Class glyphs | icons/class_warrior.png | 1 of 9, unused (m4t-02) | pixel 15x12 | 01 §8 #13 wants 9 | n/a |
| Toggle / segmented / slider | Settings.gd:295-349 | missing (cycle Buttons) | textured secondary | not in spec 06; docs/13 §7 SpeedDial | n/a |
| Corner ornament, callout flourish, log badges, emote set, building icons | Table A rows | missing | - | - | - |

## Findings

### KIT-01 · P0 · missing-widget · Building callouts are flat black boxes with no icon, chamfer, tail or shadow
Evidence: Widgets.gd:468-502 (`building_callout`: PanelCallout + two Labels, no icon slot, min width 232), Theme.gd:227-229 (flat #000E17, 1px #625959, radius 6). Town.png "Guildhall / Maintain" (225,293,230,90), "Tavern / Recruit" (640,193,230,90) floating over the tent roof, "Blacksmith" (903,295,240,120) running under the sidebar edge at x=1143 (right rim never visible), "Adventure's Board" (421,581,230,90). Concept 3 "The Tavern" (386,115,224,57): tankard icon at left, 2px warm-grey/dark two-line border, 4px chamfers, 2px drop shadow, 14x8 tail; spec 03 §3 measures all of it; spec 06 §8 row "Building callout".
Why it matters: this is the first component the designer sees on the Town, and it is the one the directive names ("build out the actual working graphics"). The plates read as debug rectangles, and one is clipped.
Fix: (1) gen_ui.lua emits `callout_plate.png` 16x16 9-slice (fill #040E18, border #605A54 outer / #2A2E32 inner, 4px chamfer) and `callout_tail.png` 14x8; (2) Theme `PanelCallout` becomes `tex("callout_plate.png", 6,6,6,6)` plus a 2px shadow layer; (3) `building_callout(name, verb, reason, icon: Texture2D)` gains a 36x32 icon column at fill.x+12 and title/subtitle at x+60 (03 §3 numbers), width = 60 + max(text) + 16, tail child positioned by a new `anchor` argument so Town.gd's BUILDINGS `"at"` becomes the tail apex (building foot) and the plate is clamped inside `Frame.SCENE`; (4) gen_icons.lua authors five 36x32 light-grey building glyphs (hall, tankard, cart/stall, anvil+hammers, notice board). The title stays a Button named "Button" inside "Callout" so `Widgets.button_of` and `test_screens` (`_button_named("Tavern")`) keep working; the reason Label keeps its text for the disabled-Blacksmith test.
Assets: game/assets/ui/callout_plate.png, callout_tail.png (gen_ui.lua); icons/building_{guildhall,tavern,market,blacksmith,board}.png (gen_icons.lua).
Acceptance: Town.png shows five plates with an icon, chamfered two-line rim, shadow and a tail whose apex sits on the building; no plate crosses x=1141; `tools/art/refdiff.py` callout regions vs Concept 3 (386,115,224,57) MAE improves; tests/unit/test_screens.gd town tests (five buildings, Blacksmith disabled with reason) unchanged.
Needs designer: no.
Verdict: CONFIRMED — Widgets.gd:468-502 / Theme.gd:229 build a flat radius-6 plate with no icon, chamfer, tail or shadow; the Town.png crops show four such plates and the Blacksmith plate running under the sidebar edge at x≈1143, and 03 §3 (lines 57-72) measures the tankard icon, 4px chamfer, 2px shadow and the 14×8 tail. Citation slip only: test_screens.gd finds buttons with `_find_button` (exact `Button.text` match, line 338) — `_button_named` lives in test_comfort.gd — so the "Button named Button inside Callout" contract still holds.

### KIT-02 · P0 · missing-widget · The speech plate has no tail or chamfer and floats with no speaker; the emote bubble has one sprite and no glyph set
Evidence: Widgets.gd:452-460 (`speech_plate` = flat PanelBubble, Theme.gd:225, 8px pad, centred text), SceneStage.gd:581-611 (positioned by a JSON `pos`, no anchor). Town.png (515,422,197,76), AdventureBoard.png (751,483,195,72), Tavern.png (771,413,195,75), Completion.png (727,500,192,74) — the last sits over empty ground with nobody near it. Concept 3 (378,373,164,52): same chamfered two-line plate as the callouts with a 14x8 tail on the speaker; Concept 2 "Reloading… again…" (535,343,110,52) with tail; spec 03 §7, 06 §8. Emote: Widgets.gd:444-449 loads the single 33x32 speech_bubble.png; SceneStage.gd:572-576 + 718-722 draws the "…" with three `draw_rect` squares; spec 06 §8 / Table A ask for a 40x44 sprite with mug / ellipsis / sweat / skull variants (Concept 1 mug at 480,470,40,44; face at 1015,575; "…" at 605,302).
Why it matters: the bubbles are the directive's "rendered, animated over a bare plate" replacement for baked dialogue; a tail-less rectangle in the middle of the plate does not read as speech, and a bubble with no speaker reads as a bug.
Fix: `Widgets.speech_plate(text, tail: Vector2 = Vector2.ZERO)` uses the KIT-01 chamfered plate + tail child (a `_draw()` triangle in the border colour with the fill inside, or callout_tail.png), left-aligned 13px text with 19px line pitch (03 §7); SceneStage reads `speech.anchor` (actor id or point) and places the plate so the tail apex is at the speaker's head, hiding the plate when the anchor actor is absent. `Widgets.speech_bubble(kind := "dots")` loads `emote_bubble.png` 40x44 and overlays `emote_<kind>.png` 16x16; SceneStage's bubble entries `[x, y, "mug"]` map to kinds (badge_* icons stay as a fallback). Text stays a Label (test-readable); no tween added, so lint_motion is untouched.
Assets: game/assets/ui/emote_bubble.png (40x44 cream #F4EEDD, 2px outline #2A1E18, 6px tail) + icons/emote_{dots,mug,sweat,skull,zzz}.png — gen_ui.lua / gen_icons.lua.
Acceptance: Town/AdventureBoard/Tavern shots show the plate's tail on an actor's head and at least one emote with a glyph other than dots; Completion shows no orphan plate; the SceneStage `from_data` unit test gains an assert that a speech entry with an anchor yields a node named "Tail".
Needs designer: no.
Verdict: CONFIRMED — `speech_plate` is a flat PanelBubble (Widgets.gd:452-460, Theme.gd:225) placed by JSON `pos` with no anchor (SceneStage.gd:590-607); the Town/AdventureBoard/Tavern/Completion crops show tail-less rectangles, Completion's over open ground; Concept 3 (03 §7 line 156: 14×8 tail) and Concept 2 plates carry tails; the emote is one 33×32 sprite plus `draw_rect` dots (SceneStage.gd:572-576, 718-721) against 06 §8 line 198's 40×44 mug/ellipsis/sweat/skull set. `SceneStage.from_data` is exercised by tests/unit/test_scene_stage.gd:40, so the acceptance assert has a home.

### KIT-03 · P1 · bug · Five screens hand-build the header chip row with sun.png; the day-chip icon flips between sun and rank sigil on every navigation
Evidence: Frame.gd:421-434 (`standard_chips`: rank sigil, sun only as fallback) vs Guildhall.gd:399-409, Market.gd:224-234, RaiderDetail.gd:174-184, Settings.gd:391-401, AdventureBoard.gd:265-275 (own builders, `sun.png`); Town.gd:178-190, Tavern.gd:175-185, RaidPrep.gd:184-192 keep dead duplicates beside their `standard_chips` call. Town.png chip 4 (1244,15,277,45) shows the dark shield sigil; Guildhall.png / Market.png / Settings.png / AdventureBoard.png / RaiderDetail.png show the sun. Spec 00 §2.5 and 06 §5.2: sun replaced by the rank sigil.
Why it matters: the header is the one thing on every screen; an icon that changes per screen reads as broken.
Fix: delete the eight per-screen builders and call `Frame.standard_chips(f, _state)`; keep the literal strings "60 G", "Day 1", "Roster 0 of 15" in Labels (test_screens.gd asserts them).
Assets: none.
Acceptance: `grep -rn 'sun.png' game/screens` returns nothing; all thirteen shots show the same chip 4 icon; test_screens chip assertions pass.
Needs designer: no.
Verdict: CONFIRMED — the five `_chips` builders are live (AdventureBoard.gd:113, Guildhall.gd:138/389, Market.gd:341, RaiderDetail.gd:123, Settings.gd:151) and load sun.png; Town/Tavern/RaidPrep call `Frame.standard_chips` and keep uncalled `_chips` copies; chip-4 crops show the shield sigil on Town/Tavern/RaidPrep/LoadSave and the sun on the other five. Fix caveat: the dead Town.gd:189-191 is the only place the rank-standing tooltip (`_standing_tip()`) is ever attached — port it into `standard_chips` before deleting the builders (see KIT-23).

### KIT-04 · P1 · bug · "Adventure's Board" overruns the nav rail
Evidence: Frame.gd:367-375 (child Label at x=73, width RAIL_W-73 = 134px, Type.NAV = 18); Type.gd:21 claims it fits at <= 18px; AdventureBoard.png (73,340,150,25) — glyphs end at x≈221, past the rail edge (208) and the active tab's chamfer; same on Town.png / Tavern.png / Market.png (73,340). Spec 01 §6 flags exactly this label.
Why it matters: text crossing a panel edge on every screen of the hall family.
Fix: interim — set the child Label `text_overrun_behavior = TRIM_ELLIPSIS` (`clip_text = true`) so nothing paints past x=206; real fix is a designer choice (below). The Button's own `text` stays "Adventure's Board" (four tests press it by that string).
Assets: none.
Acceptance: no label pixel right of x=206 in the rail band on any shot; test_screens / test_full_loop `"Adventure's Board"` presses still pass.
Needs designer: yes — the rail label for the board: (a) "Board" on the rail only, (b) two-line "Adventure's / Board", or (c) rail type at 16px for all items.
Verdict: CONFIRMED — Frame.gd:367-375 gives the child Label x=73 and RAIL_W-73=134px at Type.NAV=18, and the 3× rail crops show the glyphs of "Adventure's Board" ending at x≈220, past the x=208 rail edge and the active tab's chamfer, on AdventureBoard/Town/Tavern/Market; 01 §6 line 142 names exactly this label. `clip_text`/TRIM_ELLIPSIS on the child Label changes drawing only, so `Button.text` and `Label.text` stay intact for the tests.

### KIT-05 · P1 · bug · CTA text overflows the plate
Evidence: Widgets.gd:137-157 (`cta` sets no `autowrap_mode`/`text_overrun_behavior`); Completion.png (1176,905,348,62) — "Back to town — the guild carries on" runs 1183..1517, touching both rims.
Why it matters: the commit button is the most-designed control on the screen and it is the one that clips.
Fix: in `cta()` set `b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` and `text_overrun_behavior = TRIM_ELLIPSIS`, and let `custom_minimum_size.y` grow to 88 when the label wraps; Completion passes "Back to town" with the subline "the guild carries on" via the existing `subline` argument (test presses by fragment "Back to town").
Assets: none.
Acceptance: Completion.png label inset >= 12px from both rims; no other CTA changes height at scale 100 (pixel baselines unchanged); test_text_scale still passes at 150%.
Needs designer: no.
Verdict: CONFIRMED, Fix corrected — `cta()` sets no overrun guard (Widgets.gd:137-157) and the Completion crop shows the label inset only ≈5px into the 14px rim band on both sides (tight, not yet clipped, so "overflows" overstates it); BUT test_screens.gd:547 locates the button by the exact string "Back to town — the guild carries on" through `_find_button` (== match, line 338), so splitting it into "Back to town" + subline breaks that test. Corrected Fix: keep the full `Button.text`, add the autowrap/ellipsis guard and the taller plate, and if the string is shortened change test_screens.gd:547 in the same commit.

### KIT-06 · P1 · bug · Guildhall card actions and their reason sit outside the card frame
Evidence: Roster.gd:507-529 builds "Cheer up" (button_with_reason) and "Manage" as siblings under the card; Guildhall.png card frame (231,210,213,260) ends at y=470, buttons at (232,477,143,30)+(388,477,52,30), "They are fine." at (680,512) under a different card's column. Cards.gd:135-140 already supports one in-card `action` (RaidPrep's "Bench", RaidPrep.png 155,952,185,30, sits inside the rim).
Why it matters: the roster is where players live; detached buttons and a stray sentence read as a layout fault.
Fix: `Cards.card(raider, db, actions: Array)` — each `{"text","on","reason"}` rendered in a bottom band inside the card (HBox; the reason as the existing `faint` Label under the row); Roster.gd and RaiderDetail.gd:327-335 pass their pairs. The `button_with_reason` box and its "Button" child name are kept so `Widgets.button_of` and the tests find "Cheer up".
Assets: none.
Acceptance: Guildhall.png buttons and reason inside the card rim; test_screens roster tests unchanged.
Needs designer: no.
Verdict: CONFIRMED, cites corrected — the sibling placement is Roster.gd:485-494 (`acts` row at CARD_H+4 beneath the card; 502-535 are only the two builders) and the Guildhall crop shows Cheer up/Manage below each card rim; "They are fine." sits under the third card's own disabled Cheer up (x≈677, that card's column), not "a different card's column". Roster.gd:450 records the beneath-the-card placement as a deliberate docs/13 OQ-4 reading, so this is a polish call, not a layout bug.

### KIT-07 · P1 · polish · Log badges are vector discs, not the reference's pixel icons
Evidence: Badge.gd:136-151 (`draw_circle` + highlight + typed glyph); Widgets.gd:385-408 uses it whenever no icon is passed; Cards.gd:297-300 maps only two kinds (badge_0 / badge_5 faces). RaidView.png (1052,805,18,18), Results.png (1092,835,18,18) show red/purple discs; Concept 1 rows (1074,786,22,22 each) and Concept 2 (1075,762) carry drawn icons per event class. Spec 06 §8 log row; Table A `ui/log_badges.png` (frown, gem, star, skull, check, coin) never produced; audit M6-A11Y-07.
Why it matters: the log is the raid's narrative; discs make every row look the same at a glance.
Fix: gen_icons.lua authors 22x22 `log_<kind>.png` keyed by Enums.Verb / event kind (mistake, heal, raider_attack, boss_attack, mechanic, phase, system, morale_up, morale_down, loot, gold, recruit); `Widgets.log_row(text, tone, badge, icon, kind := "")` resolves `icons/log_<kind>.png` and keeps Badge as the fallback (its glyph stays the a11y second channel).
Assets: game/assets/ui/icons/log_*.png (12).
Acceptance: RaidView and Results log rows show pixel badges; `_texts()` output unchanged; a11y contrast of each badge vs #020C14 >= 3:1.
Needs designer: no.
Verdict: CONFIRMED — Badge.gd:136-142 draws discs, Widgets.gd:397-402 falls back to Badge whenever no icon is passed, Cards.gd:297-300 maps only two kinds; the RaidView/Results crops show red discs while the Concept 1/2 rows carry drawn icons; 06 §8 line 199 and Table A `ui/log_badges.png` (frown, gem, star, skull, check, coin) exist and no such file is in game/assets/ui (15 files); audit M6-A11Y-07 says the same.

### KIT-08 · P1 · polish · Empty states are a bare 13px line in a 474x262 void
Evidence: Widgets.gd:108-112 (`empty_state`: LabelSmall, centred, no glyph, not vertically centred); Cards.gd:259-260; 26 call sites. Town.png / Guildhall.png / Market.png / RaiderDetail.png Recent Events (1045,734,474,262) show "Nothing has happened yet." at y=778 with 200px of nothing beneath; RaidPrep.png "Bench 0" panel (14,734,108,262) shows nothing at all.
Why it matters: on a fresh guild every dashboard screen has this panel, and it is a quarter of the strip.
Fix: `empty_state(text, glyph := "quill", hint := "")` returns a VBox with a 32px muted icon, the text Label, and an optional hint Label, `size_flags_vertical = EXPAND_FILL` + centre alignment; Cards.event_log passes hint "Raids and rests write here."; roster_strip's grid pads with `seats` so an empty bench shows empty slots.
Assets: icons/empty_{quill,bench,shelf}.png 32x32 (gen_icons.lua).
Acceptance: empty log shows glyph + text centred in the panel; the Label text strings are unchanged for the 26 tests that read them.
Needs designer: no.
Verdict: CONFIRMED — Widgets.gd:108-112 returns a centred LabelSmall with no vertical expand; the Town/Guildhall crops show "Nothing has happened yet." at the panel top over ~200px of empty panel and RaidPrep's "Bench 0" panel is blank. Call-site count is 25, not 26 — immaterial.

### KIT-09 · P2 · polish · Panels have no corner ornament and the callout box has neither its gradient nor its flourish
Evidence: Theme.gd:190-195 (9-slice only); no panel_corner_ornament.png / callout_flourish.png in game/assets/ui; Widgets.gd:362-378 + Theme.gd:209-217 (flat plate, 2px rim). Concept 1 sidebar corners (1143,74,16,16 x4) and callout (1181,393,320,81: horizontal gradient to #3B141A, flourish at 1478,393,18,14); ours RaidPrep.png (1174,400,340,85) flat #08080C. Spec 06 §1 corner ornament, §6, Table A rows 6-7.
Why it matters: the ornaments are what make the reference chrome read as crafted rather than boxed.
Fix: gen_ui.lua authors both sprites (white-on-alpha flourish tinted by band); `Widgets.panel` overlays four 16x16 TextureRects on PanelWarm/PanelSteel (never baked in the 9-slice); `callout()` adds a `GradientTexture2D` plate (Table B) and the flourish top-right.
Assets: game/assets/ui/panel_corner_ornament.png, callout_flourish.png.
Acceptance: refdiff sidebar (1143,74,377,645) and callout regions vs Concept 1 improve; panel content rects unchanged.
Needs designer: no.
Verdict: CONFIRMED — Theme.gd:190-195 is a 9-slice only and Widgets.gd:362-378 + Theme.gd:209-217 a flat plate with a 2px rim; neither panel_corner_ornament.png nor callout_flourish.png exists in game/assets/ui; 06 §1 line 30 (corner ornament), line 22 (6px scene shadow), §6 lines 158-159 (gradient + flourish) and Table A list them; the Concept 1 callout crop shows the red sweep and the top-right flourish, RaidPrep's is flat.

### KIT-10 · P2 · polish · 45 hex colours live outside Palette.gd
Evidence: Theme.gd:199, 203, 207, 211, 225, 229, 234, 237, 240, 243, 247, 251, 260, 270, 278, 288-289, 297, 300, 303-304, 309, 329, 332-335; Frame.gd:145, 157, 169, 203, 225, 362, 370; Bar.gd:39-40, 48, 50, 88-89; Widgets.gd:338; Badge.gd:48; SceneStage.gd:721; Tavern.gd:278 (a hand-rolled selected-card rim). docs/13 §3 ("screens name a role, never a hex"); spec 04.
Why it matters: retuning the palette (the directive's "designed beautifully") currently means editing seven files; the Tavern's selected state cannot be reused by the Roster.
Fix: add roles to Palette.gd (SURFACE_CARD, EDGE_CARD, EDGE_WELL, SURFACE_BUBBLE, EDGE_BUBBLE, EDGE_CALLOUT, SLOT_RIM, SLOT_RIM_LIT, BAR_RIM, BAR_TRACK, INK_NAV, INK_NAV_ACTIVE, EDGE_RAIL_CORE, HEADER_DIVIDER, SCROLL_TRACK/THUMB, INK_BUBBLE_DOTS) with the same hexes; add `PanelRoundSelected` to Theme and use it in Tavern.gd; add a lint line to tools/lint_motion.sh (pattern `Color\("` with Palette.gd and generators allowed).
Assets: none.
Acceptance: `grep -rn 'Color("' game --include=*.gd | grep -v Palette.gd` is empty; art-gate pixel baselines unchanged.
Needs designer: no.
Verdict: CONFIRMED — `grep 'Color("' game --include=*.gd | grep -v Palette.gd` returns 46 (Theme 29, Frame 7, Bar 6, Widgets 1, Badge 1, SceneStage 1, Tavern 1); the report's list misses Theme.gd:164 (`Color("413D3A")`, the wordmark outline), hence 45. docs/13 line 84 keeps "screens name a role, never a hex". The lint addition fits lint_motion.sh's `check` (comments are stripped first).

### KIT-11 · P2 · polish · Button states stop at modulate; pressed has no press, several families have no disabled/pressed box, the CTA rim runs hot
Evidence: Theme.gd:255-258 / 273-276 (hover x1.18-1.22, pressed x0.8, disabled x0.5 modulate of one texture); spec 06 §3 states table (hover = plate one step + 6px #F27043 glow; pressed = inverted gradient + 1px content offset; disabled = desaturated rim #5A3A3E); docs/13 §12.3 (pressed = 1px inward + 4% darken). Theme.gd:284 ButtonIcon disabled = normal; :290 ButtonPortrait pressed/disabled = normal; :305 ButtonSlot pressed = normal. MainMenu.png "New Guild" (124,452,332,60): the 3px salmon/red rim reads brighter than Concept 1's (1179,617,305,69) where the rim is red with only a 1px gold top highlight.
Why it matters: press feedback is the "feel" line of the directive; a modulate-only press reads as a flicker.
Fix: gen_ui.lua emits `cta_plate_pressed.png` / `btn_secondary_pressed.png` (gradient inverted) and softens cta_plate's inner rim to #B86353; pressed boxes get `content_margin_top += 1`; hover gets an outer glow via a second 9-slice `cta_glow.png` (expand_margin 6, modulate α0.3); disabled boxes for ButtonIcon/ButtonPortrait/ButtonSlot (modulate 0.5). No tween involved.
Assets: game/assets/ui/cta_plate_pressed.png, btn_secondary_pressed.png, cta_glow.png.
Acceptance: `tools/art/shot --fixture` with a hovered/pressed CTA shows the glow and the 1px drop; focus ring unchanged.
Needs designer: no.
Verdict: CONFIRMED — Theme.gd:255-258 / 273-276 are modulate-only states of one texture; :284 ButtonIcon disabled = ico_n, :290 ButtonPortrait pressed/disabled = ps, :305 ButtonSlot pressed = slot_b; 06 §3 lines 96-98 specify the 6px #F27043 glow, inverted gradient with +1px offset and #5A3A3E disabled rim, and docs/13 §12.3 line 699 "1px inward offset + 4% darken"; the MainMenu crop's rim is a bright salmon against Concept 1's darker red with a gold top edge.

### KIT-12 · P2 · bug · Pagers are hand-placed per screen and collide with cards
Evidence: Widgets.gd:162-170 supplies only the arrow button; RaidPrep.gd:493-508 places the label at (127,242) and arrows at (800/840,232) inside the strip where card 4 spans x 807-1022 → RaidPrep.png arrows (815,965,75,32) over card 4, "Tonight's 12 · page 1/3" (140,984) over card 1's bottom rim; Results.png arrows stacked in the 20px gap (1028,745,28,60); RaiderDetail.png pager inside the Available panel (30,950,85,40); RaidView.png below the strip (28,990). Four screens, four layouts.
Why it matters: overlapping controls on the raid-prep strip, the screen docs/13 §10 calls "the screen that carries the game".
Fix: `Widgets.pager(page, pages, on_prev, on_next, caption)` composite (HBox ‹ caption ›, 28px) and `Cards.roster_strip(... pager_host)` reserving a 30px band under the Available grid (the RaiderDetail placement) so cards never share pixels with it; the four screens call it.
Assets: none.
Acceptance: no pager rect intersects a card rect in RaidPrep/Results/RaiderDetail/RaidView shots; tooltip "Next page" retained; tests that press the arrows unchanged.
Needs designer: no.
Verdict: CONFIRMED — RaidPrep.gd:493-507 places the label at (127,242) and the arrows at (800/840,232) strip-relative, inside card 4's span (812..1027) and over card 1's bottom rim, which the RaidPrep crop shows; Results.gd:768-785, RaiderDetail.gd:803-819 and RaidView.gd:628-640 each lay the pager out differently. Omission: Tavern.gd:250-263 is a fifth hand-placed pager (same layout as RaidPrep), so "four screens" undercounts.

### KIT-13 · P2 · polish · The header lockup changes size between screens
Evidence: Frame.gd:189-208 (tagline → 44px wordmark at baseline 50; otherwise 58px at baseline 60); only Town.gd:108 passes the tagline. Town.png lockup (104,20,270,55) + tagline vs Guildhall.png (104,12,305,60) and every other archetype-A shot; MainMenu.png also carries the tagline. Both are reference-faithful (01 §5 vs 03 §6); the flip on navigation is not.
Why it matters: the wordmark visibly resizes on every screen change.
Fix: one lockup for all archetype-A screens (`Frame.build` default `tagline` from a constant), the compact one kept for archetype B (RaidView/Results, already compact).
Assets: none.
Acceptance: header region (0,0,400,74) pixel-identical across the eleven archetype-A shots.
Needs designer: yes — tagline on every hall screen (Concept 3 / MainMenu) or on none (Concept 1)?
Verdict: CONFIRMED — Frame.gd:189-193 picks wordmark_44 (baseline 50) or wordmark_58 (baseline 60) by the `tagline` opt, and Town.gd:108 is the only screen passing it; the header crops show Town at the compact lockup with tagline and Guildhall/Market at the full mark; MainMenu.gd:91 draws its own tagline lockup in the hero block (not the header band), as the report says.

### KIT-14 · P2 · canon-conflict · The reputation chip is a gem with a bare number
Evidence: Frame.gd:428 (`gem.png`, ACCENT_GEM, "%d"); Town.png (855,15,107,45) "320" with a violet crystal. Canon: no gems (designer, 2026-09-13; 00 §2.5 records "the gem icon stays" for Reputation). Nothing on screen names the number; a player reads a gem as a currency.
Why it matters: the designer listed "no gems" among the places the design wins; the recorded ruling kept the reference's gem art.
Fix: ask; likely a reputation device (laurel / guild seal, gen_icons.lua 26x26) and tooltip "Reputation 320 — 0 to Known" on the chip. Strings stay in a Label.
Assets: icons/reputation.png if ruled.
Acceptance: chip 2 reads as reputation without a tooltip in a 2-second test.
Needs designer: yes — keep the gem icon (00 §2.5) or replace it with a reputation sigil; and whether the chip carries the word "Rep".
Verdict: CONFIRMED — Frame.gd:428 uses gem.png with a bare "%d" and the Town chip crop shows a violet gem beside "320"; 00 §2.5 line 59 records canon as "no gems" and line 61 keeps the gem icon anyway. The "designer, 2026-09-13" attribution could not be found; the nearest source is the 2026-09-10 rule (memory: reference concepts are a standard) that lists gems among the reference elements that break canon.

### KIT-15 · P2 · polish · No thousands separator anywhere
Evidence: Frame.gd:427 ("%d G"), Widgets.gd:137-157 subline, Market.gd rows; Town.png (690,25,120,25) "12480 G"; Concept 1 "12,480" and "2,400"; docs/13 §4.3 ("Gold shows 1,240g", separator from the string table, never hard-coded). Tests assert "60 G" only.
Why it matters: the numeral rule is marked non-negotiable in docs/13 §4.3.
Fix: `Type.num(n)` / `Type.gold(n)` formatter (locale from GameSettings, default en-US) used by chips, CTA cost, Market, Results tally.
Assets: none.
Acceptance: chip shows "12,480 G"; test_screens "60 G" and "Roster 0 of 15" still match.
Needs designer: no.
Verdict: CONFIRMED — Frame.gd:427 formats "%d G"; the Town chip crop reads "12480 G" against Concept 1's "12,480"; docs/13 §4.3 (heading line 156 "non-negotiable", row line 164) requires the locale thousands separator.

### KIT-16 · P2 · missing-asset · Rank sigils are flat silhouettes that vanish on the chip
Evidence: icons/rank_unknown.png (28x28 dark grey shield, no rim or device), rank_known.png (brown); Town.png / RaidPrep.png / Tavern.png / LoadSave.png chip 4 icon (1262,25,28,28) barely separates from the chip fill #020B12; Concept 1's chip icons are lit 26-29px sprites (01 §8 #2-#5).
Why it matters: the chip that names the guild's rank shows a blot.
Fix: gen_icons.lua re-authors six sigils with a 1px cream rim and a device per rank (blank shield, chevron, two chevrons, star, laurel, crowned skull), tints TEXT_MUTED → ACCENT_GOLD up the ladder.
Assets: icons/rank_{unknown,known,established,respected,renowned,legendary}.png.
Acceptance: each sigil's rim vs #020B12 >= 3:1 (tools/art/cvd.py); chip text unchanged.
Needs designer: no.
Verdict: CONFIRMED — rank_unknown.png is a 28×28 dark grey shield with no rim or device, and the 4× chip-4 crops of Town/RaidPrep/LoadSave show it barely lifting off the chip fill, against Concept 1's lit sun (01 §8 line 120); tools/art/cvd.py exists for the acceptance measurement.

### KIT-17 · P2 · missing-asset · Combatant bars carry "HP" text instead of the reference's status glyphs
Evidence: RaidView.gd:741-746 (LabelSmall "HP" at x=12, bar at x=38); RaidView.png (35,838,25,17); Concept 2 (35,838,24,24 shield #E8433A; 35,862 drop #3DA5D8); spec 06 §8 combatant panel.
Why it matters: the combat strip is the "combat UI designed beautifully" line of the directive.
Fix: gen_icons.lua `bar_hp.png` (24x24 shield) and `bar_focus.png` (drop); RaidView swaps the Label for a TextureRect with `tooltip_text = "HP"`. A second bar waits on the Focus ruling (DW-C1) and is not decided here.
Assets: icons/bar_hp.png, bar_focus.png.
Acceptance: RaidView panel shows the glyph left of the bar; Bar.gd unchanged.
Needs designer: no.
Verdict: CONFIRMED — RaidView.gd:741-746 places a LabelSmall "HP" at x=12 and the bar at x=38; the RaidView crop shows the text and the Concept 2 crop a red shield and blue drop glyph left of the bars; 06 §8 line 195 specifies 24px status glyphs.

### KIT-18 · P2 · polish · Stamps are plain red labels
Evidence: Widgets.gd:116-119 (`stamp` = LabelSectionSm in DANGER); Results.png "FALLEN" (185,745,55,20), Guildhall.png "AT RISK" (262,297,55,16); docs/13 §7 StampBadge (rotated 2-7°, ~70% opacity, worn edges, word always also readable); wax_seal.png / wipe_blot.png exist and only RaidView uses them.
Why it matters: the stamp is the game's failure vocabulary and it currently looks like a warning label.
Fix: `stamp()` returns a Control: a `stamp_frame.png` (rough 1px double outline, gen_ui.lua) with the Label inside, `rotation_degrees` 4, `pivot_offset` centre, modulate α0.85. No tween. Label text unchanged.
Assets: game/assets/ui/stamp_frame.png (9-slice 24x24).
Acceptance: Results shot shows rotated framed stamps; `_texts()` still yields "FALLEN", "AT RISK".
Needs designer: no.
Verdict: CONFIRMED — Widgets.gd:116-119 is a tinted LabelSectionSm; the Results "FALLEN" and Guildhall "AT RISK" crops are plain labels (Roster.gd:471-483 adds only a translucent backing); docs/13 §7 line 247 defines StampBadge as rotated 2-7°, ~70% opacity, worn edges; wax_seal/wipe_blot are referenced only by RaidView.gd. The Fix keeps the Label text (safe for `_texts()`) and adds no tween.

### KIT-19 · P2 · polish · Roster card finish is below the reference: flat rim, no class glyph, grey mini-grid
Evidence: Theme.gd:199 (PanelRound 1px #514D4C) vs Concept 1 card (140,735,244,261: 2px light-outer bevel #88786C/#4D4A47, fill #000A12→#030D17; spec 06 §8); Cards.gd:94-95 class row is text only vs Concept 1 "⚔ Warrior" (259,797,15,12), only icons/class_warrior.png exists and nothing loads it (audit m4t-02); Cards.gd:186-191 / Theme.gd:249-251 mini-grid uses a grey 1px rim vs the reference's bronze portrait rim (01 §4.1, 06 §2 bronze variant at ~40px; Concept 1 24,780,40,40).
Why it matters: four cards are on every dashboard screen.
Fix: `PanelCard` warm variant with the bevel (two StyleBoxFlats or `card_warm.png` 9-slice from gen_ui.lua); gen_icons.lua authors nine 16x16 class glyphs and `Cards.card` puts one before the class Label; SlotMini/ButtonMini take the SlotBronze rim at 37px.
Assets: game/assets/ui/card_warm.png; icons/class_{warrior,monk,rogue,cleric,druid,shaman,bard,mage,wizard}.png.
Acceptance: refdiff card region (140,734,215,262) MAE drops; Label "Warrior" text unchanged.
Needs designer: no.
Verdict: CONFIRMED in part — class glyph: Cards.gd:94-95 is text only, nothing in game/ loads icons/class_warrior.png (the `class_%s.png` loads are portraits/), and the Concept 1 crop shows the crossed-swords glyph before "Warrior"; card rim: 06 §8 line 194 does say 2px light-outer #88786C/#4D4A47, but 01 §3 line 74 measures the same card as 1px core #514D4C, which Theme.gd:199 implements — a spec conflict to record, not a clear defect; mini-grid: REFUTED — 01 §4.1 line 92 measures the Available cells as a 1px #35393E rim on #0F151E, exactly Theme.gd:251, and the Concept 1 crop shows that grey rim, so drop the SlotBronze-at-37px part of the Fix.

### KIT-20 · P3 · missing-widget · Settings has no toggle, segmented control or slider — every value is a cycling button
Evidence: Settings.gd:295-349 (`Widgets.button("On"/"Off")`, "%d" for audio, `_cycle_button`); Settings.png right column (941,165,148,30 x17). docs/13 §7 SpeedDial; §15.1 inventory.
Why it matters: a row of identical bronze buttons hides which values are booleans, choices or ranges.
Fix: `Widgets.toggle(on)` (Button with knob StyleBox, text kept "On"/"Off"), `Widgets.segmented(labels, idx)` (HBox of Buttons, active on nav-tab chrome), `Widgets.slider_row(value)` (HSlider themed: grabber = 16px rivet sprite, track = Bar chrome, plus a value Label). Tests read Button.text and Label.text as before.
Assets: icons/slider_grabber.png.
Acceptance: Settings shot shows three distinct control shapes; a11y_smoke Tab walk still reaches every row.
Needs designer: no.
Verdict: CONFIRMED, ruling needed — Settings.gd:293-349 builds every row from `Widgets.button` (toggle/cycle/choice/volume) and the Settings crop shows seventeen identical bronze buttons; docs/13 §7 line 256 lists SpeedDial. But Settings.gd:332-344 records the cycle button as a deliberate choice ("the reference has no slider and no switch (06 §7)"; a slider would be unreadable by the test contract), and the standing rule is that the design wins where the references lack a widget — so "Needs designer: no" should be "yes". An HSlider is FOCUS_ALL by default, so a11y_smoke's walk is unaffected if the value Label stays.

### KIT-21 · P3 · polish · "View All" link on the events log is never placed
Evidence: Cards.gd:252-256 (head row has only the title); Type.gd:33 reserves LINK for it; spec 03 §8 / 01 §4.2 measure it (1441,752,47,11, underlined). Only two `Widgets.link` call sites exist in game/screens.
Why it matters: the reference's only underlined text; its absence leaves the log header unbalanced.
Fix: add `Widgets.link("View All", true)` right-aligned in the head row, routed to the Records tab (M5-QAB-3) or disabled with the reason until it exists.
Assets: none.
Acceptance: log header shows the link at the panel's right inner edge; LinkButton text readable by tests.
Needs designer: no.
Verdict: CONFIRMED, citation corrected — Cards.gd:252-256's head row holds only the title and Type.gd:33 reserves LINK; the link is measured by 03 §8 lines 161-167 (Concept 3, 1441,752 47×11, underlined, "Absent on C1 — add it there too"), NOT by 01 §4.2 — Concept 1 has no link, as the C1 crop at that rect confirms; and there is one `Widgets.link` call site (AdventureBoard.gd:374), not two.

### KIT-22 · P3 · polish · Tooltips are the default single-string panel
Evidence: Theme.gd:329-331 (TooltipPanel + TooltipLabel only); 16 `tooltip_text` sites (Cards.gd:127, 213; RaidView.gd x6; Market.gd x2 …); spec 06 §8 designs title (16px cream) + body (14px muted), max width 260, chamfer 3, 300ms.
Why it matters: item and mechanic tooltips are where the numbers live on the raid screen.
Fix: `Widgets.tooltip_for(control, title, body)` overriding `_make_custom_tooltip` through a small `TooltipHost` subclass for slots and mechanic icons; keep `tooltip_text` set (a11y / tests).
Assets: none.
Acceptance: hovering a gear slot in a shot shows the two-line tooltip inside the frame.
Needs designer: no.
Verdict: CONFIRMED — Theme.gd:329-331 styles only TooltipPanel/TooltipLabel; 16 `tooltip_text` sites (15 outside Widgets.gd plus the pager); 06 §8 line 200 designs the title + body tooltip at max width 260, 300ms (it says chamfer 4, not 3 — trivial).

### KIT-23 · P2 · bug · The rank-standing tooltip on the day chip is dead code (Added by verifier)
Evidence: Town.gd:189-191 attaches `day.tooltip_text = _standing_tip()` inside `Town._chips()`, but nothing calls `_chips` — Town.gd:113 builds the header with `Frame.standard_chips(f, _state)`, which sets no tooltip (Frame.gd:431-434). `_standing_tip()` (Town.gd:195-202: "N reputation · M more to <rank>") is therefore never shown on any screen; the "highest standing" string test_screens.gd:415 asserts comes from the sidebar Label at Town.gd:270, not the tooltip.
Why it matters: it is the only place the header tells the player what the rank chip means and how far the next rank is; KIT-03's fix ("delete the eight per-screen builders") would silently remove it.
Fix: move `_standing_tip` into `Frame.standard_chips` (or a `Frame.standing_tip(state)` helper) and set it on the day chip there, so every archetype-A screen carries it; then delete the dead builders per KIT-03.
Assets: none.
Acceptance: `grep -rn "_standing_tip" game` resolves to one live call reached from `standard_chips`; a unit test asserts the Town day chip's `tooltip_text` contains "reputation".
Needs designer: no.
Verdict: CONFIRMED — Added by verifier; Town.gd:113 vs 176-191 and Frame.gd:421-434 read directly.

## Open questions

1. KIT-04: what does the rail say for the board — "Board", a two-line label, or 16px rail type?
2. KIT-13: tagline on every hall screen (Concept 3 / MainMenu) or on none (Concept 1)?
3. KIT-14: does the reputation chip keep the gem (00 §2.5's ruling) now that the designer has said "no gems"?
4. Chip chrome: Theme.gd:218 applies the chamfered bronze chip to all four chips citing 03 §1, while 01 §5 / 06 §5.2 give chips 1-3 a plain pill and only the day chip the bronze border. Recorded choice or drift? Not filed as a finding.
5. Focus ring: no fixture shot shows a focused control although a11y_smoke asserts one exists after `goto()`. Does `shot --fixture` run the router's focus entry? If not, the ring's look (Theme.gd:99-102) has never been checked against a shot.
6. Second combatant bar (KIT-17): waits on the Focus ruling (DW-C1); nothing here decides it.

## Files read

- game/ui/Frame.gd, Widgets.gd, Theme.gd, Cards.gd, Palette.gd, Type.gd, Fonts.gd, Badge.gd, Bar.gd (all read in full)
- game/assets/ui/speech_bubble.png, faces.png (viewed)
- shots: Town.png, Guildhall.png (viewed); Reference Concept 1.png, 3.png (viewed)
- shots viewed: all 13 + Reference Concept 2
- art/ref/specs/06 (full), 00 §2, 05 (full), 03 §3/§7/§8, 01 §4.2/§5/§6/§8; docs/13 §3, §4, §7, §8, §12.3; BUILD_STATE 'art directive' section; build/plan/audit.json (kit-related ids); tools/aseprite/gen_ui.lua, tools/art/gen_icons.lua, gen_wordmark.py (headers); tests/unit/test_screens.gd _texts contract, a11y_smoke.gd header, tools/lint_motion.sh
- game/assets/ui/*.png and icons/ (montaged and viewed)
