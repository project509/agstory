extends RefCounted
## Guild Reputation: the ladder, how it is earned, and what each rank gates.
##
## ✅ CANON: "Your guild has a single primary stat: **Guild Reputation**", it
## "determines what starts appearing around town", and "New Tiers can be unlocked
## by gaining reputations with the town." Canon names all six ranks and fixes
## Unknown as the start.
##
## What canon does NOT give, and docs/03 §6 says so in as many words: "no rate, no
## threshold, no currency, and no loss rule." RP is docs/03's implementation of
## canon's "single primary stat", and the six canon names are thresholds on it.
##
## THE ONE RULE WORTH READING TWICE — docs/03 §6.5's monotonic-rank rule: rank
## never decreases. Its reason is structural rather than generous: "reputation
## gates recruit quality, so a rank *loss* would hand a struggling player worse
## raiders — the exact death spiral named in §8. Making rank one-way removes that
## spiral's steepest edge by construction."
##
## Pure and deterministic: no Node, no RNG. Reputation is arithmetic.

const Enums = preload("res://sim/model/Enums.gd")

## docs/03 §6.4's thresholds, indexed by Enums.ReputationRank.
## docs/03 §9's tuning file. JSON rather than the `.tres` §9 used to propose, because
## docs/14 §5.1's deciding row is "readable by `sim/` without breaking §3" and
## `.tres` is not — it needs `ResourceLoader`, which `sim/` is forbidden to call.
## docs/15 Q-94's ".tres for tuning singletons" keeps the game/-side singletons
## §5.1 lists beside this one; it does not reach a table the pure sim reads. The
## reasoning in full, and the six schema divergences from §9's old fence, are
## docs/15 BL-81; §9's fence is the shipped shape now.
const DEFAULT_PATH := "res://data/reputation.json"



# ---------------------------------------------------------------- the tables

## Lazily loaded and cached by path. `_tables` is a plain Dictionary, which is
## also what docs/15 Q-94 asks tuning to be flattened to before it enters
## `SimInput` — with JSON the flattening step is the parse and there is no second
## representation to keep in step.
static var _tables: Dictionary = {}
static var _errors: Array[String] = []


## Reads and validates the file WITHOUT touching the cache, so a test or the
## §9.3 sweep can inspect a candidate table before deciding to install it.
## Returns `{"tables": Dictionary, "errors": Array[String]}`.
##
## Never crashes and never calls `push_error` — the policy `ContentDB` states at
## its own head: collect every problem and keep going, so one bad row does not
## hide the other five, and `game/` decides what a broken tuning file means.
static func read_tables(path: String = DEFAULT_PATH) -> Dictionary:
    var out: Dictionary = {}
    var errs: Array[String] = []
    if not FileAccess.file_exists(path):
        errs.append("reputation: %s is missing" % path)
        return {"tables": out, "errors": errs}
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(parsed) != TYPE_DICTIONARY:
        errs.append("reputation: %s is not a JSON object" % path)
        return {"tables": out, "errors": errs}
    out = normalize(parsed)
    errs.append_array(validate(out))
    return {"tables": out, "errors": errs}


## The shipped tables. Loads once; every accessor below goes through here.
static func tables() -> Dictionary:
    if _tables.is_empty():
        var result := read_tables(DEFAULT_PATH)
        _tables = result["tables"]
        _errors = result["errors"]
    return _tables


static func load_errors() -> Array[String]:
    tables()
    return _errors


static func is_valid() -> bool:
    return load_errors().is_empty()


## docs/14 §5.1's stated reason for choosing a plain-Dictionary format: "the sweep
## harness in §9.3 exists precisely to load *altered* tables thousands of times".
## This is that seam — an in-memory table, no disk, no file to write and delete.
## The caller owns restoring the shipped one with `reset_tables()`.
static func override_tables(d: Dictionary) -> void:
    _tables = normalize(d)
    _errors = validate(_tables)


static func reset_tables() -> void:
    _tables = {}
    _errors = [] as Array[String]


## JSON numbers arrive as whichever of int/float the parser felt like, and the
## `adventure_awards` keys arrive as the strings JSON object keys always are.
## Everything is cast once here so no accessor has to, and so an equality test
## against the literal these tables replaced compares like with like.
##
## Keys beginning with `_` are the file's provenance — JSON has no comments and
## these numbers are not defensible without their citations — and are dropped.
static func normalize(src: Dictionary) -> Dictionary:
    var out: Dictionary = {}
    for k in src:
        if String(k).begins_with("_"):
            continue
        out[k] = src[k]

    var ranks: Array = []
    for row in out.get("ranks", []):
        if typeof(row) != TYPE_DICTIONARY:
            continue
        var r: Dictionary = row
        ranks.append({
            "key": String(r.get("key", "")),
            "rp_threshold": int(r.get("rp_threshold", 0)),
            "find_weights": _ints(r.get("find_weights", [])),
            "max_raid_tier": int(r.get("max_raid_tier", 1)),
            "max_adventure": int(r.get("max_adventure", 1)),
            "sell_rate": float(r.get("sell_rate", 0.0)),
            "consumable_price": float(r.get("consumable_price", 1.0)),
            "stock_tier": int(r.get("stock_tier", 1)),
            "town_unlock": _unlock_items(r.get("town_unlock", [])),
            "market_stock": String(r.get("market_stock", "")),
        })
    out["ranks"] = ranks

    for key in ["raid_awards", "tutorial_awards"]:
        var pairs: Dictionary = {}
        for slot in out.get(key, {}):
            pairs[String(slot)] = _ints(out[key][slot])
        out[key] = pairs

    # Keyed by adventure TIER, so the JSON's string keys become the ints
    # `base_awards()` looks them up with.
    var adv: Dictionary = {}
    for tier in out.get("adventure_awards", {}):
        adv[int(String(tier))] = _ints(out["adventure_awards"][tier])
    out["adventure_awards"] = adv

    var rungs: Dictionary = {}
    for slot in out.get("rung_cumulative", {}):
        rungs[String(slot)] = _floats(out["rung_cumulative"][slot])
    out["rung_cumulative"] = rungs

    out["full_tier_bonus"] = _ints(out.get("full_tier_bonus", []))
    for key in ["repeat_halving_period", "stall_attempts", "pity_threshold",
            "pity_min_rank"]:
        out[key] = int(out.get(key, 0))
    for key in ["obsolescence_mult", "catchup_mult", "disband_rp_penalty"]:
        out[key] = float(out.get(key, 0.0))
    out["catchup_enabled"] = bool(out.get("catchup_enabled", false))
    return out


static func _ints(src) -> Array:
    var out: Array = []
    for v in (src as Array):
        out.append(int(v))
    return out


static func _floats(src) -> Array:
    var out: Array = []
    for v in (src as Array):
        out.append(float(v))
    return out


## A rank's `town_unlock` column as `[{building, text}]` — one item per thing
## the rank opens in town, each tagged with the docs/02 building id it belongs
## to (`""` for a line that is nobody's building). The file carries the column
## in that shape (M3-TUNE-05's split, W6-COPY); an older file's single prose
## string is read as one untagged item, so nothing that reads the column has
## to know which shape it was handed.
static func _unlock_items(src) -> Array:
    var out: Array = []
    if typeof(src) == TYPE_STRING:
        if not String(src).is_empty():
            out.append({"building": "", "text": String(src)})
        return out
    if typeof(src) != TYPE_ARRAY:
        return out
    for item in (src as Array):
        if typeof(item) == TYPE_DICTIONARY:
            out.append({
                "building": String((item as Dictionary).get("building", "")),
                "text": String((item as Dictionary).get("text", "")),
            })
        elif typeof(item) == TYPE_STRING and not String(item).is_empty():
            out.append({"building": "", "text": String(item)})
    return out


## docs/03 §9's three named load assertions, plus the one the build already
## depended on. §9 says of the third that it "guards C4 and C8 against a bad
## tuning pass" — canon's two "you no longer find" statements are the only thing
## stopping a retune from handing Common back at Renowned, and the doc asks for
## that guard here rather than in a review.
##
## Every failure is a collected row naming the rank, never a crash: a broken
## tuning file must fail one loud test, not take the suite down with it.
static func validate(d: Dictionary) -> Array[String]:
    var errs: Array[String] = []
    var ranks: Array = d.get("ranks", [])

    # The fourth assertion. The ladder's length is the enum's, not the file's:
    # a dropped row would silently shorten the ladder and every rank above the
    # gap would clamp to the wrong gate rather than fail.
    if ranks.size() != Enums.REPUTATION_KEYS.size():
        errs.append("reputation: %d rank rows, expected %d (one per canon rank)"
            % [ranks.size(), Enums.REPUTATION_KEYS.size()])

    var retired: Dictionary = {}   # rarity -> the rank that last carried it
    for i in ranks.size():
        var row: Dictionary = ranks[i]
        var who: String = row["key"] if not String(row["key"]).is_empty() \
            else "rank %d" % i
        if i < Enums.REPUTATION_KEYS.size() \
                and String(row["key"]) != String(Enums.REPUTATION_KEYS[i]):
            errs.append("reputation: row %d is '%s', expected '%s' — the ladder's order is the enum's"
                % [i, row["key"], Enums.REPUTATION_KEYS[i]])

        # docs/03 §5.2: "Integer weights per 1000 recruits generated. Rows sum
        # to 1000." A row that sums to anything else silently reweights every
        # rarity in it, because `pick_weighted` normalises by the total.
        var weights: Array = row["find_weights"]
        var total := 0
        for w in weights:
            total += int(w)
        if total != WEIGHT_TOTAL:
            errs.append("reputation: %s's find_weights sum to %d, not %d"
                % [who, total, WEIGHT_TOTAL])

        # docs/03 §6.4's thresholds, strictly increasing. Equal thresholds would
        # make a rank unreachable; a decreasing pair would make `rank_for_rp`
        # skip it entirely.
        if i > 0:
            var prev: int = int((ranks[i - 1] as Dictionary)["rp_threshold"])
            if int(row["rp_threshold"]) <= prev:
                errs.append("reputation: %s's threshold %d does not exceed %d"
                    % [who, int(row["rp_threshold"]), prev])

        for rarity in weights.size():
            var present: bool = int(weights[rarity]) > 0
            if present and retired.has(rarity):
                errs.append("reputation: %s reintroduces %s, retired at %s"
                    % [who, Enums.rarity_name_of(rarity),
                        String(retired[rarity])])
            elif not present and _seen_before(ranks, i, rarity):
                retired[rarity] = who
    return errs


## Whether a rarity appeared at any rank below this one — the "had at 0 after
## retiring it" half of §9's third assertion, which needs a rarity to have been
## present before its absence counts as a retirement rather than as not-yet.
static func _seen_before(ranks: Array, upto: int, rarity: int) -> bool:
    for j in upto:
        var w: Array = (ranks[j] as Dictionary)["find_weights"]
        if rarity < w.size() and int(w[rarity]) > 0:
            return true
    return false


# ---------------------------------------------------------------- the numbers

## docs/03 §5.2's per-mille denominator. This one stays a constant on purpose:
## "rows sum to 1000" is the matrix's *schema*, not a value to tune, and it is
## what `validate()` checks the file against.
const WEIGHT_TOTAL := 1000


## docs/03 §6.4's thresholds, indexed by Enums.ReputationRank.
static func thresholds() -> Array:
    var out: Array = []
    for row in tables().get("ranks", []):
        out.append(int((row as Dictionary)["rp_threshold"]))
    return out


## docs/03 §7's master gate row plus §5.2's weights row for one rank — §9's own
## shape, which puts everything a designer retunes about a rank in one block.
static func rank_row(rank: int) -> Dictionary:
    var ranks: Array = tables().get("ranks", [])
    if ranks.is_empty():
        return {}
    return ranks[clampi(rank, 0, ranks.size() - 1)]


## docs/03 §6.1's Tier 1 base awards: slot -> [first clear, repeat base]. These
## are TIER 1 bases and §6.2 multiplies them by the encounter's tier — Tier 3
## Encounter 5 pays 65 x 3.
static func raid_awards() -> Dictionary:
    return tables().get("raid_awards", {})


## docs/03 §6.1's "Full-tier clear bonus (all 5 in one lockout)", [first, repeat].
## Tier-scaled like the encounters it rewards: §6.4's pacing table prices Raid 3's
## "Enc 4, 5 + bonus" at 450, which is (35 + 65 + 50) x 3 exactly.
##
## A pair rather than §9's single `full_clear_bonus_base` because docs/15 BL-35
## ruled the bonus pays once per tier — canon has no lockout clock — and kept the
## repeat value in the table, "unused and documented, so the day a lockout clock
## lands the value is already sitting there".
static func full_tier_bonus_pair() -> Array:
    return tables().get("full_tier_bonus", [])


## docs/03 §6.1's per-adventure awards, keyed by adventure tier: [first, repeat].
##
## UNLIKE the raid table these are already tier-final and are NOT multiplied
## again. §6.4's pacing table is the proof: it prices Adventure 2 at 50 and
## Adventure 5 at 125 — the §6.1 numbers unchanged — while every raid row in the
## same table is multiplied (Raid 2 Enc 1-3 = 50 x 2 = 100). §6.1 labels the raid
## table "Tier 1 base awards" and gives the adventure table no such label, so the
## adventure curve is baked into the table and the tier factor would double-count
## it. docs/15 BL-37 records how nearly this went the other way.
static func adventure_awards() -> Dictionary:
    return tables().get("adventure_awards", {})


## docs/03 §6.1's tutorial awards. Single-encounter content, so no rung split.
## ✅ CANON makes tutorials skippable; §6.1's 🔷 PROPOSED consequence is that
## skipping forfeits the RP too — 15 RP total, "deliberately trivial".
static func tutorial_awards() -> Dictionary:
    return tables().get("tutorial_awards", {})


## docs/15 BL-24 makes one board rung one encounter, so an Adventure's single award
## splits across its three rungs. The shares are the ones the gold split already
## uses (docs/11 §F2 -> 4/6/10 of 20), so RP and gold rise together across a
## board rather than disagreeing about which rung is the payoff.
##
## Stored as cumulative shares and differenced in `_rung_award()`, which makes the
## three rungs sum to the doc's total EXACTLY at every adventure tier instead of
## losing a point to rounding: 25 -> 5/7/13, 50 -> 10/15/25, 75 -> 15/22/38.
static func rung_cumulative() -> Dictionary:
    return tables().get("rung_cumulative", {})


## docs/03 §6.3's "repeat payout halves every 5 repeats". §9 names this key and
## the code used to inline the 5, which made it the one documented lever with no
## home — extracting it adds a lever rather than moving one.
static func repeat_halving_period() -> int:
    return maxi(1, int(tables().get("repeat_halving_period", 5)))


## docs/03 §6.2: "0.25 if encounter_tier < highest_unlocked_tier - 1, else 1.0.
## Stops the player farming Raid 1 for Legendary rank."
static func obsolescence_factor() -> float:
    return float(tables().get("obsolescence_mult", 0.25))


## docs/03 §6.2's catch-up valve, "while the stall flag is set ... Applies to
## ADVENTURE content only."
static func catchup_factor() -> float:
    return float(tables().get("catchup_mult", 2.0))


## docs/03 §8.1's mitigation M3: the stall flag is set once the player has
## "attempted the same raid encounter 5+ times without clearing it".
##
## The literal is a MISSING-FILE fallback, not a second copy of the tuning value: it is
## reached only when `data/reputation.json` failed to load, in which case `is_valid()` is
## already false and `game/` decides what that means. Every other read comes from the
## file, and `test_no_tuning_number_exists_in_two_places_at_once` proves it.
static func stall_attempts() -> int:
    return int(tables().get("stall_attempts", 5))


## §8.1 says to "keep M3 behind a config flag and enable it if telemetry shows
## stalls". This IS that flag, and it ships ON — see docs/15 BL-36. There is no
## telemetry pipeline in an offline single-player game, so the real choice is
## between on and never; M3 can only ever *add* progress, and its trigger requires
## five recorded failures, so it cannot be gamed into a fast path.
static func catchup_enabled() -> bool:
    return bool(tables().get("catchup_enabled", true))


## docs/03 §8.1 M2's threshold, and the rank it switches on at: "Active from
## **Respected** onward, since Rare does not exist before then." Both halves live
## here because §5's matrix is the thing that decides them, and `Recruitment`
## reads them from here rather than keeping a second copy.
static func pity_threshold() -> int:
    return int(tables().get("pity_threshold", 25))


static func pity_min_rank() -> int:
    return int(tables().get("pity_min_rank", 2))


## docs/03 §6.5: a disband costs "-10% of RP earned inside the current rank,
## clamped to the rank floor". A fraction, not §9's `_pct`.
static func disband_rp_penalty() -> float:
    return float(tables().get("disband_rp_penalty", 0.10))


# ---------------------------------------------------------------- the ladder

## The rank an RP total reaches. Note this is the rank RP *earns*, not necessarily
## the rank a guild *holds*: §6.5's monotonic rule means a guild never drops below
## a rank it has held, so callers keep the higher of the two (see `rank_after()`).
static func rank_for_rp(rp: int) -> int:
    var rank := 0
    var t := thresholds()
    for i in t.size():
        if rp >= int(t[i]):
            rank = i
    return rank


## docs/03 §6.5's monotonic-rank rule in one place, so no caller can forget it.
static func rank_after(rp: int, held_rank: int) -> int:
    return maxi(held_rank, rank_for_rp(rp))


static func rp_floor(rank: int) -> int:
    var t := thresholds()
    if t.is_empty():
        return 0
    return int(t[clampi(rank, 0, t.size() - 1)])


## RP needed for the next rank, or -1 at the top of the ladder.
static func rp_for_next(rank: int) -> int:
    var t := thresholds()
    if rank >= t.size() - 1:
        return -1
    return int(t[rank + 1])


## Progress through the current rank, 0.0-1.0, for the desk strip's meter.
## Returns 1.0 at Legendary, which has no next rung to be partway toward.
static func progress_in_rank(rp: int, rank: int) -> float:
    var next_rp := rp_for_next(rank)
    if next_rp < 0:
        return 1.0
    var floor_rp := rp_floor(rank)
    var span := next_rp - floor_rp
    if span <= 0:
        return 1.0
    return clampf(float(rp - floor_rp) / float(span), 0.0, 1.0)


# ---------------------------------------------------------------- earning

static func is_raid_slot(slot: String) -> bool:
    return raid_awards().has(slot)


static func is_adventure_slot(slot: String) -> bool:
    return rung_cumulative().has(slot)


static func is_tutorial_slot(slot: String) -> bool:
    return tutorial_awards().has(slot)


## docs/03 §6.3:
##     repeat_rp(n) = max(1, floor(repeat_base / 2 ** floor((n - 2) / 5)))
##
## "Repeat payout halves every 5 repeats and floors at 1 RP — never zero, so a
## stuck player always inches forward." That floor is the catch-up valve, and the
## doc's own worked table for Encounter 5 (13 / 6 / 3 / 1 over clears 2-21) is a
## test rather than a comment.
static func repeat_rp(repeat_base: int, clear_number: int) -> int:
    if clear_number < 2:
        return repeat_base
    var halvings: int = int(floor(float(clear_number - 2)
        / float(repeat_halving_period())))
    var divisor: int = 1 << halvings
    return maxi(1, int(floor(float(repeat_base) / float(divisor))))


## docs/03 §6.2's obsolescence factor, which exists to stop "the player farming
## Raid 1 for Legendary rank".
static func obsolescence(encounter_tier: int, highest_unlocked_tier: int) -> float:
    if encounter_tier < highest_unlocked_tier - 1:
        return obsolescence_factor()
    return 1.0


## One rung's share of an adventure's award, differenced from cumulative shares so
## the three rungs always sum to the whole.
static func _rung_award(adventure_total: int, slot: String) -> int:
    var bounds: Array = rung_cumulative()[slot]
    var lo: int = int(floor(float(adventure_total) * float(bounds[0])))
    var hi: int = int(floor(float(adventure_total) * float(bounds[1])))
    return maxi(0, hi - lo)


## The [first clear, repeat base] pair an encounter is worth BEFORE §6.2's factors,
## or [0, 0] for content that grants no reputation.
static func base_awards(slot: String, tier: int) -> Array:
    var raids := raid_awards()
    if raids.has(slot):
        return raids[slot]
    var tutorials := tutorial_awards()
    if tutorials.has(slot):
        return tutorials[slot]
    var adventures := adventure_awards()
    if rung_cumulative().has(slot) and adventures.has(tier):
        var whole: Array = adventures[tier]
        return [_rung_award(int(whole[0]), slot), _rung_award(int(whole[1]), slot)]
    return [0, 0]


## docs/03 §6.2's formula:
##     award = base_award x encounter_tier x obsolescence x catchup x repeat_decay
##
## `clear_number` counts from 1, so a first clear pays the first-clear column and
## anything later goes through §6.3's decay. `stalled` is §8's catch-up flag, which
## the doc restricts to adventure content. The tier factor is raid-only — see the
## note on `adventure_awards()` for why, and §6.4's pacing table for the proof.
static func award_for(encounter, clear_number: int, highest_unlocked_tier: int = 1,
        stalled: bool = false) -> int:
    if encounter == null:
        return 0
    var tier := maxi(1, int(encounter.tier))
    var slot := String(encounter.slot)
    var pair := base_awards(slot, tier)
    if int(pair[0]) == 0 and int(pair[1]) == 0:
        return 0

    var base: float = float(pair[0]) if clear_number <= 1 \
        else float(repeat_rp(int(pair[1]), clear_number))
    var scale := float(tier) if is_raid_slot(slot) else 1.0
    var factor := obsolescence(tier, highest_unlocked_tier)
    var catchup := 1.0
    if stalled and not is_raid_slot(slot):
        catchup = catchup_factor()
    return maxi(0, int(floor(base * scale * factor * catchup)))


## docs/03 §6.1's full-tier bonus, "all 5 in one lockout".
static func full_tier_bonus(tier: int, first_time: bool,
        highest_unlocked_tier: int = 1) -> int:
    var t := maxi(1, tier)
    var pair := full_tier_bonus_pair()
    if pair.size() < 2:
        return 0
    var base: int = int(pair[0]) if first_time else int(pair[1])
    return maxi(0, int(floor(float(base) * float(t)
        * obsolescence(t, highest_unlocked_tier))))


## Whether a tier's five raid encounters are all cleared, given that tier's cleared
## slots. The caller owns the clear counts (docs/03 §6.1's bonus is "all 5 in one
## lockout"), so this only answers the question about the set it is handed.
static func tier_complete(cleared_slots: Array) -> bool:
    for s in raid_awards():
        if not cleared_slots.has(s):
            return false
    return true


# ---------------------------------------------------------------- losing it

## docs/03 §6.5's table, in one function. Every failure event pays 0 except a guild
## disband, and the reasons are the point:
##
##   raid wipe            0 — "The game is named after wiping ... taxing the
##                            fantasy is a design error"
##   a raider leaves      0 — "Already punished by losing the raider and their gear"
##   abandoning a raid    0 — "Encourages retreating instead of feeding a wipe"
##   dismissing a raider  0 — "Roster churn is a core verb"
##   a guild disband      -10% of RP earned INSIDE the current rank, floor-clamped
static func rp_after_disband(rp: int, rank: int) -> int:
    var floor_rp := rp_floor(rank)
    var earned_in_rank := maxi(0, rp - floor_rp)
    var penalty := int(floor(float(earned_in_rank) * disband_rp_penalty()))
    # Clamped to the rank floor: a disband can never demote (§6.5).
    return maxi(floor_rp, rp - penalty)


# ---------------------------------------------------------------- gates

## docs/03 §7's master gate row for a rank. Now the same row `rank_row()` returns:
## §9's shape puts the gate columns and §5.2's weights in one block per rank, and
## keeping two names for one row would be the first step back to two tables.
static func gates_for(rank: int) -> Dictionary:
    return rank_row(rank)


## Which raider rarities the Tavern offers at this rank. docs/03 §7 marks this
## column ✅ CANON per §5.3 — canon describes the pool at four of the six ranks
## directly, and §7 marks the two it does not (Established, Legendary) 🔷 PROPOSED.
##
## DERIVED from §5.2's weights rather than tabled beside them. It used to be a
## hardcoded `match`, which made §7's column a second copy of §5.1's matrix and
## made §9's third load assertion guard the copy instead of the original: a
## retune that zeroed a weight would leave the column claiming the rarity still
## appears. The nonzero cells of a rank's row ARE the tiers found at it, so the
## column is that and nothing else. A test asserts the derivation reproduces the
## canon column at all six ranks.
static func recruit_tiers(rank: int) -> Array:
    var out: Array = []
    var weights: Array = rank_row(rank).get("find_weights", [])
    for rarity in weights.size():
        if int(weights[rarity]) > 0:
            out.append(rarity)
    return out


## docs/03 §7's Market-stock rung as a number, which docs/15 BL-44/BL-54 rule the
## RANK owns — "six ranks over six potion tiers is exact, so the rank owns the
## potion tier" — while the stall level bought in town owns the comfort shelf.
## `Consumables.top_potion_tier()` computes the same rung as `rank + 1`; a test
## asserts the two agree rather than assuming it, the way §7's sell-rate ladder
## and `Economy.SELL_RATE` already are.
static func market_stock_tier(rank: int) -> int:
    return int(rank_row(rank).get("stock_tier", 1))


static func sell_rate(rank: int) -> float:
    return float(rank_row(rank).get("sell_rate", 0.0))


static func consumable_price_multiplier(rank: int) -> float:
    return float(rank_row(rank).get("consumable_price", 1.0))


## The highest raid tier this rank unlocks. Implements ✅ CANON "New Tiers can be
## unlocked by gaining reputations with the town."
static func max_raid_tier(rank: int) -> int:
    return int(rank_row(rank).get("max_raid_tier", 1))


static func max_adventure(rank: int) -> int:
    return int(rank_row(rank).get("max_adventure", 1))


## §7's Town-unlock column as the prose §7 prints — the row's items joined, so
## "Guildhall facility upgrade I; Quest board" reads as the doc wrote it.
##
## The column is structured now (W6-COPY, after M3-TUNE-05's shape): each item
## carries the docs/02 building id it opens, which BL-81 deferred until "the
## town screen turns out to want ids". It does — see `town_unlock_for_build`.
## The ids are docs/02 §2.3's five, not an invention: every §7 line names one
## of them or none.
static func town_unlock(rank: int) -> String:
    return _join_unlocks(town_unlock_items(rank))


## The row's items, `[{building, text}]`, unfiltered.
static func town_unlock_items(rank: int) -> Array:
    var items = rank_row(rank).get("town_unlock", [])
    return items if items is Array else []


## §7's Town-unlock column as THIS BUILD can keep it (LOOP-06, CRITIC-C4).
## `flags` maps a building id to whether its feature flag is on; an item whose
## building is in the map and off is dropped, so a promise never names a
## building the executable does not contain (docs/14 §5.2 — completable with
## every flag off — includes "and honest with every flag off"). A building
## with no flag in the map is always kept. "" when nothing at that rank
## survives the filter; the caller says what a rank always buys.
static func town_unlock_for_build(rank: int, flags: Dictionary) -> String:
    var kept: Array = []
    for item in town_unlock_items(rank):
        var building := String(item.get("building", ""))
        if not building.is_empty() and flags.has(building) and not bool(flags[building]):
            continue
        kept.append(item)
    return _join_unlocks(kept)


static func _join_unlocks(items: Array) -> String:
    var texts: Array = []
    for item in items:
        var text := String(item.get("text", ""))
        if not text.is_empty():
            texts.append(text)
    return "; ".join(PackedStringArray(texts))


static func market_stock(rank: int) -> String:
    return String(rank_row(rank).get("market_stock", ""))


## Whether an encounter's content is open at this rank, independent of whether the
## rung before it has been cleared. Both gates apply: reputation opens the TIER,
## and the board's own ladder orders the rungs inside it. Tutorials are never
## reputation-gated — they are the first thing a new guild does.
static func content_unlocked(encounter, rank: int) -> bool:
    if encounter == null:
        return false
    var slot := String(encounter.slot)
    if is_tutorial_slot(slot):
        return true
    var tier := int(encounter.tier)
    if is_raid_slot(slot):
        return tier <= max_raid_tier(rank)
    return tier <= max_adventure(rank)


# ================================================ deprecated compatibility aliases
#
# NOT a second copy: both are DERIVED from `data/reputation.json` through the accessors
# above, so a designer's edit moves them and they cannot drift. Before this they were
# `const` literals, and the comment beside them claimed "a test in test_reputation.gd
# asserts the shipped file agrees with these two" — no such test existed, and
# `grep -rn "stall_attempts\|catchup_enabled" tests/` returned nothing at all.
#
# They survive only because `game/core/GameState.gd:895,898` reads both by name and this
# wave does not own that file. Audit `M3-TUNE-04` owns the two-line edit that re-points it
# at `Reputation.catchup_enabled()` / `Reputation.stall_attempts()`; delete this block the
# day it lands. (This used to cite a `build/plan/` handoff that was never written.)
#
# Declared LAST because static initialisers run in declaration order and these call
# `tables()`, which needs `_tables` and `_errors` initialised first.

static var STALL_ATTEMPTS: int = stall_attempts()
static var CATCHUP_ENABLED: bool = catchup_enabled()
