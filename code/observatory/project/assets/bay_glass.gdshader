shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

// The glass of the hall's two glazed bays (scripts/palace_gardens.gd). Clear panes, through which the
// gardens show, reflect the hall more as they are seen more obliquely (Schlick's Fresnel), traced
// analytically as the gilt does (assets/hall_env.gdshaderinc: the far shelves, their lamp strips, the
// gallery slabs, the floor and the oculus, with parallax), since Compatibility has no screen-space
// reflections and Forward+ none on transparent surfaces. Above the transom (UV.y under fan_to), a
// fanlight of leaded quarries in colour, lit from the garden's lamps outside. UV spans the opening:
// x across, y from the head (0) down to the sill (1).

#include "res://assets/hall_env.gdshaderinc"

uniform vec2 size = vec2(4.6, 5.0);    // metres
uniform float fan_to = 0.2;           // UV.y of the transom: the fanlight above it
uniform vec3 jewel_a : source_color = vec3(0.95, 0.62, 0.2);
uniform vec3 jewel_b : source_color = vec3(0.2, 0.62, 0.66);
uniform vec3 jewel_c : source_color = vec3(0.55, 0.3, 0.75);
uniform float fan_energy = 0.75;
uniform float clear_alpha = 0.04;     // clear glass's own veil, seen square on
// At 0.3, the galleries' and shelves' arcs, reflected, banded the night sky through the panes
// (artpass/bays/art1-fwd).
uniform float reflect_energy = 0.15;
// Blurred as a rough leaf would be: sharp, the far shelves' rows of books, one shade per bay and
// row, showed over the city as a mosaic of blue-white blocks (artpass/bays/art3-fwd/canal_b5).
uniform float reflect_blur = 0.2;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 v = normalize(CAMERA_POSITION_WORLD - v_wpos);
	if (dot(n, v) < 0.0) {
		n = -n;
	}
	float ndv = clamp(dot(n, v), 0.0, 1.0);
	float fres = 0.04 + 0.96 * pow(1.0 - ndv, 5.0);
	vec3 r = reflect(-v, n);
	// Dimmed and capped: at full strength the far shelves' lamp strips crossed the panes as bright
	// bands, like blinds (artpass/bays/v1-fwd).
	vec3 env = min(hall(v_wpos + n * 0.02, r, reflect_blur, length(fwidth(r))), vec3(1.2)) * reflect_energy;
	vec2 m = UV * size;                // metres across and down
	if (UV.y < fan_to) {
		// Quarries: lozenges 0.3 m wide in lead cames, every few a jewel of colour, the rest pale
		// amber; lit through from the lamps beyond, brighter towards the middle.
		vec2 q = vec2(m.x / 0.3 + m.y / 0.42, m.x / 0.3 - m.y / 0.42);
		vec2 cell = floor(q);
		vec2 f = abs(fract(q) - 0.5);
		float w = max(0.04, length(fwidth(q)) * 0.7);
		float came = smoothstep(0.5 - w, 0.5, max(f.x, f.y));
		float pick = hash12(cell);
		// Pale amber, not white: at full strength the fanlight read as opal (artpass/bays/v4-fwd).
		vec3 pale = vec3(0.72, 0.6, 0.38);
		vec3 tint = pick < 0.18 ? jewel_a : (pick < 0.32 ? jewel_b : (pick < 0.42 ? jewel_c : pale));
		float lit = fan_energy * (0.55 + 0.45 * sin(UV.x * 3.14159)) * (0.8 + 0.4 * hash12(cell + 7.0));
		vec3 col = mix(tint * lit, vec3(0.03, 0.028, 0.025), came);
		ALBEDO = col + env * fres;
		ALPHA = mix(0.88, 0.97, came);
	} else {
		// Clear glass: a faint veil and the reflection; a little grime low down and at the edges.
		float grime = 0.02 * smoothstep(0.75, 1.0, UV.y) + 0.015 * hash12(floor(m * 40.0));
		ALBEDO = env;
		ALPHA = clamp(clear_alpha + grime + fres * 0.9, 0.0, 1.0);
	}
}
