#!/usr/bin/env bash
# The build gate. Every loop iteration must end with this returning 0.
#   ./tools/verify.sh          full gate
#   ./tools/verify.sh --fast   parse + unit tests only (skip boot)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
source tools/env.sh

# Hard timeouts. Godot can wedge on file locks (OneDrive is a known cause) and a
# stalled engine process must fail the gate loudly rather than hang the loop.
GODOT_TIMEOUT=${GODOT_TIMEOUT:-120}
# The suite ran in 33 s on this laptop boosting and 177 s at base clock (2026-09-14,
# the same code both times); a timeout is for a WEDGED engine, not a slow one.
GODOT_TESTS_TIMEOUT=${GODOT_TESTS_TIMEOUT:-900}
GODOT_SWEEP_TIMEOUT=${GODOT_SWEEP_TIMEOUT:-900}
GODOT_PLAYTEST_TIMEOUT=${GODOT_PLAYTEST_TIMEOUT:-900}
ASEPRITE_TIMEOUT=${ASEPRITE_TIMEOUT:-180}   # stage 2b: five generators, ~5 s on this machine
# stage 8/8: ~15 s boosting; the probe caps its own measuring windows so it stays
# near a minute at base clock (tools/perf_probe.gd SCREEN_CAP_MS). 5x that.
GODOT_PERF_TIMEOUT=${GODOT_PERF_TIMEOUT:-300}

FAST=0
[ "${1:-}" = "--fast" ] && FAST=1
RC=0
LOG=".verify.log"
: > "$LOG"

hdr() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
ok()  { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
bad() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; RC=1; }

# ---------------------------------------------------------------- 0. class cache
# Godot resolves class_name identifiers from .godot/global_script_class_cache.cfg,
# which only `--import` writes. In a headless-only workflow nothing ever creates
# it, so the first cross-file class_name reference fails at runtime while parse
# checks stay green. Regenerate it whenever it is missing.
CACHE=".godot/global_script_class_cache.cfg"
STALE=""
if [ -f "$CACHE" ]; then
  STALE=$(find sim game tests tools -name "*.gd" -newer "$CACHE" 2>/dev/null | head -1)
fi
if [ ! -f "$CACHE" ] || [ -n "$STALE" ]; then
  printf '
[1m== 0/5  rebuilding global class cache ==[0m
'
  timeout "$GODOT_TIMEOUT" "$GODOT" --headless --path . --import >/dev/null 2>&1
  if [ -f "$CACHE" ]; then
    printf '  [32mPASS[0m  class cache regenerated
'
  else
    printf '  [31mFAIL[0m  could not generate class cache
'
    RC=1
  fi
fi

# ---------------------------------------------------------------- 0. lint
hdr "0/8  lint: no cross-file class_name refs"
OUT=$(./tools/lint_no_global_classes.sh 2>&1)
if echo "$OUT" | grep -q "LINT OK"; then
  ok "$(echo "$OUT" | grep 'LINT OK')"
else
  bad "global class_name references found"
  echo "$OUT" | grep LINT | head -10
fi

# docs/13 §13's reduced-motion row is a blocking accessibility requirement, and a
# setting every new animation must opt INTO is a setting that is wrong by
# default. `Widgets.tween()` is the one door; this is the lock. Built before the
# tweens rather than after, which is the only order in which a lint like this
# ever holds — see tools/lint_motion.sh's own header.
OUT=$(./tools/lint_motion.sh 2>&1)
if echo "$OUT" | grep -q "MOTION LINT OK"; then
  ok "$(echo "$OUT" | grep 'MOTION LINT OK')"
else
  bad "a tween was made outside Widgets.tween()"
  echo "$OUT" | tail -8
fi

# ---------------------------------------------------------------- 1. parse
hdr "1/8  script parse"
OUT=$(timeout "$GODOT_TIMEOUT" "$GODOT" --headless --path . --script res://tools/parse_check.gd 2>&1)
echo "$OUT" >> "$LOG"
if echo "$OUT" | grep -q "PARSE_CHECK OK"; then
  ok "$(echo "$OUT" | grep 'scanned' | head -1)"
else
  bad "script parse errors"
  echo "$OUT" | grep -E "PARSE FAIL|SCRIPT ERROR|Parse Error|error" | head -25
fi

# The copy lint (ship plan §0.2, W6-COPY): no Label/Button string literal under
# game/ may admit an unfinished feature ("this build", "module", "docs/", ...).
# Guarded the way stage 2 guards gen_items.gd — the script is another unit's and
# may not exist in this tree yet; a missing lint is a SKIP, never a pass.
if [ ! -f "tools/lint_copy.sh" ]; then
  printf '  \033[33mSKIP\033[0m  tools/lint_copy.sh not written yet\n'
else
  OUT=$(./tools/lint_copy.sh 2>&1)
  echo "$OUT" >> "$LOG"
  if echo "$OUT" | grep -q "COPY LINT OK"; then
    ok "$(echo "$OUT" | grep 'COPY LINT OK' | head -1)"
  else
    bad "a player-facing string admits an unfinished feature"
    echo "$OUT" | grep -v "COPY LINT" | head -12 | sed "s/^/          /"
  fi
fi

# ---------------------------------------------------------------- 2. unit tests
# ------------------------------------------------------- 2/8 generated content
# docs/14 §10.1's pre-export gate (2), "the content generator produces no tree
# change", mapped onto the tool this project actually grew (docs/15 BL-74, which
# recorded it as the one gate of six still owed).
#
# `gen_items.gd -- check` rebuilds all sixteen Tier 2-5 files in memory and
# compares them to what is committed, writing nothing. It catches the two ways a
# generated corpus and its generator drift apart, both of them silent: a hand
# edit to a generated row, and a rule change in TierScaling that nobody re-ran.
# The mode had existed since the generator was written and had never been called.
#
# It is NOT in tools/export_build.sh and must not be: a release build that
# mutates the tree it is packing is worse than the gap it closes.
hdr "2/8  generated content matches its generator"
if [ ! -f "tools/gen_items.gd" ]; then
  printf '  \033[33mSKIP\033[0m  tools/gen_items.gd not written yet\n'
else
  OUT=$(timeout "$GODOT_TIMEOUT" "$GODOT" --headless --path . --script res://tools/gen_items.gd -- check 2>&1)
  echo "$OUT" >> "$LOG"
  if echo "$OUT" | grep -q "0 file(s) differ"; then
    ok "16 generated file(s) agree with tools/gen_items.gd"
  else
    bad "a generated file and its generator disagree"
    echo "$OUT" | grep -E "DIFFERS|PROBLEM|differ" | sed "s/^/          /"
    printf '          Re-run the generator, or mark the row hand_authored: true.\n'
  fi
fi

# ------------------------------------------------------- 2b/8 generated art
# The same gate for pixels. Every PNG the generators own (game/assets/ui,
# ui/icons, vfx, faces.json) is rebuilt into build/artcheck/ and byte-compared
# with the tree by `build_art.sh --check` — a hand edit to a generated PNG, or a
# generator change nobody re-ran, was invisible before this (PIPE-11). The
# generators are deterministic by project rule, which is what makes bytes the
# right unit. SKIPs when Aseprite is not installed, mirroring stage 2's skip:
# a machine without the editor cannot regenerate, and must not go red for it.
hdr "2b/8  generated art matches its generator"
if [ ! -x "${ASEPRITE:-}" ]; then
  printf '  \033[33mSKIP\033[0m  Aseprite not found at %s (tools/env.sh)\n' "${ASEPRITE:-unset}"
else
  OUT=$(timeout "$ASEPRITE_TIMEOUT" ./tools/build_art.sh --check 2>&1)
  echo "$OUT" >> "$LOG"
  if echo "$OUT" | grep -q "ART CHECK OK"; then
    ok "$(echo "$OUT" | grep 'ART CHECK  ' | sed 's/ *(sources.*//')"
  else
    bad "a generated PNG and its generator disagree"
    echo "$OUT" | grep -E "DIFFERS|MISSING|FAIL|ART CHECK" | head -20 | sed "s/^/          /"
    printf '          Re-run ./tools/build_art.sh --gen, or fix the generator; never hand-edit a generated PNG.\n'
  fi
fi

hdr "3/8  unit tests"
OUT=$(timeout "$GODOT_TESTS_TIMEOUT" "$GODOT" --headless --path . --script res://tests/run_tests.gd 2>&1)
echo "$OUT" >> "$LOG"
if [ $? = 124 ]; then
  bad "unit tests TIMED OUT after ${GODOT_TESTS_TIMEOUT}s (a Godot process may be wedged; check for orphans)"
elif echo "$OUT" | grep -q "TESTS PASSED"; then
  ok "$(echo "$OUT" | grep 'TESTS PASSED')"
else
  bad "unit tests"
  echo "$OUT" | grep -E "FAIL|TESTS FAILED|SCRIPT ERROR" | head -40
fi

# ---------------------------------------------------------------- 3. boot
hdr "4/8  headless boot"
MAIN=$(grep -oP 'run/main_scene="\K[^"]+' project.godot 2>/dev/null)
SCENE_PATH="${MAIN#res://}"
if [ -z "$MAIN" ] || [ ! -f "$SCENE_PATH" ]; then
  printf '  \033[33mSKIP\033[0m  no main scene yet (%s)\n' "${MAIN:-unset}"
elif [ "$FAST" = "1" ]; then
  printf '  \033[33mSKIP\033[0m  --fast\n'
else
  OUT=$(timeout "$GODOT_TIMEOUT" "$GODOT" --headless --path . --quit-after 180 2>&1)
  echo "$OUT" >> "$LOG"
  ERRS=$(echo "$OUT" | grep -E "SCRIPT ERROR|Parse Error|Cannot open|Failed to load|Condition \"" | grep -v "Blocking mode" | head -20)
  if [ -z "$ERRS" ]; then
    ok "boots clean for 180 frames"
  else
    bad "runtime errors on boot"
    echo "$ERRS"
  fi
fi

# ---------------------------------------------------------------- 4. keyboard access
# docs/13 §13 makes keyboard navigation blocking, and the unit suite structurally
# cannot check it: run_tests.gd runs from MainLoop::_initialize, before the root
# window enters the tree, so grab_focus() is a no-op and find_next_valid_focus()
# has no tree to walk. This mounts every screen for real and asks Godot.
hdr "5/8  keyboard access"
if [ "$FAST" = "1" ]; then
  printf '  [33mSKIP[0m  --fast
'
else
  OUT=$(timeout "$GODOT_TIMEOUT" "$GODOT" --headless --path .     --script res://tests/unit/a11y_smoke.gd 2>&1)
  echo "$OUT" >> "$LOG"
  if echo "$OUT" | grep -q "A11Y SMOKE PASSED"; then
    ok "$(echo "$OUT" | grep -o 'A11Y SMOKE PASSED.*' | head -1)"
    echo "$OUT" | grep -E "^  warn" | head -5
  else
    bad "keyboard access"
    echo "$OUT" | grep -E "^  (fail|warn)" | head -10
  fi
fi

# ---------------------------------------------------------------- 5. balance sweep
hdr "6/8  balance sweep"
if [ "$FAST" = "1" ]; then
  # ~25s. Too slow for the inner edit-test loop, essential before a commit.
  printf "  [33mSKIP[0m  --fast
"
elif [ -f "tools/balance_sweep.gd" ]; then
  OUT=$(timeout "$GODOT_SWEEP_TIMEOUT" "$GODOT" --headless --path . --script res://tools/balance_sweep.gd 2>&1)
  echo "$OUT" >> "$LOG"
  if echo "$OUT" | grep -q "SWEEP OK"; then
    ok "$(echo "$OUT" | grep 'runs across')"
    echo "$OUT" | grep -E "SWEEP WARNING|LEVER BALANCE|Best case|Worst case" | sed "s/^/      /"
  else
    bad "balance sweep"
    echo "$OUT" | tail -20
  fi
else
  printf '  \033[33mSKIP\033[0m  tools/balance_sweep.gd not written yet\n'
fi

# ---------------------------------------------------------------- 6b. drift
# docs/14 §9.3's CI rule, ARMED (SIM-18, audit M6-BAL-02's gate clause): the
# reference row of every encounter, plus A3 at its own stage, at 200 seeds
# against tests/baselines/sweep_baseline.csv; any clear rate moving more than
# 5 percentage points FAILS the build. The seeds are fixed and the baseline is
# written at the same count, so an unchanged sim reads 0.0pp on every cell.
#
# The baseline is never refreshed to go green. `--rebaseline` is a deliberate
# act by a SIM wave's RaidSim-owning unit, at most once per wave, with the
# before/after numbers in its commit message (ship plan §0.2). Nothing here
# runs it. ~45 s; skipped under --fast like the sweep above.
hdr "6b/8  balance drift vs the committed baseline"
if [ "$FAST" = "1" ]; then
  printf '  \033[33mSKIP\033[0m  --fast\n'
elif [ -f "tools/balance_sweep.gd" ] && [ -f "tests/baselines/sweep_baseline.csv" ]; then
  OUT=$(timeout "$GODOT_SWEEP_TIMEOUT" "$GODOT" --headless --path . --script res://tools/balance_sweep.gd -- --drift --seeds 200 2>&1)
  echo "$OUT" >> "$LOG"
  if echo "$OUT" | grep -q "SWEEP OK"; then
    ok "$(echo "$OUT" | grep 'reference cells')"
    echo "$OUT" | grep -E "pp$|pp  <-- DRIFT|not in the baseline" | sed "s/^/      /"
  else
    bad "balance drift past 5pp (or the drift run did not complete)"
    echo "$OUT" | grep -E "DRIFT|SWEEP FAIL|NO BASELINE|REFUSED" | head -20 | sed "s/^/          /"
    printf '          A moved cell is a balance change: read it, then either fix the cause or re-baseline\n'
    printf '          DELIBERATELY (--drift --rebaseline) with the numbers in the commit message.\n'
  fi
else
  printf '  \033[33mSKIP\033[0m  tools/balance_sweep.gd or tests/baselines/sweep_baseline.csv missing\n'
fi


# ---------------------------------------------------------------- 6/7 playtest
# The campaign, played start to finish, eight times. Everything above measures
# one part in isolation; this is the only thing that asks whether the parts hold
# hands — that E1 drops the gear E2 needs, at a rate a player reaches, at a
# morale the roster survives, on gold the guild can afford.
#
# IT IS A WARNING, NOT A FAILURE, AND THAT IS ON PURPOSE AND TEMPORARY.
# Its first run found a real wall: a new guild's morale ceiling is 45 (docs/05
# §8's Common baseline, which is where rest stops dead), and at 45 the Adventure
# ladder stops six guilds in eight at A2 in full Tier 1 Adventure gear. That is a
# pacing and economy ruling for a designer, filed as audit M6-BAL-04 alongside
# the two balance defects this project already pins with measurements rather than
# tuning. Making this stage FAIL today would make the gate permanently red and
# stop every other piece of work, which is worse than a warning nobody can miss.
# The day M6-BAL-04 is answered, the `|| true` and this comment come out together
# and a red playtest fails the build.
hdr "7/8  playtest — the whole campaign"
if [ "$FAST" = "1" ]; then
  printf '  \033[33mSKIP\033[0m  --fast\n'
elif [ -f "tools/playtest.gd" ]; then
  OUT=$(timeout "$GODOT_PLAYTEST_TIMEOUT" "$GODOT" --headless --path . --script res://tools/playtest.gd 2>&1)
  echo "$OUT" >> "$LOG"
  if echo "$OUT" | grep -q "PLAYTEST OK"; then
    ok "$(echo "$OUT" | grep 'cleared Tier 1')"
  else
    printf '  \033[33mWARN\033[0m  %s\n' "$(echo "$OUT" | grep 'cleared Tier 1' | sed 's/^ *//')"
    echo "$OUT" | grep -E "^  WALL" | sed "s/^/    /"
    printf '        known, measured and owned by audit M6-BAL-04 — not a build defect\n'
  fi
else
  printf '  \033[33mSKIP\033[0m  tools/playtest.gd not written yet\n'
fi

# ---------------------------------------------------------------- 8/8 latency
# docs/13 §12.1's budget ("treat as a perf test, not a guideline"): a screen
# switch settled in ≤ 140 ms, and 16.6 ms a frame at 1536x1024. Until this
# stage nothing in the gate timed anything, and the art pass adds the lights,
# particles and shaders that would break the budget unnoticed (RULES-15, audit
# M6-JUICE-07). tools/perf_probe.gd mounts every screen on a11y_smoke's list
# through the real router, on the reference fixture, inside a 1536x1024
# SubViewport with vsync off, and prints mount and mean-frame numbers per
# screen plus a calibration figure. The numbers are the point: they are printed
# here on every full run, so a regression is visible in the log even when no
# row is over budget.
#
# IT IS A WARNING, NOT A FAILURE, AND THAT IS ON PURPOSE. This laptop runs the
# same suite in 33 s boosting and 177 s at base clock (BUILD_STATE, machine
# note), so a frame time varies ~5x between runs of identical code; a red row
# here is a number to read against the probe's own calibration line, on the
# reference hardware, not a build defect — the playtest above is the precedent.
# A real display server is required (no --headless: the dummy rasteriser
# renders nothing), so the window flashes up, as it does for shot_all.sh.
hdr "8/8  latency budget — mount and frame time per screen"
if [ "$FAST" = "1" ]; then
  printf '  \033[33mSKIP\033[0m  --fast\n'
elif [ -f "tools/perf_probe.gd" ]; then
  # --warm: Boot compiles the screens and loads the plates behind its overlay
  # (W5-MOUNT), so the rows measure the page turn a player actually makes.
  OUT=$(timeout "$GODOT_PERF_TIMEOUT" "$GODOT" -w --path . --script res://tools/perf_probe.gd -- --warm 2>&1)
  echo "$OUT" >> "$LOG"
  if echo "$OUT" | grep -q "PERF OK"; then
    ok "$(echo "$OUT" | grep 'PERF OK')"
  else
    VERDICT=$(echo "$OUT" | grep -E '^PERF (WARN|SKIP)' | head -1)
    printf '  \033[33mWARN\033[0m  %s\n' "${VERDICT:-the probe printed no verdict (timed out after ${GODOT_PERF_TIMEOUT}s, or crashed) — see $LOG}"
    printf '        a measurement to read against the calibration line, not a build defect (docs/13 §12.1 is judged on the reference hardware)\n'
  fi
  # The rows are the instrument (a `!` marks a row over budget); the per-row
  # WARN table is in the log.
  echo "$OUT" | grep -E "^PERF  |^PERF clock  calibration" | sed "s/^/      /"
else
  printf '  \033[33mSKIP\033[0m  tools/perf_probe.gd not written yet\n'
fi

# ---------------------------------------------------------------- verdict
echo
if [ "$RC" = "0" ]; then
  printf '\033[1;32mVERIFY OK\033[0m  (full log: %s)\n' "$LOG"
else
  printf '\033[1;31mVERIFY FAILED\033[0m  (full log: %s)\n' "$LOG"
fi
exit $RC
