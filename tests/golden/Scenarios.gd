extends RefCounted
## Fixed scenarios for the golden tests.
##
## Shared by the generator (`tools/write_goldens.gd`) and the comparison test
## (`tests/unit/test_golden.gd`) so a golden file can never be produced by a
## different setup than the one it is checked against. If these two ever built
## their rosters separately, the goldens would drift silently and prove nothing.
##
## Every scenario is a (roster spec, encounter, seed) triple. The rosters are
## deliberately unglamorous: they cover the ends of the range — worst-case
## Commons in starting gear, best-case Legendaries in raid gear — plus the
## benchmark twelve from docs/10 §5.3 in the middle.

const Enums = preload("res://sim/model/Enums.gd")
const Raider = preload("res://sim/model/Raider.gd")

## docs/10 §5.3's benchmark composition: two tanks, all three healing shapes,
## and a Bard so the Bard is never accidentally balanced out of the game.
const BENCHMARK := ["warrior", "warrior", "cleric", "druid", "shaman", "rogue",
                    "rogue", "monk", "mage", "wizard", "wizard", "bard"]

## Canon's own roster names where it gave them, plus fillers in the same register.
const NAMES := ["Bob", "Dave", "Cindy", "Fern", "Natsuna", "Greg",
                "Pip", "Kel", "Steve", "Wanda", "Zed", "Lyra"]

## name -> {encounter, seed, rarity, morale, gear}
const SCENARIOS := {
    "e1_commons_starting": {
        "encounter": "E1", "seed": 20260909,
        "rarity": Enums.Rarity.COMMON, "morale": 45, "gear": "starting",
        "why": "The opening disaster: a fresh guild of nobodies meets four trash mobs.",
    },
    "e3_commons_adventure": {
        "encounter": "E3", "seed": 31337,
        "rarity": Enums.Rarity.COMMON, "morale": 55, "gear": "adventure",
        "why": "Mid-tier, properly geared, average morale — the ordinary case.",
    },
    "e5_first_clear": {
        "encounter": "E5", "seed": 5150,
        "rarity": Enums.Rarity.RARE, "morale": 55, "gear": "raid_entry",
        "why": "The fight that actually happens: Boss 5 in Boss 1-4 gear, which "
             + "docs/08 §9.2 sizes for 22 rounds. The tier's real difficulty check.",
    },
    "e5_legendaries_raid": {
        "encounter": "E5", "seed": 777,
        "rarity": Enums.Rarity.LEGENDARY, "morale": 95, "gear": "raid",
        "why": "Best case, in FARM gear — Boss 5 capstones included, which a raid "
             + "only owns after it has already killed Boss 5. A ceiling, not a fight.",
    },
    "e5_miserable_commons": {
        "encounter": "E5", "seed": 4242,
        "rarity": Enums.Rarity.COMMON, "morale": 5, "gear": "starting",
        "why": "Worst case. Exercises soft wipe, cascades and the Critical cap.",
    },
}


static func names() -> Array:
    var keys := SCENARIOS.keys()
    keys.sort()          # deterministic file order
    return keys


## Build the exact roster a scenario describes. Deterministic: no RNG here.
static func build_roster(spec: Dictionary, db) -> Array:
    var out := []
    for i in BENCHMARK.size():
        var class_key: String = BENCHMARK[i]
        var r = Raider.new()
        r.id = "g%02d" % i
        r.display_name = NAMES[i]
        r.class_id = Enums.class_from_key(class_key)
        r.rarity = int(spec["rarity"])
        r.morale = int(spec["morale"])
        _equip(r, class_key, String(spec["gear"]), db)
        _equip_trinket(r, class_key, String(spec["gear"]), db)
        out.append(r)
    return out


static func _equip(r, class_key: String, gear: String, db) -> void:
    match gear:
        "starting":
            for it in db.starting_set(class_key):
                r.equip(db, it)
        "after_a1":
            # docs/08 §9.1a's middle stage, its contents quoted: starting armour
            # "+ Adventure `feet` + first weapon". Measured there at 54.9 party
            # output against stage 0's 16.5 — the 3.3x jump §9.1a calls "the
            # largest single upgrade in the game", from one item per raider.
            _equip(r, class_key, "starting", db)
            _equip_adventure(r, class_key, db, [Enums.Slot.FEET, Enums.Slot.MAIN_HAND])
        "after_a2":
            # "+ Adventure `legs`", and nothing else: §9.1a lists each stage's
            # contents exactly and the increment is one armour piece, which is
            # why 54.9 only moves to 58.2 here.
            _equip(r, class_key, "after_a1", db)
            _equip_adventure(r, class_key, db, [Enums.Slot.LEGS])
        "adventure":
            var cd = db.class_by_key(class_key)
            for slot in [Enums.Slot.HEAD, Enums.Slot.CHEST, Enums.Slot.LEGS,
                         Enums.Slot.FEET, Enums.Slot.MAIN_HAND]:
                var fam: int = cd.family_for_slot(slot)
                if fam < 0:
                    continue
                for candidate in db.items_for(fam, slot):
                    if candidate.source == "adventure":
                        r.equip(db, candidate)
                        break
        "raid_entry":
            # The honest first-clear loadout: Boss 1-4 drops only. You cannot be
            # wearing the Boss 5 capstone while fighting Boss 5, so measuring E5
            # against full-clear gear measures a fight nobody ever has.
            for boss in range(1, 5):
                for it in db.raid_drops(class_key, boss):
                    r.equip(db, it)
        "raid":
            # Full clear, capstones included. This is the FARM state — what a
            # roster looks like re-running the tier, not entering it.
            for boss in range(1, 6):
                for it in db.raid_drops(class_key, boss):
                    r.equip(db, it)


## The Adventure-source item for each of `slots`, equipped. Shared by the two
## intermediate stages, which differ from each other by exactly one slot.
static func _equip_adventure(r, class_key: String, db, slots: Array) -> void:
    var cd = db.class_by_key(class_key)
    if cd == null:
        return
    for slot in slots:
        var fam: int = cd.family_for_slot(slot)
        if fam < 0:
            continue
        for candidate in db.items_for(fam, slot):
            if candidate.source == "adventure":
                r.equip(db, candidate)
                break


## docs/08 §9.1's benchmark raid explicitly wears a charm — its 175/round figure
## includes one. Leaving the trinket slot empty makes every measured roster
## weaker than the one the damage budget was derived against.
static func _equip_trinket(r, class_key: String, gear: String, db) -> void:
    if gear == "starting":
        return      # canon: a Common recruit arrives with armour and nothing else
    if gear in ["after_a1", "after_a2"]:
        # No charm at the intermediate stages. docs/08 §9.1a lists each one's
        # contents item by item — feet, first weapon, then legs — and a trinket
        # is not among them. Adding one would make the swept party stronger than
        # the party the 54.9 and 58.2 figures were measured on, which is the same
        # category of error as sweeping Boss 5 in its own capstones.
        return
    var melee := class_key in ["warrior", "monk", "rogue", "bard"]
    var want := "ITM_T1_ADV_UNIV_TRINKET_POWER" if melee else "ITM_T1_ADV_UNIV_TRINKET_MANA"
    if gear == "raid":
        want = "ITM_T1_RAID_UNIV_TRINKET_POWER" if melee else "ITM_T1_RAID_UNIV_TRINKET_MANA"
    # raid_entry keeps the Adventure charm: the Raid Trinket is a Boss 5 drop.
    var it = db.item(want)
    if it != null:
        r.equip(db, it)


static func golden_path(name: String) -> String:
    return "res://tests/golden/%s.json" % name
