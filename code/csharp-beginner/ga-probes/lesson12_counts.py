"""Lesson 12: counts in Guitar Alchemist at a pinned commit, read with git only (no checkout).

usage: python lesson12_counts.py <ga clone>
Prints: the project files on disk and in AllProjects.slnx, the test projects outside the solution and whether a
workflow names them, the projects outside the solution that a listed project references, the packages declared with
several versions, the PackageReference Update items of Directory.Build.props against the declared versions, the
blocking waits on tasks in non-test code, and the GaCLI commands that throw NotImplementedException.
"""
import collections, posixpath, re, subprocess, sys

GA, C = sys.argv[1], "5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26"

def git(*args):
    return subprocess.run(["git", "-C", GA, *args], capture_output=True, text=True, encoding="utf-8", errors="replace").stdout

def show(path):
    return git("show", f"{C}:{path}")

files = git("ls-tree", "-r", "--name-only", C).splitlines()
projects = [f for f in files if re.search(r"\.(cs|fs)proj$", f)]
listed = {p.replace("\\", "/") for p in re.findall(r'Path="([^"]+\.(?:cs|fs)proj)"', show("AllProjects.slnx"))}
outside = [p for p in projects if p not in listed]
print(f"== Solution: {len(projects)} project files, {len(listed)} in AllProjects.slnx, {len(outside)} outside")
for p in outside:
    print("  ", p)

workflows = "\n".join(show(f) for f in files if f.startswith(".github/workflows/"))
test_attribute = re.compile(r"^\s*\[(Fact|Theory|Test|TestCase|TestMethod)\b", re.M)
print("\n== Test projects outside the solution: named by a workflow (file path), lines with a test attribute")
for p in outside:
    if not p.startswith("Tests/"):
        continue
    folder = posixpath.dirname(p) + "/"
    attributes = sum(len(test_attribute.findall(show(f))) for f in files if f.startswith(folder) and f.endswith(".cs"))
    print(f"   {p}: workflow {p in workflows}, {attributes} test attributes")

referenced = collections.Counter()
for p in listed:
    for r in re.findall(r'<ProjectReference\s+Include="([^"]+)"', show(p)):
        referenced[posixpath.normpath(posixpath.join(posixpath.dirname(p), r.replace("\\", "/")))] += 1
print("\n== Projects outside the solution that a listed project references")
for p in outside:
    if referenced[p]:
        print(f"   {p}: from {referenced[p]} listed project(s)")

declared = collections.defaultdict(lambda: collections.defaultdict(list))
for p in projects:
    for name, version in re.findall(r'<PackageReference\s+Include="([^"]+)"\s+Version="([^"]+)"', show(p)):
        declared[name][version].append(p)
several = {n: v for n, v in declared.items() if len(v) > 1}
print(f"\n== Packages with a Version attribute: {len(declared)}; declared with two or more versions: {len(several)}")
for name, versions in sorted(several.items(), key=lambda kv: (-len(kv[1]), kv[0]))[:5]:
    print(f"   {name}: " + ", ".join(f"{v} x{len(ps)}" for v, ps in sorted(versions.items())))

print("\n== PackageReference Update items of Directory.Build.props, against the versions the projects declare")
total = in_solution = 0
for name, version in re.findall(r'<PackageReference\s+Update="([^"]+)"\s+Version="([^"]+)"', show("Directory.Build.props")):
    other = [(v, p) for v, ps in declared.get(name, {}).items() if v != version for p in ps]
    if other:
        total += len(other)
        in_solution += sum(p in listed for _, p in other)
        print(f"   {name} -> {version}: declared with another version in {len(other)} file(s): "
              + ", ".join(sorted({v for v, _ in other})))
print(f"   total: {total} declarations, {in_solution} of them in projects of the solution")

print("\n== Blocking waits on tasks in non-test code (outside archive/): .Result, .Wait(), GetAwaiter().GetResult()")
grep = git("grep", "-n", "-P", r"\)\.Result\b|[Tt]ask\.Result\b|\.Wait\(\s*\)|GetAwaiter\(\)\s*\.GetResult\(\)", C, "--", "*.cs")
for line in grep.splitlines():
    _, path, number, text = line.split(":", 3)
    if re.search(r"(^|/)Tests?/|\.Tests?(/|\.)|Tests?\.cs$", path) or path.startswith("archive/") or text.lstrip().startswith("//"):
        continue
    print(f"   {path}:{number}: {text.strip()[:100]}")
asyncvoid = git("grep", "-c", "-P", r"\basync\s+void\s+\w+\s*\(", C, "--", "*.cs")
print("   async void, non-test files:", sum(int(l.rsplit(":", 1)[1]) for l in asyncvoid.splitlines()
                                         if not re.search(r"(^|/)Tests?/|\.Tests?(/|\.)|Tests?\.cs:|:archive/", l)))

program = show("GaCLI/Program.cs").splitlines()
commands = re.findall(r'^\s*case "([a-z-]+)":', "\n".join(program), re.M)
throwing = []
for i, l in enumerate(program):
    # both orders of the modifiers occur: "static async Task" and "async static Task"
    m = re.search(r"\b(?:static (?:async )?|async static )Task (Run\w+)\(", l)
    if m and "throw new NotImplementedException" in " ".join(program[i + 1:i + 4]):
        throwing.append(f"{m.group(1)} (line {i + 1})")
print(f"\n== GaCLI: {len(commands)} commands, {len(throwing)} of them throw NotImplementedException")
for t in throwing:
    print("  ", t)
