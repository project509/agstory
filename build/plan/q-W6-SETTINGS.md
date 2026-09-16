# Proposed docs/15 entries — W6-SETTINGS (the Options screen, the window, the CVD option)

Two switches this unit landed under the wave-10 ship rule (ship plan §0.5 / §6). Numbers
are not claimed; W6-LEDGER assigns the next free ids and records both in spec 00 §2.7.
Nothing in `game/` cites these by number.

---

### BL-?? - `colourblind_safe` is a player option, default Off — the §8.3 ramp is reachable, the reference ramp is still the default *(TAKEN under the wave-10 ship rule; Q16 / M6-A11Y-06 still owed)*

**Owner:** docs/13 §8.3 / §13 / §15.1 - **Signal:** Quiet - a CVD player can now turn the ramp on; the default look is unchanged

`Palette.band_color_cvd` existed and nothing could select it: `Palette.cvd_safe()` probed
`GameSettings.DEFAULTS` for a key that was never there (UI-47). The key is there now
(`GameSettings.gd`, default `false`) with one Options row, "Colour-safe morale ramp",
whose control draws the ten bands as plates through `Palette.band_color_active` so the
choice is visible before any roster draws it. Ship plan §6 #40 names this default
(option, default off); the question — the reference's three-step red/amber/green or
§8.3's ten-step ramp as the ONLY ramp — is the designer's and is not resolved here.

Two facts the ruling needs: (1) the §8.3 fills are PLATES (band 0 measures 1.35:1 as
text on `SURFACE_PANEL`, `tests/unit/test_palette_cvd.gd`), so the option today drives
the plate sites only — the Options row's swatches, and by handoff the roster's morale
histogram and the raider detail's sparkline; every text-tint site (`Palette.morale_color`,
the roster cards' morale line, the raid view's card) keeps the reference ramp until the
ruling moves the chips to fill+ink plates (DESIGNER-40's wave-9 call-site pass). (2) the
docs/13 §15.1 row is in `handoff-W6-SETTINGS.md` §3-§4 and lands with the wave.

Switch: `GameSettings.DEFAULTS.colourblind_safe = false`. Flipping to `true` (the "only
ramp" ruling) also deletes the row (UI-47).

---

### BL-?? - The window opens borderless fullscreen; `window_mode` and `vsync` are live *(DECIDED - implemented)*

**Owner:** docs/13 §15.1 ("Native, borderless") / docs/14 (no display section — SHIP-06's
owed §10.4) - **Signal:** Loud - a fresh install on a 1366x768 laptop lost every commit row

`project.godot` opens the window fullscreen (`window/size/mode=3`) so a fresh install is
never larger than its screen before Boot runs; `Boot._apply_window_mode()` applies the
saved `window_mode` (`borderless` | `windowed`) and `vsync` before a frame paints;
`windowed` is a 3:2 window sized to the desktop's usable area
(`GameSettings.windowed_size`: 1020x680 on a 1366x728 desktop, the reference 1536x1024
wherever there is room); `F11` / `Alt+Enter` (`nav_fullscreen`) swap the two anywhere
(`ScreenRouter.toggle_fullscreen`); the Options rows "Window" and "V-sync" are live and
apply on press and on Apply. DESIGNER-44's default (keep the letterbox; borderless
fullscreen on first launch) is what shipped. docs/14's display section (SHIP-06's "new
§10.4") is still owed — W7-DOCS.
