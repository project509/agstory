# SCREENS rulings — the town, the chrome, motion, display and accessibility

> Ruled by the loop under the designer's 2026-09-15 delegation. Rows: #22 #24 #28 #31 #32 #33 #40 #41 #43 #44 #45, and the §7.1 deferrals Town rank-states / aerial figures / plates (M3-LOOP-06, M4B-ACT-04), region-masked diff (m4t-06), `prose_font_swap` (Q16).
> Sources: docs/_source (canon), build/plan/ship/00-plan.md §6/§7.1, DESIGNER.md, UI.md, LOOP.md, SHIP.md, CRITIC.md, audit.json, docs/12, 13, 02, 03, 15, art/ref/specs/00, 04, 05, 09.

## Rulings

### #22 — DESIGNER-22 / M3-LOOP-06 / LOOP-20 — Town rank-states: plates or dressings?

**Ruling:** One camp plate, six rank dressings (the ship default), with the six states fixed here as data on the mechanism `stage_camp.json` already has — walkers, lantern flames, props — so that every rank adds at least three deltas and Unknown → Known is felt; no second or sixth plate in 1.0.

**Inspiration:** It's A Wipe! never changes its town at all — the town-as-progression-bar is ours (docs/00 Pillar 1, canon: "make the town itself your progression engine"), so what must be true is that the town *visibly* changes at every rank, not that six paintings exist. Octopath's towns change by what is *in* them (people, lights, banners) over one painted plate — the additive-layer model is the Octopath model. The designer's 2026-09-13 ruling made the camp the guild's home (BL-78); a second plate would move the desk.

**Canon:** raw notes, *Town as progression engine*: "the town will be improved by the raids you do. Mostly by gaining reputation levels." and *Guild Reputation*: "Reputation determines what starts appearing around town." — "appearing around town" is additive dressing, in the designer's own words. docs/02 §9.1's six rows are 🔷 PROPOSED; §2.1 R2 (≥ 3 deltas per rank) and R5 (rank from a screenshot) are the acceptance bar and both are met by the table below. The memory rule (reference concepts set the bar) forbids the loop *painting* five plates; it does not forbid gating the plate's own life by rank.

The six dressings (every layer gated `rank >= N` in `stage_camp.json`; props cut from the plate's or the sheets' own pixels through `patch_plate.py` / `lib.lua`, never painted):

| Rank | Walkers on paths | Lantern flames lit (of 10) | Props added at this rank |
|---|---|---|---|
| 0 Unknown | 0 | 6 | none — the two shipped banner props hidden (a camp nobody has heard of) |
| 1 Known | 1 | 8 | the two banner props return; one cloth pennant on the big guild tent |
| 2 Respected | 2 (the shipped scene) | 10 | a notice post beside the Board callout; the pennant takes the crest colour |
| 3 Established | 3 | 10 | a cobble band on the main path (`patch_plate.py`); a pennant line of 5 between the two big tents |
| 4 Renowned | 4 | 10 + 2 brazier flames (`fire_camp` at 1x) | a second guild tent (a patch copy of the big tent); two `knight_unlabelled` actors flanking it |
| 5 Legendary | 5 | 10 + 4 braziers | a stone statue (one idle warrior frame, desaturated, on a 24×10 plinth) in the square; crest pennants on all four tents |

**Cost:** `stage_camp.json` gains `rank` gates on `paths`, the flame `props` and the `lights` they sit on, plus three new path point-lists and the seven props above; `SceneStage` reads `state.reputation_rank` through the layer-key model W8-FACILITY builds; `test_scene_stage.gd` asserts rank 0..5 shows exactly the table; `test_town.gd` asserts the Known pennant on `--fixture=play`. Ranks 0-3 land in **W8-FACILITY** (its four dressings, M as sized); ranks 4-5 (the second tent, the guards, the statue, the braziers) land in **W9-TIERS's long branch** only — Renowned opens at 1,800 RP (`data/reputation.json`) and is unreachable in a Tier-1-only 1.0 — else they stay JSON rows with no art and a README line. docs/02 §9.1 is rewritten by W7-DOCS to this table under "one plate, six dressings"; the six §9.1 rows are kept below it as the post-1.0 plate brief. Balance: none.

**Register row:** BL-SCREENS-22 — Town rank-states. The town has one plate (the camp, BL-78) and six rank dressings on it, gated in `stage_camp.json`: Unknown 0 walkers / 6 lanterns / no banners; Known 1 / 8 / banners + a pennant; Respected 2 / 10 / a notice post; Established 3 / 10 / cobbles + a pennant line; Renowned 4 / 10 + 2 braziers / a second tent + two guards; Legendary 5 / 10 + 4 braziers / a statue + crest pennants. Ranks 0-3 ship in W8-FACILITY; 4-5 mount with the tiers that reach them (W9-TIERS). docs/02 §9.1's six painted states are the post-1.0 plate brief; the designer supplies plates, the loop never paints them. — ruled by the loop under the designer's 2026-09-15 delegation

### #24 — DESIGNER-24 / M4B-ACT-04 / PIPE-09 — Aerial town: still + motion, or figures?

**Ruling:** As built — the aerial is an establishing shot with motion (sails, gulls, clouds, the fountain and the waterfall) and no figures; 10-14 px townsfolk are post-1.0 and the designer's to draw.

**Inspiration:** Octopath's title screen is a slow establishing pan with no walking figures — the diorama read comes from light and motion, not from ants. The aerial is the MainMenu and the town push-in only (spec 09 §3: "MainMenu only; no figures at that scale"); nobody plays on it, and the designer's reference concepts never populate an aerial.

**Canon:** raw notes give the town's people to the *camp* ("townsfolk" appear in docs/02 §9.1, which is the camp's rank table, #22), not to the menu. docs/12 §3.2's sprite budget has no 10-14 px set; scaling the 21-48 px strips to 0.3 destroys pixel art (M4B-ACT-04's own evidence) and would break "nothing blurry".

**Cost:** none — `stage_town.json`'s note already records "no actors"; W7-DOCS writes the row. If figures are ever wanted, PIPE.md row 14's `gen_townsfolk.lua` (2-frame walk at 12-14 px) is the post-1.0 unit. Balance: none.

**Register row:** BL-SCREENS-24 — The aerial town. The MainMenu's aerial plate is an establishing shot: motion (sails, gulls, clouds, water) and no figures, because no sprite the project owns reads at 10-14 px and downsampled pixel art is blur. Aerial-scale townsfolk are post-1.0 (`gen_townsfolk.lua`, PIPE-09). `stage_town.json`'s "no actors" note is the record. — ruled by the loop under the designer's 2026-09-15 delegation

### #28 — DESIGNER-28 / Q03 — Hall framing: same or tight; margins or 3-column

**Ruling:** As built — `HALL_FRAMING = "same"` and the roster margins-only; the hall family is a panel over the same camp the hub shows.

**Inspiration:** docs/13 M5 ("screens are pages: they change in place") and the designer's own 2026-09-13 message that the hall *is* the camp (BL-78): Town → Guildhall reading as a panel opening over the place you were already looking at is the desk not moving. A tighter framing would re-frame the plate on every hall route (four screens) for a place-change the fiction does not make — the guild lives in the camp. A 3-column roster spends 250 px of a 12-card roster on a fire ring.

**Canon:** none speaks to framing; BL-78 (the designer's ruling) fixes the plate. `Guildhall.gd:119-121` records the reading: "Same plate, same framing: Town → Guildhall reads as a panel sliding over it… ('the desk does not move')".

**Cost:** zero — one constant untouched; `FRAMINGS["tight"]` stays as the built other branch. UI-56's wide-expand column is W8's independent fix. Balance: none.

**Register row:** BL-SCREENS-28 — Hall framing. `Guildhall.HALL_FRAMING = "same"` and margins-only ship: the hall family (Guildhall, Roster, RaiderDetail, Settings, LoadSave) is a panel over the hub's own camp framing, per docs/13 M5 and BL-78. `FRAMINGS["tight"]` stays built as the recorded alternative. — ruled by the loop under the designer's 2026-09-15 delegation

### #31 — DESIGNER-31 / Q06 / UI-53 / LOOP-05 / LOOP q5 / CRITIC-C5 — Reputation chip: gem or sigil; "Rep"?

**Ruling:** OVERTURNS the ship default — chip 2 wears the rank sigil (`Frame.REP_ICON = "sigil"`, the existing `rank_<name>.png`), carries no word, and its tooltip reads "N reputation · M more to <next rank>"; the gem file stays for the Board's trinket row only.

**Inspiration:** the one thing a management game's header must never do is show a second currency the player cannot spend; It's A Wipe!'s guild rating is a number beside the guild's own mark, never a jewel. Every report that looked (UI-53, LOOP-05, DESIGNER-31) recommended the sigil; the ship default kept the gem only because spec 00 §2.5 recorded it as a placeholder reading of Concept 3 — a placeholder is not a ruling.

**Canon:** raw notes, *Guild Reputation*: "Your guild has a single primary stat: **Guild Reputation**" — one stat, one mark. Spec 00 §2.5's own reading: "Canon has one currency (gold), no gems"; canon's word is *reputation*, never abbreviated, so "Rep" appears nowhere — the tooltip says the word in full (docs/13 §8.1's discipline for the morale word applies to the guild's word too).

**Cost:** one constant in **W9-POLISH** (the unit already carries the tooltip and the `REP_ICON` switch; `"sigil"` selects the existing icon, no asset); `test_frame_header.gd` asserts chip 2's tooltip contains "reputation" and its texture is `rank_<name>`; spec 00 §2.5's "the gem icon stays" is amended by W7-DOCS to "chip 2 wears the rank sigil (ruled 2026-09-15)"; the Board's "Potential Rewards" gem (UI-14) becomes the only gem, which is a trinket, which is right. Balance: none.

**Register row:** BL-SCREENS-31 — The reputation chip. Header chip 2 shows the reputation points beside the current rank's sigil (`Frame.REP_ICON = "sigil"`), not the reference's gem: canon has one guild stat and no gems, and a gem beside a number reads as a currency. The chip carries no word; its tooltip reads "320 reputation · 80 more to Known". The `gem.png` icon stays for trinkets. Spec 00 §2.5 amended. — ruled by the loop under the designer's 2026-09-15 delegation

### #32 — DESIGNER-32 / Q08 — Depth of field: off, or on at N?

**Ruling:** Off (the ship default); no `dof` layer, no per-scene grade; the vignette stays behind `reduced_effects`; docs/12 §2.2 row 6 and docs/00 VS7 are amended.

**Inspiration:** the brief's own line — "sprites at integer scale in a lit, layered world; nothing blurry, nothing baked". Octopath's tilt-shift blurs *3D* planes behind and in front of the play plane; our plates are the designer's own 1:1 pixel art at display density (docs/12 §3.1's supersession: "no pixel pitch above 1"), so a blur would smear the designer's pixels, which is the one thing the memory rule forbids. The reference concepts show no blur.

**Canon:** the raw notes say "2D-HD aesthetic similar to Octopath Traveler" and nothing about blur; docs/12's "non-negotiable" is 🔷 PROPOSED (§2.2) and its layer stack (§6.1, "DoF has nothing to blur unless the depth is real") was written for a 640×360 grid the art pass superseded. docs/00 VS7's "depth-of-field… present in the town scene" is the vertical-slice criterion of the same superseded plan.

**Cost:** two doc lines in **W7-DOCS**: docs/12 §2.2 row 6 → "Tilt-shift DoF: optional, OFF — the plates are authored sharp at 1:1; a `dof` scene key is the post-1.0 hook"; docs/00 VS7 → "lighting, parallax and ambient motion present; no depth-of-field on 1:1 plates". Nothing in the tree changes. Balance: none.

**Register row:** BL-SCREENS-32 — Depth of field. No depth-of-field ships and none is owed: the plates are 1:1 pixel art at display density and a blur would soften the designer's own pixels. The vignette stays (behind `reduced_effects`); the scene `dof` key stays absent as the post-1.0 hook. docs/12 §2.2 row 6 ("non-negotiable") and docs/00 VS7 amended to "optional, off". — ruled by the loop under the designer's 2026-09-15 delegation

### #33 — DESIGNER-33 / Q09 / M6-JUICE-02 / UI-46 — Does "the desk does not move" forbid a 110 ms dissolve?

**Ruling:** OVERTURNS the ship default — a dissolve is not the desk moving: `ScreenRouter.TRANSITION_MS = 110`, a fade-in of the incoming page (opacity only, ease-out, inserted and laid out at t=0), gated to 0 by `reduced_motion` and by `tools/shot.gd`; no cross-fade, no 6 px tab shift, and the wipe's t=1,800 post-mortem slide stays out — the report appears in place under the stamp.

**Inspiration:** "really awesome frontend design" (the designer's direction) — a dashboard that hard-cuts between pages reads as a prototype; every polished management UI settles a page in ~100 ms. Octopath's menus fade; nothing in them slides. It's A Wipe! cuts, and its UI is the thing we are rebuilding. The desk rule is about *place*: no page arrives from off-camera. An opacity change is a page changing *in place*, which is M5's own sentence.

**Canon:** docs/13 M5 (survived the 2026-09-09 supersession): "No screen slides in from off-camera. Screens are pages: they change in place." docs/13 §12.2 (the same doc's motion table): "Screen / tab change | Cross-dissolve + active tab shifts 6px right | 110ms | ease-out" — the dissolve is the docs' own number; the 6 px shift is a slide and is struck. §11.4's t=1,800 "slides out from under the ledger page" is a slide and is struck too: the beat is the stamp press + 12 % dim + the seal (JUICE-03).

**Cost:** **W9-POLISH**, S: `_load_into_host` adds the new screen at t=0 (every `test_screens.gd` read of `Label.text` holds), sets `modulate.a = 0` on it and tweens to 1 over `TRANSITION_MS` with `Tween.EASE_OUT`; the outgoing screen is freed at once (a fade-in, not a cross-fade — one screen in the tree at any time, so nothing in the a11y smoke or the focus walks changes); `TRANSITION_MS` reads 0 when `GameSettings.reduced_motion` is true or `shot.gd` is driving (the sheets stay byte-stable); `ui.tab` fires on the first frame of the fade (docs/13 §12.4). `test_screens.gd` pins t=0 insertion and that `reduced_motion` yields a 0 ms fade. The docstring's "never will" becomes "110 ms, opacity only" (W10-DELETE's line is retargeted). docs/13 §12.2 row 1 → "Fade-in, opacity only | 110 ms | ease-out"; §11.4 t=1,800 → "the post-mortem appears in place under the stamp". Budget: 110 < §12.1's 140 ms settle. Balance: none.

**Register row:** BL-SCREENS-33 — Screen changes. A page fades in over 110 ms (`ScreenRouter.TRANSITION_MS = 110`, opacity only, ease-out, inserted at t=0), which is a page changing in place and therefore inside docs/13 M5; nothing slides — the 6 px tab shift and the wipe's t=1,800 post-mortem slide are struck, the post-mortem appears in place under the stamp. `reduced_motion` and `shot.gd` make the fade 0 ms. — ruled by the loop under the designer's 2026-09-15 delegation

### #40 — DESIGNER-40 / Q16 / M6-A11Y-06 / UI-47 / RULES-08/09 — CVD ramp and hexes; text floor; `prose_font_swap`; the logotype

**Ruling:** Four decisions. (1) The ONLY ramp is the reference's three-state red / amber / green family, corrected so it is lightness-ordered and verified under all four simulations: `DANGER #F73526` (unchanged), `CAUTION #E8A302`, `POSITIVE #AFEBA2`; docs/13 §8.3's ten-plate table is struck; the `colourblind_safe` option stays (default OFF) but means a hue swap of the third state only — `POSITIVE_CVD #C6DDF1` (sky) for eyes that do not separate red from green — three hexes, not ten. (2) The text floor: `Type.SMALL 13` / `STACK 11` stay; docs/13 §13's row is restated in its own authoring frame. (3) `prose_font_swap` is retired. (4) The logotype is exempt from "no text in art".

**Inspiration:** the roster row is *the* screen of the game (docs/00 §2: "the two seconds where you look at a number next to a person's name"); It's A Wipe! colours its raiders' states red-to-green and so does the designer's Concept 3 ("Morale: Low" in `#F13D2A`, "42%" in amber). Keeping that family is the art bar; making it legible to one player in twelve is the design's blocking bar; both are met when the three hues are ordered by lightness — which the reference's sampled hexes were not (amber L* 78.5 lighter than green 69.3, and amber vs green 2.2 L* apart for a protanope). A ten-step plate ramp was the paper-ledger thesis's and cannot be text on navy (band 0's fill is 1.35:1 on `SURFACE_PANEL`); the reference paints exactly three states and the other seven bands ride the integer, the word and the glyph, which is docs/13 §13's first row.

**Canon:** raw notes, *Morale*: "one number, one state, one effect" and the roster example "Natsuna — 87 ❤️ / Steve — 14 😡" — the number and the face carry the band; colour is decoration on them. docs/13 §13 (Blocking): "Colour is never the only signal… Adjacent morale bands must remain distinguishable by lightness alone" and §15.1: "CVD safety ship[s] on by default and ha[s] no 'off'" — so the *default* must pass, which is why the corrected triad is the only ramp and the option is a preference, not the safety switch. Measured with `tools/art/cvd.py` (Brettel/Viénot):

| Observer | L* DANGER / CAUTION / POSITIVE | adjacent ΔL* | monotone |
|---|---|---|---|
| none / greyscale | 54.5 / 71.8 / 87.6 | 17.3 / 15.8 | yes |
| protanope | 42.5 / 68.5 / 89.6 | 26.0 / 21.2 | yes |
| deuteranope | 59.5 / 73.5 / 86.4 | 14.0 / 12.9 | yes |
| tritanope | 72.4 / 78.6 / 84.9 | 6.2 / 6.4 | yes |

Every step ≥ 5 L* under every observer (the reference's own ramp: 2.2 protanope, non-monotone everywhere); contrast on `SURFACE_INSET` 4.81 / 8.47 / 13.34 (AA at every size); `POSITIVE_CVD #C6DDF1` (L* 85.8) keeps the same ordering and ≥ 6.2 L* under all four. The criterion is therefore confirmed as **ΔL* ≥ 5 between adjacent ramp steps under none / protanope / deuteranope / tritanope / greyscale, monotone** (q-a11y-legible.md's question; the 3:1-per-step half is struck as arithmetically unreachable and not what §13 says). Text floor: docs/13 §4.2 is titled "authored at 1920×1080"; the scale was re-measured off 1536-wide concepts (spec 05 §3), so 13 authored is 16.25 in §13's frame and renders 13.71 → 14 whole pixels at 1080p; STACK 11 is the stack-count and shut-caption size, rounds to 12 rendered, and the 125/150 text scale (W9-SCALE-2 makes every route clean at 150) is the remedy for a player who needs more — raising the two constants +1 px reopens the 262 px card and the 545 px roster that wave 9 is closing. Logotype: `gen_wordmark.py` renders the mark once from an OFL face; a mark is not text, and the words are also a Label beside it on MainMenu (`MainMenu.gd:226`, with an `accessibility_name` on the mark) and the Town heading, so no screen test or reader loses them.

**Cost:** **W8-KEYS** (owns `Settings.gd` rows and `test_settings.gd` in wave 8), S: `Palette.CAUTION`/`POSITIVE` take the two hexes (the success figure and the morale word move together — 04-palette §5 "one function serves both"); `BAND_FILL_CVD`/`BAND_INK_CVD`/`band_ink_cvd` are deleted and `band_color_cvd` returns `[DANGER, CAUTION, POSITIVE_CVD]` by the same `< 30 / < 65` bands; `morale_color` goes through `band_color_active` so the option finally reaches the roster (the tints pass AA, so no plate is needed); the Settings row's note becomes "Morale's third colour is sky instead of green, for eyes that do not tell red from green. The number and the state word are unaffected."; `test_palette_cvd.gd` asserts the two triads' numbers above and drops the §8.3-defect tests; the art-gate baselines re-record (a hue change on small text sits inside the 0.07 jitter — verify, do not assume). **W7-DOCS**: docs/13 §8.3 becomes the three-row table with the L* column; §13's CVD row gets the criterion sentence; §15.1 gains "Colour-safe morale ramp | Off | §13 | Player | Global" and its "no off" sentence stays true; §13's text-size row → "14 px as authored in §4.2's frame (13 in the 1536 frame renders at 14 whole pixels at 1080p)"; §13's font-choice row struck; §14 gains "the pre-rendered logotype is a mark, not text". `test_a11y_legibility.gd`'s `BELOW_FLOOR_AT_1920` becomes the record of the ruling, not a defect list. `prose_font_swap`: hidden now, row and key deleted in **W10-DELETE** as planned. Balance: none.

**Register row:** BL-SCREENS-40 — Accessibility rulings. (1) The morale/success ramp is three states, lightness-ordered and CVD-verified: `DANGER #F73526`, `CAUTION #E8A302`, `POSITIVE #AFEBA2` (every adjacent step ≥ 5 L*, monotone, under none/protanope/deuteranope/tritanope/greyscale — `tools/art/cvd.py`, `test_palette_cvd.gd`); docs/13 §8.3's ten-plate table is struck; `colourblind_safe` (default Off) swaps only the third state to `#C6DDF1` for hue separation. (2) `Type.SMALL 13` / `STACK 11` stay: §13's 14 px floor is read in §4.2's authoring frame, and the 125/150 text scale is the remedy. (3) `prose_font_swap` is retired (row and key deleted in W10-DELETE; §13's font-choice row struck). (4) The pre-rendered logotype is exempt from §14's "no text in art". — ruled by the loop under the designer's 2026-09-15 delegation

### #41 — DESIGNER-41 / Q17 — Morale faces as an authored sprite font

**Ruling:** As built — `Fonts.MORALE_FACE_FONT = true`; the ten faces are authored 24 px sprites and system emoji is the built other branch.

**Inspiration:** Octopath's UI contains no system glyph; a pixel face at integer scale is the only reading of "❤️ / 🙂 / 😒 / 😡" that sits in a 2D-HD frame. It's A Wipe! uses drawn mood faces, not emoji.

**Canon:** raw notes, *Morale*: "Natsuna — 87 ❤️ … Steve — 14 😡" — the notation is the designer's shorthand for a face beside the number; docs/12 §5.2's reading ("10 authored sprites, one per band — not system emoji") is confirmed. Spec 00 §2.1 keeps the glyph in the row canon fixes.

**Cost:** zero; `emoji_free` keeps its pip figure. Balance: none.

**Register row:** BL-SCREENS-41 — Morale faces. Canon's emoji notation is rendered as the ten authored faces (`faces*.png`, `Fonts.MORALE_FACE_FONT = true`), never system emoji; docs/12 §5.2's reading is confirmed. — ruled by the loop under the designer's 2026-09-15 delegation

### #43 — DESIGNER-43 / M6-JUICE-04 — Strike "screen shake on wipes"

**Ruling:** Struck (the ship default); the wipe's beat is the stamp press, the 12 % dim and the seal, and the camp's fallen lie down (W9-ART).

**Inspiration:** a wipe in It's A Wipe! is the joke, not the punishment; the comedy lands on the *report*, read at leisure. Octopath shakes the screen for a crit in a 3D battle; our fight is a written account on a desk, and docs/13 §11.4 says the desk's failure vocabulary is stamps, blots and seals.

**Canon:** docs/13 §11.4: "No 'You Failed', no red flash, no lost-progress language"; §12.2: "Nothing in the UI loops, pulses, or breathes"; §13: reduced flashing is unconditional. `grep -rni shake docs/` → 0. The BACKLOG line was a juice wish, not a design.

**Cost:** zero — BACKLOG.md:322 already carries the strike-through; M6-JUICE-04 closes on this row. Balance: none.

**Register row:** BL-SCREENS-43 — Screen shake. "Screen shake on wipes" is struck from BACKLOG: docs/13 §11.4, §12.2 and §13 forbid it, and the wipe's beat is the WIPE stamp, the 12 % dim and the seal. Audit M6-JUICE-04 closes. — ruled by the loop under the designer's 2026-09-15 delegation

### #44 — DESIGNER-44 / spec 00 §4 / SHIP q5 / SHIP-06 — Aspect default; fullscreen on first launch

**Ruling:** As built — `display_aspect = "keep"` (the 3:2 frame letterboxed) default with `expand` as the option, and `window_mode = "borderless"` fullscreen on first launch with `windowed` as the option and F11 / Alt+Enter to swap.

**Inspiration:** the designer's concepts are 1536×1024 compositions; letterboxing shows every player exactly that composition (spec 11 §1's revised decision, made on a 1920×1080 shot of the Town where expand exposed the plate's edge). A first launch that opens a window taller than a 1366×768 laptop hides the commit row (SHIP-06) — fullscreen is the only default that never does.

**Canon:** docs/13 §15.1: "Resolution / window mode / vsync | Native, borderless". Spec 00 §4 left the aspect to "the designer confirms"; the delegation confirms keep.

**Cost:** zero — W6-SETTINGS built both (`GameSettings.apply_window_mode`, `project.godot` `window/size/mode` fullscreen, the two rows). Balance: none.

**Register row:** BL-SCREENS-44 — Display. The game opens borderless fullscreen (`window_mode = "borderless"`, F11 / Alt+Enter to a 3:2 window that fits the desktop) and letterboxes the 1536×1024 frame (`display_aspect = "keep"`); `expand` is the opt-in for players who accept the plates' edges. Spec 00 §4's first item is closed. — ruled by the loop under the designer's 2026-09-15 delegation

### #45 — DESIGNER-45 / spec 00 §2 — Confirm the reference-concept conflicts already ruled

**Ruling:** Confirmed — Tiny/Ranger → Rogue (§2.2); no boss names or raider levels from the references (§2.3); twelve cards, paged (§2.4); "Day N · Rank" in place of the clock and the rail's canon labels (§2.5, §2.6) — with §2.5's one open item, the gem, now ruled by #31 (sigil).

**Inspiration:** the references set the art bar; where their *content* contradicts canon (a tenth class, levels, named bosses, a clock, a gem) canon wins — the memory rule's own second clause.

**Canon:** nine classes (raw notes, *Classes*); no levels anywhere in the recruitment model; "Raid 1 / Adventure 2" are placeholders "they will need names later"; one guild stat; five buildings by name.

**Cost:** zero; W7-DOCS notes the confirmation on spec 00 §2 and amends §2.5 for the sigil. Balance: none.

**Register row:** BL-SCREENS-45 — Spec 00 §2. The reference-concept conflicts art/ref/specs/00 §2.2-§2.6 ruled in canon's favour (Ranger → Rogue, no named bosses or levels, twelve paged cards, "Day N · Rank", canon rail labels) are confirmed; §2.5's gem is ruled by BL-SCREENS-31 (sigil). — ruled by the loop under the designer's 2026-09-15 delegation

### §7.1 — Town rank-states beyond derived dressings, aerial figures, the designer's plates (M3-LOOP-06, M4B-ACT-04)

**Ruling:** Stays out of 1.0 — painted plates per rank and 10-14 px aerial townsfolk are the designer's; the six derived dressings (#22) and the aerial's motion (#24) are what ships.

**Inspiration / Canon / Cost:** as #22 and #24. The row's text stands: "1 plate + rank dressings; 3 or 6 plates are the designer's, post-1.0".

**Register row:** folded into BL-SCREENS-22 and BL-SCREENS-24 above. — ruled by the loop under the designer's 2026-09-15 delegation

### §7.1 — Region-masked per-component diff scoring (m4t-06)

**Ruling:** Stays out of 1.0 — closed as not required to ship; the whole-screen 14 numbers per wave are the record and the gate is a no-regression check, not a resemblance bar.

**Inspiration:** the reference concepts are a standard for the *art*, not a target the chrome must pixel-match (memory: reference-concepts-are-a-standard — the design wins where their UI does not fit); m4t-06's own evidence is that the residual is glyph shape from a different UI font, which no region mask changes and no player sees.

**Canon:** none; UI bar #10 already states the rule. **Cost:** zero; the L unit (three region files, `--regions` in `refdiff.py`) is the post-ship instrument if the designer ever asks for a resemblance score.

**Register row:** BL-SCREENS-m4t-06 — Region-masked diff scoring is post-1.0. The art gate records the whole-screen MAE / IoU per wave and fails only on a regression past the 0.07 jitter; it is not a resemblance bar against the mockups. — ruled by the loop under the designer's 2026-09-15 delegation

### §7.1 — `prose_font_swap` (Q16)

**Ruling:** Stays out of 1.0 — retired: the row is hidden now and deleted with its key in W10-DELETE; docs/13 §13's font-choice row and §15.1's row are struck.

**Inspiration / Canon / Cost:** the option's definition was "EB Garamond → Fira Sans for prose" and Fira Sans is now the only body face (spec 05 §1.2), so the swap has nothing to swap from; redefining it as a dyslexia face would mean sourcing, licensing and crediting a third family the designer never asked for (DESIGNER-05). Cost zero beyond W10-DELETE's planned deletion.

**Register row:** folded into BL-SCREENS-40 (3). — ruled by the loop under the designer's 2026-09-15 delegation

## Canon numbers changed

- **`Palette.CAUTION` `#FBB62B` → `#E8A302` and `Palette.POSITIVE` `#32C24D` → `#AFEBA2`** (#40). Not canon numbers — art/ref/specs/04-palette.md §5's reference samples (the green was sampled from a morale *bar* canon forbids). Changed because the sampled trio is not lightness-ordered and fails protanopia at 2.2 L*; the corrected trio keeps the hue family and passes docs/13 §13's blocking CVD row under all four simulations. Every other ruling in this batch leaves canon's numbers untouched; none of docs/_source changes.
- docs/12 §2.2 row 6 ("tilt-shift DoF: non-negotiable") and docs/00 VS7 — 🔷 PROPOSED lines, amended to "optional, off" (#32).
- docs/13 §12.2 row 1 (dissolve + 6 px shift) and §11.4 t=1,800 (the slide) — 🔷 PROPOSED, amended to "fade-in, opacity only; the post-mortem appears in place" (#33).
- docs/13 §8.3's ten-row plate table — 🔷 PROPOSED, replaced by the three-row table (#40).

## Tensions

- **#45 ↔ CONTENT #25 (no boss names) and GUILD #21 (no levels):** this batch confirms spec 00 §2.3 as ruled — placeholders ship (the display name, never the kind as a name) and `Raider.level` stays display-only, never set. If CONTENT names creatures or GUILD lands Drilling with a visible level, spec 00 §2.3 must be re-amended by that batch, not reopened here.
- **#22 ↔ STAGE #42c (the first visible-change tranche / the guildhall at four levels):** both ride W8-FACILITY's one layer-key mechanism on `stage_camp.json`; the facility levels dress the *big tent* and the rank dressings dress the *camp around it* — STAGE's four tent states must not also add walkers or lanterns, or the two tables collide on the same props.
- **#44 ↔ SHIP-06 (the window fact SHIP reads):** the same default (borderless fullscreen; `keep`) — SHIP's README line and export check must state it identically; if SHIP rules "windowed sized to the desktop" instead, this row yields (it is SHIP's blocker), and `project.godot`'s `window/size/mode` follows SHIP.
- **#33 ↔ AUDIO (the `ui.tab` hook):** the hook now has a first pixel to sync to (the fade's first frame); AUDIO's W7-AUD-BIND must not have bound `ui.tab` to a screen *swap* that fires before the tween starts.
- **#40 ↔ the art-gate baselines (SHIP/UI):** two palette tokens move; the per-wave whole-screen numbers will shift by a hair on every screen that shows a morale word or the success figure — W8-KEYS re-records the baselines and asserts the delta is inside the 0.07 jitter rather than assuming it.
- **#31 ↔ CRITIC-C5's wave:** CRITIC resolved the chip in "one unit, wave 7"; the ship plan put the flip in W9-POLISH. This batch follows the ship plan (W9-POLISH); if the critic re-schedules it to wave 7 the constant is the same.
