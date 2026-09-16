#!/usr/bin/env bash
# The copy lint (build/plan/ship/00-plan.md §0.2, W6-COPY): no string literal a
# player could read under game/ may admit an unfinished feature.
#
# WHY. The designer's wave-6 directive (LOOP's "Unfinished-feature copy" table,
# C1-C31): a dozen screens printed sentences about the BUILD — "Disabled in this
# build.", "wishlists with the loot module", "the type pass ships the second
# family", a credits paragraph citing docs/15 and an audit id — to a player who
# has no build, no module, no docs and no audit. Every one was reworded to an
# in-world sentence or hidden behind the feature it was waiting for. This file
# is what stops them coming back: it greps every double-quoted literal under
# game/ for the words that only a developer says.
#
# THE RULE, exactly as tests/unit/test_copy_lint.gd re-implements it in-process
# (so `RUN_TESTS_ONLY=copy_lint` catches a new hit in seconds):
#   - every *.gd under game/, line by line;
#   - a line whose first non-blank character is `#` is a comment and is skipped;
#   - the line is cut at the first `#` outside double quotes (a trailing comment);
#   - a line that calls push_error( / push_warning( / print( / printerr( /
#     printt( / assert( is developer output, never a Label, and is skipped;
#   - every "…" literal left on the line is lower-cased and searched for each
#     WORD below; a literal containing one is a hit;
#   - a hit is allowed only if ALLOW below names its file AND a fragment of the
#     literal. An ALLOW entry that matches nothing is STALE and fails the lint
#     too: the allow-list is the only place these strings may live, so an entry
#     with no string behind it is a lie about the tree (W10-DELETE removes the
#     entry with the string).
#
# THE WORDS are §0.2's list verbatim. "arrives with" catches C12/C13's
# "Backstories arrive with the Tavern"; the Tavern's own "Linda arrives with
# Worn Leggings" is in-world and allow-listed by name.
#
# THE ALLOW-LIST is keyed by file and a fragment of the literal rather than by
# line number, because other units edit these files in the same wave and a
# line number is stale the moment someone inserts a line above it. Every entry
# says why it is here:
#   C3/C4/C5  the `screen_exists` fall-throughs — never shown (all 13 scenes
#             exist; ScreenRouter guards); DELETED with their guards by
#             W10-DELETE, which also deletes these entries.
#   C6        the boot-failure sentence (no GameSettings autoload) — never
#             reachable in an export; KEEP per LOOP's table.
#   save      docs/14 §7.3's migration notes — reachable only with a save from
#             ANOTHER build naming content this one no longer has; "this build"
#             is the honest word there. W7-SAVE freezes the format.
#   tavern    "arrives with %s" — a recruit's gear, in-world, pinned by
#             tests/unit/test_tavern.gd.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

# WORDS-BEGIN
WORDS=(
  "this build"
  "this version"
  "not built"
  "not written"
  "module"
  "canon"
  "fixture"
  "audit"
  "docs/"
  "export build"
  "type pass"
  "arrive with"
  "arrives with"
  "sign-off"
  "name pending"
)
# WORDS-END

# ALLOW-BEGIN  (path|fragment of the literal)
ALLOW=(
  "game/screens/Town.gd|Not built in this version yet."
  "game/screens/Town.gd|Raid prep is not in this version yet."
  "game/screens/AdventureBoard.gd|Not built in this version yet."
  "game/screens/AdventureBoard.gd|Raid prep is not in this version yet."
  "game/screens/Guildhall.gd|Not built in this version yet."
  "game/screens/Market.gd|Not built in this version yet."
  "game/screens/RaiderDetail.gd|Not built in this version yet."
  "game/screens/Roster.gd|Not built in this version yet."
  "game/screens/Settings.gd|Not built in this version yet."
  "game/screens/Settings.gd|The guild slots are not in this version yet."
  "game/screens/Settings.gd|Settings are unavailable in this build."
  "game/screens/MainMenu.gd|The town is not built in this version yet."
  "game/screens/MainMenu.gd|The guild slots are not in this version yet."
  "game/screens/MainMenu.gd|Settings are not in this version yet."
  "game/ui/Frame.gd|Not built in this version yet."
  "game/ui/Cards.gd|Not built in this version yet."
  "game/core/GameState.gd|this build reads up to"
  "game/core/GameState.gd|is not declared (docs/14"
  "game/core/SaveGame.gd|which this build no longer has"
  "game/screens/Tavern.gd|arrives with %s"
)
# ALLOW-END

RC=0
HITS=0
declare -A USED

words_joined=$(printf '%s\x1f' "${WORDS[@]}")

# One awk pass per file prints "line<TAB>word<TAB>literal" for every hit.
scan() {
  awk -v words="$words_joined" '
    BEGIN { nw = split(words, W, "\x1f"); if (W[nw] == "") nw-- }
    {
      line = $0
      s = line; sub(/^[ \t]+/, "", s)
      if (s ~ /^#/) next
      out = ""; inq = 0
      for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)
        if (c == "\"") inq = !inq
        if (c == "#" && !inq) break
        out = out c
      }
      if (out ~ /push_error\(|push_warning\(|printerr\(|printt\(|print\(|assert\(/) next
      rest = out
      while (match(rest, /"([^"\\]|\\.)*"/)) {
        lit = substr(rest, RSTART + 1, RLENGTH - 2)
        rest = substr(rest, RSTART + RLENGTH)
        low = tolower(lit)
        for (k = 1; k <= nw; k++) {
          if (index(low, W[k]) > 0) { printf "%d\t%s\t%s\n", NR, W[k], lit; break }
        }
      }
    }' "$1"
}

while IFS= read -r -d '' f; do
  rel="${f#./}"
  found=$(scan "$f")
  [ -z "$found" ] && continue
  while IFS=$'\t' read -r ln word lit; do
    allowed=""
    for entry in "${ALLOW[@]}"; do
      path="${entry%%|*}"
      frag="${entry#*|}"
      if [ "$path" = "$rel" ] && [[ "$lit" == *"$frag"* ]]; then
        allowed="$entry"
        break
      fi
    done
    if [ -n "$allowed" ]; then
      USED["$allowed"]=1
      continue
    fi
    printf '  \033[31mCOPY\033[0m %s:%s says "%s" — %s\n' "$rel" "$ln" "$word" "$lit"
    HITS=$((HITS + 1))
    RC=1
  done <<< "$found"
done < <(find game -name "*.gd" -type f -print0 2>/dev/null)

STALE=0
for entry in "${ALLOW[@]}"; do
  if [ -z "${USED[$entry]:-}" ]; then
    printf '  \033[31mSTALE\033[0m allow-list entry matches nothing: %s\n' "$entry"
    STALE=$((STALE + 1))
    RC=1
  fi
done

if [ "$RC" = "0" ]; then
  echo "COPY LINT OK  no player-facing string under game/ admits an unfinished feature (ship plan §0.2; ${#ALLOW[@]} allow-listed fall-throughs, all present)"
else
  echo "COPY LINT FAILED  $HITS hit(s), $STALE stale allow-list entr(y/ies)"
  echo "    A player has no build, no module, no docs and no audit. Say the"
  echo "    in-world thing, or hide the control behind the feature it waits for."
  echo "    A string the build genuinely cannot avoid goes on ALLOW in this file"
  echo "    with its reason — and comes off it the day the string goes."
fi
exit $RC
