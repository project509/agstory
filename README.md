# A Guild Story

A guild-management game about running a raiding guild of people who are bad at raiding.

> Your guild is terrible. Keep them happy enough to function, gear them well enough to
> survive their own mistakes, and turn the reputation you earn into a town that finally
> sends you someone competent. You will never once press an ability button.
>
> — the pitch, [docs/00 §2](docs/00-vision-and-pillars.md)

You recruit them at the tavern, gear them, keep them from quitting, and send them at a boss
knowing roughly how badly they will screw it up. You never press an ability button — you set
up the roster, press Start, and watch a simulated raid where every raider's incompetence is
one number (mistake chance) that morale and gear modify. Reputation earned in raids visibly
rebuilds the town, and the better town is what finally sends you someone competent.

The design set's own front door is [docs/README.md](docs/README.md). This file is for someone
who has just cloned the repo and wants it running.

**What runs today.** New Guild → Adventure's Board → raid prep (chalk a party, read the risk
readout, chalk provisions) → Depart → the encounter plays out line by line → Results with
loot, gold and the wipe report → town. Plus the Guildhall (roster, rest, facilities,
quarters), Market, Tavern, raider detail, and versioned saves with Continue. Content is Tier 1
only, there are no tutorials, and the art pass is mid-flight. `BUILD_STATE.md` is the honest
status; it is never more than an iteration old.

---

## Playing it on Windows without bash

Double-click **`play.cmd`**. It needs only Windows: it looks for Godot 4 in `godot\` beside the
project (drop the engine `.exe` there and the zipped folder runs on any machine — see
`godot/PUT-GODOT-HERE.txt`), then in the `GODOT` variable, the installer's home under
`%LOCALAPPDATA%\Programs\Godot`, and PATH; with none it says what to download.
`play.cmd debug` keeps the console open with Godot's log; `play.cmd where` prints the engine it would use;
`play.cmd check` boots headless for a moment. The `.sh` tools below still need Git Bash.

## The engine pin

**Godot 4.7.1-stable-mono**, renderer **Mobile**, base viewport **1536×1024**, stretch
`canvas_items`, aspect `keep`. The pin lives in three places that must agree — `project.godot`
(`config/features`, `rendering/renderer/rendering_method`, `display/window/size/*`),
[docs/14 §2.5](docs/14-technical-architecture.md), and this README — and nobody upgrades
mid-milestone (docs/15 Q-15).

Mobile is a requirement, not a preference: the Compatibility renderer has neither 2D glow nor
`hdr_2d`, which are two of the ingredients of the look docs/12 specifies. The project is
GDScript only — the mono build is simply the one installed here, and there is no C# build step.

`tools/env.sh` is the single place any tool learns where the engine is:

```bash
export GODOT="/c/Users/greyp/AppData/Local/Programs/Godot/Godot_v4.7.1-stable_mono_win64/Godot_v4.7.1-stable_mono_win64_console.exe"
export ASEPRITE="./Aseprite/Aseprite.exe"
```

That is the **console** build, which is what all CLI work uses. If your Godot lives somewhere
else, edit that one file and nothing else.

**Also needed:** bash (Git Bash on Windows — the scripts use `find`, `grep -P` and `timeout`).
For art work only: **Aseprite at `Aseprite/Aseprite.exe`**, which is gitignored as a licensed
third-party binary and must be supplied per machine (docs/14 §10.3), and **Python 3 with
Pillow and numpy** for the scoring tools under `tools/art/`.

---

## Run it

```bash
./tools/run_game.sh                                   # the main scene, res://game/ui/Boot.tscn
./tools/run_game.sh res://game/screens/Market.tscn    # one scene, windowed
```

## Verify it

```bash
./tools/verify.sh          # the gate — must exit 0 before every commit
./tools/verify.sh --fast   # class cache, lint, parse, tests; skips boot and the sweep
```

Its stages, in order:

| Stage | What it does | Passes when |
|---|---|---|
| class cache | Re-runs `--import` when any `.gd` is newer than `.godot/global_script_class_cache.cfg`. Nothing else writes that file in a headless-only workflow, and without it the first cross-file `class_name` reference fails at runtime while parse checks stay green. | the cache exists |
| 0/5 lint | `tools/lint_no_global_classes.sh` — no cross-file `class_name` references in `sim/` or `game/`. | `LINT OK` |
| 1/5 parse | `tools/parse_check.gd` loads every script. | `PARSE_CHECK OK` |
| 2/5 tests | `tests/run_tests.gd` — the unit and golden suite. | `TESTS PASSED` |
| 3/5 boot | Runs the main scene headless for 180 frames and greps the output for script errors. | no errors |
| 4/5 sweep | `tools/balance_sweep.gd` — the balance sweep across seeds and levers. | `SWEEP OK` |

The full output of every stage lands in `.verify.log` (gitignored).

### The engine is mutexed — always go through the lock

```bash
source tools/env.sh
tools/with_godot_lock.sh ./tools/verify.sh
tools/with_godot_lock.sh "$GODOT" --headless --path . --script res://tests/run_tests.gd
```

Godot writes `.godot/` (the import database and the class cache) and `user://` (the save
directory the tests redirect into). Two engine invocations in the same project at the same
time corrupt both, and the symptom is a **save test failing in a run whose code never touched
saves** — so the engine needs a mutex, not a convention. The lock is a directory (`mkdir` is
atomic, NTFS included); a waiter queues 900 s then fails with exit 75, and a lock older than
1200 s is assumed to belong to a killed process and is broken. An orphaned Godot process from
a killed run corrupts the save tests the same way: kill it before you believe a red suite.

## Build the art

```bash
./tools/build_art.sh --gen    # re-run every tools/aseprite/gen_*.lua -> art/src (sources) + game/assets (PNGs)
./tools/build_art.sh --check  # regenerate into build/artcheck/ and byte-compare with the tree (verify stage 2b)
./tools/build_art.sh --tags art/src/vfx/fire_hearth.aseprite   # list a source's animation tags
```

`.aseprite` files under `art/` are the source of truth and the PNGs under `game/assets/` are
what Godot loads; `--check` proves the PNGs still match their generators (there is no atlas
step — nothing consumed one). Most of the art is *generated*, not hand-drawn: the Lua generators in
`tools/aseprite/` (`gen_ui`, `gen_items`, `gen_icons`, `gen_fire`, `gen_wipe`, on `lib.lua`) run headless through
Aseprite's `-b --script`, and the Python tools in `tools/art/` do the rest — `gen_wordmark.py`,
`make_portraits.py`, `derive_busts.py`, `patch_bubbles.py`, and `slice.py`, which cuts sprites
out of the asset sheets.

**The quality bar is `ideaboard/Reference Concepts/` at 1:1.** Those three PNGs are 1536×1024,
one image pixel to one game pixel — they *are* the target framebuffer, which is why the base
viewport is exactly that size and a screenshot can be pixel-diffed against them. The measured
specs derived from them live in `art/ref/specs/00..11`; read `00-canon-reconciliation.md`
before any visual work, because the references contradict canon in five places and canon wins
every time.

```bash
./tools/diff_all.sh    # shoot every converted screen and score it against its concept
```

That is the art gate, run beside `verify.sh`. It renders through `tools/shot.gd --fixture` (an
exact-size `SubViewport`, seeded by `tools/fixture_reference.gd` so the score measures design
and not test data) and scores with `tools/art/refdiff.py` — MAE, structure, layout IoU and
palette EMD, because each number hides a different kind of failure. A screen is done when the
verdict is INDISTINGUISHABLE; VERY CLOSE is the working target.

---

## Repo layout

```
sim/        pure deterministic simulation — no engine types
  core/     Rng, EventLog, Formulas, Sim entrypoint
  model/    Raider, Item, ClassDef, Encounter, RaidState
  content/  data loading + validation
game/       Godot scenes, UI, presentation (replays sim event logs)
data/       JSON content: classes, items, encounters, backstories
art/        .aseprite sources (truth)  ->  game/assets/ PNGs (tools/aseprite/gen_*.lua writes both)
tests/      unit + golden tests
tools/      verify, build_art, balance_sweep, parse_check
docs/       the design set — canon
```

**`sim/` is pure** (docs/14 §3.2). It is a deterministic function of
`(roster, gear, encounter, seed) -> event log`: no `Node`, `SceneTree`, `await`, signals or
timers; no `Time`, `OS` or `delta`; no `FileAccess`, `load()` or autoloads; and no randomness
except an injected `sim/core/Rng.gd` stream — never `randi()` or `randf()`. `game/` may import
`sim/`; `sim/` may never import `game/`. Same inputs, byte-identical outputs, which is what
makes the golden tests and the balance sweep possible. The rule is held by review and by those
tests today; the grep gate docs/14 §3.5 proposes is not written.

**Never reference another script's `class_name`** — use `const Other = preload("res://…")`.
Godot's global class registry is not reliably present in headless `--script` runs, so such a
reference compiles in the editor, passes the parse check, and then fails at runtime the first
time the cache goes cold. `tools/lint_no_global_classes.sh` fails the build on it.

---

## How this project works

It is not a normal repo, and the discipline is the part a newcomer breaks first.

- **`docs/` is canon.** Every number in the code traces to a doc section. `docs/_source/` is
  the lead designer's own words and is **never edited**, not even for a typo; every other doc
  is derived work and cites it. Read the doc that owns a system before implementing it — the
  index is in [docs/README.md §3](docs/README.md).
- **Never invent a number, a rate or a name.** If canon is silent, the doc's proposal is the
  implementation and the fact that it was a proposal gets written down.
- **An ambiguity goes behind a switch**, with the documented default selected, plus a numbered
  entry in [docs/15-open-questions.md](docs/15-open-questions.md) (`Q-NN`) saying what was
  decided, why, and what would change the answer. Never resolve one silently.
- **`BUILD_STATE.md` and `BACKLOG.md` are the memory.** BUILD_STATE is read first and updated
  last each iteration — current focus, invariants, the GDScript traps that have already cost
  hours, and the progress log. BACKLOG is ordered: take the first unchecked box, finish it
  completely, tick it.
- **The build is always green.** `./tools/verify.sh` exits 0 before every commit; if it is
  red, fixing it is the only task.
- **The screen tests read text, not node paths.** They walk the tree collecting `Label.text`
  and `Button.text` and press buttons by a text fragment, so any user-facing string a test
  asserts must live in a Label or a Button — never only in a tooltip.
