extends "res://tests/TestCase.gd"
## The Market (docs/02 §6, docs/11 §7).
##
## ✅ CANON: "buy consumables (potions), sell loot, and maybe crafting supplies".
## docs/02 §6.1 calls selling the "primary gold faucet outside mission payouts" and
## §6.3 calls the sell-all helper "the single highest-value convenience in the game",
## so the assertions here are weighted the same way the doc weights the screen.
##
## The one that matters most is
## `test_selling_worn_gear_needs_a_confirm_not_a_refusal`. docs/02 §6.3 asks for a
## "worn by" column "so the player cannot sell equipped gear without a confirm" — a
## model that refused outright would make every raid-tier upgrade unsellable forever,
## and one that sold silently would let a misclick strip a tank.

const Consumables = preload("res://sim/core/Consumables.gd")
const Buildings = preload("res://sim/core/Buildings.gd")
const Comfort = preload("res://sim/core/Comfort.gd")
const Economy = preload("res://sim/core/Economy.gd")
const Enums = preload("res://sim/model/Enums.gd")
const DB = preload("res://sim/content/ContentDB.gd")
const Loot = preload("res://sim/core/Loot.gd")
const GameStateScript = preload("res://game/core/GameState.gd")
const Router = preload("res://game/core/ScreenRouter.gd")
const MarketView = preload("res://game/screens/Market.gd")
const TownScript = preload("res://game/screens/Town.gd")

const MARKET := "res://game/screens/Market.tscn"

var _db = null
var _made: Array = []
var _mounted: Array = []
var _borrowed = null
var _borrowed_content = null

func before_each() -> void:
    if _db == null:
        _db = DB.load_all()
    _made = []
    _mounted = []

func after_each() -> void:
    # Teardown here rather than at the end of each test: a failed assertion aborts
    # the body, and a borrowed autoload left dirty breaks later files in the run.
    if _borrowed != null and is_instance_valid(_borrowed):
        _borrowed.reset()
        _borrowed.content = _borrowed_content
        _borrowed = null
        _borrowed_content = null
    for n in _mounted:
        if is_instance_valid(n):
            if n.get_parent() != null:
                n.get_parent().remove_child(n)
            n.free()
    _mounted = []
    for n in _made:
        if is_instance_valid(n):
            n.free()
    _made = []


# =============================================== docs/11 §7's six SKUs

func test_there_are_exactly_six_consumables_and_the_doc_says_forever() -> void:
    # docs/11 §7: "Same six SKUs at each tier ... No new SKUs at higher tiers — six
    # is the whole list, forever."
    assert_eq(Consumables.SKUS.size(), 6)

func test_the_tier_one_prices_are_the_documented_ones() -> void:
    var rows := [
        ["minor_healing_potion", "Minor Healing Potion", 8],
        ["potion_of_steady_hands", "Potion of Steady Hands", 30],
        ["whetstone_kit", "Whetstone Kit", 35],
        ["mana_draught", "Mana Draught", 35],
        ["rally_flask", "Rally Flask", 40],
        ["guild_feast", "Guild Feast", 60],
    ]
    for row in rows:
        var s := Consumables.sku(String(row[0]))
        assert_false(s.is_empty(), "%s must exist" % String(row[0]))
        assert_eq(String(s["name"]), String(row[1]))
        assert_eq(int(s["price"]), int(row[2]), "%s price" % String(row[1]))
        assert_eq(Consumables.price_at(String(row[0]), 1), int(row[2]),
            "%s at tier 1 must be the printed price" % String(row[1]))

func test_every_consumable_is_pre_raid_a_safety_net_or_post_wipe() -> void:
    # docs/11 §7's binding constraint: "an in-combat reactive consumable ('use when
    # the tank drops') is unbuildable here: there is no 'when'." A fourth kind would
    # mean somebody had forgotten that.
    for id in Consumables.SKUS:
        var kind := Consumables.kind_of(String(id))
        assert_true(kind == Consumables.Kind.SAFETY_NET
            or kind == Consumables.Kind.PRE_RAID
            or kind == Consumables.Kind.POST_WIPE,
            "%s has no valid moment to be spent" % String(id))

func test_price_scales_two_point_four_per_tier_and_effect_one_point_eight() -> void:
    # docs/11 §7: "price x 2.4 per tier, effect x ~1.8 per tier."
    assert_almost(Consumables.PRICE_PER_TIER, 2.4, 0.0001)
    assert_almost(Consumables.EFFECT_PER_TIER, 1.8, 0.0001)

    # 8 G at tier 1 -> 19.2 -> 20 at tier 2, and the curve keeps climbing.
    assert_eq(Consumables.price_at("minor_healing_potion", 2), 20)
    var previous := 0
    for tier in range(1, Consumables.MAX_TIER + 1):
        var price := Consumables.price_at("minor_healing_potion", tier)
        assert_true(price > previous, "tier %d must cost more than tier %d"
            % [tier, tier - 1])
        previous = price

    assert_almost(Consumables.effect_at("minor_healing_potion", 1), 25.0, 0.0001)
    assert_almost(Consumables.effect_at("minor_healing_potion", 2), 45.0, 0.0001)

func test_there_are_six_potion_tiers_named_by_doc_03() -> void:
    # docs/03 §7's market column: Minor / Lesser / Standard / Greater / Major /
    # Perfect. docs/11 §7 confirms they are "placeholders and map onto the Minor
    # Healing Potion line".
    assert_eq(Consumables.TIER_NAMES,
        ["Minor", "Lesser", "Standard", "Greater", "Major", "Perfect"])
    assert_eq(Consumables.MAX_TIER, 6)
    assert_eq(Consumables.display_name("minor_healing_potion", 1),
        "Minor Healing Potion")
    assert_eq(Consumables.display_name("minor_healing_potion", 4),
        "Greater Healing Potion", "the adjective swaps rather than stacking")
    assert_eq(Consumables.display_name("minor_healing_potion", 6),
        "Perfect Healing Potion")

func test_the_stack_cap_is_the_documented_twenty() -> void:
    # docs/11 §7: "Stack cap 20 per SKU, per tier variant. Stops the player
    # pre-buying a whole tier's insurance at Tier 1 prices."
    assert_eq(Consumables.STACK_CAP, 20)

func test_a_tier_beyond_the_last_does_not_invent_a_price() -> void:
    assert_eq(Consumables.price_at("minor_healing_potion", 99),
        Consumables.price_at("minor_healing_potion", Consumables.MAX_TIER))
    assert_eq(Consumables.price_at("does_not_exist", 1), 0)


# =============================================== docs/02 §6.2's shelves

func test_the_stall_is_bought_not_granted() -> void:
    # docs/15 BL-54's correction. docs/02 §6.2 has no cost column, which is why BL-44
    # first read the stall level off reputation — but §11's building table prices the
    # Market's rungs at 130 / 450 / 1,100 G behind rank gates, so it is a purchase.
    assert_eq(Buildings.upgrade_cost("market", 1), 130)
    assert_eq(Buildings.upgrade_cost("market", 2), 450)
    assert_eq(Buildings.upgrade_cost("market", 3), 1100)
    assert_eq(Buildings.upgrade_cost("market", 4), -1, "there is no fifth rung")
    for level in range(1, 5):
        assert_eq(Consumables.stall_level(level), level)

func test_the_rank_caps_what_the_stall_can_be_bought_up_to() -> void:
    # docs/02 §11 gates each rung by rank as well as price, so a rich Unknown guild
    # still shops at a trestle table.
    assert_eq(Consumables.stall_level_cap(Enums.ReputationRank.UNKNOWN), 1)
    assert_eq(Consumables.stall_level_cap(Enums.ReputationRank.KNOWN), 2)
    assert_eq(Consumables.stall_level_cap(Enums.ReputationRank.RESPECTED), 3)
    assert_eq(Consumables.stall_level_cap(Enums.ReputationRank.ESTABLISHED), 4)
    assert_eq(Consumables.stall_level_cap(Enums.ReputationRank.LEGENDARY), 4)
    for rank in range(1, 6):
        assert_true(Consumables.stall_level_cap(rank)
            >= Consumables.stall_level_cap(rank - 1), "a cap must never shrink")

func test_the_stock_rows_are_the_documented_ones() -> void:
    # docs/02 §6.2's "Stock rows" column.
    assert_eq(Consumables.stock_rows(1), 5)
    assert_eq(Consumables.stock_rows(2), 7)
    assert_eq(Consumables.stock_rows(3), 9)
    assert_eq(Consumables.stock_rows(4), 12)

func test_the_comfort_shelf_fills_in_the_documented_order() -> void:
    # docs/02 §6.2's comfort column: L1 Straw Cot, L2 + Hot Meal, L3 + Feather Bed
    # and Trophy Shelf, L4 + Personal Effects.
    assert_eq(Consumables.comfort_catalogue(1), ["straw_cot"])
    assert_eq(Consumables.comfort_catalogue(2),
        ["straw_cot", "hot_meal", "hot_meal_all"])
    var third: Array = Consumables.comfort_catalogue(3)
    assert_true(third.has("feather_bed") and third.has("trophy_shelf"))
    assert_false(third.has("personal_effect"),
        "the Personal Effect is the top shelf")
    assert_true(Consumables.comfort_catalogue(4).has("personal_effect"))

func test_an_unstocked_item_says_so_rather_than_vanishing() -> void:
    # docs/13 §7: a control the player cannot use must say why.
    var blocked := Consumables.stock_blocker("personal_effect", 1)
    assert_true(blocked.contains("Personal Effect"), blocked)
    assert_eq(Consumables.stock_blocker("straw_cot", 1), "")

func test_the_potion_tier_follows_the_rank_rung_by_rung() -> void:
    # Six rank rows in docs/03 §7 against four stall levels in docs/02 §6.2 — the
    # rank is the finer ladder, so it owns the potion tier.
    for rank in range(6):
        assert_eq(Consumables.top_potion_tier(rank), rank + 1)


# =============================================== the live Market

func _state(gold: int = 500):
    var s = GameStateScript.new()
    _made.append(s)
    s.reset()
    s.set_content(_db)
    s.new_game("Market Test")
    s.gold = gold
    return s


func _drop(slot: String = "A2"):
    return Loot.drop_pool(_db.encounter_at_slot(slot), _db)[0]


func test_the_sell_list_carries_the_loot_window_and_everything_worn() -> void:
    # docs/02 §6.3: "Guild inventory with a `worn by` column".
    var s = _state()
    var it = _drop()
    s.pending_loot.append(it)
    var rows: Array = s.sell_rows()
    var pending := 0
    var worn := 0
    for row in rows:
        if String(row["worn_by"]).is_empty():
            pending += 1
        else:
            worn += 1
    assert_eq(pending, 1, "the one unassigned drop")
    assert_true(worn > 0, "and the starting armour everybody is wearing")
    for row in rows:
        assert_eq(int(row["price"]),
            Economy.sell_price(row["item"], s.reputation_rank),
            "every row must carry the price it will actually pay")

func test_selling_worn_gear_takes_it_off_and_pays() -> void:
    var s = _state(0)
    var who = s.roster[0]
    var slot := Enums.Slot.CHEST
    var it = who.item_in(_db, slot)
    assert_true(it != null, "a starting raider is wearing a chest piece")
    var expected := Economy.sell_price(it, s.reputation_rank)

    var paid: int = s.sell_equipped(who.id, slot)
    assert_eq(paid, expected)
    assert_eq(s.gold, expected)
    assert_true(who.item_in(_db, slot) == null, "and they are not wearing it now")

func test_selling_an_empty_slot_pays_nothing() -> void:
    var s = _state()
    var who = s.roster[0]
    s.sell_equipped(who.id, Enums.Slot.CHEST)
    assert_eq(s.sell_equipped(who.id, Enums.Slot.CHEST), 0,
        "the second sale of the same slot finds nothing")

func test_the_sell_all_helper_only_takes_what_nobody_can_wear() -> void:
    # docs/02 §6.3's helper, already built — asserted here because the Market is
    # where it is now reachable from.
    var s = _state(0)
    var junk := Economy.unusable_by(
        Loot.drop_pool(_db.encounter_at_slot("A3"), _db), s.roster)
    for it in junk:
        s.pending_loot.append(it)
    var usable = _drop("A1")
    if not Economy.unusable_by([usable], s.roster).is_empty():
        usable = null
    if usable != null:
        s.pending_loot.append(usable)

    var expected: int = s.unusable_loot_value()
    var paid: int = s.sell_unusable_loot()
    assert_eq(paid, expected, "the preview must equal the payout")
    for it in s.pending_loot:
        assert_true(Economy.unusable_by([it], s.roster).is_empty(),
            "%s can still be worn by somebody, so it must have been kept" % it.name)


# =============================================== docs/02 §6.1's buy-back shelf

func test_a_sale_lands_on_the_shelf_and_can_be_bought_back() -> void:
    # docs/02 §6.1: "Buy-back of the last N sold items ... N = 6. Cheap insurance
    # against a mis-sale; costs 1.25x sale price."
    var s = _state(0)
    var it = _drop()
    s.pending_loot.append(it)
    var paid: int = s.sell_loot(it.id)
    assert_eq(s.sold_recently, [it.id])

    var price: int = s.buy_back_price(it.id)
    assert_eq(price, maxi(1, int(ceil(float(paid) * 1.25))),
        "the markup is what stops buy-back being a free price oracle")
    assert_true(price > paid, "undoing a mistake costs something")

    s.gold = price
    assert_eq(s.buy_back(it.id), "")
    assert_eq(s.gold, 0)
    assert_eq(s.sold_recently, [], "and it leaves the shelf")
    var back := false
    for pending in s.pending_loot:
        if pending.id == it.id:
            back = true
    assert_true(back, "the item is in the loot window again")

func test_the_shelf_holds_six_and_forgets_the_seventh() -> void:
    var s = _state(0)
    var pool: Array = Loot.drop_pool(_db.encounter_at_slot("A3"), _db)
    pool.append_array(Loot.drop_pool(_db.encounter_at_slot("A2"), _db))
    var sold: Array = []
    for it in pool:
        if sold.size() >= 8:
            break
        if sold.has(it.id):
            continue
        s.pending_loot.append(it)
        s.sell_loot(it.id)
        sold.append(it.id)

    assert_true(sold.size() >= 7, "the fixture needs more than a shelf's worth")
    assert_eq(s.sold_recently.size(), s.BUY_BACK_SLOTS)
    assert_eq(s.BUY_BACK_SLOTS, 6, "docs/02 §6.1's N")
    assert_eq(String(s.sold_recently[0]), String(sold[sold.size() - 1]),
        "newest first — the thing just regretted is at the top")
    assert_false(s.sold_recently.has(sold[0]),
        "and the oldest has fallen off")
    assert_true(s.buy_back(String(sold[0])).contains("not on the shelf"))

func test_selling_the_same_item_twice_moves_it_up_rather_than_duplicating() -> void:
    var s = _state(9999)
    var it = _drop()
    s.pending_loot.append(it)
    s.sell_loot(it.id)
    var other = _drop("A3")
    if other.id != it.id:
        s.pending_loot.append(other)
        s.sell_loot(other.id)
    assert_eq(s.buy_back(it.id), "")
    s.pending_loot.append(it)
    s.sell_loot(it.id)
    var seen := 0
    for sid in s.sold_recently:
        if String(sid) == it.id:
            seen += 1
    assert_eq(seen, 1, "one shelf slot, not two")
    assert_eq(String(s.sold_recently[0]), it.id, "and it is back at the front")

func test_buying_back_without_the_gold_is_refused_without_charging() -> void:
    var s = _state(0)
    var it = _drop()
    s.pending_loot.append(it)
    s.sell_loot(it.id)
    s.gold = 0
    var refused := s.buy_back(it.id)
    assert_true(refused.contains("Costs"), refused)
    assert_eq(s.gold, 0)
    assert_eq(s.sold_recently, [it.id], "and it stays on the shelf")

func test_the_shelf_survives_a_save_round_trip() -> void:
    var s = _state(100)
    var it = _drop()
    s.pending_loot.append(it)
    s.sell_loot(it.id)
    var saved: Dictionary = s.to_dict()

    var t = GameStateScript.new()
    _made.append(t)
    t.set_content(_db)
    var problems: Array = t.from_dict(saved)
    assert_eq(problems.size(), 0, "clean round trip: %s" % str(problems))
    assert_eq(t.sold_recently, [it.id],
        "a mis-sale must still be undoable after a reload")


# =============================================== the screen

func _live_state(guild: String, gold: int):
    var loop := Engine.get_main_loop()
    var root: Node = (loop as SceneTree).root if loop is SceneTree else null
    var st = root.get_node_or_null("GameState")
    if st == null:
        st = GameStateScript.new()
        st.name = "GameState"
        root.add_child(st)
        _mounted.append(st)
    else:
        _borrowed = st
        _borrowed_content = st.content
    if root.get_node_or_null("ScreenRouter") == null:
        var rt = Router.new()
        rt.name = "ScreenRouter"
        root.add_child(rt)
        _mounted.append(rt)
    st.reset()
    st.set_content(_db)
    st.new_game(guild)
    st.gold = gold
    return st


func _market() -> Control:
    var loop := Engine.get_main_loop()
    var root: Node = (loop as SceneTree).root if loop is SceneTree else null
    var view := MarketView.new()
    root.add_child(view)
    _mounted.append(view)
    view.build()
    return view


func _labels(n: Node, out: Array = []) -> Array:
    if n is Label:
        out.append((n as Label).text)
    elif n is Button:
        out.append((n as Button).text)
    for c in n.get_children():
        _labels(c, out)
    return out


func _printed(n: Node) -> String:
    return "\n".join(PackedStringArray(_labels(n)))


func _buttons(n: Node, out: Array = []) -> Array:
    if n is Button:
        out.append(n)
    for c in n.get_children():
        _buttons(c, out)
    return out


func _button_named(n: Node, fragment: String):
    for b in _buttons(n):
        if (b as Button).text.contains(fragment):
            return b
    return null


func test_the_town_can_now_walk_into_the_market() -> void:
    # It shipped disabled with "Not built in this version yet."
    var found := false
    for b in TownScript.BUILDINGS:
        if String(b["id"]) == "market":
            found = true
            assert_eq(String(b["scene"]), MARKET)
            assert_eq(String(b["flag"]), "",
                "the Market is canon and not behind a maybe")
    assert_true(found, "the Market must be one of the town's buildings")
    assert_true(ResourceLoader.exists(MARKET), "and its scene must exist")

func test_the_market_opens_on_the_sell_tab_because_that_is_the_faucet() -> void:
    var st = _live_state("Shop Test", 100)
    st.pending_loot.append(_drop())
    var view := _market()
    assert_eq(view.active_tab(), "sell")
    var printed := _printed(view)
    assert_true(printed.contains("Sell all nobody can wear"),
        "docs/02 §6.3's helper must be the first thing on the tab: %s" % printed)
    assert_true(printed.contains("One trestle table"),
        "and the stall must look like an Unknown guild's Market")

func test_the_sell_all_button_previews_the_gold_before_and_after() -> void:
    # docs/02 §6.3's footer: "Gold before → after preview".
    var st = _live_state("Preview Test", 100)
    for it in Loot.drop_pool(_db.encounter_at_slot("A3"), _db):
        st.pending_loot.append(it)
    var view := _market()
    var worth: int = st.unusable_loot_value()
    if worth > 0:
        assert_true(_printed(view).contains("(100 → %d)" % (100 + worth)),
            "the preview must show the actual arithmetic: %s" % _printed(view))

func test_selling_worn_gear_needs_a_confirm_not_a_refusal() -> void:
    # docs/02 §6.3 wants the "worn by" column "so the player cannot sell equipped
    # gear without a confirm". Refusing outright would make raid-tier upgrades
    # unsellable forever; selling silently would let a misclick strip a tank.
    var st = _live_state("Confirm Test", 0)
    var view := _market()
    var who = st.roster[0]

    assert_true(_printed(view).contains("worn by %s" % who.display_name),
        "the column must name who is wearing it: %s" % _printed(view))

    var btn = _button_named(view, "Sell " + String(
        who.item_in(_db, Enums.Slot.CHEST).name))
    assert_true(btn != null, "worn gear is listed and pressable")
    btn.pressed.emit()

    # First press asks; it must NOT have sold.
    assert_eq(st.gold, 0, "nothing sold on the first press")
    assert_true(_printed(view).contains("take it off"),
        "it must ask first: %s" % _printed(view))

    var yes = _button_named(view, "take it off")
    yes.pressed.emit()
    assert_true(st.gold > 0, "and the confirm sells it")

func test_backing_out_of_the_confirm_keeps_the_gear() -> void:
    var st = _live_state("Keep Test", 0)
    var view := _market()
    var who = st.roster[0]
    var it = who.item_in(_db, Enums.Slot.CHEST)
    _button_named(view, "Sell " + String(it.name)).pressed.emit()
    _button_named(view, "Keep it").pressed.emit()
    assert_eq(st.gold, 0)
    assert_true(who.item_in(_db, Enums.Slot.CHEST) != null,
        "they are still wearing it")

func test_the_buy_tab_sells_the_six_skus_at_the_grades_the_rank_reaches() -> void:
    # docs/11 §7: "Same six SKUs at each tier ... six is the whole list, forever." An
    # Unknown guild reaches grade 1 only (docs/02 §6.2, docs/03 §7, docs/15 BL-44).
    var st = _live_state("Buy Test", 500)
    var view := _market()
    _button_named(view, "Buy").pressed.emit()
    assert_eq(view.active_tab(), "buy")

    var printed := _printed(view)
    for id in Consumables.SKUS:
        assert_true(printed.contains(String(Consumables.sku(String(id))["name"])),
            "%s must be on the stall" % String(id))
    assert_true(printed.contains("Minor — 8 G"),
        "with the grade and the price: %s" % printed)
    assert_false(printed.contains("Lesser —"),
        "and no grade an Unknown guild cannot buy")

    var potion = _button_named(view, "Minor — 8 G")
    potion.pressed.emit()
    assert_eq(st.gold, 492)
    assert_eq(st.consumable_count("minor_healing_potion", 1), 1)
    assert_true(_printed(view).contains("1 held"),
        "and the stall remembers what is already in the pack")

func test_a_renowned_guild_is_offered_every_grade_it_has_earned() -> void:
    var st = _live_state("Grades Test", 99999)
    st.reputation_rank = Enums.ReputationRank.RENOWNED
    var view := _market()
    _button_named(view, "Buy").pressed.emit()
    var printed := _printed(view)
    for grade in ["Minor", "Lesser", "Standard", "Greater", "Major"]:
        assert_true(printed.contains(grade + " —"),
            "%s must be for sale at Renowned: %s" % [grade, printed])
    assert_false(printed.contains("Perfect —"),
        "Perfect is Legendary's grade")

func test_the_comfort_tab_sells_what_the_stall_carries_and_no_more() -> void:
    # docs/02 §4.2: comfort items are "bought at the Market (§6)". docs/02 §6.2 gates
    # which ones by stall level, and that gate is the thing this tab adds over the
    # Guildhall's own Facilities tab.
    var st = _live_state("Comfort Test", 9999)
    var view := _market()
    _button_named(view, "Comfort").pressed.emit()
    assert_eq(view.active_tab(), "comfort")

    var printed := _printed(view)
    assert_true(printed.contains("Straw Cot"), "the L1 shelf")
    assert_true(printed.contains("does not carry the Feather Bed"),
        "and everything above it says so rather than vanishing: %s" % printed)

    var cot = _button_named(view, "Straw Cot")
    assert_false(cot.disabled)
    cot.pressed.emit()
    assert_eq(st.gold, 9999 - 40)
    assert_eq(st.roster[0].comfort_floor, 3,
        "and it is placed in the Guildhall, not left in a bag")

func test_a_renowned_guild_sees_the_whole_comfort_shelf() -> void:
    var st = _live_state("Rich Test", 9999)
    st.reputation_rank = Enums.ReputationRank.RENOWNED
    st.market_tier = 4
    st.facility_tier = 3
    for r in st.roster:
        r.backstory_offset = 6
    var view := _market()
    _button_named(view, "Comfort").pressed.emit()
    var printed := _printed(view)
    for id in Comfort.FURNISHINGS:
        assert_true(printed.contains(String(Comfort.furnishing(String(id))["name"])),
            "%s must be on the top shelf" % String(id))
    assert_false(printed.contains("does not carry"),
        "and nothing is out of stock: %s" % printed)

func test_the_market_is_not_a_dead_end_with_an_empty_guild() -> void:
    var st = _live_state("Bare Test", 0)
    st.roster = []
    var view := _market()
    assert_true(_printed(view).contains("Nothing to sell"), _printed(view))
    _button_named(view, "Comfort").pressed.emit()
    assert_true(_printed(view).contains("Nobody to buy for"), _printed(view))

func test_the_market_sells_its_own_upgrade() -> void:
    # docs/02 §11 prices the stall, so the Market is where it is bought. Without this
    # control `market_tier` would be a field nothing can raise and three shelves would
    # be unreachable content.
    var st = _live_state("Stall Test", 1000)
    st.reputation_rank = Enums.ReputationRank.KNOWN
    var view := _market()
    _button_named(view, "Buy").pressed.emit()
    var btn = _button_named(view, "better stall")
    assert_true(btn != null, "the rung must be on the screen: %s" % _printed(view))
    assert_false(btn.disabled)
    btn.pressed.emit()
    assert_eq(st.market_tier, 2)
    assert_eq(st.gold, 870, "130 G per docs/02 §11")

func test_an_unaffordable_stall_says_the_price() -> void:
    var st = _live_state("Poor Stall", 20)
    st.reputation_rank = Enums.ReputationRank.KNOWN
    var view := _market()
    _button_named(view, "Buy").pressed.emit()
    assert_true(_printed(view).contains("Costs 130 G"), _printed(view))
