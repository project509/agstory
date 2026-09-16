# Proposed `docs/15-open-questions.md` entries — agent `state-truth`

Four rulings and one **correction to an existing row**. The correction is the important
one: docs/15 currently asserts something that was not true of the build.

---

## CORRECTION to Q-59, row 1 (docs/15-open-questions.md:1417)

The row reads:

| # | Condition | Status |
|---|---|---|
| 1 | Benched for 5 consecutive runs | **Live** — `Raider.consecutive_benched` already counts it exactly |

Nothing counted it. `grep -rn consecutive_benched --include=*.gd .` returned five hits and
none was a write: the declaration, `to_dict`, `from_dict`, a comment, and the one read in
`GameState._refresh_big_dumb()`. The field was initialised to 0, saved as 0 and loaded as
0 for the life of every campaign, so `big_dumb_active` could never become true and the
Legendary morale floor (docs/04 §11.3, 40 morale) was **unconditional** — canon's "you can
only lose a Legendary if you are BIG dumb" (A11) had no path to being true.

It is live now: `GameState._apply_run_counters()` writes the streak on every resolved
attempt. Proposed replacement text:

| 1 | Benched for 5 consecutive runs | **Live** — `GameState._apply_run_counters()` writes `Raider.consecutive_benched` on every resolved attempt (+1 for a roster member left off the party, 0 for one who went, docs/04 §12.2), and `_refresh_big_dumb()` reads it. Was claimed live from M2 and was not: nothing incremented the counter until the M3 state-truth pass |

**BACKLOG.md:106 and BUILD_STATE.md:246 repeat the same false claim** and need the same
correction. Neither file is owned by this agent — see `build/plan/handoff-state-truth.md`.

---

## Q-NEW-A — the bench morale trigger fires from the SECOND consecutive bench

**Two docs, one number.** docs/05 §7.2's row is specific: "Benched while healthy and the
raid ran — −2 — Only from the 2nd consecutive benched tick; max −6 per 7 ticks". docs/04
§12.2's counter line is silent about a grace run: "+1 on run resolve; reset to 0 on any
run attended".

**Ruling: the specific doc wins.** `GameState._apply_bench_morale()` fires `benched` only
for a raider whose `consecutive_benched >= 2`, named as `BENCHED_MORALE_FROM_STREAK` so
the grace run cannot be mistaken for an off-by-one. The counter is incremented before the
morale pass, so a raider on their first bench reads 1 and is spared.

`benched_wishlist` (−4, "replaces the −2") is deliberately **not** fired: wishlists are
docs/05 §12 Q6's optional module, every `Raider.wishlist` is empty, so the replacement
condition can never be true and firing the −4 would be a guess.

**Balance note for the next tuning pass.** This is a live morale change, not a no-op. Q-34
measured a wipe spiral at −10.8 per wipe against +1.125 drift per Day Tick; −2 per run on
the bench pushes the same direction, capped at −6 per 7 ticks. It was specced and
unfired, so "the bench is where the game is" (docs/04 §12.1) had no cost attached to it
at all until now.

---

## Q-NEW-B — BIG-dumb is refreshed BEFORE the attempt's own morale deltas

The auditor's ordering finding: `_refresh_big_dumb()` runs from `_resolve_day_tick()`,
which is the last thing `_apply_raid_morale()` does — so with only that call, the fifth
consecutive bench would set `big_dumb_active` *after* the fifth bench's own −2 had already
been applied under a floor that was still in force. Condition #1 would bite on the sixth
run, not the fifth.

**Ruling: refresh the flag immediately after the counters are written, before the deltas.**
docs/04 §11.3 says "benched for 5 consecutive runs", so the fifth bench is the run it
bites on. The call in `_resolve_day_tick()` is kept, because `rest_in_town()` is a Day
Tick with no attempt and must also refresh the flag. `_refresh_big_dumb()` is idempotent,
so being called twice per attempt costs nothing.

---

## Q-NEW-C — the town-transition autosave coalesces a RUN of transitions onto one entry

docs/14 §7.4 row 1 asks for a rotating autosave on "any town screen transition"; docs/14
§7.2 fixes the rotation at three deep and calls it "the real backstop against a bad
migration". Those two are in tension: town navigation is the most frequent event in the
game, so a fresh rotation entry per transition means three trips to the Tavern and back
overwrite every autosave in the slot, starting with §7.4's own "moment most worth not
losing".

Two shapes were on the table. Rejected: **skip the write when `save_counter` has not
moved.** It has a real hole — buying at the Market does not autosave, so leaving the
Market would not re-save and the purchase could be lost. A debounce that can drop state is
worse than no debounce.

Also rejected: **reserve one rotation index for transitions.** Structurally safe, but it
cuts the event rotation from three deep to two, which weakens the exact property §7.2
bought the rotation for.

**Ruling: coalesce.** The first transition after any other write takes a fresh rotation
index; every transition after it overwrites *that same entry* until some other trigger
writes. `GameState.autosave()` clears the held index, so the encounter/loot/hire moments
always start a new one. The result: the newest state is always on disk, no run of
transitions however long can spend more than one rotation entry, and the rotation stays
three *different* moments. Implemented as `GameState._autosave_transition()`.

**Excluded from row 1 by name, not by exclusion:** MainMenu (docs/14 §7.4's last row gives
it the manual slot instead), Boot, and RaidView — a write on entering RaidView spends a
rotation entry on a state the player has not finished, and docs/07 §9's attempt-start
autosave is the write that moment is supposed to get.

---

## Q-NEW-D — quitting to the menu saves and does NOT reset the campaign

docs/14 §7.4's last row is "Quit to menu / window close — manual-equivalent". Only window
close was wired (`NOTIFICATION_WM_CLOSE_REQUEST` → `save_now()` → `quit()`). Both
quit-to-menu paths were bare `goto(MAIN_MENU)`.

**Ruling 1: the write is answered by GameState's `screen_changed` handler, not by the two
screens.** Every route to the title screen is a quit to the menu, including ones that do
not exist yet, and a rule spread over two screens is how §7.4's last row came to be
half-wired in the first place. `save_now()` writes the MANUAL slot, which is what §7.4
means by "manual-equivalent": quitting to the menu is the player's implicit manual save.

**Ruling 2: leaving to the menu does NOT `reset()` the campaign.** The guild stays live in
memory behind the title screen. That is the current behaviour and it is kept deliberately,
because with the write in place the in-memory copy and the manual slot now agree — so
"New Guild" discards a campaign that is already safely on disk, and "Continue" reloads
over an identical one. Resetting would additionally require MainMenu to rebuild state on
Continue, which is a screen this pass does not own. **Flagged as undocumented before this
entry, not as wrong.**
