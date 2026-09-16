# 03 — Concept 3 (CAMP / TOWN) layout spec

> **Status:** Measured (all 9 sections) · **Owner:** Art pass · **Updated:** 2026-09-09
> **Inputs:** `ideaboard/Reference Concepts/Reference Concept 3.png` (1536×1024, 1:1 = framebuffer), Concept 1 for the diff, `00-canon-reconciliation.md` (cited, not re-argued).
> **Method:** `tools/art/refkit.py` row/col/px/crop. All coordinates are framebuffer pixels; hexes are sampled, not eyeballed. Where a value is an AI-mockup artifact it is flagged as such.

Canon notes that apply here and are NOT re-litigated: morale row format (00 §2.1), "Ranger"→Rogue (00 §2.2), named missions / "Level 18+ · 1–4 Raiders" not reproduced (00 §2.3), four cards vs twelve raiders (00 §2.4), header chips (00 §2.5), nav labels Camp→Town etc. (00 §2.6).

## 1. Shared-vs-per-screen chrome (diff vs Concept 1)

Both concepts measured with the same predicates (dark-fill islands lum<26 for panel interiors, bright-text row projection lum>150, edge scans thr 20). "Identical" means Δ≤2 px, which is the AI mockup's jitter floor.

| Component | Concept 1 (HOME) | Concept 3 (CAMP) | Verdict / delta |
|---|---|---|---|
| **Header band** | Opaque dark band y 0–73; bronze rule y=74–76 (`#866653`/`#97735E`) across the full 1536 width | **No band.** Scene is full-bleed to y=0. A dark gradient plate sits behind emblem+wordmark, opaque to x≈414, fading out by x=440; the bronze rule exists only over that plate (x=300: y=77–79 `#886F57`) and over the sidebar (x=1500: y=76–78 `#AB8A66`/`#EECBA0`); absent at x=600 | **Different.** C3 = transparent header over the scene, rule 3 px lower and broken. Production: keep C1's opaque band on panel screens; on the town screen the header is an overlay (see §9) with the same 2 px bronze rule at y=74–76 drawn only over the rail plate and the sidebar. |
| **Emblem** (skull) | x 28–87, y 15–83 (60×69) | x 19–88, y 11–83 (70×73) | Same asset, C3 drawn 10 px wider / 4 px taller (AI redraw). One asset: use C1's 60×69 at (28,15). |
| **Wordmark** "A Guild Story" | x 104–408, y 20–63 (305×44), colour `#D8C0A8` | x 97–372, y 15–50 (276×36), colour `#E0C8B0` | **Different.** C3 is 0.9× and moved up 5 px to make room for the tagline (§6). Same bone/parchment colour family. |
| **Tagline** | absent | present, see §6 | C3-only. |
| **Header chips** (4) | pill (fully rounded ends). Fills: 859–1003, 1021–1148, 1166–1294, day chip 1318–1518 (borders 1317/1519); y 16–58 (h43); day chip has a double bronze line frame | **chamfered octagon** (≈6 px corner cuts). Fills: 865–1006 (w142), 1024–1152 (w129), 1169–1300 (w132), day 1321–1518 (w198); y 16–59 (h44), day chip y 16–57 (h42), same double bronze frame | Positions identical within 8 px, heights identical within 1 px. **Shape differs** (pill vs chamfered). Contents per `00 §2.5`. Production: pick one — the chamfered octagon matches the callout plates (§3) and the sidebar's chamfered corners, so it is the better system choice; C1's pills are the odd one out. |
| **Nav rail** | 7 items, pitch 55, highlight 0–211 | 6 items, pitch 56 (jitter), highlight 0–201 | Same component, shorter list — §2. |
| **Rail plate** | Opaque dark column x 0–207; scene viewport framed at x=208–209 (`#463E3E`) + bronze x=212 | No frame: at y=400 the scene (a wooden post `#CD7D48` at x=196–199) runs straight into the rail's translucent dark gradient; highlight terminator x=201 | **Different.** C1 has a framed viewport (x 210–1142, y 77–717); C3 has none. |
| **Scene viewport** | framed: left 208–212, right 1142–1145 (bronze `#856A57` at 1143), top rule 74–76, bottom frame 717–719 | full-bleed 0–1536 × 0–1024, chrome overlaid | Different by design (§9). |
| **Right sidebar** (inner-border box) | fill 1145–1517 × 86–705 (373×620); 2 px border 1143–1144 / 1518–1519 / 84–85 / 706–707 (`#745C4F`,`#59493E`); outer bronze line y=79–81 top, 712–714 bottom, x≈1131–1134 left | fill 1168–1517 × 83–654 (350×572); border 1167 (`#313332`) + bronze 1165–1166 (`#594538`,`#A58E7D`) left, 1518–1519 right, 81–82 top (`#5E5B57`), 655–656 bottom; outer bronze 76–78 top, 661–662 bottom | **Different size, same right edge (1517).** C3 is 23 px narrower and 48 px shorter (no "Current Raid" heading, no "Edit Team" row). Contents diff in §5. Production: one panel component, width 350, height content-driven; the two mockups disagree on width only because the AI redrew it. |
| **Bottom strip** | no strip rule; the viewport bottom frame at y=717–719 does the job; cards start y=735 (border) / 737 (fill) | **has** a full-width bronze rule y=726–727 (`#816D68` / `#B5916E`), measured at x=143, 278 and 1300; cards border 736–737, fill 738 | Different. Production: strip rule at y=726–727 on every screen (C1's viewport frame can sit on top of it). |
| **"Available" grid** | panel fill 16–119 × 737–993 (104×257), title rows 750–763 | absent | C1-only; `00 §2.4` / `10-screen-audit.md` own the roster-count question. |
| **Roster cards** | fill w=209/209/210, h=256 (y 737–992); x=146, 369, 592, 815 → **pitch 223**, gap 14; 2 px border (`#3B3E43`) at x 140–141 … 355–356, y 735–736 / 994–995 | fill w=251/238/236/252 (AI-inconsistent), h=242 (y 738–979); x=18, 288, 546, 802 → pitch 270/258/256, gap 20/21/21; 1 px border (`#464C57`) at x=17 / 269, y=736–737 / 981 | **Different geometry** (C3 cards are ~30 px wider, 14 px shorter, 1 px border vs 2 px). Anatomy diff in §4. |
| **Recent Events panel** | fill 1047–1516 × 736–995 (470×260); title cap rows 752–764, x=1070; 7 rows, first text row 789–802, **row pitch 28.7** (789,817,846,874,903,932,961); icon 17×17 at x 1071–1087; text x=1101 | fill 1074–1517 × 737–980 (444×244); title rows 751–764, x=1094; 7 rows, first 786–799, **row pitch 26.8** (786,813,839,866,893,920,947); icon 19×15 at x 1094–1112; text x=1127; **"View All" link** (§8) | Same component; C3 is 26 px narrower, 16 px shorter, tighter row pitch, and has the link. Production: title x = panel.x+20, icon x = panel.x+20, text x = icon.x+33, row pitch 27, title baseline = panel.y+27. |
| **Speech bubbles in scene** | small square icon-bubbles over NPCs (beer, ellipsis, sleep glyphs) — glyph, no text | one text bubble over the campfire camper (§7) | C3's text bubble is a different component (a `Label` in a plate), not the icon-bubble. |

## 2. Nav rail — 6 items vs 7

Measured on both concepts by row-projecting bright (lum>150) label pixels in x 70–180 and the selected-row highlight (blue-teal island, x=0 leftward).

| | Concept 1 (7 items) | Concept 3 (6 items) |
|---|---|---|
| Label cap-tops (y) | 126, 181, 236, 291, 345, 400, 455 | 127, 186, 242, 297, 353, 409 |
| Gaps | 55, 55, 55, 54, 55, 55 | 59, 56, 55, 56, 56 |
| Mean pitch | **54.8 → 55** | **56.4** |
| Label cap height | 15 (19 with descender) | 13–14 (17–18 with descender) |
| Selected-row highlight | x=0 y=105 w=211 h=55 (105–159) | x=0 y=106 w=201 h=59 (106–164) |
| Highlight fill (sample x=150) | `#3D5F79`/`#46687E` top → `#4D7894` bottom edge | `#4581A2` top edge → `#3D87A3` bottom edge, body `#133D53` |
| Highlight right terminator | x=211 (`#4E84A1`→`#142C3B`) | x=199–201 (`#3590B0`→`#0A1A17`) |
| Icon column | x 24–52, icon rows start y=118 | x 21–52, icon rows start y=118 |
| Label x | 73 | 73 |
| First icon top / first label top | 118 / 126 | 118 / 127 |

**Verdict: the pitch is the same component pitch within AI jitter — the list is simply shorter.** C1 is the more internally consistent measurement (six gaps, five of them exactly 55); C3's first gap of 59 is the one outlier, and its highlight is 4 px taller for no design reason (it is the same item, same icon, same label size). Production value: **pitch 55, item rect y = 105 + 55·i, h = 55; highlight = full item rect, x 0→211 (the 211 terminator is where the rail meets the scene viewport, i.e. rail width = 211)**. In C3 the rail is 10 px narrower (201) because the scene plate starts further left (the viewport in C3 has no dark frame — see §1). Use 211 for both; canonical labels come from `00 §2.6` (Camp→Town etc.), and the rail component takes the item list as data.

Icon glyphs (both concepts, same set, same order where present): house, add-person (C1 only), people, shield, quest-scroll, ledger, cog. Icon size ≈ 28×22 bright-grey (`#F1EDDF` highlights, `#7B8183` body) — pixel art, not a font glyph.

## 3. Building label callouts (unique component)

Four plates, all the same construction, **size-to-content width** (fill widths 220 / 166 / 189 / 153), nominal fill height 52 (measured 53 / 51 / 52 / 50 — jitter). Each is one dark chamfered plate with an icon at left and two left-aligned text lines.

| Plate | Fill rect (x,y,w,h) | Outer rect incl. 2 px border | Title cap rows (baseline) | Title x-run | Subtitle cap rows (baseline) | Icon rect |
|---|---|---|---|---|---|---|
| The Tavern | 388,117,220,53 | 386,115,224,57 | 126–138 (138) | 451–530 | 149–158 (158) | 400–434 × 127–158 (35×32, tankard) |
| Blacksmith | 716,214,166,51 | 714,212,170,55 | 222–234 (234) | 775–852 | 245–254 (254; p,g to 257) | 727–758 × 225–253 (32×29, crossed hammers) |
| Training Grounds | 793,410,189,52 | 791,408,193,56 | 419–431 (431; g to 434) | 852–970 | 441–450 (450; p to 453) | 806–833 × 424–449 (28×26, crossed swords) |
| Outpost | 475,580,153,50 | 473,578,157,54 | 588–600 (600; p to 603) | 533–589 | 610–617 (617; g to 620) | 485–515 × 596–615 (31×20, binoculars) |

Derived constants (what the component should hard-code):

- **Fill** `#040E18` (samples `#000C14`, `#000C18`, `#00101C`, `#000810` — flat, no gradient, no texture). Ship opaque; the faint scene bleed at the Tavern plate's lower edge is not consistent across plates.
- **Border** 2 px: outer line warm grey `#605A54` (samples `#615D5B`, `#604F42`, `#6B5E5A`, `#635C57`), inner line `#2A2E32`. Same two-line border as the sidebar's inner frame — one `StyleBoxFlat` border pair.
- **Corners** chamfered, 4 px cut (at y=fill.y+1 the border starts at x=fill.x+3…+7 vs x=fill.x−1 at mid-height). Not rounded — `corner_radius` 0 with a 4 px 45° cut; in Godot this is a 9-slice of a 16×16 chamfered PNG (or `_draw()`), not `StyleBoxFlat.corner_radius`.
- **Drop shadow** 2 px near-black (`#0E0E16`, `#000004`, `#0F0D15`) below (y = outer.bottom+1…+2) and right (x = outer.right+1…+2); the Tavern plate also shows 1–2 px at left, which reads as a halo rather than an offset. Production: `shadow_size 2, shadow_offset (2,2), shadow_color #0E0E16 @ 0.8`.
- **Icon** left inset 12 from fill (400−388=12, 727−716=11, 806−793=13, 485−475=10); icon box 36×32 max, vertically centred on the fill (Tavern: fill 117–169, icon 127–158). Icons are hand-pixelled, light grey `#C6C8C4`/`#F7F6F2` on transparent — four assets (tankard, hammers, swords, binoculars), none on the asset sheets; author in Aseprite at 36×32.
- **Title**: cap height 13, colour `#F8F8F8` (keep `#F8F8F8`, not `#FFFFFF`, per `00 §3`), top = fill.y+9 (9, 8, 9, 8), left = fill.x+**60** (63, 59, 59, 58 — Tavern's tankard is 4 px wider than the other icons and pushed the text; fix the icon, not the text x).
- **Subtitle**: cap height 10, colour `#B0B8C0` (samples `#B8C0C8`, `#B0B8C0`, `#A0A8B0`), top = fill.y+31 (32, 31, 31, 30), same left as the title. Separator dots "•" are the same colour as the subtitle text.
- **Right padding**: fill.right − text.right = 17 (Tavern), 29 (Blacksmith), 11 (Training), 10 (Outpost). Inconsistent; ship **16**. Width = 60 + max(title_w, subtitle_w) + 16.
- **Pointer**: only the **Outpost** plate has a tail — a downward triangle at x 560–566, y 631–637 (measured dark island 7×6, antialiased into the tower behind it), 85 px right of the plate's left edge, not centred (plate centre x=551). Tavern, Blacksmith and Training Grounds have none. Production decision: **every plate gets the same 14 wide × 8 tall tail**, centred, and the plate is positioned so the tail's apex sits on the building's anchor point. The Outpost tail as drawn is too small to read at 1:1 and is treated as an AI artifact.

Canon mapping (cited, not re-argued): the four labels here are not canon's five buildings. `00 §2.6` maps the town to Guildhall, Tavern, Market, Blacksmith (gated), Adventure's Board; "Training Grounds" and "Outpost" have no canon building and are **not** built — the callout component is reused with canon titles, and the subtitle line carries each building's canon verb list (e.g. Tavern → "Recruit • Rest"), sourced from `Town.BUILDINGS` so `test_the_town_lists_exactly_the_five_canon_buildings` still finds the five names in `Label.text`.

Subtitle text in the mockup ("Recruit • Heal • Morale", "Upgrade Gear", "Sharpen Skills", "Scouting • Intel") is legible, not garbled — no AI-text artifacts on these four plates.

## 4. Roster cards — the morale row

The C3 cards carry the clean row; the C1 cards carry the forbidden bar (`00 §2.1`) plus a garbled duplicate "Morale:" line (rows 865–873 on Bork and Gruk) that is a pure AI artifact. Everything below is measured on C3's Bork (Low) and Gruk (Okay) cards, with C1 for the diff only.

**Card geometry (C3, Bork card)** — fill x=18–268, y=738–979; 1 px border `#464C57`/`#36404A` at x=17, 269 and y=736–737, 981. Portrait plate x 30–120, y 748–825 (the mockup's portrait frame is within 20 lum of the fill and cannot be edge-detected; the portrait art itself is 90×78). Text column x=128: name cap rows 756–768 (cap 13, `#F8F8F8`), "Lv. 12" rows 778–788 (cap 11), class row 799–811 (class glyph 15×13 at x 128–142 + "Warrior" at x=145, cap 11). Three gear slots, fill 48×47 at x=45, 115, 195, y=913–959 (pitch 70 / 80 — jitter; ship pitch **75** → 45, 120, 195), slot border rows 911–912 / 961.
**C1 card for comparison** — fill x=146–354, y=737–992; name rows 753–765, "Lv." 775–785, class 797–806; gear slots 46×46 at x=171, 226, 282 (pitch 55–56), y=929–975. Same anatomy, tighter.

**Morale row (C3)**:

| Element | Bork — Low | Gruk — Okay |
|---|---|---|
| Face glyph rect | x 42–60, y 834–854 → **19×21** (circle 19×19 + 2 px antialias tail) | x 568–586, y 836–854 → **19×19** |
| Face fill | `#E04038` (samples `#C84838`, `#E04038`, `#E05038`) | `#F8C848` (samples `#F8D050`, `#F8C848`, `#F8C850`) |
| Face features | dark navy `#040E18` eyes + down-curved mouth | same, straight mouth |
| Label "Morale:" | x 73–118, cap rows 839–850 (cap 12, baseline 850) | x 600–649, cap rows 839–853 (cap 12 + "y" descender) |
| Value word | "Low" x 131–156 | "Okay" x 657–689 |
| Text colour (label AND value) | `#F04840` red (C3 sample `#E04038`, C1's "Low" `#F05040`; unify with the 17% red `#F04840`) | `#50D0E8` cyan (samples `#50D0E8`, `#68D0E8`) |
| Row position | face left = fill.x+24; face top = fill.y+96; text left = face.right+13; text baseline = face.bottom−4 | same |

Key finding: **in the mockup the state colour is applied to the whole line — glyph, "Morale:" label and value word all take the state colour** (red for Low, cyan for Okay). It is not a grey label with a coloured value. The Okay face is amber while the Okay text is cyan — the face and text ramps are decoupled in the mockup, which is an inconsistency; production uses one ramp for both (`04-palette.md`).

Colours for each morale state visible across both concepts:

| State word shown | Where | Text colour | Glyph colour |
|---|---|---|---|
| Low | C3 Bork/Tiny/Spoof, C1 Tiny/Spoof | `#F04840` | `#E04038` red face |
| Okay | C3 Gruk | `#50D0E8` | `#F8C848` amber face |
| (bar, no word — forbidden) | C1 Bork, C1 Gruk | label `#1878C0` blue, bar `#40B850` green | `#1878C0` blue face |

Only two canon-relevant hues are attested: a red "at-risk" end and a cyan "okay" middle; C1's green bar is the only evidence for a "good" end (`#40B850`). The ten canon band names map onto a red → amber → cyan → green ramp in `04-palette.md`; this file only records the sampled anchors.

**Quote line**: C3 rows 865–878 (cap 11, quoted string), x 87–162, colour `#C0C0C8`. The card centre is x=143 and the quote centre is 124.5 — the mockup centres the quote on the text column, not the card. Row top = fill.y+127. C1 quote rows 887–897.

**Canon rendering of the row** (from `00 §2.1`, not re-argued): line 1 `Bork — 87 ❤` beside the name block, line 2 `Warrior — Very Happy`; the face glyph rect, the 19×19 size, the row y and the state colour are kept from the table above; the number is rendered ≥ the name's cap height (13). No bar.

**Left edge and pitch here vs Concept 1**: C3 x0 = **18**, pitch 270/258/256 (mean 261, AI jitter); C1 x0 = **146** (after the 104-wide "Available" panel at 16–119), pitch **223**. Production for the town screen: x0=18, fill w=244, gap 18 → cards at 18, 280, 542, 804 (max deviation from the mockup's left edges: 0, 8, 4, 2), events panel at 1074 as measured.

## 5. Right sidebar mission panel — diff vs Concept 1

Both panels share the right edge (fill right = 1517) and the same internal order: image → title plate → "Potential Rewards" → slots → success panel → "Raid Team" → portraits + button → commit CTA. Everything else moves.

| Element | Concept 1 | Concept 3 | Delta |
|---|---|---|---|
| Panel fill | 1145–1517 × 86–705 | 1168–1517 × 83–654 | −23 w, −48 h (see §1) |
| "Current Raid" heading | cap rows 105–121, x=1176, `#F8F0E0` | **absent** | C3 drops the heading; image starts 13 px below the panel top |
| Encounter image | 1161–1499 × 132–228 (338×97) | 1183–1501 × 96–212 (318×117) | C3 image is 20 px taller, 20 px narrower |
| Title plate | 1164–1498 × 229–290 (dark island 335×62) | 1183–1501 × 213–271 (bottom edge 272) | plate h 62 vs 59 |
| Title | "The Sludge Maw" cap rows 244–265 (cap 17; g descender), x 1176–1332, `#F8F0E0` | "The Rotting Spire" cap rows 222–241 (cap 15; p,g descenders), x 1196–1340, `#F8F8F8` | C3 title is 2 px smaller and cooler white; C1's is the warmer bone. One token: `#F8F4EC`. |
| Subtitle | "Aberration" rows 271–282 (cap 12), x=1176, `#A0A0A0`…`#B0B0B0` | "Level 18+ • 1–4 Raiders" rows 248–259 (cap 12), x 1197–1364, `#B8C0C8`; bullet at 1270–1274 | same size, C3 is blue-grey vs C1 neutral grey. **Text not reproduced** — `00 §2.3` (party is 12, no levels); the slot renders the encounter `kind` / `display_name`. |
| "Potential Rewards" | rows 313–324 (cap 12), x=1176 | rows 289–300 (cap 12), x=1197 | same |
| Reward slots | **4** slots, outer 45×46 at x=1176, 1232, 1289, 1345 (pitch 56–57), y 335–380 | **5** slots, outer 47×45 at x=1196, 1252, 1305, 1360, 1416 (pitch 55), y 310–354 | 5 vs 4; slot w differs by 2, pitch by 1. Production: slot 46×46, pitch 56, count = data (`rewards` array length; 5 fits: 1196+5·56−10 = 1466 < 1500). Slot border 2 px `#5C5C5A`; rarity tint on the border per `04-palette.md`. |
| Success panel | fill `#100C14`/`#08080C` — **red-tinted** (R ≥ B), red corner ornament rows 390–400 top-right, border rows 393–394 / 472–473 → panel y 393–473 | fill `#041018` — neutral blue-black, no ornament, border not separable from fill | C1's danger state tints the whole panel; C3's amber state does not. Production: the panel takes a 6%-alpha wash of the percentage colour below the red threshold, none above. |
| "Estimated Success Chance" | rows 407–419 (cap 13) x=1176 | rows 377–388 (cap 12) x=1197 | same |
| Percentage | **"17%"** rows 432–456 (**cap 25**), x 1176–1231, **`#F04840`** | **"42%"** rows 402–425 (**cap 24**), x 1197–1258, **`#F8C840`** | Same size (25 ± 1). Colour by value: 17 → red, 42 → amber. Inferred thresholds: **< 25 red `#F04840`, 25–59 amber `#F8C840`, ≥ 60 green `#40B850`** (green is not attested on a percentage; borrowed from the C1 morale bar, the only green in the kit). Threshold constants go in `GameSettings` per the switch rule. |
| "Raid Team" | rows 491–504 (cap 14), x=1176 | rows 457–469 (cap 13), x=1197 | same |
| Party portraits | 4 slots outer 56×56 at x=1174, 1237, 1300, 1364 (pitch 63), y 518–574 | 4 slots outer 50×51 at x=1196, 1253, 1310, 1368 (pitch 57), y 482–533 | C3 portraits are 6 px smaller with a 6 px tighter pitch. Count is data (12, `00 §2.4`): 12 × 57 does not fit 320 px — `10-screen-audit.md` owns the paging/overflow decision. |
| Button after portraits | **"Team"** — cog glyph + label, outer 1427–1489 × 522–573 (63×52), fill 1429,524 59×48 | **"Edit"** — cog glyph + label, outer 1435–1489 × 482–533 (55×52), fill 1437,484 51×48 | Same button, different label. **Use "Edit"** — C1 also has a second, redundant "⚙ Edit Team" text row (rows 587–603, x 1286–1373) under the portraits which C3 drops; C3 is the deduplicated version. |
| Commit CTA "Send Them Anyway" | red fill x 1179–1482 × y 623–685 (h 63), label rows 618–650 merge with the top highlight (AI), cost row amber rows 660–673 | red fill x 1201–1483 × y 575–635 (h 61), label cap rows 583–601 (cap 15, y descender), cost row amber 610–625 (coin 16×16 + "3,200") | Same CTA, C3 2 px shorter. The trailing ")" after the cost is an AI text artifact in both — drop it. Button fill: crimson `#8F1519`→`#AC1B1A` with 2 px bronze border; exact ramp in `06-ui-component-kit.md`. |

Net: the C3 panel is the tighter, later revision (heading removed, duplicate Edit row removed, one more reward slot, smaller portraits). **Ship C3's layout** with C1's warmer title white and the data-driven slot/portrait counts.

## 6. Header tagline "Bad People. Worse Decisions." (the concept's; the game's reads "Questionable people. Worse decisions." since 2026-09-14 — same slot, same face, wider)

- **Text rect**: x 104–307, cap rows 62–72, descenders to 76 → **cap height 11, baseline y=73**, glyph box 104,62 → 204×15. Sentence case, regular weight, same humanist sans as the nav labels (not the wordmark's blackletter-serif).
- **Colour**: `#E0E0E0` (samples `#D8D8D8`, `#E0E0E0`, `#D0D0D0`, `#C0C0C0` at the antialiased edges) — a neutral light grey, deliberately cooler than the wordmark's `#E0C8B0` bone so it reads as a subtitle, not part of the logotype.
- **Trailing rule**: 2 px line at y=67–68 (vertically centred on the cap height), colour `#988880`, running from x=313 to x=374 (61 px), fading in over its first ~3 px and out over its last ~3 px (the fade is why an edge scan at thr 25 finds no start — the exact start is ±3). Ship it as a flat 60×2 rule at (313,67), no fade; start x = text.right + 6.
- **Relative to the wordmark**: wordmark cap box x 97–372, y 15–50 (36 tall). Tagline left edge is 7 px right of the wordmark's left edge (104 vs 97), aligned to the "T" stem, not the flourish. Tagline cap top is 12 px below the wordmark's bottom (62 − 50). Tagline + rule right edge (374) ≈ wordmark right edge (372) — the rule is sized to make the block right-align with the logotype.
- **Emblem/wordmark delta vs Concept 1**: C1 has no tagline and its wordmark is 44 tall at y 20–63, x 104–408 (305 wide). C3 shrinks the wordmark to 36 tall (0.82×), lifts it to y=15, and narrows it to 276 so the wordmark + tagline block (y 15–76) occupies the same band as C1's wordmark alone (20–63 plus rule at 74). Emblem: C1 60×69 at (28,15); C3 70×73 at (19,11). Production: **one header** — if the tagline ships, use C3's layout everywhere (wordmark 276×36 at (97,15), tagline baseline 73, rule (313,67)); otherwise C1's. Do not let the logotype change size between screens.
- Both text strings are legible; no AI-text artifact.

## 7. Speech bubble over the camper

Positioned over the campfire group (the speaker is the seated orange-haired camper at (357,500)); the bubble does not touch the callout plates.

- **Fill rect**: x 380–539, y 375–422 (160×48), colour `#040E18` (samples `#00101C`, `#000C14`, `#000C18`) — identical fill to the callout plates.
- **Border**: 2 px, same two-line grey as §3 (`#645D5A` outer at y=373, `#2D3135` inner at y=374; left x=378–379; right x=540–541; bottom y=423–424). Outer rect **378,373 → 164×52**.
- **Corners**: chamfered 4 px, same as the callouts.
- **Shadow**: 2 px `#0F0007`/`#000004` right and below.
- **Tail**: downward triangle, base on the bottom border at y=424, x 457–470 (14 wide), apex at y=430 (6 tall). It is drawn in the border grey and is half-swallowed by the red tent behind it — barely legible at 1:1. Ship a **14×8** tail in the border colour with the fill colour inside, base centred on the speaker's x.
- **Text**: two lines, left-aligned at x=391 (fill.x+11): line 1 "I think I'm ready" cap rows 383–393, y-descender to 396 (cap 11, baseline 393); line 2 "for a real raid this time!" rows 402–412 (baseline 412). **Line pitch 19.** Colour `#D0D0D0` (samples `#D0D0D0`, `#C0C0C8`; darker `#A0A8A8` are AA edges). Text top = fill.y+8; text bottom = fill.bottom−10.
- Same type size as the callout subtitle (cap 10–11) but in the light grey, not the blue-grey.
- Production: the bubble is a `Label` (so `test_screens.gd` can read it) inside the same chamfered `StyleBox` as the callouts, `autowrap` off, width = text width + 22. Tail is a child `Polygon2D`. The line is fixture text; the source of bubble lines is the raider's quip table (docs/05).

## 8. "Recent Events" → "View All" link

- **Text rect**: x 1441–1487, cap rows 752–762 → **47×11**, cap height 11 (same 11 as the tagline; smaller than the 14-cap title beside it). Baseline y=762.
- **Underline**: 1 px at y=765 (3 px below the baseline), x 1441–1487, same colour as the text.
- **Colour**: `#C0A898` at the glyph cores (samples `#C0A898`, `#A8A098`, `#989088`, `#787068` at AA edges) — a muted bronze-grey, i.e. the wordmark bone `#E0C8B0` at ≈70% lum. It is the only underlined text on any of the three concepts, so underline = link affordance.
- **Position**: right edge 1487 = panel fill right (1517) − 30; cap rows 752–762 sit inside the title's 751–764 — baseline-aligned with "Recent Events" (title baseline 764 vs link baseline 762, 2 px jitter). Panel-relative: (fill.right − 76, fill.top + 15).
- Production: a flat `LinkButton`/`Button` with text "View All", font size matching cap 11, colour `#C0A898`, underline always on; hover brightens to the wordmark bone `#E0C8B0`. Absent on C1 — add it there too (same panel component).

## 9. Camp scene composition in production terms

The C3 scene is full-bleed (0–1536 × 0–1024) with every chrome element overlaid on it; nothing is framed. Layer order, bottom to top, and what must be its own node (scene rects below are visual extents read from the 1:1 frame, not edge-detected — the painting has no hard edges to measure):

| Layer | What | Sprite or baked | Reason |
|---|---|---|---|
| 0 | **Sky + distant city** (turquoise sea, twin-spired city on the far headland upper-right; second island city at 1000–1250 × 60–150) | **Baked** into the terrain plate | Never changes state; no parallax is implied (single-plane mockup). One 1536×1024 PNG. |
| 1 | **Terrain plate** — the cliff-top plateau, stone steps, dirt paths, fences, crates/barrels, the wooden dock and pier at right (1000–1160 × 380–520), foliage, the sea below | **Baked**, same PNG as layer 0 | The plateau is one continuous painting; slicing it buys nothing. Fixtures that flicker are small sprites on top (layer 5). |
| 2 | **Buildings**: Tavern (timbered hall with skull banner, 240–650 × 150–380), Blacksmith forge tent (690–960 × 240–390), Training yard fence + dummies (690–1000 × 440–600), Outpost watch-post (560–700 × 560–680), the red camp tent (180–420 × 380–520) | **Separate sprites** over the plate | State-dependent: canon's town has gated buildings (Blacksmith is a "Maybe", `00 §2.6`) and rank-based unlocks; a building must be swappable for its locked/unbuilt/upgraded variant and clickable (hit-rect = sprite rect). Baking means a full-plate repaint per state. The plate under each building is painted as bare ground so the building can be absent. |
| 3 | **Campfire** (380–430 × 500–540) with glow | **Separate animated sprite** + additive glow | Looping flame; glow pulses and lights the seated raiders — a `PointLight2D` with a soft texture, not baked light. |
| 4 | **Banners** (Tavern skull banner 510–590 × 170–280; red pennants on poles at 340–370 × 360–460 and 610–650 × 470–560; hanging cloth at 590–640 × 620–700) | **Separate sprites**, 4–6 frame wave loop | Wind animation; the skull sigil is the guild's — where a future guild-emblem choice would show. |
| 5 | **Torches / lanterns / forge fire** (fence torches, tavern windows, forge hearth at 760–800 × 300–340) | **Small animated sprites** (8–16 px flames) | Flicker; the plate has the unlit fixture painted, the sprite adds flame + glow. |
| 6 | **Airship** (moored dirigible upper-right, 980–1280 × 130–420, rigging to the dock) | **Separate sprite**, slow bob (±2 px, 4 s) | Arrives/departs with raids (it is the "send them" vehicle) — needs presence state and a departure animation. Rigging is baked into the sprite, not the plate. |
| 7 | **Raiders** (seated at the fire ×5, standing on the training yard ×6, walking the paths ×4, tavern balcony ×3) | **Separate sprites** (overworld sprites, `07/08-assets-sheet-*.md`) | Data-driven: which raiders exist, where they idle, morale-dependent idle pose; the camper who speaks (§7) must be addressable. The mockup's ≈18 figures already exceed canon's roster cap floor — placement is a slot list per building. |
| 8 | **Speech bubble** (§7) | UI node | `Label` for the test suite. |
| 9 | **Building callouts** (§3) | UI nodes, anchored to building anchor points | Clickable; text is canon data. |
| 10 | **Chrome**: header plate + rule, rail gradient, sidebar, strip rule + cards + events | UI | The header/rail dark plates are gradients over the scene (rail opaque to x≈150, transparent by x≈200; header opaque to x=414, gone by 440), so they are `TextureRect`/`StyleBox` gradients, not baked. |

Practical consequence: the terrain plate PNG is painted **without** buildings, fire, banners, airship or people — it is the empty plateau — and `09-background-plates.md` should list it as such. Everything with a state or a loop is a sprite. The distant city and sky have neither and stay in the plate. If a 16:9 extension is chosen (`00 §4`), the plate needs 128 px of extra sea/sky on each side, which is why the sky must be painted wider than 1536 now.
