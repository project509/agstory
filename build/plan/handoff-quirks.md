# handoff — quirks

Exact edits in files the quirk-seam wave did not own. Nothing here is applied.

`game/core/GameState.gd:120` cites this file for one thing specifically: **the
`data/tuning/flags.json` loader and the one line of `Boot.gd` that calls it.** That is §2.
§1 is the doc-side ownership fix `build/plan/q-quirks.md` BL-NEXT+5 asks for, and it must
be ANSWERED before it is applied.

---

## 1. `docs/04-recruitment-and-roster.md` — the quirk spec's owner, and three dead links

**Do not apply §1a until `q-quirks.md` BL-NEXT+5 is answered.** It moves a spec's owner
between two canon docs, which is a designer's call.

### 1a. `docs/04` §11.2's field table (`:494`)

old:

    | `quirk` | record | One class-flavoured mechanical gift; specced in doc 07, named here |

new:

    | `quirk` | record | One class-flavoured mechanical gift; specced in [06 — Classes & Roles](06-classes-and-roles.md) §4, named here |

### 1b. Nothing to do here — the audit's second half is STALE, and checked

Audit item Q58-2's evidence says `docs/04:662-664` carry three dead links
(`07-classes-and-roles.md`, `06-raids-and-encounters.md`,
`11-economy-loot-and-itemization.md`) and that "specced in doc 07" was written under that
numbering. **The links have since been repaired.** `docs/04:661` today reads
"[06 — Classes & Roles](06-classes-and-roles.md) — owns the class kits …, the Legendary
`quirk` field, …" and every target in the block resolves;
`tests/unit/test_docs_links.gd::test_file_links_resolve` is green, which it could not be
otherwise.

That repair is what makes §1a worth doing rather than optional: `docs/04`'s
Related-documents block now says **doc 06** owns the `quirk` field while its own §11.2
table still says **doc 07**, so the doc contradicts itself in two places twelve pages
apart. §1a is the edit that removes the contradiction; BL-NEXT+5 is the ruling that says
which way.

---

## 2. `data/tuning/flags.json` and its loader — `docs/14` §5.2's other half

`docs/14` §5.2 says the flags live in `data/tuning/flags.json`. That directory does not
exist, so `GameState.FLAG_DEFAULTS` is currently the whole truth and `flag_enabled()`
falls through to it for every id. That is correct behaviour and not a bug — but the doc
describes a file, and until the file can be read the doc is describing something that is
not there.

**Shape.** `data/tuning/flags.json`, one object, id → bool. Only ids already declared in
`FLAG_DEFAULTS` are honoured; an unknown key is a collected error, never a new flag.
Declaring in code and defaulting in data is the existing rule and must not be inverted:
"an id is a contract between a screen and a system, and a contract that can be created by
adding a key to a data file cannot be checked" (`GameState.gd:122-124`).

    {
      "_source": "docs/14 §5.2. Ids are declared in GameState.FLAG_DEFAULTS; this file only overrides their default. An id not declared there is an error, not a new flag.",
      "blacksmith": false,
      "crafting": false,
      "salvage": false,
      "level_ups": false,
      "wishlists": false,
      "legendary_quirks": false
    }

**The loader** — a static function on `GameState.gd`, beside `declared_flags()` (`:587`):

    ## docs/14 §5.2's `data/tuning/flags.json`. Overrides the DECLARED defaults and can
    ## never introduce an id: an unknown key is a collected error so a typo fails loudly
    ## instead of silently doing nothing. Never crashes and never calls `push_error` —
    ## the same policy ContentDB states at its own head.
    static func flag_overrides(path: String = "res://data/tuning/flags.json") -> Dictionary:
        var out: Dictionary = {}
        var errs: Array[String] = []
        if not FileAccess.file_exists(path):
            return {"flags": out, "errors": errs}      # absent is legal: the code defaults win
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
        if typeof(parsed) != TYPE_DICTIONARY:
            errs.append("flags: %s is not a JSON object" % path)
            return {"flags": out, "errors": errs}
        for key in (parsed as Dictionary):
            var id := String(key)
            if id.begins_with("_"):
                continue
            if not FLAG_DEFAULTS.has(id):
                errs.append("flags: `%s` is not a declared flag id" % id)
                continue
            out[id] = bool((parsed as Dictionary)[key])
        return {"flags": out, "errors": errs}

**The one line in `game/ui/Boot.gd`**, in the same phase that loads `ContentDB` and before
the first screen is routed:

    # docs/14 §5.2: the declared defaults are the contract; this file only overrides them.
    state.apply_flag_overrides(GameState.flag_overrides())

with the applier next to `set_flag()` (`GameState.gd:580`), so a save's own `flags` block
still wins over the tuning file on load — the tuning file is a build-time default, not a
player setting:

    func apply_flag_overrides(result: Dictionary) -> void:
        for id in (result.get("flags", {}) as Dictionary):
            set_flag(String(id), bool(result["flags"][id]))

**Acceptance.** A test that an unknown key produces exactly one error naming the key and
changes no flag; a test that an absent file leaves every `flag_enabled()` at its
`FLAG_DEFAULTS` value; and — the one that matters — the five golden SHA-256s unchanged with
the file present and every value false.

**Why this is a handoff and not work done here.** `game/core/GameState.gd`,
`game/ui/Boot.gd` and `data/tuning/` are all outside this wave's ownership.

---

## 3. `sim/core/RaidSim.gd` and `sim/core/Mistakes.gd` — the four call sites, still unwired

`sim/core/Quirks.gd`'s four hooks exist and are identity-valued; nothing calls them. Audit
item Q58-4 names the sites, and they are outside this wave's files:

| Hook | Site |
|---|---|
| `threat_multiplier` | `RaidSim.gd:450`, the `Formulas.threat_from` result before `c.add_threat` |
| `relief_bp_bonus` | `RaidSim.gd:705`, folded into `_relief_bp()` |
| `tank_priority` | `RaidSim.gd:228`, `_assign_tanks()` |
| `immune_to` | `Mistakes.eligible_types()` |

**Do not wire them while `Quirks.SPECS` is empty.** Wiring is not free: `RaidSim.run()`
would need the `LegendaryPool` threaded through `db` so a quirk id can be resolved from
`Raider.legendary_def_id`, and every sweep and golden caller uses that argument list. The
seam is deliberately cheaper than that today, and `tests/unit/test_quirks.gd` asserts every
hook is identity at both flag settings, so wiring them later cannot move a golden either.
Do it in the same change as BL-58's spec, not before.
