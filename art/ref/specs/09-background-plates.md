# 09 — Background plates

> **Status:** Measured, sections 1–5 complete; §3 rewritten for the bare plates · **Owner:** Art pass · **Updated:** 2026-09-15 (W5-TOOLS)
> **Inputs:** `ideaboard/Reference Concepts/Reference Concept {1,2,3}.png` (1536×1024, 1:1 framebuffer), `ideaboard/Reference Graphics/*.png` (asset sheets), `00-canon-reconciliation.md` (cited, not re-litigated).
> **Kit:** `tools/art/refkit.py`, `tools/art/slice.py`.

**In one line:** the three concepts already contain three finished, in-game-size scene plates (guild hall, void arena, camp); every other screen's backdrop is either a crop of one of those, a sheet plate that is far too small to use at 1:1, or must be composed.

---

## 1. The resolution verdict

### 1.1 What the concepts give us at 1:1

All rects are `x, y, w, h` in framebuffer px (= Godot layout px). Edges were read pixel-by-pixel (`refkit.py px`-equivalent dumps), not from the run tool, because the frames are 1-px strokes.

| Concept | Scene viewport (interior, plate-visible) | How it is framed | Opaque UI that sits *on* the plate (unrecoverable underneath) |
|---|---|---|---|
| C1 Guild Hall | **`212, 78, 929, 637`** (x 212–1140, y 78–714) | Bevelled panel. Bevel light line x=208 / x=1143, y=74 / y=717; outer dark stroke x=206 / x=1149, y=72 / y=719 → panel outer `206, 72, 944, 648`. Header bar y 0–72 (`#070E14`–`#0D151C`), rail panel x 0–205, bottom strip panel starts y=733 (bevel 734–736 `#2D2723 #AB8D74 #564D43`), 13-px gap y 720–732 between scene panel and strip. | Nothing structural — but 5 speech bubbles and ~14 patrons are painted *into* the scene (see §3). |
| C2 Void arena | **`0, 0, 1536, 735`** (full-bleed; y 0–734) | No frame. Bottom strip panel top stroke y=735–737 (`#000108 #16222E #21303F`); strip card left edge x=20. | Objective panel `207, 0, 313, 325`-ish dark block (component find), boss bar/minimap blocks `1269,0,119,202`, `1367,38,142,125`, `1424,177,87,152`, `1334,281,186,151`; speech bubble `902, 391, 65, 111`; damage numbers; the Void Colossus itself occupies x ≈ 1000–1536. |
| C3 Camp | **`190, 0, 1346, 735`** (full-bleed right of the rail; y 0–734) | No frame. Rail panel `0, 0, 190, 468` (dark `#000D16`, ends y=467; scene visible below it at x<190 from y=468). Sidebar panel outer `1164, 74, 358, 590` (bevel x=1166 `#8F7F74`, y=77 `#B29A83`; scene resumes x≥1522 and y≥664). Bottom strip top stroke y=735–737 (identical to C2). Header chips float on the sky — no header bar. | Rail (0–189 × 0–467), sidebar (1164–1521 × 74–663), header chips, 4 building label pills, 1 speech bubble, ~12 raiders. |

Both C2 and C3 put the bottom strip at **y=735**; C1 puts it at **y=733** with a framed scene. The scene plates therefore need at most **735 rows** — nothing under the strip is ever visible and nothing under it exists in the references.

### 1.2 Pixel pitch — the fact that decides everything

Neighbour-identity test (fraction of horizontally adjacent pixel pairs with |Δrgb| < 6) at lags 1–4, and the even-start vs odd-start split that would expose a 2× NEAREST upscale:

| Source | lag1 | lag2 | even/odd start | Reading |
|---|---|---|---|---|
| C1 scene 929×637 | 0.260 | 0.174 | 0.246 / 0.273 | 1-px pitch |
| C2 scene 1536×735 | 0.339 | 0.249 | 0.334 / 0.344 | 1-px pitch |
| C3 scene 1346×735 | 0.238 | 0.177 | 0.235 / 0.241 | 1-px pitch |
| Top-down tavern 1536×1024 | 0.392 | 0.313 | 0.377 / 0.408 | 1-px pitch (flatter fills) |
| Top-down town 1536×1024 | 0.105 | 0.070 | 0.098 / 0.112 | 1-px pitch, very dense |
| 0718af5b plate 512×274 | 0.092 | 0.052 | 0.087 / 0.098 | 1-px pitch |
| 0f2ce34a plate 355×188 | 0.085 | 0.045 | 0.086 / 0.085 | 1-px pitch |
| de1918ac plate 432×237 | 0.175 | 0.105 | 0.168 / 0.182 | 1-px pitch |
| bbb8018d plate 402×368 | 0.073 | 0.046 | 0.071 / 0.075 | 1-px pitch |

No source shows the ≥0.5 lag-1 identity or the even/odd asymmetry of an upscaled image. **Every plate — concept and sheet — is authored at display density (1 image px = 1 art px).** Consequently a sheet plate cannot be integer-upscaled without its pixel pitch becoming 2–4× coarser than every UI element and sprite around it. Option (b) "integer NEAREST upscale" is dead for the small plates; it survives only for the two full-frame 1536×1024 top-down plates, which are already at 1:1.

### 1.3 Required vs available, per game screen

Required sizes come from §1.1. "Cover" = the plate must be at least this big at 1:1.

| Screen | Backdrop required (1:1) | Verdict | Source → size | Shortfall / notes |
|---|---|---|---|---|
| **Guildhall** | 929×637 in the C1 frame | **(a) crop C1** | C1 `212,78,929,637` | Exact. Cleanup: bubbles (§3). Alternatives: 0f2ce34a guild-hall 355×215 (needs 2.62×/2.96× — non-integer, rejected), de1918ac tavern 432×248 (2.15×/2.57×), bbb8018d town 367×368 (2.53×/1.73×), 0718af5b town 512×274 (1.81×/2.32×). All rejected on pitch. |
| **Tavern** | 929×637 (same chrome as Guildhall) *or* full-bleed 1536×735 | **(b) top-down tavern plate at 1:1** as the primary proposal; fallback (a) C1 crop with a warmer grade | `ChatGPT … 02_17_48 PM.png` 1536×1024, crop `0, 0, 1536, 735` (or `0, 144, 1536, 735` to centre the bar) | Exact, no burned-in text, no characters. Camera changes from C1's side-on to top-down; it reads as "looking down at the candidate board". If the designer wants one camera, use the C1 crop and vary the grade. |
| **Town / Camp** | 1346×735 (x 190–1535) | **(a) crop C3** | C3 `190, 0, 1346, 735` | Exact for the visible region. Cleanup: 4 label pills, 1 bubble, ~12 raiders (§3). Sheet camps: 0f2ce34a 355×198 (3.79×), bbb8018d 402×368 (3.35×/2.0×), de1918ac outpost 432×216 (3.12×/3.40×), 0718af5b camp 512×178 (2.63×/4.13×) — all rejected on pitch. |
| **MainMenu** | 1536×1024 full frame | **(b) top-down town plate at 1:1** | `ChatGPT … 02_20_36 PM.png` 1536×1024 | Exact framebuffer, no UI, no labels ("The Rusty Tankard" sign is in-world). The only full-frame 1:1 exterior we own. C3 cannot do it: 190 px missing on the left. |
| **Market** | 1346×735 | **(a)-derived**: C3 crop under a dim scrim, or the sub-crop `190, 300, 700, 435` (market tents, 1:1) behind the panel | C3 | No zoom allowed (pitch); if a tighter "storefront" view is wanted it is (c) re-author. |
| **Facilities** (Blacksmith gate, upgrades) | 1346×735 | **(a)-derived**: C3 crop, dimmed | C3 | Same as Market. |
| **AdventureBoard** | 1346×735 | **(a)-derived**: C3 crop, dimmed; the 0718af5b World Map plate 512×274 is *not* usable as a map backdrop (2.63× short). | C3 | A proper map screen is **(c)** — nothing at 1:1 exists. |
| **RaidPrep** | 1536×735 | **(a)-derived**: C2 crop, dimmed (the arena you are about to enter) | C2 | Boss region must be cleaned first (below). |
| **RaidView** | 1536×735 | **(a)+(c): crop C2, re-author the right third** | C2 `0, 0, 1536, 735` | Environment x 0–~1000 is clean once bubble/numbers/combatants are removed. The Colossus (x ≈ 1000–1536, y ≈ 60–735) is painted into the plate and must be removed so the boss can be a sprite with HP/death states — that is a paint-out of roughly 536×675 px against tentacles and portal glow: real re-authoring work. |
| **Results** | 1536×735 | **(a)-derived**: cleaned C2, dimmed | C2 | — |
| **Roster** | 929×637 or 1346×735 | **(a)-derived**: C1 interior, dimmed | C1 | Roster is a Guildhall tab (`00` §2.6). |
| **RaiderDetail** | 929×637 | **(a)-derived**: C1 interior, dimmed | C1 | — |
| **Settings** | 1346×735 / 1536×1024 | **(a)-derived**: MainMenu plate (top-down town) dimmed in-menu; C3 dimmed in-game | town plate / C3 | — |

**Summary:** three concept crops (C1 interior, C2 full-bleed, C3 full-bleed) plus the two full-frame top-down plates cover every screen at 1:1. The thirteen small sheet plates (§2) are reference and mood only; none reaches even 40 % of its target dimension, and the pitch test forbids scaling them. Nothing needs to be composed from scratch except the RaidView boss paint-out and, if a real overworld map is wanted, an AdventureBoard map.

## 2. Catalogue

Every plate we own. Rects are `x, y, w, h` in the source PNG; "content" excludes the sheet's own frame strokes. Sheet plates carry an ID used in §3/§5.

### 2.1 Concept scene regions (final in-game size)

| ID | File | Rect | Native size | Scene |
|---|---|---|---|---|
| **C1-HALL** | `Reference Concepts/Reference Concept 1.png` | `212, 78, 929, 637` | 929×637 | Guild hall interior, side-on 3/4: bar with two bartenders at left-centre, skull banner on the upper gallery, hearth at far left (x≈212–330, y≈380–470 in FB), rug + long table at centre, arched window to the harbour at right, stair to a gallery at far right. Patrons and 5 speech bubbles baked in. |
| **C2-VOID** | `Reference Concept 2.png` | `0, 0, 1536, 735` | 1536×735 | Void-realm arena: cavern with blue crystal shafts (x 0–300), ruined stone platforms and a hanging skull banner at left-centre, four combatants and cast VFX at y≈250–350, the Void Colossus filling the right third with a magenta portal core at ≈(1262, 210). |
| **C3-CAMP** | `Reference Concept 3.png` | `190, 0, 1346, 735` | 1346×735 | Cliff-top camp at dusk: tents with red awnings, campfire at ≈(410, 760 → clipped by strip), skull-crest sails, a moored airship at right (x 1000–1160, y 560–700), harbour and distant city on the sky line, sky y 0–~200. Rail (0–189×0–467) and sidebar (1164–1521×74–663) are opaque over it. |

### 2.2 Sheet `0718af5b-2c1e-41fd-8123-c74ea114b810.png` — bottom strip, white ground, 1-px white gutters (col x=513, row y=845)

| ID | Rect | Native | Scene | Burned-in label |
|---|---|---|---|---|
| S1-TOWN | `0, 571, 512, 274` | 512×274 | Guild hall interior (bar, hearth, banner) | "Town / Guild Hall Background" pill, top-left |
| S1-WORLD | `515, 571, 507, 274` | 507×274 | Overworld: cliffs, sea, airship, cloud bank | "World Map / Overworld Background" pill `521, 573, 163, 20` |
| S1-VOID | `1024, 571, 512, 274` | 512×274 | Void realm cavern, purple tentacles right | "Raid / Void Realm Background" pill |
| S1-CAMP | `0, 846, 512, 178` | 512×178 | Camp / outpost on a cliff | "Camp / Outpost Background" pill |
| S1-CAVE | `515, 846, 507, 178` | 507×178 | Dungeon / cave, blue-lit | "Dungeon / Cave Background" pill |
| S1-FOREST | `1024, 846, 512, 178` | 512×178 | Forest / wilderness | "Forest / Wilderness Background" pill `1031, 849, 161, 20` |

Pill geometry: 20 px tall, top edge at plate `y+2` (top row) / `y+3` (bottom row), left edge at plate `x+7`, width 130–165 depending on the string; a covering rect of `x+6, y+1, 170, 24` clears all six. Only the two named pills were measured; the others are covered by that rect.

### 2.3 Sheet `0f2ce34a-d799-4c05-bfc0-e830fdcba947.png` — right column "BACKGROUND SCENES", slate gutter `#3F6794`-family at x ≤ 1180, plates abut vertically

Header band y 0–30 (`#0A1722`) carries the section label; it is outside every plate.

| ID | Rect | Native | Scene |
|---|---|---|---|
| S2-HARBOUR | `1181, 31, 355, 198` | 355×198 | Camp on a headland over a harbour, airship right |
| S2-CAVERN | `1181, 229, 355, 188` | 355×188 | Blue crystal cavern with rope bridges (boundary rows 417–419 `#182B5A`) |
| S2-PORTAL | `1181, 420, 355, 185` | 355×185 | Void portal shrine, magenta core (gutter rows 605–609 slate) |
| S2-ISLAND | `1181, 610, 355, 199` | 355×199 | Island city with airship, blue sky |
| S2-HALL | `1181, 809, 355, 215` | 355×215 | Guild hall interior (clipped at the sheet's bottom edge) |

No burned-in text on any of the five.

### 2.4 Sheet `bbb8018d-68e0-46ca-91d7-fd4f18fc1fd8.png` — bottom strip, sheet bevel at y 654–655, plates y 656–1023, dark separator columns 402–403, 771–775, 1142–1149

| ID | Rect | Native | Scene | Burned-in label |
|---|---|---|---|---|
| S3-CAMP | `0, 656, 402, 368` | 402×368 | Camp with red awnings, harbour, airship | "Camp Background" text on a dark box at the plate's top-left, y 656–687 |
| S3-TOWN | `404, 656, 367, 368` | 367×368 | Guild hall interior | "Town / Guild Hall Background" (dark box spans to y=687 at x=600) |
| S3-CAVE | `776, 656, 366, 368` | 366×368 | Dungeon / cave, blue waterfalls | "Dungeon / Cave Background" |
| S3-ARENA | `1150, 656, 386, 368` | 386×368 | Raid / boss arena: ringed stone floor under a void eye | "Raid / Boss Arena Background" |

Label boxes: dark band 32 px tall at the top of each plate (y 656–687), width not measured per label — cover with `x0, 656, 300, 32`.

### 2.5 Sheet `de1918ac-90fe-436b-a041-6ffdf0efced6.png` — right column "FULL BACKGROUNDS (NO SPRITES)", navy ground `#000913`, each plate has a 2-px frame line then a 4–6 px dark gap

All four share **x 1093–1524 (432 wide)**; frame lines at x 1090–1092 / 1525–1526. Captions ("TAVERN / GUILD HALL (INTERIOR)" etc.) sit in the gutter *below* each plate, outside the content rect.

| ID | Content rect | Native | Frame rows | Scene |
|---|---|---|---|---|
| S4-TAVERN | `1093, 39, 432, 248` | 432×248 | 37–38 top, 287–288 bottom | Tavern / guild hall interior with hearth, table, skull banner |
| S4-VOID | `1093, 314, 432, 237` | 432×237 | 307–308, 551 | Void colossus cavern (no sprites — cyan waterfalls, purple rock) |
| S4-OUTPOST | `1093, 577, 432, 216` | 432×216 | 571–572, ~794 | Outpost / camp with airship, harbour |
| S4-SPIRE | `1093, 818, 432, 178` | 432×178 | 811–812 (+816–817 inner), 996–997 | The Rotting Spire: castle on a green sky (non-canon name — `00` §2.3) |

### 2.6 Full-frame top-down plates (1:1, no UI, no labels)

| ID | File | Rect | Native | Scene |
|---|---|---|---|---|
| **TD-TAVERN** | `Reference Graphics/ChatGPT Image Sep 9, 2026, 02_17_48 PM.png` | `0, 0, 1536, 1024` | 1536×1024 | Tavern interior from above: bar along the top wall with hearth at ≈(490,105), long tables, round tables, rug at centre, stair at left. No characters, no text. |
| **TD-TOWN** | `Reference Graphics/ChatGPT Image Sep 9, 2026, 02_20_36 PM.png` | `0, 0, 1536, 1024` | 1536×1024 | Walled harbour town from above: gate at top centre, fountain plaza at centre (≈1060,780), market awnings, "The Rusty Tankard" tavern at left, docks and a ship bottom-left, waterfall bottom-right. No characters, no UI text. |

Both are the same camera as each other and a different camera from C1/C2/C3.

## 3. The plates that ship — the six bare backgrounds

> **Rewritten 2026-09-15 (W5-TOOLS, audit `M4B-CONV-02`).** This section used to be the production
> plan for CROPS of the concepts — the crop rects and, for each, the paint-out list (the four speech
> bubbles over C1-HALL's patrons, C3-CAMP's four label pills and its bubble, C2-VOID's damage numbers
> "-842"/"-317", its bubble, its combatants and the Void Colossus). The designer's 2026-09-11 ruling
> (BUILD_STATE, "the art directive") retired every crop: no screen stands on a mockup with painted
> people or baked UI. The crops were deleted in waves 2 and 5 (`camp_plate`, `guildhall_plate` with
> their scene JSON; then `arena_plate`, `menu_plate`, `tavern_plate`), so there is nothing left to
> paint out and the lists are gone with them. What ships is the designer's own bare plates, below;
> the animated life that replaced the baked figures is §4's per-scene stack, read from
> `game/assets/scenes/<name>.json` by `game/ui/SceneStage.gd`.

Every plate is 1536×1024, 1:1, imported with `Filter = Nearest`, `Mipmaps = off`, unedited from
`ideaboard/bare backgrounds/`. The one plate per screen is also recorded beside the switch that
frames it in `00-canon-reconciliation.md` §2.7; the framing offsets are the screens' own constants.

| Plate (`game/assets/bg/`) | Source (`ideaboard/bare backgrounds/`) | Scene JSON | Serves |
|---|---|---|---|
| `stage_camp.png` | `camp.png` | `stage_camp.json` | Town (full-bleed, offset −46,−62), AdventureBoard (−20,−80), Completion (−46,−94); the hall family — Guildhall / Roster / Facilities / Records, RaiderDetail, LoadSave — through `Guildhall.bare_stage()` at `HALL_FRAMING = "same"` (Q03) |
| `stage_town.png` | `town_world.png` | `stage_town.json` | MainMenu only (the aerial; no figures at that scale) |
| `stage_tavern.png` | `tavern.png` | `stage_tavern.json` | Tavern |
| `stage_market.png` | `market.png` | `stage_market.json` | Market |
| `stage_arena_cave.png` | `encounter_cave_large_full.png` | `stage_arena_cave.json` | RaidPrep, RaidView, Results — `SceneStage.DEFAULT_ARENA`, every fight until an encounter→arena mapping is ruled (Q18) |
| `stage_arena_dungeon.png` | `encounter_dungeons_large_full.png` | `stage_arena_dungeon.json` | authored (marks, lights, shimmer); loaded by no screen yet |
| (inherits) | — | — | Settings stands on the plate of the screen it was opened over, dimmed (`Settings.STAGE_FOR`; default the camp at the Town's framing) |

Nothing under a plate is patched: the chrome (header, rail, sidebar, strip) is drawn by the kit over
whatever the plate has there, so a region may move without the plate being extended. The reference
thumbnails of §2.2–2.5 are not shipped (nothing reads them at runtime); the concept crops they were
going to guide are the ones deleted above.

## 4. Layer stack per scene (back to front)

Principle: the plate is one `TextureRect` (Nearest, no scale) at the rect given in §1.1. Anything that *changes* — is clicked, animates, moves, or is data-driven — sits above it as its own node, because the plate is a single texture and cannot be partially updated. Everything static stays in the plate, because splitting static content costs draw calls and authoring time for no visible gain — but the plates are BARE (§3): every figure, bubble, number and pill is a layer, never a pixel of the plate. Dimming for modal screens is a `modulate` on the plate node, never a second texture. The "keep as ambient / baked v1" rows the tables below used to carry are deleted as `SceneStage` replaced them (actors, bubbles, the airship still owed under `M4B-VFX-01`).

### 4.1 Guildhall (C1-HALL) — also Roster / RaiderDetail with the plate dimmed

> **Superseded as a screen ground — designer ruling, 2026-09-13.** C1-HALL is a crop of Concept 1
> with its patrons and five speech bubbles painted in, which the 2026-09-11 directive forbids under a
> screen. On 2026-09-13 the designer confirmed the replacement: *"background graphics with baked in UI
> … need to be replaced with our naked backgrounds"*. The hall family — Guildhall (Roster, Facilities,
> Records), RaiderDetail, LoadSave — therefore stands on the bare **`stage_camp`** plate
> (`game/assets/scenes/stage_camp.json`, the Town's ground) with the screen's panels over it, and
> Settings inherits the stage of the screen that opened it (default `stage_camp`). Whether the hall
> takes the Town's framing or a tighter one is the one part still open (plan Q03; `HALL_FRAMING`
> switch, default `same`). This closes audit `M4B-CONV-03`; pointer: [15 BL-78](../../../docs/15-open-questions.md).
> The table below is kept as the record of what the crop contained; rows 2–6 now belong to `stage_camp` (the baked-patrons row is gone: the crop is deleted and the figures are `SceneStage` actors).

| # | Layer | Node | Why separate |
|---|---|---|---|
| 0 | Header bar (y 0–72), rail panel, bottom-strip panel, scene panel frame `206, 72, 944, 648` | UI (`06`) | Chrome; the plate must not carry its own frame or the frame cannot be re-styled. |
| 1 | **Plate** `guildhall_interior.png` at `212, 78` | `TextureRect` | — |
| 2 | Hearth fire (far left, ≈ 212–330 × 380–470) | `AnimatedSprite2D` | Animated (§5). |
| 3 | Chandelier/candle flames (gallery lamps, table candles) | `AnimatedSprite2D` ×N or one flicker shader on small quads | Animated (§5). |
| 5 | Interactive hotspots (bar → Tavern, board → Adventure's Board, stair → Records) | `Button`s with `flat=true` and hover outline | Must be `Button` for the test suite and for hover/disabled-with-reason states. |
| 6 | Speech/event bubbles (canon: raiders talk — `docs/13` §12) | `Control` bubble component | Data-driven text; never baked. |
| 7 | Panels: Current Raid sidebar, roster strip, events log | UI | — |

### 4.2 Town / Camp (C3-CAMP) — also Market / Facilities / AdventureBoard with the plate dimmed

| # | Layer | Node | Why separate |
|---|---|---|---|
| 1 | **Plate** `stage_camp.png` at the Town's framing (bare; `camp_town.png` was never cut) | `TextureRect` | — |
| 1b | (Optional, v2) sky/cloud layer over `190, 0, 1346, 200` | `TextureRect` + UV-scroll shader | Only if the sky is re-authored as a tileable strip; the reference sky is baked and static. |
| 2 | Campfire (≈ 400–430 × 720–735 visible; the fire body is under the strip — the visible part is the glow on the tents) | `GPUParticles2D` + `PointLight2D`-free modulate pulse on a glow quad | Animated (§5). |
| 3 | Lanterns / torches on tent poles | `AnimatedSprite2D` | Animated. |
| 5 | Water shimmer (harbour, y ≈ 560–735 right of x 900) | shader on a masked quad | Animated. |
| 6 | Building hotspots: Guildhall, Tavern, Market, Blacksmith (gated, "Maybe"), Adventure's Board | `Button`s (`Widgets.button_with_reason`) | Test suite pins five names and the Blacksmith gating. |
| 7 | Rail `0, 0, 190, 468`, sidebar `1164, 74, 358, 590`, header chips, bottom strip | UI | Chrome over the plate; the plate has no pixels under them. |
| 9 | Weather (rain/embers) | `GPUParticles2D` full-viewport | Canon says nothing about weather; behind `GameSettings.weather` if added. |

### 4.3 RaidView (C2-VOID) — also RaidPrep / Results with the plate dimmed

| # | Layer | Node | Why separate |
|---|---|---|---|
| 1 | **Plate** `stage_arena_cave.png` (bare; `raid_void.png` was never cut — the boss is a rank strip, never a pixel of the plate) | `TextureRect` | — |
| 2 | Crystal-shaft glow (x 0–300) | shader (brightness pulse on a masked quad) | Animated. |
| 3 | Portal core (≈ 1262, 210) | `Sprite2D` ring + rotation shader | Animated; also the boss "spawn point". |
| 4 | **Boss sprite** (Void Colossus / canon "Main Boss") | `AnimatedSprite2D` | HP/hit/death states; the whole reason the plate loses the colossus. |
| 5 | Combatant sprites (12 raiders, canon; strip pages in fours per `10`) | `AnimatedSprite2D` ×12 | Data-driven. |
| 6 | VFX (bolts, slashes, hit sparks) | `GPUParticles2D` / frame sprites | — |
| 7 | Damage numbers, speech bubbles | `Label`-based components | Data-driven text. |
| 8 | Objective panel, boss bar, minimap, speed buttons, bottom strip (y ≥ 735) | UI | — |
| 9 | Dust motes / drifting ash | `GPUParticles2D` | §5; optional. |

### 4.4 MainMenu (TD-TOWN) and Tavern (TD-TAVERN)

| # | Layer | Node | Why separate |
|---|---|---|---|
| 1 | **Plate** 1536×1024 (menu) / 1536×735 (tavern) | `TextureRect` | — |
| 2 | Fountain spray (menu, ≈ 1060, 780) / hearth (tavern, ≈ 490, 105) | `GPUParticles2D` / `AnimatedSprite2D` | Animated. |
| 3 | Waterfall (menu, bottom-right) / candle flames (tavern) | UV-scroll shader / flicker | Animated. |
| 4 | Menu buttons / Tavern candidate board (`07`) | UI | — |

### 4.5 Settings

No plate of its own: it inherits the plate of the screen it was opened from, dimmed to `modulate = Color(0.55, 0.55, 0.62)` (a value to be confirmed against `04-palette.md`), so the desk "does not move" (`00` §1, M5 kept).

## 5. Animation opportunities ranked

Cost is authoring + integration time at this project's pace; "life" is how much of the screen it wakes up and how often the player sees it. Every effect is a node *over* the plate (§4), so none requires touching the exported PNGs except where a region must be cut out and patched.

| Rank | Effect | Where | Technique | Cost | Life-per-effort verdict |
|---|---|---|---|---|---|
| **1** | **Hearth / campfire fire** | Guildhall hearth (212–330 × 380–470), Camp fire glow (≈400–430 × 720–735 + tents), Tavern hearth (≈490,105) | 4–6 frame `AnimatedSprite2D` cut from the `FX & Misc` / `Animations & Effects` rows of 0718af5b / bbb8018d / de1918ac (fire sprites exist on all three sheets) + a `modulate` sine pulse (period 1.6–2.2 s, ±8 % value) on a soft orange glow quad behind it | Low (1 sprite strip, 1 tween) | Highest. On screen for the two screens the player spends most time on. The glow pulse alone, with no frames, already reads as fire on the baked flames. |
| **2** | **Torches / lanterns / candle flames** | Guildhall gallery lamps + table candles, Camp tent lanterns, Tavern candles, Void arena wall braziers (x ≈ 300–500, y ≈ 400–500) | Same fire strip at 1/3 scale is *not* allowed (pitch); use a dedicated 3-frame 6×8 flame strip; per-instance random phase offset | Low–Medium (many placements; placement list comes from the layout specs) | Very high: many small sources of motion make a still plate feel inhabited. |
| **3** | **Portal / void core rotation + pulse** | Void arena core ≈(1262,210) and S3-ARENA-style eye | Ring `Sprite2D` with a UV-rotation shader (angle += 0.15 rad/s), plus a `modulate` alpha pulse on a magenta glow quad (period 2.4 s) | Medium (no paint-out: the bare arena of §3 carries no boss) | High for RaidView — it is the focal point and the boss spawn; couples with hit flashes. |
| **4** | **Water shimmer** | Camp harbour (y ≈ 560–735, x ≥ 900), Menu town docks/waterfall | Shader on a masked quad: two scrolling noise textures sampled at UV·(1/64) at 0.02 and −0.013 UV/s, output added as ±6 value on the plate's own colours (sample the plate via `screen_texture`) | Medium (mask painting) | High on Camp because the water is a large area; waterfall on the menu uses the same shader with a vertical scroll. |
| **5** | **Crystal-shaft pulse** | Void arena x 0–300 | `modulate` value pulse on a cyan glow quad masked to the shafts, period 3 s, ±10 % | Low | Good; cheap, large area, but only in RaidView. |
| 6 | Dust motes / embers / ash | Guildhall (motes in window light), Camp (embers above fire), Void (ash) | `GPUParticles2D`, 20–40 particles, 1–2 px squares, lifetime 4–8 s, slight upward drift | Low | Pleasant; low salience — do after 1–5. |
| 7 | Clouds / sky drift | Camp sky y 0–200 | Requires a re-authored tileable cloud strip (the baked sky is not tileable) → UV-scroll shader at 2–4 px/s | Medium–High (art) | Medium; subtle at that speed, and the header chips cover much of the sky. |
| 8 | Airship drift | Camp (1000–1160 × 560–700), Menu town (none baked) | Cut the airship, patch 160×140 px of sky/water behind it, `Tween` position ±3 px over 6 s + slight bob | Medium–High (patch) | Medium; charming but a lot of patching for a 3-px motion. Would pair with a canon "airship = raid transport" reading, which canon does not make. |
| 9 | Chandelier sway | Guildhall gallery chandeliers | Cut and patch each (small), rotate ±2° period 4 s around the chain top | Medium | Low–Medium; small and subtle. |
| 10 | Weather | Camp | `GPUParticles2D` rain/snow full viewport | Low | Not in canon; behind a switch if ever. |

**Top five by life-per-effort: fire (1), torches/candles (2), portal core (3), water shimmer (4), crystal pulse (5).** Items 1, 2 and 5 need zero plate surgery and can land the same day the plates are exported; 3 needs none either on the bare arena (§3); 4 needs masks but no plate changes.
