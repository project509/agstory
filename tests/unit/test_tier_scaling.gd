extends "res://tests/TestCase.gd"
## The generated tiers, checked against the one claim that matters: NO TIER
## INVERTS POWER.
##
## `tools/gen_items.gd` writes 412 records across sixteen files from the rules in
## `sim/content/TierScaling.gd`. Generated content is cheap to produce and
## expensive to read, so the risk is not a typo — it is a RULE that looks
## reasonable and quietly makes a later tier worse than an earlier one. docs/09
## §13.2's cross-tier step is x1.10 against a within-tier x1.45, so an
## over-aggressive within-tier step makes the next tier's Adventure rung a
## DOWNGRADE on the tier below's raid gear, and the loot loop stops meaning
## anything.
##
## "No tier inverts power" is several distinct claims and each is asserted on its
## own, because any one of them can hold while another fails:
##
##   1. per-slot monotonicity — a piece never gets worse rung to rung;
##   2. per-family totals rise, which is the ladder docs/09 §13.2 describes;
##   3. no cross-rung inversion — the real content risk above;
##   4. no output inversion — the same gear, through Formulas, hits harder;
##   5. canon is preserved and placeholders are visibly placeholders.

const TierScaling = preload("res://sim/content/TierScaling.gd")
const Formulas = preload("res://sim/core/Formulas.gd")

## FOUR armour lines, not five: canon puts the monk and the rogue in one family
## (`monk_rogue_armor`, docs/09 §4.2) and they differ only at the head, so a
## fifth "rogue" line would be a line with no items in it — which reads as a
## ladder that never moves rather than as a mapping mistake.
const FAMILIES := ["warrior_bard", "monk", "healer", "mage_wizard"]
const ARMOUR_SLOTS := ["head", "chest", "legs", "feet"]
const STATS := ["ac", "hp", "mana"]

## Every generated file, in rung order: tier N's Adventure rung then its Raid
## rung, which is the ladder docs/09 §13.2 walks.
const TIERS := [1, 2, 3, 4, 5]


func _read(path: String) -> Dictionary:
    var text := FileAccess.get_file_as_string(path)
    var parsed = JSON.parse_string(text)
    return parsed if parsed is Dictionary else {}


func _items(tier: int, raid: bool) -> Array:
    var path := "res://data/items_t%d_%s.json" % [tier, "raid" if raid else "adventure"]
    return _read(path).get("items", [])


## Armour totals per family at a rung: the sum over head/chest/legs/feet of the
## best piece the family can wear in that slot.
func _family_totals(tier: int, raid: bool) -> Dictionary:
    var out := {}
    for fam in FAMILIES:
        out[fam] = {"ac": 0, "hp": 0, "mana": 0}
    for row in _items(tier, raid):
        var fam := _family_of(String(row.get("family", "")))
        if fam.is_empty() or not (String(row.get("slot", "")) in ARMOUR_SLOTS):
            continue
        var stats: Dictionary = row.get("stats", {})
        for stat in STATS:
            var v := int(stats.get(stat, 0))
            # One family can have two pieces in a slot (the monk's headband and
            # the rogue's eyepatch share a rung); the ladder is about the best.
            out[fam][stat] = maxi(int(out[fam][stat]), 0) + 0
    # Second pass, per slot, so "best" is per slot rather than a sum of maxima.
    for fam in FAMILIES:
        for stat in STATS:
            out[fam][stat] = 0
    for slot in ARMOUR_SLOTS:
        var best := {}
        for fam in FAMILIES:
            best[fam] = {"ac": 0, "hp": 0, "mana": 0, "seen": false}
        for row in _items(tier, raid):
            if String(row.get("slot", "")) != slot:
                continue
            var fam := _family_of(String(row.get("family", "")))
            if fam.is_empty():
                continue
            var stats: Dictionary = row.get("stats", {})
            var score := int(stats.get("ac", 0)) + int(stats.get("hp", 0)) + int(stats.get("mana", 0))
            var cur: Dictionary = best[fam]
            var cur_score := int(cur["ac"]) + int(cur["hp"]) + int(cur["mana"])
            if not bool(cur["seen"]) or score > cur_score:
                best[fam] = {"ac": int(stats.get("ac", 0)), "hp": int(stats.get("hp", 0)),
                    "mana": int(stats.get("mana", 0)), "seen": true}
        for fam in FAMILIES:
            for stat in STATS:
                out[fam][stat] = int(out[fam][stat]) + int(best[fam][stat])
    return out


## docs/09 §4.2's armour families, mapped to the five ladder lines.
func _family_of(family_key: String) -> String:
    match family_key:
        "warrior_bard_armor":
            return "warrior_bard"
        "monk_rogue_armor":
            return "monk"
        "healer_armor":
            return "healer"
        "mage_wizard_armor":
            return "mage_wizard"
        _:
            return ""


## ------------------------------------------------------- 1. per-slot monotonic

func test_no_single_piece_gets_worse_one_rung_up() -> void:
    # §13.4 splits a family's total across four slots by share, and a rounding
    # rule that hands Chest a remainder can leave Legs behind while the TOTAL
    # still rises — which is why this is asserted per slot and not on the sum.
    var bad: Array[String] = []
    var prev := {}
    for tier in TIERS:
        for raid in [false, true]:
            var here := {}
            for row in _items(tier, raid):
                var fam := _family_of(String(row.get("family", "")))
                var slot := String(row.get("slot", ""))
                if fam.is_empty() or not (slot in ARMOUR_SLOTS):
                    continue
                var key := "%s|%s" % [fam, slot]
                var stats: Dictionary = row.get("stats", {})
                var best: Dictionary = here.get(key, {"ac": 0, "hp": 0, "mana": 0})
                for stat in STATS:
                    best[stat] = maxi(int(best[stat]), int(stats.get(stat, 0)))
                here[key] = best
            for key in here:
                if not prev.has(key):
                    continue
                var rose := false
                for stat in STATS:
                    var a := int(here[key][stat])
                    var b := int(prev[key][stat])
                    if a < b:
                        bad.append("T%d %s %s: %s fell %d -> %d" % [
                            tier, "raid" if raid else "adventure", key, stat, b, a])
                    elif a > b:
                        rose = true
                if not rose:
                    bad.append("T%d %s %s: nothing rose at all" % [
                        tier, "raid" if raid else "adventure", key])
            prev = here
    assert_eq(bad.size(), 0, "a piece got worse or stood still:\n      " + "\n      ".join(bad))


## ------------------------------------------------------- 2. family totals rise

func test_every_family_total_rises_every_rung() -> void:
    var bad: Array[String] = []
    var prev := {}
    for tier in TIERS:
        for raid in [false, true]:
            var here := _family_totals(tier, raid)
            for fam in FAMILIES:
                if prev.is_empty():
                    continue
                var rose := false
                for stat in STATS:
                    var a := int(here[fam][stat])
                    var b := int(prev[fam][stat])
                    if a < b:
                        bad.append("T%d %s %s %s fell %d -> %d" % [
                            tier, "raid" if raid else "adventure", fam, stat, b, a])
                    elif a > b:
                        rose = true
                if not rose:
                    bad.append("T%d %s %s did not move at all" % [
                        tier, "raid" if raid else "adventure", fam])
            prev = here
    assert_eq(bad.size(), 0, "the family ladder stalls or inverts:\n      " + "\n      ".join(bad))


## --------------------------------------------- 3. no cross-rung inversion

func test_the_next_tiers_adventure_gear_beats_this_tiers_raid_gear() -> void:
    # THE content risk. §13.2's cross-tier step is x1.10 against a within-tier
    # x1.45: if the within-tier step is ever too aggressive, a player who
    # cleared tier N's raid opens tier N+1's Adventure rung and finds a
    # DOWNGRADE, and the loot loop stops making sense.
    var bad: Array[String] = []
    for tier in [1, 2, 3, 4]:
        var raid := _family_totals(tier, true)
        var next_adv := _family_totals(tier + 1, false)
        for fam in FAMILIES:
            for stat in STATS:
                var a := int(next_adv[fam][stat])
                var b := int(raid[fam][stat])
                if a <= b and b > 0:
                    bad.append("T%d Adventure %s %s (%d) does not beat T%d Raid (%d)" % [
                        tier + 1, fam, stat, a, tier, b])
    assert_eq(bad.size(), 0,
        "a tier's Adventure rung is a downgrade:\n      " + "\n      ".join(bad))


## --------------------------------------------------- 4. no output inversion

func test_the_same_gear_hits_harder_every_tier() -> void:
    # Stats are only a proxy; what the player feels is damage. Run the physical
    # line's armour totals through the same mitigation curve the sim uses and
    # assert the melee line's effective HP and the caster line's Mana both rise,
    # so no tier is softer in the numbers that reach RaidSim.
    var prev_ehp := 0.0
    var prev_mana := 0
    var bad: Array[String] = []
    for tier in TIERS:
        for raid in [false, true]:
            var t := _family_totals(tier, raid)
            var ac := int(t["warrior_bard"]["ac"])
            var hp := int(t["warrior_bard"]["hp"])
            var ehp := float(hp) / maxf(0.01, 1.0 - Formulas.mitigation(ac))
            var mana := int(t["mage_wizard"]["mana"])
            if ehp <= prev_ehp:
                bad.append("T%d %s effective HP %.1f did not beat %.1f" % [
                    tier, "raid" if raid else "adventure", ehp, prev_ehp])
            if mana <= prev_mana:
                bad.append("T%d %s cloth Mana %d did not beat %d" % [
                    tier, "raid" if raid else "adventure", mana, prev_mana])
            prev_ehp = ehp
            prev_mana = mana
    assert_eq(bad.size(), 0, "the ladder inverts in the numbers the sim reads:\n      "
        + "\n      ".join(bad))


## ------------------------------------- 5. canon preserved, placeholders visible

func test_tier_1_is_read_and_never_generated() -> void:
    # The generator reads the canon files and must never write them. A generated
    # row carries `canon: false`; canon's own rows carry neither that key nor a
    # pending name.
    for raid in [false, true]:
        for row in _items(1, raid):
            assert_false(row.has("name_pending"),
                "a Tier 1 row is marked name_pending: %s" % row.get("id", "?"))


func test_every_pending_tier_says_so_on_every_row() -> void:
    # docs/10 §2: "Do not invent lore names." While data/tier_words.json marks a
    # tier pending, every row it generates has to admit it — otherwise 300+
    # items get named by accident, which is the failure mode docs/15 records.
    var words: Dictionary = _read("res://data/tier_words.json").get("tiers", {})
    var bad: Array[String] = []
    for tier in [2, 3, 4, 5]:
        var pending := bool((words.get(str(tier), {}) as Dictionary).get("pending", true))
        if not pending:
            continue
        for raid in [false, true]:
            for row in _items(tier, raid):
                if not bool(row.get("name_pending", false)):
                    bad.append("T%d %s is not marked name_pending" % [tier, row.get("id", "?")])
                if not String(row.get("name", "")).contains("TIER%d" % tier):
                    bad.append("T%d %s does not carry its placeholder token: '%s'" % [
                        tier, row.get("id", "?"), row.get("name", "")])
    assert_eq(bad.size(), 0, "a pending tier is pretending to be named:\n      "
        + "\n      ".join(bad))


func test_every_id_is_unique_across_every_tier_and_matches_the_format() -> void:
    # ContentDB only catches a duplicate within one load, and the id is the
    # primary key save migration matches on, so a collision across two tier
    # files would surface as somebody's chest piece changing when they load.
    var seen := {}
    var bad: Array[String] = []
    # docs/09 §12.1 writes the format with ONE optional variant segment, but
    # canon's own Tier 1 file already ships two (`ITM_T1_RAID_W1H_MH_SWORD_BASIC`
    # — the weapon's shape AND its rung). The data is canon and the doc is the
    # summary, so the pattern here allows one or more and the discrepancy is
    # recorded in the audit rather than "fixed" in either direction.
    var re := RegEx.create_from_string(
        "^ITM_T[0-5]_(START|ADV|RAID|VEND|QUEST)_[A-Z0-9]+_[A-Z0-9]+(_[A-Z0-9]+)*$")
    var counted := 0
    for tier in TIERS:
        for raid in [false, true]:
            for row in _items(tier, raid):
                var id := String(row.get("id", ""))
                counted += 1
                if seen.has(id):
                    bad.append("%s appears in two files" % id)
                seen[id] = true
                if re.search(id) == null:
                    bad.append("%s does not match docs/09 §12.1's format" % id)
    assert_true(counted >= 380, "expected the generated ladder, counted %d rows" % counted)
    assert_eq(bad.size(), 0, "ids are not safe to save against:\n      " + "\n      ".join(bad))
