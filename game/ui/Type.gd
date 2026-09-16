extends RefCounted
## The type scale, in Godot font_size pixels. art/ref/specs/05-typography.md §3
## measured every one of these from the reference concepts (cap height ÷ the
## face's cap ratio); they are ±1px until the pixel diff settles them.
##
## Screens use a NAME from this list, never a number, so the scale can be tuned
## in one place when a diff says a style is a pixel off.

const WORDMARK := 58           ## "A Guild Story" on the dashboard header
const WORDMARK_COMPACT := 44   ## the raid screen's smaller header
const TAGLINE := 18            ## "Questionable people. Worse decisions."

const FIGURE_XL := 34          ## the success-chance percentage
const DAMAGE_CRIT := 34        ## floating "-842"
const DAMAGE := 28             ## floating "-317"

const CHIP := 24               ## header resource chips
const SUBJECT := 24            ## a panel's subject: "The Sludge Maw"
const SECTION := 22            ## "Current Raid"
const SECTION_SM := 17         ## "Recent Events", "Available"
const NAV := 18                ## nav rail labels — 01 §6: "Adventure's Board" only fits x=73..200 at <= 18px
const OBJECTIVE := 20          ## raid objective title
const MORALE_VALUE := 20       ## the morale number — never smaller than the name (docs/05 §10.3)

const LABEL_LG := 18           ## "Raid Team"
const NAME := 18               ## a raider's name on a card
const CALLOUT_TITLE := 18      ## building callout title
const BOSS_NAME := 18
const CTA_COST := 18           ## the gold line under the CTA
const CTA := 21                ## "Send Them Anyway"

const LABEL := 16              ## "Potential Rewards", "Estimated Success Chance"
const LINK := 16               ## "Edit Team", "View All"
const LEVEL := 16              ## "Lv. 12"
const BODY := 15               ## event rows, objective lines, callout subtitles
const CLASS := 15              ## "Warrior" beside the class glyph
const QUOTE := 14              ## the raider's one-liner
const SMALL := 13              ## combat log rows, bubble text, "48/128"
const STACK := 11              ## stack counts in ability cells

const LOG_ROW_PITCH := 29      ## event/combat log line pitch
const BUBBLE_LINE_PITCH := 16


# ---------------------------------------------------------------- text scale
#
# docs/13 §4.4: "Three user text scales — 100% / 125% / 150% — applied as a
# multiplier to every style except `stamp`. At 150% every layout in §9 must still
# fit its panel by reducing row count (scrolling), never by truncating a morale
# value, a state word, or a class name." §13's text-scaling row is Blocking: Yes.
#
# THE SCALE LIVES HERE, WITH THE CONSTANTS, ON PURPOSE. The alternative is 27
# scaled call sites inside Theme.gd's `build()` and a dozen more in the screens
# that set `font_size` directly; a screen would eventually add the 28th and
# forget. One function beside the numbers it multiplies is the version that
# cannot be half-applied.
#
# TWO ENTRY POINTS, ONE POLICY — AND THE POLICY IS GameSettings'. A caller that
# already holds the settings autoload uses `GameSettings.scaled()`; this is the
# same rule for the static UI layer, which has no autoload access. Neither
# invents the multiplier: §4.4 does.
#
# They agree on every value that can actually reach them, and that is now true by
# construction rather than by coincidence. `GameSettings._coerce` runs on both
# `set_value` and `load_from_disk`, so `get_value("text_scale")` is ALWAYS one of
# §4.4's three steps — a hand-edited 110 or 140 in settings.cfg never survives the
# door. Its recovery rule for a value that is not a step is "fall back to the
# default", and `step()` below therefore does exactly that too. It used to snap to
# the NEAREST step, which made `step(140)` = 150 while a stored 140 coerces to
# 100: two recovery policies for the same undefined input, which is how a third
# implementation of §4.4 starts. One policy, and it lives in the file that reads
# the player's file.

## §4.4's three steps, and nothing between them.
const SCALES := [100, 125, 150]
const SCALE_DEFAULT := 100


## `pct` if docs/13 §4.4 lists it, otherwise the default. A hand-edited
## `settings.cfg`, or a fourth step added to docs/13 §15.1 before this file is told
## about it, yields a step that exists rather than being honoured — §4.4 lists
## three and the layouts in §9 were only ever proven at three.
##
## The fallback is 100 and not the nearest step because that is `GameSettings`'
## documented recovery for the same key ("An out-of-range text scale would
## otherwise make every screen unreadable") and one undefined input must not have
## two answers. Nothing in the running game can reach this branch: the autoload
## coerces the stored value before any caller sees it.
static func step(pct: int) -> int:
	return pct if SCALES.has(pct) else SCALE_DEFAULT


## `size` at the player's text scale.
##
## IDENTITY AT 100% IS BY CONSTRUCTION, NOT BY LUCK. The art pass's pixel-diff
## baselines (BUILD_STATE.md: Kit 16.9 / Town 26.3 / RaidPrep 20.2 MAE) were all
## measured at the unscaled sizes. Threading this call through the Theme must not
## move a single one of them, so the default path returns `size` untouched instead
## of trusting float arithmetic to round-trip.
static func at(size: int, pct: int = SCALE_DEFAULT) -> int:
	var s: int = step(pct)
	if s == SCALE_DEFAULT:
		return size
	return int(round(float(size) * float(s) / 100.0))


# ---------------------------------------------------------------- numerals
#
# docs/13 §4.3 (non-negotiable): "Gold shows 1,240g" — every numeral the player
# reads carries the locale's thousands separator, "from the string table, never
# hard-coded". There is no string table yet (RULES-14: the whole UI is literal
# English), so the separator is ONE constant here and every consumer — the header
# chips (KIT-15), later the CTA subline, the Market and the Results tally — asks
# these two functions rather than formatting "%d" itself. en-US until the table.

const THOUSANDS_SEPARATOR := ","


## `12480` -> "12,480"; `60` -> "60"; `-1500` -> "-1,500".
static func num(n: int) -> String:
	var digits := str(absi(n))
	var out := ""
	var run := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		run += 1
		if run % 3 == 0 and i > 0:
			out = THOUSANDS_SEPARATOR + out
	return ("-" + out) if n < 0 else out


## The gold readout: `num(n)` and the unit the chips and tests already print
## ("60 G", test_screens.gd) — the separator only ever appears at four digits.
static func gold(n: int) -> String:
	return "%s G" % num(n)


## A counted noun: "1 enemy", "3 enemies", "1 day", "2 days". docs/13 §14 asks
## for ICU plurals; until a string table exists this is the one door (LOOP-04,
## UI-02: "1 enemies" was printed on the Town and the Board by two hand-rolled
## copies of the same format). Both forms are passed, never derived — English
## has no rule a suffix can express ("enemy" / "enemies").
static func count(n: int, one: String, many: String) -> String:
	return "%s %s" % [num(n), one if n == 1 else many]
