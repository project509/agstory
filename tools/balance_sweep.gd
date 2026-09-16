extends SceneTree
## The balance sweep: run the simulation thousands of times and report what
## actually happens, so tuning is settled by measurement rather than argument.
##
## docs/14 §9.3 calls this the tool that makes docs/08's tuning tables real. It
## is also the only way to answer the two questions the goldens raised:
##
##   docs/15 BL-21 — how many mistakes per encounter is the right number?
##   Why can Adventure-geared Commons not clear E3, which was sized for them?
##
## Usage:
##   godot --headless --path . --script res://tools/balance_sweep.gd
##   godot --headless --path . --script res://tools/balance_sweep.gd -- --full
##   godot --headless --path . --script res://tools/balance_sweep.gd -- --seeds 40
##   godot --headless --path . --script res://tools/balance_sweep.gd -- --out build/sweeps/x.csv
##   godot --headless --path . --script res://tools/balance_sweep.gd -- --drift
##   godot --headless --path . --script res://tools/balance_sweep.gd -- --drift --rebaseline
##
## Prints SWEEP OK when the results sit inside the sanity bounds below, so
## verify.sh can gate on it. The bounds are deliberately loose: this is a
## smoke test for "the game is still playable", not a tuning assertion. Tuning
## belongs in the report, which a human reads.
##
## ── THE BASELINE IS NEVER REFRESHED TO GO GREEN ──────────────────────────────
## `--drift` compares the reference row of every encounter against the committed
## `tests/baselines/sweep_baseline.csv` and fails past docs/14 §9.3's 5-percentage-
## point rule. `--rebaseline` rewrites that file, and it exists so that a balance
## change is a REVIEWED DIFF WITH A RECEIPT — the same discipline
## `tools/write_goldens.gd` keeps. Running `--rebaseline` because the gate went
## red is how a regression becomes the new normal. This project has already been
## bitten once by a plausible default becoming a reported number
## (BUILD_STATE.md:116) and `_cell()` below carries the scar.
##
## ARMED: `tools/verify.sh` stage 6b runs `--drift --seeds 200` in every full
## gate and fails the build on DRIFT (SIM-18, wave 6). Until then the comparison
## existed and nothing invoked it — the fourth built-and-never-armed instrument
## of that week. `--rebaseline` is never run by the gate or by a non-SIM unit:
## at most once per SIM wave, in that wave's RaidSim-owning unit, with the
## before/after numbers in the commit message (ship plan §0.2).

const Scenarios = preload("res://tests/golden/Scenarios.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const Sim = preload("res://sim/core/RaidSim.gd")
const Enums = preload("res://sim/model/Enums.gd")
const RaidPlan = preload("res://game/core/RaidPlan.gd")

## The whole Tier 1 ladder, in the order a guild climbs it. The Adventures were
## missing until M6-BAL-01: they are the on-ramp the campaign stands on and
## nothing had re-measured them since BUILD_STATE.md:280's hand-run.
const ADVENTURE_SLOTS := ["A1", "A2", "A3"]
const RAID_SLOTS := ["E1", "E2", "E3", "E4", "E5"]
const SLOTS := ["A1", "A2", "A3", "E1", "E2", "E3", "E4", "E5"]

const GEARS := ["starting", "adventure", "raid_entry", "raid"]

## An Adventure is fought at the stage the rung BEFORE it dropped — docs/08
## §9.1a measures stage 0 at 16.5 party DPS, after A1 at 54.9, after A2 at 58.2.
## Sweeping A1 in raid gear would be the same category of error as measuring
## Boss 5 in Boss-5 capstones (BACKLOG.md:44), so the Adventure axis stops at
## the Adventure rung.
##
## All four stages the Adventure ladder is actually played at, which is what
## makes each rung measurable at the gear the rung BEFORE it dropped — docs/08
## §9.2's rule for the raid tier, applied where doc 10 §8 asked for it:
##
##   starting   stage 0, 16.5 party output — where A1 is fought
##   after_a1   + Adventure feet + first weapon, 54.9 — where A2 is fought
##   after_a2   + Adventure legs, 58.2          — where A3 is fought
##   adventure  full Tier 1 Adventure kit        — where the guild enters the raid
##
## The two middle rungs were a stated gap here for months: `Scenarios.gd` could
## build only four rungs and neither of these was among them, so `starting` and
## `adventure` merely BRACKETED the ladder and no cell sat on the stage a rung is
## sized against. Audit M6-BAL-01 built them; §9.1a's own contents list is what
## each one equips, item by item.
const ADVENTURE_GEARS := ["starting", "after_a1", "after_a2", "adventure"]

## Which stage each Adventure rung is SIZED for (docs/15 BL-28, and the same map
## `tests/unit/test_adventures.gd` pins its 16.5 / 54.9 / 58.2 against). The
## sweep reports every rung at every stage — twelve cells is cheap and the whole
## picture is what a tuning decision needs — but this is the diagonal a reader
## should look at first, and `_print_clear_rates` marks it.
const ADVENTURE_STAGE := {"A1": "starting", "A2": "after_a1", "A3": "after_a2"}

const RARITIES := [Enums.Rarity.COMMON, Enums.Rarity.RARE, Enums.Rarity.LEGENDARY]
const MORALES := [15, 55, 95]

## Sanity bounds. If the game breaks these, something is badly wrong.
const BEST_CASE_MIN_CLEAR := 0.70    # Legendary + best swept gear + high morale
const WORST_CASE_MAX_CLEAR := 0.25   # Common + starting gear + low morale, at E5
const MAX_MEAN_MISTAKES := 200       # beyond this the log is unreadable at any tier

## docs/14 §9.3's CI rule: "fails the build if any clear rate moves more than 5
## percentage points from the committed baseline".
const DRIFT_PP := 0.05

## docs/14 §9.3's nightly shape is "500 seeds x every encounter". The seed count
## is not decoration: at the 8 seeds the fast grid uses, ONE run flipping is
## 12.5pp, so a 5pp gate on 8 seeds would fire on noise and mean nothing. The
## drift comparison therefore refuses to run below DRIFT_MIN_SEEDS.
##
## 200 rather than 500 (SIM-18): this is the PER-COMMIT gate now, not a nightly,
## and 200 seeds keeps the Wilson half-width near 3.5pp under the 5pp rule at
## a quarter of the cost. The baseline is written at the SAME count, on purpose:
## the seeds are fixed (`1000 + i * 7919`), so a run at the baseline's own count
## replays the baseline's own fights and an unchanged sim reads exactly 0.0pp —
## which is what makes the gate a change detector rather than a noise meter.
## `tests/unit/test_sweep_baseline.gd` pins every baseline row to this count.
const DRIFT_SEEDS := 200
const DRIFT_MIN_SEEDS := 100

## IN ITS OWN GDIGNORE'D DIRECTORY, and that is not fussiness. Godot imports a
## `.csv` as a Translation and writes a `.import` beside it, and
## `tests/unit/test_project_hygiene.gd` forbids an `.import` anywhere but
## `game/` (docs/14 §10.3: only shipped art is imported). `tests/golden/` cannot
## be gdignore'd because `Scenarios.gd` is preloaded out of it, so the baseline
## gets a directory of its own that holds no script and can be ignored whole.
## `FileAccess` reads through a `.gdignore` — it stops the importer, not the
## filesystem — so nothing else changes.
const BASELINE_PATH := "res://tests/baselines/sweep_baseline.csv"

## The reference configuration of each encounter — the one row per encounter the
## nightly drift sweep measures. docs/08 §9.2's rule is "the boss is fought in
## the gear the boss before it dropped", so each rung is measured in the kit the
## rung below it hands over, at the benchmark twelve's default rarity and at
## docs/13 §10.3's Content morale (55), which is the morale every comparison
## figure in this project is normalised to.
##
## A2 and A3 are marked because they are the honest approximation: §9.1a fights
## them at partial Adventure kits this harness cannot build, and `adventure` is
## the nearest committed rung ABOVE, so their baseline reads OPTIMISTIC.
const REFERENCE_GEAR := {
    "A1": "starting",     # docs/08 §9.1a stage 0 — canon starting armour, no weapon
    "A2": "adventure",    # approximates §9.1a "after A1" from above
    "A3": "adventure",    # approximates §9.1a "after A2" from above
    "E1": "adventure",    # docs/08 §9.2: Raid 1 is entered in full Adventure gear
    "E2": "raid_entry",
    "E3": "raid_entry",
    "E4": "raid_entry",
    "E5": "raid_entry",   # Boss 1-4 drops: the fight that actually happens
}
const REFERENCE_RARITY := Enums.Rarity.COMMON
const REFERENCE_MORALE := 55

## Cells the drift run measures BESIDE the reference row (SIM-18). A3's
## reference row is at full Adventure gear (98%, optimistic — see above), while
## `tests/unit/test_adventures.gd` pins A3 at 0% at its OWN stage, `after_a2`.
## Both are true; the wall belongs in the drift file too, so the day a balance
## change opens A3 the gate says so with a number rather than a unit test
## flipping. Same rarity and morale as the reference row.
const DRIFT_EXTRA_CELLS := [["A3", "after_a2"]]

## docs/08 §9.1a's benchmark six, named there in full: "1 Warrior, 1 Cleric,
## 2 Rogue, 1 Wizard, 1 Mage (one tank, one healer, all three damage shapes)".
## Every Adventure HP number in docs/10 §8 was derived against THIS party, at
## six bodies. `RaidSim.run` does not trim a roster to `party_size`, so sending
## Scenarios' twelve at a six-person Adventure doubles the DPS the HP was sized
## against — the exact bug BUILD_STATE.md:284 records.
const ADVENTURE_SIX := ["warrior", "cleric", "rogue", "rogue", "wizard", "mage"]

var _db = null
var _rows: Array = []
var _lookup_failures: Array = []
## Aggregated across every run of the sweep, for docs/14 §9.3's three histograms.
var _wipe_causes: Dictionary = {}
var _mistake_types: Dictionary = {}
var _blame: Dictionary = {}


func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    var full := "--full" in args
    var drift := "--drift" in args
    var rebaseline := "--rebaseline" in args
    var out_path := _arg_value(args, "--out")
    var seeds := _int_arg(args, "--seeds", DRIFT_SEEDS if drift else (30 if full else 8))

    _db = DB.load_all()
    if not _db.is_valid():
        print("CONTENT INVALID — cannot sweep")
        print(_db.error_report())
        quit(1)
        return

    if drift:
        _run_drift(seeds, rebaseline, out_path)
        return

    var t0 := Time.get_ticks_msec()
    for slot in SLOTS:
        for gear in _gears_for(slot):
            for rarity in RARITIES:
                for morale in MORALES:
                    _run_cell(slot, gear, rarity, morale, seeds)
    var dt := Time.get_ticks_msec() - t0

    _print_clear_rates("THE ADVENTURE LADDER", ADVENTURE_SLOTS, ADVENTURE_GEARS,
        ADVENTURE_STAGE)
    _print_clear_rates("THE RAID LADDER", RAID_SLOTS, GEARS)
    _print_intervals()
    _print_mistake_report()
    _print_histograms()
    _print_findings()

    if not out_path.is_empty():
        _write_csv(out_path, _rows)
        print("")
        print("CSV  %d rows -> %s" % [_rows.size(), out_path])

    var runs := 0
    for r in _rows:
        runs += int(r["runs"])
    print("")
    print("%d runs across %d cells in %.1fs" % [runs, _rows.size(), float(dt) / 1000.0])

    _finish(_check_bounds())


## The nightly shape docs/14 §9.3 specifies: one reference row per encounter at
## a seed count where 5 percentage points is a real signal, compared against the
## committed baseline.
func _run_drift(seeds: int, rebaseline: bool, out_path: String) -> void:
    if seeds < DRIFT_MIN_SEEDS:
        print("DRIFT REFUSED  %d seeds is below %d — a 5pp gate on that few runs"
            % [seeds, DRIFT_MIN_SEEDS])
        print("               measures noise. Re-run without --seeds, or above %d."
            % DRIFT_MIN_SEEDS)
        quit(1)
        return

    var t0 := Time.get_ticks_msec()
    for slot in SLOTS:
        _run_cell(slot, String(REFERENCE_GEAR[slot]), REFERENCE_RARITY,
            REFERENCE_MORALE, seeds)
    for extra in DRIFT_EXTRA_CELLS:
        _run_cell(String(extra[0]), String(extra[1]), REFERENCE_RARITY,
            REFERENCE_MORALE, seeds)
    var dt := Time.get_ticks_msec() - t0

    _print_reference_table()
    _print_histograms()

    if not out_path.is_empty():
        _write_csv(out_path, _rows)
        print("")
        print("CSV  %d rows -> %s" % [_rows.size(), out_path])

    print("")
    print("%d runs across %d reference cells in %.1fs"
        % [seeds * _rows.size(), _rows.size(), float(dt) / 1000.0])

    if rebaseline:
        _write_csv(BASELINE_PATH, _rows)
        print("")
        print("REBASELINED  %s rewritten from this run." % BASELINE_PATH)
        print("             This is a balance change with a receipt: the diff is")
        print("             the change, and it is reviewed, not rubber-stamped.")
        _finish([])
        return

    _finish(_check_drift())


func _finish(problems: Array) -> void:
    if problems.is_empty():
        print("SWEEP OK")
        quit(0)
        return
    for p in problems:
        print("  SWEEP FAIL  " + p)
    print("SWEEP FAILED (%d)" % problems.size())
    quit(1)


## The gear axis this slot is measured on. An Adventure is not fought in raid
## kit, so it is not swept in raid kit either.
func _gears_for(slot: String) -> Array:
    return ADVENTURE_GEARS if slot in ADVENTURE_SLOTS else GEARS


func _run_cell(slot: String, gear: String, rarity: int, morale: int, seeds: int) -> void:
    var spec := {"rarity": rarity, "morale": morale, "gear": gear}
    var enc = _db.encounter_at_slot(slot)
    var clears := 0
    var rounds: Array = []
    var mistakes: Array = []
    var outcomes := {}
    var deaths_on_clear: Array = []
    var deaths_all: Array = []
    var cell_causes := {}
    for i in seeds:
        var roster := _party_for(enc, Scenarios.build_roster(spec, _db))
        var res = Sim.run(roster, enc, _db, 1000 + i * 7919)
        if res.cleared():
            clears += 1
            deaths_on_clear.append(res.casualties.size())
        else:
            var cause := _root_cause(res)
            cell_causes[cause] = int(cell_causes.get(cause, 0)) + 1
            _wipe_causes[cause] = int(_wipe_causes.get(cause, 0)) + 1
        deaths_all.append(res.casualties.size())
        rounds.append(res.rounds)
        mistakes.append(res.mistake_count)
        outcomes[res.outcome_key()] = int(outcomes.get(res.outcome_key(), 0)) + 1
        _tally_mistakes(res)
    var wilson := _wilson(clears, seeds)
    _rows.append({
        "slot": slot, "gear": gear, "rarity": rarity, "morale": morale,
        "runs": seeds, "clears": clears,
        "clear_rate": float(clears) / float(seeds),
        "wilson_lo": wilson[0], "wilson_hi": wilson[1],
        "median_rounds": _median(rounds),
        "p10_rounds": _percentile(rounds, 0.10),
        "p90_rounds": _percentile(rounds, 0.90),
        "deaths_per_clear": _mean(deaths_on_clear),
        "mean_deaths": _mean(deaths_all),
        "mean_mistakes": _mean(mistakes),
        "top_wipe_cause": _top_key(cell_causes),
        "outcomes": outcomes,
    })


## Trim the benchmark twelve to the party this encounter actually fields.
## `RaidSim.run` builds a combatant per roster entry and never consults
## `party_size`, so the trim has to happen here or a six-person Adventure is
## fought by twelve (docs/10 §3, RaidPlan.party_size's own header).
func _party_for(enc, roster: Array) -> Array:
    var size := RaidPlan.party_size(enc)
    if size >= roster.size():
        return roster
    if size == ADVENTURE_SIX.size():
        return _pick_classes(roster, ADVENTURE_SIX)
    return roster.slice(0, size)


## Pick one raider per requested class key, in order. Falls back to the first
## unused raider when a class is absent, so an odd party size still fields the
## right NUMBER of bodies rather than silently fielding fewer.
func _pick_classes(roster: Array, wanted: Array) -> Array:
    var used := {}
    var out: Array = []
    for key in wanted:
        var want_class: int = Enums.class_from_key(String(key))
        var found = null
        for r in roster:
            if used.has(r.id):
                continue
            if int(r.class_id) == want_class:
                found = r
                break
        if found == null:
            for r in roster:
                if not used.has(r.id):
                    found = r
                    break
        if found != null:
            used[found.id] = true
            out.append(found)
    return out


## docs/14 §9.3's "root cause of the wipe (`cascade_depth == 0` ancestor)".
## A cascade is a chain of mistakes each caused by the last; the ancestor is the
## one that started it, and it is the only one worth counting in a histogram —
## counting the descendants would report the same wipe eight times under eight
## different names. The LAST such ancestor is taken because it is the chain that
## was still running when the raid died; earlier ones were survived.
func _root_cause(res) -> String:
    if res.log == null:
        return "unknown"
    var cause := ""
    for e in res.log.mistakes():
        if int(e.mistake.get("cascade_depth", 0)) == 0:
            cause = String(e.mistake.get("type", ""))
    if cause.is_empty():
        # A wipe with no mistake at all is an honest outcome: the fight simply
        # out-damaged the party. Naming it says so instead of blaming a raider.
        return "no_mistake_" + res.outcome_key()
    return cause


func _tally_mistakes(res) -> void:
    if res.log == null:
        return
    for e in res.log.mistakes():
        var t := String(e.mistake.get("type", "?"))
        _mistake_types[t] = int(_mistake_types.get(t, 0)) + 1
        # `e` is a sim object, so its fields are untyped (BUILD_STATE invariant
        # 8) and `:=` cannot infer through them.
        var who: String = e.actor_name if not e.actor_name.is_empty() else "(the raid)"
        _blame[who] = int(_blame.get(who, 0)) + 1


# ---------------------------------------------------------------- reporting

## `stage_map` marks the DIAGONAL — the cell where a rung is met at the stage it
## was sized for. Every other cell is real and worth printing (a tuning decision
## needs to see what one rung above and below looks like), but the starred one is
## the number that answers "is this rung fair", and without the mark a reader has
## to hold docs/15 BL-28's map in their head while reading a 36-row table.
func _print_clear_rates(title: String, slots: Array, gears: Array,
        stage_map: Dictionary = {}) -> void:
    print("")
    print("CLEAR RATE — %s  (rows: gear x rarity x morale)" % title)
    if not stage_map.is_empty():
        print("  * = the rung met at the stage it is sized for (docs/08 §9.1a)")
    print("  %-10s %-10s %-7s  %s" % ["gear", "rarity", "morale", _slot_header(slots)])
    for gear in gears:
        for rarity in RARITIES:
            for morale in MORALES:
                var cells := ""
                for slot in slots:
                    var rate: float = _cell(slot, gear, rarity, morale)["clear_rate"]
                    var mark := "*" if String(stage_map.get(slot, "")) == String(gear) else " "
                    cells += "%5.0f%%%s" % [rate * 100.0, mark]
                print("  %-10s %-10s %-7d %s"
                    % [gear, Enums.rarity_key(rarity), morale, cells])


func _slot_header(slots: Array) -> String:
    var out := ""
    for s in slots:
        out += "%7s" % s
    return out


## docs/14 §9.3's report shape, the half that was missing: a clear rate without
## an interval is a number without an error bar, and at 8 seeds the error bar is
## wider than most of the differences anyone wants to read off the grid.
func _print_intervals() -> void:
    print("")
    print("CLEAR RATE WITH 95% WILSON INTERVAL, AND ROUNDS  (reference row per encounter)")
    print("  %-4s %-11s %-9s %-24s %-16s %s"
        % ["slot", "gear", "clear", "95% interval", "rounds p10/med/p90", "deaths/clear"])
    for slot in SLOTS:
        var r = _cell(slot, String(REFERENCE_GEAR[slot]), REFERENCE_RARITY, REFERENCE_MORALE)
        print("  %-4s %-11s %8.0f%% %-24s %-16s %.2f"
            % [slot, String(REFERENCE_GEAR[slot]), float(r["clear_rate"]) * 100.0,
               "[%.0f%% .. %.0f%%]" % [float(r["wilson_lo"]) * 100.0,
                                       float(r["wilson_hi"]) * 100.0],
               "%d / %d / %d" % [int(r["p10_rounds"]), int(r["median_rounds"]),
                                 int(r["p90_rounds"])],
               float(r["deaths_per_clear"])])


func _print_reference_table() -> void:
    print("")
    print("REFERENCE ROW PER ENCOUNTER  (docs/08 §9.2: the gear the rung below dropped)")
    print("  %-4s %-11s %-9s %-24s %-16s %s"
        % ["slot", "gear", "clear", "95% interval", "rounds p10/med/p90", "top wipe cause"])
    for r in _rows:
        print("  %-4s %-11s %8.0f%% %-24s %-16s %s"
            % [r["slot"], r["gear"], float(r["clear_rate"]) * 100.0,
               "[%.0f%% .. %.0f%%]" % [float(r["wilson_lo"]) * 100.0,
                                       float(r["wilson_hi"]) * 100.0],
               "%d / %d / %d" % [int(r["p10_rounds"]), int(r["median_rounds"]),
                                 int(r["p90_rounds"])],
               r["top_wipe_cause"]])


func _print_mistake_report() -> void:
    # docs/15 BL-21: the measurement that settles the roll-cadence question.
    print("")
    print("MEAN MISTAKES PER ENCOUNTER  (the BL-21 measurement)")
    print("  %-10s %-10s %-7s  %s" % ["gear", "rarity", "morale", _slot_header(SLOTS)])
    for gear in GEARS:
        for rarity in RARITIES:
            for morale in MORALES:
                var cells := ""
                for slot in SLOTS:
                    if not gear in _gears_for(slot):
                        cells += "%7s" % "-"
                        continue
                    cells += "%7.0f" % _cell(slot, gear, rarity, morale)["mean_mistakes"]
                print("  %-10s %-10s %-7d %s"
                    % [gear, Enums.rarity_key(rarity), morale, cells])


## The three histograms docs/14 §9.3 asks for, aggregated over the whole sweep.
## Per cell they would be noise at 8 seeds; over the grid they are the shape of
## how this build kills people and who it blames.
func _print_histograms() -> void:
    _print_histogram("WIPE-CAUSE HISTOGRAM  (cascade_depth == 0 ancestor)", _wipe_causes, 10)
    _print_histogram("MISTAKE-TYPE HISTOGRAM", _mistake_types, 12)
    _print_histogram("PER-RAIDER BLAME TABLE  (Scenarios' benchmark twelve)", _blame, 12)


func _print_histogram(title: String, counts: Dictionary, limit: int) -> void:
    print("")
    print(title)
    if counts.is_empty():
        print("  (nothing recorded)")
        return
    var keys := counts.keys()
    keys.sort_custom(func(a, b) -> bool: return int(counts[a]) > int(counts[b]))
    var total := 0
    for k in keys:
        total += int(counts[k])
    var shown := 0
    for k in keys:
        if shown >= limit:
            break
        var n := int(counts[k])
        var bar := "#".repeat(clampi(int(round(40.0 * float(n) / float(maxi(1, int(counts[keys[0]]))))), 0, 40))
        print("  %-28s %7d  %5.1f%%  %s" % [k, n, 100.0 * float(n) / float(total), bar])
        shown += 1
    if keys.size() > limit:
        print("  (+%d more)" % (keys.size() - limit))


func _print_findings() -> void:
    print("")
    print("FINDINGS")

    # M6-BAL-01's headline: the on-ramp, measured for the first time by this tool.
    for slot in ADVENTURE_SLOTS:
        var a = _cell(slot, String(REFERENCE_GEAR[slot]), REFERENCE_RARITY, REFERENCE_MORALE)
        print("  %s at its own stage (%s):  %.0f%% clear, median %d rounds"
            % [slot, REFERENCE_GEAR[slot], a["clear_rate"] * 100.0, a["median_rounds"]])
    print("    (BUILD_STATE.md:280 recorded A3 at ~29%% by hand during iterations 26-32;")
    print("     tests/unit/test_adventures.gd pins A3 as a WALL — 0/24 with all three")
    print("     mechanics armed. A move here is content news, not a harness bug.)")

    # The progression question: can each gear tier clear the content it is for?
    var adv_e3 = _cell("E3", "adventure", Enums.Rarity.COMMON, 55)
    print("  Adventure-geared Commons at E3:   %.0f%% clear, median %d rounds "
        % [adv_e3["clear_rate"] * 100.0, adv_e3["median_rounds"]]
        + "(docs/08 sized E3 for 15)")

    # The honest first-clear measurement: raid_entry is Boss 1-4 drops, which is
    # what you own the first time you face Boss 5. Measuring E5 against full
    # clear gear measures a fight nobody ever has.
    var entry = _cell("E5", "raid_entry", Enums.Rarity.RARE, 55)
    print("  E5 FIRST CLEAR (raid_entry gear): %.0f%% clear, median %d rounds "
        % [entry["clear_rate"] * 100.0, entry["median_rounds"]]
        + "(docs/08 targets 22)")
    var best = _cell("E5", "raid", Enums.Rarity.LEGENDARY, 95)
    print("  E5 farm run (full-clear gear):    %.0f%% clear, median %d rounds "
        % [best["clear_rate"] * 100.0, best["median_rounds"]]
        + "(should be faster — the tier gets easier to farm)")

    var worst = _cell("E5", "starting", Enums.Rarity.COMMON, 15)
    print("  Worst case at the tier boss:    %.0f%% clear" % (worst["clear_rate"] * 100.0))

    # Morale as a lever, isolated: same rarity and gear, morale varied.
    var probe0 := _find_unsaturated_cell()
    var lo = _cell(probe0[0], probe0[1], Enums.Rarity.COMMON, 15)
    var hi = _cell(probe0[0], probe0[1], Enums.Rarity.COMMON, 95)
    print("  Morale swing (%s/%s, Common): %.0f%% -> %.0f%% clear, "
        % [probe0[0], probe0[1], lo["clear_rate"] * 100.0, hi["clear_rate"] * 100.0]
        + "%.0f -> %.0f mistakes" % [lo["mean_mistakes"], hi["mean_mistakes"]])

    # Rarity as a lever, isolated — measured at a cell where neither lever is
    # pinned, because a cell everyone clears reports zero span for everything.
    var probe := probe0
    var common = _cell(probe[0], probe[1], Enums.Rarity.COMMON, 55)
    var legend = _cell(probe[0], probe[1], Enums.Rarity.LEGENDARY, 55)
    print("  Rarity swing (%s/%s, morale 55): %.0f%% -> %.0f%% clear, "
        % [probe[0], probe[1], common["clear_rate"] * 100.0, legend["clear_rate"] * 100.0]
        + "%.0f -> %.0f mistakes" % [common["mean_mistakes"], legend["mean_mistakes"]])

    # Canon's thesis is that morale management is the core skill. If rarity
    # swamps morale, the game rewards recruiting over managing, and the Tavern
    # quietly becomes the whole game. Worth watching every sweep.
    var morale_span: float = hi["clear_rate"] - lo["clear_rate"]
    var rarity_span: float = legend["clear_rate"] - common["clear_rate"]
    # A cell where everyone clears (or nobody does) reports zero span for every
    # lever, which says nothing. Flag that rather than printing a false reading.
    var saturated: bool = (common["clear_rate"] >= 1.0 and legend["clear_rate"] >= 1.0) \
        or (common["clear_rate"] <= 0.0 and legend["clear_rate"] <= 0.0)
    var note := ""
    if saturated:
        note = "  (%s is saturated at this gear — reading is not meaningful)" % probe[0]
    elif rarity_span > morale_span * 2.0:
        note = "  <-- rarity dominates"
    elif morale_span > rarity_span * 2.0:
        note = "  <-- morale dominates"
    print("  LEVER BALANCE: morale moves clear rate by %.0fpp, rarity by %.0fpp.%s"
        % [morale_span * 100.0, rarity_span * 100.0, note])


func _check_bounds() -> Array:
    var problems: Array[String] = []

    for slot in RAID_SLOTS:
        var best = _cell(slot, "raid", Enums.Rarity.LEGENDARY, 95)
        if best["clear_rate"] < BEST_CASE_MIN_CLEAR:
            problems.append("%s unclearable by the best possible raid (%.0f%%)"
                % [slot, best["clear_rate"] * 100.0])

    # The same bound on the Adventure ladder is a WARNING, not a failure, and
    # that is a deliberate choice rather than a soft one. A3 is ALREADY pinned
    # as a wall by tests/unit/test_adventures.gd — 0/24 with its three mechanics
    # armed — and that pin says in terms that retuning it needs a designer, not
    # a loop. Failing the gate here would block every unrelated task on that one
    # open content decision, which is the reasoning the BL-21 warning below
    # already uses. The number is still printed loudly every run.
    for slot in ADVENTURE_SLOTS:
        var top_gear: String = String(ADVENTURE_GEARS[ADVENTURE_GEARS.size() - 1])
        var adv_best = _cell(slot, top_gear, Enums.Rarity.LEGENDARY, 95)
        if adv_best["clear_rate"] < BEST_CASE_MIN_CLEAR:
            print("")
            print("  SWEEP WARNING  %s clears only %.0f%% for Legendaries in %s gear at"
                % [slot, adv_best["clear_rate"] * 100.0, top_gear])
            print("                 morale 95 — the best party this content can be met with.")
            print("                 See tests/unit/test_adventures.gd's A3 pin and docs/10 §3")
            print("                 ('a gate rather than a wall'). Needs a designer.")

    var worst = _cell("E5", "starting", Enums.Rarity.COMMON, 15)
    if worst["clear_rate"] > WORST_CASE_MAX_CLEAR:
        problems.append("the tier boss falls to morale-15 Commons in starting gear (%.0f%%)"
            % (worst["clear_rate"] * 100.0))

    # Mistake volume is a KNOWN OPEN QUESTION (docs/15 BL-21), not a regression.
    # It is reported loudly as a warning rather than failing the build, because
    # blocking every unrelated task on an unresolved tuning decision helps
    # nobody — and quietly loosening the bound to go green would be worse.
    var worst_mistakes := 0.0
    var worst_cell := ""
    for r in _rows:
        if float(r["mean_mistakes"]) > worst_mistakes:
            worst_mistakes = float(r["mean_mistakes"])
            worst_cell = "%s %s/%s/m%d" % [r["slot"], r["gear"],
                Enums.rarity_key(int(r["rarity"])), int(r["morale"])]
    if worst_mistakes > MAX_MEAN_MISTAKES:
        print("")
        print("  SWEEP WARNING  worst cell %s averages %.0f mistakes (readable limit %d)."
            % [worst_cell, worst_mistakes, MAX_MEAN_MISTAKES])
        print("                 This is docs/15 BL-21, still open. Tune ROLL_SITE_WEIGHT")
        print("                 or the per-rarity bases, then re-run this sweep.")

    # A fabricated reading must fail the gate, not decorate the report.
    if not _lookup_failures.is_empty():
        problems.append("report read %d cell(s) the grid never swept: %s"
            % [_lookup_failures.size(), ", ".join(_lookup_failures)])

    # Progression must be monotone in gear: better kit cannot clear less often.
    for slot in SLOTS:
        var axis := _gears_for(slot)
        var rates: Array = []
        for gear in axis:
            rates.append(float(_cell(slot, gear, Enums.Rarity.COMMON, 55)["clear_rate"]))
        for i in range(1, rates.size()):
            if rates[i] + 0.15 < rates[i - 1]:
                problems.append("%s: %s gear clears less often than %s (%.2f < %.2f)"
                    % [slot, axis[i], axis[i - 1], rates[i], rates[i - 1]])
                break
    return problems


## docs/14 §9.3's CI rule, made executable. Compares this run's reference rows
## against the committed baseline and fails past 5 percentage points.
##
## A cell the baseline does not carry is a WARNING, not a failure: adding a rung
## to the ladder must not turn the gate red on a build that changed nothing. A
## cell whose seed count differs is also flagged, because two clear rates
## measured over different sample sizes are not the same measurement.
func _check_drift() -> Array:
    var problems: Array[String] = []
    var base := _read_csv(BASELINE_PATH)
    if base.is_empty():
        print("")
        print("  NO BASELINE  %s is missing or empty." % BASELINE_PATH)
        print("               Run with --drift --rebaseline to commit the first one.")
        problems.append("no committed baseline at %s" % BASELINE_PATH)
        return problems

    print("")
    print("DRIFT VS COMMITTED BASELINE  (docs/14 §9.3: fail past %.0fpp)" % (DRIFT_PP * 100.0))
    var unbaselined: Array = []
    for r in _rows:
        var key := _row_key(r)
        if not base.has(key):
            unbaselined.append(key)
            continue
        var base_row: Dictionary = base[key]
        var was := String(base_row.get("clear_rate", "0")).to_float()
        var now := float(r["clear_rate"])
        var delta := now - was
        var flag := ""
        if absf(delta) > DRIFT_PP:
            flag = "  <-- DRIFT"
            problems.append("%s moved %+.1fpp (baseline %.1f%% -> now %.1f%%)"
                % [key, delta * 100.0, was * 100.0, now * 100.0])
        print("  %-34s %6.1f%% -> %6.1f%%  %+6.1fpp%s"
            % [key, was * 100.0, now * 100.0, delta * 100.0, flag])
        var base_runs := int(base[key].get("runs", "0").to_int())
        if base_runs != int(r["runs"]):
            print("      note: baseline was %d seeds, this run %d — not the same measurement"
                % [base_runs, int(r["runs"])])
    for key in unbaselined:
        print("  %-34s (not in the baseline — --rebaseline to add it)" % key)
    return problems


# ---------------------------------------------------------------- csv

const CSV_COLUMNS := ["slot", "gear", "rarity", "morale", "runs", "clears",
    "clear_rate", "wilson_lo", "wilson_hi", "median_rounds", "p10_rounds",
    "p90_rounds", "deaths_per_clear", "mean_deaths", "mean_mistakes",
    "top_wipe_cause", "victory", "wipe", "soft_wipe", "attrition"]


func _row_key(r: Dictionary) -> String:
    return "%s/%s/%s/m%d" % [r["slot"], r["gear"],
        Enums.rarity_key(int(r["rarity"])), int(r["morale"])]


func _write_csv(path: String, rows: Array) -> void:
    var dir := path.get_base_dir()
    if not dir.is_empty() and not DirAccess.dir_exists_absolute(dir):
        DirAccess.make_dir_recursive_absolute(dir)
    var f := FileAccess.open(path, FileAccess.WRITE)
    if f == null:
        push_error("balance_sweep: cannot write " + path)
        return
    f.store_line(",".join(CSV_COLUMNS))
    for r in rows:
        var outcomes: Dictionary = r.get("outcomes", {})
        var fields := [
            String(r["slot"]), String(r["gear"]),
            Enums.rarity_key(int(r["rarity"])), str(int(r["morale"])),
            str(int(r["runs"])), str(int(r["clears"])),
            "%.4f" % float(r["clear_rate"]),
            "%.4f" % float(r["wilson_lo"]), "%.4f" % float(r["wilson_hi"]),
            str(int(r["median_rounds"])), str(int(r["p10_rounds"])),
            str(int(r["p90_rounds"])),
            "%.3f" % float(r["deaths_per_clear"]),
            "%.3f" % float(r["mean_deaths"]),
            "%.2f" % float(r["mean_mistakes"]),
            String(r["top_wipe_cause"]),
            str(int(outcomes.get("victory", 0))), str(int(outcomes.get("wipe", 0))),
            str(int(outcomes.get("soft_wipe", 0))), str(int(outcomes.get("attrition", 0))),
        ]
        f.store_line(",".join(fields))
    f.close()


## Read a CSV back as key -> {column: raw string}. Comment lines are skipped so
## the committed baseline can carry its own provenance at the top of the file —
## a bare grid of numbers with no note about when and why it was taken is the
## kind of artifact nobody dares regenerate.
func _read_csv(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return {}
    var header: Array = []
    var out := {}
    while not f.eof_reached():
        var line := f.get_line().strip_edges()
        if line.is_empty() or line.begins_with("#"):
            continue
        var parts := line.split(",")
        if header.is_empty():
            for p in parts:
                header.append(p)
            continue
        var row := {}
        for i in mini(header.size(), parts.size()):
            row[header[i]] = parts[i]
        out["%s/%s/%s/m%s" % [row.get("slot", "?"), row.get("gear", "?"),
            row.get("rarity", "?"), row.get("morale", "?")]] = row
    f.close()
    return out


# ---------------------------------------------------------------- helpers

func _arg_value(args: PackedStringArray, name: String) -> String:
    for i in args.size():
        if args[i] == name and i + 1 < args.size():
            return args[i + 1]
        if args[i].begins_with(name + "="):
            return args[i].substr(name.length() + 1)
    return ""


func _int_arg(args: PackedStringArray, name: String, fallback: int) -> int:
    var raw := _arg_value(args, name)
    return fallback if raw.is_empty() else maxi(1, raw.to_int())


## The first cell where Common and Legendary at the same morale give genuinely
## different results. Comparing levers anywhere else is measuring a ceiling.
##
## Searches the RAID ladder only, unchanged by M6-BAL-01. Letting the new
## Adventure rows into the search would have moved the LEVER BALANCE reading
## this report has printed since it was written, without any lever changing —
## a headline number must not shift because the grid grew.
func _find_unsaturated_cell() -> Array:
    for slot in RAID_SLOTS:
        for gear in _gears_for(slot):
            var c = _cell(slot, gear, Enums.Rarity.COMMON, 55)
            var l = _cell(slot, gear, Enums.Rarity.LEGENDARY, 55)
            if c["clear_rate"] < 0.95 and l["clear_rate"] > 0.05 \
                    and absf(float(l["clear_rate"]) - float(c["clear_rate"])) > 0.1:
                return [slot, gear]
    return ["E3", "adventure"]


## Look up a swept cell. Asking for one the grid never ran is a BUG in the
## caller, not a result: silently returning zeros once made an unswept
## morale-65 cell print "0% clear, median 0 rounds" as though it were a
## measurement. An unswept cell has no reading, so say so instead of
## inventing one.
func _cell(slot: String, gear: String, rarity: int, morale: int) -> Dictionary:
    for r in _rows:
        if r["slot"] == slot and r["gear"] == gear \
                and int(r["rarity"]) == rarity and int(r["morale"]) == morale:
            return r
    var miss := "%s/%s/%s/m%d" % [slot, gear, Enums.rarity_key(rarity), morale]
    push_error("balance_sweep: no swept cell " + miss
        + " — the grid sweeps morales " + str(MORALES))
    if not miss in _lookup_failures:
        _lookup_failures.append(miss)
    return {"clear_rate": -1.0, "median_rounds": -1, "p10_rounds": -1, "p90_rounds": -1,
        "mean_mistakes": -1.0, "deaths_per_clear": -1.0, "mean_deaths": -1.0,
        "wilson_lo": -1.0, "wilson_hi": -1.0, "top_wipe_cause": "?", "runs": 0}


func _top_key(counts: Dictionary) -> String:
    var best := ""
    var best_n := -1
    for k in counts:
        if int(counts[k]) > best_n:
            best_n = int(counts[k])
            best = String(k)
    return best if not best.is_empty() else "-"


func _median(values: Array) -> int:
    if values.is_empty():
        return 0
    var v := values.duplicate()
    v.sort()
    return int(v[v.size() / 2])


## Nearest-rank percentile. Deliberately not interpolated: rounds are integers
## and an interpolated "p90 = 17.4 rounds" is a number the game cannot produce.
func _percentile(values: Array, q: float) -> int:
    if values.is_empty():
        return 0
    var v := values.duplicate()
    v.sort()
    var idx := clampi(int(round(q * float(v.size() - 1))), 0, v.size() - 1)
    return int(v[idx])


func _mean(values: Array) -> float:
    if values.is_empty():
        return 0.0
    var total := 0
    for x in values:
        total += int(x)
    return float(total) / float(values.size())


## 95% Wilson score interval (z = 1.96). docs/14 §9.3 asks for it by name, and
## it is the right one here rather than the normal approximation: the sweep
## routinely reports 0/8 and 8/8, where the normal interval has zero width and
## claims a certainty eight runs cannot buy.
func _wilson(clears: int, runs: int) -> Array:
    if runs <= 0:
        return [0.0, 0.0]
    var z := 1.96
    var n := float(runs)
    var p := float(clears) / n
    var denom := 1.0 + z * z / n
    var centre := (p + z * z / (2.0 * n)) / denom
    var half := z * sqrt(p * (1.0 - p) / n + z * z / (4.0 * n * n)) / denom
    return [maxf(0.0, centre - half), minf(1.0, centre + half)]
