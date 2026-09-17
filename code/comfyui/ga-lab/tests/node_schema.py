"""Input names of ComfyUI nodes read from Python source, without importing torch or starting a server.

Two node styles exist in ComfyUI v0.36.0: the V1 classes (INPUT_TYPES returns a dict, registered in
NODE_CLASS_MAPPINGS as "Name": Class) and the V3 schema (node_id="Name", inputs written io.Int.Input("name")).
This reads both with regular expressions: good enough to catch a misspelled class or input in a workflow, not a
parser. CI checks the same workflows against a real server's /object_info.
"""
import os
import re

V3_BLOCK = re.compile(r'node_id="([A-Za-z0-9_+\-]+)"(.*?)(?=node_id="|\Z)', re.S)
V3_INPUT = re.compile(r'\.Input\(\s*"([A-Za-z0-9_]+)"')
MAPPING = re.compile(r'"([A-Za-z0-9_+\-]+)"\s*:\s*([A-Za-z_][A-Za-z0-9_]*)\s*[,}\n]')
V1_KEY = re.compile(r'"([A-Za-z0-9_]+)"\s*:\s*\(')


def python_files(roots):
    for root in roots:
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = [d for d in dirnames if d not in (".git", "tests", "tests-unit", "web", "node_modules")]
            for name in filenames:
                if name.endswith(".py"):
                    yield os.path.join(dirpath, name)


def v1_inputs(classes, cls, depth=0):
    body = classes.get(cls, "")
    match = re.search(r"def INPUT_TYPES.*?(?=\n    [A-Za-z_]+\s*=|\n    def |\Z)", body, re.S)
    if not match:
        return set()
    names = set(V1_KEY.findall(match.group(0)))
    parent = re.match(r"class \w+\((\w+)\)", body)
    if "super().INPUT_TYPES()" in match.group(0) and parent and depth < 5:
        names |= v1_inputs(classes, parent.group(1), depth + 1)  # LoadImageMask extends LoadImage's inputs
    return names


def schemas(roots):
    sources = {}
    for path in python_files(roots):
        try:
            with open(path, encoding="utf-8") as f:
                sources[path] = f.read()
        except (OSError, UnicodeDecodeError):
            continue
    result = {}
    classes = {}
    for path, text in sources.items():
        for m in re.finditer(r"^class ([A-Za-z_][A-Za-z0-9_]*)\b.*?(?=^class |\Z)", text, re.S | re.M):
            classes.setdefault(m.group(1), m.group(0))
        for m in V3_BLOCK.finditer(text):
            body = m.group(2)
            cut = body.find("def execute")
            result.setdefault(m.group(1), set()).update(V3_INPUT.findall(body if cut < 0 else body[:cut]))
    for path, text in sources.items():
        for block in re.findall(r"NODE_CLASS_MAPPINGS\s*=\s*\{(.*?)\}", text, re.S):
            for name, cls in MAPPING.findall(block):
                result.setdefault(name, set()).update(v1_inputs(classes, cls))
    return result
