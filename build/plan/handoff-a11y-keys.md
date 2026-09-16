# Handoff — a11y-keys (M6-A11Y-01/02/03)

Everything here is in a file I do not own. Each item is an exact edit.
**Indentation differs per screen**: AdventureBoard, Guildhall, RaiderDetail, Settings,
Tavern, Town use TABS; Market, RaidPrep, Results use FOUR SPACES. Match the file.

What already works with NO screen edit: Tab / Shift+Tab / arrows / Enter (Godot's own
focus machinery), `Esc` back-one-level, `Esc`-on-the-town-opens-Settings and `F1`
(ScreenRouter), the focus ring on every button variation and on LinkButton (Theme), and
an initial focus on every mounted screen (ScreenRouter's tree-order fallback). The edits
below are the refinements: layout-shaped Tab order, per-screen initial focus, and the
five keys whose meaning is per-screen.

---

## 1. Declare the region focus order — one line per screen

docs/13 §13.1: "focus order always follows reading order: rail, then header, then
content, then commit." Without this line a screen keeps Godot's tree order, which on this
shell puts the scene host BEFORE the rail. Call it after the content is in the tree; if
the screen has a `_refresh()` that rebuilds rows, call it at the end of `_refresh()` too,
because controls created after the call are not wired.

| File | Anchor (last line of `_build()`) | Add after it |
|---|---|---|
| `game/screens/AdventureBoard.gd:107` | `_refresh()` | `Frame.focus_order(_frame)` |
| `game/screens/Guildhall.gd:114` | `_show_tab("roster")` | `Frame.focus_order(_frame)` |
| `game/screens/Market.gd:132` | `_refresh()` | `Frame.focus_order(_frame)` |
| `game/screens/RaidPrep.gd:124` | `_refresh()` | `Frame.focus_order(_frame)` |
| `game/screens/RaiderDetail.gd:129` | `_refresh()` | `Frame.focus_order(_frame)` |
| `game/screens/Tavern.gd:94` | `_refresh()` | `Frame.focus_order(_frame)` |
| `game/screens/Settings.gd:151` | `_sidebar(Frame.sidebar(f))` | `Frame.focus_order(f)` |
| `game/screens/Town.gd:115` | `_strip(f.strip)` | `Frame.focus_order(f)` |

`focus_order()` is idempotent (asserted by
`tests/unit/test_a11y.gd::test_focus_order_is_idempotent`), so calling it from both
`_build()` and `_refresh()` is safe.

Screens with no Frame shell — MainMenu, RaidView, Results, Facilities, Roster — keep the
tree-order default, which for a single column already IS reading order. RaidView is the
one to look at properly: §13.1 gives it `Space` (pause/resume) and `1`-`4` (speed), and
§13.2 gives it right-stick scrollback.

## 2. Per-screen initial focus (`default_focus`)

`ScreenRouter` calls `default_focus() -> Control` on the mounted screen when the method
exists, and otherwise focuses the first focusable control in tree order. Two screens have
an explicit answer in the docs; the rest can take the shell default.

**a. `game/screens/Town.gd` — docs/13 §13.2**: "One hotspot is always focused, even with
no input — on entry it is the last building visited, or the Adventure's Board on a fresh
save." `_build()` currently drops the callout buttons on the floor (the
`var btn := Widgets.button_of(callout)` line in the BUILDINGS loop), so keep them (TABS):

    add a member:   var _callouts: Dictionary = {}
    add a member:   var _frame = null
    in _build():    _frame = f
    in the BUILDINGS loop, right after `var btn := Widgets.button_of(callout)`:
                    if btn != null:
                        _callouts[String(b["id"])] = btn
    new method:
        ## docs/13 §13.2: the ring's position on entry is the last building
        ## visited, or the Adventure's Board on a fresh save.
        func default_focus() -> Control:
            var last: String = String(_state.last_building) if _state != null else ""
            if _callouts.has(last):
                return _callouts[last]
            if _callouts.has("board"):
                return _callouts["board"]
            return Frame.focus_entry(_frame)

The rest of §13.2's ring (D-pad steps around it, wrapping) wants
`Frame.focus_order(f, {"scene": <callout buttons in BUILDINGS order>})`, so the arrows
walk the buildings in AUTHORED order rather than whatever order the tree walk found.

**b. `game/core/GameState.gd`** — §13.2's "last building visited" has no source today.
Add `var last_building: String = ""`, set it where Town pushes a building scene (inside
the `btn.pressed` lambda), and carry it in `to_dict()`/`from_dict()` so the ring survives
a reload. That is a save-format change: coordinate with M3-SAVE-09.

**c. `game/screens/Results.gd` — docs/13 §11.4**: after the wipe, "`Try again` is left and
**default-focused**". The screen's authored equivalent is
`Widgets.button("Back to the board")` at `Results.gd:838`. Keep the reference in a member
and add (FOUR SPACES):

        func default_focus() -> Control:
            return _again if is_instance_valid(_again) else null

The label difference ("Try again" in the doc, "Back to the board" in the screen) is the
screen owner's to reconcile — I renamed nothing.

## 3. The five keys whose meaning is per-screen

`nav_toggle` (Space), `nav_sort_1`..`nav_sort_4` (1-4), `nav_prev_subject` /
`nav_next_subject` (Q/E) and `nav_cycle_filter` (F) now EXIST as InputMap actions and no
screen reads them. That is the split the audit asked for (A11Y-01 risk: "Do not attempt
eleven screens in one iteration"). The pattern, per screen:

    func _unhandled_input(event: InputEvent) -> void:
        if event.is_action_pressed("nav_cycle_filter"):
            _cycle_filter()                  # the screen's own existing method
            get_viewport().set_input_as_handled()

**The ordering trap, in writing:** a focused Button consumes `ui_accept` in its own
`_gui_input`, and Godot's built-in `ui_accept` still carries **Space** as well as Enter.
So `nav_toggle` will NOT reach `_unhandled_input` while a Button holds focus — the button
simply presses. For a bench raider row that is the right outcome (press == chalk); where
Enter and Space must differ, handle it in the control's `_gui_input`, or rule on the first
question in `build/plan/q-a11y-keys.md`.

## 4. `tools/shot.gd` — release focus before capturing

**This one can move the art-pass numbers.** Every mounted screen now has a focused
control, so a shot taken through the router paints a 2px steel focus ring where there was
none, and refdiff's MAE (BUILD_STATE.md: Kit 16.9 / Town 26.3 / RaidPrep 20.2) will move.
The reference concepts show no focused control, so the SHOT should drop focus rather than
the ring being made invisible. In `shot.gd`, after the screen is built and before the
capture frame (TABS):

    var focused := _vp.gui_get_focus_owner()
    if focused != null:
        focused.release_focus()

Then re-run `tools/art/refdiff.py` and confirm the numbers are unchanged.

## 5. `tools/a11y_smoke.gd` — the live focus test the unit suite cannot run

`tests/run_tests.gd` does its whole run from `_initialize`, before the root window enters
the tree, so `grab_focus()` is a no-op there and `find_next_valid_focus()` returns null
(measured — `test_the_harness_cannot_hold_focus_and_this_is_why` pins it). The assertions
in `test_a11y.gd` therefore read the wiring Godot's Tab walk consumes. To assert the LIVE
behaviour, this script does the same work from `_process`, as tools/shot.gd does. Paste
as-is (TABS):

    extends SceneTree
    ## The half of tests/unit/test_a11y.gd the unit harness cannot reach: real
    ## focus, in a real tree. run_tests.gd works from _initialize, before the
    ## root window enters the tree, where grab_focus() is a hard error.
    ##   godot --headless --path . --script res://tools/a11y_smoke.gd
    var _done := false
    func _process(_dt: float) -> bool:
        if _done:
            return true
        _done = true
        var host := Control.new()
        host.set_anchors_preset(Control.PRESET_FULL_RECT)
        root.add_child(host)
        var router = load("res://game/core/ScreenRouter.gd").new()
        root.add_child(router)
        router.register_host(host)
        var bad := 0
        for path in ["res://game/screens/Town.tscn", "res://game/screens/Tavern.tscn",
                "res://game/screens/AdventureBoard.tscn", "res://game/screens/Settings.tscn"]:
            if not ResourceLoader.exists(path):
                continue
            router.goto(path)
            var who := host.get_viewport().gui_get_focus_owner()
            if who == null:
                print("A11Y FAIL  %s has nothing focused" % path)
                bad += 1
                continue
            var next_ctl := who.find_next_valid_focus()
            if next_ctl == null or next_ctl == who:
                print("A11Y FAIL  %s: Tab from the initial focus goes nowhere" % path)
                bad += 1
            else:
                print("A11Y ok    %s: %s -> %s" % [path, who.name, next_ctl.name])
        print("A11Y SMOKE %s" % ("OK" if bad == 0 else "FAILED (%d)" % bad))
        quit(1 if bad > 0 else 0)
        return true

Worth adding to `tools/verify.sh` beside the parse check once it is green.

## 6. docs/13 §13.2 leftovers I did not bind

`project.godot`'s `[input]` binds X / Y / View to `nav_toggle` / `nav_cycle_filter` /
`nav_codex`, and Godot's built-ins already cover A / B / D-pad / left stick. Three rows of
§13.2 are still unbound, each for a stated reason:

* `LB` / `RB` (previous / next focus group) — needs `ui_focus_prev` / `ui_focus_next`
  REDEFINED in project.godot, which replaces their whole event list; restate
  Tab / Shift+Tab in the same block or the keyboard loses them.
* `LT` / `RT` (previous / next raider) — analog axes, so `InputEventJoypadMotion` with an
  axis value, not a button index.
* Right stick vertical (scroll the focused list; S11 scrollback) — needs a handler, not a
  binding.

OQ-12 still owns whether any of this blocks 1.0.

## 7. FYI — `project.godot` was edited by another agent mid-wave

While I held `project.godot` (listed as exclusively mine) the `Audio` autoload and an
`[audio]` section appeared in it. My `[input]` section applied cleanly on top and both are
present; nothing was lost. Flagged only because the ownership list said otherwise.

## 8. Two smaller things, one of them in a file I do own

* `game/ui/Widgets.gd::pager_button` (mine) carries its only label in `tooltip_text`
  ("Next page" / "Previous page") — no Label, no Button text. That breaks the test
  contract's rule and leaves the pager nameless to a keyboard user. I did NOT fix it:
  adding a Label changes the strip's layout and the art-pass numbers with it, so it wants
  a call from the strip's owner (docs/13 §7).
* `game/ui/Widgets.gd::log_row` rows are not focusable. Deliberate — they are output, not
  interaction, so §13.2's "no interaction may exist only as a pointer gesture" does not
  bite. But docs/13 §10.3's bench-delta preview IS "bound to focus, not hover", so
  whoever builds that on RaidPrep needs the chalked-raider rows to be focusable controls,
  not Labels.

## 9. `RaidView` should decide what `Esc` means mid-raid

`ScreenRouter._unhandled_input` now treats `Esc` as "back one level" everywhere, per
§13.1. `RaidView` is a pushed screen, so `Esc` during a running raid pops back to
RaidPrep. Node input propagation runs later siblings first and the autoloads are added
before the main scene, so a screen's own `_unhandled_input` sees the key FIRST — RaidView
can claim `Esc` for its own meaning (skip to the post-mortem, or ignore it while the sim
is playing) with:

    func _unhandled_input(event: InputEvent) -> void:
        if event.is_action_pressed("ui_cancel"):
            _on_skip()                       # or simply swallow it while playing
            get_viewport().set_input_as_handled()

Nothing forces this — the current behaviour is exactly what §13.1 asks for — but abandoning
a raid on a stray `Esc` is worth a deliberate decision rather than a default.

---

# Repair pass — corrections and new handoffs

## 10. WITHDRAWN: §4 (`tools/shot.gd` — release focus before capturing)

**Do not apply handoff §4.** I claimed a screenshot would now paint a focus ring and move
refdiff's MAE. Checked: `tools/shot.gd:135-143` instantiates the PackedScene and calls
`build()` / `on_enter()` **itself** — it never calls `router.goto()`, so
`ScreenRouter._load_into_host` (the only code that grabs focus) never runs during a shot.
No ring is painted, no MAE moves, nothing to change. The `register_host` call at
`tools/shot.gd:118` is for the rail's navigation only.

## 11. WITHDRAWN: §5 (paste-in `tools/a11y_smoke.gd`)

Superseded — it is written, run and green, at `tests/unit/a11y_smoke.gd` (a path I am
allowed to create in). Two-pass sweep, eleven screens each, 22 mounts. Run it with:

    tools/with_godot_lock.sh "$GODOT" --headless --path . --script res://tests/unit/a11y_smoke.gd

It is not named `test_*`, so `run_tests.gd` does not collect it.

## 12. `tools/verify.sh` — add the live a11y gate (NEW, exact edit)

The suite cannot assert live focus (measured: `grab_focus()` fails from `_initialize`),
so this instrument is the only thing standing between the project and a silently
keyboard-broken screen. Add it next to the parse check and the test run:

OLD (wherever the test run is invoked, after it):
    # (nothing)
NEW:
    tools/with_godot_lock.sh "$GODOT" --headless --path . --script res://tests/unit/a11y_smoke.gd \
      || { echo "a11y smoke failed"; exit 1; }

It exits 0 on pass, 1 on failure, 2 if the GameState autoload is missing.

## 13. `game/screens/Settings.gd` — the focus ring is clipped on 13 controls (NEW)

Measured with a real layout pass on a mounted `Settings.tscn`: every setting-row control
sits flush against the right edge of its `ScrollContainer` (control rect x=940 w=150,
so end 1090; the scroll viewport is x=260 w=830, end 1090 — slack **0px**). §12.3's ring
has a 2px expand margin, so it is clipped on that edge for all thirteen. docs/13 §12.3
says the ring is "Always visible", so this is a real breach — and it is the only true
instance of the A11Y-03 risk (see report §R6: the Tavern/RaidPrep sidebar claim does not
reproduce once the tree is laid out).

Cheapest fix, one line, no column re-measure:

OLD  `game/screens/Settings.gd:255`
    ctrl.custom_minimum_size = Vector2(COL_CTRL_W, CTRL_H)
NEW
    # docs/13 §12.3's focus ring is drawn 2px OUTSIDE the control. The row sits
    # flush against the ScrollContainer's right edge, which clips, so the
    # control gives the ring its margin back. Measured: slack was 0px.
    ctrl.custom_minimum_size = Vector2(COL_CTRL_W - 4, CTRL_H)

(or add `margin_right = 4` to the row's container — either restores 2px of slack on the
clipped edge. Re-run `tests/unit/a11y_smoke.gd` and `tools/art/refdiff.py` after.)

## 14. `game/screens/AdventureBoard.gd` — the notice row is a pointer-only gesture (NEW)

`AdventureBoard.gd:206-210` connects `row.gui_input` on each rung's PanelContainer so a
click anywhere on the row pins it to the sidebar (`_select`). The rung's own Button calls
`_on_pick`, which is a different action, so **pinning a notice without departing has no
keyboard path at all** — measured, eight such targets with the reference fixture. That is
docs/13 §13.2's absolute rule ("no interaction may exist only as a pointer gesture").

docs/13 §10.3 already gives the shape of the answer — "Hovering **or focusing**", focus is
the primitive — so the fix is one line beside the existing `pressed.connect`:

OLD  `game/screens/AdventureBoard.gd:183-184`
        var enc_id: String = e.id
        btn.pressed.connect(func() -> void: _on_pick(enc_id))
NEW
        var enc_id: String = e.id
        btn.pressed.connect(func() -> void: _on_pick(enc_id))
        # docs/13 §10.3: focus is the primitive, hover merely also sets focus.
        # Without this, pinning a notice to the sidebar is pointer-only (§13.2).
        btn.focus_entered.connect(func() -> void: _select(enc_id))

`tests/unit/a11y_smoke.gd` prints these as `warn ... pointer-only gesture target(s)`
rather than failing, because the fix lives in screens I do not own.

## 15. `game/screens/Results.gd` — §11.4's "Try again" is not the initial focus (NEW)

Measured through the real router with the fixture applied: Results opens with focus on an
icon-only Button (no text). docs/13 §11.4 requires that after a wipe "`Try again` is left
and **default-focused**". Handoff §2 already asks for `default_focus()` on Results; this
is the measurement that shows it is still outstanding, and it is now the only screen whose
initial focus is demonstrably the wrong control rather than merely unstated.

## 16. `project.godot` — two built-in actions are now restated, on purpose

Measured on 4.7.1: `InputMap.action_get_events("ui_accept")` and `("ui_cancel")` returned
**no joypad event** (only `ui_up`/`ui_left`/... ship `joy btn` and axis events), so
docs/13 §13.2's `A` and `B` rows were dead. Both actions are now declared in
project.godot with the engine's own keyboard events restated **exactly** plus the button:
`ui_accept` = Enter 4194309, KP Enter 4194310, Space 32, JOY_BUTTON_A; `ui_cancel` =
Escape 4194305, JOY_BUTTON_B. If you edit that section, keep the keyboard events —
`test_the_builtin_half_of_the_map_is_still_intact` is the tripwire.

Still unbound, and now stated in the file's own comment rather than only here: `LB`/`RB`
(focus group), `LT`/`RT` (previous/next subject), right stick (scroll). OQ-12 owns
whether they block 1.0.
