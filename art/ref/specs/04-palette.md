# 04 — Palette & colour tokens

> **Status:** Measured · **Owner:** Art pass · **Updated:** 2026-09-09
> **Method:** every hex below was sampled from the reference concepts with `tools/art/refkit.py` / numpy (3×3 patch means, colour runs across edges, max-saturation and 90th-percentile-luma picks for text). Sample coordinates are given so any value can be re-checked in one command. Contrast ratios are WCAG 2.x relative-luminance.

**In one line:** the game's surfaces are four depths of near-black navy lit by warm off-white text, bronze edges and one steel-blue selection colour; danger is a hot red, caution a saturated amber, commitment a crimson plate under a gold rule.

This replaces docs/13 §3 (paper/ink/slate/brass, 🔷 PROPOSED — see `00-canon-reconciliation.md` §1). The *role-name* discipline is kept: screens name a role, never a hex.

---

## 1. Surfaces — the depth ladder

The references are not one dark colour. Four flat depths stack, and the eye reads the stack as physical layering. Fills were sampled where nothing is drawn on them; the ± is the spread inside a 3×3 patch (0–2 = genuinely flat).

| Role | Hex | Sampled at | Spread | Used for |
|---|---|---|---|---|
| `ground.page` | `#030B13` | C1 (1530,1018), C3 (1530,1018) `#030D15` | 0–2 | The window behind everything; the letterbox |
| `ground.frame` | `#0C151D` | C1 header (700,40); C1 gap between scene and strip (600,724) `#0C141B` | 0–2 | Header bar, the 12px gutter between regions |
| `ground.rail` | `#091116` | C1 nav rail (100,600) | 1 | Nav rail ground |
| `surface.panel` | `#060C12` | C1 sidebar (1300,300); C3 sidebar `#000D16`; C1 events (1300,980) `#050E17` | 0–1 | Every bordered panel: sidebar, roster card, events, combatant panels |
| `surface.inset` | `#0D151C` | C1 slot interior (1180,340) | 2 | Item slots, wells, bar tracks, portrait frames |
| `surface.chip` | `#020A12` | C1 chip (940,22) and (940,54) | 0 | Resource chips (slightly deeper than panel — they sit *in* the header) |
| `surface.callout` | `#08080C` | C1 success callout (1300,445) | 1 | The red/amber callout's base under its tinted gradient |
| `surface.nav_active.top` | `#142635` | C1 (150,112) | 2 | Active nav pill, gradient top |
| `surface.nav_active.bottom` | `#142738` | C1 (150,152) | 2 | Active nav pill, gradient bottom (near-flat: a 1–3 unit lift) |
| `surface.cta.top` | `#5B1D27` | C1 CTA (1330,628); C3 `#621722` | 1–2 | Primary CTA plate, top |
| `surface.cta.bottom` | `#511924` | C1 CTA (1330,680) | ≤18 (texture) | Primary CTA plate, bottom |

Note on Concept 3: its header (700,40) samples `#A2A1B2±80` and its rail (100,600) `#131C2D±11` — **sky and cliff showing through**. In Concept 3 the camp scene runs full-bleed under a translucent header and rail; in Concept 1 the frame is opaque. `03-concept3-camp-layout.md` owns the call; this file provides `ground.frame` at an alpha for that case: `#0C151D` @ 0.72.

## 2. Edges

Borders are 1px (occasionally 2px) and come in two families. The bronze family is *warm* and belongs to panels; the slate family is *cool* and belongs to slots and the rail.

| Role | Hex | Evidence |
|---|---|---|
| `edge.bronze` | `#856A57` | C1 sidebar left edge y=400: `… #030408 #201B19 **#856A57** #5F4D3E #020307 …` — a 1px bronze line with a 1px darker bronze shadow inboard |
| `edge.bronze_shadow` | `#5F4D3E` | same run, the inboard pixel |
| `edge.bronze_soft` | `#7F6E63` | C1 card top edge x=250: `#2B2828 **#7F6E63** #484241`; C1 header divider y=74: `#7B6453 #7D6556` (2px) |
| `edge.slate` | `#3A373A` | C1 plain slot border y=357: `#222224 **#3A373A** #1C1E23` |
| `edge.slate_light` | `#3F434B` | C1 portrait frame y=800: `#1F252D **#3F434B** #1E252F`; C3 reward slot `#353840 #3D434D` |
| `edge.rail` | `#262E35` | C1 nav rail right edge y=600: `#131920 **#262E35** #1B2127` |
| `edge.steel` | `#4982A2` | C1 active nav pill right edge y=130: `#26455B #427792 **#4982A2**`; pill bottom: `#3A5B73 **#4D7894**`; pill top: `#46687E #3D5F79` — a 2px steel-blue border, brighter on the trailing edges |
| `edge.steel_dim` | `#3D5F79` | pill top run, the second pixel |
| `edge.cta_red` | `#D03E37` | C1 CTA left edge y=650: `#050408 #842424 **#D03E37** #C34035 #5E1C22` — 1px dark red, 2px bright red |
| `edge.cta_red_dark` | `#842424` | same run |
| `edge.cta_gold` | `#FCB85D` | C1 CTA top edge x=1330: `#593526 **#FCB85D** #E69451 #4A262B` — the CTA's TOP edge is gold, its sides red: a lit gold rule on a red plate |
| `edge.cta_gold_dim` | `#E69451` | same run |
| `edge.portrait_bronze` | `#7C6454` | C1 raid-team portrait slot y=545: `#3C342E **#7C6454** #272120` |

Contrast of `edge.bronze` on `surface.panel`: 3.93:1 — a visible but quiet line, as in the reference. `edge.slate` on panel: 1.67:1 — deliberately faint (the reference's plain slots barely register); it is decorative, so no legibility rule applies.

## 3. Text

A four-level hierarchy plus one warm numeric tone. All sampled as the mean of the brightest 10% of pixels in the word's rect.

| Role | Hex | Sampled | Contrast on `surface.panel` | Use |
|---|---|---|---|---|
| `text.title` | `#F6EFDF` | "Current Raid", "Recent Events" `#F1EADA`, nav active "Home" `#F8F3E3`, wordmark bright `#F9F4E5` | 17.2 | Section titles, active nav, card names (`#F2ECDF`), CTA label (`#EDE9D9`) |
| `text.body` | `#F7F1E1` | "The Sludge Maw", boss name `#F1EBE2`, normal damage `#F4F3EC` | 17.4 | Subject titles, primary values |
| `text.label` | `#B8CDDF` | "Potential Rewards" | 12.0 | Cool section sub-labels |
| `text.muted` | `#9A9A9C` | "Aberration", "Raid Team" `#9D9B9C`, chip "8/12" `#99989B`, chip "Day 23" `#A6A5A8` | 7.0 | Secondary text, metadata, quiet numerals |
| `text.muted_warm` | `#B4B1AE` | events rows; nav inactive `#B1AFB2`; "View All" `#B0A39B` | 9.2 | Log rows, inactive nav |
| `text.numeric` | `#C0B7AC` | "Lv. 12" | 9.9 | Warm cream for stacked numerics that are not currency |
| `text.slate` | `#758A9B` | class label "Warrior"; quote `#7E8D98`; callout subtitle `#B5BDC4` | 5.5 | Class line, quotes, tertiary |
| `text.log` | `#C5CAD1` | C2 combat log damage lines | 11.9 | Combat log body |
| `text.on_cta` | `#EDE9D9` | CTA label | 10.5 on `surface.cta.top` | |

Every text role clears WCAG AA (4.5:1) on every surface, including the brightest (`surface.nav_active`, where `text.slate` is the tightest at 4.32 — but `text.slate` never appears on the active pill). `text.slate` is the one to watch: keep it ≥ 15px.

## 4. Accents

| Role | Hex | Sampled | Contrast on panel | Use |
|---|---|---|---|---|
| `accent.gold` | `#ECA742` | chip "12,480"; CTA cost `#E7AC3A`; events badge `#EA983B` | 9.5 | Currency, brass icons, the CTA sub-line |
| `accent.gold_light` | `#FCB85D` | CTA top rule | — | Highlights on gold |
| `accent.gem` | `#B1A0F6` | chip "320" numeral (icon itself `#5B2ABE`/`#9378ED`) | 8.6 | Reputation chip |
| `accent.steel` | `#4982A2` | active nav border | 4.5 on rail | Selection, focus ring, active state |
| `accent.cyan` | `#43DBF3` | C3 "Morale: Okay"; C2 mana bar `#006C9C` → `#01A2D9` | 11.9 | Secondary resource, "okay" morale in the reference |
| `accent.bubble` | `#FAE1B9` | speech bubble fill C1 | — | Speech bubbles (cream, dark text on it) |

## 5. State

| Role | Hex | Sampled | Contrast on panel | Use |
|---|---|---|---|---|
| `state.danger` | `#F73526` | "17%"; C3 "Morale: Low" `#F13D2A`; log alert `#F93F37`; events badge red `#F44339` | 5.1 | Low morale, failure, ≤ threshold success |
| `state.caution` | `#FBB62B` | C3 "42%" | 11.1 | Mid morale, mid success |
| `state.positive` | `#32C24D` | C1 morale bar `#42BF57 #43BE53`; events badge `#ACC855` | 8.4 | High morale, gains |
| `state.crit` | `#F1750E` | C2 "-842" | 6.8 | Critical damage numbers |
| `state.info` | `#7C86CC` | events badge (anxious), log badge `#6974E0` | 6.1 | Neutral/informational log rows |
| `state.arcane` | `#5911B4` | log badge (Arcane Bolt) | — | Spell log rows, gem icon body |

**Success-chance threshold (inferred):** 17% is red, 42% is amber. No green example exists. Rule adopted: `< 30` danger, `30–64` caution, `≥ 65` positive — the same bands as morale, so one function serves both (`Palette.band_color`).

**Bars.** Boss HP and combatant HP fill `#AD1C2F`/`#AE1C2C` (±35, textured) — a *desaturated* blood red, distinct from `state.danger`. Mana `#006C9C`. Tracks are `surface.inset`.

| Role | Hex |
|---|---|
| `bar.hp` | `#AE1C2C` |
| `bar.hp_light` | `#D03E37` (top highlight, shares `edge.cta_red`) |
| `bar.mana` | `#006C9C` |
| `bar.mana_light` | `#01A2D9` |
| `bar.morale_hi` | `#32C24D` |

## 6. Rarity 🔷 PROPOSED

The references show slot borders in slate (plain) and bronze (portrait), a purple gem and gold trims — not a full five-step ramp. The five *names* are ✅ CANON. Ramp chosen to sit on `surface.inset` and read at 1px:

| Rarity | Hex | Contrast on inset |
|---|---|---|
| Common | `#9A9AA5` | 6.4 |
| Uncommon | `#5FB94E` | 6.9 |
| Rare | `#4A8FD4` | 5.1 |
| Epic | `#9B5FCB` | 4.4 |
| Legendary | `#ECA742` (= `accent.gold`) | 8.9 |

Legendary moves from docs/12's orange to the reference's gold, because gold is the metal every bordered thing in these concepts is made of.

## 7. Contrast audit

Computed for every text role × {panel `#060C12`, card `#000E18`, nav-active `#142635`, slot `#0D151C`}. Minimum observed: `text.slate` on nav-active 4.32 (never used there); `state.danger` on nav-active 4.04 (large text only — the 17% figure is 34px). **No reference pairing fails AA for its size class; no nudges needed.** Decorative edges (`edge.slate` 1.67) are exempt.

## 8. Replacement `game/ui/Palette.gd`

Written by the implementation phase; this is its content. Legacy names are kept as deprecated aliases for one commit so the 559 existing call sites keep compiling while screens are rebuilt, then removed. No pure black or white anywhere (`test_no_pure_black_or_white_in_the_palette`).

```gdscript
extends RefCounted
## Semantic colour tokens for the whole interface. art/ref/specs/04-palette.md
## owns every hex here and cites where it was sampled from the references.
## Screens refer to a ROLE, never a hex — repaint the game by editing this file.
## Rule enforced by test: no pure black (#000000) and no pure white (#FFFFFF).

# ---------------------------------------------------------------- surfaces
const GROUND_PAGE := Color("030B13")      ## behind everything; letterbox
const GROUND_FRAME := Color("0C151D")     ## header bar, gutters between regions
const GROUND_RAIL := Color("091116")      ## nav rail
const SURFACE_PANEL := Color("060C12")    ## bordered panels, cards
const SURFACE_INSET := Color("0D151C")    ## slots, wells, bar tracks
const SURFACE_CHIP := Color("020A12")     ## header resource chips
const SURFACE_CALLOUT := Color("08080C")  ## base under the tinted callout
const NAV_ACTIVE_TOP := Color("142635")   ## active nav pill gradient
const NAV_ACTIVE_BOTTOM := Color("142738")
const CTA_TOP := Color("5B1D27")          ## primary commit plate gradient
const CTA_BOTTOM := Color("511924")

# ---------------------------------------------------------------- edges
const EDGE_BRONZE := Color("856A57")      ## panel borders (warm)
const EDGE_BRONZE_SHADOW := Color("5F4D3E")
const EDGE_BRONZE_SOFT := Color("7F6E63") ## header divider, card top
const EDGE_SLATE := Color("3A373A")       ## plain slot border (cool, faint)
const EDGE_SLATE_LIGHT := Color("3F434B") ## portrait frames
const EDGE_RAIL := Color("262E35")        ## nav rail's right edge
const EDGE_STEEL := Color("4982A2")       ## active/selected/focus border
const EDGE_STEEL_DIM := Color("3D5F79")
const EDGE_CTA_RED := Color("D03E37")
const EDGE_CTA_RED_DARK := Color("842424")
const EDGE_CTA_GOLD := Color("FCB85D")    ## the CTA's lit top rule
const EDGE_PORTRAIT_BRONZE := Color("7C6454")

# ---------------------------------------------------------------- text
const TEXT_TITLE := Color("F6EFDF")       ## section titles, names, active nav
const TEXT_BODY := Color("F7F1E1")        ## subject titles, primary values
const TEXT_LABEL := Color("B8CDDF")       ## cool sub-labels
const TEXT_MUTED := Color("9A9A9C")       ## metadata, quiet numerals
const TEXT_MUTED_WARM := Color("B4B1AE")  ## log rows, inactive nav
const TEXT_NUMERIC := Color("C0B7AC")     ## warm cream for stacked numbers
const TEXT_SLATE := Color("758A9B")       ## class line, quotes (keep >= 15px)
const TEXT_LOG := Color("C5CAD1")         ## combat log body
const TEXT_ON_CTA := Color("EDE9D9")

# ---------------------------------------------------------------- accents
const ACCENT_GOLD := Color("ECA742")      ## currency, brass, CTA sub-line
const ACCENT_GOLD_LIGHT := Color("FCB85D")
const ACCENT_GEM := Color("B1A0F6")       ## reputation chip numeral
const ACCENT_STEEL := Color("4982A2")     ## selection
const ACCENT_CYAN := Color("43DBF3")      ## secondary resource
const ACCENT_BUBBLE := Color("FAE1B9")    ## speech bubble fill

# ---------------------------------------------------------------- state
const DANGER := Color("F73526")           ## low morale, failure
const CAUTION := Color("FBB62B")          ## mid morale, warnings
const POSITIVE := Color("32C24D")         ## high morale, gains
const CRIT := Color("F1750E")             ## critical damage numbers
const INFO := Color("7C86CC")             ## neutral log rows
const ARCANE := Color("5911B4")           ## spell log rows

const BAR_HP := Color("AE1C2C")
const BAR_HP_LIGHT := Color("D03E37")
const BAR_MANA := Color("006C9C")
const BAR_MANA_LIGHT := Color("01A2D9")

## Rarity: names are CANON, hexes PROPOSED (04-palette.md §6). Indexed by Enums.Rarity.
const RARITY := [
    Color("9A9AA5"),   # Common
    Color("5FB94E"),   # Uncommon
    Color("4A8FD4"),   # Rare
    Color("9B5FCB"),   # Epic
    Color("ECA742"),   # Legendary — gold, the metal of every border here
]


static func rarity_color(rarity: int) -> Color:
    if rarity < 0 or rarity >= RARITY.size():
        return TEXT_MUTED
    return RARITY[rarity]


## One band function for morale AND success chance: < 30 danger, < 65 caution.
static func band_color(value: int) -> Color:
    if value < 30:
        return DANGER
    if value < 65:
        return CAUTION
    return POSITIVE


static func morale_color(morale: int) -> Color:
    return band_color(morale)
```

Legacy aliases carried for one commit: `PAPER_HIGH/BASE/LOW → SURFACE_PANEL`, `RULE_HAIR → EDGE_SLATE`, `INK_BODY → TEXT_TITLE`, `INK_MID → TEXT_MUTED`, `INK_FAINT → TEXT_SLATE`, `SLATE_BASE → SURFACE_INSET`, `CHALK_BODY → TEXT_BODY`, `BRASS_BASE → EDGE_BRONZE`, `SEAL_ACCENT → CTA_TOP`, `STAMP_INK → DANGER`.

## 9. Old tokens with no successor

`PAPER_*` (there is no paper), `CHALK_BODY` (no chalkboard), `STAMP_INK` (stamps were the paper metaphor's failure vocabulary — failure is now `DANGER` text and the red callout). `SEAL_ACCENT`'s *rule* — the commit colour appears on exactly one control per screen — survives as the CTA: one crimson plate per screen.
