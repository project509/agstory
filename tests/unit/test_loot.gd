extends "res://tests/TestCase.gd"
## Loot: the drop table, the payouts, and who the game suggests should get it.

const Loot = preload("res://sim/core/Loot.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Rng = preload("res://sim/core/Rng.gd")
const StartingRoster = preload("res://game/core/StartingRoster.gd")
const GameStateScript = preload("res://game/core/GameState.gd")

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

func _enc(slot: String):
    return _db.encounter_at_slot(slot)

func _slots_of(items: Array) -> Dictionary:
    var out := {}
    for it in items:
        out[it.slot] = true
    return out

# ---------------------------------------------------- the canon drop table

func test_the_raid_drop_table_matches_canon_slot_for_slot() -> void:
    # ✅ CANON, raw notes *Raid Layout and loot drops*, cross-checked cell by cell
    # against the nine per-class ideaboard tables in docs/10 §4.1:
    #   E1 feet + basic weapons · E2 legs + healer off-hand · E3 head
    #   E4 chest + strong weapons · E5 class-specific + trinkets
    var expected := {
        "E1": [Enums.Slot.FEET, Enums.Slot.MAIN_HAND],
        "E2": [Enums.Slot.LEGS, Enums.Slot.OFF_HAND],
        "E3": [Enums.Slot.HEAD],
        "E4": [Enums.Slot.CHEST, Enums.Slot.MAIN_HAND],
    }
    for slot in expected:
        var got := _slots_of(Loot.drop_pool(_enc(slot), _db))
        for wanted in expected[slot]:
            assert_true(got.has(wanted),
                "%s must drop %s" % [slot, Enums.slot_name_of(wanted)])

func test_boss_three_drops_head_only() -> void:
    # docs/10 §4.1 ❓: the raw notes say "Head + stronger shared gear", but no
    # per-class table shows a second E3 drop. Until that is resolved E3 is head
    # only, and the drop-count budget in §7 assumes it.
    var got := _slots_of(Loot.drop_pool(_enc("E3"), _db))
    assert_eq(got.size(), 1, "E3 should drop exactly one slot")
    assert_true(got.has(Enums.Slot.HEAD))

func test_every_raid_rung_can_actually_drop_something() -> void:
    # A rung with an empty pool would silently pay nothing and read as a bug.
    for slot in ["E1", "E2", "E3", "E4", "E5"]:
        assert_true(Loot.drop_pool(_enc(slot), _db).size() > 0,
            "%s has an empty drop pool" % slot)

func test_the_adventure_tier_hands_out_adventure_gear() -> void:
    # docs/10 §3: Adventure gear is the Adventure's payout AND the prerequisite
    # for the Raid of the same tier.
    for slot in ["A1", "A2", "A3"]:
        var pool := Loot.drop_pool(_enc(slot), _db)
        assert_true(pool.size() > 0, "%s has an empty drop pool" % slot)
        for it in pool:
            assert_eq(it.source, "adventure",
                "%s dropped a non-Adventure item: %s" % [slot, it.id])

func test_the_first_adventure_drops_the_weapon_that_unblocks_the_tier() -> void:
    # This is the single most important drop in the game: the whole Adventure
    # ladder is sized on the assumption that A1 hands out a main hand, and
    # docs/08 §9.1a measured that first weapon tripling party output.
    var got := _slots_of(Loot.drop_pool(_enc("A1"), _db))
    assert_true(got.has(Enums.Slot.MAIN_HAND), "A1 must drop a weapon")
    assert_true(got.has(Enums.Slot.FEET), "A1 must drop feet")

func test_adventures_never_drop_raid_gear() -> void:
    for slot in ["A1", "A2", "A3"]:
        for it in Loot.drop_pool(_enc(slot), _db):
            assert_ne(it.source, "raid",
                "%s leaked raid gear: %s" % [slot, it.id])

# ---------------------------------------------------------------- roll counts

func test_roll_counts_match_the_documented_table() -> void:
    # docs/10 §4.2: E1:2 E2:2 E3:2 E4:3 E5:3.
    var expected := {"E1": 2, "E2": 2, "E3": 2, "E4": 3, "E5": 3}
    for slot in expected:
        assert_eq(Loot.rolls_for(_enc(slot)), int(expected[slot]),
            "%s rolls" % slot)

func test_adventures_roll_one_per_declared_slot() -> void:
    assert_eq(Loot.rolls_for(_enc("A1")), 2, "feet + weapon")
    assert_eq(Loot.rolls_for(_enc("A2")), 1, "legs")
    assert_eq(Loot.rolls_for(_enc("A3")), 2, "head + chest")

func test_the_tier_boss_guarantees_its_trinket() -> void:
    # docs/10 §4.2: E5 is "3 + 1" — the trinket is guaranteed, not rolled,
    # because canon lists trinkets as a Boss 5 drop.
    var roster := StartingRoster.build(_db, 5)
    var drops := Loot.roll_drops(_enc("E5"), _db, roster, Rng.new(99))
    assert_eq(drops.size(), 4, "three rolls plus the guaranteed trinket")
    var trinkets := 0
    for it in drops:
        if it.slot == Enums.Slot.TRINKET:
            trinkets += 1
    assert_true(trinkets >= 1, "the Raid Trinket must be guaranteed")

# ---------------------------------------------------------------- rolling

func test_rolling_is_deterministic() -> void:
    var roster := StartingRoster.build(_db, 3)
    var a := Loot.roll_drops(_enc("A1"), _db, roster, Rng.new(4242))
    var b := Loot.roll_drops(_enc("A1"), _db, roster, Rng.new(4242))
    assert_eq(a.size(), b.size())
    for i in a.size():
        assert_eq(a[i].id, b[i].id, "same seed must give the same drops")

func test_a_clear_always_drops_something() -> void:
    # docs/10 §11 wants duplicate protection, but a pull that yields NO item
    # reads as a bug rather than as bad luck (docs/15 BL-31). The bias must never
    # become a ban.
    var roster := StartingRoster.build(_db, 8)
    for seed_value in [1, 2, 3, 77, 1234]:
        var drops := Loot.roll_drops(_enc("A1"), _db, roster, Rng.new(seed_value))
        assert_true(drops.size() > 0, "seed %d dropped nothing" % seed_value)

func test_drops_are_biased_toward_what_the_roster_can_use() -> void:
    # The fifth pair of boots must not arrive while three raiders are barefoot.
    var roster := StartingRoster.build(_db, 11)
    var useful := 0
    var total := 0
    for seed_value in range(1, 25):
        for it in Loot.roll_drops(_enc("A1"), _db, roster, Rng.new(seed_value)):
            total += 1
            if Loot.is_upgrade_for_anyone(it, _db, roster):
                useful += 1
    assert_true(total > 0)
    assert_eq(useful, total,
        "every drop should be an upgrade for somebody while the roster is bare")

func test_an_empty_roster_still_gets_drops() -> void:
    # Nothing upgrades anybody, so the bias must fall back to the whole pool.
    var drops := Loot.roll_drops(_enc("A1"), _db, [], Rng.new(7))
    assert_true(drops.size() > 0, "the fallback pool must still produce drops")

# ---------------------------------------------------------------- assignment

func test_eligibility_follows_canons_family_sharing() -> void:
    # Canon's itemization is a sharing matrix, so a drop usually has several
    # claimants — that contention is what makes loot a decision (docs/09 §107).
    var roster := StartingRoster.build(_db, 2)
    var pool := Loot.drop_pool(_enc("A1"), _db)
    var contested := 0
    for it in pool:
        if Loot.eligible(it, _db, roster).size() > 1:
            contested += 1
    assert_true(contested > 0,
        "at least one Adventure drop should have more than one claimant")

func test_nobody_ineligible_is_ever_suggested() -> void:
    var roster := StartingRoster.build(_db, 6)
    for it in Loot.drop_pool(_enc("A1"), _db):
        var target = Loot.suggest(it, _db, roster)
        if target != null:
            assert_true(it.can_be_used_by(target.class_id),
                "%s suggested for a class that cannot wear it" % it.id)

func test_the_suggestion_picks_the_biggest_gain() -> void:
    var roster := StartingRoster.build(_db, 9)
    for it in Loot.drop_pool(_enc("A2"), _db):
        var target = Loot.suggest(it, _db, roster)
        if target == null:
            continue
        var best := Loot.upgrade_delta(it, _db, target)
        for r in Loot.eligible(it, _db, roster):
            assert_true(Loot.upgrade_delta(it, _db, r) <= best,
                "%s: %s would gain more than the suggestion" % [it.id, r.display_name])

func test_an_item_nobody_needs_suggests_nobody() -> void:
    # Rather than forcing a sidegrade onto someone, which the Market should buy.
    var roster := StartingRoster.build(_db, 4)
    var boots = null
    for it in Loot.drop_pool(_enc("A1"), _db):
        if it.slot == Enums.Slot.FEET:
            boots = it
            break
    assert_ne(boots, null)
    # Equip it on everyone who can wear it, then it upgrades nobody.
    for r in Loot.eligible(boots, _db, roster):
        r.equip(_db, boots)
    assert_eq(Loot.suggest(boots, _db, roster), null,
        "an item everyone already wears should suggest nobody")

func test_a_healing_weapon_reads_as_an_upgrade() -> void:
    # A healer weapon carries its power as heal_base rather than as a stat, so
    # comparing Mana alone would rate every healing weapon at exactly zero and
    # the game would never hand one out.
    var roster := StartingRoster.build(_db, 12)
    var cleric = null
    for r in roster:
        if r.class_key() == "cleric":
            cleric = r
            break
    assert_ne(cleric, null)
    var healing_weapon = null
    for it in Loot.drop_pool(_enc("A1"), _db):
        if it.slot == Enums.Slot.MAIN_HAND and it.heal_base > 0 \
                and it.can_be_used_by(cleric.class_id):
            healing_weapon = it
            break
    assert_ne(healing_weapon, null, "A1 should offer the healer a weapon")
    assert_true(Loot.upgrade_delta(healing_weapon, _db, cleric) > 0,
        "a healing weapon must read as an upgrade for a weaponless cleric")

func test_plan_returns_one_row_per_drop() -> void:
    var roster := StartingRoster.build(_db, 1)
    var drops := Loot.roll_drops(_enc("A1"), _db, roster, Rng.new(21))
    var rows := Loot.plan(drops, _db, roster)
    assert_eq(rows.size(), drops.size())
    for row in rows:
        assert_true(row.has("item"))
        assert_true(row.has("eligible"))
        assert_true(row.has("suggested"))

# ---------------------------------------------------------------- gold

func test_raid_payouts_match_the_documented_table() -> void:
    # docs/11 §F1: E1 6 · E2 8 · E3 14 · E4 16 · E5 26 = 70 G per full Raid 1,
    # which is the anchor docs/11 §3.1 prices the whole economy against.
    var expected := {"E1": 6, "E2": 8, "E3": 14, "E4": 16, "E5": 26}
    var total := 0
    for slot in expected:
        var got := Loot.payout(_enc(slot), 0)
        assert_eq(got, int(expected[slot]), "%s first-clear payout" % slot)
        total += got
    assert_eq(total, 70, "a full Raid 1 first clear pays 70 G")

func test_the_adventure_payouts_sum_to_the_documented_twenty() -> void:
    # docs/11 §F2 prices Adventure 1 at 20 G for the whole adventure; docs/15
    # BL-24 makes one rung one encounter, so the 20 splits across the three.
    var total := 0
    for slot in ["A1", "A2", "A3"]:
        total += Loot.payout(_enc(slot), 0)
    assert_eq(total, 20, "Adventure 1 pays 20 G across its three rungs")

func test_the_tutorials_are_priced_and_roll_nothing() -> void:
    # docs/11 §F2, verbatim: "Adventure 0: 4 G · Tutorial Raid: 8 G". Neither
    # slot was in either payout table, and `payout()` answers 0 for a slot it
    # does not know — correct for an unknown rung, silently wrong for these two.
    assert_eq(Loot.payout(_enc("A0"), 0), 4)
    assert_eq(Loot.payout(_enc("TR"), 0), 8)
    assert_true(Loot.payout(_enc("A0"), 0) < Loot.payout(_enc("A1"), 0) + 1,
        "onboarding does not out-earn the first real rung")

    # The reward is a fixed once-only grant made by GameState, never a roll
    # (docs/09 §10.2 G12, docs/15 BL-77). Both tutorials declare one "trinket"
    # loot slot — canon's "1 crap trinket" — so without the guard the non-raid
    # branch would map it to Slot.TRINKET and return the real Adventure charms,
    # the exact items docs/10 §9.2 says the crap pair must be worse than.
    for slot in ["A0", "TR"]:
        var enc = _enc(slot)
        assert_eq(enc.loot_slots.size(), 1, "%s declares its one trinket slot" % slot)
        assert_eq(Loot.rolls_for(enc), 0, "%s rolls nothing" % slot)
        assert_eq(Loot.drop_pool(enc, _db).size(), 0, "%s has an empty pool" % slot)
        assert_eq(Loot.roll_drops(enc, _db, [], Rng.new(1)).size(), 0,
            "%s drops nothing through the rolled path" % slot)

func test_a_tutorial_still_decays_on_a_repeat_clear() -> void:
    # docs/10 §9.3 keeps a resolved tutorial "replayable for gold", so §F5's
    # decay applies to it like any other rung — the TRINKET is what is once-only.
    var first := Loot.payout(_enc("TR"), 0)
    var second := Loot.payout(_enc("TR"), 1)
    assert_eq(first, 8)
    assert_true(second < first)
    assert_true(Loot.payout(_enc("TR"), 9) >= 1)

func test_payout_rises_with_difficulty() -> void:
    assert_true(Loot.payout(_enc("A1"), 0) < Loot.payout(_enc("A3"), 0))
    assert_true(Loot.payout(_enc("E1"), 0) < Loot.payout(_enc("E5"), 0))

func test_repeat_clears_decay_then_floor() -> void:
    # docs/11 §F5: 100% -> 50% -> 25% -> a 10% floor forever, mirroring docs/03's
    # repeat-reputation halving.
    var first := Loot.payout(_enc("E5"), 0)
    var second := Loot.payout(_enc("E5"), 1)
    var third := Loot.payout(_enc("E5"), 2)
    var tenth := Loot.payout(_enc("E5"), 9)
    assert_eq(first, 26)
    assert_true(second < first and second > third)
    assert_true(tenth <= third)
    assert_true(tenth >= 1, "a farmed encounter must never pay literally nothing")

func test_farming_never_pays_zero() -> void:
    # Poverty must cost the player options, never access (docs/11 §12.1).
    for slot in ["A1", "A2", "A3", "E1", "E5"]:
        assert_true(Loot.payout(_enc(slot), 50) >= 1,
            "%s pays nothing when farmed" % slot)

# ---------------------------------------------------------------- game state

func _state_with_content():
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    s.new_game("Loot Test")
    return s

func test_clearing_awards_gold_and_pending_loot() -> void:
    var s = _state_with_content()
    var before: int = s.gold
    var enc = _enc("A1")
    var roster: Array = s.roster.duplicate()
    var winning = null
    for i in 40:
        var res = _run(roster, enc, 1000 + i * 7919)
        if res.cleared():
            winning = res
            break
    assert_ne(winning, null, "A1 must be winnable — see docs/15 BL-27")
    s.record_attempt(enc.id, winning)
    assert_eq(s.gold, before + Loot.payout(enc, 0), "the clear must pay")
    assert_true(s.pending_loot.size() > 0, "the clear must drop something")
    assert_eq(s.clear_count(enc.id), 1)

func _run(roster: Array, enc, seed_value: int):
    var sim = load("res://sim/core/RaidSim.gd")
    return sim.run(roster, enc, _db, seed_value)

func test_a_failed_attempt_awards_nothing() -> void:
    var s = _state_with_content()
    var before: int = s.gold
    var enc = _enc("E5")
    var losing = null
    for i in 10:
        var res = _run(s.roster, enc, 500 + i * 7919)
        if not res.cleared():
            losing = res
            break
    assert_ne(losing, null)
    s.record_attempt(enc.id, losing)
    assert_eq(s.gold, before, "a wipe must not pay")
    assert_eq(s.pending_loot.size(), 0, "a wipe must not drop")

func test_assigning_loot_equips_it_and_clears_the_row() -> void:
    var s = _state_with_content()
    var it = Loot.drop_pool(_enc("A1"), _db)[0]
    s.pending_loot.append(it)
    var target = Loot.suggest(it, _db, s.roster)
    assert_ne(target, null)
    assert_true(s.assign_loot(it.id, target.id))
    assert_eq(s.pending_loot.size(), 0)
    assert_eq(target.equipment.get(it.slot, ""), it.id, "the item must be worn")

func test_assigning_to_someone_who_cannot_use_it_changes_nothing() -> void:
    var s = _state_with_content()
    var it = null
    var wrong = null
    for candidate in Loot.drop_pool(_enc("A1"), _db):
        for r in s.roster:
            if not candidate.can_be_used_by(r.class_id):
                it = candidate
                wrong = r
                break
        if it != null:
            break
    assert_ne(it, null, "some Adventure drop must be class-restricted")
    s.pending_loot.append(it)
    assert_false(s.assign_loot(it.id, wrong.id))
    assert_eq(s.pending_loot.size(), 1, "a refused assignment must not consume it")

func test_suggested_assigns_every_row_that_helps_someone() -> void:
    var s = _state_with_content()
    for it in Loot.drop_pool(_enc("A1"), _db):
        s.pending_loot.append(it)
    var before: int = s.pending_loot.size()
    var assigned: int = s.assign_suggested_loot()
    assert_true(assigned > 0, "the suggestion must hand out something")
    assert_eq(s.pending_loot.size(), before - assigned)
    for it in s.pending_loot:
        assert_eq(Loot.suggest(it, _db, s.roster), null,
            "anything left pending should genuinely help nobody")

func test_pending_loot_survives_a_save_round_trip() -> void:
    var s = _state_with_content()
    var it = Loot.drop_pool(_enc("A2"), _db)[0]
    s.pending_loot.append(it)
    var d: Dictionary = s.to_dict()

    var other = GameStateScript.new()
    _made.append(other)
    other.reset()
    other.set_content(_db)
    var problems: Array = other.from_dict(d)
    assert_eq(problems.size(), 0, str(problems))
    assert_eq(other.pending_loot.size(), 1)
    assert_eq(other.pending_loot[0].id, it.id)

func test_a_save_naming_a_deleted_item_reports_it_rather_than_holding_a_ghost() -> void:
    var s = _state_with_content()
    var d: Dictionary = s.to_dict()
    d["pending_loot"] = ["ITM_DOES_NOT_EXIST"]
    var problems: Array = s.from_dict(d)
    assert_eq(problems.size(), 1, "the load must say what it could not restore")
    assert_eq(s.pending_loot.size(), 0)

func test_clear_count_reads_a_v3_save_that_stored_a_bool() -> void:
    # SAVE_VERSION 4 turned `cleared` from a flag into a count; v3 saves stored
    # `true`, and a silent coercion failure would delete a guild's progress.
    var s = _state_with_content()
    var d: Dictionary = s.to_dict()
    d["cleared"] = {"t1_adv_a1": true}
    var problems: Array = s.from_dict(d)
    assert_eq(problems.size(), 0, str(problems))
    assert_true(s.has_cleared("t1_adv_a1"))
    assert_eq(s.clear_count("t1_adv_a1"), 1)

# ---------------------------------------------------- the reachability chain

## The six who actually go on an Adventure: one tank, one healer, four DPS —
## docs/10 §8's own stated assumption, drawn from the live roster so they hold
## whatever loot has been assigned to them.
func _adventure_party(s) -> Array:
    var want := ["warrior", "cleric", "rogue", "rogue", "wizard", "mage"]
    var out: Array = []
    var used := {}
    for key in want:
        for r in s.roster:
            if r.class_key() == key and not used.has(r.id):
                used[r.id] = true
                out.append(r)
                break
    return out


## Clear A1 once and hand out what it drops, through the SHIPPED path.
##
## This used to hand-route every drop to the party because
## `assign_suggested_loot()` was roster-wide (docs/15 BL-32). It is party-first
## now, so the test exercises what the player's one click actually does.
func _farm_a1(s, salt: int) -> bool:
    var a1 = _enc("A1")
    var party := _adventure_party(s)
    for i in 40:
        var res = _run(party, a1, 1000 + salt * 977 + i * 7919)
        if not res.cleared():
            continue
        s.record_attempt(a1.id, res, party)
        s.assign_suggested_loot()
        return true
    return false


func test_farming_a1_arms_the_party_and_opens_a2() -> void:
    # THE WHOLE POINT OF THIS SYSTEM, end to end. Before loot existed a player
    # who cleared A1 received nothing, so A2 was played in the same starting
    # armour A1 was sized for and every rung above it was unreachable in the
    # shipped game — the exact "no unreachable content" violation.
    #
    # NOT after a single clear. A1 rolls two items, and canon makes Adventures
    # "repeatable, freely" (docs/10 §3) precisely so the on-ramp is farmed until
    # the party is equipped. docs/08 §9.1a measured what that buys: nominal party
    # DPS 16.5 -> 54.9 once everyone holds a weapon.
    var s = _state_with_content()
    var a2 = _enc("A2")

    var party := _adventure_party(s)
    assert_eq(party.size(), 6, "the benchmark adventure six must be fieldable")
    assert_eq(_a2_clears(party, a2), 0,
        "A2 must NOT be winnable before A1 has paid out — otherwise this test "
        + "proves nothing about loot")

    var runs := 0
    for attempt in 12:
        if not _farm_a1(s, attempt):
            continue
        runs += 1
        if _a2_clears(party, a2) > 0:
            break

    assert_true(runs > 0, "A1 must be winnable at all — docs/15 BL-27")
    var armed := 0
    for r in party:
        for it in r.equipped_items(_db):
            if it.source == "adventure":
                armed += 1
                break
    assert_true(armed > 0, "farming A1 must arm the party")
    assert_true(_a2_clears(party, a2) > 0,
        "A2 must become reachable after %d A1 clears armed %d of the six"
        % [runs, armed])


func _a2_clears(party: Array, a2) -> int:
    var cleared := 0
    for i in 24:
        if _run(party, a2, 2000 + i * 7919).cleared():
            cleared += 1
    return cleared


func test_farming_never_takes_gear_away() -> void:
    # Canon's Adventures are "repeatable, freely" (docs/10 §3). Each clear should
    # leave the guild at least as equipped as it was.
    var s = _state_with_content()
    var armed_after := []
    for run in 3:
        if not _farm_a1(s, 50 + run):
            continue
        var armed := 0
        for r in s.roster:
            for it in r.equipped_items(_db):
                if it.source == "adventure":
                    armed += 1
                    break
        armed_after.append(armed)

    assert_true(armed_after.size() >= 2, "at least two clears should be possible")
    for i in range(1, armed_after.size()):
        assert_true(armed_after[i] >= armed_after[i - 1],
            "farming must never take gear away — %s" % str(armed_after))


# ------------------------------------------- docs/15 BL-32 and BL-33, resolved

func test_the_shared_melee_weapon_serves_five_claimants() -> void:
    # The measured cause of BL-33, and it is CONTENT, not a bug. Canon's
    # itemization is a family-sharing matrix (docs/09 §107), and at A1 that means
    # one entry in an eleven-item pool is wanted by five raiders while every
    # caster weapon is wanted by one. Uniform rolls therefore supply a melee
    # raider five times more slowly than a caster.
    var roster := StartingRoster.build(_db, 7)
    var claimants := {}
    for it in Loot.drop_pool(_enc("A1"), _db):
        if it.slot != Enums.Slot.MAIN_HAND:
            continue
        var n := 0
        for r in roster:
            if Loot.upgrade_delta(it, _db, r) > 0:
                n += 1
        claimants[it.id] = n
    assert_eq(int(claimants.get("ITM_T1_ADV_W1H_MH", 0)), 5,
        "two Warriors, two Rogues and a Bard all want the one-hander")
    assert_eq(int(claimants.get("ITM_T1_ADV_W2H_MAGE_MH", 0)), 1,
        "while the Mage staff is wanted by exactly one raider")

func test_the_attempt_remembers_who_went() -> void:
    var s = _state_with_content()
    var enc = _enc("A1")
    var party: Array = s.roster.slice(0, enc.party_size)
    s.record_attempt(enc.id, _run(party, enc, 4242), party)
    assert_eq(s.last_party.size(), enc.party_size)

func test_loot_is_rolled_for_the_party_that_went_not_the_bench() -> void:
    # docs/15 BL-33's resolution. The BL-31 bias only concentrates on what is still
    # missing if it is asked about the right people: rolling against all twelve
    # keeps benched raiders' needs in the pool forever, so it never narrows to
    # what the six in the field are short of.
    var s = _state_with_content()
    var enc = _enc("A1")
    var party := _adventure_party(s)
    var winning = null
    for i in 40:
        var res = _run(party, enc, 900 + i * 7919)
        if res.cleared():
            winning = res
            break
    assert_ne(winning, null)
    s.record_attempt(enc.id, winning, party)
    for it in s.pending_loot:
        var wanted_by_party := false
        for r in party:
            if Loot.upgrade_delta(it, _db, r) > 0:
                wanted_by_party = true
        assert_true(wanted_by_party,
            "%s dropped for a party that cannot use it" % it.id)

func test_suggested_offers_the_party_first_then_the_roster() -> void:
    # docs/15 BL-32. Still need-based (docs/09 §14.3 Option B) — it just reads
    # "need" as the need of the raiders in the field.
    var s = _state_with_content()
    var enc = _enc("A1")
    var party := _adventure_party(s)
    s.last_party = party.duplicate()
    for it in Loot.drop_pool(enc, _db):
        s.pending_loot.append(it)
    s.assign_suggested_loot()

    var party_ids := {}
    for r in party:
        party_ids[r.id] = true
    var armed_off_party := 0
    for r in s.roster:
        if party_ids.has(r.id):
            continue
        for it in r.equipped_items(_db):
            if it.source == "adventure":
                armed_off_party += 1
                break
    var armed_in_party := 0
    for r in party:
        for it in r.equipped_items(_db):
            if it.source == "adventure":
                armed_in_party += 1
                break
    assert_true(armed_in_party >= armed_off_party,
        "the six who went should be geared before the bench (%d vs %d)"
        % [armed_in_party, armed_off_party])

func test_farming_arms_every_one_of_the_six_including_both_rogues() -> void:
    # THE BL-33 REGRESSION TEST. Before the party-first change, fifteen clears
    # armed four of the six and stranded twenty items pending, with NEITHER Rogue
    # holding a weapon — they were queued behind two Warriors and a Bard on the
    # single shared one-hander. Measured after: all six armed in eight clears.
    var s = _state_with_content()
    var party := _adventure_party(s)
    var clears := 0
    for lap in 20:
        if not _farm_a1(s, 40 + lap):
            continue
        clears += 1
        var armed := 0
        for r in party:
            if r.item_in(_db, Enums.Slot.MAIN_HAND) != null:
                armed += 1
        if armed == party.size():
            break

    var armed_at_end := 0
    var rogues_armed := 0
    for r in party:
        if r.item_in(_db, Enums.Slot.MAIN_HAND) != null:
            armed_at_end += 1
            if r.class_key() == "rogue":
                rogues_armed += 1
    assert_eq(armed_at_end, party.size(),
        "all six should hold a weapon after %d clears" % clears)
    assert_eq(rogues_armed, 2,
        "both Rogues specifically — they share one pool entry with three others")

func test_every_trinket_in_the_pool_can_actually_drop() -> void:
    # The Boss 5 pool is four items — Health / Armour / Mana / Power — and it was
    # loaded, validated, and then read by nobody: the trinket was picked by
    # scanning items and taking the first of the right tier by sorted id, which
    # is always ARMOR. Three quarters of the pool was content no player could
    # ever see, and every test passed, because "a trinket was granted" was true.
    var roster := StartingRoster.build(_db, 5)
    var seen := {}
    for seed in range(1, 60):
        for it in Loot.roll_drops(_enc("E5"), _db, roster, Rng.new(seed)):
            if it.slot == Enums.Slot.TRINKET:
                seen[it.id] = true
    var pool: Array = _db.trinket_pool_for(1)
    assert_true(pool.size() >= 4, "canon's Boss 5 pool is four trinkets, found %d" % pool.size())
    var missing: Array[String] = []
    for it in pool:
        if not seen.has(it.id):
            missing.append(it.id)
    assert_eq(missing.size(), 0,
        "these trinkets can never drop:\n      " + "\n      ".join(missing))

func test_the_trinket_draw_is_still_seeded() -> void:
    # Drawing must not cost reproducibility: the same seed still owes the same
    # drop, which is what makes a reported loot bug reproducible at all.
    var roster := StartingRoster.build(_db, 5)
    var a := Loot.roll_drops(_enc("E5"), _db, roster, Rng.new(777))
    var b := Loot.roll_drops(_enc("E5"), _db, roster, Rng.new(777))
    var ids_a: Array[String] = []
    var ids_b: Array[String] = []
    for it in a:
        ids_a.append(it.id)
    for it in b:
        ids_b.append(it.id)
    assert_eq(ids_a, ids_b, "the same seed must produce the same drops")
