extends SceneTree
## Produces the committed save fixtures under `tests/fixtures/saves/`.
##
##   godot --headless --path . --script res://tests/fixtures/make_save_fixtures.gd
##
## READ `tests/fixtures/saves/README.md` BEFORE RUNNING THIS. The fixtures are the only
## proof the migration chain works, and regenerating them at the CURRENT save version
## silently deletes that proof: a v10 fixture rewritten as v12 still loads, still passes,
## and no longer tests anything. docs/14 §7.3's second non-negotiable is "every migration
## gets a test with a committed fixture save at the old version" — committed being the
## operative word. This script exists so the fixtures are reproducible and their contents
## explainable, not so they are cheap to replace.
##
## HOW THE OLDER SHAPES ARE MADE. There is no v10 build to run any more, so the v10 and
## v11 bodies are the v12 body with the blocks those versions ADDED removed, and the
## version stamped down in both the header and the body. That is exactly what the older
## `to_dict()` emitted — this script asserts it, key for key, against the key lists read
## out of git at commits f2bc62a (v10) and 2618989 (v11). If an assertion here fails, the
## lists below are stale and the history is the thing to trust.

const GameStateScript = preload("res://game/core/GameState.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")
const ContentDB = preload("res://sim/content/ContentDB.gd")

const OUT_DIR := "res://tests/fixtures/saves"

## The campaign the fixture records, fixed so a regeneration produces the same guild.
const GUILD := "The Least Worst"
const SEED := 1337
const ENCOUNTER := "t1_raid_e1"
const ATTEMPTS := 3
const DAY := 18
const PLAYED_SECONDS := 2730          # 45 minutes, so the load menu reads "45 minutes in"

## What v11 added over v10, and v12 over v11 — the two SAVE_VERSION bumps in the log
## (2618989 "the counters the game showed the player and never wrote" and 22edc80 "the
## flag registry, two more BIG-dumb conditions, and a seam for nine quirks").
const ADDED_IN_V11 := ["tavern_board", "board_rolled"]
const ADDED_IN_V12 := ["wipe_streaks", "bullet_triggers", "bullet_tier",
    "legendary_warned"]
## v13 added the record of which tutorial rungs were skipped, under docs/10
## §9.3's skippable-with-warning rule (commit "Adventure 0 and the Tutorial
## Raid"). A v12 save predates the tutorials existing, so its absence is the
## truthful shape rather than a missing field.
const ADDED_IN_V13 := ["skipped_tutorials"]
const ADDED_IN_V14 := ["completed", "completed_on_day", "completion_seen"]
## v15 added the three lifetime counters docs/11 §11.2's reward cap is a share
## of (audit M5-QAB-5). A v14 save recorded no history at all, so their absence
## is the truthful shape rather than a missing field.
const ADDED_IN_V15 := ["gold_earned_lifetime", "rp_earned_lifetime",
    "items_sold_lifetime"]
## v16 connected docs/02 §4.4's record wall (audit M5-QAB-6). A v15 save was
## written by a build where nothing could be earned at all, so the absence of
## all three is the truthful shape.
const ADDED_IN_V16 := ["achievements_earned", "achievements_claimed", "town_flags"]
## v17 added docs/14 §7.1's last four blocks (ship plan W7-SAVE) and froze the
## format. A v16 save was written by a build that never kept a report to replay,
## never queued a departure across a tick and never counted a fastest clear, so
## the absence of all four is the truthful shape.
const ADDED_IN_V17 := ["active_run", "log_tail", "best_rounds", "pending_deltas"]


func _initialize() -> void:
    var db = ContentDB.load_all()
    if not db.is_valid():
        push_error("fixtures: content failed validation — " + db.error_report())
        quit(1)
        return

    var state = GameStateScript.new()
    state.reset()
    state.set_content(db)
    state.new_game(GUILD, SEED)

    # A campaign with something in every block docs/14 §7.1 asks for: attempts and
    # clears, a morale ledger written by real attempts, loot waiting to be handed out,
    # a furnishing placed, a candidate board rolled, and one raider gone.
    var encounter = db.encounter(ENCOUNTER)
    for i in ATTEMPTS:
        var party: Array = state.roster.slice(0, mini(int(encounter.party_size),
            state.roster.size()))
        var loadout: Dictionary = state.build_loadout(party)
        var result = state.run_attempt(party, encounter, SEED + i, loadout)
        state.record_attempt(ENCOUNTER, result, party, {"loadout": loadout})
        state.advance_day()

    state.add_gold(3000)
    if not state.roster.is_empty():
        state.buy_furnishing("straw_cot", String(state.roster[0].id))
    state.refresh_board()
    if state.roster.size() > 1:
        state.dismiss_raider(String(state.roster[state.roster.size() - 1].id))
    state.day = DAY
    state.played_seconds = PLAYED_SECONDS

    # `write_to` creates SAVE_DIR and uses it for the rename fallback, so point it at the
    # fixture directory rather than at a player's guild folder.
    SaveGame.SAVE_DIR = OUT_DIR
    var current := "%s/v%d_sample.json" % [OUT_DIR, GameStateScript.SAVE_VERSION]
    var problem := SaveGame.write_to(current, state)
    if not problem.is_empty():
        push_error("fixtures: " + problem)
        quit(1)
        return

    var doc = JSON.parse_string(FileAccess.get_file_as_string(current))
    var v16 := _downgrade(doc, 16, ADDED_IN_V17)
    var v15 := _downgrade(v16, 15, ADDED_IN_V16)
    var v14 := _downgrade(v15, 14, ADDED_IN_V15)
    var v13 := _downgrade(v14, 13, ADDED_IN_V14)
    var v12 := _downgrade(v13, 12, ADDED_IN_V13)
    var v11 := _downgrade(v12, 11, ADDED_IN_V12)
    var v10 := _downgrade(v11, 10, ADDED_IN_V11)
    _write("%s/v16_sample.json" % OUT_DIR, v16)
    _write("%s/v15_sample.json" % OUT_DIR, v15)
    _write("%s/v14_sample.json" % OUT_DIR, v14)
    _write("%s/v13_sample.json" % OUT_DIR, v13)
    _write("%s/v12_sample.json" % OUT_DIR, v12)
    _write("%s/v11_sample.json" % OUT_DIR, v11)
    _write("%s/v10_sample.json" % OUT_DIR, v10)

    print("wrote v10, v11, v12, v13, v14, v15, v16 and v%d fixtures to %s"
        % [GameStateScript.SAVE_VERSION, OUT_DIR])
    print("  v10 keys: %d   v11 keys: %d   v%d keys: %d" % [
        (v10["body"] as Dictionary).size(), (v11["body"] as Dictionary).size(),
        GameStateScript.SAVE_VERSION, (doc["body"] as Dictionary).size()])
    quit(0)


## One version step backwards: drop the keys that version added and stamp the number in
## both places it is written. The header and the body each carry `save_version` and the
## loader reads the header's, so leaving the body's behind would make the fixture lie
## about itself in the one field a migration is keyed on.
func _downgrade(doc: Dictionary, to_version: int, added: Array) -> Dictionary:
    var out: Dictionary = doc.duplicate(true)
    var body: Dictionary = out["body"]
    for key in added:
        if not body.has(key):
            push_error("fixtures: v%d body has no %s to drop — the key lists are stale"
                % [to_version + 1, key])
        body.erase(key)
    body["save_version"] = to_version
    (out["header"] as Dictionary)["save_version"] = to_version
    return out


func _write(path: String, doc: Dictionary) -> void:
    var f := FileAccess.open(path, FileAccess.WRITE)
    if f == null:
        push_error("fixtures: could not write " + path)
        return
    f.store_string(JSON.stringify(doc, "  "))
    f.close()
