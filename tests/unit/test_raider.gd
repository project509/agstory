extends "res://tests/TestCase.gd"
## sim/model/Raider.gd — the roster record.
##
## The canon anchor here is the four-person roster example in the raw notes:
## Natsuna 87 Very Happy, Bob 54 Content, Greg 31 Annoyed, Steve 14 Upset.
## If the morale band function drifts, that example stops reading correctly and
## these fail.

const R = preload("res://sim/model/Raider.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const E = preload("res://sim/model/Enums.gd")

var _db = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()

func _make(class_key: String, rarity: int = E.Rarity.COMMON, morale: int = 50):
    var r = R.new()
    r.id = "test-%s" % class_key
    r.display_name = class_key.capitalize()
    r.class_id = E.class_from_key(class_key)
    r.rarity = rarity
    r.morale = morale
    return r

func _equip_starting(r) -> void:
    for it in _db.starting_set(r.class_key()):
        var why: String = r.equip(_db, it)
        assert_eq(why, "", "could not equip %s: %s" % [it.id, why])

# ---------------------------------------------------------------- morale bands

func test_canon_roster_example_reproduces_exactly() -> void:
    # raw notes: the sample roster the designer wrote out.
    var cases := [
        ["Natsuna", "shaman", 87, "Very Happy"],
        ["Bob", "warrior", 54, "Content"],
        ["Greg", "rogue", 31, "Annoyed"],
        ["Steve", "mage", 14, "Upset"],
    ]
    for c in cases:
        var r = _make(c[1], E.Rarity.COMMON, c[2])
        r.display_name = c[0]
        assert_eq(r.morale_band_name(), c[3],
            "%s at %d should read '%s'" % [c[0], c[2], c[3]])

func test_morale_bands_are_half_open_lower_inclusive() -> void:
    # docs/15 Q-06: band_index = min(9, floor(morale/10)).
    assert_eq(E.morale_band(0), 0)
    assert_eq(E.morale_band(9), 0)
    assert_eq(E.morale_band(10), 1, "a tens value belongs to the HIGHER band")
    assert_eq(E.morale_band(79), 7)
    assert_eq(E.morale_band(80), 8)
    assert_eq(E.morale_band(100), 9, "100 clamps into the top band, not an eleventh")

func test_ten_bands_have_ten_distinct_names() -> void:
    # docs/15 Q-07 renamed the duplicate "Very Happy" at 70-80 to "Quite Happy".
    assert_eq(E.MORALE_BAND_NAMES.size(), 10)
    var seen := {}
    for n in E.MORALE_BAND_NAMES:
        assert_false(seen.has(n), "duplicate band name: %s" % n)
        seen[n] = true
    assert_eq(E.MORALE_BAND_NAMES[5], "Content", "canon calls 50-60 the base")
    assert_eq(E.MORALE_BAND_NAMES[9], "Loves Their Guild")

func test_morale_is_clamped_on_load() -> void:
    var r = R.from_dict({"class_id": "mage", "rarity": "common", "morale": 250})
    assert_eq(r.morale, 100)
    var r2 = R.from_dict({"class_id": "mage", "rarity": "common", "morale": -40})
    assert_eq(r2.morale, 0)

# ---------------------------------------------------------------- derived

func test_role_is_derived_from_class_not_stored() -> void:
    assert_eq(_make("warrior").role(_db), E.Role.MAIN_TANK)
    assert_eq(_make("shaman").role(_db), E.Role.CHAIN_HEALER)
    assert_eq(_make("shaman").role_group(_db), E.RoleGroup.HEALER)
    assert_eq(_make("monk").role_group(_db), E.RoleGroup.DPS)

func test_max_hp_uses_class_base_plus_gear() -> void:
    var w = _make("warrior")
    assert_eq(w.max_hp(_db), 120, "naked Warrior is base HP only")
    _equip_starting(w)
    assert_eq(w.max_hp(_db), 120, "canon starting gear carries no HP")
    # Adventure gear does: Warrior/Bard armour is +16 HP.
    for id in ["ITM_T1_ADV_WARBARD_HEAD", "ITM_T1_ADV_WARBARD_CHEST",
               "ITM_T1_ADV_WARBARD_LEGS", "ITM_T1_ADV_WARBARD_FEET"]:
        w.equip(_db, _db.item(id))
    assert_eq(w.max_hp(_db), 136, "docs/08 §6 publishes 136 for a geared Warrior")

func test_gear_stats_recomputed_never_cached() -> void:
    var c = _make("cleric")
    assert_true(c.gear_stats(_db).is_empty())
    _equip_starting(c)
    assert_eq(c.gear_stats(_db).ac, 5, "canon Cleric starting AC")
    c.unequip(_db, E.Slot.CHEST)
    assert_eq(c.gear_stats(_db).ac, 3, "removing the 2 AC chest must be visible immediately")

# ---------------------------------------------------------------- equipment

func test_starting_sets_equip_cleanly_for_every_class() -> void:
    var expected_ac := {
        "warrior": 7, "bard": 7, "monk": 6, "rogue": 5, "cleric": 5,
        "druid": 5, "shaman": 5, "mage": 4, "wizard": 4,
    }
    for key in E.CLASS_KEYS:
        var r = _make(key)
        _equip_starting(r)
        assert_eq(r.gear_stats(_db).ac, expected_ac[key], "%s starting AC" % key)

func test_cannot_equip_another_class_gear() -> void:
    var m = _make("mage")
    var why: String = m.equip(_db, _db.item("ITM_T1_RAID_WARBARD_HEAD"))
    assert_ne(why, "", "a Mage must not be able to wear the Warrior/Bard helm")
    assert_eq(m.item_in(_db, E.Slot.HEAD), null)

func test_two_handed_weapon_locks_the_off_hand() -> void:
    # Canon matrix: Monk, Mage and Wizard show "—" in the Off Hand column.
    var mage = _make("mage")
    assert_eq(mage.equip(_db, _db.item("ITM_T1_RAID_W2H_MAGE_BASIC")), "")
    assert_ne(mage.equip(_db, _db.item("ITM_T1_RAID_HEALOFF_OH")), "",
        "a two-handed caster has no off-hand slot at all")

func test_equipping_a_two_hander_clears_an_existing_off_hand() -> void:
    var w = _make("warrior")
    assert_eq(w.equip(_db, _db.item("ITM_T1_RAID_SHIELD_OH")), "")
    assert_ne(w.item_in(_db, E.Slot.OFF_HAND), null)
    # Warriors have no 2H in canon, so verify the rule directly on the Rogue's
    # dual-wield family instead: equipping a 2H clears the off hand.
    var monk = _make("monk")
    monk.equipment[E.Slot.OFF_HAND] = "ITM_T1_RAID_HEALOFF_OH"   # force an illegal state
    monk.equip(_db, _db.item("ITM_T1_RAID_W2H_MONK_BASIC"))
    assert_eq(monk.item_in(_db, E.Slot.OFF_HAND), null,
        "equipping a two-hander must clear the off hand")

func test_rogue_can_fill_both_hands_from_one_family() -> void:
    var rg = _make("rogue")
    var dagger = _db.item("ITM_T1_RAID_W1H_MH_DAGGER_BASIC")
    assert_eq(rg.equip(_db, dagger), "")
    rg.equipment[E.Slot.OFF_HAND] = dagger.id
    assert_eq(rg.gear_stats(_db).damage, 8, "two +4 daggers")

func test_empty_slots_respects_class_slot_availability() -> void:
    var mage = _make("mage")
    var empty: Array = mage.empty_slots(_db)
    assert_eq(empty.size(), 6, "seven slots minus the off hand a Mage does not have")
    assert_false(E.Slot.OFF_HAND in empty)
    var warrior = _make("warrior")
    assert_eq(warrior.empty_slots(_db).size(), 7)

# ---------------------------------------------------------------- status

func test_status_helpers() -> void:
    var r = _make("bard")
    assert_true(r.is_available())
    r.status = E.RaiderStatus.BENCHED
    assert_true(r.is_available(), "a benched raider is still on the roster")
    r.status = E.RaiderStatus.DEPARTED
    assert_false(r.is_available())
    assert_true(r.has_left())

func test_legendary_flag() -> void:
    var r = _make("shaman", E.Rarity.LEGENDARY, 90)
    assert_true(r.is_legendary())
    assert_false(_make("shaman").is_legendary())

# ---------------------------------------------------------------- display

func test_roster_line_matches_the_canon_format() -> void:
    # Canon writes: "Natsuna — 87 ❤️" / "Shaman — Very Happy"
    var r = _make("shaman", E.Rarity.LEGENDARY, 87)
    r.display_name = "Natsuna"
    var line := r.roster_line(_db)
    assert_true(line.contains("Natsuna"), line)
    assert_true(line.contains("87"), line)
    assert_true(line.contains("Shaman"), line)
    assert_true(line.contains("Very Happy"), line)

# ---------------------------------------------------------------- persistence

func test_round_trip_preserves_everything() -> void:
    var r = _make("druid", E.Rarity.EPIC, 73)
    r.display_name = "Greg"
    _equip_starting(r)
    r.backstory = [{"tag": "hates_being_benched", "text": "Sat out the last three."}]
    r.wishlist = ["ITM_T1_RAID_HEALER_CHEST"]
    r.traits = ["punctual"]
    r.runs_attended = 4
    r.wipes_witnessed = 2
    r.consecutive_benched = 3
    r.loot_received = 6
    r.recruited_at_rank = E.ReputationRank.RESPECTED
    r.status = E.RaiderStatus.BENCHED

    var errors := []
    var back = R.from_dict(r.to_dict(), errors)
    assert_eq(errors.size(), 0, str(errors))
    assert_eq(back.display_name, "Greg")
    assert_eq(back.class_id, r.class_id)
    assert_eq(back.rarity, E.Rarity.EPIC)
    assert_eq(back.morale, 73)
    assert_eq(back.status, E.RaiderStatus.BENCHED)
    assert_eq(back.recruited_at_rank, E.ReputationRank.RESPECTED)
    assert_eq(back.runs_attended, 4)
    assert_eq(back.wipes_witnessed, 2)
    # docs/04 §11.3's condition 1 reads the streak across a reload. A counter that reset
    # on save would be a Legendary morale floor that can never be suspended.
    assert_eq(back.consecutive_benched, 3)
    assert_eq(back.loot_received, 6)
    assert_eq(back.backstory.size(), 1)
    assert_eq(back.wishlist, ["ITM_T1_RAID_HEALER_CHEST"])
    assert_eq(back.gear_stats(_db).ac, 5, "equipment survives the round trip")

func test_equipment_serialises_by_slot_key_not_enum_int() -> void:
    var r = _make("warrior")
    _equip_starting(r)
    var d := r.to_dict()
    assert_true(d["equipment"].has("head"), "slots persist as stable string keys")
    assert_false(d["equipment"].has(2), "not raw enum ints")

func test_from_dict_reports_bad_keys_rather_than_guessing() -> void:
    var errors := []
    R.from_dict({"id": "x", "class_id": "paladin", "rarity": "mythic"}, errors)
    assert_true(errors.size() >= 2, str(errors))

func test_legendary_definition_id_is_required_and_exclusive() -> void:
    var errors := []
    R.from_dict({"id": "a", "class_id": "shaman", "rarity": "legendary"}, errors)
    assert_true(errors.size() >= 1, "a legendary with no definition id must complain")
    var errors2 := []
    R.from_dict({"id": "b", "class_id": "shaman", "rarity": "common",
        "legendary_def_id": "legendary_shaman"}, errors2)
    assert_true(errors2.size() >= 1, "a non-legendary must not carry one")

func test_combat_state_is_absent_by_design() -> void:
    # docs/04 §4: combat writes only morale and the four counters, which is what
    # keeps this record serialisable mid-encounter. HP/threat/alive live in the
    # sim's combatant struct, not here.
    var r = _make("warrior")
    var d := r.to_dict()
    for forbidden in ["current_hp", "hp", "threat", "alive", "is_dead", "buffs"]:
        assert_false(d.has(forbidden),
            "the roster record must not carry combat state (%s)" % forbidden)
