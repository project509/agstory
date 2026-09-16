# Handoff — audio (M6-AUD-03 / M6-AUD-04)

The `Audio` autoload is live (`game/core/Audio.gd`), the four buses exist
(`default_bus_layout.tres`), and all ten sampled hooks from docs/13 §12.4 load.
Four hooks are already bound from files I own; the rest need one-line edits in
files I do not.

**How to reach the autoload from anywhere**, including a `static func`:

```gdscript
const Services = preload("res://game/core/Services.gd")
...
var audio := Services.find(self, "Audio")     # or Services.find(null, "Audio")
if audio != null:
    audio.play("ui.stamp")
```

`Services.find` accepts a null `who` and falls back to the main loop's root, so
a static helper can use it. Never write the bare global `Audio` — BUILD_STATE
invariant 7. Every hook name below is checked against `Audio.HOOKS`, and an
unknown name is a `push_error`, so a typo fails loudly.

## Already bound — nothing owed

| Hook | Where | How |
|---|---|---|
| `ui.tab` | `Audio._connect_router` | Subscribes `ScreenRouter.screen_changed`. No screen learns about audio |
| `ui.coin` | `Audio._connect_state` | Subscribes `GameState.gold_changed` (declared at `GameState.gd:68` all along, so the audit's "add the signal" was already done) **plus a guard**, because the signal has FOUR emit sites and two of them are not a gold change. GameState *does* still owe one edit — **§0 below** |
| `ui.silence` | `Audio.play("ui.silence")` → `duck(-60.0, 0.4)` | Implemented; needs its caller, below |
| `ui.chalk`, `ui.chalk_bad`, `ui.stamp`, `ui.blot`, `ui.seal`, `ui.row_select` | — | Samples load and the names resolve; callers below |

---

## 0. `game/core/GameState.gd` — the fourth `gold_changed` emit (CORRECTION)

**An earlier version of this handoff said GameState needed no edit, and gave
three emit sites as proof. There are four.** `gold_changed` fires from
`add_gold` (:609), `spend_gold` (:618), `new_game` (:532) **and `from_dict`
(:2376)** — the tail of the save-restore path, right after `active = true;
_ensure_router_connected()`. So loading a save rang the 135 ms coin chime, and
so did starting a new game. docs/13 §12.4's trigger is "Gold changes / On the
value write"; a restore is not a gold change.

`game/core/Audio.gd` now guards this on its own side (`_coin_note`) and the
chime is honest today, so **this edit is an improvement, not a blocker**. It
replaces a four-fact heuristic with one fact, and it belongs here because only
GameState knows which of its own writes is which.

`GameState.gd` indents with **FOUR SPACES**.

**old** (beside the other campaign fields, ~:305 where `active` is declared):

```gdscript
var active: bool = false
```

**new**:

```gdscript
var active: bool = false
## True only while `new_game` / `from_dict` are announcing a campaign that has
## just appeared. `gold_changed` fires from four places and two of them are
## this — a whole state arriving, not a transaction — and a listener cannot
## tell them apart from the payload, which is only the new total. docs/13
## §12.4 binds a sound to "Gold changes / On the value write", and a coin
## chime over the load screen is a sound the player did not cause. A flag
## rather than a second signal because every gold label in game/screens/
## already depends on `gold_changed`'s shape.
var announcing: bool = false
```

then wrap **both** arrival emits. In `new_game`:

**old** (`:532`):

```gdscript
    gold_changed.emit(gold)
    roster_changed.emit()
```

**new**:

```gdscript
    announcing = true
    gold_changed.emit(gold)
    announcing = false
    roster_changed.emit()
```

and in `from_dict` (`:2376`), the identical change — note it sits just before
`return problems`:

**old**:

```gdscript
    gold_changed.emit(gold)
    roster_changed.emit()
    return problems
```

**new**:

```gdscript
    announcing = true
    gold_changed.emit(gold)
    announcing = false
    roster_changed.emit()
    return problems
```

⚠️ Signals are synchronous in Godot, so `announcing` is true for exactly the
duration of the emit and no listener can observe it out of scope. Nothing else
should read it.

**What lands with it, in files I own** (do NOT apply this half — tell me, or
leave it: the guard is correct without it, just wordier):

- `Audio._on_gold_changed` gains one early return,
  `if _state != null and bool(_state.announcing): return`, and the seed / day /
  roster-head half of `_coin_note` can then go.
- `tests/unit/test_audio.gd :: test_a_campaign_arriving_does_not_ring_the_coin`
  is the test that changes: it can then drive the real `new_game` /
  `from_dict` instead of the decision function.

---

## 1. `game/screens/RaidView.gd` — `ui.stamp`, `ui.blot`, `ui.silence`

### 1a. The stamp and the blot, in `_append_line`

docs/13 §12.4: `ui.stamp` on "`StampBadge` land — **the mistake sound**",
*"Exactly on frame 1 of the press. Must never be late"*; `ui.blot` "With the
stamp, one layer under it". So both fire **before** the row is built, not after.

Add the preload beside the file's other consts (this file indents with **TABS**):

```gdscript
const Services = preload("res://game/core/Services.gd")
```

(If `Services` is already preloaded there, skip it.)

**old** (`game/screens/RaidView.gd`, in `_append_line`):

```gdscript
	var is_mistake: bool = e.is_mistake()
	if is_mistake:
		_mistakes_seen += 1
		if _mistake_counter != null:
			_mistake_counter.text = "Mistakes this attempt  %d" % _mistakes_seen
```

**new**:

```gdscript
	var is_mistake: bool = e.is_mistake()
	if is_mistake:
		# docs/13 §12.4: the stamp is "the mistake sound", "exactly on frame 1
		# of the press. Must never be late" — so it fires HERE, before the row
		# is built, not after the tree work. The blot goes with it, "one layer
		# under it": the SAMPLE is rendered 12 dB down (gen_sfx.py's PARAMS,
		# -26 against the stamp's -14 dBFS), because Audio plays both at
		# volume_db 0.0 and there is no mix trim to lean on.
		var audio = Services.find(self, "Audio")
		if audio != null:
			audio.play("ui.stamp")
			audio.play("ui.blot")
		_mistakes_seen += 1
		if _mistake_counter != null:
			_mistake_counter.text = "Mistakes this attempt  %d" % _mistakes_seen
```

### 1b. `ui.silence` at the wipe, t=0

docs/13 §12.4: `ui.silence` fires at "Wipe, t=0" and "Ducks all buses to −60dB
for 400ms". In this file t=0 for the wipe sequence is the `_finished_ui`
transition in `_process` — the frame the account stops and the sequence starts,
not the later `_show_wipe_stamp()`.

**old** (`game/screens/RaidView.gd`, in `_process`):

```gdscript
	# docs/13 §11.4's wipe sequence, once the account has stopped.
	if not _finished_ui:
		_finished_ui = true
		_wipe_timer = 0.0
```

**new**:

```gdscript
	# docs/13 §11.4's wipe sequence, once the account has stopped.
	if not _finished_ui:
		_finished_ui = true
		_wipe_timer = 0.0
		# docs/13 §12.4: `ui.silence` at "Wipe, t=0". This transition IS t=0 —
		# the frame the sequence starts, not the frame the stamp lands. Audio
		# implements it as duck(-60, 0.4), so it is a mixer move and there is
		# no sample to be late.
		if _is_wipe():
			var audio = Services.find(self, "Audio")
			if audio != null:
				audio.play("ui.silence")
```

---

## 2. `game/ui/Widgets.gd` — `ui.seal`

docs/13 §12.4: `ui.seal` on "Any `WaxButton` commit", **"On press, not
release"**. So connect `button_down`, NOT `pressed` — `pressed` is release.

This file's commit control is `cta()` (the CTA plate) and `wax_button()`
("Kept: the old name for the commit control"). Both should seal. This file
indents with **TABS** and its functions are `static`, so use
`Services.find(null, "Audio")`.

Add beside the other consts:

```gdscript
const Services = preload("res://game/core/Services.gd")
```

Add one helper:

```gdscript
## docs/13 §12.4: `ui.seal` fires on "Any `WaxButton` commit", "On press, not
## release" — hence `button_down` and never `pressed`, which is release. Bound
## here rather than at each call site so no screen has to remember to seal.
static func _bind_seal(b: Button) -> void:
	b.button_down.connect(func() -> void:
		var audio = Services.find(null, "Audio")
		if audio != null:
			audio.play("ui.seal"))
```

Then in **`cta()`**, both return paths:

**old**:

```gdscript
	b.custom_minimum_size = Vector2(0, 70)
	if subline.is_empty():
		return b
```

**new**:

```gdscript
	b.custom_minimum_size = Vector2(0, 70)
	_bind_seal(b)
	if subline.is_empty():
		return b
```

and in **`wax_button()`**:

**old**:

```gdscript
static func wax_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = "ButtonCta"
	return b
```

**new**:

```gdscript
static func wax_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = "ButtonCta"
	_bind_seal(b)
	return b
```

**Test-contract note:** `button_down` is a *different* signal from `pressed`.
Screen tests press buttons with `b.pressed.emit()`, which does **not** fire
`button_down`, so this binding is invisible to the existing suite and cannot
break it. A test that wants to assert the seal must emit `button_down`.

---

## 3. `game/screens/RaidPrep.gd` — `ui.chalk`, `ui.chalk_bad`

This file indents with **FOUR SPACES**. docs/13 §12.4: `ui.chalk` on "ChalkSlot
fill / clear" at the "leading edge of the stroke" — one hook for both
directions; `ui.chalk_bad` when the "Comp check turns invalid", 60 ms after the
slot redraw.

`_toggle` (RaidPrep.gd:404) is the fill/clear path. Note its early `return`
when the party is full: nothing was chalked, so nothing should sound.

**old**:

```gdscript
func _toggle(raider_id: String) -> void:
    if _is_chalked_id(raider_id):
        for i in _chalked.size():
            if _chalked[i].id == raider_id:
                _chalked.remove_at(i)
                break
    else:
        if _chalked.size() >= _party_cap():
            return
        var r = _state.raider(raider_id) if _state != null else null
        if r != null:
            _chalked.append(r)
    _refresh()
```

**new**:

```gdscript
func _toggle(raider_id: String) -> void:
    if _is_chalked_id(raider_id):
        for i in _chalked.size():
            if _chalked[i].id == raider_id:
                _chalked.remove_at(i)
                break
    else:
        if _chalked.size() >= _party_cap():
            # The party is full: nothing was chalked, so nothing sounds.
            return
        var r = _state.raider(raider_id) if _state != null else null
        if r != null:
            _chalked.append(r)
    # docs/13 §12.4: one hook for "ChalkSlot fill / clear", on the "leading
    # edge of the stroke" — before the refresh, not after it.
    var audio = Services.find(self, "Audio")
    if audio != null:
        audio.play("ui.chalk")
    _refresh()
    _check_comp_turned_bad()
```

and add, plus a `var _comp_was_valid := true` beside the other state vars:

```gdscript
## docs/13 §12.4's `ui.chalk_bad`: "Comp check turns invalid", 60 ms after the
## slot redraw. TURNS is the operative word — it fires on the transition, not
## on every press while the comp is already short, or the hook becomes a nag.
##
## Validity here is docs/06's two hard requirements as RaidPlan.analyse reports
## them: the slots are filled and the tank weight is met. The healer count is
## "recommended", not required, and is deliberately not part of this.
func _check_comp_turned_bad() -> void:
    var db = _state.content if _state != null else null
    var a := RaidPlan.analyse(_chalked, db, _encounter)
    var valid: bool = (int(a["slots_filled"]) >= int(a["slots_required"])
        and float(a["tank_weight"]) >= float(a["tanks_required"]))
    if _comp_was_valid and not valid:
        # docs/13 §12.4 syncs this hook "60 ms after the slot redraw". The
        # lateness is the CALLER'S: the sample's onset is immediate (3 ms
        # attack, and _finish() ramps only its first 24 samples), which
        # tools/audio/gen_sfx.py:194 says in as many words. So the wait has to
        # be here, and this is the only hook in §12.4 that has one.
        _play_chalk_bad_after_the_redraw()
    _comp_was_valid = valid


## The 60 ms of §12.4's sync column, spent where it belongs. A SceneTreeTimer is
## refcounted rather than a node, and this fires on the valid -> invalid
## TRANSITION only, so it is one timer per mistake and not one per press.
func _play_chalk_bad_after_the_redraw() -> void:
    await get_tree().create_timer(0.060).timeout
    # The screen can be gone after 60 ms — a chalk sound for a slot board that
    # is no longer on the desk is worse than a missed one.
    if not is_inside_tree():
        return
    var audio = Services.find(self, "Audio")
    if audio != null:
        audio.play("ui.chalk_bad")
```

⚠️ **`_toggle` must stay synchronous.** The `await` lives in its own function
and is deliberately not awaited by the caller — an `await` inside `_toggle`
or `_check_comp_turned_bad` would make the chalk sound, the refresh and the
return late as well, and §12.4 wants only this one hook late. (An unawaited
coroutine call is fire-and-forget in Godot 4; if this project's warning set
flags it, keep the behaviour and silence the warning rather than adding an
`await` to the caller.)

**Test-contract note:** a screen test that presses its way to an invalid comp
will see `ui.chalk` immediately and `ui.chalk_bad` only after the frame the
timer resolves on, which a `--script` run never reaches. Assert on
`_comp_was_valid` flipping, or on `Audio.tape` after an explicit
`await get_tree().create_timer(0.07).timeout` in a test that has a frame loop.
Do not assert the chime synchronously — it is documented as late.

⚠️ **Verify before applying:** I did not run this. `RaidPlan.analyse` is
already called in `_build_readout` with exactly these arguments, so the call
shape is right, but calling it a second time per press is extra work; if that
matters, hoist the analysis `_refresh` already performs and pass it in. Also
confirm `RaidPlan` and `Services` are preloaded in that file.

---

## 4. `ui.row_select` — DELIBERATELY NOT BOUND, and why

docs/13 §12.4 triggers it on "Row select", synced to "the brass bar wipe".
I could not find a row-selection model with a brass bar wipe anywhere in
`game/screens/`. The sample exists (`ui_row_select_1/2.wav`) and the name
resolves, so binding it is a one-liner **once there is a real row select** —
but a hook fired on a row *hover*, or on a row's action button, is not the
thing the doc describes. Left unbound rather than bound to the wrong gesture.
Whoever owns the roster/board row model should bind it.

## 5. `ui.page_turn`, `ui.ledger_close` — NOT BOUND, waiting on JUICE-02

§12.4 syncs them to "Start of the turn" and "Start of the close". Neither
animation exists. Both samples are rendered and both names resolve, so the
binding is one line each when the animations land. Firing them on a hard cut
would be worse than silence.

---

## 6. `tools/build_art.sh` — the `--audio` flag (M6-AUD-03)

The generator must not run on the default incremental path (the art pass owns
that). Add a flag near the top of the argument handling:

```bash
if [ "${1:-}" = "--audio" ]; then
  # docs/13 §12.4's one-shots. Deliberately NOT part of the default run: the
  # samples are committed and deterministic, so re-rendering them on every art
  # build would only churn mtimes. tools/audio/README.md has the models.
  python tools/audio/gen_sfx.py
  # New assets need an import pass before Godot resolves them.
  tools/with_godot_lock.sh "$GODOT" --headless --path . --import
  exit 0
fi
```

Adjust to that file's actual arg parsing — I did not read it (not my file).

---

## 7. Documentation cross-references (M6-AUD-06)

I wrote the proposals to `build/plan/q-audio.md` (two entries, **Q-96** and
**Q-97**) and did not edit `docs/`. Whoever owns the doc set:

- Add **Q-96** (audio direction and its ownership) and **Q-97** (are the rank
  beds composed, licensed or cut?) to `docs/15-open-questions.md`'s numbered
  table. The numbered decisions currently end at Q-95.
- Make the **unnumbered** "Audio and music" row in docs/15 §8
  (`docs/15-open-questions.md:593`) point at Q-96 and Q-97, so the ownership
  gap names its own resolution.
- Cross-reference Q-96 from docs/13 §12.4, which currently hands eleven names
  to "audio's call" with no anchor.
- `BUILD_STATE.md`: there are now **four** autoloads, not three
  (`GameState`, `ScreenRouter`, `GameSettings`, `Audio`).
- `docs/14 §4`'s directory tree lists `game/autoload/audio.gd`. The file
  shipped as `game/core/Audio.gd`, beside the other three autoloads —
  `game/autoload/` is not this repo's layout. Either fix the tree or note it.
- `BACKLOG.md:167` ("Generate procedurally or source CC0") is now answered:
  generated, `tools/audio/gen_sfx.py`.
