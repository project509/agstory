# q-W5-TESTS — wording for docs/15 (W5-DOCS owns the file)

W5-TESTS may not edit docs/15. Two things below: (1) the BL-59 sentence that names the tests now
holding condition #4, which W5-DOCS's own correction says are "owed with this correction, not by it";
(2) the M6-PLAY-02 finding — NOT a new open question (the harness found a code bug, not a dead end —
handoff-W5-TESTS.md #1-#3), recorded here so the audit closure has a paper trail.

## 1. docs/15-open-questions.md — BL-59, the tests sentence (audit Q59-4 (2))

The three tests exist now, in `tests/unit/test_game_state.gd`, and each firing is a REAL
`record_attempt()` on the authored Shaman (her bullets read from `data/legendaries/`), not an injected
count. In W5-DOCS's corrected BL-59, the closing paragraph's last sentence:

old:

    per-condition tests for #2 and #4 (three firings inside one tier set `bullet_3_this_tier`,
    three spread across a tier change do not, a trigger the subscription gate swallows does not
    count) are audit `Q59-4` (1) and are owed with this correction, not by it.

new:

    per-condition tests for #4 landed with audit `Q59-4` (1) (W5-TESTS, 2026-09-15), in
    `tests/unit/test_game_state.gd`: `test_three_wipes_her_own_bullet_hears_in_one_tier_are_big_dumb`
    (three wipes Natsuna attends on three DIFFERENT rungs — so #2 stays out of the verdict — set
    `bullet_3_this_tier` on the third and print row 4's own "You did the one thing they told you not
    to"), `test_the_same_three_wipes_spread_across_a_tier_change_are_not` (two at Tier 1, Known
    unlocks Tier 2, the third counts as the FIRST of the new tier: `bullet_tier` follows
    `highest_unlocked_tier()`), and `test_a_trigger_the_subscription_gate_swallows_does_not_count`
    (four benched runs fire "benched" three times; a Common carrying `hates_being_benched` beside her
    is credited, she is not — reading (ii)). #2 (`wiped_3`) still has no per-condition test of its
    own; the first of the three above asserts only that it did NOT fire.

(If W5-DOCS's paragraph has moved on from that sentence, the fact to carry is the three test names and
that they drive `record_attempt()` rather than the counter.)

## 2. M6-PLAY-02 — the finished harness found no dead end; it found a bug

The audit's step (6) asks for a docs/15 entry "only if the finished harness finds a real dead end".
It found one STUCK run (seed 1000, day 6) and it is not a dead end: `GameState.rest_until_recovered()`'s
"stalled" guard summed the roster's morale, and six raiders drifting down while six drift up cancel to
the fourth decimal, so a rest that moved everyone toward the baseline ended after one day as "stalled".
That is a code defect with a three-edit fix in handoff-W5-TESTS.md, not a ruling for the designer, so
no Q- row is opened. The three candidate answers the audit sketched (a floor on roster size, a free
Common on an empty roster, a charity hire) stay unwritten because no seed reached the state that
would need one — every stall the harness reports is M6-BAL-04's morale-45 wall, which already has its
row.
