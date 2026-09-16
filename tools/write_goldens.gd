extends SceneTree
## Regenerate the golden event logs.
##
##   godot --headless --path . --script res://tools/write_goldens.gd
##
## Run this ONLY when the simulation changed on purpose. The resulting diff is
## the review surface: it shows exactly how behaviour moved, fight by fight.
## If you find yourself running it to make a red test go green, stop and read
## the diff instead — that is the drift the goldens exist to catch.

const Scenarios = preload("res://tests/golden/Scenarios.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const Sim = preload("res://sim/core/RaidSim.gd")

func _initialize() -> void:
    var db = DB.load_all()
    if not db.is_valid():
        print("CONTENT INVALID — refusing to write goldens")
        print(db.error_report())
        quit(1)
        return

    for name in Scenarios.names():
        var spec: Dictionary = Scenarios.SCENARIOS[name]
        var roster := Scenarios.build_roster(spec, db)
        var enc = db.encounter_at_slot(String(spec["encounter"]))
        var res = Sim.run(roster, enc, db, int(spec["seed"]))

        # A 300KB event dump is not a review surface, it is noise. Store the
        # readable story beats plus a hash of the COMPLETE stream: the hash
        # catches any drift at all, and the story lines say what changed.
        var E = load("res://sim/model/Enums.gd")
        var story := []
        for e in res.log.at_tier(E.LogTier.STORY):
            story.append(e.describe())
        var doc := {
            "scenario": name,
            "why": spec["why"],
            "encounter": enc.id,
            "seed": int(spec["seed"]),
            "outcome": res.outcome_key(),
            "rounds": res.rounds,
            "mistakes": res.mistake_count,
            "damage_dealt": res.damage_dealt,
            "healing_done": res.healing_done,
            "survivors": res.survivors.size(),
            "event_count": res.log.size(),
            "full_log_sha256": res.log.to_json().sha256_text(),
            "story": story,
        }
        var path := "res://tests/golden/%s.json" % name
        var f := FileAccess.open(path, FileAccess.WRITE)
        f.store_string(JSON.stringify(doc, "  "))
        f.close()
        print("wrote %-26s %-10s %2d rounds  %3d mistakes  %4d events"
            % [name, res.outcome_key(), res.rounds, res.mistake_count, res.log.size()])
    print("GOLDENS WRITTEN")
    quit(0)
    return
