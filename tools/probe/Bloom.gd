extends Control
## Renderer probe: does 2D glow work on the current renderer with hdr_2d?
##
## art/ref/specs/11 §6 step 1. The references' fire, crystals and portal all
## bloom; if this shot shows a hard-edged square instead of a soft halo, the
## project must move from the Mobile renderer to Forward+ before any effect
## work begins. Run:
##   godot --path . --script res://tools/shot.gd -- res://tools/probe/Bloom.tscn out.png 30 1536x1024


func build() -> void:
	for c in get_children():
		c.queue_free()

	var bg := ColorRect.new()
	bg.color = Color("060C12")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CANVAS
	e.glow_enabled = true
	e.glow_intensity = 1.0
	e.glow_strength = 1.0
	e.glow_bloom = 0.25
	e.glow_hdr_threshold = 1.0
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.environment = e
	add_child(env)

	# Left: an SDR white square — must NOT bloom (below threshold).
	var sdr := ColorRect.new()
	sdr.color = Color(0.95, 0.95, 0.95)
	sdr.position = Vector2(480, 460)
	sdr.size = Vector2(96, 96)
	add_child(sdr)

	# Right: an HDR ember-orange square well above 1.0 — MUST bloom.
	var hdr := ColorRect.new()
	hdr.color = Color(3.0, 1.8, 0.7)
	hdr.position = Vector2(960, 460)
	hdr.size = Vector2(96, 96)
	add_child(hdr)

	var l := Label.new()
	l.text = "BLOOM PROBE — left SDR (no halo), right HDR (halo expected)"
	l.position = Vector2(480, 600)
	add_child(l)
