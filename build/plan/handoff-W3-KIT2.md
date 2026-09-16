# handoff-W3-KIT2 — edits this unit needs in files it does not own

Shape: `## N. <path>:<line>` then an `old:` block and a `new:` block, one edit per heading; nothing here
is applied by the unit. Observations (no edit) are headed "Observation (no edit) — <who>". Kit.gd is
TAB-indented; the fenced blocks below carry real tabs.

## 1. tools/probe/Kit.gd:13 (the art gate's Kit target; orchestrator) — Cards preload for §2

RULES-10: `game/assets/bg/boss_sludge_maw.png` (a crop of the Concept 2 mockup) is deleted by W3-KIT2;
the probe was its only other reader. The art well is now `Cards.encounter_art`, the same composition the
RaidPrep sidebar shows.

old:
```
const Widgets = preload("res://game/ui/Widgets.gd")
const Frame = preload("res://game/ui/Frame.gd")
```
new:
```
const Widgets = preload("res://game/ui/Widgets.gd")
const Cards = preload("res://game/ui/Cards.gd")
const Frame = preload("res://game/ui/Frame.gd")
```

## 2. tools/probe/Kit.gd:133 (apply AFTER §1) — the art well composes, the mockup crop is gone

old:
```
	var art := TextureRect.new()
	art.texture = load("res://game/assets/bg/boss_sludge_maw.png")
	art.stretch_mode = TextureRect.STRETCH_KEEP
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_at(card_free, art, 1, 1, Vector2(337, 116))
```
new:
```
	# RULES-10 (W3-KIT2): the mockup crop is deleted; the well is the kit's own
	# composition (the rank creature over a darkened arena slice), no encounter.
	var art := Cards.encounter_art(null, Vector2(337, 116))
	_at(card_free, art, 1, 1, Vector2(337, 116))
```

## Observation (no edit) — orchestrator / W0-SHOT: no hover in the shot grammar (KIT-22)

`Widgets.tooltip_for(control, title, body)` shipped (a `TooltipHost` laid over the control answers
`_make_custom_tooltip` with a title Label over a body Label, max 260 wide; `tooltip_text` kept). The
acceptance line "hovering a gear slot in a RaiderDetail shot shows the two-line tooltip inside the frame"
cannot be shot: `tools/shot.gd` has no hover flag and W3-KIT2 does not own it. The two lines are asserted by
`test_widgets_kit.gd::test_tooltip_for_lays_a_host_over_the_control_and_builds_two_lines`. A `--hover=<x,y>`
flag (warp the mouse with `Input.warp_mouse`, wait `gui/timers/tooltip_delay_sec` + 2 frames before the
capture) would make it a shot; it belongs beside `--press`.

## Observation (no edit) — W3-DETAIL / W3-RAIDVIEW2 / Market's owner: `tooltip_for` is live

Gear slots (`Widgets.slot_button`, `slot_with_reason`) and mechanic icons can call
`Widgets.tooltip_for(control, item_name, slot_or_mechanic_line)` now; `Cards.card` already does it for its
three gear cells. The control keeps `tooltip_text` ("title — body") so a11y readers and tests see the words.

## Observation (no edit) — tests/unit/test_a11y_legibility.gd:647-650 (not W3-KIT2's): a stale comment

The assertion `Cards.badge_icon("loot") == null` still holds and is honoured on purpose (see
report-W3-KIT2 J1): the feed's "loot" rows take their badge through `Widgets.log_row(..., kind)` →
`Icons.at("log", "loot")`, not through `badge_icon`. The message "a kind with no feed and no verified sprite"
is now false on both counts (there is a feed, and icons/grid/log_loot.png is drawn) — the sentence, not the
assertion, wants rewriting: "the feed's kinds resolve through log_row; badge_icon answers the morale pair
and the record states only".

## Observation (no edit) — W3-ROSTER (Guildhall.gd Records rows): `Cards.badge_icon` has the record states

HALL-20: `Cards.badge_icon("locked")` is the grid's padlock, `("earned")` the coin, `("claimed")` the scroll.
A Records row can be `Widgets.log_row(text, tone, badge, Cards.badge_icon(state))` with the state word
Label kept (docs/13 §13).

## Observation (no edit) — the screens' `empty_state` sites (KIT-08): the glyph is the caller's

`Cards.event_log` now defaults its empty state to `Icons.at("empty", "quill")`. The other sites are in
screens W3-KIT2 does not own; each can pass its picture: Tavern.gd:415/690/883 → `Icons.at("empty",
"bench")` (the Tavern already passes it at :415), Market.gd:537/569/596/901/918 → `"shelf"`,
Roster.gd:441 and RaidPrep's bench → `"bench"`, RaiderDetail.gd:216/220/396/406 and Results/RaidView →
`"quill"`. Texts unchanged.

## Observation (no edit) — Tavern.gd / Market.gd: `Widgets.reasoned` now takes `width`

`Tavern._reasoned` and `Market._reasoned` (a Label width + autowrap on the kit's "Reason") can become
`Widgets.reasoned(control, reason, null, width)`; the kit's line is identical. Both also get the padlock
by default now (CRITIC-G06's one treatment) — a caller that must NOT show a lock passes its own glyph.

## Observation (no edit) — Theme.gd (nobody this wave): a zero-margin flat title for the building callout

The callout pad is 4/4 now (was 6/6); the rest of the 84px is the title Button's theme margins. A
`ButtonCalloutTitle` variation through `_button()` (flat, zero content margins, the focus ring kept) would
bring the plate to the reference's 52-57; `Widgets.building_callout` would set `b.theme_type_variation`
to it — the name is a string and falls back harmlessly, so the kit can name it the same wave it lands.

## Observation (no edit) — gen_icons.lua / Icons.gd (nobody this wave): W2-STAGE2's option (a) and W2-BOARD's `mark` role

W3-KIT2 shipped option (b) for the emote glyphs (drawn alone at 2x, no frame under them). If the designer
prefers the kit's frame (Q16), option (a) — bare 16px symbols for the `emote` role — is the generator's,
and `Widgets.speech_bubble` would then centre them in the frame again (`EMOTE_GLYPH_SCALE` and the
`t.texture = null` branch go). W2-BOARD's tick/pin/lock 16px `mark` role is unchanged and still theirs.

## Observation (no edit) — KIT-15's screen sites: `Type.gold` is the door

Tavern.gd:736 `"Hire — %d G" % price` (the shot flag `--press="Hire — 60 G"` presses that text — identical
below four digits), RaidPrep's CTA subline and the Results tally can use `Widgets.cta_priced(text, price)`
/ `Cards.price_text(n)`; nothing in W3-KIT2's own files formatted a price before this wave.
