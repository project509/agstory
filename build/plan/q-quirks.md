# Proposed `docs/15-open-questions.md` entries — Legendary quirks and the BIG-dumb counters

> **CONSUMED IN PART (W5-DOCS, 2026-09-15):** BL-NEXT+7 (`BENCH_BREAKS_WIPE_STREAK`) and BL-NEXT+8 (`BULLET_TRIGGER_COUNTS_CAPPED`, readings (i)-(iii), the seven-of-eighteen caveat) are recorded in `docs/15` **BL-59** (rows 2 and 4 and the decision paragraph, corrected to three live). BL-NEXT+5, +6 and +9 are still parked here.

**These are proposals.** `docs/15` was not edited (house rule 1). Entries continue the
**BL** series except where noted; BL-58 already exists and is OPEN, and nothing here
closes it.

Cited by `game/core/GameState.gd:132`, `:784`, `:1356` and
`sim/content/LegendaryPool.gd:100`. It was never written — the agent that planned it was
killed mid-wave — and every deviation it was meant to record is already behind a named
constant. This is the record those four comments point at.

---

## BL-NEXT+5 — which doc owns the quirk spec: `docs/06` §4, not `docs/07`

**The problem.** `docs/04` §11.2's table cell reads "One class-flavoured mechanical gift;
specced in doc 07, named here". `grep -ci quirk docs/07-combat-simulation.md` returns
**0** — the word does not appear once in the doc that is said to own it.

**Why the pointer is wrong rather than merely unfilled.** `docs/04` already answers its own
question in the other direction, twelve pages later: its Related-documents block (`:661`)
reads "[06 — Classes & Roles](06-classes-and-roles.md) — owns the class kits behind the
nine canon classes, **the Legendary `quirk` field**, and the 12 raid slots…". So the doc
contradicts itself — §11.2 says doc 07, the sibling list says doc 06 — and only one of the
two can be right. (Audit item Q58-2 diagnoses this as an off-by-one from an older
numbering in which the classes doc was 07, and cites three dead links at `:662-664` as the
evidence. Those links have since been repaired; the §11.2 cell was not. The contradiction
is what remains.)

**Proposed answer: `docs/06` §4 owns it.** That section is already the home of every
per-class "Distinguishing mechanic" and "Failure mode" row (`docs/06:96` "## 4. Class kit
specs", `:106` Warrior **Threat Lock**, `:129` Cleric **Focused Heal**). `docs/07` §1's own
rule of thumb keeps it to cadence, phase order and roll sites — a per-class gift is not
one of those. Concretely: `docs/06` §4.x gains one **Legendary quirk** row per class kit,
`docs/07` gains nothing, and `docs/04` §11.2's cell changes to "specced in doc 06 §4".

**Why this is a question and not a ruling.** It moves a spec's owner between two canon
docs. The build loop can point out that the pointer is broken; it should not choose the
new owner alone. The exact edits are staged in `build/plan/handoff-quirks.md` §1 and are
**not applied**.

**Blocking.** BL-58 (the spec itself) cannot start until this is answered: a designer told
to "spec the quirks in doc 07" opens the combat-sim doc and finds no per-class section to
put them in.

---

## BL-NEXT+6 — the `legendary_quirks` flag is an inert-seam flag, not a "Maybe" flag

`docs/14` §5.2's flag list is canon's "Maybe" systems — Blacksmith, crafting, salvage,
level-ups, wishlists — each behind a flag because the game "must boot and be completable
with every flag off". `game/core/GameState.gd`'s `FLAG_DEFAULTS` carries a sixth id,
`legendary_quirks`, that is **not** one of those.

**Ruling: it stays, and the reason is different.** Legendary quirks are canon — `docs/04`
§11.2 promises every Legendary one — so the system is not a "Maybe". What is missing is the
SPEC (BL-58, OPEN). The flag is what makes an unspecced seam provably inert:
`sim/core/Quirks.gd` ships `SPECS := {}` and `is_live()` requires the flag **and** a spec
row, so neither half alone can move a number.

**Why both halves.** A flag alone would let somebody turn quirks "on" before anybody wrote
what they do; a spec row alone would fire while BL-58 is still open. Requiring both means
the spec pass is a table plus a flag flip, and nothing in between is reachable.

**Asserted.** `tests/unit/test_quirks.gd` fails if `SPECS` is non-empty while every
authored `quirk.status` still says OPEN, and asserts every hook returns its identity value
at **both** flag settings.

**When to close.** Delete this entry the day BL-58 is DECIDED and `SPECS` has nine rows;
the flag then becomes an ordinary §5.2 row or goes away entirely.

---

## BL-NEXT+7 — `docs/04` §11.3 condition 2: does a bench break the wipe streak?

**The text.** "Wiped on the same boss 3 times in a row with them in the raid."

**The ambiguity.** The doc says nothing about a raider benched for one of the three
attempts. Two readings:

* **false (SHIPPED DEFAULT)** — a bench neither extends nor breaks the streak. "With them
  in the raid" describes *which wipes count*, so a night they did not attend is simply not
  one of them.
* **true** — a bench breaks it, on the reading that "in a row" means the attempts in a row
  and a skipped one interrupts the sequence.

**Switch.** `game/core/GameState.gd::BENCH_BREAKS_WIPE_STREAK := false`.

**Why that default.** It is the one that cannot be reached by accident: it takes three
wipes the raider was actually present for, which is what the sentence describes. It is
also the one that does not double-punish — a player who benches a Legendary is already
answering to condition 1 (`consecutive_benched`).

**What the other reading would cost.** `true` makes the condition much harder to reach in
a roster larger than the party size, because ordinary rotation would keep resetting it,
which would quietly retire one of canon's five "BIG dumb" triggers.

---

## BL-NEXT+8 — `docs/04` §11.3 condition 4: what counts as a bullet "triggering"?

**The text.** "Any of their own backstory bullets triggered 3+ times in one tier."

**The ambiguity.** "Triggered" has three readings and they fire at very different rates:

1. the listened-for event happened at all;
2. it happened **and** moved this raider's morale by a non-zero amount, after `docs/04`
   §11.3's 0.35 negative multiplier and `docs/05` §7.6's caps;
3. it happened and the tag actually amplified or dampened the delta.

**Switch.** `game/core/GameState.gd::BULLET_TRIGGER_COUNTS_CAPPED := true` ships (2);
`false` ships (1).

**Why (2) is the default.** It is the reading the code can PROVE. A trigger swallowed by a
cap did nothing to the character, and suspending a Legendary's morale floor on an event
they never felt is exactly the guess canon's "unless you are BIG dumb" forbids. Reading (1)
fires far sooner, because the caps swallow a lot.

**Why (3) is not offered at all.** Only seven trigger families are mapped in
`BackstoryPool.TRIGGER_TAGS` out of `docs/04` §8.3's eighteen tags, so several Legendaries
carry no bullet that could ever amplify anything. A condition already structurally
unreachable for some characters should not be narrowed further.

---

## BL-NEXT+9 — five of the nine authored quirks name mechanics the sim does not have

Recorded here because the spec pass (BL-58) will hit it on day one, and because it is the
reason this seam is four hooks rather than nine.

**Has substrate (4).** `quirk_warrior` (`_assign_tanks()` sets `is_main_tank`; MIS_AGGRO and
MIS_TAUNT_LAPSE exist) → `Quirks.tank_priority` / `Quirks.immune_to`. `quirk_rogue`
(threat is real and `_pick_enemy_target()` reads it) → `Quirks.threat_multiplier`.
`quirk_monk` (`Mistakes.roll()` already takes `relief_bp`, which `docs/11` §7's Steady
Hands feeds) → `Quirks.relief_bp_bonus`. `quirk_shaman`'s CLASS has a hook
(`Formulas.shaman_chain_heal`) even though its stated effect does not.

**No substrate (5).** `quirk_shaman` "buffs outlast the pull" — no buff or duration system
exists anywhere. `quirk_bard` "keeps the melee swinging through a phase change" — the Bard
has no ability at all and there is no phase-change concept; doubly blocked by `docs/06` §5
"The Bard problem ❓ OPEN" and `docs/07` OQ-10. `quirk_cleric` "finds mana that was not,
strictly, there" — Mana is a magnitude stat, not a pool, and `docs/07` OQ-1 is unresolved
on that exact point. `quirk_mage` "first spell after a wipe recovery lands harder" — there
is no in-encounter recovery event. `quirk_wizard` "knows the enrage timer" — ENRAGE fires,
but the sim has no pre-enrage decision to inform.

**What the designer must choose, per quirk in the second group:** restate the effect
against a mechanic that exists, or scope the subsystem. `docs/04:397`'s own Natsuna example
already contains a fully-formed restatement — `quirk: chain_heal_never_misses_third_target`,
which is MIS_CHAIN_FIZZLE by another name and maps straight onto `Quirks.immune_to` — and
it silently disagrees with `data/legendaries/shaman.json`'s authored `quirk_shaman`. Resolve
that contradiction in the same pass.

**`quirk_bard` should be deferred outright.** Eight quirks can ship; the ninth cannot, and
saying so now is cheaper than discovering it at the end of the spec pass.
