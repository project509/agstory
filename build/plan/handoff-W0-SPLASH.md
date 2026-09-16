# Handoff — W0-SPLASH

Edits needed in files this unit does not own. Nothing here is applied by the unit.
Indentation: match each file (docs are Markdown; tests are four spaces).

Both edits are record-truth only: the two registers that deferred the `.ico` still say it is
deferred, and W0-SPLASH landed it. Neither edit touches canon (docs/_source) or a number.
The BL-67 heading sits under an explicit `<a id="bl-67">` anchor in docs/15, so changing the
parenthetical does not move a slug; the appended paragraph uses backtick paths, not links, so
`test_docs_links.gd` has nothing new to resolve. If W4-HYGIENE prefers to own these two lines,
drop this file — the wording below is the whole of what needs saying.

## 1. docs/15-open-questions.md:2507

old:
```
### BL-67 - What is the application icon, and is an `.ico` owed for 1.0? *(DECIDED - the emblem now, `.ico` deferred)*
```

new:
```
### BL-67 - What is the application icon, and is an `.ico` owed for 1.0? *(DECIDED - the emblem now; the `.ico` landed with the art overhaul's W0-SPLASH)*
```

## 2. docs/15-open-questions.md:2527

old:
```
**The `.ico` is deferred, not dropped** - it is a packaging asset, it needs a square source
at 16/32/48/256, and it is worth exactly one art task once somebody has looked at the
emblem at 32px. Recorded here so the next export pass does not discover it as a surprise.
```

new:
```
**The `.ico` is deferred, not dropped** - it is a packaging asset, it needs a square source
at 16/32/48/256, and it is worth exactly one art task once somebody has looked at the
emblem at 32px. Recorded here so the next export pass does not discover it as a surprise.

**Landed (art overhaul, W0-SPLASH, closing `build/plan/artaudit/CRITIC.md` G01).** The look
at 32px was taken and recorded in `build/plan/report-W0-SPLASH.md`. `tools/art/gen_wordmark.py`
now writes `game/assets/ui/icon_256.png` (the emblem at 3x on a GROUND_PAGE plate with an
EDGE_BRONZE rim - packaging, not a second mark) and `game/assets/ui/icon.ico`
(256/128/64/48/32/24/16); `config/icon` names the 256 square and the Windows preset's
`application/icon` and `console_wrapper_icon` name the `.ico`. The same generator writes the
boot splash (`application/boot_splash/image` on `boot_splash/bg_color = GROUND_PAGE`) and the
clear colour behind the letterbox bars is GROUND_PAGE too. Enforced by
`tests/unit/test_export.gd` (`test_the_icon_is_a_256_square`,
`test_the_windows_preset_ships_a_real_ico`, `test_the_boot_splash_is_ours`,
`test_the_letterbox_bars_are_ground_page`).
```

## 3. build/plan/q-housekeeping.md:45

old:
```
## Q-__ - What is the application icon, and is an `.ico` owed for 1.0? *(PROPOSED - the emblem now, `.ico` deferred)*
```

new:
```
## Q-__ - What is the application icon, and is an `.ico` owed for 1.0? *(PROPOSED - the emblem now, `.ico` deferred - LANDED by W0-SPLASH, see docs/15 BL-67)*
```
