extends "res://tests/TestCase.gd"
## The achievement board — 988 lines of engine and 40 records that had no test
## at all.
##
## It landed in a parallel wave, it is wired into the Guildhall's Records tab,
## and it looks finished, which is the expensive kind of debt: nothing here was
## ever run against an expectation. These tests are written from the DOCS the
## file cites rather than from the file's own behaviour, so agreeing with it is
## evidence rather than tautology.
##
## What is checked, in the order it would hurt:
##   1. the data ships the shape docs/11 §11.1 asks for, and cannot grow a
##      time-gated entry, which canon forbids;
##   2. the engine answers "not now" rather than "no" for the conditions that
##      can only be decided while an attempt is being recorded — the failure
##      that would silently un-earn somebody's achievement on a reload;
##   3. the reward faucet is capped, and the cap is the reason a claim can be
##      refused rather than quietly paid smaller.

const A = preload("res://sim/core/Achievements.gd")
const Enums = preload("res://sim/model/Enums.gd")


func after_each() -> void:
    # The records are a static cache shared across every test file in the run.
    A.reset_records()


# ---------------------------------------------------------------- the records

func test_the_data_loads_with_no_errors() -> void:
    assert_true(A.is_valid(), "\n      ".join(A.load_errors()))
    assert_eq(A.records().size(), A.SHIP_TOTAL,
        "docs/11 §11.1 ships %d records" % A.SHIP_TOTAL)


func test_the_type_mix_is_the_one_the_doc_asks_for() -> void:
    # docs/11 §11.1's own split. A board that drifts to twenty progress rows and
    # two comedy ones is a different feature wearing the same name.
    var counted := {}
    for rec in A.records():
        var t := String((rec as Dictionary).get("type", ""))
        counted[t] = int(counted.get(t, 0)) + 1
    for t in A.TYPE_SHIP_COUNTS.keys():
        assert_eq(int(counted.get(t, 0)), int(A.TYPE_SHIP_COUNTS[t]),
            "%s records" % t)


func test_every_id_is_unique_and_every_record_cites_its_source() -> void:
    var seen := {}
    var bad: Array[String] = []
    for rec in A.records():
        var d: Dictionary = rec
        var rid := String(d.get("id", ""))
        if rid.is_empty():
            bad.append("a record with no id")
        if seen.has(rid):
            bad.append("%s appears twice" % rid)
        seen[rid] = true

    assert_eq(bad.size(), 0, "\n      " + "\n      ".join(bad))


func test_every_condition_and_reward_kind_is_one_the_engine_knows() -> void:
    # An unknown kind does not crash — `is_satisfied` falls through its match and
    # answers false — so the achievement would simply never fire. Silence is the
    # failure mode, which is why this is a test and not a guard.
    var bad: Array[String] = []
    for rec in A.records():
        var d: Dictionary = rec
        var cond: Dictionary = d.get("condition", {})
        var kind := String(cond.get("kind", ""))
        if not A.CONDITION_KINDS.has(kind):
            bad.append("%s: condition kind '%s' is not in the vocabulary" % [d.get("id"), kind])
        var rew: Dictionary = d.get("reward", {})
        var rkind := String(rew.get("kind", ""))
        if not rkind.is_empty() and not A.REWARD_KINDS.has(rkind):
            bad.append("%s: reward kind '%s' is not in the vocabulary" % [d.get("id"), rkind])
    assert_eq(bad.size(), 0, "\n      " + "\n      ".join(bad))


func test_no_record_can_be_time_gated() -> void:
    # canon has no dailies and no timers; the engine keeps a banned-key list and
    # this is the test that makes the list mean something.
    var bad: Array[String] = []
    for rec in A.records():
        for key in A.BANNED_KEYS:
            if (rec as Dictionary).has(key):
                bad.append("%s carries '%s'" % [(rec as Dictionary).get("id"), key])
            var cond: Dictionary = (rec as Dictionary).get("condition", {})
            if cond.has(key):
                bad.append("%s's condition carries '%s'" % [(rec as Dictionary).get("id"), key])
    assert_eq(bad.size(), 0, "time-gated content is not in this game:\n      "
        + "\n      ".join(bad))


# ---------------------------------------------------------------- the gate

func test_the_board_is_shut_until_known_and_says_why() -> void:
    # docs/03 §7's town unlock, and docs/13 §7's rule that a closed door states
    # its condition rather than simply being missing.
    var snap := A.blank_snapshot()
    var reason := A.unlock_reason(snap)
    assert_true(reason.length() > 0, "a brand-new guild cannot see the board")
    assert_true(reason.contains(Enums.reputation_name_of(A.UNLOCK_RANK)),
        "and the reason must name the rank: '%s'" % reason)
    snap["reputation_rank"] = A.UNLOCK_RANK
    assert_eq(A.unlock_reason(snap), "", "at Known the board opens")


# ---------------------------------------------------------------- evaluation

func test_clearing_the_first_tutorial_earns_its_record() -> void:
    # The simplest end-to-end path through evaluate(): a snapshot that has
    # cleared A0 should satisfy exactly the record docs/02 §4.4 calls First
    # Blood, and satisfying it twice should not earn it twice.
    var snap := A.blank_snapshot()
    snap["cleared_slots"] = {A.ladder_key(1, "A0"): 1}
    var earned: Array = A.evaluate(snap)
    assert_true(earned.has("prog_adventure_0"),
        "clearing Adventure 0 should earn its record, got %s" % str(earned))
    snap["earned"] = {"prog_adventure_0": 1}
    assert_false(A.evaluate(snap).has("prog_adventure_0"),
        "an earned record must not be earned again")


func test_an_event_only_condition_answers_not_now_rather_than_no() -> void:
    # THE subtle one, and the file names it itself: conditions like "flawless
    # clear" can only be decided while an attempt is being recorded. Evaluated
    # against a bare snapshot they must answer false — not because the player
    # failed, but because the question cannot be asked — and the earned set is
    # what remembers. If they answered TRUE here, every reload would hand out
    # every event achievement; if the earned set did not remember, a reload
    # would take them away.
    var event_only: Array[String] = []
    for rec in A.records():
        var cond: Dictionary = (rec as Dictionary).get("condition", {})
        if A.EVENT_ONLY_KINDS.has(String(cond.get("kind", ""))):
            event_only.append(String((rec as Dictionary).get("id", "")))
    assert_true(event_only.size() >= 1, "expected some event-only records")
    var snap := A.blank_snapshot()
    for rid in event_only:
        assert_false(A.is_satisfied(A.record(rid), snap, {}),
            "%s must not fire without an attempt to read" % rid)
    # And the earned set is what carries them across a reload.
    snap["earned"] = {event_only[0]: 1}
    assert_eq(A.state_of(event_only[0], snap), A.State.EARNED,
        "an event achievement survives in the earned set, not in the condition")


func test_state_walks_locked_then_earned_then_claimed() -> void:
    var snap := A.blank_snapshot()
    var rid := String((A.records()[0] as Dictionary)["id"])
    assert_eq(A.state_of(rid, snap), A.State.LOCKED, "everything starts locked")
    snap["earned"] = {rid: 1}
    assert_eq(A.state_of(rid, snap), A.State.EARNED)
    snap["claimed"] = [rid]
    assert_eq(A.state_of(rid, snap), A.State.CLAIMED, "claimed outranks earned")
    assert_eq(A.state_name(A.State.CLAIMED), "Claimed")


# ---------------------------------------------------------------- the faucet

func test_the_coin_cap_is_fifteen_percent_of_what_the_guild_has_earned() -> void:
    # docs/15 Q-69: "Board grants RP, capped ~15% of total earned", and docs/11
    # §11.2's version for coin. The cap is a share, so it is zero for a guild
    # that has earned nothing — which is the case that matters, because that is
    # when a free purse would distort the whole opening.
    assert_eq(A.coin_cap(0), 0, "a guild that has earned nothing is owed nothing")
    assert_eq(A.coin_cap(10000), int(10000 * A.COIN_CAP_SHARE))
    assert_eq(A.rp_cap(2000), int(2000 * A.RP_CAP_SHARE))
    assert_eq(A.coin_cap(-500), 0, "a negative lifetime is not a credit")


func test_a_claim_is_refused_rather_than_quietly_paid_smaller() -> void:
    # docs/11 §11.2: the purse "is never enough to substitute for playing
    # content". When the cap binds, the honest answer is to say so — paying a
    # reduced amount would read as the reward being wrong rather than as the
    # board having a share.
    var coin_rec := {}
    for rec in A.records():
        if String(((rec as Dictionary).get("reward", {}) as Dictionary).get("kind", "")) == "coin":
            coin_rec = rec
            break
    assert_true(not coin_rec.is_empty(), "expected at least one coin reward")
    var rid := String(coin_rec["id"])
    var snap := A.blank_snapshot()
    snap["earned"] = {rid: 1}
    snap["gold_earned_lifetime"] = 0
    var grant: Dictionary = A.claim_grant(rid, snap)
    assert_true(String(grant.get("blocked", "")).length() > 0,
        "with no lifetime income the cap must block the claim")
    assert_true(String(grant["blocked"]).contains("earned"),
        "and the message must say what it is waiting for: '%s'" % grant["blocked"])
    # With enough income behind it, the same claim pays.
    snap["gold_earned_lifetime"] = 100000
    var paid: Dictionary = A.claim_grant(rid, snap)
    assert_eq(String(paid.get("blocked", "")), "", "a well-funded guild is paid")
    assert_true(int(paid.get("amount", 0)) > 0, "and paid something")


func test_an_unearned_or_twice_claimed_record_pays_nothing() -> void:
    var rid := String((A.records()[0] as Dictionary)["id"])
    var snap := A.blank_snapshot()
    snap["gold_earned_lifetime"] = 100000
    assert_eq(String(A.claim_grant(rid, snap).get("blocked", "")), "Not earned yet.")
    snap["earned"] = {rid: 1}
    snap["claimed"] = [rid]
    assert_eq(String(A.claim_grant(rid, snap).get("blocked", "")), "Already claimed.")
    assert_eq(String(A.claim_grant("no_such_achievement", snap).get("blocked", "")),
        "No such record.")


func test_the_whole_board_cannot_outpay_a_realistic_lifetime() -> void:
    # The authoring-time check the file's own comment asks for: "a board whose
    # maximum payout already exceeds 15% of a realistic lifetime income is
    # mis-scaled at authoring time, not at play time." The denominator exists now
    # (`gold_earned_lifetime`, audit M5-QAB-5, wired and asserted in
    # test_game_state.gd), but what a whole campaign earns is the balance wave's
    # number, so this still asserts the shape rather than a tuned figure: every
    # coin the board could ever pay must fit inside the cap of SOME plausible
    # lifetime, and that lifetime is recorded here rather than left implied.
    var ceiling: int = A.coin_ceiling()
    assert_true(ceiling > 0, "the board pays something")
    var implied_lifetime := int(ceil(float(ceiling) / A.COIN_CAP_SHARE))
    assert_true(implied_lifetime < 200000,
        "the board's %d G ceiling implies a %d G lifetime before it can all be claimed"
        % [ceiling, implied_lifetime])


# ---------------------------------------------- the reputation faucet (Q-69)

## Every record whose reward is reputation-kind, by id.
func _reputation_records() -> Array:
    var out: Array = []
    for rec in A.records():
        var rew: Dictionary = (rec as Dictionary).get("reward", {})
        if String(rew.get("kind", "")) == "reputation":
            out.append(rec)
    return out


func test_a_reputation_record_pays_the_fifteen_the_ruling_gave_it() -> void:
    # docs/15 Q-69, RULED 2026-09-15: the board pays reputation, at docs/03
    # §6.1's smallest award — the two tutorials' 15. Before the ruling both
    # records carried no `rp` at all and `effective_reward` converted them to
    # their type's coin figure, so the faucet existed and paid nothing.
    var reps: Array = _reputation_records()
    assert_eq(reps.size(), 2, "docs/11 §11.1's two Roster reputation examples")
    for rec in reps:
        var rid := String((rec as Dictionary).get("id", ""))
        assert_eq(int(((rec as Dictionary).get("reward", {}) as Dictionary).get("rp", 0)), 15,
            "%s pays docs/03 §6.1's smallest award" % rid)
        var live: Dictionary = A.effective_reward(rec, true)
        assert_eq(String(live.get("kind", "")), "reputation", "%s pays in reputation" % rid)
        assert_eq(int(live.get("amount", 0)), 15)
        assert_eq(A.describe_reward(rec, true), "15 reputation",
            "and the row says so without a caveat")
        # The recorded alternative (`achievement_rp` off) is the type's coin figure.
        var off: Dictionary = A.effective_reward(rec, false)
        assert_eq(String(off.get("kind", "")), "coin", "%s with the switch off" % rid)
        assert_eq(int(off.get("amount", 0)),
            int(A.TYPE_COIN[String((rec as Dictionary).get("type", ""))]))

    # And the claim itself pays it, once the town has heard enough to owe it.
    var first_id := String((reps[0] as Dictionary)["id"])
    var snap := A.blank_snapshot()
    snap["earned"] = {first_id: 1}
    snap["rp_earned_lifetime"] = 120       # Known, docs/03 §6's first rank threshold
    var grant: Dictionary = A.claim_grant(first_id, snap)
    assert_eq(String(grant.get("blocked", "")), "", "a Known guild can be paid")
    assert_eq(String(grant.get("kind", "")), "reputation")
    assert_eq(int(grant.get("amount", 0)), 15)


func test_the_town_hears_no_more_than_its_share_over_a_whole_run() -> void:
    # Q-69's other half, the coin cap's twin: "capped at ~15% of total earned".
    # Walked as a run rather than asserted as a formula — claim every reputation
    # record the board has, in order, against a lifetime that grows the way a
    # guild's does, and check the two things that can go wrong: paying past the
    # share, and paying a reduced amount instead of saying no.
    var reps: Array = _reputation_records()
    var snap := A.blank_snapshot()
    snap["earned"] = {}
    for rec in reps:
        (snap["earned"] as Dictionary)[String((rec as Dictionary)["id"])] = 1

    # A guild that has earned nothing is owed nothing, and is told why.
    var first := String((reps[0] as Dictionary)["id"])
    var refused: Dictionary = A.claim_grant(first, snap)
    assert_true(String(refused.get("blocked", "")).length() > 0,
        "with no reputation earned the share is zero")
    assert_true(String(refused["blocked"]).contains("The town has heard its share"),
        "and the sentence is the town's: '%s'" % refused["blocked"])
    assert_true(String(refused["blocked"]).contains("reputation it may pay against 0 earned"),
        "and it names the denominator it is a share of")
    assert_eq(int(refused.get("amount", 0)), 15,
        "the amount is still the record's — a refusal, not a reduction")

    # The run: 400 lifetime RP is a Tier-1 ladder walked twice over (docs/03
    # §6.4's pacing table). 15% of it is 60, so both records fit — and nothing
    # past the share is ever paid.
    snap["rp_earned_lifetime"] = 400
    var paid_total: int = 0
    for rec in reps:
        var rid := String((rec as Dictionary)["id"])
        var grant: Dictionary = A.claim_grant(rid, snap)
        assert_eq(String(grant.get("blocked", "")), "", "%s is paid at 400 earned" % rid)
        paid_total += int(grant.get("amount", 0))
        (snap["claimed"] as Array).append(rid)
        assert_eq(A.rp_paid(snap["claimed"]), paid_total,
            "the running total is what the cap is checked against")
    assert_true(paid_total <= A.rp_cap(int(snap["rp_earned_lifetime"])),
        "the board paid %d against a %d share of %d earned"
        % [paid_total, A.rp_cap(400), 400])

    # The share binding is a refusal, never a smaller payment: at 100 earned the
    # cap is 15, so the first record fits exactly and the second cannot.
    var tight := A.blank_snapshot()
    tight["earned"] = snap["earned"]
    tight["rp_earned_lifetime"] = 100
    assert_eq(A.rp_cap(100), 15)
    var one: Dictionary = A.claim_grant(String((reps[0] as Dictionary)["id"]), tight)
    assert_eq(String(one.get("blocked", "")), "", "the first fits the share exactly")
    (tight["claimed"] as Array).append(String((reps[0] as Dictionary)["id"]))
    var two: Dictionary = A.claim_grant(String((reps[1] as Dictionary)["id"]), tight)
    assert_true(String(two.get("blocked", "")).length() > 0, "the second does not")
    assert_eq(int(two.get("amount", 0)), 15,
        "and it is refused whole rather than paid smaller")


func test_no_row_on_the_wall_apologises_for_a_missing_ruling() -> void:
    # Q-69 was OPEN for five waves and the board said so on every reputation row:
    # "40 G (reputation is not signed off — docs/03 §6 has not signed off a board
    # reputation rate)". The ruling landed; the apology has to go with it, at both
    # switch settings, because a player never sees the register.
    for rec in A.records():
        for live in [true, false]:
            var line := A.describe_reward(rec, live)
            assert_false(line.contains("signed off"),
                "%s: '%s'" % [(rec as Dictionary).get("id", "?"), line])
            assert_false(line.contains("docs/"),
                "%s: '%s'" % [(rec as Dictionary).get("id", "?"), line])
            assert_false(line.contains("switch"),
                "%s: '%s'" % [(rec as Dictionary).get("id", "?"), line])
            assert_true(line.length() > 0,
                "%s has no reward line at all" % (rec as Dictionary).get("id", "?"))


func test_no_record_names_a_feature_this_build_does_not_have() -> void:
    # docs/15 Q-13, RULED: the Blacksmith is out of 1.0. A record conditioned on
    # `items_upgraded` was a row that could never light for anybody — the same
    # shape as a test that branches on whether the work exists (LESSONS). The
    # vocabulary keeps the kind so a post-1.0 build can use it; the WALL may not.
    var absent := ["items_upgraded"]
    var bad: Array[String] = []
    for rec in A.records():
        var cond: Dictionary = (rec as Dictionary).get("condition", {})
        if absent.has(String(cond.get("kind", ""))):
            bad.append("%s is conditioned on '%s', which no 1.0 build can move"
                % [(rec as Dictionary).get("id", "?"), cond.get("kind", "")])
    assert_eq(bad.size(), 0, "\n      " + "\n      ".join(bad))
    # Its replacement is the row Q-13 named, and it reads a counter the state keeps.
    var replacement: Dictionary = A.record("econ_first_ten")
    assert_false(replacement.is_empty(), "econ_first_ten ships")
    assert_eq(String(replacement.get("name", "")), "Pocket Change")
    assert_eq(String((replacement.get("condition", {}) as Dictionary).get("kind", "")),
        "items_sold")
    assert_eq(int((replacement.get("condition", {}) as Dictionary).get("count", 0)), 10)
    assert_true(A.record("econ_upgrade_one").is_empty(),
        "and the row it replaced is gone rather than hidden")


func test_every_record_cites_the_doc_it_came_from() -> void:
    # Read from the FILE rather than from `records()`: the loader strips
    # underscore keys on the way in, so the citation only exists on disk — which
    # is the right place for it, and the wrong place to forget to check.
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(A.DEFAULT_PATH))
    assert_true(parsed is Dictionary, "the records file must parse")
    var bad: Array[String] = []
    for row in (parsed as Dictionary).get("achievements", []):
        var d: Dictionary = row
        if String(d.get("_doc", "")).length() < 10:
            bad.append("%s does not cite a source" % d.get("id", "?"))
    assert_eq(bad.size(), 0, "a record that cannot name its doc is one somebody invented:
      "
        + "
      ".join(bad))
