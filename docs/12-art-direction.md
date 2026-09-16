# 12 — Art Direction & Aseprite Pipeline

> **Status:** Draft · **Owner:** Design · **Updated:** 2026-09-08
> **Canon:** _source/lead-designer-notes-raw.md, _source/ideaboard-transcription.md
> **Legend:** ✅ CANON = decided · 🔷 PROPOSED = needs sign-off · ❓ OPEN = undecided

**In one line:** This document governs the visual bible of *A Guild Story* — what the 2D-HD target actually is technically, sprite and palette specifications, character and environment art rules — and the Aseprite-based production pipeline that turns source files into engine-ready atlases.

---

## 1. Scope

**This doc owns:** the definition of the 2D-HD look and the split between pixel work and shader work; render and sprite resolutions; the master palette; character silhouette, animation and rarity art rules; environment layer stacks and building/backdrop art states; the `art/` source tree, Aseprite conventions, the CLI facts, and the generator build (`tools/build_art.sh`).

**This doc does NOT own:**

| Topic | Owner |
|---|---|
| Screen layouts, HUD, widgets, fonts, roster and tooltip composition | [13 — UI & Presentation](13-ui-ux.md) |
| Shader implementation, render pipeline, importer code, engine choice | [14 — Technical Architecture](14-technical-architecture.md) |
| Which buildings exist, the navigation model, and the per-level exterior contract (§9.2) my plate count is bound by | [02 — Town & Buildings](02-town-and-buildings.md) |
| The item-icon budget (18 base shapes × 5 tier palettes) my §3.2 and §5.5 counts are bound by | [10 — Content Structure](10-content-and-encounters.md) |
| The mistake taxonomy the fumble animation visualises | [07 — Combat & Mistake Resolution](07-combat-simulation.md) |
| Class mechanics behind the silhouettes | [06 — Classes & Roles](06-classes-and-roles.md) |
| Morale bands and rarity rules the art expresses | [05 — Morale](05-morale.md), [03 — Guild Reputation](03-guild-reputation.md) |

I specify the *values*; doc 13 and doc 14 specify the *plumbing*. Where a number below implies engine work, it is tagged as such.

**What canon gives us.** ✅ CANON: "Clone of *It's A Wipe!* by Parody Games LLC, rebuilt with a 2D-HD aesthetic similar to *Octopath Traveler*" (canon: raw notes, Premise). ✅ CANON: "Aseprite is in the project root; use it heavily for sprite work", "Likely engine: Godot", "'Really awesome frontend design' is a priority" (canon: raw notes, Direction given alongside the notes). That is the entire art brief. Everything else in this document is 🔷 PROPOSED.

---

## 2. The 2D-HD target, defined precisely

**Why this section exists:** a team that reads "2D-HD" as "nicer sprites" will produce a competent pixel-art game that looks nothing like the reference. The look is roughly 40% pixel work and 60% render pipeline. This section names which is which so that nobody waits on the other.

### 2.1 The definition

🔷 PROPOSED. 2D-HD means: **high-resolution pixel-art sprites, integer-scaled, composited into a native-resolution HDR framebuffer over multi-layer painted environments, with a real depth stack, and then heavily post-processed.** The pixels are authored small and drawn big; the *lighting and post-processing are computed at full output resolution*, not at the sprite resolution. That single sentence is the whole trick, and it is the thing most easily got wrong: if bloom and depth-of-field run at the chunky internal resolution, the result reads as a filtered retro game rather than a diorama.

### 2.2 The ingredient list and who owns each

🔷 PROPOSED.

| # | Ingredient | What it actually contributes | Owner |
|---|---|---|---|
| 1 | High-res pixel-art sprites | Readable character acting; the "hand-made" signal | Art (this doc, §3–5) |
| 2 | Painted / pre-rendered multi-layer environments | Depth and material richness pixel tiles cannot reach | Art (§6) |
| 3 | Orthographic-ish diorama presentation | The "tabletop model" read; ground plane tilt is **painted**, not 3D | Art (§6.1) + doc 14 |
| 4 | Real depth layers with parallax | Makes 3 and 5 physically meaningful instead of a filter | Art (§6.1) + doc 14 |
| 5 | Bloom (HDR, thresholded) | Saturated highlights bleeding into deep shadow — the signature | **doc 14 (shader)** |
| 6 | ~~Tilt-shift depth-of-field on near + far planes~~ **Off, and none is owed** ([15 BL-126](15-open-questions.md#bl-126), 2026-09-15): the plates are 1:1 pixel art and a blur softens the designer's pixels; no `dof` layer ships. The diorama reads through 4, 5, 7 and 8 instead | The miniature-diorama illusion — carried by the other seven ingredients | — (no shader) |
| 7 | Per-pixel lighting + normal-mapped sprites | Sprites react to scene lights instead of sitting flat on the plate | Art authors normals (§3.4) + **doc 14** |
| 8 | Volumetric-feeling light shafts | God-rays through windows, cave mouths, boss arenas | **doc 14** (art supplies masks) |
| 9 | Particle atmospherics — dust, embers, rain | Continuous motion in an otherwise static frame | Art (sprites) + doc 14 (emitters) |
| 10 | Saturated highlights against deep shadow | A palette and value-range discipline, not a post effect | Art (§4) |
| 11 | Shallow, cinematic camera | Slow drift, small dead zone, restrained punch-ins | doc 14 (§2.4 values here) |

**Consequence for scheduling:** items 5–8 are shader tasks and can be prototyped on placeholder art in week one. Do that. The look should be provable with three grey boxes and a colour swatch before a single finished sprite exists. If the shader stack is not standing up, no amount of sprite polish will rescue the target.

### 2.3 Explicitly not the target

🔷 PROPOSED. Not: flat 2D tile-grid RPG (no depth stack); not low-res-upscaled retro (post must run native); not "HD-2D" as a CRT/scanline filter; not painterly non-pixel 2D — characters stay pixel art with hard edges, and that hard edge against soft painted backgrounds is the intended contrast.

### 2.4 Camera and projection

🔷 PROPOSED. The camera is a **2D camera over painted-perspective plates**. Ground-plane tilt lives in the artwork; the engine does not need a 3D scene. (Whether doc 14 instead places layers as textured quads in 3D for true per-layer DoF is ❓ OPEN — see Q7.)

| Parameter | Town | Combat |
|---|---|---|
| Visible area | 640 × 360 art-px (§3.1) | 640 × 360 art-px |
| Follow | **None — static framing with push-in on building select** ([02 §10.1](02-town-and-buildings.md)) | Static per encounter |
| Idle drift | — | 2 art-px amplitude, 9 s period, sinusoidal |
| Event punch-in | Building select: 1.04× (the §3.3 sanctioned scale) over ≤ 260 ms, hold until exit — doc 13 owns the timing | 1.04× over 180 ms on a fumble, hold 600 ms, release 400 ms |
| Rotation | Never | Never (sprites may rotate; the camera does not) |

**No town locomotion.** 🔷 PROPOSED, inherited from doc 02 rather than decided here: there is no player avatar and no follow camera in town. [02 §10.1](02-town-and-buildings.md) selects option A, the clickable illustrated scene — "no character controller, no collision, no pathfinding" — and [02 §10.2](02-town-and-buildings.md) instructs doc 14 "No navigation mesh, no player entity". Town movement is limited to ambient NPCs on fixed spline paths (§6.2) plus the camera pan-to-change on unlock (doc 02 rule R4) and the push-in above. If a walkable hub is wanted, reopen **doc 02 Q6** — do not ship both models.

---

## 3. Resolution and sprite specifications

> **⛔ SUPERSEDED 2026-09-09 by the art pass.** The references are 1536×1024 dense pixel art authored at display density — `refkit grid` finds no pixel pitch above 1 — so there is no 640×360 design grid and no integer scale ladder. The base viewport IS 1536×1024; wider displays *expand* (edge-anchored chrome, wider scene) with a `keep` letterbox switch; texture filtering is linear because at fractional scales nearest sampling of 1:1 art shimmers. Post-processing still runs at native resolution (§2.1's point stands). The text below is kept as the record of the rejected direction and is no longer built against. Authority: `art/ref/specs/11-godot-architecture.md` §1–2, `project.godot`.

🔷 PROPOSED throughout §3.

**Why this exists:** every canvas size, atlas, and UI margin in the project derives from one number. Fix it once.

### 3.1 The design grid and the scale ladder

The **design grid is 640 × 360 art-pixels**. It divides cleanly into every target we care about, which is why it was chosen:

| Output | Scale | Notes |
|---|---|---|
| 1280 × 720 | 2× | Minimum supported |
| 1920 × 1080 | 3× | Primary target |
| 2560 × 1440 | 4× | **Reference authoring resolution** — review art here |
| 3840 × 2160 | 6× | Free; no extra assets |

Rules: sprites and plates are drawn into a **native-resolution framebuffer** at the integer scale above (nearest-neighbour sampling). Post-processing (§2.2 items 5–8) runs at native resolution. There is no 640 × 360 intermediate buffer. Non-integer window sizes letterbox to the nearest integer scale rather than sampling fractionally.

**Engine consequence (❓ OPEN — see Q11).** The pixel layer must **not** be rendered through a 640 × 360 `SubViewport`. A fixed-resolution intermediate quantises all motion to art-pixels and silently deletes §3.3's sub-pixel positioning, the camera drift, and the 1.04× punch-in. Sprites are drawn at integer scale directly into the native-resolution 2D canvas. [14 §2.2](14-technical-architecture.md) currently offers `SubViewport` as the mechanism for this same requirement; that cell needs amending — drop it, or qualify it as "only for effects that are deliberately art-pixel-quantised".

### 3.2 Canvas sizes

| Asset | Canvas (art-px) | Occupied height | At 1080p | Notes |
|---|---|---|---|---|
| Combat/raid body sprite | 64 × 80 | ~56 px | 168 px | Feet on canvas row 76; 4 px of headroom for FX |
| Town NPC body sprite | 48 × 64 | ~44 px | 132 px | Ambient townsfolk only (§5.2, §6.2). **No player avatar** — see §2.4 |
| Roster portrait | 64 × 64 | head + shoulders | 192 px | Used in the 12-slot lineup |
| Recruit/inspect portrait | 128 × 128 | chest up | 384 px | Tavern recruiting; ✅ CANON the Tavern is where recruits are found and managed (canon: raw notes, Tavern) |
| Legendary hero portrait | 160 × 192 | three-quarter body | — | Bespoke; ✅ CANON Legendary raiders are named characters (canon: raw notes, Guild Reputation) |
| Morale chip glyph | 24 × 24 | — | — | **10 authored sprites**, one per doc 05 band — not system emoji. Used at the [13 §8.2](13-ui-ux.md) chip sizes (20–28 px); doc 13 owns the scale mapping |
| Portrait expression overlay | matches host portrait | face only | — | **5 layers per portrait** (loving / happy / neutral / annoyed / furious); band → expression mapping is doc 05's |
| Item / gear icon | 32 × 32 | — | 96 px | **18 base shapes locked at Tier 1, recoloured per tier → 90 renders** ([10 §12.2](10-content-and-encounters.md), §5.5). Never one bespoke icon per item name |
| Building plate | up to 320 × 240 | — | — | Multi-layer, see §6.2 |
| Encounter backdrop plate | 960 × 400 | — | — | Wider than the grid to allow parallax travel |
| Boss sprite | 192 × 192 (tier 1) | — | — | Scales up in later tiers |

**The 12-lineup constraint.** ✅ CANON: "I've also decided I'd like the raid size to be 12, most fights normally requiring 2 tanks" (canon: raw notes, Classes). Twelve 64-px-wide sprites do not fit across 640 art-px in one row. 🔷 PROPOSED: the raid renders as **two staggered rows of 6** — front rank (tanks/melee) on the play plane, back rank (casters/healers) 18 art-px up and 12 art-px right, at 0.92× scale for cheap depth. Spacing 88 art-px per row slot. Doc 13 owns the actual composition; this fixes the sprite budget it has to work with.

**Not budgeted here.** If [02 Q6](02-town-and-buildings.md) later resolves to the walkable hub, that adds a 9-class town body set with 8-direction `walk` — the cost is stated in doc 02 §10 option B (+3–4 EW plus the player sprite set) and is **not** absorbed by any figure in this document.

### 3.3 Pixel-perfect versus sub-pixel — the decision

🔷 PROPOSED. **The game is not pixel-perfect. Sub-pixel positioning and arbitrary rotation are allowed.** This matches the reference and is required for the camera drift, punch-in, and the fumble stagger to feel good.

| Behaviour | Rule |
|---|---|
| Sampling | Nearest-neighbour always. No bilinear on sprites, ever. |
| Position | Translation in **device pixels**, not art-pixels. No snapping. |
| Rotation | Allowed, on a whitelist: fumble stagger, death topple, projectiles, thrown props, foreground foliage sway |
| Rotation limit | ±12° except death topple (up to 90°) |
| Scale | Integer for the base ladder; the 0.92× back-rank and the 1.04× punch-in are the two sanctioned exceptions |
| Mirroring | Horizontal flip allowed; author asymmetric details (Rogue eyepatch, Bard instrument) so a flip still reads |

**Say this out loud to the team:** a rotated sprite at 3× shows non-square pixel clusters and its edges will crawl during the rotation. That is accepted. Anyone arguing for hard snapping is arguing for a different game. The mitigations are the ±12° cap and keeping rotations short (under 400 ms) so crawl reads as motion rather than as error.

**Second thing to say out loud:** because post-processing runs at native resolution, **bloom and DoF will emit colours that are not in the master palette.** Palette discipline (§4) is an *authoring* constraint, not a runtime guarantee. Do not file bugs about off-palette pixels in screenshots.

### 3.4 Normal maps for sprites

🔷 PROPOSED. Ingredient 7 requires per-sprite normals. Authoring rule: each character `.aseprite` carries a hidden layer group `_normals/` with a hand-painted 3-tone normal proxy (left-facing, right-facing, up-facing) per limb mass — not a per-pixel normal map. Export as a sibling atlas `<name>_n.png` via a second manifest entry (§7.6). If doc 14 concludes hand normals are not worth the cost, the fallback is a single global light direction with baked shading, and this layer group is dropped. ❓ OPEN — see Q6.

---

## 4. Master palette

🔷 PROPOSED throughout §4.

**Why this exists:** ingredient 10 — "saturated highlights against deep shadow" — is a palette rule, not a shader. If artists pick their own darks, the bloom has nothing to sit against and the whole frame goes muddy.

### 4.1 Structure

One master palette, organised as **5-step ramps**. Step 5 is the deepest shadow, step 1 the brightest light. Every ramp's step 5 sits at or below 18% luminance and every step 1 at or above 78% — that spread is what feeds the HDR threshold.

**Skin A (fair)** — `#4A2B3E` `#7A4453` `#B77A6B` `#DCA88A` `#F5D9AE`
**Skin B (deep)** — `#2A1826` `#4E2C33` `#7A4838` `#A96D45` `#D39C63`
**Metal / iron** — `#22222F` `#3D4155` `#5F6579` `#8F97A6` `#D6DCE4`
**Metal / gold (rarity trim)** — `#4A2E12` `#7A5218` `#B98A24` `#E5BE4E` `#FFF0A8`
**Leather** — `#241623` `#402334` `#6A3B33` `#9C5F3C` `#C98A52`
**Cloth (undyed)** — `#1E1B2E` `#3A3348` `#5F5568` `#918393` `#C9BCB6`
**Stone** — `#16161F` `#2C2E3A` `#474B5A` `#6E7382` `#A3A9B2`
**Wood** — `#1C1218` `#33202A` `#543427` `#7C512F` `#A97542`
**Foliage** — `#0E1A1C` `#1B3229` `#2F5432` `#4F7A34` `#86A83C`

Two shared singletons: **specular hit** `#FFF6DC` (warm; the only pure-bright pixel allowed on metal) and **line-dark** `#0B0A12` (contact shadow and inner silhouette only — never a fill).

### 4.2 UI accent set

> **⛔ SUPERSEDED 2026-09-09 by the art pass.** The accent set is the reference palette's; parchment/ink are gone. The five rarity NAMES stay ✅ CANON; Legendary moves from orange to gold, the metal every reference border is made of. The text below is kept as the record of the rejected direction and is no longer built against. Authority: `art/ref/specs/04-palette.md` §4–6.

Doc 13 consumes these; the values live here so gear icons and HUD agree.

| Role | Hex | Use |
|---|---|---|
| Primary / gold | `#F2C14E` | Selection, currency, focus ring |
| Parchment | `#E8DCC0` | Panel ground |
| Ink | `#1A1620` | Body text |
| Positive | `#6FBF73` | High morale, upgrades |
| Caution | `#E8A33D` | Mid morale, warnings |
| Danger | `#D2493C` | Low morale, disband risk |

**Rarity colours.** The five rarity names are ✅ CANON — "(Common raiders)", "(uncommon raiders)", "(rare raiders)", "(epic raiders)", "(Legendary raiders)" (canon: raw notes, Guild Reputation). The colours are 🔷 PROPOSED: Common `#9A9AA5`, Uncommon `#5FB94E`, Rare `#4A8FD4`, Epic `#9B5FCB`, Legendary `#F0803C`.

### 4.3 The hue-shifting rule

Mandatory, and the single most enforceable quality rule in the document:

1. **Shadows shift cool and toward violet/blue.** Each step darker rotates hue −8° to −14° and *gains* 4–8% saturation. Never darken by reducing value alone.
2. **Lights shift warm and toward yellow.** Each step lighter rotates hue +6° to +12° and *loses* 8–15% saturation.
3. **Maximum 3 ramp steps on any single 64 × 80 sprite element.** Five-step ramps are for the whole character, not for one boot.
4. **No pure black, no pure white.** `#000000` and `#FFFFFF` are banned from the palette file.
5. **Ambient occlusion is a hue shift, not a multiply.** Contact areas move toward `#0B0A12` by hue, not by opacity.

### 4.4 Night / low-reputation variant

✅ CANON: "Reputation determines what starts appearing around town" (canon: raw notes, Guild Reputation). 🔷 PROPOSED: the town also reads *dimmer and colder* at low reputation and *warmer and brighter* at high — canon says things appear, not that light changes, so this is my extension.

Do **not** hand-paint night copies of every plate. Night and low-reputation grading is a shader pass (doc 14) driven by these anchors:

| Anchor | Hex | Application |
|---|---|---|
| Ambient tint (multiply) | `#5A6AA8` | 62% at night, 28% at "Unknown/Known" daytime |
| Shadow floor (lift) | `#101423` | Clamps ramp step 5 upward so night shadows are not black holes |
| Lamp key (additive) | `#FFC46B` | Point lights at lantern/forge positions |
| Lamp bounce | `#C97B3A` | Radius 40 art-px, quadratic falloff |
| Moon rim | `#A8C4E8` | Rim light, upper-left, 1 art-px at 3× |

Art's obligation is to **tag lamp and forge positions as slices** in each building source (§7.3) so the shader has emitter anchors.

### 4.5 Palette files and the commit rule

The vendored Aseprite install keeps palettes at `Aseprite/palettes/` — it currently contains only `default.ase`. Aseprite also ships `Aseprite/docs/gpl-palette-extension.md`, which documents the GIMP-palette extensions it understands.

🔷 PROPOSED rules:

1. The shared palette is committed to the repo at **`art/_palettes/a-guild-story-master.gpl`** (source of truth, diffable) with a mirrored **`a-guild-story-master.ase`** for artists who prefer it.
2. A copy is placed in `Aseprite/palettes/` so it appears in every artist's palette dropdown. That copy is a **convenience artifact** — never edit it; edit the `art/_palettes/` file and re-copy.
3. `art/_palettes/night-anchors.gpl` holds §4.4 values for reference only; it is not used for sprite authoring.
4. Palette changes require a design review. A silent palette edit invalidates every sprite already drawn against it.
5. Character and gear sources are authored in **Indexed** colour mode against the master palette. Painted environment plates are **RGB** — see Q3.

---

## 5. Character art specification

### 5.1 Silhouette rules — the nine classes

✅ CANON: the nine classes and their roles (canon: raw notes, Classes). 🔷 PROPOSED: every silhouette rule below.

**The requirement:** all nine must be nameable as a pure black fill at 24 × 32 art-px, and distinguishable in a 12-person lineup (✅ CANON raid size 12) that will often contain duplicates of a class.

| Class | Role (✅ canon) | Silhouette rule — the one thing that identifies it |
|---|---|---|
| Warrior | Main Tank | Widest shoulder box, full closed helm; **the only shield silhouette** (✅ canon slot matrix: Warrior Shield) |
| Cleric | Main Tank Healer | Tallest vertical: straight unbroken hem to the floor, weapon held high, flat tome at the hip |
| Druid | Raid Healer | Asymmetric organic mass — antler/leaf headpiece breaking the head outline, ragged uneven hem, forward hunch |
| Shaman | Chain Healer | **Only class with dangling elements** — headdress fetishes and hem cords that swing on their own 2-frame offset |
| Rogue | Melee DPS | Smallest and lowest; deep crouch, twin blade points at hip height, eyepatch notch in the head profile (✅ canon: Rogue Eyepatch) |
| Monk | Melee DPS / Offtank | Bare arms (only class with no sleeve), headband tails, **2H staff held horizontal** across the body (✅ canon: 2H Monk Weapon) |
| Mage | AoE Caster | **Wide conical brim** — widest head outline in the cast; staff with a bulbous flame finial (✅ canon: Apprentice's Firestaff) |
| Wizard | Single-Target Caster | **Tall narrow hat + long beard mass**; staff with a thin crystal spike, no bulb (✅ canon: Apprentice's Arcstaff) |
| Bard | Support | Instrument as a **large flat plate** filling the off-hand (✅ canon slot matrix: Instrument); plumed hat |

**Highest-risk pair: Mage and Wizard.** Canon shares their armour (✅ "Mage/Wizard" head and chest/legs/feet in the slot matrix) and their weapon is a 2H staff for both. The *only* separators are hat shape and staff finial, so those must be exaggerated past the point of comfort: Mage brim ≥ 26 art-px wide with a bulb finial; Wizard hat ≥ 22 art-px tall with a spike finial and a beard reaching the belt. Second-riskiest: Cleric versus Druid versus Shaman, who share the entire canon Healer armour family — the head silhouette carries the whole distinction (circlet / antlers / headdress).

**Silhouette test (build gate).** `tools/silhouette_sheet.ps1` exports all nine at 24 × 32, alpha-thresholded to pure `#0B0A12`, into a single contact sheet. Gate: three people who have not seen the art name at least 8 of 9. Re-run whenever a head or weapon changes.

### 5.2 Required animation set

🔷 PROPOSED. Tag names are exact and load-bearing — they drive export (§7.3) and the engine reads them from the atlas JSON.

| Tag | Frames | ms/frame | Loop | Required for | Notes |
|---|---|---|---|---|---|
| `idle` | 4 | 160 | ping-pong | all | Breathing only; 1–2 px of motion |
| `walk` | 6 | 110 | forward | **ambient town NPCs only** (spline walkers, [02 §10.1](02-town-and-buildings.md) mitigation table) | Not on combat bodies, and not on a player avatar — there isn't one (§2.4) |
| `attack` | 5 | 80 | once | all | Hold frame 3 (impact) for 120 ms |
| `cast` | 6 | 90 | once | all | Frames 1–3 loopable as a channel; 4–6 release |
| `hit` | 2 | 90 | once | all | 2 px recoil, 1 frame of `#FFF6DC` flash |
| `death` | 7 | 110 | once, hold last | all | May rotate up to 90° (§3.3) |
| `fumble` | 8 | 120 | once | all | See §5.3 |
| `cheer` | 4 | 150 | ping-pong | all | Encounter clear, morale gain |

The tag table sums to 4 + 6 + 5 + 6 + 2 + 7 + 8 + 4 = **42 frames including `walk`**. Per-class total: **36 frames on a combat body** (excluding `walk`), **42 with `walk`**. Nine classes → **324 combat frames**.

**The whole character budget, not just the combat bodies.** 324 frames is one row of this table, not the total. Every §3.2 character asset, counted at Tier 1 (🔷 PROPOSED throughout):

| Asset | Count | Derivation |
|---|---|---|
| Combat/raid bodies | **324 frames** | 9 classes × 36 (all tags except `walk`) |
| Ambient town NPC set | **14 frames**, 1 set | `idle` 4 + `walk` 6 + `cheer` 4. One set recoloured for the 3→26 townsfolk of [02 §9.1](02-town-and-buildings.md), per [02 §10.1](02-town-and-buildings.md)'s "1 sprite set, recoloured" |
| Roster portraits (64 × 64) | **27 renders** | 9 shared class bases + 9 Rare accent overlays + 9 Epic per-class uniques (§5.4). Uncommon is a tint of the base, not a render |
| Recruit/inspect portraits (128 × 128) | **18 renders** | 9 shared class bases + 9 Epic per-class uniques; rarity accents reuse the roster overlay logic |
| Legendary hero portraits (160 × 192) | **9 bespoke** | 1 per class (✅ CANON "only ever find 1 Legendary per class"). Blocked on names — Q1 |
| Portrait expression overlays | **45 layers** | 5 expressions × 9 class portrait bases, reused across both portrait sizes |
| Morale chip glyphs | **10 sprites** | One per doc 05 band (§3.2); satisfies [13 §8.3](13-ui-ux.md)'s "all ten as authored sprites" |
| Boss sprites (192 × 192) | **5 actors** at Tier 1 | 4 tier-1 boss actors + 1 Tutorial Raid boss ([10 §12.1](10-content-and-encounters.md)). Clip sets and per-tier reuse are [10 §12.3](10-content-and-encounters.md)'s |
| Trash actor sprites | **6 actors** at Tier 1 | 5 tier-1 + 1 tutorial ([10 §12.1](10-content-and-encounters.md)); 6 base silhouettes recoloured per tier |

Note for reconciliation: [10 §12.3](10-content-and-encounters.md) prices raider sprites at "9 classes × (idle, attack, cast, hit, death) = 45 clips" — it omits `fumble` and `cheer`, which this doc requires (§5.3 is the game's joke). Doc 12's tag set governs; doc 10's clip count needs +2 clips per class.

**Morale expressions.** ✅ CANON: morale has ten bands with state names and the roster example shows emoji faces — "Natsuna — 87 ❤️ / Shaman — Very Happy", "Steve — 14 😡 / Mage — Upset" (canon: raw notes, Morale). 🔷 PROPOSED: **two separate assets, both counted above.** (1) *Morale chip glyph* — 10 authored sprites, one per doc 05 band, sized for the [13 §8.2](13-ui-ux.md) chip (20–28 px); these are art, never system emoji. (2) *Portrait expression overlay* — 5 layers per portrait (loving, happy, neutral, annoyed, furious) rather than one per band, because canon's ten bands collapse to eight distinct state names and only ~5 distinct faces. The band → glyph and band → expression mappings belong to doc 05; where each renders belongs to doc 13.

### 5.3 The fumble animation — where the comedy lands

🔷 PROPOSED. ✅ CANON establishes mistakes as the core mechanic — every morale band is described by its mistake chance, from "Very high mistake chance; may cause guild disband" to "Lowest mistake chance" (canon: raw notes, Morale). Doc 07 owns the taxonomy. This is the visual contract.

**Intent:** the player must be able to tell a fumble happened *without reading text*, from a full-lineup camera, in under 500 ms.

| Frame | Beat | Requirement |
|---|---|---|
| 1 | Commit | Identical to `attack`/`cast` frame 1 — the fumble must start as a competent action |
| 2–3 | The tell | Something wrong: weapon slips, foot catches, spell fizzles at the fingertip |
| 4 | Freeze | 1-frame hold at 200 ms. **The comedy is in the pause.** |
| 5–6 | Consequence | Overbalance, rotation up to ±12° (§3.3) |
| 7–8 | Recovery | Return to `idle` frame 1 pose, shoulders dropped 1 px |

Mandatory accompaniments: a `#F2C14E` "!" glyph 6 art-px above the head on frames 3–5 (readable at lineup scale), and the camera punch-in from §2.4. Required variants: `fumble` (generic, all classes). Optional: `fumble_2`, `fumble_3` for variety — export tolerates their absence.

**Per-class fumble flavour** (one line each, so nine fumbles do not read as one animation): Warrior drops the shield; Cleric heals the wrong direction (turns 90° away); Druid's heal lands as a puff of leaves; Shaman's chain heal bounces back into their own face; Rogue stabs the empty air behind the target; Monk over-rotates the staff and hits themselves; Mage's AoE detonates at their own feet; Wizard's single-target beam fires straight up; Bard's instrument string snaps.

### 5.4 Rarity visual language

✅ CANON: five raider rarities, and the rules that gate them by reputation rank (canon: raw notes, Guild Reputation). ✅ CANON: "You can only ever find 1 Legendary per class - They are also named characters - IE Natsuna(the shaman) or something."

🔷 PROPOSED: the visual language. **A Common raider must look bad, not just plain.** Canon hands us the vocabulary for free — the starting gear is literally named *Worn* Iron Cap, *Damaged* Chainmail, *Tattered* Vestments, *Frayed* Headband, *Old* Boots (canon: raw notes, Starting armor for common recruits). That damage vocabulary is the Common tier's art direction.

| Rarity | Ramp steps used | Silhouette | Material | FX | Portrait |
|---|---|---|---|---|---|
| Common | 3 (steps 2–4 only; no true light or dark) | Broken outline: dents, missing straps, one bare foot | No specular anywhere | None | Shared per class |
| Uncommon | 4 | Intact but plain | One dull specular pixel on metal | None | Shared, tinted |
| Rare | 5 | Intact + one accent panel | Cool rim light on 1 side | 1 static emissive pixel on the weapon | Shared + accent |
| Epic | 5 + gold ramp trim | Added shoulder or hem element | Full specular pass | 2-frame emissive cycle; sparse particle | Per-class unique |
| Legendary | 5 + gold + unique accent hue | **Unique silhouette element** the class does not otherwise have | Per-frame emissive | Light shaft (doc 14) + persistent particle | **Bespoke, named** |

**Legendary production rule.** Nine bespoke named characters × 36 frames would double the character budget. 🔷 PROPOSED: a Legendary **reuses its class's body sheet** and replaces only the gear, weapon, and FX layers, plus a bespoke 160 × 192 portrait. Cost: ~9 layer sets and 9 portraits instead of 324 new frames. The one named example in canon is "Natsuna(the shaman)"; the other eight Legendary names are ❓ OPEN and must come from the designer — see Q1.

### 5.5 Gear as layers, and the production win hidden in canon

🔷 PROPOSED. Gear is not baked into body sheets. Each body source carries ordered gear layers (§7.2) and gear is authored as **layer overlays covering all 36 frames** of the combat body it attaches to (42 on a town body, which carries `walk`).

This is expensive, which is why canon's sharing model matters as *production*, not just design. The ✅ CANON slot matrix (canon: ideaboard, §1) shares armour across classes: Warrior/Bard, Monk/Rogue, Healer (Cleric/Druid/Shaman), Mage/Wizard. Tier 1 asset count under that sharing:

| Family | Slots | Visual tiers (Starting / Adventure / Raid) | Layer sets |
|---|---|---|---|
| Body armour: Warrior/Bard, Monk/Rogue, Healer, Mage/Wizard | chest, legs, feet | 3 | 4 × 3 × 3 = 36 |
| Heads: Warrior, Warrior/Bard, Monk Headband, Rogue Eyepatch, Healer, Mage/Wizard | head | 3 | 6 × 3 = 18 |
| Weapons and off-hands (11 canon families) | main, off | ~3 | ~33 |
| **Tier 1 total** | | | **~87** |

The three visual tiers map to canon's own three naming vocabularies: *Worn/Damaged/Tattered/Frayed/Old* (starting), *Iron Adventurer's / Reinforced / Blessed / Spellweave / Apprentice's* (Tier 1 Adventure), *Raider's* (Tier 1 Raid). Art must make those three read as three distinct silhouette weights — broken, solid, ornamented. Stats and drop tables belong to the itemisation doc; only the visual grouping is mine.

**The 18 icon base shapes.** The same sharing logic governs the inventory icons, and here the count is a hard ceiling set by [10 §12.2](10-content-and-encounters.md): ~360 item records across five tiers resolve to **18 base shapes × 5 tier palettes = 90 renders**, and doc 10 calls that reuse "not optional". Tier identity is *palette*, never geometry — canon's own naming already says so (`Iron Adventurer's Boots` → `Raider's Boots` is one silhouette in two palettes). 🔷 PROPOSED, these are the 18, grouped by the canon slot families:

| Group | Shapes | Count |
|---|---|---|
| Heads | helm (Warrior/Bard) · headband (Monk) · eyepatch (Rogue) · circlet (Healer) · pointed cap (Mage/Wizard) | 5 |
| Chests | cuirass (plate) · leather vest · robe (Healer and Mage/Wizard share the silhouette; palette separates them) | 3 |
| Legs | rigid legs (greaves / plate) · soft legs (leather, cloth, spellweave) | 2 |
| Feet | boot (plate and leather) · soft shoe (sandal, shoe, slipper) | 2 |
| Weapons | blade (1H sword; the dagger is the same shape at 0.7 length, per Q5) · 2H staff (Monk, Mage, Wizard, and the healer weapons) | 2 |
| Off-hands | shield · instrument · tome | 3 |
| Trinkets | charm | 1 |
| **Total** | | **18** |

Adding a 19th shape is a doc 10 amendment, not an art decision — the 90-render figure is doc 10's budget and this doc must not quietly exceed it.

---

## 6. Environment art specification

### 6.1 The layer stack — what makes tilt-shift work

🔷 PROPOSED. Every scene, town or raid, is built from this stack. DoF has nothing to blur unless the depth is real, so this table is a hard requirement, not a suggestion.

| Layer | Name | Parallax | Focus | Content |
|---|---|---|---|---|
| L0 | `sky` | 0.00 | far blur, max | Gradient, clouds, void |
| L1 | `far` | 0.15 | far blur, strong | Distant painted masses; desaturate 35%, lift toward ambient tint |
| L2 | `mid` | 0.40 | far blur, light | Buildings, treelines, arena walls |
| L3 | `play` | 1.00 | **sharp — the focal plane** | Characters, interactables, ground. Never blurred. |
| L4 | `near` | 1.25 | near blur, light | Barrels, fence posts, rubble |
| L5 | `fore` | 1.60 | near blur, heavy | Framing occluders — often pure `#0B0A12` silhouette |
| L6 | `atmos` | varies | additive, unblurred | Dust, embers, rain, light-shaft masks |

Rules: L3 is authored at 1:1 art-pixel scale and is the only sharp layer. L5 should cover 15–30% of the frame edges — that occlusion is what sells the diorama, and a scene with an empty L5 will look flat no matter how good L3 is. L1/L2 are painted (RGB); L3/L4/L5 props are pixel art. That mixed-fidelity seam is intentional and matches the reference.

### 6.2 Town buildings — two axes, stated explicitly

✅ CANON: the buildings are Guildhall, Tavern, Market, Blacksmith (marked "Maybe"), and Adventure's Board (canon: raw notes, Town as progression engine). ✅ CANON: six reputation ranks — Unknown, Known, Respected, Established, Renowned, Legendary. ✅ CANON: "the town will be improved by the raids you do. Mostly by gaining reputation levels. Which will unlock additional things in the town."

**There are two axes, and they are not the same axis.** [02 §9.2](02-town-and-buildings.md) is an explicit art contract keyed to **building level** (up to 4 per building); the six reputation **ranks** are a separate ladder that gates *when* a level becomes purchasable ([02 §11](02-town-and-buildings.md)). 🔷 PROPOSED, and this is the reconciliation: **building level is the plate driver — 4 art states per building — plus one per-rank lighting/prop pass.** Keying plates to rank instead would give Unknown and Known the same base plate, which fails [02 §2.1](02-town-and-buildings.md) criteria R1 (every building level owns ≥1 exterior swap) and R5 (rank readable from one HUD-less screenshot), and would contradict [02 §9.1](02-town-and-buildings.md), where Known already patches the Guildhall roof and adds a second Market stall.

**Level → exterior read.** These four states are this doc's rendering of [02 §9.2](02-town-and-buildings.md)'s per-level deltas; that table is the contract, this is the palette and layer treatment for it:

| Level | Read | Palette / lighting |
|---|---|---|
| L1 | Derelict — boarded windows, sagging roof, no light, weeds | Clamped to ramp steps 3–5; no lamp emitters |
| L2 | Patched — roof and door repaired, sign hung straight, one lit window | Steps 2–5; 1 lamp slice |
| L3 | Working — second storey, banner, brazier, painted signage, 1–2 NPCs | Full 5-step ramp; 2–3 lamp/forge slices |
| L4 | Prosperous — stone façade, the building's ornament (stained glass / covered row / lantern arch), warm interior spill, crowd | Full ramp + gold-ramp trim; full emitter set |

**Rank → scene pass.** A rank change fires three things at once, which is what satisfies R2's "≥3 scene deltas per rank": the §4.4 grading anchors move (cold/dim → warm/bright), each building's per-rank **prop overlay layer** toggles (a new sign, a delivery cart, a queue of recruits, a lit brazier), and the ambient townsfolk count steps up on [02 §9.1](02-town-and-buildings.md)'s 3 → 6 → 10 → 14 → 20 → 26 ladder. No repaint.

**The plate count, printed.**

| Line | Count | Source |
|---|---|---|
| Building exterior plates (level axis) | **18 authored** — Guildhall / Tavern / Market L1–L4, Blacksmith / Board L1–L3 — against [02 §10.2](02-town-and-buildings.md)'s budget of 5 × 4 = **20** | doc 02 §9.2, §11 |
| Reputation grade passes (rank axis) | **6** — shader-driven (§4.4), applied over whichever level plate is current. Zero new plates | doc 02 §10.2 |
| Per-rank prop overlay layers | 5 buildings × 6 ranks = **30** cheap layers | This doc |
| Bespoke square set pieces | **6** — restored fountain (Renowned), guild statue (Legendary), cobbled main path (Established), pennant line (Established), street-name plaque (Legendary), festival braziers / lanterns (Legendary) | doc 02 §9.1 |
| Set pieces already paid for by an L4 plate | Guildhall stained glass + tower, Market covered row, Tavern lantern arch — **0 extra** | doc 02 §9.2 |
| Bespoke props | **1** — the merchant caravan (Renowned) | doc 02 §9.1 |
| Ambient townsfolk | **1 sprite set, 14 frames** (§5.2), recoloured to populate 3 → 26. Town guards, busker, children and the stray cat are recolours plus one prop each, not new sets | doc 02 §9.1, §10.1 |

That accepts [02 §10.2](02-town-and-buildings.md)'s "≈ 5 buildings × 4 levels × 1 AU + 6 rank lighting passes" figure rather than undercutting it, and it comes in 2 plates under budget because doc 02 §11 currently gives the Blacksmith and the Board three levels each. If doc 02 later adds an L4 to either, that is +1 plate each and lands inside the existing 20.

Two notes for the designer. ❓ OPEN: the Blacksmith is marked "(Maybe)" in canon and its contents are hedged — "Equipment upgrades < Maybe", "Salvaging < If we do crafting". Art will not begin the Blacksmith until it is confirmed; a boarded-up Blacksmith facade is cheap insurance and is scheduled first regardless. ❓ OPEN: canon describes what appears at Unknown, Known, Respected and Renowned but says nothing about **Established** or **Legendary**, so two of the six rank passes have no canon brief — only [02 §9.1](02-town-and-buildings.md)'s proposal and my grade/prop mapping above. See Q2.

### 6.3 Raid encounter backdrops

✅ CANON: the five-encounter structure and its star difficulty ladder — "Encounter 1 (Trash) ★", "Encounter 2 (Harder trash) ★★", "Encounter 3 (Mini boss) ★★★", "Encounter 4 (Mini boss) ★★★★", "Encounter 5 (Main boss of tier) ★★★★★" (canon: raw notes, Raid Layout and loot drops). ✅ CANON: naming is pending — "obviously they will need names later, but this is a placeholder". This doc uses canon's placeholders (Raid 1, Adventure 2, Boss 3) and invents no lore names.

🔷 PROPOSED per raid: **one painted L0/L1/L2 environment identity, five dressings.**

| Encounter | ★ (✅ canon) | L3/L5 dressing | Lighting grade | Atmos |
|---|---|---|---|---|
| Encounter 1 | ★ | Entry space, wide, few occluders | Neutral, ambient 100% | Light dust |
| Encounter 2 | ★★ | Narrower, L5 coverage up to 25% | Ambient 85%, one cool key | Dust + drips |
| Encounter 3 | ★★★ | Arena with a raised platform | Ambient 70%, warm rim | Embers |
| Encounter 4 | ★★★★ | Same arena, damaged; debris on L4 | Ambient 55%, hard key, long shadows | Embers + ash |
| Encounter 5 | ★★★★★ | Bespoke boss arena, full L5 frame | Ambient 40%, single dramatic key + light shafts | Full stack |

Cost per raid: ~3 painted plates, 5 dressing sets, 5 grades, plus boss sprites. The escalation must be legible from the backdrop alone — a player should feel Encounter 4 is worse than Encounter 2 before anything attacks.

Also required and easy to forget: ✅ CANON "Adventure 0 - 1 Trash mob (Just for learning - 1 crap trinket)" and "Tutorial Raid - 1 Boss (Just for learning - 1 crap trinket)" each need a backdrop and a distinctly poor-looking trinket icon. Canon's word for the reward is "crap" and the example is "Like a +1 dps trinket or something" — the icon should read as visibly worthless.

---

## 7. The Aseprite pipeline

Aseprite is vendored at **`Aseprite/Aseprite.exe`** in the project root, ✅ CANON as the tool ("Aseprite is in the project root; use it heavily for sprite work"). **Installed version verified this session: `Aseprite 1.3.7-x64`.** Every flag claim in §7.4 was checked against that binary's own `--help` output, and the marked subset was executed.

**§7.1, §7.5, §7.6 and §7.7 describe the pipeline as it is built** (rewritten 2026-09-15, art overhaul W4-HYGIENE, closing audit finding PIPE-14 — the first draft of this section proposed a tree, a manifest and a PowerShell driver that were never built, and an implementer reading it would have built a second pipeline beside the real one). §7.2-§7.4 are the Aseprite facts that were verified by execution and still hold; where a proposal in them was overtaken (`verify_tags.lua`, the `art/characters/` example paths) the paragraph says so in place. The short version: **a generator writes both the `.aseprite` source and the runtime PNG; `./tools/build_art.sh --check` proves the tree still matches the generators; nothing in the build calls MCP.**

### 7.1 Source tree

As built (the listing is `find art -maxdepth 2`, 2026-09-15; `art/` carries a `.gdignore`, so Godot imports nothing under it — `tests/unit/test_project_hygiene.gd` pins that only `game/` is imported):

```
art/
  .gdignore
  src/              GENERATED .aseprite sources — the editable record, written by the generators
    ui/             the chrome 9-slices, plates, frames, the faces sheet (tools/aseprite/gen_ui.lua, gen_wipe.lua, gen_icons.lua)
    ui/icons/       the icon grid, one .aseprite per glyph (gen_icons.lua; the manifest is game/assets/ui/icons/grid/icons.json)
    items/          the 39x39 gear icons (gen_items.lua)
    vfx/            fires, embers, the combat strips, the soft light (gen_fire.lua, gen_vfx.lua)
    enemies/        the six boss ranks and their glow layers (gen_boss_anims.lua)
    bg/             *_raw.png — the un-patched plates tools/art/patch_bubbles.py / patch_plate.py read from
  export/           the SLICED REFERENCE LIBRARY: tools/art/slice.py cuts these out of the concept sheets by the
                    rects in art/ref/manifests/all.json (721 rows) — background, banner, boss, building, enemy,
                    misc, npc, portraits_rejected, prop, raider, tile, ui_ornament, vehicle, vfx
  ref/
    manifests/      all.json (every rect: sheet, x,y,w,h, proposed_name, category, key, thresh; `ui_crop` rows
                    also carry `ships`, the game path — tests/unit/test_art_sources.gd re-cuts them), sheet_a.json, sheet_b.json
    specs/          00-11: the measured specs (canon reconciliation, the three concept layouts, palette, type,
                    component kit, the two asset sheets, background plates, screen audit, engine architecture)
  raiders/  town/  ui/     EMPTY — leftovers of the first draft's tree; git does not track an empty directory
```

What the game loads lives under **`game/assets/`**, beside its `.import` sidecar: `ui/` (chrome, wordmarks, wipe textures, `faces*.png` + `.json`, `icons/` and `icons/grid/`), `vfx/` (`vfx.json` manifest; W4-LIFE adds `vfx/life/`), `actors/` (56+ figure strips + `actors.json` + `class_actors.json`, written by `tools/art/gen_actors.py`), `enemies/` (`enemies.json`, `anim/`), `portraits/`, `bg/` (the six bare `stage_*.png` plates), `scenes/` (the six scene JSONs `SceneStage` reads), `fonts/`.

**The truth rule, as it actually works.** For generated art the generator is the source of truth and the `.aseprite` under `art/src/` is its editable record: `tools/aseprite/gen_*.lua` writes the `.aseprite` (`L.save_ase`) *and* the runtime PNG (`L.save_png`) in one run, and `./tools/build_art.sh --check` regenerates everything into a scratch directory and byte-compares the runtime files (`verify.sh` stage 2b; a hand edit to a shipped PNG is a build failure). For sliced art the manifest rect is the source: `slice.py cut` reproduces the PNG byte-for-byte from the concept sheet, and `test_art_sources.gd` proves it. A PNG that neither a generator nor a manifest row nor `enemies.json` names fails `test_every_shipped_png_names_its_source` by name — that is the moment to record where it came from. `build/` is scratch except `build/plan/` (the loop's memory); the old `build/atlas/` export loop was deleted in W0-LIB because nothing ever read it (`tools/build_art.sh` header records the ruling).

File naming: `snake_case`, no spaces, no capitals, no version suffixes (`_v2`, `_final`) — version control handles that.

### 7.2 Layer conventions

🔷 PROPOSED. Layers are prefixed with a two-digit order key so the stack is unambiguous and sortable:

| Prefix | Layer | Notes |
|---|---|---|
| `00_shadow` | Contact shadow | `#0B0A12`, 40% opacity |
| `10_body` | Base body + skin | The only layer that must exist |
| `20_gear_legs` `25_gear_feet` `30_gear_chest` `40_gear_head` | Gear slots | Match canon slot names |
| `50_weapon_main` `55_weapon_off` | Weapons | Off-hand empty for Monk/Mage/Wizard (✅ canon: no off-hand) |
| `60_fx` | Emissive, flash, rarity FX | Additive blend |
| `_normals/` | Normal proxy group (§3.4) | **Hidden** |
| `_ref` `_guide` | Reference and guides | **Hidden** |

**The hidden-layer rule is load-bearing and verified.** The installed Aseprite's own help text states, for `--all-layers`: *"Make all layers visible / By default hidden layers will be ignored."* So reference and guide layers only need to be **hidden** to be excluded from export — no `--ignore-layer` bookkeeping required. The corollary: **never pass `--all-layers` on a character export**, or every guide layer ships.

### 7.3 Tag and slice conventions

🔷 PROPOSED. Animation tags are the export contract.

1. Tag names are exactly the §5.2 names: lowercase, `snake_case`, no spaces. Verified: tag names arrive in the atlas JSON as `meta.frameTags[].name`.
2. Tags must not overlap and must cover every frame. (No tag checker was ever built — `verify_tags.lua` from the first draft does not exist; `./tools/build_art.sh --tags <file>` lists a source's tags, and the generated strips carry one tag each from `L.strip`. A checker is owed the day a hand-authored animated source lands.)
3. Aseprite's per-tag loop direction is honoured — verified present in the JSON as `"direction": "forward"`. Set `ping-pong` on `idle` and `cheer` in Aseprite rather than hard-coding loop behaviour in the engine.
4. Frame durations are set in Aseprite, not in engine code. Verified: they export per frame as `"duration": 100`.
5. **Slices** carry anchor data: `anchor_weapon`, `anchor_cast`, `anchor_overhead`, and for buildings `lamp_01…n`, `forge_01…n` (§4.4). Verified: slices export under `meta.slices` when `--list-slices` is passed.

### 7.4 Aseprite CLI export — verified commands

The canonical single-file export. This exact shape was **executed successfully** against `Aseprite 1.3.7-x64` when this section was written; the `art\characters\…` and `build\atlas\…` paths in the examples are illustrative (that tree was never built — §7.1) and the shipping pipeline does not export sheets this way at all (§7.6). The flag facts and the four gotchas below are what to keep:

```
.\Aseprite\Aseprite.exe -b art\characters\rogue\rogue_body.aseprite --sheet-type packed --sheet build\atlas\rogue_body.png --data build\atlas\rogue_body.json --format json-array --list-tags --list-layers --list-slices --filename-format "{title}_{tag}_{tagframe1}" --shape-padding 1 --inner-padding 1
```

The same call as a PowerShell array (kept as the verified way to build an Aseprite argument list from PowerShell 5.1, should a script ever need one — the pipeline's driver is bash, §7.6):

```powershell
$aseprite = Join-Path $PSScriptRoot '..\..\Aseprite\Aseprite.exe'
$argv = @(
  '-b', 'art\characters\rogue\rogue_body.aseprite'
  '--sheet-type', 'packed'
  '--sheet', 'build\atlas\rogue_body.png'
  '--data',  'build\atlas\rogue_body.json'
  '--format', 'json-array'
  '--list-tags', '--list-layers', '--list-slices'
  '--filename-format', '{title}_{tag}_{tagframe1}'
  '--shape-padding', '1', '--inner-padding', '1'
)
& $aseprite @argv
if ($LASTEXITCODE -ne 0) { throw "Aseprite export failed: rogue_body" }
```

(Use `$argv`, not `$args` — `$args` is an automatic variable in PowerShell.) Verified output shape, abridged from a real run:

```json
{ "frames": [
   { "filename": "rogue_body_idle_1",
     "frame": { "x": 0, "y": 0, "w": 64, "h": 80 },
     "spriteSourceSize": { "x": 0, "y": 0, "w": 64, "h": 80 },
     "sourceSize": { "w": 64, "h": 80 }, "duration": 100 } ],
  "meta": { "version": "1.3.7-x64", "format": "RGBA8888",
    "frameTags": [ { "name": "idle", "from": 0, "to": 1, "direction": "forward" } ],
    "layers": [ { "name": "body", "opacity": 255, "blendMode": "normal" } ],
    "slices": [ ] } }
```

**Flag confidence.** This is the part to trust or verify, stated plainly.

| Confidence | Flags |
|---|---|
| **Executed and confirmed this session** (1.3.7-x64) | `-b`/`--batch`, `-p`/`--preview`, `--sheet`, `--data`, `--format json-array`, `--format json-hash`, `--sheet-type packed`, `--sheet-type rows`, `--list-tags`, `--list-layers`, `--list-slices`, `--filename-format`, `--tagname-format`, `--shape-padding`, `--inner-padding`, `--trim`, `--split-layers`, `--all-layers`, `--script`, `--script-param`, `--version`, `--help` |
| **Confirmed present in the installed binary's `--help`, not executed — verify before depending on it** | `--sheet-pack`, `--sheet-width`, `--sheet-height`, `--sheet-columns`, `--sheet-rows`, `--split-tags`, `--split-slices`, `--split-grid`, `--layer`/`--import-layer`, `--ignore-layer`, `--tag`/`--frame-tag`, `--frame-range`, `--ignore-empty`, `--merge-duplicates`, `--border-padding`, `--trim-sprite`, `--trim-by-grid`, `--extrude`, `--crop`, `--slice`, `--scale`, `--save-as`, `--palette`, `--color-mode`, `--oneframe`, `--export-tileset`, `-v`/`--verbose` |
| **Filename-format tokens confirmed by execution** | `{title}`, `{tag}`, `{tagframe}` (0-based), `{tagframe1}` (1-based), `{layer}` |

**Four gotchas found by actually running it.** These will each cost someone a day if undocumented.

1. **Argument order matters.** Aseprite applies options to the files around them. With `--split-layers` placed *after* the input file, `{layer}` expanded to an **empty string** (frame keys came out as `_idle_1`) and `--tagname-format "{layer}:{tag}"` produced `":idle"`. Moving `--split-layers --all-layers` *before* the filename gave correct `body_idle_1`. **Rule: put mode flags before the input path, output flags after.**
2. **`--trim` trims each frame independently**, which destroys a shared pivot across an animation — a fumble will slide around. Confirmed: trimmed frames report their own reduced `frame.w/h` with the original in `sourceSize`. Either do not trim character sheets, or make the importer reconstruct position from `spriteSourceSize` + `sourceSize`. Default for characters: **no trim.**
3. **Empty layers silently vanish** under `--split-layers` — a layer with no cels produces no frames at all. Never derive expected frame counts from layer counts.
4. **`-p`/`--preview` is a true dry run**: it prints the full plan (sheet type, computed size, output paths, data format), writes nothing, and exits 0. Confirmed. (The shipping check is not a preview but a full regeneration and byte-compare — §7.6 — because a plan that prints the right paths says nothing about the pixels.)

Second worked example — a building plate split by layer for the parallax stack, showing the corrected flag order:

```
.\Aseprite\Aseprite.exe -b --split-layers --all-layers art\town\guildhall\guildhall_l3.aseprite --sheet-type rows --sheet build\atlas\guildhall_l3.png --data build\atlas\guildhall_l3.json --format json-hash --list-layers --list-slices --filename-format "{layer}_{frame1}" --border-padding 2
```

(`--all-layers` is correct *here* — a building plate has no hidden guide layers — and wrong on characters, per §7.2.)

### 7.5 Tooling status: MCP server and the CLI fallback

**Status.** The Aseprite MCP server (`plugin:pixel-plugin:aseprite`, pixel-mcp, ~50 tools) was misconfigured for months on a renamed-folder path and was fixed on 2026-09-13 (config at `~/.config/pixel-mcp/config.json`; the fix is recorded in the project memory); it has connected since, and it still fails to connect in some sessions (`CONNECTION_CLOSED`). Nothing in the tree depends on it. The build never has.

**The rule that keeps the pipeline unblocked:** the MCP server is an *accelerator only*. **Every pipeline step must be expressible as a CLI invocation or a `--script` Lua script, and the build must never call MCP.** If a task can only be done through MCP, it is not part of the pipeline. `--script` and `--script-param` are confirmed working (§7.4); `tools/aseprite/lib.lua` is the scripted equivalent of everything the catalogue draws (it draws lines, arcs, ellipses, polygons, ordered dither, masks and the derived outline/rim/depth/glow treatments, and authors real frames + tags through `L.strip`), and `tools/art/slice.py` + PIL cover every crop/resize/flip the catalogue offers.

**What MCP is for (audit PIPE Part 3, the tool map).** Three bins:

| Bin | Tools | Use in this repo |
|---|---|---|
| Interactive design session — decide, then encode the decision in a generator | `analyze_reference`, `analyze_palette_harmonies` / `sort_palette` / `get_palette`, `suggest_antialiasing` / `apply_auto_shading` / `apply_shading` / `apply_outline`, `get_pixels` / `get_sprite_info`, `draw_with_dither`, `downsample_image` / `scale_sprite` (rotsprite), `quantize_palette` / `set_palette` | reading a concept crop's palette or composition before authoring a match; trying a treatment on a WIP sprite; prototyping an aerial-scale figure for a designer eye-test. Its palette output feeds `art/ref/specs/04-palette.md`, never the build. |
| Convenience only — a scripted equivalent exists | `create_canvas` / `save_as` (`L.new_sprite` / `L.save_ase`), `draw_pixels` / `draw_rectangle` / `fill_area` (`L.px` / `L.fill` / `L.rrect_fill` / `L.chrect_fill`), `draw_circle` / `draw_line` / `draw_contour` (`L.circle` / `L.line` / `L.arc` / `L.poly_fill`), `export_sprite` (`L.save_png`), `import_image` (`L.import_png` / `L.blit`), `add_frame` / `create_tag` / `set_frame_duration` (`L.strip`), `crop_sprite` / `resize_canvas` / `flip_sprite` (`slice.py`, PIL), `get_sprite_info` (`build_art.sh --tags`) | use whichever is faster to think in; commit only the generator. |
| Build-violating if depended on | any MCP call inside `tools/build_art.sh`, `tools/verify.sh` or a generator | never. The catalogue offers nothing the CLI cannot do; the only MCP-unique value is the analysis bin, which produces decisions, not files. |

**Session protocol (so MCP output never becomes an unreproducible asset):**

1. Design in MCP on a scratch `.aseprite` under `scratchpad/`, never under `art/src/`.
2. When it looks right, `get_pixels` / `get_palette` to read the result, then write the generator (Lua spans or shapes through `lib.lua`) that reproduces it, and commit ONLY the generator and its outputs. `./tools/build_art.sh --check` must print `0 DIFFERS 0 MISSING` afterwards.
3. If the shape is too organic to code (a boss, an aerial figure), the `.aseprite` itself becomes the source under `art/src/<category>/`, hand-editable (real layers, frames, tags — §7.2/§7.3), and a generator step *reads* it (the way `gen_boss_anims.lua` derives the boss strips from the sliced stills) so the byte check still covers the runtime file.

Recovery, when the server will not connect: confirm `Aseprite/Aseprite.exe` runs (`./Aseprite/Aseprite.exe --version` → `Aseprite 1.3.7-x64`), then re-check `~/.config/pixel-mcp/config.json` and restart the session. Do not block art production on it.

### 7.6 The build: `tools/build_art.sh`

As built (W0-LIB replaced the first draft's `art/export.manifest.json` + `art/tools/export_all.ps1` — neither was ever written — with one bash driver; there is no PowerShell in the pipeline, which also retires §9 Q12). Run from the repo root in Git Bash; `tools/env.sh` exports `$ASEPRITE` (the vendored exe) and `$GODOT`.

| Invocation | Behaviour |
|---|---|
| `./tools/build_art.sh --gen` | Runs every `tools/aseprite/gen_*.lua` headlessly (`"$ASEPRITE" -b --script <lua>`), writing the `.aseprite` sources under `art/src/` **and** the runtime PNGs under `game/assets/` in one pass. |
| `./tools/build_art.sh --check` | Runs the same generators with `--script-param out=build/artcheck.<pid>/` — `lib.lua` prefixes every path it writes with that directory, so no generator knows it is being checked — then byte-compares every regenerated `game/**` file with the tree. Prints `ART CHECK  generators=N  runtime files: A agree  D DIFFERS  M MISSING` and `ART CHECK OK`; exit 1 on any DIFFERS or MISSING (the scratch dir is kept for diffing). Regenerated `.aseprite` sources are compared and reported but do not fail the check: the runtime bytes are the contract. The two Python generators that cannot go through `lib.lua`'s prefix carry their own `--check` and are run here too (`tools/art/gen_clouds.py --check`, `tools/art/gen_actors.py --check`). |
| `./tools/build_art.sh --tags <file.aseprite>` | Lists a source's animation tags (`--list-tags` must precede the file on Aseprite's command line — the wrapper exists so nobody rediscovers that). |

**This is the CI gate:** `tools/verify.sh` stage **2b/8 "generated art matches its generator"** runs `--check` on every gate run (timeout `ASEPRITE_TIMEOUT`, 180 s). A hand edit to a generated PNG, or a generator change without its regenerated outputs, fails the build with the file named.

**Generators and what each writes** (`tools/aseprite/`, all through `lib.lua`, all deterministic — no `math.random`, seeded LCGs only, so a re-run is byte-identical and the check means something):

| Generator | Writes |
|---|---|
| `gen_ui.lua` | the chrome: panels, plates, buttons, chips, the callout plate/tail/flourish, the cork tile, the speech and emote bubbles, the stamp frame, the pin — `art/src/ui/*.aseprite` + `game/assets/ui/*.png`; W4-CURSOR adds the two cursors |
| `gen_icons.lua` | the icon grid (`Icons.at(role, key)` is the only door in code): `art/src/ui/icons/**` + `game/assets/ui/icons/grid/*.png` + `icons.json` (name, role, key, file, cell — `tests/unit/test_icons.gd` walks it against `game/ui/Icons.gd`'s size table), the faces sheets at three text scales, the legacy top-level icons |
| `gen_items.lua` | the 39x39 gear icons — `art/src/items/` + `game/assets/ui/icons/item_*.png` |
| `gen_vfx.lua` | the six combat strips (slash, spark, bolt, burst, heal, poof) — `art/src/vfx/` + `game/assets/vfx/` (+ `vfx.json`, which `tests/unit/test_vfx_assets.gd` reads for frame geometry) |
| `gen_fire.lua` | the banded fires (camp, hearth, torch), the ember, the soft light; W4-LIFE's lantern flame under `game/assets/vfx/life/` |
| `gen_wipe.lua` | the wipe's ink blot and wax seal, the emblem — `game/assets/ui/{wipe_blot,wax_seal,emblem}.png` |
| `gen_boss_anims.lua` | idle/hit/death strips plus a glow layer per boss rank, derived from the sliced stills — `art/src/enemies/` + `game/assets/enemies/anim/` (+ `enemies.json`) |

Python generators under `tools/art/` are run by hand (each documents its own invocation in its header): `gen_actors.py` (the actor strips + `actors.json`, cut from the reference's sliced idle frames with the median-frame outlier drop and feet alignment `LESSONS.md` records), `gen_clouds.py` (the two tileable cloud layers), `gen_wordmark.py` (the wordmarks, the tagline, the splash), `derive_busts.py` / `make_portraits.py` (portraits), `place_enemies.py` (copies each boss rank's export over its rank name; `test_art_sources.gd` checks the bytes), `patch_bubbles.py` / `patch_plate.py` (inpainting a painted detail out of a plate, recorded as a PY step), `slice.py` (`islands` to find sprites on a sheet, `cut` to export a manifest's rects), and the instruments (`refdiff.py`, `refkit.py`, `contact_sheet.py`, `preview_scene.py`, `cvd.py`, `sheetscan.py`).

**Adding an asset (the conventions the tree actually follows — audit PIPE Part 4, as landed):**

1. **Source of truth**: a generator under `tools/aseprite/` writing an `.aseprite` under `art/src/<category>/` via `L.save_ase` and the runtime PNG via `L.save_png`; a new category is a new directory under `art/src/` and a row in §7.1's listing.
2. **Runtime PNG**: written DIRECTLY to its `game/assets/...` path — no atlas, no second export. Nothing loads from `build/`.
3. **`.import` sidecar**: Godot writes `<name>.png.import` on the next boot through the engine lock; the project default (335 sidecars) is `compress/mode=0`, `mipmaps/generate=false`, `process/fix_alpha_border=true`. Commit it beside the PNG; copying a neighbour's and letting Godot fill in the uid is fine; never hand-write a uid. `test_vfx_assets.gd` checks every VFX PNG has one; the boot gate fails on a `Failed to load`.
4. **Strips**: one row of frames, left to right, authored as real frames + one tag through `L.strip` (the `.aseprite` is GUI-editable) and exported as the one-row PNG. `frame_w` is declared by the CONSUMER: scene props carry `{"strip", "frame_w", "fps"}` in `game/assets/scenes/<scene>.json`, actors carry `frame_w/frame_h/frames/fps` in `actors.json`, VFX in `vfx.json`; `SceneStage._strip_frames()` cuts every `frame_w` px. No JSON comes out of Aseprite for these.
5. **9-slices**: `L.add_nine_slice(spr, name, l, t, r, b)` records the centre as an Aseprite slice and `L.check_nine_slice` asserts it; the margins are RE-DECLARED by hand in `game/ui/Theme.gd`'s `StyleBoxTexture` (the only file that names a 9-slice path). Keep both in sync.
6. **Icons**: never a path in a screen — a row in `gen_icons.lua`'s emit list and a lookup through `Icons.at(role, key)`; the grid's cell size per role is `Icons.SIZES` and the manifest must agree.
7. **Tests**: assets are asserted by existence and geometry (`test_icons.gd`, `test_vfx_assets.gd`, `test_scene_stage.gd` for `actors.json` against the PNGs, `test_art_sources.gd` for provenance), and screens by `Label.text` / `Button.text` only — so any visual that carries a word stays a Label (§7.7, doc 13 §14).
8. **Slicing from the reference sheets**: `python tools/art/slice.py islands <sheet> --key alpha|white|dark --thresh N --region x,y,w,h` to find, then a rect in `art/ref/manifests/all.json` and `slice.py cut --manifest art/ref/manifests/all.json --out art/export`. A sliced PNG is not a source; an edit to one lives nowhere reproducible unless it is re-expressed as a `tools/art/*.py` step (`derive_busts.py` is the pattern).

### 7.7 Handoff to Godot

Doc 14 owns the import side; this is only the contract. There is no atlas and no importer: a generator writes the runtime PNG to its `game/assets/` path (§7.6), Godot's own importer writes the `.import` sidecar, and the consumer declares the strip geometry (`frame_w`, `frames`, `fps`) in the JSON it reads — `game/assets/scenes/*.json` for props, `actors.json` for figures, `vfx.json` for the combat strips, `enemies.json` for the boss ranks. Animation tags exist in the `.aseprite` for the editor's benefit (§7.3), not for the engine.

**Texture filtering — the ruling (art/ref/specs/11-godot-architecture.md §2, `project.godot` `textures/canvas_textures/default_texture_filter=1`):** the project default is **Linear**, not Nearest. The art is dense 1:1 pixel art authored at display density (§3.1 was superseded — the references are 1536x1024 at 1:1), and nearest sampling at the fractional scales `display_aspect=expand` produces shimmers; at exactly 1536x1024 the two filters are identical, which is where the pixel-diff measures. A sprite that must stay crisp under a non-integer transform opts in per node — `texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST` on the `AnimatedSprite2D`/`Sprite2D` (`SceneStage.gd` does this for actors, the boss and the strips; `RaidView.gd` for its stage sprites); kit `TextureRect`s inherit Linear, which at 1:1 is the same pixels. The first draft's "Nearest filter, mipmaps off, Fix Alpha Border on — bilinear anywhere destroys the look" was written for the 640x360 grid that §3.1 no longer uses; mipmaps off and Fix Alpha Border on remain the sidecar defaults (§7.6 step 3).

No text is baked into any PNG (doc 13 §14; audit RULES-14): every word the player reads is a `Label` or `Button`, which is also what the screen tests can see. The pre-rendered wordmark is the one recorded exception, pending the designer's ruling (00-plan Q16).

---

## 8. Style guardrails

🔷 PROPOSED. The short version an artist can hold in their head.

**Do**

1. Author against the committed master palette, in Indexed mode, for characters and gear.
2. Hue-shift every ramp step — cool into shadow, warm into light (§4.3).
3. Keep the darkest value genuinely dark. The bloom needs something to sit against.
4. Build every scene with all seven layers, including a populated L5 foreground occluder.
5. Silhouette first. If it fails the 24 × 32 black-fill test, the detail pass is wasted.
6. Put the personality in `fumble` before `attack`. That is the game's joke.
7. Review at 1440p (4×), where a 1-art-pixel error is 4 device pixels and visible.
8. Hide reference and guide layers rather than deleting them — export already ignores hidden layers.

**Do not**

1. Do not add a colour that is not in the palette because "it needed one more step".
2. Do not use pure black or pure white.
3. Do not bake gear into a body sheet.
4. Do not add more than 3 ramp steps to a single small element — it reads as noise at 3×.
5. Do not hand-paint a night version of a plate; tag the lamps and let the shader grade it (§4.4).
6. Do not edit an exported PNG, or the palette copy in `Aseprite/palettes/`.
7. Do not put text in a sprite — that is doc 13's, and it will not localise.
8. Do not rely on hard pixel-grid snapping; the game is sub-pixel by decision (§3.3).
9. Do not invent lore names for unnamed content. Canon says names come later; use Raid 1, Adventure 2, Boss 3.

**Reference set.** ✅ CANON and primary: *Octopath Traveler* — specifically its town lighting at dusk and its battle-arena framing. 🔷 PROPOSED secondary references, for specific problems: *Triangle Strategy* (diorama depth on interior scenes), *Live A Live* remake (character readability at small scale), *Sea of Stars* (painted-versus-pixel seam handling), *Dead Cells* (high-frame-count character acting and rotation tolerance). Tool documentation to read before touching the pipeline: `Aseprite/docs/gpl-palette-extension.md` and `Aseprite/docs/ase-file-specs.md`.

---

## 9. Open questions

| # | Question | Why it matters | Proposed default |
|---|---|---|---|
| 1 | Canon names one Legendary raider — "Natsuna(the shaman)". What are the other eight? | ✅ CANON says 1 Legendary per class and that they are named characters. Nine bespoke portraits and gear sets cannot start without names. | Art builds Natsuna first; the other eight are blocked. No placeholder lore names invented. |
| 2 | What appears in town at **Established** and at **Legendary** reputation? | Canon describes Unknown, Known, Respected and Renowned but skips these two ranks, so two of six rank passes have no brief. | No shared plates — plates are keyed to building **level** (§6.2). Established and Legendary are **lighting-and-prop passes over the L3 and L4 plates**: Established = midday grade + cobbles, pennant line and painted signboards; Legendary = night/festival grade + statue, plaque and braziers. Each is a distinct pass, not a reused state. |
| 3 | Are painted environment plates authored in RGB, outside the master palette? | Determines whether L1/L2 artists are palette-bound. Pure palette discipline on painted plates costs quality; abandoning it costs cohesion. | L1/L2 painted in RGB but colour-checked against the palette's value range; L3/L4/L5 strictly palette-bound. |
| 4 | Is the Blacksmith in? Canon marks it "(Maybe)" with "Maybe" and "If we do crafting" on its contents. | A whole building plus its 3 level plates ([02 §11](02-town-and-buildings.md)), 6 prop overlays, and a crafting-UI icon set hang on it. | Author a boarded-up Blacksmith facade only. No interior, no crafting icons, until confirmed. |
| 5 | Does the Rogue read as swords or daggers? | Canon conflicts: raw notes give "Warrior / Rogue / Bard — Iron Adventurer's Sword", and the slot matrix shares a "Warrior/Rogue/Bard 1H" family, but the Tier 1 Raid table gives the Rogue "Basic Raid Dagger" in both hands. Silhouette rule §5.1 depends on the answer. | Draw the Rogue with twin daggers (the raid table is more specific), and treat the shared 1H sword as a Warrior/Bard silhouette. |
| 6 | Do we hand-author sprite normal maps? | Ingredient 7 is part of the target look, but per-sprite normals add a layer group and a second atlas to all ~87 gear sets. | Prototype normals on one class. If the shader gain is not obvious at 1440p, drop to a single baked light direction. |
| 7 | Layered 2D, or textured quads in a 3D scene? | Decides whether DoF is a per-layer screen effect or true depth-based, and whether the ground tilt is painted or geometric. Changes how every plate is authored. | Layered 2D with painted perspective. Revisit only if doc 14 finds per-layer DoF insufficient. |
| 8 | How many `fumble` variants per class ship at v1? | Nine classes × 8 frames is one week; ×3 variants is three. Repetition undercuts the core joke. | One `fumble` per class at v1; a second variant for the three most-played classes after playtest. |
| 9 | Do Warrior and Bard share one head asset? | Canon's slot matrix gives Warrior Head the family "Warrior" but Bard Head "Warrior/Bard", while the Tier 1 tables give both the identical "Raider's Helm — 5 AC / +5 HP / +1 Power". One asset or two. | One shared helm mesh with a Bard-only plume overlay layer — satisfies both readings cheaply. |
| 10 | Should the "!" fumble glyph be art or UI? | If it is a sprite layer it scales with the character and lives here; if it is UI it lives in doc 13 and can carry text. | Sprite layer `60_fx`, no text, so it works at lineup scale and needs no localisation. |
| 11 | Is the pixel layer composited through a fixed-res `SubViewport`, or drawn at integer scale into the native canvas? | [14 §2.2](14-technical-architecture.md) names `SubViewport` for this requirement; §3.1 rules it out. A 640 × 360 intermediate quantises all motion to art-pixels and silently deletes §3.3's sub-pixel positioning, the camera drift and the 1.04× punch-in. Pairs with Q7. | Native-resolution canvas, no `SubViewport` for the character/plate layer. Doc 14 amends its §2.2 cell — drop it, or qualify it as "only for effects that are deliberately art-pixel-quantised". Blocked until the engine prototype demonstrates sub-pixel motion at 3×. |
| 12 | PowerShell 7 (`pwsh`) on every machine, or author the pipeline for Windows PowerShell 5.1? | `pwsh` is not installed here. The two editions are materially different languages for script authors. | **Moot (2026-09-15):** the pipeline driver is `tools/build_art.sh` under Git Bash (§7.6); no PowerShell script exists in the pipeline. Kept as the record of why none was written. |

---

## Related documents

- [00 — Vision & Design Pillars](00-vision-and-pillars.md) — the pillars this art direction has to serve, including the "really awesome frontend" priority.
- [02 — Town & Buildings](02-town-and-buildings.md) — owns the buildings, the §9.2 per-level exterior contract that drives §6.2's plate count, and the §10.1 navigation ruling that §2.4 obeys (no player avatar).
- [03 — Guild Reputation](03-guild-reputation.md) — the six-rank ladder and rarity gating behind §5.4's visual language.
- [05 — Morale](05-morale.md) — the ten morale bands this doc ships as **two counted asset sets**: 10 authored chip glyphs and 5 portrait expression overlays (§3.2, §5.2). Doc 05 owns both mappings.
- [10 — Content Structure](10-content-and-encounters.md) — owns the §12.2 item-icon budget (18 base shapes × 5 tier palettes = 90 renders) that §3.2 and §5.5 are bound by, and the boss/trash actor counts in §5.2's totals table.
- [06 — Classes & Roles](06-classes-and-roles.md) — the class mechanics the §5.1 silhouettes must telegraph.
- [07 — Combat & Mistake Resolution](07-combat-simulation.md) — the mistake taxonomy the `fumble` animation in §5.3 visualises.
- [13 — UI/UX & Frontend](13-ui-ux.md) — consumes the §4.2 accent palette, the §3.2 canvas sizes, the 10 authored morale chip glyphs and the 5 expression overlays; owns all layout, the band colour ramp's *application*, and the town push-in timing referenced in §2.4.
- [14 — Technical Architecture](14-technical-architecture.md) — owns ingredients 5–8 (bloom, tilt-shift DoF, per-pixel lighting, light shafts) and the atlas importer from §7.7.
