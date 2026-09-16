# Handoff — W3-RAIDVIEW2 (key `W3-RAIDVIEW2`)

Edits needed in files this unit does not own. Shape: `## N. <path>:<line>` then an `old:`
block and a `new:` block, one edit per heading. Observations (no edit) are labelled as such.
Nothing here is applied by the unit.

## Observation (no edit) — W3-ENEMIES / orchestrator: one joke plate at a time on the stage
handoff-W2-RAIDVIEW observed three joke bubbles in ten lines overlapping (say_at keeps one plate per
SPEAKER; three mistakes by three raiders inside one 2.4 s hold stack three 196px plates over a 64px-pitch
formation). Still true after this wave (build/shots/W3RV2_story10_x2.png: three plates over the front rank).
The screen calls `say_at` once per joke and has no door to drop another speaker's plate; the rule belongs to
the stage — `say_at` could retire the previous speaker's plate when a new one lands (one bubble at a time),
or take an `opts.solo` flag RaidView passes. SceneStage.gd is W3-ENEMIES' this wave, so no edit is written
here; RaidView needs no change either way.

## Observation (no edit) — orchestrator: build/plan/ vanished from the working tree at ~22:13-22:16
Every tracked file under build/plan/ (108) and build/.gdignore showed as ` D` in `git status`; build/shots/
was untouched. This unit restored the 109 tracked files from HEAD with `git show` (no checkout/reset/clean;
script: build/shots/w3rv2_restore_plan.py). Untracked wave-3 report/handoff files written before that moment
are gone unless their units rewrote them (W3-ENEMIES' handoff was re-created at 22:16:49; this unit's two
files were rewritten at 22:17). Worth a look at which agent's script ran an `rm` over build/.
