extends "res://tests/TestCase.gd"
## The nine authored Legendaries (docs/04 §11, docs/03 §5.6).
##
## ✅ CANON (A9): "You can only ever find 1 Legendary per class - They are also named
## characters - IE Natsuna(the shaman) or something." Canon names exactly one of them and
## hedges even that, so the assertion that matters most here is
## `test_eight_of_the_nine_are_deliberately_unnamed` — docs/03 §5.6 says "Do not invent
## names", and a test that fails when somebody does is the only way that instruction
## survives contact with a content pass.
##
## The other load-bearing one is `test_a_legendary_cannot_be_neglected_into_leaving`.
## docs/04 §11.3 exists to make canon's "will not be bothered by many things easily …
## unless you are BIG dumb" implementable, and a floor that leaks is not a floor.

const LegendaryPool = preload("res://sim/content/LegendaryPool.gd")
const BackstoryPool = preload("res://sim/content/BackstoryPool.gd")
const Recruitment = preload("res://sim/core/Recruitment.gd")
const Morale = preload("res://sim/core/Morale.gd")
const Ledger = preload("res://sim/core/MoraleLedger.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Raider = preload("res://sim/model/Raider.gd")
const Rng = preload("res://sim/core/Rng.gd")
const Quirks = preload("res://sim/core/Quirks.gd")
const Scenarios = preload("res://tests/golden/Scenarios.gd")
const ContentDB = preload("res://sim/content/ContentDB.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")

var _legends = null
var _stories = null

func before_each() -> void:
    if _legends == null:
        _legends = LegendaryPool.load_from()
    if _stories == null:
        _stories = BackstoryPool.load_from()


func _rng(seed_value: int = 7):
    return Rng.new(Rng.splitmix64_mix(seed_value))


func _legendary(cls: int):
    var r = Raider.new()
    r.id = "leg_%d" % cls
    r.class_id = cls
    r.rarity = Enums.Rarity.LEGENDARY
    r.legendary_def_id = "legendary_%s" % Enums.class_key(cls)
    r.display_name = _legends.display_name(cls)
    r.backstory = _legends.backstory_of(cls)
    Morale.set_morale(r, 62.0)
    return r


# =============================================== the files

func test_all_nine_load_without_complaint() -> void:
    assert_eq(_legends.errors, [], "legendaries: %s" % str(_legends.errors))
    assert_eq(_legends.by_class.size(), 9, "one per canon class")

func test_there_is_exactly_one_per_class() -> void:
    # ✅ CANON A9. Two files claiming one class must be a load error, not a last-wins.
    for cls in Enums.all_classes():
        assert_true(_legends.has_definition(int(cls)),
            "%s has no Legendary" % Enums.class_name_of(int(cls)))
        assert_eq(String(_legends.definition(int(cls))["legendary_def_id"]),
            "legendary_%s" % Enums.class_key(int(cls)))

func test_natsuna_is_the_shaman_because_canon_says_so() -> void:
    # ✅ CANON A9's one example, and docs/05 §11.2 reads her again at 87 morale.
    assert_eq(_legends.display_name(Enums.CharClass.SHAMAN), "Natsuna")
    assert_true(_legends.is_named(Enums.CharClass.SHAMAN))

func test_eight_of_the_nine_are_deliberately_unnamed() -> void:
    # docs/03 §5.6: "The other 8 Legendary names — ❓ OPEN, naming pending. Use
    # placeholders `Legendary (Warrior) — name pending`. **Do not invent names.**"
    #
    # This test fails the moment somebody invents one, which is the point of it.
    var unnamed: Array = _legends.unnamed_classes()
    assert_eq(unnamed.size(), 8, "canon names one; the rest are the designer's call")
    assert_false(unnamed.has(Enums.CharClass.SHAMAN))
    for cls in unnamed:
        assert_eq(_legends.display_name(int(cls)),
            "Legendary (%s) — name pending" % Enums.class_name_of(int(cls)),
            "the placeholder must be docs/03 §5.6's own wording")

func test_nobody_walks_in_at_a_hardcoded_morale() -> void:
    # docs/04 §11.2: "Default is null, meaning the computed baseline per docs/05 §4/§7.5 —
    # not a fixed 75." Canon's Natsuna at 87 is a snapshot of a PLAYED roster, not an
    # arrival value, so no file sets an override (docs/15 BL-57).
    for cls in Enums.all_classes():
        assert_eq(_legends.starting_morale(int(cls)), -1,
            "%s must arrive at their baseline" % Enums.class_name_of(int(cls)))

func test_every_one_arrives_with_canons_few_raid_pieces() -> void:
    # ✅ CANON A8's "a few" pieces of current-tier raid gear, made exact by docs/04 §6.2's
    # 3-4.
    for cls in Enums.all_classes():
        var grant: Dictionary = _legends.gear_grant(int(cls))
        assert_eq(String(grant["source"]), "raid")
        assert_in_range(float(grant["pieces"]), 3.0, 4.0,
            "%s's grant" % Enums.class_name_of(int(cls)))

func test_every_one_has_a_voice_and_a_face_to_draw() -> void:
    # docs/04 §11.2's `dialogue_barks` are "the character's voice", and the portrait is
    # "hand-drawn, not pooled". The art does not exist, so the keys must at least be there
    # for it to land in.
    for cls in Enums.all_classes():
        assert_true(_legends.barks_of(int(cls)).size() >= 3,
            "%s needs lines" % Enums.class_name_of(int(cls)))
        var portrait: Dictionary = _legends.definition(int(cls))["portrait_set"]
        assert_true(String(portrait["full"]).length() > 0)
        assert_true(String(portrait["thumb"]).length() > 0)


# =============================================== docs/04 §11.3's rules

func test_every_subscription_names_a_tag_they_actually_carry() -> void:
    # docs/04 §11.3: "subscribed_tags: Only the tags in this Legendary's own backstory."
    # A subscription to a tag they do not have is a rule that can never fire, silently.
    for cls in Enums.all_classes():
        var own: Array = []
        for bullet in _legends.backstory_of(int(cls)):
            own.append(String(bullet["tag"]))
        for tag in _legends.morale_rules(int(cls)).get("subscribed_tags", []):
            assert_true(own.has(String(tag)),
                "%s subscribes to %s without carrying it"
                    % [Enums.class_name_of(int(cls)), String(tag)])

func test_every_tag_they_carry_is_one_the_game_can_actually_fire() -> void:
    # docs/04 §8.3: "Every tag must be listenable, or it does not ship." An authored
    # character carrying an invented tag would be a bullet that never does anything.
    for cls in Enums.all_classes():
        for bullet in _legends.backstory_of(int(cls)):
            var base := String(bullet["tag"]).get_slice(":", 0)
            assert_true(_stories.by_tag.has(base),
                "%s carries '%s', which is not in docs/04 §8.3"
                    % [Enums.class_name_of(int(cls)), base])

func test_nobody_carries_more_than_one_complaint() -> void:
    # docs/04 §8.1's cap applies to authored characters too: "Epics and above draw at most
    # one `negative` bullet."
    for cls in Enums.all_classes():
        var negatives := 0
        for bullet in _legends.backstory_of(int(cls)):
            if String(bullet["polarity"]) == "negative":
                negatives += 1
        assert_true(negatives <= 1,
            "%s carries %d" % [Enums.class_name_of(int(cls)), negatives])

func test_the_documented_multiplier_and_floor_are_the_ones_in_the_files() -> void:
    # docs/04 §11.3's table: 0.35 on negatives, 1.0 on positives, floor 40.
    assert_almost(Morale.LEGENDARY_NEG_MULT, 0.35, 0.0001)
    assert_eq(Morale.LEGENDARY_FLOOR, 40)
    for cls in Enums.all_classes():
        var rules: Dictionary = _legends.morale_rules(int(cls))
        assert_almost(float(rules["negative_multiplier"]), 0.35, 0.0001)
        assert_almost(float(rules["positive_multiplier"]), 1.0, 0.0001)
        assert_eq(int(rules["morale_floor"]), 40)

func test_an_event_no_bullet_listens_for_is_ignored_outright() -> void:
    # docs/04 §11.3: "All other events are ignored outright." This is the direct
    # expression of ✅ CANON A11 — "not bothered by many things easily".
    var shaman = _legendary(Enums.CharClass.SHAMAN)
    var ledger = Ledger.new()
    var before := Morale.morale_exact(shaman)
    # Natsuna's bullets are `unbothered_by_wipes` and `mentor`; nothing she carries
    # listens for a friend leaving.
    assert_almost(Morale.apply(shaman, "peer_left", ledger, "someone"), 0.0, 0.0001,
        "she does not notice")
    assert_almost(Morale.morale_exact(shaman), before, 0.0001)

func test_an_event_one_of_their_bullets_listens_for_does_reach_them() -> void:
    var shaman = _legendary(Enums.CharClass.SHAMAN)
    var ledger = Ledger.new()
    var before := Morale.morale_exact(shaman)
    # `unbothered_by_wipes` listens for a wipe, so a wipe reaches her — and, because that
    # tag DAMPENS, it reaches her softened twice over.
    var applied := Morale.apply(shaman, "wipe", ledger, "",
        BackstoryPool.tag_scale(shaman, "wipe"))
    assert_true(applied < 0.0, "a wipe still lands: %.3f" % applied)
    assert_true(Morale.morale_exact(shaman) < before)

func test_slow_to_anger_normal_to_please() -> void:
    # docs/04 §11.3's `delta_multiplier`: 0.35 on negative, 1.0 on positive. Compared
    # against an ordinary Legendary with no definition behind them, so the only difference
    # is §11.3 itself.
    var authored = _legendary(Enums.CharClass.WARRIOR)
    var plain = _legendary(Enums.CharClass.WARRIOR)
    plain.legendary_def_id = ""
    plain.id = "plain"
    Morale.set_morale(plain, 62.0)

    var a := Morale.apply(authored, "wipe", Ledger.new())
    var b := Morale.apply(plain, "wipe", Ledger.new())
    assert_true(absf(a) < absf(b),
        "the authored one must take it softer: %.3f vs %.3f" % [a, b])
    assert_almost(absf(a) / absf(b), 0.35, 0.02, "and by the documented factor")

func test_a_legendary_cannot_be_neglected_into_leaving() -> void:
    # docs/04 §11.3: the floor "guarantees they never drift into the leave/disband bands by
    # neglect", and canon's "may leave guild" band starts at 30. Hammered with every
    # negative trigger they DO listen for, forty times, with a fresh ledger each time so no
    # cooldown does the work.
    var warrior = _legendary(Enums.CharClass.WARRIOR)
    for i in 40:
        Morale.apply(warrior, "wipe", Ledger.new())
        Morale.apply(warrior, "knocked_out", Ledger.new())
    assert_true(Morale.morale_exact(warrior) >= float(Morale.LEGENDARY_FLOOR),
        "the floor held at %.2f" % Morale.morale_exact(warrior))
    assert_false(Morale.is_at_risk(warrior.morale),
        "and they are nowhere near canon's leave bands")

func test_being_big_dumb_suspends_the_floor() -> void:
    # ✅ CANON A11's escape hatch: "unless you are BIG dumb". A floor with no way through
    # it would make a Legendary unloseable, which canon does not say.
    var warrior = _legendary(Enums.CharClass.WARRIOR)
    warrior.big_dumb_active = true
    for i in 40:
        Morale.apply(warrior, "wipe", Ledger.new())
    assert_true(Morale.morale_exact(warrior) < float(Morale.LEGENDARY_FLOOR),
        "at %.2f, the floor is suspended" % Morale.morale_exact(warrior))

func test_the_rules_only_apply_to_an_authored_character() -> void:
    # A procedurally generated Legendary cannot exist — canon makes them authored — so the
    # definition id is what the rules key off.
    var plain = Raider.new()
    plain.id = "nobody"
    plain.rarity = Enums.Rarity.LEGENDARY
    assert_false(Morale.is_unbotherable(plain))
    plain.legendary_def_id = "legendary_warrior"
    assert_true(Morale.is_unbotherable(plain))
    assert_false(Morale.is_unbotherable(null))


# =============================================== the generator

func test_a_generated_legendary_is_the_authored_character() -> void:
    # docs/04 §5 step 3: "if Legendary, load the definition file and skip steps 4, 7 and 8;
    # the file supplies name, portrait, backstory, quirk."
    var who = Recruitment.generate(_rng(3), Enums.ReputationRank.LEGENDARY, 5, {
        "legendary_pool": _legends,
        "backstory_pool": _stories,
        "claimed_legendary_classes": [],
    })
    if who.rarity != Enums.Rarity.LEGENDARY:
        return   # the roll did not produce one this seed; the next test forces it
    assert_eq(who.display_name, _legends.display_name(who.class_id))
    assert_eq(who.backstory.size(), _legends.backstory_of(who.class_id).size())
    assert_false(who.legendary_def_id.is_empty())

func test_a_legendary_shaman_is_always_natsuna() -> void:
    # ✅ CANON A9 again, at the point it actually matters: whichever seed produces the
    # Shaman's Legendary, it is her.
    var claimed: Array = []
    for cls in Enums.all_classes():
        if int(cls) != Enums.CharClass.SHAMAN:
            claimed.append(cls)
    for seed_value in range(1, 12):
        var who = Recruitment.generate(_rng(seed_value),
            Enums.ReputationRank.LEGENDARY, 5, {
                "legendary_pool": _legends,
                "claimed_legendary_classes": claimed,
            })
        if who.rarity != Enums.Rarity.LEGENDARY:
            continue
        assert_eq(who.class_id, Enums.CharClass.SHAMAN,
            "only the Shaman's Legendary is unclaimed")
        assert_eq(who.display_name, "Natsuna")
        return

func test_a_generated_legendary_starts_at_their_baseline() -> void:
    # No file sets an override, so docs/05 §4's rule stands: "a newly recruited raider
    # starts at `baseline`, not at 50."
    var claimed: Array = []
    for cls in Enums.all_classes():
        if int(cls) != Enums.CharClass.WARRIOR:
            claimed.append(cls)
    for seed_value in range(1, 12):
        var who = Recruitment.generate(_rng(seed_value),
            Enums.ReputationRank.LEGENDARY, 5, {"legendary_pool": _legends,
                "claimed_legendary_classes": claimed})
        if who.rarity != Enums.Rarity.LEGENDARY:
            continue
        assert_eq(who.morale, Morale.baseline_of(who, 0))
        return


# =============================================== the quirk seam (Q58-4, W7-SIM-EFFECTS)

## The nine ids the seam dispatches on, by convention.
func _quirk_ids() -> Array:
    var out: Array = []
    for cls in Enums.all_classes():
        out.append(Quirks.expected_id_for(int(cls)))
    return out

func test_the_nine_quirk_ids_are_distinct_and_conventional() -> void:
    # `quirk_<class_key>`, one per class, and the authored files agree — that
    # convention is how RaidSim resolves a quirk from `legendary_def_id`
    # without carrying the pool.
    var seen := {}
    for cls in Enums.all_classes():
        var id := Quirks.expected_id_for(int(cls))
        assert_eq(id, "quirk_%s" % Enums.class_key(int(cls)))
        assert_false(seen.has(id), "%s is claimed twice" % id)
        seen[id] = true
        assert_eq(_legends.quirk_id_of(int(cls)), id,
            "%s's file carries the conventional id" % Enums.class_name_of(int(cls)))
    assert_eq(seen.size(), 9)

func test_every_hook_is_identity_for_every_quirk_at_either_flag_setting() -> void:
    # docs/15 BL-58's spec is a `SPECS` row; until one exists the seam may not
    # move a number even with the flag ON — a seam that could would move it
    # by accident.
    assert_eq(Quirks.SPECS, {}, "the spec pass lands rows here, not before BL-58")
    assert_eq(Quirks.HOOKS, ["threat_multiplier", "relief_bp_bonus", "tank_priority", "immune_to"])
    for id in _quirk_ids() + ["", "quirk_nobody"]:
        for enabled in [false, true]:
            assert_false(Quirks.is_live(String(id), enabled))
            assert_eq(Quirks.spec_of(String(id), enabled), {})
            assert_almost(Quirks.threat_multiplier(String(id), enabled), 1.0, 0.0001,
                "%s threat at %s" % [String(id), str(enabled)])
            assert_almost(Quirks.relief_bp_bonus(String(id), enabled), 0.0, 0.0001)
            assert_eq(Quirks.tank_priority(String(id), enabled), 0)
            for type_id in ["MIS_CHAIN_FIZZLE", "MIS_TAUNT_LAPSE", "MIS_AGGRO"]:
                assert_false(Quirks.immune_to(String(id), type_id, enabled))

func test_the_threaded_seam_leaves_the_legendary_golden_where_it_was() -> void:
    # The four hooks are called from RaidSim and Mistakes now (Q58-4's caller
    # half). The one golden that carries Legendaries is the ceiling case the
    # sweep reads, so it is the thing that must not have moved: the scenario
    # replays to the committed SHA with the flag off, with it on, and with the
    # roster marked as the nine authored characters at either setting.
    var db = ContentDB.load_all()
    var spec: Dictionary = Scenarios.SCENARIOS["e5_legendaries_raid"]
    var enc = db.encounter_at_slot(String(spec["encounter"]))
    var golden_path := Scenarios.golden_path("e5_legendaries_raid")
    assert_true(FileAccess.file_exists(golden_path))
    var golden: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(golden_path))
    var committed := String(golden["full_log_sha256"])
    var roster := Scenarios.build_roster(spec, db)
    var off = RaidSim.run(roster, enc, db, int(spec["seed"]), {}, {Quirks.FLAG_ID: false})
    var on = RaidSim.run(roster, enc, db, int(spec["seed"]), {}, {Quirks.FLAG_ID: true})
    assert_eq(off.log.to_json().sha256_text(), committed, "flag off: the golden SHA")
    assert_eq(on.log.to_json().sha256_text(), committed, "flag on: the golden SHA")
    for r in roster:
        r.legendary_def_id = "legendary_%s" % Enums.class_key(r.class_id)
    var authored_off = RaidSim.run(roster, enc, db, int(spec["seed"]), {}, {Quirks.FLAG_ID: false})
    var authored_on = RaidSim.run(roster, enc, db, int(spec["seed"]), {}, {Quirks.FLAG_ID: true})
    assert_eq(authored_off.log.to_json(), authored_on.log.to_json(),
        "the nine authored characters: the same fight at either flag setting")
    assert_eq(authored_on.outcome_key(), off.outcome_key())
    assert_eq(authored_on.rounds, off.rounds)
    assert_eq(authored_on.damage_dealt, off.damage_dealt)
    assert_eq(authored_on.healing_done, off.healing_done)
