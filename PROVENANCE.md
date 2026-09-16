# PROVENANCE — what ships, where it came from, and who signed for it

The checked-in manifest docs/00 §4.4.1 asks for: one row per shipped asset family, each with a
recorded origin and a signature. `tools/export_build.sh` step 0 reads this file and HOLDS the release
export while any `Signed:` line below is blank (`--dev` passes and stamps the build NOT SHIPPABLE).
Nothing in the build loop may sign a row: the gate clears when a person writes their name and the
date after `Signed:` — that is the whole mechanism (docs/15 Q-21, docs/16 X3.7, SHIP-17).

How to sign a row: replace the blank after `Signed:` with `<name> <YYYY-MM-DD>`, on the same line.
A row whose facts are wrong is corrected first, then signed. Rows are never deleted; a family that
stops shipping keeps its row with "no longer shipped" and the commit that removed it.

Facts below are as recorded in the tree on 2026-09-15 (art/ref/specs 07-09, tools/art, tools/aseprite,
tools/audio/README.md). The three docs/00 §4.4.1 categories that are not files — shipping strings,
names, and store/README copy — are rows 7 and 8, because the same signature covers them.

## 1. Background plates

- Ships as: `game/assets/bg/stage_camp.png`, `stage_town.png`, `stage_tavern.png`, `stage_market.png`,
  `stage_arena_cave.png`, `stage_arena_dungeon.png` (1536x1024, unedited)
- Origin: `ideaboard/bare backgrounds/*.png`, recorded in `art/ref/specs/09-background-plates.md` as the
  designer's own bare plates; the framing offsets are the screens' constants, nothing under a plate is patched
- Question for the signer: are the six bare backgrounds your own work, and may they ship?
- Signed:

## 2. Reference images (the concepts and the asset sheets)

- Ships as: nothing directly — `ideaboard/` carries a `.gdignore` and the pck-hygiene gate proves it is
  not packed. What ships is DERIVED from them: every sliced sprite in row 3, and the layout every screen
  is measured against (`tools/art/refdiff.py`)
- Origin: `ideaboard/Reference Concepts/Reference Concept {1,2,3}.png`; `ideaboard/Reference Graphics/`
  — the four asset sheets `0f2ce34a…`, `0718af5b…`, `de1918ac…`, `bbb8018d…` (specs 07/08) and the two
  files named `ChatGPT Image Sep 9, 2026, …` (spec 09's TD-TAVERN / TD-TOWN rows)
- Question for the signer: who made these, with what tool, and under what terms may work derived from
  them ship? Two carry a generator's name in the filename; the answer belongs here in writing.
- Signed:

## 3. Sliced and re-drawn sprites

- Ships as: `game/assets/actors/*.png` (the raider walk/idle strips and their hair/coat variants),
  `game/assets/enemies/*.png`, `game/assets/portraits/*.png`, `game/assets/sprites/anim/*`, the class
  glyphs and faces under `game/assets/ui/icons/`
- Origin: cut from the row-2 asset sheets by `tools/art/slice.py` against `art/ref/manifests/*.json`,
  then recoloured, animated and re-packed by `tools/art/gen_actors.py`, `derive_busts.py`,
  `make_portraits.py`, `place_enemies.py` and `tools/aseprite/gen_boss_anims.lua`
- Question for the signer: the same as row 2 — these are that material, re-drawn by script.
- Signed:

## 4. Generated UI, icons, VFX, wordmark and icon

- Ships as: `game/assets/ui/*.png` (plates, buttons, chips, cork, callouts), `game/assets/ui/icons/**`
  (items, mechanics, ranks, slots, nav, the log badges), `game/assets/vfx/*.png` (fire, embers, bolts,
  bursts, clouds, the ink blot), `game/assets/ui/icon.ico`, the boot splash and the wordmark
- Origin: procedural, original to this project — `tools/aseprite/gen_ui.lua`, `gen_icons.lua`,
  `gen_items.lua`, `gen_vfx.lua`, `gen_fire.lua`, `gen_wipe.lua`; `tools/art/gen_wordmark.py`,
  `gen_clouds.py`. Deterministic; `tools/build_art.sh` regenerates them
- Question for the signer: confirm these carry no traced or pasted material beyond rows 2-3.
- Signed:

## 5. Fonts

- Ships as: `game/assets/fonts/FiraSans-{Regular,Italic,Medium,SemiBold}.ttf`,
  `game/assets/fonts/GrenzeGotisch.ttf`
- Origin: Fira Sans (Mozilla / Carrois Apostrophe) and Grenze Gotisch (Omnibus-Type), both under the
  SIL Open Font License 1.1 — `game/assets/fonts/OFL-FiraSans.txt`, `OFL-GrenzeGotisch.txt` beside them.
  The OFL requires the licence to travel with the fonts and forbids selling the fonts alone; neither
  is a problem for a game that embeds them. Their names belong in the credits (`data/credits.json`)
- Question for the signer: confirm the two licence files ship and the credits roll names both.
- Signed:

## 6. Audio

- Ships as: `game/assets/audio/sfx/*.wav` (34 one-shots)
- Origin: rendered by `tools/audio/gen_sfx.py` — nothing sourced, downloaded or licensed; deterministic
  (each variant seeds its own generator), `tools/audio/README.md` explains each sound
- Question for the signer: confirm no sampled material was introduced.
- Signed:

## 7. The nine screenshots, and the item corpus derived from them

- Ships as: `data/items/*` (the Tier 1 item tables) and the eight generated tier tables behind the
  `name_pending` / `stats_pending` hold. The screenshots themselves are not packed (`.gdignore`)
- Origin: `ideaboard/screenshots from malkail the lead game designer/Screenshot_2026-08-27_*.png` (nine);
  docs/15 Q-21 and C-32 record that the corpus derives from them and that their provenance is written
  nowhere — this row is the nowhere
- Question for the signer: docs/15 Q-21 verbatim — are the nine screenshots original work authored for
  this project? docs/00 §4.4 bans tables taken from the original game.
- Signed:

## 8. Names, shipping strings and public copy

- Ships as: every Label/Button string under `game/`, every name in `data/*.json` (encounters, items,
  buildings, the name and backstory pools), `data/credits.json`, and the README/store copy docs/00 §4.4.2
  governs
- Origin: written for this project (docs/00 §4.4: nothing taken from the game the premise line names;
  generic MMO vocabulary kept). `tools/lint_copy.sh` keeps build-talk off the screens; the originality
  audit's string check (docs/00 §4.4.1 category 1, 2, 6) is this row
- Question for the signer: confirm the read-through of §4.4.1's categories 1, 2 and 6.
- Signed:
