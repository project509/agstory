# handoff — a11y-legible

Exact edits in files this agent does not own. Grouped by item.

Parse-checked state at handoff: `PARSE_CHECK OK` (122 scripts); suite 1214 tests, 4 failures,
all in `test_golden.gd` / `test_adventures.gd` (the sim agent's in-flight work). Nothing in
`game/ui/`, `game/screens/Tavern.gd`, `tests/unit/test_palette_cvd.gd` or
`tests/unit/test_a11y_legibility.gd` fails.

---

## 1. M6-A11Y-06 — the new option needs its docs/13 §15.1 row FIRST

`docs/13 §15.1`'s rule is *"if an option is not in this table, it does not exist in the
settings screen"*, and `game/core/GameSettings.gd:29`'s docstring says adding a key without
the row "is the same mistake in the other direction". So this edit comes before the two
after it.

### 1a. `docs/13-ui-ux.md` §15.1, after the `Reduced motion` row

    | Colour-blind safe morale ramp | Off | §8.3 | Player | Global |

Mandate: `BACKLOG.md:169` ("colourblind-safe morale coding"). Which ramp SHIPS is an open
ruling — `build/plan/q-a11y-legible.md` is written for docs/15 and carries the measurements.

### 1b. `game/core/GameSettings.gd` — the key (the audio agent owns this file)

In `DEFAULTS`, immediately after the `reduced_motion` line:

old:

    "reduced_motion": false,        # docs/13 §13

new:

    "reduced_motion": false,        # docs/13 §13
    "colourblind_safe": false,      # docs/13 §8.3 / §15.1 — the ramp ruling is open

`Palette.cvd_safe()` already probes `DEFAULTS` for this key and returns the documented
default when it is absent, so nothing breaks before or after this edit lands.

### 1c. `game/screens/Settings.gd` — the row, with a NON-EMPTY reason

The option must NOT be presented as live: no shipping call site consumes the CVD ramp yet,
and that is deliberate (report + `q-a11y-legible.md` finding 3 — §8.3's fills are plate
colours, not text tints). `Settings.gd:45-46`'s convention is that a non-empty `reason`
marks a row as not yet wired, which is exactly this case.

In `ROWS`, after the `reduced_motion` entry:

    {"key": "colourblind_safe", "label": "Colour-blind safe morale",
     "reason": "The band ramp is an open ruling - build/plan/q-a11y-legible.md.",
     "note": "Replaces the red/amber/green bands with docs/13 8.3's "
           + "lightness-ordered red-ochre-olive-teal chips."},

---

## 2. M6-A11Y-05 — the Theme half of the text scale

`game/ui/Type.gd` now owns the arithmetic: `Type.at(size, pct)` (exact identity at 100 by
construction) and `Type.step(pct)` (snaps to §4.4's three steps). Nothing calls them yet.
These edits are the consumers.

### 2a. `game/ui/Theme.gd` — cache per scale, scale in two places only

old (`:20-26`):

    static var _theme: Theme = null


    static func get_theme() -> Theme:
        if _theme == null:
            _theme = build()
        return _theme

new:

    ## One Theme PER TEXT SCALE. docs/13 §4.4's three steps are the only keys that
    ## can appear (Type.step snaps anything else), so the cache is at most three
    ## entries and a scale change is a lookup, not a rebuild of a singleton the
    ## process already handed out.
    static var _themes: Dictionary = {}


    static func get_theme(scale: int = Type.SCALE_DEFAULT) -> Theme:
        var pct: int = Type.step(scale)
        if not _themes.has(pct):
            _themes[pct] = build(pct)
        return _themes[pct]

old (`:63-68`):

    static func _label(t: Theme, name: String, font: Font, size: int, color: Color) -> void:
        t.add_type(name)
        t.set_type_variation(name, "Label")
        t.set_font("font", name, font)
        t.set_font_size("font_size", name, size)
        t.set_color("font_color", name, color)

new:

    ## `scale` is threaded rather than read from a static, so `build()` stays a pure
    ## function of its argument — two scales must be able to exist at once.
    static func _label(t: Theme, name: String, font: Font, size: int, color: Color,
            scale: int = Type.SCALE_DEFAULT) -> void:
        t.add_type(name)
        t.set_type_variation(name, "Label")
        t.set_font("font", name, font)
        t.set_font_size("font_size", name, Type.at(size, scale))
        t.set_color("font_color", name, color)

Same one-line change in `_button` (`:83`), with `scale: int = Type.SCALE_DEFAULT` added as
its last parameter:

old:

    t.set_font_size("font_size", name, size)

new:

    t.set_font_size("font_size", name, Type.at(size, scale))

Then in `build()`:

old (`:94-97`):

    static func build() -> Theme:
        var t := Theme.new()
        t.default_font = Fonts.ui()
        t.default_font_size = Type.BODY

new:

    static func build(scale: int = Type.SCALE_DEFAULT) -> Theme:
        var t := Theme.new()
        t.default_font = Fonts.ui()
        t.default_font_size = Type.at(Type.BODY, scale)

and pass `scale` as the trailing argument of every `_label(...)` / `_button(...)` call in
`build()` — 27 and 9 respectively, mechanical. Plus the two direct sets:

- `:250` `t.set_font_size("font_size", "LinkButton", Type.LINK)` → `Type.at(Type.LINK, scale)`
- `:255` `t.set_font_size("font_size", "TooltipLabel", Type.QUOTE)` → `Type.at(Type.QUOTE, scale)`

**Do NOT** scale the `flat()` / `tex()` margins. §4.4 scales type, not chrome, and moving a
margin moves the pixel-diff baselines.

**Verify after:** `Type.at(x, 100) == x` is asserted by
`tests/unit/test_a11y_legibility.gd::test_text_scale_is_exactly_identity_at_100_percent`, so
a 100% Theme is byte-identical to today's. Re-run `tools/art/refdiff.py` on the Kit / Town /
RaidPrep targets and confirm 16.9 / 26.3 / 20.2 MAE are unchanged (BUILD_STATE.md:239) before
touching any layout constant.

### 2b. The twelve screens that apply the Theme

Identical edit in each; `Services` is already preloaded in all of them.

old:

    theme = Theme_.get_theme()

new:

    theme = Theme_.get_theme(_text_scale())

with this helper added per screen (there is no shared screen base today, which is why the
duplication is listed honestly rather than hidden):

    ## docs/13 §4.4's scale, or the default outside a game. Null-tolerant because the
    ## screen tests mount screens with no GameSettings registered.
    func _text_scale() -> int:
        var s := Services.find(self, "GameSettings")
        return int(s.get_value("text_scale")) if s != null else Type.SCALE_DEFAULT

Sites: `AdventureBoard.gd:79`, `Guildhall.gd:84`, `MainMenu.gd:63`, `Market.gd:104`,
`RaiderDetail.gd:98`, `RaidPrep.gd:68`, `RaidView.gd:133`, `Results.gd:102`,
`Settings.gd:129`, `Town.gd:101`, `game/ui/Boot.gd:59`, and **`game/screens/Tavern.gd:71` —
which this agent owns but deliberately did NOT change, because calling `get_theme(scale)`
before 2a lands is a runtime error and house rule 5 forbids leaving a call to a function
that does not exist yet.** Apply 2a first, then Tavern with the rest.

### 2c. `game/screens/Settings.gd` — rebuild when the scale changes

`_scale_button` (`:319-331`) writes the value and nothing re-reads it. After the write:

    # docs/13 §4.4 is only observable if the Theme is rebuilt; get_theme() caches per
    # scale, so re-entering the screen is a lookup rather than a rebuild.
    var router := Services.find(self, "ScreenRouter")
    if router != null:
        router.goto(router.current_path())

Or connect `GameSettings.changed` in `game/ui/Frame.gd` for a global re-theme. Either
satisfies the item — pick one, not both.

### 2d. The font_size overrides that bypass the Theme

Each needs the scale too, or a screen mixes 100% chrome with 150% body text:

| File:line | Constant |
|---|---|
| `game/screens/Market.gd:676` | `Type.STACK` |
| `game/screens/RaidView.gd:315` | `Type.SMALL` |
| `game/screens/RaidView.gd:848` | `Type.FIGURE_XL` |
| `game/screens/Results.gd:325` | `Type.SECTION` |
| `game/screens/Results.gd:534` | `Type.SMALL` |
| `game/screens/Roster.gd:478` | `Type.SMALL` |
| `game/ui/Bar.gd:80` | `Type.SMALL` |
| `game/ui/Frame.gd:342` | `Type.NAV` |
| `game/ui/Widgets.gd:473` | `Type.CALLOUT_TITLE` |
| `game/ui/Widgets.gd:28-31` | `SIZE_TITLE` / `SIZE_SECTION` / `SIZE_BODY` / `SIZE_META` |

Pattern: `Type.X` → `Type.at(Type.X, <scale>)`. **DECISION for the Widgets owner:** the
`SIZE_*` entries are `const`, so they cannot take a runtime scale — either turn them into
static functions or route their callers through the Theme's type variations instead.

### 2e. The layout consequence — NOT DONE, and it is the larger half

docs/13 §14: *"Layouts reflow by reducing rows, never by truncating a morale value, state
word or class name."* Known hard widths that clip at 150%:

- `Settings.gd:92-95` — `COL_NAME_W 190` / `COL_NOTE_W 458` / `COL_CTRL_W 150`.
- `RaidPrep.gd:379` — the 74px morale chip.
- `Tavern.gd` `_candidate_card` — a fixed 215×262 card with `clip_contents = true`; at 150%
  a backstory bullet is silently cut, which docs/04 §3.5 forbids outright ("Backstory
  bullets are never hidden pre-recruit").

Sizing these is a layout pass, not a handoff line.

---

## 3. M6-A11Y-04 — route the last five morale-glyph sites

The funnel is `Cards.morale_glyph(who_node, morale)` (`game/ui/Cards.gd:26-45`). All five
files already preload `Cards`, so no new `const` line is needed.

`game/screens/Facilities.gd:222`

    old:  Enums.morale_band_emoji(m)], "LabelMorale")
    new:  Cards.morale_glyph(self, m)], "LabelMorale")

`game/screens/Guildhall.gd:296`

    old:  String(r.display_name), m, Enums.morale_band_emoji(m),
    new:  String(r.display_name), m, Cards.morale_glyph(self, m),

`game/screens/Market.gd:654`

    old:  % [who.display_name, m, Enums.MORALE_BAND_EMOJI[who.morale_band()]],
    new:  % [who.display_name, m, Cards.morale_glyph(self, m)],

`game/screens/RaidPrep.gd:378`

    old:  % [r.morale, Enums.MORALE_BAND_EMOJI[r.morale_band()]])
    new:  % [r.morale, Cards.morale_glyph(self, int(r.morale))])

`game/screens/RaiderDetail.gd:290-291` — replaces the local null-tolerant copy

    old:  var settings = Services.find(self, "GameSettings")
          var glyph: String = settings.morale_glyph(_who.morale) if settings != null \
              else Enums.MORALE_BAND_EMOJI[_who.morale_band()]
    new:  var glyph: String = Cards.morale_glyph(self, int(_who.morale))

**Do NOT touch `sim/model/Raider.gd:287` or `sim/core/Morale.gd:147`.** They are sim-side
and may not read an autoload (house rule 6). The audit counted nine sites by including them;
there are eight settable ones.
`tests/unit/test_a11y_legibility.gd::test_the_sim_keeps_its_own_raw_glyph_and_that_is_correct`
asserts they stay raw, so a well-meaning sweep will trip.

**Width, and it is a real risk the audit flagged.** The pip figure is 10 characters
(`"|".repeat(band+1) + ".".repeat(9-band)`) against a 1–2 character emoji.
`game/screens/RaidPrep.gd:379` pins that chip at `Vector2(74, 0)`, which cannot hold the
figure plus the integer at `Type.BODY`. Measure it, then drop the fixed width or raise it —
docs/13 §14 forbids resolving it by truncation.

**The lint that makes a tenth site impossible** — add to `tools/lint_no_global_classes.sh`:

    # docs/13 §13's emoji-free mode reached one panel out of eight because eight files
    # each read the raw table. There is now one funnel (Cards.morale_glyph); this keeps
    # it the only one.
    if grep -rn --include=*.gd -E "MORALE_BAND_EMOJI|morale_band_emoji" game/ \
        | grep -v "game/core/GameSettings.gd" | grep -v "game/ui/Cards.gd"; then
      echo "FAIL: read the morale glyph through Cards.morale_glyph (docs/13 13)"
      exit 1
    fi

`test_only_the_funnel_reads_the_raw_morale_emoji_table` already enforces the same rule as a
subset check. When the lint lands, delete `GLYPH_HANDOFF_PENDING` from that test in the same
change so the two cannot disagree.

---

## 4. M6-A11Y-07 — the combat-log badge's second channel

`game/ui/Badge.gd` (owned here) now draws a one-character glyph in a contrast-chosen ink and
exposes `Badge.glyph_for_verb(verb, by_raider)`. Two edits wire it.

### 4a. `game/ui/Widgets.gd` — `log_row` carries the glyph

old (`:363-365`):

    static func log_row(text: String, tone: Color = Palette.TEXT_MUTED_WARM,
            badge: Color = Palette.INFO, icon: Texture2D = null) -> HBoxContainer:

new:

    static func log_row(text: String, tone: Color = Palette.TEXT_MUTED_WARM,
            badge: Color = Palette.INFO, icon: Texture2D = null,
            glyph: String = "") -> HBoxContainer:

old (`:377-380`):

        var dot := preload("res://game/ui/Badge.gd").new()
        dot.custom_minimum_size = Vector2(18, 18)
        dot.color = badge

new:

        var dot := preload("res://game/ui/Badge.gd").new()
        dot.custom_minimum_size = Vector2(18, 18)
        dot.color = badge
        # docs/13 §13, blocking: colour is never the only signal. An empty glyph
        # keeps the reference's bare disc for a row that has no class.
        dot.glyph = glyph

### 4b. `game/screens/RaidView.gd:891` — pass it

old:

    var row := Widgets.log_row(text, style[0], style[1])

new:

    var row := Widgets.log_row(text, style[0], style[1], null,
        Badge.glyph_for_verb(e.verb, not e.actor_id.is_empty()))

with `const Badge = preload("res://game/ui/Badge.gd")` added to RaidView's preloads.
`by_raider` is `not e.actor_id.is_empty()` — the same expression `_row_style` (`:930`)
already uses to pick INFO over CAUTION, so the two channels agree by construction.

### 4c. `game/screens/Guildhall.gd:296-298` — hue twice on one row

That `log_row` is passed `Palette.morale_color(m)` for BOTH the text tone and the badge, so
the row is hue-only in two places at once. Its text already names the class and the state
word, so the disc just needs a shape. The low-morale list is by definition the bad half, so
pass the sad-face sprite as `log_row`'s existing `icon` argument:

old:

        Palette.morale_color(m), Palette.morale_color(m)))

new:

        Palette.morale_color(m), Palette.morale_color(m),
        Cards.badge_icon("morale_down")))

`Cards` is already preloaded in Guildhall.gd.

### 4d. `art/ref/specs/01-concept1-home-layout.md:100` and `:203-208` are WRONG

Checked by upscaling the actual sprites: `badge_4.png` is an amber **grimacing face** and
`badge_5.png` a green **smiling face**. The spec's list ("up-arrow (level)", "item (loot)")
describes sprites that were never cropped. **Audit item m4t-09 plans to rename these files
by that mistaken list** — do not; rename by what they contain, or leave them.
`game/ui/Cards.gd`'s `BADGE_FOR_KIND` is the only lookup, resolves by name in one place, and
has a `ResourceLoader.exists` guard so a rename degrades to a plain disc instead of crashing
five screens. `game/assets/scenes/camp.json` also names `badge_1`.


---

## 5. Repair-pass addendum (nothing above is withdrawn)

**5a. §4b now covers a SEVENTH verb, at no extra cost.** `Badge.glyph_for_verb` returned `""`
for `Enums.Verb.SYSTEM`, which `RaidView._row_style`'s `_` branch paints DANGER on a wipe
line and TEXT_MUTED otherwise — the loudest row in the log, separated by hue alone.
`Badge.GLYPH_SYSTEM := "="` now exists and the §4b snippet picks it up unchanged, because it
passes `e.verb` straight through. If you have already written the edit, nothing changes; if
you have written "six event classes" anywhere near it, docs/07 §10.1 lists seven.

**5b. §4d has a ruling attached now.** The divergence is not only that spec 01 §4.2's list of
*contents* is wrong. Its class *assignment* sends every morale row to the blue-violet mood
badge (`badge_1`), and `Cards.BADGE_FOR_KIND` ships `badge_0`/`badge_5` instead, because the
reference has no mark for a morale GAIN — its one mood crop is a dizzy face. That is a
departure from the reference concepts and therefore a ruling under the standing user rule;
it is written up as **Q-NEXT+3** in `build/plan/q-a11y-legible.md`. Do not "fix" the map to
match the spec without that ruling, and do not rename the files by the spec's contents list.

**5c. The four screens in §3 are now checked end to end, not only in source.**
`tests/unit/test_a11y_legibility.gd::test_no_town_screen_prints_a_raw_morale_face_under_emoji_free`
mounts Town, Roster, Guildhall, Facilities, Market and RaidPrep with `emoji_free` on and
reads what they print. It is tolerant in one direction only: a screen you FIX simply passes,
so applying any §3 edit will not turn it red — but a sixth screen, or a new route to the raw
table (`Raider.summary()` is sim-side and stays raw), does.
