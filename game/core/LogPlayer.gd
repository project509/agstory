extends RefCounted
## The pacing model behind the raid view (docs/13 §11.2).
##
## The sim has already finished by the time this runs — docs/15 Q-09 rules out
## mid-raid input, so a raid is a completed event log and this screen is a
## READER, not a simulation. That is the whole reason the timing can live in a
## plain RefCounted with no Node, no tree and no signals: feed it delta seconds,
## it tells you which lines have become visible.
##
## Kept out of the screen so it can be tested at all. A reveal schedule expressed
## as `await` inside a Control is untestable by construction, and this one has
## real rules to get wrong — a comedy brake, three hold floors, and phase
## batching that only applies at one speed.
##
## docs/13 §11.2's hard constraint, quoted: "Speed affects presentation only and
## can never affect outcome." Nothing here touches a result; the log is read-only.

const Enums = preload("res://sim/model/Enums.gd")
const EventLog = preload("res://sim/core/EventLog.gd")

enum Speed { ONE, TWO, FOUR, INSTANT }

## docs/07 §5.5's fourth guard — "Identical Minor events by different raiders
## in the same round collapse to one line with a count" — at DISPLAY time and
## nowhere else (docs/07 §10 rule 2: the sim emits everything; folding at emit
## would make the log a source of divergence and move every golden's
## `event_count`). CONTENT-13 / audit M5-COMEDY-10. `true` ships; the switch
## exists because docs/13 §11 owns the widget and never drew it — the designer
## may want the wall of AFKs back.
const COLLAPSE := true

const SPEED_LABELS := ["1x", "2x", "4x", "Instant"]

## docs/13 §11.2, verbatim. Round duration is the doc's target for a whole round;
## the per-line cadence is what actually drives the reveal, so round length is
## emergent from it. Both are recorded because the doc gives both.
const ROUND_DURATION := {Speed.ONE: 2.60, Speed.TWO: 1.30, Speed.FOUR: 0.65}
const LINE_CADENCE := {Speed.ONE: 0.180, Speed.TWO: 0.110, Speed.FOUR: 0.0}
const MISTAKE_HOLD := {Speed.ONE: 0.700, Speed.TWO: 0.500, Speed.FOUR: 0.300}

## docs/13 §11.2's floors, which speed may never cross: "a mistake line is never
## below 300ms, is never batched with other lines, and is never skipped by a
## speed change mid-reveal."
const MISTAKE_HOLD_FLOOR := 0.300

## At 4x the doc paces by the ROUND (0.65s) and batches non-mistake lines "per
## phase", so a phase block gets one phase's share of the round. Derived from
## docs/13 §11.2's own round duration and the eight phases docs/07 §4 defines, so
## a round made of full phase blocks lands on the documented 0.65s.
##
## This exists because `LINE_CADENCE[FOUR]` is 0.0 — the doc's way of saying
## "batched" — and a zero hold made the reveal loop spin straight through the end
## of a block into the next mistake, batching it with lines it must never be
## batched with.
const PHASE_BLOCK_HOLD := ROUND_DURATION[Speed.FOUR] / 8.0

## docs/13 §11.4: the wipe sequence is ~2.4s total and fully skippable.
const WIPE_SEQUENCE_SECONDS := 2.40

## 🔷 The comedy brake (docs/13 §11.2), default on: at 2x and 4x, a Severe
## mistake, any death, and the wipe line drop to 1x cadence for that line only.
## "A joke needs a beat, and the player chose 4x to skip the arithmetic, not the
## story."
var comedy_brake: bool = true

var speed: int = Speed.ONE
var paused: bool = false

var _entries: Array = []
var _revealed: int = 0
var _timer: float = 0.0


## `entries` is an already-filtered list (see `EventLog.at_tier`), in order.
## The fold (`collapse`) is applied here, once, so every reader of this player
## — the reveal, `revealed()`, `total()` — sees the account the screen prints.
func _init(entries: Array = [], start_speed: int = Speed.ONE) -> void:
    _entries = collapse(entries)
    speed = start_speed
    _timer = 0.0


# ---------------------------------------------------------------- the fold

## docs/07 §5.5 guard 4, pure and screen-free: entries that are Minor mistakes
## of one type in one round by DIFFERENT raiders fold into one synthetic entry
## carrying `params.count` and `params.actors`; everything else passes through
## untouched, in order. The folded row lands where the group's LAST member
## stood and carries that member's `sequence`, so a screen folding HP bars "up
## to the newest line shown" (RaidView._fold_to) never runs ahead of the page,
## and the joke shown is that member's — the bag drew one per raider, the row
## prints one (CONTENT-13: one line for the folded row). A Severe never folds
## (docs/13 §11.2 gives it its own beat); a knock-on (`caused_by`) keeps its
## chain and never folds; a different round never folds. Idempotent: a row
## already carrying `count` passes through.
static func collapse(entries: Array) -> Array:
    if not COLLAPSE or entries.size() < 2:
        return entries
    var groups: Dictionary = {}
    for e in entries:
        if _foldable(e):
            var key := _fold_key(e)
            if not groups.has(key):
                groups[key] = []
            (groups[key] as Array).append(e)
    var out: Array = []
    for e in entries:
        if not _foldable(e):
            out.append(e)
            continue
        var g: Array = groups[_fold_key(e)]
        if g.size() < 2 or not _distinct_actors(g):
            out.append(e)
            continue
        if e != g[g.size() - 1]:
            continue
        out.append(_folded(g))
    return out


static func _fold_key(e) -> String:
    return "%d:%s" % [int(e.round_no), String(e.mistake.get("type", ""))]


static func _foldable(e) -> bool:
    if e == null or not e.is_mistake():
        return false
    if severity_of(e) != Enums.Severity.MINOR:
        return false
    if not String(e.mistake.get("caused_by", "")).is_empty():
        return false
    return int(e.params.get("count", 1)) <= 1


## "by different raiders": one raider fumbling the same way twice in a round is
## two lines, not a count.
static func _distinct_actors(g: Array) -> bool:
    var seen := {}
    for e in g:
        var id := String(e.actor_id)
        if seen.has(id):
            return false
        seen[id] = true
    return true


## The synthetic entry: the last member, copied, plus the count and the names.
static func _folded(g: Array):
    var last = g[g.size() - 1]
    var f = EventLog.Entry.new()
    f.sequence = last.sequence
    f.round_no = last.round_no
    f.phase = last.phase
    f.tier = last.tier
    f.verb = last.verb
    f.actor_id = last.actor_id
    f.actor_name = last.actor_name
    f.actor_class = last.actor_class
    f.target_id = last.target_id
    f.target_name = last.target_name
    f.target_class = last.target_class
    f.numbers = last.numbers.duplicate()
    f.mistake = last.mistake.duplicate()
    f.debug = last.debug.duplicate()
    f.template_id = last.template_id
    f.params = last.params.duplicate()
    f.params["count"] = g.size()
    var names: Array = []
    var sequences: Array = []
    for e in g:
        names.append(String(e.actor_name))
        sequences.append(int(e.sequence))
    f.params["actors"] = names
    f.params["sequences"] = sequences
    return f


## How many mistakes an entry stands for: its fold's count, else one.
static func count_of(e) -> int:
    if e == null:
        return 0
    return maxi(1, int(e.params.get("count", 1)))


## docs/13 §11.3's header, ONE rule for both reading surfaces (UI-19,
## CRITIC-C2): the TYPE leads — it is the one fact the row exists to say and
## the part an ellipsis used to eat — then who, then how bad:
## "Dropped a Mechanic — Greg, Severe". The class is on the card and in the
## joke's voice, so it is not repeated here. A folded row counts its raiders
## instead of naming one ("Went AFK — 3 raiders, Minor"); `actors_of` has the
## names.
static func mistake_header(e) -> String:
    var sev := severity_of(e)
    var sev_name: String = Enums.severity_name_of(sev) if sev >= 0 else "?"
    var who: String
    var count := count_of(e)
    if count > 1:
        who = "%d raiders" % count
    else:
        who = String(e.actor_name) if not String(e.actor_name).is_empty() else "Someone"
    return "%s — %s, %s" % [String(e.mistake_name()), who, sev_name]


## The raiders behind a row, as prose: "Greg, Steve and Bob" for a folded row,
## the one name otherwise. A courtesy for a tooltip — never the only place the
## header's facts live (docs/13 §7).
static func actors_of(e) -> String:
    var names: Array = []
    if e != null and e.params.has("actors"):
        for n in e.params["actors"]:
            names.append(String(n))
    if names.is_empty():
        return String(e.actor_name) if e != null else ""
    if names.size() == 1:
        return String(names[0])
    var head: Array = names.slice(0, names.size() - 1)
    return "%s and %s" % [", ".join(PackedStringArray(head)), String(names[names.size() - 1])]


func total() -> int:
    return _entries.size()


func revealed_count() -> int:
    return _revealed


func is_finished() -> bool:
    return _revealed >= _entries.size()


func progress() -> float:
    if _entries.is_empty():
        return 1.0
    return float(_revealed) / float(_entries.size())


## Everything revealed so far, for a screen rebuilding its page from scratch.
func revealed() -> Array:
    return _entries.slice(0, _revealed)


func next_entry():
    return _entries[_revealed] if _revealed < _entries.size() else null


## Reveal the rest at once. docs/13 §11.2's Instant row, and also what any input
## during the wipe sequence does.
func reveal_all() -> Array:
    var out := _entries.slice(_revealed, _entries.size())
    _revealed = _entries.size()
    _timer = 0.0
    return out


## Advance the reveal by `delta` seconds and return the lines that just landed.
##
## Returns an empty array while paused, which is what makes pause a presentation
## concern and not a state machine of its own.
func advance(delta: float) -> Array:
    if paused or is_finished():
        return []
    if speed == Speed.INSTANT:
        return reveal_all()

    var out: Array = []
    _timer -= maxf(0.0, delta)
    # A loop rather than a single step: at 4x a whole phase block lands in one
    # frame, and a long frame must delay the account rather than swallow part of
    # it. Every path through the body either spends time or ends the log, so the
    # loop cannot spin.
    while _timer <= 0.0 and not is_finished():
        var e = _entries[_revealed]
        _revealed += 1
        out.append(e)
        if _batches_with_next(e):
            # Still inside a 4x phase block: the next line joins this one and no
            # time is spent between them.
            continue
        _timer += maxf(duration_for(e), _minimum_step())
    return out


## No reveal step may be zero, or one frame would empty the whole account.
func _minimum_step() -> float:
    return PHASE_BLOCK_HOLD if speed == Speed.FOUR else 0.001


## How long the reveal holds after showing this line.
func duration_for(e) -> float:
    if e == null:
        return 0.0
    var effective: int = _effective_speed(e)
    if _is_mistake(e):
        var hold: float = float(MISTAKE_HOLD.get(effective, MISTAKE_HOLD_FLOOR))
        return maxf(MISTAKE_HOLD_FLOOR, hold)
    if effective == Speed.FOUR:
        # Batched per phase, so the hold belongs to the block, not the line.
        return PHASE_BLOCK_HOLD
    return float(LINE_CADENCE.get(effective, 0.0))


## The comedy brake, resolved per line. A braked line is paced as if the player
## had chosen 1x, and only that line.
func _effective_speed(e) -> int:
    if speed == Speed.ONE or not comedy_brake:
        return speed
    if deserves_a_beat(e):
        return Speed.ONE
    return speed


## docs/13 §11.2 names exactly three things the brake catches.
func deserves_a_beat(e) -> bool:
    if e == null:
        return false
    if _is_severe_mistake(e):
        return true
    if is_death(e):
        return true
    if is_wipe_line(e):
        return true
    return false


func _is_mistake(e) -> bool:
    return e != null and e.is_mistake()


func _is_severe_mistake(e) -> bool:
    if not _is_mistake(e):
        return false
    return severity_of(e) >= Enums.Severity.SEVERE


## The mistake dict stores severity as a KEY STRING (`EventLog.emit_mistake`),
## but tolerate an int in case a future emitter passes the enum directly.
static func severity_of(e) -> int:
    if e == null or not e.is_mistake():
        return -1
    var raw = e.mistake.get("severity", "")
    if typeof(raw) == TYPE_INT:
        return int(raw)
    return Enums.severity_from_key(String(raw))


static func is_death(e) -> bool:
    if e == null or e.verb != Enums.Verb.STATE_CHANGE:
        return false
    var state := String(e.params.get("state", "")).to_lower()
    return state == "dead" or state == "died" or state == "death"


static func is_wipe_line(e) -> bool:
    if e == null or e.verb != Enums.Verb.SYSTEM:
        return false
    return String(e.params.get("text", "")).to_lower().contains("wipe")


## Non-mistake lines batch per phase at 4x only (docs/13 §11.2), and a mistake
## line "is never batched with other lines" no matter the speed.
func _batches_with_next(e) -> bool:
    if speed != Speed.FOUR or is_finished():
        return false
    if _is_mistake(e):
        return false
    var nxt = _entries[_revealed]
    if _is_mistake(nxt):
        return false
    return nxt.round_no == e.round_no and nxt.phase == e.phase


# ---------------------------------------------------------------- controls

func set_speed(next_speed: int) -> void:
    # "never skipped by a speed change mid-reveal" — a pending hold is kept, so
    # raising the speed cannot cut a mistake's beat short.
    speed = clampi(next_speed, Speed.ONE, Speed.INSTANT)


func toggle_pause() -> bool:
    paused = not paused
    return paused


func cycle_speed() -> int:
    # Instant is deliberately NOT in the cycle: it ends the reveal, so it belongs
    # on its own control rather than one click away from 1x.
    if speed >= Speed.FOUR:
        speed = Speed.ONE
    else:
        speed += 1
    return speed


func speed_label() -> String:
    return SPEED_LABELS[clampi(speed, 0, SPEED_LABELS.size() - 1)]
