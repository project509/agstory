# handoff-W6-SHEETS

Edits this unit needs in files it does not own. Applied by the orchestrator at the wave's close
(`python tools/apply_handoff.py build/plan/handoff-W6-SHEETS.md --dry-run` parses it).

Context: UI-49's sweep. The `hover` sheet (`tools/shot_all.sh --sheet=hover`, five pinned sites) found
that only RaiderDetail's gear cells use the kit's two-line tooltip (`Widgets.tooltip_for`, KIT-22); the
Market's Sell-window buttons and worn-gear slots, the RaidView party cards' gear cells and the Tavern's
"arrives with" cells set a plain `tooltip_text`, which Godot renders as its one-line plate (274x34 /
158x34 on the sheet). §1-§4 convert those sites the way `Cards.gd:215-216` already does — the host laid
over the control, `tooltip_text` kept as the same words so every test and the a11y walk still read
them. `TooltipHost` is `MOUSE_FILTER_PASS` and `FOCUS_NONE` (Widgets.gd:334-340), so a press on the
Market button still reaches the Button. §5 is described, not an edit: W6-COPY is rewriting that block
this wave (UI-14). §6 is a finding for whoever owns Recruitment next (W6-LEDGER holds it this wave).

## 1. game/screens/Market.gd:711

The Sell window's item button (`_sell_row`; the `hover` sheet's Market row hovers it at 290,350).
Market.gd is a SPACES file.

old:
```
    b.tooltip_text = "%s — %s%s" % [it.name, Enums.slot_name_of(int(it.slot)),
        "" if worn_by.is_empty() else " — worn by %s" % worn_by]
```

new:
```
    # KIT-22 / UI-49's sweep (handoff-W6-SHEETS): the kit's two-line plate —
    # the item over its slot and wearer — with `tooltip_text` kept as the
    # same words for the tests and the a11y walk.
    Widgets.tooltip_for(b, String(it.name), "%s%s" % [Enums.slot_name_of(int(it.slot)),
        "" if worn_by.is_empty() else " — worn by %s" % worn_by])
    b.tooltip_text = "%s — %s%s" % [it.name, Enums.slot_name_of(int(it.slot)),
        "" if worn_by.is_empty() else " — worn by %s" % worn_by]
```

## 2. game/screens/Market.gd:794

The worn-gear shelf slot (`_item_slot`). SPACES.

old:
```
    s.tooltip_text = "%s — %s" % [it.name, Enums.slot_name_of(int(it.slot))]
    return s
```

new:
```
    # KIT-22 / UI-49's sweep (handoff-W6-SHEETS): the two-line plate.
    Widgets.tooltip_for(s, String(it.name), Enums.slot_name_of(int(it.slot)))
    s.tooltip_text = "%s — %s" % [it.name, Enums.slot_name_of(int(it.slot))]
    return s
```

## 3. game/screens/RaidView.gd:1093

The party card's gear cell (`_gear_cell`; the `hover` sheet's RaidView row hovers one at 176,908). An
empty cell keeps the one-line "Head — empty" plate: there is no item to put on a title line.
RaidView.gd is a TABS file.

old:
```
	cell.tooltip_text = ("%s — %s" % [Enums.slot_name_of(slot), String(item.name)]
		if item != null else "%s — empty" % Enums.slot_name_of(slot))
	return cell
```

new:
```
	cell.tooltip_text = ("%s — %s" % [Enums.slot_name_of(slot), String(item.name)]
		if item != null else "%s — empty" % Enums.slot_name_of(slot))
	if item != null:
		# KIT-22 / UI-49's sweep (handoff-W6-SHEETS): the kit's two-line plate
		# for a worn piece; `tooltip_text` re-set to the "slot — item" words
		# the tests read (tooltip_for writes "item — slot").
		Widgets.tooltip_for(cell, String(item.name), Enums.slot_name_of(slot))
		cell.tooltip_text = "%s — %s" % [Enums.slot_name_of(slot), String(item.name)]
	return cell
```

## 4. game/screens/Tavern.gd:630

The candidate card's "arrives with" cell (`_gear_slots`). Today this line never runs on any fixture —
see §6 — so the edit is for the day recruits are dressed. TABS.

old:
```
			var cell := Widgets.slot(Cards.gear_icon(int(it.slot), true, it), GEAR_CELL, "SlotMini")
			cell.tooltip_text = "%s — %s" % [Enums.slot_name_of(int(it.slot)), String(it.name)]
```

new:
```
			var cell := Widgets.slot(Cards.gear_icon(int(it.slot), true, it), GEAR_CELL, "SlotMini")
			# KIT-22 / UI-49's sweep (handoff-W6-SHEETS): the two-line plate;
			# `tooltip_text` kept as the "slot — item" words the tests read.
			Widgets.tooltip_for(cell, String(it.name), Enums.slot_name_of(int(it.slot)))
			cell.tooltip_text = "%s — %s" % [Enums.slot_name_of(int(it.slot)), String(it.name)]
```

## 5. game/screens/AdventureBoard.gd — the notice's "Potential Rewards" cells (described, no edit)

Not an edit apply_handoff.py can make: W6-COPY rewrites this block in the same wave (UI-14: exactly
`n` cells, "Nothing worth carrying." at zero, the charm family's icon for the trinket), so an anchor
against today's `:620-627` would not match at the close. What the `hover` sheet found: the reward
slot at 1197,375 (`Widgets.slot(Cards.loot_slot_icon(...))`) carries NO tooltip — `POPUP none` — the
only one of the five pinned sites with nothing to say. When the block is rewritten, each cell should
carry `Widgets.tooltip_for(cell, <the slot's name, e.g. Enums.slot_name_of(...) or "Trinket">,
"Potential reward")` (and `cell.tooltip_text` set to the same words) so the sheet's Board row shows a
plate. Owner at the close: whoever holds AdventureBoard.gd next (W6-COPY this wave).

## 6. Recruits arrive undressed — `Recruitment.gear_plan()` has no caller (finding, no edit)

`grep -rn "gear_plan" game/ sim/` finds only its definition (`sim/core/Recruitment.gd:182`). The
header above it says "every recruit arrives dressed" and `GEAR_RECIPES` gives a Common four starting
pieces, but `GameState.refresh_board()` -> `Recruitment.roll_board()` never asks for a plan or equips a
candidate, so every card in the Tavern reads "arrives with nothing anyone would call armour" and the
three "arrives with" cells are empty on every fixture (the `fixture`, `new` and `play` sheets all show
it). The seventh built-but-not-armed mechanism in LESSONS' count. Not this unit's file (Recruitment.gd
is W6-LEDGER's this wave, GameState.gd is hot); it needs a row in the queue or in BUILD_STATE's watch
list, and the Tavern hover row lights up the day it lands.
