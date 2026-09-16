extends "res://tests/TestCase.gd"
## The Results screen's one piece of arithmetic that a shot cannot hold still.
##
## "The fallen" is a grid of portrait cells inside a report panel that CLIPS.
## At the roomy cell size — 92px wide, four to a row — a total wipe is twelve
## cells in three rows, and the third row was cut through the middle of its own
## names. Scrolling was already in place and did not save it: the column does
## scroll, so the overflow was merely hidden, with no scrollbar to say so.
##
## A total wipe is not the corner case. It is the likeliest outcome of the tier
## that is currently a wall (`test_adventures.gd` pins A3 at 0/24), and
## `docs/13` §11.4 makes the fallen the payload of the wipe sequence, so half a
## dead raider's name is the wrong way to deliver it.
##
## The fix is that the grid FITS rather than scrolls, and the numbers that make
## it fit are asserted here against the column they have to fit into — because
## the next person to change `LEFT_COL_W` or a cell size will not remember them.

const Results = preload("res://game/screens/Results.gd")


func test_a_small_loss_keeps_the_roomy_cell() -> void:
    # Three dead is a story about three people; they get the space.
    for n in [1, 3, 6]:
        assert_eq(Results.fallen_metrics(n), Results.FALLEN_CELL,
            "%d casualties should still get the roomy cell" % n)
        assert_eq(Results.fallen_gap(n), Results.FALLEN_GAP, "and the roomy separation")


func test_a_wipe_gets_the_compact_cell() -> void:
    for n in [7, 11, 12]:
        assert_eq(Results.fallen_metrics(n), Results.FALLEN_CELL_COMPACT,
            "%d casualties do not fit at the roomy size" % n)
        assert_eq(Results.fallen_gap(n), Results.FALLEN_GAP_COMPACT, "and the tighter separation")


func test_the_compact_cell_puts_exactly_six_in_a_row() -> void:
    # THE number. Six to a row is what turns twelve cells into TWO rows, and two
    # rows is what fits under the headline and the tally. Seven would not fit
    # the column, and five would put twelve back into three rows.
    var w: int = Results.FALLEN_CELL_COMPACT.x
    var gap: int = Results.FALLEN_GAP_COMPACT
    var six := 6 * w + 5 * gap
    var seven := 7 * w + 6 * gap
    assert_true(six <= Results.LEFT_COL_W,
        "six compact cells (%d) must fit the %dpx column" % [six, Results.LEFT_COL_W])
    assert_true(seven > Results.LEFT_COL_W,
        "a seventh (%d) must NOT fit, or the row count stops being predictable" % seven)


func test_the_roomy_cell_still_fits_four_in_a_row() -> void:
    var w: int = Results.FALLEN_CELL.x
    var gap: int = Results.FALLEN_GAP
    assert_true(4 * w + 3 * gap <= Results.LEFT_COL_W, "four roomy cells must fit")
    assert_true(5 * w + 4 * gap > Results.LEFT_COL_W, "five must not")


func test_a_full_wipe_is_two_rows_and_they_fit_the_panel() -> void:
    # The measurement that closes the defect: twelve cells, six to a row, at a
    # row cost of portrait + two label lines, against the height the panel has
    # left under the headline and the tally. `PANEL_RECT` is the clip.
    var rows := int(ceil(12.0 / 6.0))
    assert_eq(rows, 2, "twelve compact cells should be two rows")
    # A row is the portrait plus two lines of LabelSmall plus the cell's own
    # 2px spacing; 20px per line is the measured cost at this type scale.
    var row_h: int = Results.FALLEN_CELL_COMPACT.y + 2 * 20 + 2
    var grid_h := rows * row_h + (rows - 1) * 8
    # Measured off the shot: the headline, the tally and their rules take about
    # 300px of the panel's 616, leaving this much under "The fallen".
    var room := int(Results.PANEL_RECT.size.y) - 300 - 36
    assert_true(grid_h <= room,
        "a full wipe needs %dpx and the panel leaves about %dpx" % [grid_h, room])


# ---------------------------------------------------------------- the epigraph (BL-139)

## Q12b as ruled: the encounter's comedy line stays on EVERY Results page as
## the notice's epigraph, under the eyebrow "The notice said:" — the board
## said what was supposed to happen, the report says what did, and the
## distance is the joke. Mounted on the fixture's wipe and on its clear, read
## through `Label.text` the way every screen test reads a page.

const Router = preload("res://game/core/ScreenRouter.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Fixture = preload("res://tools/fixture_reference.gd")
const RESULTS := "res://game/screens/Results.tscn"

var _made: Array = []


func after_each() -> void:
    var root: Node = (Engine.get_main_loop() as SceneTree).root
    var st = root.get_node_or_null("GameState")
    if st != null and not (st in _made):
        st.reset()
        st.content = null
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []


func _state_node():
    var root: Node = (Engine.get_main_loop() as SceneTree).root
    if root.get_node_or_null("GameState") == null:
        var s = GameStateScript.new()
        s.name = "GameState"
        root.add_child(s)
        _made.append(s)
    if root.get_node_or_null("ScreenRouter") == null:
        var r = Router.new()
        r.name = "ScreenRouter"
        root.add_child(r)
        _made.append(r)
    return root.get_node("GameState")


func _mount() -> Control:
    var root: Node = (Engine.get_main_loop() as SceneTree).root
    var host := Control.new()
    host.size = Vector2(1536, 1024)
    root.add_child(host)
    _made.append(host)
    var r = Router.new()
    _made.append(r)
    r.register_host(host)
    assert_true(r.goto(RESULTS), "the report must mount")
    return r.current_screen()


func _texts(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _texts(c, out)
    return out


func _index_of(list: Array, text: String) -> int:
    for i in list.size():
        if String(list[i]) == text:
            return i
    return -1


func test_the_epigraph_wears_its_eyebrow_on_a_wipe() -> void:
    var st = _state_node()
    Fixture.apply(st, null, true)
    assert_false(st.last_result.cleared())
    var enc = st.content.encounter(st.last_result.encounter_id)
    var texts := _texts(_mount())
    var eyebrow := _index_of(texts, Results.EPIGRAPH_EYEBROW)
    assert_true(eyebrow >= 0, "BL-139: the eyebrow is a Label on the page")
    assert_eq(String(texts[eyebrow + 1]), String(enc.comedy_line),
        "…directly above the notice's line, which stays verbatim")


func test_the_epigraph_wears_its_eyebrow_on_a_clear_too() -> void:
    var st = _state_node()
    assert_true(Fixture.apply_clear(st) >= 0, "the clear fixture must find a clearing seed")
    assert_true(st.last_result.cleared())
    var enc = st.content.encounter(st.last_result.encounter_id)
    var texts := _texts(_mount())
    var eyebrow := _index_of(texts, Results.EPIGRAPH_EYEBROW)
    assert_true(eyebrow >= 0, "on every outcome — the clear page too")
    assert_eq(String(texts[eyebrow + 1]), String(enc.comedy_line))
    assert_true(texts.has("CLEARED"), "and the clear's stamp reads CLEARED")
