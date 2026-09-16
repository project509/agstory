# 00 — Canon reconciliation for the visual overhaul

> **Status:** Decided · **Owner:** Art pass · **Updated:** 2026-09-15 (§2.7, the switch register, W4-HYGIENE)
> **Inputs:** `ideaboard/Reference Concepts/*.png` (the three master references), `docs/_source/lead-designer-notes-raw.md` (canon), docs 12/13/14.

**In one line:** the three reference concepts are the visual target and override every 🔷 PROPOSED aesthetic decision in the docs — but they are AI-generated mockups, and where they contradict ✅ CANON the canon wins and the reference is corrected, never the other way round.

This file exists because the project's rule (BUILD_STATE, memory) is that the designer's raw notes are canon and ambiguities go behind a switch rather than being resolved silently. The references contain several things that are not canon and one thing that is anti-canon. Each is listed here with its resolution so the implementation phase copies the *look* without importing the *errors*.

---

## 1. What the references supersede (and are allowed to)

| Doc | Section | Status there | Resolution |
|---|---|---|---|
| 13 | §2 Design thesis — "the interface is the guild's own paperwork … cheap ledger stock" | 🔷 PROPOSED | **Superseded.** The references are a dark-fantasy dashboard: layered navy panels, bronze/gold borders, crimson commit CTA, illustrated scene viewport. §2.4 explicitly *rejected* "flat modern dark-mode game UI"; that rejection was a proposal and the designer has now chosen otherwise by supplying these references. |
| 13 | §3 Surface tokens (paper/ink/slate/brass) | 🔷 PROPOSED | **Superseded** by `04-palette.md`. `game/ui/Palette.gd` is rewritten; the *role-name* discipline (screens refer to roles, never hexes) is kept because it is what makes the repaint possible at all. |
| 13 | §4 Typography — IM Fell English / EB Garamond / Fira Sans | 🔷 PROPOSED | **Superseded** by `05-typography.md`. The numeral rule (§4.3, tabular figures for stacked numbers) is *kept* — it is a legibility rule, not an aesthetic one. |
| 13 | §2.3 M5 "The desk does not move" (no screen transitions) | 🔷 PROPOSED | **Kept.** Nothing in the references shows a transition, and `ScreenRouter` is built on it. |
| 12 | §3.1 design grid 640×360 art-px, integer scale ladder | 🔷 PROPOSED | **Superseded.** The references are 1536×1024 at 1:1 — dense pixel art authored at display density, not chunky art upscaled. See `11-godot-architecture.md`. |
| 12 | §2 the 2D-HD target (painted depth, hard-edged sprites over soft plates, bloom, atmospherics) | ✅ CANON ("2D-HD aesthetic similar to Octopath Traveler") + 🔷 details | **Kept and served.** The references *are* this target realised. |
| 12 | §4.2 rarity colours | 🔷 PROPOSED | Re-derived from the references' item-slot borders in `04-palette.md`; the five *names* are ✅ CANON and untouched. |

## 2. Where the references are wrong and canon wins

### 2.1 The roster card's morale row

✅ CANON (raw notes, Morale; docs/05 §10.1; docs/13 §8.1) fixes the format:

```
Name — value glyph
Class — State
```

"The number precedes the glyph. The state word is always present. … never abbreviated, never collapsed to a bar, and never replaced by a colour."

The references show `😞 Morale: Low` (Concept 3) and a green *bar* (Concept 1). Both violate canon: "Low" is not a canon band name, there is no number, and a bar is explicitly forbidden.

**Resolution:** the card keeps the reference's *visual language* — face glyph, coloured state word, same row position, same type sizes — but the content is canon's: `Bork — 87 ❤` on line 1 next to the name block, `Warrior — Very Happy` on line 2. The ten band names in `Enums.MORALE_BAND_NAMES` are the only words that may appear. The morale colour ramp from `04-palette.md` colours the state word and glyph; it never replaces them. No bar. The morale number is rendered at least as large as the name (docs/05 §10.3).

### 2.2 The "Ranger" class

The references show Bork/Warrior, Tiny/**Ranger**, Gruk/Cleric, Spoof/Mage. Canon has exactly nine classes (`Enums.CharClass`): Warrior, Monk, Rogue, Cleric, Druid, Shaman, Bard, Mage, Wizard. There is no Ranger and the asset sheets' "Ranger / Berserker / Engineer / Thief" rows are likewise non-canon.

**Resolution:** the reference fixture maps Tiny to **Rogue** (the hooded green archer silhouette is the closest canon read, and Rogue is canon's own "Greg" class). Sprite rows labelled Ranger on the sheets are harvested as Rogue variants; Berserker rows as Warrior/Monk variants; Engineer rows are not used. All nine canon classes need a portrait and a sprite — the sheets cover fewer than nine, which `07`/`08-assets-sheet-*.md` quantify and the production phase fills in Aseprite.

### 2.3 Named bosses and encounters

The references show "The Sludge Maw — Aberration", "The Rotting Spire — Level 18+ · 1–4 Raiders", "Void Colossus 48,532 / 120,000". Canon's Tier 1 content is `Raid 1 — Encounter 1…5` with enemies literally named "Trash", "Elite", "Mini Boss", "Main Boss" (`data/encounters_t1.json`), a fixed 12-raider party, and HP in the thousands, not the hundred-thousands.

**Resolution:** the mission panel renders `display_name` as its title and the encounter `kind` as its subtitle. A **`title`** field is on the encounter schema, *optional*: when present it is shown in the title slot and `display_name` drops to the subtitle. **Ruled ([docs/15 BL-119](../../../docs/15-open-questions.md#bl-119), 2026-09-15):** the 21 boss rungs carry a role title through this field — The Doorman (TR, W7-REPORT) through The Last Word (Raid 5, W9-TIERS) — on the boss plate and the prep card; trash, the ladder words and every enemy log name keep canon's placeholders ("Encounter N"; "Boss N" only as the loot key), so no golden moves. "Level 18+ · 1–4 Raiders" is not reproduced — the party is 12 (✅ CANON) and there are no raider levels in canon's recruitment model, only rarity: **no level is shown** ([BL-135](../../../docs/15-open-questions.md#bl-135), [Q-14](../../../docs/15-open-questions.md#q-14)). `Raider.level` / `xp` stay serialised and unread; the `new` and `play` fixtures carry no level, the reference fixture keeps its four levels as data, and the two dormant `Lv. N` branches are deleted in W10-DELETE.

### 2.4 Four cards, twelve raiders

The references show four roster cards and four combatants. Canon: 12-slot raids, roster cap 15–20 by rank (`GameState.ROSTER_CAP_BY_RANK`). `10-screen-audit.md` owns the concrete resolution (the bottom strip pages / scrolls in fours with the reference card size unchanged; the raid view's combatant strip does the same). The reference's *card* is reproduced pixel-exactly; the *count* is data-driven.

### 2.5 Resources in the header

Concepts 1 and 3 show gold, a purple gem, a "book" 8/12, and a day-clock with time of day. Canon has one currency (gold), no gems, and days without hours. The `8/12`–`12/12` chip is read as roster-fielded / party size (12 ✅ CANON).

**Resolution:** chip 1 = gold; chip 2 = **Reputation points** — the icon is the **rank sigil** (`Frame.REP_ICON = "sigil"`, the existing `rank_<name>.png`), not the gem, and never the word "Rep"; tooltip "N reputation · M more to <rank>" ([docs/15 BL-125](../../../docs/15-open-questions.md#bl-125), 2026-09-15; W9-POLISH lands the constant — the gem stays for trinkets); chip 3 = raiders available / raid size; chip 4 = `Day N` with rank name in place of a clock ("Day 23 · Unknown"), because the day number and rank are the two things the town test already asserts are on screen. The chip chrome is pixel-identical to the reference; the icons on chips 2 and 4 are the two departures.

### 2.6 Nav rail labels

Concept 1: Home, Recruit, Roster, Gear, Missions, Reports, Options. Concept 3: Camp, Roster, Gear, Missions, Reports, Options. Canon's town is five buildings — Guildhall, Tavern, Market, Blacksmith (Maybe), Adventure's Board — and `test_the_town_lists_exactly_the_five_canon_buildings` pins them.

**Resolution:** the rail is a component with a variable item list (the two concepts differ only in list length — `03-concept3-camp-layout.md` measures the pitch). Items map: Home→**Town**, Recruit→**Tavern**, Roster→**Roster** (Guildhall), Gear→**Market**, Missions→**Adventure's Board**, Reports→**Records** (Guildhall records tab), Options→**Settings**. The Blacksmith stays a gated building in the town scene, not a rail item, because canon calls it a "Maybe" and the test pins that gating. Rail label *text* is canon's building names; the rail *chrome* is the reference's.

### 2.7 The switch register — where the overhaul could not decide, and what it did instead

The project's rule (BUILD_STATE, memory) is that an ambiguity the designer has not ruled goes behind a switch at the recommended default, never gets resolved silently. The art/UI overhaul (`build/plan/artaudit/00-plan.md` §0.6) landed thirteen of those. This table is the one place they are listed: the constant that holds each default, the file it lives in, what flipping it does, and the ruling that settled it. **Flip the constant; nothing else** — every switch has both branches built, and a test pins the default. Recorded 2026-09-15 (W4-HYGIENE); **every row below is RULED** (`build/plan/ship/RULINGS.md`, the designer's 2026-09-15 delegation; W7-DOCS wrote the rulings in) — "the other branch" is a recorded alternative, not a pending answer, and where a ruling moved a default the unit that lands the constant is named.

| Switch (file) | Default | The other branch | Ruling |
|---|---|---|---|
| `figure_scale` per scene (`game/assets/scenes/<scene>.json`) | camp / cave / dungeon **2**, tavern / market **1** | any integer; the plate's own props (tents ~210px, stools ~22px) set today's numbers | [BL-103](../../../docs/15-open-questions.md#bl-103): as built — 2 on the camp and both arenas, 1 on the tavern and market; the tavern takes no 1.5x exception (a non-integer shimmers under nearest, blurs under linear) |
| `marks.boss.scale` (the two arena JSONs) | **2** on both arenas for every enemy rank (W7-STAGE; was 1) | `1` — the sliced density; or a re-authored boss at painted density (post-1.0, a person's) | [BL-103](../../../docs/15-open-questions.md#bl-103): "upscale ok" — the Main Boss stands 262 px beside 62-96 px raiders, one pixel pitch on the floor; `test_scene_stage.gd` reads `Vector2(2, 2)` |
| `Guildhall.HALL_FRAMING` (`game/screens/Guildhall.gd`; RaiderDetail/LoadSave/Settings read `Guildhall.framing()`) | `"same"` — the hall family frames the camp exactly as the hub does | `"tight"` — `Guildhall.FRAMINGS`' tighter framing on the big guild tent (TOWN-14's suggestion) so the hall reads as its own place | [BL-124](../../../docs/15-open-questions.md#bl-124): as built — `"same"`, margins-only; the hall is a panel over the camp |
| Bubble chrome (`Widgets.speech_plate` / `PanelBubble`) | one chrome everywhere: Concept 3's dark callout plate | Concept 2's navy plate for the fight; the emote vocabulary beyond "…" | [BL-136](../../../docs/15-open-questions.md#bl-136): one chrome; `SceneStage.EMOTE_MAP` in two halves (fight: MINOR question · MODERATE sweat · SEVERE anger · CRITICAL exclaim · downed skull · the song's note; town moods wipe skull · cleared heart · at_risk sweat) — W9-ART |
| `Frame.LOCKUP` (`game/ui/Frame.gd`; `LOCKUPS` holds the three) | `"44_tagline"` — 44px mark + tagline on every framed screen (Concept 3) | `"58"` (Concept 1, no tagline), `"33_compact"` (the wide-safe fallback) | [BL-137](../../../docs/15-open-questions.md#bl-137): as built — the 44 px mark with "Questionable people. Worse decisions." on every framed screen |
| Overhead bars (`RaidView._bar_ids`, `SceneStage.bar_for`) | badge + pips on every figure; the full HP bar only on the acting and the struck figure | a bar on every figure | [BL-137](../../../docs/15-open-questions.md#bl-137): as built |
| Scene `dof` key / the vignette (`SceneStage.VIGNETTE_SHADER`) | `dof` absent (no blur); the vignette on, hidden by `reduced_effects` | a `dof` layer with a strength, colour grade values per scene | [BL-126](../../../docs/15-open-questions.md#bl-126): off, and none is owed — the plates are 1:1 pixel art and a blur softens the designer's pixels; docs/12 §2.2 row 6 struck |
| Screen transitions (`ScreenRouter.TRANSITION_MS`, W8-KEYS) | **110** — a fade-in of the incoming page, opacity only, ease-out, 0 under `reduced_motion` and under `shot.gd` (was 0) | `0` — no transition; the 6 px tab shift and the wipe's t=1,800 slide are struck either way | [Q-99](../../../docs/15-open-questions.md#q-99): a page changing in place is docs/13 M5's own sentence; no cross-fade, no slide |
| `Town.HUB_CTA` (`game/screens/Town.gd`) | `"board"` — the hub's one crimson control is "Open the board" | `"prep"` — "Go to prep" (pin the next mission and open prep) | [BL-106](../../../docs/15-open-questions.md#bl-106) a: as built — `"board"` |
| `RaidView.EXITS_GATED` (`game/screens/RaidView.gd`) | `false` — the player may leave mid-account | `true` — the first watch is mandatory | [BL-139](../../../docs/15-open-questions.md#bl-139): as built — the exits stay live from round 1 |
| `Results.COMEDY_LINE` (`game/screens/Results.gd`) | `"epigraph"` — the notice's line on every Results page under the eyebrow "The notice said:" (W7-REPORT; was `"as_built"`) | `"as_built"` (beside the tally) / `"promise"` | [BL-139](../../../docs/15-open-questions.md#bl-139): overturned to (b) so the card never claims to report the attempt |
| `Fonts.MORALE_FACE_FONT` (`game/ui/Fonts.gd`) | `true` — the morale faces are the authored sprite font (`faces*.png`) | `false` — the system emoji | [BL-128](../../../docs/15-open-questions.md#bl-128): as built — ten authored faces, never system emoji |
| `Icons.WARRIOR_GLYPH` (`game/ui/Icons.gd`) | `"shield"` — docs/12 §5.1's silhouette (W9-ART flips it; `"swords"` at HEAD until then) | `"swords"` — the reference's crossed swords | [BL-106](../../../docs/15-open-questions.md#bl-106) b: the tank's badge is canon's one shield; a tank badge that says "swords" says DPS |

**Answered (Q13).** The locked Blacksmith callout's blurb reads **"Closed. The smith took a better offer."** (`Town.gd`, final — [docs/15 Q-13](../../../docs/15-open-questions.md#q-13): the building is out of 1.0; the copy lint keeps the lock reason in-world). Q13's second half is ruled too: "Pauline_4" stays exactly as generated — a shape-B handle is the raider's name everywhere and nothing restyles it ([BL-120](../../../docs/15-open-questions.md#bl-120)).

**Not switches, recorded here so nobody looks for one:** the arena belongs to the RAID — `SceneStage.arena_for(encounter)` is the one rule ([Q-96](../../../docs/15-open-questions.md#q-96) RESOLVED, W7-STAGE): the tier row's `scene` if `data/tier_words.json` names it, else E1-E5 in `stage_arena_dungeon` and A0 / TR / A1-A3 in `stage_arena_cave`; no `backdrop` key on encounter records; the ambience bed follows the same function ([BL-138](../../../docs/15-open-questions.md#bl-138)); the Blacksmith stays a locked building, not a rail item (§2.6, §4; out of 1.0 — Q-13); the hall family's plate is the camp by the 2026-09-13 message (not a switch — BL-78). **§2 as a whole is confirmed in canon's favour** ([BL-131](../../../docs/15-open-questions.md#bl-131)): Ranger → Rogue, no creature names or levels from the references, twelve paged cards, "Day N · Rank", canon rail labels.

## 3. Implementation constraints inherited from the test suite

`tests/unit/test_screens.gd` reads screens by walking the tree and collecting **`Label.text` and `Button.text` only**. The rewrite must therefore:

- keep every asserted string ("Test Guild", "60 G", "Day 1", "Roster 0 of 15", "Unknown", the five building names, "Adventure's Board" spelling) in a `Label` or `Button` — not in a `RichTextLabel`, a texture, or a `_draw()` call;
- keep `Town.BUILDINGS` (five entries, same ids/names) and `Widgets.button_with_reason` / `button_of` (disabled-with-reason is asserted);
- keep `Palette.rarity_color()` clamping and `Palette.morale_color()` moving through the at-risk end;
- keep **no pure black (#000000) or pure white (#FFFFFF)** in `Palette.gd` — `test_no_pure_black_or_white_in_the_palette` enforces docs/12 §4.2 rule 4. The references' darkest ground samples near `#0B1118`, so this costs nothing.

1019 tests pass at the start of this pass; that number is the floor for every commit in it.

## 4. Things this pass does not decide

- ~~Whether the 3:2 reference frame letterboxes or extends on 16:9~~ — closed ([docs/15 BL-130](../../../docs/15-open-questions.md#bl-130), W6-SETTINGS): the game opens borderless fullscreen and letterboxes the 1536×1024 frame (`display_aspect = "keep"`, `window_mode = "borderless"`; `F11` / `Alt+Enter` to a window; docs/14 §10.4).
- Whether a Blacksmith rail item appears once the building is built — behind `GameSettings` when it comes up, per the project's switch rule.
- Sound. None of the references imply any; docs/13 §12.4 hook points stand.
