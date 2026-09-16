# 08 — Asset sheets B1 / B2 inventory

> **Status:** Measured (all six sections) · **Owner:** Art pass · **Updated:** 2026-09-09
> **Inputs:** `ideaboard/Reference Graphics/de1918ac-90fe-436b-a041-6ffdf0efced6.png` (B1, dark navy bg), `ideaboard/Reference Graphics/bbb8018d-68e0-46ca-91d7-fd4f18fc1fd8.png` (B2, white bg). Cross-referenced against A1 (`0f2ce34a…`, alpha) and A2 (`0718af5b…`) from `07-assets-sheet-a.md`.
> **Canon:** the nine classes in `sim/model/Enums.gd` (see `00-canon-reconciliation.md` §2.2 — Ranger/Berserker/Engineer/Thief rows are non-canon and are harvested as variants or dropped; cited, not re-litigated).
> **Tools:** `tools/art/refkit.py`, `tools/art/slice.py islands`. All coordinates are sheet pixels at 1:1.

---

## 1. Section map

### 1.1 B1 (dark navy)

Sheet: 1536×1024 RGB, **no alpha channel** although its printed title says "TILESET & SPRITE SHEET (TRANSPARENT BACKGROUND)" — an AI-mockup artifact; the sheet must be keyed. Sheet ground `#010F19` (corner `#010F19`, panel fill `#000812`–`#010913`, i.e. indistinguishable from the ground — panels are delimited only by a 1 px border line). Border line colour ramps `#1F3344` / `#153347` / `#0E2D44` / `#143240` (blue-grey, lum 40–70), detected as gap-tolerant runs ≥110 px of pixels with R≤40, G 22–70, B 38–95, B>G>R. Coordinates below are the border-line pixel (inclusive; the second number of a `/` pair is the 2 px line's second row/column).

| # | Printed label (as on sheet) | x0 | y0 | x1 | y1 | w×h (outer) | Notes |
|---|---|---|---|---|---|---|---|
| T | *(title block)* "A Guild Story — TILESET & SPRITE SHEET (TRANSPARENT BACKGROUND)" | 0 | 0 | 325 | 93 | 326×94 | Skull mark at 12–70 x, 6–60 y. Not an asset. |
| 1 | "STRUCTURES & BUILDINGS" *(mislabel — panel holds ground/wall tiles, not buildings)* | 8 | 94/95 | 325 | 318 | 318×225 | Left border obscured by tiles at x 11. Treat as **Terrain tiles A**. |
| 2 | "ENVIRONMENT TILES" | 325 | 7 | 554/555 | 318 | 231×312 | 4×4-ish block of 32-px-ish stone/grass/water tiles (top-left), cliffs below. |
| 3 | "STRUCTURES & BUILDINGS" | 561/562 | 7 | 850 | 318 | 290×312 | Houses, tents, banners on poles, a tower, market stalls. |
| 4 | "PROPS & INTERACTABLES" | 856/857 | 7 | 1077 | 318 | 222×312 | Barrels, crates, chairs, tables, torches, a tall skull banner at x≈1030. |
| 5 | "TERRAIN & NATURE" | 8 | 326 | 230/231 | 613/614 | 224×289 | Trees, bushes, mushrooms, crystals, a rock pillar. |
| 6 | "CHARACTER SPRITES (RECRUITS / GUILD MEMBERS)" | 237/238 | 326 | 696/697 | 613/614 | 461×289 | 5 rows × 16 cols of ~26 px-tall chibi sprites, **unlabelled by class**. |
| 7 | "NPCS & TOWNSFOLK" | 703 | 326 | 1077 | 613/614 | 375×289 | 5 rows × 12 cols, same sprite scale. |
| 8 | "ENEMIES & MONSTERS" | 8 | 621/622 | 513/514 | 822/823 | 507×203 | 3 rows: goblins/skeletons/undead; spiders/beasts; heavies (see §3). |
| 9 | "BOSS SPRITES" | 520/521 | 621/622 | 1077 | 822/823 | 558×203 | Four bosses: eye-tentacle aberration, stone/earth brute, red dragon, airship (see §4). |
| 10 | "ANIMATIONS & EFFECTS" | 8 | 830/831 | 362 | 1009 | 355×180 | 3 rows of VFX bursts, beams, sparkles, weapons (see §4.1). |
| 11 | *(no label)* | 369 | 830/831 | 428 | 1009 | 60×180 | Three ~40 px round glyphs: grey rune ring, purple sigil, green sigil — **ability/status icon candidates**. |
| 12 | "MISC / UTILITIES" | 434/435 | 830/831 | 665/666 | 1009 | 232×180 | Skull banners, torches, scaffold/gallows frame, fences, 4 rows of ~16 px item icons (see §5). |
| 13 | "VEHICLES / AIRSHIPS" | 672/673 | 830/831 | 926 | 1009 | 255×180 | Two airships + a rowboat + a sky-galleon. |
| 14 | "EXTRA" | 933/934 | 830/831 | 1077 | 1009 | 145×180 | Livestock: donkey, chicken, horse, wolf, bear, boar, cow. |
| 15 | "FULL BACKGROUNDS (NO SPRITES)" header + "TAVERN / GUILD HALL (INTERIOR)" | 1090 | 7 | 1525/1526 | 308 | 437×302 | Header strip y 7–37; plate ≈ x 1092–1524, y 37–287; caption strip y 287–308. |
| 16 | "VOID COLOSSUS (DUNGEON / RAID)" | 1090 | 315 | 1525/1526 | 571/572 | 437×258 | Plate ≈ y 315–552; caption 552–571. |
| 17 | "OUTPOST (WORLD / CAMP)" | 1090/1091 | 577/578 | 1525/1526 | 811/812 | 437×235 | Plate ≈ y 578–792; caption 792–811. |
| 18 | "THE ROTTING SPIRE (WORLD / RAID)" | 1090 | 817 | 1525/1526 | 1016 | 437×200 | Plate ≈ y 817–995; caption 995–1016. |

Panels 15–18 are the same four plates as B2's bottom row and Concept 1/2/3's viewports; `09-background-plates.md` owns them. Names "Void Colossus" / "The Rotting Spire" are non-canon per `00` §2.3 — plate *images* are usable, the *names* are not.

### 1.2 B2 (white)

Sheet: 1536×1024 RGB. **Not a white background**: every panel body is a fake-transparency checkerboard (`#EFF1F0` / `#DAD9DA`, lum 240 / 218) inside a light-grey panel with a 1–2 px grey outline (`#8B8B8B`–`#C1C0C1`), on a dark navy sheet ground (`#0C141F`, corner). Every panel has a black title bar (`#0D1720`, lum <40) 25 px tall with white bold sans text. Panel x-extents were read from the title-bar dark runs at y=3 / y=455 / y=634 (exact, ±0); y-extents from the grey outline (±1).

| # | Printed label | x0 | y0 | x1 | y1 | w×h | Notes |
|---|---|---|---|---|---|---|---|
| 1 | "Characters – Raiders (Player Controlled & NPCs)" | 0 | 0 | 355 | 622 | 356×623 | Row labels (left column, y of label baseline): Warrior 55, Rogue 107, Mage 158, Cleric 210, Ranger 263, Berserker 315, Druid 371, Engineer 425; "Raider Variants" 484 with two unlabelled rows at y≈510 and 560. **Only 5 of the 8 labelled rows are canon** (`00` §2.2). |
| 2 | "Enemies & Bosses" | 361 | 0 | 750 | 622 | 390×623 | Sub-labels: "Common Enemies" y≈45 (3 rows y 50–200), "Elite Enemies" y≈218 (2 rows y 225–375), "Bosses" y≈383 (2 rows of 3, y 385–620). |
| 3 | "Props & Interactive Objects" | 757 | 0 | 994 | 622 | 238×623 | Barrels, crates, banners, tents, bookshelves, tables, lanterns. Same vocabulary as B1 #4 at ~1.5× the pixel size. |
| 4 | "Tileset – Camp / Town" | 1000 | 0 | 1253 | 447 | 254×448 | Isometric-ish stone/wood tiles and fences — **perspective does not match** the concepts' side-on plates. |
| 5 | "Tileset – Dungeons / Caves" | 1260 | 0 | 1535 | 447 | 276×448 | Dark stone blocks, purple/blue crystals, lava cracks. Same perspective caveat. |
| 6 | "Environmental Elements" | 1000 | 452 | 1288 | 622 | 289×171 | Trees, bushes, stumps, signposts, small crystals; title bar y 452–475. |
| 7 | "Vehicles / Airships" | 1295 | 452 | 1535 | 622 | 241×171 | One large airship (~200×90) + a rowboat. |
| 8 | "Camp Background" | 0 | 630 | 400/403 | 1023 | 404×394 | Title bar y 630–654 spans the full sheet width; plate from y 655. |
| 9 | "Town / Guild Hall Background" | 403 | 630 | 768/771 | 1023 | 368×394 | |
| 10 | "Dungeon / Cave Background" | 771 | 630 | 1150/1152 | 1023 | 381×394 | |
| 11 | "Raid / Boss Arena Background" | 1152 | 630 | 1535 | 1023 | 384×394 | Purple vortex arena — the one plate **not** present on B1. |

## 2. Cross-sheet source ranking

The four sheets, as they actually are (not as their titles claim):

| Sheet | File | Ground / key | Labels | Notes |
|---|---|---|---|---|
| **A1** | `0f2ce34a…` | **real alpha** | Warrior, Ranger, Mage, Cleric, Rogue with **portrait-scale busts** (~48–56 px) + 4-frame rows; bosses ~230 px; "Combat Effects / VFX" ~35 items incl. slashes; "Misc / Decor" banners in 6 colours; 5 background plates | The only sheet that needs no keying. Warm-brown ground haze behind the alpha in some panels (see `07`). |
| **A2** | `0718af5b…` | checker (fake alpha) | 8 labelled classes incl. **Thief, Berserker, Engineer, Bard**; enemies labelled by family (Void Colossus, Abomination Swarm, Stone Golem, Undead Legion, Slime Hive, Constructs); "FX & Misc"; 6 plates incl. **World Map** and **Forest** | Widest plates (~505×255). Isometric buildings. |
| **B1** | `de1918ac…` | flat `#010F19` navy, **no alpha** (title lies) | Panels titled but **sprites unlabelled**; 80 raiders + 58 townsfolk; 31 monsters; 3 bosses (+1 misfiled airship); 19 VFX; 16 buildings; 4 plates | Dark key is clean for everything except black outlines/cloth; VFX are **usable unkeyed with ADD blend**. Side-on buildings match Concept 3. |
| **B2** | `bbb8018d…` | checker (fake alpha) on navy | 8 labelled class rows (**Ranger, Berserker, Engineer** non-canon) + 2 variant rows; enemies in 3 canon-shaped tiers (Common / Elite / Bosses); 6 bosses; 75 props; isometric tilesets; 4 plates incl. **Raid / Boss Arena** | Most *sprite poses* of any sheet (≈100 raider poses, 52 trash, 16 elites). Checker key erodes light pixels. No VFX. |

Ranking per category (1 = harvest from this first). "Style match" is to the three Reference Concepts.

| Category | 1st | 2nd | 3rd | 4th | Why |
|---|---|---|---|---|---|
| **Raider sprites (combat / raid strip)** | **B2** | A2 | A1 | B1 | B2 has the most poses per class (11) at the largest body size (22×37–50) with attack/cast poses the raid view needs; A2 has 8 labelled classes incl. Bard; A1's small sprites are 4-frame walk rows only; B1's are front-idle, unlabelled. Key cost: B2/A2 checker erodes highlights — accept and repair, or cut B2 and re-alpha from A1 where the same pose exists. |
| **Raider sprites (roster card / tavern board, static)** | **B1** | B2 variants | A1 | A2 | B1's 80 front-facing idles are exactly the "line-up" pose the roster cards and candidate board want; dark key is clean on their mid-tone leathers; pitch 28 px gives a ready grid. |
| **Portraits** | **A1** | — | — | — | Only A1 has bust-scale portraits (5 classes). B1/B2 have **none**. Missing canon portraits (Monk, Druid, Shaman, Bard, Wizard) are Aseprite work; B2's row sprites are too small (≤50 px) to crop into busts. |
| **Bosses** | **A1** | B1 | B2 | A2 | A1: alpha and ~230 px (nearest Concept 2's boss scale). B1: the best single aberration render (197×160, concept colourway) but only 3 bosses. B2: most *types* (6) but ≤147 px and checker-keyed. A2: labelled "Void Colossus" is split into body + loose tentacle parts (useful for animating) but names are non-canon (`00` §2.3). |
| **Enemies (trash / elite)** | **B2** | B1 | A2 | A1 | B2's tiers map 1:1 onto canon's Trash/Elite/Mini Boss/Main Boss naming (`data/encounters_t1.json`): 52 commons in 4 rows (~21×30) + 16 elites (~40×60). B1's 31 monsters add non-humanoid variety (spiders, ogres, eye-horrors) that B2 lacks. A2's are family-labelled but few; A1's are small. |
| **VFX** | **B1** (glows) / **A1** (slashes) | A2 | B2 (none) | — | B1: 19 standalone glows on near-black → ADD-blend, zero keying, no fringe — the cleanest VFX pipeline available. A1: alpha + the only slash arcs / sword-swing smears / impact stars. A2 "FX & Misc": ~20 items but checker-keyed glow falloff is destroyed. B2 has no VFX panel. Neither B1 nor A1 has true animation strips; all frames are singles. |
| **Props** | **A1** | B2 | B1 | A2 | A1 "Environment / Objects" is alpha. B2 has the most (75 islands) at ~1.5× B1's size, incl. tents and shelves the tavern scene wants; B1's 43 props are smaller but dark-keyed cleanly; A2's props are isometric. |
| **Tiles** | **A1** | B1 | A2 | B2 | A1 tileset is a regular ~32 px grid with alpha. B1 "Environment Tiles" top-left block is a 4×4 of ~32 px side-on ground tiles (stone/grass/water). A2 mixed. B2's two tilesets are **isometric** — wrong perspective for the side-on painted plates the concepts use. Tiles matter little: the concepts are plate-backed, not tiled. |
| **Buildings** | **B1** | A2 | A1 | B2 | B1 "Structures & Buildings": 16 side-on buildings (houses ×5, tents ×2, towers ×3, stalls, banner poles) that match Concept 3's camp callouts in perspective and palette. A2's are isometric; A1's are wall/tower segments; B2 has only two tents (in Props). |
| **Banners / UI ornaments** | **A1** | B1 | B2 | A2 | A1 "Misc / Decor": six banner colours + torches + shields, alpha. B1: the crimson skull guild mark in 5 drapes + the round skull-wreath medallion (only circular ornament) + torches/braziers, all dark-keyed. B2: 9 banners incl. the only navy/gold one, checker fringe. See §5. |
| **Backgrounds** | **A2** (width) / **B2** (Raid Arena) | B1 | A1 | — | Same generator scenes recur on all four. A2 has six incl. World Map and Forest at the widest (~505×255). B2 alone has the "Raid / Boss Arena" vortex plate that Concept 2's viewport is built on, at 400×368 (tallest). B1's four are 432×250 with baked-in captions inside the panel. Ownership: `09-background-plates.md`. |

**Single most useful conclusion:** cut *raider combat poses and enemy tiers from B2*, *static roster idles, buildings, glow-VFX and the guild-mark banners from B1*, and *portraits, bosses, slash-VFX and everything that must be alpha-clean from A1*. A2 contributes only Bard, the World Map/Forest plates, and animatable boss parts.

## 3. JSON manifest (B1 + B2 islands)

Keying thresholds used: **B1** `--key dark --thresh 35` (foreground = mean-RGB > 35; ground is lum = 10, panel borders lum 40-70 so regions are set inside the borders); **B2** `--key white --thresh 50` for bosses (foreground = lum < 205) and `--thresh 60` (lum < 195) for the raider/enemy rows where checker noise pixels otherwise bridge neighbours. `--min-area`: 200 B1 bosses, 60 VFX, 120 enemies, 400 B2 bosses. Boxes named `_MERGED` (w > 40) are two adjacent sprites the column projection could not split; `_headonly` means the dark torso fell under the key and only the head survived - re-cut those with `--thresh 25`. Raider rows are listed per sprite (B2: labelled rows; B1: 5x16 grid, pitch 28 px, unlabelled). Common enemies (B2) are listed per sprite as `trash_rN_cNN`. Total entries: 343.

```json
[
{"sheet":"B1","section":"Boss Sprites","index":0,"x":544,"y":650,"w":197,"h":160,"proposed_name":"boss_aberration","category":"boss"},
{"sheet":"B1","section":"Boss Sprites","index":1,"x":758,"y":655,"w":111,"h":152,"proposed_name":"boss_stone_brute","category":"boss"},
{"sheet":"B1","section":"Boss Sprites","index":2,"x":850,"y":646,"w":120,"h":155,"proposed_name":"boss_dragon_red","category":"boss"},
{"sheet":"B1","section":"Boss Sprites","index":3,"x":945,"y":660,"w":123,"h":148,"proposed_name":"vehicle_airship_misfiled","category":"vehicle"},
{"sheet":"B1","section":"Animations & Effects","index":0,"x":16,"y":855,"w":35,"h":40,"proposed_name":"vfx_burst_blood","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":1,"x":60,"y":855,"w":51,"h":40,"proposed_name":"vfx_ring_fire+vfx_wisp_fire","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":2,"x":119,"y":846,"w":127,"h":45,"proposed_name":"vfx_comet+vfx_beam_frost+vfx_bolt_fire","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":3,"x":255,"y":848,"w":32,"h":47,"proposed_name":"vfx_orb_arcane","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":4,"x":294,"y":848,"w":62,"h":47,"proposed_name":"vfx_orb_nature+vfx_sparkle_white","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":5,"x":16,"y":895,"w":36,"h":47,"proposed_name":"vfx_vortex_water","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":6,"x":61,"y":895,"w":32,"h":48,"proposed_name":"vfx_flame_tall","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":7,"x":102,"y":901,"w":48,"h":42,"proposed_name":"vfx_starburst_holy","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":8,"x":158,"y":897,"w":54,"h":42,"proposed_name":"vfx_shard_ice_ab","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":9,"x":219,"y":901,"w":33,"h":38,"proposed_name":"vfx_star_shadow","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":10,"x":259,"y":895,"w":19,"h":47,"proposed_name":"vfx_bolt_arcane","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":11,"x":287,"y":895,"w":18,"h":49,"proposed_name":"vfx_bolt_rise","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":12,"x":314,"y":895,"w":39,"h":44,"proposed_name":"vfx_wheel_web","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":13,"x":17,"y":951,"w":46,"h":46,"proposed_name":"vfx_burst_red_ring","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":14,"x":72,"y":952,"w":48,"h":44,"proposed_name":"vfx_ring_venom","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":15,"x":127,"y":946,"w":54,"h":50,"proposed_name":"vfx_explosion_fire","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":16,"x":188,"y":946,"w":52,"h":52,"proposed_name":"vfx_explosion_shadow","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":17,"x":248,"y":951,"w":49,"h":46,"proposed_name":"vfx_ring_void","category":"vfx"},
{"sheet":"B1","section":"Animations & Effects","index":18,"x":306,"y":947,"w":49,"h":50,"proposed_name":"vfx_splash_water","category":"vfx"},
{"sheet":"B1","section":"(unlabelled glyph panel)","index":0,"x":375,"y":856,"w":46,"h":46,"proposed_name":"icon_rune_ring_grey","category":"ui_ornament"},
{"sheet":"B1","section":"(unlabelled glyph panel)","index":1,"x":376,"y":914,"w":43,"h":33,"proposed_name":"icon_sigil_purple","category":"ui_ornament"},
{"sheet":"B1","section":"(unlabelled glyph panel)","index":2,"x":377,"y":964,"w":39,"h":32,"proposed_name":"icon_sigil_green","category":"ui_ornament"},
{"sheet":"B1","section":"Enemies & Monsters","index":0,"x":15,"y":654,"w":22,"h":34,"proposed_name":"enemy_goblin_a","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":1,"x":44,"y":655,"w":21,"h":16,"proposed_name":"enemy_goblin_b_headonly","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":2,"x":74,"y":656,"w":21,"h":18,"proposed_name":"enemy_goblin_c_headonly","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":3,"x":107,"y":657,"w":21,"h":17,"proposed_name":"enemy_goblin_d_headonly","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":4,"x":142,"y":655,"w":17,"h":15,"proposed_name":"enemy_goblin_e_headonly","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":5,"x":181,"y":651,"w":23,"h":43,"proposed_name":"enemy_skeleton_a","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":6,"x":220,"y":651,"w":24,"h":43,"proposed_name":"enemy_skeleton_b","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":7,"x":298,"y":651,"w":21,"h":37,"proposed_name":"enemy_ghoul_a","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":8,"x":329,"y":652,"w":18,"h":36,"proposed_name":"enemy_ghoul_b","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":9,"x":363,"y":655,"w":21,"h":28,"proposed_name":"enemy_ghoul_c","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":10,"x":399,"y":652,"w":23,"h":31,"proposed_name":"enemy_ghoul_blue","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":11,"x":431,"y":651,"w":37,"h":28,"proposed_name":"enemy_imp_red_crawler","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":12,"x":480,"y":655,"w":23,"h":39,"proposed_name":"enemy_ghoul_grey","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":13,"x":17,"y":706,"w":21,"h":27,"proposed_name":"enemy_goblin_grunt_a","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":14,"x":45,"y":707,"w":23,"h":26,"proposed_name":"enemy_goblin_grunt_b","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":15,"x":80,"y":708,"w":17,"h":16,"proposed_name":"enemy_goblin_grunt_c_headonly","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":16,"x":122,"y":707,"w":33,"h":21,"proposed_name":"enemy_spider_black","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":17,"x":175,"y":713,"w":36,"h":36,"proposed_name":"enemy_spider_grey","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":18,"x":228,"y":705,"w":29,"h":28,"proposed_name":"enemy_spider_brown","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":19,"x":267,"y":705,"w":30,"h":35,"proposed_name":"enemy_troll_brown","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":20,"x":329,"y":705,"w":19,"h":23,"proposed_name":"enemy_ghoul_armoured","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":21,"x":366,"y":704,"w":45,"h":38,"proposed_name":"enemy_warrior_dark","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":22,"x":435,"y":701,"w":29,"h":29,"proposed_name":"enemy_brute_pinkmane","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":23,"x":485,"y":709,"w":16,"h":25,"proposed_name":"enemy_beast_redmane_clipped","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":24,"x":24,"y":753,"w":29,"h":48,"proposed_name":"enemy_demon_blue_armoured","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":25,"x":70,"y":755,"w":63,"h":57,"proposed_name":"enemy_ogre_green","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":26,"x":154,"y":771,"w":27,"h":41,"proposed_name":"enemy_imp_pumpkin","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":27,"x":189,"y":771,"w":89,"h":41,"proposed_name":"enemy_beast_purple+beast_lavender","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":28,"x":299,"y":764,"w":39,"h":38,"proposed_name":"enemy_spider_blue","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":29,"x":363,"y":763,"w":59,"h":48,"proposed_name":"enemy_beast_tan","category":"enemy"},
{"sheet":"B1","section":"Enemies & Monsters","index":30,"x":452,"y":761,"w":35,"h":46,"proposed_name":"enemy_eye_horror_purple","category":"enemy"},
{"sheet":"B1","section":"Character Sprites","index":0,"x":249,"y":357,"w":24,"h":41,"proposed_name":"raider_unlabelled_r1_c01","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":1,"x":279,"y":357,"w":22,"h":40,"proposed_name":"raider_unlabelled_r1_c02","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":2,"x":308,"y":358,"w":21,"h":40,"proposed_name":"raider_unlabelled_r1_c03","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":3,"x":337,"y":359,"w":21,"h":39,"proposed_name":"raider_unlabelled_r1_c04","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":4,"x":367,"y":361,"w":15,"h":37,"proposed_name":"raider_unlabelled_r1_c05","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":5,"x":392,"y":360,"w":19,"h":38,"proposed_name":"raider_unlabelled_r1_c06","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":6,"x":418,"y":360,"w":20,"h":38,"proposed_name":"raider_unlabelled_r1_c07","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":7,"x":445,"y":358,"w":25,"h":40,"proposed_name":"raider_unlabelled_r1_c08","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":8,"x":476,"y":358,"w":24,"h":40,"proposed_name":"raider_unlabelled_r1_c09","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":9,"x":505,"y":359,"w":22,"h":39,"proposed_name":"raider_unlabelled_r1_c10","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":10,"x":533,"y":358,"w":21,"h":40,"proposed_name":"raider_unlabelled_r1_c11","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":11,"x":561,"y":353,"w":21,"h":45,"proposed_name":"raider_unlabelled_r1_c12","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":12,"x":589,"y":358,"w":21,"h":40,"proposed_name":"raider_unlabelled_r1_c13","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":13,"x":616,"y":356,"w":21,"h":41,"proposed_name":"raider_unlabelled_r1_c14","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":14,"x":644,"y":359,"w":18,"h":38,"proposed_name":"raider_unlabelled_r1_c15","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":15,"x":669,"y":359,"w":19,"h":39,"proposed_name":"raider_unlabelled_r1_c16","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":16,"x":250,"y":407,"w":23,"h":39,"proposed_name":"raider_unlabelled_r2_c01","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":17,"x":280,"y":408,"w":19,"h":38,"proposed_name":"raider_unlabelled_r2_c02","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":18,"x":308,"y":408,"w":21,"h":38,"proposed_name":"raider_unlabelled_r2_c03","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":19,"x":337,"y":407,"w":21,"h":39,"proposed_name":"raider_unlabelled_r2_c04","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":20,"x":367,"y":411,"w":16,"h":35,"proposed_name":"raider_unlabelled_r2_c05","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":21,"x":392,"y":408,"w":19,"h":38,"proposed_name":"raider_unlabelled_r2_c06","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":22,"x":418,"y":407,"w":21,"h":39,"proposed_name":"raider_unlabelled_r2_c07","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":23,"x":446,"y":406,"w":24,"h":40,"proposed_name":"raider_unlabelled_r2_c08","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":24,"x":476,"y":406,"w":23,"h":40,"proposed_name":"raider_unlabelled_r2_c09","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":25,"x":505,"y":407,"w":22,"h":39,"proposed_name":"raider_unlabelled_r2_c10","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":26,"x":532,"y":407,"w":23,"h":39,"proposed_name":"raider_unlabelled_r2_c11","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":27,"x":561,"y":401,"w":22,"h":45,"proposed_name":"raider_unlabelled_r2_c12","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":28,"x":589,"y":405,"w":21,"h":41,"proposed_name":"raider_unlabelled_r2_c13","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":29,"x":617,"y":407,"w":20,"h":39,"proposed_name":"raider_unlabelled_r2_c14","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":30,"x":642,"y":406,"w":21,"h":40,"proposed_name":"raider_unlabelled_r2_c15","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":31,"x":668,"y":407,"w":20,"h":39,"proposed_name":"raider_unlabelled_r2_c16","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":32,"x":248,"y":455,"w":25,"h":43,"proposed_name":"raider_unlabelled_r3_c01","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":33,"x":278,"y":453,"w":24,"h":45,"proposed_name":"raider_unlabelled_r3_c02","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":34,"x":307,"y":454,"w":23,"h":44,"proposed_name":"raider_unlabelled_r3_c03","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":35,"x":337,"y":454,"w":23,"h":43,"proposed_name":"raider_unlabelled_r3_c04","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":36,"x":366,"y":459,"w":17,"h":39,"proposed_name":"raider_unlabelled_r3_c05","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":37,"x":389,"y":455,"w":23,"h":42,"proposed_name":"raider_unlabelled_r3_c06","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":38,"x":416,"y":454,"w":24,"h":43,"proposed_name":"raider_unlabelled_r3_c07","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":39,"x":447,"y":455,"w":22,"h":43,"proposed_name":"raider_unlabelled_r3_c08","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":40,"x":475,"y":454,"w":23,"h":43,"proposed_name":"raider_unlabelled_r3_c09","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":41,"x":504,"y":453,"w":23,"h":45,"proposed_name":"raider_unlabelled_r3_c10","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":42,"x":533,"y":455,"w":21,"h":42,"proposed_name":"raider_unlabelled_r3_c11","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":43,"x":560,"y":455,"w":22,"h":43,"proposed_name":"raider_unlabelled_r3_c12","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":44,"x":590,"y":455,"w":19,"h":42,"proposed_name":"raider_unlabelled_r3_c13","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":45,"x":616,"y":455,"w":21,"h":43,"proposed_name":"raider_unlabelled_r3_c14","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":46,"x":643,"y":455,"w":19,"h":43,"proposed_name":"raider_unlabelled_r3_c15","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":47,"x":668,"y":456,"w":19,"h":42,"proposed_name":"raider_unlabelled_r3_c16","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":48,"x":248,"y":509,"w":25,"h":41,"proposed_name":"raider_unlabelled_r4_c01","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":49,"x":279,"y":510,"w":21,"h":40,"proposed_name":"raider_unlabelled_r4_c02","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":50,"x":308,"y":510,"w":21,"h":40,"proposed_name":"raider_unlabelled_r4_c03","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":51,"x":339,"y":510,"w":19,"h":40,"proposed_name":"raider_unlabelled_r4_c04","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":52,"x":368,"y":510,"w":16,"h":40,"proposed_name":"raider_unlabelled_r4_c05","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":53,"x":394,"y":510,"w":21,"h":40,"proposed_name":"raider_unlabelled_r4_c06","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":54,"x":423,"y":511,"w":17,"h":39,"proposed_name":"raider_unlabelled_r4_c07","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":55,"x":448,"y":509,"w":22,"h":41,"proposed_name":"raider_unlabelled_r4_c08","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":56,"x":477,"y":509,"w":19,"h":41,"proposed_name":"raider_unlabelled_r4_c09","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":57,"x":504,"y":509,"w":20,"h":41,"proposed_name":"raider_unlabelled_r4_c10","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":58,"x":532,"y":508,"w":22,"h":42,"proposed_name":"raider_unlabelled_r4_c11","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":59,"x":562,"y":509,"w":17,"h":41,"proposed_name":"raider_unlabelled_r4_c12","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":60,"x":587,"y":510,"w":19,"h":40,"proposed_name":"raider_unlabelled_r4_c13","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":61,"x":614,"y":510,"w":19,"h":40,"proposed_name":"raider_unlabelled_r4_c14","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":62,"x":640,"y":509,"w":19,"h":41,"proposed_name":"raider_unlabelled_r4_c15","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":63,"x":666,"y":509,"w":19,"h":41,"proposed_name":"raider_unlabelled_r4_c16","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":64,"x":249,"y":560,"w":23,"h":41,"proposed_name":"raider_unlabelled_r5_c01","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":65,"x":279,"y":560,"w":20,"h":42,"proposed_name":"raider_unlabelled_r5_c02","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":66,"x":309,"y":559,"w":20,"h":43,"proposed_name":"raider_unlabelled_r5_c03","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":67,"x":338,"y":560,"w":20,"h":42,"proposed_name":"raider_unlabelled_r5_c04","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":68,"x":367,"y":559,"w":18,"h":42,"proposed_name":"raider_unlabelled_r5_c05","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":69,"x":394,"y":560,"w":21,"h":42,"proposed_name":"raider_unlabelled_r5_c06","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":70,"x":422,"y":560,"w":18,"h":42,"proposed_name":"raider_unlabelled_r5_c07","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":71,"x":447,"y":559,"w":21,"h":43,"proposed_name":"raider_unlabelled_r5_c08","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":72,"x":475,"y":559,"w":21,"h":43,"proposed_name":"raider_unlabelled_r5_c09","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":73,"x":504,"y":560,"w":20,"h":42,"proposed_name":"raider_unlabelled_r5_c10","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":74,"x":531,"y":558,"w":23,"h":44,"proposed_name":"raider_unlabelled_r5_c11","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":75,"x":560,"y":559,"w":18,"h":42,"proposed_name":"raider_unlabelled_r5_c12","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":76,"x":585,"y":556,"w":22,"h":46,"proposed_name":"raider_unlabelled_r5_c13","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":77,"x":613,"y":559,"w":20,"h":43,"proposed_name":"raider_unlabelled_r5_c14","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":78,"x":640,"y":560,"w":19,"h":41,"proposed_name":"raider_unlabelled_r5_c15","category":"raider"},
{"sheet":"B1","section":"Character Sprites","index":79,"x":667,"y":559,"w":18,"h":42,"proposed_name":"raider_unlabelled_r5_c16","category":"raider"},
{"sheet":"B1","section":"Misc / Utilities","index":0,"x":447,"y":856,"w":28,"h":62,"proposed_name":"banner_skull_red_large","category":"ui_ornament"},
{"sheet":"B1","section":"Misc / Utilities","index":1,"x":477,"y":863,"w":20,"h":41,"proposed_name":"banner_skull_red_small","category":"ui_ornament"},
{"sheet":"B1","section":"Misc / Utilities","index":2,"x":507,"y":860,"w":16,"h":44,"proposed_name":"torch_lit_standing","category":"ui_ornament"},
{"sheet":"B1","section":"Misc / Utilities","index":3,"x":530,"y":857,"w":15,"h":32,"proposed_name":"pennant_skull_red","category":"ui_ornament"},
{"sheet":"B1","section":"Misc / Utilities","index":4,"x":552,"y":856,"w":40,"h":48,"proposed_name":"frame_scaffold_wood","category":"ui_ornament"},
{"sheet":"B1","section":"Misc / Utilities","index":5,"x":599,"y":856,"w":28,"h":38,"proposed_name":"frame_wood_wheel","category":"ui_ornament"},
{"sheet":"B1","section":"Misc / Utilities","index":6,"x":634,"y":856,"w":22,"h":47,"proposed_name":"banner_pole_narrow","category":"ui_ornament"},
{"sheet":"B1","section":"Props & Interactables","index":0,"x":1023,"y":58,"w":49,"h":92,"proposed_name":"brazier_flaming_tall","category":"ui_ornament"},
{"sheet":"B1","section":"Props & Interactables","index":1,"x":1025,"y":213,"w":44,"h":96,"proposed_name":"banner_skull_purple_tall","category":"ui_ornament"},
{"sheet":"B1","section":"Props & Interactables","index":2,"x":993,"y":209,"w":19,"h":56,"proposed_name":"banner_skull_red_pole","category":"ui_ornament"},
{"sheet":"B1","section":"Props & Interactables","index":3,"x":914,"y":227,"w":19,"h":52,"proposed_name":"torch_lit_pole","category":"ui_ornament"},
{"sheet":"B1","section":"Props & Interactables","index":4,"x":1000,"y":272,"w":21,"h":37,"proposed_name":"signboard_post","category":"prop"},
{"sheet":"B1","section":"Props & Interactables","index":5,"x":1001,"y":106,"w":16,"h":31,"proposed_name":"candlestand_a","category":"prop"},
{"sheet":"B1","section":"Props & Interactables","index":6,"x":1025,"y":110,"w":15,"h":40,"proposed_name":"candlestand_b","category":"prop"},
{"sheet":"B1","section":"Structures & Buildings","index":0,"x":752,"y":27,"w":34,"h":63,"proposed_name":"banner_skull_red_on_pole","category":"ui_ornament"},
{"sheet":"B1","section":"Structures & Buildings","index":1,"x":796,"y":68,"w":45,"h":83,"proposed_name":"totem_skull_wreath_banner","category":"ui_ornament"},
{"sheet":"B1","section":"Structures & Buildings","index":2,"x":751,"y":228,"w":46,"h":81,"proposed_name":"tower_round_skull_banners","category":"ui_ornament"},
{"sheet":"B1","section":"Structures & Buildings","index":3,"x":749,"y":128,"w":31,"h":51,"proposed_name":"tower_conical_blue","category":"prop"},
{"sheet":"B1","section":"Structures & Buildings","index":4,"x":820,"y":215,"w":19,"h":29,"proposed_name":"signboard_a","category":"prop"},
{"sheet":"B1","section":"Structures & Buildings","index":5,"x":803,"y":252,"w":18,"h":23,"proposed_name":"signboard_b","category":"prop"},
{"sheet":"B1","section":"Structures & Buildings","index":6,"x":822,"y":254,"w":19,"h":20,"proposed_name":"signboard_c","category":"prop"},
{"sheet":"B2","section":"Enemies & Bosses / Bosses","index":0,"x":373,"y":385,"w":83,"h":81,"proposed_name":"boss_flame_brute","category":"boss"},
{"sheet":"B2","section":"Enemies & Bosses / Bosses","index":1,"x":469,"y":385,"w":103,"h":93,"proposed_name":"boss_spiked_crawler","category":"boss"},
{"sheet":"B2","section":"Enemies & Bosses / Bosses","index":2,"x":583,"y":385,"w":147,"h":92,"proposed_name":"boss_aberration","category":"boss"},
{"sheet":"B2","section":"Enemies & Bosses / Bosses","index":3,"x":377,"y":462,"w":117,"h":140,"proposed_name":"boss_moss_golem","category":"boss"},
{"sheet":"B2","section":"Enemies & Bosses / Bosses","index":4,"x":496,"y":491,"w":107,"h":114,"proposed_name":"boss_iron_golem","category":"boss"},
{"sheet":"B2","section":"Enemies & Bosses / Bosses","index":5,"x":597,"y":485,"w":143,"h":121,"proposed_name":"boss_dragon","category":"boss"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":0,"x":371,"y":231,"w":55,"h":59,"proposed_name":"elite_horned_warrior","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":1,"x":433,"y":229,"w":53,"h":64,"proposed_name":"elite_bull_brute","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":2,"x":492,"y":238,"w":26,"h":57,"proposed_name":"elite_rogue_dark","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":3,"x":527,"y":231,"w":54,"h":58,"proposed_name":"elite_knight_blue","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":4,"x":583,"y":230,"w":39,"h":65,"proposed_name":"elite_swordsman_white","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":5,"x":629,"y":230,"w":27,"h":59,"proposed_name":"elite_dancer_red","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":6,"x":662,"y":239,"w":25,"h":50,"proposed_name":"elite_imp_purple","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":7,"x":693,"y":232,"w":41,"h":56,"proposed_name":"elite_archer_dark","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":8,"x":372,"y":302,"w":40,"h":71,"proposed_name":"elite_mage_grey","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":9,"x":419,"y":299,"w":45,"h":57,"proposed_name":"elite_armoured_green","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":10,"x":472,"y":297,"w":48,"h":63,"proposed_name":"elite_werewolf","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":11,"x":526,"y":297,"w":36,"h":60,"proposed_name":"elite_sorcerer_white","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":12,"x":568,"y":295,"w":43,"h":60,"proposed_name":"elite_demon_staff","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":13,"x":616,"y":297,"w":32,"h":59,"proposed_name":"elite_rogue_redhood","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":14,"x":656,"y":297,"w":46,"h":62,"proposed_name":"elite_brute_redhair","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Elite Enemies","index":15,"x":704,"y":295,"w":33,"h":60,"proposed_name":"elite_witch_purple","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":0,"x":373,"y":58,"w":24,"h":27,"proposed_name":"trash_r1_c01","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":1,"x":401,"y":51,"w":20,"h":37,"proposed_name":"trash_r1_c02","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":2,"x":427,"y":58,"w":20,"h":27,"proposed_name":"trash_r1_c03","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":3,"x":453,"y":58,"w":20,"h":27,"proposed_name":"trash_r1_c04","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":4,"x":479,"y":56,"w":19,"h":29,"proposed_name":"trash_r1_c05","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":5,"x":503,"y":58,"w":20,"h":30,"proposed_name":"trash_r1_c06","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":6,"x":529,"y":56,"w":21,"h":29,"proposed_name":"trash_r1_c07","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":7,"x":556,"y":55,"w":21,"h":33,"proposed_name":"trash_r1_c08","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":8,"x":579,"y":58,"w":22,"h":27,"proposed_name":"trash_r1_c09","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":9,"x":604,"y":53,"w":23,"h":32,"proposed_name":"trash_r1_c10","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":10,"x":629,"y":58,"w":21,"h":30,"proposed_name":"trash_r1_c11","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":11,"x":655,"y":58,"w":20,"h":27,"proposed_name":"trash_r1_c12","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":12,"x":681,"y":58,"w":18,"h":32,"proposed_name":"trash_r1_c13","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":13,"x":707,"y":59,"w":21,"h":26,"proposed_name":"trash_r1_c14","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":14,"x":375,"y":94,"w":20,"h":28,"proposed_name":"trash_r2_c01","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":15,"x":398,"y":90,"w":15,"h":35,"proposed_name":"trash_r2_c02","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":16,"x":418,"y":95,"w":16,"h":27,"proposed_name":"trash_r2_c03","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":17,"x":439,"y":95,"w":22,"h":26,"proposed_name":"trash_r2_c04","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":18,"x":463,"y":95,"w":21,"h":31,"proposed_name":"trash_r2_c05","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":19,"x":486,"y":90,"w":19,"h":36,"proposed_name":"trash_r2_c06","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":20,"x":511,"y":95,"w":21,"h":33,"proposed_name":"trash_r2_c07","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":21,"x":536,"y":90,"w":21,"h":38,"proposed_name":"trash_r2_c08","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":22,"x":565,"y":94,"w":31,"h":31,"proposed_name":"trash_r2_c09","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":23,"x":599,"y":94,"w":23,"h":34,"proposed_name":"trash_r2_c10","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":24,"x":624,"y":91,"w":18,"h":34,"proposed_name":"trash_r2_c11","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":25,"x":648,"y":94,"w":21,"h":28,"proposed_name":"trash_r2_c12","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":26,"x":674,"y":97,"w":28,"h":31,"proposed_name":"trash_r2_c13","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":27,"x":711,"y":97,"w":23,"h":30,"proposed_name":"trash_r2_c14","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":28,"x":373,"y":132,"w":23,"h":31,"proposed_name":"trash_r3_c01","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":29,"x":401,"y":128,"w":17,"h":31,"proposed_name":"trash_r3_c02","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":30,"x":423,"y":132,"w":19,"h":27,"proposed_name":"trash_r3_c03","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":31,"x":446,"y":132,"w":44,"h":30,"proposed_name":"trash_r3_c04","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":32,"x":494,"y":128,"w":24,"h":31,"proposed_name":"trash_r3_c05","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":33,"x":523,"y":131,"w":19,"h":28,"proposed_name":"trash_r3_c06","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":34,"x":549,"y":131,"w":22,"h":28,"proposed_name":"trash_r3_c07","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":35,"x":578,"y":131,"w":24,"h":32,"proposed_name":"trash_r3_c08","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":36,"x":606,"y":128,"w":21,"h":31,"proposed_name":"trash_r3_c09","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":37,"x":631,"y":131,"w":22,"h":28,"proposed_name":"trash_r3_c10","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":38,"x":658,"y":130,"w":23,"h":31,"proposed_name":"trash_r3_c11","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":39,"x":687,"y":129,"w":25,"h":31,"proposed_name":"trash_r3_c12","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":40,"x":717,"y":131,"w":25,"h":32,"proposed_name":"trash_r3_c13","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":41,"x":373,"y":165,"w":24,"h":33,"proposed_name":"trash_r4_c01","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":42,"x":401,"y":167,"w":26,"h":35,"proposed_name":"trash_r4_c02","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":43,"x":433,"y":165,"w":24,"h":34,"proposed_name":"trash_r4_c03","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":44,"x":460,"y":166,"w":26,"h":36,"proposed_name":"trash_r4_c04","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":45,"x":492,"y":166,"w":45,"h":32,"proposed_name":"trash_r4_c05","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":46,"x":539,"y":163,"w":30,"h":39,"proposed_name":"trash_r4_c06","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":47,"x":577,"y":165,"w":24,"h":33,"proposed_name":"trash_r4_c07","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":48,"x":605,"y":167,"w":23,"h":34,"proposed_name":"trash_r4_c08","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":49,"x":633,"y":163,"w":49,"h":35,"proposed_name":"trash_r4_c09","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":50,"x":687,"y":163,"w":22,"h":37,"proposed_name":"trash_r4_c10","category":"enemy"},
{"sheet":"B2","section":"Enemies & Bosses / Common Enemies","index":51,"x":714,"y":163,"w":23,"h":35,"proposed_name":"trash_r4_c11","category":"enemy"},
{"sheet":"B2","section":"Characters - Raiders / Warrior","index":0,"x":51,"y":37,"w":55,"h":43,"proposed_name":"raider_warrior_01_MERGED","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Warrior","index":1,"x":108,"y":33,"w":75,"h":45,"proposed_name":"raider_warrior_02_MERGED","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Warrior","index":2,"x":185,"y":37,"w":24,"h":41,"proposed_name":"raider_warrior_03","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Warrior","index":3,"x":211,"y":33,"w":22,"h":46,"proposed_name":"raider_warrior_04","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Warrior","index":4,"x":235,"y":39,"w":25,"h":37,"proposed_name":"raider_warrior_05","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Warrior","index":5,"x":263,"y":39,"w":22,"h":37,"proposed_name":"raider_warrior_06","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Warrior","index":6,"x":288,"y":30,"w":24,"h":50,"proposed_name":"raider_warrior_07","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Warrior","index":7,"x":317,"y":37,"w":30,"h":43,"proposed_name":"raider_warrior_08","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Rogue","index":0,"x":52,"y":85,"w":26,"h":43,"proposed_name":"raider_rogue_01","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Rogue","index":1,"x":82,"y":90,"w":23,"h":42,"proposed_name":"raider_rogue_02","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Rogue","index":2,"x":108,"y":89,"w":46,"h":41,"proposed_name":"raider_rogue_03_MERGED","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Rogue","index":3,"x":159,"y":91,"w":23,"h":35,"proposed_name":"raider_rogue_04","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Rogue","index":4,"x":188,"y":92,"w":18,"h":35,"proposed_name":"raider_rogue_05","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Rogue","index":5,"x":212,"y":92,"w":19,"h":35,"proposed_name":"raider_rogue_06","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Rogue","index":6,"x":237,"y":91,"w":21,"h":36,"proposed_name":"raider_rogue_07","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Rogue","index":7,"x":265,"y":90,"w":20,"h":37,"proposed_name":"raider_rogue_08","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Rogue","index":8,"x":292,"y":85,"w":20,"h":42,"proposed_name":"raider_rogue_09","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Rogue","index":9,"x":319,"y":89,"w":29,"h":38,"proposed_name":"raider_rogue_10","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Mage","index":0,"x":51,"y":140,"w":26,"h":43,"proposed_name":"raider_mage_01","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Mage","index":1,"x":82,"y":141,"w":24,"h":37,"proposed_name":"raider_mage_02","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Mage","index":2,"x":108,"y":137,"w":45,"h":41,"proposed_name":"raider_mage_03_MERGED","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Mage","index":3,"x":159,"y":137,"w":22,"h":41,"proposed_name":"raider_mage_04","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Mage","index":4,"x":186,"y":142,"w":22,"h":36,"proposed_name":"raider_mage_05","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Mage","index":5,"x":212,"y":142,"w":19,"h":36,"proposed_name":"raider_mage_06","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Mage","index":6,"x":236,"y":141,"w":22,"h":37,"proposed_name":"raider_mage_07","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Mage","index":7,"x":263,"y":141,"w":21,"h":37,"proposed_name":"raider_mage_08","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Mage","index":8,"x":289,"y":137,"w":23,"h":41,"proposed_name":"raider_mage_09","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Mage","index":9,"x":316,"y":142,"w":33,"h":36,"proposed_name":"raider_mage_10","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Cleric","index":0,"x":51,"y":191,"w":27,"h":38,"proposed_name":"raider_cleric_01","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Cleric","index":1,"x":81,"y":191,"w":24,"h":43,"proposed_name":"raider_cleric_02","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Cleric","index":2,"x":108,"y":191,"w":50,"h":43,"proposed_name":"raider_cleric_03_MERGED","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Cleric","index":3,"x":162,"y":193,"w":46,"h":36,"proposed_name":"raider_cleric_04_MERGED","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Cleric","index":4,"x":211,"y":193,"w":23,"h":40,"proposed_name":"raider_cleric_05","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Cleric","index":5,"x":240,"y":193,"w":18,"h":36,"proposed_name":"raider_cleric_06","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Cleric","index":6,"x":265,"y":188,"w":22,"h":42,"proposed_name":"raider_cleric_07","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Cleric","index":7,"x":292,"y":192,"w":22,"h":37,"proposed_name":"raider_cleric_08","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Cleric","index":8,"x":316,"y":192,"w":32,"h":37,"proposed_name":"raider_cleric_09","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Ranger","index":0,"x":51,"y":244,"w":24,"h":38,"proposed_name":"raider_ranger_NONCANON_as_rogue_variant_01","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Ranger","index":1,"x":82,"y":241,"w":100,"h":49,"proposed_name":"raider_ranger_NONCANON_as_rogue_variant_02_MERGED","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Ranger","index":2,"x":186,"y":247,"w":21,"h":41,"proposed_name":"raider_ranger_NONCANON_as_rogue_variant_03","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Ranger","index":3,"x":212,"y":247,"w":19,"h":35,"proposed_name":"raider_ranger_NONCANON_as_rogue_variant_04","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Ranger","index":4,"x":241,"y":246,"w":16,"h":36,"proposed_name":"raider_ranger_NONCANON_as_rogue_variant_05","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Ranger","index":5,"x":265,"y":246,"w":19,"h":36,"proposed_name":"raider_ranger_NONCANON_as_rogue_variant_06","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Ranger","index":6,"x":290,"y":243,"w":22,"h":47,"proposed_name":"raider_ranger_NONCANON_as_rogue_variant_07","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Ranger","index":7,"x":317,"y":246,"w":26,"h":36,"proposed_name":"raider_ranger_NONCANON_as_rogue_variant_08","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Berserker","index":0,"x":53,"y":296,"w":25,"h":42,"proposed_name":"raider_berserker_NONCANON_as_warrior_monk_variant_01","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Berserker","index":1,"x":81,"y":294,"w":25,"h":50,"proposed_name":"raider_berserker_NONCANON_as_warrior_monk_variant_02","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Berserker","index":2,"x":112,"y":294,"w":42,"h":41,"proposed_name":"raider_berserker_NONCANON_as_warrior_monk_variant_03_MERGED","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Berserker","index":3,"x":163,"y":297,"w":19,"h":38,"proposed_name":"raider_berserker_NONCANON_as_warrior_monk_variant_04","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Berserker","index":4,"x":185,"y":293,"w":21,"h":42,"proposed_name":"raider_berserker_NONCANON_as_warrior_monk_variant_05","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Berserker","index":5,"x":213,"y":293,"w":20,"h":42,"proposed_name":"raider_berserker_NONCANON_as_warrior_monk_variant_06","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Berserker","index":6,"x":243,"y":298,"w":16,"h":37,"proposed_name":"raider_berserker_NONCANON_as_warrior_monk_variant_07","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Berserker","index":7,"x":269,"y":297,"w":17,"h":38,"proposed_name":"raider_berserker_NONCANON_as_warrior_monk_variant_08","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Berserker","index":8,"x":292,"y":297,"w":20,"h":38,"proposed_name":"raider_berserker_NONCANON_as_warrior_monk_variant_09","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Berserker","index":9,"x":318,"y":298,"w":29,"h":35,"proposed_name":"raider_berserker_NONCANON_as_warrior_monk_variant_10","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Druid","index":0,"x":53,"y":352,"w":23,"h":39,"proposed_name":"raider_druid_01","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Druid","index":1,"x":81,"y":347,"w":28,"h":45,"proposed_name":"raider_druid_02","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Druid","index":2,"x":112,"y":351,"w":43,"h":40,"proposed_name":"raider_druid_03_MERGED","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Druid","index":3,"x":162,"y":353,"w":19,"h":38,"proposed_name":"raider_druid_04","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Druid","index":4,"x":189,"y":355,"w":19,"h":36,"proposed_name":"raider_druid_05","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Druid","index":5,"x":211,"y":354,"w":22,"h":37,"proposed_name":"raider_druid_06","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Druid","index":6,"x":242,"y":348,"w":16,"h":47,"proposed_name":"raider_druid_07","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Druid","index":7,"x":266,"y":352,"w":18,"h":39,"proposed_name":"raider_druid_08","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Druid","index":8,"x":291,"y":354,"w":25,"h":37,"proposed_name":"raider_druid_09","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Druid","index":9,"x":321,"y":354,"w":23,"h":40,"proposed_name":"raider_druid_10","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Engineer","index":0,"x":52,"y":401,"w":27,"h":45,"proposed_name":"raider_engineer_NONCANON_unused_01","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Engineer","index":1,"x":83,"y":404,"w":25,"h":42,"proposed_name":"raider_engineer_NONCANON_unused_02","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Engineer","index":2,"x":111,"y":404,"w":46,"h":42,"proposed_name":"raider_engineer_NONCANON_unused_03_MERGED","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Engineer","index":3,"x":163,"y":405,"w":19,"h":40,"proposed_name":"raider_engineer_NONCANON_unused_04","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Engineer","index":4,"x":184,"y":409,"w":26,"h":36,"proposed_name":"raider_engineer_NONCANON_unused_05","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Engineer","index":5,"x":213,"y":409,"w":20,"h":36,"proposed_name":"raider_engineer_NONCANON_unused_06","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Engineer","index":6,"x":242,"y":409,"w":18,"h":37,"proposed_name":"raider_engineer_NONCANON_unused_07","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Engineer","index":7,"x":266,"y":409,"w":20,"h":37,"proposed_name":"raider_engineer_NONCANON_unused_08","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Engineer","index":8,"x":288,"y":405,"w":24,"h":40,"proposed_name":"raider_engineer_NONCANON_unused_09","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Engineer","index":9,"x":315,"y":409,"w":30,"h":37,"proposed_name":"raider_engineer_NONCANON_unused_10","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r1","index":0,"x":57,"y":501,"w":18,"h":34,"proposed_name":"raider_variant_r1_01","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r1","index":1,"x":83,"y":500,"w":18,"h":36,"proposed_name":"raider_variant_r1_02","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r1","index":2,"x":105,"y":507,"w":16,"h":28,"proposed_name":"raider_variant_r1_03","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r1","index":3,"x":127,"y":495,"w":19,"h":40,"proposed_name":"raider_variant_r1_04","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r1","index":4,"x":150,"y":499,"w":22,"h":36,"proposed_name":"raider_variant_r1_05","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r1","index":5,"x":180,"y":500,"w":41,"h":40,"proposed_name":"raider_variant_r1_06_MERGED","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r1","index":6,"x":223,"y":500,"w":23,"h":34,"proposed_name":"raider_variant_r1_07","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r1","index":7,"x":249,"y":500,"w":21,"h":35,"proposed_name":"raider_variant_r1_08","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r1","index":8,"x":278,"y":501,"w":19,"h":37,"proposed_name":"raider_variant_r1_09","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r1","index":9,"x":303,"y":501,"w":18,"h":35,"proposed_name":"raider_variant_r1_10","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r1","index":10,"x":326,"y":497,"w":23,"h":39,"proposed_name":"raider_variant_r1_11","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r2","index":0,"x":57,"y":541,"w":18,"h":40,"proposed_name":"raider_variant_r2_01","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r2","index":1,"x":81,"y":546,"w":20,"h":38,"proposed_name":"raider_variant_r2_02","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r2","index":2,"x":106,"y":546,"w":19,"h":36,"proposed_name":"raider_variant_r2_03","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r2","index":3,"x":130,"y":546,"w":18,"h":35,"proposed_name":"raider_variant_r2_04","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r2","index":4,"x":155,"y":543,"w":20,"h":37,"proposed_name":"raider_variant_r2_05","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r2","index":5,"x":179,"y":546,"w":19,"h":34,"proposed_name":"raider_variant_r2_06","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r2","index":6,"x":203,"y":546,"w":20,"h":35,"proposed_name":"raider_variant_r2_07","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r2","index":7,"x":230,"y":546,"w":17,"h":35,"proposed_name":"raider_variant_r2_08","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r2","index":8,"x":249,"y":546,"w":23,"h":35,"proposed_name":"raider_variant_r2_09","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r2","index":9,"x":274,"y":542,"w":24,"h":39,"proposed_name":"raider_variant_r2_10","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r2","index":10,"x":302,"y":545,"w":20,"h":36,"proposed_name":"raider_variant_r2_11","category":"raider"},
{"sheet":"B2","section":"Characters - Raiders / Raider Variants r2","index":11,"x":324,"y":544,"w":26,"h":39,"proposed_name":"raider_variant_r2_12","category":"raider"},
{"sheet":"B2","section":"Props & Interactive Objects","index":0,"x":805,"y":102,"w":39,"h":76,"proposed_name":"banner_skull_red_pole","category":"ui_ornament"},
{"sheet":"B2","section":"Props & Interactive Objects","index":1,"x":958,"y":239,"w":31,"h":69,"proposed_name":"banner_navy_gold_sigil","category":"ui_ornament"},
{"sheet":"B2","section":"Props & Interactive Objects","index":2,"x":836,"y":359,"w":20,"h":83,"proposed_name":"banner_purple_tall_narrow","category":"ui_ornament"},
{"sheet":"B2","section":"Props & Interactive Objects","index":3,"x":860,"y":308,"w":33,"h":56,"proposed_name":"pennant_skull_red","category":"ui_ornament"},
{"sheet":"B2","section":"Props & Interactive Objects","index":4,"x":819,"y":458,"w":23,"h":71,"proposed_name":"banner_skull_red_pole_b","category":"ui_ornament"},
{"sheet":"B2","section":"Props & Interactive Objects","index":5,"x":932,"y":537,"w":26,"h":67,"proposed_name":"banner_skull_red_c","category":"ui_ornament"},
{"sheet":"B2","section":"Props & Interactive Objects","index":6,"x":927,"y":484,"w":29,"h":46,"proposed_name":"banner_navy_small","category":"ui_ornament"},
{"sheet":"B2","section":"Props & Interactive Objects","index":7,"x":962,"y":485,"w":26,"h":45,"proposed_name":"banner_red_gold_small","category":"ui_ornament"},
{"sheet":"B2","section":"Props & Interactive Objects","index":8,"x":815,"y":570,"w":25,"h":46,"proposed_name":"banner_skull_red_small","category":"ui_ornament"},
{"sheet":"B2","section":"Props & Interactive Objects","index":9,"x":843,"y":447,"w":35,"h":55,"proposed_name":"frame_gallows_chain","category":"ui_ornament"},
{"sheet":"B2","section":"Props & Interactive Objects","index":10,"x":830,"y":68,"w":18,"h":32,"proposed_name":"lantern_post_a","category":"ui_ornament"},
{"sheet":"B2","section":"Props & Interactive Objects","index":11,"x":858,"y":69,"w":19,"h":30,"proposed_name":"lantern_post_b","category":"ui_ornament"},
{"sheet":"B2","section":"Props & Interactive Objects","index":12,"x":766,"y":390,"w":20,"h":45,"proposed_name":"signpost_or_banner_verify","category":"ui_ornament"}
]
```

## 4. Bosses + VFX in detail

### 4.0 B1 "Boss Sprites" (panel 9)

Islands via `slice.py islands --key dark --thresh 35 --min-area 200` on region `522,640,554,182` → 23 fragments (dark armour/shadow splits every boss); re-grouped by hand into four bodies. The dragon and the brute overlap in x (dragon's left wing tip at x 850–894, y 646–694 sits over the brute's shoulder line but does not touch it — separate components), so a per-column projection cannot split them; the boxes below are unions of the assigned fragments.

| Boss | x | y | w | h | Dominant ramp (lum>45, 20-step quantised) | Read |
|---|---|---|---|---|---|---|
| Aberration (eye + tentacles) | 544 | 650 | 197 | 160 | `#1E1E5A #321E5A #321E46 #461E5A #1E326E` — indigo/violet body, magenta tentacle tips, `#FF3C5A`-class red highlights, single amber-cored eye at ≈(686,715) | The "Sludge Maw — Aberration" of Concept 2. The **largest single boss render on any sheet**; colourway (blue-violet + red) is the closest to the concept. |
| Stone/earth brute | 758 | 655 | 111 | 152 | `#323232 #463232 #464632 #5A4646 #5A3232` — warm grey-brown rock, moss-green crown, bare face | Hunched biped, left arm down. Equivalent to A1's crystal golem / A2's "Stone Golem". |
| Red dragon | 850 | 646 | 120 | 155 | dark maroon `#3C1420`-class body, `#8C2C2C` membranes, orange belly flame | Wings spread, facing left-down; tail curls to x≈872–937 y 745–790. 22 fragments at `--min-area 30` (region `845,640,125,175`), the lower ones were being lost at min-area 200. |
| Airship *(not a boss — misfiled by the generator)* | 945 | 660 | 123 | 148 | `#323232 #463232 #464646 #323246` grey-brown hull, cream balloon | Duplicate of Vehicles panel content. Do not harvest as a boss. |

### 4.1 B1 "Animations & Effects" (panel 10)

Islands via `--key dark --thresh 35 --min-area 60` on region `10,846,352,162` → 27 fragments, then a per-row column projection (gap 3) with row bands y 846–895 / 895–944 / 944–1008 → **19 effects**. All are **standalone single frames**: no island repeats a silhouette in a horizontal sequence, so nothing here is an animation strip despite the panel title. Because the ground is `#010F19` (lum ≈ 10) every effect can be used **unkeyed with `CanvasItem.blend_mode = ADD`** — the near-black ground contributes ~4 % brightness — which preserves the glow falloff that white/checker keying destroys on A2 and B2.

| # | x | y | w | h | Shape | Ramp (lum>45, quantised) | Proposed name |
|---|---|---|---|---|---|---|---|
| v01 | 16 | 855 | 35 | 40 | vertical crystal/ember burst | `#540C24 → #840C24 → #9C2424` deep red | `vfx_burst_blood` |
| v02 | 60 | 855 | 51 | 40 | **two effects merged**: orange ring (x 60–85) + curling flame wisp (x 88–111) | `#54240C → #B45424 → #E48424 → #FCCC54` | `vfx_ring_fire`, `vfx_wisp_fire` |
| v03 | 119 | 846 | 127 | 45 | **three merged**: red/cyan comet streak (top, x≈150–235, y 846–860), cyan horizontal beam with orb head (x 119–190, y 860–890), orange arrow bolt (x≈190–245, y 875–890) | `#0C3C54 → #0C546C → #0C6C84` cyan; comet has `#C83C3C` red | `vfx_comet`, `vfx_beam_frost`, `vfx_bolt_fire` |
| v04 | 255 | 848 | 32 | 47 | round orb burst, white core | `#0C2454 → #0C3C9C → #0C54B4` blue | `vfx_orb_arcane` |
| v05 | 294 | 848 | 62 | 47 | **two merged**: green orb burst (x 294–330) + white 4-point sparkle (x 338–356, 18×19) | `#0C3C3C → #0C543C → #246C3C` green; sparkle near-white | `vfx_orb_nature`, `vfx_sparkle_white` |
| v06 | 16 | 895 | 36 | 47 | water/wind vortex | `#0C2454 → #0C3C6C → #0C549C → #3C9CE4` | `vfx_vortex_water` |
| v07 | 61 | 895 | 32 | 48 | flame with rising tail | `#6C0C0C → #B4240C → #CC3C24 → #E45424` | `vfx_flame_tall` |
| v08 | 102 | 901 | 48 | 42 | 8-ray starburst, white core | `#242454 → #3C3C84 → #FCFCFC` violet-white | `vfx_starburst_holy` |
| v09 | 158 | 897 | 54 | 42 | **two diamond shards** (small at x≈158–180, large at x≈185–212) + cyan sparkle — the only plausible 2-frame pair on the panel | `#0C2454 → #0C3C84 → #3CCCFC → #FCFCFC` | `vfx_shard_ice_a/b` |
| v10 | 219 | 901 | 33 | 38 | 4-ray star burst | `#240C54 → #3C0C6C → #6C0C84` magenta | `vfx_star_shadow` |
| v11 | 259 | 895 | 19 | 47 | vertical spear/bolt, bright | `#3C2484 → #54249C → #8454CC → #B484E4` | `vfx_bolt_arcane` |
| v12 | 287 | 895 | 18 | 49 | vertical upward arrow bolt | `#240C54 → #3C0C84 → #54249C` | `vfx_bolt_rise` |
| v13 | 314 | 895 | 39 | 44 | 8-spoke wheel / web | `#240C54 → #3C246C → #542484 → #8454B4` | `vfx_wheel_web` |
| v14 | 17 | 951 | 46 | 46 | radial burst inside ring | `#540C24 → #6C2424 → #B4243C` red | `vfx_burst_red_ring` |
| v15 | 72 | 952 | 48 | 44 | broken ring, dotted | `#243C24 → #3C5424 → #6C843C → #849C54` green | `vfx_ring_venom` |
| v16 | 127 | 946 | 54 | 50 | 8-ray sunburst, white core | `#54240C → #6C240C → #9C3C0C` orange | `vfx_explosion_fire` |
| v17 | 188 | 946 | 52 | 52 | starburst in ring | `#240C54 → #540C6C → #84249C` magenta | `vfx_explosion_shadow` |
| v18 | 248 | 951 | 49 | 46 | dark ring, faint spokes | `#240C54 → #3C2454 → #54246C` dim violet | `vfx_ring_void` |
| v19 | 306 | 947 | 49 | 50 | water splash / swirl | `#0C246C → #0C6CCC → #249CE4 → #54CCFC` | `vfx_splash_water` |

Colour families present: red ×3, orange/fire ×4, blue/water ×4, green ×2, violet/shadow ×6, white ×1. Missing vs A1's "Combat Effects / VFX": **no slash arcs, no sword swings, no impact stars** — melee hit VFX must come from A1.

### 4.2 B2 "Bosses" (panel 2, sub-block y 383–620)

Islands via `--key white --thresh 50 --min-area 400` on region `363,385,386,236` → exactly **6 islands, one per boss, no merging needed** (the checker's dark square is lum 218 < 205 cut-off, so it drops out; grey outline lines are outside the region). Quantised palettes here are outline-dominated (`#0A0A1E`…`#1E1E32`) because the sprites are heavily black-outlined; the *body* hue is given from inspection.

| Boss | x | y | w | h | Body hue | Read |
|---|---|---|---|---|---|---|
| Flame brute (skull-faced, fire mane) | 373 | 385 | 83 | 81 | orange-red `#C8461E`-class, black skull | Smallest boss; reads as an Elite+ rather than a Main Boss. |
| Spiked crawler with chain-flail | 469 | 385 | 103 | 93 | dark iron, orange spikes, magenta flail heads | Low, wide silhouette; the flail heads are separate pixels at ≈(484–496, 445–475) but connect via the chain. |
| Aberration (eye + tentacles) | 583 | 385 | 147 | 92 | indigo/violet, magenta core | Same creature as B1's, 25 % narrower and wider-than-tall; B1's is the better render. |
| Moss/earth golem | 377 | 462 | 117 | 140 | olive-green moss over brown rock, grey face | Tallest B2 boss. Note y 462 overlaps row 1's y-range — the island is correct, the "row" is a visual convenience. |
| Iron/stone golem | 496 | 491 | 107 | 114 | blue-grey stone, orange eye-slits | Equivalent to A2 "Stone Golem". |
| Dragon | 597 | 485 | 143 | 121 | maroon body, violet membranes, orange belly | Wings spread, three-quarter view; B1's dragon is taller (155) but B2's is wider (143) and cleaner to key. |

**Boss size verdict.** Concept 2's boss viewport (see `02-concept2-raid-layout.md`) wants a boss on the order of 200 px tall. Nothing on B1/B2 reaches that; the B1 aberration (197×160) is closest and upscales ×1.25 tolerably; every other boss needs ×1.5–×2 or Aseprite enlargement. A1's alpha bosses (≈230 px) remain the primary source — B1/B2 supply the *additional* boss types (brute, crawler, moss golem, iron golem, flame brute) that A1 lacks.

## 5. UI-ornament candidates

The concepts' chrome (see `06-ui-component-kit.md`) needs: a callout flourish for the mission panel title, panel-corner ornaments, a rail/header divider motif, torch/brazier accents for the town scene chrome, and a "guild mark" (the skull-on-crimson banner that appears on every background plate). Everything below is a real island (coordinates from §3), rated for that use. `key` = how it must be cut.

| Island | Sheet | x,y,w,h | key | Kit component it could supply | Verdict |
|---|---|---|---|---|---|
| `banner_skull_red_large` | B1 Misc | 447,856,28,62 | dark 35 | **Guild mark** — the crimson skull banner. Roster-panel header badge, mission-panel title flourish (mirrored pair). Pennant tails are the tapered-swallowtail shape Concept 1's header uses. | **Best banner on B1/B2**: full pole-and-crossbar, 28×62, clean ramp `#5A1420 → #A02832 → #C8465A`, ivory skull. Cut at ×1 and ×2. |
| `banner_skull_purple_tall` | B1 Props | 1025,213,44,96 | dark 35 | Tall side-ornament for the nav rail top; "Aberration" faction mark for raid panels. | Largest banner (96 tall); crossbar + tassels; purple `#3C1E50`-class matches the raid palette. |
| `banner_skull_red_pole` | B1 Props | 993,209,19,56 | dark 35 | Small badge (tab marker, card rarity flag). | 19 px wide — usable at ×1 inside a 24-px tab. |
| `banner_skull_red_small` / `pennant_skull_red` | B1 Misc | 477,863,20,41 / 530,857,15,32 | dark 35 | List bullet / active-row marker. | Pennant (15×32) is the smallest legible skull banner on any sheet. |
| `banner_pole_narrow` | B1 Misc | 634,856,22,47 | dark 35 | Vertical divider with finial. | Pink-mauve — off-palette; recolour. |
| `banner_skull_red_on_pole` | B1 Struct | 752,27,34,63 | dark 35 | Same role as Misc large banner; alternate drape. | Slight lean (pole not vertical) — worse for chrome. |
| `totem_skull_wreath_banner` | B1 Struct | 796,68,45,83 | dark 35 | **Panel-corner / title ornament**: round skull-in-wreath medallion (top 45×45) over a hanging strip. Medallion alone = the round guild seal for the header chip row. | Medallion is the only *circular* ornament on B1/B2; gold-brown wreath `#8C6E3C`-class matches the bronze border tokens in `04-palette.md`. |
| `tower_round_skull_banners` | B1 Struct | 751,228,46,81 | dark 35 | Not chrome — scene building. | Skip for UI. |
| `brazier_flaming_tall` | B1 Props | 1023,58,49,92 | dark 35 (flame: ADD) | Town-scene torch accent flanking the building callouts; animated by swapping the flame tip only. | Flame occupies y 58–108, stand below; cut flame separately and blend ADD. |
| `torch_lit_standing` / `torch_lit_pole` | B1 Misc / Props | 507,860,16,44 / 914,227,19,52 | dark 35 | Rail-item hover accent; "lit" state indicator. | 16–19 px wide — fits a 24-px rail glyph cell. |
| `candlestand_a/b` | B1 Props | 1001,106,16,31 / 1025,110,15,40 | dark 35 | Tavern-screen chrome accents. | Fine detail; only at ×2. |
| `frame_scaffold_wood` / `frame_wood_wheel` | B1 Misc | 552,856,40,48 / 599,856,28,38 | dark 35 | **Panel-corner ornament source**: the lashed-timber corner joint (top-left 12×12 of each) is a ready-made corner bracket for wooden-frame panels. | Only if the kit goes "camp-timber" rather than "bronze"; `04-palette.md` chose bronze — keep as fallback. |
| `signboard_post` / `signboard_a/b/c` | B1 Props / Struct | 1000,272,21,37 · 820,215,19,29 · 803,252,18,23 · 822,254,19,20 | dark 35 | Tooltip/callout plate silhouette (hanging wooden sign). | The shape Concept 3's building callouts approximate; use as the callout's *tail* ornament. |
| `icon_rune_ring_grey` / `icon_sigil_purple` / `icon_sigil_green` | B1 unlabelled panel | 375,856,46,46 · 376,914,43,33 · 377,964,39,32 | dark 35 (ADD) | Status/ability glyph backgrounds; empty-slot placeholder for gear slots. | 46×46 grey ring is a near-exact fit for Concept 1's gear-slot square (`06` measures 48). |
| `banner_navy_gold_sigil` | B2 Props | 958,239,31,69 | white 60 | **Second faction colour** — navy banner with gold crest: Reputation / guild-rank chip ornament. | Only navy banner on B1/B2; checker key leaves grey fringe on the gold, ~1 px. |
| `banner_skull_red_pole` (B2) | B2 Props | 805,102,39,76 | white 60 | Same role as B1 large banner at ×1.25 scale. | Prefer B1's — dark key is cleaner than checker on a red/black banner. |
| `banner_purple_tall_narrow` | B2 Props | 836,359,20,83 | white 60 | Vertical divider / rail spine ornament. | 20×83, gold sigil; good aspect for a rail. |
| `pennant_skull_red` (B2) · `banner_skull_red_pole_b` · `banner_skull_red_c` · `banner_skull_red_small` | B2 Props | 860,308,33,56 · 819,458,23,71 · 932,537,26,67 · 815,570,25,46 | white 60 | Drape variants of the guild mark. | Four more drape shapes; use for variety in the town scene, not in chrome (chrome wants one canonical mark). |
| `banner_navy_small` / `banner_red_gold_small` | B2 Props | 927,484,29,46 / 962,485,26,45 | white 60 | Paired left/right title flourish (blue/red). | Only *pair* of matched banners in two colours on B2. |
| `frame_gallows_chain` | B2 Props | 843,447,35,55 | white 60 | Hanging-sign bracket with chain — callout tail. | Chain is 1 px; survives only at ×2. |
| `lantern_post_a/b` | B2 Props | 830,68,18,32 / 858,69,19,30 | white 60 | Lit lantern accents (alternative to torches). | Warm glow halo is lost to the checker key; B1 torches are better. |

**Ranking for chrome:** (1) A1 "Misc / Decor" (alpha, six banner colours, torches, shields — see `07`) → (2) B1 Misc/Props/Struct banners above (dark key, clean) → (3) B2 props (checker key, fringe). Nothing on B1/B2 is a *frame* or *border* in the sense of Concept 1's bronze panel border — that border is authored in the kit, not harvested.

## 6. Quality verdict per canon class (B1 / B2)

Measured sprite metrics. **B2** raider rows: 10–11 poses per labelled row (column projection at `--thresh 60`, occupancy ≥3 gives 8–10 boxes per row because 1–2 neighbours merge — counts by eye are 11 per row), median body 22 px wide × 37–39 px tall, tallest with raised weapon 50 px; poses vary (idle, walk, attack, cast, kneel), all side/three-quarter facing, black-outlined, saturated. **B1** "Character Sprites": 5 rows × 16 = 80 sprites, all ~20×41 px front-facing idle, unlabelled; 28 px column pitch; rows start x 248–250, y bands 353–397 / 401–445 / 453–497 / 508–549 / 556–601. B1 "NPCs & Townsfolk": 5 rows × 11–12 at ~19×41, same style — townsfolk for the camp scene, not raiders. Neither sheet has portraits.

Keying caveat that decides several verdicts: B2's checker key (`lum < 195`) **erodes light pixels** — white/grey hair, the Cleric row's ivory robes, steel highlights — leaving holes; B1's dark key (`lum > 35`) **erodes dark outlines and black cloth**, which is why the goblin row split into head-only islands. Neither is clean; A1 (true alpha) is.

| Canon class (`Enums.CharClass`) | B1 | B2 | Verdict for B1/B2 | Best source overall |
|---|---|---|---|---|
| Warrior | unlabelled; ~6 armoured brown/grey front-idle sprites (rows 1–2) usable as recolour bases | **labelled row y 30–80**, 11 poses, 22×43 median, sword+shield, brown leather + steel | **B2 Good** — most poses of any Warrior on any sheet; Berserker row (y 291–344, 11 poses, red-haired, axe) harvests as Warrior variants per `00` §2.2 | B2 for combat poses; A1 for portrait |
| Monk | none | none labelled; **Berserker row** (bare-armed, wraps) is the nearest silhouette | **B2 Fair (derived)** — Berserker sprites 2, 5, 7 (x 81, 185, 269) are unarmed/fist poses → Monk base with a recolour to saffron/grey | B2 Berserker row → Aseprite recolour |
| Rogue | row 3 col 1 hooded green (x 249,y 453) and ~3 dark hooded sprites | **labelled row y 82–132**, 11 poses, daggers, hood; plus **Ranger row y 237–290** (bow, green) as variants per `00` §2.2 | **B2 Good** — Rogue + Ranger = 22 poses | B2 (poses), A1 (portrait "Rogue" exists) |
| Cleric | row 3 white-hatted/robed sprites (cols 7–8) | **labelled row y 185–236**, 11 poses, mace + book, **ivory robes** | **B2 Fair** — content is right, but the checker key eats the ivory robe interior; needs manual alpha repair of ~10 % of pixels per sprite | A1 (alpha) for clean cut; B2 for pose count |
| Druid | row 3 col 1 hooded green + row 4 col 1 green hood | **labelled row y 345–398**, 11 poses, green hood, staff with leaf/flame tip; blonde-and-white variants at cols 6–9 | **B2 Good** — only labelled Druid on any of the four sheets | B2 (unique) |
| Shaman | none; nearest: row 3 hat-wearers (cols 3–6) with feathers | none labelled; nearest: Druid cols 6–9 (pale, staff) or Engineer row's goggled sprites (no) | **Missing** — no Shaman on any sheet. Propose: Druid row recoloured to bone/teal + a mask/feather headdress edit, ~11 sprites of Aseprite work | Author in Aseprite from B2 Druid |
| Bard | none | none | **Missing on B1/B2**; A2 has a labelled Bard row (see `07`) | A2 |
| Mage | row 3 pointed hats (cols 3, 5, 6; blue and red hats) | **labelled row y 133–184**, 11 poses: **two colourways** — cols 1–4 (x 51–181) red/orange-haired brown robe, cols 5–11 (x 185–349) blue robe with staff | **B2 Good** — and the two colourways give **Mage vs Wizard** for free: propose brown/red = Mage, blue = Wizard (behind a switch; the designer names which) | B2 |
| Wizard | as Mage | as Mage (blue colourway) | **B2 Fair (derived)** — 7 blue-robe poses; a pointed hat is present on only 2 of them, so the silhouette distinction from Mage is weak | B2 blue colourway + A1 Mage hat portrait |

Non-canon rows and what happens to them: B2 **Ranger** (y 237–290) → Rogue variants; **Berserker** (y 291–344) → Warrior/Monk variants; **Engineer** (y 399–452) → **not used** (goggles, wrench, blue overalls — no canon read). B2 **Raider Variants** (y 490–540: 11 sprites; y 541–592: 12 sprites; ~19×36, dark leather, mixed hair) are class-agnostic and serve as the **named-legendary bases** (`legendaries` commit) since they are the only rows without class kit. B1's 80 unlabelled sprites are the **recruitment-pool filler**: front-facing idle only, so they suit the tavern candidate board and roster cards, not the raid strip.

Coverage count: labelled canon classes present on B1/B2 = **5 of 9** (Warrior, Rogue, Mage, Cleric, Druid — all on B2). Derived = 3 (Monk, Wizard, Shaman-by-edit). Absent = 1 on these sheets (Bard; A2 has it). Combined with A1/A2, every canon class except Shaman has at least a labelled sprite row somewhere; **Shaman is the one class that must be authored from scratch**, and portraits exist only for A1's five (Warrior, Ranger→Rogue, Mage, Cleric, Rogue) — four canon portraits (Monk, Druid, Shaman, Bard) plus a Wizard variant are Aseprite work.
