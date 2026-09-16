extends RefCounted
## Finding the autoloads from anywhere, including outside the tree.
##
## `get_node("/root/GameState")` resolves ONLY when the calling node is itself
## inside the scene tree. A SceneTree script — the test runner, anything in
## tools/ — owns the root itself, so nodes parented under it are not "inside the
## tree" and every absolute path silently returns null.
##
## That silence is the problem. A screen looking up its state this way does not
## crash; it renders an empty desk strip and looks like a content bug. This
## helper falls back to the main loop's root so a screen behaves the same in the
## game, in a test and in a tool.
##
## Autoloads are still never referenced by their global identifier (BUILD_STATE
## invariant 7) — this resolves them by name at runtime, which is the safe form.

const GAME_STATE := "GameState"
const SCREEN_ROUTER := "ScreenRouter"


## The autoload named `singleton_name`, or null when it is not registered.
static func find(who: Node, singleton_name: String) -> Node:
    if who != null and who.is_inside_tree():
        var direct := who.get_node_or_null("/root/" + singleton_name)
        if direct != null:
            return direct
    var loop := Engine.get_main_loop()
    if loop is SceneTree:
        var root := (loop as SceneTree).root
        if root != null:
            return root.get_node_or_null(singleton_name)
    return null


static func state(who: Node) -> Node:
    return find(who, GAME_STATE)


static func router(who: Node) -> Node:
    return find(who, SCREEN_ROUTER)
