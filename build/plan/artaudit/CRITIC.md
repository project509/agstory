# CRITIC — completeness pass over the seven art/UI audit reports

Date: 2026-09-13. Key: CRITIC. Read-only; no tree edits, no Godot, no Aseprite. Other reports untouched.

## Scope

Reports read in full: COMBAT (22 findings), KIT (23), HALL (26), TOWN (31), STAGE (21), PIPE (17), RULES (16) — all seven present, none missing, 156 findings between them. Shots viewed: the thirteen fixture shots under scratchpad/shots/ (MainMenu, Town, AdventureBoard, RaidPrep, RaidView, Results, Guildhall, RaiderDetail, Tavern, Market, LoadSave, Settings, Completion). References: ideaboard/Reference Concepts/Reference Concept 1/2/3.png. Tree greps for the surfaces the brief names and nobody shot: game/ui/Boot.gd, project.godot, export_presets.cfg, the four inline confirm pairs (LoadSave.gd:266-283, Market.gd:417-442, RaiderDetail.gd:345-382, Tavern.gd:617-637), RaidView.gd:425-447 and :995-1004 (verbosity buttons, `log_manual_advance`), game/core/LogPlayer.gd:27-29 (cadence), tools/shot.gd:51-58 and tools/shot_all.sh:21-35 (what the instrument can select), AdventureBoard.gd:242-256 / :381-414 and tests/unit/test_tutorials.gd (what a tutorial renders).

Method: for each surface the brief lists, find which report covers it and how; for every widget or asset two or more reports specify, compare numbers, names and owners; for every Fix, check it against RULES §1-§4; for every severity, ask whether the designer's bar ("insanely polished … like a real team of fantasy 2D artists and UI designers") would rate it the same.

## Gaps

Each gap: what is missing from all seven reports, the evidence, and the cluster that should own it.

### CRITIC-G01 · P0 · The exported build's first frames are unowned: no boot splash, no clear colour, a non-square icon and no .ico
Evidence: project.godot [application] carries `config/icon="res://game/assets/ui/emblem.png"` (82x57, the file's own comment admits it is not square) and nothing else — `grep boot_splash\|default_clear_color project.godot` is empty, so the shipped .exe opens on Godot's default splash (engine logo on the engine's grey) and every pixel the 3:2 frame does not cover (the letterbox bars under `window/stretch/aspect="keep"`, project.godot:45-46) paints the engine's default clear colour. export_presets.cfg:69-75 points the Windows icon at the same 82x57 PNG. build/plan/q-housekeeping.md:45-67 records the icon/.ico as PROPOSED-deferred; no plan, spec or report mentions a splash or a clear colour. No report covers any of it: PIPE's inventory stops at game/assets, RULES §2's `display_aspect` row says "none (visual only)".
Why it matters: the first thing a player of the exported build sees is another company's logo, and on any 16:9 monitor the bars beside the game are engine grey for the whole session — the opposite of "a real team made this", before a single screen of ours is on.
Owner: PIPE (assets: `gen_wordmark.py` already renders the lockup — emit a 1536x1024 splash on `Palette.GROUND_PAGE` with the emblem + wordmark, a 256x256 square icon from the emblem, and the .ico via Pillow) + RULES (project.godot `application/boot_splash/image`, `boot_splash/bg_color = GROUND_PAGE`, `rendering/environment/defaults/default_clear_color = GROUND_PAGE`; a `test_export.gd` case that asserts the three keys exist and the icon is square). Acceptance: a 1920x1080 shot (G03) shows GROUND_PAGE bars; the exported .exe's first frame is our lockup.

### CRITIC-G02 · P2 · The Boot overlay has never been shot or audited
Evidence: Boot.gd:55-79 builds a 560px PanelWarm card with the pre-rendered lockup, a rule and "Reading the guild's paperwork…"; :137-178 builds the failure card (up to 12 problems + Quit). TOWN's "Empty and first-run states" section calls it "Fine as is" without a shot; shot_all.sh's 13 targets and a11y_smoke's SCREENS omit Boot; test_screens only asserts Boot.tscn exists (RULES §1). Boot.gd:114-118 applies `display_aspect` AFTER the overlay is built and shown, so on a wide window the boot card is the one frame that "flashes the other framing" the comment says never happens.
Owner: TOWN (the screen — it is the MainMenu's prelude; check the card against the kit's panel finish, KIT-09's ornaments, and the failure card's typography) + RULES (a `--hold-boot` path in shot.gd, or shoot Boot.tscn with the router's goto suppressed).

### CRITIC-G03 · P1 · Nobody looked at a wide display: the 3:2 letterbox and the `expand` mode are unseen
Evidence: GameSettings.gd:41 / :287-291 offer `keep | expand`; project.godot:35-46 records that `expand` "exposed their baked-in chrome beside ours (verified with a 1920x1080 shot)" — a shot from before the bare plates; no current shot exists at any size but 1536x1024 although shot.gd takes WxH positionally (RULES §3 step 1). Under `expand` Frame's explicit placement (RULES §4: "explicit placement", Frame.gd) leaves the sidebar at x 1148 and the strip at 1536 wide; what fills x 1536..1820 is unknown (plate? clear colour?). RaidView/Results' compact header assumes x=0..352 and the boss plate x 931..1315 (COMBAT-12, STAGE §blocking) — right-anchored chrome is not anchored. The Settings row itself promises "Expand: fill the width; the scene plates end where they end" (Settings.png row 5).
Owner: RULES (two shots per screen at 1820x1024 — `keep` and `--set=display_aspect=expand` — added to shot_all.sh as a third sheet) + KIT (Frame: anchor the sidebar/strip right edge to the viewport under expand, or fill the extra width with GROUND_RAIL so the promise in the Settings copy is true).

### CRITIC-G04 · P1 · Five tab surfaces exist, were never shot, and three were never mentioned
Evidence: Guildhall › Facilities (HALL-18/22, by code only), Guildhall › Records (HALL-20, by code), Tavern › Manage (Tavern.gd:592 `_build_manage`, the dismiss list with its confirm — no finding anywhere), Market › Buy (Market.gd:529, TOWN-21 by code), Market › Comfort (Market.gd:613, TOWN-21 by code). shot.gd:51-58 has `--fixture`, `--fixture=raid`, `--completed`, `--set=` and no way to select a tab; shot_all.sh:21-35 lists one shot per screen. HALL open q8 asks for Facilities/Records only.
Owner: RULES (shot.gd `--press=<Button.text>` — press a button by exact text after `on_enter()`, which is how the tests already drive screens — then shot_all.sh gains Guildhall|Facilities, Guildhall|Records, Tavern|Manage, Market|Buy, Market|Comfort rows) → then HALL (Facilities/Records/Manage) and TOWN (Buy/Comfort) audit the five shots.

### CRITIC-G05 · P1 · The destructive confirm is four hand-built idioms and none was shot
Evidence: LoadSave.gd:269-283 `_confirm_pair` (a row: "Yes — overwrite Slot N" in DANGER font + "Keep it"); Market.gd:417-433 (a wide "Yes — take it off X and sell it" + a shrink-centred "Keep it" inside the ledger row); RaiderDetail.gd:345-382 `_dismiss_block` (a column: a note, "Yes — let them go (+cost)" at `SIZE_META`, "Keep them"); Tavern.gd:617-633 (a row: "Yes — let them go (-2 morale to everyone else)" + "Keep them"). Four layouts, two "no" words, one font-size override, all coloured only by a `font_color` override — no plate, no glyph, no stamp, no focus move to the safe choice. No fixture shot shows any of them (they need a press). TOWN-21 moves the Market's confirm into the sidebar as the screen's crimson CTA, which would make a fifth shape. docs/02 §5.3/§6.3 (name the consequence) is met; the *shape* is nobody's.
Owner: KIT — `Widgets.confirm_pair(yes_text, no_text, on_yes, on_no) -> Control` (both halves Buttons so `_texts()` sees them — test_loadsave_screen.gd:235-236 reads "Yes — overwrite Slot 1"/"Keep it", test_market.gd:485 "take it off"; texts unchanged), one DANGER-rimmed plate, the "no" focused by default (docs/13 §7's safe default), one word for "no" ("Keep it"/"Keep them" is a copy choice — keep both strings as they are the tests' contract, but one geometry). Then the four screens call it; TOWN-21's sidebar version uses the same widget.

### CRITIC-G06 · P1 · "Disabled with reason" has at least seven shapes and every report fixes only its own
Evidence: (1) `Widgets.button_with_reason` — a Label under the Button (Widgets.gd:223-232; cards, sidebars); (2) the callout's reason lines inside the plate (Town.gd:300-305, TOWN-02); (3) tab reasons as one full-width sentence (Guildhall.gd:199-207, HALL-10); (4) Settings' steel-blue reason under the description (HALL-17, Settings.png rows 8/11/16/17); (5) LoadSave's reason printed twice per row (HALL-15); (6) RaidView's floating 250x20 plate over the arena (COMBAT-04); (7) RaidPrep's "Unknown guilds cannot commission this. Reach Known." under a greyed button (Tavern.png/Market.png sidebars). The proposed fixes add more: a dimmed plate + padlock (TOWN-02), "Skip — locked" button text (COMBAT-04), a WaxButton sub-line (COMBAT-14), a tooltip/sub-line (COMBAT-22), a per-tab caption (HALL-10). Constraint every fix must keep (RULES §1, docs/01 §9 line 506, docs/13:700): the reason is a Label adjacent to the control — tooltip-only variants are out.
Owner: KIT — one treatment: `Widgets.reasoned(control, reason: String)` = the control dimmed to 0.55 + a 16px padlock glyph in its leading slot + ONE `LabelSmall` in CAUTION directly under (or inside, for callouts/tabs) — and a lint line in tools/lint_motion.sh that flags `.disabled = true` outside Widgets.gd without `reasoned`/`button_with_reason`. Then Town (callout), Guildhall (tabs), LoadSave, Settings, RaidView (skip + exits), Results (Suggested) adopt it in their own clusters.

### CRITIC-G07 · P1 · No single icon manifest: nine cell sizes are in use and three reports invent three more sets
Evidence: shipping icons run 15x12 (class_warrior), 16x16 (arrows), 18x18 (badge_N), 22-30 (nav_*), 24x24 (mech_*, face_N), 26-29 (chip icons), 28x28 (rank_*), 32x32 (slot_*, provision items), 39x39 (item_*), 48 (boss sigil slot) — PIPE §1.8/§1.9. New sets are proposed at 16 (KIT-19/PIPE-06 class), 20 (COMBAT-06 class + log), 22 (KIT-07 log, COMBAT-03/13 state), 24 (PIPE-07 state/mech, TOWN-01 building), 36x32 (KIT-01 building), 32 (KIT-08 empty-state), 12 (COMBAT-09 blots). See CRITIC-C03 for the name and size collisions. Nothing in game/ui says "an icon at role R is N px from path P"; each screen loads by string.
Owner: PIPE (gen_icons.lua as the single generator with a fixed grid: 16 class/emote, 22 log-event/state, 24 mechanic/status, 28 rank, 32 building/empty-state; PIPE-13's manifest) + KIT (`Icons.gd`: `static func at(role, key) -> Texture2D` with the size table, so Cards/Widgets/RaidView stop hand-typing paths and sizes). COMBAT/TOWN/HALL cite roles, not pixel sizes.

### CRITIC-G08 · P1 · No motion table, and nobody budgeted the per-line UI effects against the flash rule at 2x
Evidence: docs/13 §12.2 is the canon table; the reports pick their own numbers — 90 ms settle (COMBAT-17), 120/60 stamp press (COMBAT-08), 110 dissolve (RULES-03, banned pending ruling), 600 ms number rise of 18 px (COMBAT-02, STAGE-04) vs 700 ms / 28 px (PIPE-01), 2.4 s bubble (COMBAT-03, STAGE-04), 180 ms bolt / 90 ms hit / 350 ms burst (STAGE-03), 1.5 s strip hold (RaidView.gd:911-924). Flash rule (RULES §2: `MAX_CHANGES_PER_SECOND = 3`, UI layer only, BL-75 DECIDED): LogPlayer.gd:28 `LINE_CADENCE` is 0.180 s at 1x (5.5 lines/s), 0.110 s at 2x (9/s), batched at 4x. COMBAT-16's per-line panel rim + sprite brighten, COMBAT-17's per-row settle, COMBAT-09's per-mistake blot and COMBAT-13's status row are UI-layer changes driven at that cadence; STAGE-03's verifier notes BL-75 is UI-only, but the panel rim IS UI. No report computes the rate.
Owner: KIT — `Widgets.Motion` constants (STAMP_PRESS 120/60, LOG_SETTLE 90, NUMBER 600, BUBBLE 2400, HIT 90, BURST 350; one rise distance) consumed by COMBAT/STAGE, plus a rule COMBAT applies: per-line UI-layer effects (rim, settle, blot) coalesce to once per round at 2x and are off at 4x/Instant; world-layer effects (numbers, sparks) are exempt by BL-75. Acceptance: a test that steps the player at Speed.TWO for one second and counts StyleBox swaps on any one panel ≤ 3.

### CRITIC-G09 · P2 · Emoji-free mode has never been rendered, and its pip figure is set in a proportional face
Evidence: GameSettings.gd:194-198 builds `"|" * (band+1) + "." * (9-band)`; Theme.gd:182 sets LabelMorale in `Fonts.ui_tabular(500)` — tabular *figures* even out digits, not "|" and "."; in Fira Sans the bar and the period have different advances, so the ten-pip figure is uneven and the count is hard to read at a glance (docs/13 §13 asks for a "monochrome pip figure"). No shot with `--set=emoji_free=true` exists; COMBAT-10's "pip sprite" is barred by test_a11y_legibility.gd:488-492 (the "|" must be in Label.text). HALL-05's font route fixes the emoji half only.
Owner: KIT — keep the string in the Label (the contract) and give it a fixed-advance rendering: a `LabelPip` variation on a monospace face (game/assets/fonts has none — PIPE adds one, OFL) OR a drawn pip row (Bar.gd-style) beside a Label whose string is the contract; plus `--set=emoji_free=true` on shot_all's second sheet.

### CRITIC-G10 · P2 · CVD mode has no design and no shot
Evidence: RULES-09 covers that `Palette.cvd_safe()` is unreachable (no `colourblind_safe` key) and what the tests pin; no report says what the morale chip, the roster strip, the combatant HP bar or the log's red mistake rows look like under the CVD ramp (BAND_FILL_CVD is asserted "too dark for text" — fills are plates, so every chip needs a plate variant). `--set=colourblind_safe=true` is refused today (GameSettings.set_value rejects unknown keys).
Owner: KIT (the chip/strip/bar in CVD mode: lightness-ordered plate fills with the integer + word + glyph unchanged — RULES-09's four channels) + RULES (the key, docs/13 §15.1 row, Settings.ROWS entry; a CVD sheet in shot_all run through tools/art/cvd.py --sim deuteranope).

### CRITIC-G11 · P1 · The measurement instrument needs nine flags that six reports ask for separately and nobody owns
Evidence: `--focus` / `--tab=N` (RULES-13), `--advance=N|all` for mid-fight and wipe shots (COMBAT q7; needed by COMBAT-02/03/07/08/09/15/16 acceptance), a tab/press selector (G04, HALL q8), a `--set=text_scale=150` sheet (RULES-02), `--set=emoji_free=true` (G09), `--set=reduced_effects=true` (nobody: with glow off the 1.2-1.35-modulated flame props render as flat over-bright sprites, STAGE §ingredients), `--set=reduced_motion=true` (STAGE-14 acceptance), a hovered/pressed state (KIT-11 acceptance "a hovered/pressed CTA"), wide sizes (G03), a clear-outcome raid fixture (see G12), two-frame motion diffs (STAGE-14, M4B-VFX-01's own measurement), Boot (G02), the a11y "empty" sweep as images (no-guild mounts — "Roster 0 of 15", "No attempt to report", "Nobody to manage" — TOWN and HALL describe them from code). shot.gd today: four flags (tools/shot.gd:51-58).
Owner: RULES/measurement — one commit to shot.gd + shot_all.sh (sheets: fixture, empty, a11y-focus, text150, emoji-free, reduced, wide-keep, wide-expand, tabs, raid-advanced, raid-clear) and diff_all.sh scoring all 13 (RULES-11). Every other cluster's acceptance lines depend on it; it is wave 0.

### CRITIC-G12 · P1 · Results on a clear — the loot hand-out — has never been seen
Evidence: the raid fixture wipes (tools/fixture_reference.gd:72-81 runs one attempt; playtest: 0 of 8 clear Tier 1), so Results.png shows the wipe branch only: "No payout", the disabled "Sell all unusable", "Nothing left to hand out." COMBAT-11/22 audit that branch. The clear branch — per-item assignment rows, "Suggested — give everything" doing something, "See how it ended" (test_screens.gd:615-618), the Cracked Charm reward line (test_full_loop.gd:265-268) — has no shot and no finding, although test_full_loop proves a clear is producible (A0 is "won by the squad the game hands you", test_tutorials.gd:236).
Owner: COMBAT (audit the clear branch once G11's `--fixture=raid:clear` exists — seed the A0 fixture rather than E5) + RULES (the fixture flag).

### CRITIC-G13 · P2 · RaidView's three verbosity modes and the manual-advance pause have no findings
Evidence: RaidView.gd:425-447 builds Story / Play-by-play / Numbers (docs/13 §11.1); every RaidView shot is Play-by-play. `log_manual_advance` (RaidView.gd:995-1004 `_dwell_on`) sets `_player.paused = true` at each mistake and calls `_sync_controls()` — the only cue that the account has stopped and is waiting for the player is the Pause button's state; no "paused on a mistake — press to continue" line, no focus move, no dim. Settings.png row 3 promises "The account pauses at each mistake until you dismiss it" — there is nothing to dismiss.
Owner: COMBAT — one finding per mode (what Numbers hides/shows, whether the strip and HP fold agree in Story mode) and a dwell affordance (a `Widgets.stamp` "PAUSED — mistake" on the log panel + the Pause button focused; Label so tests read it), shot via G11's `--advance` + `--set=log_manual_advance=true`.

### CRITIC-G14 · P2 · The tutorial teaches nothing on screen, and no report noticed
Evidence: what a tutorial renders is the Board's facts suffix "tutorial · skippable" (AdventureBoard.gd:242-256) and the sidebar skip block (:381-414: the amber warning + "Skip the tutorial"); `TutorialSkipPrompt` is 🔷 PROPOSED and parked in build/plan/q-tutorials.md (:393-397). In the fight itself A0's scripted round-3 mistake — "that is the lesson" (test_tutorials.gd:146; the Board's own blurb) — is one red log row among others; TR's "read the Wipe Report" advice is a blurb on the Board. No overlay, callout, or first-time prompt exists on RaidView/Results, and no report asks whether one should.
Owner: COMBAT, after Q15 — if the designer wants the lesson surfaced, a one-line `Widgets.callout` band over the log ("Round 3 — somebody was always going to do this. This is the lesson.") shown only on tutorial encounters; if not, record it in q-tutorials.md so the next auditor stops asking.

### CRITIC-G15 · P2 · Every proposed widget is sized in absolute pixels while `text_scale` is dead and docs/13 §14 asks for +30% elasticity
Evidence: RULES-02 (P1) proves no screen passes the scale. On top of that the fixes add fixed geometry: callout width 232 / icon column 60 (KIT-01, TOWN-01), combatant status row at panel-local y 121 (COMBAT-13), paper-doll 62x74 + 47px cells (HALL-07), two-column strip at pitch 36 (HALL-04), Settings rows at 40 (HALL-17), damage numbers at fixed px (C05), LoadSave buttons 200x36 (HALL-15), stamp 100x26 (HALL-13), pager band 30 (KIT-12). None states its 125/150% behaviour; docs/13 §4.4 says reflow by rows, never truncate a morale value/state word/class name; §14 wants two-line wrap only on prose.
Owner: KIT — every new composite takes its sizes through `Type.at(size, pct)` and `Widgets.SCALE` multipliers, and every wave's acceptance includes the text150 sheet from G11 with "no clipped Label" as the pass. RULES-02's `Theme_.current()` door lands first (wave 0).

### CRITIC-G16 · P3 · Crimson means "commit" on five screens and "apply options" on one; nobody states the rule
Evidence: the crimson CTA is "Go to prep" (Board), "Depart" (Prep), "Hire — 60 G" (Tavern), "Rest until recovered" (Guildhall), "Back to town — the guild carries on" (Completion), the wax "The report" (RaidView) and "Apply" (Settings); Town, Market, RaiderDetail, LoadSave, Results have none (TOWN-06/21 propose two). Spec 06 §3 and docs/13 §6.1 make the CTA the screen's one commit; whether Settings' Apply and Guildhall's rest are commits of that grade, or secondary, is unstated — and Guildhall's crimson sits on a screen where the player's real commit is elsewhere.
Owner: KIT — a one-line rule in spec 06 §3 ("crimson = spends time, gold or a raider; everything else is secondary") and the two screens adjust (Settings' Apply → secondary-lit per HALL-17; Guildhall's rest stays only if resting is a spend — it costs days, so it is).

### CRITIC-G17 · P3 · Reduced-effects and the animated layer were never captured
Evidence: no shot with `--set=reduced_effects=true`; STAGE's ingredient table says only the flame props (modulate 1.2-1.35) and the ember birth colour exceed 1.0 — with glow off those over-driven sprites clip to flat white-orange, which nobody has looked at. No two-frame capture exists for any stage, so whether the shot pipeline's 30-40 frames actually show a fire mid-loop (STAGE-11's straddle, STAGE-12's speckle) was judged from the strips, not the screen.
Owner: STAGE (a `reduced_effects` variant of the prop modulate — 1.0 when glow is off — set in `apply_settings`) + RULES (G11's reduced sheet and a `--frames=A,B` two-capture mode).

## Contradictions

Where two or more reports propose different owners, values or rulings for the same thing, and where a proposed fix breaks a contract RULES pins.

### CRITIC-C01 · The hall family's plate: same framing as the hub, or a distinct one — and who must rule it
- HALL (plate plan, HALL-01/02): `stage_camp` at Town's `CAMP_OFFSET` (-46,-62), dim 0.62, "so Town → Guildhall reads as a panel sliding over the SAME camp"; needs designer: no (only the Guildhall/RaiderDetail band question).
- TOWN-14 (P0): "if the hall family goes on stage_camp the hub and the Guildhall become the same picture with different chrome"; recommends a distinct framing "tight on the big guild tent, offset ≈(-120,-140)" with its own dim/tint; needs designer: yes; asks for a `SceneStage.SERVES` table + test.
- STAGE-13: per-screen SCENE_DIM "the way AdventureBoard does (0.68)"; needs designer: no.
- RULES-10 (P0): "copy Town.gd:143-146"; needs designer: no. BUILD_STATE.md:73 still maps Settings to `stage_town`; HALL/RULES q7 say inherit-with-default-camp.
Resolution: HALL owns the conversion and lands it at the hub's offset (cheapest, meets the directive, no ruling needed to start); the framing is a per-screen constant, so TOWN-14's question becomes a switch, not a blocker — record it in art/ref/specs/00 §2 as `HALL_FRAMING = same | tight` (default same) with the designer's answer (Q03) flipping one constant; TOWN's `SERVES` table + test is the right guard against BUILD_STATE drifting again and belongs to STAGE (SceneStage owner). Settings' ground: inherit, default camp (three reports agree; BUILD_STATE:73 is the stale row).

### CRITIC-C02 · One bubble, four chromes, four tails, three generators
- KIT-02: the speech plate takes the callout's chrome (#040E18, chamfer 4, `callout_plate.png` + `callout_tail.png` 14x8); emote = `emote_bubble.png` 40x44 cream + `emote_<kind>` 16x16 (dots, mug, sweat, skull, zzz).
- STAGE-10: spec 02 §5.3 — opaque navy #03122C, 2px #545663 + 1px #03040E, chamfer 6, tail 12x10 at head − (0,28), 17px #F0F0F0; `bubble_navy.png`; emotes as 12x12 icons in the badge slot (mug, heart, zzz, skull).
- TOWN-03: a 3px stepped 12x8 tail from the Reference Graphics UI sheet, bubble 9-slice + tail on a 16px grid; TOWN open q8 already names the 03 §7 (callout chrome) vs 06 §8 (steel #0B1B26) split as "a kit decision".
- PIPE-05: `bubble_body` 24x24 9-slice in CREAM (#EED0AB, lip #F9E3BA, shade #C0AB8E, rim #1A1512), four 8x6 tails, `emote_frame` 40x44, ten 16x16 emote spans.
- COMBAT-03: reuse `Widgets.speech_plate()` with a tail, "spec §5.3 chamfer, 117x56 min".
So: three fills (dark, navy, cream), four tail sizes (14x8, 12x10, 12x8, 8x6), three emote vocabularies, two generators (gen_ui.lua vs gen_icons.lua vs a sheet slice).
Resolution: PIPE emits exactly one text-bubble 9-slice and one tail, and one emote frame + glyph set (its list is the superset and cites the A1-S8 rects); KIT owns `speech_plate(text, tail_at)` and `speech_bubble(emote)`; STAGE owns anchoring (`speaker`). The fill is a designer question (Q04) because two references disagree (Concept 3's camp bubble is dark like its callouts; Concept 2's combat bubble is navy) — until answered, one chrome everywhere (dark callout chrome; it is what the hub, the designer's first screen, uses).

### CRITIC-C03 · Icon names and sizes collide across five reports
- Class glyph: 20x20 "from the class portraits' silhouettes" (COMBAT-06) vs 16x16 (KIT-19, PIPE-06); identity shield (docs/12 §5.1) vs crossed swords (spec 01/02) — PIPE q9.
- Log/event icons: `log_<kind>` 22x22 by Enums.Verb, twelve kinds (KIT-07, Table A) vs `log_boss/log_alert/log_heal/log_mech` 20x20 (COMBAT-06, spec 02 §2.1) vs `badge_<kind>` via `Cards.BADGE_FOR_KIND` (TOWN-23, PIPE-13) — three name schemes for one set; existing badge_N is 18.
- State/status: `badge_downed.png` 22x22 + `state_dead.png` (COMBAT-03/13) vs `state_<key>` 24x24 (PIPE-07) vs `bar_hp.png`/`bar_focus.png` 24x24 (KIT-17).
- Building callout icon: five new 36x32 (KIT-01) vs five new 24px (TOWN-01) vs reuse `nav_<id>.png` 22-30px (PIPE-08; its verifier corrects the mapping — Market already owns nav_gear, only the Blacksmith lacks a glyph).
- Callout tail/pointer: 14x8 centred on the bottom edge (KIT-01, TOWN-01, spec 03 §3) vs 12x7 "under the left third" (PIPE-08, spec 06 §8).
- Affix cells: 30 px at pitch 34 (COMBAT-05, spec 02 §9.2) vs the 26/32 drawn today; boss sigil 48.
Resolution: PIPE's grid (G07) and names win because PIPE owns the generator: `class_<key>` 16, `log_<kind>` 22 (one scheme — retire `badge_<kind>` naming; `Cards.BADGE_FOR_KIND` maps kinds to `log_*`), `state_<key>` 24, `building_<id>` 32 (the reference callout icon is ~24-35 px: spec 03 §3 — 32 fits both), tail 14x8 (spec 03 §3 is the measured one; 06 §8's 6px triangle is the drawn fallback). COMBAT/TOWN/KIT cite the role, PIPE the pixels.

### CRITIC-C04 · Three VFX inventories, three generators, three APIs for the same effects
- COMBAT-03: `fx_impact` 48x48x6, `fx_slash` 64x48x5, `fx_orb` 32x32x6, `fx_heal` 32x32x6 via "tools/aseprite/ Lua"; `SceneStage.play_fx(strip, at)`; VFX under `reduced_effects`.
- STAGE-03: `fx_spark` 16x16x6, `fx_slash` 48x40x4, `fx_bolt_arcane`/`fx_bolt_fire` 12x6 + trail, `fx_impact` 48x48x5 via `gen_fx.lua`; verbs `hit/burst/bolt/slash` with one-shot GPUParticles2D bursts; held under `reduced_motion`.
- PIPE-02: `fx_spark_hit` 32x32x4, `fx_slash_arc` 64x48x5, `fx_bolt_arcane` 24x48x4 + `fx_bolt_trail` 8x2, `fx_heal_sparkle` 32x32x6, `fx_burst_impact` 64x64x5, `fx_poof_smoke` 48x48x5 via `gen_vfx.lua` (auto-run by build_art.sh); `SceneStage.add_fx(strip, frame_w, fps, pos, {additive, once})`; last-frame-for-300ms under `reduced_motion`.
None of the three is sized for the 2x figures STAGE-02 asks for (a 16px spark on a 96px body).
Resolution: PIPE owns assets and names (its list is the superset, cites the A1-S7 rects and the spec 02 §9.1 ramps, and lands the lib.lua primitives PIPE-12 needs); STAGE owns the API (`add_fx` as the primitive, the four verbs as thin wrappers) and the `apply_settings` gating (both settings: `reduced_effects` drops VFX, `reduced_motion` freezes to the last frame — the two reports each named one); COMBAT owns the Verb→effect trigger table in `_append_line`. Sizes re-authored after Q01 (figure scale).

### CRITIC-C05 · Damage numbers: three sizes, two rises, two anchor names, one non-existent token
- PIPE-01: `Type.DAMAGE = 28` / `DAMAGE_CRIT = 34` (the tokens exist; spec 05:99 rules them), outline 2px #1A0A05, rise 28 px / 0.7 s ease-out, pool 16, `SceneStage.anchor_of(sprite)`.
- STAGE-04: 16 px / 22 px (spec 02 §5.4's reference measurement), `Palette.CRIT` / `Palette.TEXT_BRIGHT` (does not exist — its verifier notes it), rise 18 px / 600 ms, `SceneStage.head_of(spr)`.
- COMBAT-02: evidence cites 22/16 px, Fix names `LabelDamage/LabelDamageCrit/LabelHeal` with `Fonts.ui_tabular(600)`, rise 18 px / 600 ms, inline anchor math; colours DANGER/CRIT/POSITIVE/white.
Resolution: the Type.gd tokens are the recorded ruling (spec 05 supersedes a measurement of a reference drawn at a different figure scale) — 28/34; KIT owns the three Label variations; STAGE owns one anchor helper (`head_of` — STAGE's name, STAGE's file); rise/duration from G08's table (600 ms / 18 px, the majority); pooling per PIPE.

### CRITIC-C06 · Overhead bars: all twelve or the focused actor
- COMBAT-03 acceptance: "a bar above each of the twelve".
- STAGE-04: "Twelve 62px bars over a 2x crowd will overlap; the safe default is badge + pips only, bar on the focused/most-recent actor" — designer question (STAGE q4).
Resolution: STAGE's caution is arithmetically right at 2x (column pitch 64 vs a 96px bar); ship badge + pips on all, bar on the acting/struck figure; one question to the designer (Q07), asked once.

### CRITIC-C07 · Who owns the world-space overlay layer
- COMBAT-03: "three widgets under game/ui/ (or a new game/ui/Overlays.gd owned by RaidView)", screen-space Controls repositioned each frame from the sprite.
- STAGE-04: overlays are stage children "added after the actor layer so they draw over figures and under the chrome", `SceneStage.head_of`, `stage.say_at(spr, line)`.
- RULES §4: SceneStage is one owner; "new layer types = new JSON key + `apply_settings` handling + a test".
Resolution: SceneStage owns the layer (so `reduced_motion`/`reduced_effects` gating stays in the one door RULES §2 names, and Results/RaidPrep get the same layer for free); RaidView calls `stage.say_at`, `stage.number_at`, `stage.bar_for`. Either way the Labels sit inside the screen subtree, so `_texts()` reads bubble and number text.

### CRITIC-C08 · StampBadge: three specifications for one widget, one hard constraint only COMBAT knows
- COMBAT-08: `Widgets.stamp_badge(word, tone)` — `stamp_frame.png` 9-slice (2px double rule, 3-4 worn gaps, DANGER 70%, 40x22 min), rotation 2-7° from `word.hash()`, pressed 1.06→1.0 at `motion_duration(120, 60)`; verifier: the stamp must BE the direct child of the screen that `_wipe_stamp_label.get_parent()` resolves to (test_wipe_sequence.gd:295-297).
- KIT-18: `stamp()` returns a Control with `stamp_frame.png` 9-slice 24x24, `rotation_degrees` 4, modulate 0.85; no tween.
- HALL-13: a PanelContainer with a 2px DANGER/CAUTION rim, radius 3, rotation −6°, `wipe_blot.png` ink behind at low alpha, 100x26.
Resolution: KIT owns it, under the existing name `Widgets.stamp(word, tone)` (three call sites migrate without renames); COMBAT's sibling-order constraint is written into the docstring; rotation from the word hash (COMBAT — two fixed-angle stamps side by side read as printed); HALL's ink-behind idea is the texture (PIPE's gen_wipe.lua emits `stamp_frame.png` with the blot's fibre edge); the press tween only where a stamp lands live (RaidView), never on a static card (HALL/Roster).

### CRITIC-C09 · Morale glyph: font fallback or TextureRect — two doors for one glyph
- HALL-05: a bitmap `FontFile` built from faces.png added as a fallback in Fonts.gd, so `Label.text` keeps the emoji code point and every contract (test_screens :856-931, the emoji-free pip string, the lint's one door) is untouched.
- COMBAT-10: `Cards.card` renders line 1 as a Label without the glyph + a `TextureRect` face; "Results is not in MORALE_SCREENS so its Labels may drop the glyph" — but `Cards.card` is shared by Roster (inside Guildhall, which IS in MORALE_SCREENS), Town, Board and Prep, and test_screens.gd:928 requires the Tavern to still print an emoji with the option off.
- Both: free RaidView.gd:795's face-as-portrait.
Resolution: HALL-05's route is the only one that keeps one door and every contract; COMBAT-10's TextureRect route is retired. KIT owns Fonts.gd; PIPE regenerates faces.png at the three text scales (24/30/36 — a bitmap glyph in a scaled Label otherwise blurs, and the same face must serve the strip, the cards and the combat status row); the pip string gets G09's fixed-advance treatment. Whether the sprite faces are canon at all is COMBAT q3 / docs/12 §5.2 PROPOSED (Q17).

### CRITIC-C10 · Figure and boss scale: four numbers, two positions on whether it is a ruling — and every camp/hall measurement was taken at 1x
- STAGE-02 (P0): 2x on camp and both arenas, tavern 1x pending a look; "needs designer: yes — confirm".
- COMBAT-01 (P0): actors x2, boss x3-x4; "the scale change is not [a designer call]".
- STAGE-01: boss 2.5x main/mini, 2x elite/trash.
- PIPE-03 (P0): integer 2x of a boss "contradicts 07 §4.1 ('would read as chunky') and must not be done silently — needs a ruling first"; PIPE-04: accept the sliced idles or author combat bodies — designer.
Dependency nobody states: TOWN-01's tail anchors, TOWN-07's "hat-to-edge" clearances and its fix positions, HALL's plate-plan visibility claims ("the fire ring with its four seated actors in x 810..1138"), TOWN-22's "≥4 whole actors", and STAGE-02's own "re-author every bubble y by minus one frame_h" are all computed against 1x figures.
Resolution: one designer question (Q01/Q02), asked once; STAGE owns `figure_scale` and lands it first; TOWN and HALL re-measure after it (their numbers are provisional and their reports should say so). The party at 2x is within canon (docs/12 §3.3 allows integer scale); the boss is the only real ruling (PIPE is right that 07 §4.1 warns against it).

### CRITIC-C11 · The pager: three placements
- KIT-12: `Widgets.pager(page, pages, on_prev, on_next, caption)` in a 30px band under the Available grid (RaiderDetail's placement); "cards never share pixels with it".
- TOWN-16: paging inside `Cards.roster_strip`, ◄ ► as focusable Buttons "in the 8-px gutters at x 131 and 1035, page dots '1/3'" (spec 10 §2 R1).
- COMBAT-19: match RaidView — prev/next side by side under the cards at y 1004 with the caption; or up/down glyphs in the gutter.
Resolution: one owner (KIT — `Cards.roster_strip` is its file) and one placement; spec 10 §2 R1's gutters are the recorded choice and cannot collide with cards or the strip's bottom band; RaidView/Results/RaidPrep/Tavern/RaiderDetail adopt it. KIT-12's count ("four screens") is five (its verifier), so the widget saves five layouts, not four.

### CRITIC-C12 · The header: one defect, three severities, and a question that is half-answered
- The day-chip icon flip: KIT-03 P1, TOWN-05 P2, HALL-19 P3 — the same defect (five `_chips` builders load sun.png; `Frame.standard_chips` loads the rank sigil). All three also note the dead `_standing_tip()` (KIT-23, HALL-19 caveat, TOWN-30).
- The lockup size flip: KIT-13 "needs designer: tagline everywhere or none" vs TOWN-05's verifier "spec 03 §6 already rules 'do not let the logotype change size between screens' — a build defect, not an open question" — but TOWN's own open q4 still asks "which one, everywhere?"
Resolution: one finding, P1 (CRITIC-R03), owner KIT (Frame): delete the five builders, move `_standing_tip` into `standard_chips`. The lockup: 03 §6 decides *sameness*; *which* lockup is one designer question (Q05) with a recommendation both reports share (44 + tagline).

### CRITIC-C13 · The rail label: ruling or mechanics
- KIT-04: needs designer — "Board" on the rail, two-line, or 16px rail type.
- TOWN-04: needs designer: no — shrink to `Type.NAV − 2` when `get_string_size` exceeds 134, or move the glyph column to x=16 and the label to x=62 ("the canon label is longer and the design wins").
Resolution: TOWN-04's is decidable from the memory rule (reference concepts are a standard; where their UI does not fit the design, the design wins): shift the columns, keep the label whole; KIT-04's `clip_text` guard stays as the safety. No question.

### CRITIC-C14 · "Back to town / Back to menu": link or button
- TOWN-31: one idiom on all four hub sidebars — the 06 §7.3 underlined `LinkButton` (`Widgets.link(text, true)`).
- TOWN-06 (verifier): "Back to menu" must stay a `Button` (spec 10 §3.1; `_texts()` cannot see a LinkButton); TOWN-31 itself admits any future assertion on "Back to town" must target a Button.
Resolution: the idiom is a quiet *Button* variation (`ButtonQuiet`, registered through Theme.gd `_button()` so test_a11y's ≥9-types/focus-ring contract holds), not a LinkButton, on all four; `Widgets.link` stays for "View All" (KIT-21, TOWN-23).

### CRITIC-C15 · Card actions: "layout accident" or "deliberate OQ-4 reading"
- HALL-03 (P1, "polish"): actions hang below the card border and halve the visible rows.
- KIT-06's verifier: Roster.gd:450 records the beneath-the-card placement as a deliberate docs/13 OQ-4 reading — "a polish call, not a layout bug".
Both propose the same fix (actions inside the card via `Cards.card(actions: Array)`).
Resolution: same fix, KIT owns the widget, HALL calls it — but the OQ-4 record in docs/13 must be updated in the same commit (canon discipline: a recorded reading is not reversed silently).

### CRITIC-C16 · Settings' controls: the recorded cycle-button choice vs new widget classes
- HALL-17: keep the cycle buttons (spec 06 §7.2: the reference has no switch); light the engaged value with a ButtonChip pressed state; volume as a `Widgets.bar` pip strip beside the number — within the recorded choice.
- KIT-20: `Widgets.toggle`, `segmented`, `slider_row` (HSlider) — its verifier flips "needs designer" to yes because Settings.gd:332-344 records the cycle button as deliberate.
Resolution: HALL-17 now (no ruling); KIT-20 only if the designer answers Q14 — the memory rule says where the references lack a widget the design wins, so it is the designer's call.

### CRITIC-C17 · DoF / tilt-shift: required or deferred
- STAGE-07 (P1): docs/12 §2.2 row 6 "non-negotiable"; "needs designer: no for DoF/vignette".
- PIPE-10: "the reference concepts show no blur; spec 11:139 records DoF as deferred — not in the references' visible signature at 1:1; needs a recorded ruling before it ships"; STAGE's own open q7 asks the parallax half.
Resolution: PIPE is right by the memory rule (the references set the bar and show no blur) and by spec 11's recorded deferral; STAGE-07 drops to a switch (`dof` key in the scene JSON, default absent) and the ruling is one question (Q08). The vignette half (8% edge darkening) is cheap and reference-neutral — ship it behind `reduced_effects` without waiting.

### CRITIC-C18 · Fixes the RULES report forbids or endangers
- **Baked "!" glyphs** — COMBAT-03 `badge_downed.png` (22x22 "!" plate), COMBAT-07 `icons/fumble_bang.png`, STAGE-09's icon option: docs/13 §14 "no baked-in text on any sprite" (RULES-14). Use STAGE-09's other option — the "!" is a Label (`LabelFigure`, #F2C14E) over a bare plate; only the plate is a sprite. Same for any "N" numeral on stack badges (PIPE-07 already keeps the numeral a Label).
- **The stamp's sibling order** — COMBAT-08's verifier: `_wipe_stamp_label.get_parent()` must be a direct child of RaidView and index-above `_wipe_blot` (test_wipe_sequence.gd:295-297); KIT-18 and HALL-13's composites nest the Label one level deeper. Whichever `Widgets.stamp` lands (C08) keeps the box as the parent the test reads.
- **Tooltip-only reasons** — COMBAT-04 variant (b), HALL-15 ("Delete keeps `disabled` with a tooltip rather than a second Label"), COMBAT-22 ("tooltip/sub-line"): docs/01 §9 line 506 and docs/13:700 require the reason as adjacent text, and `_texts()` reads only Label/Button (RULES §1). Reasons stay Labels (G06).
- **LinkButton for tested text** — TOWN-06's "demote Back to menu to a link", TOWN-31: `_texts()` cannot see a LinkButton; test_screens reads "Back to menu"; spec 10 §3.1. See C14.
- **New Button-family variations** — RULES-07's `Notice_<id>` row buttons (also TOWN-25), TOWN-16's ◄ ►, KIT-12's pager, KIT-20's toggle/segmented, C14's quiet button, TOWN-01's callout hover: every variation must be registered through Theme.gd `_button()` or test_a11y.gd:229-277 (≥9 types, each with the 2px EDGE_STEEL `focus` StyleBoxFlat) goes red — only RULES-07 says so. Texture buttons may replace normal/hover/pressed, never `focus`.
- **Mouse-eating overlays** — STAGE-07's full-stage DoF ColorRect and STAGE-10's tail Control must be `MOUSE_FILTER_IGNORE` (their verifiers caught it) or every Town hotspot dies; TOWN-08's gradient scrims and TOWN-12's version line likewise. And nothing may be parented to the router's host (test_screens.gd:159-169 one-child rule; RULES-03) — Boot-owned or screen-owned only.
- **Containers inside Frame** — TOWN-17's ScrollContainer in `Frame.sidebar`: Frame.gd:380-390 records that Containers created inside `build()` measure and paint nothing (RULES q10). The wrap must be built by the screen after `Frame.build`, or the trap reproduced and explained first.
- **Branching on the setting** — TOWN-03 "fade in/out … (tween gated by reduced_motion)", PIPE-01 and STAGE-04 "under reduced_motion a static 600 ms hold-then-fade": test_motion's rule is that call sites never branch — they pass `GameSettings.motion_duration(ms, floor_ms)` and a 0 s tween still arrives. Write the hold as `floor_ms`, not an `if`.
- **Unknown GameSettings keys** — STAGE-06's `--set=backdrop=…` is refused (its verifier); RULES-09 pins the CVD key's name to `colourblind_safe`; M6-JUICE-02's transition switch is `TRANSITION_MS`. Every new key needs the docs/13 §15.1 row + `Settings.ROWS` entry (RULES §4) in the same commit.
- **One test, two editors** — STAGE-01 and COMBAT-01 both rewrite test_scene_stage.gd:534-566 (boss feet band). STAGE owns it (its `marks` design replaces the hard-coded rows).
- **The lint's text is a contract** — KIT-10 adds a `Color("` line to tools/lint_motion.sh: test_motion.gd:97-116 reads that file for five literal strings, so add, never rename or split.

## Re-ratings

| Finding(s) | Rated | Should be | Why |
|---|---|---|---|
| HALL-05 + COMBAT-10 — system colour emoji as the morale glyph | P1 / P1 | **P0** | It is on nine of the thirteen shots (Town, Board, Prep, Results, Guildhall + its strip, RaiderDetail, Tavern, Market) — the one anti-aliased, non-pixel element on every card in the game, and the loudest "not a real team" tell against the designer's bar; HALL-05's fix needs no new asset. |
| STAGE-05 — the crystal pulse quads are hard-edged rectangles | P1 | **P0** | A visible UI-looking box floats on the art of RaidPrep, RaidView and Results — the combat surfaces the directive names first — measured as a 2x luminance step at every rect edge; a shader feather, no asset. |
| KIT-03 / TOWN-05 / HALL-19 — the day chip flips between sun and sigil; the wordmark resizes | P1 / P2 / P3 | **one finding, P1** | Same defect rated three ways; the header is on twelve of thirteen screens and "reads as two builds stitched together" (TOWN-05); one-function fix. |
| STAGE-11 — the tavern hearth strip is cut at 48 px on a 64 px strip | P2 | **P1** | The brightest object in the Tavern jitters sideways on every frame at 9 fps; the fix is one number. |
| CRITIC-G01 — no splash, no clear colour, non-square icon | — | **P0** | The exported build's first frame is the engine's logo; on 16:9 the bars are engine grey all session. |
| KIT-14 — the reputation chip is a gem | P2 | **P1** | A canon breach ("no gems", the designer's own list) on every screen's header; cheap once ruled (Q06). |
| TOWN-02 — "Canon lists this one as a maybe. Disabled in this build." on the hub | P1 | **P1 (flagged)** | Not re-rated, but it is the only *build note* a player reads, on the first screen after the menu; the copy ruling (Q13) is cheap and should not wait for the callout rebuild. |
| RULES-02 — `text_scale` live and applied nowhere | P1 | **P1, wave 0** | docs/13 marks it Blocking: Yes and every wave adds fixed pixels (G15); it is a prerequisite, not a finding to schedule. |
| TOWN-14 — the hub's plate is assigned two ways | P0 | **P1** | A documentation conflict (BUILD_STATE table vs tree); nothing visible is wrong and HALL's plan resolves it operationally (C01). |
| PIPE-03 — the boss stands ~120 px | P0 | **P1** | The visible defect is STAGE-01/COMBAT-01 (P0, kept); PIPE-03 is the asset ruling behind them. |

Down-rates are offered, not insisted on; the two up-rates to P0 are.

## Questions for the designer

Only what canon and the three references cannot settle. Each is asked once here; the reports' duplicates are folded in.

1. **Figure scale (C10).** 2x for every figure on the camp and both arenas (the plates' own tents, crates and posts say so; spec 02:268's reference bodies are 81-104 px). Does the tavern stay 1x or take the 1.5x exception docs/12 §3.3 allows? (STAGE q1, COMBAT q2, PIPE q2)
2. **Boss mass (C10).** How tall should a main boss stand on the 1536 frame — docs/12's 192 art-px, ~300 px, or the reference's ~580? And may a boss be integer-upscaled (07 §4.1 warns 2x "reads as chunky") or must it be re-authored? (PIPE q1, COMBAT q2, STAGE q2 is sign-off only)
3. **Hall vs hub on one camp plate (C01).** Same framing and dim as Town (a panel over the same camp) or a distinct framing/tint so the hall reads as its own place? Default lands as "same".
4. **Bubble chrome (C02).** One text bubble everywhere: the dark callout chrome (Concept 3's camp) or the navy plate (Concept 2's fight)? And the emote vocabulary beyond "…" (mug, sweat, skull, zzz, heart, !, ?) and what drives each. (PIPE q4)
5. **Header lockup (C12).** Same on every framed screen — 44 px + tagline (Concept 3) or 58 px without (Concept 1)? Both reports recommend 44 + tagline.
6. **Reputation chip (KIT-14).** Keep the reference's gem (00 §2.5's recorded choice) or a reputation sigil, given "no gems"?
7. **Overhead bars (C06).** Badge + pips on all twelve with the HP bar only on the acting/struck figure, or a bar on every figure?
8. **Depth of field (C17).** The references show no blur; docs/12 calls tilt-shift non-negotiable; spec 11 defers it. On (strength?) or off? The vignette ships regardless behind `reduced_effects`.
9. **Screen change (RULES-03).** Does "the desk does not move" forbid a 110 ms opacity cross-dissolve, or only spatial slides? Also gates the wipe's t=1,800 slide.
10. **Town focus entry (RULES-06).** Rail-first (as built and tested) or hotspot-first (§13.2, PROPOSED)?
11. **Levels on cards (HALL-24).** Display-only "Lv. N" on every card, or none (canon 00 §2.3)? The fixture shows four with and eight without.
12. **Combat copy.** (a) May "Main Boss" become a creature name in content (COMBAT-05)? (b) The comedy line vs the tally on Results — options (a)/(b)/(c) (COMBAT-20)? (c) May the player leave mid-account, or is the first watch mandatory (COMBAT-14)?
13. **Hub copy.** What does a player read on the locked Blacksmith callout (TOWN-02; the test pins the word "maybe")? And does "Pauline_4" stay as the handle joke (TOWN-20)?
14. **Settings controls (C16).** Keep the recorded cycle buttons (lit when engaged), or add toggle/segmented/slider widgets the references lack?
15. **Tutorial lesson (G14).** Should A0's scripted round-3 mistake and TR's "read the Wipe Report" be surfaced on RaidView/Results, or stay as Board blurbs?
16. **Accessibility rulings held by RULES.** CVD: a player option or the only ramp, and the ten hexes (RULES q4); the text floor at the 1.0547 letterbox (RULES q3); what `prose_font_swap` means now (RULES q5); is the pre-rendered logotype exempt from §14 (RULES q6)?
17. **Morale faces as sprite art (C09).** docs/12 §5.2's PROPOSED reading of canon's emoji notation — confirm, so HALL-05's font route is canon.
18. **Asset-scope rulings the clusters need before drawing.** The first visible-change tranche on the camp (TOWN-15) and what the guildhall IS on that plate with its four levels (HALL-18); HSV-derived variant busts vs drawn ones (HALL-06); the three fumble flavours to animate first (STAGE q5); normals or a global light (STAGE q6); aerial-scale townsfolk or an establishing shot (PIPE q6); the warrior glyph — shield or crossed swords (PIPE q9); which sim states get a glyph (PIPE q5); one attack and one support VFX family per class (PIPE-02); Raid Group tab — read-only view or retired (HALL-21); which encounters fight in the dungeon (Q-96, STAGE q3); the hub's crimson control — "Go to prep" (TOWN q3).

Decidable without the designer (and therefore not asked): the rail label (C13), the header's *sameness* (spec 03 §6), the callout geometry (spec 03 §3), the pager placement (spec 10 §2 R1), the stamp (docs/13 §7), the icon grid (C03), the confirm and reason idioms (G05/G06), the splash/icon/clear colour (G01), the wide-display sheet (G03).

## Files read

Reports: build/plan/artaudit/{COMBAT,KIT,HALL,TOWN,STAGE,PIPE,RULES}.md in full. Shots: scratchpad/shots/*.png (13) viewed at 1536x1024. References: ideaboard/Reference Concepts/Reference Concept 1.png, 2.png, 3.png. Tree (greps and excerpts only): project.godot:1-60, export_presets.cfg (icon/name lines), build/plan/q-housekeeping.md:45-67, game/ui/Boot.gd:26-79, :100-130, :137-178, game/screens/LoadSave.gd:266-300, Market.gd:410-445, RaiderDetail.gd:340-382, Tavern.gd:612-640, RaidView.gd:425-447, :993-1012, game/core/LogPlayer.gd:22-51, game/core/GameSettings.gd:41, :284-291, game/ui/Theme.gd:171-183, game/ui/Fonts.gd:44, game/screens/AdventureBoard.gd:242-256, :381-414, tests/unit/test_tutorials.gd (test names), tools/shot.gd:51-58, tools/shot_all.sh:15-40. Not run: Godot, Aseprite.
