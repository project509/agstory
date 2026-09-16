# Proposed docs/15-open-questions.md entries — a11y-legible

Six entries. The first is the ruling the M6-A11Y-06 audit item asks for; the second is a
defect I found in docs/13 §8.3 while building the verification for the first, and it is
independent of how the first is ruled. The last four — a correction to the first, and
Q-NEXT+2..+4 — were added in the repair pass after a review found that two of them had been
resolved silently inside passing tests.

Do NOT edit docs/15 from this file — it is a proposal for a human to paste, per house rule 1.

---

## Q-NEXT — Which band ramp ships: the reference concepts' red/amber/green, or docs/13 §8.3's L*-ordered red→ochre→olive→teal?

**Status:** ❓ OPEN — needs a human ruling. Both authorities are in writing and they disagree.
Extends [Q-79](15-open-questions.md), which proposed the §8.3 ladder and was then overtaken by
the art pass adopting the reference hues.

**Authority A — the reference concepts (art).** `art/ref/specs/04-palette.md` §5 samples
`DANGER #F73526` / `CAUTION #FBB62B` / `POSITIVE #32C24D` from the reference concepts and notes
that "one function serves both" morale and the success chance. The standing user rule
(2026-09-10) is that the reference concepts set the art bar and win on art.

**Authority B — docs/13 §8.3 + §13 (accessibility).** §8.3 rejects this axis by name:

> **Why red→teal and not red→green:** the ramp's primary axis is lightness (L* 16 → 79,
> monotone, ~7 per step), which survives full colour blindness and greyscale printing. The hue
> axis runs red → ochre → olive → teal, which stays separable under deuteranopia and
> protanopia; **a red→green ramp does not.** Verification is a blocking QA item in §13.

§13's CVD row is **Blocking: Yes**.

**What is now measured rather than argued.** `tools/art/cvd.py` (new) applies the
Brettel/Viénot protanope, deuteranope and tritanope projections plus greyscale;
`tests/unit/test_palette_cvd.gd` (new) runs the same pipeline in-engine on every commit.
Reproduce with:

    python tools/art/cvd.py - --ramp "#F73526,#FBB62B,#32C24D"

| Ramp | Observer | Adjacent ΔL* | L*-monotone? |
|---|---|---|---|
| Reference (3-step) | none | 24.0 / 9.2 | **No** — amber (78.5) is lighter than green (69.3) |
| Reference | protanope | 32.9 / **2.2** | No |
| Reference | deuteranope | 20.7 / 13.0 | No |
| Reference | tritanope | 12.7 / 20.1 | No |
| Reference | greyscale | 24.0 / 9.2 | No |
| §8.3 (10-step) | none | 4.5 … 8.4 | Yes |
| §8.3 | protanope | 6.3 … 8.7 | Yes |
| §8.3 | deuteranope | 3.5 … 8.3 | Yes |
| §8.3 | tritanope | 1.7 … 8.9 | Yes |
| §8.3 | greyscale | 4.5 … 8.4 | Yes |

Three findings a ruling should have in front of it:

1. **§8.3 was right, and the specific victim is protanopia, not deuteranopia.** The reference
   amber/green pair — "middling" vs "fine", on both morale and the raid-prep success figure —
   separates by only **2.2 L\*** for a protanope. Under deuteranopia and greyscale it survives
   (13.0 and 9.2). §8.3 named deuteranopia and protanopia together; measured, protanopia is
   where it actually breaks.
2. **The reference ramp is not lightness-ordered even for full colour vision.** Amber is
   lighter than green (L\* 78.5 vs 69.3), so "getting worse" is not "getting heavier". That
   breaks §8.3's primary axis before any simulation is applied, and it is why
   `test_reference_ramp_collapses_under_protanopia` asserts the non-monotonicity too.
3. **§8.3's ramp is not a drop-in, because it is a ramp of PLATES.** §8.3 is explicit that a
   band is "a **pair** — a fill and an ink"; the fills run down to L\* 16 and are meant to sit
   on doc 13's light paper surface. The shipped palette is near-black navy
   (`SURFACE_PANEL #060C12`), and the morale mark today is **tinted text**, not a chip. Band 0's
   fill as text on `SURFACE_PANEL` measures **1.35:1** — unreadable. So adopting §8.3 is not a
   hex swap: it means the morale reading becomes a filled chip with its own ink, which is a
   layout change on seven screens (§8.2 already reserves the row heights for it).

**What was built without the ruling** (per the project's ambiguity rule):
`Palette.band_color` keeps the reference ramp as the documented default; `Palette.band_color_cvd`
/ `band_ink_cvd` implement §8.3's table verbatim; `Palette.band_color_active(who, value)` selects
between them on a new `colourblind_safe` option. **No live call site was switched**, because
switching a text tint to a plate colour would make the roster less readable, not more — see
finding 3. The default cannot be flipped without this ruling.

**Also owed if the option ships:** docs/13 §15.1 needs a row for `colourblind_safe`. That
section's rule is "if an option is not in this table, it does not exist in the settings screen",
and `GameSettings.gd`'s own docstring says adding the key without the row "is the same mistake in
the other direction". `BACKLOG.md:169` ("colourblind-safe morale coding") is the mandate.

**A note on the acceptance threshold.** The M6-A11Y-06 brief asked for "≥ 5 in L\* AND ≥ 3:1
after deuteranope simulation" between adjacent bands. The ΔL\* half is checkable and is what
§13's own words ask for ("distinguishable by lightness alone"). The **3:1 half is arithmetically
unreachable by any ramp**: two consecutive 3:1 steps require 9:1 end to end, and L\* 16 → 79
affords 8.6:1. Reaching 9:1 needs either an L\* ≈ 82 top step or a pure-black bottom, which
docs/12 §4.2 forbids. `test_palette_cvd.gd` therefore asserts 3:1 where it is meaningful — end
to end across the active ramp after deuteranope simulation (measured 4.5:1) — and reports the
adjacent-step ratios as a diagnostic. **Please confirm ΔL\* ≥ 5 is the intended criterion**, or
give the number that replaces it.

---

## Q-NEXT+1 — docs/13 §8.3's fill/ink pairs do not meet §8.3's own 4.5:1 promise at bands 4, 5 and 6

**Status:** ❓ OPEN — a defect in the table, independent of the ruling above.

§8.3 states: "Each band is a **pair** — a fill and an ink guaranteed ≥ 4.5:1 against each other.
The chip is therefore surface-independent." Measured on the section's own hexes:

    python tools/art/cvd.py - --ramp "<the ten fills>" --ink "<the ten inks>"

| Band | Fill | Ink | Contrast |
|---|---|---|---|
| 0-3 | `#521015`…`#94491D` | `#E8E6D6` | 11.58 / 9.23 / 6.86 / 5.18 ✅ |
| **4** | `#99621F` | `#E8E6D6` | **4.06** ❌ |
| **5** | `#8E7C33` | `#2B2A24` | **3.48** ❌ |
| **6** | `#77914E` | `#2B2A24` | **4.07** ❌ |
| 7-9 | `#75A56F`…`#93C7BC` | `#2B2A24` | 5.05 / 6.27 / 7.63 ✅ |

The three failures are exactly the crossover where the ink flips from cream to near-black. The
tabulated L\* column also drifts from the hexes: the table reads 16/23/30/37/44/51/58/65/72/79
while the hexes measure 16.6/23.9/32.2/39.8/46.5/52.3/56.8/63.2/70.0/76.5, so "~7 L\* per step"
is really 4.5–8.4, with the weakest step at 5→6 (Content → Happy).

**Not fixed here on purpose.** §8.3 marks the hexes 🔷 PROPOSED and subordinate to doc 12, and
choosing three replacement hexes would be inventing numbers (house rule 1). Either doc 12 supplies
the corrected pairs, or §8.3 drops the "guaranteed" wording.
`tests/unit/test_palette_cvd.gd::test_docs_13_8_3_fill_ink_pairs_miss_their_own_4_5_promise`
asserts the failing set is exactly `[4, 5, 6]`, so a doc fix turns the test red and forces the
table to be re-imported rather than diverging silently.

---

# ADDED IN THE REPAIR PASS

Three more rulings, and one correction to the entry above. All four came out of a review
that found the first version of this work had resolved two of them silently inside passing
tests. None of them is fixed in code, because fixing any of them means either inventing a
number or overruling one of two written authorities.

---

## Correction to Q-NEXT — §8.3's ramp does not meet §13's own criterion either

The table above reports the §8.3 ramp's adjacent ΔL\* as a RANGE (`4.5 … 8.4` and so on).
Stated as the acceptance test rather than as a range, the same measurement reads:

| Observer | worst adjacent ΔL\* | at bands | clears 5.0? |
|---|---|---|---|
| none | 4.51 | 5-6 Content → Happy | **No** |
| protanope | 6.30 | 0-1 | Yes |
| deuteranope | 3.51 | 5-6 | **No** |
| tritanope | 1.68 | 4-5 Slightly Annoyed → Content | **No** |
| greyscale | 4.51 | 5-6 | **No** |

So the option added as the CVD-safe answer does not itself pass the row it exists to
satisfy — and §8.3's stated "~7 L\* per step" is met by no observer at all. The weakness is
the same crossover that breaks the fill/ink promise in Q-NEXT+1 below: bands 4-6 are
compressed, and the hue turns from ochre to olive there rather than continuing to lighten.

`tests/unit/test_palette_cvd.gd::test_docs_13_8_3_ramp_misses_delta_l_5_between_adjacent_bands`
now asserts each of those five figures and the pair each occurs at, so a repaint of §8.3
turns it red. The earlier version of that test measured bands 1, 4 and 8 only — three steps
apart — and passed while calling itself §13's blocking assertion. That was wrong and is
withdrawn.

**What a ruling needs to decide:** whether §8.3's hexes are corrected (doc 12 owns them),
or §13's criterion is restated as something the ramp can meet (monotonicity under all four
simulations, which it DOES satisfy at all ten steps), or the ten bands stop being
individually distinguishable and the chip carries a state word instead. Note that ten bands
across L\* 16-79 affords 7.0 per step at best, so ΔL\* ≥ 5 adjacent is reachable but only
with an evenly spaced ramp; the current one spends its range unevenly.

---

## Q-NEXT+2 — Is docs/13 §13's "14px at 1920×1080" a floor on the authored number or on the rendered pixel?

**Status:** ❓ OPEN — needs a human ruling. Two authorities author in two different frames.

**Authority A — docs/13 §4.2**, titled "Scale — **authored at 1920×1080**". Its own type
table treats 14 as a number written in a 1920-wide frame (`meta`, "14px is the floor for
readable text"), and §13's blocking row restates it: "Minimum text size: 14px at 1920×1080
for anything the player must read. 12px permitted only for decorative stamps whose content
is duplicated in readable text."

**Authority B — art/ref/specs/05 §3 + specs/11 §1.** Our type scale was measured off the
reference concepts, which are **1536×1024**, and project.godot ships
`window/stretch/aspect="keep"` over that base viewport. specs/11 §1: "at 1080p the window
is 1920 wide but the reference frame scaled to 1080 tall is 1620 wide", and its table gives
the scale factor as **×1.0547** for `keep` *and* for the `expand` opt-in.

**The measurement.** `min(1920/1536, 1080/1024) = 1080/1024 = 1.0546875`, so at the
resolution §13 names:

| Type style | Authored | On screen at 1920×1080 | §13 |
|---|---|---|---|
| `QUOTE` | 14 | 14.77 | passes — the smallest that does |
| **`SMALL`** | 13 | **13.71** | **misses the 14px readable floor** |
| **`STACK`** | 11 | **11.60** | **misses even the 12px decorative allowance** |

`SMALL` is not decorative: it is combat-log rows, bubble text, "48/128", and the Tavern
candidate card's morale rows and backstory bullets. Under reading A it is fine (13 authored
in a 1536 frame is 16.25 in docs/13's 1920 frame); under reading B, which is what §13's
words literally say, a **Blocking: Yes** row does not hold today.

**Not resolved here.** The sizes came from the reference concepts and the standing user rule
(2026-09-10) is that the reference concepts win on art, so raising `SMALL` to 14 is not this
agent's call; and picking reading A to make the row pass is exactly the silent resolution the
project's ambiguity rule forbids — the first version of this work did that, with an invented
1.25 "conversion" (the width ratio, which no shipped stretch mode applies), and it made the
failure invisible. `tests/unit/test_a11y_legibility.gd` now measures at 1.0547 and asserts
the offender list is exactly `["SMALL", "STACK"]`.

**If the ruling is B (the strict reading),** the cheapest fix is `SMALL` 13 → 14 and `STACK`
11 → 12, which are +1px each and would need a refdiff pass on every screen that uses them
(the log, the bubbles, the Tavern card). **If it is A,** docs/13 §13 should say "14px as
authored in §4.2's 1920×1080 frame" and specs/05 §3 should record the frame it measured in,
because otherwise the next reader repeats this.

---

## Q-NEXT+3 — The event-log badge for a morale row: the reference says MOOD, we ship a frown/smile pair

**Status:** ❓ OPEN — a small ruling, but it is a divergence from the reference concepts and
the standing rule says they win on art.

spec 01 §4.2 assigns the seven `badge_*.png` crops to four classes by colour: failure &
mishap **red** (rows 1, 4), mood **blue-violet** (row 2), recruit / level / gold **gold**
(rows 3, 5, 7), loot **yellow-green** (row 6). Every row `Cards.recent_events` emits is a
morale note, and by that table a morale row is **mood** — the blue-violet `badge_1`.

`Cards.BADGE_FOR_KIND` instead ships `morale_down → badge_0` (the red frowning face, spec's
*failure* class) and `morale_up → badge_5` (the green smiling face, spec's *loot* class).

The reason, which is a measurement and not a preference: **the reference has no mark for a
morale gain.** Its single mood crop is a *dizzy* face. Painting "Hilda's morale went up" with
a dizzy face loses the sign that docs/13 §13's blocking first row exists to preserve, and
badge_0's frown / badge_5's smile are the only pair in the sheet that reads as down/up at
18px. (Note also that spec 01 §4.2's *contents* list is independently wrong — it calls
badge_4 an up-arrow and badge_5 an item; upscaled, badge_4 is an amber grimace and badge_5 a
green smiling face. Audit item m4t-09 plans to rename the files by that mistaken list.)

**Options for the ruling:** (a) keep the frown/smile pair and record the departure in spec 01
§4.2; (b) use `badge_1` for a morale drop and no badge for a gain, which is faithful and
loses the gain's second channel; (c) author an eighth crop — a blue-violet *good*-mood badge —
which is the only answer that is both faithful and complete. One edit in
`game/ui/Cards.gd:BADGE_FOR_KIND` either way.

---

## Q-NEXT+4 — The Tavern candidate card cannot be both 215×262 and carry four wrapped bullets

**Status:** ❓ OPEN — arithmetic, not opinion. Implemented the way that breaks neither
blocking row; the alternative is one line away.

**Authority A — art/ref/specs/01 §3** measured the card from the reference concept at
**215×262**, pitch 224, four across, and §4.2 unifies the bottom strip's bottom edge at
y=995 (`Widgets.STRIP_Y` 734 + `STRIP_H` 262 = 996).

**Authority B — docs/04 §3.5**: the card "is the entire decision surface and must be readable
without a submenu", and §6.2 / `BackstoryPool.BULLET_COUNTS` give 2-3 bullets at the middle
rarities and `MAX_BULLETS` = 4 for a Legendary. Backstory bullets run to 61 characters
(`data/backstories.json`), which is two to three wrapped lines each at `Type.SMALL` in the
card's 191px content column.

They do not fit. Measured on a mounted Tavern at 1536×1024 with layout settled over ten
frames, the card's content needs 57-77px of bullet area for two bullets, 117 for three and
157 for four, against the ~101px the box has left after the portrait row, docs/13 §13's two
morale rows and the primary button.

**What was shipped:** the bullet block is a `ScrollContainer` (horizontal scrolling off,
vertical on), which is the mechanism docs/13 §4.4 names — layouts "reflow by reducing row
count (scrolling), never by truncating". Every bullet is still built and still a Label, so
nothing is hidden from a screen test or from the sidebar, which shows the whole backstory at
330px. The card now holds 215×262 at every bullet count and its "Look" button sits at global
y949-984 in all of them.

**What it costs:** a three-bullet card scrolls by 16px and a four-bullet Legendary by 56px,
so part of the backstory is one wheel-notch away rather than face-up. That is a real
weakening of §3.5's "face up", traded for docs/13 §14 (nothing leaves the frame).

**Before this change the trade went the other way and nobody chose it:** the card simply grew
— 318px tall for four bullets, 398 with long ones, bottom edge at y1052 and y1132 against a
1024-tall frame — and 16px of the Legendary card's primary control was **below the bottom of
the screen**. That is not a variant of the trade-off, it is both rows broken at once.

**Options for the ruling:** (a) keep the scroll; (b) let the Legendary card be taller than the
others — docs/13 §9.4 already says "The Legendary card is full-height and framed differently",
which may be permission for exactly this, but it needs `Widgets.STRIP_H` or the strip's
anchoring to change and that is five screens; (c) drop `Type.SMALL` to fit more lines, which
Q-NEXT+2 shows is already under §13's floor; (d) let the middle rarities show two bullets on
the card and the rest in the sidebar, which contradicts §3.5 outright. Only (a) and (b) keep
both blocking rows.
