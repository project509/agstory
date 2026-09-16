# Report — W1-KIT — the composites, in code, with no new pixels of their own

Unit: wave 1, 00-plan.md §2 "W1-KIT". Findings closed (the widget half of each): CRITIC-G05, CRITIC-G06,
CRITIC-G08, KIT-05, KIT-08, KIT-12 + CRITIC-C11 + TOWN-16 + COMBAT-19, KIT-18 + COMBAT-08 + HALL-13 +
CRITIC-C08 + CRITIC-C18, KIT-01 + TOWN-01 + PIPE-08, KIT-02 + STAGE-10 + PIPE-05 + CRITIC-C02, COMBAT-02 +
PIPE-01 + CRITIC-C05, RULES-12, HALL-11, KIT-06 + HALL-03 + CRITIC-C15, TOWN-29, KIT-21 + TOWN-23.
Owned: game/ui/Widgets.gd, game/ui/Cards.gd, game/ui/Badge.gd, game/ui/Bar.gd, tests/unit/test_widgets_kit.gd (new).
Handoff: build/plan/handoff-W1-KIT.md.

## Acceptance

- [x] `stamp_box()`'s Label is a DIRECT child of the PanelStamp box; `stamp()` keeps its Label contract (see judgement call 1).
- [x] `confirm_pair` yields two Buttons with the given texts, one DANGER-rimmed plate, the "no" half is the default focus.
- [x] `reasoned` disables the control, dims it to 0.55 and prints the reason in ONE CAUTION LabelSmall (never a tooltip).
- [x] `damage_number(-317, "hit").text == "-317"`, named "DamageNumber", typed LabelDamage/Crit/Heal, value never changes, pooled to 16.
- [x] `roster_strip` pages twelve names across three pages via a `PagerNext` Button in the strip's gutter (x 131 / 1035).
- [x] `building_callout` keeps `Widgets.button_of` semantics (Button named "Button" inside "Callout"); icon column + tail exist.
- [x] `speech_plate(text, tail_at)` grows a "Tail" only when `tail_at` is finite; `speech_bubble(kind, glyph)` centres a 16px glyph.
- [x] `Widgets.Motion` constants; `Widgets.pager`; `Widgets.tab_row`; `slot_with_reason` + `sparkline` promoted verbatim; `Cards.card(actions)`; quote fallback; event_log "View All" + hint; `cta` overflow guard.
- [x] `test_screens.gd:432-443` (button_with_reason) and `test_a11y.gd:279-353` (link) green; whole unit suite green.
- [x] Shots viewed with the Read tool and described below: `Town --fixture`, `RaidPrep --fixture`, `Results --fixture=raid`, RaiderDetail before/after.
- [x] `verify.sh --fast` green; `lint_motion.sh` prints `MOTION LINT OK`; summary lines pasted below.

## Judgement calls

1. `stamp()` STAYS A LABEL; the box form is `stamp_box()`. The plan's KIT-18 line says `Widgets.stamp(word, tone) -> PanelContainer`,
   but its own Build notes say "keep every existing constructor's return type" (RULES §4 pins the same), and four screens this unit
   does not own hold the return as a Label (`RaidView._wipe_stamp_label: Label`, `Results.gd:336 t: Label`, `Roster.gd:477-483`
   sets `.horizontal_alignment`/`.vertical_alignment` on it, `Tavern.gd:291/412`). A PanelContainer return would not compile in
   files outside this unit's ownership. So `stamp()` keeps its signature and carries the docs/13 §7 treatment on the Label itself
   (2-7° lean from the word, 0.85 alpha, shrink-to-text), and `stamp_box(word, tone: String)` is the PanelStamp box with the Label
   its DIRECT child — the form the wave-2/3 sites (RaidView's wipe, Results, Roster) migrate to; test_wipe_sequence's
   `get_parent().get_index()` sibling contract is written into stamp_box's doc comment.
2. The one failing test (`test_the_label_stamp_keeps_its_contract_and_leans`) was a float round-trip, not a wrong angle:
   `"WIPE.".hash() % 6 == 0`, so the lean is exactly 2.0°, which Control stores as radians and reads back as 1.9999999°, under the
   test's `>= 2.0`. The bound in both stamp tests now allows 0.01° of round-trip; the code is unchanged. ("FALLEN" hashes to 7°,
   "MISTAKE" to 5°, "1 OF 1" to 2°, "CLEARED" to 7°, "MAY LEAVE" to 5° — checked with the same djb2 in Python.)
3. RaidPrep, Tavern and RaiderDetail still draw their OWN page arrows over card 4 (KIT-12's defect) and are untouched this wave, so
   the strip's gutter pager and the legacy one are BOTH on those screens until the handoff lands: handoff-W1-KIT.md §3-§5 remove
   the three `_pager()` bodies and pass `"on_page"` so each screen's `_page` stays in step. No test reads the legacy captions
   (grep `page|pager|Tonight's` over tests/unit: nothing).
4. RaiderDetail "mae 0": the screen is NOT switched to `Widgets.sparkline` this wave (RaiderDetail.gd is W1-HALL's, and W1-HALL,
   W1-FRAME and W1-CHROME all moved the screen's pixels), so a whole-screen mae 0 against the pre-wave shot is not a measurement of
   this unit. The verbatim claim is proven by text instead: `Sparkline._draw` is `MoraleChart._draw` line for line (the only
   differences are `Pal` -> `Palette` and the colour going through `color_fn`, which defaults to the same `morale_color`), and
   `slot_with_reason` is `Market._slot_with_reason` with `Widgets.` prefixes dropped. handoff §1-§2 switch the two screens.
5. `speech_bubble` centres its glyph and its dots on the frame's BODY read off the theme's PanelEmote content margins (12/10/12/18
   on the 40x44 frame = the 16x16 body), so the geometry is the chrome's and moves with it; SceneStage still adds its own
   Ellipsis at the old 33x32 bubble's pixels (8,11), which now sits on the new frame's rim — handoff §6 retires it.
6. `stamp_box` re-tints a COPY of the theme's PanelStamp StyleBoxTexture for a non-danger tone (W1-CHROME's Theme.gd comment
   expects Widgets to do exactly that); the shared theme resource is never mutated.

## Shots

(each one viewed with the Read tool; what it shows)

- `build/shots/W1-KIT-Town.png` (`Town --fixture`, 16:47, after the two fixes): five callouts on W1-CHROME's chamfered
  PanelCallout 9-slice, each with the 32px SlotMini icon well at the plate's left (empty until W2-TOWN passes
  `Icons.at("building_<id>")`), title Button and subtitle at x+60, and a 14x8 tail hanging from the middle of the bottom
  edge in the plate's own fill/rim (SURFACE_BUBBLE / EDGE_CALLOUT) — the tail and the 9-slice read as one object
  (2x crop `W1-KIT-Town_callouts.png`). The locked Blacksmith is dimmed with "Canon lists this one as a maybe. /
  Disabled in this build." in CAUTION inside the plate, now clamped to the scene's right edge (x 653-928) instead of
  running under the sidebar; it butts against the Market plate below it — W2-TOWN's anchors will place both. [WRONG,
  per review F7: 653-928 was the framed band applied to the full-bleed host; the Town's scene edge is 1139 and the
  clamp had dragged the Blacksmith 247px left onto the Market. Corrected in the Repair pass below: 863-1139.] The camp's
  text bubble ("I think I'm ready…") is the PanelBubble plate, no tail (W1-STAGE's one-arg call). Emote bubbles are the
  40x44 cream PanelEmote with ONE row of dots (the 16:21 shot had two — SceneStage's Ellipsis — until W1-STAGE applied
  handoff §10-§11; crop `W1-KIT-Town_emote.png`). Strip: ◄ at x≈131 and ► at x≈1035 in the gutters as 16x44 mini
  plates, "1/3" under the right gutter at y≈1008, no pager over a card. [Review M1: on the Town the ◄ sits 12px over
  the Available panel, whose head grows it to 123; only RaidPrep's is in a gutter — W3-KIT2, see the Repair pass.]
  Event log head: "Recent Events" left, the disabled "View All" link right with "Records opens this" under it in
  CAUTION, "Nothing has happened yet." centred in the well (crop `W1-KIT-Town_strip_r.png`; the 16:21 shot had the
  reason one letter per line — defect 1, fixed). [Review F8: the word itself was near-black under the dim and
  unreadable — not noticed; fixed in the Repair pass.]
- `build/shots/W1-KIT-RaidPrep.png` (`RaidPrep --fixture`, 16:27): the strip's gutter pager at x≈131 / 1035 with "1/3"
  under the right gutter; the four chalked cards carry their "Bench" action; RaidPrep's OWN legacy arrows still sit over
  card 4 (x 830-885, y≈980) with "Tonight's 12 · page 1/3" under card 1 — that is RaidPrep.gd (handoff §5-§6); once
  applied, no pager is over a card. Readout, verdict callout ("~58.5 mistakes" on PanelCalloutDanger) and Depart CTA
  unchanged.
- `build/shots/W1-KIT-Results.png` (`Results --fixture=raid`, 16:27): four "FALLEN" stamps on the party cards, each
  leaning 7° (the word's hash; the same word lands at the same angle), DANGER at 0.85 — `Widgets.stamp` as a Label,
  which is what Results.gd holds. The report panel, loot column and "Back to the board" / "Return to town" unchanged;
  Results' own between-card pager and "What happened" log are Results.gd's.
- `build/shots/W1-KIT-RaiderDetail.png` (`RaiderDetail --fixture`, 16:47): the event log head fixed as on Town (crop
  `W1-KIT-RaiderDetail_strip.png`); the strip's gutter pager plus RaiderDetail's own "page 1 / 3" arrows under the
  mini-grid (handoff §8-§9). The Quarters/On record columns show no sparkline because the fixture has no morale history
  ("No history yet") — and RaiderDetail still draws its private MoraleChart until handoff §1-§2; the "mae 0" claim is
  by text (judgement call 4), since W1-HALL/W1-FRAME/W1-CHROME moved this screen's pixels in the same wave.
- `build/shots/W1-KIT-before-*.png` (09:47): taken while another unit's Fonts.gd did not compile — Town shows NO
  callouts at all — so they are not a baseline; the wave-0 sweep `build/shots/all/fixture/*.png` is.

## Log

(one entry per landed item: what was done, what was seen)

### 09:40-10:10 — read, decided, first code landed
- Read 00-plan §0 + wave 1 + W1-KIT, RULES.md in full, every cited finding (CRITIC G05/G06/G08/C02/C05/C08/C11/C15/C18,
  KIT 01/02/05/06/08/12/18/21, TOWN 01/16/23/29, COMBAT 02/08/19, HALL 03/11/13, PIPE 01/05/08, STAGE-10, RULES-12),
  LESSONS.md, report/handoff-W0-TEXTSCALE, tools/shot.gd's header, and the four owned files in full.
- Baseline shots attempted at 09:47 under the lock: every screen failed to compile because another unit's
  in-progress Fonts.gd (`set_glyph_advance` argument type) breaks the tree — not mine. The wave-0 sweep
  `build/shots/all/fixture/*.png` (08:32 today, pre-wave-1) is the honest pre-change baseline instead.
- Widgets.gd rewritten in place (every existing constructor keeps its signature and return type):
  `Motion` table, `Tail`/`Dots`/`Sparkline` inner classes, `empty_state(text, glyph, hint)` (still a Label),
  `stamp()` (Label, now leaning 2-7°, 0.85) + `stamp_box(word, tone)` (PanelStamp, Label direct child) +
  `stamp_press`, `cta` overflow guard, `pager`, `reasoned`, `confirm_pair` + `default_focus_of`, `tab_row` +
  `tabs_of`, `slot_with_reason`, `sparkline`, `damage_number` + `number_rise` + `number_stagger` (pool 16),
  `speech_bubble(kind, glyph)`, `speech_plate(text, tail_at)`, `building_callout(name, verb, reason, icon, anchor)`.
- Cards.gd: `card(raider, db, action, actions)` with the in-card band; quote falls back to the first backstory
  bullet (2 lines max, only on action-less cards); `roster_strip` draws its own gutter pager under a "RosterStrip"
  wrapper, `strip_page(host)`, `opts.on_page`; `event_log(host, state, rows, hint)` with the reasoned "View All".
- Bar.gd: the numeral size goes through `Type.at(Type.SMALL, Theme_.scale_of(self))` (W0 door). Badge.gd untouched.
- tests/unit/test_widgets_kit.gd written (19 tests). Next: parse check under the lock.

### 13:55 — resumed (previous agent killed by a usage limit before ticking anything)
- Re-read plan §0/§2/W1-KIT, RULES §1-§5, LESSONS, the four owned files and the test in full, the wave-start signatures
  (`git show HEAD:`), every caller of the new/changed functions (Town/SceneStage/RaidPrep/Tavern/RaiderDetail/Market),
  handoff-W1-CHROME §14-§15 (its Widgets.gd anchors are left byte-identical) and Theme.gd's registered names.
- Theme names match: PanelStamp, PanelCallout, PanelBubble, PanelEmote, ButtonQuiet, NavItemActive, SlotMini,
  LabelDamage/LabelDamageCrit/LabelHeal all registered by W1-CHROME; ButtonNotice/ButtonChip exist but nothing here needs them.
- Diagnosed the red test (judgement call 2). Next: the test bound, stamp_box re-tint, bubble geometry, handoff, engine runs.

### 14:05 — edits landed, engine queued
- tests/unit/test_widgets_kit.gd: the two lean bounds take 0.01° of float slack (judgement call 2); two new tests —
  `test_a_caution_stamp_retints_a_copy_of_the_frame_never_the_theme` and the bubble-body geometry asserts in
  `test_speech_bubble_centres_a_glyph_or_draws_dots` (both read the theme's registered PanelStamp / PanelEmote, no branch on
  whether the work exists). 21 tests in the file.
- Widgets.gd: `stamp_box` re-tints a duplicate of the theme's PanelStamp StyleBoxTexture for a non-danger tone (judgement call 6);
  `speech_bubble` reads the body off PanelEmote's content margins and centres the 16px glyph / the 15x3 dots on whole pixels
  (judgement call 5); `Dots` draws at its own origin. handoff-W1-CHROME §14/§15's anchors in this file are byte-identical still.
- Cards.gd: line endings normalised to LF (the previous agent had written it CRLF; every other .gd is LF and git warned).
- handoff-W1-KIT.md written: 11 exact edits (RaiderDetail x4, Market x2, RaidPrep x2, Tavern x1, SceneStage x2) + API notes.
- `verify.sh --fast` queued behind another unit's run under the lock (13:52 holder). lint_motion below.
- RULES-12 verbatim evidence (difflib over the two class bodies, `Pal.`->`Palette.` normalised): `Sparkline` vs `MoraleChart`
  differs ONLY by the dropped `const Pal` preload, the added `color_fn` member, and the colour of each bar going through
  `color_fn.call(v)` (default `Palette.morale_color`, i.e. the same value). `slot_with_reason` vs `Market._slot_with_reason`
  differs only in the function's name line. Same pixels by construction; handoff §1-§4 switch the screens.
- `tools/lint_motion.sh`: `MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)`.

### 15:20 — resumed again (second agent killed by a usage limit; nothing ticked)
- Re-read plan §0/§2/W1-KIT, RULES §1/§4/§5 + RULES-12, LESSONS, report + handoff, all four owned files and the test in
  full, handoff-W1-CHROME §8-§16 and Theme.gd's registrations (PanelCallout/PanelBubble carry a `tail` icon =
  callout_tail.png 14x8; PanelEmote 12/10/12/18; PanelStamp tinted DANGER, TILE edges; ButtonQuiet/NavItemActive/SlotMini/
  LabelDamage*/LabelHeal all present — every name this unit uses is registered).
- Applied handoff-W1-CHROME §8-§13 (Bar.gd: RIM/TRACK/boss/hp fills/numeral ink+outline → Palette.BAR_*/INK_BAR*), §14
  (Widgets.slot_rarity fill → SURFACE_SLOT) and §15 (Tail fill/rim → SURFACE_BUBBLE/EDGE_CALLOUT, comment updated) and §16
  (Badge default disc → Palette.BADGE_DANGER) with a byte-exact patch; every token exists in Palette.gd with the same hex.
  `grep -n 'Color("' game/ui/Bar.gd game/ui/Widgets.gd game/ui/Badge.gd` now prints nothing (KIT-10's lint line is clear
  for the three files this unit owns).

### 16:20-16:45 — shots 1-4 taken and read; two defects found and fixed
- Shots (all four `SHOT OK` 1536x1024, viewed with the Read tool; described under "Shots" below): W1-KIT-Town.png,
  W1-KIT-RaidPrep.png, W1-KIT-Results.png, W1-KIT-RaiderDetail.png, plus 2x crops W1-KIT-Town_{callouts,emote,strip_r}.png.
- DEFECT 1 (Town + RaiderDetail): the event log's "View All" reason ("Records opens this") rendered one letter per line down
  the panel's right edge and pushed "Recent Events" to y=927 — `reasoned()` gave the reason `AUTOWRAP_WORD_SMART`, and a
  wrapping Label has a zero minimum width, so inside the SHRINK_END head box it wrapped at nothing. Fixed at the source:
  `reasoned()` and `tab_row()` no longer wrap the reason (docs/13 §14: a line under a row grows the row, never wraps);
  `building_callout` keeps its wrap because it gives the reason a 200px width. Test pins `AUTOWRAP_OFF`.
- DEFECT 2 (Town): the locked Blacksmith callout (60+200+16 = 276 wide) placed by Town.gd at scene x=900 ran under the
  sidebar and lost its right rim. `_centre_tail` (the no-anchor path) now clamps the plate inside `SCENE` on every rect
  change, as the plan's "plate clamped inside Frame.SCENE" says; the anchored path already did. New test
  `test_a_placed_callout_is_kept_inside_the_scene` (emits `item_rect_changed` by hand — nothing lays out outside a tree).
- Seen, not mine: RaidPrep still draws its OWN pager over card 4 and its "Tonight's 12 · page 1/3" caption under card 1
  (handoff §5-§6, RaidPrep.gd), RaiderDetail its own under the mini-grid (handoff §8-§9) — both screens show the strip's
  gutter pager AND the legacy one until the orchestrator applies the handoff (judgement call 3). The Town's emote bubbles
  showed two rows of dots at 16:21 (SceneStage's Ellipsis + the kit's) — W1-STAGE applied handoff §10-§11 itself at 16:31
  (its own file; SceneStage.gd:953 now reads `Widgets.speech_bubble("dots", glyph)`); marked APPLIED in the handoff.
- Unit suite at 16:40: `TESTS FAILED 2/1712` — both in W1-STAGE's test_scene_stage.gd (written 16:33, in flight):
  `test_every_ambient_bubble_hangs_over_a_head` counts stage children named "Emote" and found 3 of 15, and
  `test_reduced_motion_holds_lights_and_bubbles` compares bubble NAMES across two builds — Godot renames colliding
  sibling names to "@TextureRect@N" (a different N per run), so only the FIRST bubble a stage adds keeps "Emote". The
  kit cannot make five siblings share a name; `speech_bubble` now also sets meta `emote = kind` as the stable hook and
  the handoff's API notes say so for W1-STAGE. Every other file green (test_widgets_kit 22/22 at that run).

### 16:50-17:05 — green
- Unit suite after the fixes: `TESTS PASSED   1713 test(s) in 80 file(s)  [33144 ms]` (test_widgets_kit.gd: 22 tests, all
  green; W1-STAGE's two bubble tests green too on this run — its file moved at 16:33).
- `tools/with_godot_lock.sh ./tools/verify.sh --fast`:
  `PASS  LINT OK  no cross-file class_name references in sim/ or game/`
  `PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)`
  `PASS  PARSE_CHECK scanned 160 script(s)`
  `PASS  16 generated file(s) agree with tools/gen_items.gd`
  `PASS  ART CHECK  generators=6  runtime files: 184 agree  0 DIFFERS  0 MISSING`
  `PASS  TESTS PASSED   1713 test(s) in 80 file(s)  [33787 ms]`
  `VERIFY OK  (full log: .verify.log)`
- `tools/lint_motion.sh`: `MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)`;
  `create_tween(` is in Widgets.gd only; `MORALE_BAND_EMOJI` in Cards/GameSettings only.
- `tests/unit/a11y_smoke.gd` under the lock: `A11Y SMOKE PASSED   26 screen mount(s)`; the only `warn` is the
  pre-existing AdventureBoard "10 pointer-only gesture target(s)" on the fixture sweep (W2-BOARD's). The strip's
  `PagerPrev`/`PagerNext` are FOCUS_ALL, inside the strip host, and the ring closes through them on every strip screen.
- Left for the orchestrator (handoff-W1-KIT.md §1-§9; §10-§11 already applied by W1-STAGE): RaiderDetail → Widgets.sparkline
  and no private pager; Market → Widgets.slot_with_reason; RaidPrep/Tavern → no private pager, `on_page`. Until then
  RaidPrep/Tavern/RaiderDetail show two pagers (the strip's in the gutters and their own).
- Not done, and why: nothing in the contract is left undone. Two judgement calls stand against the plan's letter —
  `stamp()` stays a Label (call 1; the box form is `stamp_box`), and RaiderDetail "mae 0" is proven by text (call 4).

## Repair pass (review-W1-KIT.md, FAIL: F7 blocker + F8 major; M1-M8 minors)

Third agent, repair only; owned files only (Widgets.gd, Cards.gd, test_widgets_kit.gd; Badge.gd and Bar.gd untouched
this pass). Boxes are the review's items; each was ticked when it held on the tree.

- [x] F7 (blocker): `building_callout` clamps against the scene band IN THE PLATE'S PARENT'S SPACE — `_callout_bounds`
  carries `SCENE` (screen 210,77 929x640) into the parent by the parent's offset from the screen root (summed up the
  Control chain, stopping at the node carrying Frame's `frame_focus_order` meta, so a letterboxing shot host is not
  counted), cut to the parent's own rect. Town's full-bleed host at (0,0) → band (210,77)-(1139,717); a framed host at
  (210,77) → (0,0)-(928,640). Both paths (`_centre_tail`, `_place_callout`) use it through one `_clamp_to_band`; a new
  `bounds: Rect2 = Rect2()` parameter (parent's space) overrides the derived band. Measured on W1-KIT-fix-Town.png (PIL
  dark-fill runs): Guildhall 226, Tavern 642, Blacksmith 865-1137 (plate 863..1139 — the reviewer's expected 863),
  Market 862 (860), Board 422 at y=580 (its bottom edge at 660); pre-wave all/fixture/Town.png: Blacksmith 901-1143
  (under the sidebar), Market 896, Board 421; the failed review shot: Blacksmith and Market both 800-927.
- [x] F8 (major): `Widgets.link()` now gives every LinkButton a `font_disabled_color` = the theme's LinkButton rest ink
  (`_link_ink()` reads `font_color` for "LinkButton" off Theme.gd, TEXT_MUTED_WARM; Palette fallback), so a disabled
  link is the same word dimmed by `reasoned()`'s 0.55 instead of Godot's near-black default under that dim. Measured
  on W1-KIT-fix-Town.png: the brightest "View All" glyph pixel is (101,103,105) on panel (0,13,22) = 3.46:1 (≥ the 3:1
  floor); 210 glyph pixels in the word's box clear 3:1. Viewed at 3x (W1-KIT-fix-Town_loghead3x.png): a grey underlined
  "View All" with "Records opens this" in CAUTION under it — readable at 100 and at 150.
- [x] M2: `Cards._turn_page` calls `_rewire_focus(wrap)` after `_fill_strip` and `on_page`, before the deferred grab on
  the new arrow: the nearest ancestor carrying `frame_focus_order` (the literal ScreenRouter mirrors; Cards cannot
  preload Frame) has its Callable called, which re-runs `Frame.focus_order` (idempotent per test_a11y). Test:
  `test_turning_a_page_rewires_the_screens_focus` — 0 calls on build, 1 per turn, a strip on a bare host still turns.
- [x] M1 / M3 / M4 / M5 / M6 / M7 / M8: judgement calls 7-11 below; handoff-W1-KIT.md "API notes added by the repair
  pass" carries M1 (W3-KIT2), M2, M7 (W2-RAIDVIEW/W2-RESULTS/W3-ROSTER), M8 (W3-OPTIONS/W3-DETAIL) and the 150% note
  for W2-TOWN.
- [x] Tests: test_widgets_kit.gd 24 tests (was 22): `test_the_callout_band_is_the_scene_rect_in_the_parents_space`
  (full-bleed host under a screen root under an offset shot host: Blacksmith 900→863, Market/Board unmoved, a plate at
  (100,20) pushed to (210,77), an anchor at (1130,700) lands flush with the band with the tail still aimed at it, a
  framed host clamps to its own 928, an explicit `bounds` wins), `test_turning_a_page_rewires_the_screens_focus`, and
  the event-log test now asserts the link's `font_disabled_color` override equals the theme's LinkButton `font_color`
  and the 0.55 dim. Suite: `TESTS PASSED   1715 test(s) in 80 file(s)`.
- [x] `tools/with_godot_lock.sh ./tools/verify.sh --fast` (after the fixes):
  `PASS  LINT OK  no cross-file class_name references in sim/ or game/`
  `PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)`
  `PASS  PARSE_CHECK scanned 160 script(s)`
  `PASS  16 generated file(s) agree with tools/gen_items.gd`
  `PASS  ART CHECK  generators=6  runtime files: 184 agree  0 DIFFERS  0 MISSING`
  `PASS  TESTS PASSED   1715 test(s) in 80 file(s)  [32608 ms]`
  `VERIFY OK  (full log: .verify.log)`
  `tools/lint_motion.sh`: `MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)`.
  `tests/unit/a11y_smoke.gd` under the lock: `A11Y SMOKE PASSED   26 screen mount(s)`; the only `warn` is the
  pre-existing AdventureBoard "10 pointer-only gesture target(s)" (W2-BOARD's).
- [x] Shots (one lock hold, all `SHOT OK` 1536x1024, each viewed with the Read tool; described under "Repair shots").

### Judgement calls (continued)

7. THE NO-ANCHOR CLAMP IS KEPT, AGAINST THE RIGHT BAND. The review offers "drop the clamp from the no-anchor path, or
   keep it only inside the parent's own rect" and then expects the re-shoot to show the Blacksmith at 863 — which only
   a kept clamp produces (dropped: 900, under the sidebar; the parent's own rect on the Town is (0,0)-(1536,726) and
   would also allow 900). KIT-01's acceptance ("no plate crosses x=1141") and W2-TOWN's are met on the Town this wave
   only with the band clamp on the caller-placed path, so that is what stands; with the correct band it moves exactly
   one plate (the Blacksmith, 37px left), the plan's "the caller places the plate, as today" holds for the other four.
8. The band's origin is found by walking the Control chain up to the screen root (the node with Frame's focus meta),
   not by `global_position`: tools/shot.gd's wide `keep` letterboxes by moving and scaling its host Control, and a
   global read there would have shifted every band by the letterbox offset in the wide-keep sheet. Widgets names the
   meta key as a literal (`SCREEN_ROOT_META`) the way ScreenRouter does — Widgets must not preload Frame (Frame
   preloads Widgets).
9. The disabled link's ink is the link's REST ink, not a brighter one: docs/13 §7's treatment is "the control dimmed",
   and the callout title takes the same reading (TEXT_MUTED under the dim); 3.46:1 clears the 3:1 UI floor, and the
   reason line in CAUTION carries the message. If the designer wants the dead word brighter, `_link_ink()` is the one
   line. Read off the theme rather than a Palette token so a LinkButton retone in Theme.gd reaches the disabled state.
10. M3 (TOWN-29 scoping), on the record: the quote falls back to the first backstory bullet ONLY on a card with no
    action band (`action` and `actions` both empty), because a 262-tall card cannot hold the portrait row, two morale
    lines, a two-line quote, three slots AND a Bench button — Raid prep's card keeps its shape; the Town's, the
    Guildhall's and the Tavern's cards (no band) get the line. M4: `event_log` draws at most `fit` = (262 - 28 - 36 -
    1) / 29 = 6 rows where callers ask for 7 — the head grew a line (the reasoned "View All") and the panel clips, so
    the seventh row (which sat under the strip's bottom before) is dropped rather than half-shown; no test reads the
    count and spec 01 §4.2's seven fit a head with no second line.
11. M5/M6 stand as the review read them (wiring assertions per the suite's convention; RaiderDetail "mae 0" proven by
    diff, judgement call 4). M7: `stamp()`'s lean is static (docs/13 §7), every existing site now leans — the handoff
    tells W2-RAIDVIEW/W2-RESULTS/W3-ROSTER to expect it. M8: the confirm's deferred grab on `tree_entered` is meant —
    the safe half of a pending destructive choice holds focus; noted for W3-OPTIONS/W3-DETAIL. M1: the ◄ plate's 12px
    over the Available panel is the panel's HEAD, not the grid — "Available   12" at 17px ≈ 99px + 24 pad = 123 > 110
    (the 2x4 grid is 105; RaidPrep's "Bench 0" fits, so it is clean there); spec 01 §4.1's own geometry (count flush
    right at x≈101-110 in a 110-wide panel) fits one digit. The fix splits the head into two Labels or widens the
    panel — either changes the strip's `_texts()` — so it is W3-KIT2's (recorded in the handoff), not this pass's.

### Repair shots

- `build/shots/W1-KIT-fix-Town.png` (`Town --fixture`): five callouts on PanelCallout with the icon well, title Button,
  subtitle and tail; the locked Blacksmith now ends at x=1139 with its right rim visible beside the sidebar (863..1139),
  the Market back at 860 over the vegetable beds, the Board at 420,580 by the bridge; the Blacksmith's bottom rim still
  meets the Market's top (the designer's `at` values, 122px apart, with a two-line reason — W2-TOWN's anchors). Event
  log head: "Recent Events" left, a readable grey underlined "View All" right with "Records opens this" under it.
  Crops: `W1-KIT-fix-Town_callouts.png` (1x, the callout band), `W1-KIT-fix-Town_callouts-before-after.png` (pre-wave
  all/fixture/Town.png beside it: the flat plates with the Blacksmith cut off at 1143 vs the chamfered, tailed plates
  inside the band), `W1-KIT-fix-Town_loghead3x.png` (the link, 3x).
- `build/shots/W1-KIT-fix-Town-t150.png` (`--set=text_scale=150`): "View All" readable at 150; the Blacksmith's
  three-line reason makes its plate ~185 tall and it covers the Market's title — `W1-KIT-fix-Town-t150-crop.png` puts
  the pre-wave all/text150/Town.png beside it: the SAME stack before this unit (the flat plate over "M… / Buy / Sell"),
  so it is the coordinates, not the clamp; W2-TOWN's one-line reason and anchors resolve it (handoff note).
- `build/shots/W1-KIT-fix-Town-focus.png` (`--focus --tab=11`; shot.gd log `TAB 11 -> PagerPrev<Button> at 124,843
  16x44`): the steel ring on the strip's ◄ (crop `W1-KIT-fix-Town-focus-crop.png`) — the arrow is in the ring at
  entry; the crop also shows M1 (the ◄ plate over the Available panel's right rim on the Town).
- `build/shots/W1-KIT-fix-RaidPrep.png` (`RaidPrep --fixture`; strip crop `W1-KIT-fix-RaidPrep-strip.png`): unchanged
  by this pass — the kit's gutter pager clean beside the 110-wide "Bench 0" panel, "1/3" under the right gutter, and
  RaidPrep.gd's own legacy arrows still over card 4 until handoff §5-§6 land.

### Log (repair pass)

- Read: review-W1-KIT.md in full, the report and handoff, 00-plan §0/§2 (W1-KIT, W2-TOWN, W3-KIT2), RULES §1-§5,
  KIT-01/KIT-21, LESSONS, Widgets.gd and Cards.gd in full, Town.gd's BUILDINGS/`_build`/`_scene`, Frame.relayout
  (scene host (0,0) 1536x726 full-bleed / (210,77) 928x640 framed, added directly to the screen), ScreenRouter's
  shell-focus hooks, Theme.gd's LinkButton block, spec 01 §4.1 (for M1), tools/shot.gd's `_place_host` (for call 8).
- Widgets.gd: `SCREEN_ROOT_META`, `_callout_bounds`, `_clamp_to_band`; `_centre_tail`/`_place_callout` take `bounds`;
  `building_callout(..., bounds := Rect2())`; `link()` sets `font_disabled_color` from `_link_ink()`. Cards.gd:
  `SCREEN_FOCUS_META`, `_rewire_focus`, called from `_turn_page`. Indentation re-scanned: Widgets/Cards 0 space-led
  lines, the test 0 tab-led, no CRLF. Parse check `PARSE_CHECK OK` (160 scripts) before any engine run.
- Engine runs (each under the lock): parse check; unit suite 1715/1715; four shots in one hold; verify --fast (above);
  a11y smoke (above). Not touched: Badge.gd, Bar.gd, any unowned file; no git command.
