"""Helpers shared by the lesson scripts: a report written to out/<lesson>.txt, and fixed float formatting.

Blender runs each script with: blender --background --factory-startup --python-exit-code 1 --python scripts/<lesson>.py -- <out dir>
Lines that start with "# " (timings, sizes that vary) are kept in out/ but not compared by check.sh.
"""
import os
import sys


def out_dir():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    path = args[0] if args else "out"
    os.makedirs(path, exist_ok=True)
    return path


class Report:
    def __init__(self, name):
        self.path = os.path.join(out_dir(), name + ".txt")
        self.lines = []

    def __call__(self, *parts):
        line = " ".join(str(p) for p in parts)
        self.lines.append(line)
        print(line)

    def section(self, title):
        if self.lines:
            self("")
        self("==", title)

    def save(self):
        with open(self.path, "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(self.lines) + "\n")


def f(x, digits=4):
    """A float with a fixed number of decimals, and no negative zero."""
    s = f"{x:.{digits}f}"
    return s[1:] if s.startswith("-") and float(s) == 0 else s


def vec(v, digits=4):
    return "(" + ", ".join(f(c, digits) for c in v) + ")"
