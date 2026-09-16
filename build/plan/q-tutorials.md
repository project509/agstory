# Proposed docs/15 build-loop entries — M5 tutorials (key `tutorials`)

> **CONSUMED IN PART (W5-DOCS, 2026-09-15):** the skip fork (:86-113) and the docs/13 addendum (:115-140) are `docs/15` **BL-79**, with the switch corrected to `RaidPlan.SKIPPED_TUTORIAL_STAYS_ON_BOARD`; docs/13 §5's S09 cell lists the skip panel. The first three entries (the mechanic budget, the HP column, `tanks_required: 0`) are still parked here and still unnumbered.

Five rulings this slice made. **Numbers are not claimed here** — six agents ran in
parallel this wave and BL-67 was the highest declared entry when I started, so the docs
owner should assign the next free numbers in order. Nothing in `sim/`, `game/`, `data/`
or `tests/` cites these by number, deliberately: `tests/unit/test_docs_links.gd:284`
walks `res://data` and `.gd`/`.json` alike and fails the suite on a `BL-nn` citation
docs/15 does not declare yet. Every code comment points at `build/plan/q-tutorials.md`
instead; those pointers should be rewritten to the assigned ids once these land.

Copy the entries below in the file's existing heading style, each preceded by its
`<a id="bl-nn"></a>` anchor.

---

### BL-?? - Adventure 0 has no mechanics and the validator budgets one per star *(DECIDED - implemented)*

**Owner:** [10 §6](./10-content-and-encounters.md) / [10 §9.1](./10-content-and-encounters.md) - **Signal:** Loud - the first fight in the game could not be authored at all

`sim/model/Encounter.gd`'s structural block enforces two rules that Adventure 0 cannot
satisfy together: `stars` must be 1-5, and `mechanics.size()` must EQUAL `stars`.
[10 §9.1](./10-content-and-encounters.md) specifies Adventure 0 as "1 x 350 HP, raw swing
20, 1/round, **no mechanics**, target rounds 6". There is no (stars, mechanics) pair that
satisfies both, so the encounter the whole onboarding rests on was unauthorable.

| Option | Cost |
|---|---|
| Give A0 one mechanic and `stars` 1 | Contradicts [10 §9.1](./10-content-and-encounters.md) in terms, and puts a boss mechanic in the fight whose entire job is teaching the UI |
| Allow `stars` 0 | Breaks the board's star display and `Enums.ENCOUNTER_STARS`, for one record |
| Relax the equality to `<=` everywhere | Deletes the rule [10 §6](./10-content-and-encounters.md) calls load-bearing for all 42 encounters, silently |

**Decision: exempt the two tutorial slots from the EQUALITY, not from the budget, and
only downward.** `TwgEncounter.TUTORIAL_SLOTS := ["A0", "TR"]` and `is_tutorial()`; the
check fires on `!= stars` for everything else and on `> stars` for a tutorial. A tutorial
may carry fewer mechanics than its stars and never more. Stars stay 1-5 untouched.
Pinned by `tests/unit/test_encounters.gd::test_the_mechanic_budget_is_relaxed_for_tutorials_and_only_downward`,
which asserts all three cases including the one that must still fail.

---

### BL-?? - The tutorials' HP column is docs/10 §9.1's third instance of the stage-A error *(DECIDED - re-derived)*

**Owner:** [10 §9.1](./10-content-and-encounters.md) / [08 §9.1a](./08-stats-and-formulas.md) - **Signal:** Silent, and it ships two unwinnable tutorials

[10 §9.1](./10-content-and-encounters.md) prints 350 HP for Adventure 0 and 1,055 for the
Tutorial Raid, and states its own derivation: "~58/round for 4 (1/3 of doc 08 §9.1 stage
A) x 6" and "~88/round for 6 x 12". Both are **stage A** figures — full Tier 1 Adventure
gear — and both tutorials are played at **stage 0**, because nothing has dropped yet.
This is exactly the error [BL-28](#bl-28) found and corrected for A1-A3: "The 88 figure
was 5.3x too high for A1."

**Decision: re-derive off [08 §9.1a](./08-stats-and-formulas.md) stage 0, and say so
loudly in the data file.** Stage 0 = 16.5/round over the benchmark six = 2.75/raider.
Adventure 0 at party 4 = 11.0 x 6 rounds = **66**. Tutorial Raid at party 6 = 16.5 x 12 =
**198**. The raw swings (20 x1 and 15 x2) are NOT re-derived — [10 §9.1](./10-content-and-encounters.md)
states the resulting unhealed clocks on purpose ("a tutorial demonstrates a fail state, it
does not impose one"), and enrage stays `ceil(1.4 x target_rounds)` = 9 and 17, the 17
matching the doc's own printed value independently.

**Owed against [10 §9.1](./10-content-and-encounters.md):** its HP column should be
corrected to 66 / 198 with a pointer to [08 §9.1a](./08-stats-and-formulas.md), the same
way [10 §8](./10-content-and-encounters.md)'s was.

---

### BL-?? - `tanks_required: 0` and an absent field are the same value *(DECIDED - refused at load)*

**Owner:** [15 Q-47](#q-47) / [10 §9.1](./10-content-and-encounters.md) - **Signal:** Silent, tier-wide if fixed the wrong way

[10 §9.1](./10-content-and-encounters.md) fields Adventure 0 with "no tanks required";
[Q-47](#q-47) rules "Per-fight `tanks_required` (default 2, **tutorials 1**)". Beneath the
doc conflict is a code trap: `sim/model/Encounter.gd` defaults an absent `tanks_required`
to 2 and `game/core/RaidPlan.gd`'s guard reads `> 0`, so an authored **0 silently becomes
2** — the opposite of what the author asked for, with no error anywhere.

**Decision, two parts.** (a) Both tutorials are authored `tanks_required: 1`, resolving
the doc conflict by the register, with the departure noted in the JSON `_notes`. (b) The
trap is closed by REFUSING `tanks_required <= 0` in the validator rather than by loosening
RaidPlan's guard — loosening it to `>= 0` without also changing Encounter's default from 2
to -1 would make every encounter that omits the field require zero tanks, a silent
tier-wide difficulty change. Pinned by
`tests/unit/test_encounters.gd::test_validator_refuses_a_zero_tank_requirement`.

---

### BL-?? - Does a skipped tutorial leave the board, and does a skip count as onboarding? *(DECIDED - switch + one reading)*

**Owner:** [10 §9.3](./10-content-and-encounters.md) / [01 §8.3](./01-core-loop.md) / [15 Q-90](#q-90) - **Signal:** Two docs, opposite answers

Two live forks, resolved together because they are the same question asked twice.

**Fork 1 — what happens to the mission.** [10 §9.3](./10-content-and-encounters.md)'s
Re-run row (marked 🔷 PROPOSED): "a skipped tutorial stays on the board and is replayable
for gold, but its trinket is gone for the run". [01 §8.3](./01-core-loop.md)'s
Irreversibility row and [Q-90](#q-90): "Skip is permanent — the mission leaves the board
and the reward is gone." **Defaulted to the register**, which is this project's tie-break
and which [10 §9.3](./10-content-and-encounters.md) itself marks proposed. Implemented as
`AdventureBoard.SKIPPED_TUTORIAL_STAYS_ON_BOARD := false`, a named switch with both
citations on it, so flipping it is one line rather than an archaeology exercise.

**Fork 2 — does a skip complete onboarding?** [05 §6.3](./05-morale.md) gates disband on
having "completed Adventure 0 and the Tutorial Raid", and a skip is not a completion. But
the skip is permanent, so a player who skips both would be exempt from disband **forever**.
**Decision: a RESOLVED tutorial counts, cleared or skipped.** The gate exists to protect a
player who has not yet seen the game, not to reward clearing. `GameState.rung_resolved()`
is the predicate, and it is what the board's ladder gate asks instead of `has_cleared()` —
without that, "skip" would have meant "soft-lock the campaign".

**A third thing decided by omission and worth writing down:** a content set with **no**
tutorials leaves `onboarding_complete` **false**. This is the flag that arms a whole-roster
wipe, and "the onboarding file failed to load" is not consent to that.

---

### BL-?? - The tutorial skip prompt is a panel on the board, not a screen after ConfirmRaid *(DECIDED - docs/13 addendum)*

**Owner:** [01 §4.2](./01-core-loop.md) / [13 §5](./13-ui-ux.md) - **Signal:** Quiet - a named state with no screen to put it in

[01 §4](./01-core-loop.md)'s state chart names `TutorialSkipPrompt`, reached from
`ConfirmRaid`. [13 §5](./13-ui-ux.md)'s S01-S16 inventory has no screen for it, and this
codebase has no dialog primitive at all (`grep -rn 'AcceptDialog|ConfirmationDialog' game/`
returns nothing).

**Decision: fold it into S09, the Adventure's Board**, as a warning Label plus a
`Skip the tutorial` Button in the Selected Notice sidebar, beneath the existing
`Go to prep` CTA. [01 §8.3](./01-core-loop.md)'s "Where the skip lives" row is 🔷 PROPOSED,
not canon; canon requires only that the player be warned. The board is where the rung is
chosen and where the notice already prints its Potential Rewards, so the forfeit is
legible **next to the thing being forfeited** instead of one screen later — and a player
who skips never has to enter prep at all.

Warning copy meets [10 §9.3](./10-content-and-encounters.md)'s two requirements verbatim:
it names the item and its stat (read off the granted item itself, with
[09 §10.2](./09-items-and-itemization.md)'s authored pair as the fallback) and says
plainly "It is not a good trinket". Every string is a Label or a Button, because the
screen tests collect only `Label.text` and `Button.text` — a warning in a tooltip would be
the one canon-mandated sentence in the game that nothing tests.

**Owed against [13 §5](./13-ui-ux.md):** S09's contents list should gain the skip panel.
No S17.
