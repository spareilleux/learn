"""Mutation check of jones_state_sum.py: each mutant must make its check fail.

Each mutant changes one line of the script, the copy runs in a temporary folder, and
the mutant counts as caught when the copy exits with a non-zero status. The line
printed after the arrow is the mutant's last line of output. Exits with status 1
if a mutant is missed or if a line to change is not found exactly once.
"""

import subprocess
import sys
import tempfile
from pathlib import Path

SOURCE = Path(__file__).with_name("jones_state_sum.py")

# name: (line in jones_state_sum.py, what the mutant writes instead)
MUTANTS = {
    "crossing convention flipped": ("exponent += -sign if mask >> j & 1 else sign",
                                    "exponent += sign if mask >> j & 1 else -sign"),
    "loop value +A^2 + A^-2": ("add(out, e + 2, -c)\n        add(out, e - 2, -c)",
                               "add(out, e + 2, c)\n        add(out, e - 2, c)"),
    "writhe sign dropped": ("sign = -1 if writhe % 2 else 1", "sign = 1"),
    "closure not glued": ("return (level % c) * strands + position",
                          "return min(level, c - 1) * strands + position"),
    "t = A^4 instead of A^-4": ("add(out, -shifted // 2, sign * c)",
                                "add(out, shifted // 2, sign * c)"),
    "permutation swap skipped": ("at[k - 1], at[k] = at[k], at[k - 1]", "pass"),
}


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    source = SOURCE.read_text(encoding="utf-8")
    caught = 0
    with tempfile.TemporaryDirectory() as folder:
        copy = Path(folder) / "mutant.py"
        for name, (line, mutant) in MUTANTS.items():
            if source.count(line) != 1:
                print(f"NOT FOUND {name}: the line to change is not in the script exactly once")
                return 1
            copy.write_text(source.replace(line, mutant), encoding="utf-8")
            run = subprocess.run([sys.executable, str(copy)], capture_output=True,
                                 text=True, encoding="utf-8")
            output = (run.stdout.strip() or run.stderr.strip()).splitlines()
            last = output[-1] if output else "(no output)"
            ok = run.returncode != 0
            caught += ok
            print(f"{'CAUGHT' if ok else 'MISSED'} {name} -> {last}")
    print(f"{caught}/{len(MUTANTS)} mutants caught")
    return 0 if caught == len(MUTANTS) else 1


if __name__ == "__main__":
    sys.exit(main())
