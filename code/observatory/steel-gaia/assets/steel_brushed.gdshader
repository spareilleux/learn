shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Brushed steel for the Blender shell's SP_Steel panels and SP_SteelTrim trims (scripts/steel_cube.gd).
// It keeps the GLB's baked brushed normal and roughness maps and changes:
//   - fully metallic: the GLB's metallic channel is 0.55, which renders as grey paint;
//   - highlights stretched across the brushing (anisotropy), as on real brushed sheet;
//   - ComfyUI stains and streaks (assets/steel_grime.png, R stains, G streaks), projected in the
//     mesh's frame so they run downwards, vary the colour a little and the roughness a lot;
//   - box realism pass: each plate (octagon face x course between the bands) its own tone and
//     roughness, a contact shadow beside the bands, grime running down from under each band, and
//     dust near the plinth. A clean, uniform, evenly lit box read as a cartoon;
//   - the baked brushing sampled brush_scale times finer, and a slight oil-canning of each plate
//     (a low-frequency tilt of the normal), so reflections waver as on real sheet. At 3x and
//     roughness x0.95 the brushing's roughness streaks smeared reflections into vertical "rain";
//     6x and x1.3 give a satin sheet (artpass/box/NOTES.md, round 2).

uniform vec3 base_color : source_color = vec3(0.76, 0.75, 0.73);
uniform sampler2D metal_rough : hint_default_white, filter_linear_mipmap_anisotropic; // G: roughness
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D grime : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float grime_tile = 1.6;
// How much the ComfyUI stains (R) and streaks (G) vary the colour and roughness; 1 = as before.
uniform float stain_strength = 1.0;
uniform float streak_strength = 1.0;
uniform float roughness_scale = 1.3;
uniform float brush_scale = 6.0;
uniform float oil_can : hint_range(0.0, 0.2) = 0.05;
uniform float normal_depth = 1.0;
uniform float anisotropy_amount : hint_range(-1.0, 1.0) = 0.25;
uniform vec2 brush_flow = vec2(1.0, 0.0);
// 1 under Forward+. Lower under the Compatibility renderer, where a fully metallic shell has only
// the reflection probes and no SSR or GI to show (scripts/steel_cube.gd).
uniform float metallic : hint_range(0.0, 1.0) = 1.0;
// Multiplies the albedo. 1 under Forward+; warmer under Compatibility (scripts/steel_cube.gd).
uniform vec3 tint = vec3(1.0);
// Box realism pass. The seam heights (m, mesh frame) are the four bands of
// artpass/blender/steel_portal.py, bottom to top.
uniform vec4 seams = vec4(0.26, 1.45, 2.95, 4.22);
uniform float plate_variation : hint_range(0.0, 0.3) = 0.08;
uniform float seam_shadow : hint_range(0.0, 1.0) = 0.35;
uniform float run_length = 0.8;
uniform float run_strength : hint_range(0.0, 1.0) = 0.5;
uniform float dust_height = 0.9;
uniform float dust_strength : hint_range(0.0, 1.0) = 0.5;
uniform vec3 dust_color : source_color = vec3(0.34, 0.31, 0.27);
// Gaia art pass (OBSERVATORY-GAIA-ART-20261006, isolated copy); the defaults draw the steel as before.
// Vertical joints on the four wide faces at +-joint_s from their centre line (0: none): a dark groove
// joint_width wide, and each panel between joints its own tone.
uniform float joint_s = 0.0;
uniform float joint_width = 0.004;
// Rounded vertical edges: within edge_roll metres of a face's side edge (half widths of the wide and
// the cut faces of the octagon, mesh frame, measured in artpass/gaia/inspect_shell.gd) the normal
// turns toward the edge, up to 40 degrees, and the sheet is a little smoother there (0: none).
uniform float edge_roll = 0.0;
uniform float face_half_major = 1.442;
uniform float face_half_minor = 0.395;
// A slight warm or cool cast per plate, +- plate_hue (0: none).
uniform float plate_hue : hint_range(0.0, 0.1) = 0.0;
// Wear where hands touch: an upright ellipse around touch_center (mesh frame, x across, y up) where
// the sheet is polished: smoother, cleaner, a little brighter (0: none).
uniform vec3 touch_center = vec3(0.0);
uniform float touch_radius = 0.2;
uniform float touch_strength : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_opos;
varying vec3 v_onorm;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
		mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	v_opos = VERTEX;
	v_onorm = NORMAL;
}

void fragment() {
	vec3 n = normalize(v_onorm);
	vec3 w = pow(abs(n), vec3(4.0));
	w /= w.x + w.y + w.z;
	vec3 q = v_opos / grime_tile;
	// Side faces map height to the texture's v, so the streaks run down the walls.
	vec4 g = texture(grime, vec2(q.z, -q.y)) * w.x + texture(grime, q.xz) * w.y + texture(grime, vec2(q.x, -q.y)) * w.z;
	float stains = g.r;
	float streaks = g.g;

	// Walls only (not the roof): plates, contact shadow, run-off and dust.
	float wall = 1.0 - smoothstep(0.5, 0.8, abs(n.y));
	float y = v_opos.y;
	float face = round(atan(n.x, n.z) / (PI * 0.25)); // octagon faces sit at multiples of 45 degrees
	float course = step(seams.y, y) + step(seams.z, y);
	vec2 tangent = normalize(vec2(n.z, -n.x) + vec2(1e-5));
	float s_face = dot(v_opos.xz, tangent);
	float fws = fwidth(s_face);
	float is_wide = 1.0 - step(0.5, mod(face, 2.0));
	float panel = joint_s > 0.0 ? is_wide * (step(joint_s, s_face) - step(s_face, -joint_s)) : 0.0;
	float groove = joint_s > 0.0 ? is_wide * wall * (1.0 - smoothstep(joint_width * 0.5, joint_width * 0.5 + fws + 0.0005, abs(abs(s_face) - joint_s))) : 0.0;
	float de = mix(face_half_minor, face_half_major, is_wide) - abs(s_face);
	float roll = edge_roll > 0.0 ? (1.0 - smoothstep(0.0, edge_roll, de)) * wall : 0.0;
	float touch = touch_strength * (1.0 - smoothstep(0.4, 1.0, length((v_opos.xy - touch_center.xy) / (touch_radius * vec2(0.6, 1.4)))));
	float h = hash12(vec2(face + panel * 0.37, course) + 17.0);
	float h2 = hash12(vec2(course, face + panel * 0.37) + 5.0);
	float plate = 1.0 + plate_variation * (h * 2.0 - 1.0) * wall;
	float dy = min(min(abs(y - seams.x), abs(y - seams.y)), min(abs(y - seams.z), abs(y - seams.w)));
	float contact = seam_shadow * exp(-dy / 0.05) * wall;
	float seam_above = y < seams.y ? seams.y : (y < seams.z ? seams.z : seams.w);
	float streak = texture(grime, vec2(dot(v_opos.xz, tangent) * 1.3, y * 0.12)).g;
	float run = run_strength * wall * exp(-max(seam_above - y, 0.0) / run_length) * smoothstep(0.35, 0.75, streak);
	float dust = dust_strength * wall * (1.0 - smoothstep(0.14, 0.14 + dust_height, y)) * (0.6 + 0.4 * stains);
	dust *= 1.0 - touch;

	vec2 buv = UV * brush_scale;
	float rough = texture(metal_rough, buv).g * roughness_scale;
	rough *= mix(1.0, mix(0.82, 1.25, stains), stain_strength) * mix(1.0, mix(0.92, 1.08, streaks), streak_strength) * mix(1.0, mix(0.85, 1.15, h2), wall);
	rough = mix(rough, 0.75, run * 0.8);
	rough = mix(rough, 0.85, dust);
	rough = mix(rough, 0.7, groove) * mix(1.0, 0.8, roll) * mix(1.0, 0.6, touch);
	vec3 albedo = base_color * mix(1.0, mix(0.86, 1.04, stains), stain_strength) * mix(1.0, mix(0.95, 1.04, streaks), streak_strength) * plate;
	albedo *= (1.0 - contact) * (1.0 - 0.6 * run);
	albedo *= (1.0 + plate_hue * (h2 * 2.0 - 1.0) * wall * vec3(1.0, 0.0, -1.0)) * (1.0 - 0.6 * groove);
	albedo = mix(albedo, base_color * 1.05, 0.6 * touch);
	ALBEDO = mix(albedo * tint, dust_color, dust);
	METALLIC = metallic * (1.0 - 0.7 * dust);
	ROUGHNESS = clamp(rough, 0.06, 0.9);
	// Oil-canning: a smooth height over the plate, about 0.9 m across, tilts the normal.
	vec2 fp = vec2(dot(v_opos.xz, tangent), y) / 0.9 + vec2(face * 7.3, course * 3.1);
	float e = 0.08;
	float c0 = vnoise(fp);
	vec2 tilt = vec2(vnoise(fp + vec2(e, 0.0)) - c0, vnoise(fp + vec2(0.0, e)) - c0) / e * oil_can * wall;
	if (edge_roll > 0.0) {
		vec3 out_dir = vec3(tangent.x, 0.0, tangent.y) * sign(s_face);
		NORMAL = normalize(NORMAL + (mat3(VIEW_MATRIX) * mat3(MODEL_MATRIX) * out_dir) * tan(radians(40.0) * roll));
	}
	vec3 nm = texture(normal_map, buv).rgb;
	NORMAL_MAP = vec3(clamp(nm.xy + 0.5 * tilt, 0.0, 1.0), nm.z);
	NORMAL_MAP_DEPTH = normal_depth;
	ANISOTROPY = anisotropy_amount;
	ANISOTROPY_FLOW = brush_flow;
}
