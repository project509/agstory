extends "res://tests/TestCase.gd"
## Raid prep's arithmetic, and the full Board -> Prep -> Depart -> Results loop.

const RaidPlan = preload("res://game/core/RaidPlan.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const RouterScript = preload("res://game/core/ScreenRouter.gd")
const StartingRoster = preload("res://game/core/StartingRoster.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Raider = preload("res://sim/model/Raider.gd")
const Morale = preload("res://sim/core/Morale.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const Scenarios = preload("res://tests/golden/Scenarios.gd")

const BOARD := "res://game/screens/AdventureBoard.tscn"
const PREP := "res://game/screens/RaidPrep.tscn"
const RESULTS := "res://game/screens/Results.tscn"
const RAID_VIEW := "res://game/screens/RaidView.tscn"

var _db = null
var _made: Array = []

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _made = []

func after_each() -> void:
    # The GameState autoload outlives this file. Leaving content attached made
    # another file's empty-roster assertion depend on test ORDER, because
    # new_game() seeds a roster only when content is present.
    var st = _root().get_node_or_null("GameState") if _root() != null else null
    if st != null:
        st.reset()
        st.set_content(null)
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []

func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null

func _texts(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _texts(c, out)
    return out

func _joined(n: Node) -> String:
    return "\n".join(PackedStringArray(_texts(n)))

func _make(class_key: String, morale: int = 45, id_suffix: String = ""):
    var r = Raider.new()
    r.id = "t_%s%s" % [class_key, id_suffix]
    r.display_name = class_key.capitalize() + id_suffix
    r.class_id = Enums.class_from_key(class_key)
    r.rarity = Enums.Rarity.COMMON
    r.morale = morale
    return r

## docs/06 §6.5's worked example: the week-three raid where the tavern has
## produced no Cleric. W1 Mo1 Ro4 Cl0 Dr2 Sh1 Ma1 Wi1 Ba1 = 12.
func _week_three() -> Array:
    var out: Array = []
    var spec := {"warrior": 1, "monk": 1, "rogue": 4, "druid": 2,
                 "shaman": 1, "mage": 1, "wizard": 1, "bard": 1}
    for key in spec:
        for i in int(spec[key]):
            out.append(_make(key, 45, str(i)))
    return out

func _encounter():
    return _db.encounter_at_slot("E5")

# ---------------------------------------------------------------- comp, canon

func test_the_week_three_worked_example_reproduces_exactly() -> void:
    # docs/06 §6.5 spells this comp out and states its verdict. Tank weight is
    # 1.0 because the Monk "contributes 0 outside its emergency state" — it is
    # standing by to take over, not covering the slot.
    var comp := _week_three()
    assert_eq(comp.size(), Enums.RAID_SIZE, "the worked example fields twelve")
    var a := RaidPlan.analyse(comp, _db, _encounter())
    assert_almost(float(a["tank_weight"]), 1.0, 0.001,
        "only the Warrior counts; the Monk buys nothing before it dies")
    assert_eq(int(a["tanks_required"]), 2)
    assert_almost(float(a["tank_shortfall"]), 1.0, 0.001)
    assert_eq(int(a["tank_mistake_bp"]), 500,
        "docs/06 §6.5: +5 percentage points per full point of shortfall")
    assert_eq(int(a["healers"]), 3, "Druid x2 + Shaman = 3")
    assert_eq(int(a["healer_shortfall"]), 0, "3 meets the recommendation")
    assert_almost(float(a["healing_penalty"]), 0.0, 0.001,
        "no healing penalty — it is a comp SHAPE problem, not a violation")

func test_a_monk_never_counts_as_a_tank() -> void:
    var comp: Array = []
    for i in 12:
        comp.append(_make("monk", 45, str(i)))
    assert_almost(float(RaidPlan.tank_weight(comp, _db)), 0.0, 0.001)

func test_healing_penalty_is_25_percent_per_missing_healer() -> void:
    assert_almost(RaidPlan.healing_penalty(0), 0.00, 0.001)
    assert_almost(RaidPlan.healing_penalty(1), 0.25, 0.001)
    assert_almost(RaidPlan.healing_penalty(2), 0.50, 0.001)

func test_healing_penalty_caps_at_75_percent() -> void:
    # docs/06 §6.5 caps it, so a raid with no healers at all is crippled but not
    # mathematically unable to heal.
    assert_almost(RaidPlan.healing_penalty(3), 0.75, 0.001)
    assert_almost(RaidPlan.healing_penalty(9), 0.75, 0.001)

func test_underfilling_the_raid_adds_no_penalty_beyond_the_missing_bodies() -> void:
    # docs/06 §6.5: "No extra penalty. The missing bodies are the penalty."
    var comp := _week_three().slice(0, 8)
    var a := RaidPlan.analyse(comp, _db, _encounter())
    assert_eq(int(a["slots_missing"]), 4)
    assert_eq(int(a["slots_filled"]), 8)

# ---------------------------------------------------------------- gear

func test_gear_coverage_counts_visible_slots_not_seven_for_everyone() -> void:
    # docs/13 §10.2 / docs/09 §3.2: a Mage's off-hand is hidden, not empty.
    # Counting seven for everyone would mark every caster permanently short.
    var mage := [_make("mage")]
    var warrior := [_make("warrior")]
    assert_eq(int(RaidPlan.gear_coverage(mage, _db)["visible"]), 6,
        "Monk / Mage / Wizard have six visible slots")
    assert_eq(int(RaidPlan.gear_coverage(warrior, _db)["visible"]), 7)

func test_gear_totals_are_three_numbers_never_one_score() -> void:
    # docs/13 §10.2 rejects a single gear score outright: a Mage's Mana and a
    # Warrior's AC are not commensurable.
    var roster := StartingRoster.build(_db, 11)
    var totals := RaidPlan.gear_totals(roster, _db)
    for key in ["ac", "damage", "mana"]:
        assert_true(totals.has(key), "missing %s" % key)
    assert_true(int(totals["ac"]) > 0, "starting armour has AC")

# ---------------------------------------------------------------- risk

func test_the_baseline_is_the_same_comp_at_content() -> void:
    # docs/13 §10.3: "the same figure with every raider at band 5 Content. This
    # is what makes 4.6 mean something."
    var comp := _week_three()
    var content: Array = []
    for r in comp:
        content.append(_make(r.class_key(), RaidPlan.CONTENT_MORALE, r.id))
    var enc = _encounter()
    assert_almost(RaidPlan.baseline_mistakes(comp, enc),
        RaidPlan.expected_mistakes(content, enc), 0.01)

func test_misery_raises_expected_mistakes_above_the_baseline() -> void:
    var enc = _encounter()
    var sad: Array = []
    for i in 12:
        sad.append(_make("rogue", 5, str(i)))
    var a := RaidPlan.analyse(sad, _db, enc)
    assert_true(float(a["expected_mistakes"]) > float(a["baseline_mistakes"]),
        "a miserable raid must predict more mistakes than a content one")
    assert_eq(String(a["risk_word"]), "SEVERE")

func test_a_content_raid_reads_low() -> void:
    var enc = _encounter()
    var fine: Array = []
    for i in 12:
        fine.append(_make("rogue", RaidPlan.CONTENT_MORALE, str(i)))
    var a := RaidPlan.analyse(fine, _db, enc)
    assert_eq(String(a["risk_word"]), "LOW")

func test_the_risk_readout_carries_a_hatch_not_only_a_word() -> void:
    # docs/13 §10.3: "a word and a hatch density, never colour alone" — this is
    # what survives the greyscale screenshot test in §13.
    var hatch := RaidPlan.risk_hatch(10.0, 5.0)
    assert_true(hatch.length() > 0)
    assert_true(hatch.contains("/"), "elevated risk must show filled hatching")
    assert_false(RaidPlan.risk_hatch(5.0, 5.0).contains("/"),
        "risk at baseline must show no hatching")

func test_the_fill_is_zero_at_baseline_and_one_at_severe_and_the_hatch_reads_it() -> void:
    # UI-17: the screen draws its stripes from `risk_fill`; the typed hatch
    # the log and these tests read is cut from the same number, so the two
    # can never disagree about how full the meter is.
    assert_almost(RaidPlan.risk_fill(5.0, 5.0), 0.0, 0.0001, "at baseline: empty")
    assert_almost(RaidPlan.risk_fill(4.0, 5.0), 0.0, 0.0001, "under it: still empty")
    assert_almost(RaidPlan.risk_fill(5.0 * RaidPlan.SEVERE_RATIO, 5.0), 1.0, 0.0001,
        "at the SEVERE ratio: full")
    assert_almost(RaidPlan.risk_fill(50.0, 5.0), 1.0, 0.0001, "and never past full")
    var quarter := 1.0 + (RaidPlan.SEVERE_RATIO - 1.0) * 0.25
    assert_almost(RaidPlan.risk_fill(5.0 * quarter, 5.0), 0.25, 0.0001)
    assert_eq(RaidPlan.risk_hatch(5.0 * quarter, 5.0, 24), "/".repeat(6) + ".".repeat(18),
        "a quarter fill is six of twenty-four")
    assert_almost(RaidPlan.risk_fill(5.0, 0.0), 0.0, 0.0001, "no baseline: empty, not a division")
    var a := RaidPlan.analyse(_week_three(), _db, _encounter())
    assert_true(a.has("risk_fill"), "the readout carries the fill")
    assert_eq(String(a["risk_hatch"]),
        RaidPlan.risk_hatch(float(a["expected_mistakes"]), float(a["baseline_mistakes"])))

func test_the_delta_is_expected_less_baseline_and_always_signed() -> void:
    # LOOP-08: the callout's one number is what morale is costing tonight —
    # expected less the same comp at Content — not the per-encounter total,
    # which reads "~44 mistakes" for a Ready twelve.
    assert_almost(RaidPlan.risk_delta(58.5, 44.4), 14.1, 0.0001)
    assert_almost(RaidPlan.risk_delta(40.0, 44.4), -4.4, 0.0001)
    assert_eq(RaidPlan.signed(14.16), "+14.2")
    assert_eq(RaidPlan.signed(0.0), "+0.0")
    assert_eq(RaidPlan.signed(-0.04), "+0.0", "a delta that rounds to nothing is never '-0.0'")
    assert_eq(RaidPlan.signed(-3.2), "−3.2", "a real minus sign, not a hyphen")
    assert_false(RaidPlan.signed(-3.2).begins_with("-"))
    var enc = _encounter()
    var sad: Array = []
    for i in 12:
        sad.append(_make("rogue", 5, str(i)))
    var a := RaidPlan.analyse(sad, _db, enc)
    assert_almost(float(a["risk_delta"]),
        float(a["expected_mistakes"]) - float(a["baseline_mistakes"]), 0.0001)
    assert_true(float(a["risk_delta"]) > 0.0, "misery costs mistakes")
    assert_eq(String(a["risk_delta_text"]), RaidPlan.signed(float(a["risk_delta"])))
    assert_true(String(a["risk_delta_text"]).begins_with("+"))
    var fine: Array = []
    for i in 12:
        fine.append(_make("rogue", RaidPlan.CONTENT_MORALE, str(i)))
    var b := RaidPlan.analyse(fine, _db, enc)
    assert_eq(String(b["risk_delta_text"]), "+0.0", "a content guild costs nothing over itself")
    var happy: Array = []
    for i in 12:
        happy.append(_make("rogue", 95, str(i)))
    var c := RaidPlan.analyse(happy, _db, enc)
    assert_true(float(c["risk_delta"]) <= 0.0, "a happier guild is at or under the baseline")

func test_contributors_name_the_person_not_the_rarity() -> void:
    # docs/13 §10.3: contributions are attributed by EXCESS over that raider's
    # own Content figure. Otherwise every Common tops the list for being Common,
    # and the readout stops being a decision about a person.
    var comp: Array = []
    for i in 11:
        comp.append(_make("rogue", RaidPlan.CONTENT_MORALE, str(i)))
    var steve = _make("mage", 14, "_steve")
    steve.display_name = "Steve"
    comp.append(steve)

    var top := RaidPlan.contributors(comp, _encounter())
    assert_true(top.size() >= 1, "somebody must be named")
    assert_eq(String(top[0]["name"]), "Steve",
        "canon's own example: Steve at 14 is the problem")
    assert_eq(String(top[0]["state"]), "Upset")

func test_a_content_raid_names_nobody() -> void:
    var comp: Array = []
    for i in 12:
        comp.append(_make("rogue", RaidPlan.CONTENT_MORALE, str(i)))
    assert_eq(RaidPlan.contributors(comp, _encounter()).size(), 0,
        "nobody is above their own baseline, so nobody is to blame")

# ---------------------------------------------------------------- verdict

func test_a_clean_comp_reads_ready() -> void:
    var roster := StartingRoster.build(_db, 3)
    for r in roster:
        r.morale = RaidPlan.CONTENT_MORALE
    var a := RaidPlan.analyse(roster, _db, _encounter())
    assert_eq(String(a["verdict"]), "Ready")

func test_the_week_three_comp_does_not_read_ready() -> void:
    var a := RaidPlan.analyse(_week_three(), _db, _encounter())
    assert_ne(String(a["verdict"]), "Ready",
        "one tank short must be visible in the verdict word")
    assert_true(a["warnings"].size() > 0,
        "the player is allowed to lose, not to be surprised")

func test_analyse_never_returns_a_veto() -> void:
    # docs/06 §6.6 and docs/13 §10.4: "Penalties teach; locks do not." There is
    # no key in this readout that a screen could use to disable Depart.
    var a := RaidPlan.analyse([_make("bard")], _db, _encounter())
    for forbidden in ["blocked", "can_depart", "locked", "valid"]:
        assert_false(a.has(forbidden),
            "a comp readout must not expose '%s'" % forbidden)

# ---------------------------------------------------------------- the loop

## Mount through the REAL autoload router, exactly as Boot does. Screens look
## their router up via Services, so handing them a private instance would test a
## wiring that never exists in the game — and Depart would silently fail to
## navigate, which is how this was found.
func _mount(scene: String):
    var root := _root()
    var host := Control.new()
    root.add_child(host)
    _made.append(host)
    var r = root.get_node_or_null("ScreenRouter")
    assert_ne(r, null, "the ScreenRouter autoload must exist")
    r.register_host(host)
    assert_true(r.goto(scene), "could not open %s" % scene)
    return r

func _fresh_state():
    var st = _root().get_node_or_null("GameState")
    st.reset()
    st.set_content(_db)
    st.new_game("Loop Test")
    return st

## The bottom of the ladder moved when the tutorials landed: docs/10 §9.1 puts
## Adventure 0 and the Tutorial Raid ahead of A1, so a brand-new guild is gated
## on A0 and not on A1. Resolving the two tutorials is what a real player does
## before A1 is even offered, so a test about ADVENTURE ordering has to stand
## where the player stands.
func _past_the_tutorials(st) -> void:
    for e in _db.tutorial_encounters():
        st.cleared[e.id] = true

## The gate's sentence names the rung by its display name, never by its slot
## code (LOOP-03) — "Clear Adventure 0 first.", not "Clear A0 first.".
func _clear_first(slot: String) -> String:
    return "Clear %s first." % String(_db.encounter_at_slot(slot).display_name)

func test_the_board_locks_the_ladder_until_you_clear_the_rung_below() -> void:
    var st = _fresh_state()
    var printed := _joined(_mount(BOARD).current_screen())
    assert_true(printed.contains("Adventure's Board"), "canon's own spelling")
    assert_true(printed.contains("Clear Adventure 0 first."),
        "a new guild is gated on the first tutorial, because docs/10 §9.1 puts "
        + "Adventure 0 at the bottom of the ladder: %s" % printed)
    assert_false(printed.contains("Clear A0 first."),
        "the slot code stays off the sentence (LOOP-03)")

    _past_the_tutorials(st)
    printed = _joined(_mount(BOARD).current_screen())
    assert_true(printed.contains(_clear_first("A1")),
        "with the tutorials behind it the ladder opens on the Adventure tier, "
        + "because docs/08 §9.2 sizes Raid 1 for a guild that already owns "
        + "Adventure gear: %s" % printed)
    st.reset()

func test_clearing_a_rung_unlocks_the_next() -> void:
    var st = _fresh_state()
    _past_the_tutorials(st)
    var advs = _db.adventure_encounters(1)
    st.cleared[advs[0].id] = true
    var printed := _joined(_mount(BOARD).current_screen())
    assert_true(printed.contains("CLEARED"), "a cleared rung must say so")
    assert_false(printed.contains(_clear_first("A1")),
        "A1's gate must lift once A1 is cleared")
    assert_true(printed.contains(_clear_first("A2")),
        "A3 is still gated behind A2 — the ladder stays ordered")
    st.reset()

func test_prep_opens_with_a_suggested_twelve() -> void:
    var st = _fresh_state()
    st.selected_encounter_id = _db.raid_encounters(1)[0].id
    # Raid 1 fields twelve; the Adventure tier fields six (docs/10 §3).
    var prep = _mount(PREP).current_screen()
    assert_eq(prep.chalked_ids().size(), Enums.RAID_SIZE,
        "the player's job is to change the twelve, not to assemble one")
    st.reset()

func test_prep_shows_all_four_readouts_without_interaction() -> void:
    # docs/13 §10.2 — comp validity, morale, gear power, predicted risk, all
    # visible with no click. §10.4 forbids hiding the risk figure behind a hover.
    var st = _fresh_state()
    st.selected_encounter_id = _db.raid_encounters(1)[0].id
    var printed := _joined(_mount(PREP).current_screen())
    assert_true(printed.contains("Comp check"))
    assert_true(printed.contains("Tanks"))
    assert_true(printed.contains("Healers"))
    assert_true(printed.contains("Expected mistakes"), "the risk figure is not hidden")
    assert_true(printed.contains("Baseline at this comp"))
    assert_true(printed.contains("Verdict:"))
    assert_true(printed.contains("Slightly Annoyed"),
        "morale carries its state word on both lists")
    st.reset()

func test_departing_runs_the_sim_and_records_the_attempt() -> void:
    var st = _fresh_state()
    var enc = _db.raid_encounters(1)[0]
    st.selected_encounter_id = enc.id
    var router = _mount(PREP)
    var prep = router.current_screen()
    prep._on_depart()

    assert_eq(st.attempt_count(enc.id), 1, "the attempt must be recorded")
    assert_ne(st.last_result, null, "a result must exist")
    assert_eq(st.last_result.encounter_id, enc.id)
    # Depart lands on the ACCOUNT now (docs/13 §11), not the report: the raid is
    # experienced in RaidView and Results is the paperwork filed afterwards.
    assert_eq(router.current_path(), RAID_VIEW,
        "Depart lands on the raid view")
    st.reset()

func test_the_opening_raid_resolves_to_a_real_outcome() -> void:
    # NOT "the starting roster clears E1". The golden `e1_commons_starting`
    # records a SOFT WIPE for precisely this roster, and docs/01 §7.2 gives hour
    # one the emotional beat "these people are idiots" with failure meaning
    # "Comedy". The opening disaster is the design, so this asserts that the
    # attempt RESOLVES, not that it succeeds.
    var st = _fresh_state()
    var enc = _db.raid_encounters(1)[0]
    st.selected_encounter_id = enc.id
    var prep = _mount(PREP).current_screen()
    prep._on_depart()
    assert_true(st.last_result.outcome_key() in
        ["victory", "wipe", "soft_wipe", "attrition"],
        "got %s" % st.last_result.outcome_key())
    assert_eq(st.has_cleared(enc.id), st.last_result.cleared(),
        "the rung is cleared if and only if the raid won")
    st.reset()

func test_recording_a_win_clears_the_rung() -> void:
    # Bookkeeping, isolated from whether any particular raid is winnable. Uses
    # Adventure gear because starting armour cannot clear E1 at all — see the
    # test below, which pins that as the deliberate finding it is.
    var st = _fresh_state()
    var enc = _db.raid_encounters(1)[0]
    var roster: Array = Scenarios.build_roster(
        {"rarity": Enums.Rarity.COMMON, "morale": 55, "gear": "adventure"}, _db)
    var winning = null
    for attempt in 20:
        var res = RaidSim.run(roster, enc, _db, 1000 + attempt * 7919)
        if res.cleared():
            winning = res
            break
    assert_ne(winning, null, "Adventure-geared Commons must be able to clear E1")
    st.record_attempt(enc.id, winning)
    assert_true(st.has_cleared(enc.id))
    assert_eq(st.attempt_count(enc.id), 1)
    st.reset()

func test_raid_one_cannot_be_entered_in_starting_armour() -> void:
    # NOT a bug, and NOT a tuning accident. docs/08 §9.2 derives Boss 1's HP
    # from "Raid DPS at attempt" = 182, which is the After-Boss-0 row — i.e. a
    # raid that already owns Tier 1 ADVENTURE gear. The golden
    # `e1_commons_starting` has recorded a soft wipe for this roster since it
    # was written.
    #
    # What this pins is the CONSEQUENCE: canon's on-ramp — "Adventure 0 - 1
    # Trash mob (Just for learning - 1 crap trinket)" and "Adventure 1 - a few
    # trash encounters and a mini boss" — is the content that carries a guild
    # from starting armour to raid-ready, and it does not exist yet. Until it
    # does, the Adventure's Board is a ladder whose first rung cannot be
    # climbed. Tracked as docs/15 BL-26.
    #
    # This still holds after docs/15 BL-27's output floor landed, and that is
    # the intended design: the floor makes the ADVENTURE tier playable, not the
    # raid tier. Raid 1 is entered in Adventure gear, which Adventures hand out.
    # If it ever fails, someone buffed starting gear rather than the on-ramp.
    var enc = _db.raid_encounters(1)[0]
    var roster := StartingRoster.build(_db, 7)
    for r in roster:
        r.morale = 95
    var cleared := 0
    for i in 20:
        if RaidSim.run(roster, enc, _db, 1000 + i * 7919).cleared():
            cleared += 1
    assert_eq(cleared, 0,
        "starting armour clearing E1 would mean docs/08 §9.2's DPS-at-attempt "
        + "no longer holds — check the gear tables before deleting this")

func test_raid_seeds_do_not_repeat_across_attempts() -> void:
    var st = _fresh_state()
    var first: int = st.next_raid_seed()
    st.record_attempt("enc_x", null)
    assert_ne(st.next_raid_seed(), first,
        "every attempt must draw its own seed, or all raids are the same raid")
    st.reset()

func test_results_reports_the_attempt() -> void:
    var st = _fresh_state()
    var enc = _db.raid_encounters(1)[0]
    st.selected_encounter_id = enc.id
    var prep = _mount(PREP).current_screen()
    prep._on_depart()
    var printed := _joined(_mount(RESULTS).current_screen())
    assert_true(printed.contains("Rounds"))
    assert_true(printed.contains("Mistakes"))
    assert_true(printed.contains("What happened"), "a wipe must read as a story")
    assert_true(printed.contains(enc.display_name))
    st.reset()

func test_results_without_an_attempt_is_an_empty_state_not_a_crash() -> void:
    var st = _fresh_state()
    st.last_result = null
    var printed := _joined(_mount(RESULTS).current_screen())
    assert_true(printed.contains("No attempt to report"))
    st.reset()

func test_raid_progress_survives_a_save_round_trip() -> void:
    var st = _fresh_state()
    st.cleared["enc_a"] = true
    st.attempts["enc_a"] = 3
    var d: Dictionary = st.to_dict()
    var other = GameStateScript.new()
    _made.append(other)
    other.reset()
    var problems: Array = other.from_dict(d)
    assert_eq(problems.size(), 0, str(problems))
    assert_true(other.has_cleared("enc_a"))
    assert_eq(other.attempt_count("enc_a"), 3)
    st.reset()


func test_the_tutorials_resolve_to_one_tank_at_the_layer_the_screen_reads() -> void:
    # docs/15 Q-47 is the tie-break over docs/10 §9.1's "no tanks required":
    # "Per-fight `tanks_required` (default 2, tutorials 1)". Both tutorials
    # author 1, and `sim/model/Encounter.gd` refuses a literal 0 at load so the
    # trap that made an authored 0 indistinguishable from an absent field is
    # closed at the door.
    #
    # THIS ASSERTS THE RESOLUTION, NOT THE DATA, and that is the point. Nothing
    # pinned `RaidPlan.tanks_required()` itself, so widening its guard from
    # `> 0` to `> 1` would have handed both tutorials the default 2 — a party
    # requirement the tutorial cannot field — and the whole suite would still
    # have passed. The data is checked in test_encounters.gd; this is the one
    # line of code RaidPrep actually calls.
    for slot in ["A0", "TR"]:
        var enc = _db.encounter_at_slot(slot)
        assert_ne(enc, null, "%s must be in the content set" % slot)
        assert_eq(RaidPlan.tanks_required(enc), 1,
            "%s resolves to %d tanks, not Q-47's 1" % [slot, RaidPlan.tanks_required(enc)])
    # The negative half: a real rung still takes the docs/06 §6.5 default, so the
    # assertion above is about the tutorials rather than about the function
    # having been flattened to return 1.
    assert_eq(RaidPlan.tanks_required(_db.encounter_at_slot("E1")),
        RaidPlan.DEFAULT_TANKS_REQUIRED, "a raid rung keeps the default")
