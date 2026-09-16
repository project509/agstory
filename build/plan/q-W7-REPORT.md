# q-W7-REPORT — the docs/15 rows this unit proposes (W7-DOCS owns the file)

One row. Nothing here is a question for the designer: BL-119, BL-139, BL-141 and Q-53 were ruled and are
built as ruled. This records a stand-in that must be retired, so it cannot be forgotten.

## BL-<next> — the reputation feed glyph is a stand-in until W9-ART draws it

**Row text (proposed):**

> **BL-<next> — `Icons.ALIASES["log/reputation"]` is a stand-in, not a glyph.** LOOP-13's reputation
> feed row (the kind `GameState._award_reputation` writes) asks `Icons.at("log", "reputation")` for a
> 22px glyph. `tools/gen_icons.lua` draws none and is not owned in wave 7, so `game/ui/Icons.gd` maps the
> name to the rank sigil the header chip already wears (`rank_known`) through a new `ALIASES` table,
> consulted only when a name has no file of its own. W9-ART draws `log_reputation.png`; the alias row is
> deleted in the same commit and nothing else changes, because the call site names the glyph, not the
> file. Status: built, stand-in art. Owner: W9-ART.

**Why it is a row and not a comment:** the project has shipped six mechanisms that were "built" and never
"armed" (LESSONS). An alias that resolves silently is exactly the kind of thing that survives to 1.0
wearing the wrong picture; the row is what makes its removal somebody's job.
