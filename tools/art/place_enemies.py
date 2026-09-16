#!/usr/bin/env python3
"""place_enemies - copy each boss rank's sliced export into game/assets/enemies (PIPE-17).

The game loads bosses by RANK name (boss_main, boss_mini_2, ...) while the art library holds
them by EXPORT name (sludge_maw_leviathan, boss_stone_brute, ...). The mapping is data in
game/assets/enemies/enemies.json; this script is the one hand that copies export -> rank, so
replacing a boss (PIPE-03) edits the table and re-runs this instead of overwriting an orphan.

  python tools/art/place_enemies.py            # copy every rank (byte copy, no re-encode)
  python tools/art/place_enemies.py --check    # compare only; exit 1 on DIFFERS / MISSING
  python tools/art/place_enemies.py --rank boss_main [--rank ...]

Each export must also have a `boss` row in art/ref/manifests/all.json under the same name -
that row is the sheet rect (slice.py cut reproduces the export from it), so the chain
sheet -> export -> rank is closed without storing any rect twice. A missing row is an error.

A rank PNG that is new to the tree needs a `.png.import` beside it; this script does not write
one - Godot generates it on the next boot through the lock, and the boot gate reports a PNG
that fails to load. Exit codes: 0 ok, 1 differs/missing under --check, 2 table error.
"""
import argparse
import filecmp
import json
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TABLE = os.path.join(ROOT, "game", "assets", "enemies", "enemies.json")


def die(msg):
    """A table error: nothing was written; exit 2 so a caller can tell it from a DIFFERS (1)."""
    print("ERROR " + msg)
    sys.exit(2)


def load_table():
    with open(TABLE, encoding="utf-8") as f:
        table = json.load(f)
    for key in ("export_dir", "target_dir", "manifest", "ranks"):
        if key not in table:
            die("enemies.json has no '%s'" % key)
    return table


def manifest_boss_names(table):
    path = os.path.join(ROOT, table["manifest"])
    with open(path, encoding="utf-8") as f:
        man = json.load(f)
    return {e.get("proposed_name") for e in man.get("entries", []) if e.get("category") == "boss"}


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--check", action="store_true", help="compare only, never write")
    ap.add_argument("--rank", action="append", default=[], help="limit to these rank names")
    a = ap.parse_args(argv)

    table = load_table()
    ranks = table["ranks"]
    wanted = a.rank or sorted(ranks)
    unknown = [r for r in wanted if r not in ranks]
    if unknown:
        die("not in enemies.json: %s" % ", ".join(unknown))
    in_manifest = manifest_boss_names(table)

    problems = 0
    for rank in wanted:
        row = ranks[rank]
        export = row.get("export", "")
        if not export:
            print("%-12s ERROR   no export named" % rank)
            problems += 1
            continue
        if export not in in_manifest:
            print("%-12s ERROR   export '%s' has no boss row in %s" % (rank, export, table["manifest"]))
            problems += 1
            continue
        src = os.path.join(ROOT, table["export_dir"], export + ".png")
        dst = os.path.join(ROOT, table["target_dir"], rank + ".png")
        if not os.path.isfile(src):
            print("%-12s ERROR   export missing: %s" % (rank, os.path.relpath(src, ROOT)))
            problems += 1
            continue
        if a.check:
            if not os.path.isfile(dst):
                print("%-12s MISSING %s" % (rank, os.path.relpath(dst, ROOT)))
                problems += 1
            elif filecmp.cmp(src, dst, shallow=False):
                print("%-12s OK      == %s" % (rank, export))
            else:
                print("%-12s DIFFERS from %s" % (rank, export))
                problems += 1
            continue
        if os.path.isfile(dst) and filecmp.cmp(src, dst, shallow=False):
            print("%-12s kept    == %s" % (rank, export))
        else:
            shutil.copyfile(src, dst)
            print("%-12s placed  <- %s" % (rank, export))
        if not os.path.isfile(dst + ".import"):
            print("%-12s note    no .import beside it yet; Godot writes one on the next boot" % rank)

    if a.check:
        print("PLACE_ENEMIES %s" % ("OK" if problems == 0 else "%d problem(s)" % problems))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
