# Handoff — agent `doclinks` (DW-A1, DW-A2, DW-A4, M6-FINAL-04)

Two things I could not do because I do not own the files: the nine dead anchors
in `docs/15-open-questions.md` (DW-A2), and the two non-docs files
`M6-FINAL-04` lists (`tools/lint_doc_links.sh`, `BACKLOG.md`).

The 91 dead **file** links in docs 01-08 are fixed and
`tests/unit/test_docs_links.gd` now guards them. That test also checks
fragments and prose filenames, and it **allowlists exactly the nine docs/15
fragments below** with a comment naming DW-A2/DW-A3 — so docs/15 can be fixed
without touching the test, and the allowlist entries simply go inert. Any *new*
dead anchor, in docs/15 or anywhere else, fails the suite today.

---

## 1. `docs/15-open-questions.md` — the nine dead anchors (DW-A2)

DW-A2 is right that this is blocked on DW-A3, and the reason is sharper than
"ambiguous": **two of the nine have no valid target at all today.** Q-31 names
two different questions in this one file —

| Q-31 | Where | What it asks | Has a heading? |
|---|---|---|---|
| upkeep | register row, `docs/15:454` | "Is there per-run **upkeep**?" — still OPEN | **no** |
| duplicate protection | heading, `docs/15:1066` | loot roll bias — DECIDED, implemented | yes |

`#q-31` at L1260 and L1421 both mean the *upkeep* one (their sentences are about
upkeep and payday), and a register-table row has no slug. So those two cannot be
repointed until DW-A3 gives that row an ID and an explicit anchor. The other
seven have a real heading to aim at.

**Recommended shape (what DW-A2 asks for):** put `<a id="q-nn"></a>` on its own
line immediately above each `### Q-nn` heading, and for the upkeep question an
`<a id="q-31-upkeep"></a>` (or whatever DW-A3 renumbers it to) on the row or a
new subheading. Then every link below is just `(#q-nn)` and survives future
title edits. The test reads `<a id=...>` tags as well as heading slugs, so this
works with no test change.

**If you would rather not add anchor tags**, these are the exact slugs that
resolve against the headings as they read today. Note `docs/15:1610`'s heading
embeds a link, which mangles its own slug into `...and-q-44q-44-was-wrong...` —
worth un-embedding while you are in there.

| Line | Old | New (long-slug form) | Target heading |
|---|---|---|---|
| 1202 | `[Q-31](#)` | `[Q-31](#q-31---duplicate-protection-with-no-mechanism-given-decided---implemented)` | 1066 — duplicate protection (the sentence is about loot roll bias) |
| 1260 | `[Q-31](#q-31)` | **blocked on DW-A3** — means the upkeep Q-31 (`docs/15:454`), which has no heading; needs an explicit anchor | 454 |
| 1421 | `[Q-31](#q-31)` | **blocked on DW-A3** — same, upkeep/payday | 454 |
| 1560 | `[Q-34](#q-34)` | `[Q-34](#q-34---a-wipe-costs-ten-ticks-of-recovery-and-a-retry-costs-one-resolved-for-the-click-count-comfort-items-still-open)` | 2019 — the ten-ticks ruling the sentence cites, *not* the 1235 resolution note |
| 1590 | `[Q-50](#q-50)` | `[Q-50](#q-50---what-shape-is-a-morale-history-decided---implemented)` | 1548 |
| 1610 | `[Q-44](#q-44)` | `[Q-44](#q-44---the-market-has-two-stock-ladders-and-no-price-for-the-stall-superseded-by-q-54q-54---the-stall-does-have-a-price)` | 1765 |
| 1614 | `[Q-44](#q-44)` | same as 1610 | 1765 |
| 1695 | `[Q-38](#q-38)` | `[Q-38](#q-38---three-docs-read-comfort-items-three-ways-decided---implemented)` | 1872 |
| 1765 | `[Q-54](#q-54)` | `[Q-54](#q-54---correction-the-market-stall-is-priced-and-q-44q-44-was-wrong-about-it-fixed---implemented)` | 1610 |

Slug rule the long forms follow (GitHub's, and what the file's existing working
anchors were written against): lower-case, drop every character that is not a
letter, digit, hyphen, underscore or space, then spaces become hyphens. Runs of
hyphens are **not** collapsed — `Q-24 - What` really does slug to `q-24---what`.
`_slug()` in `tests/unit/test_docs_links.gd` implements exactly this.

### One more docs/15 item, not a link

`docs/15:1270` names `06-town-and-guild-progression.md` in inline code. DW-A4
says to leave it — it is a historical note about a rename already made — so the
prose check allowlists it by name for that file only. If you delete or reword
that note, drop the allowlist entry in `test_docs_links.gd` with it.

---

## 2. `tools/lint_doc_links.sh` and `BACKLOG.md` (M6-FINAL-04)

M6-FINAL-04 wanted a shell linter wired into `tools/verify.sh`. I did not write
it: the same check now lives in `tests/unit/test_docs_links.gd`, which
`tools/verify.sh` already runs via the suite, so a second implementation would
be two things to keep in step. If the orchestrator still wants a standalone
script, the whole check is four functions in that file and is deliberately
dependency-free.

`BACKLOG.md:184` ("Sweep every doc for dead links and fix. File under M6
polish") is done and can be struck. Suggested closing line, for whoever owns
BACKLOG.md:

> Dead doc links — DONE 2026-09-10. 91 links across docs 01-08 repointed to the
> 00 §1.1 filename set (37 distinct bad slugs), docs/03's `docs/00-index.md`
> prose authority removed, and `tests/unit/test_docs_links.gd` now fails the
> suite on any dead doc link, dead anchor or dead prose filename. Nine anchors
> in docs/15 remain, tracked as DW-A2 and blocked on DW-A3.
