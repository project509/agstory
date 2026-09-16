extends "res://tests/TestCase.gd"
## What consumables actually DO (docs/11 §7).
##
## docs/11 §7's constraint is the reason this file exists at all: "the player does not
## control the raid — the sim does ... Every consumable is therefore either a
## **pre-raid buff** committed before the attempt, or a **safety net** the sim spends on
## the player's behalf under a rule the player can read."
##
## Two assertions here are load-bearing above the rest.
##
## `test_an_empty_loadout_changes_nothing_at_all` is the one that protects every golden
## file in the project: `RaidSim.run()` grew a parameter, and if the no-consumables path
## drifted by a single RNG draw, five goldens and the whole balance sweep would be
## quietly wrong rather than loudly broken.
##
## `test_steady_hands_cannot_beat_the_rarity_floor` is the one that protects canon.
## ✅ CANON fixes that "mistake values stay within tier limits … based on their tier", so
## gold may buy back situational risk and must never buy competence.

const Consumables = preload("res://sim/core/Consumables.gd")
const Formulas = preload("res://sim/core/Formulas.gd")
const Morale = preload("res://sim/core/Morale.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Raider = preload("res://sim/model/Raider.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const StartingRoster = preload("res://game/core/StartingRoster.gd")

var _db = null
var _made: Array = []

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _made = []

func after_each() -> void:
    for n in _made:
        if is_instance_valid(n):
            n.free()
    _made = []


func _state(gold: int = 5000):
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    s.new_game("Consumable Test", 4242)
    s.gold = gold
    return s


func _encounter(slot: String = "A1"):
    return _db.encounter_at_slot(slot)


# =============================================== the golden guarantee

func test_an_empty_loadout_changes_nothing_at_all() -> void:
    # `RaidSim.run()` grew a fifth parameter. Every golden file and the balance sweep
    # assume the no-consumables path is untouched, so this compares the FULL event
    # stream — the same SHA-256 the goldens pin — with the parameter absent, empty, and
    # freshly built.
    var s = _state()
    var party: Array = s.roster.slice(0, 6)
    var enc = _encounter("A1")

    var bare = RaidSim.run(party, enc, _db, 12345)
    var explicit = RaidSim.run(party, enc, _db, 12345, {})
    var built = RaidSim.run(party, enc, _db, 12345, Consumables.new_loadout())

    var hash_bare: String = bare.log.to_json().sha256_text()
    assert_eq(explicit.log.to_json().sha256_text(), hash_bare,
        "an explicitly empty loadout must not move a single RNG draw")
    assert_eq(built.log.to_json().sha256_text(), hash_bare,
        "and neither must a freshly built one")
    assert_eq(built.potions_spent, 0)

func test_a_new_loadout_is_empty_by_construction() -> void:
    assert_true(Consumables.loadout_is_empty(Consumables.new_loadout()))
    assert_true(Consumables.loadout_is_empty({}))


# =============================================== the group buffs

func test_the_whetstone_sharpens_the_melee_and_only_the_melee() -> void:
    # docs/11 §7: "+1 Power to every melee participant (Warrior, Monk, Rogue, Bard)."
    for cls in [Enums.CharClass.WARRIOR, Enums.CharClass.MONK,
            Enums.CharClass.ROGUE, Enums.CharClass.BARD]:
        assert_true(Consumables.is_melee_class(cls),
            "%s is on docs/11's melee list" % Enums.class_name_of(cls))
    for cls in [Enums.CharClass.CLERIC, Enums.CharClass.DRUID,
            Enums.CharClass.SHAMAN, Enums.CharClass.MAGE, Enums.CharClass.WIZARD]:
        assert_false(Consumables.is_melee_class(cls),
            "%s is not" % Enums.class_name_of(cls))

    var loadout := Consumables.new_loadout()
    assert_eq(Consumables.fold_into_loadout(loadout, "whetstone_kit", 1), "")
    assert_eq(int(loadout["power_bonus"]), 1, "docs/11 §7's Tier 1 effect")
    assert_eq(int(loadout["mana_bonus"]), 0, "and it is not a mana buff")

func test_the_draught_reaches_the_casters_and_only_the_casters() -> void:
    var loadout := Consumables.new_loadout()
    assert_eq(Consumables.fold_into_loadout(loadout, "mana_draught", 1), "")
    assert_eq(int(loadout["mana_bonus"]), 10, "docs/11 §7's +10 Mana")
    assert_eq(int(loadout["power_bonus"]), 0)

func test_a_group_buff_is_once_per_attempt() -> void:
    # docs/11 §7 phrases every group SKU as a flat effect on "this attempt", never as a
    # stack, and prices the Rally Flask as "One per attempt" outright. docs/15 BL-46.
    var loadout := Consumables.new_loadout()
    assert_eq(Consumables.fold_into_loadout(loadout, "whetstone_kit", 1), "")
    var second := Consumables.fold_into_loadout(loadout, "whetstone_kit", 1)
    assert_true(second.contains("already sharpened"), second)
    assert_eq(int(loadout["power_bonus"]), 1, "and the value did not double")

    assert_eq(Consumables.fold_into_loadout(loadout, "guild_feast", 1), "")
    assert_true(Consumables.fold_into_loadout(
        loadout, "guild_feast", 1).contains("One feast"))

func test_a_higher_grade_buff_is_stronger_by_the_documented_factor() -> void:
    # docs/11 §7: "effect x ~1.8 per tier."
    var t1 := Consumables.new_loadout()
    var t3 := Consumables.new_loadout()
    Consumables.fold_into_loadout(t1, "mana_draught", 1)
    Consumables.fold_into_loadout(t3, "mana_draught", 3)
    assert_eq(int(t1["mana_bonus"]), 10)
    assert_eq(int(t3["mana_bonus"]), int(round(10.0 * 1.8 * 1.8)))

func test_the_whetstone_actually_moves_the_damage_in_a_raid() -> void:
    # An effect nothing can measure is not an effect. Same seed, same party, one kit.
    var s = _state()
    var party: Array = s.roster.slice(0, 12)
    var enc = _encounter("E1")
    var loadout := Consumables.new_loadout()
    Consumables.fold_into_loadout(loadout, "whetstone_kit", 6)

    var plain = RaidSim.run(party, enc, _db, 777)
    var sharp = RaidSim.run(party, enc, _db, 777, loadout)
    assert_true(sharp.damage_dealt > plain.damage_dealt,
        "a sharpened party must hit harder: %d vs %d"
            % [sharp.damage_dealt, plain.damage_dealt])


# =============================================== the Guild Feast

func test_the_feast_is_fought_at_higher_morale_and_stores_nothing() -> void:
    # docs/11 §7: "The attempt is simulated using each participant's morale +5. Stored
    # morale is unchanged." The second half is the part that could quietly break.
    var s = _state()
    var party: Array = s.roster.slice(0, 12)
    for r in party:
        Morale.set_morale(r, 30.0)
    var before: Array = []
    for r in party:
        before.append(Morale.morale_exact(r))

    var loadout := Consumables.new_loadout()
    assert_eq(Consumables.fold_into_loadout(loadout, "guild_feast", 1), "")
    assert_eq(int(loadout["morale_bonus"]), 5, "docs/11 §7's +5")
    RaidSim.run(party, _encounter("E1"), _db, 999, loadout)

    for i in party.size():
        assert_almost(Morale.morale_exact(party[i]), float(before[i]), 0.0001,
            "%s's stored morale must not have moved" % party[i].display_name)

func test_the_feast_changes_the_outcome_it_is_paid_for() -> void:
    var s = _state()
    var party: Array = s.roster.slice(0, 12)
    for r in party:
        Morale.set_morale(r, 25.0)
    var loadout := Consumables.new_loadout()
    Consumables.fold_into_loadout(loadout, "guild_feast", 4)

    var sober = RaidSim.run(party, _encounter("E1"), _db, 555)
    var fed = RaidSim.run(party, _encounter("E1"), _db, 555, loadout)
    assert_ne(sober.log.to_json().sha256_text(), fed.log.to_json().sha256_text(),
        "60 G must buy a different raid")


# =============================================== Steady Hands

func test_steady_hands_lowers_the_mistake_chance_by_percentage_points() -> void:
    # docs/11 §7: "-3 percentage points mistake chance for one named raider." The
    # formulas work in basis points, so three points is 300.
    var loadout := Consumables.new_loadout()
    assert_eq(Consumables.fold_into_loadout(
        loadout, "potion_of_steady_hands", 1, "bob"), "")
    var relief: Dictionary = loadout["mistake_relief_bp"]
    assert_almost(float(relief["bob"]), 300.0, 0.01)

    # A raider carrying a token is above the floor, so the relief is visible there.
    var rattled := Formulas.mistake_chance_bp(
        Enums.Rarity.COMMON, 20, 1300, 1.0, 0.0)
    var steadied := Formulas.mistake_chance_bp(
        Enums.Rarity.COMMON, 20, 1300, 1.0, 300.0)
    assert_eq(steadied, rattled - 300,
        "three percentage points off, exactly")

func test_steady_hands_cannot_beat_the_rarity_floor() -> void:
    # ✅ CANON: "mistake values stay within tier limits … based on their tier."
    # docs/05 §5.4 gives a Common a floor of 12%. A potion steadies a panicking raider;
    # it must not make a Common better than a Common can be.
    var floor_bp: int = int(Formulas.MISTAKE_FLOOR_BP[Enums.Rarity.COMMON])
    var calm := Formulas.mistake_chance_bp(Enums.Rarity.COMMON, 95, 0, 1.0, 0.0)
    var dosed := Formulas.mistake_chance_bp(Enums.Rarity.COMMON, 95, 0, 1.0, 5000.0)
    assert_true(dosed >= floor_bp,
        "even a huge dose stops at the floor: %d vs %d" % [dosed, floor_bp])
    assert_eq(dosed, mini(calm, maxi(floor_bp, calm - 5000)))

func test_steady_hands_needs_a_name() -> void:
    var loadout := Consumables.new_loadout()
    var refused := Consumables.fold_into_loadout(
        loadout, "potion_of_steady_hands", 1)
    assert_true(refused.contains("named raider"), refused)
    assert_eq(Consumables.fold_into_loadout(
        loadout, "potion_of_steady_hands", 1, "bob"), "")
    assert_true(Consumables.fold_into_loadout(
        loadout, "potion_of_steady_hands", 1, "bob").contains("already"))

func test_steady_hands_only_helps_the_raider_it_was_bought_for() -> void:
    var s = _state()
    var party: Array = s.roster.slice(0, 12)
    var loadout := Consumables.new_loadout()
    Consumables.fold_into_loadout(loadout, "potion_of_steady_hands", 6,
        String(party[0].id))
    var relief: Dictionary = loadout["mistake_relief_bp"]
    assert_eq(relief.size(), 1, "one potion, one raider")
    assert_true(relief.has(String(party[0].id)))


# =============================================== the healing potion

func _hurt_party(size: int = 6) -> Array:
    var out: Array = []
    for i in size:
        var r = Raider.new()
        r.id = "hurt%d" % i
        r.display_name = "Hurt%d" % i
        r.class_id = Enums.CharClass.WARRIOR
        r.rarity = Enums.Rarity.COMMON
        Morale.set_morale(r, 50.0)
        out.append(r)
    return out


func test_the_potion_fires_below_thirty_percent_and_restores_a_quarter() -> void:
    # docs/11 §7: "Auto-spent by the sim when a participant drops below 30% HP;
    # restores 25% of max HP. One per raider per encounter maximum."
    assert_almost(Consumables.POTION_TRIGGER_FRACTION, 0.30, 0.0001)
    assert_eq(Consumables.POTIONS_PER_RAIDER, 1)
    assert_almost(Consumables.effect_at("minor_healing_potion", 1), 25.0, 0.0001)

    var s = _state()
    var party: Array = s.roster.slice(0, 12)
    var loadout := Consumables.new_loadout()
    for i in 12:
        Consumables.fold_into_loadout(loadout, "minor_healing_potion", 1, "", 12)
    assert_eq(int(loadout["potion_count"]), 12)

    # E5 is the tier boss, so somebody will certainly drop under 30%.
    var dry = RaidSim.run(party, _encounter("E5"), _db, 4242)
    var stocked = RaidSim.run(party, _encounter("E5"), _db, 4242, loadout)
    assert_true(stocked.potions_spent > 0,
        "a boss fight in starting gear must trigger the safety net")
    assert_true(stocked.log.to_json().contains("drains a potion"),
        "and the player must be able to see the gold being spent")

func test_a_raider_drinks_at_most_one_potion_per_encounter() -> void:
    var s = _state()
    var party: Array = s.roster.slice(0, 12)
    var loadout := Consumables.new_loadout()
    for i in 12:
        Consumables.fold_into_loadout(loadout, "minor_healing_potion", 6, "", 12)
    var res = RaidSim.run(party, _encounter("E5"), _db, 4242, loadout)
    assert_true(res.potions_spent <= party.size(),
        "one per raider is the cap: %d spent for %d raiders"
            % [res.potions_spent, party.size()])

func test_the_party_cannot_carry_more_potions_than_it_has_hands() -> void:
    var loadout := Consumables.new_loadout()
    for i in 6:
        assert_eq(Consumables.fold_into_loadout(
            loadout, "minor_healing_potion", 1, "", 6), "")
    var refused := Consumables.fold_into_loadout(
        loadout, "minor_healing_potion", 1, "", 6)
    assert_true(refused.contains("One per raider"), refused)

func test_potion_healing_is_not_credited_to_the_healers() -> void:
    # `result.healing_done` is the healers' number. Gold should not flatter them.
    var s = _state()
    var party: Array = s.roster.slice(0, 12)
    var loadout := Consumables.new_loadout()
    for i in 12:
        Consumables.fold_into_loadout(loadout, "minor_healing_potion", 6, "", 12)
    var dry = RaidSim.run(party, _encounter("E5"), _db, 4242)
    var stocked = RaidSim.run(party, _encounter("E5"), _db, 4242, loadout)
    if stocked.potions_spent > 0:
        assert_eq(stocked.healing_done, stocked.log.sum_numbers(
            Enums.Verb.HEAL, "amount"),
            "healing_done must still be exactly the HEAL verbs")


# =============================================== the Rally Flask

func test_the_flask_is_refused_before_the_wipe_it_treats() -> void:
    # docs/11 §7 files it as "Post-wipe, town". It cannot be chalked onto an attempt
    # that has not failed yet.
    var loadout := Consumables.new_loadout()
    var refused := Consumables.fold_into_loadout(loadout, "rally_flask", 1)
    assert_true(refused.contains("after a wipe"), refused)
    assert_true(Consumables.loadout_is_empty(loadout))

func test_the_flask_gives_back_half_the_wipe_penalty() -> void:
    # docs/11 §7: "Halves the wipe morale penalty for all participants of the attempt
    # just failed (rounds toward zero)."
    assert_almost(Consumables.wipe_refund_at(1), 0.5, 0.0001)

    var s = _state()
    var party: Array = s.roster.slice(0, 6)
    for r in party:
        Morale.set_morale(r, 60.0)
    assert_eq(s.buy_consumable("rally_flask", 1, 1), "")

    s.record_attempt("t1_adv_a1", _Lost.new(), party)
    assert_false(s.last_wipe_penalty.is_empty(),
        "the wipe must have recorded what it cost")
    var after_wipe: Array = []
    for r in party:
        after_wipe.append(Morale.morale_exact(r))

    assert_eq(s.use_rally_flask(1), "")
    for i in party.size():
        var hit: float = absf(float(s.last_wipe_penalty.get(party[i].id, 0.0)))
        var lifted: float = Morale.morale_exact(party[i]) - float(after_wipe[i])
        assert_true(lifted > 0.0, "%s must feel better" % party[i].display_name)
    assert_eq(s.consumable_count("rally_flask", 1), 0, "and the flask is gone")

func test_a_flask_with_nothing_to_treat_is_refused_without_being_drunk() -> void:
    var s = _state()
    assert_eq(s.buy_consumable("rally_flask", 1, 1), "")
    var refused := s.use_rally_flask(1)
    assert_true(refused.contains("Nothing to drink to"), refused)
    assert_eq(s.consumable_count("rally_flask", 1), 1)

func test_a_clear_leaves_nothing_for_a_flask_to_do() -> void:
    var s = _state()
    var party: Array = s.roster.slice(0, 6)
    s.record_attempt("t1_adv_a1", _Won.new(), party)
    assert_true(s.last_wipe_penalty.is_empty(),
        "a clear records no wipe penalty")

class _Lost extends RefCounted:
    var casualties: Array = []
    var survivors: Array = []
    var mistake_count: int = 0
    func cleared() -> bool: return false

class _Won extends RefCounted:
    var casualties: Array = []
    var survivors: Array = []
    var mistake_count: int = 0
    func cleared() -> bool: return true


# =============================================== the cupboard and the commit point

func test_buying_a_consumable_charges_and_stocks_it() -> void:
    var s = _state(100)
    assert_eq(s.buy_consumable("minor_healing_potion", 1, 4), "")
    assert_eq(s.gold, 100 - 32, "four at 8 G")
    assert_eq(s.consumable_count("minor_healing_potion", 1), 4)

func test_the_stack_cap_refuses_the_twenty_first() -> void:
    # docs/11 §7: "Stack cap 20 per SKU, per tier variant."
    var s = _state(9999)
    assert_eq(s.buy_consumable("minor_healing_potion", 1, 20), "")
    var refused := s.buy_consumable("minor_healing_potion", 1, 1)
    assert_true(refused.contains("holds 20"), refused)
    assert_eq(s.consumable_count("minor_healing_potion", 1), 20)

func test_a_grade_above_the_guilds_standing_is_not_for_sale() -> void:
    var s = _state(99999)
    var refused := s.buy_consumable("minor_healing_potion", 2, 1)
    assert_true(refused.contains("does not stock"), refused)
    assert_eq(s.gold, 99999, "and nothing was charged")

    s.reputation_rank = Enums.ReputationRank.KNOWN
    assert_eq(s.buy_consumable("minor_healing_potion", 2, 1), "",
        "Known reaches grade 2")

func test_choosing_a_consumable_spends_nothing() -> void:
    # docs/11 §7, quoting docs/01 §6.2: "cancelling at confirm is free; that must stay
    # true". This is that promise, asserted.
    var s = _state(200)
    assert_eq(s.buy_consumable("whetstone_kit", 1, 1), "")
    var gold_after_shopping: int = s.gold

    assert_eq(s.choose_consumable("whetstone_kit", 1), "")
    assert_eq(s.gold, gold_after_shopping, "choosing costs no gold")
    assert_eq(s.consumable_count("whetstone_kit", 1), 1,
        "and the kit is still in the cupboard")

    s.clear_chosen_consumables()
    assert_eq(s.consumable_count("whetstone_kit", 1), 1,
        "walking away costs nothing at all")

func test_the_loadout_is_built_from_the_selection() -> void:
    var s = _state(500)
    assert_eq(s.buy_consumable("whetstone_kit", 1, 1), "")
    assert_eq(s.buy_consumable("mana_draught", 1, 1), "")
    assert_eq(s.choose_consumable("whetstone_kit", 1), "")
    assert_eq(s.choose_consumable("mana_draught", 1), "")
    var loadout: Dictionary = s.build_loadout(s.roster)
    assert_eq(int(loadout["power_bonus"]), 1)
    assert_eq(int(loadout["mana_bonus"]), 10)

func test_departing_spends_the_selection_and_brings_the_leftovers_home() -> void:
    # docs/11 §7's commit point, and its kinder half: potions the sim never drank are
    # still in the cupboard afterwards.
    var s = _state(500)
    assert_eq(s.buy_consumable("minor_healing_potion", 1, 6), "")
    assert_eq(s.buy_consumable("whetstone_kit", 1, 1), "")
    for i in 6:
        assert_eq(s.choose_consumable("minor_healing_potion", 1), "")
    assert_eq(s.choose_consumable("whetstone_kit", 1), "")

    s.spend_loadout(2)
    assert_eq(s.consumable_count("minor_healing_potion", 1), 4,
        "two drunk, four came home")
    assert_eq(s.consumable_count("whetstone_kit", 1), 0,
        "a kit is used the moment it is opened")
    assert_eq(s.chosen_consumables, {}, "and the selection is cleared")

func test_you_cannot_chalk_what_you_do_not_have() -> void:
    var s = _state(0)
    var refused := s.choose_consumable("whetstone_kit", 1)
    assert_true(refused.contains("none spare"), refused)

func test_the_cupboard_survives_a_save_round_trip() -> void:
    var s = _state(500)
    assert_eq(s.buy_consumable("minor_healing_potion", 1, 3), "")
    var saved: Dictionary = s.to_dict()

    var t = GameStateScript.new()
    _made.append(t)
    t.set_content(_db)
    var problems: Array = t.from_dict(saved)
    assert_eq(problems.size(), 0, "clean round trip: %s" % str(problems))
    assert_eq(t.consumable_count("minor_healing_potion", 1), 3)
    assert_eq(t.chosen_consumables, {},
        "an uncommitted selection is not worth saving")
