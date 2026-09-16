# handoff-W3-DETAIL — edits this unit needs in files it does not own

Shape: `## N. <path>:<line>` then an `old:` block and a `new:` block, one edit per heading; nothing here is
applied by the unit. Observations (no edit) are labelled as such.

Why §1 exists: KIT-22 puts the two-line tooltip on every gear slot through `Widgets.tooltip_for(control,
title, body)`, which W3-KIT2 is adding to Widgets.gd IN THIS SAME WAVE (00-plan §0.2: a unit may not call
a function another unit adds in the same wave). So this unit composes the title + body itself
(`RaiderDetail._tip`, "title\nbody" in `tooltip_text`) and the switch is written here for the
orchestrator to apply once KIT2 has landed. §1 is an edit to a file THIS unit owns (`game/ui/PaperDoll.gd`,
TABS) — apply it after the wave, after `grep -n "static func tooltip_for" game/ui/Widgets.gd` finds the
door; if KIT2's signature differs from `(control, title, body)`, adapt the one call. The composition stays
where it is: `tooltip_for` keeps `tooltip_text` set (KIT-22), so `tests/unit/test_paper_doll.gd`'s
two-line read of `tooltip_text` still holds either way.

## 1. game/ui/PaperDoll.gd:149

old:
```
	var tip := String(cell.get("tooltip", ""))
	if not tip.is_empty():
		b.tooltip_text = tip
```
new:
```
	var tip := String(cell.get("tooltip", ""))
	if not tip.is_empty():
		# KIT-22: the title line over the body line, drawn as two styles by
		# the kit's TooltipHost; `tooltip_text` stays set for a11y and tests.
		var parts: PackedStringArray = tip.split("\n", true, 1)
		Widgets.tooltip_for(b, parts[0], parts[1] if parts.size() > 1 else "")
		if b.tooltip_text.is_empty():
			b.tooltip_text = tip
```

## Observations (no edit)

- W3-KIT2 (`Widgets.reasoned` padlock default, CRITIC-G06): RaiderDetail passes `Icons.at("lock", "16")`
  explicitly as the third argument of `reasoned` for the disabled Cheer up. Once KIT2 makes the padlock the
  default, that argument is redundant but harmless; nothing to apply.
- W3-KIT2 (`empty_state` glyphs, KIT-08): the four empty states on this screen already pass their glyph
  (`Icons.at("empty", "quill" | "shelf")`); nothing to apply.
- W3-KIT2 (`Widgets.empty_state`, KIT-08): the glyph and the hint are placed around a ONE-line text
  (`offset = ±line_h * 0.5`), so a text that wraps to two lines has the hint drawn over its second line
  (seen on this screen's first shot: "Nothing is written down about them yet. Wants nothing in particular."
  wraps at 375px). This unit split the sentences (text = the first, hint = the second) rather than edit
  Widgets. If the hint offset measured the wrapped text (`get_line_count()` after a `size` is known, or a
  `TextParagraph` at the Label's width), a two-line text could carry a hint.
- Orchestrator: something rewrote every file under `build/plan/` at 22:17 (all mtimes equal) and the
  untracked wave-3 report/handoff files (this unit's, ROSTER's, OPTIONS', ENEMIES') vanished with
  `build/diff/`; this unit re-created its two from context at 22:30. Worth a look at what ran.
