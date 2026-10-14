"""The RTX package's sources, copied into learn's code/observatory/rtx so that GitHub holds them (NOTES.md):
the player and its probe and bridge, the build and test scripts, the installer, the MCP server, and the
local patches of NVIDIA's Godot fork with their whole diff. Logs, captures and builds stay here.
    py -3.14 sync_rtx_learn.py <learn checkout>
rtx/ in learn is replaced wholesale: a file deleted here goes there too."""
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
RTX_COPY = r'C:\tmp\observatory-foundation-rtx'
FORK = r'C:\tmp\godot-nvidia-dlss'
LEARN = sys.argv[1]
DEST = os.path.join(LEARN, 'code', 'observatory', 'rtx')
KEEP = ('.gd', '.ps1', '.py', '.cmd', '.cfg', '.tscn', '.txt', '.md', '.wxs', '.go', '.mod')
SKIP_DIRS = {'logs', 'out', '__pycache__', 'bin'}

if os.path.exists(DEST):
    shutil.rmtree(DEST)
n = 0
for d, dirs, names in os.walk(HERE):
    dirs[:] = [x for x in dirs if x not in SKIP_DIRS]
    for name in names:
        if name.endswith(KEEP):
            rel = os.path.relpath(os.path.join(d, name), HERE)
            os.makedirs(os.path.dirname(os.path.join(DEST, rel)), exist_ok=True)
            shutil.copy2(os.path.join(d, name), os.path.join(DEST, rel))
            n += 1
# The player's base: dlss_play.gd and the path tracer's dressing, as the package takes them (assemble_rtx.py).
for name in ('dlss_play.gd', 'pt_scene.gd', 'pt_night_sky.gdshader'):
    os.makedirs(os.path.join(DEST, 'player-base'), exist_ok=True)
    shutil.copy2(os.path.join(RTX_COPY, 'artpass', 'dlss', name), os.path.join(DEST, 'player-base', name))
    n += 1
# The fork: each patch script, and the whole local diff over the commit they apply to.
fork_dest = os.path.join(DEST, 'fork')
os.makedirs(fork_dest, exist_ok=True)
for name in sorted(os.listdir(FORK)):
    if name.endswith('.py'):
        shutil.copy2(os.path.join(FORK, name), os.path.join(fork_dest, name))
        n += 1
git = os.path.join(FORK, 'godot')
head = subprocess.run(['git', '-C', git, 'rev-parse', 'HEAD'], capture_output=True, text=True, check=True).stdout.strip()
branch = subprocess.run(['git', '-C', git, 'rev-parse', '--abbrev-ref', 'HEAD'], capture_output=True, text=True, check=True).stdout.strip()
diff = subprocess.run(['git', '-C', git, 'diff', '--no-color'], capture_output=True, check=True).stdout
with open(os.path.join(fork_dest, 'local-changes.diff'), 'wb') as f:
    f.write(diff.replace(b'\r\n', b'\n'))
stat = subprocess.run(['git', '-C', git, 'diff', '--stat'], capture_output=True, text=True, check=True).stdout
with open(os.path.join(fork_dest, 'BASE.txt'), 'w', encoding='utf-8', newline='\n') as f:
    f.write('https://github.com/NVIDIA-RTX/godot.git, branch %s, commit %s\n' % (branch, head))
    f.write('local-changes.diff is `git diff` of the checkout after the patch scripts here ran:\n\n' + stat)
print('copied', n, 'files and the fork diff (%d bytes) into' % len(diff), DEST)
