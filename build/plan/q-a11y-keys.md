# Proposed `docs/15-open-questions.md` entries — a11y-keys agent

Drafts for the orchestrator to merge; do not paste blind. Numbering is left blank because
another agent may be claiming the next free Q number. I did not edit docs/15.

---

## Q-__ — Does `Tab` step between focus GROUPS or between controls? *(PROPOSED — groups, with the convention behind a switch)*

**Owner:** [13 §13.1](./13-ui-ux.md) — **Signal:** Immediate, on the first keyboard pass
over any list screen

[13 §13.1](./13-ui-ux.md) gives two rows that only agree under one reading:

| `Tab` / `Shift+Tab` | Next / previous focus group (rail → list → detail → commit) |
| Arrows | Move within the focused group |

Read literally, `Tab` from the first rail item goes to the HEADER, not to the second rail
item, and the only way to reach the second rail item is an arrow. That is how a gamepad
works (§13.2 maps the same row onto `LB`/`RB`, with the D-pad moving inside the group) and
it is what the closing sentence of §13.1 describes. It is also **not** how any desktop
toolkit behaves: everywhere else `Tab` visits every focusable control in order, and a
keyboard user who cannot reach a control with `Tab` alone usually concludes it is
unreachable. Screen readers and Windows' own focus conventions assume the toolkit rule.

**Proposed decision: the doc wins by default, and the convention is one flag.**
Implemented in `game/ui/Frame.gd` as `static var tab_steps_within_region`, default
`false` = §13.1's group step; `true` gives the desktop convention, where `Tab` walks a
region's members and only the last one steps to the next region. Both are asserted
(`tests/unit/test_a11y.gd::test_tab_is_a_region_step_and_the_arrows_move_inside_the_region`,
`::test_the_other_reading_of_tab_is_available_behind_the_switch`), so flipping the default
is a one-line change with test coverage on both sides.

**What a person should rule on:** whether the shipped default stays the doc's. The
argument for flipping it is that §13's blocking requirement is *"Every screen operable
with no mouse"*, and a player who only knows `Tab` operates strictly more of the game
under the convention. The argument for keeping it is that §13.2's gamepad map is the same
model, and one model for both inputs is the reason §13.1 reads that way at all. If the
default flips, the arrows keep working either way — nothing else changes.

**Not an open question:** the ring wraps in both modes. §13.2's "it wraps, so there is no
dead end" is applied to the region ring and to each region's members.

---

## Q-__ — Does `Space` still press a focused Button, when §13.1 gives `Space` to Toggle? *(PROPOSED — yes, and Toggle is the same act on a row)*

**Owner:** [13 §13.1](./13-ui-ux.md) — **Signal:** Quiet; shows up as a double action or a
dead key on S10

[13 §13.1](./13-ui-ux.md) lists them as two rows: `Enter` is "Primary action on the focused
item" and `Space` is "Toggle — chalk/unchalk a raider, check/uncheck a filter". Godot's
built-in `ui_accept` carries **Enter, KP Enter and Space**, and a focused `Button` consumes
`ui_accept` in its own `_gui_input` — which runs BEFORE any screen's `_unhandled_input`.
So while a Button holds focus, a new `nav_toggle` action on `Space` never fires: the
button just presses.

Three ways out:

1. **Leave it (proposed).** On the surfaces §13.1 names, "press the focused row" and
   "toggle the focused row" are the same act: a bench raider's primary action IS chalk
   (§13.2 says exactly this — "Focus a bench raider, `X` to chalk into the first legal
   slot ... `X` again to unchalk"), and a checkbox's primary action IS check. `nav_toggle`
   then exists for the cases where the focused control is not itself the toggle.
2. **Remove `Space` from `ui_accept`** in project.godot. Clean separation, and it takes
   `Space` away from every Button in the game — including screens with no toggle at all,
   where a keyboard user reasonably expects `Space` to press.
3. **Handle `Space` in the control's own `_gui_input`** on the screens that need `Enter`
   and `Space` to differ (S10's bench, a detail panel where `Enter` opens and `Space`
   chalks). Most work, most faithful, and it can be done screen by screen.

**Proposed decision: (1) now, (3) where a screen actually needs the two to differ.** The
overlap is pinned by `tests/unit/test_a11y.gd::test_space_and_enter_stay_two_different_bindings`,
which asserts that `Enter` is NOT a toggle and that `ui_accept` still carries `Space` —
so if a later ruling picks (2), that assertion fails and points a reader back here rather
than letting the change land silently.

---

## Not a question, recorded for the reader: the focus ring's colour

[13 §12.3](./13-ui-ux.md) specifies "2px `brass.base` ring with a 1px `ink.body` outer
offset". `game/ui/Theme.gd::focus_ring()` ships 2px `edge.steel` (`#4982A2`) with no outer
offset, and says why at the call site: the art pass re-anchored the focus/selected role to
the colour sampled off the reference concepts
(`art/ref/specs/04-palette.md` §5: `accent.steel` — "Selection, focus ring, active state"),
which is the standing rule for hues, and it clears §13's 3:1 floor for UI boundaries at
4.7:1 on the panel ground. The 1px `ink.body` offset is the part that does not survive the
translation: on doc 13's light ground it is a dark separator, but this chrome's ink token
is a near-white (`#F7F1E1`), so 1px of it outside a steel ring reads as a glow. If a
person wants the offset back, the dark-chrome equivalent is `edge.rail` (`#262E35`) or
`surface.panel`, drawn as the stylebox's shadow (`shadow_color` + `shadow_size = 1`) —
one line in `focus_ring()`. **Caution:** `game/ui/Frame.gd` sets `clip_contents` on the
scene host, so an offset wider than the ring's 2px expand margin can be clipped at a
region's edge.

---

## Q-__ — Does `Start` open Settings from anywhere, or only from the town? *(PROPOSED — anywhere)*

[13 §13.2](./13-ui-ux.md)'s gamepad table gives `Start` the action "Settings (S15)" and
names its keyboard equivalent as "`Esc` from the town". Those are not the same rule: `Esc`
is contextual (it pops a level and only opens Settings when the town is the root), while
the `Start` row is written flat, with no condition.

**Proposed answer: flat, as written.** `ScreenRouter.settings()` pushes Settings from any
screen and is inert once Settings is on the desk; `B` / `Esc` is the way out, which §13.1
already guarantees. A controller has no `Esc` and no other route to the options, so making
`Start` contextual would leave a pad-only player unable to reach Settings from nine of the
eleven screens. If a person rules the other way, the change is one line — the guard
becomes `current_path() == TOWN_SCENE` — and
`test_the_gamepads_start_button_opens_settings` is where it is pinned.

## Not a question, recorded for the reader: `A` and `B` are ours now, not the engine's

Measured on Godot 4.7.1 in this project: `InputMap.action_get_events("ui_accept")` returned
three keyboard events and **no joypad button**, and `ui_cancel` returned one keyboard event
and no joypad button, while `ui_up` returned a key, `joy btn=11` and an axis event. So the
engine's built-in map covers §13.2's D-pad row but not its `A` and `B` rows, and a pad
could neither confirm nor cancel anything. `project.godot` now restates both actions —
the engine's own keyboard events, unchanged, plus `JOY_BUTTON_A` / `JOY_BUTTON_B`.

The consequence a later reader needs: those two actions are no longer engine defaults, so
Godot will not add events to them in a future version. If 4.8 ships a new default event on
`ui_accept`, this project will not get it. `test_the_builtin_half_of_the_map_is_still_intact`
asserts the keyboard half so the restatement cannot silently lose Enter, KP Enter or Esc.
