#!/usr/bin/env bash
# The art pass's gate, run beside tools/verify.sh.
#
# Shoots every screen (and the kit probe) with its fixture and scores it against
# the concept it is derived from (art/ref/specs/11 §8; the target table is
# build/plan/artaudit/00-plan.md §0.3). A screen is done when refdiff says
# INDISTINGUISHABLE; VERY CLOSE is the working target while the scene layers
# and per-class art are still landing.
#
#   tools/with_godot_lock.sh ./tools/diff_all.sh [build/diff]
#
# Prints exactly one line per target (14: the kit probe + the 13 screens) and
# exits 0 when every target rendered; a target that did not render prints FAIL
# and the script exits 1. The numbers are written to <out>/<name>_diff.json by
# refdiff, with a heat map and a side-by-side beside it.
#
# MASKS exist because a screen and its concept can legitimately differ in one
# region. Every screen stands on a BARE plate since the 2026-09-11 directive,
# not on a crop of its concept, so the scene band (Concept 3 screens) or the
# arena viewport (Concept 2 screens) is deliberately different art; scoring it
# would measure the wrong thing, and — see LESSONS "a diff score against the
# reference is a tautology" — scoring a crop of the reference measures nothing.
# What gets graded is the chrome. The masked numbers still move a little when
# a SceneStage lands, because its glow is a screen-space post-process.
#
# THE LOCK: Godot must never run twice in this project at once. The script is
# meant to be wrapped (the grammar above); run bare, it wraps itself. The lock
# is not re-entrant, so it looks for a with_godot_lock.sh ancestor before
# taking it.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

under_godot_lock() {
  local pid=$$
  while [ -n "$pid" ] && [ "$pid" != "0" ] && [ "$pid" != "1" ]; do
    if tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null | grep -q "with_godot_lock"; then
      return 0
    fi
    pid=$(cat "/proc/$pid/ppid" 2>/dev/null) || return 1
  done
  return 1
}
if ! under_godot_lock; then
  exec tools/with_godot_lock.sh "$0" "$@"
fi

source tools/env.sh

OUT="${1:-build/diff}"
mkdir -p "$OUT"

# scene | concept | name | masks | shot flags
#   masks: space-separated x,y,w,h rects excluded from the score; "-" for none;
#   or "region=x,y,w,h" to score ONLY that rect (refdiff --region).
# The pipe is deliberate: res:// paths contain colons.
SCENE_BAND="0,77,1536,649"   # Concept 3 screens: the whole scene band is the bare plate
ARENA="210,77,928,640"       # Concept 2 screens: the arena viewport
TARGETS=(
  "res://tools/probe/Kit.tscn|1|kit|-|--fixture"
  "res://game/screens/Town.tscn|3|town|$SCENE_BAND|--fixture"
  "res://game/screens/Tavern.tscn|3|tavern|$SCENE_BAND|--fixture"
  "res://game/screens/Market.tscn|3|market|$SCENE_BAND|--fixture"
  "res://game/screens/Guildhall.tscn|3|guildhall|$SCENE_BAND|--fixture"
  "res://game/screens/RaiderDetail.tscn|3|raiderdetail|$SCENE_BAND|--fixture"
  "res://game/screens/LoadSave.tscn|3|loadsave|$SCENE_BAND|--fixture"
  "res://game/screens/Settings.tscn|3|settings|$SCENE_BAND|--fixture"
  "res://game/screens/RaidPrep.tscn|2|raidprep|$ARENA|--fixture"
  "res://game/screens/RaidView.tscn|2|raidview|$ARENA|--fixture=raid"
  "res://game/screens/Results.tscn|2|results|$ARENA|--fixture=raid"
  "res://game/screens/AdventureBoard.tscn|1|board|-|--fixture"
  "res://game/screens/Completion.tscn|1|completion|-|--fixture"
  # MainMenu precedes any save, so it is shot bare. It has no dashboard chrome
  # (W3-MENU keeps it frameless): its chrome is the lockup and the menu column,
  # so "chrome-only" scores that region and nothing else — the scene-band mask
  # would hide exactly the pixels a menu change moves.
  "res://game/screens/MainMenu.tscn|3|mainmenu|region=0,300,520,420|-"
)

RC=0
for t in "${TARGETS[@]}"; do
  IFS="|" read -r scene ref name masks flags <<< "$t"
  args=()
  [ "$flags" != "-" ] && args=("$flags")
  if ! timeout 150 "$GODOT" -w --path . --script res://tools/shot.gd -- \
      "$scene" "$OUT/$name.png" 40 1536x1024 "${args[@]}" > "$OUT/$name.log" 2>&1; then
    printf '  \033[31mFAIL\033[0m  %s did not render (see %s/%s.log)\n' "$name" "$OUT" "$name"
    RC=1; continue
  fi
  ARGS=()
  if [[ "$masks" == region=* ]]; then
    ARGS=(--region "${masks#region=}")
  elif [ "$masks" != "-" ]; then
    for m in $masks; do ARGS+=(--mask "$m"); done
  fi
  printf '  %-13s vs %s  ' "$name" "$ref"
  python tools/art/refdiff.py "$OUT/$name.png" "$ref" --out "$OUT" "${ARGS[@]}" \
    | grep -E '"(mae|layout_iou|pct_pixels_within_8)"|verdict' \
    | tr -d '\n ' | sed 's/,/   /g'
  echo
done
exit $RC
