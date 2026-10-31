extends RefCounted
## Bones for the photographed people of the gardens (scripts/garden_crowd.gd), so that the path tracer sees them
## walk. The author, 2026-10-15: « les personnages sont figés et ne sont pas avec "rig" », then « les personnages
## doivent avancer normalement (en marchant, pas en glissant) - ils doivent être rigged ». assets/garden_plant.gdshader
## (kind 4) walks them in its vertex stage, which NVIDIA's fork never runs for its rays; the fork does trace a
## skinned mesh as deformed each frame (render_raytracing.h, RTDeformedGeometrySource), so they walk here on bones.
## The author again, 2026-10-15: « les personnages ne savent toujours pas marcher correctement ». The first bones
## copied the shader's walk, a leg turned whole about the hip like a stilt, the foot flat, the robe a rigid tube
## over shoes sliding under its hem. They walk now as people do, the gait drawn from its phases:
##   stance   the foot lands on its heel, toes up, rolls flat, and comes up on its ball, the toes staying flat;
##            whichever of heel, sole or ball is on the ground stays where it was put down, to the millimetre
##            (artpass/gardens/people/gait_check.gd); heel and ball where each figure's shoes have them;
##   swing    the foot goes from where it came off to where it lands, lifted early, the knee bending as far as
##            that asks (sixty degrees or so), then reaching forward, the knee straightening before the heel lands;
##   legs     thigh and shin, put by the hip and the ankle (two-bone IK), the knee forward;
##   hips     as high as the legs bearing the weight reach, a little less (the knee giving 18 degrees as the
##            heel lands, 8 at midstance): lowest as the weight passes from foot to foot, highest over the planted
##            foot, the inverted pendulum's rise and fall; the foot behind, once the other is down, no longer
##            holds them: its heel comes up as far as it must, its knee bending to 35 degrees as it comes off
##            (straightened to 4 degrees there, then bent again, it snapped);
##   robe     its lower half, each side, going some way with that side's thigh; and below the waist, a pendulum
##            hung there (cloth_step): what the waist does, the hem does after, swaying across with each step as
##            the hips go over the planted foot, running on at a stop and back at a start, swinging out in a
##            turn, the skirt twisting behind as the body turns. The author, 2026-10-15: « Les vêtements doivent
##            pouvoir bouger naturellement »;
##   arms     lowered from the A pose about the shoulder, swung against the legs, the elbow bending more forward.
## The weights are made here from the walk's own in UV2 (artpass/gardens/people/rig_people.py: x a leg's weight,
## + the left, or 2 + an arm's, + the right; y how far down the garment hangs) and from where each vertex is:
## thigh, shin or foot by height, upper arm or forearm by distance from the shoulder. Each bone rests at the origin
## unturned, binding with the identity, so that a bone's pose is the very transform a vertex takes. The shader's
## walk (stock and the web) is unchanged.

enum { BODY, BODY_HEM, THIGH_L, THIGH_R, SHIN_L, SHIN_R, FOOT_L, FOOT_R, UPPER_R, UPPER_L, FORE_R, FORE_L, TOE_L, TOE_R }
const BONES := 14
const NAMES := ["body", "body_hem", "thigh_l", "thigh_r", "shin_l", "shin_r", "foot_l", "foot_r", "upper_r", "upper_l",
	"fore_r", "fore_l", "toe_l", "toe_r"]
const LEG_SWING := 0.4     # the shader's: the stride, as the crowd steps the phase by it (garden_crowd.gd cycle)
const KNEE := 0.49         # the knee's height between ankle (0) and hip (1)
const DUTY := 0.6          # the share of a cycle a foot is on the ground
const LAND := 0.25         # cycles' length ahead of the hip a foot lands
const HEEL := 0.06         # m behind the ankle, the heel's back, where a shoe has none to measure
const BALL := 0.13         # m ahead of it, the ball of the foot
const BALL_AT := 0.3       # the ball's place along the sole, from the toe (skin_mesh measures each shoe)
const STRIKE := 0.2        # rad, the toes up as the heel lands
const PUSH := 0.6          # rad, the heel up as the foot comes off
const FLAT := Vector2(0.08, 0.36)  # the stance's phases (of the cycle) between which the sole is flat
const LIFT := 0.085        # m the ankle rises in the swing, over the straight line, at a full pace
const LIFT_END := 0.72     # of the swing, by which the foot is down to its landing height (lifted to the end, the
                           # knee came forward bent 55 degrees a tenth of a cycle before the heel landed)
const CLEAR := 0.015       # m the heel stays clear of the ground meanwhile, reaching forward
const LIFT_MAX := 0.75     # rad the heel is up as the foot comes off (raised as far as kept the ball down, it
                           # raced near the ankle's nearest the hips: the gardener's boots, 0.8 to 1.17 rad in three
                           # steps of 1/240; the walker's, 0.57 to 0.75 in four)
const PRESWING := 0.61     # rad the knee is bent at the least as the foot comes off, from none as the other lands
const FALL := 0.25         # m the hips may stand over a swinging foot's landing reach, times (1 - its swing)^2
const SETTLE := Vector2(0.002, 0.009)  # m the hips stay under a bearing leg's reach: always, and more as it
										# takes the weight (the knee giving), peaking an eighth into its stance
const ARM_SWING := 0.28    # rad either way (0.38 put the hand forward level with the elbow: walk-bones-3)
const UPPER_ARM := 0.29    # m from the shoulder's pivot to the elbow
const ELBOW := 0.15        # rad the elbow is bent at the least, walking
const ELBOW_SWING := 0.2   # rad more as the arm swings forward
const KNEE_BLEND := 0.07   # m either side of the knee over which thigh gives way to shin (0.05 balled wide trousers)
const GARMENT := 0.4       # the most the robe below the hips goes with a thigh (0.6 parted a gown in two bells)
const GARMENT_HEM := 0.5   # of which its hem keeps this much, the pendulum carrying the rest
const GARMENT_X := Vector2(0.015, 0.09)  # m from the body's middle over which it comes to that
const GARMENT_Y := 0.24    # m below the hips at which it has
const WAIST := 0.12        # m over the hips, where the robe's pendulum hangs from
const CLOTH_L := 0.36      # m, its length: on its own it sways at 0.83 Hz, near a walk's own sway
const CLOTH_DAMP := 0.3    # its damping ratio: a stop's swing dies in two or three sways
const CLOTH_COUPLE := 0.6  # how much of the waist's push the hem takes: cloth is no free weight on a string
const CLOTH_MAX := 0.32    # rad, the most it swings
const TRAIL := 0.045       # rad the hem trails behind at a full pace, the legs and the air pushing it
const TWIST_HZ := 0.9      # the skirt's twist, ringing
const TWIST_MAX := 0.5     # rad
const LEAN := 0.018        # metres the body leans onto the supporting foot, at 1.6 m and over
const SWAY := 0.012        # metres the standing shift their weight, the same way


## src's surfaces with bones and weights, and their materials. joints: hip_y, ankle_y, shoulder_y; shoulder_x: the
## shoulders' pivots' x, right and left (garden_crowd.gd PHOTO_POSE). Its meta "elbows": each arm's elbow at rest,
## right then left; and "foot": the shoes' heel and ball, metres behind and ahead of the ankle, from their soles
## (the vertices of the legs within 2 cm of the ground), to merge into the joints pose() is given. mask: the
## figure's cloth mask (garden_crowd.gd PHOTO_MASK, red where the cloth is dyed) or null: under a robe down to the
## ground, what of the legs' marks is dyed cloth is the robe's hem lying on the shoes, and goes with the robe (on
## the feet, the lady's hem was drawn out in shards: walk-bones-3). A leg's mark gives way above the hips, where
## a rig marked part of a coat (the gardener's, up to 1.7 m), which a thigh would have swung back. Triangles from
## one leg to the other are left out: where a generated mesh has the two legs grown together (the gardener's wide
## trousers, from 0.3 to 0.6 m), they stretched into a web between the legs as these parted (walk-bones-4). Its meta
## "cut": how many.
static func skin_mesh(src: Mesh, joints: Dictionary, shoulder_x: Vector2, mask: Image = null) -> ArrayMesh:
	var hip := float(joints.hip_y)
	var ankle := float(joints.ankle_y)
	var knee := ankle + KNEE * (hip - ankle)
	var shoulder := float(joints.shoulder_y)
	var pivots := [Vector2(shoulder_x.x, shoulder), Vector2(-shoulder_x.y, shoulder)]
	# Each arm's line at rest, from its pivot along its vertices: where the elbow is.
	var sums := [Vector2.ZERO, Vector2.ZERO]
	for s in src.get_surface_count():
		var arrays := src.surface_get_arrays(s)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2] if arrays[Mesh.ARRAY_TEX_UV2] != null else PackedVector2Array()
		for i in mini(v.size(), uv2.size()):
			if uv2[i].x > 2.9 or uv2[i].x < -2.9:
				var k := 0 if uv2[i].x > 0.0 else 1
				var d := Vector2(v[i].x, v[i].y) - (pivots[k] as Vector2)
				if d.length() > 0.05:
					sums[k] += d.normalized()
	# The soles: the heel at their back, the ball a third of the way from their toe.
	var sole := Vector2(1e9, -1e9)
	for s in src.get_surface_count():
		var arrays := src.surface_get_arrays(s)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2] if arrays[Mesh.ARRAY_TEX_UV2] != null else PackedVector2Array()
		for i in mini(v.size(), uv2.size()):
			if uv2[i].x != 0.0 and absf(uv2[i].x) < 1.5 and v[i].y < 0.02:
				sole = Vector2(minf(sole.x, v[i].z), maxf(sole.y, v[i].z))
	# A robe to the ground: its garment hanging within 30 cm of it.
	var robe := false
	for s in src.get_surface_count():
		var arrays := src.surface_get_arrays(s)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2] if arrays[Mesh.ARRAY_TEX_UV2] != null else PackedVector2Array()
		for i in mini(v.size(), uv2.size()):
			if uv2[i].x == 0.0 and uv2[i].y > 0.5 and v[i].y < 0.3:
				robe = true
				break
	if mask != null and mask.is_compressed():
		mask = mask.duplicate()
		mask.decompress()
	var heel := HEEL
	var ball := BALL
	if sole.y > sole.x + 0.1:
		heel = clampf(sole.y - 0.015, 0.0, 0.15)
		ball = clampf(-(sole.x + BALL_AT * (sole.y - sole.x)), 0.05, 0.2)
	var dirs: Array[Vector2] = []
	var elbows: Array[Vector3] = []
	for k in 2:
		var d: Vector2 = (sums[k] as Vector2).normalized() if (sums[k] as Vector2).length() > 1e-6 else Vector2.DOWN
		dirs.append(d)
		var e: Vector2 = (pivots[k] as Vector2) + d * UPPER_ARM
		elbows.append(Vector3(e.x, e.y, 0.0))
	var out := ArrayMesh.new()
	var cut := 0
	for s in src.get_surface_count():
		var arrays := src.surface_get_arrays(s)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uv2: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2] if arrays[Mesh.ARRAY_TEX_UV2] != null else PackedVector2Array()
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var n := v.size()
		var bones := PackedInt32Array()
		bones.resize(n * 4)
		var weights := PackedFloat32Array()
		weights.resize(n * 4)
		for i in n:
			var mark := uv2[i].x if i < uv2.size() else 0.0
			var hang := clampf(uv2[i].y, 0.0, 1.0) if i < uv2.size() else 0.0
			var p := v[i]
			if robe and mask != null and mark != 0.0 and absf(mark) < 1.5 and i < uv.size():
				var px := Vector2i(clampi(int(uv[i].x * mask.get_width()), 0, mask.get_width() - 1),
					clampi(int(uv[i].y * mask.get_height()), 0, mask.get_height() - 1))
				if mask.get_pixelv(px).r > 0.5:
					mark = 0.0
					hang = 1.0
			var w := 0.0
			var seg_a := BODY
			var seg_b := BODY
			var share_a := 0.0
			if mark != 0.0 and absf(mark) > 1.5:
				# An arm: upper arm, forearm past the elbow.
				w = clampf(absf(mark) - 2.0, 0.0, 1.0)
				var k := 0 if mark > 0.0 else 1
				var along := (Vector2(p.x, p.y) - (pivots[k] as Vector2)).dot(dirs[k])
				var fore := smoothstep(UPPER_ARM - 0.04, UPPER_ARM + 0.04, along)
				seg_a = UPPER_R if k == 0 else UPPER_L
				seg_b = FORE_R if k == 0 else FORE_L
				share_a = 1.0 - fore
			elif mark != 0.0:
				# A leg: foot under the ankle, shin under the knee, thigh above.
				w = clampf(absf(mark), 0.0, 1.0) * smoothstep(hip + 0.02, hip - 0.1, p.y)
				var left := mark > 0.0
				var foot := 1.0 - smoothstep(ankle - 0.015, ankle + 0.03, p.y)
				var shin := (1.0 - foot) * (1.0 - smoothstep(knee - KNEE_BLEND, knee + KNEE_BLEND, p.y))
				var toe := smoothstep(-ball + 0.015, -ball - 0.015, p.z)
				if foot > 0.0 and toe > 0.0 and foot >= 1.0:
					seg_a = TOE_L if left else TOE_R
					seg_b = FOOT_L if left else FOOT_R
					share_a = toe
				elif foot > 0.0:
					seg_a = FOOT_L if left else FOOT_R
					seg_b = SHIN_L if left else SHIN_R
					share_a = foot
				else:
					seg_a = SHIN_L if left else SHIN_R
					seg_b = THIGH_L if left else THIGH_R
					share_a = shin
			elif p.y < hip + 0.03:
				# The garment below the hips, each side going some way with its thigh.
				w = GARMENT * smoothstep(GARMENT_X.x, GARMENT_X.y, absf(p.x)) * smoothstep(hip + 0.03, hip - GARMENT_Y, p.y) \
					* (1.0 - (1.0 - GARMENT_HEM) * smoothstep(knee, ankle, p.y))
				seg_a = THIGH_L if p.x < 0.0 else THIGH_R
				seg_b = seg_a
				share_a = 1.0
			var k4 := i * 4
			bones[k4] = BODY
			weights[k4] = (1.0 - w) * (1.0 - hang)
			bones[k4 + 1] = BODY_HEM
			weights[k4 + 1] = (1.0 - w) * hang
			bones[k4 + 2] = seg_a
			weights[k4 + 2] = w * share_a
			bones[k4 + 3] = seg_b
			weights[k4 + 3] = w * (1.0 - share_a)
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
		# Each vertex's leg: 1 the left, -1 the right, 0 neither (marked well enough to tell).
		var side := PackedInt32Array()
		side.resize(n)
		for i in mini(n, uv2.size()):
			var mk := uv2[i].x
			if mk != 0.0 and absf(mk) < 1.5 and absf(mk) > 0.25:
				side[i] = 1 if mk > 0.0 else -1
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if idx.is_empty():
			idx.resize(n)
			for i in n:
				idx[i] = i
		var kept := PackedInt32Array()
		for t in idx.size() / 3:
			var a := side[idx[t * 3]]
			var b := side[idx[t * 3 + 1]]
			var c := side[idx[t * 3 + 2]]
			if (a > 0 or b > 0 or c > 0) and (a < 0 or b < 0 or c < 0):
				cut += 1
				continue
			kept.append(idx[t * 3])
			kept.append(idx[t * 3 + 1])
			kept.append(idx[t * 3 + 2])
		arrays[Mesh.ARRAY_INDEX] = kept
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_material(s, src.surface_get_material(s))
	out.set_meta("elbows", elbows)
	out.set_meta("foot", {"heel": heel, "ball": ball})
	out.set_meta("cut", cut)
	return out


static func skeleton() -> Skeleton3D:
	var sk := Skeleton3D.new()
	for b: String in NAMES:
		sk.add_bone(b)
	return sk


static func skin() -> Skin:
	var s := Skin.new()
	for i in BONES:
		s.add_bind(i, Transform3D.IDENTITY)
	return s


## sk posed at phase ph (cycles; the left heel down at 0), pace (0 standing, 1 walking) and stride (the figure's), as
## the crowd steps a person whose phase runs by its cycle (garden_crowd.gd). joints: hip_y, ankle_y, shoulder_y;
## arm_lower (radians) and shoulder_x as the shader's uniforms; t: seconds, for the standing sway; elbows: the
## skinned mesh's meta. cloth: the person's robe (cloth_state()), stepped by dt with the person placed at xf;
## frame: a count the caller steps once a frame, by which the robe knows it has been away.
static func pose(sk: Skeleton3D, ph: float, pace: float, stride: float, joints: Dictionary, arm_lower: float,
		shoulder_x: Vector2, t: float, elbows: Array, cloth: Dictionary, xf: Transform3D, dt: float, frame: int) -> void:
	var m := transforms(ph, pace, stride, joints, arm_lower, shoulder_x, t, elbows, cloth)
	for i in m.size():
		sk.set_bone_pose(i, m[i])
	cloth_step(cloth, xf * (m[BODY] * Vector3(0.0, float(joints.hip_y), 0.0)), xf.basis, pace, dt, frame)


## A robe at rest.
static func cloth_state() -> Dictionary:
	return {"frame": -2, "p": Vector3.ZERO, "v": Vector3.ZERO, "a": Vector3.ZERO, "yaw": 0.0, "yv": 0.0,
		"q": Vector2.ZERO, "w": Vector2.ZERO, "tw": 0.0, "tv": 0.0}


## The robe c moved on by dt, its waist now at `waist` (world) and its wearer turned by basis: a pendulum whose
## pivot moves, theta'' = -(g + a_y) / L theta - a_h / L, damped; q.x about +x (+ the hem forward, at -z), q.y about
## +z (+ the hem to +x); and the twist, behind the body's turning. Away a frame or more, it starts again at rest.
static func cloth_step(c: Dictionary, waist: Vector3, basis: Basis, pace: float, dt: float, frame: int) -> void:
	var b := basis.orthonormalized()
	var yaw := atan2(b.z.x, b.z.z)
	if int(c.frame) != frame - 1 or dt <= 0.0:
		var fresh := int(c.frame) < frame - 1
		c.frame = frame
		c.p = waist
		c.v = Vector3.ZERO
		c.a = Vector3.ZERO
		c.yaw = yaw
		c.yv = 0.0
		if fresh:
			c.q = Vector2(-TRAIL * clampf(pace, 0.0, 1.0), 0.0)
			c.w = Vector2.ZERO
			c.tw = 0.0
			c.tv = 0.0
		return
	c.frame = frame
	var v := (waist - (c.p as Vector3)) / dt
	var acc := ((v - (c.v as Vector3)) / dt).limit_length(12.0)
	c.a = (c.a as Vector3).lerp(acc, 1.0 - exp(-dt * 30.0))  # a frame's noise out of it, 33 ms
	c.p = waist
	c.v = v
	var yv := angle_difference(float(c.yaw), yaw) / dt
	var ya := clampf((yv - float(c.yv)) / dt, -30.0, 30.0)
	c.yaw = yaw
	c.yv = yv
	var la := b.transposed() * (c.a as Vector3)
	var w0 := sqrt(maxf(9.81 + la.y, 3.0) / CLOTH_L)
	var force := Vector2(la.z, -la.x) * CLOTH_COUPLE / CLOTH_L
	var rest := Vector2(-TRAIL * clampf(pace, 0.0, 1.0), 0.0)
	var wt := TAU * TWIST_HZ
	var q: Vector2 = c.q
	var w: Vector2 = c.w
	var tw := float(c.tw)
	var tv := float(c.tv)
	var n := ceili(dt / 0.006)
	var h := dt / n
	for i in n:
		w += (-w0 * w0 * (q - rest) - 2.0 * CLOTH_DAMP * w0 * w + force) * h
		q += w * h
		tv += (-wt * wt * tw - 2.0 * CLOTH_DAMP * wt * tv - ya) * h
		tw += tv * h
	if q.length() > CLOTH_MAX:
		q = q.normalized() * CLOTH_MAX
		w *= 0.5
	c.q = q
	c.w = w
	c.tw = clampf(tw, -TWIST_MAX, TWIST_MAX)
	c.tv = tv


## The cycle's length: how far a person walks in one (unscaled), as the crowd steps its phase.
static func cycle(stride: float, pace: float, joints: Dictionary) -> float:
	var leg := float(joints.hip_y) - float(joints.ankle_y)
	return 4.0 * leg * sin(LEG_SWING * stride) * sqrt(clampf(pace, 0.0, 1.0))


## Where a foot is at its own phase u (0 the heel landing), in the walker's frame (z forward negative, y up): the
## ankle, the foot's pitch (+ the toes up), what touches the ground ("heel", "sole", "ball", or "" in the air) and
## where that is.
static func foot(u: float, c: float, a: float, ankle_y: float, heel := HEEL, ball := BALL) -> Dictionary:
	var z0 := -LAND * c + c * u  # the ankle over the sole, as the ground goes back under the walker
	var heel_rest := Vector2(heel, -ankle_y)  # (z, y) from the ankle
	var ball_rest := Vector2(-ball, -ankle_y)
	if u < DUTY:
		var g := 0.0
		var on := "sole"
		if u < FLAT.x:
			g = STRIKE * a * (1.0 - smoothstep(0.0, FLAT.x, u))
			on = "heel"
		elif u > FLAT.y:
			# Up on the ball; once the other foot is down, on up to LIFT_MAX as it comes off.
			g = -a * (PUSH * smoothstep(FLAT.y, DUTY, u) + (LIFT_MAX - PUSH) * smoothstep(0.5, DUTY, u))
			on = "ball"
		var ground := Vector2(z0, ankle_y)  # the ankle, the foot flat
		var pivot := Vector2.ZERO
		if on == "heel":
			pivot = ground + heel_rest
		elif on == "ball":
			pivot = ground + ball_rest
		var at := ground
		if on != "sole":
			at = pivot + _turn(ground - pivot, g)
		return {"ankle": at, "pitch": g, "on": on, "ground": pivot if on != "sole" else ground + Vector2(0.0, -ankle_y), "u": u}
	# In the air: from where it came off to where it lands, lifted.
	var s := (u - DUTY) / (1.0 - DUTY)
	var off := foot(DUTY - 1e-4, c, a, ankle_y, heel, ball)
	var down := foot(0.0, c, a, ankle_y, heel, ball)
	var from: Vector2 = off.ankle
	var to: Vector2 = down.ankle
	var e := smoothstep(0.0, 1.0, s)
	var at := Vector2(lerpf(from.x, to.x, e), lerpf(from.y, to.y, s) + LIFT * a * sin(PI * s))
	var g := lerpf(-PUSH * a, STRIKE * a, smoothstep(0.0, 0.8, s))
	return {"ankle": at, "pitch": g, "on": "", "ground": Vector2.INF, "u": u}


## (z, y) turned by g about +x (+ the toes, ahead at -z, up).
static func _turn(v: Vector2, g: float) -> Vector2:
	return Vector2(v.y * sin(g) + v.x * cos(g), v.y * cos(g) - v.x * sin(g))


## The gait at phase ph: the hips' height, and each leg's (left, right) foot, knee and the angles of thigh, shin
## (from straight down, + forward) and foot.
static func gait(ph: float, pace: float, stride: float, joints: Dictionary) -> Dictionary:
	var hip := float(joints.hip_y)
	var ankle := float(joints.ankle_y)
	var knee := ankle + KNEE * (hip - ankle)
	var l1 := hip - knee
	var l2 := knee - ankle
	var a := sqrt(clampf(pace, 0.0, 1.0))
	var c := cycle(stride, pace, joints)
	var heel := float(joints.get("heel", HEEL))
	var ball := float(joints.get("ball", BALL))
	var h := _hips(ph, c, a, joints)
	var reach := (l1 + l2) * 0.9995
	var legs := []
	for side in 2:
		var u := fposmod(ph + 0.5 * side, 1.0)
		var f := foot(u, c, a, ankle, heel, ball)
		var at: Vector2 = f.ankle
		var pitch := float(f.pitch)
		if str(f.on) == "":
			# In the air: from where it came off, its heel as far up as it had to be then, to where it lands.
			var s := (u - DUTY) / (1.0 - DUTY)
			var off := foot(DUTY - 1e-4, c, a, ankle, heel, ball)
			var made := _stand(off, _hips(ph - u + DUTY - 1e-4, c, a, joints), ankle, ball, l1, l2)
			var from: Vector2 = made[0]
			var to: Vector2 = foot(0.0, c, a, ankle, heel, ball).ankle
			# Fore and aft, still on the ground as it lands: going back under the walker at the stance's rate by then (a
			# cubic Hermite from rest under the walker, as it came off, to that). Eased from rest to rest under the
			# walker, the heel came down at the walking speed, 20 to 30 mm a frame over its last frames
			# (artpass/gardens/people/crowd_slip.gd). Going back as it came off too, the ankle went out of the hips'
			# reach, the knee straight, 3.7 mm off the shin (gait_check.gd joints).
			var m := c * (1.0 - DUTY)
			var s2 := s * s
			var s3 := s2 * s
			var x := (2.0 * s3 - 3.0 * s2 + 1.0) * from.x + (3.0 * s2 - 2.0 * s3) * to.x + (s3 - s2) * m
			var up := LIFT * a * sin(PI * clampf(s / LIFT_END, 0.0, 1.0)) + CLEAR * a * sin(PI * s)
			at = Vector2(x, lerpf(from.y, to.y, smoothstep(0.0, LIFT_END, s)) + up)
			if (at - Vector2(0.0, h)).length() > reach:
				at = Vector2(0.0, h) + (at - Vector2(0.0, h)).normalized() * reach
			pitch = lerpf(float(made[1]), STRIKE * a, smoothstep(0.0, 0.8, s))
		else:
			var made := _stand(f, h, ankle, ball, l1, l2)
			at = made[0]
			pitch = made[1]
			f.on = made[2]
		var d := Vector2(at.x, at.y - h)
		var dl := maxf(d.length(), absf(l1 - l2) + 1e-4)
		var phi := atan2(-d.x, -d.y)
		var a1 := acos(clampf((l1 * l1 + dl * dl - l2 * l2) / (2.0 * l1 * dl), -1.0, 1.0))
		var a2 := acos(clampf((l2 * l2 + dl * dl - l1 * l1) / (2.0 * l2 * dl), -1.0, 1.0))
		var thigh := phi + a1
		var kn := Vector2(-sin(thigh) * l1, h - cos(thigh) * l1)
		legs.append({"ankle": at, "knee": kn, "thigh": thigh, "shin": phi - a2, "pitch": pitch, "on": f.on,
			"ground": f.ground, "flex": a1 + a2})
	return {"hip": h, "legs": legs, "cycle": c}


## The hips' height at phase ph: as high as the feet bearing the weight reach, the knee giving a little (a foot
## from landing until the other lands), and coming down through the other foot's swing to where it will land.
static func _hips(ph: float, c: float, a: float, joints: Dictionary) -> float:
	var hip := float(joints.hip_y)
	var ankle := float(joints.ankle_y)
	var leg := hip - ankle
	var heel := float(joints.get("heel", HEEL))
	var ball := float(joints.get("ball", BALL))
	var h := hip - SETTLE.x * a
	for side in 2:
		var u := fposmod(ph + 0.5 * side, 1.0)
		var f := foot(u, c, a, ankle, heel, ball)
		if str(f.on) != "":
			if u < 0.5:
				var at: Vector2 = f.ankle
				var give := SETTLE.x + SETTLE.y * sin(PI * clampf(u / 0.25, 0.0, 1.0))
				h = minf(h, at.y + sqrt(maxf(leg * leg - at.x * at.x, 0.0)) - give * a)
		else:
			var land: Vector2 = foot(0.0, c, a, ankle, heel, ball).ankle
			var s := (u - DUTY) / (1.0 - DUTY)
			h = minf(h, land.y + sqrt(maxf(leg * leg - land.x * land.x, 0.0)) - SETTLE.x * a + FALL * (1.0 - s) * (1.0 - s))
	return h


## A foot on the ground at f, the hips at h: out of reach (behind, once the other is down, its knee kept bent by
## PRESWING), the ankle drawn in, the foot leaving the ground a little early. [ankle, pitch, on]
static func _stand(f: Dictionary, h: float, ankle: float, ball: float, l1: float, l2: float) -> Array:
	var reach := (l1 + l2) * 0.9995
	if str(f.on) == "ball" and float(f.u) >= 0.5:
		var bend := PRESWING * smoothstep(0.5, DUTY, float(f.u))
		reach = minf(reach, sqrt(l1 * l1 + l2 * l2 + 2.0 * l1 * l2 * cos(bend)))
	var at: Vector2 = f.ankle
	var pitch := float(f.pitch)
	var hips := Vector2(0.0, h)
	var on := str(f.on)
	if (at - hips).length() > reach:
		at = hips + (at - hips).normalized() * reach
		on = ""
	return [at, pitch, on]


## The fourteen poses (pose()), for sk or for a test.
static func transforms(ph: float, pace: float, stride: float, joints: Dictionary, arm_lower: float,
		shoulder_x: Vector2, t: float, elbows: Array, cloth: Dictionary) -> Array[Transform3D]:
	var hip := float(joints.hip_y)
	var ankle := float(joints.ankle_y)
	var knee := ankle + KNEE * (hip - ankle)
	var shoulder := float(joints.shoulder_y)
	var p := clampf(pace, 0.0, 1.0)
	var a := sqrt(p)
	var g := gait(ph, pace, stride, joints)
	var h := float(g.hip)
	var s := sin(ph * TAU)
	# The lean onto the planted foot and the standing's shift of weight, a turn about the feet, by that much at 1.6 m.
	var lean := (LEAN * a * s - (1.0 - p) * SWAY * sin(t * 0.6 + ph * 40.0)) / 1.6
	var root := Transform3D(Basis(Vector3.BACK, lean), Vector3(0.0, h - hip, 0.0))
	var out: Array[Transform3D] = []
	out.resize(BONES)
	out[BODY] = root
	# The robe below the waist, as its pendulum has swung and twisted.
	var q: Vector2 = cloth.get("q", Vector2.ZERO)
	var hb := Basis(Vector3.UP, float(cloth.get("tw", 0.0))) * Basis(Vector3.RIGHT, q.x) * Basis(Vector3.BACK, q.y)
	var waist := Vector3(0.0, hip + WAIST, 0.0)
	out[BODY_HEM] = root * Transform3D(hb, waist - hb * waist)
	for k in 2:
		var leg: Dictionary = (g.legs as Array)[k]
		var left := k == 0
		var at: Vector2 = leg.ankle
		var kn: Vector2 = leg.knee
		out[THIGH_L if left else THIGH_R] = _about(float(leg.thigh), Vector3(0.0, hip, 0.0), Vector3(0.0, h, 0.0))
		out[SHIN_L if left else SHIN_R] = _about(float(leg.shin), Vector3(0.0, knee, 0.0), Vector3(0.0, kn.y, kn.x))
		var ft := _about(float(leg.pitch), Vector3(0.0, ankle, 0.0), Vector3(0.0, at.y, at.x))
		out[FOOT_L if left else FOOT_R] = ft
		# The toes, bent back about the ball as far as the heel is up: flat.
		var ball_rest := Vector3(0.0, 0.0, -float(joints.get("ball", BALL)))
		out[TOE_L if left else TOE_R] = ft * _about(-minf(float(leg.pitch), 0.0), ball_rest, ball_rest)
	for k in 2:
		# The arm: + the right, forward as the left heel lands; first lowered in the body's plane about its pivot.
		var side := 1.0 if k == 0 else -1.0
		var pivot := Vector3(shoulder_x.x if k == 0 else -shoulder_x.y, shoulder, 0.0)
		var lower := Basis(Vector3.BACK, -side * arm_lower)
		var lowered := Transform3D(lower, pivot - lower * pivot)
		var sw := side * ARM_SWING * a * cos(ph * TAU)
		var swing := Basis(Vector3.RIGHT, sw)
		var at := Vector3(0.0, shoulder, 0.0)
		var swung := Transform3D(swing, at - swing * at)
		var rest: Vector3 = elbows[k] if k < elbows.size() else pivot + Vector3(0.0, -UPPER_ARM, 0.0)
		var elbow := lowered * rest
		var bend := Basis(Vector3.RIGHT, (ELBOW + ELBOW_SWING * maxf(sw, 0.0) / ARM_SWING) * a)
		out[UPPER_R if k == 0 else UPPER_L] = root * swung * lowered
		out[FORE_R if k == 0 else FORE_L] = root * swung * Transform3D(bend, elbow - bend * elbow) * lowered
	return out


## A turn by angle about +x taking the point `from` (at rest) to `to`.
static func _about(angle: float, from: Vector3, to: Vector3) -> Transform3D:
	var b := Basis(Vector3.RIGHT, angle)
	return Transform3D(b, to - b * from)
