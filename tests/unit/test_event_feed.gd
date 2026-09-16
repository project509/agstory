extends "res://tests/TestCase.gd"
## W3-KIT2 / TOWN-23: the hub's event feed. `GameState.event_feed` is a
## non-persisted ring buffer of the last twenty things the guild DID (hires,
## dismissals, sales, purchases, upgrades, raid results, rests, departures),
## `Cards.recent_events` reads it before the morale notes, and
## `Cards.event_log` prints each row as a Label with the icon grid's badge
## (KIT-07: `Widgets.log_row(..., kind)` → `Icons.at("log", kind)`).
##
## tests/unit/test_event_log.gd covers the RAID's EventLog (sim/core); this
## file is the hub's feed, the new case TOWN-23's acceptance asked for beside
## it. Four-space indented, like every test.

const Cards = preload("res://game/ui/Cards.gd")
const Widgets = preload("res://game/ui/Widgets.gd")
const Icons = preload("res://game/ui/Icons.gd")
const Badge = preload("res://game/ui/Badge.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Enums = preload("res://sim/model/Enums.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")

const GUILDHALL := "res://game/screens/Guildhall.tscn"
## The log's ground (spec 01 §4.2's panel fill), the plate every badge sits on.
const LOG_GROUND := Color("020C14")

var _db = null
var _mounted: Array = []
var _made: Array = []
var _borrowed = null
var _borrowed_content = null


class StateStub:
    var roster: Array = []


func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _mounted = []
    _made = []


func after_each() -> void:
    if _borrowed != null and is_instance_valid(_borrowed):
        _borrowed.reset()
        _borrowed.content = _borrowed_content
        _borrowed = null
        _borrowed_content = null
    for n in _mounted:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _mounted = []
    for n in _made:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _made = []


func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null


## The live-autoload shape test_a11y_legibility.gd uses: borrow the real
## GameState when the autoloads exist under `--script`, else provide them.
## Snapshot and restore in `after_each` (LESSONS: the autoloads outlive a file).
func _live_state(guild: String, gold: int = 5000):
    var root := _root()
    var st = root.get_node_or_null("GameState")
    if st == null:
        st = GameStateScript.new()
        st.name = "GameState"
        root.add_child(st)
        _mounted.append(st)
    else:
        _borrowed = st
        _borrowed_content = st.content
    if root.get_node_or_null("ScreenRouter") == null:
        var rt = Router.new()
        rt.name = "ScreenRouter"
        root.add_child(rt)
        _mounted.append(rt)
    st.reset()
    st.set_content(_db)
    st.new_game(guild)
    st.gold = gold
    return st


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


func _find(n: Node, name: String) -> Node:
    if String(n.name) == name:
        return n
    for c in n.get_children():
        var hit := _find(c, name)
        if hit != null:
            return hit
    return null


func _find_all(n: Node, name: String, out: Array = []) -> Array:
    if String(n.name) == name:
        out.append(n)
    for c in n.get_children():
        _find_all(c, name, out)
    return out


func _link(n: Node, text: String) -> LinkButton:
    if n is LinkButton and (n as LinkButton).text == text:
        return n as LinkButton
    for c in n.get_children():
        var hit := _link(c, text)
        if hit != null:
            return hit
    return null


## The log row whose Label carries `text`, or null.
func _row_with(host: Node, text: String) -> HBoxContainer:
    for c in host.get_children():
        if c is HBoxContainer:
            for l in c.get_children():
                if l is Label and String((l as Label).text).contains(text):
                    return c as HBoxContainer
        var deeper := _row_with(c, text)
        if deeper != null:
            return deeper
    return null


# ------------------------------------------------------------ the ring buffer

func test_the_feed_is_a_ring_of_twenty_newest_last_and_reset_clears_it() -> void:
    var st = _live_state("Feed Test")
    assert_true(st.event_feed.is_empty(), "a new guild has an empty feed")
    for i in 25:
        st.log_event("gold", "row %d" % (i + 1))
    assert_eq(st.event_feed.size(), st.EVENT_FEED_CAP, "capped at twenty")
    assert_eq(String(st.event_feed[0]["text"]), "row 6", "the oldest five fell off the front")
    assert_eq(String(st.event_feed[-1]["text"]), "row 25", "newest last")
    var newest: Array = st.recent_feed(3)
    assert_eq(newest.size(), 3)
    assert_eq(String(newest[0]["text"]), "row 25", "recent_feed is newest first")
    assert_eq(int(newest[0]["day"]), int(st.day), "stamped with the day it happened")
    assert_true(int(newest[0]["seq"]) > int(newest[1]["seq"]), "seq orders rows within a day")
    st.log_event("gold", "")
    assert_eq(st.event_feed.size(), st.EVENT_FEED_CAP, "an empty text writes nothing")
    var shape: Dictionary = st.to_dict()
    assert_false(shape.has("event_feed"), "not persisted: the save shape does not move (LESSONS)")
    st.reset()
    assert_true(st.event_feed.is_empty(), "reset clears the feed with everything else")


# --------------------------------------------------------------------- hire

func test_a_hire_writes_a_recruit_row_the_town_log_shows_with_its_badge() -> void:
    # TOWN-23's acceptance line: after a hire the log shows a recruit row with
    # its badge. The Town, the Tavern, the Guildhall, the Market and the Detail
    # all draw the same `Cards.event_log`, so the log is asserted directly.
    var st = _live_state("Feed Test", 5000)
    if st.tavern_board.is_empty():
        st.refresh_board()
    assert_true(st.tavern_board.size() > 0, "need a candidate on the board")
    var who = st.tavern_board[0]
    var name := String(who.display_name)
    assert_eq(st.hire(0), "", "the hire went through")
    assert_eq(st.event_feed.size(), 1, "one row for one hire")
    var row: Dictionary = st.event_feed[0]
    assert_eq(String(row["kind"]), "recruit")
    assert_true(String(row["text"]).begins_with("Hired %s the " % name), row["text"])
    assert_true(String(row["text"]).ends_with(" G."), "the price is on the row: %s" % row["text"])

    var events: Array = Cards.recent_events(st, 7)
    assert_true(events.size() >= 1)
    assert_eq(String(events[0]["kind"]), "recruit", "the feed comes before the morale notes")
    assert_true(String(events[0]["text"]).contains(name))

    var host := Control.new()
    _made.append(host)
    Cards.event_log(host, st)
    var all := _joined(host)
    assert_true(all.contains("Hired %s" % name), "the row is a Label the tests can read: %s" % all)
    assert_false(all.contains("Nothing has happened yet."), "no empty state once there is a row")
    var log_row := _row_with(host, "Hired %s" % name)
    assert_ne(log_row, null, "the row is a log_row")
    var badge := _find(log_row, "Badge")
    assert_true(badge is TextureRect, "KIT-07: the badge is the icon grid's pixel sprite, not a disc")
    assert_eq((badge as TextureRect).texture.resource_path, Icons.path("log", "recruit"),
        "the recruit badge is icons/grid/log_recruit.png")


# ------------------------------------------------------------- other verbs

func test_the_other_verbs_write_their_rows_with_their_kinds() -> void:
    var st = _live_state("Feed Test", 5000)
    var before: int = st.event_feed.size()
    var gone = st.roster[0]
    assert_eq(st.dismiss_raider(gone.id), "", "dismissal went through")
    assert_eq(String(st.event_feed[-1]["kind"]), "morale_down", "a dismissal is a loss for the rest")
    assert_true(String(st.event_feed[-1]["text"]).contains(gone.display_name))

    st.rest_in_town()
    assert_eq(String(st.event_feed[-1]["kind"]), "phase", "a rest is a day passing")
    assert_true(String(st.event_feed[-1]["text"]).begins_with("Rested a day"), st.event_feed[-1]["text"])
    assert_eq(int(st.event_feed[-1]["day"]), int(st.day), "stamped with the day the rest ended on")

    # A rest-until-recovered is ONE row however many ticks it took (a 28-day
    # rest must not push every real event out of a 20-row ring).
    var n_before: int = st.event_feed.size()
    var report: Dictionary = st.rest_until_recovered()
    var days: int = int(report["days"])
    if days > 0:
        assert_eq(st.event_feed.size(), n_before + 1 + (report["departed"] as Array).size(),
            "one row for the whole rest (+ one per departure)")
        assert_true(String(st.event_feed[n_before]["text"]).begins_with("Rested %d day" % days),
            st.event_feed[n_before]["text"])
    else:
        assert_eq(st.event_feed.size(), n_before, "nothing rested, nothing written")

    # An upgrade names the building and its new level.
    st.reputation_rank = Enums.ReputationRank.KNOWN
    st.gold = 100000
    var blocker := String(st.upgrade_building("tavern"))
    if blocker.is_empty():
        assert_eq(String(st.event_feed[-1]["kind"]), "system")
        assert_true(String(st.event_feed[-1]["text"]).begins_with("Tavern upgraded to level 2"),
            st.event_feed[-1]["text"])
    assert_true(st.event_feed.size() > before, "the verbs wrote rows")


func test_a_sell_all_is_one_row_and_a_single_sale_names_the_item() -> void:
    var st = _live_state("Feed Test", 100)
    # Borrow three items nobody can wear: the content's first items, whatever
    # they are, are enough for the SHAPE of the rows — what is asserted is the
    # row count, not the economics (test_economy owns those).
    var items: Array = []
    for it in _db.items.values():
        items.append(it)
        if items.size() >= 3:
            break
    assert_true(items.size() >= 2, "content has items to sell")
    st.pending_loot = [items[0]]
    var paid: int = st.sell_loot(items[0].id)
    assert_true(paid >= 0)
    assert_eq(String(st.event_feed[-1]["kind"]), "gold", "a sale is gold")
    assert_true(String(st.event_feed[-1]["text"]).begins_with("Sold %s for" % String(items[0].name)),
        st.event_feed[-1]["text"])
    var n_before: int = st.event_feed.size()
    st.pending_loot = items.duplicate()
    var total: int = st.sell_unusable_loot()
    var junk_rows: int = st.event_feed.size() - n_before
    assert_true(junk_rows <= 1, "a sell-all writes at most ONE row, never one per item (%d)" % junk_rows)
    if junk_rows == 1:
        assert_true(String(st.event_feed[-1]["text"]).begins_with("Sold "), st.event_feed[-1]["text"])
        assert_true(String(st.event_feed[-1]["text"]).contains("%d G" % total))


# ------------------------------------------------------------- empty states

func test_the_empty_log_says_day_one_on_day_one_and_nothing_yet_after() -> void:
    var st = _live_state("Feed Test")
    assert_eq(int(st.day), 1)
    var host := Control.new()
    _made.append(host)
    Cards.event_log(host, st, 7, "Raids and rests write here.")
    var all := _joined(host)
    assert_true(all.contains(Cards.DAY_ONE_EMPTY), "TOWN-23's day-one line: %s" % all)
    assert_false(all.contains("Nothing has happened yet."))
    assert_true(all.contains("Raids and rests write here."), "the hint is still a Label")
    var glyph := _find(host, "Glyph")
    assert_true(glyph is TextureRect, "KIT-08: the empty log carries its picture by default")
    assert_eq((glyph as TextureRect).texture.resource_path, Icons.path("empty", "quill"),
        "the quill, unless a screen passes its own")

    st.day = 12
    var later := Control.new()
    _made.append(later)
    Cards.event_log(later, st)
    assert_true(_joined(later).contains("Nothing has happened yet."), "past day one, the plain line")
    var stub := StateStub.new()
    assert_eq(Cards.empty_text(stub), "Nothing has happened yet.", "a state without a day is not day one")


# ------------------------------------------------------------------ badges

func test_every_feed_badge_reads_on_the_log_ground_at_three_to_one() -> void:
    # KIT-07's acceptance: pixel badges with contrast >= 3:1 vs #020C14. The
    # PNGs are read raw (never the imported texture — test_icons.gd's rule) and
    # the badge's ink is the mean of its opaque pixels.
    for kind in Icons.LOG_KINDS:
        var path := Icons.path("log", String(kind))
        assert_ne(path, "", "the grid has log_%s" % kind)
        var img := Image.load_from_file(ProjectSettings.globalize_path(path))
        assert_ne(img, null, "%s reads" % path)
        img.convert(Image.FORMAT_RGBA8)
        var sum := Color(0, 0, 0, 0)
        var n := 0
        for y in img.get_height():
            for x in img.get_width():
                var c := img.get_pixel(x, y)
                if c.a > 0.5:
                    sum += c
                    n += 1
        assert_true(n > 0, "log_%s has opaque pixels" % kind)
        var mean := Color(sum.r / n, sum.g / n, sum.b / n, 1.0)
        var ratio: float = Badge._contrast(mean, LOG_GROUND)
        assert_true(ratio >= 3.0, "log_%s reads %.2f:1 on the log ground — §13 asks 3:1" % [kind, ratio])


func test_log_row_resolves_a_kind_through_the_grid_and_falls_back_to_a_glyphed_disc() -> void:
    var iconed := Widgets.log_row("Hired Bork the Warrior for 60 G.", Palette.TEXT_MUTED_WARM,
        Palette.INFO, null, "recruit")
    _made.append(iconed)
    var badge := _find(iconed, "Badge")
    assert_true(badge is TextureRect, "a grid kind is a pixel badge")
    assert_eq((badge as TextureRect).texture.resource_path, Icons.path("log", "recruit"))
    assert_true(_joined(iconed).contains("Hired Bork"), "the text is still a Label")
    var plain := Widgets.log_row("Something else.", Palette.TEXT_MUTED_WARM, Palette.INFO, null, "nonsense")
    _made.append(plain)
    var disc := _find(plain, "Badge")
    assert_true(disc != null and not (disc is TextureRect), "an unknown kind keeps the disc")
    var bare := Widgets.log_row("No kind at all.")
    _made.append(bare)
    assert_true(_find(bare, "Badge") != null and not (_find(bare, "Badge") is TextureRect),
        "the old four-argument call still draws the disc")
    assert_eq(Badge.glyph_for_kind("mistake"), Badge.GLYPH_MISTAKE, "the disc's glyph follows the kind")
    assert_eq(Badge.glyph_for_kind("nonsense"), "")


func test_badge_icon_keeps_the_morale_pair_and_answers_the_record_states() -> void:
    # HALL-20: locked / earned / claimed for the Records wall; the morale pair
    # moves from the mockup crops to the grid's arrows (KIT-07); "loot" stays
    # null — test_a11y_legibility.gd pins it as the disc.
    assert_eq(Cards.badge_icon("morale_down").resource_path, Icons.path("log", "morale_down"))
    assert_eq(Cards.badge_icon("morale_up").resource_path, Icons.path("log", "morale_up"))
    assert_eq(Cards.badge_icon("locked").resource_path, Icons.path("lock", "16"))
    assert_ne(Cards.badge_icon("earned"), null)
    assert_ne(Cards.badge_icon("claimed"), null)
    assert_eq(Cards.badge_icon("loot"), null)
    assert_eq(Cards.badge_icon(""), null)


# ---------------------------------------------------------------- View All

func test_view_all_is_shut_below_known_and_names_its_reason() -> void:
    var st = _live_state("Feed Test")
    assert_true(int(st.reputation_rank) < Enums.ReputationRank.KNOWN, "a new guild is Unknown")
    assert_eq(Cards.view_all_reason(st), "Opens at Known.")
    var host := Control.new()
    _made.append(host)
    Cards.event_log(host, st)
    var link := _link(host, "Records")
    assert_ne(link, null)
    assert_true(link.disabled)
    assert_true(_joined(host).contains("Opens at Known."), "the reason is a Label beside the link")
    assert_eq(Cards.view_all_reason(StateStub.new()), "Opens at Known.", "a stub state cannot route")
    st.reputation_rank = Enums.ReputationRank.KNOWN
    assert_eq(Cards.view_all_reason(st), "", "at Known the link opens")


func test_view_all_opens_the_records_tab_on_the_guildhall() -> void:
    # KIT-21: the link presses the "Records" tab Button — the screen tests'
    # own door — on the current screen, pushing the Guildhall first from
    # anywhere else. The autoload router is what the screens navigate with
    # (LESSONS), so the host is registered on it, exactly as Boot does.
    var st = _live_state("Feed Test")
    st.reputation_rank = Enums.ReputationRank.KNOWN
    var router = _root().get_node_or_null("ScreenRouter")
    assert_ne(router, null)
    var host := Control.new()
    host.name = "FeedTestHost"
    _root().add_child(host)
    _made.append(host)
    router.register_host(host)
    assert_true(router.goto("res://game/screens/Town.tscn"), "the Town mounts")
    var town = router.current_screen()
    var link := _link(town, "Records")
    assert_ne(link, null, "the Town's log carries the link")
    assert_false(link.disabled, "and at Known it is open")
    link.pressed.emit()
    var screen = router.current_screen()
    assert_ne(screen, town, "the link left the Town")
    assert_true(screen != null and screen.has_method("active_tab"), "for the Guildhall")
    assert_eq(String(screen.active_tab()), "records", "on its Records tab")
    assert_true(_joined(screen).contains("Records  "), "the wall is up (\"Records  N of M\")")
    # Cleanup: the router's current screen is inside the host this test frees.
    router.register_host(null)
