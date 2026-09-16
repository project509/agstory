# Report — W3-MENU — the first and last screens

Findings: TOWN-12 (the real lockup + a version line + hover with no scale), TOWN-13 (the CTA inset,
the credits roll with the roster, the camp with the guild in it), RULES-05 (MainMenu's stale water
comment), CRITIC-G02 (Boot's card on the kit panel, `display_aspect` before the overlay, the failure
card's typography through Type), KIT-05 (Completion consumes `cta()`'s guard).
Owns: game/screens/MainMenu.gd, game/screens/Completion.gd, game/ui/Boot.gd (spaces),
tests/unit/test_menu_lockup.gd (new). Handoff: build/plan/handoff-W3-MENU.md.

## Acceptance

- [x] A1 MainMenu draws the real lockup: emblem + `Frame.wordmark("wordmark_58")` + `wordmark_tagline` (+ the trailing rule per 03 §6); the Label "A Guild Story" is kept for `test_screens.gd:180`
  - MainMenu.gd `_lockup()`: a "Lockup" host at (120,296) with `Emblem` (emblem.png, 82x57), `Frame.wordmark("wordmark_58")` at the emblem's right edge on baseline +45 (01 §5: 60-15), and — because `Frame.LOCKUPS[Frame.LOCKUP]["tagline"]` is true — `wordmark_tagline` on the mark's left edge at baseline +30 (03 §6's +23 x 58/44); the 03 §6 rule is drawn only when >= 24px (here 18px: hidden, the same call `Frame.draw_lockup` makes on the header). Hidden Labels "Title"/"Tagline" carry the strings; `accessibility_name` set on the two TextureRects.
  - Seen in W3MENU_MainMenu.png + the 2x crop W3MENU_MainMenu_lockup2x.png: the skull, the bone blackletter mark, the grey tagline under it, aligned on the mark's left.
- [x] A2 MainMenu prints a LabelMuted version line read from `application/config/version`
  - `_version()` -> Label "Version" (LabelMuted) at (24, 980); `version_line()` static: "Version <v>" from `application/config/version`, else "Development build" (the key is unset today; handoff #1 adds it).
  - Seen bottom-left of W3MENU_MainMenu.png: "Development build" in the muted grey, inside the gutter.
- [x] A3 MainMenu hover = plate one step lighter + 1px lift, no scale, no tween
  - `_lift_on_hover(menu)` after the stack is built: for every Button (New Guild's ButtonCta, the four plain Buttons) the theme's `hover` box for its variation — already one step lighter (Theme.gd: the CTA's glow plate, the secondary's 1.22 modulate) — copied with content_margin_top -1 / bottom +1 and expand_margin_top +1 / bottom -1, set as the button's `hover` override; `focus` untouched; no tween, no scale (the test greps for both). Min size identical to the theme's box, so nothing in the column moves.
  - Evidence is the test, not a shot: shot.gd has no hover flag (CRITIC-G02/KIT-11's "a hovered/pressed CTA" is still unshot — a `--hover=<Button.text>` flag would be W0-SHOT's), so the numbers are asserted against `Theme_.current()`'s box instead.
- [x] A4 RULES-05: the MainMenu.gd comment says water shimmer is on; cloud drift and sail motion are M4B-VFX-01
  - The `_build()` comment now reads: the harbour's water shimmer is on (stage_town.json's three rects), the sky's cloud drift and the chimney smoke landed with W2-STAGE2, the windmill's sail motion is still M4B-VFX-01's (RULES-05). The lie "none of which SceneStage can build" is gone; test_menu_lockup pins both. LIES row for W4-HYGIENE noted in the handoff.
- [x] A5 Completion shows four+ actors in the open camp (the band and the scene offset re-composed)
  - Band at the bottom of the scene host (PANEL_INSET 18/14, PANEL_H 368 at a 6px pitch, `grow_vertical` BEGIN), SCENE_OFFSET (-46,-94). W3MENU_Completion.png: the band's rim rows 626..991 (whole, inside the host's 77..1007 — the first take at PANEL_H 348 ran off the host because the panel had always grown past 348); above it the fire ring at screen (884,402) with eight whole figures (warrior, cleric, mage, rogue, mage_b, knight, ranger, ginger) and the crate-side cleric_b with its bubble ("I think I'm ready for a real raid this time!") just above the band. The test counts >= 4 `Actor_*` above the band.
- [x] A6 Completion's CTA keeps "Back to town — the guild carries on" verbatim and its text is inset >= 12px each side (KIT-05's guard consumed)
  - `back.custom_minimum_size.y = BTN_H` only (the guard's width kept); `_inset_cta` copies normal/hover/pressed/disabled with side content margins 29; SIDEBAR_W 314. Measured on W3MENU_Completion.png: plate x 1175..1486 (312), line 1 "Back to town — the guild" x 1215..1446 (inset 40/40), line 2 "carries on" centred x 1284..1375; the plate's right rim now inside the pad (was 1502 against the panel's 1506).
- [x] A7 Completion's credits are a centred roll: the guild's roster (names, classes, 48px portraits) above `credit_lines()`; every non-empty credit line printed verbatim; "not written yet" still present
  - `_roll()`: "Credits" (centred LabelSection) → "The guild" (LabelLabel) → GridContainer "Roll", two columns, one `_credit` row per raider: `Widgets.slot(Cards.portrait_for(r), 48, "SlotMini")` + LabelName (clip + ellipsis) over LabelClass → rule → the file's lines centred (verbatim, blank entries kept as empty Labels) → spacer → rule → CTA. Empty roster: "Nobody on the books." Seen: twelve rows Bork/Warrior … Clive/Bard with their busts, then the unsigned-roll sentence.
- [x] A8 Boot: the card on the kit panel; `display_aspect` applied BEFORE the overlay is shown; the failure card's widths through `Type.at`
  - Boot.gd: `_apply_display_aspect()` first in `_ready()` (before `_build_host`/`_build_overlay`), gone from `_boot()`; `CARD_W`/`FAILURE_CARD_W`/`FAILURE_TEXT_W` consts, the failure card's label widths and card width through `Type.at(…, Theme_.scale_of(self))`; the overlay docstring names the kit panel and KIT-09's door. Seen: W3MENU_Boot.png (S4).
- [x] T1 `tests/unit/test_menu_lockup.gd` (new, four-space) green
  - 13 tests (four-space): the lockup's parts and metrics, the tagline switch (both branches assert), the RULES-05 phrases, the version line and `version_line()`'s set/unset round-trip (ProjectSettings in memory, restored), the hover lift vs the theme's box with no min-size change and no focus override, the roll (one credit per raider, names + class words, 48px tile, the file's lines after the roll, "not written yet", the CTA found verbatim), the empty roster, the CTA's guard + inset + SIDEBAR_W arithmetic, the band at the bottom with >= 4 actors above it, Boot's card on PanelWarm with the ornament slot registered, the failure card's widths through Type.at, the `_ready` source order. Green in the 23:34 verify run (1908 tests; only other units' six in-flight failures listed).
- [x] S1 shot `MainMenu` viewed
  - W3MENU_MainMenu.png (1536x1024, bare): the aerial with the dark left scrim, the lockup (skull + 58 mark + tagline) at 120,296, New Guild crimson over Continue (disabled, "No saved guild found." under it) / Load Guild / Settings / Quit, "Development build" bottom-left.
- [x] S2 shot `MainMenu --frames=1,60` viewed
  - W3MENU_MainMenu_frames.a/.b.png: diff image W3MENU_frames_diff.png viewed — the clouds across rows 0-200, three chimney plumes, the three shimmer rects (left sea, bottom-left, harbour); the lockup/stack/version regions differ only by the sea shimmer under the scrim (max 24/765 summed channels, the same 1179/1041 px the wave-2 pair had there). The sky and the water move, the ground and the chrome do not.
- [x] S3 shot `Completion --fixture --completed` viewed
  - W3MENU_Completion.png (--fixture --completed, second take): the framed camp with the guild around the fire in the open, the report band whole across the bottom, the credits roll with twelve busts/names/classes, the CTA in two balanced lines. W3MENU_Completion_gate.png (--fixture, the gate's variant) is the same composition.
- [x] S4 shot `Boot.tscn --hold-boot` viewed
  - W3MENU_Boot.png (--hold-boot): the card centred on GROUND_PAGE — PanelWarm's chamfered double line WITH the four corner ornaments (W3-KIT2's `Widgets.panel` overlay landed in the working tree during this wave; the boot card gets them through the same call, as predicted — crop W3MENU_Boot_corner4x.png viewed), the 58 mark, the designer's tagline, the rule, "Reading the guild's paperwork…".
- [x] S5 shot `MainMenu 1820x1024 --set=display_aspect=keep` viewed
  - W3MENU_MainMenu_wide.png (1820x1024, keep): the 1536 frame centred on GROUND_PAGE bars 142px each side; the lockup, the stack and the version line inside the frame, nothing cut.
- [x] G1 `test_screens.gd:170-215` / `:495-577`, `test_savegame.gd` green; `verify.sh --fast` green; `lint_motion.sh` OK
  - `tools/with_godot_lock.sh ./tools/verify.sh --fast` (23:34, build/shots/W3MENU_verify.log):
    `PASS  LINT OK  no cross-file class_name references in sim/ or game/`
    `PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)`
    `PASS  PARSE_CHECK scanned 173 script(s)`
    `PASS  16 generated file(s) agree with tools/gen_items.gd`
    `TESTS FAILED   6/1908 failing  [241095 ms]` → `VERIFY FAILED` — the six are other units' work in this same tree, none in a file this unit owns or a test that reads one: test_options_layout x1 (W3-OPTIONS' new test), test_roster_layout x2 (W3-ROSTER's new test), test_text_scale `Guildhall.gd must not call Theme_.get_theme()` (W3-ROSTER), test_widgets_kit x2 (callout clamp — W3-KIT2). test_menu_lockup, test_screens (MainMenu :170-215, Completion :495-577) and test_savegame report no failure.
  - `a11y_smoke.gd` (same lock hold): `A11Y SMOKE PASSED   26 screen mount(s)`; MainMenu owner 'New Guild', tab ring 5, focusable 5 = reachable 5 on both sweeps; Completion owner 'Camp', rail 6, focusable 7 = reachable 7 on both sweeps; no new warn.
  - `tools/lint_motion.sh`: `MOTION LINT OK`.
- [x] R1 refdiff MainMenu vs 3 (region 0,300,520,420) and Completion vs 1 — before/after recorded
  - After: mainmenu vs 3 (region 0,300,520,420): mae 36.126 (was 36.289) · layout_iou 0.0868 (was 0.0758) · within-8 29.84% (was 28.45%) — no regression. completion vs 1 (--fixture, no mask): mae 28.092 (was 28.634) · layout_iou 0.0977 (was 0.0854) · within-8 39.4% (was 34.82%) — no regression; the --completed take scores the same (28.093 / 0.0977 / 39.4). Heat/sbs under build/diff/w3menu/.

## Before (the wave-2 gate, build/diff at 20:56)

- mainmenu vs 3 (region 0,300,520,420): mae 36.289 · layout_iou 0.0758 · within-8 28.45%
- completion vs 1 (--fixture, no mask): mae 28.634 · layout_iou 0.0854 · within-8 34.82%

## Judgement calls

- **The Completion band moved to the bottom; the scene offset is (-46,-94), not the plan's (-46,-300).** With a
  top band, -300 puts the fire ring at host y 119 — under the band — so the plan's sentence cannot be built as
  written; TOWN-13's own alternative ("or lower the band to the bottom third") is what was built. -94 (32px
  above Town's -62) keeps the crate-side figure (plate y 625) clear of the band and puts the plate's last row on
  the host's last row (1024 - 930). The band's PANEL_H is now the content's real height (368 at a 6px pitch;
  the old 348 was short and the panel silently grew, harmless at the top, off the host at the bottom) and it
  grows UPWARD (`grow_vertical` BEGIN) at larger text scales.
- **The title's mark is the 58, the header's tagline switch decides the tagline.** TOWN-12 names
  `wordmark_58` + `wordmark_tagline`; Q05's `Frame.LOCKUP` is consumed for the tagline half only (the title
  needs the full-size mark whichever header lockup the designer picks). Flipping LOCKUP to "58" drops the
  tagline from the title as it does from the header.
- **The 03 §6 trailing rule is hidden under 24px.** The designer's tagline (283px) leaves 18px of the 58 mark's
  width; the header hides its rule for the same reason (tagline wider than the 44 mark). A stub is not a rule.
- **Hover lift = a copied hover StyleBox** (content +1 up, plate expand +1 top / -1 bottom): the plate and its
  label rise one pixel, the control's rect and the stack do not move (docs/13 §12.1 no layout shift), no tween,
  no scale. `_lift_on_hover` runs over every Button in the stack after it is parented (theme lookup).
- **The CTA breaks after "guild"**: with FiraSans SemiBold 21, "Back to town — the" is 182px and "the guild
  carries on" 184px, so a break at the dash has no width window; "Back to town — the guild / carries on" has
  [235, 305). CTA_SIDE_INSET 29 on the 314px plate gives 256px of line and 40px of inset each side (measured).
- **SIDEBAR_W 330 -> 314**: the old value overflowed the pad by 16px (the CTA's rim ran to x 1502 against the
  panel's 1506); 378 - 2x14 - 2x18 is the column's true width. The credits text wraps 16px narrower.
- **The roll is the camp's JSON actors, not `place_party`**: the camp already stands twelve figures (Town's
  same cast) and doubling them with the roster's class actors would crowd the ring; the credits column is
  where the roster is named. Two-column grid, 48px `SlotMini` portraits via `Cards.portrait_for`, capped by
  nothing: fifteen fit above the file's lines.

## Log

- 22:1x engine batch 1 (six shots, one lock hold): all SHOT OK; viewed (S1, S2, S4, S5; S3's first take showed the band running off the host — fixed in the second Completion pass).
- 22:23 batch 2 first attempt: PARSE_CHECK FAILED (17) — `Cards.gd` (W3-KIT2's, mid-edit) would not resolve and the cascade broke every screen that preloads it, my test file included; not mine, re-ran once Cards parsed again (23:0x: PARSE_CHECK OK, 173 scripts).
- 23:17 batch 2: suite `TESTS FAILED 7/1908` — one mine (`test_hover…`: off the tree `Button.get_theme_stylebox("hover")` answers with the engine default, so the lift was computed from the wrong box; `_lift_on_hover` now reads the theme's box by variation name through `Theme_.current(self)` and `_theme_hover`), six other units' in-flight (test_options_layout x1, test_roster_layout x2, test_text_scale re Guildhall.gd, test_widgets_kit x1). Completion re-shot both ways, viewed.

- Read in order: 00-plan §0 (+ wave-3 ownership table) and §W3-MENU, §6/§7; RULES.md §1-§5 (+ RULES-05);
  TOWN-12, TOWN-13, CRITIC-G02, KIT-05; LESSONS.md in full; report-W1-FRAME (lockup table, `draw_lockup`,
  `wordmark`), report-W2-STAGE2 (the MainMenu sky: clouds + smoke landed, rm pair 0 px); MainMenu.gd,
  Completion.gd, Boot.gd in full; Frame.gd's LOCKUPS/draw_lockup/wordmark; Widgets.cta/_guard_cta/panel;
  Cards.portrait_for; Theme.gd's buttons + ornament icon slot; shot.gd's --hold-boot; test_screens.gd's
  walker and the MainMenu/Completion cases; test_text_scale's DOOR_FILES rule.
- Wave-2 state found: `Widgets.cta()` ALREADY guards the two-line wrap (KIT-05: autowrap + ellipsis,
  `CTA_WRAP_W` 300, plate 70 -> 88 when wrapped) — no handoff needed for the guard; Completion's
  `custom_minimum_size = Vector2(0, BTN_H)` was overwriting the guard's width, which is the fix here.
  `Widgets.panel` does not yet overlay KIT-09's ornaments (W3-KIT2's, this wave); Theme.gd already
  registers the `corner_ornament` icon on PanelWarm, so Boot's card gets them through the same
  `Widgets.panel("PanelWarm", …)` call the day KIT2 lands — nothing to switch over.
- `application/config/version` is NOT set in project.godot (export_presets.cfg carries
  `application/product_version="0.1.0.0"`); the screen reads the setting with an honest fallback and
  the handoff asks the orchestrator to add the key.
- 23:34 batch 3 (verify --fast + a11y_smoke, one lock hold): lint/motion/parse/generated PASS, suite 6/1908 failing — none mine (list under G1), a11y both sweeps PASS. Done: the tree parses, my 13 tests and every test that reads my screens are green, the handoff has one exact edit (project.godot's `config/version`) and two observations.

## Left undone / for the orchestrator

- `config/version` is the handoff's edit #1; until it lands the title prints "Development build" (honest, tested both ways).
- The LIES row for MainMenu.gd's retired phrase is W4-HYGIENE's (RULES-05 → W3-MENU + W4-HYGIENE); noted in the handoff.
- Completion's band clips at text_scale 150 (it grows upward now instead of off the host, but the sidebar column and the 928px band are not scale-tested by this unit's contract); the CTA wraps to three lines at 150 inside an 88px plate. Both are the text-scale sheet's business (W0-TEXTSCALE / CRITIC-G15), not asserted here.
- The a11y_smoke's disabled-count for MainMenu reads 0 because the reasoned Continue is `FOCUS_NONE` by `button_with_reason` (unchanged by this unit).
