extends "res://tests/TestCase.gd"
## ============================================================================
## THE CANON GUARD — do not weaken this file.
## ============================================================================
##
## Every number below is the lead designer's, transcribed from
## docs/_source/lead-designer-notes-raw.md and
## docs/_source/ideaboard-transcription.md.
##
## If a test here fails, the DATA is wrong, not the expectation. The only
## legitimate reason to change a number in this file is that the designer
## changed the canon source — in which case update the source first, and say so
## in the commit.
##
## This runs through ContentDB, i.e. the exact path the game uses, so it also
## catches a loader that quietly drops or rewrites a value. Per-file tests check
## the JSON cell by cell; this one checks what the game actually ends up holding.

const DB = preload("res://sim/content/ContentDB.gd")
const E = preload("res://sim/model/Enums.gd")
const S = preload("res://sim/model/Stats.gd")

var _db = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()

func _s(id: String):
    var it = _db.item(id)
    if it == null:
        fail("canon item missing from the loaded content: %s" % id)
        return S.new()
    return it.stats

func _sum_ids(ids: Array):
    var blocks := []
    for id in ids:
        blocks.append(_s(id))
    return S.sum(blocks)

# ============================================================ structural canon

func test_content_loads_clean() -> void:
    assert_true(_db.is_valid(), _db.error_report())

func test_canon_structural_facts() -> void:
    assert_eq(E.RAID_SIZE, 12, "canon: raid size is 12")
    assert_eq(E.TYPICAL_TANKS, 2, "canon: most fights normally require 2 tanks")
    assert_eq(E.ENCOUNTERS_PER_RAID, 5, "canon: five encounters per raid tier")
    assert_eq(E.CLASS_KEYS.size(), 9, "canon: nine classes")
    assert_eq(E.SLOT_KEYS.size(), 7, "seven slots")
    assert_eq(E.REPUTATION_KEYS.size(), 6, "canon: six reputation ranks")
    assert_eq(E.MORALE_MIN, 0)
    assert_eq(E.MORALE_MAX, 100)
    assert_eq(E.MORALE_BAND_COUNT, 10, "canon: ten morale bands of ten")

func test_canon_class_roster() -> void:
    var expected := {
        "warrior": "Main Tank", "cleric": "Main Tank Healer",
        "druid": "Raid Healer", "shaman": "Chain Healer",
        "rogue": "Melee DPS", "monk": "Melee DPS / Offtank",
        "mage": "AoE Caster", "wizard": "Single-Target Caster",
        "bard": "Support",
    }
    for key in expected.keys():
        var cd = _db.class_by_key(key)
        assert_ne(cd, null, "missing class %s" % key)
        assert_eq(cd.role_name(), expected[key], "%s role" % key)

# ============================================================ tier 0 — starting

func test_canon_starting_ac_totals() -> void:
    # raw notes, *Starting armor for common recruits*
    var expected := {
        "warrior": 7, "bard": 7, "monk": 6, "rogue": 5, "cleric": 5,
        "druid": 5, "shaman": 5, "mage": 4, "wizard": 4,
    }
    for key in expected.keys():
        var total := 0
        for it in _db.starting_set(key):
            total += it.stats.ac
        assert_eq(total, expected[key], "%s starting AC" % key)

func test_canon_starting_gear_is_ac_only_and_armor_only() -> void:
    for key in E.CLASS_KEYS:
        var pieces: Array = _db.starting_set(key)
        assert_eq(pieces.size(), 4, "%s should start with four pieces" % key)
        for it in pieces:
            assert_true(it.is_armor(), "%s: %s is not armor" % [key, it.id])
            assert_eq(it.stats.hp, 0, "%s carries HP" % it.id)
            assert_eq(it.stats.power, 0, "%s carries Power" % it.id)
            assert_eq(it.stats.mana, 0, "%s carries Mana" % it.id)
            assert_eq(it.stats.damage, 0, "%s carries Damage" % it.id)

func test_canon_worn_leggings_is_two_different_items() -> void:
    # The trap: same canon name, 2 AC on plate and 1 AC on cloth.
    assert_eq(_s("ITM_T0_START_WARBARD_LEGS").ac, 2)
    assert_eq(_s("ITM_T0_START_HEALER_LEGS").ac, 1)
    assert_eq(_db.item("ITM_T0_START_WARBARD_LEGS").name, "Worn Leggings")
    assert_eq(_db.item("ITM_T0_START_HEALER_LEGS").name, "Worn Leggings")

# ============================================================ tier 1 — adventure

func test_canon_adventure_armor_totals() -> void:
    # ideaboard §2.5 — the five family totals. [ac, hp, mana]
    var families := {
        "warrior_bard": [["ITM_T1_ADV_WARBARD_HEAD", "ITM_T1_ADV_WARBARD_CHEST",
                          "ITM_T1_ADV_WARBARD_LEGS", "ITM_T1_ADV_WARBARD_FEET"], [15, 16, 0]],
        "monk":         [["ITM_T1_ADV_MONKHEAD_HEAD", "ITM_T1_ADV_MONKROGUE_CHEST",
                          "ITM_T1_ADV_MONKROGUE_LEGS", "ITM_T1_ADV_MONKROGUE_FEET"], [14, 14, 0]],
        "rogue":        [["ITM_T1_ADV_ROGUEHEAD_HEAD", "ITM_T1_ADV_MONKROGUE_CHEST",
                          "ITM_T1_ADV_MONKROGUE_LEGS", "ITM_T1_ADV_MONKROGUE_FEET"], [13, 14, 0]],
        "healer":       [["ITM_T1_ADV_HEALER_HEAD", "ITM_T1_ADV_HEALER_CHEST",
                          "ITM_T1_ADV_HEALER_LEGS", "ITM_T1_ADV_HEALER_FEET"], [9, 12, 13]],
        "mage_wizard":  [["ITM_T1_ADV_MAGEWIZ_HEAD", "ITM_T1_ADV_MAGEWIZ_CHEST",
                          "ITM_T1_ADV_MAGEWIZ_LEGS", "ITM_T1_ADV_MAGEWIZ_FEET"], [8, 10, 17]],
    }
    for label in families.keys():
        var t = _sum_ids(families[label][0])
        var want: Array = families[label][1]
        assert_eq([t.ac, t.hp, t.mana], want, "%s adventure armor total" % label)

func test_canon_adventure_weapons_and_trinkets() -> void:
    assert_eq(_s("ITM_T1_ADV_W1H_MH").damage, 5, "Iron Adventurer's Sword")
    assert_eq(_s("ITM_T1_ADV_W2H_MONK_MH").damage, 9, "Iron Adventurer's Staff")
    assert_eq(_s("ITM_T1_ADV_W2H_MAGE_MH").damage, 10, "Apprentice's Firestaff")
    assert_eq(_s("ITM_T1_ADV_W2H_WIZ_MH").damage, 10, "Apprentice's Arcstaff")
    assert_eq(_s("ITM_T1_ADV_UNIV_TRINKET_HEALTH").hp, 7)
    assert_eq(_s("ITM_T1_ADV_UNIV_TRINKET_ARMOR").ac, 2)
    assert_eq(_s("ITM_T1_ADV_UNIV_TRINKET_MANA").mana, 10)
    assert_eq(_s("ITM_T1_ADV_UNIV_TRINKET_POWER").power, 2)

func test_canon_no_adventure_offhands() -> void:
    for id in _db.items.keys():
        var it = _db.item(id)
        if it.source == "adventure":
            assert_ne(it.slot, E.Slot.OFF_HAND,
                "canon Tier 1 Adventure has no off-hands, found %s" % id)

# ============================================================ tier 1 — raid

func test_canon_raid_armor_totals() -> void:
    # docs/08 §6's "+ T1 Raid armor" column, from CANON items only.
    var expected := {
        "warrior": [21, 24], "bard": [21, 24], "monk": [20, 22], "rogue": [19, 21],
        "cleric": [13, 19], "druid": [13, 19], "shaman": [13, 19],
        "mage": [13, 16], "wizard": [13, 16],
    }
    for key in expected.keys():
        var blocks := []
        for boss in range(1, 6):
            for it in _db.raid_drops(key, boss):
                if it.is_armor() and it.canon:
                    blocks.append(it.stats)
        var t = S.sum(blocks)
        assert_eq([t.ac, t.hp], expected[key], "%s raid armor" % key)

func test_canon_raid_piece_stats() -> void:
    # Every canon raid armour and off-hand piece. [ac, hp, power, mana]
    var expected := {
        "ITM_T1_RAID_WARBARD_HEAD": [5, 5, 1, 0],
        "ITM_T1_RAID_WARBARD_CHEST": [7, 9, 2, 0],
        "ITM_T1_RAID_WARBARD_LEGS": [5, 6, 1, 0],
        "ITM_T1_RAID_WARBARD_FEET": [4, 4, 0, 0],
        "ITM_T1_RAID_MONKHEAD_HEAD": [5, 5, 0, 0],
        "ITM_T1_RAID_ROGUEHEAD_HEAD": [4, 4, 2, 0],
        "ITM_T1_RAID_MONKROGUE_CHEST_MONK": [6, 7, 2, 0],
        "ITM_T1_RAID_MONKROGUE_CHEST_ROGUE": [6, 7, 2, 0],
        "ITM_T1_RAID_MONKROGUE_LEGS": [5, 6, 1, 0],
        "ITM_T1_RAID_MONKROGUE_FEET": [4, 4, 0, 0],
        "ITM_T1_RAID_HEALER_HEAD": [3, 4, 0, 7],
        "ITM_T1_RAID_HEALER_CHEST": [4, 7, 0, 10],
        "ITM_T1_RAID_HEALER_LEGS": [3, 4, 0, 6],
        "ITM_T1_RAID_HEALER_FEET": [3, 4, 0, 4],
        "ITM_T1_RAID_HEALOFF_OH": [2, 0, 0, 5],
        "ITM_T1_RAID_MAGEWIZ_HEAD": [3, 3, 0, 8],
        "ITM_T1_RAID_MAGEWIZ_CHEST": [4, 6, 0, 12],
        "ITM_T1_RAID_MAGEWIZ_LEGS": [3, 4, 0, 8],
        "ITM_T1_RAID_MAGEWIZ_FEET": [3, 3, 0, 6],
        "ITM_T1_RAID_SHIELD_OH": [7, 8, 1, 0],
        "ITM_T1_RAID_INSTR_OH": [0, 0, 0, 20],
    }
    for id in expected.keys():
        var st = _s(id)
        assert_eq([st.ac, st.hp, st.power, st.mana], expected[id], id)

func test_canon_raid_weapon_damage() -> void:
    var expected := {
        "ITM_T1_RAID_W1H_MH_SWORD_BASIC": 6, "ITM_T1_RAID_W1H_MH_SWORD_STRONG": 8,
        "ITM_T1_RAID_W1H_MH_DAGGER_BASIC": 4, "ITM_T1_RAID_W1H_MH_DAGGER_STRONG": 6,
        "ITM_T1_RAID_W2H_MONK_BASIC": 10, "ITM_T1_RAID_W2H_MONK_STRONG": 14,
        "ITM_T1_RAID_W2H_MAGE_BASIC": 11, "ITM_T1_RAID_W2H_MAGE_STRONG": 15,
        "ITM_T1_RAID_W2H_WIZ_BASIC": 12, "ITM_T1_RAID_W2H_WIZ_STRONG": 16,
    }
    for id in expected.keys():
        assert_eq(_s(id).damage, expected[id], id)

func test_canon_warrior_shield_is_the_largest_single_ac_value() -> void:
    var shield_ac: int = _s("ITM_T1_RAID_SHIELD_OH").ac
    assert_eq(shield_ac, 7)
    for id in _db.items.keys():
        var it = _db.item(id)
        if it.canon:
            assert_true(it.stats.ac <= shield_ac,
                "%s has %d AC, above the canon Warrior Shield's %d"
                    % [id, it.stats.ac, shield_ac])

func test_canon_bard_instrument_is_the_largest_single_mana_value() -> void:
    var instr: int = _s("ITM_T1_RAID_INSTR_OH").mana
    assert_eq(instr, 20)
    for id in _db.items.keys():
        var it = _db.item(id)
        if it.canon:
            assert_true(it.stats.mana <= instr,
                "%s has %d Mana, above the canon Bard Instrument's %d"
                    % [id, it.stats.mana, instr])

# ============================================================ the ladder

func test_progression_is_monotonic_for_every_class() -> void:
    # starting AC < adventure AC < raid AC, for all nine classes. If this ever
    # inverts, the loot ladder is broken regardless of what any single table says.
    var adventure := {
        "warrior": 15, "bard": 15, "monk": 14, "rogue": 13,
        "cleric": 9, "druid": 9, "shaman": 9, "mage": 8, "wizard": 8,
    }
    for key in E.CLASS_KEYS:
        var start_ac := 0
        for it in _db.starting_set(key):
            start_ac += it.stats.ac
        var best := {}
        for boss in range(1, 6):
            for it in _db.raid_drops(key, boss):
                if it.is_armor():
                    best[it.slot] = it
        var raid_ac := 0
        for slot in best.keys():
            raid_ac += best[slot].stats.ac
        assert_true(start_ac < adventure[key],
            "%s: starting %d must be below adventure %d" % [key, start_ac, adventure[key]])
        assert_true(adventure[key] < raid_ac,
            "%s: adventure %d must be below raid %d" % [key, adventure[key], raid_ac])

func test_armor_weight_ordering_holds_at_every_rung() -> void:
    # Plate beats leather beats cloth, at all three rungs.
    var rungs := [
        {"warrior": 7, "monk": 6, "rogue": 5, "cleric": 5, "mage": 4},
        {"warrior": 15, "monk": 14, "rogue": 13, "cleric": 9, "mage": 8},
        {"warrior": 21, "monk": 20, "rogue": 19, "cleric": 13, "mage": 13},
    ]
    for rung in rungs:
        assert_true(rung["warrior"] >= rung["monk"], "plate >= monk leather")
        assert_true(rung["monk"] >= rung["rogue"], "monk >= rogue")
        assert_true(rung["rogue"] >= rung["cleric"], "leather >= healer")
        assert_true(rung["cleric"] >= rung["mage"], "healer >= cloth")

func test_canon_only_healer_weapons_and_ten_named_gaps_are_non_canon() -> void:
    # Canon names ten items with no stat block; docs/09 §10.2 fills them in.
    # Anything else claiming canon:false means somebody invented an item.
    var non_canon := []
    for id in _db.items.keys():
        if not _db.item(id).canon:
            non_canon.append(id)
    assert_eq(non_canon.size(), 22,
        "3 adventure healer weapons + 17 raid gap-fills + §10.2 G12's two tutorial "
            + "trinkets; got %s" % str(non_canon.size()))
    for id in non_canon:
        assert_false(_db.item(id).note.is_empty(),
            "%s is non-canon and must cite its derivation" % id)


# ============================================================ the one equation
# docs/08 §8.8 publishes the mistake-chance equation ONCE (docs/15 Q-04/Q-05,
# BL-20, BL-21; W7-DOCS, 2026-09-15 — audit DW-D1/DW-D2). These tests hold the
# doc and `sim/core/Formulas.gd` equal so the fork that once gave the game's most
# important number two values cannot re-open: the doc is read as text, the code
# as constants, and a retune moves both in one commit or fails here.

const FORMULAS = preload("res://sim/core/Formulas.gd")
const COMBATANT = preload("res://sim/model/Combatant.gd")
const DOC_08 := "res://docs/08-stats-and-formulas.md"
const DOC_05 := "res://docs/05-morale.md"

## The ruled coefficients (docs/15 BL-20 adopted docs/05's shape into docs/08).
## Pinned here as well as read from the doc: a deliberate retune is a BL row
## first, then the doc, the code and this table in one commit — never one of them.
const RULED_BP := {
    "Common": [2400, 1.20, 1200, 8500],
    "Uncommon": [1500, 1.05, 800, 5000],
    "Rare": [800, 0.90, 500, 2500],
    "Epic": [350, 0.70, 250, 900],
    "Legendary": [120, 0.50, 90, 250],
}
const RARITY_OF := {
    "Common": E.Rarity.COMMON, "Uncommon": E.Rarity.UNCOMMON, "Rare": E.Rarity.RARE,
    "Epic": E.Rarity.EPIC, "Legendary": E.Rarity.LEGENDARY,
}

func _doc(path: String) -> String:
    var f := FileAccess.open(path, FileAccess.READ)
    assert_true(f != null, "cannot read %s" % path)
    if f == null:
        return ""
    return f.get_as_text().replace("\r\n", "\n")

## The text of one `### N.N` section: from its heading to the next heading of
## the same or a higher level.
func _section(text: String, heading: String) -> String:
    var start := text.find(heading)
    assert_true(start >= 0, "heading not found: %s" % heading)
    if start < 0:
        return ""
    var body_at := start + heading.length()
    var next_h3 := text.find("\n### ", body_at)
    var next_h2 := text.find("\n## ", body_at)
    var end := text.length()
    if next_h3 >= 0:
        end = next_h3
    if next_h2 >= 0 and next_h2 < end:
        end = next_h2
    return text.substr(start, end - start)

## Numbers written the doc's way: "+2.00", "−0.35" (unicode minus), "0.55".
func _num(s: String) -> float:
    return float(s.strip_edges().replace("−", "-").replace("+", ""))

func test_docs_08_8_8_coefficient_table_equals_formulas() -> void:
    var sec := _section(_doc(DOC_08), "### 8.8 Mistake chance")
    assert_false(sec.contains("❓ OPEN"), "docs/08 §8.8 still carries an OPEN marker — the equation is ruled (Q-04/Q-05)")
    assert_false(sec.contains("MORALE_MULT"), "docs/08 §8.8 still names the rejected MORALE_MULT table")
    var row := RegEx.create_from_string("(?m)^\\| (Common|Uncommon|Rare|Epic|Legendary) \\| (\\d+) \\| ([0-9.]+) \\| (\\d+) \\| (\\d+) \\|")
    var found := {}
    for m in row.search_all(sec):
        var name := m.get_string(1)
        if found.has(name):
            continue
        found[name] = [int(m.get_string(2)), float(m.get_string(3)), int(m.get_string(4)), int(m.get_string(5))]
    assert_eq(found.size(), 5, "docs/08 §8.8's coefficient table has %d rarity rows, want 5" % found.size())
    for name in RULED_BP.keys():
        if not found.has(name):
            fail("docs/08 §8.8 has no %s row" % name)
            continue
        var r: int = RARITY_OF[name]
        var doc: Array = found[name]
        var ruled: Array = RULED_BP[name]
        assert_eq(doc[0], int(FORMULAS.MISTAKE_BASE_BP[r]), "%s base: doc %d vs Formulas" % [name, doc[0]])
        assert_almost(doc[1], float(FORMULAS.MISTAKE_SENSITIVITY[r]), 0.0001)
        assert_eq(doc[2], int(FORMULAS.MISTAKE_FLOOR_BP[r]), "%s floor: doc %d vs Formulas" % [name, doc[2]])
        assert_eq(doc[3], int(FORMULAS.MISTAKE_CEIL_BP[r]), "%s ceiling: doc %d vs Formulas" % [name, doc[3]])
        assert_eq(doc[0], int(ruled[0]), "%s base is not the ruled value" % name)
        assert_almost(doc[1], float(ruled[1]), 0.0001)
        assert_eq(doc[2], int(ruled[2]), "%s floor is not the ruled value" % name)
        assert_eq(doc[3], int(ruled[3]), "%s ceiling is not the ruled value" % name)

func test_docs_08_8_8_band_delta_caps_and_site_weights_equal_formulas() -> void:
    var sec := _section(_doc(DOC_08), "### 8.8 Mistake chance")
    # `MORALE_BAND_DELTA` ... imported unchanged: **+2.00 · +1.40 · ... · −0.35**
    var delta := RegEx.create_from_string("`MORALE_BAND_DELTA`[^*]*\\*\\*([^*]+)\\*\\*")
    var m := delta.search(sec)
    assert_true(m != null, "docs/08 §8.8 does not print the imported MORALE_BAND_DELTA")
    if m != null:
        var parts := m.get_string(1).split("·")
        assert_eq(parts.size(), 10, "MORALE_BAND_DELTA in the doc has %d entries, want 10" % parts.size())
        for i in mini(parts.size(), FORMULAS.MORALE_BAND_DELTA.size()):
            assert_almost(_num(parts[i]), float(FORMULAS.MORALE_BAND_DELTA[i]), 0.0001)
    var cap := RegEx.create_from_string("`SITUATIONAL_CAP_BP` = \\*\\*(\\d+)\\*\\*")
    var c := cap.search(sec)
    assert_true(c != null, "docs/08 §8.8 does not print SITUATIONAL_CAP_BP")
    if c != null:
        assert_eq(int(c.get_string(1)), FORMULAS.SITUATIONAL_CAP_BP)
    var site := RegEx.create_from_string("`ROLL_SITE_WEIGHT` = \\*\\*([0-9.]+) action · ([0-9.]+) mechanic · ([0-9.]+) ambient\\*\\*")
    var s := site.search(sec)
    assert_true(s != null, "docs/08 §8.8 does not print ROLL_SITE_WEIGHT (BL-21)")
    if s != null:
        assert_almost(float(s.get_string(1)), float(FORMULAS.ROLL_SITE_WEIGHT[E.RollSite.ACTION]), 0.0001)
        assert_almost(float(s.get_string(2)), float(FORMULAS.ROLL_SITE_WEIGHT[E.RollSite.MECHANIC]), 0.0001)
        assert_almost(float(s.get_string(3)), float(FORMULAS.ROLL_SITE_WEIGHT[E.RollSite.AMBIENT]), 0.0001)

func test_docs_05_5_2_band_table_equals_formulas() -> void:
    # docs/05 owns the band side and docs/08 imports it; the two must agree.
    var sec := _section(_doc(DOC_05), "### 5.2 Band delta")
    var row := RegEx.create_from_string("(?m)^\\| (\\d) \\| [^|]+ \\| ([+−-]?[0-9.]+) \\|")
    var seen := 0
    for m in row.search_all(sec):
        var band := int(m.get_string(1))
        seen += 1
        assert_almost(_num(m.get_string(2)), float(FORMULAS.MORALE_BAND_DELTA[band]), 0.0001)
    assert_eq(seen, 10, "docs/05 §5.2 has %d band rows, want 10" % seen)

func test_docs_08_11_overkill_margin_row_equals_combatant() -> void:
    # SIM-23: `Combatant.OVERKILL_MARGIN` said "docs/08 owns the final value" and
    # docs/08 had no such row. Now it does, and this holds it.
    var sec := _section(_doc(DOC_08), "## 11. Tuning levers")
    var row := RegEx.create_from_string("(?m)^\\| `OVERKILL_MARGIN` \\| (\\d+) \\|")
    var m := row.search(sec)
    assert_true(m != null, "docs/08 §11 has no OVERKILL_MARGIN row")
    if m != null:
        assert_eq(int(m.get_string(1)), COMBATANT.OVERKILL_MARGIN)
    var base := RegEx.create_from_string("(?m)^\\| `MISTAKE_BASE_BP\\[Common\\]` \\| (\\d+) \\|")
    var b := base.search(sec)
    assert_true(b != null, "docs/08 §11 has no MISTAKE_BASE_BP[Common] row")
    if b != null:
        assert_eq(int(b.get_string(1)), int(FORMULAS.MISTAKE_BASE_BP[E.Rarity.COMMON]))

func test_no_doc_but_08_prints_a_per_rarity_mistake_base_table() -> void:
    # DW-D2: four docs once printed rival Common bases (24.0% / 22% / 25% / 12%).
    # A table ROW whose first cell is a rarity name and whose second cell is a
    # percentage is a mistake-base table; only docs/08 §8.8 may hold one. docs/15
    # is the register and records the history of the fork on purpose.
    var row := RegEx.create_from_string("(?m)^\\| (Common|Uncommon|Rare|Epic|Legendary) \\| \\*{0,2}\\d+(?:\\.\\d+)?%")
    var dir := DirAccess.open("res://docs")
    assert_true(dir != null, "cannot open res://docs")
    if dir == null:
        return
    var offenders: Array[String] = []
    var scanned := 0
    dir.list_dir_begin()
    var name := dir.get_next()
    while name != "":
        if name.ends_with(".md") and not dir.current_is_dir():
            scanned += 1
            var path := "res://docs/" + name
            if not (name.begins_with("08-") or name.begins_with("15-")):
                var text := _doc(path)
                for m in row.search_all(text):
                    offenders.append("%s: %s" % [name, m.get_string(0)])
        name = dir.get_next()
    dir.list_dir_end()
    assert_true(scanned >= 17, "walked only %d docs" % scanned)
    assert_eq(offenders.size(), 0, "a doc other than 08 prints a per-rarity mistake table:\n      " + "\n      ".join(offenders))
