# report-W3-KIT2 — the kit's second pass and the hub's event feed

Unit: W3-KIT2 (00-plan §4). Owns `game/ui/Widgets.gd`, `game/ui/Cards.gd`, `game/ui/Badge.gd`,
`game/ui/Bar.gd`, `game/core/GameState.gd` (event_feed only), `game/assets/bg/boss_sludge_maw.png`
(deletion), `tests/unit/test_event_feed.gd` (new), `tests/unit/test_widgets_kit.gd`.
Handoff: `build/plan/handoff-W3-KIT2.md`. Shots: `build/shots/W3KIT2_*.png`.

## Acceptance (00-plan §4 W3-KIT2)

- [x] A1 after a hire the Town log shows a recruit row with its badge (`test_event_feed.gd`)
  - `test_event_feed.gd::test_a_hire_writes_a_recruit_row_the_town_log_shows_with_its_badge` green; shot
    `build/shots/W3KIT2_Tavern_hire.png` (`Tavern --fixture --press="Hire — 60 G"`, crop `_log2x.png`): the
    strip's Recent Events (the same `Cards.event_log` the Town draws) reads "Hired Linda the Mage for 60 G."
    with the grid's 22px person badge; "View All" reasoned "Opens at Known." on the Unknown fixture guild.
- [x] A2 Guildhall shot shows a glyph before each class word (`Cards.card`, KIT-19)
  - `W3KIT2_Guildhall.png` / `W3KIT2_Town_raid_cards3x.png`: crossed swords, dagger, cross, hat, totem, fist before
    the class words; `test_the_card_puts_a_class_glyph_before_the_class_word_and_trims_the_band_line` green.
- [x] A3 RaidView/Results/Town log rows show pixel badges with contrast >= 3:1 vs #020C14 (KIT-07 / COMBAT-06)
  - Seen in `W3KIT2_RaidView_log3x.png`, `W3KIT2_Results_log2x.png`, `W3KIT2_Town_raid_log3x.png`;
    `test_every_feed_badge_reads_on_the_log_ground_at_three_to_one` measures all 12 log_* PNGs' mean opaque ink
    against #020C14 through `Badge._contrast` (green).
- [x] A4 hovering a gear slot shows the two-line tooltip inside the frame (`Widgets.tooltip_for`, KIT-22) — BUILT, NOT SHOT
  - `tooltip_for` + `TooltipHost` shipped and `Cards.card` uses it on its gear cells; asserted by
    `test_tooltip_for_lays_a_host_over_the_control_and_builds_two_lines` (title over body, ≤ 260 wide,
    `tooltip_text` kept). The shot tool has no hover flag (J4; handoff observation for shot.gd's owner).
- [x] A5 `_texts()` output of every screen test unchanged; `test_a11y_legibility.gd:644-655` green
  - No screen test moved in either suite run; the only Label text I changed is the log's own reason line
    ("Records opens this" → "Opens at Known.", read by my test file alone) and the day-one empty line.
- [x] A6 "View All" routes to the Records tab (KIT-21)
  - `test_view_all_opens_the_records_tab_on_the_guildhall`: on a Known guild the Town's link pushes the
    Guildhall through the autoload router and lands on `active_tab() == "records"` with the wall up;
    `test_view_all_is_shut_below_known_and_names_its_reason` for the gate.
- [x] A7 `Widgets.panel` corner ornaments on PanelWarm/PanelSteel; `callout()` gradient plate + flourish (KIT-09)
  - `W3KIT2_Town_raid_corner4x.png` (bronze ornament in the sidebar's corner), `W3KIT2_Results_log2x.png`
    (steel), `W3KIT2_RaidPrep_callout3x.png` (sweep + rim + flourish); two unit tests.
- [x] A8 `empty_state` glyph wiring (KIT-08) — the event log's default quill
  - `Cards.event_log` defaults to `Icons.at("empty", "quill")` (`W3KIT2_Guildhall.png`); the screens' own
    25 sites are not mine — per-site glyphs listed in the handoff.
- [x] A9 `reasoned` padlock default + `width` + icon gated on the reason (CRITIC-G06, W2 obs b/e)
  - `test_reasoned_disables_dims_and_prints_the_reason_in_a_label` extended; seen on the RaidView's skip and
    the Tavern's "Take the room next door" (`W3KIT2_Tavern_hire_plate.png`).
- [x] A10 mission well: `boss_sludge_maw.png` crop replaced by `encounter_art`; the PNG deleted (RULES-10)
  - `W3KIT2_RaidPrep_side.png`: the main boss composes over the cave slice like every rank; the PNG and its
    .import are deleted (`git rm --cached` staged); tools/probe/Kit.gd:134 is handoff §1/§2.
- [x] A11 `Cards.badge_icon` for record states locked/earned/claimed (HALL-20)
  - padlock / coin / scroll through Icons; `test_badge_icon_keeps_the_morale_pair_and_answers_the_record_states`.
- [x] A12 CTA subline / card prices through `Type.gold` (KIT-15)
  - `Widgets.cta_priced(text, price)` and `Cards.price_text(n)` are the doors (tested); the screens' sites are
    handoff observations (J5).
- [x] A13 wave-2 observations: TAB_MIN (a), damage_number z_index (b), card class/band ellipsis (c),
      emote glyph drawn alone at 2x (d), tab_row re-grab (e), locked callout two rows + pad 4/4 + own settle (f)
  - all six landed and each has a unit assertion; (d) seen in `W3KIT2_Town_emotes4x.png`, (c) in
    `W3KIT2_Guildhall_t150_cards.png`, (f) in `W3KIT2_Town_raid_smith2x.png`; (h) BUILD_STATE's one-letter-
    per-line reason was already gone (reasoned no-wrap) and the reason now reads "Opens at Known.".
- [x] A14 `test_event_feed.gd` passes; `verify.sh --fast` green; `lint_motion.sh` MOTION LINT OK
  - `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` (build/shots/W3KIT2_verify2.log):
    ```
    PASS  class cache regenerated
    PASS  LINT OK  no cross-file class_name references in sim/ or game/
    PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
    PASS  PARSE_CHECK scanned 173 script(s)
    PASS  16 generated file(s) agree with tools/gen_items.gd
    PASS  ART CHECK  generators=7  runtime files: 197 agree  0 DIFFERS  0 MISSING
    PASS  TESTS PASSED   1908 test(s) in 92 file(s)  [223046 ms]
    exit 0
    ```
    The run before it (W3KIT2_verify.log) had 3/1908 failing: my two callout-clamp tests (outside a tree the
    plate's minimum is measured on the default theme's wider face — the tests now read
    `get_combined_minimum_size()`) and W3-OPTIONS's `test_options_layout.gd`, which had landed by the second run.
- [x] A15 shots viewed: Town, Guildhall, RaidView --advance=10, Tavern after a hire (see Shots)

## Log (write-as-you-go)

- Read: 00-plan §0/§4/W3-KIT2, RULES §1-2, KIT-07/08/09/15/19/21/22, COMBAT-06, TOWN-23, CRITIC-G06,
  RULES-10, HALL-20, LESSONS, the seven wave-2 handoffs' Observation headings, the five owned files.
- Before-state crops: `build/shots/W3KIT2_before_town_log.png` (empty log, reasoned View All),
  `build/shots/W3KIT2_icons_sheet.png` (the 12 log_* grid icons: frown, cross, sword, eye, gear, hourglass,
  scroll, up, down, gem, coin, person — all crisp 22px), `W3KIT2_badges_sheet.png` (the seven badge_N
  mockup crops, blurry at 18px).

## Judgement calls (recorded, 00-plan rule 8)

- J1 `test_a11y_legibility.gd:647-650` (not mine) pins `Cards.badge_icon("loot") == null`, so
  `BADGE_FOR_KIND` cannot literally map EVERY log kind. The feed's rows resolve their badge through
  `Widgets.log_row(..., kind)` → `Icons.at("log", kind)` (KIT-07's door); `badge_icon` keeps the morale pair
  (now the grid's crisp arrows instead of the badge_0/badge_5 mockup crops) plus HALL-20's three record
  states. The stale comment on that test is an observation in the handoff, not an edit.
- J2 "day advance" rows: a raw row per Day Tick would let a 28-day rest flood the 20-row ring buffer and
  push every real event out. The feed logs RESTS instead (`rest_in_town` → "Rested a day.",
  `rest_until_recovered` → one "Rested N days." row) and the raid row carries its own day; `advance_day()`
  itself writes nothing.
- J3 The feed is a non-persisted ring buffer of the last 20 (`GameState.EVENT_FEED_CAP`), cleared by
  `reset()`, absent from `to_dict()` — the plan's recommended shape, so SAVE_VERSION does not move.
- J4 The shot tool has no hover flag, so the tooltip's two lines are asserted by the unit test
  (`_make_custom_tooltip` returns a title Label over a body Label) and a `--hover` flag is a handoff
  observation for shot.gd's owner.
- J5 KIT-15: nothing in my files formats a price today (the CTA subline is the caller's string); the kit
  gains `Widgets.cta_priced(text, price)` and `Cards.price_text(n)` as the door, and the screen call
  sites are observations in the handoff.

## Progress (code landed, parse OK at 173 scripts)

- GameState.gd: `event_feed` ring buffer (cap 20, `log_event`, `recent_feed`, `_feed_batch`, cleared in
  `reset()`, not in `to_dict()`); rows written by hire (recruit), dismiss_raider (morale_down), sell_loot /
  sell_equipped (gold), sell_unusable_loot (ONE gold row, per-item rows muted), buy_consumable /
  buy_furnishing / buy_guild_furnishing / buy_back (loot), upgrade_building (system), record_attempt
  (raider_attack on a clear with the payout, mistake on a wipe with the fallen), rest_in_town (phase),
  rest_until_recovered (one phase row + one per departure), departures and disband in the day tick.
- Widgets.gd: `Icons` preload; `TAB_MIN`, `TOOLTIP_W`, `ORNAMENT*`, `CALLOUT_SWEEP`, `EMOTE_GLYPH_SCALE`;
  `Ornaments`/`Flourish` Node2D classes; `TooltipHost` (MOUSE_FILTER_PASS, `_make_custom_tooltip`);
  `reasoned(control, reason, glyph, width)` — padlock default through `Icons.at("lock","16")`, worn only
  with a reason, `width` wraps; `tab_row` TAB_MIN + deferred re-grab when no focus owner; `damage_number`
  z_index 1; `speech_bubble` draws a framed glyph alone at 2x (0,14) in the 40x44 footprint;
  `panel()` overlays "Ornaments" after the Pad; `callout()` gradient StyleBoxTexture + "Flourish";
  `log_row(..., kind)` → `Icons.at("log", kind)`, disc fallback wears `Badge.glyph_for_kind`;
  `tooltip_for`; `cta_priced`; `building_callout` pad 4/4, locked = two rows (Subtitle hidden, Reason
  one line), own double-deferred settle.
- Badge.gd: `GLYPH_FOR_KIND` + `glyph_for_kind(kind)`.
- Cards.gd: `Icons` preload; card's "ClassRow" with a 16px "ClassGlyph" before the class Label
  (`class_glyph`), class/band Label TRIM_ELLIPSIS, gear cells through `tooltip_for`; `event_log` —
  "View All" routes (`view_all_reason` / `open_records` presses the "Records" Button, pushing the
  Guildhall first), day-one empty line, default quill, rows through `log_row(kind)`; `BADGE_FOR_KIND` →
  Icons role/key pairs (morale pair on the grid arrows + locked/earned/claimed); `recent_events` reads
  the feed first (day desc, seq desc); `feed_tone`; `encounter_art` composes every rank (mockup crop gone);
  `price_text`.
- Deleted `game/assets/bg/boss_sludge_maw.png` + `.import` (only other reader: tools/probe/Kit.gd:134 —
  handoff §1/§2).
- Tests: `tests/unit/test_event_feed.gd` (10 cases) new; `test_widgets_kit.gd` updated (bubble geometry,
  View All reason, padlock default, TAB_MIN) + 7 new cases.
- J6 `tab_row`'s kit-level re-grab (W2 obs e) is gated on the PRESSED tab holding focus at press time
  (`Widgets._tab_refocus`): an unconditional "grab when nothing owns focus one frame after entering"
  would have put a focus ring on the active tab in every Market/Tavern shot taken without `--focus`
  (shot.gd mounts the screen with no router grab), changing every refdiff for a reason nobody asked for.
  A test's `pressed.emit()` and a shot's `--press` carry no focus, so they keep the ring where it was.
- Unit suite, first run after the code landed: 8/1908 failing, none mine after the two callout-clamp
  tests in `test_widgets_kit.gd` were updated to read the plate's own width (the locked plate is as wide
  as its one-line reason now, 283 vs the old fixed 276) — the other six are W3-MENU (17 asserts, one
  test), W3-OPTIONS, W3-ROSTER, W3-ENEMIES and W3-ROSTER's Guildhall `Theme_.get_theme()` bare call
  (test_text_scale), all mid-wave in files I do not own. `lint_motion.sh`: MOTION LINT OK.

## Shots (all in build/shots/, every one viewed with the Read tool; 0 SCRIPT ERRORs in every .log)

- `W3KIT2_Tavern_hire.png` (`Tavern --fixture --press="Hire — 60 G"`; crop `_log2x`): the strip's Recent
  Events reads "Hired Linda the Mage for 60 G." beside the grid's person badge; "View All" reasoned
  "Opens at Known." (the fixture guild is Unknown). A1.
- `W3KIT2_Town_raid.png` (`Town --fixture=raid`; crops `_log3x`, `_cards3x`, `_corner4x`, `_smith2x`): six
  "<name>: wipe" rows with the crisp red DOWN-ARROW badge (log_morale_down replaces the blurry badge_0
  crop); the four cards carry crossed swords / dagger / cross / hat before "Warrior / Rogue / Cleric /
  Mage"; the sidebar's PanelWarm shows the bronze corner ornament inside its double rim; the locked
  Blacksmith plate is TWO rows (title + the one-line CAUTION reason), the same height as its neighbours.
  FOUND AND FIXED from this shot: the raid row ("Wiped on … — N fell.") was stamped day 23 while the
  tick's twelve morale notes were day 24, so it sorted 13th and off the seven rows — `record_attempt`
  now writes the row after `_apply_raid_morale` (same day as the notes, feed rows sort above notes).
- `W3KIT2_Town.png` (`Town --fixture`, day 23, no raid): the callout plates measure 4px shorter than the
  wave-2 shot (dark run 76 vs 80 at x=790 — the Adventure's Board plate; pad 6/6 → 4/4); the emote
  markers are single small tailed bubbles at 2x (`W3KIT2_Town_emotes4x.png`: the mug with no frame behind
  it; the "..." keeps the frame) — W2-STAGE2's bubble-in-a-bubble is gone.
- `W3KIT2_Guildhall.png` (`--fixture`): W3-ROSTER's concurrent state; a glyph before every class word on
  the eight cards (dagger, hat, totem, fist, …); the tab row's active plate is TAB_MIN (110x32); the log's
  empty state carries the quill by default. A2.
- `W3KIT2_Guildhall_t150.png` (crop `_cards`): "Shaman — Slightl…" / "Rogue — Slightly …" trim inside
  the card at 150% (handoff-W2-RESULTS c). FOUND from this shot: the class word beside its glyph ran
  under the rim ("Shamar") — the names column now takes the leftover width and the class Label trims.
- `W3KIT2_RaidView_adv10.png` (`--fixture=raid --advance=10`; crop `_log3x`): sword / purple eye / red
  frown pixel badges on the log rows; "-30"/"-4" numbers above the figures; the reasoned "Skip to the
  end" wears the default padlock. A3 (RaidView side; the contrast test covers all 12 kinds).
- `W3KIT2_Results.png` (`--fixture=raid`; crop `_log2x`): scroll / red frown badges on "What happened",
  the steel corner ornament at the panel's top-left. A3.
- `W3KIT2_RaidPrep.png` (crops `_side`, `_callout3x`): the success callout is the dark→red sweep with the
  2px rim and the flourish top-right (KIT-09); FOUND: the 64px gradient stepped visibly — now 256. The
  mission well composes the main boss over the cave slice (the mockup crop is gone). A7, A10.

## Left undone / for the orchestrator

- The tooltip hover SHOT (A4) — no `--hover` flag in shot.gd (handoff observation); the behaviour is unit-tested.
- `tools/probe/Kit.gd:134` still loads the deleted PNG until handoff §1/§2 are applied (the art gate's Kit
  target, run by diff_all.sh only).
- Refdiff numbers: not run — the plan's W3-KIT2 section names no refdiff target of its own (Town/Guildhall/
  RaidView belong to their screens' units); the wave-end diff_all.sh records the 13.
- No canon number moved; no test outside my two files was edited; SAVE_VERSION untouched (the feed is not saved).

## Files changed

game/core/GameState.gd · game/ui/Widgets.gd · game/ui/Cards.gd · game/ui/Badge.gd · tests/unit/test_event_feed.gd (new) ·
tests/unit/test_widgets_kit.gd · game/assets/bg/boss_sludge_maw.png + .import (deleted) · build/plan/report-W3-KIT2.md ·
build/plan/handoff-W3-KIT2.md. game/ui/Bar.gd: owned, unchanged (nothing in the unit needed it).
