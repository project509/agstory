# Handoff — sim/comedy-pipeline slice

Changes I could not make because the file is not mine. Each one is small and each one is
named by a test that already documents the gap.

---

## 1. `sim/model/Encounter.gd` — reject a `spawn_round` block that M04 already owns

**Why:** M04 now owns add spawning (`sim/core/RaidSim._spawn_scheduled`, and the ruling in
`build/plan/q-sim.md`). The duplicate authored blocks are suppressed at runtime, which fixes
the double spawn but leaves the data lying: E1 still declares a "Late Add" block that never
appears, and nothing tells an author their block is dead.

**Change:** in `from_dict`'s structural-rules block (beside the one-mechanic-per-star check,
around `Encounter.gd:190-206`), append an error when any `EnemyBlock` has `spawn_round > 0`
and the encounter carries an `ADD_SPAWNS` spec that fires on that round. The fire predicate is
`RaidSim._spec_fires_on(spec, round_no)` — copy it or lift it somewhere both can call it, but
do **not** write a second copy that can drift from the first; the two paths disagreeing is
exactly the bug being fixed.

**Test that already anticipates this:**
`tests/unit/test_raid_sim.gd::test_an_authored_spawn_block_on_the_m04_round_never_activates`
asserts the block still exists in data and says in its failure message that Encounter.gd
should reject it. That assertion inverts once this lands — please update it in the same commit
rather than deleting it.

---

## 2. `data/encounters_t1.json` — delete the three now-inert spawn blocks

Once (1) lands, these three blocks are load errors:

| Encounter | Block | Why it is now inert |
|---|---|---|
| `t1_raid_e1` | `Late Add` ×1, hp 180, swing 8, `spawn_round: 5` | m04 spec: `count 1, hp 180, swing 8, round 5` — identical numbers, same round |
| `t1_raid_e2` | `Add` ×4, hp 75, swing 8, `spawn_round: 4` | m04 spec: `count 2, hp 75, swing 8, round 4, every 4` |
| `t1_raid_e3` | `Add` ×3, hp 50, swing 6, `spawn_round: 6` | m04 spec: `count 3, hp 50, swing 6, round 6` — identical numbers, same round |

E1 and E3's block/spec pairs carry the *same* hp, swing and count, so nothing is lost by
deleting the blocks. **E2 is the one that needs a decision:** the block says 4 adds and the
spec says 2 every 4 rounds from round 4, so removing the block reduces round 4 from six adds
to two. That drop is already in the goldens and the sweep numbers I report, and it is why E2's
clear rate at adventure/common/morale-55 moved 75% → 100%. If content wants the old volume,
raise the spec's `count` — do not restore the block.

**Also recheck:** `Encounter.primary_raw_per_round()` (`Encounter.gd:93-98`) filters on
`spawn_round == 0 and threat_rule != "lowest_hp"`. All three blocks above are `lowest_hp`, so
deleting them cannot re-include anything through the first clause — but the filter's
`spawn_round == 0` half becomes dead code once no block carries a `spawn_round`, and
`tests/unit/test_encounters.gd` should say which of the two clauses it is relying on.

---

## 3. `sim/content/MistakeLines.gd` + `data/mistake_lines.json` (M5-COMEDY-02/03) — the render path is now live and waiting

Every render site is wired end to end and tested. What is missing is only the corpus. To light
it up, populate two fields on the `Mistakes.MistakeEvent` that `Mistakes.roll()` returns:

- `ev.log_template_id` — the drawn variant's id, e.g. `"MIS_AGGRO.01"`. Lands on the entry as
  `mistake["template"]` and is pinned by the goldens, so the *choice* is reviewable.
- `ev.log_line` — the rendered text with `{actor}` substituted. Lands on the entry as
  `params["text"]`.

`RaidSim._log_mistake` already forwards both; nothing else needs changing there. Set them at
the four sites where a non-null `ev` comes back from `Mistakes.roll`:
`RaidSim._take_action`, `_phase_healers`, `_phase_ambient`,
`_roll_encounter_start_mistakes`. One Bag per encounter, built in `run()` from
`rng.derive("mistake_line", 0, 0)` per the audit's determinism note.

What already works, with no further plumbing:

- `EventLog.Entry.describe()` appends the joke as `      "…"` on a second line, matching
  docs/07 §10.3's sample block — so `tools/write_goldens.gd` will dump the whole corpus in
  situ into the five `story` arrays the moment lines exist. That regeneration is the
  "192 jokes appeared" diff the audit asked for, and it will be exactly that: nothing else in
  the story arrays moves.
- `game/screens/RaidView._append_line` draws it as an indented `LabelQuote` in quotation marks.
- `game/screens/Results._story_row` draws the same treatment as a second row.
- All three are asserted by `tests/unit/test_event_log.gd::test_the_joke_line_reaches_the_rendered_account`,
  `tests/unit/test_log_player.gd::test_the_joke_line_reaches_the_raid_view_as_a_label` and
  `::test_the_joke_line_reaches_the_post_mortem_as_a_label`, all three driving a
  hand-built entry because there is no corpus to draw from yet.

I deliberately did **not** author any lines, not even the four verbatim ones in docs/07 §10.3.
docs/07 §10.3 rule 4 requires ≥6 variants per type "so a long raid does not repeat", and a
one-variant seed would print the same joke for all nine `MIS_AGGRO` failures in
`e1_commons_starting` — worse than printing none, and it would have to be unpicked again.

---

## 4. `game/core/LogPlayer.gd` — no change needed, but its comment is now true

`severity_of` (`LogPlayer.gd:187-195`) reads the severity as a key and tolerates an int. That
was correct all along; the sim was the side that was wrong. No edit requested — noting it so
nobody "fixes" the reader.

---

## 5. Nine of twelve mechanics have no behaviour — the guard test now names them

`tests/unit/test_raid_sim.gd::MECHANICS_WITH_NO_BEHAVIOUR` lists
`m01, m03, m05, m07, m08, m09, m10, m11, m12` and a behaviour probe asserts that list is
exactly right. Whoever implements one must delete their key from it in the same commit, or the
suite goes red and says so.

Two notes for that implementer:

- **m03 is on the list even though `RaidSim._phase_effects` implements it.** It only damages
  raiders holding a Fire token, and every mistake type that emits one is rolled at
  `RollSite.MECHANIC` — which the sim never rolls at (that is audit item M5-COMEDY-09). The
  code exists and cannot be reached. It comes off the list when M5-COMEDY-09 lands, not when
  someone touches `_phase_effects`. Because it is the one mechanic that would otherwise look
  dispatched, it emits its own note — template id `mechanic_unreachable`, wording "is
  implemented but unreachable", distinct from the `mechanic_unimplemented` note the other
  eight get. Both are Debug tier; see `build/plan/q-sim.md` for why not Numbers.
- The auditor's `m5-mechanic-dispatch-guard` evidence says three of twelve are dispatched and
  implies nine are missing; that count is right, but only because m03's implementation is
  unreachable. Counting match arms alone would have called m03 done.

---

## 6. COMMIT ORDER — required, and the proof that it works

`audit.json`'s M5-COMEDY-01 `risk` field is an instruction, not a preference:
*"Do this alone, in one commit, with `story` arrays byte-identical and only
`full_log_sha256` moving — otherwise the diff that proves the comedy pass is
correct is buried under a diff that proves nothing."* This slice arrived as one
uncommitted change containing both the comedy items and the two behaviour fixes,
which is exactly the outcome that warns against. **Land it as two commits.**

### Commit A — the comedy pipeline (M5-COMEDY-06, -01, -05 plumbing, and the dispatch guard)

Everything except the two behaviour fixes. Regenerating the goldens on this tree
alone gives the artifact the audit asked for. Measured, not asserted — the run is
reproducible by neutralising two lines in `sim/core/RaidSim.gd`
(`var owned_by_m04 := false` and `var ignores_ac := false`) and running
`tools/write_goldens.gd`:

| scenario | `story` vs HEAD | `full_log_sha256` | `event_count` |
|---|---|---|---|
| e1_commons_starting | **byte-identical** (82 lines) | moved | 620 → 620 |
| e3_commons_adventure | **byte-identical** (37 lines) | moved | 523 → 524 |
| e5_first_clear | **byte-identical** (21 lines) | moved | 435 → 437 |
| e5_legendaries_raid | **byte-identical** (8 lines) | moved | 321 → 323 |
| e5_miserable_commons | **byte-identical** (95 lines) | moved | 316 → 318 |

Not one visible line of any transcript moves: `describe()` now reads
`mistake["name"]` and maps the severity key back through
`Enums.severity_name_of`, so the prose is the prose it always was. The `sha256`
moves because `to_dict()` grew keys, which is the movement the audit predicted.
The small `event_count` rises are the dispatch guard's Debug-tier gap notes, one
per unimplemented mechanic per fight — E1 has none, E3 has m01, the three E5
fights have m01 and m03. **If you want commit A's `event_count` to be flat too,
split the dispatch guard off as its own commit A2**; nothing else in A emits an
entry.

### Commit B — the two behaviour fixes (m5-m02-raid-wide-ac, m5-m04-double-spawn)

`ignores_ac` and the m04 spawn suppression, with their own regeneration. This is
the commit where `story` moves, and it should: E1 loses its duplicate add and
three fights re-resolve. Reviewing it against commit A's goldens is a diff about
combat, with no serialisation churn mixed in.

| scenario | `story` | rounds | mistakes | events |
|---|---|---|---|---|
| e1_commons_starting | 82 → 74 lines | 22 | 52 → 54 | 620 → 624 |
| e3_commons_adventure | 37 → 31 lines | 19 → 18 | 22 | 524 → 496 |
| e5_first_clear | unchanged | 21 | 14 | 437 → 455 |
| e5_legendaries_raid | unchanged | 17 | 2 | 323 → 354 |
| e5_miserable_commons | 95 → 84 lines | 16 → 14 | 64 → 58 | 318 → 278 |

(E5's larger event jumps in commit B are the pulse: 26/27/28 unmitigated means
more damage entries, more healing and more state changes.)

---

## 7. Status correction — M5-COMEDY-05 is NOT done

Its `depends_on` in `audit.json` is `["M5-COMEDY-02", "M5-COMEDY-03"]` and that is
still accurate. What landed is the render path and its tests; the acceptance
criterion — *"at least one Label whose text starts and ends with a double-quote
and matches a line in the pool"* — cannot be met because **there is no pool**.
`Mistakes.MistakeEvent.log_template_id` and `.log_line` have a declaration, a
`to_dict()` entry and a forwarder at `RaidSim._log_mistake`, and **no writer**;
`params["text"]` is therefore never populated by the sim, and all four joke tests
hand-build their entry. `build/plan/index.md` now marks it blocked, not done.

Section 3 above is the whole of what remains: set those two fields at the four
`Mistakes.roll()` call sites. Everything downstream of them is live and tested.
