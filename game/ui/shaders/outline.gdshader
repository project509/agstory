// The alpha-dilate outline (PIPE-15, W4-CURSOR): every pixel within `width`
// texels of an opaque one is painted `color`, so a sprite with transparent
// margins grows a ring in its own canvas item, and a copy of a 9-slice drawn
// two pixels larger behind its plate (Widgets.Outline, `fill` = 1) becomes a
// ring that hugs the chamfered corners. Static on purpose: no TIME, no motion
// uniform, nothing here consults a setting — the ring is a state, not an
// animation, so reduced_motion has nothing to hold (00-plan §0.5).
//
//   color      the ring (a Palette token, set by the consumer; the default is
//              Palette.ACCENT_GOLD_LIGHT #FCB85D so a bare load still reads)
//   width      dilation radius in TEXELS, 0..2 on a 5x5 kernel; 0 = no ring,
//              only `fill` (a nine-patch stretches its texels, so a plate
//              copy uses 0 and grows by drawing larger instead)
//   fill       1.0 paints the opaque pixels too (a silhouette); 0.0 keeps the
//              texture's own pixels and adds the fringe only
//   threshold  the alpha that counts as opaque
shader_type canvas_item;

uniform vec4 color : source_color = vec4(0.988, 0.722, 0.365, 1.0);
uniform float width = 2.0;
uniform float fill = 0.0;
uniform float threshold = 0.5;

// The vertex colour is the CanvasItem's modulate; kept so a dimmed plate's
// ring dims with it.
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float near = 0.0;
	if (width > 0.0) {
		vec2 px = TEXTURE_PIXEL_SIZE * (width / 2.0);
		for (int x = -2; x <= 2; x++) {
			for (int y = -2; y <= 2; y++) {
				// A round kernel: the four corners of the 5x5 are skipped.
				if (x * x + y * y > 5 || (x == 0 && y == 0)) {
					continue;
				}
				near = max(near, texture(TEXTURE, UV + vec2(float(x), float(y)) * px).a);
			}
		}
	}
	float inside = step(threshold, tex.a);
	float edge = step(threshold, near) * (1.0 - inside);
	float k = max(edge, fill * inside);
	COLOR = mix(tex, color, k) * tint;
}
