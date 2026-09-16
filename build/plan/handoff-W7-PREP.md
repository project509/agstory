# handoff-W7-PREP

Edits this unit needs in files it does not own (wave-7 ownership table, `build/plan/ship/00-plan.md` §2). Applied by the orchestrator at the wave's close. Nothing in `game/screens/RaidPrep.gd` calls anything listed here — every entry is a later convenience, not a dependency.

`game/ui/SceneStage.gd` is TABS and W7-STAGE's this wave. Line numbers as read on 2026-09-15.

## 1. game/ui/SceneStage.gd:809 — `remove_actor(spr)`, the door RaidPrep's `_clear_party` reaches through today

UI-16: RaidPrep re-places the chalked party on every `_refresh` and has to take the old figures off first. `add_actor` appends to the private `_actors`, which `apply_settings` walks (`spr.stop()` on a freed sprite would throw), so `RaidPrep._clear_party` removes the sprite and its `Shadow_` sibling itself and erases the sprite from `stage.get("_actors")` — a private-member poke across a file boundary. This gives the stage the verb, so the next screen that needs it (Results' settled fight, W8-SCALE-1) does not repeat the poke. RaidPrep is NOT changed in this wave (same-wave isolation); a later wave may switch `_clear_party` to `_stage.remove_actor(spr)` and drop the `get("_actors")` scrub.

old:
```
## Whether docs/13 §13's reduced-motion switch has already been applied. A
## screen that resumes a figure's animation itself has to ask, or it would undo
## the setting for exactly the figures it added.
func motion_held() -> bool:
```
new:
```
## Take a figure `add_actor` built off the stage: the sprite, the contact
## shadow `add_actor` put directly before it, and its place in `_actors`, so
## a later `apply_settings` never meets a freed object. A screen that
## re-places a party (RaidPrep on every chalk) uses this rather than freeing
## the nodes itself. Safe on a sprite that is already gone.
func remove_actor(spr: Node) -> void:
	if spr == null or not is_instance_valid(spr):
		return
	_actors.erase(spr)
	var i: int = spr.get_index()
	if spr.get_parent() == self and i > 0:
		var shadow: Node = get_child(i - 1)
		if String(shadow.name).begins_with("Shadow_"):
			remove_child(shadow)
			shadow.queue_free()
	if spr.get_parent() == self:
		remove_child(spr)
	spr.queue_free()


## Whether docs/13 §13's reduced-motion switch has already been applied. A
## screen that resumes a figure's animation itself has to ask, or it would undo
## the setting for exactly the figures it added.
func motion_held() -> bool:
```

## Notes — no edit proposed, for the units that own the file (not parsed by apply_handoff.py)

- **The cave's rank pitch is W7-STAGE's, and RaidPrep follows it live.** `RaidPrep._party_layout()`
  reads `SceneStage.marks("stage_arena_cave")` on every `_refresh`, so whatever UI-21's "party spread"
  sets for `marks.party` (the plan's 84px across / 40px rank pitch) is what the prep band shows. At the
  marks as they stand on 2026-09-15 (38px rank pitch, `figure_scale` 2) the twelve figures overlap into
  one mass on `--fixture` — visible in `build/shots/W7PREP_RaidPrep.png`. No change is asked for here:
  W7-STAGE's own acceptance ("the twelve figures read as twelve") covers it, and the prep band inherits
  the fix with no RaidPrep edit.
- **The boss is deliberately absent from the prep band.** `Cards.encounter_sprite` at `marks.boss`
  (x 1210) lands under the readout column once `RaidPrep.arena_view()` shifts the band, so the optional
  boss was left out (contract: "if it fights the reviewer's look, leave the boss out"). If UI-22 moves
  the boss mark's x in front of the fence line, a later wave may revisit; nothing here depends on it.
- **150% on RaidPrep with a STOCKED cupboard clips the loadout line** (five icon buttons wrap to one
  per row). Pre-existing and unrelated to the icons — the bare-cupboard 150% test still passes. It is
  W8-SCALE-1's "150% on Results and RaidPrep" row.
