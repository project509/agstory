# handoff-W2-TAVERN — edits this unit needs in files it does not own

Shape: `## N. <path>:<line>` then an `old:` block and a `new:` block, one edit per heading; nothing here is
applied by the unit. Empty until an edit is needed.

No edits. Every change this unit needed landed in the two files it owns.

## Notes for W3-KIT2 (nothing to apply)

- `Widgets.tab_row` is a rebuild-per-switch idiom: the pressed tab is freed, so keyboard focus is dropped unless the screen re-grabs it. Tavern.gd handles it locally (`_focus_region` / `_regrab` around `_refresh`, plus re-running the shell `frame_focus_order` Callable the way `Cards._turn_page` does). A kit-level answer (tab_row re-grabbing its active tab after a rebuild, or swapping variations in place) would let every screen drop that code.
- `Widgets.reasoned` leaves its reason on one line; the Tavern gives the "Reason" Label a width and autowrap for a sentence wider than its column at 150% (`Tavern._reasoned`). If more screens need that, a `width` argument on `reasoned` is the one-door form.
