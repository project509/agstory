#!/usr/bin/env bash
# sim/ and game/ must reference other scripts via `const X = preload(...)`,
# never via Godot's global class_name registry.
#
# Why: that registry is populated from .godot/global_script_class_cache.cfg and
# is not reliably present in headless `--script` runs. A cross-file class_name
# reference compiles in the editor, passes a load()-based parse check, and then
# fails at runtime the first time the cache goes cold — which is exactly what
# happened to Stats.gd referencing TwgEnums.
#
# A script referring to its OWN class_name is fine and is allowed.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

RC=0
while IFS= read -r -d '' f; do
  own=$(grep -m1 -oP '^class_name\s+\K\w+' "$f" 2>/dev/null || true)
  # Strip comments first: a docstring naming a type is documentation, not a
  # dependency, and flagging it would train people to ignore the lint.
  refs=$(sed 's/#.*$//' "$f" | grep -oP '\bTwg[A-Za-z0-9_]+' 2>/dev/null | sort -u || true)
  for r in $refs; do
    [ -n "$own" ] && [ "$r" = "$own" ] && continue
    # a preload const line is how it should be done; the identifier itself is the smell
    printf '  \033[31mLINT\033[0m %s references global class name %s — use `const %s = preload(...)`\n' \
      "$f" "$r" "$r"
    RC=1
  done
done < <(find sim game -name "*.gd" -type f -print0 2>/dev/null)

if [ "$RC" = "0" ]; then
  echo "LINT OK  no cross-file class_name references in sim/ or game/"
else
  echo "LINT FAILED"
fi
exit $RC
