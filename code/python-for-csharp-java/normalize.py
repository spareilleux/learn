# Makes the outputs of python, mypy, pytest, uv, dotnet and javac comparable between machines:
#     python normalize.py [--uv] < raw.txt > out.txt
# - colors are removed, and line endings become \n
# - absolute paths and file URLs under this folder become paths relative to it, with forward slashes,
#   and so do relative paths that Windows prints with backslashes (errors\l01_order.py)
# - memory addresses (<function f at 0x7f3a…>) become 0xADDRESS, and pytest's durations become TIME
# - with --uv, uv's progress lines (Resolved…, Installed…, + package==version) are dropped: they depend on its cache
import re
import sys

COURSE = "python-for-csharp-java"

course_path = re.compile(r"(?:file:///?)?[^\s'\"(`]*?" + re.escape(COURSE) + r"(?:[\\/]([^\s'\":(),`]*))?")
relative_windows_path = re.compile(r"\b(?:[\w.-]+\\)+[\w.-]+\.(?:py|cs|java|toml|json)\b")
uv_progress = re.compile(
    r"^\s*(?:Resolved|Prepared|Installed|Uninstalled|Audited|Downloading|Downloaded|Building|Built|Using CPython"
    r"|Creating virtual environment|Removed virtual environment|Bytecode compiled)\b|^ [+~-] \S+(?:==| @ )"
)


def normalize_line(line: str) -> str:
    line = re.sub(r"\x1b\[[0-9;]*[A-Za-z]", "", line)
    line = course_path.sub(lambda m: (m.group(1) or ".").replace("\\", "/"), line)
    line = relative_windows_path.sub(lambda m: m.group(0).replace("\\", "/"), line)
    line = re.sub(r"\b0x[0-9A-Fa-f]{6,16}\b", "0xADDRESS", line)
    line = re.sub(r" in \d+\.\d+s\b", " in TIME", line)
    return line.rstrip()


def main() -> None:
    drop_uv = "--uv" in sys.argv[1:]
    text = sys.stdin.buffer.read().decode("utf-8", errors="replace").replace("\r\n", "\n")
    lines = [normalize_line(line) for line in text.split("\n")]
    if drop_uv:
        lines = [line for line in lines if not uv_progress.search(line)]
    sys.stdout.buffer.write("\n".join(lines).encode("utf-8"))


main()
