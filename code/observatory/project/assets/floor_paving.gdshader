shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Polished marble paving for the hall floor (scripts/observatory.gd, _build_floor): rings of
// slabs laid between the brass inlays, the rings alternating a pale and a dark marble, and a
// compass rose whose eight points reach out from under the steel box, each point half pale and
// half dark inside a gilt outline. Everything is procedural in the floor's own xz plane, so the
// disc needs no UVs. Colour comes from the art pass's ComfyUI marble.

uniform sampler2D marble : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float marble_tile = 3.5;
uniform float marble_mean = 0.25;  // the texture's mean: tints below are the slabs' mean albedo
uniform vec3 pale : source_color = vec3(0.55, 0.58, 0.65);
uniform vec3 dark : source_color = vec3(0.1, 0.11, 0.14);
uniform float roughness = 0.22;
uniform float slab = 1.2;             // target slab length along a ring, metres
uniform float ring_bounds[24];        // ring joints, metres from the centre, ascending
uniform int ring_count = 0;
uniform float joint_width = 0.0035;
uniform vec3 gilt : source_color = vec3(0.85, 0.65, 0.32);
uniform float gilt_emission = 0.6;
uniform float rose_major = 5.6;       // tip radius of the four cardinal points
uniform float rose_minor = 4.3;       // tip radius of the four intercardinal points
uniform float rose_base_major = 1.25; // half width of a cardinal point at the centre, metres
uniform float rose_base_minor = 0.9;
uniform float line_width = 0.014;
uniform vec3 rose_pale : source_color = vec3(0.85, 0.84, 0.8);
uniform vec3 rose_dark : source_color = vec3(0.05, 0.055, 0.07);

// Contact shadows, painted in: the web build's renderer has no ambient occlusion, and nothing
// else darkens the floor where the box, the pier plinths, the statue's pedestal and the ground
// shelves stand on it. Distances are in the floor's xz plane; 0 strength turns them off.
uniform float contact_strength = 0.0;
uniform float contact_width = 0.7;           // metres over which a contact shadow fades out
uniform vec2 box_half = vec2(2.0, 2.0);      // the steel box's footprint, centred on the hall
uniform float box_chamfer = 0.45;            // its corners, cut at 45 degrees
uniform int pier_count = 16;                 // plinths at angles TAU * i / pier_count
uniform float pier_radius = 13.0;
uniform vec2 pier_half = vec2(0.75, 0.9);    // plinth half size along the ring and the radius
uniform vec3 pedestal = vec3(0.0, 0.0, -1.0);  // centre x, z and half size; negative: none
uniform float pedestal_angle = 0.0;          // its rotation about the vertical, radians
uniform float shelf_radius = 1e3;            // front of the ground-level shelves

varying vec3 v_opos;

float hash12(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

// One point of the rose on the axis at angle phi: x = signed side (-1 or 1) where inside, and
// y = distance to the point's edge in metres (negative outside).
vec2 rose_point(float ang, float rad, float phi, float tip, float base) {
	float d = ang - phi;
	d = d - TAU * floor(d / TAU + 0.5);
	float u = rad * cos(d);
	float v = rad * sin(d);
	float half_w = base * (1.0 - u / tip);
	float edge = (half_w - abs(v)) * tip / sqrt(tip * tip + base * base);
	edge = min(edge, u < 0.0 ? -1.0 : edge);
	return vec2(v < 0.0 ? -1.0 : 1.0, edge);
}

float sd_box(vec2 q, vec2 b) {
	vec2 d = abs(q) - b;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// 1 at the edge of an object, fading to 0 at contact_width from it.
float contact(float d) {
	float t = clamp(d / contact_width, 0.0, 1.0);
	return (1.0 - t) * (1.0 - t);
}

float contact_shadow(vec2 p, float rad, float ang) {
	vec2 q = abs(p);
	float d_box = max(sd_box(p, box_half), (q.x + q.y - (box_half.x + box_half.y - box_chamfer)) * 0.70710678);
	float step_a = TAU / float(pier_count);
	float phi = step_a * floor(ang / step_a + 0.5);
	float da = ang - phi;
	float d_pier = sd_box(vec2(rad * sin(da), rad * cos(da) - pier_radius), pier_half);
	float occ = max(contact(d_box), contact(d_pier));
	if (pedestal.z > 0.0) {
		vec2 r = p - pedestal.xy;
		float c = cos(pedestal_angle);
		float s = sin(pedestal_angle);
		occ = max(occ, contact(sd_box(vec2(c * r.x + s * r.y, -s * r.x + c * r.y), vec2(pedestal.z))));
	}
	return max(occ, contact(shelf_radius - rad));
}

void vertex() {
	v_opos = VERTEX;
}

void fragment() {
	vec2 p = v_opos.xz;
	float rad = length(p);
	float ang = atan(p.y, p.x);
	float fw = fwidth(rad);
	vec3 base = texture(marble, p / marble_tile).rgb / marble_mean;

	// Ring and slab of this pixel.
	float r0 = 0.0;
	float r1 = ring_bounds[0];
	int ring = 0;
	for (int i = 0; i < 24; i++) {
		if (i >= ring_count - 1 || rad < ring_bounds[i]) {
			break;
		}
		r0 = ring_bounds[i];
		r1 = ring_bounds[i + 1];
		ring = i + 1;
	}
	float mid = 0.5 * (r0 + r1);
	float n = 16.0 * max(1.0, floor(TAU * mid / slab / 16.0 + 0.5));
	float s = ang / TAU * n + 0.5 * float(ring % 2);
	float sid = floor(s);
	float fs = s - sid;
	float d_head = min(fs, 1.0 - fs) * TAU * max(rad, 0.01) / n;
	float d_bed = min(rad - r0, r1 - rad);
	float dj = ring == 0 ? 1e3 : min(d_head, d_bed);
	float joint = 1.0 - smoothstep(joint_width - fw, joint_width + fw, dj);
	joint *= 1.0 - smoothstep(0.004, 0.02, fw);

	float v = hash12(vec2(float(ring), sid) + 3.7);
	vec3 col = base * (ring % 2 == 0 ? pale : dark) * (0.9 + 0.2 * v);

	// Compass rose: intercardinal points first, cardinal points over them.
	float gold = 0.0;
	for (int j = 0; j < 8; j++) {
		int k = j < 4 ? 2 * j + 1 : 2 * (j - 4);
		bool major = j >= 4;
		vec2 pt = rose_point(ang, rad, float(k) * TAU / 8.0, major ? rose_major : rose_minor,
			major ? rose_base_major : rose_base_minor);
		if (pt.y > -fw) {
			float inside = smoothstep(-fw, fw, pt.y);
			vec3 fill = base * (pt.x > 0.0 ? rose_pale : rose_dark);
			col = mix(col, fill, inside);
			joint *= 1.0 - inside;
			float line = 1.0 - smoothstep(line_width - fw, line_width + fw, abs(pt.y));
			// The spine of the point, where its pale and dark halves meet.
			float spine = inside * (1.0 - smoothstep(line_width * 0.5 - fw, line_width * 0.5 + fw,
				abs(rad * sin(ang - float(k) * TAU / 8.0))));
			gold = max(gold * (1.0 - inside), max(line, spine));
		}
	}

	col *= 1.0 - 0.55 * joint;
	float shade = contact_strength > 0.0 ? 1.0 - contact_strength * contact_shadow(p, rad, ang) : 1.0;
	ALBEDO = mix(col, gilt, gold) * shade;
	METALLIC = gold;
	ROUGHNESS = mix(mix(roughness, 0.6, joint), 0.35, gold);
	EMISSION = gilt * gold * gilt_emission * shade;
}
