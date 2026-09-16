# Handoff — W0-SHOT (key `W0-SHOT`)

Edits needed in files this unit does not own. Shape: `## N. <path>:<line>` then an `old:`
block and a `new:` block, one edit per heading.

Observation for W1-FRAME / W1-KIT, not an edit (review F10 / A2): the plan's
"`--tab=1` moves it to the first header chip" cannot happen on today's shell.
`Frame.standard_chips()` builds the header chips as `Widgets.chip(...)` Labels
(Frame.gd:421-436), and `tab_steps_within_region = false` (Frame.gd:485) makes
Tab leave the rail for the next region's entry (:620-621) — on Town that is the
Guildhall callout's title button (`TAB 1 -> Button<Button> at 242,310 196x38`,
build/shots/Town_tab1.png). The instrument does RULES-13's Fix (N verified
`find_next_valid_focus()` grabs); whether a chip becomes focusable — and what a
focused chip looks like — is the shell's decision. Until then the `focus` sheet's
`--tab=1` row shows the scene's entry, not a chip.

Observation for W4-HYGIENE, not an edit (found while closing review F12): the
unit-test stage of `verify.sh --fast` (verify.sh:138 → `tests/run_tests.gd`)
rewrites the developer's real `user://settings.cfg`. The runner redirects
`SaveGame.SAVE_DIR` (run_tests.gd:12) but not GameSettings; test_a11y_legibility,
test_motion, test_settings, test_text_scale and test_wipe_sequence call
`set_value("reduced_motion", true)` / `set_value("text_scale", …)` on the
autoload, and `GameSettings._notification()` (GameSettings.gd:159-161) saves
the last values on PREDELETE when the runner quits. Measured 2026-09-14: after
nine shot.gd exits the file was byte-identical (md5 c7d5a3d1…, text_scale=150,
reduced_motion=false); after `verify.sh --fast` it held text_scale=100,
reduced_motion=true (md5 7a5ebee4…). Every agent's verify run does this; a
`GameSettings.PATH` redirect (or a `persist` switch) in the runner is the fix,
and it belongs with the playtest-autosave note already recorded for W4-HYGIENE.

## 1. tests/unit/test_w0_shot.gd:1 (new file; §0.2 asks every unit for `tests/unit/test_<key>.gd`, but `tests/` is outside this unit's ownership list — rule 1 — so the file is delivered here; four-space indented as tests/ requires)

old:
```
```

new:
```gdscript
extends "res://tests/TestCase.gd"
## W0-SHOT: the reference fixture's two raid modes, as tools/shot.gd reads them.
## `--fixture=raid` records a WIPE at t1_raid_e5 (docs/15 M6-BAL-04: the fixture's
## twelve do not clear Tier 1); `--fixture=raid:clear` records a CLEAR of Adventure
## 0 by the party RaidPlan.suggest_party() hands this guild and returns the seed
## it used (CRITIC-G12: the Results clear branch had never been seen). Both are
## deterministic, so a shot is reproducible from its command line alone.

const Fixture = preload("res://tools/fixture_reference.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")


func after_each() -> void:
    # record_attempt autosaves (docs/14 §7.4); the runner points SAVE_DIR at a
    # test dir, so this purges only that.
    SaveGame.purge_all()


func _fresh():
    var s = GameStateScript.new()
    s.reset()
    return s


func test_the_raid_fixture_records_one_wipe_at_the_selected_encounter() -> void:
    var st = _fresh()
    Fixture.apply(st, null, true)
    assert_eq(st.attempt_count(Fixture.SELECTED_ENCOUNTER), 1, "one attempt at t1_raid_e5")
    assert_true(st.last_result != null and not st.last_result.cleared(),
        "and it is a wipe, which is why the clear branch needed its own mode")
    assert_eq(st.selected_encounter_id, Fixture.SELECTED_ENCOUNTER, "RaidView reads E5")


func test_the_clear_fixture_records_one_clear_of_adventure_zero_and_names_its_seed() -> void:
    var st = _fresh()
    var seed_used: int = Fixture.apply_clear(st)
    assert_true(seed_used >= Fixture.SEED, "a seed from SEED upward, got %d" % seed_used)
    assert_true(seed_used < Fixture.SEED + Fixture.CLEAR_MAX_SEEDS, "inside the cap")
    assert_true(st.last_result != null and st.last_result.cleared(), "the recorded attempt is a clear")
    var enc = st.content.encounter_at_slot(Fixture.CLEAR_SLOT)
    assert_true(enc != null, "content has an encounter at %s" % Fixture.CLEAR_SLOT)
    assert_eq(st.selected_encounter_id, String(enc.id), "Results reads the A0 encounter")
    assert_eq(st.attempt_count(String(enc.id)), 1, "exactly one attempt recorded")


func test_the_clear_promotes_the_guild_so_the_records_tab_opens() -> void:
    # Guildhall's Records tab is gated on rank >= Known; a wipe pays no RP, so
    # `--press="Records"` is only reachable on the clearing fixture (report J2).
    var wiped = _fresh()
    Fixture.apply(wiped, null, true)
    var cleared = _fresh()
    Fixture.apply_clear(cleared)
    assert_true(int(cleared.reputation_rank) > int(wiped.reputation_rank),
        "the clear promotes: wipe rank %d, clear rank %d" % [wiped.reputation_rank, cleared.reputation_rank])


func test_the_clear_fixture_is_deterministic() -> void:
    var a = _fresh()
    var b = _fresh()
    assert_eq(Fixture.apply_clear(a), Fixture.apply_clear(b), "same seed twice")
    assert_eq(a.gold, b.gold, "same payout twice")
```
