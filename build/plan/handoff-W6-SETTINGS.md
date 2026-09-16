# handoff-W6-SETTINGS — edits in files this unit does not own

Applied by the orchestrator at the wave's close (`python tools/apply_handoff.py build/plan/handoff-W6-SETTINGS.md --dry-run` parses it). Each edit is one heading. §1 and §2 are the two PLATE sites the `colourblind_safe` option should drive (text-tint sites stay on the reference ramp — `tests/unit/test_palette_cvd.gd` says why); §3 is the docs/13 §15.1 row that unlocks the switch under its own rule; §4 keeps the sheet runs from flashing a fullscreen window now that `project.godot` opens fullscreen.

## 1. game/screens/Roster.gd:742
The roster's morale histogram bars are plates, not text. Read the active ramp through the one door so the Options row's choice is what the roster draws. (W6-COPY owns Roster.gd this wave.)
old:
```
		bar.color = Palette.morale_color(band * 10 + 5)
```
new:
```
		bar.color = Palette.band_color_active(self, band * 10 + 5)
```

## 2. game/screens/RaiderDetail.gd:843
The morale sparkline's bars are plates. Hand `Widgets.sparkline` a band function that reads the option (its default is the static `morale_color`, which has no node to read a setting through). (W6-COPY owns RaiderDetail.gd this wave.)
old:
```
	var chart := Widgets.sparkline(values)
```
new:
```
	var chart := Widgets.sparkline(values,
		func(v: int) -> Color: return Palette.band_color_active(self, v))
```

## 3. docs/13-ui-ux.md:842
docs/13 §15.1's own rule ("if an option is not in this table, it does not exist in the settings screen") wants the row before the key; the key landed under the wave-10 ship rule (ship plan §6 #40, default off) and this is the row. The window-mode row gains the two values the screen offers. (W7-DOCS / the orchestrator owns docs/13.)
old:
```
| Resolution / window mode / vsync | Native, borderless | [14](14-technical-architecture.md) | Player | Global |
```
new:
```
| Resolution / window mode / vsync | Native, borderless (window mode: borderless fullscreen or a 3:2 window sized to the desktop; `F11` / `Alt+Enter` swap them) | [14](14-technical-architecture.md) | Player | Global |
| Colour-safe morale ramp (`colourblind_safe`) — §8.3's L*-ordered red → ochre → olive → teal on the morale plates | Off 🔷 (the reference concepts' red/amber/green stays the default until Q16 / M6-A11Y-06 is ruled; ship plan §6 #40) | §8.3, §13 | Player | Global |
```

## 4. docs/13-ui-ux.md:848
The paragraph under the table says CVD safety "ships on and has no off"; with the row above it is an option, and the sentence must say so (LESSONS: a comment that documents the absence of a gate changes when the gate lands).
old:
```
Same reasoning excludes the §13 items marked Yes/blocking: contrast, minimum text size and CVD safety ship on by default and have no "off".
```
new:
```
Same reasoning excludes the §13 items marked Yes/blocking: contrast and minimum text size ship on by default and have no "off". CVD safety is the exception, as an option (the row above): the reference concepts' ramp and §8.3's disagree in writing, so the §8.3 ramp ships behind `colourblind_safe`, default off, until the ruling.
```

## 5. tools/shot_all.sh:230
`project.godot` now opens the window fullscreen (`window/size/mode=3`, SHIP-06). The shot instrument captures a SubViewport and never the window, so the picture is unchanged — but every sheet row would flash a fullscreen window on the desktop for a second. Godot's `--windowed` (`-w`) keeps the harness window a window. (W6-SHEETS owns shot_all.sh this wave; the same flag is worth adding wherever else a non-headless `$GODOT` run is scripted — `tools/diff_all.sh` if it shoots, `tools/perf_probe.gd`'s caller in verify.sh.)
old:
```
    timeout 200 "$GODOT" --path . --script res://tools/shot.gd -- \
```
new:
```
    timeout 200 "$GODOT" -w --path . --script res://tools/shot.gd -- \
```

## 6. tools/diff_all.sh:84
Same as §5: the diff run shoots through shot.gd with a real window. (No wave-6 owner; the orchestrator applies.)
old:
```
  if ! timeout 150 "$GODOT" --path . --script res://tools/shot.gd -- \
```
new:
```
  if ! timeout 150 "$GODOT" -w --path . --script res://tools/shot.gd -- \
```

## 7. tools/verify.sh:322
Same as §5: the latency stage runs the perf probe with a real window (it needs a renderer). `-w` keeps it a window; the probe's SubViewport is unaffected. (W6-SIM-CASCADE owns verify.sh this wave — one flag on one line, outside the stage-6b block.)
old:
```
  OUT=$(timeout "$GODOT_PERF_TIMEOUT" "$GODOT" --path . --script res://tools/perf_probe.gd -- --warm 2>&1)
```
new:
```
  OUT=$(timeout "$GODOT_PERF_TIMEOUT" "$GODOT" -w --path . --script res://tools/perf_probe.gd -- --warm 2>&1)
```
