extends "res://tests/TestCase.gd"
## W3-RAIDVIEW2: the beats (00-plan §W3-RAIDVIEW2) — the Verb→verb table, the
## wipe on the page, the settle, the pause, the boss plate, the gated exits.
##
## The screen is mounted the way test_raid_overlays.gd mounts it (the real
## router autoload with a host under the tree root, a wiped t1_raid_e5 account,
## seed 5). For the verbs a PROBE stage built through `SceneStage.from_data`
## (two figures and a boss, no scene file) is swapped in for the screen's own,
## so what each Verb does to the floor is observable: the stage's clock is
## stepped by hand (`stage._process`), the way test_scene_stage.gd steps it,
## because nothing in the unit suite is inside a tree (RULES §1).

const RaidView = preload("res://game/screens/RaidView.gd")
const SceneStage = preload("res://game/ui/SceneStage.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Settings = preload("res://game/core/GameSettings.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const EventLog = preload("res://sim/core/EventLog.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Combatant = preload("res://sim/model/Combatant.gd")
const LogPlayer = preload("res://game/core/LogPlayer.gd")

const RAID_VIEW := "res://game/screens/RaidView.tscn"
const SRC := "res://game/screens/RaidView.gd"

var _db = null
var _root: Node = null
var _made: Array = []


func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    var loop := Engine.get_main_loop()
    _root = (loop as SceneTree).root if loop is SceneTree else null
    _made = []


func after_each() -> void:
    var st = _root.get_node_or_null("GameState")
    if st != null and not (st in _made):
        st.reset()
        st.set_content(null)
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []


## The settings autoload, or one for this test (a screen caches it at build,
## so it has to exist BEFORE `_screen()`).
func _settings():
    var gs = _root.get_node_or_null("GameSettings")
    if gs == null:
        gs = Settings.new()
        gs.name = "GameSettings"
        _root.add_child(gs)
        _made.append(gs)
    return gs


func _screen():
    var st = _root.get_node_or_null("GameState")
    if st == null:
        st = GameStateScript.new()
        st.name = "GameState"
        _root.add_child(st)
        _made.append(st)
    if _root.get_node_or_null("ScreenRouter") == null:
        var rt = Router.new()
        rt.name = "ScreenRouter"
        _root.add_child(rt)
        _made.append(rt)
    st.reset()
    st.set_content(_db)
    st.new_game("Beats Guild", 31)
    var enc = _db.encounter("t1_raid_e5")
    var party: Array = st.roster.slice(0, mini(int(enc.party_size), st.roster.size()))
    var result = RaidSim.run(party, enc, _db, 5, st.build_loadout(party))
    result.outcome = RaidSim.Outcome.WIPE
    st.last_result = result
    st.last_party = party.duplicate()
    st.selected_encounter_id = "t1_raid_e5"
    var host := Control.new()
    _root.add_child(host)
    _made.append(host)
    var r = Router.new()
    _made.append(r)
    r.register_host(host)
    assert_true(r.goto(RAID_VIEW), "the raid view must mount")
    return r.current_screen()


## A probe stage swapped in for the screen's: the party's first two raiders as
## a warrior and a cleric strip on a bare floor, the boss a plain texture to
## the right. Returns {stage, a, b, boss} — ids and sprites.
func _probe(view, a: String = "", b: String = "") -> Dictionary:
    if a.is_empty():
        a = String(view._party[0].id)
    if b.is_empty():
        b = String(view._party[1].id) if String(view._party[1].id) != a else String(view._party[0].id)
    var stage: Control = SceneStage.from_data("probe", {"actors": []})
    _made.append(stage)
    var sprs: Dictionary = stage.place_party([
        {"who": "warrior", "pos": [200, 300], "id": a},
        {"who": "cleric", "pos": [260, 300], "id": b},
    ])
    var img := Image.create(40, 60, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.5, 0.2, 0.2, 1))
    var boss = stage.place_boss(ImageTexture.create_from_image(img), Vector2(500, 300))
    view._stage_node = stage
    view._party_sprites = sprs
    view._boss_sprite = boss
    return {"stage": stage, "a": a, "b": b, "spr_a": sprs[a], "spr_b": sprs[b], "boss": boss}


func _texts(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _texts(c, out)
    return out


func _find_named(n: Node, name: String, out: Array = []) -> Array:
    if String(n.name) == name:
        out.append(n)
    for c in n.get_children():
        _find_named(c, name, out)
    return out


func _find_button(n: Node, text: String) -> Button:
    if n is Button and (n as Button).text == text:
        return n
    for c in n.get_children():
        var b := _find_button(c, text)
        if b != null:
            return b
    return null


## Names of the stage's children that begin with `prefix` (the effects the
## verbs leave: "Fx_<strip>_N", "Burst_<kind>_N", "Trail_N").
func _effects(stage: Node, prefix: String) -> Array:
    var out: Array = []
    for c in stage.get_children():
        if String(c.name).begins_with(prefix):
            out.append(c)
    return out


func _combatant(view, id: String):
    for r in view._party:
        if String(r.id) == id:
            return Combatant.create(r, _db, 0)
    return null


func _mistake_by(view, id: String):
    var log = EventLog.new()
    return log.emit_mistake(2, Enums.Phase.DPS, _combatant(view, id), "MIS_AGGRO",
        "Pulled Aggro Off the Tank", Enums.severity_key(Enums.Severity.SEVERE),
        "", 0, "MIS_AGGRO.01", "A joke for the bubble.")


# ------------------------------------------------------------ the switch

func test_exits_gated_is_the_plans_default_and_the_exits_are_live() -> void:
    # Q12c (00-plan §0.6): `false` until the designer rules.
    assert_false(RaidView.EXITS_GATED, "COMBAT-14's gate stays off (Q12c)")
    var view = _screen()
    var back := _find_button(view, "Back to the board")
    var onward := _find_button(view, "The report")
    assert_true(back != null and onward != null, "both exits are Buttons")
    assert_false(back.disabled, "live from the first line under the default")
    assert_false(onward.disabled)
    assert_false(RaidView.EXITS_REASON in _texts(view), "no reason printed while ungated")


func test_the_gate_behind_the_switch_locks_and_releases_the_exits() -> void:
    var view = _screen()
    view._gate_exits()
    var back := _find_button(view, "Back to the board")
    var onward := _find_button(view, "The report")
    assert_true(back.disabled and onward.disabled, "gated: both exits locked")
    var reasons: Array = []
    for t in _texts(view):
        if String(t) == RaidView.EXITS_REASON:
            reasons.append(t)
    assert_eq(reasons.size(), 2, "one reason Label under each exit (docs/13 §7)")
    assert_eq(back.focus_mode, Control.FOCUS_ALL)
    assert_eq(onward.focus_mode, Control.FOCUS_ALL)
    assert_true(view._retry_button == back, "§11.4's focus target is still the paper exit")
    # The account finishes: the exits open.
    view._release_exits()
    assert_false(back.disabled, "released")
    assert_false(onward.disabled)
    assert_almost(back.modulate.a, 1.0, 0.001, "and undimmed")
    var shown := 0
    for why in _find_named(view, "Reason"):
        if (why as Control).visible and String((why as Label).text) == RaidView.EXITS_REASON:
            shown += 1
    assert_eq(shown, 0, "the reasons are gone once the exits are live")
    view._release_exits()
    assert_false(back.disabled, "releasing twice is harmless")


# ------------------------------------------------------------ Q18's default

func test_the_role_table_covers_every_role_and_records_q18s_default() -> void:
    for role in Enums.ROLE_KEYS:
        assert_true(RaidView.VFX_FAMILY.has(role), "VFX_FAMILY has a row for %s" % role)
        var fam: Dictionary = RaidView.VFX_FAMILY[role]
        assert_true(String(fam["attack"]) in ["slash", "bolt"], "%s attacks by slash or bolt" % role)
        assert_true(SceneStage.BURST_KINDS.has(String(fam["kind"])),
            "%s's burst kind is one the stage draws" % role)
        assert_true(SceneStage.BURST_KINDS.has(String(fam["support"])))
    # The recommended default, as recorded: melee slash, casters bolt.
    for melee in ["main_tank", "melee_dps_offtank", "melee_dps"]:
        assert_eq(String(RaidView.VFX_FAMILY[melee]["attack"]), "slash")
    for caster in ["aoe_caster", "single_target_caster", "main_tank_healer", "raid_healer", "chain_healer", "support"]:
        assert_eq(String(RaidView.VFX_FAMILY[caster]["attack"]), "bolt")
    assert_eq(String(RaidView.BOSS_FAMILY["attack"]), "burst", "the boss has nothing to slash with")


# ------------------------------------------------------------ COMBAT-21 / RULES-04

func test_the_wipe_docstrings_tell_the_truth() -> void:
    var src := FileAccess.get_file_as_string(SRC)
    assert_false(src.contains("has no blot"), "the blot exists (RULES-04)")
    assert_false(src.contains("art that does not exist"), "both textures exist (COMBAT-21)")
    assert_true(src.contains("wipe_blot.png") and src.contains("wax_seal.png"),
        "the docstring names the assets")
    assert_true(src.contains("gen_wipe.lua"), "and their generator")


func test_the_boss_is_held_as_a_node2d() -> void:
    # W3-ENEMIES turns `place_boss`'s Sprite2D into an AnimatedSprite2D this
    # wave; the screen must not care which.
    var src := FileAccess.get_file_as_string(SRC)
    assert_true(src.contains("var _boss_sprite: Node2D = null"))
    assert_false(src.contains("_boss_sprite: Sprite2D"))


# ------------------------------------------------------------ COMBAT-15

func test_the_stamp_presses_across_the_log_panel_and_the_seal_straddles_its_corner() -> void:
    var view = _screen()
    view._run_wipe_sequence(float(RaidView.WIPE_BEAT_EXITS_MS))
    var log_rect: Rect2 = RaidView.LOG_RECT
    var box: Control = view._wipe_stamp_label.get_parent()
    var centre: Vector2 = box.position + box.size * 0.5
    assert_true(log_rect.has_point(centre),
        "the WIPE. box is centred on the log panel, not the arena (%s)" % str(centre))
    assert_true(RaidView.WIPE_STAMP_RECT.intersects(log_rect))
    assert_true(view._wipe_blot != null, "the bleed is on the page")
    var blot: Rect2 = Rect2(view._wipe_blot.position, view._wipe_blot.size)
    assert_true(log_rect.encloses(blot), "the ink bleeds into the panel: %s" % str(blot))
    var cost := _find_named(view, "WipeCost")
    assert_eq(cost.size(), 1)
    assert_true(log_rect.has_point((cost[0] as Control).position + Vector2(4, 4)),
        "the cost line sits beneath the stamp inside the panel")
    assert_true(view._wax_seal != null)
    var rest: Vector2 = RaidView.WAX_SEAL_REST
    assert_eq(view._wax_seal.position, rest, "outside a tree the seal is simply at its rest")
    var seal_h: float = view._wax_seal.size.y
    assert_true(rest.y < log_rect.end.y and rest.y + seal_h > log_rect.end.y,
        "the seal straddles the panel's bottom edge")
    assert_true(rest.x + view._wax_seal.size.x <= log_rect.end.x, "inside its right edge")
    assert_true(rest.y <= 952.0, "COMBAT-15's corrected rest: y <= 952")
    assert_true(rest.x > RaidView.FRAME.x * 0.5 and rest.y > RaidView.FRAME.y * 0.5,
        "and still right and low for test_wipe_sequence")
    assert_true(view._wipe_blot.get_index() < box.get_index(), "ink under the stamp")


# ------------------------------------------------------------ COMBAT-17

func _attack_on_first(view, amount: int, round_no: int = 1):
    var log = EventLog.new()
    var target = Combatant.create(view._party[0], _db, 0)
    return log.emit_attack(round_no, Enums.Phase.DPS, "Trash", target, amount,
        maxi(0, int(view._party[0].max_hp(_db)) - amount))


func test_a_log_row_lands_in_a_settle_wrapper() -> void:
    assert_eq(Widgets.Motion.LOG_SETTLE, 90, "docs/13 §12.2's 90 ms")
    var view = _screen()
    view._append_line(_attack_on_first(view, 9, 1))
    var wrap = view._log_rows.back()
    assert_true(wrap is MarginContainer and String(wrap.name) == "Settle",
        "the row is inside the settle wrapper the age ramp dims")
    assert_eq(wrap.get_child_count(), 1)
    assert_eq(wrap.get_theme_constant("margin_top"), 0,
        "outside a tree there is no tween: the margin is 0 at once (arrive instantly)")
    assert_eq(wrap.get_parent(), view._log_col)


func test_the_round_divider_carries_a_rule() -> void:
    var view = _screen()
    view._append_line(_attack_on_first(view, 5, 3))
    var markers := _find_named(view, "Round_3")
    assert_eq(markers.size(), 1, "one divider for round 3")
    assert_true("Round 3" in _texts(markers[0]), "the word is a Label")
    var rules := _find_named(markers[0], "Rule")
    assert_eq(rules.size(), 1)
    assert_true(rules[0] is ColorRect and (rules[0] as ColorRect).color == Palette.EDGE_SLATE,
        "a 1px EDGE_SLATE rule (COMBAT-17)")
    assert_eq(int((rules[0] as Control).custom_minimum_size.y), 1)


func test_a_phase_row_is_a_heading_not_a_line_of_the_account() -> void:
    # CRITIC-G13's Numbers-mode finding: "-- Pull --" is a divider.
    var view = _screen()
    var before: int = view._log_rows.size()
    var log = EventLog.new()
    view._append_line(log.emit_phase(1, Enums.Phase.DPS))
    assert_eq(view._log_rows.size(), before, "no age-ramp row, no settle")
    var printed := "\n".join(PackedStringArray(_texts(view)))
    assert_true(printed.contains("--"), "the phase's own text is still printed")
    assert_true(view._bar_ids.is_empty(), "a phase line switches no over-head bar")


# ------------------------------------------------------------ CRITIC-G13

func test_the_dwell_raises_the_paused_stamp_and_resume_takes_it_down() -> void:
    var gs = _settings()
    var before = gs.get_value("log_manual_advance")
    gs.set_value("log_manual_advance", true)
    var view = _screen()
    var e = _mistake_by(view, String(view._party[0].id))
    view._append_line(e)
    view._dwell_on(e)
    gs.set_value("log_manual_advance", before)
    assert_true(view.player().paused, "the account stops on the mistake")
    var stamps := _find_named(view, "PausedStamp")
    assert_eq(stamps.size(), 1, "the paused Label exists")
    var stamp: Label = stamps[0]
    assert_eq(stamp.text, "PAUSED — mistake")
    assert_true(stamp.visible)
    assert_eq(stamp.get_parent(), view, "on the page, not in the column")
    assert_true(RaidView.LOG_RECT.has_point(stamp.position + Vector2(stamp.size.x, 4)),
        "its right edge is on the log panel")
    assert_true(absf(stamp.rotation_degrees) >= 2.0 and absf(stamp.rotation_degrees) <= 7.0,
        "a static stamp's lean")
    assert_eq(stamp.focus_mode, Control.FOCUS_NONE, "a Label, never a focus stop")
    assert_eq(_find_button(view, "Resume").text, "Resume")
    # Resume takes it down.
    view.player().toggle_pause()
    view._sync_controls()
    assert_false(stamp.visible, "dismissed with the pause")
    assert_false(view._dwelling)


func test_a_players_own_pause_does_not_wear_the_mistakes_word() -> void:
    var view = _screen()
    view.player().paused = true
    view._sync_controls()
    for s in _find_named(view, "PausedStamp"):
        assert_false((s as Control).visible, "no mistake stamp for a pause the player chose")


# ------------------------------------------------------------ CRITIC-G08

func test_at_two_x_no_panel_swaps_its_stylebox_more_than_three_times_a_second() -> void:
    var view = _screen()
    view.player().speed = LogPlayer.Speed.TWO
    view._sync_controls()
    var last: Dictionary = {}
    var swaps: Dictionary = {}
    for id in view._panel_nodes:
        last[id] = view._panel_nodes[id].has_theme_stylebox_override("panel")
        swaps[id] = 0
    for i in 50:
        view._process(0.02)
        for id in view._panel_nodes:
            var panel = view._panel_nodes[id]
            if not is_instance_valid(panel):
                continue
            var now: bool = panel.has_theme_stylebox_override("panel")
            if last.has(id) and now != bool(last[id]):
                swaps[id] = int(swaps.get(id, 0)) + 1
            last[id] = now
    var worst := 0
    for id in swaps:
        worst = maxi(worst, int(swaps[id]))
    assert_true(view.player().revealed_count() > 0, "the second passed lines")
    assert_true(worst <= 3, "docs/13 §13: at most 3 StyleBox changes a second on one panel (saw %d)" % worst)


# ------------------------------------------------------------ COMBAT-05

func test_the_boss_sigil_is_the_rank_glyph_not_the_body() -> void:
    var view = _screen()
    var rank: String = view._boss_rank_key()
    assert_true(rank.begins_with("boss_"), "the rank key is the enemies PNG's name: %s" % rank)
    var slots := _find_named(view, "BossSigil")
    assert_eq(slots.size(), 1)
    var icon: Node = slots[0].get_child(0)
    assert_true(icon is TextureRect and (icon as TextureRect).texture != null)
    var path := String((icon as TextureRect).texture.resource_path)
    assert_true(path.get_file().begins_with("sigil_"), "a bare 48px family glyph: %s" % path)
    assert_eq((icon as TextureRect).texture.get_width(), 48)
    assert_eq(int(RaidView.BOSS_SIGIL.size.x), 48)


func test_the_affix_cells_are_30_at_pitch_34() -> void:
    assert_eq(RaidView.BOSS_AFFIX_CELL, 30)
    assert_eq(RaidView.BOSS_AFFIX_PITCH, 34)
    var view = _screen()
    var xs: Array = []
    for key in view._mech_cells:
        var cell: Control = view._mech_cells[key]
        assert_eq(int(cell.size.x), 30)
        assert_eq(int(cell.size.y), 30)
        assert_eq(int(cell.position.y), 122)
        xs.append(int(cell.position.x))
    xs.sort()
    for i in range(1, xs.size()):
        assert_eq(int(xs[i]) - int(xs[i - 1]), 34, "cells at pitch 34 (spec 02 §9.2)")
    if not xs.is_empty():
        assert_eq(int(xs[0]), 1001)


# ------------------------------------------------------------ the verbs

func test_a_melee_attack_lunges_slashes_bursts_and_recoils_the_boss() -> void:
    var view = _screen()
    var p := _probe(view)
    var log = EventLog.new()
    # The party's first raider swings at the boss — as a melee fighter,
    # whatever its class, so the slash family is what this line exercises.
    var role := ""
    for k in RaidView.VFX_FAMILY:
        if String(RaidView.VFX_FAMILY[k]["attack"]) == "slash":
            role = k
            break
    assert_true(role != "", "some role slashes")
    var e = log.emit_attack(1, Enums.Phase.DPS, _combatant(view, p["a"]), "Main Boss", 30, 100)
    var spr: Node2D = p["spr_a"]
    var boss: Node2D = p["boss"]
    var base: Vector2 = spr.position
    var boss_base: Vector2 = boss.position
    var fam: Dictionary = view._family_of(e)
    view._append_line(e)
    p["stage"]._process(0.03)
    assert_true(spr.position != base, "the attacker lunges (act 'attack')")
    assert_true(boss.modulate == SceneStage.FLASH_COLOR, "the struck boss flashes (hit)")
    var strikes := _effects(p["stage"], "Fx_") + _effects(p["stage"], "Burst_")
    assert_true(strikes.size() >= 1, "a strike (strip or burst) is on the floor")
    if String(fam["attack"]) == "slash":
        assert_true(_effects(p["stage"], "Fx_fx_slash_arc").size() >= 1, "the slash arc over the target")
    else:
        assert_true(_effects(p["stage"], "Fx_fx_bolt").size() >= 1, "the bolt strip on its way")
    p["stage"]._process(1.0)
    assert_true(spr.position.distance_to(base) < 0.01, "and comes back to its mark")
    assert_almost(boss.position.x, boss_base.x, 0.01, "the boss's recoil returned (the bob owns y)")


func test_a_boss_attack_bursts_on_the_raider_and_flashes_them() -> void:
    var view = _screen()
    var p := _probe(view)
    var log = EventLog.new()
    var e = log.emit_attack(1, Enums.Phase.DPS, "Main Boss", _combatant(view, p["a"]), 12, 80)
    var spr: Node2D = p["spr_a"]
    view._append_line(e)
    p["stage"]._process(0.03)
    assert_eq(spr.modulate, SceneStage.FLASH_COLOR, "the struck raider flashes")
    assert_true(_effects(p["stage"], "Burst_impact").size() >= 1 or _effects(p["stage"], "Fx_fx_burst_impact").size() >= 1,
        "the boss's strike is an impact burst on the raider")
    assert_eq(_effects(p["stage"], "Fx_fx_slash_arc").size(), 0, "no slash: the boss holds no blade")


func test_a_heal_lifts_the_healer_and_sparkles_the_healed() -> void:
    var view = _screen()
    var p := _probe(view)
    var log = EventLog.new()
    var e = log.emit_heal(1, Enums.Phase.DPS, _combatant(view, p["b"]), _combatant(view, p["a"]), 20, 90)
    var healer: Node2D = p["spr_b"]
    view._append_line(e)
    p["stage"]._process(0.05)
    assert_true(healer.modulate.b > 1.0, "the cast's emissive lift is on the healer (%s)" % str(healer.modulate))
    var sparkle := _effects(p["stage"], "Fx_fx_heal_sparkle") + _effects(p["stage"], "Burst_heal")
    assert_true(sparkle.size() >= 1, "the sparkle lands on the healed")


func test_a_death_topples_the_figure_and_a_replay_stands_it_up() -> void:
    var view = _screen()
    var p := _probe(view)
    var log = EventLog.new()
    var e = log.emit_state_change(3, Enums.Phase.DPS, _combatant(view, p["a"]), "dead")
    var spr: Node2D = p["spr_a"]
    view._append_line(e)
    assert_true(view._dying.has(p["a"]), "the screen knows the act is running")
    p["stage"]._process(0.6)
    assert_true(absf(spr.rotation) > 0.5, "the 45° topple (act 'death') stays: %f" % spr.rotation)
    view._set_tier(Enums.LogTier.STORY)
    assert_almost(spr.rotation, 0.0, 0.0001, "a replay stands the fallen back up")
    assert_false(view._dying.has(p["a"]))


func test_a_mistake_makes_the_offender_fumble_with_a_mark() -> void:
    var view = _screen()
    var p := _probe(view)
    var spr: Node2D = p["spr_a"]
    var base: Vector2 = spr.position
    view._append_line(_mistake_by(view, p["a"]))
    p["stage"]._process(0.03)
    assert_true(spr.position != base, "the fumble's commit lunge")
    var marks := _find_named(p["stage"], "Mark_%s" % spr.name)
    assert_eq(marks.size(), 1, "the '!' over the head")
    assert_true(marks[0] is Label and (marks[0] as Label).text == "!", "as a Label")


func test_a_mechanic_flares_the_boss_s_eye() -> void:
    var view = _screen()
    var p := _probe(view)
    var log = EventLog.new()
    view._append_line(log.emit_mechanic(2, Enums.Phase.DPS, 0, "The floor shakes."))
    var flare := _effects(p["stage"], "Burst_%s" % RaidView.MECHANIC_BURST)
    assert_true(flare.size() >= 1, "a %s burst at the boss" % RaidView.MECHANIC_BURST)
    var boss: Node2D = p["boss"]
    var eye: Vector2 = view._eye_of(boss)
    assert_true(eye.y < boss.position.y and eye.y > view._stage_node.head_of(boss).y,
        "the eye is in the upper body")
    assert_true((flare[0] as Node2D).position.distance_to(eye) < 1.0)


func test_a_skipped_account_fires_no_flourish_but_the_dead_still_fall() -> void:
    var view = _screen()
    var p := _probe(view)
    var log = EventLog.new()
    view._live = false
    view._append_line(log.emit_attack(1, Enums.Phase.DPS, _combatant(view, p["a"]), "Main Boss", 30, 100))
    assert_eq((_effects(p["stage"], "Fx_") + _effects(p["stage"], "Burst_")).size(), 0,
        "G08: a skip lands no strikes")
    view._append_line(log.emit_state_change(2, Enums.Phase.DPS, _combatant(view, p["b"]), "dead"))
    view._live = true
    p["stage"]._process(0.6)
    assert_true(absf((p["spr_b"] as Node2D).rotation) > 0.5, "the death is a destination and lands on a skip")


func test_reduced_motion_holds_the_verbs_on_their_marks() -> void:
    var view = _screen()
    var p := _probe(view)
    p["stage"].apply_settings(true, false)
    var log = EventLog.new()
    var spr: Node2D = p["spr_a"]
    var base: Vector2 = spr.position
    view._append_line(log.emit_attack(1, Enums.Phase.DPS, _combatant(view, p["a"]), "Main Boss", 30, 100))
    for i in 4:
        p["stage"]._process(0.02)
        assert_eq(spr.position, base, "no lunge under reduced motion")
    assert_eq((p["boss"] as Node2D).modulate, SceneStage.FLASH_COLOR,
        "the hit's flash is information and still lands")


func test_a_fallen_actor_is_not_brightened_by_the_ui_layer() -> void:
    var view = _screen()
    # A REAL death from the account: the fold marks the raider dead by the
    # time the UI layer looks (a synthetic entry is off-stream and folds nothing).
    var e = null
    for x in view._full:
        if LogPlayer.is_death(x) and not String(x.actor_id).is_empty():
            e = x
            break
    assert_true(e != null, "the seed-5 wipe kills somebody")
    var p := _probe(view, String(e.actor_id))
    view.player().speed = LogPlayer.Speed.ONE
    view._append_line(e)
    assert_eq(String(view._raider_state.get(p["a"], "")).to_lower(), "dead", "the fold read the death")
    assert_true(view._dying.has(p["a"]), "and the stage's death act is running")
    for entry in view._lit:
        assert_true(entry["node"] != p["spr_a"], "no 1.15 lift on a figure the death act owns")
    # The fold's refresh leaves the tint to the act while it runs.
    var spr: Node2D = p["spr_a"]
    p["stage"]._process(0.05)
    var mid: Color = spr.modulate
    view._refresh_bars()
    assert_eq(spr.modulate, mid, "a refresh mid-death does not snap the grey under the lerp")


func test_every_stage_call_here_existed_at_the_waves_start() -> void:
    # Rule 7: the screen names only verbs SceneStage.gd carried before this
    # wave; W3-ENEMIES edits that file concurrently.
    var src := FileAccess.get_file_as_string(SRC)
    var stage_src := FileAccess.get_file_as_string("res://game/ui/SceneStage.gd")
    for fn in ["act(", "hit(", "burst(", "bolt(", "slash(", "head_of(", "place_boss(",
            "place_party(", "say_at(", "number_at(", "bar_for(", "apply_settings(", "motion_held("]:
        if src.contains("_stage_node." + fn) or src.contains("stage." + fn):
            assert_true(stage_src.contains("func " + fn), "SceneStage has %s" % fn)


# ------------------------------------------------------------ W6-LOG: nothing cut, the tape

func _audio() -> Node:
    return _root.get_node_or_null("Audio") if _root != null else null


func _tape(a: Node) -> Array:
    var out: Array = []
    for row in a.tape:
        out.append(String(row["hook"]))
    return out


func test_no_revealed_mistake_header_or_quote_clips_and_every_row_is_whole_pitches() -> void:
    # LOOP-11 / UI-19 / CONTENT-15 / UI-35: the whole seed-5 wipe read through
    # `_on_skip()` (`reveal_all` -> `_append_line`), then every row of the
    # column inspected. Outside a tree a Label never lays out, so the check is
    # the screen's own arithmetic (`text_lines` at the width `_append_line`
    # gave the Label) against the Label's `max_lines_visible`, plus the shape
    # that makes it true on screen: no trimming, no clip, the full text in
    # `Label.text`, and every child of the column a whole number of pitches so
    # the scroll's end lands on a row.
    var view = _screen()
    view._on_skip()
    var pitch: int = Widgets.LOG_ROW_PITCH
    var hf: Array = Widgets.font_of("LabelLog", view)
    var qf: Array = Widgets.font_of("LabelQuote", view)
    var mistakes: Array = []
    for e in view.player().revealed():
        if e.is_mistake():
            mistakes.append(e)
    assert_true(mistakes.size() >= 3, "the seed-5 wipe fumbles at least three times")
    var headers := 0
    var quotes := 0
    for child in view._log_col.get_children():
        var c := child as Control
        # A Settle wrapper (`_log_rows` holds them in order; sibling names are
        # not unique) carries no minimum of its own; the row inside does.
        var settled: bool = c in view._log_rows
        var sized: Control = c.get_child(0) if settled else c
        var h: int = int(sized.custom_minimum_size.y)
        assert_true(h > 0 and h % pitch == 0,
            "%s is %dpx — not a whole number of %dpx pitches" % [sized.name, h, pitch])
        if not settled:
            continue
        var inner: Control = sized
        if inner is MarginContainer:
            var q := inner.get_child(0) as Label
            quotes += 1
            assert_eq(q.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
            assert_eq(q.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING)
            assert_false(q.clip_text)
            assert_false(q.text.ends_with("…") or q.text.ends_with("…\""), q.text)
            assert_true(q.max_lines_visible >= RaidView.QUOTE_LINES)
            var need: int = RaidView.text_lines(qf[0], int(qf[1]), q.text, q.size.x)
            assert_true(need <= q.max_lines_visible,
                "a quote needs %d lines and may show %d: %s" % [need, q.max_lines_visible, q.text])
            assert_eq(int(inner.custom_minimum_size.y), pitch * q.max_lines_visible)
            continue
        var row := inner as HBoxContainer
        if row == null or _find_named(row, "Stamp").is_empty():
            continue
        headers += 1
        var l := row.get_child(row.get_child_count() - 1) as Label
        assert_eq(l.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
        assert_eq(l.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING)
        assert_false(l.clip_text)
        assert_false(l.text.ends_with("…"), l.text)
        assert_eq(l.max_lines_visible, RaidView.HEADER_LINES)
        var lines: int = RaidView.text_lines(hf[0], int(hf[1]), l.text, l.size.x)
        assert_true(lines <= RaidView.HEADER_LINES, "%s needs %d lines" % [l.text, lines])
        assert_eq(h, pitch * lines, "the header row is sized to its lines")
    assert_eq(headers, mistakes.size(), "one header row per revealed mistake")
    var joked := 0
    for e in mistakes:
        if not String(e.joke()).is_empty():
            joked += 1
            var want := '"%s"' % String(e.joke())
            assert_true(want in _texts(view), "the whole joke is a Label: " + want)
        assert_true(LogPlayer.mistake_header(e) in _texts(view),
            "the whole header is a Label: " + LogPlayer.mistake_header(e))
    assert_eq(quotes, joked, "one quote row per joke")
    # UI-35: the viewport is whole rows too, so the account's end is a boundary.
    assert_eq(int(view._scroll.size.y), pitch * RaidView.LOG_VISIBLE_ROWS)
    assert_eq(RaidView.snap_scroll(float(pitch * 5 + 11)), pitch * 5)
    assert_eq(RaidView.snap_scroll(-3.0), 0)


func test_three_mistakes_at_one_x_tape_three_stamps_and_three_blots() -> void:
    # AUDIO-04(b): `ui.stamp` and `ui.blot` fire from the mistake block of
    # `_append_line`, before the row is built, with `{"live": true}` while the
    # account is read at 1x.
    var a := _audio()
    assert_true(a != null, "the Audio autoload is registered")
    a.ensure_wired()
    a.debug_tape = true
    a.tape = []
    var view = _screen()
    view.player().speed = LogPlayer.Speed.ONE
    var p := _probe(view)
    var log = EventLog.new()
    for i in 3:
        view._append_line(log.emit_mistake(i + 1, Enums.Phase.DPS, _combatant(view, p["a"]),
            "MIS_AGGRO", "Pulled Aggro Off the Tank", Enums.severity_key(Enums.Severity.SEVERE),
            "", 0, "MIS_AGGRO.01", "A joke for the tape."))
    view._append_line(log.emit_attack(4, Enums.Phase.DPS, _combatant(view, p["a"]), "Main Boss", 30, 100))
    var tape := _tape(a)
    a.debug_tape = false
    a.tape = []
    a.advance_duck(999.0)
    assert_eq(tape.count("ui.stamp"), 3, str(tape))
    assert_eq(tape.count("ui.blot"), 3, str(tape))
    assert_eq(tape.size(), 6, "an ordinary line tapes nothing: %s" % str(tape))
    for i in 3:
        assert_eq(tape[i * 2], "ui.stamp", "the stamp before its blot")
        assert_eq(tape[i * 2 + 1], "ui.blot")


func test_a_wipe_tapes_silence_then_the_stamp_then_the_seal_in_order() -> void:
    # AUDIO-16: the wipe's beats sound — `ui.silence` at t=0, the stamp's
    # sound on frame 1 of the WIPE. press, the wax on the seal's drop — each
    # once, in the doc's order, whether watched or skipped through `_on_skip`
    # (every beat in one frame).
    var a := _audio()
    assert_true(a != null)
    a.ensure_wired()
    a.debug_tape = true
    a.tape = []
    var view = _screen()
    view._live = false
    view._run_wipe_sequence(float(RaidView.WIPE_BEAT_EXITS_MS))
    view._run_wipe_sequence(float(RaidView.WIPE_BEAT_EXITS_MS))
    var tape := _tape(a)
    a.debug_tape = false
    a.tape = []
    a.advance_duck(999.0)
    assert_eq(tape, ["ui.silence", "ui.stamp", "ui.seal"], str(tape))


# ------------------------------------------------ W7-REPORT: focus, Esc, the title, the cause

const Scenarios = preload("res://tests/golden/Scenarios.gd")
const TOWN := "res://game/screens/Town.tscn"


## The screen mounted on an attempt at `enc_id` by `roster` (the game's own
## suggested party when empty), through a router `r` the test holds — with
## `under` pushed first when the stack shape matters (Esc pops, or must not).
func _screen_on(enc_id: String, roster: Array = [], seed_value: int = 5, under: String = "") -> Dictionary:
    var st = _root.get_node_or_null("GameState")
    if st == null:
        st = GameStateScript.new()
        st.name = "GameState"
        _root.add_child(st)
        _made.append(st)
    if _root.get_node_or_null("ScreenRouter") == null:
        var rt = Router.new()
        rt.name = "ScreenRouter"
        _root.add_child(rt)
        _made.append(rt)
    st.reset()
    st.set_content(_db)
    st.new_game("Beats Guild", 31)
    var enc = _db.encounter(enc_id)
    var party: Array = roster
    if party.is_empty():
        party = st.roster.slice(0, mini(int(enc.party_size), st.roster.size()))
    var result = RaidSim.run(party, enc, _db, seed_value, st.build_loadout(party))
    st.last_result = result
    st.last_party = party.duplicate()
    st.selected_encounter_id = enc_id
    var host := Control.new()
    _root.add_child(host)
    _made.append(host)
    var r = Router.new()
    _made.append(r)
    r.register_host(host)
    if not under.is_empty():
        assert_true(r.goto(under), "the screen under the account must mount")
        assert_true(r.push(RAID_VIEW), "the raid view must mount over it")
    else:
        assert_true(r.goto(RAID_VIEW), "the raid view must mount")
    return {"view": r.current_screen(), "router": r, "state": st, "result": result}


func _cancel_event() -> InputEventAction:
    var ev := InputEventAction.new()
    ev.action = "ui_cancel"
    ev.pressed = true
    return ev


func test_focus_opens_on_pause() -> void:
    # UI-33 / CRITIC-R4: the one control a watching player needs. The router's
    # hook asks the screen by name; the screen answers with the Pause button.
    var view = _screen()
    var pause: Control = view.default_focus()
    assert_true(pause is Button and (pause as Button).text == "Pause", "default_focus() is Pause")
    assert_eq(pause.focus_mode, Control.FOCUS_ALL)
    assert_true(Router.initial_focus_target(view) == pause,
        "and the router takes the screen's answer over tree order")


func test_escape_mid_replay_skips_to_the_post_mortem_and_never_pops_the_account() -> void:
    # SHIP-03's Esc rule (the attempts ruling): while the account is being
    # read, Esc is the screen's and means "skip to the end" — the router
    # defers by name, so the stack under the account is never popped.
    var m := _screen_on("t1_raid_e5", [], 5, TOWN)
    var view = m["view"]
    var r = m["router"]
    assert_eq(r.depth(), 2, "an account over the town, so a pop would be visible")
    assert_false(view.player().is_finished(), "mid-replay: nothing has been read yet")
    assert_true(view.handles_cancel(), "the screen claims Esc while reading")
    assert_true(r.screen_handles_cancel(), "…and the router sees the claim")
    var ev := _cancel_event()
    r._unhandled_input(ev)
    assert_eq(r.current_path(), RAID_VIEW, "the router did not pop the account")
    assert_eq(r.depth(), 2)
    view._unhandled_input(ev)
    assert_true(view.player().is_finished(), "the screen skipped to the post-mortem")
    assert_eq(r.current_path(), RAID_VIEW, "…on this screen, never the menu")
    assert_true(_texts(view).has("WIPE.") or not view._is_wipe(),
        "a wiped account has its stamp after the skip")
    assert_false(view.handles_cancel(), "the account is read: Esc is the router's again")
    assert_false(r.screen_handles_cancel())
    r._unhandled_input(ev)
    assert_eq(r.current_path(), TOWN, "docs/13 §13.1's binding stands once the claim is released")
    assert_ne(r.current_path(), "res://game/screens/MainMenu.tscn")


func test_the_boss_plate_prints_the_title_when_the_record_carries_one() -> void:
    # BL-119: "The Doorman" in the title slot, the ladder words as the
    # subtitle; a record with no title prints its display_name as before.
    var plain = _screen()
    var name_l := _find_named(plain, "BossTitle")
    assert_eq(name_l.size(), 1)
    assert_eq((name_l[0] as Label).text, "Raid 1 — Encounter 5", "no title: the display name, as today")
    assert_eq(_find_named(plain, "BossSubtitle").size(), 0, "and no subtitle line")
    var tr = _db.encounter("t1_tut_tr")
    assert_eq(String(tr.title), "The Doorman", "TR's record carries its title")
    var st = _root.get_node("GameState")
    st.reset()
    st.set_content(_db)
    st.new_game("Beats Guild", 31)
    var party: Array = st.roster.slice(0, 6)
    var m := _screen_on("t1_tut_tr", party)
    var view = m["view"]
    var titled := _find_named(view, "BossTitle")
    assert_eq(titled.size(), 1)
    assert_eq((titled[0] as Label).text, "The Doorman")
    var sub := _find_named(view, "BossSubtitle")
    assert_eq(sub.size(), 1, "the ladder words drop to a subtitle")
    assert_eq((sub[0] as Label).text, "Tutorial Raid · Main Boss")
    assert_true(view._boss_bar.position.y > RaidView.BOSS_BAR.position.y,
        "the bar steps down to make the second line's room")
    assert_true(view._boss_bar.position.y + view._boss_bar.size.y <= RaidView.BOSS_PLATE.end.y,
        "…and stays inside 02 §3.1's plate")
    assert_eq(String(tr.enemies[0].name), "Tutorial Boss", "the enemy's log name is untouched")


func test_the_wipe_beat_points_at_the_cause_row() -> void:
    # LOOP-12: the live log's "It traces back to …" row is kept by the screen
    # so the wipe's final-line beat can bring it into view — the same entry
    # the report's sentence names. The golden's worst case has one.
    var spec: Dictionary = Scenarios.SCENARIOS["e5_miserable_commons"]
    var roster: Array = Scenarios.build_roster(spec, _db)
    var m := _screen_on("t1_raid_e5", roster, int(spec["seed"]))
    var view = m["view"]
    var res = m["result"]
    assert_false(res.wipe_cause.is_empty(), "the golden names a culprit")
    assert_true(view._cause_row == null, "nothing read yet, nothing to point at")
    view._on_skip()
    assert_true(view._cause_row != null, "after the read the cause row is kept")
    assert_true(view._cause_row.get_parent() == view._log_col, "…and it is a row of the log")
    var words := "\n".join(PackedStringArray(_texts(view._cause_row)))
    assert_true(words.contains("It traces back to"), words)
    var e = res.log.entries[int(res.wipe_cause["entry_seq"])]
    assert_true(words.contains(String(e.actor_name)), "names the culprit: " + words)
    var cause_entries := 0
    for entry in res.log.entries:
        if String(entry.template_id) == "wipe_cause":
            cause_entries += 1
            assert_eq(view._row_style(entry)[0], Palette.DANGER, "the cause line reads in the wipe's ink")
    assert_eq(cause_entries, 1, "the sim files the cause once")


func test_a_raid_carries_no_lesson_band() -> void:
    # BL-141: the band is the tutorials'. E5 is not one.
    assert_true(RaidView.TUTORIAL_BAND, "the ruling: the band ships")
    var view = _screen()
    assert_eq(_find_named(view, "LessonBand").size(), 0)
