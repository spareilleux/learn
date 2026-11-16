shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

// What shows through a door's window and under its leaf in the multiverse corridor
// (scripts/multiverse.gd): each door opens on another world. The world comes from the door's own
// position, so the corridor can slide its doors along as the visitor walks and every door keeps
// its world: index = floor(z / pitch) on each side. A ray from the eye through the window meets a
// sky and a ground plane some metres behind the door, so the view shifts as one walks past.
//   UV.y > 0.5: the window; below: the strip of light under the leaf.

uniform float pitch = 3.2;        // metres between two doors on the same side
uniform float corridor_z = 0.0;   // the corridor's frame, so the indices do not depend on its placement
uniform float strip_energy = 1.2;

varying vec3 v_wpos;
varying flat float v_world;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

float hash21(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 o = MODEL_MATRIX[3].xyz;
	float side = o.x > 0.0 ? 1.0 : 0.0;
	float k = floor((o.z - corridor_z) / pitch + 0.5);
	v_world = floor(hash11(k * 2.0 + side + 17.0) * 12.0);
}

// Twelve worlds: [sky high, sky low, ground, feature colour]
void palette(float w, out vec3 hi, out vec3 lo, out vec3 gr, out vec3 ft) {
	if (w < 1.0) { hi = vec3(0.55, 0.68, 0.85); lo = vec3(0.92, 0.95, 1.0); gr = vec3(0.9, 0.93, 0.98); ft = vec3(1.0); }            // snowfield
	else if (w < 2.0) { hi = vec3(0.18, 0.03, 0.02); lo = vec3(0.95, 0.35, 0.08); gr = vec3(0.12, 0.08, 0.07); ft = vec3(1.0, 0.55, 0.2); } // ash and embers
	else if (w < 3.0) { hi = vec3(0.1, 0.35, 0.55); lo = vec3(0.6, 0.85, 0.9); gr = vec3(0.05, 0.3, 0.38); ft = vec3(0.85, 1.0, 1.0); }    // ocean
	else if (w < 4.0) { hi = vec3(0.45, 0.6, 0.85); lo = vec3(1.0, 0.85, 0.6); gr = vec3(0.85, 0.62, 0.35); ft = vec3(1.0, 0.95, 0.7); }   // desert
	else if (w < 5.0) { hi = vec3(0.02, 0.01, 0.06); lo = vec3(0.25, 0.05, 0.35); gr = vec3(0.03, 0.02, 0.05); ft = vec3(0.2, 0.9, 1.0); } // night city
	else if (w < 6.0) { hi = vec3(0.3, 0.42, 0.35); lo = vec3(0.7, 0.8, 0.65); gr = vec3(0.08, 0.2, 0.1); ft = vec3(0.02, 0.08, 0.04); }   // forest in mist
	else if (w < 7.0) { hi = vec3(0.0); lo = vec3(0.02, 0.02, 0.05); gr = vec3(0.0); ft = vec3(1.0); }                                    // void and stars
	else if (w < 8.0) { hi = vec3(0.02, 0.06, 0.12); lo = vec3(0.05, 0.3, 0.25); gr = vec3(0.03, 0.05, 0.06); ft = vec3(0.3, 1.0, 0.6); }  // aurora
	else if (w < 9.0) { hi = vec3(0.2, 0.22, 0.28); lo = vec3(0.45, 0.48, 0.55); gr = vec3(0.15, 0.16, 0.18); ft = vec3(0.9, 0.9, 1.0); }  // storm
	else if (w < 10.0) { hi = vec3(0.05, 0.03, 0.08); lo = vec3(0.35, 0.22, 0.12); gr = vec3(0.12, 0.07, 0.04); ft = vec3(1.0, 0.75, 0.4); } // an observatory
	else if (w < 11.0) { hi = vec3(0.6, 0.35, 0.5); lo = vec3(1.0, 0.7, 0.5); gr = vec3(0.35, 0.5, 0.25); ft = vec3(1.0, 0.95, 0.8); }     // garden at dusk
	else { hi = vec3(0.7, 0.85, 0.95); lo = vec3(0.85, 0.95, 1.0); gr = vec3(0.55, 0.75, 0.85); ft = vec3(0.95, 1.0, 1.0); }              // glacier
}

vec3 world(float w, vec3 rd, vec3 ro) {
	vec3 hi, lo, gr, ft;
	palette(w, hi, lo, gr, ft);
	int k = int(w + 0.5);
	float y = rd.y;
	vec3 col = mix(lo, hi, smoothstep(-0.02, 0.5, y));
	float t = TIME;
	if (y < 0.0) {
		// The ground, 1.6 m below the eye, receding into haze.
		float d = 1.6 / max(-y, 0.02);
		vec2 g = ro.xz + rd.xz * d;
		float haze = 1.0 - exp(-d * 0.05);
		vec3 ground = gr;
		if (k == 0 || k == 11) {
			ground *= 0.85 + 0.15 * hash21(floor(g * 2.0));                                  // snow, ice
		} else if (k == 1) {
			ground = mix(gr, ft, 0.35 * (0.5 + 0.5 * sin(g.x * 1.5 + t * 1.2) * sin(g.y * 0.9 - t))); // cinders
		} else if (k == 2) {
			ground *= 0.9 + 0.2 * sin(g.x * 0.7 + g.y * 0.4 - t * 0.8);                       // swell
		} else if (k == 4) {
			float grid = max(step(0.94, fract(g.x * 0.25)), step(0.94, fract(g.y * 0.25)));
			ground = mix(gr, ft, grid * 0.6 * exp(-d * 0.03));                                 // streets
		}
		col = mix(ground, lo, haze);
	} else {
		// Something on the horizon or in the sky.
		vec2 s = rd.xz / max(y + 0.15, 0.05);
		if (k == 0) {
			col = mix(col, ft, step(0.99, hash21(floor(s * 22.0 + vec2(0.0, -t * 1.5)))));       // snow falling
		} else if (k == 1) {
			col += ft * step(0.985, hash21(floor(s * 18.0 + vec2(0.0, t * 2.0)))) * 0.8;         // embers rising
		} else if (k == 3) {
			col = mix(col, ft, smoothstep(0.07, 0.05, length(rd.xy - vec2(-0.1, 0.35))));        // a white sun
		} else if (k == 4) {
			float c = floor(rd.x * 40.0);
			col += ft * step(0.9, hash21(vec2(c, 0.0))) * step(y, 0.15 * hash21(vec2(c, 1.0))); // lit towers
		} else if (k == 6) {
			col += vec3(step(0.996, hash21(floor(s * 60.0))));                                   // stars
		} else if (k == 7) {
			col += ft * smoothstep(0.0, 0.3, y) * (0.5 + 0.5 * sin(rd.x * 9.0 + t * 0.6)) * 0.6;  // aurora
		} else if (k == 8) {
			col += ft * step(0.985, hash11(floor(t * 3.0))) * 0.8;                               // lightning
		} else if (k == 9) {
			col += ft * smoothstep(0.08, 0.0, abs(length(rd.xy - vec2(0.0, 0.25)) - 0.18)) * 0.7; // a ring in the sky
		} else if (k == 10) {
			col = mix(col, ft, smoothstep(0.06, 0.04, length(rd.xy - vec2(0.2, 0.08))));         // setting sun
		}
	}
	return col;
}

void fragment() {
	vec3 eye = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 rd = normalize(v_wpos - eye);
	// Looking into the door: turn the ray into the world's frame, facing away from the corridor.
	vec3 into = normalize((MODEL_MATRIX * vec4(0.0, 0.0, -1.0, 0.0)).xyz);
	vec3 side = normalize(cross(vec3(0.0, 1.0, 0.0), into));
	vec3 r = vec3(dot(rd, side), rd.y, dot(rd, into));
	vec3 ro = vec3(dot(v_wpos, side), 0.0, dot(v_wpos, into)) * 0.3;
	vec3 col = world(v_world, normalize(vec3(r.x, r.y, max(r.z, 0.05))), ro);
	if (UV.y < 0.5) {
		// The strip of light under the leaf: the world's low sky, brightest in the middle.
		vec3 hi, lo, gr, ft;
		palette(v_world, hi, lo, gr, ft);
		col = lo * strip_energy * (0.4 + 0.6 * sin(PI * UV.x));
	}
#if CURRENT_RENDERER != RENDERER_COMPATIBILITY
	col = pow(col, vec3(2.2));
#endif
	ALBEDO = col;
}
