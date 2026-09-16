# Handoff — W5-MOUNT (key `W5-MOUNT`)

Edits needed in files this unit does not own. Shape: `## N. <path>:<line>` then an `old:`
block and a `new:` block, one edit per heading. Observations (measured screen-side costs) are
prose above the edits.

## Observations (measured 2026-09-15, this laptop boosting, calibration loop 8-9 ms; `tools/perf_probe.gd -- --warm --split`)

The split found the mount budget's costs in this order, and the unit fixed the ones it owns:

1. **`load(path)` of the screen's PackedScene: 45-140 ms on every FIRST visit** (MainMenu 49, LoadSave 43,
   Settings 56, Completion 54, AdventureBoard 74, Results 78, Market 81, Tavern 82, RaiderDetail 82,
   RaidPrep 91, Guildhall 127, RaidView 144) — the screen's GDScript compiling again, because the weak
   resource cache dropped the PackedScene (and the script with it) when the previous instance was freed.
   FIXED for every revisit (`ScreenRouter._scenes` holds them; a revisit's load is 0.0 ms). A first visit
   can only be made cheap by compiling AHEAD: `ScreenRouter.warm()` does the thirteen in ~1.0 s — edit §1
   below puts it behind Boot's overlay, §2 makes the gate measure what the game then does.
2. **The plate: ~36-41 ms per first visit of each scene** (a 1536x1024 .ctex decode + upload), the actor
   and prop strips a few ms more. FIXED for every revisit (`SceneStage._tex_cache`); `SceneStage.warm()`
   loads the five plates a screen stands on ahead (~190 ms) — §1 calls it beside the router's.
3. **A `Shader` object per water quad, per pulse, per cloud layer and per vignette: ~6 ms each** (the
   cave: 2 shimmers + 3 pulses + vignette = 39 ms of a 47 ms stage build with every texture cached).
   FIXED (`SceneStage._shader_cache`, one shared water noise texture): the cave's `water` lap is 0.1 ms.
4. **actors.json parsed once per actor, class_actors.json / enemies.json per call.** FIXED (`_json_cache`).
5. **Screen-side build cost** (goto's `build` minus Frame.build minus SceneStage.from_data), with every
   cache warm — NOT edited (other units own the screens); the numbers, so their owners can decide:
   Town ~70 ms (build 74.8: five hotspot callouts, the sidebar's event feed, `Widgets.Outline` loading
   `OUTLINE_SHADER` per callout — Widgets.gd:187, a weak-cache `load()` of a .gdshader and a compile per
   Town visit), Tavern ~40 (build 90.1 − stage 47.6 − frame 3.2; the seat cards with their gear and
   Cards.gd's portrait `load()`s at :66/:70/:80 — weak-cached, so re-read per visit), Guildhall ~47
   (51.8 − 1.0 − 3.5: the roster rows, each a card with a portrait), Results ~44 (45.1 − 0.8), Market ~34
   (84.0 − 47.3 − 2.9), RaidView ~29 (29.7 − 0.6: the log column, the party bars, the boss plate's still
   `load()` at RaidView.gd — weak-cached), AdventureBoard ~26, RaiderDetail ~23, Completion ~8,
   Settings ~11, LoadSave ~8, MainMenu ~7. The cheapest general fix is the same shape as this unit's:
   `Cards.gd`'s `_portrait()`/gear-icon `load()`s and `Widgets.Outline`'s shader load through a static
   strong cache (one Dictionary each). Not done here: `Cards.gd` and `Widgets.gd` are W5-KIT3's this wave.
6. `Frame.build()` is 3-4 ms with its textures held (was ~15 ms cold: emblem, two wordmarks, two .json
   baselines, six rail glyphs, four chip icons per turn). FIXED (`Frame._tex_cache`, `_baseline_cache`).

With §1-§3 applied the gate's stage 8/8 reads `PERF OK  14 screen(s) within 140 ms mount` (measured with
`--warm`: MainMenu 27, Town 47, AdventureBoard 61, Tavern 60, Guildhall 72, Market 64, RaidPrep 59,
RaiderDetail 41, RaidView 42, Results 71, Completion 26, Settings 29, LoadSave 20, RaidView revisit 35 —
every row inside the budget with a 2x margin, boosting). Without them the cold table is 6 rows over
(Tavern 194, Guildhall 210, Market 183, RaidPrep 171, RaidView 161, Results 165) and every revisit inside
it (RaidView revisit 37 ms).

Boot cost of §1, measured: ~1.0 s for the thirteen scenes + ~0.2 s for the five plates, behind the
"Loading" card that is already up. If that is judged too long for a boot, the honest alternative is to
warm only the hub's rail (Town, Tavern, Guildhall, Market, AdventureBoard, Settings) and let the raid
screens compile on the first Depart — `warm()` takes a list.

## 1. game/ui/Boot.gd:149 (compile the screens and load the plates behind the overlay, before the first page turn; four-space file)

old:
```
    # The display choice was applied in `_ready()`, before the overlay painted.
    router.register_host(_host)
    if not router.goto(MAIN_MENU):
```

new:
```
    # The display choice was applied in `_ready()`, before the overlay painted.
    router.register_host(_host)
    # W5-MOUNT: the thirteen screens' scripts compile now (~1 s boosting) and
    # the five plates load (~0.2 s), behind the card, so no page turn pays for
    # them later — measured at 45-140 ms and ~37 ms of a first visit's mount
    # (build/plan/report-W5-MOUNT.md; tools/perf_probe.gd --warm --split).
    router.warm()
    SceneStage.warm()
    if not router.goto(MAIN_MENU):
```

## 2. game/ui/Boot.gd:18 (the stage's script, for `SceneStage.warm()` above; Boot already preloads the rest of game/ui)

old:
```
const Frame = preload("res://game/ui/Frame.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
```

new:
```
const Frame = preload("res://game/ui/Frame.gd")
const SceneStage = preload("res://game/ui/SceneStage.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
```

## 3. tools/verify.sh:273 (the gate measures the game as Boot leaves it — apply WITH §1, never without: `--warm` on a Boot that does not warm would print numbers the player never sees)

old:
```
  OUT=$(timeout "$GODOT_PERF_TIMEOUT" "$GODOT" --path . --script res://tools/perf_probe.gd 2>&1)
```

new:
```
  # --warm: Boot compiles the screens and loads the plates behind its overlay
  # (W5-MOUNT), so the rows measure the page turn a player actually makes.
  OUT=$(timeout "$GODOT_PERF_TIMEOUT" "$GODOT" --path . --script res://tools/perf_probe.gd -- --warm 2>&1)
```
