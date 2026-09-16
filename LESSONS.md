# ENGINE & BUILD LESSONS

> Split out of `BUILD_STATE.md` on 2026-09-11 to keep that file inside its own length rule.
> Every one of these cost time at least twice. Read this before touching Godot layout, GDScript typing, tests or a tuning number.

## GDScript gotchas that have cost time twice

- **Containers re-lay whatever is put straight into them.** `Widgets.panel()`'s content is a MarginContainer ("Pad"); children positioned by coordinate inside it pile up at the margin, and `PanelWarm`'s StyleBox adds its own 14px content margin under the Pad's 18. Place coordinate-driven children in a plain Control nested INSIDE the Pad (and offset that inner Control, not the Pad's child — the Pad re-lays its direct child). Found by cross-correlating edge profiles against the concept: a constant +14/+14 drift.
- **A Control anchored `PRESET_FULL_RECT` inside a `SubViewport` parented to the Window resolves its anchors against the *window's* canvas, not the SubViewport.** In `tools/shot.gd` that made the screen root 4608x3072 instead of 1536x1024, so every region placed relative to the RIGHT edge (header chips, the whole sidebar) sat ~2400px off-screen. It is invisible in a screenshot and the missing nodes report perfect `get_rect()`, `get_global_rect()`, `visible_in_tree`, z-index and child counts. **When UI is blank but measures correct, print the screen root's real `size` first.** Fix: `PRESET_TOP_LEFT` plus explicit `position`/`size`.
- **`Frame.gd` places every region explicitly rather than by anchor**, for the same reason: `anchor_left == anchor_right == 1.0` lays out correctly and paints nothing. `tools/probe/Chips.tscn` isolates both cases; do not "tidy" that file back into anchors.

- **Never use `:=` on the result of a sim method that returns an object.** Those returns
  are untyped (see invariant 8), so inference fails and this project treats the warning
  as an error. Write `var x: int = c.heal(20)` or plain `var x = ...`.
- `quit()` in a `SceneTree` script REQUESTS a quit; execution continues. Always `return`
  straight after it.
- Godot's global class registry is unavailable in headless `--script` runs unless
  `.godot/global_script_class_cache.cfg` is fresh. `verify.sh` regenerates it.

- **The Bash tool collapses `\\` to `\` inside heredocs**, even quoted ones. A Python patch script whose anchor contains a GDScript line-continuation therefore arrives with a *single* backslash, which Python then reads as a line continuation and silently joins the lines — so the anchor never matches and the edit no-ops. This cost two failed passes. **Write patch scripts with the Write tool**, or build the character with `chr(92)`. Line-index splicing beats text anchors for any file containing backslashes or curly quotes (`BACKLOG.md` uses curly apostrophes).
- **A lookup that returns a default for a missing key will eventually be read as data.** `balance_sweep._cell()` returned `{clear_rate: 0.0, ...}` for a cell the grid never swept; asking it for morale 65 (the grid runs 15/55/95) printed "0% clear, median 0 rounds" in the findings block, indistinguishable from a real measurement. Prefer failing loudly over a plausible default anywhere a value becomes a reported number.

- **The unit-test runner redirects saves but not settings — and any instrument that applies the fixture writes a real autosave.** `tests/run_tests.gd` pointed `SaveGame.SAVE_DIR` at a test dir while `GameSettings` still saved to the real `user://settings.cfg` on PREDELETE, so every `verify.sh` run overwrote the developer's options with the last test's values (text_scale 100, reduced_motion true); `tools/playtest.gd` and `a11y_smoke.gd` wrote "Playtest NNNNN" and fixture autosaves into the real save dir for the same reason. `GameSettings.PATH` is a `static var` now and the runner points it at `user://test_settings.cfg` beside its `test_saves`; the two instruments redirect `SAVE_DIR` the way `shot.gd` and `perf_probe.gd` already did. The rule: before wiring a verb that touches the user's disk, ask what happens when the whole suite calls it, and put the answer behind a variable the runner can move (W4-HYGIENE).
- **Never edit a bash script while it is running, and never let a Python patch open a file for writing before the new text is built.** Bash reads scripts incrementally, so an edit mid-run executes garbage; a Windows Python patch that truncates first and then fails leaves an empty file. Build the text, then write bytes as UTF-8 with the file's own line endings.
- **An autoload name is a global identifier.** Registering `GameState` as an autoload means any script declaring `const GameState = preload(...)` fails to compile, and the error surfaces as an unrelated cascade ("Nonexistent function 'new' in base 'GDScript'") in *other* files. Name the const `GameStateScript`, and reach autoloads by node path, never by the bare identifier.
- **`get_node("/root/Foo")` returns null unless the caller is inside the tree.** A SceneTree script (the test runner, anything in `tools/`) owns the root itself, so nodes parented under it are NOT "inside the tree" and every absolute path silently resolves to null — and `_ready()` never fires either. Screens mounted fine and rendered completely blank. Use `game/core/Services.gd` for autoload lookup and the screens' idempotent `build()` instead of relying on `_ready`.
- **`ResourceLoader.load(..., CACHE_MODE_IGNORE)` does NOT surface parse errors** — it has the same blind spot as plain `load()`. Only `reload()` does. For a script with live instances (an autoload), build a detached `GDScript`, assign `source_code`, and `reload()` that. Verified by reintroducing a real error: the CACHE_MODE_IGNORE version passed it green.

- **The autoloads outlive a test file.** `GameState` is shared across every test file in one runner process, so a file that leaves `content` attached changes what `new_game()` does for the NEXT file — an empty-roster assertion in `test_screens.gd` started failing purely on test order. Reset the autoload AND clear its content in `after_each`.
- **Screens resolve their router through `Services`, which returns the AUTOLOAD.** Mounting a screen into a privately constructed router tests a wiring the game never has: the screen navigates via the autoload, which has no host, and Depart silently does nothing. Tests must register a host on the real autoload router, exactly as Boot does.

- **Never `free()` a node from inside its own signal handler.** `Depart` calls `router.goto()`, which freed the screen whose button was still on the stack; Godot refuses with "attempted to free a locked object" and the navigation half-completes, leaving the player on the old screen with no error the tests would notice. `remove_child()` immediately (no overlap) then `queue_free()`.
- **`"prop" in some_object` is not a safe existence check.** In `Results.gd` it matched on a Combatant and then `String(...)` on the value threw "Nonexistent 'String' constructor". Read through the known field (`c.raider.display_name`) rather than duck-typing a type you own.

- **A test can pin a bug as expected behaviour and still read as coverage.** `test_heal_base_prevents_zero_healing_at_game_start` asserted that a fresh healer heals `1` — the defect — while its own comment cited the open question explaining why that was wrong. When a test's comment argues against its own assertion, believe the comment.
- **Prefer a FLOOR to an ADDEND when patching a formula that already has validated tuning downstream.** `max(FLOOR, gear_derived)` fixed the zero-output bug while leaving every geared number byte-identical; `base + gear_derived` would have re-tuned the entire raid tier and moved every golden.
- **Re-sizing an encounter's HP silently changes its SHAPE unless the mechanic magnitudes move with it.** Cutting a pull from 705 to 135 turned its 60 HP add from 8% of the fight into 44% of it.

- **Do not rank an ITEM by the CLASS's primary stat.** A Warrior's primary stat is not `damage`, so a `+5 damage` sword scored a zero-point upgrade and the loot system handed out no weapons whatsoever — while every test about pools, rolls and payouts passed. Rank by what the item actually carries (`Loot.item_worth`), and compare only within one slot for one raider.
- **"Need-based" has to mean NEED.** Ranking purely by stat delta let a raider trading up beat one holding nothing at all. Canon starting armour leaves every main hand and trinket empty, so on day one the empty-slot rule is what does all the work of kitting a party out.
- **When replacing a block by index, check whether the thing you plan to de-duplicate was inside it.** A patch that spliced out `upgrade_delta` and its helper, then asserted the helper appeared twice, aborted after writing nothing.

- **`assert_almost(a, b, "msg")` silently means a TOLERANCE of "msg".** The third parameter is `tol: float`, not the message — passing a string is a parse error in typed GDScript, which is the lucky case; an untyped harness would have accepted it as tolerance 0.
- **A zero-duration step in a reveal loop empties the whole log in one frame.** `LINE_CADENCE[FOUR] = 0.0` is the doc expressing "batched per phase", not a real hold. Any `while timer <= 0` loop needs every path to spend time or terminate.

- **A canon constant is not a substitute for asking the content.** `Enums.RAID_SIZE` is 12 and correct for raids, which is exactly why using it everywhere looked right; Adventures field 6, and every screen that hardcoded the constant silently sent twice the party the encounter was sized for. Ask the encounter.
- **Drive the milestone test through `Button.pressed.emit()`, not through method calls.** A test that calls `_on_depart()` still passes when the button was never connected. Finding the enabled button by its label is what makes a dead end a failure.

- **THE recurring balance error in this project: a correct formula read at the wrong gear stage.** Three times now — `docs/10`'s 88/round benchmark (BL-28), the raid's DPS-at-attempt row (iter 22), and the tank death clock (BL-30). Every one was arithmetic nobody disputed, applied at a stage the fight is never fought at. When a sizing number is quoted, ask which gear stage it was computed at before trusting it.
- **A test that hardcodes a tuning number can forbid its own correction.** `assert_eq(raw, 42)` plus a comment saying "do NOT soften this" would have read a doc-derived INCREASE as the violation it was guarding against. Derive the expected value from the owning formula so the test moves when the input legitimately does.

- **A "prefer what is still needed" heuristic is only as good as the population you ask it about.** The loot bias was correct and did nothing, because it was asked about twelve raiders while the player was fielding six — the needed-set never narrowed. When a weighting rule underperforms, check its audience before its arithmetic.

- **Read a doc's anti-exploit claim as scoped, not absolute.** `docs/05` §7.6 says the clear bonus is held back by "once per tick, and drift pulls it back" — which bounds the PER-TICK gain and says nothing about a climb over many ticks. The same section says band 9 should be reachable by active play. A test that read the claim as an absolute ceiling failed against correct code.

- **When a penalty lands before its recovery lever, the result looks like bad tuning and is not.** Morale's wipe cost read as brutally overtuned until the measurement showed all three of `docs/05`'s recovery mechanisms were simply unimplemented. Before touching a number, check whether the thing that was supposed to offset it exists.

- **A doc that prints an expected-progress table has handed you a spec, not an illustration.** `docs/03` §6.4's pacing table caught the one real ambiguity in the whole reputation formula (whether adventures are tier-multiplied) without my having to guess, because the table prices the same content the formula does and the two readings disagree by 5x. Reproduce those tables cell by cell before writing the formula they describe.
- **Test data must be a state the game can actually be in.** A disband test asserted "rank never changes" while feeding 199 RP to a guild holding Unknown — impossible, since 120 promotes. The code was right; the test's fixture was not. Derive fixture values from the band under test rather than picking round numbers.

- **Test files share `/root/GameState` under `--script`, so a screen test that touches the autoload must put it back.** A new test called `set_content()` on the shared node; three files later, `test_screens`'s "Roster 0 of 15" broke, because a GameState *with* content builds a starting roster on `new_game()` and one without cannot. If a test borrows the autoload, snapshot what it changed and restore it in `after_each` — including `content`.

- **When a doc says it "adopted another doc's numbers unchanged", check the numbers.** `docs/11` §8.4 said exactly that and printed a different column. The cheapest way to catch it was to find two docs working the SAME canon example and compare their answers — a five-number gap is invisible, but "62 vs 64" points straight at the disputed term.
- **A derived per-entity number belongs on the entity, written by exactly one owner.** `Raider.comfort_floor` is computed by `GameState` and only ever read by `sim/`, which meant drift, resting, recovery and the roster readout all picked up comfort with zero signature changes. `from_dict` recomputes rather than trusting the saved value, so a save can never disagree with itself about what the guild owns.

- **`reset()` is the function everyone forgets, so test it against the save shape, not field by field.** Three fields were added to the state and to `to_dict()` but not to `reset()`. `assert to_dict() == a_fresh_state.to_dict()` after a dirty reset catches every future one for free, because a field worth persisting is a field worth clearing.
- **Test teardown belongs in `after_each`, never at the end of the test body.** A failed assertion aborts the body, so an explicit cleanup call never runs — and a borrowed `/root` autoload left dirty then breaks unrelated files later in the run. One failure in this iteration produced three collateral failures in two other files before the teardown moved.

- **When two docs describe the same ladder at different resolutions, give each the column it was drawn for instead of picking a winner.** `docs/02` §6.2's four stall levels map exactly onto its own four comfort rungs; `docs/03` §7's six ranks map exactly onto six potion tiers. Forcing either into the other's granularity would have bent a table that was already right.

- **When a sim entry point grows a parameter, write the byte-identical test before the feature.** `RaidSim.run()` gained a loadout argument this iteration. One extra RNG draw on the no-consumables path would have made five goldens and 1,440 sweep runs quietly wrong instead of loudly broken. Comparing `log.to_json().sha256_text()` across absent / empty / freshly-built took four lines.
- **A modifier that is clamped on the way in cannot be used as its own inverse.** Steady Hands was going to be a negative `situational_bp` until `Formulas.mistake_chance_bp` turned out to clamp that term to zero and upward — the potion would have silently done nothing. Check the clamp before reusing a parameter for the opposite sign.

- **`GameSettings.get_value(key)` takes ONE argument.** Calling it with a default (`get_value("x", false)`) parses fine and fails at runtime, which no parse check catches. The screen test that mounted the panel caught it; a screen with no test would have shipped broken.

- **A field nothing reads yet is a field nothing validates.** `GameState.day` had been failing to advance on raid attempts since the Day Tick shipped, and every test passed, because nothing in the game read the date. The first feature that actually used it found the bug in its first run. When adding a field, ask what would notice if it were wrong — and if the answer is nothing, that is the test to write.

- **The Bash-tool backslash collapse bites patch scripts fed through a heredoc, even a quoted one.** A patch anchor containing GDScript's `\` line continuation silently lost the newline after it and matched nothing. This is already in the notes as "write patch scripts with the Write tool" — the reminder is that it applies to ANY script text containing a backslash, not only to commit messages.

- **"That number exists nowhere" is a claim about a whole document, and one section cannot support it.** BL-44 ruled the Market stall unpriced after reading `docs/02` §6.2; §11 priced it, one section further on. Before deciding a value is missing, grep the doc for its UNIT — a search for "G |" across doc 02 would have found the cost table in seconds.
- **A derived value turned into a purchased one leaves a field nothing can raise.** Making `market_tier` a purchase silently made three shelves unreachable until the Market got the control that buys it. When a value stops being computed, ask immediately what now sets it.

- **A test suite that exercises a side-effecting verb acquires that side effect.** Wiring `docs/14` §7.4's autosaves made 999 tests write real save files into the user's own save directory. Before wiring a verb that touches the user's disk, network or clipboard, ask what happens when the whole suite calls it — and put the answer behind a variable the runner can move, with a test that asserts it moved.
- **Defaulting a missing key to `null` throws on the first `int()` or `String()` that touches it.** Give every field in a parsed dictionary a TYPED default. This one bit inside the save header, i.e. inside the exact mechanism built to avoid crashing on a bad file.
- **A value that lives in two places will disagree with itself.** `played_seconds` was a `GameState` field AND a `write_to()` parameter; the header said 600 and the body said 0. If a writer needs a number the state already owns, read it off the state.


- **A member function named `load` does NOT shadow the global `load()`.** `SceneStage` declares
  `static func load(name: String) -> Control` and, three lines later, `plate.texture = load(plate_path)`.
  That reads like a latent bug — it is not: probed on 4.7.1, the unqualified call resolves to
  @GlobalScope's utility function and returns a `CompressedTexture2D`. Worth knowing before "fixing" it,
  and worth not relying on: new code in that file calls `load()` for resources and `from_data()` /
  `SceneStage.load()` explicitly for stages.
- **A sliced sprite group can contain a mis-cut rect, and padding the strip to it ruins the whole
  animation.** `raider_knight_unlabelled_idle_1` is 31x82 beside four ~25x39 siblings;
  `raider_rogue_idle_5` is 24x79; `raider_warrior_idle_1` is 77x51 beside three 31x48s. Pad every frame
  up to the largest and the figure shrinks inside its own frame and un-plants its feet. Compare each
  frame against the group's MEDIAN, drop the outliers, and report them by name — a silent drop is a
  frame count nobody can explain later.
- **Align sprite frames on the feet, not on the centre of the box.** An extended arm widens the alpha
  box on one side only, so box-centring slides the entire body sideways between frames — it reads as a
  glitch, not a breath. The alpha centroid of the bottom ~20% of rows is the part that must not move.
- **An exclusion list inside a checker is a hole, and the hole will be used.** `tools/parse_check.gd`
  skipped the three `SceneTree` entrypoints because "reload() on the running script returns ERR_BUSY" —
  true of the script actually running, false of the other two. A type-inference error
  (`var who := e.actor_name if …`, untyped sim field) then sat in `tools/balance_sweep.gd` for two
  commits: stage 1 said OK and stage 5 failed at the end of a two-minute gate run. The fix is the
  mechanism the same file already uses for autoloads — build a detached `GDScript`, assign
  `source_code`, `reload()` that — and it now catches the reintroduced bug in seven seconds. Verified by
  reintroducing it.
- **A diff score against the reference is a tautology wherever the plate IS the reference.** Town scored
  `layout_iou 0.44` for weeks while its background was a CROP OF CONCEPT 3 — the region being graded was
  the grader's own pixels pasted back in. Swapping in the bare plate dropped the whole-screen number to
  0.13, which looks like a regression and is really the first honest measurement: masking the scene rect
  the way `raidprep` already does gives the chrome-only score (mae 36.7, 50.7% within 8) and that is the
  number that means something. Before trusting an art-gate verdict, ask which pixels in it came from the
  reference itself (audit `m4t-06` is the fix: region-masked per-component scoring).
- **A `SceneStage` on a screen adds a viewport-wide post-process, so an art-gate MASK does not contain
  it.** The stage builds its own `WorldEnvironment` with glow at `hdr_threshold 1.3`; glow is screen
  space, not scene space. Converting RaidPrep moved its *masked* diff numbers slightly (mae 20.7 -> 21.8,
  within-8 63.6% -> 56.5%) even though every pixel of mine was inside the mask. Only emissive pixels
  (> 1.0) bloom, so the effect is small and intended — but when a masked score moves after a change that
  was entirely inside the mask, suspect a post-process before suspecting the mask.
- **One uncapped Label in a sidebar breaks every wrapped Label below it.** AdventureBoard's card printed
  the encounter's facts line with no `custom_minimum_size` and no autowrap. That set the card's minimum
  width, which widened the whole `VBoxContainer`, which made the labels that DO wrap (capped at 330) wrap
  at the column's new width instead — so the skip warning and the standing lines ran off the right edge of
  the 1536px frame. The wrapped labels were not the bug and looked like it. When wrapped text overflows a
  panel, find the widest UNWRAPPED sibling first.
- **A scrolling column can hide a layout defect instead of solving it.** Results' report column already
  used `ScrollContainer`s, with a comment saying a twelve-body wipe "never grows the panel past its rect"
  — and it did not: it clipped the third row of the fallen through the middle of their names, with no
  visible scrollbar to say there was more. Scrolling is the right answer for a list of unknown length; for
  a grid with a KNOWN maximum (a raid is twelve), make it fit and assert the arithmetic. And when a patch
  targets `HFlowContainer` boilerplate, check WHICH function it landed in — the same three lines appeared
  in `_numbers()` and `_fallen()`, the first match won, and the screen went blank.
- **A backslash line-continuation dies TWICE on the way into a patch script.** The known trap is that a
  bash heredoc collapses `\\` to `\`; the second half is that a lone `\` at the end of a line inside a
  Python triple-quoted string is a *Python* line continuation, so the backslash and the newline both
  vanish and the two GDScript lines arrive joined, with the second line's leading tabs stranded in the
  middle. It parsed — a one-line ternary is valid — so nothing failed; it was just wrong to read. Write
  patch scripts with the Write tool, or restructure the GDScript so it needs no continuation at all.
- **A screen a test never mounts is a screen the keyboard gate never sees.** `tests/unit/a11y_smoke.gd`
  carries an EXPLICIT list of scenes, not a directory walk, so a new screen passes the whole six-stage
  gate without one keyboard assertion ever touching it. Add the scene to `SCREENS` in the same commit
  that creates it. (LoadSave had been missing from that list since it landed; it is on it now.)
- **A panel sized to the viewport instead of to its content reads as a broken screen.** The completion
  report filled the scene rect the way every archetype-C screen does and left 500px of empty navy under
  six lines of text. Sizing the panel to the content and letting the animated plate have the rest is both
  better-looking and closer to the art directive — the bare background is there to be seen, not to be a
  texture behind a wall. Shoot the screen before believing the layout (`tools/shot.gd -- <scene> <png>
  <frames> <WxH> --fixture`); no test in the suite can see dead space.
- **`String.capitalize()` in GDScript is title case, not sentence case.** It upper-cases every word:
  `"6 hours in"` becomes `"6 Hours In"`. There is no sentence-case helper — build the sentence so the
  fragment never needs one.
- **A sidebar that fits today is not a sidebar with room in it.** Adding a 70px callout to the
  Adventure's Board's sidebar pushed "Back to town" off the panel's bottom edge, and adding a two-line
  meter to the Tavern's footer did the same there. Neither failed a test, because a clipped Label still
  reports its text and `_joined()` still reads it — the whole screen-test contract is blind to whether a
  string is ON SCREEN. Shoot the screen and crop the region (`PIL` is installed: `Image.open(shot).crop(
  box).resize(..., Image.NEAREST)`), or the assertion passes and the player sees nothing.
- **Wrapping an overflowing column in a `ScrollContainer` can change nothing visible.** The board's
  sidebar scrolled after the change and still showed exactly the same cut text with no visible bar — the
  panel's own edge sits where the scrollbar would draw. A scroll is a real fix only where the bar can be
  seen; otherwise it converts "clipped" into "clipped and undiscoverable". The fix that worked was moving
  the content to a column that had room.
- **Put a fact where the thing that rebuilds it lives.** The Tavern's collection meter belongs in
  `_sidebar_footer()` and not in the scene's house caption, because `_refresh()` rebuilds the sidebar
  after a hire and never rebuilds the scene. A meter in the caption would have been correct on arrival
  and stale for the rest of the visit — the worst kind of wrong, because it looks right.
- **A file that states a rule trips a grep for that rule.** `test_export.gd`'s "no secret in the
  committed preset" check read `export_presets.cfg`'s own header — *"must never carry a keystore
  password"* — as a violation. Same shape as the register lint failing on the file that lists its own
  exceptions. Scan SETTING lines, not whole files: skip `;` and `#` rows first.
- **A guard against a blind test must not itself be a guessed number.** `assert_true(seen.size() > 80)`
  went red at 64 scripts — the walk was fine, the threshold was invented. Anchor on something real
  (`"res://sim/core/RaidSim.gd" in seen`): it cannot go stale when a file is added or cut, and it says
  what "the walk worked" actually means.
- **`--export-release` returns 0 over a project that cannot boot.** It packs whatever it is given; a
  missing scene, a broken autoload or a resource only the editor could resolve all survive the export
  and die on the player's machine. The launch check (run the exported console wrapper headless, grep its
  stdout the way the boot gate does) is the only step that distinguishes a build from an artifact — and
  it needs `debug/export_console_wrapper=2`, because 1 is debug-only and this project only ever exports
  release, so at 1 the wrapper does not exist and the check silently has nothing to run.
- **A citation to the loop's own working directory is a citation nobody checks.** `test_docs_links.gd`
  walked `docs/` and `art/ref/specs/` and not `build/plan/`, so eight dead paths accumulated in shipped
  code — two of them naming a handoff that was never authored, with real untracked work behind it. When
  a comment points at a file, something has to prove the file is there; the directory the lint skips is
  the directory the rot lives in.
- **Repoint a dead citation by reading the comment, not by matching the filename.** `handoff-debt.md`
  has an obvious-looking neighbour in `report-debt.md` — different document, no §1, none of the content.
  The right target was an audit item. A citation repointed at the wrong file is worse than a dead one: a
  dead link announces itself and a wrong one does not.
- **A historical note that names the dead file needs the lint to exempt it, so do not write one.** Two
  repoints said "this used to cite `build/plan/handoff-debt.md`", which the new lint then flagged. The
  fact worth keeping is that the plan file was never written, not its name — keep the record, drop the
  path, and the exception list stays empty.
- **A cap is a share of something, so find the something before writing the cap.** `coin_cap()` and
  `rp_cap()` shipped, were tested, and refused claims correctly — against a lifetime income of zero,
  because the counter they divide by did not exist and `_prop()` handed back its fallback. A test that
  proves a formula is right proves nothing about the number going into it; assert the WIRE as well,
  which here is one line reading the snapshot field against the state field.
- **The two numbers that look like a lifetime total both go down.** `gold` is what survived spending and
  `reputation_points` is reduced by the disband penalty. Anything phrased "~15% of lifetime X" needs its
  own monotonic counter, incremented at the moment of the gain and never at the balance.
- **A save-shape change is still four files, every time.** SAVE_VERSION, a registered migration step
  (even a pure stamp — a hole in the chain cannot be told from a decision), `FROZEN_AT_VERSION` plus
  `FROZEN_SHAPE` moved together, and a committed fixture at the version left behind. The fixture
  generator needs its new `ADDED_IN_Vnn` list AND a new `_downgrade` link, and the test that proves the
  old fixtures are genuinely old holds its own copy of those lists — that one is easy to miss, and it
  fails by claiming a v10 file should contain a field invented five versions later.
- **A faucet must not be allowed to feed its own denominator.** The achievement board's coin cap is 15%
  of lifetime income, and paying board coin through the ordinary `add_gold()` would have counted it AS
  income — every payout widening the ceiling it was paid under. It converges, so it would never have
  looked broken; it would just have quietly stopped being a cap. Any "N% of lifetime X" needs to ask
  which payments are allowed to raise X.
- **Wire a system and the first thing to check is what the system's own comments already promised.**
  `Achievements.claim_grant()`'s docstring named `GameState.claim_achievement()` as "the hand", and
  `Guildhall.gd` had a `_record_notice` field and a comment describing the answer to a press. Both had
  been written for a caller that was never built. When a file describes its collaborator by name, grep
  for that name before designing a new one.
- **An event is stamped with the day it happened, not the day it is noticed.** An attempt is a Day Tick
  here, so by the time the end of `record_attempt()` runs the clock has already moved — and a record wall
  reading "cleared Adventure 0 on day 43" for a raid fought on day 42 is wrong in the one field the
  player reads it for. Capture the day at the top of the function and carry it in the event.
- **A system that passes every part-test can still fail as a chain.** Nine subsystems each had their own
  green tests — loot rates, encounter budgets, morale recovery, the economy, the ladder — and the first
  thing that ever asked them to hold hands found the campaign is not completable. Part-tests cannot see a
  closed circuit (no clears -> no gold -> no facility -> no morale -> no clears). If a project has
  systems that feed each other, something has to play the whole thing.
- **Extract the rule before writing the harness that walks it.** The ladder and the party suggestion
  lived inside the Adventure's Board and RaidPrep, so the playtest could only have REIMPLEMENTED them —
  and a harness that walks its own ladder proves a game nobody plays is completable. Moving them to
  `RaidPlan` first cost 49 deleted lines and made the tool worth running.
- **A gate that is red for a reason nobody is allowed to fix stops all work.** The playtest's first run
  was correct and red, and the fix is a designer ruling. Wiring it to FAIL would have made every future
  iteration's only task an item the loop may not touch. It warns instead, prints the wall on every full
  gate run, and its own comment says the warning becomes a failure the day the ruling lands — which is a
  promise in the file rather than in somebody's memory.
- **Before building a checker, grep for the one that is already there.** `gen_items.gd -- check` had
  existed since the generator was written, did exactly what the audit asked for, and had never been
  called — the third instrument-without-a-caller found in a week, after `Achievements.evaluate()` and
  `tools/export_build.sh`. The audit proposed two new shapes and both were worse than the mode already
  on disk; one of them would have been a second implementation of the generator competing with the first.
- **A comment that documents the absence of a gate has to change when the gate lands.** The generated
  files said "a hand edit here is lost on the next regeneration and nothing will warn you". True when
  written, false the moment it was wired, and a file that tells a reader the wrong thing about its own
  protection is worse than one that says nothing. Regenerating to fix a note is a one-line diff in eight
  files and worth it.
- **An audit entry written before the work is not evidence of what is missing now.** `M6-BAL-01` asked
  for four things and three had quietly landed in other iterations; the one that had NOT was the one the
  sweep's own header named in a "KNOWN GAP" paragraph. Read the file before reading the plan — the code's
  own comments are newer than the audit.
- **A test that reads a property the object does not have can fail for a reason that looks like content.**
  `_equipped_slots()` read `r.gear`, and the spec dictionaries call a gear rung "gear", so it read
  perfectly and meant nothing — `Raider` keeps `equipment`. It surfaced as "nobody gains a weapon", which
  sent me looking at item `source` fields and family maps before the field name. When an assertion about
  data fails implausibly, check that the reader is reading the thing it names.
- **Build the gate while the thing it guards is still empty.** The motion lint landed against a codebase
  with zero tweens, which is the only moment it could land without failing against fresh call sites and
  tempting somebody to weaken it. A rule written after the code it governs is a negotiation; a rule
  written before it is a rule.
- **A setting each new call site must opt INTO is wrong by default.** `reduced_motion` had one consumer
  and no enforcement, and the three queued juice items would each have had to remember it — with no
  symptom if they did not, because an animation that ignores the setting looks exactly like one that
  respects it unless you are the person it is for. Make the sanctioned helper the only door and lint the
  door.
- **Reduced motion means "arrive instantly", not "skip".** A 0.0-duration tween in Godot completes on the
  next frame and applies its final value, so a duration of zero lets the call site keep exactly one code
  path. Branching on the setting instead would create a second path that only the people who need it ever
  execute — the least tested code in the build, serving the players least able to work around it.
- **A helper's comment claiming "every site funnels through here" is a claim, not a mechanism.**
  `Cards.morale_glyph()` said exactly that while five screens still read the raw emoji table. The same
  sentence appeared in `gen_items.gd` about its check and in `Achievements` about its evaluator. When a
  file asserts that it is the only door, grep for the door — and then put a lint on it, because the
  comment is what somebody will believe next time.
- **One flag for a whole option inventory beats a flag per option.** `tools/shot.gd` had grown
  `--fixture`, `--fixture=raid` and `--completed`; the fourth need was an accessibility state, and
  `--set=key=value` covers every row of docs/13 §15.1 at once. `GameSettings` coerces the value and
  refuses an unknown key with its own error, so the tool needs no table of its own.
- **Three gates on one field is the same as no gate.** `comedy_line` was checked at 40 characters by one
  test, 20 by another and non-empty by the validator; the corpus satisfied all three by accident, and
  nobody could have said what the rule was. When two tests assert different numbers about the same thing,
  neither is the rule — put the number in the code that owns the field and have the tests read it.
- **A doc rule nothing enforces drifts, and the content is usually the half worth keeping.** docs/10 §6
  asked for one sentence and five of the ten authored lines were two, because two reads better — setup
  then punchline. Amending the doc and recording why took one edit; rewriting five good lines to satisfy
  an unexplained constraint would have made the game worse. Check which side of a doc/code disagreement
  is actually load-bearing before assuming it is the code.
- **Walk the files, not the loaded database, when the question is "does all the content have X".**
  `ContentDB.load_all()` mounts only named tiers (BL-69), so a coverage test built on it would have
  inspected ten encounters out of forty-two and reported complete — and the thirty-two it skipped are
  exactly the ones most likely to ship with a hole.
- **A timed sequence that must be skippable cannot be an `await` chain.** docs/13 §11.4 says "fully
  skippable on any input", which rules out the obvious implementation before it is written: an await
  chain cannot be aborted mid-flight. Driving it from a clock in `_process` and firing each beat once as
  the time passes is both skippable and testable — the tests advance the clock by hand instead of waiting
  2.4 real seconds. When a spec says "interruptible", that is a constraint on the control flow, not a
  feature to add afterwards.
- **A member and a method cannot share a name in GDScript, and the error names the wrong one.**
  `var _wipe_stamp` plus `func _wipe_stamp()` reports "Function has the same name as a previously
  declared variable" at the function's line, which reads as though the function is the problem. The beat
  wanted the name; the Label got `_wipe_stamp_label`.
- **Drive the real code path, not only its constants.** The wipe sequence's offsets and durations were
  easy to assert and would have proved nothing about a beat that throws — each one touches something
  different (the stage, the audio bus, the log column, a tween, the focus) and `_process` is the only
  other caller, so nothing in the suite would have noticed. Four tests mount the real screen on a wiped
  account and run every beat.
- **A queue that lies is worse than a short queue.** Thirteen audit items were finished while still
  marked open, because work lands inside a neighbouring item and nobody walks back to the plan. Twice it
  cost the pick: an iteration chose an item, read the file, and found it done. Cheapest fix found —
  rank open items by how much of what they NAME already exists (`tools/audit_stale.py`), because an
  entry arguing "`foo()` does not exist" against a tree where it does is mechanically detectable.
- **A detector that closes things is a judge, and this one must not be.** The false positive is exactly
  the interesting case: an item whose PREMISE is "this exists but nothing calls it" scores a perfect
  match and is genuinely open. Say so in the tool's own header, have it edit nothing, and make every hit
  cost one reading of the citing sentence.
- **Do not write a test that asserts the plan is accurate.** Staleness is a judgement about the tree, not
  a property of the file; a test that tried would either re-implement the detector or assert something
  it cannot know. Assert the SHAPE instead — unique ids, a status the brief can act on, an open item
  that says what is left — so a stale entry is at least a well-formed one.
- **Generated art must be deterministic or the build grows diffs nobody made.** `gen_wipe.lua` uses a
  fixed lobe table and a sine wobble where `math.random` would have been easier; a blot that differed on
  every run would churn `game/assets/` and make `build_art.sh`'s staleness manifest meaningless. The same
  rule the goldens live by, applied to pixels.
- **The first render of a procedural texture is a draft, and the doc says which one is right.** The ink
  blot's first pass had a 9px fade and an 11-times rim frequency, which read as a SPLAT. §11.4 says
  "bleed into the paper fibre" — wicking, not impact — so the fade doubled and the wobble halved.
  Composite the asset over the real ground and look before wiring it; the difference between a splash
  and a spread is not visible in the code.
- **"Built" and "armed" are different states, and this project keeps shipping the first.** SIX times now:
  `Achievements.evaluate()`, `export_build.sh`, `gen_items.gd -- check`, `Cards.morale_glyph()`, the
  balance drift gate whose baseline had never been generated, and the tutorial trinket grant, written
  against two item ids that resolved to null. When a mechanism lands, the last step is not the last
  commit — it is the first real invocation, and something has to assert that invocation stays
  possible.
- **A test that branches on whether the work exists is not a gate.** `test_tutorials.gd` read
  `if authored: assert the grant works / else: assert it grants nothing`, and passed for weeks on the
  second branch while the feature did nothing at all. Writing the branch felt like honesty — it even
  carried a comment saying the rows were missing — but a conditional assertion is a note, not a test.
  If the data is not ready, let the test FAIL and pin the item; once it is, delete the branch.
- **An id is data with a grammar, and the grammar has an owning doc.** Two tutorial trinket ids were
  chosen in code (`ITM_T0_TUT_CRACKED_POWER`) and did not parse under docs/09 §12.1 at all. Check the
  format doc before minting an id, because ids are permanent once anything stores one — and if the
  grammar genuinely cannot express the thing, that is a doc gap to rule in `docs/15`, not a licence to
  freehand it.
- **Godot imports a committed `.csv` and writes an `.import` beside it.** That collides with the rule
  that only `game/` art may be imported. A data file that must live under `tests/` needs its own
  directory with a `.gdignore` — `FileAccess` reads straight through one — and it cannot share a
  directory with anything `preload()`ed, because an ignored tree has no scripts to preload.
