"""Lay screen shots out on contact sheets so a whole pass fits in two images.

    python tools/art/contact_sheet.py build/shots/all/fixture   # every *.png there
    python tools/art/contact_sheet.py DIR --scale 0.5 --cols 2 --per 6

Writes DIR/_sheet_1.png, _sheet_2.png, ... (files starting with '_' are skipped
as inputs, so re-running does not sheet the sheets). Order follows the game's
own flow when the names are known, alphabetical otherwise; a tile named
"<Screen>_<variant>" (a pressed tab, a reduced pass, an advanced fight) sorts
with its screen, variants alphabetical inside it.

Tiles are resized to the FIRST tile's size, so a directory should hold one
sheet's tiles at one size (tools/shot_all.sh writes each sheet to its own
directory for that reason). A tile of another size is resized, not refused,
and the mismatch is printed so it is not mistaken for a layout change.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

FLOW = [
    "MainMenu", "Town", "AdventureBoard", "RaidPrep", "RaidView", "Results",
    "Guildhall", "RaiderDetail", "Tavern", "Market", "LoadSave", "Settings", "Completion",
]


def flow_key(name: str):
    """Sort by the screen the tile belongs to, then by the variant suffix."""
    screen, _, variant = name.partition("_")
    return (FLOW.index(screen) if screen in FLOW else len(FLOW), screen, variant)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("dir")
    ap.add_argument("--scale", type=float, default=0.5)
    ap.add_argument("--cols", type=int, default=2)
    ap.add_argument("--per", type=int, default=6, help="tiles per sheet")
    a = ap.parse_args()

    names = [f[:-4] for f in os.listdir(a.dir)
             if f.lower().endswith(".png") and not f.startswith("_")]
    if not names:
        print(f"no shots in {a.dir}", file=sys.stderr)
        return 1
    names.sort(key=flow_key)

    first = Image.open(os.path.join(a.dir, names[0] + ".png"))
    tw, th = int(first.width * a.scale), int(first.height * a.scale)
    label_h = 18

    for si in range(0, len(names), a.per):
        chunk = names[si:si + a.per]
        rows = (len(chunk) + a.cols - 1) // a.cols
        sheet = Image.new("RGB", (a.cols * tw, rows * (th + label_h)), (20, 20, 20))
        draw = ImageDraw.Draw(sheet)
        for i, n in enumerate(chunk):
            x, y = (i % a.cols) * tw, (i // a.cols) * (th + label_h)
            im = Image.open(os.path.join(a.dir, n + ".png")).convert("RGB")
            label = n
            if im.size != first.size:
                label = f"{n}  ({im.width}x{im.height}, resized)"
                print(f"note: {n} is {im.width}x{im.height}, sheet tiles are "
                      f"{first.width}x{first.height}", file=sys.stderr)
            draw.text((x + 4, y + 2), label, fill=(255, 220, 120))
            sheet.paste(im.resize((tw, th), Image.LANCZOS), (x, y + label_h))
        out = os.path.join(a.dir, f"_sheet_{si // a.per + 1}.png")
        sheet.save(out)
        print(out, sheet.size, ", ".join(chunk))
    return 0


if __name__ == "__main__":
    sys.exit(main())
