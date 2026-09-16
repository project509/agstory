# handoff-W7-REPORT — edits this unit needs in files it does not own

Written first, per the wave rules. **It is empty on purpose: this unit needs no edit in any file it
does not own**, and the paragraphs below say why for each thing that looked like it would need one.

- **`game/ui/Theme.gd` — `LabelDamageDealt`.** UI-34's RaidView line names the variation as a STRING
  (§0.2: a string-named theme variation falls back harmlessly, so it may be named a wave early).
  `RaidView._number()` sets it only when `Theme_.get_theme().get_type_variation_base("LabelDamageDealt")`
  answers non-empty, and keeps today's `TEXT_BODY` colour override until then — so W7-STAGE registering
  the variation this wave turns it on with no edit here, and its absence changes nothing.

- **`game/screens/RaidView.gd` `_stage()` and `game/screens/Results.gd` `_scene()`.** These are
  `handoff-W7-STAGE.md` §2/§3 — W7-STAGE's edits INTO this unit's files, applied by the orchestrator at
  the close (the plan says so in W7-REPORT's Findings line). Nothing for this unit to do; both call
  sites were left exactly as they were so the handoff still applies cleanly.

- **`game/core/GameState.gd` — the reputation feed row and its glyph.** LOOP-13's feed line is W7-SAVE's
  (`_award_reputation` logs "+N reputation — the town heard."). This unit owes it only the glyph, and
  that is `Icons.at("log", "reputation")` in `game/ui/Icons.gd`, which this unit owns. The tally cell
  reads `Reputation.award_for(...)` directly — a pure call on facts the state already keeps, no new
  field, so no GameState edit.

- **`tools/gen_icons.lua` — the real `log_reputation.png`.** Not owned by any wave-7 unit (W9-ART's), so
  the name is served by `Icons.ALIASES` from the existing `rank_known` file at 22px, exactly as the
  contract's Assets line directs. The retirement note is in `build/plan/q-W7-REPORT.md` for docs/15.

- **`docs/15-open-questions.md`.** Owned by W7-DOCS this wave. The one row this unit proposes is in
  `build/plan/q-W7-REPORT.md`.
