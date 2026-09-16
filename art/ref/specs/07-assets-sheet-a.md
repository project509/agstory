# 07 — Asset sheet A inventory (A1 alpha sheet, A2 white-background sheet)

> **Status:** Measured (A1 complete; A2 raiders not sliced by design, see §6) · **Owner:** Art pass · **Updated:** 2026-09-09
> **Inputs:** `ideaboard/Reference Graphics/0f2ce34a-d799-4c05-bfc0-e830fdcba947.png` (A1, 1536x1024 RGBA), `ideaboard/Reference Graphics/0718af5b-2c1e-41fd-8123-c74ea114b810.png` (A2, 1536x1024 RGB), `00-canon-reconciliation.md` §2.2 (Ranger/Berserker/Engineer/Thief are non-canon).
> **Tools:** `tools/art/refkit.py`, `tools/art/slice.py islands`.

All coordinates are sheet pixels at 1:1 (x right, y down, origin top-left). Canon classes: Warrior, Monk, Rogue, Cleric, Druid, Shaman, Bard, Mage, Wizard (`data/classes.json`, `Enums.CharClass`).

## 1. Section map

### 1.1 A1 (alpha sheet)
Every A1 section is a dark label pill (mean RGB about `#2B3237`, 24-25 px tall, white serif caps) placed above a loose cluster of islands; there are no panel borders. Pill rects were found as alpha islands with mean RGB < 90 and w >= 60; section rects are the union of the islands under each pill (`slice.py islands --region`).

| # | Printed label | Pill rect (x,y,w,h) | Section content rect (x,y,w,h) | Notes |
|---|---|---|---|---|
| A1-S1 | Tileset (World / Camp / Buildings) | 10,8,300,25 | 9,38,451,590 | Top block 9,38,451,201 is one fused island of touching tiles (see §3); loose building/prop islands below it to y=628. |
| A1-S2 | Raider Sprites (player controlled) | 477,8,261,25 | 477,37,262,575 | Class pills + portraits at x 478-538; 5 sprite columns at x 546-740. |
| A1-S3 | Raider Variations | 754,8,133,24 | 758,42,122,536 | 4 cols x 12 rows of palette-swap idles. |
| A1-S4 | Monsters / Bosses | 905,8,164,25 | 904,36,259,566 | 4 boss-sized islands + 18 monster islands. |
| A1-S5 | Background Scenes | fused into plate island | 1181,8,349,1003 | Five scene plates stacked; the pill touches plate 1 so the whole column is one island. Plate rects in §3. |
| A1-S6 | Environment / Objects | 10,638,190,24 | 8,662,535,355 | 67 islands: chests, barrels, furniture, trees, rocks, bridges, boats. |
| A1-S7 | Combat Effects / VFX | 552,616,163,23 | 548,640,275,375 | 36 islands. |
| A1-S8 | Animations / Extras | 829,612,152,24 | 829,645,345,200 | 33 islands: emote bubbles, portrait heads, icons, one downed raider, campfires, loot. |
| A1-S9 | Misc / Decor | 831,849,101,22 | 841,878,315,120 | 7 hanging banners, 3 wall torches, 1 pillar, 3 crest shields. |

Class pills inside A1-S2 (dark islands, w < 60): Warrior 479,37 (fused with its portrait into 54x81), Ranger 479,129,53,22, Mage 478,219,42,20, Cleric 479,320 (fused with portrait, 54x82), Rogue 479,409,46,20. A sixth portrait at 481,510,57,68 (full-helm knight) and a crown/loot object at 482,590,47,21 carry **no label** — mockup overflow.

### 1.2 A2 (white-background sheet)
A2 is **not** a white sheet: the background is an AI-painted checkerboard (light squares lum 238-245, dark squares about 225, with noise down to lum 190 next to sprites; row 5 changes value every 1-6 px, so it is not a regular checker either) — see §6. Panels have a 1-px grey border line, measured as columns/rows with lum < 220 over > 60 % of their length and lighter checker 4 px either side. Labels are black pills with white sans text (row-label text is grey-on-checker, not pilled). The six background plates are the only sections that key as clean rects.

| # | Printed label | Panel rect (x,y,w,h) | Notes |
|---|---|---|---|
| A2-S1 | Player Character Sprites (Raiders) | 0,0,392,448 | 8 class rows: Warrior, Ranger, Mage, Cleric, Thief, Berserker, Engineer, Bard (label column x 8-45; row centres y 44, 84, 125, 169, 213, 257, 300, 345). Only Warrior/Mage/Cleric/Bard are canon names (00 §2.2). |
| A2-S2 | Enemies & Bosses | 392,0,359,448 | Sub-labels top to bottom: Void Colossus (Boss), Abomination Swarm, Stone Golem (Boss), Stone Golem (Boss), Undead Legion, Slime Hive, Constructs. The label "Stone Golem (Boss)" is printed twice and from row 4 down each label sits one row above its art (skeletons under the 2nd "Stone Golem", slimes under "Undead Legion", clockwork under "Slime Hive", nothing under "Constructs") — AI-mockup artifact; resolve by content, not label. |
| A2-S3 | Tileset | 751,0,304,448 | Ground tiles 4 rows x 8 in 757-1050 x 22-140 (about 33-px pitch); walls, crates, tables, ladders below. |
| A2-S4 | Buildings & Structures | 1055,0,280,448 | 7 iso buildings incl. an airship and a crane. |
| A2-S5 | Environment Props | 1335,0,201,382 | Trees, crystals, barrels, lanterns, banners. |
| A2-S6 | Vehicles / Mounts | 1335,382,201,66 | Airship, horse, blue beast. |
| A2-S7 | World/ NPC Sprites | 0,452,696,116 | 2 rows x 22 townsfolk (about 22x38) + dog, chicken. |
| A2-S8 | FX & Misc | 696,452,347,116 | 3 rows of burst / void / ring VFX. |
| A2-S9 | Furniture & Interior Props | 1043,452,493,116 | Beds, tables, shelves, chairs, chandeliers. |
| A2-B1 | Town / Guild Hall Background | 0,571,513,274 | island-exact |
| A2-B2 | World Map / Overworld Background | 514,571,508,273 | island-exact |
| A2-B3 | Raid / Void Realm Background | 1024,571,512,273 | island-exact |
| A2-B4 | Camp / Outpost Background | 0,846,512,178 | island-exact |
| A2-B5 | Dungeon / Cave Background | 514,846,508,178 | island-exact |
| A2-B6 | Forest / Wilderness Background | 1024,846,512,178 | island-exact |

Border lines: vertical x = 392, 751, 1055, 1335 (upper band) and 696, 1043 (lower band); horizontal y = 448 (upper panels' bottom), 570/571 and 845/846 (background rows). The S5/S6 split at y = 382 is read from the "Vehicles / Mounts" pill (1343,384), no line was detected.

## 2. Raider sprites
### 2.1 A1-S2 "Raider Sprites" (the block that matters)

`slice.py islands --key alpha --thresh 16 --min-area 30 --region 470,36,420,575` gives **114 islands** (includes S3 and the pills/portraits). Sprite islands only: w min/median/max = 21/25/33, h = 36/39/45. Two fused pairs: 705,425,24,79 (split at y = 464) and 552,514,31,82 (split at y = 555).

**Grid.** 5 columns x 12 rows (6 class pairs of 2 rows). Column left edges (median): **549, 592, 632, 670, 706** — pitch 43, 40, 38, 36, i.e. the mockup did not lay these on a true grid; cut by island, not by pitch. Row top edges: 41/95 (Warrior), 145/190 (Ranger), 235/280 (Mage), 336/380 (Cleric), 424/466 (Rogue), 514/559 (unlabelled knight). Intra-pair row pitch 42-54; class pitch 95-101.

**What the columns are.** At 5x (`a1_warrior.png`, `a1_ranger.png`): every one of the 5 columns in a row is the **same front-facing idle pose**. The differences are (a) whether the weapon is drawn (Warrior cols 1-2 carry a sword, cols 3-5 do not), (b) armour palette (Warrior row 2 cols 3-5 are olive-green instead of grey), (c) sub-pixel noise. There is **no walk, attack, cast or down frame anywhere in A1-S2**. Confidence: **high** — silhouettes match to within 1 px; these are AI repetitions of one sprite, not an animation strip. Row 2 of each pair is a face/armour variant of row 1, not a second animation. The only "down" pose on the sheet is the single fallen raider in A1-S8 (849,714,56,48).

**Per class (A1-S2):**

| Label | Rows y | Sprite size (typical) | Colour read | Canon mapping |
|---|---|---|---|---|
| Warrior | 41, 95 | 31x41 with sword / 25x41 without | orange hair, grey plate, skull-white face | Warrior |
| Ranger | 145, 190 | 26-31x39 | olive hood + cloak | Rogue (00 §2.2) |
| Mage | 235, 280 | 27-39x44 | wide dark hat, navy robe | Mage (Wizard by palette swap) |
| Cleric | 336, 380 | 25-33x41 | steel helm, grey mail | Cleric |
| Rogue | 424, 466 | 24-25x38 | black hood, dark leathers | Rogue |
| (unlabelled) | 514, 559 | 25-31x42 | full-helm knight, blue-grey | Warrior / Monk variant |

### 2.2 A1-S3 "Raider Variations"

4 cols x 12 rows, left edges **758, 790, 822, 855** (pitch 32/32/33), row tops 42, 89, 140, 185, 232, 282, 334, 376 (heads only, 22 px), 408, 449, 491, 536 (pitch 42-52). Sprites **21-25 x 31-40**. At 5x (`a1_var.png`): four hair colours (ginger, brown, black, grey) on an identical dark-leather body — palette-swap idles, no animation. Row 8 (y 376) is 3 detached heads (25x22, a 60x22 fused pair, 30x21) — portrait crops, not sprites.

### 2.3 A2-S1 "Player Character Sprites (Raiders)"

8 labelled rows (Warrior, Ranger, Mage, Cleric, Thief, Berserker, Engineer, Bard) x 9-12 sprites, sprite about 22x38 at row pitch 44 and column pitch 31 (first column x = 52). At 3x (`a2_tl.png`) the sprites are **blurred and colour-bled** — A2 is a JPEG-grade upscale, not clean pixel art; edges are 2-3 px soft. Columns 10-12 of Warrior / Mage / Cleric show a fire-swipe, blue-bolt and lunge pose, so A2 does contain *one* attack-ish pose per class, but at unusable fidelity. Not island-sliced: the noisy checker defeats a clean key (§6).

## 3. JSON manifest
378 entries. Every rect is an island bounding box from `slice.py islands` (A1: `--key alpha --thresh 16`; A2: `--key white --thresh 70` for S2, `60` for backgrounds) except the A1 tile grid (one grid entry) and the five A1 background plates (alpha edges at x = 1185 / 1500, x-extent from row 500). `index` restarts per section. Names were assigned by looking at 2x-5x crops; a `note` of `fused` means two sprites touch and the cut step must split them (the split line is given where it was measured). Counts by category: background 11, banner 17, boss 10, building 20, enemy 40, misc 22, npc 11, prop 104, raider 102, tile 4, vfx 37. Also saved as `scratchpad/manifest_a1.json` (scratch; regenerate with the recipe in §6).

```json
[
{"sheet":"0f2ce34a","section":"A1-S2","index":0,"x":479,"y":37,"w":54,"h":81,"proposed_name":"pill_warrior_plus_portrait","category":"misc","note":"label/portrait column"},
{"sheet":"0f2ce34a","section":"A1-S2","index":1,"x":549,"y":41,"w":77,"h":51,"proposed_name":"raider_warrior_idle_1","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":0,"x":758,"y":42,"w":24,"h":39,"proposed_name":"raider_variant_r01_ginger_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":1,"x":790,"y":42,"w":24,"h":39,"proposed_name":"raider_variant_r01_brown_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":2,"x":822,"y":42,"w":24,"h":39,"proposed_name":"raider_variant_r01_black_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":3,"x":855,"y":42,"w":25,"h":39,"proposed_name":"raider_variant_r01_grey_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":2,"x":630,"y":43,"w":31,"h":48,"proposed_name":"raider_warrior_idle_3","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":3,"x":668,"y":43,"w":32,"h":48,"proposed_name":"raider_warrior_idle_4","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":4,"x":705,"y":43,"w":28,"h":48,"proposed_name":"raider_warrior_idle_5","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":4,"x":758,"y":89,"w":24,"h":40,"proposed_name":"raider_variant_r02_ginger_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":5,"x":855,"y":89,"w":25,"h":40,"proposed_name":"raider_variant_r02_grey_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":6,"x":789,"y":90,"w":25,"h":39,"proposed_name":"raider_variant_r02_brown_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":7,"x":822,"y":90,"w":25,"h":39,"proposed_name":"raider_variant_r02_black_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":5,"x":546,"y":95,"w":32,"h":43,"proposed_name":"raider_warrior_b_idle_1","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":6,"x":586,"y":95,"w":32,"h":44,"proposed_name":"raider_warrior_b_idle_2","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":7,"x":631,"y":98,"w":25,"h":41,"proposed_name":"raider_warrior_b_idle_3","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":8,"x":669,"y":98,"w":25,"h":41,"proposed_name":"raider_warrior_b_idle_4","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":9,"x":706,"y":98,"w":25,"h":40,"proposed_name":"raider_warrior_b_idle_5","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":10,"x":479,"y":129,"w":53,"h":22,"proposed_name":"pill_ranger","category":"misc","note":"label/portrait column"},
{"sheet":"0f2ce34a","section":"A1-S3","index":8,"x":759,"y":140,"w":23,"h":36,"proposed_name":"raider_variant_r03_ginger_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":9,"x":791,"y":140,"w":23,"h":36,"proposed_name":"raider_variant_r03_brown_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":10,"x":823,"y":140,"w":24,"h":37,"proposed_name":"raider_variant_r03_black_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":11,"x":856,"y":140,"w":23,"h":36,"proposed_name":"raider_variant_r03_grey_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":11,"x":549,"y":145,"w":31,"h":39,"proposed_name":"raider_ranger_as_rogue_idle_1","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":12,"x":591,"y":145,"w":26,"h":39,"proposed_name":"raider_ranger_as_rogue_idle_2","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":13,"x":630,"y":145,"w":29,"h":39,"proposed_name":"raider_ranger_as_rogue_idle_3","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":14,"x":671,"y":145,"w":24,"h":39,"proposed_name":"raider_ranger_as_rogue_idle_4","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":15,"x":707,"y":145,"w":25,"h":39,"proposed_name":"raider_ranger_as_rogue_idle_5","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":16,"x":488,"y":152,"w":41,"h":59,"proposed_name":"portrait_ranger_as_rogue","category":"npc","note":"label/portrait column"},
{"sheet":"0f2ce34a","section":"A1-S3","index":12,"x":759,"y":185,"w":23,"h":37,"proposed_name":"raider_variant_r04_ginger_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":13,"x":791,"y":185,"w":22,"h":37,"proposed_name":"raider_variant_r04_brown_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":14,"x":823,"y":185,"w":23,"h":37,"proposed_name":"raider_variant_r04_black_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":15,"x":855,"y":185,"w":24,"h":37,"proposed_name":"raider_variant_r04_grey_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":17,"x":550,"y":190,"w":30,"h":39,"proposed_name":"raider_ranger_as_rogue_b_idle_1","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":18,"x":671,"y":190,"w":23,"h":39,"proposed_name":"raider_ranger_as_rogue_b_idle_4","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":19,"x":593,"y":191,"w":26,"h":39,"proposed_name":"raider_ranger_as_rogue_b_idle_2","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":20,"x":633,"y":191,"w":24,"h":39,"proposed_name":"raider_ranger_as_rogue_b_idle_3","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":21,"x":707,"y":191,"w":24,"h":38,"proposed_name":"raider_ranger_as_rogue_b_idle_5","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":22,"x":478,"y":219,"w":42,"h":20,"proposed_name":"pill_mage","category":"misc","note":"label/portrait column"},
{"sheet":"0f2ce34a","section":"A1-S3","index":16,"x":759,"y":232,"w":23,"h":40,"proposed_name":"raider_variant_r05_ginger_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":17,"x":791,"y":232,"w":23,"h":40,"proposed_name":"raider_variant_r05_brown_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":18,"x":823,"y":232,"w":23,"h":40,"proposed_name":"raider_variant_r05_black_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":19,"x":855,"y":232,"w":24,"h":40,"proposed_name":"raider_variant_r05_grey_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":23,"x":551,"y":235,"w":31,"h":41,"proposed_name":"raider_mage_idle_1","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":24,"x":593,"y":237,"w":27,"h":40,"proposed_name":"raider_mage_idle_2","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":25,"x":669,"y":238,"w":26,"h":38,"proposed_name":"raider_mage_idle_4","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":26,"x":632,"y":239,"w":25,"h":37,"proposed_name":"raider_mage_idle_3","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":27,"x":706,"y":239,"w":26,"h":38,"proposed_name":"raider_mage_idle_5","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":28,"x":487,"y":242,"w":51,"h":68,"proposed_name":"portrait_mage","category":"npc","note":"label/portrait column"},
{"sheet":"0f2ce34a","section":"A1-S2","index":29,"x":547,"y":280,"w":39,"h":45,"proposed_name":"raider_mage_b_idle_1","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":30,"x":593,"y":281,"w":30,"h":44,"proposed_name":"raider_mage_b_idle_2","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":20,"x":760,"y":282,"w":22,"h":37,"proposed_name":"raider_variant_r06_ginger_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":21,"x":791,"y":282,"w":23,"h":37,"proposed_name":"raider_variant_r06_brown_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":22,"x":823,"y":282,"w":24,"h":37,"proposed_name":"raider_variant_r06_black_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":23,"x":856,"y":282,"w":22,"h":37,"proposed_name":"raider_variant_r06_grey_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":31,"x":632,"y":283,"w":27,"h":42,"proposed_name":"raider_mage_b_idle_3","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":32,"x":670,"y":283,"w":23,"h":41,"proposed_name":"raider_mage_b_idle_4","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":33,"x":706,"y":284,"w":22,"h":40,"proposed_name":"raider_mage_b_idle_5","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":34,"x":479,"y":320,"w":54,"h":82,"proposed_name":"pill_cleric_plus_portrait","category":"misc","note":"label/portrait column"},
{"sheet":"0f2ce34a","section":"A1-S3","index":24,"x":856,"y":332,"w":22,"h":36,"proposed_name":"raider_variant_r07_grey_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":25,"x":825,"y":333,"w":21,"h":34,"proposed_name":"raider_variant_r07_black_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":26,"x":761,"y":334,"w":22,"h":33,"proposed_name":"raider_variant_r07_ginger_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":27,"x":793,"y":334,"w":21,"h":31,"proposed_name":"raider_variant_r07_brown_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":35,"x":551,"y":336,"w":33,"h":41,"proposed_name":"raider_cleric_idle_1","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":36,"x":593,"y":337,"w":30,"h":40,"proposed_name":"raider_cleric_idle_2","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":37,"x":670,"y":338,"w":25,"h":39,"proposed_name":"raider_cleric_idle_4","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":38,"x":706,"y":338,"w":25,"h":39,"proposed_name":"raider_cleric_idle_5","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":39,"x":632,"y":339,"w":26,"h":38,"proposed_name":"raider_cleric_idle_3","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":28,"x":760,"y":376,"w":25,"h":22,"proposed_name":"head_variant_0","category":"npc","note":"detached head, not a body sprite"},
{"sheet":"0f2ce34a","section":"A1-S3","index":29,"x":790,"y":376,"w":60,"h":22,"proposed_name":"head_variant_1","category":"npc","note":"detached head, not a body sprite (fused pair)"},
{"sheet":"0f2ce34a","section":"A1-S3","index":30,"x":852,"y":377,"w":30,"h":21,"proposed_name":"head_variant_3","category":"npc","note":"detached head, not a body sprite"},
{"sheet":"0f2ce34a","section":"A1-S2","index":40,"x":551,"y":380,"w":33,"h":38,"proposed_name":"raider_cleric_b_idle_1","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":41,"x":591,"y":382,"w":29,"h":37,"proposed_name":"raider_cleric_b_idle_2","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":42,"x":632,"y":382,"w":26,"h":36,"proposed_name":"raider_cleric_b_idle_3","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":43,"x":670,"y":382,"w":23,"h":37,"proposed_name":"raider_cleric_b_idle_4","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":44,"x":705,"y":382,"w":24,"h":37,"proposed_name":"raider_cleric_b_idle_5","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":31,"x":856,"y":407,"w":23,"h":35,"proposed_name":"raider_variant_r09_grey_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":32,"x":761,"y":408,"w":22,"h":34,"proposed_name":"raider_variant_r09_ginger_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":33,"x":792,"y":408,"w":22,"h":34,"proposed_name":"raider_variant_r09_brown_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":34,"x":824,"y":408,"w":23,"h":34,"proposed_name":"raider_variant_r09_black_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":45,"x":479,"y":409,"w":46,"h":20,"proposed_name":"pill_rogue","category":"misc","note":"label/portrait column"},
{"sheet":"0f2ce34a","section":"A1-S2","index":46,"x":552,"y":424,"w":25,"h":38,"proposed_name":"raider_rogue_idle_1","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":47,"x":592,"y":425,"w":25,"h":38,"proposed_name":"raider_rogue_idle_2","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":48,"x":632,"y":425,"w":24,"h":37,"proposed_name":"raider_rogue_idle_3","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":49,"x":670,"y":425,"w":23,"h":36,"proposed_name":"raider_rogue_idle_4","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":50,"x":705,"y":425,"w":24,"h":79,"proposed_name":"raider_rogue_idle_5","category":"raider","note":"fused pair: split at y=464"},
{"sheet":"0f2ce34a","section":"A1-S2","index":51,"x":490,"y":433,"w":37,"h":66,"proposed_name":"portrait_rogue","category":"npc","note":"label/portrait column"},
{"sheet":"0f2ce34a","section":"A1-S3","index":35,"x":761,"y":449,"w":22,"h":33,"proposed_name":"raider_variant_r10_ginger_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":36,"x":793,"y":449,"w":22,"h":34,"proposed_name":"raider_variant_r10_brown_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":37,"x":825,"y":449,"w":22,"h":33,"proposed_name":"raider_variant_r10_black_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":38,"x":857,"y":449,"w":21,"h":33,"proposed_name":"raider_variant_r10_grey_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":52,"x":552,"y":466,"w":25,"h":39,"proposed_name":"raider_rogue_b_idle_1","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":53,"x":593,"y":466,"w":29,"h":39,"proposed_name":"raider_rogue_b_idle_2","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":54,"x":669,"y":466,"w":24,"h":38,"proposed_name":"raider_rogue_b_idle_4","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":55,"x":632,"y":467,"w":24,"h":37,"proposed_name":"raider_rogue_b_idle_3","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":39,"x":761,"y":491,"w":22,"h":36,"proposed_name":"raider_variant_r11_ginger_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":40,"x":792,"y":491,"w":22,"h":36,"proposed_name":"raider_variant_r11_brown_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":41,"x":824,"y":491,"w":22,"h":36,"proposed_name":"raider_variant_r11_black_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":42,"x":855,"y":491,"w":23,"h":36,"proposed_name":"raider_variant_r11_grey_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":56,"x":481,"y":510,"w":57,"h":68,"proposed_name":"portrait_knight_unlabelled","category":"npc","note":"label/portrait column"},
{"sheet":"0f2ce34a","section":"A1-S2","index":57,"x":552,"y":514,"w":31,"h":82,"proposed_name":"raider_knight_unlabelled_idle_1","category":"raider","note":"fused pair: split at y=555"},
{"sheet":"0f2ce34a","section":"A1-S2","index":58,"x":592,"y":514,"w":26,"h":42,"proposed_name":"raider_knight_unlabelled_idle_2","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":59,"x":631,"y":515,"w":25,"h":39,"proposed_name":"raider_knight_unlabelled_idle_3","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":60,"x":670,"y":515,"w":23,"h":39,"proposed_name":"raider_knight_unlabelled_idle_4","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":61,"x":705,"y":515,"w":24,"h":38,"proposed_name":"raider_knight_unlabelled_idle_5","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":43,"x":760,"y":536,"w":23,"h":40,"proposed_name":"raider_variant_r12_ginger_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":44,"x":791,"y":536,"w":23,"h":40,"proposed_name":"raider_variant_r12_brown_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":45,"x":823,"y":536,"w":24,"h":40,"proposed_name":"raider_variant_r12_black_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S3","index":46,"x":855,"y":536,"w":23,"h":40,"proposed_name":"raider_variant_r12_grey_idle","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":62,"x":592,"y":559,"w":28,"h":37,"proposed_name":"raider_knight_unlabelled_b_idle_2","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":63,"x":632,"y":559,"w":25,"h":37,"proposed_name":"raider_knight_unlabelled_b_idle_3","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":64,"x":670,"y":559,"w":23,"h":37,"proposed_name":"raider_knight_unlabelled_b_idle_4","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":65,"x":706,"y":559,"w":22,"h":37,"proposed_name":"raider_knight_unlabelled_b_idle_5","category":"raider"},
{"sheet":"0f2ce34a","section":"A1-S2","index":66,"x":482,"y":590,"w":47,"h":21,"proposed_name":"crown_loot_unlabelled","category":"prop","note":"label/portrait column"},
{"sheet":"0f2ce34a","section":"A1-S4","index":0,"x":904,"y":36,"w":259,"h":154,"proposed_name":"void_eye_tentacle_boss","category":"boss"},
{"sheet":"0f2ce34a","section":"A1-S4","index":1,"x":906,"y":188,"w":138,"h":109,"proposed_name":"crystal_golem_boss","category":"boss"},
{"sheet":"0f2ce34a","section":"A1-S4","index":2,"x":1050,"y":199,"w":58,"h":103,"proposed_name":"brute_pair_fused","category":"enemy","note":"two figures fused: split at y=250"},
{"sheet":"0f2ce34a","section":"A1-S4","index":3,"x":1098,"y":206,"w":62,"h":78,"proposed_name":"armored_ogre_brute","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":4,"x":907,"y":301,"w":254,"h":124,"proposed_name":"crimson_wyvern_boss","category":"boss"},
{"sheet":"0f2ce34a","section":"A1-S4","index":5,"x":1061,"y":361,"w":99,"h":119,"proposed_name":"sludge_maw_leviathan","category":"boss"},
{"sheet":"0f2ce34a","section":"A1-S4","index":6,"x":909,"y":406,"w":67,"h":65,"proposed_name":"green_spider_crawler","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":7,"x":985,"y":430,"w":61,"h":44,"proposed_name":"dark_spider_small","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":8,"x":913,"y":479,"w":32,"h":40,"proposed_name":"green_beetle_imp","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":9,"x":955,"y":484,"w":39,"h":39,"proposed_name":"dark_bat_blob","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":10,"x":1001,"y":485,"w":37,"h":78,"proposed_name":"pink_tentacle_wraith","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":11,"x":1046,"y":492,"w":36,"h":37,"proposed_name":"green_blob","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":12,"x":1088,"y":497,"w":44,"h":44,"proposed_name":"spore_blob","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":13,"x":909,"y":526,"w":41,"h":35,"proposed_name":"eye_blob","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":14,"x":957,"y":529,"w":33,"h":37,"proposed_name":"green_blob_b","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":15,"x":1032,"y":534,"w":30,"h":56,"proposed_name":"tentacle_polyp","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":16,"x":1068,"y":538,"w":29,"h":51,"proposed_name":"tentacle_polyp_b","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":17,"x":1126,"y":529,"w":33,"h":36,"proposed_name":"dark_blob","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":18,"x":1097,"y":559,"w":24,"h":23,"proposed_name":"small_blob","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":19,"x":912,"y":567,"w":43,"h":30,"proposed_name":"dark_crab","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":20,"x":966,"y":566,"w":57,"h":34,"proposed_name":"pink_squid_flat","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S4","index":21,"x":1128,"y":565,"w":25,"h":25,"proposed_name":"tiny_blob","category":"enemy"},
{"sheet":"0f2ce34a","section":"A1-S5","index":0,"x":1181,"y":33,"w":349,"h":194,"proposed_name":"bg_harbour_town_day","category":"background","note":"plate edges from alpha at x=1185/1500; plate 1 top is the art edge (label pill above it, y 8-32)"},
{"sheet":"0f2ce34a","section":"A1-S5","index":1,"x":1181,"y":230,"w":349,"h":187,"proposed_name":"bg_void_cavern_bridge","category":"background","note":"plate edges from alpha at x=1185/1500; plate 1 top is the art edge (label pill above it, y 8-32)"},
{"sheet":"0f2ce34a","section":"A1-S5","index":2,"x":1181,"y":419,"w":349,"h":189,"proposed_name":"bg_void_portal_cavern","category":"background","note":"plate edges from alpha at x=1185/1500; plate 1 top is the art edge (label pill above it, y 8-32)"},
{"sheet":"0f2ce34a","section":"A1-S5","index":3,"x":1181,"y":609,"w":349,"h":196,"proposed_name":"bg_island_fortress_sea","category":"background","note":"plate edges from alpha at x=1185/1500; plate 1 top is the art edge (label pill above it, y 8-32)"},
{"sheet":"0f2ce34a","section":"A1-S5","index":4,"x":1181,"y":808,"w":349,"h":202,"proposed_name":"bg_guild_hall_interior","category":"background","note":"plate edges from alpha at x=1185/1500; plate 1 top is the art edge (label pill above it, y 8-32)"},
{"sheet":"0f2ce34a","section":"A1-S7","index":0,"x":559,"y":645,"w":57,"h":49,"proposed_name":"ice_crescent_slash","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":1,"x":593,"y":655,"w":34,"h":35,"proposed_name":"fire_slash_small","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":2,"x":636,"y":640,"w":67,"h":102,"proposed_name":"fire_burst_fused_stack","category":"vfx","note":"fused"},
{"sheet":"0f2ce34a","section":"A1-S7","index":3,"x":711,"y":645,"w":46,"h":49,"proposed_name":"arcane_ring_blue","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":4,"x":765,"y":645,"w":37,"h":83,"proposed_name":"ice_crystal_plus_diamond_fused","category":"vfx","note":"fused"},
{"sheet":"0f2ce34a","section":"A1-S7","index":5,"x":559,"y":699,"w":88,"h":43,"proposed_name":"blue_comet_arc","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":6,"x":714,"y":696,"w":39,"h":42,"proposed_name":"blue_star_spark","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":7,"x":753,"y":735,"w":50,"h":45,"proposed_name":"void_dark_orb","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":8,"x":559,"y":749,"w":31,"h":32,"proposed_name":"blue_orb_ring","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":9,"x":593,"y":749,"w":54,"h":28,"proposed_name":"purple_streak","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":10,"x":655,"y":747,"w":35,"h":34,"proposed_name":"pink_starburst","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":11,"x":703,"y":746,"w":38,"h":36,"proposed_name":"orange_burst_small","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":12,"x":559,"y":785,"w":87,"h":22,"proposed_name":"sliver_pair_fused","category":"vfx","note":"fused"},
{"sheet":"0f2ce34a","section":"A1-S7","index":13,"x":669,"y":787,"w":51,"h":22,"proposed_name":"purple_sliver","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":14,"x":732,"y":790,"w":69,"h":45,"proposed_name":"purple_ground_ellipse","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":15,"x":615,"y":802,"w":46,"h":50,"proposed_name":"dark_purple_slash","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":16,"x":673,"y":811,"w":48,"h":37,"proposed_name":"smoke_puff_grey","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":17,"x":561,"y":816,"w":46,"h":32,"proposed_name":"blue_dagger_slash","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":18,"x":645,"y":847,"w":40,"h":61,"proposed_name":"fire_flame","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":19,"x":557,"y":854,"w":42,"h":63,"proposed_name":"ice_orb_glow","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":20,"x":610,"y":855,"w":25,"h":59,"proposed_name":"blue_needle_slash","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":21,"x":695,"y":850,"w":47,"h":60,"proposed_name":"grey_smoke_cloud","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":22,"x":749,"y":852,"w":57,"h":55,"proposed_name":"purple_shard_cloud","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":23,"x":639,"y":915,"w":36,"h":50,"proposed_name":"pink_flame_wisp","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":24,"x":685,"y":923,"w":34,"h":38,"proposed_name":"void_ring_black_hole","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":25,"x":728,"y":919,"w":16,"h":46,"proposed_name":"blue_sparkle_column","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":26,"x":750,"y":916,"w":18,"h":20,"proposed_name":"sparkle_white_a","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":27,"x":778,"y":915,"w":19,"h":21,"proposed_name":"sparkle_white_b","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":28,"x":561,"y":928,"w":66,"h":60,"proposed_name":"void_nebula_burst","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":29,"x":751,"y":942,"w":16,"h":22,"proposed_name":"sparkle_blue_c","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":30,"x":772,"y":943,"w":25,"h":23,"proposed_name":"orange_spark","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":31,"x":643,"y":969,"w":20,"h":33,"proposed_name":"ice_crystal_small","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":32,"x":671,"y":972,"w":16,"h":27,"proposed_name":"blue_drop","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":33,"x":696,"y":969,"w":24,"h":33,"proposed_name":"dark_crystal_small","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":34,"x":732,"y":972,"w":28,"h":29,"proposed_name":"orange_sparkle","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S7","index":35,"x":770,"y":974,"w":25,"h":24,"proposed_name":"pink_sparkle","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S8","index":0,"x":839,"y":645,"w":17,"h":17,"proposed_name":"bubble_dots_a","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":1,"x":866,"y":645,"w":17,"h":17,"proposed_name":"bubble_dots_b","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":2,"x":894,"y":645,"w":16,"h":17,"proposed_name":"bubble_exclaim","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":3,"x":921,"y":645,"w":17,"h":17,"proposed_name":"bubble_face","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":4,"x":950,"y":646,"w":16,"h":17,"proposed_name":"icon_round_a","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":5,"x":975,"y":647,"w":15,"h":16,"proposed_name":"icon_round_b","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":6,"x":1000,"y":647,"w":14,"h":15,"proposed_name":"icon_round_c","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":7,"x":1024,"y":648,"w":15,"h":15,"proposed_name":"icon_round_d","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":8,"x":1051,"y":647,"w":17,"h":16,"proposed_name":"icon_round_e","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":9,"x":1124,"y":647,"w":17,"h":16,"proposed_name":"heart_red","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":10,"x":838,"y":668,"w":19,"h":21,"proposed_name":"head_ginger","category":"npc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":11,"x":865,"y":667,"w":19,"h":22,"proposed_name":"head_brown","category":"npc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":12,"x":893,"y":667,"w":18,"h":22,"proposed_name":"head_black","category":"npc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":13,"x":920,"y":668,"w":19,"h":22,"proposed_name":"head_grey","category":"npc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":14,"x":951,"y":670,"w":19,"h":20,"proposed_name":"icon_round_f","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":15,"x":1086,"y":670,"w":23,"h":21,"proposed_name":"loot_sack","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S8","index":16,"x":979,"y":672,"w":18,"h":17,"proposed_name":"icon_round_g","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":17,"x":1007,"y":672,"w":16,"h":18,"proposed_name":"icon_round_h","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":18,"x":1033,"y":672,"w":17,"h":18,"proposed_name":"icon_round_i","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":19,"x":1058,"y":672,"w":18,"h":18,"proposed_name":"icon_round_j","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":20,"x":1122,"y":672,"w":20,"h":20,"proposed_name":"potion_blue","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S8","index":21,"x":846,"y":705,"w":13,"h":15,"proposed_name":"ember_small","category":"vfx"},
{"sheet":"0f2ce34a","section":"A1-S8","index":22,"x":849,"y":714,"w":56,"h":48,"proposed_name":"raider_ginger_downed","category":"raider","note":"the only downed/KO pose on either sheet"},
{"sheet":"0f2ce34a","section":"A1-S8","index":23,"x":910,"y":707,"w":18,"h":19,"proposed_name":"zzz_sleep","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":24,"x":951,"y":705,"w":28,"h":27,"proposed_name":"bubble_dots_large","category":"misc"},
{"sheet":"0f2ce34a","section":"A1-S8","index":25,"x":1003,"y":713,"w":68,"h":35,"proposed_name":"rubble_pile_skull","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S8","index":26,"x":1074,"y":705,"w":15,"h":16,"proposed_name":"orb_small","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S8","index":27,"x":1102,"y":708,"w":38,"h":42,"proposed_name":"treasure_heap_small","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S8","index":28,"x":917,"y":742,"w":34,"h":38,"proposed_name":"campfire","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S8","index":29,"x":979,"y":766,"w":38,"h":31,"proposed_name":"stone_dome","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S8","index":30,"x":1039,"y":758,"w":93,"h":61,"proposed_name":"campfire_circle_with_raiders","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S8","index":31,"x":846,"y":786,"w":82,"h":44,"proposed_name":"loot_table_gold","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S8","index":32,"x":949,"y":799,"w":25,"h":24,"proposed_name":"campfire_small","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S9","index":0,"x":841,"y":878,"w":42,"h":71,"proposed_name":"banner_red_skull","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S9","index":1,"x":889,"y":878,"w":40,"h":65,"proposed_name":"banner_blue_skull","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S9","index":2,"x":1023,"y":878,"w":42,"h":66,"proposed_name":"banner_crimson_skull","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S9","index":3,"x":1071,"y":878,"w":40,"h":68,"proposed_name":"banner_black_skull","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S9","index":4,"x":1116,"y":878,"w":39,"h":70,"proposed_name":"banner_green_skull","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S9","index":5,"x":937,"y":880,"w":36,"h":62,"proposed_name":"banner_navy_skull","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S9","index":6,"x":980,"y":880,"w":37,"h":60,"proposed_name":"banner_purple_skull","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S9","index":7,"x":856,"y":955,"w":13,"h":41,"proposed_name":"wall_torch_a","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S9","index":8,"x":887,"y":957,"w":13,"h":39,"proposed_name":"wall_torch_b","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S9","index":9,"x":916,"y":954,"w":13,"h":42,"proposed_name":"wall_torch_c","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S9","index":10,"x":944,"y":951,"w":21,"h":45,"proposed_name":"stone_pillar_small","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S9","index":11,"x":977,"y":958,"w":29,"h":37,"proposed_name":"crest_shield_gold","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S9","index":12,"x":1019,"y":957,"w":28,"h":38,"proposed_name":"crest_shield_orange","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S9","index":13,"x":1060,"y":957,"w":29,"h":39,"proposed_name":"crest_shield_black","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S6","index":0,"x":13,"y":668,"w":35,"h":28,"proposed_name":"chest_blue","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":1,"x":54,"y":668,"w":28,"h":26,"proposed_name":"chest_red","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":2,"x":87,"y":668,"w":33,"h":28,"proposed_name":"chest_brown","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":3,"x":125,"y":668,"w":36,"h":30,"proposed_name":"chest_navy","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":4,"x":224,"y":665,"w":43,"h":32,"proposed_name":"table_small","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":5,"x":273,"y":662,"w":27,"h":37,"proposed_name":"barrel_tall","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":6,"x":307,"y":662,"w":62,"h":41,"proposed_name":"bookshelf_tall","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":7,"x":378,"y":662,"w":51,"h":35,"proposed_name":"hedge_box","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":8,"x":434,"y":662,"w":42,"h":35,"proposed_name":"crate_stack","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":9,"x":168,"y":674,"w":18,"h":20,"proposed_name":"orb_small","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":10,"x":193,"y":672,"w":23,"h":25,"proposed_name":"barrel_small","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":11,"x":483,"y":675,"w":46,"h":31,"proposed_name":"bench","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":12,"x":13,"y":699,"w":54,"h":45,"proposed_name":"bookshelf_wide","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":13,"x":76,"y":700,"w":38,"h":42,"proposed_name":"cabinet","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":14,"x":390,"y":702,"w":32,"h":35,"proposed_name":"barrel_round","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":15,"x":432,"y":700,"w":22,"h":35,"proposed_name":"barrel_c","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":16,"x":465,"y":700,"w":19,"h":34,"proposed_name":"chair_a","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":17,"x":121,"y":704,"w":23,"h":32,"proposed_name":"crate","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":18,"x":150,"y":705,"w":54,"h":40,"proposed_name":"gold_pile_table","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":19,"x":211,"y":705,"w":65,"h":42,"proposed_name":"table_long","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":20,"x":283,"y":708,"w":32,"h":34,"proposed_name":"barrel_d","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":21,"x":321,"y":714,"w":32,"h":24,"proposed_name":"keg_stack","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":22,"x":361,"y":704,"w":21,"h":31,"proposed_name":"barrel_tall_b","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":23,"x":493,"y":709,"w":37,"h":34,"proposed_name":"chair_b","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":24,"x":11,"y":746,"w":68,"h":153,"proposed_name":"rubble_plus_oak_tree_fused","category":"prop","note":"fused"},
{"sheet":"0f2ce34a","section":"A1-S6","index":25,"x":77,"y":750,"w":41,"h":27,"proposed_name":"bench_low","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":26,"x":126,"y":747,"w":22,"h":34,"proposed_name":"barrel_e","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":27,"x":159,"y":751,"w":42,"h":28,"proposed_name":"fence","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":28,"x":211,"y":751,"w":43,"h":36,"proposed_name":"cot","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":29,"x":264,"y":750,"w":22,"h":33,"proposed_name":"stool","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":30,"x":295,"y":747,"w":23,"h":35,"proposed_name":"barrel_f","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":31,"x":325,"y":742,"w":55,"h":42,"proposed_name":"table_red_cloth","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":32,"x":388,"y":748,"w":28,"h":36,"proposed_name":"chair_c","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":33,"x":418,"y":743,"w":21,"h":35,"proposed_name":"pole","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":34,"x":448,"y":741,"w":28,"h":19,"proposed_name":"debris_small","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":35,"x":487,"y":743,"w":24,"h":45,"proposed_name":"ladder","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":36,"x":523,"y":745,"w":7,"h":44,"proposed_name":"post","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":37,"x":441,"y":767,"w":37,"h":21,"proposed_name":"rubble_small","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":38,"x":138,"y":783,"w":39,"h":72,"proposed_name":"pine_a","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":39,"x":184,"y":783,"w":37,"h":69,"proposed_name":"pine_b","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":40,"x":76,"y":786,"w":56,"h":72,"proposed_name":"tree_autumn_orange","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":41,"x":229,"y":794,"w":73,"h":60,"proposed_name":"rock_pile_grey","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":42,"x":306,"y":788,"w":79,"h":132,"proposed_name":"tree_oak_large_fused","category":"prop","note":"fused"},
{"sheet":"0f2ce34a","section":"A1-S6","index":43,"x":394,"y":786,"w":32,"h":47,"proposed_name":"lantern_post","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":44,"x":430,"y":786,"w":18,"h":40,"proposed_name":"post_b","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":45,"x":456,"y":798,"w":24,"h":28,"proposed_name":"rock_a","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":46,"x":485,"y":799,"w":25,"h":24,"proposed_name":"rock_b","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":47,"x":494,"y":792,"w":36,"h":72,"proposed_name":"stone_well","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":48,"x":415,"y":831,"w":34,"h":34,"proposed_name":"rock_d","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":49,"x":388,"y":837,"w":23,"h":28,"proposed_name":"rock_c","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":50,"x":455,"y":833,"w":29,"h":66,"proposed_name":"hanging_banner_red","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":51,"x":85,"y":862,"w":48,"h":38,"proposed_name":"bush_a","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":52,"x":166,"y":859,"w":39,"h":28,"proposed_name":"bush_small","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":53,"x":243,"y":850,"w":104,"h":157,"proposed_name":"bush_cluster_plus_pier_fused","category":"prop","note":"fused"},
{"sheet":"0f2ce34a","section":"A1-S6","index":54,"x":141,"y":870,"w":20,"h":38,"proposed_name":"sapling","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":55,"x":200,"y":867,"w":69,"h":55,"proposed_name":"bush_berries","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":56,"x":366,"y":870,"w":27,"h":35,"proposed_name":"barrel_stone","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":57,"x":399,"y":867,"w":14,"h":37,"proposed_name":"stake","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":58,"x":420,"y":866,"w":29,"h":38,"proposed_name":"pillar_stone","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":59,"x":492,"y":869,"w":40,"h":35,"proposed_name":"campfire_glow","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":60,"x":10,"y":903,"w":125,"h":98,"proposed_name":"stone_arch_gate","category":"tile"},
{"sheet":"0f2ce34a","section":"A1-S6","index":61,"x":11,"y":903,"w":21,"h":20,"proposed_name":"flower_a","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":62,"x":38,"y":902,"w":31,"h":20,"proposed_name":"flower_b","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":63,"x":138,"y":899,"w":100,"h":108,"proposed_name":"bridge_wood_arch","category":"tile"},
{"sheet":"0f2ce34a","section":"A1-S6","index":64,"x":358,"y":911,"w":65,"h":93,"proposed_name":"rowing_boat","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":65,"x":433,"y":911,"w":37,"h":90,"proposed_name":"ice_crystal_statue","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S6","index":66,"x":479,"y":907,"w":55,"h":92,"proposed_name":"boat_dock_long","category":"tile"},
{"sheet":"0f2ce34a","section":"A1-S1","index":0,"x":9,"y":38,"w":451,"h":201,"proposed_name":"ground_wall_tiles_grid_9x4","category":"tile","note":"pseudo-grid: nominal 50x50 cells, origin 9,38, 9 cols x 4 rows; measured seams are irregular (x 48,83,103,229,272,318,387,421,436; y 117,145,179,237) so cut with slice.py grid --origin 9,38 --cell 50x50 --count 9x4 and hand-trim"},
{"sheet":"0f2ce34a","section":"A1-S1","index":1,"x":11,"y":243,"w":46,"h":57,"proposed_name":"wall_window_arch_a","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":2,"x":61,"y":240,"w":50,"h":60,"proposed_name":"wall_window_b","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":3,"x":118,"y":242,"w":44,"h":58,"proposed_name":"wall_tower_narrow","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":4,"x":168,"y":242,"w":47,"h":58,"proposed_name":"wall_window_lit","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":5,"x":219,"y":240,"w":54,"h":61,"proposed_name":"wall_door_dark","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":6,"x":276,"y":248,"w":37,"h":60,"proposed_name":"banner_pole_red_a","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S1","index":7,"x":315,"y":243,"w":59,"h":64,"proposed_name":"roof_slate_corner","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":8,"x":379,"y":245,"w":47,"h":61,"proposed_name":"hedge_bush_round","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":9,"x":428,"y":247,"w":33,"h":60,"proposed_name":"banner_pole_red_b","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S1","index":10,"x":11,"y":304,"w":64,"h":49,"proposed_name":"rope_pulley_frame","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":11,"x":79,"y":305,"w":29,"h":46,"proposed_name":"lantern_post_a","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":12,"x":115,"y":304,"w":80,"h":66,"proposed_name":"stone_arch_gate_b","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":13,"x":209,"y":305,"w":22,"h":31,"proposed_name":"sign_small_a","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":14,"x":249,"y":305,"w":22,"h":31,"proposed_name":"sign_small_b","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":15,"x":275,"y":318,"w":25,"h":49,"proposed_name":"banner_short_red","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S1","index":16,"x":359,"y":311,"w":101,"h":59,"proposed_name":"fence_panel_wood_a","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":17,"x":302,"y":320,"w":29,"h":47,"proposed_name":"banner_short_navy","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S1","index":18,"x":337,"y":320,"w":17,"h":48,"proposed_name":"pole_iron","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":19,"x":189,"y":339,"w":76,"h":116,"proposed_name":"tent_red_plus_cart_fused","category":"building","note":"fused"},
{"sheet":"0f2ce34a","section":"A1-S1","index":20,"x":10,"y":358,"w":99,"h":162,"proposed_name":"stone_tower_wall_plus_wreath_fused","category":"building","note":"fused"},
{"sheet":"0f2ce34a","section":"A1-S1","index":21,"x":81,"y":358,"w":29,"h":26,"proposed_name":"lantern_small","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":22,"x":87,"y":373,"w":94,"h":94,"proposed_name":"round_tower_slate_roof","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":23,"x":163,"y":374,"w":22,"h":18,"proposed_name":"sign_c","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":24,"x":271,"y":377,"w":51,"h":71,"proposed_name":"banner_purple_tall","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S1","index":25,"x":327,"y":376,"w":66,"h":84,"proposed_name":"banner_pair_purple_fused","category":"banner","note":"fused"},
{"sheet":"0f2ce34a","section":"A1-S1","index":26,"x":397,"y":373,"w":63,"h":83,"proposed_name":"gate_dark_wood","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":27,"x":310,"y":393,"w":12,"h":40,"proposed_name":"pole_b","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":28,"x":208,"y":419,"w":75,"h":141,"proposed_name":"chapel_tower_fireplace_fused","category":"building","note":"fused"},
{"sheet":"0f2ce34a","section":"A1-S1","index":29,"x":11,"y":443,"w":28,"h":73,"proposed_name":"shelf_pillar_lit","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":30,"x":143,"y":445,"w":61,"h":113,"proposed_name":"fireplace_hearth_plus_campfire_fused","category":"prop","note":"fused"},
{"sheet":"0f2ce34a","section":"A1-S1","index":31,"x":298,"y":442,"w":20,"h":29,"proposed_name":"lantern_b","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":32,"x":366,"y":462,"w":18,"h":24,"proposed_name":"sign_d","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":33,"x":385,"y":463,"w":74,"h":34,"proposed_name":"low_wall_navy_roof","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":34,"x":115,"y":472,"w":24,"h":31,"proposed_name":"sign_hanging","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":35,"x":279,"y":474,"w":45,"h":28,"proposed_name":"anvil_table","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":36,"x":327,"y":467,"w":39,"h":50,"proposed_name":"barrel_hut_round","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":37,"x":11,"y":510,"w":129,"h":81,"proposed_name":"fence_wall_long_plus_gear_fused","category":"building","note":"fused"},
{"sheet":"0f2ce34a","section":"A1-S1","index":38,"x":275,"y":509,"w":34,"h":79,"proposed_name":"campfire_stone_pit","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":39,"x":374,"y":503,"w":87,"h":84,"proposed_name":"hut_open_front_lit","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":40,"x":11,"y":522,"w":43,"h":35,"proposed_name":"crate_low","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":41,"x":311,"y":522,"w":10,"h":69,"proposed_name":"pole_c","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":42,"x":324,"y":520,"w":47,"h":57,"proposed_name":"shelf_cabinet_tall","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":43,"x":93,"y":568,"w":47,"h":25,"proposed_name":"fence_short","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":44,"x":144,"y":568,"w":46,"h":53,"proposed_name":"banner_red_skull_hanging","category":"banner"},
{"sheet":"0f2ce34a","section":"A1-S1","index":45,"x":193,"y":570,"w":78,"h":55,"proposed_name":"table_long_wood","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":46,"x":322,"y":582,"w":59,"h":43,"proposed_name":"ledger_desk","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":47,"x":407,"y":591,"w":52,"h":34,"proposed_name":"fence_iron","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":48,"x":11,"y":598,"w":104,"h":27,"proposed_name":"wall_low_stone","category":"building"},
{"sheet":"0f2ce34a","section":"A1-S1","index":49,"x":119,"y":599,"w":22,"h":26,"proposed_name":"barrel_g","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":50,"x":275,"y":595,"w":17,"h":30,"proposed_name":"vase_a","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":51,"x":297,"y":597,"w":21,"h":28,"proposed_name":"barrel_small_b","category":"prop"},
{"sheet":"0f2ce34a","section":"A1-S1","index":52,"x":385,"y":592,"w":18,"h":33,"proposed_name":"vase_b","category":"prop"},
{"sheet":"0718af5b","section":"A2-S2","index":0,"x":497,"y":20,"w":150,"h":104,"proposed_name":"void_colossus_core","category":"boss","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":1,"x":643,"y":45,"w":36,"h":77,"proposed_name":"void_tentacle_a","category":"boss","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":2,"x":444,"y":64,"w":21,"h":57,"proposed_name":"void_tentacle_b","category":"boss","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":3,"x":471,"y":64,"w":29,"h":58,"proposed_name":"void_tentacle_c","category":"boss","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":4,"x":717,"y":80,"w":24,"h":42,"proposed_name":"void_tentacle_d","category":"boss","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":5,"x":475,"y":140,"w":34,"h":44,"proposed_name":"abomination_b","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":6,"x":512,"y":142,"w":25,"h":38,"proposed_name":"abomination_c","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":7,"x":538,"y":141,"w":53,"h":42,"proposed_name":"abomination_d_winged","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":8,"x":594,"y":142,"w":23,"h":36,"proposed_name":"abomination_e","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":9,"x":618,"y":143,"w":41,"h":37,"proposed_name":"abomination_f","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":10,"x":437,"y":144,"w":34,"h":41,"proposed_name":"abomination_a","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":11,"x":482,"y":191,"w":97,"h":75,"proposed_name":"stone_golem_boss","category":"boss","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":12,"x":591,"y":206,"w":49,"h":54,"proposed_name":"stone_golem_mid","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":13,"x":648,"y":214,"w":37,"h":46,"proposed_name":"stone_golem_small","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":14,"x":694,"y":229,"w":31,"h":30,"proposed_name":"stone_golem_runt","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":15,"x":462,"y":277,"w":34,"h":40,"proposed_name":"skeleton_a","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":16,"x":499,"y":281,"w":26,"h":36,"proposed_name":"skeleton_b","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":17,"x":527,"y":278,"w":26,"h":39,"proposed_name":"skeleton_c","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":18,"x":600,"y":281,"w":28,"h":36,"proposed_name":"skeleton_d","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":19,"x":656,"y":278,"w":30,"h":38,"proposed_name":"skeleton_e","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":20,"x":454,"y":334,"w":53,"h":32,"proposed_name":"slime_pink_a","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":21,"x":566,"y":332,"w":54,"h":33,"proposed_name":"slime_pink_c","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":22,"x":527,"y":339,"w":33,"h":25,"proposed_name":"slime_pink_b","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":23,"x":674,"y":336,"w":33,"h":26,"proposed_name":"slime_pink_d","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":24,"x":456,"y":381,"w":54,"h":57,"proposed_name":"clockwork_construct_a","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":25,"x":518,"y":377,"w":59,"h":60,"proposed_name":"clockwork_construct_b","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":26,"x":591,"y":381,"w":59,"h":55,"proposed_name":"clockwork_construct_c","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-S2","index":27,"x":650,"y":376,"w":47,"h":65,"proposed_name":"clockwork_construct_d","category":"enemy","note":"keyed white thresh 70; edges soft"},
{"sheet":"0718af5b","section":"A2-B1","index":0,"x":0,"y":571,"w":513,"h":274,"proposed_name":"bg_guild_hall_interior_a2","category":"background","note":"island-exact, white thresh 60"},
{"sheet":"0718af5b","section":"A2-B2","index":0,"x":514,"y":571,"w":508,"h":273,"proposed_name":"bg_world_map_overworld","category":"background","note":"island-exact, white thresh 60"},
{"sheet":"0718af5b","section":"A2-B3","index":0,"x":1024,"y":571,"w":512,"h":273,"proposed_name":"bg_raid_void_realm","category":"background","note":"island-exact, white thresh 60"},
{"sheet":"0718af5b","section":"A2-B4","index":0,"x":0,"y":846,"w":512,"h":178,"proposed_name":"bg_camp_outpost","category":"background","note":"island-exact, white thresh 60"},
{"sheet":"0718af5b","section":"A2-B5","index":0,"x":514,"y":846,"w":508,"h":178,"proposed_name":"bg_dungeon_cave","category":"background","note":"island-exact, white thresh 60"},
{"sheet":"0718af5b","section":"A2-B6","index":0,"x":1024,"y":846,"w":512,"h":178,"proposed_name":"bg_forest_wilderness","category":"background","note":"island-exact, white thresh 60"}
]
```

## 4. Bosses and VFX
### 4.1 Bosses

| Sheet | Island | Rect (x,y,w,h) | Read | Notes |
|---|---|---|---|---|
| A1 | void_eye_tentacle_boss | 904,36,259,154 | purple/indigo mass of tentacles around one glowing eye, red-lit underbelly | This is the sheet's "Void Colossus". Widest boss; at 259x154 it fits the Concept 2 arena (boss zone about 420 px wide) at 1:1 with room. Pixel fidelity is the best on either sheet - crisp 1-px cluster edges. |
| A1 | crystal_golem_boss | 906,188,138,109 | grey stone golem with cyan crystal shoulders / core | Clean silhouette. Would sit at 1:1 as an Elite / Mini Boss. |
| A1 | crimson_wyvern_boss | 907,301,254,124 | wings-spread red wyvern, yellow throat | Wing tips are 1-px soft; body good. |
| A1 | sludge_maw_leviathan | 1061,361,99,119 | dark blue-green round maw, white fangs, red gums | Closest match to Concept 2's "Sludge Maw" but 99x119 is small for a Main Boss; scale 2x would read as chunky against 1:1 raiders. Use as Mini Boss or redraw larger. |
| A2 | void_colossus_core (+4 tentacle islands) | 497,20,150,104 core; tentacles 643,45,36,77 / 444,64,21,57 / 471,64,29,58 / 717,80,24,42 | same creature as A1's, walking on two legs, magenta core | A2 fragments it because the checker key eats the thin tentacle joins. Softer edges than A1; prefer A1. |
| A2 | stone_golem_boss | 482,191,97,75 | grey humanoid golem, orange joints | Plus three shrinking variants 49x54, 37x46, 31x30 - a ready size ladder for Trash / Elite / Mini Boss. Soft edges. |

Size ladder available for canon's Trash / Elite / Mini Boss / Main Boss (`data/encounters_t1.json`): A1 blobs 24-44 px (Trash), spiders 61-67 px (Elite), leviathan 99-138 px (Mini Boss), void eye / wyvern 254-259 px (Main Boss). A1 also has one fused pair of brown brutes (1050,199,58,103; split at y = 250) and an armoured ogre (1098,206,62,78) that read as "Elite".

### 4.2 VFX (A1-S7, 36 islands)

All 36 are **standalone stills**, not frames: no two islands share a silhouette at a different phase, and the row layout groups by *colour family*, not by sequence. Confidence high. Colour ramps (dominant hues read at 3x):

| Family | Islands | Shape / ramp | Use |
|---|---|---|---|
| Ice / blue | ice_crescent_slash 559,645,57,49; blue_comet_arc 559,699,88,43; blue_orb_ring 559,749,31,32; blue_dagger_slash 561,816,46,32; ice_orb_glow 557,854,42,63; blue_needle_slash 610,855,25,59; ice_crystal_small 643,969,20,33; blue_drop 671,972,16,27; arcane_ring_blue 711,645,46,49; blue_star_spark 714,696,39,42; ice_crystal_plus_diamond_fused 765,645,37,83 | white core, `#9FD8FF`-ish mid, `#3B6FE0` rim | Mage / Wizard cast, Cleric heal ring |
| Fire / orange | fire_slash_small 593,655,34,35; fire_burst_fused_stack 636,640,67,102 (fire burst + orange streak + purple burst, three sprites fused - split at y = 690 and 718); orange_burst_small 703,746,38,36; fire_flame 645,847,40,61; orange_spark 772,943,25,23; orange_sparkle 732,972,28,29 | white-yellow core, orange, red rim | Warrior hit, campfire |
| Void / purple | purple_streak 593,749,54,28; pink_starburst 655,747,35,34; void_dark_orb 753,735,50,45; sliver_pair_fused 559,785,87,22 (blue + purple slivers); purple_sliver 669,787,51,22; purple_ground_ellipse 732,790,69,45; dark_purple_slash 615,802,46,50; purple_shard_cloud 749,852,57,55; pink_flame_wisp 639,915,36,50; void_ring_black_hole 685,923,34,38; void_nebula_burst 561,928,66,60; dark_crystal_small 696,969,24,33; pink_sparkle 770,974,25,24 | magenta core, `#7B2FD8` mid, near-black `#1A0A2E` rim | boss attacks, Shaman / Druid; matches Concept 2's void arena |
| Smoke / grey | smoke_puff_grey 673,811,48,37; grey_smoke_cloud 695,850,47,60 | grey-blue 3-step | death poof, dust |
| Sparkles | blue_sparkle_column 728,919,16,46 (two sparkles fused vertically); sparkle_white_a/b 750,916 / 778,915; sparkle_blue_c 751,942,16,22 | 4-point white/blue | item glints, crit marker |

The purple_ground_ellipse (69x45) is the only ground-projected effect; it is the natural "targeted" marker for the raid view. A2-S8 (FX & Misc, 696,452,347,116) repeats the same three families as 3 rows of ~12 bursts at lower fidelity - not inventoried; A1 supersedes it.

## 5. Quality verdict per canon class
Blunt version: **A1 gives usable idle sprites for four of the nine canon classes; nothing here animates; A2 adds names but not usable pixels.**

| Canon class | Source on these sheets | Sprite px | Fidelity at 1:1 | Verdict |
|---|---|---|---|---|
| Warrior | A1-S2 rows y 41/95 (10 idles; sword in cols 1-2); portrait 479,37; A1-S8 downed pose 849,714,56,48; A2 Warrior + Berserker rows | 25-31 x 41 | Good - crisp 1-px edges, readable skull face and orange hair at the Concept 1 card scale (the concept's Bork is the same design). | **Usable.** Idle + downed only; walk/attack/cast must be drawn in Aseprite. |
| Monk | none labelled; A1-S2 unlabelled knight rows y 514/559 or A2 Berserker row could be recoloured | 25-31 x 42 | Good (A1) | **Gap.** Recolour the knight or draw. |
| Rogue | A1-S2 Ranger rows y 145/190 (olive hood, 00 §2.2 mapping) **and** Rogue rows y 424/466 (black hood); A2 Ranger + Thief rows | 24-31 x 38-39 | Good (A1); A2 soft | **Usable, twice over.** Pick black-hood for canon Rogue; keep olive-hood as the fixture's Tiny. |
| Cleric | A1-S2 rows y 336/380; portrait 479,320; A2 Cleric row | 25-33 x 41 | Good | **Usable** (idle only). |
| Druid | none | - | - | **Gap.** Nearest palette base: Ranger olive. |
| Shaman | none | - | - | **Gap.** |
| Bard | A2 Bard row only (y about 345, 9 sprites) | about 22 x 38 | Poor - blurred, colour-bled, checker halo | **Not usable as pixels**; use as a costume reference only. |
| Mage | A1-S2 rows y 235/280; portrait 487,242; A2 Mage row | 27-39 x 44 (hat brim) | Good | **Usable** (idle only). |
| Wizard | none; palette-swap of Mage (robe navy -> another hue) | as Mage | Good | **Derivable** in Aseprite from Mage. |

Non-canon rows (Ranger, Thief, Berserker, Engineer on A2; Ranger on A1) are harvested per 00 §2.2 or dropped; Engineer is dropped.

Scale check against the concepts: Concept 2's combatants stand about 40-48 px tall in the arena and Concept 1's card portraits are about 64 px; the A1 sprites (38-44 px) sit at 1:1 in the arena without scaling, and the A1 portraits (41-57 x 59-82) fit the card slot at 1:1. The A1-S3 variations (21-25 x 31-40) are a ready 4-hair-colour recolour set for the tavern candidate board's anonymous recruits. Nothing on either sheet should be scaled by a non-integer factor; A2 sprites should not be scaled at all because their edges are already 2-3 px soft.

Animation is the real gap: **zero** walk / attack / cast / hurt frames on either sheet (A2's three attack-ish poses are unusable). Production must author, per fielded class, at minimum idle (have), attack, hurt, down (have one, Warrior-coloured) - 8 canon classes x 3 missing states.

## 6. Keying thresholds
These settings reproduce every island rect in §3 exactly.

**A1** (`0f2ce34a`, RGBA, 77 % of pixels alpha 0): `--key alpha --thresh 16` (foreground = alpha > 16). The sheet's alpha is essentially binary at sprite edges (1-px AA fringe at alpha 40-200), so thresholds 8-64 give identical bounding boxes; 16 is kept because it is the tool default and the `cut` step re-reads it from the manifest. `--min-area 30` for the raider region (smallest true sprite is 550 px area), `--min-area 40` elsewhere, `--min-area 60` for the buildings block. Regions used: raiders `470,36,420,575`; monsters `900,36,275,570`; VFX `548,640,275,375`; anim `829,640,345,200`; misc `829,872,345,140`; environment `8,662,535,355`; buildings `9,240,455,392`. The tile block `9,38,451,201` is one island and is cut with `grid --origin 9,38 --cell 50x50 --count 9x4`. Background plates are cut by rect, not by island (they touch each other; alpha edges at x 1185: 7/227/230/417/419/608/609/805/808/1010).

**A2** (`0718af5b`, RGB, no alpha). The background is a *painted* checker, not white: light squares lum 238-245, dark squares about 225, and there is contamination down to lum 190 within 3 px of sprites and to lum 86 inside busy rows. `slice.py`'s white key is `lum < 255 - thresh`, so:
- `--thresh 60` (lum < 195) isolates the six background plates exactly (6 islands at `--min-area 15000`); it also works for the large bosses.
- `--thresh 70` (lum < 185) is the setting used for A2-S2 enemies (`--region 396,20,355,428 --min-area 400`, then drop islands with w*h <= 800 which are checker noise); it fragments thin tentacles and drops white highlights (skull faces on skeletons lose a few pixels) but gives 28 clean bodies.
- The raider rows (A2-S1) were **not** sliced: at thresh 70 the light-grey armour and skull-white faces fall out with the checker, at thresh 40 the checker's dark squares join sprites into row-long islands. If A2 raiders are ever cut, key on chroma (saturation > 0.12 or |R-G|+|G-B| > 24) rather than luminance - a `--key chroma` would need adding to `slice.py`. Given §5, this is not worth doing.
- Label pills on A2 are lum < 90 boxes, 12-16 px tall, but sit on the same noise; detect them by mean luminance of a 12-row window, not by single pixels.

Crops referenced above (scratch, regenerable with `refkit.py crop`): `a1_warrior.png` 540,36,210,110 @5x; `a1_ranger.png` 540,140,210,100 @5x; `a1_var.png` 750,36,140,100 @5x; `a1_mon.png` 900,36,275,570 @2x; `a1_vfx.png` 548,640,275,375 @3x; `a1_animmisc.png` 829,640,345,380 @3x; `a1_env.png` 8,662,535,355 @2x; `a1_build.png` 9,240,455,392 @2x; `a2_tl.png` 0,0,400,130 @3x; `a2_enemies.png` 392,0,359,448 @2x.
