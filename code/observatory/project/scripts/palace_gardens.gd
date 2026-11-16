extends Node3D
## Two glazed bays in the hall's outer wall, at floor level, and through them the palace gardens of
## Trantor (the author, 2026-10-03: "2 baies vitrées à travers lesquelles on voit les jardins du palais
## de Trantor"). In Prelude to Foundation the Imperial grounds are the one place on Trantor under open
## sky; here the observatory stands at their edge.
##   - The bays: the ground-level shelves of bays 2 and 5, either side of the lift, give way to a
##     stone recess and a window of four lights in bronze, under a fanlight of leaded quarries in
##     colour. The glass reflects the hall (assets/bay_glass.gdshader). observatory.gd built the
##     shelves and the wall and stays version 28's in builds, so this script takes them out where the
##     windows go: the bay's wood mesh loses its ground level's back and boards, the books, lamp strips
##     and crystals there are scaled to nothing, and the outer wall is rebuilt with two openings.
##   - Through them: a terrace with a balustrade and lamps, the parterre five metres below it, box in
##     scrolls, a fountain, a canal, bosquets and cypresses, the palace in a U at the far end, and the
##     domed city round the grounds under the city's glow.
##   - The light: the fanlights throw coloured shafts down into the hall (assets/palace_glow.gdshader,
##     and under Forward+ a spot into the volumetric fog), and the shelf lamp of each bay turns into the
##     garden's cool light.
## Everything outside lights itself (assets/palace_garden.gdshader): no light is added to the scene
## for it, it casts no shadow, and it is drawn only while the camera is in the hall with a bay in view.
## Adaptive quality (scripts/quality.gd) thins it out from level 3.

const GARDEN_SHADER_PATH := "res://assets/palace_garden.gdshader"
const GLOW_SHADER_PATH := "res://assets/palace_glow.gdshader"
const GLASS_SHADER_PATH := "res://assets/bay_glass.gdshader"
const CARD_SHADER_PATH := "res://assets/garden_card.gdshader"
## The palace, painted (Z-Image-Turbo, cut out with BiRefNet: artpass/gardens/NOTES.md) on a card this
## wide, its garden front at PALACE_Z, its foot a metre under the ground. Without the image, the
## palace is built in boxes as before.
const PALACE_TEX_PATH := "res://assets/garden_palace.png"
const PALACE_W := 280.0
const PALACE_Z := 430.0
## Since the author found the card "du carton pâte" and asked for the heart of the Empire, Gothic, high
## tech and science fiction (2026-10-12), the palace is modelled in Blender (artpass/foundation/palace/
## make_palace.py, an original design), its light baked there by Cycles into a lightmap
## (assets/palace_baked.gdshader), its root at PALACE_Z on the ground, its garden front 24 m nearer. The
## water mirrors its front elevation, rendered there too. Without the model, or with --palace=card
## (?palace=card), the card.
const PALACE_GLB_PATH := "res://assets/palace/imperial_palace.glb"
## Off the web, the clock in the palace's rose window (loaded, not preloaded: the web build leaves it out).
const PALACE_CLOCK_SCRIPT_PATH := "res://scripts/palace_clock.gd"
## The clipped hedges' outer leaves, in layers of real geometry over them, off the web (loaded, not preloaded).
const HEDGE_SHELLS_PATH := "res://scripts/hedge_shells.gd"
const PALACE_LIGHT_PATH := "res://assets/palace/palace_light.png"
## In the web build, the lightmap at half the size: 16 MB of video memory there rather than 64.
const PALACE_LIGHT_WEB_PATH := "res://assets/palace/palace_light_web.png"
const PALACE_MIRROR_PATH := "res://assets/palace/palace_mirror.png"
const PALACE_SHADER_PATH := "res://assets/palace_baked.gdshader"
const PALACE_BEAM_SHADER_PATH := "res://assets/palace_beam.gdshader"
## The elevation's extent (make_palace.py's MIRROR_X, MIRROR_Z0, MIRROR_Z1): x from -x to x, y from
## GROUND_Y + y to GROUND_Y + z. The water's reflected rays meet it in the plane z = PALACE_MIRROR_Z,
## between the gate's front (428) and the dome's (472).
const PALACE_MIRROR := Vector3(180.0, -1.0, 189.0)
const PALACE_MIRROR_Z := 450.0
## The model's materials, by name (make_palace.py's MATS, linear): the shader's kind, albedo, emission and
## its energy, and its other parameters.
const PALACE_MATS := {
	"stone": [0, Vector3(0.66, 0.56, 0.42), Vector3.ZERO, 0.0, {"stone_detail": 0.6}],
	"dark": [0, Vector3(0.05, 0.05, 0.06), Vector3.ZERO, 0.0, {}],
	"gold": [0, Vector3(0.85, 0.55, 0.2), Vector3.ZERO, 0.0, {"sheen": 0.6}],
	"dome": [0, Vector3(0.03, 0.06, 0.16), Vector3(0.06, 0.12, 0.35), 0.2, {"gloss": 1.0}],
	"glass": [1, Vector3.ZERO, Vector3(1.0, 0.55, 0.22), 0.9, {}],
	"rose": [2, Vector3.ZERO, Vector3(0.16, 0.34, 1.0), 1.1, {}],
	"cyan": [2, Vector3.ZERO, Vector3(0.25, 0.75, 1.0), 3.0, {}],
	"lamp": [2, Vector3.ZERO, Vector3(1.0, 0.7, 0.4), 4.0, {}],
}
## The city round the grounds, painted in strips (Z-Image-Turbo, the sky found by Lotus depth:
## artpass/gardens/NOTES.md) on a ring CITY_R out, standing on the ground, all the way round (the roof
## sees it all), each CITY_ARC degrees wide; neighbours overlap by their faded ends. Since the author
## asked for a line of buildings like the TV series' (2026-10-04), monolithic slabs of raw concrete,
## nearly windowless, joined high up by bridges and platforms, as the series' Trantor is described
## (artpass/gardens/NOTES.md); before them, glass towers in an amber haze (garden_city_711 to 716, now in
## artpass/gardens/retired-city), which read as Manhattan rather than Trantor, and before those domes
## (garden_city_402 to 406, there too), which filled a
## strip's lower half and at 40 degrees a strip stood 5 degrees high, hidden by the bosquets
## (artpass/bays/art1-fwd). A strip is a quarter as high as it is wide: at 70 degrees, the towers rise
## up to about 17. One every 60 degrees from CITY_A0: they overlap by 10, their ends fading over 8 (an
## overlap of 4 left a seam, art2-fwd), and one overlap falls behind the palace, which hides it.
## Without them, the city is built in domes and towers as before.
## Since the author asked for Trantor at night, blue and cyan, in towers and great round structures
## (2026-10-12, artpass/foundation/NOTES.md), the city is modelled instead (scripts/night_city.gd): the
## strips come back with --city=strips (?city=strips), or without that script.
const NIGHT_CITY_PATH := "res://scripts/night_city.gd"
## The library wing off bay 10 (scripts/library_wing.gd, made by extra_views.gd): its bay's shelves and
## wall are cut here as the glazed bays' are, and the walking body and the riders go round it through it.
const WING_SCRIPT_PATH := "res://scripts/library_wing.gd"
const CITY_TEX_PATHS := ["res://assets/garden_city_731.png", "res://assets/garden_city_733.png",
	"res://assets/garden_city_738.png", "res://assets/garden_city_734.png", "res://assets/garden_city_735.png",
	"res://assets/garden_city_737.png"]
## Painted trees (assets/garden_impostor.gdshader): cypresses and round-crowned limes cut out of
## Z-Image-Turbo images (artpass/gardens/NOTES.md), four of each in an atlas, standing as cards that
## turn to the camera and sway. The cells' shares of their trees: a cypress fills 0.99 of its cell's
## height, a lime 0.977. Without the atlases, the trees are round meshes as before.
const IMPOSTOR_SHADER_PATH := "res://assets/garden_impostor.gdshader"
const CYPRESS_TEX_PATH := "res://assets/garden_cypress.png"
const TREES_TEX_PATH := "res://assets/garden_trees.png"
## Since the author found them "vraiment pas terrible" and asked for Blender and ComfyUI (2026-10-04), the
## trees and the clipped greenery are modelled (artpass/gardens/veg/, NOTES.md "Hedges and trees"):
##   - trees in 3D (artpass/gardens/blender/tree_kit.py): a trunk and branches in tubes under a crown of
##     leaf cards, sprigs drawn by Z-Image-Turbo and cut out by BiRefNet, each kind in variants: limes for
##     the bosquets, the avenues and the woods, pears in the orchard, cypresses, and the terrace's orange
##     trees. Near the eye (VEG_NEAR_R) the meshes, in chunks VEG_CHUNK square whose visibility range
##     drops them further off; out from there each tree's own views, eight round it, rendered by Cycles
##     and lit by the game from their normals (assets/garden_impostor.gdshader, views 8). The woods, out
##     past VEG_ZONE, only ever as views.
##   - the hedges: boxes as before, textured with a clipped box surface (a seamless Z-Image-Turbo tile and
##     its normal map, triplanar), fringed with sprays near the eye (hedge_kit.py); the parterre's yews
##     clipped cones.
## All drawn by assets/garden_plant.gdshader, which lights them as the gardens light themselves. Without
## the kit, the painted trees and plain boxes as before.
const PLANT_SHADER_PATH := "res://assets/garden_plant.gdshader"
const VEG_TREE_PATH := "res://assets/garden_tree_%s%d.glb"
const VEG_KIT_PATH := "res://assets/garden_%s.glb"
const VEG_IMP_PATH := "res://assets/garden_imp_%s%s.png"
const VEG_LEAVES_PATH := "res://assets/garden_leaves_%s.png"
const VEG_BARK_PATH := "res://assets/garden_bark.png"
const VEG_HEDGE_PATH := "res://assets/garden_hedge_box%s.png"
## Each kind: its variants' heights (m, artpass/gardens/veg/trees/tree_kit.json), the leaves' atlas, the
## views' frame (span, m, and width over height), the leaves' tint (linear: the sprigs were drawn in
## daylight), the sway at the top (m).
const VEG_KINDS := {
	"linden": {"tops": [13.52, 14.6, 14.06], "leaves": "linden", "span": 15.18, "aspect": 1.0, "tint": 0.5, "sway": 0.15},
	"pear": {"tops": [6.4, 5.73, 6.68], "leaves": "pear", "span": 6.95, "aspect": 1.0, "tint": 0.5, "sway": 0.12},
	"cypress": {"tops": [12.29, 12.46, 12.54], "leaves": "cypress", "span": 13.04, "aspect": 0.25, "tint": 0.75, "sway": 0.25},
	"orange": {"tops": [3.07, 2.85], "leaves": "pear", "span": 0.0, "aspect": 0.0, "tint": 0.55, "sway": 0.04},
}
## Out to here the meshes, by quality level (scripts/quality.gd, 0 to 5); 0: the views alone.
const VEG_NEAR_R := [70.0, 70.0, 45.0, 0.0, 0.0, 0.0]
const VEG_BAND := 8.0
const VEG_CHUNK := 64.0
## The sprays fringing the hedges and the yews: drawn out to FRINGE_R from the eye, in chunks FRINGE_CHUNK square.
## Through the telescope or the monocle (view_fit.gd zoom), as far as the screen shows them as near, up to
## FRINGE_ZOOM_MAX times: at power 100 from the terrace, 150 m off, none was drawn, and the hedges' edges were
## a box's (the author, 2026-10-16: « Les haies ont l'air du papier peint »). The field narrows as the reach
## grows, so that about as many are drawn.
const FRINGE_R := 60.0
const FRINGE_CHUNK := 32.0
const FRINGE_ZOOM_MAX := 8.0
const VEG_ZONE := 470.0
## The views' foot: this share of their frame up from its bottom (tree_kit.py).
const VEG_FOOT_V := 0.0198
## The parterre modelled for the Versailles pass (artpass/foundation/gardens/NOTES.md; the author,
## 2026-10-13: « Je veux des jardins aussi beaux et réalistes que les jardins de Versailles »): an original
## broderie of clipped box in each compartment, the beds round them edged in box with clipped yews (Blender,
## make_parterre.py, their occlusion baked into the vertex colour), and the ground under them from generated
## tiles: the walks' gravel, the broderie's crushed brick, the lawns, the ground darkened round the box
## (PARTERRE_AO_PATH). The places come from scripts/parterre_layout.gd. Without them, the shader's scrolls,
## the box edging and the yews as before.
const PARTERRE_GLB_PATH := "res://assets/garden_parterre.glb"
## Off the web, the same box from make_parterre.py --detail=rtx when it is there: a section every 12 cm, each plant
## fuller or thinner than the next, the shears' unevenness at three scales (the author, 2026-10-16, from the
## terrace: « la vue de loin est pas terrible »). The web keeps the lighter one.
const PARTERRE_RTX_GLB_PATH := "res://assets/garden_parterre_rtx.glb"
const PARTERRE_AO_PATH := "res://assets/garden_parterre_ao.png"
const GROUND_TEX_PATH := "res://assets/garden_ground_%s.png"
const PARTERRE_LAYOUT := preload("res://scripts/parterre_layout.gd")
## The round basin modelled with it (artpass/foundation/gardens/make_basin.py): a moulded coping, a fountain
## of two vasques with gilt rims, veils of water falling from them, a jet and six smaller ones round it.
## Without it, the flat rim and the crossed sheets as before.
const BASIN_GLB_PATH := "res://assets/garden_basin.glb"
## The Grand Canal's fountain show: jets that sway, cross and burst in turn, in colours, mirrored in the canal.
const SHOW_SCRIPT_PATH := "res://scripts/fountain_show.gd"
## The terrace's stone in detail (assets/palace_garden.gdshader, stone_detail): generated photographs of
## travertine and of limestone paving, as detail maps. Without them, plain stone as before.
const KIT_PATH := "res://assets/garden_%s.obj"
## The finer baluster, off the web ("" and "_low"; artpass/gardens/blender/baluster_fine.py).
const FINE_BALUSTER_PATH := "res://assets/garden_baluster_fine%s.obj"
const STONE_TEX_PATH := "res://assets/garden_stone.png"
const PAVING_TEX_PATH := "res://assets/garden_paving.png"
const CITY_R := 1600.0
const CITY_ARC := 70.0
const CITY_A0 := 25.0
const BAYS := [2, 5]          # either side of the lift's bay (3) and its neighbour, mirrored on the start view's axis
const OPEN_W := 4.4           # m: the glazed opening
const SILL := 0.15
const HEAD := 5.15            # the gallery walkway's underside is at 5.85
const TRANSOM := 4.0          # the fanlight above it
const SCREEN_Z := 0.24        # the recess's face, flush with the back of the shelves' sides
const OUT_Z := -0.45          # through the outer wall
const GLASS_Z := -0.15
## Walking out (the author, 2026-10-05: "je veux pouvoir sortir dehors a pieds du rez de chausee"): each
## bay's lights below the transom are a pair of French doors, which swing out as a visitor comes near.
## The hall's walking body goes on into the recess and through them (walk_physics.gd: bay_walk, then
## bay_out past the glass), where the gardens' walk on foot takes over (segway.gd walk_out), the scooter
## parked on the terrace; back in the same way (bay_in). Ported into the prototype on 2026-10-12 at the
## author's "je veux une porte dans l'observatoire" (artpass/agent/NOTES.md, pass 5).
const DOOR_SWING := 0.5 * PI    # each leaf's, outwards
const DOOR_SPEED := 2.6         # rad/s: open in about 0.6 s
## They open for a visitor within DOOR_NEAR of the opening's foot who looks towards them (within about 45
## degrees), and within DOOR_BY whatever the view. Opening at 5 m whatever the view, they opened for a
## reader at the next bay's books nearest the doorway, 3.99 m from it and facing the shelf; nearer than
## 3.3 m an open leaf (2.1 m wide) could close on the visitor (pass 5, artpass/gardens/walkout).
const DOOR_NEAR := 5.0
const DOOR_BY := 3.3
const DOOR_LOOK := 0.7          # the cosine of the angle between the view and the way to the foot
const DOOR_HIGH := 3.0          # m: an eye higher above the floor (a gallery's) leaves them shut
const DOOR_PASS := 1.2          # rad: open this far, they let a visitor through
const DOOR_GAP := 0.1           # m: the frame's stile either side, which stays where it is
const TERRACE_R := 24.0
## The parterre's level. At -5 the balustrade hid the parterre and the basin, and the gardens showed
## from the bays as a strip a few pixels high under the palace (artpass/bays/art3-fwd/canal_b5).
const GROUND_Y := -10.0
const SEED := 20261004
## The grounds beyond the parterre, since the author asked for great gardens as in the TV series
## (2026-10-04): a hedge maze whose path to its temple is lit, an orchard with rose beds, a goose foot
## of avenues fanning out from the basin to the horizon, lamps all along them, and woods out to the
## city, clear round the palace. Rectangles are (x, z, width, depth), in metres.
const MAZE_RECT := Rect2(-196.0, 36.0, 112.0, 96.0)
const MAZE_CELL := 4.0
const ORCHARD_RECT := Rect2(84.0, 36.0, 112.0, 96.0)
const AVENUE_FROM := Vector2(0.0, 95.0)    # the basin's middle, (x, z)
const AVENUES := [35.0, 60.0]              # degrees off the garden's axis, either side
const AVENUE_LEN := 1250.0
const AVENUE_HALF := 9.0                   # from the middle of an avenue to its rows of trees
## From the hall's middle. To 1250 m, an empty band of plain stood between the woods and the city's
## strips at 1600 m, seen from above (artpass/bays/grounds2-fwd/air).
const WOODS_R := Vector2(380.0, 1560.0)
const PALACE_CLEAR := Rect2(-190.0, 330.0, 380.0, 430.0)
## A ride in the gardens (scripts/segway.gd, the author: "on doit pouvoir se balader dans les jardins en
## Segway", 2026-10-04): a ramp down from the terrace to the parterre on the garden's axis, 11 m wide
## between its parapets, a slope of 1 in 4 (a self-balancing scooter climbs that), through a gap in
## the balustrade; and, for the rider, the ground's height and the solids, found in cells SOLID_CELL
## square.
const RAMP_HALF := 5.5
const RAMP_Z0 := TERRACE_R + 0.6
const RAMP_Z1 := TERRACE_R + 40.6
const SOLID_CELL := 8.0
const SEGWAY_SCRIPT_PATH := "res://scripts/segway.gd"
const CROWD_SCRIPT_PATH := "res://scripts/garden_crowd.gd"
const CAPITOLE_SCRIPT_PATH := "res://scripts/capitole_square.gd"
const CAPITOLE_GLB_PATH := "res://assets/capitole/capitole.glb"
const CAPITOLE_AT := 300.0   # metres from the basin along the avenue 60 degrees west to the square's street
const GRAND_SCRIPT_PATH := "res://scripts/garden_grand.gd"
## The lamps modelled (artpass/gardens/lamps/make_lamp.py; the author, 2026-10-15: « les lampadaires sont
## pourris!! »): a fluted iron post under a six-sided lantern, in place of a box under a globe, off the web.
## Its glass's middle stands LAMP_GLASS_Y over its foot; the glass's mesh is LAMP_GLASS_SCALE times its size,
## so that an instance scaled by 1 / LAMP_GLASS_SCALE has the old globes' scale, which their glow's min_angle
## and the path tracer's light read (set_rt_lit).
const LAMP_KIT_PATH := "res://assets/garden_lamp.glb"
const LAMP_GLASS_Y := 3.19
const LAMP_GLASS_SCALE := 2.5
## How far from the hall's middle a rider goes: the maze, the orchard, the parterre to the canal's end
## and the first 300 m of the avenues, to the woods' edge. Further, the palace and the city, both
## painted cards, would show what they are.
const RIDE_R := 400.0
## The hall's outside over the terrace (_build_facade): stone laid on the wall's face, its plinth and
## pilasters standing this far out of it.
const FACADE_SKIN := 0.2
const FACADE_OUT := 0.45
## Colours of the shafts through the fanlights, one per bay.
const RAY_COLOURS := [Color(1.0, 0.68, 0.38), Color(0.42, 0.78, 0.86)]
## [eye, target, vertical fov]: at bay 2's glass, looking out and a little down over the terrace to
## the parterre and the palace. --preset=gardens (?preset=gardens) starts there; --no-gardens
## (?gardens=0) leaves the hall as it was, for comparisons.
const VIEW := [Vector3(8.6, 1.7, 12.9), Vector3(30.0, -2.0, 60.0), 70.0]

var enabled := true
## The modelled night city (NIGHT_CITY_PATH) rather than the painted strips. Set before the node enters
## the tree; --city=strips (?city=strips) turns it off.
var night_city := true
## The modelled palace (PALACE_GLB_PATH) rather than the card; --palace=card (?palace=card) turns it off.
var palace_model := true
## The modelled parterre (PARTERRE_GLB_PATH: box in broderie, clipped yews, the ground from tiles) rather
## than the scrolls the ground's shader drew; --parterre=drawn (?parterre=drawn) turns it off.
var parterre_kit := true
## The canal's fountain show (SHOW_SCRIPT_PATH); --show=off (?show=off) turns it off.
var fountain_show := true
## The Place du Capitole at the end of the avenue 60 degrees west (CAPITOLE_SCRIPT_PATH), off the web;
## --capitole=off turns it off.
var capitole := true
var stats := {"bays": 0, "books_hidden": 0, "strips_hidden": 0, "crystals_hidden": 0, "wood_tris_cut": 0,
	"lamps_turned": 0, "garden_meshes": 0, "garden_instances": 0, "shown_frames": 0, "hidden_frames": 0}
var garden_visible := false
## Shows the garden whatever the camera sees, for views from above it (artpass/bays/baysprobe.gd).
var show_always := false
## Shows the garden until this tick (ms) whatever the camera sees: set by the path tracer's dress
## (artpass/dlss/pt_scene.gd) as it starts, so that the fork builds the gardens' hit shaders during its first
## half minute rather than when the visitor first walks out. Hidden until then, they were missing from the rays
## for over 6 s after the eye reached the terrace (RTX 0.2.4's tree 12, artpass/publish/rtx/logs/views-b12).
var rt_warm_until := 0

var _obs: Node3D
var _core := Vector3(-0.468, 0.867, -0.170)
var _garden: Node3D
var _openings: Array[Dictionary] = []
var _doors: Array[Dictionary] = []    # a bay's: its frame, its foot, the leaves' swing, the leaves
## false: the doors open within DOOR_NEAR whatever the view, as the candidate of 2026-10-05 did.
var door_look := true
var _jets: Array[Node3D] = []
var _rays: Array[Node3D] = []
var _thin: Array[MultiMeshInstance3D] = []  # thinned out from quality level 3, to their "keep" meta
var _far: Array[Node3D] = []                # gone from level 4
var _lods: Array = []                       # [MultiMeshInstance3D, full mesh, light mesh from level 3]
var _level := -1
var _view_fit: Node         # view_fit.gd, for the screen's zoom (_zoom_fringe)
var _fringe_zoom := 1.0
var _compat := false
## The solids a rider meets, by cell (Vector2i): Vector4(x, z, half width, half depth) for a box,
## Vector4(x, z, radius, -1) for a round one.
var _solids := {}
## What the terrace and the parterre share, drawn together by _build_fittings: boxes in stone or
## bronze (tinted), lamp globes, and round trees (tinted).
var _fit := {"boxes": [], "box_tints": [], "lamps": [], "trees": [], "tree_tints": [], "lamp_feet": [], "lamp_glass": []}
var _lamp_kit := false                    # the modelled lamps (LAMP_KIT_PATH) stand for the posts and globes
var _water_mat: ShaderMaterial  # mirrors the palace's card, once there is one
## The vegetation kit, once loaded: its meshes by path, its materials by name, and what the quality level
## changes: the near chunks, the near materials and the far views' materials that hand over to them.
var _veg := {"ok": false, "meshes": {}, "mats": {}, "chunks": [], "fringe": [], "fringe_mats": [], "near_mats": [], "far_mats": [],
	"near_r": -1.0}
var _crowd: Node3D                        # scripts/garden_crowd.gd, when its figures are there
var _capitole: Node3D                     # scripts/capitole_square.gd, once built
var _capitole_script: Script              # its script, while the square is to be built (its place, covers())
var _capitole_xf := Transform3D()         # its place
var _show: Node3D                         # scripts/fountain_show.gd, when the canal has its show
var _maze_way := PackedVector2Array()     # from outside the maze's entrance to its clearing (_build_maze)
var _maze_mid := Vector2.ZERO             # the temple's middle
## Lit by the path tracer (set_rt_lit; the author, 2026-10-15: « On veut des arbres et jardins
## photorealistes »): whether it is, and the lights that stand for the lamps then.
var _rt_lit := false
var _rt_lights: Node3D
var _rt_sky: Node3D                         # the core and the sky's fill: outside _garden, so the hall never sees them come and go
var _rt_lamps: Array[OmniLight3D] = []
var _rt_culled_at := -1.0e9


## observatory: the hall, for its dimensions, materials and the nodes it built; core: the galactic
## core's direction (the night sky's, as scripts/upperside.gd takes it).
func configure(observatory: Node3D, core: Vector3) -> void:
	_obs = observatory
	_core = core


func _ready() -> void:
	# After the camera, the walking body and the flights have moved the camera this frame.
	process_priority = 900
	_compat = RenderingServer.get_current_rendering_method() == "gl_compatibility"
	var args := OS.get_cmdline_user_args()
	var start := args.has("--preset=gardens")
	enabled = not args.has("--no-gardens")
	night_city = night_city and not args.has("--city=strips")
	palace_model = palace_model and not args.has("--palace=card")
	parterre_kit = parterre_kit and not args.has("--parterre=drawn")
	fountain_show = fountain_show and not args.has("--show=off")
	capitole = capitole and not args.has("--capitole=off")
	if OS.has_feature("web"):
		fountain_show = fountain_show and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('show') || ''", true)) != "off"
		palace_model = palace_model and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('palace') || ''", true)) != "card"
		parterre_kit = parterre_kit and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('parterre') || ''", true)) != "drawn"
		start = start or str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('preset') || ''", true)) == "gardens"
		enabled = enabled and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('gardens') || ''", true)) != "0"
		night_city = night_city and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('city') || ''", true)) != "strips"
	if start:
		go.call_deferred()
	if not enabled:
		set_process(false)
		_web_state()
		return
	var t0 := Time.get_ticks_usec()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_open_bays()
	_veg.ok = _veg_ready()
	stats.trees_kit = _veg.ok
	_lamp_kit = not _compat and ResourceLoader.exists(LAMP_KIT_PATH)
	stats.lamp_kit = _lamp_kit
	# The Place du Capitole's place first: the avenues and the woods keep clear of it.
	if capitole and not _compat and ResourceLoader.exists(CAPITOLE_SCRIPT_PATH) and ResourceLoader.exists(CAPITOLE_GLB_PATH):
		_capitole_script = load(CAPITOLE_SCRIPT_PATH)
		var a := deg_to_rad(-60.0)
		_capitole_xf = _capitole_script.call("placement", AVENUE_FROM, Vector2(sin(a), cos(a)), CAPITOLE_AT, GROUND_Y)
	_garden = Node3D.new()
	_garden.name = "Garden"
	add_child(_garden)
	_build_terrace()
	_build_facade()
	_build_parterre(rng)
	_build_grounds()
	_build_fittings()
	_build_water()
	_build_palace()
	_build_capitole()
	_build_city(rng)
	_build_crowd()
	_build_grand()
	# Off the web, the clipped hedges' outer leaves in layers over them (scripts/hedge_shells.gd).
	if not _compat and _veg.ok and ResourceLoader.exists(HEDGE_SHELLS_PATH):
		var shells: Node3D = load(HEDGE_SHELLS_PATH).new()
		shells.name = "HedgeShells"
		_garden.add_child(shells)
		shells.call("build", _garden, _obs)
		stats.hedge_shells = shells.get("stats")
	# The ride in the gardens (scripts/segway.gd), beside the walking body and the other ways round.
	if ResourceLoader.exists(SEGWAY_SCRIPT_PATH) and _obs.get_node_or_null("Segway") == null:
		var seg: Node = load(SEGWAY_SCRIPT_PATH).new()
		seg.name = "Segway"
		seg.call("configure", _obs, self)
		_obs.add_child.call_deferred(seg)
	_garden.visible = false
	stats.build_ms = snappedf(float(Time.get_ticks_usec() - t0) / 1000.0, 0.1)
	_web_state()


# --- Helpers ------------------------------------------------------------------------------------

## As observatory.gd's: on a circle of the given radius, local +Z towards the centre, +X tangent.
static func _radial(angle: float, radius: float, y: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, atan2(-cos(angle), -sin(angle))), Vector3(cos(angle) * radius, y, sin(angle) * radius))


static func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


## A box from its two corners, in the frame xf.
static func _span(xf: Transform3D, lo: Vector3, hi: Vector3) -> Array:
	return [_box(hi - lo), xf * Transform3D(Basis(), (lo + hi) * 0.5)]


func _gmat(kind: int, albedo: Color, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(GARDEN_SHADER_PATH)
	m.set_shader_parameter("kind", kind)
	m.set_shader_parameter("albedo", albedo)
	m.set_shader_parameter("core_dir", _core)
	m.set_shader_parameter("terrace_r", TERRACE_R - 0.3)
	m.set_shader_parameter("terrace_y", 1.45)
	if kind == 5:
		# A lamp's light stands inside its globe in the path tracer (set_rt_lit): let it out (the fork's
		# rt_no_shadow.py; only the shader's RT variant declares it).
		m.set_shader_parameter("rt_no_shadow", true)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


func _glow(colour: Color, energy: float, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(GLOW_SHADER_PATH)
	m.set_shader_parameter("colour", colour)
	m.set_shader_parameter("energy", energy)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


## Outside: no shadow, no GI, nothing the hall's light probes should take in.
func _out(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	return mi


func _mesh(parent: Node, node_name: String, mesh: Mesh, mat: Material, xf := Transform3D()) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xf
	parent.add_child(mi)
	_out(mi)
	stats.garden_meshes += 1
	return mi


func _multi(parent: Node, node_name: String, mesh: Mesh, mat: Material, xforms: Array, colors: Array = []) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if mm.use_colors:
			mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = mat
	parent.add_child(mmi)
	_out(mmi)
	stats.garden_meshes += 1
	stats.garden_instances += xforms.size()
	return mmi


func _merge(parts: Array) -> ArrayMesh:
	return _obs.call("_merge", parts)


## The mesh with every vertex coloured `col`, so that parts in different colours can be merged into
## one mesh (palace_glow.gdshader multiplies by it). All the parts of a merge need a colour, or the
## others come out black.
static func _tinted(mesh: Mesh, col: Color) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var colours := PackedColorArray()
	colours.resize((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	colours.fill(col)
	arrays[Mesh.ARRAY_COLOR] = colours
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


static var _fine_balusters := {}


## The finer baluster ("" or its light version "_low"; FINE_BALUSTER_PATH), its attributes uncompressed, with
## the import's levels of detail and shadow mesh; the same mesh at each call, here and in the library's wings.
## NVIDIA's fork merges a MultiMesh into one acceleration structure, with its instances' INSTANCE_CUSTOM, only
## for a mesh whose attributes are not compressed (render_raytracing.cpp _build_merged_mm_blas), and the OBJ
## importer compresses them: path traced, the balusters lost their custom data and the stone ringed them as it
## does the walls (artpass/gardens/balusters/NOTES.md).
static func fine_baluster(variant: String) -> Mesh:
	if _fine_balusters.has(variant):
		return _fine_balusters[variant]
	var src: Mesh = load(FINE_BALUSTER_PATH % variant)
	var out := ArrayMesh.new()
	out.resource_name = (FINE_BALUSTER_PATH % variant).get_file().get_basename()
	for s in src.get_surface_count():
		var sd := RenderingServer.mesh_get_surface(src.get_rid(), s)
		var main: PackedByteArray = sd.get("index_data", PackedByteArray())
		var wide := main.size() >= int(sd.get("index_count", 0)) * 4  # 32-bit indices, else 16
		var lods := {}
		for lod: Dictionary in sd.get("lods", []):
			var bytes: PackedByteArray = lod["index_data"]
			var idx := PackedInt32Array()
			if wide:
				idx = bytes.to_int32_array()
			else:
				idx.resize(bytes.size() / 6 * 3)
				for i in idx.size():
					idx[i] = bytes.decode_u16(i * 2)
			lods[float(lod["edge_length"])] = idx
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, src.surface_get_arrays(s), [], lods)
		out.surface_set_material(s, src.surface_get_material(s))
	if src is ArrayMesh:
		out.shadow_mesh = (src as ArrayMesh).shadow_mesh
	_fine_balusters[variant] = out
	return out


## A flat convex face from its corners, fanned into triangles that face along n (Godot's front faces
## wind clockwise as seen from in front), UV the world's x and z.
static func _face(st: SurfaceTool, pts: Array, n: Vector3) -> void:
	for k in range(1, pts.size() - 1):
		var p0: Vector3 = pts[0]
		var p1: Vector3 = pts[k]
		var p2: Vector3 = pts[k + 1]
		if (p1 - p0).cross(p2 - p0).dot(n) > 0.0:
			var t := p1
			p1 = p2
			p2 = t
		for p: Vector3 in [p0, p1, p2]:
			st.set_normal(n)
			st.set_uv(Vector2(p.x, p.z))
			st.add_vertex(p)


## The angles (from +X round to +Z) between which a ring of radius r opens over the ramp.
static func _ramp_gap(r: float) -> Vector2:
	var a := acos(clampf(RAMP_HALF / r, -1.0, 1.0))
	return Vector2(a, PI - a)


## A solid for the rider: a box of half size `half` (x, z), or round, of radius half.x, when half.y < 0.
func _solid(c: Vector2, half: Vector2) -> void:
	var ext := Vector2(half.x, half.x) if half.y < 0.0 else half
	var s := Vector4(c.x, c.y, half.x, half.y)
	for i in range(floori((c.x - ext.x) / SOLID_CELL), floori((c.x + ext.x) / SOLID_CELL) + 1):
		for j in range(floori((c.y - ext.y) / SOLID_CELL), floori((c.y + ext.y) / SOLID_CELL) + 1):
			var k := Vector2i(i, j)
			if _solids.has(k):
				(_solids[k] as Array).append(s)
			else:
				_solids[k] = [s]


## The ground's height for a rider at p (x, z): the terrace's paving (and the hall's floor), the ramp
## down from it, the parterre; on the Place du Capitole's footprint, its paving, laid 3 cm over the gardens'
## ground (capitole_square.gd placement): the scooter's wheels sank into it, and its headlamp's pool, 5 cm up,
## went under it as the scooter leaned (2026-10-16, artpass/gardens/escooter).
func ground_at(p: Vector2) -> float:
	if absf(p.x) <= RAMP_HALF + 0.4 and p.y >= RAMP_Z0 - 0.6 and p.y <= RAMP_Z1:
		return lerpf(0.0, GROUND_Y, clampf((p.y - RAMP_Z0) / (RAMP_Z1 - RAMP_Z0), 0.0, 1.0))
	if p.length() < RAMP_Z0 and p.y > 0.0:
		return 0.0
	if _capitole != null and _capitole_covers(p, 0.0):
		return _capitole_xf.origin.y
	return GROUND_Y


## Where a rider of radius r at p (x, z), on ground at height y, ends once pushed out of what stands
## round it: the solids; on the terrace, the hall's wall, the balustrade (but over the ramp) and the
## terrace's ends; below, the retaining wall; and the ride's edge, RIDE_R.
func push_out(p: Vector2, r: float, y: float, doors := false) -> Vector2:
	var q := p
	# The people first: whatever stands is pushed out of last.
	if _crowd != null and _crowd.is_visible_in_tree():
		q = _crowd.call("push_out", q, r)
	var cell := Vector2i(floori(q.x / SOLID_CELL), floori(q.y / SOLID_CELL))
	for i in range(cell.x - 1, cell.x + 2):
		for j in range(cell.y - 1, cell.y + 2):
			for s: Vector4 in _solids.get(Vector2i(i, j), []):
				var c := Vector2(s.x, s.y)
				if s.w < 0.0:
					var d := q - c
					var reach := s.z + r
					if d.length_squared() < reach * reach:
						q = c + (d.normalized() if d.length_squared() > 1e-8 else Vector2.RIGHT) * reach
					continue
				var lo := c - Vector2(s.z, s.w)
				var hi := c + Vector2(s.z, s.w)
				var near := q.clamp(lo, hi)
				var off := q - near
				if off.length_squared() >= r * r:
					continue
				if off.length_squared() > 1e-8:
					q = near + off.normalized() * r
				else:
					# Inside the box: out by its nearest side.
					var best := Vector2(lo.x - r - q.x, 0.0)
					for o: Vector2 in [Vector2(hi.x + r - q.x, 0.0), Vector2(0.0, lo.y - r - q.y), Vector2(0.0, hi.y + r - q.y)]:
						if o.length() < best.length():
							best = o
					q += best
	var dist := q.length()
	if y > GROUND_Y + 1.0 and dist < RAMP_Z0:
		var wall := float(_obs.get("outer_radius")) + 0.42 + FACADE_SKIN + FACADE_OUT + r
		# On foot (`doors`), an open bay's doorway lets the visitor through the wall to the hall.
		var through := _door_pass(q, r) if doors else Vector2.INF
		if through != Vector2.INF:
			q = through
		elif dist < wall:
			q = q.normalized() * wall
		q = _push_leaves(q, r)
		# The balustrade, from the side the rider is on.
		var rail := TERRACE_R - 0.3
		var from_rail := q.length() - rail
		if absf(q.x) > RAMP_HALF - r and absf(from_rail) < 0.25 + r:
			q = q.normalized() * (rail + signf(from_rail) * (0.25 + r))
		q.y = maxf(q.y, 0.6 + r)
	elif y <= GROUND_Y + 1.0:
		if dist < RAMP_Z0 + r:
			q = (q.normalized() if dist > 1e-4 else Vector2.DOWN) * (RAMP_Z0 + r)
		q.y = maxf(q.y, r)
	var wing := _wing()
	if wing != null:
		q = wing.call("push_out", q, r, y)
	# On the Place du Capitole's ground, past the ride's edge, the square's own bounds hold the rider.
	if _capitole != null and _capitole_covers(q, 0.0):
		q = _capitole.call("push_in", q, r)
		if q.length() <= RIDE_R or _capitole_covers(q, 0.0):
			return q
	if q.length() > RIDE_R:
		# Off the square's footprint past the ride's edge, by its far streets: held on the footprint, its edge a
		# wall there. Put back on the ride's edge, a walker landed in a building and was moved across the square.
		if _capitole != null and _capitole_covers(q, 2.0):
			return _capitole.call("hold_in", q, r)
		q = q.normalized() * RIDE_R
	return q


static func _sphere(segments: int, rings: int, hemisphere := false) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0  # a hemisphere's is half that
	s.is_hemisphere = hemisphere
	s.radial_segments = segments
	s.rings = rings
	return s


# --- The bays -----------------------------------------------------------------------------------

func _open_bays() -> void:
	var shelves := _obs.get_node_or_null("Generated/Shelves")
	var bay_count := int(_obs.get("bay_count"))
	var outer := float(_obs.get("outer_radius"))
	var levels: PackedFloat32Array = _obs.get("gallery_levels")
	var top0 := levels[0] - 0.6 if levels.size() > 0 else 5.6
	var r := outer - 0.55
	var width := 2.0 * r * sin(PI / bay_count) - 0.3
	var m: Dictionary = _obs.get("_m")
	var half_a := (OPEN_W * 0.5) / outer
	var cuts: Array[float] = []
	var acc := {"recess": [], "trim": [], "bronze": [], "glass": [], "shafts": [], "pools": [], "doors": []}
	for k in BAYS.size():
		var i: int = BAYS[k]
		var a := TAU * (i + 0.5) / bay_count
		cuts.append(a)
		var unit := _radial(a, r, 0.0)
		if shelves != null:
			_cut_shelves(shelves, i, unit, width, top0)
		var lamp := _obs.get_node_or_null("Generated/Shelves/Unit_L0_B%02d/ShelfLamp" % i) as OmniLight3D
		if lamp != null:
			# The shelf's warm lamp becomes the garden's light through the glass.
			lamp.light_color = Color(0.62, 0.72, 1.0)
			lamp.light_energy = 0.45
			lamp.position = Vector3(0, 3.2, 0.9)
			stats.lamps_turned += 1
		var row := _obs.get_node_or_null("Generated/CourseShelves/CourseRow_B%02d" % i) as Node3D
		if row != null:
			row.visible = false
		var frame := _radial(a, outer, 0.0)
		_build_bay(frame, k, acc)
		_openings.append({"centre": frame * Vector3(0, (SILL + HEAD) * 0.5, GLASS_Z), "in": frame.basis.z,
			"corners": [frame * Vector3(-OPEN_W * 0.5, SILL, GLASS_Z), frame * Vector3(OPEN_W * 0.5, SILL, GLASS_Z),
				frame * Vector3(-OPEN_W * 0.5, HEAD, GLASS_Z), frame * Vector3(OPEN_W * 0.5, HEAD, GLASS_Z)]})
		stats.bays += 1
	# The library wing's bay: an opening as wide, which the wing frames with its own portal.
	for i: int in _wing_bays():
		var a := TAU * (i + 0.5) / bay_count
		cuts.append(a)
		if shelves != null:
			_cut_shelves(shelves, i, _radial(a, r, 0.0), width, top0)
		var row := _obs.get_node_or_null("Generated/CourseShelves/CourseRow_B%02d" % i) as Node3D
		if row != null:
			row.visible = false
		if not stats.has("wing_bay"):
			stats.wing_bay = i
		stats.wing_bays = stats.get("wing_bays", []) + [i]
	# For the course shelves' later rebuilds (course_library.gd _build), which leave these bays empty.
	var opened: Array = BAYS.duplicate()
	opened.append_array(_wing_bays())
	_obs.set_meta("open_bays", opened)
	_bay_meshes(acc, m)
	# The outer wall again, with the openings through it below the walkway.
	var wall := _obs.get_node_or_null("Generated/Shelves/OuterWall") as MeshInstance3D
	if wall != null:
		var top := float(_obs.get("_ceiling_y")) + 0.6
		var parts := [[_obs.call("ring_sector", outer, outer + 0.4, top - HEAD, 0.0, TAU, 128), Transform3D(Basis(), Vector3(0, HEAD, 0))]]
		cuts.sort()
		for k in cuts.size():
			var a0: float = cuts[k] + half_a
			var a1: float = (cuts[k + 1] if k + 1 < cuts.size() else cuts[0] + TAU) - half_a
			parts.append([_obs.call("ring_sector", outer, outer + 0.4, HEAD, a0, a1, maxi(4, int((a1 - a0) / TAU * 128.0))), Transform3D()])
		wall.mesh = _merge(parts)
		stats.wall_rebuilt = true


## A quad of a bay's glass from x0 to x1 and y0 to y1 in its frame, at the glass's depth, with its
## vertices given from `origin` (a leaf's hinge) and its UV over the whole opening, as
## bay_glass.gdshader expects: UV.x across, UV.y from the head down to the sill.
static func _glass_quad(x0: float, x1: float, y0: float, y1: float, origin := Vector3.ZERO) -> ArrayMesh:
	var q := QuadMesh.new()
	q.size = Vector2(x1 - x0, y1 - y0)
	q.center_offset = Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, GLASS_Z)
	var arrays := q.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uv := PackedVector2Array()
	for i in v.size():
		uv.append(Vector2((v[i].x + OPEN_W * 0.5) / OPEN_W, (HEAD - v[i].y) / (HEAD - SILL)))
		v[i] -= origin
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


## A bay's French doors below the transom: two leaves hinged on the frame's stiles and meeting in the
## middle, each a node with its bronze (stiles, rails, a glazing bar and the two cross bars, as the
## lights had) and its glass, which _swing_doors turns.
func _build_doors(g: Node3D, f: Transform3D, bronze: Material, glass: Material) -> void:
	var hw := OPEN_W * 0.5
	var b := 0.05
	var top := TRANSOM - b
	var w := hw - DOOR_GAP
	var door := {"frame": f, "foot": f * Vector3(0.0, 0.0, GLASS_Z), "angle": 0.0, "leaves": []}
	for side: float in [-1.0, 1.0]:
		var hinge := Vector3(side * w, 0.0, GLASS_Z)
		var leaf := Node3D.new()
		leaf.name = "Door%d%s" % [_doors.size(), "L" if side < 0.0 else "R"]
		leaf.transform = f * Transform3D(Basis(), hinge)
		leaf.set_meta("side", side)
		leaf.set_meta("hinge", hinge)
		leaf.set_meta("width", w)
		g.add_child(leaf)
		# In the leaf's frame x runs from the hinge (0) to the middle (-side * w).
		var bar := func(x0: float, x1: float, y0: float, y1: float, depth: float) -> Array:
			return _span(Transform3D(), Vector3(minf(x0, x1), y0, -depth), Vector3(maxf(x0, x1), y1, depth))
		var mid := -side * w
		var glazing := side * (DOOR_GAP - hw * 0.5)
		var parts := [
			bar.call(0.0, -side * 2.0 * b, SILL, top, 0.06),
			bar.call(mid + side * b, mid, SILL, top, 0.06),
			bar.call(glazing - b, glazing + b, SILL, top, 0.06),
			bar.call(0.0, mid, SILL, SILL + 2.0 * b, 0.06),
			bar.call(0.0, mid, top - 2.0 * b, top, 0.06),
		]
		for y: float in [1.45, 2.75]:
			parts.append(bar.call(0.0, mid, y - 0.02, y + 0.02, 0.03))
		if bronze != null:
			_add_in(leaf, "Bronze", _merge(parts), bronze)
		if glass != null:
			_add_in(leaf, "Glass", _glass_quad(minf(0.0, side * w), maxf(0.0, side * w), SILL, top, hinge), glass, false)
		(door.leaves as Array).append(leaf)
	_doors.append(door)


## The doors open as a visitor on foot comes near their foot at the floor's level, from the hall or from
## the terrace, and close behind them.
func _swing_doors(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var walking := _on_foot()
	for door: Dictionary in _doors:
		var foot: Vector3 = door.foot
		var want := 0.0
		if cam != null and walking:
			var p := cam.global_position
			var to := Vector2(foot.x - p.x, foot.z - p.z)
			var view := cam.global_transform.basis.z
			var look := -Vector2(view.x, view.z)
			var seen: bool = not door_look or to.length() < DOOR_BY \
				or (look.length() > 1e-4 and look.normalized().dot(to.normalized()) > DOOR_LOOK)
			if p.y - foot.y < DOOR_HIGH and to.length() < DOOR_NEAR and seen:
				want = DOOR_SWING
		var a := move_toward(float(door.angle), want, DOOR_SPEED * delta)
		if a == float(door.angle):
			continue
		door.angle = a
		var f: Transform3D = door.frame
		for leaf: Node3D in door.leaves:
			leaf.transform = f * Transform3D(Basis(Vector3.UP, -float(leaf.get_meta("side")) * a), leaf.get_meta("hinge"))


## Whether the camera is a visitor on foot: the hall's walking body (walk_physics.gd is_walking) or the
## gardens' walk (segway.gd on_foot). For a rider, a flight or a view the doors stay shut: open, their
## leaves stood across the terrace and stopped a ride along the facade (artpass/gardens/walkout).
func _on_foot() -> bool:
	var seg := _obs.get_node_or_null("Segway")
	if seg != null:
		if bool(seg.get("on_foot")):
			return true
		if bool(seg.get("riding")):
			return false
	var walker := _obs.get_node_or_null("WalkBody")
	return walker != null and walker.has_method("is_walking") and bool(walker.call("is_walking"))


## p (x, z) in a bay's frame: +X along the wall, +Z into the hall from the wall's inner face.
func _in_bay(door: Dictionary, p: Vector2) -> Vector3:
	return (door.frame as Transform3D).affine_inverse() * Vector3(p.x, 0.0, p.y)


## For the hall's walking body (walk_physics.gd), held `reach` from the hall's middle (the shelves'
## front): within a bay's opening it goes on into the recess between the jambs, up to the glass, or
## through while the doors stand open. Where a body of radius r going to p stays.
func bay_walk(p: Vector2, r: float, reach: float) -> Vector2:
	if p.length() <= reach:
		return p
	for door: Dictionary in _doors:
		var q := _in_bay(door, p)
		# Within its opening and on its side of the hall: bay 2's line runs on across the hall down the
		# library wing, whose nave it made a lane as wide as its doorway, open at the end (2026-10-13,
		# artpass/foundation/wingwalk).
		if absf(q.x) > OPEN_W * 0.5 or q.z < GLASS_Z - 2.0 or q.z > float(_obs.get("outer_radius")):
			continue
		var side := OPEN_W * 0.5 - DOOR_GAP - r
		q.x = clampf(q.x, -side, side)
		if float(door.angle) < DOOR_PASS:
			q.z = maxf(q.z, GLASS_Z + r + 0.04)
		var at := (door.frame as Transform3D) * q
		return Vector2(at.x, at.z)
	var wing := _wing()
	if wing != null:
		var w: Vector2 = wing.call("walk", p, r)
		if w != Vector2.INF:
			return w
	return p.normalized() * reach


## How far from the hall's middle the walking body may go on the floor: out through a bay's doorway,
## or down the library wing (walk_physics.gd widens the camera's bound to it).
func walk_radius() -> float:
	var reach := float(_obs.get("outer_radius")) + 1.5
	var wing := _wing()
	return maxf(reach, float(wing.call("far_radius"))) if wing != null else reach


## The library wing, once extra_views.gd has made it; null without it.
func _wing() -> Node3D:
	var wing := _obs.get_node_or_null("LibraryWing") as Node3D
	return wing if wing != null and wing.has_method("walk") else null


## The bays the library wings open, when they are wanted (library_wing.gd bays(): 10 and 13).
func _wing_bays() -> Array[int]:
	var out: Array[int] = []
	if not ResourceLoader.exists(WING_SCRIPT_PATH):
		return out
	var script: GDScript = load(WING_SCRIPT_PATH)
	for i: int in script.call("bays"):
		out.append(i)
	return out


## Whether the hall's walking body at p has gone out past a bay's glass, its doors open.
func bay_out(p: Vector2) -> bool:
	for door: Dictionary in _doors:
		var q := _in_bay(door, p)
		if absf(q.x) <= OPEN_W * 0.5 and q.z < GLASS_Z - 0.1 and q.z > GLASS_Z - 2.0 and float(door.angle) >= DOOR_PASS:
			return true
	return false


## Whether a visitor on foot from the gardens at p has come in past a bay's glass.
func bay_in(p: Vector2) -> bool:
	for door: Dictionary in _doors:
		var q := _in_bay(door, p)
		if absf(q.x) <= OPEN_W * 0.5 and q.z > GLASS_Z + 0.1 and q.z < 1.0:
			return true
	return false


## On the terrace, a visitor on foot of radius r at p within an open bay's opening: kept between its
## jambs, and let through the wall towards the hall; Vector2.INF when p is not there.
func _door_pass(p: Vector2, r: float) -> Vector2:
	var depth := 0.42 + FACADE_SKIN + FACADE_OUT + r + 0.3
	for door: Dictionary in _doors:
		if float(door.angle) < DOOR_PASS:
			continue
		var q := _in_bay(door, p)
		if absf(q.x) > OPEN_W * 0.5 or q.z < -depth or q.z > 0.8:
			continue
		var side := OPEN_W * 0.5 - DOOR_GAP - r
		q.x = clampf(q.x, -side, side)
		var at := (door.frame as Transform3D) * q
		return Vector2(at.x, at.z)
	return Vector2.INF


## A body of radius r at p, out of the doors' leaves where they stand open from the wall.
func _push_leaves(p: Vector2, r: float) -> Vector2:
	var q := p
	for door: Dictionary in _doors:
		if float(door.angle) < 0.3:
			continue
		for leaf: Node3D in door.leaves:
			var xf := leaf.transform
			var h3 := xf.origin
			var e3 := xf * Vector3(-float(leaf.get_meta("side")) * float(leaf.get_meta("width")), 0.0, 0.0)
			var a := Vector2(h3.x, h3.z)
			var ab := Vector2(e3.x, e3.z) - a
			var t := clampf((q - a).dot(ab) / maxf(ab.length_squared(), 1e-8), 0.0, 1.0)
			var near := a + ab * t
			var d := q - near
			var reach := r + 0.04
			if d.length_squared() < reach * reach:
				var n := d.normalized() if d.length_squared() > 1e-8 else Vector2(-ab.y, ab.x).normalized()
				q = near + n * reach
	return q


## The ground level of bay i goes: its wood's back and boards (the sides stay, as the recess's
## jambs, and the top board as its cornice), and its books, strips and crystals.
func _cut_shelves(shelves: Node, i: int, unit: Transform3D, width: float, top0: float) -> void:
	var to_unit := unit.affine_inverse()
	var keep_x := width * 0.5 - 0.1
	var low := top0 - 0.1
	var wood := shelves.get_node_or_null("Wood_B%02d" % i) as MeshInstance3D
	if wood != null and wood.mesh != null:
		wood.mesh = _cut_mesh(wood.mesh, to_unit, keep_x, low)
	var inside := func(p: Vector3) -> bool:
		var q := to_unit * p
		return q.y < low and absf(q.x) < keep_x + 0.05 and absf(q.z) < 1.0
	# The course row's crystals too (course_library.gd), which its row's hiding left standing in the air.
	var course := _obs.get_node_or_null("Generated/CourseShelves")
	for spec: Array in [[shelves, "Books_B%02d" % i, "books_hidden"], [shelves, "ShelfLightStrips", "strips_hidden"],
			[shelves, "CrystalArchives", "crystals_hidden"], [course, "CourseRowCrystals", "crystals_hidden"]]:
		var mmi: MultiMeshInstance3D = null
		if spec[0] != null:
			mmi = (spec[0] as Node).get_node_or_null(str(spec[1])) as MultiMeshInstance3D
		if mmi == null or mmi.multimesh == null:
			continue
		var mm := mmi.multimesh
		for j in mm.instance_count:
			var xf := mm.get_instance_transform(j)
			if inside.call(mmi.transform * xf.origin):
				mm.set_instance_transform(j, Transform3D(Basis.from_scale(Vector3.ZERO), xf.origin))
				stats[spec[2]] += 1


## The mesh without its triangles whose centre, in the unit's frame, lies below `low` and within
## `keep_x` of the middle.
func _cut_mesh(mesh: Mesh, to_unit: Transform3D, keep_x: float, low: float) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var nrm: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var tri := idx.size() / 3 if not idx.is_empty() else v.size() / 3
	var ov := PackedVector3Array()
	var on := PackedVector3Array()
	var ou := PackedVector2Array()
	var cut := 0
	for t in tri:
		var ids: Array[int] = [t * 3, t * 3 + 1, t * 3 + 2]
		if not idx.is_empty():
			ids = [idx[t * 3], idx[t * 3 + 1], idx[t * 3 + 2]]
		var c := to_unit * ((v[ids[0]] + v[ids[1]] + v[ids[2]]) / 3.0)
		if c.y < low and absf(c.x) < keep_x:
			cut += 1
			continue
		for id in ids:
			ov.append(v[id])
			if not nrm.is_empty():
				on.append(nrm[id])
			if not uv.is_empty():
				ou.append(uv[id])
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = ov
	if not nrm.is_empty():
		out[Mesh.ARRAY_NORMAL] = on
	if not uv.is_empty():
		out[Mesh.ARRAY_TEX_UV] = ou
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	stats.wood_tris_cut += cut
	return am


## Bay k's recess, frame, glass and light, in the frame on the wall's inner face (local +Z into the
## hall, +X along the wall), gathered in `acc` by material: _bay_meshes draws the two bays together,
## one mesh per material, so that a bay in view costs six draw calls rather than eight per bay.
func _build_bay(f: Transform3D, k: int, acc: Dictionary) -> void:
	var hw := OPEN_W * 0.5
	# The recess's face, flush with the shelves' sides, from the floor to the walkway: piers either
	# side and a lintel.
	acc.recess.append_array([
		_span(f, Vector3(-3.2, 0.0, 0.0), Vector3(-hw, 5.85, SCREEN_Z)),
		_span(f, Vector3(hw, 0.0, 0.0), Vector3(3.2, 5.85, SCREEN_Z)),
		_span(f, Vector3(-hw, HEAD, 0.0), Vector3(hw, 5.85, SCREEN_Z)),
	])
	# In lighter stone: the reveals through the wall, the sill, and an architrave round the opening on
	# the recess's face.
	acc.trim.append_array([
		_span(f, Vector3(-hw - 0.3, 0.0, OUT_Z), Vector3(-hw, HEAD + 0.3, 0.0)),
		_span(f, Vector3(hw, 0.0, OUT_Z), Vector3(hw + 0.3, HEAD + 0.3, 0.0)),
		_span(f, Vector3(-hw, HEAD, OUT_Z), Vector3(hw, HEAD + 0.3, 0.0)),
		_span(f, Vector3(-hw - 0.1, 0.0, OUT_Z - 0.05), Vector3(hw + 0.1, SILL, SCREEN_Z + 0.12)),
		_span(f, Vector3(-hw - 0.28, SILL, SCREEN_Z), Vector3(-hw, HEAD + 0.28, SCREEN_Z + 0.07)),
		_span(f, Vector3(hw, SILL, SCREEN_Z), Vector3(hw + 0.28, HEAD + 0.28, SCREEN_Z + 0.07)),
		_span(f, Vector3(-hw - 0.28, HEAD, SCREEN_Z), Vector3(hw + 0.28, HEAD + 0.28, SCREEN_Z + 0.07)),
	])
	# Bronze: a bead inside the architrave (the gilt, which glows by itself, read as a neon tube round
	# the window: artpass/bays/v1-fwd), the frame, three mullions, the transom, and two glazing bars
	# across each light.
	var b := 0.05
	acc.bronze.append_array([
		_span(f, Vector3(-hw - 0.03, SILL, SCREEN_Z + 0.06), Vector3(-hw, HEAD, SCREEN_Z + 0.09)),
		_span(f, Vector3(hw, SILL, SCREEN_Z + 0.06), Vector3(hw + 0.03, HEAD, SCREEN_Z + 0.09)),
		_span(f, Vector3(-hw, HEAD, SCREEN_Z + 0.06), Vector3(hw, HEAD + 0.03, SCREEN_Z + 0.09)),
	])
	# The frame's stiles stand from the sill to the head, the mullions above the transom only: below it,
	# the doors' own stiles and bars swing with them (_build_doors).
	for x: float in [-hw, -hw * 0.5, 0.0, hw * 0.5, hw]:
		var x0 := clampf(x - b, -hw, hw - 2.0 * b)
		var lo := SILL if absf(x) >= hw else TRANSOM - b
		acc.bronze.append(_span(f, Vector3(x0, lo, GLASS_Z - 0.06), Vector3(x0 + 2.0 * b, HEAD, GLASS_Z + 0.06)))
	for y: float in [TRANSOM - b, HEAD - 2.0 * b]:
		acc.bronze.append(_span(f, Vector3(-hw, y, GLASS_Z - 0.06), Vector3(hw, y + 2.0 * b, GLASS_Z + 0.06)))
	# The fixed glass, the fanlight, with UV over the whole opening as the doors' (UV.y from the head down
	# to the sill), so that bay_glass.gdshader draws them as one window.
	acc.glass.append([_glass_quad(-hw, hw, TRANSOM - b, HEAD), f])
	acc.doors.append(f)
	# The coloured light through the fanlight: a shaft down into the hall and its pool on the floor,
	# in the bay's colour as vertex colour, linear (palace_glow.gdshader converts under Compatibility).
	var col: Color = RAY_COLOURS[k % RAY_COLOURS.size()]
	var tint := col.srgb_to_linear()
	var dir := Vector3(0.0, -sin(deg_to_rad(38.0)), cos(deg_to_rad(38.0)))
	var length := (TRANSOM - 0.05) / -dir.y
	var shaft := _shaft(Vector3(-hw + 0.1, TRANSOM, GLASS_Z), Vector3(hw - 0.1, HEAD - 0.1, GLASS_Z), dir * length)
	acc.shafts.append([_tinted(shaft, tint), f])
	var pool := QuadMesh.new()
	pool.size = Vector2(OPEN_W * 0.9, 3.2)
	pool.orientation = PlaneMesh.FACE_Y
	var land := (length - 0.8) * dir.z + GLASS_Z
	# 6 mm over the floor: coplanar faces fight in WebGL.
	acc.pools.append([_tinted(pool, tint), f * Transform3D(Basis(), Vector3(0.0, 0.006, land))])
	if not _compat:
		# Under Forward+, a spot from the fanlight into the volumetric fog as well.
		var spot := SpotLight3D.new()
		spot.name = "FanlightLight%d" % BAYS[k]
		spot.light_color = col
		spot.light_energy = 0.8
		spot.light_specular = 0.05
		spot.spot_range = 11.0
		spot.spot_angle = 22.0
		spot.spot_attenuation = 0.8
		spot.light_volumetric_fog_energy = 1.4
		var from := f * Vector3(0.0, (TRANSOM + HEAD) * 0.5, GLASS_Z - 0.6)
		spot.transform = Transform3D(Basis(), from).looking_at(from + f.basis * dir, Vector3.UP)
		add_child(spot)
		_rays.append(spot)


## The two bays' parts, one mesh per material.
func _bay_meshes(acc: Dictionary, m: Dictionary) -> void:
	var g := Node3D.new()
	g.name = "Bays"
	add_child(g)
	var stone: Material = m.get("stone_piers", m.get("stone", null))
	var dark: Material = m.get("stone_blocks", m.get("stone_dark", null))
	var bronze: Material = m.get("bronze", null)
	_add_in(g, "Recess", _merge(acc.recess), dark)
	_add_in(g, "Trim", _merge(acc.trim), stone)
	if bronze != null:
		_add_in(g, "Bronze", _merge(acc.bronze), bronze)
	var glass: ShaderMaterial = null
	if ResourceLoader.exists(GLASS_SHADER_PATH):
		glass = ShaderMaterial.new()
		glass.shader = load(GLASS_SHADER_PATH)
		_obs.call("_hall_params", glass)
		glass.set_shader_parameter("size", Vector2(OPEN_W, HEAD - SILL))
		glass.set_shader_parameter("fan_to", (HEAD - TRANSOM) / (HEAD - SILL))
		_add_in(g, "Glass", _merge(acc.glass), glass, false)
	for f: Transform3D in acc.doors:
		_build_doors(g, f, bronze, glass)
	stats.doors = _doors.size()
	# Under Compatibility each face is converted on its own and the faces add up in sRGB: seen through
	# its front and back, the shaft veiled the window more than under Forward+ (artpass/bays/region.py:
	# 117 against 87 in red at 0.03, 80 at 0.6 times that, where the beam seen from the side vanished).
	var shaft_energy := 0.03 * (0.8 if _compat else 1.0)
	var shafts := _add_in(g, "Shafts", _merge(acc.shafts),
		_glow(Color.WHITE, shaft_energy, {"fade_top": 0.12, "fade_foot": 0.5, "edge": 0.9, "near_fade_from": 1.5, "near_fade_to": 5.0}))
	# At 0.07 the pool was a faint smudge on the dark marble (artpass/bays/v7-fwd/pool_b2.png).
	var pools := _add_in(g, "Pools", _merge(acc.pools), _glow(Color.WHITE, 0.12, {"fade_top": 0.45, "fade_foot": 0.45, "edge": 0.9}))
	for mi: MeshInstance3D in [shafts, pools]:
		_out(mi)
		_rays.append(mi)
	stats.bay_meshes = g.get_child_count()


## Painted trees from an atlas of grid cells: xforms stand each card on its foot, scaled to its width and
## height; customs give each its cell (x) and its phase in the wind (y); colours tint them.
func _impostors(parent: Node, node_name: String, tex_path: String, grid: Vector2, xforms: Array, customs: Array,
		colors: Array, params := {}) -> MultiMeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	quad.center_offset = Vector3(0, 0.5, 0)
	var tex: Texture2D = load(tex_path)
	var mat := ShaderMaterial.new()
	mat.shader = load(IMPOSTOR_SHADER_PATH)
	mat.set_shader_parameter("tex", tex)
	mat.set_shader_parameter("grid", grid)
	mat.set_shader_parameter("tex_size", Vector2(tex.get_width(), tex.get_height()))
	for k in params:
		mat.set_shader_parameter(k, params[k])
	var mmi := _multi(parent, node_name, quad, mat, [])
	var mm := mmi.multimesh
	mm.instance_count = 0
	mm.use_colors = true
	mm.use_custom_data = true
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, colors[i])
		mm.set_instance_custom_data(i, customs[i])
	stats.garden_instances += xforms.size()
	return mmi


# --- The vegetation kit (artpass/gardens/veg/) ----------------------------------------------------------

## Whether the kit is all there: the shaders, every tree's mesh, views and leaves, the bark, the hedges'
## surface and the clipped greenery's meshes.
func _veg_ready() -> bool:
	for path: String in [PLANT_SHADER_PATH, IMPOSTOR_SHADER_PATH, VEG_BARK_PATH, VEG_HEDGE_PATH % "", VEG_HEDGE_PATH % "_n",
			VEG_KIT_PATH % "fringe_tall", VEG_KIT_PATH % "fringe_low", VEG_KIT_PATH % "yew"]:
		if not ResourceLoader.exists(path):
			return false
	for kind: String in VEG_KINDS:
		var k: Dictionary = VEG_KINDS[kind]
		for v in (k.tops as Array).size():
			if not ResourceLoader.exists(VEG_TREE_PATH % [kind, v + 1]):
				return false
		if not ResourceLoader.exists(VEG_LEAVES_PATH % k.leaves):
			return false
		if float(k.span) > 0.0 and not (ResourceLoader.exists(VEG_IMP_PATH % [kind, ""]) and ResourceLoader.exists(VEG_IMP_PATH % [kind, "_n"])):
			return false
	return true


## The mesh in a GLB the kit exported. With `mats`, its surfaces take them by their material's name (bark,
## leaves, fruit, hedge), or failing a name by Blender's order; the mesh is shared, so a mesh given its
## materials is used for one thing only (the fringes take theirs as an override instead).
func _veg_mesh(path: String, mats := {}) -> Mesh:
	if _veg.meshes.has(path):
		return _veg.meshes[path]
	var root: Node = (load(path) as PackedScene).instantiate()
	var found := root.find_children("*", "MeshInstance3D", true, false)
	var mesh: Mesh = (found[0] as MeshInstance3D).mesh if not found.is_empty() else null
	root.free()
	if mesh != null and not mats.is_empty():
		var order := ["hedge", "leaves"] if mats.has("hedge") else ["bark", "leaves", "fruit"]
		var names: Array[String] = []
		for i in mesh.get_surface_count():
			var m := mesh.surface_get_material(i)
			var nm := m.resource_name if m != null else ""
			if not mats.has(nm):
				nm = order[i] if i < order.size() and mats.has(order[i]) else str(mats.keys()[0])
			mesh.surface_set_material(i, mats[nm])
			names.append(nm)
		stats["veg_surfaces_" + path.get_file().get_basename()] = names
	_veg.meshes[path] = mesh
	return mesh


## A material of assets/garden_plant.gdshader, lit as the gardens' others.
func _pmat(kind: int, tex_path: String, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(PLANT_SHADER_PATH)
	m.set_shader_parameter("kind", kind)
	if tex_path != "":
		m.set_shader_parameter("tex", load(tex_path))
	m.set_shader_parameter("core_dir", _core)
	m.set_shader_parameter("terrace_r", TERRACE_R - 0.3)
	m.set_shader_parameter("terrace_y", 1.45)
	m.set_shader_parameter("foot_y", GROUND_Y)
	if kind == 2 and not _compat:
		# Off the web, the clipped growth in clumps and the wind in its leaves (assets/garden_plant.gdshader lumps,
		# leaf_wind; the author at the telescope, 2026-10-16: « Les haies ont l'air du papier peint et devraient
		# bouger un peu au vent »).
		m.set_shader_parameter("lumps", 1.0)
		m.set_shader_parameter("leaf_wind", 1.0)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


## A kind's tree materials (bark, leaves, an orange's fruit), made once; `near`: they hand over to the far
## views past the near radius.
func _veg_tree_mats(kind: String, near: bool) -> Dictionary:
	if _veg.mats.has(kind):
		return _veg.mats[kind]
	var k: Dictionary = VEG_KINDS[kind]
	var common := {"sway": k.sway, "tree_h": (k.tops as Array).max(), "uplight": 0.45, "uplight_h": 5.0}
	if near:
		common.near_r = VEG_NEAR_R[0]
		common.band = VEG_BAND
	var bark := _pmat(0, VEG_BARK_PATH, common.merged({"tint": Vector3.ONE * 0.5}))
	var leaves := _pmat(1, VEG_LEAVES_PATH % k.leaves, common.merged({"tint": Vector3.ONE * float(k.tint), "flutter": 0.015}))
	var mats := {"bark": bark, "leaves": leaves, "fruit": _pmat(3, "", common.merged({"tint": Vector3(0.75, 0.22, 0.02)}))}
	if near:
		(_veg.near_mats as Array).append_array([bark, leaves])
	_veg.mats[kind] = mats
	return mats


## A clipped hedge's surface: the box tile on the three axes with its normal map, darker towards the foot
## over `foot_h`, tinted.
func _veg_hedge_mat(foot_h: float, tint: Vector3) -> ShaderMaterial:
	return _pmat(2, VEG_HEDGE_PATH % "", {"ntex": load(VEG_HEDGE_PATH % "_n"), "tile": 1.0, "bump": 0.9, "tint": tint,
		"foot_dark": 0.45, "foot_h": foot_h})


## The sprays fringing a hedge or a yew, from a leaves atlas, out to 60 m from the eye: further, under a
## few pixels, they would only shimmer.
func _veg_fringe_mat(atlas: String, tint: float, foot_h: float) -> ShaderMaterial:
	var m := _pmat(1, VEG_LEAVES_PATH % atlas, {"tint": Vector3.ONE * tint, "foot_dark": 0.45, "foot_h": foot_h,
		"near_r": FRINGE_R, "band": 6.0, "flutter": 0.006, "wrap": 0.3})
	if not _compat:
		m.set_shader_parameter("gusty", 0.035)  # pushed 3.5 cm downwind in a gust, rasterized
	(_veg.fringe_mats as Array).append(m)
	return m


## A MultiMesh whose instances carry a colour and custom data.
func _multi_cc(parent: Node, node_name: String, mesh: Mesh, mat: Material, xforms: Array, colors: Array,
		customs: Array) -> MultiMeshInstance3D:
	var mmi := _multi(parent, node_name, mesh, mat, [])
	var mm := mmi.multimesh
	mm.instance_count = 0
	mm.use_colors = true
	mm.use_custom_data = true
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, colors[i] if not colors.is_empty() else Color.WHITE)
		mm.set_instance_custom_data(i, customs[i] if not customs.is_empty() else Color(0, 0, 0, 0))
	stats.garden_instances += xforms.size()
	return mmi


## Instances of `mesh` in chunks `size` square, each chunk dropped once its middle is `reach` and its
## half-diagonal from the eye, as the material drops each instance past `reach` from its own place.
func _veg_chunks(parent: Node, node_name: String, mesh: Mesh, mat: Material, xforms: Array, colors: Array,
		customs: Array, size: float, reach: float) -> Array[MultiMeshInstance3D]:
	var groups := {}
	for i in xforms.size():
		var p: Vector3 = (xforms[i] as Transform3D).origin
		var key := Vector2i(floori(p.x / size), floori(p.z / size))
		if not groups.has(key):
			groups[key] = [[], [], []]
		var g: Array = groups[key]
		(g[0] as Array).append(xforms[i])
		(g[1] as Array).append(colors[i] if not colors.is_empty() else Color.WHITE)
		(g[2] as Array).append(customs[i] if not customs.is_empty() else Color(0, 0, 0, 0))
	var out: Array[MultiMeshInstance3D] = []
	for key: Vector2i in groups:
		var g: Array = groups[key]
		var mmi := _multi_cc(parent, "%s_%d_%d" % [node_name, key.x, key.y], mesh, mat, g[0], g[1], g[2])
		mmi.visibility_range_end = reach + size * 0.75
		out.append(mmi)
	return out


## Sprays along straight hedges: modules (hedge_kit.py's fringe_tall, 4 m, or fringe_low, 2 m) at the
## given places, in chunks shown near the eye only, gone from quality level 3.
func _veg_fringe(parent: Node, node_name: String, part: String, mat: Material, xforms: Array) -> void:
	var chunks := _veg_chunks(parent, node_name, _veg_mesh(VEG_KIT_PATH % part), mat, xforms, [], [], FRINGE_CHUNK, FRINGE_R)
	(_veg.fringe as Array).append_array(chunks)
	stats.veg_fringe_modules = int(stats.get("veg_fringe_modules", 0)) + xforms.size()


## The kit's trees of `kind` where painted cards would have stood (_impostors' arguments): each card's foot
## is a tree's, its height the card's times `fill` (the share of its cell the painted tree filled), its
## variant its cell (custom x), its phase in the wind kept (custom y); turned by its place, its tint the
## card's, narrowed. Returns the far views, one MultiMesh, the trees in the order given (the first "keep" of
## them stay from quality level 3); unless `far_only`, those within VEG_ZONE as meshes too, in chunks.
func _veg_trees(parent: Node, node_name: String, kind: String, xforms: Array, customs: Array, tints: Array,
		fill: float, far_only := false) -> MultiMeshInstance3D:
	var k: Dictionary = VEG_KINDS[kind]
	var tops: Array = k.tops
	var far_xf: Array[Transform3D] = []
	var far_c: Array[Color] = []
	var far_t: Array[Color] = []
	var by_variant := []
	for v in tops.size():
		by_variant.append([[], [], []])
	for i in xforms.size():
		var card: Transform3D = xforms[i]
		var custom: Color = customs[i]
		var variant := int(custom.r) % tops.size()
		var p := card.origin
		var s := card.basis.y.length() * fill / float(tops[variant])
		var yaw := fposmod(sin(p.x * 12.9898 + p.z * 78.233) * 43758.5453, TAU)
		var xf := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s), p)
		var g := 0.78 + 0.22 * clampf((tints[i] as Color).r, 0.0, 1.1)
		var tint := Color(g, g, g)
		far_xf.append(xf)
		far_c.append(Color(float(variant), custom.g, 0.0, 0.0))
		far_t.append(tint)
		if not far_only and Vector2(p.x, p.z).length() < VEG_ZONE:
			var b: Array = by_variant[variant]
			(b[0] as Array).append(xf)
			(b[1] as Array).append(tint)
			(b[2] as Array).append(Color(0.0, custom.g, 0.0, 0.0))
	var mats := _veg_tree_mats(kind, true)
	for v in tops.size():
		var b: Array = by_variant[v]
		if (b[0] as Array).is_empty():
			continue
		var mesh := _veg_mesh(VEG_TREE_PATH % [kind, v + 1], mats)
		(_veg.chunks as Array).append_array(_veg_chunks(parent, "%sNear%d" % [node_name, v + 1], mesh, null, b[0], b[1], b[2],
			VEG_CHUNK, VEG_NEAR_R[0]))
		stats.veg_near_trees = int(stats.get("veg_near_trees", 0)) + (b[0] as Array).size()
	return _veg_far(parent, node_name, kind, far_xf, far_c, far_t, not far_only)


## A kind's far views (assets/garden_impostor.gdshader, views 8) for the trees at `xforms` (turn and scale
## as their meshes'); `near`: they give way to the meshes within the near radius.
func _veg_far(parent: Node, node_name: String, kind: String, xforms: Array, customs: Array, tints: Array,
		near: bool) -> MultiMeshInstance3D:
	var k: Dictionary = VEG_KINDS[kind]
	var tex: Texture2D = load(VEG_IMP_PATH % [kind, ""])
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	quad.center_offset = Vector3(0, 0.5, 0)
	var mat := ShaderMaterial.new()
	mat.shader = load(IMPOSTOR_SHADER_PATH)
	var params := {"tex": tex, "ntex": load(VEG_IMP_PATH % [kind, "_n"]), "grid": Vector2(8, (k.tops as Array).size()),
		"tex_size": Vector2(tex.get_width(), tex.get_height()), "views": 8, "span": k.span, "aspect": k.aspect,
		"foot_v": VEG_FOOT_V, "near_r": VEG_NEAR_R[0] if near else 0.0, "band": VEG_BAND, "tint": Vector3.ONE * float(k.tint),
		"sway": k.sway, "uplight": 0.45, "uplight_h": 5.0, "foot_y": GROUND_Y, "core_dir": _core}
	for p in params:
		mat.set_shader_parameter(p, params[p])
	if near:
		(_veg.far_mats as Array).append(mat)
	var mmi := _multi_cc(parent, node_name, quad, mat, xforms, tints, customs)
	# The card is drawn the views' frame high, not the quad's metre: cull by the trees' real extent.
	if not xforms.is_empty():
		var lo: Vector3 = (xforms[0] as Transform3D).origin
		var hi := lo
		var top := 0.0
		for xf: Transform3D in xforms:
			lo = lo.min(xf.origin)
			hi = hi.max(xf.origin)
			top = maxf(top, xf.basis.y.length())
		var r := float(k.span) * top
		mmi.custom_aabb = AABB(lo - Vector3(r, 1.0, r), hi - lo + Vector3(2.0 * r, r + 2.0, 2.0 * r))
	return mmi


func _add_in(parent: Node, node_name: String, mesh: Mesh, mat: Material, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.material_override = mat
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## The shaft from the fanlight's rectangle (lo to hi, across x and up y) along `along`: its four long
## faces, each with UV.x across and UV.y from the glass (0) to the end (1).
func _shaft(lo: Vector3, hi: Vector3, along: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := [Vector3(lo.x, lo.y, lo.z), Vector3(hi.x, lo.y, lo.z), Vector3(hi.x, hi.y, lo.z), Vector3(lo.x, hi.y, lo.z)]
	for s in 4:
		var p0: Vector3 = c[s]
		var p1: Vector3 = c[(s + 1) % 4]
		var q0 := p0 + along
		var q1 := p1 + along
		var n := (p1 - p0).cross(along).normalized()
		for v: Array in [[p0, Vector2(0, 0)], [p1, Vector2(1, 0)], [q1, Vector2(1, 1)], [p0, Vector2(0, 0)], [q1, Vector2(1, 1)], [q0, Vector2(0, 1)]]:
			st.set_normal(n)
			st.set_uv(v[1])
			st.add_vertex(v[0])
	return st.commit()


# --- The terrace --------------------------------------------------------------------------------

func _build_terrace() -> void:
	var g := Node3D.new()
	g.name = "Terrace"
	_garden.add_child(g)
	var outer := float(_obs.get("outer_radius"))
	var paving := _gmat(1, Color(0.46, 0.43, 0.39), {"sheen": 0.04})
	var stone := _gmat(0, Color(0.58, 0.55, 0.5), {"uplight": 0.35, "base_y": GROUND_Y})
	# In detail, and lit more by its own lamps than by the core: at 0.35 and with pools 3.5 m wide
	# round lamps 3.1 m apart, the terrace was lit evenly all over and read as plastic
	# (artpass/bays/art7-fwd).
	for pair: Array in [[paving, PAVING_TEX_PATH], [stone, STONE_TEX_PATH]]:
		if ResourceLoader.exists(pair[1]):
			var m: ShaderMaterial = pair[0]
			m.set_shader_parameter("detail_tex", load(pair[1]))
			m.set_shader_parameter("stone_detail", 1.0)
			m.set_shader_parameter("core_energy", 0.22)
			m.set_shader_parameter("terrace_reach", 2.6)
			stats.stone = "detail"
	# The paving from the wall to the edge, over the +Z half round the hall (both bays look out over
	# it), its top 6 mm under the hall's floor where the two meet.
	_mesh(g, "Paving", _obs.call("ring_sector", outer + 0.1, TERRACE_R, 0.3, 0.0, PI, 96), paving, Transform3D(Basis(), Vector3(0, -0.306, 0)))
	# The retaining wall down to the parterre, and the balustrade's plinth and coping, in one mesh; the
	# turned balusters between them; a pedestal with a lamp every 7.5 degrees.
	var rail_r := TERRACE_R - 0.3
	# Each ring open over the ramp's head; under it, the wall stops at the paving's level.
	var stone_parts := []
	for ring: Array in [[TERRACE_R - 0.05, TERRACE_R + 0.6, -GROUND_Y + 0.25, GROUND_Y], [rail_r - 0.2, rail_r + 0.2, 0.18, 0.0],
			[rail_r - 0.22, rail_r + 0.22, 0.14, 1.0]]:
		var gap := _ramp_gap(float(ring[1]))
		for span: Vector2 in [Vector2(0.0, gap.x), Vector2(gap.y, PI)]:
			stone_parts.append([_obs.call("ring_sector", ring[0], ring[1], ring[2], span.x, span.y, maxi(4, int(96.0 * (span.y - span.x) / PI))),
				Transform3D(Basis(), Vector3(0, ring[3], 0))])
	var head := _ramp_gap(TERRACE_R + 0.6)
	stone_parts.append([_obs.call("ring_sector", TERRACE_R - 0.05, TERRACE_R + 0.6, -GROUND_Y, head.x, head.y, 8),
		Transform3D(Basis(), Vector3(0, GROUND_Y, 0))])
	# The ramp: its two sides in stone, a parapet 0.9 m high along each; its top in paving.
	var w := RAMP_HALF + 0.4
	var sides := SurfaceTool.new()
	sides.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx: float in [-1.0, 1.0]:
		_face(sides, [Vector3(sx * w, 0.0, RAMP_Z0), Vector3(sx * w, GROUND_Y, RAMP_Z1), Vector3(sx * w, GROUND_Y, RAMP_Z0)], Vector3(sx, 0, 0))
	stone_parts.append([sides.commit(), Transform3D()])
	var run := RAMP_Z1 - RAMP_Z0
	var slope := atan2(-GROUND_Y, run)
	for sx: float in [-1.0, 1.0]:
		var mid := Vector3(sx * (RAMP_HALF + 0.2), GROUND_Y * 0.5 + 0.45 / cos(slope), (RAMP_Z0 + RAMP_Z1) * 0.5)
		stone_parts.append([_box(Vector3(0.4, 0.9, run / cos(slope))), Transform3D(Basis(Vector3.RIGHT, slope), mid)])
		_solid(Vector2(mid.x, mid.z), Vector2(0.2, run * 0.5))
	_mesh(g, "Stone", _merge(stone_parts), stone)
	var top := SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	_face(top, [Vector3(-w, 0.0, RAMP_Z0), Vector3(w, 0.0, RAMP_Z0), Vector3(w, GROUND_Y, RAMP_Z1), Vector3(-w, GROUND_Y, RAMP_Z1)],
		Vector3(0.0, run, -GROUND_Y).normalized())
	_mesh(g, "Ramp", top.commit(), paving)
	# The kit made in Blender (artpass/gardens/blender/terrace_kit.py) when it is there: turned balusters
	# 0.82 m high (400 triangles; 120 from quality level 3), moulded pedestals, and iron lanterns whose
	# glass is lit, in place of the hall's low-poly balusters, plain boxes and glowing globes.
	var kit := ResourceLoader.exists(KIT_PATH % "baluster") and ResourceLoader.exists(KIT_PATH % "baluster_low") \
		and ResourceLoader.exists(KIT_PATH % "pedestal") and ResourceLoader.exists(KIT_PATH % "lantern_frame") \
		and ResourceLoader.exists(KIT_PATH % "lantern_glass")
	var baluster: Mesh = load(KIT_PATH % "baluster") if kit else _obs.call("low_poly", "baluster")
	var light: Mesh = load(KIT_PATH % "baluster_low") if kit else null
	# Off the web, the finer baluster (artpass/gardens/blender/baluster_fine.py, after the author's « je veux de
	# bien plus belles balustres », 2026-10-16): a square die and abacus, eased, and between them a pear turned
	# on 36 sides with its torus, astragal and ovolo; 6,608 triangles, 1,008 from quality level 3.
	var fine := kit and not _compat and ResourceLoader.exists(FINE_BALUSTER_PATH % "") \
		and ResourceLoader.exists(FINE_BALUSTER_PATH % "_low")
	if fine:
		baluster = fine_baluster("")
		light = fine_baluster("_low")
	stats.balusters = "fine" if fine else ("kit" if kit else "low_poly")
	var xf: Array[Transform3D] = []
	var step := deg_to_rad(7.5)
	var n := int(PI * rail_r / 0.3)
	for i in n:
		var a := PI * (i + 0.5) / n
		if absf(a / step - roundf(a / step)) * step * rail_r < (0.42 if kit else 0.35):
			continue  # the pedestal's place
		if absf(cos(a) * rail_r) < RAMP_HALF:
			continue  # the ramp's head
		var b := Basis(Vector3.UP, -a) if kit else Basis.from_scale(Vector3(1.6, 0.92, 1.6))
		xf.append(Transform3D(b, Vector3(cos(a) * rail_r, 0.18, sin(a) * rail_r)))
	if baluster != null and fine:
		# Each instance's custom data 1, a turned piece: the stone's detail wrapped round it, its mouldings
		# modelled by the light (assets/palace_garden.gdshader v_turned). Mapped as the walls are, they drew rings.
		# In stretches of 15 degrees (about 6 m), each its own MultiMesh: Godot picks a mesh's level of detail
		# by the MultiMesh's bounds, so the far stretches draw the import's lighter levels.
		var parts := {}
		for t in xf:
			var k := int(floorf(atan2(t.origin.z, t.origin.x) / deg_to_rad(15.0)))
			if not parts.has(k):
				var stretch: Array[Transform3D] = []
				parts[k] = stretch
			(parts[k] as Array).append(t)
		var keys := parts.keys()
		keys.sort()
		for k: int in keys:
			var turned := []
			turned.resize((parts[k] as Array).size())
			turned.fill(Color(1.0, 0.0, 0.0, 0.0))
			var bal := _multi_cc(g, "Balusters" if k == keys[0] else "Balusters%d" % k, baluster, stone, parts[k], [], turned)
			_lods.append([bal, baluster, light])
	elif baluster != null:
		var bal := _multi(g, "Balusters", baluster, stone, xf)
		if kit:
			_lods.append([bal, baluster, light])
	# Box colours are given as the albedos they replace, in sRGB; the shader takes them as linear.
	var stone_tint := Color(0.58, 0.55, 0.5).srgb_to_linear()
	var piers: Array[Transform3D] = []
	var lanterns: Array[Transform3D] = []
	# A pedestal every 7.5 degrees, but over the ramp's head; and one either side of the ramp's foot.
	var spots := []  # [angle, place]
	for j in range(1, int(PI / step)):
		var a := step * j
		if absf(cos(a) * rail_r) >= RAMP_HALF:
			spots.append([a, Vector3(cos(a) * rail_r, 0.0, sin(a) * rail_r)])
	for sx: float in [-1.0, 1.0]:
		var foot := Vector3(sx * (RAMP_HALF + 0.2), GROUND_Y, RAMP_Z1 + 0.32)
		spots.append([PI * 0.5, foot])
		_solid(Vector2(foot.x, foot.z), Vector2(0.32, 0.32))
	for spot: Array in spots:
		var a: float = spot[0]
		var at: Vector3 = spot[1]
		if kit:
			piers.append(Transform3D(Basis(Vector3.UP, -a), at))
			lanterns.append(Transform3D(Basis(Vector3.UP, -a), at + Vector3(0, 1.26, 0)))
		else:
			_fit.boxes.append(Transform3D(Basis(Vector3.UP, -a).scaled(Vector3(0.5, 1.2, 0.5)), at + Vector3(0, 0.6, 0)))
			_fit.box_tints.append(stone_tint)
			_fit.lamps.append(Transform3D(Basis.from_scale(Vector3.ONE * 0.24), at + Vector3(0, 1.38, 0)))
	if kit:
		_multi(g, "Pedestals", load(KIT_PATH % "pedestal"), stone, piers)
		_multi(g, "LanternFrames", load(KIT_PATH % "lantern_frame"), _gmat(0, Color(0.09, 0.08, 0.07), {"sheen": 0.35}), lanterns)
		# The glass flickers a little, each lantern at its own pace, as a flame would.
		_multi(g, "LanternGlass", load(KIT_PATH % "lantern_glass"), _gmat(5, Color.WHITE, {"flicker": 0.07}), lanterns)
		stats.terrace = "kit"
	else:
		stats.terrace = "boxes"
	# Orange trees in tubs along the terrace, clear of the windows' middles and of the ramp's head. With the
	# kit, clipped balls on clear stems, oranges in them, standing in the tubs (0.8 m), at 0.7 of their size.
	# The tubs are Versailles boxes made in Blender (artpass/gardens/blender/tub_kit.py) when they are there:
	# painted panels between iron corner posts, a ball on each; plain boxes otherwise.
	var tub_kit := ResourceLoader.exists(KIT_PATH % "tub_wood") and ResourceLoader.exists(KIT_PATH % "tub_iron")
	var tub_green := Color(0.16, 0.22, 0.2).srgb_to_linear()
	var tubs: Array[Transform3D] = []
	var oranges: Array = [[], []]
	var phases: Array = [[], []]
	for a_deg: float in [22.0, 40.0, 72.0, 108.0, 140.0, 158.0]:
		var a := deg_to_rad(a_deg)
		var at := Vector3(cos(a), 0.0, sin(a)) * (TERRACE_R - 1.8)
		_solid(Vector2(at.x, at.z), Vector2(0.6, -1.0))
		if tub_kit:
			tubs.append(Transform3D(Basis(Vector3.UP, -a), at))
		else:
			_fit.boxes.append(Transform3D(Basis(Vector3.UP, -a).scaled(Vector3.ONE * 0.8), at + Vector3(0, 0.4, 0)))
			_fit.box_tints.append(tub_green)
		if _veg.ok:
			var v := (oranges[0] as Array).size() + (oranges[1] as Array).size()
			(oranges[v % 2] as Array).append(Transform3D(Basis(Vector3.UP, a * 3.0).scaled(Vector3.ONE * 0.7), at + Vector3(0, 0.8, 0)))
			(phases[v % 2] as Array).append(Color(0.0, a_deg / 180.0, 0.0, 0.0))
		else:
			_fit.trees.append(Transform3D(Basis.from_scale(Vector3(1.5, 1.6, 1.5)), at + Vector3(0, 1.9, 0)))
			_fit.tree_tints.append(Color(0.07, 0.15, 0.05, 0.0))  # alpha 0: the shader adds oranges
	if tub_kit:
		var greens: Array[Color] = []
		greens.resize(tubs.size())
		greens.fill(tub_green)
		_multi(g, "TubWood", load(KIT_PATH % "tub_wood"), _gmat(0, Color.WHITE, {"uplight": 0.35, "base_y": GROUND_Y, "sheen": 0.1}), tubs, greens)
		_multi(g, "TubIron", load(KIT_PATH % "tub_iron"), _gmat(0, Color(0.09, 0.08, 0.07), {"sheen": 0.35}), tubs)
		stats.tubs = "kit"
	if _veg.ok:
		for v in 2:
			_multi_cc(g, "OrangeTrees%d" % (v + 1), _veg_mesh(VEG_TREE_PATH % ["orange", v + 1], _veg_tree_mats("orange", false)),
				null, oranges[v], [], phases[v])


## The hall's outside over the terrace, which was the dark face of the hall's own wall, lit from inside
## only (artpass/gardens/hall0-fwd): ashlar laid on it and floodlit from the terrace, a plinth, a
## pilaster at each of the hall's piers, an entablature under Upperside's cornice, and a surround, a
## keystone and a hood round each glazed bay. From one end of the terrace to the other (0 to PI).
func _build_facade() -> void:
	var outer := float(_obs.get("outer_radius"))
	var bay_count := int(_obs.get("bay_count"))
	var face := outer + 0.42                                 # 2 cm off the hall wall's face
	var r := face + FACADE_SKIN                              # the facade's face
	var top := float(_obs.get("_ceiling_y")) + 0.6 - 0.356   # under Upperside's cornice, 6 mm short
	var hw := OPEN_W * 0.5
	var head := HEAD + 0.45
	var bays: Array[float] = []
	for i: int in BAYS:
		bays.append(TAU * (i + 0.5) / bay_count)
	bays.sort()
	var parts := []
	# The skin and the plinth: up to the bays' heads, between them; above, all along.
	var spans: Array[Vector2] = []
	var from := 0.0
	for a in bays:
		spans.append(Vector2(from, a))
		from = a
	spans.append(Vector2(from, PI))
	for k in spans.size():
		var a0 := spans[k].x + (hw / r if k > 0 else 0.0)
		var a1 := spans[k].y - (hw / r if k < spans.size() - 1 else 0.0)
		var segs := maxi(4, int(64.0 * (a1 - a0) / PI))
		parts.append([_obs.call("ring_sector", face, r, head, a0, a1, segs), Transform3D()])
		var p0 := spans[k].x + ((hw + 0.45) / r if k > 0 else 0.0)
		var p1 := spans[k].y - ((hw + 0.45) / r if k < spans.size() - 1 else 0.0)
		parts.append([_obs.call("ring_sector", r - 0.02, r + 0.25, 0.9, p0, p1, segs), Transform3D()])
	parts.append([_obs.call("ring_sector", face, r, top - head, 0.0, PI, 96), Transform3D(Basis(), Vector3(0, head, 0))])
	# The entablature: an architrave, a frieze and a cornice out to Upperside's.
	parts.append([_obs.call("ring_sector", r - 0.02, r + 0.16, 0.4, 0.0, PI, 96), Transform3D(Basis(), Vector3(0, top - 1.1, 0))])
	parts.append([_obs.call("ring_sector", r - 0.02, r + 0.1, 0.52, 0.0, PI, 96), Transform3D(Basis(), Vector3(0, top - 0.7, 0))])
	parts.append([_obs.call("ring_sector", r - 0.02, outer + 1.25, 0.18, 0.0, PI, 96), Transform3D(Basis(), Vector3(0, top - 0.18, 0))])
	# A pilaster at each pier, on a base, under a capital; flat boxes sunk 3 cm into the curved face.
	for i in range(bay_count / 2 + 1):
		var f := _radial(TAU * i / bay_count, r, 0.0)
		parts.append(_span(f, Vector3(-0.8, 0.0, -0.32), Vector3(0.8, 0.9, 0.03)))
		parts.append(_span(f, Vector3(-0.65, 0.9, -0.25), Vector3(0.65, top - 1.6, 0.03)))
		parts.append(_span(f, Vector3(-0.85, top - 1.6, -0.34), Vector3(0.85, top - 1.1, 0.03)))
	# Round each bay: its reveals through the facade (6 mm back from the hall's own, which they meet),
	# jambs and a lintel, a keystone, a hood, and a sill.
	for a in bays:
		var f := _radial(a, r, 0.0)
		for sx: float in [-1.0, 1.0]:
			parts.append(_span(f, Vector3(minf(sx * (hw + 0.006), sx * (hw + 0.1)), 0.0, -0.01),
				Vector3(maxf(sx * (hw + 0.006), sx * (hw + 0.1)), head, FACADE_SKIN + 0.05)))
			parts.append(_span(f, Vector3(minf(sx * hw, sx * (hw + 0.45)), 0.0, -0.12), Vector3(maxf(sx * hw, sx * (hw + 0.45)), head, 0.03)))
		parts.append(_span(f, Vector3(-hw, HEAD + 0.006, -0.01), Vector3(hw, head, FACADE_SKIN + 0.05)))
		parts.append(_span(f, Vector3(-hw, HEAD, -0.12), Vector3(hw, head, 0.03)))
		parts.append(_span(f, Vector3(-0.25, HEAD - 0.08, -0.2), Vector3(0.25, head + 0.12, 0.03)))
		parts.append(_span(f, Vector3(-hw - 0.7, head, -0.3), Vector3(hw + 0.7, head + 0.25, 0.03)))
		parts.append(_span(f, Vector3(-hw - 0.1, 0.0, -0.15), Vector3(hw + 0.1, SILL - 0.006, FACADE_SKIN + 0.05)))
	# At 0.9 the drum came out as saturated as the terrace's lit balustrade (artpass/gardens/hall1-fwd).
	var stone := _gmat(0, Color(0.56, 0.53, 0.48), {"uplight": 0.65, "base_y": 0.0, "sheen": 0.04, "wall_top": top + 1.0,
		"ashlar": Vector2(1.5, 0.75)})
	if ResourceLoader.exists(STONE_TEX_PATH):
		stone.set_shader_parameter("detail_tex", load(STONE_TEX_PATH))
		stone.set_shader_parameter("stone_detail", 1.0)
	_mesh(_garden, "Facade", _merge(parts), stone)
	stats.facade_parts = parts.size()


# --- Below: the parterre, the trees -------------------------------------------------------------

func _build_parterre(rng: RandomNumberGenerator) -> void:
	var g := Node3D.new()
	g.name = "Parterre"
	_garden.add_child(g)
	var ground := PlaneMesh.new()
	# Out to the city's strips (CITY_R), under the woods.
	ground.size = Vector2(3300.0, 1700.0)
	var ground_mat := _gmat(2, Color(0.62, 0.57, 0.47))
	_mesh(g, "Ground", ground, ground_mat, Transform3D(Basis(), Vector3(0, GROUND_Y, 810.0)))
	# Lamp posts in bronze down the middle walk, where the shader's walk lamps are (walk_x, lamp_step).
	var lz := 36.0
	while lz <= 176.0:
		for side: float in [-1.0, 1.0]:
			_lamp(Vector3(side * 7.0, GROUND_Y, lz), 3.2, 0.45, Vector3(0.14, 3.0, 0.14), Color(0.2, 0.18, 0.15).srgb_to_linear())
			_solid(Vector2(side * 7.0, lz), Vector2(0.2, -1.0))
		lz += 14.0
	var foliage := _gmat(3, Color.WHITE)
	if parterre_kit and _build_parterre_kit(g, ground_mat):
		stats.parterre = "kit"
	else:
		_build_edging(g, foliage)
		stats.parterre = "drawn"
	# Cypresses down both sides of the parterre, and along the canal: painted when the atlas is there, or
	# the kit's. Its cards' own draws (cell, phase, tint) come from a generator of their own, so that the
	# layout after them stays the same either way.
	var painted := (ResourceLoader.exists(CYPRESS_TEX_PATH) and ResourceLoader.exists(IMPOSTOR_SHADER_PATH)) or bool(_veg.ok)
	var cards := RandomNumberGenerator.new()
	cards.seed = SEED + 1
	var cyp: Array[Transform3D] = []
	var cyp_custom: Array[Color] = []
	var cyp_tint: Array[Color] = []
	for side: float in [-1.0, 1.0]:
		for run: Array in [[15, 10.0, 13.0, 70.0, 34.0, 9.0, 2.2], [17, 9.0, 11.0, 26.0, 172.0, 10.0, 2.0]]:
			for i in int(run[0]):
				var h := rng.randf_range(run[1], run[2])
				var at := Vector3(side * float(run[3]), GROUND_Y, float(run[4]) + float(run[5]) * i)
				var tint := Color(0.05, 0.1, 0.06).lerp(Color(0.07, 0.13, 0.07), rng.randf())
				_solid(Vector2(at.x, at.z), Vector2(0.9, -1.0))
				if painted:
					var card_h := h / 0.99
					cyp.append(Transform3D(Basis.from_scale(Vector3(card_h * 0.25, card_h, 1.0)), at))
					cyp_custom.append(Color(float(cards.randi_range(0, 3)), cards.randf(), 0, 0))
					var v := cards.randf_range(0.75, 1.1)
					cyp_tint.append(Color(v, v, v))
				else:
					_fit.trees.append(Transform3D(Basis.from_scale(Vector3(float(run[6]), h, float(run[6]))), at + Vector3(0, h * 0.5, 0)))
					_fit.tree_tints.append(tint)
	if _veg.ok:
		# The card stood the tree's height over 0.99.
		_veg_trees(g, "Cypresses", "cypress", cyp, cyp_custom, cyp_tint, 0.99)
		stats.trees = "kit"
	elif painted:
		_impostors(g, "Cypresses", CYPRESS_TEX_PATH, Vector2(4, 1), cyp, cyp_custom, cyp_tint, {"energy": 0.55, "sway": 0.25})
		stats.trees = "painted"
	else:
		stats.trees = "meshes"
	# The bosquets: masses of round trees either side, out to the palace's wings, 80 m off and more, in
	# fewer facets than the near trees. Every other tree goes after the rest, so that showing the first
	# half (quality level 3) thins both sides evenly.
	var keep: Array[Transform3D] = []
	var keep_tint: Array[Color] = []
	var extra: Array[Transform3D] = []
	var extra_tint: Array[Color] = []
	var keep_custom: Array[Color] = []
	var extra_custom: Array[Color] = []
	var painted_limes := (ResourceLoader.exists(TREES_TEX_PATH) and ResourceLoader.exists(IMPOSTOR_SHADER_PATH)) or bool(_veg.ok)
	for side: float in [-1.0, 1.0]:
		var z := 30.0
		while z < 330.0:
			var x := 82.0
			while x < 200.0:
				var w := rng.randf_range(7.0, 10.0)
				var h := rng.randf_range(8.0, 12.0)
				var at := Vector3(side * (x + rng.randf_range(-3.0, 3.0)), GROUND_Y + 3.0 + h * 0.5, z + rng.randf_range(-3.0, 3.0))
				var c := Color(0.06, 0.12, 0.05).lerp(Color(0.11, 0.16, 0.06), rng.randf())
				# The maze, the orchard and the avenues take their place (_build_grounds); the draws
				# above are made all the same, so that the trees left stand where they stood.
				if _in_the_way(at, 2.0):
					x += rng.randf_range(9.0, 12.0)
					continue
				_solid(Vector2(at.x, at.z), Vector2(0.7, -1.0))
				var xf := Transform3D(Basis.from_scale(Vector3(w, h, w)), at)
				if painted_limes:
					# The whole tree, its 3 m of trunk and its crown, from the foot.
					var card_h := (3.0 + h) / 0.977
					xf = Transform3D(Basis.from_scale(Vector3(card_h, card_h, 1.0)), Vector3(at.x, GROUND_Y, at.z))
					var v := cards.randf_range(0.6, 1.0)
					c = Color(v, v, v)
				if keep.size() == extra.size():
					keep.append(xf)
					keep_tint.append(c)
					keep_custom.append(Color(float(cards.randi_range(0, 3)), cards.randf(), 0, 0))
				else:
					extra.append(xf)
					extra_tint.append(c)
					extra_custom.append(Color(float(cards.randi_range(0, 3)), cards.randf(), 0, 0))
				x += rng.randf_range(9.0, 12.0)
			z += rng.randf_range(9.0, 12.0)
	var bosquets: MultiMeshInstance3D
	if _veg.ok:
		bosquets = _veg_trees(g, "Bosquets", "linden", keep + extra, keep_custom + extra_custom, keep_tint + extra_tint, 0.977)
	elif painted_limes:
		bosquets = _impostors(g, "Bosquets", TREES_TEX_PATH, Vector2(2, 2), keep + extra, keep_custom + extra_custom,
			keep_tint + extra_tint, {"energy": 0.45, "sway": 0.18})
	else:
		bosquets = _multi(g, "Bosquets", _sphere(8, 4), foliage, keep + extra, keep_tint + extra_tint)
	bosquets.set_meta("keep", keep.size())
	_thin.append(bosquets)


## The parterre modelled (PARTERRE_GLB_PATH): each compartment's broderie and bed of box, its yews, the
## rider's solids round its bed, and the ground's tiles and occlusion; false, with nothing built, when a
## part is missing.
func _build_parterre_kit(g: Node3D, ground: ShaderMaterial) -> bool:
	var paths: Array[String] = [PARTERRE_GLB_PATH, PARTERRE_AO_PATH, PLANT_SHADER_PATH, VEG_HEDGE_PATH % "", VEG_HEDGE_PATH % "_n"]
	for k: String in ["walk", "brick", "lawn"]:
		paths.append(GROUND_TEX_PATH % k)
	for path in paths:
		if not ResourceLoader.exists(path):
			return false
	var meshes := {}
	var glb := PARTERRE_RTX_GLB_PATH if not _compat and ResourceLoader.exists(PARTERRE_RTX_GLB_PATH) else PARTERRE_GLB_PATH
	stats.parterre_glb = glb.get_file()
	var root: Node = (load(glb) as PackedScene).instantiate()
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		meshes[String(mi.name)] = mi.mesh
	root.free()
	for nm: String in ["broderie_plain", "broderie_notched", "topiary_0", "topiary_1", "topiary_2"]:
		if not meshes.has(nm):
			return false
	# The box clipped close: a finer tile than the hedges' (1 m); its occlusion is in the vertex colour.
	var box := _pmat(2, VEG_HEDGE_PATH % "", {"ntex": load(VEG_HEDGE_PATH % "_n"), "tile": 0.5, "bump": 0.9,
		"tint": Vector3(0.95, 1.0, 0.9)})
	var yew := _pmat(2, VEG_HEDGE_PATH % "", {"ntex": load(VEG_HEDGE_PATH % "_n"), "tile": 0.8, "bump": 0.9,
		"tint": Vector3(0.7, 0.85, 0.7), "uplight": 0.25, "uplight_h": 2.5})
	# The beds' mounds of low plants in flower, the petals in the mesh's colours (make_parterre.py).
	# At 0.45 the beds read as low box with a few flowers (live-07): in bloom, they are mostly flowers.
	var flowers := _pmat(2, VEG_HEDGE_PATH % "", {"ntex": load(VEG_HEDGE_PATH % "_n"), "tile": 0.35, "bump": 0.6,
		"tint": Vector3(0.72, 0.86, 0.5), "flowers": 0.8, "flower_plane": 1.0})
	var yews: Array = [[], [], []]
	# The yews' turns from a generator of their own, so that the layout after them stays as it was.
	var turn := RandomNumberGenerator.new()
	turn.seed = SEED + 2
	for i in PARTERRE_LAYOUT.LAYOUT.size():
		var place: Array = PARTERRE_LAYOUT.LAYOUT[i]
		var variant: String = place[0]
		var c := Vector2(float(place[1]), float(place[2]))
		var m := Vector2(float(place[3]), float(place[4]))
		# The variant's frame: x along, y across as glTF's -z (make_parterre.py), to the world's (x, z).
		var frame := Transform3D(Basis.from_scale(Vector3(m.x, 1.0, -m.y)), Vector3(c.x, GROUND_Y, c.y))
		_mesh(g, "Broderie%d" % i, meshes["broderie_" + variant], box, frame)
		if meshes.has("beds_" + variant):
			_mesh(g, "Beds%d" % i, meshes["beds_" + variant], flowers, frame)
		for y: Array in PARTERRE_LAYOUT.YEWS[variant]:
			(yews[int(y[2])] as Array).append(Transform3D(Basis(Vector3.UP, turn.randf() * TAU),
				Vector3(c.x + m.x * float(y[0]), GROUND_Y, c.y + m.y * float(y[1]))))
		for s: Array in PARTERRE_LAYOUT.SOLIDS[variant]:
			_solid(Vector2(c.x + m.x * float(s[0]), c.y + m.y * float(s[1])), Vector2(float(s[2]), float(s[3])))
	for k in 3:
		_multi(g, "Topiary%d" % k, meshes["topiary_%d" % k], yew, yews[k])
	ground.set_shader_parameter("parterre_kit", 1.0)
	ground.set_shader_parameter("parterre_ao", load(PARTERRE_AO_PATH))
	for k: String in ["walk", "brick", "lawn"]:
		ground.set_shader_parameter(k + "_tex", load(GROUND_TEX_PATH % k))
	if not _compat:
		# Off the web, the crushed brick as fine as it is laid, its pieces 2 cm at most rather than the 7 cm stones
		# a 70 cm tile made of them (the author, 2026-10-16, from the terrace: « la vue de loin est pas terrible »).
		ground.set_shader_parameter("tile_span", Vector3(1.6, 0.2, 2.4))
		ground.set_shader_parameter("brick_macro", 0.3)
	return true


## Without the modelled parterre: the compartments' box edging in relief, and a clipped yew at each
## corner (as the shader draws them: 52 x 28 m, from 10 m off the middle walk, every 32 m from z = 30).
func _build_edging(g: Node3D, foliage: Material) -> void:
	var hedges: Array[Transform3D] = []
	var hedge_tint: Array[Color] = []
	var yews: Array[Transform3D] = []
	var yew_tint: Array[Color] = []
	# With the kit: the edging's sprays, a 2 m module at a time, and the yews clipped cones on their foot.
	var fringe: Array[Transform3D] = []
	var clipped: Array[Transform3D] = []
	for side: float in [-1.0, 1.0]:
		for c in 4:
			var x0 := side * 10.0
			var x1 := side * 62.0
			var z0 := 30.0 + 32.0 * c
			var z1 := z0 + 28.0
			var cx := (x0 + x1) * 0.5
			var cz := (z0 + z1) * 0.5
			for e: Array in [[Vector3(cx, 0, z0 + 1.0), Vector3(50.0, 0.7, 0.7)], [Vector3(cx, 0, z1 - 1.0), Vector3(50.0, 0.7, 0.7)],
					[Vector3(x0 + side * 1.0, 0, cz), Vector3(0.7, 0.7, 26.0)], [Vector3(x1 - side * 1.0, 0, cz), Vector3(0.7, 0.7, 26.0)]]:
				var at: Vector3 = e[0]
				var size: Vector3 = e[1]
				hedges.append(Transform3D(Basis.from_scale(size), Vector3(at.x, GROUND_Y + 0.35, at.z)))
				hedge_tint.append(Color(0.06, 0.13, 0.05))
				_solid(Vector2(at.x, at.z), Vector2(size.x, size.z) * 0.5)
				var length := maxf(size.x, size.z)
				var n := roundi(length / 2.0)
				for m in n:
					var u := -length * 0.5 + (m + 0.5) * length / n
					if size.x > size.z:
						fringe.append(Transform3D(Basis.from_scale(Vector3(length / n / 2.0, 1.0, 1.0)), Vector3(at.x + u, GROUND_Y, at.z)))
					else:
						fringe.append(Transform3D(Basis(Vector3.UP, PI * 0.5).scaled(Vector3(1.0, 1.0, length / n / 2.0)), Vector3(at.x, GROUND_Y, at.z + u)))
			for corner: Vector2 in [Vector2(x0 + side, z0 + 1), Vector2(x1 - side, z0 + 1), Vector2(x0 + side, z1 - 1), Vector2(x1 - side, z1 - 1)]:
				yews.append(Transform3D(Basis.from_scale(Vector3(1.4, 3.6, 1.4)), Vector3(corner.x, GROUND_Y + 1.8, corner.y)))
				yew_tint.append(Color(0.05, 0.11, 0.06))
				clipped.append(Transform3D(Basis(Vector3.UP, corner.x * 0.37 + corner.y * 0.91), Vector3(corner.x, GROUND_Y, corner.y)))
				_solid(corner, Vector2(0.7, -1.0))
	if _veg.ok:
		_multi(g, "BoxEdging", _box(Vector3.ONE), _veg_hedge_mat(0.7, Vector3(0.95, 1.0, 0.9)), hedges)
		_veg_fringe(g, "BoxEdgingFringe", "fringe_low", _veg_fringe_mat("pear", 0.28, 0.7), fringe)
		var yew := _veg_mesh(VEG_KIT_PATH % "yew", {"hedge": _veg_hedge_mat(3.6, Vector3(0.7, 0.85, 0.7)),
			"leaves": _veg_fringe_mat("pear", 0.35, 3.6)})
		_multi(g, "Yews", yew, null, clipped)
	else:
		_multi(g, "BoxEdging", _box(Vector3.ONE), foliage, hedges, hedge_tint)
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.5
		cone.height = 1.0
		cone.radial_segments = 8
		cone.rings = 1
		_multi(g, "Yews", cone, foliage, yews, yew_tint)


# --- The grounds: the maze, the orchard, the avenues, the woods --------------------------------

## Whether something at `at` would stand in the maze, the orchard, or an avenue's way (its rows of
## trees and 2 m more), `margin` more round them.
static func _in_the_way(at: Vector3, margin: float) -> bool:
	var p := Vector2(at.x, at.z)
	if MAZE_RECT.grow(margin).has_point(p) or ORCHARD_RECT.grow(margin).has_point(p):
		return true
	return _avenue_offset(p) < AVENUE_HALF + 2.0 + margin


## How far p (x, z) is from the nearest avenue's middle line, ahead of the basin (INF behind it).
static func _avenue_offset(p: Vector2) -> float:
	var best := INF
	for deg: float in AVENUES:
		for side: float in [-1.0, 1.0]:
			var a := deg_to_rad(deg) * side
			var dir := Vector2(sin(a), cos(a))
			var d := p - AVENUE_FROM
			if d.dot(dir) > 0.0:
				best = minf(best, absf(d.cross(dir)))
	return best


func _build_grounds() -> void:
	var g := Node3D.new()
	g.name = "Grounds"
	_garden.add_child(g)
	# Draws of their own, so that the parterre, the bosquets and the city stay as they were.
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 2
	var pools: Array[Transform3D] = []
	_build_maze(g, rng, pools)
	_build_orchard(g, rng, pools)
	# Lamplight on the ground round the maze's and the orchard's lamps, added over it: the ground's
	# shader knows only the parterre's walk lamps and the terrace's.
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	_multi(g, "LampPools", plane, _glow(Color(1.0, 0.72, 0.42), 0.32, {"fade_top": 0.5, "fade_foot": 0.5, "edge": 1.0}), pools)
	# A clipped hedge across the palace's forecourt, 30 m short of it, where the ride ends on the
	# garden's axis (RIDE_R): the rider meets a hedge there, not an unseen wall.
	var forecourt := Rect2(-60.0, 398.0, 120.0, 1.4)
	var hedge := [Transform3D(Basis.from_scale(Vector3(forecourt.size.x, 1.6, forecourt.size.y)), Vector3(0.0, GROUND_Y + 0.8, forecourt.get_center().y))]
	if not _compat:
		# Off the web, a railing of forged iron there instead: from the garden, the hedge hid the palace's ground
		# floor (the author at the telescope, 2026-10-16: « LE PALAIS est barre par une haie!!! »).
		_build_forecourt_railing(g, forecourt)
	elif _veg.ok:
		_multi(g, "Forecourt", _box(Vector3.ONE), _veg_hedge_mat(1.6, Vector3(0.85, 0.95, 0.85)), hedge)
		# The maze's 4 m modules of sprays, lowered and widened to this hedge.
		var fringe: Array[Transform3D] = []
		for m in int(forecourt.size.x / 4.0):
			fringe.append(Transform3D(Basis.from_scale(Vector3(1.0, 1.6 / 2.4, forecourt.size.y / 1.1)),
				Vector3(forecourt.position.x + (m + 0.5) * 4.0, GROUND_Y, forecourt.get_center().y)))
		_veg_fringe(g, "ForecourtFringe", "fringe_tall", _veg_fringe_mat("cypress", 0.55, 1.6), fringe)
	else:
		_multi(g, "Forecourt", _box(Vector3.ONE), _gmat(3, Color.WHITE), hedge, [Color(0.05, 0.11, 0.05)])
	_solid(forecourt.get_center(), forecourt.size * 0.5)
	var far := Node3D.new()
	far.name = "Far"
	g.add_child(far)
	_far.append(far)
	_build_avenues(g, rng)
	_build_woods(far, rng)


## The forecourt's railing, off the web, where the ride ends: square bars 13 cm apart, 1.9 m high, with gilded
## spear heads; a rail near the top and one near the foot; a post every 4 m with a gilded ball. The palace's
## ground floor shows between the bars, as a royal court's through its gate.
func _build_forecourt_railing(g: Node3D, r: Rect2) -> void:
	const H := 1.9
	const PER := 31               # bars from one post to the next: 13 cm apart
	const POST := 4.0
	var z := r.get_center().y
	var iron := _gmat(0, Color(0.07, 0.07, 0.075), {"sheen": 0.3, "metal": 0.6})
	var gilt := _gmat(0, Color(0.78, 0.6, 0.3), {"sheen": 0.8, "metal": 1.0})
	var spear := CylinderMesh.new()
	spear.top_radius = 0.0
	spear.bottom_radius = 0.026
	spear.height = 0.13
	spear.radial_segments = 4
	spear.rings = 1
	var ball := SphereMesh.new()
	ball.radius = 0.065
	ball.height = 0.13
	var bars: Array[Transform3D] = []
	var tips: Array[Transform3D] = []
	var balls: Array[Transform3D] = []
	var n := int(round(r.size.x / POST)) * PER
	for i in n + 1:
		var x := r.position.x + r.size.x * i / n
		var post := i % PER == 0
		var w := 0.06 if post else 0.02
		var top := H + (0.12 if post else 0.0)
		bars.append(Transform3D(Basis.from_scale(Vector3(w, top, w)), Vector3(x, GROUND_Y + top * 0.5, z)))
		if post:
			balls.append(Transform3D(Basis(), Vector3(x, GROUND_Y + top + 0.06, z)))
		else:
			tips.append(Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3(x, GROUND_Y + H + 0.06, z)))
	for y: float in [0.16, H - 0.14]:
		bars.append(Transform3D(Basis.from_scale(Vector3(r.size.x, 0.045, 0.03)), Vector3(r.get_center().x, GROUND_Y + y, z)))
	_multi(g, "ForecourtRailing", _box(Vector3.ONE), iron, bars)
	_multi(g, "ForecourtSpears", spear, gilt, tips)
	_multi(g, "ForecourtBalls", ball, gilt, balls)


## The maze's lanterns' light on its hedges (assets/garden_plant.gdshader, lantern_map), every
## LANTERN_TEXEL metres over MAZE_RECT: the lanterns within LANTERN_REACH whose light no hedge stops, each
## falling off as the inverse square (and to nothing at the reach). A hedge stands on every side of a cell
## with no passage, so a ray from a lantern is stopped where it crosses such a side. R and G: the light's
## mean way to its lanterns (0.5 + 0.5 x, 0.5 + 0.5 z); B: the square root of its strength over
## LANTERN_FULL. The cells where it shows on the walk (a strength over LANTERN_SEEN) are put in `lit`.
const LANTERN_TEXEL := 0.5
const LANTERN_REACH := 5.5
const LANTERN_FULL := 2.0       # 1/m²: a lantern's light 0.4 m off, where the nearest hedge faces it
const LANTERN_ENERGY := 1.2
const LANTERN_SEEN := 0.004     # of LANTERN_FULL: a pool's light there is under a thousandth of white
const LANTERN_POOL := 0.32      # the pools' energy, as the square pools before them


func _lantern_map(nx: int, nz: int, to_x: PackedByteArray, to_z: PackedByteArray, lanterns: PackedVector2Array, lit: Dictionary) -> ImageTexture:
	var w := int(MAZE_RECT.size.x / LANTERN_TEXEL)
	var h := int(MAZE_RECT.size.y / LANTERN_TEXEL)
	var x0 := MAZE_RECT.position.x
	var z0 := MAZE_RECT.position.y
	var e := PackedFloat32Array()
	e.resize(w * h)
	e.fill(0.0)
	var wx := e.duplicate()
	var wz := e.duplicate()
	var r_px := ceili(LANTERN_REACH / LANTERN_TEXEL)
	var reach2 := LANTERN_REACH * LANTERN_REACH
	for lamp in lanterns:
		var lx := int((lamp.x - x0) / LANTERN_TEXEL)
		var lz := int((lamp.y - z0) / LANTERN_TEXEL)
		for tz in range(maxi(0, lz - r_px), mini(h, lz + r_px + 1)):
			var pz := z0 + (tz + 0.5) * LANTERN_TEXEL
			for tx in range(maxi(0, lx - r_px), mini(w, lx + r_px + 1)):
				var px := x0 + (tx + 0.5) * LANTERN_TEXEL
				var dx := px - lamp.x
				var dz := pz - lamp.y
				var d2 := dx * dx + dz * dz
				if d2 > reach2 or not _maze_sees(lamp, Vector2(px, pz), nx, nz, to_x, to_z):
					continue
				var f := 1.0 - d2 / reach2
				var s := f * f / (d2 + 0.25)
				var d := sqrt(d2) + 1e-4
				var i := tx + tz * w
				e[i] += s
				wx[i] -= dx / d * s
				wz[i] -= dz / d * s
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for tz in h:
		for tx in w:
			var i := tx + tz * w
			var s := e[i]
			var way := Vector2(wx[i], wz[i]) / maxf(s, 1e-6)
			img.set_pixel(tx, tz, Color(0.5 + 0.5 * way.x, 0.5 + 0.5 * way.y, sqrt(minf(s / LANTERN_FULL, 1.0)), 1.0))
			if s > LANTERN_SEEN * LANTERN_FULL:
				lit[int((tx + 0.5) * LANTERN_TEXEL / MAZE_CELL) + int((tz + 0.5) * LANTERN_TEXEL / MAZE_CELL) * nx] = true
	return ImageTexture.create_from_image(img)


## Whether a lantern at a sees the point b in the maze: no side of a cell without a passage between them.
func _maze_sees(a: Vector2, b: Vector2, nx: int, nz: int, to_x: PackedByteArray, to_z: PackedByteArray) -> bool:
	var x0 := MAZE_RECT.position.x
	var z0 := MAZE_RECT.position.y
	var i := int(floorf((a.x - x0) / MAZE_CELL))
	var j := int(floorf((a.y - z0) / MAZE_CELL))
	var ib := int(floorf((b.x - x0) / MAZE_CELL))
	var jb := int(floorf((b.y - z0) / MAZE_CELL))
	var d := b - a
	var si := 1 if d.x > 0.0 else -1
	var sj := 1 if d.y > 0.0 else -1
	var tx := INF if is_zero_approx(d.x) else ((x0 + (i + (1 if si > 0 else 0)) * MAZE_CELL) - a.x) / d.x
	var tz := INF if is_zero_approx(d.y) else ((z0 + (j + (1 if sj > 0 else 0)) * MAZE_CELL) - a.y) / d.y
	var step_x := INF if is_zero_approx(d.x) else MAZE_CELL / absf(d.x)
	var step_z := INF if is_zero_approx(d.y) else MAZE_CELL / absf(d.y)
	while i != ib or j != jb:
		if tx < tz:
			var lo := mini(i, i + si)
			if lo < 0 or lo >= nx - 1 or to_x[lo + j * nx] == 0:
				return false
			i += si
			tx += step_x
		else:
			var lo := mini(j, j + sj)
			if lo < 0 or lo >= nz - 1 or to_z[i + lo * nx] == 0:
				return false
			j += sj
			tz += step_z
		if minf(tx, tz) > 1.0 and (i != ib or j != jb):
			return false
	return true


## A hedge maze in the first of the left-hand bosquets, in cells MAZE_CELL square, carved by a
## depth-first walk from its entrance on the parterre's side; a round temple in its middle, and the way
## there lit: lamplight on the ground of each of its cells, a lantern in every other.
func _build_maze(g: Node3D, rng: RandomNumberGenerator, pools: Array[Transform3D]) -> void:
	var nx := int(MAZE_RECT.size.x / MAZE_CELL)
	var nz := int(MAZE_RECT.size.y / MAZE_CELL)
	var x0 := MAZE_RECT.position.x
	var z0 := MAZE_RECT.position.y
	# Passages from each cell to its +x neighbour and to its +z one.
	var to_x := PackedByteArray()
	to_x.resize(nx * nz)
	to_x.fill(0)
	var to_z := PackedByteArray()
	to_z.resize(nx * nz)
	to_z.fill(0)
	var seen := PackedByteArray()
	seen.resize(nx * nz)
	seen.fill(0)
	# The entrance: the cell on the parterre's side (+x), one row from the terrace's end.
	var door := nx - 1 + nx
	var stack: Array[int] = [door]
	seen[door] = 1
	while not stack.is_empty():
		var c: int = stack.back()
		var i := c % nx
		var j := c / nx
		var next: Array[int] = []
		if i > 0 and seen[c - 1] == 0:
			next.append(c - 1)
		if i < nx - 1 and seen[c + 1] == 0:
			next.append(c + 1)
		if j > 0 and seen[c - nx] == 0:
			next.append(c - nx)
		if j < nz - 1 and seen[c + nx] == 0:
			next.append(c + nx)
		if next.is_empty():
			stack.pop_back()
			continue
		var n: int = next[rng.randi_range(0, next.size() - 1)]
		if absi(n - c) == 1:
			to_x[mini(n, c)] = 1
		else:
			to_z[mini(n, c)] = 1
		seen[n] = 1
		stack.append(n)
	# The middle: four cells opened into one clearing, for the temple.
	var ci := nx / 2 - 1
	var cj := nz / 2 - 1
	var centre := ci + cj * nx
	to_x[centre] = 1
	to_x[centre + nx] = 1
	to_z[centre] = 1
	to_z[centre + 1] = 1
	# The way from the entrance to the middle, breadth first.
	var parent := PackedInt32Array()
	parent.resize(nx * nz)
	parent.fill(-1)
	parent[door] = door
	var queue: Array[int] = [door]
	var head := 0
	while head < queue.size():
		var c: int = queue[head]
		head += 1
		var i := c % nx
		var nbrs: Array[int] = []
		if i < nx - 1 and to_x[c] == 1:
			nbrs.append(c + 1)
		if i > 0 and to_x[c - 1] == 1:
			nbrs.append(c - 1)
		if c + nx < nx * nz and to_z[c] == 1:
			nbrs.append(c + nx)
		if c - nx >= 0 and to_z[c - nx] == 1:
			nbrs.append(c - nx)
		for n in nbrs:
			if parent[n] == -1:
				parent[n] = c
				queue.append(n)
	var path: Array[int] = []
	var at := centre
	while at != door and at != -1:
		path.append(at)
		at = parent[at]
	path.append(door)
	# The way in for the crowd (_build_crowd): from outside the entrance, cell by cell, to the first cell
	# of the clearing; there it ends short of the temple's columns, once the temple is placed (below).
	var clearing := [centre, centre + 1, centre + nx, centre + nx + 1]
	_maze_way = PackedVector2Array([Vector2(x0 + nx * MAZE_CELL + 1.5, z0 + (door / nx + 0.5) * MAZE_CELL)])
	for k in range(path.size() - 1, -1, -1):
		var c: int = path[k]
		_maze_way.append(Vector2(x0 + (c % nx + 0.5) * MAZE_CELL, z0 + (c / nx + 0.5) * MAZE_CELL))
		if clearing.has(c):
			break
	# The hedges, 2.4 m high and 1.1 m thick, each straight run of wall one box.
	var walls: Array[Transform3D] = []
	var tints: Array[Color] = []
	var fringe: Array[Transform3D] = []  # with the kit: a 4 m module of sprays along each cell's side of wall
	var h := 2.4
	var t := 1.1
	for j in nz + 1:
		var run := -1
		for i in nx + 1:
			var wall := i < nx and (j == 0 or j == nz or to_z[i + (j - 1) * nx] == 0)
			if wall and run < 0:
				run = i
			elif not wall and run >= 0:
				for k in range(run, i):
					fringe.append(Transform3D(Basis(), Vector3(x0 + (k + 0.5) * MAZE_CELL, GROUND_Y, z0 + j * MAZE_CELL)))
				walls.append(Transform3D(Basis.from_scale(Vector3((i - run) * MAZE_CELL + t, h, t)),
					Vector3(x0 + (run + i) * 0.5 * MAZE_CELL, GROUND_Y + h * 0.5, z0 + j * MAZE_CELL)))
				_solid(Vector2(x0 + (run + i) * 0.5 * MAZE_CELL, z0 + j * MAZE_CELL), Vector2(((i - run) * MAZE_CELL + t) * 0.5, t * 0.5))
				tints.append(Color(0.05, 0.11, 0.05).lerp(Color(0.07, 0.14, 0.06), rng.randf()))
				run = -1
	for i in nx + 1:
		var run := -1
		for j in nz + 1:
			var wall := j < nz and (i == 0 or i == nx or to_x[i - 1 + j * nx] == 0) and not (i == nx and j == door / nx)
			if wall and run < 0:
				run = j
			elif not wall and run >= 0:
				for k in range(run, j):
					fringe.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(x0 + i * MAZE_CELL, GROUND_Y, z0 + (k + 0.5) * MAZE_CELL)))
				walls.append(Transform3D(Basis.from_scale(Vector3(t, h, (j - run) * MAZE_CELL + t)),
					Vector3(x0 + i * MAZE_CELL, GROUND_Y + h * 0.5, z0 + (run + j) * 0.5 * MAZE_CELL)))
				_solid(Vector2(x0 + i * MAZE_CELL, z0 + (run + j) * 0.5 * MAZE_CELL), Vector2(t * 0.5, ((j - run) * MAZE_CELL + t) * 0.5))
				tints.append(Color(0.05, 0.11, 0.05).lerp(Color(0.07, 0.14, 0.06), rng.randf()))
				run = -1
	var light: ImageTexture = null
	var lit := {}
	if _veg.ok:
		# One surface for every wall, tinted in the shader by place: where two walls overlap, both show the
		# same, so their faces cannot fight. The lanterns along the way light the hedges near them.
		var lanterns := PackedVector2Array()
		for k in range(0, path.size(), 2):
			var c: int = path[k]
			lanterns.append(Vector2(x0 + (c % nx + 0.5) * MAZE_CELL + 1.05, z0 + (c / nx + 0.5) * MAZE_CELL + 1.05))
		var t0 := Time.get_ticks_usec()
		light = _lantern_map(nx, nz, to_x, to_z, lanterns, lit)
		stats.lantern_ms = snappedf(float(Time.get_ticks_usec() - t0) / 1000.0, 0.1)
		stats.lanterns = lanterns.size()
		var hedge_mat := _veg_hedge_mat(2.4, Vector3(0.85, 0.95, 0.85))
		var fringe_mat := _veg_fringe_mat("cypress", 0.55, 2.4)
		for m: ShaderMaterial in [hedge_mat, fringe_mat]:
			m.set_shader_parameter("lantern_map", light)
			m.set_shader_parameter("lantern_rect", Vector4(x0, z0, 1.0 / MAZE_RECT.size.x, 1.0 / MAZE_RECT.size.y))
			m.set_shader_parameter("lantern_y", GROUND_Y + 1.0)
			m.set_shader_parameter("lantern_energy", LANTERN_ENERGY)
		_multi(g, "MazeHedges", _box(Vector3.ONE), hedge_mat, walls)
		_veg_fringe(g, "MazeFringe", "fringe_tall", fringe_mat, fringe)
	else:
		_multi(g, "MazeHedges", _box(Vector3.ONE), _gmat(3, Color.WHITE), walls, tints)
	stats.maze_walls = walls.size()
	stats.maze_path = path.size()
	# The way lit, from the entrance in: a lantern on a bronze post by the hedge in every other cell.
	var bronze := Color(0.2, 0.18, 0.15).srgb_to_linear()
	for k in path.size():
		var c: int = path[k]
		var cx := x0 + (c % nx + 0.5) * MAZE_CELL
		var cz := z0 + (c / nx + 0.5) * MAZE_CELL
		if light == null:
			pools.append(Transform3D(Basis.from_scale(Vector3(3.2, 1.0, 3.2)), Vector3(cx, GROUND_Y + 0.15, cz)))
		if k % 2 == 0:
			var post := Vector3(cx + 1.05, GROUND_Y, cz + 1.05)
			_lamp(post, 1.0, 0.22, Vector3(0.12, 0.9, 0.12), bronze)
			_solid(Vector2(post.x, post.z), Vector2(0.12, -1.0))
	if light != null:
		# The lanterns' light on the walk, from the same map: round about each post and stopped by the
		# hedges, where the square pools stood in every cell of the way whether a lantern stood there or not.
		var cells: Array[Transform3D] = []
		for c: int in lit:
			cells.append(Transform3D(Basis.from_scale(Vector3(MAZE_CELL, 1.0, MAZE_CELL)),
				Vector3(x0 + (c % nx + 0.5) * MAZE_CELL, GROUND_Y + 0.15, z0 + (c / nx + 0.5) * MAZE_CELL)))
		var plane := PlaneMesh.new()
		plane.size = Vector2.ONE
		_multi(g, "MazePools", plane, _glow(Color(1.0, 0.72, 0.42), LANTERN_POOL, {"mode": 2, "lantern_map": light,
			"lantern_rect": Vector4(x0, z0, 1.0 / MAZE_RECT.size.x, 1.0 / MAZE_RECT.size.y),
			"near_fade_from": 0.0, "near_fade_to": 0.3}), cells)
		stats.maze_pool_cells = cells.size()
	# The temple: eight columns round a lamp, under a ring of entablature and a low dome.
	var mid := Vector3(x0 + (ci + 1) * MAZE_CELL, GROUND_Y, z0 + (cj + 1) * MAZE_CELL)
	_maze_mid = Vector2(mid.x, mid.z)
	var last := _maze_way[_maze_way.size() - 1]
	_maze_way[_maze_way.size() - 1] = _maze_mid + (last - _maze_mid).normalized() * 3.3
	var column := CylinderMesh.new()
	column.top_radius = 0.15
	column.bottom_radius = 0.17
	column.height = 3.0
	column.radial_segments = 8
	column.rings = 1
	var parts := [
		[_obs.call("ring_sector", 0.0, 2.9, 0.3, 0.0, TAU, 32), Transform3D(Basis(), mid)],
		[_obs.call("ring_sector", 2.0, 2.75, 0.4, 0.0, TAU, 32), Transform3D(Basis(), mid + Vector3(0, 3.3, 0))],
		[_sphere(16, 6, true), Transform3D(Basis.from_scale(Vector3(5.2, 3.6, 5.2)), mid + Vector3(0, 3.7, 0))],
	]
	for k in 8:
		var a := TAU * k / 8.0
		parts.append([column, Transform3D(Basis(), mid + Vector3(cos(a) * 2.35, 1.8, sin(a) * 2.35))])
		_solid(Vector2(mid.x + cos(a) * 2.35, mid.z + sin(a) * 2.35), Vector2(0.22, -1.0))
	_mesh(g, "MazeTemple", _merge(parts), _gmat(0, Color(0.64, 0.6, 0.54), {"uplight": 0.6, "base_y": GROUND_Y}))
	# The lamp hangs under the dome, over a rider's head.
	_fit.lamps.append(Transform3D(Basis.from_scale(Vector3.ONE * 0.4), mid + Vector3(0, 3.0, 0)))
	pools.append(Transform3D(Basis.from_scale(Vector3(7.0, 1.0, 7.0)), mid + Vector3(0, 0.45, 0)))


## The orchard in the first of the right-hand bosquets: fruit trees in quincunx every 8 m, a rose bed
## between each two rows either side of a walk down the middle, and lamps along the walk.
func _build_orchard(g: Node3D, rng: RandomNumberGenerator, pools: Array[Transform3D]) -> void:
	var painted := (ResourceLoader.exists(TREES_TEX_PATH) and ResourceLoader.exists(IMPOSTOR_SHADER_PATH)) or bool(_veg.ok)
	var trees: Array[Transform3D] = []
	var customs: Array[Color] = []
	var tints: Array[Color] = []
	var x0 := ORCHARD_RECT.position.x
	var z0 := ORCHARD_RECT.position.y
	var x1 := ORCHARD_RECT.end.x
	var walk := ORCHARD_RECT.get_center().x
	var rows := int(ORCHARD_RECT.size.y / 8.0)
	for j in rows:
		var z := z0 + 4.0 + 8.0 * j
		var x := x0 + 2.0 + (4.0 if j % 2 == 1 else 0.0)
		while x < x1:
			if absf(x - walk) > 3.0:
				var at := Vector3(x + rng.randf_range(-0.4, 0.4), GROUND_Y, z + rng.randf_range(-0.4, 0.4))
				var height := rng.randf_range(5.0, 6.5)
				_solid(Vector2(at.x, at.z), Vector2(0.4, -1.0))
				if painted:
					var card_h := height / 0.977
					trees.append(Transform3D(Basis.from_scale(Vector3(card_h, card_h, 1.0)), at))
					customs.append(Color(float(rng.randi_range(0, 3)), rng.randf(), 0, 0))
					var v := rng.randf_range(0.75, 1.05)
					tints.append(Color(v, v, v))
				else:
					# Round crowns with fruit (alpha 0: the shader adds oranges up close).
					_fit.trees.append(Transform3D(Basis.from_scale(Vector3(3.6, 3.0, 3.6)), at + Vector3(0, height - 1.5, 0)))
					_fit.tree_tints.append(Color(0.07, 0.15, 0.05, 0.0))
			x += 8.0
	if _veg.ok:
		var orchard := _veg_trees(g, "Orchard", "pear", trees, customs, tints, 0.977)
		orchard.set_meta("keep", trees.size())
	elif painted:
		var orchard := _impostors(g, "Orchard", TREES_TEX_PATH, Vector2(2, 2), trees, customs, tints, {"energy": 0.5, "sway": 0.12})
		orchard.set_meta("keep", trees.size())
	# Rose beds: deep red, pink, white and apricot, 0.6 m high, in the foliage's shader.
	var roses := [Color(0.24, 0.02, 0.035), Color(0.45, 0.11, 0.17), Color(0.5, 0.47, 0.42), Color(0.48, 0.22, 0.05)]
	var beds: Array[Transform3D] = []
	var bed_tints: Array[Color] = []
	var bed_roses: Array[Color] = []
	for j in rows - 1:
		var z := z0 + 8.0 + 8.0 * j
		for half: Array in [[x0 + 2.0, walk - 2.5], [walk + 2.5, x1 - 2.0]]:
			var a: float = half[0]
			var b: float = half[1]
			beds.append(Transform3D(Basis.from_scale(Vector3(b - a, 0.6, 1.4)), Vector3((a + b) * 0.5, GROUND_Y + 0.3, z)))
			_solid(Vector2((a + b) * 0.5, z), Vector2((b - a) * 0.5, 0.7))
			var rose: Color = roses[(j + (1 if a > walk else 0)) % roses.size()]
			bed_tints.append(rose.lerp(Color(0.05, 0.1, 0.04), 0.3))
			bed_roses.append(rose)
	if _veg.ok:
		# Bushes of clipped leaves, as the hedges', in bloom: a flower in a third of the 16 cm cells, in the
		# bed's colour (assets/garden_plant.gdshader, flowers).
		var mat := _veg_hedge_mat(0.6, Vector3(0.75, 0.9, 0.7))
		mat.set_shader_parameter("flowers", 0.35)
		# The petals lighter than the painted beds' colours, which read as brown discs by night (shots-veg3).
		var blooms: Array[Color] = []
		for rose in bed_roses:
			blooms.append(Color(minf(rose.r * 1.8, 0.95), minf(rose.g * 1.8, 0.9), minf(rose.b * 1.8, 0.85)))
		_multi(g, "RoseBeds", _box(Vector3.ONE), mat, beds, blooms)
	else:
		_multi(g, "RoseBeds", _box(Vector3.ONE), _gmat(3, Color.WHITE), beds, bed_tints)
	# The walk's lamps, as the parterre's: on bronze posts 3 m high, every 12 m either side.
	var bronze := Color(0.2, 0.18, 0.15).srgb_to_linear()
	var lz := z0 + 6.0
	while lz < ORCHARD_RECT.end.y:
		for side: float in [-1.0, 1.0]:
			var post := Vector3(walk + side * 1.8, GROUND_Y, lz)
			_lamp(post, 3.2, 0.4, Vector3(0.14, 3.0, 0.14), bronze)
			pools.append(Transform3D(Basis.from_scale(Vector3(5.0, 1.0, 5.0)), post + Vector3(0, 0.15, 0)))
			_solid(Vector2(post.x, post.z), Vector2(0.2, -1.0))
		lz += 12.0


## The goose foot: four avenues from the basin out to the woods' edge, two rows of limes each and a
## lamp every 24 m either side of the way, from where they leave the parterre's lawns. Far lamps would
## shrink under a pixel and flicker: their globes grow with the distance to stay about 2.5 milliradians
## across (the lamps' min_angle).
func _build_avenues(g: Node3D, rng: RandomNumberGenerator) -> void:
	if not ((ResourceLoader.exists(TREES_TEX_PATH) and ResourceLoader.exists(IMPOSTOR_SHADER_PATH)) or bool(_veg.ok)):
		return
	var keep: Array[Transform3D] = []
	var extra: Array[Transform3D] = []
	var keep_c: Array[Color] = []
	var extra_c: Array[Color] = []
	var keep_t: Array[Color] = []
	var extra_t: Array[Color] = []
	var bronze := Color(0.2, 0.18, 0.15).srgb_to_linear()
	var o := Vector3(AVENUE_FROM.x, GROUND_Y, AVENUE_FROM.y)
	for deg: float in AVENUES:
		for side: float in [-1.0, 1.0]:
			var a := deg_to_rad(deg) * side
			var dir := Vector3(sin(a), 0.0, cos(a))
			var across := Vector3(dir.z, 0.0, -dir.x)
			var s := 12.0
			while s < AVENUE_LEN:
				for k: float in [-1.0, 1.0]:
					var at := o + dir * s + across * AVENUE_HALF * k
					var p := Vector2(at.x, at.z)
					if absf(at.x) < 72.0 or PALACE_CLEAR.has_point(p) or MAZE_RECT.grow(3.0).has_point(p) or ORCHARD_RECT.grow(3.0).has_point(p):
						continue
					# The avenue 60 degrees west ends at the Place du Capitole's street.
					if _capitole_script != null and ((deg == 60.0 and side < 0.0 and s > CAPITOLE_AT) or _capitole_covers(p, 4.0)):
						continue
					var height := rng.randf_range(10.0, 13.0)
					var card_h := (3.0 + height) / 0.977
					var xf := Transform3D(Basis.from_scale(Vector3(card_h, card_h, 1.0)), at)
					var custom := Color(float(rng.randi_range(0, 3)), rng.randf(), 0, 0)
					var v := rng.randf_range(0.55, 0.9)
					_solid(p, Vector2(0.6, -1.0))
					if keep.size() == extra.size():
						keep.append(xf)
						keep_c.append(custom)
						keep_t.append(Color(v, v, v))
					else:
						extra.append(xf)
						extra_c.append(custom)
						extra_t.append(Color(v, v, v))
					# A lamp every other tree, inside the row. Far off, its globe grows to stay a point of
					# light (the lamps' min_angle, _build_fittings).
					if int(s / 12.0) % 2 == 0:
						var lamp := o + dir * s + across * (AVENUE_HALF - 4.5) * k
						_lamp(lamp, 3.2, 0.4, Vector3(0.14, 3.0, 0.14), bronze)
						_solid(Vector2(lamp.x, lamp.z), Vector2(0.2, -1.0))
				s += 12.0
	var avenues: MultiMeshInstance3D
	if _veg.ok:
		avenues = _veg_trees(g, "Avenues", "linden", keep + extra, keep_c + extra_c, keep_t + extra_t, 0.977)
	else:
		avenues = _impostors(g, "Avenues", TREES_TEX_PATH, Vector2(2, 2), keep + extra, keep_c + extra_c, keep_t + extra_t,
			{"energy": 0.45, "sway": 0.15})
	avenues.set_meta("keep", keep.size())
	_thin.append(avenues)
	stats.avenue_trees = keep.size() + extra.size()


## Woods out to the city, in clumps with clearings between: a tree on a jittered grid every 18 m
## wherever a slow noise is high enough, clear of the avenues and of the palace's forecourt (and so of
## its outline against the city).
func _build_woods(far: Node3D, rng: RandomNumberGenerator) -> void:
	if not ((ResourceLoader.exists(TREES_TEX_PATH) and ResourceLoader.exists(IMPOSTOR_SHADER_PATH)) or bool(_veg.ok)):
		return
	var noise := FastNoiseLite.new()
	noise.seed = SEED + 3
	noise.frequency = 1.0 / 260.0
	var keep: Array[Transform3D] = []
	var extra: Array[Transform3D] = []
	var keep_c: Array[Color] = []
	var extra_c: Array[Color] = []
	var keep_t: Array[Color] = []
	var extra_t: Array[Color] = []
	var step := 18.0
	var x := -WOODS_R.y
	while x <= WOODS_R.y:
		var z := 30.0
		while z <= WOODS_R.y:
			var p := Vector2(x + rng.randf_range(-6.0, 6.0), z + rng.randf_range(-6.0, 6.0))
			var r := p.length()
			if r > WOODS_R.x and r < WOODS_R.y and noise.get_noise_2d(p.x, p.y) > -0.05 and not PALACE_CLEAR.has_point(p) \
					and _avenue_offset(p) > AVENUE_HALF + 6.0 and not _capitole_covers(p, 6.0):
				var height := rng.randf_range(12.0, 20.0)
				var card_h := (3.0 + height) / 0.977
				var xf := Transform3D(Basis.from_scale(Vector3(card_h, card_h, 1.0)), Vector3(p.x, GROUND_Y, p.y))
				_solid(p, Vector2(0.8, -1.0))
				var custom := Color(float(rng.randi_range(0, 3)), rng.randf(), 0, 0)
				var v := rng.randf_range(0.45, 0.8)
				if keep.size() == extra.size():
					keep.append(xf)
					keep_c.append(custom)
					keep_t.append(Color(v, v, v))
				else:
					extra.append(xf)
					extra_c.append(custom)
					extra_t.append(Color(v, v, v))
			z += step
		x += step
	var woods: MultiMeshInstance3D
	if _veg.ok:
		# Out past VEG_ZONE: their views only.
		woods = _veg_trees(far, "Woods", "linden", keep + extra, keep_c + extra_c, keep_t + extra_t, 0.977, true)
	else:
		woods = _impostors(far, "Woods", TREES_TEX_PATH, Vector2(2, 2), keep + extra, keep_c + extra_c, keep_t + extra_t,
			{"energy": 0.4, "sway": 0.1})
	woods.set_meta("keep", keep.size())
	_thin.append(woods)
	stats.wood_trees = keep.size() + extra.size()


## The terrace's and the parterre's boxes (pedestals, tubs, lamp posts), lamp globes and round trees
## (cypresses, orange trees): one MultiMesh each.
func _build_fittings() -> void:
	var g := Node3D.new()
	g.name = "Fittings"
	_garden.add_child(g)
	_multi(g, "Boxes", _box(Vector3.ONE), _gmat(0, Color.WHITE, {"uplight": 0.35, "base_y": GROUND_Y, "sheen": 0.1}), _fit.boxes, _fit.box_tints)
	_multi(g, "Lamps", _sphere(8, 4), _gmat(5, Color.WHITE, {"min_angle": 0.0025}), _fit.lamps)
	if not (_fit.lamp_feet as Array).is_empty():
		var kit := {}
		var root: Node = (load(LAMP_KIT_PATH) as PackedScene).instantiate()
		for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
			kit[String(mi.name)] = mi.mesh
		root.free()
		# Painted iron, its gilt as the basin's, its occlusion in the vertex colour (kind 0 multiplies by it); the
		# glass glows as the globes did and stands for their light in the rays.
		_multi(g, "LampIron", kit["iron"], _gmat(0, Color(0.035, 0.04, 0.035), {"sheen": 0.35}), _fit.lamp_feet)
		_multi(g, "LampGilt", kit["gilt"], _gmat(0, Color(0.78, 0.6, 0.3), {"sheen": 0.8, "metal": 1.0}), _fit.lamp_feet)
		_multi(g, "LampGlass", kit["glass"], _gmat(5, Color.WHITE, {"min_angle": 0.0025}), _fit.lamp_glass)
		stats.lamps_modelled = (_fit.lamp_feet as Array).size()
	_multi(g, "Trees", _sphere(8, 6), _gmat(3, Color.WHITE), _fit.trees, _fit.tree_tints)


## A lamp on the ground at foot, its light globe_y over it: the modelled lamp (LAMP_KIT_PATH) scaled so that its
## glass stands there, off the web; else a post (a box post_size big) and a globe globe metres across, as
## before, both drawn by _build_fittings.
func _lamp(foot: Vector3, globe_y: float, globe: float, post_size: Vector3, tint: Color) -> void:
	if _lamp_kit:
		var k := globe_y / LAMP_GLASS_Y
		_fit.lamp_feet.append(Transform3D(Basis.from_scale(Vector3.ONE * k), foot))
		_fit.lamp_glass.append(Transform3D(Basis.from_scale(Vector3.ONE * (k / LAMP_GLASS_SCALE)), foot + Vector3(0.0, globe_y, 0.0)))
		return
	_fit.boxes.append(Transform3D(Basis.from_scale(post_size), foot + Vector3(0.0, post_size.y * 0.5, 0.0)))
	_fit.box_tints.append(tint)
	_fit.lamps.append(Transform3D(Basis.from_scale(Vector3.ONE * globe), foot + Vector3(0.0, globe_y, 0.0)))


## The lights that stand for the lamps while the path tracer lights the gardens (set_rt_lit): one in each
## lamp's globe and each lantern's glass, inverse square; the galactic core's, and the sky's in a wide cone
## from overhead, which the rays found too rarely in the sky's map for the shade to read as the painted
## ambient did. The rasterizer never sees them; the gardens paint that light themselves there.
const RT_LAMP_COLOUR := Color(1.0, 0.72, 0.42)  # palace_garden.gdshader's lamp_colour (sRGB)
const RT_LAMP_ENERGY := 8.0      # a walk lamp's globe, 0.45 m across; smaller globes in proportion to their area
const RT_LANTERN_ENERGY := 4.0   # a terrace lantern's glass
const RT_LAMP_RANGE := 20.0
const RT_CORE_ENERGY := 0.35    # the shaders' core_energy
const RT_FILL_COLOUR := Color(0.64, 0.73, 1.0)  # the shaders' ambient (0.07, 0.08, 0.11), its hue, linear
const RT_FILL_ENERGY := 0.07
## The fork draws a light for each hit from 8 picked at random among all of them: of the 613 lamps, the
## nearest this many to the camera are shown, a quarter of a second at a time.
const RT_LAMPS_SHOWN := 48


## Path traced (on), the gardens are lit by the rays from lights standing for their lamps and the galactic
## core (their shaders' RT variants take no light of their own); off, they paint their light again. The
## lights are made the first time. Returns how many there are.
func set_rt_lit(on: bool) -> Dictionary:
	_rt_lit = on
	if on and _rt_lights == null and _garden != null:
		_rt_lights = _build_rt_lights()
	if _rt_lights != null:
		_rt_lights.visible = on
	if on and _rt_sky == null and _garden != null:
		_rt_sky = _build_rt_sky()
	if _rt_sky != null:
		_rt_sky.visible = on
	if _crowd != null:
		_crowd.call("set_rays", on)   # the nearest people on bones, which the rays see walk
	_rt_culled_at = -1.0e9
	return {"on": on, "lights": _rt_lights.get_child_count() if _rt_lights != null else 0}


func _build_rt_lights() -> Node3D:
	var g := Node3D.new()
	g.name = "RtLights"
	_garden.add_child(g)
	for n in _garden.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		var m := mmi.material_override as ShaderMaterial
		if m == null or mmi.multimesh == null or mmi.multimesh.mesh == null or m.shader == null \
				or m.shader.resource_path != GARDEN_SHADER_PATH or int(m.get_shader_parameter("kind")) != 5:
			continue
		var box := mmi.multimesh.mesh.get_aabb()
		var lantern := mmi.name == "LanternGlass"
		for i in mmi.multimesh.instance_count:
			var t: Transform3D = mmi.global_transform * mmi.multimesh.get_instance_transform(i)
			var r := 0.5 * box.size.x * t.basis.get_scale().x
			var l := OmniLight3D.new()
			l.light_color = RT_LAMP_COLOUR
			l.light_energy = RT_LANTERN_ENERGY if lantern else RT_LAMP_ENERGY * minf(1.0, pow(r / 0.225, 2.0))
			l.light_size = r
			l.omni_range = RT_LAMP_RANGE
			l.omni_attenuation = 2.0
			l.shadow_enabled = false  # the rays shadow every light; the rasterizer never draws these
			g.add_child(l)
			l.global_position = t * box.get_center()
			_rt_lamps.append(l)
	stats.rt_lights = g.get_child_count()
	return g


## Under the garden, so hidden with it: two directional lights reach every hit, the hall's too, where their
## shadow rays cross the dome. With them always on, the hall took 17.4 ms of GPU at DLSS Quality against 15.7
## for 0.2.3's scene on the same engine (RTX 0.2.4's tree 12, artpass/publish/rtx/logs/ab-engine024-*).
func _build_rt_sky() -> Node3D:
	var g := Node3D.new()
	g.name = "RtSky"
	_garden.add_child(g)
	var core := DirectionalLight3D.new()
	core.name = "Core"
	core.light_color = Color(0.9, 0.8, 0.66).linear_to_srgb()  # the shaders' core_light, linear
	core.light_energy = RT_CORE_ENERGY
	core.light_angular_distance = 6.0
	core.shadow_enabled = false
	g.add_child(core)
	var up := Vector3.UP if absf(_core.normalized().y) < 0.99 else Vector3.FORWARD
	core.global_basis = Basis.looking_at(-_core.normalized(), up)
	var fill := DirectionalLight3D.new()
	fill.name = "SkyFill"
	fill.light_color = RT_FILL_COLOUR.linear_to_srgb()
	fill.light_energy = RT_FILL_ENERGY
	fill.light_angular_distance = 90.0  # the widest Godot allows: a cone 45 degrees about the zenith
	fill.shadow_enabled = false
	g.add_child(fill)
	fill.global_basis = Basis.looking_at(Vector3.DOWN, Vector3.FORWARD)
	return g


func _build_water() -> void:
	var g := Node3D.new()
	g.name = "Water"
	_garden.add_child(g)
	var water := _gmat(4, Color(0.05, 0.07, 0.08))
	_water_mat = water
	# Neither rides into: the basin with its rim, the canal with its.
	_solid(Vector2(0.0, 95.0), Vector2(14.8, -1.0))
	_solid(Vector2(0.0, 250.0), Vector2(12.8, 80.8))
	var rim := _gmat(0, Color(0.6, 0.57, 0.52), {"uplight": 0.2, "base_y": GROUND_Y})
	# The round basin and the canal beyond it, one mesh; their rims, another.
	var disc := CylinderMesh.new()
	disc.top_radius = 14.0
	disc.bottom_radius = 14.0
	disc.height = 0.1
	disc.radial_segments = 48
	disc.rings = 1
	# With the modelled basin, its water's edge as round as its coping's lathe (at 48 sides it stood up to
	# 3 cm inside the coping's inner wall).
	var kit := parterre_kit and ResourceLoader.exists(BASIN_GLB_PATH)
	disc.radial_segments = 128 if kit else 48
	_mesh(g, "Basins", _merge([[disc, Transform3D(Basis(), Vector3(0, GROUND_Y + 0.2, 95.0))],
		[_box(Vector3(24.0, 0.1, 160.0)), Transform3D(Basis(), Vector3(0, GROUND_Y + 0.2, 250.0))]]), water)
	_build_show(g, water)
	var rims := [
		[_box(Vector3(0.8, 0.5, 161.6)), Transform3D(Basis(), Vector3(-12.4, GROUND_Y + 0.25, 250.0))],
		[_box(Vector3(0.8, 0.5, 161.6)), Transform3D(Basis(), Vector3(12.4, GROUND_Y + 0.25, 250.0))],
		[_box(Vector3(24.0, 0.5, 0.8)), Transform3D(Basis(), Vector3(0, GROUND_Y + 0.25, 169.6))],
		[_box(Vector3(24.0, 0.5, 0.8)), Transform3D(Basis(), Vector3(0, GROUND_Y + 0.25, 330.4))],
	]
	if kit and _build_basin_kit(g, water):
		stats.basin = "kit"
		_mesh(g, "Rims", _merge(rims), rim)
		return
	stats.basin = "drawn"
	rims.append([_obs.call("ring_sector", 14.0, 14.8, 0.5, 0.0, TAU, 48), Transform3D(Basis(), Vector3(0, GROUND_Y, 95.0))])
	_mesh(g, "Rims", _merge(rims), rim)
	# The fountain: a tall jet in the middle and six round it, as crossed sheets of rising drops, all in
	# one mesh.
	var sheets := []
	for j in 7:
		var h := 11.0 if j == 0 else 4.0
		var w := 1.4 if j == 0 else 0.7
		var at := Vector3(0, GROUND_Y + 0.25 + h * 0.5, 95.0)
		if j > 0:
			var a := TAU * j / 6.0
			at += Vector3(cos(a) * 8.0, 0.0, sin(a) * 8.0)
		var q := QuadMesh.new()
		q.size = Vector2(w, h)
		for turn: float in [0.0, PI * 0.5]:
			sheets.append([q, Transform3D(Basis(Vector3.UP, turn), at)])
	_jets.append(_mesh(g, "Jets", _merge(sheets), _glow(Color(0.75, 0.88, 1.0), 0.3, {"mode": 1, "fade_top": 0.3, "fade_foot": 0.1, "edge": 0.8})))


## The canal's fountain show (SHOW_SCRIPT_PATH), over the water's surface from one end of the canal to the
## other; hidden with the other jets from quality level 3.
func _build_show(g: Node3D, water: ShaderMaterial) -> void:
	stats.show = 0
	if not (fountain_show and ResourceLoader.exists(SHOW_SCRIPT_PATH)):
		return
	var show: Node3D = load(SHOW_SCRIPT_PATH).new()
	show.name = "FountainShow"
	if not bool(show.call("setup", water, GROUND_Y + 0.25, Vector2(170.0, 330.0))):
		show.free()
		return
	g.add_child(show)
	_show = show
	_jets.append(show)
	stats.show = int((show.get("stats") as Dictionary).nozzles)


## The modelled basin (BASIN_GLB_PATH) at the parterre's basin: its coping and fountain in stone and gilt,
## their occlusion in the vertex colour (kind 0 multiplies by it), floodlit from the water; its veils and
## jets as turned water (palace_glow.gdshader mode 3), warm at their nozzles; the water lit round the
## fountain's foot and round each jet. false, with nothing built, when a part is missing.
func _build_basin_kit(g: Node3D, water: ShaderMaterial) -> bool:
	var meshes := {}
	var root: Node = (load(BASIN_GLB_PATH) as PackedScene).instantiate()
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		meshes[String(mi.name)] = mi.mesh
	root.free()
	for nm: String in ["coping", "fountain", "gilt", "veils", "jet_main", "jet_side"]:
		if not meshes.has(nm):
			return false
	var at := Transform3D(Basis(), Vector3(AVENUE_FROM.x, GROUND_Y, AVENUE_FROM.y))
	var foot := GROUND_Y + 0.25
	var stone := _gmat(0, Color(0.62, 0.59, 0.54), {"uplight": 0.3, "base_y": foot, "sheen": 0.08})
	# At 0.86, 0.66, 0.3 and uplight 0.45 the rims read as orange plastic (shots/basin/live-basin-oblique2).
	var gilt := _gmat(0, Color(0.78, 0.6, 0.3), {"uplight": 0.3, "base_y": foot, "sheen": 0.8, "metal": 1.0})
	_mesh(g, "BasinCoping", meshes["coping"], stone, at)
	_mesh(g, "Fountain", meshes["fountain"], stone, at)
	_mesh(g, "FountainGilt", meshes["gilt"], gilt, at)
	var falling := _glow(Color(0.75, 0.88, 1.0), 0.32, {"mode": 3, "fade_top": 0.12, "fade_foot": 0.04, "foot_glow": 0.5})
	# The jets' columns solid from their nozzles to where they break up (make_basin.py's profiles, by their
	# length: the main jet's at UV.y 0.57, the side jets' at 0.42).
	var rising := _glow(Color(0.75, 0.88, 1.0), 0.36, {"mode": 3, "fade_top": 0.25, "fade_foot": 0.03, "foot_glow": 0.7,
		"nozzle_film": 0.5, "nozzle_to": 0.45})
	var rising_side := _glow(Color(0.75, 0.88, 1.0), 0.36, {"mode": 3, "fade_top": 0.25, "fade_foot": 0.03, "foot_glow": 0.7,
		"nozzle_film": 0.45, "nozzle_to": 0.3})
	_jets.append(_mesh(g, "Veils", meshes["veils"], falling, at))
	_jets.append(_mesh(g, "JetMain", meshes["jet_main"], rising, at))
	var sides: Array[Transform3D] = []
	for j in 6:
		var a := TAU * j / 6.0
		sides.append(at * Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a), 0.0, sin(a)) * 8.0))
	_jets.append(_multi(g, "JetsSide", meshes["jet_side"], rising_side, sides))
	water.set_shader_parameter("jet_light", Vector4(AVENUE_FROM.x, AVENUE_FROM.y, 8.0, 0.35))
	water.set_shader_parameter("still_ruffle", 0.015)
	return true


# --- The crowd ----------------------------------------------------------------------------------

## A sparse crowd, after the author's "On peut rajouter une foule (Clairsemee la foule) dans les jardins?"
## (2026-10-04): about a hundred people (scripts/garden_crowd.gd) walking the walks back and forth, or
## standing at the balustrade, round the basin, by the orchard's roses and round the maze's temple. Each
## walk is [points, walkers, half its width], its middle line clear of whatever stands by that much and a
## person's breadth more (artpass/gardens/crowd/crowdprobe.gd walks each one's edges against push_out).
func _build_crowd() -> void:
	if not (_veg.ok and ResourceLoader.exists(CROWD_SCRIPT_PATH)):
		return
	var routes: Array = []
	# The terrace, between the hall's wall and the orange trees' tubs; the ramp, down to the basin.
	var arc := PackedVector2Array()
	for k in 31:
		var a := deg_to_rad(15.0 + 150.0 * k / 30.0)
		arc.append(Vector2(cos(a), sin(a)) * 20.35)
	routes.append([arc, 6, 0.55])
	routes.append([PackedVector2Array([Vector2(0.0, 22.0), Vector2(0.0, 75.5)]), 4, 3.0])
	# Round the basin, its near side and its far one, within the middle walk; the middle walk beyond it.
	# (The walks' ends stay a person's breadth from one another's: those turning back there would meet.)
	for far: float in [0.0, PI]:
		var rim := PackedVector2Array()
		for k in 9:
			var t := deg_to_rad(-22.0 + 44.0 * k / 8.0) + far
			rim.append(Vector2(0.0, 95.0) + Vector2(sin(t), -cos(t)) * 17.2)
		routes.append([rim, 2, 0.35])
	routes.append([PackedVector2Array([Vector2(0.0, 114.5), Vector2(0.0, 168.0)]), 5, 5.0])
	for side: float in [-1.0, 1.0]:
		# Between the walk lamps and the compartments, beside the ramp and past the basin; under the
		# retaining wall; across between the compartments (round the basin at z = 92); round them; along
		# the canal; down the avenues, from beyond the cypresses.
		# (8.0 to 9.7: the parterre de broderie's compartments begin 5 cm nearer than the lawns they replace.)
		routes.append([PackedVector2Array([Vector2(side * 8.85, 29.6), Vector2(side * 8.85, 82.0)]), 3, 0.85])
		routes.append([PackedVector2Array([Vector2(side * 8.85, 108.0), Vector2(side * 8.85, 168.0)]), 3, 0.85])
		routes.append([PackedVector2Array([Vector2(side * 10.4, 27.4), Vector2(side * 62.8, 27.4)]), 2, 0.9])
		for z: float in [60.0, 124.0, 156.5]:
			routes.append([PackedVector2Array([Vector2(side * 10.4, z), Vector2(side * 62.8, z)]), 2, 1.0])
		routes.append([PackedVector2Array([Vector2(side * 15.6, 92.0), Vector2(side * 62.8, 92.0)]), 2, 1.0])
		routes.append([PackedVector2Array([Vector2(side * 65.5, 29.6), Vector2(side * 65.5, 165.0)]), 4, 2.0])
		routes.append([PackedVector2Array([Vector2(side * 16.8, 172.0), Vector2(side * 16.8, 326.0)]), 4, 2.5])
		for deg: float in AVENUES:
			var a := deg_to_rad(deg) * side
			var dir := Vector2(sin(a), cos(a))
			routes.append([PackedVector2Array([AVENUE_FROM + dir * (74.0 / absf(dir.x)), AVENUE_FROM + dir * 300.0]), 3, 3.0])
	# The orchard's walk, and the way through the maze to its temple.
	var walk := ORCHARD_RECT.get_center().x
	routes.append([PackedVector2Array([Vector2(walk, ORCHARD_RECT.position.y + 1.5), Vector2(walk, ORCHARD_RECT.end.y - 1.5)]), 5, 1.0])
	if _maze_way.size() > 1:
		routes.append([_maze_way, 4, 0.4])
	# Standing: at the balustrade looking out, round the basin looking at the jets, by the orchard's roses
	# (a gardener among them), round the maze's temple.
	var spots: Array = []
	for a_deg: float in [30.0, 50.0, 62.0, 118.0, 130.0, 150.0]:
		var a := deg_to_rad(a_deg)
		spots.append([Vector2(cos(a), sin(a)) * 22.9, Vector2(cos(a), sin(a)) * 40.0, -1])
	for t_deg: float in [-20.0, -4.0, 12.0, 24.0]:
		var t := deg_to_rad(t_deg)
		spots.append([Vector2(0.0, 95.0) + Vector2(sin(t), -cos(t)) * 15.5, Vector2(0.0, 95.0), -1])
	# Beside the orchard's walk, between it and the beds.
	spots.append([Vector2(walk - 1.9, 60.0), Vector2(walk - 10.0, 60.0), 3])
	spots.append([Vector2(walk + 1.9, 84.0), Vector2(walk + 10.0, 84.0), -1])
	spots.append([Vector2(walk - 1.9, 108.0), Vector2(walk - 10.0, 108.0), -1])
	if _maze_way.size() > 1:
		var arrive := (_maze_way[_maze_way.size() - 1] - _maze_mid).normalized()
		for turn: float in [PI * 0.5, PI]:
			spots.append([_maze_mid + arrive.rotated(turn) * 3.3, _maze_mid, -1])
	var mats := {}
	for part: String in ["skin", "cloth", "trim"]:
		mats[part] = _pmat(4, "", {"part": ["skin", "cloth", "trim"].find(part)})
	var crowd: Node3D = load(CROWD_SCRIPT_PATH).new()
	crowd.name = "Crowd"
	if not bool(crowd.call("setup", self, mats, routes, spots, SEED + 7)):
		crowd.free()
		stats.crowd = 0
		return
	_garden.add_child(crowd)
	_crowd = crowd
	stats.crowd = (crowd.get("stats") as Dictionary).people


## The gardens made grander (scripts/garden_grand.gd; the author, 2026-10-15: « Pour ressembler un petit peu plus
## à Versailles ou quelque chose de plus grandiose »): statues and vases along the canal, gilded dolphins in the
## basin. Off the web, and only when its script and every one of its files are there.
func _build_grand() -> void:
	stats.grand = 0
	if _compat or not ResourceLoader.exists(GRAND_SCRIPT_PATH):
		return
	var grand: Node3D = load(GRAND_SCRIPT_PATH).new()
	grand.name = "Grand"
	if not bool(grand.call("setup", self, GROUND_Y)):
		grand.free()
		return
	_garden.add_child(grand)
	stats.grand = int((grand.get("stats") as Dictionary).pieces)


# --- The palace, the city -----------------------------------------------------------------------

func _build_palace() -> void:
	var g := Node3D.new()
	g.name = "Palace"
	_garden.add_child(g)
	if palace_model and _build_palace_model(g):
		return
	var y0 := GROUND_Y
	var tex: Texture2D = load(PALACE_TEX_PATH) if ResourceLoader.exists(PALACE_TEX_PATH) else null
	if tex != null:
		var h := PALACE_W * tex.get_height() / tex.get_width()
		var foot := y0 - 1.0
		var card := QuadMesh.new()
		card.size = Vector2(PALACE_W, h)
		var mat := ShaderMaterial.new()
		mat.shader = load(CARD_SHADER_PATH)
		mat.set_shader_parameter("tex", tex)
		# Forward+ tone maps (ACES) what Compatibility shows as it is.
		var energy := 1.0 if _compat else 1.35
		mat.set_shader_parameter("energy", energy)
		# A quad faces +Z: turned round to face the hall.
		_mesh(g, "Card", card, mat, Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, foot + h * 0.5, PALACE_Z)))
		if _water_mat != null:
			_water_mat.set_shader_parameter("palace_tex", tex)
			_water_mat.set_shader_parameter("palace_rect", Vector4(-PALACE_W * 0.5, PALACE_W * 0.5, foot, foot + h))
			_water_mat.set_shader_parameter("palace_z", PALACE_Z)
			_water_mat.set_shader_parameter("palace_energy", energy)
		stats.palace = "card"
		return
	stats.palace = "boxes"
	var facade := _gmat(0, Color(0.8, 0.76, 0.68), {"windows": 0.62, "uplight": 0.9, "base_y": y0,
		"window_cell": Vector3(3.6, 4.4, 3.6), "sheen": 0.05})
	var o := Transform3D()
	var parts := [
		# The garden front, its middle pavilion standing forward, and the wings coming forward on
		# either side, each ending in a pavilion: a U open towards the hall.
		_span(o, Vector3(-150, y0, 420), Vector3(150, y0 + 24, 446)),
		_span(o, Vector3(-32, y0, 404), Vector3(32, y0 + 32, 450)),
		_span(o, Vector3(-176, y0, 262), Vector3(-150, y0 + 22, 446)),
		_span(o, Vector3(150, y0, 262), Vector3(176, y0 + 22, 446)),
		_span(o, Vector3(-182, y0, 238), Vector3(-144, y0 + 28, 264)),
		_span(o, Vector3(144, y0, 238), Vector3(182, y0 + 28, 264)),
		# Attics and a cornice line over the fronts.
		_span(o, Vector3(-151, y0 + 24, 419), Vector3(151, y0 + 25.2, 447)),
		_span(o, Vector3(-33, y0 + 32, 403), Vector3(33, y0 + 33.5, 451)),
	]
	_mesh(g, "Fronts", _merge(parts), facade)
	# The colonnade before the middle pavilion.
	var shaft := CylinderMesh.new()
	shaft.top_radius = 1.0
	shaft.bottom_radius = 1.15
	shaft.height = 1.0
	shaft.radial_segments = 10
	shaft.rings = 1
	var cols: Array[Transform3D] = []
	for i in 10:
		cols.append(Transform3D(Basis.from_scale(Vector3(1, 26, 1)), Vector3(-27.0 + 6.0 * i, y0 + 13.0, 400.5)))
	_multi(g, "Colonnade", shaft, _gmat(0, Color(0.86, 0.82, 0.74), {"uplight": 1.1, "base_y": y0}), cols)
	# The dome over the middle pavilion, gilt ribs catching the core, and its lantern.
	var dome := SphereMesh.new()
	dome.radius = 24.0
	dome.height = 30.0
	dome.is_hemisphere = true
	dome.radial_segments = 32
	dome.rings = 10
	_mesh(g, "Dome", dome, _gmat(0, Color(0.42, 0.5, 0.5), {"sheen": 0.5, "uplight": 0.25, "base_y": y0 + 33}), Transform3D(Basis(), Vector3(0, y0 + 33.5, 427)))
	var drum := CylinderMesh.new()
	drum.top_radius = 3.0
	drum.bottom_radius = 3.0
	drum.height = 6.0
	drum.radial_segments = 12
	drum.rings = 1
	_mesh(g, "Lantern", drum, _gmat(0, Color(0.8, 0.76, 0.68), {"windows": 1.0, "window_cell": Vector3(1.5, 3.0, 1.5), "window_energy": 2.4}), Transform3D(Basis(), Vector3(0, y0 + 33.5 + 15.0 + 2.5, 427)))


## The Place du Capitole (scripts/capitole_square.gd) at _capitole_xf, the end of the avenue 60 degrees west.
func _build_capitole() -> void:
	if _capitole_script == null:
		return
	var sq := Node3D.new()
	sq.set_script(_capitole_script)
	sq.name = "Capitole"
	sq.transform = _capitole_xf
	_garden.add_child(sq)
	if not bool(sq.call("build", 1.0 if _compat else 1.35)):
		sq.queue_free()
		_capitole_script = null
		return
	_capitole = sq
	stats.capitole = sq.get("stats")


## Whether p (x, z) is on the Place du Capitole's footprint, grown by margin.
func _capitole_covers(p: Vector2, margin: float) -> bool:
	return _capitole_script != null and bool(_capitole_script.call("covers", _capitole_xf, p, margin))


## The modelled palace (PALACE_GLB_PATH), each of its materials drawn by assets/palace_baked.gdshader with
## the baked light, the beam from its spire by assets/palace_beam.gdshader. false when it is not there.
func _build_palace_model(g: Node3D) -> bool:
	if not (ResourceLoader.exists(PALACE_GLB_PATH) and (ResourceLoader.exists(PALACE_LIGHT_PATH) or ResourceLoader.exists(PALACE_LIGHT_WEB_PATH))):
		return false
	var root: Node3D = (load(PALACE_GLB_PATH) as PackedScene).instantiate()
	root.name = "Model"
	root.position = Vector3(0.0, GROUND_Y, PALACE_Z)
	g.add_child(root)
	# The web's lightmap there (or with --palace-light=web), and wherever the full one was left out.
	var web := OS.has_feature("web") or OS.get_cmdline_user_args().has("--palace-light=web")
	var web_light := (web and ResourceLoader.exists(PALACE_LIGHT_WEB_PATH)) or not ResourceLoader.exists(PALACE_LIGHT_PATH)
	var light: Texture2D = load(PALACE_LIGHT_WEB_PATH if web_light else PALACE_LIGHT_PATH)
	stats.palace_light = light.get_width()
	var detail: Texture2D = load(STONE_TEX_PATH) if ResourceLoader.exists(STONE_TEX_PATH) else null
	# Forward+ tone maps (ACES) what Compatibility shows as it is, as for the card.
	var energy := 1.0 if _compat else 1.35
	var mats := {}
	var names: Array[String] = []
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		_out(mi)
		stats.garden_meshes += 1
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i)
			var nm := src.resource_name if src != null else ""
			if not mats.has(nm):
				mats[nm] = _palace_mat(nm, light, detail, energy)
			mi.set_surface_override_material(i, mats[nm])
			names.append(nm)
			if nm == "beam":
				# The beam widens far off (palace_beam.gdshader): past its mesh's bounds.
				mi.extra_cull_margin = 16.0
	stats.palace_surfaces = names
	# The author, 2026-10-16, at the telescope: « Je veux l'horloge de l'hotel de ville de retour vers le futur ».
	if not _compat and ResourceLoader.exists(PALACE_CLOCK_SCRIPT_PATH):
		var clock: Node3D = load(PALACE_CLOCK_SCRIPT_PATH).new()
		clock.name = "Clock"
		root.add_child(clock)
		clock.call("build")
		stats.palace_clock = clock.get("stats")
	if _water_mat != null and ResourceLoader.exists(PALACE_MIRROR_PATH):
		_water_mat.set_shader_parameter("palace_tex", load(PALACE_MIRROR_PATH))
		_water_mat.set_shader_parameter("palace_rect", Vector4(-PALACE_MIRROR.x, PALACE_MIRROR.x, GROUND_Y + PALACE_MIRROR.y, GROUND_Y + PALACE_MIRROR.z))
		_water_mat.set_shader_parameter("palace_z", PALACE_MIRROR_Z)
		_water_mat.set_shader_parameter("palace_energy", energy)
	stats.palace = "model"
	return true


func _palace_mat(nm: String, light: Texture2D, detail: Texture2D, energy: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	if nm == "beam":
		m.shader = load(PALACE_BEAM_SHADER_PATH)
		m.set_shader_parameter("energy", 4.0 * energy)
		return m
	var p: Array = PALACE_MATS.get(nm, PALACE_MATS.stone)
	m.shader = load(PALACE_SHADER_PATH)
	m.set_shader_parameter("kind", p[0])
	m.set_shader_parameter("albedo", p[1])
	m.set_shader_parameter("emission", p[2])
	m.set_shader_parameter("emission_energy", p[3])
	m.set_shader_parameter("light_tex", light)
	m.set_shader_parameter("core_dir", _core)
	m.set_shader_parameter("energy", energy)
	var extra: Dictionary = p[4]
	for k in extra:
		m.set_shader_parameter(k, extra[k])
	if detail != null and extra.has("stone_detail"):
		m.set_shader_parameter("detail_tex", detail)
	return m


func _build_city(rng: RandomNumberGenerator) -> void:
	var g := Node3D.new()
	g.name = "City"
	_garden.add_child(g)
	if night_city and ResourceLoader.exists(NIGHT_CITY_PATH):
		# The night city stays at every level (the author on version 42, 2026-10-13: « Je vois pas la
		# nouvelle ville de Trantor en fonds »): the painted strips went from level 4 with the far woods,
		# and the grounds' horizon is empty without a city. From the air it is 29 draw calls and 120,408
		# triangles (artpass/publish/regress-pub35, views_compat, city_air).
		# The night city, with its own glow round the horizon.
		var nc: Node3D = load(NIGHT_CITY_PATH).new()
		nc.name = "NightCity"
		nc.call("configure", _compat, GROUND_Y)
		g.add_child(nc)
		stats.city = "night"
		stats.night_city = nc.get("stats")
		return
	_far.append(g)
	if _build_city_strips(g):
		stats.city = "strips"
	else:
		stats.city = "domes"
		_build_city_domes(g, rng)
	# The city's glow over the horizon, behind it all.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 48
	var r_glow := 1900.0
	var a0 := deg_to_rad(4.0)
	var a1 := deg_to_rad(176.0)
	for i in seg:
		var t0 := a0 + (a1 - a0) * i / seg
		var t1 := a0 + (a1 - a0) * (i + 1) / seg
		var c0 := Vector3(cos(t0), 0, sin(t0)) * r_glow
		var c1 := Vector3(cos(t1), 0, sin(t1)) * r_glow
		var u0 := float(i) / seg
		var u1 := float(i + 1) / seg
		var lo := GROUND_Y
		var hi := 520.0
		for v: Array in [[c0 + Vector3(0, hi, 0), Vector2(u0, 0)], [c1 + Vector3(0, hi, 0), Vector2(u1, 0)], [c1 + Vector3(0, lo, 0), Vector2(u1, 1)],
				[c0 + Vector3(0, hi, 0), Vector2(u0, 0)], [c1 + Vector3(0, lo, 0), Vector2(u1, 1)], [c0 + Vector3(0, lo, 0), Vector2(u0, 1)]]:
			st.set_uv(v[1])
			st.add_vertex(v[0])
	# Amber, as the towers' haze: violet, as it was for the domes, turned it pink under Compatibility
	# (artpass/bays/art9-compat).
	var glow := _mesh(g, "CityGlow", st.commit(), _glow(Color(0.62, 0.44, 0.26), 0.09, {"fade_top": 0.95, "fade_foot": 0.02, "edge": 0.15, "near_fade_from": -1.0, "near_fade_to": 0.0}))
	glow.name = "CityGlow"


## The painted strips, if their images are there: one curved band each, the image's left at its lower
## angle (on the left as seen from the hall), wound as the glow's band is.
func _build_city_strips(g: Node3D) -> bool:
	var texes: Array[Texture2D] = []
	for p: String in CITY_TEX_PATHS:
		if not ResourceLoader.exists(p):
			return false
		texes.append(load(p))
	var arc := deg_to_rad(CITY_ARC)
	var step := TAU / texes.size()
	var seg := 40
	for k in texes.size():
		var tex := texes[k]
		var h := CITY_R * arc * tex.get_height() / tex.get_width()
		var lo := GROUND_Y - 2.0
		var hi := lo + h
		var a0 := deg_to_rad(CITY_A0) + step * k
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in seg:
			var t0 := a0 + arc * i / seg
			var t1 := a0 + arc * (i + 1) / seg
			var c0 := Vector3(cos(t0), 0, sin(t0)) * CITY_R
			var c1 := Vector3(cos(t1), 0, sin(t1)) * CITY_R
			var u0 := float(i) / seg
			var u1 := float(i + 1) / seg
			for v: Array in [[c0 + Vector3(0, hi, 0), Vector2(u0, 0)], [c1 + Vector3(0, hi, 0), Vector2(u1, 0)], [c1 + Vector3(0, lo, 0), Vector2(u1, 1)],
					[c0 + Vector3(0, hi, 0), Vector2(u0, 0)], [c1 + Vector3(0, lo, 0), Vector2(u1, 1)], [c0 + Vector3(0, lo, 0), Vector2(u0, 1)]]:
				st.set_uv(v[1])
				st.add_vertex(v[0])
		var mat := ShaderMaterial.new()
		mat.shader = load(CARD_SHADER_PATH)
		mat.set_shader_parameter("tex", tex)
		mat.set_shader_parameter("energy", 1.0 if _compat else 1.35)
		mat.set_shader_parameter("sky_glow", 0.8)
		mat.set_shader_parameter("haze_distance", 6000.0)
		_mesh(g, "Strip%d" % k, st.commit(), mat)
	return true


## The city in domes of every size and towers between them, their windows lit, fading into the haze.
func _build_city_domes(g: Node3D, rng: RandomNumberGenerator) -> void:
	var hemi := _sphere(16, 6, true)
	var domes: Array[Transform3D] = []
	var towers: Array[Transform3D] = []
	for i in 70:
		var a := rng.randf_range(deg_to_rad(8.0), deg_to_rad(172.0))
		var r := rng.randf_range(900.0, 1800.0)
		var s := rng.randf_range(80.0, 300.0)
		domes.append(Transform3D(Basis.from_scale(Vector3(s, s * rng.randf_range(0.5, 0.9), s)), Vector3(cos(a) * r, GROUND_Y - 2.0, sin(a) * r)))
	for i in 90:
		var a := rng.randf_range(deg_to_rad(8.0), deg_to_rad(172.0))
		var r := rng.randf_range(1100.0, 1850.0)
		var h := rng.randf_range(40.0, 170.0)
		var w := rng.randf_range(18.0, 40.0)
		towers.append(Transform3D(Basis(Vector3.UP, rng.randf() * PI).scaled(Vector3(w, h, w)), Vector3(cos(a) * r, GROUND_Y + h * 0.5, sin(a) * r)))
	# Their windows lit by districts, in bays of 12 m by floors of 8: far off, points of light on dark
	# shells rather than an even glow.
	var shell := _gmat(0, Color(0.2, 0.22, 0.26), {"windows": 0.22, "window_cell": Vector3(12, 8, 12), "districts": 1.0, "sheen": 0.2, "window_energy": 1.8})
	_multi(g, "Domes", hemi, shell, domes)
	_multi(g, "Towers", _box(Vector3.ONE), _gmat(0, Color(0.18, 0.2, 0.24), {"windows": 0.45, "window_cell": Vector3(6, 5, 6), "districts": 1.0, "window_energy": 1.8}), towers)


# --- Every frame ----------------------------------------------------------------------------------

## Takes the view at bay 2's glass, as a cut.
func go() -> void:
	var cam := _obs.get_node_or_null("FlyCamera") as Camera3D
	if cam == null:
		return
	var move := _obs.get_node_or_null("ViewMove")
	if move != null and move.has_method("cut"):
		move.call("cut")
	cam.look_at_from_position(VIEW[0], VIEW[1], Vector3.UP)
	cam.fov = VIEW[2]
	var e := cam.basis.get_euler()
	cam.set("_yaw", e.y)
	cam.set("_pitch", e.x)
	stats.views = int(stats.get("views", 0)) + 1


## In the web build, window.__obsGardens for the page's tests.
func _web_state() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__obsGardens = %s" % JSON.stringify({"enabled": enabled, "visible": garden_visible,
			"level": _level, "views": stats.get("views", 0), "build_ms": stats.get("build_ms", 0.0)}), true)


func _process(delta: float) -> void:
	_swing_doors(delta)
	var show := show_always or Time.get_ticks_msec() < rt_warm_until or _bay_in_view() or _wing_view()
	if _garden.visible != show:
		_garden.visible = show
		garden_visible = show
		_web_state()
	stats.shown_frames += 1 if show else 0
	stats.hidden_frames += 0 if show else 1
	var quality := _obs.get_node_or_null("Quality")
	var level := int(quality.get("level")) if quality != null else 0
	if level != _level:
		_apply_quality(level)
	if _rt_lit and show and not _rt_lamps.is_empty():
		_rt_cull()
	if show:
		_zoom_fringe()


## The fringes' reach times the screen's zoom (FRINGE_ZOOM_MAX), in steps of a tenth.
func _zoom_fringe() -> void:
	var k := 1.0
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		if _view_fit == null or not is_instance_valid(_view_fit):
			_view_fit = _obs.get_node_or_null("ViewFit") if _obs != null else null
		if _view_fit != null:
			k = clampf(1.0 / clampf(float(_view_fit.get("zoom")), 0.001, 1.0), 1.0, FRINGE_ZOOM_MAX)
	if absf(k - _fringe_zoom) < 0.1 * _fringe_zoom and (k > 1.0 or _fringe_zoom == 1.0):
		return
	_fringe_zoom = k
	stats.fringe_zoom = snappedf(k, 0.01)
	for m: ShaderMaterial in _veg.fringe_mats:
		m.set_shader_parameter("near_r", FRINGE_R * k)
	for c: MultiMeshInstance3D in _veg.fringe:
		c.visibility_range_end = FRINGE_R * k + FRINGE_CHUNK * 0.75


## The lamps nearest the camera shown, the others hidden (RT_LAMPS_SHOWN), at most four times a second.
func _rt_cull() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var cam := get_viewport().get_camera_3d()
	if cam == null or now - _rt_culled_at < 0.25:
		return
	_rt_culled_at = now
	var eye := cam.global_position
	var near: Array = []
	for l in _rt_lamps:
		near.append([l.global_position.distance_squared_to(eye), l])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for i in near.size():
		(near[i][1] as OmniLight3D).visible = i < RT_LAMPS_SHOWN


## Whether the camera sees out through one of the library wing's windows (library_wing.gd).
func _wing_view() -> bool:
	var wing := _wing()
	return wing != null and bool(wing.call("window_in_view"))


## Whether the camera that draws is in the hall with a bay's opening in its view.
func _bay_in_view() -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var corridor := _obs.get_node_or_null("Multiverse")
	if corridor != null and bool(corridor.get("inside")):
		return false
	var p := cam.global_position
	# Out to outer + 1: walking out, extra_views.gd shows the gardens from outer + 0.8 on.
	if Vector2(p.x, p.z).length() > float(_obs.get("outer_radius")) + 1.0 or p.y > float(_obs.get("_ceiling_y")):
		return false
	for o in _openings:
		var c: Vector3 = o.centre
		if p.distance_to(c) < 3.5:
			return true  # in the recess, or in the doorway either side of the glass
		var inward: Vector3 = o["in"]
		if (p - c).dot(inward) < 0.05:
			continue
		if p.distance_to(c) < 3.5 or cam.is_position_in_frustum(c):
			return true
		for q: Vector3 in o.corners:
			if cam.is_position_in_frustum(q):
				return true
	return false


## Level 3 on: half the bosquets' trees, no jets. Level 4 on: no far woods either, nor the shafts, nor the
## painted city where it stands in for the night city.
func _apply_quality(level: int) -> void:
	_level = level
	for mmi in _thin:
		var n := mmi.multimesh.instance_count
		mmi.multimesh.visible_instance_count = -1 if level < 3 else int(mmi.get_meta("keep", n / 2))
	for l: Array in _lods:
		(l[0] as MultiMeshInstance3D).multimesh.mesh = l[1] if level < 3 else l[2]
	for j in _jets:
		j.visible = level < 3
	if _show != null:
		_show.call("set_quality", level)
	for f in _far:
		f.visible = level < 4
	for r in _rays:
		r.visible = level < 4
	# The kit's trees: meshes out to the level's radius, then their views; from level 3, the views alone,
	# and no sprays on the hedges.
	var near: float = VEG_NEAR_R[clampi(level, 0, VEG_NEAR_R.size() - 1)]
	if near != float(_veg.near_r):
		_veg.near_r = near
		for m: ShaderMaterial in _veg.near_mats:
			m.set_shader_parameter("near_r", near)
		for m: ShaderMaterial in _veg.far_mats:
			m.set_shader_parameter("near_r", near)
		for c: MultiMeshInstance3D in _veg.chunks:
			c.visible = near > 0.0
			c.visibility_range_end = near + VEG_CHUNK * 0.75
	for f: MultiMeshInstance3D in _veg.fringe:
		f.visible = level < 3
	# The crowd: everyone to level 2, then half, then a third.
	if _crowd != null:
		_crowd.call("set_quality", level)
		stats.crowd_shown = (_crowd.get("stats") as Dictionary).shown
	stats.veg_near_r = near
	stats.level = level
	_web_state()
