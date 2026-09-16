# PROGRESS LOG — archive

> Split out of `BUILD_STATE.md` on 2026-09-11. Newest first. `BUILD_STATE.md` keeps only the recent entries.

- **[WAVE 6] "Nothing lies" — the ship plan's first wave (2026-09-15).** The designer's directive came
  first: W6-COPY applied every row of LOOP's unfinished-feature table — the locked Blacksmith reads "Closed. The
  smith took a better offer.", the Board says "Clear Adventure 0 first." and "1 enemy", no rank promises a
  flagged-off building, a walked-out ladder says so on the hub and the Board — and left a copy lint in the gate
  so it stays that way, with every pinned test string retargeted rather than deleted. W6-SHEETS built the two
  fixtures a player actually reaches (Day 1, and a legal Known save cleared through the real doors) and shot
  them, added the hover sheet, made the export boot from a fresh profile and through the v10 migration, and put
  a provenance hold on the gate. W6-SETTINGS made the Options screen list only what works and the window fit a
  laptop. W6-LOG made the type lead the mistake header, wrapped instead of cut, and folded the report on a line.
  W6-AUD-BIND gave the game its first sounds — eleven hooks synthesised by a deterministic generator, byte-gated
  like the art — and bound every one to its site. W6-SIM-CASCADE armed the drift gate (stage 6b, 200 seeds, 5pp)
  and then, in one golden regeneration, made the sim attribute mistakes to their cause so the wipe report can
  say why. W6-LEDGER closed 47 audit rows, filed 12, wrote BL-82..BL-109, landed the register's 15 G Common, and
  wrote the designer page — which the designer answered the same day by delegating every decision to the loop.
  2,038 → 2,131 tests; the art gate flat; the audit at 120 done / 53 open / 17 blocked.

- **[WAVE 5] The follow-up pass after the art overhaul (2026-09-15).** Seven units under the brief-review
  rule, contracts drawn from the audit rather than the art plan. W5-MOUNT measured goto() with per-section
  laps and found the wave-4 suspicion wrong: the big cost was the screen's PackedScene and script compiling
  again on every first visit, then the 1536x1024 plate, then one Shader object per water/pulse/cloud quad —
  four strong caches and a Boot warm-up later, PERF OK on 14 of 14 screens (RaidView's revisit 156 → 37 ms).
  W5-KIT3 paid the kit's debts inside the kit (every band name whole at every width and scale, the action band
  exactly 262, empty_state placing its hint under a wrapped line, reasoned's placement, pips(), Cards.ROWS,
  ButtonMiniPicked, tab_row's min_size) with no screen edit. W5-SCALE wrote the 13-route layout test at
  100/125/150 — an allow-list that fails when a listed overflow is fixed, which is exactly what happened at the
  close when eight rows went red and were deleted — and fixed the three known 150 breaks. W5-TOOLS gave shot.gd
  --hover (four fixes to make Godot's real tooltip land in a detached capture, and the instrument's first find
  was the kit's 571px tooltip Window), deleted eleven dead crops, and cut BUILD_STATE to its rule with a test.
  W5-TESTS landed six owed test halves and the playtest's solvency invariant (which found one STUCK seed that
  was a code bug in rest_until_recovered, not a dead end). W5-DOCS wrote BL-79/80/81 and corrected BL-59, Q-35
  and nine dead anchors. W5-SIM put the tutorial mistake rate and Adventure 0's scripted round-3 mistake into
  the sim (the M11/M12 arms were already there — a stale audit — and got a second, static hold); the drift
  gate read +0.0pp. 1,959 → 2,038 tests; 23 audit rows closed (92 → 78 open); the art gate flat. Reviews were
  brief and reviews were enough. The same day the user set the finish line — five more waves, shippable and
  polished by wave 10, unfinished-feature wording hidden first — and the ship plan was commissioned as seven
  recon reports, a critic and a synthesis under build/plan/ship/.

- **[M6-FINAL-03] BUILD_STATE.md cut to its length rule (2026-09-15, W5-TOOLS).**
  The file had grown to 325 lines against its own "under ~250" (audit `M6-FINAL-03`): the growth was all in
  Current focus — the wave-0-to-4 narratives, the bare-plate table with its prose, the art-gate baselines.
  Those are history, and this entry is where they went, verbatim, so nothing the waves recorded is lost. The
  plate table now lives in `art/ref/specs/09-background-plates.md` §3 (rewritten for the bare plates) beside
  spec 00 §2.7's switches. `tests/unit/test_build_state.gd` holds the length and checks every path the file
  names exists. The sweep count is reconciled in the same pass: the default grid is 288 cells x 8 seeds =
  2,304 runs (`tools/balance_sweep.gd` :45/:47/:69/:78/:79/:153), not BACKLOG's old "1080 runs / 135 cells".

  --- moved from BUILD_STATE.md "Binding decisions" (the two setup notes under the table) ---

  Two notes on Q-15/Q-18, which the register wrote before this session's setup:
  - `git init` is **done**; canon is under version control with history.
  - **The working copy is still on OneDrive.** The register recommends moving it: OneDrive
    sync plus Godot's generated `.godot/` cache can produce file locks and import
    corruption. `.godot/` is gitignored and Godot regenerates it, and `verify.sh` would
    catch breakage, so the loop treats this as an accepted risk rather than relocating the
    user's project directory unilaterally mid-run. **Flag it to the user.**

  ---

  --- moved from BUILD_STATE.md "Current focus", as it stood at the wave-5 start ---

  **Waves 0-2 landed 2026-09-14** (instruments; the kit, chrome, icons, stage, frame, hall family, VFX; the
  screens on the foundations) — the summaries are `docs/_log/progress.md`'s ART WAVE 0/1/2 entries.
  **How a wave runs:** one agent per unit under the wave's ownership table (00-plan §0.2), each writing
  `build/plan/report-<KEY>.md` as it goes and `build/plan/handoff-<KEY>.md` for files it does not own; an
  adversarial reviewer per unit; the orchestrator applies handoffs, runs `verify.sh`, `shot_all.sh` and
  `diff_all.sh`, commits per unit. Session limits killed both waves once; the reports made every resume cheap.
  **Machine note:** the suite ran 33 s boosting and 177 s at base clock on the same code; verify's timeouts are
  sized for the slow case and the engine lock no longer adds 30 s per run.
  **Wave 3 (the second pass) landed 2026-09-15** — W3-KIT2, W3-ROSTER, W3-DETAIL, W3-OPTIONS, W3-RAIDVIEW2, W3-MENU,
  W3-ENEMIES; every handoff applied; gate green at **1,908 tests**; reports `build/plan/report-W3-*.md`, reviews
  `review-W3-*.md` (7/7 pass); the summary is the log's ART WAVE 3 entry. **Reviews are brief now** — the user's rule
  (2026-09-14): one look that the new thing shows, the unit's own test, then move on; no acceptance audits, no repair
  loops; breakage is fixed at the wave close when the full gate runs.
  **Wave 4 (polish, life and hygiene) landed 2026-09-15:** the records and guards (W4-HYGIENE — four LIES
  rows, the hex lint, `test_sidebar_fit.gd` over all 13 routes, docs/12 §7 rewritten, spec 00 §2.7's switch
  register, spec 06 §3's crimson rule, nine audit rows closed, the unit-test runner no longer rewriting the real
  `user://settings.cfg`, `tools/shot.gd` four-space); the prep strip paging through the kit, an empty bench with
  seats, the arena dimmed on the marks, a scrolling sidebar (W4-PREP); the pip figure made even AT THE FONT LAYER
  (`Fonts.with_pips` — a one-glyph bar font at the dot's advance — because the figure lives inside nine `"%s — %d
  %s"` strings in seven screens) and the faces at 24/30/36 by scale (W4-PIP); walkers on paths in the camp and the
  hub, the windmill sails as rotors over a hub patch, gulls, a waving banner, lantern flames (W4-LIFE); the kit
  cursor pair and an alpha-dilate outline on the focused/hovered callout (W4-CURSOR); `tools/perf_probe.gd` and
  verify's WARN-only latency stage (W4-PERF — frames ~10x under budget everywhere, MOUNT over 140 ms on 12 of 14
  screens boosting: RaidView 259, Guildhall 297; a follow-up item, not a failure). 6/6 brief reviews pass; every
  handoff applied; gate green at **1,959 tests**. Reports `build/plan/report-W4-*.md`, reviews `review-W4-*.md`.
  The wave-4 run died with a session restart at ~02:30 with three units mid-work and was resumed at 10:35 as a NEW
  run (finished units passed in as `reviewOnly` + their journal result, killed units given a resume note) — the
  reports on disk made it cheap; `docs/_log/progress.md` has the long entry.
  **The plan's five waves (00-plan §1-§5) are complete.** What is NOT done is §6 (the 18 designer questions) and
  the follow-ups below.
  **Next task: the audit queue** — `python tools/audit_stale.py --top 15` FIRST (see the paragraph below), then the
  follow-up pass the waves left, in this order of value: (1) the MOUNT budget — `perf_probe.gd` says every screen
  spends 90-270 ms in `goto()` and RaidView ~80 ms of it reloading its own textures from the weak resource cache
  (report-W4-PERF.md); (2) the kit's small debts — the card's class/band Label trims a morale-state word with an
  ellipsis at 100% ("Shaman — Slightly Annoy…", docs/13 §8.1 never abbreviates a band; `Roster._fit_band` is the
  interim) and the band is ~12px too tall for a 262 card with a reason; `Widgets.empty_state` draws its hint over a
  wrapped text's second line; `reasoned` wants a placement argument and Settings' volume strip a `Widgets.pips()`;
  Town's sidebar says "7 recent events" while `Cards.event_log` fits 6 rows; `Widgets.TAB_MIN` 110x32 vs the
  Guildhall's 110x28 (+8px panel to adopt); the Records sidebar's ~320px empty run; `Facilities._picker`'s
  screen-local gold rim; (3) at 150% — the Guildhall sidebar's roster block clips the morale chart (worse now that
  face-carrying lines are 36 tall), the Tavern seat card's authored face costs ~11px, Completion's CTA would wrap
  to three lines in an 88px plate; (4) instruments — `tools/shot.gd` has no `--hover` flag so tooltips, hover
  lifts and the outline are asserted numerically; `shot_all --sheet=tabs` SKIPs `Guildhall_Records` on
  `--fixture`; `Settings --focus --tab=6` lands on the rail; (5) housekeeping — the five life strips live under
  `game/assets/vfx/life/` (moving them up means rows in `gen_vfx.lua`'s vfx.json block — handoff-W4-LIFE.md has
  the recipe); M4B-CONV-02's four unreferenced `*_plate.png` crops and m4t-09's seven `badge_N.png` crops (loaded
  only by `tools/probe/Kit.gd:229`) can go; M4B-VFX-01 now owes only the airship; the emote glyphs are still
  pictograms in a PNG (Q16). Q02/Q03/Q05/Q12a/Q12c/Q18 stay behind their switches at the recommended defaults.
  **Q13's hub copy has a designer answer in the tree:** the locked Blacksmith's blurb reads "Under construction."
  (commit cfd2c29 — a direct edit during wave 3, by no unit; the lock reason the tests read still carries "maybe").

  **The audit queue: run `python tools/audit_stale.py --top 15` FIRST, then pick, and READ THE FILE BEFORE
  THE AUDIT ENTRY.** Sixteen entries had been found stale by wave 3; W4-HYGIENE closed nine more that other units had
  finished (M4B-CONV-03, M6-JUICE-05, M6-JUICE-08, m4t-01/02/03/08/09) and re-scoped M4B-CONV-02 and M4B-VFX-01 to
  what is actually left. Confirm a hit in the tree before trusting the ranking either way. Best-verified open
  candidate: `M6-BAL-02` piece 3 (the sweep's `--roster`/`--comp`/`--gear`/`--morale`/`--tuning` axes with
  `docs/14`:731's five roster fixtures — together, or the fixtures are data nothing reads).



  | Bare plate (1536x1024, installed + imported) | Source | Serves (as the tree stands, 2026-09-15 — corrected by W4-HYGIENE, TOWN-14) |
  |---|---|---|
  | `game/assets/bg/stage_camp.png` | `ideaboard/bare backgrounds/camp.png` | Town (full-bleed, offset -46,-62), AdventureBoard (-20,-80), Completion (-46,-94); the hall family — Guildhall/Roster/Facilities, RaiderDetail, LoadSave — through `Guildhall.bare_stage()` at `HALL_FRAMING = "same"` (Q03) |
  | `game/assets/bg/stage_town.png` | `town_world.png` | MainMenu only (the aerial; no figures at that scale, M4B-ACT-04) |
  | `game/assets/bg/stage_tavern.png` | `tavern.png` | Tavern |
  | `game/assets/bg/stage_market.png` | `market.png` | Market |
  | `game/assets/bg/stage_arena_cave.png` | `encounter_cave_large_full.png` | RaidPrep, RaidView, Results — `SceneStage.DEFAULT_ARENA`, every fight (Q-96 / Q18: nothing routes to the dungeon yet) |
  | `game/assets/bg/stage_arena_dungeon.png` | `encounter_dungeons_large_full.png` | authored (marks, lights, shimmer) and loaded by no screen until an encounter→arena mapping is ruled |
  | (inherits) | — | Settings stands on the plate of the screen it was opened over, dimmed (`Settings.STAGE_FOR`; default the camp at the Town's framing) |

  The table used to say Town/AdventureBoard stood on the aerial and Settings on `stage_town`; the tree never did
  (Town.gd, AdventureBoard.gd and Completion.gd load `stage_camp`, and spec 10 §1 / spec 09 §4.2 map the hub to the
  camp). The one plate per screen is now recorded in `art/ref/specs/00-canon-reconciliation.md` §2.7 beside the
  switch that frames it; whether the hall reads as its own place on the same camp is Q03.

  **Every screen stands on a bare plate** (waves 1-2: the hall family under BL-78, the mockup crops `camp_plate.png`
  and `guildhall_plate.png` deleted). Four old crops — `arena_plate`, `arena_stage`, `menu_plate`, `tavern_plate` —
  are still in `game/assets/bg/`, loaded by nothing (three comments name them as history); deleting them and
  rewriting spec 09 §3's paint-out lists is what is left of `M4B-CONV-02`.

  **What is built over the plates:** `game/ui/SceneStage.gd` is the data-driven stage — plate, `marks`, emissive
  flame strips, breathing `PointLight2D`s, ember particles, shimmer and pulse quads, cloud scroll, the vignette, the
  speech/emote bubbles, **and the actor layer** (`AnimatedSprite2D`s from `game/assets/actors/*.png`, placed by
  their feet, back-to-front, phase-spread, held by `reduced_motion`; the boss as a rank strip from
  `gen_boss_anims.lua`). It reads `game/assets/scenes/<name>.json`; `from_data()` is the seam the tests build
  through; `tools/art/preview_scene.py` composites the same stack in PIL. W4-LIFE is adding paths, rotors and
  the small life strips this wave.
  `art/ref/specs/09-background-plates.md` §4 already lists the animated layers per plate, in order, with
  coordinates — build from that table, and delete its "keep as ambient / baked v1" rows as they are replaced.

  ### Art gate baselines (after wave 4, 2026-09-15)

  `./tools/with_godot_lock.sh ./tools/diff_all.sh` scores 14 targets — the Kit probe and all 13 screens — with
  `build/plan/artaudit/00-plan.md` §0.3's masks (Concept 3 rows: scene band `0,77,1536,649`; Concept 2 rows: arena `210,77,928,640`;
  MainMenu: the menu column only, `region=0,300,520,420`). Numbers are **mae / layout_iou / within-8 %**, every
  verdict DIFFERENT (bare plates under the masks; the chrome is what is graded — a unit's rule is "does not
  regress", before/after in its commit message; kit / raidview / results jitter <= 0.07 mae between runs).
  After wave 4 (after wave 3 in brackets): kit vs 1 **26.26 / 0.184 / 41.6** (26.22) · town vs 3 36.09 /
  0.111 / 50.4 (36.08) · tavern 36.99 / 0.112 / 48.6 (36.99) · market 36.88 / 0.102 / 50.7 (36.88) · guildhall
  34.66 / 0.084 / 55.1 (34.66) · raiderdetail 37.97 / 0.100 / 47.7 (37.97) · loadsave 37.00 / 0.092 / 34.0 (36.99) ·
  settings 36.52 / 0.090 / 40.4 (36.52) · raidprep vs 2 **31.33 / 0.079 / 35.5** (31.63) · raidview vs 2 34.06 /
  0.119 / 24.8 (34.05) · results vs 2 32.31 / 0.075 / 24.7 (32.32) · board vs 1 27.54 / 0.140 / 41.4 (27.52) ·
  completion vs 1 28.12 / 0.098 / 39.4 (28.09) · mainmenu vs 3 36.13 / 0.087 / 29.8 (36.13). Wave 4 touched one
  graded screen's chrome (RaidPrep, improved) and the world layers under the masks; everything else is jitter.
  Sheets: `./tools/with_godot_lock.sh ./tools/shot_all.sh build/shots/all --sheet=all` (eleven sheets).

- **[ART WAVE 4] Polish, life and hygiene — the plan's last wave (2026-09-15).**
  Six units under the brief-review rule. W4-HYGIENE: four LIES rows, the hex lint, `test_sidebar_fit.gd`
  over all 13 routes (it caught RaidPrep's column 70-110px over its band; W4-PREP closed it in-wave), docs/12
  §7 rewritten to the pipeline that exists, the thirteen-switch register in spec 00 §2.7 with Q13's in-tree
  answer, nine audit rows closed, and the handoff that stops the unit-test runner rewriting the developer's
  real `user://settings.cfg`. W4-PREP: the strip pages through the kit, seats on the empty bench, the arena
  dimmed on the marks, a sidebar that scrolls. W4-PIP: the plan offered a mono face or a drawn row, but the
  pip figure lives inside nine `"%s — %d %s"` strings in seven screens, so the fix went into the FONT —
  `Fonts.with_pips` puts a one-glyph bar font at the dot's advance ahead of Fira, and the faces come in
  24/30/36 by scale. W4-LIFE: walkers on JSON paths (a 2-frame bob walk from `gen_actors.py`), the windmill
  sails as rotors over a hub patch `patch_plate.py` paints back from the pristine plate, gulls on a spline,
  a waving banner, lantern flames — all held under `reduced_motion` through `apply_settings`. W4-CURSOR: the
  cursor pair from `gen_ui.lua` and an alpha-dilate outline the callout lights on focus and hover, beside the
  theme's ring. W4-PERF: `tools/perf_probe.gd` and a WARN-only latency stage — frames ~10x under budget,
  MOUNT over 140 ms on 12 of 14 screens boosting, RaidView reloading ~80 ms of its own textures from the weak
  cache: the next pass's first item. 1,908 → 1,959 tests. The run died with a session restart at ~02:30
  (HYGIENE/PERF/CURSOR done, PIP/PREP/LIFE mid-work) and resumed at 10:35 as a NEW run with the finished
  units passed in as `reviewOnly` + their journal result and the killed units given a resume note — every
  killed unit verified its own report against the tree and finished within the hour. With this, the five
  waves of `build/plan/artaudit/00-plan.md` are complete; §6's eighteen designer questions are not.

- **[ART WAVE 3] The second pass: hall polish, combat beats, the menu, the bodies (2026-09-15).**
  Seven units, seven owners, one engine mutex: W3-KIT2 (the hub's event feed as a non-persisted ring
  buffer, two-line tooltips through a `TooltipHost`, log badges resolved from the icon grid with the
  Badge as the a11y fallback, a callout that pads 4/4, prints its locked reason in-row and settles
  itself), W3-ROSTER (card actions inside the card — docs/13 OQ-4 records the reversal — the AT RISK
  stamp, lit filter chips, tabs with reasons, the strip as 3x4 two-line entries, iconed records),
  W3-DETAIL (`PaperDoll.gd`: Concept 2's slot grid beside a 2x portrait; gear bonuses as "+7 AC"),
  W3-OPTIONS (nine identical slot Buttons with one reason each and a human timestamp; Settings at one
  pitch with lit values, volume pips and a secondary-lit Apply), W3-RAIDVIEW2 (every account verb fires
  a stage verb through a role-keyed VFX table — Q18's default recorded, not resolved; the wipe presses
  onto the log panel; lines settle; a PAUSED stamp; the rank sigil), W3-MENU (the authored lockup, a
  version line from `config/version`, the ending's open camp with the guild's figures and a credits
  roll), W3-ENEMIES (`gen_boss_anims.lua` derives idle/hit/death strips plus a glow layer from each
  sliced still; `place_boss` builds an AnimatedSprite2D at 1x; the 44 townsfolk breathe in four frames;
  `say_at` retires the previous speaker's plate). 1,806 → 1,908 tests; every handoff applied; 7/7 reviews
  pass — four full, three brief, because mid-wave the user ruled that reviews are one look that the new
  thing shows and then move on. Two incidents worth their lines: at 22:15 the contents of `build/` were
  deleted through Explorer mid-wave (tracked plan files back from `git archive`, the in-flight reports
  from the Recycle Bin, the agents re-created the rest — `build/plan/` is the loop's memory, clean
  `build/` by subfolder); and a resume of the wave runner re-launched four already-passed reviews
  because its cache is prefix-based — an edited review call invalidates every call after it, so a
  resumed script must make finished units skip their review stage rather than re-request it.

- **[ART WAVE 2]** The screens (2026-09-14). The hub's callouts on their buildings and a next-mission
  sidebar; the cork board with focusable notices; candidate cards with gear; the Market as a slot-grid shop;
  the fight on the floor (numbers, bubbles, bars, blots, stamps, a reasoned skip); the by-raider report and
  the clear branch; stage verbs, speakers, emotes, the drifting sky; the two mockup-crop plates deleted.
  Gate green at **1,806 tests**; `build/exports/AGuildStory.exe` (dev export, NOT SHIPPABLE stamp) boots.

- **[ART WAVE 1]** Foundations (2026-09-14). The icon grid behind `Icons.at(role, key)`; fourteen chrome
  9-slices and the palette roles, no colour literal left in Theme.gd, the morale faces as a font fallback;
  the kit composites (building callout with icon column and tail, speech plate with tail, emote bubble,
  stamp box, pooled damage number, `reasoned`, `confirm_pair`, pager, tab row, empty state, `Motion`
  constants; the strip pages in its own gutters; cards take actions inside); the stage at plate scale with
  arena `marks` and `head_of / say_at / number_at / bar_for`, feathered pulses, a vignette; one header
  (`Frame.standard_chips`, `Type.gold`), one lockup, the compact wordmark, a wide-safe frame; the hall family
  on bare `stage_camp` (M4B-CONV-03 closed under BL-78); six combat VFX strips, banded fires, cloud layers.
  Reports and reviews: `build/plan/report-W1-*.md`, `review-W1-*.md`; every handoff applied
  (`python tools/apply_handoff.py <file>` does that step now).

- **[ART WAVE 0]** Instruments (2026-09-14). `tools/shot.gd` grew `--focus --tab= --press= --advance=
  --frames= --hold-boot --fixture=raid:clear` and wide sizes; `shot_all.sh --sheet=` shoots eleven sheets;
  `Theme_.current(self)` makes `text_scale` real; `lib.lua` draws (masks, lines, arcs, dither, strips) and
  `build_art.sh --check` gates every generated PNG; every hand-cropped icon has a manifest rect; the export
  has a splash, a square icon and an `.ico`.

- **[M5-TUT-04 / -05] The tutorials' reward existed everywhere except in the content set.** The grant,
  its once-only guard, the drop-pool bypass, the skip warning's fallback copy and a test for all of it
  had shipped — naming two item ids that resolved to null, so a first clear of either tutorial handed
  over nothing, and the test BRANCHED on whether the rows existed rather than failing. The sixth
  instrument found complete and unarmed. `data/items_tutorial.json` is docs/09 §10.2 G12's pair, both
  deliberately under Adventure's own charms because docs/10 §9.3 makes the skip warning name what is
  forfeited and a better tutorial reward would make that warning a lie. The ids moved to docs/09
  §12.1's actual grammar, which needed a `TUT` source token the doc had never minted despite its own
  tier row reading "0 = starting gear and tutorial rewards" (`docs/15` BL-77). And both tutorials paid
  ZERO GOLD: docs/11 §F2 prices them in one line and neither slot was in either payout table, so
  `payout()` took its unknown-rung branch. That table is now also the tutorial test inside `Loot`, so
  `payout`, `rolls_for` and `drop_pool` cannot disagree about what a tutorial is. 11 tests; the
  conditional one is deleted.

- **[M6-BAL-02] The drift gate was complete and had never been armed.** `docs/14` §9.3 makes a balance
  regression a build failure, and every part of that was built — `--drift`, `--rebaseline`, the 5pp
  bound, Wilson intervals, a refusal to compare below 100 seeds — except the one step that switches it
  on. The baseline had never been generated, so the command answered "NO BASELINE" and nothing was
  gated: the fourth instrument this week found complete and never called.
  `tests/baselines/sweep_baseline.csv` is committed now at 4,000 runs, one reference cell per slot at the
  gear that rung is sized for, and it records what the game currently IS — A1 34.2% for Commons at morale
  55, A2 99.8%, A3 98.2%, E1-E4 100%, E5 75.4%. Proven by reintroduction: halving `AC_K` moves E5 by
  +9.8pp and the gate names it. It sits in its own gdignore'd directory because Godot imports a `.csv`
  and `test_project_hygiene.gd` allows an `.import` only under `game/`, while `tests/golden/` cannot be
  ignored — `Scenarios.gd` is preloaded from it. The run is ~95s and §9.3 calls it nightly, so six cheap
  tests hold the baseline's shape instead.

- **[M6-JUICE-08] The wipe sequence's last two beats were art, and now they exist.**
  `tools/aseprite/gen_wipe.lua` authors both through the pipeline that already draws the kit, and neither
  colour is a new one — that was the item's stated trap. The blot is the ink `Widgets.stamp()` already
  uses, so the bleed is the same substance as the word it spreads from; the seal is the CTA plate's wax,
  because the commit control is what this project already calls wax and a second one would read as a
  different material. Deterministic by construction: a fixed lobe table and a sine wobble rather than
  `math.random`, or every build would carry a diff nobody made. The first render splashed instead of
  bleeding — a tight fade and a high-frequency rim read as a splat, which is the wrong event for a page
  being filed — so the fade doubled and the wobble halved, checked by compositing and looking. The ink is
  added BEFORE the stamp so sibling order puts it under the word, and neither beat takes §13's stamp
  floor: the doc gives that to the stamp alone and names the bleed among what reduced motion turns off.
- **[M6-DOC-07] The queue had been lying, and it cost the pick twice.** Thirteen open audit items turned
  out to be finished in one week — the work had landed inside other items and nobody walked back to the
  plan — and on two consecutive iterations the chosen item was already done, so the iteration spent its
  first third choosing again. `tools/audit_stale.py` ranks every open item by how much of what it NAMES
  already exists in the tree, which is the shape all thirteen had. It is a DETECTOR AND NOT A JUDGE and
  its header says so: the false positive is an item whose premise is "this exists but nothing calls it",
  and `M6-JUICE-08` — filed the same day, genuinely open — scores 5 of 5. It closes nothing itself.
  `tests/unit/test_audit_hygiene.gd` holds the invariants that keep the queue readable, and deliberately
  does not assert that no item is stale: that is a judgement about the tree, not a property of the file.
  Eight items reconciled in the pass (`M5-COMEDY-06` and `m5-m02-raid-wide-ac` were live sim bugs already
  fixed; `M6-DOC-01`, `M6-A11Y-02`, `Q59-0`, `M5-TUT-07`, `M3-SAVE-05`, `DW-B2` likewise), and step 1 of
  the loop brief now names the tool.
- **[M6-JUICE-03] The wipe sequence was one beat of six, and it arrived at the wrong moment.** `_process`
  waited the whole 2.4 seconds and then dropped a static Label, so a player who had just lost twelve
  raiders watched nothing for two and a half seconds and then saw a word. Five of `docs/13` §11.4's six
  beats now land at their documented offsets: the account stops and the stage holds every animation on
  frame through 400ms of silence, the `[R<n>] WIPE.` line writes into the log, the stamp presses
  1.15→1.00 and −7° over 180ms, the page dims 12%, and focus hands off to the left exit. Driven by a
  CLOCK, not `await` — §11.4 requires the sequence be abortable on any input and an await chain cannot
  be, so skipping now fires every beat at once and leaves the same state watching does. **It is the first
  thing built on the motion gate**, which is why that landed first: §13's "stamps still land but at 60ms
  with no rotation" is two instructions, and `motion_duration(180, 60)` and `motion_scale()` each carry
  one. The ink bleed and the wax seal are art that does not exist (`M6-JUICE-08`); t=1,800's post-mortem
  slide is a screen transition and belongs to `M6-JUICE-02`. Both are named in the code rather than faked.
- **[M5-COMEDY-11 / BL-76] Three gates checked the comedy line and no two agreed.** `docs/10` §6 makes
  `comedy_line` required and says why — "if it cannot be filled in, the encounter is a chore and should
  be cut" — so it is a cut rule wearing a content field. It was checked at 40 characters by one test, 20
  by another and non-empty by the validator, and the corpus passed all three by accident.
  `Encounter.COMEDY_LINE_MIN` is the one bar now, enforced by the validator and read by both tests, and
  its comment says what it is for: a placeholder detector far below the shortest shipped line, whose job
  is to refuse "TBD" and never to judge whether a joke lands. Two checks nobody had made now exist —
  every encounter in `data/` carries a line, and no two share one, the copy-paste failure this field
  exists to prevent — and both walk the FILES, because BL-69 keeps unnamed tiers out of the default mount
  and a DB-based check would have seen ten of forty-two. **`BL-76` settles the contradiction the audit
  found:** §6 said "one sentence" and five of the ten hand-authored lines are two or three. The doc
  moved, because those are the better writing, and sentence count stays untested — counting full stops
  would be policing prose, which `docs/16` R-3 reserves for a human.
- **[M6-A11Y-04] The second accessibility option this week with one consumer and no enforcement.**
  `docs/13` §13's emoji-free row was implemented in `GameSettings.morale_glyph()` and read by one screen
  out of eight — so a player who turned it on got a pip figure on the raider panel and emoji everywhere
  else, while Settings offered it with an empty `reason`, i.e. as fully live. Five sites converted (the
  helper's own comment already claimed "there is nothing left to forget", which was false by five), and
  the rule joined `tools/lint_motion.sh`: reading the raw emoji table anywhere under `game/` now fails
  the build. Two rules in one lint because they are one idea — an option is only as live as its least
  careful call site. Verified by LOOKING as well as asserting: `tools/shot.gd` gained `--set=key=value`
  for the whole `docs/13` §15.1 inventory, and the Tavern card at `emoji_free=true` reads
  "starts at 46 |||||....." with the state word beneath it and no overflow. `M6-A11Y-03` (the focus
  ring) and `M6-A11Y-08` (the Tavern state word) were both found already done.
- **[M6-JUICE-06 / BL-75] The reduced-motion gate is built before there is anything to gate.** The
  setting had one consumer — `SceneStage`, stopping its own flames — and the game contains zero tweens,
  which is why the gap had cost nothing yet and why three queued juice items would each have had to
  remember it. An animation that ignores reduced motion looks exactly like one that respects it unless
  you are the person the setting is for, so the rule is a LINT:
  `GameSettings.motion_duration(ms, floor_ms)` applies it in one place, `Widgets.tween()` is the only
  door, and `tools/lint_motion.sh` fails the build on any other `create_tween(`. The zero is the design —
  a 0.0-duration tween completes next frame and still applies its final value, so a call site needs no
  branch — and §13's stamp keeps its 60ms floor because the doc names it. **§13's flashing row turned out
  to be an ambiguity** (`BL-75`): read literally it bans the shipped art (9 fps flames, 5 fps idles). The
  UI-only reading ships, because §12.2 already says ambient motion belongs to the world layer and is doc
  12's; both readings are switched and tested, the literal one held as a measurement of what it costs.
- **[M6-BAL-01] The Adventure ladder had never been measured at the gear it is played in.** `docs/08`
  §9.1a's two intermediate kits — starting armour plus feet and the first weapon, then plus legs — could
  not be built by `Scenarios.gd`, a gap the sweep's own header had been declaring for months. So
  `starting` and `adventure` only BRACKETED the ladder and not one cell in 1,872 runs sat on the stage a
  rung is sized for, which is the one number that answers whether a rung is fair. Both stages now build
  with their contents quoted from §9.1a item by item, no charm at either (its list does not include one,
  and adding it would make the swept party stronger than the party 54.9 and 58.2 were measured on). 288
  cells, 45.7s, SWEEP OK holds, and the Adventure table stars the diagonal. **It is the evidence
  `M6-BAL-04` was missing:** a Common party clears A1 at 50% and A2 at 63% at morale 55 and neither at
  morale 15, A3 at 0% for Commons at any morale — and the ceiling canon gives a new guild is 45, so the
  cliff runs through the only morale a starting roster can reach.
- **[M6-EXP-06] The generator's own check had never once been run.** `gen_items.gd -- check` rebuilds all
  sixteen Tier 2-5 files in memory, compares them to what is committed and writes nothing — and it had sat
  uncalled since the day the generator was written, which is the same shape as the last two findings: an
  instrument built and never wired. Neither option the audit proposed was needed; the existing mode
  compares the whole corpus against the real generator, where a re-deriving unit test would have been a
  second implementation competing with the first. Now `verify.sh` stage 2/8, proven by reintroduction —
  add 7 to one `ac` and the gate names the file. It stays OUT of `export_build.sh` on purpose, and a test
  asserts that too: a release build must not rewrite the tree it is packing. The generated files' own note
  said "nothing will warn you", which was true when written and is not now, so all eight were regenerated
  to say what actually happens. `docs/15` BL-74 and `docs/14` §10.1 both record that all six pre-export
  gates run.
- **[M6-PLAY-01] The campaign gets played, and it does not finish.** `tools/playtest.gd` walks the whole
  Tier 1 ladder eight times, driving the campaign rather than the UI — which meant extracting the ladder
  and the party suggestion out of the screens into `RaidPlan` first, because a harness that walked its
  own ladder would prove a game nobody plays is completable. 49 duplicated lines left RaidPrep, 12 tests
  hold the shared rules, and both bounds are derived (`docs/15` Q-90's attempts, `docs/02` §4.3's slowest
  recovery). **Its first run found a closed circuit, filed as `M6-BAL-04`:** a new guild is twelve
  Commons, `docs/05` §8 puts a Common's baseline at 45, and §8's drift stops dead at the baseline — so
  `rest_until_recovered()` can never return a roster above 45 at facility tier 0. At 45, in full Tier 1
  Adventure gear, six of eight guilds stop at A2 and two at A1. The sweep's own lever readout says morale
  moves clear rate by 100pp; canon pins the starting guild at the bottom of it, and with no clears there
  is no gold for the facility that would raise the baseline. Gate stage 6/7 WARNS rather than fails, and
  says in its own comment that the warning becomes a failure the day the ruling lands.
- **[M5-QAB-6] The achievement board had no caller, and now it has two.** 988 lines of engine, 40
  validated records and a reward model with caps and refusals — all of it load-bearing for nothing:
  `Achievements.evaluate()` was called from nowhere and GameState had no field to write an earned record
  into, so every row read Locked forever, "Records 0 of 40" was what a guild that cleared the game saw on
  three screens, and no reward had ever been paid. Three pieces in one commit: persisted state (earned
  keyed to the DAY it happened, claimed, and town flags kept clear of `docs/14` §5.2's build-flag
  registry), evaluation at the attempt — the only moment the event-only records can be decided — and at
  every `docs/14` §7.4 save point, and the claim hand `Guildhall.gd` already had a comment for and no
  button. Save v16 with its four parts. **One design defect found while wiring it:** board coin paid
  through `add_gold()` would have fed `gold_earned_lifetime`, and the cap is 15% OF that — a faucet that
  widens itself every time it pays. `add_gold()` grew `counts_as_income` and a test pins it.
- **[M5-QAB-5] The reward cap had no denominator, so it was a share of nothing.** `docs/11` §11.2 caps
  board coin at "~15% of lifetime income" and `docs/15` caps its reputation the same way — and nothing in
  the build counted lifetime anything, so `Achievements.coin_cap()` divided by `_prop()`'s zero fallback
  and every cap was zero. Three persisted counters that only ever RISE, because both figures that looked
  like they could serve instead fall: `gold` is what is left after spending and `reputation_points` is
  reduced by the disband penalty, so a cap taken from either would shrink as the player played. RP is
  counted at the AWARD, before the penalty can reach it. The opening 60 G is seed capital rather than
  income — the other reading is defensible, which is why a test states this one. Save v15 cost its four
  parts again: the bump, a registered stamp step, the freeze record moved, and a committed v14 fixture.
- **[M6-DOC-06] Eight citations in shipped code pointed at plan files that do not exist.** `build/plan/`
  is the loop's working memory and the one directory `test_docs_links.gd` never walked. Thirteen sites
  across nine files repointed — each by reading the citing comment and the candidate, never by matching a
  filename — and the lint gained a fourth failure mode, verified by reintroducing a dead path. Two of
  them turned out to be citing documents that were **never written at all**: `handoff-debt.md` §1 was
  cited twice for the edits that delete a deprecated alias block, and the work behind it (audit
  `M3-TUNE-04`) had sat untracked for four milestones. Where nothing holds a decision any more the
  comment now says so instead of naming a file — the save screen still has no `docs/13` §5 row, and the
  Tank Swap and tier-scaling switches still have no `docs/15` entry. **The archaeology turned up a much
  larger hole, filed as `M5-QAB-6`:** `Achievements.evaluate()` has no caller anywhere, and GameState has
  no `achievements_earned` field at all, so all 40 records read Locked forever, "Records 0 of 40" is what
  a guild that cleared everything sees, and no reward has ever been paid.
- **[M6-EXP-01..05 / BL-74] The game exports, and the build actually boots.** `export_presets.cfg` and
  `tools/export_build.sh` were swept into the rename commit unreviewed and had never once been run. They
  work: sim purity, the 6-stage gate, import, Windows **and** Linux presets, five pck-hygiene greps at
  zero, and — the step that separates a build from an artifact — the exported console wrapper booting
  clean for 180 frames from the pack, because `--export-release` returns 0 over a project that cannot
  start. `docs/14` §10.1's pre-export gate list named five tools this project never grew and demanded
  ripgrep, which is still not installed; `BL-74` maps all six gates onto the command that runs each one,
  corrects four rows of §10.1 in place, and records gate (2) as the single one still owed rather than
  dropping it — §10.1's own rule is that a gate that cannot run is not a gate. `test_export.gd` now
  holds the configuration nothing could previously notice going wrong. **A release is blocked on
  CONTENT, correctly:** 16 files carry `stats_pending`/`name_pending`, so a plain run HOLDS and `--dev`
  stamps the result NOT SHIPPABLE.
- **[M5-END-3] The endgame had been built for weeks and was invisible.** docs/10 §13 row 2's three
  continuing activities: repeat clears (the payout decay and the halved repeat RP) and the Legendary
  collection were both ENGINE-complete and displayed nowhere — `legendary_classes_found` had no reader
  in `game/screens/` at all. The meter is now on the Tavern, where they are found, beside the record
  wall on Records, and the Adventure's Board states the goal under its own subtitle once the campaign is
  finished. One phrasing across four surfaces, and nine is never typed: it is the class list's length.
  Both placements were decided by a SHOT, not by guessing — the first try put the board's goal in the
  sidebar, where it clipped through the panel and took "Back to town" with it, and wrapping that column
  in a ScrollContainer did not save it (no visible bar, same cut). Moving the line was the fix; the
  scroll was reverted. `tools/shot.gd` gained `--completed` so the three post-clear surfaces can be
  looked at at all, since tier 5 does not ship until it is named.
- **[M5-END-2 / BL-73] The ending fires into a screen, and doc 13 finally carries the row doc 10 gave it.**
  `docs/10` §13 row 1 asserts the beat and hands the SCREEN to doc 13 — whose inventory ran S01–S16 and
  never gained it, so the doc that owns S17 had no spec for it. §5 now carries the row and §9.5 the panel
  spec; `BL-73` records the propagation and why amending doc 13 is legitimate rather than invented canon.
  The screen is a report and a door back to town (Q-88: the save continues), built only from figures the
  campaign already keeps. Three things are rulings, not layout: the beat is spent on ARRIVAL, so closing
  the game while reading it counts as having seen it; Results' exit row collapses to one crimson commit
  while the beat is pending, so it cannot be walked past; and the credits block is DATA, read from
  `data/credits.json`, which ships one line saying the roll is unsigned — who this game credits is a
  person's signature (`M5-END-4`), and a build loop inventing names would be inventing people.
- **[M5-END-1] The game gets an ending, and the save keeps it.** docs/10 §13 row 1 (Q-88): the campaign
  finishes on the FIRST clear of the last encounter of the last tier, and the save continues rather than
  being taken away — so it is three fields, not a mode. The trigger resolves through the encounter record
  rather than an id, so renaming content cannot move the ending. `Achievements.snapshot()` had been
  looking for `completed` all along and defaulting it to false, which meant a campaign-complete
  achievement could never fire; that wire is connected. The save freeze demanded all four of its parts in
  one commit — version bump, a registered migration step, the frozen shape moved, a fixture at the version
  left behind — and my first comment claiming "no step needed" was wrong; the test said so.
- **[M5-QAB-1 / -2] The achievement board gets its first test, and eight records get their citations.**
  988 lines of engine and 40 records, wired into the Records tab, never once run against an expectation.
  The suite holds the data's shape against docs/11 §11.1's own type split, the rule that canon has no
  dailies, the Known-rank gate stating its condition, the locked/earned/claimed walk, and the faucet: the
  15% cap from Q-69, and a claim REFUSED rather than quietly paid smaller when it binds. The subtle one
  is the reason it needed a test: conditions decidable only while an attempt is being recorded must
  answer "not now" rather than "no" against a bare snapshot — answer "yes" and every reload hands out
  every event achievement; let the earned set forget and a reload takes them away. Eight records had
  shipped with no `_doc`; each turned out to be a per-tier repeat or a direct instance of §11.1's own
  examples, and now says so.
- **[M5-T25-07] The generator learns to leave hand-written rows alone, and three trinkets in four start
  dropping.** docs/09 §13.5 says capstones, trinkets and "any item with a joke in it" are hand-authored
  forever — in files the generator rewrites, which meant the first joke anybody wrote would vanish on the
  next run with nothing in the diff to explain it. A row marked `hand_authored: true` now wins over its
  generated twin; an UNMARKED edit is still overwritten, because claiming a row is what makes it
  authorship. And the Boss 5 trinket pool was loaded, validated per tier, and then read by nobody: `Loot`
  picked the first trinket of the right tier by sorted id, which is always ARMOR, so three quarters of
  every pool was content no player could ever see. It is a seeded draw now, and a test walks 59 seeds to
  prove every trinket can arrive.
- **[M5-T25-11] The ladder gets a validator, and it caught my own rules first.** `tier_rule_problems()`
  checks the four things no single encounter record can see: coverage (docs/10 §10), the escalation rule
  (§473's "at most two mechanics the player has not seen"), a ladder that never steps down, and orphan
  mechanics. All five tiers pass, which is the first evidence that the generator's encounter half is
  legal CONTENT rather than well-formed JSON. Two of the rules as specified were wrong and the errors
  taught them: coverage cannot demand all four role groups, because the only mechanic that stresses
  SUPPORT is M10 and Tier 1 does not have it — so it is "the three the vocabulary can stress, plus the
  boss must not be the first fight to test anything"; and the ladder is compared SLOT BY SLOT, because
  "tier N+1's E1 beats tier N's E5" would reject canon's own tier (a twelve-round pull legitimately holds
  less HP than a twenty-two-round boss). A test documents the comparison that is not made.
- **[M5-T25-03 / BL-72] The two flat constants become curves, and the doc's own note was wrong twice.**
  `AC_K` and `MANA_TO_SPELL` are functions of the tier now, each behind a named step, each defaulting to
  tier 1 so the shipped game and the five golden hashes are byte-identical. Both of `docs/08` §9's claims
  about the tank channel were corrected by measuring the ladder that exists rather than the one it
  projected: the mitigation cap binds at **Tier 5 Boss 1**, not "roughly index 5"; and the step is per
  **TIER**, because read per RUNG the doc's own `1.5^index` over-shoots to 11.1% tank mitigation by Tier 4
  — armour that has stopped mattering in the other direction. Per tier it holds mitigation at 36-40%
  across all five. The rejected reading is held by a test so the choice stays visible. Threading the tier
  into the sim and the budget is deliberately one future commit (`M5-T25-15`): a budget sized with the
  curve and fights fought on the flat constant would disagree about how hard every tier above one is.
- **[M5-T25-02 / BL-71] Tier 1 was two corrections behind its own budget.** `docs/08` §9.2 says
  2200/2500/3200/4100/7150 and §9.3 says 61/63/65/68/73; `data/encounters_t1.json` and `docs/10` §5.2 had
  been shipping 2100/2350/3000/3800/6200 and 55/58/62/68/74 — an EARLIER §9.2, from before the +2 Power
  correction on the Boss-4 chests moved the DPS-at-attempt column. `docs/15` Q-17 had already ruled doc 08
  §9 authoritative; this is that ruling reaching the data. The HP split keeps each encounter's shape and
  the swing is re-split across each block's own swings/round. **It cost something, and the cost is
  recorded rather than tuned away:** goldens regenerated deliberately, `e5_first_clear` 21 -> 25 rounds
  against a 22-round target, and the sweep's levers moved from morale 88pp / rarity 38pp to 100pp / 13pp —
  longer fights compound the mistake tax, so gear buys less and morale buys more.
- **[M5-T25-05 / -06] The generator ran, and running it found two real defects.** 412 records across
  sixteen files. **BL-70:** the first generated rung inverted at the SLOT level — warrior_bard legs flat
  at 5 AC / 6 HP and monk_rogue legs falling 5/6 to 5/5 between the Tier 1 raid rung and the Tier 2
  Adventure rung — because §13.2 steps the family TOTAL and §13.4 re-splits it, so a share plus rounding
  can leave one slot behind while the total rises. Fixed by flooring every generated slot against the rung
  below. **BL-69:** generating the files SHIPPED 336 items called "TIER2's Boots" into the live content
  set in one command, because the loader discovers tiers by filename — three existing tests caught it. A
  tier now mounts only once `data/tier_words.json` says its words are answered, so the content is
  reviewable without being playable. `tests/unit/test_tier_scaling.gd` holds monotonicity per slot, per
  family, across rungs, and in the numbers that reach the sim.
- **[M5-T25-01] The tiers above one have a budget, and it is derived rather than invented.** `docs/08`
  §9.6 publishes twenty-five raid bosses and twelve Adventure rungs, generated by
  `tools/gen_items.gd -- budget` from §9.1/§9.2/§9.3/§9.5's own methods over docs/09 §13's gear ladder.
  **Tier 1 is in the table on purpose**: derived the same way, it lands exactly on the numbers §9.2 and
  §9.3 published by hand (2200/2500/3200/4100/7150 and 61/63/65/68/73), which is the whole argument that
  the upper tiers are canon's curve continued rather than a new one. Three things the derivation says out
  loud: the tank death clock holds at ~3.5 rounds across all twenty-five bosses; `MITIGATION_CAP` binds
  from **Tier 5 Boss 1**, where tank AC stops buying survivability (the audit had guessed tier 3); and the
  Adventure rungs are sized at their own gear stage, which is why their clock runs 5.5/4.3/3.5. Six tests
  hold it, comparing §9.6 against §9.2/§9.3 rather than against a copy of the same numbers. The generator
  would not run at all until `data/tier_words.json` existed — it now does, with tiers 2-5 `pending` and
  nothing named.
- **[M4B-CONV-05 / VFX-01 / ACT-05] The stages finished moving.** A full wipe's twelve fallen fit the
  report page instead of spilling past its clip (the column already scrolled, which is why nobody could
  SEE the overflow — six to a row at 60px against a 392px column is the arithmetic, and a test holds it).
  The water shimmers and the crystals pulse on spec 09 §5 rows 4 and 5's own numbers, with the
  reduced-motion switch travelling as a shader uniform because a TIME-driven shader is where
  `set_process(false)` cannot reach. And the arena carries the fight: twelve combatants in three ranks on
  measured ground, tanks nearest the boss, plus the boss itself, whose feet are computed from its own
  height so the tallest creature's head clears its own HP bar.
- **[M4B-ACT-03 / BL-68] Canon's armour families decide which figure is which class.** The reference
  labelled four figures; canon has nine classes, no Ranger and no Knight. The ruling: a full figure shows
  what it is WEARING, so `data/classes.json`'s four armour families take one figure's poses each —
  warrior+bard the warrior's, monk+rogue the rogue's, the three healers the cleric's, mage+wizard the
  mage's. `game/assets/actors/class_actors.json` holds a row per class with its reason and
  `SceneStage.actor_for_class()` reads it, so revisiting the ruling is a JSON edit. It **disagrees with
  `derive_busts.py`** on monk, druid and bard, deliberately: a bust is a face and a hat and pairs by
  headgear, a figure is armour and pairs by armour. One exception declared with its reason (three healers,
  two healer poses), three figures recorded unclaimed, six tests holding all of it.
- **[M4B-CONV-01] Eight of the fourteen screens are off the mockups.** Town (`stage_camp`, offset
  -46,-62, callouts moved off the figures), Tavern (-320,-130), Market (-330,-240 — it had been showing
  the CAMP), RaidPrep (`stage_arena_cave`, -30,-120), RaidView (0,-280, full-bleed, no dim), Results
  (RaidView's offset — the report is filed in the room the fight was in), AdventureBoard (-20,-80 — it had
  been showing the HALL) and MainMenu (`stage_town`, mounted as a stage so it wakes up with `M4B-VFX-01`).
  Three rules came out of it, and they are the part worth keeping: **the offset belongs to the SCREEN**,
  because every screen frames the same plate differently and the panels decide which half is even visible;
  **a window edge never cuts a figure in half**, which is what several of those numbers are actually for;
  and **the dim eases** on every screen, because the light being taken out is now ours. Two screens were
  in the wrong ROOM as well as on a crop. `m4t-11` closed on the way (`raid_void.png` never needed
  authoring). The six that remain are all the same guildhall crop — `M4B-CONV-03`.

Older entries are in `docs/_log/progress.md`.

---
- **[M4B-ACT-02] Six stages, authored against the plates rather than against the spec's crops.** Camp,
  tavern and market get 12-14 figures each; both arenas get fire and light and deliberately NO figures,
  because spec 09 §4.3 row 5 gives the twelve combatants to the raid screen and a scene with its own crowd
  would put strangers in the fight. A lantern under 12px gets a breathing light and no sprite — a 16x24
  flame strip is bigger than the lamp it is supposed to be inside. The town aerial gets no figures at all
  and says why in its own note: a person on that street is 10-14px and every strip we own is 21-48px.
  `tools/art/preview_scene.py` is the new instrument — the same stack in PIL, exact on geometry,
  approximate on light, so placing a figure's feet costs a second instead of a boot.
- **[M4B-ACT-01] The people in a scene stop being paint.** `tools/art/gen_actors.py` cuts the reference's
  own idle frames into 56 actor strips with a manifest (12 real cycles at 5 fps; 44 synthesised 2-frame
  breaths for the single-pose townsfolk), dropping three rects that were mis-cuts rather than poses. Each
  frame is planted on the alpha centroid of its bottom rows, not the centre of its box, or an extended arm
  slides the whole body sideways. `SceneStage` places actors by their feet, sorts them back to front by
  TREE ORDER (a `z_index` above zero would lift a figure over the bubbles, which are Controls added after),
  spreads the breath phase, and freezes everything under `reduced_motion`. 13 tests, one of them reading
  raw pixels so the manifest cannot lie about the art.
Older entries — the rename, the tutorials, the save freeze, the citation guard, keyboard and
colour, audio, the twelve mechanics — are in `docs/_log/progress.md`.
---

- **[1d5dcc9] The game is A Guild Story, and it gets bare stages to act on.** 50 occurrences across
  30 files renamed (including the `.exe` and `.gpl` slugs); two title-dependent arguments were reworded
  rather than substituted, and the wordmark art regenerated (the new title needs no condensing, 1.000 vs
  0.874). Six bare plates installed as `game/assets/bg/stage_*.png`, beside the old crops, not over them.
- **[c797491] The tutorials exist, and both of canon's one-tank Tank Swaps are a wall.** The three
  tutorials authored (`data/encounters_tutorial_t1.json`), `_auto_chalk()` now seeds a tutorial party by
  ROLE rather than by morale, and `_premade()` builds through `StartingRoster` (A0 went 11/20 → 20/20 on
  that one change). `TANK_SWAP_NEEDS_A_PARTNER` is a `static var`, not a `const`, so both readings of
  docs/10 §9.1 stay under test. A3 and the Tutorial Raid are pinned with their measurements.
- **[e4bbba9] The save format is frozen, the chain is walked, and the slots have a screen.** v13 with
  `skipped_tutorials`, `_v12_to_v13` registered, a four-version fixture chain (v10-v13), and
  `slot_summaries()` reporting a damaged slot instead of hiding it. S16 Load/Save shipped.
- **[292ade7] 236 citations were naming the wrong decision, and now a test says so.** docs/15 carries two
  registers — `Q-nn` (design questions awaiting a designer) and `BL-nn` (this loop's rulings) — and they
  overlap on 19-67. `test_docs_links.gd` reads the declared ids out of the doc and fails on a citation
  naming the wrong register; the exceptions are listed with the reason each was read against both entries.
- **[d860cf4] / [24eeb2b] Keyboard and colour.** Full keyboard navigation, a CVD switch with
  `tools/art/cvd.py`, and the focus check that `run_tests.gd` cannot run (it runs from
  `MainLoop::_initialize`, before the root window enters the tree) became gate stage 4,
  `tests/unit/a11y_smoke.gd`, which mounts all screens twice and asks Godot about focus.
- **[756081a] Audio, generated rather than sourced.** The whole subsystem synthesised with numpy.
- **[729b8ea] All twelve mechanics do something now, and A3 turns out to be a wall.**
  `MECHANICS_WITH_NO_BEHAVIOUR := []`. The roll site is `_phase_mechanic_checks()` /
  `_mechanic_demands()` per docs/07 §5.3(b); only M01/M03/M05/M07 demand a response, per docs/10 §10.
---

- **[8c7dd07] docs/15 stops contradicting itself.** The register sweep, and the two-register split.
- **[4a5b09a] / [22edc80] / [ee5b64b] / [a8a2673] / [5e98bb7]** The town reads the rank; the flag registry
  and the nine-quirk seam; reputation tuning extracted to `data/reputation.json`; the 228-line mistake
  corpus and its loader; ContentDB made tier-capable.


Newest first. One line per iteration: what shipped, and anything the next iteration must know.

- **[art 2]** **Every screen stands on the reference chrome.** Tavern, AdventureBoard, Guildhall/Roster/Facilities, Market, RaiderDetail, RaidView, Results, Settings, MainMenu and the Boot overlay joined Town and RaidPrep; all eleven shoot with `tools/shot.gd --fixture` (RaidView/Results need `--fixture=raid`, which runs one deterministic attempt so they have a log, HP and loot to show). 1,019 tests green throughout — presentation changed, no sim call moved. The nav list, the four header chips (rank sigil on the day chip, 00 §2.5) and the board/party paging now live in `Frame`/`Cards`, not per screen. Art that shipped: 10 morale faces, 7 slot-type glyphs, 6 rank sigils (`tools/art/gen_icons.lua`). Art that was REJECTED: the generated class portraits — 3x upscales of 30px sprite heads, mushy beside the four reference busts; they sit in `art/export/portraits_rejected/` and `Cards.portrait_for` borrows the reference bust for the four classes it depicts (warrior/rogue/cleric/mage) and shows an honest blank for the other five. Two engine lessons: `free()` inside a refresh loop that was triggered by a Button's own `pressed` is refused mid-signal — every refresh loop now uses `queue_free()`; and orphaned Godot processes from killed agents corrupt the save tests, so kill them before trusting a red suite. Three attempts to fan this work out to parallel agents died to usage limits (~4.3M tokens, one survivor); the remaining conversions were done in-session.
- **[art 3]** **Scene life, the wordmark, the raid screen, and busts for every class.** `game/ui/SceneStage.gd` builds a scene from `game/assets/scenes/<name>.json` — plate, emissive flame strips (`tools/aseprite/gen_fire.lua`, multi-tongue, authored to sit ON the painted hearth), PointLight2Ds that breathe on two-octave noise at a THIRD of the energy (the plates already carry their lighting — the lights move, they do not light), ember particles, and speech bubbles that shuffle between figures with a drawn "..." or a badge icon. Kit and Town stand on it. The reference's painted bubbles and the stray `-842` are inpainted out of the plates by `tools/art/patch_bubbles.py` (best-matching neighbour block; raw plates kept in `art/src/bg/*_raw.png`). The wordmark is pre-rendered (`tools/art/gen_wordmark.py`: Grenze Gotisch 450, condensed to the reference run width, stepped metal bands, 1px warm outline; metrics in a sidecar .json Frame reads for the baseline) and shared by Frame/Boot/RaidView/Results; MainMenu keeps a Label because the test contract reads the title as text. RaidView: the controls moved to 02 §8's bottom-left row (speed chevrons, pause, skip, the three tiers), the boss sigil is the boss sprite, the four affix cells are the encounter's mechanics (`icons/mech_<key>.png`, cut from the VFX sheet), empty gear cells show their slot glyph dimmed, the round line carries canon's target/enrage. Class busts for monk/druid/shaman/bard/wizard are DERIVED from the reference busts by re-hueing (`tools/art/derive_busts.py`) — see BACKLOG for which read and which do not. Aspect is `keep` (letterbox) after a 1920×1080 shot exposed the plates' baked chrome under `expand`; spec 11 §1 revised. Then the Kit's sidebar was measured against the concept and found +14/+14 (PanelWarm's own content margin under the Pad's — see `## GDScript gotchas`), pulled back, and the CTA learned to carry its cost line inside the plate: **Kit 19.0 → 16.9 MAE (chrome alone 16.6), Town 26.3, RaidPrep 20.2 chrome-masked; 1019 tests green.** Follow-ups in the same block: encounter art per rank (`Cards.encounter_sprite/encounter_art` — board, prep and raid show the same creature), one gear-icon rule (`Cards.gear_icon`), chevron pagers (`Widgets.pager_button`), `Frame` `tall` for strip-less screens (Options fills the page), and the bench tiles' faces drawn as child TextureRects (Button.icon beside an invisible caption had shrunk them to a few pixels). SceneStage also grew the camp's one SPEAKING bubble on Concept 3's spot (an opaque plate over the painted line, rotating the roster's own backstory bullets, JSON lines when nobody has any) and honours `reduced_motion` / `reduced_effects` — the two switches' first consumer. Inpainting that spot was tried three ways and looked worse than covering it; the raw plate is kept.
- **[art 4]** **Item art for every gear slot.** `tools/aseprite/gen_items.lua` draws the icons the sliced sheets never had — head/legs/feet/off-hand × iron/leather/cloth, plus canon's Rogue eyepatch, Monk headband and Bard lute — as masks shaded like the reference icons (1px warm outline + halo, two-pixel bevel, grain, drop shadow), 39×39. `Cards.gear_icon(slot, has_item, item)` picks the material from the item's `family` (WARBARD plate, MONK/ROGUE leather, HEALER/MAGEWIZ cloth) and `Cards.loot_slot_icon(key)` reads docs/10 §4.2's loot keys (`weapon_basic`, `offhand_healer`, `capstone`…) so Potential Rewards and loot rows show the slot they mean. Every screen goes through those two functions now; no screen indexes `item_gear_%d` by position any more. Second pass the same day: weapons by family (the reference sword for the Warrior/Rogue/Bard one-hander, a dagger when the item says so; plain / ember / arc / living staves for Monk, Mage, Wizard, Druid; a mace for the Cleric; a totem for the Shaman), a robe and a laced jerkin for cloth and leather chests, and the four charms (Armor / Health / Mana / Power) as one medallion with four stones. 33 generated icons in all; the item sheet the docs kept promising exists. Merged `art-pass` into master (fast-forward) at the user's request. 1019 tests green. The twelve paper-era Palette aliases are gone with their last call sites; `GameSettings.display_aspect` (keep | expand) has a Settings row and applies at boot.


- **[art 1]** **The visual overhaul's foundation, and the Town on the reference frame.** The three files in `ideaboard/Reference Concepts/` are the target framebuffer at 1:1 (1536x1024), so the project now renders at exactly that size and a screenshot can be pixel-diffed against them. Instruments first, because "indistinguishable" is only a claim until it is measured: `tools/art/refkit.py` (measure the references), `tools/art/refdiff.py` (score a shot — MAE, structure, layout IoU, palette divergence), `tools/art/slice.py` (721 sprites cut out of the four asset sheets), `tools/shot.gd --fixture` (exact-size capture seeded by `tools/fixture_reference.gd` so the diff measures design, not test data), `tools/aseprite/gen_ui.lua` + `lib.lua` (the 9-slice chrome, generated not hand-drawn), and `tools/diff_all.sh` as the art gate beside `verify.sh`. **Baseline MAE 171.8 -> 18.5 on the kit and 24.7 on the Town; the Town went from DIFFERENT to RECOGNISABLY THE SAME DESIGN.** Eleven measured specs live in `art/ref/specs/`; read `art/ref/specs/00-canon-reconciliation.md` before any visual work — the references contradict canon in five places (the morale row is the important one: they show a bar and a non-canon word, canon fixes `Name - 87 heart / Class - Very Happy` and forbids the bar) and canon wins every time. `Palette.gd` is now the reference's dark chrome with the twelve paper names kept as aliases, which is why 1,019 tests never went red; **those aliases must die with the last converted screen**. Two Godot 4.7 traps cost hours and are written down in `## GDScript gotchas`.


- **[iter 49]** **The nine Legendaries, eight of them deliberately nameless.** ✅ CANON names exactly one — "IE Natsuna(the shaman) **or something**" — and both `docs/03` §5.6 and `docs/04` §11.1 refuse to invent the rest, so the eight render `docs/03` §5.6's own placeholder and **a test fails the moment somebody invents one**. Everything that is not a name IS authored, because it survives the naming pass: two bullets each drawn from the real tag vocabulary, three barks, a quirk name, a gear grant. All three of `docs/04` §11.3's mechanisms for canon's "will not be bothered by many things easily" are live — subscription (an event reaches them only via their own bullets), the 0.35 negative multiplier, and the floor of 40, which a test attacks with eighty negative triggers and a fresh ledger each time so no cooldown can do the work. Three decisions logged rather than guessed: Natsuna does not start at canon's 87 (a mid-campaign snapshot, not an arrival value — BL-57), the quirks are named and inert until `docs/07` specs them (BL-58), and four of five BIG-dumb conditions are recorded rather than approximated, because an approximated one suspends a Legendary's floor on a guess (BL-59). 1,019 tests.

- **[iter 48]** **Saves — and wiring them found a bug that could have cost somebody their guild.** `docs/14` §7.2's atomic write, §7.1's header-first read, §7.3's refusal of a newer save before anything is built, the `.bak` before a migration, three slots x three rotating autosaves, Continue naming the guild it would open, and the close-request save that runs before Godot accepts the quit. **BL-56 is the one that matters**: `docs/14` §7.4's autosave triggers are at the right moments, and wiring them turned the TEST SUITE into a save-writer — `./tools/verify.sh` on a dev machine would have overwritten that dev's own save in `user://saves`, and a lost save is a lost bug report. The directory is a variable now, the runner points it somewhere disposable before any test runs, and a test asserts the suite is not aimed at the real one. Two more real defects surfaced: `played_seconds` existed as both a state field and a write parameter so header and body could disagree, and `created_at` has second resolution so two saves in the same second tied and the load menu offered the OLDER one — there is a monotonic per-campaign counter now. And `read_header` defaulted missing keys to `null`, so the first `int()` on an older header threw *inside the mechanism whose whole purpose is not crashing on a bad save* (BL-55). 999 tests.

- **[iter 47]** **The Tavern, and a correction to my own earlier ruling.** `docs/04` §3.5's card is the entire decision surface with **every backstory bullet face up before the money moves** — that doc gives the reason itself ("the joke only lands if the player knowingly hires the guy whose bullet says he quits when benched"), so a test walks a whole board and asserts nothing is hidden. All three of §3.2's refresh triggers, §3.4's free dismissal, and a Manage tab whose confirm names the -2 morale it is about to charge. ✅ C12 ("only ever 1 Legendary per class") is claimed on HIRE, not on appearance — claiming on appearance would let a player burn all nine by rerolling past them. **BL-54: BL-44 was wrong.** I ruled the Market stall unpriced and derived it from reputation, having read `docs/02` §6.2 — which has no cost column — and concluded the price existed nowhere. §11 is a building cost table with all four buildings in it, one section past where I stopped reading. The stall is a purchase now, `Buildings.gd` owns §11 as the single source, the Guildhall's duplicate copy of those costs is gone, and the Market sells its own upgrade — without which `market_tier` would have been a field nothing could raise. 978 tests.

- **[iter 46]** **The name pool and the backstory pool — canon's texture, as data.** `docs/04` §7 says why the pool looks like this: "canon's own examples — Bob, Greg, Steve — are aggressively ordinary. A fantasy name generator would kill the premise on sight." Three weighted shapes, and the collision rule that took the real work is the second one: **no `Steve` AND `Steev`**, which means the generator has to trace a mangled or epithet name back to its mundane root before it can refuse it. Backstories ship all eighteen of `docs/04` §8.3's tags at four variants each — the doc's own rule is "every tag must be listenable, or it does not ship", so each row keeps its "Listens for" column where a reader can check the claim. Every draw rule is asserted, including the canon one: a Common always draws something negative, because ✅ CANON says lower tiers are "hardest to keep happy". Both of `docs/05` §7.5's backstory hooks are now live and wired, so a raider who "cries during wipes. Every wipe" now takes wipes 1.5x harder than one who "calls every wipe 'data'". **Q-53 is the one open item a build loop cannot close**: `docs/04` §7's content-review gate wants a named human reviewer, and the failure mode is a name that means something to somebody this loop has never heard of. 947 tests.

- **[iter 45]** **Recruitment: the matrix, the roll order, and the trap sitting next to it in canon.** `docs/03` §5.1 flags in red that canon's "1%" belongs to the Legendary's MISTAKE chance and not to the chance of FINDING one — canon gives that only as "VERY SMALL" — so there is a test named after the misreading. §5.5's **rarity-before-class order** is measured rather than trusted: with eight of nine Legendary classes claimed, the observed find rate is still ~1.5%, which is exactly what rolling class first would have destroyed (by the ninth Legendary it would be a ninth of the table value). Every canon "no longer find" is asserted as a zero at every rank above it, and `docs/03` §5.4's gap-filled Established and Legendary rows are checked against the doc's own criteria — they introduce nothing early and retire nothing canon kept. Both §8.1 mitigations are live: pity forces the lowest Rare-or-better the RANK can produce (so the top rank forces Epic, not a retired Rare), and M1's modal floor holds across 40 boards. Q-52: names and backstories are injected callables with placeholder fallbacks, because `docs/03` §5.6 says in bold **do not invent names** — the riskiest arithmetic should not wait on a data file. 917 tests, green first run.

- **[iter 44]** **Morale history — and it found a six-iteration-old bug in its first test run.** Thirty Day Ticks per raider, one row each, the biggest mover of the tick named, drawn on S05 as a sparkline over the three biggest moves in words: "day 4 -11 a wipe · day 7 +7 a hot bath". A sparkline says something changed; that line says what. **BL-51, the bug:** `docs/05` §4 defines a Day Tick as "one advance of the town clock" fired by an attempt *or* a rest — and `rest_in_town()` advanced `day` while `record_attempt()` did not. Twelve raids all happened on day 1. It was invisible for six iterations because drift, the leave checks and the disband check all live inside the tick and fired correctly either way; it surfaced the instant the history stamped a row with the date and five wipes collapsed into one. `_resolve_day_tick()` now advances the clock itself, so every caller gets exactly one advance by construction. Checked the fallout because `day` seeds the town RNG: departure rolls draw a different stream now, which is the correct one, and raid seeds come from attempt counts — no golden and no sweep cell moved. 887 tests.

- **[iter 43]** **S05 Raider detail, and `docs/13` OQ-4's two-click morale repair.** The paper doll offers the best upgrade in the loot window with its delta on the button, picked by the same `item_worth` the Suggested split uses so the two can never disagree about which item is the upgrade. **The decision I am most confident about is what I did NOT build**: `docs/13` §5 names four contents and two have no data — backstory bullets need a file that does not exist and the wishlist is `docs/05` §12 Q6's later module — so both panels say so plainly (Q-48). Invented bullets would have to be deleted the day the real tags start driving morale, and until then they would read as content a player might act on. Where the morale history would go, the screen carries `docs/02` §4.5's baseline arithmetic instead, which answers the question S05 is actually opened with. Q-49: the roster-row quick-apply spends an **Indulgence** rather than a Furnishing, because OQ-4's stated reason is that repair is "done many times per cycle" and a durable one-off purchase would disable that button forever after one press. 875 tests, green first run.

- **[iter 42]** **Consumables do what they say: all six of `docs/11` §7's effects, the commit point, and the Buy tab that sells them.** The Whetstone and Draught fold into the gear profile so every formula downstream sees them without knowing consumables exist; the Guild Feast simulates at morale +5 and **stores nothing** (a test reads every party member's morale back afterwards); Steady Hands became a real `relief_bp` term through `Formulas` rather than a negative situational, because the situational modifier is clamped to zero-and-up — and it still loses to ✅ CANON's per-rarity floor, so gold buys back situational risk and never competence. The healing potion is a new phase placed AFTER the healers, because spending it first would burn gold the healer would have saved. **`RaidSim.run()` grew a parameter, so the first test written was the one that proves the empty path is byte-identical** — same SHA-256 the five goldens pin, with the argument absent, empty, and freshly built. Two doc conflicts resolved: group buffs are once per attempt (BL-46 — twelve stacked Whetstones would be +12 Power for 420 G against a doc that budgets "≈15 G, noticeable, not dominant"), and the Rally Flask's "0.5x" is the fraction given BACK, since scaling the surviving multiplier by 1.8 would make a better flask relieve less (Q-47, found by a failing assertion). 858 tests.

- **[iter 41]** **The Market — the last canon building the core loop was missing.** Sell is the half `docs/02` §6.1 calls the "primary gold faucet outside mission payouts", so it got the weight: the full inventory including everything worn, with §6.3's **"worn by" column and the confirm it exists to force** — refusing outright would make every raid-tier upgrade unsellable forever, and selling silently would let one misclick strip a tank, so the first press asks and the second sells. Plus §6.1's buy-back shelf (last 6, 1.25x, newest first, and an item sold twice moves up rather than duplicating) and the sell-all helper with its before→after arithmetic printed on the button where the decision is made. **BL-44**: `docs/02` §6.2 has four stall levels with no price anywhere and `docs/03` §7 has six rank rows, so the stall is read off reputation (✅ CANON: it "determines what starts appearing around town") and the two ladders divide by what each is exact at — rank owns the six potion tiers, stall level owns the four comfort rungs. **Q-45**: all six of `docs/11` §7's consumables change how a raid RESOLVES, so the catalogue ships complete and the Buy tab ships shut with that reason printed on it. Selling an inert potion would be worse than not selling one. 828 tests.

- **[iter 40]** **The Facilities tab: the comfort system has a screen, and building it found a save-state bug.** `docs/02` §4.5's spec in full — both level cards, the cost, the delta table, and `docs/11` §8.4's requirement that the screen say *which* of the two gates is blocking (rank first, then price, each naming its number). The quarters panel prints `docs/02` §4.5's arithmetic strip verbatim, so a player can see which term their next 260 G moves, and it warns when a purchase would hit `docs/05` §7.6's ceiling and achieve nothing. **The bug:** a screen test on a brand-new guild read a +3 morale baseline out of a Leaking Guildhall — `reset()` had never cleared `facility_tier`, `_trophy_witnesses` or `_pending_departures`, so a second New Guild in one session inherited the first one's building. The regression test asserts against the SAVE SHAPE rather than field by field, so the next field added to `to_dict()` is covered without anyone remembering this. 798 tests.

- **[iter 39]** **Comfort: canon's one line, read three ways by three docs, shipped as the two product lines `docs/11` §8.1 proposes.** ✅ CANON says only "Manage morale with comfort items". `docs/02` §4.2 made that a durable placed baseline shift, `docs/05` §7.4 made it a +8 event on a 2-tick cooldown, and `docs/11` §8.1 said do both — so **Furnishings** and **Indulgences** are separate lines, and a test from each end keeps them apart (a Furnishing must never move morale on the spot; an Indulgence must never move the baseline). Neither single reading survives on its own: event-delta-only cannot hold `docs/02`'s word *durable* without becoming the free +8-forever exploit `docs/05` §7.6 claims to block. **BL-39, the number that nearly went wrong:** `docs/11` §8.4 printed facility floors of 45/50/55/60 while saying it had adopted `docs/02`'s column "unchanged", and `docs/02` says in terms that the column is `docs/05` §7.5's +0/+3/+6/+10. The tie-break was that `docs/02` and `docs/11` work the SAME canon Steve example to different answers (62 vs 64) — the gap is exactly the disputed +2. `docs/05` wins, 62 is a test, and `docs/11`'s "build first, then the people" arc was re-measured at the corrected +3 and still holds (L2 at 4.17 G/point beats a Straw Cot's 13.3; L4 at 29.2 inverts it). Also ruled: `docs/02` §12 Q13 (BL-38), the facility rung off-by-one (BL-41), the Tavern round deferred (BL-40), and a roster-cap conflict logged for a ruling (Q-42). 785 tests.

- **[iter 38]** **"Rest until recovered" — `docs/15` BL-34's fix, with no morale number touched.** The measurement said recovery from one wipe is 8-10 Day Ticks and `docs/02` §4.3 works an example at ~30, so the complaint was a click count, not a balance number. The control lives on the Guildhall's roster tab because ✅ CANON puts morale maintenance in the Guildhall, and it **prices itself before you pay**: `Morale.rest_ticks_needed()` prints "9 days of rest will settle the roster", and a test asserts the forecast equals the days it then costs. Three things it deliberately is not: not a drift change (raising drift stays rejected until comfort items exist), **not shelter** (`docs/05` §6's leave checks fire on every tick, so the rest stops on a departure and names who left, and the forecast warns first), and not free forever (upkeep will charge it on its own). Re-ran BL-34's original twelve-wipe measurement with one rest between laps: **zero departures, roster ends at a Common's baseline of 45** — against 11 of 12 lost and an average of 1 before. Also fixed four `docs/05` cross-references pointing at a doc number that no longer exists. 751 tests.

- **[iter 37]** **Reputation: the ladder, the earning rules and the gates — and `docs/03` §6.4's nineteen-row pacing table now reproduces row by row, RP *and* rank, through the live award code.** The doc says that table is "the pacing the numbers in §6.1 were solved for", which makes it the spec and the formula its implementation; it passed on the first run, including the proof that a clean no-farm run never trips the obsolescence factor and that Legendary lands exactly on the full clear of Raid 5. Also pinned: §6.3's worked repeat curve (13/6/3/1) and its stated contract that twenty farmed boss clears (115 RP) lose to one first clear of the next tier's boss (130). **The trap I nearly walked into** — §6.2 multiplies awards by `encounter_tier`, and applying that to adventures would have inflated Adventure 5 from 125 RP to 625; §6.4's own table settles it by pricing Adventure 2 at 50 in the same table where every raid row IS multiplied (BL-37). Three decisions logged: the full-tier bonus pays once per tier because lockouts do not exist (BL-35), §8.1's M3 catch-up valve ships ON because "enable it if telemetry shows stalls" resolves to never in an offline game (BL-36), and the 20/30/50 rung split (BL-37). Wired live: clears pay RP, rank advances and announces itself, a disband applies the game's only RP loss, and the board draws itself from the unlocked tier and prints what the next rank opens. 735 tests.

- **[iter 36]** **Morale has consequences: `docs/05` §6's leave and disband checks, wired to the raid.** The doc's own worked odds reproduce exactly (a Common at 14 morale departs within four ticks 55% of the time, a Legendary 13%), band 3+ is a hard zero per canon's "Won't leave", and all four hard rules hold — including the one that is an *absence*: no plot armour for the last raider of a required class. Disband's absolute rule ("can never fire without prior warning", enforced structurally) is asserted by 900 rolls at strikes 0-2 that must every one decline. **Then measured the live loop and found a real spiral** (`docs/15` BL-34): twelve unrested A1 attempts took a guild from 48 average morale to 1 and cost 11 of its 12 raiders, because a wipe costs a Common 10.8 against 1.125/tick of drift — ten ticks of damage per attempt, one tick of recovery. **Not a tuning accident, a missing lever**: all three of `docs/05`'s recovery mechanisms were unbuilt, and §4 names resting in the same sentence as the attempt. Built `rest_in_town()`; re-measured on the same seeds the guild holds 43-56 morale with **zero departures across twelve laps**. Nothing retuned. 692 tests.

- **[iter 35]** **Morale moves in play: `docs/05` §7's trigger table, complete.** All 22 rows with their deltas, and all eight cap shapes the doc actually uses — once-per-tick, once-per-session, once-ever-per-subject, session total, rolling 7-tick window, cooldown, uncapped — in a `MoraleLedger` that round-trips through a save, because a cap you can reset by quitting to the menu is not a cap. `docs/05` §7.6's anti-farm audit is five tests. **Split the backlog item at the doc's own section boundary**: §7 (triggers) ships now because it makes morale a live system, and §6 (leave/disband) next because that machinery has no input until morale actually moves. Fixed a real fidelity gap on the way: `docs/05` §4 says morale is "stored as float so sub-1 drift accumulates", but `Raider.morale` was an int — a Common's 1.125/tick drift truncated to 1 and quietly lost an eighth of its recovery, every tick, forever. `morale_exact` now carries it and the int is the rounded display. **One test I wrote was wrong about the doc**: I asserted re-clearing cannot lift a Common past its 63 ceiling, but §7.6 says that ceiling is "without ongoing events" and that band 9 is "reachable only by active play ... the top band should feel earned". Clearing every tick IS active play; the cap bounds the per-tick gain, not the climb. 668 tests.

- **[iter 34]** **Loot can be sold, priced by formula rather than by hand.** `sim/core/Economy.gd` implements `docs/11` §6.1 — `raw = 2·AC + 1·HP + 3·Power + 0.8·Mana + 2.5·Damage`, times `docs/11` §5's gear-step coefficient (0.35 for starting armour, then 1.9^(n-1)), times `docs/03` §7's per-rank sell rate — and **all twelve of `docs/11` §6.2's worked canon rows reproduce exactly**, floor cases included. The doc chose a formula over a price list for a stated reason worth keeping: nine classes across five encounters of class-restricted drops makes hand-pricing "both a content cost and a bug farm". Sell is live in the loot window with the price ON the button, and `docs/02` §6.3's sell-all helper ships — it sells only gear **nobody** on the roster can wear, so it can never quietly take a sidegrade someone wanted. The whole canon starting kit prices at **1 G at every reputation rank**, which `docs/11` §6.2 says is the joke and also why a 15 G Common hire is not an arbitrage target. 640 tests, green first run.

- **[iter 33]** **BL-33 and BL-32 were the same question.** BL-33 ("loot starves Rogues") is not a bug: A1's eleven-entry pool is rolled uniformly, but canon's family-sharing matrix makes `ITM_T1_ADV_W1H_MH` wanted by **5** raiders while every caster weapon is wanted by **1** — so melee arm five times more slowly, which is contention working as `docs/09` §107 intends. What SHOULD have absorbed it is BL-31's bias toward items that still upgrade somebody; it never narrowed because it was computed against the whole twelve-raider roster, so benched raiders' unmet needs kept every entry in the pool forever. Fixed both by routing loot to the party that actually went: `record_attempt()` now takes the departing party, rolls bias against it, and Suggested offers party-first then the roster. **Measured, same content and seeds: 15 clears armed 4 of 6 with 20 items stranded and NEITHER Rogue armed; now 8 clears arm all six including both Rogues, nothing stranded.** 620 tests.

- **[iter 32]** **`docs/15` BL-30 resolved: the clock was right, the stage was wrong.** `docs/10` §8 applied `docs/08` §9.3's tank-death-clock formula at 7 AC / 120 HP for all three Adventure rungs while its own loot column says each rung is fought in the gear the one before it dropped. Recomputed at the real stages: A2 34 -> **38** raw/rd, A3 42 -> **50**. **A1 needed no correction** (27 authored vs 26.9 needed) — it is the one rung genuinely fought at stage 0, which is precisely why the doc got A1 right and only the geared rungs wrong. Result: the ★★★ mini boss went from **90% clear (the tier's EASIEST fight) to 29% at Content**, decisively the hardest. This RAISES pressure by the doc's own rule, the opposite of the softening `docs/10` §8 forbids. Tests now DERIVE each swing from the formula instead of hardcoding it — the test being replaced asserted a bare `42` and told the reader not to soften it, which would have flagged this correction as the very thing it guarded against. Caveat recorded: A1 and A2 now sit within one clear of each other, because the first weapon is a 3.3x output jump. 615 tests.

- **[iter 31]** **Settings, as a closed inventory.** `GameSettings` autoload holds all 18 of `docs/13` §15.1's keys — that section is explicitly a closed list, so an option not in it does not exist — persisted to `user://settings.cfg`, kept **separate from saves** because options belong to the installation and not to a guild, and corrupt-safe by construction: an unparseable file yields defaults and is rewritten rather than blocking boot. The screen shows every row, disabling the ones whose subsystem does not exist yet **with their reason**. Wired live: comedy brake, sim speed, log dwell, emoji-free glyphs, auto-loot, text scale. **Reading the owning doc caught a real gap**: `docs/01` §9's OQ#1 ruling unlocks Instant and Skip **per encounter after a first clear**, and RaidView was letting you skip a first-ever attempt — deleting the comedy on precisely the content it was written for. Also made the two sibling-doc edits `docs/01` §9 lists as owed (`docs/07` §3.1's Availability column, `docs/13` §11.2's locked Instant). 613 tests.

- **[iter 30]** **M2 milestone gate: the loop is playable end to end.** `test_full_loop.gd` walks the whole game by locating the real `Button` and emitting `pressed` — wiring, not state machine — plus no-dead-ends, two laps, documented payout, and A1 clearing to open A2. **Verified the gate is real** by cutting one navigation link: 8 assertions fail, restored goes green. Writing it immediately caught a live balance leak: **nothing respected `encounter.party_size`**, so raid prep chalked twelve for every mission and a player would have sent a full raid on a six-person Adventure — double the party DPS the Adventure HP was derived against. `RaidPlan` now asks the encounter, and healers recommended floors to **1** at party six, matching what `docs/10` §8 and BL-29 already assumed. 587 tests.

- **[iter 29]** **The raid is something you watch.** `RaidView` (`docs/13` §11) plus `LogPlayer.gd`, the pacing model split out so it could be tested at all — a reveal schedule written as `await` inside a Control is untestable by construction. Ships §11.2's cadences verbatim (1x 180ms / 2x 110ms / 4x batched, holds 700/500/300 with a hard 300ms floor), the **comedy brake** (a Severe mistake, any death and the wipe line drop to 1x even at 4x), three verbosity tiers, pause, skip, and §11.4's wipe sequence. Depart lands on the account now; Results is the paperwork after. **Caught a real bug in the batching**: `LINE_CADENCE[4x]` is 0.0 — the doc's way of writing "batched" — so the reveal loop spun past the end of a phase block and batched a mistake with lines it must never be batched with, which §11.2 forbids in terms. 4x now spends one phase's share of its 0.65s round per block. 578 tests.

- **[iter 28]** **Loot — clearing something now pays.** `sim/core/Loot.gd` (pure, seeded): canon's drop table from `docs/10` §4.1-4.2, the raid tier read straight off each item's own `drop_encounter`, `docs/11` §F1/§F2 payouts with §F5's repeat decay, and `docs/09` §14.3's loot window on Results — Suggested pre-fill, per-row override, Sell deferred to the Economy task rather than priced by guesswork. **Reordered the backlog deliberately**: RaidView was next by position, but without loot a player clearing A1 got nothing, so A2 onward was unreachable in the shipped game — a hard quality-bar violation outranks presentation. **Measured end to end: farming A1 arms the six and takes A2 from 0/24 to 6/24.** Found a real bug in my own first cut: `upgrade_delta` measured the CLASS's primary stat, but a Warrior's primary stat is not `damage`, so a +5 sword scored zero and the game handed out no weapon at all — the party farmed A1 fifteen times and came back wearing only boots. Now measured on the item's own worth, with an empty slot outranking an upgrade so "need-based" means need. Also removed a stale unchecked `Results` line that shipped in iter 25. 549 tests.

- **[iter 27]** **The game is winnable from a cold start.** Implemented `docs/15` BL-27's tier-0 output floor — `UNARMED_DAMAGE = 2`, `HEAL_FLOOR = 6` — as **floors rather than addends**, which is the decision the whole iteration turned on: a floor changes nothing for anyone holding a weapon, so **E5's first clear stayed at 22 rounds against a target of 22** and 3 of 5 goldens regenerated byte-identical. Only the two starting-gear goldens moved. Also published `docs/08` §9.1a, the starting-gear DPS stage `docs/10` §8 had asked for in writing: **stage 0 = 16.5/round**, not the assumed 88 — **5.3x** off — so Adventure HP was re-derived per rung at its own gear stage (135 / 550 / 700), the same staged rule `docs/08` §9.2 uses for raids. **Adventure 1 went from 0% clear at ANY enemy HP to 50%.** Two knock-ons found by measurement: M04 add HP had to stay a fixed fraction of the pull (60 on a 135 HP fight is 44% of it), and M02's magnitude 23 was derived for a 12-raid with three healers — at party 6 with one healer it killed the party outright, so it is 15 here (BL-29). Also **found a test asserting the bug**: `test_heal_base_prevents_zero_healing_at_game_start` asserted `cleric_heal(0,0) == 1` while its own comment explained why that was wrong. 515 tests.

- **[iter 26]** **Authored the Adventure tier (A1-A3)** verbatim from `docs/10` §8, wired it into `ContentDB`, and put it ahead of Raid 1 on the board. Then measured it and **found the real blocker one level down (`docs/15` BL-27)**: canon starting armour is four pieces with NO WEAPON and 0 Mana, and both output formulas read entirely off gear, so a starting healer's `heal_power` is exactly **0**. A1 gets **0 clears in 24 even with enemy HP cut to 40%** — the party *dies*, it does not fail to kill, which is the diagnostic that rules out any content-side fix. `docs/16` E1.3 and `docs/10` §8 both predicted this in writing; `docs/15` Q-02 already ruled the fix shape (class-fixed, off gear) and shipped the enum, but **no class base was ever implemented**. Deliberately deferred: it moves every golden and the sweep, so it gets its own iteration. Also fixed a real router bug — `goto()` from inside a screen's own button handler tried to `free()` that screen mid-signal, which Godot refuses; now detach-then-queue_free. 510 tests.

- **[iter 25]** **The loop closes.** Board -> Prep -> Depart -> Results -> Town runs the real sim and records real progress. Shipped `RaidPlan.gd` (prep arithmetic, pinned to `docs/06` §6.5's worked example), `AdventureBoard`, `RaidPrep` and `Results`, plus raid progress in `GameState` (v3 save). **BLOCKING FINDING, measured not guessed:** the starting roster clears E1 **zero times in 20 seeds at morale 95**. That is correct — `docs/08` §9.2 sizes Boss 1 for a raid already in Tier 1 Adventure gear — but it means canon's Adventure on-ramp (A1-A3, slots already reserved) is missing content and the board is a ladder with no bottom step. Logged as `docs/15` BL-26, top of the backlog, and pinned by a test so nobody "fixes" it by buffing starting gear. Also answered BL-24 (one rung = one encounter) and BL-25 (risk words are a ratio against the same comp at Content). 494 tests.

- **[iter 24]** **You can read your roster.** Shipped `Morale.gd` (the `docs/05` §8 baseline and resilience half), `StartingRoster.gd`, the `Roster` readout and the `Guildhall` tab rail that houses it. **Answered `docs/15` BL-23**: a new guild cannot start empty — raid size 12 against 60 G and 15 G Commons means an empty roster can never reach a first raid — so a new game now hands over the benchmark twelve (`docs/06` §6.4 Template A, the comp every balance number is derived against) as Commons at morale 45, with canon's Bob/Greg/Steve on their canon classes and Natsuna pointedly absent. **Found and fixed a real canon bug in existing code**: `MORALE_BAND_EMOJI` had the heart on band 9, but canon's Natsuna is 87, which is band 8 — the game rendered its own headline roster row wrong. All four canon (value, face, state) rows are now pinned by test. 466 tests.

- **[iter 23]** **The game launches.** Shipped the app spine as one unit because the pieces are mutually dependent: `Boot` (loads + validates content, and renders the validation report as a readable page rather than crashing), `GameState` and `ScreenRouter` autoloads, `MainMenu`, and `Town`. Town came forward from its backlog slot because MainMenu's New Guild had nowhere to go otherwise. **The gate's headless-boot check is live** (was SKIP since M0). Canon on screen and asserted: 60 G, day 1, Unknown, "Roster 0 of 15", five buildings in canon's own spellings. 428 tests. Three traps found, all of which produce *plausible* output rather than errors — see the gotchas: autoload names are global identifiers that a same-named `const` silently collides with; `get_node("/root/X")` returns null when the caller is not inside the tree, so screens rendered blank under the test runner; and `parse_check`'s new autoload path was a **false green** until I reintroduced a bug and watched it pass.

- **[iter 22]** **Second balance pass — all three "findings" from iter 21 were my own measurement errors, not game bugs.** The sweep fought Boss 5 while wearing Boss 5 capstones, a loadout no raid can ever have. `docs/08` §9.2 says it plainly: *"the boss is fought in the gear the boss before it dropped"* — so Boss 5's DPS-at-attempt row is **After Boss 4 (325.0)**. Added a **`raid_entry`** gear tier (Boss 1-4 drops, Adventure charm since the Raid Trinket is a Boss 5 drop); E5 now measures **22 rounds against a 22-round target**. Also corrects an error in *my own iter-21 note*: I recorded the benchmark as 286/round when §9.1's *After Boss 5* row is **329.0** — and it was the wrong row to compare against anyway, so the "~28% DPS overshoot" never existed and nothing needs tuning. **Q-22 inverts** when measured at an auto-detected unsaturated cell (E2/Adventure): **morale 100pp vs rarity 25pp**, the direction canon wants. Hardening: `_cell()` silently returned zeros for an unswept cell, so a mistyped morale printed a **fabricated** "0% clear, 0 rounds" that I nearly recorded as a real finding — unswept lookups now fail the sweep. New golden `e5_first_clear` (21 rounds) + a guard that Boss 5 drops can never leak back into `raid_entry`. 389 tests green.

- **[iter 21]** **First balance pass.** Two changes. (1) **Fixture fidelity**: the sweep/golden roster never equipped a trinket, but `docs/08` §9.1's 175/round benchmark explicitly includes one — so every measured roster was weaker than the one the damage budget was derived against. Fixing that alone took Adventure-geared Commons at E3 from **0% to 100%**. (2) **BL-21 resolved**: `ROLL_SITE_WEIGHT` 1.00/1.00/0.35 -> **0.55/0.55/0.15**, so the per-round aggregate matches `docs/08`'s published chance. Worst cell 312 -> 144 mistakes; every cell now readable. Goldens regenerated **deliberately** — `e3_commons_adventure` went attrition(26 rounds) -> **victory(19)**. Two tests updated to assert the NEW invariant (aggregate, not per-site). Lever readout now detects a saturated cell instead of printing a false reading. **Three new measured findings queued as a second balance pass.**

- **[iter 19]** **Golden tests.** 4 fixed scenarios (best case, worst case, ordinary, opening disaster) sharing one `tests/golden/Scenarios.gd` with the generator so a golden can never be produced by a different setup than it is checked against. Each stores summary + **readable story lines** + **SHA-256 of the full event stream** — the hash catches any drift, the story says what moved. 18KB total instead of 600KB of raw events. `tools/write_goldens.gd` regenerates **deliberately**. Verified to catch a one-point `AC_K` nudge. **Two balance findings recorded in BACKLOG**: best-case clears E5 in exactly the 22 rounds `docs/08` targeted; Commons in Adventure gear take 26 rounds and lose E3 by attrition against a 15-round design — the sweep must decide whether the mistake DPS tax is too steep.

- **[iter 18]** **`sim/core/RaidSim.gd` — THE GAME IS SIMULATABLE.** Eight-phase round loop per `docs/07` §4.1, sequential resolution, threat targeting, all three healer archetypes, mechanics (raid-wide/adds/enrage/ground effect), mistake rolls at all three sites, Downed→Dead, four outcomes incl. the auto-called soft wipe. Pure: **a test asserts the sim never writes to a Raider**. 23 tests. **Two defects found by actually running a fight and reading the log**: (1) `docs/07` §5.5's anti-spam guards were implemented but never wired — a fresh Context per roll meant cooldowns and the Critical cap never persisted; now round-scoped and tested. (2) **The gate had a blind spot**: `load()` succeeds while a script has parse errors, so seven `:=` inference bugs in RaidSim passed green. `parse_check` now uses `reload()`, verified to catch a reintroduced bug and to pass clean. BL-21 now has a measurement: **46 mistakes / 12 rounds**.

- **[iter 17]** `sim/core/Mistakes.gd` — the comedy engine. All 18 `docs/07` §5.2 types as data with class/role gating, context requirements and affinity weights; three roll sites; margin-based severity (`S = margin*100 + d20 - 10`, clamped to the type's band ±1 so a forgotten consumable can never be Critical); cascade attribution (`caused_by`/`cascade_depth`); anti-spam guards. **Affinity scales SELECTION WEIGHT, not mistake chance** — a Rogue is not clumsier, their clumsiness is likelier to be a facepull. **Opened BL-21**: `docs/07` §5.3 demands `docs/08` rescale for multi-site rolling and that has not happened; shipped `ROLL_SITE_WEIGHT` (action 1.0 preserves the DPS tax, mechanic 1.0 preserves doc 10's dial, ambient 0.35) and **the balance sweep must measure real mistakes/encounter to settle it**. 28 tests.

- **[iter 16]** `sim/core/EventLog.gd` — the sim's only output (`docs/07` §10), plus Verb/LogTier/Phase vocabulary in Enums. **Two rules are enforced by tests**: (1) entries are structured data, never prose — the string renders from a template at display time, which is what makes localisation and verbosity filtering possible; (2) **the sim always emits everything** and tier is a display FILTER — emitting differently per tier would make the log a source of divergence and two players at different settings would get different games. Mistakes are Story tier so no filter can hide them. `sequence` is assigned in exactly one place so golden-file ordering is a property of the code. `Phase` enum encodes `docs/07` §4.1's turn order — **RaidSim will consume it directly**. 17 tests.

- **[iter 15]** **Mistake chance merged** — the game's most important number had two values (81.6% vs 40% for a Very Upset Common). Per `docs/15` Q-04/05: `docs/05`'s shape `base * (1 + band_delta * sensitivity)` and its coefficients, living in `Formulas.gd` at `docs/08`'s ownership location, in basis points. Per-rarity `sensitivity` is canon's *"legendaries are not bothered easily"* encoded **in the curve**. All 50 cells of `docs/05` §5.4 pinned; Legendary at best morale = **0.99%**, landing on canon's "near 1%". **Recorded BL-20**: adopting these coefficients loses `docs/08`'s claimed "morale inverts one rarity step, never two" — a miserable Rare (22.4%) is worse than a beloved Common (13.9%). Shipped deliberately; the canon-anchored Legendary-beats-Epic guarantee does hold. Also fixed a latent `:=` inference bug in `apply_variance` that only surfaced on recompile.

- **[iter 14]** `sim/core/Formulas.gd` — the arithmetic core (`docs/08` §8.1-8.7). Mitigation curve, melee (Power once **per swing**), spell (Mage is per-target), the three canon healer archetypes, threat, retarget thresholds. **Both canon ambiguities are single named switches**: `AC_READING` (Q-01 ruled Reading 3, `(AC*2)/((AC*2)+60)` capped 0.75) and `MANA_MODEL` (Q-02 ruled Model A+). Variance and crit ship at **zero** on `docs/08`'s own recommendation — the drama is mistakes and morale, not dice — and `apply_variance` consumes **no RNG draws** while off, which golden files depend on. Added `heal_base` to healer weapons: canon starting armour has no Mana, so a purely Mana-derived heal would be literally zero on day one. 32 tests; doc 08's worked examples and doc 10's hand-computed tables agree to 2dp, which validates both.

- **[iter 13]** `sim/model/Encounter.gd` + `data/encounters_t1.json` — **the first real content**. All five Tier 1 encounters: enemy stat blocks, configured mechanics, canon loot slots, target rounds, enrage, and a required comedy line. Plus the 12-mechanic vocabulary in Enums (`docs/10` §10) — 40 fights get built by recombining twelve behaviours, not inventing eighty. **Every HP and swing number is QUOTED from `docs/08` §9.2/§9.3, never authored here**; if `docs/08` retunes, edit the data, do not re-derive. The validator enforces `docs/10`'s structural rules on load: **one mechanic per star exactly**, enrage = `ceil(1.4 x rounds)`, canon loot slot per encounter, and a non-empty comedy line (a fight that cannot be made funny is a chore). 23 tests. Full Tier 1 clear = 316s of sim, inside doc 01's 3-8 min loop.

- **[iter 12]** `sim/model/Combatant.gd` — per-encounter combat state, implementing `docs/07` §7.1 and §6. **The Downed state is the load-bearing rule**: the round resolves sequentially with boss damage in Phase 1 and healing in Phase 4, so without a grace state a healer *structurally cannot* save anyone from a big hit and the clutch heal never happens. Downed pins HP at 0, takes no further damage, holds threat, is not a boss target but IS a heal target, and dies at Phase 7 unless healed. Overkill (`current_hp + OVERKILL_MARGIN`) skips it. Consequence tokens (Aggro/Fire/Mana/Adds/Distraction) with canon durations are here too — they are what turn four small failures into one wipe with a story. Combat state serialises for mid-encounter resume (`docs/14` OQ-11). 27 tests.

- **[iter 11]** `sim/model/Raider.gd` — the roster record, field-for-field from `docs/04` §4 (same field names as the save file). Plus canon morale bands in Enums: `morale_band(m) = min(9, m/10)` per `docs/15` Q-06, with 70-80 renamed **"Quite Happy"** per Q-07 so ten bands carry ten names. **This reproduces canon's own four-person roster example exactly** — Natsuna 87 Very Happy, Bob 54 Content, Greg 31 Annoyed, Steve 14 Upset. **Raider holds NO combat state by design** (`docs/04` §4: combat writes only morale + 4 counters, which keeps it serialisable mid-encounter) — HP/threat/alive go in the new `Combatant.gd` task. Equipment stores item ids, not Item objects, so the record serialises without the content DB. 21 tests.

- **[iter 10]** **M0 COMPLETE.** `test_canon_guard.gd` (24 tests through ContentDB, the path the game actually uses) plus canon constants in Enums (`RAID_SIZE=12`, `TYPICAL_TANKS=2`, `ENCOUNTERS_PER_RAID=5`, morale 0-100 in ten bands). **Five infrastructure bugs found and fixed**, all of which would have bitten an unattended run: (1) the class cache goes stale whenever a script is ADDED, not just when missing — `verify.sh` now regenerates it if any `.gd` is newer; (2) `quit()` in Godot does not return, so `parse_check` printed OK *and* FAILED; (3) a script's own `class_name` does not resolve inside a **static** function headless — `Stats`/`Rng`/`ContentDB` now use a `_cls()` self-load helper and no `Twg*` identifiers in code at all; (4) the test runner **hung** on a script that failed to compile, turning every compile error into a gate timeout — it now fails fast; (5) every Godot call in `verify.sh` is time-bounded, and orphaned engine processes had been accumulating and holding file locks. Suite: 193 tests, 585ms.

- **[iter 9]** `ContentDB` + `Item` + `ClassDef` — the content layer. Loads all four JSON files, indexes **98 items**, and validates: unknown keys, duplicate ids, role/group mismatch, families that do not claim their class, two-handed classes with off-hands, dangling references, encounters with no drops, non-canon items missing a derivation note. **It accumulates errors instead of throwing** — one bad item must not hide the next — and `sim/` never crashes; `game/` boot decides what invalid content means. Item eligibility is DERIVED from family at load, never stored. On-disk JSON keeps nested `stats` and file-level `tier`/`source` for hand-authoring; `ContentDB` normalises to `docs/14` §5.3.2's field names. Half the tests feed the validator broken content and assert it complains.

- **[iter 8]** `data/items_t1_raid.json` — 48 items, per-class Boss 1-5 tables, Boss 5 trinket pool of four. **Plus a real infrastructure fix.** Godot resolves `class_name` identifiers from `.godot/global_script_class_cache.cfg`, which only `--import` writes — and in a headless-only workflow *nothing ever created it*. It worked until `Stats.gd` needed its first cross-file reference, then failed at runtime while every static check stayed green. Three changes: (1) `verify.sh` regenerates the cache when missing; (2) `sim/` now references other scripts via `const X = preload(...)`, never a global class name; (3) `tools/lint_no_global_classes.sh` enforces that and is wired in as gate step 0 — proven by injecting the bug and watching it fail. Side effect: suite runtime 3.8s -> 0.39s.

- **[iter 7]** `data/items_starting.json` — 22 tier-0 pieces plus a `starting_sets` map (class key -> 4 item ids) that the recruiter will consume. Canon facts pinned: starting gear is **AC only** and **armor only** (a Common recruit arrives unarmed, no weapon/off-hand/trinket). **Name collisions are real and deliberate**: canon's `Worn Leggings` is 2 AC for Warrior/Bard and 1 AC for healers — kept as two items disambiguated by family per `docs/09` §5; merging them would hand every healer a free +1 AC. `Worn Trousers` and `Old Sandals` collide too but agree on stats. Note Monk/Rogue and the three healers get *distinct* named starting pieces despite sharing an armor family at every later rung. 15 tests incl. all nine canon AC totals (7/7/6/5/5/5/5/4/4).

- **[iter 6]** `data/items_t1_adventure.json` (28 items) **and resolved BL-19**: canon's slot matrix and canon's item tables disagreed about Warrior's head slot. Item tables won — `WARRIOR_HEAD` is gone, `WARRIOR_BARD_HEAD` is claimed by both. Enums/classes.json/tests updated together. Canon Tier 1 Adventure has **no off-hand items at all** (off-hands start at Raid rung) — that is canon, not a gap. The three healer weapons are the only non-canon entries (`canon: false`, +10 Mana, `docs/09` §10.2 G11). New integration test equips every class from `classes.json` using this file and checks the ideaboard totals — the strongest guard in the suite so far.

- **[iter 5]** `data/classes.json` — all nine classes with canon role/description, role group, the four equipment families, base HP from `docs/08` §6 (Warrior 120 … Mage/Wizard 65; canon has no base HP, this is PROPOSED), primary/secondary stats, 2H + dual-wield flags. Rarity HP multipliers ship at 1.00 deliberately. 19 tests **cross-validate** rather than spot-check: every family a class names must claim it back in `Enums.FAMILY_CLAIMANTS` (itself pinned to the ideaboard matrix), and base HP + canon armor HP must reproduce `docs/08`'s published totals (136/114/106/99/87/75). **Decisions found in `docs/08` that later iterations must honour are now in BACKLOG Discovered work — read them before writing `Formulas.gd` or `Mistakes.gd`.**

- **[iter 4]** `sim/model/Stats.gd` — the five-stat value type. Non-mutating `add`/`subtract`/`scaled`, mutating `accumulate`, static `sum`, enum-keyed `get_stat`/`set_stat`, `to_dict` (omits zeros, mirroring the ideaboard's `—`) and strict `from_dict(d, errors, context)` that **reports unknown/non-integer keys instead of ignoring them** — ContentDB will collect those errors. Deliberately knows nothing about what stats *mean*; the unresolved `AC = 2 damage reduction` reading stays isolated in Formulas.gd. 27 tests pin every canon total (15/14/13/9/8 AC, 21 and 28 AC raid Warrior, healer 27 Mana, weapon and trinket values).

- **[iter 3]** `sim/model/Enums.gd` — shared vocabulary: 9 classes, 5 rarities, 7 slots, 5 stats, 9 canon roles + 4 role groups, 19 item families with their claimant classes, encounter kinds, 6 reputation ranks. Each has a stable **string key (persistence contract — never rename; append only)** plus a display name. `FAMILY_CLAIMANTS` is the single source of truth for loot contention — nothing else may hardcode who wants a drop. 19 tests incl. rebuilding the canon equipment matrix cell-for-cell.

- **[iter 2]** `sim/core/Rng.gd` — deterministic PRNG per `docs/14` §8: xoshiro256** draws, SplitMix64 seeding, FNV-1a channel hashing, per-channel derived streams (`rng.derive(channel, round, actor_ordinal)`), unbiased `next_below`/`randi_range`, basis-point gates (`chance_bp`), `shuffle`/`pick`/`pick_weighted`, `get_state`/`from_state`. **All sim randomness must go through a derived channel stream** — channels: damage, mistake_gate, mistake_type, severity, targeting, compliance, loot. 25 tests, incl. known-answer vectors from an independent Python implementation (not self-captured).

- **[iter 1]** Art + run tooling: `tools/run_game.sh`, `tools/build_art.sh` (runs `tools/aseprite/gen_*.lua`, exports every `art/**/*.aseprite` to `build/atlas/` as packed sheet + json-array with tags/layers, incremental via mtime, `--gen`/`--clean`). Validated end-to-end against a throwaway generator incl. the failure path; art/ is intentionally empty until M4.

- **[setup]** Foundations: git repo, `project.godot` (1920×1080, nearest-neighbour filtering), test harness (`tests/TestCase.gd` + `tests/run_tests.gd`), parse checker, `tools/verify.sh` gate, Aseprite headless pipeline verified. Gate green with 3 tests.

---
