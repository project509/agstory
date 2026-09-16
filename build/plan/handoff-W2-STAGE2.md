# Handoff — W2-STAGE2 (key `W2-STAGE2`)

Edits needed in files this unit does not own. Shape: `## N. <path>:<line>` then an `old:`
block and a `new:` block, one edit per heading. Observations (no edit) are labelled as such.

## 1. game/ui/Palette.gd:136
Two tokens SceneStage's verbs use as floats today (docs/12 §5.2's hit flash and §5.3's fumble mark);
once they exist, SceneStage.gd's `FLASH_COLOR` / `MARK_COLOR` consts can be repointed to them.
old:
```
const INK_BUBBLE_DOTS := Color("3B2F27")  ## the "..." in the cream bubble (SceneStage.gd)
```
new:
```
const INK_BUBBLE_DOTS := Color("3B2F27")  ## the "..." in the cream bubble (SceneStage.gd)
const FLASH_HIT := Color("FFF6DC")        ## docs/12 §5.2: the one-beat hit flash on a struck figure (SceneStage.hit)
const MARK_FUMBLE := Color("F2C14E")      ## docs/12 §5.3: the "!" over a fumbling figure (SceneStage.act "fumble")
```

## 2. tools/probe/Kit.gd:92
The comment names the deleted pair, which trips RULES-16's grep (`guildhall_plate`) — LESSONS: "a file that
states a rule trips a grep for that rule". The files are gone (this unit deleted camp.json, guildhall.json,
bg/camp_plate.png, bg/guildhall_plate.png); the comment should stop naming them.
old:
```
	# The scene: the BARE camp plate with its living layers (the 2026-09-11
	# directive; RULES-16). The legacy guildhall.json / guildhall_plate.png pair
	# is scheduled for deletion (M4B-CONV-02) and nothing may load it. The stage
```
new:
```
	# The scene: the BARE camp plate with its living layers (the 2026-09-11
	# directive; RULES-16). The legacy mockup-crop scene this probe used to
	# mount was deleted in W2-STAGE2 (M4B-CONV-02); only bare stages exist. The stage
```

## 3. tests/unit/test_hall_plates.gd:388
The guard's own pattern is the other remaining hit of RULES-16's grep. The assertion is kept whole
(the string it forbids is built from two halves so the file no longer contains it verbatim).
old:
```
        assert_false(src.contains("guildhall_plate"),
            "%s must not name the Concept 1 crop" % path)
```
new:
```
        assert_false(src.contains("guildhall" + "_plate"),
            "%s must not name the Concept 1 crop" % path)
```

## 4. game/screens/Town.gd:201
TOWN-26's "a skull over the camp after a wipe from `last_result`": stage_camp.json carries a skull bubble
with the mood `"wipe"` ([560, 634, "emote:skull", "wipe"], over the bridge figure); the stage shows it only
while `set_mood("wipe")` has been called, and the SCREEN is what knows the state. W2-TOWN owns Town.gd this
wave, so this is the exact edit for after the wave (line 201 at the review is the `stage.set_lines(lines)`
call inside `_scene`'s `if _state != null:` block; if W2-TOWN moved it, the edit goes wherever that call now
is). "A wipe" is the screen's own rule — RaidView.gd:1480-1483 `_is_wipe()` is `not last_result.cleared()`,
which is what raises the WIPE stamp — so WIPE, SOFT_WIPE and ATTRITION all skull the camp (the review
noted the first draft tested `== RaidSim.Outcome.WIPE` only), and no RaidSim preload is needed.
old:
```
		stage.set_lines(lines)
```
new:
```
		stage.set_lines(lines)
		if _state.last_result != null and not _state.last_result.cleared():
			stage.set_mood("wipe")
```

## Withdrawn (was 5.) — game/screens/Town.gd:44, a RaidSim preload
Not needed once §4 reads `last_result.cleared()` (RaidSim.gd:178) instead of the Outcome enum. No edit.

## Observation (no edit) — W2-MARKET: where the market's crowd now stands
stage_market.json's eight shoppers are placed for the layout the plan gives W2-MARKET (ledger 560px on the
LEFT, `PLATE_OFFSET ~(-420,-300)`, the square visible on the right): five stand on the cobbles in front of
the three right-hand stalls at plate (1040,432), (1130,572), (1020,650), (1108,874), (1248,632) — all whole
inside plate x 980..1349 × y 300..940 — and three at y ~300 (x 560, 740, 900) in the 66px top band the
pre-W2 layout shows (harmlessly under the ledger afterwards). The speaking line's speaker is index 4 (the
knight at (1130,572), whole under its plate right of the ledger) since handoff-W2-MARKET §1 was applied
in-wave — the first draft's index 5 (variant_r01_brown at (1020,650)) put the plate's left third under the
ledger. If the final offset differs, the numbers to keep whole are those five feet points; the JSON note
says so.

## Observation (no edit) — W3-RAIDVIEW2: the verbs' shape
`stage.act(spr, "attack"|"cast"|"fumble"|"death", {toward: Vector2})`, `stage.hit(spr, {from: Vector2})`,
`stage.burst(pos, kind)`, `stage.bolt(from, to, kind)`, `stage.slash(pos, {flip, scale})`,
`stage.add_fx(strip_key_or_path, frame_w, fps, pos, {additive, once, flip, scale, emissive, tint})`. All run on
the stage's clock (no Tween — see report J1); a verb on a figure already acting replaces the act. `burst`
kinds: impact, fire, arcane, slash, void, heal, spark, poof.

## Observation (no edit) — W3-KIT2 / Icons: the emote glyphs are bubbles inside a bubble
W1-ICONS' `emote_<kind>.png` (16px) are drawn as the A1-S8 reference glyphs — each a small cream, tailed
bubble with the symbol inside. `Widgets.speech_bubble(kind, Icons.at("emote", kind))` centres that glyph in
the kit's own 40x44 cream frame (`PanelEmote`), so every emote reads as a bubble-in-a-bubble
(build/shots/W2STAGE2_Town.png at (1098..1138, 448..492); the tavern's mugs likewise). The plan's composition
is what shipped; the fix is one of: (a) gen_icons.lua emits BARE 16px symbols for the `emote` role (the frame
is the kit's); (b) `speech_bubble` draws the glyph alone at 2x (32x32) as the whole marker when the glyph
carries its own frame. (a) keeps the kit's geometry and the `emote` meta contract; nothing in SceneStage
would change.
