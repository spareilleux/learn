"""The Observatory's native builds, from ../project (the published web build's tree).

    python native.py prepare <project> <tree> [--templates <dir>]
        Copies the project to <tree> for a desktop build: Forward+ (Godot falls back to OpenGL by itself
        where Vulkan, Metal or Direct3D 12 is missing), the name "Observatory", and export presets for
        Windows, Linux and macOS with the web preset's exclude_filter. --templates names a folder holding
        Godot's release templates (windows_release_x86_64.exe, linux_release.x86_64, macos.zip), for a
        machine whose Godot has none installed.
    python native.py stage <export dir>
        Puts LICENSES.txt, GODOT_COPYRIGHT.txt and README.txt beside an export.
    python native.py version <project>
        Prints the package version: the scene's version (scripts/build_info.gd) as <n>.0.0.

Python 3.9 or later, standard library only.
"""
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GODOT_TAG = '4.6.1-stable'
GODOT_COMMIT = '14d19694e0c88a3f9e82d899a0400f27a24c176e'
BUNDLE_ID = 'io.github.spareilleux.observatory'
AUTHOR = 'Stephane Pareilleux'


def read(path):
    with open(path, encoding='utf-8') as f:
        return f.read().replace('\r\n', '\n')


def write(path, text):
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)


def scene_version(project):
    m = re.search(r'^const VERSION := (\d+)', read(os.path.join(project, 'scripts', 'build_info.gd')), re.M)
    assert m and int(m.group(1)) > 0, 'scripts/build_info.gd has no published version'
    return int(m.group(1))


def sub_once(pattern, repl, text, what):
    new, n = re.subn(pattern, repl, text, flags=re.M)
    assert n == 1, f'{what}: {n} matches'
    return new


def presets(exclude, version, templates):
    def tpl(name):
        return os.path.join(templates, name).replace('\\', '/') if templates else ''

    common = ('runnable=false\nadvanced_options=false\ndedicated_server=false\ncustom_features=""\n'
              'export_filter="all_resources"\ninclude_filter=""\n'
              f'exclude_filter="{exclude}"\n'
              'encryption_include_filters=""\nencryption_exclude_filters=""\nencrypt_pck=false\n'
              'encrypt_directory=false\nscript_export_mode=2\n')
    v4 = f'{version}.0.0.0'
    v3 = f'{version}.0.0'
    return f'''[preset.0]

name="Windows Desktop"
platform="Windows Desktop"
export_path="out/windows/Observatory.exe"
{common}
[preset.0.options]

custom_template/debug=""
custom_template/release="{tpl('windows_release_x86_64.exe')}"
debug/export_console_wrapper=0
binary_format/embed_pck=false
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
binary_format/architecture="x86_64"
codesign/enable=false
application/modify_resources=true
application/icon=""
application/file_version="{v4}"
application/product_version="{v4}"
application/company_name="{AUTHOR}"
application/product_name="Observatory"
application/file_description="Observatory"
application/copyright=""
application/trademarks=""

[preset.1]

name="Linux"
platform="Linux"
export_path="out/linux/observatory.x86_64"
{common}
[preset.1.options]

custom_template/debug=""
custom_template/release="{tpl('linux_release.x86_64')}"
debug/export_console_wrapper=0
binary_format/embed_pck=false
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
binary_format/architecture="x86_64"

[preset.2]

name="macOS"
platform="macOS"
export_path="out/macos/Observatory.zip"
{common}
[preset.2.options]

export/distribution_type=1
binary_format/architecture="universal"
custom_template/debug="{tpl('macos.zip')}"
custom_template/release="{tpl('macos.zip')}"
debug/export_console_wrapper=0
application/icon=""
application/bundle_identifier="{BUNDLE_ID}"
application/signature=""
application/app_category="Games"
application/short_version="{v3}"
application/version="{v3}"
application/copyright=""
display/high_res=true
codesign/codesign=1
notarization/notarization=0
'''


def prepare(project, tree, templates):
    if os.path.exists(tree):
        sys.exit(f'{tree} exists')
    shutil.copytree(project, tree, ignore=shutil.ignore_patterns('.godot', 'out'))
    version = scene_version(tree)
    path = os.path.join(tree, 'project.godot')
    text = read(path)
    text = sub_once(r'^config/name="Observatory Web"$', 'config/name="Observatory"', text, 'config/name')
    text = sub_once(r'^config/description=".*"$', 'config/description="The Observatory, native."', text, 'description')
    text = sub_once(r'^(config/features=PackedStringArray\("[\d.]+", )"GL Compatibility"\)$', r'\1"Forward Plus")', text, 'features')
    text = sub_once(r'^renderer/rendering_method="gl_compatibility"$', 'renderer/rendering_method="forward_plus"', text, 'renderer')
    # macOS's universal build needs ETC2/ASTC beside S3TC/BPTC; each export keeps only its own formats.
    text = sub_once(r'^\[rendering\]$', '[rendering]\n\ntextures/vram_compression/import_etc2_astc=true', text, 'rendering section')
    write(path, text)
    web = read(os.path.join(project, 'export_presets.cfg'))
    exclude = re.search(r'^exclude_filter="([^"]*)"$', web, re.M).group(1)
    write(os.path.join(tree, 'export_presets.cfg'), presets(exclude, version, templates))
    print(f'prepared {tree}: scene version {version}, Forward+, presets Windows Desktop, Linux, macOS'
          + (f', templates from {templates}' if templates else ''))


README = '''Observatory {v}

The Observatory of https://spareilleux.github.io/learn/observatory/ (version {scene} of the scene), native,
on the Godot Engine {tag}. It renders with Godot's Forward+ renderer (Vulkan, Metal or Direct3D 12),
and falls back to OpenGL where none of those is available.

Keys: the scene shows its own at the top left. WASD to walk, F to fly, 1-9 for the views, Tab for the
curios, G to ride in the gardens; Esc releases the mouse.

Built by GitHub Actions from https://github.com/spareilleux/learn/tree/main/code/observatory
LICENSES.txt lists the engine's licence and where each of the scene's assets comes from.
'''


def stage(out):
    project = os.path.join(HERE, '..', 'project')
    scene = scene_version(project)
    mit = read(os.path.join(HERE, 'godot', 'LICENSE.txt')).strip('\n')
    assets = read(os.path.join(HERE, 'ASSETS.txt')).strip('\n')
    licenses = f'''Observatory {scene}.0.0 (version {scene} of the scene): engine and asset notices

----------------------------------------------------------------------------------------------------
The engine

Godot Engine {GODOT_TAG} (https://github.com/godotengine/godot, commit {GODOT_COMMIT}), its official
release templates, unchanged, under the Godot Engine's licence:

MIT License

{mit}

Godot's third-party copyright and licence inventory: GODOT_COPYRIGHT.txt, beside this file.

----------------------------------------------------------------------------------------------------
The scene

{assets}
'''
    write(os.path.join(out, 'LICENSES.txt'), licenses)
    shutil.copyfile(os.path.join(HERE, 'godot', 'COPYRIGHT.txt'), os.path.join(out, 'GODOT_COPYRIGHT.txt'))
    write(os.path.join(out, 'README.txt'), README.format(v=f'{scene}.0.0', scene=scene, tag=GODOT_TAG))
    print(f'staged notices in {out}')


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else ''
    if cmd == 'prepare':
        args = sys.argv[2:]
        templates = ''
        if '--templates' in args:
            i = args.index('--templates')
            templates = os.path.abspath(args[i + 1])
            del args[i:i + 2]
        prepare(os.path.abspath(args[0]), os.path.abspath(args[1]), templates)
    elif cmd == 'stage':
        stage(os.path.abspath(sys.argv[2]))
    elif cmd == 'version':
        print(f'{scene_version(sys.argv[2])}.0.0')
    else:
        sys.exit(__doc__)
