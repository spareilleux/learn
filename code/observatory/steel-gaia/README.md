# Observatory: Gaia steel shell v2, preset 3

The research box replaces its round corner rods with folded sheet corners, thinner seam bands, smaller irregular rivets, a stepped cornice and plinth, and a detailed hinged door. The completed Gaia snapshot selects steel preset 3. This directory preserves that bounded source-and-asset increment, completed on 2026-10-06 at 23:17:58 UTC.

It is an overlay for the existing native Observatory project, not a complete replacement project. Copy `scripts/steel_cube.gd` and the three files in `assets/` into that project's matching paths after backing them up. Keep the existing `assets/steel_portal.glb`: the old-shell/control toggle depends on it. The selected new shell is `assets/steel_portal_gaia.glb`; `gaia_art = true`, `gaia_shell = true`, `gaia_steel = 3`. The local source project was `C:/tmp/observatory-gaia`.

The existing public WebGL package under `public/demos/observatory/` is a separate build. This source publication does not update its PCK or make it use NVIDIA ray tracing. The owner is still tuning Compatibility in the separate prototype; those unfinished changes are excluded from this snapshot. Preset 3 was chosen from path-traced results; its appearance under Compatibility is not approved by this publication.

## Verification

Run from this directory with Python 3 (standard library only):

```sh
python -B verify_snapshot.py
```

This checks file hashes, GLB structure, the exact embedded texture bytes and the completed capture receipt. It does not render or prove equivalent appearance in other engines.

Historical owner tests in `evidence/` checked the transfer into the prototype with official Godot 4.6.1 under Forward+ and Compatibility: selftests reported `missing: []`; each flytest passed 11/11. They precede the owner's further Compatibility tuning. They are not new tests of a complete application distributed here.

The completed NVIDIA capture used the 4.6.3 fork at `e1157bf10f70bef34933a80a5d29f6e6788a0dc6`, Forward+/Vulkan, 2 path-tracing samples per pixel, 3 bounces, denoiser 1 (DLSS Ray Reconstruction), DLSS scale 1.0 and frame generation off. The three views of the old shell, new shell and control were 3840 × 2160; 32/32 automated checks passed. The process ran 73.58 seconds, exited 0 and was gone afterwards. See `evidence/pt-preset3.json` and the trimmed execution receipt. This historical capture is not evidence of a later interactive launch.

The capture harness explicitly sets otherwise-unset `source_color` defaults for the fork's ray-tracing material path and supplies the 56-light PT set and sky. Those probe changes are not an engine fix or included in this steel-only overlay. Reproducing the full approved image requires the existing harness and hall, not just these files. No performance comparison against standard Godot is claimed from different capture protocols.

## Blender source

`artpass/gaia/blender/steel_portal_gaia.py` is the authored builder, with only its texture directory made relative to the project root in this published copy. The original is unchanged; `snapshot.json` records both hashes. It expects the nearest enclosing `project.godot` and the two existing textures in `artpass/blender/textures/`. The generated GLB is already included; rebuilding or rendering is unnecessary to verify it.

Builder report: Blender 5.2.2 LTS, seed 20261006, 61,638 reported faces, 808 rivets, 12 hex bolts, four missing fasteners, six flush screws, 30 mm corner radius. The final v2 mesh contains 25 mesh parts; weighted panel normals correct the flat panel's diagonal shading. No downloaded geometry or model weights are included.

See [NOTICES.md](NOTICES.md) for texture provenance and distribution notices.
