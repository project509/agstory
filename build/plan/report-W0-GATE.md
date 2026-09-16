# Report — W0-GATE: the art gate scores every screen and its noise is gone

Owned files: `tools/shot_all.sh`, `tools/diff_all.sh`, `tools/probe/Kit.gd`, `tools/art/contact_sheet.py`,
the result-stub blocks only in `tests/unit/test_consumables.gd`, `test_game_state.gd`, `test_raider_detail.gd`,
`test_reputation.gd`, `test_rest.gd`, `test_savegame.gd`, `test_tavern.gd`, `test_tutorials.gd`,
one new "art gate baselines" block in `BUILD_STATE.md`.

Written as each item lands, in the order it was done. Findings closed: RULES-01, RULES-11, RULES-16,
CRITIC-G11 (sheet half), CRITIC-G04 (tab rows), CRITIC-G09 (emoji sheet), CRITIC-G17 (reduced sheet),
CRITIC-G03 (wide sheets).

## Acceptance

- [x] A1 `diff_all.sh` scores every screen with §0.3's masks, prints one line per target (14), exits 0 (run 20:57:51-20:58:36, 45 s). Re-run on resume at 08:37 after W0-SHOT's settings reset: 14 lines, exit 0, same numbers within jitter.
- [x] A2 The first honest numbers are recorded in BUILD_STATE (one "art gate baselines" block): 17 inserted lines vs HEAD and nothing else; the fourteen numbers match `build/diff/*_diff.json` digit for digit; the 08:37 re-run confirmed them (≤0.07 mae jitter on the animated targets, now a clause in the block); the block was truncated by a codec error at 08:40 and rebuilt from HEAD + the block (08:41 entry).
- [x] A3 `verify.sh --fast` stage 3 prints zero `'survivors'` lines (first run 21:05: 0 `survivors`, 0 SCRIPT ERROR lines; the suite's reds are other units' in-flight files — see log). `TESTS PASSED` re-checked at the end. Re-checked 08:52 (see A7): 0 `survivors` lines, 0 `SCRIPT ERROR` lines, `TESTS PASSED 1604 test(s) in 72 file(s)`.
- [x] A4 `grep -rn 'load("guildhall")' tools` is empty; the Kit probe stands on `stage_camp`; kit re-baselined: 16.94/0.279/59.7 % (guildhall.json, a crop of Concept 1 = the tautology) -> 25.20/0.200/44.3 % (bare camp, honest). Re-checked on resume: the grep is still empty; Kit.gd is tab-indented throughout (171 tab lines, 0 space lines).
- [x] A5 `shot_all.sh build/shots/all` shoots the fixture sheet; `--sheet=` grows the ten other sheets; a row whose flag shot.gd lacks prints `SKIPPED` and the sheet exits 0. Done: the verbatim command ran 08:51 (13 ok, `sheets rc=0`); all eleven sheets ran under `--sheet=all` and again per sheet; SKIPPED proven three ways — dry run with a flag-less shot.gd (every flagged row), dry run with exit 2, and LIVE for exit 12 (`Guildhall_Records`, the fixture at Unknown) — each with exit 0.
- [x] A6 Every sheet that can render in this worktree was shot and LOOKED AT (Read tool) and is described below. All eleven sheets (125 tiles, 29 contact-sheet pages) were viewed with the Read tool, twice for the seven that had to be re-shot after W0-SHOT's settings reset landed mid-run; each view is described in the progress log with what it showed.
- [x] A7 `verify.sh --fast` green; summary lines pasted below. 08:52:37, `VERIFY OK`, summary lines pasted at the end of this report. `lint_motion.sh` ran inside it (`MOTION LINT OK`); no game/ file was touched by this unit.

## Findings before any code was written

- **Today's `tools/shot.gd` does not reject an unknown flag with exit 2 — it appends it to the positional
  list and ignores it.** `--focus` would therefore produce a plain shot labelled "focus" (a lie in a sheet).
  The plan's "SKIPPED on exit 2" clause is kept AND a cheaper pre-check is added: a row is SKIPPED when
  `tools/shot.gd` does not contain the flag's spelling (`grep -q -- '--focus' tools/shot.gd`). The moment
  W0-SHOT lands in this worktree the rows light up with no edit here.
- **`tools/with_godot_lock.sh` is not re-entrant** (mkdir lock, no env marker), and `shot_all.sh` (9c1575f)
  took the lock per shot while the plan's grammar wraps the whole script
  (`tools/with_godot_lock.sh ./tools/shot_all.sh …`). Wrapped as the plan says, the old script would have
  queued 900 s against its own parent and exited 75. Both scripts now detect a lock-holding ancestor through
  `/proc/<pid>/ppid` + `/proc/<pid>/cmdline` (present in Git Bash, verified) and re-exec themselves under
  the lock only when bare. Either grammar is safe.
- **The plan's target count is off by one.** §0.3 lists the Kit probe plus all 13 screens (MainMenu included,
  "vs 3 chrome-only") = 14 targets; the acceptance line says "13 lines". Fourteen lines are printed — one per
  target, nothing else — because dropping MainMenu contradicts §0.3 and dropping the Kit contradicts RULES-16.
- **§0.3 moves RaidPrep from Concept 1 to Concept 2** ("RaidPrep, RaidView, Results vs 2 with the arena
  masked"); the old gate scored it vs 1 (21.85 MAE). The plan's table is followed; both numbers are recorded.
- The existing numbers before this unit (from `build/diff/*_diff.json`): kit 16.94 / iou 0.279 / 59.7 % (vs 1,
  guildhall.json plate); town 36.73 / 0.103 / 50.7 % (vs 3, scene band masked); raidprep 21.85 / 0.171 / 56.5 %
  (vs 1, arena masked).

## Judgement calls

- Every sheet writes its tiles to `<out>/<sheet>/` (the default `fixture` sheet included) so a directory holds
  exactly one sheet's tiles and `contact_sheet.py`'s directory walk stays honest; `--sheet=all` runs them all.
- The `reduced` sheet is two passes into one directory with `_motion` / `_effects` suffixes; the contact sheet
  sorts by the screen prefix so the pair sits together.
- Wide rows are SKIPPED until shot.gd mentions `display_aspect`: today's shot.gd accepts the WxH and the `--set`
  but mounts the screen at the full width, so a "keep" tile would show an 1820-wide mount and mislead.
- The Kit probe mirrors Town's stage placement (`Vector2(-46, -62)`, Town.gd:134) rather than sitting the
  1536x1024 camp plate at the scene origin, so the same part of the camp is under the Concept-1 chrome.
- MainMenu "vs 3 chrome-only": the menu column only (`--region 0,300,520,420`: the lockup, tagline and
  five buttons). The scene-band mask was tried first and rejected after looking at the shot: MainMenu has no
  dashboard chrome (W3-MENU keeps it frameless), so that mask would have hidden exactly the pixels a menu
  change moves and scored sky and sea instead. `diff_all.sh`'s masks field learned `region=x,y,w,h`.

## Progress log

- 20:55 Stubs: `var survivors: Array = []` + `var mistake_count: int = 0` added to all ten stub classes
  (two each in test_consumables/test_reputation/test_tavern, one each elsewhere), four-space, after the
  existing `casualties` line; `casualties` not redeclared (RULES-01 verdict). Awaiting the suite.
- 20:57 `tools/probe/Kit.gd`: `SceneStage.load("stage_camp")` at Town's `CAMP_OFFSET` (a local const,
  the probe does not preload a screen); comment names RULES-16 / M4B-CONV-02. `grep -rn 'load("guildhall")' tools`
  is now empty (only `tools/art/patch_bubbles.py`'s docstring still says `guildhall_plate`, a usage
  example for an inpainting tool, not a load — left alone, not mine).
- 20:58 `tools/diff_all.sh` rewritten: 14 TARGETS (`scene|concept|name|masks|shot flags`), Concept-3 rows
  masked `0,77,1536,649`, Concept-2 rows masked `210,77,928,640`, RaidView/Results `--fixture=raid`,
  MainMenu bare; self-wraps in the lock when run bare (ancestor walk through /proc).
- 20:59 `tools/shot_all.sh` rewritten: `--sheet=NAME|all`, eleven sheets, per-sheet output directory,
  SKIPPED rows for flags shot.gd lacks (grep) or exit 2, `Town,RaidView` filter kept.
  `tools/art/contact_sheet.py`: `<Screen>_<variant>` tiles sort with their screen; a tile of another size
  is resized and announced instead of silently squeezed.
- 21:02 First sheet run: `./tools/shot_all.sh build/shots/all --sheet=tabs` bare (self-wrapped in the lock;
  the ancestor walk worked, exit 0). Every row came back `ok`, not `SKIPPED`: W0-SHOT's `tools/shot.gd`
  is already on disk in this worktree (456-line diff, `--press=`/`--focus`/`--advance=`/`raid:clear`/
  `display_aspect` all present), so the SKIPPED path was exercised only by the grep pre-check being
  false — the exit-2 path stays as the fallback. Viewed `build/shots/all/tabs/_sheet_1.png` (5 tiles):
  Guildhall_Facilities shows the Facilities wall ("Leaking Guildhall — level 1 of 4", "Commission the
  work — 150 G", the Quarters row of twelve busts); Tavern_Manage shows the Manage list (eight rows with
  a Dismiss button each, "Ask around again — 50 G"); Market_Buy shows the six consumables ("Minor — 8 G"
  … "Minor — 40 G"); Market_Comfort shows the furnishing list for Bork ("Straw Cot +3 · 40 G", the
  Feather Bed refusal line). NOTE for W0-SHOT: `Guildhall_Records` shows the ROSTER tab — `Records` is a
  disabled chip under this worktree's fixture (the header chip reads "Day 23 · Unknown", and the tab's
  own line says "The board opens at Known"), so `--press=Records` had nothing enabled to press. W0-SHOT's
  acceptance line ("`--press="Records"` on Guildhall shows the Records wall") needs the fixture at Known
  or the press to report a disabled target; nothing in this unit can change it.
- 21:05 `verify.sh --fast` #1 (with the stubs and the Kit change in): stages 0-2 PASS, PARSE_CHECK 150
  scripts; stage 3 `TESTS FAILED 4/1593` — the four are `test_text_scale.gd` x3 (W0-TEXTSCALE's new test,
  written at 20:51 while its Theme/Settings edits are still landing) and `test_export.gd ::
  test_the_preset_ships_the_same_icon_the_project_names` (the export preset / project icon, W0-SPLASH's
  files). Zero `'survivors'` lines and zero `SCRIPT ERROR` lines in the whole log: the 40-line stub noise
  is gone and the real reds are the only thing the summary prints (RULES-01's point). No test that touches
  the eight stubs changed state — the previously dropped `_attempt_event` now records with alive 0 /
  party_size 0 and nothing asserts on it.
- 20:58 `./tools/diff_all.sh build/diff` under one lock: 14 lines, exit 0. The first honest numbers
  (mae / layout_iou / within-8 %, all verdict DIFFERENT — the screens stand on bare plates and the masks
  grade the chrome):
  kit vs 1 (no mask) 25.20 / 0.200 / 44.3 (was 16.94 / 0.279 / 59.7 on the guildhall.json crop — the
  drop is LESSONS' tautology leaving the number, not a regression of any pixel of chrome);
  town vs 3 36.73 / 0.103 / 50.7 (unchanged from the old gate, byte for byte);
  tavern 34.94 / 0.094 / 53.1; market 37.00 / 0.091 / 50.8; guildhall 33.73 / 0.078 / 61.5;
  raiderdetail 37.86 / 0.103 / 51.5; loadsave 32.38 / 0.059 / 58.5; settings 35.06 / 0.075 / 51.3;
  raidprep vs 2 32.21 / 0.077 / 34.5 (was 21.85 / 0.171 / 56.5 vs 1 — the concept moved per §0.3, so
  the two numbers are not comparable; both stay recorded); raidview vs 2 34.51 / 0.114 / 25.9;
  results vs 2 32.36 / 0.075 / 25.3; board vs 1 28.65 / 0.147 / 38.9; completion vs 1 28.23 / 0.091 / 35.0;
  mainmenu vs 3 (scene band masked) 36.45 / 0.069 / 32.4 — superseded, see 21:10.
- 21:10 Viewed `build/diff/kit.png`: Concept 1's chrome (Home rail, four chips, the Sludge Maw card, 17 %
  callout, the four roster cards and the seven-line event log) with the bare camp under it — tents, the
  fire ring, five actors, the speaking bubble and a "…" bubble — framed exactly as the Town frames it.
  Viewed `build/diff/mainmenu.png`: the full-bleed town aerial with the lockup + five buttons at the left;
  no rail, header or strip. Hence the region re-score: mainmenu vs 3 (menu column) 35.83 / 0.089 / 28.5.
  `diff_all.sh` now carries the `region=` row; the other 13 rows and their shots are unchanged.
- 21:12 Viewed the fixture sheet (`build/shots/all/fixture/_sheet_1..3.png`, 13 tiles): MainMenu (aerial,
  "Continue — A Guild Story"), Town (five callouts on the camp, sidebar, four roster cards), AdventureBoard
  (A0/TR/A1/A2 notices, "Go to prep"), RaidPrep (comp check, "~58.5 mistakes", 12 of 12 chalked), RaidView
  (E5 round 1, boss plate 7150/7150, four party cards, the first MISTAKE line), Results ("It's a wipe!",
  Survivors 0 of 12, the twelve fallen), Guildhall (Roster tab, eight cards, "Rest until recovered"),
  RaiderDetail (Bork's kit, Quarters, "On record"), Tavern (Linda at the bar, "Hire — 60 G", four seats),
  Market (Sell tab, seven worn-by rows, The Stall), LoadSave (Slot 1 — A Guild Story, slots 2/3 empty),
  Settings (13 of 17 live), Completion ("The guild is finished.", camp under it, the Back button).

## Resumed 2026-09-14 (the first agent was killed by a usage limit after 21:12)

- Read on resume: 00-plan §0 + W0-GATE, RULES-01/11/16, CRITIC-G03/04/09/11/17, LESSONS, every diff of the
  owned files. A1/A3/A4 re-checked against the tree: `grep -rn 'load("guildhall")' tools` still empty;
  the 14 `build/diff/*_diff.json` numbers match the BUILD_STATE block digit for digit (kit 25.202/0.2002/
  44.29 … mainmenu 35.825/0.0885/28.47); all eleven sheet directories existed on disk (125 tiles, shot
  20:59-21:03, AFTER shot.gd's last change at 20:53) but only `fixture` and `tabs` had been LOOKED AT.
  Moved them to `build/shots/all.prev` and re-shot `--sheet=all` + `diff_all.sh` under ONE lock hold
  (`with_godot_lock.sh bash -c '…'` — the ancestor walk must see the lock through a `bash -c` parent).
- 08:30 A5's SKIPPED contract exercised WITHOUT the engine (scratchpad `dry_skipped.sh`: a copy of
  shot_all.sh with the lock self-wrap, the shot.gd path and `$GODOT` swapped for fakes). (1) a shot.gd
  that lacks every W0-SHOT flag: focus/tabs/raid-advanced/raid-clear/wide-keep/wide-expand print one
  `SKIPPED <tile> (tools/shot.gd lacks --focus|--press=…|--advance=…|--fixture=raid:clear|
  --set=display_aspect=…)` per row, 0 ok / N skipped / 0 failed, exit 0, no engine call, no contact sheet;
  (2) engine exits 2 -> `SKIPPED … (shot.gd usage exit 2; see …log)`, exit 0; (3) engine exits 1 -> `FAIL`,
  exit 1; (4) engine exits 0 with the real shot.gd -> every tabs row `ok`; (5) `--sheet=nope` -> usage +
  exit 2 (one edit today: `shoot_sheet … || RC=$?`, so an unknown sheet exits 2 like an unknown flag and a
  failed row still exits 1); `--bogus` -> exit 2. `bash -n` clean.
- 08:33 Re-shot `fixture` (3 sheets, 13 tiles) — same content the first agent described at 21:12, one
  change since: the Town/Guildhall/Tavern/Market/Board sidebars and roster cards now carry the fixture
  (Bork 87 / Tiny 14 / Gruk 54 / Spoof 31, "12480 G", "Day 23 · Unknown"); MainMenu still lists
  "Continue — A Guild Story". Nothing missing, no blank region, every screen at 1536x1024.
- 08:33 Viewed `empty` (3 sheets, 13 tiles — the a11y "empty" sweep as images, no fixture): the header
  chip reads "No guild loaded." on Town/RaidPrep/Tavern/LoadSave/Settings/Completion and "0 G · 0 ·
  Roster 0 of 15 · Day 1 · Unknown" on Board/Guildhall/RaiderDetail/Market; every empty state has its
  sentence — Town's "Available 0", Board "Nothing pinned yet / No notices — the guild has no content
  loaded", RaidPrep "No mission chosen … ~0.0 mistakes … 0 of 12 chalked", RaidView "Nobody went.
  Depart from the board to run an attempt.", Results "No attempt to report", Guildhall "No raiders yet.
  The Tavern is where a guild finds people.", RaiderDetail "Nobody selected", Tavern "Nobody is
  drinking", Market "Nothing to sell. Everything the guild owns is being worn or was never found.",
  LoadSave slots 2/3 empty with disabled Load/Delete, Completion "The guild is finished." with an EMPTY
  guild name (" cleared the last fight on day 1") — a real finding for whoever owns Completion, not
  this unit (recorded, not fixed; the empty sweep is exactly what these tiles are for). Town's sidebar
  keeps the disabled-hotspot reasons ("Canon lists this one as a maybe. Disabled in this build.").
- 08:33 Viewed `focus` (3 sheets, 13 tiles, `--focus`): a thin steel outline sits on the rail's "Camp"
  (`Nav_home`) item on Town/Board/RaidPrep/Guildhall/RaiderDetail/Tavern/Market/LoadSave/Settings/
  Completion, on "New Guild" on MainMenu, on the ">>" transport button on RaidView and on the log
  pager on Results; nothing else differs from the fixture sheet (the ring is the only delta, as it
  should be). Full-resolution crop of Town's rail and RaidView's transport viewed next.
- 08:34 Viewed a NEAREST 3x crop of `focus/Town.png` (0,60)-(300,200): a 2px steel-blue ring boxes the
  "Camp" rail item, top edge at y≈103, bottom at y≈158, right edge at x≈206 — the shape W0-SHOT's
  acceptance line names, seen through this unit's sheet.
- 08:37 Viewed `text150` (3 sheets): the 150 % scale is REAL in this worktree now (W0-TEXTSCALE landed
  while this unit ran) — every Label and Button is a step larger and the fixed-pixel layouts show it:
  the header chips run off the right edge ("Day 23" clipped, "Unknown" gone) on every framed screen,
  MainMenu's tagline is drawn over the wordmark, Board/RaidPrep/Tavern sidebars clip their last lines,
  Settings' Language/Controller rows fall below the panel, Completion's "Back to town — the guild
  carries on" button is cut at the panel edge, Guildhall's card buttons stay tiny. All of it is the
  evidence W0-TEXTSCALE/W1-FRAME need; none of it is this unit's to fix.
- 08:37 THE LEAK. Viewed `emoji` (3 sheets): the pip strings are there ("Bork — 87 ||||||.", "Tiny —
  14 ||......", morale faces gone, the Settings row "Emoji-free mode On") — AND the text is still at
  150 %, the Settings tile reading "Text scale 150%". Today's `fixture` Settings tile also read
  "Reduced motion On" with nothing on the command line. Cause, from `tools/shot.gd`'s new header:
  GameSettings loads `user://settings.cfg` in `_ready()` and shot.gd used to inherit whatever the last
  Settings-screen Apply had written; W0-SHOT fixed it (`GameSettings.reset_all()` before `--set`,
  "SETTINGS defaults" printed per shot) at 08:35:48 — DURING this run. Counting the tile logs that carry
  the line: fixture/empty/focus/text150/emoji/reduced 0 of 13/13/13/13/13/26, wide-keep 4 of 13,
  wide-expand/tabs/raid-advanced/raid-clear all. So the first six sheets and nine wide-keep tiles are
  contaminated and are being re-shot (08:38, one lock hold, with `tabs` to exercise the new exit-12 row);
  wide-expand, tabs, raid-advanced, raid-clear stand.
- 08:37 Viewed `wide-keep` (3 sheets; the last four tiles are post-fix): every tile is 1820 wide with
  the 1536 frame centred on flat dark bars (~142 px each side); the Settings tile reads Keep / 100 % /
  Off / Off / Off. Viewed `wide-expand` (3 sheets, all post-fix): 1820 wide, no bars — the header chips
  reach x≈1810, the sidebar sits at the far right, the scene band stretches under it (Town's camp runs
  edge to edge), Settings reads "Wide displays: Expand". CRITIC-G03's two modes are now on a sheet.
- 08:37 Viewed `tabs` (4 ok + 1 FAIL): Guildhall_Facilities ("Leaking Guildhall — level 1 of 4",
  "Commission the work — 150 G", the Quarters busts), Tavern_Manage (eight rows with Dismiss, "Ask
  around again — 50 G"), Market_Buy (Minor — 8/30/35/35/40 G, Guild Feast), Market_Comfort ("Furnishings
  for Bork", Straw Cot +3 · 40 G, the Feather Bed refusal). `Guildhall_Records` exited 12: shot.gd now
  refuses to fake a press on a disabled chip and prints "--press 'Records' is disabled — There is
  nothing to record until you have raided. The board opens at Known." (W0-SHOT answered the first
  agent's 21:02 note.) JUDGEMENT CALL: exit 12 is a SKIPPED row, not a FAIL — the fixture is at Unknown
  by design (HALL-24 is blocked), a player could not press it either, and a permanently red
  `--sheet=all` is the noise RULES-01 exists to remove; the row echoes shot.gd's reason so nothing is
  hidden, and it lights up the day the fixture reaches Known. `shot_all.sh` gained that branch (header
  updated); `bash -n` clean.
- 08:37 Viewed `raid-advanced` (1 sheet): RaidView_10 — "Mistakes this attempt 5", Round 1 of 22, boss
  7142/7150, five log lines (Greg/Tiny MISTAKE, Main Boss hits Bork for 30 x2, Bork hits Main Boss for
  4), party page 2/3 (Pip/Cindy/Steve/Hal, full HP bars). RaidView_all — the red "WIPE." stamp over the
  arena with "A wipe costs time, consumables, morale and money — never the save." under it, Mistakes 25,
  Round 11 of 22, boss 7062/7150, party page 3/3 with Nev/Clive/Spoof/Tiny marked Dead at 0 HP.
- 08:37 `diff_all.sh` re-run (post-fix, 08:36:52-08:37:40): 14 lines, exit 0. Against the BUILD_STATE
  block: 10 targets identical to two decimals; kit 25.27 (block 25.20), raidview 34.44 (34.51), results
  32.39 (32.36), mainmenu 35.83 (35.83) — ≤0.07 mae run-to-run jitter on the targets with animated
  layers (fire, shimmer, the boss). One clause added to the block recording that jitter.
- 08:38 LESSON for LESSONS.md (not mine to edit; recorded here): the first `--sheet=all` run reported
  `sheets rc=2` although every sheet but tabs was 0 ok-failures — because I edited `shot_all.sh`'s
  last lines (`RC=$?`) while bash was still executing the running copy. Bash reads a script as it goes;
  never edit a script that is mid-run. A comment now says so at the top of shot_all.sh.
- 08:41 INCIDENT, recovered. Adding the jitter clause to the BUILD_STATE block with a Python one-liner
  (`open(p,'w')` then `.write()`) truncated `BUILD_STATE.md` to 0 bytes: the default codec on this
  machine is cp1252, the clause held a `≤`, and the encode error fired AFTER the `'w'` open had emptied
  the file. Rebuilt from `git show HEAD:BUILD_STATE.md` + the block verbatim (from this report's own
  diff read at 08:28) with CRLF as the working copy had: `git diff --stat` = 17 insertions, 0 deletions,
  i.e. HEAD + the one block. The same codec had written my `—` in shot_all.sh's header as byte 0x97;
  replaced with the UTF-8 dash (`file` says UTF-8 again, `bash -n` clean). LESSON: on Windows, Python
  patch scripts open files in binary or with `encoding="utf-8"`, and never `'w'` before the new text
  is fully built — write to bytes first. The two earlier shot_all.sh patches were ASCII and unaffected.
- 08:42 Viewed `raid-clear` (1 sheet, post-fix): Results_clear reads "Cleared. / A0 — Adventure 0", the
  header "Day 24 · Known · Attempt 1 at A0", tally Rounds 9 · Mistakes 5 · Damage 212 · Healing 70 ·
  Survivors 4 of 4, "Everyone came home. This is unusual.", Loot "Payout 4 G" with the Cracked Charm of
  Power (Trinket) row — "Sell 1 G" and a Give dropdown on "Bork · Warrior (+1)" — "Morale has already
  settled from this one.", four party cards marked "cleared" (Bork 94 Loves Their Guild, Gruk 61 Happy,
  Rhona 52, Greg 52), the seven-line log. The loot hand-out CRITIC-G12 said nobody had ever looked at.
- 08:44 The queued re-shoot was withdrawn (its child killed first, then the waiter — no trap is set until
  the lock is taken, and the lock dir stayed another agent's) and replaced by ONE detached runner
  (scratchpad `runner_w0gate.sh`, nohup): seven sheets + `./tools/shot_all.sh build/shots/all` verbatim
  (the default sheet = fixture, A5's literal command) + `verify.sh --fast`, all in one lock hold, immune
  to the Bash tool's 10-minute cap that a four-deep lock queue could have hit. Lock taken 08:46:26.
- 08:48 Viewed re-shot `empty` (3 sheets) and `focus` (3 sheets), post-reset: identical to the 08:33
  views except the Settings tile now reads 100 % / Off / Off / Off (the leaked "Reduced motion On" is
  gone) and MainMenu now shows "Continue" DISABLED with "No saved guild found." beside it (LoadSave's
  slot 1 is empty too) — another agent's test run cleared user:// between runs; the disabled-with-
  reason contract holds and the ring on "New Guild" is unchanged. Camp's ring on every framed screen.
- 08:52 Viewed re-shot `text150` (3 sheets): unchanged from 08:37 — 150 % is real, Settings reads
  "Text scale 150%" with every other option at its default, and every overflow listed at 08:37 stands.
- 08:52 Viewed re-shot `emoji` (3 sheets): the type is back at 100 % and the pip strings sit on every
  card and roster line ("Bork — 87 ||||||||.", "Tiny — 14 ||......", Guildhall's "Lowest morale first"
  list, RaiderDetail's Raider panel, the Tavern seats, Results' fallen cards) with no morale face
  anywhere; Settings reads "Emoji-free mode On", "Text scale 100%". The leak is gone. CRITIC-G09's
  "never been rendered" is closed at the instrument level; the pips' proportional face is W4-PIP's.
- 08:52 Viewed re-shot `reduced` (5 sheets, 26 tiles): `<Screen>_effects` and `<Screen>_motion` sit
  side by side for all 13 screens (the contact sheet's variant sort); Settings_effects reads
  "Reduced effects On / Reduced motion Off", Settings_motion the reverse, both at 100 % / emoji Off.
  A still cannot show motion held or glow gone at half scale — the tiles look like the fixture's — but
  the sheet is the capture CRITIC-G17 asked for and W1-STAGE/W3 can diff it at full size.
- 08:53 Viewed re-shot `wide-keep` (3 sheets): all 13 tiles are 1820 wide with the 1536 frame centred
  on flat dark bars (~142 px each side), the type at 100 % and the morale faces back (the nine
  contaminated tiles are gone); Settings reads Keep / 100 % / Off / Off / Off. Viewed re-shot `tabs`
  (1 sheet, 4 tiles): Facilities / Manage / Buy / Comfort as at 08:37, and NO Guildhall_Records tile —
  the row printed `SKIPPED Guildhall_Records (press target is disabled — There is nothing to record
  until you have raided. The board opens at Known.)`, the sheet 4 ok / 1 skipped / 0 failed, exit 0.
  The exit-12 branch is exercised live, not only in the dry run.
- 08:53 Viewed the default sheet from `./tools/shot_all.sh build/shots/all` run verbatim (3 sheets,
  13 tiles, `sheets rc=0`): the fixture as at 08:33 with Settings at 100 % / Off / Off / Off and
  MainMenu's "Continue" disabled with "No saved guild found." (no save on this machine any more).
  Every sheet in `build/shots/all/` now comes from one shot.gd (mtime 08:43:07) with the settings
  reset in force; `build/shots/all.prev` (yesterday's tiles) removed.

## verify.sh --fast — summary lines (08:51:30-08:52:37, under the runner's lock hold)

```
== 0/8  lint: no cross-file class_name refs ==
  PASS  LINT OK  no cross-file class_name references in sim/ or game/
  PASS  MOTION LINT OK  tweens and morale glyphs each go through one door (docs/13 §12.2, §13)
== 1/8  script parse ==
  PASS  PARSE_CHECK scanned 151 script(s)
== 2/8  generated content matches its generator ==
  PASS  16 generated file(s) agree with tools/gen_items.gd
== 2b/8  generated art matches its generator ==
  PASS  ART CHECK  generators=5  runtime files: 76 agree  0 DIFFERS  0 MISSING
== 3/8  unit tests ==
  PASS  TESTS PASSED   1604 test(s) in 72 file(s)  [38861 ms]
VERIFY OK  (full log: .verify.log)
```
`grep -c survivors` on the whole log: 0. `grep -c "SCRIPT ERROR"`: 0.

## What is left, and for whom

Nothing of this unit's contract is left. Not this unit's, recorded for the owners:
- W0-SHOT: `--press=Records` cannot render under the wave-0 fixture (Unknown); its acceptance line
  needs the fixture at Known or must read the exit-12 refusal as the pass. The sheet skips the row.
- W0-TEXTSCALE / W1-FRAME: the `text150` sheet shows the fixed-pixel chrome not fitting 150 % type
  (header chips off the right edge, sidebars clipping, MainMenu's tagline over the wordmark,
  Completion's button cut) — `build/shots/all/text150/`.
- Completion.gd's owner: the `empty` sheet prints an empty guild name (" cleared the last fight on
  day 1") with no save loaded.
- LESSONS.md's owner (W4-HYGIENE): two lessons above — never edit a bash script while it runs; on
  Windows, Python patches open files as bytes/UTF-8 and never truncate before the text is built.
- The orchestrator: `build/shots/all/` holds all eleven sheets from one shot.gd (mtime 08:43:07);
  `build/diff/` holds the 14 post-reset scores; both are gitignored and re-made by the wave-end run.
