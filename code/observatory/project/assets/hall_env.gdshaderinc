// The hall as a reflecting surround, traced analytically for materials that need something to
// reflect under Compatibility (no SSR, no SDFGI): the reflected ray is intersected with the ring
// of shelves, the floor and the ceiling, so the lamp strips, the books, the gallery slabs and the
// oculus land where they are, with parallax. observatory.gd's _hall_params() sets the dimensions.
// Used by gilt.gdshader, radiant_crystal.gdshader and gem.gdshader.

// The hall, from observatory.gd.
uniform float wall_radius = 17.14;     // front of the shelves
uniform float wall_top = 18.1;
uniform float ceiling_y = 20.5;
uniform float oculus_radius = 10.0;
uniform vec3 level_y = vec3(0.0, 6.2, 12.6);
uniform float strip_pitch = 1.244;     // lamp strips on every other shelf row
uniform float bay_count = 16.0;
uniform float unit_frac = 0.955;       // share of a bay filled by the shelf unit
// What the hall looks like to the leaf.
uniform vec3 strip_color : source_color = vec3(1.0, 0.86, 0.66);
uniform float strip_energy = 9.0;
uniform float halo_energy = 0.4;       // the books and board lit just around each strip
uniform vec3 books_color : source_color = vec3(0.4, 0.32, 0.25);
uniform vec3 slab_color : source_color = vec3(0.08, 0.08, 0.09);
uniform vec3 floor_color : source_color = vec3(0.16, 0.16, 0.17);
uniform vec3 vault_color : source_color = vec3(0.06, 0.07, 0.09);
uniform vec3 sky_color : source_color = vec3(0.1, 0.15, 0.3);

varying vec3 v_wpos;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float hash11(float x) {
	return fract(sin(x * 127.1) * 43758.5453);
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash13(i), hash13(i + vec3(1, 0, 0)), f.x),
			mix(hash13(i + vec3(0, 1, 0)), hash13(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash13(i + vec3(0, 0, 1)), hash13(i + vec3(1, 0, 1)), f.x),
			mix(hash13(i + vec3(0, 1, 1)), hash13(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

// The hall seen along ray o + t d. blur widens with the leaf's roughness and the distance; pix is
// how much the ray turns across one pixel (length(fwidth(d)) in the caller), so a reflection is
// never sharper than the pixel can show: without it, the lamp strips reflected in thin gilt
// mouldings broke into crawling dots (artpass/aa/NOTES.md).
vec3 hall(vec3 o, vec3 d, float rough, float pix) {
	vec2 oxz = o.xz;
	vec2 dxz = d.xz;
	float a = max(dot(dxz, dxz), 1e-5);
	float b = dot(oxz, dxz);
	float c = dot(oxz, oxz) - wall_radius * wall_radius;
	float t_wall = (-b + sqrt(max(b * b - a * c, 0.0))) / a;
	float t_floor = d.y < -1e-4 ? -o.y / d.y : 1e9;
	float t_ceil = d.y > 1e-4 ? (ceiling_y - o.y) / d.y : 1e9;
	float blur = 0.012 + rough * rough * 0.9;
	if (t_floor < t_wall) {
		vec3 p = o + d * t_floor;
		// The polished floor itself mirrors the lamp band near the wall.
		float near_wall = smoothstep(wall_radius - 4.0, wall_radius, length(p.xz));
		return floor_color + books_color * near_wall * 0.5;
	}
	vec3 p = o + d * t_wall;
	if (p.y > wall_top) {
		vec3 q = o + d * min(t_ceil, 1e4);
		float in_oculus = 1.0 - smoothstep(oculus_radius - 0.3, oculus_radius + 0.3, length(q.xz));
		return mix(vault_color, sky_color, in_oculus);
	}
	float w = max(blur, pix) * t_wall; // footprint of the lobe on the wall, in metres
	// Which level: the bottom below p.y.
	float y0 = p.y >= level_y.z ? level_y.z : (p.y >= level_y.y ? level_y.y : level_y.x);
	float top = p.y >= level_y.z ? wall_top : (p.y >= level_y.y ? level_y.z - 0.6 : level_y.y - 0.6);
	if (p.y > top) {
		return slab_color;               // the gallery slab and its balustrade
	}
	float phi = atan(p.z, p.x) / 6.2831853 * bay_count;
	float u = fract(phi);
	float bay = floor(phi);
	float in_unit = 1.0 - smoothstep(unit_frac * 0.5 - w * 0.2, unit_frac * 0.5 + w * 0.2, abs(u - 0.5));
	// Lamp strips: 2 cm bright lines; blurred, the same light spread over the footprint.
	float s = fract((p.y - y0 + 0.06) / strip_pitch);
	float dist = min(s, 1.0 - s) * strip_pitch;
	float sw = max(0.02, w);
	float strip = (1.0 - smoothstep(0.0, sw, dist)) * (0.02 / sw);
	float halo = exp(-dist / max(0.12, w)) * (0.12 / max(0.12, w));
	// Books: rows of spines, warm in the lamp light, varying per bay and per row.
	float row = floor((p.y - y0) / (strip_pitch * 0.5));
	vec3 books = books_color * (0.6 + 0.8 * hash11(bay * 7.0 + row + y0));
	books = mix(books, books_color * 1.0, clamp(w * 2.0, 0.0, 1.0));
	vec3 col = mix(slab_color, books + strip_color * (strip * strip_energy + halo * halo_energy), in_unit);
	return col;
}
