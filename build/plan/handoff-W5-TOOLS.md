# handoff-W5-TOOLS — edits this unit needs in files it does not own

Unit: W5-TOOLS (tools/shot.gd, tools/shot_all.sh, tools/probe/Kit.gd, the dead crops, spec 09,
BUILD_STATE.md, BACKLOG.md, docs/_log/progress.md, tests/unit/test_build_state.gd, four audit rows).
Nothing below is applied by the unit. Shape: `## N. <path>:<line>` then an `old:` fenced block and a
`new:` fenced block, one edit per heading; `python tools/apply_handoff.py build/plan/handoff-W5-TOOLS.md
--dry-run` parses it. Line numbers are from the tree at the wave-5 start (2026-09-15); match by the
`old:` text.

## 1. art/ref/manifests/all.json:9445

The seven `badge_N` `ui_crop` rows (Concept 1's event-log badges, cut at 18x18) name files this unit
retires: `tools/probe/Kit.gd` was their only reader and now draws the icon grid's `log_<kind>` sprites
through `Cards.badge_icon` / `Widgets.log_row` (audit m4t-09). The rows must go BEFORE the files —
`tests/unit/test_art_sources.gd` asserts every row's `ships` path exists — and the manifest is not this
unit's file, so the deletion is here. After applying this edit, delete the seven files and their
`.import` siblings (apply_handoff.py cannot delete files):

    rm -f game/assets/ui/icons/badge_{0,1,2,3,4,5,6}.png game/assets/ui/icons/badge_{0,1,2,3,4,5,6}.png.import

test_art_sources.gd's two row-count floors were lowered in-wave (57 -> 50 rows, 45 -> 38 reproducible)
so the test is green both before and after this lands. The seven entries are contiguous; removing them
whole leaves the JSON valid (checked with json.loads on the result).

old:
```
  {
   "sheet": "ideaboard/Reference Concepts/Reference Concept 1.png",
   "section": "Concept 1 / event log",
   "index": 0,
   "x": 1070,
   "y": 786,
   "w": 18,
   "h": 18,
   "proposed_name": "badge_0",
   "category": "ui_crop",
   "note": "log-row event badge 0 (Cards.badge_icon); W1-ICONS retires the numbering for log_<kind>",
   "ships": "game/assets/ui/icons/badge_0.png"
  },
  {
   "sheet": "ideaboard/Reference Concepts/Reference Concept 1.png",
   "section": "Concept 1 / event log",
   "index": 1,
   "x": 1070,
   "y": 815,
   "w": 18,
   "h": 18,
   "proposed_name": "badge_1",
   "category": "ui_crop",
   "note": "log-row event badge 1 (Cards.badge_icon); W1-ICONS retires the numbering for log_<kind>",
   "ships": "game/assets/ui/icons/badge_1.png"
  },
  {
   "sheet": "ideaboard/Reference Concepts/Reference Concept 1.png",
   "section": "Concept 1 / event log",
   "index": 2,
   "x": 1070,
   "y": 843,
   "w": 18,
   "h": 18,
   "proposed_name": "badge_2",
   "category": "ui_crop",
   "note": "log-row event badge 2 (Cards.badge_icon); W1-ICONS retires the numbering for log_<kind>",
   "ships": "game/assets/ui/icons/badge_2.png"
  },
  {
   "sheet": "ideaboard/Reference Concepts/Reference Concept 1.png",
   "section": "Concept 1 / event log",
   "index": 3,
   "x": 1070,
   "y": 872,
   "w": 18,
   "h": 18,
   "proposed_name": "badge_3",
   "category": "ui_crop",
   "note": "log-row event badge 3 (Cards.badge_icon); W1-ICONS retires the numbering for log_<kind>",
   "ships": "game/assets/ui/icons/badge_3.png"
  },
  {
   "sheet": "ideaboard/Reference Concepts/Reference Concept 1.png",
   "section": "Concept 1 / event log",
   "index": 4,
   "x": 1070,
   "y": 901,
   "w": 18,
   "h": 18,
   "proposed_name": "badge_4",
   "category": "ui_crop",
   "note": "log-row event badge 4 (Cards.badge_icon); W1-ICONS retires the numbering for log_<kind>",
   "ships": "game/assets/ui/icons/badge_4.png"
  },
  {
   "sheet": "ideaboard/Reference Concepts/Reference Concept 1.png",
   "section": "Concept 1 / event log",
   "index": 5,
   "x": 1070,
   "y": 929,
   "w": 18,
   "h": 18,
   "proposed_name": "badge_5",
   "category": "ui_crop",
   "note": "log-row event badge 5 (Cards.badge_icon); W1-ICONS retires the numbering for log_<kind>",
   "ships": "game/assets/ui/icons/badge_5.png"
  },
  {
   "sheet": "ideaboard/Reference Concepts/Reference Concept 1.png",
   "section": "Concept 1 / event log",
   "index": 6,
   "x": 1070,
   "y": 958,
   "w": 18,
   "h": 18,
   "proposed_name": "badge_6",
   "category": "ui_crop",
   "note": "log-row event badge 6 (Cards.badge_icon); W1-ICONS retires the numbering for log_<kind>",
   "ships": "game/assets/ui/icons/badge_6.png"
  },
```

new:
```
```

## 2. game/ui/Widgets.gd:381

FOUND BY THE NEW INSTRUMENT. The first tooltip ever shot (`RaiderDetail --fixture --hover=584,167`,
build/shots/w5tools/RaiderDetail_hover.png) came up as a 180x571 PopupPanel: the two lines are right,
the plate under them runs 571px down the screen. Cause, proven with a scratch probe (a PopupPanel given
`build_tooltip()`'s VBox printed `contents_min=(180, 571)`; the same VBox with its Labels pre-sized
printed `(180, 56)`): Godot sizes the tooltip Window from `get_contents_minimum_size()` BEFORE any
layout pass, and an autowrap Label that has never been laid out is 0 wide, so `_shape()` breaks every
grapheme onto its own line and reports that as its minimum height. The VBox's `custom_minimum_size.x`
caps the width but does not reach the Labels. Not visible in a test (they read the Labels, not the
Window) and not visible in-game until someone hovers a slot — it is the real tooltip's size in play.
Widgets.gd is a tab file.

old:
```
		v.custom_minimum_size = Vector2(minf(widest + 2.0, float(TOOLTIP_W)), 0)
		return v
```

new:
```
		v.custom_minimum_size = Vector2(minf(widest + 2.0, float(TOOLTIP_W)), 0)
		# Pre-size the Labels to that width: Godot reads the tooltip Window's
		# size off get_contents_minimum_size() before any layout pass, and an
		# autowrap Label still 0 wide breaks every grapheme onto its own line —
		# the two-line tooltip came out 180x571 the first time one was shot
		# (W5-TOOLS `--hover`; probe: 571 -> 56 with this loop).
		for c in v.get_children():
			if c is Label:
				(c as Label).size = Vector2(v.custom_minimum_size.x, 0)
		return v
```

## 3. game/assets/bg/arena_stage.png

Not an edit — a deletion apply_handoff.py cannot make (this heading carries no old/new block and the
parser skips it). `arena_stage.png` is the fourth dead mockup crop audit M4B-CONV-02 names; the other
three (`arena_plate`, `menu_plate`, `tavern_plate`) were in W5-TOOLS's file list and are deleted, this
one was not. Nothing loads it: `grep -rn arena_stage game tools tests` -> two history comments
(game/screens/RaidView.gd:436, game/ui/Cards.gd:795), no manifest row, no test pin. After this:

    rm -f game/assets/bg/arena_stage.png game/assets/bg/arena_stage.png.import

then M4B-CONV-02 (left `partial` with exactly this as its remaining_work) can be closed.

## 4. build/plan/artaudit/00-plan.md:26

The §0.3 grammar block is not this unit's file; the flag list there is what every later unit cites.

old:
```
#                --hold-boot               (mount Boot.tscn and stop before the router's goto)
```

new:
```
#                --hold-boot               (mount Boot.tscn and stop before the router's goto)
#  W5-TOOLS adds: --hover=x,y               (a pointer at that shot pixel after every other action: hover
#                                            styles, mouse_entered, and Godot's tooltip, embedded and grounded;
#                                            prints HOVER/POPUP lines; exit 13 when nothing is under it)
```
