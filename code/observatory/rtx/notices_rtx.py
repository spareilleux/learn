"""LICENSES.txt of the Observatory's native package: the engine's licences as the fork's checkout has them,
then the scene's asset notices (ASSETS.txt, beside this file: the Web distribution's, with the credits its
page carries, since the zip travels without the page).
    py -3.14 notices_rtx.py <foundation copy> <fork folder> <package version> <scene version>
Writes out/LICENSES.txt beside this file."""
import io
import os
import subprocess
import sys

FDN, FORK, VERSION, SCENE = sys.argv[1].rstrip('/\\'), sys.argv[2].rstrip('/\\'), sys.argv[3], sys.argv[4]
HERE = os.path.dirname(os.path.abspath(__file__))
GODOT = os.path.join(FORK, 'godot')


def read(path):
    return io.open(path, encoding='utf-8').read().replace('\r\n', '\n').strip('\n')


def git(*args):
    return subprocess.run(['git', '-C', GODOT, *args], capture_output=True, text=True, check=True).stdout.strip()


commit = git('rev-parse', 'HEAD')
branch = git('branch', '--show-current')
origin = git('remote', 'get-url', 'origin')
assert origin == 'https://github.com/NVIDIA-RTX/godot.git', origin
touched = [l[3:] for l in git('status', '--porcelain').split('\n') if l.strip()]
fdn_commit = subprocess.run(['git', '-C', FDN, 'rev-parse', '--short', 'HEAD'], capture_output=True, text=True, check=True).stdout.strip()
mit = read(os.path.join(GODOT, 'LICENSE.txt'))
assert mit.startswith('Copyright (c) 2014-present Godot Engine contributors'), mit[:60]
sl = read(os.path.join(FORK, 'streamline', 'sdk', 'license.txt'))
sl = sl[:sl.index('*/') + 2]  # its first block; the second is the NSight Perf SDK's, for sl_nvperf.h
assert 'NVIDIA CORPORATION' in sl and 'Permission is hereby granted, free of charge' in sl and 'NSight' not in sl
# sl_nvperf.h lies in the fork's tree, under that other licence: nothing the engine compiles includes it.
for top in ('drivers', 'servers', 'platform/windows', 'thirdparty/streamline'):
    for d, dirs, names in os.walk(os.path.join(GODOT, top)):
        for n in names:
            if n.endswith(('.h', '.cpp', '.inc')) and n != 'sl_nvperf.h':
                code = io.open(os.path.join(d, n), encoding='utf-8', errors='replace').read()
                assert 'sl_nvperf' not in code, os.path.join(d, n) + ' includes sl_nvperf.h'
# The Streamline headers the engine is compiled with carry that same licence.
header = read(os.path.join(GODOT, 'thirdparty', 'streamline', 'include', 'sl.h'))
assert 'Permission is hereby granted, free of charge' in header[:400], 'sl.h has no MIT header'
assets = read(os.path.join(HERE, 'ASSETS.txt'))

text = f'''Observatory RTX {VERSION} (version {SCENE} of the scene): engine and asset notices

This package holds the Observatory's scene and a build of NVIDIA's fork of the Godot Engine. It holds no
file of NVIDIA's DLSS, Streamline or Reflex run times: setup-dlss.ps1 downloads those on your machine from
NVIDIA's own release (https://github.com/NVIDIA-RTX/Streamline/releases/tag/v2.10.0), where they stay
NVIDIA's software under NVIDIA's licences, which it puts in the nvidia-licenses folder.

NVIDIA, GeForce, RTX and DLSS are trademarks of NVIDIA Corporation. This package is not sponsored,
endorsed or supported by NVIDIA.

----------------------------------------------------------------------------------------------------
The engine

Godot Engine 4.6.3, NVIDIA's fork ({origin[:-4]}, branch
{branch}, commit {commit}), built from source with {len(touched)}
files changed locally by the Observatory's author: Streamline's loader made to take sl.interposer.dll
only from the program's own folder and only when NVIDIA's signature on it verifies, with no over-the-air
update; two texture bindings corrected; DLSS's output declared as written, so that it is shown in its
own frame; in the path tracer, hand-written shader materials with their instance colours, emission,
unshaded materials and normal matrix, the Environment's ambient colour as light for the bounces, and the
compiler's message when a hit shader fails; a status call for DLSS. The fork and those changes are under
the Godot Engine's licence:

MIT License

{mit}

Godot's third-party copyright and licence inventory: GODOT_COPYRIGHT.txt, beside this file (the fork's
COPYRIGHT.txt at that commit).

The engine is compiled with header files of NVIDIA's Streamline SDK, under this licence (sl_nvperf.h,
which is under another, is not among them):

{sl}

----------------------------------------------------------------------------------------------------
The scene (the Foundation copy at {fdn_commit})

{assets}
'''
os.makedirs(os.path.join(HERE, 'out'), exist_ok=True)
out = os.path.join(HERE, 'out', 'LICENSES.txt')
io.open(out, 'w', encoding='utf-8', newline='\n').write(text)
print('LICENSES.txt:', len(text.split('\n')), 'lines; fork', commit[:10], 'with', len(touched), 'files changed; scene', fdn_commit)
