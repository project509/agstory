class_name TwgRng
extends RefCounted
## Deterministic PRNG for the simulation.  xoshiro256** for draws, SplitMix64
## for seeding and stream derivation.
##
## Implements docs/14-technical-architecture.md §8.
##
## Godot's RandomNumberGenerator is deliberately NOT used: its internals may
## change between engine versions, which would silently invalidate every golden
## file in tests/golden/.  This implementation is pinned here forever.
##
## Streams are per-channel.  With one shared stream, adding a single roll
## anywhere shifts every downstream result and no seed reproduces after a
## content change; channels keep the sim diff-stable.
##
##     var master = TwgRng.new(12345)   # or preload the script and .new()
##     var dmg := master.derive("damage", round_no, actor_ordinal)
##     if dmg.chance_bp(150): ...   # 1.50%

# SplitMix64 constants, written as signed int64 (GDScript ints are signed).
const GOLDEN_GAMMA := -7046029254386353131  # 0x9E3779B97F4A7C15
const SM_MIX_1 := -4658895280553007687      # 0xBF58476D1CE4E5B9
const SM_MIX_2 := -7723592293110705685      # 0x94D049BB133111EB

# FNV-1a 64. Used instead of String.hash() because that is engine-defined and
# may drift; channel names must hash identically across versions forever.
const FNV_OFFSET := -3750763034362895579    # 0xCBF29CE484222325
const FNV_PRIME := 1099511628211            # 0x100000001B3

const BP_SCALE := 10000  # basis points: outcome gates use integers, never floats


## Self-reference without the global class registry. A script's own `class_name`
## does not reliably resolve inside a STATIC function in headless runs, which
## broke this file twice; loading by path always works and is cached after the
## first call.
static var _self_script: GDScript = null
static func _cls() -> GDScript:
    if _self_script == null:
        _self_script = load("res://sim/core/Rng.gd")
    return _self_script

var master_seed: int = 0
var draws: int = 0

var _s0: int = 0
var _s1: int = 0
var _s2: int = 0
var _s3: int = 0


func _init(seed_value: int = 0) -> void:
    master_seed = seed_value
    var st := seed_state(seed_value)
    _s0 = st[0]
    _s1 = st[1]
    _s2 = st[2]
    _s3 = st[3]


# ---------------------------------------------------------------- bit helpers

## Logical (zero-filling) shift right. GDScript's >> is arithmetic on signed
## ints, which sign-extends and would corrupt every mix step.
static func lsr(x: int, n: int) -> int:
    if n <= 0:
        return x
    if n >= 64:
        return 0
    return (x >> n) & ~(-1 << (64 - n))


static func rotl(x: int, k: int) -> int:
    if k <= 0 or k >= 64:
        return x
    return (x << k) | lsr(x, 64 - k)


# ---------------------------------------------------------------- SplitMix64

## One SplitMix64 mix of an already-advanced state word.
static func splitmix64_mix(z_in: int) -> int:
    var z := z_in
    z = (z ^ lsr(z, 30)) * SM_MIX_1
    z = (z ^ lsr(z, 27)) * SM_MIX_2
    return z ^ lsr(z, 31)


## Full SplitMix64 step: advance by the golden gamma, then mix.
static func splitmix64(state: int) -> int:
    return splitmix64_mix(state + GOLDEN_GAMMA)


## Expand a seed into the four xoshiro256** state words.
static func seed_state(seed_value: int) -> Array:
    var s := seed_value
    var out := []
    for _i in 4:
        s += GOLDEN_GAMMA
        out.append(splitmix64_mix(s))
    return out


## Stable 64-bit string hash (FNV-1a).
static func hash64(text: String) -> int:
    var h := FNV_OFFSET
    for b in text.to_utf8_buffer():
        h = (h ^ b) * FNV_PRIME
    return h


# ---------------------------------------------------------------- draws

## Raw xoshiro256** draw. Full 64-bit range, may be negative.
func next_u64() -> int:
    var result := rotl(_s1 * 5, 7) * 9
    var t := _s1 << 17
    _s2 ^= _s0
    _s3 ^= _s1
    _s1 ^= _s2
    _s0 ^= _s3
    _s2 ^= t
    _s3 = rotl(_s3, 45)
    draws += 1
    return result


## Uniform in [0, n). Rejection-sampled, so genuinely unbiased — modulo would
## skew low values, which matters when a 1% mistake gate is being rolled
## millions of times in a balance sweep.
func next_below(n: int) -> int:
    if n <= 1:
        return 0
    var bits := 1
    while bits < 63 and (1 << bits) < n:
        bits += 1
    var mask := (1 << bits) - 1
    while true:
        var v := next_u64() & mask
        if v < n:
            return v
    return 0


## Uniform inclusive integer in [lo, hi].
func randi_range(lo: int, hi: int) -> int:
    if hi <= lo:
        return lo
    return lo + next_below(hi - lo + 1)


## Uniform basis points in [0, 10000).
func next_bp() -> int:
    return next_below(BP_SCALE)


## True with probability p_bp/10000. The only gate the sim should use.
func chance_bp(p_bp: int) -> bool:
    if p_bp <= 0:
        return false
    if p_bp >= BP_SCALE:
        return true
    return next_bp() < p_bp


## Uniform element of a non-empty array.
func pick(arr: Array):
    if arr.is_empty():
        return null
    return arr[next_below(arr.size())]


## In-place Fisher-Yates. Deterministic given the stream.
func shuffle(arr: Array) -> void:
    for i in range(arr.size() - 1, 0, -1):
        var j := next_below(i + 1)
        var tmp = arr[i]
        arr[i] = arr[j]
        arr[j] = tmp


## Weighted pick. weights are integers; returns an index, or -1 if all zero.
func pick_weighted(weights: Array) -> int:
    var total := 0
    for w in weights:
        if w > 0:
            total += w
    if total <= 0:
        return -1
    var roll := next_below(total)
    var acc := 0
    for i in weights.size():
        var w: int = weights[i]
        if w <= 0:
            continue
        acc += w
        if roll < acc:
            return i
    return weights.size() - 1


# ---------------------------------------------------------------- derivation

## Derive an independent per-channel stream.
## docs/14 §8: child_seed = splitmix64(master ^ hash64(channel)
##                                     ^ (round << 32) ^ actor_ordinal)
func derive(channel: String, round_no: int = 0, actor_ordinal: int = 0):
    var mixed := master_seed ^ hash64(channel) ^ (round_no << 32) ^ actor_ordinal
    return _cls().new(splitmix64(mixed))


## A fresh stream on the same seed — replays this stream from the start.
func fork_reset():
    return _cls().new(master_seed)


## Snapshot for save games. Restores draw-for-draw.
func get_state() -> Dictionary:
    return {
        "master_seed": master_seed, "draws": draws,
        "s0": _s0, "s1": _s1, "s2": _s2, "s3": _s3,
    }


static func from_state(state: Dictionary):
    var r = _cls().new(int(state.get("master_seed", 0)))
    r.draws = int(state.get("draws", 0))
    r._s0 = int(state.get("s0", 0))
    r._s1 = int(state.get("s1", 0))
    r._s2 = int(state.get("s2", 0))
    r._s3 = int(state.get("s3", 0))
    return r
