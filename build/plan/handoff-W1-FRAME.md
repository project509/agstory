# Handoff — W1-FRAME (key `W1-FRAME`)

Edits needed in files this unit does not own. Shape: `## N. <path>:<line>` then an `old:`
block and a `new:` block, one edit per heading. Nothing here is applied by the unit.

Observations first (not edits; each names the wave-2/3 unit that owns the file):

- W2-TOWN: `Town.gd:106-109` passes `"tagline": "Bad People. Worse Decisions."` to `Frame.build`.
  The opt is now inert — `Frame.LOCKUP = "44_tagline"` draws the same lockup on every framed
  screen (Q05 flips the constant, not the opt). Delete the line when Town.gd is next edited;
  `Town._chips()` and `Town._standing_tip()` (Town.gd:176-202) are dead copies of
  `Frame.standard_chips` / `Frame.standing_tip` and go with it (KIT-03/KIT-23/TOWN-30).
- W2-BOARD / W1-HALL / W3-DETAIL / W3-OPTIONS / W2-MARKET: the per-screen `_chips()` builders
  (AdventureBoard.gd:265-275, Guildhall.gd:399-409, RaiderDetail.gd:174-184, Settings.gd:391-401,
  Market.gd:224-234) become `Frame.standard_chips(f, _state)`; Market's refresh path
  (Market.gd:340-341) becomes `Frame.refresh_chips(_frame, _state)`.
- W2-RAIDVIEW / W2-RESULTS (COMBAT-12): the compact header consumes
  `Frame.LOCKUPS["33_compact"]` — `Frame.draw_lockup(host, "33_compact")` places the 65x57
  emblem crop at (22,12) and `wordmark_33` at x 96, baseline 48, and returns the lockup's
  right edge (< 352 - 8). Replace `Frame.wordmark("wordmark_44")` at RaidView.gd:377-379 and
  Results.gd:179-181 with that one call.
- W1-CHROME: Frame.gd's hexes are unchanged in count and value (the divider bronze "7A6152"
  is reused for the full-bleed sidebar rule); your hex→token handoff lines for Frame.gd still
  match, but the line numbers moved — anchor on the text.

- W2-TOWN (measured on build/shots/W1F_Town.png, 2026-09-14): the Town sidebar's PanelContainer
  draws to x≈1533 (its border at 1528/1533) while every framed screen's sidebar ends at 1519 —
  an unwrapped Label in Town's sidebar column ("Next at Known: Guildhall facility upgrade I;
  Quest board." is the widest) sets the panel's minimum width past `Frame.SIDEBAR_W` (LESSONS:124,
  "find the widest UNWRAPPED sibling first"). Cap or autowrap it. The same shot shows the
  Blacksmith callout's plate clipped under the sidebar's left edge (a `Frame.SCENE` clamp is in
  W1-KIT's `building_callout`), and the strip's disabled "View All" reason Label wrapping one
  character per line at the event log's right edge (W1-KIT's `event_log` head).

- ORCHESTRATOR / W1-CHROME: handoff-W1-CHROME.md edits 1-7 (the seven Frame.gd hex→token lines) were APPLIED by W1-FRAME on 2026-09-14 16:17 (Frame.gd is this unit's file); skip them when applying that handoff — their `old:` text no longer exists. Edits 8-18 (Bar/Widgets/Badge/SceneStage/Tavern) are untouched.
- W1-KIT / W2-TOWN (measured on build/shots/W1F_Town_expand.png, 1820x1024, 16:23): `Frame.relayout` runs `p.strip` to x 1803 under `expand`, but `Cards.roster_strip` sizes its event-log wrap from constants (`PAGER_NEXT_X + PAGER_W`, Cards.gd:~234), so the log ends at x≈1518 and the extra width shows page ground. Size the wrap from `host.size.x` (the strip host is already right-anchored) when Cards.gd is next edited.
