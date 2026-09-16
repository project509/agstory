# STAGE — rulings on the fight's picture and sound

_Ruler: STAGE batch, 2026-09-15, under the designer's 2026-09-15 delegation ("you make all of the determinations and decisions left for me, intelligently and based on the game's intended design inspirations"). Rows: 00-plan §6 #23 #26 #27 #29 #30 #42 #46 #67 and §7.1's five STAGE deferrals. Read-only on the tree; this file is the only output. Written as I go._

## Rulings

### #23 — DESIGNER-23 / Q-96 / M4B-CONV-04 / UI q7 / AUDIO Q-F — which arena each fight is in

**Ruling:** Per raid, by kind — `SceneStage.arena_for(encounter)` returns the tier row's `scene` if `data/tier_words.json` names one, else the kind rule: every E-slot (the raid, E1-E5) fights in `stage_arena_dungeon`; every A-slot and both tutorials (A0, TR, A1-A3) fight in `stage_arena_cave`; the same function is the only arena rule in the tree and the bed follows it (#67). The ship default stands.

**Inspiration:** It's A Wipe! makes the raid the real thing and the adventures the errands before it; Octopath gives each dungeon one painted identity for the whole run, never a new room per fight. Canon's raid is "one location, five fights" by its own table (five encounters of one tier's raid), so the dungeon is the raid's place and the cave is everything smaller. Fighting the Tutorial Raid in the cave keeps the dungeon plate as the thing Raid 1 earns — the first real raid should look like a first real raid.

**Canon:** raw notes, Raid Layout: "Encounter 1 (Trash) … Encounter 5 (Main boss of tier)" — one raid, five encounters; Adventure's Board: "Adventure 1 - a few trash encounters and a mini boss / Raid 1 - Explained below". docs/15 Q-96 asks "whether the backdrop belongs to the ENCOUNTER … or to the RAID"; docs/12 §6.3 🔷 "per raid: one painted L0/L1/L2 environment identity, five dressings" already reads the raid as one place. BL-100 (DECIDED) fixes the accessor shape; this row supplies Q-96's answer. Q-54's "alternate as listed" is satisfied for free: adventures are always the cave, raids always the dungeon, so the ladder alternates.

**Cost:** W7-STAGE as planned — `SceneStage.arena_for()`, `ContentDB.tier_scene(tier, kind)`, the three `DEFAULT_ARENA` sites (RaidPrep `_scene()`, RaidView `_stage()`, Results `_scene()`) become handoff lines; `tier_words.json` gains `scene` for tier 1 only (`{"adventure": "stage_arena_cave", "raid": "stage_arena_dungeon"}` — a per-kind pair, so a future tier can point both kinds at one plate). No `backdrop` key on encounter records (Q-96's own proposal is superseded — a per-encounter key is a second truth for a fact the kind already carries). Balance: none. Test: `arena_for()` returns the dungeon for an E-slot record and the cave for A-slots and TR. Strikes Q-96 and closes M4B-CONV-04.

**Register row:** Q-96 — RESOLVED: the arena belongs to the RAID, not the encounter. `SceneStage.arena_for(encounter)` is the one rule: the tier row's `scene` (per kind) if `data/tier_words.json` names it, else raid encounters (E1-E5) in `stage_arena_dungeon` and adventures and tutorials (A0, TR, A1-A3) in `stage_arena_cave`. No `backdrop` key on encounter records; the arena's ambience bed follows the same function (Q-98 (ii)). Tiers 2-5, if mounted, inherit the kind rule until a tier row names a plate — ruled by the loop under the designer's 2026-09-15 delegation.

### #67 — AUDIO Q-F / DESIGNER-23 — the arena bed per encounter or per raid

**Ruling:** The bed follows the arena, never a second mapping — `Audio.BEDS` keys by scene name (`stage_arena_cave` → `amb_cave`, `stage_arena_dungeon` → `amb_dungeon`), and `SceneStage.load()`'s one door plays it, so RaidPrep, RaidView and Results hear the fight's arena because they stand on it. The ship default stands, with one change: the dungeon gets its own bed (the deferral below), so "follows" means the dungeon sounds like a dungeon.

**Inspiration:** Octopath's dungeon has one ambience for the whole crawl; a bed that changed per encounter would tell the player a room changed when the plate did not.

**Canon:** none on sound (docs/_source has no audio word). Q-98 (ii) DECIDED: "the arena bed follows `SceneStage.arena_for()` (Q-96's answer), never a second mapping". #23 above is that answer.

**Cost:** zero beyond W7-AUD-AMB's `BEDS` table — one line per scene JSON name; the door is `handoff-W7-AUD-AMB.md` §1 into `SceneStage.load()`. Test: every `game/assets/scenes/*.json` name resolves to a bed file that exists (`test_audio_beds.gd`).

**Register row:** Q-98 (ii), the arena half — CONFIRMED: the arena's ambience bed is keyed by the scene `SceneStage.arena_for()` returns, through `Audio.BEDS` and the one door in `SceneStage.load()`; there is no per-encounter bed. The cave plays `amb_cave`; the dungeon plays `amb_dungeon` from wave 7 (BL row: the dungeon bed), falling back to `amb_cave` — never the camp — if the fifth bed sheds — ruled by the loop under the designer's 2026-09-15 delegation.

### #26 — DESIGNER-26 / Q01 / UI q1 — figure scale per scene

**Ruling:** As built — `figure_scale` 2 on the camp and both arenas, 1 on the tavern and the market; the tavern does NOT take docs/12 §3.3's 1.5x exception, and the 2x-canvas re-author stays out of 1.0 (its own block below). The ship default stands, because 1.5 is not an integer.

**Inspiration:** Octopath's one inviolable rule is that a sprite's pixels are whole screen pixels — the hard pixel edge against the soft painted plate IS the 2D-HD contrast (docs/12 §2.3). A 1.5x figure under nearest sampling doubles every third texel and shimmers on every walk cycle; under linear it blurs — and "nothing blurry" is the standard this batch is held to. The tavern's small patrons are the right size for its 22px stools; the fix for the joke plate dwarfing them is UI-07's (the plate at `Type.SMALL`, 140px wrap when `figure_scale == 1`), landed by W7-STAGE, not a scale change.

**Canon:** raw notes, Premise: "2D-HD aesthetic similar to *Octopath Traveler*". docs/12 §3.3 (🔷): "Scale: Integer for the base ladder" — the 0.92x back rank and the 1.04x punch-in are its only sanctioned exceptions and neither is a figure's resting scale. spec 11 §1: "nearest sampling of dense art at non-integer scale produces irregular texel doubling — shimmer on every edge". BL-103 (DECIDED) records the 2x/1x split; this row confirms it.

**Cost:** zero. The switch register row (spec 00 §2.7 `figure_scale`) is marked ruled; W9-ART flips nothing. Balance: none.

**Register row:** Q01 — RESOLVED as built: figures stand at the scene's integer — 2 on `stage_camp`, `stage_arena_cave` and `stage_arena_dungeon`, 1 on `stage_tavern` and `stage_market` — because a sprite's pixel must be a whole screen pixel; the tavern takes no 1.5x exception (docs/12 §3.3's allowance is withdrawn for figures: it shimmers under nearest and blurs under linear). The tavern speaker's plate is sized to the 1x figure (UI-07), not the figure to the plate — ruled by the loop under the designer's 2026-09-15 delegation.

### #27 — DESIGNER-27 / Q02 — boss mass: upscale or re-author

**Ruling:** Upscale ok — `marks.boss.scale` goes to 2 on BOTH arenas for EVERY enemy rank (main, mini, elite, trash and the `_2` variants), so the enemy shares the party's pixel pitch; the Main Boss then stands 262 px (155×131 at 2x), the Mini Boss 210, the stone brute 330, the elite 182, trash 164, beside 62-96 px raiders; no re-author in 1.0. This overturns the ship default (1x, "never silently"): the delegation is the "upscale ok" the default was waiting for, and the reasons follow.

**Inspiration:** Octopath never mixes pixel pitches inside one scene — a boss is a bigger canvas at the SAME pitch as the party, and that shared pitch is what makes a 4x-tall boss read as a creature in the same world rather than a painting behind actors. UI-22 measured exactly the seam the mismatch makes: "the party is crunchier than its enemy … reads as a different medium". Concept 2's boss is ~580 px against ~90 px raiders (≈6x); at 2x the Main Boss is ≈3.2x a raider — Octopath's proportion, not the mockup's, and the design wins where the mockup does not fit (memory: reference concepts are a standard). It's A Wipe!'s fight is the twelve against one big thing; a boss smaller than four raiders inverts the silhouette the wipe report is about. The "chunky" warning (spec 07 A1: "scale 2x would read as chunky against 1:1 raiders") had 1:1 raiders as its premise, and the raiders are 2x — the premise is gone. A re-author at ~300 px 1:1 would REOPEN the seam, and no loop tool can paint a 300 px painted-density boss; the dungeon plate's 2x is the honest finish.

**Canon:** raw notes: "2D-HD aesthetic similar to *Octopath Traveler*"; "Really awesome frontend design is a priority." docs/12 §2.1 (🔷): "high-resolution pixel-art sprites, integer-scaled". docs/12 §3.2's "Boss sprite 192 × 192 (tier 1) … Scales up in later tiers" is SUPERSEDED with §3 (spec 00 §1) and binds nothing. BL-103 (DECIDED, wave 6) said "1x … ONLY if the designer writes 'upscale ok'" — the delegation writes it; BL-103's ruling paragraph is amended, not struck.

**Cost:** W7-STAGE (the unit already owns both arena JSONs and `place_boss`): `"scale": 2` in `marks.boss` of `stage_arena_cave.json` and `stage_arena_dungeon.json` (two integers); `RaidView.boss_feet_y()` already scales the plate clearance by `sc` and clamps into `floor`, and `place_boss()` already scales the contact shadow by `w * sc` — no code; the boss mark's x moves so the 2x footprint (up to 400 px wide for `void_colossus_core`) clears the front rank by ≥ 24 px and the lantern sprite entirely (the unit's mark re-author, which it is doing anyway for "in front of the fence"); `tests/unit/test_scene_stage.gd:602` (`anim.scale == Vector2.ONE`) becomes `Vector2(2, 2)` read from the mark, and the party/boss overlap assertion (≤ 25 %) covers the boss too. Damage numbers and `head_of(boss)` follow the frame rect (UI-34). Spec 00 §2.7's `marks.boss.scale` row: default 2, "the other branch" 1. Balance: none — art only. Shot: `RaidView --fixture=raid`, the one look: a boss that fills its floor.

**Register row:** Q02 — RESOLVED: "upscale ok". `marks.boss.scale` is 2 on both arenas for every enemy rank, so every sprite on the arena floor shares one pixel pitch (docs/12 §2.1: integer-scaled; Octopath never mixes pitches); the Main Boss stands 262 px, the Mini Boss 210, beside 2x raiders, in front of the fence with a scaled contact shadow. BL-103 is amended: 1.0 ships the party AND the boss at 2x; a re-author at painted density would reopen the seam UI-22 measured and is not wanted; the 2x-canvas re-author of the families stays post-1.0 — ruled by the loop under the designer's 2026-09-15 delegation.

### #29 — DESIGNER-29 / Q04 — one bubble chrome; the emote map

**Ruling:** One chrome everywhere (Concept 3's dark callout plate, as built), and ONE ten-row emote table behind `SceneStage.EMOTE_MAP` — in the fight a glyph per mistake severity plus downed and the Bard's song; in town three state moods over the authored ambient bubbles — replacing both loose proposals (DESIGNER-29's seven rows and UI-41's ten) with this:

| Glyph | Fight — over the figure the log line names, for the line's dwell | Town — `set_mood()`, one at a time, priority top-down |
|---|---|---|
| `skull` | downed; stays while the figure is down | mood `wipe`: the camp's skull (authored; exists) |
| `heart` | — | mood `cleared`: one new camp bubble; the last result was a clear |
| `sweat` | a MODERATE mistake | mood `at_risk`: the camp's sweat bubble gains the tag; any roster raider below 40 |
| `question` | a MINOR mistake | ambient only (the figure by a locked callout) |
| `anger` | a SEVERE mistake | ambient only |
| `exclaim` | a CRITICAL mistake | ambient only (the Board's post) |
| `note` | the Bard's song lands (over the Bard) | ambient only (the busker, the market) |
| `mug` | — | ambient only (the tavern's patrons) |
| `zzz` | — | ambient only (the sleeper) |
| `dots` | — (the speech plate's "…" is the pause) | ambient only |

**Inspiration:** Canon's roster notation is already an emote vocabulary — ❤️ 🙂 😒 😡 beside a number — and the four fight glyphs are the same ladder read for one mistake instead of one raider: a "?" for the embarrassing one, sweat for the costly one, anger for the one someone dies of, "!" for the one wipes start from. docs/12 §5.3's fumble tell is a "!" over the head; reserving it for CRITICAL keeps the loudest glyph for the loudest line. In town the three moods are the only state the camp can honestly know (the last result and the roster's at-risk end); everything else is the scene author's decor. A bubble that shows sweat over a contented camp lies, so the camp's sweat bubble stops being ambient.

**Canon:** raw notes, Morale: "Natsuna — 87 ❤️ … Bob — 54 🙂 … Greg — 31 😒 … Steve — 14 😡" and "Oh shit, Steve is at 14. Maybe I shouldn't bring him" — the at-risk read is the game; docs/05's bands put "noticeably higher mistake chance" at 30-40 and below, so `at_risk` is morale < 40. `Enums.Severity` has four bands (MINOR / MODERATE / SEVERE / CRITICAL, `Enums.gd:143`) — four fight glyphs, one each. Q17 (DECIDED: the morale faces are the sprite font) is untouched: cards keep the faces; figures get the emotes.

**Cost:** W9-ART (owns `SceneStage.gd` and the emote PNGs): `EMOTE_MAP` as two dictionaries (`FIGHT: severity/event → key`, `MOODS: mood → key`) with the table above recorded in spec 07's emote table; RaidView's `_line_effects` calls `stage.emote(id, EMOTE_MAP.FIGHT[sev])` on a MISTAKE line under the existing `_effects_allowed` gate (the one RaidView line is W9-ART's handoff to that wave's RaidView owner); `Town.gd` picks the mood in priority order (`wipe` if the last result wiped, `cleared` if it cleared, `at_risk` if `roster.any(morale < 40)`, else "") — three lines where it sets `wipe` today; `stage_camp.json`: the sweat bubble gains a fourth entry `"at_risk"`, one heart bubble `[x, y, "emote:heart", "cleared"]` is added (two JSON lines; W9-ART takes the file for them). UI-41's 24px glyphs and `figure_scale` bubble sizing land in the same unit. Balance: none. Test: `test_scene_stage.gd` — every `Severity` has a fight glyph and every mood a bubble on the camp.

**Register row:** Q04 — RESOLVED: one bubble chrome (the dark callout plate) on every scene. `SceneStage.EMOTE_MAP` is the one emote table: in the fight MINOR → `question`, MODERATE → `sweat`, SEVERE → `anger`, CRITICAL → `exclaim`, downed → `skull`, the Bard's song → `note`; in town the camp shows one mood at a time — `wipe` → skull, `cleared` → heart, `at_risk` (any roster raider below 40) → sweat — and every other bubble is the scene author's ambient decor. Canon's ❤️ 🙂 😒 😡 stay the cards' morale faces (Q17) — ruled by the loop under the designer's 2026-09-15 delegation.

### #30 — DESIGNER-30 / Q05 + Q07 — header lockup; overhead bars

**Ruling:** As built — `Frame.LOCKUP = "44_tagline"` (the 44 px mark with "Questionable people. Worse decisions." on every framed screen) and the overhead rule (class badge + pips on every figure, the full HP bar only on the acting or struck figure, the stack hidden on back ranks except that figure — UI-21's extension). The ship default stands: both reports recommended it and the tagline is the designer's own sentence.

**Inspiration:** The tagline is the premise in five words, and It's A Wipe!'s joke belongs on every page; the HP bar on the acting figure only is how Octopath keeps twelve overheads from becoming a spreadsheet on the floor.

**Canon:** raw notes, Direction: "'Really awesome frontend design' is a priority"; Classes: "raid size to be 12". The lockup and bars are 🔷 with no canon number against them.

**Cost:** zero; the two spec 00 §2.7 rows are marked ruled. Balance: none.

**Register row:** Q05 / Q07 — RESOLVED as built: the header lockup is the 44 px mark plus the tagline on every framed screen; overhead bars are badge + pips on every figure with the full HP bar on the acting or struck figure only, the whole stack hidden on back ranks except that one — ruled by the loop under the designer's 2026-09-15 delegation.

### #42 — DESIGNER-42 / Q18 bundle (a-k) / LOOP q6 / UI q6 — the asset-scope bundle

**Ruling:** Ten of the eleven at the ship default and one flipped: **a** `Town.HUB_CTA = "board"` as built · **b** `Icons.WARRIOR_GLYPH = "shield"` (FLIPPED from "swords") · **c** dressings per level — the guild tent is the guildhall, with four states (L1 the patched tent · L2 + a cloth banner · L3 + a second tent and a lantern ring · L4 + a painted sign) and one camp dressing per rank (a pennant at Known, a notice post at Respected, a paved path at Established, a statue at Renowned), all cut from the plate's own pixels — the same default as SCREENS #22 · **d** one figure per class, no re-hue · **e** trip / drop weapon / wrong target, keyed MINOR / MODERATE / SEVERE-and-CRITICAL · **f** a global light · **h** no further glyphs · **i** the role-based VFX default as built · **j** the Raid Group tab retired (hidden in 6, deleted in 10) — the same default as UX's "Raid Group" deferral · **k** the reference density; with #27 upscaling rather than re-authoring, the party bodies stay as sliced.

**Inspiration:** (b) The Warrior's whole identity in canon is the shield — the only class with one — and the badge on twelve overheads exists so the player can find the two tanks at a glance (the "Oh shit, Steve" read, applied to the fight): a tank badge that says "swords" says DPS. Octopath's job icons name the role, not the weapon. The reference's crossed swords are a generic-RPG "warrior" and this is the case where the design wins over the mockup (memory: reference-concepts-are-a-standard). The asset already exists beside the swords. (c) Pillar 1 — the town is the progression bar — is paid in the tent's four states and one prop per rank; the designer's plates are theirs, the dressings are cut from them. (d, f, i, h, k) The loop cannot paint; a re-hue was tried and rejected; a global light is Q-75's own fallback; the log line carries every state a glyph does not. (e) The three generic fumbles docs/12 §5.3 lists before its nine per-class flavours, in severity order: a trip is embarrassing, a dropped weapon costs a round, the wrong target is how someone dies. (j) RaidPrep's strip IS the raid group; a second view is a second truth, and the hub already hides the tab.

**Canon:** raw notes, Classes: "Warrior | Main Tank"; ideaboard §1: Warrior Off Hand "Warrior Shield" — the matrix's only shield; docs/12 §5.1: "the only shield silhouette". Town as progression engine: "the town will be improved by the raids you do … Which will unlock additional things in the town"; Guildhall: "Upgrade guild facilities". BL-106 (DECIDED) fixes d/f/h/i; this row confirms them and rules b, c, e, j, k.

**Cost:** (b) one constant in `game/ui/Icons.gd` (`WARRIOR_GLYPH := "shield"`) and `tests/unit/test_icons.gd:122` asserting `"shield"`; W9-ART owns `Icons.gd` — an S line in that unit; no PNG (the glyph is emitted already). (c) W8-FACILITY exactly as planned — `facility_l1..l4.png`, `dressing_{pennant,post,path,statue}.png`, the `level`/`rank` layer keys; the Facilities card crops the level's layer. (e) W9-ART's three `fumble_*` frames on the actor strips; `FUMBLE_BY_SEVERITY = {MINOR: "trip", MODERATE: "drop", SEVERE: "wrong_target", CRITICAL: "wrong_target"}` in `SceneStage`. (j) W10-DELETE removes the tab and retargets `test_roster_layout.gd:296,:319` and `test_starting_roster.gd:224`. (a, d, f, h, i, k) zero. Balance: none.

**Register row:** Q18 — RESOLVED: a `HUB_CTA = "board"` · b `Icons.WARRIOR_GLYPH = "shield"` — the tank's badge is canon's one shield, not the reference's swords · c the guild tent has four facility states and the camp one dressing per rank, cut from the designer's plate (BL-102) · d one figure per class · e the fumbles are trip (MINOR), drop weapon (MODERATE), wrong target (SEVERE, CRITICAL) · f a global light · h no further glyphs · i the role-based VFX default · j the Raid Group tab is retired · k the party bodies stay at the sliced reference density (the bosses upscale, Q02) — ruled by the loop under the designer's 2026-09-15 delegation.

### #46 — DESIGNER-46 / M6-AUD-05 / AUDIO-09/13 / AUDIO Q-A..Q-E / SHIP q10 — audio: owner, music, the Voice bus, world sound, the WIPE stamp, ambience's slider

**Ruling:** The loop owns audio (everything generated in `tools/audio`, byte-checked, nothing downloaded); ambience rides the **Music** bus under "Audio — music and ambience" (Q-A, as landed); music is the **generated sparse lute** — docs/02 §9.1's own Unknown and Known rows, `tools/audio/gen_music.py`, two loops, on the Music bus under the ambience of the camp family and the main menu, behind `Audio.MUSIC_BED := true` (Q-B (ii), OVERTURNING "no music"); the Voice bus becomes real with **`ui.quill`** — a quill scratch under every log line at live speed, the Settings row returning as "Audio — the scribe" (Q-C, OVERTURNING "retire"); the **world layer stays silent** (Q-D, default); the **WIPE stamp uses `ui.stamp` unjittered** (Q-E, landed at `RaidView.gd:1803`); the three option-interplay defaults and "the clear's sound is the coin" stand. The ensemble, the bell toll, the cheer stinger and the leitmotif are post-1.0 (they are authored things, or one-shots for ranks 1.0 may never reach).

**Inspiration:** Octopath is remembered for its music; a 2D-HD game that opens on a painted night camp in total silence is not in its register, and "really awesome frontend design" includes what the ears get on the first screen. But a generator cannot write a theme, and the reports are right that an arpeggio would be worse than silence — so the ruling takes exactly what docs/02 wrote for the two ranks a 1.0 guild lives in: "sparse lute" and "lute gains a drum". A sparse pluck is a texture, not a tune; the Karplus-Strong string is a physical model of a plucked string, which is the audio direction's own rule ("built from a crude physical model of the object that makes it — NOT an oscillator playing a note", `gen_sfx.py`). The scribe: docs/13 calls the log a document; the empty states already draw a quill (`empty_quill.png`); a scratch under each line arriving IS "the voice of the scribe", the only reading of a phrase the docs never defined that costs nothing and makes the slider true. The fight stays silent between stamps because `ui.stamp` is "the game's signature sound" and failure is the content — hits and heals would bury the mistakes under the noise of competence.

**Canon:** docs/_source has no audio word — everything here is 🔷 or the loop's. docs/02 §9.1 (🔷): Unknown "Wind, one dog, sparse lute" / Known "Lute gains a drum". docs/13 §12.4: "All UI sound is material … No synthesized blips"; "`ui.stamp` is the game's signature sound"; §11.1 the log is a document; §15.1 four buses (Master / Music / UI / Voice) at 100 / 80 / 80 / 100 — unchanged. Q-97 (as built) and Q-98 (DECIDED for the defaults) — Q-98's (i) and (iii) are amended by this row; (ii), (iv), (v) and the three interplay defaults are confirmed. docs/00 §4.4 (5) "all audio original" holds: nothing is downloaded.

**Cost:** W8-AUD-OPT runs — the conditional slot is spent, (a) S + (b) L; if the unit must shed, (b) sheds and is cut for 1.0 in writing. **(b) `tools/audio/gen_music.py`** in `gen_sfx.py`'s shape (numpy + `wave`, seeded per `sha256("music:<rank_bed>")`, `--check`/`--list`/`--out`, one `build_art.sh` block): a Karplus-Strong string (delay `fs/f0`, averaging loop filter, decay 0.996, a pluck-position comb at 0.13 of the delay, two strings per note detuned ±3 cents, a body band-pass at 210 Hz Q 4 mixed at −12 dB); mode A minor pentatonic (A C D E G) from A2 (110 Hz) to A4 (440 Hz); the phrase walker: gaps exponential with mean 2.4 s clamped 0.6-6 s, step ±1 (55 %) / ±2 (25 %) / repeat (10 %) / to the tonic (10 %), 20 % of notes a dyad with the scale's nearest fifth, velocity 0.55-0.9, a rest of 8 s after every 6-10 notes (15 %); Unknown rubato; Known adds the frame drum (a 200 Hz low-passed noise thump, 90 ms decay, beats 1 and 3 of 4/4 at 66 BPM, beat 3 at −6 dB) and quantises the lute's onsets to the eighth grid. Two files: `music_lute_unknown.wav` 90 s, `music_lute_known.wav` 87.27 s (24 bars at 66 BPM, so the drum loops clean), 44.1 kHz mono 16-bit, the tail folded into the head over 600 ms; peak −24 dBFS, RMS ≈ −34 dBFS (under the beds' −30). `Audio.BEDS_MUSIC = {"unknown": …, "known": …}` — rank 0 plays Unknown, ranks 1-5 play Known; `MUSIC_BY_SCENE = {"stage_camp", "stage_town"}` (the camp family and the main menu; the tavern, market and arenas carry ambience only); a second player pair on the Music bus with the beds' 600 ms equal-power crossfade; `Audio.MUSIC_BED := true` is the switch (false = ambience only). `tests/unit/test_audio_music.gd`: both files exist and `--check` AGREEs, the lute plays under `stage_camp` and not under `stage_arena_cave`, the tripwire `test_play_bed_is_a_no_op_because_no_one_owns_the_music_yet` is rewritten to "play_bed plays ambience, and the lute only where MUSIC_BY_SCENE says". **(a) `ui.quill`**: one `PARAMS` entry in `gen_sfx.py` — model `stick_slip`, 85 ms, band 1.8-6 kHz, grain 90 Hz, 3 round-robin variants, peak −27 dBFS (the quietest sound in the game), jitter 0 (§12.4's jitter is the stamp's alone); one `HOOKS` row on the Voice bus; the bind `audio.play("ui.quill", {"live": live})` beside the stamp's in `RaidView._append_line` (a handoff line to W8-KEYS, which owns RaidView that wave); the Settings row returns as `{"key": "audio_voice", "label": "Audio — the scribe", "note": "The quill under each line of the account."}` (a handoff to W8-KEYS); docs/13 §12.4 gains its twelfth row — `ui.quill` | Log line arrival (live speed) | With the line's first pixel; `test_audio_binds.gd`: one `ui.quill` per revealed line at 1x, none at Instant or during a skip. **Docs:** docs/02 §9.1's Audio column amended 🔷 to what ships (Unknown "Fire, night wind, one dog; a sparse lute" / Known "the lute gains a frame drum" / Respected-Legendary "as Known" with the anvil, ensemble, bell, cheer and leitmotif marked post-1.0); `data/credits.json`'s audio line reads "Sound and music: generated from physical models, tools/audio (this project)" (the CREDITS batch's file — flagged). W10-DELETE no longer deletes the Voice row. Balance: none.

**Register row:** Q-98 — AMENDED under the delegation: (i) MUSIC in 1.0 is the generated sparse lute docs/02 §9.1 asked for at Unknown and Known — `tools/audio/gen_music.py`, a Karplus-Strong string on A minor pentatonic, two loops (`music_lute_unknown`, `music_lute_known` with the frame drum), on the Music bus under the camp family's and the main menu's ambience, behind `Audio.MUSIC_BED = true`; the ensemble, the bell toll, the cheer and the leitmotif are post-1.0. (ii) Ambience rides the Music bus ("Audio — music and ambience"), five generated beds through the one door in `SceneStage.load()`. (iii) The Voice bus is "the scribe": `ui.quill`, a quill scratch under every log line at live speed, the twelfth §12.4 hook; the row returns as "Audio — the scribe". (iv) The world layer is silent; (v) the WIPE stamp is `ui.stamp` unjittered; the three interplay defaults and the coin as the clear's sound stand. The owner is the loop; nothing is downloaded — ruled by the loop under the designer's 2026-09-15 delegation.

### §7.1 — Per-tier arenas, boss recolours, icon palettes (docs/16 W3.3 / W3.6) — CONTENT-26, CRITIC-C15

**Ruling:** Stays out of 1.0 — tiers 2-5 (if mounted) fight on the two arenas by #23's kind rule and reuse the Tier 1 boss set and the one icon palette; the `scene` key on the tier row is where a plate goes when one is painted. The ship default (BL-100) stands.

**Inspiration:** Octopath gives every chapter its own place, and that is the bar — but the loop cannot paint a plate, and a `modulate` re-hue of a boss was tried on the figures and rejected (PIPE-16); a tinted sludge maw is the MMO palette-swap It's A Wipe! parodies, and a parody needs to be drawn on purpose, not fall out of a tint.

**Canon:** raw notes, Adventure's Board: "obviously they will need names later, but this is a placeholder" — the tiers' identities are not authored anywhere; docs/12 §8 rule 9. BL-100 (DECIDED).

**Cost:** zero; W9-TIERS's long branch (if CONTENT's #2 mounts tiers) uses `arena_for` unchanged. Flagged to CONTENT.

**Register row:** BL-100 stands: tiers 2-5 share the two arenas by kind (adventures in the cave, raids in the dungeon), the Tier 1 boss set and one icon palette; per-tier plates, recolours and palettes are post-1.0 and land through `tier_words.json`'s `scene` key when painted — ruled by the loop under the designer's 2026-09-15 delegation.

### §7.1 — The 2x-canvas re-author of the party families and the bosses (Q01/Q02) — UI-22, DESIGNER-26/27

**Ruling:** Stays out of 1.0 — 1.0 ships every arena sprite at 2x integer scale (the party by `figure_scale`, the enemies by #27's `marks.boss.scale = 2`); a re-author on a 2x canvas at painted density is post-1.0 and would be commissioned from a person, not a loop.

**Inspiration:** the seam UI-22 measured is closed by one shared pitch, not by more pixels; Octopath's finish is a consistent pitch first and dense art second.

**Canon:** raw notes, Direction: "Aseprite is in the project root; use it heavily for sprite work" — the pipeline exists for a person to do this later; docs/12 §2.1. BL-103 (DECIDED) — its text is amended by #27 ("the boss at 1x" → "the boss at 2x").

**Cost:** zero beyond #27's two integers; BL-103's paragraph and spec 00 §2.7's row are rewritten by W7-DOCS.

**Register row:** BL-103 amended: 1.0 ships the party and every enemy at 2x integer scale on both arenas, the boss in front of the fence with a scaled contact shadow; the 2x-canvas re-author of the four party families and six enemies at painted density is post-1.0 and a person's — ruled by the loop under the designer's 2026-09-15 delegation.

### §7.1 — A per-class VFX family (Q18i), normals (Q18f), more state glyphs (Q18h), HSV busts (Q18d) — DESIGNER-42, PIPE-02/07/16, STAGE-17

**Ruling:** Stays out of 1.0 — the role-based VFX default, a global light, the eight glyphs and one figure per class ship (BL-106 stands; #42 confirms d/f/h/i). One clarification: the nine Legendary busts (CRITIC-M5, CONTENT's #3) are not a rarity re-hue and are not barred by 18d — a Legendary is one named person, and `derive_busts.py`'s hue-and-prop pass is how the five class busts canon does not draw were made.

**Inspiration:** a per-class VFX family is nine drawn things; the role families (attack / support) already tell the reader who acted; Octopath's per-job spell art is the 1.1 bar, not the 1.0 one.

**Canon:** docs/12 §3.4 (🔷): "If doc 14 concludes hand normals are not worth the cost, the fallback is a single global light direction"; §5.4: Legendary "Bespoke, named" portrait. BL-106 (DECIDED).

**Cost:** zero. Flagged to CONTENT (#3) so the bust pass is not read as forbidden by 18d.

**Register row:** BL-106 stands: per-class VFX families, sprite normals, further state glyphs and per-rarity figures are post-1.0; the Legendary busts, if #3 names them, are drawn by `derive_busts.py`'s named pass and are not a rarity tint — ruled by the loop under the designer's 2026-09-15 delegation.

### §7.1 — Music (Q-B), the voice bus's content (Q-C), world/combat sound (Q-D) — AUDIO-09/13, DESIGNER-46, SHIP q10

**Ruling:** Music and the scribe COME INTO 1.0 in wave 8 as unit **W8-AUD-OPT** (a: `ui.quill`, S; b: `gen_music.py`'s lute, L) — #46's ruling; the world layer (hits, spells, heals) stays out of 1.0. The §7.1 row is rewritten: "a generated sparse lute at Unknown/Known on the Music bus and the quill on the Voice bus ship; the ensemble, bell, cheer, leitmotif and the world layer are post-1.0".

**Inspiration / Canon / Cost:** as #46 — the conditional wave-8 slot is spent; if it must shed, the lute sheds first and is cut in writing; the quill is S and does not shed.

**Register row:** see #46 (Q-98 amended) — ruled by the loop under the designer's 2026-09-15 delegation.

### §7.1 — The dungeon and town-aerial ambience beds beyond the camp bed — AUDIO-07, W7-AUD-AMB's table

**Ruling:** The dungeon bed COMES INTO 1.0 in wave 7 as the fifth bed of **W7-AUD-AMB** (`amb_dungeon`: the cave's 40-120 Hz hollow rumble, a chain-creak — `stick_slip` at 2-4 Hz, 1.2 s, every 9-17 s — and a distant stone fall every 20-40 s; no drip; 25 s, the same loop fold), with `amb_cave` as its shed-fallback, never the camp; the aerial bed stays out of 1.0 and `stage_town` (the main menu) plays `amb_camp` by design — the aerial is the guild's own camp from above, and the main menu carries the lute too.

**Inspiration:** Raid 1 is the dungeon's reveal (#23); a campfire crackling under it would tell the ear the plate lied, and Octopath's dungeon has its own low air the moment you enter. The main menu hearing the guild's fire before the player sees it is the right first sound for "you are the guild leader".

**Canon:** none on sound. Q-98 (ii) DECIDED the door and the Music bus; this row adds one bed to its table.

**Cost:** W7-AUD-AMB: one more `gen_amb.py` bed (S — a recombination of the cave's layers plus one `stick_slip` event), `BEDS` = {camp, tavern, market → their own; `stage_arena_cave` → `amb_cave`; `stage_arena_dungeon` → `amb_dungeon`; `stage_town` → `amb_camp` (stated in the table's comment)}; all beds 44.1 kHz mono 16-bit, 25 s, RMS −30 dBFS / peak ≤ −20 dBFS (12 dB under the stamp's −14 peak), 600 ms equal-power crossfade stepped in `_process`. `test_audio_beds.gd`: `--check` prints 5 AGREE; the dungeon bed is not the camp's bytes. Balance: none. W10-BUFFER carries nothing for audio.

**Register row:** BL row (new): five generated ambience beds ship — camp, tavern, market, cave, dungeon — keyed by scene through `Audio.BEDS` and the door in `SceneStage.load()`; the aerial main menu plays the camp bed by design, not as a placeholder; a town-aerial bed is post-1.0 — ruled by the loop under the designer's 2026-09-15 delegation.

## Canon numbers changed

None. docs/_source carries no art scale, no arena, no emote rule and no audio word; every number above is 🔷 or the loop's. Three DECIDED-but-not-canon records are amended, not struck, and W7-DOCS rewrites them:

- **BL-103** — "the boss at 1x" becomes "the party and every enemy at 2x" (#27); spec 00 §2.7's `marks.boss.scale` row: default 2, other branch 1.
- **Q-98 (i) and (iii)** — "no music in 1.0" becomes the generated lute at Unknown/Known behind `Audio.MUSIC_BED`; "the Voice row hidden then deleted" becomes `ui.quill` and the row "Audio — the scribe" (#46). docs/13 §12.4 gains a twelfth hook row; docs/02 §9.1's Audio column is amended 🔷 to what ships.
- **Q-96** — resolved per raid (#23); its own proposal (a `backdrop` key per encounter) is superseded by `arena_for`.
- **spec 00 §2.7** `Icons.WARRIOR_GLYPH` — default "shield", other branch "swords" (#42b); `tests/unit/test_icons.gd:122` follows.

## Tensions

1. **#42c ↔ SCREENS #22 (the town's rank-states).** Ruled to the same default here: one plate, the guild tent's four facility states and one camp dressing per rank, cut from the designer's plate (W8-FACILITY, BL-102). If SCREENS rules three or six designer plates instead, #42c's tent states still stand on whichever plate is the camp — the mechanism (`level`/`rank` layer keys) does not change; only the prop cuts would.
2. **#42j ↔ UX's "Raid Group" deferral (HALL-21 / LOOP-14).** Ruled the same: retire — hidden in wave 6, deleted in wave 10 (W10-DELETE), RaidPrep's strip is the raid group. If UX rules "read-only view", W10-BUFFER builds it from `record_attempt`'s ids and this row's "deleted in 10" becomes "returns in 10"; nothing else here depends on it.
3. **#23 / #67 — one arena rule.** Both rows resolve to the single function `SceneStage.arena_for(encounter)` (tier `scene` per kind, else E-slots dungeon / A-slots and tutorials cave) and `Audio.BEDS` keyed by the scene it returns; no `backdrop` key, no second mapping. CONTENT's #2/#53 (tiers 2-5) inherit it unchanged; CONTENT's #25 (encounter names) does not touch it.
4. **#46 ↔ the CREDITS batch (#5).** `data/credits.json`'s audio line should read "Sound and music: generated from physical models, tools/audio (this project)" — the lute is generated in-tree, so no third-party notice is owed (AUDIO-17); the CREDITS ruler owns the file.
5. **#46 ↔ wave 8 capacity (CRITIC's order).** W8-AUD-OPT's conditional slot is spent (S + L). If the wave sheds, the lute sheds first and is "cut for 1.0, in writing"; the quill (S) does not shed. W8-KEYS receives two handoff lines (the `_append_line` bind, the Settings row).
6. **#27 ↔ COMBAT's rulings on damage numbers / the boss plate.** A 2x boss moves `head_of(boss)` and the number spawn (UI-34's fix already reads the frame rect); the boss plate's clearance is computed by `boss_feet_y` from `sc` — nothing in COMBAT's numbers changes, but W7-STAGE's dungeon marks must clear the front rank by ≥ 24 px with a boss up to 400 px wide.
7. **#29 ↔ COMBAT (the log's MISTAKE line / `_line_effects`).** The fight emote fires from `_line_effects` on a MISTAKE verb by `Severity`; if COMBAT renames or merges severities, the map's keys follow `Enums.SEVERITY_KEYS`.
8. **#42d ↔ CONTENT #3 (Legendary names / busts).** The Legendary busts are a named pass through `derive_busts.py`, explicitly not barred by 18d's "no re-hue"; CONTENT decides whether the names come.
9. **§7.1 per-tier arenas ↔ CONTENT #2.** If CONTENT mounts tiers 2-5, they alternate cave/dungeon by kind with the Tier 1 boss set — no new art is implied by that ruling.
