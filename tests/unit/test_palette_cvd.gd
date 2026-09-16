extends "res://tests/TestCase.gd"
## The band ramp under colour-vision deficiency — docs/13 §13's CVD row, which
## that table marks **Blocking: Yes** and which nothing in this repo had ever run.
##
## §13, verbatim: "Simulate every screen under protanopia, deuteranopia,
## tritanopia and full greyscale. Adjacent morale bands must remain
## distinguishable by lightness alone (§8.3 gives ~7 L* per step)."
##
## The simulation here is the same Brettel/Viénot pipeline as `tools/art/cvd.py`,
## reimplemented in GDScript because a test cannot shell out to Python and the
## tool cannot boot the engine. `test_pipeline_landmark` locks the two together on
## a published value, so the pair cannot silently drift apart.
##
## WHY A UNIT TEST AND NOT ONLY THE SCREENSHOT TOOL: a screenshot pass tells you a
## screen looked wrong on the day someone ran it. The ramp is a constant, so its
## separability is a property that can be asserted forever, on every commit, for
## free. The tool stays for the half a constant cannot answer — whether a real
## screen composited that ramp onto a ground that ruins it.

const Palette = preload("res://game/ui/Palette.gd")
const Enums = preload("res://sim/model/Enums.gd")
const GameSettings = preload("res://game/core/GameSettings.gd")

## Smith-Pokorny cone fundamentals for sRGB primaries, published with the
## Viénot/Brettel/Mollon method. LINEAR rgb in, LMS out — the two traps
## tools/art/cvd.py's docstring names (LMS-space matrices misapplied to RGB, and
## running on gamma-encoded bytes) both produce plausible wrong answers, so this
## copy keeps the same shape and the same landmark check.
const RGB_TO_LMS := [
    Vector3(17.8824, 43.5161, 4.11935),
    Vector3(3.45565, 27.1554, 3.86714),
    Vector3(0.0299566, 0.184309, 1.46709),
]
const LMS_TO_RGB := [
    Vector3(0.0809444479, -0.130504409, 0.116721066),
    Vector3(-0.0102485335, 0.0540193266, -0.113614708),
    Vector3(-0.000365296938, -0.00412161469, 0.693511405),
]

## Rec.709 — the same weights WCAG relative luminance uses.
const LUMA := Vector3(0.2126, 0.7152, 0.0722)

## docs/13 §13's own figure is "~7 L* per step"; 5 is the tolerance this project
## checks against, which is looser than the doc and therefore safe to assert.
const MIN_DELTA_L := 5.0

## One morale value from each of `Palette.band_color`'s three REFERENCE bands —
## it splits at 30 and 65 (04-palette.md §5). These sample the ramp the shipped
## default paints, and they are the right samples for the reference-ramp tests
## below. They are NOT the subject of §13's CVD row: that row says "adjacent
## morale bands", and `band_color_cvd` indexes all ten §8.3 rows through
## `Enums.morale_band`, so the criterion is measured over the whole table.
const SAMPLES := [15, 45, 80]

## Measured minimum ΔL* between ADJACENT §8.3 bands, per observer, with the pair
## it occurs at. Reproduce exactly:
##
##   python tools/art/cvd.py - --ramp "521015,6D1A19,85301C,94491D,99621F,\
##       8E7C33,77914E,75A56F,7FB79A,93C7BC"
##
## Four of the five miss MIN_DELTA_L. This is the doc's table, not a choice made
## here — see the test below and build/plan/q-a11y-legible.md.
const ADJACENT_MIN_DL := {
    "none": [4.51, 5, 6],
    "protanope": [6.30, 0, 1],
    "deuteranope": [3.51, 5, 6],
    "tritanope": [1.68, 4, 5],
    "greyscale": [4.51, 5, 6],
}

## The only observer whose worst adjacent step clears MIN_DELTA_L.
const SIMS_CLEARING_5 := ["protanope"]

const SIMS := ["none", "protanope", "deuteranope", "tritanope", "greyscale"]


# ---------------------------------------------------------------- the pipeline

func _to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)


func _to_srgb(c: float) -> float:
    var v: float = clampf(c, 0.0, 1.0)
    return v * 12.92 if v <= 0.0031308 else 1.055 * pow(v, 1.0 / 2.4) - 0.055


func _linear(col: Color) -> Vector3:
    return Vector3(_to_linear(col.r), _to_linear(col.g), _to_linear(col.b))


func _mul(rows: Array, v: Vector3) -> Vector3:
    return Vector3(
        (rows[0] as Vector3).dot(v),
        (rows[1] as Vector3).dot(v),
        (rows[2] as Vector3).dot(v))


## `kind` is one of SIMS. Returns the colour as that observer sees it.
func _simulate(col: Color, kind: String) -> Color:
    var lin := _linear(col)
    var out := lin
    match kind:
        "none":
            out = lin
        "greyscale":
            var y: float = LUMA.dot(lin)
            out = Vector3(y, y, y)
        _:
            var lms := _mul(RGB_TO_LMS, lin)
            # Each dichromacy loses one cone and reconstructs it from the other
            # two: Viénot, Brettel & Mollon (1999).
            match kind:
                "protanope":
                    lms.x = 2.02344 * lms.y - 2.52581 * lms.z
                "deuteranope":
                    lms.y = 0.494207 * lms.x + 1.24827 * lms.z
                "tritanope":
                    lms.z = -0.395913 * lms.x + 0.801109 * lms.y
            out = _mul(LMS_TO_RGB, lms)
    return Color(_to_srgb(out.x), _to_srgb(out.y), _to_srgb(out.z))


func _luminance(col: Color) -> float:
    return LUMA.dot(_linear(col))


func _lstar(col: Color) -> float:
    var y := _luminance(col)
    return 116.0 * pow(y, 1.0 / 3.0) - 16.0 if y > 0.008856 else 903.3 * y


func _contrast(a: Color, b: Color) -> float:
    var ya := _luminance(a)
    var yb := _luminance(b)
    return (maxf(ya, yb) + 0.05) / (minf(ya, yb) + 0.05)


func _lstars(cols: Array, kind: String) -> Array:
    var out: Array = []
    for c in cols:
        out.append(_lstar(_simulate(c, kind)))
    return out


# ---------------------------------------------------------------- the pipeline is right

## The landmark tools/art/cvd.py's `--selftest` prints. Full linear red under
## deuteranopia lands on (0.29275, 0.29275, -0.02234) — libDaltonLens's tabulated
## Viénot-1999 deuteranope matrix, row-multiplied. Getting bright yellow instead
## means the LMS matrices were applied to RGB, which is the mistake this project
## already made once and which inflates every score downstream.
func test_pipeline_landmark_matches_the_python_tool() -> void:
    var lms := _mul(RGB_TO_LMS, Vector3(1.0, 0.0, 0.0))
    lms.y = 0.494207 * lms.x + 1.24827 * lms.z
    var got := _mul(LMS_TO_RGB, lms)
    assert_almost(got.x, 0.29275, 0.001, "deuteranope linear red, R")
    assert_almost(got.y, 0.29275, 0.001, "deuteranope linear red, G")
    assert_almost(got.z, -0.02234, 0.001, "deuteranope linear red, B")
    # Dark olive, not bright yellow: the luminance must stay near red's own.
    assert_in_range(_luminance(_simulate(Color(1, 0, 0), "deuteranope")),
        0.15, 0.40, "deuteranope red is a dark olive, not a bright yellow")


## Greyscale must be pure luminance: equal channels, and the L* unchanged.
func test_greyscale_preserves_lightness_exactly() -> void:
    for v in SAMPLES:
        var c := Palette.band_color_cvd(v)
        var g := _simulate(c, "greyscale")
        assert_almost(g.r, g.g, 0.002, "greyscale is achromatic")
        assert_almost(g.g, g.b, 0.002, "greyscale is achromatic")
        assert_almost(_lstar(g), _lstar(c), 0.05,
            "greyscale keeps L* — it is the lightness channel §13 relies on")


# ---------------------------------------------------------------- the table

## §8.3's table, verbatim. If a repaint moves a hex this goes red, which is the
## point: the ramp is under an open ruling and must not drift quietly.
func test_cvd_ramp_is_docs_13_8_3_verbatim() -> void:
    assert_eq(Palette.BAND_FILL_CVD.size(), Enums.MORALE_BAND_COUNT,
        "one fill per canon morale band")
    assert_eq(Palette.BAND_INK_CVD.size(), Enums.MORALE_BAND_COUNT,
        "§8.3: a band is a PAIR — every fill has an ink")
    var fills := ["521015", "6D1A19", "85301C", "94491D", "99621F",
        "8E7C33", "77914E", "75A56F", "7FB79A", "93C7BC"]
    for i in fills.size():
        assert_eq(Palette.BAND_FILL_CVD[i], Color(fills[i]),
            "§8.3 band %d fill" % i)
    for i in Enums.MORALE_BAND_COUNT:
        var expected := Color("E8E6D6") if i < 5 else Color("2B2A24")
        assert_eq(Palette.BAND_INK_CVD[i], expected, "§8.3 band %d ink" % i)


## The lookup goes through canon's band arithmetic, not a second copy of it.
func test_cvd_lookup_uses_canon_bands() -> void:
    for m in [0, 9, 10, 29, 30, 64, 65, 87, 99, 100]:
        assert_eq(Palette.band_color_cvd(m),
            Palette.BAND_FILL_CVD[Enums.morale_band(m)],
            "band_color_cvd(%d) indexes Enums.morale_band" % m)
        assert_eq(Palette.band_ink_cvd(m),
            Palette.BAND_INK_CVD[Enums.morale_band(m)],
            "band_ink_cvd(%d) indexes Enums.morale_band" % m)


# ---------------------------------------------------------------- the blocking assertion

## §13's CVD ROW, MEASURED WHERE THE ROW POINTS — AND IT DOES NOT PASS.
##
## "Adjacent morale bands must remain distinguishable by lightness alone (§8.3
## gives ~7 L* per step)". Adjacent morale bands are the ten §8.3 rows, which is
## precisely what `Palette.band_color_cvd` indexes through `Enums.morale_band`.
## Measured over all nine adjacent pairs, the worst step is:
##
##   none 4.51 · protanope 6.30 · deuteranope 3.51 · tritanope 1.68 · grey 4.51
##
## so §8.3's own table misses the ~7 it advertises, and misses 5 under four of
## the five observers. AN EARLIER VERSION OF THIS TEST MEASURED ONLY BANDS 1, 4
## AND 8 (`SAMPLES`), which are three steps apart, and passed — a scope that made
## the failure structurally invisible while the docstring called it §13's
## blocking assertion.
##
## Not fixed by repainting: the hexes are 🔷 PROPOSED in §8.3 and subordinate to
## doc 12, and choosing replacements is inventing numbers (house rule 1). The
## exact figures are asserted so a doc fix turns this red and forces the table to
## be re-imported. build/plan/q-a11y-legible.md carries the ruling request.
func test_docs_13_8_3_ramp_misses_delta_l_5_between_adjacent_bands() -> void:
    var failing: Array = []
    for kind in SIMS:
        var ls := _lstars(Palette.BAND_FILL_CVD, kind)
        var worst := 999.0
        var worst_at := -1
        for i in ls.size() - 1:
            var d: float = absf(float(ls[i + 1]) - float(ls[i]))
            if d < worst:
                worst = d
                worst_at = i
        var want: Array = ADJACENT_MIN_DL[kind]
        assert_almost(worst, float(want[0]), 0.02,
            "%s: worst adjacent step is %.2f L*, not the recorded %.2f — the "
                % [kind, worst, float(want[0])]
            + "ramp or the pipeline moved")
        assert_eq(worst_at, int(want[1]),
            "%s: the weakest step is between bands %d and %d"
                % [kind, int(want[1]), int(want[2])])
        if worst < MIN_DELTA_L:
            failing.append(kind)
    var clearing: Array = []
    for kind in SIMS:
        if not failing.has(kind):
            clearing.append(kind)
    assert_eq(clearing, SIMS_CLEARING_5,
        "the observers whose adjacent §8.3 bands clear %.1f L*. If this grew, "
            % MIN_DELTA_L
        + "§8.3 was repainted and build/plan/q-a11y-legible.md can be closed")


## The coarse triple the screens sample today, as a diagnostic and nothing more.
## `band_color_cvd` is only ever asked for a raider's morale, and three values
## three bands apart DO clear 5 L* under every observer — which is why the
## failure above never showed up when only these were measured. Kept, labelled,
## and explicitly NOT presented as §13's criterion.
func test_three_bands_apart_clears_five_which_is_not_the_criterion() -> void:
    var cols: Array = []
    for v in SAMPLES:
        cols.append(Palette.band_color_cvd(v))
    for kind in SIMS:
        var ls := _lstars(cols, kind)
        for i in ls.size() - 1:
            var d: float = absf(float(ls[i + 1]) - float(ls[i]))
            assert_true(d >= MIN_DELTA_L,
                "%s: sampled bands %d/%d differ by only %.2f L*"
                    % [kind, i, i + 1, d])


## §8.3's central claim about its own ramp: "Bands are ordered by lightness."
## It holds for all ten steps under every simulation — that monotonicity is what
## makes the ramp readable with no hue channel at all.
func test_cvd_ramp_is_lstar_monotone_under_every_simulation() -> void:
    for kind in SIMS:
        var ls := _lstars(Palette.BAND_FILL_CVD, kind)
        for i in ls.size() - 1:
            assert_true(float(ls[i + 1]) > float(ls[i]),
                "%s: band %d (L* %.2f) is not lighter than band %d (L* %.2f)"
                    % [kind, i + 1, ls[i + 1], i, ls[i]])


## Contrast after deuteranope simulation, at the only scale where a contrast
## ratio can be asked of a ramp at all.
##
## THE BRIEFED CRITERION WAS ">= 3:1 BETWEEN ADJACENT BANDS AFTER DEUTERANOPE
## SIMULATION" AND THAT IS ARITHMETICALLY UNREACHABLE — not by this ramp, by any
## ramp inside §8.3's window. Two consecutive 3:1 steps need 9:1 end to end;
## L* 16 to L* 79 affords 8.6:1, and reaching 9:1 would need either an L* 82 top
## step or a pure-black bottom, which docs/12 §4.2 forbids outright. So the
## assertion is made where it is meaningful: end to end across the active ramp,
## after the simulation, against §13's 3:1 UI-boundary figure. The adjacent-step
## ratios are reported by tools/art/cvd.py as a diagnostic and are all ~1.2-1.5:1
## by construction; build/plan/q-a11y-legible.md asks a human to confirm that
## ΔL* is the right criterion, which is what §13's own wording says.
func test_active_cvd_ramp_end_to_end_contrast_after_deuteranope() -> void:
    var lo := _simulate(Palette.band_color_cvd(SAMPLES[0]), "deuteranope")
    var hi := _simulate(Palette.band_color_cvd(SAMPLES[SAMPLES.size() - 1]),
        "deuteranope")
    assert_true(_contrast(lo, hi) >= 3.0,
        "deuteranope end-to-end contrast %.2f:1 < 3:1" % _contrast(lo, hi))


# ---------------------------------------------------------------- the conflict, as facts

## THE DEFAULT MUST NOT MOVE WITHOUT A HUMAN RULING. The reference concepts win on
## art by standing user rule, so red/amber/green stays the shipped ramp; docs/13
## §13 makes CVD safety blocking, so the alternative exists behind
## `colourblind_safe`. This test is the lock on the default half.
func test_default_ramp_is_still_the_reference_ramp() -> void:
    assert_eq(Palette.band_color(15), Palette.DANGER, "<30 is the reference red")
    assert_eq(Palette.band_color(45), Palette.CAUTION, "30-64 is the reference amber")
    assert_eq(Palette.band_color(80), Palette.POSITIVE, ">=65 is the reference green")
    assert_eq(Palette.morale_color(45), Palette.band_color(45),
        "morale and success chance share one band function (04-palette.md §5)")
    assert_eq(Palette.OPT_CVD_SAFE, "colourblind_safe",
        "the option key is the settings-file format — renaming it is a migration")
    # The DOCUMENTED default, not this machine's settings.cfg: docs/13 §15.1 owns
    # it, and until that row lands the key is absent and the default is Off by
    # construction (Palette.cvd_safe probes DEFAULTS for exactly that reason).
    var defaults: Dictionary = GameSettings.DEFAULTS
    if defaults.has(Palette.OPT_CVD_SAFE):
        assert_false(bool(defaults[Palette.OPT_CVD_SAFE]),
            "the CVD ramp ships Off — the reference ramp is the default until ruled on")
    # The switch selects, and only selects, between the two ramps. Written against
    # the live flag rather than a hard-coded expectation so the assertion is the
    # same on a clean checkout and on a machine with the option turned on.
    var want: Color = Palette.band_color_cvd(45) if Palette.cvd_safe(null) \
        else Palette.band_color(45)
    assert_eq(Palette.band_color_active(null, 45), want,
        "band_color_active honours colourblind_safe and nothing else")


## WHY §8.3 WAS RIGHT, AS A MEASUREMENT RATHER THAN AN ASSERTION.
##
## §8.3 says only that "a red→green ramp does not" stay separable. It does not say
## by how much, and the art pass adopted the reference hues anyway. Measured: the
## reference ramp's CAUTION (#FBB62B) and POSITIVE (#32C24D) — the amber/green
## pair that separates "middling" from "fine", on both morale and the raid-prep
## success figure — collapse to ΔL* 2.2 under PROTANOPIA. Under deuteranopia and
## greyscale they survive (13.0 and 9.2), so protanopia is the specific failure
## and 8% of men is the specific audience.
##
## This test asserts the failure so the conflict is a fact in the suite, not an
## opinion in a document. It goes red the day someone repaints the ramp — which is
## exactly the day the ruling in build/plan/q-a11y-legible.md must be revisited.
func test_reference_ramp_collapses_under_protanopia() -> void:
    var cols := [Palette.band_color(15), Palette.band_color(45),
        Palette.band_color(80)]
    var ls := _lstars(cols, "protanope")
    var d: float = absf(float(ls[2]) - float(ls[1]))
    assert_true(d < MIN_DELTA_L,
        ("the reference amber/green pair now separates by %.2f L* under protanopia"
        + " — better than the 2.2 recorded here. Re-run tools/art/cvd.py and"
        + " revisit build/plan/q-a11y-legible.md") % d)
    # Not L*-monotone either: amber is LIGHTER than green, so "worse" and "better"
    # are not ordered by weight the way §8.3 requires even for full-colour vision.
    var plain := _lstars(cols, "none")
    assert_true(float(plain[1]) > float(plain[2]),
        ("reference ramp: amber is no longer lighter than green (%.1f vs %.1f)"
        + " — the ramp may now be ordered by lightness, §8.3's primary axis")
        % [plain[1], plain[2]])


## §8.3's promise about its OWN table: "a fill and an ink guaranteed >= 4.5:1
## against each other". Measured, it is not true at the crossover, where the ink
## flips from cream to near-black: bands 4, 5 and 6 come in at 4.06, 3.48 and
## 4.07:1. The hexes are 🔷 PROPOSED in that section and subordinate to doc 12, so
## this is a doc defect to raise rather than a code defect to patch — and patching
## it here would mean inventing three hexes, which house rule 1 forbids.
##
## The exact list is asserted so that fixing the doc turns this red and forces the
## table to be re-imported rather than diverging silently.
func test_docs_13_8_3_fill_ink_pairs_miss_their_own_4_5_promise() -> void:
    var below: Array = []
    for i in Palette.BAND_FILL_CVD.size():
        var cr := _contrast(Palette.BAND_FILL_CVD[i], Palette.BAND_INK_CVD[i])
        if cr < 4.5:
            below.append(i)
        assert_true(cr >= 3.0,
            "§8.3 band %d fill/ink is %.2f:1 — below even §13's 3:1 floor" % [i, cr])
    assert_eq(below, [4, 5, 6],
        "§8.3's fill/ink pairs below its own 4.5:1 promise. If this list changed, "
        + "docs/13 §8.3 was repainted — re-import the table and re-read the q entry")


## The CVD fills are PLATE colours and cannot be used as text tints on this
## palette's surfaces. Recorded as a test because it is the reason no live call
## site was switched over: band 0 as text on SURFACE_PANEL measures 1.35:1, and
## a well-meaning future edit routing `morale_color` through the CVD ramp would
## make the roster unreadable rather than more accessible.
func test_cvd_fills_are_plates_not_text_tints() -> void:
    var worst := 99.0
    for i in Palette.BAND_FILL_CVD.size():
        worst = minf(worst, _contrast(Palette.BAND_FILL_CVD[i], Palette.SURFACE_PANEL))
    assert_true(worst < 3.0,
        "the darkest §8.3 fill now clears 3:1 on SURFACE_PANEL (%.2f:1); the ramp "
        % worst
        + "could become a text tint after all — revisit the handoff")
