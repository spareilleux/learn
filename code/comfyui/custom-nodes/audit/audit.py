"""Reads a ComfyUI custom node pack without running it, and lists the code worth reading before installing it.

    python audit.py <pack folder> [<pack folder> ...] [--details N]

Only the standard library is used, and nothing from the pack is imported or executed: Python files are parsed with
ast, JavaScript files and requirements are read as text. A finding is a place to read, not a verdict: most packs
call subprocess or download models for good reasons, and a pack with no finding can still be malicious (code can be
hidden in a dependency, a downloaded file, or an update).
"""

import argparse
import ast
import re
import sys
import warnings
from collections import Counter
from pathlib import Path

SKIP_DIRS = {".git", "node_modules", "__pycache__", ".venv", "venv", "dist", "build"}

# Files ComfyUI or ComfyUI-Manager run by themselves.
AUTORUN = {
    "__init__.py": "imported by ComfyUI at every start",
    "prestartup_script.py": "run by ComfyUI at every start, before the nodes load",
    "install.py": "run by ComfyUI-Manager after install and update",
    "requirements.txt": "installed with pip by ComfyUI-Manager",
}

RULES = {
    "autorun": "file that runs without being asked",
    "subprocess": "starts a process (subprocess, os.system, os.popen, os.exec*)",
    "pip-runtime": "installs packages at run time (pip install from code)",
    "eval-exec": "evaluates code from a string (eval, exec, compile)",
    "obfuscation": "decodes data that may be code (base64, zlib, marshal)",
    "pickle": "unpickles data (pickle, dill, joblib, torch.load with weights_only=False, numpy allow_pickle=True)",
    "torch-load": "torch.load without weights_only: restricted by default since PyTorch 2.6, full pickle before",
    "network": "network call (urllib, requests, httpx, aiohttp client, socket)",
    "download": "downloads files or models (hf_hub_download, snapshot_download, torch.hub, wget)",
    "import-time": "one of the calls above sits outside any function: it runs as soon as the file is imported or run",
    "requirement-url": "requirement installed from a URL, a git repository, a local wheel or another index",
    "js-network": "browser code calling fetch, WebSocket or EventSource on an absolute URL, or XMLHttpRequest",
    "js-eval": "browser code evaluating a string as code (eval, new Function)",
}

CALLS = {
    "subprocess": {"subprocess.run", "subprocess.Popen", "subprocess.call", "subprocess.check_call",
                   "subprocess.check_output", "subprocess.getoutput", "subprocess.getstatusoutput",
                   "os.system", "os.popen", "os.execv", "os.execvp", "os.execl", "os.spawnl", "os.startfile",
                   "asyncio.create_subprocess_exec", "asyncio.create_subprocess_shell"},
    "eval-exec": {"eval", "exec", "compile", "builtins.eval", "builtins.exec"},
    "obfuscation": {"base64.b64decode", "base64.b32decode", "base64.a85decode", "codecs.decode",
                    "zlib.decompress", "marshal.loads"},
    "pickle": {"pickle.load", "pickle.loads", "cPickle.load", "cPickle.loads", "dill.load", "dill.loads",
               "joblib.load"},
    "network": {"urllib.request.urlopen", "urllib.request.urlretrieve", "requests.get", "requests.post",
                "requests.put", "requests.request", "requests.Session", "httpx.get", "httpx.post", "httpx.Client",
                "httpx.AsyncClient", "aiohttp.ClientSession", "socket.socket", "socket.create_connection",
                "http.client.HTTPConnection", "http.client.HTTPSConnection"},
    "download": {"huggingface_hub.hf_hub_download", "huggingface_hub.snapshot_download", "torch.hub.load",
                 "torch.hub.download_url_to_file", "torch.hub.load_state_dict_from_url", "wget.download",
                 "gdown.download"},
}
CALL_RULE = {name: rule for rule, names in CALLS.items() for name in names}

PIP_WORDS = re.compile(r"\bpip3?\b.*\binstall\b|\binstall\b.*\bpip\b", re.IGNORECASE)
JS_FETCH = re.compile(r"""\b(fetch|new\s+WebSocket|new\s+EventSource)\s*\(\s*[`'"](https?:|wss?:)?//""")
JS_XHR = re.compile(r"\bnew\s+XMLHttpRequest\b")
JS_EVAL = re.compile(r"(?<![\w.])eval\s*\(|\bnew\s+Function\s*\(")
REQ_URL = re.compile(r"(^|\s)(git\+|https?://|file:|--index-url|--extra-index-url|-i\s|--find-links|-f\s)|\.whl\b")


class Finding:
    def __init__(self, rule, path, line, text):
        self.rule, self.path, self.line, self.text = rule, path, line, text


def dotted(node):
    """ast for a.b.c -> 'a.b.c', or None."""
    parts = []
    while isinstance(node, ast.Attribute):
        parts.append(node.attr)
        node = node.value
    if isinstance(node, ast.Name):
        parts.append(node.id)
        return ".".join(reversed(parts))
    return None


class PythonAudit(ast.NodeVisitor):
    def __init__(self, path, rel, source):
        self.rel, self.lines = rel, source.splitlines()
        self.aliases = {}  # local name -> full dotted name, from imports anywhere in the file
        self.depth = 0     # > 0 inside a function or a lambda
        self.findings = []
        self.import_time_lines = set()

    def add(self, rule, node):
        text = self.lines[node.lineno - 1].strip() if node.lineno <= len(self.lines) else ""
        self.findings.append(Finding(rule, self.rel, node.lineno, text[:110]))
        if self.depth == 0 and node.lineno not in self.import_time_lines and                 rule in {"subprocess", "pip-runtime", "eval-exec", "network", "download", "pickle", "torch-load"}:
            self.import_time_lines.add(node.lineno)
            self.findings.append(Finding("import-time", self.rel, node.lineno, f"[{rule}] " + text[:100]))

    def visit_Import(self, node):
        for alias in node.names:
            self.aliases[alias.asname or alias.name.split(".")[0]] = alias.name if alias.asname else \
                alias.name.split(".")[0]
        self.generic_visit(node)

    def visit_ImportFrom(self, node):
        if node.module and node.level == 0:
            for alias in node.names:
                self.aliases[alias.asname or alias.name] = f"{node.module}.{alias.name}"
        self.generic_visit(node)

    def _scoped(self, node):
        self.depth += 1
        self.generic_visit(node)
        self.depth -= 1

    visit_FunctionDef = visit_AsyncFunctionDef = visit_Lambda = _scoped

    def visit_If(self, node):
        test = node.test  # if __name__ == "__main__": runs only when the file is run as a script
        if isinstance(test, ast.Compare) and isinstance(test.left, ast.Name) and test.left.id == "__name__":
            self.visit(test)
            self.depth += 1
            for child in node.body:
                self.visit(child)
            self.depth -= 1
            for child in node.orelse:
                self.visit(child)
        else:
            self.generic_visit(node)

    def resolve(self, func):
        name = dotted(func)
        if name is None:
            return None
        head, _, rest = name.partition(".")
        full = self.aliases.get(head, head)
        return f"{full}.{rest}" if rest else full

    def visit_Call(self, node):
        name = self.resolve(node.func)
        if name:
            rule = CALL_RULE.get(name)
            if rule is None and name.startswith("subprocess."):
                rule = "subprocess"
            if rule:
                self.add(rule, node)
            if rule == "subprocess" or name in {"os.system", "os.popen"}:
                words = " ".join(self._strings(node))
                if PIP_WORDS.search(words) or ("-m" in words.split() and "pip" in words.split()):
                    self.add("pip-runtime", node)
            if name in {"pip.main", "pip._internal.main", "pip._internal.cli.main.main"}:
                self.add("pip-runtime", node)
            if name == "torch.load":
                weights_only = next((k.value for k in node.keywords if k.arg == "weights_only"), None)
                if weights_only is None:
                    self.add("torch-load", node)
                elif not (isinstance(weights_only, ast.Constant) and weights_only.value is True):
                    self.add("pickle", node)
            if name in {"numpy.load", "np.load"}:
                if any(k.arg == "allow_pickle" and isinstance(k.value, ast.Constant) and k.value.value is True
                       for k in node.keywords):
                    self.add("pickle", node)
        self.generic_visit(node)

    @staticmethod
    def _strings(node):
        for child in ast.walk(node):
            if isinstance(child, ast.Constant) and isinstance(child.value, str):
                yield child.value


def audit_pack(root):
    root = Path(root)
    findings, counts, unparsed = [], Counter(), []
    for path in sorted(root.rglob("*")):
        if not path.is_file() or any(part in SKIP_DIRS for part in path.relative_to(root).parts):
            continue
        rel = path.relative_to(root).as_posix()
        counts["files"] += 1
        if rel in AUTORUN:
            findings.append(Finding("autorun", rel, 0, AUTORUN[rel]))
        suffix = path.suffix.lower()
        if suffix == ".py":
            counts["python"] += 1
            source = path.read_text(encoding="utf-8", errors="replace")
            try:
                with warnings.catch_warnings():
                    warnings.simplefilter("ignore", SyntaxWarning)  # invalid escapes in the pack's strings
                    tree = ast.parse(source, filename=rel)
            except SyntaxError:
                unparsed.append(rel)
                continue
            visitor = PythonAudit(path, rel, source)
            visitor.visit(tree)
            findings.extend(visitor.findings)
        elif suffix in {".js", ".mjs", ".ts"}:
            counts["javascript"] += 1
            for number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
                if JS_FETCH.search(line) or JS_XHR.search(line):
                    findings.append(Finding("js-network", rel, number, line.strip()[:110]))
                if JS_EVAL.search(line):
                    findings.append(Finding("js-eval", rel, number, line.strip()[:110]))
        elif path.name.startswith("requirements") and suffix == ".txt":
            for number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
                if REQ_URL.search(line.split("#")[0]):
                    findings.append(Finding("requirement-url", rel, number, line.strip()[:110]))
    return findings, counts, unparsed


def report(root, details, out):
    findings, counts, unparsed = audit_pack(root)
    by_rule = Counter(f.rule for f in findings)
    web = "yes" if any(f.rule.startswith("js-") for f in findings) or (Path(root) / "web").is_dir() or \
        (Path(root) / "js").is_dir() else "no"
    print(f"== {Path(root).name}: {counts['files']} files, {counts['python']} Python, "
          f"{counts['javascript']} JavaScript, web folder: {web}", file=out)
    if unparsed:
        print(f"   not parsed (syntax this Python cannot read): {', '.join(unparsed)}", file=out)
    for rule in RULES:
        if by_rule[rule]:
            print(f"   {rule:<16}{by_rule[rule]:>4}  {RULES[rule]}", file=out)
            shown = [f for f in findings if f.rule == rule][:details]
            for f in shown:
                where = f"{f.path}:{f.line}" if f.line else f.path
                print(f"{'':<24}{where}  {f.text}", file=out)
    if not findings:
        print("   no finding", file=out)
    return by_rule


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("packs", nargs="+", help="custom node folders")
    parser.add_argument("--details", type=int, default=0, help="print the first N findings of each rule")
    args = parser.parse_args(argv)
    for pack in args.packs:
        if not Path(pack).is_dir():
            parser.error(f"not a folder: {pack}")
        report(pack, args.details, sys.stdout)


if __name__ == "__main__":
    main()
