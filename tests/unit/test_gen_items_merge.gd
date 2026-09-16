extends "res://tests/TestCase.gd"
## The generator must MERGE, never clobber.
##
## docs/09 §13.5 is explicit that part of the item line is hand-written and
## always will be: *"Hand-author, always: capstones (Boss 5), trinkets, and any
## item with a joke in it. Nine capstones, four Raid charms and four Adventure
## charms per tier is 85 hand-written items across the game."*
##
## `tools/gen_items.gd` writes those same files. Without a rule, the first
## person to write a joke into a capstone loses it on the next regeneration —
## and finds out days later, with no error and nothing in the diff to explain
## it. The rule is one flag: a row carrying `"hand_authored": true` wins over
## the generated row with the same id, and a hand-authored row with no generated
## counterpart is kept as well.
##
## Tested against the real static rather than by running the generator, because
## a test that regenerated `data/` would rewrite the repository as a side effect.

const Gen = preload("res://tools/gen_items.gd")

const FIXTURE := "user://test_gen_merge.json"


func after_each() -> void:
    if FileAccess.file_exists(FIXTURE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE))


func _write(doc: Dictionary) -> void:
    var f := FileAccess.open(FIXTURE, FileAccess.WRITE)
    f.store_string(JSON.stringify(doc, "  "))
    f.close()


func test_a_hand_authored_row_survives_regeneration() -> void:
    _write({"items": [
        {"id": "ITM_T2_RAID_WPN_CLR_FINAL", "name": "The Very Last Word",
         "hand_authored": true, "stats": {"mana": 26}},
    ]})
    var fresh := {"items": [
        {"id": "ITM_T2_RAID_WPN_CLR_FINAL", "name": "TIER2 Cleric Weapon",
         "stats": {"mana": 26}},
        {"id": "ITM_T2_RAID_WARBARD_FEET", "name": "TIER2's Boots", "stats": {"ac": 6}},
    ]}
    var merged: Dictionary = Gen._merge_hand_authored(FIXTURE, fresh)
    var by_id := {}
    for row in merged["items"]:
        by_id[String(row["id"])] = row
    assert_eq(by_id.size(), 2, "the generated row count is unchanged")
    assert_eq(String(by_id["ITM_T2_RAID_WPN_CLR_FINAL"]["name"]), "The Very Last Word",
        "the hand-authored capstone must win")
    assert_eq(String(by_id["ITM_T2_RAID_WARBARD_FEET"]["name"]), "TIER2's Boots",
        "and the generated rows beside it must not be touched")


func test_a_hand_authored_row_with_no_generated_twin_is_kept() -> void:
    # A joke item the generator has no rule for — which is most of what §13.5
    # means by "any item with a joke in it".
    _write({"items": [
        {"id": "ITM_T2_RAID_UNIV_TRINKET_JOKE", "name": "Someone Else's Problem",
         "hand_authored": true, "stats": {"hp": 1}},
    ]})
    var merged: Dictionary = Gen._merge_hand_authored(FIXTURE, {"items": [
        {"id": "ITM_T2_RAID_WARBARD_FEET", "name": "TIER2's Boots", "stats": {"ac": 6}},
    ]})
    assert_eq(merged["items"].size(), 2, "the extra row must be appended, not dropped")


func test_an_unmarked_edit_is_still_overwritten() -> void:
    # The other half of the rule, and the reason the flag exists: editing a
    # GENERATED row without claiming it is not authorship, it is a change that
    # will be regenerated away — and it should be, or the generator stops being
    # the source of truth for the 412 rows it owns.
    _write({"items": [
        {"id": "ITM_T2_RAID_WARBARD_FEET", "name": "I edited this by hand",
         "stats": {"ac": 999}},
    ]})
    var merged: Dictionary = Gen._merge_hand_authored(FIXTURE, {"items": [
        {"id": "ITM_T2_RAID_WARBARD_FEET", "name": "TIER2's Boots", "stats": {"ac": 6}},
    ]})
    assert_eq(String(merged["items"][0]["name"]), "TIER2's Boots",
        "an unmarked edit must not survive")


func test_a_file_that_is_not_there_yet_is_not_an_error() -> void:
    # The first run writes into an empty directory.
    var fresh := {"items": [{"id": "X", "name": "Y"}]}
    var merged: Dictionary = Gen._merge_hand_authored("user://no_such_file.json", fresh)
    assert_eq(merged["items"].size(), 1, "a missing file merges to the generated doc")


func test_the_shipped_tiers_carry_no_hand_authored_rows_yet() -> void:
    # A statement of where the work actually is: the generator produces the
    # capstones and charms at the right VALUES (docs/09 §13.2's capstone rule and
    # the scaled charm magnitudes), and what is still owed is §13.5's other half
    # — the names and the jokes — which is blocked on the tier words (BL-69).
    # When that lands, these rows gain the flag and this expectation changes.
    var marked := 0
    for tier in range(2, 6):
        for kind in ["adventure", "raid"]:
            var path := "res://data/items_t%d_%s.json" % [tier, kind]
            var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
            if not (parsed is Dictionary):
                continue
            for row in (parsed as Dictionary).get("items", []):
                if bool((row as Dictionary).get("hand_authored", false)):
                    marked += 1
    assert_eq(marked, 0,
        "no row claims to be hand-authored yet; when the tier words land, 68 will")

# ------------------------------ docs/14 §10.1 gate 2, wired at last (M6-EXP-06)

## `gen_items.gd -- check` rebuilds all sixteen generated files in memory and
## compares them to what is committed, writing nothing. It existed from the day
## the generator was written and had NO CALLER for as long — docs/15 BL-74
## recorded it as the one pre-export gate of six still owed.
##
## The check itself is a gate stage and cannot run inside the unit suite: it
## starts the engine and rebuilds 412 records. What CAN be asserted here, cheaply
## and usefully, is that the wiring exists and that the files say so — because a
## gate nobody calls is the exact failure this closes, and it would close again
## in silence if somebody dropped the stage.

const GENERATED := [
    "res://data/items_t2_adventure.json", "res://data/items_t2_raid.json",
    "res://data/items_t3_adventure.json", "res://data/items_t3_raid.json",
    "res://data/items_t4_adventure.json", "res://data/items_t4_raid.json",
    "res://data/items_t5_adventure.json", "res://data/items_t5_raid.json",
]


func test_the_gate_stage_is_actually_wired_into_verify() -> void:
    var gate := FileAccess.get_file_as_string("res://tools/verify.sh")
    assert_true(not gate.is_empty(), "tools/verify.sh must be readable")
    assert_true(gate.contains("res://tools/gen_items.gd -- check"),
        "the generator check has to be RUN by something or it is not a gate — "
        + "which is precisely how it sat uncalled from the day it was written")
    assert_true(gate.contains("0 file(s) differ"),
        "and the stage must read the generator's own verdict line")


func test_the_release_export_does_not_regenerate_anything() -> void:
    # docs/15 BL-74 is explicit about where this gate may NOT live: a release
    # build that mutates the tree it is packing is worse than the gap it closes.
    var ship := FileAccess.get_file_as_string("res://tools/export_build.sh")
    assert_true(not ship.is_empty(), "tools/export_build.sh must be readable")
    assert_false(ship.contains("gen_items.gd"),
        "the export must never run the generator — it packs the tree, it does "
        + "not rewrite it")


func test_every_generated_file_says_it_is_generated_and_how_to_keep_an_edit() -> void:
    # The note used to end "and nothing will warn you", which was true and is not
    # any more. A file that tells a reader the wrong thing about its own gate is
    # worse than one that says nothing.
    for path in GENERATED:
        var doc = JSON.parse_string(FileAccess.get_file_as_string(path))
        assert_true(doc is Dictionary, "%s must parse" % path)
        var notes := "
".join(PackedStringArray((doc as Dictionary).get("_notes", [])))
        assert_true(notes.contains("GENERATED FILE"),
            "%s must declare itself generated" % path)
        assert_true(notes.contains("hand_authored"),
            "%s must name the one sanctioned way to keep an edit" % path)
        assert_false(notes.contains("nothing will warn you"),
            "%s still claims a hand edit goes unnoticed, and it no longer does" % path)
        var src = (doc as Dictionary).get("_source", {})
        assert_true(String((src as Dictionary).get("generator", "")).contains("gen_items.gd"),
            "%s must name the generator that owns it" % path)
