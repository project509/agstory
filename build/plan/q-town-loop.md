# Proposed `docs/15-open-questions.md` entry — the town ladder and the Blacksmith gate

**This is a proposal.** `docs/15` was not edited (house rule 1). The entry continues the
**BL** series.

Cited by `sim/core/Buildings.gd:61`, at the moment the `blacksmith` ladder rows were
added. It was never written; this is the record that comment points at.

---

## BL-NEXT+10 — the Blacksmith's rank gates ship as authored, and `docs/03` §11 Q8's alternate reading does NOT

**What is in the code.** `sim/core/Buildings.gd::LADDERS["blacksmith"]` carries
`docs/02` §11's three rows verbatim — L1 Respected / 300 G, L2 Established / 700 G,
L3 Renowned / 1,600 G — plus one structural fact that separates this building from the
other four: `base_level("blacksmith")` is **0**, because unlike the Guildhall, Tavern,
Market and Board it is not standing when the game begins. Its first level is a purchase.

**The problem.** Every one of those three gates is ❓ OPEN in `docs/02` §11's own
"canon status" column, because canon's heading reads "Blacksmith (Maybe)". `docs/03` §11
Q8 is the unanswered question:

> Is the Blacksmith rank-gated at all? … If the Blacksmith is cut, Respected loses its
> town unlock and needs a replacement, or the ladder has a hole at rank 3.
> **Proposed default:** Blacksmith opens at Respected if it ships; if cut, Respected
> instead unlocks the Tavern expansion (moved down from Renowned).

**Ruling 1: the rows ship, the DECISION does not.** The table is `docs/02` §11's own
numbers, so putting them in `LADDERS` invents nothing. What keeps this from being "the
Blacksmith shipped" is the `blacksmith` feature flag `docs/14` §5.2 requires:
`game/screens/Town.gd` asks the flag **before** it asks the rank, so with the flag off
(its `FLAG_DEFAULTS` value) the rows are unreachable data. Adding a ladder to a building
nothing can open is not a design decision; leaving the ladder empty and hard-coding the
gate at the call site later would be.

**Ruling 2: Q8's alternate reading is deliberately NOT implemented.** Q8's fallback moves
the Tavern's L4 rung down from Renowned to Respected. That is a 🔷 PROPOSED gate on a ✅
CANON building (`docs/03` §7 marks Renowned's "Tavern expansion" and `docs/02` §11 prices
Tavern L4 at Renowned / 1,200 G), and it would be moved to satisfy an ❓ OPEN one. Moving
canon-adjacent structure to accommodate a "Maybe" is the wrong direction, and it is
irreversible in a way the flag is not: if the Blacksmith later ships, the Tavern rung has
to move back and every save between the two states has bought a rung at the wrong rank.

**What that costs, stated.** With the flag off, **Respected's town unlock is empty**.
`docs/03` §7's row for Respected reads "Blacksmith opens" and nothing else, so a player at
rank 3 sees no new building — the hole Q8's own text predicts. That is the honest state of
the ladder, not a bug to paper over, and it is the single strongest argument for answering
Q8 rather than leaving it.

**What a human must decide.** Only one thing: *does the Blacksmith ship?* If yes, flip the
`blacksmith` flag and both rulings above become moot. If no, Q8's fallback needs a fresh
look — and the alternative worth putting beside it is giving Respected a *different*
unlock rather than moving the Tavern's, because `docs/02` §11's Market L3 already lands at
Respected and could carry the rank's visible change on its own.

**Do not** resolve this by editing `LADDERS`. The rows are the doc's; the flag is the
decision.
