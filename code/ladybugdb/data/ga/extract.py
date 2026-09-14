"""The .NET projects of GuitarAlchemist/ga as CSV files, for lessons 5 and 6 of the LadybugDB course.

Usage: python extract.py <checkout of GuitarAlchemist/ga>

The files of the course come from commit a26a7893 (2026-09-14). Only the project files are needed:

    git clone --filter=blob:none --no-checkout https://github.com/GuitarAlchemist/ga
    cd ga
    git sparse-checkout set --no-cone '*.csproj' '*.fsproj' '*.slnx'
    git checkout a26a7893

Writes, next to this script:
- projects.csv: path, name, language (C# or F#), sdk, target frameworks (';'-separated), and whether AllProjects.slnx lists it
- project_refs.csv: ProjectReference items, from project to project (paths from the repository root)
- package_refs.csv: PackageReference items, project, package, version (empty when the item has none)
"""
from __future__ import annotations

import csv
import posixpath
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

HERE = Path(__file__).resolve().parent


def local(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def main() -> None:
    root = Path(sys.argv[1]).resolve()
    files = sorted(p for p in root.rglob("*") if p.suffix in (".csproj", ".fsproj") and ".claude" not in p.parts)
    solution = ET.parse(root / "AllProjects.slnx").getroot()
    in_solution = {e.get("Path").replace("\\", "/") for e in solution.iter() if local(e.tag) == "Project"}

    projects, project_refs, package_refs = [], [], []
    for file in files:
        path = file.relative_to(root).as_posix()
        xml = ET.parse(file).getroot()
        frameworks = ""
        for e in xml.iter():
            if local(e.tag) in ("TargetFramework", "TargetFrameworks") and e.text:
                frameworks = e.text.strip()
        projects.append([path, file.stem, "F#" if file.suffix == ".fsproj" else "C#", xml.get("Sdk", ""), frameworks,
                         str(path in in_solution).lower()])
        for e in xml.iter():
            include = e.get("Include")
            if not include:
                continue
            if local(e.tag) == "ProjectReference":
                target = posixpath.normpath(posixpath.join(posixpath.dirname(path), include.replace("\\", "/")))
                project_refs.append([path, target])
            elif local(e.tag) == "PackageReference":
                version = e.get("Version")
                if version is None:
                    child = next((c for c in e if local(c.tag) == "Version"), None)
                    version = child.text.strip() if child is not None and child.text else ""
                package_refs.append([path, include, version])

    for name, header, rows in [
        ("projects.csv", ["path", "name", "language", "sdk", "frameworks", "in_solution"], projects),
        ("project_refs.csv", ["from", "to"], sorted(project_refs)),
        ("package_refs.csv", ["project", "package", "version"], sorted(package_refs)),
    ]:
        with open(HERE / name, "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f, lineterminator="\n")
            w.writerow(header)
            w.writerows(rows)
        print(f"{name}: {len(rows)} rows")


if __name__ == "__main__":
    main()
