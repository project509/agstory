# Proposed `docs/15-open-questions.md` entries — housekeeping agent

Do not paste blind; these are drafts for the orchestrator to merge. Numbering is
left blank because another agent may be claiming the next free Q number.

---

## Q-__ - Does `build/` carry a `.gdignore`, given that `build/atlas/` is meant to be consumed? *(PROPOSED - yes, with a documented move condition)*

**Owner:** [14 §4](./14-technical-architecture.md) / [14 §10.2](./14-technical-architecture.md) - **Signal:** Loud the first time an atlas is loaded

[14 §4](./14-technical-architecture.md) lists the directories that must carry a
`.gdignore`: `Aseprite/`, `ideaboard/`, `docs/`, `content_src/`, `art/_ref/` and
`art/`. `build/` is **not** on that list. But [14 §10.2](./14-technical-architecture.md)
makes `build/atlas/` the single atlas output path "for the whole project", i.e.
the one thing under `build/` the game is supposed to consume — and §4's list was
written before the scratch directory existed.

Measured on this tree: `build/` holds 181 files and 76 MB, of which 158 were
importable PNGs with `.import` siblings already generated, and **nothing under
`game/` loads from `res://build`** (`grep -rn "res://build" --include=*.gd
--include=*.tscn` returns zero). The shipped art all lives in `game/assets/`,
written there by the art pipeline rather than read out of `build/`.

**Proposed decision: `build/` carries a `.gdignore`, and the condition for
moving it is written down.** If a later art task starts loading
`res://build/atlas/*` at runtime, the marker moves *down* into the scratch
siblings (`build/plan/`, `build/shots/`, `build/diff/`, ...) rather than being
deleted — the 76 MB of scratch is the thing being kept out of the `.pck`, not
the atlas.

**Why not leave it off.** Every one of those 158 PNGs would ship inside the
export from any working copy that has run the art tools, which is every
developer's. §4's own rationale ("real import-time and export-size cost that
§11's atlas/VRAM budget does not otherwise account for") applies to `build/`
more strongly than to anything already on its list.

**Enforcement:** `tests/unit/test_project_hygiene.gd::test_only_game_assets_are_imported`
fails if an `.import` file appears anywhere outside `game/`, which is the
symptom rather than the marker, so it catches the marker being removed *and* the
marker being put in the wrong place.

---

## Q-__ - What is the application icon, and is an `.ico` owed for 1.0? *(PROPOSED - the emblem now, `.ico` deferred - LANDED by W0-SPLASH, see docs/15 BL-67)*

**Owner:** [12](./12-art-direction.md) owns the look / [14 §10.1](./14-technical-architecture.md) owns the export - **Signal:** Quiet, and cosmetic

`project.godot` shipped with `config/icon="res://icon.svg"` — the path the Godot
template writes, never replaced, and there has never been a file behind it. No
doc specifies an application icon: doc 12 names sprite, UI and palette work but
no icon, and doc 14 §10.1's export table does not mention one.

**Proposed decision: `config/icon="res://game/assets/ui/emblem.png"`.** The
emblem is the game's own authored mark — the one the Home lockup draws
(`art/ref/specs/01 §5`, `game/ui/Frame.gd`) — it is already shipped under
`game/assets/`, and it is in the shipped palette. The alternative the audit
offered was to generate a fresh 256x256 icon; that would be **inventing art the
docs do not specify**, which the project rule forbids, and it would put a second
mark in circulation next to the one the game actually wears.

**What this does not fix.** `emblem.png` is 82x57 and not square: Godot scales it
for the window and the project list, so it reads small. The Windows `.exe`'s own
resource icon needs a real `.ico`; with only a PNG, Godot gives the window the
PNG and leaves the engine default on the `.exe` in Explorer.

**Proposed: the `.ico` is deferred, not dropped** — it is a packaging asset, it
needs a square source at 16/32/48/256, and it is worth exactly one art task once
someone has looked at the emblem at 32px. Recorded here so the next export pass
does not discover it as a surprise.

**Enforcement:** `tests/unit/test_project_hygiene.gd::test_project_icon_resolves`
asserts `application/config/icon` names a file that exists, so the phantom path
cannot come back.

---

## Correction owed to the existing Q-43 (not a new question)

`docs/15-open-questions.md` Q-43's closing section still reads:

> Neither the Market (S06) nor Raider Detail (S05) exists yet.
> [...] The full slot view OQ-4 asks for is built - it just lives on the
> Facilities tab until S05 exists.

Both sentences are now false. S05 exists as `game/screens/RaiderDetail.gd`, is
routed from `game/screens/Roster.gd:36`, is tested by
`tests/unit/test_raider_detail.gd`, and carries the full slot view
(`RaiderDetail.gd:16` says so in its own header). `Roster.gd:498-520` carries
OQ-4's quick-apply, and `RaiderDetail.gd:326` repeats it. The **ruling** — buying
and placing are ONE action, `GameState.buy_furnishing(id, raider_id)` — is
unchanged and is still what `game/screens/Facilities.gd:397` does.

Proposed replacement for the "What is still owed to 13 OQ-4" paragraph:

> **What 13 OQ-4 asked for is now built on both sides:** `Roster.gd`'s row
> carries the quick-apply (a 2-click morale repair) and S05 Raider Detail carries
> the full slot view. The Facilities tab keeps its own quarters column because
> [02 §4.5](./02-town-and-buildings.md) specifies one there, and because this is
> where the one-action ruling above lives — the furnishing buttons print the
> price and call `buy_furnishing`. The Market's Comfort tab (S06) is still a
> second entry point to the same verb and still unbuilt.

`game/screens/Facilities.gd:16-21` has already been corrected to match.
