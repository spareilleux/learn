// The Grand Canal's fountain show (scripts/fountain_show.gd): what each nozzle does at each moment, read by
// the jets (fountain_jet.gdshader) and by the pools of light on the water under them
// (fountain_pool.gdshader). The author, 2026-10-13: « des fontaines colorées et peut-être des jets d'eau qui
// font un peu comme à Las Vegas des formes particulières ».
//
// The show is a loop of SHOW_SCENES scenes of SHOW_SCENE seconds, each fading into the next over SHOW_FADE.
// A nozzle is INSTANCE_CUSTOM: x its place along its group (0 to 1), y its group, z what the group needs
// besides, w a random number.
//   group 0: the two rows along the canal (z: -1 the row at -x, 1 the row at +x), 0 at the canal's head
//   group 1: the shooters down its middle (z: the shooter's number)
//   group 2: the three rings (z: the ring's number, plus 0.5 for every other nozzle)
//   group 3: the fan at the canal's far end, 0 at -x, 1 at +x
// A nozzle's frame (its instance's basis): +X towards the canal's middle for a row, the ring's for a ring,
// the world's +X for the fan; +Y up; +Z along the row, round the ring.

const float SHOW_G = 9.81;
const int SHOW_SCENES = 10;
const float SHOW_SCENE = 12.0;
const float SHOW_FADE = 2.0;
const float SHOW_LOOP = 120.0;
const float SHOW_TAU = 6.2831853;

// The lights' colours, as they are set (sRGB).
const vec3 SHOW_MOON = vec3(0.82, 0.9, 1.0);
const vec3 SHOW_BLUE = vec3(0.16, 0.42, 1.0);
const vec3 SHOW_CYAN = vec3(0.1, 0.85, 0.95);
const vec3 SHOW_GOLD = vec3(1.0, 0.72, 0.3);
const vec3 SHOW_ROSE = vec3(1.0, 0.25, 0.62);
const vec3 SHOW_VIOLET = vec3(0.55, 0.3, 1.0);
const vec3 SHOW_GREEN = vec3(0.15, 0.95, 0.55);

struct ShowJet {
	float h;            // m: how high its water rises above the nozzle
	float reach_in;     // m: how far from the nozzle it lands, along the frame's +X
	float reach_along;  // m: and along its +Z
	float valve;        // 0 shut, 1 open: how much water
	vec3 led;           // the colour of the light under it
};

vec3 show_rainbow(float p) {
	vec3 c = 0.5 + 0.5 * cos(SHOW_TAU * (p + vec3(0.0, 0.33, 0.67)));
	return mix(c, SHOW_MOON, 0.2);
}

// The fan's nozzle at x (-1 to 1 across it), opened by `open`: all within the canal's width.
ShowJet show_fan(float x, float top, float open, vec3 middle, vec3 edge) {
	return ShowJet(top * (1.0 - 0.55 * x * x) * (0.35 + 0.65 * open), 9.8 * x * open, 0.0, 1.0, mix(middle, edge, abs(x)));
}

// Scene k at t (seconds into the loop), lt seconds after the scene began (past SHOW_SCENE while it fades).
ShowJet show_scene(int k, int group, float u, float extra, float rnd, float t, float lt) {
	ShowJet j = ShowJet(0.0, 0.0, 0.0, 0.0, SHOW_MOON);
	float side = extra;                       // a row's
	float ring = floor(extra);                // a ring's
	float theta = u * SHOW_TAU;               // round a ring
	float fx = u * 2.0 - 1.0;                 // across the fan
	if (k == 0) {
		// The veil: the rows rise as two low curtains, the rings as low domes.
		float up = smoothstep(0.0, 5.0, lt);
		if (group == 0) {
			j = ShowJet(3.6 * up + 0.5 * up * sin(u * 60.0 + t * 0.9), 2.0, 0.0, up, mix(SHOW_BLUE, SHOW_MOON, 0.35));
		} else if (group == 2) {
			j = ShowJet(5.0 * up, 11.0, 0.0, up, SHOW_BLUE);
		}
	} else if (k == 1) {
		// The wave: a swell running down the rows, the shooters low between its crests.
		float ph = SHOW_TAU * (u * 3.0 - t * 0.22);
		if (group == 0) {
			j = ShowJet(12.0 + 7.0 * sin(ph), 1.5, 0.0, 1.0, mix(SHOW_BLUE, SHOW_CYAN, 0.5 + 0.5 * sin(ph)));
		} else if (group == 1) {
			j = ShowJet(7.0 - 4.0 * sin(ph), 0.0, 0.0, 1.0, SHOW_MOON);
		} else if (group == 2) {
			j = ShowJet(7.0, 5.5 + 2.0 * sin(t * 0.8 + ring * 2.1), 0.0, 1.0, SHOW_CYAN);
		}
	} else if (k == 2) {
		// The sway: the rows lean in and out together, the rings against them.
		float sw = sin(SHOW_TAU * t / 5.0);
		if (group == 0) {
			j = ShowJet(15.0, 3.5 + 6.0 * sw, 0.0, 1.0, mix(SHOW_ROSE, SHOW_VIOLET, 0.5 + 0.5 * sin(u * 9.0 - t * 0.6)));
		} else if (group == 1) {
			j = ShowJet(26.0 + 3.0 * sin(t + u * 9.0), 0.0, 0.0, 1.0, SHOW_MOON);
		} else if (group == 2) {
			j = ShowJet(9.0, 4.0 - 4.0 * sw, 0.0, 1.0, SHOW_VIOLET);
		}
	} else if (k == 3) {
		// The vault: each row's water lands by the other's, a nave of arches down the canal, and nothing
		// else, to see down it.
		if (group == 0) {
			j = ShowJet(15.0 + 2.0 * sin(SHOW_TAU * (u * 2.0 - t / 7.0)), 18.5, 0.0, 1.0, mix(SHOW_GOLD, SHOW_MOON, 0.15));
		}
	} else if (k == 4) {
		// The helix: each nozzle's water turns round its foot, a turn behind its neighbour's, the two rows
		// half a turn apart.
		float ph = SHOW_TAU * (u * 5.0 - t / 3.5) + (side > 0.0 ? 3.14159265 : 0.0);
		if (group == 0) {
			j = ShowJet(13.0, 4.0 + 4.5 * sin(ph), 4.5 * cos(ph), 1.0, side > 0.0 ? SHOW_ROSE : SHOW_CYAN);
		} else if (group == 1) {
			j = ShowJet(20.0 + 8.0 * sin(SHOW_TAU * (u * 2.0 + t / 6.0)), 0.0, 0.0, 1.0, SHOW_MOON);
		} else if (group == 2) {
			j = ShowJet(4.0, 11.0, 0.0, 1.0, SHOW_VIOLET);
		}
	} else if (k == 5) {
		// The baskets: each ring's jets lean round it one way, then the other.
		if (group == 0) {
			j = ShowJet(3.0 + 0.5 * sin(u * 60.0 + t), 2.0, 0.0, 1.0, mix(SHOW_BLUE, vec3(0.0), 0.3));
		} else if (group == 1) {
			j = ShowJet(6.0, 0.0, 0.0, 1.0, SHOW_GREEN);
		} else if (group == 2) {
			j = ShowJet(13.0, 4.0, 10.0 * sin(SHOW_TAU * t / 8.0), 1.0, mix(SHOW_GREEN, SHOW_GOLD, 0.5 + 0.5 * sin(theta * 3.0 + t)));
		}
	} else if (k == 6) {
		// The braid: the tops of each ring's jets on a (2, 3) torus knot round it, a trefoil, turning: every
		// other nozzle is on its second turn, half a turn of the tube away.
		float psi = 1.5 * theta + fract(extra) * SHOW_TAU + t * 0.9;
		if (group == 0) {
			j = ShowJet(5.0 + 1.5 * sin(SHOW_TAU * (u * 6.0 - t / 4.0)), 2.5, 0.0, 1.0, SHOW_VIOLET);
		} else if (group == 1) {
			j = ShowJet(8.0, 0.0, 0.0, 1.0, SHOW_MOON);
		} else if (group == 2) {
			j = ShowJet(9.0 + 2.6 * sin(psi), 5.0 - 4.4 * cos(psi), 0.0, 1.0, mix(SHOW_CYAN, SHOW_GOLD, 0.5 + 0.5 * sin(psi)));
		}
	} else if (k == 7) {
		// The chase: two bursts run down the shooters and back, the rows rising as they pass, the rings
		// beating.
		float p = fract(lt / 6.0) * 2.0;
		float run = p < 1.0 ? p : 2.0 - p;
		float d = min(abs(u - run), abs(u - (1.0 - run)));
		float by = 1.0 - smoothstep(0.05, 0.13, d);
		if (group == 0) {
			// A swell under each burst, a second across: rising and dropping within a quarter of one, the
			// rows' water was torn into sheets (shots/show/a4 head_t090).
			float swell = 1.0 - smoothstep(0.0, 0.33, d);
			j = ShowJet(6.0 + 8.0 * swell, 2.0, 0.0, 1.0, mix(SHOW_BLUE, SHOW_CYAN, swell));
		} else if (group == 1) {
			j = ShowJet(46.0, 0.0, 0.0, by, SHOW_MOON);
		} else if (group == 2) {
			float beat = pow(max(sin(SHOW_TAU * lt / 3.0 + ring), 0.0), 3.0);
			j = ShowJet(4.0 + 7.0 * beat, 11.0, 0.0, 1.0, SHOW_ROSE);
		}
	} else if (k == 8) {
		// The fan: it opens at the canal's end, a peacock's tail, over rows and shooters kept low before it,
		// the rings as tulips that open and close.
		if (group == 0) {
			j = ShowJet(4.5 + 1.5 * sin(SHOW_TAU * (u * 4.0 - t / 4.0)), 2.0, 0.0, 1.0, mix(SHOW_GREEN, SHOW_BLUE, 0.5 + 0.5 * sin(u * 12.0 + t * 0.5)));
		} else if (group == 1) {
			j = ShowJet(7.0 + 4.0 * sin(t * 1.3 + mod(extra, 2.0) * 3.14159265), 0.0, 0.0, 1.0, SHOW_CYAN);
		} else if (group == 2) {
			j = ShowJet(13.0, 3.0 + 4.0 * sin(t * 0.7 + ring * 2.1), 0.0, 1.0, SHOW_GOLD);
		} else {
			j = show_fan(fx, 30.0, smoothstep(0.0, 4.0, lt), SHOW_GREEN, SHOW_GOLD);
		}
	} else {
		// The finale: everything, in every colour, then the valves shut and the last water falls.
		float open = 1.0 - smoothstep(9.0, 10.0, lt);
		if (group == 0) {
			j = ShowJet(21.0 + 3.0 * sin(SHOW_TAU * (u * 4.0 - t / 2.0)), 3.0 + 4.0 * sin(SHOW_TAU * t / 3.0 + u * 12.0), 0.0, open,
				show_rainbow(u + t * 0.15 + side * 0.125));
		} else if (group == 1) {
			j = ShowJet(60.0 + 2.0 * sin(t * 3.0 + u * 20.0), 0.0, 0.0, open, show_rainbow(u * 0.5 + t * 0.1));
		} else if (group == 2) {
			j = ShowJet(14.0, 2.5 + 5.0 * sin(t * 1.2), 0.0, open, show_rainbow(u + ring * 0.33 - t * 0.2));
		} else {
			j = show_fan(fx, 30.0, 1.0, show_rainbow(t * 0.1), show_rainbow(t * 0.1 + 0.4));
			j.valve = open;
		}
	}
	return j;
}

// The nozzle at `time` (any time: the show loops): the scene it is in, mixed with the one before while
// that fades.
ShowJet show_jet(vec4 nozzle, float time) {
	float t = mod(time, SHOW_LOOP);
	int k = int(floor(t / SHOW_SCENE));
	float lt = t - float(k) * SHOW_SCENE;
	int group = int(nozzle.y + 0.5);
	ShowJet a = show_scene(k, group, nozzle.x, nozzle.z, nozzle.w, t, lt);
	float f = smoothstep(0.0, SHOW_FADE, lt);
	if (f < 1.0) {
		ShowJet b = show_scene((k + SHOW_SCENES - 1) % SHOW_SCENES, group, nozzle.x, nozzle.z, nozzle.w, t, lt + SHOW_SCENE);
		a.h = mix(b.h, a.h, f);
		a.reach_in = mix(b.reach_in, a.reach_in, f);
		a.reach_along = mix(b.reach_along, a.reach_along, f);
		a.valve = mix(b.valve, a.valve, f);
		a.led = mix(b.led, a.led, f);
	}
	return a;
}

// The velocity (m/s, in the nozzle's frame) the water leaves it with.
vec3 show_velocity(ShowJet j) {
	float h = max(j.h, 0.0);
	float flight = max(2.0 * sqrt(2.0 * h / SHOW_G), 0.5);
	return vec3(j.reach_in / flight, sqrt(2.0 * SHOW_G * h), j.reach_along / flight);
}
