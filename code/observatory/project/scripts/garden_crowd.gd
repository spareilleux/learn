extends Node3D
## A sparse crowd in the palace gardens, after the author's "On peut rajouter une foule (Clairsemee la
## foule) dans les jardins?" (2026-10-04): about a hundred people, most of them walking the garden's
## walks back and forth at their own pace, the others standing at the balustrade, round the basin, in the
## orchard and at the maze's temple. Four figures made in Blender (artpass/gardens/blender/crowd_kit.py),
## one MultiMesh each, walked in the vertex shader (assets/garden_plant.gdshader, kind 4): this script
## only moves each person along its walk, once a frame while the gardens show, and stops those the
## visitor comes near. The walks are scripts/palace_gardens.gd's (_build_crowd), which knows the grounds.

const FIGURES := ["courtier", "lady", "walker", "gardener"]
const FIGURE_PATH := "res://assets/garden_figure_%s.glb"
const LEG := 0.85            # a leg, hip to ankle (assets/garden_plant.gdshader's hip_y - ankle_y)
const LEG_SWING := 0.4       # radians a leg swings either way at stride 1, at a full pace, as the shader
## How far the legs swing in each figure (crowd_kit.py: 0.6 under the courtier's and the lady's robes).
const FIGURE_STRIDE := [0.6, 0.6, 1.0, 1.0]
const NEAR_STOP := 2.6       # a walker stops for the visitor this near, the visitor ahead of it
const RADIUS := 0.32         # a person, for a rider (push_out)
const TURN := 3.0            # radians a second a walker turns
const ACCEL := 1.5           # metres a second a walker gains or loses each second, setting off or stopping
const FOLLOW := 1.4          # a walker keeps this far behind someone going its way on its side of the walk
## Garments, linear: muted, as fine cloth by night. Gardeners wear the last four.
const CLOTH := [Color(0.3, 0.04, 0.05), Color(0.42, 0.26, 0.06), Color(0.04, 0.18, 0.2), Color(0.6, 0.56, 0.46),
	Color(0.09, 0.12, 0.28), Color(0.22, 0.06, 0.18), Color(0.17, 0.19, 0.06), Color(0.06, 0.06, 0.07),
	Color(0.6, 0.4, 0.06), Color(0.52, 0.2, 0.24), Color(0.26, 0.2, 0.14), Color(0.2, 0.22, 0.16),
	Color(0.32, 0.27, 0.2), Color(0.14, 0.15, 0.13)]

var stats := {"people": 0, "walkers": 0, "routes": 0, "stopped": 0, "updates": 0, "shown": 0, "kit": false}

var _gardens: Node
var _routes: Array = []       # each {"p": points, "n": their offsets to the side, "cum", "len", "half", "walkers"}
var _people: Array = []       # each a Dictionary (see _add)
var _mms: Array[MultiMesh] = []
var _rng := RandomNumberGenerator.new()


## gardens: scripts/palace_gardens.gd, for the ground's height (ground_at); mats: the figures' materials by
## their surfaces' names (skin, cloth, trim); routes: [points (PackedVector2Array, x and z), walkers, half
## the walk's width]; spots: [where (Vector2), what they look at (Vector2), figure or -1]. False when the
## kit's figures are missing.
func setup(gardens: Node, mats: Dictionary, routes: Array, spots: Array, seed: int) -> bool:
	_gardens = gardens
	_rng.seed = seed
	var meshes: Array[Mesh] = []
	for f: String in FIGURES:
		var path: String = FIGURE_PATH % f
		if not ResourceLoader.exists(path):
			return false
		var scene := (load(path) as PackedScene).instantiate()
		var found := scene.find_children("*", "MeshInstance3D", true, false)
		var mesh: Mesh = (found[0] as MeshInstance3D).mesh if not found.is_empty() else null
		scene.free()
		if mesh == null:
			return false
		mesh = mesh.duplicate() as Mesh
		for s in mesh.get_surface_count():
			var m := mesh.surface_get_material(s)
			var key := m.resource_name if m != null else ""
			if mats.has(key):
				mesh.surface_set_material(s, mats[key])
		meshes.append(mesh)
	stats.kit = true
	for r: Array in routes:
		var pts: PackedVector2Array = r[0]
		var cum := PackedFloat32Array([0.0])
		for i in range(1, pts.size()):
			cum.append(cum[i - 1] + pts[i].distance_to(pts[i - 1]))
		_routes.append({"p": pts, "n": _sides(pts), "cum": cum, "len": cum[cum.size() - 1], "half": float(r[2]), "walkers": []})
		var placed := PackedFloat32Array()
		for k in int(r[1]):
			# Not on top of someone already on the walk.
			var s := _rng.randf() * cum[cum.size() - 1]
			for attempt in 12:
				var clear := true
				for o in placed:
					clear = clear and absf(o - s) > 3.0
				if clear:
					break
				s = _rng.randf() * cum[cum.size() - 1]
			placed.append(s)
			_add(_routes.size() - 1, s, Vector2.ZERO, 0.0, -1)
	for s: Array in spots:
		var at: Vector2 = s[0]
		var look: Vector2 = s[1]
		_add(-1, 0.0, at, atan2(at.x - look.x, at.y - look.y), int(s[2]))
	stats.routes = _routes.size()
	stats.people = _people.size()
	# Each figure's instances in a shuffled order, so that showing only the first ones (set_quality) thins
	# every walk alike.
	var order := range(_people.size())
	for i in range(order.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t: int = order[i]
		order[i] = order[j]
		order[j] = t
	var counts := [0, 0, 0, 0]
	for i: int in order:
		var p: Dictionary = _people[i]
		p.idx = counts[p.fig]
		counts[p.fig] += 1
	for f in FIGURES.size():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = meshes[f]
		mm.instance_count = counts[f]
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Crowd_" + FIGURES[f]
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# The people move: a box round every walk, not round the instances' first places.
		mmi.custom_aabb = AABB(Vector3(-450, -15, -60), Vector3(900, 30, 520))
		add_child(mmi)
		_mms.append(mm)
	for p: Dictionary in _people:
		_mms[p.fig].set_instance_color(p.idx, p.cloth)
		_place(p, 0.0)
	stats.shown = stats.people
	return true


## Each point's offset to one side of the walk, mitred, so that a walker keeping its distance from the
## middle line keeps it round a bend.
static func _sides(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in pts.size():
		var a := (pts[i] - pts[maxi(i - 1, 0)]).normalized()
		var b := (pts[mini(i + 1, pts.size() - 1)] - pts[i]).normalized()
		var nb := Vector2(-b.y, b.x) if b != Vector2.ZERO else Vector2(-a.y, a.x)
		var na := Vector2(-a.y, a.x) if a != Vector2.ZERO else nb
		var m := (na + nb).normalized()
		out.append(m / maxf(m.dot(nb), 0.5))
	return out


## route: an index into _routes, at s metres along it; or -1 for someone standing at `at`, facing `yaw`.
func _add(route: int, s: float, at: Vector2, yaw: float, fig: int) -> void:
	var f := fig
	if f < 0:
		var u := _rng.randf()
		f = 0 if u < 0.36 else (1 if u < 0.72 else (2 if u < 0.92 else 3))
	var gardener := f == 3
	var cloth: Color = CLOTH[_rng.randi_range(10, 13) if gardener else _rng.randi_range(0, 9)]
	# The skin's tone in the alpha (the shader mixes a light and a dark tone by it).
	cloth.a = _rng.randf()
	var child := f == 2 and route >= 0 and _rng.randf() < 0.18
	var dir := 1.0 if _rng.randf() < 0.5 else -1.0
	# Walkers keep to their right of the walk's middle line, at a distance of their own.
	var lane := _rng.randf_range(0.45, 1.0) * float(_routes[route].half) if route >= 0 else 0.0
	# A shorter step, a slower walk: under a robe, at a cadence near the others'.
	var speed := _rng.randf_range(0.95, 1.45) * (0.85 if child else 1.0) * sqrt(float(FIGURE_STRIDE[f]))
	var p := {
		"route": route, "s": s, "dir": dir, "seg": 0, "lane": lane, "side": dir * lane, "wait": 0.0, "end": _rng.randf_range(0.0, 1.5),
		"speed": speed, "v": speed if route >= 0 else 0.0, "phase": _rng.randf(), "pace": 1.0 if route >= 0 else 0.0,
		"pos": at, "y": 0.0, "yaw": yaw, "fig": f, "idx": 0, "cloth": cloth,
		"trim": (4.0 if gardener else float(_rng.randi_range(0, 3))) / 4.0,
		"scale": 0.64 if child else _rng.randf_range(0.93, 1.07),
	}
	_people.append(p)
	if route >= 0:
		(_routes[route].walkers as Array).append(p)
		stats.walkers += 1


## From quality level 3, half the people; from level 4, a third.
func set_quality(level: int) -> void:
	var keep := 1.0 if level < 3 else (0.5 if level == 3 else 0.34)
	var shown := 0
	for mm in _mms:
		mm.visible_instance_count = -1 if keep >= 1.0 else ceili(mm.instance_count * keep)
		shown += mm.instance_count if keep >= 1.0 else mm.visible_instance_count
	stats.shown = shown


func _shown(p: Dictionary) -> bool:
	var mm := _mms[p.fig]
	return mm.visible_instance_count < 0 or int(p.idx) < mm.visible_instance_count


func _process(delta: float) -> void:
	if _mms.is_empty() or not is_visible_in_tree():
		return
	var t0 := Time.get_ticks_usec()
	var dt := minf(delta, 0.1)
	var cam := get_viewport().get_camera_3d()
	var eye := Vector3(1e9, 0.0, 1e9) if cam == null else cam.global_position
	var stopped := 0
	for p: Dictionary in _people:
		if not _shown(p):
			continue
		if int(p.route) >= 0:
			stopped += _step(p, dt, eye)
		_place(p, dt)
	stats.stopped = stopped
	stats.updates += 1
	# What a frame of it costs, smoothed: for the probes and the web page's tests.
	stats.process_us = roundi(lerpf(float(stats.get("process_us", 0)), float(Time.get_ticks_usec() - t0), 0.05))


## Walks p on by dt: it stops for the visitor in its way, keeps behind someone slower going its way on its
## side, steps aside for someone coming the other way on its line, slows down to the walk's end, waits
## there a moment, turning round and shuffling over to its other side, and walks back. 1 when the
## visitor stops it.
func _step(p: Dictionary, dt: float, eye: Vector3) -> int:
	var r: Dictionary = _routes[p.route]
	var pos: Vector2 = p.pos
	var fwd := Vector2(-sin(float(p.yaw)), -cos(float(p.yaw)))
	var to_eye := Vector2(eye.x, eye.z) - pos
	var blocked := to_eye.length() < NEAR_STOP and to_eye.dot(fwd) > -0.2 and absf(eye.y - float(p.y) - 1.2) < 2.5
	var dir := float(p.dir)
	var s := float(p.s)
	var length: float = r.len
	# Each turns back a little short of the walk's ends, at a distance of its own: two never meet there.
	var lo := minf(float(p.end), length * 0.2)
	var hi := length - lo
	var want := 0.0 if blocked or float(p.wait) > 0.0 else float(p.speed)
	want = clampf(0.15 + (hi - s if dir > 0.0 else s - lo) * 0.8, 0.0, want)
	var target := dir * float(p.lane)
	var across := 0.45 if float(p.wait) > 0.0 else float(p.v) * 0.5
	for o: Dictionary in r.walkers:
		if is_same(o, p) or absf(float(o.side) - float(p.side)) > 0.7:
			continue
		var ahead := (float(o.s) - s) * dir
		if float(o.dir) == dir:
			if ahead > 0.0 and ahead < FOLLOW:
				want = minf(want, float(o.v) * ahead / FOLLOW)
		elif ahead > 0.0 and ahead < 4.0:
			# Coming the other way on its line (or turning round at the walk's end): both to their own edge
			# of the walk, slowing as they near, waiting short of the other until the way is clear.
			target = dir * float(r.half)
			across = maxf(across, 0.8)
			want = minf(want, maxf(ahead - 0.7, 0.0) * 0.6)
	p.wait = maxf(float(p.wait) - dt, 0.0)
	var v := move_toward(float(p.v), want, ACCEL * dt)
	s += v * dt * dir
	if (dir > 0.0 and s >= hi) or (dir < 0.0 and s <= lo):
		s = clampf(s, lo, hi)
		p.dir = -dir
		p.wait = _rng.randf_range(1.5, 5.0)
		v = 0.0
	p.s = s
	p.v = v
	p.pace = clampf(v / float(p.speed), 0.0, 1.0)
	# To its side of the walk: shuffling over as it turns round, then across as it walks on.
	p.side = move_toward(float(p.side), target if float(p.dir) == dir else float(p.dir) * float(p.lane), across * dt)
	# The phase by the figure's own step (the shader's kind 4): its planted foot holds the ground.
	var cycle := 4.0 * LEG * sin(LEG_SWING * float(FIGURE_STRIDE[p.fig])) * sqrt(float(p.pace)) * float(p.scale)
	if cycle > 0.02:
		p.phase = fposmod(float(p.phase) + v * dt / cycle, 1.0)
	return 1 if blocked else 0


## Writes p's instance: where its walk and its side of it put it, turned towards where it goes.
func _place(p: Dictionary, dt: float) -> void:
	if int(p.route) >= 0:
		var r: Dictionary = _routes[p.route]
		var pts: PackedVector2Array = r.p
		var sides: PackedVector2Array = r.n
		var cum: PackedFloat32Array = r.cum
		var s := float(p.s)
		var seg := clampi(int(p.seg), 0, pts.size() - 2)
		while seg < pts.size() - 2 and s > cum[seg + 1]:
			seg += 1
		while seg > 0 and s < cum[seg]:
			seg -= 1
		p.seg = seg
		var t := clampf((s - cum[seg]) / maxf(cum[seg + 1] - cum[seg], 1e-4), 0.0, 1.0)
		var side := float(p.side)
		p.pos = (pts[seg] + sides[seg] * side).lerp(pts[seg + 1] + sides[seg + 1] * side, t)
		var along := (pts[seg + 1] - pts[seg]).normalized() * float(p.dir)
		var want := atan2(-along.x, -along.y)
		p.yaw = rotate_toward(float(p.yaw), want, TURN * dt) if dt > 0.0 else want
	var at: Vector2 = p.pos
	p.y = float(_gardens.call("ground_at", at))
	var basis := Basis(Vector3.UP, float(p.yaw)).scaled(Vector3.ONE * float(p.scale))
	var mm := _mms[p.fig]
	mm.set_instance_transform(p.idx, Transform3D(basis, Vector3(at.x, float(p.y), at.y)))
	mm.set_instance_custom_data(p.idx, Color(float(p.phase), float(p.pace), float(p.trim), float(FIGURE_STRIDE[p.fig])))


## Where a rider of radius r at q (x, z) ends once pushed out of the people near it.
func push_out(q: Vector2, r: float) -> Vector2:
	var out := q
	for p: Dictionary in _people:
		if not _shown(p):
			continue
		var d: Vector2 = out - (p.pos as Vector2)
		var reach := RADIUS * float(p.scale) + r
		if d.length_squared() < reach * reach:
			out = (p.pos as Vector2) + (d.normalized() if d.length_squared() > 1e-8 else Vector2.RIGHT) * reach
	return out


## Where the people shown within r of p stand: for the scooter's autopilot (scripts/segway.gd).
func near(p: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q: Dictionary in _people:
		if _shown(q) and (q.pos as Vector2).distance_squared_to(p) < r * r:
			out.append(q.pos)
	return out


## The people, for probes: each one's place, ground, pace, walk, side of it, figure and size.
func people() -> Array:
	var out := []
	for p: Dictionary in _people:
		out.append({"pos": p.pos, "y": p.y, "yaw": p.yaw, "v": p.v, "pace": p.pace, "route": p.route, "side": p.side,
			"fig": FIGURES[p.fig], "scale": p.scale, "shown": _shown(p), "wait": p.wait})
	return out


## The walks, for probes: their points, offsets to the side and half widths.
func routes() -> Array:
	var out := []
	for r: Dictionary in _routes:
		out.append({"p": r.p, "n": r.n, "half": r.half, "walkers": (r.walkers as Array).size()})
	return out
