# 02 — Concept 2 (RAID / COMBAT) pixel-exact layout spec

> **Status:** Measured (all 10 sections) · **Owner:** Art pass · **Updated:** 2026-09-09
> **Input:** `ideaboard/Reference Concepts/Reference Concept 2.png` (1536×1024, 1:1 = one image px per game px; every coordinate below is a Godot layout coordinate).
> **Reconciliation:** `00-canon-reconciliation.md` governs. Named boss "Void Colossus 48,532 / 120,000" is fixture data (§2.3); "Ranger" = Rogue (§2.2); four combatant panels page in fours over the 12-slot party (§2.4). Not re-litigated here.

Method: every rect is `x, y, w, h` in image px; hexes are sampled with `tools/art/refkit.py px/row/col`. Where the reference is an AI-mockup artifact it is called out and a clean resolution is proposed.

---

## 0. Frame and what replaces the nav rail / resource chips

Concept 2 has **no nav rail and no resource chips**. The left 122 px column that Concept 1 gives to the rail is scene here; the header row is only the emblem + wordmark (§4). What replaces them:

| Concept 1 element | Concept 2 replacement | Where |
|---|---|---|
| Nav rail (left column) | **Combatant strip** — four panels + combat log, full width | §1, §2 — `y 735..1024`, the bottom 289 px |
| Resource chips (header right) | **Boss health plate** (top-centre) and **minimap** (top-right) | §3, §6 |
| Header mission line | **Objective block** under the wordmark, left | §4 |
| — | **Cog + fast-forward** pair, bottom-left of the stage, just above the strip | §8 |

Frame: 1536×1024. The strip is a full-width plate: rect `0, 735, 1536, 289`; fill `#050D1A` (samples `#000E1C`–`#081422`); a 2 px top edge line at `y 736..737`, `#272F3B` (the strip's bevel; the scene above ends with a 1 px near-black seam `#00020A` at y 735). Everything above y 735 is the scene viewport with world-space overlays — there is no framed "stage" panel (§7).

Godot: `RaidScreen` is a `Control` filling the viewport; the strip is a `PanelContainer` anchored bottom with `custom_minimum_size.y = 289`; the four combatant panels and the log are children of an `HBoxContainer` with `separation = 22` (§1); the boss plate, objective block, minimap and cog pair are free-positioned children at the coordinates in §3, §4, §6, §8. Nothing here goes through the `NavRail` or `ResourceChips` components.

## 1. Bottom strip — combatant panels and combat log

### 1.1 Strip geometry and pitch

Four combatant panels then the log, left to right. Measured 1 px bright border lines (the reference drifts ±3 px between panels because it is a mockup; the *clean* column is what is built):

| Panel | Measured left border x | Measured right border x | Clean rect `x, y, w, h` |
|---|---|---|---|
| 1 Bork | 23 | 254 | `23, 741, 232, 240` |
| 2 Tiny | 277 | 514 | `277, 741, 232, 240` |
| 3 Gruk | 531 | 771 | `531, 741, 232, 240` |
| 4 Spoof | 790 | 1023 | `785, 741, 232, 240` |
| Combat log | 1044 (outer) / 1051 (inner) | 1517 | `1044, 741, 474, 240` (§2 for the reference's own y) |

- **Pitch 254 px** (23→277→531 exactly; the fourth panel is drawn 5 px late in the mockup and is corrected to 785). Gap between panel borders = 254−232 = **22 px**.
- Panel y: top border `y 741`, bottom border `y 980` → **height 240**. Margin to the strip top line: 4 px (737→741); margin to frame bottom: 43 px (980→1024) — the strip's bottom band is empty dark plate.
- Left margin 23 px; right margin after the log 1536−1518 = 18 px. `4×232 + 3×22 + 22 + 474 = 1494` → with the 23 px left margin the log ends at x 1517, matching the measurement.

### 1.2 Panel chrome

- Border: 1 px, `#4E515C` (samples `#4E515C` top-left, `#5A5E66` right, `#3D3F49` top at x 200, `#314253` bottom — the bottom edge is drawn dimmer; build one colour `#4E515C`). Corner radius **6 px** (the rounded corner spans 6 px on both axes in the top-left corner crop).
- Outer halo: a second 1 px line 5 px outside the border, `#2D313C` (x 18 / x 260; the top one merges with the strip edge line at y 736). Build as `StyleBoxFlat.shadow_size = 5`, shadow colour `#2D313C` at ~60 %.
- Fill: `#010E1C` (flat; samples `#000E1C`–`#010F1D` everywhere inside).
- Inner top hairline: 1 px `#23425C` at `y 749` (border+8) spanning the interior. It is the only inner bevel present; optional.

### 1.3 Portrait

- Portrait frame rect **`32, 750, 79, 80`** (left border x 32 `#3F5161`, top y 750, bottom y 829, right x 110); 1 px border `#3F5161`, radius 6, fill = panel fill. The portrait sprite is drawn 1:1 centred; the mockup lets hair/shoulders overflow the frame top by ~4 px — clip in the build.
- Derived padding: portrait left = border+9, top = border+9.

### 1.4 Name / level / status column (x 122 →)

| Text | bbox | Baseline | Cap height | Colour | Size |
|---|---|---|---|---|---|
| Name "Bork" | x 122..152, y 762..774 | **y 774** | 13 px | `#F6F6F2` (warm white) | 17 px sans |
| "Lv. 12" | x 122..156, y 787..797 | **y 797** | 11 px | `#9B948B` (grey) | 14 px sans |
| Buff/debuff icon row | x 122..184, y 812..825 | — | 14 px | 4 icons @ 14×14, gap 2 (pitch 16), no frames | — |

Level text is shown only when `Raider.level > 0` (00 §2.3). Text column x = portrait right + 12.

- **Top-right status slot**: a 24×24 icon cell at `227, 750, 24, 24` (bbox x 222..254 includes its 1 px frame `#6F6569`; right-aligned to border−4). Bork's shows an "X"/crossed-box (`#6F6569` on `#254860`) — an AI-mockup control with no readable meaning. **Resolution:** the slot shows the raider's current *state* glyph (Dead / Fleeing / Stunned), empty when none. The other three panels leave it empty.
- **Bork's flame icon**: bbox `230..254, 780..808` → 24×28 flame glyph, `#F6593F` core → `#BF3628` edge, brightest `#FB7052`; no frame. Sits under the status slot (slot bottom 774 → flame top 780, gap 6). Read as a "burning" DoT; build as status slot #2 in a vertical 24 px column at x 230, pitch 30.

### 1.5 HP bar and secondary bar

| | HP | Secondary (Rage/Mana/Focus) |
|---|---|---|
| Icon | shield-heart `41..49 × 840..854` (9×15), `#F7484F`, brightest `#FB5657` | wing/drop `40..49 × 866..878` (10×13), `#A0E3FD` |
| Track rect | **`61, 838, 182, 17`** — 1 px border `#112233` left / `#103449` top / `#2C3F5C` right / `#042740` bottom; inside `#0A090D`→`#000714` | **`61, 862, 182, 18`** — border `#15252E` top, `#113651` bottom, `#374B67` right |
| Fill inset | 2 px each side → fill rect `63, 840, 178, 14` | `63, 864, 178, 14` |
| Fill gradient (vertical) | rows 840..844 `#CB2434`→`#C72532` (top 5 px), rows 845..852 `#AD1D2C`→`#851827`→`#91131E` (bottom 8 px). **Two-band**: top `#C52232`, bottom `#861626`. | rows 864..869 `#02A1D3`→`#0197CA`, rows 870..877 `#006797`→`#006291`→`#0C6B97`. Two-band: top `#0199CC`, bottom `#00648F`. |
| Fill width | 48/128 = 37.5 % → ends x 130 (178×0.375 = 67 ✓) | 32/60 → ends ~x 158 |
| Text | "48/128": bbox x 118..157, y 841..851 → **baseline y 851**, 11 px digits, `#F5F1E8`, tabular | "32/60": x 118..151, y 865..875, baseline 875, reads `#B3F2FB` (white over cyan) — build white `#F5F1E8` |
| Text alignment | bbox centre x 137 vs track centre 151 — text sits 14 px left of centre in every panel (62/104 at 370..413 on panel 2, same offset). **AI drift; build centred on the track.** | same |

Bar row pitch: 838 → 862 = **24 px**. Bars start 9 px under the portrait frame (829→838). Icon column centre x 45 = border+22.

### 1.6 Weapon slot and ability grid

Measured 1 px borders (`#4A5261` unlit / `#5A5E6B`, radius 4):

| Cell | Measured x | Measured y | Clean rect |
|---|---|---|---|
| Weapon slot | 34..93 | 890..973 | **`34, 890, 60, 84`** |
| Ability c1 r1 | 99..137 | 890..928 | `112, 890, 38, 38` |
| c2 r1 | 148..185 | 890..928 | `158, 890, 38, 38` |
| c3 r1 | 198..242 | 890..928 | `204, 890, 38, 38` |
| r2 | 99..137 / 148..185 / 198..242 | 934..970 | y = 936 |

- **Cell 38×38, gap 8 → pitch 46 both axes** (measured column pitch 47–48 and row pitch 44 — corrected to one number). Grid width 3×38+2×8 = 130. The mockup stretches the third column to x 242 to fill the panel; instead right-align the grid so it ends at 242 = border−12 → origin `x 112`. Weapon slot spans both rows: 2×38+8 = 84 ✓ measured. Gap weapon→grid = 112−94 = 18.
- Weapon slot fill `#0C1520`; ability cell fill `#0A0F1A`; unlit cell border `#4A5261`. **Lit** cells (Bork c1 r1 yellow `#F4F197`/`#9E914C`, c2 r1 orange `#D39553`/`#985F38`) carry a 1 px border in the icon's hue (`#9A9C59` yellow, `#E2A85A` orange, `#948681` on the stack-count cell). Build: `border_color = icon dominant hue @ 80 %` when ready/active.
- **Stack-count numeral** ("3" on c3 r2; "2" on Tiny/Spoof): bbox `227..232 × 955..964` → 6×10 digit, `#F0EEEC`, bottom-right of the cell, inset 4/4 (cell bottom 970 → digit bottom 964), 1 px dark outline `#10121B`; ≈13 px bold digits.
- Grid top = bar row 2 bottom (880) + 10 px. Grid bottom 974 → 6 px above the panel border.

## 2. Combat log

Panel rect: the reference draws the log border at `x 1044 (outer, #6E6972) / 1051 (inner, #334052)`, `y 752 (top, #898383) .. 982 (bottom, #6F6267)`, right `x 1516..1518`. So it has a **double frame** — outer 1 px `#6E6972` at 1044/1517 and an inner 1 px `#334052` 7 px inside at 1051 — and its top sits 11 px lower than the combatant panels (752 vs 741). **Resolution:** align to the panels — rect `1044, 741, 474, 240`, single 1 px border `#4E515C` + the same 5 px `#2D313C` halo, radius 6; keep the inner `#334052` hairline as an optional inset (+7 px). Fill `#050D1A`.

### 2.1 Rows

Eight rows, most-recent-last. Measured text bboxes (cap top .. descender):

| Row | Text | bbox y | Baseline | Badge bbox |
|---|---|---|---|---|
| 1 | Gruk used Heavy Strike on Void Colossus for 724 damage. | 762..776 | 773 | 1070..1088 × 759..778 |
| 2 | Tiny fired a shot for 317 damage. | 789..803 | 800 | 1070..1088 × 787..805 |
| 3 | Spoof cast Arcane Bolt for 442 damage. | 816..830 | 827 | 1071..1089 × 813..831 |
| 4 | The Void Colossus used Void Slam! | 842..855 | 853 | 1068..1090 × 839..861 |
| 5 | Bork is down! | 874..885 | 885 | 1071..1087 × 871..888 |
| 6 | Tiny is bleeding! | 901..914 | 912 | 1073..1085 × 898..916 |
| 7 | Gruk gained 12 Rage. | 927..941 | 938 | 1071..1088 × 924..943 |
| 8 | Spoof gained 8 Mana. | 954..968 | 965 | 1071..1088 × 951..969 |

- **Row pitch 27 px** (measured 27, 27, 26, 30, 27, 26, 27 — the 30 is mockup drift). Baselines at `773 + 27k`. First baseline = panel border (741) + 32.
- Text: 15 px sans, 11 px cap height (digits 11), left edge `x 1112` (= badge right + 24). Longest row ends x 1471; inner right is 1510, so a row never wraps at this size — the LIVE log's ordinary rows ellipsize, never wrap; the MISTAKE header (type first) and its quote wrap to whole pitches, and the wipe REPORT's rows wrap in full, because both were measured here on short factual rows and the comedy is longer than the reference ever printed (W6-LOG, UI-19/UI-23; the docs/15 row records the reversal).
- **Badge**: a bare 20×20 glyph (no frame, no plate) at `x 1069`, vertically centred on the row (row 1: y 759..778, centre = baseline − 5). Glyphs are per-actor: Gruk = crossed axes (`#9AA0A9` steel), Tiny = crossbow (`#F6CDAC` wood), Spoof = arcane skull (`#7980E4`/`#979AEF`), boss = purple eye (`#A672C8`/`#E8AAEE`, drawn 23×23 — unify to 20), alert = red skull (`#F5514B`/`#FA3D40`) and blood drop (`#E46F62`), Rage = grey shield (`#B1B4C1`), Mana = blue drop (`#388EC0`/`#44A7D3`).

### 2.2 The three text colours

| Line class | Dominant quantized colour | Brightest AA pixel | **Build hex** |
|---|---|---|---|
| Damage / action lines (rows 1, 2) | `#D8D8D8` / `#C0C0C0` | `#CADCE6` | **`#D8DEE6`** |
| Older damage / boss action (rows 3, 4) | `#A8A8C0` / `#9090A8` | `#B3C6DC` | same class at 75 % alpha — the mockup fades rows that are not the two newest; treat as an *age* ramp (1.0, 1.0, 0.75 …), not a colour |
| **Red alerts** (rows 5, 6: "Bork is down!", "Tiny is bleeding!") | `#D83030` / `#C03030` | `#F93F37` / `#FA414A` | **`#E8453F`** (badge and text) |
| Resource-gain lines (rows 7, 8: "gained 12 Rage", "gained 8 Mana") | `#A8A8C0` / `#9090A8` | `#C6D8E3` / `#B7CEE5` | **`#A9B7C9`** (dim blue-grey, full alpha) |

Row 4 (boss ability) is not red — only *raider* harm is red. Numbers inside damage lines are the same colour as their sentence (no highlight).

## 3. Boss health bar (top-centre)

Fixture data per 00 §2.3: "Void Colossus" and "48,532 / 120,000" are reproduced for the diff only; the build renders the encounter `display_name`/`title` and canon HP in the thousands with the same chrome.

### 3.1 Plate

- **Plate rect `931, 53, 384, 65`** (border lines at x 931 left `#726869`, x 1313..1314 right `#464958`/`#525363`, y 53..54 top `#403E4C`/`#363A47`, y 116..117 bottom `#3D3E4B`/`#4F4B59`). Border is drawn **2 px** on top/right/bottom and 1 px on the left — build 2 px `#464958` all round. Horizontal centre = 1123 (frame centre 768 — the plate is *not* centred on the frame; it is centred on the boss/stage right half. Build it at the measured x; see §7).
- Corners: **chamfered**, not rounded — a 45° cut of 6 px at all four corners (visible at 3×). `StyleBoxFlat` cannot chamfer; use `corner_radius = 6` with `corner_detail = 1` (which yields a straight cut) or a 9-slice texture.
- Fill `#010B1A` (samples `#010B1A`, `#000C1B`, `#000B19`), opaque. No inner bevel, no halo.

### 3.2 Sigil

- Bbox `943..990 × 60..110` → **48×51 bare glyph** at `943, 60` (no frame, no plate — the diamond floats on the plate fill). Vertical centre 85 = plate centre 85 ✓. Left inset 12 px from the plate border.
- Colours: body `#300078`/`#480090`, ridges `#9F32EB`→`#D36EFC`, hot core `#F8BAFE` → white `#FFFFFF` centre pixel. Reads as the boss's *affix family* sigil; build as a 48×48 icon slot (glyph authored 48×51 is a mockup overflow — author 48×48).

### 3.3 Name

- "Void Colossus": bbox `1001..1108 × 64..77` → **baseline y 77**, cap height 14 → ~18 px sans, weight regular, colour `#F2F0EA` (dominant `#F0F0F0`/`#F0F0D8`). Left x 1001 = sigil right + 11 = track left + 2.

### 3.4 Track and fill

- **Track rect `999, 85, 299, 24`** — 1 px border: left `#364669`, right `#2D4566`, top `#182E3F`, bottom `#051A2E`; inside dark `#04162B`→`#02152D`. Right border x 1297 → 16 px inset from the plate's right border (1313).
- Fill inset 1 px → fill rect `1000, 86, 297, 21` (the top row y 86 is a `#60525E` grey seam in the mockup; the real fill starts y 87 → **20 px tall**).
- Fill gradient (vertical, sampled at x 1050): y 87 `#E17573` (1 px pale highlight), 88 `#FC5857`, 89..95 `#F32934`→`#D5233A`, 96..106 `#A81A2D`→`#83172A`, 106 `#791D2F`. **Two-band build:** top 9 px `#EE2334`, bottom 11 px `#861829`, with a 1 px `#E17573` highlight on row 87. The fill's right end is square (no rounded cap); at x 1133 `#5B1422` → `#060F28`.
- Fill width: 48 532 / 120 000 = 40.4 % of 297 = 120 px → should end x 1120; the mockup ends at 1133 (45 %). Data-driven in the build; the reference is 4.6 % over.
- **Text "48,532 / 120,000"**: bbox `1189..1293 × 92..104` → **right-aligned to x 1293** (track right − 4), **baseline y 104**, digits 13 px cap → ~17 px sans, tabular, thousands separators, spaces around the slash. Colour `#E8E8EA` (dominant `#D8D8D8`, AA peaks `#FFFDFC`); no outline — it sits on the dark track, not on the fill.

### 3.5 Affix icons (under the plate)

Four cells in a row, left-aligned with the track:

| Cell | Measured x | Measured y | Clean rect |
|---|---|---|---|
| 1 | 1001..1029 | 122..153 | `1001, 122, 30, 30` |
| 2 | 1035..1063 | 122..153 | `1035, 122, 30, 30` |
| 3 | 1069..1097 | 122..153 | `1069, 122, 30, 30` |
| 4 | 1103..1131 | 122..153 | `1103, 122, 30, 30` |

- **Pitch 34, gap 4** (measured 29×32 cells; built square 30×30). Top y 122 = plate bottom (117) + 5. Frame 1 px, dark maroon `#58202D` left / `#451F21` right (the frame takes the icon's hue at ~35 % — build `frame = icon_hue.darkened(0.6)`); fill `#11060B`→`#300913` (dark maroon, near-black); corner radius 3.
- Glyphs: cells 1, 2, 4 red (`#E14F47`/`#FF735D`/`#FEAE94` spiky bursts), cell 3 purple (`#9151CB`/`#A35AC3`). Glyph footprint ≈ 22×22 centred. Meaning is unreadable at this size (AI mockup); **resolve as** the encounter's affix/mechanic list (e.g. Enrage, Bleed, Void, Slam) with tooltips — the icon set comes from `09-icons`.

## 4. Compact header and objective block

### 4.1 Compact header — emblem + wordmark, and the delta from Concept 1

| Element | Concept 1 bbox (measured on ref 1) | Concept 2 bbox | Delta |
|---|---|---|---|
| Skull emblem | `22..87 × 15..79` (66×65) | `22..86 × 12..69` (65×58) | same x; top −3; the ring is cropped 7 px shorter (mockup — same glyph) |
| Wordmark "A Guild Story" | `104..399 × 20..62` (296×43) | `96..319 × 19..51` (224×33) | **scale 0.76** (224/296 = 0.757, 33/43 = 0.767); left −8; top −1 |
| Wordmark baseline | — | **y 48** (the `d` of Guild bottoms at 48; ascender top 19 → 29 px ascender-to-baseline) | |

**Build:** one `HeaderEmblem` component with a `compact` flag. Compact = wordmark scaled ×0.76 about its top-left and moved to `x 96`, baseline `y 48`; the skull stays 65 px wide at `x 22, y 12`. Wordmark colour `#D8C0A8` body / `#A89090` shade / `#FCF9F3` highlight (identical to Concept 1's — the bronze-cream lettering, not re-sampled here; see `01-concept1`).

Header plate: fill `#090D16` (sample 200,40), spanning `0, 0, 352, 64`; a 1 px rule `#273242` at **y 64** ending at x 351 (row-64 scan: last edge 351→`#020B19`). Right of x 352 the plate is gone — the scene shows (`#07152B` at 400,40). The plate is opaque-dark under the wordmark and reads as ~85 % over the scene at its right edge; build opaque `#090D16` with a 24 px alpha fade from x 328 to 352 if the soft edge is wanted.

Between the header rule (64) and the objective plate (88) the scene shows through (`#0F0B35` purple at 200,75) — a **24 px gap**.

### 4.2 Objective block

Plate: `0, 88, 352, 106` (rules at y 88 `#273242` and y 194 — measured `#7F85AB` bright at x 150, i.e. the bottom rule is lighter than the top); fill `#070727` (200,150) / `#000927` (200,185) — a dark navy at ~80 % over the scene. Contents:

| Row | Icon | Text | Text bbox | Baseline | Cap | Size / colour |
|---|---|---|---|---|---|---|
| Title | gold shield/house glyph `20..43 × 98..125` (24×28; `#D89030`/`#C07830`, highlight `#FBEB9C`) | "The Shattered Core" | `57..220 × 105..119` | **y 119** | 15 px | ~20 px sans, `#F2EFE0` (cream white) |
| Objective | grey crossed-swords glyph, ≈20×20 at `20, 140` | "Defeat the Void Colossus" | `50..226 × 144..156` | **y 156** | 13 px | ~17 px sans, `#F0F0F0` |
| Optional | bullet 4×4 at `50..53 × 174..177`, `#A8A8C0` | "(Optional) Keep at least 2 raiders alive" | `62..308 × 169..183` | **y 180** | 11–12 px | ~15 px sans, `#BBBFD4` (dim blue-grey) |

- Indents: icon column x 20; title text x 57 (icon right + 13); objective text x 50 (icon right + 10 — the objective icon is smaller); optional bullet x 50, optional text **x 62** (bullet + 12). So the optional line is indented 12 px past the objective text, with the bullet on the objective text's x.
- Vertical pitch: title baseline 119 → objective baseline 156 = **37**; objective → optional = **24**. Title underline: a faint 1 px rule at y 130..131 `#474B5D` (col 150 sample) spanning the plate — 11 px under the title baseline.
- Title = encounter `title` if present else `display_name` (00 §2.3); the subtitle-as-kind is not shown in the raid view — the objective line replaces it. "Defeat the …" is generated from the encounter's win condition; optional lines from its bonus conditions. Godot: three `Label`s (test suite reads `Label.text`) in a `VBoxContainer` with `separation` tuned to the baselines above.

## 5. World-space overlays

All overlays are screen-space `Control`s positioned from a world anchor (the sprite's head point), never children of the sprite, so they stay pixel-crisp.

### 5.1 Floating status bar (measured on the gunner's, anchored above the sprite at `522..579 × 431..521`)

Layout, left to right, bottom-aligned: **class badge · pip row over HP bar**. Overall footprint `494, 403, 96, 23`.

| Part | Rect | Detail |
|---|---|---|
| Class badge | `494, 403, 24, 24` (frame 1 px `#3078C0`, inner fill `#0C1836`; glyph = gold shield `#F3BE43`/`#F7DB78` ~12×14 centred) | Frame colour = class colour (blue for this Rogue/gunner; the mage's badge at `222, 515` is the same 24×24 with a blue-white star glyph; the hooded raider's at `410, 488` blue with a green shield). |
| Pip row | y `405..415`, 4 pips at x `524, 538, 552, 566` | **pip 12×12, gap 2 → pitch 14**; each pip is a bare 12×12 glyph with a 1 px dark rim `#0A1F44`; pip 1 = skill icon (`#7EA5B6` blue-white), pips 2–4 = red debuff glyphs (`#A23532`/`#966E93`). Row starts at badge right + 6. |
| HP bar | **`522, 418, 62, 7`** (frame 1 px: top `#507D58`, sides `#0B1028`/`#17486A`; fill inner `523..582 × 419..423` = 60×5) | Fill green `#2DA35E` with a 1 px top highlight `#83DF83` (row 419); the missing portion is dark red `#3F1A32`. The mockup paints the *left* 8 px red and the rest green (an AI slip — the lost HP belongs on the right). Build: fill from the left, `#3F1A32` remainder. |

Bar bottom (425) sits 6 px above the sprite's head (431). Pip row bottom (415) → bar top (418): 3 px gap.

The other three bars (`222..310 × 515..540` mage, `410..500 × 488..510` hooded, `572..660 × 588..612` fallen Bork) are the same component; the fallen one's HP fill is empty and the badge is replaced by the "!" badge.

### 5.2 "!" badge (downed raider)

- Rect **`577, 588, 22, 22`**, a red rounded plate (radius 6) `#9B161D` body / `#8D0C13` edge, 1 px rim `#534F52`; glyph "!" cream `#FFFFF2`, bbox `586..589 × 593..606` (4×14), centred. It occupies the class-badge slot of the downed raider's bar (bar at `600..660 × 604..610`).

### 5.3 Speech bubble ("Reloading… again…")

- Bubble rect **`529, 341, 117, 56`** (borders: left x 529..530 `#545663`, right x 644..645 `#444E5B`, top y 341..342 `#28303D`, bottom y 395..396). Border **2 px `#545663`**, plus a 1 px near-black outer line `#03040E`. Fill `#03122C`→`#05152C` (dark navy, opaque). Corners **chamfered 6 px** (same octagon language as the boss plate and minimap).
- Tail: a filled triangle **12 wide × 10 tall** on the bottom edge at x `577..589`, y `396..406`, pointing down-right toward the speaker's head (sprite top-centre ≈ 550, 431); same fill and border as the bubble.
- Text: two lines, centred on the bubble's centre x 587: "Reloading..." cap top 354 → **baseline 367**; "again..." cap top 372 → **baseline 385**; **pitch 18**, cap 13 → ~17 px sans, colour `#F0F0F0` (AA `#C0C0D8`). Padding: 13 px above the first cap top, 11 px below the last baseline, ≥ 10 px sides.
- Position rule: bubble bottom-left tail base sits 25 px above the status bar's top (403) and the bubble's left edge is 35 px right of the bar's left edge in the mockup; build: tail tip = sprite head anchor − (0, 28), bubble centred on the tail with a 10 px minimum viewport margin.

### 5.4 Floating damage numbers

| | "-842" (crit, on the boss) | "-317" (normal, on the boss) |
|---|---|---|
| Glyph rect | `1033..1088 × 253..274` → **22 px digit height**, 56 wide for 4 glyphs | `845..900 × 508..523` → **16 px digit height** (the "1" stem at x 878 spans y 508..523) |
| Fill | orange `#F28C45` (rows 253 `#E67F33` → 274 `#F28C45`: a slight top-dark gradient) | white `#FAF5E5` → `#FFFFFF` |
| Outline | **2 px** `#0F060F`/`#000000` (1003 px of lum < 25 in the 90×50 box) | **1–2 px** `#212D31`/`#333333` → `#000000` (657 dark px in a 90×55 box) |
| Font | heavy geometric sans, tabular, minus sign 10 px wide | same face, smaller |

Crit = larger (22 vs 16 px, ratio 1.375) and orange; normal = white. Both use a black outline (2 px on the crit, 1–2 px on the normal), not a drop shadow; no glow (the "-842" halo in the bbox is the boss's purple lightning behind it). Heal numbers are not shown — take `#83DF83` (the HP-bar highlight) for consistency.

## 6. Minimap (top-right)

- **Rect `1356, 14, 164, 162`** (borders: left x 1356..1357 `#816C6B`, right x 1518..1519 `#444551`/`#272A35`, top y 14..16 `#918276`/`#AB988D`, bottom y 173..175 `#BDA292`). Right margin to frame = 16 px; top margin 14 px. Build **164×164** at `1356, 14` (the mockup is 2 px short vertically).
- Border **2 px bronze `#9A8479`** (the top/left/bottom edges are warm `#918276`–`#BDA292`; the right edge is drawn cold `#444551` — mockup lighting; use one bronze). This is the **same bronze chrome as the cog/fast-forward buttons (§8)** and distinct from the grey `#4E515C` of the strip panels.
- Corners **chamfered 8 px**; an inner 1 px line `#1E2B3B` 6 px inside the border (y 20..21, y 168..169) with its own 4 px chamfer — a double frame like the log panel's.
- Fill: `#020B1F` / `#020A19` (near-black navy). Map rooms are painted as lighter plates `#06172D`→`#232D3E` with 1 px outlines `#34445C`; the room set is fixture art (the layout is not readable as any canon raid) — build the minimap as a `SubViewport`-rendered or hand-authored 148×148 room mask per encounter.
- **"N" label**: glyph bbox `1434..1442 × 27..37` (9×11), cream `#C0C0A8`/`#FBF6F0`, ~14 px serif-ish caps, centred on the minimap's centre x 1438 (= (1356+1519)/2); flanked by two 1 px dashes `#4A4A50` at y 27..28, 12 px long, 6 px either side.
- **Blips** (saturated pixels: 59+34 red, 9+8 cyan, plus white dots): boss = red skull glyph ≈ 18×18 (`#F03030`/`#D83030`) at `1424..1435 × 85..96`; enemies = red 6 px diamonds `#F03048`; raiders = cyan 8 px diamonds `#48C0D8`/`#60C0D8`; points of interest = 3 px white dots `#EAF0EE`. Blip hexes: boss/enemy **`#EE3232`**, raider **`#54C4DA`**, POI **`#EAF0EE`**.

## 7. Battle stage

- **Stage rect = the whole viewport above the strip: `0, 0, 1536, 735`.** There is no framed stage panel; the header, objective block, boss plate and minimap float over the scene (§0). The scene is a single painted 2D-HD plate (00 §1: canon's Octopath-style target) — cavern walls in `#0A0C18`→`#444F95`, a blue light shaft centre-left (`#0D366B`), purple void on the right (`#19113A`→`#331A72`).
- **Floor: painted, not a tile grid.** Edge scans along `y 660` give flagstone seams at x 305, 383, 391, 447, 462, 548, 591, 610, 636, 688, 701 (spacing 53–84, mean **56**), and along `x 450` at y 563, 587, 599, 617, 640, 656, 687, 710 (spacing 23–31, mean **27**). So the flagstones read as foreshortened slabs of **≈ 56 × 27 px** with irregular joints — a painted floor, no repeat. Floor band y 540..735 in the party's area; floor colours `#374968` (lit slab), `#121B33`/`#09142B` (shadowed), `#395680` (blue-lit right), `#5D3F47` (fire-lit left). Build as one painted floor texture; unit positions are authored points, not grid cells.
- **Party sprite positions** (bright-pixel bboxes; feet anchor = bbox bottom-centre):

| # | Sprite (reference reading) | bbox | Feet anchor | Facing |
|---|---|---|---|---|
| 1 | Mage (Spoof) casting the arcane orb | `240..314 × 540..643` (staff and orb included) | **(277, 643)** | right |
| 2 | Hooded archer (Tiny → Rogue, 00 §2.2) | `426..499 × 524..604` | **(462, 604)** | right |
| 3 | Gunner (red hair, rifle; the speaker of "Reloading… again…") | `522..579 × 431..521` (rifle excluded past 579) | **(550, 521)** | right |
| 4 | Fallen raider (Bork, "!" badge) | `550..664 × 605..668` (prone, 115 wide) | **(607, 668)** | — |
| 5 | Shield knight (Gruk) mid-slash at the boss | `740..834 × 540..649` (slash arc included) | **(787, 649)** | right |

  Five sprites for four panels: the mockup shows an extra body. Canon parties are 12 (00 §2.4), so the stage positions are data-driven from a 12-slot formation of which the mockup shows a 5-point sample; use these five as the first five formation points (a loose staggered wedge, x pitch ~120–180, y pitch ~60–120, front-liners right). Sprite frames are 64×64 authored art drawn 1:1 (bodies read 58–75 px wide incl. weapons; heights 81–104 incl. hats/staffs).

- **Boss**: the purple silhouette is not separable from the purple scene by colour (a mask of `b>g+40 & r>g+30` fills the whole right half), so the extent is read at 1×: body `730..1310 × 110..700` (≈ 580 × 590), with tentacles reaching to x 1527 and the strip. The measured anchor is the **eye core: brightest pixels bbox `921..1028 × 302..399`, centre `(970, 353)`** — the point damage numbers, the boss health-plate and hit VFX reference. The boss plate (§3) is centred at x 1123, 153 px right of the eye; the "-842" number sits at `1033..1088 × 253..274`, i.e. up-right of the eye by (+90, −90). Build: `boss_anchor = Vector2(970, 353)`; damage numbers spawn at anchor + (60..120, −80..−110) with the sign of x random.

## 8. Bottom-left cog and fast-forward buttons

Two buttons side by side, above the strip, hugging the left edge.

| Button | Measured border x | Measured border y | Clean rect | Glyph bbox |
|---|---|---|---|---|
| Cog (settings) | left edge off-frame (chamfer at x 0) .. 55 | 675..719 | **`4, 675, 52, 45`** | cog `19..38 × 686..708` (20×23), grey `#9A9AA2`/`#B0B0B7`, 8 teeth, 6 px hub hole |
| Fast-forward | 72..122 | 675..719 | **`72, 675, 52, 45`** | double chevron `87..103 × 688..706` (17×19), cream `#F0DED0`/`#E7D5C7` |

- **Pitch 68, gap 16.** Bottom edge 719 → 16 px above the strip's top line (735). The mockup's left button starts at x ≈ 0 with its chamfer clipped; the build puts it at x 4 so both buttons are whole.
- Border **2 px bronze** — top `#A78B7A`/`#864537`, bottom `#545458`/`#7D6B6A` — same family as the minimap (§6): build `#9A8479`. Corners **chamfered 8 px** (octagon), with tiny corner rivets drawn in the mockup (ignore).
- Fill `#030A14` (samples `#000108`, `#010C18`) — near-black navy, opaque. No hover/pressed states are shown; propose hover = border `#C9AE9C`, pressed = fill `#0F1A26`, and the fast-forward glyph turning `#F3BE43` (gold) while ×2 speed is active.
- Radius: none (chamfer). Glyph centred in the button; the cog is 1 px left of centre in the mockup.

## 9. VFX + icon inventory

### 9.1 Spell VFX

Colour ramps are luminance percentiles (5 / 30 / 60 / 90 / 99 %) of the saturated pixels inside the footprint, darkest → brightest; use them as the 5-stop gradient of each particle/sprite sheet.

| VFX | Footprint (saturated bbox) | Shape | Ramp (dark → hot) |
|---|---|---|---|
| **Blue arcane orb** (mage projectile) | `320..369 × 558..614` → 50×57; core ≈ 24 px sphere + 12 px halo + streaks | filled sphere with a lighter off-centre core, 6–8 radial sparks, short trail to the staff tip at (312, 585) | `#443388` → `#67599E` → `#7769BE` → `#9AA9F9` → `#B3EEFD` (indigo → periwinkle → ice-white) |
| **Fire muzzle flash** (rifle) | `585..659 × 415..472` → 75×58; the flash itself ≈ 30×30 at the muzzle (588, 447) with a 60 px horizontal streak | starburst: 4 long + 4 short rays, warm core; bullet trail as a 2 px line with 1 px dark rim toward the boss | `#813D2A` → `#F3BE43` (gold) → `#FCF4BA` (white-yellow); the ramp's blue members (`#397EBD`, `#6BC7F4`) are the scene's light shaft behind it — exclude |
| **Red impact burst** (hit on the boss) | `800..959 × 440..599` → 160×160 | ragged radial burst: red core with magenta fringe, 10–14 spikes, plus falling red sparks toward the floor (the "blood" splashes at y 560..600) | `#6A294C` → `#A54980` → `#C01830`/`#D81830` (dominant reds) → `#FA9194` → `#FD9FFD` (pink-white); the `#384D96` blue is scene bleed — exclude |
| **Cyan slash arc** (knight's swing) | `715..839 × 520..624` → 125×105; arc thickness 6–10 px | a 200° crescent sweeping from upper-left over the shield to lower-right, thicker at the leading edge, dotted afterimage | `#314476` → `#4C5594` → `#2C7AD7` → `#75C0F9` → `#B7F1FD` (steel-blue → cyan → white) |
| Boss eye / void lightning (idle) | `900..1059 × 240..419` (saturated) | eye core `#FFFFFF`→`#D848F0` with `#600090`/`#7818A8` iris rings; 3–4 forked bolts 2–3 px wide toward the party | `#301890` → `#601890` → `#9018C0` → `#D848F0` → `#FFFFFF` |

All VFX are drawn *over* the sprites and *under* the overlays (§5). Footprints are authored at 1× (no upscaling), matching the sprite density.

### 9.2 Icon inventory (every distinct glyph, with rect)

| Icon | Where | Rect / size | Colours |
|---|---|---|---|
| Skull emblem | header | `22, 12, 65, 58` | `#787878` steel skull, `#D8C0A8` bronze ring |
| Objective title glyph (gold shield/house) | objective block | `20, 98, 24, 28` | `#D89030`/`#C07830`, `#FBEB9C` |
| Objective line glyph (crossed swords) | objective block | `20, 140, 20, 20` | grey `#A8A8C0` |
| Optional bullet | objective block | `50, 174, 4, 4` | `#A8A8C0` |
| Boss sigil (purple diamond) | boss plate | `943, 60, 48, 51` | `#300078` → `#F8BAFE`, white core |
| Affix icons ×4 | under boss plate | `1001/1035/1069/1103, 122, 30, 30` (pitch 34) | red `#E14F47`/`#FEAE94` (1, 2, 4), purple `#9151CB` (3) |
| Minimap "N" | minimap | `1434, 27, 9, 11` | `#C0C0A8` |
| Minimap blips | minimap | skull 18×18; diamonds 6 / 8 px; dots 3 px | `#EE3232`, `#54C4DA`, `#EAF0EE` |
| Class badge (shield) | floating bars | `494, 403, 24, 24` (frame) | frame `#3078C0`, glyph `#F3BE43` |
| Status pips ×4 | floating bars | 12×12 at pitch 14 | `#7EA5B6` skill; `#A23532` debuffs |
| "!" badge | fallen raider | `577, 588, 22, 22` | `#9B161D` plate, `#FFFFF2` glyph |
| Cog | bottom-left button | `19, 686, 20, 23` | `#9A9AA2`/`#B0B0B7` |
| Fast-forward chevrons | bottom-left button | `87, 688, 17, 19` | `#F0DED0`/`#E7D5C7` |
| Panel status slot ("X" box) | combatant panel | `227, 750, 24, 24` | `#6F6569` on `#254860` — replaced by state glyphs (§1.4) |
| Flame (burning) | combatant panel | `230, 780, 24, 28` | `#F6593F`, `#BF3628`, `#FB7052` |
| Buff/debuff row ×4 | combatant panel | `122, 812, 14, 14` pitch 16 | green `#4F6E63`/`#3D5D5A` (Bork), mixed (others) |
| HP icon (shield-heart) | combatant panel | `41, 840, 9, 15` | `#F7484F` |
| Secondary icon (wing/drop) | combatant panel | `40, 866, 10, 13` | `#A0E3FD` |
| Weapon (rifle / bow / sword / staff) | weapon slot | `34, 890, 60, 84` (art ≈ 48×70 diagonal) | steel `#F0EFF3`/`#8D909B`; wood `#D39553` |
| Ability icons ×6 per panel | ability grid | 38×38 cells, art ≈ 30×30 | per ability; lit = yellow `#F4F197`, orange `#D39553` |
| Log badges ×8 | combat log | 20×20 at x 1069 | see §2.1 |

Everything above is authored pixel art at 1×; nothing in this screen is a font glyph except the text runs listed in §1–§5.
