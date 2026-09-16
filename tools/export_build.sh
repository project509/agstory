#!/usr/bin/env bash
# The release export: gates -> import -> export -> pck hygiene -> LAUNCH the
# thing that was built. docs/14 §10.1.
#
#   ./tools/export_build.sh                gates, export, hygiene, launch check
#   ./tools/export_build.sh --skip-gates   skip ./tools/verify.sh (a re-export)
#   ./tools/export_build.sh --clean        wipe build/exports/ first
#   ./tools/export_build.sh --linux        also export the Linux preset
#   ./tools/export_build.sh --dev          export past the pending-content gate
#                                          AND the provenance gate, and stamp
#                                          the result NOT SHIPPABLE
#
# WHY THE LAUNCH CHECK: `--export-release` returns 0 for a build that cannot
# boot. It packs whatever it was given; a missing scene, a broken autoload or a
# resource that only the editor could resolve all survive the export and die on
# the player's machine. So step 7 runs the exported console wrapper headless and
# reads its stdout with the same grep verify.sh's boot step uses. An export that
# is not launched has not been verified, only produced.
#
# WHY A FRESH PROFILE (SHIP-05, W6-SHEETS): the launch check used to boot against
# whatever `%APPDATA%/Godot/app_userdata/A Guild Story/` already held on the
# build machine — the developer's settings.cfg and saves — so the first-run path
# (no settings file, no saves, Continue disabled) was never the one exercised.
# Godot 4.7.1 has no `--user-data-dir` flag (`$GODOT --help` lists none; the
# only "user" option is `--`), so the empty profile is made the way the engine
# resolves `user://` on each platform: `%APPDATA%` on Windows, `$XDG_DATA_HOME`
# on Linux, both pointed at a temp directory for the launch only. The check
# then asserts the engine CREATED `Godot/app_userdata/A Guild Story/` under
# that temp root, because a redirect nothing honoured would boot the developer's
# profile again and look identical. Step 7b boots a second fresh profile with
# tests/fixtures/saves/v10_sample.json copied into its saves/ — the packed
# build's main menu must read a six-versions-old header without an error. The
# game migrates on Continue, not at boot (SaveGame.load_into), so there is no
# migration line to grep; the chain itself is proven in the tree by
# tests/unit/test_savegame.gd on every fixture, and 7b proves the packed build
# reads the header and leaves the file and its profile exactly as it found them.
#
# WHY THE PROVENANCE GATE (SHIP-17, docs/00 §4.4.1, docs/15 Q-21): the
# originality audit is a pre-export gate on paper — "each of the six categories
# has a named author or a recorded original-work provenance; anything
# unattributed fails the gate". PROVENANCE.md is that manifest, one row per
# shipped asset family with a `Signed:` line; step 0 HOLDS while any row is
# unsigned. Same shape as the pending-content hold: a content gap, not a build
# defect, cleared by a person writing their name and never by editing here.
#
# WHY THE PENDING GATE: docs/14 §5.4 assertion 10 — "No `stats_pending: true`
# and no `shippable: false` in a release build" — and §10.1 makes it pre-export
# gate (4). It is a LIST of flags rather than two hard-coded greps because the
# same rule keeps arriving with a new name: `name_pending` landed with the nine
# Legendary definition files that docs/03 §5.6 forbids inventing names for. A
# new pending flag is one line in PENDING below.
#
# WHY IT RE-EXECS ITSELF: this starts the engine three times and Godot corrupts
# .godot/ if two invocations overlap (tools/with_godot_lock.sh's header). The
# lock is a directory, so acquiring it twice would deadlock — hence the env
# guard rather than wrapping each call.
#
# SENTINELS, for a caller that greps: `EXPORT OK` (shippable), `DEV EXPORT OK`
# (--dev, pending content or an unsigned provenance inside; the stamp names
# every hold), `EXPORT FAILED`.
#
# The .NET question, settled by running it: tools/env.sh's GODOT is the mono
# editor build and this project has no .cs file and no .csproj. The mono editor
# exports it as an ordinary GDScript project using the mono templates at
# 4.7.1.stable.mono/ — no solution is generated and none is needed.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
source tools/env.sh

if [ "${TWG_HOLDING_GODOT_LOCK:-0}" != "1" ]; then
  TWG_HOLDING_GODOT_LOCK=1 exec ./tools/with_godot_lock.sh "$0" "$@"
fi

GODOT_TIMEOUT=${GODOT_TIMEOUT:-300}
GODOT_GATE_TIMEOUT=${GODOT_GATE_TIMEOUT:-900}

SKIP_GATES=0; CLEAN=0; WITH_LINUX=0; DEV=0
for a in "$@"; do
  [ "$a" = "--skip-gates" ] && SKIP_GATES=1
  [ "$a" = "--clean" ]      && CLEAN=1
  [ "$a" = "--linux" ]      && WITH_LINUX=1
  [ "$a" = "--dev" ]        && DEV=1
done

RC=0
PENDING_HITS=0
PROV_UNSIGNED=0
PROV_ROWS=0
PROVENANCE="PROVENANCE.md"
V10_FIXTURE="tests/fixtures/saves/v10_sample.json"
# Where the exported build keeps `user://` under a profile root (Windows:
# %APPDATA%/Godot/app_userdata/<config/name>; Linux: $XDG_DATA_HOME/godot/app_userdata/<name>).
USERDATA_WIN="Godot/app_userdata/A Guild Story"
OUTDIR="build/exports"
EXE="$OUTDIR/AGuildStory.exe"
PCK="$OUTDIR/AGuildStory.pck"
CONSOLE="$OUTDIR/AGuildStory.console.exe"
LOG="$OUTDIR/export.log"
IMPORT_LOG="$OUTDIR/import.log"

hdr() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
ok()  { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
bad() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; RC=1; }
skip(){ printf '  \033[33mSKIP\033[0m  %s\n' "$1"; }

# ------------------------------------------------- 0/8 provenance (docs/00 §4.4.1)
# One `Signed:` line per asset family in PROVENANCE.md. A blank one is a family
# nobody has vouched for, and the release holds on it. The unsigned rows are
# printed by their headings so the person who has to sign sees the list.
hdr "0/8  provenance (docs/00 §4.4.1, docs/15 Q-21 — PROVENANCE.md)"
if [ ! -f "$PROVENANCE" ]; then
  PROV_UNSIGNED=1
  printf '  \033[31m%s\033[0m  %s\n' "HOLD" "no $PROVENANCE at the repo root — nothing is vouched for"
else
  PROV_ROWS=$(grep -cE '^- Signed:' "$PROVENANCE")
  PROV_SIGNED=$(grep -cE '^- Signed:[[:space:]]*[^[:space:]]' "$PROVENANCE")
  PROV_UNSIGNED=$((PROV_ROWS - PROV_SIGNED))
  if [ "$PROV_ROWS" = "0" ]; then
    PROV_UNSIGNED=1
    printf '  \033[31m%s\033[0m  %s\n' "HOLD" "$PROVENANCE has no 'Signed:' rows — nothing is vouched for"
  elif [ "$PROV_UNSIGNED" = "0" ]; then
    ok "every asset family in $PROVENANCE is signed ($PROV_ROWS rows)"
  else
    printf '  \033[31m%s\033[0m  %s\n' "HOLD" "$PROV_UNSIGNED of $PROV_ROWS asset families in $PROVENANCE are unsigned"
    awk '/^## /{h=$0} /^- Signed:[[:space:]]*$/{sub(/^## /,"",h); print "          " h}' "$PROVENANCE"
  fi
fi
if [ "$PROV_UNSIGNED" -gt 0 ]; then
  if [ "$DEV" = "1" ]; then
    skip "--dev: exporting anyway. This build is NOT SHIPPABLE."
  else
    bad "the provenance manifest is unsigned — a release must not ship past this"
    printf '        This is a SIGN-OFF gap, not a build defect. It clears when the\n'
    printf '        designer signs each row of %s, not by editing here.\n' "$PROVENANCE"
    printf '        Use --dev for a playable build that is stamped NOT SHIPPABLE.\n'
  fi
fi

# ------------------------------------------------- 1/8 pending content (§5.4.10)
# Each row is `flag:blocking_value`. A row means "this JSON key set to this value
# is unresolved content, and unresolved content does not ship". Add a row; do not
# add a second grep somewhere else.
PENDING=(
  "stats_pending:true"    # docs/14 §5.4 assertion 10 — a canon item with no stat block
  "shippable:false"       # docs/14 §5.4 assertion 10 — Bard's kit is the named case (docs/14 §5.3)
  "name_pending:true"     # docs/03 §5.6 — the eight unnamed Legendaries. DO NOT INVENT NAMES
)

hdr "1/8  pending content (docs/14 §5.4 assertion 10)"
for row in "${PENDING[@]}"; do
  flag="${row%%:*}"
  value="${row##*:}"
  HITS=$(grep -rlE "\"$flag\"[[:space:]]*:[[:space:]]*$value" data/ 2>/dev/null | sort)
  if [ -z "$HITS" ]; then
    ok "no \"$flag\": $value in data/"
  else
    N=$(echo "$HITS" | wc -l | tr -d ' ')
    PENDING_HITS=$((PENDING_HITS + N))
    printf '  \033[31m%s\033[0m  %s\n' "HOLD" "$N file(s) carry \"$flag\": $value"
    echo "$HITS" | sed 's/^/          /'
  fi
done
if [ "$PENDING_HITS" -gt 0 ]; then
  if [ "$DEV" = "1" ]; then
    skip "--dev: exporting anyway. This build is NOT SHIPPABLE."
  else
    bad "$PENDING_HITS file(s) hold unresolved content — a release must not ship past this"
    printf '        This is a CONTENT gap, not a build defect. It clears when a\n'
    printf '        designer supplies the missing names/stats, not by editing here.\n'
    printf '        Use --dev for a playable build that is stamped NOT SHIPPABLE.\n'
  fi
fi

# ------------------------------------------------- 2/8 sim purity (§10.1 gate 1)
# docs/14 §10.1 names `check_sim_purity.sh`, which this build never grew. The
# equivalent that DOES exist is house rule 6 written as a grep: nothing under
# sim/ may touch the clock, the scene tree, the engine singleton, unseeded
# randomness, or game/. Full-line comments are excluded (MistakeLines.gd's own
# header quotes the rule); a trailing comment that names one of these still
# trips it, which is the safe direction to be wrong in.
hdr "2/8  sim purity (docs/14 §10.1 gate 1, mapped — see docs/15 BL-74)"
IMPURE=$(grep -rnE 'Engine\.|get_tree\(\)|OS\.|Time\.|randi\(|randf\(|randomize\(|res://game/' \
  sim/ --include='*.gd' 2>/dev/null | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#')
if [ -z "$IMPURE" ]; then
  ok "sim/ touches no clock, tree, engine singleton or unseeded RNG"
else
  bad "sim/ is not pure"
  echo "$IMPURE" | head -10 | sed 's/^/          /'
fi

# ------------------------------------------------- 3/8 the build gate
hdr "3/8  build gate (docs/14 §10.1 gate 3)"
if [ "$SKIP_GATES" = "1" ]; then
  skip "--skip-gates"
else
  GATE=$(TWG_HOLDING_GODOT_LOCK=1 timeout "$GODOT_GATE_TIMEOUT" ./tools/verify.sh 2>&1)
  if echo "$GATE" | grep -q "VERIFY OK"; then
    ok "$(echo "$GATE" | grep -E 'TESTS PASSED' | head -1)"
  else
    bad "./tools/verify.sh did not return VERIFY OK"
    echo "$GATE" | grep -E "FAIL|TESTS FAILED|SCRIPT ERROR" | head -20 | sed 's/^/          /'
  fi
fi

# A gate that failed must not produce an artifact. Exporting anyway is how a
# broken build reaches a tester with a green-looking log above it.
if [ "$RC" != "0" ]; then
  echo
  printf '\033[1;31mEXPORT FAILED\033[0m  (gates did not pass; nothing was exported)\n'
  exit "$RC"
fi

# ------------------------------------------------- 4/8 import
[ "$CLEAN" = "1" ] && rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

# The import log is kept SEPARATE from the export log. Both stages print script
# errors and pooling them made an unrelated parse error in the tree read as an
# export defect — the first run of this script did exactly that.
hdr "4/8  import"
timeout "$GODOT_TIMEOUT" "$GODOT" --headless --path . --import > "$IMPORT_LOG" 2>&1
IMPORT_ERRS=$(grep -aE "SCRIPT ERROR|Parse Error|Compile Error" "$IMPORT_LOG" | head -5)
if [ ! -f ".godot/global_script_class_cache.cfg" ]; then
  bad "--import did not produce a class cache"
elif [ -n "$IMPORT_ERRS" ]; then
  bad "the project does not compile — fix the tree before exporting it"
  echo "$IMPORT_ERRS" | sed 's/^/          /'
else
  ok "import database and class cache are warm"
fi

if [ "$RC" != "0" ]; then
  echo
  printf '\033[1;31mEXPORT FAILED\033[0m  (import: %s)\n' "$IMPORT_LOG"
  exit "$RC"
fi

# ------------------------------------------------- 5/8 export
hdr "5/8  export"
: > "$LOG"
export_one() {
  local preset="$1" out="$2"
  timeout "$GODOT_TIMEOUT" "$GODOT" --headless --path . \
    --export-release "$preset" "$out" >> "$LOG" 2>&1
  local status=$?
  # `--export-release` has returned 0 over a log full of errors before, so the
  # log is read as well as the exit code.
  local errs
  errs=$(grep -aE "ERROR|Failed|Cannot open|Can't open" "$LOG" | head -5)
  if [ "$status" != "0" ]; then
    bad "$preset: export exited $status (log: $LOG)"
    tail -5 "$LOG" | sed 's/^/          /'
  elif [ -n "$errs" ]; then
    bad "$preset: export log carries errors"
    echo "$errs" | sed 's/^/          /'
  elif [ ! -f "$out" ]; then
    bad "$preset: no file at $out"
  else
    ok "$preset -> $out"
  fi
}
export_one "Windows Desktop" "$EXE"
if [ "$WITH_LINUX" = "1" ]; then
  export_one "Linux x86_64" "$OUTDIR/AGuildStory.x86_64"
  # Stated, not implied: nothing below launches it. A Linux binary cannot be
  # run on this build machine, so that preset is export-only until CI has a
  # Linux runner. docs/14 §10.1 wants the target from day one; this is it,
  # honestly labelled.
  skip "Linux binary exported but NOT launch-checked (no Linux runner here)"
fi

# ------------------------------------------------- 6/8 pck hygiene (§10.1 gate 6)
# A .pck stores resource paths as plain strings, so the pack can be asked
# directly whether a directory that should have been .gdignore'd got in. This is
# the check that catches a missing marker (docs/14 §4), and it only works
# because binary_format/embed_pck is false in export_presets.cfg.
hdr "6/8  pck hygiene (docs/14 §10.1 gate 6)"
if [ ! -f "$PCK" ]; then
  bad "no $PCK to inspect (embed_pck must stay false)"
else
  for prefix in "res://ideaboard/" "res://Aseprite/" "res://build/" "res://art/" "res://docs/"; do
    # `grep -c` exits 1 on no match, which is the PASS case here, so its status
    # is deliberately ignored — reading it as failure printed "0" twice.
    N=$(grep -a -c "$prefix" "$PCK" 2>/dev/null)
    if [ "${N:-0}" = "0" ]; then
      ok "no $prefix paths packed"
    else
      bad "$N reference(s) to $prefix are inside the pack — a .gdignore is missing"
    fi
  done
fi

# ------------------------------------------------- 7/8 launch check
# A new, empty profile per launch: the exported build must not see the
# developer's settings or saves. `launch_from PROFILE [args]` boots the console
# wrapper headless with the engine's own data-path variables pointed at PROFILE
# and prints its stdout+stderr; `userdata_of PROFILE` is where the build's
# `user://` lands under it.
fresh_profile() {
  mktemp -d "${TMPDIR:-/tmp}/aguildstory-profile.XXXXXX"
}
userdata_of() {
  printf '%s/%s' "$1" "$USERDATA_WIN"
}
launch_from() {
  local profile="$1"; shift
  local win_profile="$profile"
  command -v cygpath >/dev/null 2>&1 && win_profile=$(cygpath -w "$profile")
  APPDATA="$win_profile" LOCALAPPDATA="$win_profile" XDG_DATA_HOME="$profile" \
    XDG_CONFIG_HOME="$profile" XDG_CACHE_HOME="$profile" \
    timeout "$GODOT_TIMEOUT" "$CONSOLE" --headless --quit-after 180 "$@" 2>&1
}
boot_errors() {
  echo "$1" | grep -aE "SCRIPT ERROR|Parse Error|Cannot open|Failed to load|Condition \"" \
    | grep -v "Blocking mode" | head -20
}

hdr "7/8  the exported build actually launches — from an EMPTY profile"
if [ ! -f "$CONSOLE" ]; then
  bad "no console wrapper at $CONSOLE (debug/export_console_wrapper must be 2)"
elif [ "$RC" != "0" ]; then
  skip "an earlier step failed; not launching a build that is already broken"
else
  PROFILE=$(fresh_profile)
  BOOT=$(launch_from "$PROFILE")
  BOOT_STATUS=$?
  ERRS=$(boot_errors "$BOOT")
  USERDIR=$(userdata_of "$PROFILE")
  if [ "$BOOT_STATUS" != "0" ]; then
    bad "the exported build exited $BOOT_STATUS"
    echo "$BOOT" | tail -10 | sed 's/^/          /'
  elif [ -n "$ERRS" ]; then
    bad "the exported build boots with errors"
    echo "$ERRS" | sed 's/^/          /'
  elif [ ! -d "$USERDIR" ]; then
    # The redirect is the whole point of the step, so its absence is a
    # failure, not a note: the build booted the developer's profile again.
    bad "the exported build did not use the temp profile (no $USERDATA_WIN under $PROFILE)"
  elif [ -d "$USERDIR/saves" ]; then
    bad "a first boot wrote saves/ into the empty profile — nothing should save before a guild exists"
  else
    ok "boots clean for 180 frames from the packed build, first-run profile at $PROFILE"
  fi
  rm -rf "$PROFILE"
fi

# ------------------------------------------------- 7b/8 an old save in the profile
# The oldest migratable fixture, dropped into a fresh profile's saves/ as slot 0.
# The packed build's main menu reads that header on boot (SaveGame.read_header /
# newest_loadable) and must offer Continue without an error; migration itself
# runs on Continue and writes a .bak first, so a boot must leave the file alone
# and write no backup — both asserted, because a boot that migrated would be a
# boot that lost the player's file to a bad step before they pressed anything.
hdr "7b/8 the exported build boots with a v10 save in the profile"
if [ ! -f "$CONSOLE" ] || [ "$RC" != "0" ]; then
  skip "not launched (see 7/8)"
elif [ ! -f "$V10_FIXTURE" ]; then
  bad "no $V10_FIXTURE to seed the profile with"
else
  PROFILE=$(fresh_profile)
  USERDIR=$(userdata_of "$PROFILE")
  mkdir -p "$USERDIR/saves"
  cp "$V10_FIXTURE" "$USERDIR/saves/slot_0.json"
  BOOT=$(launch_from "$PROFILE")
  BOOT_STATUS=$?
  ERRS=$(boot_errors "$BOOT")
  if [ "$BOOT_STATUS" != "0" ]; then
    bad "the exported build exited $BOOT_STATUS with a v10 save present"
    echo "$BOOT" | tail -10 | sed 's/^/          /'
  elif [ -n "$ERRS" ]; then
    bad "the exported build boots with errors when a v10 save is present"
    echo "$ERRS" | sed 's/^/          /'
  elif ! cmp -s "$V10_FIXTURE" "$USERDIR/saves/slot_0.json"; then
    bad "the boot rewrote the v10 save — migration belongs to Continue, not to boot"
  elif ls "$USERDIR/saves"/*.bak >/dev/null 2>&1; then
    bad "the boot wrote a migration backup — migration belongs to Continue, not to boot"
  else
    ok "boots clean with $(basename "$V10_FIXTURE") as slot 0; the file is untouched"
  fi
  rm -rf "$PROFILE"
fi

# ------------------------------------------------- 8/8 sizes
hdr "8/8  artifact"
for f in "$EXE" "$PCK" "$CONSOLE" "$OUTDIR/AGuildStory.x86_64"; do
  [ -f "$f" ] && printf '  %-42s %s\n' "$f" "$(du -h "$f" | cut -f1)"
done

echo
# The stamp names EVERY hold, so a --dev build says exactly what stands between
# it and a release rather than the first thing the script happened to check.
HOLDS=""
[ "$PENDING_HITS" -gt 0 ] && HOLDS="$PENDING_HITS file(s) hold unresolved content"
if [ "$PROV_UNSIGNED" -gt 0 ]; then
  [ -n "$HOLDS" ] && HOLDS="$HOLDS; "
  HOLDS="${HOLDS}provenance unsigned ($PROV_UNSIGNED of $PROV_ROWS rows in $PROVENANCE)"
fi
if [ "$RC" != "0" ]; then
  printf '\033[1;31mEXPORT FAILED\033[0m  (log: %s)\n' "$LOG"
elif [ -n "$HOLDS" ]; then
  printf '\033[1;33mDEV EXPORT OK\033[0m  NOT SHIPPABLE: %s (log: %s)\n' "$HOLDS" "$LOG"
else
  printf '\033[1;32mEXPORT OK\033[0m  (log: %s)\n' "$LOG"
fi
exit $RC
