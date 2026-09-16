# handoff-W6-COPY

Edits this unit needs in files it does not own. §1 is applied in-wave by W6-AUD-BIND (RaidPrep.gd's owner) and §2 by W6-LOG (RaidView.gd's owner) — the orchestrator applies neither (00-plan §1 "Wave 6 handoffs expected"). §3-§7 and §9-§11 are for the orchestrator at the close: each group pairs one edit to a file W6-COPY owns (Cards.gd) with the test pins in files it does not, so the flip lands atomically and the tree is never red between them.

Status when this file was written (2026-09-15, in-wave):
- §1 — ALREADY APPLIED by W6-AUD-BIND (RaidPrep.gd:444-452 carries the "LOOP C24 (interim, W6)" sub-line: enemy count and rounds, never the kind). Listed so `apply_handoff.py --dry-run` reports it as such.
- §2 — ALREADY TRUE at the wave's start: RaidView.gd:734-737 prints `_encounter.display_name` on the boss plate under a Q12a comment. No edit needed; listed for the record with old == the current text so the dry run reports ALREADY APPLIED.
- §3-§7 (the Records link) and §9-§11 (the one-raider sentence) — OPEN; the orchestrator applies each group together at the close.
- §12-§15 — OPEN, and RED IN-WAVE: four pins in two test files no wave-6 unit owns (test_text_scale_layout.gd, test_paper_doll.gd) on strings the directive removed; verify --fast shows exactly these four until they are applied. Proved green with the edits applied on a backed-up tree (2026-09-15), then restored.

## 1. game/screens/RaidPrep.gd:446
LOOP C24 interim: the prep card's sub-line prints the encounter's facts, never the kind as a name ("Main Boss"). Applied in-wave by W6-AUD-BIND; the `new:` block is the text now in the file.
old:
```
    var kind := Widgets.label_as(
        Enums.encounter_kind_name_of(_encounter.kind) if _encounter != null else "",
        "LabelMuted")
```
new:
```
    # LOOP C24 (interim, W6): the encounter's display_name is its only name;
    # the kind ("Main Boss", "Trash") is never printed as one. The sub-line
    # carries the fight's facts instead — the enemy count and the rounds the
    # encounter is sized for, both the encounter's own numbers — until Q12a
    # rules whether a boss gets a creature name.
    var facts := ""
```

## 2. game/screens/RaidView.gd:737
LOOP C24 interim: the boss plate's name is the encounter's `display_name` only. Already the case; old == new on purpose so the dry run reports ALREADY APPLIED.
old:
```
	var name_l := Widgets.label_as(_encounter.display_name, "LabelBossName")
```
new:
```
	var name_l := Widgets.label_as(_encounter.display_name, "LabelBossName")
```

## 3. game/ui/Cards.gd:616
LOOP-15's third site: the event log's link is relabelled "Records" (it opens the Records tab, not a full feed). Its shut reason STAYS "Opens at Known." — the short form of the same true gate (C10 KEEP): the long sentence was tried in the head row and at text scale 150 its 294px pushed the log panel 4px past the clip on six screens (test_text_scale_layout, measured 2026-09-15), so the wall's full sentence is the Records tab's and the link keeps the short one. Held back in-wave because tests/unit/test_event_feed.gd and tests/unit/test_widgets_kit.gd (not W6-COPY's) pin "View All" exactly; §4 adds the constant and §5-§7 carry those pins. Apply §3-§7 together.
old:
```
	var link := Widgets.link("View All", true)
	var why := view_all_reason(state)
```
new:
```
	var link := Widgets.link(RECORDS_LINK_TEXT, true)
	var why := view_all_reason(state)
```

## 4. game/ui/Cards.gd:49
old:
```
const RECORDS_TAB_TEXT := "Records"
```
new:
```
const RECORDS_TAB_TEXT := "Records"
## The event log's link (LOOP-15): it opens the Records tab, so it says so —
## "View All" promised a full feed the panel does not have.
const RECORDS_LINK_TEXT := "Records"
```

## 5. tests/unit/test_event_feed.gd:367
old:
```
    assert_eq(Cards.view_all_reason(st), "Opens at Known.")
    var host := Control.new()
    _made.append(host)
    Cards.event_log(host, st)
    var link := _link(host, "View All")
    assert_ne(link, null)
    assert_true(link.disabled)
    assert_true(_joined(host).contains("Opens at Known."), "the reason is a Label beside the link")
    assert_eq(Cards.view_all_reason(StateStub.new()), "Opens at Known.", "a stub state cannot route")
```
new:
```
    assert_eq(Cards.view_all_reason(st), "Opens at Known.")
    var host := Control.new()
    _made.append(host)
    Cards.event_log(host, st)
    var link := _link(host, "Records")
    assert_ne(link, null)
    assert_true(link.disabled)
    assert_true(_joined(host).contains("Opens at Known."), "the reason is a Label beside the link")
    assert_eq(Cards.view_all_reason(StateStub.new()), "Opens at Known.", "a stub state cannot route")
```

## 6. tests/unit/test_event_feed.gd:397
old:
```
    var link := _link(town, "View All")
    assert_ne(link, null, "the Town's log carries the link")
```
new:
```
    var link := _link(town, "Records")
    assert_ne(link, null, "the Town's log carries the link")
```

## 7. tests/unit/test_widgets_kit.gd:620
old:
```
    assert_true(all.contains("Opens at Known."), "the link's reason is a Label")
    var link := _link(host, "View All")
```
new:
```
    assert_true(all.contains("Opens at Known."), "the link's reason is a Label")
    var link := _link(host, "Records")
```

## 9. game/ui/Cards.gd:880
UI-51's last inch: a ONE-raider morale row is the table's sentence ("Bob is still upset about the wipe.") rather than the raw pair ("Bob: wipe"). Held back in-wave because tests/unit/test_a11y_legibility.gd:657-727 (W6-SETTINGS's file this wave) finds the single rows by `text.ends_with(note)` / `split(": ")`; §10-§11 retarget them to the row's `note` field, which `recent_events` now carries on every morale row. Apply §9-§11 together. test_kit3.gd's `test_one_raiders_note_names_them_and_a_day_keeps_at_most_two_morale_rows` asserts both forms through `morale_sentence(note, names, true/false)` and reads the default, so it stays green either way.
old:
```
const SINGLE_ROW_SENTENCE := false
```
new:
```
const SINGLE_ROW_SENTENCE := true
```

## 10. tests/unit/test_a11y_legibility.gd:670
old:
```
    var by_note := {}
    for e in events:
        for note in ["wipe", "cleared"]:
            if String(e["text"]).ends_with(note):
                by_note[note] = e
```
new:
```
    var by_note := {}
    for e in events:
        for note in ["wipe", "cleared"]:
            if String(e.get("note", "")) == note:
                by_note[note] = e
```

## 11. tests/unit/test_a11y_legibility.gd:713
old:
```
    var by_note := {}
    for e in Cards.recent_events(st, 9):
        var parts := String(e["text"]).split(": ")
        by_note[parts[parts.size() - 1]] = e
```
new:
```
    var by_note := {}
    for e in Cards.recent_events(st, 9):
        by_note[String(e.get("note", ""))] = e
```

## 12. tests/unit/test_text_scale_layout.gd:96
LOOP-04: the Board's facts line now reads "1 enemy" (Type.count). This self-policing allow-list row keys on the old wrong plural and fails as "matched nothing" the moment the copy is right. One token; the overflow it records (the sidebar's one-line facts cap, W2-BOARD's) is unchanged. The file is in no wave-6 ownership table, so the orchestrator applies this at the close — IN-WAVE THIS ROW IS RED (one assertion) until it does.
old:
```
    {"screen": "AdventureBoard.tscn", "scale": 0, "kind": CUT, "match": "Trash  ·  1 enemies",
```
new:
```
    {"screen": "AdventureBoard.tscn", "scale": 0, "kind": CUT, "match": "Trash  ·  1 enemy  ·",
```

## 13. tests/unit/test_paper_doll.gd:283
UI-27: the Quarters line reads "Settles at 45 — Common, no furnishings." and docs/02 §4.5's arithmetic is its tooltip (HALL-26's "one Label, single-spaced" still holds — of the sentence). The Label is named "Settles". Red in-wave until applied (the file is in no wave-6 table).
old:
```
func test_the_baseline_formula_is_one_label() -> void:
    # HALL-26: "50 base ... = 45 baseline" in ONE Label, single-spaced, at the
    # kit's small size so it sits on one line of the column at 100%.
    var st = _live_state("Doll Formula")
    st.selected_raider_id = st.roster[0].id
    var view := _detail()
    var l := _label_containing(view, "baseline")
    assert_true(l != null)
    assert_true(l.text.contains("50 base"), "the terms and the result share the Label: %s" % l.text)
    assert_false(l.text.contains("  "), "no double spaces: %s" % l.text)
    assert_eq(l.theme_type_variation, "LabelSmall")
```
new:
```
func test_the_baseline_formula_is_one_label() -> void:
    # HALL-26 / UI-27: ONE Label, single-spaced, at the kit's small size —
    # "Settles at 45 — Common, no furnishings." in the guild's own voice — and
    # docs/02 §4.5's "50 base ... = 45 baseline" arithmetic as its tooltip.
    var st = _live_state("Doll Formula")
    st.selected_raider_id = st.roster[0].id
    var view := _detail()
    var l := _label_containing(view, "Settles at")
    assert_true(l != null)
    assert_true(l.tooltip_text.contains("50 base") and l.tooltip_text.contains("baseline"),
        "the terms and the result are the Label's tooltip: %s" % l.tooltip_text)
    assert_false(l.text.contains("  "), "no double spaces: %s" % l.text)
    assert_eq(l.theme_type_variation, "LabelSmall")
```

## 14. tests/unit/test_paper_doll.gd:317
LOOP-16: "They are fine." is gone — the quick-apply has no morale gate (the Market never had one). The reasoned treatment (CRITIC-G06) is asserted on the gate that remains: the price. Red in-wave until applied.
old:
```
    var st = _live_state("Doll Reasoned")
    var who = st.roster[0]
    var MoraleScript = load("res://sim/core/Morale.gd")
    MoraleScript.set_morale(who, 70.0)
    st.selected_raider_id = who.id
    var view := _detail()
    var cheer = _button_named(view, "Cheer up")
    assert_true(cheer != null)
    assert_true(cheer.disabled)
    var reason: Node = (cheer as Button).get_parent().get_node_or_null("Reason")
    assert_true(reason is Label, "the reason sits in the same box as the button")
    assert_true((reason as Label).text.contains("They are fine"), (reason as Label).text)
    assert_true(cheer.icon != null, "the padlock sits in the button's leading slot")
```
new:
```
    var st = _live_state("Doll Reasoned", 0)
    var who = st.roster[0]
    st.selected_raider_id = who.id
    var view := _detail()
    var cheer = _button_named(view, "Cheer up")
    assert_true(cheer != null)
    assert_true(cheer.disabled, "no gold, no bath — the one gate the Market also has (LOOP-16)")
    var reason: Node = (cheer as Button).get_parent().get_node_or_null("Reason")
    assert_true(reason is Label, "the reason sits in the same box as the button")
    assert_true((reason as Label).text.contains("Costs 20 G"), (reason as Label).text)
    assert_true(cheer.icon != null, "the padlock sits in the button's leading slot")
```

## 15. tests/unit/test_paper_doll.gd:348
C12-C14 / LOOP-17: starters draw a backstory, so the empty state is the rare case (a raider with none) and it is ONE sentence with no hint — the wishlist's admission is gone (wishlists are out of 1.0, ship plan §6 #59). Red in-wave until applied.
old:
```
    var st = _live_state("Doll Empty")
    st.selected_raider_id = st.roster[0].id
    var view := _detail()
    var l := _label_containing(view, "Nothing is written down about them yet")
    assert_true(l != null)
    assert_eq(l.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)
    assert_eq(l.size_flags_vertical, Control.SIZE_EXPAND_FILL, "it fills the space the panel has left")
    var hint: Node = l.get_node_or_null("Hint")
    assert_true(hint is Label, "the wishlist's admission is the block's hint line")
    assert_true((hint as Label).text.contains("Wants nothing in particular"), (hint as Label).text)
    assert_true(l.get_node_or_null("Glyph") != null, "with the quill over it")
```
new:
```
    var st = _live_state("Doll Empty")
    st.roster[0].backstory = []
    st.roster[0].backstory_offset = 0
    st.selected_raider_id = st.roster[0].id
    var view := _detail()
    var l := _label_containing(view, "Nothing is written down about them yet")
    assert_true(l != null)
    assert_eq(l.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)
    assert_eq(l.size_flags_vertical, Control.SIZE_EXPAND_FILL, "it fills the space the panel has left")
    assert_true(l.get_node_or_null("Hint") == null,
        "one sentence, no hint: nothing about when a backstory arrives or a wishlist (C12-C14)")
    assert_true(l.get_node_or_null("Glyph") != null, "with the quill over it")
```
