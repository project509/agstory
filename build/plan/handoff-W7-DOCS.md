# handoff-W7-DOCS — edits in files this unit does not own

Applied by the orchestrator at the wave-7 close (`python tools/apply_handoff.py build/plan/handoff-W7-DOCS.md --dry-run` to parse; W7-DOCS's own commit lands first). Each edit is one ruling's propagation into a file another unit owns this wave or nobody does: docs/11 (unowned), docs/06 (unowned), docs/09 outside §13.1 (unowned), `data/reputation.json` (no unit owns `data/` this wave — the plan says the orchestrator applies it), `sim/core/Comfort.gd` (unowned). None of them changes a number the sim reads. Edits 11-12 (`data/reputation.json`) and 14-15 (`test_reputation.gd`'s two pins on the same strings) are one group and land together; `test_screens.gd:485` reads `contains("Guildhall facility upgrade II")` and survives the longer string.

## 1. docs/11-economy-and-crafting.md:67
Q-39 / Q-61 / Q-68 (RULINGS §2 row 47): the currency is gold, "G", final.
old:
```
| Placeholder name | **Guild Coin**, abbreviated **G** (placeholder — canon names no currency; naming is pending) |
```
new:
```
| Name | **gold**, abbreviated **G** — RULED ([15 Q-61](15-open-questions.md#q-61), 2026-09-15): "G" on chips and prices, "gold" in prose, final; the "Guild Coin" placeholder is retired (the copy lint may carry "no coin / Guild Coin / GC in player-facing strings") |
```

## 2. docs/11-economy-and-crafting.md:112
BL-40: "Buy a round" is cut for 1.0; the S3 row is struck.
old:
```
| S3 | Buy a round | 🔷 (doc 02 §5.1) | 8 G × roster size | Impulse | Discretionary |
```
new:
```
| ~~S3~~ | ~~Buy a round~~ struck — cut for 1.0 ([15 BL-40](15-open-questions.md#bl-40)): 96 G for a +2 that drifts away in two ticks is a trap purchase; the Hot Bath Token is the Indulgence line | — | — | — | — |
```

## 3. docs/11-economy-and-crafting.md:296
BL-40: the §8.3 row is struck with the same reason.
old:
```
| Buy a round (Tavern, doc 02 §5.1) | "small guild-wide morale bump" — doc 05 owns the number | 8 G × roster size (12 raiders → 96 G) |
```
new:
```
| ~~Buy a round (Tavern, doc 02 §5.1)~~ | struck — cut for 1.0 ([15 BL-40](15-open-questions.md#bl-40)); the Hot Bath Token is the Indulgence line | ~~8 G × roster size (12 raiders → 96 G)~~ |
```

## 4. docs/11-economy-and-crafting.md:211
BL-98: wishlists are out of 1.0; §6.3 is tagged post-1.0.
old:
```
### 6.3 The wishlist collision — flagged, not solved
```
new:
```
### 6.3 The wishlist collision — post-1.0 with the module ([15 BL-98](15-open-questions.md#bl-98))
```

## 5. docs/09-items-and-itemization.md:826
BL-98: docs/09 §14.3 is tagged post-1.0 for its wishlist half (the Master Looter with Suggested is Q-11's shipped answer).
old:
```
### 14.3 Recommendation
```
new:
```
### 14.3 Recommendation (the wishlist half is post-1.0 — [15 BL-98](15-open-questions.md#bl-98); the Master Looter with a Suggested button is Q-11's shipped answer)
```

## 6. docs/09-items-and-itemization.md:269
DW-C2 / BL-87: the "2 variables" question is answered in docs/08 §5.3 (Model A+, Focus as a non-gear resource, DECIDED for 1.1).
old:
```
❓ OPEN — that "2 variables or not" question is unresolved canon. It is preserved as OQ-4, not decided here. §10 proposes numbers *conditional* on the single-variable answer.
```
new:
```
RULED — that "2 variables or not" question is answered in [08 §5.3](08-stats-and-formulas.md) ([15 Q-02](15-open-questions.md#q-02) / [BL-87](15-open-questions.md#bl-87)): one gear variable, Mana, on every item record here; Focus is a class-fixed resource that never appears on gear and is DECIDED for 1.1. OQ-4's "one variable: Mana" stands for gear, which is all §10's numbers depend on.
```

## 7. docs/06-classes-and-roles.md:528
DW-C2 / BL-87: docs/06 Q1's default reads docs/08 §5.3's ruling.
old:
```
| Mana drives both spell damage and healing magnitude; no fourth stat. Keep canon's "subject to change" flag until doc 08 lands. |
```
new:
```
| RULED ([08 §5.3](08-stats-and-formulas.md), [15 Q-02](15-open-questions.md#q-02) / [BL-87](15-open-questions.md#bl-87)): Mana drives both spell damage and healing magnitude; no fourth *gear* stat; one class-fixed resource (Focus) that never appears on gear, DECIDED for 1.1 and not in 1.0. |
```

## 8. docs/06-classes-and-roles.md:129
DW-C2: the healer scaling-stat cells stop reading OPEN.
old:
```
| Scaling stat | Mana (❓ OPEN — see Open Questions #1; canon healer weapons are explicitly "mana or power unsure how much"). |
```
new:
```
| Scaling stat | Mana — RULED (Open Questions #1 → [08 §5.3](08-stats-and-formulas.md)); canon's healer weapons ("mana or power unsure how much") carry Mana. |
```

## 9. docs/06-classes-and-roles.md:147
DW-C2: the Druid's scaling-stat cell (anchored with its Failure-mode line, because the Shaman's cell reads the same).
old:
```
| Failure mode | **Fumbled Cast** — the blanket heal does not go out at all this round. Nobody dies from one missed tick; the raid dies from three of them, and the player does not notice until the third. |
| Scaling stat | Mana (❓ OPEN — see #1). |
```
new:
```
| Failure mode | **Fumbled Cast** — the blanket heal does not go out at all this round. Nobody dies from one missed tick; the raid dies from three of them, and the player does not notice until the third. |
| Scaling stat | Mana — RULED (#1 → [08 §5.3](08-stats-and-formulas.md)). |
```

## 13. docs/06-classes-and-roles.md:167
DW-C2: the Shaman's scaling-stat cell.
old:
```
| Failure mode | **Bad Bounce** — the chain starts on a random raider instead of the lowest-HP one. The two medium hops land on people who did not need them and the raider who did need it receives, at best, the small third hop. |
| Scaling stat | Mana (❓ OPEN — see #1). |
```
new:
```
| Failure mode | **Bad Bounce** — the chain starts on a random raider instead of the lowest-HP one. The two medium hops land on people who did not need them and the raider who did need it receives, at best, the small third hop. |
| Scaling stat | Mana — RULED (#1 → [08 §5.3](08-stats-and-formulas.md)). |
```

## 14. tests/unit/test_reputation.gd:522
Q-22: the Legendary row's text moved (edit 12); the pin follows it. Applied together with 11 and 12.
old:
```
    assert_eq(Reputation.town_unlock(Enums.ReputationRank.LEGENDARY), "Guildhall facility upgrade IV")
```
new:
```
    assert_eq(Reputation.town_unlock(Enums.ReputationRank.LEGENDARY),
        "Perfect potions; Legendary raiders, one in twenty")
```

## 15. tests/unit/test_reputation.gd:527
Q-22: Established's filtered text now carries the Market line (edit 11). Applied together with 11 and 12.
old:
```
    assert_eq(Reputation.town_unlock_for_build(Enums.ReputationRank.ESTABLISHED, off),
        "Guildhall facility upgrade II")
```
new:
```
    assert_eq(Reputation.town_unlock_for_build(Enums.ReputationRank.ESTABLISHED, off),
        "Guildhall facility upgrade II; Market expansion")
```

## 10. sim/core/Comfort.gd:258
BL-40: the comment that named "Buy a round" as the Tavern's goes — the row is cut.
old:
```
## docs/11 §8.3 also prices "Buy a round (Tavern, doc 02 §5.1)" at 8 G x roster
## size, but for the delta it says "doc 05 owns the number" and docs/05 §7.4 has no
## such row. That one therefore ships with the Tavern, not here (docs/15 BL-40).
```
new:
```
## "Buy a round" (docs/11 §8.3, doc 02 §5.1) is cut for 1.0 — docs/15 BL-40: a
## 96 G spike that drift erases in two ticks was a trap purchase; the Hot Bath
## Token is the Indulgence line.
```

## 11. data/reputation.json:74
Q-22 (RULINGS §2 row 20): Established's `town_unlock` names the Market's fourth level so the rank-up callout prints it. `Reputation.town_unlock_for_build` still drops the Blacksmith item while its flag is off.
old:
```
      "town_unlock": [
        {"building": "guildhall", "text": "Guildhall facility upgrade II"},
        {"building": "blacksmith", "text": "Blacksmith tier 2"}
      ],
```
new:
```
      "town_unlock": [
        {"building": "guildhall", "text": "Guildhall facility upgrade II"},
        {"building": "market", "text": "Market expansion"},
        {"building": "blacksmith", "text": "Blacksmith tier 2"}
      ],
```

## 12. data/reputation.json:104
Q-22: the Legendary row's phantom "Guildhall facility upgrade IV" (the ladder ends at L4 = Renowned's III) becomes what the rank actually changes (`stock_tier 6`, `find_weights … 50`).
old:
```
      "town_unlock": [
        {"building": "guildhall", "text": "Guildhall facility upgrade IV"}
      ],
```
new:
```
      "town_unlock": [
        {"building": "market", "text": "Perfect potions"},
        {"building": "tavern", "text": "Legendary raiders, one in twenty"}
      ],
```
