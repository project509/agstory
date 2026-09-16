class_name TwgStats
extends RefCounted
## A stat block: the five values that can appear on an item or a raider.
##
## Canon (raw notes, *Stat definitions*; ideaboard §2 column headers):
##     AC, HP, Power, Mana, Damage
##
## This type is deliberately dumb. It stores and sums numbers; it does NOT know
## what they mean in a fight. "AC = 2 damage reduction" is an interpretation
## question owned by sim/core/Formulas.gd (docs/08 §3, still OPEN) — putting any
## of that here would spread the unresolved reading across the codebase.
##
## All values are integers. docs/14 §8 requires integer arithmetic for anything
## that gates an outcome, and every canon stat value is a whole number.

## Cross-file reference via preload, NOT via the global class_name registry:
## that registry is populated from .godot/global_script_class_cache.cfg and is
## not reliably available in headless `--script` runs, which made this file fail
## to compile the moment Enums.gd changed. preload resolves at parse time.
const Enums = preload("res://sim/model/Enums.gd")


## Self-reference without the global class registry. A script's own `class_name`
## does not reliably resolve inside a STATIC function in headless runs, which
## broke this file twice; loading by path always works and is cached after the
## first call.
static var _self_script: GDScript = null
static func _cls() -> GDScript:
    if _self_script == null:
        _self_script = load("res://sim/model/Stats.gd")
    return _self_script

var ac: int = 0
var hp: int = 0
var power: int = 0
var mana: int = 0
var damage: int = 0


func _init(p_ac: int = 0, p_hp: int = 0, p_power: int = 0, p_mana: int = 0, p_damage: int = 0) -> void:
    ac = p_ac
    hp = p_hp
    power = p_power
    mana = p_mana
    damage = p_damage


# ---------------------------------------------------------------- arithmetic

## Sum of this block and another, as a new block. Non-mutating.
func add(other):
    return _cls().new(
        ac + other.ac, hp + other.hp, power + other.power,
        mana + other.mana, damage + other.damage
    )


## Add another block into this one. Mutating — use in hot accumulation loops.
func accumulate(other) -> void:
    ac += other.ac
    hp += other.hp
    power += other.power
    mana += other.mana
    damage += other.damage


## Difference, as a new block. Used for gear-swap previews ("+3 AC, -2 Mana").
func subtract(other):
    return _cls().new(
        ac - other.ac, hp - other.hp, power - other.power,
        mana - other.mana, damage - other.damage
    )


## Every stat multiplied by an integer factor.
func scaled(factor: int):
    return _cls().new(ac * factor, hp * factor, power * factor, mana * factor, damage * factor)


func duplicate_stats():
    return _cls().new(ac, hp, power, mana, damage)


## Sum an array of stat blocks. The normal way to total a set of equipment.
static func sum(blocks: Array):
    var out = _cls().new()
    for b in blocks:
        if b != null:
            out.accumulate(b)
    return out


# ---------------------------------------------------------------- access

func get_stat(kind: int) -> int:
    match kind:
        Enums.StatKind.AC: return ac
        Enums.StatKind.HP: return hp
        Enums.StatKind.POWER: return power
        Enums.StatKind.MANA: return mana
        Enums.StatKind.DAMAGE: return damage
    return 0


func set_stat(kind: int, value: int) -> void:
    match kind:
        Enums.StatKind.AC: ac = value
        Enums.StatKind.HP: hp = value
        Enums.StatKind.POWER: power = value
        Enums.StatKind.MANA: mana = value
        Enums.StatKind.DAMAGE: damage = value


func is_empty() -> bool:
    return ac == 0 and hp == 0 and power == 0 and mana == 0 and damage == 0


func equals(other) -> bool:
    if other == null:
        return false
    return (ac == other.ac and hp == other.hp and power == other.power
        and mana == other.mana and damage == other.damage)


# ---------------------------------------------------------------- serialization

## Dictionary form for JSON and save games.
## Zero stats are omitted by default, mirroring the ideaboard's "—" cells: an
## absent key means "this item does not carry that stat".
func to_dict(include_zero: bool = false) -> Dictionary:
    var d := {}
    for kind in Enums.StatKind.values():
        var v := get_stat(kind)
        if v != 0 or include_zero:
            d[Enums.stat_key(kind)] = v
    return d


## Parse a stat dictionary. Unknown keys are reported into `errors` rather than
## ignored — a typo like "armor" instead of "ac" must fail content validation
## loudly, not silently ship an item with no armour on it.
static func from_dict(d: Dictionary, errors: Array = [], context: String = ""):
    var out = _cls().new()
    for key in d.keys():
        var key_str := String(key)
        var kind := Enums.stat_from_key(key_str)
        if kind < 0:
            errors.append("%sunknown stat key '%s' (expected one of %s)"
                % [_ctx(context), key_str, ", ".join(Enums.STAT_KEYS)])
            continue
        var raw = d[key]
        if not (raw is int or raw is float):
            errors.append("%sstat '%s' must be a number, got %s"
                % [_ctx(context), key_str, type_string(typeof(raw))])
            continue
        if raw is float and raw != floor(raw):
            errors.append("%sstat '%s' must be a whole number, got %s"
                % [_ctx(context), key_str, str(raw)])
            continue
        out.set_stat(kind, int(raw))
    return out


static func _ctx(context: String) -> String:
    return "" if context.is_empty() else context + ": "


# ---------------------------------------------------------------- display

## Compact player-facing summary, e.g. "5 AC / +5 HP / +1 Power".
## AC reads bare (it is a rating); the others read as bonuses, matching how the
## ideaboard writes them.
func describe() -> String:
    var parts: Array[String] = []
    if ac != 0:
        parts.append("%d AC" % ac)
    if hp != 0:
        parts.append("%+d HP" % hp)
    if power != 0:
        parts.append("%+d Power" % power)
    if mana != 0:
        parts.append("%+d Mana" % mana)
    if damage != 0:
        parts.append("%+d Damage" % damage)
    if parts.is_empty():
        return "—"
    return " / ".join(parts)


func _to_string() -> String:
    return "Stats(%s)" % describe()
