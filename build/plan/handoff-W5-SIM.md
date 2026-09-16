# Handoff — W5-SIM (key `W5-SIM`)

Edits needed in files this unit does not own. Shape: `## N. <path>:<line>` then an `old:`
block and a `new:` block, one edit per heading.

Proposed docs/15 entries are in `build/plan/q-W5-SIM.md` (W5-DOCS owns docs/15).

## 1. docs/10-content-and-encounters.md:236 (the §6 field table has no `force_mistake_round` row — audit M5-TUT-12's risk clause; the field is authorised by §9.1 prose only, so the next encounter author cannot know it exists)

old:
```
| `comedy_line` | string | **Required.** One or two sentences: what makes this funny when it goes wrong. If it cannot be filled in, the encounter is a chore and should be cut. Amended from "one sentence" by [15 BL-76](15-open-questions.md#bl-76) — half the shipped lines are two, they are the better writing, and the rule was never enforced by anything |
```

new:
```
| `comedy_line` | string | **Required.** One or two sentences: what makes this funny when it goes wrong. If it cannot be filled in, the encounter is a chore and should be cut. Amended from "one sentence" by [15 BL-76](15-open-questions.md#bl-76) — half the shipped lines are two, they are the better writing, and the rule was never enforced by anything |
| `force_mistake_round` | int, default 0 | §9.1's content-level override: on this round one raider makes a scripted Minor mistake regardless of the roll (implemented in `sim/core/RaidSim.gd`, picked from the seeded Rng — see [15](15-open-questions.md) W5-SIM entries). **Exactly one encounter may carry it** (Adventure 0, `3`); the loader refuses a negative value or one past `target_rounds` |
```
