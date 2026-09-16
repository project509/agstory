extends RefCounted
## Semantic colour tokens for the whole interface.
##
## art/ref/specs/04-palette.md owns every hex here and records where each was
## sampled from the reference concepts (ideaboard/Reference Concepts). Screens
## refer to a ROLE, never a hex — that discipline is what let this file replace
## the paper palette without touching a screen, and it is what will let the next
## repaint do the same.
##
## The look, in one line: four depths of near-black navy lit by warm off-white
## text, bronze edges and one steel-blue selection colour; danger is a hot red,
## caution a saturated amber, commitment a crimson plate under a gold rule.
##
## Two rules enforced by test, not by code:
##   No pure black (#000000) and no pure white (#FFFFFF) anywhere (docs/12 §4.2).
##   The commit colour (CTA_*) appears on exactly ONE control per screen.
##
## THE BAND RAMP IS AN OPEN RULING. `band_color` below is the reference concepts'
## red/amber/green; `band_color_cvd` is docs/13 §8.3's L*-ordered alternative, and
## the two authorities disagree in writing. See §8.3 / the `colourblind_safe`
## option below and build/plan/q-a11y-legible.md — do not quietly pick a side.

const Enums = preload("res://sim/model/Enums.gd")
const Services = preload("res://game/core/Services.gd")

# ---------------------------------------------------------------- surfaces
const GROUND_PAGE := Color("030B13")      ## behind everything; the letterbox
const GROUND_FRAME := Color("0C151D")     ## header bar, gutters between regions
const GROUND_RAIL := Color("091116")      ## nav rail
const SURFACE_PANEL := Color("060C12")    ## bordered panels, cards, logs
const SURFACE_INSET := Color("0D151C")    ## slots, wells, bar tracks, portrait frames
const SURFACE_CHIP := Color("020A12")     ## header resource chips
const SURFACE_CALLOUT := Color("08080C")  ## base under the tinted success callout
const NAV_ACTIVE_TOP := Color("142635")   ## active nav pill gradient, top
const NAV_ACTIVE_BOTTOM := Color("142738")
const CTA_TOP := Color("5B1D27")          ## the ONE commit plate per screen, top
const CTA_BOTTOM := Color("511924")

# ---------------------------------------------------------------- edges
const EDGE_BRONZE := Color("856A57")      ## panel borders — the warm family
const EDGE_BRONZE_SHADOW := Color("5F4D3E")
const EDGE_BRONZE_SOFT := Color("7F6E63") ## header divider, card top edge
const EDGE_SLATE := Color("3A373A")       ## plain slot border — the cool family, faint
const EDGE_SLATE_LIGHT := Color("3F434B") ## portrait frames
const EDGE_RAIL := Color("262E35")        ## the nav rail's right edge
const EDGE_STEEL := Color("4982A2")       ## active / selected / focus ring
const EDGE_STEEL_DIM := Color("3D5F79")
const EDGE_CTA_RED := Color("D03E37")
const EDGE_CTA_RED_DARK := Color("842424")
const EDGE_CTA_GOLD := Color("FCB85D")    ## the CTA's lit top rule
const EDGE_PORTRAIT_BRONZE := Color("7C6454")

# ---------------------------------------------------------------- text
const TEXT_TITLE := Color("F6EFDF")       ## section titles, names, active nav
const TEXT_BODY := Color("F7F1E1")        ## subject titles, primary values
const TEXT_LABEL := Color("B8CDDF")       ## cool sub-labels ("Potential Rewards")
const TEXT_MUTED := Color("9A9A9C")       ## metadata, quiet numerals
const TEXT_MUTED_WARM := Color("B4B1AE")  ## log rows, inactive nav
const TEXT_NUMERIC := Color("C0B7AC")     ## warm cream for stacked numbers
const TEXT_SLATE := Color("758A9B")       ## class line, quotes — keep >= 15px
const TEXT_LOG := Color("C5CAD1")         ## combat log body
const TEXT_ON_CTA := Color("EDE9D9")
const TEXT_ON_BUBBLE := Color("2A1F14")   ## dark ink on the cream speech bubble

# ---------------------------------------------------------------- accents
const ACCENT_GOLD := Color("ECA742")      ## currency, brass icons, CTA sub-line
const ACCENT_GOLD_LIGHT := Color("FCB85D")
const ACCENT_GEM := Color("B1A0F6")       ## reputation chip numeral
const ACCENT_STEEL := Color("4982A2")     ## selection
const ACCENT_CYAN := Color("43DBF3")      ## secondary resource
const ACCENT_BUBBLE := Color("FAE1B9")    ## speech bubble fill

# ---------------------------------------------------------------- state
const DANGER := Color("F73526")           ## low morale, failure, low odds
const CAUTION := Color("FBB62B")          ## mid morale, warnings, middling odds
const POSITIVE := Color("32C24D")         ## high morale, gains
const CRIT := Color("F1750E")             ## critical damage numbers
const HIT_FLASH := Color("FFF6DC")        ## docs/12 §5.2: the one-frame hit flash on a struck figure
const INFO := Color("7C86CC")             ## neutral log rows
const ARCANE := Color("5911B4")           ## spell log rows

const BAR_HP := Color("AE1C2C")           ## a desaturated blood red, not DANGER
const BAR_HP_LIGHT := Color("D03E37")
const BAR_MANA := Color("006C9C")
const BAR_MANA_LIGHT := Color("01A2D9")

# ---------------------------------------------------------------- kit roles (W1-CHROME, KIT-10)
# The 45 hexes that lived in Theme.gd, Frame.gd, Bar.gd, Widgets.gd, Badge.gd,
# SceneStage.gd and Tavern.gd, as roles. SAME HEXES — retuning the kit is now
# one file, and no art-gate baseline moved when these landed. Add only; never
# rename (22 files preload this and tests assert the names above).

# -- cards, wells, art cards (01 §3, 06 §7.1, 01 §2)
const SURFACE_CARD := Color("020C14")     ## PanelRound: roster cards, event log; Tavern's selected card
const EDGE_CARD := Color("514D4C")        ## PanelRound's 1px rim (01 §3 measures 1px; 06 §8's 2px bevel is recorded, not built — KIT-19)
const SURFACE_WELL := Color("02070E")     ## PanelInset
const EDGE_WELL := Color("292B2E")
const SURFACE_ART_CARD := Color("070E1B") ## PanelCard: the boss-art card in the sidebar
const EDGE_ART_CARD := Color("444247")
const EDGE_CALLOUT_DANGER := Color("BA302D")  ## PanelCalloutDanger's rim: a cooler red than DANGER, the plate is the loud part

# -- the ONE dark bubble/callout chrome (03 §3, CRITIC-C02, Q04)
const SURFACE_BUBBLE := Color("040E18")   ## callout_plate.png / bubble_plate.png fill; a tail drawn in code matches it
const EDGE_BUBBLE := Color("605A54")      ## its outer line
const EDGE_BUBBLE_INNER := Color("2A2E32")## its inner line
const EDGE_CALLOUT := EDGE_BUBBLE         ## the building callout's rim IS the bubble's until Q04 forks them
const SURFACE_TOOLTIP := Color("0B1B26")  ## TooltipPanel (06 §8), at α0.95 in the theme
const EDGE_TOOLTIP := Color("4C6B81")

# -- slots (06 §2)
const SURFACE_SLOT := Color("11181E")     ## Slot / ButtonSlot / rarity slots
const SURFACE_SLOT_LIT := Color("161F27") ## ButtonSlot hover
const SLOT_RIM := Color("33302F")         ## the plain slot's 2px rim
const SLOT_RIM_LIT := Color("5A4B44")     ## hovered
const SURFACE_SLOT_BRONZE := Color("0E1016")  ## SlotBronze
const SURFACE_ABILITY := Color("0A1422")  ## SlotAbility / SlotReady
const EDGE_ABILITY := Color("3F5161")
const EDGE_READY_GOLD := Color("C9A24A")  ## SlotReady, ButtonChip's pressed rim
const SURFACE_PORTRAIT := Color("0B141F") ## PortraitFrame
const SURFACE_MINI := Color("0F151E")     ## SlotMini / ButtonMini (01 §4.1)
const EDGE_MINI := Color("35393E")
const SURFACE_PLATE := Color("0E161E")    ## ButtonPortrait plate (06 §7.2)
const SURFACE_PLATE_LIT := Color("15202B")## ButtonPortrait / ButtonMini hover plate
const EDGE_BRONZE_RIM := Color("886955")  ## btn_secondary.png's rim, ButtonPortrait's rim, the wax seal's lip
const EDGE_BRONZE_LIT := Color("A78B7A")  ## the lit line on those

# -- ink on chrome
const TEXT_DISABLED := Color("6E6A66")    ## disabled Button text
const TEXT_DISABLED_ON_CTA := Color("8A7F80")
const INK_NAV := Color("9B9A9D")          ## inactive nav label (Frame.gd too)
const INK_NAV_ACTIVE := Color("F0E3D2")
const INK_NAV_DISABLED := Color("55575C")
const INK_NAV_GLYPH := Color("8A8A8A")    ## the rail glyph's modulate (Frame.gd)
const INK_NAV_GLYPH_ACTIVE := Color("F9F3E0")
const INK_WORDMARK_OUTLINE := Color("413D3A")  ## 01 §5: the wordmark's 1px dark warm outline, never black
const INK_NUMBER_OUTLINE := Color("1A0A05")    ## 05 §5: damage numbers' 2px outline (CRITIC-C05)
const INK_BUBBLE_DOTS := Color("3B2F27")  ## the "..." in the cream bubble (SceneStage.gd)
const FLASH_HIT := Color("FFF6DC")        ## docs/12 §5.2: the one-beat hit flash on a struck figure (SceneStage.hit)
const MARK_FUMBLE := Color("F2C14E")      ## docs/12 §5.3: the "!" over a fumbling figure (SceneStage.act "fumble")
const INK_BAR := Color("F5F1E8")          ## Bar.gd's numerals
const INK_BAR_OUTLINE := Color("0B1118")

# -- frame lines (01 §1; Frame.gd)
const GROUND_SEAM := Color("020406")      ## the 1px dark inset seam around the scene
const HEADER_RULE := Color("3B3532")      ## the shared rule at y=717
const HEADER_DIVIDER := Color("7A6152")   ## 01 §1: the 2px bronze divider under the header
const HEADER_RULE_LIT := Color("988880")  ## 03 §6: the tagline's trailing rule
const EDGE_RAIL_CORE := Color("463E3E")   ## 01 §1: the rail border's core at x=208

# -- bars (Bar.gd, 06 §4)
const BAR_RIM := Color("2C3F5C")
const BAR_TRACK := Color("010D1B")
const BAR_BOSS_LIGHT := Color("F24A50")   ## the boss track's two-tone fill
const BAR_BOSS := Color("B01A28")
const BAR_HP_FILL_LIGHT := Color("F54841")  ## the party HP bar's fill (Bar.gd's draw, not BAR_HP_LIGHT's tint)
const BAR_HP_FILL := Color("811725")

# -- badges, scrollbars, stamps, board
const BADGE_DANGER := Color("E44434")     ## Badge.gd's default disc (Concept 1's frown)
const SCROLL_TRACK := Color("1B2630")
const SCROLL_THUMB := EDGE_BRONZE         ## HALL-14: the grabber is bronze, 8px
const SCROLL_THUMB_LIT := EDGE_BRONZE_LIT
const SURFACE_PAPER := Color("17120E")    ## PanelPaper: a notice on the cork (TOWN-24) — the warm family's ground
const EDGE_PAPER := Color("7F6E63")       ## = EDGE_BRONZE_SOFT's hex; the notice's rim
const SURFACE_PAPER_LIT := Color("1F1913")## a hovered/selected notice

## Rarity colours. The five NAMES are ✅ CANON; the hexes are 🔷 PROPOSED
## (04-palette.md §6). Indexed by Enums.Rarity so a rarity int reads straight
## into a colour. Legendary is gold — the metal every border here is made of.
const RARITY := [
	Color("9A9AA5"),   # Common
	Color("5FB94E"),   # Uncommon
	Color("4A8FD4"),   # Rare
	Color("9B5FCB"),   # Epic
	Color("ECA742"),   # Legendary
]

static func rarity_color(rarity: int) -> Color:
	if rarity < 0 or rarity >= RARITY.size():
		return TEXT_MUTED
	return RARITY[rarity]


## One band function for morale AND success chance (04-palette.md §5): the
## references paint 17% red and 42% amber, the same bands canon's morale uses.
##
## THIS IS THE DEFAULT AND IT IS DISPUTED. docs/13 §8.3 rules against exactly this
## axis — "The hue axis runs red → ochre → olive → teal, which stays separable
## under deuteranopia and protanopia; a red→green ramp does not" — while the
## reference concepts, which set the art bar, paint red/amber/green. The project's
## ambiguity rule says implement the documented default behind a switch rather than
## resolve it: this stays the default because the reference wins on art by standing
## user rule, and `band_color_cvd` is the §8.3 answer, chosen by `colourblind_safe`.
## A human ruling is owed; build/plan/q-a11y-legible.md states the question.
static func band_color(value: int) -> Color:
	if value < 30:
		return DANGER
	if value < 65:
		return CAUTION
	return POSITIVE


## docs/13 §8.3's ten bands, verbatim, fill then ink. A band is a PAIR, not a
## colour — "a fill and an ink guaranteed >= 4.5:1 against each other. The chip is
## therefore surface-independent" — which is the whole reason the ramp is allowed
## to run down to L* 16: it is a plate with its own ink, never tinted text.
##
## Indexed by `Enums.morale_band`, so the doc's Range column and this array cannot
## drift apart. Hexes are 🔷 PROPOSED in §8.3 and subordinate to doc 12.
const BAND_FILL_CVD := [
	Color("521015"),   # 0  Very Upset         L* 16
	Color("6D1A19"),   # 1  Upset              L* 23
	Color("85301C"),   # 2  Unhappy            L* 30
	Color("94491D"),   # 3  Annoyed            L* 37
	Color("99621F"),   # 4  Slightly Annoyed   L* 44
	Color("8E7C33"),   # 5  Content            L* 51
	Color("77914E"),   # 6  Happy              L* 58
	Color("75A56F"),   # 7  Very Happy         L* 65
	Color("7FB79A"),   # 8  Very Happy         L* 72
	Color("93C7BC"),   # 9  Loves Their Guild  L* 79
]

## The ink for each fill above. §8.3 gives two: cream on bands 0-4, near-black on
## 5-9, which is where the ramp crosses the light/dark ink line.
const BAND_INK_CVD := [
	Color("E8E6D6"), Color("E8E6D6"), Color("E8E6D6"), Color("E8E6D6"), Color("E8E6D6"),
	Color("2B2A24"), Color("2B2A24"), Color("2B2A24"), Color("2B2A24"), Color("2B2A24"),
]


## docs/13 §8.3's L*-ordered alternative to `band_color`: ten steps, hue running
## red → ochre → olive → teal. §13's CVD row is the acceptance test — "Adjacent
## morale bands must remain distinguishable by lightness alone" — and
## tests/unit/test_palette_cvd.gd measures it under the Brettel/Viénot simulations
## rather than asserting it by assertion.
##
## MEASURED, IT DOES NOT MEET THAT ROW EITHER, AND §8.3'S "~7 L* PER STEP" IS MET BY
## NO OBSERVER. The ramp IS monotone in lightness under all four simulations, which
## is the property that survives; but the worst adjacent step is 4.51 unsimulated,
## 6.30 protanope, 3.51 deuteranope, 1.68 tritanope and 4.51 greyscale, so four of
## the five miss 5 L*. The weak steps are 4-5 and 5-6, the same crossover where the
## fill/ink pairs miss §8.3's own 4.5:1 promise. The hexes are 🔷 PROPOSED and
## subordinate to doc 12, so this is a defect to raise rather than three colours to
## invent: build/plan/q-a11y-legible.md carries the numbers and the ruling request.
static func band_color_cvd(value: int) -> Color:
	return BAND_FILL_CVD[Enums.morale_band(value)]


## The ink §8.3 pairs with `band_color_cvd`'s fill. A caller that draws the CVD
## ramp MUST use both: the fill alone is a plate colour and reaches L* 16, which is
## unreadable as text on any surface in this palette (SURFACE_PANEL is itself
## near-black, so fill-as-text measures 1.35:1 against it — see the report).
static func band_ink_cvd(value: int) -> Color:
	return BAND_INK_CVD[Enums.morale_band(value)]


## The option key. In `GameSettings.DEFAULTS` since W6-SETTINGS (default Off,
## ship plan §6 #40 / UI-47) with its row on the Options screen ("Colour-safe
## morale ramp"); BACKLOG.md:169 was the mandate ("colourblind-safe morale
## coding"). The settings file's key, so renaming it is a migration.
const OPT_CVD_SAFE := "colourblind_safe"

## Whether the player asked for §8.3's ramp. Null-tolerant on purpose: widgets are
## built by unit tests with no autoloads registered, and a missing autoload must
## mean the documented default (Off), never a crash. `who` may be null —
## `Services.find` falls through to the SceneTree root.
static func cvd_safe(who: Node) -> bool:
	var settings: Node = Services.find(who, "GameSettings")
	if settings == null or not settings.has_method("get_value"):
		return false
	return bool(settings.get_value(OPT_CVD_SAFE))


## The band FILL the active ramp wants. In reference mode this is a text tint; in
## §8.3 mode it is a plate that needs `band_ink_cvd` over it. PLATE sites only:
## the Options row's swatches (Settings.gd) draw it, and the roster's morale bar
## and the kit's sparkline are the other two plates (handoff-W6-SETTINGS). The
## text-tint sites (`morale_color`) stay on the reference ramp on purpose —
## band 0's fill as text measures 1.35:1 on SURFACE_PANEL
## (tests/unit/test_palette_cvd.gd) — until the ruling moves the chips to plates.
static func band_color_active(who: Node, value: int) -> Color:
	return band_color_cvd(value) if cvd_safe(who) else band_color(value)


## Morale colour by band. Bands 0-2 are the at-risk end docs/13 §9 demands be
## nameable in two seconds, so they are the loudest colour on the roster.
static func morale_color(morale: int) -> Color:
	return band_color(morale)
