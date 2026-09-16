# M5 — the mechanic arms: REPAIR PASS

The original `report-mech-arms.md` is not on disk (the previous wave lost it).
This file starts at the repair, and records the reviewer's six findings, what
was verified, and what was changed. Everything below was checked against the
code before it was acted on.

Baseline at the start of this pass: **1267 tests, 1 red** —
`test_adventures.gd :: test_the_mini_boss_is_still_winnable` (A3 clears 0/24).

---

## Verdicts on the six findings

| # | Finding | Verdict |
|---|---------|---------|
| 1 | Stray MIS_FIRE kills raiders on E3 | **CONFIRMED — fixed** |
| 2 | `split(" ")[3]` swap-cap assertion is vacuous | **CONFIRMED — fixed** |
| 3 | Inertness test is a replay-determinism test | **CONFIRMED — fixed** |
| 4 | Two undocumented rulings live in `sim/` | **CONFIRMED — both deleted** |
| 5 | `_tank_swap_is_live` silently voids m01 on A3 | **CONFIRMED — gate removed** |
| 6 | Q-M03 and the m03 exit code disagree | **CONFIRMED — code now matches Q-M03** |

No finding was wrong. Three of them were my own report's claims about my own
work, and all three were false as written.

---

## 1. The E3 fire kill (must_fix 1)

**Verified.** `data/encounters_t1.json` t1_raid_e3 carries m01, m02, m04 and no
m03, yet `tests/golden/e3_commons_adventure.json` lines 14, 15 and 37-38 showed
`Bob · Stood in the Fire` at R01 and R03 and `Bob MISTAKE · Severe · Died to
Something Extremely Avoidable` / `Bob is DEAD` at R11. The chain the reviewer
describes is exactly right, and every link is in a file I own.

**Two independent defects, two fixes.**

*(a) M01 was asking a question every round.* `_mechanic_demands_now`'s TANK_SWAP
arm fell through to `_mechanic_fires`, which is true every round for a spec with
no cadence, so both tanks rolled a MECHANIC-site mistake check on every round of
every m01 fight. Before the arms landed, E3 rolled that site zero times.

docs/10 §7.3's E3 card and §7.5's E5 card both say **"Standard threat, with M01
overriding on stack 3"** — the swap is an event AT the threshold, not a standing
demand. So the check is now gated on the threshold:

- `sim/core/RaidSim.gd` `_check_demanded_now` — new predicate, "was a raider
  ASKED this round", used only by `_phase_mechanic_checks`.
- `sim/core/RaidSim.gd` `_tank_swap_demanded` — true only while the living
  active tank is carrying `swap_at` or more.
- `_resolve_demanded_mechanics` deliberately keeps the older, wider
  `_mechanic_demands_now`: the off-duty decay and the hand-over when the holder
  dies must run every round or M01 becomes a different mechanic. The comment
  above it says so.

*(b) A Fire token could be stamped on a fight with no fire.* Two MECHANIC-site
types emit `Token.FIRE` (`MIS_FIRE` and `MIS_MECHANIC_DROP`) and neither is
gated on the encounter carrying a zone. With no m03 spec there is no tick, no
`escape_chance_bp` to roll against, and `Enums.TOKEN_DURATION[FIRE]` is -1 — so
the token was permanent, and `Mistakes._eligible` treats `requires_token` as ANY,
which armed the taxonomy's only Critical cascade-only type for the whole fight.

`_phase_mechanic_checks` now refuses the stamp: the encounter card is the
authority on which consequences are in play, RaidSim is the only thing that
reads it, so the invariant belongs there. Note this is **not** made redundant by
gating `MIS_FIRE` in `Mistakes.gd` — `MIS_MECHANIC_DROP` emits FIRE too and has
no `requires` at all.

*The flavour half is not mine.* "Stood in the Fire" should not be *eligible* on
an encounter with no ground effect — docs/07 §5.2 row 1 defines its consequence
as "takes mechanic tick damage in Phase 5", which a fight with no tick cannot
deliver. `Mistakes.gd` already has the exact mechanism (`"requires":
"interrupt_check"` on the two interrupt types, set from `_context` in RaidSim).
Exact old→new is in `build/plan/handoff-mech-arms.md`.

## 4 and 5. The undocumented rulings, and the silent retune

**`TANK_DEBUFF_STACK_CAP_AT_SWAP` — deleted.** `grep` across `build/plan/`
confirms the reviewer: there was never a proposal for it. docs/10 §10 M01 names
one threshold and no ceiling. The cap's only real effect was to soften the one
case docs/06 says must hurt — a tank with nobody to swap to — so it is gone
rather than proposed. Stacks are now uncapped.

**`POSITIONING_DEFAULT_REQUIRED` — deleted.** docs/10 §10 M07 is "demands Spread
or Stack" and privileges neither; "M07 names Spread first" was a reading of
table word-order. An m07 spec with no `required` param now opens no window and
says so in a MECHANIC line ("The fight demands a position and nobody can say
which") — the same treatment M05's unnamed effect `E` already gets, and for the
same reason. No shipped encounter authors m07.

**`_tank_swap_is_live` — deleted.** It gated M01 off entirely when
`tanks_required < 2`, which made m01 a silent no-op on A3 — a ★★★ encounter
whose docs/10 §8 row lists M01 among its mechanics. That is docs/10 §6's "a star
that buys nothing is a lie on the encounter card", and it contradicted the
audit's `m5-m01-tank-swap` remaining_work (5) directly. The "nobody to swap with
and holds it at N stacks" line in `_attempt_tank_swap` was already written; the
gate was the only thing making it unreachable.

The motive for the gate was A3 measuring 0/24 seeds. Measured again with the
gate gone, A3 is still 0/24 — the gate never bought the test it was added for.

## 6. The m03 exit

**Verified.** `var out := round_no > emitted` ran unconditionally before the
escape roll, so every stay capped at two ticks, `escape_chance_bp` only ever
chose between one tick and two, and the permanent zone `q-mech-arms.md` Q-M03
describes did not exist in the code at all — the doc entry would have documented
behaviour the sim does not have.

`_phase_effects` now implements Q-M03 as written: the docs/10 re-roll is the
only exit, and an encounter that omits `escape_chance_bp` keeps a permanent
zone. docs/07 §5.2 row 1's "leaves at end of next round" reads as the expected
outcome of a 50%/round re-roll, which is what Q-M03 already argued.
`Combatant.token_source` was this branch's only reader in `sim/`; the
`_apply_mistake` comment no longer claims a reader that does not exist.

## Combatant.from_dict, unrecognised stance

**Verified.** `maxi(0, Enums.stance_from_key(...))` mapped an unrecognised key
to 0, which is `Stance.SPREAD` — the opposite of the "stacked" default the same
line declares. Only the absent-key case was tested. `from_dict` now falls back
explicitly to `Stance.STACKED`.

---

## 2 and 3. The two vacuous assertions

**#2 - the swap threshold.** Confirmed exactly as described. The line is
`"%s steps out at %d stacks; %s takes over."`, so `split(" ")[3]` is the word
`"at"`, `int("at")` is 0, and `assert_true(stacks <= swap_at)` was `0 <= 3` on
every run. The report advertised that assertion as proof the cap held.

Replaced by two things:

- `_handover_stacks()` parses from the RIGHT of the number
  (`text.get_slice(" stacks;", 0)`, last word), which is also name-safe: a
  two-word display name would have shifted the old index anyway.
- `test_m01_steps_out_at_the_authored_threshold_and_not_before` asserts the
  bracket **`swap_at <= stacks <= swap_at + swings_per_round`** (nobody steps
  out early; nobody carries it more than one round of swings past the
  threshold, because stacks land in Phase 1 and the swap resolves in Phase 0)
  AND the relative property: the same fight authored with `swap_at` 6 must hand
  over at strictly higher stacks than the same fight at 3. That second half is
  what a hardcoded threshold cannot satisfy. It is the reviewer's own breaking
  input ("make a tank step out at 5 stacks on E3 and watch the suite stay
  green") turned into an assertion.

**#3 - the joke picker's inertness.** Confirmed:
`test_drawing_a_line_moves_no_simulation_outcome` ran `_run()` twice on the same
seed and compared, which is replay determinism, not inertness, and it contained
`assert_eq(res.rounds, res.rounds)`.

Rewritten to hold the seed fixed and vary the **joke volume**, which is the only
variable that matters. A `_SilentPool` test double returns an empty list from
`variants_for` / `legendary_variants_for`; `Bag.draw` bails on an empty list
having consumed **zero** draws, so the quiet run draws no jokes and the loud run
draws one per mistake. The test asserts both facts (0 jokes vs more than 3) and
then that `rounds`, `damage_dealt`, `healing_done`, `mistake_count`, survivor
count and outcome are all identical. If `_draw_joke` shared the master stream,
every roll in the loud run would land one draw later and the two fights would
diverge on the first mistake - which is exactly the reviewer's breaking input.

The pool is borrowed and restored around the swap (`Sim._lines()` first, so the
content cache is populated before it is replaced), with no assertions inside the
swap, so a failure cannot leave a silent corpus behind for every test that runs
after it.

The determinism half it used to be doing kept its assertion and got an honest
name: `test_the_same_seed_replays_exactly`.

---

## The goldens

Regenerated. Against the pre-wave commit 8c7dd07, which is the honest baseline
for the whole arm-landing plus this repair:

| golden | outcome | rounds | survivors |
|---|---|---|---|
| e1_commons_starting | attrition = | 22 = | 11 = |
| e3_commons_adventure | victory = | 18 -> 19 | 12 -> 11 |
| e5_first_clear | victory = | 21 = | 12 = |
| e5_legendaries_raid | victory = | 17 = | 12 = |
| e5_miserable_commons | wipe = | 14 -> 11 | 0 = |

**e1 is still the control and it still holds.** Every simulation number is
byte-identical to the pre-wave commit - damage_dealt 1789, healing_done 662,
mistakes 54, rounds 22, survivors 11, event_count 624 - and only
full_log_sha256 moved, because the log now carries joke strings. E1's only spec
is m04, so nothing in this repair could touch it, and nothing did.

**e3 no longer contains the word "fire".** A grep of the golden for "Stood in
the Fire" or "Extremely Avoidable" returns 0.

### Correcting my own section 5

The old report said "E3 and E5 got harder in the way the mechanics intend - one
casualty each". For E3 that was wrong, and the reviewer is right that it
laundered a defect as design: the casualty was Bob dying at R11 to
MIS_AVOIDABLE_DEATH, armed by a permanent Fire token on a fight with no fire.

E3 is still 11 survivors and the casualty is still Bob, but the cause is now one
the encounter card actually promises. Traced from the log:

```
[R01] boss hits Bob x2      stacks 0 -> 2   (hit 1 unmultiplied, hit 2 at x1.5)
[R02] boss hits Bob x2      stacks 2 -> 4   (x2.0, x2.5)
[R03] p0  Bob MISTAKE - Severe - Dropped a Mechanic       <- the swap check
[R03] p0  "Bob is meant to step out at 3 stacks, and does not."
[R03] p1  boss hits Bob x2  (x3.0, x3.5)                  <- Bob is DEAD
```

That is docs/10 section 7.3's card working: "the first fight where the second
tank has to function rather than merely exist". Dave picks the boss up and the
raid clears in 19 rounds. I am not claiming it is correctly TUNED - a single
fumbled check killing the tank inside one round is a balance question - but it
is the mechanic, not a phantom.

e5_miserable_commons wiping three rounds sooner is the same two changes: fires
now last as long as the re-roll says (Q-M03) instead of being force-cleared
after two ticks, and tank stacks are uncapped.

---

## A3, and the one red test

`test_adventures.gd :: test_the_mini_boss_is_still_winnable` is red. It was red
before this repair pass, at the same 0/24. The `_tank_swap_is_live` gate had
been added to save it and did not.

Measured at A3's own gear stage over the 24 seeds the test uses, adding
mechanics one at a time to an A3-shaped encounter:

| A3 mechanics live | clear rate |
|---|---|
| none | **24/24** |
| m01 only | **0/24** |
| m02 only | 3/24 |
| m03 only | 9/24 |
| all three (= shipped A3) | **0/24** |

The top row is the finding: **A3's boss autoattacks alone are a 100% clear**, so
docs/10 section 8's clock sizing for A3 prices the swings and nothing else, and
A3 then carries three mechanics on a six-person party. m01 is fatal by itself
for the reason in `handoff-mech-arms.md` item 3 - the tank has nobody to swap
with, the stacks climb, and the tank dies at a mean round of 4.8 against a
12-round target.

I did **not** retune to compensate, and I removed the gate that had quietly done
so. The content contradiction is written up as `handoff-mech-arms.md` item 3 and
as `q-mech-arms.md` Q-M01b.

---

## Docs written (proposals only; docs/15 untouched)

In `build/plan/q-mech-arms.md`:

- **Q-M12** - dead doc-link fixed. It cited
  `test_m12_escalates_and_still_terminates`, which does not exist; the test is
  `test_m12_still_terminates_inside_the_round_cap`.
- **Q-M01** - records that the stack has no ceiling, and why that is a reading
  of canon rather than a question (docs/10 section 10 M12 says "no cap" in as
  many words for another mechanic, so this vocabulary writes ceilings down when
  it means them).
- **Q-M01b** - new. What "swap required at 3" means with nobody to swap to.
- **Q-M03** - now describes the exit the sim actually has, and covers the
  no-zone case explicitly.
- **Q-M07** - now covers an m07 that does not name its stance.

---

## Tests

Suite: **1280 tests, 1 failing** - the pre-existing A3 red above. Baseline at
the start of this pass was 1267 with the same single red. Eight of the
difference are mine; the rest arrived from the other agents working in parallel.

| test | what it asserts | file |
|---|---|---|
| test_m01_steps_out_at_the_authored_threshold_and_not_before | swap_at <= stacks <= swap_at + swings on every handover, and that raising swap_at from 3 to 6 delays the handover | test_raid_sim.gd |
| test_m01_still_bites_an_encounter_that_only_asked_for_one_tank | m01 on a tanks_required 1 encounter still logs, still stacks, still says "nobody to swap with" - the deleted gate cannot come back unnoticed | test_raid_sim.gd |
| test_m03_without_an_escape_chance_is_a_zone_you_cannot_leave | Q-M03's permanent-zone case: no escape_chance_bp, nobody ever leaves | test_raid_sim.gd |
| test_an_encounter_with_no_ground_effect_cannot_set_anybody_on_fire | E2 and E3, five seeds each including the golden's 31337: no fire tick, no Fire token, no MIS_AVOIDABLE_DEATH | test_raid_sim.gd |
| test_m07_without_a_named_stance_demands_nothing_and_says_so | no invented default stance, no damage, and the gap is visible in a MECHANIC line | test_raid_sim.gd |
| test_m08_gives_the_boss_back_to_the_threat_table_between_windows | the "and then lets go" half, on a fixture with a gap between windows (E4's cadence tiles them end to end, so it cannot show this) | test_raid_sim.gd |
| test_an_unrecognised_stance_key_reads_back_as_the_same_default | "foo", "" and "SPREAD" all read back Stance.STACKED, like the absent key | test_combatant.gd |
| test_the_same_seed_replays_exactly | the determinism assertion the inertness test used to be doing under the wrong name | test_mistake_lines.gd |

Two existing tests were rewritten rather than added.
`test_m01_hands_the_boss_from_one_tank_to_the_other` keeps only the "a handover
happens" half; the threshold claim moved out into a test that can actually make
it. `test_m03_puts_raiders_in_the_fire_and_takes_them_out_again` asserted the
two-tick cap, which is gone; it now asserts an open-ended stay that always ends,
that no tick precedes an entry, and that some stay exceeds two ticks at 5000bp -
the audit's own acceptance criterion, which the old code made unreachable.

One was renamed: `test_m01_pins_a_one_tank_roster_at_the_cap_and_says_so` to
`test_m01_strands_a_one_tank_roster_and_says_so`, and it now asserts the stacks
climb PAST swap_at instead of being pinned at it.

`_synthetic` gained a `tanks_required` parameter (default 2, so every existing
caller is unchanged). It was hardcoded to 2, which is what made the dispatch
guard structurally blind to m01 being switched off for one-tank encounters.

Gates: parse_check OK (124 scripts), lint_no_global_classes OK, four-space
indentation throughout (a grep for a leading tab returns 0 in every file I
touched).
