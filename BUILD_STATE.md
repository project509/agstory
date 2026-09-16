# BUILD STATE — A Guild Story

> **This file is the loop's memory.** Every autonomous iteration reads it first and updates it last.
> Keep it accurate and keep it short: under 250 lines (`tests/unit/test_build_state.gd` holds the line and
> checks every path it names exists) and no more than ~12 entries in the progress list — the tail moves to
> `docs/_log/progress.md` (the full history). `LESSONS.md` has the engine/GDScript/test traps that each cost
> time twice (read it before editing UI, typing or tuning); `BACKLOG.md` holds the forward list.

---

## Current focus

**Milestone:** M6 ship-readiness — **the ship plan, `build/plan/ship/00-plan.md`** (waves 6-10, the user's
2026-09-15 directive: five more waves, then a completely shippable, polished game). **Wave 6, "Nothing lies",
landed 2026-09-15** (7/7): no player-facing string admits an unfinished feature and a copy lint keeps it so; the
Options screen honest; every UI hook makes a generated sound; the drift gate armed (stage 6b); a Common is 15 G.
**The designer delegated every open decision to the loop (2026-09-15)** — the rulings in
`build/plan/ship/RULINGS.md` bind waves 7-10 and nothing waits for a person. **Wave 7, "The fight reads", landed
2026-09-15** (7/7): the prep band shows the party it chalks; the fight's picture is lit, spread and given its
arena by kind; the report says why it wiped and offers Try again; every named mistake has its consequence; one
v17 save bump and the format is frozen; five ambience beds through one door; docs/08 §8.8 publishes the one
mistake equation the tree runs. Next: 8 "The numbers are ruled" · 9 "Tiers and finish" · 10 "Release".
**Work list:** `build/plan/audit.json` is the queue (W7-DOCS's close, 2026-09-15: **136 done, 39 open, 15
blocked on a designer**); `python tools/audit_stale.py --top 15` FIRST, then READ THE FILE BEFORE THE AUDIT ENTRY
(an entry written before the work is not evidence of what is missing now). `build/plan/artaudit/00-plan.md` §6
holds the 18 art questions; the ship plan's §6 folds them into its 68 rows.
**The designer's page:** `build/plan/ship/designer-page.md` — every unanswered question (the plan's §6) with ONE
ship default and an answer line each. **The wave-10 ship rule:** a row still unanswered by the wave its "Needed
by" names is taken at that default BY THE UNIT §6 NAMES, in writing (a `docs/15` row marked "taken under the
wave-10 ship rule"), never silently. That rule is what gives W8-SIM-BALANCE the authority to size A1-A3 and the
tutorials for morale 45 (§6 #1, default (c), docs/08 §9.3's formula with the mechanic term) if the page is not
back by wave 7's close — and what forbids every other unit touching that number.
**Build status:** 🟢 GREEN — `./tools/verify.sh` (ten stages, listed in HANDOFF 1) passing at **2,131 tests** at
the wave-6 close (art gate flat, 14 sheets); stage 8 (latency) stays WARN by design with its budget stated here: mount ≤ 140 ms warm, frame
≤ 16.6 ms on the reference laptop boosting (calibration loop ≤ 10 ms), PERF OK on all 14 screens;
`./tools/with_godot_lock.sh ./tools/diff_all.sh` scores 14 targets (a unit's rule is "does not regress").
**The balance sweep** (`tools/balance_sweep.gd`) walks 288 cells — 8 slots (A1-A3, E1-E5) x 4 gear stages x 3
rarities x 3 morale bands — at 8 seeds by default: **2,304 runs** per gate; `--drift` runs 500 seeds against
`tests/baselines/sweep_baseline.csv` (stage 6b from wave 6; `--rebaseline` only in a SIM wave's RaidSim unit).
**How a wave runs:** one agent per unit under an ownership table, writing `build/plan/report-<KEY>.md` as it
goes and `build/plan/handoff-<KEY>.md` for files it does not own; a brief review per unit (the user's rule,
2026-09-14: one look that the new thing shows, its own test, move on); the orchestrator applies handoffs, runs
the gate, the sheets and the diffs, commits per unit. Restarts have killed runs twice; the reports on disk resume them.

**`M6-BAL-04` — the Tier 1 campaign was not completable, and it is now RULED, not open.** `tools/playtest.gd`
walks it and stops: a new guild is pinned at morale 45 by `docs/05` §8's baseline, so six of eight guilds stop at
A2. Lever (c) is taken under the delegation — the on-ramp re-sized by docs/08 §9.3a's healed clock at stage 0,
all-Common, morale 45; W8-SIM-BALANCE applies it, and no encounter is softened to make the playtest green.

**Watch:** the record wall is live — a mutation path that does not go through `autosave()` must call
`check_achievements()` itself. Tier 1 got harder under BL-71 (corrected arithmetic, not a regression).

### The art directive that overrides the mockup-matching instinct

The designer's ruling, 2026-09-11, verbatim: *"To aid you in refining how the graphics should ACTUALLY
look rather than blindly matching the mockups references and keeping in things in the background like
static rendered dialog and unanimated characters, I have provided bare backgrounds to use in the game
frame that we can then render beautifully sliced/animated assets and effects over and on top of."*

So: the reference concepts still set the **quality bar** (see `[[reference-concepts-are-a-standard]]`), but a
screen never sits on a crop of a mockup with painted people or baked bubbles, numbers or pills. Every screen
stands on one of the six bare plates in `game/assets/bg/` — the plate per screen, its source and its framing
switch are `art/ref/specs/09-background-plates.md` §3 and `art/ref/specs/00-canon-reconciliation.md` §2.7 (the
crops are deleted, waves 2 and 5). Over the plates is `game/ui/SceneStage.gd`, data-driven from
`game/assets/scenes/<name>.json` (`from_data()` is the seam the tests build through; spec 09 §4 lists the
animated layers per plate; `tools/art/preview_scene.py` composites the same stack in PIL).

---

## HANDOFF — read this first in a new session

1. `./tools/verify.sh` — must be green before anything else. Ten stages: lint (class_name + motion +
   hex), parse, generated content vs its generator, generated art vs its generators (2b), unit tests,
   headless boot, keyboard access (`tests/unit/a11y_smoke.gd`), balance sweep, the campaign playtest
   (WARN-only, because the campaign is not completable — see `M6-BAL-04`) and the latency probe
   (WARN-only). If it fails, fixing it is the *only* task for that iteration.
2. **Route every Godot invocation through `tools/with_godot_lock.sh`.** Two engine processes in this
   project corrupt `.godot/` and `user://`; the symptom is a *save* test failing in a run that never
   touched saves. Orphan cleanup: `taskkill //F //IM Godot_v4.7.1-stable_mono_win64_console.exe`
   then `rm -rf .godot_engine.lock`.
3. `./tools/run_game.sh` plays the real game in a window; `./tools/export_build.sh --dev` builds a
   playable .exe; `./tools/diff_all.sh` scores converted screens against their concepts.
4. Read this file, then `BACKLOG.md`, then `build/plan/audit.json`. They are the memory; recollection is not.

**What is playable end to end today.** New Guild → Adventure's Board → Raid prep (chalk a party, read
the risk readout, chalk provisions) → Depart → the encounter plays out line by line → Results with loot,
gold and the wipe report → town. Guildhall (roster, rest, facilities, quarters, Records), Market (sell
with the worn-by confirm, buy-back shelf, six consumables, comfort items), Tavern (candidate board, hire,
dismiss, paid reroll), Raider detail (paper doll, morale sparkline), Load/Save with a damaged-slot
readout, versioned saves (v16) with autosaves and Continue, audio (a fourth autoload, `game/core/Audio.gd`),
keyboard navigation, a colour-safe morale option (landing in wave 6), and the three tutorials. S17, the ending, is built and reachable but not yet REACHABLE IN PLAY — it
fires on the first clear of the last tier, and tier 5 does not ship until it is named (BL-69).

**The three gaps between this tree and a shipped game — none of them a build-loop task:**
1. **Tiers 2-5 content.** The eight generated tier tables are unnamed (`stats_pending`/`name_pending`, BL-69) and
   the eight Legendaries `docs/03` §5.6 forbids naming; `ContentDB.load_all()` mounts only named tiers, so the
   campaign ends at tier 1 and S17 cannot fire in play. `./tools/export_build.sh` holds on exactly these 16
   files — the gate clears when a designer supplies names, never by editing the gate.
2. **The tutorials and Tier 1 as authored.** The Tutorial Raid is unwinnable, A3 is a wall (pinned below) and
   the campaign is not completable (`M6-BAL-04`, above). Every fix moves a canon number.
3. **Ship tooling.** `export_build.sh` is green with `--dev`; what it waits on is rulings, chiefly `docs/15`
   **Q-53** (are attempts limited, can the player quit mid-sim — the save-scum surface and what `SimState`
   serialises), built at its recommended default and awaiting the signature (page row #6), and **Q-29** (does a
   recruit's rolled gear price the recruit), NOT implemented — `Recruitment.cost_of()` has no gear term; the
   surcharge lands in W8-ITEMS behind `GEAR_SURCHARGE_BP` under page row #7. The recruit price itself is doc 11's
   from wave 6 (`Recruitment.PRICE_SCALE`, BL-94: a Common is 15 G).

**The two content defects that are deliberately PINNED, not tuned.** `docs/15` records exactly one
number ever changed on judgement alone (BL-29) and the bar is that there stays one. Both of these are
held by tests that assert the *measured* failure so that fixing them is a visible, deliberate act:
- **A3 is a wall:** `test_adventures.gd` pins a 0.0 clear rate (measured: no mechanics 24/24,
  m01 only 0/24, m02 only 3/24, m03 only 9/24).
- **The Tutorial Raid is unwinnable:** `test_tutorials.gd` pins 0 clears in 20 (as authored 0/20,
  without m01 13/20, with the swing cut 15→10 10/20).
Both trace to the same cause: canon prices a boss swing against the autoattack alone, then adds M01,
which multiplies it by 2.5. The fix is a designer ruling (audit `M6-BAL-03`, register `Q-` row), not a nudge.

---

## Binding decisions (from `docs/15-open-questions.md` §9)

The decision register resolved six questions that shipped documents were answering
two or more ways. **Implement these; do not re-derive them.** Each links to its owner.

| # | Ruling | Where it binds |
|---|---|---|
| Q-01 | **AC is a diminishing-returns curve:** `mitigation = (AC*2) / ((AC*2) + AC_K)`, `AC_K = 60`, clamped at `MITIGATION_CAP = 0.75`. Keeps canon's `x2` literally in the numerator. | `sim/core/Formulas.gd` — default value of the AC switch; keep R1/R1b/R2 selectable |
| Q-01r | **Raid-wide and spell damage ignore AC**, so encounter pressure lands on healer throughput | `Formulas.gd`, encounter data |
| Q-02 | **Mana stays a magnitude stat** (spell damage *and* healing). Add a class-fixed **Focus** resource that never appears on gear ("Model A+"). | `Formulas.gd`, healer kits, `data/classes.json` |
| Q-04/05 | **`docs/08` §8.8 owns the mistake equation and all coefficients**, importing `docs/05`'s per-rarity `sensitivity`. The roll is **per raider per mechanic event**, not per round. | `sim/core/Mistakes.gd` |
| Q-09 | **No mid-raid player input.** No "Calls". The raid resolves on the roster, gear and morale it started with. | `sim/core/RaidSim.gd`, `game/screens/RaidView` |
| Q-06/07 | **Morale bands are half-open, lower-inclusive:** `band_index = min(9, floor(morale / 10))`. Rename the second "Very Happy" (70–80) to **"Quite Happy"** so the ten bands have ten names. | `sim/core/Morale.gd` |
| Q-15 | **Godot >= 4.3, renderer = Mobile.** Compatibility supports neither 2D glow nor `hdr_2d` and would delete four of the eight ingredients of the 2D-HD look. Forward+ is the fallback only if an effect proves Forward+-only. | `project.godot` (applied), `docs/14` §2.5, README |

---

## Invariants — never break these

1. **The build is always green.** `./tools/verify.sh` must exit 0 before every commit. If it fails, fixing it is the *only* task for that iteration.
2. **`sim/` is pure.** No `Node`, no `SceneTree`, no `await`, no timers, no rendering, no global RNG inside `sim/`. It is a deterministic function of `(roster, gear, encounter, seed) -> event log`. `game/` may import `sim/`; `sim/` may **never** import `game/`.
3. **Canon is canon.** Numbers come from `docs/_source/lead-designer-notes-raw.md` and `docs/_source/ideaboard-transcription.md`. Never "improve" a canon value. If canon is silent, implement the design doc's proposal and note it.
4. **Read the doc before building the system.** `docs/NN-*.md` owns each system. Never implement from memory.
5. **No stubs left behind.** A ticked task means working, tested code — not a placeholder. If a task must be split, split it in the backlog rather than half-doing it.
6. **Every iteration commits.** Small, clear, reviewable commits.
7. **Never reference another script's `class_name`.** Inside `sim/` and `game/`, use
   `const Other = preload("res://.../Other.gd")`. Godot's global class registry is not
   reliably present in headless runs; `tools/lint_no_global_classes.sh` enforces this.
8. **Never use a `class_name` identifier in code — not even the file's own.** It does
   not resolve inside static functions in headless runs. Use `const X = preload(...)` for
   other scripts and the `_cls()` self-load helper for self-construction.
9. **Seeded RNG only.** `sim/core/Rng.gd`, injected. Never `randi()` / `randf()` inside `sim/`.

---

## Key commands

```bash
# EVERY Godot invocation goes through the mutex. No exceptions, no "just this once".
./tools/with_godot_lock.sh ./tools/verify.sh          # the ten-stage gate (see HANDOFF above)
./tools/with_godot_lock.sh ./tools/verify.sh --fast   # stages 0-3: lint, parse, generated content, tests
./tools/with_godot_lock.sh "$GODOT" --headless --path . --script res://tools/playtest.gd
./tools/with_godot_lock.sh "$GODOT" --headless --path . --script res://tools/balance_sweep.gd -- --drift
./tools/with_godot_lock.sh "$GODOT" --headless --path . --script res://tests/run_tests.gd
./tools/build_art.sh --gen   # re-run every Lua generator (sources + PNGs); --check byte-compares them (verify stage 2b)
./tools/export_build.sh      # the Windows build: export, launch check, ship gate (holds on `stats_pending`/`name_pending` content)
./tools/export_build.sh --dev   # the same build stamped NOT SHIPPABLE, so a playable .exe exists before the content is named
./tools/run_game.sh          # launch the game windowed (manual look)
./tools/diff_all.sh          # shoot every converted screen and score it against its concept
./tools/shot_all.sh build/shots/all --sheet=all   # every screen on every sheet (fixture, focus, text150, tabs, ...)
python tools/audit_stale.py --top 15              # rank open audit items by how much of what they name already exists
python tools/art/slice.py cut --manifest art/ref/manifests/all.json --out art/export
```

Read `LESSONS.md` before editing UI layout, GDScript typing, a test or a tuning number. Every entry in it
cost time at least twice.

## Key paths

- `ideaboard/Reference Concepts/*.png` — the visual target, 1:1 at 1536x1024. Reference anything visual against these.
- `art/ref/specs/00..11` — the measured specs (canon reconciliation, per-concept layouts, palette, type, component kit, asset inventories, backgrounds, screen audit, engine architecture).
- `art/ref/manifests/all.json` — 721 sprite rects; `python tools/art/slice.py cut --manifest ... --out art/export`.
- `game/ui/` — `Palette` (tokens), `Fonts`, `Type` (the scale), `Theme` (one Theme, built in code), `Widgets` (the kit), `Frame` (the dashboard shell), `Cards` (roster card, strip, event log), `Bar`, `Badge`.
- `./tools/diff_all.sh` — shoot every converted screen and score it against its concept.

| Thing | Path |
|---|---|
| Godot 4.7.1 (console build, use for CLI) | `/c/Users/greyp/AppData/Local/Programs/Godot/Godot_v4.7.1-stable_mono_win64/Godot_v4.7.1-stable_mono_win64_console.exe` |
| Aseprite | `./Aseprite/Aseprite.exe` (headless: `-b --script foo.lua`) |
| Shared tool env | `tools/env.sh` |
| Design docs | `docs/00-*.md` … `docs/16-*.md` |
| Canon source | `docs/_source/` |

---

## Architecture at a glance

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
```

---

## Environment notes

- Godot **4.7.1-stable-mono**. Export templates installed → real Windows builds are possible.
- Project uses **GDScript** (not C#) — no compile step, fastest loop iteration.
- Aseprite **Lua scripting works headless** (verified). This is the art pipeline.
- The `plugin:pixel-plugin:aseprite` **MCP server** was fixed 2026-09-13 (a renamed-folder path; ~50 tools) and still fails to connect in some sessions — never a build dependency (docs/12 §7.5). Use the CLI.
- A `godot-mcp` exists at `~/AppData/Local/Programs/mcp/godot-mcp` but is **not** connected this session. Use the CLI.
- Project is a git repo (initialized this session). Commit every iteration.

---

## Recent progress

Newest first, one line each. **The full history is `docs/_log/progress.md`** — older entries move there.

- (2026-09-15, wave 7) The fight reads: the prep band, the arena by kind, the wipe's cause on the report,
  mistake consequences and healer threat, save v17 frozen, five ambience beds, docs/08 §8.8 published.
- (2026-09-15, wave 6, W6-LEDGER) 47 audit rows closed against HEAD, 12 filed (120/53/17); docs/15 BL-82..106 +
  Q-97..99; `Recruitment.PRICE_SCALE = "doc11"` (a Common is 15 G); the credits' derivable block; the designer's
  page. BACKLOG's "screen shake on wipes" struck under page row #43 (docs/13 §11.4/§12.2; the stamp is the beat).
- (2026-09-15, wave 6 close) 2,131 tests; the copy lint and the drift gate in the gate; art gate flat; 14 sheets.
---

## Open risks the loop should watch

- **The A3 / Tutorial-Raid balance is RULED, not guessed** (Q-100, under the 2026-09-15 delegation): the
  curve, the bands and the correction rule are written down, and the rows that were blocked on a person are
  answered in `build/plan/ship/RULINGS.md`. A default is still taken only in writing, under the ship rule above.
- **`build/plan/` is tracked and is the loop's memory; the rest of `build/` is scratch.** Clean `build/` by
  subfolder, never whole (2026-09-14: the whole of `build/` was deleted through Explorer mid-wave — the log's
  ART WAVE 3 entry has the recovery). `build/exports/AGuildStory.exe` is gone until `./tools/export_build.sh --dev`.
- **The working copy is still on OneDrive.** Sync plus Godot's generated `.godot/` can produce file locks
  and import corruption. `.godot/` is gitignored and regenerated and `verify.sh` would catch breakage, so
  this is an accepted risk rather than a unilateral move of the user's project directory. **Flag it.**
- **Renaming the repo FOLDER is deliberately deferred.** The rename of the project and game is complete;
  renaming the working directory would break this session, every tool path and any running loop.
- **Art volume is the dominant cost.** Prefer procedural / scripted generation with a shared palette over
  hand-placing pixels, and prefer extending `SceneStage` over one-off screen code.
- **Do not let a screen's presentation outrun the sim.** The UI is a log player; `sim/` stays pure.
