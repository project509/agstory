#!/usr/bin/env bash
# Run a command holding the project's Godot mutex.
#
# WHY: Godot writes .godot/ (the import database and the global class cache) and
# user:// (the save directory the tests redirect into). Two engine invocations
# in the same project at the same time corrupt both — the symptom is a save test
# failing in a run whose code never touched saves. Parallel agents each want to
# verify their own work, so the engine needs a mutex rather than a convention.
#
# mkdir is atomic on every filesystem this project sees (NTFS included), so the
# lock is a directory. A lock older than STALE_S is assumed to belong to a killed
# process and is broken — a crashed agent must not wedge the build for everyone.
#
#   tools/with_godot_lock.sh "$GODOT" --headless --path . --script res://tests/run_tests.gd
#   tools/with_godot_lock.sh ./tools/verify.sh --fast
#
# Exits with the command's own status. Waits up to WAIT_S for the lock, then
# fails 75 rather than running unguarded.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

LOCK=".godot_engine.lock"
WAIT_S="${GODOT_LOCK_WAIT:-900}"     # how long to queue for the engine
STALE_S="${GODOT_LOCK_STALE:-1200}"  # a lock older than this belonged to a dead run

waited=0
while ! mkdir "$LOCK" 2>/dev/null; do
  # Break a stale lock: mtime older than STALE_S and no live holder heartbeat.
  if [ -d "$LOCK" ]; then
    mtime=$(stat -c %Y "$LOCK" 2>/dev/null || echo "")
    if [ -z "$mtime" ]; then
      sleep 1
      continue
    fi
    age=$(( $(date +%s) - mtime ))
    if [ "$age" -gt "$STALE_S" ]; then
      echo "godot-lock: breaking stale lock (${age}s old)" >&2
      rm -rf "$LOCK"
      continue
    fi
  fi
  if [ "$waited" -ge "$WAIT_S" ]; then
    echo "godot-lock: gave up after ${waited}s waiting for $LOCK" >&2
    exit 75
  fi
  sleep 3
  waited=$(( waited + 3 ))
done

# Keep the lock's mtime fresh while the command runs, so a long test run is
# never mistaken for a stale lock by another waiter.
# One-second steps, not one 30 s sleep: `kill $heartbeat` ends the subshell but not
# a `sleep 30` it is inside, and that orphan held the caller's pipe open for up to
# 30 s after every engine run (measured 2026-09-14: a 0.8 s script took 30.2 s).
( while [ -d "$LOCK" ]; do touch "$LOCK" 2>/dev/null; for _ in $(seq 30); do [ -d "$LOCK" ] || exit 0; sleep 1; done; done ) &
heartbeat=$!

cleanup() {
  kill "$heartbeat" 2>/dev/null
  rm -rf "$LOCK"
}
trap cleanup EXIT INT TERM

"$@"
status=$?
exit "$status"
