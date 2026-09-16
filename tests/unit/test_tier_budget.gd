extends "res://tests/TestCase.gd"
## docs/08 §9.6 — the Tiers 2-5 boss budget — read back and checked.
##
## §9.6 is GENERATED (`tools/gen_items.gd -- budget`), which makes it the one
## section of canon a build loop is allowed to write, and therefore the one that
## most needs a guard: a generated table nobody checks is a table that quietly
## stops meaning what its prose says.
##
## So this test reads the section out of the doc and asserts the three claims
## the prose makes about it:
##
##   1. Tier 1 in §9.6 reproduces the Tier 1 numbers §9.2 and §9.3 published by
##      hand. That is the whole argument that tiers 2-5 are the same curve
##      continued rather than a new one invented, and it is checked against the
##      OTHER section rather than against a copy of the same numbers.
##   2. The tank death clock holds at ~3.5 rounds for every raid boss — §9.3's
##      invariant, the reason the raw-swing column is a derivation.
##   3. Nothing inverts: HP, DPS and swing all rise across the twenty-five
##      bosses, so a later tier is never a softer fight than an earlier one.
##
## It also holds the arithmetic in `sim/content/TierScaling.gd` that produced
## them, so a change to the rules fails here before it reaches a data file.

const TierScaling = preload("res://sim/content/TierScaling.gd")
const Formulas = preload("res://sim/core/Formulas.gd")

const DOC := "res://docs/08-stats-and-formulas.md"

## §9.2 and §9.3's hand-published Tier 1 rows, transcribed here ONCE so the test
## can compare two independent statements of the same five fights.
const T1_BOSS_HP := [2200, 2500, 3200, 4100, 7150]
const T1_RAW_SWING := [61, 63, 65, 68, 73]


func _doc() -> String:
    return FileAccess.get_file_as_string(DOC)


## Every "| Boss n | …" row under a "#### Tier n raid" heading in §9.6.
func _raid_rows() -> Dictionary:
    var out := {}
    var tier := 0
    var in_96 := false
    # The docs are CRLF on this checkout, so a raw split leaves a trailing \r
    # and every `ends_with` below would silently never match.
    for raw_line in _doc().split("\n"):
        var line := raw_line.strip_edges()
        if line.begins_with("### 9.6"):
            in_96 = true
            continue
        if in_96 and line.begins_with("## 10"):
            break
        if not in_96:
            continue
        if line.begins_with("#### Tier ") and line.ends_with(" raid"):
            tier = int(line.replace("#### Tier ", "").replace(" raid", ""))
            out[tier] = []
            continue
        if tier > 0 and line.begins_with("| Boss "):
            var cells: Array = []
            for c in line.split("|"):
                var t := c.strip_edges().replace("**", "")
                if not t.is_empty():
                    cells.append(t)
            # The table's own header row also starts "| Boss " — its second cell
            # is the words "Raid DPS at attempt" rather than a number.
            if cells.size() > 1 and String(cells[1]).is_valid_float():
                out[tier].append(cells)
    return out


func test_the_section_is_there_and_is_five_tiers_of_five_bosses() -> void:
    var rows := _raid_rows()
    assert_eq(rows.size(), 5, "expected five raid tiers in §9.6")
    for tier in rows:
        assert_eq(rows[tier].size(), 5, "tier %d should have five bosses" % tier)


func test_tier_1_in_96_reproduces_the_numbers_92_and_93_published_by_hand() -> void:
    # THE claim of the section. Columns: Boss | DPS | Rounds | HP | TankAC |
    # TankHP | Mit | Raw | Clock | Cloth | AoE | AoEgross
    var rows: Array = _raid_rows()[1]
    var wrong: Array[String] = []
    for i in rows.size():
        var hp := int(rows[i][3])
        var raw := int(rows[i][7])
        if hp != T1_BOSS_HP[i]:
            wrong.append("Boss %d HP: §9.6 says %d, §9.2 says %d" % [i + 1, hp, T1_BOSS_HP[i]])
        if raw != T1_RAW_SWING[i]:
            wrong.append("Boss %d swing: §9.6 says %d, §9.3 says %d" % [i + 1, raw, T1_RAW_SWING[i]])
    assert_eq(wrong.size(), 0,
        "§9.6's method no longer reproduces canon's own tier:\n      " + "\n      ".join(wrong))


func test_the_tank_death_clock_holds_across_every_raid_boss() -> void:
    # §9.3's invariant: the swing is solved so an unhealed tank dies in the same
    # number of rounds at every tier. If this drifts, a later tier is a
    # different game rather than a bigger one.
    var rows := _raid_rows()
    var bad: Array[String] = []
    for tier in rows:
        for r in rows[tier]:
            var clock := float(r[8])
            if absf(clock - 3.5) > 0.06:
                bad.append("T%s %s: clock %.2f" % [tier, r[0], clock])
    assert_eq(bad.size(), 0, "the death clock moved:\n      " + "\n      ".join(bad))


func test_no_tier_is_a_softer_fight_than_the_one_below_it() -> void:
    var rows := _raid_rows()
    var bad: Array[String] = []
    for tier in range(2, 6):
        for i in 5:
            var here: Array = rows[tier][i]
            var below: Array = rows[tier - 1][i]
            for col in [[3, "HP"], [1, "raid DPS"], [7, "swing"]]:
                var a := float(here[int(col[0])])
                var b := float(below[int(col[0])])
                if a <= b:
                    bad.append("T%d Boss %d %s: %s is not above T%d's %s" % [
                        tier, i + 1, col[1], here[int(col[0])], tier - 1, below[int(col[0])]])
    assert_eq(bad.size(), 0, "the ladder inverts:\n      " + "\n      ".join(bad))


func test_the_mitigation_cap_binds_exactly_where_the_prose_says() -> void:
    # The prose claims the cap binds from Tier 5 Boss 1. That is a real design
    # consequence — tank AC stops buying survivability — so it is asserted
    # rather than left as a sentence somebody might not re-check.
    var rows := _raid_rows()
    var cap := Formulas.MITIGATION_CAP * 100.0
    for i in 5:
        var mit := float(String(rows[5][i][6]).replace("%", ""))
        assert_almost(mit, cap, 0.06, "Tier 5 Boss %d should sit on the cap" % [i + 1])
    var t4 := float(String(rows[4][0][6]).replace("%", ""))
    assert_true(t4 < cap - 0.5, "Tier 4 Boss 1 should still be below the cap, not on it")


## ------------------------------------------------- the rules behind the table

func test_boss_hp_is_dps_times_rounds_rounded_to_the_docs_step() -> void:
    # §9.2's method, held directly: HP is the party's own damage over the target
    # round count, rounded — not a number somebody liked the look of.
    assert_eq(TierScaling.boss_hp(182.3, 12), 2200, "Tier 1 Boss 1")
    assert_eq(TierScaling.boss_hp(325.0, 22), 7150, "Tier 1 Boss 5")


func test_the_swing_is_solved_from_the_clock_not_chosen() -> void:
    # §9.3 inverted: given a tank's HP and AC, the swing that kills them in
    # TANK_DEATH_CLOCK rounds. Tier 1 Boss 1's published 61 comes back out.
    assert_eq(TierScaling.boss_auto_raw(136, 17), 61, "Tier 1 Boss 1's tank channel")
    var clock := TierScaling.unhealed_clock(136, 17, 61)
    assert_almost(clock, 3.5, 0.06, "and the clock it was solved for")
