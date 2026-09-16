# Handoff — M5 tutorials (key `tutorials`)

Everything below is outside my file ownership. Ordered by how badly the feature wants it.
`data/encounters_tutorial_t1.json`, `sim/model/Encounter.gd`, `sim/content/ContentDB.gd`,
`game/core/GameState.gd`, `game/screens/AdventureBoard.gd` and my four test files are
already done and green; these are the gaps that remain.

---

## H1 — `data/items_starting.json`: the two crap trinkets do not exist (M5-TUT-04)

**Blocking.** `GameState._grant_tutorial_trinket` resolves `ITM_T0_TUT_CRACKED_POWER` /
`ITM_T0_TUT_CRACKED_HEALTH` through `content.item()` and grants nothing when they are
absent, so a tutorial clear currently pays **no item at all**. The board's skip warning
falls back to `GameState.TUTORIAL_TRINKET_LINE` so the copy is still correct and tested;
the grant is the half that is missing.

Add two rows to the `items` array (docs/09 §10.2 G12 owns these stat blocks and says so at
docs/09:541 — do NOT use docs/10 §9.2's "Trinket of Mild Competence / +1 Damage", which is
not even expressible: docs/09 §12.2 restricts `damage` to weapons). Do **not** add them to
any `starting_sets` entry — `ContentDB._load_starting_sets` requires exactly 4 pieces per
class and errors at 5.

```json
{ "id": "ITM_T0_TUT_CRACKED_POWER", "name": "Cracked Charm of Power",
  "slot": "trinket", "family": "universal_trinket", "stats": { "power": 1 },
  "canon": false,
  "note": "docs/09 §10.2 G12; canon gives only 'Like a +1 dps trinket or something'. +1 Power not +1 Damage, because docs/09 §12.2 puts `damage` on weapons only." },
{ "id": "ITM_T0_TUT_CRACKED_HEALTH", "name": "Cracked Charm of Health",
  "slot": "trinket", "family": "universal_trinket", "stats": { "hp": 2 },
  "canon": false,
  "note": "docs/09 §10.2 G12; deliberately worse than the weakest canon Adventure charm (+7 HP), per canon 'not a great piece'." }
```

Two existing tests move with it or the suite goes red:

- `tests/unit/test_items_starting.gd:49` — `assert_eq(_items.size(), 22, ...)` → **24**,
  and reword: these are not "starting pieces", they are tier-0 tutorial rewards.
- `tests/unit/test_canon_guard.gd:265` — `assert_eq(non_canon.size(), 20, "3 adventure
  healer weapons + 17 raid gap-fills…")` → **22**, message `+ 2 tutorial trinkets`. The
  same test at :267-269 requires a non-empty `note` on every non-canon item, which both
  rows satisfy.

Once this lands, `tests/unit/test_tutorials.gd::test_the_tutorial_trinket_is_granted_once_or_not_at_all`
switches from the "not authored yet" branch to asserting the real grant with no edit —
it already branches on `_db.item(expected_id) != null`.

Also owed, one line each, docs/09:541 asks for it explicitly: correct **docs/10 §9.2**'s
table and **docs/01 §8.2**'s line to cite the two rows above by name and stat instead of
forking their own.

---

## H2 — `sim/core/Loot.gd`: the tutorials pay 0 gold (M5-TUT-05)

`payout()` returns 0 for any slot in neither `RAID_PAYOUT` nor `ADVENTURE_PAYOUT`, so both
tutorials currently pay nothing. docs/11 §F2 prices them: **Adventure 0: 4 G · Tutorial
Raid: 8 G**.

```gdscript
## docs/11 §F2 prices the onboarding rungs separately from the Adventure split.
const TUTORIAL_PAYOUT := {"A0": 4, "TR": 8}
```

and `payout()` (sim/core/Loot.gd:268) consults it **before** `ADVENTURE_PAYOUT`. The
repeat decay at :277-283 applies unchanged — docs/10 §11 keeps a cleared tutorial
replayable for gold.

**Do NOT add a tutorial branch to `drop_pool()` or `rolls_for()`.** `GameState.record_attempt`
already short-circuits the roll for a tutorial slot and grants the fixed trinket instead,
which is where the once-only guard has to live (`Loot`'s own header promises purity and a
once-only grant depends on campaign state). A second guard in `Loot` would be dead code
today and a silent double-source the day someone removes one. If you want belt and braces,
make `drop_pool()` return `[]` for `Reputation.is_tutorial_slot(slot)` **with a comment
saying GameState is the real gate** — but the dangerous direction is the opposite one:
without GameState's short-circuit, `drop_pool` hands A0 the real Adventure charms
(+7 HP / +2 Power), which are the items docs/10 §9.2 says the crap trinkets must be
"visibly worse than or the skip warning is a lie".

Tests owed in `tests/unit/test_loot.gd`: `payout(a0, 0) == 4`, `payout(tr, 0) == 8`,
`payout(a0, 1) == 5` (decay then round-to-5).

---

## H3 — `sim/core/Mistakes.gd` + `sim/core/RaidSim.gd`: the reduced tutorial rate (M5-TUT-11)

docs/15 Q-51 is DECIDED: "Reduced rate for both tutorials, full rates from Adventure 1
onward", mirroring docs/07 OQ-9 which names `MIS_FACEPULL` and `MIS_NINJAPULL` as the two
to disable. Nothing is built.

1. `var tutorial: bool = false` on `Mistakes.Context`.
2. Set it in `RaidSim._context()` from `Reputation.is_tutorial_slot(String(encounter.slot))`
   — the slot test, not a new data field, so docs/10 §6's encounter template does not grow.
3. `eligible_types()` drops `MIS_FACEPULL` and `MIS_NINJAPULL` when `ctx.tutorial`.
4. `roll()` applies one named constant after `p_bp` is computed. Q-51 says "reduced"
   without a number; **0.5 is the smallest defensible reading** and must live in exactly
   one `const TUTORIAL_MISTAKE_MULT := 0.5` with the choice logged as its own docs/15
   build-loop entry.

**Interaction to respect:** Adventure 0's scripted round-3 mistake (H4) must fire even at
the halved rate — seeing a mistake is the thing A0 exists to teach. Build H4 as a
deterministic construction, not as a boosted roll, and the two cannot conflict.

---

## H4 — `sim/core/RaidSim.gd`: honour `force_mistake_round` (M5-TUT-12, the sim half)

The **model half is done**: `TwgEncounter.force_mistake_round` is parsed, validated
against `target_rounds`, authored as `3` on `t1_tut_a0` and pinned by
`tests/unit/test_encounters.gd` and `tests/unit/test_tutorials.gd`
(`test_adventure_zero_scripts_a_mistake_on_round_three` also asserts that exactly one
encounter in the whole game carries it). **The sim ignores it.**

docs/10 §9.1: "Adventure 0 scripts one guaranteed mistake on round 3 regardless of morale
rolls … this is a content-level override flag on the encounter record." Adventure 0's five
teaching beats are "roster select → confirm → watch the sim → **read a mistake in the log**
→ equip a drop"; without this the first tutorial teaches four of them and skips the one the
game is named after.

In `RaidSim._run_round`, after the actor phase: if `encounter.force_mistake_round == round_no`
and no mistake has been logged this round, construct one deterministically — pick the
**highest-morale non-tank** actor (highest, so the player reads "even your best is bad",
which is the joke), build it through the normal `Mistakes` path so severity comes from
`severity_for` and the log line is byte-identical in shape to an organic one, then route it
through the existing `_log_mistake` / `_apply_mistake`. Guard with a once-only flag on the
round state (`_new_round_state()`).

Acceptance: 20 seeds on A0 each produce a mistake event at round 3. Pair it with the H3
test so the halved rate is proven not to suppress it. Add the test to
`tests/unit/test_tutorials.gd` (mine, but yours to extend once this lands) or
`tests/unit/test_raid_sim.gd`.

**Also owed against docs/10 §6:** the field table must gain `force_mistake_round`, or the
next encounter author will not know it exists. docs/10 §9.1 authorises the field in the
same doc, so this is a table row, not a change request.

---

## H5 — `game/core/RaidPlan.gd`: the `tanks_required` trap is closed one-sidedly (M5-TUT-13)

I refused `tanks_required <= 0` in `Encounter.from_dict`'s validator, which is the cheap
half and the one that matches how that file already treats impossible content. RaidPlan's
guard at :97 (`if encounter.tanks_required > 0`) is now unreachable-by-data but still
reads as if 0 were meaningful. Optional cleanup: leave the guard (it is the null-encounter
fallback too) and add one comment line pointing at the validator, so the next reader does
not "fix" the guard and re-open the trap.

`tests/unit/test_raid_plan.gd` should gain `RaidPlan.tanks_required(a0) == 1` and
`(tr) == 1` — two lines, and they pin the doc conflict's resolution at the layer the prep
screen actually reads.

---

## H6 — docs/05 §6.3's warning guarantees, NONE of which are built (M5-TUT-09)

**This is the one to read before shipping.** `onboarding_complete` now turns on, so
`Morale.may_disband(crisis_strikes, onboarding_complete)` stops short-circuiting to false
and `rolls_to_disband` goes live. That arms `DISBAND_P := [0.0, 0.0, 0.0, 0.08, 0.18, 0.30]`
from `MIN_CRISIS_STRIKES_TO_DISBAND = 3` onward — an 8% / 18% / 30%-per-Day-Tick chance
that `GameState._resolve_day_tick` wipes `roster` to `[]`, applies `Reputation.rp_after_disband`,
resets `crisis_strikes` and emits `guild_disbanded`. **Nothing in `game/` connects to
`guild_crisis` or `guild_disbanded`.** Today the roster silently becomes empty with no
screen change, which reads as a crash.

docs/05:347-356 calls the prior warning an **"Absolute rule — disband can never fire
without prior warning"** and names three guarantees. Split as four items; (a)-(c) should
land in the same release as this slice.

**(a) S — the crisis banner.** `game/ui/Frame.gd`'s chip/header row is used by every town
screen (see `Frame.chips(_frame)` at `game/screens/AdventureBoard.gd:107` and the
equivalents in Town/Guildhall/Tavern/Market). Add a `Widgets.chip` in `Palette.DANGER`
when `state.crisis_strikes >= 1`, text `GUILD UNSTABLE` / `GUILD IN CRISIS` /
`GUILD COLLAPSING` per docs/05:341-345's strike table. One helper, called from the one
shared Frame builder. **Needs:** a `state` reference in the Frame builder (it already
takes one for the chips) and the three strings.

**(b) M — the strike-2 acknowledgement.** docs/05 §6.3 wants a modal "the player must
acknowledge, listing every raider in band 0-1 and the specific actions available", and it
"states the actual p_disband for the next tick". This codebase has no dialog primitive, so
build it as a panel on Town, connected to `guild_crisis`: one Label per raider in morale
band 0-1 naming them, a Label printing `Morale.p_disband(strikes + 1)` as a percentage,
and Buttons for the four actions docs/05 §6.3 names (comfort item, bench, facility
upgrade, dismiss). **Needs:** a band-0-1 query on the roster (`Morale` has the band
function), and the four actions already exist as GameState methods — this is wiring, not
new mechanics. Labels and Buttons only, for the screen-test contract.

**(c) M — the disband outcome.** Connect `guild_disbanded` and route to a report (or a
Town takeover panel) that says what happened and prints the RP cost from
`Reputation.rp_after_disband`. **Needs:** a decision about where the player lands — a
Results-shaped screen is the cheapest, and Results already renders a "what happened"
column.

**(d) S — the pre-roll autosave.** docs/05 §6.3's "Save-scummable" row wants the save
written **before** the roll. `autosave()` currently runs at the END of `record_attempt`,
i.e. after `_resolve_day_tick` has already rolled. Move or duplicate the call to before
`_resolve_day_tick()`. **Needs:** care with BL-64's transition-coalescing index — this
should be a real rotation entry, not a coalesced one.

Acceptance (docs/05 §6.3, and it is worth writing the test first): `tests/unit/test_screens.gd`
mounts Town with `crisis_strikes = 2` and asserts a Label containing `CRISIS` and a Label
containing a percentage; a second test with `crisis_strikes = 3`, `onboarding_complete = true`
and a forced RNG asserts the disband screen's Label text after `guild_disbanded`.

---

## H7 — `BACKLOG.md` / `BUILD_STATE.md` are stale (M5-TUT-15)

`BACKLOG.md:155` lists "Adventure 0 + Tutorial Raid, with canon's skippable-with-warning
rule and the two crap trinket rewards" as one unchecked line, which reads as if none of it
exists. **Tutorial reputation was already fully built before this wave** —
`sim/core/Reputation.gd`'s `TUTORIAL_AWARDS` (5/1 and 10/2, from `data/reputation.json`),
`is_tutorial_slot`, `base_awards`, the `content_unlocked` exemption and the tier-multiplier
exclusion are all done and pinned by `tests/unit/test_reputation.gd`. What was missing was
the encounter records, the item rows, the loot/skip wiring and the warning UI.

After this slice, what remains open of that line is exactly H1-H6. `BUILD_STATE.md:39`
("A1 is currently the player's first fight, and `onboarding_complete` is still false") is
now false in both halves and should say so.

---

## H8 — `tests/unit/test_screens.gd` (not mine): board and skip coverage

The screen-level assertions the audit asked for landed in `tests/unit/test_full_loop.gd`
instead, because that file is mine and the board is where the skip ended up:
`test_the_tutorials_can_be_skipped_with_a_warning` mounts the real board, asserts the
warning names `Cracked Charm of Power` and `+1 Power` and says `not a good trinket`,
presses `Skip the tutorial`, and then asserts A1 is reachable (the soft-lock regression)
and that A0 has left the board. If `test_screens.gd` wants its own copy, nothing more is
needed from me.
