# report-W6-COPY — no screen admits an unfinished feature

Wave 6 · started 2026-09-15 · contract: build/plan/ship/00-plan.md "### W6-COPY".

## Acceptance (from the contract)

- [x] `tools/lint_copy.sh` prints `COPY LINT OK` over `game/` (run by hand in-wave)
- [x] `tests/unit/test_copy_lint.gd` green (the same grep in-process)
- [x] Town `--fixture=new`: Blacksmith callout with no "Canon"/"build" word (C1/C2 -> "Closed. The smith took a better offer."; `blurb` the one source; three "maybe" pins retargeted)
- [x] Board reads "Clear Adventure 0 first." (LOOP-03: `RaidPlan.locked_reason()` prints display_name; CTA sub-line drops the slot; test_ladder / test_raid_plan retargeted)
- [x] Board/Town read "1 enemy" (LOOP-04/UI-02: `Type.count(n, "enemy", "enemies")` at both sites)
- [x] LOOP-06 guard: `AdventureBoard._standing()` names a tier only when mounted; `Town._town_unlock_line()` prints `Reputation.town_unlock_for_build(rank, flags)`; `data/reputation.json` town_unlock split into ids; the "120 more to Known" pin gains the mounted-tier clause
- [x] LOOP-07: every tier-1 rung cleared -> Town "The ladder is walked out", Board "Raid 1 is cleared. The road past it is not open yet." (new test in test_screens.gd)
- [x] LOOP-14/UI-50 (C22): Raid Group tab dropped from `Guildhall.TABS`; pins retargeted to three tabs; test_full_loop green
- [~] LOOP-15 (C9/C10/C11): "The record wall opens at Known." owned by `Achievements.unlock_reason()`; the Records tab's caption and body print it; C9's false sentence gone. HELD TO THE HANDOFF (§3-§7): the "View All" -> "Records" relabel — test_event_feed.gd / test_widgets_kit.gd (not mine) pin "View All". The link's reason STAYS "Opens at Known." (C10 KEEP): the long sentence in the log's head row overflows the panel at text scale 150 on six screens (measured).
- [x] LOOP-16: `>= 40` clause removed in Roster.gd and RaiderDetail.gd; a 45-morale raider's "Cheer up" is live with gold in hand (test_roster_layout.gd)
- [x] LOOP-17/UI-27 (C12/C13/C14): `_written()` prints "Nothing is written down about them yet." alone; Quarters line "Settles at 45 — Common, no furnishings." with the breakdown as tooltip; starters draw a backstory; no "module"
- [x] CONTENT-20: starters draw names through `NamePool.pick(rng, taken)` after Bob/Greg/Steve; `NAME_POOL` deleted; test_starting_roster reads data/names.json
- [x] LOOP-24 copy: the skip block reads "This one is hard. Skipping it forfeits the trinket and nothing else."
- [x] LOOP-27 (C8): Completion prints the roster block and, with `lines` empty or marker-only, nothing else; pins retargeted; no "not written yet"
- [x] LOOP-20 copy: Market `:355` and Facilities `:163-166` print the level's NAME and effect; the look sentence only when a layer exists
- [x] UI-12: `Cards.event_log`'s `hint` defaults to the hub's line
- [x] UI-14 Board half: exactly `n` reward cells; `n == 0` prints "Nothing worth carrying."; the trinket icon is the charm's
- [~] UI-51: `Cards.recent_events` folds same-note morale rows per day into one sentence (MORALE_SENTENCES covers every Morale.TRIGGERS id and NOTE_SIGN); <= 2 morale rows per day; the raid line first; test_kit3.gd. HELD TO THE HANDOFF (§9-§11): a ONE-raider row prints the raw pair ("Bob: wipe") behind `Cards.SINGLE_ROW_SENTENCE = false`, because test_a11y_legibility.gd:657-727 (W6-SETTINGS's file this wave) finds rows by `text.ends_with(note)`; the flip is one constant.
- [x] C24 interim: handoff §1 (RaidPrep sub-line) and §2 (RaidView boss plate) written
- [x] Shots viewed: `Town --fixture=new`, `AdventureBoard --fixture=new`
- [~] `verify.sh --fast`: every stage green except stage 3, which is red on exactly FOUR assertions in two test files no wave-6 unit owns (test_paper_doll.gd x3, test_text_scale_layout.gd x1) — pins on strings the directive removed ("50 base" as the Label, "They are fine", "Wants nothing in particular", the allow-list key "1 enemies"); handoff §12-§15 carries the retargets, proved green on a backed-up tree. 2122/2126 pass. `lint_motion.sh` OK; `lint_copy.sh` OK; a11y_smoke 26 mounts PASSED.

## Log (what I did and saw, as I go)

- 13:50 `tools/lint_copy.sh` written (awk, no python; comment-stripped literals; push_error/print lines skipped; allow-list keyed by file|fragment, self-policing on stale entries). First run found exactly the five strings this unit removes (Town:567, RaiderDetail:760/765/773, Completion:104). After the code edits: `COPY LINT OK ... 20 allow-listed fall-throughs, all present`. PARSE_CHECK OK over 187 scripts.
- Code landed (parse-clean): Type.count; RaidPlan.locked_reason -> display_name; Town (blurb "Closed. The smith took a better offer." as the one source; walked-out `_next_mission` null; `town_unlock_for_build`); AdventureBoard (Type.count, "A party of N", exactly-n reward cells / "Nothing worth carrying.", the honest skip line, `_standing` mounted-tier guard, `_completion_goal` walked-out sentence); Guildhall TABS = 3, Records reason from `Achievements.unlock_reason`; Achievements "The record wall opens at Known."; Cards (HUB_HINT default, MORALE_SENTENCES fold <= 2 rows/day, charm fallback for the trinket cell, `scene_has_level_layer`); Roster/RaiderDetail Cheer-up gate on price/cap only; RaiderDetail `_written` bullets-only + "Settles at N — Common, no furnishings." with the sum as a kit tooltip; StartingRoster names via NamePool + backstories via BackstoryPool; Completion prints non-marker `lines` only; Market/Facilities "Next:" = effect, look only behind `scene_has_level_layer`; Reputation `town_unlock` items + `town_unlock_for_build`; reputation.json rows split into {building, text}.
- 14:20 Owned test files retargeted/added and green under RUN_TESTS_ONLY: test_copy_lint (4), test_ladder, test_raid_plan (Results cases red only from W6-LOG's in-flight Results.gd parse error — not mine), test_reputation(+schema), test_starting_roster, test_names_and_backstories, test_screens, test_town_layout, test_roster_layout, test_raider_detail, test_menu_lockup, test_board_rows, test_kit3: 158/158 in the last batch.
- Judgement call: starters draw the register's BARE form (`NamePool.root_of(pick())`) — an epithet name ("Kevin of the Ninefold Path") widened a 215px roster card to 250 (test_roster_layout caught it); canon's three are "aggressively ordinary" and the opening twelve read like them. The card-width defect for HIRED epithet names is pre-existing and W9-POLISH's (recorded under Left).
- Judgement call: the skip line keeps canon's two requirements inside LOOP-24's sentence ("This one is hard. Skipping it forfeits the <item — stat> and nothing else. It is not a good trinket.") because test_full_loop.gd (not mine) pins the item, its stat and "not a good trinket" on the board page.
- 14:32 Shots viewed (Read tool): `build/shots/w6copy/Town_new.png` — the Blacksmith plate reads "Closed. The smith took a better offer." (no Canon/build word); the card's facts read "Trash · 1 enemy · about 6 rounds"; the promise "Next at Known: Guildhall facility upgrade I; Quest board."; the cards carry backstory quotes on day one ("Will not stand next to a Bard.") with register names (Bob, Keith, Barry, Alan) at 43-46 morale; the log's day-one line under "Raids and rests write here.". `build/shots/w6copy/Board_new.png` — "Clear Adventure 0 first." on TR, "1 enemy", ONE reward cell with the charm (no empty well beside it), "A party of 4" under Go to prep, the standing "120 more to Known, which opens more of the same, better paid.", the skip line "This one is hard. Skipping it forfeits the Cracked Charm of Power — +1 Power and nothing else. It is not a good trinket."
- Handoff written and dry-run clean (`apply_handoff.py --dry-run`: #1 RaidPrep ALREADY (W6-AUD-BIND applied it in-wave), #2 RaidView ALREADY (true at the wave's start), #3-#8 the Records link + its three pins, #9-#11 the one-raider sentence flip + its two pins — the orchestrator applies each group together at the close).
- Judgement call (LOOP-17's numeric side): starters open AT their own baseline (`Morale.baseline_of`, 45 + the backstory offset, 41-46, all "Slightly Annoyed"), the rule `Recruitment.generate` applies to every hire (docs/05 §4; docs/04 §5 step 8) — leaving them at a flat 45 with a non-45 baseline made "a new guild starts at baseline" false (tests/unit/test_rest.gd) and drift would have moved them there anyway. No canon number changes; BUILD_STATE's "pinned at morale 45" sentence becomes "at their baseline, 45 plus their past" (W6-LEDGER owns BUILD_STATE — noted under Left).

## verify --fast (final, 2026-09-15 ~14:45)

```
== 0/8  lint: no cross-file class_name refs ==   PASS  LINT OK / MOTION LINT OK
== 1/8  script parse ==                           PASS  PARSE_CHECK scanned 189 script(s)
                                                  PASS  COPY LINT OK  ... 20 allow-listed fall-throughs, all present
== 2/8  generated content ==                      PASS  16 generated file(s) agree
== 2b/8 generated art ==                          PASS  ART CHECK 204 agree
== 3/8  unit tests ==                             FAIL  TESTS FAILED 4/2126 failing
        test_paper_doll.gd :: test_the_baseline_formula_is_one_label            (handoff #13)
        test_paper_doll.gd :: test_the_disabled_cheer_up_says_why_beside_itself  (handoff #14)
        test_paper_doll.gd :: test_the_empty_record_is_one_empty_state_...       (handoff #15)
        test_text_scale_layout.gd :: KNOWN row 0 'Trash · 1 enemies' matched nothing (handoff #12)
A11Y SMOKE PASSED 26 screen mount(s)   (run by hand; --fast skips stage 5)
```

With handoff #12-#15 applied (proved on a backed-up copy, then the bytes restored): test_paper_doll and test_text_scale_layout green.

## Audit closures

- **M3-LOOP-03** (partial -> the copy half is done; the GameState `blacksmith_tier` half stays — not this unit's): the Town's shut Blacksmith reads the building's own `blurb` ("Closed. The smith took a better offer.", ship plan §6 #10's default), never a word about the build; `Town._town_unlock_line()` prints `Reputation.town_unlock_for_build(rank, flags)` so no rank promises a flagged-off building. Held by `test_screens.gd::test_the_smithys_sentence_is_in_world_and_names_no_build`, `::test_the_town_never_promises_a_building_the_build_ships_off`, `test_town_layout.gd::test_the_locked_blacksmith_...` and `tools/lint_copy.sh` (verify stage 1). The entry's clause (2) — `blacksmith_tier` in GameState — is untouched (GameState.gd is W6-LEDGER's; the building is out of 1.0 by §6 #10).
- **M3-LOOP-04** (partial; the "display names" half this unit's Findings name): every player-facing sentence about a rung names it by `display_name` — `RaidPlan.locked_reason()` ("Clear Adventure 0 first."), the Board's commit sub-line ("A party of 4"); the slot code lives only on the rung Button the loop test presses by. Held by `test_ladder.gd::test_a_locked_rung_names_the_one_in_front_of_it`, `test_raid_plan.gd::test_the_board_locks_the_ladder_...`, `test_board_rows.gd::test_the_facts_line_pluralises_one_enemy`. The `GameState.building_level("board")` seam the entry names is not this unit's.
- **M3-TUNE-05** (the `town_unlock` half): `data/reputation.json`'s `town_unlock` is `[{building, text}]` per rank (docs/02 §2.3's five ids); `Reputation.town_unlock()` joins the texts to docs/03 §7's prose and `town_unlock_for_build()` filters by id. Held by `test_reputation.gd::test_the_town_unlock_column_is_items_with_building_ids`, `test_reputation_schema.gd::test_the_town_unlock_column_is_a_list_of_building_items_in_the_file` (the §9 fence parity still holds — the key name is unchanged). The entry's other half (a sibling `data/recruitment.json` for doc 04's cost/experience tables) is not this unit's.

## Left

- **The in-wave reds (4 assertions, 2 unowned test files)** — handoff #12-#15; the orchestrator applies them at the close. Nothing else in the gate is red.
- **LOOP-15's relabel ("View All" -> "Records")** — handoff #3-#7 with its three pins; the link's reason keeps the short "Opens at Known." for the layout reason above.
- **UI-51's one-raider sentence** — handoff #9-#11 flips `Cards.SINGLE_ROW_SENTENCE` with the two `test_a11y_legibility.gd` pins.
- **Hired epithet names widen the roster card** — `Cards.card`'s name row is unwrapped; "Kevin of the Ninefold Path" makes a 215px card 250 wide (test_roster_layout measured it when the starters first drew from the register). Starters now take the bare form, so day one is clean; a Tavern hire with a shape-C name shows it today. W9-POLISH's ("the sidebars fit, the Tavern's cards fold on a line").
- **Starters open at their baseline (45 + their past)**, not a flat 45 — BUILD_STATE's "pinned at morale 45" sentence is W6-LEDGER's to reword ("at their baseline, 45 plus their past"; the band is unchanged). No canon number moved; the balance sweep uses its own rosters; the playtest is WARN-only and walks the same closed circuit it did.
- **docs/03 §9's fence line 514** reads `town_unlock: String (§7, prose — see 15 BL-81)`; the value is now a list of {building, text}. W7-DOCS's (docs/03). BL-81's own "revisit when the town screen wants ids" clause is met — one status line on BL-81 for W6-LEDGER: "the town screen wanted ids in W6-COPY (LOOP-06); `town_unlock` is `[{building, text}]`; the prose is the join". No `q-W6-COPY.md`: the ruling names its own trigger and nothing here is the designer's.
- **Not done, by design:** the `screen_exists` fall-throughs (C3-C5) stay on the lint's allow-list until W10-DELETE; `GameState.gd:217`'s flag untouched; `test_screens.gd`'s flag-on fall-through test kept; no docs edited; `item_reward_2.png` (the gem) is now unreferenced by code — left on disk (asset deletion is not this unit's).
