shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, shadows_disabled;

// The Imperial Palace at the far end of the palace gardens (scripts/palace_gardens.gd, _build_palace),
// modelled in Blender (artpass/foundation/palace/make_palace.py) with its light baked by Cycles: its
// floodlights, its uplights, the shadows they cast and the light bounced between its stones, in a
// lightmap on the mesh's second UV (assets/palace/palace_light.png: (light / light_max) to the power
// 1 / 2.2, 8 bits, encode_lightmap.py). As assets/palace_garden.gdshader, it lights itself (no light
// is added to the scene) and fades into the same haze with distance.
//   kind 0: lit by the lightmap: stone, dark stone, gilt and the dome's glazing, by albedo
//   kind 1: the windows' glass, lit from inside in cells (UV in metres), as Blender draws them
//   kind 2: light itself: the rose window, the cyan lines, the lamps
// The beam from the spire into the sky has its own shader, added over the sky (palace_beam.gdshader).

uniform int kind = 0;
// Linear values throughout, as make_palace.py's MATS: no source_color, so that both renderers take
// them as given.
uniform vec3 albedo = vec3(0.66, 0.56, 0.42);
uniform vec3 emission = vec3(0.0);
uniform float emission_energy = 0.0;
uniform sampler2D light_tex : hint_default_black, filter_linear_mipmap, repeat_disable;
uniform float light_max = 8.0;
// Gilt (sheen > 0): brighter towards grazing angles, and a glint of the galactic core.
uniform float sheen = 0.0;
uniform vec3 core_dir = vec3(-0.468, 0.867, -0.170);
uniform vec3 core_light = vec3(0.9, 0.8, 0.66);
uniform float core_energy = 0.35;
// The dome's glazing (gloss > 0): the night sky and the city's glow in it.
uniform float gloss = 0.0;
uniform vec3 sky_low = vec3(0.05, 0.06, 0.11);
// Stone in detail up close (stone_detail > 0): assets/garden_stone.png, a photograph of stone divided by
// its mean colour and stored halved (0.5: no change), laid on three planes, and courses of blocks.
uniform sampler2D detail_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float stone_detail = 0.0;
uniform float detail_scale = 2.4;   // metres across the image
uniform vec2 block = vec2(1.8, 0.9); // a block's length and course height, metres
uniform vec2 glass_cell = vec2(3.5, 8.0);
// Forward+ tone maps (ACES) what Compatibility shows as it is (palace_gardens.gd's card had the same).
uniform float energy = 1.0;
// The lit surfaces' share of it: at the full energy the floodlit stone read white rather than the warm
// stone of Blender's previews (artpass/foundation/palace/NOTES.md).
uniform float lit_scale = 0.8;
uniform vec3 haze = vec3(0.016, 0.02, 0.036);
uniform float haze_distance = 900.0;

varying vec3 v_wpos;
varying vec3 v_wnorm;

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wnorm = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec3 to_output(vec3 c) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// There, the output is not converted to sRGB.
	return pow(max(c, vec3(0.0)), vec3(1.0 / 2.2));
#else
	return c;
#endif
}

void fragment() {
	vec3 n = normalize(v_wnorm);
	if (!FRONT_FACING) {
		n = -n;
	}
	vec3 eye = INV_VIEW_MATRIX[3].xyz;
	vec3 to_eye = eye - v_wpos;
	float dist = length(to_eye);
	vec3 v = to_eye / max(dist, 1e-4);
	float fade = exp(-dist / haze_distance);
	float m_px = max(length(dFdx(v_wpos)), length(dFdy(v_wpos))) + 1e-5;
	if (kind == 0) {
		vec3 lm = texture(light_tex, UV2).rgb;
		vec3 light = pow(lm, vec3(2.2)) * light_max;
		vec3 a = albedo;
		if (stone_detail > 0.0 && m_px < 0.2) {
			// Three planes, blended by the normal; the detail's average (1) once a block is a few pixels.
			vec3 w = pow(abs(n), vec3(4.0));
			w /= w.x + w.y + w.z;
			vec3 p = v_wpos / detail_scale;
			vec3 d = texture(detail_tex, p.zy).rgb * w.x + texture(detail_tex, p.xz).rgb * w.y + texture(detail_tex, p.xy).rgb * w.z;
			float near = 1.0 - smoothstep(0.05, 0.2, m_px);
			a *= mix(vec3(1.0), d * 2.0, stone_detail * near);
			// Courses of blocks on the walls, staggered, their joints a little darker.
			if (abs(n.y) < 0.6) {
				vec2 s = vec2(abs(n.x) > abs(n.z) ? v_wpos.z : v_wpos.x, v_wpos.y) / block;
				s.x += 0.5 * mod(floor(s.y), 2.0);
				vec2 f = abs(fract(s) - 0.5);
				vec2 jw = (0.008 + 0.5 * m_px) / block;
				float joint = max(smoothstep(0.5 - jw.x, 0.5, f.x), smoothstep(0.5 - jw.y, 0.5, f.y));
				a *= 1.0 - 0.35 * joint * (1.0 - smoothstep(0.04, 0.1, m_px));
			}
		}
		vec3 col = a * light;
		if (sheen > 0.0) {
			// Gilt: its baked light brighter at grazing angles, as metal reflects more there, and a glint
			// of the core.
			float f = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 3.0);
			col *= 1.0 + sheen * (0.4 + 2.0 * f);
			vec3 h = normalize(normalize(core_dir) + v);
			col += albedo * core_light * core_energy * sheen * 2.0 * pow(max(dot(n, h), 0.0), 48.0);
		}
		if (gloss > 0.0) {
			// The glazing: the sky low over the city in it, more at grazing angles.
			vec3 r = reflect(-v, n);
			float f = 0.04 + 0.96 * pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 5.0);
			vec3 sky = mix(sky_low * 2.5, sky_low * 0.6, clamp(r.y * 2.0, 0.0, 1.0));
			col += sky * f * gloss;
		}
		col = col * lit_scale + emission * emission_energy;
		ALBEDO = to_output(mix(haze, col * energy, fade));
	} else if (kind == 1) {
		// Lit cells, each its own brightness, a thin dark line under each row: Blender's UV is glTF's
		// upside down.
		vec2 q = vec2(UV.x, 1.0 - UV.y) / glass_cell;
		float lit = mix(0.35, 1.25, hash12(floor(q) + 19.0));
		float line = smoothstep(0.0, 0.06, fract(q.y));
		// Far off, the cells' average, so that they do not shimmer.
		float near = 1.0 - smoothstep(0.4, 1.0, m_px / glass_cell.x);
		float k = mix(0.8 * 0.94, lit * line, near);
		vec3 col = emission * emission_energy * k;
		ALBEDO = to_output(mix(haze, col * energy, fade) + col * energy * 0.15 * (1.0 - fade));
	} else {
		vec3 col = emission * emission_energy;
		// Light carries through the haze better than lit stone: a glow, not a surface.
		ALBEDO = to_output(mix(haze, col * energy, fade) + col * energy * 0.3 * (1.0 - fade));
	}
}
