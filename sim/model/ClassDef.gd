class_name TwgClassDef
extends RefCounted
## A playable class definition, loaded from data/classes.json.
##
## `head_family` is kept distinct from `body_family` rather than collapsed into
## one "armor family" (docs/14 OQ-6): canon's slot matrix and its item tables
## disagree about the Warrior head slot, and keeping the field separate means
## either reading stays expressible without a data migration. docs/15 BL-19
## resolved the current reading in favour of the item tables.

const Enums = preload("res://sim/model/Enums.gd")

var key: String = ""
var name: String = ""
var index: int = -1               # Enums.CharClass
var role: int = -1                # Enums.Role
var role_group: int = -1          # Enums.RoleGroup
var description: String = ""
var base_hp: int = 0
var primary_stat: int = -1        # Enums.StatKind
var secondary_stats: Array = []   # Array[Enums.StatKind]

var head_family: int = -1
var body_family: int = -1
var main_hand_family: int = -1
var off_hand_family: int = -1     # -1 when the class has no off-hand slot

var two_handed: bool = false
var dual_wield: bool = false


## Which item family fills a given slot for this class, or -1 if the class has
## no such slot. Chest/legs/feet all draw from the body family.
func family_for_slot(slot: int) -> int:
    match slot:
        Enums.Slot.HEAD: return head_family
        Enums.Slot.CHEST, Enums.Slot.LEGS, Enums.Slot.FEET: return body_family
        Enums.Slot.MAIN_HAND: return main_hand_family
        Enums.Slot.OFF_HAND: return off_hand_family
        Enums.Slot.TRINKET: return Enums.ItemFamily.UNIVERSAL_TRINKET
    return -1


## Slots this class can actually fill. Monk, Mage and Wizard have no off-hand.
func available_slots() -> Array:
    var out := []
    for slot in Enums.all_slots():
        if family_for_slot(slot) >= 0:
            out.append(slot)
    return out


func has_off_hand() -> bool:
    return off_hand_family >= 0


func is_healer() -> bool:
    return role_group == Enums.RoleGroup.HEALER


func is_tank() -> bool:
    return role_group == Enums.RoleGroup.TANK


func role_name() -> String:
    return Enums.role_name_of(role)


func _to_string() -> String:
    return "ClassDef(%s %s hp=%d)" % [key, role_name(), base_hp]
