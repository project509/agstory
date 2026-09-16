# Handoff — housekeeping agent (M6-EXP-03, M6-EXP-04, M6-FINAL-02, m4t-13)

Changes I could not make because the file is not mine this wave. Each one is
verified, not guessed; file:line is where the edit goes.

## 1. `docs/.gdignore` — DONE in the repair pass (M6-EXP-03)

`docs/14-technical-architecture.md:312` names the required set as `Aseprite/`,
`ideaboard/`, `docs/`, `content_src/`, `art/_ref/` and `art/`. The tree now
carries `art/`, `ideaboard/`, `Aseprite/`, `build/`, `docs/` and `.godot/`, so
M6-EXP-03's list is complete. `content_src/` and `art/_ref/` do not exist, so
they are not owed.

The marker is 0 bytes like its four siblings, is not covered by any `.gitignore`
rule (`git check-ignore docs/.gdignore` exits 1, `git status` shows it
untracked), and `"docs"` is now in `MUST_NOT_IMPORT`, so
`test_scratch_trees_carry_gdignore` guards it. It changes nothing for the suite:
`.gdignore` stops the importer, not `FileAccess`, and `test_docs_links.gd` still
reads all eighteen `.md` files with the marker in place — verified by a full
green run after adding it.

## 2. `BACKLOG.md:176` — "remove dead code" is now answered, not open

`tools/probe/diag.gd` and `tools/probe/diag.gd.uid` are deleted (M6-FINAL-02).
The audit's own note records that this was the entire provable surface and that
the TODO/FIXME/HACK/XXX grep across `game sim tools tests data` returns zero.
The backlog line should say so, or a later loop goes hunting for dead code that
is not there. I do not own `BACKLOG.md`.

## 3. `BUILD_STATE.md` "Current focus" (lines 9-11) is stale

m4t-13's `remaining_work` names it: it still says "Foundation, UI kit and the
Town screen are on the reference frame; 15 screens remain" and points at build
order step 1 = RaidPrep, both untrue since `BACKLOG.md:122-131` ticked all
eleven screens. Not my file.

## 4. The three stale art comments outside my files — m4t-13 IS NOT CLOSED

m4t-13's `files_to_touch` is `RaiderDetail.gd`, `Results.gd`, `Frame.gd`,
`tools/art/make_portraits.py`, `BUILD_STATE.md`, and **none of the five is mine
in either wave**, so none was touched. The four comments I did rewrite are in
`Cards.gd`, `RaidView.gd` and `Facilities.gd` — the same defect, different lines.
Leave the item open.

What the repair pass could do without owning the files: the three verified rows
are now in `LIES_OWED` in `tests/unit/test_project_hygiene.gd`, and
`test_comments_owed_a_rewrite_are_still_owed` asserts each phrase is STILL
present. The day the owner rewrites one, that test fails and names the row, so
the fix is finished by moving the row into `LIES` (where it becomes a permanent
guard) rather than by leaving the file unguarded. Whoever holds these files can
close m4t-13 in one commit: rewrite the comment, promote the row.

Still lying, all verified again in the repair pass:

- `game/screens/RaiderDetail.gd:461` — "the icon art is the reference's gear
  placeholders until the item sheet lands", but `:464` calls
  `Cards.gear_icon(slot, true, worn)` and `game/ui/Cards.gd:341-366` resolves
  real per-slot, per-material art.
- `game/screens/Results.gd:499` — "the reward glyph is a placeholder by index
  until item art exists", same call at `:506`.
- `game/screens/Results.gd:53` — "09 §3.3's full-bleed cleaned arena is not
  authored yet"; I did NOT verify this one, it may still be true.
- `game/ui/Frame.gd:173-174` — "the emblem sprite is not authored yet", but
  `game/assets/ui/emblem.png` exists at 82x57, exactly the rect `:180-181`
  places it at.
- `tools/art/make_portraits.py:1` — docstring claims it regenerates class glyphs
  it does not write (m4t-01).

## 5. `docs/15-open-questions.md` Q-43 (line ~1867) is stale in the same way

Its closing paragraph reads "Neither the Market (S06) nor Raider Detail (S05)
exists yet" and "The full slot view OQ-4 asks for is built - it just lives on
the Facilities tab until S05 exists." S05 exists (`game/screens/RaiderDetail.gd`,
routed from `game/screens/Roster.gd:36`, tested by
`tests/unit/test_raider_detail.gd`), it carries the full slot view, and
`Roster.gd:498-520` carries OQ-4's quick-apply. The ruling itself (buying and
placing are ONE action) is unaffected and still what `Facilities.gd:397` does —
only the "what is still owed" paragraph needs correcting. I did not edit
`docs/15` per the wave rule; the proposed replacement is in
`build/plan/q-housekeeping.md`.

## 6. `game/screens/RaidView.gd:622-624` is now unreachable for canon classes

```gdscript
var by_class := PORTRAIT + "class_%s.png" % Enums.class_key(raider.class_id)
if ResourceLoader.exists(by_class):
    return load(by_class)
```

`Cards.portrait_for` already tries exactly this path one call earlier, so this
block can only fire for a class Cards does not answer — which, now that the five
missing busts are authored, is none of the nine. It is harmless and I corrected
only the comment above it, because RaidView is owned by the comedy-pipeline agent
this wave. Deleting the three lines is a one-line-net cleanup for whoever holds
the file next.

## 7. `export_presets.cfg` when M6-EXP-01 writes it

`project.godot:8` now reads `config/icon="res://game/assets/ui/emblem.png"`.
The preset's `application/icon` must be set to the same path or the export
silently disagrees with the project. The Windows executable's own resource icon
wants an `.ico`; a PNG gives the window its icon and leaves the engine default on
the `.exe` in Explorer. See `build/plan/q-housekeeping.md` for the proposed
ruling on whether that `.ico` is owed for 1.0.
