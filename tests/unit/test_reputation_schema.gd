extends "res://tests/TestCase.gd"
## docs/03 §9's data shape against the file that implements it (audit M3-TUNE-02 (3)).
##
## `data/reputation.json` `_notes[3]` has claimed since the extraction that "keys
## beginning with `_` are ... ignored by every loader and by the key-parity test".
## There was no key-parity test. This is it, and it fails in BOTH directions: a key
## the fence names that the file does not carry, and a key the file carries that the
## fence never mentions. The fence is read from the doc rather than copied here, so
## a retune that adds a lever has to write it down in §9 or go red — and a §9 rewrite
## that drops a column the code reads goes red the same way.
##
## The fence is the block under "## 9. Data shape for implementation" that starts
## `res://data/reputation.json` (the corrected one, build/plan/handoff-tuning.md §1).
## While the doc still carries the `.tres` fence this file was written against, the
## parity test fails and says so by name — that is the finding, not a harness gap.

const Reputation = preload("res://sim/core/Reputation.gd")
const Consumables = preload("res://sim/core/Consumables.gd")
const Enums = preload("res://sim/model/Enums.gd")

const DATA := "res://data/reputation.json"
const DOC := "res://docs/03-guild-reputation.md"
const SECTION := "## 9. Data shape for implementation"
const FENCE_HEAD := "res://data/reputation.json"


# ---------------------------------------------------------------- readers

## The raw file, `_` keys and all — `Reputation.normalize()` drops them, and this
## test is about the file as authored.
func _raw() -> Dictionary:
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA))
    assert_eq(typeof(parsed), TYPE_DICTIONARY, "%s must be a JSON object" % DATA)
    return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


## Every key of a dictionary that is not provenance, sorted.
func _data_keys(d: Dictionary) -> Array:
    var out: Array = []
    for k in d:
        if not String(k).begins_with("_"):
            out.append(String(k))
    out.sort()
    return out


## The §9 fence's lines out of a doc's text, or [] when the corrected fence is not there.
func _parse_fence(doc: String) -> Array:
    var at := doc.find(SECTION)
    if at < 0:
        return []
    var head := doc.find(FENCE_HEAD, at)
    if head < 0:
        return []
    var close := doc.find("```", head)
    if close < 0:
        return []
    return doc.substr(head, close - head).split("\n")


## The shipped doc's fence, or [] with a failure that names what is missing.
func _fence_lines() -> Array:
    var lines := _parse_fence(FileAccess.get_file_as_string(DOC))
    assert_true(not lines.is_empty(),
        "docs/03 §9 must carry a fence starting '%s' under '%s' — the corrected fence "
        % [FENCE_HEAD, SECTION] + "is build/plan/handoff-tuning.md §1 (audit M3-TUNE-02 (2))")
    return lines


## `  key: type` at two-space indent is a top-level key of the fence.
func _fence_top_keys(lines: Array) -> Array:
    var rx := RegEx.new()
    rx.compile("^  ([a-z_]+):")
    var out: Array = []
    for line in lines:
        var m := rx.search(String(line))
        if m != null:
            out.append(m.get_string(1))
    out.sort()
    return out


## `#   key: type` — a key of one rank row, listed under `ranks:` in the fence.
func _fence_rank_keys(lines: Array) -> Array:
    var rx := RegEx.new()
    rx.compile("#   ([a-z_]+):")
    var out: Array = []
    for line in lines:
        var m := rx.search(String(line))
        if m != null:
            out.append(m.get_string(1))
    out.sort()
    return out


func _missing(from: Array, in_other: Array) -> Array:
    var out: Array = []
    for k in from:
        if not in_other.has(k):
            out.append(k)
    return out


# ---------------------------------------------------------------- the parity

func test_the_fence_and_the_file_name_the_same_top_level_keys() -> void:
    var lines := _fence_lines()
    if lines.is_empty():
        return
    var doc_keys := _fence_top_keys(lines)
    var file_keys := _data_keys(_raw())
    assert_true(doc_keys.size() > 5, "the fence must list keys: %s" % str(doc_keys))
    assert_eq(_missing(doc_keys, file_keys), [],
        "docs/03 §9 names keys data/reputation.json does not carry")
    assert_eq(_missing(file_keys, doc_keys), [],
        "data/reputation.json carries keys docs/03 §9 never mentions")

func test_the_fence_and_the_file_name_the_same_per_rank_keys() -> void:
    var lines := _fence_lines()
    if lines.is_empty():
        return
    var doc_keys := _fence_rank_keys(lines)
    var ranks: Array = _raw().get("ranks", [])
    assert_eq(ranks.size(), Enums.REPUTATION_KEYS.size(), "one row per canon rank")
    for row in ranks:
        var file_keys := _data_keys(row)
        assert_eq(_missing(doc_keys, file_keys), [],
            "docs/03 §9 names rank columns the '%s' row does not carry"
            % String((row as Dictionary).get("key", "?")))
        assert_eq(_missing(file_keys, doc_keys), [],
            "the '%s' row carries columns docs/03 §9 never mentions"
            % String((row as Dictionary).get("key", "?")))

func test_the_parity_fails_in_both_directions() -> void:
    # The reader and the diff, proved on a fence that is wrong both ways at once, so
    # "fails both ways" is a property this file demonstrates rather than promises. The
    # synthetic fence drops `ranks` and `pity_threshold`, adds `awards`, drops the rank
    # column `sell_rate` and adds `buy_pct` — the shape of the old `.tres` block.
    var fake := "\n".join(PackedStringArray([
        SECTION, "", "```", FENCE_HEAD,
        "  schema_version: int = 1",
        "  rungs: Array                       # one row per canon rank:",
        "                                     #   key: String",
        "                                     #   rp_threshold: int",
        "                                     #   buy_pct: float",
        "  awards: Dictionary",
        "  raid_awards: Dictionary",
        "```",
    ]))
    var lines := _parse_fence(fake)
    assert_true(lines.size() >= 8, str(lines))
    assert_eq(String(lines[0]), FENCE_HEAD)
    var top := _fence_top_keys(lines)
    assert_eq(top, ["awards", "raid_awards", "rungs", "schema_version"])
    var file_keys := _data_keys(_raw())
    assert_true(_missing(top, file_keys).has("awards"), "a doc key the file lacks is reported")
    assert_true(_missing(file_keys, top).has("ranks"), "a file key the doc lacks is reported")
    var rank := _fence_rank_keys(lines)
    assert_eq(rank, ["buy_pct", "key", "rp_threshold"])
    var row_keys := _data_keys(_raw()["ranks"][0])
    assert_true(_missing(rank, row_keys).has("buy_pct"))
    assert_true(_missing(row_keys, rank).has("sell_rate"))
    assert_true(_parse_fence("no section here").is_empty(), "no fence, no lines")

func test_every_rank_row_carries_the_same_columns() -> void:
    # A column present on five rows and missing on the sixth would read as that rank's
    # accessor default — silently, since `rank_row().get(key, default)` never complains.
    var ranks: Array = _raw().get("ranks", [])
    assert_true(ranks.size() > 1)
    var first := _data_keys(ranks[0])
    for row in ranks:
        assert_eq(_data_keys(row), first,
            "row '%s' differs from row '%s'" % [
                String((row as Dictionary).get("key", "?")),
                String((ranks[0] as Dictionary).get("key", "?"))])


# ---------------------------------------------------------------- the exemption

func test_provenance_keys_exist_and_the_loader_drops_them() -> void:
    # `_notes[3]`'s claim has two halves. The file really does carry `_` keys at both
    # levels (otherwise the exemption guards nothing), and `normalize()` really does
    # drop them (otherwise a `_doc` string would be a column a designer could retune).
    var raw := _raw()
    assert_true(raw.has("_notes"), "the file's provenance block")
    assert_true(raw.has("_source"))
    var underscored := 0
    for row in raw.get("ranks", []):
        for k in row:
            if String(k).begins_with("_"):
                underscored += 1
    assert_true(underscored > 0, "every rank row cites its doc")
    var clean: Dictionary = Reputation.normalize(raw)
    for k in clean:
        assert_false(String(k).begins_with("_"), "normalize() must drop '%s'" % String(k))
    for row in clean.get("ranks", []):
        for k in row:
            assert_false(String(k).begins_with("_"),
                "normalize() must drop the rank rows' '%s'" % String(k))

func test_the_loader_reads_every_column_the_file_carries_and_no_other() -> void:
    # The third side of the triangle, and the one that holds without the doc:
    # `normalize()` rebuilds each rank row from a fixed key list and fills every
    # top-level lever it expects with a default. So a column the file carries that the
    # loader ignores, or a lever the loader wants that the file lacks, shows up as a
    # difference between the raw keys and the normalized ones.
    var raw := _raw()
    var clean: Dictionary = Reputation.normalize(raw)
    assert_eq(_data_keys(clean), _data_keys(raw),
        "the loader's levers and the file's keys must be the same set")
    var raw_ranks: Array = raw.get("ranks", [])
    var clean_ranks: Array = clean.get("ranks", [])
    assert_eq(clean_ranks.size(), raw_ranks.size())
    for i in raw_ranks.size():
        assert_eq(_data_keys(clean_ranks[i]), _data_keys(raw_ranks[i]),
            "row '%s': the loader's columns vs the file's"
            % String((raw_ranks[i] as Dictionary).get("key", "?")))

func test_the_note_that_claims_this_test_exists_still_points_here() -> void:
    # The sentence that was a lie for a wave. If the note is reworded, whoever does it
    # should know a test reads it.
    var notes: Array = _raw().get("_notes", [])
    var claimed := false
    for n in notes:
        if String(n).contains("key-parity test"):
            claimed = true
    assert_true(claimed, "data/reputation.json _notes[3] names the key-parity test")


# ---------------------------------------------------------------- stock_tier

func test_the_stock_tier_column_agrees_with_the_potion_ladder_at_every_rank() -> void:
    # `Reputation.market_stock_tier()` had no caller and no test, so its column was a
    # number nothing could contradict. Its own docstring promises "a test asserts the
    # two agree" with `Consumables.top_potion_tier()`, which the Market and the potion
    # purchase actually read. This is that test; the column is armed by it, and if a
    # future §9 pass drops `stock_tier`, this is the line to delete with it.
    for rank in Enums.all_reputation_ranks():
        assert_eq(Reputation.market_stock_tier(int(rank)),
            Consumables.top_potion_tier(int(rank)),
            "%s: docs/03 §7's stock rung vs docs/02 §6.2's potion tier"
            % Enums.reputation_key(int(rank)))
    assert_true(Reputation.is_valid(), str(Reputation.load_errors()))


# ---------------------------------------------------------------- town_unlock

func test_the_town_unlock_column_is_a_list_of_building_items_in_the_file() -> void:
    # W6-COPY, after audit M3-TUNE-05: the column keeps its NAME (so the §9
    # fence's parity above holds) and its VALUE is `[{building, text}]` — each
    # item tagged with a docs/02 §2.3 building id the Town can filter by, or
    # "" for a line that is nobody's building. Every id is one Buildings.gd
    # ladders; the prose docs/03 §7 prints is the items' texts joined.
    var Buildings = load("res://sim/core/Buildings.gd")
    for row in _raw().get("ranks", []):
        var col = (row as Dictionary).get("town_unlock", null)
        assert_true(col is Array and (col as Array).size() >= 1,
            "'%s': town_unlock is a non-empty list" % String(row.get("key", "?")))
        for item in (col as Array):
            assert_true(item is Dictionary, str(item))
            var b := String((item as Dictionary).get("building", "?"))
            assert_true(b.is_empty() or Buildings.LADDERS.has(b),
                "'%s' is not a docs/02 building id (row %s)" % [b, String(row.get("key", "?"))])
            assert_true(String((item as Dictionary).get("text", "")).length() > 0)
    assert_true(Reputation.town_unlock(Enums.ReputationRank.KNOWN).contains("Quest board"))
