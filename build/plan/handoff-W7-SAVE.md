# handoff-W7-SAVE

Edits W7-SAVE needs in files it does not own. Apply with `python tools/apply_handoff.py build/plan/handoff-W7-SAVE.md`.

The third thing this unit owes — the wave's "v17 BL row" for `docs/15-open-questions.md` — is NOT an edit heading here, because a proposed docs/15 row goes to `build/plan/q-<KEY>.md` when the unit does not own docs/15 (00-plan §0.3). It is written out, heading, status cell and body, in **`build/plan/q-W7-SAVE.md`**, for W7-DOCS or the orchestrator to land at the next free `BL-` number. An exact-anchor edit against docs/15 would not have survived the wave anyway: W7-DOCS is rewriting that file around BL-110..BL-143 as this is written.

Both edits below are AUDIO-10's other half, into W7-AUD-AMB's files (`game/core/Audio.gd`, `tests/unit/test_audio.gd`) — the plan names them: "`handoff-W7-SAVE.md` §1 carries Audio's early return and the retargeted `test_a_campaign_arriving_does_not_ring_the_coin` into W7-AUD-AMB's file". The GameState half landed in-wave: `GameState.announcing` is true for the whole of `new_game()` and `from_dict()` and false everywhere else, so Audio no longer has to infer which of the four `gold_changed` emit sites it is hearing. The heuristic is NOT deleted — it still holds for a save loaded by something that never sets the flag, and it is still what keeps the watermark current — the flag is simply believed first.

## 1. game/core/Audio.gd:592
The coin's guard reads the flag instead of inferring the emit site (SPACES). The anchor starts at the stale paragraph of the docstring — the fix it says "belongs in GameState" has landed, and a comment that documents the absence of a gate has to change when the gate lands (LESSONS). `_coin_note()` is still called on every write, so the watermark stays current and a reward one frame after the campaign arrives still rings.
old:
```
## The payload is only the new total, so the emitting site cannot be read off
## the signal. THE FIX BELONGS IN GameState and is written out line-for-line in
## build/plan/handoff-audio.md §0 (a `restoring` flag around the two arrival
## emits); this guard is what keeps the chime honest until that lands, and the
## test that will have to change is named there.
##
## Until then the coin rings only when the total moved AND the campaign under
## it is the one Audio last heard from: same guild seed, same object at the head
## of the roster, and the day has not run backwards. Both arrival sites call
## `reset()` (:499) first and rebuild the roster from scratch, so both always
## fail that test; neither `add_gold` nor `spend_gold` touches the seed, the day
## or the roster, so neither ever does. It depends on GameState emitting
## `gold_changed` BEFORE `roster_changed` at both arrival sites, which is the
## order it has and which is why the real fix belongs over there.
func _on_gold_changed(amount: int) -> void:
    var seed_now: int = 0
    var day_now: int = 0
    if _state != null:
        seed_now = int(_state.guild_seed)
        day_now = int(_state.day)
    if _coin_note(amount, seed_now, day_now, _roster_head()):
        play("ui.coin")
```
new:
```
## The payload is only the new total, so the emitting site cannot be read off
## the signal — which is why this used to be a heuristic. It is not any more:
## `GameState.announcing` (AUDIO-10, W7-SAVE) is true for the whole of
## `new_game()` and `from_dict()` and false everywhere else, so the state SAYS
## which of the four emits this is and the coin believes it.
##
## The watermark is still recorded on every write, and the heuristic behind it
## still stands as the second line: the coin rings only when the total moved AND
## the campaign under it is the one Audio last heard from — same guild seed, same
## object at the head of the roster, the day not run backwards. Both arrival
## sites call `reset()` (:499) first and rebuild the roster from scratch, so both
## fail that test too; neither `add_gold` nor `spend_gold` touches the seed, the
## day or the roster, so neither ever does. A reward one frame after a campaign
## arrives still rings, because the flag is false by then.
func _on_gold_changed(amount: int) -> void:
    var seed_now: int = 0
    var day_now: int = 0
    var arriving: bool = false
    if _state != null:
        seed_now = int(_state.guild_seed)
        day_now = int(_state.day)
        arriving = bool(_state.announcing)
    var moved: bool = _coin_note(amount, seed_now, day_now, _roster_head())
    if moved and not arriving:
        play("ui.coin")
```

## 2. tests/unit/test_audio.gd:611
`test_a_campaign_arriving_does_not_ring_the_coin` retargeted at the flag (SPACES). The `_coin_note` walk is kept verbatim — it is the second line of defence and still true — and the flag's own path is added underneath it, driven through the real handler with a stand-in state, so what is asserted is the thing the player hears rather than the helper's return value.
old:
```
    assert_true(a._coin_note(1300, 777, 9, 900003), "then play resumes")
    assert_false(a._coin_note(1400, 777, 4, 900003),
        "day 4 arriving after day 9 is a load, whatever the roster says")
```
new:
```
    assert_true(a._coin_note(1300, 777, 9, 900003), "then play resumes")
    assert_false(a._coin_note(1400, 777, 4, 900003),
        "day 4 arriving after day 9 is a load, whatever the roster says")

    # AUDIO-10, landed: the state now SAYS which emit this is, so the handler is
    # driven directly. `announcing` is true for the whole of `new_game()` and
    # `from_dict()` (GameState, W7-SAVE) and false everywhere else.
    var was_state = a._state
    var stand_in := _AnnouncingState.new()
    a._state = stand_in
    a.tape = []
    stand_in.announcing = true
    a._on_gold_changed(500)
    assert_eq(a.tape.size(), 0, "a campaign announcing itself does not ring")
    stand_in.announcing = false
    a._on_gold_changed(560)
    assert_eq(a.tape.size(), 1, "and the first real change after it does")
    a._state = was_state


## The two fields `_on_gold_changed` reads off the state, and the flag under test.
class _AnnouncingState extends RefCounted:
    var guild_seed: int = 777
    var day: int = 9
    var announcing: bool = false
```
