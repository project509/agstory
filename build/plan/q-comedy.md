# Proposed `docs/15-open-questions.md` entries — the mistake-line corpus

> **CONSUMED IN PART (W5-DOCS, 2026-09-15):** BL-NEXT+11, +12 and +13 are `docs/15` **BL-80** (the measurement re-derived off the committed goldens — e5_miserable_commons is 11 rounds / 44 mistakes, max 7 of one type; e3_commons_adventure fires Pulled Aggro 11 times; the "forecast pair" is measured now). BL-NEXT+14 (the writing envelope as machine checks) is still parked here; Q-NEXT+15 is the open human read and stays open.

**These are proposals.** `docs/15` was not edited (house rule 1). Entries continue the
**BL** series except BL-NEXT+15, which is a **Q** — a question only a human can answer.

Cited by `data/mistake_lines.json` `_notes[2]` and `_notes[6]`,
`sim/content/MistakeLines.gd:14` and `:36`, and `tests/unit/test_mistake_lines.gd:11`.
It was never written — the agent that planned it was killed mid-wave. Every deviation it
was meant to record is behind a named constant in `sim/content/MistakeLines.gd`; this is
the entry those five comments point at.

---

## BL-NEXT+11 — the line budget is 14 / 8, above the documented floor of 6

**The documented number.** `docs/07` §10.3 rule 4: "Each mistake type needs **at least 6
template variants** so a long raid does not repeat." `docs/14` §5.4 assertion 7 says the
same. Two docs, one number.

**Why six is not enough, measured rather than felt.** The shipped goldens are the evidence:
`e1_commons_starting` fires **Forgot to Taunt twelve times** inside one 22-round encounter,
and `e5_miserable_commons` fires **Went AFK and Attacked the Wrong Target eleven times
each** in fourteen rounds. At six variants the player watches the same sentence twice in a
fight they are watching tonight — which is `docs/07` §5.5's own named failure mode: it
"reads as a bug, not a joke".

**Ruling: the floor stays and a measured budget sits above it.**

* `MIN_VARIANTS := 6` — the doc floor, unchanged, and enforced on every type's **ungated**
  lines (see BL-NEXT+12).
* `HOT_VARIANTS := 14` — the measured worst case (12) plus headroom, for eight types.
* `COLD_VARIANTS := 8` — everything else, still comfortably above the floor.

All three are in `sim/content/MistakeLines.gd:37-39`. The docs are not overruled: 14 and 8
both satisfy "at least 6", so this is a tightening, not a contradiction. It is recorded
because a reader who finds 14 lines where the doc asks for 6 deserves to know it was
measured.

**The eight hot types** (`HOT_TYPES`, `:47-50`): `MIS_AFK`, `MIS_TAUNT_LAPSE`,
`MIS_WRONG_TARGET`, `MIS_HEAL_WRONG`, `MIS_AGGRO`, `MIS_ARGUMENT`, `MIS_FIRE`,
`MIS_MECHANIC_DROP`. Six are measured — each fires five or more times inside a single
shipped golden. `MIS_FIRE` and `MIS_MECHANIC_DROP` are a **forecast**, stated as one:
both are ungated by class and role and both sit at weight 8-9, so they are rare today only
because Tier 1's mechanic checks are thin. They go hot the moment `docs/10`'s Tier 2
encounters land, and writing their fourteen now is cheaper than noticing later.

**Legendary budget: 4 each** (`LEGENDARY_VARIANTS := 4`). `docs/07` §10.3 rule 4's second
sentence gives Legendaries their own variants and no number.
`e5_legendaries_raid` records two mistakes across seventeen rounds, so four is already
several fights' worth for a rarity the player owns one of.

---

## BL-NEXT+12 — the floor is measured on the lines ANY raider can draw, not on the row total

`docs/07` §10.3 rule 4's floor exists so a long raid does not repeat. A type whose extra
lines are all class-gated would satisfy a row-total check and still drop a Cleric back to
four lines — the exact repetition the rule forbids, hidden behind a passing count.

**Ruling.** `MIN_VARIANTS` is enforced on the **ungated subset**: variants carrying neither
a `classes` gate nor a `severity` gate (`MistakeLines._check_budget`). A gate is an EXTRA
on top of the floor and can only ever add. The per-type budget (14 / 8) is enforced on the
row total as well, so both properties hold.

---

## BL-NEXT+13 — one file, not eighteen; and the Legendary variants live in it

**One file.** `data/mistake_lines.json` carries all eighteen types plus the nine Legendary
sets. The alternative — one file per type, mirroring `data/legendaries/` — was rejected
because the corpus's load-bearing invariant is **global uniqueness of the line text**: two
types wearing the same joke reads as a bug rather than a callback. That check is one pass
over one document; across eighteen files it becomes a cross-file validator nobody would
write, and the writing pass would lose the ability to read the whole corpus at once, which
is the only way a human can tell whether it is funny.

**Legendary variants live here too**, not in `data/legendaries/*.json`. This one is
genuinely arguable and the counter-argument is real: `dialogue_barks` already lives in each
Legendary's own file, so a reader could reasonably expect their mistake lines beside them.

**Ruling: this file, for three reasons.**

1. The uniqueness check above spans the whole corpus. A Legendary line duplicating a type
   line is the same defect, and it would fall between two loaders.
2. `data/legendaries/*.json` is a *character* record — name, portrait, backstory, morale
   rules, quirk. A mistake line is not a property of the character, it is a property of a
   **failure the character committed**, and its gate is a mistake type id
   (`legendary_variants_for(def_id, type_id)`), which is this corpus's vocabulary and not
   that file's.
3. `MistakeLines._validate_coverage()` derives the nine expected `legendary_<class>` ids
   from `Enums.all_classes()`, so adding a tenth class fails loudly here. Split across
   nine files, a missing set is a missing file, which is a much quieter failure.

**Revisit if** the Legendary files ever gain their own line-shaped content beyond barks;
at that point one loader owning both would be worth the cross-file check.

---

## BL-NEXT+14 — rules 1 and 3 as machine checks, and the envelope comes from the doc's own sample

`docs/07` §10.3's five rules are written for a human reviewer. Three of them are
checkable; the checkable form of each was taken from the doc's own authored text rather
than from taste, because the doc's sample block **breaks its own rule 1**.

**Rule 1, "one sentence".** The sample's *"Bob assumed someone else was handling it. Bob
was the someone else."* is two sentences and names Bob twice. The rule's stated intent is
"the joke is in the sentence, not in a paragraph", so the shipped envelope is the doc's own
widest authored line: `MAX_SENTENCES := 2`, `MIN_ACTOR_TOKENS := 1`,
`MAX_ACTOR_TOKENS := 2`. A line with no terminator at all fails outright.

**Length.** `docs/13` §11.1 sets the log's measure at "≤ 74 characters"
(`LOG_MEASURE_CHARS`). The joke line is indented 24px under its mistake header so it may
wrap; `MAX_LINE_CHARS := LOG_MEASURE_CHARS * 2` is the point past which a one-sentence gag
has become a paragraph on screen.

**Rule 3, "never explain the mechanic".** As a case-insensitive substring test:
`BANNED_SUBSTRINGS := ["threat", "hp", "dps", "cooldown", "mitigat", "%"]`. Every one is
arithmetic the structured entry already carries and `docs/07` §10.2 tier 2 already prints.
This is a blunt instrument on purpose — it is a **necessary** condition, not a sufficient
one, and BL-NEXT+15 is what covers the rest of rule 3.

**The token contract.** `{actor}` is the only substitution token, because it is the only
field a `Mistakes.MistakeEvent` can resolve: the event carries `actor_id`, type, severity,
round and cascade, and **no target**. `docs/07` §10.3's own sample line "Cindy heals
Natsuna…" names a second person who has nowhere to come from at render time, so the
shipped variant of that line is adapted rather than copied. A `{target}` or `{tank}`
slipping in would be a crash waiting for one specific fight, which is why an unknown token
is a load-time error and not a runtime fallback.

**No proper nouns.** `docs/03` §5.6 says "DO NOT INVENT NAMES" and eight of the nine
Legendaries have none. A capitalised word that is not opening a sentence is rejected
(`MistakeLines._stray_capital`), which also catches a second raider's name in a type line —
the thing `{actor}` cannot substitute for.

**Rules 2 and 5 are NOT checkable** and no check pretends to cover them. "The raider is a
person with a reason" and "never blame the player" are judgements. They are BL-NEXT+15.

---

## Q-NEXT+15 — the corpus has not been certified funny, and a machine cannot do it

**Status: OPEN. This is a question for a human, not a ruling.**

`docs/16` R-3 names "the comedy does not land" the project's **top risk** and says plainly
that nothing in the doc set can prove otherwise. The split of labour in
`sim/content/MistakeLines.gd` is deliberate and it is a split, not a solution: the
validators prove SHAPE — coverage, budget, global uniqueness, resolvable tokens, sentence
count, no mechanic-explaining, no proper nouns — and **a human proves FUNNY**.

**What is unproven, precisely:** rule 2 (the raider is a person with a reason, not a random
number generator) and rule 5 (never blame the player; affectionate exasperation, not
scolding). Both are the whole point of the corpus and neither is machine-checkable.

**What the human read must produce.** A pass/fail per line against rules 2 and 5, and a
verdict on the three borderline rule-3 lines and `MIS_ARGUMENT.07` listed in
`build/plan/q-debt.md` §3 — those are where a reviewer should start, because they are the
lines where the machine check and the intent of the rule disagree.

**Until then**, the backlog's comedy line is not done, and `M5-COMEDY-12`
("'genuinely funny' cannot be self-certified") stays open regardless of how green the
suite is.
