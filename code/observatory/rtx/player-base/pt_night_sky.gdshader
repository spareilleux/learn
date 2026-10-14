shader_type sky;

// Trantor's night sky for the fork's path tracer (artpass/dlss/pt_sky.gd): assets/night_sky.gdshader
// as a sky shader. The rasterizer draws that one on a dome round the camera, which the rays would meet as
// a 1 m ball, so it is hidden while path tracing (dlss_play.gd); a ray that leaves the scene reads the
// Environment's sky instead, its radiance map. Same uniforms, copied from the dome's material by
// pt_sky.gd; the body is night_sky.gdshader's fragment() with EYEDIR for the direction. No screen
// derivatives here: a pixel's angle is the radiance map's texel (px_cube), or the screen's (px_screen)
// when the sky is drawn as the background.

uniform vec3 core_dir = vec3(-0.468, 0.867, -0.170);
uniform vec3 galaxy_normal = vec3(-0.34, 0.2, 0.94);
uniform float core_zoom = 5.0;
uniform float glow_energy = 1.0;
uniform float band_energy = 0.34;
uniform float star_energy = 1.0;
uniform sampler2D milky_way : source_color, filter_linear_mipmap, repeat_enable;
uniform float photo_energy = 0.0;
uniform float photo_width = 4096.0;
uniform sampler2D core_cap : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform float cap_energy = 0.0;
uniform float cap_radius = 1.4;
uniform float cap_fade = 0.35;
uniform float cap_width = 2048.0;
uniform vec3 city_glow = vec3(0.03, 0.085, 0.16);
uniform float city_energy = 1.0;
uniform float glow_height = 0.12;
uniform float cloud_energy = 1.0;
uniform float px_cube = 0.0017;
uniform float px_screen = 0.001;

vec3 hash33(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yxx) * p.zyx);
}

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash13(i), hash13(i + vec3(1, 0, 0)), f.x), mix(hash13(i + vec3(0, 1, 0)), hash13(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash13(i + vec3(0, 0, 1)), hash13(i + vec3(1, 0, 1)), f.x), mix(hash13(i + vec3(0, 1, 1)), hash13(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float a = 0.5;
	float s = 0.0;
	for (int k = 0; k < 5; k++) {
		s += a * noise(p);
		p = p * 2.03 + vec3(1.7, 9.2, 4.1);
		a *= 0.5;
	}
	return s;
}

vec3 star_colour(float t) {
	vec3 c = mix(vec3(0.7, 0.8, 1.0), vec3(1.0), smoothstep(0.0, 0.35, t));
	c = mix(c, vec3(1.0, 0.9, 0.72), smoothstep(0.6, 0.85, t));
	return mix(c, vec3(1.0, 0.68, 0.45), smoothstep(0.9, 1.0, t));
}

vec3 stars(vec3 d, float scale, float density, float bright, float px) {
	vec3 cell = floor(d * scale);
	vec3 h = hash33(cell);
	if (h.x > density) {
		return vec3(0.0);
	}
	vec3 s = normalize(cell + 0.25 + 0.5 * hash33(cell + 17.0));
	if (any(notEqual(floor(s * scale), cell))) {
		return vec3(0.0);
	}
	float r = length(d - s);
	float sigma = max(px * 0.75, 1e-5);
	float flux = bright * (0.08 + 6.0 * pow(h.y, 14.0));
	float peak = flux * px * px / (6.2832 * sigma * sigma);
	return star_colour(h.z) * peak * exp(-r * r / (2.0 * sigma * sigma));
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float px = AT_CUBEMAP_PASS ? px_cube : px_screen;
	float up = clamp(d.y, -1.0, 1.0);

	vec3 core = normalize(core_dir);
	vec3 n = normalize(galaxy_normal - dot(galaxy_normal, core) * core);
	vec3 e = cross(n, core);

	float c = clamp(dot(d, core), -1.0, 1.0);
	float th = acos(c);
	float t = tan(th * 0.5);
	float th_src = 2.0 * atan(t / core_zoom);
	vec3 perp = d - core * c;
	float pl = length(perp);
	vec3 ds = pl > 1e-6 ? core * cos(th_src) + perp / pl * sin(th_src) : core;
	float px_src = px * (1.0 + t * t) / (core_zoom * (1.0 + t * t / (core_zoom * core_zoom)));

	vec3 col = mix(vec3(0.014, 0.018, 0.034), vec3(0.006, 0.009, 0.02), smoothstep(0.0, 0.5, up));
	col += vec3(1.0, 0.84, 0.62) * (exp(-th * 4.0) * 0.05 + exp(-th * 1.4) * 0.018) * glow_energy;

	float g = dot(ds, n);
	float band = exp(-g * g / (2.0 * 0.13 * 0.13));
	float bulge = exp(-(1.0 - dot(ds, core)) * 7.0);
	vec3 galaxy = vec3(0.0);
	if (photo_energy > 0.0) {
		float l = atan(dot(ds, e), dot(ds, core));
		float b = asin(clamp(g, -1.0, 1.0));
		vec2 uv = vec2(0.5 - l / 6.2832, 0.5 - b / 3.1416);
		float lod = log2(max(px_src * photo_width / 6.2832, 1.0));
		galaxy = textureLod(milky_way, uv, lod).rgb * photo_energy;
	} else {
		float cloud = fbm(ds * 5.0);
		float lane = exp(-g * g / (2.0 * 0.028 * 0.028)) * smoothstep(0.35, 0.75, fbm(ds * 11.0 + 3.0));
		float milk = (band * (0.35 + 0.9 * cloud) + bulge * (0.6 + 0.8 * cloud)) * (1.0 - 0.75 * lane);
		vec3 milk_colour = mix(vec3(0.62, 0.7, 0.9), vec3(1.0, 0.85, 0.66), clamp(bulge * 1.5, 0.0, 1.0));
		galaxy = milk_colour * milk * band_energy;
	}
	if (cap_energy > 0.0 && th < cap_radius) {
		float r = th / cap_radius;
		vec2 across = pl > 1e-6 ? vec2(dot(perp, e), dot(perp, n)) / pl : vec2(0.0);
		vec2 cuv = vec2(0.5) + vec2(across.x, -across.y) * r * 0.5;
		float clod = log2(max(px * cap_width / (2.0 * cap_radius), 1.0));
		vec3 cap = textureLod(core_cap, cuv, clod).rgb * cap_energy;
		galaxy = mix(galaxy, cap, 1.0 - smoothstep(1.0 - cap_fade, 1.0, r));
	}
	col += galaxy;

	float dens = 1.0 + 3.0 * band + 8.0 * bulge;
	vec3 st = stars(d, 70.0, 0.02 * dens, 4.0, px) + stars(d, 180.0, 0.012 * dens, 1.2, px);
	if (photo_energy <= 0.0) {
		st += stars(d, 260.0, 0.045 * dens, 1.0, px);
	}
	float h = max(up, 0.0);
	float district = 0.6 + 0.8 * fbm(vec3(d.x, 0.0, d.z) * 2.3 + 7.0);
	float glow = (exp(-h / glow_height) * 0.9 + exp(-h / (glow_height * 5.0)) * 0.3) * district * city_energy;
	float wisp = smoothstep(0.5, 0.78, fbm(vec3(d.x * 3.0, d.y * 16.0, d.z * 3.0) + 11.0));
	float cloud = wisp * exp(-h / 0.16) * cloud_energy;
	float extinction = clamp(glow * 0.9 + cloud * 0.8, 0.0, 0.95);
	col += st * star_energy * smoothstep(-0.02, 0.06, up) * (1.0 - extinction);
	col = col * (1.0 - cloud * 0.5) + city_glow * glow + city_glow * vec3(1.3, 1.1, 1.0) * cloud * (0.35 + 0.65 * exp(-h / 0.05)) * 0.8 * district;

	col = mix(vec3(0.006, 0.007, 0.012) + city_glow * 0.25 * city_energy, col, smoothstep(-0.08, 0.01, up));
	COLOR = col;
}
