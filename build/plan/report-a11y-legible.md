# report - a11y-legible

Items: M6-A11Y-04, M6-A11Y-05, M6-A11Y-06, M6-A11Y-07, M6-A11Y-08.

Files owned: game/ui/Palette.gd, game/ui/Type.gd, game/ui/Cards.gd, game/ui/Badge.gd,
game/screens/Tavern.gd, tools/art/cvd.py (new), tests/unit/test_palette_cvd.gd (new),
tests/unit/test_a11y_legibility.gd (new). Nothing outside that list was edited.

Companion files: build/plan/q-a11y-legible.md (two proposed docs/15 entries),
build/plan/handoff-a11y-legible.md (every exact edit in a file I do not own).

**Verification:** PARSE_CHECK OK (125 scripts) - parse-checked after each item, not once at
the end. Suite: **1215 tests, 4 failing**, all four in test_golden.gd and test_adventures.gd
(the sim agent's in-flight balance work; they were failing before my last edit and none of
my files appears in any failure). **25 tests added** - 11 in test_palette_cvd.gd, 14 in
tests/unit/test_a11y_legibility.gd.

---

## Three auditor claims that were wrong, and one bug the audit missed

Checked before acting, as instructed.

1. **"nine morale-glyph sites"** - there are **eight** settable ones. The ninth in the
   audit's count is sim/model/Raider.gd:287 (Raider.summary()), with sim/core/Morale.gd:147
   in the same position. Those are sim-side and may not read an autoload (house rule 6), so
   they must STAY raw. Routing them would have broken the project's purity story to satisfy
   a count. test_the_sim_keeps_its_own_raw_glyph_and_that_is_correct now asserts they stay
   raw, so a future sweep trips instead of "finishing the job".

2. **"the seven badge glyphs already exist as art - wire them"** (M6-A11Y-07). They exist,
   but they are not the glyphs the combat log needs, and
   art/ref/specs/01-concept1-home-layout.md:100 describes contents the files do not have.
   Upscaled and looked at: badge_0 red frowning face, badge_1 blue-violet dizzy face,
   badge_2 gold person, badge_3 red frowning face, badge_4 **amber grimacing face**,
   badge_5 **green smiling face**, badge_6 gold coin. The spec claims badge_4 is an
   up-arrow and badge_5 an item; **no up-arrow and no item was ever cropped.** They are
   also typed to the *guildhall* log's kinds, not the raid log's verbs (mistake / heal /
   attack / mechanic / phase), so they could not be wired into the combat log at all.
   Consequence for someone else's item: **m4t-09 plans to rename these files by that
   mistaken list.** Flagged in the handoff, section 4d.

3. **">= 3:1 between adjacent bands after deuteranope simulation"** (the briefed acceptance
   threshold) is **arithmetically unreachable by any ramp**, not just by these two. Two
   consecutive 3:1 steps require 9:1 end to end; docs/13 8.3's L* 16 -> 79 window affords
   8.56:1. Reaching 9:1 needs an L* of about 82 at the top or a pure-black bottom, and
   docs/12 4.2 forbids pure black. Section 13's own wording is "distinguishable by lightness
   alone", so the test asserts dL* and asserts 3:1 where it is meaningful - end to end
   across the active ramp after deuteranope simulation. Written up for a human in
   q-a11y-legible.md.

4. **A bug the audit did not find, in a file I own.** Cards.recent_events() coloured every
   event-log row from `float(e.get("delta", 0.0)) < 0.0`, but a morale_log entry is
   {day, morale, note} (sim/model/Raider.gd:245-251, 355-362) and **has never carried a
   delta**. So the condition was always false and **every row in the "Recent Events" panel
   on five screens rendered POSITIVE green regardless of what happened.** The hue channel
   the item was about was carrying nothing. Fixed at game/ui/Cards.gd:296-311 by taking the
   sign from docs/05 section 7's trigger table, which `note` keys.

---

## M6-A11Y-04 - the morale glyph now has exactly one chooser

**Built:** game/ui/Cards.gd:26-45 - `static func morale_glyph(who: Node, morale: int) -> String`.
Delegates to GameSettings.morale_glyph through Services.find; falls back to
Enums.MORALE_BAND_EMOJI when the autoload is absent (the shape RaiderDetail.gd:290-291
already used, so widget-level tests that mount nothing keep working). `who` may be null,
because a card is built before it is parented and Services.find falls through to the
SceneTree root.

**Why Cards.gd and not Widgets.gd**, where the audit put it: I do not own Widgets.gd.
Cards.gd is the next-best single funnel - all eleven screens already preload it, so no
screen needs a new const line, and Cards.gd is the module that renders the morale row
anyway. If the reviewer prefers Widgets.gd, **move** it; do not add a second copy.

**Re-routed in files I own:** game/ui/Cards.gd:97 (the card's morale line),
game/screens/Tavern.gd:289 (recruit card), game/screens/Tavern.gd:527 (manage row).

**Handed off:** Facilities, Guildhall, Market, RaidPrep, RaiderDetail - exact old-to-new in
handoff section 3 - plus the tools/lint_no_global_classes.sh rule.

Tests:
- test_only_the_funnel_reads_the_raw_morale_emoji_table - walks every .gd under game/ with
  FileAccess and asserts any file still reading the raw table is in the declared
  handoff-pending list. A **subset** check on purpose: applying a handoff never turns it
  red, only a NEW bypass does. This is the assertion that makes a tenth site impossible; no
  amount of screen mounting could catch "a file forgot".
- test_the_sim_keeps_its_own_raw_glyph_and_that_is_correct - the counter-rule.
- test_the_tavern_board_honours_emoji_free - mounts the real Tavern with emoji_free on and
  asserts none of the ten MORALE_BAND_EMOJI faces is printed and the pip figure is.
- test_emoji_free_keeps_the_integer_and_the_state_word - docs/13 13's explicit promise,
  quoted: "The integer and state word are unaffected."

The last two flip a **global, persisted** option, so after_each restores the previous value
before anything else - a test that changed the developer's own settings.cfg would be its own
bug.

---

## M6-A11Y-05 - text_scale: which half I built, which I handed off

**I built the arithmetic, in game/ui/Type.gd:44-93** - the half the brief asked me to design
into Type.gd, where the constants live:

- Type.SCALES := [100, 125, 150] and Type.SCALE_DEFAULT - docs/13 4.4's three steps.
- Type.step(pct) - snaps anything else to a step that exists, because 4.4 gives three "and
  nothing between them" and section 9's layouts were only ever proven at three.
- Type.at(size, pct) - the multiplier. **Identity at 100% by construction, not by luck**: it
  returns `size` untouched rather than trusting float arithmetic to round-trip. That is the
  guarantee the audit's risk note demanded, because the art pass's pixel-diff baselines
  (Kit 16.9 / Town 26.3 / RaidPrep 20.2 MAE, BUILD_STATE.md:239) were all measured at the
  unscaled sizes.

**I handed off the Theme, the cache and every consumer** - handoff section 2, with exact
old-to-new: get_theme(scale) keyed by a `static var _themes: Dictionary` so 100/125/150 each
cache separately; Type.at() inside _label() and _button() only (two edits, not 27 call
sites); the twelve `theme = Theme_.get_theme()` sites; Settings.gd's _scale_button re-entry;
and the eleven add_theme_font_size_override sites that bypass the Theme entirely.

**game/screens/Tavern.gd:71 is mine and I deliberately did NOT change it.** Calling
Theme_.get_theme(scale) before the Theme.gd handoff lands is a runtime error, and house rule
5 forbids leaving a call to a function that does not exist yet. It is listed with the other
eleven so it is applied in the same change.

Tests:
- test_text_scale_is_exactly_identity_at_100_percent - every font-size constant plus the log
  pitch. This is the test the Theme handoff should be verified against.
- test_text_scale_applies_docs_13_4_4s_three_steps - 20px to 25/30, 15px to 19, and every
  constant strictly grows at 125% and again at 150%.
- test_text_scale_snaps_to_a_documented_step - 0 to 100, 110 to 100, 140 to 150, 400 to 150.
- test_every_readable_type_size_clears_docs_13_13s_floor - see the finding below.

**A section-13 finding while writing that last test.** The minimum is "14px at 1920x1080",
but the frame is authored at 1536x1024 (project.godot:41-42, art/ref/specs/11 section 1), so
an authored size must be converted by 1920/1536 = 1.25 before it can be compared - without
that conversion every size in Type.gd looks 25% too small. Converted, exactly one style is
under the 14px floor: Type.STACK = 11 (13.75px at 1920), which is inside the 12px decorative
allowance but not the 14px one. Named in SUB_MINIMUM_SIZES and asserted as the **only** one,
so a new too-small style fails immediately.

---

## M6-A11Y-06 - the ramp conflict: switch, tooling, and a ruling requested

Applied the ambiguity rule; did not pick a side.

**Built in game/ui/Palette.gd:**
- band_color (:105-116) unchanged as the **default**, with the conflict documented at the
  function and in the file header.
- BAND_FILL_CVD / BAND_INK_CVD (:119-147) - docs/13 8.3's ten pairs verbatim, indexed by
  Enums.morale_band so the doc's Range column and the array cannot drift.
- band_color_cvd(value) / band_ink_cvd(value) (:150-161). **Both**, because 8.3 is explicit
  that a band is "a pair - a fill and an ink", and that is the whole reason the ramp is
  allowed to run down to L* 16.
- OPT_CVD_SAFE + cvd_safe(who) (:164-188) - reads the new option, null-tolerant, and
  **probes GameSettings.DEFAULTS for the key first**. Not paranoia: docs/13 15.1's rule is
  that an option not in its table does not exist, GameSettings enforces that by
  push_error-ing unknown keys, and the 15.1 row is a handoff. Until it lands this returns
  the documented default silently instead of logging an error on every morale chip.
- band_color_active(who, value) (:191-197) - the selector.

**Built tools/art/cvd.py** - Brettel/Vienot protanope, deuteranope and tritanope plus
greyscale, wired the way refdiff.py is (same argv style, --out, --region, --mask, JSON to
stdout, a verdict line, __main__ guard). Additions it needed: --swatch x,y,w,h (a rect per
ramp step, measured from a real screenshot), --ramp "#hex,..." (measure a ramp with no
screenshot at all - pass - as the shot), --ink "#hex,..." (8.3's fill-vs-ink promise), and
--selftest.

**A rewrite worth recording, because the first version was confidently wrong.** I first used
the famous 2.02344 / 0.494207 / 0.801109 matrices as if they were linear-RGB matrices. They
are **LMS-space**. The result looked plausible and was not: pure red came out bright yellow
under deuteranopia (a deuteranope sees dark olive), and every score was inflated - the
reference ramp's worst deuteranope dL* read as 1.35 instead of the true 12.99. The tool now
runs sRGB to linear to Smith-Pokorny LMS, collapses the missing cone, and comes back;
--selftest pins linear red under deuteranopia to (0.29275, 0.29275, -0.02234) -
libDaltonLens's tabulated Vienot-1999 deutan matrix, row-multiplied - to 4e-06. Both traps
are named in the tool's docstring. Verified visually too: run on Reference Concept 1, the
event log's red and green badges converge to the same olive under both the protanope and
deuteranope renders, which is the failure 8.3 predicted.

**Built tests/unit/test_palette_cvd.gd** - 11 tests, the same pipeline in GDScript (a test
cannot shell out to Python; the tool cannot boot the engine), locked to the Python
implementation by the same landmark:

| Test | Asserts |
|---|---|
| test_pipeline_landmark_matches_the_python_tool | deuteranope linear red = (0.29275, 0.29275, -0.02234) +/-1e-3, and its luminance stays in 0.15-0.40 (dark olive, not bright yellow) |
| test_greyscale_preserves_lightness_exactly | greyscale is achromatic and preserves L* - the channel section 13 relies on |
| test_cvd_ramp_is_docs_13_8_3_verbatim | all ten fills and all ten inks equal 8.3's hexes; a repaint turns it red |
| test_cvd_lookup_uses_canon_bands | the lookup goes through Enums.morale_band, not a second copy of the band arithmetic |
| test_active_cvd_ramp_separates_by_lightness_under_every_simulation | **the blocking one**: dL* >= 5 between adjacent steps of the ramp the screens actually index (values 15/45/80), under none/protanope/deuteranope/tritanope/greyscale |
| test_cvd_ramp_is_lstar_monotone_under_every_simulation | all ten steps strictly increase in L* under every simulation - 8.3's central claim, and it holds |
| test_active_cvd_ramp_end_to_end_contrast_after_deuteranope | >= 3:1 end to end after deuteranope simulation (measured 4.5:1), with the arithmetic impossibility of the adjacent-pair form written out |
| test_default_ramp_is_still_the_reference_ramp | the lock on the default: band_color still returns DANGER/CAUTION/POSITIVE, the key is colourblind_safe, its documented default is Off, and band_color_active honours the flag and nothing else |
| test_reference_ramp_collapses_under_protanopia | the conflict as a fact: the reference amber/green pair separates by < 5 L* under protanopia, and amber is lighter than green so the ramp is not lightness-ordered at all |
| test_docs_13_8_3_fill_ink_pairs_miss_their_own_4_5_promise | the failing set is exactly bands [4, 5, 6] |
| test_cvd_fills_are_plates_not_text_tints | the darkest 8.3 fill is under 3:1 on SURFACE_PANEL - the reason no live call site was switched |

**Measurements the ruling needs** (all reproducible from the CLI, all in the q file):

- The reference ramp fails, and **protanopia is the specific failure, not deuteranopia**:
  CAUTION/POSITIVE separate by **2.23 L*** for a protanope (13.0 under deuteranopia, 9.2 in
  greyscale). Section 8.3 named both; only one breaks.
- The reference ramp is **not lightness-ordered even in full colour**: L* 54.5 -> 78.5 ->
  69.3. Amber is lighter than green, so "worse" is not "heavier".
- **8.3's own ramp is not a drop-in.** It is a ramp of *plates*: the fills reach L* 16 and
  presuppose doc 13's light paper surface, while the shipped palette is near-black navy and
  the morale mark today is *tinted text*. Band 0's fill as text on SURFACE_PANEL measures
  **1.35:1**. Adopting 8.3 means the morale reading becomes a filled chip with its own ink -
  a layout change on seven screens (8.2 already reserves the row heights for it), not a hex
  swap.
- **8.3 does not meet its own promise.** "a fill and an ink guaranteed >= 4.5:1 against each
  other" measures 4.06 / 3.48 / 4.07:1 at bands 4, 5 and 6 - the crossover where the ink
  flips from cream to near-black. Its tabulated L* column also drifts from its hexes
  (16/23/30/.../79 stated; 16.6/23.9/32.2/.../76.5 measured), so "~7 L* per step" is really
  4.5-8.4. Not patched: the hexes are PROPOSED and subordinate to doc 12, and choosing three
  replacements would be inventing numbers (house rule 1). Filed as the second q entry.

**What I deliberately did NOT do:** switch any live call site to the CVD ramp. Doing it
blind would tint text with plate colours and make the roster *less* readable - the exact
opposite of the item. The audit says the same ("the default cannot be flipped without [the
ruling]"), and the handoff therefore gives the Settings.gd row a **non-empty reason**, so
the option is presented as pending rather than live - Settings.gd:45-46's own convention.

---

## M6-A11Y-07 - the combat-log badge's second channel (my half)

**Built in game/ui/Badge.gd** (rewritten; 4-space indent kept to match the existing file):
- @export var glyph: String - one character, drawn at the disc's centre.
- glyph_for_verb(verb, by_raider) - ! mistake/state-change, + heal, > raider attack,
  < boss attack, * mechanic, - phase, "" unknown. The **directional pair** is the point:
  "the boss hit someone" vs "someone hit the boss" was INFO vs CAUTION and nothing else,
  which is exactly the distinction a dichromat loses.
- ink_for(fill) - picks between TEXT_ON_BUBBLE and ACCENT_BUBBLE by measured contrast,
  because the six log hues run from light amber to dark violet and one ink cannot serve
  both. That is 8.3's fill/ink logic applied to a disc instead of a chip.
- The glyph is sized to the disc's inner square (a character sized to the full diameter
  overhangs a circle at every corner) and the stale "Until the glyph sheet exists" sentence
  is gone.

**Built in game/ui/Cards.gd** - the *guildhall* event log, which is the log I own:
- BADGE_FOR_KIND + badge_icon(kind) (:267-286) - morale_down to badge_0.png (red frowning
  face), morale_up to badge_5.png (green smiling face), verified by eye, keyed by **meaning**
  with a ResourceLoader.exists guard so m4t-09's rename degrades to a plain disc instead of
  crashing five screens.
- recent_events() (:288-320) - emits kind, and takes the sign from docs/05 section 7's
  trigger table instead of the delta key that never existed. This is finding 4 above.
- event_log() (:249-256) - passes the sprite.

**Handed off** (section 4): Widgets.log_row's new glyph parameter, RaidView.gd:891, and
Guildhall.gd:296-298 (which passes morale_color twice, so that row is hue-only in two places
at once).

Tests: test_every_combat_log_event_class_carries_a_glyph (all six classes non-empty, one
character each, the two attack directions differ, an unknown verb draws the bare reference
disc); test_the_badge_glyph_ink_is_readable_on_every_log_hue (>= 3:1 on all seven log hues,
plus the two named endpoints - dark ink on amber, cream on violet);
test_the_event_log_badge_resolves_for_both_morale_kinds;
test_the_event_log_sign_comes_from_the_trigger_table (the bug fix: a wipe row and a cleared
row no longer render identically); test_the_badge_glyph_draw_path_has_the_font_api_it_needs.

**GAP, stated plainly.** Badge._draw() cannot be entered by a headless test - the runner
never reaches a frame - and the glyph path is *currently unreachable in the running game
too*, because the only caller that could reach it is RaidView via the handoff. So the two
Font calls it depends on are exercised directly in a test, and the geometry (centring,
inner-square sizing) is **unverified by anything but reading**. Whoever applies handoff 4b
should take one tools/shot.gd capture of the raid view and look at it. I did not, because
shot.gd needs a real window and four other agents were sharing the Godot mutex.

---

## M6-A11Y-08 - the Tavern recruit card's fourth channel

**Built:** game/screens/Tavern.gd:279-296. The state word is printed, on its **own row**,
not appended to the figure. Both reasons are from the docs, not from taste:

- docs/13 9.4's S06 wireframe puts it on its own row - "Starts 52 (o)" then "Content".
- at Type.SMALL (13px) the card's content width is 215 - 2x12 = 191px, and "starts at 74
  <glyph> - Loves Their Guild" overruns it. docs/13 section 14 forbids resolving that by
  truncation, and the wireframe's own "Slightly Ann." shows the doc hit the same wall.

Both rows carry Palette.morale_color(m), so they read as one unit.
grep -rn "starts at" tests/ game/ first: no test asserts on that string, so the format
change breaks nothing.

Tests: test_every_recruit_card_names_its_morale_state - mounts the real Tavern with a rolled
board and asserts, for every candidate, that both the morale integer and
Enums.morale_band_name are printed. Generalising it across all seven morale-bearing screens
(which the audit asked for) belongs with the A11Y-04 handoff, since five of those screens
are not mine and are mid-handoff; noted rather than half-done.

---

## What I deliberately did not do

1. **Did not switch any live call site to the CVD ramp.** Reason above; it needs the human
   ruling and, on this palette, a chip instead of a text tint.
2. **Did not edit docs/.** House rule 1. The two proposed docs/15 entries and the docs/13
   15.1 row are in q-a11y-legible.md and handoff-a11y-legible.md.
3. **Did not fix 8.3's three failing fill/ink pairs.** That needs three new hexes and doc 12
   owns them. The failing set is asserted as [4, 5, 6] so a doc fix forces a re-import.
4. **Did not change game/screens/Tavern.gd:71's get_theme() call** even though I own the
   file - it would be a call to a signature that does not exist until handoff 2a lands.
5. **Did not do the section-14 layout pass for 150% text.** The known clipping sites are
   listed with file:line in handoff 2e, including one in my own file: Tavern.gd's recruit
   card is a fixed 215x262 with clip_contents = true, so at 150% a backstory bullet is
   silently cut - which docs/04 3.5 forbids outright ("Backstory bullets are never hidden
   pre-recruit"). Fixing it means the card scrolls or the board reflows, which moves the
   pixel-diff baseline and is a layout decision, not a one-line edit.
6. **Did not widen RaidPrep.gd:379's 74px morale chip** for the 10-character pip figure -
   not my file. It is the concrete risk in handoff section 3 and needs a measurement.
7. **Did not run tools/art/refdiff.py.** Nothing I changed alters a font size, a margin or a
   colour at the default settings, so the MAE numbers should be untouched; but the Tavern
   card gained a row, which WILL move the Tavern shot if one is ever added to the diff set.
   Worth one refdiff run on the Tavern target after the wave.
8. **Did not visually verify the badge glyph.** See the gap under A11Y-07.

## Doc sections relied on

docs/13: 4.4 (three text scales, the multiplier), 4.5 (legibility gate, greyscale), 8.2
(S06 card's state-word column, row heights), 8.3 (the band ramp, the fill/ink pair, the
red-to-green rejection), 9.4 (the S06 wireframe), 13 (the whole accessibility table:
colour-is-never-the-only-signal, CVD verification, contrast, minimum text size, text
scaling, emoji-free mode), 14 (+30% elasticity, reflow-not-truncate), 15.1 (the closed
settings inventory).
docs/05: 7 and 7.1 (the trigger table and its deltas), 10.1 and 10.3 (the morale contract).
docs/04 3.5 (every backstory bullet face up). docs/12 4.2 (no pure black or white).
docs/15 Q-79 (the earlier CVD proposal).
art/ref/specs/01-concept1-home-layout.md 4.2 (the event badge, and the list of its contents
that turned out to be wrong), 04-palette.md 5 and 7 (the reference hues; the WCAG-only
audit), 05-typography.md 3, 11-godot-architecture.md 1 (the 1536x1024 frame).
BACKLOG.md:169 (the colourblind-safe mandate). BUILD_STATE.md:239 (the MAE baselines).

---

# REPAIR PASS — answering the review

The reviewer found four must-fix defects. **All four are real**; I reproduced every
measurement before touching anything. Two of the three "canon violations" are real and are
fixed; one (`Type.at` vs `GameSettings.scaled`) is **wrong on its example** and is answered
with evidence below. Every item was verified through the mutex before the next was started.

## R1 — The 1.25 conversion factor. REVIEWER CORRECT. Fixed.

`AUTHORED_TO_1920 := 1920.0/1536.0` was the width ratio, not the on-screen factor.
`window/stretch/aspect="keep"` (project.godot:46) scales by the **smaller** ratio:
`min(1920/1536, 1080/1024) = 1080/1024 = 1.0546875`. specs/11 §1's own table gives x1.0547
for `keep` **and** for the `expand` opt-in, so no shipped display setting produces 1.25 —
only `aspect="ignore"` would, and this project has none.

Under the real factor:

| Style | Authored | At 1920x1080 | docs/13 §13 |
|---|---|---|---|
| QUOTE | 14 | 14.77 | passes (the smallest that does) |
| **SMALL** | 13 | **13.71** | **fails the 14px readable floor** |
| **STACK** | 11 | **11.60** | **fails even the 12px decorative allowance** |

`tests/unit/test_a11y_legibility.gd:31-87` now names both factors as constants with the
derivation, and:

- `test_the_letterbox_factor_is_not_the_width_ratio` asserts `LETTERBOX == min(...)`, that
  `1536 * LETTERBOX == 1620` (specs/11 §1's own sentence), and that the two candidate
  factors *disagree about SMALL* — i.e. that the invented number was the thing that made
  the row read as passing.
- `test_docs_13_13s_text_floor_is_missed_by_exactly_two_styles` replaces the old
  certification. It asserts the offender list is exactly `["SMALL", "STACK"]`, pins both
  rendered sizes to 0.01px, asserts STACK misses the 12px allowance too, and still
  certifies the other 24 styles. **It records a failure of a blocking row rather than
  claiming the row passes.**

Not fixed by changing a font size: those came from the reference concepts
(art/ref/specs/05 §3) and the standing user rule is that the reference wins on art. The
underlying conflict — docs/13 §4.2 authors at 1920x1080, specs/11 §1 letterboxes 1536 to
1620 — is a second genuine two-authority conflict and is now **Q-NEXT+2** in
`build/plan/q-a11y-legible.md`.

## R2 — The CVD ramp assertion measured three bands out of ten. REVIEWER CORRECT. Fixed.

Reproduced with the project's own tool:

    python tools/art/cvd.py - --ramp "521015,6D1A19,85301C,94491D,99621F,8E7C33,77914E,75A56F,7FB79A,93C7BC"

| Observer | worst adjacent dL* | at bands |
|---|---|---|
| none | 4.51 | 5-6 (Content -> Happy) |
| protanope | 6.30 | 0-1 |
| deuteranope | 3.51 | 5-6 |
| tritanope | 1.68 | 4-5 |
| greyscale | 4.51 | 5-6 |

So §8.3's own table misses the dL* >= 5 the old test claimed to enforce, under four of the
five observers — and misses the "~7 per step" §8.3 advertises under all five. The old
`SAMPLES := [15, 45, 80]` measured bands 1, 4 and 8, three steps apart, which is why it
passed. The docstring's excuse ("asserting the ten-step table alone would test a constant
the screens never index") was false in its own file: `band_color_cvd`/`band_ink_cvd` index
exactly that constant through `Enums.morale_band`.

`tests/unit/test_palette_cvd.gd`:
- `test_docs_13_8_3_ramp_misses_delta_l_5_between_adjacent_bands` (new, replaces
  `test_active_cvd_ramp_separates_by_lightness_under_every_simulation`) walks all nine
  adjacent pairs under all five observers, pins each worst dL* to 0.02 **and the pair index
  it occurs at**, and asserts the set of observers that clear 5.0 is exactly
  `["protanope"]`.
- `test_three_bands_apart_clears_five_which_is_not_the_criterion` keeps the old coarse
  measurement, labelled as the diagnostic it always was.

Not fixed by repainting: §8.3's hexes are PROPOSED and subordinate to doc 12, so picking
three replacements is inventing numbers. Recorded in the q file, folded into the existing
§8.3 entry — same table, same cause: the crossover around bands 4-6 is compressed.

## R3 — `rally_flask` lost both channels. REVIEWER CORRECT. Fixed.

Verified: `GameState.gd:2040` writes `record_morale_day(day, morale, "rally_flask")` and
`Morale.TRIGGERS` has no such key (22 keys, sim/core/Morale.gd:170-284). The row fell to
`delta 0.0` -> `kind ""` + `TEXT_MUTED`: a grey disc with no badge for a morale **gain**,
on five screens.

`game/ui/Cards.gd` now resolves a row's sign in three documented steps
(`Cards._note_sign`):

1. `Morale.TRIGGERS[note].delta` — docs/05 §7, unchanged, still first.
2. `Cards.NOTE_SIGN` — notes that reach the log from outside §7. One entry today:
   `rally_flask: +1`, sourced to docs/11 §7 ("halves the wipe morale penalty") and to
   `use_rally_flask` only writing the row when the refund is positive. **A sign, not a
   delta** — the magnitude belongs to the doc that owns the mechanic.
3. The log's own history: this row's `morale` minus the previous row's. `recent_events`
   now walks `morale_log` by index for this. Real recorded data, no invented number, and it
   means the *next* orphan note is signed correctly the day it appears rather than the day
   somebody notices.

A raider's first recorded day has no previous row, and only that case stays neutral —
guessing a sign there would paint a wrong badge, which is worse than none.

Why step 2 is needed and not just step 3: `Raider.record_morale_day` **overwrites** a repeat
of the same day, so a flask drunk on the day of the wipe replaces the wipe's note in the
same row. The day-on-day difference is then the wipe's net loss and the flask row would be
signed *down*. The explicit map wins over the history for exactly that reason.

Tests: `test_a_note_outside_the_trigger_table_still_carries_a_sign` (asserts the premise
that TRIGGERS still lacks the key, then that the flask row is `morale_up`/POSITIVE and
resolves a badge sprite, that an unheard-of note takes its sign from the recorded history,
and that a known note still comes from the table) and
`test_an_unknown_note_on_the_first_recorded_day_stays_neutral`.

## R5 — `Type.step` vs `GameSettings._coerce`. THE EXAMPLE IS WRONG; the underlying point is right, and is fixed anyway.

The claim: "`Type.at(15, 110) = 15` while `scaled(15)` at a stored 110 = 17."

**`scaled(15)` at a stored 110 is 15, not 17.** `GameSettings._coerce`
(GameSettings.gd:103-109) runs on both `set_value` (line 79) and `load_from_disk` (line
138), and its text_scale rule is `return n if n in TEXT_SCALES else int(DEFAULTS[key])`. A
hand-edited 110 becomes 100 at the door, so `get_value("text_scale")` can only ever be
100/125/150 and `scaled()` cannot see 110. The two functions agreed on the stated example.

They did disagree about the **recovery policy** for a value that is not a step: `_coerce`
falls back to the default, the old `Type.step` snapped to the nearest, so `Type.step(140)`
was 150 while a stored 140 coerces to 100. That is one undefined input with two answers,
which is the reviewer's real point. `game/ui/Type.gd` now uses GameSettings' policy —
`return pct if SCALES.has(pct) else SCALE_DEFAULT` — and the comment states which file owns
the policy instead of claiming the two "do the same arithmetic".

`test_text_scale_recovery_matches_the_settings_autoload` (replaces
`test_text_scale_snaps_to_a_documented_step`) asserts
`Type.SCALES == GameSettings.TEXT_SCALES` and then, for seven off-table values, that
`Type.step(x)` equals what the live autoload coerces `x` to. The developer's stored scale is
captured and restored.

## R6 — The `Cards.gd` tautology. REVIEWER CORRECT. Fixed.

`assert_false(offenders.has("game/ui/Cards.gd"))` could never fail: Cards.gd is in
`GLYPH_FUNNEL` and is `continue`d before the scan. Replaced with the guard the funnel
actually needs — that both exempt files still do the job their exemption is granted for
(`Cards.gd` defines `morale_glyph` and asks GameSettings first; `GameSettings.gd` still
implements `emoji_free`) — plus a positive check that Tavern *reaches* the funnel rather
than only that it does not bypass it.

## R7 — `Enums.Verb.SYSTEM` had no glyph. REVIEWER CORRECT. Fixed.

docs/07 §10.1 lists seven verbs (`attack, heal, mechanic, mistake, state_change, phase,
system`) and `Enums.Verb` (sim/model/Enums.gd:173) has seven members. `Badge.gd` said "six
event classes" and returned `""` for SYSTEM — and SYSTEM is not a quiet class:
`RaidView._row_style`'s `_` branch paints it DANGER on a wipe line and TEXT_MUTED otherwise,
so the loudest row in the log was the one still separated by hue alone.

`Badge.GLYPH_SYSTEM := "="` added and the docstrings corrected to seven.
`test_every_combat_log_event_class_carries_a_glyph` now enumerates `Enums.Verb.values()`
instead of a hand-written list — the hand-written list is what hid the seventh — and a new
`test_no_two_log_classes_share_a_glyph_except_the_documented_pair` asserts the only pair
allowed to share a mark is `mistake+state_change` (which `_row_style` already paints
identically).

## R8 — `Badge._draw`'s glyph geometry was untestable. REVIEWER CORRECT. Fixed.

The runner does all its work in `_initialize`, so no test can reach a frame and `_draw`'s
arithmetic was unreachable. Extracted verbatim into `Badge.glyph_layout(box, font, glyph)`
-> `{px, pos}`; `_draw` now calls it. `test_the_badge_glyph_sits_inside_its_disc` asserts,
at three disc sizes: the glyph fits the disc's **inner square** (`px <= r*sqrt(2)`), the 8px
floor holds, the advance is centred to 0.001px, and the baseline straddles the centre (below
it by half an ascent, the glyph's top above it). The wiring gap — no game code calls
`Badge.glyph` or `Type.at` — is unchanged and is not mine to close: `RaidView.gd` and
`Theme.gd` are other keys' files and the exact edits are already in
`handoff-a11y-legible.md`.

## R4 — The Tavern card runs off the bottom of the frame. REVIEWER CORRECT, AND MY EARLIER REPORT WAS WRONG TWICE. Fixed.

I withdraw report claim 7 ("Nothing I changed alters a font size, margin or colour at
default settings") and deliberately-not-done item 5 (filed as a 150%-only clipping problem).
Both were wrong: the card's height moved 20px at 100%, the mechanism was growth past the
frame rather than clipping, and it took a primary control off-screen.

Measured on a mounted Tavern at 1536x1024 with layout settled over ten frames (a transient
`tools/art/_probe_tavern.gd`, since deleted; it borrows the live autoloads, pads each
candidate's `backstory` to n bullets, rebuilds, and prints each card's rect and its "Look"
button's global rect):

| bullets | card, before | bottom | Look button, before | card, after | bottom | Look, after |
|---|---|---|---|---|---|---|
| 2 | 215x262 | y996 | y905..940 | 215x262 | **y996** | y949..984 |
| 3 | 215x262 | y996 | y925..960 | 215x262 | **y996** | y949..984 |
| 4 | 215x**318** | **y1052** | **y1005..1040** | 215x262 | **y996** | y949..984 |
| 2, longest bullet | 215x278 | y1012 | y925..960 | 215x262 | **y996** | y949..984 |
| 3, longest bullet | 215x**338** | **y1072** | y965..1000 | 215x262 | **y996** | y949..984 |
| 4, longest bullet | 215x**398** | **y1132** | **y1005..1040** | 215x262 | **y996** | y949..984 |

(The strip's top is `Widgets.STRIP_Y` = 734 and the frame is 1024 tall. "Longest bullet" is
the 61-character maximum in `data/backstories.json`.) So a 4-bullet Legendary had 16px of
its 35px primary control below the bottom of the screen, exactly as reported.

**Mechanism, stated correctly this time.** `custom_minimum_size` is a MINIMUM.
`Cards.roster_strip` assigns every card `Widgets.CARD_SIZE`, but `Control.size` clamps UP to
`get_combined_minimum_size()`, so the card grew rather than clipping. `clip_contents = true`
never fired, because there was nothing to clip.

**The fix.** The bullet block is now a `ScrollContainer` (horizontal scrolling DISABLED,
vertical on) that takes the card's vertical slack. With vertical scrolling enabled the
container contributes **zero minimum height**, so the bullets cannot drive the card's size;
the card holds 215x262 at every bullet count and the button is pinned to its bottom edge.
The per-line `custom_minimum_size = Vector2(187, 0)` is gone: inside a horizontally-disabled
ScrollContainer the child is forced to the container's width, so the bullets wrap to 191px
without any risk of pushing the card past its 224px pitch.

**What it costs, said plainly:** the scroll viewport is 191x101 and the bullets need 57-77px
for two, 117 for three and 157 for four, so a 3-bullet card scrolls by 16px and a 4-bullet
Legendary by 56. That is a real weakening of docs/04 §3.5's "face up", and it is the trade
docs/13 §4.4 sanctions ("reflow by reducing row count (scrolling), never by truncating")
against docs/13 §14 (nothing leaves the frame). Every bullet is still built, still a Label,
still read by the screen tests, and the sidebar still shows the whole backstory at 330px.
The underlying conflict — spec 01 §3's fixed 215x262 vs docs/04 §3.5's four face-up wrapped
bullets — cannot be satisfied by any layout and is filed as **Q-NEXT+4**, with docs/13
§9.4's "The Legendary card is full-height and framed differently" named as the alternative
a human may prefer.

**Test.** `test_the_candidate_card_fits_its_strip_at_every_bullet_count` builds the real
`_candidate_card` at 2, 3 and 4 bullets and asserts: every bullet is present as a Label; the
block is a ScrollContainer with horizontal scrolling off and vertical on; the card's
**combined minimum height is identical at 2 and at 4 bullets** (the property the old code
failed — bullets drove the height); that height fits `Widgets.CARD_SIZE.y`; and
`STRIP_Y + CARD_SIZE.y = 996 <= 1024`. The minimum size is the right quantity because the
suite cannot settle a frame — and asserting `min <= 262` alone would have passed *before*
the fix too, since an unwrapped Label reports one line. The equality assertion is what
actually catches it.

## R9 — emoji_free was only checked in source on the four bypassing screens. REVIEWER CORRECT. Fixed as far as it can be.

`test_no_town_screen_prints_a_raw_morale_face_under_emoji_free` mounts Town, Roster,
Guildhall, Facilities, Market and RaidPrep with the option on and reads what they print. It
catches a route the source scan structurally cannot: `Raider.summary()` is sim-side and
stays raw by design, so a screen that shows a summary shows a face while naming no emoji
table at all.

It is tolerant in one direction only — a screen that gets FIXED simply passes, so another
agent applying a §3 handoff mid-wave cannot turn the tree red, while a sixth screen or a new
route does fail. A test that fails *today* (which is what a strict end-to-end assertion
would be, since all five sites still bypass) would block every other agent's suite run, and
that is not a trade I will make on my own authority; the exact edits have been in
`handoff-a11y-legible.md` since the first pass and are re-flagged in its new §5c.

## What I did NOT change, and why

- **The font sizes.** `SMALL` 13 and `STACK` 11 miss docs/13 §13's floor at the real
  letterbox. They were measured off the reference concepts and the reference wins on art by
  standing user rule, so raising them is a ruling (Q-NEXT+2), not a repair.
- **§8.3's hexes.** Marked 🔷 PROPOSED and subordinate to doc 12; three replacement colours
  would be three invented numbers.
- **`Cards.BADGE_FOR_KIND`.** The divergence from spec 01 §4.2's class assignment is now
  named in the code comment and filed as Q-NEXT+3, but changing the map to the reference's
  mood badge would paint a morale GAIN with a dizzy face, which loses the very channel the
  blocking row is about.
- **The `Badge.glyph` / `Type.at` wiring.** Still zero callers in game code, because
  `RaidView.gd`, `Widgets.gd` and `Theme.gd` belong to other keys. M6-A11Y-05 and the
  combat-log half of M6-A11Y-07 remain OPEN; the exact old→new edits are in
  `handoff-a11y-legible.md` §2 and §4.

## Verification

Through the mutex, after every item:

    tools/with_godot_lock.sh "$GODOT" --headless --path . --script res://tools/parse_check.gd   # OK
    tools/with_godot_lock.sh "$GODOT" --headless --path . --script res://tests/run_tests.gd

**1281 tests, 1 failing** — `test_adventures.gd::test_the_mini_boss_is_still_winnable`, which
is the RaidSim mechanics work in flight and touches none of my files. My two files hold **33
tests** (was 25 — +7 in `test_a11y_legibility.gd`, +1 in `test_palette_cvd.gd`, with three of
the originals rewritten and renamed and one split in two) and all 33
pass with no stderr from any file I own. Note for the next pass: `tools/parse_check.gd` does
**not** scan `tests/`, so a test file must be checked with
`--check-only --script res://tests/unit/<file>.gd` — a parse error there costs a full suite
run to discover.

## Visual capture (the gap the review noted)

    "$GODOT" --path . --script res://tools/shot.gd -- res://game/screens/Tavern.tscn         user://tavern_after.png 40 --fixture

Looked at, not just run. The four candidate cards end level with the strip at y996, the
"Look" buttons form one row at the card bottoms (they used to sit at three different heights
depending on how far the bullets pushed them), and with the fixture's two-bullet Commons no
scrollbar appears — which matches the probe's "content 57-77 vs 101 available". The
four-bullet Legendary case is measured rather than shot: the reference fixture rolls Commons
and its roster is another key's file.

One thing the shot makes obvious and worth restating: those backstory bullets are
`Type.SMALL`, which is the 13px style Q-NEXT+2 says renders at 13.71px against §13's 14px
floor. The card is the screen most affected by that ruling.
