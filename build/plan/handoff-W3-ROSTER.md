# handoff-W3-ROSTER — edits this unit needs in files it does not own

Shape: `## N. <path>:<line>` then an `old:` block and a `new:` block, one edit per heading; nothing here is
applied by the unit. Observations (no edit) are labelled as such.

## Observation (no edit) — W3-KIT2 / orchestrator: the tab row's height is the roster's fold

`Guildhall.gd` sizes each tab to `TAB_SIZE` (110x28) AFTER `Widgets.tabs_of()` and re-types the two shut
tabs' "Reason" Labels to `Type.STACK` on one line at 100% (wrapped at their 100% width above that). The
arithmetic behind it: the content panel's inner height is 596; two full card rows and the top of a third
(HALL-03's acceptance) need 541; so tab row + caption + rule + the column gap must fit in 55. A 32px tab
(`Widgets.TAB_MIN` as it stands in the working tree) or a 13px two-line caption takes the third row's top
away. Guildhall's `custom_minimum_size` after `tabs_of()` REPLACES the kit's min (it is the same property),
so the row stays 28 whatever `TAB_MIN` says; `tests/unit/test_roster_layout.gd ::
test_the_panel_leaves_room_for_two_full_rows_and_the_top_of_a_third` measures the row and says so.
Nothing to apply.

## Observation (no edit) — W3-KIT2: `Cards.card(actions)` and the 262 card

A card with a DISABLED "Cheer up" carries its reason Label in the band. Measured in
`test_the_panel_leaves_room_for_two_full_rows_and_the_top_of_a_third` (each Card's combined minimum
height must be <= 262). If that assertion is red after KIT2's Cards.gd lands, the band's reason is the
line that grew; the fix belongs in `Cards.card` (the band's `button_with_reason` box at separation 0,
or the reason at `Type.STACK`), not in Roster.gd.

## 1. game/screens/Guildhall.gd:528 (owner this wave: W3-ROSTER; apply AFTER W3-KIT2's Cards.gd lands)

The record wall's icons go through KIT2's `Cards.badge_icon("locked" | "earned" | "claimed")` once that
door exists (HALL-20's plan line); the `RECORD_ICON` table in this file is the interim, kept as the
fallback for a key the kit does not map. Rule 7: the door is KIT2's this wave, so it is not called yet.

old:
```
	var key: Array = RECORD_ICON.get(state, [])
	if key.size() == 2:
		t.texture = Icons.at(String(key[0]), String(key[1]))
```
new:
```
	t.texture = Cards.badge_icon(Achievements.state_name(state).to_lower())
	if t.texture == null:
		var key: Array = RECORD_ICON.get(state, [])
		if key.size() == 2:
			t.texture = Icons.at(String(key[0]), String(key[1]))
```

## 2. tools/with_godot_lock.sh:31 (owner: orchestrator / tooling)

Seen 23:15 on a W3-ROSTER probe run: `godot-lock: breaking stale lock (1789445756s old)`. The age is
computed as `now - (stat || 0)`: when the lock directory vanishes between the failed `mkdir` and the
`stat` (another agent released it in that instant), `stat` fails, the age becomes ~1.79e9 s and the
script `rm -rf`s whatever lock the NEXT agent may have just taken — the exact double-engine the mutex
exists to prevent. A failed `stat` means "the lock moved", not "the lock is ancient": retry instead.

old:
```
    age=$(( $(date +%s) - $(stat -c %Y "$LOCK" 2>/dev/null || echo 0) ))
    if [ "$age" -gt "$STALE_S" ]; then
```
new:
```
    mtime=$(stat -c %Y "$LOCK" 2>/dev/null || echo "")
    if [ -z "$mtime" ]; then
      sleep 1
      continue
    fi
    age=$(( $(date +%s) - mtime ))
    if [ "$age" -gt "$STALE_S" ]; then
```

## Observation (no edit) — W3-KIT2: the card's band line trims the state word

`Cards.card` (working tree) gives the "Class — State" line `text_overrun_behavior = OVERRUN_TRIM_ELLIPSIS`
for text_scale 150. At 100% it already trims Rhona's "Shaman — Slightly Annoyed" to "Shaman — Slightly
Annoy…" on the 215px card (build/shots/W3R_Guildhall.png, card 3 of row 1). docs/13 §8.1: the state word is
"never abbreviated"; §4.4: never truncate a state word at any scale — wrap (the Tavern's card wraps its
class line: report-W2-TAVERN judgement 2) or drop the class word before the band word. Not this unit's
file.
