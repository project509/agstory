# Report — a11y-keys (M6-A11Y-01, -02, -03)

Files owned and touched: `project.godot`, `game/ui/Theme.gd`, `game/ui/Widgets.gd`,
`game/ui/Frame.gd`, `game/core/ScreenRouter.gd`, `tests/unit/test_a11y.gd` (new).
No other file edited. Nothing committed.

Companion files: `build/plan/q-a11y-keys.md`, `build/plan/handoff-a11y-keys.md`.

## What I found

Both audit items held up, one auditor claim did not.

* **A11Y-01 confirmed.** No `[input]` section in project.godot, no handler anywhere in `game/`.
* **A11Y-01, one claim wrong.** `remaining_work` asks for a `nav_prev_group` action for
  Shift+Tab. That is a Godot built-in (`ui_focus_prev`); a second action on the same key
  would be a duplicate nothing reads. Pinned by
  `test_the_builtin_half_of_the_map_is_still_intact`. Six of §13.1's eleven rows are
  engine defaults; five needed declaring (nine actions, `1`-`4` being four of them).
* **A11Y-02 confirmed.** Zero `focus_mode` / `grab_focus` / `focus_neighbor` in the tree.
* **A11Y-03 confirmed exactly.** Theme.gd:81 was `flat(transparent, EDGE_STEEL, 1, 3)` —
  1px, no expand margin, drawn INSIDE the rect. LinkButton had no `focus` stylebox at all.
* **New finding (harness).** Nothing under `tests/` can hold focus: `run_tests.gd` runs
  everything from `_initialize`, before the root window enters the tree (same reason
  `_ready` never fires there, and why tools/shot.gd works from `_process`).
  `grab_focus()` requires `is_inside_tree()`, so it is a no-op and
  `find_next_valid_focus()` returns null. Measured and pinned; see Gaps.

## What I built

### 1. The InputMap — `project.godot`, new `[input]` section

Nine actions for the five §13.1 rows Godot has no default for, keys PHYSICAL so §13.1's
QWERTY positions survive AZERTY: `nav_toggle` (Space), `nav_prev_subject` (Q),
`nav_next_subject` (E), `nav_cycle_filter` (F), `nav_codex` (F1), `nav_sort_1`..`nav_sort_4`
(1-4). The six built-ins are deliberately NOT restated — redefining one replaces its whole
event list. Joypad events for §13.2's three plain-button rows on the same actions:
X -> toggle, Y -> cycle filters, View/Back -> codex.

### 2. Focus that follows the layout — `game/ui/Frame.gd:431-576`

* `FOCUS_REGIONS = ["rail", "header", "scene", "sidebar", "strip"]` — §13.1's four names
  mapped onto Frame's five regions (`list` = scene, `detail` = sidebar, `commit` = strip).
  Rail first, per §13.1's closing sentence, even though the header band is painted above it.
* `Frame.focus_order(p, extra := {})` — collects the focusable controls per region, drops
  empty regions, wires `focus_next`/`focus_previous` region-to-region and all four
  `focus_neighbor_*` member-to-member, both rings wrapping (§13.2: "it wraps, so there is
  no dead end"). Returns the regions so a test can assert the order. Idempotent.
* `Frame.focus_entry(p)` — the first control in reading order, for a screen's
  `default_focus()` one-liner.
* `Frame.tab_steps_within_region` (default `false`) — the switch for the other reading of
  §13.1's Tab row; see `build/plan/q-a11y-keys.md`.
* Disabled controls and invisible branches are skipped (Settings' hidden strip, an
  unbuilt nav item).

### 3. Initial focus and Esc/F1 — `game/core/ScreenRouter.gd:26-36, 108-202, 233-243`

* `initial_focus_target(screen)` — static and pure: the screen's own
  `default_focus() -> Control` if it has one, else the first focusable control in tree
  order. `_load_into_host` grabs it after `on_enter`, guarded by the engine's own
  in-tree/visible precondition. **Every screen therefore has an initial focus today,
  without editing a single screen.**
* `back()` — §13.1's `Esc`: pop when the stack is deeper than one, else push Settings when
  the root is the Town, else nothing. It never quits the game.
* `codex()` — §13.1's `F1`, inert while S16 does not exist (guarded by `screen_exists`).
* `_unhandled_input` and not `_input`, so a screen keeps first refusal on both keys.

### 4. The focus ring — `game/ui/Theme.gd:63-89, 110, 277-288` and `game/ui/Widgets.gd:191-212`

* `Theme.focus_ring()` — one shared shape: transparent fill, 2px `EDGE_STEEL` border,
  radius 3, **`set_expand_margin_all(2)`**, which is what puts it outside the rect and is
  what §12.3 means by "drawn *outside* the bounds so it never shifts layout".
* `_button()` now uses it, so all nine button variations get it (ButtonCta, ButtonCtaCost,
  Button, ButtonIcon, ButtonPortrait, NavItem, NavItemActive, ButtonSlot, ButtonMini) —
  including the nav rail, which is what makes the rail visibly reachable.
* **LinkButton** gets the same ring plus `font_focus_color`; it had no focus item at all.
* `Widgets.link()` also turns the underline on for focus and off again when focus leaves,
  because `UNDERLINE_MODE_ON_HOVER` is invisible to a keyboard.
* Colour and the missing 1px outer offset are argued at the call site and in
  `build/plan/q-a11y-keys.md` (third entry). The hue stays the reference's `edge.steel`;
  2px-and-outside is the half the design owns.

## The tests — `tests/unit/test_a11y.gd`, 30 tests, all passing

Suite: **1201 passing / 4 failing**, and the 4 are `test_adventures.gd` and
`test_golden.gd` — the sim agent's in-flight work, not reachable from anything I touched.
`parse_check` OK (120 scripts), `tools/lint_no_global_classes.sh` OK.

The InputMap (7):
1. `test_every_action_docs13_names_exists` — all nine actions are in the map.
2. `test_every_action_is_bound_to_the_key_docs13_gives_it` — each is bound to §13.1's key.
3. `test_the_letter_and_digit_keys_are_physical` — Q/E/F/1-4 carry a physical code, not a
   logical one, so they stay in place on a non-QWERTY layout.
4. `test_the_builtin_half_of_the_map_is_still_intact` — Enter on `ui_accept`, Esc on
   `ui_cancel`, Tab on `ui_focus_next`, Shift+Tab (or BACKTAB) on `ui_focus_prev`, four
   arrows. The tripwire for someone redefining a built-in and dropping its events.
5. `test_space_and_enter_stay_two_different_bindings` — Enter is not a toggle; Space is;
   and the Space/`ui_accept` overlap is pinned deliberately, pointing at the q entry.
6. `test_the_gamepad_equivalents_docs132_names_are_bound` — X / Y / View.
7. `test_a_real_key_event_fires_the_action` — a real `InputEventKey` matches, so the map
   works the way a screen's `_unhandled_input` will use it.

The focus ring (5):
8. `test_every_button_variation_has_a_focus_ring_outside_its_bounds` — enumerates every
   theme type whose variation chain reaches Button (plus LinkButton), and asserts for each:
   a `focus` StyleBoxFlat exists, all four border widths are 2, all four expand margins are
   >= 2, the border is `EDGE_STEEL`, and the fill is transparent. Found 10 types.
9. `test_the_link_button_is_in_that_family` — LinkButton has the ring and a focus colour.
10. `test_the_focus_ring_is_the_same_shape_on_every_widget` — §12.3's "identical shape".
11. `test_a_focused_link_underlines_itself` — a focus handler exists and flips the
    underline both ways.
12. `test_an_always_underlined_link_is_left_alone` — no handler where there is nothing to
    toggle.

The focus order (7):
13. `test_the_focus_order_is_reading_order_not_tree_order` — rail, header, scene, ...,
    commit, AND asserts the premise that tree order really differs (otherwise the test
    proves nothing).
14. `test_tab_from_the_last_control_in_a_region_reaches_the_next_region` — for every
    region, and the ring wraps forwards and backwards.
15. `test_tab_is_a_region_step_and_the_arrows_move_inside_the_region` — Tab leaves the
    rail even from its first item; arrows step and wrap at both ends; the vertical and
    horizontal arrows agree.
16. `test_the_other_reading_of_tab_is_available_behind_the_switch` — the flag works.
17. `test_the_nav_rail_is_reachable_and_escapable` — Tab from the content reaches the rail
    within one cycle, and Tab from every rail item leaves the rail (no trap).
18. `test_a_disabled_nav_item_is_not_a_tab_stop` — and the arrows step over it.
19. `test_focus_order_is_idempotent` — and no control Tabs to itself.
20. `test_frame_offers_an_entry_control_for_default_focus`.

Initial focus (4):
21. `test_a_screen_can_declare_its_initial_focus` — the declaration beats tree order.
22. `test_a_screen_that_declares_nothing_still_gets_focus`.
23. `test_a_declaration_that_cannot_hold_focus_falls_back` — a disabled control cannot be
    the initial focus.
24. `test_every_mounted_screen_designates_exactly_one_initial_focus` — mounts MainMenu,
    Town, AdventureBoard and Settings through the real router and asserts each designates
    exactly one control, inside itself, focusable, stable across two calls.

Esc / F1 (4) and the harness (1):
25. `test_escape_goes_back_one_level`.
26. `test_escape_from_the_town_opens_settings` — and Esc again returns to the town.
27. `test_escape_at_any_other_root_does_nothing` — the router never quits the game.
28. `test_the_escape_key_itself_is_wired` — a real Esc event through `_unhandled_input`.
29. `test_f1_is_wired_to_the_codex_and_inert_until_s16_exists`.
30. `test_the_harness_cannot_hold_focus_and_this_is_why` — pins the harness limitation and
    says what to re-enable if it changes.

## Docs I relied on

* `docs/13-ui-ux.md:693-708` — §13.1, the eleven-row keyboard map and the closing rule
  ("focus order always follows reading order: rail, then header, then content, then
  commit"; "focus never traps in a modal without a visible way out").
* `docs/13-ui-ux.md:710-740` — §13.2, the gamepad map, the hotspot ring ("it wraps, so
  there is no dead end"; "one hotspot is always focused, even with no input"), and "no
  interaction may exist only as a pointer gesture".
* `docs/13-ui-ux.md:647` — §12.3's focus row: "2px `brass.base` ring with a 1px `ink.body`
  outer offset, drawn *outside* the bounds ... Identical shape on every widget. Always
  visible."
* `docs/13-ui-ux.md:~685` — §13's blocking rows: full keyboard navigation, and 3:1
  contrast for UI boundaries and focus rings.
* `docs/13-ui-ux.md:601` — §11.4: after the wipe, "`Try again` is left and
  **default-focused**".
* `docs/13-ui-ux.md:~289, §10.3` — the state-word/focus rules quoted in the handoff.
* `art/ref/specs/04-palette.md` §5 — `accent.steel #4982A2`, "Selection, focus ring,
  active state" (why the ring is steel and not brass).
* `docs/15` Q-85, quoted by the audit: "Focus model is 1.0".

## What I deliberately did NOT do

1. **No screen edits.** I do not own `game/screens/`. Per-screen `default_focus()`
   declarations (Town's last-visited building, Results' "Try again"), the
   `Frame.focus_order(...)` call per screen, and per-screen handlers for
   `nav_toggle` / `nav_sort_*` / `nav_prev_subject` / `nav_next_subject` /
   `nav_cycle_filter` are written as exact old→new edits in
   `build/plan/handoff-a11y-keys.md` §1-3. The audit itself said to split this
   ("Do not attempt eleven screens in one iteration").
2. **No `game/ui/KeyNav.gd`.** The audit proposed it; it is not in my file list, so the
   region model lives in `Frame.gd` (which owns the shell) instead, and the per-screen
   key handlers stay handoffs. Nothing was created outside my listed paths.
3. **The 1px `ink.body` outer offset of §12.3** is not drawn — one `StyleBoxFlat` has one
   border colour, and this chrome's ink token is a near-white that would read as a glow on
   the dark ground. Argued in `q-a11y-keys.md`, with the one-line implementation if a
   person rules the other way.
4. **`Space` was left on `ui_accept`.** Removing it separates toggle from primary cleanly
   and takes Space away from every Button in the game. The overlap is pinned by a test and
   put to docs/15 rather than decided quietly.
5. **`nav_prev_group` was not added** — `ui_focus_prev` already is Shift+Tab (the auditor's
   claim was wrong; the test now proves the built-in carries it).
6. **§13.2's LB/RB, LT/RT and right-stick rows are unbound** — LB/RB needs the built-in Tab
   actions redefined, LT/RT are analog axes, and the stick needs a handler. Reasons and
   the exact remaining work are in the handoff §6. OQ-12 still owns whether they block 1.0.
7. **`Widgets.log_row` was not made focusable.** Log rows are output, not interaction. But
   docs/13 §10.3's bench-delta preview IS bound to focus, so RaidPrep's chalked rows will
   need to be real controls — handoff §8.
8. **`Widgets.pager_button`'s tooltip-only label was left alone** (it is my file). Adding
   a Label changes the strip layout and the art-pass pixel numbers; it needs the strip
   owner's call. Flagged, not fixed — handoff §8.

## Gaps, honestly

* **No live focus assertion.** `run_tests.gd` runs from `_initialize`, before the root
  window enters the tree, so `grab_focus()` is a no-op and `find_next_valid_focus()`
  returns null there. My tests assert the wiring Godot's Tab walk reads (`focus_next`,
  `focus_neighbor_*`) and that the router designates exactly one initial control — one
  step short of "a mounted screen HAS exactly one focused control", which the task asked
  for and the harness cannot express. `build/plan/handoff-a11y-keys.md` §5 carries a
  complete paste-in `tools/a11y_smoke.gd` that asserts the live version from `_process`
  (the way tools/shot.gd gets a real tree). Until that lands, "focus is grabbed" is
  verified by code inspection, not by a test.
* **Screenshot risk to the art pass.** Every mounted screen now has a focused control, so
  a shot through the router will paint a focus ring the reference concepts do not have,
  and refdiff's MAE will move. Fix is three lines in `tools/shot.gd` (handoff §4) —
  release focus before capturing. I could not make or verify that change.
* **The header region will be empty on real screens.** `Frame.standard_chips` builds
  PanelContainers, which are not focusable, so §13.1's "then header" step collapses and
  the live order is rail -> scene -> sidebar -> strip. Correct (there is nothing to
  operate in the header) but worth knowing before someone hunts for the missing step.
* **`CODEX_SCENE` is a provisional path.** S16 does not exist; F1 is inert and tested as
  inert. Whoever builds S16 must confirm the filename against the constant.
* **Five of the eleven §13.1 rows do nothing yet** — Space, 1-4, Q/E, F. The actions exist,
  the ordering trap is documented, and the per-screen wiring is the next backlog item.

---

# Repair pass — reviewer findings, one at a time

Everything below is measured on Godot 4.7.1 through the real router, from
`_process` (where the tree exists), not inferred. The two probes are
`tools/probe/scratch/probe_focus_a11y.gd` and `..._a11y2.gd`.

## R1. `Widgets.link()` never set `focus_mode` — REVIEWER CORRECT, fixed

Measured: `LinkButton.new().focus_mode == 3` (`Control.FOCUS_ACCESSIBILITY`),
`Button.new().focus_mode == 2` (`FOCUS_ALL`). Godot's Tab walk stops only on
`FOCUS_ALL`, so every link in the game was pointer-only and both the LinkButton
focus ring and the new underline handlers were unreachable. Measured Tab chain
on `AdventureBoard.tscn` BEFORE the fix — six stops, rail only, forever:

    Nav_home -> Nav_tavern -> Nav_roster -> Nav_market -> Nav_board -> Nav_options -> Nav_home

and the board's `Widgets.link("Back to town")` reported `mode=3`, absent from it.

Fix: `game/ui/Widgets.gd:207` — `l.focus_mode = Control.FOCUS_ALL`, with the
measurement in the comment so it is not "tidied" away as redundant.

## R2. `_focusable` / `_can_focus` accepted three modes the engine refuses — REVIEWER CORRECT, fixed

* `game/ui/Frame.gd:_focusable` and `game/core/ScreenRouter.gd:_can_focus` now
  require `focus_mode == Control.FOCUS_ALL`. Measured values in this engine:
  `FOCUS_NONE 0`, `FOCUS_CLICK 1`, `FOCUS_ALL 2`, `FOCUS_ACCESSIBILITY 3`.
* Consequence the reviewer described is real: with the old predicate the router
  would hand a LinkButton to `grab_focus()`, the engine refused it, and the
  screen opened with `gui_get_focus_owner() == null` and only a warning on
  stderr.

## R3 + R4. The rail trap, and A11Y-02 having no caller in `game/` — REVIEWER CORRECT, fixed in the shell

The mechanism had zero callers, so the shipped Tab order was still tree order.
Fixed WITHOUT touching `game/screens/`: `Frame.build()` now leaves two
Callables on the host as metadata (`frame_focus_order`, `frame_focus_entry`,
`game/ui/Frame.gd:_publish_focus_hooks`) and `ScreenRouter._load_into_host`
invokes them after `on_enter()` — the first moment a screen's content exists.
Metadata and not a preload because nothing under `game/core` depends on
`game/ui` and the focus model is not going to be the first thing to invert that.

`initial_focus_target()` now prefers the shell's reading-order entry over tree
order, which is what makes §13.1's "rail, then header, then content, then
commit" true rather than accidental: `Frame.build()` adds the scene host FIRST
so panels draw over it, so tree order opens a screen mid-content.

Measured AFTER, same screen: initial focus `Nav_home`, and Tab now leaves the
rail and the ring closes — `Camp -> Back to town -> Camp`. Two regions, because
the board's other content is not focusable at all (see the handoff).

## R5. The brief's central assertion — REVIEWER CORRECT that it was missing; it is now a real, passing instrument

New: `tests/unit/a11y_smoke.gd` (runs standalone, NOT collected by
`run_tests.gd`, whose discovery requires a `test_` prefix):

    godot --headless --path . --script res://tests/unit/a11y_smoke.gd

Why it cannot be a suite test — measured this pass, both phases in one run
(`tools/probe/scratch/probe_focus_a11y2.gd`):

    === _initialize phase ===   (this is where run_tests.gd runs)
    root.is_inside_tree=false
    ERROR: Condition "!is_inside_tree()" is true.  at: grab_focus (control.cpp:2996)
    owner=<Object#null>
    ERROR: Parameter "data.tree" is null.  at: get_tree  (find_next_valid_focus)
    === _process phase ===
    owner=@Button@37:<Button#42228254191>

So the reviewer and the earlier report are both right: focus CAN be set headless
from `_process`, and CANNOT be set from `_initialize`. The suite runs in
`_initialize`. Hence a second instrument with its own exit code rather than a
test that pretends.

It applies `tools/fixture_reference.gd` first — without a guild every list is
empty and a keyboard check passes by having nothing to reach — then for each of
the eleven screens asserts, by ASKING GODOT:

1. `gui_get_focus_owner() != null` after `router.goto(path)`, inside the screen,
   and `FOCUS_ALL` — the brief's assertion, and the audit's stated acceptance test.
2. The owner is the rail's first item where there is a rail (§13.1 reading order).
3. The `find_next_valid_focus()` ring closes, visits no stop twice, and LEAVES
   the rail whenever the screen has any enabled button outside it.
4. `find_valid_focus_neighbor(SIDE_BOTTOM)` steps every rail item and wraps
   (§13.1 arrows; §13.2 "it wraps, so there is no dead end").
5. The reachable closure of Tab + Shift-Tab + four arrows covers EVERY enabled
   focusable on the screen — §13.2's "no interaction may exist only as a pointer
   gesture", asked of the engine.
6. No enabled `BaseButton` has a `focus_mode` the keyboard cannot reach. This is
   the check with teeth: it is the one that fails on the un-fixed
   `Widgets.link()`, and the reason check 3 counts BUTTONS outside the rail
   rather than current Tab STOPS — a refused button is absent from the stop
   list, so a stops-based guard lets the defect hide the evidence of itself.
   That is exactly why the earlier `test_the_nav_rail_is_reachable_and_escapable`
   passed on a trapped screen.

Measured result, all eleven screens, with the fixture applied:

    ok  MainMenu        owner='New Guild'   ring=4   rail=0  focusable=4   reachable=4
    ok  Town            owner='Camp'        ring=3   rail=6  focusable=11  reachable=11
    ok  AdventureBoard  owner='Camp'        ring=3   rail=6  focusable=9   reachable=16
    ok  Tavern          owner='Camp'        ring=4   rail=6  focusable=19  reachable=19
    ok  Guildhall       owner='Camp'        ring=3   rail=6  focusable=42  reachable=42
    ok  Market          owner='Camp'        ring=3   rail=6  focusable=58  reachable=60
    ok  RaidPrep        owner='Camp'        ring=3   rail=6  focusable=14  reachable=14
    ok  RaiderDetail    owner='Camp'        ring=4   rail=6  focusable=24  reachable=24
    ok  RaidView        owner='1x'          ring=10  rail=0  focusable=9   reachable=10
    ok  Results         owner=<icon button> ring=6   rail=0  focusable=5   reachable=6
    ok  Settings        owner='Camp'        ring=3   rail=6  focusable=22  reachable=22
    A11Y SMOKE PASSED   11 screen(s)

`reachable` exceeds `focusable` only by disabled buttons, which Godot's own walk
stops on and this list deliberately excludes (docs/13 §7 puts the reason in an
adjacent Label); the instrument prints the disabled count so the gap is
explained rather than mysterious.

`Frame._wire_regions` stale-neighbour bug (the reviewer's fourth "missing test")
is fixed at `game/ui/Frame.gd:_wire_regions`: a region that shrinks to one
member on a rebuild now has its four `focus_neighbor_*` CLEARED instead of
keeping paths to controls that no longer exist.

## R6. WHERE THE REVIEWER IS WRONG: the `clip_contents` ring clipping

> "Measured with a mounted layout, Tavern.tscn and RaidPrep.tscn each have a
> focusable Button flush (slack 0px) against a `clip_contents` 'Sidebar', so the
> 2px outer ring is clipped on that edge."

This does not reproduce, and I believe I know how it was produced. Measuring a
mounted screen WITHOUT waiting for a layout pass reports every child of a
container at the container's own origin, so the top and left slack come out as
exactly 0 for every control in the panel. That is the signature in the claim:
"flush (slack 0px)" on the two leading edges, for a control the sidebar actually
insets by 18px. My first run reproduced the artifact exactly —

    CLIP 'Back to town' slack=[0.0, 0.0, 273.0, 600.0] clipper=Sidebar
      rect=[P:(2678,79) S:(105,35)]  clipper_rect=[P:(2678,79) S:(378,635)]

note the control's origin IS the clipper's origin, and both are at x=2678 on a
1536-wide screen. After adding a 12-frame settle before measuring, the same
sweep reports:

    Tavern.tscn          focusables=9  clipped=0
    RaidPrep.tscn        focusables=7  clipped=0
    AdventureBoard.tscn  focusables=7  clipped=0

`Frame.sidebar()` builds the panel with an 18px content margin, so a sidebar
control has 18px of slack against the clipper on the two edges that matter and
the 2px ring fits. **No change made to `Theme.gd` or `Frame.gd` for this.**

The risk itself is real, though, and there IS one true instance the reviewer did
not name — `Settings.tscn`. Measured after layout, all thirteen setting-row
controls sit flush against the right edge of the options `ScrollContainer`
(control x=940 w=150 → end 1090; viewport x=260 w=830 → end 1090; slack 0px on
the right), so the ring is clipped on that edge. `game/screens/Settings.gd` is
not mine: the exact one-line fix is `build/plan/handoff-a11y-keys.md` §13.

## R7. Also corrected: two claims in my own earlier report

* **"Screenshot risk to the art pass"** — withdrawn. `tools/shot.gd:135-143`
  instantiates the scene and calls `build()`/`on_enter()` itself; it never calls
  `router.goto()`, so the only code that grabs focus never runs during a shot.
  No ring is painted and no refdiff number moves. Handoff §4 is withdrawn (§10).
* **"A/B/D-pad are already Godot defaults on ui_accept / ui_cancel"** — a
  comment in the test file, and false. Measured: `ui_up` ships `joy btn=11` plus
  an axis event, but `ui_accept` and `ui_cancel` shipped NO joypad event at all,
  so §13.2's `A` (primary) and `B` (back) rows were dead and a controller could
  neither confirm nor cancel. project.godot now restates both actions with the
  engine's own keyboard events plus the button, and §13.2's `Start` row (the one
  the reviewer flagged) is bound as `nav_settings` → `ScreenRouter.settings()`.
  The consequence — those two actions are no longer engine defaults — is
  recorded in `build/plan/q-a11y-keys.md`.

## Proving the new instrument has teeth

The reviewer's real complaint was tests that pass while the app is broken, so I
re-created the pre-fix state on a live mounted board (link back to
`FOCUS_ACCESSIBILITY`, the router's wiring stripped off every button) and ran the
smoke's checks against it. Throwaway script, deleted after the run.

With no guild — the state the trap actually lives in, because the board's list is
then empty:

    check 6 -> 1 refused button(s): [@LinkButton@108]
    check 3 -> ring: [Nav_home, Nav_tavern, Nav_roster, Nav_market, Nav_board, Nav_options]
    check 3 -> Tab leaves the rail: false      <-- the trap, reproduced

With the reference fixture applied, the rung buttons make tree order leave the
rail, so only check 6 fires:

    check 6 -> 1 refused button(s): [@LinkButton@274]
    check 3 -> Tab leaves the rail: true

Two things follow, and both are now in the instrument. First, check 6 (every
enabled button is a stop Godot accepts) is the check that catches the defect in
BOTH states, which is why it exists. Second, the trap is only visible on an
EMPTY screen, so the smoke sweeps all eleven screens twice — once with no guild,
once with the fixture. A single-pass instrument would have missed the half the
reviewer found.

## Final state

    tools/with_godot_lock.sh "$GODOT" --headless --path . --script res://tools/parse_check.gd
    PARSE_CHECK scanned 123 script(s) / PARSE_CHECK OK
    tools/lint_no_global_classes.sh
    LINT OK  no cross-file class_name references in sim/ or game/
    tools/with_godot_lock.sh "$GODOT" --headless --path . --script res://tests/run_tests.gd
    TESTS FAILED   1/1266 failing
      FAIL  test_adventures.gd :: test_the_mini_boss_is_still_winnable
    tools/with_godot_lock.sh "$GODOT" --headless --path . --script res://tests/unit/a11y_smoke.gd
    A11Y SMOKE PASSED   22 screen mount(s)

1266 total, 1 failing, and the failure is `test_adventures.gd` — the sim agent's
in-flight encounter tuning, not reachable from anything in my six files.
`tests/unit/test_a11y.gd` is 36 tests, all passing: 30 from the first pass
(2 renamed, 4 strengthened) and 6 new this pass —

* `test_the_gamepads_a_and_b_are_bound_because_the_engine_does_not_bind_them`
* `test_the_gamepads_start_button_opens_settings`
* `test_a_link_is_a_stop_the_engine_accepts`
* `test_a_control_the_engine_would_refuse_is_not_treated_as_a_tab_stop`
* `test_the_router_wires_the_shells_focus_order_on_every_real_screen`
* `test_a_region_that_shrinks_to_one_member_drops_its_stale_neighbours`

plus `tests/unit/a11y_smoke.gd`, the live instrument: 6 checks × 11 screens × 2
data states.

Files touched, all mine: `project.godot`, `game/ui/Widgets.gd`,
`game/ui/Frame.gd`, `game/core/ScreenRouter.gd`, `tests/unit/test_a11y.gd`,
`tests/unit/a11y_smoke.gd` (new). `game/ui/Theme.gd` was NOT touched this pass —
see R6. Nothing committed.
