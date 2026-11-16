// One step of an IX pipeline, as a hologram panel (scripts/hologram_ix.gd): a glowing frame, a faint
// fill, and a small chart of the step's real result. Additive and unshaded, like the data rain; the
// script turns it to face the viewer. UV (0,0) is the panel's top left.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 tint : source_color = vec3(0.4, 1.0, 0.78);
uniform vec3 accent : source_color = vec3(1.0, 0.78, 0.38);
uniform float appear = 0.0;  // 0..1 as the hologram unfolds
uniform float lit = 0.0;     // 0 waiting, 1 run
uniform float flash = 0.0;   // 1 the moment it runs, then fades
uniform vec2 size = vec2(0.48, 0.3);  // metres, for round corners and line widths
// What to draw: 0 nothing, 1 bars, 2 dots (values = class), 3 range (median, mean), 4 line,
// 5 pairs (birth, death; aux = dimension), 6 gauge, 7 verdict (values[0]: 1 T/P, 0.5 U, 0 D/F/C).
uniform int kind = 0;
uniform int count = 0;
uniform float values[96];
uniform float aux[48];

float box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

vec3 class_colour(float c) {
	if (c < 0.5) return tint;
	if (c < 1.5) return accent;
	return vec3(0.95, 0.45, 0.9);
}

// The chart in its own box: c in 0..1 both ways, y up. Returns colour.
vec3 chart(vec2 c, vec2 px) {
	if (kind == 1 && count > 0) {
		float i = floor(c.x * float(count));
		float f = fract(c.x * float(count));
		float h = values[int(clamp(i, 0.0, 95.0))];
		float on = step(c.y, max(h, 0.015)) * step(0.14, f) * step(f, 0.86);
		return tint * on * (0.55 + 0.45 * c.y);
	}
	if (kind == 2 && count > 0) {
		float cols = 16.0;
		float rows = ceil(float(count) / cols);
		vec2 cell = vec2(c.x * cols, (1.0 - c.y) * rows);
		float i = floor(cell.y) * cols + floor(cell.x);
		if (i >= float(count)) return vec3(0.0);
		float cls = values[int(clamp(i, 0.0, 95.0))];
		vec2 d = (fract(cell) - 0.5) * vec2(1.0, cols / rows * 0.6);
		float on = (1.0 - smoothstep(0.22, 0.32, length(d)));
		return class_colour(cls) * on * (cls > 0.5 ? 1.4 : 0.8);
	}
	if (kind == 3) {
		float line = (1.0 - smoothstep(0.0, 2.0 * px.y, abs(c.y - 0.5))) * 0.5;
		float med = (1.0 - smoothstep(0.0, 2.0 * px.x, abs(c.x - values[0]))) * step(abs(c.y - 0.5), 0.3);
		float mean = (1.0 - smoothstep(0.0, 3.0 * px.x, abs(c.x - values[1]))) * step(abs(c.y - 0.5), 0.45);
		float ends = (step(c.x, 2.0 * px.x) + step(1.0 - 2.0 * px.x, c.x)) * step(abs(c.y - 0.5), 0.25);
		return tint * (line + med + ends) + accent * mean;
	}
	if (kind == 4 && count > 1) {
		float d = 1e9;
		for (int i = 0; i < count - 1; i++) {
			vec2 a = vec2(float(i) / float(count - 1), values[i]);
			vec2 b = vec2(float(i + 1) / float(count - 1), values[i + 1]);
			vec2 pa = c - a, ba = b - a;
			float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
			d = min(d, length((pa - ba * t) / px));
		}
		return tint * (1.0 - smoothstep(0.8, 2.2, d));
	}
	if (kind == 5 && count > 0) {
		float diag = (1.0 - smoothstep(0.0, 1.5, abs(c.x - c.y) / px.x)) * 0.35;
		vec3 col = tint * diag;
		for (int i = 0; i < count; i++) {
			vec2 p = vec2(values[2 * i], values[2 * i + 1]);
			float on = (1.0 - smoothstep(2.0, 4.0, length((c - p) / px)));
			col += class_colour(aux[i]) * on;
		}
		return col;
	}
	if (kind == 6) {
		float bar = step(abs(c.y - 0.5), 0.18) * step(c.x, values[0]);
		float zero = (1.0 - smoothstep(0.0, 2.0 * px.x, abs(c.x - 0.5))) * step(abs(c.y - 0.5), 0.4);
		float track = step(abs(c.y - 0.5), 0.18) * 0.18;
		return tint * (bar + track) + accent * zero;
	}
	if (kind == 7) {
		vec3 col = values[0] > 0.75 ? tint : (values[0] > 0.25 ? accent : vec3(1.0, 0.35, 0.3));
		float ring = 1.0 - smoothstep(0.0, 3.0 * px.y, abs(length((c - 0.5) * vec2(size.x / size.y * 0.55, 1.0)) - 0.32));
		return col * ring * 1.3;
	}
	return vec3(0.0);
}

void fragment() {
	vec2 p = (UV - 0.5) * size;
	float d = box(p, size * 0.5, 0.03);
	float px = fwidth(d);
	float frame = (1.0 - smoothstep(0.0, 2.0 * px, abs(d + 0.006))) + 0.35 * (1.0 - smoothstep(0.0, 0.03, -d)) * step(d, 0.0);
	float fill = step(d, 0.0) * 0.06;
	// The chart takes the panel's middle: under the step's name, over its headline.
	vec2 lo = vec2(0.08, 0.30);
	vec2 hi = vec2(0.92, 0.66);
	vec2 c = (UV - lo) / (hi - lo);
	c.y = 1.0 - c.y;
	vec3 col = tint * (frame + fill);
	if (c.x >= 0.0 && c.x <= 1.0 && c.y >= 0.0 && c.y <= 1.0) {
		vec2 cpx = vec2(fwidth(c.x), fwidth(c.y));
		col += chart(c, max(cpx, vec2(1e-4))) * (0.25 + 0.75 * lit);
	}
	// Scanlines that drift, and a flicker: a projection, not a screen.
	float scan = 0.82 + 0.18 * sin((UV.y * size.y) * 380.0 - TIME * 6.0);
	float on = appear * (0.3 + 0.7 * lit) * scan;
	ALBEDO = col * on + vec3(0.9, 1.0, 0.95) * flash * (frame + fill * 2.0) * appear;
}
