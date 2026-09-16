class_name TwgItem
extends RefCounted
## One equippable item.
##
## Field set follows docs/14 §5.3.2, which adopts docs/09 §12.2 field-for-field.
##
## Note the on-disk shape differs slightly from this in-memory shape, on purpose:
## the JSON nests stats under "stats" and carries `tier`/`source` once per file
## rather than per item, because those files are hand-authored and diffed.
## ContentDB normalises on load. Canon VALUES are identical either way.
##
## Eligibility is DERIVED from `family`, never stored (docs/09 §12.4). There is
## exactly one place that knows who can wear what: Enums.FAMILY_CLAIMANTS.

const Enums = preload("res://sim/model/Enums.gd")
const Stats = preload("res://sim/model/Stats.gd")

var id: String = ""
var name: String = ""
var slot: int = -1                # Enums.Slot
var family: int = -1              # Enums.ItemFamily
var tier: int = 0                 # 0 = starting gear
var source: String = ""           # start | tutorial | adventure | raid | vendor | quest
var drop_encounter: int = -1      # 1..5 for raid drops, -1 when not a raid drop
var stats = null                  # TwgStats
## Flat healing component on a healer weapon (docs/08 §8.5). Zero on
## everything else. See the note in the data files for why it exists.
var heal_base: int = 0

var two_handed: bool = false
var canon: bool = true            # false = a PROPOSED stat block, see `note`
var note: String = ""


func _init() -> void:
    stats = Stats.new()


## Classes that can equip this item. Derived, never stored.
func eligible_classes() -> Array:
    return Enums.claimants_of(family)


func can_be_used_by(char_class: int) -> bool:
    return Enums.class_can_use_family(char_class, family)


## How many classes compete for this item — docs/09's "demand".
func demand() -> int:
    return Enums.family_demand(family)


func is_armor() -> bool:
    return slot in Enums.ARMOR_SLOTS


func is_weapon() -> bool:
    return slot == Enums.Slot.MAIN_HAND


func slot_key() -> String:
    return Enums.slot_key(slot)


func family_key() -> String:
    return Enums.family_key(family)


## "Raider's Helm — 5 AC / +5 HP / +1 Power"
func describe() -> String:
    return "%s — %s" % [name, stats.describe()]


func _to_string() -> String:
    return "Item(%s %s)" % [id, stats.describe()]
