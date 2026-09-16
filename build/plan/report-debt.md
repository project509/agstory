# report — debt

Six queued-debt items nobody had cleared. Written as each item finished, not at the end.

Owned files: `build/plan/`, `sim/core/Reputation.gd`, `sim/core/Recruitment.gd`,
`sim/content/MistakeLines.gd`, `sim/core/Quirks.gd`, `sim/content/LegendaryPool.gd`,
`tests/unit/test_mistake_lines_corpus.gd` (new), `tests/unit/test_quirks.gd` (new),
`tests/unit/test_reputation.gd`, `tests/unit/test_legendaries.gd`, `game/ui/Type.gd`,
`game/ui/Theme.gd`.

Baseline at start: 1282 tests green.

---

## 0. What the audit got wrong

`build/plan/audit.json` lists **M3-TUNE-03** and **M3-TUNE-04** as `not-started`. Both are
in fact SHIPPED: `data/reputation.json` exists, `sim/core/Reputation.gd:60-250` is the
loader with docs/03 §9's three load assertions plus the enum-length fourth, and every
`Reputation` accessor already reads `tables()`. The audit snapshot predates that wave. The
residue the audit does not describe is what item 1 below is about — the extraction stopped
one file short.

_(sections appended below as each item lands)_
