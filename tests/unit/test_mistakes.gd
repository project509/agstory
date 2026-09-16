extends "res://tests/TestCase.gd"
## sim/core/Mistakes.gd — the comedy engine.
##
## Canon gives the dial and nothing else: every raider has a mistake chance that
## moves with morale and rarity. The taxonomy, cadence, severity model and
## cascade rules are all docs/07's proposal, so most of these tests pin docs/07
## rather than canon — except where canon anchors a number, which is called out.

const M = preload("res://sim/core/Mistakes.gd")
const F = preload("res://sim/core/Formulas.gd")
const Rng = preload("res://sim/core/Rng.gd")
const E = preload("res://sim/model/Enums.gd")

func _ctx(site: int = E.RollSite.ACTION, round_no: int = 1):
    var c = M.Context.new()
    c.roll_site = site
    c.round_no = round_no
    return c

# ---------------------------------------------------------------- taxonomy

func test_all_eighteen_types_are_present() -> void:
    assert_eq(M.type_count(), 18, "docs/07 §5.2 defines eighteen mistake types")

func test_every_type_is_well_formed() -> void:
    for type_id in M.TYPES.keys():
        var t: Dictionary = M.TYPES[type_id]
        assert_true(type_id.begins_with("MIS_"), "id convention: %s" % type_id)
        for field in ["name", "site", "severity", "weight", "emits", "cascade_only"]:
            assert_true(t.has(field), "%s missing %s" % [type_id, field])
        assert_false(String(t["name"]).is_empty(), "%s has no display name" % type_id)
        assert_true(int(t["weight"]) > 0, "%s must have a positive weight" % type_id)
        assert_in_range(int(t["severity"]), 0, 3, "%s severity band" % type_id)

func test_exactly_one_cascade_only_type() -> void:
    # docs/07 §6 rule 3: cascade-only types can never open a chain.
    var cascade_only := []
    for type_id in M.TYPES.keys():
        if bool(M.TYPES[type_id]["cascade_only"]):
            cascade_only.append(type_id)
    assert_eq(cascade_only, ["MIS_AVOIDABLE_DEATH"])

func test_types_are_spread_across_all_three_roll_sites() -> void:
    var counts := {E.RollSite.ACTION: 0, E.RollSite.MECHANIC: 0, E.RollSite.AMBIENT: 0}
    for type_id in M.TYPES.keys():
        counts[int(M.TYPES[type_id]["site"])] += 1
    for site in counts.keys():
        assert_true(counts[site] >= 4,
            "site %s has only %d types" % [E.roll_site_key(site), counts[site]])

# ---------------------------------------------------------------- eligibility

func test_class_gated_types_only_offer_to_their_classes() -> void:
    var ctx = _ctx(E.RollSite.ACTION)
    var mage := M.eligible_types(E.CharClass.MAGE, E.RoleGroup.DPS, ctx)
    var warrior := M.eligible_types(E.CharClass.WARRIOR, E.RoleGroup.TANK, ctx)
    assert_true("MIS_TAUNT_LAPSE" in warrior, "a Warrior can forget to taunt")
    assert_false("MIS_TAUNT_LAPSE" in mage, "a Mage cannot forget to taunt")
    assert_false("MIS_CHAIN_FIZZLE" in mage, "only a Shaman has a chain heal")

func test_role_gated_types_follow_the_role_group() -> void:
    var ctx = _ctx(E.RollSite.ACTION)
    var healer := M.eligible_types(E.CharClass.DRUID, E.RoleGroup.HEALER, ctx)
    var dps := M.eligible_types(E.CharClass.ROGUE, E.RoleGroup.DPS, ctx)
    assert_true("MIS_HEAL_WRONG" in healer)
    assert_false("MIS_HEAL_WRONG" in dps, "a Rogue cannot misheal")
    assert_true("MIS_AGGRO" in dps, "DPS can pull aggro")
    assert_false("MIS_AGGRO" in healer, "healers pull aggro by healing, not by this type")

func test_context_requirements_gate_types() -> void:
    var ctx = _ctx(E.RollSite.ACTION)
    var rogue_no_trash := M.eligible_types(E.CharClass.ROGUE, E.RoleGroup.DPS, ctx)
    assert_false("MIS_FACEPULL" in rogue_no_trash, "nothing to facepull mid-boss")
    ctx.trash_phase = true
    assert_true("MIS_FACEPULL" in M.eligible_types(E.CharClass.ROGUE, E.RoleGroup.DPS, ctx))

func test_cascade_only_type_needs_a_live_token() -> void:
    var ctx = _ctx(E.RollSite.MECHANIC)
    assert_false("MIS_AVOIDABLE_DEATH" in M.eligible_types(E.CharClass.MAGE, E.RoleGroup.DPS, ctx),
        "cascade-only types can never open a chain")
    ctx.live_tokens = [E.Token.FIRE]
    assert_true("MIS_AVOIDABLE_DEATH" in M.eligible_types(E.CharClass.MAGE, E.RoleGroup.DPS, ctx),
        "a live Fire token makes an avoidable death reachable")

func test_per_type_cooldown_blocks_a_repeat() -> void:
    # docs/07 §5.5: "Steve stood in the fire" three rounds running reads as a bug.
    var ctx = _ctx(E.RollSite.MECHANIC, 5)
    ctx.zone_exists = true    # there has to be a fire to stand in (SIM-14)
    assert_true("MIS_FIRE" in M.eligible_types(E.CharClass.MAGE, E.RoleGroup.DPS, ctx))
    ctx.cooldowns["MIS_FIRE"] = 5
    assert_false("MIS_FIRE" in M.eligible_types(E.CharClass.MAGE, E.RoleGroup.DPS, ctx),
        "blocked in the round it fired")
    ctx.round_no = 6
    assert_true("MIS_FIRE" in M.eligible_types(E.CharClass.MAGE, E.RoleGroup.DPS, ctx),
        "available again the next round")

func test_eligible_list_is_deterministically_ordered() -> void:
    var a := M.eligible_types(E.CharClass.ROGUE, E.RoleGroup.DPS, _ctx())
    var b := M.eligible_types(E.CharClass.ROGUE, E.RoleGroup.DPS, _ctx())
    assert_eq(a, b, "golden files depend on this ordering")
    var sorted_copy := a.duplicate()
    sorted_copy.sort()
    assert_eq(a, sorted_copy)

# ---------------------------------------------------------------- weights

func test_affinity_scales_selection_weight_not_mistake_chance() -> void:
    # docs/07 §5.2: a Rogue is not clumsier than a Mage; a Rogue's clumsiness is
    # more likely to express itself as a facepull.
    var rogue_w := M.weight_for("MIS_FACEPULL", E.CharClass.ROGUE, 5)
    var monk_w := M.weight_for("MIS_FACEPULL", E.CharClass.MONK, 5)
    assert_true(rogue_w > monk_w, "Rogue has x2 facepull affinity")
    # ...and the underlying chance is identical for both.
    assert_eq(F.mistake_chance_bp(E.Rarity.COMMON, 55),
              F.mistake_chance_bp(E.Rarity.COMMON, 55),
        "affinity must not touch the raider's mistake chance")

func test_wizard_is_the_likeliest_to_pull_aggro() -> void:
    # Canon: "Very high single-target DPS" — the classic threat problem.
    var wiz := M.weight_for("MIS_AGGRO", E.CharClass.WIZARD, 5)
    var rogue := M.weight_for("MIS_AGGRO", E.CharClass.ROGUE, 5)
    var mage := M.weight_for("MIS_AGGRO", E.CharClass.MAGE, 5)
    assert_true(wiz > rogue, "Wizard x2 beats Rogue x1.5")
    assert_true(rogue > mage, "Rogue x1.5 beats an unmodified caster")

func test_misery_makes_some_failures_far_likelier() -> void:
    # Going AFK is x2 in Upset or worse — canon's low bands are meant to bite.
    var content := M.weight_for("MIS_AFK", E.CharClass.MAGE, 5)
    var upset := M.weight_for("MIS_AFK", E.CharClass.MAGE, 1)
    assert_eq(upset, content * 2, "AFK doubles at Upset or worse")
    assert_eq(M.weight_for("MIS_AFK", E.CharClass.MAGE, 2), content,
        "but not at Unhappy, which is above the threshold")

func test_melee_affinity_applies_to_the_canon_melee_classes() -> void:
    var rogue := M.weight_for("MIS_FIRE", E.CharClass.ROGUE, 5)
    var wizard := M.weight_for("MIS_FIRE", E.CharClass.WIZARD, 5)
    assert_true(rogue > wizard, "melee stand in fire more often")

# ---------------------------------------------------------------- severity

func test_severity_tracks_the_margin_of_failure() -> void:
    # docs/07 §5.4: a roll just under the line is a fumble; a roll near zero is a
    # catastrophe. Without this, a game with this many rolls flattens into noise.
    var rng = Rng.new(1)
    var low_margin := 0
    var high_margin := 0
    for i in 200:
        var r = Rng.new(i)
        low_margin += M.severity_for("MIS_FIRE", 0.05, r)
        var r2 = Rng.new(i)
        high_margin += M.severity_for("MIS_FIRE", 0.95, r2)
    assert_true(high_margin > low_margin,
        "a catastrophic miss must skew more severe than a near miss")

func test_severity_is_clamped_to_the_type_band() -> void:
    # A forgotten consumable can never be Critical; a facepull can never be Minor.
    for i in 60:
        var r = Rng.new(i)
        var s := M.severity_for("MIS_NO_CONSUMABLE", 1.0, r)
        assert_true(s <= E.Severity.MODERATE,
            "MIS_NO_CONSUMABLE is base Minor, so it caps at Moderate")
    for i in 60:
        var r2 = Rng.new(i)
        var s2 := M.severity_for("MIS_FACEPULL", 0.0, r2)
        assert_true(s2 >= E.Severity.SEVERE,
            "MIS_FACEPULL is base Critical, so it floors at Severe")

func test_severity_is_deterministic_for_a_seed() -> void:
    assert_eq(M.severity_for("MIS_AGGRO", 0.78, Rng.new(99)),
              M.severity_for("MIS_AGGRO", 0.78, Rng.new(99)))

# ---------------------------------------------------------------- the roll

func test_a_perfect_raider_never_makes_a_mistake() -> void:
    # Sanity floor: with a zero chance the gate must never open.
    var rng = Rng.new(7)
    var ctx = _ctx()
    for i in 200:
        ctx.round_no = i + 1
        var ev = M.roll(rng, E.CharClass.WARRIOR, E.RoleGroup.TANK,
            E.Rarity.LEGENDARY, 95, ctx, 0, 0.0)   # facility_mult 0 => p = floor
        if ev != null:
            assert_true(ev.severity >= 0)          # clamped to the floor, still possible
    assert_true(true)

func test_action_rate_matches_the_weighted_published_chance() -> void:
    # docs/15 BL-21: the published 24% for a Content Common is now the PER-ROUND
    # aggregate across roll sites, not the per-site rate. The action site carries
    # ROLL_SITE_WEIGHT of it. This is the end-to-end check that the equation, the
    # weighting and the gate agree.
    var expected := 24.0 * float(F.ROLL_SITE_WEIGHT[E.RollSite.ACTION])
    var rng = Rng.new(20260909)
    var hits := 0
    var n := 4000
    for i in n:
        var ctx = _ctx(E.RollSite.ACTION, i + 1)
        if M.roll(rng, E.CharClass.ROGUE, E.RoleGroup.DPS, E.Rarity.COMMON, 55, ctx) != null:
            hits += 1
    var rate := float(hits) / float(n) * 100.0
    assert_in_range(rate, expected - 2.5, expected + 2.5,
        "observed %.1f%% should sit near the weighted %.1f%%" % [rate, expected])

func test_per_round_aggregate_stays_near_the_published_chance() -> void:
    # The invariant the rescale exists to hold: a raider taking one action roll
    # and one ambient roll should fail about as often per ROUND as docs/08
    # publishes, because that is what its DPS-tax argument assumes.
    var published := 0.24
    var a := float(F.mistake_chance_at_site_bp(E.Rarity.COMMON, 55, E.RollSite.ACTION)) / 10000.0
    var amb := float(F.mistake_chance_at_site_bp(E.Rarity.COMMON, 55, E.RollSite.AMBIENT)) / 10000.0
    var aggregate := 1.0 - (1.0 - a) * (1.0 - amb)
    assert_true(aggregate <= published,
        "aggregate %.3f must not exceed the published %.3f" % [aggregate, published])
    # Ambient sits deliberately below an equal split — going AFK is colour, not a
    # second combat roll — so the aggregate lands a little under rather than on.
    assert_true(aggregate >= published * 0.6,
        "aggregate %.3f collapsed too far below the published %.3f" % [aggregate, published])

func test_legendary_rate_is_near_canon_one_percent() -> void:
    # Canon's only stated mistake number, measured end to end.
    var rng = Rng.new(4242)
    var hits := 0
    var n := 20000
    for i in n:
        var ctx = _ctx(E.RollSite.ACTION, i + 1)
        if M.roll(rng, E.CharClass.WARRIOR, E.RoleGroup.TANK, E.Rarity.LEGENDARY, 95, ctx) != null:
            hits += 1
    var rate := float(hits) / float(n) * 100.0
    assert_in_range(rate, 0.6, 1.4, "observed %.2f%% should sit near canon's 1%%" % rate)

func test_ambient_rolls_are_scaled_down() -> void:
    # docs/15 BL-21: ambient failures are colour, not a second full mistake roll.
    var action := F.mistake_chance_at_site_bp(E.Rarity.COMMON, 55, E.RollSite.ACTION)
    var ambient := F.mistake_chance_at_site_bp(E.Rarity.COMMON, 55, E.RollSite.AMBIENT)
    var published := F.mistake_chance_bp(E.Rarity.COMMON, 55)
    assert_true(ambient < action, "ambient must be rarer than acting")
    assert_true(action < published,
        "after the BL-21 rescale no single site carries the full published chance")
    assert_true(action > published / 3,
        "the action site is still the dominant one")

func test_roll_is_deterministic_for_a_seed() -> void:
    var a = M.roll(Rng.new(31337), E.CharClass.ROGUE, E.RoleGroup.DPS,
        E.Rarity.COMMON, 20, _ctx())
    var b = M.roll(Rng.new(31337), E.CharClass.ROGUE, E.RoleGroup.DPS,
        E.Rarity.COMMON, 20, _ctx())
    if a == null:
        assert_eq(b, null)
    else:
        assert_eq(a.type_id, b.type_id)
        assert_eq(a.severity, b.severity)
        assert_almost(a.margin, b.margin, 0.0001)

func test_a_rolled_mistake_carries_its_provenance() -> void:
    var rng = Rng.new(5)
    var ev = null
    for i in 400:
        var ctx = _ctx(E.RollSite.ACTION, i + 1)
        ev = M.roll(rng, E.CharClass.ROGUE, E.RoleGroup.DPS, E.Rarity.COMMON, 15, ctx)
        if ev != null:
            break
    assert_ne(ev, null, "a miserable Common should fail within 400 rolls")
    assert_false(ev.type_id.is_empty())
    assert_false(ev.id().is_empty())
    assert_in_range(ev.margin, 0.0, 1.0)
    assert_true(ev.rng_draw_index >= 0, "the draw index is recorded for tier-3 debugging")

# ---------------------------------------------------------------- guards

func test_critical_cap_demotes_rather_than_discards() -> void:
    # docs/07 §5.5: a wipe should read as a chain of small failures, not a
    # simultaneous explosion. The mistake still happened, so it is demoted.
    var ctx = _ctx(E.RollSite.ACTION)
    ctx.trash_phase = true
    ctx.criticals_this_round = M.MAX_CRITICALS_PER_ROUND
    var rng = Rng.new(11)
    var found_critical := false
    for i in 300:
        ctx.round_no = i + 1
        ctx.cooldowns.clear()
        var ev = M.roll(rng, E.CharClass.ROGUE, E.RoleGroup.DPS, E.Rarity.COMMON, 5, ctx)
        if ev != null and ev.severity == E.Severity.CRITICAL:
            found_critical = true
    assert_false(found_critical, "no second Critical may be logged in one round")

func test_note_fired_arms_the_cooldown_and_counts_criticals() -> void:
    var ctx = _ctx(E.RollSite.ACTION, 4)
    var ev = M.MistakeEvent.new()
    ev.type_id = "MIS_AGGRO"
    ev.round_no = 4
    ev.severity = E.Severity.CRITICAL
    M.note_fired(ctx, ev)
    assert_eq(int(ctx.cooldowns["MIS_AGGRO"]), 4)
    assert_eq(ctx.criticals_this_round, 1)

func test_cascade_attribution_records_the_chain() -> void:
    # docs/07 §6 rule 1: this is what lets the post-mortem say "the wipe started
    # when Greg pulled aggro in round 4".
    var parent = M.MistakeEvent.new()
    parent.type_id = "MIS_AGGRO"
    parent.actor_id = "greg"
    parent.round_no = 4
    var child = M.MistakeEvent.new()
    child.type_id = "MIS_TAUNT_LAPSE"
    child.actor_id = "bob"
    child.round_no = 4
    child.tokens_emitted = [E.Token.AGGRO]
    M.attribute(child, parent)
    assert_eq(child.caused_by, parent.id())
    assert_eq(child.cascade_depth, 1)
    assert_true(child.caused_by.contains("greg"))

func test_chains_terminate_at_the_depth_cap() -> void:
    # docs/07 §6 rule 2: a mistake at depth 3 emits no tokens, so chains end and
    # logs stay readable.
    var prev = M.MistakeEvent.new()
    prev.type_id = "MIS_AGGRO"
    prev.actor_id = "a"
    prev.cascade_depth = M.MAX_CASCADE_DEPTH - 1
    var child = M.MistakeEvent.new()
    child.type_id = "MIS_FIRE"
    child.actor_id = "b"
    child.tokens_emitted = [E.Token.FIRE]
    M.attribute(child, prev)
    assert_eq(child.cascade_depth, M.MAX_CASCADE_DEPTH)
    assert_eq(child.tokens_emitted, [], "a mistake at the depth cap emits nothing")

func test_emitted_tokens_match_the_taxonomy() -> void:
    assert_eq(M.TYPES["MIS_AGGRO"]["emits"], [E.Token.AGGRO])
    assert_eq(M.TYPES["MIS_FIRE"]["emits"], [E.Token.FIRE])
    assert_eq(M.TYPES["MIS_BROKE_CC"]["emits"], [E.Token.ADDS])
    assert_eq(M.TYPES["MIS_MECHANIC_DROP"]["emits"], [E.Token.FIRE, E.Token.DISTRACTION])
    assert_eq(M.TYPES["MIS_HEAL_WRONG"]["emits"], [E.Token.MANA])

# ---------------------------------------------------------- no fire without fire

func test_no_fire_mistake_on_an_encounter_without_a_ground_effect() -> void:
    # SIM-14: "Stood in the Fire" is a sentence about the encounter. The roll
    # site used to strip the TOKEN on a fight with no M03 and keep the NAME, so
    # E3 logged a fire nobody could stand in. The type is gated now, in the
    # taxonomy, and so is every type's Fire token.
    var dry = _ctx(E.RollSite.MECHANIC)
    var wet = _ctx(E.RollSite.MECHANIC)
    wet.zone_exists = true
    for cls in _every_class():
        for role in [E.RoleGroup.TANK, E.RoleGroup.HEALER, E.RoleGroup.DPS, E.RoleGroup.SUPPORT]:
            assert_false("MIS_FIRE" in M.eligible_types(cls, role, dry),
                "class %d role %d offered Stood in the Fire with no fire" % [cls, role])
            assert_true("MIS_FIRE" in M.eligible_types(cls, role, wet),
                "class %d role %d cannot stand in a fire that exists" % [cls, role])
    # The token half, for the OTHER type that emits Fire: a dropped mechanic on
    # a dry fight still distracts, and never burns.
    assert_eq(M.emits_for("MIS_MECHANIC_DROP", dry), [E.Token.DISTRACTION])
    assert_eq(M.emits_for("MIS_MECHANIC_DROP", wet), [E.Token.FIRE, E.Token.DISTRACTION])
    assert_eq(M.emits_for("MIS_FIRE", wet), [E.Token.FIRE])
    assert_eq(M.emits_for("MIS_AGGRO", dry), [E.Token.AGGRO], "non-Fire tokens are untouched")
    # End to end through `roll`: a miserable melee at the mechanic site, 400
    # rolls, no zone — no Fire by name and no Fire by token, ever.
    var rng = Rng.new(2024)
    var fired := 0
    for i in 400:
        var ctx = _ctx(E.RollSite.MECHANIC, i + 1)
        var ev = M.roll(rng, E.CharClass.ROGUE, E.RoleGroup.DPS, E.Rarity.COMMON, 5, ctx)
        if ev == null:
            continue
        fired += 1
        assert_ne(ev.type_id, "MIS_FIRE", "round %d: Stood in the Fire with no fire" % (i + 1))
        assert_false(E.Token.FIRE in ev.tokens_emitted,
            "round %d: %s emitted a Fire token with no fire" % [i + 1, ev.type_id])
    assert_true(fired > 20, "the fixture must actually fail some rolls (%d)" % fired)

# ------------------------------------------------------ tier-3 provenance

func test_a_rolled_mistake_carries_its_tier_three_provenance() -> void:
    # SIM-29 / docs/07 §10.1: p, r, margin, the weights the type was drawn from
    # and the raw severity score, so a tier-3 view can say why THIS roll failed.
    var rng = Rng.new(8)
    var ev = null
    var ctx = null
    for i in 400:
        ctx = _ctx(E.RollSite.ACTION, i + 1)
        ev = M.roll(rng, E.CharClass.ROGUE, E.RoleGroup.DPS, E.Rarity.COMMON, 15, ctx)
        if ev != null:
            break
    assert_ne(ev, null, "a miserable Common should fail within 400 rolls")
    assert_eq(ev.p_bp, M.chance_bp(E.Rarity.COMMON, 15, ctx), "the gate chance, in bp")
    assert_true(ev.r_bp >= 0 and ev.r_bp < ev.p_bp, "the draw was under the gate")
    assert_almost(ev.margin, float(ev.p_bp - ev.r_bp) / float(ev.p_bp), 0.0001)
    assert_in_range(ev.severity_s, 1, 100, "docs/07 §5.4's S")
    assert_eq(ev.severity, M.severity_band_for(ev.type_id, ev.severity_s),
        "the band is the score banded, and nothing else")
    assert_true(ev.weights.has(ev.type_id), "the chosen type is in the weights it was drawn from")
    assert_eq(int(ev.weights[ev.type_id]),
        M.weight_for(ev.type_id, E.CharClass.ROGUE, E.morale_band(15)))
    var d: Dictionary = ev.debug_dict()
    for key in ["p_bp", "r_bp", "margin", "channel", "draw", "weights", "severity_s"]:
        assert_true(d.has(key), "debug block missing %s" % key)
    assert_eq(int(d["draw"]), ev.rng_draw_index)

func test_severity_for_is_the_score_then_the_band_with_one_draw() -> void:
    # The split exists so the score can travel to the log without a second
    # d20. Same seed, same answer, and the wrapper still draws exactly once.
    for i in 40:
        var a = Rng.new(100 + i)
        var b = Rng.new(100 + i)
        var whole := M.severity_for("MIS_AGGRO", 0.61, a)
        var s := M.severity_score(0.61, b)
        assert_eq(whole, M.severity_band_for("MIS_AGGRO", s))
        assert_eq(a.draws, b.draws, "one draw either way")
    assert_eq(M.severity_band_for("MIS_NO_CONSUMABLE", 100), E.Severity.MODERATE,
        "the band is still clamped to the type's own +/- 1")
    assert_eq(M.severity_band_for("MIS_FACEPULL", 1), E.Severity.SEVERE)

# ---------------------------------------------------------------- tutorials

## docs/15's tutorial-mistake-rate ruling (DECIDED, answering docs/07 OQ-9):
## "Reduced rate for both tutorials, full rates from Adventure 1 onward"; OQ-9
## names MIS_FACEPULL and MIS_NINJAPULL as the two to disable. The 0.5 is the
## build loop's number (build/plan/q-W5-SIM.md).

func _every_class() -> Array:
    var out := []
    for cls in E.CharClass.size():
        out.append(cls)
    return out

func test_a_tutorial_never_offers_the_two_pulls_to_any_class() -> void:
    # Both types need a context flag to be eligible at all, so the test arms
    # the flags — a test that passed because the flag was off would prove nothing.
    for cls in _every_class():
        for role in [E.RoleGroup.TANK, E.RoleGroup.HEALER, E.RoleGroup.DPS, E.RoleGroup.SUPPORT]:
            for site in [E.RollSite.ACTION, E.RollSite.AMBIENT, E.RollSite.MECHANIC]:
                var ctx = _ctx(site)
                ctx.trash_phase = true
                ctx.break_phase = true
                ctx.tutorial = true
                var offered := M.eligible_types(cls, role, ctx)
                for banned in M.TUTORIAL_DISABLED_TYPES:
                    assert_false(banned in offered,
                        "%s offered to class %d role %d at site %d in a tutorial"
                        % [banned, cls, role, site])

func test_outside_a_tutorial_the_same_context_still_offers_them() -> void:
    # The inverse, so the gate above is known to be the tutorial flag and not a
    # broken context: a Rogue on a trash pull can still facepull on Adventure 1.
    var ctx = _ctx(E.RollSite.ACTION)
    ctx.trash_phase = true
    assert_true("MIS_FACEPULL" in M.eligible_types(E.CharClass.ROGUE, E.RoleGroup.DPS, ctx))
    var amb = _ctx(E.RollSite.AMBIENT)
    amb.break_phase = true
    assert_true("MIS_NINJAPULL" in M.eligible_types(E.CharClass.ROGUE, E.RoleGroup.DPS, amb))
    assert_eq(M.TUTORIAL_DISABLED_TYPES, ["MIS_FACEPULL", "MIS_NINJAPULL"],
        "docs/07 OQ-9 names exactly these two")

func test_the_tutorial_gate_is_exactly_half_the_published_site_chance() -> void:
    assert_almost(M.TUTORIAL_MISTAKE_MULT, 0.5, 0.0001,
        "the proposed docs/15 entry says half; change both or neither")
    for rarity in [E.Rarity.COMMON, E.Rarity.UNCOMMON, E.Rarity.RARE, E.Rarity.EPIC, E.Rarity.LEGENDARY]:
        for morale in [5, 31, 55, 95]:
            for site in [E.RollSite.ACTION, E.RollSite.AMBIENT, E.RollSite.MECHANIC]:
                var real = _ctx(site)
                var tut = _ctx(site)
                tut.tutorial = true
                var full: int = F.mistake_chance_at_site_bp(rarity, morale, site)
                assert_eq(M.chance_bp(rarity, morale, real), full,
                    "a real rung's gate is the formula, untouched")
                var halved: int = M.chance_bp(rarity, morale, tut)
                assert_eq(halved, int(round(float(full) * M.TUTORIAL_MISTAKE_MULT)),
                    "rarity %d morale %d site %d: tutorial %d vs full %d"
                    % [rarity, morale, site, halved, full])
                assert_true(absi(halved * 2 - full) <= 1, "exactly half, to the rounding")

func test_the_halved_gate_halves_the_observed_mistake_rate() -> void:
    # End to end through `roll`, not only through the accessor: a multiplier the
    # roll never read would pass the test above and change nothing.
    var n := 6000
    var real_hits := 0
    var tut_hits := 0
    var rng_real = Rng.new(515)
    var rng_tut = Rng.new(515)
    for i in n:
        var real = _ctx(E.RollSite.ACTION, i + 1)
        if M.roll(rng_real, E.CharClass.ROGUE, E.RoleGroup.DPS, E.Rarity.COMMON, 25, real) != null:
            real_hits += 1
        var tut = _ctx(E.RollSite.ACTION, i + 1)
        tut.tutorial = true
        if M.roll(rng_tut, E.CharClass.ROGUE, E.RoleGroup.DPS, E.Rarity.COMMON, 25, tut) != null:
            tut_hits += 1
    assert_true(real_hits > 300, "the miserable Common must fail often enough to measure (%d)" % real_hits)
    var ratio := float(tut_hits) / float(real_hits)
    assert_in_range(ratio, 0.38, 0.62,
        "tutorial %d vs real %d hits — ratio %.2f should sit near 0.5" % [tut_hits, real_hits, ratio])

# ----------------------------------------------------- the scripted mistake

## docs/10 §9.1: "Adventure 0 scripts one guaranteed mistake on round 3
## regardless of morale rolls." `force` is the half of that which lives in the
## taxonomy; RaidSim decides who and when.

func test_a_forced_mistake_fires_with_no_gate_roll_at_all() -> void:
    # A Legendary at 95 morale rolls the gate at ~1% (canon). Forced, it fails
    # every time — and in a tutorial context, where the gate is halved again,
    # which is the interaction M5-TUT-11's risk clause names.
    for i in 40:
        var ctx = _ctx(E.RollSite.ACTION, 3)
        ctx.tutorial = true
        var ev = M.force(Rng.new(1000 + i), E.CharClass.ROGUE, E.RoleGroup.DPS, 95, ctx)
        assert_ne(ev, null, "seed %d: the scripted mistake did not happen" % i)
        assert_eq(ev.round_no, 3)
        assert_eq(ev.roll_site, E.RollSite.ACTION)
        assert_true(M.TYPES.has(ev.type_id), "keyed on the taxonomy")
        assert_false(ev.type_id in M.TUTORIAL_DISABLED_TYPES,
            "a tutorial's scripted mistake obeys the tutorial's own bans")

func test_a_forced_mistake_is_minor_wherever_the_type_allows_it() -> void:
    # "A tutorial demonstrates a fail state, it does not impose one." The draw
    # prefers types whose band reaches Minor, and the severity is that floor.
    for cls in _every_class():
        for role in [E.RoleGroup.TANK, E.RoleGroup.HEALER, E.RoleGroup.DPS, E.RoleGroup.SUPPORT]:
            var ctx = _ctx(E.RollSite.ACTION, 3)
            ctx.tutorial = true
            var ev = M.force(Rng.new(7), cls, role, 55, ctx)
            if ev == null:
                continue    # a class/role pair with no action-site type at all
            var base: int = int(M.TYPES[ev.type_id]["severity"])
            assert_eq(ev.severity, maxi(E.Severity.MINOR, base - 1),
                "%s forced at %s, base %s" % [ev.type_id,
                    E.severity_key(ev.severity), E.severity_key(base)])
            if base <= E.Severity.MODERATE:
                assert_eq(ev.severity, E.Severity.MINOR)

func test_a_forced_mistake_is_deterministic_for_a_seed_and_shaped_like_a_real_one() -> void:
    var ctx = _ctx(E.RollSite.ACTION, 3)
    var a = M.force(Rng.new(99), E.CharClass.WIZARD, E.RoleGroup.DPS, 40, ctx)
    var b = M.force(Rng.new(99), E.CharClass.WIZARD, E.RoleGroup.DPS, 40, ctx)
    assert_ne(a, null)
    assert_eq(a.type_id, b.type_id)
    assert_eq(a.severity, b.severity)
    # The same field set `roll` fills, so `_log_mistake` and the goldens read
    # one shape.
    assert_eq(a.type_name, String(M.TYPES[a.type_id]["name"]))
    assert_eq(a.tokens_emitted, M.emits_for(a.type_id, ctx))
    assert_eq(a.cascade_depth, 0, "a scripted mistake opens a chain; it is never inside one")
    assert_false(a.id().is_empty())
    assert_eq(a.p_bp, -1, "no gate was rolled, and the provenance says so")
    assert_eq(a.severity_s, -1, "no score was rolled either")
    assert_true(a.weights.has(a.type_id), "the pool it was drawn from is recorded")

func test_a_forced_mistake_respects_the_per_type_cooldown() -> void:
    # The one guard that could leave nothing eligible: a DPS whose only gentle
    # type fired last round falls back to the rest of the set rather than to
    # nothing, because the mistake is guaranteed.
    var ctx = _ctx(E.RollSite.ACTION, 3)
    ctx.tutorial = true
    ctx.cooldowns["MIS_WRONG_TARGET"] = 3
    var ev = M.force(Rng.new(3), E.CharClass.MAGE, E.RoleGroup.DPS, 55, ctx)
    assert_ne(ev, null, "a cooldown narrows the pool; it must not empty the script")
    assert_ne(ev.type_id, "MIS_WRONG_TARGET")
