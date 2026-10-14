"""The native package's project tree: the fork's copy of the Foundation redesign, without what never ships.
    py -3.14 assemble_rtx.py <foundation copy> <fork copy> <new tree>
The scripts and assets are the fork copy's (its .import files are in the fork's format), and each must be
byte for byte the Foundation copy's, whose git names the commit. Left out, as the Web export leaves them:
Daneel (never ships), the Prime Radiant (an experiment: observatory.gd falls back without its files), the
SDXL tree cards (unused when the vegetation kit loads) and the first steel shell (read only with gaia_art
off). Kept, unlike the Web export: the gilt's metal shader, the shelves' wood, the stone's slope map and the
palace's 4096 light map, which the native renderer and the path tracer use.
The player goes to rtx/, outside artpass/ (a .gdignore there keeps it out of an export): dlss_play.gd,
pt_scene.gd and its sky shader as they are, and rtx_play.gd over them with its probe and its empty main
scene. project.godot is the fork copy's with the package's name, the one setting of the fork copy's
override.cfg, the player as the main loop, Vulkan and a maximised window."""
import hashlib
import io
import os
import shutil
import sys

FDN, RTX, TREE = (a.rstrip('/\\') for a in sys.argv[1:4])
LEFT = {
    'scripts/daneel_statue.gd', 'assets/daneel_marble.gdshader', 'assets/daneel_statue.glb',
    'scripts/prime_radiant.gd', 'assets/prime_radiant.glb', 'assets/gem.gdshader', 'assets/radiant_core.gdshader',
    'assets/radiant_crystal.gdshader', 'assets/radiant_glyphs.gdshader', 'assets/radiant_glyphs.png',
    'assets/radiant_particles.gdshader',
    'assets/garden_cypress.png', 'assets/garden_trees.png',
    'assets/steel_portal.glb', 'assets/steel_portal_SteelBrushed_MetalRough.png', 'assets/steel_portal_SteelBrushed_normal.png',
}
SIDE = ('.import', '.uid')
PLAYER = {  # in the tree: from
    'rtx/dlss_play.gd': (RTX, 'artpass/dlss/dlss_play.gd'),
    'rtx/pt_scene.gd': (RTX, 'artpass/dlss/pt_scene.gd'),
    'rtx/pt_night_sky.gdshader': (RTX, 'artpass/dlss/pt_night_sky.gdshader'),
    'rtx/rtx_play.gd': (FDN, 'artpass/publish/rtx/rtx_play.gd'),
    'rtx/rtx_probe.gd': (FDN, 'artpass/publish/rtx/rtx_probe.gd'),
    'rtx/rtx_bridge.gd': (FDN, 'artpass/publish/rtx/rtx_bridge.gd'),
    'rtx/rtx_life.gd': (FDN, 'artpass/publish/rtx/rtx_life.gd'),
    'rtx/stage.tscn': (FDN, 'artpass/publish/rtx/stage.tscn'),
}
TOP = ('main.tscn', 'icon.svg', 'icon.svg.import')


def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def put(src, rel):
    dst = os.path.join(TREE, rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy2(src, dst)
    return os.path.getsize(dst)


if os.path.exists(TREE):
    sys.exit(TREE + ' exists')
bad, copied, size, left = [], 0, 0, []
for root in ('scripts', 'assets'):
    for d, dirs, names in os.walk(os.path.join(RTX, root)):
        for n in sorted(names):
            p = os.path.join(d, n)
            rel = os.path.relpath(p, RTX).replace('\\', '/')
            base = rel
            for s in SIDE:
                if rel.endswith(s):
                    base = rel[:-len(s)]
            if base in LEFT:
                if base == rel:
                    left.append(rel)
                continue
            if os.path.basename(base).startswith('daneel_') or n.endswith('.tmp'):
                bad.append('unexpected: ' + rel)
                continue
            if base == rel:  # the file itself, not its .import or .uid: the Foundation copy's, byte for byte
                f = os.path.join(FDN, rel)
                if not os.path.exists(f):
                    bad.append('only in the fork copy: ' + rel)
                    continue
                if os.path.getsize(f) != os.path.getsize(p) or sha(f) != sha(p):
                    bad.append('differs from the Foundation copy: ' + rel)
                    continue
            size += put(p, rel)
            copied += 1
for d, dirs, names in os.walk(os.path.join(FDN, 'scripts')):
    for n in names:
        rel = os.path.relpath(os.path.join(d, n), FDN).replace('\\', '/')
        if not rel.endswith(SIDE) and rel not in LEFT and not os.path.exists(os.path.join(RTX, rel)):
            bad.append('only in the Foundation copy: ' + rel)
for rel in sorted(LEFT):
    if rel not in left:
        bad.append('named as left out, not in the fork copy: ' + rel)
if bad:
    shutil.rmtree(TREE, ignore_errors=True)
    print('\n'.join(bad))
    sys.exit('the two copies do not agree: nothing assembled')
for rel in TOP:
    size += put(os.path.join(RTX, rel), rel)
for rel, (base, src) in PLAYER.items():
    size += put(os.path.join(base, src), rel)

# project.godot: the fork copy's, named for the package, with override.cfg's setting.
s = io.open(os.path.join(RTX, 'project.godot'), encoding='utf-8', newline='').read().replace('\r\n', '\n')
old = 'config/name="Observatory Prototype v1"\n'
assert s.count(old) == 1
s = s.replace(old, 'config/name="Observatory RTX"\n')
old = 'renderer/rendering_method="forward_plus"\n'
assert s.count(old) == 1
assert 'multimesh_merged_blas_max_triangles' not in s
override = io.open(os.path.join(RTX, 'override.cfg'), encoding='utf-8').read()
key = 'pathtracing/multimesh_merged_blas_max_triangles=4194304'
assert key in override, 'override.cfg no longer holds ' + key
s = s.replace(old, old + key + '\n' + 'rendering_device/driver.windows="vulkan"\n')
# A release template takes no --script: the player is the project's main loop, over an empty main scene
# (rtx_play.gd), and what the author's launcher passes as arguments is set here.
old = 'run/main_scene="res://main.tscn"\n'
assert s.count(old) == 1
s = s.replace(old, 'run/main_scene="res://rtx/stage.tscn"\nrun/main_loop_type="ObservatoryRtx"\n')
old = 'window/size/viewport_height=900\n'
assert s.count(old) == 1
s = s.replace(old, old + 'window/size/mode=2\n')
io.open(os.path.join(TREE, 'project.godot'), 'w', encoding='utf-8', newline='\n').write(s)

# Every res:// path the scripts name is in the tree, or is one of those left out (each guarded by
# ResourceLoader.exists in the script that names it; paths built with % are skipped).
import re
miss = set()
for d, dirs, names in os.walk(TREE):
    for n in names:
        if n.endswith(('.gd', '.gdshader', '.gdshaderinc', '.tres', '.tscn')):
            text = io.open(os.path.join(d, n), encoding='utf-8', errors='replace').read()
            for m in re.findall(r'res://[^"\'\s)]+', text):
                if '%' in m or m.endswith('/'):
                    continue
                if not os.path.exists(os.path.join(TREE, m[6:])):
                    miss.add(m)
print('assembled', TREE, ':', copied, 'files of scripts/ and assets/,', f'{size:,}', 'bytes with the player')
print('left out:', len(left))
for rel in sorted(left):
    print('   -', rel)
print('res:// paths named and not in the tree:', len(miss))
for m in sorted(miss):
    print('   ?', m, '(left out)' if m[6:] in LEFT else '')
