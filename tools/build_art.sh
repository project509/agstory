#!/usr/bin/env bash
# Art pipeline:  tools/aseprite/gen_*.lua  ->  art/src/**/*.aseprite (source of truth)
#                                          +  game/assets/**/*.png     (what Godot loads)
#
#   ./tools/build_art.sh --gen          re-run every generator, writing into the tree
#   ./tools/build_art.sh --check        re-run every generator into build/artcheck/ and
#                                       byte-compare with the tree; exit 1 on any DIFFERS
#                                       or MISSING (verify.sh stage 2b runs this)
#   ./tools/build_art.sh --tags <file>  list the animation tags of one .aseprite
#
# Every generator saves through tools/aseprite/lib.lua (save_png / save_ase /
# write_text), and lib.lua honours `--script-param out=<dir>` as a prefix on
# every path it writes. That is the whole mechanism behind --check: nothing in
# a generator knows it is being checked, and a generator that writes by any
# other route is invisible to the gate — do not add one. Generators are
# deterministic by project rule (no math.random; seeded LCGs only), which is
# what makes a byte comparison meaningful.
#
# Only game/assets/** is gated. The regenerated .aseprite sources are compared
# too and reported as a count, but a differing source does not fail the check:
# the runtime bytes are the contract, the source is the editable record.
#
# RULING (tooling, reversible, 2026-09-13, W0-LIB): the old `build/atlas/`
# export loop (every art/**/*.aseprite packed with --trim into a sheet + JSON)
# is deleted. Nothing under game/ or sim/ ever read it — the generators write
# the runtime PNGs directly and SceneStage cuts strips by the consumer's
# `frame_w` (PIPE-11, PIPE q7). If a consumer for atlas JSON appears, the loop
# comes back next to a reader, not before one.
#
# `$ASEPRITE` (tools/env.sh) is a path relative to the repo root; run from here.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
source tools/env.sh

MODE=""
TAG_FILE=""
for a in "$@"; do
  case "$a" in
    --gen)   MODE="gen" ;;
    --check) MODE="check" ;;
    --tags)  MODE="tags" ;;
    --*)     echo "unknown flag: $a" >&2; exit 2 ;;
    *)       TAG_FILE="$a" ;;
  esac
done
if [ -z "$MODE" ]; then
  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
fi
if [ ! -x "${ASEPRITE:-}" ]; then
  echo "ART BUILD FAILED  Aseprite not found at '${ASEPRITE:-unset}' (tools/env.sh)"
  exit 3
fi

# ---------------------------------------------------------------- --tags
# `--list-tags` only prints when it comes BEFORE the file on Aseprite's
# command line (1.3.7); this wrapper exists so nobody rediscovers that.
if [ "$MODE" = "tags" ]; then
  [ -f "$TAG_FILE" ] || { echo "no such file: $TAG_FILE" >&2; exit 2; }
  "$ASEPRITE" -b --list-tags "$TAG_FILE"
  exit $?
fi

# ---------------------------------------------------------------- generators
# run_generators <out-prefix>: empty prefix writes into the tree.
RC=0
GEN_N=0
run_generators() {
  local prefix="$1" lua
  shopt -s nullglob
  for lua in tools/aseprite/gen_*.lua; do
    printf '  gen  %s\n' "$(basename "$lua")"
    if [ -n "$prefix" ]; then
      OUT_TXT=$("$ASEPRITE" -b --script-param "out=$prefix" --script "$lua" 2>&1)
    else
      OUT_TXT=$("$ASEPRITE" -b --script "$lua" 2>&1)
    fi
    if [ $? -ne 0 ]; then
      printf '  \033[31mFAIL\033[0m %s\n%s\n' "$lua" "$OUT_TXT"; RC=1
    else
      [ "$MODE" = "gen" ] && { echo "$OUT_TXT" | sed 's/^/       /' | grep -v '^\s*$' || true; }
      GEN_N=$((GEN_N+1))
    fi
  done
  shopt -u nullglob
}

if [ "$MODE" = "gen" ]; then
  run_generators ""
  # The UI one-shots (W6-AUD-BIND): the samples are committed and deterministic
  # (seeded per "<hook>:<index>"), so a re-render only moves bytes when PARAMS
  # changed — which is exactly when it should. Same door as the art, no flag
  # of its own. Godot needs `--import` after a real change (tools/audio/README.md).
  if [ -f tools/audio/gen_sfx.py ]; then
    printf '  gen  %s (py)\n' "gen_sfx.py"
    if OUT_TXT=$(python tools/audio/gen_sfx.py --out game/assets/audio/sfx 2>&1); then
      echo "$OUT_TXT" | sed 's/^/       /' | grep -v '^\s*$' || true
      GEN_N=$((GEN_N+1))
    else
      printf '  \033[31mFAIL\033[0m tools/audio/gen_sfx.py\n%s\n' "$OUT_TXT"; RC=1
    fi
  fi
  # The five ambience beds under game/assets/audio/amb (W7-AUD-AMB, BL-138):
  # seeded per "<bed>:<layer>", so the same rule — bytes move only when the
  # generator's BEDS table does. `--import` after a real change.
  if [ -f tools/audio/gen_amb.py ]; then
    printf '  gen  %s (py)\n' "gen_amb.py"
    if OUT_TXT=$(python tools/audio/gen_amb.py --out game/assets/audio/amb 2>&1); then
      echo "$OUT_TXT" | sed 's/^/       /' | grep -v '^\s*$' || true
      GEN_N=$((GEN_N+1))
    else
      printf '  \033[31mFAIL\033[0m tools/audio/gen_amb.py\n%s\n' "$OUT_TXT"; RC=1
    fi
  fi
  echo
  printf 'ART BUILD  generated=%d\n' "$GEN_N"
  if [ "$RC" = "0" ]; then echo "ART BUILD OK"; else echo "ART BUILD FAILED"; fi
  exit $RC
fi

# ---------------------------------------------------------------- --check
CHECK="build/artcheck.$$"   # per-process: concurrent --check runs must not rm -rf each other (W1-VFX handoff §3)
rm -rf "$CHECK"
mkdir -p "$CHECK"
run_generators "$CHECK"
# PY generators carry their own byte-check (they cannot go through lib.lua's out= prefix).
if [ -f tools/art/gen_clouds.py ]; then
  printf '  gen  %s (py)\n' "gen_clouds.py"
  if ! python tools/art/gen_clouds.py --check >/dev/null 2>&1; then
    printf '  \033[31mFAIL\033[0m tools/art/gen_clouds.py --check (run it without --check to see the diff)\n'; RC=1
  fi
fi
# The actor strips (W3-ENEMIES): the same byte gate over game/assets/actors/**.
if [ -f tools/art/gen_actors.py ]; then
  printf '  gen  %s (py)\n' "gen_actors.py"
  if ! python tools/art/gen_actors.py --check >/dev/null 2>&1; then
    printf '  \033[31mFAIL\033[0m tools/art/gen_actors.py --check (run it without --check to see the diff)\n'; RC=1
  fi
fi
# The windmill sails and the patched aerial plate (W4-LIFE): the same byte gate.
if [ -f tools/art/patch_plate.py ]; then
  printf '  gen  %s (py)\n' "patch_plate.py"
  if ! python tools/art/patch_plate.py --check >/dev/null 2>&1; then
    printf '  \033[31mFAIL\033[0m tools/art/patch_plate.py --check (run it without --check to see the diff)\n'; RC=1
  fi
fi
# The UI one-shots under game/assets/audio/sfx (W6-AUD-BIND, AUDIO-05): the same
# byte gate over the samples — 17 AGREE, or a DIFFERS / MISSING / ORPHAN line
# per file and a red stage 2b. A sample is never hand-edited; PARAMS is.
if [ -f tools/audio/gen_sfx.py ]; then
  printf '  gen  %s (py)\n' "gen_sfx.py"
  SFX_TXT=$(python tools/audio/gen_sfx.py --check 2>&1)
  if [ $? -ne 0 ]; then
    printf '  \033[31mFAIL\033[0m tools/audio/gen_sfx.py --check\n'
    echo "$SFX_TXT" | grep -E "DIFFERS|MISSING|ORPHAN|Traceback|Error" | sed 's/^/       /'; RC=1
  else
    printf '       %s\n' "$(echo "$SFX_TXT" | grep 'GEN_SFX ')"
  fi
fi
# The ambience beds under game/assets/audio/amb (W7-AUD-AMB, BL-138): the same
# byte gate — 5 AGREE, a LOOP line per bed (the wrap-around level and seam
# step), DISTINCT across the set — or a red stage 2b. A loop is never
# hand-edited; the BEDS table in gen_amb.py is.
if [ -f tools/audio/gen_amb.py ]; then
  printf '  gen  %s (py)\n' "gen_amb.py"
  AMB_TXT=$(python tools/audio/gen_amb.py --check 2>&1)
  if [ $? -ne 0 ]; then
    printf '  \033[31mFAIL\033[0m tools/audio/gen_amb.py --check\n'
    echo "$AMB_TXT" | grep -E "DIFFERS|MISSING|ORPHAN|LOOP BAD|DUPLICATE|Traceback|Error" | sed 's/^/       /'; RC=1
  else
    printf '       %s\n' "$(echo "$AMB_TXT" | grep 'GEN_AMB ')"
  fi
fi

AGREE=0; DIFFERS=0; MISSING=0
SRC_AGREE=0; SRC_DIFF=0
while IFS= read -r -d '' f; do
  rel="${f#$CHECK/}"
  case "$rel" in
    game/*)
      if [ ! -f "$rel" ]; then
        printf '  \033[31mMISSING\033[0m  %s (generated, not in the tree)\n' "$rel"; MISSING=$((MISSING+1))
      elif cmp -s "$f" "$rel"; then
        AGREE=$((AGREE+1))
      else
        printf '  \033[31mDIFFERS\033[0m  %s\n' "$rel"; DIFFERS=$((DIFFERS+1))
      fi ;;
    *)
      if [ -f "$rel" ] && cmp -s "$f" "$rel"; then SRC_AGREE=$((SRC_AGREE+1)); else SRC_DIFF=$((SRC_DIFF+1)); fi ;;
  esac
done < <(find "$CHECK" -type f -print0 2>/dev/null)

echo
printf 'ART CHECK  generators=%d  runtime files: %d agree  %d DIFFERS  %d MISSING   (sources: %d agree, %d differ — not gated)\n' \
  "$GEN_N" "$AGREE" "$DIFFERS" "$MISSING" "$SRC_AGREE" "$SRC_DIFF"
if [ "$RC" = "0" ] && [ "$DIFFERS" = "0" ] && [ "$MISSING" = "0" ] && [ "$AGREE" -gt 0 ]; then
  rm -rf "$CHECK"
  echo "ART CHECK OK"
  exit 0
fi
printf 'ART CHECK FAILED  (regenerated files kept under %s for diffing; re-run the generator with --gen, or fix it)\n' "$CHECK"
exit 1
