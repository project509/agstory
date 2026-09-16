# handoff-W5-KIT3 — edits this unit needs in files it does not own

Shape: `## N. <path>:<line>` then an `old:` block and a `new:` block, one edit per heading; nothing here is
applied by the unit. Observations (no edit) are labelled as such. THIS UNIT OWES NO EDIT: every debt in its
contract was paid inside the kit, and the contract defers every screen's adoption ("adopts later"). The
observations below are the adoption recipes and one engine trap, for the units that own those files.

## Observation (no edit) — LESSONS.md (orchestrator): a `with_pips` font drawn at a size it was not built for corrupts every glyph of that size on the screen

Measured on the Guildhall at 125% (report-W5-KIT3.md, log 12:40-13:05). `Theme.gd` builds `LabelClass` on
`Fonts.with_pips(Fonts.ui(), 19, 125)` — the pip bar FontFile in front, a copy of Fira Sans Regular and the
30px face sheet behind. A Label drawing that variation with a `font_size` override of 16 rendered its own
letters overlapping AND every other 16px Fira Regular Label on the screen — the Rest panel's LabelSmall, the
event log's empty state, "+9 more" — with glyphs about 1.25x their advance (the 16px rasters had been made
at 20), while `get_string_size` at 16 measured correct headless before and after. At 100% the same override
(13 on the 15-built variation) rendered clean, and the Town at 125% (no override on any card) was clean.
The fix in `Cards.fit_band_line` is to shape the smaller rungs from the plain face (`Fonts.ui()`) and never
draw the variation at another size. Proposed entry: "A `with_pips` variation is drawn at the size it was
built for and no other: a `font_size` override on a LabelClass/LabelBody/LabelLog/LabelMorale Label at
125/150 corrupts that size's rasters for the whole screen. Override the font to the plain face with it."

## Observation (no edit) — game/screens/Guildhall.gd:310-316 (W5 owner of Guildhall): `tab_row` takes the tab minimum now

`Widgets.tab_row(labels, active, reasons, min_size := TAB_MIN)` — pass `TAB_SIZE` as the fourth argument and
drop the `b.custom_minimum_size = TAB_SIZE` line in the loop after `tabs_of()` (the `size_flags_horizontal`
line stays). test_kit3 `test_tab_row_takes_a_screens_own_minimum_and_keeps_tab_min_by_default` pins the
parameter; test_roster_layout's tab-row measurement is unchanged either way.

## Observation (no edit) — game/screens/Town.gd:496-500 (W5 owner of Town): the sidebar's event count

`Cards.recent_events(_state, 7)` and "%d recent event%s on the log." count seven where the log fits six
(`Cards.ROWS`, exposed this wave: (262 - 28 - 36 - 1) / 29 = 6). Replace the literal 7 with `Cards.ROWS`;
`Cards.event_log`'s own default is `ROWS` now, so the `7` in `Town.gd:534` (and Guildhall.gd:780/828,
Tavern.gd:430) can be dropped or left — the log caps at six either way.

## Observation (no edit) — game/screens/Facilities.gd:294-308 (W5 owner of Facilities): the picked tile's rim is a theme variation

`ButtonMiniPicked` (base `ButtonMini`; `pressed` and `hover_pressed` = the lit plate in the 2px
EDGE_READY_GOLD rim, the override at :307-308 verbatim; `normal`/`hover`/`disabled` = ButtonMini's). Set
`b.theme_type_variation = "ButtonMiniPicked"` on every tile (or only the chosen one) and delete the
`add_theme_stylebox_override("pressed", Theme_.flat(...))` block — the screen then builds no StyleBox.

## Observation (no edit) — game/screens/Settings.gd:530-556 and :403-411 (W5 owner of Settings)

`Widgets.pips(level, 100.0, VOLUME_STEPS.size() - 1)` is `_volume_control`'s strip verbatim: five 12x10
`Widgets.bar` pips at a 3px gap, `mana` tint, named "Pip20".."Pip100" (by threshold, so `Pip%d` readers keep
working), MOUSE_FILTER_IGNORE on the row and each pip. `Widgets.reasoned(ctrl, reason, lock, COL_NOTE_W,
"beside")` puts the reason on one row beside the control (an HBox "Row" as the box's only child); the option
row's move-into-the-note-column stays the screen's own choice — "beside" is to the RIGHT of the control,
and the control is the row's last column, so adopting it means the reason column moves too.

## Observation (no edit) — game/screens/LoadSave.gd:385-397 (W5 owner of LoadSave)

`_row_button` detaches the kit's "Reason" to print each phrase once under the row. `reasoned(b, reason,
lock, 0, "beside")` is the kit form when a reason may sit beside its button; the once-per-phrase row is
still the screen's, and `box.find_child("Reason", true, false)` finds the Label under "beside".

## Observation (no edit) — game/screens/Roster.gd:566-588 (W5 owner of Roster): `_fit_band` is a no-op now

The kit's card already sets the reason at `Type.STACK`, its box at separation 0 and the column at 2 for a
banded card (and takes the bottom pad to 7 when a reason is present); test_kit3
`test_rosters_interim_fit_band_is_a_no_op_on_the_kits_card` runs `_fit_band` on the kit's card and asserts
nothing changes. The function and its call at :552 can go whenever Roster is next edited.

## Observation (no edit) — tests/unit/test_text_scale_layout.gd (W5-SCALE): the Guildhall rows

The estimator's Guildhall findings at 125 ("They are fine." ending 10px past its cell) and 150 (the band's
"Cheer up" and the morale line wider than the cell) are the card at those scales: measured in-tree this wave
(scratchpad probe, real frames), the reasoned card's minimum is 277 at 125 (was 301 before this unit) and the
Roster's `row_height()` grows every row to it, so the reason sits inside the rim in the 125 shot
(build/shots/W5KIT3_Guildhall_t125.png). Nothing at 100 is reported for the Guildhall.
