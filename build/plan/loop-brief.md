# THE AUTONOMOUS LOOP BRIEF — A Guild Story

The cron job fires this. One firing = **one iteration**. Do not ask the user anything; a question that
must be answered by a human becomes a written `docs/15` entry and the item moves to blocked.

## Each iteration, in order

1. **Orient from files, never from recollection.** Read `BUILD_STATE.md` (current focus, art directive,
   handoff), then the open boxes in `BACKLOG.md`, then `build/plan/audit.json` — the authoritative queue.
   `git log --oneline -5` and `git status --porcelain` tell you whether the last iteration landed cleanly.
   **READ THE FILE BEFORE THE AUDIT ENTRY.** Thirteen open items were found already finished in one week
   — the work had landed inside other items and nobody walked back to the plan — and twice that cost the
   PICK, not just the orientation. `python tools/audit_stale.py --top 15` ranks open items by how much of
   what they NAME already exists. A hit is a suspicion, never a verdict: the false positive is an item
   whose premise is "this exists but nothing calls it". Confirm in the tree, then close it as you go.
2. **If the working tree is dirty, finish or revert that work before starting anything new.** A
   half-applied edit from a killed iteration is the single most expensive thing in this project's history.
3. **If the gate is red, fixing it is the ONLY task for this iteration.**
   `./tools/with_godot_lock.sh ./tools/verify.sh --fast`
4. **Pick ONE item you can finish completely in this iteration.** Prefer, in order:
   a. anything that unblocks several other items (the `SceneStage` actor layer is the current example);
   b. `partial` items over `not-started` ones — a half-built system is a liability;
   c. small/medium over large, unless a large one is the thing everything else waits on.
   **Never pick a `blocked-needs-human` item** except to write its `docs/15` question properly.
5. **Build it. Completely.** Code, tests, data, and the doc edit if a doc was wrong. No stubs, no TODOs
   left as the deliverable, no "wired but untested".
6. **Gate, then commit.** `--fast` at minimum; the full six-stage gate every third iteration and always
   before a commit that touches `sim/`, tuning, or content data. One item per commit, message in this
   repo's voice (lower-case, what changed and what it cost), ending with the Co-Authored-By line.
7. **Update the memory files last:** tick the box in `BACKLOG.md`, set `actual_status` in
   `build/plan/audit.json`, add one line to `BUILD_STATE.md`'s progress list, and move the oldest entry
   to `docs/_log/progress.md` if the list is past ~12. Keep `BUILD_STATE.md` under ~250 lines.
   Append anything learned the hard way to `LESSONS.md`.

## The rules that are load-bearing (each was learned by breaking it)

- **Every Godot invocation goes through `tools/with_godot_lock.sh`.** Two engine processes corrupt
  `.godot/` and `user://`; the symptom is a *save* test failing in a run that never touched saves.
  Orphans: `taskkill //F //IM Godot_v4.7.1-stable_mono_win64_console.exe` then `rm -rf .godot_engine.lock`.
- **Never leave the tree unparseable, not even for one edit.** Write the function before the call site.
  Parse-check after each file, not at the end of the iteration.
- **Indentation is per-file and Godot rejects mixing.** `sim/`, `game/core/`, `game/screens/RaidPrep.gd`
  use FOUR SPACES; `game/ui/` and most of `game/screens/` use TABS. Match the file you are editing and
  re-read the inserted block afterwards.
- **Canon is canon.** Numbers come from `docs/_source/` and the owning `docs/NN`. **Never invent a
  number, a rate or a name.** If canon is silent or contradicts itself, implement the reading the owning
  doc proposes, put the ambiguity behind ONE named switch with both readings under test, and file a
  numbered `docs/15` entry. `docs/15` records exactly one number ever changed on judgement alone
  (BL-29) and the bar is that there stays one.
- **`docs/15` has two registers**: `Q-nn` = design questions awaiting the designer, `BL-nn` = this
  loop's rulings. They overlap on 19-67. A citation naming the wrong register is worse than no citation
  and `tests/unit/test_docs_links.gd` fails on it.
- **Two balance defects are PINNED with measurements, not tuned**: A3's 0/24 clear rate
  (`test_adventures.gd`) and the Tutorial Raid's 0/20 (`test_tutorials.gd`). Do not "fix" either by
  moving a number. They need a designer ruling (audit `M6-BAL-03`).
- **`sim/` is pure**: no clock, no scene tree, no unseeded randomness, no `game/` imports. SHA-256
  goldens assert it. Regenerate a golden only deliberately, with the reason in the commit message.
- **Read `LESSONS.md` before editing UI layout, GDScript typing, a test, or a tuning number.**

## The art directive (2026-09-11, the designer's own words)

*"To aid you in refining how the graphics should ACTUALLY look rather than blindly matching the mockups
references and keeping in things in the background like static rendered dialog and unanimated characters,
I have provided bare backgrounds to use in the game frame that we can then render beautifully
sliced/animated assets and effects over and on top of."*

So a screen may no longer sit on a mockup crop carrying painted people, baked speech bubbles, baked
damage numbers or label pills. Six bare plates are installed as `game/assets/bg/stage_*.png`; the
figures and effects are ours, rendered and animated over them by `game/ui/SceneStage.gd` (which needs
an actor layer — see `BACKLOG.md` M4b). `art/ref/specs/09-background-plates.md` §4 is the build order.
The reference concepts still set the **quality bar**; where their UI does not fit the design, the design
wins.

## The quality bar (the designer's words, same message)

*"Everything must be worked at an exceedingly high quality standard as if working on shippable quality
content, and polished to a reliable working perfection."*

Which in this project means: it runs, it is tested, it is committed, the gate is green, and the next
iteration can find it from the files alone.
