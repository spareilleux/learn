r"""Count compiler warnings in an MSBuild log, deduplicated by (file, line, column, code).

Usage: python count_warnings.py <build.log> [code-regex]
The default code regex is CS8[67]\d\d (nullable warnings CS86xx/CS87xx).
"""
import re
import sys
from collections import Counter

log_path = sys.argv[1]
code_re = sys.argv[2] if len(sys.argv) > 2 else r"CS8[67]\d\d"

line_re = re.compile(
    r"^(?P<file>[^\s].*?)\((?P<line>\d+),(?P<col>\d+)\): warning (?P<code>" + code_re + r"): (?P<msg>.*?) \[(?P<proj>[^\]]+)\]\s*$"
)

raw = 0
seen = {}
with open(log_path, encoding="utf-8", errors="replace") as f:
    for text in f:
        m = line_re.match(text.strip())
        if not m:
            continue
        raw += 1
        key = (m["file"], int(m["line"]), int(m["col"]), m["code"])
        proj = m["proj"].replace("\\", "/").rsplit("/", 1)[-1]
        seen.setdefault(key, (proj, m["msg"]))

print(f"raw matching lines: {raw}")
print(f"unique (file, line, column, code): {len(seen)}")

by_proj = Counter(p for p, _ in seen.values())
print("\nby project:")
for proj, n in sorted(by_proj.items()):
    print(f"  {proj}: {n}")

by_code = Counter(k[3] for k in seen)
print("\nby code (all projects):")
for code, n in sorted(by_code.items()):
    print(f"  {code}: {n}")

for proj in sorted(by_proj):
    c = Counter(k[3] for k, v in seen.items() if v[0] == proj)
    print(f"\nby code in {proj}:")
    for code, n in sorted(c.items()):
        print(f"  {code}: {n}")

files = Counter((v[0], k[0]) for k, v in seen.items())
for proj in sorted(by_proj):
    n_files = sum(1 for (p, _f) in files if p == proj)
    print(f"\nfiles with at least one warning in {proj}: {n_files}")
