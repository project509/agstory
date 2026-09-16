extends SceneTree
## Generate Tiers 2-5: eight item files, four raid encounter files, four
## Adventure encounter files — and the derivation behind docs/08 §9.6.
##
##   godot --headless --path . --script res://tools/gen_items.gd            write everything
##   godot --headless --path . --script res://tools/gen_items.gd -- budget  print §9.6 only
##   godot --headless --path . --script res://tools/gen_items.gd -- check   write nothing, report diffs
##
## `check` IS A GATE STAGE (tools/verify.sh, docs/14 §10.1 pre-export gate 2,
## mapped in docs/15 BL-74). It exits non-zero and names the file when a
## generated corpus and its generator disagree, which happens two ways: a hand
## edit to a generated row, or a rule change in TierScaling that nobody re-ran.
## Both were invisible before it was wired — the mode existed and had no caller.
##
## WHY A GENERATOR. docs/09 §13 sizes Tiers 2-5 at ~360 item records. Hand-typed,
## they drift the first time a multiplier moves; generated, a balance pass is a
## re-run. The rules live in `sim/content/TierScaling.gd` (pure, testable); this
## file is the plumbing that reads canon, applies them, and writes JSON.
##
## WHAT IS CANON AND CANNOT BE TOUCHED. Tier 1 is read, never written. Rungs r1
## and r2 are seeded from `data/items_t1_adventure.json` and
## `data/items_t1_raid.json` cell for cell, which is docs/09 §13.3's "canon
## values are entered as overrides at r1/r2 and win over the formula, always"
## implemented as a read rather than as a transcription — a transcription can be
## typed wrong, a read cannot. This script never opens a Tier 1 file for writing
## and `tests/unit/test_tier_scaling.gd` asserts their bytes are unchanged.
##
## WHAT IS DERIVED AND WHAT IS AUTHORED, in the encounter files. Derived: every
## `hp`, every `raw_swing`, `target_rounds`, `enrage_round`, `loot_slots`, and
## every mechanic MAGNITUDE (M02 off the cloth pool, M03 off the cloth pool, M11
## off the tank channel). Authored, in `MECHANIC_PLAN` and `COMEDY` below:
## WHICH mechanics a fight uses, which failure modes it is built to punish, and
## the comedy line. docs/10 §6 makes `comedy_line` required and says an
## encounter that cannot be given one is a chore and should be cut — a test a
## generator cannot apply, and a joke a generator cannot write.
##
## NAMES ARE PLACEHOLDERS AND MUST STAY THAT WAY. `data/tier_words.json` holds
## one material and one title word per tier, all four tiers pending a designer.
## Every row this script writes carries `name_pending: true` while its tier's
## words are pending, and `tests/unit/test_tier_scaling.gd` fails the suite if a
## tier is marked answered while a placeholder token survives anywhere in it.
## docs/10 §2: "Do not invent lore names, in code, in UI, or in asset filenames."

const TS = preload("res://sim/content/TierScaling.gd")
const Formulas = preload("res://sim/core/Formulas.gd")

const DATA := "res://data/"
const FAMS := ["warrior_bard", "monk", "rogue", "healer", "mage_wizard"]
const SLOTS := ["head", "chest", "legs", "feet"]
const STATS := ["ac", "hp", "mana", "power"]

# ---------------------------------------------------------------- canon seeds

## The canon armour rows that make up each family's r1 and r2 totals. Monk and
## Rogue share `monk_rogue_armor` for chest/legs/feet and differ only at the
## head, which is why both lists name the same three body pieces.
const SEED := {
    "warrior_bard": {
        1: ["ITM_T1_ADV_WARBARD_HEAD", "ITM_T1_ADV_WARBARD_CHEST",
            "ITM_T1_ADV_WARBARD_LEGS", "ITM_T1_ADV_WARBARD_FEET"],
        2: ["ITM_T1_RAID_WARBARD_HEAD", "ITM_T1_RAID_WARBARD_CHEST",
            "ITM_T1_RAID_WARBARD_LEGS", "ITM_T1_RAID_WARBARD_FEET"],
    },
    "monk": {
        1: ["ITM_T1_ADV_MONKHEAD_HEAD", "ITM_T1_ADV_MONKROGUE_CHEST",
            "ITM_T1_ADV_MONKROGUE_LEGS", "ITM_T1_ADV_MONKROGUE_FEET"],
        2: ["ITM_T1_RAID_MONKHEAD_HEAD", "ITM_T1_RAID_MONKROGUE_CHEST_MONK",
            "ITM_T1_RAID_MONKROGUE_LEGS", "ITM_T1_RAID_MONKROGUE_FEET"],
    },
    "rogue": {
        1: ["ITM_T1_ADV_ROGUEHEAD_HEAD", "ITM_T1_ADV_MONKROGUE_CHEST",
            "ITM_T1_ADV_MONKROGUE_LEGS", "ITM_T1_ADV_MONKROGUE_FEET"],
        2: ["ITM_T1_RAID_ROGUEHEAD_HEAD", "ITM_T1_RAID_MONKROGUE_CHEST_ROGUE",
            "ITM_T1_RAID_MONKROGUE_LEGS", "ITM_T1_RAID_MONKROGUE_FEET"],
    },
    "healer": {
        1: ["ITM_T1_ADV_HEALER_HEAD", "ITM_T1_ADV_HEALER_CHEST",
            "ITM_T1_ADV_HEALER_LEGS", "ITM_T1_ADV_HEALER_FEET"],
        2: ["ITM_T1_RAID_HEALER_HEAD", "ITM_T1_RAID_HEALER_CHEST",
            "ITM_T1_RAID_HEALER_LEGS", "ITM_T1_RAID_HEALER_FEET"],
    },
    "mage_wizard": {
        1: ["ITM_T1_ADV_MAGEWIZ_HEAD", "ITM_T1_ADV_MAGEWIZ_CHEST",
            "ITM_T1_ADV_MAGEWIZ_LEGS", "ITM_T1_ADV_MAGEWIZ_FEET"],
        2: ["ITM_T1_RAID_MAGEWIZ_HEAD", "ITM_T1_RAID_MAGEWIZ_CHEST",
            "ITM_T1_RAID_MAGEWIZ_LEGS", "ITM_T1_RAID_MAGEWIZ_FEET"],
    },
}

## Off-hands and capstones have no family total of their own, so each is priced
## as a fixed ratio against the tier's Raid armour total for the family that
## wears it — which is what the audit asked for and what reproduces canon at
## Tier 1 exactly. The reproduced value is in the comment on every line.
const TOME_AC_RATIO := 0.15          # 0.15 x 13 = 1.95 -> 2  (canon Tome 2 AC)
const TOME_MANA_RATIO := 0.185       # 0.185 x 27 = 5.0 -> 5  (canon Tome 5 Mana)
const SHIELD_AC_RATIO := 0.3333      # x 21 = 7.0 -> 7        (canon Shield 7 AC)
const SHIELD_HP_RATIO := 0.3333      # x 24 = 8.0 -> 8        (canon Shield 8 HP)
const SHIELD_POWER_RATIO := 0.25     # x 4  = 1.0 -> 1        (canon Shield 1 Power)
const INSTRUMENT_MANA_RATIO := 0.588 # x 34 = 20.0 -> 20      (canon Instrument 20 Mana)
const MONK_FINAL_AC_RATIO := 0.30    # x 20 = 6.0 -> 6        (canon Final Headband 6 AC)
const MONK_FINAL_HP_RATIO := 0.2727  # x 22 = 6.0 -> 6
const MONK_FINAL_POWER_RATIO := 0.667  # x 3 = 2.0 -> 2
const ROGUE_FINAL_AC_RATIO := 0.2632   # x 19 = 5.0 -> 5      (canon Final Eyepatch 5 AC)
const ROGUE_FINAL_HP_RATIO := 0.2381   # x 21 = 5.0 -> 5
const ROGUE_FINAL_POWER_RATIO := 0.60  # x 5 = 3.0 -> 3

## The healer weapon line. docs/09 §10.2 G4-G11 and docs/08 §8.5 leave canon's
## "Stats TBD" filled in at Tier 1 as Adventure (10 Mana / 14 heal_base), Basic
## (11/16), Strong (15/19), Final (19/22). Those four are one arithmetic shape —
## +1/+2, +5/+5, +9/+8 off the Adventure row — and that shape is what carries
## forward. Reproduces all four Tier 1 rows exactly.
const HEALW_BASIC := [1, 2]
const HEALW_STRONG := [5, 5]
const HEALW_FINAL := [9, 8]
## The Final healer weapons each carry one small extra stat on top of Mana
## (docs/09 §10.2 G6-G8). Ratios against the tier's Raid healer totals.
const CLERIC_FINAL_AC_RATIO := 0.15    # x 13 = 1.95 -> 2   (canon Cleric Weapon 2 AC)
const DRUID_FINAL_HP_RATIO := 0.2105   # x 19 = 4.0 -> 4    (canon Druid Weapon 4 HP)
const SHAMAN_FINAL_AC_RATIO := 0.077   # x 13 = 1.0 -> 1    (canon Shaman Weapon 1 AC)
const SHAMAN_FINAL_HP_RATIO := 0.1053  # x 19 = 2.0 -> 2

# ---------------------------------------------------------------- naming

## docs/09 §11.2's fixed base nouns. "Never varies by tier" is the rule, so
## these are the only nouns any generated tier can use.
const NOUNS := {
    "warrior_bard": {"head": "Helm", "chest": "Cuirass", "legs": "Greaves", "feet": "Boots"},
    "monk": {"head": "Headband", "chest": "Vest", "legs": "Leggings", "feet": "Boots"},
    "rogue": {"head": "Eyepatch", "chest": "Leather Vest", "legs": "Leggings", "feet": "Boots"},
    "healer": {"head": "Circlet", "chest": "Vestments", "legs": "Leggings", "feet": "Shoes"},
    "mage_wizard": {"head": "Cap", "chest": "Robe", "legs": "Leggings", "feet": "Slippers"},
}

## Which word column each family's Adventure name draws from. docs/09 §11.4:
## the metal line, the cloth line and the healer line each need their own word
## per tier (Tier 1: Iron / Spellweave / Blessed).
const WORD_COLUMN := {
    "warrior_bard": "material", "monk": "material", "rogue": "material",
    "healer": "healer", "mage_wizard": "cloth",
}

# ---------------------------------------------------------------- state

var _canon := {}          # item id -> row, from the two Tier 1 files
var _words := {}          # tier -> {material, cloth, healer, raid_title, raid_adj, pending}
var _tot := {}            # "fam|rung" -> {ac,hp,mana,power}
var _piece := {}          # "fam|rung|slot" -> {ac,hp,mana,power}
var _wpn := {}            # "line|rung" -> int
var _healw := {}          # "variant|rung" -> [mana, heal_base]
var _charm := {}          # rung -> {hp,ac,mana,power}
var _written := 0
var _problems: Array[String] = []


func _initialize() -> void:
    var mode := "write"
    for a in OS.get_cmdline_user_args():
        if String(a) in ["budget", "check", "write"]:
            mode = String(a)

    if not _load_canon():
        _finish(1)
        return
    if not _load_words():
        _finish(1)
        return
    _build_ladder()

    if mode == "budget":
        _print_budget_markdown()
        _finish(0)
        return

    for tier in range(2, 6):
        _write_json("%sitems_t%d_adventure.json" % [DATA, tier], _adventure_items_doc(tier), mode)
        _write_json("%sitems_t%d_raid.json" % [DATA, tier], _raid_items_doc(tier), mode)
        _write_json("%sencounters_t%d.json" % [DATA, tier], _raid_encounters_doc(tier), mode)
        _write_json("%sencounters_adventure_t%d.json" % [DATA, tier],
            _adventure_encounters_doc(tier), mode)
    print("%s: %d file(s) %s" % ["gen_items", _written, "changed" if mode == "write" else "differ"])
    _finish(1 if (mode == "check" and _written > 0) else 0)


func _finish(code: int) -> void:
    for p in _problems:
        print("  PROBLEM  " + p)
    quit(code if _problems.is_empty() else 1)


# ================================================================ loading

func _load_canon() -> bool:
    for path in [DATA + "items_t1_adventure.json", DATA + "items_t1_raid.json"]:
        var text := FileAccess.get_file_as_string(path)
        if text.is_empty():
            _problems.append("cannot read %s" % path)
            return false
        var doc = JSON.parse_string(text)
        if doc == null:
            _problems.append("%s is not valid JSON" % path)
            return false
        for row in doc.get("items", []):
            _canon[String(row["id"])] = row
    return true


func _load_words() -> bool:
    var text := FileAccess.get_file_as_string(DATA + "tier_words.json")
    if text.is_empty():
        _problems.append("cannot read data/tier_words.json")
        return false
    var doc = JSON.parse_string(text)
    if doc == null:
        _problems.append("data/tier_words.json is not valid JSON")
        return false
    for key in doc.get("tiers", {}).keys():
        _words[int(key)] = doc["tiers"][key]
    for tier in range(1, 6):
        if not _words.has(tier):
            _problems.append("tier_words.json has no entry for tier %d" % tier)
            return false
    return true


func _stat(id: String, key: String) -> int:
    var row: Dictionary = _canon.get(id, {})
    return int(row.get("stats", {}).get(key, 0))


# ================================================================ the ladder

func _build_ladder() -> void:
    # r1 and r2 come out of the canon files, cell for cell.
    for fam in FAMS:
        for rung in [1, 2]:
            var ids: Array = SEED[fam][rung]
            var t := {}
            for stat in STATS:
                t[stat] = 0
            for i in SLOTS.size():
                var slot: String = SLOTS[i]
                var p := {}
                for stat in STATS:
                    p[stat] = _stat(String(ids[i]), stat)
                    t[stat] = int(t[stat]) + int(p[stat])
                _piece["%s|%d|%s" % [fam, rung, slot]] = p
            _tot["%s|%d" % [fam, rung]] = t

    for rung in range(3, TS.RUNGS + 1):
        for fam in FAMS:
            var prev: Dictionary = _tot["%s|%d" % [fam, rung - 1]]
            _tot["%s|%d" % [fam, rung]] = TS.totals_for(fam, prev, rung)
        for fam in FAMS:
            var t: Dictionary = _tot["%s|%d" % [fam, rung]]
            for slot in SLOTS:
                _piece["%s|%d|%s" % [fam, rung, slot]] = {}
            for stat in STATS:
                var shares: Dictionary = TS.POWER_SHARES if stat == "power" else TS.SHARES[fam]
                var d := TS.split_slots(int(t[stat]), shares)
                for slot in SLOTS:
                    _piece["%s|%d|%s" % [fam, rung, slot]][stat] = int(d[slot])
            # docs/15 BL-70: a rising TOTAL does not stop an individual slot
            # going flat or backwards once §13.4 re-splits it. Floor every slot
            # against the rung below before anything else reads it.
            for slot in SLOTS:
                var key := "%s|%d|%s" % [fam, rung, slot]
                var prev_slot: Dictionary = _piece.get("%s|%d|%s" % [fam, rung - 1, slot], {})
                _piece[key] = TS.floor_against_previous(prev_slot, _piece[key],
                    TS.SHARES[fam], slot)
        _reconcile_monk_rogue(rung)

    _build_weapons()
    _build_charms()


## Monk and Rogue share chest/legs/feet in one canon family and differ only at
## the head, so the two families cannot both own the body. The Monk's split
## drives the shared rows (canon puts the body stats in the Monk column), and
## the Rogue's head is whatever is left of the Rogue's own family total. At
## Tier 1 that reproduces canon exactly: Monk body 10 AC, Rogue total 13, Rogue
## head 3 — which is the canon Reinforced Rogue Eyepatch.
func _reconcile_monk_rogue(rung: int) -> void:
    for stat in STATS:
        var body := 0
        for slot in ["chest", "legs", "feet"]:
            body += int(_piece["monk|%d|%s" % [rung, slot]][stat])
            _piece["rogue|%d|%s" % [rung, slot]][stat] = int(_piece["monk|%d|%s" % [rung, slot]][stat])
        var head: int = maxi(0, int(_tot["rogue|%d" % rung][stat]) - body)
        _piece["rogue|%d|head" % rung][stat] = head
        _tot["rogue|%d" % rung][stat] = body + head


# ---------------------------------------------------------------- weapons

func _build_weapons() -> void:
    _wpn["sword|1"] = _stat("ITM_T1_ADV_W1H_MH", "damage")
    _wpn["monk|1"] = _stat("ITM_T1_ADV_W2H_MONK_MH", "damage")
    _wpn["mage|1"] = _stat("ITM_T1_ADV_W2H_MAGE_MH", "damage")
    _wpn["wizard|1"] = _stat("ITM_T1_ADV_W2H_WIZ_MH", "damage")
    _healw["adv|1"] = [_stat("ITM_T1_ADV_WPN_CLR_MH", "mana"),
        int(_canon["ITM_T1_ADV_WPN_CLR_MH"].get("heal_base", 0))]

    # Tier 1's Raid weapons are canon and are read, not derived — the Rogue's
    # Basic Dagger at +4 against a +5 Adventure sword is exactly the step
    # docs/09 OQ-15 rules must not be silently fixed.
    _wpn["sword_basic|2"] = _stat("ITM_T1_RAID_W1H_MH_SWORD_BASIC", "damage")
    _wpn["sword_strong|2"] = _stat("ITM_T1_RAID_W1H_MH_SWORD_STRONG", "damage")
    _wpn["dagger_basic|2"] = _stat("ITM_T1_RAID_W1H_MH_DAGGER_BASIC", "damage")
    _wpn["dagger_strong|2"] = _stat("ITM_T1_RAID_W1H_MH_DAGGER_STRONG", "damage")
    _wpn["monk_basic|2"] = _stat("ITM_T1_RAID_W2H_MONK_BASIC", "damage")
    _wpn["monk_strong|2"] = _stat("ITM_T1_RAID_W2H_MONK_STRONG", "damage")
    _wpn["mage_basic|2"] = _stat("ITM_T1_RAID_W2H_MAGE_BASIC", "damage")
    _wpn["mage_strong|2"] = _stat("ITM_T1_RAID_W2H_MAGE_STRONG", "damage")
    _wpn["mage_final|2"] = _stat("ITM_T1_RAID_W2H_MAGE_FINAL", "damage")
    _wpn["wizard_basic|2"] = _stat("ITM_T1_RAID_W2H_WIZ_BASIC", "damage")
    _wpn["wizard_strong|2"] = _stat("ITM_T1_RAID_W2H_WIZ_STRONG", "damage")
    _wpn["wizard_final|2"] = _stat("ITM_T1_RAID_W2H_WIZ_FINAL", "damage")
    _healw["basic|2"] = [_stat("ITM_T1_RAID_WPN_CLR_BASIC", "mana"),
        int(_canon["ITM_T1_RAID_WPN_CLR_BASIC"].get("heal_base", 0))]
    _healw["strong|2"] = [_stat("ITM_T1_RAID_WPN_CLR_STRONG", "mana"),
        int(_canon["ITM_T1_RAID_WPN_CLR_STRONG"].get("heal_base", 0))]
    _healw["final|2"] = [_stat("ITM_T1_RAID_WPN_CLR_FINAL", "mana"),
        int(_canon["ITM_T1_RAID_WPN_CLR_FINAL"].get("heal_base", 0))]

    for tier in range(2, 6):
        var a := TS.rung_of(tier, false)
        var b := TS.rung_of(tier, true)
        _wpn["sword|%d" % a] = TS.weapon_next_tier(int(_wpn["sword_strong|%d" % (b - 2)]))
        _wpn["monk|%d" % a] = TS.weapon_next_tier(int(_wpn["monk_strong|%d" % (b - 2)]))
        _wpn["mage|%d" % a] = TS.weapon_next_tier(int(_wpn["mage_strong|%d" % (b - 2)]))
        _wpn["wizard|%d" % a] = TS.weapon_next_tier(int(_wpn["wizard_strong|%d" % (b - 2)]))

        _wpn["sword_basic|%d" % b] = TS.weapon_basic(int(_wpn["sword|%d" % a]))
        _wpn["sword_strong|%d" % b] = TS.weapon_strong(int(_wpn["sword_basic|%d" % b]), false)
        _wpn["dagger_basic|%d" % b] = maxi(1, int(_wpn["sword_basic|%d" % b]) + TS.DAGGER_OFFSET)
        _wpn["dagger_strong|%d" % b] = maxi(1, int(_wpn["sword_strong|%d" % b]) + TS.DAGGER_OFFSET)
        _wpn["monk_basic|%d" % b] = TS.weapon_basic(int(_wpn["monk|%d" % a]))
        _wpn["monk_strong|%d" % b] = TS.weapon_strong(int(_wpn["monk_basic|%d" % b]), true)
        _wpn["mage_basic|%d" % b] = TS.weapon_basic(int(_wpn["mage|%d" % a]))
        _wpn["mage_strong|%d" % b] = TS.weapon_strong(int(_wpn["mage_basic|%d" % b]), true)
        _wpn["mage_final|%d" % b] = TS.weapon_capstone(int(_wpn["mage_strong|%d" % b]))
        _wpn["wizard_basic|%d" % b] = TS.weapon_basic(int(_wpn["wizard|%d" % a]), true)
        _wpn["wizard_strong|%d" % b] = TS.weapon_strong(int(_wpn["wizard_basic|%d" % b]), true)
        _wpn["wizard_final|%d" % b] = TS.weapon_capstone(int(_wpn["wizard_strong|%d" % b]))

        # The healer line steps across the tier boundary on the Mana rule for
        # its Mana and the weapon rule for its heal_base, because heal_base IS
        # the healer's weapon damage (docs/08 §8.5).
        var prev: Array = _healw["strong|%d" % (b - 2)]
        _healw["adv|%d" % a] = [
            TS.round_half_up(float(prev[0]) * float(TS.CROSS["mana"])),
            TS.round_half_up(float(prev[1]) * float(TS.CROSS["weapon"])),
        ]
        var base: Array = _healw["adv|%d" % a]
        _healw["basic|%d" % b] = [base[0] + HEALW_BASIC[0], base[1] + HEALW_BASIC[1]]
        _healw["strong|%d" % b] = [base[0] + HEALW_STRONG[0], base[1] + HEALW_STRONG[1]]
        _healw["final|%d" % b] = [base[0] + HEALW_FINAL[0], base[1] + HEALW_FINAL[1]]


func _build_charms() -> void:
    _charm[1] = {
        "hp": _stat("ITM_T1_ADV_UNIV_TRINKET_HEALTH", "hp"),
        "ac": _stat("ITM_T1_ADV_UNIV_TRINKET_ARMOR", "ac"),
        "mana": _stat("ITM_T1_ADV_UNIV_TRINKET_MANA", "mana"),
        "power": _stat("ITM_T1_ADV_UNIV_TRINKET_POWER", "power"),
    }
    _charm[2] = {
        "hp": _stat("ITM_T1_RAID_UNIV_TRINKET_HEALTH", "hp"),
        "ac": _stat("ITM_T1_RAID_UNIV_TRINKET_ARMOR", "ac"),
        "mana": _stat("ITM_T1_RAID_UNIV_TRINKET_MANA", "mana"),
        "power": _stat("ITM_T1_RAID_UNIV_TRINKET_POWER", "power"),
    }
    for rung in range(3, TS.RUNGS + 1):
        var raid := TS.rung_is_raid(rung)
        var p: Dictionary = _charm[rung - 1]
        # Power has no multiplier of its own in docs/09 §13.2 — it is derived
        # from AC — so the Power charm rides the AC step.
        _charm[rung] = {
            "hp": TS.round_half_up(float(p["hp"]) * TS.step_multiplier("hp", raid, false, rung - 1)),
            "ac": TS.round_half_up(float(p["ac"]) * TS.step_multiplier("ac", raid, false, rung - 1)),
            "mana": TS.round_half_up(float(p["mana"]) * TS.step_multiplier("mana", raid, false, rung - 1)),
            "power": TS.round_half_up(float(p["power"]) * TS.step_multiplier("ac", raid, false, rung - 1)),
        }


# ================================================================ accessors

func piece(fam: String, rung: int, slot: String) -> Dictionary:
    return _piece["%s|%d|%s" % [fam, rung, slot]]

func total(fam: String, rung: int) -> Dictionary:
    return _tot["%s|%d" % [fam, rung]]

func wpn(line: String, rung: int) -> int:
    return int(_wpn["%s|%d" % [line, rung]])

func healw(variant: String, rung: int) -> Array:
    return _healw["%s|%d" % [variant, rung]]

func word(tier: int, column: String) -> String:
    return String(_words[tier].get(column, "TIER%d" % tier))

func pending(tier: int) -> bool:
    return bool(_words[tier].get("pending", true))


# ================================================================ items

func _stats_block(src: Dictionary, keys: Array) -> Dictionary:
    var out := {}
    for k in keys:
        var v := int(src.get(k, 0))
        if v != 0:
            out[k] = v
    return out


func _row(id: String, name: String, slot: String, family: String,
        stats: Dictionary, note: String, tier: int, extra: Dictionary = {}) -> Dictionary:
    var out := {"id": id, "name": name, "slot": slot, "family": family, "stats": stats}
    for k in extra.keys():
        out[k] = extra[k]
    out["canon"] = false
    out["note"] = note
    out["name_pending"] = pending(tier)
    return out


const NOTE_ARMOUR := ("docs/09 §13.2 growth rule + §13.4 slot shares, generated by"
    + " tools/gen_items.gd from the canon Tier 1 totals. Name is a placeholder:"
    + " docs/09 §11.4's tier words are pending a designer.")
const NOTE_WEAPON := ("docs/09 §13.2 weapon rule (Basic = Adventure +1, +2 Wizard;"
    + " Strong = Basic +2 one-hand / +4 two-hand; capstone = Strong +4; x1.25"
    + " across tiers), generated by tools/gen_items.gd. Name is a placeholder.")
const NOTE_TRINKET := ("docs/09 §13.2 growth rule applied to the canon Tier 1 charm"
    + " magnitudes, generated by tools/gen_items.gd. Name is a placeholder.")
const NOTE_CAPSTONE := ("docs/09 §13.5 hand-authored slot, priced at its Tier 1 ratio"
    + " against this tier's Raid armour total. Stats generated; the joke docs/10 §6"
    + " asks for is NOT written and the name is a placeholder.")


func _adventure_items_doc(tier: int) -> Dictionary:
    var a := TS.rung_of(tier, false)
    var mat := word(tier, "material")
    var clo := word(tier, "cloth")
    var hea := word(tier, "healer")
    var items: Array = []

    # 17 armour rows: the same family x slot grid the shipped Tier 1 file has.
    for fam in FAMS:
        for slot in SLOTS:
            if fam == "rogue" and slot != "head":
                continue      # the body is the Monk's row, shared
            var st := _stats_block(piece(fam, a, slot), ["ac", "hp", "mana"])
            items.append(_row(_armour_id(tier, false, fam, slot),
                "%s Adventurer's %s" % [_family_word(tier, fam), NOUNS[fam][slot]],
                slot, _armour_family(fam, slot), st, NOTE_ARMOUR, tier))

    # 7 weapons.
    items.append(_row("ITM_T%d_ADV_W1H_MH" % tier, "%s Adventurer's Sword" % mat,
        "main_hand", "wrb_one_hand", {"damage": wpn("sword", a)}, NOTE_WEAPON, tier))
    items.append(_row("ITM_T%d_ADV_W2H_MONK_MH" % tier, "%s Adventurer's Staff" % mat,
        "main_hand", "monk_two_hand", {"damage": wpn("monk", a)}, NOTE_WEAPON, tier,
        {"two_handed": true}))
    items.append(_row("ITM_T%d_ADV_W2H_MAGE_MH" % tier, "%s Firestaff" % clo,
        "main_hand", "mage_two_hand", {"damage": wpn("mage", a)}, NOTE_WEAPON, tier,
        {"two_handed": true}))
    items.append(_row("ITM_T%d_ADV_W2H_WIZ_MH" % tier, "%s Arcstaff" % clo,
        "main_hand", "wizard_two_hand", {"damage": wpn("wizard", a)}, NOTE_WEAPON, tier,
        {"two_handed": true}))
    var hw: Array = healw("adv", a)
    for pair in [["CLR", "cleric_weapon"], ["DRU", "druid_weapon"], ["SHM", "shaman_weapon"]]:
        items.append(_row("ITM_T%d_ADV_WPN_%s_MH" % [tier, pair[0]],
            "%s Adventurer's Healing Focus" % hea, "main_hand", String(pair[1]),
            {"mana": int(hw[0])}, NOTE_WEAPON, tier, {"heal_base": int(hw[1])}))

    # 4 universal charms.
    items.append_array(_charm_rows(tier, a, false))

    return {
        "schema_version": 1,
        "tier": tier,
        "source": "adventure",
        "_source": {
            "generator": "tools/gen_items.gd (run it; do not hand-edit)",
            "rules": "docs/09 §13.2 growth, §13.4 slot shares and Power, §11 naming",
            "seed": "data/items_t1_adventure.json + data/items_t1_raid.json (CANON, read only)",
            "budget": "docs/08 §9.6",
        },
        "_notes": _generated_notes(tier, 28),
        "items": items,
    }


func _raid_items_doc(tier: int) -> Dictionary:
    var b := TS.rung_of(tier, true)
    var title := word(tier, "raid_title")
    # `raid_adj` is docs/09 §11.3's {RaidTitle-adj}: the TIER word in
    # `Basic {RaidTitle-adj} {WeaponNoun}` / `Strong {RaidTitle-adj} {WeaponNoun}`
    # — "Raid" at Tier 1, so "Basic Raid Sword" — and the prefix of the Boss 5
    # capstones. The quality words Basic / Strong are the rung's and stay literal
    # below. data/tier_words.json's T1 row held "Basic" in this column until
    # 2026-09-15 (it would have rendered "Basic Basic Sword"); the column's
    # meaning is fixed here so the designer fills it as an adjective of the title.
    var adj := word(tier, "raid_adj")
    var hea := word(tier, "healer")
    var items: Array = []

    # Armour, in canon drop order: B1 feet, B2 legs, B3 head, B4 chest.
    var drop_slot := {"feet": 1, "legs": 2, "head": 3, "chest": 4}
    for slot in ["feet", "legs", "head", "chest"]:
        for fam in FAMS:
            if fam == "rogue" and slot != "head":
                continue
            if slot == "chest" and fam == "monk":
                # Canon splits the Boss 4 chest into a Monk row and a Rogue row
                # with identical stats and different names. Kept: the ids are
                # the identity and both class tables point at their own.
                var st_m := _stats_block(piece("monk", b, "chest"), ["ac", "hp", "mana", "power"])
                items.append(_row("ITM_T%d_RAID_MONKROGUE_CHEST_MONK" % tier,
                    "%s's Vest" % title, "chest", "monk_rogue_armor", st_m,
                    NOTE_ARMOUR, tier, {"boss": 4}))
                items.append(_row("ITM_T%d_RAID_MONKROGUE_CHEST_ROGUE" % tier,
                    "%s's Leather Vest" % title, "chest", "monk_rogue_armor",
                    st_m.duplicate(), NOTE_ARMOUR, tier, {"boss": 4}))
                continue
            var st := _stats_block(piece(fam, b, slot), ["ac", "hp", "mana", "power"])
            items.append(_row(_armour_id(tier, true, fam, slot),
                "%s's %s" % [title, NOUNS[fam][slot]], slot, _armour_family(fam, slot),
                st, NOTE_ARMOUR, tier, {"boss": int(drop_slot[slot])}))

    # Boss 1 weapons.
    items.append(_row("ITM_T%d_RAID_W1H_MH_SWORD_BASIC" % tier, "Basic %s Sword" % adj,
        "main_hand", "wrb_one_hand", {"damage": wpn("sword_basic", b)}, NOTE_WEAPON, tier,
        {"boss": 1}))
    items.append(_row("ITM_T%d_RAID_W1H_MH_DAGGER_BASIC" % tier, "Basic %s Dagger" % adj,
        "main_hand", "wrb_one_hand", {"damage": wpn("dagger_basic", b)},
        NOTE_WEAPON + " The Rogue equips two, and the dagger keeps canon's -2"
        + " against the sword at every rung (docs/09 OQ-15: do not silently fix it).",
        tier, {"boss": 1}))
    items.append(_row("ITM_T%d_RAID_W2H_MONK_BASIC" % tier, "Basic %s Staff" % adj,
        "main_hand", "monk_two_hand", {"damage": wpn("monk_basic", b)}, NOTE_WEAPON, tier,
        {"boss": 1, "two_handed": true}))
    items.append(_row("ITM_T%d_RAID_W2H_MAGE_BASIC" % tier, "Basic %s Staff" % adj,
        "main_hand", "mage_two_hand", {"damage": wpn("mage_basic", b)}, NOTE_WEAPON, tier,
        {"boss": 1, "two_handed": true}))
    items.append(_row("ITM_T%d_RAID_W2H_WIZ_BASIC" % tier, "Basic %s Staff" % adj,
        "main_hand", "wizard_two_hand", {"damage": wpn("wizard_basic", b)}, NOTE_WEAPON, tier,
        {"boss": 1, "two_handed": true}))
    var hb: Array = healw("basic", b)
    for pair in [["CLR", "cleric_weapon"], ["DRU", "druid_weapon"], ["SHM", "shaman_weapon"]]:
        items.append(_row("ITM_T%d_RAID_WPN_%s_BASIC" % [tier, pair[0]],
            "Basic %s Healing Weapon" % adj, "main_hand", String(pair[1]),
            {"mana": int(hb[0])}, NOTE_WEAPON, tier, {"boss": 1, "heal_base": int(hb[1])}))

    # Boss 2 off-hand.
    var ht: Dictionary = total("healer", b)
    items.append(_row("ITM_T%d_RAID_HEALOFF_OH" % tier, "%s %s's Tome" % [hea, title],
        "off_hand", "healer_off_hand",
        {"ac": maxi(1, TS.round_half_up(TOME_AC_RATIO * float(ht["ac"]))),
         "mana": maxi(1, TS.round_half_up(TOME_MANA_RATIO * float(ht["mana"])))},
        NOTE_CAPSTONE, tier, {"boss": 2}))

    # Boss 4 weapons.
    items.append(_row("ITM_T%d_RAID_W1H_MH_SWORD_STRONG" % tier, "Strong %s Sword" % adj,
        "main_hand", "wrb_one_hand", {"damage": wpn("sword_strong", b)}, NOTE_WEAPON, tier,
        {"boss": 4}))
    items.append(_row("ITM_T%d_RAID_W1H_MH_DAGGER_STRONG" % tier, "Strong %s Dagger" % adj,
        "main_hand", "wrb_one_hand", {"damage": wpn("dagger_strong", b)},
        NOTE_WEAPON + " The Rogue equips two.", tier, {"boss": 4}))
    items.append(_row("ITM_T%d_RAID_W2H_MONK_STRONG" % tier, "Strong %s Staff" % adj,
        "main_hand", "monk_two_hand", {"damage": wpn("monk_strong", b)}, NOTE_WEAPON, tier,
        {"boss": 4, "two_handed": true}))
    items.append(_row("ITM_T%d_RAID_W2H_MAGE_STRONG" % tier, "Strong %s Staff" % adj,
        "main_hand", "mage_two_hand", {"damage": wpn("mage_strong", b)}, NOTE_WEAPON, tier,
        {"boss": 4, "two_handed": true}))
    items.append(_row("ITM_T%d_RAID_W2H_WIZ_STRONG" % tier, "Strong %s Staff" % adj,
        "main_hand", "wizard_two_hand", {"damage": wpn("wizard_strong", b)}, NOTE_WEAPON, tier,
        {"boss": 4, "two_handed": true}))
    var hs: Array = healw("strong", b)
    for pair in [["CLR", "cleric_weapon"], ["DRU", "druid_weapon"], ["SHM", "shaman_weapon"]]:
        items.append(_row("ITM_T%d_RAID_WPN_%s_STRONG" % [tier, pair[0]],
            "Strong %s Healing Weapon" % adj, "main_hand", String(pair[1]),
            {"mana": int(hs[0])}, NOTE_WEAPON, tier, {"boss": 4, "heal_base": int(hs[1])}))

    # Boss 5 capstones — nine, one per class (docs/09 §13.5).
    var wt: Dictionary = total("warrior_bard", b)
    items.append(_row("ITM_T%d_RAID_SHIELD_OH" % tier, "%s Warrior Shield" % adj,
        "off_hand", "warrior_shield",
        {"ac": TS.round_half_up(SHIELD_AC_RATIO * float(wt["ac"])),
         "hp": TS.round_half_up(SHIELD_HP_RATIO * float(wt["hp"])),
         "power": maxi(1, TS.round_half_up(SHIELD_POWER_RATIO * float(wt["power"])))},
        NOTE_CAPSTONE, tier, {"boss": 5}))
    items.append(_row("ITM_T%d_RAID_INSTR_OH" % tier, "%s Bard Instrument" % adj,
        "off_hand", "instrument",
        {"mana": TS.round_half_up(INSTRUMENT_MANA_RATIO * float(total("mage_wizard", b)["mana"]))},
        NOTE_CAPSTONE, tier, {"boss": 5}))
    var mt: Dictionary = total("monk", b)
    items.append(_row("ITM_T%d_RAID_MONKHEAD_HEAD_FINAL" % tier, "%s Final Headband" % adj,
        "head", "monk_head",
        {"ac": TS.round_half_up(MONK_FINAL_AC_RATIO * float(mt["ac"])),
         "hp": TS.round_half_up(MONK_FINAL_HP_RATIO * float(mt["hp"])),
         "power": maxi(1, TS.round_half_up(MONK_FINAL_POWER_RATIO * float(mt["power"])))},
        NOTE_CAPSTONE, tier, {"boss": 5}))
    var rt: Dictionary = total("rogue", b)
    items.append(_row("ITM_T%d_RAID_ROGUEHEAD_HEAD_FINAL" % tier, "%s Final Eyepatch" % adj,
        "head", "rogue_head",
        {"ac": TS.round_half_up(ROGUE_FINAL_AC_RATIO * float(rt["ac"])),
         "hp": TS.round_half_up(ROGUE_FINAL_HP_RATIO * float(rt["hp"])),
         "power": maxi(1, TS.round_half_up(ROGUE_FINAL_POWER_RATIO * float(rt["power"])))},
        NOTE_CAPSTONE, tier, {"boss": 5}))
    var hf: Array = healw("final", b)
    items.append(_row("ITM_T%d_RAID_WPN_CLR_FINAL" % tier, "%s Cleric Weapon" % adj,
        "main_hand", "cleric_weapon",
        {"mana": int(hf[0]), "ac": maxi(1, TS.round_half_up(CLERIC_FINAL_AC_RATIO * float(ht["ac"])))},
        NOTE_CAPSTONE, tier, {"boss": 5, "heal_base": int(hf[1])}))
    items.append(_row("ITM_T%d_RAID_WPN_DRU_FINAL" % tier, "%s Druid Weapon" % adj,
        "main_hand", "druid_weapon",
        {"mana": int(hf[0]), "hp": maxi(1, TS.round_half_up(DRUID_FINAL_HP_RATIO * float(ht["hp"])))},
        NOTE_CAPSTONE, tier, {"boss": 5, "heal_base": int(hf[1])}))
    items.append(_row("ITM_T%d_RAID_WPN_SHM_FINAL" % tier, "%s Shaman Weapon" % adj,
        "main_hand", "shaman_weapon",
        {"mana": int(hf[0]),
         "ac": maxi(1, TS.round_half_up(SHAMAN_FINAL_AC_RATIO * float(ht["ac"]))),
         "hp": maxi(1, TS.round_half_up(SHAMAN_FINAL_HP_RATIO * float(ht["hp"])))},
        NOTE_CAPSTONE, tier, {"boss": 5, "heal_base": int(hf[1])}))
    items.append(_row("ITM_T%d_RAID_W2H_MAGE_FINAL" % tier, "%s Mage Staff" % adj,
        "main_hand", "mage_two_hand", {"damage": wpn("mage_final", b)}, NOTE_CAPSTONE, tier,
        {"boss": 5, "two_handed": true}))
    items.append(_row("ITM_T%d_RAID_W2H_WIZ_FINAL" % tier, "%s Wizard Staff" % adj,
        "main_hand", "wizard_two_hand", {"damage": wpn("wizard_final", b)}, NOTE_CAPSTONE, tier,
        {"boss": 5, "two_handed": true}))

    items.append_array(_charm_rows(tier, b, true))

    return {
        "schema_version": 1,
        "tier": tier,
        "source": "raid",
        "_source": {
            "generator": "tools/gen_items.gd (run it; do not hand-edit)",
            "rules": "docs/09 §13.2 growth, §13.4 slot shares and Power, §13.5 capstones, §11 naming",
            "seed": "data/items_t1_adventure.json + data/items_t1_raid.json (CANON, read only)",
            "budget": "docs/08 §9.6",
        },
        "_notes": _generated_notes(tier, 48),
        "items": items,
        "class_tables": _class_tables(tier),
        "boss5_trinket_pool": [
            "ITM_T%d_RAID_UNIV_TRINKET_HEALTH" % tier,
            "ITM_T%d_RAID_UNIV_TRINKET_ARMOR" % tier,
            "ITM_T%d_RAID_UNIV_TRINKET_MANA" % tier,
            "ITM_T%d_RAID_UNIV_TRINKET_POWER" % tier,
        ],
    }


func _charm_rows(tier: int, rung: int, raid: bool) -> Array:
    var c: Dictionary = _charm[rung]
    var src := "RAID" if raid else "ADV"
    var fiction := "%s's" % word(tier, "raid_title") if raid else "%s Adventure's" % word(tier, "material")
    var extra := {"boss": 5} if raid else {}
    var out: Array = []
    for spec in [["HEALTH", "Health", "hp"], ["ARMOR", "Armor", "ac"],
            ["MANA", "Mana", "mana"], ["POWER", "Power", "power"]]:
        out.append(_row("ITM_T%d_%s_UNIV_TRINKET_%s" % [tier, src, spec[0]],
            "%s Charm of %s" % [fiction, spec[1]], "trinket", "universal_trinket",
            {String(spec[2]): int(c[spec[2]])}, NOTE_TRINKET, tier, extra))
    return out


func _armour_id(tier: int, raid: bool, fam: String, slot: String) -> String:
    var src := "RAID" if raid else "ADV"
    match fam:
        "warrior_bard":
            return "ITM_T%d_%s_WARBARD_%s" % [tier, src, slot.to_upper()]
        "monk":
            if slot == "head":
                return "ITM_T%d_%s_MONKHEAD_HEAD" % [tier, src]
            return "ITM_T%d_%s_MONKROGUE_%s" % [tier, src, slot.to_upper()]
        "rogue":
            return "ITM_T%d_%s_ROGUEHEAD_HEAD" % [tier, src]
        "healer":
            return "ITM_T%d_%s_HEALER_%s" % [tier, src, slot.to_upper()]
    return "ITM_T%d_%s_MAGEWIZ_%s" % [tier, src, slot.to_upper()]


func _armour_family(fam: String, slot: String) -> String:
    match fam:
        "warrior_bard":
            return "warrior_bard_head" if slot == "head" else "warrior_bard_armor"
        "monk":
            return "monk_head" if slot == "head" else "monk_rogue_armor"
        "rogue":
            return "rogue_head"
        "healer":
            return "healer_armor"
    return "mage_wizard_armor"


func _family_word(tier: int, fam: String) -> String:
    return word(tier, String(WORD_COLUMN[fam]))


func _class_tables(tier: int) -> Dictionary:
    var t := tier
    return {
        "warrior": {"1": ["ITM_T%d_RAID_WARBARD_FEET" % t, "ITM_T%d_RAID_W1H_MH_SWORD_BASIC" % t],
            "2": ["ITM_T%d_RAID_WARBARD_LEGS" % t], "3": ["ITM_T%d_RAID_WARBARD_HEAD" % t],
            "4": ["ITM_T%d_RAID_WARBARD_CHEST" % t, "ITM_T%d_RAID_W1H_MH_SWORD_STRONG" % t],
            "5": ["ITM_T%d_RAID_SHIELD_OH" % t]},
        "bard": {"1": ["ITM_T%d_RAID_WARBARD_FEET" % t, "ITM_T%d_RAID_W1H_MH_SWORD_BASIC" % t],
            "2": ["ITM_T%d_RAID_WARBARD_LEGS" % t], "3": ["ITM_T%d_RAID_WARBARD_HEAD" % t],
            "4": ["ITM_T%d_RAID_WARBARD_CHEST" % t, "ITM_T%d_RAID_W1H_MH_SWORD_STRONG" % t],
            "5": ["ITM_T%d_RAID_INSTR_OH" % t]},
        "monk": {"1": ["ITM_T%d_RAID_MONKROGUE_FEET" % t, "ITM_T%d_RAID_W2H_MONK_BASIC" % t],
            "2": ["ITM_T%d_RAID_MONKROGUE_LEGS" % t], "3": ["ITM_T%d_RAID_MONKHEAD_HEAD" % t],
            "4": ["ITM_T%d_RAID_MONKROGUE_CHEST_MONK" % t, "ITM_T%d_RAID_W2H_MONK_STRONG" % t],
            "5": ["ITM_T%d_RAID_MONKHEAD_HEAD_FINAL" % t]},
        "rogue": {"1": ["ITM_T%d_RAID_MONKROGUE_FEET" % t, "ITM_T%d_RAID_W1H_MH_DAGGER_BASIC" % t],
            "2": ["ITM_T%d_RAID_MONKROGUE_LEGS" % t], "3": ["ITM_T%d_RAID_ROGUEHEAD_HEAD" % t],
            "4": ["ITM_T%d_RAID_MONKROGUE_CHEST_ROGUE" % t, "ITM_T%d_RAID_W1H_MH_DAGGER_STRONG" % t],
            "5": ["ITM_T%d_RAID_ROGUEHEAD_HEAD_FINAL" % t]},
        "cleric": {"1": ["ITM_T%d_RAID_HEALER_FEET" % t, "ITM_T%d_RAID_WPN_CLR_BASIC" % t],
            "2": ["ITM_T%d_RAID_HEALER_LEGS" % t, "ITM_T%d_RAID_HEALOFF_OH" % t],
            "3": ["ITM_T%d_RAID_HEALER_HEAD" % t],
            "4": ["ITM_T%d_RAID_HEALER_CHEST" % t, "ITM_T%d_RAID_WPN_CLR_STRONG" % t],
            "5": ["ITM_T%d_RAID_WPN_CLR_FINAL" % t]},
        "druid": {"1": ["ITM_T%d_RAID_HEALER_FEET" % t, "ITM_T%d_RAID_WPN_DRU_BASIC" % t],
            "2": ["ITM_T%d_RAID_HEALER_LEGS" % t, "ITM_T%d_RAID_HEALOFF_OH" % t],
            "3": ["ITM_T%d_RAID_HEALER_HEAD" % t],
            "4": ["ITM_T%d_RAID_HEALER_CHEST" % t, "ITM_T%d_RAID_WPN_DRU_STRONG" % t],
            "5": ["ITM_T%d_RAID_WPN_DRU_FINAL" % t]},
        "shaman": {"1": ["ITM_T%d_RAID_HEALER_FEET" % t, "ITM_T%d_RAID_WPN_SHM_BASIC" % t],
            "2": ["ITM_T%d_RAID_HEALER_LEGS" % t, "ITM_T%d_RAID_HEALOFF_OH" % t],
            "3": ["ITM_T%d_RAID_HEALER_HEAD" % t],
            "4": ["ITM_T%d_RAID_HEALER_CHEST" % t, "ITM_T%d_RAID_WPN_SHM_STRONG" % t],
            "5": ["ITM_T%d_RAID_WPN_SHM_FINAL" % t]},
        "mage": {"1": ["ITM_T%d_RAID_MAGEWIZ_FEET" % t, "ITM_T%d_RAID_W2H_MAGE_BASIC" % t],
            "2": ["ITM_T%d_RAID_MAGEWIZ_LEGS" % t], "3": ["ITM_T%d_RAID_MAGEWIZ_HEAD" % t],
            "4": ["ITM_T%d_RAID_MAGEWIZ_CHEST" % t, "ITM_T%d_RAID_W2H_MAGE_STRONG" % t],
            "5": ["ITM_T%d_RAID_W2H_MAGE_FINAL" % t]},
        "wizard": {"1": ["ITM_T%d_RAID_MAGEWIZ_FEET" % t, "ITM_T%d_RAID_W2H_WIZ_BASIC" % t],
            "2": ["ITM_T%d_RAID_MAGEWIZ_LEGS" % t], "3": ["ITM_T%d_RAID_MAGEWIZ_HEAD" % t],
            "4": ["ITM_T%d_RAID_MAGEWIZ_CHEST" % t, "ITM_T%d_RAID_W2H_WIZ_STRONG" % t],
            "5": ["ITM_T%d_RAID_W2H_WIZ_FINAL" % t]},
    }


func _generated_notes(tier: int, count: int) -> Array:
    return [
        "GENERATED FILE. Edit tools/gen_items.gd or sim/content/TierScaling.gd and re-run;",
        "a hand edit here is lost on the next regeneration. `tools/verify.sh` runs",
        "`gen_items.gd -- check` as a gate stage, so an edit here fails the build",
        "and names this file. Mark a row hand_authored: true to keep it (BL-69).",
        "Row count is held at Tier 1's shape (%d): the shipped canon rung is the" % count,
        "template, which also answers docs/09 §13.1's 27-vs-28 Adventure discrepancy",
        "in favour of the data (28 = 17 armour + 7 weapons + 4 charms, no off-hands).",
        "NAMES ARE PLACEHOLDERS. Every row carries name_pending while",
        "data/tier_words.json marks tier %d pending. docs/09 §11.4's material and" % tier,
        "title words are a designer decision and nothing here may invent them.",
        "Stats are docs/09 §13.2's growth rule applied to the CANON Tier 1 totals,",
        "split by §13.4's shares with the remainder to Chest. docs/08 §9.6 is the",
        "boss budget these numbers feed, and it is derived from the same ladder.",
    ]


# ================================================================ the budget

## docs/08 §9.1's benchmark comp, as counts: 2 Warrior, 1 Monk, 2 Rogue, 1 Bard,
## 1 Mage, 2 Wizard, and three healers who contribute no damage.
const COMP := {"warrior": 2, "monk": 1, "rogue": 2, "bard": 1, "mage": 1, "wizard": 2}
const CLASS_MELEE_COEF := {"warrior": 1.00, "monk": 1.10, "rogue": 0.95, "bard": 0.55}
const MELEE_SWINGS := 2
const OFFHAND_COEF := 0.75
const MANA_TO_SPELL := 0.35
const WIZARD_SPELL_COEF := 1.60
const MAGE_SPELL_COEF := 0.60
const BASE_HP := {"warrior": 120, "mage": 65}

## The gear one family is wearing at one stage of one tier's raid. Stage 0 is
## full tier-N Adventure; stage n is after Boss n, with canon's one-slot-per-boss
## drop order (B1 feet, B2 legs, B3 head, B4 chest).
const STAGE_SLOT := {1: "feet", 2: "legs", 3: "head", 4: "chest"}

func _gear(fam: String, tier: int, stage: int) -> Dictionary:
    var a := TS.rung_of(tier, false)
    var b := TS.rung_of(tier, true)
    var out := {"ac": 0, "hp": 0, "mana": 0, "power": 0}
    for slot in SLOTS:
        var rung := a
        for n in range(1, mini(stage, 4) + 1):
            if String(STAGE_SLOT[n]) == slot:
                rung = b
        var p := piece(fam, rung, slot)
        for k in out.keys():
            out[k] = int(out[k]) + int(p.get(k, 0))
    return out


func _melee(cls: String, main: int, off: int, power: int, dual: bool) -> float:
    var coef := float(CLASS_MELEE_COEF[cls])
    var out := 0.0
    for _i in MELEE_SWINGS:
        out += (float(main) + float(power)) * coef
        if dual:
            out += (float(off) * OFFHAND_COEF + float(power)) * coef
    return out


## docs/08 §9.1's stage row, reproduced rather than restated. At Tier 1 this
## returns 182.3 / 193.9 / 214.1 / 239.7 / 325.0 / 329.0 — the doc's own table.
func _stage(tier: int, stage: int) -> Dictionary:
    var a := TS.rung_of(tier, false)
    var b := TS.rung_of(tier, true)
    var ch: Dictionary = _charm[a]     # §9.1: Charm of Power (melee) / Mana (casters)
    var sword: int
    var dagger: int
    var monk_w: int
    var mage_w: int
    var wiz_w: int
    if stage == 0:
        sword = wpn("sword", a); dagger = wpn("sword", a)
        monk_w = wpn("monk", a); mage_w = wpn("mage", a); wiz_w = wpn("wizard", a)
    elif stage <= 3:
        sword = wpn("sword_basic", b); dagger = wpn("dagger_basic", b)
        monk_w = wpn("monk_basic", b); mage_w = wpn("mage_basic", b); wiz_w = wpn("wizard_basic", b)
    else:
        sword = wpn("sword_strong", b); dagger = wpn("dagger_strong", b)
        monk_w = wpn("monk_strong", b); mage_w = wpn("mage_strong", b); wiz_w = wpn("wizard_strong", b)

    var gw := _gear("warrior_bard", tier, stage)
    var gm := _gear("monk", tier, stage)
    var gr := _gear("rogue", tier, stage)
    var gc := _gear("mage_wizard", tier, stage)
    var pw_w := int(gw["power"]) + int(ch["power"])
    var pw_bard := pw_w
    if stage >= 5:
        # §9.1's Boss 5 row is "capstones; Shield only statted" — the Warrior
        # picks up the Shield's Power, the Bard's Instrument carries none, and
        # the Mage/Wizard Final staves are deliberately not counted there.
        pw_w += maxi(1, TS.round_half_up(SHIELD_POWER_RATIO * float(total("warrior_bard", b)["power"])))
    var mana := int(gc["mana"]) + int(ch["mana"])

    var warrior := _melee("warrior", sword, 0, pw_w, false)
    var monk := _melee("monk", monk_w, 0, int(gm["power"]) + int(ch["power"]), false)
    var rogue := _melee("rogue", dagger, dagger, int(gr["power"]) + int(ch["power"]), true)
    var bard := _melee("bard", sword, 0, pw_bard, false)
    var wizard := (float(wiz_w) + float(mana) * MANA_TO_SPELL) * WIZARD_SPELL_COEF
    var mage := (float(mage_w) + float(mana) * MANA_TO_SPELL) * MAGE_SPELL_COEF
    var raid_total := 2.0 * warrior + monk + 2.0 * rogue + bard + mage + 2.0 * wizard
    return {"warrior": warrior, "monk": monk, "rogue": rogue, "bard": bard,
        "wizard": wizard, "mage": mage, "mana": mana, "total": raid_total}


## One raid encounter's whole budget, by docs/08 §9.2/§9.3/§9.5's own method.
func _budget_row(tier: int, boss: int) -> Dictionary:
    var a := TS.rung_of(tier, false)
    var stage := _stage(tier, boss - 1)
    var rounds: int = TS.TARGET_ROUNDS[boss - 1]
    var gw := _gear("warrior_bard", tier, boss - 1)
    var gc := _gear("mage_wizard", tier, boss - 1)
    var tank_ac := int(gw["ac"]) + int(_charm[a]["ac"])
    var tank_hp := int(BASE_HP["warrior"]) + int(gw["hp"])
    var cloth_ac := int(gc["ac"])
    var cloth_hp := int(BASE_HP["mage"]) + int(gc["hp"])
    var raw := TS.boss_auto_raw(tank_hp, tank_ac)
    return {
        "tier": tier, "boss": boss, "dps": float(stage["total"]), "rounds": rounds,
        "hp": TS.boss_hp(float(stage["total"]), rounds),
        "tank_ac": tank_ac, "tank_hp": tank_hp,
        "mitigation": Formulas.mitigation(tank_ac),
        "raw": raw,
        "clock": TS.unhealed_clock(tank_hp, tank_ac, raw),
        "cloth_ac": cloth_ac, "cloth_hp": cloth_hp,
        "aoe": TS.aoe_pulse(cloth_hp), "aoe_gross": TS.aoe_pulse_gross(cloth_hp, cloth_ac),
    }


## The Adventure ladder's budget. docs/10 §8's corrected rule: Adventure tier N
## is played in tier N-1's gear, and each rung is sized for the gear the rung
## before it dropped. Party of six, one tank, one healer.
func _adventure_row(tier: int, rung_index: int) -> Dictionary:
    var a := TS.rung_of(tier, false)
    var prev_b := TS.rung_of(tier - 1, true)
    # Slots the party has replaced by the time it fights this rung: A2 has A1's
    # feet and first weapon, A3 also has A2's legs.
    var replaced := {}
    if rung_index >= 1:
        replaced["feet"] = true
    if rung_index >= 2:
        replaced["legs"] = true

    var gear := {}
    for fam in FAMS:
        var g := {"ac": 0, "hp": 0, "mana": 0, "power": 0}
        for slot in SLOTS:
            var p := piece(fam, a if replaced.has(slot) else prev_b, slot)
            for k in g.keys():
                g[k] = int(g[k]) + int(p.get(k, 0))
        gear[fam] = g
    var ch: Dictionary = _charm[prev_b]

    var sword: int = wpn("sword", a) if rung_index >= 1 else wpn("sword_strong", prev_b)
    var dagger: int = wpn("sword", a) if rung_index >= 1 else wpn("dagger_strong", prev_b)
    var wiz_w: int = wpn("wizard", a) if rung_index >= 1 else wpn("wizard_strong", prev_b)
    var mage_w: int = wpn("mage", a) if rung_index >= 1 else wpn("mage_strong", prev_b)

    var gw: Dictionary = gear["warrior_bard"]
    var gr: Dictionary = gear["rogue"]
    var gc: Dictionary = gear["mage_wizard"]
    var mana := int(gc["mana"]) + int(ch["mana"])
    var warrior := _melee("warrior", sword, 0, int(gw["power"]) + int(ch["power"]), false)
    var rogue := _melee("rogue", dagger, dagger, int(gr["power"]) + int(ch["power"]), true)
    var wizard := (float(wiz_w) + float(mana) * MANA_TO_SPELL) * WIZARD_SPELL_COEF
    var mage := (float(mage_w) + float(mana) * MANA_TO_SPELL) * MAGE_SPELL_COEF
    var party := warrior + 2.0 * rogue + wizard + mage

    var tank_ac := int(gw["ac"]) + int(ch["ac"])
    var tank_hp := int(BASE_HP["warrior"]) + int(gw["hp"])
    var cloth_hp := int(BASE_HP["mage"]) + int(gc["hp"])
    var rounds: int = TS.ADVENTURE_TARGET_ROUNDS[rung_index]
    return {
        "tier": tier, "rung": rung_index, "dps": party, "rounds": rounds,
        "hp": TS.boss_hp(party, rounds),
        "tank_ac": tank_ac, "tank_hp": tank_hp,
        "raw": TS.adventure_raw_per_round(tank_hp, tank_ac, rung_index),
        "clock": TS.ADVENTURE_CLOCKS[rung_index],
        "cloth_hp": cloth_hp, "aoe": TS.adventure_aoe_pulse(cloth_hp),
    }


func _print_budget_markdown() -> void:
    print("### 9.6 Tiers 2-5 boss budget (generated by tools/gen_items.gd -- budget)")
    print("")
    for tier in range(1, 6):
        print("#### Tier %d raid" % tier)
        print("")
        print("| Boss | Raid DPS at attempt | Rounds | Boss HP | Tank AC | Tank HP | Mit |"
            + " Raw/rd | Clock | Cloth AC/HP | AoE pulse | AoE grossed |")
        print("|---|---|---|---|---|---|---|---|---|---|---|---|")
        for boss in range(1, 6):
            var r := _budget_row(tier, boss)
            print("| Boss %d | %.1f | %d | **%d** | %d | %d | %.1f%% | **%d** | %.2f | %d / %d | **%d** | %d |"
                % [r["boss"], r["dps"], r["rounds"], r["hp"], r["tank_ac"], r["tank_hp"],
                   float(r["mitigation"]) * 100.0, r["raw"], r["clock"],
                   r["cloth_ac"], r["cloth_hp"], r["aoe"], r["aoe_gross"]])
        print("")
    for tier in range(2, 6):
        print("#### Tier %d Adventure" % tier)
        print("")
        print("| Rung | Party DPS at its own stage | Rounds | Pull HP | Tank AC | Tank HP |"
            + " Raw/rd | Clock | M02 pulse |")
        print("|---|---|---|---|---|---|---|---|---|")
        for i in 3:
            var r := _adventure_row(tier, i)
            print("| A%d | %.1f | %d | **%d** | %d | %d | **%d** | %.1f | %d |"
                % [i + 1, r["dps"], r["rounds"], r["hp"], r["tank_ac"], r["tank_hp"],
                   r["raw"], r["clock"], r["aoe"]])
        print("")
    print("#### Family totals per rung (docs/09 §13.2 ladder)")
    print("")
    print("| Family | r1 | r2 | r3 | r4 | r5 | r6 | r7 | r8 | r9 | r10 |")
    print("|---|---|---|---|---|---|---|---|---|---|---|")
    for fam in FAMS:
        var cells: Array[String] = []
        for rung in range(1, TS.RUNGS + 1):
            var t := total(fam, rung)
            cells.append("%d/%d/%d" % [int(t["ac"]), int(t["hp"]), int(t["mana"])])
        print("| %s AC/HP/Mana | %s |" % [fam, " | ".join(cells)])
    print("")


# ================================================================ encounters

## AUTHORED, not generated (docs/10 §6 and §10). `mechanics` is the mechanic
## selection per encounter, subject to §10's two tier rules: at most two
## mechanics the player has not seen, and all four role groups stressed before
## E5. Tier 1 uses M01-M06, M08, M09; Tier 2 introduces M07 and M11; Tier 3
## introduces M10 and M12; Tiers 4 and 5 recombine and introduce nothing.
const MECHANIC_PLAN := {
    2: [["m04"], ["m04", "m02"], ["m01", "m02", "m11"],
        ["m03", "m05", "m07", "m09"], ["m01", "m02", "m03", "m11", "m06"]],
    3: [["m02"], ["m04", "m11"], ["m01", "m02", "m10"],
        ["m03", "m07", "m09", "m12"], ["m01", "m02", "m08", "m10", "m06"]],
    4: [["m11"], ["m02", "m12"], ["m01", "m05", "m10"],
        ["m03", "m04", "m07", "m09"], ["m01", "m02", "m08", "m12", "m06"]],
    5: [["m12"], ["m02", "m10"], ["m01", "m03", "m11"],
        ["m05", "m07", "m08", "m09"], ["m01", "m02", "m04", "m12", "m06"]],
}

const ALL_NINE_MISTAKES := ["warrior_lost_aggro", "monk_panicked_stance", "rogue_faced_the_boss",
    "cleric_wrong_target", "druid_skipped_heal", "shaman_bad_bounce", "mage_overpull",
    "wizard_broke_the_ramp", "bard_wrong_song"]

const MISTAKES := {
    2: [["mage_overpull", "warrior_lost_aggro"],
        ["druid_skipped_heal", "mage_overpull"],
        ["warrior_lost_aggro", "monk_panicked_stance", "rogue_faced_the_boss"],
        ["rogue_faced_the_boss", "wizard_broke_the_ramp", "cleric_wrong_target", "shaman_bad_bounce"],
        ALL_NINE_MISTAKES],
    3: [["druid_skipped_heal", "shaman_bad_bounce"],
        ["mage_overpull", "rogue_faced_the_boss"],
        ["warrior_lost_aggro", "bard_wrong_song", "cleric_wrong_target"],
        ["rogue_faced_the_boss", "wizard_broke_the_ramp", "shaman_bad_bounce", "monk_panicked_stance"],
        ALL_NINE_MISTAKES],
    4: [["rogue_faced_the_boss", "monk_panicked_stance"],
        ["druid_skipped_heal", "warrior_lost_aggro"],
        ["monk_panicked_stance", "bard_wrong_song", "cleric_wrong_target"],
        ["mage_overpull", "wizard_broke_the_ramp", "rogue_faced_the_boss", "shaman_bad_bounce"],
        ALL_NINE_MISTAKES],
    5: [["warrior_lost_aggro", "cleric_wrong_target"],
        ["bard_wrong_song", "druid_skipped_heal"],
        ["monk_panicked_stance", "rogue_faced_the_boss", "shaman_bad_bounce"],
        ["rogue_faced_the_boss", "wizard_broke_the_ramp", "cleric_wrong_target", "mage_overpull"],
        ALL_NINE_MISTAKES],
}

## docs/10 §6: "Required. One sentence: what makes this funny when it goes
## wrong. If it cannot be filled in, the encounter is a chore and should be
## cut." Written by a person, per encounter. A generated joke fails the
## project's own premise, so these are the one thing in the file typed by hand.
const COMEDY := {
    2: [
        "Two packs, one corridor, and a Mage who has learned exactly one lesson from Tier 1: pull the second pack from further away.",
        "The room breathes on everybody every fourth round, and your Druid has decided this is the fight where he tries out a rotation.",
        "It swings wide enough to catch three melee at once, which the Rogue interprets as an invitation to stand closer.",
        "Four things to get right at once, and the Wizard is still explaining why the last wipe was a positioning issue and not his.",
        "Your guild beat this fight on the pull. Then it kept going for another nineteen rounds, and by round twenty they had reinvented the wipe.",
    ],
    3: [
        "One raid-wide pulse a round earlier than anybody expected, and the healers discover that Tier 2's comfortable margin was Tier 2's.",
        "Adds and a cleave, so the melee must move and the casters must not, and precisely one of those groups has been listening.",
        "The silence window lands on the only three raiders with a plan, leaving the plan to the nine who do not have one.",
        "It escalates, it debuffs the healer, it demands a formation, and your Bard is confident the song is helping.",
        "Twenty-two rounds of a boss that gets angrier every round, against a guild whose defining trait is getting slower every round.",
    ],
    4: [
        "A one-star fight whose entire mechanic is 'do not stand in front of it', which is where your Monk likes to stand.",
        "The swing grows, the room pulses, and somebody in your raid is doing the arithmetic out loud and getting it wrong.",
        "Silence, an interrupt check and a tank swap, all landing in the same round, on a raid that struggles with one of them.",
        "Four mechanics, twelve raiders, and a Mage who found an add nobody else could see and pulled it anyway.",
        "Your best fight so far, ruined for the eleventh time by the exact same raider making a slightly different mistake.",
    ],
    5: [
        "The boss swings harder every single round from the pull, and your raid's whole strategy is 'be quick about it'.",
        "The casters are silenced while the room is pulsing, so for four rounds the guild's fate rests on the people who hit things.",
        "A tank swap, a puddle and a cleave: three ways to be standing in the wrong place, and your melee will find a fourth.",
        "It fixates, it silences, it demands a formation and it checks the interrupt, and your Rogue is facing the wrong way for all four.",
        "The last boss in the game, and the log will still say a raider named Steve stood in something on round twenty-one.",
    ],
}

const ADVENTURE_COMEDY := {
    2: [
        "A fresh Adventure in last tier's raid gear, which the party reads as being unbeatable rather than as being adequate.",
        "Two of them and something in the room that breathes, and the one healer you brought is doing sums.",
        "A tank swap with one tank, a puddle, and a raid-wide, for six people who have between them one good idea.",
    ],
    3: [
        "The trash is bigger and so is your guild, and neither of those facts has reached the Rogue.",
        "Somebody breathes on the party every fourth round and your healer's answer is to heal the tank, who is fine.",
        "Three mechanics, six raiders and a mini boss that only needs one of them to be facing the wrong way.",
    ],
    4: [
        "Your raiders are carrying gear worth more than the town and are being hit by three things in a cave.",
        "The pull is routine, the pulse is routine, and your party has stopped reading the room entirely.",
        "It swaps, it pulses and it puddles, and your six best raiders have collectively decided the puddle is decorative.",
    ],
    5: [
        "The last Adventure in the game, fought by six people who still cannot agree who pulls.",
        "Two enormous trash mobs and one healer, and the healer is the one who suggested this.",
        "The final warm-up before the final raid, and your party treats it exactly like the first one.",
    ],
}


func _raid_encounters_doc(tier: int) -> Dictionary:
    var encounters: Array = []
    var kinds := ["trash", "hard_trash", "mini_boss", "mini_boss", "main_boss"]
    var loot := [["feet", "weapon_basic"], ["legs", "offhand_healer"], ["head"],
        ["chest", "weapon_strong"], ["capstone", "trinket"]]
    for i in 5:
        var boss := i + 1
        var r := _budget_row(tier, boss)
        var rounds := int(r["rounds"])
        encounters.append({
            "id": "t%d_raid_e%d" % [tier, boss],
            "display_name": "Raid %d — Encounter %d" % [tier, boss],
            "tier": tier,
            "slot": "E%d" % boss,
            "stars": boss,
            "kind": kinds[i],
            "party_size": 12,
            "tanks_required": 2,
            "enemies": _raid_enemies(i, r),
            "mechanics": _mechanics_for(tier, i, r, rounds),
            "mistakes_invited": MISTAKES[tier][i],
            "loot_slots": loot[i],
            "target_rounds": rounds,
            "enrage_round": TS.enrage_for(rounds),
            "comedy_line": COMEDY[tier][i],
        })
    return {
        "schema_version": 1,
        "tier": tier,
        "_source": {
            "generator": "tools/gen_items.gd (numbers); mechanics and comedy authored in it",
            "structure": "docs/10 §4 (five-encounter ladder), §6 (16-field template)",
            "stat_blocks": "docs/08 §9.6, derived by the §9.1/§9.2/§9.3 method",
            "mechanics": "docs/10 §10 vocabulary, §10's escalation and coverage rules",
        },
        "_notes": _encounter_notes(tier),
        "encounters": encounters,
    }


func _raid_enemies(index: int, r: Dictionary) -> Array:
    var total_hp := int(r["hp"])
    var raw := int(r["raw"])
    var add_swing: int = maxi(1, TS.round_half_up(float(r["cloth_hp"]) * 0.10))
    match index:
        0:
            # docs/10 §7.1: a four-mob pack divides the tank channel four ways,
            # plus a round-5 add that sits inside the HP budget.
            var each := int(floor(float(total_hp) * 0.92 / 4.0))
            return [
                {"name": "Trash", "count": 4, "hp": each,
                 "raw_swing": TS.round_half_up(float(raw) / 4.0),
                 "swings_per_round": 1, "threat_rule": "independent"},
                {"name": "Late Add", "count": 1, "hp": total_hp - 4 * each,
                 "raw_swing": add_swing, "swings_per_round": 1,
                 "threat_rule": "lowest_hp", "spawn_round": 5},
            ]
        1:
            # 13% of the pull is the four adds, and the remainder splits evenly
            # across two elites — exactly, because a budget rounded to 50 is
            # even and `4 x add_hp` is even, so the halving never leaves a
            # stray point of HP outside the doc 08 total.
            var add_hp := maxi(1, int(floor(float(total_hp) * 0.13 / 4.0)))
            var elite := (total_hp - 4 * add_hp) / 2
            return [
                {"name": "Elite", "count": 2, "hp": elite,
                 "raw_swing": TS.round_half_up(float(raw) / 2.0),
                 "swings_per_round": 1, "threat_rule": "standard"},
                {"name": "Add", "count": 4, "hp": add_hp, "raw_swing": add_swing,
                 "swings_per_round": 1, "threat_rule": "lowest_hp", "spawn_round": 4},
            ]
        2:
            var add := maxi(1, int(floor(float(total_hp) * 0.05 / 3.0)))
            return [
                {"name": "Mini Boss", "count": 1, "hp": total_hp - 3 * add,
                 "raw_swing": TS.round_half_up(float(raw) / 2.0),
                 "swings_per_round": 2, "threat_rule": "standard"},
                {"name": "Add", "count": 3, "hp": add, "raw_swing": maxi(1, add_swing - 2),
                 "swings_per_round": 1, "threat_rule": "lowest_hp", "spawn_round": 6},
            ]
        3:
            return [{"name": "Mini Boss", "count": 1, "hp": total_hp,
                "raw_swing": TS.round_half_up(float(raw) / 2.0),
                "swings_per_round": 2, "threat_rule": "standard"}]
    return [{"name": "Main Boss", "count": 1, "hp": total_hp,
        "raw_swing": TS.round_half_up(float(raw) / 2.0),
        "swings_per_round": 2, "threat_rule": "standard"}]


## Mechanic parameters are DERIVED wherever docs/10 §10 gives a formula: M02 and
## M03 off the cloth pool, M11 and M12 off the tank channel, M06 off the enrage
## round. The parameter NAMES are RaidSim's (sim/core/RaidSim.gd), because a key
## the sim does not read is a star that buys nothing.
func _mechanics_for(tier: int, index: int, r: Dictionary, rounds: int) -> Array:
    var out: Array = []
    var aoe := int(r["aoe"])
    var cloth_hp := int(r["cloth_hp"])
    var raw := int(r["raw"])
    for id in MECHANIC_PLAN[tier][index]:
        var key := String(id)
        var params := {}
        match key:
            "m01":
                params = {"stack_damage_pct": 50, "swap_at": 3}
            "m02":
                params = {"damage": aoe, "every": 4, "ignores_ac": true}
            "m03":
                params = {"damage_per_round": TS.round_half_up(float(cloth_hp) * 0.30),
                    "escape_chance_bp": 5000}
            "m04":
                var add_hp: int = maxi(1, TS.round_half_up(float(r["hp"]) * 0.03))
                params = {"count": 2, "hp": add_hp,
                    "swing": maxi(1, TS.round_half_up(float(cloth_hp) * 0.10)),
                    "round": 5, "every": 6}
            "m05":
                params = {"round": 4, "every": 5, "requires_melee": 1}
            "m06":
                params = {"round": TS.enrage_for(rounds), "damage_multiplier_pct": 200}
            "m07":
                params = {"required": "spread" if index % 2 == 0 else "stacked",
                    "round": 3, "every": 5, "rounds": 2,
                    "damage": TS.round_half_up(float(cloth_hp) * 0.12)}
            "m08":
                params = {"rounds": 3, "round": 5, "every": 6}
            "m09":
                params = {"reduction_pct": 40, "rounds": 3, "target": "active_tank",
                    "round": 4, "every": 6}
            "m10":
                params = {"rounds": 2, "round": 5, "every": 6}
            "m11":
                # A cleave is tank-channel pressure on the melee line, so it is
                # priced off the boss's own per-round raw rather than invented.
                params = {"damage": maxi(1, TS.round_half_up(float(raw) * 0.12))}
            "m12":
                params = {"increment": maxi(1, TS.round_half_up(float(raw) * 0.04)),
                    "from_round": 3}
        out.append({"id": key, "params": params})
    return out


func _encounter_notes(tier: int) -> Array:
    return [
        "GENERATED FILE. tools/gen_items.gd writes it; re-run rather than hand-editing.",
        "HP and per-round raw are QUOTED from docs/08 §9.6, which derives them by",
        "§9.1/§9.2/§9.3's own method — the same method that reproduces Tier 1's",
        "published 2200/2500/3200/4100/7150 and 61/63/65/68/73 exactly.",
        "target_rounds hold at docs/08 §9.2's 12/13/15/17/22 and enrage is",
        "ceil(1.4 x target_rounds), which ContentDB validates on load.",
        "MECHANIC SELECTION AND COMEDY ARE AUTHORED, not generated. docs/10 §10's",
        "escalation rule caps a tier at two mechanics the player has not seen:",
        "Tier 2 introduces M07 and M11, Tier 3 M10 and M12, Tiers 4-5 recombine.",
        "Mechanic MAGNITUDES are derived: M02 and M03 off the cloth pool, M11 and",
        "M12 off the tank channel, M06 off the enrage round.",
        "Total HP steps DOWN at every tier boundary and that is correct: E1's",
        "target length resets to 12 rounds while E5's was 22. The monotone",
        "quantities across the whole 25-fight ladder are raid DPS at attempt and",
        "boss raw per round, and docs/08 §9.6 says so.",
        "Names are canon placeholders; tier %d has not been named (docs/10 §2)." % tier,
    ]


func _adventure_encounters_doc(tier: int) -> Dictionary:
    var encounters: Array = []
    var kinds := ["trash", "hard_trash", "mini_boss"]
    var loot := [["feet", "weapon"], ["legs"], ["head", "chest"]]
    var plan := [["m04"], ["m04", "m02"], ["m01", "m02", "m03"]]
    for i in 3:
        var r := _adventure_row(tier, i)
        var rounds := int(r["rounds"])
        var pull := int(r["hp"])
        var mechanics: Array = []
        for id in plan[i]:
            var key := String(id)
            match key:
                "m04":
                    mechanics.append({"id": "m04", "params": {
                        "count": 1, "hp": TS.adventure_add_hp(pull, i),
                        "swing": maxi(1, TS.round_half_up(float(r["raw"]) * 0.18)),
                        "round": 5 + i}})
                "m02":
                    mechanics.append({"id": "m02", "params": {
                        "damage": int(r["aoe"]), "every": 4, "ignores_ac": true}})
                "m01":
                    mechanics.append({"id": "m01", "params": {
                        "stack_damage_pct": 50, "swap_at": 3}})
                "m03":
                    mechanics.append({"id": "m03", "params": {
                        "damage_per_round": TS.round_half_up(float(r["cloth_hp"]) * 0.22),
                        "escape_chance_bp": 5000}})
        encounters.append({
            "id": "t%d_adv_a%d" % [tier, i + 1],
            "display_name": "Adventure %d — %s" % [tier,
                "Mini Boss" if i == 2 else "Encounter %d" % (i + 1)],
            "tier": tier,
            "slot": "A%d" % (i + 1),
            "stars": i + 1,
            "kind": kinds[i],
            "party_size": TS.ADVENTURE_PARTY_SIZE,
            "tanks_required": 1,
            "enemies": _adventure_enemies(i, pull, int(r["raw"])),
            "mechanics": mechanics,
            "mistakes_invited": [["mage_overpull", "warrior_lost_aggro"],
                ["druid_skipped_heal", "rogue_faced_the_boss"],
                ["warrior_lost_aggro", "cleric_wrong_target", "monk_panicked_stance"]][i],
            "loot_slots": loot[i],
            "target_rounds": rounds,
            "enrage_round": TS.enrage_for(rounds),
            "comedy_line": ADVENTURE_COMEDY[tier][i],
        })
    return {
        "schema_version": 1,
        "tier": tier,
        "_source": {
            "generator": "tools/gen_items.gd (numbers); mechanics and comedy authored in it",
            "structure": "docs/10 §8 (Adventure anatomy), and docs/15's ruling that"
                + " Adventures 2-5 keep the A1/A2/A3 shape at each tier's numbers",
            "stat_blocks": "docs/08 §9.6's Adventure rows",
        },
        "_notes": [
            "GENERATED FILE. tools/gen_items.gd writes it; re-run rather than hand-editing.",
            "PARTY SIZE 6, TANKS REQUIRED 1 (docs/10 §3).",
            "THE GEAR ASSUMPTION (docs/10 §8): Adventure tier N is played in tier N-1's",
            "gear, and EACH RUNG IS SIZED FOR THE GEAR THE RUNG BEFORE IT DROPPED.",
            "Sizing all three rungs at one stage is the mistake docs/10 §8 made twice",
            "and warns about in writing; A1 here is the previous tier's full raid",
            "clear, A2 adds this tier's Adventure feet and weapon, A3 its legs.",
            "UNHEALED TANK CLOCKS are docs/10 §8's intended 5.5 / 4.3 / 3.5 rounds,",
            "evaluated at each rung's OWN tank AC, not the tier's entry AC.",
            "M02 IS HELD CONSTANT PER HEALER, not per raider: a party of six with one",
            "healer carries docs/08 §9.5's pulse 1.5x harder than a 12-raid with three.",
            "M04's add HP is a fraction of the pull, not a fixed number, so re-sizing",
            "the pull cannot change the encounter's shape (docs/10 §8 knock-on 1).",
            "Names are canon placeholders; the designer has not named this content.",
        ],
        "encounters": encounters,
    }


func _adventure_enemies(index: int, pull: int, raw: int) -> Array:
    match index:
        0:
            var each := maxi(1, TS.round_half_up(float(pull) / 3.0))
            return [{"name": "Trash", "count": 3, "hp": each,
                "raw_swing": TS.round_half_up(float(raw) / 3.0),
                "swings_per_round": 1, "threat_rule": "independent"}]
        1:
            var each2 := maxi(1, TS.round_half_up(float(pull) / 2.0))
            return [{"name": "Harder Trash", "count": 2, "hp": each2,
                "raw_swing": TS.round_half_up(float(raw) / 2.0),
                "swings_per_round": 1, "threat_rule": "independent"}]
    return [{"name": "Mini Boss", "count": 1, "hp": pull,
        "raw_swing": TS.round_half_up(float(raw) / 2.0),
        "swings_per_round": 2, "threat_rule": "highest_threat"}]


# ================================================================ output

## MERGE, NEVER CLOBBER. docs/09 §13.5 is explicit that some rows are
## hand-written and always will be: "Hand-author, always: capstones (Boss 5),
## trinkets, and any item with a joke in it." A generator that overwrote those
## would make the first person to write a joke lose it on the next run, and they
## would find out days later.
##
## So any row in the file on disk carrying `"hand_authored": true` wins over the
## generated row with the same id, and a hand-authored row with no generated
## counterpart is kept as well. Nothing else is preserved: a generated row that
## somebody edited WITHOUT marking it is still overwritten, because that is the
## whole point of generating it.
static func _merge_hand_authored(path: String, doc: Dictionary) -> Dictionary:
    if not FileAccess.file_exists(path):
        return doc
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not (parsed is Dictionary):
        return doc
    var kept := {}
    for row in (parsed as Dictionary).get("items", []):
        if row is Dictionary and bool(row.get("hand_authored", false)):
            kept[String(row.get("id", ""))] = row
    if kept.is_empty():
        return doc
    var out: Array = []
    var used := {}
    for row in doc.get("items", []):
        var id := String((row as Dictionary).get("id", ""))
        if kept.has(id):
            out.append(kept[id])
            used[id] = true
        else:
            out.append(row)
    for id in kept.keys():
        if not used.has(id):
            out.append(kept[id])
    doc["items"] = out
    print("  kept     %d hand-authored row(s) in %s" % [kept.size(), path])
    return doc


func _write_json(path: String, doc: Dictionary, mode: String) -> void:
    if doc.has("items"):
        doc = _merge_hand_authored(path, doc)
    var text := JSON.stringify(doc, "  ") + "\n"
    var existing := ""
    if FileAccess.file_exists(path):
        existing = FileAccess.get_file_as_string(path)
    if existing == text:
        return
    _written += 1
    if mode == "check":
        print("  DIFFERS  %s" % path)
        return
    var f := FileAccess.open(path, FileAccess.WRITE)
    if f == null:
        _problems.append("cannot write %s" % path)
        return
    f.store_string(text)
    f.close()
    print("  wrote    %s" % path)
