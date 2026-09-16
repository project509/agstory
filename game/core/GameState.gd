extends Node
## Autoload: the guild that persists between raids.
##
## This is the game-side counterpart to `sim/` — it holds everything the player
## accumulates (guild, gold, day, reputation, roster) and hands the sim a
## snapshot when a raid departs. It never simulates anything itself.
##
## docs/14 §3.1: the sim is `simulate(roster, gear, encounter, seed)`. Keeping
## campaign state here rather than in `sim/` is what lets the balance sweep run
## thousands of raids without a guild existing at all.
##
## SHAPE IS SAVE SHAPE. `to_dict()` / `from_dict()` round-trip everything, and
## `SAVE_VERSION` is bumped by ANY change to that shape (docs/14 §7). The save
## *service* — files, slots, migrations — is M3 and lives elsewhere; this class
## only knows how to describe itself.

const Enums = preload("res://sim/model/Enums.gd")
const Raider = preload("res://sim/model/Raider.gd")
const Rng = preload("res://sim/core/Rng.gd")
const StartingRoster = preload("res://game/core/StartingRoster.gd")
const Loot = preload("res://sim/core/Loot.gd")
const Economy = preload("res://sim/core/Economy.gd")
const Morale = preload("res://sim/core/Morale.gd")
const MoraleLedger = preload("res://sim/core/MoraleLedger.gd")
const Achievements = preload("res://sim/core/Achievements.gd")
const Reputation = preload("res://sim/core/Reputation.gd")
const Comfort = preload("res://sim/core/Comfort.gd")
const Consumables = preload("res://sim/core/Consumables.gd")
const BackstoryPool = preload("res://sim/content/BackstoryPool.gd")
const NamePool = preload("res://sim/content/NamePool.gd")
const LegendaryPool = preload("res://sim/content/LegendaryPool.gd")
const Recruitment = preload("res://sim/core/Recruitment.gd")
const Buildings = preload("res://sim/core/Buildings.gd")
const RaidSim = preload("res://sim/core/RaidSim.gd")
const SaveGame = preload("res://game/core/SaveGame.gd")
const Services = preload("res://game/core/Services.gd")

## Bumped by any change to the dictionary shape in `to_dict()` (docs/14 §7).
##
## v17 IS THE LAST BUMP BEFORE 1.0 — THE FORMAT IS FROZEN HERE (docs/14 §7.5,
## ship plan W7-SAVE, audit M6-SAVE-01). Every block docs/14 §7.1 lists now has
## a key, and every persisted need of waves 8-10 rides one of them: a later wave
## adds a key INSIDE `flags` (declared in `ONCE_FLAG_DEFAULTS`, coerced by its
## default's type) and never a top-level key. v17 added the four blocks §7.1
## still lacked — `active_run` (the attempt as it departed: encounter, seed,
## party ids, the party's snapshot, the loadout, the run options — so Continue
## after a mid-replay quit replays the fight that happened, Q-53), `log_tail`
## (the report's facts and the last `LOG_TAIL_CAP` play-by-play lines, so the
## post-mortem survives a reload), `best_rounds` (encounter id -> fewest rounds
## to clear) and `pending_deltas` (the departures queued for the next tick's
## peer hit, so a quit between ticks cannot eat a consequence) — plus the
## once-flags inside `flags`. `SaveGame._v16_to_v17` is a stamp: every field
## defaults to "nothing pending", which is the only truthful reading of a save
## from a build that never wrote them.
## v12 added the two BIG-dumb counters docs/04 §11.3 conditions 2 and 4 need
## (`wipe_streaks`, and `bullet_triggers` with the `bullet_tier` they belong to) plus
## `legendary_warned`, which is what makes §11.4's "the *first* time" mean once per save
## rather than once per session. All three are campaign history: a counter the player can
## reset by quitting to the menu would make canon's "BIG dumb" bar unreachable on purpose.
## v11 persisted the Tavern board itself (`tavern_board`, `board_rolled`). Until it did,
## every reload re-rolled the board, which is a free refresh past docs/04 §3.2's
## `50g x 2^n` ladder — a paid mechanic bypassed by quitting to the menu and back.
## v10 added the town building levels and the Tavern board.
## v9 added the consumable stores (`consumables`, `chosen_consumables`).
## v8 added the Market buy-back shelf (`sold_recently`).
## v7 added the comfort holdings (`furnishings`, `guild_furnishings`).
## v6 added the reputation bookkeeping (`tier_bonus_awarded`, `stalled`).
## v5 added the morale ledger and `crisis_strikes`.
## v2 added `guild_seed`; v3 added `cleared` and `attempts`; v4 turned `cleared`
## from a bool flag into a CLEAR COUNT, because docs/11 §F5's repeat-clear decay
## needs to know how many times, not merely whether. Old saves coerce cleanly:
## `true` reads as 1 through `int()`.
## v16 connected the achievement board: `achievements_earned`,
## `achievements_claimed` and `town_flags`. `SaveGame._v15_to_v16` is a stamp for
## the same reason every stamp here is one — `from_dict` defaults all three empty,
## and empty is the truthful reading of a save from a build where nothing was ever
## earned. Nothing is back-awarded: a v15 guild that already cleared Raid 1 does
## not retroactively hold `prog_raid_1`, because the snapshot-based records will
## notice on its next save point anyway and the EVENT-only ones genuinely cannot
## be recovered — "cleared it with nobody dead" is not a fact a save can
## rediscover. Awarding what we can and silently not awarding the rest would be
## the worst of both.
##
## v15 added the three lifetime counters (`gold_earned_lifetime`,
## `rp_earned_lifetime`, `items_sold_lifetime`). `SaveGame._v14_to_v15` is a stamp:
## `from_dict` defaults all three to zero, which is the only honest reading of a
## save written before anything counted — the history was never recorded and
## cannot be reconstructed, so a guild that carries one starts its lifetime totals
## from now. The alternative, seeding them from the CURRENT balances, would be an
## invented number: `gold` is what is left after spending, not what was earned.
##
## v14 added the completion beat (`completed`, `completed_on_day`,
## `completion_seen`). `SaveGame._v13_to_v14` is a stamp and nothing more:
## `from_dict` defaults all three, and their defaults are exactly what a save
## written before the ending existed means — a guild that has not finished Raid
## 5. The step exists anyway, because every version has one; a chain with holes
## in it cannot tell a decision from an omission.
##
## v13 added `skipped_tutorials`. `SaveGame.OLDEST_MIGRATABLE` stays 10 and
## `migrate()` needs NO step for it: the chain returns the body unchanged when no
## step exists for a version, and `from_dict` defaults the missing array to empty
## — which is exactly what a save written before the skip existed means. The
## omission is deliberate, not a forgotten migration.
const SAVE_VERSION := 17

## docs/14 §7.1's `log_tail` row: "Last N=200 log events of the most recent
## encounter ... capped so the file cannot grow forever."
const LOG_TAIL_CAP := 200

## docs/01 §8.0 Q-13: the opening balance. One Common hire (15 G) plus a farm
## run's potions (~15 G) with change, against docs/11's ~100 G-per-Raid-1 anchor.
const STARTING_GOLD := 60

## Canon: "You start at: Unknown" (raw notes, *Guild Reputation*).
const STARTING_RANK := Enums.ReputationRank.UNKNOWN

## docs/04 §12.1 — the single source of the roster cap, driven by reputation
## rank and nothing else. Indexed by Enums.ReputationRank.
const ROSTER_CAP_BY_RANK := [15, 16, 17, 18, 19, 20]

signal gold_changed(amount: int)
signal day_advanced(day: int)
signal roster_changed()
signal attempt_recorded(encounter_id: String, cleared: bool)
signal loot_changed()
signal raiders_departed(names: Array)
signal guild_crisis(strikes: int, p_disband_next: float)
signal guild_disbanded()
signal reputation_changed(points: int, rank: int)
signal rank_advanced(rank: int)
signal comfort_changed()
signal consumables_changed()
signal board_changed()
signal autosaved()
## One or more records went from Locked to Earned. Carries the ids, so a screen
## can say which rather than re-diffing the whole wall.
signal achievements_changed(newly_earned: Array)
signal raider_hired(name: String)
signal facility_upgraded(tier: int)
## docs/04 §11.4's "hard, unmissable confirmation the *first* time a Legendary crosses
## below 40". Emitted once per raider ever; the screen that shows it calls
## `acknowledge_legendary_warning()`, and until something does, the warning stays pending —
## a modal nobody was listening for must not count as having been shown.
signal legendary_at_risk(raider_id: String)

# ---------------------------------------------------------------- campaign state
var guild_name: String = ""
var gold: int = 0
var day: int = 1

## docs/11 §11.2's reward cap is "~15% of lifetime income", and the achievement
## board's reputation faucet is capped the same way (the register question
## `sim/core/Achievements.gd` cites) — both are a SHARE of something, and until
## these three existed there was no denominator to take a share of. `gold` and
## `reputation_points` cannot serve: the first is what is left after spending and
## the second is reduced by docs/03 §6.5's disband penalty, so both go DOWN and a
## cap computed from a falling number would shrink as the player played.
##
## These only ever rise. That is the whole contract:
##   gold_earned_lifetime   every positive `add_gold()`, never a `spend_gold()`
##   rp_earned_lifetime     every award, BEFORE the disband penalty can touch it
##   items_sold_lifetime    every `sell_loot()` — docs/11 §11.1's "Sell 100 items"
##                          needs it, and `sold_recently` cannot supply it because
##                          that is docs/02 §6.1's six-slot buy-back shelf and it
##                          forgets the seventh sale
##
## Persisted, because a cap that resets on load is not a cap. See audit M5-QAB-5.
var gold_earned_lifetime: int = 0
var rp_earned_lifetime: int = 0
var items_sold_lifetime: int = 0

## docs/02 §4.4's record wall, as the two things the save has to remember about it.
##
##   achievements_earned    id -> the day it was earned. A DICTIONARY and not a
##                          set, because the day is the only part a snapshot
##                          cannot recompute, and docs/02 §4.4 wants a wall you
##                          can read rather than a checklist you tick.
##   achievements_claimed   ids whose reward has been taken. Separate from earned
##                          on purpose: docs/11 §11.2's coin cap is a share of
##                          lifetime income, so a record can be earned long before
##                          the guild has earned enough for the board to pay it.
##
## EARNED IS PERSISTED RATHER THAN RECOMPUTED, and that is the whole reason this
## field exists: `Achievements.EVENT_ONLY_KINDS` are decidable only while an
## attempt is being recorded. "Cleared it with nobody dead" is not something a
## save can rediscover a week later, so the moment it happens is the only moment
## it can be written down. See audit M5-QAB-6.
var achievements_earned: Dictionary = {}
var achievements_claimed: Array = []

## The two `town_flag` rewards on the wall (a statue; a banner over the door).
## Distinct from `flags`, which is docs/14 §5.2's BUILD-flag registry and refuses
## an id it does not declare — these are things the town gained, not features the
## build turned on, and conflating them would let a reward switch off the
## Blacksmith. Stored as ids the town can read; nothing renders them yet, and the
## record is honest about that rather than the grant being silently dropped.
var town_flags: Array = []
var reputation_rank: int = STARTING_RANK
var reputation_points: int = 0

## Seeds every deterministic campaign roll — the opening roster today, recruit
## generation and loot later. Saved, so a guild can always be regenerated.
var guild_seed: int = 0

## Array of `sim/model/Raider.gd`. The bench and the raid group both live here;
## who is chalked for tonight is raid-prep's business, not the roster's.
var roster: Array = []

## Canon's "Maybe" systems each get a flag (docs/14 §5.2). The game must boot
## and be completable with every flag off.
##
## flag id -> bool, and ONLY ids in `FLAG_DEFAULTS`. Read it through
## `flag_enabled()` rather than indexing: a `flags["wishlist"]` typo reads false, which
## is indistinguishable from a feature deliberately off, and that is how a finished
## system ships switched off forever.
var flags: Dictionary = {}

## docs/14 §5.2's closed list, in the doc's own words: "Canon's 'Maybe' systems
## (Blacksmith, crafting, salvage, level-ups, wishlists) each get a flag in
## `data/tuning/flags.json`. The game must boot and be completable with every flag off."
##
## THIS TABLE IS THE DECLARATION; the JSON file is the eventual override. `data/tuning/`
## does not exist yet, so there is nothing to load and the defaults here are the whole
## truth — see build/plan/handoff-quirks.md for the loader that should read it at boot and
## the one line of `Boot.gd` that calls it. Declaring in code and defaulting in data is
## deliberate: an id is a contract between a screen and a system, and a contract that can
## be created by adding a key to a data file cannot be checked.
##
## Every "Maybe" default is FALSE. docs/14 §5.2's completability rule means off is the
## state the game is tested in, and five of these six systems have no implementation at
## all.
##
## `legendary_quirks` is the exception to §5.2's "Maybe" framing and is here for a
## different reason: the system is canon (docs/04 §11.2 promises every Legendary a quirk)
## but its SPEC does not exist — docs/15 BL-58 is OPEN and `sim/core/Quirks.gd`'s registry
## is empty. The flag is what keeps an unspecced seam provably inert. See
## build/plan/q-quirks.md.
##
## `achievement_rp` is docs/15 Q-69's switch, RULED 2026-09-15 (RULINGS.md §2 row 13):
## the record wall pays reputation — the two reputation-kind records pay 15 RP each,
## capped live at 15 % of RP earned. TRUE is the shipped value; `false` is the
## recorded alternative (the records pay their type's coin figure instead).
const FLAG_DEFAULTS := {
    "blacksmith": false,        # docs/14 §5.2, docs/02 §11's "Maybe" building
    "crafting": false,          # docs/14 §5.2
    "salvage": false,           # docs/14 §5.2
    "level_ups": false,         # docs/14 §5.2; canon "Train raiders < Maybe if we have level ups"
    "wishlists": false,         # docs/14 §5.2, §5.3's `wishlist` row: "❓ OPEN module, behind a flag"
    "legendary_quirks": false,  # docs/15 BL-58 — the spec, not the code, is missing
    "achievement_rp": true,     # docs/15 Q-69 (RULED): the board pays 15 RP per reputation record
}

## THE ONCE-FLAGS (ship plan W7-SAVE): the small "has the player seen / when did it
## happen" marks later waves persist WITHOUT a save bump, because `flags` is a
## Dictionary and the freeze test asserts the top-level key set, not its contents.
## They live inside `flags` beside the build flags above, and this table is their
## declaration: `from_dict` accepts a key from EITHER table and drops anything else
## with a problem line (docs/14 §7.3: a migration may drop, never guess), and each
## value is coerced to its default's TYPE on the way in — JSON has one number type.
## Read through `once_flag()`, written through `set_once_flag()`; `flag_enabled()`
## still refuses these ids, because "was the rank-up callout shown" is not a feature.
##
##   last_rank_seen     the rank the Town's rank-up callout last acknowledged; a
##                      fresh guild starts at Unknown so nothing is owed (W8-CRISIS)
##   disbanded_day      the day the guild disbanded, 0 = never (W8-CRISIS, BL-143)
##   crisis_modal_seen  the crisis modal was shown this crisis (W8-CRISIS)
##   walk_in_id         the free walk-in recruit's id, "" = none (W8-CRISIS, BL-143)
const ONCE_FLAG_DEFAULTS := {
    "last_rank_seen": 0,
    "disbanded_day": 0,
    "crisis_modal_seen": false,
    "walk_in_id": "",
}

## docs/14 §7.1's `active_run`, as the tree's sim allows it: the sim is a pure
## function replayed by RaidView, so "resume" means "replay from the stored seed"
## (SHIP-03, Q-53 RULED). Written by `record_attempt()` — the attempt is committed
## at Depart, before RaidView plays a line, so this is never a save-scum surface —
## and cleared when the report is dismissed (`_on_screen_changed`). Continue with
## `resolved` true re-runs the fight through `replay_active_run()` and lands on
## Results instead of Town.
##
##   encounter_id     the rung
##   master_seed      the seed the fight was run with (`result.seed_used`)
##   party_ids        who went, in slot order
##   resolved         true while a report is owed; false = nothing pending
##   difficulty_mult  BL-113's multiplier the fight was run under (1.0)
##   ninja_pulled     BL-116's puller, "" = nobody
##   party            the party AS IT DEPARTED (`Raider.to_dict()` each) — the
##                    morale the fight was rolled against, which `record_attempt`
##                    moves before the autosave; without it the replay is not the
##                    fight that happened (see report-W7-SAVE, judgement call 1)
##   loadout          the folded consumables the fight was run with, for the same
##                    reason — `spend_loadout()` has emptied the cupboard by then
var active_run: Dictionary = {}

## docs/14 §7.1's `log_tail`: the report's header facts plus the last
## `LOG_TAIL_CAP` play-by-play lines of the most recent attempt, per save. What
## survives a reload of the post-mortem's TEXT even where the sim could not be
## replayed (a content change); Results reads the live `last_result` first.
##
##   encounter_id, seed, cleared, rounds, payout, loot_ids, lines
var log_tail: Dictionary = {}

## docs/14 §7.1's progress row, `best_rounds`: encounter id -> the fewest rounds a
## clear of it has taken. Written by `record_attempt()` on a clear; the Records
## tab may read it.
var best_rounds: Dictionary = {}

## AUDIO-10 (ship plan W7-SAVE): true while a whole campaign is ARRIVING —
## `new_game()` and `from_dict()` both emit `gold_changed` so the gold labels
## redraw, and docs/13 §12.4's trigger for the coin is "Gold changes", which a
## restore is not. Audio reads this and stays silent; a transaction never sets it.
## Not saved: it describes this frame, not the guild.
var announcing: bool = false

## The run options the last `run_attempt()` forwarded, for the replay test to
## read back — `RaidSim.run` has no options parameter until W8-SIM-BALANCE lands
## BL-113/BL-116's sim halves, so this is where the seam records what it was
## handed. Not saved.
var last_run_opts: Dictionary = {}

## encounter_id -> how many times this guild has cleared it. The Adventure's
## Board reads this to unlock the next rung, which is what makes the board a
## progression bar rather than a menu (docs/02 §2.2), and docs/11 §F5's payout
## decay reads the count.
var cleared: Dictionary = {}

## Items from the last clear that nobody has been given yet. docs/09 §14.3: the
## loot window opens once at the end of the raid, one list, all drops — so drops
## wait here for the player rather than being auto-equipped behind their back.
var pending_loot: Array = []

## Gold the last clear paid, kept for the Results screen to report.
var last_payout: int = 0

## docs/05 §7.6's cap bookkeeping. Saved, because a cap the player can reset by
## quitting to the menu is not a cap.
var morale_ledger = null

## docs/05 §6.3's guild-level counter: consecutive Day Ticks on which the crisis
## conditions have held. Resets to 0 the moment either fails.
var crisis_strikes: int = 0

## docs/05 §6.3 disables disband "until the player has completed Adventure 0 and
## the Tutorial Raid". Both now exist (data/encounters_tutorial_t1.json), and
## `_maybe_complete_onboarding()` is the only thing that writes this outside
## `reset()` and `from_dict()`. It arms `Morale.may_disband`, and nothing else
## in the codebase reads the flag.
var onboarding_complete: bool = false

## Tutorial encounter ids the player chose to skip. Canon makes the tutorials
## skippable ("Tutorials can be skip, but will offer a special loot piece …
## players will be warned that they will miss out on reward"), and a skip has to
## be remembered or the ladder behind it stays locked forever — `rung_resolved()`
## is what the board asks instead of `has_cleared()`. Saved, because a skip the
## player can undo by quitting to the menu is not a skip.
var skipped_tutorials: Array = []

## docs/10 §13 row 1, ruled in docs/15 Q-88: the game has an ENDING, and it is
## the first clear of the last encounter of the last tier. Not a victory screen
## that takes the save away — "the save continues" — so this is three fields
## rather than a mode:
##
##   completed         the guild has finished the campaign, ever
##   completed_on_day  which day it happened, for the report
##   completion_seen   whether the beat has been SHOWN, so a reload does not
##                     replay somebody's ending at them
##
## `completed` is the one the rest of the game reads (Achievements' snapshot
## already looks for it); `completion_seen` exists only so the screen can fire
## once. Both survive a save, because an ending you have to earn twice is not an
## ending.
var completed := false
var completed_on_day := 0
var completion_seen := false

## docs/03 §6.1's full-tier bonus is "all 5 in one lockout", and lockouts do not
## exist yet (docs/15 BL-35). Until they do, the bonus pays once per tier, the first
## time all five of that tier's encounters are cleared — recorded here so it cannot
## pay twice.
var tier_bonus_awarded: Array = []

## docs/03 §8.1's M3 catch-up flag: set once the player has "attempted the same raid
## encounter 5+ times without clearing it", cleared on their next raid first clear.
## While set, adventure content pays double RP (§6.2's `catchup`).
var stalled: bool = false

## docs/02 §4.2's placed Furnishings: raider id -> Array of furnishing ids. The
## raider's own `comfort_floor` is derived from this and never the source of truth,
## so a save cannot disagree with itself about what has been bought.
var furnishings: Dictionary = {}

## docs/02 §4.2's guild-wide variants, bought once and felt by everyone.
var guild_furnishings: Array = []

## Which save slot this campaign belongs to, and how far round the autosave rotation
## it is. docs/14 §7.2: "3 guild slots x (1 manual + 3 rotating autosaves)."
var save_slot: int = 0
var autosave_index: int = 0

## A monotonic count of writes for this campaign, so two saves made in the same second
## can still be ordered. Saved, because a tick count would reset on reload.
var save_counter: int = 0

## docs/14 §7.1's `played_seconds`, so a load menu can say "40 minutes in" rather than
## just naming the guild. Counted off the router's screen changes by
## `_accrue_played_time()`, because that is the only clock this game has that ticks while
## the player is thinking.
var played_seconds: float = 0.0

## docs/02 §11's bought building levels. The Guildhall's is `facility_tier` (0-based,
## because docs/05 §7.5 indexes its bonus that way); these two are 1-based levels,
## because docs/02 §5.2 and §6.2 both count their rungs from L1.
var tavern_tier: int = 1
var market_tier: int = 1

## docs/04 §3.1's candidate board, and §3.2's reroll counter: "price doubles each paid
## refresh within the same mission cycle, resets on mission completion".
var tavern_board: Array = []
var rerolls_since_run: int = 0

## Whether this campaign has ever rolled a board. Saved, and separate from "the board is
## empty", because docs/04 §3.4 makes those two different states: a candidate dismissed
## off the board leaves a slot that "stays empty until the next refresh", so an empty
## board the player emptied must NOT be refilled by opening the door again.
var board_rolled: bool = false

## docs/03 §8.1 M2's save-persistent pity counter, and the Legendary classes already
## found — ✅ C12: "You can only ever find 1 Legendary per class", for the whole save.
var recruit_pity: int = 0
var legendary_classes_found: Array = []

## docs/11 §7's cupboard: `Consumables.stock_key()` -> how many are held. Bought at
## the Market, spent when an attempt begins.
var consumables: Dictionary = {}

## What the player has chalked onto the NEXT attempt, same keys. docs/11 §7's commit
## point: "Pre-raid consumables are chosen at the raid-confirm screen and are only
## *spent* as the attempt begins. Doc 01 §6.2 says cancelling at confirm is free; that
## must stay true." So this is a selection, not a withdrawal.
var chosen_consumables: Dictionary = {}

## Steady Hands is bought for a named raider, so the selection has to remember who:
## stock key -> raider id.
var chosen_targets: Dictionary = {}

## docs/05 §7.1's wipe delta as actually applied, per raider, for the attempt just
## resolved — the number docs/11 §7's Rally Flask gives half of back.
var last_wipe_penalty: Dictionary = {}
## The attempt's NET morale movement per party member (brought + cleared, or
## brought + wipe + knocked out), raider id -> float, for the report's by-raider
## tally (docs/13 §11.4 "morale ledger preview"; Results.gd reads it first).
## Separate from `last_wipe_penalty` because the flask's refund is a share of
## the wipe hit alone; the flask adds what it gives back here too.
var last_attempt_morale: Dictionary = {}

## docs/02 §6.1's buy-back shelf: "Buy-back of the last N sold items ... N = 6.
## Cheap insurance against a mis-sale; costs 1.25x sale price." Newest first, so the
## thing the player just regretted is at the top.
var sold_recently: Array = []

## docs/11 §8.3's anti-stockpiling cap: Indulgence purchases per Day Tick may not
## exceed roster size. Reset by `advance_day()`, because a Day Tick is what the cap
## is written against.
var indulgences_today: int = 0

## Who actually went on the last attempt. Loot rolls and the Suggested split are
## computed against THESE raiders rather than the whole roster (docs/15 BL-32 and
## BL-33): a player farming an on-ramp with a fixed six is trying to gear those
## six, and rolling against twelve keeps the "still needed" set so wide that it
## never concentrates on what the party in the field is missing.
var last_party: Array = []

## encounter_id -> attempts made. Kept separate from `cleared` so a guild that
## has thrown itself at Boss 5 nine times reads differently from one that has
## never seen it.
var attempts: Dictionary = {}

## docs/04 §11.3 condition 2: "Wiped on the same boss 3 times in a row with them in the
## raid." `attempts` cannot answer that — it is a lifetime total per encounter with no
## per-raider dimension and no notion of consecutiveness, which is a different question
## wearing the same word.
##
## encounter_id -> {raider_id: consecutive wipes}. Keyed by encounter FIRST because "the
## same boss" is literal: three wipes spread over two bosses is not this condition.
## Pruned as it goes (`_apply_wipe_streaks`, `_forget_raider_counters`) so a long campaign
## does not carry dead ids into every save.
var wipe_streaks: Dictionary = {}

## docs/04 §11.3 condition 4: "Any of their own backstory bullets triggered 3+ times in
## one tier." The morale ledger caps per tick / session / ever / window (docs/05 §7.6) and
## has no tier scope, and it stores accumulated MAGNITUDES — "how many times did this
## bullet fire" is not recoverable from it. So it is counted here.
##
## raider_id -> {tag: count}, and `bullet_tier` names the tier those counts belong to.
## `highest_unlocked_tier()` is the only tier this build has (docs/03 §6.2), so a change
## in it is what clears the counts.
var bullet_triggers: Dictionary = {}
var bullet_tier: int = 1

## docs/04 §11.4: the confirmation is "the *first* time a Legendary crosses below 40", so
## "the first time" has to be a fact about the save and not about the session. Ids of the
## Legendaries whose warning the player has already seen and acknowledged.
var legendary_warned: Array = []

## Which board rung the player is preparing for. Set by the board, read by prep.
var selected_encounter_id: String = ""

## Which raider S05 is showing. Transient, like the selected encounter — a screen
## selection is not campaign state and is deliberately not saved.
var selected_raider_id: String = ""

## The most recent SimResult. Transient by design — a raid log is large, it is
## regenerable from its seed, and docs/14 §7 keeps saves small.
var last_result = null

## True once a game exists — distinguishes "Continue" from a cold menu.
var active: bool = false

## The loaded content tables. Set once by Boot; read by every screen that needs
## to name an item or a class. Never mutated after load.
var content = null

## The reason the last transition-driven write failed, or "". Not saved — it describes
## this session's disk, not the campaign. A save that fails silently is worse than one
## that fails loudly, and the transition writes have no return value a caller can read.
var last_save_problem: String = ""

## Wall clock at the last screen change, for `played_seconds`. Not saved: a tick count
## restarts with the process, which is exactly why the accumulated total is the saved half.
var _last_transition_msec: int = 0

## The rotation entry the current RUN of town transitions is writing to, or -1 when the
## next one must take a fresh index. Not saved: which way the player is pacing around
## town this session is not a fact about the guild. See `_autosave_transition()`.
var _transition_slot: int = -1

## The hub's event feed (TOWN-23, W3-KIT2): what the guild DID, in the game's own
## words — hires, dismissals, sales, purchases, upgrades, raid results, rests,
## departures — for the "Recent Events" panel every dashboard screen carries
## (`Cards.recent_events` reads it first, then the morale notes). Each row is
## `{day, seq, kind, text}`; `kind` is one of the icon grid's log kinds
## (Icons.LOG_KINDS: recruit, gold, loot, mistake, raider_attack, morale_down,
## phase, system …) so the row's badge is a picture and the text is the second
## channel (docs/13 §13). A RING BUFFER OF THE LAST `EVENT_FEED_CAP`, NOT SAVED:
## the log is a courtesy on the desk, not campaign state, and keeping it out of
## `to_dict()` keeps SAVE_VERSION where it is (LESSONS: a save-shape change is
## four files, every time). `reset()` clears it with everything else.
var event_feed: Array = []
var _event_seq: int = 0
## While > 0, `log_event` is muted for the rows a batch verb would otherwise write
## one at a time (a sell-all, a rest-until-recovered); the batch writes ONE row.
var _feed_batch: int = 0
const EVENT_FEED_CAP := 20


## docs/14 §7.4's last row: "Quit to menu / window close — NOTIFICATION_WM_CLOSE_REQUEST
## on the root, with `auto_accept_quit = false` ... so the handler runs the synchronous
## write and THEN calls quit()."
##
## The doc is specific about why the setting matters: "with only [quit_on_go_back]
## disabled, Godot accepts the quit itself and the save is skipped."
func _notification(what: int) -> void:
    if what != NOTIFICATION_WM_CLOSE_REQUEST:
        return
    save_now()
    var loop := Engine.get_main_loop()
    if loop is SceneTree:
        (loop as SceneTree).quit()


func _ready() -> void:
    # Without this Godot accepts the close itself and the save above never runs.
    var loop := Engine.get_main_loop()
    if loop is SceneTree:
        (loop as SceneTree).auto_accept_quit = false
    # An autoload must not carry state between tests or between a quit and a
    # restart within one process. Starting empty makes `active` meaningful.
    reset()
    _ensure_router_connected()


# --------------------------------------------- docs/14 §7.4: screen transitions

## docs/14 §7.4 row 1: "Any town screen transition — rotating". Named explicitly rather
## than derived by exclusion, because the screens that must NOT write are the ones an
## exclusion list silently picks up the day a new screen lands: RaidView (a write mid
## attempt spends a rotation entry on a state the player has not finished) and Boot.
const TOWN_SCREENS := [
    "res://game/screens/Town.tscn",
    "res://game/screens/Guildhall.tscn",
    "res://game/screens/Tavern.tscn",
    "res://game/screens/Market.tscn",
    "res://game/screens/AdventureBoard.tscn",
    "res://game/screens/RaidPrep.tscn",
    "res://game/screens/RaiderDetail.tscn",
    "res://game/screens/Results.tscn",
    "res://game/screens/Settings.tscn",
]

## docs/14 §7.4's last row pairs "quit to menu" with window close, both manual-equivalent.
const MAIN_MENU_SCREEN := "res://game/screens/MainMenu.tscn"

## The report and the account, for `active_run`'s dismissal rule below.
const RESULTS_SCREEN := "res://game/screens/Results.tscn"
const RAID_VIEW_SCREEN := "res://game/screens/RaidView.tscn"
## Leaving the report for one of these does NOT dismiss it: the player may come
## back to it, and a Continue that lands on the report again is the right answer.
const REPORT_DETOURS := [
    "res://game/screens/Settings.tscn",
    "res://game/screens/LoadSave.tscn",
]

## Where the router was before the transition being handled. Not saved.
var _screen_before: String = ""

## An overnight idle on one screen is not play. docs/14 §7.1 wants `played_seconds` to
## tell three save slots apart, and a slot that reads "9 hours in" because the player went
## to lunch tells the player something false.
const PLAYED_SECONDS_PER_TRANSITION_CAP := 600.0


## The router is an autoload too and autoload order is not guaranteed — under `--script`
## it may be built after this one. So this is idempotent and called again from every entry
## point that makes a campaign live. Reached by name, never by the global identifier
## (BUILD_STATE invariant 7); `Services` is what handles the SceneTree-script case.
func _ensure_router_connected() -> void:
    var router := Services.router(self)
    if router == null:
        return
    if not router.is_connected("screen_changed", Callable(self, "_on_screen_changed")):
        router.connect("screen_changed", Callable(self, "_on_screen_changed"))


## docs/14 §7.4's first and last rows, both of which are screen transitions.
##
## Subscribed here rather than emitted by each screen: every route to the title screen is
## a quit to the menu, including the ones that do not exist yet, and a rule that lives in
## one handler cannot be half-wired the way §7.4's last row was — only window close saved,
## so Town's own Back button dropped everything since the last autosave.
func _on_screen_changed(path: String) -> void:
    _accrue_played_time()
    var came_from := _screen_before
    _screen_before = path
    if not active:
        return
    # The report is DISMISSED when the player leaves it for the town (or for the
    # prep board — "Try again" writes a fresh `active_run` at the next Depart). A
    # detour to Options and back, or a quit to the menu from the report, leaves it
    # owed, so Continue lands on the report again — the player never read past it.
    if came_from == RESULTS_SCREEN and path != RESULTS_SCREEN \
            and path != RAID_VIEW_SCREEN and path != MAIN_MENU_SCREEN \
            and not REPORT_DETOURS.has(path):
        dismiss_active_run()
    if path == MAIN_MENU_SCREEN:
        # "manual-equivalent" is the doc's own word: the same synchronous write the close
        # handler makes. The campaign is deliberately LEFT LIVE in memory rather than
        # reset — see build/plan/q-state-truth.md for why that is a ruling, not an
        # oversight.
        last_save_problem = save_now()
        return
    if TOWN_SCREENS.has(path):
        _autosave_transition()


## docs/14 §7.1's `played_seconds`, counted where the field's own contract says it is:
## by the router, on every screen change. There is no other clock — this game has no
## `_process` and a Day Tick is not wall time.
func _accrue_played_time() -> void:
    var now: int = Time.get_ticks_msec()
    var elapsed := float(now - _last_transition_msec) / 1000.0
    _last_transition_msec = now
    if not active:
        return
    played_seconds += clampf(elapsed, 0.0, PLAYED_SECONDS_PER_TRANSITION_CAP)


## docs/14 §7.4 row 1's write, and the debounce that makes it safe.
##
## Town navigation is frequent and the rotation is only three deep, so writing a fresh
## entry per transition lets three trips to the Tavern and back evict every autosave the
## guild has — including §7.4's own "moment most worth not losing". A RUN of transitions
## therefore coalesces onto ONE entry: the first takes a fresh index, every transition
## after it overwrites that same one until some other trigger writes. The state on disk
## is always current, and the rotation stays three deep and three DIFFERENT moments,
## which is the only property that makes it docs/14 §7.2's backstop.
func _autosave_transition() -> String:
    if not active:
        return ""
    # SHIP-15: a snapshot record earned on the Market or in the Guildhall lights on
    # the NEXT screen, not on the next raid — and it is in the file this writes.
    check_achievements()
    if _transition_slot < 0:
        _transition_slot = autosave_index
        autosave_index = (autosave_index + 1) % SaveGame.AUTOSAVES_PER_SLOT
    var problem := SaveGame.autosave(save_slot, _transition_slot, self)
    last_save_problem = problem
    if problem.is_empty():
        autosaved.emit()
    return problem


# ---------------------------------------------------------------- lifecycle

func reset() -> void:
    guild_name = ""
    gold = 0
    gold_earned_lifetime = 0
    rp_earned_lifetime = 0
    items_sold_lifetime = 0
    achievements_earned = {}
    achievements_claimed = []
    town_flags = []
    day = 1
    reputation_rank = STARTING_RANK
    reputation_points = 0
    guild_seed = 0
    roster = []
    flags = {}
    cleared = {}
    attempts = {}
    wipe_streaks = {}
    bullet_triggers = {}
    bullet_tier = 1
    legendary_warned = []
    big_dumb_reasons = {}
    pending_legendary_warning = ""
    pending_loot = []
    last_payout = 0
    last_party = []
    morale_ledger = MoraleLedger.new()
    crisis_strikes = 0
    onboarding_complete = false
    skipped_tutorials = []
    completed = false
    completed_on_day = 0
    completion_seen = false
    tier_bonus_awarded = []
    stalled = false
    _tick_notes = {}
    furnishings = {}
    guild_furnishings = []
    indulgences_today = 0
    sold_recently = []
    save_slot = 0
    autosave_index = 0
    save_counter = 0
    played_seconds = 0.0
    tavern_tier = 1
    market_tier = 1
    tavern_board = []
    board_rolled = false
    rerolls_since_run = 0
    recruit_pity = 0
    legendary_classes_found = []
    consumables = {}
    chosen_consumables = {}
    chosen_targets = {}
    last_wipe_penalty = {}
    last_attempt_morale = {}
    facility_tier = 0
    _trophy_witnesses = {}
    _pending_departures = []
    active_run = {}
    log_tail = {}
    best_rounds = {}
    announcing = false
    last_run_opts = {}
    selected_encounter_id = ""
    selected_raider_id = ""
    last_result = null
    active = false
    last_save_problem = ""
    _transition_slot = -1
    _screen_before = ""
    event_feed = []
    _event_seq = 0
    _feed_batch = 0
    # Re-stamped rather than zeroed: the interval that ends at the NEXT screen change
    # started here, and zeroing would bill the whole process uptime to the new campaign.
    _last_transition_msec = Time.get_ticks_msec()


## Begin a campaign. Canon start: Unknown rank, day 1, docs/01's opening purse,
## and the benchmark twelve in starting armour (see StartingRoster for why a new
## guild cannot start empty). Pass a seed to reproduce an exact guild.
func new_game(name: String, seed_value: int = 0) -> void:
    reset()
    # AUDIO-10: a campaign arriving is not a transaction. Cleared at the end,
    # after the two announcement emits.
    announcing = true
    guild_name = name.strip_edges()
    if guild_name.is_empty():
        guild_name = "A Guild Story"
    gold = STARTING_GOLD
    # Deriving from the name keeps a new game reproducible from what the player
    # typed, which makes a reported bug reproducible from a screenshot.
    guild_seed = seed_value if seed_value != 0 else Rng.hash64(guild_name)
    active = true
    # `_ready()` may have run before the router autoload existed. A campaign only becomes
    # live through here or `from_dict()`, so connecting at both makes the subscription
    # exist before any transition it has to answer.
    _ensure_router_connected()

    # The roster needs content. Boot loads and validates it before any menu
    # exists, so this is populated in the real game; a caller that skips that
    # step gets an empty roster rather than a crash.
    if content != null:
        for r in StartingRoster.build(content, guild_seed):
            roster.append(r)

    gold_changed.emit(gold)
    roster_changed.emit()
    announcing = false


func set_content(db) -> void:
    content = db


# ---------------------------------------------------------------- docs/14 §5.2: flags

## Whether a declared feature flag is on. An UNDECLARED id is a bug in the caller, not a
## feature that happens to be off, so it says so out loud — the same contract
## `GameSettings.get_value()` keeps with docs/13 §15.1's closed list of options.
##
## `sim/` never calls this. docs/14 §3.1 makes the sim a pure function of its arguments,
## so a flag reaches it as an argument (`Quirks.is_live(id, enabled)`), never as a lookup.
func flag_enabled(flag_id: String) -> bool:
    if not FLAG_DEFAULTS.has(flag_id):
        push_error("GameState: '%s' is not a declared flag (docs/14 §5.2)" % flag_id)
        return false
    return bool(flags.get(flag_id, FLAG_DEFAULTS[flag_id]))


## Turn a declared flag on or off for THIS campaign. Returns false for an undeclared id.
##
## Stored only when it differs from the default, so a save carries the player's and the
## build's deviations and nothing else — a flag whose default changes between builds then
## follows the new default instead of being pinned by an old save that never chose.
func set_flag(flag_id: String, on: bool) -> bool:
    if not FLAG_DEFAULTS.has(flag_id):
        push_error("GameState: '%s' is not a declared flag (docs/14 §5.2)" % flag_id)
        return false
    if on == bool(FLAG_DEFAULTS[flag_id]):
        flags.erase(flag_id)
    else:
        flags[flag_id] = on
    return true


## Every declared flag id, sorted. What a debug overlay lists and what a test walks.
func declared_flags() -> Array:
    var ids: Array = FLAG_DEFAULTS.keys()
    ids.sort()
    return ids


## A once-flag's value, or its declared default. An undeclared id is a bug in the
## caller and says so, the same contract `flag_enabled()` keeps.
func once_flag(key: String):
    if not ONCE_FLAG_DEFAULTS.has(key):
        push_error("GameState: '%s' is not a declared once-flag (ONCE_FLAG_DEFAULTS)" % key)
        return null
    return _coerce_like(flags.get(key, ONCE_FLAG_DEFAULTS[key]), ONCE_FLAG_DEFAULTS[key])


## Write a once-flag. Stored only when it differs from the default, like `set_flag()`,
## so a save carries what happened and nothing else. Returns false for an undeclared id.
func set_once_flag(key: String, value) -> bool:
    if not ONCE_FLAG_DEFAULTS.has(key):
        push_error("GameState: '%s' is not a declared once-flag (ONCE_FLAG_DEFAULTS)" % key)
        return false
    var v = _coerce_like(value, ONCE_FLAG_DEFAULTS[key])
    if v == ONCE_FLAG_DEFAULTS[key]:
        flags.erase(key)
    else:
        flags[key] = v
    return true


## `value` as the type of `like`. JSON has one number type, so a saved 3 comes back
## 3.0; coercing at the boundary keeps every reader's comparison honest.
func _coerce_like(value, like):
    match typeof(like):
        TYPE_BOOL:
            return bool(value)
        TYPE_INT:
            return int(value)
        TYPE_FLOAT:
            return float(value)
        TYPE_STRING:
            return String(value)
    return value


# ---------------------------------------------------------------- queries

## docs/04 §12.1. A Respected guild reads "17 of 17" everywhere, never "17/20".
func roster_cap() -> int:
    if reputation_rank < 0 or reputation_rank >= ROSTER_CAP_BY_RANK.size():
        return ROSTER_CAP_BY_RANK[0]
    return ROSTER_CAP_BY_RANK[reputation_rank]


func roster_is_full() -> bool:
    return roster.size() >= roster_cap()


func rank_name() -> String:
    return Enums.reputation_name_of(reputation_rank)


## How many must sit out a full raid. docs/04 §12.1's "forced bench" column is
## exactly this, so it is derived rather than duplicated as a second table.
func forced_bench() -> int:
    return maxi(0, roster_cap() - Enums.RAID_SIZE)


func can_field_a_raid() -> bool:
    return roster.size() >= Enums.RAID_SIZE


# ---------------------------------------------------------------- mutation

## Positive amounts only are counted as income. A refund path that hands gold
## back with a negative amount elsewhere would otherwise inflate the denominator
## docs/11 §11.2's cap divides by, which is the one number the board must not be
## able to talk up.
##
## `counts_as_income` false is for exactly that: the achievement board's own coin.
## Its cap is 15% of lifetime income, so paying board coin INTO that figure would
## let the board raise its own ceiling every time it paid out — a faucet that
## widens itself, which is precisely what docs/11 §11.2's "never enough to
## substitute for playing content" forbids. The gold is real; the income is not.
func add_gold(amount: int, counts_as_income: bool = true) -> void:
    if amount > 0 and counts_as_income:
        gold_earned_lifetime += amount
    gold = maxi(0, gold + amount)
    gold_changed.emit(gold)


## Returns false and changes nothing if the guild cannot afford it, so callers
## never have to check first and then spend in two steps.
func spend_gold(amount: int) -> bool:
    if amount < 0 or gold < amount:
        return false
    gold -= amount
    gold_changed.emit(gold)
    return true


func advance_day() -> void:
    indulgences_today = 0
    day += 1
    day_advanced.emit(day)


## One row on the hub's event feed (see `event_feed`). `kind` names the badge
## (an icon-grid log kind); `text` is the row, already a sentence. Stamped with
## the day it HAPPENED (read now, before any tick that follows — LESSONS: an
## event carries the day it happened, not the day it is noticed). The oldest row
## falls off past `EVENT_FEED_CAP`. Muted inside a batch (`_feed_batch`), whose
## verb writes its own single row.
func log_event(kind: String, text: String) -> void:
    if _feed_batch > 0 or text.is_empty():
        return
    _event_seq += 1
    event_feed.append({"day": day, "seq": _event_seq, "kind": kind, "text": text})
    while event_feed.size() > EVENT_FEED_CAP:
        event_feed.pop_front()


## The feed newest first, at most `limit` rows.
func recent_feed(limit: int = EVENT_FEED_CAP) -> Array:
    var out: Array = event_feed.duplicate()
    out.reverse()
    return out.slice(0, maxi(0, limit))


## Returns false when the roster is at its reputation-driven cap (docs/04 §12.1).
func add_raider(r) -> bool:
    if r == null or roster_is_full():
        return false
    roster.append(r)
    # A new recruit walks into whatever standing orders the guild already has
    # (docs/02 §4.2's guild-wide variant), so their comfort floor is not zero.
    r.comfort_floor = comfort_floor_of(r.id)
    roster_changed.emit()
    return true


func remove_raider(raider_id: String) -> bool:
    for i in roster.size():
        if roster[i].id == raider_id:
            roster.remove_at(i)
            _forget_raider_counters(raider_id)
            roster_changed.emit()
            return true
    return false


func raider(raider_id: String):
    for r in roster:
        if r.id == raider_id:
            return r
    return null


# ---------------------------------------------------------------- raids

func has_cleared(encounter_id: String) -> bool:
    return clear_count(encounter_id) > 0


## Has this rung been DEALT WITH — cleared, or skipped? The board's ladder gate
## asks this rather than `has_cleared()`, because canon lets a player skip the
## tutorials and a skip that still locked everything behind it would turn
## "skip" into "soft-lock the campaign". Only a tutorial can ever be skipped, so
## for every other rung this is exactly `has_cleared()`.
func rung_resolved(encounter_id: String) -> bool:
    return has_cleared(encounter_id) or skipped_tutorials.has(encounter_id)


## docs/10 §9.3 / canon: "Tutorials can be skip … players will be warned that
## they will miss out on reward". Per tutorial, not global — skipping Adventure
## 0 does not skip the Tutorial Raid.
##
## Refuses anything that is not a tutorial rather than trusting the caller: the
## board is not the only thing that could ever call this, and a skipped Raid 1
## would hand out the ladder for free. Returns false when it refused, so a
## caller can tell the difference between "done" and "ignored".
func skip_tutorial(encounter_id: String) -> bool:
    if content == null:
        return false
    var enc = content.encounter(encounter_id)
    if enc == null or not Reputation.is_tutorial_slot(String(enc.slot)):
        return false
    if skipped_tutorials.has(encounter_id):
        return true
    skipped_tutorials.append(encounter_id)
    # The forfeited trinket is forfeited by never being granted: the grant in
    # `record_attempt` only fires on a first CLEAR, so there is nothing to undo.
    _maybe_complete_onboarding()
    if selected_encounter_id == encounter_id:
        selected_encounter_id = ""
    # The board re-reads the ladder off this, and Results/Town read the same
    # signal — reusing it keeps the skip on the one refresh path that already
    # works rather than adding a signal only one screen listens to.
    board_changed.emit()
    autosave()
    return true


## docs/05 §6.3 gates disband on having "completed Adventure 0 and the Tutorial
## Raid". Resolved by SLOT, never by a hard-coded id — sim/core/Reputation.gd
## keys the tutorials off the literal strings "A0" and "TR" and the id is the
## content file's business.
##
## A RESOLVED tutorial counts, cleared or skipped. A skip is not a completion in
## the doc's words, but docs/01 §8.3 and docs/15 Q-90 make the skip permanent,
## so if a skip did not count, a player who skipped both would be exempt from
## disband for the rest of the campaign. The gate exists to protect a player who
## has not yet seen the game, not to reward clearing. Recorded as docs/15
## BL-79 (promoted from build/plan/q-tutorials.md, 2026-09-15).
##
## One-way: nothing clears this flag except `reset()`.
func _maybe_complete_onboarding() -> void:
    if onboarding_complete or content == null:
        return
    var found := 0
    for slot in ["A0", "TR"]:
        var enc = content.encounter_at_slot(slot)
        if enc == null:
            continue
        found += 1
        if not rung_resolved(String(enc.id)):
            return
    # A content set with no tutorials at all leaves the flag FALSE. This is the
    # flag that arms a roster wipe, and "the onboarding file failed to load" is
    # not consent to that — the safe direction for a rule whose whole point is
    # that it never surprises the player is the one where it cannot fire.
    if found > 0:
        onboarding_complete = true


## How many times this encounter has been cleared. Tolerates a v3 save (or a
## test) that stored `true` rather than a count.
func clear_count(encounter_id: String) -> int:
    var raw = cleared.get(encounter_id, 0)
    if typeof(raw) == TYPE_BOOL:
        return 1 if raw else 0
    return int(raw)


func attempt_count(encounter_id: String) -> int:
    return int(attempts.get(encounter_id, 0))


## A fresh, reproducible seed per attempt. Derived from the guild seed and the
## attempt number rather than from the clock, so a raid can always be re-run
## exactly — which is the difference between a reportable bug and a ghost story.
func next_raid_seed() -> int:
    var n := 0
    for k in attempts:
        n += int(attempts[k])
    return Rng.splitmix64_mix(guild_seed + n * 7919 + 1)


## Record the outcome of one attempt. The sim never writes to game state, so
## this is the single place a raid changes the campaign (docs/14 §3.1) — and
## therefore the single place loot and gold enter the guild.
## `party` is the raiders who departed. It defaults to the whole roster only so
## that a caller with no party to hand still behaves sensibly; the game always
## passes the chalked group.
##
## `opts` is the attempt as it was RUN, for `active_run` (docs/14 §7.1, Q-53):
##   loadout          the folded consumables `RaidSim.run` received
##   difficulty_mult  BL-113's multiplier (default 1.0)
##   ninja_pulled     BL-116's puller (default "")
## Absent keys take the defaults, so every existing three-argument caller is a
## fight run at 1.0 with nobody pulling — which is what those callers run.
func record_attempt(encounter_id: String, result, party: Array = [],
        opts: Dictionary = {}) -> void:
    # Read before the Day Tick below moves it: this is the day the attempt HAPPENED,
    # and it is what the record wall is stamped with.
    var attempt_day: int = day
    last_party = party.duplicate() if not party.is_empty() else roster.duplicate()
    # The attempt as it departed, written BEFORE a single delta lands: the morale
    # below moves before the autosave, and a replay rolled against the moved
    # numbers would not be the fight that happened (Q-53's commit rule).
    _write_active_run(encounter_id, result, opts)
    # Read before anything is written, because the two BIG-dumb counters below both
    # branch on it and `_apply_raid_morale()` must see the state they leave behind.
    var won: bool = result != null and result.cleared()
    _apply_run_counters(result)
    _apply_wipe_streaks(encounter_id, won)
    # docs/04 §11.3 conditions 1 and 2 are both "N runs in a row", so the Nth run is the
    # one it bites on. `_resolve_day_tick()` refreshes this too, but at the END of the
    # tick — right for a rest, one run late here, because the morale deltas this attempt
    # is about to apply are exactly the ones a suspended floor must let through.
    _refresh_big_dumb()
    var prior_clears := clear_count(encounter_id)
    attempts[encounter_id] = attempt_count(encounter_id) + 1
    last_result = result
    last_payout = 0
    # Everything past this index in `pending_loot` is THIS clear's drops.
    var loot_before: int = pending_loot.size()

    if won:
        cleared[encounter_id] = prior_clears + 1
        # docs/14 §7.1's progress row: the fewest rounds a clear has taken.
        var took: int = int(result.get("rounds")) if result.get("rounds") != null else 0
        if took > 0 and (not best_rounds.has(encounter_id)
                or took < int(best_rounds[encounter_id])):
            best_rounds[encounter_id] = took
        var enc = content.encounter(encounter_id) if content != null else null
        if enc != null:
            # docs/10 §13 row 1 / docs/15 Q-88. The trigger is the FIRST clear of
            # the last encounter of the last tier, resolved through the record
            # rather than by matching an id, so renaming content cannot silently
            # move the ending. `prior_clears == 0` is what makes it a beat and
            # not a thing that happens on every farm run.
            if prior_clears == 0 and not completed and Achievements.is_completion_encounter(enc):
                completed = true
                completed_on_day = day
                completion_seen = false
            # docs/11 §F5: the decay reads how many times it was ALREADY cleared,
            # so a first clear pays full.
            last_payout = Loot.payout(enc, prior_clears)
            if last_payout > 0:
                add_gold(last_payout)
            if Reputation.is_tutorial_slot(String(enc.slot)):
                _grant_tutorial_trinket(enc, prior_clears)
            else:
                var rng = Rng.new(Rng.splitmix64_mix(
                    guild_seed + attempt_count(encounter_id) * 6971 + 3))
                # Biased toward what the PARTY THAT WENT still needs (BL-33).
                for it in Loot.roll_drops(enc, content, last_party, rng):
                    pending_loot.append(it)
            loot_changed.emit()

    # The report's facts and its last lines, once the payout and the drops are
    # known (docs/14 §7.1's `log_tail`).
    _write_log_tail(encounter_id, result, won, _pending_ids().slice(loot_before))

    var enc_for_rp = content.encounter(encounter_id) if content != null else null
    if won:
        _award_reputation(enc_for_rp, prior_clears + 1)
        _witness_kill(enc_for_rp)
    _update_stall_flag(enc_for_rp, encounter_id, won)

    _apply_raid_morale(encounter_id, result, won)
    # The feed row goes on AFTER the Day Tick inside `_apply_raid_morale`, so it
    # carries the same day as the morale notes that tick writes and sorts ABOVE
    # them in the log (feed rows precede notes within a day) — written before it,
    # it was stamped a day earlier and twelve "wipe" notes pushed the headline
    # off the seven visible rows (build/shots/W3KIT2_Town_raid.png, first take).
    # The record wall keeps `attempt_day`; the row names the encounter, not the day.
    log_event("raider_attack" if won else "mistake", _attempt_feed_line(enc_for_rp, encounter_id, result, won))
    # docs/04 §3.2: "Any Adventure or Raid run resolves (win or wipe) — full board
    # reroll; unheld candidates are gone." And the reroll price resets here, which is
    # what makes "go do a raid" the answer to a bad board.
    rerolls_since_run = 0
    refresh_board()
    if won:
        _maybe_complete_onboarding()
    attempt_recorded.emit(encounter_id, won)
    # The ONE moment the event-only records can be decided (docs/02 §4.4's wall,
    # audit M5-QAB-6). "Cleared it with nobody dead" is not a fact a save can
    # rediscover, so it is noticed here or never. After the deltas and before the
    # autosave, so what is earned is in the file the save writes.
    check_achievements(_attempt_event(enc_for_rp, result, won, attempt_day))
    # docs/14 §7.4: "Encounter resolved (clear, wipe, or retreat), AFTER deltas apply —
    # the moment most worth not losing."
    autosave()


## The attempt as one feed row (TOWN-23): the encounter by its display name,
## the purse on a clear, the fallen on a wipe. Read after `last_payout` is set.
func _attempt_feed_line(enc, encounter_id: String, result, won: bool) -> String:
    var what: String = String(enc.display_name) if enc != null and not String(enc.display_name).is_empty() else encounter_id
    if won:
        return "Cleared %s — %d G." % [what, last_payout] if last_payout > 0 else "Cleared %s." % what
    var fell: int = (result.casualties as Array).size() if result != null else 0
    if fell > 0:
        return "Wiped on %s — %d fell." % [what, fell]
    return "Wiped on %s." % what


# ------------------------------------------ docs/14 §7.1: active_run and log_tail

## `active_run`, written at the top of `record_attempt()` from `last_party` — see
## the field's comment for the shape and for why the party is snapshotted.
func _write_active_run(encounter_id: String, result, opts: Dictionary) -> void:
    var ids: Array = []
    var snapshot: Array = []
    for r in last_party:
        if r == null:
            continue
        ids.append(String(r.id))
        snapshot.append(r.to_dict())
    var raw_loadout = opts.get("loadout", {})
    active_run = {
        "encounter_id": encounter_id,
        "master_seed": _result_int(result, "seed_used"),
        "party_ids": ids,
        "resolved": true,
        "difficulty_mult": float(opts.get("difficulty_mult", 1.0)),
        "ninja_pulled": String(opts.get("ninja_pulled", "")),
        "party": snapshot,
        "loadout": _loadout_like(
            raw_loadout if typeof(raw_loadout) == TYPE_DICTIONARY else {}),
    }


## `log_tail`: the report's header facts and the last `LOG_TAIL_CAP` play-by-play
## lines, rendered now — the strings, not the entries, so a content edit cannot
## leave a save holding a template nobody can render.
func _write_log_tail(encounter_id: String, result, won: bool, loot_ids: Array) -> void:
    var lines: Array = []
    var log = result.get("log") if result != null else null
    if log != null and log.has_method("at_tier"):
        for e in log.at_tier(Enums.LogTier.PLAY_BY_PLAY):
            lines.append(String(e.describe()))
    if lines.size() > LOG_TAIL_CAP:
        lines = lines.slice(lines.size() - LOG_TAIL_CAP)
    log_tail = {
        "encounter_id": encounter_id,
        "seed": _result_int(result, "seed_used"),
        "cleared": won,
        "rounds": _result_int(result, "rounds"),
        "payout": last_payout,
        "loot_ids": loot_ids.duplicate(),
        "lines": lines,
    }


## A 64-bit integer off the disk, from either form the body may carry: the
## string this build writes, or the number an older build wrote (lossy above
## 2^53, and nothing can recover what that write dropped).
func _int64(v) -> int:
    if typeof(v) == TYPE_STRING:
        return String(v).to_int()
    return int(v)


## A deep copy of `block` with its seed field written as text — see `to_dict()`.
func _with_seed_as_text(block: Dictionary, key: String) -> Dictionary:
    var out: Dictionary = block.duplicate(true)
    if out.has(key):
        out[key] = str(_int64(out[key]))
    return out


## A SimResult field as an int, 0 when the result (or a test's stand-in) lacks it.
func _result_int(result, key: String) -> int:
    if result == null:
        return 0
    var v = result.get(key)
    return int(v) if v != null else 0


## A loadout in `Consumables.new_loadout()`'s exact shape, from whatever was
## stored: JSON hands back floats for ints and nothing for a missing key, and the
## sim reads the table by key.
func _loadout_like(raw: Dictionary) -> Dictionary:
    var out: Dictionary = Consumables.new_loadout()
    for key in out.keys():
        if not raw.has(key):
            continue
        var v = raw[key]
        if typeof(out[key]) == TYPE_DICTIONARY:
            var table: Dictionary = {}
            if typeof(v) == TYPE_DICTIONARY:
                for k in (v as Dictionary):
                    table[String(k)] = float((v as Dictionary)[k])
            out[key] = table
        else:
            out[key] = _coerce_like(v, out[key])
    return out


## Whether a report is owed: an attempt was recorded and nothing has dismissed it.
func active_run_pending() -> bool:
    return active and bool(active_run.get("resolved", false)) \
        and not String(active_run.get("encounter_id", "")).is_empty()


## The report has been read. Called from `_on_screen_changed` when the player
## leaves Results for the town; public so a screen that knows better can say so.
func dismiss_active_run() -> void:
    active_run = {}


## THE ONE DOOR to the sim from a campaign. RaidPrep's Depart and the replay both
## run the fight through here so the two can never disagree about the arguments.
## `opts` — `difficulty_mult` (BL-113) and `ninja_pulled` (BL-116) — is recorded
## in `last_run_opts`; `RaidSim.run` grows the parameter that carries it in
## W8-SIM-BALANCE, and this is the line that will forward it.
func run_attempt(party: Array, enc, seed_value: int, loadout: Dictionary = {},
        opts: Dictionary = {}):
    last_run_opts = {
        "difficulty_mult": float(opts.get("difficulty_mult", 1.0)),
        "ninja_pulled": String(opts.get("ninja_pulled", "")),
    }
    return RaidSim.run(party, enc, content, seed_value, loadout)


## Continue after a mid-replay quit (Q-53, SHIP-03): re-run the stored attempt —
## the party as it departed, the loadout it carried, the seed it rolled, the
## options it ran under — so the report the player lands on is the fight that
## happened. Returns the SimResult, or null when nothing is owed or the content
## no longer has the rung; `last_result` and `last_party` are set for Results.
func replay_active_run():
    if not active_run_pending() or content == null:
        return null
    var enc = content.encounter(String(active_run.get("encounter_id", "")))
    if enc == null:
        return null
    var departed: Array = _active_run_party()
    if departed.is_empty():
        return null
    var seed_value: int = int(active_run.get("master_seed", 0))
    var raw_loadout = active_run.get("loadout", {})
    var result = run_attempt(departed, enc, seed_value,
        _loadout_like(raw_loadout if typeof(raw_loadout) == TYPE_DICTIONARY else {}),
        active_run)
    last_result = result
    # The loot split is offered to the LIVE roster members who went; the snapshot
    # was only ever the sim's.
    last_party = []
    for rid in active_run.get("party_ids", []):
        var who = raider(String(rid))
        if who != null:
            last_party.append(who)
    if String(log_tail.get("encounter_id", "")) == String(enc.id) \
            and int(log_tail.get("seed", -1)) == seed_value:
        last_payout = int(log_tail.get("payout", 0))
    return result


## The party as it departed, rebuilt from the snapshot; a save with no snapshot
## (hand-written) falls back to the live roster by id.
func _active_run_party() -> Array:
    var out: Array = []
    var raw = active_run.get("party", [])
    if typeof(raw) == TYPE_ARRAY:
        for entry in (raw as Array):
            if typeof(entry) != TYPE_DICTIONARY:
                continue
            var r = Raider.from_dict(entry, [])
            if r != null:
                out.append(r)
    if not out.is_empty():
        return out
    for rid in active_run.get("party_ids", []):
        var who = raider(String(rid))
        if who != null:
            out.append(who)
    return out


## The attempt, in the shape `Achievements.is_satisfied()` reads: tier and slot
## from the encounter record (never its id — docs/10 §2 note 2), and the three
## figures the event-only kinds need.
##
## `party_size` is who WENT, counted as survivors + casualties, not the
## encounter's authored size. docs/11 §11.1's "Clear Raid 1 with 12/12 alive" is a
## claim about the party that was fielded: a guild that sent eleven and brought
## eleven home has not done the thing, and a guild that could only field eleven
## should not be able to earn it by sending fewer.
func _attempt_event(enc, result, won: bool, on_day: int) -> Dictionary:
    if result == null:
        return {}
    var alive: int = (result.survivors as Array).size()
    var fell: int = (result.casualties as Array).size()
    return {
        "tier": int(enc.tier) if enc != null else 0,
        "slot": String(enc.slot) if enc != null else "",
        "won": won,
        "mistakes": int(result.mistake_count),
        "survivors": alive,
        "party_size": alive + fell,
        "day": on_day,
    }


## Canon: each tutorial pays "1 crap trinket", once. docs/09 §10.2 owns the two stat
## blocks and names them; docs/10 §9.3 makes the reward gone for the run once the
## mission is skipped or already taken.
##
## A FIXED GRANT, NOT A ROLL, and the roll is bypassed on purpose. `Loot.drop_pool`
## takes its non-raid branch for A0/TR, maps the "trinket" loot slot to
## `Slot.TRINKET` and returns every tier-1 `source == "adventure"` trinket — which
## is Adventure's Charm of Health (+7 HP) and Charm of Power (+2 Power), the very
## items docs/10 §9.2 says the crap trinkets must be "visibly worse than or the skip
## warning is a lie". Rolling here would pay the tutorials BETTER loot than
## Adventure 1 and make the warning untrue.
##
## The once-only guard lives here rather than in `Loot.roll_drops` because that
## function's contract is purity (sim/core/Loot.gd: "Pure and deterministic. No
## Node, no global RNG") and a grant that depends on how many times the guild has
## cleared something is campaign state, which is this file's business (docs/14 §3.1).
## The ids follow docs/09 §12.1's grammar exactly — `ITM_T{tier}_{SOURCE}_{FAMILY}_
## {SLOT}[_{VARIANT}]` — with the `TUT` source token ruled in docs/15 BL-77,
## because §12.1's tier row already said tier 0 covers "starting gear and tutorial
## rewards" and its SOURCE list had no token for the second half of that sentence.
const TUTORIAL_TRINKET := {
    "A0": "ITM_T0_TUT_UNIV_TRINKET_POWER",
    "TR": "ITM_T0_TUT_UNIV_TRINKET_HEALTH",
}

func _grant_tutorial_trinket(enc, prior_clears: int) -> void:
    if prior_clears > 0:
        return      # docs/10 §9.3: replayable for gold, but the trinket is gone
    var item_id := String(TUTORIAL_TRINKET.get(String(enc.slot), ""))
    if item_id.is_empty() or content == null:
        return
    var it = content.item(item_id)
    if it != null:
        pending_loot.append(it)


## docs/09 §10.2's authored pair, as the warning has to print them. Kept here
## beside the grant so the copy on the board and the item actually handed over
## can never name two different things, and used as the FALLBACK when the item
## rows are not in the content set — docs/10 §9.3 requires the skip warning to
## "name the forfeited item and its stat", and a blank warning is the one
## failure canon forbids here.
const TUTORIAL_TRINKET_LINE := {
    "A0": "Cracked Charm of Power — +1 Power",
    "TR": "Cracked Charm of Health — +2 HP",
}

func tutorial_reward_line(encounter_id: String) -> String:
    if content == null:
        return ""
    var enc = content.encounter(encounter_id)
    if enc == null:
        return ""
    var slot := String(enc.slot)
    var it = content.item(String(TUTORIAL_TRINKET.get(slot, "")))
    if it != null:
        return it.describe()
    return String(TUTORIAL_TRINKET_LINE.get(slot, ""))


## docs/04 §12.2's bench counter and docs/14 OQ-10's division of labour, in one place —
## the per-raider counters RaiderDetail already prints, which were all permanently 0.
##
## OQ-10 is quoted at RaidSim.gd's own `_queue_deltas`: "the sim only reports; `game/`
## applies these to the roster". So `runs_attended` and `wipes_witnessed` are taken from
## the sim's `deltas_queued` rather than recounted from `last_party` — two places counting
## the same thing is two places that can disagree, and the sim is the one that was there.
##
## `consecutive_benched` is not in that report because the sim never sees the bench:
## docs/04 §12.2 defines benching as "any raider not placed in the 12 for a run", which is
## a fact about the roster. `died` IS reported and is deliberately NOT applied — nothing
## in this build removes a dead raider, and writing a status the roster does not honour
## would show the player a corpse on the bench.
func _apply_run_counters(result) -> void:
    var went: Dictionary = {}
    for r in last_party:
        if r != null:
            went[r.id] = true
    for r in roster:
        if went.has(r.id):
            r.consecutive_benched = 0
        else:
            r.consecutive_benched += 1

    var queued = result.get("deltas_queued") if result != null else null
    if typeof(queued) != TYPE_ARRAY:
        return
    for delta in queued:
        if typeof(delta) != TYPE_DICTIONARY:
            continue
        var who = raider(String((delta as Dictionary).get("raider_id", "")))
        if who == null:
            continue
        who.runs_attended += int((delta as Dictionary).get("runs_attended", 0))
        who.wipes_witnessed += int((delta as Dictionary).get("wipes_witnessed", 0))


## docs/04 §11.3 condition 2's counter: "Wiped on the same boss 3 times in a row with them
## in the raid."
##
## AMBIGUITY, BEHIND A SWITCH (house rule; recorded in docs/15 BL-59, row 2,
## 2026-09-15). The doc says "with them in the raid" and says nothing about a
## raider who was benched for one of the three attempts. Two readings:
##   false (DEFAULT) — a bench neither extends nor breaks the streak. "With them in the
##     raid" describes which wipes count, so a night they did not attend is not one of
##     them, and the player who benches a Legendary is already answering to condition 1.
##   true — a bench breaks it, on the reading that "in a row" means the attempts in a row
##     and a skipped one interrupts the sequence.
## The default is the one that cannot be reached by accident: it takes three wipes the
## raider was actually present for, which is what the sentence describes.
const BENCH_BREAKS_WIPE_STREAK := false


func _apply_wipe_streaks(encounter_id: String, won: bool) -> void:
    if won:
        # A clear ends everybody's streak on this boss, which is what "in a row" means,
        # and it takes the encounter's whole entry with it rather than leaving a row of
        # zeroes in every future save.
        wipe_streaks.erase(encounter_id)
        return

    var went: Dictionary = {}
    for r in last_party:
        if r != null:
            went[r.id] = true

    var streak: Dictionary = wipe_streaks.get(encounter_id, {})
    for r in roster:
        if went.has(r.id):
            streak[r.id] = int(streak.get(r.id, 0)) + 1
        elif BENCH_BREAKS_WIPE_STREAK:
            streak.erase(r.id)
    # A raider who has left the guild keeps no streak; `_forget_raider_counters()` handles
    # the departure itself, and this is the backstop for a roster changed any other way.
    var live: Dictionary = {}
    for r in roster:
        live[r.id] = true
    for known in streak.keys():
        if not live.has(known):
            streak.erase(known)

    if streak.is_empty():
        wipe_streaks.erase(encounter_id)
    else:
        wipe_streaks[encounter_id] = streak


## The longest run of consecutive wipes this raider is carrying on any single boss.
## docs/04 §11.3 condition 2 is per-boss, so the worst boss is the one that decides it.
func wipe_streak_of(raider_id: String) -> int:
    var worst := 0
    for enc in wipe_streaks:
        var streak: Dictionary = wipe_streaks[enc]
        worst = maxi(worst, int(streak.get(raider_id, 0)))
    return worst


## Drop every per-raider counter for somebody who is no longer in the guild. Called from
## both removal paths, because a campaign that runs for weeks would otherwise carry a dead
## id in `wipe_streaks` and `bullet_triggers` in every save it writes.
func _forget_raider_counters(raider_id: String) -> void:
    bullet_triggers.erase(raider_id)
    big_dumb_reasons.erase(raider_id)
    if pending_legendary_warning == raider_id:
        pending_legendary_warning = ""
    for enc in wipe_streaks.keys():
        var streak: Dictionary = wipe_streaks[enc]
        streak.erase(raider_id)
        if streak.is_empty():
            wipe_streaks.erase(enc)


## docs/03 §6's reputation award for one clear, plus §6.1's full-tier bonus.
##
## docs/03 §6.5's monotonic-rank rule is applied through `Reputation.rank_after()`
## rather than by assigning `rank_for_rp()` directly, so a rank can never fall out
## of an ordinary award path either.
func _award_reputation(enc, clear_number: int) -> void:
    if enc == null:
        return
    var rp := Reputation.award_for(
        enc, clear_number, highest_unlocked_tier(), stalled)

    var tier := int(enc.tier)
    if Reputation.is_raid_slot(String(enc.slot)) and not tier_bonus_awarded.has(tier):
        if Reputation.tier_complete(cleared_raid_slots(tier)):
            rp += Reputation.full_tier_bonus(tier, true, highest_unlocked_tier())
            tier_bonus_awarded.append(tier)

    if rp <= 0:
        return
    # Counted here, at the award, and never anywhere the balance is REDUCED:
    # docs/03 §6.5's disband penalty takes points away and must not take away the
    # history that the board's cap is a share of.
    _gain_reputation(rp, true)


## Every reputation GAIN lands here — a clear's award and a record-wall claim —
## so the feed line, the signal and the rank-up beat cannot be half-wired
## (LOOP-13: the macro loop's currency was never shown). `counts_as_earned` is
## false for the board's own reputation: its cap is a share of RP earned, and a
## faucet paid into its own denominator widens the ceiling it is paid under
## (LESSONS: the coin learned this first).
func _gain_reputation(rp: int, counts_as_earned: bool) -> void:
    if rp <= 0:
        return
    var was_rank := reputation_rank
    if counts_as_earned:
        rp_earned_lifetime += rp
    reputation_points += rp
    reputation_rank = Reputation.rank_after(reputation_points, reputation_rank)
    # LOOP-13's feed line, kind `reputation` (the 22px glyph is W7-REPORT's; a
    # string kind falls back harmlessly). The sentence is the town's, not a tally.
    log_event("reputation", "+%d reputation — the town heard." % rp)
    reputation_changed.emit(reputation_points, reputation_rank)
    if reputation_rank > was_rank:
        # docs/04 §3.2: "Guild reputation rank increases — immediate full board reroll
        # (so the new rank is visible at once)."
        refresh_board()
        rank_advanced.emit(reputation_rank)


## docs/03 §8.1 M3. Set on the fifth failed attempt at a raid encounter that has
## never been cleared; cleared by the next raid FIRST clear, per the doc — a repeat
## clear of content the player has already beaten is not evidence of being unstuck.
func _update_stall_flag(enc, encounter_id: String, won: bool) -> void:
    if enc == null or not Reputation.is_raid_slot(String(enc.slot)):
        return
    if won:
        if clear_count(encounter_id) <= 1:
            stalled = false
        return
    if not Reputation.CATCHUP_ENABLED:
        return
    if clear_count(encounter_id) == 0 \
            and attempt_count(encounter_id) >= Reputation.STALL_ATTEMPTS:
        stalled = true


## The raid slots of `tier` this guild has cleared at least once.
func cleared_raid_slots(tier: int) -> Array:
    var out := []
    if content == null:
        return out
    for enc_id in cleared:
        if int(cleared[enc_id]) <= 0:
            continue
        var e = content.encounter(String(enc_id))
        if e == null or int(e.tier) != tier:
            continue
        var slot := String(e.slot)
        if Reputation.is_raid_slot(slot) and not out.has(slot):
            out.append(slot)
    return out


## docs/03 §6.2's `highest_unlocked_tier`. Reputation is what unlocks tiers
## (✅ CANON), so the rank's own gate is the answer — there is no second ladder.
func highest_unlocked_tier() -> int:
    return Reputation.max_raid_tier(reputation_rank)


## docs/05 §7.1 and §7.2's raid-outcome triggers, then §6's Day Tick.
##
## docs/05 §4 fixes this order and warns about it: all deltas first, then drift
## and the leave/disband checks, because rolling a leave check against a
## mid-update morale value would decide a departure on a number the player never
## saw.
func _apply_raid_morale(encounter_id: String, result, won: bool) -> void:
    if morale_ledger == null:
        morale_ledger = MoraleLedger.new()
    # A raid attempt is one session for the caps written "per attempt".
    morale_ledger.begin_session()

    last_wipe_penalty = {}
    last_attempt_morale = {}
    _tick_notes = {}
    for r in last_party:
        var net: float = _apply_morale(r, "brought")
        if won:
            net += _apply_morale(r, "cleared")
        else:
            # Recorded as applied, because docs/11 §7's Rally Flask gives half of this
            # exact number back and the player buys it AFTER seeing the wipe.
            var hit: float = _apply_morale(r, "wipe")
            if hit < 0.0:
                last_wipe_penalty[r.id] = hit
            net += hit
        last_attempt_morale[r.id] = net

    # docs/05 §7.1: "Raider knocked out during a clear — -3, max -6 per attempt."
    if result != null:
        for c in result.casualties:
            if c != null and c.raider != null:
                var ko: float = _apply_morale(c.raider, "knocked_out")
                last_attempt_morale[c.raider.id] = float(last_attempt_morale.get(c.raider.id, 0.0)) + ko

    # docs/07 §5.2 row 17 / OQ-8: a loot call is a mid-fight mistake whose morale
    # lands at encounter end. The sim counts them per raider (`loot_call` on the
    # queued delta, W7-SIM-EFFECTS); the ledger's own ONCE_SESSION cap keeps it
    # to one hit per attempt however many times they typed.
    if result != null and typeof(result.get("deltas_queued")) == TYPE_ARRAY:
        for delta in result.deltas_queued:
            if typeof(delta) != TYPE_DICTIONARY or int((delta as Dictionary).get("loot_call", 0)) <= 0:
                continue
            var caller = raider(String((delta as Dictionary).get("raider_id", "")))
            if caller == null:
                continue
            var lc: float = _apply_morale(caller, "loot_call")
            last_attempt_morale[caller.id] = float(last_attempt_morale.get(caller.id, 0.0)) + lc

    _apply_bench_morale()
    _resolve_day_tick()


## docs/05 §7.2: the bench row fires "only from the 2nd consecutive benched tick", which
## docs/04 §12.2's own counter line ("+1 on run resolve; reset to 0 on any run attended")
## is silent about. Two docs, one number: the specific one wins, and naming it here keeps
## the grace run from reading as an off-by-one.
const BENCHED_MORALE_FROM_STREAK := 2


## docs/05 §7.2's "Benched while healthy and the raid ran — -2". The last of that table's
## raid-outcome rows to be wired, and the reason the bench had no cost at all: the whole
## trigger was specced, capped and unfired.
##
## The counters are already updated when this runs, so a raider on their FIRST bench reads
## 1 and is spared. The cap in Morale's own row (-6 per 7 ticks) is what stops a long
## bench from spiralling, so no second limit is applied here.
##
## docs/05 §7.2's `benched_wishlist` variant, which "replaces the -2", is not fired:
## wishlists are docs/05 §12 Q6's optional module and every `wishlist` is empty, so the
## replacement condition can never be true and firing the -4 would be a guess.
func _apply_bench_morale() -> void:
    for r in roster:
        if int(r.consecutive_benched) < BENCHED_MORALE_FROM_STREAK:
            continue
        # "while HEALTHY and the raid ran" — somebody who has left the guild is not being
        # benched, and nothing else in this build can make a raider unavailable.
        if not r.is_available():
            continue
        _apply_morale(r, "benched")


## docs/05 §4 names two things that advance the clock: "It fires when the player
## resolves an Adventure or Raid attempt, OR EXPLICITLY RESTS IN TOWN."
##
## Resting is the recovery half of that sentence, and without it the wipe penalty
## is a one-way trip: a Common loses 10.8 morale to a wipe and drifts back only
## 1.125 a tick, so a guild that retries immediately after every failure spirals
## out. Measured before this existed: twelve straight A1 attempts took a guild
## from 48 average morale to 1, losing 11 of 12 raiders. See docs/15 BL-34.
##
## A rest is a Day Tick with no raid, so drift, leave checks and disband all run —
## resting is not free, it just is not a wipe.
func rest_in_town() -> void:
    _resolve_day_tick()
    # Stamped with the day the rest ENDED on — the tick above has moved the clock,
    # and "rested into day 24" is the fact the row states.
    log_event("phase", "Rested a day — day %d." % day)


## An absolute backstop on the rest loop, not a design number. docs/02 §4.3's own
## worked example (Steve at 14, Guildhall L2) runs to ~30 Day Ticks, and the
## slowest possible case — a Common at 0 morale with no facilities — is 40, so 90
## can only ever be reached by a bug.
const REST_DAY_LIMIT := 90


## docs/15 BL-34's fix: rest until the roster has settled, in one click.
##
## The measurement that prompted it: one wipe costs a Common 10.8 morale against
## 1.125 per Day Tick of drift, so recovery is 8-10 rests, and docs/02 §4.3 works
## an example that takes ~30. That is a click count, not a decision, and the
## alternative fix — raising the drift rate — would be tuning around the missing
## comfort-item lever (docs/05 §7.4) and would have to be undone later.
##
## It is NOT a safe-conduct pass. docs/05 §6's leave and disband checks fire on
## every tick of this loop, so it stops the moment anything happens that the player
## would want to see, and reports it. Returns:
##   days      how many Day Ticks passed
##   departed  display names of anyone who left, in the order they left
##   reason    "rested" | "departure" | "disbanded" | "empty" | "stalled" | "limit"
##   settled   whether the roster is now at or above baseline
func rest_until_recovered() -> Dictionary:
    var days := 0
    var lost: Array = []
    var reason := "rested"
    # One feed row for the whole rest, not one per tick (the ring buffer holds
    # twenty and docs/02 §4.3's own example runs to ~30 days).
    _feed_batch += 1

    while true:
        if roster.is_empty():
            reason = "empty"
            break
        if Morale.roster_is_rested(roster, facility_tier):
            break
        if days >= REST_DAY_LIMIT:
            reason = "limit"
            break

        var before: Dictionary = {}
        var before_exact: Dictionary = {}
        for r in roster:
            before[r.id] = r.display_name
            before_exact[r.id] = Morale.morale_exact(r)

        rest_in_town()
        days += 1

        if roster.is_empty():
            # A disband empties the roster wholesale; reporting twelve individual
            # departures would be a lie about what the player just saw.
            reason = "disbanded"
            break

        var present: Dictionary = {}
        for r in roster:
            present[r.id] = true
        for gone_id in before:
            if not present.has(gone_id):
                lost.append(before[gone_id])
        if not lost.is_empty():
            reason = "departure"
            break

        # A tick that moved nobody cannot be repeated into progress. PER RAIDER,
        # not as a roster total: six raiders drifting down to the baseline and six
        # drifting up cancel exactly (the playtest's seed 1000 on day 3, +/-1.125
        # each), and the total-based check this used to be called that "stalled"
        # one tick short of recovery — on the town's rest button too (W5-TESTS).
        # Unreachable while anyone is below baseline (drift always moves them), so
        # this is a guard against a future clamp, not an expected path.
        var moved := false
        for r in roster:
            var was: float = float(before_exact.get(r.id, Morale.morale_exact(r)))
            if absf(Morale.morale_exact(r) - was) >= 0.0001:
                moved = true
                break
        if not moved:
            reason = "stalled"
            break

    _feed_batch -= 1
    if days > 0:
        log_event("phase", "Rested %d day%s — day %d." % [days, "" if days == 1 else "s", day])
    for gone in lost:
        log_event("morale_down", "%s left the guild." % String(gone))
    if reason == "disbanded":
        log_event("mistake", "The guild disbanded.")
    return {
        "days": days,
        "departed": lost,
        "reason": reason,
        "settled": Morale.roster_is_rested(roster, facility_tier),
    }


func _roster_morale_total() -> float:
    var total := 0.0
    for r in roster:
        total += Morale.morale_exact(r)
    return total


# ------------------------------------------------- docs/02 §4: comfort and facilities

## The comfort floor a raider currently enjoys, guild-wide orders included.
func comfort_floor_of(raider_id: String) -> int:
    return Comfort.comfort_floor(placed_for(raider_id), guild_furnishings,
        _trophy_present(raider_id))


func placed_for(raider_id: String) -> Array:
    var held = furnishings.get(raider_id, [])
    return (held as Array).duplicate() if typeof(held) == TYPE_ARRAY else []


## docs/02 §4.2's Trophy Shelf pays "+2 extra if the raider was present for the kill
## it commemorates". A trophy commemorates a BOSS, so only a boss clear makes
## witnesses — trash does not get a shelf.
func _witness_kill(enc) -> void:
    if enc == null:
        return
    var kind := int(enc.kind)
    if kind != Enums.EncounterKind.MINI_BOSS and kind != Enums.EncounterKind.MAIN_BOSS:
        return
    for r in last_party:
        if r != null:
            _trophy_witnesses[r.id] = true
    _recompute_comfort()


## docs/02 §4.2's Trophy Shelf pays "+2 extra if the raider was present for the kill
## it commemorates". `last_party` plus the clear record is the only evidence the build
## has of who was in the room, which is what `_witness_kill()` records.
func _trophy_present(raider_id: String) -> bool:
    if _trophy_witnesses.has(raider_id):
        return bool(_trophy_witnesses[raider_id])
    return false


## Raider ids who were in the party for a boss clear. Written by `record_attempt`,
## saved, because who was in the room is a fact about the past.
var _trophy_witnesses: Dictionary = {}


## Push the derived comfort floor onto every raider. The single writer — `sim/` only
## reads `Raider.comfort_floor`, so this is the one place staleness could come from.
func _recompute_comfort() -> void:
    for r in roster:
        r.comfort_floor = comfort_floor_of(r.id)


## Buy a Furnishing and place it in one raider's quarters. Returns "" on success or
## the reason it could not happen, so a caller never has to guess why.
##
## docs/02 §4.2's Feather Bed "replaces Straw Cot in same slot", so a better
## furnishing in an occupied slot is an upgrade rather than a refusal. The old one is
## gone: neither doc offers a resale, and a durable object you paid for being
## displaced is the cost of the upgrade.
func buy_furnishing(furnishing_id: String, raider_id: String) -> String:
    var f := Comfort.furnishing(furnishing_id)
    if f.is_empty():
        return "No such furnishing."
    var who = raider(raider_id)
    if who == null:
        return "No such raider."

    var held := placed_for(raider_id)
    var replacing := ""
    var slot := Comfort.furnishing_slot(furnishing_id)
    for other in held:
        if Comfort.furnishing_slot(String(other)) == slot:
            replacing = String(other)
            break

    if replacing != "":
        if held.has(furnishing_id):
            return "%s already has one." % who.display_name
        var current := int(Comfort.furnishing(replacing).get("floor", 0))
        if int(f["floor"]) <= current:
            return "The %s they already have is no worse." % \
                String(Comfort.furnishing(replacing)["name"])
    else:
        var blocker := Comfort.placement_blocker(
            furnishing_id, held, facility_tier, who)
        if blocker != "":
            return blocker

    var price := Comfort.furnishing_price(furnishing_id)
    if gold < price:
        return "Costs %d G — you have %d." % [price, gold]
    if not spend_gold(price):
        return "Costs %d G — you have %d." % [price, gold]

    if replacing != "":
        held.erase(replacing)
    held.append(furnishing_id)
    furnishings[raider_id] = held
    _recompute_comfort()
    log_event("loot", "Bought %s for %s — %d G." % [
        String(f.get("name", furnishing_id)), who.display_name, price])
    comfort_changed.emit()
    return ""


## docs/02 §4.2's guild-wide variant. One purchase, felt by the whole roster —
## including raiders recruited after it, which is what makes it worth 4x.
func buy_guild_furnishing(furnishing_id: String) -> String:
    if not Comfort.is_guild_wide(furnishing_id):
        return "That one is bought for a person, not the guild."
    if guild_furnishings.has(furnishing_id):
        return "The guild already has that standing order."
    var price := Comfort.furnishing_price(furnishing_id)
    if gold < price:
        return "Costs %d G — you have %d." % [price, gold]
    if not spend_gold(price):
        return "Costs %d G — you have %d." % [price, gold]
    guild_furnishings.append(furnishing_id)
    _recompute_comfort()
    log_event("loot", "Bought %s for the whole guild — %d G." % [
        String(Comfort.furnishing(furnishing_id).get("name", furnishing_id)), price])
    comfort_changed.emit()
    return ""


## docs/11 §8.4's Guildhall rung. Returns "" on success, or which of the two gates —
## rank or price — is blocking, because docs/11 requires the screen to say which.
func upgrade_guildhall() -> String:
    var blocker := Comfort.upgrade_blocker(facility_tier, gold, reputation_rank)
    if blocker != "":
        return blocker
    var cost := Comfort.upgrade_cost(facility_tier)
    if not spend_gold(cost):
        return "Costs %d G — you have %d." % [cost, gold]
    facility_tier += 1
    # docs/05 §7.5: an upgrade raises the BASELINE, it is not a one-off spike. So
    # nobody gains morale here — they gain somewhere better to drift to.
    _recompute_comfort()
    facility_upgraded.emit(facility_tier)
    comfort_changed.emit()
    roster_changed.emit()
    return ""


## docs/11 §8.3's Indulgence: consumed, and it fires docs/05 §7.4's `comfort_item`
## trigger so the +8 and its 2-Day-Tick per-raider cooldown are that doc's numbers.
##
## The cooldown is checked by SPENDING it first and only then charging, because a
## player who is charged 20 G for a bath that the cooldown swallowed has been robbed.
func use_indulgence(indulgence_id: String, raider_id: String) -> String:
    var item := Comfort.indulgence(indulgence_id)
    if item.is_empty():
        return "No such indulgence."
    var who = raider(raider_id)
    if who == null:
        return "No such raider."
    if indulgences_today >= Comfort.indulgence_cap(roster.size()):
        return "The Market has sold out for today."
    var price := int(item.get("price", 0))
    if gold < price:
        return "Costs %d G — you have %d." % [price, gold]
    if morale_ledger == null:
        morale_ledger = MoraleLedger.new()

    var applied: float = _apply_morale(who, String(item["trigger"]))
    if is_zero_approx(applied):
        return "%s had one recently. It would not land." % who.display_name
    who.record_morale_day(day, int(who.morale), String(item["trigger"]))

    if not spend_gold(price):
        return "Costs %d G — you have %d." % [price, gold]
    indulgences_today += 1
    roster_changed.emit()
    return ""


## docs/05 §4's Day Tick: "It fires when the player resolves an Adventure or Raid
## attempt, or explicitly rests in town."
## docs/05 §4 defines a Day Tick as "one advance of the town clock" and says it "fires
## when the player resolves an Adventure or Raid attempt, or explicitly rests in town".
##
## The clock used to advance on a rest and NOT on an attempt, so twelve raids all
## happened on day 1 — harmless while nothing read the date, and wrong the moment the
## morale history started stamping rows with it (docs/15 BL-51). Advancing here means
## every caller of a Day Tick gets one, by construction.
func _resolve_day_tick() -> void:
    advance_day()
    morale_ledger.advance_tick()
    # Last tick's departures hit morale now, not when they happened.
    _apply_pending_departures()
    var report: Dictionary = Morale.resolve_day_tick(roster, _town_rng(), {
        "facility_tier": facility_tier,
        "onboarding_complete": onboarding_complete,
        "crisis_strikes": crisis_strikes,
    })

    crisis_strikes = int(report["crisis_strikes"])

    var departed: Array = report["departed"]
    if not departed.is_empty():
        var names: Array = []
        for r in departed:
            names.append(r.display_name)
            _remove_raider_object(r)
        # docs/05 §7.2's peer deltas land on the FOLLOWING tick, never this one —
        # the doc rules out a same-tick cascade in terms. They are queued here and
        # applied by the next tick's own pass. Queued as the two facts the pass
        # reads rather than as the Raider objects, because the queue is SAVED
        # (docs/14 §7.1's `pending_deltas`) and a departed raider is not on the
        # roster the save writes.
        for gone in departed:
            _pending_departures.append({"id": String(gone.id), "class_id": int(gone.class_id)})
        roster_changed.emit()
        for gone_name in names:
            log_event("morale_down", "%s left the guild." % String(gone_name))
        raiders_departed.emit(names)
        # docs/02 §4.4's "Big Dumb", the wall's one named event. Its condition is
        # `{"kind": "event", "name": "legendary_departed"}` and this is the only
        # place a Legendary can leave over morale, so it is the only place that
        # name can be true. One event per departure, because losing two is two
        # disasters and the record only fires once anyway.
        for gone in departed:
            if int(gone.rarity) == Enums.Rarity.LEGENDARY:
                check_achievements({"name": "legendary_departed"})

    _refresh_big_dumb()
    _record_morale_day()

    if crisis_strikes >= Morale.CRISIS_MODAL_STRIKE:
        guild_crisis.emit(crisis_strikes, float(report["p_disband_next"]))

    if bool(report["disbanded"]):
        # docs/05 §6.3 fires the event and wipes the roster; docs/03 §6.5 owns the
        # reputation penalty — the one failure in the game that costs RP, and even
        # it cannot demote, because it is clamped to the current rank's floor.
        reputation_points = Reputation.rp_after_disband(
            reputation_points, reputation_rank)
        reputation_changed.emit(reputation_points, reputation_rank)
        roster = []
        crisis_strikes = 0
        roster_changed.emit()
        log_event("mistake", "The guild disbanded.")
        guild_disbanded.emit()


## Departures queued for the next tick's peer-morale hit (docs/05 §7.2), each
## `{id, class_id}`. Saved as `pending_deltas` — "so quitting between encounters
## cannot eat a consequence" (docs/14 §7.1).
var _pending_departures: Array = []


func _apply_pending_departures() -> void:
    if _pending_departures.is_empty():
        return
    for gone in _pending_departures:
        var gone_class: int = int((gone as Dictionary).get("class_id", -1))
        var gone_id := String((gone as Dictionary).get("id", ""))
        for r in roster:
            var trigger := "peer_left_same_class" if r.class_id == gone_class \
                else "peer_left"
            _apply_morale(r, trigger, gone_id)
    _pending_departures.clear()


## The queued departures, for the save and for a test. Copies, so nothing outside
## can edit the queue.
func pending_deltas() -> Array:
    var out: Array = []
    for gone in _pending_departures:
        out.append((gone as Dictionary).duplicate())
    return out


## Every morale trigger this file fires goes through here, so the history knows what
## moved a raider without `sim/` having to record anything about days.
##
## Keeps the LARGEST mover of the tick per raider, because that is the one sentence a
## history line has room for: "the wipe", not "brought, then the wipe, then a friend
## leaving".
var _tick_notes: Dictionary = {}


func _apply_morale(who, trigger: String, subject: String = "") -> float:
    if who == null:
        return 0.0
    if morale_ledger == null:
        morale_ledger = MoraleLedger.new()
    # docs/05 §7.5's second backstory hook: "named trigger tags that multiply a
    # §7 delta by 1.5x or 0.5x". Which tag listens to which trigger is docs/04
    # §8.3's own "Listens for" column, mapped in `BackstoryPool.TRIGGER_TAGS`.
    var scale := BackstoryPool.tag_scale(who, trigger)
    var delta: float = Morale.apply(who, trigger, morale_ledger, subject, scale)
    _count_bullet_triggers(who, trigger, delta)
    if is_zero_approx(delta):
        return delta
    var best: Dictionary = _tick_notes.get(who.id, {"trigger": "", "size": 0.0})
    if absf(delta) > float(best["size"]):
        _tick_notes[who.id] = {"trigger": trigger, "size": absf(delta)}
    return delta


## docs/04 §11.3 condition 4's counter: "Any of their own backstory bullets triggered 3+
## times in one tier."
##
## AMBIGUITY, BEHIND A SWITCH (recorded in docs/15 BL-59, 2026-09-15).
## "Triggered" has three readings and they fire at very different rates:
##   (i)   the listened-for event happened at all;
##   (ii)  it happened AND moved this raider's morale by a non-zero amount, after
##         docs/04 §11.3's 0.35 negative multiplier and docs/05 §7.6's caps;
##   (iii) it happened and the tag actually amplified or dampened it.
## `true` ships (ii); `false` ships (i). (ii) is the default because it is the reading the
## code can PROVE — a trigger swallowed by a cap did nothing to the character, and
## suspending a Legendary's morale floor on an event they never felt is the guess canon's
## "BIG dumb" forbids. Reading (i) fires far sooner, because caps swallow a lot.
##
## (iii) is deliberately not offered: only seven trigger families are mapped in
## `BackstoryPool.TRIGGER_TAGS` out of docs/04 §8.3's eighteen tags, so several
## Legendaries carry no bullet that could ever amplify anything, and a condition that is
## structurally unreachable for some characters should not be narrowed further.
const BULLET_TRIGGER_COUNTS_CAPPED := true


## Credit every tag this raider carries that listens for `trigger`. Their OWN bullets
## only — condition 4 says "any of THEIR OWN backstory bullets" — which
## `BackstoryPool.tags_listening()` intersected with the carried tags is exactly.
func _count_bullet_triggers(who, trigger: String, delta: float) -> void:
    if BULLET_TRIGGER_COUNTS_CAPPED and is_zero_approx(delta):
        return
    var listeners: Array = BackstoryPool.tags_listening(trigger)
    if listeners.is_empty():
        return
    var counts: Dictionary = bullet_triggers.get(who.id, {})
    var credited := false
    for bullet in who.backstory:
        if typeof(bullet) != TYPE_DICTIONARY:
            continue
        # docs/04 §8.3's tags carry an optional `:qualifier`; the family is what listens.
        var base := String((bullet as Dictionary).get("tag", "")).get_slice(":", 0)
        if not listeners.has(base):
            continue
        counts[base] = int(counts.get(base, 0)) + 1
        credited = true
    if credited:
        bullet_triggers[who.id] = counts


## The highest count any single bullet of theirs has reached in the current tier.
func bullet_trigger_peak(raider_id: String) -> int:
    var counts: Dictionary = bullet_triggers.get(raider_id, {})
    var peak := 0
    for tag in counts:
        peak = maxi(peak, int(counts[tag]))
    return peak


## docs/04 §11.3's five "BIG dumb" conditions — canon's own bar for losing a Legendary
## ("unless you are BIG dumb"). While any holds, the Legendary morale floor is suspended
## and the negative multiplier returns to 1.0.
##
## THREE OF THE FIVE ARE LIVE. #1 was made live by `_apply_run_counters()` writing
## `consecutive_benched`; before that nothing anywhere incremented the counter, so this
## predicate read 0 forever and the floor was unconditional — docs/15 BL-59's "Live" claim
## about that row was false, which is the correction recorded in
## build/plan/q-state-truth.md. #2 and #4 are live now, on `wipe_streaks` and
## `bullet_triggers`, which are counters this file writes and saves.
##
## TWO ARE NOT, and the table below says so rather than letting them look implemented:
## #3 needs the wishlist module (docs/14 §5.3's `wishlist` row is "❓ OPEN module, behind
## a flag", and `FLAG_DEFAULTS`'s `wishlists` is off), and #5 needs a payday, which exists
## in neither the code nor the doc that owns it (docs/15 Q-31). Approximating either would
## suspend a Legendary's floor on a guess, which is the one thing canon's "BIG dumb"
## forbids.
const BENCHED_RUNS_IS_BIG_DUMB := 5

## docs/04 §11.3 #2's "3 times in a row" and #4's "3+ times in one tier". Both are the
## doc's own number; neither is tunable here.
const WIPES_ON_ONE_BOSS_IS_BIG_DUMB := 3
const BULLET_TRIGGERS_IS_BIG_DUMB := 3

## docs/04 §11.3's table, in the doc's order. `condition` and `reads_as` are that table's
## two columns verbatim — the player-facing sentence is the designer's, not a paraphrase —
## and `live` is whether this build can evaluate the row at all.
const BIG_DUMB_CONDITIONS := [
    {
        "id": "benched_5", "row": 1, "live": true,
        "condition": "Benched for 5 consecutive runs",
        "reads_as": "You stopped using them",
    },
    {
        "id": "wiped_3", "row": 2, "live": true,
        "condition": "Wiped on the same boss 3 times in a row with them in the raid",
        "reads_as": "You are not learning",
    },
    {
        "id": "wishlist_insult_2", "row": 3, "live": false,
        "condition": "An item on their wishlist awarded to a lower-rarity raider of the"
            + " same class, twice",
        "reads_as": "You insulted them, twice",
    },
    {
        "id": "bullet_3_this_tier", "row": 4, "live": true,
        "condition": "Any of their own backstory bullets triggered 3+ times in one tier",
        "reads_as": "You did the one thing they told you not to",
    },
    {
        "id": "unpaid_2_paydays", "row": 5, "live": false,
        "condition": "Guild gold at 0 on payday for 2 consecutive paydays",
        "reads_as": "You cannot pay them",
    },
]

## raider_id -> Array of the condition ids currently holding. DERIVED and not saved, like
## `comfort_floor`: it is a pure function of the counters, and a saved copy could disagree
## with them. docs/04 §11.4 needs the WHY as well as the whether — `big_dumb_active` is
## one bool, so a screen that wanted to name the reason could not.
var big_dumb_reasons: Dictionary = {}

## The raider whose docs/04 §11.4 confirmation is waiting to be shown, or "". Derived, not
## saved: it is recomputed from `legendary_warned` and the morale on the roster, so a quit
## before the player acknowledged it does not lose the warning.
var pending_legendary_warning: String = ""


func _refresh_big_dumb() -> void:
    # docs/04 §11.3 #4 is scoped "in one tier", and `highest_unlocked_tier()` is the only
    # tier this build has (docs/03 §6.2). Crossing into a new one is a clean slate: the
    # bullets that annoyed them at Tier 1 are not evidence about Tier 2.
    var tier := highest_unlocked_tier()
    if tier != bullet_tier:
        bullet_triggers = {}
        bullet_tier = tier

    big_dumb_reasons = {}
    for r in roster:
        if r.rarity != Enums.Rarity.LEGENDARY:
            continue
        var reasons: Array = []
        # #1 "Benched for 5 consecutive runs" — reads as "You stopped using them".
        if int(r.consecutive_benched) >= BENCHED_RUNS_IS_BIG_DUMB:
            reasons.append("benched_5")
        # #2 "Wiped on the same boss 3 times in a row with them in the raid."
        if wipe_streak_of(r.id) >= WIPES_ON_ONE_BOSS_IS_BIG_DUMB:
            reasons.append("wiped_3")
        # #4 "Any of their own backstory bullets triggered 3+ times in one tier."
        if bullet_trigger_peak(r.id) >= BULLET_TRIGGERS_IS_BIG_DUMB:
            reasons.append("bullet_3_this_tier")
        r.big_dumb_active = not reasons.is_empty()
        if not reasons.is_empty():
            big_dumb_reasons[r.id] = reasons

    _refresh_legendary_warning()


## docs/04 §11.4's other half: "a hard, unmissable confirmation the *first* time a
## Legendary crosses below 40".
##
## Written as "is below and has not been acknowledged" rather than as an edge, on purpose.
## An edge fires into whatever happens to be listening, and a modal nobody heard is
## exactly the surprise §11.4 exists to prevent — "Losing a hand-authored character should
## be a story the player tells, but it must never be a surprise." So the warning stays
## pending across saves, screens and sessions until something acknowledges it, and
## `legendary_warned` is what makes "the first time" mean once ever.
func _refresh_legendary_warning() -> void:
    if not pending_legendary_warning.is_empty():
        return
    for r in roster:
        if not Morale.is_unbotherable(r):
            continue
        if legendary_warned.has(r.id):
            continue
        if float(r.morale) >= float(Morale.LEGENDARY_FLOOR):
            continue
        pending_legendary_warning = r.id
        legendary_at_risk.emit(r.id)
        return


## Called by whichever screen showed docs/04 §11.4's confirmation. Marks it seen for the
## life of the save, so the second crossing is not a second modal.
func acknowledge_legendary_warning() -> void:
    if pending_legendary_warning.is_empty():
        return
    if not legendary_warned.has(pending_legendary_warning):
        legendary_warned.append(pending_legendary_warning)
    pending_legendary_warning = ""


## The condition ids currently suspending this raider's floor, in docs/04 §11.3's order.
func big_dumb_reason_ids(raider_id: String) -> Array:
    var ids: Array = big_dumb_reasons.get(raider_id, [])
    return ids.duplicate()


## One docs/04 §11.3 row by id, or {}. What a screen reads to print the condition.
func big_dumb_condition(condition_id: String) -> Dictionary:
    for row in BIG_DUMB_CONDITIONS:
        if String((row as Dictionary)["id"]) == condition_id:
            return (row as Dictionary).duplicate(true)
    return {}


## docs/04 §11.4's "persistent roster warning while any BIG-dumb condition is active", as
## one line of text, or "" when the floor is holding.
##
## "Morale floor suspended" is docs/04 §11.3's own phrase for what has happened, and is
## deliberately NOT the existing "AT RISK" stamp (docs/13 §244, docs/05 §322): that word
## already means morale bands 0-2, and the point of this warning is that the raider is not
## there yet and now nothing is stopping them.
func big_dumb_warning_line(raider_id: String) -> String:
    var ids := big_dumb_reason_ids(raider_id)
    if ids.is_empty():
        return ""
    var reads := ""
    for cid in ids:
        var row := big_dumb_condition(String(cid))
        if row.is_empty():
            continue
        if not reads.is_empty():
            reads += "; "
        reads += String(row["reads_as"])
    return "Morale floor suspended — %s" % reads


## The confirmation docs/04 §11.4 asks for, as the lines a screen puts in Labels. Empty
## when nothing is pending. The last line is §11.3's own consequence read backwards: while
## the floor holds a Legendary "cannot enter the canon 'may leave guild' bands (10-30) at
## all", so saying what suspending it costs is a statement of the rule, not a threat.
func legendary_warning_lines() -> Array:
    if pending_legendary_warning.is_empty():
        return []
    var who = raider(pending_legendary_warning)
    if who == null:
        return []
    var lines: Array = [
        "%s has fallen below %d morale." % [who.display_name, Morale.LEGENDARY_FLOOR],
    ]
    var warning := big_dumb_warning_line(who.id)
    if not warning.is_empty():
        lines.append(warning)
    lines.append("Their floor no longer holds them out of the bands where a raider"
        + " may leave.")
    return lines


## Write one history row per raider for the Day Tick that just resolved. docs/13 §5's
## "morale history", recorded after drift so the number in the log is the number the
## roster shows.
func _record_morale_day() -> void:
    for r in roster:
        var note: Dictionary = _tick_notes.get(r.id, {})
        r.record_morale_day(day, int(r.morale), String(note.get("trigger", "")))
    _tick_notes = {}


func _remove_raider_object(target) -> void:
    for i in roster.size():
        if roster[i].id == target.id:
            roster.remove_at(i)
            _forget_raider_counters(String(target.id))
            return


## The town's own RNG stream. docs/14 §8 keeps town rolls off the combat stream so
## a raid's seed cannot shift a departure, or vice versa.
func _town_rng():
    return Rng.new(Rng.splitmix64_mix(guild_seed + day * 104729 + 17))


## docs/05 §7.5's facility tier, owned by docs/06's upgrade track. Zero until the
## Guildhall's facilities ship, which is the honest value rather than a guess.
var facility_tier: int = 0


# ---------------------------------------------------------------- loot

## Give a pending drop to a raider. docs/09 §14 rulings: a raider cannot refuse
## an item, and re-assignment later is allowed. Returns false if the item is not
## pending or the raider cannot use it, so a bad call changes nothing.
func assign_loot(item_id: String, raider_id: String) -> bool:
    var idx := _pending_index(item_id)
    if idx < 0 or content == null:
        return false
    var it = pending_loot[idx]
    var r = raider(raider_id)
    if r == null or not it.can_be_used_by(r.class_id):
        return false
    r.equip(content, it)
    # docs/13 §5's "On record" line prints this, and it read "took 0 drops" for a raider
    # in full raid gear. Counted here rather than in `equip()` because `sim/` must not
    # know the difference between a drop and a Market purchase.
    r.loot_received += 1
    pending_loot.remove_at(idx)
    loot_changed.emit()
    roster_changed.emit()
    # docs/14 §7.4: "Loot assignment committed — it is a decision with morale
    # consequences."
    autosave()
    return true


## docs/09 §14.3's one-click "Suggested": fill every row with the need-based
## pick. Rows that help nobody are LEFT PENDING rather than forced onto someone —
## the Market is where those belong once it exists.
##
## docs/15 BL-32: PARTY FIRST, then the rest of the roster. §14.3's Option B is
## "need-based", and the literal roster-wide reading handed gear to benched
## raiders during exactly the grind where that hurts — measured, twelve A1 clears
## armed only 4 of the 6 who actually went. Offering the party first is still
## need-based; it just reads "need" as the need of the people in the field.
func assign_suggested_loot() -> int:
    if content == null:
        return 0
    var assigned := 0
    for group in [_party_for_loot(), roster]:
        for row in Loot.plan(pending_loot.duplicate(), content, group):
            if row["suggested"] == null:
                continue
            if assign_loot(row["item"].id, row["suggested"].id):
                assigned += 1
    return assigned


## The raiders the Suggested split offers loot to first.
func _party_for_loot() -> Array:
    return last_party if not last_party.is_empty() else roster


## docs/09 §14.3 point 4: "A Sell target sits alongside the raiders." Returns
## the gold paid, or 0 if the item was not pending.
##
## docs/05 §7.3 prices the morale side of this — "Passed over: a wishlisted item
## was sold at the Market, -7 morale, not capped; this is the player choosing gold
## over a person" — and that hook belongs here when the wishlist module lands.
## Nothing is applied yet because wishlists do not exist to be passed over.
func sell_loot(item_id: String) -> int:
    var idx := _pending_index(item_id)
    if idx < 0:
        return 0
    var paid := Economy.sell_price(pending_loot[idx], reputation_rank)
    var sold_name := String(pending_loot[idx].name)
    _remember_sale(pending_loot[idx])
    pending_loot.remove_at(idx)
    items_sold_lifetime += 1
    add_gold(paid)
    log_event("gold", "Sold %s for %d G." % [sold_name, paid])
    loot_changed.emit()
    return paid


## docs/02 §6.3's sell-all helper, "the single highest-value convenience in the
## game". Sells only what NOBODY on the roster can wear, so it can never quietly
## sell a sidegrade somebody wanted.
func sell_unusable_loot() -> int:
    var junk := Economy.unusable_by(pending_loot.duplicate(), roster)
    var total := 0
    _feed_batch += 1
    for it in junk:
        total += sell_loot(it.id)
    _feed_batch -= 1
    if not junk.is_empty():
        log_event("gold", "Sold %d piece%s nobody could wear for %d G." % [
            junk.size(), "" if junk.size() == 1 else "s", total])
    return total


## What the sell-all helper would pay, for the footer preview.
func unusable_loot_value() -> int:
    return Economy.total_sell_price(
        Economy.unusable_by(pending_loot.duplicate(), roster), reputation_rank)


# ------------------------------------------------- docs/02 §11: town buildings

func building_level(building: String) -> int:
    match building:
        "guildhall":
            return facility_tier + 1
        "tavern":
            return tavern_tier
        "market":
            return market_tier
        _:
            return 1


## Buy the next rung of a town building. Returns "" or which of the two gates blocks it,
## because docs/11 §8.4 requires the screen to be able to say which.
func upgrade_building(building: String) -> String:
    var level := building_level(building)
    var blocker := Buildings.upgrade_blocker(building, level, gold, reputation_rank)
    if blocker != "":
        return blocker
    var cost := Buildings.upgrade_cost(building, level)
    if cost > 0 and not spend_gold(cost):
        return "Costs %d G — you have %d." % [cost, gold]

    match building:
        "guildhall":
            facility_tier += 1
            _recompute_comfort()
            facility_upgraded.emit(facility_tier)
            comfort_changed.emit()
        "tavern":
            tavern_tier += 1
            # docs/02 §5.2: a bigger Tavern shows more slots, so the board grows at once
            # rather than at the next refresh — the player just paid for those seats.
            refresh_board()
        "market":
            market_tier += 1
            comfort_changed.emit()
    log_event("system", "%s upgraded to level %d%s." % [
        building.capitalize(), level + 1, (" for %d G" % cost) if cost > 0 else ""])
    roster_changed.emit()
    return ""


# ------------------------------------------------- docs/04 §3: the Tavern board

## docs/02 §5.2: "4 at Tavern L1, 5 at L2, 6 at L3, 7 at L4."
const BOARD_SLOTS := [4, 5, 6, 7]

## docs/04 §3.2: "manual reroll cost: `50g × 2^(rerolls_since_last_run)`, capped at
## 400g. Counter resets to 0 on run resolution."
const REROLL_BASE := 50
const REROLL_CAP := 400


func board_slots() -> int:
    return BOARD_SLOTS[clampi(tavern_tier - 1, 0, BOARD_SLOTS.size() - 1)]


func reroll_cost() -> int:
    return mini(REROLL_CAP, REROLL_BASE * (1 << mini(rerolls_since_run, 8)))


## Whether opening the Tavern should fill the board for free. True exactly once per
## campaign — the first look, which would otherwise be a dead screen.
##
## docs/04 §3.2 refreshes the board on events, not on opening the door, and §3.4 says a
## dismissed candidate's slot "stays empty until the next refresh". So "the board is
## empty" is NOT the question: an emptied board must stay empty, and a loaded board must
## not be re-rolled. Both were free refreshes past §3.2's `50g x 2^n` ladder.
func board_needs_first_roll() -> bool:
    return not board_rolled and tavern_board.is_empty()


## Roll a whole new board. docs/04 §3.2's free refresh path — a run resolving, or a rank
## increase — calls this with no charge; the paid path is `pay_to_reroll()`.
func refresh_board() -> void:
    if content == null:
        tavern_board = []
        return
    var names = _name_pool()
    var stories = _backstory_pool()
    var legends = _legendary_pool()
    var taken: Array = []
    for r in roster:
        taken.append(r.display_name)

    tavern_board = Recruitment.roll_board(_tavern_rng(), board_slots(),
        reputation_rank, highest_unlocked_tier(), {
            "claimed_legendary_classes": legendary_classes_found,
            "pity": recruit_pity,
            "facility_tier": facility_tier,
            "name_pool": names,
            "backstory_pool": stories,
            "legendary_pool": legends,
            "taken_names": taken,
        })
    recruit_pity = Recruitment.board_pity(recruit_pity, tavern_board)
    board_rolled = true
    board_changed.emit()


## docs/04 §3.2's paid refresh. Returns "" or why not.
func pay_to_reroll() -> String:
    var price := reroll_cost()
    if gold < price:
        return "A reroll costs %d G — you have %d." % [price, gold]
    if not spend_gold(price):
        return "A reroll costs %d G — you have %d." % [price, gold]
    rerolls_since_run += 1
    refresh_board()
    return ""


## Hire a candidate off the board. Returns "" or why not.
##
## ✅ C12 is enforced here rather than at generation: a Legendary the player HIRES claims
## that class for the save. One who was merely offered and passed over does not, or a
## player could burn the nine Legendaries by rerolling past them.
func hire(index: int) -> String:
    if index < 0 or index >= tavern_board.size():
        return "Nobody is sitting there."
    var who = tavern_board[index]
    if roster_is_full():
        return "The roster is full at %d. Dismiss somebody first." % roster_cap()
    var price := Recruitment.cost_of(who.rarity, highest_unlocked_tier())
    if gold < price:
        return "%s wants %d G — you have %d." % [who.display_name, price, gold]
    if not spend_gold(price):
        return "%s wants %d G — you have %d." % [who.display_name, price, gold]

    if not add_raider(who):
        add_gold(price)
        return "The roster is full at %d." % roster_cap()
    if who.rarity == Enums.Rarity.LEGENDARY \
            and not legendary_classes_found.has(who.class_id):
        legendary_classes_found.append(who.class_id)
    tavern_board.remove_at(index)
    log_event("recruit", "Hired %s the %s for %d G." % [
        who.display_name, Enums.class_name_of(who.class_id), price])
    autosave()   # docs/14 §7.4: "Recruit hired / raider fired."
    # docs/05 §7.4's `mentor` tag listens for exactly this, and the trigger table has a
    # row for it, so the recruit is announced to the roster that already exists.
    raider_hired.emit(who.display_name)
    board_changed.emit()
    return ""


## docs/04 §3.4: "dismissing a candidate from the board is free and instant; the slot
## stays empty until the next refresh."
func dismiss_candidate(index: int) -> bool:
    if index < 0 or index >= tavern_board.size():
        return false
    tavern_board.remove_at(index)
    board_changed.emit()
    return true


## docs/04 §12.3's roster operation, and docs/05 §12 Q12's price for it: "Voluntary
## dismissal is -2 to all remaining, versus -4 for a departure. Cheaper, but not free."
func dismiss_raider(raider_id: String) -> String:
    var who = raider(raider_id)
    if who == null:
        return "No such raider."
    if not remove_raider(raider_id):
        return "No such raider."
    for r in roster:
        Morale.apply(r, "peer_dismissed", morale_ledger, who.id)
    _recompute_comfort()
    log_event("morale_down", "Dismissed %s — the rest took it badly." % who.display_name)
    roster_changed.emit()
    # docs/14 §7.4: "Recruit hired / raider fired" — the half of that row that was
    # never wired (SHIP-15). The ledger's -2 lands in the same rotation entry.
    autosave()
    return ""


func _name_pool():
    if _names_cache == null:
        _names_cache = NamePool.load_from()
    return _names_cache


func _backstory_pool():
    if _stories_cache == null:
        _stories_cache = BackstoryPool.load_from()
    return _stories_cache


func _legendary_pool():
    if _legends_cache == null:
        _legends_cache = LegendaryPool.load_from()
    return _legends_cache


var _names_cache = null
var _stories_cache = null
var _legends_cache = null


## The Tavern's own RNG stream. docs/14 §8 keeps town rolls off the combat stream, and
## the board has to change when the day does or a refresh would return the same faces.
func _tavern_rng():
    return Rng.new(Rng.splitmix64_mix(
        guild_seed + day * 31337 + rerolls_since_run * 7 + 91))


# --------------------------------------------------- docs/11 §7: consumables

func consumable_count(sku_id: String, tier: int) -> int:
    return int(consumables.get(Consumables.stock_key(sku_id, tier), 0))


func chosen_count(sku_id: String, tier: int) -> int:
    return int(chosen_consumables.get(Consumables.stock_key(sku_id, tier), 0))


## Buy `count` of a SKU at a tier. Returns "" on success, or why not — docs/11 §7's
## stack cap and the rank gate are both refusals with a stated reason.
func buy_consumable(sku_id: String, tier: int, count: int = 1) -> String:
    var s := Consumables.sku(sku_id)
    if s.is_empty():
        return "No such consumable."
    if count <= 0:
        return "Buy at least one."
    if tier < 1 or tier > Consumables.top_potion_tier(reputation_rank):
        return "The Market does not stock that grade for a %s guild." \
            % Enums.reputation_name_of(reputation_rank)

    var key := Consumables.stock_key(sku_id, tier)
    var held := int(consumables.get(key, 0))
    if held + count > Consumables.STACK_CAP:
        return "The cupboard holds %d, and you have %d." % [
            Consumables.STACK_CAP, held]

    var price := Consumables.price_at(sku_id, tier) * count
    if gold < price:
        return "Costs %d G — you have %d." % [price, gold]
    if not spend_gold(price):
        return "Costs %d G — you have %d." % [price, gold]

    consumables[key] = held + count
    log_event("loot", "Bought %d× %s for %d G." % [count, String(s.get("name", sku_id)), price])
    consumables_changed.emit()
    return ""


## Chalk a consumable onto the next attempt. Nothing is spent here — docs/01 §6.2 says
## cancelling at confirm is free, and docs/11 §7 says so again in its own words.
func choose_consumable(sku_id: String, tier: int, target_id: String = "") -> String:
    var key := Consumables.stock_key(sku_id, tier)
    var held := int(consumables.get(key, 0))
    var already := int(chosen_consumables.get(key, 0))
    if held <= already:
        return "You have none spare."
    if Consumables.kind_of(sku_id) == Consumables.Kind.POST_WIPE:
        return "A Rally Flask is drunk after a wipe, not before one."

    # Ask the loadout whether it would take it, so the refusal the player sees is the
    # same one the sim would give.
    var probe := build_loadout(last_party if not last_party.is_empty() else roster)
    var problem := Consumables.fold_into_loadout(
        probe, sku_id, tier, target_id, roster.size())
    if not problem.is_empty():
        return problem

    chosen_consumables[key] = already + 1
    if not target_id.is_empty():
        chosen_targets[key] = target_id
    consumables_changed.emit()
    return ""


func clear_chosen_consumables() -> void:
    chosen_consumables = {}
    chosen_targets = {}
    consumables_changed.emit()


## The loadout the sim will receive, folded from the current selection. Pure read —
## calling it does not spend anything, which is what makes the confirm screen free.
func build_loadout(party: Array = []) -> Dictionary:
    var loadout := Consumables.new_loadout()
    var size: int = party.size() if not party.is_empty() else roster.size()
    for key in chosen_consumables:
        var sku_id := Consumables.sku_of_key(String(key))
        var tier := Consumables.tier_of_key(String(key))
        var target := String(chosen_targets.get(key, ""))
        for i in int(chosen_consumables[key]):
            Consumables.fold_into_loadout(loadout, sku_id, tier, target, size)
    return loadout


## docs/11 §7's commit point, and the only place a pre-raid consumable leaves the
## cupboard: "only *spent* as the attempt begins".
##
## `potions_spent` is what the sim actually drank, so unopened potions come home.
func spend_loadout(potions_spent: int = -1, unspent: Array = []) -> void:
    # docs/07 §5.2 row 15: a forgotten consumable "is not consumed". The sim
    # lists them (`result.consumables_unspent`, W7-SIM-EFFECTS); the group
    # buffs were opened for the party and stay charged, and each Steady Hands
    # potion a raider forgot comes back to the cupboard.
    var forgotten_potions := 0
    for row in unspent:
        if typeof(row) == TYPE_DICTIONARY and String((row as Dictionary).get("sku", "")) == "potion_of_steady_hands":
            forgotten_potions += 1
    for key in chosen_consumables:
        var sku_id := Consumables.sku_of_key(String(key))
        var take := int(chosen_consumables[key])
        if sku_id == "minor_healing_potion" and potions_spent >= 0:
            take = mini(take, potions_spent)
        if sku_id == "potion_of_steady_hands":
            take = maxi(0, take - forgotten_potions)
        var held := int(consumables.get(key, 0))
        var left := maxi(0, held - take)
        if left == 0:
            consumables.erase(key)
        else:
            consumables[key] = left
    clear_chosen_consumables()


## docs/11 §7's Rally Flask: "Halves the wipe morale penalty for all participants of the
## attempt just failed." Spent from the Results screen, on a wipe that already landed —
## which is why the penalties are recorded when they are applied.
func use_rally_flask(tier: int = 1) -> String:
    if last_wipe_penalty.is_empty():
        return "Nothing to drink to."
    var key := Consumables.stock_key("rally_flask", tier)
    if int(consumables.get(key, 0)) <= 0:
        return "You have no Rally Flask."

    var refund := Consumables.wipe_refund_at(tier)
    var lifted := 0.0
    for raider_id in last_wipe_penalty:
        var who = raider(String(raider_id))
        if who == null:
            continue
        # "rounds toward zero" — the flask gives back the smaller half.
        var give := float(int(absf(float(last_wipe_penalty[raider_id])) * refund))
        if give <= 0.0:
            continue
        Morale.set_morale(who, Morale.morale_exact(who) + give)
        who.record_morale_day(day, int(who.morale), "rally_flask")
        last_attempt_morale[raider_id] = float(last_attempt_morale.get(raider_id, 0.0)) + give
        lifted += give

    consumables[key] = int(consumables[key]) - 1
    if int(consumables[key]) <= 0:
        consumables.erase(key)
    last_wipe_penalty = {}
    consumables_changed.emit()
    roster_changed.emit()
    if lifted <= 0.0:
        return "It helps nobody, but it was drunk."
    return ""


# ------------------------------------------------------- docs/02 §6: the Market

## docs/02 §6.1's shelf depth.
const BUY_BACK_SLOTS := 6

## docs/02 §6.1: buy-back "costs 1.25x sale price".
const BUY_BACK_MARKUP := 1.25


## Sell something a raider is wearing. docs/02 §6.3 wants a "worn by" column
## "so the player cannot sell equipped gear without a confirm" — the confirm is the
## caller's, because a model that refuses outright would make raid-tier upgrades
## unsellable forever.
##
## Returns the gold paid, or 0 if that slot was empty.
func sell_equipped(raider_id: String, slot: int) -> int:
    if content == null:
        return 0
    var who = raider(raider_id)
    if who == null:
        return 0
    var it = who.item_in(content, slot)
    if it == null:
        return 0
    who.unequip(content, slot)
    var paid := Economy.sell_price(it, reputation_rank)
    _remember_sale(it)
    add_gold(paid)
    log_event("gold", "Sold %s off %s for %d G." % [String(it.name), who.display_name, paid])
    roster_changed.emit()
    loot_changed.emit()
    return paid


## docs/02 §6.1's insurance against a mis-sale. The markup means undoing a mistake
## costs something, so it cannot be used as a free price oracle.
func buy_back_price(item_id: String) -> int:
    if content == null:
        return 0
    var it = content.item(item_id)
    if it == null:
        return 0
    return maxi(1, int(ceil(float(Economy.sell_price(it, reputation_rank))
        * BUY_BACK_MARKUP)))


## The markup as a percentage, for the shelf's heading.
func buy_back_markup_percent() -> int:
    return int(round(BUY_BACK_MARKUP * 100.0))


## Take a sold item back off the shelf. Returns "" on success, or why not.
func buy_back(item_id: String) -> String:
    if not sold_recently.has(item_id):
        return "That is not on the shelf any more."
    if content == null:
        return "The Market is closed."
    var it = content.item(item_id)
    if it == null:
        return "That item no longer exists."
    var price := buy_back_price(item_id)
    if gold < price:
        return "Costs %d G — you have %d." % [price, gold]
    if not spend_gold(price):
        return "Costs %d G — you have %d." % [price, gold]
    sold_recently.erase(item_id)
    pending_loot.append(it)
    log_event("loot", "Bought back %s for %d G." % [String(it.name), price])
    loot_changed.emit()
    return ""


## Push a sale onto the shelf, oldest off the end. An item sold twice moves to the
## front rather than appearing twice.
func _remember_sale(it) -> void:
    if it == null:
        return
    sold_recently.erase(it.id)
    sold_recently.push_front(it.id)
    while sold_recently.size() > BUY_BACK_SLOTS:
        sold_recently.pop_back()


## Everything the Market's Sell tab lists: the unassigned window plus everything
## worn, each row carrying who is wearing it so the screen can ask for a confirm.
## docs/02 §6.3's "Guild inventory with a `worn by` column".
func sell_rows() -> Array:
    var rows: Array = []
    for it in pending_loot:
        rows.append({
            "item": it, "worn_by": "", "raider_id": "", "slot": -1,
            "price": Economy.sell_price(it, reputation_rank),
        })
    if content == null:
        return rows
    for r in roster:
        for slot in Enums.all_slots():
            var it = r.item_in(content, slot)
            if it == null:
                continue
            rows.append({
                "item": it, "worn_by": r.display_name, "raider_id": r.id,
                "slot": slot,
                "price": Economy.sell_price(it, reputation_rank),
            })
    return rows


func _pending_index(item_id: String) -> int:
    for i in pending_loot.size():
        if pending_loot[i].id == item_id:
            return i
    return -1


# ---------------------------------------------------------------- serialization

func to_dict() -> Dictionary:
    var raiders := []
    for r in roster:
        raiders.append(r.to_dict())
    # docs/14 §7.1's `rng_town` row states the reason in the doc itself: "Otherwise
    # reloading rerolls the recruit list." The candidates are stored whole rather than
    # re-derived from the seed, because `_tavern_rng()` is a function of `day` and
    # `rerolls_since_run` and the board outlives both.
    var candidates := []
    for c in tavern_board:
        candidates.append(c.to_dict())
    return {
        "save_version": SAVE_VERSION,
        "guild_name": guild_name,
        "gold": gold,
        "day": day,
        "reputation_rank": Enums.reputation_key(reputation_rank),
        "reputation_points": reputation_points,
        # A 64-bit seed as a STRING: JSON has one number type, a float64, and
        # a splitmix64 seed loses its low bits through it (measured: a seed
        # came back 32 off after one save, and the replay was a different
        # fight). Every seed in the body is written this way; `_int64()` reads
        # either form, so a v16 save's number still loads.
        "guild_seed": str(guild_seed),
        "cleared": cleared.duplicate(true),
        "attempts": attempts.duplicate(true),
        "wipe_streaks": wipe_streaks.duplicate(true),
        "bullet_triggers": bullet_triggers.duplicate(true),
        "bullet_tier": bullet_tier,
        "legendary_warned": legendary_warned.duplicate(),
        "pending_loot": _pending_ids(),
        "crisis_strikes": crisis_strikes,
        "onboarding_complete": onboarding_complete,
        "skipped_tutorials": skipped_tutorials.duplicate(),
        "completed": completed,
        "completed_on_day": completed_on_day,
        "completion_seen": completion_seen,
        "gold_earned_lifetime": gold_earned_lifetime,
        "rp_earned_lifetime": rp_earned_lifetime,
        "items_sold_lifetime": items_sold_lifetime,
        "achievements_earned": achievements_earned.duplicate(),
        "achievements_claimed": achievements_claimed.duplicate(),
        "town_flags": town_flags.duplicate(),
        "facility_tier": facility_tier,
        "morale_ledger": morale_ledger.to_dict() if morale_ledger != null else {},
        "tier_bonus_awarded": tier_bonus_awarded.duplicate(),
        "furnishings": furnishings.duplicate(true),
        "guild_furnishings": guild_furnishings.duplicate(),
        "sold_recently": sold_recently.duplicate(),
        "consumables": consumables.duplicate(),
        "save_slot": save_slot,
        "autosave_index": autosave_index,
        "played_seconds": int(played_seconds),
        "save_counter": save_counter,
        "tavern_tier": tavern_tier,
        "market_tier": market_tier,
        "rerolls_since_run": rerolls_since_run,
        "tavern_board": candidates,
        "board_rolled": board_rolled,
        "recruit_pity": recruit_pity,
        "legendary_classes_found": legendary_classes_found.duplicate(),
        "trophy_witnesses": _trophy_witnesses.duplicate(),
        "stalled": stalled,
        "roster": raiders,
        "flags": flags.duplicate(true),
        # v17 — docs/14 §7.1's last four blocks. The format is frozen after these.
        "active_run": _with_seed_as_text(active_run, "master_seed"),
        "log_tail": _with_seed_as_text(log_tail, "seed"),
        "best_rounds": best_rounds.duplicate(true),
        "pending_deltas": pending_deltas(),
    }


## Restores state written by `to_dict()`. Returns an array of problems; an empty
## array means a clean load. A save from a NEWER version is refused rather than
## half-read, because a partially-applied save is worse than a refused one.
func from_dict(d: Dictionary) -> Array:
    var problems: Array[String] = []
    var version := int(d.get("save_version", 0))
    if version > SAVE_VERSION:
        return ["save is version %d; this build reads up to %d"
            % [version, SAVE_VERSION]]

    reset()
    # AUDIO-10: a restore is not a gold change. Cleared at the end, after the
    # two announcement emits.
    announcing = true
    guild_name = String(d.get("guild_name", ""))
    gold = int(d.get("gold", 0))
    # Zero, not `gold`: a save written before v15 never recorded what it earned,
    # and seeding the lifetime total from the balance that is LEFT would be an
    # invented figure dressed as a recovered one.
    gold_earned_lifetime = maxi(0, int(d.get("gold_earned_lifetime", 0)))
    rp_earned_lifetime = maxi(0, int(d.get("rp_earned_lifetime", 0)))
    items_sold_lifetime = maxi(0, int(d.get("items_sold_lifetime", 0)))
    var raw_earned = d.get("achievements_earned", {})
    if typeof(raw_earned) == TYPE_DICTIONARY:
        achievements_earned = (raw_earned as Dictionary).duplicate()
    var raw_claimed = d.get("achievements_claimed", [])
    if typeof(raw_claimed) == TYPE_ARRAY:
        for rid in (raw_claimed as Array):
            achievements_claimed.append(String(rid))
    var raw_town = d.get("town_flags", [])
    if typeof(raw_town) == TYPE_ARRAY:
        for fid in (raw_town as Array):
            town_flags.append(String(fid))
    day = maxi(1, int(d.get("day", 1)))
    reputation_points = int(d.get("reputation_points", 0))
    guild_seed = _int64(d.get("guild_seed", 0))
    var raw_cleared = d.get("cleared", {})
    if typeof(raw_cleared) == TYPE_DICTIONARY:
        cleared = raw_cleared.duplicate(true)
    var raw_attempts = d.get("attempts", {})
    if typeof(raw_attempts) == TYPE_DICTIONARY:
        attempts = raw_attempts.duplicate(true)

    # The v11 -> v12 step, and the whole of it. A v11 save carries none of the three
    # BIG-dumb fields, and `SaveGame.MIGRATIONS[11]` (`_v11_to_v12`) is a pure version
    # stamp by the same rule as 10: an added field "has no mapping to make", so the step
    # moves nothing and `from_dict` defaults every field it does not find. The defaults
    # are the honest mapping and docs/14 §7.3's rule holds — a
    # migration "may DROP a field, never guess a value". An absent `wipe_streaks` means
    # "we were not counting", which is exactly what a v11 save can tell us, and an empty
    # `legendary_warned` means the confirmation has not been shown, which is the safe
    # direction for a warning whose whole point is that it never surprises the player.
    var raw_streaks = d.get("wipe_streaks", {})
    if typeof(raw_streaks) == TYPE_DICTIONARY:
        wipe_streaks = _load_counter_table(raw_streaks)
    var raw_bullets = d.get("bullet_triggers", {})
    if typeof(raw_bullets) == TYPE_DICTIONARY:
        bullet_triggers = _load_counter_table(raw_bullets)
    bullet_tier = maxi(1, int(d.get("bullet_tier", 1)))
    legendary_warned = []
    for warned_id in d.get("legendary_warned", []):
        legendary_warned.append(String(warned_id))

    crisis_strikes = int(d.get("crisis_strikes", 0))
    onboarding_complete = bool(d.get("onboarding_complete", false))
    # The v12 -> v13 step, and the whole of it. A v12 save carries no skip list,
    # and an empty one is the honest reading: that guild never skipped anything,
    # because the skip did not exist. SaveGame's `_v12_to_v13` is a pure stamp —
    # registered so a hole in the chain is always a mistake and never a judgement
    # somebody once made — and `from_dict` defaults what it cannot find.
    skipped_tutorials = []
    var raw_skipped = d.get("skipped_tutorials", [])
    if typeof(raw_skipped) == TYPE_ARRAY:
        for skipped_id in raw_skipped:
            skipped_tutorials.append(String(skipped_id))
    stalled = bool(d.get("stalled", false))
    # v14. All three default to "this guild has not finished", which is exactly
    # what a save written before the ending existed means.
    completed = bool(d.get("completed", false))
    completed_on_day = int(d.get("completed_on_day", 0))
    completion_seen = bool(d.get("completion_seen", false))
    var raw_furnishings = d.get("furnishings", {})
    if typeof(raw_furnishings) == TYPE_DICTIONARY:
        furnishings = raw_furnishings.duplicate(true)
    guild_furnishings = []
    for gid in d.get("guild_furnishings", []):
        guild_furnishings.append(String(gid))
    sold_recently = []
    for sid in d.get("sold_recently", []):
        sold_recently.append(String(sid))
    var raw_consumables = d.get("consumables", {})
    if typeof(raw_consumables) == TYPE_DICTIONARY:
        consumables = raw_consumables.duplicate()
    save_slot = clampi(int(d.get("save_slot", 0)), 0, SaveGame.SLOTS - 1)
    autosave_index = maxi(0, int(d.get("autosave_index", 0)))
    played_seconds = float(d.get("played_seconds", 0))
    save_counter = maxi(0, int(d.get("save_counter", 0)))
    tavern_tier = clampi(int(d.get("tavern_tier", 1)), 1, Buildings.MAX_LEVEL)
    market_tier = clampi(int(d.get("market_tier", 1)), 1, Buildings.MAX_LEVEL)
    rerolls_since_run = maxi(0, int(d.get("rerolls_since_run", 0)))
    recruit_pity = maxi(0, int(d.get("recruit_pity", 0)))

    # The v10 -> v11 step, and the whole of it. A v10 save carries no board block at all,
    # and SaveGame's chain registers `10: _v10_to_v11` as a pure version stamp — its own
    # comment says an added field "has no mapping to make", so the step moves nothing and
    # `from_dict` defaults every field it does not find. (This comment once said the chain
    # had NO entry for 10; it always had one — audit M3-SAVE-06's correction.) The
    # defaults ARE the mapping here, and they are the honest one: `board_rolled` false
    # means "this guild has never rolled a board", which is exactly what a v10 save can
    # tell us, and the first look at the Tavern fills it just as it did before.
    board_rolled = bool(d.get("board_rolled", false))
    tavern_board = []
    for entry in d.get("tavern_board", []):
        if typeof(entry) != TYPE_DICTIONARY:
            problems.append("tavern candidate is not an object — skipped")
            continue
        var candidate_errors: Array = []
        var c = Raider.from_dict(entry, candidate_errors)
        for e in candidate_errors:
            problems.append("tavern candidate '%s': %s"
                % [String((entry as Dictionary).get("id", "?")), String(e)])
        if c == null:
            continue
        tavern_board.append(c)
    legendary_classes_found = []
    for cls in d.get("legendary_classes_found", []):
        legendary_classes_found.append(int(cls))
    var raw_witnesses = d.get("trophy_witnesses", {})
    if typeof(raw_witnesses) == TYPE_DICTIONARY:
        _trophy_witnesses = raw_witnesses.duplicate()
    tier_bonus_awarded = []
    for raw_tier in d.get("tier_bonus_awarded", []):
        tier_bonus_awarded.append(int(raw_tier))
    facility_tier = int(d.get("facility_tier", 0))
    var raw_ledger = d.get("morale_ledger", {})
    morale_ledger = MoraleLedger.from_dict(raw_ledger) \
        if typeof(raw_ledger) == TYPE_DICTIONARY else MoraleLedger.new()

    # Pending loot is saved as ids and re-resolved against the live content
    # tables, so a content edit can never leave a save holding a phantom item.
    pending_loot = []
    for raw_id in d.get("pending_loot", []):
        if content == null:
            problems.append("cannot restore pending loot before content loads")
            break
        var it = content.item(String(raw_id))
        if it == null:
            problems.append("pending loot item '%s' no longer exists" % String(raw_id))
            continue
        pending_loot.append(it)

    var rank_key := String(d.get("reputation_rank", ""))
    var rank := Enums.reputation_from_key(rank_key)
    if rank < 0:
        problems.append("unknown reputation rank '%s' — defaulted to Unknown" % rank_key)
        rank = STARTING_RANK
    reputation_rank = rank

    for entry in d.get("roster", []):
        if typeof(entry) != TYPE_DICTIONARY:
            problems.append("roster entry is not an object — skipped")
            continue
        var entry_errors: Array = []
        var r = Raider.from_dict(entry, entry_errors)
        for e in entry_errors:
            problems.append("roster entry '%s': %s"
                % [String(entry.get("id", "?")), String(e)])
        if r == null:
            continue
        roster.append(r)

    # An UNDECLARED flag id is dropped and reported. docs/14 §7.3's rule is that a
    # migration "may DROP a field, never guess a value", and a flag whose declaration has
    # gone is precisely a field with no sensible mapping — carrying it forward would let a
    # retired system be switched on by an old save.
    var raw_flags = d.get("flags", {})
    if typeof(raw_flags) == TYPE_DICTIONARY:
        flags = {}
        for flag_id in (raw_flags as Dictionary):
            var key := String(flag_id)
            if FLAG_DEFAULTS.has(key):
                flags[key] = bool((raw_flags as Dictionary)[flag_id])
            elif ONCE_FLAG_DEFAULTS.has(key):
                # A once-flag, coerced to its declared type (JSON's one number type).
                flags[key] = _coerce_like((raw_flags as Dictionary)[flag_id],
                    ONCE_FLAG_DEFAULTS[key])
            else:
                problems.append("flag '%s' is not declared (docs/14 §5.2) — dropped" % key)

    # v17 — the four blocks, each defaulting to "nothing pending" (`SaveGame._v16_to_v17`
    # is a stamp; an older save never wrote them and that IS the truthful reading).
    # `active_run` is kept only while it names a rung and says a report is owed;
    # `log_tail` and `best_rounds` are kept as written, ints coerced at the boundary.
    var raw_run = d.get("active_run", {})
    active_run = {}
    if typeof(raw_run) == TYPE_DICTIONARY and bool((raw_run as Dictionary).get("resolved", false)) \
            and not String((raw_run as Dictionary).get("encounter_id", "")).is_empty():
        var run: Dictionary = (raw_run as Dictionary).duplicate(true)
        run["master_seed"] = _int64(run.get("master_seed", 0))
        run["difficulty_mult"] = float(run.get("difficulty_mult", 1.0))
        run["ninja_pulled"] = String(run.get("ninja_pulled", ""))
        var ids: Array = []
        for rid in run.get("party_ids", []):
            ids.append(String(rid))
        run["party_ids"] = ids
        if typeof(run.get("party", [])) != TYPE_ARRAY:
            run["party"] = []
        var raw_loadout = run.get("loadout", {})
        run["loadout"] = _loadout_like(
            raw_loadout if typeof(raw_loadout) == TYPE_DICTIONARY else {})
        active_run = run
    var raw_tail = d.get("log_tail", {})
    log_tail = {}
    if typeof(raw_tail) == TYPE_DICTIONARY and not (raw_tail as Dictionary).is_empty():
        var tail: Dictionary = (raw_tail as Dictionary).duplicate(true)
        tail["seed"] = _int64(tail.get("seed", 0))
        tail["rounds"] = int(tail.get("rounds", 0))
        tail["payout"] = int(tail.get("payout", 0))
        tail["cleared"] = bool(tail.get("cleared", false))
        if typeof(tail.get("lines", [])) != TYPE_ARRAY:
            tail["lines"] = []
        if typeof(tail.get("loot_ids", [])) != TYPE_ARRAY:
            tail["loot_ids"] = []
        log_tail = tail
    var raw_best = d.get("best_rounds", {})
    best_rounds = {}
    if typeof(raw_best) == TYPE_DICTIONARY:
        for enc_id in (raw_best as Dictionary):
            var took: int = int((raw_best as Dictionary)[enc_id])
            if took > 0:
                best_rounds[String(enc_id)] = took
    var raw_pending = d.get("pending_deltas", [])
    _pending_departures = []
    if typeof(raw_pending) == TYPE_ARRAY:
        for gone in (raw_pending as Array):
            if typeof(gone) != TYPE_DICTIONARY:
                continue
            _pending_departures.append({
                "id": String((gone as Dictionary).get("id", "")),
                "class_id": int((gone as Dictionary).get("class_id", -1)),
            })

    # The roster exists now, so the derived comfort floors can be rebuilt from the
    # holdings. Recomputing rather than trusting the saved per-raider number means a
    # save can never disagree with itself about what the guild owns.
    _recompute_comfort()

    active = true
    _ensure_router_connected()
    gold_changed.emit(gold)
    roster_changed.emit()
    announcing = false
    return problems




# ------------------------------------------------- docs/02 §4.4: the record wall

## Notice anything the guild has just become entitled to, and write it down.
##
## `event` is the attempt being recorded, or {} for a plain re-check. The
## distinction is the whole design: `Achievements.EVENT_ONLY_KINDS` can only be
## decided while an attempt is in hand, and answer "not now" rather than "no"
## without one — so a re-check can never take an earned record away, and the
## persisted set is what remembers. Returns the ids that are new, for a caller
## that wants to say what just happened.
##
## Nothing is paid here. docs/14 OQ-10: the board REPORTS and `game/` acts, so
## earning is free and `claim_achievement()` is the hand that opens the purse.
func check_achievements(event: Dictionary = {}) -> Array:
    if not Achievements.is_valid():
        return []
    var fresh: Array = Achievements.evaluate(Achievements.snapshot(self), event)
    if fresh.is_empty():
        return []
    # The day the EVENT happened, not the day the check runs. An attempt is a Day
    # Tick (docs/05 §7), so by the time `record_attempt()` gets here the clock has
    # already moved — and a wall that said a guild cleared Adventure 0 on day 43
    # when the raid was on day 42 would be wrong in the one field the player reads
    # it for. Everything else has no event and is noticed today, which is true.
    var earned_on: int = int(event.get("day", day))
    for rid in fresh:
        achievements_earned[String(rid)] = earned_on
    achievements_changed.emit(fresh.duplicate())
    return fresh


## Take a record's reward. Returns "" on success, or the sentence to print.
##
## `Achievements.claim_grant()` decides WHAT is owed and whether the claim may
## proceed at all — already claimed, not earned, or docs/11 §11.2's coin cap
## reached. This is only the hand: it applies the grant and records the claim, and
## it refuses in exactly the words the board gave it, because docs/13 §7 forbids a
## refusal the player cannot read.
##
## The cap refusal is deliberately NOT a smaller payout. docs/11 §11.2 wants the
## board to never substitute for playing content, so the honest failure is "come
## back when you have earned more", which is a sentence, not a quieter purse.
func claim_achievement(achievement_id: String) -> String:
    var rid := String(achievement_id)
    # docs/15 Q-69, RULED: the record wall pays reputation. `achievement_rp` is the
    # switch (`FLAG_DEFAULTS`, true); off, `effective_reward()` pays the record's
    # type coin figure from docs/11 §11.2 instead — the recorded alternative.
    var grant: Dictionary = Achievements.claim_grant(
        rid, Achievements.snapshot(self), flag_enabled("achievement_rp"))
    var blocked := String(grant.get("blocked", ""))
    if not blocked.is_empty():
        return blocked

    var kind := String(grant.get("kind", "none"))
    var amount: int = int(grant.get("amount", 0))
    match kind:
        "coin":
            # Not income: see `add_gold()`. The board must not be able to raise
            # its own cap by paying out.
            add_gold(amount, false)
        "reputation":
            # Not EARNED reputation, for the same reason the coin is not income:
            # the board's RP cap is 15 % of `rp_earned_lifetime`, and a claim paid
            # into that figure would widen the ceiling it was paid under. The feed
            # line, the signal and the rank-up beat are `_gain_reputation`'s.
            _gain_reputation(amount, false)
        "furnishing":
            var fid := String(grant.get("furnishing_id", ""))
            if not fid.is_empty() and not guild_furnishings.has(fid):
                guild_furnishings.append(fid)
                _recompute_comfort()
                comfort_changed.emit()
        "town_flag":
            var tid := String(grant.get("flag_id", ""))
            if not tid.is_empty() and not town_flags.has(tid):
                town_flags.append(tid)
        "consumables":
            var sku := String(grant.get("consumable_id", ""))
            if not sku.is_empty():
                # Tier 1: docs/11 §11.2 names the bundle by its plain name and
                # prices no grade, so the board pays the grade every guild can
                # already buy rather than a tier nobody wrote down.
                var key := Consumables.stock_key(sku, 1)
                consumables[key] = mini(Consumables.STACK_CAP,
                    int(consumables.get(key, 0)) + maxi(0, amount))
                consumables_changed.emit()

    achievements_claimed.append(rid)
    autosave()
    return ""



## docs/14 §7.4's rotating autosave. Called at the moments that doc lists as "the moment
## most worth not losing" — a resolved encounter, a hire, a loot decision — and it takes
## the NEXT rotation slot each time so one bad state cannot overwrite the only copy.
##
## Returns "" or the reason it failed; a save that fails silently is worse than one that
## fails loudly, and every caller here surfaces it.
##
## It also re-checks the record wall first, and that is deliberate rather than a
## side effect smuggled into a save: docs/14 §7.4's list of save points IS the set
## of moments this campaign considers state-worthy — a hire, a loot decision, a
## resolved encounter — which is exactly the set of moments a snapshot-based
## record can newly become true. Checking here rather than at twenty mutation
## sites means a new record kind needs no new call, and running BEFORE the write
## means whatever was just earned is in the file. The event-only kinds are not
## served by this (they carry no event) and never were meant to be —
## `record_attempt()` hands them theirs.
func autosave() -> String:
    check_achievements()
    if not active:
        return ""
    var problem := SaveGame.autosave(save_slot, autosave_index, self)
    autosave_index = (autosave_index + 1) % SaveGame.AUTOSAVES_PER_SLOT
    # This is one of the moments a transition write must never overwrite, so the next run
    # of town transitions starts on a fresh entry rather than continuing onto this one.
    _transition_slot = -1
    last_save_problem = problem
    if problem.is_empty():
        autosaved.emit()
    return problem


## docs/14 §7.4's "Quit to menu / window close" row, which is the one write that has to be
## synchronous — the process is going away.
func save_now() -> String:
    if not active:
        return ""
    # SHIP-15: the manual write carries whatever was just earned, like every
    # other write does.
    check_achievements()
    return SaveGame.save_slot(save_slot, self)


func _pending_ids() -> Array:
    var out: Array = []
    for it in pending_loot:
        out.append(it.id)
    return out


## Read back a two-level `id -> {key: count}` table. JSON has one number type, so a saved
## 3 returns as 3.0 and `wipe_streak_of()`'s comparison against an int would be doing
## float arithmetic on a counter — this coerces once, at the boundary, rather than at
## every read site. A malformed inner value is dropped rather than trusted; a counter is
## the thing suspending a Legendary's morale floor, and a corrupt one must not.
func _load_counter_table(raw: Dictionary) -> Dictionary:
    var out: Dictionary = {}
    for outer in raw:
        var inner = raw[outer]
        if typeof(inner) != TYPE_DICTIONARY:
            continue
        var counts: Dictionary = {}
        for key in (inner as Dictionary):
            counts[String(key)] = int((inner as Dictionary)[key])
        if not counts.is_empty():
            out[String(outer)] = counts
    return out
