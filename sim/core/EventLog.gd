class_name TwgEventLog
extends RefCounted
## The simulation's only output.
##
## docs/07 §10: the log IS the game's output. The player reads it more than any
## other screen and it carries all the comedy; it is also the only debugging
## surface for a sim the player cannot touch.
##
## Two rules make it work, and both are enforced here:
##
## 1. **Entries are structured data, never prose.** The displayed string is
##    rendered from a template at display time, which is what keeps localisation
##    and verbosity filtering possible at all.
##
## 2. **The sim always emits everything.** Verbosity is a display FILTER over one
##    complete log. Emitting differently per tier would make the log itself a
##    source of divergence, and two players at different settings would get
##    different games.
##
## The whole raid view is a player for this stream (docs/13), which is what makes
## speed controls, pause and skip trivial rather than a rewrite.

const Enums = preload("res://sim/model/Enums.gd")

static var _self_script: GDScript = null
static func _cls() -> GDScript:
    if _self_script == null:
        _self_script = load("res://sim/core/EventLog.gd")
    return _self_script


## One event. Field set is docs/07 §10.1.
class Entry extends RefCounted:
    var sequence: int = 0          # monotone within the encounter; the sort key
    var round_no: int = 0
    var phase: int = 0             # Enums.Phase
    var tier: int = 0              # Enums.LogTier — the LOWEST tier that shows it
    var verb: int = 0              # Enums.Verb

    var actor_id: String = ""
    var actor_name: String = ""
    var actor_class: int = -1
    var target_id: String = ""
    var target_name: String = ""
    var target_class: int = -1

    ## damage/heal amount, hp_after, threat_after, resource_after …
    var numbers: Dictionary = {}
    ## type, severity, caused_by, cascade_depth — empty on non-mistakes
    var mistake: Dictionary = {}
    ## docs/07 §10.1's provenance — p_bp, r_bp, margin, channel, draw, weights,
    ## severity_s on a mistake (SIM-29). ALWAYS written when the sim has it,
    ## SHOWN only at tier DEBUG: rule 2 above, the sim emits everything and the
    ## tier is a display filter. Empty on entries that have no roll behind them.
    var debug: Dictionary = {}

    var template_id: String = ""
    var params: Dictionary = {}

    func is_mistake() -> bool:
        return verb == Enums.Verb.MISTAKE

    func number(key: String, fallback: int = 0) -> int:
        return int(numbers.get(key, fallback))

    ## Severity as an Enums.Severity index, or -1 when the entry has none.
    ##
    ## `mistake["severity"]` is a KEY ("severe"), because every other enum on
    ## this entry serialises as a key. Writing the display Name here instead and
    ## reading it back through `severity_from_key` returned -1 for every real
    ## mistake, which silently disabled docs/13 §11.2's comedy brake and printed
    ## `?` in §11.3's header. Both directions of that round trip now go through
    ## this pair, so a mismatch cannot come back.
    func severity_index() -> int:
        var raw = mistake.get("severity", "")
        if typeof(raw) == TYPE_INT:
            return int(raw)
        return Enums.severity_from_key(String(raw))

    func severity_display() -> String:
        var idx := severity_index()
        return Enums.severity_name_of(idx) if idx >= 0 else "?"

    ## The mistake's display name ("Pulled Aggro Off the Tank"). The stable key
    ## a line corpus is looked up on is `mistake["type"]` ("MIS_AGGRO").
    func mistake_name() -> String:
        return String(mistake.get("name", mistake.get("type", "?")))

    ## The rendered joke line, or "" when no corpus supplied one. docs/13 §11.3.
    func joke() -> String:
        return String(params.get("text", ""))

    ## docs/07 §10.3's tier-3 sample, rendered from `debug`:
    ##   p=14.0 r=3.1 margin=0.779 | ch=mistake_gate:r4:5 draw#17 | type roll
    ##   {MIS_AGGRO: 15, ...} -> MIS_AGGRO | severity S=82
    ## "" when the entry carries no provenance, so a tier-3 view can append it
    ## under any header without checking first. `p`/`r` are percentages; a
    ## scripted (forced) mistake prints `p=- r=-` because no gate was rolled.
    func debug_line() -> String:
        if debug.is_empty():
            return ""
        var p := int(debug.get("p_bp", -1))
        var r := int(debug.get("r_bp", -1))
        var s := int(debug.get("severity_s", -1))
        var weights: Dictionary = debug.get("weights", {})
        var parts: Array[String] = []
        for k in weights.keys():
            parts.append("%s: %d" % [String(k), int(weights[k])])
        return "p=%s r=%s margin=%.3f | ch=%s draw#%d | type roll {%s} -> %s | severity S=%s" % [
            ("%.1f" % (float(p) / 100.0)) if p >= 0 else "-",
            ("%.1f" % (float(r) / 100.0)) if r >= 0 else "-",
            float(debug.get("margin", 0.0)),
            String(debug.get("channel", "")), int(debug.get("draw", 0)),
            ", ".join(parts), String(mistake.get("type", "?")),
            str(s) if s >= 0 else "-"]

    ## Plain fallback rendering from the structured fields. Real display goes
    ## through the template registry (content, docs/07 §10.3); this exists so a
    ## log is always readable in tests, dev builds and bug reports even when no
    ## template is registered for an event.
    func describe() -> String:
        var head := "[R%02d]" % round_no
        match verb:
            Enums.Verb.MISTAKE:
                var line := "%s %s MISTAKE · %s · %s" % [
                    head, actor_name, severity_display(), mistake_name()]
                # docs/07 §6's edge, so the goldens' story shows a chain as a
                # chain (SIM-05): the parent's id and the depth. The screens
                # render this line through `LogPlayer.mistake_header` and
                # resolve the id to a name themselves (Results' cause line).
                var cause := String(mistake.get("caused_by", ""))
                if not cause.is_empty():
                    line += " (after %s, depth %d)" % [cause, int(mistake.get("cascade_depth", 0))]
                # docs/07 §10.3's sample block puts the joke on an indented,
                # quoted second line under its header. Carrying it here is what
                # makes the golden `story` arrays a readable dump of the corpus
                # in situ, which is the only cheap review surface it gets.
                var quip := joke()
                if not quip.is_empty():
                    line += "\n      \"%s\"" % quip
                return line
            Enums.Verb.ATTACK:
                if numbers.has("amount"):
                    return "%s %s hits %s for %d." % [head, actor_name, target_name, number("amount")]
                return "%s %s attacks %s." % [head, actor_name, target_name]
            Enums.Verb.HEAL:
                return "%s %s heals %s for %d." % [head, actor_name, target_name, number("amount")]
            Enums.Verb.STATE_CHANGE:
                return "%s %s is %s." % [head, actor_name, String(params.get("state", "changed"))]
            Enums.Verb.MECHANIC:
                return "%s %s" % [head, String(params.get("text", "A mechanic fires."))]
            Enums.Verb.PHASE:
                return "%s -- %s --" % [head, Enums.phase_name_of(phase)]
            _:
                return "%s %s" % [head, String(params.get("text", template_id))]

    func to_dict() -> Dictionary:
        var d := {
            "sequence": sequence, "round": round_no,
            "phase": Enums.phase_key(phase), "tier": Enums.log_tier_key(tier),
            "verb": Enums.verb_key(verb),
            "actor_id": actor_id, "actor_name": actor_name,
            "target_id": target_id, "target_name": target_name,
            "template_id": template_id,
        }
        if not numbers.is_empty():
            d["numbers"] = numbers.duplicate()
        if not mistake.is_empty():
            d["mistake"] = mistake.duplicate()
        if not params.is_empty():
            d["params"] = params.duplicate()
        if not debug.is_empty():
            d["debug"] = debug.duplicate()
        return d


var entries: Array = []
var _next_sequence: int = 0


# ---------------------------------------------------------------- emission

## Append an event. Returns the Entry so a caller can attach extra fields.
## `sequence` is assigned here and nowhere else, so it cannot skip or repeat.
func emit(verb: int, tier: int, round_no: int, phase: int,
        template_id: String = "", params: Dictionary = {}) -> Entry:
    var e := Entry.new()
    e.sequence = _next_sequence
    _next_sequence += 1
    e.verb = verb
    e.tier = tier
    e.round_no = round_no
    e.phase = phase
    e.template_id = template_id
    e.params = params.duplicate()
    entries.append(e)
    return e


func emit_attack(round_no: int, phase: int, actor, target, amount: int,
        hp_after: int, threat_after: int = 0) -> Entry:
    var e := emit(Enums.Verb.ATTACK, Enums.LogTier.PLAY_BY_PLAY, round_no, phase, "attack")
    _set_actor(e, actor)
    _set_target(e, target)
    e.numbers = {"amount": amount, "hp_after": hp_after, "threat_after": threat_after}
    return e


func emit_heal(round_no: int, phase: int, actor, target, amount: int, hp_after: int) -> Entry:
    var e := emit(Enums.Verb.HEAL, Enums.LogTier.PLAY_BY_PLAY, round_no, phase, "heal")
    _set_actor(e, actor)
    _set_target(e, target)
    e.numbers = {"amount": amount, "hp_after": hp_after}
    return e


## Mistakes are always Story tier: they are the thing the player came for, and
## they must survive every verbosity filter.
##
## `type_id` is the taxonomy key ("MIS_AGGRO", a key of `Mistakes.TYPES`) and it
## is what a line corpus is looked up on; `display_name` is the prose the header
## shows. Both are stored, because storing only the name left nothing to key a
## template on (docs/07 §10.1: the entry references the line, it never inlines
## it) and storing only the key would have moved every golden's `story` array.
## `severity` is an Enums.SEVERITY_KEYS key, like every other enum on the entry.
## `debug` is docs/07 §10.1's provenance block (`MistakeEvent.debug_dict()`),
## shown at tier DEBUG only; empty leaves the entry without one.
func emit_mistake(round_no: int, phase: int, actor, type_id: String,
        display_name: String, severity: String, caused_by: String = "",
        cascade_depth: int = 0, template_id: String = "",
        joke: String = "", debug: Dictionary = {}) -> Entry:
    var e := emit(Enums.Verb.MISTAKE, Enums.LogTier.STORY, round_no, phase, "mistake")
    _set_actor(e, actor)
    e.mistake = {
        "type": type_id, "name": display_name, "severity": severity,
        "caused_by": caused_by, "cascade_depth": cascade_depth,
        "template": template_id,
    }
    # Only present when a corpus rendered a line, so an entry with no joke
    # serialises exactly as it did before the joke path existed.
    if not joke.is_empty():
        e.params["text"] = joke
    if not debug.is_empty():
        e.debug = debug.duplicate()
    return e


## Downed, revived, died. Also Story tier — these are the beats of the fight.
func emit_state_change(round_no: int, phase: int, actor, state: String) -> Entry:
    var e := emit(Enums.Verb.STATE_CHANGE, Enums.LogTier.STORY, round_no, phase,
        "state_change", {"state": state})
    _set_actor(e, actor)
    return e


func emit_mechanic(round_no: int, phase: int, mechanic: int, text: String) -> Entry:
    return emit(Enums.Verb.MECHANIC, Enums.LogTier.STORY, round_no, phase,
        "mechanic", {"mechanic": Enums.mechanic_key(mechanic), "text": text})


func emit_phase(round_no: int, phase: int) -> Entry:
    return emit(Enums.Verb.PHASE, Enums.LogTier.NUMBERS, round_no, phase, "phase")


func emit_system(round_no: int, text: String, tier: int = Enums.LogTier.STORY) -> Entry:
    return emit(Enums.Verb.SYSTEM, tier, round_no, Enums.Phase.ROUND_CLOSE,
        "system", {"text": text})


## Actors are Combatants, or anything exposing `display_name()` and a `raider`.
## Enemies have neither, so they can be passed as a plain name string.
func _fill_actor(actor, fields: Array) -> Array:
    # returns [id, name, class]
    if actor == null:
        return ["", "", -1]
    if actor is String:
        return ["", String(actor), -1]
    var nm := ""
    if actor.has_method("display_name"):
        nm = actor.display_name()
    var rid := ""
    var cls := -1
    if "raider" in actor and actor.raider != null:
        rid = actor.raider.id
        cls = actor.raider.class_id
        if nm.is_empty():
            nm = actor.raider.display_name
    return [rid, nm, cls]


func _set_actor(e: Entry, actor) -> void:
    var f := _fill_actor(actor, [])
    e.actor_id = f[0]
    e.actor_name = f[1]
    e.actor_class = f[2]


func _set_target(e: Entry, target) -> void:
    var f := _fill_actor(target, [])
    e.target_id = f[0]
    e.target_name = f[1]
    e.target_class = f[2]


# ---------------------------------------------------------------- reading

func size() -> int:
    return entries.size()


## Entries visible at a verbosity tier. A tier shows everything at or below it,
## so Story is always included and Debug shows the lot.
func at_tier(tier: int) -> Array:
    var out := []
    for e in entries:
        if e.tier <= tier:
            out.append(e)
    return out


func mistakes() -> Array:
    var out := []
    for e in entries:
        if e.is_mistake():
            out.append(e)
    return out


func for_round(round_no: int) -> Array:
    var out := []
    for e in entries:
        if e.round_no == round_no:
            out.append(e)
    return out


func last_round() -> int:
    var r := 0
    for e in entries:
        r = maxi(r, e.round_no)
    return r


## Total of a numeric field across the log — damage dealt, healing done, and so
## on. Used by the results screen and the balance sweep.
func sum_numbers(verb: int, key: String) -> int:
    var total := 0
    for e in entries:
        if e.verb == verb:
            total += e.number(key)
    return total


## Plain-text transcript at a tier. Used by tests, dev builds and bug reports.
func transcript(tier: int = Enums.LogTier.PLAY_BY_PLAY) -> String:
    var lines: Array[String] = []
    for e in at_tier(tier):
        lines.append(e.describe())
    return "\n".join(lines)


# ---------------------------------------------------------------- persistence

## Golden tests compare this. Deterministic ordering is guaranteed by `sequence`
## being assigned only in emit().
func to_dicts() -> Array:
    var out := []
    for e in entries:
        out.append(e.to_dict())
    return out


func to_json() -> String:
    return JSON.stringify(to_dicts(), "  ")
