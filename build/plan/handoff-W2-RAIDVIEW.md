# Handoff — W2-RAIDVIEW (key `W2-RAIDVIEW`)

Edits needed in files this unit does not own. Shape: `## N. <path>:<line>` then an `old:`
block and a `new:` block, one edit per heading (Palette.gd/Widgets.gd/Cards.gd use TABS). Nothing
here is applied by the unit. Observations (no edit) are labelled as such.

Rewritten clean on the repair pass (review F5: the first copy carried double-encoded UTF-8).

## 1. game/ui/Palette.gd:77

COMBAT-07's interim hit flash and COMBAT-16's boss flash are docs/12 §5.2's `#FFF6DC`; no token
carries it, so RaidView flashes with `Palette.TEXT_BODY` (F7F1E1) for now. Add the token (never a hex
in a screen; W3-RAIDVIEW2 / W2-STAGE2's `hit()` then read it).

old:
```
const CRIT := Color("F1750E")             ## critical damage numbers
```
new:
```
const CRIT := Color("F1750E")             ## critical damage numbers
const HIT_FLASH := Color("FFF6DC")        ## docs/12 §5.2: the one-frame hit flash on a struck figure
```

## Observation (no edit) — W3-KIT2: the damage number's z-order belongs in the kit

RaidView sets `z_index = 1` on every `Widgets.damage_number` it places, because a number (600 ms) spawned
after a joke bubble (2.4 s hold) in the same `Overlay` was drawn UNDER the plate and never seen
(build/shots/W2RV_adv10.png, first take). `Widgets.damage_number` could set it once (the pool resets
modulate/scale/visible, not z_index) so every caller gets it — W3-KIT2 owns Widgets.gd.

## Observation (no edit) — W2-STAGE2 / W3-RAIDVIEW2: three joke bubbles in ten lines overlap each other

`say_at` keeps one plate per SPEAKER; three mistakes by three raiders inside one 2.4 s hold stack three
196px plates over a 64px-pitch formation (W2RV_adv10.png). RaidView calls the stage once per joke and
has no door to drop another speaker's plate. If the stage wants "one bubble at a time", `say_at` could
retire the previous speaker's plate when a new one lands (a stage rule, not a screen's).

## Observation (no edit) — W3-KIT2: `Widgets.reasoned` sets the glyph whether or not there is a reason

`Widgets.gd:624-626` puts the padlock on the button whenever `glyph` is non-null, before the reason is
looked at, so an ENABLED control handed the lock wears it (review F2). RaidView now passes the glyph
only while the skip is locked; the kit could gate the icon on `not reason.is_empty()` so every caller
gets the same rule.

## Withdrawn — W0-GATE: the "raid-advanced tile cannot show a damage number at 40 frames" note

The first handoff said the sheet's `RaidView_10` tile is taken after every number has faded. The
reviewer's 40-frame `--advance=10` shot (build/shots/review-W2-RAIDVIEW-adv10.png) shows both "-30"s
and the "-4", 2px higher than at 6 frames — the tween runs on the shot's frame clock, not on wall time.
Nothing for W0-GATE to do.
