#!/usr/bin/env bash
# Launch the game windowed for a manual look.
#   ./tools/run_game.sh                 main scene
#   ./tools/run_game.sh res://x.tscn    a specific scene
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
source tools/env.sh
if [ -n "${1:-}" ]; then
  exec "$GODOT" --path . "$1"
fi
exec "$GODOT" --path .
