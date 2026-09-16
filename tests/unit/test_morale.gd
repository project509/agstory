extends "res://tests/TestCase.gd"
## Morale baselines, rarity resilience and the canon band readout.

const Morale = preload("res://sim/core/Morale.gd")
const Enums = preload("res://sim/model/Enums.gd")

# ---------------------------------------------------------------- canon rows

func test_the_canon_example_roster_reproduces_exactly() -> void:
    # Canon prints four raiders with their morale, face and state. This is the
    # single most quotable thing in the design notes, and every one of the four
    # must come out of the implementation unchanged:
    #
    #   Natsuna — 87 ❤️ / Shaman — Very Happy
    #   Bob     — 54 🙂 / Warrior — Content
    #   Greg    — 31 😒 / Rogue — Annoyed
    #   Steve   — 14 😡 / Mage — Upset
    var rows := [
        {"morale": 87, "state": "Very Happy", "face": "❤"},
        {"morale": 54, "state": "Content", "face": "🙂"},
        {"morale": 31, "state": "Annoyed", "face": "😒"},
        {"morale": 14, "state": "Upset", "face": "😡"},
    ]
    for row in rows:
        var m := int(row["morale"])
        assert_eq(Morale.band_name(m), String(row["state"]),
            "canon roster: %d must read as %s" % [m, row["state"]])
        assert_eq(Morale.face(m), String(row["face"]),
            "canon roster: %d must show %s" % [m, row["face"]])

func test_bands_are_half_open_and_lower_inclusive() -> void:
    # docs/15 Q-06: band_index = min(9, floor(morale / 10)). Every tens value
    # belongs to the band it opens, never the one it closes.
    for tens in range(0, 10):
        var v := tens * 10
        assert_eq(Morale.band(v), tens, "%d opens band %d" % [v, tens])
        if tens > 0:
            assert_eq(Morale.band(v - 1), tens - 1,
                "%d still closes band %d" % [v - 1, tens - 1])

func test_the_top_band_is_closed_and_includes_100() -> void:
    assert_eq(Morale.band(100), 9)
    assert_eq(Morale.band_name(100), "Loves Their Guild")

func test_ten_bands_carry_ten_distinct_names() -> void:
    # Canon names bands 7 and 8 both "Very Happy"; docs/15 Q-07 renamed 70-80
    # to "Quite Happy". A duplicate name cannot be sorted, logged or saved.
    var seen := {}
    for n in Enums.MORALE_BAND_NAMES:
        assert_false(seen.has(n), "duplicate band name '%s'" % n)
        seen[n] = true
    assert_eq(Enums.MORALE_BAND_NAMES.size(), 10)
    assert_eq(Enums.MORALE_BAND_EMOJI.size(), 10, "one face per band")
    var faces := {}
    for f in Enums.MORALE_BAND_EMOJI:
        assert_false(faces.has(f), "duplicate face '%s' — the ramp must read" % f)
        faces[f] = true

func test_band_eight_stays_very_happy_because_natsuna_is_87() -> void:
    # docs/05 §3.1: 80-90 is locked by canon's own example. If the rename had
    # gone the other way, the canon roster row would be wrong.
    assert_eq(Morale.band_name(87), "Very Happy")
    assert_eq(Morale.band_name(75), "Quite Happy")

# ---------------------------------------------------------------- baselines

func test_baselines_match_the_documented_table() -> void:
    # docs/05 §8: Common 45, Uncommon 48, Rare 50, Epic 54, Legendary 62.
    var expected := [45, 48, 50, 54, 62]
    for rarity in Enums.all_rarities():
        assert_eq(Morale.baseline_for(rarity), expected[rarity],
            "%s baseline" % Enums.rarity_key(rarity))

func test_a_recruit_arrives_at_their_baseline_not_at_fifty() -> void:
    # docs/05: "a Common walks in at 45, a Legendary at 62" — this is what
    # makes rarity legible the moment a recruit appears.
    assert_eq(Morale.starting_morale(Enums.Rarity.COMMON), 45)
    assert_eq(Morale.starting_morale(Enums.Rarity.LEGENDARY), 62)

func test_a_common_starts_slightly_annoyed() -> void:
    # 45 is band 4. The opening roster is unhappy before anything goes wrong,
    # which is the correct first note for this game.
    assert_eq(Morale.band_name(Morale.starting_morale(Enums.Rarity.COMMON)),
        "Slightly Annoyed")

func test_facility_upgrades_raise_the_baseline() -> void:
    # ✅ CANON: "Upgrade guild facilities < better morale values" — docs/05 §7.5
    # models this as a standing baseline shift, not a one-off spike.
    assert_eq(Morale.baseline_for(Enums.Rarity.COMMON, 6), 51)

# ---------------------------------------------------------------- resilience

func test_one_wipe_from_baseline_matches_the_worked_table() -> void:
    # docs/05 §8's worked comparison, -8 raw from each rarity's own baseline.
    # This single test pins the whole resilience model to canon's claim that
    # "legendary raiders will not be bothered by many things easily".
    var expected := [34.2, 38.8, 42.0, 48.4, 58.8]
    var bands := [3, 3, 4, 4, 5]
    for rarity in Enums.all_rarities():
        var start := float(Morale.baseline_for(rarity))
        var after := Morale.apply_delta(start, rarity, -8.0)
        assert_almost(after, expected[rarity], 0.05,
            "%s after one wipe" % Enums.rarity_key(rarity))
        assert_eq(Morale.band(int(after)), bands[rarity],
            "%s band after one wipe" % Enums.rarity_key(rarity))

func test_a_common_takes_a_wipe_far_harder_than_a_legendary() -> void:
    var common := absf(Morale.scale_delta(Enums.Rarity.COMMON, -10.0))
    var legendary := absf(Morale.scale_delta(Enums.Rarity.LEGENDARY, -10.0))
    assert_true(common > legendary * 3.0,
        "canon: lower tiers are hardest to keep happy (%.1f vs %.1f)"
        % [common, legendary])

func test_positives_land_softer_on_low_rarities_than_negatives() -> void:
    # The asymmetry is the mechanism behind "hardest to keep happy": a Common
    # loses more than it gains from the same sized event.
    for rarity in [Enums.Rarity.COMMON, Enums.Rarity.UNCOMMON]:
        assert_true(absf(Morale.scale_delta(rarity, -10.0))
            > Morale.scale_delta(rarity, 10.0))

func test_morale_is_clamped_at_both_ends() -> void:
    assert_eq(Morale.apply_delta(2.0, Enums.Rarity.COMMON, -100.0), 0.0)
    assert_eq(Morale.apply_delta(98.0, Enums.Rarity.LEGENDARY, 100.0), 100.0)

# ---------------------------------------------------------------- drift

func test_drift_moves_toward_the_baseline_from_both_sides() -> void:
    var below := Morale.drift(30.0, Enums.Rarity.RARE)
    assert_true(below > 30.0 and below <= 50.0)
    var above := Morale.drift(70.0, Enums.Rarity.RARE)
    assert_true(above < 70.0 and above >= 50.0)

func test_drift_never_overshoots_the_baseline() -> void:
    # A raider 0.4 below baseline must land exactly on it, not bounce past.
    assert_almost(Morale.drift(49.6, Enums.Rarity.RARE), 50.0)
    assert_almost(Morale.drift(50.4, Enums.Rarity.RARE), 50.0)
    assert_almost(Morale.drift(50.0, Enums.Rarity.RARE), 50.0)

func test_recovery_times_match_the_worked_table() -> void:
    # docs/05 §8 quotes ticks-to-baseline after one wipe: 10 / 7 / 6 / 4 / 2.
    var expected := [10, 7, 6, 4, 2]
    for rarity in Enums.all_rarities():
        var start := float(Morale.baseline_for(rarity))
        var after := Morale.apply_delta(start, rarity, -8.0)
        assert_eq(Morale.ticks_to_baseline(after, rarity), expected[rarity],
            "%s recovery" % Enums.rarity_key(rarity))

func test_higher_rarities_recover_faster() -> void:
    var prev := 999
    for rarity in Enums.all_rarities():
        var t := Morale.ticks_to_baseline(20.0, rarity)
        assert_true(t <= prev, "recovery must not slow as rarity rises")
        prev = t

# ---------------------------------------------------------------- at risk

func test_at_risk_covers_exactly_the_bands_canon_warns_about() -> void:
    # docs/05 §2: 0-10 "may cause guild disband", 10-20 and 20-30 "may leave
    # guild". Band 3 explicitly "Won't leave".
    assert_true(Morale.is_at_risk(5))
    assert_true(Morale.is_at_risk(14), "canon's Steve at 14 is at risk")
    assert_true(Morale.is_at_risk(29))
    assert_false(Morale.is_at_risk(30), "band 3 won't leave")
    assert_false(Morale.is_at_risk(54))
