shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Bindings for the observatory's shelf books, one MultiMesh instance per book
// (_book_mesh and _fill_board in scripts/observatory.gd).
//   COLOR            binding colour (sRGB) in rgb, a per-book seed in a
//   INSTANCE_CUSTOM  style (leather < 0.5 <= cloth < 0.9 <= vellum), raised bands / 8, gilt, wear;
//                    a course book (scripts/course_library.gd) adds 1 to its style: a Label3D
//                    carries its real title, so the decorative lettering is left out
//   UV.x             part: 0 boards, 1 spine, 2 page block
// The unit mesh is scaled per instance, so the lengths below are metres recovered from MODEL_MATRIX.

uniform vec3 gilt_color : source_color = vec3(0.83, 0.64, 0.3);
uniform vec3 paper_color : source_color = vec3(0.66, 0.6, 0.48);
// R: leather grain, G: book-cloth weave. Tileable ComfyUI outputs, see artpass/books/comfyui/.
uniform sampler2D grain_map : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float grain_tile = 0.08; // metres covered by one tile of grain_map
uniform float grain_strength : hint_range(0.0, 1.0) = 0.6;
// Warm light the shelf strips bounce onto the books, added as emission. Forward+ gets it from SDFGI
// and SSIL and leaves this at zero; the Compatibility renderer (the web build) has neither
// (_make_materials in scripts/observatory.gd).
uniform vec3 bounce_fill = vec3(0.0);

varying flat vec3 v_color;
varying flat vec4 v_style;
varying flat float v_seed;
varying flat float v_part;
varying flat vec3 v_size;
varying vec3 v_lpos;
varying vec3 v_lnorm;
varying vec3 v_wnorm;

float hash12(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), f.x),
		mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}

// One line of lettering. q.x runs along the line from its start, q.y across it from its centre,
// both in metres. Each character is a few strokes (stems, bars, a bowl) picked by hash, which
// reads as capitals at shelf distance without a font. Returns ink coverage.
float lettering(vec2 q, vec2 cell, float count, float seed) {
	float ci = floor(q.x / cell.x);
	vec2 f = vec2(q.x / cell.x - ci, q.y / cell.y + 0.5);
	float inside = step(0.0, ci) * step(ci, count - 1.0) * step(0.0, f.y) * step(f.y, 1.0);
	float space = step(hash12(vec2(ci, seed * 7.0)), 0.13);
	vec2 g = (f - vec2(0.2, 0.12)) / vec2(0.6, 0.76);
	float box = step(0.0, g.x) * step(g.x, 1.0) * step(0.0, g.y) * step(g.y, 1.0);
	float sw = 0.17;
	float h0 = hash13(vec3(ci, seed, 1.0));
	float h1 = hash13(vec3(ci, seed, 2.0));
	float h2 = hash13(vec3(ci, seed, 3.0));
	float h3 = hash13(vec3(ci, seed, 4.0));
	float stem_l = step(g.x, sw) * step(0.25, h0);
	float stem_r = step(1.0 - sw, g.x) * step(0.55, h1);
	float stem_c = step(abs(g.x - 0.5), sw * 0.5) * step(0.8, h1);
	float bar_t = step(g.y, sw * 0.8) * step(0.45, h2);
	float bar_m = step(abs(g.y - 0.5), sw * 0.4) * step(0.5, h3);
	float bar_b = step(1.0 - sw * 0.8, g.y) * step(0.35, fract(h2 * 7.0));
	float ink = max(max(stem_l, stem_r), max(stem_c, max(bar_t, max(bar_m, bar_b))));
	return inside * box * ink * (1.0 - space);
}

// Thin rule of the given half width around distance d = 0, anti-aliased by the pixel footprint.
float rule(float d, float half_w, float fw) {
	return 1.0 - smoothstep(half_w, half_w + max(fw, 0.0002), abs(d));
}

void vertex() {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// Compatibility shades in sRGB space and writes the result out unconverted, as it does for
	// source_color: linearising here would crush dark bindings to black.
	v_color = COLOR.rgb;
#else
	v_color = pow(COLOR.rgb, vec3(2.2));
#endif
	v_seed = COLOR.a;
	v_style = INSTANCE_CUSTOM;
	v_part = UV.x;
	v_size = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	v_lpos = VERTEX * v_size;
	v_lnorm = NORMAL;
	// Inverse transpose of the per-instance non-uniform scale, done here so the rounded spine
	// shades round whatever the engine does with a scaled MultiMesh instance's normals.
	v_wnorm = mat3(MODEL_MATRIX) * (NORMAL / (v_size * v_size));
}

void fragment() {
	float part = floor(v_part + 0.5);
	float real_title = step(1.0, v_style.x);
	float style = v_style.x - real_title;
	float gilt_amt = v_style.z;
	float wear = v_style.w;
	float w = v_size.x;
	float h = v_size.y;
	vec3 p = v_lpos;
	vec3 an = abs(v_lnorm);
	float is_leather = 1.0 - step(0.5, style);
	float is_vellum = step(0.9, style);
	float is_cloth = (1.0 - is_leather) * (1.0 - is_vellum);

	// Everything that needs derivatives runs here, in uniform control flow.
	vec3 fw3 = fwidth(p);
	float fw = max(fw3.x, max(fw3.y, fw3.z));         // metres per pixel
	float detail = 1.0 - smoothstep(0.0012, 0.004, fw); // lettering and rules fade to their average
	float relief_lod = 1.0 - smoothstep(0.003, 0.012, fw);
	vec2 plane = an.x > max(an.y, an.z) ? p.zy : (an.y > an.z ? p.xz : p.xy);
	vec4 grain_s = texture(grain_map, plane / grain_tile + vec2(v_seed * 17.0, v_seed * 29.0));
	float g = mix(grain_s.r, grain_s.g, is_cloth);

	vec3 albedo = v_color * mix(1.0, 0.72 + 0.56 * g, grain_strength * (1.0 - 0.7 * is_vellum));
	float rough = mix(mix(0.52, 0.86, is_cloth), 0.6, is_vellum);
	float height = (g - 0.5) * mix(0.00035, 0.0002, is_cloth) * grain_strength * relief_lod;
	float gilt = 0.0;
	float ink = 0.0;
	vec3 ink_color = vec3(0.02, 0.015, 0.012);

	if (part > 1.5) {
		// Page block: cream paper, yellowed with age, sheets stacked across the width.
		vec3 paper = paper_color * mix(vec3(1.0), vec3(0.9, 0.8, 0.6), wear);
		float sheets = vnoise(vec2(p.x * 2600.0, v_seed * 91.0));
		float sheet_detail = 1.0 - smoothstep(0.0002, 0.0008, fw);
		albedo = paper * (1.0 - 0.2 * mix(0.5, sheets, sheet_detail));
		albedo *= 0.8 + 0.2 * smoothstep(0.0, 0.004, 0.5 * w - abs(p.x) - 0.1 * w);
		rough = 0.9;
		height = 0.0;
		// Gilt edges on the finest leather bindings.
		gilt = step(0.85, gilt_amt) * is_leather * 0.85;
	} else if (part > 0.5) {
		// Spine. a runs across it (-0.5..0.5), t from the head, tb from the tail, in metres.
		float a = p.x / w;
		float t = 0.5 * h - p.y;
		float tb = h - t;
		float ends = min(t, tb);
		float joint = smoothstep(0.34, 0.5, abs(a));
		float rub = wear * max(joint, 1.0 - smoothstep(0.004, 0.02, ends))
			* (0.45 + 0.55 * vnoise(vec2(a * 7.0, t * 70.0) + v_seed * 50.0));
		if (is_leather > 0.5) {
			// Raised bands over the sewing cords, gold rules either side of them and at head
			// and tail, a lettering piece in the second compartment, a small tool in the others.
			float nb = floor(v_style.y * 8.0 + 0.5);
			float t0 = h * 0.07;
			float comp = h * 0.86 / (nb + 1.0);
			float k = clamp(floor((t - t0) / comp + 0.5), 1.0, nb);
			float db = t - (t0 + k * comp);
			float band = 1.0 - smoothstep(0.0018, 0.0042, abs(db));
			height += band * 0.0018 * relief_lod;
			albedo *= 1.0 + 0.35 * band * (0.4 + wear);
			float tooled = step(0.3, gilt_amt);
			gilt += tooled * detail * max(rule(abs(db) - 0.008, 0.0004, fw), rule(ends - 0.011, 0.0004, fw));
			gilt += tooled * (1.0 - detail) * 0.12 * step(abs(abs(db) - 0.008), 0.004);
			float c = floor((t - t0) / comp);
			float ct = t - t0 - c * comp - 0.5 * comp; // from the compartment's centre
			float label_h = comp - 0.024;
			float in_label = step(abs(ct), 0.5 * label_h) * step(abs(a), 0.44) * step(0.5, c) * step(c, 1.5)
				* step(2.5, nb);
			float lab = fract(style * 10.0);
			vec3 label_col = lab < 0.45 ? vec3(0.018, 0.014, 0.012) : (lab < 0.8 ? vec3(0.2, 0.025, 0.018) : vec3(0.025, 0.07, 0.035));
			albedo = mix(albedo, label_col * (0.8 + 0.4 * g), in_label);
			height -= in_label * 0.0003 * relief_lod;
			rough = mix(rough, 0.42, in_label);
			vec2 cell = vec2(0.0034, 0.0048);
			float count = floor(w * mix(0.55, 0.8, fract(v_seed * 5.3)) / cell.x);
			float line_gap = min(label_h * 0.28, 0.0065);
			float text = 0.0;
			text += lettering(vec2(p.x + 0.5 * count * cell.x, ct + line_gap), cell, count, v_seed * 97.0);
			text += lettering(vec2(p.x + 0.5 * (count - 2.0) * cell.x, ct - line_gap), cell, count - 2.0, v_seed * 57.0 + 3.0);
			gilt += in_label * mix(0.22, min(text, 1.0), detail);
			// Centre tool in the other compartments: a small lozenge.
			float lz = abs(p.x) / 0.0045 + abs(ct) / 0.006; // outlined lozenge with a centre dot
			float tool = step(lz, 1.0) * max(step(lz, 0.35), step(0.75, lz));
			float other = (1.0 - in_label) * step(0.0, c) * step(c, nb) * step(abs(ct), 0.5 * comp - 0.012);
			gilt += other * step(0.55, gilt_amt) * mix(0.05 * step(lz, 1.0), tool, detail);
			// Rubbed joints, head and tail show the lighter leather under the finish.
			albedo = mix(albedo, albedo * 1.8 + vec3(0.03, 0.02, 0.01), rub);
		} else if (is_cloth > 0.5) {
			// Publisher's cloth: stamped rules at head and tail, the title running up the spine.
			float marks = max(rule(ends - 0.012, 0.0005, fw), rule(ends - 0.016, 0.0005, fw));
			vec2 cell = vec2(0.0058, 0.0074) * clamp(w / 0.035, 0.6, 1.0);
			float count = floor(h * mix(0.22, 0.45, fract(v_seed * 13.7)) / cell.x);
			float title = lettering(vec2(tb - h * 0.25, p.x), cell, count, v_seed * 131.0);
			float author = lettering(vec2(tb - h * 0.08, p.x), cell * 0.7, floor(count * 0.35), v_seed * 71.0 + 5.0);
			marks = max(marks, max(title, author) * (1.0 - real_title));
			float avg = step(abs(p.x), 0.5 * cell.y) * 0.3 * step(h * 0.25, tb) * step(tb, h * 0.25 + count * cell.x) * (1.0 - real_title);
			marks = mix(avg, marks, detail);
			float gilded = step(0.45, gilt_amt);
			gilt += gilded * marks;
			float lum = dot(v_color, vec3(0.3, 0.59, 0.11));
			ink = (1.0 - gilded) * marks;
			ink_color = lum < 0.05 ? vec3(0.55, 0.5, 0.42) : vec3(0.012, 0.01, 0.01);
			// Sun-faded spine, frayed at head and tail.
			albedo = mix(albedo, vec3(lum) * 1.25 + 0.015, wear * 0.45);
			albedo = mix(albedo, albedo * 1.5 + vec3(0.03), rub * 0.8);
		} else {
			// Limp vellum: a hand-written title in iron-gall ink.
			vec2 cell = vec2(0.0062, 0.007) * clamp(w / 0.035, 0.6, 1.0);
			float count = floor(h * mix(0.18, 0.35, fract(v_seed * 13.7)) / cell.x);
			float title = lettering(vec2(tb - h * 0.45, p.x + 0.0008 * sin(t * 300.0)), cell, count, v_seed * 43.0);
			float avg = step(abs(p.x), 0.5 * cell.y) * 0.25 * step(h * 0.45, tb) * step(tb, h * 0.45 + count * cell.x);
			ink = mix(avg, title, detail) * 0.85;
			ink_color = vec3(0.12, 0.07, 0.04);
			albedo *= 0.92 + 0.12 * vnoise(p.xy * 60.0 + v_seed * 20.0);
			albedo = mix(albedo, albedo * vec3(0.82, 0.72, 0.55), rub);
		}
		gilt *= 1.0 - 0.7 * rub;
	} else {
		// Boards: the same binding, darker than the sun-faded spine; worn at the edges.
		albedo *= 0.75;
		float edge = an.y > max(an.x, an.z) ? 1.0 : 0.0;
		albedo = mix(albedo, albedo * 1.6 + vec3(0.02), edge * wear * 0.6);
	}

	albedo = mix(albedo, ink_color, clamp(ink, 0.0, 1.0));
	rough = mix(rough, 0.7, clamp(ink, 0.0, 1.0));
	gilt = clamp(gilt, 0.0, 1.0);
	albedo = mix(albedo, gilt_color * (0.8 + 0.4 * g), gilt);
	rough = mix(rough, 0.3, gilt);
	float metal = gilt;
	height -= gilt * 0.00012 * relief_lod; // tooling is pressed into the leather

	// Bump from the height field (Mikkelsen 2010, surface gradient from screen-space derivatives),
	// on top of the normal rebuilt from v_wnorm. The tilt is clamped so edges between instances
	// do not sparkle.
	vec3 n = normalize((VIEW_MATRIX * vec4(v_wnorm, 0.0)).xyz);
	vec3 dpdx = dFdx(VERTEX);
	vec3 dpdy = dFdy(VERTEX);
	float dhx = dFdx(height);
	float dhy = dFdy(height);
	vec3 r1 = cross(dpdy, n);
	vec3 r2 = cross(n, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dhx * r1 + dhy * r2) / max(abs(det), 1e-12);
	float gl = length(grad);
	grad *= min(gl, 1.2) / max(gl, 1e-6);
	NORMAL = normalize(n - grad);
	ALBEDO = albedo;
	ROUGHNESS = rough;
	METALLIC = metal;
	SPECULAR = 0.5;
	EMISSION = albedo * bounce_fill * (1.0 - metal);
}
