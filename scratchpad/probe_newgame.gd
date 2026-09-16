extends SceneTree
## Probe: what does a brand-new guild actually have, on the real boot path?
const ContentDB = preload("res://sim/content/ContentDB.gd")
func _initialize() -> void:
    var SaveGame = load("res://game/core/SaveGame.gd")
    SaveGame.SAVE_DIR = "user://probe_saves"
    var db = ContentDB.load_all()
    print("content ok      = ", db.ok())
    if not db.ok():
        print(db.error_report().substr(0, 1200))
        quit(1); return
    var st = root.get_node_or_null("GameState")
    st.set_content(db)
    st.new_game("Probe Guild")
    print("gold            = ", st.gold)
    print("roster size     = ", st.roster.size())
    print("rank            = ", st.reputation_rank)
    print("tavern_board    = ", st.tavern_board.size(), "  board_rolled=", st.get("board_rolled"))
    var Recruitment = load("res://sim/core/Recruitment.gd")
    print("cost_of(COMMON,1) = ", Recruitment.cost_of(0, 1))
    st.refresh_board()
    print("after refresh_board: board=", st.tavern_board.size(), " gold=", st.gold)
    for c in st.tavern_board:
        print("   cand: ", c.get("name","?"), " rarity=", c.get("rarity","?"), " price=", c.get("price", c.get("cost","?")))
    quit(0)
