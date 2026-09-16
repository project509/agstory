extends "res://tests/TestCase.gd"
## Names and backstories (docs/04 §7, §8).
##
## docs/04 §7 states the premise these files exist to protect: "the joke is that this
## reads like a real guild roster, and canon's own examples — Bob, Greg, Steve — are
## aggressively ordinary. A fantasy name generator would kill the premise on sight." So
## the first assertion in this file is that canon's own three names are in the pool.
##
## The one that matters most is `test_no_steve_and_steev`. docs/04 §7's second collision
## rule is the subtle one — a roster may not hold both a name and a mangled form of it —
## and getting it wrong produces a roster that reads like a bug rather than a joke.

const NamePool = preload("res://sim/content/NamePool.gd")
const BackstoryPool = preload("res://sim/content/BackstoryPool.gd")
const Recruitment = preload("res://sim/core/Recruitment.gd")
const Raider = preload("res://sim/model/Raider.gd")
const Morale = preload("res://sim/core/Morale.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Rng = preload("res://sim/core/Rng.gd")

var _names = null
var _stories = null

func before_each() -> void:
    if _names == null:
        _names = NamePool.load_from()
    if _stories == null:
        _stories = BackstoryPool.load_from()

func _rng(seed_value: int = 99):
    return Rng.new(Rng.splitmix64_mix(seed_value))


# =============================================== docs/04 §7, the pool

func test_both_files_load_without_complaint() -> void:
    assert_eq(_names.errors, [], "names: %s" % str(_names.errors))
    assert_eq(_stories.errors, [], "backstories: %s" % str(_stories.errors))

func test_canons_own_three_raiders_are_in_the_pool() -> void:
    # ✅ CANON names Bob, Greg and Steve in the roster mock-up, and docs/04 §7.1 marks
    # them as the texture the whole pool imitates.
    for name in ["Bob", "Greg", "Steve"]:
        assert_true(_names.given.has(name), "%s must be drawable" % name)

func test_every_name_in_the_docs_sample_table_is_reachable() -> void:
    # docs/04 §7.1 prints forty outputs as proof of tone. Every shape-A entry in that
    # table has to be in the pool, or the samples are aspirational rather than real.
    for name in ["Dave", "Gary", "Terry", "Barry", "Kevin", "Doug", "Randy", "Neil",
            "Phil", "Dennis", "Marv", "Carl", "Wayne", "Deb", "Brenda", "Sharon",
            "Janice", "Ron"]:
        assert_true(_names.given.has(name), "%s is in the doc's table" % name)

func test_the_pool_is_given_names_only() -> void:
    # docs/04 §7's content-review gate: "given names only, no surnames, no full-name
    # pairs". A space in the pool means somebody added a person rather than a name.
    for name in _names.given:
        assert_false(String(name).contains(" "),
            "'%s' is a full name, which the review rules forbid" % String(name))
        assert_true(String(name).length() >= 2)

func test_the_epithet_list_stays_short_enough_to_be_a_running_gag() -> void:
    # docs/04 §7: "Shape C epithet list stays short (~20 entries) so it reads as a
    # running gag, not a generator."
    assert_in_range(float(_names.epithets.size()), 12.0, 26.0,
        "%d epithets" % _names.epithets.size())

func test_the_shape_weights_are_the_documented_ones() -> void:
    # docs/04 §7: A 62%, B 26%, C 12%.
    assert_eq(_names.shape_weights, [620, 260, 120])
    var total := 0
    for w in _names.shape_weights:
        total += int(w)
    assert_eq(total, 1000)


# =============================================== docs/04 §7's shapes

func test_the_generator_mostly_produces_plain_mundane_names() -> void:
    # 62% of the time the answer is just "Greg", which is the whole joke.
    var rng = _rng(7)
    var bare := 0
    var runs := 2000
    for i in runs:
        var name: String = _names.pick(rng, [])
        if _names.given.has(name):
            bare += 1
    var rate := float(bare) / float(runs)
    assert_in_range(rate, 0.55, 0.70, "bare rate %.3f" % rate)

func test_every_generated_name_traces_back_to_a_mundane_root() -> void:
    # If a name cannot be traced home, the collision rules cannot work either.
    var rng = _rng(13)
    for i in 400:
        var name: String = _names.pick(rng, [])
        assert_true(_names.given.has(_names.root_of(name)),
            "'%s' has no mundane root (got '%s')" % [name, _names.root_of(name)])

func test_no_steve_and_steev() -> void:
    # docs/04 §7: "Never generate a shape-B or shape-C form of a name already live in
    # the roster (no `Steve` **and** `Steev`)." The roster reads as a bug otherwise.
    var rng = _rng(21)
    var roster: Array = ["Steve", "Bob", "Gary"]
    for i in 300:
        var name: String = _names.pick(rng, roster)
        var root: String = _names.root_of(name)
        assert_false(root in ["Steve", "Bob", "Gary"],
            "'%s' collides with a live raider through root '%s'" % [name, root])

func test_a_full_pool_still_returns_something_usable() -> void:
    # Twenty raiders and thirty-six names is a state a real save reaches. docs/04 §7's
    # last resort is a numeric suffix, and it must not loop forever getting there.
    var rng = _rng(37)
    var everyone: Array = _names.given.duplicate()
    var name: String = _names.pick(rng, everyone)
    assert_false(name.is_empty())
    assert_false(everyone.has(name), "and it is not one already taken")

func test_the_mangles_read_like_the_documented_samples() -> void:
    # docs/04 §7.1's shape-B samples: Bobb, Steev, Kevin7, Dave_2, Barry99, Randee.
    var rng = _rng(3)
    var seen_digit := false
    var seen_letters := false
    for i in 400:
        var mangled: String = _names._mangle(rng, "Steve")
        assert_true(mangled.begins_with("Stev") or mangled.begins_with("Steev")
            or mangled.begins_with("Steve"),
            "'%s' should still read as Steve" % mangled)
        if mangled != "Steve" and mangled[-1].is_valid_int():
            seen_digit = true
        elif mangled != "Steve":
            seen_letters = true
    assert_true(seen_digit, "the digit mangles must fire")
    assert_true(seen_letters, "and so must the letter ones")

func test_an_epithet_lands_on_the_side_its_form_says() -> void:
    # docs/04 §7.1 uses all three forms: "Gary Bloodfang", "Phil the Bold", "Big Ron".
    var rng = _rng(5)
    var prefixes := 0
    var suffixes := 0
    for i in 300:
        var name: String = _names._with_epithet(rng, "Gary")
        if name.begins_with("Gary "):
            suffixes += 1
        elif name.ends_with(" Gary"):
            prefixes += 1
    assert_true(suffixes > 0 and prefixes > 0,
        "both forms must appear: %d suffix, %d prefix" % [suffixes, prefixes])


# =============================================== docs/04 §8, the tags

func test_all_eighteen_documented_tags_ship() -> void:
    # docs/04 §8.3's table, by name. A missing one is a morale hook that silently
    # never fires.
    for tag in ["hates_being_benched", "only_here_for_loot", "worships_guild_leader",
            "scared_of_wipes", "unbothered_by_wipes", "class_rival", "needs_a_friend",
            "glory_hound", "chronically_late", "gear_snob", "gear_indifferent",
            "wants_to_tank", "superstitious", "homesick", "in_debt",
            "loves_the_tavern", "mentor", "blames_the_healers"]:
        assert_true(_stories.by_tag.has(tag), "%s is in docs/04 §8.3" % tag)
    assert_eq(_stories.tags.size(), 18)

func test_every_tag_says_what_it_listens_for() -> void:
    # docs/04 §8.3: "Every tag must be listenable, or it does not ship." Keeping the
    # doc's own column on the row is what lets a reader check the claim.
    for row in _stories.tags:
        assert_true(String(row["listens"]).length() > 0,
            "%s must name its event" % String(row["tag"]))

func test_every_tag_has_enough_variants_to_not_repeat_itself() -> void:
    # docs/04 §8.1: "Written per-tag with 3-6 variants for variety."
    for row in _stories.tags:
        assert_in_range(float((row["variants"] as Array).size()), 3.0, 6.0,
            "%s has %d variants" % [String(row["tag"]),
                (row["variants"] as Array).size()])

func test_the_weights_are_the_documented_three() -> void:
    # docs/04 §8.1: "0.5 / 1.0 / 1.5".
    for row in _stories.tags:
        assert_true(float(row["weight"]) in [0.5, 1.0, 1.5],
            "%s has weight %s" % [String(row["tag"]), str(row["weight"])])


# =============================================== docs/04 §8.1's draw rules

func test_a_raider_never_carries_the_same_tag_twice() -> void:
    var rng = _rng(41)
    for rarity in Enums.all_rarities():
        for i in 60:
            var seen := {}
            for b in _stories.draw(rng, rarity, Enums.CharClass.WARRIOR):
                var base := String(b["tag"]).get_slice(":", 0)
                assert_false(seen.has(base), "%s drawn twice" % base)
                seen[base] = true

func test_the_exclusion_graph_holds() -> void:
    # docs/04 §8.1 names two pairs; the file adds the two its own table creates.
    var rng = _rng(43)
    for i in 400:
        var drawn := {}
        for b in _stories.draw(rng, Enums.Rarity.RARE, Enums.CharClass.MAGE):
            drawn[String(b["tag"]).get_slice(":", 0)] = true
        for pair in _stories.exclusions:
            assert_false(drawn.has(String(pair[0])) and drawn.has(String(pair[1])),
                "%s and %s cannot co-occur" % [String(pair[0]), String(pair[1])])

func test_a_common_always_has_something_to_be_unhappy_about() -> void:
    # docs/04 §8.1: "Commons must include at least one `negative` bullet — canon: 'Lower
    # tier raiders will be hardest to keep happy'."
    var rng = _rng(47)
    for i in 300:
        var bullets: Array = _stories.draw(rng, Enums.Rarity.COMMON, Enums.CharClass.ROGUE)
        var negatives := 0
        for b in bullets:
            if String(b["polarity"]) == BackstoryPool.NEGATIVE:
                negatives += 1
        assert_true(negatives >= 1, "a Common drew nothing negative: %s" % str(bullets))

func test_an_epic_carries_at_most_one_complaint() -> void:
    # docs/04 §8.1: "Epics and above draw at most one `negative` bullet."
    var rng = _rng(53)
    for rarity in [Enums.Rarity.EPIC, Enums.Rarity.LEGENDARY]:
        for i in 300:
            var negatives := 0
            for b in _stories.draw(rng, rarity, Enums.CharClass.CLERIC):
                if String(b["polarity"]) == BackstoryPool.NEGATIVE:
                    negatives += 1
            assert_true(negatives <= 1,
                "%s drew %d negatives" % [Enums.rarity_name_of(rarity), negatives])

func test_the_bullet_count_matches_the_rarity() -> void:
    # docs/04 §6.2's column: 2 for a Common, 2-3 in the middle, 2-4 for a Legendary.
    var rng = _rng(59)
    for i in 100:
        assert_eq(_stories.draw(rng, Enums.Rarity.COMMON,
            Enums.CharClass.WARRIOR).size(), 2)
        assert_in_range(float(_stories.draw(rng, Enums.Rarity.RARE,
            Enums.CharClass.WARRIOR).size()), 2.0, 3.0)
        assert_in_range(float(_stories.draw(rng, Enums.Rarity.LEGENDARY,
            Enums.CharClass.WARRIOR).size()), 2.0, 4.0)

func test_nobody_is_their_own_class_rival() -> void:
    # docs/04 §8.3 tag 6 is parameterised. A Rogue who refuses to speak to Rogues is a
    # different joke, and not this one.
    var rng = _rng(61)
    for cls in Enums.all_classes():
        for i in 80:
            for b in _stories.draw(rng, Enums.Rarity.RARE, int(cls)):
                if not String(b["tag"]).begins_with("class_rival"):
                    continue
                assert_ne(String(b["tag"]),
                    "class_rival:%s" % Enums.class_key(int(cls)),
                    "%s is their own rival" % Enums.class_name_of(int(cls)))
                assert_false(String(b["text"]).contains("{class}"),
                    "the placeholder must be bound: %s" % String(b["text"]))


# =============================================== docs/05 §7.5's two hooks

func test_the_offset_lands_inside_doc_05s_range() -> void:
    # docs/05 §7.5: "a `backstory_offset` in the range -8..+8 on baseline".
    var rng = _rng(67)
    for rarity in Enums.all_rarities():
        for i in 200:
            var offset := BackstoryPool.offset_for(
                _stories.draw(rng, rarity, Enums.CharClass.DRUID))
            assert_in_range(float(offset), -8.0, 8.0, "offset %d" % offset)

func test_a_grim_backstory_reads_negative_and_a_cheerful_one_positive() -> void:
    var grim := [
        {"polarity": BackstoryPool.NEGATIVE, "weight": 1.5},
        {"polarity": BackstoryPool.NEGATIVE, "weight": 1.5},
    ]
    var sunny := [
        {"polarity": BackstoryPool.POSITIVE, "weight": 1.5},
        {"polarity": BackstoryPool.POSITIVE, "weight": 1.5},
    ]
    assert_true(BackstoryPool.offset_for(grim) < 0)
    assert_true(BackstoryPool.offset_for(sunny) > 0)
    assert_eq(BackstoryPool.offset_for([]), 0, "no past, no shift")

func test_a_mixed_bullet_moves_the_baseline_by_nothing() -> void:
    # A mixed tag earns its morale through its trigger, not by shifting where the raider
    # settles — otherwise `only_here_for_loot` would be a flat penalty for existing.
    assert_eq(BackstoryPool.offset_for(
        [{"polarity": BackstoryPool.MIXED, "weight": 1.5}]), 0)

func test_the_extreme_backstory_reaches_the_documented_limit() -> void:
    # The scale is derived from the extreme rather than picked, so the top of docs/05's
    # range has to be actually reachable.
    var maxed: Array = []
    for i in BackstoryPool.MAX_BULLETS:
        maxed.append({"polarity": BackstoryPool.POSITIVE,
            "weight": BackstoryPool.MAX_WEIGHT})
    assert_eq(BackstoryPool.offset_for(maxed), 8)

func test_a_tag_scales_the_trigger_it_listens_for() -> void:
    # docs/05 §7.5's other hook: "named trigger tags that multiply a §7 delta by 1.5x or
    # 0.5x". docs/04 §8.3's "Listens for" column says which.
    var scared = Raider.new()
    scared.backstory = [{"tag": "scared_of_wipes", "polarity": "negative",
        "weight": 1.5}]
    assert_almost(BackstoryPool.tag_scale(scared, "wipe"), Morale.TAG_AMPLIFY, 0.0001)
    assert_almost(BackstoryPool.tag_scale(scared, "cleared"), 1.0, 0.0001,
        "and it says nothing about winning")

    var calm = Raider.new()
    calm.backstory = [{"tag": "unbothered_by_wipes", "polarity": "positive",
        "weight": 1.0}]
    assert_almost(BackstoryPool.tag_scale(calm, "wipe"), Morale.TAG_DAMPEN, 0.0001)

    assert_almost(BackstoryPool.tag_scale(null, "wipe"), 1.0, 0.0001)
    assert_almost(BackstoryPool.tag_scale(Raider.new(), "wipe"), 1.0, 0.0001,
        "a raider with no past has no opinion")


# =============================================== plugged into the generator

func test_a_recruit_now_arrives_named_and_written() -> void:
    var rng = _rng(71)
    var who = Recruitment.generate(rng, Enums.ReputationRank.KNOWN, 1, {
        "name_pool": _names, "backstory_pool": _stories,
    })
    assert_false(who.display_name.contains("name pending"),
        "the pool must have supplied a name: %s" % who.display_name)
    assert_true(_names.given.has(_names.root_of(who.display_name)))
    assert_true(who.backstory.size() >= 2, "and a past")

func test_the_backstory_moves_where_the_recruit_settles() -> void:
    # docs/04 §5 step 8 is explicit about the order: "backstory must be drawn first: the
    # bullets supply doc 05's `backstory_offset`", and morale is the baseline including
    # that offset. Getting the order wrong gives every recruit the same morale.
    var offsets := {}
    for seed_value in range(1, 60):
        var who = Recruitment.generate(_rng(seed_value),
            Enums.ReputationRank.KNOWN, 1,
            {"name_pool": _names, "backstory_pool": _stories})
        assert_eq(who.morale, Morale.baseline_of(who, 0),
            "%s must start at their own baseline" % who.display_name)
        offsets[who.backstory_offset] = true
    assert_true(offsets.size() > 1,
        "different pasts must produce different baselines, saw %s" % str(offsets.keys()))

func test_a_board_of_recruits_holds_no_two_of_the_same_name() -> void:
    # docs/04 §7: "Never two live raiders with the same `display_name`."
    var rng = _rng(79)
    var taken: Array = []
    for i in 12:
        var who = Recruitment.generate(rng, Enums.ReputationRank.RESPECTED, 2, {
            "name_pool": _names, "backstory_pool": _stories, "taken_names": taken,
        })
        assert_false(taken.has(who.display_name),
            "'%s' was already on the roster" % who.display_name)
        taken.append(who.display_name)


# =============================================== one register (CONTENT-20)

func test_the_starting_roster_and_the_tavern_draw_from_the_same_register() -> void:
    # docs/04 §7 "Pool is data, not code": game/core/StartingRoster.gd carried a
    # second pool of twenty-four literals — names the Tavern could never offer,
    # twenty-two of them never through docs/15 BL-53's review. Every starter
    # who is not canon's Bob, Greg or Steve is rooted in data/names.json, and
    # the starters' stories come from data/backstories.json's tags.
    var StartingRoster = load("res://game/core/StartingRoster.gd")
    var DB = load("res://sim/content/ContentDB.gd")
    var db = DB.load_all()
    var tags := {}
    for row in _stories.tags:
        tags[String(row["tag"])] = true
    for r in StartingRoster.build(db, 2026, _names, _stories):
        var name := String(r.display_name)
        if name in ["Bob", "Greg", "Steve"]:
            continue
        assert_true(_names.given.has(_names.root_of(name)),
            "'%s' is not in the register" % name)
        for bullet in r.backstory:
            assert_true(tags.has(String(bullet["tag"]).get_slice(":", 0)),
                "'%s' carries a tag the file does not: %s" % [name, str(bullet)])
