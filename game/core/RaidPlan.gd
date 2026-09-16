extends RefCounted
## The four things raid prep must show without any interaction (docs/13 §10.2).
##
## This is deliberately separate from the screen. docs/13 §10 calls raid prep
## "the screen that carries the game", and what carries it is arithmetic the
## player is trusted with — comp shortfalls, gear coverage and an expected
## mistake count. Keeping that arithmetic out of the UI means it can be tested
## against docs/06 §6.5's worked example directly, which a Control cannot be.
##
## docs/13 §10.4 is a list of things this screen must NOT do, and two of them
## are enforced here rather than in the layout:
##   - **Never block Depart on an invalid comp.** docs/06 §6.6: "Penalties
##     teach; locks do not." `analyse()` returns warnings, never a veto.
##   - **No single gear score.** Canon's itemization is a family-sharing matrix
##     where a Mage's +17 Mana and a Warrior's 15 AC are not commensurable, so
##     one number would be a weighted guess wearing false authority. Coverage
##     plus raw stat sums cannot lie.

const Enums = preload("res://sim/model/Enums.gd")
const Formulas = preload("res://sim/core/Formulas.gd")
const Morale = preload("res://sim/core/Morale.gd")
const Reputation = preload("res://sim/core/Reputation.gd")

## docs/06 §6.5 defaults, used when an encounter does not state its own.
const DEFAULT_TANKS_REQUIRED := 2
const DEFAULT_HEALERS_RECOMMENDED := 3

## docs/10 §3: an Adventure fields SIX, not twelve, and canon fixes 12 for raids
## only. Every "how many slots" question therefore has to ask the encounter, not
## the rulebook — sending twelve on a six-person Adventure doubles the party DPS
## the HP in docs/08 §9.1a was derived against.
static func party_size(encounter) -> int:
    if encounter != null and encounter.party_size > 0:
        return encounter.party_size
    return Enums.RAID_SIZE


## Healers scale with the party. docs/06 §6.5 recommends 3 for a raid of 12 (one
## per four), and flooring that ratio at a six-party gives ONE — which is exactly
## the assumption docs/10 §8 used to derive A3's healing requirement and the one
## docs/15 BL-29 held constant when it rescaled the raid-wide magnitude. Rounding
## up to 2 instead would quietly contradict both.
static func healers_recommended(encounter) -> int:
    var size := party_size(encounter)
    if size >= Enums.RAID_SIZE:
        return DEFAULT_HEALERS_RECOMMENDED
    return maxi(1, int(floor(float(DEFAULT_HEALERS_RECOMMENDED)
        * float(size) / float(Enums.RAID_SIZE))))

## docs/06 §6.5: "+5 percentage points per full point of S" of tank shortfall.
const TANK_SHORTFALL_MISTAKE_BP := 500

## docs/06 §6.5: "-25% to all raid healing per missing healer, capped at -75%".
const HEALER_PENALTY_PER_MISSING := 0.25
const HEALER_PENALTY_CAP := 0.75

## The morale every raider is held at to compute the comparison figure.
## docs/13 §10.3: "the same figure with every raider at band 5 Content. This is
## what makes 4.6 mean something."
const CONTENT_MORALE := 55

## Sites each raider rolls every round. The sim rolls ACTION on a raider's turn
## and AMBIENT as colour; MECHANIC fires only on mechanic rounds and is counted
## separately below, so this stays an honest per-round figure rather than a
## worst case dressed as an average.
const PER_ROUND_SITES := [Enums.RollSite.ACTION, Enums.RollSite.AMBIENT]

## 🔷 PROPOSED — docs/13 §10.3 requires the words LOW / ELEVATED / SEVERE but
## does not set their thresholds. These are expressed as a RATIO against the
## same comp at Content, so the words describe *what morale is costing you*
## rather than how big the fight is. Recorded as docs/15 BL-25.
const ELEVATED_RATIO := 1.25
const SEVERE_RATIO := 2.00


# ---------------------------------------------------------------- comp

## Tank weight per docs/06 §6.2: in practice, Warriors. A Monk contributes 0
## outside its emergency state, which is why this counts role GROUP and not
## "can this class hold a boss for one round".
static func tank_weight(chalked: Array, db) -> float:
    var w := 0.0
    for r in chalked:
        if db != null and r.role_group(db) == Enums.RoleGroup.TANK:
            w += 1.0
    return w


static func count_group(chalked: Array, db, group: int) -> int:
    var n := 0
    for r in chalked:
        if db != null and r.role_group(db) == group:
            n += 1
    return n


static func tanks_required(encounter) -> int:
    if encounter != null and encounter.tanks_required > 0:
        return encounter.tanks_required
    return DEFAULT_TANKS_REQUIRED


# ---------------------------------------------------------------- gear

## docs/13 §10.2: coverage is filled over VISIBLE slots — seven per raider, six
## for Monk / Mage / Wizard whose off-hand is hidden rather than empty, and the
## denominator tracks who is actually chalked.
static func gear_coverage(chalked: Array, db) -> Dictionary:
    var filled := 0
    var visible := 0
    for r in chalked:
        filled += r.equipment.size()
        var cd = db.class_by_key(r.class_key()) if db != null else null
        visible += cd.available_slots().size() if cd != null \
            else Enums.all_slots().size()
    return {"filled": filled, "visible": visible}


## Summed AC / Damage / Mana. Three numbers, never one.
static func gear_totals(chalked: Array, db) -> Dictionary:
    var ac := 0
    var damage := 0
    var mana := 0
    for r in chalked:
        if db == null:
            continue
        var s = r.gear_stats(db)
        ac += s.ac
        damage += s.damage
        mana += s.mana
    return {"ac": ac, "damage": damage, "mana": mana}


## The highest gear tier anyone chalked is standing in, in docs/13 §9.1 notation.
static func gear_label(chalked: Array, db) -> String:
    if db == null:
        return "Gear"
    var best := "Start"
    for r in chalked:
        for it in r.equipped_items(db):
            if it.source == "raid":
                return "T1R"
            if it.source == "adventure":
                best = "T1A"
    return best


# ---------------------------------------------------------------- risk

## One raider's expected mistakes per round, summed across the sites they roll.
static func per_round_chance(r, situational_bp: int = 0) -> float:
    var total := 0.0
    for site in PER_ROUND_SITES:
        total += float(Formulas.mistake_chance_at_site_bp(
            r.rarity, r.morale, site, situational_bp)) / 10000.0
    return total


## Same, with the raider held at Content — the comparison figure.
static func per_round_chance_at_content(r, situational_bp: int = 0) -> float:
    var total := 0.0
    for site in PER_ROUND_SITES:
        total += float(Formulas.mistake_chance_at_site_bp(
            r.rarity, CONTENT_MORALE, site, situational_bp)) / 10000.0
    return total


static func rounds_for(encounter) -> int:
    if encounter != null and encounter.target_rounds > 0:
        return encounter.target_rounds
    return 1


## docs/13 §10.3's headline: expected mistakes per encounter.
static func expected_mistakes(chalked: Array, encounter,
        situational_bp: int = 0) -> float:
    var per_round := 0.0
    for r in chalked:
        per_round += per_round_chance(r, situational_bp)
    return per_round * float(rounds_for(encounter))


static func baseline_mistakes(chalked: Array, encounter,
        situational_bp: int = 0) -> float:
    var per_round := 0.0
    for r in chalked:
        per_round += per_round_chance_at_content(r, situational_bp)
    return per_round * float(rounds_for(encounter))


## LOW / ELEVATED / SEVERE, as a ratio against the same comp at Content.
static func risk_word(expected: float, baseline: float) -> String:
    if baseline <= 0.0:
        return "LOW"
    var ratio := expected / baseline
    if ratio >= SEVERE_RATIO:
        return "SEVERE"
    if ratio >= ELEVATED_RATIO:
        return "ELEVATED"
    return "LOW"


## How full the risk meter is, 0.0 at baseline (or below it) and 1.0 at the
## SEVERE ratio — the one density both the typed hatch and the drawn one read
## (UI-17), so the log's text and the screen's stripes can never disagree.
static func risk_fill(expected: float, baseline: float) -> float:
    var ratio := 1.0 if baseline <= 0.0 else expected / baseline
    return clampf((ratio - 1.0) / (SEVERE_RATIO - 1.0), 0.0, 1.0)


## docs/13 §10.3: "a word AND a hatch density, never colour alone." The hatch is
## what keeps the readout legible in the greyscale screenshot test (§13). The
## screen draws its stripes from `risk_fill` (W7-PREP); this text stays for the
## log and the tests.
static func risk_hatch(expected: float, baseline: float, width: int = 24) -> String:
    var filled := clampi(int(round(float(width) * risk_fill(expected, baseline))),
        0, width)
    return "/".repeat(filled) + ".".repeat(width - filled)


## LOOP-08: the one number a player can act on. Not the per-encounter total
## (a Ready twelve still reads "~44 mistakes" on a 22-round raid) but what
## MORALE is costing tonight — expected less the same comp at Content, so a
## content guild reads +0.0 and a happier one reads under zero.
static func risk_delta(expected: float, baseline: float) -> float:
    return expected - baseline


## The delta as the callout prints it: always signed, one decimal, a real
## minus sign (U+2212) rather than a hyphen so "−3.2" reads as a number and
## not a dash. "+0.0" for a delta that rounds to nothing either way.
static func signed(delta: float) -> String:
    var body := "%.1f" % absf(delta)
    if delta < 0.0 and body != "0.0":
        return "−" + body
    return "+" + body


## Top contributors by how much each raider costs ABOVE their own Content
## figure. docs/13 §10.3: "this is what turns a number into a decision about a
## person" — so the excess is attributed, not the raw chance, or every Common
## would top the list simply for being Common.
static func contributors(chalked: Array, encounter, limit: int = 3,
        situational_bp: int = 0) -> Array:
    var rounds := float(rounds_for(encounter))
    var rows: Array = []
    for r in chalked:
        var excess := (per_round_chance(r, situational_bp)
            - per_round_chance_at_content(r, situational_bp)) * rounds
        if excess <= 0.0001:
            continue
        rows.append({
            "id": r.id,
            "name": r.display_name,
            "class_name": Enums.class_name_of(r.class_id),
            "state": r.morale_band_name(),
            "morale": r.morale,
            "excess": excess,
        })
    rows.sort_custom(func(a, b) -> bool:
        return float(a["excess"]) > float(b["excess"]))
    return rows.slice(0, mini(limit, rows.size()))


# ---------------------------------------------------------------- verdict

## docs/06 §6.5's Comp Preview verdict word. "The player is allowed to lose;
## they are not allowed to be surprised that they lost."
static func verdict(tank_shortfall: float, healer_shortfall: int,
        slots_missing: int, risk: String) -> String:
    var trouble := 0
    if tank_shortfall > 0.0:
        trouble += int(ceil(tank_shortfall))
    if healer_shortfall > 0:
        trouble += healer_shortfall
    if slots_missing > 0:
        trouble += 1
    if risk == "SEVERE":
        trouble += 2
    elif risk == "ELEVATED":
        trouble += 1

    if trouble == 0:
        return "Ready"
    if trouble == 1:
        return "Risky"
    if trouble <= 3:
        return "Reckless"
    return "Suicidal"


# ---------------------------------------------------------------- the readout

## Everything raid prep shows, in one call. Never returns a veto: docs/06 §6.6
## forbids a hard comp gate anywhere in the game.
static func analyse(chalked: Array, db, encounter) -> Dictionary:
    var required := tanks_required(encounter)
    var tw := tank_weight(chalked, db)
    var tank_short: float = maxf(0.0, float(required) - tw)

    var recommended := healers_recommended(encounter)
    var healers := count_group(chalked, db, Enums.RoleGroup.HEALER)
    var healer_short: int = maxi(0, recommended - healers)

    var required_slots := party_size(encounter)
    var slots_missing: int = maxi(0, required_slots - chalked.size())

    var expected := expected_mistakes(chalked, encounter)
    var baseline := baseline_mistakes(chalked, encounter)
    var risk := risk_word(expected, baseline)

    var cover := gear_coverage(chalked, db)
    var totals := gear_totals(chalked, db)

    var warnings: Array[String] = []
    if tank_short > 0.0:
        warnings.append(("One tank short: %d loose boss attack(s) per round, "
            + "+%d%% mistakes, and nobody is watching the tank.")
            % [int(ceil(tank_short)),
               int(tank_short) * TANK_SHORTFALL_MISTAKE_BP / 100])
    if healer_short > 0:
        warnings.append("%d healer(s) short: %d%% less raid healing."
            % [healer_short, int(round(healing_penalty(healer_short) * 100.0))])
    if slots_missing > 0:
        warnings.append("%d empty slot(s). The missing bodies are the penalty."
            % slots_missing)
    for c in contributors(chalked, encounter, 1):
        if risk != "LOW":
            warnings.append("%s is %s and will cost you about %.1f extra mistakes."
                % [c["name"], String(c["state"]).to_lower(), float(c["excess"])])

    return {
        "slots_filled": chalked.size(),
        "slots_required": required_slots,
        "slots_missing": slots_missing,
        "tank_weight": tw,
        "tanks_required": required,
        "tank_shortfall": tank_short,
        "tank_mistake_bp": int(tank_short) * TANK_SHORTFALL_MISTAKE_BP,
        "healers": healers,
        "healers_recommended": recommended,
        "healer_shortfall": healer_short,
        "healing_penalty": healing_penalty(healer_short),
        "dps": count_group(chalked, db, Enums.RoleGroup.DPS),
        "support": count_group(chalked, db, Enums.RoleGroup.SUPPORT),
        "gear_label": gear_label(chalked, db),
        "gear_filled": int(cover["filled"]),
        "gear_visible": int(cover["visible"]),
        "sum_ac": int(totals["ac"]),
        "sum_damage": int(totals["damage"]),
        "sum_mana": int(totals["mana"]),
        "expected_mistakes": expected,
        "baseline_mistakes": baseline,
        "risk_word": risk,
        "risk_hatch": risk_hatch(expected, baseline),
        "risk_fill": risk_fill(expected, baseline),
        "risk_delta": risk_delta(expected, baseline),
        "risk_delta_text": signed(risk_delta(expected, baseline)),
        "contributors": contributors(chalked, encounter),
        "verdict": verdict(tank_short, healer_short, slots_missing, risk),
        "warnings": warnings,
        "at_risk": _at_risk_count(chalked),
    }


## docs/06 §6.5: -25% per missing healer, capped at -75%.
static func healing_penalty(healer_shortfall: int) -> float:
    return minf(HEALER_PENALTY_CAP,
        float(maxi(0, healer_shortfall)) * HEALER_PENALTY_PER_MISSING)


static func _at_risk_count(chalked: Array) -> int:
    var n := 0
    for r in chalked:
        if Morale.is_at_risk(r.morale):
            n += 1
    return n


# ---------------------------------------------------------------- the ladder

## TWO DOCS DISAGREE about what a skipped tutorial does to the board, so this is
## a named switch rather than a silent pick.
##   false — docs/01 §8.3 and docs/15 Q-90: "Skip is permanent — the mission
##           leaves the board and the reward is gone."
##   true  — docs/10 §9.3: "a skipped tutorial stays on the board and is
##           replayable for gold, but its trinket is gone for the run."
## Defaulted to the register's answer, because the register is this project's
## tie-break and docs/10 §9.3 marks its own row 🔷 PROPOSED.
##
## It lives HERE rather than on the Adventure's Board because the ladder does:
## the screen that draws the board and the harness that walks it must read one
## switch, or a run could be proved completable under a rule the game does not
## use (audit M6-PLAY-01).
const SKIPPED_TUTORIAL_STAYS_ON_BOARD := false


## Every mission this guild can see, in the order canon puts them in.
##
## EXTRACTED FROM THE SCREEN, and that is the point: `tools/playtest.gd` walks
## this ladder and `game/screens/AdventureBoard.gd` draws it, and a harness that
## proved a DIFFERENT ladder completable would prove nothing about the game. One
## implementation, two callers.
##
## Canon's own order (raw notes, *Adventure's Board*): "Adventure 0 … Adventure
## 1 …", so the two tutorials are the first rungs, ahead of A1. Only Tier 1 has
## them; every other tier answers empty, so this needs no tier test. Tiers come
## from the RANK rather than from a hardcoded 1 (✅ CANON: "New Tiers can be
## unlocked by gaining reputations with the town"), so the day Tier 2 ships it
## appears here on its own.
static func ladder(state) -> Array:
    if state == null or state.content == null:
        return []
    var out: Array = []
    for tier in range(1, int(state.highest_unlocked_tier()) + 1):
        for tut in state.content.tutorial_encounters(tier):
            if not SKIPPED_TUTORIAL_STAYS_ON_BOARD \
                    and state.skipped_tutorials.has(String(tut.id)):
                continue
            out.append(tut)
        out.append_array(state.content.adventure_encounters(tier))
        out.append_array(state.content.raid_encounters(tier))
    return out


## Why `encounter` cannot be attempted yet, or "" when it can.
##
## RESOLVED, not cleared. Canon lets the player skip the tutorials, and a gate
## that only counted clears would make "skip" mean "soft-lock the campaign" —
## every rung behind a skipped Adventure 0 would ask forever for a clear the
## board no longer offers.
##
## The sentence names the rung by its DISPLAY name ("Clear Adventure 0 first."),
## never by its slot code (LOOP-03): "A0", "TR" and "E1" are data keys a new
## player has never been told the meaning of, and this is the first sentence a
## blocked player reads. The slot stays on the rung Button's own text, where
## the loop test presses it by fragment.
static func locked_reason(state, encounter) -> String:
    if state == null:
        return "No guild loaded."
    if encounter == null:
        return "No mission selected."
    if not Reputation.content_unlocked(encounter, int(state.reputation_rank)):
        return "Your guild is not known enough for tier %d work yet." % int(encounter.tier)
    for other in ladder(state):
        if String(other.id) == String(encounter.id):
            return ""
        if not state.rung_resolved(String(other.id)):
            return "Clear %s first." % String(other.display_name)
    return ""


## The next rung the guild may attempt, or null when the ladder is walked out.
## The campaign is strictly ordered, so this is simply the first unresolved rung
## — and saying it in one place is what lets a harness walk the real campaign
## rather than a reimplementation of it.
static func next_open_mission(state):
    for e in ladder(state):
        if not state.rung_resolved(String(e.id)) and locked_reason(state, e).is_empty():
            return e
    return null


# ---------------------------------------------------------------- the party

## The twelve (or six) a reasonable guild leader would chalk, which is what the
## prep screen opens with and what the playtest harness sends.
##
## Highest morale first, because that is the default worth ARGUING with — docs/13
## §10.4 forbids the screen reordering the chalked party after this point, and
## seeding the opening state is not the same thing.
##
## A tutorial gets a PRE-MADE squad instead (docs/10 §9.1 calls both tutorial
## parties pre-made, and it matters: the Tutorial Raid's whole teaching payload is
## M01 Tank Swap, which a squad with no tank cannot be taught by). Nothing in the
## shape is invented — it is read off the encounter's own `tanks_required` and
## docs/10 §3's healer recommendation, both already here.
static func suggest_party(state, encounter, db = null) -> Array:
    if state == null or encounter == null:
        return []
    var pool: Array = (state.roster as Array).duplicate()
    pool.sort_custom(func(a, b) -> bool: return a.morale > b.morale)
    var cap: int = party_size(encounter)
    if not Reputation.is_tutorial_slot(String(encounter.slot)):
        return pool.slice(0, mini(cap, pool.size()))

    var content = db if db != null else state.content
    var picked: Array = []
    var taken := {}
    var want := {
        Enums.RoleGroup.TANK: tanks_required(encounter),
        Enums.RoleGroup.HEALER: healers_recommended(encounter),
    }
    for group in [Enums.RoleGroup.TANK, Enums.RoleGroup.HEALER]:
        for r in pool:
            if picked.size() >= cap or int(want[group]) <= 0:
                break
            if taken.has(r.id) or _role_group_of(content, r) != group:
                continue
            picked.append(r)
            taken[r.id] = true
            want[group] = int(want[group]) - 1
    for r in pool:
        if picked.size() >= cap:
            break
        if not taken.has(r.id):
            picked.append(r)
            taken[r.id] = true
    return picked


static func _role_group_of(db, r) -> int:
    if db == null:
        return Enums.RoleGroup.DPS
    var cd = db.class_of(r.class_id)
    return cd.role_group if cd != null else Enums.RoleGroup.DPS
