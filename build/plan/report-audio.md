# Report — audio (M6-AUD-01, -02, -03, -04, -06)

Items: **M6-AUD-01** (bus layout + autoload), **-02** (the four dead settings
keys), **-03** (procedural SFX generator), **-04** (bind the hooks), **-06**
(the docs/15 record). **M6-AUD-05 was deliberately not done** — see the last
section.

Suite: **0 failures in `test_audio.gd` or `test_settings.gd`.** Baseline was
1117; the first pass added **43** (35 in `tests/unit/test_audio.gd`, 8 appended
to `tests/unit/test_settings.gd`) and the repair pass at the end of this report
added **5 more** (40 in `test_audio.gd` now), so **48** in total. Parse check
green. Last full run: **1/1265 failing**, and that one is another agent's
in-flight file (`test_adventures.gd`) — I touched nothing under `sim/`, and
nothing in `game/screens/` in the repair pass at all.

⚠️ **Read the "Repair pass" section at the end before trusting anything in the
middle of this report.** A reviewer found four real defects, including a doc
quotation this report fabricated and repeated. Every claim it corrects is
marked in place.

---

## What I found

The audit was accurate about the hole: `grep AudioStreamPlayer` returned
nothing, `find -name '*.wav'` returned nothing, `project.godot` had no
`[audio]` section and three autoloads. `game/screens/Settings.gd:79` carried
the confession `"reason": "There is no audio yet."`.

**Two auditor claims turned out wrong, one materially:**

1. **M6-AUD-04 item (f) is half wrong, and my first account of it was also
   wrong — see the repair pass.** The audit says to "emit a `gold_changed`
   signal from GameState and let Audio subscribe". The signal was already
   there: `GameState.gd:68` has declared `signal gold_changed(amount: int)` all
   along. But **subscribing is not the whole binding**, which is what I got
   wrong: the signal is emitted from **four** places, not the three I listed —
   `add_gold` (:609), `spend_gold` (:618), `new_game` (:532) **and `from_dict`
   (:2376)**, the tail of the save-restore path. Only the first two are a gold
   change. `ui.coin` is bound in this pass (`Audio.gd`, `_connect_state` and
   `_on_gold_changed`) **with a guard**, and GameState still owes the one-flag
   edit in `build/plan/handoff-audio.md` §0.
2. **M6-AUD-01's plumbing assumption is wrong about `_ready`.** The audit
   assumed the autoload's `_ready` would run and only worried about *ordering*.
   Under `--script` an autoload's `_ready` **does not run at all**: the test
   runner is itself the `SceneTree`, owns the root, and quits inside
   `_initialize()` without flushing a frame, so the autoload nodes exist with
   none of their callbacks fired. I proved this with a throwaway probe test
   (`_pool.size() == 0`, `_settings == null`, and `GameSettings._values`
   holding 4 keys instead of 19 — so *its* `_ready` had not run either). Fixed
   with the codebase's own established answer: an idempotent `ensure_wired()`
   called from `_ready` and from every public entry point, exactly the shape of
   `GameState._ensure_router_connected` (`GameState.gd:383`), whose comment
   already documents half of this trap.

Also: my task brief proposed buses **Master / Music / SFX / UI**. The docs do
specify, and they say something different — docs/13 §15.1's row is
*"Audio bus levels (master / music / UI / voice-of-the-scribe) | 100 / 80 / 80
/ 100"*, and `GameSettings.AUDIO_BUSES` already agreed with it. **There is no
SFX bus.** A fifth bus would be a level in the mixer that nothing in §15.1's
closed inventory could move, so I followed the doc and the four existing keys.
Flagging it because it is a deliberate divergence from the brief.

---

## What I built

### M6-AUD-01 — the mixer and the autoload

| File | What |
|---|---|
| `default_bus_layout.tres` (new) | Master / Music / UI / Voice in §15.1's order; Music, UI and Voice send to Master; all at 0 dB, because the layout is the **topology** and `settings.cfg` is the **level** |
| `project.godot:24` | `Audio="*res://game/core/Audio.gd"` — the fourth autoload, registered after GameSettings |
| `project.godot:26-32` | `[audio] buses/default_bus_layout="res://default_bus_layout.tres"`, stated explicitly rather than left implicit so a reader can see the game has a mixer |

**Path divergence, flagged:** the audit asked for
`game/assets/audio/bus_layout.tres`; my brief's file list said
`default_bus_layout.tres` at the repo root. I used the root, because that is
where Godot's own mixer panel writes when a human edits the buses in the
editor — putting it elsewhere means an editor edit silently creates a second
layout. `project.godot` names it either way.

`game/core/Audio.gd` (462 lines, **four-space** indent to match `game/core/`):

- `const BUSES` (:41), `const BUS_FOR_KEY` (:46) — the key to bus map is
  written out rather than derived from the key name, because stripping
  `audio_` and capitalising gets `UI` wrong and a mixer key that misses its
  bus is invisible.
- `const HOOKS` (:69) — docs/13 §12.4's eleven names in the doc's row order,
  each with `bus`, `streams` (resource **paths**; a `const` cannot hold a
  loaded resource) and `pitch_jitter_semitones`.
- `ensure_wired()` (:161) — idempotent boot, above.
- `_ensure_buses()` (:218) — recreates a missing bus rather than letting every
  `play()` route to bus -1 in a stripped export.
- `apply_levels()` (:233) / `_apply_key()` (:239) / `level_db()` (:259).
- `duck()` (:284), `_process` (:295), `_unduck()` (:304), `advance_duck()`
  (:314, test seam), `is_ducked()` (:322).
- `play()` (:332) — unknown hook is a `push_error`; empty `streams` is a legal
  no-op; round-robin over variants; ±2 semitone jitter for `ui.stamp` only.
- `_build_pool()` (:389) — a ring of 8 `AudioStreamPlayer` per bus (32 total),
  allocated once, because §12.4 says the stamp "fires dozens of times per raid".
- `play_bed()` (:454) / `stop_bed()` (:459) — **deliberate no-ops** with the
  reason on them.

One subtlety worth recording: `AudioStreamPlayer.play()` **refuses** outside
the scene tree ("Playback can only happen when a node is inside the scene
tree"), and under `--script` this autoload's children are not in a tree. That
logged 11 engine errors per test run. `play()` now sets the stream and the
pitch and then skips only the driver call when `not player.is_inside_tree()`
(`Audio.gd:363-370`) — so a test can still see what *would* have played, and
the run is clean. Verified: **0 occurrences** of that error in the final run.

### M6-AUD-02 — the four settings keys now move four buses

`game/core/GameSettings.gd` **needed no change**. It already declared the four
keys with §15.1's defaults (100/80/80/100), already clamped them 0-100, and
already had `const AUDIO_BUSES` in the doc's order. It is in my file list; I
read it and left it alone.

`game/screens/Settings.gd` (**tabs**, matched):

- `:87-94` — the single disabled `audio_master` row is replaced by **four**
  live rows in §15.1's order: "Audio — master", "Audio — music",
  "Audio — interface", "Audio — voice of the scribe", each `"reason": ""`.
  The other three keys previously had **no row at all**, so the screen was
  quietly narrower than the closed list it claims to render.
- `:285-286` — the `_control_for` match now sends all four keys to
  `_volume_button`.
- `:344` `const VOLUME_STEPS := [0, 20, 40, 60, 80, 100]`, `:347`
  `_volume_button`, `:361` `_next_volume`.
- `:55-62` — the ROWS docstring now explains the audio rows, per M6-AUD-06.

**Deliberate divergence from the audit:** it proposed a 0/25/50/75/100 ladder.
I used **20% steps** instead, because a 25% ladder makes §15.1's own default of
**80** unreachable from the screen that owns it. `_next_volume` is written as a
search for the next step strictly above the current value (wrapping to 0), so a
stored value off the ladder — a hand-edited `settings.cfg` — still steps
somewhere sensible instead of snapping to silence.

The control is a `Button` whose text is the integer, per the test contract; a
slider would be an option no screen test could see.

### M6-AUD-03 — the samples, generated

`tools/audio/gen_sfx.py` (434 lines, numpy + stdlib `wave`, no new dependency,
nothing downloaded) writes 17 files / **257 kB** to `game/assets/audio/sfx/`.

The constraint is docs/13 §12.4: *"All UI sound is material: paper, chalk,
brass, wax, coin. No synthesized blips."* That rules out the obvious
implementation, so nothing here is an oscillator playing a note:

- **paper / chalk** — band-limited noise gated by a random-walk *stick-slip*
  grain (`stick_slip`, :112). Chalk on slate catches and releases hundreds of
  times a second; a flat noise burst is a hiss, a gated one has grit.
- **brass / coin / wax** — banks of exponentially damped sinusoids at
  **inharmonic** ratios (`struck`, :127). A struck disc's modes are Bessel
  zeros; harmonic partials are exactly what makes a tone sound synthetic.
- **mass on a desk** — low-passed noise plus one low damped sine.

Filtering is an FFT mask with a raised-cosine skirt (`band`, :77) so no `scipy`
is needed; the skirt is load-bearing, because a brick-wall mask rings and
ringing is the artefact §12.4 forbids. Output is **deterministic** — each
variant seeds its own `Generator` from `sha256("<hook>:<index>")`, verified by
re-rendering and diffing md5s — so a re-run does not churn the repo.

`PARAMS` (:189) is the single dict of every number, per the audit's own
mitigation, and `tools/audio/README.md` records the model, the length, the
level and the take count for each of the eleven hooks in a table.

Doc-traced facts: `ui.stamp` is **3 variants at 125 ms** (§12.4: "<= 140ms,
three round-robin variants") with a 4 ms contact tick that starts on sample 0,
so the sound *cannot* be late. `ui.page_turn` (380 ms) and `ui.ledger_close`
(430 ms) are the only two that run long, and each now fits inside the motion
§12.2 gives it (700 / 900 ms) — **`ui.seal` was a third at 155 ms when this
report first claimed otherwise; it is 138 ms now.** `ui.blot` is the quietest
thing in the set (-26 dBFS) because §12.4 puts it "with the stamp, one layer
under it" — that 12 dB is in the SAMPLE, not in a mix trim; `play()` sets
`volume_db` to 0.0 for both. `ui.silence` has **no sample** — it is
`duck(-60.0, 0.4)`.

`pitch_jitter_semitones` is **2.0 for `ui.stamp` and 0.0 for every other
hook**, because §12.4 specifies a jitter for the stamp and only the stamp.
Giving another hook one would be inventing a number.

New assets were imported through the mutex
(`with_godot_lock.sh "$GODOT" --headless --path . --import`).

### M6-AUD-04 — the bindings

**Bound in this pass, in files I own:**

| Hook | Binding |
|---|---|
| `ui.tab` | `Audio._connect_router` (:190) subscribes `ScreenRouter.screen_changed`. No screen learns about audio |
| `ui.coin` | `Audio._connect_state` (:205) subscribes the **already existing** `GameState.gold_changed`. §12.4's "On the value write" is literally where that signal fires |
| `ui.silence` | `play("ui.silence")` performs `duck(-60.0, 0.4)` (:284). Implementation complete; its one caller is in RaidView |

**Handed off** (exact old-to-new in `build/plan/handoff-audio.md`):
`ui.stamp` + `ui.blot` in `RaidView._append_line`; `ui.silence`'s call at
RaidView's `_finished_ui` transition (wipe t=0); `ui.seal` on `button_down`
(**not** `pressed`, which is release) in `Widgets.cta` and `Widgets.wax_button`;
`ui.chalk` + `ui.chalk_bad` in `RaidPrep._toggle`; the `--audio` flag for
`tools/build_art.sh`; and the doc cross-references.

### M6-AUD-06 — the record

`build/plan/q-audio.md` proposes **two** numbered entries for docs/15 (whose
numbered decisions currently end at Q-95): **Q-96** — the audio direction and
what "audio's call" means when nobody owns audio, whose ruling is what
AUD-01..04 actually implement; **Q-97** — are the per-rank beds and the
Legendary leitmotif composed, licensed CC0, or cut? I did **not** edit
`docs/15-open-questions.md` (house rule 1).

---

## The tests, and what each asserts

`tests/unit/test_audio.gd` — 35 tests (new file, four-space indent).
`before_each` calls `Audio.ensure_wired()`, because the game's `_ready` boot is
the one thing a `--script` test has to do by hand; `after_each` restores the
four settings values, clears the duck and re-applies the levels.

*The mixer (6):* the autoload is registered; `project.godot` names the layout
and the file exists; the layout text names exactly Master/Music/UI/Voice at
indices 0-3 **and has no `bus/4`**; all four buses are live on `AudioServer`
after boot with Master at index 0; every non-Master bus sends to Master;
`BUS_FOR_KEY` and `GameSettings.AUDIO_BUSES` are the same list.

*The four keys move the buses (5):* each key moves **its own** bus to
`linear_to_db(0.5)` and leaves the other three at unity; a `set_value` reaches
the mixer with **no** explicit `apply_levels()` (the `changed` subscription);
0 **mutes** rather than trusting `linear_to_db(0.0)` (-inf, which Godot clamps
to -80 dB, audible) and any level above 0 unmutes; §15.1's 100/80/80/100 land
as the matching dB; a key outside the four is refused.

*The hooks (9):* the table is **exactly** §12.4's eleven, in both directions;
an unknown hook plays nothing (and `push_error`s); every named sample resolves
via `ResourceLoader.exists`; every hook but `ui.silence` loaded at least one
stream, and `ui.silence` loaded none; **no `.wav` in the repo is an orphan**
and every hook's sample is on disk; `ui.stamp` has 3 variants, jitter 2.0, and
every variant's `get_length()` is <= 0.140 s; only `ui.page_turn` and
`ui.ledger_close` exceed 160 ms; **only** `ui.stamp` carries a pitch jitter;
every hook's bus exists, and UI sound is on the UI bus (Master for `ui.silence`).

*Headless safety (3) — the important ones:* playing all eleven hooks records
eleven plays and completes in **under 1 s** (if any call threw or waited on a
driver the whole suite would go with it); 50 `ui.stamp` presses add **zero**
child nodes and the pool is exactly 8 x 4; the round-robin actually reaches
all three stamp variants.

*`ui.silence` / the duck (4):* it is a duck with -60 dB / 0.4 s and no sample;
the duck lowers Master 60 dB and `advance_duck` gives it back; the duck **rides
on top of** the player's own master level (a player at 50% ends the wipe at 50%,
not at unity by accident); a zero-length duck is a restore, not a permanent dip.

*The bindings (3):* `ScreenRouter.screen_changed` is connected to Audio, so no
screen owns the tab sound; `GameState.gold_changed` is connected and emitting
it plays exactly one `ui.coin`; **nothing under `sim/` mentions `AudioServer`,
`AudioStreamPlayer` or `"Audio"`** — a directory walk, enforcing BUILD_STATE
invariant 2 and docs/14:123.

*No music (1):* `play_bed` over all six rank ids plus `""` records nothing and
leaves every Music-bus player with a null stream. **This is the tripwire that
has to change when a human owner delivers stems.**

*The generator (3):* the generator and its README ship with the samples and the
generator accounts for all eleven hook names; every sample is 44.1 kHz **mono**;
no sample loops (docs/13 §12.2: "Nothing in the UI loops, pulses, or breathes").

`tests/unit/test_settings.gd` — 8 appended: every bus key in the inventory has
a row on the screen; the four audio rows stand in §15.1's order; no audio row
still carries the stale "There is no audio yet."; the ladder keeps **both**
documented defaults (80, 100) and 0 reachable; `_next_volume` walks up, wraps
100 to 0, and handles a value off the ladder; all four volume controls are
Buttons showing four **distinct** values (proving each row reads its own key
rather than four rows reading master); pressing the music row's "40" button
makes it 60 and leaves master at 100; and the row **reaches the mixer**, not
just the config file — `set_value("audio_ui", 20)` moves `level_db("audio_ui")`
to `linear_to_db(0.2)`. That last one is the whole point of the item — a row in
docs/13 §15.1's closed inventory that moves the mixer rather than only the
config file. (It is **not** a docs/13 §7 quotation; see the correction under
"Repair pass" at the end of this report.)

---

## Doc sections relied on

- **docs/13 §12.4** — the eleven hook names, their triggers and sync column;
  "All UI sound is material: paper, chalk, brass, wax, coin. No synthesized
  blips"; `ui.stamp`'s "<= 140ms, three round-robin variants, ±2 semitone
  random pitch"; `ui.silence` = "Ducks all buses to -60dB for 400ms";
  `ui.seal` "On press, not release"; `ui.blot` "one layer under it".
- **docs/13 §15.1** — the four buses (master / music / UI / voice-of-the-scribe)
  and their defaults 100 / 80 / 80 / 100; the closed-list rule; `settings.cfg`.
- **docs/13 §12.2** — the MOTION table: "Nothing in the UI loops, pulses, or
  breathes"; the departure page turn (700 ms) and the day advance (900 ms) as
  the two indulgent moments; log-line arrival at 90 ms. Its "Everything else is
  under 140ms" is a bound on **animation duration**, not on sample length —
  see the correction under "Repair pass".
- **docs/13 §7 / §12.3** — a disabled control states its reason ("reason text
  beneath — never a mystery"; "A disabled control that does not say why is a
  dead end"). **Neither section says anything about a lying toggle or about
  volume** — that sentence is `game/screens/Settings.gd`'s own header prose and
  an earlier draft of this report quoted it as the doc's. See "Repair pass".
- **docs/02 §9.1** — the per-rank Audio column, i.e. the melodic work I did not do.
- **docs/15 §8** — the unnumbered "Audio and music" ownership gap.
- **docs/14 §4 / :123** — `audio.gd` in the tree (shipped as `game/core/Audio.gd`
  instead; `game/autoload/` is not this repo's layout — flagged in the handoff);
  the event layer emits "no tween, sound, or particle".
- **`art/ref/specs/06-ui-component-kit.md` §7** ("Inset/well · secondary + icon
  buttons · text links") — the reference kit has no slider or switch, so a
  value cycles on press (the pattern `_volume_button` follows). This is the
  ART spec, not `docs/06-classes-and-roles.md`, whose §7 is "Class availability
  ❓ OPEN"; the bare `06 §7` in the code comment is this repo's established
  shorthand for the art spec (Theme.gd:170/240/247, Widgets.gd:124/191), but
  writing it as `docs/06 §7` here promoted it into the design doc set, which
  was wrong.

---

## What I deliberately did NOT do

1. **No music. M6-AUD-05 stays blocked.** `play_bed()` and `stop_bed()` are
   no-ops with the reason written on them (`Audio.gd:438-459`). docs/02 §9.1's
   rank beds — the sparse lute, the drum, the Renowned bell toll, the Legendary
   cheer stinger, and above all the leitmotif — are authored melodic work. A
   leitmotif has to be *recognisable*; procedural generation yields something
   technically music and audibly not a theme, and shipping that is worse than
   shipping silence. Decision recorded as proposed **Q-97**.
2. **No ambience generator (`gen_amb.py`).** This is the generable half of
   AUD-05 and I could have written it — the wind/murmur/anvil loops are
   filtered noise, not melody. I did not, for two reasons: AUD-05 is not one of
   my items, and its consumer (`game/screens/Town.gd`, keyed off
   `_state.reputation_rank`) is not my file, so I would be committing ~200 kB
   of assets that nothing loads. Flagged in `tools/audio/README.md` and Q-97.
   **This is a real gap**, not a judgement that it should not exist.
3. **`ui.row_select` is not bound.** §12.4 triggers it on "Row select", synced
   to "the brass bar wipe". I could not find a row-selection model with a brass
   bar wipe anywhere in `game/screens/`. The sample exists and the name
   resolves; binding it to a row *hover* or to a row's action button would be
   binding it to the wrong gesture. Left for whoever owns the row model.
4. **`ui.page_turn` and `ui.ledger_close` are not bound.** Their samples are
   rendered and their names resolve, but §12.4 syncs them to "start of the
   turn" and "start of the close" and neither animation exists (JUICE-02).
   Firing them on a hard cut would be worse than silence.
5. **No edits to `docs/`, `BUILD_STATE.md`, `BACKLOG.md`,
   `tools/build_art.sh`, `RaidView.gd`, `RaidPrep.gd`, `Widgets.gd`,
   `Town.gd`, `test_screens.gd`** — not my files. Everything owed is in
   `build/plan/handoff-audio.md` with exact old-to-new.
6. **The `--audio` flag for `tools/build_art.sh` is a handoff, not an edit.**
   `tools/audio/` is mine; `tools/build_art.sh` is not.
7. **`GameSettings.gd` was read and left unchanged.** It already had everything
   AUD-02 needed. Reporting this so "no diff" is not mistaken for "not done".
8. **No test asserts audible output.** Headless has a dummy driver. The tests
   assert the mixer's state, the hook table, the files on disk, and that
   nothing crashes or blocks — never that a sound was heard.

## Honest risks

- **`ui.stamp`'s fatigue is unverified, and it is the thing most likely to be
  wrong.** §12.4 makes "never fatiguing" a requirement, and that is a taste
  judgement a build loop cannot self-check. The measurable constraints are met
  (125 ms, three variants, ±2 semitones, -14 dBFS peak, faded ends so it cannot
  click). The subjective one needs a human with headphones and a raid running.
  The mitigation is in place: every parameter is one dict in `gen_sfx.py` and
  every model is written down in `tools/audio/README.md`, so re-tuning is an
  edit and a re-render, not a re-derivation.
- **"Material, not blips" is likewise unverified by ear.** I checked spectral
  centroids and envelopes, not aesthetics. `ui.seal` sits at ~780 Hz (low, soft,
  wax-like) and `ui.coin` at ~5 kHz (bright, disc-like), which is at least the
  right *direction*, but that is not the same as sounding good.
- **`RaidPrep`'s `ui.chalk_bad` handoff is unrun code.** I wrote it against the
  file's real shape (`_toggle` at :404, `RaidPlan.analyse` as `_build_readout`
  already calls it) but I could not execute it, and it adds a second `analyse`
  call per press. Marked with a verify-before-applying note in the handoff.
- **`project.godot` is shared.** The a11y agent added an `[input]` section to it
  mid-pass. Both sets of edits coexist in the file as it stands; I checked
  after their write and did not revert anything.

---

# Repair pass — the four reviewer findings, and what changed

A reviewer read this subsystem and found four defects. All four were real.
Nothing below is disputed, and everything in it was verified rather than
asserted.

## 1. A fabricated doc quotation, in four places — fixed

*"A lying toggle is the one thing worse than a missing one"* is
`game/screens/Settings.gd`'s **own header prose** (`git show
HEAD:game/screens/Settings.gd`, line 8), written by an earlier pass as its own
sentence next to a docs/13 §7 citation. This pass re-quoted it as **the doc's
words**. It is not in the doc set. I re-read §7: it is the Widget kit parts
table, and what it actually says about a disabled control is the `WaxButton`
row's "disabled (grey wax, reason text beneath — never a mystery)"; the general
rule lives in **§12.3** ("a reason string adjacent. A disabled control that
does not say why is a dead end"). Neither section mentions a toggle, a lie, or
volume. A code comment laundered into a doc quotation is exactly the failure
house rule 1 exists to stop.

Corrected in all four places, with the correction itself written down so the
next reader sees the history rather than a silently better sentence:

| Where | What it says now |
|---|---|
| `game/core/Audio.gd` (header) | Quotes §12.3 and §7 for what they do say, and states plainly that the lying-toggle judgement is `Settings.gd`'s sentence, "not a doc's — no section of docs/13 says it, and it must not be quoted as though one did" |
| `tests/unit/test_settings.gd` (`..._reach_the_mixer_and_not_just_the_config_file`) | Cites §15.1 for the row existing and §12.3 for the disabled case, and says the enabled-row judgement is the screen's own |
| `tests/unit/test_settings.gd` (`..._cannot_honour_says_why`) | Keeps §7's "never a mystery", attributes the rest to the screen |
| `build/plan/q-audio.md` | Carries a **Correction** blockquote naming all four occurrences |
| this report (twice) | The mixer sentence, and the "Doc sections relied on" entry |

**Also corrected in "Doc sections relied on":** it cited "**docs/06 §7** — no
slider/switch". `docs/06-classes-and-roles.md` §7 is "Class availability
❓ OPEN" and the word "slider" appears nowhere in `docs/`. The kit with no
slider is `art/ref/specs/06-ui-component-kit.md` §7 ("Inset/well · secondary +
icon buttons · text links"). The bare `06 §7` in the *code* comment is this
repo's established shorthand for that art spec (`Theme.gd:170/240/247`,
`Widgets.gd:124/191`) and stands; writing it as `docs/06 §7` in a report
promoted an art spec into the design doc set, and that was wrong.

## 2. `ui.seal` was 155 ms and the test was set to 160 to let it through — fixed

`test_only_the_two_indulgent_hooks_run_long` quoted §12.2's "Everything else is
under 140ms" in its own comment and then asserted `<= 0.160`. Measured: every
sample but one is at or under 140 ms, and `ui_seal.wav` was **0.1550 s**
(`PARAMS["ui.seal"]["ms"] = 155`). The 0.160 traced to no doc section; it
existed so that one file would pass.

Both halves are fixed:

- **The sample came down.** `ui.seal` is now **138 ms** (`gen_sfx.py`,
  re-rendered and re-imported through the mutex). 138 and not 140 so the
  assertion never compares a float32 sample length against its own bound; that
  2 ms is stated as rounding clearance, not as a length allowance. The ring's
  slowest partial has τ 60 ms, so it is 20 dB down by 138 ms and `_finish()`'s
  6 ms out-fade covers the rest.
- **The test stopped mis-citing the doc.** §12.2 is the **motion** table —
  which is why the 700 ms page turn and the 900 ms ledger close are in it — so
  it is not a source for sample lengths at all. docs/13 gives a sample length
  to exactly one hook: §12.4's stamp, "≤ 140ms". The old test is now two:
  - `test_the_two_indulgent_hooks_fit_inside_their_own_motions` — each long
    sample must end before the motion §12.4 syncs it to (380 ≤ 700,
    430 ≤ 900). Both bounds are the doc's own numbers.
  - `test_every_other_hook_stays_inside_the_stamps_140ms` — 15 samples, bound
    140 ms, with the comment stating outright that extending the stamp's
    ceiling to the other nine hooks is a **house choice**, that §12.2 is not
    its source, and what the 0.160 was.
- `tools/audio/README.md` gained a "Where the lengths come from, and where they
  do not" note saying the same, and its `ui.seal` row records the change.

Re-rendered to a scratch directory first and md5'd against the tree: **16 of 17
samples byte-identical**, `ui_seal.wav` the only one that moved. Determinism
holds.

## 3. `ui.coin` fired on save-load, and my account of the emit sites was short one

Confirmed. `gold_changed` is emitted from **four** places, not the three this
report and the handoff both offered as proof that "subscribing IS the binding":
`add_gold` (:609), `spend_gold` (:618), `new_game` (:532) and **`from_dict`
(:2376)**, immediately after `active = true; _ensure_router_connected()` in the
function that returns `problems`. So restoring a save rang the 135 ms coin
chime, `new_game` did too, and `add_gold(0)` dinged for a write that changed
nothing. docs/13 §12.4's trigger is "Gold changes / On the value write" — a
restore is not a gold change.

The payload is only the new total, so **the emitting site cannot be read off
the signal**, and `GameState.gd` is not my file. So:

- **`Audio._on_gold_changed` now rings only for a gold CHANGE inside the
  campaign it last heard from** — `_coin_note(amount, seed, day, roster_head)`.
  A campaign arrival always runs `reset()` (:499) first and rebuilds the
  roster, so it always brings a new guild seed and a new object at the head of
  the roster; `add_gold`/`spend_gold` touch none of the three. The day is
  checked for running **backwards**, which is what an older save is.
  `roster_changed` is subscribed for exactly one reason: it keeps the watermark
  current, so a hire or a departure does not cost the *next* real gold change
  its chime.
- **The correct fix is one flag in GameState**, written out line-for-line as
  `build/plan/handoff-audio.md` **§0** — an `announcing` bool set around the
  two arrival emits, collapsing four facts to one. The handoff names the test
  that changes when it lands, and says explicitly that the guard is correct
  without it so nobody rushes it.
- **Known residue, disclosed:** the guard depends on GameState emitting
  `gold_changed` *before* `roster_changed` at both arrival sites (the order it
  has today). If a future edit swapped them a restore would ring again — which
  is the other reason the real fix belongs over there.

Tests — the reviewer's missing one, plus what it took to make it bite:

- `test_a_campaign_arriving_does_not_ring_the_coin` — walks a campaign arriving
  (silent), a reward (rings), a no-op write (silent), a **quickload of the same
  campaign on the same day with different gold** (silent; this is the case the
  old test could not see), a different campaign loading (silent), and a day
  arriving out of order (silent). It drives `_coin_note` directly, because
  `new_game`/`from_dict` on the autoload need a content database to build a
  real roster from and would leave the shared campaign other screen tests
  mount against in pieces.
- `test_the_coin_follows_the_gold_signal_that_already_existed` — rewritten from
  "the signal is connected and one emit records one play" to the real thing: a
  same-total write is silent, `add_gold(7)` rings once, `add_gold(0)` is
  silent, `spend_gold(7)` rings, and the purse ends where it started.
- `test_a_hire_or_a_departure_does_not_cost_the_next_chime` — the other half of
  the guard, and the whole reason `roster_changed` is subscribed.

## 4. The handoff told the next agent something false about `ui.chalk_bad` — fixed

The worst of the four, because the handoff is the artifact another agent pastes
**verbatim**. §3 pasted a comment claiming "the sample carries §12.4's own 60ms
lateness in its envelope". It does not: `PARAMS["ui.chalk_bad"]` is
`attack_ms 3.0 / tau_ms 48.0` and `_finish()` ramps only the first 24 samples
(~0.5 ms), so the onset is immediate. `tools/audio/gen_sfx.py:194` and
`tools/audio/README.md` both say the opposite, and say it correctly — "§12.4
fires it 60 ms after the slot redraws, so the lateness is the **caller's**, not
the sample's". Net effect of the wrong one: §12.4's only delayed hook was
documented as done and implemented nowhere.

The handoff now hands over a real implementation of it: a
`_play_chalk_bad_after_the_redraw()` that awaits
`get_tree().create_timer(0.060).timeout`, checks `is_inside_tree()` before
playing (60 ms is long enough for the board to leave the desk), and is called
without `await` so `_toggle` stays synchronous. A `SceneTreeTimer` is
refcounted rather than a node, and it is created on the valid→invalid
**transition** only — one timer per mistake, not one per press, which is the
objection the false comment was reaching for. The test-contract consequence
(the chime is deliberately late, so a `--script` test cannot assert it
synchronously) is written down beside it.

Also corrected in the handoff: §1a told the next agent that "Audio's own mix
keeps it 12 dB quieter". There is no mix trim — `play()` sets `volume_db` to
0.0 for both hooks — and the 12 dB is baked into the sample (-26 against -14
dBFS in `PARAMS`). The comment now says so, and so does §1a.

## Two more the reviewer flagged as untested — both now tested

- **Relative levels.** §12.4's `ui.blot` "one layer under" the stamp lived only
  in `PARAMS`, and a re-render with the blot at -14 dBFS passed every test in
  the file. `test_the_blot_is_mixed_under_the_stamp_in_the_samples_themselves`
  measures the peak of every stamp and blot variant **from the source .wav
  bytes** and asserts the blot is strictly under. It reads the files rather
  than the loaded streams because the WAV importer compresses to QOA
  (`compress/mode=2` in every `.import`), so `AudioStreamWAV.data` is not PCM
  and cannot be measured. The doc gives no dB figure, so the test asserts only
  what the doc says — under — which equal levels fail.
- **Pool overlap.** `test_playing_the_same_hook_many_times_reuses_the_pool`
  asserted only `get_child_count()` stability, which is blind to a cut-off, and
  `_take()` reassigning `stream` on a sounding player is a hard cut (the 6 ms
  fade `_finish()` writes is at the end of the buffer, not at a stop).
  `test_a_full_lap_of_the_ring_touches_every_player_exactly_once` asserts the
  cursor walks all eight players before returning to one, then derives the
  burst it has to survive from doc numbers — §12.2's 90 ms log-line arrival ×
  §12.4's two hooks per mistake line, against the 138 ms longest sample — so
  `POOL_PER_BUS` is checked arithmetic rather than a number nobody can
  question. It still traces to no doc section; no doc states a pool size.

## And one test that had no regression value — replaced

`test_a_key_outside_the_four_is_refused` asserted
`level_db("audio_nonsense") == 0.0`, which the reviewer correctly shows passes
with the guard **deleted** (dict miss → null → `get_bus_index("")` is -1 →
`else 0.0`) — and 0.0 dB is unity, a correct answer for a real bus at 100%.
`level_db` now returns **NAN** for a key with no bus and for a bus missing from
the layout: the only float here that cannot be mistaken for a level. The test
asserts `is_nan()` for the refusal *and* that a real key at unity is not NAN,
so deleting the guard now fails. `level_db` has no callers outside `tests/`.

## Verification

    tools/with_godot_lock.sh "$GODOT" --headless --path . --script res://tools/parse_check.gd
      -> PARSE_CHECK scanned 123 script(s) / PARSE_CHECK OK   (re-run after each item)

    tools/with_godot_lock.sh "$GODOT" --headless --path . --import      (ui_seal.wav)

    tools/with_godot_lock.sh "$GODOT" --headless --path . --script res://tests/run_tests.gd
      -> 1/1265 failing        (an intermediate run mid-repair was 2/1259)

The one failure is another agent's in-flight file, not audio:
`test_adventures.gd :: test_the_mini_boss_is_still_winnable`. Every test in
`test_audio.gd` (40) and `test_settings.gd` (34) passes. The four red goldens
the reviewer saw, and the `test_a11y.gd` initial-focus failure that appeared
mid-pass, have both been resolved by their owners in the meantime.

**Net new tests in this repair pass: 5** (`test_audio.gd`, 35 → 40), plus three
existing tests rewritten to assert something they previously could not
distinguish. Sixteen engine errors are logged across the whole suite and
**two** of them now trace to `test_audio.gd` — the `level_db` refusal (:190)
and the unknown-hook refusal (:215). Both are deliberate `push_error` calls
with "this is expected" written on the assertion, and both are the same
pattern as the twelve others (`test_settings.gd:74/75`, `test_savegame.gd`,
`test_formulas.gd`, `test_content_db.gd`, `test_raid_plan.gd`): a subsystem
refusing an input loudly rather than inventing an answer.

**Files this repair pass touched** — all within the ownership list:
`game/core/Audio.gd`, `tests/unit/test_audio.gd`, `tests/unit/test_settings.gd`
(two comments), `tools/audio/gen_sfx.py`, `tools/audio/README.md`,
`game/assets/audio/sfx/ui_seal.wav` (+ its `.import`), and the three
`build/plan/*-audio.md` artifacts. `game/core/GameSettings.gd`,
`game/screens/Settings.gd`, `default_bus_layout.tres` and `project.godot` were
**not** modified.
