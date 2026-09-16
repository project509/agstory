# 06 — UI component kit (measured from the three master references)

> **Status:** Measured (all 9 sections) · **Owner:** Art pass · **Updated:** 2026-09-09
> **Inputs:** `ideaboard/Reference Concepts/Reference Concept {1,2,3}.png` at 1:1 (1536×1024 = the framebuffer). Measured with `tools/art/refkit.py`.
> **Read first:** `00-canon-reconciliation.md` — content corrections (morale row, Ranger, named bosses, header chips, rail labels) are decided there and are cited, not re-argued, here.

**In one line:** one panel, one slot, one CTA, one bar family, one chip, one callout — measured on every concept they appear on, reconciled to a single spec each, with 9-slice margins and a Godot mapping.

Conventions: all coordinates are framebuffer pixels on the named concept (`C1`/`C2`/`C3`); hexes are sampled with `refkit px`/`row`/`col`; where the reference is an AI-mockup artefact it is called out as **ARTEFACT** with the clean resolution.

---

## 1. Panel

Measured on: C1 "Current Raid" sidebar (outer rect **x 1143..1519, y 74..718 → 377×645**), C1 "Recent Events" log (top line y 734-735), C3 "Current Raid" sidebar (**x 1165..1519, y 76..662 → 355×587**), C2 combatant panel #1 (outer line x=21 / y=736, inner line x=31-32 / y=740-742, right outer x=260-261, right inner x=254), C2 log panel (outer x=1044-1045, inner x=1050-1051, top outer y=736-737).

**Verdict: one panel, three tints.** All four share the same anatomy — a thin 2px bevelled rim, a dark 5px "moat", then the fill, with an optional 1px inner highlight on the fill's edge. C1 adds a bronze corner ornament and a 12px ornamental band along top and bottom only; C2 tints the rim steel-blue and chamfers the inner line ~3px. Those are concept-level variations of the same component, not different components.

| Layer (outside → in) | Width | C1 sample | C3 sample | C2 sample | **Canonical** |
|---|---|---|---|---|---|
| Drop shadow onto scene | 6px | `#0A0A0F` band over bright scene (x 1136..1142 @ y400), 1px hard `#050F17` hugging the rim | 1px `#0D1113` only | none visible | 1px hard `#050F17` α1.0 + 6px shadow `#0B1118` α0.45 (no pure black — 00 §3) |
| Rim, outer px | 1 | `#5F4D3E` (L), `#393535` (R) | `#4E4847` (L), `#4F4E46` (R) | `#40414E` | `#4F4E46` |
| Rim, inner px | 1 | `#856A57` (L), `#4E4744` (R), `#836858` (T) | `#7E7A79` (L), `#807C78` (R) | `#535259` | `#7E7A79` — the light px is always on the *inner* side, i.e. the rim reads as a raised lip |
| Moat | 5 | `#02070E` | `#000308` | `#00040E` | `#02070E` |
| Inner highlight (edge of fill) | 1–3 | absent on sides; 2px `#514945` line at y 84-85 as part of the top band | 3px `#041824`/`#0B1E2C` on all four sides | 1–2px `#3F5161`/`#4A5869` all sides | 1px `#0B1E2C` on all sides (a StyleBoxFlat border on the fill) |
| Fill | — | `#0B131A` (sides), `#07111A` (upper area) | `#010E19` | `#010D18` | `#0A1219` flat. Measured top→bottom drift is ≤ 4 levels of blue — flat is within AI noise; do not gradient. |

**Corner radius: 0.** C1 and C3 corners are square (crops `p1tl.png`, `p3tl.png`); the C2 inner line shows a ~3px chamfer — treat as tint-variant option `corner_radius 3` on the *inner* highlight only; the rim stays square.

**Corner ornament (C1, C3):** an L-shaped bronze flourish `#83542E` with `#F27043` highlight, ~14×14, sitting on the rim's inside corner (C1 TL at x 1143..1157, y 74..88). Along the C1 top and bottom edges the ornament continues as a 3px rail (y 79-81 top, y 711-713 bottom) that is bronze near the corners and fades to grey `#181C1F` by x=1250 — **ARTEFACT** (inconsistent rail colour). Resolution: ornament = 4 corner TextureRects only; no continuous rail. The C1 12px top band (rim 74-75 · rail 79-81 · line 84-85) and mirrored bottom band (706-707 · 711-713 · 717-718) are therefore reduced to rim + moat; the title "Current Raid" keeps its measured baseline.

**Tints:** `warm` (C1: rim `#5F4D3E`/`#836858`) for Home/Camp, `steel` (C2: rim `#40414E`/`#535259`, inner `#4A5869`) for Raid. C3 samples neutral (`#4F4E46`/`#7E7A79`) — between the two; canonical rim hexes above are the neutral ones so both tints are a hue shift of one token pair.

**9-slice margins (if textured):** L/T/R/B = **8/8/8/8** (rim 2 + moat 5 + highlight 1). Minimum source texture **24×24** (8+8 margins + 8px stretchable centre); author **32×32** so the centre tile is not a single 8px run. The corner ornament is a separate 16×16 sprite overlaid, not baked into the 9-slice (it would stretch).

**Godot:** nested `StyleBoxFlat` reproduces this exactly (§9 Table B): outer `Panel` = bg `#02070E`, border 1px `#4F4E46`, shadow_size 6 shadow_color `#0B1118` α0.45; a second `Panel` inset 1px with border 1px `#7E7A79` (the light rim px); inner `Panel` with content margin 7 = fill `#0A1219`, border 1px `#0B1E2C`.

## 2. Item slot

Measured: C1 Potential Rewards row (slot 1 **x 1175..1221, y 335..381 → 47×47**, pitch 57 → 10px gap; slots at x 1175, 1232, 1288), C1 Raid Team portrait slots (**x 1174..1229, y 517..574 → 56×56**, pitch 63 → 7px gap), C3 rewards row (same 47 slot, same 2px rim), C1 roster-card gear slots (47, three per card), C1 "Available" mini-grid (portrait slot ~40px, 2 per row), C2 combatant ability grid (~40px thin-rim slots, 3×2, plus a tall weapon slot ~62×74).

**Canonical slot = 47×47, corner radius 4, 2px bevelled rim, flat navy fill, sunken.**

| Part | Measured | Canonical |
|---|---|---|
| Outer size | 47×47 (C1, C3, roster cards) | 47×47 (pitch 57 in rows → 10px gap) |
| Corner radius | ~4px on all rewards/gear slots (montage `m_slot.png`) | 4 |
| Rim top/left | 2px: outer `#232224` → inner `#3B383A` (x 1175-1176); top `#2F2D2C`/`#363334` | 2px `#33302F` |
| Rim bottom/right | 2px: inner `#5C4C46` → outer `#2A2524` (x 1219-1221); bottom `#615247`/`#2F2A27` | 2px `#5A4B44` — warmer and lighter than top/left → the slot reads *inset* (light catches the lower lip) |
| Fill | `#0E1319` top → `#111A22` centre → `#12191F` bottom | flat `#11181E`; the ≤4-level gradient is noise |
| Icon | centred, ~34px art | 32×32 sprite centred (icon sheets slice at 32; see `07/08-assets-sheet-*.md`) |

**Variants**

| Variant | Where | Delta from canonical |
|---|---|---|
| Plain | rewards rows (C1, C3), roster-card gear (C1, C3) | none |
| Empty | C3 rewards slot 3 (no icon, same rim) | same chrome, no icon; do **not** darken the fill — the reference keeps it identical |
| Bronze-bordered (portrait-holding) | C1/C3 Raid Team, C1 "Available" grid | **56×56**, radius 5, rim 3px = `#272120` · `#7C6454` · `#272120` (dark/light/dark — 1px bright bronze core, x 1174-1176), right rim reads `#5A4E47`; fill hidden by the portrait; pitch 63 (7px gap). Portrait art is 48×48 centred. "Available" uses the same rim at ~40px — same StyleBox at a smaller size (StyleBoxFlat scales; no texture). |
| Ability-icon with stack numeral | C2 combatant panels (3×2 grid) | ~40×40, **1px** rim `#3F5161` (steel, matches the C2 panel tint), radius 3, fill `#0A1422`. Stack numeral: white `#F4F4F0` digit, ~12px cap, 1px dark outline `#0B1118`, anchored bottom-right with 3px inset. Ready abilities carry a **gold rim** `#C9A24A` + inner glow (C2 Gruk's two lit icons) — the rarity-border chrome reused as *state*. |
| Rarity-bordered | C2 lit icons; C1 gem slot (purple bleed) | same 47 slot; rim colour = `Palette.rarity_color()` (04-palette.md), fill unchanged. Legendary adds a 1px outer glow at α0.35 of the rim colour. |
| Weapon slot (C2) | left of each ability grid | 62×74, same 1px steel rim, radius 4 — a taller instance of the ability slot, not a new component |

**9-slice margins:** 6/6/6/6 (rim 2 + radius 4) if textured. Every variant is reproducible with `StyleBoxFlat`; per-side border colours are not supported, so render the bevel as *two* StyleBoxFlats: base with border 2px `#33302F`, overlay Panel with `border_width_left/top = 0` and bottom/right 2px `#5A4B44`. Minimum source texture 16×16.

## 3. Primary CTA ("Send Them Anyway")

Measured: C1 **x 1179..1483, y 617..685 → 305×69** (row y=645, col x=1330). C3 **x 1201.., y 571..635 → 65 tall** (row y=600, col x=1330) — 4px shorter, same anatomy. Canonical = C1 (HOME is the primary screen). Both render two centred lines: **"Send Them Anyway"** (white `#FFFFF7`, x-height rows 636-646 → ~24px font, cap ≈17px) and a cost line with a gold coin icon + `2,400 )` in gold `#C8AF73`/`#E8C878` (~18px). The trailing `)` is an **ARTEFACT** (garbled glyph) — render coin icon (16px) + `2,400` in tabular figures, no paren.

**Layers, outside → in (vertical, at x=1330):**

| y | px | Colour | Role |
|---|---|---|---|
| 616 | 1 | `#020108` | hard shadow line |
| 617-619 | 3 | `#593526` · `#FCB85D` · `#E69451` | **outer rim**: 1px bright core `#FCB85D`. Top edge reads gold; sides read red (`#D23D36` at x 1180-1181); bottom reads orange `#F47A46` (y 683-685) — **ARTEFACT** (rim hue drifts). Resolution: outer rim 2px `#D23D36` all round, with a 1px top highlight `#FCB85D` and 1px bottom `#F47A46` — a bevelled red rim lit from above. |
| 620 | 1 | `#4A262B` | gap |
| 621-622 | 2 | `#B86353` · `#E7705E` | **inner rim**: 1px salmon `#E7705E` |
| 623-634 | 12 | `#7A2931` → `#5D1E27` | plate, upper stop |
| 635-647 | — | text line 1 (white) | |
| 648-652 | — | `#5B2028` | plate mid |
| 653-666 | 14 | `#32131C` → `#38141E` | plate, lower stop (darker) |
| 667-668 | 2 | `#230911` · `#17030A` | plate bottom shade |
| 683-685 | 3 | `#E2744D` · `#F47A46` · `#B05034` | outer rim bottom (orange) |

**Plate gradient:** vertical, 2 stops: `#601E28` (y 623) → `#33131B` (y 666). Sides: `#5E1D27` at x 1186-1196 confirms the top stop is uniform across the width.

**Notches:** all four corners chamfered at 45°, cut **8px** on both axes, on *both* rims (montage `m_cta.png`; the inner rim follows the chamfer at a 4px inset). Inner rim inset from the outer rim = 4px (y 617→621).

**Size and margins:** 305×69. 9-slice margins **L/T/R/B = 12/12/12/12** (8px chamfer + 4px inner-rim inset) — a `StyleBoxTexture` from a 40×40 authored source (12+12 margins, 16px centre). This is the one component that **needs a texture**: StyleBoxFlat cannot chamfer. (Alternative `_draw()` with two polygons + gradient — not worth it for one texture at four states.)

**States (designed — none are shown in the references; justified from the plate language):**

| State | Plate | Outer rim | Inner rim | Text | Why |
|---|---|---|---|---|---|
| Normal | `#601E28`→`#33131B` | `#D23D36`, top `#FCB85D` | `#E7705E` | `#FFFFF7` / gold cost | as measured |
| Hover | plate one step brighter: `#7A2931`→`#43181F`; 6px outer glow `#F27043` α0.30 | `#E94E4E` | `#F0857A` | unchanged | the C3 CTA (`#E94E4E` rim, `#621822` plate) is exactly "C1 one step brighter" — the two references already give normal and hover |
| Pressed | gradient inverted `#33131B`→`#601E28`; no glow; content offset +1px y | `#B02A2B` | `#B86353` | unchanged | inset read: the bevel's light moves to the bottom |
| Disabled | desaturated `#2A1B20`→`#1B1216`; no glow | `#5A3A3E` | none | text `#8A7F80`; the cost line is replaced by the reason string (`Widgets.button_with_reason`, asserted by tests) | keeps the silhouette so layout does not jump; the reason text stays a `Label`, test-readable |

The same chrome at a bronze rim / navy plate tint is the **secondary button family** (§7).

**The rule for when a control is crimson (CRITIC-G16, recorded 2026-09-15 — W4-HYGIENE):** **crimson = spends time, gold or a raider; everything else is secondary.** One per screen at most, and it is the screen's commit — the thing the player came to do and cannot take back: "Depart" (a day and a party), "Hire — 60 G", "Sell — 40 G", "Commission the work — 150 G", "Rest until recovered" (it costs days, so it qualifies), "Go to prep" / "Open the board" (`Town.HUB_CTA`), "See how it ended" and "Back to town — the guild carries on" (the campaign's own commits). Settings' **Apply** is not a spend, so it is **`ButtonSecondaryLit`** — the secondary silhouette in the engaged tint (§7.2, HALL-17), which is what it has been since W3-OPTIONS. RaidView's wax "The report" is the same commit grade in the wax material (`Widgets.wax_button`). A screen with no spend has no crimson (Town's is behind its switch; Market's is the sell confirm; RaiderDetail, LoadSave and Results' ordinary clear have none). `Widgets.cta()` is the only constructor, and it carries the guard (KIT-05) that keeps the two-line text inside the plate.

## 4. Progress bars

Three bars measured; they are one family (1px steel rim, dark navy track, two-tone fill, rounded end caps) at three heights.

| Bar | Concept · rect | Outer size | Rim | Track | Fill (top → bottom) | Caps | Text |
|---|---|---|---|---|---|---|---|
| **Boss HP** | C2, x ≈935..1297, **y 85..108** (col x=1150) | ~363×**24** | 2px bevel: `#2D364C` outer / `#72809B` inner (top), `#455C7C`/`#132742` (bottom); right end x 1296-1297 `#1B2A46`/`#32415E` | `#01152C` (18px tall) | `#F24A50` (top 4px) → `#F02434` body → `#B01A28` (bottom 3px) | radius 6 both ends (montage) | `48,532 / 120,000` right-aligned inside the track, white `#F4F4F0` ~20px, 8px right pad. Values are fixture data (00 §2.3). |
| **Combatant HP** | C2 card 1, **x 40..243, y 838..854** (row y=846, col x=100) | **204×17** | 1px `#2C3F5C` (right end x 242), top `#11384D` | `#010D1B` | `#F54841` (top 5px, y 840-844) → `#811725` (lower 8px, y 846-852) — a hard two-tone, not a smooth gradient | radius 5 | `48/128` centred, white ~18px, 1px `#0B1118` outline |
| **Combatant secondary (mana/stamina)** | C2 card 1, x 40..243, **y 862..878** | 204×17, 7px below HP | 1px `#0A1F29`/`#17272D` | `#010D1B` | `#019CD0` (top 6px) → `#00638E` (lower 8px) | radius 5 | `32/60` centred |
| **Morale bar (C1 roster card)** | C1 card 1, **x 197..324, y 853..861** | 128×**9** | 1px `#033246` top, `#125251` bottom shade | none visible (bar at 100%; track presumed `#041119` = card fill) | horizontal hue sweep `#2DB2CD` (left) → `#45C558` (right); vertical `#23ADD3` highlight row → `#1F8C9B` | square | "Morale:" label painted **over** the bar — **ARTEFACT** |

**Canon note:** the morale bar is **not implemented** — 00 §2.1 forbids a bar for morale. Its 9px thin-bar chrome is recorded only as the family's small size, available for non-morale uses if one arises; nothing in the references requires it.

**Canonical bar spec (the Combatant size is the default):** outer 204×17; `StyleBoxFlat` rim 1px `#2C3F5C`, radius 5, track `#010D1B`; the fill is inset by the 1px rim, radius 4, drawn as two stacked rects (highlight 5/13 of the inner height, shade 8/13). `ProgressBar.fill` cannot do two-tone, so Table B chooses a custom `_draw()` (six lines, exact). The fill's right end follows the rim radius only when ≥ 96%; otherwise it is a hard vertical cut (visible on Boss HP at 40%: the fill ends square at x≈1090 — montage). Colours by role: HP `#F54841`/`#811725`, Mana `#019CD0`/`#00638E`, Boss `#F24A50`/`#F02434`/`#B01A28`. Boss variant = same spec at 24 tall, rim 2px bevel `#72809B` inner / `#2D364C` outer, radius 6.

## 5. Nav rail item · resource chip

### 5.1 Nav rail item

Measured on C1 (active "Home": col x=100, row y=133) and C3 (active "Camp"). Labels are canon's building names, per 00 §2.6; only the chrome is measured here.

| Part | C1 measurement | Canonical |
|---|---|---|
| Active plate rect | **x 0..210, y 106..159 → 211×54**; flush to the screen's left edge | 211×54, x=0 |
| Item pitch | 55px (C1 centres y≈133, 188, 243…); C3 reads 56 | **55** |
| Plate fill | horizontal gradient `#0A1520` (x=0) → `#1B3446` (x=207) | 2-stop horizontal gradient, same hexes — the plate brightens toward the scene |
| Plate rim | top 2px `#4C6B81`/`#43647E` (y 106-107); bottom 2px `#3C5C74`/`#4E7C9A` (y 157-158); right 2px `#457892`/`#4C83A2` (x 209-210); **no left rim** (bleeds off-screen) | 2px `#4C83A2` on top/right/bottom, 0 on left |
| Right-end shape | tab: top-right and bottom-right corners chamfered ~6px; a 3px rivet dot `#4C83A2` inside the top-right chamfer (montage `m_nav.png`) | chamfer 6, rivet drawn as a 3px circle — **StyleBoxTexture** (chamfer) or `_draw()`; Table B: texture, 18/8/18/8 margins |
| Icon | 32px cream `#F9F3E0` glyph at x 22..54 (row y=133 shows `#F9F3E0` at x=23), vertically centred | 32×32 sprite, x=22 |
| Label | cream `#F0EAD8`, ~26px, x=72, baseline ≈ y 141 | Label at x=72, font size per `05-typography.md` |
| Inactive | no plate; icon `#8A8A8A` (grey), label `#B8B4AC`; same positions | icon/label modulate only — no chrome change |
| Hover (designed) | inactive + plate at 40% alpha, no rim | plate ghost tells the cursor where the tab will land; rim reserved for the active state |

### 5.2 Resource chip

Measured on C1 gold chip (row y=38, col x=900): **x 857..1005, y 15..60 → 149×46**. The four chips (gold · gem · book · day) share one chrome; contents are reassigned per 00 §2.5 (gold, Reputation, raiders available/12, Day N · rank).

| Part | Measured | Canonical |
|---|---|---|
| Size | 149×46 (gold, widest content); chips are content-sized | height **46**, width = content + 2×16 padding, min 96 |
| Corner radius | ~10 (pill-ish, montage) | 10 |
| Rim | 1px `#2F333A` (top, y=15); bottom `#121D26`; sides `#171E27` faint | 1px `#2F333A` — treat the darker bottom/side samples as the rim over darker ground |
| Fill | `#030B14` | `#030B14`; the chip is darker than the panel fill `#0A1219` on purpose (reads as a well) |
| Inner shadow | 2px darkening under the top rim (`#0C0E12` at y 32) | `StyleBoxFlat` cannot inner-shadow; skip — within noise |
| Icon | 32px coin at x 875..907 (`#F0B557` core `#EBA845`), vertically centred | 32×32 sprite, 16px from the left rim |
| Value | cream `#F0EAD8` ~26px tabular figures, x=925, 8px after icon | Label, tabular figures (05-typography) |
| Chip 4 (day) | sun icon + `Day 23  16:40` | `Day 23 · Unknown` — icon = rank sigil (00 §2.5). No better reading was found here: the chip has room for a 32px icon and ~110px of text; "Day 23 · Unknown" fits at 26px. |

## 6. Callout box (success chance)

Measured: C1 red variant (col x=1330 y 385..485, row y=440): **x 1181..1500, y 393..473 → 320×81**. C3 amber variant (col x=1330 y 360..450): y ≈370..440, same width, same inner layout.

| Part | C1 red (17%) | C3 amber (42%) | Canonical |
|---|---|---|---|
| Size | 320×81 | 320×~70 (fixture text is one line shorter) | 320 wide, height = content (label 20px + value 40px + 3×8 padding ≈ 84) |
| Rim | left 3px bright `#F54A40` (x 1181-1183); right 2px `#BC3230`/`#92262A` (x 1499-1500); top 2px dim `#62181A` (y 393); bottom 2px `#732022` (y 472-473) | ~1px neutral `#272520` bottom; top not resolvable through text; **no red** | 2px rim in the *severity colour* at α0.85, plus 1px extra on the left (a 3px "spine") — the reference brightens the left and right rims and dims top/bottom: read as rim colour × a left-right light sweep. Implement as: rim 2px severity colour; a 1px inner left spine at severity colour full alpha. |
| Plate | horizontal gradient `#0A0C12` (left, x≈1200) → `#3B141A` (right, x 1470-1497) | `#000C15` flat with a faint warm right edge | 2-stop horizontal gradient: panel fill `#0A1219` → severity colour at α0.30 over `#0A1219` (red → `#3B141A`; amber → `#2A2014`) |
| Corner flourish | top-right: small bronze-red leaf/scroll ornament, ~18×14, overlapping the rim at (1478..1496, 393..407) | same ornament in amber/bronze | 18×14 sprite, top-right, tinted with the severity colour; authored once in Aseprite (Table A) |
| Corner radius | 0 (square) | 0 | 0 |
| Label | "Estimated Success Chance", cream `#E8E0D0`, ~20px, x 1195, y 404..419 | same | Label, 12px from the left rim, 10px below the top rim |
| Value | "17%", `#E8433A`, ~40px bold, y 425..465 | "42%", `#F0B040` | Label, tabular figures, coloured by band |
| Bands (designed) | <25% red | 25–59% amber | ≥60% **green** — no green variant is shown; take the C1 morale-bar green `#45C558` as the third severity so the three bands share one family. Thresholds are 🔷 PROPOSED and belong behind a `GameSettings` switch if the designer's notes give different numbers. |

## 7. Inset/well · secondary + icon buttons · text links

### 7.1 Inset / well (mission image well, C1)

The mission illustration sits in a well inside the Current Raid panel: left rim at **x=1161** (1px `#292B2E`, row y=200; image starts x=1162), horizontal extent x 1161..≈1502; vertical ≈ y 130..246 (title "The Sludge Maw" overlaps the bottom 20px over a dark gradient). Canonical well: `StyleBoxFlat` fill `#02070E`, border 1px `#292B2E`, radius 0, content clipped; image fades to `#02070E` α0.9 over the bottom 24px so the title stays legible. The C1 "Available" mini-grid and both log panels use the same well (fill darker than the panel by one step, 1px neutral rim).

### 7.2 Secondary buttons

| Button | Concept · rect | Chrome | Content |
|---|---|---|---|
| "Team" gear (Raid Team row) | C1 **x 1426..1490, y 517..574 → 65×58** (row y=545, col x=1460) | **portrait-slot chrome** (§2): 3px rim `#554339`·`#886955`·`#35302F`, radius 5, fill `#0E161E` | gear glyph `#95908C` 26px at y 526..548; label "Team" `#878384` ~14px at y 557..565 |
| "Edit" (C3 equivalent) | C3 Raid Team row, same size | identical | gear + "Edit" |
| Cog / fast-forward (C2 raid controls) | C2 cog ≈ x 10..54, ff ≈ x 73..121, **y 674..719 → ~45×46** (row y=698, col x=30) | 1px steel rim `#484F5C` (x=54, x=121), radius 3, **top highlight 2px bronze** `#A78B7A`/`#958177` (y 674-675), fill `#010A17`; corners chamfered ~5px with a rivet dot (montage `m_misc.png`) — the nav-tab end shape reused | cog `#9C9DA8` 24px; ff two triangles cream `#E0C8B0` 22px — the ff is tinted warm because it is the *active* control; canonical: icon `#9C9DA8` idle, `#E0C8B0` when the control is engaged |

Canonical **secondary button** = the CTA silhouette (§3) at a neutral tint: rim 2px `#886955` (bronze), inner rim none, plate `#1A2431`→`#0E161E` vertical gradient, chamfer 8, text cream. States mirror §3 (hover = plate +1 step and bronze glow α0.25; pressed = gradient inverted; disabled = rim `#3B3733`, text `#6E6A66`). Icon-only buttons are the same StyleBox at 46×46 with chamfer 5.

### 7.3 Text links

| Link | Concept · rect | Style |
|---|---|---|
| "View All" | C3 log header, x ≈1441..1489, y ≈750..762 | `#B8B4AC` ~14px, **underlined** (1px, same colour, 2px below baseline); right-aligned to the panel's inner edge |
| "Edit Team" | C1 below Raid Team row, x ≈1290..1375, y ≈586..602 | gear glyph 14px + `#C8C2B8` ~16px text, **no underline**, centred under the row |

Canonical text link: `LinkButton`, colour `#B8B4AC`, hover `#F0EAD8`, underline `ALWAYS` for "View All" style (navigational) and `ON_HOVER` for "Edit Team" style (in-place action). Both are `Button`-derived so `test_screens.gd` sees their text.

## 8. Composites: roster card, combatant panel, building callout, speech bubble + emote, log row, tooltip

| Composite | Measured | Built from |
|---|---|---|
| **Roster card** (C1, C3 bottom strip) | C1 card 1: top rim y 735-736 (`#88786C` light outer / `#4D4A47`), bottom rim y 994 (`#6F625B`) → **261 tall**; width 244, pitch 250 (gap 6) from the overview (cards at half-scale x 62-184, 187-309, 312-434, 437-559). Fill `#000A12`→`#030D17`. | §1 Panel, *warm* tint, rim 2px light-outer (`#88786C`/`#4D4A47` — the light px is *outer* here, i.e. the card reads raised, unlike the sidebar), moat 0, no ornament; inside: §2 portrait slot (56, bronze) at (14, 17); name/level/class Labels; **morale row per 00 §2.1** (`Bork — 87 ❤` / `Warrior — Very Happy`, no bar); quote line in `#B8B4AC` italic; three §2 plain slots (47, pitch 57) along the bottom, 12px above the rim. |
| **Combatant panel** (C2 bottom strip) | Panel #1 x 21..261, y 736..~1000; steel tint | §1 Panel *steel* tint (outer 1px `#40414E`, inner line `#4A5869`, 3px chamfer on the inner line); §2 portrait slot; two §4 bars 204×17 at y 838 and 862 (7px gap) with 24px status glyphs left of them (shield `#E8433A`, drop `#3DA5D8`); §2 weapon slot 62×74 + 3×2 ability grid (40px, 1px steel rim) with stack numerals. |
| **Building callout** (C3 town) | "The Tavern": x 399..≈597, y ≈124..170 → **~199×47**; left rim 2px cream-bronze `#EABC92`/`#D4A180` (x 400-401), bottom rim 1px `#625959` (y 169), plate `#000E17` opaque; radius ~6; a 6px down-pointer under the left third (montage) | a **chip** (§5.2) variant: radius 6, rim 1px `#625959` with a 2px bronze left spine; 24px icon at x+8; title cream `#F4EEDD` 20px; subtitle `#B8B4AC` 14px with `•` separators; pointer = 6px triangle in plate colour with rim. Contents are canon's five buildings (00 §2.6). |
| **Speech bubble** (C3 "I think I'm ready…", C1 "…") | C3: ≈ x 380..545, y 385..435 → ~165×50; plate `#0B1B26` at α≈0.92, 1px rim `#4C6B81` steel, corners chamfered 4px, 6px pointer bottom-left, text `#F4F4F0` ~18px two lines, 8px padding | §1 Panel *steel* tint with moat 0 and chamfer 4 (the nav-tab end shape) + pointer; `RichTextLabel` is fine here (dialogue is not test-asserted). Width = content, max 200. |
| **Emote marker** (C1 over raiders, e.g. beer mug at ≈ x 480..520, y 470..515) | pixel speech-bubble outline ~40×44: 2px dark outline `#2A1E18`, cream fill `#F4EEDD`, 16px icon inside, 6px tail bottom-left | a **sprite**, not a StyleBox — author 40×44 in Aseprite with the icon swapped per emote (mug, ellipsis `…`, sweat, skull). Same silhouette as the C2 "Reloading… again." text bubble but cream. |
| **Log row** (C1/C3 Recent Events, C2 combat log) | rows pitch **29px** (half-scale 396, 411, 425, 439…); badge = 22px circle (red frown `#E8433A` fill, `#F4F4F0` face) at x 1074..1096; text `#E0DACC` ~20px at x 1104; C2 variant highlights keywords in bold `#F4F4F0`/red `#F54841`; log panel = §7.1 well | `HBoxContainer` row 29 tall: `TextureRect` 22 badge + `Label` (or `RichTextLabel` for the C2 keyword tint — the *town/home* log stays `Label`, test-readable). Badge glyph set: frown (failure), gem (morale), star (recruit), skull (death), check (success), coin (gold). |
| **Tooltip** — **none is shown on any concept; designed:** | — | §1 Panel *steel* tint at moat 0, chamfer 4 (= the speech-bubble chrome without the pointer), fill `#0B1B26` α0.95, rim 1px `#4C6B81`, padding 10/8; title cream `#F4EEDD` 16px + body `#B8B4AC` 14px; max width 260; appears 300ms after hover, offset (12, 16) from the cursor, clamped to the frame. Uses Godot's `Control.tooltip_text` with a `_make_custom_tooltip` returning this panel so `Label` text stays inspectable. Rationale: the speech bubble is already "a small dark steel plate that speaks over the scene" — the tooltip is the same idiom addressed to the player. |

## 9. Table A — texture production list · Table B — Godot mapping

### Table A — textures to produce

Only components that `StyleBoxFlat` cannot reproduce get a texture. Everything else is flat colour and needs no asset. "Crop" = lift from the reference at 1:1 then clean in Aseprite; "author" = draw from the spec.

| Asset | Source | Output size | 9-slice L/T/R/B | Notes |
|---|---|---|---|---|
| `ui/cta_plate.png` | author in Aseprite from §3 (crop C1 `1179,617,305,69` as the reference layer) | 40×40 | 12/12/12/12 | red-rim variant; plate gradient baked vertically, so the centre row must be stretched only horizontally — set `axis_stretch_vertical = TILE_FIT`… no: bake the gradient as 40 tall and use `StyleBoxTexture.region_rect` + `modulate` per state; four states = four 40×40 sheets, or one 40×160 strip |
| `ui/cta_plate_hover.png`, `_pressed.png`, `_disabled.png` | author (§3 states table) | 40×40 each | 12/12/12/12 | or modulate the normal texture: hover ×1.25, pressed = flip vertically, disabled = desaturate — cheaper and exact enough |
| `ui/btn_secondary.png` | author (§7.2, bronze/navy tint of the CTA) | 40×40 | 12/12/12/12 | shared by "Team"/"Edit" text buttons if they adopt the chamfer; otherwise they stay StyleBoxFlat |
| `ui/btn_icon.png` | author (§7.2 cog/ff chrome; crop C2 `10,674,45,46` as reference) | 24×24 | 7/7/7/7 | chamfer 5 + rivet; 1px steel rim, 2px bronze top |
| `ui/nav_tab_active.png` | author (§5.1; crop C1 `0,106,211,54` as reference) | 40×24 | 8/8/18/8 | right end holds the chamfer + rivet; left margin 8 is inert (bleeds off-screen) |
| `ui/panel_corner_ornament.png` | crop C1 `1143,74,16,16` and clean | 16×16 | — (sprite, 4 rotations) | bronze L flourish (§1) |
| `ui/callout_flourish.png` | crop C1 `1478,393,18,14` and clean; tint at runtime | 18×14 | — (sprite) | white-on-alpha so `modulate` gives red/amber/green |
| `ui/emote_bubble.png` + icon set | crop C1 `480,470,40,44` (mug) and clean; author ellipsis/sweat/skull | 40×44 | — (sprite) | §8 |
| `ui/bar_fill_2tone.png` | author: 1×13 (5px highlight, 8px shade) per colour, or a 1×13 white ramp modulated | 1×13 | — | only if `TextureProgressBar` is chosen over `_draw()`; Table B chooses `_draw()`, so **optional** |
| `ui/log_badges.png` | author 6 glyphs | 22×22 ×6 | — | frown, gem, star, skull, check, coin (§8) |
| `ui/rank_sigil.png` | author | 32×32 | — | replaces the chip-4 sun (00 §2.5) |

No panel, slot, chip, well, bar track, callout body, speech bubble or tooltip needs a texture.

### Table B — Godot mapping

| Component | Control | Style | Reason |
|---|---|---|---|
| Panel (§1) | `PanelContainer` ⊃ `PanelContainer` ⊃ `MarginContainer` | **StyleBoxFlat ×3** (outer rim `#4F4E46` + shadow; 1px inset rim `#7E7A79`; inner fill `#0A1219` border `#0B1E2C`) | square corners, flat fills, 1px lines — flat reproduces it exactly; the ornament is 4 `TextureRect`s |
| Item slot (§2) | `Panel` (or `Button` for interactive slots) + `TextureRect` icon | **StyleBoxFlat ×2** (base rim `#33302F`; bottom/right-only overlay `#5A4B44`) | radius 4 + 2px border is flat's home ground; the per-side bevel needs the second box |
| Portrait slot / "Team" button | `Button` | StyleBoxFlat (3px rim `#886955`, radius 5) | flat reproduces the dark/light/dark rim as border `#886955` 1px inside a 1px `#272120` border (two boxes) |
| Ability slot + numeral | `Panel` + `TextureRect` + `Label` | StyleBoxFlat (1px `#3F5161`, radius 3) | flat; gold "ready" rim is a border colour swap |
| Primary CTA (§3) | `Button` | **StyleBoxTexture** `cta_plate*.png`, margins 12 | chamfered corners + inner rim cannot be flat; one texture per state (or modulate) |
| Secondary button (§7.2) | `Button` | StyleBoxTexture `btn_secondary.png` **or** StyleBoxFlat radius 3 if the chamfer is dropped | chamfer only |
| Icon button (cog, ff) | `Button` 46×46 | StyleBoxTexture `btn_icon.png` 7/7/7/7 | chamfer + rivet |
| Progress bars (§4) | custom `Control` with `_draw()` (`draw_style_box` for track, two `draw_rect` for fill) | StyleBoxFlat track (1px `#2C3F5C`, radius 5) + **custom draw** fill | `ProgressBar` cannot do a two-tone fill or the square-cut-until-96% end; six lines of `_draw()` are exact |
| Nav rail item (§5.1) | `Button` (toggle group) | **StyleBoxTexture** `nav_tab_active.png` for the active plate (gradient + chamfer + rivet); `StyleBoxEmpty` for inactive | chamfer + gradient + rivet |
| Resource chip (§5.2) | `PanelContainer` ⊃ `HBoxContainer` | StyleBoxFlat (fill `#030B14`, 1px `#2F333A`, radius 10) | flat, exact |
| Callout box (§6) | `PanelContainer` | StyleBoxFlat (2px severity rim, flat plate) + `TextureRect` flourish | horizontal gradient is not in StyleBoxFlat — plate is drawn flat at the mid-stop `#22101A`… **or** a 2×1 `GradientTexture2D` behind the labels for the exact sweep; choose GradientTexture2D (no authored asset) |
| Inset/well (§7.1) | `PanelContainer` | StyleBoxFlat (fill `#02070E`, 1px `#292B2E`) + `TextureRect` with a `GradientTexture2D` fade | flat |
| Text links (§7.3) | `LinkButton` | theme colours only | Button-derived, test-readable |
| Roster card / combatant panel (§8) | `PanelContainer` composites | StyleBoxFlat (warm / steel panel tints) | composites of the above |
| Building callout / speech bubble / tooltip (§8) | `PanelContainer` (+ `Polygon2D` 6px pointer) | StyleBoxFlat radius 6 (callout) / **StyleBoxTexture** or `_draw()` chamfer 4 (bubble, tooltip) | the 4px chamfer is small enough that `corner_radius 3` in StyleBoxFlat is visually indistinguishable at 1:1 — **prefer StyleBoxFlat radius 3** and skip the texture |
| Emote marker, badges, ornaments | `TextureRect` / `Sprite2D` | sprites (Table A) | pixel art, not chrome |
