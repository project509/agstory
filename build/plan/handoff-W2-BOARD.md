# Handoff — W2-BOARD

Edits needed in files this unit does not own. Shape: `## N. <path>:<line>` then an `old:`
block and a `new:` block, one edit per heading. Nothing here is applied by the unit.

Observations first (not edits):

- W1-ICONS / W3-KIT2 (gen_icons.lua, Icons.gd): the rung ladder (TOWN-11) wants three 16px state
  glyphs — tick / pin / padlock. The grid has `lock_16` only; the pin is a 12x12 theme icon on
  `PanelPaper` (not in the grid), and there is no tick. This unit draws the cleared tick from two
  rotated ColorRects in ACCENT_GOLD and reads the pin off the theme. A `tick_16` (role `lock`'s
  sibling — e.g. a new `mark` role: `mark_tick`, `mark_pin`) would let the ladder use `Icons.at`
  for all three; when it lands, replace `_rung_glyph()` in AdventureBoard.gd.
