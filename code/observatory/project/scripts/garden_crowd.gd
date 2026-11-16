extends Node3D
## A sparse crowd in the palace gardens, after the author's "On peut rajouter une foule (Clairsemee la
## foule) dans les jardins?" (2026-10-04): about a hundred people, most of them walking the garden's
## walks back and forth at their own pace, the others standing at the balustrade, round the basin, in the
## orchard and at the maze's temple. Four figures made in Blender (artpass/gardens/blender/crowd_kit.py),
## one MultiMesh each, walked in the vertex shader (assets/garden_plant.gdshader, kind 4): this script
## only moves each person along its walk, once a frame while the gardens show, and stops those the
## visitor comes near. The walks are scripts/palace_gardens.gd's (_build_crowd), which knows the grounds.
## Off the web (any renderer but Compatibility), the people are photographed ones when their files are there
## (artpass/gardens/people/, after the author's "il va falloir que tu utilises Comfy UI et Blender ... pour
## avoir des personnages photoréalistes", 2026-10-15): each figure from its far mesh, and the NEAR_SLOTS
## nearest of each within NEAR_R from its whole one; each person's white garment dyed in its colour.
## Those nearest walk on bones instead (scripts/garden_bones.gd): the rays never see the shader's walk, and the
## author, 2026-10-15: « les personnages doivent avancer normalement (en marchant, pas en glissant) - ils doivent
## être rigged »; then « les personnages ne savent toujours pas marcher correctement ». Rasterized as well as path
## traced, since the bones walk as people do and the shader's stick legs do not (skinning them: 112 ms at setup).

const GardenBones := preload("res://scripts/garden_bones.gd")
const FIGURES := ["courtier", "lady", "walker", "gardener"]
const FIGURE_PATH := "res://assets/garden_figure_%s.glb"
## The photographed people (artpass/gardens/people/: Z-Image-Turbo, TRELLIS.2, Blender, IX): whole (about 40 000
## triangles) and far (6 000), their colours, and their garment's share and roughness (dye.py).
const PHOTO_PATH := "res://assets/garden_person_%s.glb"
const PHOTO_FAR_PATH := "res://assets/garden_person_%s_far.glb"
const PHOTO_TEX := "res://assets/garden_person_%s_albedo.jpg"
const PHOTO_MASK := "res://assets/garden_person_%s_mask.png"
## Their folds, as TRELLIS.2 baked them (tangent space), when there; and how far their arms come down from the A
## pose and about which pivots (artpass/gardens/people/arm_pose.py: as far as leaves the hand 6 cm clear of the
## garment beside it, and 1.5 degrees more).
const PHOTO_NORMAL := "res://assets/garden_person_%s_normal.png"
const PHOTO_NORMAL_STRENGTH := 0.8
const PHOTO_POSE := {"courtier": [6.1, Vector2(0.123, 0.126)], "lady": [14.4, Vector2(0.082, 0.082)],
	"walker": [4.8, Vector2(0.131, 0.127)], "gardener": [5.3, Vector2(0.201, 0.088)]}
## Their joints, as rig_people.py set them (1.7 m tall; the shoulder by the body's proportions).
const PHOTO_JOINTS := {"shoulder_y": 1.394, "hip_y": 0.901, "ankle_y": 0.076}
const NEAR_R := 28.0         # a photographed person nearer the eye than this is drawn whole...
const NEAR_SLOTS := 8        # ...up to this many of each figure, the nearest
const LEG := 0.85            # a leg, hip to ankle (assets/garden_plant.gdshader's hip_y - ankle_y)
const LEG_SWING := 0.4       # radians a leg swings either way at stride 1, at a full pace, as the shader
## How far the legs swing in each figure (crowd_kit.py: 0.6 under the courtier's and the lady's robes).
const FIGURE_STRIDE := [0.6, 0.6, 1.0, 1.0]
## The photographed ones, whose shoes show under their hems: at 0.6 the robes took 113 to 171 steps a minute,
## scurrying; at 0.85, 96 to 146, a walk (artpass/gardens/people/gait_check.gd).
const PHOTO_STRIDE := [0.85, 0.85, 1.0, 1.0]
const NEAR_STOP := 2.6       # a walker stops for the visitor this near, the visitor ahead of it
const RADIUS := 0.32         # a person, for a rider (push_out)
const TURN := 3.0            # radians a second a walker turns
const ACCEL := 1.5           # metres a second a walker gains or loses each second, setting off or stopping
const PACE_EASE := 2.0       # the most a walker's pace (0 to 1) changes in a second, coming to a stop
const FOLLOW := 1.4          # a walker keeps this far behind someone going its way on its side of the walk
# Getting past (the author, 2026-10-16: « les personnages ont du mal à se contourner, ils restent complètement
# bloqués »): two on a walk 0.7 m wide, its edges 0.7 m apart, never passed, since passing asked for more than 0.7.
const PASS := 0.66           # m from side to side: two people pass, shoulder by shoulder (RADIUS each)
const ROUND := 0.75          # m aside of the visitor, to get round them
const STUCK_TURN := 5.0      # s stopped, and not waiting at a walk's end: it turns back
## Garments, linear: muted, as fine cloth by night. Gardeners wear the last four.
const CLOTH := [Color(0.3, 0.04, 0.05), Color(0.42, 0.26, 0.06), Color(0.04, 0.18, 0.2), Color(0.6, 0.56, 0.46),
	Color(0.09, 0.12, 0.28), Color(0.22, 0.06, 0.18), Color(0.17, 0.19, 0.06), Color(0.06, 0.06, 0.07),
	Color(0.6, 0.4, 0.06), Color(0.52, 0.2, 0.24), Color(0.26, 0.2, 0.14), Color(0.2, 0.22, 0.16),
	Color(0.32, 0.27, 0.2), Color(0.14, 0.15, 0.13)]
## The photographed garments' dyes, linear, over their white (garden_plant.gdshader white_ref): the dyes of fine
## wool and silk, deep and greyed, some left undyed (the CLOTH colours multiplied the photographs' white into
## plastic yellows and magentas: grand/allee1-fwd). In the same places as CLOTH's, so the draws stay as they were.
const PHOTO_CLOTH := [Color(0.2, 0.04, 0.05), Color(0.34, 0.24, 0.12), Color(0.05, 0.1, 0.12), Color(0.72, 0.69, 0.62),
	Color(0.06, 0.08, 0.15), Color(0.16, 0.08, 0.12), Color(0.12, 0.13, 0.07), Color(0.06, 0.06, 0.065),
	Color(0.62, 0.6, 0.55), Color(0.3, 0.17, 0.17), Color(0.4, 0.33, 0.24), Color(0.22, 0.22, 0.18),
	Color(0.48, 0.43, 0.34), Color(0.18, 0.18, 0.16)]

var stats := {"people": 0, "walkers": 0, "routes": 0, "stopped": 0, "updates": 0, "shown": 0, "kit": false, "photo": false, "near": 0}

var _gardens: Node
var _routes: Array = []       # each {"p": points, "n": their offsets to the side, "cum", "len", "half", "walkers"}
var _people: Array = []       # each a Dictionary (see _add)
var _mms: Array[MultiMesh] = []
var _photo := false
var _near: Array[MultiMesh] = []   # photographed: each figure's whole mesh, for the nearest of them
var _near_used := [0, 0, 0, 0]
var _near_src: Array[Mesh] = []    # their whole meshes, to be skinned (_build_rigged)
var _rays := false
var _bones := false               # the nearest on bones: photographed, off the web
var _rigged: Array = []           # each figure's NEAR_SLOTS skinned people (_build_rigged)
var _leg := LEG
var _strides: Array = FIGURE_STRIDE
var _elbows: Array = []           # each figure's elbows at rest, right and left (GardenBones.skin_mesh)
var _joints: Array = []           # each figure's PHOTO_JOINTS, with its shoes' heel and ball
var _rng := RandomNumberGenerator.new()
var _fit: Node                    # view_fit.gd, for the screen's zoom (_draw_near)


## gardens: scripts/palace_gardens.gd, for the ground's height (ground_at); mats: the figures' materials by
## their surfaces' names (skin, cloth, trim); routes: [points (PackedVector2Array, x and z), walkers, half
## the walk's width]; spots: [where (Vector2), what they look at (Vector2), figure or -1]. False when the
## kit's figures are missing.
func setup(gardens: Node, mats: Dictionary, routes: Array, spots: Array, seed: int) -> bool:
	_gardens = gardens
	_rng.seed = seed
	var meshes: Array[Mesh] = []
	var near_meshes: Array[Mesh] = []
	_photo = RenderingServer.get_current_rendering_method() != "gl_compatibility" and mats.has("cloth")
	for f: String in FIGURES:
		if not _photo:
			break
		var near := _first_mesh(PHOTO_PATH % f)
		var far := _first_mesh(PHOTO_FAR_PATH % f)
		if near == null or far == null or not ResourceLoader.exists(PHOTO_TEX % f) or not ResourceLoader.exists(PHOTO_MASK % f):
			_photo = false
			break
		var m := (mats["cloth"] as ShaderMaterial).duplicate() as ShaderMaterial
		m.set_shader_parameter("photo", true)
		m.set_shader_parameter("tex", load(PHOTO_TEX % f))
		m.set_shader_parameter("mask_tex", load(PHOTO_MASK % f))
		for k: String in PHOTO_JOINTS:
			m.set_shader_parameter(k, PHOTO_JOINTS[k])
		if ResourceLoader.exists(PHOTO_NORMAL % f):
			m.set_shader_parameter("normal_tex", load(PHOTO_NORMAL % f))
			m.set_shader_parameter("normal_strength", PHOTO_NORMAL_STRENGTH)
		var pose: Array = PHOTO_POSE[f]
		m.set_shader_parameter("arm_lower", deg_to_rad(float(pose[0])))
		m.set_shader_parameter("shoulder_x", pose[1])
		for mesh: Mesh in [near, far]:
			for s in mesh.get_surface_count():
				mesh.surface_set_material(s, m)
		near_meshes.append(near)
		meshes.append(far)
	if _photo:
		_leg = float(PHOTO_JOINTS.hip_y) - float(PHOTO_JOINTS.ankle_y)
		_near_src = near_meshes
		_strides = PHOTO_STRIDE
	else:
		meshes.clear()
		near_meshes.clear()
		for f: String in FIGURES:
			var mesh := _first_mesh(FIGURE_PATH % f)
			if mesh == null:
				return false
			for s in mesh.get_surface_count():
				var m := mesh.surface_get_material(s)
				var key := m.resource_name if m != null else ""
				if mats.has(key):
					mesh.surface_set_material(s, mats[key])
			meshes.append(mesh)
	stats.kit = true
	stats.photo = _photo
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
		if _photo:
			var nm := MultiMesh.new()
			nm.transform_format = MultiMesh.TRANSFORM_3D
			nm.use_colors = true
			nm.use_custom_data = true
			nm.mesh = near_meshes[f]
			nm.instance_count = NEAR_SLOTS
			for j in NEAR_SLOTS:
				nm.set_instance_transform(j, HIDDEN)
			nm.visible_instance_count = 0
			var nmi := MultiMeshInstance3D.new()
			nmi.name = "CrowdNear_" + FIGURES[f]
			nmi.multimesh = nm
			nmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			nmi.custom_aabb = mmi.custom_aabb
			add_child(nmi)
			_near.append(nm)
	for p: Dictionary in _people:
		_mms[p.fig].set_instance_color(p.idx, p.cloth)
		_place(p, 0.0)
	stats.shown = stats.people
	_bones = _photo and not _near_src.is_empty()
	if _bones:
		_build_rigged()
	stats.rigged = _bones
	return true


## A scene file's first mesh, a copy of it (its materials are set per crowd); null when it is missing.
static func _first_mesh(path: String) -> Mesh:
	if not ResourceLoader.exists(path):
		return null
	var scene := (load(path) as PackedScene).instantiate()
	var found := scene.find_children("*", "MeshInstance3D", true, false)
	var mesh: Mesh = (found[0] as MeshInstance3D).mesh if not found.is_empty() else null
	scene.free()
	return mesh.duplicate() as Mesh if mesh != null else null


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
	var cloth: Color = (PHOTO_CLOTH if _photo else CLOTH)[_rng.randi_range(10, 13) if gardener else _rng.randi_range(0, 9)]
	# The skin's tone in the alpha (the shader mixes a light and a dark tone by it).
	cloth.a = _rng.randf()
	var child := f == 2 and route >= 0 and _rng.randf() < 0.18
	var dir := 1.0 if _rng.randf() < 0.5 else -1.0
	# Walkers keep to their right of the walk's middle line, at a distance of their own.
	var lane := _rng.randf_range(0.45, 1.0) * float(_routes[route].half) if route >= 0 else 0.0
	# A shorter step, a slower walk: under a robe, at a cadence near the others'.
	var speed := _rng.randf_range(0.95, 1.45) * (0.85 if child else 1.0) * sqrt(float(_strides[f]))
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


## Path traced or not (scripts/palace_gardens.gd set_rt_lit): the nearest walk on bones either way (_bones). The
## skinned people are kept, those unused out of sight under the ground (each hidden one would lose its place in the
## rays' cache, to be rebuilt on its return); each slot is let go, to be taken again by the nearest.
func set_rays(on: bool) -> void:
	_rays = on and _bones
	for slots: Array in _rigged:
		for sl: Dictionary in slots:
			(sl.root as Node3D).transform = HIDDEN
			sl.who = null
	for f in _near.size():
		_near_used[f] = NEAR_SLOTS


func _build_rigged() -> void:
	for f in FIGURES.size():
		var src := _near_src[f]
		var mask: Image = (load(PHOTO_MASK % FIGURES[f]) as Texture2D).get_image() if ResourceLoader.exists(PHOTO_MASK % FIGURES[f]) else null
		var mesh := GardenBones.skin_mesh(src, PHOTO_JOINTS, PHOTO_POSE[FIGURES[f]][1], mask)
		_elbows.append(mesh.get_meta("elbows"))
		var jf: Dictionary = PHOTO_JOINTS.duplicate()
		jf.merge(mesh.get_meta("foot"))
		_joints.append(jf)
		var base := src.surface_get_material(0) as ShaderMaterial
		var slots := []
		for j in NEAR_SLOTS:
			var root := Node3D.new()
			root.name = "Rigged_%s_%d" % [FIGURES[f], j]
			root.transform = HIDDEN
			var sk := GardenBones.skeleton()
			root.add_child(sk)
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			mi.skin = GardenBones.skin()
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var mat := base.duplicate() as ShaderMaterial
			mat.set_shader_parameter("skinned", true)
			mi.material_override = mat
			sk.add_child(mi)
			# Its skeleton: its parent, named. The path's default is empty in 4.6 (not ".."): the skin bound to no
			# skeleton and the person drawn unposed, a block gliding (artpass/gardens/people/skin_probe.gd).
			mi.skeleton = NodePath("..")
			add_child(root)
			slots.append({"root": root, "sk": sk, "mat": mat, "who": null})
		_rigged.append(slots)
	print("CROWD on bones: %d people of each of %d figures" % [NEAR_SLOTS, FIGURES.size()])


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
	if _photo:
		_draw_near(eye, dt, cam)
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
	var dir := float(p.dir)
	# Ahead along its walk, not its face: stepping aside, it turns to the side it steps to.
	var pts: PackedVector2Array = r.p
	var sides: PackedVector2Array = r.n
	var seg := clampi(int(p.seg), 0, pts.size() - 2)
	var fwd := (pts[seg + 1] - pts[seg]).normalized() * dir
	var to_eye := Vector2(eye.x, eye.z) - pos
	var blocked := to_eye.length() < NEAR_STOP and to_eye.dot(fwd) > -0.2 and absf(eye.y - float(p.y) - 1.2) < 2.5
	var s := float(p.s)
	var length: float = r.len
	# Each turns back a little short of the walk's ends, at a distance of its own: two never meet there.
	var lo := minf(float(p.end), length * 0.2)
	var hi := length - lo
	var want := 0.0 if float(p.wait) > 0.0 else float(p.speed)
	want = clampf(0.15 + (hi - s if dir > 0.0 else s - lo) * 0.8, 0.0, want)
	var target := dir * float(p.lane)
	# Over to its side as it walks on, never standing (shuffled across there, it slid 0.45 m a second on planted feet:
	# artpass/gardens/people/crowd_slip.gd).
	var across := 0.0 if float(p.wait) > 0.0 else float(p.v) * 0.5
	for o: Dictionary in r.walkers:
		if is_same(o, p) or absf(float(o.side) - float(p.side)) >= PASS:
			continue
		var ahead := (float(o.s) - s) * dir
		if float(o.dir) == dir:
			if ahead > 0.0 and ahead < FOLLOW:
				want = minf(want, float(o.v) * ahead / FOLLOW)
		elif ahead > 0.0 and ahead < 4.0:
			# Coming the other way on its line (or turning round at the walk's end): both to their own edge
			# of the walk, PASS apart at least, slowing as they near, waiting short of the other until the way
			# is clear.
			target = dir * maxf(float(r.half), PASS * 0.5 + 0.02)
			across = maxf(across, 0.8)
			want = minf(want, maxf(ahead - 0.7, 0.0) * 0.6)
	# The visitor in the way: round them within the walk, slowing as it passes; stopped only until it has
	# stepped aside, or where the walk leaves no room (then, in a while, it turns back).
	if blocked:
		var eye_side := float(p.side) + to_eye.dot(sides[seg])
		var half := float(r.half)
		var gap := float(p.side) - eye_side
		var clear := true
		if absf(target - eye_side) < ROUND or signf(target - eye_side) != signf(gap):
			# Its line runs into them, or across them: the nearest clear place within the walk on its own side,
			# or else on the other, reached walking on, stepping across as it goes (a sidestep where it stands
			# slid its planted feet 188 mm a second: artpass/gardens/people/crowd_slip.gd).
			clear = false
			for aside: float in [eye_side + signf(gap + 1e-3) * ROUND, eye_side - signf(gap + 1e-3) * ROUND]:
				if absf(aside) <= half and not clear:
					target = aside
					clear = true
			across = maxf(across, float(p.v) * 0.6)
		# Stopped while not yet past them and too near to step round, or with no room to.
		blocked = absf(gap) < ROUND - 0.05 and (not clear or to_eye.dot(fwd) < 1.0)
		want = 0.0 if blocked else minf(want, float(p.speed) * 0.7)
	p.wait = maxf(float(p.wait) - dt, 0.0)
	# Stopped too long, and not at a walk's end: it turns back, so that nobody stands stuck for good.
	if want < 0.05 and float(p.wait) <= 0.0:
		p.stuck = float(p.get("stuck", 0.0)) + dt
		if float(p.stuck) > STUCK_TURN:
			p.dir = -dir
			p.wait = _rng.randf_range(0.6, 1.4)
			p.stuck = 0.0
			stats.turned_back = int(stats.get("turned_back", 0)) + 1
			want = 0.0
	else:
		p.stuck = 0.0
	var v := move_toward(float(p.v), want, ACCEL * dt)
	s += v * dt * dir
	if (dir > 0.0 and s >= hi) or (dir < 0.0 and s <= lo):
		s = clampf(s, lo, hi)
		p.dir = -dir
		p.wait = _rng.randf_range(1.5, 5.0)
		v = 0.0
	p.s = s
	p.v = v
	# To its side of the walk, across as it walks on (_place steps it by the ground it covers).
	p.side = move_toward(float(p.side), target if float(p.dir) == dir else float(p.dir) * float(p.lane), across * dt)
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
		var was: Vector2 = p.pos
		p.pos = (pts[seg] + sides[seg] * side).lerp(pts[seg + 1] + sides[seg + 1] * side, t)
		var along := (pts[seg + 1] - pts[seg]).normalized() * float(p.dir)
		var want := atan2(-along.x, -along.y)
		if dt > 0.0:
			# The phase by the figure's own step (the shader's kind 4) and the ground it covers, forward, aside and
			# round a bend on its side of the walk, turned the way it goes: its planted foot holds the ground. Stepped
			# by the walk's length instead, it slid 57 mm a second walking on (artpass/gardens/people/crowd_slip.gd).
			var moved: Vector2 = (p.pos as Vector2) - was
			var g := moved.length() / dt
			if g > 0.05:
				want = atan2(-moved.x, -moved.y)
			# Easing down to a stop at the walk's end, from 0.15 m/s: its feet come together over a few frames.
			p.pace = move_toward(float(p.pace), clampf(g / float(p.speed), 0.0, 1.0), PACE_EASE * dt)
			var cycle := 4.0 * _leg * sin(LEG_SWING * float(_strides[p.fig])) * sqrt(float(p.pace)) * float(p.scale)
			if cycle > 0.02:
				p.phase = fposmod(float(p.phase) + moved.length() / cycle, 1.0)
		p.yaw = rotate_toward(float(p.yaw), want, TURN * dt) if dt > 0.0 else want
	var at: Vector2 = p.pos
	p.y = float(_gardens.call("ground_at", at))
	var basis := Basis(Vector3.UP, float(p.yaw)).scaled(Vector3.ONE * float(p.scale))
	var mm := _mms[p.fig]
	p.xf = Transform3D(basis, Vector3(at.x, float(p.y), at.y))
	p.custom = Color(float(p.phase), float(p.pace), float(p.trim), float(_strides[p.fig]))
	mm.set_instance_transform(p.idx, p.xf)
	mm.set_instance_custom_data(p.idx, p.custom)


## An instance put out of sight: shrunk to nothing, out under the ground.
const HIDDEN := Transform3D(Basis(Vector3(1e-4, 0, 0), Vector3(0, 1e-4, 0), Vector3(0, 0, 1e-4)), Vector3(0, -200, 0))


## The nearest photographed people of each figure, within NEAR_R of the eye, drawn whole: their far instances
## hidden, the whole mesh's slots taking their places (_place has just written them all). Through the telescope or
## the monocle (view_fit.gd zoom), as near as the screen shows them: their distance times the zoom, those in its
## field only. The author, through the telescope, 2026-10-16: « quand on zoome les personnages glissent »: 160 m
## off at x6.7, the 55 people in the field were all far instances, which the rays see unwalked, gliding
## (artpass/gardens/people/crowd_slip.gd).
func _draw_near(eye: Vector3, dt: float, cam: Camera3D) -> void:
	var zoom := _zoom(cam)
	var inv := Transform3D.IDENTITY
	var half := Vector2.ZERO  # the field's half widths across and up, as tangents, with a margin
	if zoom < 0.999:
		inv = cam.global_transform.affine_inverse()
		var up := tan(deg_to_rad(float(_fit.call("fitted", cam.fov))) * 0.5) * zoom * 1.15
		var size := get_viewport().get_visible_rect().size
		half = Vector2(up * size.x / maxf(size.y, 1.0), up)
	var nearest: Array = [[], [], [], []]
	for p: Dictionary in _people:
		if not _shown(p):
			continue
		var d2 := Vector2(eye.x, eye.z).distance_squared_to(p.pos)
		if zoom < 0.999:
			var q := inv * Vector3((p.pos as Vector2).x, float(p.y) + 0.9, (p.pos as Vector2).y)
			if q.z > -0.3 or absf(q.x) > half.x * -q.z + 0.5 or absf(q.y) > half.y * -q.z + 1.0:
				continue
			d2 = q.length_squared() * zoom * zoom
		if d2 < NEAR_R * NEAR_R:
			(nearest[p.fig] as Array).append([d2, p])
	var shown := 0
	var t := Time.get_ticks_msec() * 0.001
	for f in FIGURES.size():
		var list: Array = nearest[f]
		list.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		var nm := _near[f]
		var n := mini(list.size(), NEAR_SLOTS)
		var rig: Array = _rigged[f] if _bones else []
		var pose: Array = PHOTO_POSE[FIGURES[f]]
		for j in n:
			var p: Dictionary = list[j][1]
			if rig.is_empty():
				nm.set_instance_transform(j, p.xf)
				nm.set_instance_custom_data(j, p.custom)
				nm.set_instance_color(j, p.cloth)
			else:
				# On bones; the dye set only when the slot's person changes.
				var sl: Dictionary = rig[j]
				(sl.root as Node3D).transform = p.xf
				# Its robe goes with the person, from slot to slot as the nearest change places.
				if not p.has("robe"):
					p.robe = GardenBones.cloth_state()
				GardenBones.pose(sl.sk, float(p.phase), float(p.pace), float(_strides[f]), _joints[f],
						deg_to_rad(float(pose[0])), pose[1], t, _elbows[f], p.robe, p.xf, dt, int(stats.updates))
				if not is_same(sl.who, p):
					sl.who = p
					(sl.mat as ShaderMaterial).set_shader_parameter("dye", p.cloth)
			_mms[f].set_instance_transform(p.idx, HIDDEN)
		for j in range(n, int(_near_used[f])):
			if rig.is_empty():
				nm.set_instance_transform(j, HIDDEN)
			else:
				(rig[j].root as Node3D).transform = HIDDEN
				rig[j].who = null
		_near_used[f] = n
		nm.visible_instance_count = 0 if not rig.is_empty() else n
		shown += n
	stats.near = shown
	stats.near_zoom = snappedf(zoom, 0.001)


## The inverse of what the screen magnifies by (view_fit.gd zoom: the telescope's down to 0.01, the monocle's to 0.4),
## 1 without it.
func _zoom(cam: Camera3D) -> float:
	if cam == null:
		return 1.0
	if _fit == null or not is_instance_valid(_fit):
		_fit = null
		var n := cam.get_parent()
		while n != null and _fit == null:
			_fit = n.get_node_or_null("ViewFit")
			n = n.get_parent()
		if _fit == null:
			return 1.0
	return clampf(float(_fit.get("zoom")), 0.001, 1.0)


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
