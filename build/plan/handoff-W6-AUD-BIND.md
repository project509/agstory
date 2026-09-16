# handoff-W6-AUD-BIND

Edits this unit needs in files it does not own (00-plan §1 wave-6 ownership: `Widgets.gd` is W6-LOG's this wave; `AdventureBoard.gd` and `Market.gd` are W6-COPY's; `Tavern.gd` is untouched this wave). Applied by the orchestrator at the wave's close, together with §8's test cases — code and test land in one step. Every hook name is a string in `Audio.HOOKS` (in the tree at the wave's start) and every lookup is `Services.find(node, "Audio")`, so nothing here references a function another unit is adding. `Widgets.gd` is TABS; the three screens are `AdventureBoard.gd` TABS, `Market.gd` SPACES, `Tavern.gd` TABS. Line numbers are as read on 2026-09-15 and will drift; the anchors are the function bodies.

## 1. game/ui/Widgets.gd:740 — `ui.seal` on every commit press, and in-screen `ui.tab`

docs/13 §12.4: `ui.seal` fires on "any WaxButton commit — on press, not release", so the bind is `button_down` (never `pressed`, which is the release). Every commit control goes through `cta()` / `cta_priced()` (both end in `_guard_cta`) or `wax_button()`; a disabled Button emits no `button_down`, so a `reasoned` CTA stays silent for free. Kit-level: no screen learns about audio, and RaidPrep's Depart, the wipe's "Try again" / "Return to town", the Market's Buy, the Tavern's Hire all inherit it. `Services` is already a const in this file (`:36`).

old:
```
static func _guard_cta(b: Button) -> void:
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
```
new:
```
static func _guard_cta(b: Button) -> void:
	# docs/13 §12.4: `ui.seal` — "any WaxButton commit", "on press, not
	# release" — so `button_down`, never `pressed`. A disabled Button emits
	# no `button_down`, which is how a `reasoned` CTA stays silent (W6-AUD-BIND).
	b.button_down.connect(func() -> void:
		var audio: Node = Services.find(b, "Audio")
		if audio != null:
			audio.play("ui.seal"))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
```

## 2. game/ui/Widgets.gd:801 — the same press on `wax_button`

old:
```
static func wax_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = "ButtonCta"
	return b
```
new:
```
static func wax_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = "ButtonCta"
	b.button_down.connect(func() -> void:
		var audio: Node = Services.find(b, "Audio")
		if audio != null:
			audio.play("ui.seal"))
	return b
```

## 3. game/ui/Widgets.gd:1043 — `ui.tab` on an in-panel tab press

docs/13 §12.4's "Tab / screen change" is bound for the SCREEN change in `Audio._on_screen_changed`; the Guildhall / Market / Records tabs built by `tab_row` are the in-screen half (AUDIO-04's `ui.tab` row). The row is rebuilt per switch, so the press is the only moment the kit has; the same lambda that remembers focus plays it.

old:
```
		b.pressed.connect(func() -> void:
			if b.has_focus():
				_tab_refocus = true)
```
new:
```
		b.pressed.connect(func() -> void:
			if b.has_focus():
				_tab_refocus = true
			# docs/13 §12.4 "Tab / screen change": the in-screen half (W6-AUD-BIND).
			var audio: Node = Services.find(b, "Audio")
			if audio != null:
				audio.play("ui.tab"))
```

## 4. game/screens/AdventureBoard.gd:908 — `ui.row_select` when a notice is pinned

docs/13 §12.4: `ui.row_select` "on the brass bar wipe". The bar is §12.2 motion the kit never built (M6-JUICE-02); the SELECT gesture exists and is the trigger, the bar was only the sync (AUDIO-04's default: bind to the gesture). `_select` already returns early on a re-select, so this fires on CHANGE only. `Services` is a const in this file (`:45`).

old:
```
func _select(encounter_id: String) -> void:
	if encounter_id == _selected:
		return
	var was := _selected
	_selected = encounter_id
```
new:
```
func _select(encounter_id: String) -> void:
	if encounter_id == _selected:
		return
	var was := _selected
	_selected = encounter_id
	# docs/13 §12.4 `ui.row_select`: the pick, on change only (W6-AUD-BIND).
	var audio: Node = Services.find(self, "Audio")
	if audio != null:
		audio.play("ui.row_select")
```

## 5. game/screens/Market.gd:704 — `ui.row_select` on the sell-row pick

The cell's `pressed` lambda writes `_selected = key` unguarded; the sound goes on the CHANGE (mirror the Board's guard). SPACES in this file. `Services` is a const (`:48`).

old:
```
    b.pressed.connect(func() -> void:
        _selected = key
        _confirming = "" if worn_by.is_empty() else key
        _notice = ""
        _refresh())
```
new:
```
    b.pressed.connect(func() -> void:
        if _selected != key:
            # docs/13 §12.4 `ui.row_select`: the pick, on change only (W6-AUD-BIND).
            var audio: Node = Services.find(self, "Audio")
            if audio != null:
                audio.play("ui.row_select")
        _selected = key
        _confirming = "" if worn_by.is_empty() else key
        _notice = ""
        _refresh())
```

## 6. game/screens/Tavern.gd:606 — `ui.row_select` on the candidate's "Look"

Two lambdas write `_selected = _index_of(who)`: the strip's `grid_action` (`:424`) and the card's Look button (`:607`). The card's button is the one a player presses (the grid action is the kit's tile, which the strip builds from the same board and routes to the same card); one line on the Look press, on change only — "Looking" (the selected card's own button) re-selects and stays silent. TABS. `Services` is a const (`:37`).

old:
```
	look.pressed.connect(func() -> void:
		_selected = _index_of(who)
		_active = "board"
		_refresh())
```
new:
```
	look.pressed.connect(func() -> void:
		if _selected != _index_of(who):
			# docs/13 §12.4 `ui.row_select`: the pick, on change only (W6-AUD-BIND).
			var audio: Node = Services.find(self, "Audio")
			if audio != null:
				audio.play("ui.row_select")
		_selected = _index_of(who)
		_active = "board"
		_refresh())
```

## 7. game/screens/Tavern.gd:423 — the strip tile's pick, the same guard

old:
```
			"grid_action": func(who) -> void:
				_selected = _index_of(who)
				_active = "board"
				_refresh(),
```
new:
```
			"grid_action": func(who) -> void:
				if _selected != _index_of(who):
					var audio: Node = Services.find(self, "Audio")
					if audio != null:
						audio.play("ui.row_select")
				_selected = _index_of(who)
				_active = "board"
				_refresh(),
```

## 8. tests/unit/test_audio_binds.gd:end — the cases for §1-§7, appended at the END of the file

Applied with the seven edits above (a test that lands before its code is red for a wave; one that never lands is a bind nobody proved). Every assertion reads the tape. The file's helpers (`_audio`, `_count`, `_fixture_state`, `_router`, `_button_named`, `_buttons`, `_state`, `_made`, `_host`) exist at the wave's start of this file; `Widgets` and the three screen scripts are preloaded here because the file did not need them before. `old:` is empty — the block is appended whole (the parser writes a new file only for a new path, so the orchestrator appends this by hand or with `cat >>`; the `old:` anchor below is the file's last line, so `apply_handoff.py` can place it too).

old:
```
    assert_false(printed.contains("party stands"))
```
new:
```
    assert_false(printed.contains("party stands"))


# ------------------------------------------ handoff-W6-AUD-BIND §1-§7 (applied at the wave's close)

const Widgets = preload("res://game/ui/Widgets.gd")
const BOARD := "res://game/screens/AdventureBoard.tscn"
const MARKET := "res://game/screens/Market.tscn"
const TAVERN := "res://game/screens/Tavern.tscn"


func _mount_screen(path: String):
    var root := _root()
    var r = _router()
    if _host == null:
        _host = Control.new()
        _host.size = Vector2(1536, 1024)
        root.add_child(_host)
        _made.append(_host)
        r.register_host(_host)
    assert_true(r.goto(path), "could not open %s" % path)
    _audio().tape = []
    return r.current_screen()


func test_a_commit_press_seals_on_button_down_not_on_release() -> void:
    # docs/13 §12.4: `ui.seal` on "any WaxButton commit — on press, not release".
    var a := _audio()
    for b in [Widgets.cta("Depart", "12 of 12 chalked"), Widgets.cta_priced("Buy", 40),
            Widgets.wax_button("Hire")]:
        _made.append(b)
        a.tape = []
        (b as Button).button_down.emit()
        assert_eq(_count("ui.seal"), 1, "%s seals once on the press" % (b as Button).text)
        a.tape = []
        (b as Button).pressed.emit()
        assert_eq(_count("ui.seal"), 0, "and not again on the release")
    # A reasoned (disabled) commit: the engine emits no button_down for a
    # disabled Button under real input, so the bind is silent for free; what
    # this can assert headless is that the reason really disables it.
    var shut := Widgets.cta("Depart")
    var box = Widgets.reasoned(shut, "Chalk at least one raider.", null, 302)
    _made.append(box)
    assert_true(shut.disabled, "a reasoned CTA is disabled, so it never presses")


func test_an_in_screen_tab_press_rings_the_tab() -> void:
    var a := _audio()
    var row = Widgets.tab_row(["Roster", "Facilities", "Records"], 0)
    _made.append(row)
    var tabs: Array = Widgets.tabs_of(row)
    assert_eq(tabs.size(), 3)
    (tabs[1] as Button).pressed.emit()
    assert_eq(_count("ui.tab"), 1, "a tab press is a tab change")
    assert_eq(a.tape.size(), 1)


func test_pinning_a_different_notice_rings_the_row_select_once() -> void:
    _fixture_state()
    var view = _mount_screen(BOARD)
    var was := String(view._selected)
    var other := ""
    for id in view._notices.keys():
        if String(id) != was:
            other = String(id)
            break
    assert_ne(other, "", "the board has a second notice to pin")
    view._select(was)
    assert_eq(_count("ui.row_select"), 0, "re-pinning the pinned one is not a change")
    view._select(other)
    assert_eq(_count("ui.row_select"), 1, "pinning another is one row select")
    view._select(other)
    assert_eq(_count("ui.row_select"), 1)


func test_looking_at_another_candidate_rings_the_row_select_once() -> void:
    _fixture_state()
    var view = _mount_screen(TAVERN)
    var looks: Array = []
    for b in _buttons(view):
        if (b as Button).text == "Look":
            looks.append(b)
    assert_true(looks.size() >= 1, "the fixture's tavern board has a candidate not being looked at")
    (looks[0] as Button).pressed.emit()
    assert_eq(_count("ui.row_select"), 1, "looking at another candidate is one row select")
    var looking = _button_named(view, "Looking")
    assert_ne(looking, null)
    (looking as Button).pressed.emit()
    assert_eq(_count("ui.row_select"), 1, "re-looking at the same one is not a change")


func test_picking_a_sell_row_rings_the_row_select_once() -> void:
    # The Market opens on its Sell tab; every sell row is a Button whose text
    # begins "Sell " (`_sell_cell`). The shelf is rebuilt on every press, so
    # each press looks its Button up afresh by text. Whatever the opening
    # pick was, pressing a DIFFERENT row is one change and the same row again
    # is none.
    _fixture_state()
    var view = _mount_screen(MARKET)
    var names: Array = []
    for b in _buttons(view):
        var t := String((b as Button).text)
        if t.begins_with("Sell ") and not (t in names):
            names.append(t)
    assert_true(names.size() >= 2, "the fixture's market has two sell rows (%d found)" % names.size())
    _button_named(view, String(names[0])).pressed.emit()
    var after_first := _count("ui.row_select")
    assert_true(after_first <= 1, "one press is at most one row select")
    _button_named(view, String(names[1])).pressed.emit()
    assert_eq(_count("ui.row_select"), after_first + 1, "a different row is one change")
    _button_named(view, String(names[1])).pressed.emit()
    assert_eq(_count("ui.row_select"), after_first + 1, "the same row again is not a change")
```
