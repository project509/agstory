extends "res://tests/TestCase.gd"
## W1-CHROME: the theme's new variations, the palette roles, the 9-slice
## assets and the faces font (00-plan.md §2 "W1-CHROME"; KIT-09/10/11/18,
## COMBAT-08/15, HALL-05, CRITIC-C02/C05/C08/C09/C14, RULES-07, HALL-07/12/14/17,
## TOWN-24). Static and pure: nothing here mounts a screen or touches an autoload.
##
## "Built vs armed" (LESSONS): every PNG the theme names is asserted to load, every
## Button-family variation is walked (not hand-listed) for its focus ring, and the
## faces font is proved by SHAPING a glyph and reading which font the text server
## drew it from — not by asserting a property was set.

const Palette = preload("res://game/ui/Palette.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
const Fonts = preload("res://game/ui/Fonts.gd")
const Type = preload("res://game/ui/Type.gd")
const Enums = preload("res://sim/model/Enums.gd")

## The roles 00-plan §2 W1-CHROME names (KIT-10's list plus the ones the
## theme's own hexes needed). Add only, never rename — 22 files preload Palette.
const NEW_ROLES := [
    "SURFACE_CARD", "EDGE_CARD", "EDGE_WELL", "SURFACE_BUBBLE", "EDGE_BUBBLE",
    "SURFACE_CALLOUT", "EDGE_CALLOUT", "SLOT_RIM", "SLOT_RIM_LIT", "BAR_RIM", "BAR_TRACK",
    "INK_NAV", "INK_NAV_ACTIVE", "EDGE_RAIL_CORE", "HEADER_DIVIDER", "SCROLL_TRACK",
    "SCROLL_THUMB", "INK_BUBBLE_DOTS", "INK_WORDMARK_OUTLINE",
    # the extra roles Theme.gd's remaining literals became
    "SURFACE_WELL", "SURFACE_ART_CARD", "EDGE_ART_CARD", "EDGE_CALLOUT_DANGER",
    "EDGE_BUBBLE_INNER", "SURFACE_TOOLTIP", "EDGE_TOOLTIP", "SURFACE_SLOT", "SURFACE_SLOT_LIT",
    "SURFACE_SLOT_BRONZE", "SURFACE_ABILITY", "EDGE_ABILITY", "EDGE_READY_GOLD",
    "SURFACE_PORTRAIT", "SURFACE_MINI", "EDGE_MINI", "SURFACE_PLATE", "SURFACE_PLATE_LIT",
    "EDGE_BRONZE_RIM", "EDGE_BRONZE_LIT", "TEXT_DISABLED", "TEXT_DISABLED_ON_CTA",
    "INK_NAV_DISABLED", "INK_NAV_GLYPH", "INK_NAV_GLYPH_ACTIVE", "INK_NUMBER_OUTLINE",
    "INK_BAR", "INK_BAR_OUTLINE", "GROUND_SEAM", "HEADER_RULE", "HEADER_RULE_LIT",
    "BAR_BOSS_LIGHT", "BAR_BOSS", "BAR_HP_FILL_LIGHT", "BAR_HP_FILL", "BADGE_DANGER",
    "SCROLL_THUMB_LIT", "SURFACE_PAPER", "EDGE_PAPER", "SURFACE_PAPER_LIT",
]

## The hexes the handoff replaces, so a token can never drift from the literal it
## stands in for (the whole point of KIT-10 was that no pixel moves).
const HANDOFF_HEXES := {
    "GROUND_SEAM": "020406", "HEADER_RULE": "3b3532", "HEADER_DIVIDER": "7a6152",
    "HEADER_RULE_LIT": "988880", "EDGE_RAIL_CORE": "463e3e",
    "INK_NAV_GLYPH_ACTIVE": "f9f3e0", "INK_NAV_GLYPH": "8a8a8a",
    "INK_NAV_ACTIVE": "f0e3d2", "INK_NAV": "9b9a9d",
    "BAR_RIM": "2c3f5c", "BAR_TRACK": "010d1b", "BAR_BOSS_LIGHT": "f24a50", "BAR_BOSS": "b01a28",
    "BAR_HP_FILL_LIGHT": "f54841", "BAR_HP_FILL": "811725", "INK_BAR_OUTLINE": "0b1118",
    "INK_BAR": "f5f1e8", "SURFACE_SLOT": "11181e", "BADGE_DANGER": "e44434",
    "INK_BUBBLE_DOTS": "3b2f27", "SURFACE_CARD": "020c14",
}

const PANELS := [
    "PanelWarm", "PanelSteel", "PanelRound", "PanelRoundSelected", "PanelInset", "PanelCard",
    "PanelCalloutDanger", "PanelCalloutCaution", "PanelCalloutPositive", "PanelChip",
    "PanelCallout", "PanelBubble", "PanelEmote", "PanelStamp", "PanelCork", "PanelPaper",
    "Slot", "SlotBronze", "SlotAbility", "SlotReady", "SlotWeapon", "PortraitFrame", "SlotMini",
]

const BUTTONS := [
    "Button", "ButtonCta", "ButtonCtaCost", "ButtonIcon", "ButtonPortrait", "NavItem",
    "NavItemActive", "ButtonSlot", "ButtonMini", "ButtonQuiet", "ButtonNotice", "ButtonChip",
]

## Every texture Theme.gd names. If one is missing the boot gate fails on
## `Failed to load`; this says which, in the unit suite, first.
const TEXTURES := [
    "panel_warm", "panel_steel", "panel_corner_ornament", "callout_flourish", "chip_chamfer",
    "callout_plate", "bubble_plate", "callout_tail", "emote_frame", "stamp_frame", "cork_tile",
    "pin", "cta_plate", "cta_glow", "cta_plate_pressed", "btn_secondary",
    "btn_secondary_pressed", "btn_icon", "nav_tab_active", "wipe_blot", "wax_seal", "faces",
]


func _consts() -> Dictionary:
    return (Palette as GDScript).get_script_constant_map()


func _button_family(t: Theme) -> Array:
    var out: Array = []
    for type_name in t.get_type_list():
        var walk: String = type_name
        var guard: int = 0
        while walk != "" and guard < 8:
            if walk == "Button" or walk == "LinkButton":
                out.append(type_name)
                break
            walk = t.get_type_variation_base(walk)
            guard += 1
    return out


# ------------------------------------------------------------------ palette

func test_every_new_role_exists_as_a_colour_and_is_not_pure() -> void:
    var consts := _consts()
    for role in NEW_ROLES:
        assert_true(consts.has(role), "Palette.%s is missing" % role)
        if not consts.has(role):
            continue
        assert_true(consts[role] is Color, "Palette.%s is not a Color" % role)
        var html: String = Color(consts[role]).to_html(false)
        assert_ne(html, "000000", "%s is pure black" % role)
        assert_ne(html, "ffffff", "%s is pure white" % role)


func test_handoff_tokens_carry_the_hexes_they_replace() -> void:
    var consts := _consts()
    for role in HANDOFF_HEXES:
        assert_eq(Color(consts[role]).to_html(false), HANDOFF_HEXES[role],
            "%s must keep the literal it replaced (no pixel moves)" % role)
    # the aliases the plan names are the bubble chrome's, until Q04 forks them
    assert_eq(Palette.EDGE_CALLOUT, Palette.EDGE_BUBBLE)
    assert_eq(Palette.SCROLL_THUMB, Palette.EDGE_BRONZE, "HALL-14: a bronze grabber")


func test_the_old_palette_contract_still_holds() -> void:
    # test_screens.gd:445-470's names; RARITY untouched; EDGE_STEEL kept (test_a11y).
    for role in ["GROUND_PAGE", "GROUND_FRAME", "GROUND_RAIL", "SURFACE_PANEL", "SURFACE_INSET",
            "EDGE_SLATE", "EDGE_BRONZE", "TEXT_TITLE", "TEXT_BODY", "TEXT_MUTED", "TEXT_SLATE",
            "CTA_TOP", "DANGER", "CAUTION", "POSITIVE", "ACCENT_GOLD", "EDGE_STEEL", "RARITY",
            "BAND_FILL_CVD", "BAND_INK_CVD", "TEXT_ON_BUBBLE", "ACCENT_BUBBLE", "INFO", "ARCANE"]:
        assert_true(_consts().has(role), "Palette.%s went missing" % role)
    assert_eq(Palette.RARITY.size(), Enums.RARITY_KEYS.size())


func test_theme_names_no_hex_literal() -> void:
    # KIT-10's acceptance: `grep -n 'Color("' game/ui/Theme.gd` is empty. The
    # WHOLE line is checked, comments included, because that is what the grep
    # (W4-HYGIENE's lint line) sees — review W1-CHROME F2 caught a comment that
    # quoted the pattern and tripped it.
    var f := FileAccess.open("res://game/ui/Theme.gd", FileAccess.READ)
    assert_true(f != null, "Theme.gd unreadable")
    if f == null:
        return
    var offenders: Array = []
    var n := 0
    while not f.eof_reached():
        var line := f.get_line()
        n += 1
        if line.contains("Color(\""):
            offenders.append(n)
    assert_eq(offenders, [], "Theme.gd lines with a hex literal: %s" % str(offenders))


# ------------------------------------------------------------------ variations

func test_every_panel_variation_exists_on_panelcontainer() -> void:
    var t: Theme = Theme_.build()
    for name in PANELS:
        assert_true(t.has_stylebox("panel", name), "%s has no panel StyleBox" % name)
        assert_eq(t.get_type_variation_base(name), "PanelContainer", name)


func test_callout_and_bubble_share_one_nine_slice_chrome() -> void:
    # CRITIC-C02 / Q04: one dark chrome for the building callouts and speech.
    var t: Theme = Theme_.build()
    for name in ["PanelCallout", "PanelBubble"]:
        var sb = t.get_stylebox("panel", name)
        assert_true(sb is StyleBoxTexture, "%s is not a 9-slice" % name)
        var s: StyleBoxTexture = sb
        assert_eq(s.texture_margin_left, 6.0, name)
        assert_eq(s.content_margin_left, 8.0, "%s keeps the 8px pad speech_plate/building_callout lay out on" % name)
        assert_true(t.has_icon("tail", name), "%s has no tail icon slot" % name)
        assert_eq(t.get_icon("tail", name).get_size(), Vector2(14, 8), "03 §3: the 14x8 tail")


func test_emote_frame_centres_a_16px_glyph() -> void:
    var t: Theme = Theme_.build()
    var s: StyleBoxTexture = t.get_stylebox("panel", "PanelEmote")
    assert_eq(s.texture.get_size(), Vector2(40, 44), "06 §8: 40x44")
    assert_eq(s.texture.get_width() - s.content_margin_left - s.content_margin_right, 16.0)
    assert_eq(s.texture.get_height() - s.content_margin_top - s.content_margin_bottom, 16.0)


func test_stamp_frame_is_a_tinted_tiled_nine_slice() -> void:
    # docs/13 §7 StampBadge; CRITIC-C08: the box IS the Label's parent (W1-KIT's
    # Widgets.stamp), so the theme provides the box and nothing deeper.
    var t: Theme = Theme_.build()
    var s: StyleBoxTexture = t.get_stylebox("panel", "PanelStamp")
    assert_eq(s.texture.get_size(), Vector2(24, 24))
    assert_eq(s.modulate_color, Palette.DANGER, "the default stamp is DANGER")
    assert_eq(s.axis_stretch_horizontal, StyleBoxTexture.AXIS_STRETCH_MODE_TILE)
    assert_eq(s.axis_stretch_vertical, StyleBoxTexture.AXIS_STRETCH_MODE_TILE)
    assert_true(s.content_margin_left >= 8.0, "the word must clear the double rule")


func test_board_chrome_cork_paper_pin() -> void:
    var t: Theme = Theme_.build()
    var cork: StyleBoxTexture = t.get_stylebox("panel", "PanelCork")
    assert_eq(cork.axis_stretch_horizontal, StyleBoxTexture.AXIS_STRETCH_MODE_TILE, "cork tiles")
    assert_eq(cork.texture.get_size(), Vector2(32, 32))
    var paper: StyleBoxFlat = t.get_stylebox("panel", "PanelPaper")
    assert_eq(paper.bg_color, Palette.SURFACE_PAPER)
    assert_true(t.has_icon("pin", "PanelPaper"))
    assert_eq(t.get_icon("pin", "PanelPaper").get_size(), Vector2(12, 12))


func test_ornament_and_flourish_slots_are_registered() -> void:
    # KIT-09: overlays, never baked into the 9-slice (they would stretch).
    var t: Theme = Theme_.build()
    for p in ["PanelWarm", "PanelSteel"]:
        assert_true(t.has_icon("corner_ornament", p), p)
        assert_eq(t.get_icon("corner_ornament", p).get_size(), Vector2(16, 16), p)
        assert_true(t.has_color("ornament_tint", p), "%s needs a tint for the white-on-alpha sprite" % p)
    for c in ["PanelCalloutDanger", "PanelCalloutCaution", "PanelCalloutPositive"]:
        assert_true(t.has_icon("flourish", c), c)
        assert_eq(t.get_icon("flourish", c).get_size(), Vector2(18, 14), c)


func test_selected_card_and_weapon_slot() -> void:
    var t: Theme = Theme_.build()
    var sel: StyleBoxFlat = t.get_stylebox("panel", "PanelRoundSelected")
    var plain: StyleBoxFlat = t.get_stylebox("panel", "PanelRound")
    assert_eq(sel.bg_color, plain.bg_color, "the selected card is the same plate")
    assert_eq(sel.border_color, Palette.EDGE_STEEL, "Tavern.gd:278's hand-rolled rim, as a variation")
    assert_eq(sel.corner_radius_top_left, plain.corner_radius_top_left)
    var w: StyleBoxFlat = t.get_stylebox("panel", "SlotWeapon")
    assert_eq(w.border_width_left, 1, "06 §2: 1px steel rim")
    assert_eq(w.corner_radius_top_left, 4)


func test_damage_number_variations_carry_type_gd_sizes_and_the_outline() -> void:
    # CRITIC-C05: Type.gd's 28/34 are the ruling; 05 §5's 2px outline.
    var t: Theme = Theme_.build()
    assert_eq(t.get_font_size("font_size", "LabelDamage"), Type.DAMAGE)
    assert_eq(t.get_font_size("font_size", "LabelDamageCrit"), Type.DAMAGE_CRIT)
    assert_eq(t.get_font_size("font_size", "LabelHeal"), Type.DAMAGE)
    for n in ["LabelDamage", "LabelDamageCrit", "LabelHeal"]:
        assert_eq(t.get_type_variation_base(n), "Label", n)
        assert_eq(t.get_constant("outline_size", n), 2, n)
        assert_eq(t.get_color("font_outline_color", n), Palette.INK_NUMBER_OUTLINE, n)
    assert_eq(t.get_color("font_color", "LabelDamageCrit"), Palette.CRIT)
    assert_eq(t.get_color("font_color", "LabelHeal"), Palette.POSITIVE)
    # and they scale through the one door like every other size
    var big: Theme = Theme_.get_theme(150)
    assert_eq(big.get_font_size("font_size", "LabelDamage"), Type.at(Type.DAMAGE, 150))


# ------------------------------------------------------------------ buttons

func test_every_button_variation_exists_with_all_four_state_boxes() -> void:
    var t: Theme = Theme_.build()
    for name in BUTTONS:
        for slot in ["normal", "hover", "pressed", "disabled", "focus"]:
            assert_true(t.has_stylebox(slot, name), "%s has no %s box" % [name, slot])
        assert_true(t.has_color("font_disabled_color", name), name)


func test_the_button_family_grew_and_every_member_keeps_the_ring() -> void:
    # test_a11y.gd:229-277's contract, re-stated here against the NEW members:
    # a texture button may replace normal/hover/pressed, never `focus`.
    var t: Theme = Theme_.build()
    var family: Array = _button_family(t)
    for name in BUTTONS:
        assert_has(family, name, "%s is not a Button variation" % name)
    assert_true(family.size() >= 13, "found %d Button-family types" % family.size())
    var reference: StyleBoxFlat = t.get_stylebox("focus", "Button")
    for type_name in family:
        var sb = t.get_stylebox("focus", type_name)
        assert_true(sb is StyleBoxFlat, "%s focus ring is not a StyleBoxFlat" % type_name)
        var f: StyleBoxFlat = sb
        assert_eq(f.border_width_left, 2, type_name)
        assert_eq(f.border_color, Palette.EDGE_STEEL, type_name)
        assert_true(f.expand_margin_left >= 2.0, "%s ring is inside its bounds" % type_name)
        assert_eq(f.expand_margin_left, reference.expand_margin_left, type_name)
        assert_almost(f.bg_color.a, 0.0, 0.001, type_name)
    assert_true(t.has_color("font_focus_color", "LinkButton"))


func test_pressed_boxes_drop_the_label_one_pixel() -> void:
    # docs/13 §12.3 "pressed = 1px inward offset"; KIT-11.
    var t: Theme = Theme_.build()
    for name in ["Button", "ButtonCta", "ButtonCtaCost", "ButtonIcon", "ButtonPortrait", "ButtonSlot",
            "ButtonMini", "ButtonQuiet", "ButtonNotice", "ButtonChip"]:
        var n: StyleBox = t.get_stylebox("normal", name)
        var p: StyleBox = t.get_stylebox("pressed", name)
        assert_eq(p.content_margin_top, n.content_margin_top + 1.0, name)
        assert_eq(p.content_margin_left, n.content_margin_left, "%s: only the top moves" % name)


func test_the_cta_states_are_four_plates_not_one_modulated() -> void:
    var t: Theme = Theme_.build()
    var n: StyleBoxTexture = t.get_stylebox("normal", "ButtonCta")
    var h: StyleBoxTexture = t.get_stylebox("hover", "ButtonCta")
    var p: StyleBoxTexture = t.get_stylebox("pressed", "ButtonCta")
    var d: StyleBoxTexture = t.get_stylebox("disabled", "ButtonCta")
    assert_ne(h.texture.resource_path, n.texture.resource_path, "hover is its own plate (the glow)")
    assert_ne(p.texture.resource_path, n.texture.resource_path, "pressed is the inverted plate")
    assert_eq(h.expand_margin_left, 6.0, "06 §3: the 6px glow draws OUTSIDE the control")
    assert_eq(h.texture_margin_left, 20.0, "14 + the 6px halo")
    assert_eq(h.content_margin_left, n.content_margin_left, "the label does not move on hover")
    assert_true(d.modulate_color.r < 0.6, "disabled dims")
    # the secondary family too
    var sp: StyleBoxTexture = t.get_stylebox("pressed", "Button")
    assert_true(sp.texture.resource_path.ends_with("btn_secondary_pressed.png"))


func test_icon_portrait_and_slot_buttons_have_real_pressed_and_disabled_boxes() -> void:
    # KIT-11: they used to reuse `normal` for pressed and/or disabled.
    var t: Theme = Theme_.build()
    for name in ["ButtonIcon", "ButtonPortrait", "ButtonSlot"]:
        var n: StyleBox = t.get_stylebox("normal", name)
        assert_ne(t.get_stylebox("pressed", name), n, "%s pressed == normal" % name)
        assert_ne(t.get_stylebox("disabled", name), n, "%s disabled == normal" % name)
    var d: StyleBoxTexture = t.get_stylebox("disabled", "ButtonIcon")
    assert_almost(d.modulate_color.r, 0.5, 0.01, "disabled = modulate 0.5")


func test_chip_pressed_state_is_lit_and_gold() -> void:
    # HALL-12 / HALL-17: a toggle's "on" is chrome, not font colour alone.
    var t: Theme = Theme_.build()
    var p: StyleBoxFlat = t.get_stylebox("pressed", "ButtonChip")
    var n: StyleBoxFlat = t.get_stylebox("normal", "ButtonChip")
    assert_eq(p.border_color, Palette.EDGE_READY_GOLD)
    assert_ne(p.bg_color, n.bg_color, "the plate lights")
    assert_eq(t.get_color("font_pressed_color", "ButtonChip"), Palette.ACCENT_GOLD)


func test_quiet_and_notice_buttons_are_buttons() -> void:
    # CRITIC-C14: "Back to town" stays a Button (the tests read Button.text);
    # RULES-07: a notice row is a full-rect Button with the paper's chrome.
    var t: Theme = Theme_.build()
    assert_eq(t.get_type_variation_base("ButtonQuiet"), "Button")
    assert_eq(t.get_type_variation_base("ButtonNotice"), "Button")
    var qn: StyleBoxFlat = t.get_stylebox("normal", "ButtonQuiet")
    assert_almost(qn.bg_color.a, 0.0, 0.001, "quiet: no plate at rest")
    var nn: StyleBoxFlat = t.get_stylebox("normal", "ButtonNotice")
    var pp: StyleBoxFlat = t.get_stylebox("panel", "PanelPaper")
    assert_eq(nn.bg_color, pp.bg_color, "a notice row is paper")
    var np: StyleBoxFlat = t.get_stylebox("pressed", "ButtonNotice")
    assert_eq(np.border_color, Palette.EDGE_STEEL, "pressed = selected")


func test_the_scrollbar_is_eight_pixels_of_bronze() -> void:
    # HALL-14 / TOWN-10: a list that scrolls says so.
    var t: Theme = Theme_.build()
    var track: StyleBox = t.get_stylebox("scroll", "VScrollBar")
    assert_eq(track.get_minimum_size().x, 8.0)
    var thumb: StyleBoxFlat = t.get_stylebox("grabber", "VScrollBar")
    assert_eq(thumb.bg_color, Palette.SCROLL_THUMB)
    assert_eq(Palette.SCROLL_THUMB, Palette.EDGE_BRONZE)


# ------------------------------------------------------------------ assets

func test_every_texture_the_theme_names_loads() -> void:
    for n in TEXTURES:
        var path := "res://game/assets/ui/%s.png" % n
        assert_true(ResourceLoader.exists(path), "%s missing" % path)
        var tex = load(path)
        assert_true(tex is Texture2D, "%s did not load as a texture" % path)


func test_the_wipe_assets_keep_their_geometry() -> void:
    # COMBAT-15 re-authored both; RaidView's placement and test_wipe_sequence's
    # seal-position checks assume these sizes.
    assert_eq((load("res://game/assets/ui/wipe_blot.png") as Texture2D).get_size(), Vector2(320, 150))
    assert_eq((load("res://game/assets/ui/wax_seal.png") as Texture2D).get_size(), Vector2(72, 72))
    var blot: Image = (load("res://game/assets/ui/wipe_blot.png") as Texture2D).get_image()
    if blot.is_compressed():
        blot.decompress()
    # a hard core: the centre of the blot is DANGER at ~85%, not a feathered cloud
    var c := blot.get_pixel(160, 76)
    assert_in_range(c.a, 0.80, 0.90, "COMBAT-15: DANGER at 85%%, got a=%.2f" % c.a)
    assert_almost(c.r, Palette.DANGER.r, 0.02)


func test_generated_chrome_has_the_measured_sizes() -> void:
    var sizes := {
        "callout_plate": Vector2(16, 16), "bubble_plate": Vector2(16, 16), "callout_tail": Vector2(14, 8),
        "emote_frame": Vector2(40, 44), "stamp_frame": Vector2(24, 24), "cta_glow": Vector2(60, 60),
        "cta_plate_pressed": Vector2(48, 48), "btn_secondary_pressed": Vector2(48, 48),
        "panel_corner_ornament": Vector2(16, 16), "callout_flourish": Vector2(18, 14),
        "cork_tile": Vector2(32, 32), "pin": Vector2(12, 12),
    }
    for n in sizes:
        var tex: Texture2D = load("res://game/assets/ui/%s.png" % n)
        assert_eq(tex.get_size(), sizes[n], n)


# ------------------------------------------------------------------ the faces font

func test_face_glyphs_are_the_sim_s_morale_glyphs_in_band_order() -> void:
    # Fonts.gd cannot name the table (tools/lint_motion.sh reserves the name for
    # the one display door), so this is where the two lists are pinned equal.
    assert_eq(Fonts.FACE_GLYPHS, Enums.MORALE_BAND_EMOJI)
    assert_eq(Fonts.FACE_GLYPHS.size(), Enums.MORALE_BAND_COUNT)


func test_the_bitmap_font_has_all_ten_faces_at_24px() -> void:
    var f: FontFile = Fonts.faces()
    assert_eq(f.fixed_size, 24)
    for g in Fonts.FACE_GLYPHS:
        var cp: int = String(g).unicode_at(0)
        assert_true(f.has_char(cp), "no glyph for U+%X" % cp)
    assert_false(f.has_char("A".unicode_at(0)), "the face font carries faces only")
    assert_almost(f.get_string_size("❤", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x, 24.0, 0.01)
    # the sheet it reads is gen_icons.lua's: ten 24px frames (faces.json agrees)
    var sheet: Texture2D = load("res://game/assets/ui/faces.png")
    assert_eq(sheet.get_size(), Vector2(240, 24))


## Shape `text` through `font` at `size` and return the glyphs' font rids in order.
func _shaped_rids(font: Font, text: String, size: int) -> Array:
    var ts := TextServerManager.get_primary_interface()
    var rid: RID = ts.create_shaped_text()
    ts.shaped_text_add_string(rid, text, font.get_rids(), size)
    ts.shaped_text_shape(rid)
    var out: Array = []
    for g in ts.shaped_text_get_glyphs(rid):
        out.append(g["font_rid"])
    ts.free_rid(rid)
    return out


func test_the_morale_variations_draw_every_face_from_the_face_font() -> void:
    # The proof is a SHAPE, not a property: shape each glyph through the
    # variation's font and read which font rid the text server assigned it.
    # ALL TEN are shaped — nine are astral Emoji_Presentation characters, which
    # this engine hands to the system colour-emoji font ahead of a non-colour
    # fallback unless the first font forbids system fallback (review W1-CHROME
    # F3: the first pass shaped only "❤", the one text-presentation glyph, and
    # was green over nine system emoji).
    var t: Theme = Theme_.build()
    var faces_rids: Array = Fonts.faces().get_rids()
    var astral := 0
    for name in ["LabelMorale", "LabelLog", "LabelBody", "LabelClass"]:
        var font: Font = t.get_font("font", name)
        var size: int = t.get_font_size("font_size", name)
        for g in Fonts.FACE_GLYPHS:
            var cp: int = String(g).unicode_at(0)
            if cp > 0xFFFF:
                astral += 1
            assert_true(font.has_char(cp), "%s cannot draw U+%X" % [name, cp])
            var rids: Array = _shaped_rids(font, g, size)
            assert_eq(rids.size(), 1, "%s shaped U+%X into %d glyphs" % [name, cp, rids.size()])
            if rids.size() == 1:
                assert_has(faces_rids, rids[0],
                    "%s drew U+%X from a system font, not faces.png" % [name, cp])
        # a mixed line, as the roster prints it: the letters from Fira Sans,
        # the face (the last glyph) from the sheet
        var mixed: Array = _shaped_rids(font, "Tiny — 14 😡", size)
        assert_true(mixed.size() >= 10, "%s shaped the mixed line into %d glyphs" % [name, mixed.size()])
        if mixed.size() >= 2:
            assert_has(faces_rids, mixed[mixed.size() - 1], "%s: the face of the mixed line" % name)
            assert_false(faces_rids.has(mixed[0]), "%s: the letters are not the face font's" % name)
    assert_eq(astral, 9 * 4, "nine astral glyphs were shaped through each of the four variations")
    # and a variation that carries no glyph is left on the plain face
    var plain: Font = t.get_font("font", "LabelSmall")
    assert_false(plain is FontVariation and (plain as FontVariation).fallbacks.size() > 0,
        "LabelSmall does not carry the face fallback")


func test_the_face_font_is_a_fallback_the_base_font_never_learns_about() -> void:
    # with_faces wraps a COPY of the base's file (system fallback off); it must
    # not mutate the shared Fira Sans resource or borrow a system font itself.
    var base: Font = Fonts.ui()
    var faced: Font = Fonts.with_faces(base)
    assert_ne(faced, base)
    assert_true(faced is FontVariation)
    var under: Font = (faced as FontVariation).base_font
    assert_ne(under, base, "the variation stands on a copy, not the shared file")
    assert_true(under is FontFile)
    assert_false((under as FontFile).allow_system_fallback, "the copy never borrows a system font")
    assert_true((base as FontFile).allow_system_fallback, "the shared Fira Sans still may")
    assert_eq(base.fallbacks.size(), 0, "Fira Sans itself is untouched")
    assert_eq(under.fallbacks.size(), 0)
    assert_eq((faced as FontVariation).fallbacks.size(), 1)
    assert_eq((faced as FontVariation).fallbacks[0], Fonts.faces())
    assert_false(Fonts.faces().allow_system_fallback, "the sheet holds ten faces and nothing else")
    assert_eq(Fonts.with_faces(base), faced, "cached per base font")
    assert_true(Fonts.MORALE_FACE_FONT is bool, "Q17's switch")
    # ui_tabular's base is itself a FontVariation: the copy keeps its tnum feature
    var tab: Font = Fonts.ui_tabular(500)
    var faced_tab: Font = Fonts.with_faces(tab)
    assert_ne(faced_tab, faced, "one wrapper per base")
    var ts := TextServerManager.get_primary_interface()
    assert_has((faced_tab as FontVariation).opentype_features, ts.name_to_tag("tnum"), "tabular figures kept")
    var tab_under: Font = (faced_tab as FontVariation).base_font
    assert_true(tab_under is FontFile and not (tab_under as FontFile).allow_system_fallback)
    assert_eq((tab as FontVariation).base_font, Fonts.ui_medium(), "ui_tabular itself is untouched")
    assert_true((Fonts.ui_medium() as FontFile).allow_system_fallback)


func test_turning_system_fallback_off_costs_no_character_the_interface_prints() -> void:
    # The four face-carrying variations can no longer borrow a system glyph, so
    # every non-ASCII character a Label in this game prints (grep of game/ and
    # sim/ outside comments, 2026-09-14) must be in Fira Sans's own cmap.
    var under: Font = (Fonts.with_faces(Fonts.ui()) as FontVariation).base_font
    for ch in ["§", "—", "·", "→", "…", "×", "±", "•", "°", "–", "−", "≈", "≤", "é", "ç", "‹", "›"]:
        var cp: int = String(ch).unicode_at(0)
        assert_true(under.has_char(cp), "Fira Sans lacks U+%X %s" % [cp, ch])
    # and the sheet's own copy of the glyph is the one drawn, not a .notdef box:
    # a missing glyph shapes to index 0 in the base font, never to the sheet
    var faced: Font = Fonts.with_faces(Fonts.ui())
    var rids: Array = _shaped_rids(faced, "…→", 15)
    assert_eq(rids.size(), 2)
    for r in rids:
        assert_false(Fonts.faces().get_rids().has(r), "punctuation is Fira Sans's, not the sheet's")
