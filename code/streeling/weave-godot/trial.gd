extends SceneTree

const MM_TO_M = 0.001
const EPSILON = 0.0000001
var report = {"status": "failed", "checks": [], "crossings": []}
var report_path = ""

func _init():
    call_deferred("_run")

func _check(name: String, passed: bool, detail):
    report.checks.append({"name": name, "passed": passed, "detail": detail})

func _finish():
    report.status = "passed"
    for item in report.checks:
        if not item.passed:
            report.status = "failed"
    var file = FileAccess.open(report_path, FileAccess.WRITE)
    if file == null:
        printerr("Cannot write Godot report: ", report_path)
        quit(1)
        return
    file.store_string(JSON.stringify(report, "  ") + "\n")
    file.close()
    print(JSON.stringify({"status": report.status, "report": report_path}))
    quit(0 if report.status == "passed" else 1)

func _run():
    var args = OS.get_cmdline_user_args()
    if args.size() != 6 or args[0] != "--manifest" or args[2] != "--report" or args[4] != "--manifest-sha256":
        printerr("Expected --manifest PATH --report PATH --manifest-sha256 HASH")
        quit(2)
        return
    report_path = args[3]
    report.godot_version = Engine.get_version_info()
    report.source_manifest_sha256 = FileAccess.get_sha256(args[1])
    _check("source_manifest_sha256", report.source_manifest_sha256 == args[5], "Actual manifest bytes must match the controller digest")
    var version = Engine.get_version_info()
    _check("godot_version", version.major == 4 and version.minor == 6 and version.patch == 1, version.string)
    var manifest = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
    if not manifest is Dictionary or not manifest.get("crossings") is Array:
        _check("manifest_input", false, "Invalid manifest")
        _finish()
        return
    _check("manifest_input", manifest.crossings.size() == 36 and manifest.variant == "global-parity", "36 admitted crossings")
    for item in report.checks:
        if not item.passed:
            _finish()
            return

    var scene = Node3D.new()
    scene.name = "Weave"
    root.add_child(scene)
    scene.set_meta("source_manifest_sha256", report.source_manifest_sha256)
    var meshes = {}
    var shapes = {}
    var materials = {}
    for strand in ["warp", "weft"]:
        var dimensions = Vector3(2, 2, 4) if strand == "warp" else Vector3(4, 2, 2)
        var mesh = BoxMesh.new()
        mesh.size = dimensions * MM_TO_M
        meshes[strand] = mesh
        var shape = BoxShape3D.new()
        shape.size = dimensions * MM_TO_M
        shapes[strand] = shape
        var material = StandardMaterial3D.new()
        material.albedo_color = Color("406fa0") if strand == "warp" else Color("d8a34d")
        materials[strand] = material
    for crossing in manifest.crossings:
        var parent = Node3D.new()
        parent.name = crossing.id
        parent.position = Vector3(crossing.x_mm, 0, crossing.z_mm) * MM_TO_M
        parent.set_meta("crossing_id", crossing.id)
        parent.set_meta("warp_over", crossing.warp_over)
        scene.add_child(parent)
        parent.owner = scene
        for strand in ["warp", "weft"]:
            var upper = crossing.warp_over == (strand == "warp")
            var mesh = MeshInstance3D.new()
            mesh.name = strand
            mesh.mesh = meshes[strand]
            mesh.material_override = materials[strand]
            mesh.position.y = (1.5 if upper else -1.5) * MM_TO_M
            mesh.set_meta("crossing_id", crossing.id)
            mesh.set_meta("strand", strand)
            parent.add_child(mesh)
            mesh.owner = scene
            var body = StaticBody3D.new()
            body.name = "Body"
            body.set_meta("crossing_id", crossing["id"])
            body.set_meta("strand", strand)
            mesh.add_child(body)
            body.owner = scene
            var collider = CollisionShape3D.new()
            collider.name = "Shape"
            collider.shape = shapes[strand]
            body.add_child(collider)
            collider.owner = scene
    var packed = PackedScene.new()
    var pack_error = packed.pack(scene)
    _check("scene_pack", pack_error == OK, pack_error)
    if pack_error != OK:
        scene.free()
        _finish()
        return
    var save_error = ResourceSaver.save(packed, "res://weave.tscn")
    _check("scene_save", save_error == OK, save_error)
    scene.free()
    packed = null
    if save_error != OK:
        _finish()
        return
    var saved = ResourceLoader.load("res://weave.tscn", "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
    _check("scene_load", saved is PackedScene, "Load the saved native scene")
    if not saved is PackedScene:
        _finish()
        return
    var loaded = saved.instantiate()
    root.add_child(loaded)
    await physics_frame
    await physics_frame
    _check("loaded_manifest_binding", loaded.get_meta("source_manifest_sha256", "") == report.source_manifest_sha256, "Root metadata survives serialization")
    var loaded_meshes = loaded.find_children("*", "MeshInstance3D", true, false)
    var bodies = loaded.find_children("*", "StaticBody3D", true, false)
    var colliders = loaded.find_children("*", "CollisionShape3D", true, false)
    report.counts = {"crossings": loaded.get_child_count(), "meshes": loaded_meshes.size(), "static_bodies": bodies.size(), "collision_shapes": colliders.size()}
    _check("loaded_counts", loaded.get_child_count() == 36 and loaded_meshes.size() == 72 and bodies.size() == 72 and colliders.size() == 72, report.counts)
    var mesh_resources = {}
    var shape_resources = {}
    var material_resources = {}
    for mesh in loaded_meshes:
        mesh_resources[mesh.mesh.get_instance_id()] = true
        material_resources[mesh.material_override.get_instance_id()] = true
    for collider in colliders:
        shape_resources[collider.shape.get_instance_id()] = true
    report.resources = {"meshes": mesh_resources.size(), "shapes": shape_resources.size(), "materials": material_resources.size()}
    _check("shared_resources", mesh_resources.size() == 2 and shape_resources.size() == 2 and material_resources.size() == 2, report.resources)
    var matched_rays = 0
    for crossing in manifest.crossings:
        var parent = loaded.get_node_or_null(NodePath(crossing.id))
        if parent == null:
            _check("loaded_crossing", false, crossing.id)
            continue
        var warp = parent.get_node("warp")
        var weft = parent.get_node("weft")
        var upper = warp if crossing.warp_over else weft
        var lower = weft if crossing.warp_over else warp
        var upper_aabb = upper.global_transform * upper.get_aabb()
        var lower_aabb = lower.global_transform * lower.get_aabb()
        var gap = upper_aabb.position.y - lower_aabb.end.y
        # Independent metre expectations deliberately do not use MM_TO_M.
        var expected_centre = Vector3(float(crossing.grid_x) * 0.005, 0, float(crossing.grid_y) * 0.005)
        var metres_ok = parent.global_position.distance_to(expected_centre) < EPSILON
        metres_ok = metres_ok and abs(upper.global_position.y - 0.0015) < EPSILON and abs(lower.global_position.y + 0.0015) < EPSILON
        metres_ok = metres_ok and abs(upper_aabb.size.y - 0.002) < EPSILON and abs(lower_aabb.size.y - 0.002) < EPSILON
        metres_ok = metres_ok and (warp.global_transform * warp.get_aabb()).size.distance_to(Vector3(0.002, 0.002, 0.004)) < EPSILON
        metres_ok = metres_ok and (weft.global_transform * weft.get_aabb()).size.distance_to(Vector3(0.004, 0.002, 0.002)) < EPSILON
        _check("independent_world_metres", metres_ok, crossing.id)
        _check("aabb_clearance", abs(gap - 0.001) < EPSILON, {"id": crossing.id, "gap_metres": gap})
        _check("loaded_metadata", parent.get_meta("crossing_id", "") == crossing.id and parent.get_meta("warp_over", null) == crossing.warp_over and warp.get_meta("strand", "") == "warp" and weft.get_meta("strand", "") == "weft" and warp.get_meta("crossing_id", "") == crossing.id and weft.get_meta("crossing_id", "") == crossing.id, crossing.id)
        var query = PhysicsRayQueryParameters3D.create(expected_centre + Vector3(0, 0.01, 0), expected_centre + Vector3(0, -0.01, 0))
        var hit = loaded.get_world_3d().direct_space_state.intersect_ray(query)
        var expected_strand = "warp" if crossing.warp_over else "weft"
        var hit_id = "" if hit.is_empty() else str(hit.collider.get_meta("crossing_id", ""))
        var hit_strand = "" if hit.is_empty() else str(hit.collider.get_meta("strand", ""))
        _check("ray_crossing_identity", hit_id == crossing.id, {"expected": crossing.id, "actual": hit_id})
        _check("ray_upper_strand", hit_strand == expected_strand, {"id": crossing.id, "expected": expected_strand, "actual": hit_strand})
        if hit_id == crossing.id and hit_strand == expected_strand:
            matched_rays += 1
        report.crossings.append({"id": crossing.id, "warp_over": crossing.warp_over, "world_position_metres": _vector(parent.global_position), "warp_position_metres": _vector(warp.global_position), "weft_position_metres": _vector(weft.global_position), "upper_aabb_metres": _aabb(upper_aabb), "lower_aabb_metres": _aabb(lower_aabb), "gap_metres": gap, "ray": {"crossing_id": hit_id, "strand": hit_strand, "position_metres": [] if hit.is_empty() else _vector(hit.position)}})
    report.matching_ray_identities = matched_rays
    _check("all_ray_identities", matched_rays == 36, matched_rays)
    report.scene_sha256 = FileAccess.get_sha256("res://weave.tscn")
    _finish()

func _vector(value: Vector3):
    return [value.x, value.y, value.z]

func _aabb(value: AABB):
    return {"position": _vector(value.position), "size": _vector(value.size)}
