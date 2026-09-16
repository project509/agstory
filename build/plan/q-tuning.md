# Proposed `docs/15-open-questions.md` entries — the reputation tuning file

> **CONSUMED (W5-DOCS, 2026-09-15):** BL-NEXT+0, +1 and +3 are `docs/15` **BL-81**, with +2 (the scope boundary) and +4 (the derived aliases) folded into its closing paragraph; docs/03 §9's fence is `handoff-tuning.md` §1 and its opening line is §2. `data/reputation.json`'s `_notes` and `sim/core/Reputation.gd`'s two pointers are repointed in `handoff-W5-DOCS.md`. `handoff-tuning.md` §3 (BACKLOG.md:103) is still unapplied.

Written for the tuning extraction (M3-TUNE-01…05). **These are proposals.** `docs/15` was
not edited (house rule 1). Entries continue the **BL** series — these are rulings this
build loop made, not questions awaiting a lead designer.

`data/reputation.json` cites this file three times (`_notes[0]`, `_notes[1]`, `_notes[2]`)
and `sim/core/Reputation.gd` twice (`:30`, `:619`). It was never written, because the agent
that planned it was killed mid-wave; every deviation it was meant to record was already
behind a named constant or a named accessor, and this is that record.

---

## BL-NEXT+0 — `.json`, not `docs/03` §9's `.tres`

**The conflict.** `docs/03` §9 proposes `res://data/reputation.tres`. `BACKLOG.md:103`
says JSON. `docs/14` §5.1 flags the pair as OPEN.

**Ruling: JSON.** `docs/14` §5.1's own deciding row settles it without a preference:

> Readable by `sim/` without breaking §3 — `.tres`: **No**, requires `ResourceLoader`,
> which `sim/` is forbidden to call.

The two consumers are `sim/core/Reputation.gd` and `sim/core/Recruitment.gd`, both pure
sim. A `.tres` reaches them only through a `game/`-side loader that hands the tables in,
which is a second module and a second format to keep in step for no gain.

**What survives of the `.tres` answer.** `docs/15` Q-94's ".tres for tuning singletons"
still holds for the `game/`-side singletons §5.1 lists beside this one — the UI Theme is
the live example. The ruling here is narrow: a table the pure sim reads is JSON.

**Second reason, from §5.1 itself.** "The sweep harness in §9.3 exists precisely to load
*altered* tables thousands of times." A plain `Dictionary` is what an altered table
already is; `Reputation.override_tables()` is that seam and needs no file at all.

---

## BL-NEXT+1 — §9's fence is stale in six places; the file wins, and the fence is corrected

§9's fence was written before `docs/15` BL-35 and BL-37 changed the award tables. Six of
its keys no longer describe the code. Divergence by divergence, with the shipped shape and
the reason it wins. The corrected fence, ready to paste into `docs/03` §9, is
`build/plan/handoff-tuning.md` §1.

**1. Content gate.** §9 has `unlocks_content: Array[StringName]` and
`unlocks_building: Array[StringName]`; the file has `max_raid_tier: int` and
`max_adventure: int`. **The file wins.** `docs/15` §2.3 closed rank→tier gating in
`docs/03` §7's favour and had doc 10 delete its rival table; an id list would re-open it.
`docs/02` owns the building ids §7 never names — see BL-NEXT+3.

**2. Market block.** §9 has `market: {stock_tier, sell_pct, buy_pct}`; the file has
`stock_tier`, `sell_rate` and `consumable_price` flat in the rank row. **The file wins on
the numbers; §9's grouping is dropped.** §9's `_pct` suffix on a fraction is exactly the
misreading `docs/14` OQ-2 exists to prevent, so `sell_rate` keeps the unambiguous name.
`consumable_price` is a multiplier on the buy side, which is what §7's ladder prints
(100/100/95/90/85/80 percent). They sit flat because every other rank column does.

**3. Awards.** §9 has one `awards: Dictionary # encounter_id -> {first, repeat}`; the file
has four tables — `raid_awards` (by slot), `adventure_awards` (by adventure tier),
`tutorial_awards` (by slot), `rung_cumulative` (by rung). **The file wins, and the split is
load-bearing rather than cosmetic.** §6.2 multiplies the raid table by the encounter's tier
and does NOT multiply the adventure table: §6.4's pacing table prices Adventure 2 at 50 —
the §6.1 number unchanged — in the same table where Raid 2 Enc 1-3 is 50 × 2. One
dictionary keyed by encounter id cannot express "this table is tier-scaled and that one is
not". `rung_cumulative` exists because `docs/15` BL-24 makes one board rung one encounter
and BL-37 split one Adventure's award across three of them; §9 predates both.

**4. Full-clear bonus.** §9 has `full_clear_bonus_base: int = 50`; the file has
`full_tier_bonus: [50, 10]`. **The file wins.** `docs/15` BL-35 ruled the bonus pays once
per tier (canon has no lockout clock) and deliberately kept the repeat value in the table —
"unused and documented, so the day a lockout clock lands the value is already sitting
there". A scalar throws the 10 away.

**5. Two omissions.** §9 lists neither `stall_attempts` nor `catchup_enabled`; the file
carries both. **The file wins.** Both are stated in `docs/03` §8.1's own prose (M3's "5+
times without clearing it", and "keep M3 behind a config flag"), both are read live, and §9
simply forgot them. `docs/15` BL-36 is the ruling that ships the flag ON.

**6. Half a rule.** §9 has `pity_threshold: int = 25` and stops; the file adds
`pity_min_rank: 2`. **The file wins.** §8.1 M2 is a two-number rule — "when `pity >= 25` …
Active from **Respected** onward, since Rare does not exist before then" — and half a rule
in a tuning file is worse than none: a designer who moves the threshold cannot move the
rank it starts at.

**Acceptance, and it is now asserted.**
`tests/unit/test_reputation.gd::test_the_shipped_file_carries_exactly_the_documented_schema`
lists the expected top-level and per-rank key sets and fails in both directions — a key in
the file that is not in the list, or a key in the list that is not in the file.

---

## BL-NEXT+2 — the scope boundary: what this file does NOT carry

`BACKLOG.md:103` says "extract reputation *and* recruitment tables". §9's fence names only
`find_weights` and `pity_threshold` from the recruitment side. Four more tuning tables sit
in `sim/core/Recruitment.gd` and belong to other docs.

**Ruling.** `data/reputation.json` carries what `docs/03` owns: `find_weights` (§5.2),
`pity_threshold` and `pity_min_rank` (§8.1 M2), and everything in §6, §7 and §8.1. All of
it is shipped.

What `docs/04` owns stays where it is **for now**, as named constants with this entry as
their note: `COST_BASE` / `COST_PER_TIER` (`docs/04` §3.3), `EXPERIENCE_BANDS`
(`docs/04` §6.2), and `GEAR_RECIPES` / `GRANT_SLOTS` (`docs/03` §4.1 + `docs/04` §6.2 — the
one genuinely shared pair).

**Why not extract them in the same pass.** `BACKLOG.md:103`'s own reason for deferring is
"extracting half a table now means churning it next iteration", and doc 04's cost table is
the one most likely to move when the economy is swept. M3-TUNE-05's recommendation stands:
ship a sibling `data/recruitment.json` when that sweep runs, not before.
`GEAR_RECIPES`/`GRANT_SLOTS` are the arguable pair, and they are left out deliberately — a
`gear` key inside `reputation.json` would put a doc-04 table in a doc-03 file and undo the
boundary this entry draws.

**What this costs today.** `BACKLOG.md:103` cannot be checked off as done. It is half done,
and this entry is the record of which half.

---

## BL-NEXT+3 — `town_unlock` and `market_stock` stay free text

`docs/03` §7's Town-unlock and Market-stock columns are prose ("Blacksmith opens", "Greater
potions"). §9 asks for `unlocks_building: Array[StringName]`.

**Ruling: prose, deferred, not refused.** `docs/02` owns the building ids and `docs/03` §7
never names one, so a structured list would have to invent six sets of ids — house rule 1
forbids exactly that. `Reputation.town_unlock()` and `market_stock()` return the strings §7
prints, and `Reputation.market_stock_tier()` carries the one part of the column that IS
structured (the potion rung `docs/15` BL-44/BL-54 give the rank).

**Revisit when** `docs/02` publishes a building-id table. Until then the honest shape is a
sentence a screen can print, not a list nothing can resolve.

**A real cost, stated.** These two strings are display copy living in a pure-sim module and
they have no non-test caller today (audit item M3-LOOP-03). If M3-LOOP-03 gives them one
and the town screen turns out to want ids, this entry is where the decision was made and
where it should be re-opened.

---

## BL-NEXT+4 — one source per number, and the aliases that are not a second copy

The extraction left three tables in two places at once, with no test that they agreed:
`find_weights` (file **and** `Recruitment.FIND_WEIGHTS`), the pity pair (file **and**
`Recruitment.PITY_THRESHOLD` / `PITY_MIN_RANK`), and M3's pair (file **and**
`Reputation.STALL_ATTEMPTS` / `CATCHUP_ENABLED`). Four comments claimed a test guarded
them. None existed.

**Ruling: the file is the only source.** Every accessor now reads `Reputation.tables()`.
`Recruitment.weights_for()` and `pity_forced_tier()` read the file; `stall_attempts()` and
`catchup_enabled()` keep a literal only as the missing-file fallback, reachable only when
`is_valid()` is already false.

**The five old names survive as DERIVED aliases**, because
`tests/unit/test_recruitment.gd` and `game/core/GameState.gd` read them by name and neither
was owned by this wave. They are `static var`s computed from the file, so they cannot
drift; `build/plan/handoff-debt.md` §1 carries the exact edits that retire them.

**Acceptance.**
`tests/unit/test_reputation.gd::test_no_tuning_number_exists_in_two_places_at_once`
asserts every alias equals the file's value at every rank, and
`test_editing_the_file_moves_the_recruit_roll` proves the designer's edit reaches the
generator — the property the duplicate silently broke.
