# Review — W1-STAGE (adversarial, against the tree)

Reviewer edits nothing but this file. Written finding by finding. Everything below was run or measured
by the reviewer on 2026-09-14 16:45-17:00; where a number comes from the implementer's artefact it says so.

## 1. Ownership / files touched

- `git status --porcelain`: ~70 modified and ~100 untracked paths in the tree; the other six wave-1 units
  own the rest. The nine paths this unit changed are all in its owned list: `game/ui/SceneStage.gd`,
  `game/assets/scenes/stage_{camp,tavern,market,arena_cave,arena_dungeon}.json`, `game/screens/RaidView.gd`,
  `tests/unit/test_scene_stage.gd`, `tools/art/preview_scene.py`, plus report/handoff. No change in any
  other file is attributable to this unit (the report's file list matches; camp.json/guildhall.json untouched).
- RaidView.gd diff read in full: four hunks — the ARENA_OFFSET/PARTY_RANKS/BOSS_X docstrings, `boss_feet_y`
  (gains an optional `scene` param, default preserved), `_stage`, `_party_layout`. Nothing outside the six
  owned symbols; `BOSS_HEAD_CLEAR`/`BOSS_FEET_RANGE` untouched; `git diff | grep -c '_wipe\|WIPE_'` = 0.
  Tab-indented (828 tab lines / 0 space lines).
- SceneStage.gd diff read in full (899 diff lines): 762 tab lines / 0 space lines. test_scene_stage.gd:
  890 space lines / 0 tabs. preview_scene.py: Python, no Godot call.
- Line endings: the owned .gd/.json/.py working copies are CRLF while `.gitattributes` says `eol=lf`
  (git warns "CRLF will be replaced by LF"); git normalises on add and the diffs are clean hunks. MINOR, cosmetic.
- **Same-wave cross-unit reference (§0.2)**: SceneStage.gd:953 `Widgets.speech_bubble("dots", glyph)`. At
  wave start (`git show HEAD:game/ui/Widgets.gd` :444) `speech_bubble()` is zero-arg; the two-arg form is
  W1-KIT's. The unit applied handoff-W1-KIT §10/§11 (aimed at SceneStage.gd) itself; handoff-W1-KIT.md
  records "ALREADY APPLIED by W1-STAGE" and handoff-W1-STAGE.md tells the orchestrator. If W1-KIT's
  Widgets.gd were reverted, SceneStage.gd would not parse (too many arguments), and the fifteen re-authored
  bubble positions assume the kit's 40x44 frame. Coordinated and documented on both sides, and the
  orchestrator would have made the identical edit between waves — recorded as MINOR, but it is not the
  plan's letter. `Widgets.speech_plate(text)`, `Widgets.bar(...)`, `Widgets.content_of` exist at HEAD with
  compatible signatures; `Palette.EDGE_STEEL_DIM/SURFACE_INSET/GROUND_PAGE` exist at HEAD.

## 2. Tests and verify (observed)

- `GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` → `LINT OK`, `MOTION LINT OK`,
  `PARSE_CHECK scanned 160 script(s)`, `16 generated file(s) agree`, `ART CHECK generators=6 184 agree
  0 DIFFERS 0 MISSING`, `TESTS PASSED 1713 test(s) in 80 file(s) [33775 ms]`, `VERIFY OK`, exit 0.
- The plan's Green line also names a11y_smoke and the boot; ran both under the lock:
  `A11Y SMOKE PASSED 26 screen mount(s)` with one `warn` on AdventureBoard (10 pointer-only PanelContainers —
  the board's notice cards, not this unit's; AdventureBoard is untouched this wave); headless boot
  `--quit-after 180`: zero SCRIPT ERROR / Parse Error / Failed to load lines.
- The eight named tests plus `test_overlays_sit_above_the_figures_and_carry_labels`, `test_ember_colour_is_data`,
  `test_speech_anchors_to_its_speaker`, `test_every_ambient_bubble_hangs_over_a_head` exist by name
  (`grep ^func test_` = 44) and the file ran in the suite (.verify.log:146-160 carries the two expected
  push_warnings from test_scene_stage.gd:198/:452). The old boss test is replaced by
  `test_every_creature_the_sheet_can_produce_clears_the_chrome_and_lands_on_its_mark` iterating both arenas.
- Oddity: test_scene_stage.gd:1142-1144 has RAW newlines inside a double-quoted string (the heredoc
  backslash trap, rule 5) where every other assertion writes `\n`. Godot 4 accepts it (parse and suite
  green). MINOR, cosmetic.

## 3. Shots re-taken (§0.3 grammar, through the lock; all viewed with Read)

`build/shots/review-W1-STAGE-RaidView.png` (--fixture=raid), `-RaidView_re.png` (--set=reduced_effects=true),
`-Town.png` (--fixture), `-Tavern.a/.b.png` (--fixture --frames=1,20), `-RaidPrep.png` (--fixture); crops
`-party_x3.png`, `-boss_x3.png`, `-pulse_pairs_x2.png`, `-town_bubbles_x4.png`, `-hearth_ab_x3.png`.
(First attempt with `--headless` produced no image — shot.gd needs a real display server; §0.3's grammar is right.)

- RaidView: twelve 2x figures in three ranks on the lower-left lantern floor facing the bridge; the leviathan
  on the lower-right railed ledge, flipped to face them; the header, objective block, boss plate, control row
  and strip untouched. Party crop at 3x with the mark ticks drawn: every figure's feet on its red tick, every
  head above the green tick 70px up. Boss crop at 3x: base on the red tick at screen (1210,520) inside the
  orange floor rect (screen 1090..1320 x 450..570), mouth toward the party; at `scale 1` it is small beside
  the 2x party — Q02's default, not a placement fault.
- RaidView reduced_effects: glow off, every pulse gone, no motes, lantern/torch flames still burning and
  reading as painted flames (modulate 1.0), party and boss present; no vignette.
- Town: 2x crowd on the bare camp; the speaking plate over cleric_b by the tents; two "..." bubbles up with
  ONE row of three dots each and a tail. The Tavern/Blacksmith/Market callouts sit on 2x figures — W2-TOWN's,
  recorded in the unit's handoff. Bubble crop at 4x: tail apex (green) 6px above the figure's frame top (red).
- Tavern frames 1 and 20: two different flame shapes on the same grate, no half-frame shift; bright-flame
  centroid x 868.7 vs 870.7, same x-range.
- RaidPrep: dimmed cave at RaidPrep's own view; the left crystal cluster reads as a soft brighten with no box.

## 4. Acceptance lines (00-plan §W1-STAGE)

| # | Line | Verdict | Evidence |
|---|---|---|---|
| A1 | RaidView: twelve figures >= 70px tall, feet inside the party mark | MET | review-W1-STAGE-party_x3.png (twelve on the ticks, heads above the 70px ticks); data: 2x frame_h of the fixture's classes 72..96 |
| A2 | no sprite under BOSS_PLATE (931,53,384,65) or OBJECTIVE (0,88,352,106) | MET | shot: party right edge x<=700, highest head y 240 > 194; boss rows ~400..520 at x 1160..1260 — both chrome rects sit over empty plate; `test_marks_place_the_party_and_boss_in_band` asserts it for both arenas |
| A3 | boss feet inside its floor rect | MET | review-W1-STAGE-boss_x3.png; `boss_feet_y(119,"stage_arena_cave")` = 800 inside floor y 730..850; test iterates all six creatures x both arenas |
| A4 | Town: shortest standing figure >= 62px | MET | stage_camp.json x actors.json at figure_scale 2: heights [72,76,76,78,78,78,80,82,82,84,90,96]; viewed on review-W1-STAGE-Town.png |
| A5 | no two actor bboxes overlap > 25% | MET | pairwise 2x bboxes: only warrior/mage intersect, 10% / 12% |
| A6 | every ambient bubble's bottom edge 4-10px above its figure's head | MET | on my Town shot all five camp bubbles' bottoms are 6px above the nearest head's frame top (two visible, viewed at 4x); `test_every_ambient_bubble_hangs_over_a_head` covers camp+tavern+market against the real frame size |
| A7 | pulse inside/outside luminance ratio < 1.15 at the four STAGE-05 rects | MET IN INTENT, one number over | measured on my shots (4px inner / 16px outer band): RaidView (1440,410,96,220) 0.946; RaidPrep (233,390,150,110) 1.137; Results (1440,410,96,220) 0.923 (implementer's W1STAGE_Results.png); RaidView (55,150,150,110) **1.642** — but the same rect with the pulses hidden reads 1.705: that rect's top 44 rows are under the OBJECTIVE panel and its edge cuts the plate's own crystal cluster, so the metric there is the plate's, not the quad's. review-W1-STAGE-pulse_pairs_x2.png (on/off) shows no rectangle edge at any of the three RaidView rects. Not achievable below 1.15 by anything this unit owns; not a failure of the unit. |
| A8 | the eight named tests | MET | all eight present by name and green in the suite (§2) |
| A9 | test_scene_stage.gd:534-566 rewritten to iterate both arenas' marks | MET | `test_every_creature_the_sheet_can_produce_clears_the_chrome_and_lands_on_its_mark` (:553) loops ARENAS x 6 creatures, checks head clearance, floor, band, feet x |
| A10 | test_motion.gd:139-156 green | MET | cave 9 / dungeon 16 props with fps > 3 (counted from the JSON); suite green |
| A11 | refdiff RaidView/RaidPrep/Results vs 2 recorded before/after | MET (record exists; "commit message" is the orchestrator's) | build/diff/*_diff.json (before) vs build/diff/w1stage/*_diff.json (after): raidview 34.553 -> 33.813, raidprep 32.209 -> 32.108, results 32.390 -> 32.014 — no regression |
| S1-S5 | the five shots | MET | re-taken and viewed (§3) |
| G | `apply_settings(reduced_motion: bool` literal; no focusable; overlay Labels in the screen subtree; no create_tween; wipe untouched | MET | SceneStage.gd:1088 literal; grep create_tween/focus_mode/grab_focus = 0; overlay test asserts FOCUS_NONE on every overlay Control; wipe lines absent from the RaidView diff |

Build notes checked against the tree: figure_scale per scene (camp/cave/dungeon 2, tavern/market 1) = §0.6;
cave marks = STAGE.md "Proposed arena blocking" verbatim (ranks 692/654/616, boss (1210,800) flipped, floor
[1090,730,230,120]); dungeon marks = its recommended blocking verbatim (660/622/584, boss (965,900), floor
[900,830,130,110], pulse [905,830,120,110], light (965,870), motes (965,890)); boss `scale` 1 (Q02 default);
`stage_tavern.json frame_w 64` (512/64 = 8 frames); ember `preset/color/lifetime/size`; PULSE_SHADER
`feather 0.35` keeping `color.a`; vignette 8% GROUND_PAGE, MOUSE_FILTER_IGNORE, hidden under reduced_effects;
flame modulate 1.0 under reduced_effects; `_process` gated on `_motion_held`; overlay API `head_of/say_at/
number_at/bar_for` with the 96x23 / 24 / 4x12 / 62x7 geometry; preview_scene.py `--marks --view`.
Shimmer+pulse total 16 (>= 10); TOWN-07's two moves in; `speech.speaker` on camp (4) and tavern (12).

## 5. Contracts (§0.5 / Green)

- Label/Button texts and node names: the unit adds nodes (`Overlay`, `Say_*`, `Bar_*`, `Vignette`, `Badge`,
  `Pip_N`, `HP`) and changes none of the asserted names (`Actor_*`, `Shadow_*`, `BossShadow`, `Shimmer_*`,
  `Pulse_*` kept); no screen string touched.
- Indentation matches each file (§1). `create_tween` 0 in SceneStage; procedural motion is `_process`
  held by `_motion_held`. No branch on `reduced_motion` outside the designated `apply_settings` consumer.
- Overlays: `Overlay`, plates, labels, bars, badge/pip rects all `MOUSE_FILTER_IGNORE` (Bar.gd draws itself,
  no children; speech_plate's Label is IGNORE). Vignette IGNORE.
- Pure black/white: `vig.color = Color(1,1,1,1)` is never rendered (the shader writes COLOR wholesale) and
  flame modulate `Color(1,1,1,1)` is the neutral tint; no hex literal (`grep 'Color("'` = 0).
- No `$GODOT` outside the lock in any script the unit added; no new PNGs (no baked text / .import question).
- Nothing parented to the router host (the stage is the screen's child; overlays are the stage's).
- Handoff: observations only (W2-TOWN callouts, W2-MARKET speaker, the applied-handoffs note); no edit
  blocks needed, so nothing to check for old/new exactness.
- `_ready()` in SceneStage gains `_fit_vignette()` — a kit component, not a screen; the no-`_ready()` rule is
  for screens. `_notification(RESIZED)` refits. Fine.
- preview_scene.py still outlines bubbles as 33x32 (`draw.rectangle([... b[0]+33, b[1]+32])`) while the
  camp note and the test say the frame is 40x44. MINOR, tooling-only.

## 6. Judgement calls vs §6

- J2 (vignette fitted to the visible band, not the whole plate): implementation detail; §6 reserves DoF/grade
  (Q08), and the vignette "ships regardless" — OK.
- J3 (`speech.speaker` = authoring-order index; camp 4, tavern 12, market left on `pos`): TOWN-03's anchor half
  is in the unit's finding list — OK.
- J4 (A7 measured as the quad's own contribution): see A7 — the honest reading; the absolute numbers are
  recorded beside it in the report — OK.
- J5 (re-authoring the 1x tavern/market bubbles too, and applying W1-KIT §10/§11 in-wave): the bubbles are
  the unit's data; the in-wave application is the §0.2 letter breach recorded in §1 — MINOR.
- figure_scale 2/2/2/1/1, boss scale 1, vignette-on/`dof` absent, bars badge+pips with the HP bar per call:
  every one is §0.6's landed default; nothing reserved for the designer was decided here.

## 7. Report accuracy

Every number I re-measured matched the report (pulse ratios to three decimals, refdiff before/after, bubble
gap 6px, overlap 10%/12%, heights 72..96, hearth centroids within 2px, 1713 tests / 80 files). No false claims
found. The report's A7 tick is annotated with the 1.642 outlier rather than hidden.

## Verdict

**PASS** — every acceptance line is met or (A7, one rect) met in intent with the metric shown to be the
plate's own. Minors: (1) in-wave application of W1-KIT §10/§11 makes SceneStage.gd depend on this wave's
`Widgets.speech_bubble(kind, glyph)` signature — documented on both sides, the orchestrator should keep the two
files together; (2) raw newlines inside a string literal at test_scene_stage.gd:1142-1144; (3) CRLF working
copies against `eol=lf`; (4) preview_scene.py's bubble outline is the old 33x32.
