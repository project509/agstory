extends RefCounted
## The save system (docs/14 §7).
##
## docs/14 §7 opens with the reason it is built this carefully, and it is worth keeping
## in front of anyone editing this file: "this game will change every week for months. An
## unversioned save format costs weeks of lost test progress and, worse, produces bug
## reports nobody can trust."
##
## Three of its rules shape everything here:
##
##   §7.2  "Temp file + fsync + atomic rename over the target. An interrupted write must
##         never destroy the previous save."
##   §7.3  "Newer `save_version`: refuse with a clear message. Never partially load."
##   §7.3  "A migration has no sensible mapping — it may DROP a field, never guess a
##         value. Dropping is visible; a guess is not."
##
## Lives in `game/` and not `sim/`, because it reads campaign state and touches the
## filesystem; `sim/` may never depend on either.

const GameStateScript = preload("res://game/core/GameState.gd")
const Enums = preload("res://sim/model/Enums.gd")
const Reputation = preload("res://sim/core/Reputation.gd")

## Where saves live. A variable rather than a constant for one reason, and it is a
## safety one: the autosave triggers mean the TEST SUITE writes saves too, and a suite
## that writes into `user://saves` would overwrite a real player's guild on any machine
## that ran it. `tests/run_tests.gd` points this somewhere disposable — see docs/15 BL-56.
static var SAVE_DIR := "user://saves"

## docs/14 §7.2: "3 guild slots × (1 manual + 3 rotating autosaves)". The rotation is
## the real backstop against a bad migration, so it is not optional.
const SLOTS := 3
const AUTOSAVES_PER_SLOT := 3

## docs/14 §7.1's header, "read WITHOUT parsing the body, so the load menu can show an
## incompatible save instead of crashing on it".
##
## docs/15 BL-55 records the one deviation: this is a single JSON document with a `header`
## key rather than a header line plus a body. Splitting the file would let the head be
## read without the tail, and would cost §7.2's stated first priority — "Plain JSON,
## pretty-printed ... A tester can attach a save to a bug report and an engineer can read
## it". `read_header()` therefore parses the file and returns only the header, and no
## caller ever builds a campaign from a save whose header it has not accepted.
## Keyed by field so a header missing one still reads as the RIGHT TYPE. Defaulting a
## missing key to `null` looked harmless and threw on the first `int()` that touched it,
## which is exactly the crash the header exists to prevent.
const HEADER_DEFAULTS := {
    "save_version": 0, "content_version": 0, "engine_version": "",
    "created_at": "", "played_seconds": 0, "sequence": 0, "guild_name": "",
}

const HEADER_KEYS := ["save_version", "content_version", "engine_version",
    "created_at", "played_seconds", "sequence", "guild_name"]

## The content schema this build authors. Bumped when a data file changes shape, which
## is what triggers §7.3's `reconcile_content`.
const CONTENT_VERSION := 1

## The oldest save shape this build can still migrate from. Everything below it predates
## the migration chain and is refused with a reason rather than half-read — docs/14 §7.3
## asks for migrations "from day one", and this is the honest record that they did not
## exist before v10.
const OLDEST_MIGRATABLE := 10

## docs/14 §7.3: "Migrations are a chain of one-way functions ... one file per step."
##
## The steps live in THIS file rather than in §7.3's `game/autoload/migrations/v7_to_v8.gd`.
## Two reasons, and the second is the one that matters: the save code already lives in
## `game/core/` and nothing else in this project is an autoload-per-file; and every step so
## far is three lines, so a file each would be a directory of headers. The deviation is
## still missing from docs/13 §5's inventory; the write-up was lost with the plan file
## that held it. Audit `M3-SAVE-04` owns the screen, and docs/15 BL-73 is the precedent
## for how a missing §5 row gets propagated when somebody takes it.
##
## A `static var` and not a `const`: a const expression may not hold a Callable, and the
## registry has to hold the steps themselves so `migrate()` can walk them one at a time.
## The last migration walk, as one readable line — printed to the log and kept
## here so a test (and a bug report) can say which chain a save came through.
## "" when the last load needed no walk.
static var last_migration_note: String = ""

static var MIGRATIONS: Dictionary = {
    10: _v10_to_v11,
    11: _v11_to_v12,
    12: _v12_to_v13,
    13: _v13_to_v14,
    14: _v14_to_v15,
    15: _v15_to_v16,
    16: _v16_to_v17,
}


static func slot_path(slot: int) -> String:
    return "%s/slot_%d.json" % [SAVE_DIR, clampi(slot, 0, SLOTS - 1)]


static func autosave_path(slot: int, index: int) -> String:
    return "%s/slot_%d_auto_%d.json" % [
        SAVE_DIR, clampi(slot, 0, SLOTS - 1), index % AUTOSAVES_PER_SLOT]


## Delete every save under the current root. Used by the test runner so one run cannot
## leave state for the next, and never called by the game.
static func purge_all() -> void:
    var dir := DirAccess.open(SAVE_DIR)
    if dir == null:
        return
    for file in dir.get_files():
        dir.remove(file)


static func _ensure_dir() -> void:
    if not DirAccess.dir_exists_absolute(SAVE_DIR):
        DirAccess.make_dir_recursive_absolute(SAVE_DIR)


# ---------------------------------------------------------------- writing

## Write a campaign to one path. Returns "" on success, or a message that names the
## problem — a save that failed silently is worse than one that failed loudly.
##
## docs/14 §7.2's atomic write: the temp file is written and renamed over the target, so
## an interrupted write leaves the PREVIOUS save intact rather than a truncated one.
## `played_seconds` and `sequence` are read off the STATE rather than passed in: a number
## that lives in two places is a number that can disagree with itself, and the header's
## whole job is to describe the body accurately without being parsed alongside it.
static func write_to(path: String, state) -> String:
    if state == null:
        return "There is no guild to save."
    _ensure_dir()

    # A monotonic per-campaign counter, bumped on every write. `created_at` has
    # second resolution, so two saves written in the same second tie — and a load menu
    # that offers the older of two same-second saves is worse than one with no clock at
    # all. This is the tiebreak, and it survives a reload where a tick count would not.
    state.save_counter += 1

    var body: Dictionary = state.to_dict()
    var doc := {
        "header": {
            "save_version": int(body.get("save_version", 0)),
            "content_version": CONTENT_VERSION,
            "engine_version": Engine.get_version_info().get("string", ""),
            "created_at": Time.get_datetime_string_from_system(true),
            "played_seconds": int(state.played_seconds),
            "sequence": int(state.save_counter),
            "guild_name": String(body.get("guild_name", "")),
        },
        "body": body,
    }

    var tmp := path + ".tmp"
    var f := FileAccess.open(tmp, FileAccess.WRITE)
    if f == null:
        return "Could not open %s for writing (error %d)." % [
            tmp, FileAccess.get_open_error()]
    f.store_string(JSON.stringify(doc, "  "))
    # Closing flushes to disk; Godot has no separate fsync, and the rename below is what
    # makes the swap atomic on both Windows and POSIX.
    f.close()

    var err := DirAccess.rename_absolute(
        ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))
    if err != OK:
        # `user://` paths that have not been globalised still rename through DirAccess on
        # some platforms, so try once more before giving up on the write.
        var dir := DirAccess.open(SAVE_DIR)
        if dir == null or dir.rename(tmp.get_file(), path.get_file()) != OK:
            return "Could not replace %s (error %d)." % [path, err]
    return ""


static func save_slot(slot: int, state) -> String:
    return write_to(slot_path(slot), state)


## docs/14 §7.4's rotating autosave. The index rotates so a bad migration or a bad state
## cannot take the only copy with it.
static func autosave(slot: int, index: int, state) -> String:
    return write_to(autosave_path(slot, index), state)


# ---------------------------------------------------------------- reading

## docs/14 §7.1's header read. Returns an empty Dictionary when there is nothing readable
## there, so a load menu can list a slot as damaged rather than crash on it.
static func read_header(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var text := FileAccess.get_file_as_string(path)
    if text.is_empty():
        return {}
    var parsed = JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    var header = parsed.get("header", {})
    if typeof(header) != TYPE_DICTIONARY:
        return {}
    var out: Dictionary = {}
    for key in HEADER_KEYS:
        out[key] = header.get(key, HEADER_DEFAULTS[key])
    return out


## Why this save cannot be loaded, or "" when it can. Checked before anything is built,
## which is docs/14 §7.3's "Never partially load" made structural.
static func incompatibility(path: String) -> String:
    if not FileAccess.file_exists(path):
        return "There is no save there."
    return incompatibility_of(read_header(path))


## The same judgement made from a header ALREADY read. Split out because
## `slot_summaries()` reads twelve headers and used to re-parse each of them twice more
## through `incompatibility()` and `_label_for()` — ~36 full JSON parses per call on a
## screen that calls it after every press. The rule lives here; `incompatibility(path)` is
## the convenience wrapper for callers that hold a path and nothing else.
static func incompatibility_of(header: Dictionary) -> String:
    if header.is_empty():
        return "That save is damaged and cannot be read."
    var version := int(header.get("save_version", 0))
    if version > GameStateScript.SAVE_VERSION:
        return "That guild was saved by a newer build (version %d; this one reads %d)." \
            % [version, GameStateScript.SAVE_VERSION]
    if version < OLDEST_MIGRATABLE:
        return "That guild predates the save format (version %d; the oldest readable is %d)." \
            % [version, OLDEST_MIGRATABLE]
    return ""


## Load a campaign into `state`. Returns an Array of problems; empty means a clean load.
## The first element of a non-empty array is always the reason, so a caller can show one
## line without inspecting the rest.
##
## docs/14 §7.3: a migrated file gets a `.bak` of its PRE-migration self first, because
## the migration is the step most likely to be wrong.
static func load_into(path: String, state) -> Array:
    var problem := incompatibility(path)
    if not problem.is_empty():
        return [problem]

    var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(parsed) != TYPE_DICTIONARY:
        return ["That save is damaged and cannot be read."]
    var body = parsed.get("body", {})
    if typeof(body) != TYPE_DICTIONARY:
        return ["That save has no guild in it."]

    var header := read_header(path)
    var from_version := int(header.get("save_version", 0))
    var problems: Array = []
    last_migration_note = ""
    if from_version < GameStateScript.SAVE_VERSION:
        var backed := _write_backup(path)
        if not backed.is_empty():
            problems.append(backed)
        for gap in chain_gaps(from_version):
            # docs/14 §7.3 wants a chain, not a hole. `migrate()` still hands the body
            # forward — refusing an otherwise-good save because a step is missing would
            # cost the player a guild — but the hole is named rather than passed over,
            # because a RENAMED or RESHAPED field cannot be recovered by `from_dict`'s
            # defaults and would otherwise load as silently wrong.
            problems.append("No migration step is registered for version %d; "
                % gap + "anything that changed shape at that version was defaulted.")
        var migrated = migrate(body, from_version)
        if typeof(migrated) != TYPE_DICTIONARY:
            return ["That guild could not be brought forward from version %d." \
                % from_version]
        body = migrated
        last_migration_note = ("SaveGame: brought '%s' forward from save version %d to %d "
            % [String(header.get("guild_name", "")), from_version,
                GameStateScript.SAVE_VERSION]
            + "(%d steps); the original is at %s.bak"
            % [GameStateScript.SAVE_VERSION - from_version, path])
        print(last_migration_note)

    # docs/14 §7.3's load pseudocode, the line after the migration loop:
    #   if header.content_version != CURRENT_CONTENT: body = reconcile_content(body)
    # Before `from_dict`, so the campaign is built from a reconciled body rather than
    # built and then corrected. The content DB comes off the state because that is the
    # one this build authored; a state with none cannot judge an id, and says so.
    if int(header.get("content_version", 0)) != CONTENT_VERSION:
        var db = state.get("content") if state != null else null
        if db == null:
            problems.append("This guild was saved against a different content set, "
                + "and there is no content loaded to check it against.")
        else:
            problems.append_array(reconcile_content(body, db))

    problems.append_array(rank_canary(body))
    problems.append_array(state.from_dict(body))
    return problems


## docs/14 §7.3's chain, walked one step at a time.
##
## The body is duplicated once, up front, so a step can edit in place without reaching
## back into the caller's dictionary — `migrate()` is called with the parsed save AND
## from tests holding a literal, and mutating either would be a surprise.
static func migrate(body: Dictionary, from_version: int):
    if from_version >= GameStateScript.SAVE_VERSION:
        return body
    var out: Dictionary = body.duplicate(true)
    var v := from_version
    while v < GameStateScript.SAVE_VERSION:
        if not MIGRATIONS.has(v):
            # No step for this version. The doc's rule is that a migration may drop a
            # field but never guess one, so the honest move is to hand the body to
            # `from_dict`, which defaults every field it does not find and reports what
            # it could not restore. `chain_gaps()` is what makes that visible.
            return out
        out = (MIGRATIONS[v] as Callable).call(out)
        if typeof(out) != TYPE_DICTIONARY:
            return null
        v += 1
    return out


## Every version between `from_version` and the current one with no registered step.
## Empty means the chain is complete, which is the state this file is kept in.
static func chain_gaps(from_version: int) -> Array:
    var out: Array = []
    var v := maxi(from_version, OLDEST_MIGRATABLE)
    while v < GameStateScript.SAVE_VERSION:
        if not MIGRATIONS.has(v):
            out.append(v)
        v += 1
    return out


## v10 -> v11: v11 ADDED `tavern_board` and `board_rolled` and changed nothing else.
##
## An added field has no mapping to make, and docs/14 §7.3 forbids inventing one — "it
## may DROP a field, never guess a value". So the step's whole content is the version
## stamp, and `GameState.from_dict`'s defaults do the honest work: `board_rolled` false
## means "this guild has never rolled a board", which is exactly what a v10 save knows.
##
## The step is registered anyway rather than left as a gap, because a gap and a
## deliberate no-op are different facts and only one of them is safe to keep silent.
static func _v10_to_v11(body: Dictionary) -> Dictionary:
    body["save_version"] = 11
    return body


## v11 -> v12: v12 ADDED the two BIG-dumb counters (`wipe_streaks`, `bullet_triggers`,
## `bullet_tier`) and `legendary_warned`. Added fields again, same reasoning as v10 -> v11:
## an absent `wipe_streaks` means "we were not counting", and an empty `legendary_warned`
## means the confirmation has not been shown, which is the safe direction for a warning
## whose whole point is that it never surprises the player.
static func _v11_to_v12(body: Dictionary) -> Dictionary:
    body["save_version"] = 12
    return body


## v12 -> v13: v13 ADDED `skipped_tutorials`, the record of which tutorial rungs the
## player chose to skip under docs/10 §9.3's skippable-with-warning rule. An added
## field again, and the absent-means-nothing reading is the right one twice over: a
## v12 save predates the tutorials existing at all, so nobody skipped anything, and
## `from_dict`'s empty default says exactly that. Guessing the other way would mark a
## returning player as having skipped content they were never offered.
static func _v12_to_v13(body: Dictionary) -> Dictionary:
    body["save_version"] = 13
    return body


## v14 added the completion beat. Nothing to move: `from_dict` defaults
## `completed`, `completed_on_day` and `completion_seen`, and their defaults are
## exactly what a save written before the ending existed means — a guild that
## has not finished Raid 5. The step still exists, because this project's rule
## is that every version has one: a hole in the chain is then always a mistake
## and never a judgement somebody made once and did not write down.
static func _v13_to_v14(body: Dictionary) -> Dictionary:
    body["save_version"] = 14
    return body


## v15 added the three lifetime counters. A stamp, and it has to be: the history
## they record was never written down by an older build, and `from_dict` defaults
## all three to zero, which is the only truthful reading. Seeding them from the
## save's current `gold` or `reputation_points` would reconstruct a number nobody
## measured — and both of those fall when the player spends or disbands, so they
## are not even an upper bound. A guild loaded from v14 starts counting from now,
## which makes docs/11 §11.2's cap generous on that one save and wrong on none.
static func _v14_to_v15(body: Dictionary) -> Dictionary:
    body["save_version"] = 15
    return body


## v16 connected the achievement board. A stamp, and nothing is back-awarded.
##
## A v15 guild that has already cleared Raid 1 does NOT arrive holding
## `prog_raid_1`: `from_dict` defaults the earned set empty and the snapshot-based
## records notice on that guild's very next save point anyway, so nothing is lost
## that can be recovered. What genuinely cannot be recovered is the event-only
## half — "cleared it with nobody dead" is not a fact a save can rediscover — and
## awarding the recoverable records here while silently skipping those would hand
## the player a wall that is wrong in a way nobody could explain. Empty, then
## correct from the next save onward, is the honest shape.
static func _v15_to_v16(body: Dictionary) -> Dictionary:
    body["save_version"] = 16
    return body


## v17 — THE LAST BUMP BEFORE 1.0; the format is frozen here (docs/14 §7.5, ship
## plan W7-SAVE). v17 added docs/14 §7.1's four remaining blocks — `active_run`,
## `log_tail`, `best_rounds`, `pending_deltas` — and the once-flags inside `flags`.
## A stamp, because every one of them defaults to "nothing pending": a v16 save
## was written by a build that never queued a departure across a tick, never
## kept a report to replay and never counted a fastest clear, so empty is the
## truthful reading and anything else would be a guess. Every later persisted
## need lands as a key INSIDE `flags` (declared in `GameState.ONCE_FLAG_DEFAULTS`),
## which the shape test does not enumerate — so no wave after this needs a step.
static func _v16_to_v17(body: Dictionary) -> Dictionary:
    body["save_version"] = 17
    return body


static func _write_backup(path: String) -> String:
    var text := FileAccess.get_file_as_string(path)
    if text.is_empty():
        return ""
    var f := FileAccess.open(path + ".bak", FileAccess.WRITE)
    if f == null:
        return "Could not write a backup before migrating; the save was left alone."
    f.store_string(text)
    f.close()
    return ""


# ---------------------------------------------------------------- reconciliation

## docs/14 §7.3's table row: "Item / class / encounter id no longer exists —
## `reconcile_content` moves the reference to `orphaned[]`, logs it, and continues. Never
## crash, never silently equip nothing."
##
## WHAT IS IN SCOPE, and why it is not everything the body holds. `CONTENT_VERSION` is
## "the content schema this build authors" — the `data/` files ContentDB reads. So the
## three kinds the doc names are exactly the three kinds reconciled here: item ids
## (equipment, `pending_loot`, `sold_recently`), class ids (a raider's `class_id`) and
## encounter ids (`cleared`, `attempts`).
##
## `consumables` and `furnishings` look like inventory and are NOT reconciled: their ids
## come from `Consumables.SKUS` and `Comfort.FURNISHINGS`, which are code constants, not
## `data/`. A content bump cannot invalidate them, and a shape change to either is a
## SAVE_VERSION matter with a migration step — reconciling them here would put one field's
## fate under two different version counters.
##
## Returns one problem line per orphan, and records each in a body-level `orphaned` array
## so the reference is moved rather than deleted (§7.3 non-negotiable 3's spirit: nothing
## a save mentioned is thrown away without a record of it). `orphaned` is not read by
## `from_dict` and is not part of `to_dict()`'s shape; it exists for the bug report.
static func reconcile_content(body: Dictionary, db) -> Array:
    var problems: Array = []
    var orphaned: Array = []

    var roster = body.get("roster", [])
    if typeof(roster) == TYPE_ARRAY:
        for entry in roster:
            if typeof(entry) != TYPE_DICTIONARY:
                continue
            var who := String(entry.get("display_name", entry.get("id", "a raider")))
            var equipment = entry.get("equipment", {})
            if typeof(equipment) == TYPE_DICTIONARY:
                for slot_key in equipment.keys():
                    var item_id := String(equipment[slot_key])
                    if item_id.is_empty() or db.item(item_id) != null:
                        continue
                    # "Never silently equip nothing": the slot is emptied AND said aloud.
                    equipment.erase(slot_key)
                    orphaned.append({"kind": "item", "id": item_id,
                        "where": "%s's %s" % [who, slot_key]})
                    problems.append("%s was wearing %s, which this build no longer has — "
                        % [who, item_id] + "the slot is empty.")
            # A class is NOT dropped. Removing it would leave `from_dict` to pick one,
            # and §7.3's rule is that a migration may drop a field but never guess a
            # value — a raider with a guessed class is a guess wearing a name.
            var class_id := String(entry.get("class_id", ""))
            if not class_id.is_empty() and db.class_by_key(class_id) == null:
                orphaned.append({"kind": "class", "id": class_id, "where": who})
                problems.append("%s is a %s, which this build no longer has — "
                    % [who, class_id] + "the class was kept as written.")

    for field in ["pending_loot", "sold_recently"]:
        var ids = body.get(field, [])
        if typeof(ids) != TYPE_ARRAY:
            continue
        var kept: Array = []
        for raw in ids:
            var item_id := String(raw)
            if db.item(item_id) != null:
                kept.append(item_id)
                continue
            orphaned.append({"kind": "item", "id": item_id, "where": field})
            problems.append("%s held %s, which this build no longer has."
                % [field, item_id])
        body[field] = kept

    for field in ["cleared", "attempts"]:
        var table = body.get(field, {})
        if typeof(table) != TYPE_DICTIONARY:
            continue
        for encounter_id in table.keys():
            if db.encounter(String(encounter_id)) != null:
                continue
            orphaned.append({"kind": "encounter", "id": String(encounter_id),
                "where": field, "value": table[encounter_id]})
            table.erase(encounter_id)
            problems.append("%s records %s, which this build no longer has."
                % [field, encounter_id])

    if not orphaned.is_empty():
        body["orphaned"] = orphaned
    return problems


## docs/14 §7.1's `guild` row: "Rank is derived from RP but stored anyway, and the loader
## asserts they agree — a cheap corruption canary."
##
## THE COMPARISON IS ONE-SIDED, and that is the whole design. docs/03 §6.5 makes rank
## monotonic: a disband costs RP and leaves the rank where it was, so a legitimate save
## can and routinely does carry a rank ABOVE the one its RP would buy. `rank_for_rp()`
## alone would therefore call every post-disband guild corrupt. `rank_after(rp, held)` is
## `max(held, rank_for_rp(rp))`, so it differs from the stored rank in exactly one
## direction: when the stored rank is BELOW what the RP already earned. That cannot happen
## in play, and it is what a hand-edited or half-written save looks like.
##
## The saved rank is KEPT either way — §7.3's "never guess a value". This reports; it does
## not repair.
static func rank_canary(body: Dictionary) -> Array:
    if not body.has("reputation_rank"):
        return []
    var key := String(body.get("reputation_rank", ""))
    var held := Enums.reputation_from_key(key)
    if held < 0:
        # An unknown key is `from_dict`'s problem to report, not a rank/RP disagreement.
        return []
    var rp := int(body.get("reputation_points", 0))
    var expected := Reputation.rank_after(rp, held)
    if expected == held:
        return []
    return ["Rank and reputation disagree: the save says %s at %d points, which is at "
        % [key, rp] + "least %s. The saved rank was kept."
        % Enums.reputation_key(expected)]


# ---------------------------------------------------------------- the load menu

## Every slot, described well enough for a menu row: whether it holds anything, what it
## says, and why it cannot be loaded if it cannot.
static func slot_summaries() -> Array:
    var out: Array = []
    for slot in SLOTS:
        var path := slot_path(slot)
        var header := read_header(path)
        var newest := path
        var newest_header := header
        # An autosave newer than the manual save is what the player actually wants back.
        for i in AUTOSAVES_PER_SLOT:
            var auto_path := autosave_path(slot, i)
            var auto_header := read_header(auto_path)
            if auto_header.is_empty():
                continue
            if newest_header.is_empty() or _is_newer(auto_header, newest_header):
                newest = auto_path
                newest_header = auto_header
        # A file that is present but unreadable is NOT an empty slot, and the
        # difference is the whole reason docs/14 §7.1 reads the header first —
        # "so the load menu can show an incompatible save instead of crashing
        # on it". An empty header from a path that exists means the bytes are
        # there and the JSON is not, so the row says damaged and refuses the
        # load rather than quietly offering a New Guild in its place.
        var damaged := newest_header.is_empty() and FileAccess.file_exists(path)
        out.append({
            "slot": slot,
            "path": path if damaged else newest,
            "exists": not newest_header.is_empty() or damaged,
            "damaged": damaged,
            "guild_name": String(newest_header.get("guild_name", "")),
            "created_at": String(newest_header.get("created_at", "")),
            "sequence": int(newest_header.get("sequence", 0)),
            "save_version": int(newest_header.get("save_version", 0)),
            "blocked": ("That save is damaged and cannot be read." if damaged
                else (incompatibility_of(newest_header) if not newest_header.is_empty()
                else "")),
            "label": _label_for(slot, newest_header),
        })
    return out


## Sequence first, because it cannot tie; the timestamp only breaks a tie between saves
## from different campaigns, which a slot never holds.
static func _is_newer(a: Dictionary, b: Dictionary) -> bool:
    var sa := int(a.get("sequence", 0))
    var sb := int(b.get("sequence", 0))
    if sa != sb:
        return sa > sb
    return String(a.get("created_at", "")) > String(b.get("created_at", ""))


## Reads the header it is handed rather than the file again — see `incompatibility_of`.
static func _label_for(slot: int, header: Dictionary) -> String:
    if header.is_empty():
        return "Slot %d — empty" % (slot + 1)
    var blocked := incompatibility_of(header)
    if not blocked.is_empty():
        return "Slot %d — %s" % [slot + 1, blocked]
    var played := int(header.get("played_seconds", 0))
    return "Slot %d — %s, %s" % [slot + 1,
        String(header.get("guild_name", "a guild")), played_words(played)]


## How long this save has been played, in words. Public because the completion
## screen (S17) prints the same number and two phrasings of it would drift.
static func played_words(seconds: int) -> String:
    if seconds < 60:
        return "just started"
    var minutes := seconds / 60
    if minutes < 60:
        return "%d minute%s in" % [minutes, "" if minutes == 1 else "s"]
    var hours := minutes / 60
    return "%d hour%s in" % [hours, "" if hours == 1 else "s"]


## Whether anything at all is loadable, for the main menu's Continue.
static func has_any_save() -> bool:
    for row in slot_summaries():
        if bool(row["exists"]) and String(row["blocked"]).is_empty():
            return true
    return false


## The slot Continue should open: the most recently written loadable one.
static func newest_loadable() -> Dictionary:
    var best: Dictionary = {}
    for row in slot_summaries():
        if not bool(row["exists"]) or not String(row["blocked"]).is_empty():
            continue
        if best.is_empty() or int(row["sequence"]) > int(best["sequence"]) \
                or (int(row["sequence"]) == int(best["sequence"])
                    and String(row["created_at"]) > String(best["created_at"])):
            best = row
    return best


## Remove a slot and its rotation. Used by the menu, and by tests that must not leave a
## save behind for the next test to find.
static func erase_slot(slot: int) -> void:
    var paths := [slot_path(slot), slot_path(slot) + ".bak"]
    for i in AUTOSAVES_PER_SLOT:
        paths.append(autosave_path(slot, i))
        paths.append(autosave_path(slot, i) + ".bak")
    for path in paths:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
