# report-W7-STAGE — the fight's picture: light mask, plate keep-out, party spread, boss forward, arena by kind, the two 150% leftovers

Wave 7 of `build/plan/ship/00-plan.md`. Written as I go (rule 3). Contract: 00-plan §2 "W7-STAGE"; rulings BL-103 (boss 2x, both arenas), Q-96 (arena per raid: tier `scene` else kind rule), BL-137 (overhead rule), Q01 (as built: 2 camp/arenas, 1 tavern/market).

## Acceptance

- [x] UI-26 — every `PointLight2D` under a loaded stage has `range_item_cull_mask == 2`; the stage's own world items carry `light_mask = 2`; no non-stage CanvasItem in a mounted Guildhall matches the lights (bit 2 clear); Frame's panel hosts `light_mask = 0`.
- [x] UI-20/35 — `say_at(spr, line, hold_ms, keep_out)`: after `place_party` + `say_at(front-rank id, keep_out)` the plate rect intersects no actor head rect and no keep-out rect; the tail length is a `speech_plate` parameter; a boss speaker anchors to the boss plate's bottom-left.
- [x] UI-21 — cave and dungeon party marks: front rank at 84px pitch, ranks staggered by half a pitch, rank pitch raised; no two actor body rects overlap by more than 25% of the narrower (worst-case figure in every slot); the badge stack hides on back ranks except the acting/struck figure (`bar_for` opt).
- [x] UI-22 + BL-103 — `marks.boss.scale = 2` on both arenas; the boss mark in front of the fence line, x clear of the front rank by >= 24px for a 400px footprint and of the cave lantern sprite; `test_scene_stage.gd`'s `anim.scale == Vector2(2, 2)` read from the mark; the <= 25% overlap assertion covers the boss.
- [x] UI-04 — Town passes the callout rects as keep-out; `test_town_layout.gd` asserts no speech plate rect intersects a callout rect.
- [x] UI-07 — the tavern speaker's mark on the floor beside the table; a `furniture` rect list in `stage_tavern.json` and a test that no actor mark lies inside one; `say_at`/the scene plate on a `figure_scale == 1` scene wrap at 140px.
- [x] UI-34 — `NUMBER_STAGGER` = the label's `size.y + 4` per label (two `number_at` calls give disjoint rects); `head_of` for an `AnimatedSprite2D` boss lies in the frame rect's top 10px; `LabelDamageDealt` in Theme.
- [x] UI-30 — rail label floor `Type.at(Type.NAV - 2, pct)` and a two-line wrap inside the item at 150; a test that every RailLabel's size >= the scaled floor.
- [x] UI-31 — `Cards.fit_band_line`'s ladder on the ClassRow with a wider names column as the third rung; `test_kit3.gd`: the nine canon class names whole at 100/125/150 on both card widths.
- [x] UI-54 + CONTENT-26 + CRITIC-C15 — `SceneStage.arena_for(encounter)`: the tier's `scene` from `ContentDB.tier_scene(tier, kind)` if named, else E-slots -> dungeon, A/TR -> cave; `tier_words.json` tier 1 `scene` key; `test_content_db.gd`: tier 1's scene files exist on disk.
- [x] `handoff-W7-STAGE.md` §1-§4 (the three `DEFAULT_ARENA` sites; the Q-96 row) parse under `apply_handoff.py --dry-run`.
- [ ] Shots viewed: `RaidView --fixture=raid` (boss 2x in front of the fence, twelve heads, plate clear of the header), `Guildhall --fixture` (no lantern glow on the panel).
- [ ] `verify.sh --fast` green; `lint_motion.sh` OK; summary lines pasted below.

## Log

(appended as items land)

### 2026-09-15 21:2x — resume after the usage-limit kill

Audited the killed agent's tree against the contract before adding anything
(`git diff` over every owned file). Everything it wrote is in place and parses
(`parse_check` 190 scripts OK): `SceneStage.arena_for` + `ARENA_RAID/ADVENTURE`,
`LIGHT_LAYER`/`_lit()` on every world item and `range_item_cull_mask` on every
light, `say_at(..., keep_out)` + `_clear_plate`/`set_keep_out`/`_stretch_tail`,
`in_back_rank` + `bar_for`'s BL-137 hide, `NUMBER_AIR` per-label stagger, the
re-authored cave/dungeon party ranks and 2x boss marks, the tavern's
`furniture` list and moved marks, `Widgets.Tail.length` + `speech_plate(opts)`,
`Frame._unlit` + `rail_label_floor`/`_rail_fit`, `Cards.fit_class_word`,
`Theme`'s `LabelDamageDealt`, `Town`'s `set_keep_out`, `tier_words` `scene` and
`ContentDB.tier_scene`, and 8 new tests in `test_scene_stage.gd`. The handoff
file (§1-§5) was already written and parses. What was NOT done: the five other
test files, the shots, and any run of the suite — the first run of
`test_scene_stage.gd` was red 3/88.

Fixed on the resume:
- `_clear_plate`'s dodge picked ONE way out and gave up when it did not fit:
  a header pinned to the top of the band (nothing above it, x 0..352) left the
  plate sitting on the chrome. It now scores all three doors (left, right,
  above) and takes the shortest that fits the plate, dropping UNDER the rect
  when none does.
- the light walk in `test_scene_stage.gd` counted `PointLight2D`s as world
  items; a lamp's own `light_mask` says which lights fall on it, which is
  meaningless. Lights are skipped in that loop (their cull mask is asserted
  one loop up).

### What landed, item by item (the boxes above, ticked)

- **UI-26 — the light mask.** `SceneStage.LIGHT_LAYER = 2`; every `PointLight2D`
  the builder makes gets `range_item_cull_mask = LIGHT_LAYER`, and one static
  `_lit(item)` puts the plate, every prop, every figure and its contact shadow,
  the boss and its `BossGlow`, rotors, flyers, fx sprites, bursts, bolt ghosts,
  shimmers, pulses, scrolls and ember emitters on that layer. Nothing else in
  the game is: `Frame._unlit()` pins Header / ChipHost / Rail / SidebarHost /
  StripHost to `light_mask = 0` as the belt to that brace. Two tests: one walks
  the six shipped scenes (lights' cull mask, world items' mask, the Overlay
  NOT on the layer), the other mounts the real Guildhall on the fixture and
  walks 100+ chrome CanvasItems finding none on the layer.
- **UI-20/35 — the plate keep-out.** `say_at(spr, line, hold_ms, keep_out)` (the
  fourth argument defaults to `[]`, so every existing call site compiles) and a
  stage-wide `set_keep_out(rects_or_controls)`. `_clear_plate()` starts the
  plate over the speaker and then walks it clear: a chrome rect is dodged by the
  shortest of left / right / above that actually fits, and dropped under when
  none does; a head it covers lifts it to `CROWD_AIR` above that head; a boss
  speaker under a keep-out rect hangs its plate at that rect's bottom-left.
  `_stretch_tail` writes the chosen lift into the kit's `Tail.length`, which
  widens the tail's base by sqrt(length/TAIL_H) to twice `TAIL_W` at most —
  a lifted plate's tail is a wedge, not a needle.
- **UI-21 — the party spread.** Cave and dungeon `marks.party.ranks` re-authored:
  front rank across the plateau at an **84px** pitch, each rank offset by half a
  pitch (42px) and **44px** apart in y. (The plan's line says 40px rank pitch;
  44 is what keeps the worst-case figure's body rects inside the 25% rule with
  the ranks' x-stagger, and the test measures the rule rather than the number —
  judgement call, recorded.) `bar_for` builds the whole stack on a back-rank
  figure and hides it unless the call carries the bar (BL-137 / Q07's rule
  extended); `in_back_rank(spr)` is the public read.
- **UI-22 + BL-103 — the boss forward, at 2x.** `marks.boss.scale = 2` on BOTH
  arenas; the cave's boss moved from (1210, 800) to (1030, 790) — in front of
  the ledge's fence, on a 150x40 lip — and the dungeon's to (990, 900) on the
  ritual circle's right half, each with a smaller `floor` rect so
  `RaidView.boss_feet_y` keeps every creature on the stone. The old
  `anim.scale == Vector2.ONE` assertion now reads the scale off the mark and
  expects `Vector2(2, 2)`; the <= 25% overlap test includes the boss, and pins
  BL-103's two numbers (a 400px footprint clears the front rank by >= 24px and
  the cave's ledge-lantern flame entirely).
- **UI-04 — Town's callouts as keep-out.** `Town._scene` hands the five callout
  Controls to `stage.set_keep_out()`; the stage reads each Control's rect LIVE
  (they settle one frame later, deferred) and re-anchors on every tick.
  `test_town_layout.gd` mounts Town, settles the plates, runs the real
  `_tick_overlays()` and asserts the joke plate intersects no callout.
- **UI-07 — the tavern floor.** `furniture` is a new `[x,y,w,h]` list in
  `stage_tavern.json` (two table tops, the long tables' benches, the bar and its
  stools); four actor marks moved off it, the speaker at (792,722) to the floor
  beside the bench at (836,730). A test asserts no actor mark lies strictly
  inside a furniture rect. On a `figure_scale == 1` scene `say_at` wraps at
  `SAY_WRAP_1X = 140` and the scene's own `speech.size` gives the same 140px
  line (156 authored box − the kit's 16).
- **UI-34 — the numbers do not stack.** `NUMBER_STAGGER` (a flat 14px under a
  35px glyph) is gone; `number_at` lifts by each earlier label's own `size.y`
  plus `NUMBER_AIR = 4`, so two numbers over one figure are disjoint rects.
  `head_of` already read an `AnimatedSprite2D`'s frame height, and a test pins
  that the 2x strip boss's head lies in its frame rect's top 10px and is centred
  on it. `LabelDamageDealt` (ACCENT_GOLD_LIGHT, Type.DAMAGE, the same 2px
  number-ink outline) is in `Theme.build` with a test; the RaidView kind-switch
  that uses it is W7-REPORT's by name.
- **UI-30 — the rail label at 150.** `Frame.rail_label_floor(pct)` scales
  TOWN-04's `Type.NAV - 2` like every other size, so "Adventure's Board" can no
  longer fall to 14px between 24px neighbours; a string still wider than the
  145px column at the floor wraps to two lines INSIDE the 55px item
  (`_rail_fit`: the plain Fira face, `max_lines_visible = 2`, and just enough
  negative `line_spacing` for both lines to sit inside). The new test walks
  every RailLabel on all 13 routes at 100/125/150 and asserts the floor, the
  two-line ceiling and that the block fits the item.
- **UI-31 — the class word whole.** `Cards.fit_class_word(label, width, extra)`
  is `fit_band_line`'s ladder without the wrap: the variation's size, then
  `Type.CLASS - 2` on the plain face bottom-aligned in the variation's own line
  height, then the third rung — `CLASS_ROW_GIVE = 10` px taken from the two
  gutters beside the word (8 from the portrait row's separation, 2 from the
  glyph's), the bust keeping its integer 2x. `test_kit3.gd` proves the NINE
  canon class names whole on both card widths at 100/125/150, plus the ladder
  itself rung by rung.
- **UI-54 + CONTENT-26 + CRITIC-C15 — the arena by rule.** `SceneStage.arena_for(
  encounter)`: the tier row's `scene` through `ContentDB.tier_scene(tier, kind)`
  when it names one and that JSON is on disk, else raid encounters (E-slots) to
  `stage_arena_dungeon` and adventures and tutorials to `stage_arena_cave`; a
  null encounter answers `DEFAULT_ARENA`, which stays for callers not yet
  migrated. `data/tier_words.json` tier 1 gains `scene: {"adventure": …,
  "raid": …}` (tier 1 only — a pending tier names none and inherits the rule).
  Tests: every real tier-1 record routed, both plates on disk, a stub tier with
  no row falling through, and `test_content_db.gd` on the key's shape.

### Judgement calls (the contract left the choice; the recommended one was taken)

1. **Rank pitch 44px, not the plan's 40.** The plan's UI-21 line names "84px
   across, 40px rank pitch". At 40 with the half-pitch x-stagger the worst-case
   strip (mage_b at 2x, 78x90) puts a back-rank body 90px tall across a front
   body's top 50px; 44 is the smallest pitch that keeps every pair inside the
   25% rule with the ranks' x-offsets as authored. The TEST asserts the rule
   (<= 25% of the narrower, worst-case figure in every slot on both arenas),
   not the number, so a later re-author moves with it.
2. **`NUMBER_STAGGER` became `NUMBER_AIR = 4.0`.** UI-34's Fix is "the label's
   `sz.y + 4`, computed per label, not a constant" — so the old name (which
   meant the WHOLE stagger, 14px) would now be a lie. Nothing outside this file
   read it (`Widgets.NUMBER_STAGGER_PX` is the kit's own, untouched).
3. **Town reaches the stage through `set_keep_out(plates)`, not through a
   `say_at` call.** UI-04 says "Town's speaker pick passes the callout rects as
   `keep_out`", and the plan's Owns line says "Town.gd (the `say_at` call
   only)" — but the camp does not call `say_at`: its line is the SCENE's own
   speech plate (`speech.lines` + `set_lines`), placed by `_place_speech` and
   re-anchored from `_process`. One line in `Town._scene` hands the five
   callout Controls to the stage, which reads them live; `_anchor_speech` runs
   the same `_clear_plate` `say_at` does, so both plates obey one rule.
4. **The keep-out list takes Controls as well as Rect2s.** Town's callouts are
   sized by a DEFERRED settle, so a rect captured at build time would be the
   pre-layout box. A `Control` entry is read live in the stage's parent's space
   and converted through the stage's own `position`.
5. **The scene plate's outer width is not asserted; its LINE is.** `speech.size`
   is the authored box and `_place_speech` hands the Label `size.x - 16`;
   PanelBubble's stylebox then adds ~20px a side, so the tavern's 156 box draws
   at 180. The 140px LINE is the number UI-07 is about, and that is what the
   test pins (with a "narrower than the 2x floor" guard beside it).
6. **`arena_for` falls back when the named plate has no JSON.** A tier row that
   names a plate the build does not ship answers `DEFAULT_ARENA` rather than
   sending `SceneStage.load` at a missing file; `test_content_db.gd` makes the
   authored case loud instead (tier 1's two names must be on disk).
