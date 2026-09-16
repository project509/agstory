"""Apply a wave handoff file's exact edits to the tree.

    python tools/apply_handoff.py build/plan/handoff-W1-KIT.md            # apply
    python tools/apply_handoff.py build/plan/handoff-W1-KIT.md --dry-run  # report only
    python tools/apply_handoff.py FILE --only 1,3,5                        # a subset

A handoff (00-plan.md §0.2) is a Markdown file where each edit is

    ## N. <path>:<line>
    ...prose...
    old:
    ```
    <exact text>
    ```
    new:
    ```
    <exact text>
    ```

`old:` must occur exactly once in the file; an edit whose `new:` text is already
present and whose `old:` is absent is reported as ALREADY APPLIED (a unit may have
applied it in-wave); anything else is SKIPPED with the reason. Line endings follow
the target file. The fence may carry a language tag. A heading whose path is a
new file (old block empty) is written whole. Exit 1 if any edit was skipped.
"""
import argparse
import os
import re
import sys

HEAD = re.compile(r"^## (\d+)\. ([^\s:]+)(?::(\d+))?.*$")
FENCE = re.compile(r"^```[\w-]*\s*$")


def parse(text):
    lines = text.split("\n")
    edits, i = [], 0
    while i < len(lines):
        m = HEAD.match(lines[i])
        if not m:
            i += 1
            continue
        n, path = int(m.group(1)), m.group(2)
        blocks, j = {}, i + 1
        while j < len(lines) and not HEAD.match(lines[j]):
            key = lines[j].strip().rstrip(":").lower()
            if key in ("old", "new") and j + 1 < len(lines) and FENCE.match(lines[j + 1]):
                k = j + 2
                body = []
                while k < len(lines) and not lines[k].startswith("```"):
                    body.append(lines[k])
                    k += 1
                blocks[key] = "\n".join(body)
                j = k + 1
                continue
            j += 1
        if "old" in blocks and "new" in blocks:
            edits.append((n, path, blocks["old"], blocks["new"]))
        i = j
    return edits


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("handoff")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--only", default="")
    a = ap.parse_args()
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    only = {int(x) for x in a.only.split(",") if x.strip()}
    text = open(a.handoff, encoding="utf-8").read().replace("\r\n", "\n")
    edits = parse(text)
    if not edits:
        print("no edits found")
        return 1
    rc = 0
    for n, rel, old, new in edits:
        if only and n not in only:
            continue
        path = os.path.join(root, rel)
        tag = f"#{n} {rel}"
        if old.strip() == "" or old.strip().startswith("(none"):
            if os.path.exists(path):
                print(f"  SKIP     {tag}: new file but it exists")
                rc = 1
                continue
            if not a.dry_run:
                os.makedirs(os.path.dirname(path), exist_ok=True)
                open(path, "w", encoding="utf-8", newline="\n").write(new + "\n")
            print(f"  CREATED  {tag}")
            continue
        if not os.path.exists(path):
            print(f"  SKIP     {tag}: file missing")
            rc = 1
            continue
        raw = open(path, encoding="utf-8", newline="").read()
        nl = "\r\n" if raw.count("\r\n") > raw.count("\n") / 2 else "\n"
        s = raw.replace("\r\n", "\n")
        # The new text first: an insertion after an anchor keeps the old text
        # inside the new, so "old still matches" is not proof it is unapplied.
        deletion = new.strip() == ""
        if not deletion and new in s:
            print(f"  ALREADY  {tag}")
            continue
        c = s.count(old)
        if c == 0:
            if deletion:
                print(f"  ALREADY  {tag} (deleted)")
            else:
                print(f"  SKIP     {tag}: old text not found")
                rc = 1
            continue
        if c > 1:
            print(f"  SKIP     {tag}: old text occurs {c} times")
            rc = 1
            continue
        s = s.replace(old, new, 1)
        if not a.dry_run:
            open(path, "w", encoding="utf-8", newline="").write(s.replace("\n", nl))
        print(f"  APPLIED  {tag}")
    return rc


if __name__ == "__main__":
    sys.exit(main())
