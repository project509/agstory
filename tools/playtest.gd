extends SceneTree
## The playtest sweep: play the whole campaign, headlessly, and report whether a
## new guild can actually finish Tier 1.
##
## Usage:
##   godot --headless --path . --script res://tools/playtest.gd
##   godot --headless --path . --script res://tools/playtest.gd -- --full
##   godot --headless --path . --script res://tools/playtest.gd -- --seeds 24
##   godot --headless --path . --script res://tools/playtest.gd -- --verbose
##
## Prints `PLAYTEST OK` or `PLAYTEST FAILED (n)` so verify.sh can gate on it.
##
## ── WHAT THIS ANSWERS THAT NOTHING ELSE DOES ────────────────────────────────
## `tools/balance_sweep.gd` measures one ENCOUNTER against one gear stage, 1872
## times. `tests/unit/test_full_loop.gd` walks one lap of the UI. Neither can see
## the CHAIN: that E1 drops the gear E2 needs, at a rate a player reaches, at a
## morale the roster survives, on gold the guild can afford — eight rungs deep.
## Every one of those is a separate system that is individually tested and has
## never been asked to hold hands with the other seven.
##
## ── IT DRIVES THE CAMPAIGN, NOT THE UI ──────────────────────────────────────
## No screen is instantiated. It calls the same functions the screens call —
## `RaidPlan.next_open_mission()`, `RaidPlan.suggest_party()`,
## `GameState.record_attempt()`, `assign_suggested_loot()`, `sell_unusable_loot()`,
## `rest_until_recovered()`, `hire()` — which is why the ladder and the party
## suggestion were EXTRACTED into RaidPlan rather than reimplemented here. A
## harness that walked its own ladder or chalked its own twelve would prove a
## campaign nobody plays is completable.
##
## ── THE PLAYER IT SIMULATES ─────────────────────────────────────────────────
## A reasonable one, not an optimal one: it takes the board's own suggestions
## every time. It never reorders the chalked party, never holds loot back for a
## better owner, never farms a cleared rung for gold, and never skips a tutorial.
## That is deliberately the FLOOR — if the suggested line completes the campaign,
## a player who thinks about it will too. A harness that played perfectly would
## prove nothing about the game a person is handed.
##
## ── THE DAY CAP IS DERIVED, NOT PICKED ──────────────────────────────────────
## docs/15 Q-90 is the only documented attempts-per-rung figure in the project:
## "Target 3-5 attempts across 2-3 town cycles for a first Raid 1 clear." The cap
## is that upper bound, times the ladder's own length, times the most days one
## attempt can cost — a Day Tick plus docs/02 §4.3's slowest possible recovery.
## Nothing here invents a pacing number: change Q-90 or add a rung and the cap
## moves on its own.
##
## It is DELIBERATELY LOOSE. It is a runaway detector — the thing that stops an
## unwinnable rung spinning forever — and not a pacing assertion. Pacing is
## docs/03 §6.4's table and a human reads the report for it; the per-rung patience
## below and the WALL lines are what actually carry the finding.
##
## ── IF IT GOES RED, THAT IS A CONTENT FINDING ───────────────────────────────
## Audit M6-PLAY-01 says it in terms: a failure here is a loot-rate or encounter
## finding, not a harness bug. Measure it, write it into BACKLOG, and do not
## soften an encounter to make this tool go green.
##
## ── IT REFUSES A DEAD END (audit M6-PLAY-02) ────────────────────────────────
## After every hire, every attempt and every rest, `_can_still_make_progress()`
## asks whether the guild has ANY door left — a party it can field, a hire it
## can afford, or gear it could sell to afford one — and a guild with none is
## STUCK: dumped in full where it happened and a failure of the gate regardless
## of how many other seeds finished. Two consecutive rests that returned "limit"
## or "stalled", or an empty roster, are stuck the same way.

const GameStateScript = preload("res://game/core/GameState.gd")
const RaidPlan = preload("res://game/core/RaidPlan.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const ContentDB = preload("res://sim/content/ContentDB.gd")
const Recruitment = preload("res://sim/core/Recruitment.gd")
const Reputation = preload("res://sim/core/Reputation.gd")
const Economy = preload("res://sim/core/Economy.gd")
const Enums = preload("res://sim/model/Enums.gd")

## docs/15 Q-90's upper bound. The one documented attempts-per-rung figure.
const ATTEMPTS_PER_RUNG := 5
## An attempt is a Day Tick (docs/05 §7), and the town cycle after it is a rest.
## docs/02 §4.3's own worked example runs a recovery to ~30 Day Ticks and the
## SLOWEST possible case — a Common at 0 morale with no facilities — is 40, which
## `GameState.REST_DAY_LIMIT`'s comment already records. So an attempt can cost
## one day plus a full recovery, and this is what the cap is built from.
const SLOWEST_RECOVERY_DAYS := 40
const DAYS_PER_ATTEMPT := 1 + SLOWEST_RECOVERY_DAYS

const DEFAULT_SEEDS := 8
const FULL_SEEDS := 24

## How many seeds must finish for the campaign to count as completable. Seven of
## eight is audit M6-PLAY-01's own bound, kept as a SHARE so `--seeds` cannot
## quietly weaken it.
const MUST_COMPLETE_SHARE := 7.0 / 8.0

## The last rung. Named by slot rather than by id, because docs/10 §2 note 2
## forbids depending on an invented name and the harness must survive a rename.
const FINAL_TIER := 1
const FINAL_SLOT := "E5"

var _seeds := DEFAULT_SEEDS
var _verbose := false


func _initialize() -> void:
    for a in OS.get_cmdline_user_args():
        if a == "--full":
            _seeds = FULL_SEEDS
        elif a == "--verbose":
            _verbose = true
        elif a.begins_with("--seeds"):
            var parts := a.split("=")
            if parts.size() == 2 and String(parts[1]).is_valid_int():
                _seeds = maxi(1, int(parts[1]))

    # record_attempt autosaves (docs/14 §7.4): without this every verify.sh
    # run left "Playtest NNNNN" autosaves in the developer's own save dir
    # (report-W0-SHOT). The same redirect shot.gd and perf_probe.gd carry.
    var SaveGame = load("res://game/core/SaveGame.gd")
    SaveGame.SAVE_DIR = "user://playtest_saves"
    SaveGame.purge_all()

    var db = ContentDB.load_all()
    if not db.is_valid():
        push_error("playtest: content failed validation — " + db.error_report())
        print("PLAYTEST FAILED (content)")
        quit(1)
        return

    var runs: Array = []
    for i in _seeds:
        runs.append(_play(db, 1000 + i * 7919))
    _report(db, runs)


# ---------------------------------------------------------------- one guild

## One campaign, start to finish or until it stalls. Returns the record of it.
func _play(db, seed_value: int) -> Dictionary:
    var s = GameStateScript.new()
    s.reset()
    s.set_content(db)
    s.new_game("Playtest %d" % seed_value, seed_value)

    var cap := _day_cap(s)
    var run := {
        "seed": seed_value, "completed": false, "days": 0, "attempts": 0,
        "wipes": 0, "stalled_on": "", "reason": "", "clears": {},
        "peak_gold": s.gold, "final_gold": 0, "roster": 0, "morale": 0.0,
        "rungs": RaidPlan.ladder(s).size(), "skipped": [],
        "last_gear": "", "last_morale": 0.0, "stuck": "",
    }
    var bad_rests := 0

    while true:
        if s.day > cap:
            run["reason"] = "day cap (%d) reached" % cap
            break
        var enc = RaidPlan.next_open_mission(s)
        if enc == null:
            run["reason"] = "no mission open"
            break
        # The unthinking hire. Whether it was enough is not this line's call —
        # an Adventure fields six — so the solvency check below decides, after
        # every hire, whether a short roster is a short roster or a dead end.
        if s.roster.size() < Enums.RAID_SIZE:
            _try_hire(s)
        var why := _can_still_make_progress(s, db)
        if not why.is_empty():
            _mark_stuck(run, s, db, enc, why)
            break

        var party: Array = RaidPlan.suggest_party(s, enc, db)
        if party.size() < int(enc.party_size):
            # docs/04: the guild cannot field the rung. That is a roster problem,
            # and the harness reports it rather than fielding a short party the
            # game itself would refuse.
            run["stalled_on"] = String(enc.slot)
            run["reason"] = "cannot field %s: %d of %d" % [
                String(enc.slot), party.size(), int(enc.party_size)]
            break

        # What the guild walked in WITH, kept for the stall report: a rung that
        # wipes a well-geared happy party is an encounter finding, and one that
        # wipes a naked miserable party is an economy or morale finding. Without
        # this the report cannot tell a reader which it is looking at.
        run["last_gear"] = RaidPlan.gear_label(party, db)
        run["last_morale"] = _mean_of(party)
        var result = RaidSim.run(party, enc, db, s.next_raid_seed(),
            s.build_loadout(party))
        run["attempts"] = int(run["attempts"]) + 1
        var won: bool = result.cleared()
        if not won:
            run["wipes"] = int(run["wipes"]) + 1
        s.record_attempt(String(enc.id), result, party)

        if won and not run["clears"].has(String(enc.slot)):
            run["clears"][String(enc.slot)] = s.day
        # The whole loot decision a reasonable player makes: take the suggestion,
        # sell what nobody can wear. docs/09 §14.3's one-click Suggested.
        s.assign_suggested_loot()
        s.sell_unusable_loot()
        run["peak_gold"] = maxi(int(run["peak_gold"]), s.gold)

        if won and int(enc.tier) == FINAL_TIER and String(enc.slot) == FINAL_SLOT:
            run["completed"] = true
            run["reason"] = "cleared %s" % FINAL_SLOT
            break
        # After every attempt: a wipe can cost the guild the raiders it needs to
        # try again, and the loot it just sold was the inventory it could have
        # hired on.
        why = _can_still_make_progress(s, db)
        if not why.is_empty():
            _mark_stuck(run, s, db, enc, why)
            break

        # Rest before the next rung, which is what the town is FOR (docs/05 §7).
        # A guild that cannot recover is the stall this harness exists to find.
        var rest: Dictionary = s.rest_until_recovered()
        var rest_reason := String(rest.get("reason", ""))
        if rest_reason == "empty":
            run["stalled_on"] = String(enc.slot)
            run["reason"] = "the guild disbanded"
            break
        bad_rests = bad_rests + 1 if BAD_REST_REASONS.has(rest_reason) else 0
        if bad_rests >= BAD_RESTS_IS_STUCK:
            _mark_stuck(run, s, db, enc,
                "rest_until_recovered() came back '%s' %d times in a row — the roster cannot recover"
                % [rest_reason, bad_rests])
            break
        # After every rest: departures during it can empty the bench.
        why = _can_still_make_progress(s, db)
        if not why.is_empty():
            _mark_stuck(run, s, db, enc, why)
            break
        if not run["completed"] and _stuck_on(s, enc):
            # A TUTORIAL is skippable and a real player would skip one they could
            # not beat — canon says so in terms ("Tutorials can be skip[ped], but
            # will offer a special loot piece ... players will be warned that they
            # will miss out on reward"), and docs/15 Q-90 makes the skip permanent.
            # So the harness takes the door the game offers rather than reporting
            # a stall the player would never actually sit in. It is still counted
            # and still printed as a WALL: using a documented escape hatch is not
            # the same as the rung being fine, and the report has to say which.
            if Reputation.is_tutorial_slot(String(enc.slot))                     and s.skip_tutorial(String(enc.id)):
                run["skipped"].append("%s after %d attempts" % [
                    String(enc.slot), s.attempt_count(String(enc.id))])
                run["stalled_on"] = String(enc.slot)
                continue
            run["stalled_on"] = String(enc.slot)
            run["reason"] = "%d attempts at %s without a clear" % [
                s.attempt_count(String(enc.id)), String(enc.slot)]
            break

    run["days"] = s.day
    run["final_gold"] = s.gold
    run["roster"] = s.roster.size()
    run["morale"] = _mean_morale(s)
    s.free()
    return run


## The per-rung patience, and it is Q-90's own upper bound rather than a multiple
## of it. The doc targets 3-5 attempts for a first clear; a rung that has eaten
## five and paid nothing has missed the documented target, which is exactly the
## signal this tool exists to raise. Saying WHICH rung is the whole value of it.
func _stuck_on(s, enc) -> bool:
    return s.attempt_count(String(enc.id)) >= ATTEMPTS_PER_RUNG


# ---------------------------------------------------------------- solvency

## Two bad rests in a row is a guild that cannot recover, not one that is slow.
## `rest_until_recovered()` returns "limit" when its 90-day backstop fired and
## "stalled" when a tick moved nobody; either once could be a clamp at the
## baseline, twice is the loop this harness exists to catch.
const BAD_RESTS_IS_STUCK := 2
const BAD_REST_REASONS := ["limit", "stalled"]


## Audit M6-PLAY-02's invariant — the one question the part-tests cannot ask:
## can this guild still DO anything? Returns "" while at least one door is open,
## or a sentence naming the dead end. Three doors, any one of which is enough:
##
##   (a) the roster can field the next open mission;
##   (b) somebody is sitting on the Tavern board at a price the purse covers —
##       `Recruitment.cost_of(Common, tier)` is the floor of that price, and the
##       board's own cheapest seat is what `hire()` would actually charge;
##   (c) unsold inventory — loose drops plus the roster's equipped gear — would
##       sell for at least `GameState.STARTING_GOLD`, docs/01 §8.0's "one Common
##       hire plus a farm run's potions": the purse the guild started solvent on.
##
## An empty roster is stuck immediately: docs/05 §6 calls that a disband, and a
## guild with nobody in it cannot take the attempt that would refresh the board.
##
## Static and pure over the state, so tests/unit/test_playtest_invariants.gd can
## hand it a hand-built guild without running a campaign.
static func _can_still_make_progress(state, db) -> String:
    if state.roster.is_empty():
        return "the roster is empty"
    var enc = RaidPlan.next_open_mission(state)
    var need: int = int(enc.party_size) if enc != null else Enums.RAID_SIZE
    var where := String(enc.slot) if enc != null else "the next rung"
    if state.roster.size() >= need:
        return ""
    var seat := _cheapest_seat(state)
    if seat >= 0 and seat <= int(state.gold):
        return ""
    var worth := _unsold_inventory_value(state, db)
    if worth >= int(GameStateScript.STARTING_GOLD):
        return ""
    var board := "nobody on the board"
    if seat >= 0:
        board = "the cheapest seat costs %d G" % seat
    return "%d of %d needed for %s, %d G in the purse (%s), and %d G of unsold inventory against the %d G a fresh guild starts on" % [
        state.roster.size(), need, where, int(state.gold), board, worth,
        int(GameStateScript.STARTING_GOLD)]


## What the cheapest candidate on the board would cost to hire, or -1 for an
## empty board. The same figure `hire()` charges and `_try_hire()` compares.
static func _cheapest_seat(state) -> int:
    var best := -1
    for who in state.tavern_board:
        var cost: int = Recruitment.cost_of(who.rarity, state.highest_unlocked_tier())
        if best < 0 or cost < best:
            best = cost
    return best


## Everything the guild could put on the Market's counter, at the rank's sell
## rate: the loose drops in `pending_loot` and every piece the roster is wearing.
static func _unsold_inventory_value(state, db) -> int:
    var items: Array = state.pending_loot.duplicate()
    if db != null:
        for r in state.roster:
            items.append_array(r.equipped_items(db))
    return Economy.total_sell_price(items, state.reputation_rank)


## Record a stuck state on the run and capture the whole picture at once — the
## roster, the purse, what the shelf would pay, the cleared set — for `_report()`
## to print UNCONDITIONALLY under the run's row, because a dead end nobody can
## read is a dead end nobody fixes. Captured here because the state is freed
## before the report runs. `_report()` then fails the gate on it.
func _mark_stuck(run: Dictionary, s, db, enc, why: String) -> void:
    run["stuck"] = why
    run["stalled_on"] = String(enc.slot) if enc != null else ""
    run["reason"] = "STUCK — %s" % why
    run["dump"] = [
        "day %d, gold %d, board %d seat(s), inventory would sell for %d G" % [
            s.day, s.gold, s.tavern_board.size(), _unsold_inventory_value(s, db)],
        "roster (%d): %s" % [s.roster.size(), _roster_line(s)],
        "cleared: %s" % str(run["clears"]),
        "attempts %d, wipes %d, skipped: %s" % [
            int(run["attempts"]), int(run["wipes"]), str(run["skipped"])],
    ]


func _roster_line(s) -> String:
    var parts: Array = []
    for r in s.roster:
        parts.append("%s %s %.0f" % [
            r.display_name, Enums.class_key(int(r.class_id)), float(r.morale)])
    return ", ".join(PackedStringArray(parts)) if not parts.is_empty() else "nobody"


## docs/15 Q-90's upper bound x the ladder's own length x a rest day per attempt.
func _day_cap(s) -> int:
    return maxi(1, RaidPlan.ladder(s).size()) * ATTEMPTS_PER_RUNG * DAYS_PER_ATTEMPT


## Hire whoever the board offers, cheapest first, while the roster is short and
## the gold holds. The unthinking version of the decision, on purpose.
func _try_hire(s) -> bool:
    if s.roster_is_full():
        return false
    var best := -1
    var best_cost := 1 << 30
    for i in s.tavern_board.size():
        # The same figure `hire()` charges: docs/11 §4.2's recruit price table,
        # which docs/11 calls "the only recruit price table in the project".
        var cost: int = Recruitment.cost_of(
            s.tavern_board[i].rarity, s.highest_unlocked_tier())
        if cost <= s.gold and cost < best_cost:
            best = i
            best_cost = cost
    if best < 0:
        return false
    return s.hire(best).is_empty()


func _mean_morale(s) -> float:
    return _mean_of(s.roster)


func _mean_of(who: Array) -> float:
    if who.is_empty():
        return 0.0
    var total := 0.0
    for r in who:
        total += float(r.morale)
    return total / float(who.size())


# ---------------------------------------------------------------- the report

func _report(db, runs: Array) -> void:
    var done := 0
    var days: Array = []
    print("")
    print("PLAYTEST — %d guild(s), Tier 1 start to finish" % runs.size())
    print("  seed        days  attempts  wipes  gold  roster  morale  outcome")
    for run in runs:
        var r: Dictionary = run
        if bool(r["completed"]):
            done += 1
            days.append(int(r["days"]))
        print("  %-10d  %4d  %8d  %5d  %4d  %6d  %6.1f  %s" % [
            int(r["seed"]), int(r["days"]), int(r["attempts"]), int(r["wipes"]),
            int(r["final_gold"]), int(r["roster"]), float(r["morale"]),
            String(r["reason"])])
        if not String(r["stalled_on"]).is_empty():
            print("      at the wall: %s, party morale %.0f" % [
                String(r["last_gear"]), float(r["last_morale"])])
        if not (r["skipped"] as Array).is_empty():
            print("      skipped: %s" % ", ".join(PackedStringArray(r["skipped"])))
        # A stuck run's dump is not behind --verbose: it is the finding.
        for line in r.get("dump", []):
            print("      %s" % String(line))
        if _verbose:
            print("      first clears: %s" % str(r["clears"]))

    print("")
    var need := int(ceil(float(runs.size()) * MUST_COMPLETE_SHARE))
    print("  %d of %d guild(s) cleared Tier 1 — %d needed" % [done, runs.size(), need])
    if not days.is_empty():
        days.sort()
        print("  median days to the last clear: %d" % days[days.size() / 2])

    # Where the failures piled up, which is the sentence a person acts on.
    var walls := {}
    for run in runs:
        var where := String((run as Dictionary)["stalled_on"])
        if not where.is_empty():
            walls[where] = int(walls.get(where, 0)) + 1
    for slot in walls:
        print("  WALL  %s stopped %d guild(s)" % [String(slot), int(walls[slot])])

    # A dead end is a failure on its own, whatever the completion count says: a
    # campaign that seven guilds finish and one cannot even keep playing is the
    # unrecoverable state audit M6-PLAY-02 exists to refuse. The full dump was
    # printed at the moment it happened (`_mark_stuck`); this is the tally.
    var stuck := 0
    for run in runs:
        if not String((run as Dictionary)["stuck"]).is_empty():
            stuck += 1
    if stuck > 0:
        print("  STUCK  %d guild(s) reached a state they could not play on from" % stuck)

    if done >= need and stuck == 0:
        print("")
        print("PLAYTEST OK")
        quit(0)
        return
    print("")
    print("  A red run here is a CONTENT finding (loot rate, encounter budget,")
    print("  morale recovery), not a harness bug. Measure it and write it down;")
    print("  do not soften an encounter to make this go green (audit M6-PLAY-01).")
    if stuck > 0:
        print("  A STUCK run is a solvency finding (audit M6-PLAY-02): the candidate")
        print("  answers go to docs/15, not into this harness.")
    print("PLAYTEST FAILED (%d of %d)" % [maxi(runs.size() - done, stuck), runs.size()])
    quit(1)
