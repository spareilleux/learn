"""CPU verification of the frozen steel increment, without imports or rendering."""
from pathlib import Path
import ast
import hashlib
import json
import struct

root = Path(__file__).resolve().parent
manifest = json.loads((root / 'snapshot.json').read_text())
for name, entry in manifest['files'].items():
    target = (root / name).resolve()
    assert target.is_relative_to(root), name
    raw = target.read_bytes()
    assert len(raw) == entry['bytes'], name
    assert hashlib.sha256(raw).hexdigest() == entry['sha256'], name
ast.parse((root / 'artpass/gaia/blender/steel_portal_gaia.py').read_text())
raw = (root / 'assets/steel_portal_gaia.glb').read_bytes()
magic, version, size = struct.unpack_from('<4sII', raw)
assert (magic, version, size) == (b'glTF', 2, len(raw))
count, kind = struct.unpack_from('<II', raw, 12)
assert kind == 0x4e4f534a
gltf = json.loads(raw[20:20+count])
offset = 20+count
count, kind = struct.unpack_from('<II', raw, offset)
assert kind == 0x004e4942
data = raw[offset+8:offset+8+count]
assert len(gltf['meshes']) == 25
assert {'DoorHinge', 'DoorLeaf', 'Shell'} <= {n.get('name') for n in gltf['nodes']}
for image in gltf['images']:
    view = gltf['bufferViews'][image['bufferView']]
    start = view.get('byteOffset', 0)
    embedded = data[start:start+view['byteLength']]
    assert embedded == (root / 'artpass/blender/textures' / (image['name']+'.png')).read_bytes()
for accessor in gltf['accessors']:
    if 'bufferView' in accessor:
        assert 0 <= accessor['bufferView'] < len(gltf['bufferViews'])
for view in gltf['bufferViews']:
    assert view.get('byteOffset', 0)+view['byteLength'] <= len(data)
receipt = json.loads((root / 'evidence/execution-preset3.json').read_text())
assert receipt['ExitCode'] == 0 and receipt['ProcessGone'] and not receipt['BudgetStopped']
assert receipt['ElapsedSeconds'] == 73.58 and receipt['ElapsedSeconds'] < 120
probe = json.loads((root / 'evidence/pt-preset3.json').read_text())
assert len(probe['checks']) == 32 and all(probe['checks'].values())
assert probe['states']['shellnew']['steel']['steel_preset'] == 3
assert probe['pt_settings'] == {'spp':2, 'bounces':3, 'denoiser':1, 'scale':1.0, 'frame_generation':False}
print(json.dumps({'files_hash_checked':len(manifest['files']), 'meshes':25, 'embedded_texture_byte_matches':len(gltf['images']), 'historical_capture_checks':32, 'preset':3, 'new_gpu_runs':0}))
