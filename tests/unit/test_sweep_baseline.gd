extends "res://tests/TestCase.gd"
## The committed balance baseline (docs/14 §9.3's CI rule, audit M6-BAL-02).
##
## §9.3 asks for "a nightly reduced sweep (500 seeds × every encounter) [that]
## writes a CSV and fails the build if any clear rate moves more than 5
## percentage points from the committed baseline. Balance regressions become
## build failures."
##
## The whole mechanism was built — `--drift`, `--rebaseline`, the 5pp bound, the
## Wilson interval, the refusal to compare below 500 seeds — and the baseline it
## compares against had never been generated, so `--drift` answered "NO BASELINE"
## and nothing was gated. The same shape as three other findings this week: an
## instrument built and never armed.
##
## It is armed now, and these tests are what stop it going quiet again. The
## comparison itself is NOT run here: it is 1,800 simulated encounters and ~45
## seconds, which is `tools/verify.sh` stage 6b's job (SIM-18: `--drift --seeds
## 200` in every full gate, FAIL past 5pp). What is cheap is checking that the
## file still describes the sweep that reads it — a baseline missing the row for
## a slot is a slot nobody is watching, and it fails silently by design
## (`_check_drift` reports unbaselined cells and moves on, because a NEW
## encounter legitimately has no history) — and that the gate still invokes it.
##
## ── THE BASELINE IS NEVER REFRESHED TO GO GREEN ─────────────────────────────
## `--rebaseline` exists so a balance change is a reviewed diff with a receipt,
## exactly as `tools/write_goldens.gd` works for the sim. Running it because the
## gate went red is how a regression becomes the new normal.

const Sweep = preload("res://tools/balance_sweep.gd")

## Its own directory, gdignore'd: Godot imports a `.csv` and
## `test_project_hygiene.gd` allows an `.import` only under `game/`.
## `tests/golden/` cannot be ignored because `Scenarios.gd` is preloaded from it.
const BASELINE := "res://tests/baselines/sweep_baseline.csv"

## Every column `_check_drift()` and the report read back. A baseline written by
## an older shape of the script would parse and compare nothing.
const REQUIRED_COLUMNS := [
    "slot", "gear", "rarity", "morale", "runs", "clears", "clear_rate",
    "wilson_lo", "wilson_hi", "median_rounds", "p10_rounds", "p90_rounds",
    "deaths_per_clear", "mean_deaths", "mean_mistakes", "top_wipe_cause",
]

var _rows: Array = []
var _header: Array = []


func before_each() -> void:
    if not _rows.is_empty():
        return
    var text := FileAccess.get_file_as_string(BASELINE)
    var lines := text.strip_edges().split("\n")
    if lines.is_empty():
        return
    _header = Array(String(lines[0]).strip_edges().split(","))
    for i in range(1, lines.size()):
        var cells := String(lines[i]).strip_edges().split(",")
        var row := {}
        for c in mini(_header.size(), cells.size()):
            row[String(_header[c])] = String(cells[c])
        _rows.append(row)


func test_the_baseline_is_committed_at_all() -> void:
    # The one that would have caught this: the drift gate shipped complete and
    # unarmed, and `--drift` says "NO BASELINE" rather than failing a build.
    assert_true(FileAccess.file_exists(BASELINE),
        "docs/14 §9.3's committed baseline must exist or nothing is gated")
    assert_true(_rows.size() > 0, "and carry rows")


func test_it_carries_every_column_the_comparison_reads() -> void:
    for col in REQUIRED_COLUMNS:
        assert_true(String(col) in _header,
            "the baseline has no '%s' column — it was written by a different "
                % col + "shape of tools/balance_sweep.gd")


func test_every_encounter_the_sweep_references_has_a_row() -> void:
    # A slot with no baseline row is a slot the 5pp gate cannot fail on.
    # `_check_drift` reports it and continues, on purpose — a NEW encounter
    # legitimately has no history — which is exactly why it needs asserting here.
    var by_slot := {}
    for raw in _rows:
        by_slot[String((raw as Dictionary).get("slot", ""))] = true
    for slot in Sweep.SLOTS:
        assert_true(by_slot.has(String(slot)),
            "%s has no baseline row: nothing watches it for drift" % String(slot))


func test_each_row_is_a_cell_the_drift_run_measures() -> void:
    # `--drift` sweeps ONE cell per slot — the rung's own gear stage at the
    # reference rarity and morale (docs/15 BL-28's map) — plus the named extra
    # cells (`DRIFT_EXTRA_CELLS`: A3 at its own stage, the wall). A baseline row
    # for any other cell would compare two different measurements and call the
    # difference drift.
    for raw in _rows:
        var row: Dictionary = raw
        var slot := String(row.get("slot", ""))
        var gear := String(row.get("gear", ""))
        var legit: bool = gear == String(Sweep.REFERENCE_GEAR.get(slot, ""))
        for extra in Sweep.DRIFT_EXTRA_CELLS:
            if String(extra[0]) == slot and String(extra[1]) == gear:
                legit = true
        assert_true(legit, "%s/%s is not a cell the drift run measures" % [slot, gear])
        assert_eq(int(String(row.get("morale", "0")).to_int()), Sweep.REFERENCE_MORALE)
        assert_eq(String(row.get("rarity", "")),
            Sweep.Enums.rarity_key(Sweep.REFERENCE_RARITY))


func test_the_wall_is_in_the_drift_file() -> void:
    # SIM-18: A3's reference row (full Adventure gear) reads ~98%, while
    # tests/unit/test_adventures.gd pins A3 at 0% at its OWN stage. Both are
    # true, and the gate must watch the one the player actually meets, or the
    # day a balance change opens A3 nothing in the drift file says so.
    assert_true(Sweep.DRIFT_EXTRA_CELLS.size() >= 1)
    for extra in Sweep.DRIFT_EXTRA_CELLS:
        var found := false
        for raw in _rows:
            var row: Dictionary = raw
            if String(row.get("slot", "")) == String(extra[0]) \
                    and String(row.get("gear", "")) == String(extra[1]):
                found = true
        assert_true(found, "%s/%s has no baseline row: the wall is not gated"
            % [String(extra[0]), String(extra[1])])


func test_the_sample_is_large_enough_for_a_five_point_gate() -> void:
    # The sweep refuses to compare below `DRIFT_MIN_SEEDS` because at 8 seeds one
    # run flipping is 12.5pp and a 5pp bound would fire on noise. A baseline
    # written at a smaller sample would smuggle that noise back in.
    assert_true(Sweep.DRIFT_SEEDS >= Sweep.DRIFT_MIN_SEEDS)
    for raw in _rows:
        var row: Dictionary = raw
        assert_true(String(row.get("runs", "0")).to_int() >= Sweep.DRIFT_MIN_SEEDS,
            "%s was baselined at %s runs, under the %d the gate needs"
                % [String(row.get("slot", "?")), String(row.get("runs", "0")),
                    Sweep.DRIFT_MIN_SEEDS])


func test_the_baseline_and_the_gate_measure_the_same_fights() -> void:
    # The seeds are fixed, so a drift run at the baseline's own seed count
    # replays the baseline's own fights and an unchanged sim reads exactly
    # 0.0pp. A row at any other count would put a sampling offset inside the
    # 5pp budget on every gate run — a 3pp subset offset plus a 2pp real move
    # reads as DRIFT, and a 3pp real move hides behind a -3pp offset.
    for raw in _rows:
        var row: Dictionary = raw
        assert_eq(String(row.get("runs", "0")).to_int(), Sweep.DRIFT_SEEDS,
            "%s/%s was baselined at %s runs; the gate runs %d"
                % [String(row.get("slot", "?")), String(row.get("gear", "?")),
                    String(row.get("runs", "0")), Sweep.DRIFT_SEEDS])


func test_the_gate_actually_runs_the_comparison() -> void:
    # "Built" and "armed" are different states (LESSONS.md): `--drift` existed
    # for a week with nothing invoking it. verify.sh stage 6b is the invocation;
    # this is the assertion that it stays there, at the count the baseline was
    # written at.
    var gate := FileAccess.get_file_as_string("res://tools/verify.sh")
    assert_false(gate.is_empty(), "tools/verify.sh must be readable")
    assert_true(gate.contains("balance_sweep.gd -- --drift --seeds %d" % Sweep.DRIFT_SEEDS),
        "verify.sh must run balance_sweep.gd -- --drift --seeds %d (stage 6b)"
            % Sweep.DRIFT_SEEDS)
    assert_true(gate.contains("6b/"), "the drift stage prints a 6b/ line")
    for line in gate.split("\n"):
        var l := String(line).strip_edges()
        if l.begins_with("#") or not l.contains("balance_sweep.gd"):
            continue
        assert_false(l.contains("--rebaseline"),
            "the gate never re-baselines; that is a deliberate act with a receipt: " + l)


func test_every_clear_rate_is_a_rate() -> void:
    for raw in _rows:
        var row: Dictionary = raw
        var rate := String(row.get("clear_rate", "")).to_float()
        assert_in_range(rate, 0.0, 1.0,
            "%s's baseline clear rate is not a share" % String(row.get("slot", "?")))
        var lo := String(row.get("wilson_lo", "")).to_float()
        var hi := String(row.get("wilson_hi", "")).to_float()
        assert_true(lo <= rate and rate <= hi,
            "%s's Wilson interval does not contain its own rate"
                % String(row.get("slot", "?")))
