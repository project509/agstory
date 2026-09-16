extends "res://tests/TestCase.gd"
## W2-BOARD — the Adventure's Board's notice rows are keyboard stops (RULES-07,
## TOWN-25, TOWN-11, TOWN-24, TOWN-10, TOWN-17). The board is mounted through the
## real autoload router with content loaded, the way Boot does, and the tree is
## read back: every notice is a full-rect Button named `Notice_<id>` the walk
## would stop on; focusing one pins it (the sidebar names it); a locked notice
## can be pinned while its rung stays disabled; the loop test's fragment presses
## still find the rung and nothing else; the scene region opens on the first
## notice; the ladder and the cork are there.
##
## The harness cannot hold focus (test_a11y.gd: run_tests.gd runs before the
## root enters the tree, so grab_focus() is refused and find_next_valid_focus()
## is null). So, as test_a11y does, this file asserts the WIRING — the
## `focus_neighbor_bottom` chain Frame.focus_order writes for the arrow step
## inside the scene region — and drives `focus_entered` by hand, which is the
## signal the engine would emit on the same control.

const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const Frame = preload("res://game/ui/Frame.gd")

const BOARD := "res://game/screens/AdventureBoard.tscn"

var _root: Node = null
var _made: Array = []
var _db = null


func before_each() -> void:
    var loop := Engine.get_main_loop()
    _root = (loop as SceneTree).root if loop is SceneTree else null
    _made = []
    if _db == null:
        _db = DB.load_all()


func after_each() -> void:
    # The autoloads outlive this file (LESSONS): put the state back, content
    # included, or another file's empty-roster assertion depends on test order.
    var st = _root.get_node_or_null("GameState") if _root != null else null
    if st != null:
        st.reset()
        st.set_content(null)
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []


# ---------------------------------------------------------------- helpers

func _ensure_autoloads() -> void:
    if _root.get_node_or_null("GameState") == null:
        var s = GameStateScript.new()
        s.name = "GameState"
        _root.add_child(s)
        _made.append(s)
    if _root.get_node_or_null("ScreenRouter") == null:
        var r = Router.new()
        r.name = "ScreenRouter"
        _root.add_child(r)
        _made.append(r)
    if _root.get_node_or_null("GameSettings") == null:
        var gs = SettingsScript.new()
        gs.name = "GameSettings"
        _root.add_child(gs)
        _made.append(gs)


## A fresh guild with content, on the REAL autoload state.
func _fresh_state():
    _ensure_autoloads()
    var st = _root.get_node_or_null("GameState")
    st.reset()
    st.set_content(_db)
    st.new_game("Board Rows")
    return st


## Mount the board through the autoload router, exactly as Boot does.
func _mount():
    var host := Control.new()
    host.name = "BoardRowsHost"
    _root.add_child(host)
    _made.append(host)
    var r = _root.get_node_or_null("ScreenRouter")
    r.register_host(host)
    assert_true(r.goto(BOARD), "could not open the board")
    return r.current_screen()


func _buttons(n: Node, out: Array = []) -> Array:
    if n is Button:
        out.append(n)
    for c in n.get_children():
        _buttons(c, out)
    return out


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


func _named(n: Node, prefix: String, out: Array = []) -> Array:
    if String(n.name).begins_with(prefix):
        out.append(n)
    for c in n.get_children():
        _named(c, prefix, out)
    return out


func _notices(screen: Node) -> Array:
    return _named(screen, "Notice_")


## The first enabled Button under `n` whose text contains `fragment` — the
## loop test's press.
func _press_target(n: Node, fragment: String) -> Button:
    for b in _buttons(n):
        if not b.disabled and b.text.contains(fragment):
            return b
    return null


# ---------------------------------------------------------------- rows

func test_every_notice_is_a_named_focusable_button_with_no_text() -> void:
    var st = _fresh_state()
    var screen = _mount()
    var rows := _notices(screen)
    var ladder: Array = screen._missions()
    assert_eq(rows.size(), ladder.size(), "one paper per rung on the ladder")
    assert_true(rows.size() >= 3, "the fixture ladder has at least A0, TR and A1")
    for i in rows.size():
        var b = rows[i]
        assert_true(b is Button, "%s must be a Button" % String(b.name))
        var btn: Button = b
        assert_eq(String(btn.name), "Notice_" + String(ladder[i].id),
            "rows are named by encounter id, in ladder order")
        assert_eq(btn.focus_mode, Control.FOCUS_ALL,
            "%s must be a keyboard stop (RULES-07)" % String(btn.name))
        assert_false(btn.disabled,
            "%s stays enabled even when the rung is locked — a locked notice is still readable"
            % String(btn.name))
        assert_eq(btn.text, "",
            "the paper carries no text, so `_press(\"A1\")` finds the rung and not the paper")
        assert_eq(String(btn.theme_type_variation), "ButtonNotice",
            "the paper's chrome is the W1-CHROME variation with the focus ring")
    st.reset()


func test_the_rung_button_keeps_its_slot_and_name_and_the_gate() -> void:
    var st = _fresh_state()
    var screen = _mount()
    var ladder: Array = screen._missions()
    for e in ladder:
        var wanted := "%s — %s" % [e.slot, e.display_name]
        var found: Button = null
        for b in _buttons(screen):
            if b.text == wanted:
                found = b
        assert_ne(found, null, "the rung Button '%s' must exist" % wanted)
        if found != null:
            assert_eq(found.disabled, not screen._locked_reason(e).is_empty(),
                "'%s' is disabled exactly when the ladder gates it" % wanted)
    # The on-ramp is A0; A1 sits behind the tutorials (test_full_loop reads
    # "A1" + "disabled" off the Button list).
    assert_ne(_press_target(screen, "A0"), null, "A0 is pressable")
    assert_eq(_press_target(screen, "A1"), null, "A1 is gated behind the tutorials")
    st.reset()


func test_focusing_a_notice_pins_it_and_the_sidebar_names_it() -> void:
    var st = _fresh_state()
    var screen = _mount()
    var ladder: Array = screen._missions()
    var first_id := String(ladder[0].id)
    assert_eq(screen._selected, first_id, "the board opens on the first climbable rung")
    for i in range(1, ladder.size()):
        var id := String(ladder[i].id)
        var paper: Button = screen.get_node_or_null(
            NodePath(_path_of(screen, "Notice_" + id)))
        assert_ne(paper, null, "Notice_%s must be in the tree" % id)
        # What the engine emits when the arrows land here.
        paper.focus_entered.emit()
        assert_eq(screen._selected, id, "focusing Notice_%s pins it (TOWN-25)" % id)
        var printed := _joined(screen)
        assert_true(printed.contains("Selected Notice"))
        assert_true(_count(printed, String(ladder[i].display_name)) >= 2,
            "the sidebar's card names the pinned notice (once on the paper, once in the card): %s"
            % String(ladder[i].display_name))
    st.reset()


func test_a_locked_notice_pins_but_its_rung_and_commit_stay_disabled() -> void:
    var st = _fresh_state()
    var screen = _mount()
    var locked = null
    for e in screen._missions():
        if not screen._locked_reason(e).is_empty():
            locked = e
            break
    assert_ne(locked, null, "a new guild has a locked rung to read")
    var id := String(locked.id)
    var paper: Button = screen.get_node_or_null(NodePath(_path_of(screen, "Notice_" + id)))
    assert_ne(paper, null)
    paper.pressed.emit()
    assert_eq(screen._selected, id, "a keyboard press pins a locked notice")
    var reason: String = screen._locked_reason(locked)
    var printed := _joined(screen)
    assert_true(printed.contains(reason), "the sidebar prints why: %s" % reason)
    var go: Button = null
    for b in _buttons(screen):
        if b.text == "Go to prep":
            go = b
    assert_ne(go, null)
    assert_true(go.disabled, "the commit is disabled on a locked notice, with its reason beside it")
    var rung := "%s — %s" % [locked.slot, locked.display_name]
    for b in _buttons(screen):
        if b.text == rung:
            assert_true(b.disabled, "the locked rung itself stays disabled")
    st.reset()


func test_pinning_does_not_rebuild_the_rows_so_focus_would_survive() -> void:
    var st = _fresh_state()
    var screen = _mount()
    var before := _notices(screen)
    var second: Button = before[1]
    second.focus_entered.emit()
    var after := _notices(screen)
    assert_eq(after.size(), before.size())
    for i in before.size():
        assert_true(is_instance_valid(before[i]) and before[i] == after[i],
            "the paper the keyboard is on must be the same node after a pin, not a rebuilt one")
    st.reset()


func test_the_skip_block_sits_on_the_selected_tutorials_paper_and_follows_the_pin() -> void:
    var st = _fresh_state()
    var screen = _mount()
    var ladder: Array = screen._missions()
    var a0 := String(ladder[0].id)
    var tr := String(ladder[1].id)
    # A0 is selected and skippable: its paper holds the one "Skip the tutorial".
    var skips: Array = []
    for b in _buttons(screen):
        if b.text == "Skip the tutorial":
            skips.append(b)
    assert_eq(skips.size(), 1, "exactly one skip control on the board")
    var row_a0: Node = screen.get_node_or_null(NodePath(_path_of(screen, "Row_" + a0)))
    assert_true(row_a0 != null and row_a0.is_ancestor_of(skips[0]),
        "the skip sits on A0's paper (docs/10 §9.3: next to the thing forfeited)")
    # LOOP-24's copy: the forced skip does not read as failure — and canon's
    # two requirements stay (the item and its stat by name; "not a good").
    var warning := _joined(row_a0)
    assert_true(warning.contains("Skipping it forfeits the"), "and so does the warning: %s" % warning)
    assert_true(warning.contains("and nothing else"), warning)
    assert_true(warning.contains("Cracked Charm of Power") and warning.contains("+1 Power"), warning)
    assert_true(warning.contains("not a good trinket"), "docs/10 §9.3: honesty is the joke")
    # Pin the Tutorial Raid: the block moves to its paper.
    var paper: Button = screen.get_node_or_null(NodePath(_path_of(screen, "Notice_" + tr)))
    paper.focus_entered.emit()
    skips = []
    for b in _buttons(screen):
        if b.text == "Skip the tutorial":
            skips.append(b)
    assert_eq(skips.size(), 1)
    var row_tr: Node = screen.get_node_or_null(NodePath(_path_of(screen, "Row_" + tr)))
    assert_true(row_tr != null and row_tr.is_ancestor_of(skips[0]), "the skip followed the pin to TR")
    assert_false(row_a0.is_ancestor_of(skips[0]))
    st.reset()


# ---------------------------------------------------------------- the keyboard walk

func test_the_scene_region_opens_on_the_first_notice_and_the_arrows_walk_the_rows() -> void:
    var st = _fresh_state()
    var screen = _mount()
    var regions: Array = Frame.focus_order(screen._frame)
    var first: Control = _notices(screen)[0]
    var scene_region: Array = []
    for members in regions:
        if members.has(first):
            scene_region = members
    assert_false(scene_region.is_empty(), "the notices are a shell region")
    assert_eq(scene_region[0], first,
        "the Tab ring's scene entry is Notice_%s (a11y_smoke: 'the Tab ring includes Notice_A0')"
        % String(screen._missions()[0].id))
    # Every paper is on the arrow ring, and stepping the ring by hand pins
    # each one in turn (what the arrows do live). The ring is re-wired on
    # every pin (the skip block moves to the pinned paper), so the walk runs
    # until it is back at the start, bounded rather than counted.
    var seen: Array = []
    var c: Control = first
    var steps := 0
    while steps == 0 or c != first:
        seen.append(c)
        var next_path: NodePath = c.focus_neighbor_bottom
        var next: Control = c.get_node_or_null(next_path) as Control
        assert_ne(next, null, "'%s' has a next arrow stop" % String(c.name))
        assert_eq(next.focus_mode, Control.FOCUS_ALL)
        next.focus_entered.emit()
        c = next
        steps += 1
        if steps > scene_region.size() + 4:
            break
    assert_eq(c, first, "the arrow ring wraps back to the first notice")
    for paper in _notices(screen):
        assert_true(seen.has(paper), "%s is on the arrow ring" % String(paper.name))
    assert_eq(screen._selected, String(screen._missions()[0].id),
        "a full lap ends where it began")
    st.reset()


func test_pinning_rewires_the_sidebar_so_tab_out_of_a_row_still_lands() -> void:
    var st = _fresh_state()
    var screen = _mount()
    var papers := _notices(screen)
    var second: Button = papers[1]
    second.focus_entered.emit()
    # The sidebar was rebuilt by the pin; the row's Tab target must resolve to
    # a live FOCUS_ALL control (a stale path is an engine error and a dead end).
    var target: Control = second.get_node_or_null(second.focus_next) as Control
    assert_ne(target, null, "Tab out of a notice must resolve after a pin")
    assert_true(is_instance_valid(target), "the Tab target is a live node")
    assert_eq(target.focus_mode, Control.FOCUS_ALL)
    assert_true(_buttons(screen).has(target), "and it is on this screen")
    st.reset()


# ---------------------------------------------------------------- the board itself

func test_the_ladder_and_the_cork_are_there() -> void:
    var st = _fresh_state()
    var screen = _mount()
    var rows := _notices(screen)
    assert_true(_named(screen, "Ladder").size() >= rows.size(),
        "one ladder cell per notice (TOWN-11)")
    assert_true(_joined(screen).contains("Tier 1"), "a tier divider (TOWN-11)")
    var cork: Control = screen.get_node_or_null(NodePath(_path_of(screen, "Board"))) as Control
    assert_ne(cork, null, "the list panel")
    assert_eq(String(cork.theme_type_variation), "PanelCork", "the list stands on cork (TOWN-24)")
    var glyphs := _named(screen, "Glyph")
    assert_true(glyphs.size() >= rows.size(), "a state glyph per rung")
    var pins := _named(screen, "Pin")
    assert_eq(pins.size(), rows.size(), "a pin on every paper (TOWN-24)")
    assert_true(_joined(screen).contains("LOCKED"), "a locked notice is stamped")
    # The scroll is bounded by a plain Control the column sizes, and the fade
    # sits in the same wrap above it (TOWN-10).
    var wrap: Control = screen.get_node_or_null(NodePath(_path_of(screen, "ListWrap"))) as Control
    assert_ne(wrap, null)
    assert_eq(wrap.size_flags_vertical, Control.SIZE_EXPAND_FILL)
    assert_ne(screen.get_node_or_null(NodePath(_path_of(screen, "Fade"))), null)
    st.reset()


func test_back_to_town_is_a_quiet_button_and_the_sidebar_has_no_scroll() -> void:
    var st = _fresh_state()
    var screen = _mount()
    var back: Button = null
    for b in _buttons(screen):
        if b.text == "Back to town":
            back = b
    assert_ne(back, null, "'Back to town' is a Button (TOWN-31 / CRITIC-C14)")
    assert_eq(String(back.theme_type_variation), "ButtonQuiet")
    assert_eq(back.focus_mode, Control.FOCUS_ALL)
    var side = screen._frame.sidebar_host
    var scrolls: Array = []
    _collect(side, ScrollContainer, scrolls)
    assert_eq(scrolls.size(), 0, "no ScrollContainer in the sidebar (TOWN-17, LESSONS)")
    st.reset()


func test_the_rewards_row_has_exactly_as_many_cells_as_drops_and_the_charm_for_a_trinket() -> void:
    # UI-14: A0's one trinket used to sit beside an empty 9-slice (the row
    # floored at two), and its icon was the reputation gem. Exactly `n` cells,
    # the charm family's picture for a trinket; with nothing to drop, a
    # caption instead of an empty well.
    var st = _fresh_state()
    var screen = _mount()
    var ladder: Array = screen._missions()
    var a0 = ladder[0]
    assert_eq(String(a0.slot), "A0")
    assert_eq(a0.loot_slots.size(), 1, "docs/10 §9: A0 offers one trinket")
    var rewards := _named(screen, "Rewards")
    assert_eq(rewards.size(), 1, "one rewards row on the sidebar")
    var cells: Array = []
    _collect(rewards[0], PanelContainer, cells)
    assert_eq(cells.size(), 1, "exactly one cell for one drop, no empty well beside it")
    var pics: Array = []
    _collect(rewards[0], TextureRect, pics)
    assert_true(pics.size() >= 1 and (pics[0] as TextureRect).texture != null)
    var path := String((pics[0] as TextureRect).texture.resource_path)
    assert_true(path.contains("item_trinket_"), "the charm family's icon, not the gem: %s" % path)
    assert_false(path.contains("item_reward_2") or path.contains("gem"), path)
    # E5 (two drops) gets two cells — the row is data-driven, never a fixed four.
    var e5 = ladder[ladder.size() - 1]
    assert_eq(String(e5.slot), "E5")
    var paper: Button = screen.get_node_or_null(NodePath(_path_of(screen, "Notice_" + String(e5.id))))
    paper.focus_entered.emit()
    rewards = _named(screen, "Rewards")
    cells = []
    _collect(rewards[0], PanelContainer, cells)
    assert_eq(cells.size(), e5.loot_slots.size())
    # Nothing to drop: the caption, not a well.
    var bare = ladder[1]
    var kept: Array = bare.loot_slots
    bare.loot_slots = []
    paper = screen.get_node_or_null(NodePath(_path_of(screen, "Notice_" + String(bare.id))))
    paper.focus_entered.emit()
    assert_true(_joined(screen).contains("Nothing worth carrying."), _joined(screen))
    assert_eq(_named(screen, "Rewards").size(), 0, "no empty row")
    bare.loot_slots = kept
    st.reset()


func test_the_facts_line_pluralises_one_enemy() -> void:
    # LOOP-04 / UI-02: "Trash · 1 enemies · about 6 rounds" on every one-enemy
    # notice. Both the notice and the sidebar read Type.count's line.
    var st = _fresh_state()
    var screen = _mount()
    var printed := _joined(screen)
    assert_true(printed.contains("1 enemy  ·"), printed)
    assert_false(printed.contains("1 enemies"), printed)
    assert_false(printed.contains("A0  ·  a party"), "no slot code on the commit's sub-line (LOOP-03)")
    assert_true(printed.contains("A party of 4"), printed)
    st.reset()


func test_the_empty_board_says_so_with_a_glyph() -> void:
    _ensure_autoloads()
    var st = _root.get_node_or_null("GameState")
    st.reset()
    st.set_content(null)
    st.new_game("No Content")
    var screen = _mount()
    assert_eq(_notices(screen).size(), 0)
    var printed := _joined(screen)
    assert_true(printed.contains("Nothing is pinned."), "the list's empty state is a Label")
    var glyphs := _named(screen, "Glyph")
    assert_true(glyphs.size() >= 1, "the empty state carries KIT-08's glyph")
    st.reset()


# ---------------------------------------------------------------- small helpers

func _path_of(root: Node, name: String) -> String:
    var found := _named(root, name)
    if found.is_empty():
        return "__missing__"
    return String(root.get_path_to(found[0]))


func _count(haystack: String, needle: String) -> int:
    if needle.is_empty():
        return 0
    var n := 0
    var at := 0
    while true:
        at = haystack.find(needle, at)
        if at < 0:
            break
        n += 1
        at += needle.length()
    return n


func _collect(n: Node, type, out: Array) -> void:
    if is_instance_of(n, type):
        out.append(n)
    for c in n.get_children():
        _collect(c, type, out)
