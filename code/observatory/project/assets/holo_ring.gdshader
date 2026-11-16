// The gold ring round the Prime Radiant in Seldon's hands (scripts/hologram_ix.gd): a faint circle
// once the viewer is near, filling clockwise from the top while they look at the sphere; full, it
// opens the hologram. Billboard; UV centred on the sphere.
// Blended over, not added, with a thin dark rim: under Compatibility the marble behind it is close
// to white, and gold added to white is white (the ring went unseen on the Web up to version 26).
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 gold : source_color = vec3(1.0, 0.8, 0.45);
uniform float near = 0.0;  // 0..1: shown as the viewer comes within reach
uniform float fill = 0.0;  // 0..1: gaze held

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 p = UV - 0.5;
	float r = length(p);
	float a = fract(atan(p.x, p.y) / 6.28318 + 1.0);  // 0 at the top, clockwise
	float w = fwidth(r);
	float ring = (1.0 - smoothstep(0.0, 2.0 * w, abs(r - 0.42)));
	float filled = ring * step(a, fill);
	float tick = (1.0 - smoothstep(0.0, 2.0 * w, abs(r - 0.47))) * step(abs(p.x), 0.012) * step(0.0, p.y);
	float g = clamp(ring * 0.35 * near + filled + tick * near, 0.0, 1.0);  // gold
	float rim = (1.0 - smoothstep(2.0 * w, 5.0 * w, abs(r - 0.42))) * 0.35 * near;  // dark, under it
	float alpha = g + rim * (1.0 - g);
	ALBEDO = gold * (1.0 + 0.6 * filled) * g / max(alpha, 1e-4);
	ALPHA = alpha;
}
