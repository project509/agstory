# tools/audio — the UI one-shots and the ambience beds, and why each one sounds like that

`gen_sfx.py` renders every sample in `game/assets/audio/sfx/`; `gen_amb.py`
renders the five ambience loops in `game/assets/audio/amb/` (the second table,
below). Nothing in this
project's audio is sourced, downloaded or licensed; the art pipeline generates
its assets from script (`tools/art/*.py`, `tools/aseprite/*.lua`) and audio
follows the same rule.

```
python tools/audio/gen_sfx.py            # write game/assets/audio/sfx/
python tools/audio/gen_sfx.py --list     # print the manifest, write nothing
python tools/audio/gen_sfx.py --check    # re-render into a temp dir, byte-compare
                                         # with the tree; exit 1 on any miss
```

After a render, Godot needs `--import` before the new samples resolve:

```
source tools/env.sh
tools/with_godot_lock.sh "$GODOT" --headless --path . --import
```

Output is deterministic: every variant seeds its own `numpy` `Generator` from
`sha256("<hook>:<index>")`, so re-running produces byte-identical `.wav` files
and does not churn the repo. Requires `numpy` (already a dependency of
`tools/art`) and the stdlib `wave` module. Nothing else.

## The gate

Deterministic is not the same as gated. `--check` renders every manifest file
into a `tempfile.mkdtemp()` and compares it byte-for-byte with
`game/assets/audio/sfx/`, printing one line per file — `AGREE`, `DIFFERS`,
`MISSING` (in the manifest, not in the tree) — plus `ORPHAN` for a `.wav` in
the tree the manifest does not name (the `HOOKS` table in `game/core/Audio.gd`
repeats these filenames, so an orphan is a rename that landed on one side
only). Any of the last three exits 1.

`tools/build_art.sh --check` runs it beside the three Python art generators,
and `tools/verify.sh` stage 2b runs that — so a hand-edited sample, a stale
one, or a `PARAMS` change nobody re-rendered turns the gate red instead of
shipping. `tools/build_art.sh --gen` renders the samples with the art; there is
no separate `--audio` flag, because one door for every generated asset is the
point. Proved once on 2026-09-15 by flipping one byte of `ui_seal.wav`: `--check`
printed `DIFFERS`, stage 2b's `ART CHECK FAILED`, and the sample was restored.

The `.import` record beside each `.wav` is the other half: without it
`ResourceLoader.exists()` is false on a fresh clone, and
`tests/unit/test_audio.gd :: test_every_sample_has_its_import_record_beside_it`
is what notices.

## The constraint this file exists to satisfy

docs/13 §12.4:

> Names for 14 to bind; mixing is audio's call. All UI sound is *material*:
> paper, chalk, brass, wax, coin. **No synthesized blips.**

That sentence is the whole specification, and it rules out the obvious
implementation. An oscillator with a decay envelope is a blip no matter what
frequency it plays. So every sound below is built from a crude physical model
of the object that makes it:

| Material | Model | Why it reads as that material |
|---|---|---|
| Paper, chalk | Band-limited noise gated by a random-walk "stick-slip" grain | Chalk on slate catches and releases hundreds of times a second. A flat noise burst is a hiss; a gated one has grit |
| Brass, coin, wax seal | A bank of exponentially damped sinusoids at **inharmonic** ratios | A struck disc's modes are Bessel zeros, not integer multiples. Harmonic partials are exactly what makes a synth tone sound synthetic |
| Mass on a desk (stamp, ledger) | Low-passed noise plus one low damped sine | The thump is the platen and the desk, not a note |

Filtering is done as an FFT mask with a raised-cosine skirt over `width`
octaves rather than an IIR filter, so no `scipy` is needed. The skirt is not
cosmetic: a brick-wall mask rings, and ringing is precisely the artefact §12.4
forbids.

Every file is 44.1 kHz, mono, 16-bit PCM, DC-removed, peak-normalised, and
faded 0.5 ms in / 6 ms out. The out-fade matters — a buffer that ends
mid-waveform clicks, and a click on `ui.stamp` (which fires dozens of times per
raid) is exactly the fatigue §12.4 warns about.

## The eleven hooks

Lengths obey docs/13 §12.2: *"Only the last two are indulgent, and both are
once-per-cycle commitments. Everything else is under 140ms."* The two
indulgent moments are the page turn and the ledger close.

Round-robin depth is doc-mandated **only** for `ui.stamp` ("three round-robin
variants"). The others are chosen for fatigue on the hooks that fire most and a
single take where the hook fires once per cycle. Pitch jitter is likewise
doc-specified only for `ui.stamp` (±2 semitones); giving another hook a jitter
would be inventing a number the doc set does not state, so every other hook's
`pitch_jitter_semitones` is 0.

| Hook | ms | dBFS | Takes | Model |
|---|---|---|---|---|
| `ui.tab` | 95 | −20 | 1 | Two sheets of paper settling 35 ms apart: stick-slip noise banded 900–5200 Hz, 3.5 ms attack, 22 ms decay, the second at 0.45 gain |
| `ui.row_select` | 70 | −23 | 2 | A brass bar tapped: damped sines at 1180 Hz × (1, 2.37, 3.91), τ 16/9/5 ms, plus 0.30 of 3.2–8.5 kHz air on the leading edge. Take 2 detunes ×1.06 |
| `ui.chalk` | 78 | −22 | 3 | Stick-slip at 620 Hz grain, banded 1800–7000 Hz, τ 26 ms. The grain is the sound |
| `ui.chalk_bad` | 120 | −21 | 1 | The same stroke lower, duller and 50% longer: 700–3400 Hz, 320 Hz grain, τ 48 ms. §12.4 fires it 60 ms late; the lateness is the caller's, not the sample's |
| `ui.stamp` | 125 | −14 | 3 | **The signature sound.** Three layers: a 4 ms contact tick (3–6.5 kHz) that starts on sample 0 so the sound can never be late; the wooden body (380–1700 Hz, τ 13 ms); the platen hitting the desk (260 Hz damped sine + sub-260 Hz noise, τ 34 ms). Loudest of the set on purpose, and the shortest thing that could carry it |
| `ui.seal` | 138 | −18 | 1 | Wax under a press: a 210 Hz thump (τ 52 ms), a soft brass ring at 860 Hz × (1, 2.71, 4.13), and 0.30 of banded 150–1100 Hz squelch. **Was 155 ms**, the one sample above §12.4's 140 ms — see the note under the table |
| `ui.coin` | 135 | −21 | 2 | A small struck disc: 2420 Hz × (1, 1.59, 2.14, 2.65, 3.16) with τ 88→16 ms, plus a 2.5 ms 5–11 kHz contact tick. Take 2 detunes ×1.093 |
| `ui.page_turn` | 380 | −20 | 1 | Indulgent. The grab (stick-slip, 0–70 ms hump), the sweep (band centre gliding 1100→3300 Hz across four crossfaded bands, 30–300 ms hump), the flap as it lands (sub-1 kHz burst at 285 ms) |
| `ui.ledger_close` | 430 | −17 | 1 | Indulgent. Pages compressing (300–2600 Hz, 180 Hz grain, 0–300 ms hump), then the covers meeting at 290 ms (165 Hz, τ 72 ms) with a 0.22 air tail |
| `ui.blot` | 90 | −26 | 2 | Wet and dark: sub-900 Hz stick-slip, τ 40 ms, with a 0.22 spatter tail at 1.5–3.2 kHz starting 14 ms in. The quietest thing in the set, because §12.4 puts it "with the stamp, one layer under it" — it must never be heard as a second stamp |
| `ui.silence` | — | — | — | **Not a sample.** §12.4: "Ducks all buses to −60dB for 400ms." Implemented as `Audio.duck(-60.0, 0.4)` in `game/core/Audio.gd` |

### Where the lengths come from, and where they do not

docs/13 gives a sample length for **exactly one** hook: §12.4's `ui.stamp` is
"≤ 140ms, three round-robin variants, ±2 semitone random pitch". Every other
number in the `ms` column is a house choice, disclosed here rather than traced.

§12.2's "Everything else is under 140ms" is **not** a second source for those:
that table bounds *animation duration*, and the two hooks it calls indulgent
(the 700 ms page turn, the 900 ms ledger close) are bounded by their own
motions, which is why `ui.page_turn` (380 ms) and `ui.ledger_close` (430 ms)
may run long. The house rule adopted is that a non-indulgent one-shot stays
inside the stamp's 140 ms — the doc's own number, applied wider than the doc
applies it. `ui.seal` came down from 155 ms to honour it, because
`tests/unit/test_audio.gd` asserts it, and a bound with an exception for the
one file that broke it is not a bound.

## Where each hook fires (W6-AUD-BIND)

Bound by signal where a signal exists, in `game/core/Audio.gd` (no screen learns
about audio): `ui.tab` ← `ScreenRouter.screen_changed` (silent on the boot
transition — the first screen of a session is one the player did not cause);
`ui.coin` ← `GameState.gold_changed` (a restore is not a change);
`ui.ledger_close` ← `GameState.day_advanced` (the Day Tick, on a rest or an
attempt). Bound at the gesture where none does: `ui.chalk` in
`RaidPrep._toggle` (both branches, before the redraw), `ui.chalk_bad` on the
chalk refused at the cap and 60 ms after the comp check TURNS invalid
(`RaidPrep._build_readout`, a tree timer), `ui.page_turn` at the Depart press,
`ui.stamp`/`ui.blot` in `RaidView._append_line`'s mistake block and the wipe's
stamp beat, `ui.seal` at the wipe's seal drop and on every `Widgets.cta`
`button_down`, `ui.row_select` at the three `_selected` transitions,
`ui.silence` at wipe t=0. The two motion-synced hooks bind to their EVENTS: the
router has no transition (docs/13 §2 M5), so the sound is the turn / the close,
and a motion, if ever built, syncs to the sound.

Three defaults, asserted in `tests/unit/test_audio_binds.gd`: reduced motion
never silences a hook (sound is not motion; §13 keeps the stamps landing); at
Instant and during a skip no per-line hook fires (`Audio.play(hook,
{"live": false})` is dropped in the autoload) and only the wipe's tail sounds;
reduced effects and the comedy brake do not touch audio.

## Re-tuning

Every number above lives in `PARAMS` in `gen_sfx.py`, one entry per hook. Edit
there, re-render, re-import. The filenames are produced by `filename()` and
repeated by `HOOKS` in `game/core/Audio.gd`; a rename in one is a rename in the
other, and `tests/unit/test_audio.gd` fails on the drift in either direction
(`test_every_hook_with_a_sample_names_a_file_that_is_really_there` and
`test_no_generated_sample_is_an_orphan`).

## The five ambience beds (W7-AUD-AMB — Q-98 (ii), BL-138)

`gen_amb.py` renders one seamless loop per stage family into
`game/assets/audio/amb/`, from the same primitives as the one-shots (it imports
`band`, `stick_slip`, `struck`, `ar` and `hump` from `gen_sfx.py`). They ride the
**Music** bus ("Audio — music and ambience") through two dedicated players in
`game/core/Audio.gd`, crossfading equal-power over 600 ms, and reach the mixer
through ONE door: `SceneStage.load(name)` calls `Audio.play_bed(name)`, and
`Audio.BEDS` maps the scene name to its bed. No screen learns about audio.

```
python tools/audio/gen_amb.py            # write game/assets/audio/amb/
python tools/audio/gen_amb.py --list     # the manifest: bed, file, length, layers
python tools/audio/gen_amb.py --check    # re-render to a temp dir; AGREE / DIFFERS /
                                         # MISSING / ORPHAN per bed, a LOOP line per
                                         # bed, DISTINCT across the set; exit 1 on any
```

`tools/build_art.sh --check` runs it beside `gen_sfx.py --check` (verify stage
2b); `--gen` renders the beds with the art. After a render, `--import` — and the
`.import` beside each bed says `edit/loop_mode=2`, which is **Forward** in
Godot's WAV importer (0 detects from the file, 1 is Disabled); the streams
load as `AudioStreamWAV.LOOP_FORWARD` and `tests/unit/test_audio_beds.gd`
asserts both the record and the loaded stream. Compression is QOA, the
importer's default and the one-shots' own (~450 kB per bed in the pack).

| Bed | s | Scenes | Layers (seed `sha256("<bed>:<layer>")`) |
|---|---|---|---|
| `amb_camp` | 26 | `stage_camp` (Town, the Board, the Guildhall, the Completion); `stage_town` (the main menu's aerial — the guild's own camp from above, BL-138) | **hearth** — 60–400 Hz roar under a 2–9-cycle swell; ~12 crackles/s of 1–4 kHz noise with 4–14 ms decays, log-uniform in size; a 120–700 Hz pop every ~1.6 s. **wind** — 100–600 Hz noise under a squared 1–5-cycle gust (the lulls are lulls) |
| `amb_tavern` | 24 | `stage_tavern` | **murmur** — five detuned voices, 200–800 Hz, each a two-formant noise band (f ±½ oct, 1.9–2.6 f at 0.4) gated at 3–5 syllables/s and swelling on its own 2–8-cycle walk. **clink** — pewter and glass: 2.1–3.4 kHz × (1, 1.48, 2.11, 2.79), τ 120→30 ms, every 6–14 s. **hearth** — the camp's fire at 0.4, further off |
| `amb_market` | 28 | `stage_market` | **chatter** — the murmur brighter (300–1400 Hz), busier (seven voices) and faster (4–7 syllables/s). **cart** — a 70–260 Hz wooden rumble under a 6 Hz clatter, humped over 5–7 s, every 12–20 s. **gull** — two to four falling cries a cluster (a band gliding 2800→1700 Hz over ~220 ms), a cluster every 8–16 s |
| `amb_cave` | 22 | `stage_arena_cave` (adventures, tutorials) | **air** — a 40–120 Hz hollow rumble swelling over 1–4 cycles, a 150–500 Hz breath at 0.22. **drip** — a 1.2–2.5 kHz resonant tick (τ 40 ms, a 2.3× partial at 0.3) with a 2.5–7 kHz splash, every 2–7 s |
| `amb_dungeon` | 25 | `stage_arena_dungeon` (raids, Q-96) | **air** — the cave's, re-seeded. **creak** — a chain taking weight: stick-slip catches at 2–4 Hz over 1.2 s gating a 160–1300 Hz grain with a 300–500 Hz ring under it, every 9–17 s. **stonefall** — once a loop: an 80 + 130 Hz thump, a 500–3000 Hz gravel scatter 40–90 ms behind, two or three smaller stones after. **No drip** — the same rock, a different room |

Every bed is 44.1 kHz mono 16-bit at **RMS −30 dBFS, peak ≤ −20** (BL-138).
Those two numbers leave 10 dB of crest and Gaussian noise takes 12, so each
continuous layer is rounded at 2.5 σ (crest ≈ 8 dB — rounded noise is still
noise) and normalised to unit RMS before its gain; each event layer is
normalised to unit peak, so its gain is how far its loudest moment stands over
the bed (2.6–3.5 = +8 to +11 dB); a tanh knee from −24 dB folds what is left
under −20. The seam: every bed renders N + 600 ms and folds the tail into the
head equal-power (sin/cos), and every slow modulator is a sum of sines with an
integer number of cycles per loop, so a gust rising at the loop's end is rising
at its start. `--check`'s LOOP line measures it — the 125 ms each side of the
seam within 3 dB, the seam's sample step no outlier against the bed's own
p99.99 step — and DISTINCT is the ruling's own acceptance line: the dungeon is
a recombination of the cave's layers plus one event, never anyone's bytes.

The crossfade in `Audio.gd` is the same 600 ms and the same law, stepped in
`_process` beside the §12.4 duck — no Tween, so `lint_motion.sh` has nothing
to say; a fade is not motion and reduced motion does not touch it (AUDIO-11).
The same bed asked for twice is left running: the camp family shares one fire.

## What is deliberately NOT here

**No music yet.** docs/02 §9.1's melodic column — the sparse lute, the drum,
the Renowned bell toll, the Legendary stinger and the leitmotif — is ruled
(Q-98 (i), 2026-09-15): the generated lute at Unknown/Known is W10-BUFFER's
first item (`gen_music.py`, `Audio.BEDS_MUSIC`, `Audio.MUSIC_BED`), cut for
1.0 in writing if the buffer is consumed; the ensemble, the bell, the cheer and
the leitmotif are post-1.0. `Audio.play_bed()` plays ambience and nothing
melodic, and `tests/unit/test_audio.gd :: test_play_bed_plays_ambience_and_never_a_melodic_bed`
pins the boundary. A town-aerial bed is post-1.0 too (BL-138): the aerial
plays the camp.
