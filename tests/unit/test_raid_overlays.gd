extends "res://tests/TestCase.gd"
## W2-RAIDVIEW: the fight on the floor and the strip (00-plan §W2-RAIDVIEW).
##
## What a screen test can see is `Label.text` and the tree (RULES §1), so every
## assertion here is about a Label, a node name, a sibling index or a member the
## screen exposes — never a pixel. The shots are the other half of the evidence
## and live in build/plan/report-W2-RAIDVIEW.md.
##
## The screen is mounted the way test_wipe_sequence.gd mounts it: the real
## router autoload with a host under the tree root, a wiped account on the
## t1_raid_e5 fixture, seed 5 — the account the wipe tests already read.

const RaidView = preload("res://game/screens/RaidView.gd")
const Settings = preload("res://game/core/GameSettings.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const EventLog = preload("res://sim/core/EventLog.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Combatant = preload("res://sim/model/Combatant.gd")
const LogPlayer = preload("res://game/core/LogPlayer.gd")
const Type = preload("res://game/ui/Type.gd")

const RAID_VIEW := "res://game/screens/RaidView.tscn"

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
    # The autoload outlives this file (LESSONS): put its content back.
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


## A mounted RaidView on a wiped account (never cleared before: the skip is
## locked, which is the state COMBAT-04 is about). `prior_clears` > 0 mounts
## it as an encounter the guild had already cleared, which unlocks the skip.
func _screen(prior_clears: int = 0):
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
    st.new_game("Overlay Guild", 31)
    var enc = _db.encounter("t1_raid_e5")
    var party: Array = st.roster.slice(0, mini(int(enc.party_size), st.roster.size()))
    var result = RaidSim.run(party, enc, _db, 5, st.build_loadout(party))
    result.outcome = RaidSim.Outcome.WIPE
    st.last_result = result
    st.last_party = party.duplicate()
    st.selected_encounter_id = "t1_raid_e5"
    if prior_clears > 0:
        st.cleared["t1_raid_e5"] = prior_clears

    var host := Control.new()
    _root.add_child(host)
    _made.append(host)
    var r = Router.new()
    _made.append(r)
    r.register_host(host)
    assert_true(r.goto(RAID_VIEW), "the raid view must mount")
    return r.current_screen()


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


func _labels_starting(n: Node, prefix: String, out: Array = []) -> Array:
    if n is Label and String((n as Label).text).begins_with(prefix):
        out.append(n)
    for c in n.get_children():
        _labels_starting(c, prefix, out)
    return out


## An ATTACK entry from the boss onto the party's first raider, shaped as the
## sim emits one (a Combatant target carries the raider's id).
func _attack_on(view, amount: int, round_no: int = 1):
    var log = EventLog.new()
    var target = Combatant.create(view._party[0], _db, 0)
    return log.emit_attack(round_no, Enums.Phase.DPS, "Trash", target, amount,
        maxi(0, int(view._party[0].max_hp(_db)) - amount))


## The first entry of the ACCOUNT (the Play-by-play stream the fold reads)
## that `pred` accepts. The fold consumes the real stream up to a revealed
## line's sequence, so a test about the fold must feed it a real line — a
## synthetic entry from a fresh EventLog is off-stream and folds nothing.
func _first_real(view, pred: Callable):
    for e in view._full:
        if pred.call(e):
            return e
    return null


func _first_mistake_with_a_joke(view):
    var e = _first_real(view, func(x) -> bool:
        return x.is_mistake() and not String(x.actor_id).is_empty() and not String(x.joke()).is_empty())
    assert_true(e != null, "the seed-5 wipe carries a mistake with a corpus joke")
    return e


func _mistakes_by_before(view, id: String, sequence: int) -> int:
    var n := 0
    for e in view._full:
        if e.sequence <= sequence and e.is_mistake() and String(e.actor_id) == id:
            n += 1
    return n


# ------------------------------------------------------------ COMBAT-02

func test_an_attack_line_yields_a_damage_number_label_whose_text_never_changes() -> void:
    var view = _screen()
    view._append_line(_attack_on(view, 317))
    var numbers := _find_named(view, "DamageNumber")
    assert_eq(numbers.size(), 1, "one number for one struck figure: %d" % numbers.size())
    var l: Label = numbers[0]
    assert_eq(l.text, "-317", "the value is the entry's amount, signed")
    # docs/13 §12.2: numbers are instant, never tweened in value. Nothing that
    # runs after the spawn may touch the text — the fold, a frame, a refresh.
    view._refresh_bars()
    view._process(0.05)
    view._process(0.5)
    assert_eq(l.text, "-317", "the number's text never changes after it lands")
    assert_true(l.get_parent() != null and String(l.get_parent().name) == "Overlay",
        "the number lives in the stage's overlay layer, over the figures")
    # Within 120px of the struck figure's head (the acceptance's own number):
    # the overlay is in stage space, and so is `head_of`.
    var struck := String(view._party[0].id)
    if view._party_sprites.has(struck):
        var head: Vector2 = view._stage_node.head_of(view._party_sprites[struck])
        var centre: Vector2 = l.position + l.size * 0.5
        assert_true(centre.distance_to(head) <= 120.0,
            "the number hangs over the struck figure (%s vs head %s)" % [centre, head])


func test_a_heal_prints_a_plus_and_a_boss_hit_prints_a_minus() -> void:
    var view = _screen()
    var log = EventLog.new()
    var who = Combatant.create(view._party[0], _db, 0)
    view._append_line(log.emit_heal(1, Enums.Phase.DPS, "Cleric", who, 40,
        int(view._party[0].max_hp(_db))))
    var texts := []
    for n in _find_named(view, "DamageNumber"):
        texts.append((n as Label).text)
    assert_true("+40" in texts, "a heal prints +N: %s" % str(texts))


func test_a_skipped_account_lands_no_numbers() -> void:
    # `_on_skip` reveals every line in one frame; two hundred labels rising
    # at once would be noise, and G08 turns the per-line layer off at Instant.
    var view = _screen()
    view._on_skip()
    assert_eq(_find_named(view, "DamageNumber").size(), 0)
    assert_true(view.player().is_finished())


# ------------------------------------------------------------ COMBAT-09

func test_the_fold_counts_blots_per_actor_and_the_panels_wear_them() -> void:
    var view = _screen()
    view._on_skip()
    var expected := {}
    for e in view.player().revealed():
        if e.is_mistake() and not String(e.actor_id).is_empty():
            expected[e.actor_id] = int(expected.get(e.actor_id, 0)) + 1
    var total := 0
    for r in view._party:
        var id := String(r.id)
        assert_eq(view.blots_of(id), int(expected.get(id, 0)),
            "%s's blots must be their MISTAKE entries" % r.display_name)
        total += view.blots_of(id)
    assert_eq(total, view.mistakes_seen(), "the per-raider ink sums to the counter")
    # The panels on the current page carry exactly their raider's count.
    for id in view._panel_blots:
        var host: Control = view._panel_blots[id]
        assert_eq(int(host.get_meta("count", -1)), view.blots_of(id),
            "the status row's blot host follows the fold")


func test_a_mistake_row_carries_a_blot_a_stamp_and_the_whole_line_last() -> void:
    var view = _screen()
    var e = _first_mistake_with_a_joke(view)
    view._append_line(e)
    var stamps := _find_named(view, "Stamp")
    assert_true(stamps.size() >= 1, "the MISTAKE stamp box is on the row")
    var stamp: Node = stamps[0]
    assert_eq(String((stamp.get_child(0) as Label).text), "MISTAKE",
        "the stamp's word is a Label (docs/13 §7: always readable text)")
    var row: Node = stamp.get_parent()
    assert_true(_find_named(row, "Blot").size() == 1, "the margin blot is on the row")
    var last := row.get_child(row.get_child_count() - 1)
    assert_true(last is Label and String((last as Label).text).contains(String(e.mistake_name())),
        "the row's last child is still the header Label test_log_player reads")
    assert_eq(view.blots_of(String(e.actor_id)), _mistakes_by_before(view, String(e.actor_id), e.sequence),
        "the offender's ink is folded up to this line")
    assert_true(view.blots_of(String(e.actor_id)) >= 1)


# ------------------------------------------------------------ COMBAT-03 / Q07

func test_the_struck_figure_wears_the_bar_and_the_rest_a_badge() -> void:
    var view = _screen()
    var struck := String(view._party[0].id)
    if not view._party_sprites.has(struck):
        # A class with no figure has no sprite to hang a bar on; the rule
        # cannot be read off this party, which is data, not a failure here.
        return
    view._append_line(_attack_on(view, 12))
    assert_true(struck in view._bar_ids, "the struck raider is the one with a bar")
    var struck_spr: Node = view._party_sprites[struck]
    var bars := _find_named(view, "Bar_%s" % struck_spr.name)
    assert_eq(bars.size(), 1, "one overhead box per figure")
    assert_true(bars[0].get_node_or_null("HP") != null, "the struck figure's box carries the HP bar")
    assert_true(bars[0].get_node_or_null("Badge") != null, "and the class badge")
    var others := 0
    for id in view._party_sprites:
        if id == struck:
            continue
        var spr: Node = view._party_sprites[id]
        var box := _find_named(view, "Bar_%s" % spr.name)
        if box.is_empty():
            continue
        others += 1
        assert_true(box[0].get_node_or_null("HP") == null,
            "every other figure carries badge + pips only (Q07's default)")
    assert_true(others > 0, "the other figures wear a badge box")


func test_the_joke_lands_in_a_bubble_over_the_offender_and_stays_in_the_log() -> void:
    var view = _screen()
    var e = _first_mistake_with_a_joke(view)
    var joke := String(e.joke())
    view._append_line(e)
    var printed := "\n".join(PackedStringArray(_texts(view)))
    assert_true(printed.contains('"%s"' % joke), "the quoted joke line is in the log")
    assert_true(view._party_sprites.has(String(e.actor_id)), "the offender stands on the floor")
    var spr: Node = view._party_sprites[String(e.actor_id)]
    var says := _find_named(view, "Say_%s" % spr.name)
    assert_eq(says.size(), 1, "one bubble over the offender")
    var texts := _texts(says[0])
    assert_true(joke in texts, "the bubble's words are a Label: %s" % str(texts))


func test_a_downed_figure_wears_the_state_plate_with_a_label_bang() -> void:
    var view = _screen()
    var e = _first_real(view, func(x) -> bool:
        return (x.verb == Enums.Verb.STATE_CHANGE
            and String(x.params.get("state", "")).to_lower() == "downed"
            and view._party_sprites.has(String(x.actor_id))))
    assert_true(e != null, "a wipe downs somebody with a figure")
    var id := String(e.actor_id)
    view._append_line(e)
    var spr: Node = view._party_sprites[id]
    var box := _find_named(view, "Bar_%s" % spr.name)
    assert_eq(box.size(), 1)
    var bang: Node = box[0].get_node_or_null("Bang")
    assert_true(bang is Label and (bang as Label).text == "!",
        "CRITIC-C18: the '!' is a Label over the plate, never a baked glyph")
    # The panel's status row shows the state glyph and the word stays a Label.
    if view._panel_glyphs.has(id):
        assert_true((view._panel_glyphs[id] as TextureRect).visible)
    var printed := "\n".join(PackedStringArray(_texts(view)))
    assert_true(printed.contains("Downed"), "the state WORD is still printed")


# ------------------------------------------------------------ COMBAT-04

func test_the_skip_reason_is_a_label_inside_the_reasoned_box() -> void:
    var view = _screen()
    var reasons := _labels_starting(view, "Unlocks once")
    assert_eq(reasons.size(), 1, "exactly one reason line")
    var why: Label = reasons[0]
    assert_eq(String(why.name), "Reason", "it is the kit's Reason Label")
    var box: Node = why.get_parent()
    var skip: Button = box.get_node_or_null("Skip") as Button
    assert_true(skip != null, "the reason and the button share the reasoned box")
    assert_true(skip.disabled, "the skip is locked before a first clear")
    assert_eq(skip.text, "Skip to the end")
    # Nothing floats over the arena any more: the reason's parent is the
    # reasoned box, and the box is the only holder of that sentence.
    assert_true(box is VBoxContainer)
    assert_true(skip.icon != null, "the locked skip wears the padlock")


func test_an_unlocked_skip_is_enabled_and_wears_no_padlock() -> void:
    # docs/01 §9: skipping unlocks once the encounter has been cleared before
    # this attempt. The kit sets the glyph before it reads the reason, so the
    # screen must hand it the lock only while locked (review F2).
    var view = _screen(1)
    assert_true(view._skip_unlocked, "a prior clear unlocks the skip")
    var skips := _find_named(view, "Skip")
    assert_eq(skips.size(), 1)
    var skip: Button = skips[0]
    assert_false(skip.disabled, "enabled after a first clear")
    assert_true(skip.icon == null, "no padlock on an enabled control")
    assert_eq(_labels_starting(view, "Unlocks once").size(), 0,
        "no reason line when nothing is locked")
    assert_almost(skip.modulate.a, 1.0, 0.001, "undimmed")
    assert_eq(skip.focus_mode, Control.FOCUS_ALL)
    assert_eq(skip.text, "Skip to the end")


# ------------------------------------------------------------ CRITIC-G15

func test_the_bar_buttons_do_not_overlap_at_text_scale_150() -> void:
    # Review F1: the slots were fixed at their 100% widths while the type
    # scaled, and "Numbers" painted over "Play-by-play". Every button on the
    # row must end before the next begins, and be as wide as its word.
    var gs = _settings()
    var before = gs.get_value("text_scale")
    gs.set_value("text_scale", 150)
    var view = _screen()
    gs.set_value("text_scale", before)
    var pbp: Button = view._tier_buttons[Enums.LogTier.PLAY_BY_PLAY]
    assert_eq(pbp.get_theme_font_size("font_size"), Type.at(Type.SMALL, 150),
        "the bar's type scales with text_scale")
    # [left, right, text] in row order: speed, pause, skip, the three tiers.
    var spans: Array = []
    for b in [view._speed_button, view._pause_button]:
        spans.append([b.position.x, b.position.x + b.size.x, b.text])
    var skips := _find_named(view, "Skip")
    assert_eq(skips.size(), 1)
    var skip: Button = skips[0]
    var box: Control = skip.get_parent()
    # Inside the reasoned box the button sits at the left (SHRINK_BEGIN) at
    # its own minimum width; the container's sort is deferred, so read that.
    spans.append([box.position.x, box.position.x + skip.get_combined_minimum_size().x, skip.text])
    for tier in [Enums.LogTier.STORY, Enums.LogTier.PLAY_BY_PLAY, Enums.LogTier.NUMBERS]:
        var b: Button = view._tier_buttons[tier]
        spans.append([b.position.x, b.position.x + b.size.x, b.text])
    for i in range(1, spans.size()):
        assert_true(float(spans[i - 1][1]) <= float(spans[i][0]),
            "'%s' (ends %s) must not overlap '%s' (starts %s)" % [
                spans[i - 1][2], str(spans[i - 1][1]), spans[i][2], str(spans[i][0])])
    for tier in view._tier_buttons:
        var b: Button = view._tier_buttons[tier]
        assert_true(b.size.x + 0.5 >= b.get_combined_minimum_size().x,
            "'%s' is as wide as its word" % b.text)
    assert_true(float(spans[spans.size() - 1][1]) < float(RaidView.EXIT_BACK_X),
        "the row ends before the exits")
    # The exits themselves still fit their words at 150.
    for text in ["Back to the board", "The report"]:
        var found: Array = []
        for n in _find_buttons(view, text, found):
            assert_true(n.size.x + 0.5 >= n.get_combined_minimum_size().x,
                "'%s' fits its button at 150" % text)


func _find_buttons(n: Node, text: String, out: Array) -> Array:
    if n is Button and (n as Button).text == text:
        out.append(n)
    for c in n.get_children():
        _find_buttons(c, text, out)
    return out


# ------------------------------------------------------------ COMBAT-08

func test_the_wipe_stamp_is_the_kits_box_a_direct_child_after_the_blot() -> void:
    var view = _screen()
    view._run_wipe_sequence(float(RaidView.WIPE_BEAT_EXITS_MS))
    var label: Label = view._wipe_stamp_label
    assert_true(label != null and label.text == "WIPE.")
    var box: Node = label.get_parent()
    assert_true(box is PanelContainer and String(box.name) == "WipeStamp",
        "the word sits directly in the stamp box")
    assert_true(box.get_parent() == view, "the box is a direct child of the screen")
    assert_true(view._wipe_blot != null)
    assert_true(view._wipe_blot.get_index() < box.get_index(), "ink under the stamp")
    var stamps := 0
    for t in _texts(view):
        if String(t) == "WIPE.":
            stamps += 1
    assert_eq(stamps, 1, "exactly one WIPE. Label")


# ------------------------------------------------------------ COMBAT-06

func test_rows_older_than_the_two_newest_are_dimmed() -> void:
    var view = _screen()
    for i in 3:
        view._append_line(_attack_on(view, 10 + i, 1))
    var rows: Array = []
    for r in view._log_rows:
        if is_instance_valid(r):
            rows.append(r)
    assert_eq(rows.size(), 3)
    assert_almost((rows[0] as Control).modulate.a, RaidView.LOG_AGE_ALPHA, 0.001,
        "the oldest row is on the age ramp")
    assert_almost((rows[1] as Control).modulate.a, 1.0, 0.001)
    assert_almost((rows[2] as Control).modulate.a, 1.0, 0.001)


# ------------------------------------------------------------ COMBAT-16 / G08

func test_the_actors_panel_wears_the_rim_at_one_x() -> void:
    var view = _screen()
    view.player().speed = LogPlayer.Speed.ONE
    var e = _first_real(view, func(x) -> bool:
        return x.verb == Enums.Verb.ATTACK and not String(x.actor_id).is_empty())
    assert_true(e != null, "a raider swings at some point")
    view._append_line(e)
    assert_eq(view._lit_panel_id, String(e.actor_id), "the acting raider's panel is rimmed")
    var panel: Control = view._panel_nodes[String(e.actor_id)]
    assert_true(panel.has_theme_stylebox_override("panel"), "as a StyleBox swap, not a tween")
    # The next actor takes it with them.
    var e2 = _first_real(view, func(x) -> bool:
        return (x.verb == Enums.Verb.ATTACK and not String(x.actor_id).is_empty()
            and String(x.actor_id) != String(e.actor_id)))
    if e2 != null:
        view._append_line(e2)
        assert_eq(view._lit_panel_id, String(e2.actor_id))
        if is_instance_valid(panel) and view._panel_nodes.get(String(e.actor_id), null) == panel:
            assert_false(panel.has_theme_stylebox_override("panel"), "the rim moved on")


func test_effects_fire_per_line_at_one_x_once_per_round_at_two_x_and_never_faster() -> void:
    var view = _screen()
    var e1 = _attack_on(view, 5, 3)
    var e2 = _attack_on(view, 6, 3)
    var e3 = _attack_on(view, 7, 4)
    view.player().speed = LogPlayer.Speed.ONE
    assert_true(view._effects_allowed(e1) and view._effects_allowed(e2))
    view.player().speed = LogPlayer.Speed.TWO
    view._effect_round = -1
    assert_true(view._effects_allowed(e1), "the first line of a round fires")
    assert_false(view._effects_allowed(e2), "the second line of the same round does not")
    assert_true(view._effects_allowed(e3), "the next round fires again")
    view.player().speed = LogPlayer.Speed.FOUR
    assert_false(view._effects_allowed(e1), "off at 4x")
    view.player().speed = LogPlayer.Speed.INSTANT
    assert_false(view._effects_allowed(e1), "off at Instant")


## The settings autoload, or one for this test (RULES §1: screens tolerate its
## absence, so the runner does not always carry one).
func _settings():
    var gs = _root.get_node_or_null("GameSettings")
    if gs == null:
        gs = Settings.new()
        gs.name = "GameSettings"
        _root.add_child(gs)
        _made.append(gs)
    return gs


func test_reduced_effects_turns_the_per_line_layer_off() -> void:
    var gs = _settings()
    var before = gs.get_value("reduced_effects")
    gs.set_value("reduced_effects", true)
    var view = _screen()
    view.player().speed = LogPlayer.Speed.ONE
    var off: bool = not view._effects_allowed(_attack_on(view, 5, 1))
    gs.set_value("reduced_effects", before)
    assert_true(off, "no rim, brighten or flash under reduced_effects")


# ------------------------------------------------------------ the header

func test_the_compact_header_is_frames_33_lockup_inside_its_plate() -> void:
    var view = _screen()
    var marks := _find_named(view, "wordmark_33")
    assert_eq(marks.size(), 1, "the compact wordmark, through Frame.draw_lockup")
    var mark: Control = marks[0]
    assert_true(mark.position.x + mark.size.x <= RaidView.HEADER_W - 8,
        "COMBAT-12: the mark ends inside the 352px plate (right edge %d)" % int(mark.position.x + mark.size.x))
    assert_eq(_find_named(view, "wordmark_44").size(), 0, "wordmark_44 no longer overruns")


# ------------------------------------------------------------ the strip

func test_the_hp_caption_is_a_glyph_with_the_word_as_its_tooltip() -> void:
    var view = _screen()
    var glyphs := _find_named(view, "HpGlyph")
    assert_true(glyphs.size() >= 1, "one shield glyph per panel")
    for g in glyphs:
        assert_true(g is TextureRect and (g as TextureRect).texture != null)
        assert_eq((g as TextureRect).tooltip_text, "HP")
    assert_false("HP" in _texts(view), "no Label prints the bare word")


func test_the_status_row_prints_the_morale_figure_and_the_pager_is_the_kits() -> void:
    var view = _screen()
    var morale := _find_named(view, "Morale")
    assert_true(morale.size() >= 1, "a morale Label per panel")
    for m in morale:
        assert_true(String((m as Label).text).length() > 0)
        assert_eq(String((m as Label).theme_type_variation), "LabelMorale")
    if view._pages() > 1:
        var pagers := _find_named(view, "Pager")
        assert_eq(pagers.size(), 1, "KIT-12: the kit's captioned pager")
        assert_true(pagers[0].get_node_or_null("PagerPrev") != null)
        assert_true(pagers[0].get_node_or_null("PagerNext") != null)
        var printed := "\n".join(PackedStringArray(_texts(view)))
        assert_true(printed.contains("page 1/"), "the caption reads the page")
        # No pager pixel under a panel: the row sits in the band below them.
        var row: Control = pagers[0]
        assert_true(row.position.y >= RaidView.PANEL_Y + RaidView.PANEL_SIZE.y,
            "the pager is under the panels, never over card 4")
