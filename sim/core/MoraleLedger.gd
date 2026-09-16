extends RefCounted
## The bookkeeping that stops morale being farmable (docs/05 §7.6).
##
## Every row in docs/05 §7's trigger table carries a cap or a cooldown, and the
## doc is explicit about why: "A build needs the full trigger list with caps, or
## morale becomes farmable and every raider parks at 100."
##
## Eight distinct cap shapes appear across those 24 rows, which is why this is its
## own object rather than a few counters on the raider. It is plain data — no
## Node, no RNG — and it round-trips through a save, because a cap the player can
## reset by quitting to the menu is not a cap.
##
## SCOPES, in the doc's own vocabulary:
##   tick     one Day Tick (docs/05 §4: resolving an attempt, or resting in town)
##   session  one raid attempt, or one loot distribution — the caller opens it
##   ever     permanent, per raider and subject ("once per boss per raider")
##   window   a rolling span of ticks ("max -6 per 7 ticks")

## Cap kinds, matching the phrasings docs/05 §7 actually uses.
enum Cap {
    NONE,            ## "Not capped"
    ONCE_TICK,       ## "Once per Day Tick"
    ONCE_SESSION,    ## "Once per attempt" / "Once per distribution"
    ONCE_EVER,       ## "Once per boss per raider, permanently"
    TOTAL_SESSION,   ## "Max -16 per raid attempt session"
    TOTAL_WINDOW,    ## "max -6 per 7 ticks"
    COOLDOWN,        ## "one per raider per 2 Day Ticks"
}

var tick: int = 0
var session: int = 0

## key -> accumulated magnitude, cleared when its scope rolls over.
var _tick_totals: Dictionary = {}
var _session_totals: Dictionary = {}
## key -> the tick it last fired on, for cooldowns and rolling windows.
var _last_fired: Dictionary = {}
## key -> array of [tick, magnitude], for TOTAL_WINDOW.
var _window: Dictionary = {}
## key -> true, for ONCE_EVER.
var _ever: Dictionary = {}


## A Day Tick has passed. docs/05 §4: drift and the §6 checks resolve once per
## tick, "after all event-driven morale deltas for that tick have applied".
func advance_tick() -> void:
    tick += 1
    _tick_totals.clear()


## Open a new attempt or loot distribution. Session-scoped caps reset.
func begin_session() -> void:
    session += 1
    _session_totals.clear()


static func key_for(raider_id: String, trigger_id: String, subject: String = "") -> String:
    return "%s|%s|%s" % [raider_id, trigger_id, subject]


# ---------------------------------------------------------------- queries

## How much of `magnitude` this trigger may still contribute, given its cap.
## Returns 0.0 when the cap is spent, which is what makes a blocked trigger a
## no-op rather than an error.
func allowance(key: String, cap: int, limit: float, window_ticks: int,
        magnitude: float) -> float:
    match cap:
        Cap.NONE:
            return magnitude
        Cap.ONCE_TICK:
            return 0.0 if _tick_totals.has(key) else magnitude
        Cap.ONCE_SESSION:
            return 0.0 if _session_totals.has(key) else magnitude
        Cap.ONCE_EVER:
            return 0.0 if _ever.has(key) else magnitude
        Cap.COOLDOWN:
            if not _last_fired.has(key):
                return magnitude
            var elapsed: int = tick - int(_last_fired[key])
            return magnitude if elapsed >= window_ticks else 0.0
        Cap.TOTAL_SESSION:
            var spent: float = float(_session_totals.get(key, 0.0))
            return maxf(0.0, minf(magnitude, limit - spent))
        Cap.TOTAL_WINDOW:
            var used := _window_total(key, window_ticks)
            return maxf(0.0, minf(magnitude, limit - used))
    return magnitude


func _window_total(key: String, window_ticks: int) -> float:
    var entries: Array = _window.get(key, [])
    var total := 0.0
    for e in entries:
        if tick - int(e[0]) < window_ticks:
            total += float(e[1])
    return total


## Record that `magnitude` actually fired, so the cap tightens.
func record(key: String, cap: int, window_ticks: int, magnitude: float) -> void:
    _tick_totals[key] = float(_tick_totals.get(key, 0.0)) + magnitude
    _session_totals[key] = float(_session_totals.get(key, 0.0)) + magnitude
    _last_fired[key] = tick
    if cap == Cap.ONCE_EVER:
        _ever[key] = true
    if cap == Cap.TOTAL_WINDOW:
        var entries: Array = _window.get(key, [])
        entries.append([tick, magnitude])
        # Drop entries that can never be in range again, so a long campaign does
        # not accumulate an unbounded history.
        var kept: Array = []
        for e in entries:
            if tick - int(e[0]) < window_ticks:
                kept.append(e)
        _window[key] = kept


func has_fired_ever(key: String) -> bool:
    return _ever.has(key)


# ---------------------------------------------------------------- save shape

## A cap the player can reset by quitting to the menu is not a cap, so this
## round-trips. Window history is pruned on write for the same reason it is
## pruned on record.
func to_dict() -> Dictionary:
    var windows := {}
    for key in _window:
        windows[key] = _window[key].duplicate(true)
    return {
        "tick": tick,
        "session": session,
        "last_fired": _last_fired.duplicate(true),
        "window": windows,
        "ever": _ever.duplicate(true),
        "session_totals": _session_totals.duplicate(true),
    }


static func from_dict(d: Dictionary):
    var out = load("res://sim/core/MoraleLedger.gd").new()
    out.tick = int(d.get("tick", 0))
    out.session = int(d.get("session", 0))
    for field in [["last_fired", "_last_fired"], ["window", "_window"],
            ["ever", "_ever"], ["session_totals", "_session_totals"]]:
        var raw = d.get(field[0], {})
        if typeof(raw) == TYPE_DICTIONARY:
            out.set(field[1], raw.duplicate(true))
    return out
