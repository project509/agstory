# RULES — the contracts that constrain any UI rewrite

Report key: RULES. Date: 2026-09-13. Phase: read-only audit (no tree edits, no Godot, no Aseprite).

## Scope

Cluster: the contracts that constrain any UI rewrite, and the tooling that measures it. Read: every test under `tests/unit/` that mounts a screen or reads `game/ui`, the a11y smoke instrument, the two lints, the eight-stage gate, the shot/fixture/diff instruments, the router, the settings inventory, the Frame/Theme/Type/Widgets/Cards/SceneStage APIs, docs/13 §4.4/§7/§12/§13/§14, spec 11 §3-5, BUILD_STATE's art directive, LESSONS.md, audit.json's art rows, the baseline verify log, and three of the thirteen fixture shots (AdventureBoard, RaidView, Town — to ground the a11y warn and the focus/hotspot findings). Full list under "Files read". Read-only; no Godot, no Aseprite.

## Summary

- Screens are read by tests through ONE mechanism — a walk that collects `Label.text` and `Button.text` — and by the keyboard instrument through node NAMES (`Nav_*`) and `focus_mode == FOCUS_ALL`. §1 lists every exact substring, button text and name each screen must keep; an art pass may change any pixel that is not one of those.
- Every visual must go through five doors: `Widgets.tween` + `GameSettings.motion_duration` (lint-enforced), `SceneStage.apply_settings` for world motion/effects, `Cards.morale_glyph` for glyphs (lint-enforced), `Type.at`/`Theme.get_theme(scale)` for text scale, and Theme.gd's `_button()` for the focus ring. §2 says how; §4 says who owns each shared file.
- The measurement loop is `with_godot_lock.sh` → `shot.gd` (real display, `--fixture[=raid]`, `--completed`, `--set=k=v`) → Read → `refdiff.py` with masks; `diff_all.sh` scores only 3 of 13 screens and the new `shot_all.sh` scores none (RULES-11).
- The baseline gate was red on one register citation, fixed seven minutes later (d8c57f9); the 40 `survivors` SCRIPT ERRORs are stub noise that hides real failures (RULES-01). Indentation is per-file, not per-directory: Market/RaidPrep/Results/Badge/Bar/Boot use spaces.
- Fifteen findings: one P0 (the five hall screens still on `guildhall_plate.png`, with the conversion contract), one P1 (`text_scale` is live in Settings and applied nowhere), and six rulings a designer must give before agents can proceed (transitions, Town focus entry, CVD ramp/option, font swap, logotype-as-text, Settings' inherited plate).
- Two "art pending" comments are now false (RaidView's blot/seal, MainMenu's water) and need `LIES` rows so they cannot rot again.

## 1. Test contracts per screen

How the tests SEE a screen (the mechanism every rewrite must keep):

- `tests/unit/test_screens.gd:66-85` — a screen is mounted by `Router.goto(path)` into a bare `Control` host named `TestHost` under the SceneTree root, and read back by `_texts()`, which walks the subtree and collects **only `Label.text` and `Button.text`** (nothing from RichTextLabel, TextureRect, Sprite2D, tooltips, or bbcode). `_find_button(n, text)` (`:337`) finds a `Button` by exact `.text`. Consequence: any string the tests assert must live in a `Label` or `Button` (a `RichTextLabel` heading breaks the test even though the player sees it; a tooltip-only reason breaks `:383-400`).
- Autoloads are provided by the test if absent (`:49-61`): `GameState`, `ScreenRouter`; `GameSettings` is added on demand (`:838-846`). Screens must therefore tolerate `GameSettings` being absent (see `Cards.morale_glyph(_root, ...)` taking the tree root).
- The GameState in most of this file is CONTENTLESS (`:212-217`, `:606-611`): `new_game()` without content builds no roster. A screen that hard-requires content (e.g. iterates `st.content.classes`) will crash under `test_the_town_prints_the_guild...` (`:221`).
- Tests use FOUR-space indentation (this file), not tabs; do not mix when adding cases.

### test_screens.gd — per-screen assertions (Label/Button text, exact substrings)

| Screen (scene) | Must print (substring) | Must NOT print | Buttons found by exact text |
|---|---|---|---|
| Boot.tscn, MainMenu.tscn, Town.tscn | must exist on disk (`:89-93`) | | |
| MainMenu | "A Guild Story", "New Guild", "Continue", "Quit" (`:180-183`); "No saved guild found." when no save (`:194`); "Continue — Saved Guild" when slot 0 holds a guild named Saved Guild (`:210`) | | |
| Town | guild name, "60 G", "Day 1", "Roster 0 of 15", "Unknown" (`:230-235`); "Guildhall","Tavern","Market","Adventure's Board" (`:309`); "maybe" (blacksmith reason, `:311`); "Reach Respected" / "Costs 300 G" / "Not built in this version yet." depending on rank/price (`:346-381`); "Next at Known" + "Quest board" (`:407-409`); "the highest standing there is" + "Guildhall facility upgrade IV" at Legendary (`:415-417`); "Level 1 of 3" + "reputation raises this, not gold" / "Level 3 of 3" (`:425-430`) | "Disabled in this build" (`:353`); "Next at" when Legendary (`:418`) | `Blacksmith` must be a **Button**, `.disabled == true`, still present (`:395-397`) |
| Town (static) | `TownScript.BUILDINGS` size 5, names exactly `["Guildhall","Tavern","Market","Blacksmith","Adventure's Board"]` (`:240-245`); id "board" name "Adventure's Board" (`:253`); blacksmith `flag == "blacksmith"` (`:294`) | | |
| AdventureBoard | "Unknown", "120 more to Known", "Raid 2" (`:267-271`); "double reputation" when `st.stalled` (`:286`); when `st.completed`: "The campaign is finished. The guild is not.", "Legendaries 0 of 9", "Records 0 of" (`:689-693`) | when completed: "tier 6","heroic","new game+","prestige","difficulty" (lower-cased, `:723`); "The campaign is finished" when not completed (`:705`) | |
| Completion | guild name, "day 91", `st.rank_name()`, "Gold in the strongbox" (`:502-505`); "Legendaries 0 of 9" (`:519`); every non-empty line of `Completion.credit_lines()` verbatim (`:567-571`); credits must contain "not written yet" (`:577`); building the screen sets `completion_seen = true` (`:533`) | | `Back to town — the guild carries on` → pressing routes the AUTOLOAD router to Town (`:547-550`) |
| Results | ordinary clear: "Return to town", "Back to the board" (`:622-623`); completing clear: "See how it ended" and NOT "Return to town" (`:615-618`); seen ending: "Return to town" and NOT "See how it ended" (`:630-632`) | | |
| Guildhall (Records tab) | after pressing Button `Records` (must be enabled at Known): "Legendaries 0 of 9", "Records  0 of" (two spaces, `:746-749`); "paid its share" after pressing `Claim` with 0 lifetime gold (`:808`); "G" somewhere on a locked wall (`:792`) | | `Records`, `Read the ending again` (only when `st.completed`, `:648`/`:665`), `Claim` (only when earned, `:779`/`:790`) |
| Guildhall, Tavern, Market, RaiderDetail (MORALE_SCREENS `:830`) | with `emoji_free` on: no glyph from `Enums.MORALE_BAND_EMOJI` in any Label/Button (`:883`); Tavern must still print a `Enums.morale_band_name()` word (`:910`); with the option off the Tavern DOES print an emoji (`:928`) | | |
| Widgets (static) | `Widgets.button_with_reason(text, reason)` returns a box; `Widgets.button_of(box)` finds the Button; disabled iff reason non-empty; reason is a Label in the box (`:432-443`) | | |
| Palette (static) | `Palette.RARITY.size() == Enums.RARITY_KEYS.size()`; `rarity_color(-1/99) == TEXT_MUTED`; `morale_color(14)==DANGER`, `(45)==CAUTION`, `(90)==POSITIVE`; none of the 16 named tokens + RARITY may be `#000000`/`#ffffff` (`:445-470`). Token names that MUST keep existing: GROUND_PAGE, GROUND_FRAME, GROUND_RAIL, SURFACE_PANEL, SURFACE_INSET, EDGE_SLATE, EDGE_BRONZE, TEXT_TITLE, TEXT_BODY, TEXT_MUTED, TEXT_SLATE, CTA_TOP, DANGER, CAUTION, POSITIVE, ACCENT_GOLD, RARITY. |
| Router | `goto` replaces stack; `push/pop`; `pop` at root refuses; failed goto leaves the current screen; host has exactly ONE child after two gotos (`:159-169`, so no lingering transition layers/overlays parented to the host) | | |

### a11y_smoke.gd — keyboard behaviour (a separate instrument, exit code, not a test_*)

Run: `godot --headless --path . --script res://tests/unit/a11y_smoke.gd` (`tests/unit/a11y_smoke.gd:5`) under the Godot lock. It mounts the 13 screens in `SCREENS` (`:43-57`) into a 1536x1024 full-rect host named `SmokeHost` (`:136-143`), waits `SETTLE_FRAMES = 12` (`:62`), and sweeps TWICE: pass "empty" (no guild, every list empty — where the rail trap lives) and pass "fixture" (`Fixture.apply(state, null, true)`, `:92`). What each screen must satisfy after `goto()`:

1. **Exactly one focus owner, inside the screen, with `focus_mode == FOCUS_ALL`** (`:172-179`). A screen that grabs nothing fails as "mouse-only". This is the rule any new custom-drawn widget must obey: whatever it replaces must still call `grab_focus()` on the first rail item in `_ready`/after layout.
2. **Rail items are identified by node name prefix `Nav_`** (`:187`, `:213`, `:298`). The focus owner must be `rail[0]` — the first `Nav_*` Control in tree order (`:189`). Renaming rail buttons, or reordering their tree position, breaks this even if they look the same.
3. **The Tab ring closes** (`find_next_valid_focus()` returns to the owner) without revisiting a stop (`:194-210`), and it must **leave the rail** if any enabled non-`Nav_` BaseButton is visible (`:222-224`).
4. **Every enabled visible BaseButton is `FOCUS_ALL`** (`:226-231`), i.e. no `FOCUS_CLICK`/`FOCUS_NONE` buttons. Icon-only buttons print as `<Class Name>` in the log (`:353-355`) — so name them.
5. **Rail arrow ring**: `find_valid_focus_neighbor(SIDE_BOTTOM)` from `rail[0]` visits every rail item and wraps back (`:243-258`). A rail rebuilt as a `VBoxContainer` of plain `TextureButton`s keeps this only if `focus_neighbor_bottom/top` are wired (see test_a11y.gd below).
6. **Every FOCUS_ALL visible Control is reachable** from the owner by the closure of next/prev/four neighbours (`:260-281`). Orphans fail.
7. Reported as `warn` but not failed: a non-button Control with a `gui_input` connection and `focus_mode != FOCUS_ALL` ("pointer-only gesture", `:233-241`, `:315-324`). Any new hover/drag widget in Cards.gd or SceneStage.gd will show here.
8. Visibility is `is_visible_in_tree()` (`:295`, `:306`, `:361`): controls hidden behind a collapsed tab are exempt, so tab panels that use `visible = false` are fine; tab panels that use `modulate.a = 0` are NOT (they stay focusable and count as stops).

Consequence for an art pass: nodes' NAMES carry the contract (`Nav_*`), not their class. A rail of `TextureButton`s or a custom `Control` with `focus_mode = FOCUS_ALL` is allowed provided the names and the neighbour wiring survive.

### test_a11y.gd — InputMap, focus ring, Frame focus wiring, Esc/Start/F1

Mounts MainMenu, Town, AdventureBoard, Settings (`tests/unit/test_a11y.gd:22-25`, `:609`, `:679`). Contracts:

- **InputMap** (`:28-38`, `:109-131`): actions `nav_toggle`(Space), `nav_prev_subject`(Q), `nav_next_subject`(E), `nav_cycle_filter`(F), `nav_codex`(F1), `nav_sort_1..4`(1-4) exist in project.godot; letters/digits bound as PHYSICAL keycodes (`keycode == 0`). Gamepad A/B/Start bound (`:174-197`); `nav_settings` fires on JOY_BUTTON_START (`:796`).
- **Theme focus ring** (`:229-277`): `Theme_.build()` must expose >= 9 theme types whose variation base chain reaches `Button` or `LinkButton` (`:212-226`, `:235`); EVERY one has a `focus` StyleBoxFlat with border 2/2/2/2, `expand_margin_* >= 2`, `border_color == Palette.EDGE_STEEL`, `bg_color.a == 0`, and identical `corner_radius_top_left` / `expand_margin_left` to `Button`'s ring. So: **a new button variation (e.g. a pixel-art nine-slice `StyleBoxTexture` button) must still register its `focus` slot as a StyleBoxFlat with those numbers** — texture buttons may replace `normal/hover/pressed`, never `focus`. `Palette.EDGE_STEEL` must keep existing. `LinkButton` must have `font_focus_color` (`:265`).
- **Widgets.link()** (`:279-353`): returns a LinkButton with `focus_mode == FOCUS_ALL` (engine default is FOCUS_ACCESSIBILITY in 4.7.1, `:317`), `underline == ON_HOVER`, a `focus_entered` handler that flips underline to ALWAYS and back on `focus_exited`; `Widgets.link(text, true)` = always-underlined with no handler.
- **Frame focus model** (`:360-547`): `Frame.build(host, {"nav": Frame.nav_items(r), "active": "home"})` returns parts `p` with `p.nav_buttons[id]`, `Frame.chips(p)`, `p.scene`, `p.strip`. `Frame.focus_order(p)` returns regions in READING order: `[rail, chips/header, scene content, strip/commit]` (`:386-392`), wraps at both ends (`:457-459`), Tab from ANY rail item leaves the rail (`:469`, `:510-512`), arrows (all four sides agree, `:442`) step inside the rail and wrap (`:471-475`), disabled nav items (those with a `reason`) are skipped by both Tab and arrows (`:515-529`), idempotent on re-call and no control Tabs to itself (`:532-542`), a region that shrinks to one member clears stale neighbours (`:702`). `Frame.tab_steps_within_region` static switch flips Tab to a control step (`:478-491`). `Frame.focus_entry(p) == p.nav_buttons["home"]` (`:547`). `Frame._focusable(c)` and `Router._can_focus(c)` reject FOCUS_CLICK/FOCUS_ACCESSIBILITY (`:325-345`).
- **Initial focus** (`:552-650`): a screen may define `default_focus() -> Control`; otherwise `Router.initial_focus_target()` uses `Frame.META_FOCUS_ENTRY` meta (shell screens → rail[0]) else first FOCUS_ALL focusable in tree order. Target must be FOCUS_ALL, inside the screen, stable across calls. At least one of MainMenu/Town/Board/Settings must have reading order != tree order (`:649`) — i.e. Frame.build must keep adding the scene host BEFORE the rail in tree order (`:382-383`, `:633-635`). **This pins Frame's z-order trick**: scene layer first, chrome after.
- **Router wiring** (`:668-699`): after `goto()`, Town/Board/Settings carry `Frame.META_FOCUS_ORDER` meta; `>= 2` regions, rail `>= 2` items, Tab leaves rail from every item, `initial_focus_target == rail[0]`.
- **Esc/Back** (`:762-847`): `r.back()` pops; from Town it pushes Settings (depth 2); at MainMenu it refuses; `nav_settings` from any screen pushes Settings once (inert when already open); F1 → `Router.CODEX_SCENE` if it exists else no-op; physical Escape key reaches `_unhandled_input`.
- **Harness fact** (`:731-759`): nothing in run_tests.gd is inside the tree; `_ready` never fires, `grab_focus()` fails, `find_next_valid_focus()` is null. So any screen logic placed in `_ready()` is INVISIBLE to test_*.gd — screens build in `on_enter()`/`_init`-time code paths the router calls (see §ScreenRouter below). Tween/animation code in `_ready` also never runs under tests; that is fine, but text asserted by tests must not wait for `_ready`.

### test_motion.gd — the motion API and the lint that guards it

- `GameSettings.motion_scale()` is 1.0 normally, 0.0 under `reduced_motion` (`tests/unit/test_motion.gd:49-60`). `motion_duration(ms, floor_ms = 0)` returns seconds; collapses to 0.0 under reduced motion EXCEPT it keeps `floor_ms` (the stamp's 60 ms, `:63-68`); 0 or negative → 0.0 (`:75-83`). Call sites therefore NEVER branch on the setting: they tween for `motion_duration(...)` seconds and a 0.0 tween applies the final value next frame ("arrive instantly, still arrive").
- `Widgets.tween(node)` is the ONLY tween factory; returns null for null or a node not inside the tree (`:88-95`).
- The test reads `tools/verify.sh` and `tools/lint_motion.sh` as text (`:97-116`): verify must contain "lint_motion.sh"; the lint must contain "MOTION LINT OK", "create_tween", "game/ui/Widgets.gd", "MORALE_BAND_EMOJI", "game/ui/Cards.gd". Renaming or splitting the lint breaks this test.
- Flash rule: `Settings.MAX_CHANGES_PER_SECOND == 3.0`, `flash_rule_applies_to("ui") == true`, `("world") == false`, `FLASH_RULE_COUNTS_WORLD_MOTION == false` (`:121-137`). `test_the_literal_reading_would_cost_every_fire_in_the_game` (`:139-156`) REQUIRES at least one `props`/`actors` entry in some `game/assets/scenes/*.json` to have `fps > 3` — i.e. the world layer must keep an animation faster than 3 fps or this test fails (it is a measurement, a designer's number: see Open questions).
- `game/ui/SceneStage.gd` must contain the literal text `func apply_settings(reduced_motion: bool` and the word `reduced_motion` (`:163-167`). Do not rename that method.

### test_wipe_sequence.gd — RaidView's wipe beats (docs/13 §11.4)

Mounts RaidView with `st.last_result.outcome = WIPE`, `selected_encounter_id = "t1_raid_e5"`, seed 5 (`tests/unit/test_wipe_sequence.gd:53-82`). Constants on `RaidView.gd` that must keep their names and values: `WIPE_BEAT_SILENCE_MS=0`, `WIPE_BEAT_LINE_MS=400`, `WIPE_BEAT_STAMP_MS=900`, `WIPE_BEAT_DIM_MS=1400`, `WIPE_BEAT_EXITS_MS=2400`, `WIPE_STAMP_MS=180`, `WIPE_STAMP_FROM=1.15`, `WIPE_STAMP_TILT_DEG=-7.0`, `WIPE_DIM=0.12`, `WIPE_STAMP_FLOOR_MS` (60), `WIPE_BLEED_MS=400`, `WIPE_BLOT`, `WAX_SEAL` (paths that must exist), `FRAME` (Vector2). Source-text contracts (`:181-201`): RaidView.gd must contain the literal strings `func _run_wipe_sequence(elapsed_ms: float)`, `_run_wipe_sequence(float(WIPE_BEAT_EXITS_MS))`, `if _wipe_beats.has(method)`, and must NOT contain `await get_tree().create_timer`. Members read directly: `_wipe_shown`, `_wipe_dim`, `_wipe_blot`, `_wax_seal` (with `.position` past half of FRAME in both axes, `:283-286`), `_wipe_stamp_label` (its parent's sibling index must be greater than `_wipe_blot`'s: ink under stamp, `:294-297`). Exactly one Label/Button with text `WIPE.` after running the sequence 5 times (`:236-246`). **Any redesign of the wipe (e.g. a shader-driven stamp or a particle bleed) must keep these member names, the sibling order, and the "WIPE." label; the visuals under them are free.**

### test_scene_stage.gd — the world layer (SceneStage.gd, actors.json, class_actors.json, scenes/*.json, enemies/)

Node-name and data contracts (`tests/unit/test_scene_stage.gd`):
- `SceneStage.from_data(name, dict)` builds a stage from a dictionary with keys `actors`, `embers`, `shimmer`, `pulse` (`:39-42`, `:124`, `:226-229`, `:574`, `:597-600`). Actors are `AnimatedSprite2D` children named `Actor_*` with an `"idle"` animation (`:54`, `:132`), `is_playing()` true by default (`:134`), **added in ascending `pos.y` (back-to-front tree order, no z_index)** (`:137-151`), `offset.y == -frame_h/2` (planted by the feet, `:154-163`), `scale`/`flip`/`tint` keys honoured (`:166-173`), phase or speed spread across a crowd (`:176-191`), unknown `who` skipped not fatal (`:194-202`).
- `game/assets/actors/actors.json` `actors{key: {frames, frame_w, frame_h, fps, moving_px, kind}}`: >= 12 entries; every strip PNG at `game/assets/actors/<key>.png` is exactly `frames*frame_w` x `frame_h` (`:61-82`); every actor has `frames >= 2`, `moving_px > 0`, `fps > 0` (`:85-98`); `cleric`, `warrior`, `variant_r01_black` must exist and their frame 2 differ from frame 1 in pixels (`:101-118`). **A new actor strip = PNG + manifest row, or the suite goes red.**
- `game/assets/scenes/*.json`: every `actors[].who` names a manifest key (`:242-263`); every `shimmer[]`/`pulse[]` `rect` is `[x,y,w,h]` inside 1536x1024 and there are >= 10 such rects in total across all scene files (`:631-659`).
- `game/assets/actors/class_actors.json`: `classes{key: {actor, figure, family}}` for all 9 canon classes, actors exist, no two classes share an actor, one figure per armour family unless listed in `family_exceptions{key: reason > 20 chars}` (>= 1 entry), `unclaimed{key: reason}` covers every `kind == "sliced"` figure no class uses (`:293-399`). `SceneStage.actor_for_class("monk") == "rogue_b"`, `("bard") == "warrior_b"`, `("mage") == "mage"`, unknown → `""` (`:402-411`).
- `stage.apply_settings(reduced_motion: bool, reduced_effects: bool)`: reduced motion → every actor `is_playing() == false`, `frame == 0`, `stage.is_processing() == false`, `stage.motion_held() == true` and later `place_party()` sprites also held (`:211-222`, `:460-470`); shader `motion` uniform → 0.0 on `Shimmer_*` ColorRects and `Pulse_*` alpha returns to base (`:594-615`). Reduced effects → `WorldEnvironment.environment.glow_enabled == false`, every `GPUParticles2D.emitting == false`, actors STILL playing (`:225-237`); `Shimmer_*`/`Pulse_*` `visible == false` (`:618-628`).
- `stage.place_party([{who, pos, id}]) -> {id: AnimatedSprite2D}`, same back-to-front rule, one `Sprite2D` named `Shadow_*` per figure (`:422-457`). `SceneStage.party_state_style("" | "Downed" | "dead") -> {still, tint, rewind}` (`:473-484`).
- `stage.place_boss(tex, pos) -> Sprite2D` with `offset.y == -h/2`, plus a `Sprite2D` named exactly `BossShadow`; null tex → null; single-texture boss bobs in `_process` and reduced motion returns it to base y (`:498-531`). `RaidView.boss_feet_y(h)` must put every PNG in `game/assets/enemies/` (>= 6) with head >= plate y 398 and feet within plate y 481..556 (`:534-563`) — **this hard-codes the current RaidView stage offset (-280) and the arena plate's stone band; moving the arena viewport or the boss plate chrome (screen y 53..118) changes these numbers and the test must move with it.**
- Shimmer shader uniforms: `strength == 0.024`, `tex_scale == 64.0`, `speed_a == Vector2(0.02, -0.013)`, `motion == 1.0` (`:573-591`) — spec 09 §5's numbers.

### tools/lint_motion.sh — the two doors

- Strips `#` comments, then greps every `.gd` under `game sim tools` for `create_tween(`; the ONLY allowed file is `game/ui/Widgets.gd` (`tools/lint_motion.sh:66-69`). Under `game/` the pattern `MORALE_BAND_EMOJI|morale_band_emoji` is allowed only in `game/ui/Cards.gd` and `game/core/GameSettings.gd` (`:71-74`). Not covered: `AnimationPlayer`, `AnimatedSprite2D`, shaders, `GPUParticles2D` (`:37-40`) — those are the world layer and must consult `apply_settings()` themselves. Verdict line `MOTION LINT OK` (`:77`).
- Practical rule for an art pass: every UI animation = `var t := Widgets.tween(self); t.tween_property(..., GameSettings.motion_duration(ms[, floor_ms]))`. Any shader/particle = read `reduced_motion`/`reduced_effects` through `SceneStage.apply_settings` or an equivalent uniform/`emitting` gate, and add a test in the style of `test_reduced_motion_stops_the_water_and_the_pulse`.

### Other screen tests — exact substrings they read (all via the same Label/Button walk)

| Test file | Screen | Must print (Label/Button text) | Buttons / structure |
|---|---|---|---|
| test_loadsave_screen.gd | LoadSave | "Guild Slots", "Slot 1 — Slotted", "Slot 2 — empty", "Slot 3 — empty" (`:158-161`), "Slot 2 is empty." (`:175`), "damaged" (`:189`), "newer build" (`:205`), "Yes — overwrite Slot 1", "Keep it" (`:235-236`), "Slot 2 — Fresh" (`:258`), "Yes — delete Slot 1" (`:291`), "Slot 1 — empty" (`:300`), "No guild loaded." (`:311`), "Load Guild" (`:338`), "Save / Load" (`:348`) | confirmation is inline text + buttons, not a modal the walk cannot see |
| test_raider_detail.gd | RaiderDetail | "<name> — 54" (`:145`), "misses about" (`:156`), "Nobody selected" + "Back to the roster" (`:163-164`), "empty" (`:190`), "<n> AC" (`:198`), "50 base", "baseline", "Slots:" (`:251-253`), "Nothing is written down about them yet", "Wants nothing in particular", "Ran 0 raids" (`:285-289`), "They are fine" (`:320`), "Costs 20 G" (`:327`), "falling", "a wipe", "day " (`:455-459`), "over 4 days" (`:468`), "climbing" (`:478`) | a Button whose text contains "(+" (`:219`, the upgrade-delta button); must NOT print "Personal Effect" when none (`:273`) |
| test_settings.gd | Settings | rows per DEFAULTS key, `audio_*` rows grouped (`:343-351`); Audio autoload read (`:414`) | reads Buttons by text (`:299`) |
| test_tavern.gd | Tavern | "Known", "120" (`:167-170`), "nothing left" (`:174`), "50 G" (`:257`), "full" (`:303`), "misses about", "arrives with", "Hire — " (`:423-425`), "-2 morale" (`:449`), "as big as it gets" (`:468`), "Nobody to manage" (`:476`), "Legendaries N of 9" (`:493-519`) | `view._candidate_card(who, index)` must exist and return a Control containing a ScrollContainer with h-scroll DISABLED, v-scroll enabled, all bullets present, combined min height <= `Widgets.CARD_SIZE.y` (test_a11y_legibility.gd `:793-848`); `Widgets.CARD_SIZE.y == Widgets.STRIP_H`, `Widgets.STRIP_Y + CARD_SIZE.y == 996` |
| test_market.gd | Market | "Sell all nobody can wear", "One trestle table" (`:451-453`), "(100 → N)" (`:464`), "worn by <name>" (`:475`), "take it off" (`:485`), "Minor — 8 G" (`:515`), "1 held" (`:524`), "Straw Cot", "does not carry the Feather Bed" (`:549-550`), "Nothing to sell", "Nobody to buy for" (`:580-582`), "Costs 130 G" (`:604`); NOT "Lesser —", "Perfect —" when not stocked | |
| test_comfort.gd | Guildhall > Facilities | "Leaking Guildhall", "Boarded windows", "Repaired Guildhall", "150 G", "+3 morale baseline" (`:649-654`), "Reach Known" (`:664`), "Costs 150 G" (`:676`), "Proper Guildhall" (`:693`), "50 base", "-5 Common", "+0 Guildhall", "+0 furnishings", "45 baseline" (`:702-706`), "+3 furnishings", "Straw Cot" (`:719-721`), "<price> G" per furnishing (`:734`), "Capped at 80", "does nothing" (`:751-753`), "Renowned Guildhall", "nothing left to build" (`:762-763`), "Nobody lives here yet" (`:774`) | |
| test_rest.gd | Guildhall | "Rest until recovered", "Rest a day", "<n> days of rest", "rolls the leave checks", "baseline" (`:322-347`) | |
| test_starting_roster.gd | Guildhall > Roster | "Bob", "Warrior — Slightly Annoyed", "45 " (`:203-206`), "Showing 12 of 12" (`:210`), "Roster average morale 45", "At risk 0", "Tanks 2", "Healers 3" (`:216-220`), tab labels "Raid Group", "Facilities", "Records" (`:224-226`), "not in this version yet" or "nothing to record" (`:227`), "No raiders yet" (`:244`) | |
| test_raid_plan.gd | AdventureBoard / RaidPrep / Results | Board: "Adventure's Board", "Clear A0 first.", "Clear A1 first.", "CLEARED", "Clear A2 first." (`:270-292`); Prep: "Comp check", "Tanks", "Healers", "Expected mistakes", "Baseline at this comp", "Verdict:", "Slightly Annoyed" (`:311-317`); Results: "Rounds", "Mistakes", "What happened", "No attempt to report" (`:421-431`); `RaidPlan.risk_hatch()` uses "/" for elevated risk (`:182`) | |
| test_log_player.gd | RaidView / Results | "Greg (Rogue) — Severe — Pulled Aggro Off the Tank" (`:386`), first text "MISTAKE · Severe · Pulled Aggro Off the Tank" with no newline (`:418-422`); never "— ? —" | the log row's FIRST Label carries the whole line |
| test_full_loop.gd | MainMenu→Town→Board→Prep→RaidView→Results | drives Buttons by text; board rows contain "A1"/"A2"/"TR" and the word "disabled" when locked (`:171`, `:228`, `:450`); Results page prints "Cracked Charm of Power", "+1 Power", "not a good trinket" (`:265-268`); "not in this version yet" or "No saved guild found." (`:384`) | the tutorial loop must remain button-drivable end to end |
| test_savegame.gd | Town / Tavern / MainMenu / RaidView | mounts them after load; slot labels contain "empty" / "damaged" / "2 hours in" (`:601-638`) | |
| test_achievement_board.gd | (board logic) | refusals "Not earned", "Already claimed", "paid its share" (`:189-229`) — the Records tab prints these verbatim | |
| test_project_hygiene.gd | tree | RaiderDetail.tscn listed (`:49`); every `res://game/...` asset reference must resolve (`:105-109`) — a texture path typed in a screen must exist | |
| test_a11y_legibility.gd | Type / Badge / Cards / Tavern | `Type.at(size, scale)`, `Type.step(v)`, `Type.SCALES == [100,125,150] == GameSettings.TEXT_SCALES`, `Type.SCALE_DEFAULT`, `Type.LOG_ROW_PITCH`; the 26 READABLE_SIZES + `STACK` const names must all exist on Type.gd (`:58-68`); exactly `["SMALL","STACK"]` fall under 14px at the 1.0547 letterbox — SMALL == 13, STACK == 11 (`:348-380`); `Badge.glyph_layout(box, font, glyph)`, `Badge.ink_for(fill)` >= 3:1 on DANGER/CAUTION/POSITIVE/INFO/ARCANE/EDGE_SLATE/TEXT_MUTED, `Badge.GLYPH_MISTAKE`, `GLYPH_HEAL`, `Palette.TEXT_ON_BUBBLE`, `ACCENT_BUBBLE` (`:594-642`); `Cards.badge_icon("morale_down"/"morale_up")` non-null, `("")`/`("loot")` null (`:644-655`); only GameSettings.gd + Cards.gd (+ the five `GLYPH_HANDOFF_PENDING` screens, a shrinking allowlist) may reference the raw emoji table (`:93-108`, `:383`) | |
| test_palette_cvd.gd | Palette | `Palette.BAND_FILL_CVD` == docs/13 §8.3's ten hexes verbatim, `BAND_INK_CVD` E8E6D6 for bands 0-4 / 2B2A24 for 5-9 (`:180-193`); `band_color_cvd(m)`/`band_ink_cvd(m)` index `Enums.morale_band` (`:196-203`); the ramp's measured adjacent ΔL* values are asserted EXACTLY (`:63-72`) — a repaint of the CVD ramp turns this red on purpose, and the fills are asserted to be too dark for text on SURFACE_PANEL (`:397-404`). **Do not route `morale_color()` through the CVD ramp.** | |

Screens are mounted by `ScreenRouter._load_into_host()` (`game/core/ScreenRouter.gd:273-314`): instantiate, `PRESET_FULL_RECT`, add to host, call `build()` if present, then `on_enter()`, then `wire_shell_focus()` (invokes the `frame_focus_order` meta Callable), then `grab_focus()` on `initial_focus_target()` only if in tree and visible. `_ready()` NEVER fires under tests or tools (LESSONS.md:24) — **every screen must be fully drawn by the end of `build()`/`on_enter()`**; art added in `_ready()` will be absent from every shot and every test. `_clear_current()` calls `on_exit()`, `remove_child` immediately, `queue_free` later (`:316-329`).

The router has no transitions and "never will" (`ScreenRouter.gd:4-7`, docs/13 §2 M5 "The desk does not move"); docs/13 §12.2's 110 ms cross-dissolve on screen change is therefore unbuilt by ruling, not by omission — M6-JUICE-02 (the wipe's "post-mortem slides out from under", `test_wipe_sequence.gd:16-18`, `RaidView.gd:163`) is blocked on the same ruling.

## 2. Settings every visual must honour

The inventory is closed: `game/core/GameSettings.gd:30-50` `DEFAULTS` is docs/13 §15.1's table and `set_value()`/`get_value()` push_error on any other key (`:69-79`). Keys an art pass reads, and HOW:

| Key | Default | What a visual must do | Mechanism (the one door) | Test that pins it |
|---|---|---|---|---|
| `reduced_motion` | false | UI tweens collapse to 0 s (final value still applied next frame); stamps keep a 60 ms floor and no rotation; world layer (actors, boss bob, shimmer, pulse, fire) holds still on frame 0; shader-time motion is stopped via a uniform, `set_process(false)` cannot reach a shader | UI: `Widgets.tween(node)` + `GameSettings.motion_duration(ms[, floor_ms])` (`GameSettings.gd:225-240`); rotation: multiply by `motion_scale()` (`test_wipe_sequence.gd:157-166`); world: `SceneStage.apply_settings(reduced_motion, reduced_effects)` sets `is_playing=false, frame=0`, `set_process(false)`, `motion` uniform 0.0, remembers via `motion_held()` for later `place_party()` | test_motion.gd, test_wipe_sequence.gd, test_scene_stage.gd `:211-222, :460-470, :521-531, :594-615` |
| `reduced_effects` | false | Glow off (`WorldEnvironment.environment.glow_enabled=false`), particles `emitting=false`, `Shimmer_*`/`Pulse_*` hidden; figures KEEP animating | same `apply_settings()` second argument | test_scene_stage.gd `:225-237, :618-628` |
| `emoji_free` | false | Every morale glyph becomes a 10-char pip string (`"|"*(band+1) + "."*(rest)`, `GameSettings.gd:194-198`); the integer and band word stay | `Cards.morale_glyph(tree_root_or_node, morale)` only; lint forbids `Enums.MORALE_BAND_EMOJI` outside Cards/GameSettings | test_screens.gd `:856-931`, test_a11y_legibility.gd `:383-515`, lint_motion.sh |
| `text_scale` | 100 (100/125/150 only, `:53`, `:107-109`) | Every font size passes through `GameSettings.scaled(size)` (`:202-203`) or `Type.gd`'s equivalent; layouts must not overflow at 150 | `--set=text_scale=150` shot; test_a11y_legibility.gd `:256-317` (identity at 100, three steps, matches autoload) | test_a11y_legibility.gd |
| `prose_font_swap` | false | body prose in a plainer face (docs/13 §13) | Type.gd (verify: see finding RULES-05) | none found yet |
| `display_aspect` | "keep" | 1536x1024 letterboxed on wide displays; `expand` widens the canvas, plates keep their width — so no chrome may assume the right edge is x=1536 unless it is anchored | `GameSettings.apply_display_aspect(window, aspect)` (`:287-291`), `Window.content_scale_aspect` | none (visual only) |
| `sim_speed` | 0 | RaidView speed chips 1x/2x/4x/Instant; Instant gated on first clear | `effective_sim_speed(state, encounter_id)` (`:185-189`) | test_settings.gd |
| `log_manual_advance`, `comedy_brake` | false / true | LogPlayer pacing | game/core/LogPlayer.gd | test_log_player.gd |
| flash rule (not a setting) | — | no UI element changes more than 3x/s; world layer exempt under the shipped reading (BL-75) | `MAX_CHANGES_PER_SECOND`, `flash_rule_applies_to()` (`:248-280`) | test_motion.gd `:121-156` |
| CVD | (no key) | Palette's morale ramp must be L*-monotone under protanope/deuteranope/tritanope/greyscale simulations, adjacent-band ΔL floors, fills are plates not text tints | `game/ui/Palette.gd` ramp + `tools/art/cvd.py` (same pipeline, `test_palette_cvd.gd:153`) | test_palette_cvd.gd (see below) |

Also: `text_scale` is coerced to one of three values, so a UI that offers a slider must snap. `GameSettings.changed(key)` signal (`:58`) exists — a screen that caches a scaled size must reconnect on change or be rebuilt by the router on re-entry. As built, NO screen passes the scale to `Theme_.get_theme()` (RULES-02).

Two further docs/13 constraints with no test behind them, which an art pass is the most likely thing to break:
- **§12.1 latency budget** (docs/13-ui-ux.md:659-672): input → first visible change ≤ 80 ms; screen/tab switch settled ≤ 140 ms; hover ≤ 40 ms with no layout shift ever; number recompute same frame, never tweened; any queued animation interruptible by the next input. No perf test exists (M6-JUICE-07, RULES-15). Practical rule: hover = `Theme` stylebox swap only (no tween, no size change); numbers set `text` directly; every tween is killable (`Widgets.tween` returns the Tween — keep the handle and `kill()` on input).
- **§14 localization/scaling readiness** (`:793-811`): +30% string elasticity at 125% text scale; two-line wrap only on `head.panel`/`body.prose`/`log.line`, never on rows/chips/slot labels (those grow the row); no text baked into sprites or panel backgrounds (shop signage in the world layer is the sole exception); no hard-coded left/right anchors. None of it is enforced (RULES-14); the constraint for the art pass is "words stay Labels, textures carry no glyphs".

## 3. Measurement loop

All engine invocations go through the mutex, because Godot writes `.godot/` and `user://` and two engines in one project corrupt both (`tools/with_godot_lock.sh:4-12`); lock dir `.godot_engine.lock`, waits up to 900 s, breaks a lock older than 1200 s, heartbeats every 30 s (`:23-48`). `$GODOT` comes from `tools/env.sh` (Godot 4.7.1 mono console exe). Run everything from the repo root in Git Bash.

```bash
cd "/c/Users/greyp/OneDrive/Desktop/Gold Projects/The Worst Guild" && source tools/env.sh

# 1. Shoot one screen (real display server needed — NOT --headless: tools/shot.gd:7-11)
tools/with_godot_lock.sh "$GODOT" --path . --script res://tools/shot.gd -- \
  res://game/screens/Town.tscn build/shots/Town.png 40 1536x1024 --fixture
#    --fixture        Fixture.apply(state) — Bork/Tiny/Gruk/Spoof, 12480 G, day 23, rep 320, t1_raid_e5 selected (tools/fixture_reference.gd:25-39)
#    --fixture=raid   also runs one RaidSim attempt on t1_raid_e5 with the 12 highest-morale raiders (:72-81) — needed for RaidView/Results/RaidPrep
#    --completed      sets completed/completed_on_day/completion_seen=false (tools/shot.gd:175-186) — Completion, post-clear Board, Records re-read link
#    --set=key=value  any GameSettings key, e.g. --set=emoji_free=true --set=reduced_motion=true --set=text_scale=150 (:58-66, :157-173)
#    frames (3rd arg) default 30; 40 in diff_all. Exit codes: 2 usage, 3 no scene, 4 null image (headless), 5 save fail, 6 wrong size, 7 missing autoload.
#    The screen is mounted TOP_LEFT with an explicit size inside a SubViewport (:133-143) — a FULL_RECT anchor resolves against the Window, not the SubViewport (LESSONS / memory: right-edge UI blanked).
#    shot.gd calls inst.build() then inst.on_enter() if present (:199-202); it does NOT run the router's focus wiring, so focus rings are absent in shots.

# 2. View: Read the PNG with the Read tool (1536x1024).

# 3. Score against a concept (1=home, 2=combat, 3=camp), masks exclude regions that legitimately differ
python tools/art/refdiff.py build/shots/Town.png 3 --out build/diff --mask 0,77,1536,649
#    prints mae/rmse/structure/layout_iou/palette_divergence/pct_pixels_within_8 and a verdict:
#    INDISTINGUISHABLE  iou>0.80 && mae<6 ; VERY CLOSE iou>0.65 && mae<14 ; RECOGNISABLY THE SAME DESIGN iou>0.45 ; else DIFFERENT (tools/art/refdiff.py:117-120)
#    writes <name>_heat.png (red = error), <name>_sbs.png (ref | shot), <name>_diff.json (:123-135). Size mismatch = exit 2.

# 4. The art gate (three targets, masks baked in): tools/diff_all.sh:22-30
tools/with_godot_lock.sh ./tools/diff_all.sh build/diff
#    Kit.tscn vs 1 (no mask), Town vs 3 (mask 0,77,1536,649 = the whole scene band), RaidPrep vs 1 (mask 210,77,928,640 = the arena viewport)

# 5. The build gate (eight stages)
tools/with_godot_lock.sh ./tools/verify.sh          # or --fast (skips boot, a11y, sweep, playtest)
```

`tools/verify.sh` stages and what each checks (`tools/verify.sh`):
0. class cache rebuild via `--import` if any .gd is newer than `.godot/global_script_class_cache.cfg` (`:30-48`) — this is why the tree must not be edited while another engine runs.
0/8 lint: `lint_no_global_classes.sh` (no cross-file `class_name` refs) and `lint_motion.sh` (`:51-71`).
1/8 parse: `tools/parse_check.gd` must print `PARSE_CHECK OK` (`:74-82`).
2/8 generated content: `gen_items.gd -- check` must print `0 file(s) differ` (`:98-111`).
3/8 unit tests: `tests/run_tests.gd` must print `TESTS PASSED`; 120 s timeout (`:113-123`).
4/8 headless boot: main scene for 180 frames with no SCRIPT ERROR / Parse Error / Cannot open / Failed to load / `Condition "` (`:126-143`). **A missing texture path (`Failed to load`) fails the gate here** even if every test passes.
5/8 keyboard access: `a11y_smoke.gd` must print `A11Y SMOKE PASSED` (`:150-164`).
6/8 balance sweep: `SWEEP OK` (`:167-184`).
7/8 playtest: WARN only, never fails (`:203-218`, M6-BAL-04).

Log: `.verify.log` in the repo root (`:18`).

Every art wave's acceptance is therefore: (a) the new shot, read with the Read tool, shows the thing; (b) `refdiff` verdict for the screen's concept does not regress (record the numbers before/after); (c) `verify.sh --fast` green in the wave, full `verify.sh` green before merge; (d) `a11y_smoke.gd` still passes both sweeps.

## 4. File-ownership hazards

Counted by `grep -l "ui/<Lib>.gd"` over game/screens, game/ui, game/core (2026-09-13). A parallel wave must give each of these ONE owner; everyone else sends exact-edit handoffs (the `build/plan/handoff-*.md` shape).

| Shared file | Files that preload it | Why it is hot | Owner-only rule |
|---|---|---|---|
| `game/ui/Palette.gd` | 22 (every screen + every kit file) | token names are asserted by test_screens `:462-467`, test_a11y `:255` (EDGE_STEEL), test_a11y_legibility `:627-642` (INFO, ARCANE, TEXT_ON_BUBBLE, ACCENT_BUBBLE), test_palette_cvd (BAND_FILL_CVD/BAND_INK_CVD verbatim) | add tokens, never rename or delete; no pure black/white |
| `game/ui/Widgets.gd` | 19 | the ONLY `create_tween()` site (lint); `button_with_reason`/`button_of`/`link`/`tween` signatures pinned by tests; `CARD_SIZE`, `STRIP_H`, `STRIP_Y`, `SCREEN`, `SCENE`, `SIDEBAR` consts pinned (test_a11y_legibility `:836-848`); tabs | additive helpers only; keep every existing constructor's return type |
| `game/ui/Theme.gd` | 15 | `build(scale)`/`get_theme(scale)`; every Button-family variation must carry the 2px-outside `focus` StyleBoxFlat (`_button()` `:125-136` does this automatically — new button variations MUST go through `_button()`); >= 9 Button-family types; LinkButton focus + `font_focus_color`; tabs | one owner for the whole art-kit repaint; textures via `tex()` 9-slice from `game/assets/ui/` |
| `game/ui/Frame.gd` | 14 (13 screens + ScreenRouter by meta name only) | explicit placement, scene host added BEFORE chrome (pinned by test_a11y `:649`), `Nav_*` button names, `META_FOCUS_ORDER`/`META_FOCUS_ENTRY` keys mirrored as string literals in `ScreenRouter.gd:200-201`, `NAV` order = focus order, Containers created inside `build()` do not paint (`:380-390`); tabs | one owner; never rename the meta keys without editing ScreenRouter in the same commit |
| `game/ui/SceneStage.gd` | 9 screens (Town, AdventureBoard, Tavern, Market, MainMenu, Completion, RaidPrep, RaidView, Results) + tests | `from_data`, `load`, `place_party`, `place_boss`, `apply_settings(reduced_motion: bool, reduced_effects: bool)` (literal text pinned by test_motion `:164`), `motion_held`, `party_state_style`, `actor_for_class`, `DEFAULT_ARENA`; node names `Actor_*`, `Shadow_*`, `BossShadow`, `Shimmer_*`, `Pulse_*`; back-to-front rule; tabs | one owner; new layer types = new JSON key + `apply_settings` handling + a test |
| `game/ui/Cards.gd` | 11 | the ONLY morale-glyph door (lint); `card`, `roster_strip`, `event_log`, `badge_icon`, `encounter_art`, `gear_icon`, `loot_slot_icon`; loads the old `boss_sludge_maw.png` crop for the mission well (`:431-432`); tabs | one owner |
| `game/ui/Type.gd` | 9 | the 27 size names are enumerated by test_a11y_legibility `:58-68`; `SMALL == 13` and `STACK == 11` are asserted as the only sub-floor styles (`:88`, `:348-380`) — **changing any size changes that test's expected list; do it with the q-a11y-legible ruling** | one owner (the type pass) |
| `game/ui/Badge.gd`, `Bar.gd` | via Widgets | drawn (`_draw`) not themed; API pinned by legibility tests; spaces | one owner |
| `game/core/GameSettings.gd` | all | closed inventory; `DEFAULTS` keys are the settings-file format (renaming = migration); `motion_duration`, `motion_scale`, `scaled`, `morale_glyph`; spaces | additive only; a new key needs a docs/13 §15.1 row and a Settings.gd ROWS entry |
| `game/core/ScreenRouter.gd` | Boot + tests | no transitions by ruling; mounts via `build()`/`on_enter()`; spaces | do not add a transition layer here (see RULES-03) |
| `game/assets/actors/actors.json`, `class_actors.json`, `game/assets/scenes/*.json` | SceneStage + 3 test files | manifests asserted against PNG geometry and each other; scene rects asserted inside the plate; some scene must keep an `fps > 3` entry | the actor/scene owner regenerates `actors.json` only via `tools/art/gen_actors.py` (LESSONS.md:92-100: median-frame outlier drop, feet alignment) |
| `tests/unit/a11y_smoke.gd` `SCREENS` | — | explicit list, no directory walk (LESSONS.md:141-144) | any new screen is added here in the same commit |
| `tools/diff_all.sh` `TARGETS` | — | 3 targets with hand-typed masks; m4t-08 says 11 screens are on the frame | the measurement owner |

Screen files are single-owner by construction; the pairs that share a scene are `Guildhall.gd` + `Roster.gd` + `Facilities.gd` (Roster and Facilities are hosted inside Guildhall's tabs and have no ground of their own — `grep ground|plate|SceneStage game/screens/Roster.gd` returns nothing), and `RaidPrep.gd`/`RaidView.gd`/`Results.gd` (all mount `SceneStage.DEFAULT_ARENA`; RaidView owns `boss_feet_y()` which test_scene_stage reads).

Indentation per file (see §5): Market/RaidPrep/Results/Badge/Bar/Boot are SPACES inside otherwise-tab directories.

## 5. Red / fragile tests

Source: `scratchpad/verify_baseline.log` (2026-09-13 19:17). Verdict **VERIFY FAILED**.

| Stage | Result | Detail |
|---|---|---|
| 0/8 lint | PASS | LINT OK, MOTION LINT OK |
| 1/8 parse | PASS | 149 scripts |
| 2/8 generated content | PASS | 16 files agree |
| 3/8 unit tests | **FAIL** (stale) | `.verify.log:896-901` (same 19:17 run): `TESTS FAILED 1/1588` — `test_docs_links.gd :: test_every_register_citation_resolves_to_a_declared_entry`: `test_raid_plan.gd:450` and `:466` cite Q-47 while BL-47 also exists. **Fixed by commit d8c57f9 at 19:24** (`test_docs_links.gd:277` now allowlists test_raid_plan.gd for Q-47), seven minutes after the baseline; expected green now, unverified because this phase may not run Godot. The 40 `SCRIPT ERROR: Invalid access to property or key 'survivors'` lines in the summary are NOISE, not failures — see RULES-01 |
| 4/8 headless boot | PASS | 180 frames clean |
| 5/8 keyboard access | PASS | 26 mounts (13 screens x 2 sweeps). One `warn` on the fixture sweep: `AdventureBoard.tscn 10 pointer-only gesture target(s)` — ten anonymous `PanelContainer`s wired to `gui_input` with no focus (the quest cards); reported, not failed (`a11y_smoke.gd:233-241`). An art pass that turns those cards into real buttons closes it; one that keeps them as hover panels must give each a focusable proxy |
| 6/8 balance sweep | PASS | 2304 runs |
| 7/8 playtest | WARN (by design) | 0 of 8 cleared Tier 1 — owned by M6-BAL-04 |

Fragile by construction (would go red on an innocent art change):
- `test_scene_stage.gd:534-563` boss placement numbers (plate y 398 / 481..556) are tied to the current arena plate and the -280 stage offset.
- `test_wipe_sequence.gd:283-286` seal position vs `RaidView.FRAME`; `:294-297` sibling order of blot and stamp box.
- `test_motion.gd:139-156` REQUIRES some scene JSON to keep an `fps > 3` entry.
- `test_a11y.gd:649` REQUIRES at least one of MainMenu/Town/Board/Settings to have tree order != reading order — i.e. Frame.build must keep adding the scene host before the rail.
- `test_a11y.gd:235` requires >= 9 Button-family theme types — deleting variations from Theme.gd breaks it.
- `test_screens.gd:749` asserts the literal `"Records  0 of"` with TWO spaces — a heading re-typeset with one space breaks it.
- `test_screens.gd:159-169` host has exactly one child after two `goto`s — a persistent transition/vignette layer parented to the host breaks it (parent it to the screen, or to Boot's overlay).
- Every `_texts()`-based assertion breaks if a Label becomes a RichTextLabel or a texture.

Indentation (verified by counting leading-tab vs leading-4-space lines): `sim/` and `game/core/` are ALL spaces; `game/ui/` is tabs EXCEPT `Badge.gd`, `Bar.gd`, `Boot.gd` (spaces); `game/screens/` is tabs EXCEPT `Market.gd`, `RaidPrep.gd`, `Results.gd` (spaces); `tools/shot.gd` tabs; every test file spaces. GDScript refuses a file that mixes the two, so **the rule is per-file: match the file you are in**, not per-directory. The brief's "screens use tabs" is wrong for three of the most-touched screens.

## Findings

### RULES-01 · P2 · bug · Eight test stubs lack `survivors`/`casualties`, so every gate run prints 40 SCRIPT ERRORs that bury the real failure
Evidence: `scratchpad/verify_baseline.log` stage 3/8 (40 x `Invalid access to property or key 'survivors' on a base object of type 'RefCounted (_Lost|_Won|_Result|_LostResult|Won|Lost)'`); `game/core/GameState.gd:980-981` reads `result.survivors` and `result.casualties` in `_attempt_event()`; stub classes without those fields at `tests/unit/test_consumables.gd:355,359`, `test_game_state.gd:47`, `test_raider_detail.gd:481`, `test_reputation.gd:528,532`, `test_rest.gd:258`, `test_savegame.gd:397`, `test_tavern.gd:261,265`, `test_tutorials.gd:305`. `tools/verify.sh:122` prints `SCRIPT ERROR` lines as the failure summary, so the one real red (`test_docs_links`, `.verify.log:896`) was invisible in the baseline's 40-line head.
Why it matters: an art wave that breaks a screen test will read the same 40 lines and conclude "pre-existing noise". The stubs also make `_attempt_event` record `alive = 0` in those tests, so any future assertion on the attempt event's `party_size` silently tests the wrong number.
Fix: add `var survivors: Array = []` and `var casualties: Array = []` to each stub (or one shared `tests/fixtures/ResultStub.gd`); no game code changes. Keeps every contract: no screen, name or text touched.
Assets: none.
Acceptance: `tools/with_godot_lock.sh ./tools/verify.sh --fast` stage 3 prints zero `'survivors'` lines and `TESTS PASSED`.
Needs designer: no.
Verdict: CONFIRMED — the 40 `survivors` lines, GameState.gd:980-981 and every cited stub line check out, but the stubs already declare `casualties` and lack `survivors` AND `mistake_count` (GameState.gd:986), so the Fix must add only `var survivors: Array = []` and `var mistake_count: int = 0` (redeclaring `casualties` is a GDScript parse error); the runtime error also aborts `_attempt_event`, so nothing records `alive = 0` — the event is dropped, not mis-sized.

### RULES-02 · P1 · bug · `text_scale` is offered as a live option and applied by no screen
Evidence: `game/screens/Settings.gd:75` (`"reason": ""` = live, `:182` treats empty reason as enabled); `game/ui/Theme.gd:35` `get_theme(scale = Type.SCALE_DEFAULT)`; every caller is bare — `Town.gd:101`, `AdventureBoard.gd:90`, `Boot.gd:59` and the other 11 screens (`grep -rn "get_theme([^)]" game/` matches only the definition); `Theme.gd:32` cites `tests/unit/test_text_scale.gd`, which does not exist; audit `M6-A11Y-05` still describes the tree. `test_a11y_legibility.gd:256-317` proves the arithmetic, never a mounted screen.
Why it matters: docs/13 §13 text scaling is Blocking: Yes, and §7 forbids a control that does nothing. Any art pass that hand-sets `font_size` on new widgets (the RaidView party cards, callouts) widens the gap; the pass is the moment to route them.
Fix: one door in Theme.gd — `static func current(who: Node) -> Theme` that reads `GameSettings.text_scale` via `Services.find(who, "GameSettings")` and returns `get_theme(pct)`; every screen's `build()` sets `theme = Theme_.current(self)`; Settings' Apply calls `router.goto(router.current_path())` (or emits `changed("text_scale")` and Boot re-mounts) so screens rebuild; widgets that set sizes directly use `Type.at(size, pct)`. Per-file indentation: Theme/Town/etc. tabs, Market/RaidPrep/Results spaces.
Assets: none.
Acceptance: new `tests/unit/test_text_scale.gd`: set `text_scale=150` on the autoload, mount Town, assert some Label's effective `get_theme_font_size("font_size") == Type.at(Type.BODY, 150)`; shot each screen with `--set=text_scale=150` (add a second sheet to `tools/shot_all.sh`) and check nothing clips (docs/13 §4.4: reflow by rows, never truncate a morale value/state word/class name); `test_a11y_legibility.gd:256-317` still green (identity at 100 preserved).
Needs designer: no.
Verdict: CONFIRMED — Settings.gd:75 is live, Theme.gd:34 (not :32) cites a `tests/unit/test_text_scale.gd` that does not exist, all 13 screens plus Boot.gd:59 call `Theme_.get_theme()` bare (AdventureBoard's call is at :91), and `Services.find` (Services.gd:22) and `current_path()` (ScreenRouter.gd:53) named in the Fix both exist.

### RULES-03 · P2 · canon-conflict · Screen transitions are forbidden by ruling while docs/13 §12.2 and §11.4 specify them
Evidence: `game/core/ScreenRouter.gd:4-7` ("no transition animation and never will", docs/13 §2 M5 "The desk does not move"); docs/13 §12.2 row 1 "Cross-dissolve + active tab shifts 6px right, 110ms"; §11.4 t=1,800 "post-mortem slides out from under" — `RaidView.gd:160-165` and `test_wipe_sequence.gd:16-18` name it as unbuilt; audit `M6-JUICE-02` open; `test_screens.gd:159-169` pins `host.get_child_count() == 1` after two gotos.
Why it matters: a hard cut between every screen is the single most visible unpolished thing against the "insanely polished" bar, and no agent may build one without the ruling.
Fix: if the ruling allows a non-spatial dissolve: a `CanvasLayer` overlay owned by Boot (not the router's host, so the one-child contract holds), snapshot-free — a `ColorRect` fade to `GROUND_PAGE` and back via `Widgets.tween` with `motion_duration(110)`; reduced_motion collapses it to 0 s by construction. The 6px tab shift is a `Nav_*` button `position.x` tween in Frame.gd, same door. §11.4's slide stays banned if the ruling reads "no spatial motion".
Assets: none.
Acceptance: `test_screens.gd:159-169` green; `lint_motion.sh` green; a11y_smoke green (the overlay must be `mouse_filter = IGNORE`, `focus_mode = NONE`); two shots 2 frames apart show the mid-dissolve.
Needs designer: YES — does "the desk does not move" forbid a 110 ms opacity cross-dissolve, or only slides/pushes? (M6-JUICE-02, docs/15 entry owed.)
Verdict: CONFIRMED — ScreenRouter.gd:4-7, RaidView.gd:161-166, test_wipe_sequence.gd:16-18, test_screens.gd:169 and docs/13:69/:650/:678 all read as cited; audit M6-JUICE-02 (audit.json:1923-1927) already asks for the switch form (a `TRANSITION_MS` defaulting to 0), so the Fix's overlay must sit behind that switch whichever way the ruling goes.

### RULES-04 · P3 · bug · RaidView's wipe comment says the ink blot and wax seal "are art that does not exist" — both exist and are tweened
Evidence: `game/screens/RaidView.gd:155-159` vs `game/assets/ui/wipe_blot.png`, `wax_seal.png` (present), `RaidView.gd:1155` and `:1202` tween them, `test_wipe_sequence.gd:254-259` asserts the paths resolve. `tests/unit/test_project_hygiene.gd:41-56` (`LIES`) has no row for it.
Why it matters: the m4t-13 failure shape — a comment that denies art which exists sends the next loop to redraw it.
Fix: rewrite the comment to name the assets and `tools/aseprite/gen_wipe.lua`; add a `LIES` row `["res://game/screens/RaidView.gd", "art that does not exist", "res://game/assets/ui/wipe_blot.png"]`.
Assets: none.
Acceptance: `test_project_hygiene.gd` green with the new row.
Needs designer: no.
Verdict: CONFIRMED — RaidView.gd:156-158 still says the blot and seal do not exist; both PNGs, `tools/aseprite/gen_wipe.lua`, the tweens at :1155/:1202 and test_wipe_sequence.gd:254-259 are exactly as cited; LIES (test_project_hygiene.gd:41-56) has no RaidView wipe row.

### RULES-05 · P3 · bug · MainMenu's comment says the aerial's water cannot be built — water shimmer exists now
Evidence: `game/screens/MainMenu.gd:76-82` ("water, clouds and windmill sails, none of which SceneStage can build (audit M4B-VFX-01)"); `game/ui/SceneStage.gd:362` `add_shimmer`, `game/assets/scenes/stage_town.json` carries 3 shimmer rects (scene inventory above); `test_scene_stage.gd:573-591` pins the shader. Clouds and sails are still absent; `M4B-VFX-01` is partly done and its audit text does not say so.
Fix: rewrite the comment to "water shimmer is on; cloud drift and sail motion are M4B-VFX-01"; add a `LIES` row keyed on `game/assets/scenes/stage_town.json`; update the audit entry.
Assets: none for the comment; the cloud/sail layers are a separate SceneStage feature (a `Parallax2D` "far" layer per spec 11 §5 with autoscroll, reduced_motion via `apply_settings`).
Acceptance: hygiene test green; MainMenu shot after 60 frames differs from frame 1 in the water rects only.
Needs designer: no.
Verdict: CONFIRMED — MainMenu.gd:76-81 says SceneStage cannot build water; `add_shimmer` at SceneStage.gd:362 and stage_town.json's 3 shimmer rects exist and test_scene_stage.gd:573-591 pins the shader; one correction: audit M4B-VFX-01's `actual_status` is already "partial" (audit.json:3413) — only its evidence prose ("stage_town gets NO animated layer") is stale.

### RULES-06 · P2 · missing-widget · No screen declares `default_focus()`; the town hotspot ring and the wipe's default-focused "Try again" are unbuilt, and two doc rules disagree about the Town
Evidence: `grep -ln "func default_focus" game/screens/*.gd` returns nothing; `game/core/ScreenRouter.gd:171-190` supports the hook; docs/13 §13.2 "one hotspot is always focused, even with no input — on entry it is the last building visited, or the Adventure's Board on a fresh save", §11.4 "`Try again` is left and default-focused"; `tests/unit/a11y_smoke.gd:189-191` fails a screen whose focus does not open on `rail[0]`; `test_a11y.gd:696` asserts `initial_focus_target == rail[0]` on Town. Town shot: focus (invisible in shots, see RULES-13) is on `Nav_home`, the callouts are `Button`s inside `PanelCallout` plates (`Widgets.gd:468-520`).
Why it matters: an art pass that turns the callouts into sprite hotspots (the directive's "actual working graphics") must carry the ring or the hub becomes mouse-only; and the two rules cannot both be satisfied on the Town.
Fix: (1) ruling on which wins on the Town; (2) if hotspot-first: `Town.gd` implements `default_focus()` returning the last-visited callout Button (persist `last_building` on GameState) and a11y_smoke's rule 2 exempts screens that declare `default_focus()`; (3) `RaidView.gd` implements `default_focus()` returning the report/try-again button after a wipe; (4) the ring is `Frame.focus_order` on the scene region — already wraps arrows inside a region, so hotspots authored left-to-right in tree order get D-pad wrap for free.
Assets: none.
Acceptance: a11y_smoke both sweeps green with the amended rule; `test_a11y.gd:558-571` pattern applied to Town and RaidView; shot with `--focus` (RULES-13) shows the ring on the hotspot.
Needs designer: YES — on the Town, does focus open on the rail (§13.1 reading order, as built) or on a hotspot (§13.2)?
Verdict: CONFIRMED — no `default_focus` in game/screens, the hook is ScreenRouter.gd:177-178, a11y_smoke.gd:189-191 and test_a11y.gd:696 pin rail[0], docs/13:779 and :651 say what is quoted, Widgets.building_callout (:468-480) puts a Button named "Button" in each plate, and the Town shot shows the rail's Camp item lit with no ring anywhere; two corrections: §13.2 is marked PROPOSED (docs/13:760) so this is canon-vs-proposed, and the Fix must also amend `test_a11y.gd:696` (it asserts rail[0] on Town outright), not only a11y_smoke's rule 2.

### RULES-07 · P2 · bug · The Adventure's Board's ten notice rows are pointer-only PanelContainers
Evidence: `game/screens/AdventureBoard.gd:231-234` (`row.gui_input.connect(...)` on a `PanelContainer`); `scratchpad/verify_baseline.log` 5/8 `warn fixture AdventureBoard.tscn 10 pointer-only gesture target(s)`; `a11y_smoke.gd:233-241` reports but does not fail; AdventureBoard shot (region 233,180,500,500) shows the rows with no focusable affordance.
Why it matters: docs/13 §13.2 "no interaction may exist only as a pointer gesture" (Blocking: Yes for keyboard); the warn has been standing since the keyboard pass.
Fix: give each row a full-rect flat `Button` named `Notice_<id>` (`focus_mode = FOCUS_ALL`, `text = ""`, `PanelCard` chrome on the button not the panel), `pressed → _select(id)`; keep the title `Label` so `test_raid_plan.gd:270-292` still reads "A0 — Adventure 0" / "Clear A0 first." / "CLEARED"; `Frame.focus_order` collects it in the scene region automatically; Space/Enter select via `ui_accept`.
Assets: none (the hover/focus styles come from Theme.gd's `_button()`).
Acceptance: a11y_smoke prints no `warn` for AdventureBoard and the Tab ring includes `Notice_A0`; `test_raid_plan.gd` and `test_screens.gd:256-288` green.
Needs designer: no.
Verdict: CONFIRMED — AdventureBoard.gd:231-234 wires `gui_input` on the PanelContainer, the baseline log (line 60) lists ten anonymous PanelContainers, the shot region shows the rows as plain panels with only a selected-border, and `Frame._region_members` (Frame.gd:563-570) walks `p.scene` for FOCUS_ALL controls so the region pickup is automatic; Fix caveat: "PanelCard chrome on the button" means a new Button-family theme variation, which must go through Theme.gd `_button()` or test_a11y.gd:229-277 (every variation carries the focus ring, >= 9 types) goes red.

### RULES-08 · P3 · canon-conflict · `prose_font_swap` (EB Garamond → Fira Sans) is moot after the type pass
Evidence: docs/13 §13 "Optional swap of EB Garamond → Fira Sans for prose and log"; `game/ui/Fonts.gd:25-64` — the UI/prose face already IS Fira Sans, display is Grenze Gotisch (spec 05); `game/screens/Settings.gd:79-80` disables the row with "The type pass ships the second family."; `game/core/GameSettings.gd:35` keeps the key.
Why it matters: the row promises a second family the type spec does not plan; an art pass adding a serif for flavour would resurrect a dead option by accident.
Fix: ruling — retire the row (docs/13 §15.1 edit; keep the DEFAULTS key for settings-file compatibility, mark it ignored) or redefine it (e.g. Grenze → Fira for headings for dyslexic readers).
Assets: none, or a second prose face if redefined.
Acceptance: `test_settings.gd` green; the row's reason text matches the ruling.
Needs designer: YES — what does the font-swap option mean now that Fira Sans is the body face?
Verdict: CONFIRMED — Fonts.gd:25-64 maps ui/prose to FiraSans-*.ttf and display to GrenzeGotisch.ttf, docs/13:740 still describes EB Garamond → Fira Sans, Settings.gd:79-80 and GameSettings.gd:35 are as cited.

### RULES-09 · P2 · missing-widget · The CVD-safe morale ramp is built and unreachable, and Settings' comment says CVD safety "ships on" when it ships off
Evidence: `game/ui/Palette.gd:180-200` `cvd_safe()` probes `GameSettings.DEFAULTS` for `OPT_CVD_SAFE`; `game/core/GameSettings.gd:30-50` has no such key; `game/screens/Settings.gd:15` "contrast / minimum text size / CVD safety — ship on, and have no off"; `tests/unit/test_palette_cvd.gd:315` (`default ramp is still the reference ramp`), `:352` (`reference ramp collapses under protanopia`), `:227-262` (docs/13 §8.3's own ramp misses ΔL* 5 under four of five observers), `:397-404` (the CVD fills cannot be text tints).
Why it matters: docs/13 §13 CVD row is Blocking: Yes; the chip's four channels (integer, word, glyph, lightness) are the real guarantee, and any redesigned morale chip must keep all four — a colour-only pixel chip would fail the row even with the ramp fixed.
Fix: designer rulings (the §8.3 hexes, `build/plan/q-a11y-legible.md`; and setting vs always-on). Then either add `cvd_safe` to DEFAULTS + docs/13 §15.1 + `Settings.ROWS`, or drop `cvd_safe()` and make `Widgets.chip`/`Cards.card` carry lightness-ordered fills by default. Either way the chip keeps integer + state word + glyph (`Cards.morale_glyph`) + fill.
Assets: none (a ten-swatch strip for `tools/art/cvd.py` verification).
Acceptance: `python tools/art/cvd.py <shot> --sim deuteranope` on Guildhall shows adjacent bands ≥ 5 ΔL*; `test_palette_cvd.gd` updated to the ruled hexes; `test_screens.gd:453-456` (`morale_color` red/amber/green) still green if the text ramp is untouched.
Needs designer: YES — ramp hexes, and is CVD-safe a player option or the only ramp?
Verdict: CONFIRMED — Palette.gd:179-200 probes `OPT_CVD_SAFE = "colourblind_safe"`, GameSettings.DEFAULTS (:30-50) has no such key, Settings.gd:15 says CVD safety ships on, and all four test_palette_cvd citations resolve; Fix correction: the key must be named `colourblind_safe` (test_palette_cvd.gd:321 pins `Palette.OPT_CVD_SAFE` to that string and :327-328 requires its default false), not `cvd_safe`; test_settings.gd:80 forbids a `cvd_safety` key, which does not collide.

### RULES-10 · P0 · baked-bg · Five hall-family screens still mount `guildhall_plate.png`; the conversion contract an implementer must obey
Evidence: `game/screens/Guildhall.gd:164`, `RaiderDetail.gd:139`, `LoadSave.gd:42`, `Settings.gd:161` (full plate, dimmed by `modulate`), `Facilities.gd:476-477` (an `AtlasTexture` crop 296,250,337,104 of the same plate as the "current level" thumbnail); Roster has no ground of its own; `game/assets/scenes/camp.json` and `guildhall.json` still point at `camp_plate.png`/`guildhall_plate.png` and no screen loads them (`SceneStage.load` callers: stage_camp x3, stage_town, stage_market, stage_tavern, DEFAULT_ARENA x3); `game/ui/Cards.gd:431-432` uses `boss_sludge_maw.png` (a mockup crop) for the mission well. BUILD_STATE.md:60-92 records the block (M4B-CONV-03); the designer's 2026-09-13 message lifts it: hall family → `stage_camp`, Settings inherits/dims.
Why it matters: the directive's headline.
Fix (contract, the hall cluster does the work): copy `Town.gd:143-146` — `SceneStage.load("stage_camp")`, position by offset, `modulate` for the dim, callouts/panels on top; for Facilities replace the atlas crop with a `SceneStage`-free `AtlasTexture` of `stage_camp.png` at a region the hall cluster picks (or m4t-10's per-level art). Delete `camp.json`/`guildhall.json` and the `*_plate.png` crops only after nothing loads them (M4B-CONV-02). Keep: every Label/Button text in §1's tables (test_comfort `:649-774`, test_rest `:322-347`, test_starting_roster `:203-244`, test_screens Records `:634-810`, test_raider_detail, test_loadsave_screen `:158-348`, test_settings); `Nav_*` names and rail order (a11y_smoke both sweeps, `test_a11y.gd:668-699` mounts Settings); `apply_settings` on every stage (reduced_motion holds the camp still). Note LESSONS.md:116-121: a SceneStage adds a screen-space glow, so masked refdiff numbers move even when the change is inside the mask — record before/after. `test_motion.gd:139-156` survives the JSON deletions (stage_arena_cave/dungeon keep 9 and 16 entries above 3 fps).
Assets: none new (six bare stages are authored); Facilities per-level thumbnails are m4t-10 (missing-asset, separate).
Acceptance: `shot_all.sh` sheet shows no painted figures/bubbles under the hall screens; `refdiff` vs concept 3 with the scene band masked (`0,77,1536,649`) recorded in BUILD_STATE; `verify.sh` green; a11y_smoke 26 mounts green.
Needs designer: no (answered 2026-09-13); one residual question in Open questions (what Settings dims when opened from MainMenu).
Verdict: CONFIRMED — Guildhall.gd:164, RaiderDetail.gd:139, LoadSave.gd:42, Settings.gd:161 and Facilities.gd:476-477 all load guildhall_plate.png, Roster has no ground, Cards.gd:431-432 loads boss_sludge_maw.png, the SceneStage.load caller set is exactly as listed (Completion.SCENE is stage_camp) and the fps>3 survivors are cave 9 / dungeon 16; two corrections: (a) the designer's "Settings inherits/dims" message is not in the tree — BUILD_STATE.md:73 maps Settings (dimmed) to `stage_town`, so Open question 7 is the only record; (b) `guildhall.json` IS still loaded, by `tools/probe/Kit.gd:67` (`SceneStage.load("guildhall")`), the art gate's first target — see RULES-16.

### RULES-11 · P2 · bug · The art gate scores 3 targets; `shot_all.sh` now shoots 13 screens and scores none
Evidence: `tools/diff_all.sh:22-30` (Kit, Town, RaidPrep); `tools/shot_all.sh` (commit 9c1575f, 19:25) shoots all 13 into `build/shots/all` with contact sheets and runs no `refdiff`; audit `m4t-08` open; `tools/probe/Kit.tscn` exists (`ls -la tools/probe/`).
Why it matters: every screen the directive names gets no number; regressions in ten screens are invisible to the gate.
Fix: extend `TARGETS` with `scene|concept|name|masks` rows: Tavern/Market/Guildhall/RaiderDetail/LoadSave/Settings vs 3 with the scene band masked; RaidView/Results vs 2 with the arena masked (`210,77,928,640` as raidprep); AdventureBoard/Completion vs 1; MainMenu vs 3 chrome-only. Use `--fixture=raid` for RaidView/Results (shot_all.sh already knows which). Record the first honest numbers in BUILD_STATE as the baseline (LESSONS.md:109-115: a crop of the reference scores as a tautology).
Assets: none.
Acceptance: `tools/with_godot_lock.sh ./tools/diff_all.sh` prints 13 lines and exits 0; numbers in BUILD_STATE.
Needs designer: no.
Verdict: CONFIRMED — diff_all.sh:22-30 holds three targets, shot_all.sh (commit 9c1575f, 19:25:29) lists the 13 screens and runs only contact_sheet.py (no refdiff), m4t-08 is "partial" at audit.json:2359, tools/probe/Kit.tscn exists; note the Kit target depends on the legacy `guildhall` scene (RULES-16).

### RULES-12 · P3 · polish · Two kit widgets live as private classes inside screens
Evidence: `game/screens/Market.gd:583-586` `_slot_with_reason` ("Private until the kit grows a slot variant of button_with_reason"); `game/screens/RaiderDetail.gd:694-700` `MoraleChart` ("Private to this screen until the kit grows a sparkline"); spec 11 §3 lists composites `RosterCard`, `CombatantPanel`, `MissionPanel`, `EventLog`, `BuildingCallout`, `SpeechBubble` as separate files that do not exist (they are functions in Cards.gd/Widgets.gd — fine — but the sparkline and the reasoned slot are not in either).
Why it matters: a kit repaint (nine-slice slots, pixel sparkline) has to find and restyle two private copies.
Fix: promote to `Widgets.slot_with_reason(caption, reason, cell, icon)` and `Widgets.sparkline(values, band_color_fn)` (Widgets owner, tabs); screens call them. Keep `button_of()` semantics (the Button is named `"Button"`).
Assets: none.
Acceptance: `test_market.gd` and `test_raider_detail.gd` green; RaiderDetail shot unchanged pixel-for-pixel (`refdiff` against the pre-change shot: mae 0).
Needs designer: no.
Verdict: CONFIRMED — Market.gd:583-586 and RaiderDetail.gd:694-700 carry the two "private until the kit grows" classes, spec 11 §3 (:62) names the six composite files and none exist under game/ui/; `button_of` (Widgets.gd:237-243) looks up the child named "Button" first, and refdiff.py:39 accepts an arbitrary path as the reference, so the mae-0 acceptance is runnable as written.

### RULES-13 · P2 · bug · `tools/shot.gd` never wires or grabs focus, so the §12.3 focus ring has never been seen in a shot
Evidence: `tools/shot.gd:193-202` (instantiate, `build()`, `on_enter()`; no `wire_shell_focus`, no `grab_focus`); `ScreenRouter.gd:299-313` does both in the game; the ring's geometry is asserted (`test_a11y.gd:229-277`) but its look (2px EDGE_STEEL outside the bounds on every widget, incl. the new pixel buttons) is unreviewed; a11y_smoke runs headless (no image).
Why it matters: "UI in every surface is functioning and designed as well as it possibly can be" includes the keyboard state; a redesigned button whose `focus` slot is wrong (e.g. a texture button that clips the ring) passes the wiring tests and looks broken.
Fix: `shot.gd` flags `--focus` (after `on_enter`: `ScreenRouter.wire_shell_focus(inst)`; `ScreenRouter.initial_focus_target(inst).grab_focus()` — legal inside the SubViewport) and `--tab=N` (call `find_next_valid_focus()` N times); add a focus sheet to `shot_all.sh`.
Assets: none.
Acceptance: `Town.png` shot with `--focus` shows a 2px ring around `Nav_home` at rail x 0..206, y 105..160; with `--tab=1` the ring is on the first header chip.
Needs designer: no.
Verdict: CONFIRMED — shot.gd:193-202 does build()/on_enter() and nothing else, ScreenRouter.gd:309-313 wires and grabs focus, `wire_shell_focus`/`initial_focus_target` are static (:226/:173) so the Fix's calls are legal, and rail item 0 is at y 105..160 (Widgets.gd:43-44) x 0..206 (Frame.gd:33); whether `grab_focus()` succeeds inside shot.gd's SubViewport is unverified without running Godot.

### RULES-14 · P3 · canon-conflict · docs/13 §14 forbids literal strings and text baked into art; the whole UI is literal English and the wordmark is a PNG
Evidence: docs/13 §14 rows "No literal strings in scenes", "Text in art: No baked-in text on any sprite or panel background. Shop signage in the world layer is the sole exception"; every test in §1 asserts English substrings; `game/ui/Frame.gd:171-190` mounts `wordmark_58.png`/`wordmark_44.png`/`wordmark_tagline.png` (pre-rendered by `tools/art/gen_wordmark.py`); no string table exists in `game/` or `data/`.
Why it matters: an art pass is exactly when words get painted into pixel-art plates ("RECRUIT", "GEAR", a "WIPE" stamp texture). The tests would go green while §14 goes further red.
Fix: constraint, not a build: every word stays a `Label` (theme-driven, scalable, readable by `_texts()`); textures carry no glyphs; the wordmark stays the one exception pending a ruling; localization proper is out of scope for the art pass.
Assets: none.
Acceptance: `tools/art/sheetscan.py`-style OCR is overkill — a reviewer checks each new PNG under `game/assets/ui/` carries no letters; the "WIPE." stamp remains a Label (`test_wipe_sequence.gd:216`).
Needs designer: YES — is the pre-rendered logotype exempt from §14 like shop signage?
Verdict: CONFIRMED — docs/13:797 and :807 are the two rows, Frame.gd:171-190 mounts the three pre-rendered wordmark PNGs from gen_wordmark.py, no string table exists (data/ holds content JSON only), and test_wipe_sequence.gd:216 reads "WIPE." through `_texts()`.

### RULES-15 · P3 · polish · The §12.1 latency budget has no instrument, and the art pass adds the load that would break it
Evidence: docs/13 §12.1 (screen switch ≤ 140 ms, hover ≤ 40 ms with no layout shift, number recompute same frame); audit `M6-JUICE-07` open; SceneStage on 9 screens with up to 19 `PointLight2D`s + `WorldEnvironment` glow per scene (`stage_arena_dungeon.json` lights: 19; `SceneStage.gd:498-510`); `tools/verify.sh` has no timing stage.
Why it matters: every new light, particle system and shader lands without a number; a 300 ms screen change would ship unnoticed.
Fix: `tools/perf_probe.gd` (SceneTree script, real display server like shot.gd): for each screen in `a11y_smoke.SCREENS`, `goto()` and measure wall time to the first rendered frame and the mean frame time over 120 frames with the fixture; print `PERF OK` / a WARN table; wire into verify.sh as a WARN stage (the playtest precedent, `:193-202`).
Assets: none.
Acceptance: the probe prints per-screen numbers; RaidView ≤ 140 ms mount, ≤ 16.6 ms mean frame at 1536x1024.
Needs designer: no.
Verdict: CONFIRMED — docs/13:659-670 is the budget table, M6-JUICE-07 is "not-started" (audit.json:2018), stage_arena_dungeon.json has 19 lights, SceneStage.gd:498 builds a PointLight2D per entry, and verify.sh has no timing stage; the playtest WARN precedent's comment block is verify.sh:193-202 with the stage header at :203.

### RULES-16 · P2 · bug · The art gate's first target mounts the legacy `guildhall` scene that RULES-10 schedules for deletion (Added by verifier)
Evidence: `tools/probe/Kit.gd:65-67` (`SceneStage.load("guildhall")` — its comment: "SceneStage reads game/assets/scenes/guildhall.json"); `tools/diff_all.sh:23` (`res://tools/probe/Kit.tscn|1|kit|-`, the only unmasked target); `game/assets/scenes/guildhall.json:2` points at `guildhall_plate.png`; `tools/art/patch_bubbles.py:12` also names `guildhall_plate`. RULES-10's "no screen loads them" is true of screens and false of the gate.
Why it matters: RULES-10's M4B-CONV-02 step (delete `camp.json`/`guildhall.json` and the `*_plate.png` crops) leaves `SceneStage.load("guildhall")` with no JSON to read on the Kit probe, so `diff_all.sh` target 1 — the kit baseline BUILD_STATE records as Kit 16.9 MAE — either fails to shoot or scores a blank scene band, and the regression is invisible because RULES-11 says nothing else is scored.
Fix: before M4B-CONV-02, repoint `Kit.gd:67` to a bare stage (`SceneStage.load("stage_camp")` or whichever the kit owner picks) and re-baseline the kit number in BUILD_STATE; add `tools/probe/` to RULES-10's `SceneStage.load` caller inventory and to its "only after nothing loads them" grep.
Assets: none.
Acceptance: `grep -rn 'load("guildhall")\|load("camp")\|guildhall_plate\|camp_plate' game tools tests` returns nothing before the JSON/PNG deletion; `diff_all.sh` prints its kit line with a recorded before/after.
Needs designer: no.
Verdict: CONFIRMED — Added by verifier; Kit.gd:67 and diff_all.sh:23 read as cited.

## Open questions

1. **Town focus entry** — rail-first (docs/13 §13.1, `a11y_smoke.gd:189`, `test_a11y.gd:696`) or hotspot-first (§13.2 "one hotspot is always focused")? Blocks any sprite-hotspot rebuild of the Town (RULES-06).
2. **Screen change** — does docs/13 §2 M5 "the desk does not move" forbid a 110 ms opacity cross-dissolve (§12.2 row 1) or only spatial slides? Blocks M6-JUICE-02 and the wipe's t=1,800 beat (RULES-03).
3. **Text floor** — `Type.SMALL = 13` and `STACK = 11` render at 13.71/11.60 px at 1920x1080 under the real 1.0547 letterbox (`test_a11y_legibility.gd:348-380`, `build/plan/q-a11y-legible.md`). Which authority wins, docs/13 §4.2's 1920 scale or spec 05's measured concept sizes? Any type repaint must wait for this or the exact-list assertion turns red by design.
4. **CVD ramp** — docs/13 §8.3's ten hexes miss their own ΔL* promise (`test_palette_cvd.gd:227-262`); is CVD-safe a player option (`OPT_CVD_SAFE`) or the only ramp? (RULES-09)
5. **`prose_font_swap`** — what does it mean now that Fira Sans is the body face? (RULES-08)
6. **Logotype** — is the pre-rendered wordmark exempt from docs/13 §14's "no text in art"? (RULES-14)
7. **Settings' ground** — today's message says Settings "inherits/dims". Inherits from the screen beneath it: from Town that is `stage_camp`; from MainMenu (`Router.settings()` is reachable via Start from any screen, `test_a11y.gd:786-803`) that would be `stage_town`. One plate or the stack's plate? If the latter, Settings needs to read `router` depth-1's scene — say so before the hall cluster hard-codes `stage_camp`.
8. **Arena per encounter** — `SceneStage.DEFAULT_ARENA = "stage_arena_cave"` for every fight (`SceneStage.gd:52-61`, Q-96 / M4B-CONV-04). `test_scene_stage.gd:534-563` hard-codes the cave's stone band (plate y 481..556); a dungeon mapping needs its own feet band and a `boss_feet_y(h, arena)` signature.
9. **Flash rule scope (BL-75)** — `test_motion.gd:139-156` REQUIRES the world layer to keep an entry above 3 fps. If the ruling ever goes literal, that test flips and every hearth drops to 3 fps; the art pass should not author new fps values above 3 for UI-layer elements (stamps, badges) regardless.
10. **Frame's non-painting Containers** — `Frame.gd:380-390` documents that Containers created inside `build()` measure correctly and paint nothing (cause unknown; `tools/probe/Chips.tscn` isolates the anchor case only). Any chrome rewrite that moves panels into Frame must first reproduce and explain this, or keep the "plain Controls only inside build()" rule.

## Files read

Tests: `tests/unit/test_screens.gd` (full), `a11y_smoke.gd` (full), `test_a11y.gd` (`:27-110`, `:200-380`, `:380-710`, `:728-847`), `test_a11y_legibility.gd` (`:49-110`, `:256-380`, `:594-660`, `:793-862`), `test_scene_stage.gd` (full), `test_wipe_sequence.gd` (full), `test_motion.gd` (full), `test_palette_cvd.gd` (`:40-80`, `:180-230`, `:379-404`), `test_project_hygiene.gd` (`:30-120`), `test_docs_links.gd` (`:236-290`), `test_settings.gd` (`:300-360`), `test_raid_plan.gd` (`:448-452`); assertion-line greps of `test_loadsave_screen`, `test_results_screen`, `test_raider_detail`, `test_settings`, `test_tavern`, `test_market`, `test_completion`, `test_achievement_board`, `test_comfort`, `test_rest`, `test_ladder`, `test_raid_plan`, `test_log_player`, `test_starting_roster`, `test_full_loop`, `test_canon_guard`, `test_docs_links`, `test_export`, `test_game_state`, `test_savegame`; `tests/run_tests.gd` (`:1-60`).
Tools: `tools/lint_motion.sh`, `tools/lint_no_global_classes.sh` (`:1-25`), `tools/verify.sh`, `tools/with_godot_lock.sh`, `tools/diff_all.sh`, `tools/shot.gd`, `tools/shot_all.sh` (`:1-30`), `tools/fixture_reference.gd`, `tools/art/refdiff.py`, `tools/art/contact_sheet.py` (`:1-20`), `tools/build_art.sh` (`:1-45`), `tools/env.sh`, `tools/probe/` listing.
Game: `game/core/ScreenRouter.gd` (`:1-80`, `:160-334`), `game/core/GameSettings.gd` (full), `game/core/GameState.gd` (`:972-986`), `game/ui/Frame.gd` (`:1-330`, `:380-392`, `:470-622`), `game/ui/Theme.gd` (`:1-60`, function list), `game/ui/Type.gd` (full), `game/ui/Widgets.gd` (API list, `:440-530`), `game/ui/Cards.gd` (API list), `game/ui/SceneStage.gd` (`:1-75`, API list, `:470-500`), `game/ui/Palette.gd` (`:180-200`), `game/ui/Bar.gd` (`:1-14`), `game/ui/Fonts.gd` (API), `game/screens/AdventureBoard.gd` (`:78-96`, `:118-135`, `:222-242`), `MainMenu.gd` (`:70-95`), `RaidView.gd` (`:150-175`), `Facilities.gd` (`:1-20`, `:468-484`), `Market.gd` (`:64-80`, `:580-592`), `Tavern.gd` (`:108-128`), `RaiderDetail.gd` (`:132-146`, `:690-700`), `Guildhall.gd` (`:156-172`), `LoadSave.gd` (`:38-48`), `Settings.gd` (`:9-45`, `:63-100`, `:152-168`, `:265-275`), `Town.gd` (`:99-103`, `:138-152`), `Completion.gd` (`:45-51`); indentation counts across `game/ui`, `game/screens`, `game/core`.
Data: `game/assets/scenes/*.json` (key inventory + fps), `game/assets/bg/`, `game/assets/ui/`, `game/assets/fonts/` listings; `build/plan/audit.json` (M4B-*, M6-JUICE-*, M6-A11Y-*, m4t-* rows).
Docs: `docs/13-ui-ux.md` §4.4, §7 (kit table), §12, §13, §13.1, §13.2, §14; `art/ref/specs/11-godot-architecture.md` §3-5; spec 06 headings; `BUILD_STATE.md:60-120`; `LESSONS.md` (headings + `:84-170`, `:320-348`).
Shots: `AdventureBoard.png`, `RaidView.png`, `Town.png` (scratchpad/shots). Logs: `scratchpad/verify_baseline.log`, `.verify.log:890-901`. Git: status, last three commits.
