"""Remove GA's nullable NoWarn codes from the worktree's copies only, byte for byte.

Usage: python lift_nullable_nowarn.py <worktree> <orig-dir> props|both
  props: delete Directory.Build.props line 21 (the nullable NoWarn line)
  both:  also delete the nullable codes line (line 7) from Directory.Build.targets
Starts from the pristine copies in <orig-dir> each time, so it is idempotent.
"""
import sys
from pathlib import Path

wt, orig, mode = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
CODES = b"CS8600;CS8601;CS8602;CS8603;CS8604;CS8618;CS8619;CS8620;CS8625;CS8629;CS8632;CS8714;CS8762;CS8767;CS8774"

props = (orig / "Directory.Build.props").read_bytes()
props_line = b"    <NoWarn>$(NoWarn);" + CODES + b"</NoWarn>\r\n"
assert props.count(props_line) == 1, "props line 21 not found exactly once"
(wt / "Directory.Build.props").write_bytes(props.replace(props_line, b""))

targets = (orig / "Directory.Build.targets").read_bytes()
if mode == "both":
    targets_line = b"      " + CODES + b";\r\n"
    assert targets.count(targets_line) == 1, "targets line 7 not found exactly once"
    targets = targets.replace(targets_line, b"")
(wt / "Directory.Build.targets").write_bytes(targets)
print(f"mode={mode}: props and targets written")
