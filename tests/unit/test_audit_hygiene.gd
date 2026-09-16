extends "res://tests/TestCase.gd"
## `build/plan/audit.json` is the loop's queue, and the loop's own brief says to
## orient from it rather than from recollection. That only works while it is
## true.
##
## In one week THIRTEEN open items turned out to be finished — the work had
## landed inside other items and nobody walked back to the plan. Each cost an
## iteration's orientation to discover by hand, and twice in a row it cost the
## pick itself: two chosen items were already done, so the iteration spent its
## first third choosing again.
##
## `tools/audit_stale.py` is the detector — it ranks open items by how much of
## what they NAME already exists, which is the shape all thirteen had. This file
## is the other half: the invariants that keep the queue's own shape honest, so
## that a stale entry is at least a well-formed stale entry and the tool has
## something consistent to read.
##
## It deliberately does NOT assert that no item is stale. Staleness is a
## judgement about the tree, not a property of the file, and a test that tried
## would either be the detector (slow, and it shells out) or a lie.

const AUDIT := "res://build/plan/audit.json"

## The statuses the loop's brief knows how to act on. A fourteenth spelling of
## "done" is how a queue stops being sortable.
const STATUSES := [
    "not-started", "partial", "done", "blocked-needs-human", "done-backlog-stale",
]

var _items: Array = []


func before_each() -> void:
    if not _items.is_empty():
        return
    var doc = JSON.parse_string(FileAccess.get_file_as_string(AUDIT))
    assert_true(doc is Dictionary, "the audit must parse")
    _items = (doc as Dictionary).get("items", [])


func test_the_queue_is_readable_at_all() -> void:
    assert_true(_items.size() > 100,
        "read %d items — the walk is broken, not the plan" % _items.size())


func test_every_item_has_an_id_and_no_two_share_one() -> void:
    # The loop cites these ids in commit messages, BUILD_STATE and BACKLOG. A
    # duplicate makes every one of those citations ambiguous.
    var seen := {}
    for raw in _items:
        var item: Dictionary = raw
        var id := String(item.get("id", ""))
        assert_false(id.is_empty(), "an item has no id: %s" % str(item.get("title", "")))
        assert_false(seen.has(id), "two items share the id %s" % id)
        seen[id] = true


func test_every_status_is_one_the_brief_knows() -> void:
    for raw in _items:
        var item: Dictionary = raw
        var status := String(item.get("actual_status", ""))
        assert_true(status in STATUSES,
            "%s has status '%s', which the loop brief cannot act on"
                % [String(item.get("id", "?")), status])


func test_an_open_item_says_what_is_left() -> void:
    # An open item with an empty `remaining_work` is unactionable: the next
    # iteration reads the title, cannot tell what is owed, and either re-derives
    # it or picks something else.
    for raw in _items:
        var item: Dictionary = raw
        var status := String(item.get("actual_status", ""))
        if status != "not-started" and status != "partial":
            continue
        assert_false(String(item.get("remaining_work", "")).strip_edges().is_empty(),
            "%s is open and says nothing about what is left" % String(item.get("id", "?")))


func test_a_closed_item_says_what_it_did_and_owes_nothing() -> void:
    # The two halves of closing one. `remaining_work` left behind on a done item
    # is what the detector reads as an open claim, and a `done` with no note is a
    # decision nobody can review.
    for raw in _items:
        var item: Dictionary = raw
        if String(item.get("actual_status", "")) != "done":
            continue
        var id := String(item.get("id", "?"))
        assert_true(String(item.get("remaining_work", "")).strip_edges().is_empty(),
            "%s is done and still lists remaining work" % id)
        assert_false(String(item.get("remaining_work_note", "")).strip_edges().is_empty(),
            "%s is done and does not say what it did" % id)


func test_a_blocked_item_says_what_a_person_has_to_decide() -> void:
    # `blocked-needs-human` is the one status the loop may not pick up, so the
    # entry is the whole handover. An empty one blocks the item twice.
    for raw in _items:
        var item: Dictionary = raw
        if String(item.get("actual_status", "")) != "blocked-needs-human":
            continue
        assert_false(String(item.get("remaining_work", "")).strip_edges().is_empty(),
            "%s is blocked on a person and does not say on what"
                % String(item.get("id", "?")))


func test_every_item_carries_the_doc_it_answers_to() -> void:
    # The project's rule is that nothing is built from recollection. An item with
    # no `spec_source` is an instruction with no authority behind it.
    for raw in _items:
        var item: Dictionary = raw
        assert_false(String(item.get("spec_source", "")).strip_edges().is_empty(),
            "%s cites no source" % String(item.get("id", "?")))


func test_the_staleness_detector_is_where_the_brief_can_find_it() -> void:
    assert_true(FileAccess.file_exists("res://tools/audit_stale.py"),
        "the detector has to exist for the next iteration to run it")
    var src := FileAccess.get_file_as_string("res://tools/audit_stale.py")
    assert_true(src.contains("AUDIT STALENESS REPORTED"),
        "and print a sentinel a caller can grep")
    assert_true(src.contains("It is a DETECTOR, NOT A JUDGE")
            or src.contains("IT IS A DETECTOR, NOT A JUDGE"),
        "and say in its own header that a hit is a suspicion — the false "
        + "positive is an item whose PREMISE is that a symbol exists")


## The rows the ship plan (build/plan/ship/00-plan.md §1 W6-LEDGER) asked the
## queue to grow in wave 6: the findings CRITIC and the seven reports raised
## that no audit id tracked. A plan that names an id the queue does not carry
## is a citation into nothing — the same rot test_docs_links.gd guards for
## plan files, applied to the queue.
const WAVE6_ROWS := [
    "m6-forgiving-guild", "m6-ambient-effects", "m6-e4-m05-effect",
    "m6-e4-m08-window", "m6-e4-m09-cadence", "m6-mech-arms-register",
    "m6-kit-bard", "m6-kit-proposed", "M6-EXP-07", "M6-FINAL-05",
    "m6-legendary-busts", "m6-quill-hook",
]


func test_the_wave_6_rows_the_ship_plan_names_exist() -> void:
    var ids := {}
    for raw in _items:
        ids[String((raw as Dictionary).get("id", ""))] = true
    for id in WAVE6_ROWS:
        assert_true(ids.has(id), "the ship plan names audit row %s and the queue does not carry it" % id)
