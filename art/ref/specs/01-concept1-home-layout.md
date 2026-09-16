# 01 — Concept 1 (HOME / GUILD HALL) pixel-exact layout

> **Status:** Measured (all 8 sections; radii and the CTA notch are read from 2–6× crops, everything else from row/column scans) · **Source:** `ideaboard/Reference Concepts/Reference Concept 1.png` (1536×1024, 1:1 = target framebuffer) · **Kit:** `tools/art/refkit.py`
> **Read first:** `00-canon-reconciliation.md`. Every canon conflict below is cited to that file, not re-argued.

All rects are `x, y, w, h` in framebuffer pixels (also Godot layout px). Hexes are sampled from the PNG; where the reference is an AI-mockup artifact it is called out and a clean resolution proposed.

## 1. Global frame

The page is a single dark ground with five regions. There is **no** single bottom-strip panel: the bottom region is bare ground holding six independent panels (§3, §4) whose top edges align at y=734.

| Region | Rect (x, y, w, h) | Boundary pixels (measured) |
|---|---|---|
| Page ground | 0, 0, 1536, 1024 | fill `#050E15` (sampled y=1000; also `#040B12` right gutter, `#081017` left). Darkest ground `#0B1118`-class — no pure black. |
| **Header bar** | 0, 0, 1536, 74 | fill `#0B131A` (x=700, y=60–72). **Divider**: 1px dark `#1C1917` at y=73, 2px bronze at **y=74–75**, 1px dark `#251E1B` at y=76. Line runs x=103→1523 (left of x=103 the emblem overprints it; right gutter x≥1524 is ground). Bronze colour drifts along the line (`#7C6251` over the scene, `#4F494B` grey over nav/sidebar) — mockup artifact; **use one hex `#7A6152`**. |
| **Nav rail** | 0, 77, 207, 640 | fill `#0A1016`. Right edge border x=207–209: `#1F1E1F` / **`#463E3E`** / `#262323` (core x=208). Rail bottom is the shared horizontal line at y=717–718 (see below). No left or top border of its own. |
| **Central scene viewport** | 210, 77, 929, 640 | art begins x=210 (y=400: x=210–211 `#020406` inner dark seam, art from 212). Sky begins y=78 at x=1000 (y=77 `#020814` seam). Right edge: art ends x=1136, dark seam 1137–1138, thin bronze `#523E35` at x=1139–1140, dark x=1141. Bottom: art ends y=713, dark seam 714–716. **Implementation: TextureRect at 210,77 929×640 with a 1px `#020406` inset stroke**; the bronze at 1139–1140 is the sidebar's outer glow, not a scene frame. |
| **Shared horizontal rule** | 0, 717, 1536, 2 | y=717–718, full width, `#3E332F` (warm, under scene) → `#303032` (grey, under nav) → `#393534` (under sidebar). Mockup drift; **use `#3B3532`**. It is the bottom edge of nav + scene, and passes *under* the sidebar panel (the sidebar's own bottom border ends at y=713). |
| **Right sidebar panel** ("Current Raid") | 1142, 79, 378, 635 | outer border left x=1142–1144 (`#181312`, **`#6C5346`**, `#6C5346`), right x=1517–1519 (`#151415`, **`#4C4746`**, `#3A3838`), top y=79–81 (`#452D1C`, **`#83542E`**, `#482E1E`), bottom y=711–713 (`#23140F`, `#6F3E23`, **`#814E2F`**). An inner 2px line sits 5px inside (top y=84–85 `#52463E`/`#564F4C`; bottom y=706–707 `#54524F`/`#423E3E`). Fill `#060E17` (x=1300, y=87–109). Right of the panel x=1520–1535 is page ground (16px gutter). Detail in §2. |
| **Bottom region** | 0, 719, 1536, 305 | bare ground `#050E15`. Panels sit at y=734 (top border core y=735) and end y=995 (bottom border core y=994) — see §3/§4. Left gutter 0–12, right gutter 1514–1535. |

**Column summary (x):** nav 0–206 · rail border 207–209 · scene 210–1138 · seam 1139–1141 · sidebar 1142–1519 · gutter 1520–1535.
**Row summary (y):** header 0–73 · divider 74–75 · nav/scene 77–716 · rule 717–718 · bottom region 719–1023 (panels 734–995).

Border-width note: the mockup's line weights wobble between 2 and 3 px around the same panel. The *core* pixel is always 1 px and bright, flanked by 1 px darker on each side — implement every panel border as **1px core + 1px darker inner + 1px darker outer = 3px**, or as a 2px `StyleBoxFlat` border with the brighter hex; either matches within 1px.

## 2. Right sidebar — "Current Raid" panel

**Outer:** rect **1142, 79, 378, 635**. Radius ≈8 (read from 2× crop; all four corners rounded, not chamfered). Fill `#060E17`. Border: 3px, core `#83542E` (top) / `#6C5346` (left) / `#4C4746` (right) / `#814E2F` (bottom) — the mockup lights the top-left warm bronze and the right grey; **use `#7A5A42` core with `#1B1512` flanks**. Inner line: 2px `#54524F`/`#423E3E` inset 5px (top y=84–85, bottom y=706–707; not visible on the left/right sides at y=300 — mockup; draw it on all four sides). Glow: a 2px `#523E35` haze on the scene side at x=1139–1140 — implement as a 2px outer shadow of the border colour at 40% alpha, or skip.

Content column: children are left-aligned at **x=1176** (text) / **x=1175** (slot borders) and the wide cards span **x=1162–1501** (w=340). Panel padding: 20 left, 18 right, 26 top (title cap top y=105).

| Child | Rect / metrics | Colour |
|---|---|---|
| **Section title** "Current Raid" | glyph bbox x=1176–1294, cap top y=105, baseline **y=121** (cap 17 → ~24px font, semibold) | `#F0E4D2`, peak `#FFFFFA` |
| **Boss art card** | rect **1162, 132, 339, 161**; border 1px core `#444247` top / `#373842` bottom, flanked dark; radius ≈6 | fill `#070E1B` |
| ↳ art | **1163, 133, 337, 116** (y=133–248) | — |
| ↳ bottom scrim | gradient of `#070E1B` from α0 at y=225 → α≈0.85 at y=248 (sample y=235–248 `#0E1225`), then **solid `#070E1B` y=249–291 (h=43)** | — |
| ↳ title "The Sludge Maw" | x=1176, cap top 245, baseline **260**, descender to 265 (cap 16 → ~22px, semibold) | `#EEE3D2` |
| ↳ subtitle "Aberration" | x=1176, cap top 270, x-height 274, baseline **282** (cap 13 → ~17px) | `#97989A` |
| **"Potential Rewards"** label | x=1176, cap top 313, baseline **324** (cap 12 → ~16px) | `#9EB2C5` pale steel |
| **4 item slots** | size **47×47**, y=335–381; x = **1175, 1232, 1288, 1344** (pitch 56, gap 9 — mockup jitters 56/57). Border 1px core `#3A373A`→`#5B4B45` warm grey (flanks `#222223`/`#1C1E23`), radius ≈4 | fill `#10151B` |
| ↳ rarity note | all four borders are the same neutral grey here; rarity tinting per `04-palette.md` is applied by the implementation, not read from this reference | — |
| **"Estimated Success Chance" callout** | rect **1164, 392, 337, 82** (y=392–473) | fill: horizontal gradient `#08090D` (x≤1400) → `#1B0F16` (1404) → `#2A1118` (1430) → `#361319` (1498) — i.e. flat dark for 70% then a red bloom toward the right edge |
| ↳ border | top 1px `#62181A` (y=393), bottom 2px `#701D20` (y=472–473), left: none visible; **right edge 2px `#BA302D` at x=1499–1500 running y=385–468** (starts 7px above the box — it is the flourish's tail) | — |
| ↳ corner flourish | top-right, bbox ≈ **1487, 385, 16, 25** — a small torn-banner/leaf shape in `#B93030` overlapping the box's top-right corner. Mockup decoration; **resolve as a 12×12 45° triangle of `#BA302D` outside the corner**, or omit. | `#B93030` |
| ↳ label | "Estimated Success Chance" x=1176, cap top 407, baseline **419** (cap 13 → ~17px) | `#E1CAAF` |
| ↳ **17%** figure | x=1176–1231, top 432, baseline **456** (digit height 25 → ~34px bold) | `#EC4039`, peak `#FD5747` |
| **"Raid Team"** label | x=1176, cap top 491, baseline **504** (cap 14 → ~19px) | `#8D8C8D` |
| **4 portrait slots** | size **56×58** (normalise to 56×56), y=517–574; x = **1174, 1237, 1300, 1363** (pitch 63, gap 7). Border 3px (core bright): slot1 `#7C6454` bronze, slot2 `#715F55`, slot3 `#4E5256`, slot4 `#595859` — mockup drift; use `#5A4E47` (leader slot may use bronze). Radius ≈4 | fill `#0E1016` |
| **"Team" gear button** | rect **1426, 517, 64, 58**; border core `#675549`/`#6B5142`; gear glyph 17×17 at ≈1450,527 in `#8D8B89`; label "Team" x=1442–1473, cap 555–565 (~14px) | label `#B8B0AC`, fill `#0D151D` |
| **"Edit Team"** link | centred on x≈1330; gear icon **1286, 587, 16, 17**; text x=1308–1373, cap top 588, baseline **600** (~17px) | `#AFABA9`, peak `#E6E6E5` |
| **"Send Them Anyway" CTA** | rect **1179, 617, 305, 70** (x=1179–1483, y=617–686) | see below |
| ↳ outer border | 2px: sides `#C93F36` (x=1180–1181 / 1481–1482); top lit gold `#FCB85D`/`#E69451` (y=618–619); bottom `#D56240`/`#F27043` (y=683–684) with `#A54732` at 685. Mockup lighting; **resolve: 2px `#C9453A`, plus a 1px `#FCB85D` highlight on the top edge only** | — |
| ↳ inner border | 1px `#E7705E` at inset 4 (y=622), with 1px `#4A262B` gap between it and the outer | — |
| ↳ fill gradient (vertical) | y=624 `#5B1D26` → y=653 `#33131C` → y=670 `#250A11` → y=680 `#4A1621` (bottom lip lifts). Stops: 0% `#5B1D26`, 55% `#33131C`, 80% `#250A11`, 100% `#4A1621` | — |
| ↳ notch | corners are 45° chamfers, ≈5px (10px at 2×) on the outer stroke; inner stroke follows | — |
| ↳ label | "Send Them Anyway" x=1248–1416 (centred x=1332), cap top 632, baseline **646**, descender 650 (cap 15 → ~20px bold) | `#F8F5E4` |
| ↳ cost sub-line | coin icon **1291, 658, 17, 17** (gold `#FBEC74`/`#E6AF5D` disc, dark `#743F17` ring); text "2,400" x=1318–1359, digit top 660, baseline **672** (~16px) | `#CDAA73`, peak `#FBD480` |
| ↳ artifact | a stray `)` glyph at x≈1366–1372 after the number is an AI-text artifact. **Drop it.** Render `{cost} G` per the header's gold chip format (`60 G` is a test-asserted string). | — |

Canon notes (cite, don't re-argue): title/subtitle = `title` (🔷 optional) or `display_name` / `kind` per 00 §2.3; "Raid Team" shows 4 of the 12-slot party and pages per 00 §2.4; the success percentage is a display of whatever `RaidResolver` exposes and is not a canon number.

## 3. Roster card anatomy (bottom strip)

Four cards on bare ground. All offsets below are for **card 1 (Bork)**, origin **(140, 734)**; the other three are translated copies.

**Card rect:** 140, 734, **217×262** (x=140–356, y=734–995). Measured edges of all four: left x = **140, 366, 589, 813**; right x = 356, 579, 802, 1027 → widths 217/214/214/215, pitch 226/223/224. Mockup jitter; **build: w=215, h=262, pitch 224 (gap 9), x = 140, 364, 588, 812.** Radius ≈6 (top border begins at x=144 for a left edge at 140). Fill `#020C14` → `#031018`. Border 1px core, lit: top `#A1866F` (y=735), bottom `#484443` (y=994), left `#4C494C`, right `#515053`, flanks `#2B2C31`. **Use core `#514D4C` everywhere, with the bronze `#A1866F` top edge as an optional 1px highlight.**

| Element | Rect / metrics (card 1 absolute) | Offset from card origin | Colour |
|---|---|---|---|
| **Portrait frame** | x=155–244?, y=744–837; left border core x=156 `#3F434B`, faint right edge x=243–244 `#403D41`; top y=744, bottom y=837 (sprite feet). Read as **155, 744, 90, 94**, radius ≈6 | (15, 10) | border `#3F434B`, fill `#0B141F` |
| ↳ portrait sprite | 64-class bust, drawn at 1:1 inside the frame, feet clipped by frame bottom; occupies ≈ x=166–253, y=746–837 (overflows the frame's right edge by ~9px in the mockup — clip to frame) | — | — |
| **Name** "Bork" | x=261, cap top 753, baseline **765** (cap 13 → ~18px bold) | (121, 31) | `#EDE3D3`, peak `#FFFEF5` |
| **Level** "Lv. 12" | x=260, top 774, baseline **785** (12 → ~16px) | (120, 51) | `#B3ACA3` |
| **Class glyph** (crossed swords) | **259, 797, 15, 12** | (119, 63) | `#7E6B6A`→`#A3B9C8` |
| **Class label** "Warrior" | x=277–322, cap top 797, baseline **808** (11 → ~15px) | (137, 74) | `#6D7C8A`, peak `#A3B9C8` |
| **Morale row (garbled)** | icon: blue face/pot **178, 846, 27, 19**; **bar 205–323 × 853–861 (119×9)** with a left→right gradient `#1A7BC5` → `#21ACF3` → `#07A0B1` → `#2DB188` → `#3DBB51`; the word "Morale:" in white is overprinted on the bar at y=848–855; a second illegible line ("Morlle: F…") sits at y=863–873, x=189–267, `#ACA8A5`. | (38, 112) | — |
| ↳ **canon replacement** | Per **00 §2.1** the bar is forbidden and "Low"/no-number is non-canon. Keep the row *position* (y=846–873, two lines) and *language* (face glyph left, coloured state word), but render `Bork — 87 ❤` (line 1, glyph and number ≥ name size, i.e. ≥18px) and `Warrior — Very Happy` (line 2, ~15px) coloured by `Palette.morale_color()`; the number precedes the glyph; band names only from `Enums.MORALE_BAND_NAMES`. **No bar.** The freed bar colour ramp (`#1A7BC5`→`#3DBB51`) may seed the morale colour ramp in `04-palette.md`. | — | — |
| **Quote** "I got this." | x=222–288 (centred x≈255 — card centre is 248; mockup drift, centre it), cap top 887, baseline **897** (11 → ~15px, italic-weight light) | (—, 153) | `#8F9FA9`, peak `#C4CCD1` |
| **3 equipment slots** | size **47×48** (normalise **47×47**, same component as the sidebar item slot), y=929–976; x = **171, 226, 282** (pitch 55.5 → use 171, 227, 283, pitch 56, gap 9); the trio is centred on the card (span 171–328, centre 249.5). Border 1px core `#313944`/`#454A56` blue-grey (slots 1–2), `#6E5E51`/`#4B4746` warm (slot 3 — a rarity tint), radius ≈4 | (31, 195) | fill `#0B151E` |

Other three cards (for the fixture): Tiny / Lv. 11 / Ranger→**Rogue** (00 §2.2) / "Morale: Low" red text (again non-canon, 00 §2.1) / "I hope they don't have water…"; Gruk / Lv. 9 / Cleric / green bar / "I'll just try to believe in this."; Spoof / Lv. 10 / Mage / "Morale: Low" red / "I'll just try my best… I guess". Class-label colours per card: Warrior steel `#6D7C8A`, Ranger green (`#5F6A48`-class art), Cleric grey, Mage violet (`#544F66`-class art) — the implementation takes class colour from `04-palette.md`. `Lv. N` shows only when `level > 0` (00 §2.3). Twelve raiders page in fours (00 §2.4).

## 4. "Available 7" mini-grid and "Recent Events" log

### 4.1 "Available" panel (bottom-left)

- **Panel rect: 13, 734, 110, 262** (x=13–122, y=734–995). Border 1px core: left `#232C32`/`#272F33`, right `#5E5958`/`#7B6863`, top `#4A4848` (y=735), bottom `#1C282D` (y=994–996, faint). Same height and border scheme as the roster cards (§3) — use the same style; corners chamfered ≈5px (top-right notch visible at 3×).
- **Header:** "Available" x=27, cap top **750**, baseline **763** (cap 13–14 → ~18px bold), `#DCD2BC`, peak `#FFFDF4`. Count "7" right of it at x≈101–110, same baseline, dim `#6D7C8A`-class grey. (The grid shows 8 portraits under a "7" — mockup inconsistency; the count is data.)
- **Inner grid frame:** 1px `#29333D`/`#303234` at x=26–27 and 104–105, top y=773–774, bottom ≈y=990 → **26, 773, 80, 218**. Its left/right lines coincide with the outer cell borders — treat the frame as the cells' container with 0 horizontal padding and 11px top padding.
- **Cells:** **37×37**, 2 columns × 4 rows. x = **26, 69** (pitch 43, gap 6); y = **785, 829, 872, 916** (pitch 43.7). **Build: pitch 44 both axes** (x = 26, 70; y = 785, 829, 873, 917). Border 1px core `#35393E`/`#383F42`, radius ≈4, fill `#0F151E`. Portrait busts are drawn at 1:1 and overflow the cell by 1–3px in the mockup — clip to the cell.

### 4.2 "Recent Events" log (bottom-right)

- **Panel rect: 1045, 734, 474, 264** (x=1045–1518, y=734–997; bottom border core y=997 `#4B4648`). Two pixels taller than the cards — **unify at y=995**. Border 1px core `#373940` left, `#3B3A3D` right, `#484649` top. Radius ≈6; top-right corner shows a small chamfer in the 2× crop.
- **Header:** "Recent Events" x=1070, cap top **752**, baseline **763** (~18px bold), `#DECEBF`, peak `#FFFFFA`.
- **Header rule:** 1px `#434044` at **y=775**, x=1053–1504 (inset 8 left; fades 1505–1516), flanked `#27282D`/`#1E2329`.
- **Rows:** 7 rows. Text baselines **799, 828, 856, 885, 914, 942, 971** → pitch **28.67**; **build pitch 29** (baseline₀ = 799). Text x=**1100**, cap top = baseline − 10, x-height 7–8, descender +3 (→ ~15px regular). Colour `#ACA8A7`, peak `#EEE8E2`. Row 1 text: "Gruk returned from a failed mission. (0/3 survived)" spans x=1101–1425.
- **Badge:** circle **18×18** at x=**1070**, vertically centred on the row (row 1: y=786–804; row centre = baseline − 4). Colours by event type (fill / highlight): failure & mishap **red** `#E44434` / `#F97C64` (rows 1, 4); mood **blue-violet** `#6377A7` / `#9DA7E0` (row 2); recruit / level / gold **gold** `#E1923F` / `#F4C066` (rows 3, 5, 7); loot **yellow-green** `#819351` / `#B2B251` (row 6). Each badge carries a 1-colour glyph: sad face, dizzy face, person, sad face, up-arrow, item, coin.
- **Scrollbar:** track **1500, 787, 4, 193** (x=1500–1503). Segment y=787–827 `#1B2630`, y=836–979 `#3A4756`; the 2× crop reads the *top* 60px as the thumb. Mockup ambiguity — **build: 4px track `#1B2630`, thumb `#485968`, radius 2**, thumb length proportional.

Rows are `Label`s (test constraint, 00 §3). Event strings shown are fixture text; `Recruit`/`gold` wording follows the game's own event log.

## 5. Header

Bar: 0, 0, 1536, 74, fill `#0B131A`, divider at y=74–75 (§1).

**Emblem** (skull over crossed weapons, pixel art): bbox **22, 15, 82, 57** (x=22–103, y=15–71); its lower spikes overprint the divider down to y=75 at x=33–35, 53–56, 71–75. Palette: bone `#F9F1D7` highlights, mid `#9F8D7E`, shadow `#564D49`. Reserve **20, 12, 88, 64** for the sprite.

**Wordmark** "A Guild Story": glyph bbox **104, 20, 256, 41** (x=104–359). 'T' cap top **y=20**, baseline **y=60** → cap height **41px** (display blackletter-ish serif, ~56px). Lowercase x-height ≈22 (x-height line y≈38). Metallic fill, vertical: top highlight `#F9F4E5`→`#F0DBC0` (y≈20–30), mid band `#C6AF98`/`#C8AF96` (y≈36–45), lower `#DABB9C`, bottom edge lightens again to `#E6CBB3`. Outline **1px `#413D3A`** (dark warm grey; not black). Left edge of 'T' sits 1px right of the emblem bbox — treat emblem+wordmark as one lockup at x=22, spacing 0.

**Resource chips** (4), all vertically centred on the bar: pill height **45** at **y=15–59** (chip 4 is 47 tall, y=14–60, because of its heavier border). Gaps 24/26/25 → **build gap 24**. Text baseline **y=45**, cap top **y=30** (digit height 15–16 → ~21px semibold); icon box 26–29px square at y≈20–47, icon left edge 18px inside the chip, text starts 15–17px after the icon.

| # | Rect (x, y, w, h) | Chrome | Icon rect | Text | Text colour |
|---|---|---|---|---|---|
| 1 gold | **857, 15, 146, 45** | full-radius pill (r=22), fill `#030B13`, 1px edge `#172229` (barely visible) | coin **875, 21, 26, 26** — gold disc `#F4BF5E`/`#EDB862`, rim `#B2712F`, dark `#7B5027` | "12,480" x=916–977 | `#E4C9AA`, peak `#F9EBD0` |
| 2 gem | **1024, 15, 122, 45** | same pill, fill `#01070E`–`#020A17`, no visible edge | gem **1036, 21, 27, 26** — violet `#592EBC`/`#B882F2`, white facet `#F9F0FD`, cyan sheen `#D5EDFA` | "320" x=1078–1111 | `#A597F3` violet, peak `#BCB6F9` |
| 3 book | **1171, 15, 121, 45** | same pill, fill `#010911`, **lit top edge 1px `#A2968F` at y=15**, bottom `#22262C` | book **1181, 22, 23, 26** — cream pages `#F9DFC3`, brown spine `#BC946C`/`#592A20` | "8/12" x=1223–1261 | `#A09EA0` grey, peak `#B5B1B1` |
| 4 day | **1316, 14, 205, 47** | **2px bronze border `#816B5B`** (outer `#473F39`, inner `#4C4039`), 45° chamfers ≈6px on all four corners, fill `#020B12` | sun **1332, 20, 29, 27** — `#FBC64A` core, `#E0913C` rays | "Day 23" x=1373–1433 · "16:40" x=1459–1506 | `#A5A4A7` grey, peak `#C3BFC0` |

Artifacts: a tiny "◂" glyph at x≈1310–1315 left of chip 4 is an AI artifact (hallucinated stepper) — drop. The right edge of chip 4 (x=1520) overhangs the sidebar's right edge (1519) by 1px — align both at 1519.

Canon mapping (00 §2.5, cite): chip 1 = gold (`"60 G"` is a test-asserted string, so the label is `{n} G`, rendered in a `Label`); chip 2 = Reputation (gem icon kept); chip 3 = raiders available / raid size (`8/12`, party = 12 ✅); chip 4 = `Day N · {rank}` — the `16:40` clock and sun icon are replaced by the rank sigil per 00 §2.5; `Day 1` and `Unknown` are asserted strings.

## 6. Nav rail

Rail: 0, 77, 207, 640 (§1), fill `#0A1016`, right border core x=208 `#463E3E`. Seven items, top-aligned; no bottom items.

**Pitch: 55px.** Row rects: **0, 105 + 55·k, 210, 55** (k = 0…6 → y = 105, 160, 215, 270, 325, 380, 435). Measured label baselines (glyph-bottom of the non-descending letters): **140, 195, 250, 306, 360, 414, 469** → build **baseline = 140 + 55·k** (140, 195, 250, 305, 360, 415, 470; max drift 1px). Labels are vertically centred in the row (row centre = 132.5 + 55k; cap centre ≈ baseline − 7).

| Element | Rect / metrics | Inactive | Active (Home) |
|---|---|---|---|
| Icon | bbox x=**22–51** (26–30 wide, centre x=36–37), 22–29 tall, centred on the row centre. Measured: Home **22, 118, 30, 22** · Recruit **24, 180, 26, 23** · Roster **22, 229, 30, 28** · Gear **23, 284, 28, 28** · Missions **23, 340, 28, 27** · Reports **24, 393, 27, 29** · Options **23, 448, 28, 29**. Reserve **20, rowY+12, 32, 32** | `#7E8184`–`#838386`, peak `#A5A6A5` | `#E8CFAE`, peak `#FCF6DC` (warm bone) |
| Label | x=**73**, cap top = baseline − 14/15, cap 14–15 → **~19–20px semibold**; strings: Home, Recruit, Roster, Gear, Missions, Reports, Options | `#9B9A9D` (samples `#97979B` `#9B9A9D` `#9E9DA0`), peak `#F1EFEA` | `#F0E3D2`, peak `#FFFFFC` |
| **Active pill** | rect **0, 105, 211, 55** (x=0–210, y=105–159). Flush to the rail's left edge; its right edge (x=209–210) sits *on* the rail border, 1–2px past it. | — | fill: horizontal gradient `#0C1823` (x=0) → `#11212E` (x=74) → `#152837` (x=146) → `#20384B` (x≈200); vertical component negligible (`#11222F` top → `#10202E` bottom). Border **2px**: top `#47677F` (y=106–107), bottom `#4E7C9A`/`#3C5C74` (y=157–158), right `#447992`/`#4B83A3` (x=209–210); none on the left. Under-glow 3px `#050B11` at y=160–162. |
| ↳ corner notches | top-right and bottom-right corners are 45° chamfers ≈**7px** (the border steps x=203→210 across y=105→113); left corners square (flush). | — | — |
| ↳ left accent bar | **none in this reference** — the pill runs to x=0 with no bright bar. If the kit wants one, take the 2px `#4E7C9A` border colour, 4px wide, x=0–3. | — | — |

Hover state is not shown; propose the active gradient at 40% alpha with no border.

Canon (00 §2.6, cite): the seven labels become Town, Tavern, Roster, Market, Adventure's Board, Records, Settings; chrome unchanged; the list is variable-length (Concept 3 has six). "Adventure's Board" at ~20px semibold is the widest label (≈170px) — it fits x=73–200 only at ≤18px; **either drop the rail label size to 18px or let the label clip at the pill edge x=203**; `03-concept3-camp-layout.md` measures the same rail and should confirm the pitch.

## 7. Central scene

**Viewport rect: 210, 77, 929, 640** (x=210–1138, y=77–716) — see §1 for the seams. The scene is a two-storey tavern interior (balcony with a red skull banner and notice board upstairs; bar counter, fireplace, long table and a doorway/arch to the town on the right, downstairs). The scene plate is a single 929×640 painted background with sprites composited over it; the plate is not sliced in this pass.

**Speech / emote bubble** (5 instances found by cream-component search; a 6th hit at 346,426 17×15 `#FDFDD8` is a lamp, not a bubble):

| # | bbox (x, y, w, h) | note |
|---|---|---|
| 1 | 848, 131, 33, 32 | "…" ellipsis; balcony, under the notice board |
| 2 | 604, 311, 33, 32 | "…" ellipsis; over the bar counter |
| 3 | 821, 472, 34, 35 | glyph bubble; right end of the long table |
| 4 | 476, 487, 37, 37 | glyph bubble (pennant); left end of the long table |
| 5 | 1015, 575, 35, 36 | face glyph; doorway on the right |

Anatomy (from #1 at 6×): **body 33×26** (x=848–880, y=131–156), corners rounded ≈3px in pixel steps, **fill `#EED0AB`** (top row lighter `#F9E3BA`, bottom row shaded `#C0AB8E`), **outline 1px `#1A1512`** (near-black warm; not `#000`), **tail** 6px tall at bottom-left pointing down-left (tip ≈ x=856, y=162). Glyph slot ≈16×12 centred in the body; the ellipsis is three 3×3 `#2A2320` squares at 5px pitch. The mockup draws the bubble at 33–37px — **build one 33×32 sprite** and never scale it. Anchor rule: tail tip = sprite head-top − 4px; body horizontally centred on the sprite's centre + 8px.

**Spawn points** (approximate, from the 0.5× overview; `x, y` is the feet centre, sprites are ~48px tall so head-top ≈ y − 44):

| Zone | Points |
|---|---|
| Balcony (upstairs walkway, y≈190–240) | (300, 190) · (660, 190) · (866, 215) ← bubble #1 |
| Bar counter (behind/at the bar, y≈370–380) | (476, 380) · (622, 380) ← bubble #2 · (700, 372) · (780, 372) |
| Fireplace (left) | (250, 490) |
| Long table (centre) | (494, 560) ← bubble #4 · (680, 490) · (750, 510) · (838, 560) ← bubble #3 · (570, 600) |
| Right side / doorway | (960, 530) · (1032, 640) ← bubble #5 |
| Foreground | (430, 600) · (500, 650) · (690, 660) |

Z-order: sort by feet y. Balcony sprites are clipped by the balcony rail plate (a foreground overlay strip at y≈226–255 across x=210–1138, per the grid bands at y=226/255). The scene shows ~19 figures; canon's roster cap is 15–20 by rank (00 §2.4), so every rostered raider can be placed — assign spawn points in roster order and leave the rest empty.

## 8. Icon inventory

Every distinct icon on the screen, with its measured rect (x, y, w, h) and the reserve size to author it at. Portraits, the boss art and the scene plate are not icons and are excluded.

| # | Icon | Rect | Author at | Description / colours |
|---|---|---|---|---|
| 1 | Guild emblem | 22, 15, 82, 57 | 88×64 | Skull over crossed weapons, bone `#F9F1D7` → `#9F8D7E` → `#564D49`; spikes overprint the header divider |
| 2 | Gold coin (header) | 875, 21, 26, 26 | 26×26 | Disc `#F4BF5E`/`#EDB862`, rim `#B2712F`, shadow `#7B5027`, embossed face |
| 3 | Gem (header) | 1036, 21, 27, 26 | 26×26 | Violet crystal `#592EBC`/`#B882F2`, white facet `#F9F0FD`, cyan sheen `#D5EDFA` |
| 4 | Book / ledger (header) | 1181, 22, 23, 26 | 26×26 | Cream pages `#F9DFC3`, brown spine `#BC946C`, dark `#592A20` |
| 5 | Sun (header) | 1332, 20, 29, 27 | 28×28 | `#FBC64A` core, `#E0913C` rays — replaced by the rank sigil (00 §2.5) |
| 6 | Nav: Home | 22, 118, 30, 22 | 32×32 | House outline, active colour `#E8CFAE` |
| 7 | Nav: Recruit | 24, 180, 26, 23 | 32×32 | Rising figure/arrow; inactive `#7E8184` |
| 8 | Nav: Roster | 22, 229, 30, 28 | 32×32 | Two busts side by side |
| 9 | Nav: Gear | 23, 284, 28, 28 | 32×32 | Helmet / armour piece in a ring |
| 10 | Nav: Missions | 23, 340, 28, 27 | 32×32 | Skull with crossed picks |
| 11 | Nav: Reports | 24, 393, 27, 29 | 32×32 | Scroll/clipboard with lines |
| 12 | Nav: Options | 23, 448, 28, 29 | 32×32 | Cog |
| 13 | Class glyph: Warrior | 259, 797, 15, 12 | 16×16 | Crossed swords, `#7E6B6A`→`#A3B9C8` (one per canon class → 9 needed) |
| 14 | Morale face (card) | 178, 846, 27, 19 | 24×24 | Blue face/pot `#1A7BC5`/`#54BAE9`; canon wants a face glyph per band (00 §2.1) |
| 15 | Equipment: sword | 171, 929, 47, 48 (slot) | 40×40 in a 47 slot | Steel blade `#D2D4DC`, wrapped grip `#746F6D` |
| 16 | Equipment: chest armour | 226, 929, 47, 48 (slot) | 40×40 | Plate `#999BA1`/`#A9A4A8`, dark seams |
| 17 | Equipment: satchel/backpack | 282, 929, 47, 48 (slot) | 40×40 | Leather `#D07838`/`#B56A34`, straps `#662F1F` |
| 18 | Reward: sword | 1175, 335, 47, 47 (slot) | 40×40 | As 15 |
| 19 | Reward: green tunic | 1232, 335, 47, 47 (slot) | 40×40 | Cloth `#456D4E`/`#3D604E` |
| 20 | Reward: violet crystal | 1288, 335, 47, 47 (slot) | 40×40 | `#8955AF`/`#EABFF1`, peak `#D8A3ED` |
| 21 | Reward: gold coin (large) | 1344, 335, 47, 47 (slot) | 40×40 | `#FBBE56`/`#DC9B52`, `#FEE697` glint |
| 22 | Gear cog (Team button) | ≈1450, 527, 17, 17 | 16×16 | `#8D8B89` |
| 23 | Gear cog (Edit Team) | 1286, 587, 16, 17 | 16×16 | `#BFBDBC`; same asset as 22 |
| 24 | Coin (CTA cost) | 1291, 658, 17, 17 | 16×16 | `#FBEC74`/`#E6AF5D`, ring `#743F17`; 16px version of 2 |
| 25 | Event badge: failure (sad face) | 1070, 786, 18, 18 | 18×18 | Red `#E44434`, highlight `#F97C64`, dark glyph |
| 26 | Event badge: mood (dizzy face) | 1070, 815, 18, 18 | 18×18 | Blue-violet `#6377A7`/`#9DA7E0` |
| 27 | Event badge: recruit (person) | 1070, 843, 18, 18 | 18×18 | Gold `#E1923F`/`#F4C066` |
| 28 | Event badge: level-up (arrow) | 1070, 901, 18, 18 | 18×18 | Gold, as 27 |
| 29 | Event badge: loot (item) | 1070, 930, 18, 18 | 18×18 | Yellow-green `#819351`/`#B2B251` |
| 30 | Event badge: gold spent (coin) | 1070, 959, 18, 18 | 18×18 | Gold, as 27 |
| 31 | Speech bubble "…" | 848, 131, 33, 32 | 33×32 | Cream `#EED0AB`, outline `#1A1512`, tail bottom-left (§7) |
| 32 | Emote glyphs (in bubble) | ≈16×12 slot | 16×16 | Ellipsis, pennant, face — one sheet |
| 33 | Red corner flourish (callout) | 1487, 385, 16, 25 | 16×24 | `#B93030` torn-banner shape; optional (§2) |
| 34 | Scrollbar thumb | 1500, 787, 4, 60 | 4×N | `#485968` on `#1B2630` (§4.2) |

Counts for the production phase: 7 nav icons, 5 header/currency icons (4 + small coin), 9 class glyphs (1 shown), ≥10 morale faces (1 shown), 6 event badges, 6 item icons (4 rewards + 2 unique equipment), 1 bubble + a glyph sheet, 2 cogs (1 asset), 1 emblem. Item-slot chrome (47×47, §2/§3) and portrait-slot chrome (56×56, §2) are `StyleBoxFlat`, not icons.
