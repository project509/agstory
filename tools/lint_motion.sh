#!/usr/bin/env bash
# Every tween goes through `Widgets.tween()`, and every morale glyph through
# `Cards.morale_glyph()`. Two accessibility options, one door each.
#
# WHY A LINT AND NOT A CONVENTION. docs/13 §13 makes reduced motion a blocking
# accessibility requirement, and for months it had exactly ONE consumer —
# `SceneStage`, which stops its own flames — while the M6 juice items were queued
# to add tweens to the screen change, the wipe sequence, the chalk slots and the
# stamp badges. Every one of those would have had to remember a setting nobody
# would have noticed them forgetting: an animation that ignores reduced motion
# looks exactly like an animation that respects it, unless you are the person the
# setting is for. A setting that each new call site must opt INTO is a setting
# that is wrong by default.
#
# So the gate is built before the tweens rather than after. It runs against a
# codebase with zero `create_tween()` calls outside the one sanctioned helper,
# and its whole job is to still be true in six commits' time.
#
# IT ALSO GUARDS THE OTHER ACCESSIBILITY OPTION THAT HAD ONE CONSUMER. docs/13
# §13's emoji-free row — "Replaces morale glyphs with a 10-step monochrome pip
# figure. The integer and state word are unaffected" — was implemented in
# `GameSettings.morale_glyph()` and read by one screen out of eight; the other
# seven reached straight past it to `Enums.MORALE_BAND_EMOJI`, so turning the
# option on changed one panel and left emoji on the Roster, the raid prep, the
# Market and the Guildhall's low-morale list. Same failure shape as the tween
# rule, same fix: one door, and a lint on the door. Two rules in one file because
# they are one idea — an accessibility option is only as live as its least
# careful call site.
#
# THE SHAPE OF THE TWEEN RULE. `Widgets.tween(node)` is the only place allowed to
# call `create_tween()`. The duration still comes from
# `GameSettings.motion_duration()` at the call site, because only the caller knows
# which row of docs/13 §12.2 it means and whether §13's stamp exception applies —
# a 0.0-duration tween completes on the next frame and still applies its final
# value, which is what lets a call site have no branch and still be correct.
#
# `AnimationPlayer` and `AnimatedSprite2D` are NOT covered here: they are the
# world layer's (doc 12's), `SceneStage` already consults both settings for them,
# and a test pins that. docs/15 BL-75 rules which layer §13's three-changes-a-
# second rule governs.
#
# A THIRD DOOR, SAME SHAPE (KIT-10, W4-HYGIENE): every colour under game/ is a
# `Palette` role, never a hex. docs/13 §3 ("screens name a role, never a hex")
# had been the rule for as long as the palette existed, and 45 `Color("…")`
# literals had accumulated across seven files anyway — a retune of the palette
# meant editing all seven, and the Tavern's selected-card rim could not be
# reused by the Roster because it was a number in a screen. W1-CHROME moved
# every literal into Palette.gd as a named role; this line is what stops them
# coming back. `Color("` is the pattern (hex-string constructors are the only
# form a stray literal takes here — `Color(r, g, b)` arithmetic on a role, as
# `SceneStage` does for a light's tint, stays legal). Palette.gd is the one
# file allowed to name a hex; tools/ (the kit probes, the shot instrument) is
# outside the rule because nothing there ships.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

RC=0
HITS=0

# Comments are stripped before every check: a docstring explaining a rule is
# documentation, not a violation, and flagging it would train people to ignore
# the lint — the same reasoning tools/lint_no_global_classes.sh already uses.
check() {
  local pattern="$1" allowed="$2" what="$3" dirs="$4"
  local f rel found line
  while IFS= read -r -d '' f; do
    rel="${f#./}"
    case " $allowed " in *" $rel "*) continue;; esac
    found=$(sed 's/#.*$//' "$f" | grep -nE "$pattern" 2>/dev/null || true)
    [ -z "$found" ] && continue
    while IFS= read -r line; do
      printf '  \033[31mLINT\033[0m %s:%s %s\n' "$rel" "${line%%:*}" "$what"
      HITS=$((HITS + 1))
    done <<< "$found"
    RC=1
  done < <(find $dirs -name "*.gd" -type f -print0 2>/dev/null)
}

check 'create_tween\(' \
  "game/ui/Widgets.gd" \
  "calls create_tween() directly" \
  "game sim tools"

check 'MORALE_BAND_EMOJI|morale_band_emoji' \
  "game/ui/Cards.gd game/core/GameSettings.gd" \
  "reads the morale emoji table directly — use Cards.morale_glyph(self, morale)" \
  "game"

check 'Color\("' \
  "game/ui/Palette.gd" \
  "names a hex colour — add a role to game/ui/Palette.gd and use it (docs/13 §3, KIT-10)" \
  "game sim"

if [ "$RC" = "0" ]; then
  echo "MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)"
  echo "                and every colour under game/ is a Palette role (docs/13 §3)"
else
  echo "MOTION LINT FAILED  $HITS call site(s)"
  echo "    Tweens: use Widgets.tween(node) with a duration from"
  echo "    GameSettings.motion_duration(ms) — a 0.0 duration still applies the"
  echo "    final value, so the call site needs no branch."
  echo "    Morale glyphs: use Cards.morale_glyph(self, morale), which consults"
  echo "    the emoji_free option; reading Enums.MORALE_BAND_EMOJI skips it."
  echo "    Colours: a Color(\"hex\") outside Palette.gd is a retune nobody can"
  echo "    find — name the role in Palette.gd and reference it."
fi
exit $RC
