extends "res://tests/TestCase.gd"
## Legibility: the text scale, the emoji-free funnel, the four-channel morale
## reading, and the log badge's second channel.
##
## Four rows of docs/13 §13's accessibility table are marked **Blocking: Yes** and
## three of them were being carried by a setting nothing consumed:
##
##   "Colour is never the only signal" — the combat-log badge was an 18px disc.
##   "Text scaling 100 / 125 / 150%"   — no caller anywhere.
##   Emoji-free mode                   — honoured on one of eight display sites.
##
## The tests here are deliberately of two kinds. Some mount the real Tavern and
## read `Label.text`, because that is the only channel a test can see and §13's
## state word exists precisely so that a machine and a colour-blind player have
## the same information. Others read the SOURCE of game/, because "a tenth site
## forgets" is a defect no amount of screen mounting can catch — only an
## inventory can.

const Type = preload("res://game/ui/Type.gd")
const Badge = preload("res://game/ui/Badge.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Palette = preload("res://game/ui/Palette.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Morale = preload("res://sim/core/Morale.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const SettingsScript = preload("res://game/core/GameSettings.gd")
const TavernView = preload("res://game/screens/Tavern.gd")
const Widgets = preload("res://game/ui/Widgets.gd")

## THE CONVERSION IS A MEASURED CONSEQUENCE OF THE STRETCH MODE, NOT A CHOICE.
##
## project.godot sets `window/stretch/aspect="keep"` over a 1536x1024 base
## viewport, and GameSettings.DEFAULTS ships `display_aspect="keep"`. `keep`
## scales by the SMALLER of the two ratios, so on the 1920x1080 display docs/13
## §13 states its floor against, an authored pixel renders at
## min(1920/1536, 1080/1024) = 1080/1024 = 1.0547 — art/ref/specs/11 §1 says the
## same thing in words: "at 1080p the window is 1920 wide but the reference frame
## scaled to 1080 tall is 1620 wide", and its own table gives the factor as
## x1.0547 for BOTH `keep` and the `expand` opt-in. There is no display setting
## under which 1.25 is the on-screen factor; 1.25 is the width ratio alone, which
## only a `stretch/aspect="ignore"` build would apply, and this project has none.
##
## An EARLIER VERSION OF THIS FILE USED 1.25 AND CERTIFIED A ROW THAT DOES NOT
## HOLD. Left here as a named constant so the mistake cannot be made silently
## again, and so `test_the_letterbox_factor_is_not_the_width_ratio` can assert the
## difference is the thing that decides §13's blocking row.
const FRAME := Vector2(1536.0, 1024.0)      ## project.godot, specs/11 §1
const REPORTED_AT := Vector2(1920.0, 1080.0)  ## the resolution docs/13 §13 names
const LETTERBOX := 1080.0 / 1024.0          ## = min(1920/1536, 1080/1024)
const WIDTH_RATIO_ONLY := 1920.0 / 1536.0   ## 1.25 — NOT the on-screen factor
const MIN_READABLE_1920 := 14.0
const MIN_DECORATIVE_1920 := 12.0

## Every font size in Type.gd, by name. Enumerated by hand rather than scraped so
## that adding a style forces a decision about whether the player must read it.
const READABLE_SIZES := [
    "WORDMARK", "WORDMARK_COMPACT", "TAGLINE", "FIGURE_XL", "DAMAGE_CRIT",
    "DAMAGE", "CHIP", "SUBJECT", "SECTION", "SECTION_SM", "NAV", "OBJECTIVE",
    "MORALE_VALUE", "LABEL_LG", "NAME", "CALLOUT_TITLE", "BOSS_NAME", "CTA_COST",
    "CTA", "LABEL", "LINK", "LEVEL", "BODY", "CLASS", "QUOTE", "SMALL",
]

## `STACK` is a stack count in an ability cell and is not enumerated above,
## because §13's floor is for "anything the player must read" and a stack count is
## duplicated in the cell's own tooltip-free caption. It is measured all the same.
const DECORATIVE_SIZES := ["STACK"]

## THE STYLES THAT MISS docs/13 §13's FLOOR AT THE PROJECT'S REAL LETTERBOX, in
## the order the scan below finds them. This list is a DEFECT RECORD, not an
## exemption list:
##
##   SMALL  13 -> 13.71px  — combat-log rows, bubble text, "48/128", and the
##                           Tavern candidate card's morale rows and backstory
##                           bullets. All of that is "anything the player must
##                           read", so this is a blocking-row failure.
##   STACK  11 -> 11.60px  — under even §13's 12px decorative allowance.
##
## It is not fixed here because the sizes are not this file's to invent: they were
## measured off the reference concepts (art/ref/specs/05 §3, cap height / cap
## ratio) and the standing user rule is that the reference concepts win on art.
## docs/13 §4.2 authors its own scale at 1920x1080 while specs/11 §1 letterboxes a
## 1536-wide frame to 1620 — two authorities, two authoring frames, and the gap
## between them is exactly the 1.25/1.0547 discrepancy. The ruling is asked for in
## build/plan/q-a11y-legible.md; asserting the exact list here means the day
## somebody repaints the type scale or rules on the frame, this test says so.
const BELOW_FLOOR_AT_1920 := ["SMALL", "STACK"]

## Files allowed to touch `Enums.MORALE_BAND_EMOJI` / `morale_band_emoji`.
## `GameSettings.gd` implements docs/13 §13's substitution; `Cards.gd` is the one
## funnel every display site goes through (`Cards.morale_glyph`).
const GLYPH_FUNNEL := [
    "game/core/GameSettings.gd",
    "game/ui/Cards.gd",
]

## Sites audit item M6-A11Y-04 found bypassing the funnel that this agent does not
## own. Each is an exact-edit handoff in build/plan/handoff-a11y-legible.md. The
## assertion below is a SUBSET check, so applying a handoff never turns this red —
## only a NEW bypass does.
const GLYPH_HANDOFF_PENDING := [
    "game/screens/Facilities.gd",
    "game/screens/Guildhall.gd",
    "game/screens/Market.gd",
    "game/screens/RaidPrep.gd",
    "game/screens/RaiderDetail.gd",
]

var _db = null
var _mounted: Array = []
var _made: Array = []
var _borrowed = null
var _borrowed_content = null
var _emoji_free_was = null


func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _mounted = []
    _made = []


func after_each() -> void:
    # The option is global and persisted, so a test that flips it and dies would
    # change the developer's own settings file. Restore before anything else.
    if _emoji_free_was != null:
        var gs = _root().get_node_or_null("GameSettings")
        if gs != null:
            gs.set_value("emoji_free", _emoji_free_was)
        _emoji_free_was = null
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
            n.free()
    _made = []


func _root() -> Node:
    var loop := Engine.get_main_loop()
    return (loop as SceneTree).root if loop is SceneTree else null


## The same live-autoload shape test_tavern.gd uses: borrow the real GameState if
## the autoloads exist under `--script`, otherwise provide them.
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
    if root.get_node_or_null("GameSettings") == null:
        var gs = SettingsScript.new()
        gs.name = "GameSettings"
        root.add_child(gs)
        _mounted.append(gs)
    st.reset()
    st.set_content(_db)
    st.new_game(guild)
    st.gold = gold
    return st


func _settings():
    return _root().get_node_or_null("GameSettings")


func _set_emoji_free(on: bool) -> void:
    var gs = _settings()
    if gs == null:
        return
    if _emoji_free_was == null:
        _emoji_free_was = gs.get_value("emoji_free")
    gs.set_value("emoji_free", on)


func _tavern() -> Control:
    var view := TavernView.new()
    _root().add_child(view)
    _mounted.append(view)
    view.build()
    return view


func _labels(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _labels(c, out)
    return out


func _printed(n: Node) -> String:
    return "\n".join(PackedStringArray(_labels(n)))


## Type.gd's constants by name. The script is `load`ed rather than reached
## through the `const Type` above, because calling `get_script_constant_map()` on
## a preloaded class is a parse error in 4.7 — it is an instance method on the
## Script resource, and a const class reference is not an instance.
func _type_consts() -> Dictionary:
    var s: GDScript = load("res://game/ui/Type.gd")
    return s.get_script_constant_map()


func _read(rel: String) -> String:
    var f := FileAccess.open("res://" + rel, FileAccess.READ)
    return "" if f == null else f.get_as_text()


func _gd_files(dir: String, out: Array = []) -> Array:
    var d := DirAccess.open("res://" + dir)
    if d == null:
        return out
    d.list_dir_begin()
    var name := d.get_next()
    while name != "":
        if d.current_is_dir():
            if not name.begins_with("."):
                _gd_files(dir + "/" + name, out)
        elif name.ends_with(".gd"):
            out.append(dir + "/" + name)
        name = d.get_next()
    d.list_dir_end()
    return out


# ================================================ docs/13 §4.4 — the text scale

## Nothing may move at 100%. The art pass's pixel-diff baselines were all measured
## at the unscaled sizes (BUILD_STATE.md: Kit 16.9 / Town 26.3 / RaidPrep 20.2
## MAE), so threading `Type.at` through the Theme has to be provably free.
func test_text_scale_is_exactly_identity_at_100_percent() -> void:
    var consts: Dictionary = _type_consts()
    for key in READABLE_SIZES + DECORATIVE_SIZES:
        var size: int = int(consts[key])
        assert_eq(Type.at(size, 100), size, "Type.%s must not move at 100%%" % key)
    assert_eq(Type.at(Type.LOG_ROW_PITCH, 100), Type.LOG_ROW_PITCH,
        "the log pitch must not move either")


## docs/13 §4.4: "Three user text scales — 100% / 125% / 150% — applied as a
## multiplier to every style". A multiplier, so the arithmetic is checkable.
func test_text_scale_applies_docs_13_4_4s_three_steps() -> void:
    assert_eq(Type.SCALES, [100, 125, 150], "§4.4 lists three steps")
    assert_eq(Type.at(20, 125), 25, "20px at 125%")
    assert_eq(Type.at(20, 150), 30, "20px at 150%")
    assert_eq(Type.at(15, 125), 19, "15px at 125% rounds to 19, not 18")
    var consts: Dictionary = _type_consts()
    for key in READABLE_SIZES + DECORATIVE_SIZES:
        var size: int = int(consts[key])
        assert_true(Type.at(size, 125) > size,
            "Type.%s must actually grow at 125%%" % key)
        assert_true(Type.at(size, 150) > Type.at(size, 125),
            "Type.%s must grow again at 150%%" % key)


## §4.4 gives three steps "and nothing between them", so a value from a
## hand-edited settings.cfg falls back to a step that exists — and falls back the
## SAME WAY `GameSettings._coerce` does, because a second recovery policy for the
## same key is a second implementation of §4.4.
func test_text_scale_recovery_matches_the_settings_autoload() -> void:
    assert_eq(Type.SCALES, SettingsScript.TEXT_SCALES,
        "§4.4's table is one table; Type.SCALES and GameSettings.TEXT_SCALES are "
        + "two copies of it and must not drift")
    for s in Type.SCALES:
        assert_eq(Type.step(int(s)), int(s), "a documented step is itself")
    # Not a step: GameSettings._coerce returns DEFAULTS["text_scale"], so this
    # does too. The pairs are checked against the autoload's own arithmetic
    # rather than against a hard-coded 100.
    #
    # The setting is persisted, so the developer's own scale is put back before
    # the test returns. `assert_*` in this harness records and continues rather
    # than aborting, so the restore runs even on a failure.
    var gs = _settings()
    var was = gs.get_value("text_scale") if gs != null else null
    for odd in [0, 99, 110, 124, 140, 151, 400]:
        assert_eq(Type.step(odd), Type.SCALE_DEFAULT,
            "%d is not in §4.4's table, so it falls back to the default" % odd)
        if gs != null:
            gs.set_value("text_scale", odd)
            assert_eq(gs.get_value("text_scale"), Type.step(odd),
                ("GameSettings coerced %d differently from Type.step — one "
                + "undefined input, two answers") % odd)
    if gs != null:
        gs.set_value("text_scale", was)
    assert_eq(Type.at(37, 400), Type.at(37, Type.SCALE_DEFAULT),
        "so does the multiplier")


## The factor itself, before it is used on anything. `keep` takes the SMALLER
## ratio, and the difference between the two candidates is not academic: it is the
## whole verdict on §13's blocking text-size row. At 1.0547 two styles miss the
## floor; at 1.25 none of them do, which is how an invented factor came to certify
## a row that does not hold.
func test_the_letterbox_factor_is_not_the_width_ratio() -> void:
    var by_width: float = REPORTED_AT.x / FRAME.x
    var by_height: float = REPORTED_AT.y / FRAME.y
    assert_almost(LETTERBOX, minf(by_width, by_height), 1e-9,
        "`keep` scales by the smaller ratio — project.godot:46")
    assert_almost(LETTERBOX, 1.0546875, 1e-9, "specs/11 §1's own x1.0547")
    assert_almost(WIDTH_RATIO_ONLY, 1.25, 1e-9, "the width ratio, for contrast")
    # specs/11 §1: "the reference frame scaled to 1080 tall is 1620 wide".
    assert_almost(FRAME.x * LETTERBOX, 1620.0, 0.5,
        "the letterboxed frame is 1620 wide, not 1920 — so 1.25 is unreachable")
    # And the two disagree about SMALL, which is the row's whole subject.
    var consts: Dictionary = _type_consts()
    var small: float = float(int(consts["SMALL"]))
    assert_true(small * LETTERBOX < MIN_READABLE_1920,
        "SMALL renders at %.2fpx under the real letterbox" % (small * LETTERBOX))
    assert_true(small * WIDTH_RATIO_ONLY >= MIN_READABLE_1920,
        "...and at %.2fpx under the invented one, which is why it read as passing"
            % (small * WIDTH_RATIO_ONLY))


## docs/13 §13: "Minimum text size: 14px at 1920x1080 for anything the player must
## read. 12px permitted only for decorative stamps whose content is duplicated in
## readable text."
##
## THIS TEST RECORDS A FAILURE OF THAT ROW RATHER THAN CERTIFYING IT. Two styles
## miss the floor once the real letterbox factor is applied, and neither is this
## agent's to repaint (see BELOW_FLOOR_AT_1920 and build/plan/q-a11y-legible.md).
## The exact list and the exact rendered pixel sizes are asserted so that a
## repaint, a ruling, or a new style smaller than QUOTE all turn it red.
func test_docs_13_13s_text_floor_is_missed_by_exactly_two_styles() -> void:
    var consts: Dictionary = _type_consts()
    var below: Array = []
    for key in READABLE_SIZES + DECORATIVE_SIZES:
        if float(int(consts[key])) * LETTERBOX < MIN_READABLE_1920:
            below.append(key)
    assert_eq(below, BELOW_FLOOR_AT_1920,
        "the styles under §13's 14px-at-1920 floor at the project's own x1.0547. "
        + "If this list grew, a new style is too small; if it shrank, the ruling "
        + "in build/plan/q-a11y-legible.md landed and this comment is stale")
    # The two figures the q entry quotes, so the doc and the suite cannot drift.
    assert_almost(float(int(consts["SMALL"])) * LETTERBOX, 13.71, 0.01,
        "SMALL is 13.71px at 1920x1080")
    assert_almost(float(int(consts["STACK"])) * LETTERBOX, 11.60, 0.01,
        "STACK is 11.60px at 1920x1080")
    # STACK misses even the decorative allowance, which is the smaller half of
    # the same defect and is asserted separately so a fix to one is visible.
    assert_true(float(int(consts["STACK"])) * LETTERBOX < MIN_DECORATIVE_1920,
        "STACK now clears §13's 12px decorative allowance — good, update the q "
        + "entry and this assertion together")
    # Everything ABOVE the two is genuinely clear, which is the half that IS a
    # certification: QUOTE at 14 is the smallest style that passes (14.77px).
    for key in READABLE_SIZES:
        if BELOW_FLOOR_AT_1920.has(key):
            continue
        assert_true(float(int(consts[key])) * LETTERBOX >= MIN_READABLE_1920,
            "Type.%s is %.2fpx at 1920x1080, under §13's 14px floor"
                % [key, float(int(consts[key])) * LETTERBOX])


# ============================================= docs/13 §13 — emoji-free mode

## The inventory that makes a tenth site impossible. A source scan, because the
## defect M6-A11Y-04 found was not a wrong pixel — it was eight files each
## reaching past the setting, and no rendered screen can report that.
func test_only_the_funnel_reads_the_raw_morale_emoji_table() -> void:
    var offenders: Array = []
    for path in _gd_files("game"):
        if GLYPH_FUNNEL.has(path):
            continue
        var src := _read(path)
        if src.contains("MORALE_BAND_EMOJI") or src.contains("morale_band_emoji"):
            offenders.append(path)
    for path in offenders:
        assert_true(GLYPH_HANDOFF_PENDING.has(path),
            ("%s reads the raw morale emoji table instead of "
            + "Cards.morale_glyph(), so docs/13 §13's emoji-free mode does not "
            + "reach it") % path)
    # NOT `assert_false(offenders.has("game/ui/Cards.gd"))` — Cards.gd is in
    # GLYPH_FUNNEL and is `continue`d above, so that assertion could never fail
    # and read as a guard on the funnel while guarding nothing. The guard the
    # funnel actually needs is that both exempt files still DO the job their
    # exemption is granted for.
    var cards_src := _read("game/ui/Cards.gd")
    assert_true(cards_src.contains("static func morale_glyph("),
        "Cards.gd is exempt because it DEFINES the funnel — if morale_glyph "
        + "moved, this file's exemption is stale and every caller is a bypass")
    assert_true(cards_src.contains("settings.morale_glyph("),
        "the funnel must ask GameSettings first; reading the raw table is its "
        + "no-autoload fallback, not its behaviour")
    var settings_src := _read("game/core/GameSettings.gd")
    assert_true(settings_src.contains("emoji_free"),
        "GameSettings.gd is exempt because it implements §13's substitution")
    # Tavern is NOT exempt, so both halves are checked: it names no raw table,
    # and it reaches the funnel rather than inventing a third path.
    assert_false(offenders.has("game/screens/Tavern.gd"),
        "Tavern's two morale sites go through the funnel")
    assert_true(_read("game/screens/Tavern.gd").contains("Cards.morale_glyph("),
        "Tavern's card reads its glyph through the funnel")


## THE SAME QUESTION ASKED OF THE RUNNING SCREENS, NOT OF THE SOURCE.
##
## The scan above is an inventory and can only see what a file mentions. It cannot
## see a screen that prints a raw face through some other route — `Raider.summary()`
## is sim-side and stays raw on purpose (see below), so a screen that shows a
## summary shows an emoji while naming no emoji table at all. This mounts the town
## screens with emoji-free ON and reads what they actually print.
##
## Tolerant in one direction ONLY: a screen that still prints a face must be one of
## the five M6-A11Y-04 found, each of which is an exact-edit handoff in
## build/plan/handoff-a11y-legible.md. A screen that has been FIXED simply passes,
## so applying a handoff never turns this red — but a sixth screen, or a new route
## to the raw table, does.
func test_no_town_screen_prints_a_raw_morale_face_under_emoji_free() -> void:
    var st = _live_state("Legible Test")
    if st.tavern_board.is_empty():
        st.refresh_board()
    _set_emoji_free(true)
    var checked := 0
    var offending: Array = []
    for path in ["game/screens/Town.gd", "game/screens/Roster.gd",
            "game/screens/Guildhall.gd", "game/screens/Facilities.gd",
            "game/screens/Market.gd", "game/screens/RaidPrep.gd"]:
        var script: GDScript = load("res://" + path)
        if script == null or not script.can_instantiate():
            continue
        var view: Control = script.new()
        _root().add_child(view)
        _mounted.append(view)
        if view.has_method("build"):
            view.build()
        var printed := _printed(view)
        if printed.is_empty():
            continue
        checked += 1
        for face in Enums.MORALE_BAND_EMOJI:
            if printed.contains(String(face)):
                offending.append(path)
                break
    assert_true(checked >= 4, "at least four town screens mounted and printed")
    for path in offending:
        assert_true(GLYPH_HANDOFF_PENDING.has(path),
            ("%s prints a raw morale face with emoji_free on. If it is a screen "
            + "the M6-A11Y-04 handoff already covers, add it to "
            + "GLYPH_HANDOFF_PENDING; otherwise it is a NEW bypass") % path)
    # The inventory is only worth keeping while it is true. Recorded as a plain
    # count so the report and the handoff file cannot quietly diverge from it.
    assert_true(offending.size() <= GLYPH_HANDOFF_PENDING.size(),
        "more screens ignore emoji_free than the handoff lists")


## sim/ must NOT be routed through the setting: house rule 6 keeps it pure, and
## `Raider.summary()` / `Morale.band_emoji()` are sim-side. Asserted so a future
## sweep of A11Y-04 does not "finish the job" by breaking the sim's purity.
func test_the_sim_keeps_its_own_raw_glyph_and_that_is_correct() -> void:
    var src := _read("sim/model/Raider.gd")
    assert_true(src.contains("morale_band_emoji"),
        "Raider.summary() is sim-side and may not read an autoload — it stays raw")


## docs/13 §13: emoji-free mode "Replaces morale glyphs with a 10-step monochrome
## pip figure." Mounted for real, because the point of the item was that the
## option changed one panel out of eight.
func test_the_tavern_board_honours_emoji_free() -> void:
    var st = _live_state("Legible Test")
    if st.tavern_board.is_empty():
        st.refresh_board()
    _set_emoji_free(true)
    var printed := _printed(_tavern())
    for face in Enums.MORALE_BAND_EMOJI:
        assert_false(printed.contains(String(face)),
            "emoji-free mode still prints %s on the Tavern" % String(face))
    assert_true(printed.contains("|"),
        "the 10-step pip figure replaces the glyph, it does not vanish")


## §13's promise, quoted: "The integer and state word are unaffected." That is the
## whole reason emoji-free mode is safe to offer, so it is asserted separately.
func test_emoji_free_keeps_the_integer_and_the_state_word() -> void:
    var st = _live_state("Legible Test")
    if st.tavern_board.is_empty():
        st.refresh_board()
    _set_emoji_free(true)
    var printed := _printed(_tavern())
    for who in st.tavern_board:
        var m: int = int(who.morale)
        assert_true(printed.contains("starts at %d" % m),
            "the morale integer survives emoji-free mode")
        assert_true(printed.contains(Enums.morale_band_name(m)),
            "the state word survives emoji-free mode")


# ==================================== docs/13 §13 — the four-channel morale read

## docs/13 §13, blocking: a morale reading carries "the integer, the state word,
## the glyph, and the chip's lightness". The Tavern recruit card carried three.
## docs/13 §9.4's S06 wireframe shows the word on its own row, which is where it
## went — a test cannot see the colour or the tint, so the word is the channel
## that makes this checkable at all.
func test_every_recruit_card_names_its_morale_state() -> void:
    var st = _live_state("Legible Test")
    if st.tavern_board.is_empty():
        st.refresh_board()
    var view := _tavern()
    var printed := _printed(view)
    var checked := 0
    for who in st.tavern_board:
        var m: int = int(who.morale)
        assert_true(printed.contains("starts at %d" % m),
            "the recruit card prints the morale integer")
        assert_true(printed.contains(Enums.morale_band_name(m)),
            "the recruit card names the morale state (%d -> %s)"
                % [m, Enums.morale_band_name(m)])
        checked += 1
    assert_true(checked > 0, "the board had candidates to check")


# ============================== docs/13 §13 — colour is never the only signal

## docs/07 §10.1 lists SEVEN verbs and `Enums.Verb` has seven members. Every one
## now carries a glyph, and the two ATTACK directions have DIFFERENT glyphs —
## that pair ("the boss hit someone" vs "someone hit the boss") was INFO vs
## CAUTION, the exact kind of distinction a dichromat loses.
##
## Enumerated from `Enums.Verb` itself rather than from a hand-written list: the
## previous list had six entries and SYSTEM — the verb `RaidView` paints DANGER
## on a wipe line — was the one nothing noticed was missing.
func test_every_combat_log_event_class_carries_a_glyph() -> void:
    var verbs: Array = Enums.Verb.values()
    assert_eq(verbs.size(), 7, "docs/07 §10.1 names seven verbs")
    assert_eq(verbs.size(), Enums.VERB_KEYS.size(), "and one key each")
    for verb in verbs:
        var g := Badge.glyph_for_verb(int(verb))
        assert_false(g.is_empty(),
            "verb %s has no glyph, so its rows are separated by hue alone"
                % Enums.VERB_KEYS[int(verb)])
        assert_eq(g.length(), 1, "a badge glyph is one character at 18px")
    var out := Badge.glyph_for_verb(Enums.Verb.ATTACK, true)
    var back := Badge.glyph_for_verb(Enums.Verb.ATTACK, false)
    assert_ne(out, back,
        "raider-attack and boss-attack must not share a glyph — hue was the only "
        + "thing separating them")
    assert_eq(Badge.glyph_for_verb(-1), "",
        "an unknown verb draws the reference's bare disc, not a wrong glyph")


## A second channel that repeats itself is not a second channel. Only one pair
## may share a glyph — MISTAKE and STATE_CHANGE, which `RaidView._row_style`
## already paints identically (both DANGER) because a mistake and the state it
## causes are one event to the reader.
func test_no_two_log_classes_share_a_glyph_except_the_documented_pair() -> void:
    var by_glyph := {}
    for verb in Enums.Verb.values():
        var g := Badge.glyph_for_verb(int(verb))
        var key: String = Enums.VERB_KEYS[int(verb)]
        if by_glyph.has(g):
            by_glyph[g] = String(by_glyph[g]) + "+" + key
        else:
            by_glyph[g] = key
    var shared: Array = []
    for g in by_glyph:
        if String(by_glyph[g]).contains("+"):
            shared.append(String(by_glyph[g]))
    assert_eq(shared, ["mistake+state_change"],
        "the only classes allowed to share a mark")
    assert_ne(Badge.GLYPH_SYSTEM, Badge.GLYPH_PHASE,
        "phase and system sit a few rows apart in the same log")
    assert_ne(Badge.glyph_for_verb(Enums.Verb.ATTACK, false), Badge.GLYPH_SYSTEM,
        "the boss's swing and the sim's own narration are different marks")


## `Badge._draw` needs a frame and this runner never reaches one, so the geometry
## it depends on is asserted through `Badge.glyph_layout` instead — the same
## arithmetic, lifted out for exactly this reason. A glyph half outside its disc
## is invisible to every other test in the suite.
func test_the_badge_glyph_sits_inside_its_disc() -> void:
    var font: Font = ThemeDB.fallback_font
    assert_ne(font, null, "there is a fallback font to measure with")
    for box in [Vector2(18, 18), Vector2(24, 24), Vector2(12, 12)]:
        var lay: Dictionary = Badge.glyph_layout(box, font, Badge.GLYPH_MISTAKE)
        var px: int = int(lay["px"])
        var pos: Vector2 = lay["pos"]
        var r: float = minf(box.x, box.y) * 0.5
        # The inner square of a circle of radius r has side r*sqrt(2). A glyph
        # sized past that overhangs the disc at the corners.
        assert_true(float(px) <= r * sqrt(2.0) + 0.5,
            "%.0fpx disc: a %dpx glyph does not fit its inner square"
                % [box.x, px])
        assert_true(px >= 8, "never smaller than the fallback font's floor")
        var adv: Vector2 = font.get_char_size(Badge.GLYPH_MISTAKE.unicode_at(0), px)
        # Horizontally centred on the advance, to within a rounding pixel.
        assert_almost(pos.x + adv.x * 0.5, box.x * 0.5, 0.001,
            "the advance is centred on the disc")
        # The baseline sits below the centre by half an ascent, so the glyph's
        # own body straddles it: cap top above the centre, baseline below.
        var ascent: float = font.get_ascent(px)
        assert_true(pos.y > box.y * 0.5, "the baseline is below the centre")
        assert_true(pos.y - ascent < box.y * 0.5,
            "and the glyph's top is above it — otherwise it hangs off the disc")
        assert_true(pos.y <= box.y, "the baseline is inside the badge")
    # The floor bites before the disc vanishes: a 4px badge would compute a 3px
    # glyph, and `_draw` refuses to draw anything at r <= 1 anyway.
    assert_eq(int(Badge.glyph_layout(Vector2(4, 4), font, "!")["px"]), 8,
        "the 8px floor holds at any disc size")


## The ink is chosen by contrast rather than fixed, because the six log hues run
## from light amber to dark violet and one ink cannot serve both.
func test_the_badge_glyph_ink_is_readable_on_every_log_hue() -> void:
    for fill in [Palette.DANGER, Palette.CAUTION, Palette.POSITIVE,
            Palette.INFO, Palette.ARCANE, Palette.EDGE_SLATE,
            Palette.TEXT_MUTED]:
        var ink := Badge.ink_for(fill)
        assert_true(Badge._contrast(fill, ink) >= 3.0,
            "badge ink on %s is only %.2f:1 — §13 asks 3:1 of a UI boundary"
                % [fill.to_html(false), Badge._contrast(fill, ink)])
    assert_eq(Badge.ink_for(Palette.CAUTION), Palette.TEXT_ON_BUBBLE,
        "a light amber disc takes the dark ink")
    assert_eq(Badge.ink_for(Palette.ARCANE), Palette.ACCENT_BUBBLE,
        "a dark violet disc takes the cream ink")


## The event log's own second channel: the badge sprite. The seven crops are
## keyed by MEANING here because spec 01 §4.2's list of what they contain is
## wrong (badge_4 is a grimace, badge_5 a green smile — no up-arrow, no item).
func test_the_event_log_badge_resolves_for_both_morale_kinds() -> void:
    assert_ne(Cards.badge_icon("morale_down"), null, "a bad day has a sad face")
    assert_ne(Cards.badge_icon("morale_up"), null, "a good day has a happy face")
    assert_eq(Cards.badge_icon(""), null, "an unclassified row keeps the disc")
    assert_eq(Cards.badge_icon("loot"), null,
        "a kind with no feed and no verified sprite returns null rather than "
        + "guessing at a crop")


## THE BUG THIS FOUND. `recent_events` derived its row colour from
## `e.get("delta", 0.0)`, but a `morale_log` entry is `{day, morale, note}` and has
## never had a `delta` — so every row in the event log rendered POSITIVE green
## whatever happened. The sign now comes from docs/05 §7's trigger table.
func test_the_event_log_sign_comes_from_the_trigger_table() -> void:
    var st = _live_state("Legible Test")
    if st.tavern_board.is_empty():
        st.refresh_board()
    assert_true(st.tavern_board.size() > 0, "need a candidate to borrow")
    var who = st.tavern_board[0]
    st.roster.append(who)
    # "wipe" is -8.0 and "cleared" is +6.0 in docs/05 §7.1's table.
    who.morale_log.clear()
    who.record_morale_day(1, 40, "wipe")
    who.record_morale_day(2, 46, "cleared")
    var events: Array = Cards.recent_events(st, 7)
    assert_eq(events.size(), 2, "both notes reached the log")
    var by_note := {}
    for e in events:
        for note in ["wipe", "cleared"]:
            if String(e.get("note", "")) == note:
                by_note[note] = e
    assert_has(by_note, "wipe", "the wipe row is in the log")
    assert_has(by_note, "cleared", "the cleared row is in the log")
    assert_eq(by_note["wipe"]["kind"], "morale_down", "a wipe reads as a loss")
    assert_eq(by_note["cleared"]["kind"], "morale_up", "a clear reads as a gain")
    assert_eq(by_note["wipe"]["tone"], Palette.DANGER, "and it is not green")
    assert_ne(by_note["wipe"]["tone"], by_note["cleared"]["tone"],
        "the two signs no longer render identically")


## THE REGRESSION THE TRIGGER-TABLE FIX INTRODUCED, ASSERTED SO IT CANNOT COME
## BACK. `morale_log` notes are not all §7 trigger ids: `GameState.use_rally_flask`
## writes "rally_flask" (docs/11 §7, a morale GAIN — it refunds half the wipe
## penalty) and `Morale.TRIGGERS` has no such key, so keying the sign off that
## table alone gave the row delta 0.0 — no badge sprite and no hue, losing BOTH of
## docs/13 §13's channels on a row that is unambiguously good news.
func test_a_note_outside_the_trigger_table_still_carries_a_sign() -> void:
    # The premise, first: if a future doc adds the trigger, this test is stale
    # rather than wrong, and it says so here instead of failing obscurely below.
    assert_false(Morale.TRIGGERS.has("rally_flask"),
        "docs/05 §7 now carries rally_flask — drop it from Cards.NOTE_SIGN and "
        + "let the trigger table answer")
    assert_true(Cards.NOTE_SIGN.has("rally_flask"),
        "a note that reaches the log and is in no §7 row needs a sign somewhere")
    var st = _live_state("Legible Test")
    if st.tavern_board.is_empty():
        st.refresh_board()
    var who = st.tavern_board[0]
    st.roster.append(who)
    who.morale_log.clear()
    # One row per DAY: `Raider.record_morale_day` overwrites a repeat of the same
    # day, which is also why the flask needs its own NOTE_SIGN row — drunk on the
    # day of the wipe it REPLACES the wipe's note, and the day-on-day difference
    # it would otherwise be signed by is the wipe's loss, not the flask's gain.
    who.record_morale_day(1, 40, "wipe")
    who.record_morale_day(2, 46, "rally_flask")
    # A note in neither table: the sign comes from the history the log itself
    # recorded — 46 -> 39 is a loss whatever the note is called.
    who.record_morale_day(3, 39, "a_note_no_table_has_ever_heard_of")
    var by_note := {}
    for e in Cards.recent_events(st, 9):
        by_note[String(e.get("note", ""))] = e
    assert_has(by_note, "rally_flask", "the flask row reached the log")
    assert_eq(by_note["rally_flask"]["kind"], "morale_up",
        "a Rally Flask is a gain and must carry the gain badge")
    assert_eq(by_note["rally_flask"]["tone"], Palette.POSITIVE,
        "and the gain hue — not TEXT_MUTED, which is neither channel")
    assert_ne(Cards.badge_icon(String(by_note["rally_flask"]["kind"])), null,
        "so the row draws a badge sprite rather than a bare grey disc")
    assert_eq(by_note["a_note_no_table_has_ever_heard_of"]["kind"], "morale_down",
        "an unknown note takes its sign from the morale the log recorded")
    assert_eq(by_note["wipe"]["kind"], "morale_down",
        "and a note that IS in the table still comes from the table")


## The first row a raider ever records has no previous morale to difference
## against, so an unknown note there is the one case that stays neutral. Asserted
## because the alternative — guessing a sign — would paint a wrong badge, and a
## wrong second channel is worse than an absent one.
func test_an_unknown_note_on_the_first_recorded_day_stays_neutral() -> void:
    var st = _live_state("Legible Test")
    if st.tavern_board.is_empty():
        st.refresh_board()
    var who = st.tavern_board[0]
    st.roster.append(who)
    who.morale_log.clear()
    who.record_morale_day(1, 50, "an_unheard_of_note")
    var events: Array = Cards.recent_events(st, 4)
    assert_eq(events.size(), 1, "the row is in the log")
    assert_eq(events[0]["kind"], "", "with no claimed direction")
    assert_eq(events[0]["tone"], Palette.TEXT_MUTED, "and the neutral tone")
    assert_eq(Cards.badge_icon(""), null, "which draws the reference's disc")


# ================================== docs/13 §14 — the card fits inside the frame

## Every Label that is a backstory bullet on this card.
func _bullets_on(card: Node, n: int = 0) -> int:
    if card is Label and String((card as Label).text).begins_with("• "):
        n += 1
    for c in card.get_children():
        n = _bullets_on(c, n)
    return n


func _scroll_in(card: Node):
    if card is ScrollContainer:
        return card
    for c in card.get_children():
        var found = _scroll_in(c)
        if found != null:
            return found
    return null


## THE REGRESSION THIS CAUGHT, AND WHY IT IS ASSERTED ON THE MINIMUM SIZE.
##
## `Cards.roster_strip` assigns every card `Widgets.CARD_SIZE`, but `Control.size`
## clamps UP to `get_combined_minimum_size()`, so a card whose content needs more
## than 262px grows instead of holding its box. Adding the §13 state-word row did
## exactly that. Measured on a mounted Tavern at 1536x1024, layout settled over ten
## frames (tools/art/_probe_tavern.gd, transient):
##
##            before            after
##   2 bullets  262 / y996       262 / y996
##   3 bullets  278 / y1012      262 / y996
##   4 bullets  318 / y1052      262 / y996
##   4 long     398 / y1132      262 / y996
##
## and the Legendary's "Look" — docs/04 §3.5's primary control on the decision
## surface — sat at global y1005..1040, 16px of a 35px button below the 1024
## frame. It is now at y949..984 in every case.
##
## The suite cannot settle a frame (tests/run_tests.gd does everything in
## `_initialize`), so the assertion is made one level up, on the quantity that
## DRIVES the laid-out size: the card's combined minimum. Two properties, and the
## second is the one the old code failed — asserting `min <= 262` alone would have
## passed before the fix too, because an unwrapped Label reports one line.
func test_the_candidate_card_fits_its_strip_at_every_bullet_count() -> void:
    var st = _live_state("Legible Test")
    if st.tavern_board.is_empty():
        st.refresh_board()
    var view := _tavern()
    var who = st.tavern_board[0]
    var src: Array = who.backstory.duplicate(true)
    assert_true(src.size() > 0, "the candidate has a bullet to repeat")
    var mins: Array = []
    # docs/04 §6.2 / BackstoryPool.BULLET_COUNTS: 2-3 at the middle rarities,
    # MAX_BULLETS = 4 for a Legendary.
    for n in [2, 3, 4]:
        var padded: Array = []
        for i in n:
            padded.append((src[i % src.size()] as Dictionary).duplicate(true))
        who.backstory = padded
        var card: Control = view._candidate_card(who, 1)
        view.add_child(card)
        _mounted.append(card)
        assert_eq(_bullets_on(card), n,
            "docs/04 §3.5: all %d bullets are on the card, none hidden" % n)
        var scroll = _scroll_in(card)
        assert_ne(scroll, null,
            "the bullet block scrolls; docs/13 §4.4 allows reflow by scrolling "
            + "and forbids truncation, and growth past the frame is neither")
        assert_eq(scroll.horizontal_scroll_mode,
            ScrollContainer.SCROLL_MODE_DISABLED,
            "horizontal scrolling off, so the bullets wrap to the card's width "
            + "instead of widening it past the 224px pitch")
        assert_ne(scroll.vertical_scroll_mode,
            ScrollContainer.SCROLL_MODE_DISABLED,
            "vertical scrolling on, which is what makes the block cost the card "
            + "no minimum height")
        mins.append(card.get_combined_minimum_size().y)
    who.backstory = src
    # 1. The bullets no longer drive the card's height at all.
    assert_eq(mins[0], mins[2],
        "a 4-bullet Legendary card must want exactly the height a 2-bullet card "
        + "does (%s) — if these differ, the bullets are outside the scroll again"
            % str(mins))
    # 2. And that height fits the authored box, so `roster_strip`'s assignment
    #    wins and the card is exactly CARD_SIZE.
    assert_true(float(mins[2]) <= float(Widgets.CARD_SIZE.y),
        "the card wants %.0fpx and spec 01 §3 authored %d" % [mins[2],
            Widgets.CARD_SIZE.y])
    assert_eq(Widgets.CARD_SIZE.y, Widgets.STRIP_H,
        "the card is the strip's full height, so its bottom IS the strip's")
    assert_true(Widgets.STRIP_Y + Widgets.CARD_SIZE.y <= Widgets.SCREEN.y,
        "strip top %d + card %d must land inside the %dpx frame (docs/13 §14)"
            % [Widgets.STRIP_Y, Widgets.CARD_SIZE.y, Widgets.SCREEN.y])
    assert_eq(Widgets.STRIP_Y + Widgets.CARD_SIZE.y, 996,
        "spec 01 §4.2 unifies the strip's bottom edge at y=995")


## The glyph is drawn in `Badge._draw()`, which no headless test can enter (the
## runner never reaches a frame). So the two Font calls that path depends on are
## exercised here instead: a signature change in either would otherwise surface
## as a blank disc in the shipped game and in nothing else.
func test_the_badge_glyph_draw_path_has_the_font_api_it_needs() -> void:
    var font: Font = ThemeDB.fallback_font
    assert_ne(font, null, "there is a fallback font to draw a glyph with")
    var adv: Vector2 = font.get_char_size(Badge.GLYPH_MISTAKE.unicode_at(0), 12)
    assert_true(adv.x > 0.0, "get_char_size(char, size) returns an advance")
    assert_true(font.get_ascent(12) > 0.0, "get_ascent(size) returns an ascent")
    var b = Badge.new()
    b.glyph = Badge.GLYPH_HEAL
    b.color = Palette.POSITIVE
    assert_eq(b.glyph, Badge.GLYPH_HEAL, "the glyph setter keeps its value")
    assert_eq(b.color, Palette.POSITIVE, "the colour setter still works")
    b.free()


# ================================== docs/13 §8.3 / §13 — the CVD ramp is an option

## UI-47 / M6-A11Y-06: `colourblind_safe` used to be a key `Palette.cvd_safe()`
## probed for and never found — the §8.3 ramp was unreachable in the shipped
## game while BUILD_STATE called it a switch. It is in the inventory now, default
## Off (the reference's ramp stays the default until the ruling; ship plan §6
## #40), with a row on the Options screen. This pins the wire: the option
## exists, Palette reads THIS autoload's value, and the door selects the ramp.
func test_the_cvd_ramp_is_a_player_option_default_off() -> void:
    assert_true(SettingsScript.DEFAULTS.has(Palette.OPT_CVD_SAFE),
        "colourblind_safe is in docs/13 §15.1's inventory")
    assert_false(bool(SettingsScript.DEFAULTS[Palette.OPT_CVD_SAFE]),
        "the CVD ramp ships Off — the reference ramp is the default until ruled on")
    var loop := Engine.get_main_loop()
    var root: Node = (loop as SceneTree).root if loop is SceneTree else null
    var settings = root.get_node_or_null("GameSettings") if root != null else null
    assert_ne(settings, null, "the GameSettings autoload must be registered")
    if settings == null:
        return
    settings.reset_all()
    assert_false(Palette.cvd_safe(null), "off by default: the reference ramp")
    assert_eq(Palette.band_color_active(null, 45), Palette.band_color(45))
    settings.set_value(Palette.OPT_CVD_SAFE, true)
    assert_true(Palette.cvd_safe(null), "Palette reads the autoload's value")
    assert_eq(Palette.band_color_active(null, 45), Palette.band_color_cvd(45),
        "on: docs/13 §8.3's plate")
    assert_eq(Palette.morale_color(45), Palette.band_color(45),
        "the text-tint sites stay on the reference ramp (test_palette_cvd.gd)")
    settings.reset_all()
