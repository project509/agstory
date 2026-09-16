extends Control
const Widgets = preload("res://game/ui/Widgets.gd")
const Theme_ = preload("res://game/ui/Theme.gd")
func _c(t): return Widgets.chip(t, Color("E4C9AA"))
func build() -> void:
	theme = Theme_.get_theme()
	var bg := ColorRect.new(); bg.color = Color("0C151D")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(bg)

	# A: HBox explicit pos/size, children added BEFORE add_child
	var a := Widgets.row(24); a.add_child(_c("A-before"))
	add_child(a); a.position = Vector2(40, 40); a.size = Vector2(400, 45)

	# B: plain host explicit, HBox FULL_RECT, children added AFTER
	var hb := Control.new(); add_child(hb)
	hb.position = Vector2(40, 110); hb.size = Vector2(400, 45)
	var b := Widgets.row(24); b.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.add_child(b); b.add_child(_c("B-after"))

	# C: plain host explicit, HBox FULL_RECT, children added BEFORE reparent
	var hc := Control.new(); add_child(hc)
	hc.position = Vector2(40, 180); hc.size = Vector2(400, 45)
	var c := Widgets.row(24); c.add_child(_c("C-before"))
	c.set_anchors_preset(Control.PRESET_FULL_RECT); hc.add_child(c)

	# D: HBox explicit pos/size, children added AFTER add_child  <-- Kit's pattern
	var d := Widgets.row(24); add_child(d)
	d.position = Vector2(40, 250); d.size = Vector2(400, 45)
	d.add_child(_c("D-after"))

	# E: PanelWarm explicit pos/size, content added AFTER
	var e := Widgets.panel("PanelWarm", 10); add_child(e)
	e.position = Vector2(40, 320); e.size = Vector2(400, 70)
	Widgets.content_of(e).add_child(Widgets.label_as("E-after", "LabelSection"))
