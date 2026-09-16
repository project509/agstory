extends "res://tests/TestCase.gd"
## sim/core/Rng.gd — determinism, correctness and bounds.
##
## The known-answer values below were produced by an INDEPENDENT Python
## implementation of SplitMix64 / xoshiro256** (see the commit that added this
## file). They are not captured from this implementation's own output, so they
## catch a wrong algorithm, not just a changed one. Do not regenerate them from
## GDScript — that would defeat the point.

const Rng = preload("res://sim/core/Rng.gd")

# ---------------------------------------------------------------- bit helpers

func test_lsr_does_not_sign_extend() -> void:
    # The whole reason lsr() exists: >> on a negative int sign-extends.
    assert_eq(Rng.lsr(-1, 1), 9223372036854775807, "lsr(-1,1) must zero-fill")
    assert_eq(Rng.lsr(-1, 63), 1)
    assert_eq(Rng.lsr(-1, 64), 0)
    assert_eq(Rng.lsr(16, 2), 4)
    assert_eq(Rng.lsr(5, 0), 5, "shift of 0 is identity")

func test_rotl_wraps_bits_around() -> void:
    assert_eq(Rng.rotl(1, 1), 2)
    assert_eq(Rng.rotl(-9223372036854775808, 1), 1, "top bit rotates to bottom")
    assert_eq(Rng.rotl(1, 64), 1, "full rotation is identity")
    assert_eq(Rng.rotl(1, 0), 1)

# ---------------------------------------------------------------- known answers

func test_kat_seed_state() -> void:
    var st := Rng.seed_state(12345)
    assert_eq(st[0], 2454886589211414944)
    assert_eq(st[1], 3778200017661327597)
    assert_eq(st[2], 2205171434679333405)
    assert_eq(st[3], 3248800117070709450)

func test_kat_draw_sequence() -> void:
    var r = Rng.new(12345)
    var expected := [
        -4725905248023948133, 2398916695208396998, -676359223724682360,
        891717726879801395, -8205428027391097272, 196975429884907396,
    ]
    for i in expected.size():
        assert_eq(r.next_u64(), expected[i], "draw %d" % i)

func test_kat_channel_hashes() -> void:
    assert_eq(Rng.hash64("damage"), 9179190079975030720)
    assert_eq(Rng.hash64("mistake_gate"), 5898614013793709683)
    assert_eq(Rng.hash64("loot"), -3608253369810582345)

func test_kat_derive() -> void:
    var master = Rng.new(12345)
    var child = master.derive("damage", 3, 7)
    assert_eq(child.master_seed, 988408075765935402, "derived child seed")
    assert_eq(child.next_u64(), -3774241187929768857)
    assert_eq(child.next_u64(), -6024919136831333776)
    assert_eq(child.next_u64(), -4540993622985683114)

# ---------------------------------------------------------------- determinism

func test_same_seed_same_sequence() -> void:
    var a = Rng.new(999)
    var b = Rng.new(999)
    for i in 200:
        assert_eq(a.next_u64(), b.next_u64(), "divergence at draw %d" % i)

func test_different_seeds_diverge() -> void:
    var a = Rng.new(1)
    var b = Rng.new(2)
    var same := 0
    for _i in 100:
        if a.next_u64() == b.next_u64():
            same += 1
    assert_eq(same, 0, "distinct seeds must not produce identical draws")

func test_deriving_does_not_consume_parent() -> void:
    var parent = Rng.new(42)
    var before: int = parent.next_u64()
    var p2 = Rng.new(42)
    p2.derive("damage", 1, 1)
    p2.derive("loot", 5, 2)
    assert_eq(p2.next_u64(), before, "derive() must not advance the parent stream")

func test_channels_are_independent() -> void:
    # Draws on one channel must not shift another — this is what keeps golden
    # files stable when a new roll is added somewhere in the sim.
    var m = Rng.new(7)
    var dmg_a = m.derive("damage", 1, 0)
    var loot_a = m.derive("loot", 1, 0)
    var loot_first: int = loot_a.next_u64()

    var m2 = Rng.new(7)
    var dmg_b = m2.derive("damage", 1, 0)
    for _i in 50:
        dmg_b.next_u64()          # burn draws on an unrelated channel
    var loot_b = m2.derive("loot", 1, 0)
    assert_eq(loot_b.next_u64(), loot_first, "loot channel perturbed by damage draws")
    assert_ne(dmg_a.next_u64(), loot_first)

func test_round_and_actor_change_the_stream() -> void:
    var m = Rng.new(3)
    var a: int = m.derive("damage", 1, 0).next_u64()
    var b: int = m.derive("damage", 2, 0).next_u64()
    var c: int = m.derive("damage", 1, 1).next_u64()
    assert_ne(a, b, "round must affect the stream")
    assert_ne(a, c, "actor ordinal must affect the stream")

# ---------------------------------------------------------------- bounds

func test_next_below_bounds_and_coverage() -> void:
    var r = Rng.new(5150)
    var seen := {}
    for _i in 4000:
        var v: int = r.next_below(6)
        assert_in_range(v, 0, 5, "next_below(6) out of range")
        seen[v] = true
    assert_eq(seen.size(), 6, "all six outcomes should appear")

func test_next_below_degenerate() -> void:
    var r = Rng.new(1)
    assert_eq(r.next_below(1), 0)
    assert_eq(r.next_below(0), 0)
    assert_eq(r.next_below(-3), 0)

func test_randi_range_inclusive_bounds() -> void:
    var r = Rng.new(77)
    var lo := 999
    var hi := -999
    for _i in 3000:
        var v: int = r.randi_range(-5, 9)
        assert_in_range(v, -5, 9)
        lo = mini(lo, v)
        hi = maxi(hi, v)
    assert_eq(lo, -5, "lower bound must be reachable")
    assert_eq(hi, 9, "upper bound must be reachable (inclusive)")

func test_randi_range_degenerate() -> void:
    var r = Rng.new(1)
    assert_eq(r.randi_range(4, 4), 4)
    assert_eq(r.randi_range(9, 2), 9, "inverted range returns lo")

# ---------------------------------------------------------------- basis points

func test_chance_bp_extremes_consume_nothing() -> void:
    var r = Rng.new(11)
    assert_false(r.chance_bp(0), "0 bp must never fire")
    assert_true(r.chance_bp(10000), "10000 bp must always fire")
    assert_eq(r.draws, 0, "certain outcomes must not consume draws")

func test_chance_bp_is_statistically_sane() -> void:
    # Canon anchors a Legendary raider near a 1% mistake rate, so a 100 bp gate
    # has to actually be 1% or the whole mistake model is wrong.
    var r = Rng.new(20260908)
    var hits := 0
    var n := 100000
    for _i in n:
        if r.chance_bp(100):
            hits += 1
    assert_in_range(hits, 880, 1120, "100bp over 100k trials should land near 1000, got %d" % hits)

func test_next_bp_bounds() -> void:
    var r = Rng.new(4)
    for _i in 2000:
        assert_in_range(r.next_bp(), 0, 9999)

# ---------------------------------------------------------------- collections

func test_shuffle_is_a_permutation() -> void:
    var arr := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    var original := arr.duplicate()
    Rng.new(31337).shuffle(arr)
    assert_eq(arr.size(), original.size())
    var sorted_copy := arr.duplicate()
    sorted_copy.sort()
    assert_eq(sorted_copy, original, "shuffle must preserve the multiset")
    assert_ne(arr, original, "a 12-element shuffle should reorder")

func test_shuffle_is_deterministic() -> void:
    var a := [1, 2, 3, 4, 5, 6, 7, 8]
    var b := [1, 2, 3, 4, 5, 6, 7, 8]
    Rng.new(8).shuffle(a)
    Rng.new(8).shuffle(b)
    assert_eq(a, b)

func test_pick_returns_members() -> void:
    var r = Rng.new(6)
    var arr := ["warrior", "cleric", "mage"]
    for _i in 60:
        assert_has(arr, r.pick(arr))
    assert_eq(r.pick([]), null, "empty array picks null")

func test_pick_weighted_respects_zero_weights() -> void:
    var r = Rng.new(9)
    var counts := [0, 0, 0, 0]
    for _i in 3000:
        counts[r.pick_weighted([50, 0, 30, 20])] += 1
    assert_eq(counts[1], 0, "zero-weight entry must never be picked")
    assert_true(counts[0] > counts[2], "weight 50 should beat weight 30")
    assert_true(counts[2] > counts[3], "weight 30 should beat weight 20")
    assert_eq(r.pick_weighted([0, 0]), -1, "all-zero weights return -1")

# ---------------------------------------------------------------- save/restore

func test_state_round_trip_resumes_draw_for_draw() -> void:
    var r = Rng.new(555)
    for _i in 20:
        r.next_u64()
    var snapshot: Dictionary = r.get_state()
    var expected := []
    for _i in 10:
        expected.append(r.next_u64())

    var restored = Rng.from_state(snapshot)
    assert_eq(restored.draws, 20, "draw count must survive the round trip")
    for i in 10:
        assert_eq(restored.next_u64(), expected[i], "draw %d after restore" % i)

func test_fork_reset_replays_from_the_start() -> void:
    var r = Rng.new(123)
    var first: int = r.next_u64()
    for _i in 30:
        r.next_u64()
    assert_eq(r.fork_reset().next_u64(), first)

func test_draw_accounting() -> void:
    var r = Rng.new(1)
    assert_eq(r.draws, 0)
    r.next_u64()
    r.next_u64()
    assert_eq(r.draws, 2, "every raw draw must be counted for divergence tracing")
