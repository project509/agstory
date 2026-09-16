# Proposed docs/15 entries — audio (M6-AUD-06, and the AUD-05 deferral)

> **CONSUMED (W6-LEDGER, 2026-09-15):** the two entries are `docs/15` **Q-97** (the direction, as built, with the two repair-pass house choices folded in) and **Q-98** (the beds — plus AUDIO-07's ambience-bus ruling, AUDIO-13's voice/world questions, AUDIO-11's three option defaults and AUDIO-19's clear's-sound line, so the designer answers the whole soundscape once; ship plan §6 #46); the §8 gap row points at both. The draft's numbers (Q-96/Q-97) were taken by the arena question and are renumbered on landing, as AUDIO-06 said. The `Audio.gd` header's citation of this file stays valid (the file exists) and W7-AUD-AMB re-points it when it next owns the file; docs/13 §12.4 / docs/14 §4's cross-references are W7-DOCS's.

Audit item **M6-AUD-06** is the record-keeping half of the project's own
ambiguity rule. docs/15's numbered decisions run to **Q-95**, and audio appears
in that document exactly once: `docs/15-open-questions.md:593`, as an
**unnumbered row** in §8 *"Ownership gaps — nobody owns these at all"*:

> **Audio and music** | The word "music" appears nowhere in the doc set …
> defers mixing to "audio's call" — to nobody | **Assign an owner.**

Because it carries no Q number, nothing in the build treats any audio choice as
DECIDED, and this project's rule — an ambiguity is implemented behind a switch
with the documented default and recorded in docs/15 — has no anchor to point
at. The audio pass just made ~15 choices that need one.

I did not edit `docs/15-open-questions.md` (house rule 1). Two entries are
proposed below, in the shape of that table's existing rows.

---

## Q-96 — What is the audio direction, and what does "audio's call" mean when nobody owns audio?

**Source.** docs/13 §12.4 (the eleven hook names, the material rule, the
`ui.stamp` constraints); docs/13 §15.1 (the four bus levels and their
defaults); docs/14 §4 (an `audio.gd` in the directory tree that never existed);
docs/15 §8 (the ownership gap above).

**Why it matters.** docs/13 §12.4 hands doc 14 eleven hook names and says
"mixing is audio's call." docs/15 §8 observes that this defers the decision to
nobody. Meanwhile `GameSettings` already declared four audio keys with
documented defaults and the Settings screen already showed a master-volume row
— *disabled, with the reason "There is no audio yet."* The gap was not
theoretical: the game presented a volume control that controlled nothing.

> **Correction (repair pass).** An earlier draft of this entry, of
> `game/core/Audio.gd`'s header and of `tests/unit/test_settings.gd` attributed
> the sentence *"a lying toggle is the one thing worse than a missing one"* to
> **docs/13 §7**. The doc does not contain it. §7 is the Widget kit parts
> table; what it says is that a disabled `WaxButton` carries "reason text
> beneath — never a mystery", and §12.3 says a disabled control needs "a reason
> string adjacent. A disabled control that does not say why is a dead end". The
> lying-toggle sentence is `game/screens/Settings.gd`'s own header prose,
> written by an earlier pass beside a §7 citation, and re-quoting it as canon
> was the exact failure house rule 1 exists to stop. All four occurrences are
> corrected; the ruling below does not depend on it.

**Ruling (what M6-AUD-01..04 actually implement).**

1. **Four buses, no fifth.** `default_bus_layout.tres` declares Master, Music,
   UI, Voice, in docs/13 §15.1's own order, with Music/UI/Voice sending to
   Master. There is deliberately **no SFX bus**: §15.1 names
   voice-of-the-scribe, not SFX, and inventing a fifth bus would put a level in
   the mixer that no option in the closed inventory can move.
2. **The four settings keys move those four buses**, by name, at boot and on
   every change (`Audio.apply_levels`). 0 mutes rather than trusting
   `linear_to_db(0.0)`, which is −∞ and which Godot clamps to −80 dB — audible
   on a loud system, and "0" in an options menu has to mean silent.
3. **The eleven §12.4 hooks are bound by name, and an unknown name is a hard
   error** (`push_error`), never a silent no-op — the same discipline as
   `GameSettings.get_value`. A hook with an empty stream list is a legal
   no-op, which is how a hook can be bound before its sample or its animation
   exists.
4. **SFX are generated procedurally from physical models**
   (`tools/audio/gen_sfx.py`), because canon is silent on audio and docs/13
   §12.4's "material: paper, chalk, brass, wax, coin. No synthesized blips" is
   the only constraint in the doc set. Filtered noise with a stick-slip grain
   for fibre and grit; inharmonically damped sine banks for struck metal and
   wax; a low-passed thump for mass on a desk. Each model and its parameters
   are recorded in `tools/audio/README.md` so a re-render is reproducible and a
   human can re-tune without re-deriving.
5. **`ui.silence` is a mixer move, not a sample** — `Audio.duck(-60.0, 0.4)`,
   exactly §12.4's "Ducks all buses to −60dB for 400ms". The duck rides on top
   of the player's own master level, so a player at 50% ends the wipe at 50%.
6. **Melodic beds and the Legendary leitmotif are DEFERRED pending a human
   owner** — see Q-97.

**Switch.** The proposal implements the documented default in every case, so no
runtime switch is required. The two parameters a human is most likely to want
to change are isolated: `PARAMS` in `tools/audio/gen_sfx.py` (every synthesis
number, one entry per hook) and `Audio.HOOKS` (bus, variant list and pitch
jitter per hook). `pitch_jitter_semitones` is 2.0 for `ui.stamp` — §12.4's
"±2 semitone random pitch" — and **0.0 for every other hook**, because §12.4
specifies a jitter for the stamp and only for the stamp, and giving another
hook one would be inventing a number.

**Still owed by a person.** docs/15 §8's own recommendation stands: *assign an
owner.* Specifically (a) is `ui.stamp` actually non-fatiguing at the rate a
real raid fires it — a taste judgement a build loop cannot self-verify, and the
one thing in the audio pass most likely to be wrong; (b) the two hooks with
samples and no trigger yet (`ui.page_turn`, `ui.ledger_close`) need the
animations they sync to (JUICE-02).

---

## Q-97 — Are the per-rank music beds and the Legendary leitmotif composed, licensed, or cut?

**Source.** docs/02 §9.1's per-rank Audio column
(`docs/02-town-and-buildings.md:349-354`); docs/15 §8's ownership gap.

**Why it matters.** docs/02 §9.1 makes six concrete audio commitments, one per
reputation rank: Unknown *"Wind, one dog, sparse lute"*; Known *"Lute gains a
drum"*; Respected *"Anvil ring loop, market chatter"*; Established *"Full
ensemble; crowd murmur bed"*; Renowned *"Bell toll on entry"*; Legendary
*"Cheer stinger on entry; leitmotif"*. docs/02 §2.2 claims the town is the
progression bar, and a third of that checklist is audio. None of it exists.

**Ruling — SPLIT, and only half of it is a build task.**

The **melodic** half is genuinely blocked and must not be autonomously
"solved": the sparse lute, the drum, the Renowned bell toll, the Legendary
cheer stinger, and above all the leitmotif. A leitmotif is an authored theme
that has to be recognisable and has to carry the game's tone. Procedural
generation produces something that is technically music and audibly not a
theme, and shipping that is worse than shipping silence. So:

- `Audio.play_bed()` and `Audio.stop_bed()` ship as **deliberate no-ops** with
  the reason written on them, so callers can be authored now.
- `tests/unit/test_audio.gd :: test_play_bed_is_a_no_op_because_no_one_owns_the_music_yet`
  is the tripwire: it asserts nothing plays on the Music bus, and it is the
  test that has to change when a human owner delivers stems.

The **ambience** half is not blocked. Wind, rain on puddles, crowd murmur, an
anvil ring, a dog — these are filtered noise and granular material, exactly
what `gen_sfx.py` already does, and a `tools/audio/gen_amb.py` can produce
seamless 30–60 s loops keyed by rank for `Town.gd` to pick from
`_state.reputation_rank`. That half should not be held hostage to the composed
half. **It is not built in this pass** — see the report's "what I did not do".

**What a person must decide.**

1. Name an audio owner (docs/15 §8's own recommendation).
2. Are the five rank beds composed, licensed CC0, or cut for 1.0?
3. If composed: five stems at 44.1 kHz that loop seamlessly, plus the leitmotif
   in a form the Legendary entry stinger can quote.

**Cross-references owed** (M6-AUD-06, and not written by me — I do not own
these files): docs/13 §12.4 should point at Q-96 for its binding; docs/15 §8's
unnumbered "Audio and music" gap row should point at Q-96 and Q-97 so the gap
row names its own resolution; BUILD_STATE.md should record that a fourth
autoload exists.

---

## Repair-pass addenda to Q-96 — two house choices that were not written down

Both are disclosed rather than traced. Neither is a switch, and the reason in
each case is that the alternative is not a behaviour a player would ever want
selectable.

**(a) The 140 ms ceiling is applied wider than the doc applies it.** docs/13
gives a sample length to exactly ONE hook — §12.4's `ui.stamp`, "≤ 140ms" — and
none at all to the other nine. §12.2's "Everything else is under 140ms" is a
bound on **motion duration** and not a second source for sample lengths, which
is why that table also contains the 700 ms page turn and the 900 ms ledger
close. The house rule adopted, and asserted in
`test_audio.gd :: test_every_other_hook_stays_inside_the_stamps_140ms`, is that
a non-indulgent one-shot stays inside the stamp's 140 ms; the two indulgent
hooks are bounded instead by the motion §12.4 syncs each of them to (380 ≤ 700,
430 ≤ 900). `ui.seal` came down from 155 ms to 138 ms to honour it. If a human
audio owner wants a longer seal, this is the line to argue with — the number is
in `PARAMS` and the bound is in one test.

**(b) A save restore is not a "gold change".** docs/13 §12.4 triggers `ui.coin`
on "Gold changes", synced "On the value write", and does not say what happens
when a whole campaign is written at once. `GameState.gold_changed` fires from
four places and two of them are exactly that — `new_game` (:532) and the tail
of `from_dict` (:2376) — so the literal reading rings a coin chime over the
load screen. **The default implemented is silence**, on the reading that a
restore is a state arriving rather than a transaction the player caused, and
that a sound the player did not cause is worse than a missing one. The guard is
`Audio._coin_note`; the clean version is one flag in `GameState` and is written
out in `build/plan/handoff-audio.md` §0. No switch: a player who wants a chime
when a save loads is not a player this project has.
