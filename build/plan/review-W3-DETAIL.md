# review-W3-DETAIL — adversarial review of "one raider, one kit, one character"

Reviewer: Claude (adversarial). Date: 2026-09-14. Verifying against the TREE, not the report.
Edits nothing except this file.

## 1. Tree state

Owned: game/screens/RaiderDetail.gd (M), game/ui/PaperDoll.gd (new), tests/unit/test_paper_doll.gd (new), report/handoff-W3-DETAIL.md.
Untracked companions: game/ui/PaperDoll.gd.uid, tests/unit/test_paper_doll.gd.uid (Godot-generated, expected).

Other changed files in the tree (NOT owned; other wave-3 units are mid-edit — attribution below):
- GameState.gd, Widgets.gd, Cards.gd, Badge.gd, test_widgets_kit.gd, boss_sludge_maw.png deleted → W3-KIT2's ownership
- Guildhall.gd, Roster.gd, Facilities.gd, docs/13-ui-ux.md → W3-ROSTER
- LoadSave.gd, Settings.gd → W3-OPTIONS
- RaidView.gd → W3-RAIDVIEW2
- MainMenu.gd, Completion.gd, Boot.gd → W3-MENU
- SceneStage.gd, test_scene_stage.gd, gen_actors.py, actors/**, enemies/** → W3-ENEMIES
- Town.gd → not in the wave-3 table (nobody) — noted, not attributable to DETAIL unless its diff says so (checked below)
- build/plan/*-W0/W1/W2 report/handoff files modified + build/plan/recovered-2215/ → the 22:17 rewrite the implementer mentions; not this unit's.

Town.gd's one-line change (Blacksmith blurb "Canon calls this one a maybe." → "Under construction.") is NOT this unit's — no reference in its diff, report or handoff. Flagged for the orchestrator only: Q13 pins the word "maybe" and Town.gd has no wave-3 owner.

## 2. Diff review (read in full: `git diff -- game/screens/RaiderDetail.gd` 625 lines; PaperDoll.gd 190 lines; test_paper_doll.gd 330 lines)

Indentation: `grep -c "^ " game/screens/RaiderDetail.gd` = 0, PaperDoll.gd = 0 (tabs); `grep -c "^\t" tests/unit/test_paper_doll.gd` = 0 (spaces). OK.

Same-wave isolation (rule 7) — every kit call resolved against `git show HEAD:` (the wave's start), since Widgets/Cards are KIT2's this wave:
- Widgets.gd@HEAD: empty_state(text, glyph, hint):271, reasoned(control, reason, glyph):617, confirm_pair(yes,no,on_yes,on_no):647 (names the buttons "Yes"/"No", sets meta default_focus), button_of:687, slot:808, slot_button:823, sparkline:883, Sparkline.PITCH/HEIGHT:160-161, SLOT:64, SIZE_META:43 (= Type.SMALL). `tooltip_for` absent at HEAD — correctly NOT called; composed locally in `_tip()` (RaiderDetail.gd:132) with the switch in handoff §1. OK.
- Cards.gd@HEAD: gear_icon(slot, has_item, item):678, roster_strip with on_page pager:220/395 — `_fill_strip` is byte-identical to HEAD (the KIT-12 pager was already consumed in wave 2). OK.
- Theme.gd: current:60, scale_of:68, flat:77, pressed:112, dimmed:120; "SlotWeapon":340, "PortraitFrame":342, "LabelSmall":247 (Type.SMALL), "ButtonSlot":409. Type.at:100, Type.STACK:39. Icons.at("lock","16") → PREFIX "lock_"+"16" = lock_16 (game/assets/ui/icons/grid/lock_16.png.import exists; same idiom as LoadSave.gd:388/Settings.gd:398); Icons.at("empty","quill"|"shelf") → EMPTY_KEYS. Enums.slot_key:536, slot_name_of:537, reputation_name_of:561, all_slots:586. Raider.max_hp(db):204, recruited_at_rank:117, consecutive_benched:122. ClassDef.has_off_hand:53. Frame names the sidebar "Sidebar":532. All exist at the wave's start. OK.

Contract strings (RULES §1 test_raider_detail row) traced in the new code:
- "<name> — 54" / class / band: `_sidebar` card unchanged. "misses about": `_competence_line` unchanged. "Nobody selected"/"Back to the roster": `_nobody` (texts unchanged; glyphs added).
- "empty": `_legend_row` prints "empty" in CAUTION LabelSmall (was LabelBody). Slot names: legend prints "<Slot> —" per available slot AND every slot Button.text = slot name.
- "<n> AC": `_totals` prints "%+d AC" → "+7 AC" contains "7 AC"; "+0 AC" contains "0 AC". Holds for any sign.
- "50 base"/"baseline": one LabelSmall "%d base %+d %s %+d Guildhall %+d furnishings = %d baseline" — single-spaced, one Label (HALL-26). LabelSmall = Type.SMALL = Widgets.SIZE_META, so the plan's size is met by variation rather than override. "Slots:" at :682 unchanged.
- "Nothing is written down about them yet" (empty_state text) + "Wants nothing in particular" (its Hint Label) + "Ran 0 raids" (sidebar `_history`). "They are fine"/"Costs 20 G" through reasoned's "Reason" Label. "Yes — let them go%s"/"Keep them" verbatim into confirm_pair. Button containing "(+": `_legend_row`'s Equip button unchanged. "Personal Effect": still only printed if worn (legend) — unchanged behaviour.
- No `create_tween`, no `reduced_motion`, no `class_name`, no `$GODOT` in any of the three files (grep: 0 hits each). `_ready()` → `build()` idempotent guard is pre-existing (HEAD identical).
- Overlays: PaperDoll's blank wells and the legend's spacer are MOUSE_FILTER_IGNORE. No new PNGs, no new .import needed. Nothing parented to the router host (the screen adds to `_left/_right/_side` under Frame).
- Font colours: the slot caption is hidden with Color(0,0,0,0) overrides — alpha 0, not a pure-black ink; the rule's target is visible ink. Not charged. The Button.text is still the slot name (a11y walker reads it) and the legend repeats it in a LabelSmall — the "never tooltip-only" contract holds.

Handoff: `python tools/apply_handoff.py build/plan/handoff-W3-DETAIL.md --dry-run` → "APPLIED #1 game/ui/PaperDoll.gd". One edit, tab-indented, old block matches PaperDoll.gd:149-151 verbatim. Note it edits a file THIS unit owns (a deferred self-edit, because the door is KIT2's this wave) — correct under rule 7; the orchestrator applies it after `grep -n "static func tooltip_for" game/ui/Widgets.gd` finds the door. `tip.split("\n", true, 1)` yields at most two parts — right. Observations section is labelled as no-edit. OK.

## 3. The implementer's shots, viewed (Read tool)

- `W3-DETAIL-fixture.png` (22:47): Kit panel = Bork's bust at 2x in a rimmed well (≈250..432 x 145..335), the 62x74 weapon slot beside it (dim sword glyph), a 3x2 grid of 47px slots (shield/helm/chest over leggings/boots/ring; worn ones bright, empty ones dim); under it the five cells "120 HP | +7 AC | +0 Power | +0 Mana | no weapon" — no bare "0 <stat>"; then seven legend rows ("Main Hand — empty" in gold, "Head — Worn Iron Cap · worth 1 G" …) and "4 of 7 slots filled · the whole kit would fetch 4 G at the Market". Right panel: "50 base -5 Common +0 Guildhall +0 furnishings = 45 baseline" on ONE line (y≈150), Settled, Slots: empty, Straw Cot / Hot Bath Token, "Backstory" with a quill glyph over "Nothing is written down about them yet." and the two-line hint centred. Sidebar: card, padlocked dimmed "Cheer up" with "They are fine." in CAUTION under it, "Dismiss", "On record" with three facts, then air from y≈545 to the Back button at y≈650 (≈105px), "Back to the roster". Matches the report's description.
- `W3-DETAIL-text150.png`: the five cells reflow to two rows ("no weapon" alone on the second, full width); the legend scrolls with a visible bronze bar at the panel's right (Trinket row cut at the scroll's edge — it is a scroll, the bar says so); the sidebar's record scrolls likewise and "Back to the roster" stays on the panel; the formula wraps after "+0" (acceptance is at 100%).
- `W3-DETAIL-dismiss_sidebar.png`: the DANGER-rimmed plate with "Yes — let them go (-2 morale to everyone else)" wrapped to two lines in red and "Keep them" wearing the focus ring; record and Back unmoved below.
- `W3-DETAIL-empty.png`: "Nobody selected" + "Back to the roster" in the sidebar; Kit / On record panels with bench/quill empty states. (The sidebar's ~470px of air here is the no-raider case; HALL-09's 120px line is about the fixture — noted, not charged.) A faint disc at ≈(880,420) shows through the middle panel: the report attributes it to the camp's lantern glow through PanelWarm; it is on the wave-2 shots too — not this unit's.
- `W3-DETAIL-focus-tab1.png`: the ring on the 62x74 weapon slot (`Slot_main_hand`, per shot2.log "TAB 1 -> Slot_main_hand<Button> at 440,144 62x74"). shot2.log confirms `--tab=4` lands on Nav_home (region-Tab wraps to the rail) — judgement call 7 is true to the instrument.
- `W3-DETAIL-ref-c2-panel.png`: Concept 2's panel — bust, name, two bars, the tall weapon slot left of a 3x2 icon grid. The doll follows its shape (weapon tall, grid 3x2, icon-only slots).

## 4. What I ran (through the lock)

`GODOT_LOCK_WAIT=3000 tools/with_godot_lock.sh ./tools/verify.sh --fast` → `build/shots/review-W3-DETAIL-verify.log` (23:02-23:16):
- 0/5 class cache PASS · lint PASS · MOTION LINT OK · 1/8 PARSE_CHECK 173 scripts PASS · generated content PASS · ART CHECK 197 agree 0 DIFFERS 0 MISSING PASS
- 3/8 unit tests FAIL: 7/1908 failing (the implementer saw 8; test_scene_stage has since gone green). Every failure names another wave-3 unit's file: test_menu_lockup (MENU), test_options_layout (OPTIONS), test_roster_layout ×2 (ROSTER), test_text_scale "Guildhall.gd must not call Theme_.get_theme() itself" (ROSTER's Guildhall.gd), test_widgets_kit ×2 (KIT2). `grep -i "paper_doll|PaperDoll|RaiderDetail|raider_detail"` over the log: 0 hits; 0 SCRIPT ERROR lines. Not charged to this unit — verify_fast_observed = fail, cause elsewhere.
- Stages 4-7 SKIP (--fast). VERIFY FAILED, exit 1.

Two-file run (a runner in the OS temp dir mirroring tests/run_tests.gd over test_paper_doll.gd + test_raider_detail.gd, through the lock; `build/shots/review-W3-DETAIL-batch.log`): "FILE test_paper_doll.gd ran 13 test(s)", "FILE test_raider_detail.gd ran 29 test(s)", "REVIEW RUN 0/42 failing". (One push_error from ScreenRouter "no host registered" during test_raider_detail's roster-row test is pre-existing noise, not a failure.)

## 5. My shots (§0.3 grammar, through the lock, viewed with Read)

- `build/shots/review-W3-DETAIL-fixture.png` (`RaiderDetail --fixture`, 23:28): identical in content to the implementer's 22:47 shot (described in §3). Measured with PIL: the weapon slot spans x 440..502 (62px) × y 144..218 (74px); the grid cells sit at x 510..557 / 562..609 / 614..661 (47px, 5px gaps); the well spans x 248..432 (184px) with the bust's first pixel row at y 145 — 2x of the 90x94 bust. Sidebar empty run (rows with no pixel > 60 from the panel median across x 1180..1480): ONE run, y 540..647 = 108px, between "passes." and "Back to the roster". Stat cells read "120 HP | +7 AC | +0 Power | +0 Mana | no weapon". Formula "50 base -5 Common +0 Guildhall +0 furnishings = 45 baseline" on one line at y≈150.
- `build/shots/review-W3-DETAIL-focus-tab1.png` (`--fixture --focus --tab=1`) + crop `_doll2x.png`: log "TAB 1 -> Slot_main_hand<Button> at 440,144 62x74"; the crop shows the 2px steel ring around the weapon slot, the sword glyph lifted, the bust's pixels crisp at 2x, the grid's worn icons bright and its two empties (shield, ring) dim. The plan's `--tab=4` lands on Nav_home under the frame's region-Tab (implementer's shot2.log; call 7) — the slot ring is the thing the line wants seen and it is seen at tab 1.
- refdiff re-run by me: `python tools/art/refdiff.py build/shots/review-W3-DETAIL-fixture.png 3 --mask 0,77,1536,649` → mae 37.968 / structure 0.185 / layout_iou 0.0995 / within-8 47.65% — byte-for-byte the report's "after"; `W3-DETAIL-before.png` → mae 37.817 / 0.1855 / 0.0992 — the report's "before". Flat (+0.15 mae, within the glow noise LESSONS:116-121 names). Recorded honestly.

## 6. Acceptance lines (00-plan "### W3-DETAIL"), judged

| Line | Met | Evidence |
|---|---|---|
| RaiderDetail shot shows the grid beside a 2x portrait | yes | review-W3-DETAIL-fixture.png: well 184px wide at x 248..432, bust 2x nearest (crisp pixels in `_doll2x.png`), weapon slot 62x74 at 440,144, 3x2 grid of 47px cells at x 510/562/614 — PIL-measured (§5) |
| no bare "0 <stat>" | yes | shot cells "120 HP / +7 AC / +0 Power / +0 Mana / no weapon"; test_no_stat_cell_reads_as_a_bare_zero green (RaiderDetail.gd `_totals`:379-391 prints max_hp + signed bonuses + "no weapon") |
| the formula and its result on one line at 100% | yes | shot y≈150: "50 base -5 Common +0 Guildhall +0 furnishings = 45 baseline" one line; RaiderDetail.gd:479-487 one LabelSmall, single-spaced; test_the_baseline_formula_is_one_label green. Caveat recorded by the unit (call 9): "Uncommon" measures 374/375px and a "their past" term wraps — the fixture case meets the line; the general case is a wrap, never a clip. Minor. |
| the sidebar with ≤ 120px of empty run | yes | PIL scan of my shot: one empty run y 540..647 = 108px (§5) |
| test_raider_detail.gd green unchanged | yes | `git diff --stat tests/unit/test_raider_detail.gd` empty; 29 tests ran, 0 failing in my two-file run and inside verify's 1908 |
| test_paper_doll.gd asserts seven slot Buttons (or six + blank) with their slot names | yes | tests/unit/test_paper_doll.gd:163-181 (one Button per available slot, `.text` = slot name, `Slot_<key>`, FOCUS_ALL), :203-218 (six + `Blank_off_hand`, no Off Hand in the legend), :220-227 (seven); 13 ran, 0 failing |
| refdiff RaiderDetail vs 3 masked recorded | yes | report §Acceptance + build/diff/W3-DETAIL-fixture_diff.json; re-run by me, numbers reproduce exactly (above) |
| Shot list: `--fixture`, `--fixture --focus --tab=4`, `--fixture --set=text_scale=150`, empty | yes | all four on disk and viewed by me (§3, §5); `--tab=4` lands on Nav_home under the frame's region-Tab so the slot ring is shown at `--tab=1` (call 7, verified by the shot log) |
| Green: every slot a FOCUS_ALL Button | yes | Widgets.slot_button → Button.new() (FOCUS_ALL default); asserted at test_paper_doll.gd:177 and :309; a11y_smoke fixture sweep: focusable 31 = reachable 31 (W3-DETAIL-a11y.log) |
| Green: reasons adjacent | yes | `Widgets.reasoned` puts "Reason" LabelSmall under Cheer up (RaiderDetail.gd:380-383); shot shows "They are fine." directly under the padlocked button; test_the_disabled_cheer_up_says_why_beside_itself green |
| Green: tabs indentation | yes | 0 space-led lines in RaiderDetail.gd and PaperDoll.gd; 0 tab-led lines in test_paper_doll.gd |

Findings closed as the plan lists them: HALL-07 (doll + legend + Equip on the legend row), HALL-08 (signed bonuses, base+gear HP, "no weapon"), HALL-09 detail half ("On record" + sparkline under the card; Quarters keeps the right panel), HALL-23 (one `empty_state` with both asserted sentences in Labels — text + Hint), HALL-26 (one Label, double spaces dropped, LabelSmall = Type.SMALL = Widgets.SIZE_META), CRITIC-G05 (confirm_pair, texts kept), CRITIC-G06 (reasoned + lock_16), KIT-12 (pager already consumed at HEAD — nothing to do; `_fill_strip` unchanged), RULES-12 (no private classes: `grep -n "^class " RaiderDetail.gd` = 0), KIT-22 (two-line tooltip_text now; `tooltip_for` switch in handoff §1 — correct under rule 7).

## 7. §0.5 / rules checklist

- Label/Button texts and node names tests read: unchanged (§2). New names (`PaperDoll`, `Grid`, `Portrait`, `Slot_*`, `Blank_*`, `Legend_*`, `Totals`, `Body`) are additions.
- Indentation per file: OK. No `create_tween`, no `reduced_motion` branch, no `class_name`, no `$GODOT` outside the lock (the unit added no shell scripts). No new PNG, so no baked text and no .import to check. Nothing parented to the router host. Blank wells / spacers MOUSE_FILTER_IGNORE. Font sizes through `Type.at(..., Theme_.scale_of(self))` (Equip button, Yes button, caption fallback).
- Same-wave isolation: no call to anything KIT2/ENEMIES/ROSTER are adding this wave (every symbol resolved at HEAD, §2). `tooltip_for` deferred to the handoff. Theme variation names used ("SlotWeapon", "PortraitFrame", "ButtonSlot", "LabelSmall", "LabelLevel") all registered at HEAD.
- Handoff parses (`--dry-run` APPLIED #1); exact old→new, tabs.
- Canon: docs/_source untouched; no canon number changes; no canon-guard test edited.
- §6 (designer-reserved): nothing this unit decided is on the Q01-Q18 list. Q03's HALL_FRAMING (dimmed camp under the panels) is untouched — `_scene` still stages the camp the same way (diff touches only the right column's size flags). The judgement calls (hidden captions behind icons, the record split between sidebar and right panel, text+hint split of the empty state, the two extra record facts, the scrolled columns, the weapon chrome as StyleBox overrides on ButtonSlot rather than a new `_button()` variation) are all inside the plan's text or the kit's existing idioms and are recorded in the report.
- The report's claims checked against the tree: 13 tests (true), 29 unchanged (true), 105px empty run (I measure 108 — same shot content, different threshold; both ≤ 120), refdiff numbers (reproduce exactly), 0 space-indented lines (true), "8/1908 failing none in mine" (now 7/1908, none in this unit's files — true), a11y 26 mounts PASSED (log on disk).

## 8. Issues

Minor (none blocks):
1. HALL-26's one-line claim holds for the fixture (358/375px) but is 1px from wrapping for an "Uncommon" raider and wraps for any raider with a "their past" term — the unit measured and recorded this (call 9); the fallback is a wrap, not a clip. Nothing to do inside the unit's remit without a layout change (a LabelSmall of terms over "= N baseline" was considered and rejected for splitting the result from the formula).
2. Slot captions ride in `Button.text` with a transparent font colour (the Market picker-tile idiom, Market.gd:741-743/:981). Readable by the walker and the keyboard, repeated in the legend Label and the tooltip title — the contract holds; a sighted mouse user without hover sees icon-only slots, as Concept 2 draws them. Recorded as call 1.
3. `Widgets.empty_state`'s hint geometry assumes a one-line text (KIT2's file) — the unit worked around it by splitting text/hint and wrote the observation into the handoff. Fine.
4. The empty-guild sidebar ("Nobody selected") shows ~470px of air above Back — the no-raider case has nothing to say; HALL-09's 120px line is about the fixture and is met there. Observation only.
5. The `Yes` confirm button gets `OVERRUN_TRIM_ELLIPSIS` at 2.6 lines of height; at 100% the whole consequence fits on two lines (dismiss shot). At 150% no Dismiss shot was taken; if the clause needed a third line it would be elided visually (Button.text stays whole for tests). Worth one `--set=text_scale=150 --press=Dismiss` shot in the orchestrator's sweep.

Not this unit's, for the orchestrator: Town.gd's Blacksmith blurb change ("maybe" → "Under construction.") sits in a file with no wave-3 owner and Q13 pins "maybe"; the build/plan/ rewrite at 22:17 the report describes (many W0-W2 report/handoff files show as modified and a `build/plan/recovered-2215/` directory exists).

Note on my third re-take: `--fixture --set=text_scale=150` queued behind other agents' suites for the full GODOT_LOCK_WAIT (3000s, 23:31→00:21) and gave up without running — no `review-W3-DETAIL-text150.png` exists. The 150% line is judged from the implementer's `W3-DETAIL-text150.png` (22:47), which I viewed (§3): the cells reflow, the two scrolled columns show their bar, Back stays on the panel. Two acceptance shots were re-taken by me (fixture, focus).

## 9. Verdict

PASS. No blocker; every acceptance line met on the tree with evidence; verify --fast is red only in files this unit does not own (7/1908, all other wave-3 units' in-progress tests); the unit's 42 tests (13 new + 29 pinned) green alone and in the suite; no false claims found in the report — every number I re-derived (test counts, refdiff before/after, empty run ≤ 120, geometry 184/62x74/47, indentation) reproduces. Minors listed in §8; the handoff §1 (tooltip_for switch) is for the orchestrator after KIT2 lands.
