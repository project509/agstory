# 05 — Typography

> **Status:** Measured · **Owner:** Art pass · **Updated:** 2026-09-09
> **Method:** specimen crops of every text style at 2–4×, letterform comparison against 12 OFL candidates (`build/fonts_candidates/`, specimen sheets `build/_font_specimens.png`, `build/_font_ab_ui.png`), ink-height measurement of each style in the concepts, and cap/x/ascender ratios measured from the candidate font files themselves.

**In one line:** one blackletter-derived display face for the wordmark (Grenze Gotisch) and one humanist sans for everything else (Fira Sans), on a 12–34px scale with two floating-number sizes and a 58px wordmark.

Supersedes docs/13 §4.1–4.2 (IM Fell / EB Garamond / Fira Sans — 🔷 PROPOSED). Keeps §4.3 (tabular numerals) and §4.5 (legibility gate).

---

## 1. The faces

### 1.1 Display — **Grenze Gotisch** (OFL 1.1, Google Fonts `Grenze Gotisch`, variable wght 100–900)

Evidence, from the 2× wordmark crop against six candidates:
- The **W** has the reference's three narrow, spiky stems with a raised centre — Grenze Gotisch exactly; Pirata One's W is heavier and rounder; UnifrakturCook is fully broken blackletter (too much); Almendra/Cinzel/MedievalSharp are roman-structured and wrong at a glance.
- The **G** carries a crossbar and a closed lower bowl — Grenze's textura-influenced G matches; Pirata's is a plain spur.
- The **T**'s flag serif and the tall, narrow **l/d** ascenders (ascender 0.787 em vs cap 0.625 em, the largest ratio of any candidate) reproduce the reference's spiky skyline.
- Weight: the reference is bolder than Grenze at 400. Use **wght 600**.

Runner-up: Pirata One (single weight, close silhouette, less refined). Not a fallback — commit to Grenze.

### 1.2 UI — **Fira Sans** (OFL 1.1, Google Fonts `Fira Sans`, static 9 weights)

Evidence, from the 4× A/B of "Tiny / Lv. 11 / Ranger" against six candidates:
- **g** single-storey with an open tail; **a** double-storey — rules out IBM Plex (spurred a) and matches Fira, Barlow, Inter, Roboto.
- **1** with a flag and no foot serif; **R** with a straight leg — Fira and Barlow.
- Width: the reference is slightly narrow. Barlow is narrower and more geometric (rounder o/e); Fira's humanist stroke modulation and the terminal angles on **e**/**y** match the reference's "Tiny" and "Ranger" more closely.
- Digits: Fira's lining figures have the reference's slightly-taller-than-cap digits (digit 0.713 em vs cap 0.693) — visible in "Lv. 11" where the numerals sit a hair above the L.

Runner-up: Barlow Medium (a legitimate alternate if Fira's width ever fights a layout). Rejected: Inter/Roboto (too wide, mechanical), IBM Plex (wrong a), Archivo (grotesque, wide).

Weights used: **Regular 400** (body, labels), **Medium 500** (names, values, nav), **SemiBold 600** (section titles, CTA, big figures).

### 1.3 Availability

Neither face is installed on this machine (only Roboto/Segoe are). Both are fetched to `build/fonts_candidates/` and ship into `game/assets/fonts/` with their `OFL.txt`. Files:
- `GrenzeGotisch[wght].ttf`
- `FiraSans-Regular.ttf`, `FiraSans-Medium.ttf`, `FiraSans-SemiBold.ttf`, `FiraSans-Italic.ttf` (quotes)

## 2. Measured ratios (from the font files, 400px render)

| Face | cap H | digits | x-height | ascender (h,l) |
|---|---|---|---|---|
| Fira Sans Medium | 0.693 | 0.713 | 0.530 | 0.770 |
| Fira Sans Regular | 0.690 | 0.703 | 0.527 | 0.762 |
| Grenze Gotisch | 0.625 | 0.655 | 0.470 | 0.787 |

Godot's `font_size` is the em size in pixels, so **font_size = measured cap height ÷ 0.693** (Fira) or **÷ 0.625** (Grenze). For mixed-case words the ink span from ascender top to baseline is ≈ 0.77 em and to a descender bottom ≈ 0.96 em; both estimators were used and reconciled below.

## 3. The type scale

Ink heights are what the reference actually prints (AA fringe included, ≈ 1px). Sizes are ±1px; the pixel diff finalises each.

| Style token | Where | Ink h / band (px) | font_size | Face · weight | Colour token |
|---|---|---|---|---|---|
| `type.wordmark` | "A Guild Story" header (C1) | 46 ink, 38 cap | **58** | Grenze 600 | metallic — §5 |
| `type.wordmark_compact` | header on the raid screen (C2) | 34 / 29 | **44** | Grenze 600 | metallic |
| `type.tagline` | "Questionable people. Worse decisions." (C3 read "Bad People. Worse Decisions."; designer's copy 2026-09-14) | 19 / 14 | **18** | Fira 400, +1px tracking | `text.muted_warm` `#D1D0D1` |
| `type.figure_xl` | "17%", "42%" | 25 | **34** | Fira 600 | `state.*` by band |
| `type.damage_crit` | "-842" | 36 ink incl. outline / 24 | **34** | Fira 600, outline 2px `#1A0A05` | `state.crit` |
| `type.damage` | "-317" | 29 / 20 | **28** | Fira 600, outline 2px | `text.body` |
| `type.chip` | "12,480", "320", "8/12", "Day 23" | 21 / 17 | **24** | Fira 500, tabular | gold / gem / muted |
| `type.subject` | "The Sludge Maw", "The Rotting Spire" | 23 / 17 | **24** | Fira 500 | `text.body` |
| `type.section` | "Current Raid", "Recent Events" (17/16 — but 14/10 on the events title; use two sizes) | 17 / 16 | **22** | Fira 600 | `text.title` |
| `type.section_sm` | "Recent Events", "Available" | 14 / 10 | **17** | Fira 600 | `text.title` |
| `type.nav` | "Home", "Recruit" … | 17 / 12 | **20** | Fira 500 | title (active) / muted_warm (inactive) |
| `type.objective` | "The Shattered Core" (C2) | 16 / 14 | **20** | Fira 600 | `text.title` |
| `type.label_lg` | "Raid Team" | 15 / 14 | **18** | Fira 400 | `text.muted` |
| `type.name` | roster card / combatant "Bork" | 14 / 13 | **18** | Fira 500 | `text.title` |
| `type.callout_title` | "The Tavern" (C3 building callout) | 14 / 13 | **18** | Fira 600 | `text.title` |
| `type.boss_name` | "Void Colossus" | 15 / 11 | **18** | Fira 600 | `text.body` |
| `type.cta_cost` | "2,400" under the CTA | 17 / 13 | **18** | Fira 500, tabular | `accent.gold` |
| `type.cta` | "Send Them Anyway" | 21 / 11 | **21** | Fira 600 | `text.on_cta` |
| `type.label` | "Potential Rewards", "Estimated Success Chance" | 13–14 / 9–10 | **16** | Fira 400 | `text.label` / `text.body` |
| `type.link` | "Edit Team", "View All" | 13 | **16** | Fira 500 | `text.muted_warm` |
| `type.level` | "Lv. 12" | 12 / 11 | **16** | Fira 400 | `text.numeric` |
| `type.body` | objective line, events rows, callout subtitle, morale row | 14–15 / 9–10 | **15** | Fira 400 | varies |
| `type.class` | "Warrior" beside the class glyph | 11 / 8 | **15** | Fira 400 | `text.slate` |
| `type.quote` | "I got this." | 14 / 9 | **14** | Fira Italic 400 | `text.slate` |
| `type.small` | combat log rows, speech-bubble text, "48/128" | 13–16 / 8–9 | **13** | Fira 400 (500 for numerals, tabular) | `text.log` / dark on bubble |
| `type.stack` | stack-count numerals in ability cells (C2) | ~8 | **11** | Fira 600, outline 1px | `text.title` |

Line pitch for multi-line runs: events/log rows **29px** (C1 badges at y = 795, 823, 852, 881, 909, 938, 966 → 28–29), speech bubble lines **16px**.

### 3.1 The morale row (canon-constrained)

The reference's `Morale: Low` becomes canon's two lines (`00-canon-reconciliation.md` §2.1): line 1 `Bork — 87 ❤` with the **number at `type.name` size or larger** (docs/05 §10.3: the morale number is never smaller than the name) → number at **20**, glyph 20px; line 2 `Warrior — Very Happy` at `type.class` 15, state word coloured by `Palette.band_color`.

## 4. Numerals

Every stacked numeric — HP `48/128`, chips, costs, the morale value column on the roster — uses **tabular lining figures**. Fira Sans carries `tnum`; in Godot 4.7 this is a `FontVariation` with `opentype_features = {"tnum": 1}` (feature tag via `TextServer.name_to_tag("tnum")`), created once in `game/ui/Fonts.gd` as `Fonts.UI_TABULAR` and used by every numeric label. Proportional figures are used only in prose.

## 5. Effects

**Wordmark.** Vertical metallic gradient `#F9F4E5` (top, sampled max-luma) → `#DEC5AA` (lower body, 90th-pct mean) with a 1px dark outline `#1A1410` and a 1px drop shadow at +0/+2 `#000000`@0.6. There is exactly one wordmark, it never changes, and a Label + gradient shader costs a shader and a draw call for no benefit — **pre-render it** at export time (`tools/art/gen_wordmark.py`, PIL with Grenze Gotisch at wght 600) to `game/assets/ui/wordmark_58.png` and `wordmark_44.png`, and place a `TextureRect`. This also makes the wordmark pixel-identical between the game and the diff, which a live Label's hinting would not.

**Damage numbers.** Live `Label` with `LabelSettings`: `font_size` 34/28, `outline_size` 2, `outline_color` `#1A0A05`, `shadow_size` 0. Rise-and-fade: Tween `position.y -= 28` over 0.7s (ease out), `modulate.a → 0` from 0.45s. Crit adds a 1.25× scale pop over 90ms.

**Everything else** is plain `Label`s with theme colours; no glow on text (the references have none).

## 6. Legibility gate

Smallest body text is 13px Fira Regular on `#060C12` in `#C5CAD1` (11.9:1). Smallest coloured text is 15px `text.slate` (5.5:1). All within AA. The 11px stack-count numeral is SemiBold with a 1px outline — exempt as a glyph-like marker, per docs/13 §4.5's icon exemption.

## 7. Godot constants

```gdscript
extends RefCounted
## Type scale — art/ref/specs/05-typography.md owns these numbers.
const WORDMARK := 58
const WORDMARK_COMPACT := 44
const TAGLINE := 18
const FIGURE_XL := 34
const DAMAGE_CRIT := 34
const DAMAGE := 28
const CHIP := 24
const SUBJECT := 24
const SECTION := 22
const SECTION_SM := 17
const NAV := 20
const OBJECTIVE := 20
const MORALE_VALUE := 20
const LABEL_LG := 18
const NAME := 18
const CALLOUT_TITLE := 18
const BOSS_NAME := 18
const CTA_COST := 18
const CTA := 21
const LABEL := 16
const LINK := 16
const LEVEL := 16
const BODY := 15
const CLASS := 15
const QUOTE := 14
const SMALL := 13
const STACK := 11

const LOG_ROW_PITCH := 29
const BUBBLE_LINE_PITCH := 16
```
