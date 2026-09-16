# Handoff — W0-TEXTSCALE

Every file this unit needed was in its ownership list (Theme.gd, Type.gd, the fifteen
screens, Boot.gd, its own test). Nothing to apply.

The fourteen screen-level `add_theme_font_size_override("font_size", …)` sites that
bypass the theme are listed in `build/plan/report-W0-TEXTSCALE.md` under "Left for the
screen units"; they are in files the wave-2/3 screen units own, and the plan assigns
them there (00-plan.md §1 W0-TEXTSCALE build notes: "Widgets that hand-set sizes are
not this unit's"). The door for them is `Type.at(size, Theme_.scale_of(self))`.
