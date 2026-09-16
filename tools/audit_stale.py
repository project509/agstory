#!/usr/bin/env python3
"""Find audit items that have quietly been done.

    python tools/audit_stale.py              rank every open item
    python tools/audit_stale.py --top 15     just the worst offenders
    python tools/audit_stale.py --id M6-BAL-01

WHY THIS EXISTS. `build/plan/audit.json` is the loop's queue, and the loop's own
rule is to orient from it rather than from recollection. In one week SEVEN open
items turned out to be finished — M6-BAL-01, M6-EXP-06, M6-A11Y-03, M6-A11Y-08,
half of M6-A11Y-04, M5-COMEDY-06 and m5-m02-raid-wide-ac — because the work
landed inside other items and nobody walked back to the plan. Each one cost an
iteration's orientation to discover by hand, twice in a row costing the pick
itself. A queue that lies is worse than a short queue.

HOW IT DECIDES. Every audit item argues its case in `evidence` and
`remaining_work`, and those arguments are full of NAMED THINGS: functions the
item says do not exist, constants it says are owed, files it says are missing.
This walks those names and asks the tree whether they are there now. An item that
named ten things and whose ten things all exist is not proof of anything — but it
is exactly the shape the seven had, and ranking by it puts them at the top of the
list instead of in the twentieth iteration's way.

IT IS A DETECTOR, NOT A JUDGE. It closes nothing and edits nothing. Every hit
needs the citing sentence read, because the interesting case is an item that says
"`foo()` exists but is never called" — the symbol being present is the item's
PREMISE, not its completion. Those show up here too and must be read out; that is
the cost of a heuristic that catches the other kind.
"""

import argparse
import io
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIT = os.path.join(ROOT, "build", "plan", "audit.json")

OPEN_STATUSES = ("not-started", "partial")

# What counts as a named thing worth asking about. Deliberately narrow: a symbol
# with parentheses, a SHOUTING constant, or a path with an extension. Prose in
# backticks ("`the board`") is not a claim a grep can settle.
NAMED = re.compile(
    r"`([A-Za-z_][A-Za-z0-9_]*\(\)"           # a_function()
    r"|[A-Z][A-Z0-9_]{3,}"                    # A_CONSTANT
    r"|[\w./-]+\.(?:gd|sh|py|json|md|tscn|cfg))`"
)

# Names that are everywhere and settle nothing.
NOISE = {
    "TODO", "NOTE", "CANON", "OPEN", "PROPOSED", "DONE", "JSON", "HTML",
    "README.md", "BACKLOG.md", "BUILD_STATE.md", "LESSONS.md", "audit.json",
}

SEARCH_DIRS = ["sim", "game", "tools", "tests", "data", "docs"]


def tree_has(name: str) -> bool:
    """Is `name` present anywhere the loop writes code or data?"""
    if name.endswith(".gd") or name.endswith(".sh") or name.endswith(".py") \
            or name.endswith(".tscn") or name.endswith(".cfg"):
        # A path claim is settled by the filesystem, not by a grep — an item
        # saying "tools/foo.sh does not exist" is answered by looking.
        if os.path.exists(os.path.join(ROOT, name)):
            return True
        base = os.path.basename(name)
        for d in SEARCH_DIRS:
            for dirpath, _, files in os.walk(os.path.join(ROOT, d)):
                if base in files:
                    return True
        return False
    needle = name[:-2] if name.endswith("()") else name
    try:
        out = subprocess.run(
            ["grep", "-rlF", "--include=*.gd", "--include=*.sh", "--include=*.py",
             "--include=*.json", needle] + SEARCH_DIRS,
            cwd=ROOT, capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired):
        return False
    return bool(out.stdout.strip())


def names_in(item: dict) -> list:
    text = " ".join(str(item.get(k, "")) for k in ("evidence", "remaining_work"))
    seen = []
    for m in NAMED.finditer(text):
        n = m.group(1)
        if n in NOISE or n in seen:
            continue
        seen.append(n)
    return seen


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--top", type=int, default=0, help="show only the worst N")
    ap.add_argument("--id", help="check one item by id")
    args = ap.parse_args()

    doc = json.loads(io.open(AUDIT, encoding="utf-8").read())
    rows = []
    for item in doc["items"]:
        if args.id:
            if item["id"] != args.id:
                continue
        elif item.get("actual_status") not in OPEN_STATUSES:
            continue
        names = names_in(item)
        if not names:
            continue
        present = [n for n in names if tree_has(n)]
        rows.append({
            "id": item["id"],
            "status": item.get("actual_status", "?"),
            "share": len(present) / float(len(names)),
            "present": len(present),
            "total": len(names),
            "missing": [n for n in names if n not in present][:4],
            "title": str(item.get("title", ""))[:70],
        })

    rows.sort(key=lambda r: (-r["share"], -r["total"]))
    if args.top:
        rows = rows[: args.top]

    print("")
    print("AUDIT STALENESS — how much of what each open item names already exists")
    print("  A high share is a SUSPICION, not a verdict: read the item's own")
    print("  sentence before closing it. An item whose premise is 'X exists but")
    print("  nothing calls it' scores high and is genuinely open.")
    print("")
    print("  %-24s %-12s %7s  %s" % ("id", "status", "present", "title"))
    for r in rows:
        print("  %-24s %-12s %3d/%-3d  %s"
              % (r["id"], r["status"], r["present"], r["total"], r["title"]))
        if r["missing"]:
            print("      still missing: %s" % ", ".join(r["missing"]))

    full = [r for r in rows if r["share"] >= 1.0]
    print("")
    print("  %d open item(s) named things that ALL exist now." % len(full))
    if full:
        print("  %s" % ", ".join(r["id"] for r in full))
    print("")
    print("AUDIT STALENESS REPORTED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
