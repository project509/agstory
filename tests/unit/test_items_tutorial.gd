extends "res://tests/TestCase.gd"
## data/items_tutorial.json — docs/09 §10.2 G12's pair of crap trinkets.
##
## These two rows are what canon asks for twice in one breath ("Adventure 0 …
## 1 crap trinket", "Tutorial Raid … 1 crap trinket") and what the game had never
## had. Everything around them shipped first: `GameState._grant_tutorial_trinket`
## and its once-only guard, the drop-pool bypass, the skip warning's fallback
## copy, and a test that BRANCHED on whether the rows existed. The ids named
## nothing, so a first clear of either tutorial handed over nothing — the sixth
## instrument this project has found complete and unarmed. See docs/15 BL-77.
##
## So the tests here are mostly about the seam rather than the numbers: does the
## id the shipped code names actually resolve, is the reward worse than the rung
## it is teaching you to reach, and can either of them leak into a rolled pool.

const E = preload("res://sim/model/Enums.gd")
const S = preload("res://sim/model/Stats.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")

const PATH := "res://data/items_tutorial.json"

const POWER := "ITM_T0_TUT_UNIV_TRINKET_POWER"
const HEALTH := "ITM_T0_TUT_UNIV_TRINKET_HEALTH"

var _data: Dictionary = {}
var _rows: Array = []
var _by_id: Dictionary = {}
var _db = null


func before_each() -> void:
    if not _rows.is_empty():
        return
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
    if parsed == null:
        fail("could not parse %s" % PATH)
        return
    _data = parsed
    _rows = _data.get("items", [])
    for it in _rows:
        _by_id[String(it.get("id", ""))] = it
    _db = DB.load_all()


# ---------------------------------------------------------------- the file

func test_the_file_is_tier_zero_and_declares_exactly_the_authored_pair() -> void:
    # docs/09 §12.1's tier column: "0 = starting gear and tutorial rewards".
    # The rungs are mounted at tier 1; the REWARD is tier 0, which is why the
    # filename carries no `_t1` suffix.
    assert_eq(int(_data.get("tier", -1)), 0, "tutorial rewards are tier 0")
    assert_eq(String(_data.get("source", "")), "tutorial")
    assert_eq(_rows.size(), 2, "docs/09 §10.2 G12 authors exactly two")
    assert_true(_by_id.has(POWER))
    assert_true(_by_id.has(HEALTH))


func test_ids_follow_the_id_grammar_with_its_new_source_token() -> void:
    # docs/09 §12.1 as amended by docs/15 BL-77: the SOURCE enumeration gained
    # `TUT`, because the same table's tier row already said tier 0 covers
    # tutorial rewards and there was no token to name one with.
    var re := RegEx.new()
    re.compile("^ITM_T[0-5]_(START|TUT|ADV|RAID|VEND|QUEST)_[A-Z0-9]+(_[A-Z0-9]+)+$")
    for it in _rows:
        var id := String(it["id"])
        assert_true(re.search(id) != null, "malformed id %s" % id)
        assert_true(id.begins_with("ITM_T0_TUT_"),
            "%s is a tutorial reward and must say so in its source field" % id)


func test_keys_resolve_and_every_row_cites_its_derivation() -> void:
    for it in _rows:
        var id := String(it["id"])
        assert_true(E.slot_from_key(String(it["slot"])) >= 0, "%s bad slot" % id)
        assert_true(E.family_from_key(String(it["family"])) >= 0, "%s bad family" % id)
        var errors := []
        S.from_dict(it["stats"], errors, id)
        assert_eq(errors.size(), 0, "%s: %s" % [id, str(errors)])
        # §10.2 is 🔷 PROPOSED, not ✅ CANON — canon asked for "a crap trinket"
        # and never gave a stat line — so both rows are non-canon and both owe a
        # derivation. ContentDB enforces this at load; it is asserted here too so
        # the reason is written down where the numbers are.
        assert_false(bool(it.get("canon", true)), "%s: §10.2 is proposed" % id)
        assert_false(String(it.get("note", "")).is_empty(),
            "%s is non-canon and must cite its derivation" % id)


func test_the_stat_blocks_are_the_ones_doc_09_authored() -> void:
    # docs/09 §10.2 G12: "+1 Power" (canon's "+1 dps", ruled to Power because
    # §12.2 restricts `damage` to weapons) and "+2 HP".
    var power = _db.item(POWER)
    var health = _db.item(HEALTH)
    assert_ne(power, null, "the id GameState names must resolve")
    assert_ne(health, null)
    assert_eq(power.stats.power, 1)
    assert_eq(power.stats.hp, 0, "the power trinket carries one stat")
    assert_eq(health.stats.hp, 2)
    assert_eq(health.stats.power, 0)
    assert_eq(power.name, "Cracked Charm of Power")
    assert_eq(health.name, "Cracked Charm of Health")


# ------------------------------------------------- the reasons they exist

func test_both_are_visibly_worse_than_the_adventure_charms_they_precede() -> void:
    # docs/10 §9.2 requires it in terms, and docs/10 §9.3 makes the skip warning
    # name what is forfeited: a tutorial reward that BEAT Adventure 1's would
    # make that warning a lie. Measured against the live Adventure rows rather
    # than a copied number, so re-tuning those re-checks this.
    var adv_power = _db.item("ITM_T1_ADV_UNIV_TRINKET_POWER")
    var adv_health = _db.item("ITM_T1_ADV_UNIV_TRINKET_HEALTH")
    assert_ne(adv_power, null, "the Adventure charms are the comparison")
    assert_ne(adv_health, null)
    assert_true(_db.item(POWER).stats.power < adv_power.stats.power,
        "the tutorial power trinket must be worse than Adventure's")
    assert_true(_db.item(HEALTH).stats.hp < adv_health.stats.hp,
        "the tutorial health trinket must be worse than Adventure's")


func test_neither_can_ever_enter_a_rolled_drop_pool() -> void:
    # `source` is not a label here: Loot's non-raid pool selects on
    # `source == "adventure"` and the raid pool on `source == "raid"`, so
    # "tutorial" is unreachable by either by construction. This is what makes
    # the once-only fixed grant the ONLY way these two ever reach a roster.
    for id in [POWER, HEALTH]:
        var it = _db.item(id)
        assert_eq(it.source, "tutorial", "%s must not be adventure or raid loot" % id)
        assert_eq(it.tier, 0)
        assert_eq(it.drop_encounter, -1, "a fixed grant drops from no encounter")


func test_the_skip_warnings_fallback_copy_still_matches_the_real_item() -> void:
    # docs/10 §9.3 requires the skip warning to "name the forfeited item and its
    # stat", so `GameState.tutorial_reward_line` prints the item when the content
    # set has it and `TUTORIAL_TRINKET_LINE` when it does not. Two authors for
    # one sentence is a drift waiting to happen — and while the rows did not
    # exist, the fallback was the ONLY thing anyone ever read, so nothing would
    # have noticed it diverging. They must agree character for character.
    var line: Dictionary = GameStateScript.TUTORIAL_TRINKET_LINE
    var named: Dictionary = GameStateScript.TUTORIAL_TRINKET
    for slot in named.keys():
        var it = _db.item(String(named[slot]))
        assert_eq(it.describe(), String(line.get(slot, "")),
            "%s: the fallback copy and the item say different things" % slot)


func test_the_ids_the_shipped_grant_names_are_these_ids() -> void:
    # The failure this whole item was: `TUTORIAL_TRINKET` named two ids that
    # resolved to null, `_grant_tutorial_trinket` appended nothing, and every
    # test around it passed. One assertion stops that returning.
    var named: Dictionary = GameStateScript.TUTORIAL_TRINKET
    assert_eq(String(named.get("A0", "")), POWER, "Adventure 0 pays the power charm")
    assert_eq(String(named.get("TR", "")), HEALTH, "the Tutorial Raid pays the health charm")
    for slot in named.keys():
        assert_ne(_db.item(String(named[slot])), null,
            "%s names %s, which is not in the content set" % [slot, named[slot]])
