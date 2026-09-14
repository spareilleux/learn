# LadybugDB course: export the pages, links and Git history of this repository at one commit into CSV files
# Run from the repository root: python code/ladybugdb/data/extract.py <commit>
import csv
import re
import subprocess
import sys
from pathlib import PurePosixPath
from urllib.parse import urljoin, urlsplit

commit = sys.argv[1]
out = PurePosixPath("code/ladybugdb/data")
docs = "src/content/docs/"


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True, encoding="utf-8").stdout


def page_url(file):
    # src/content/docs/fr/duckdb/index.md -> /fr/duckdb/ ; src/content/docs/duckdb/01-first-queries.mdx -> /duckdb/01-first-queries/
    path = PurePosixPath(file[len(docs):]).with_suffix("")
    parts = list(path.parts)
    if parts[-1] == "index":
        parts = parts[:-1]
    return "/" + "".join(p + "/" for p in parts)


def write(name, header, rows):
    with open(out / name, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(header)
        writer.writerows(rows)


files = [f for f in git("ls-tree", "-r", "--name-only", commit, docs).splitlines() if f.endswith((".md", ".mdx"))]
pages, links, external = [], [], []
for file in sorted(files):
    text = git("show", f"{commit}:{file}")
    url = page_url(file)
    segments = url.strip("/").split("/") if url != "/" else []
    locale = segments[0] if segments and segments[0] in ("fr", "es") else "en"
    rest = segments[1:] if locale != "en" else segments
    course = rest[0] if rest else ""
    title = re.search(r"^title:\s*(.+)$", text, re.M)
    pages.append([url, locale, course, title.group(1).strip().strip("'\"") if title else "", len(text.splitlines())])

    # Links in the prose: [text](target) and href="target", outside fenced code blocks
    prose = re.sub(r"^(`{3,}).*?^\1", "", text, flags=re.S | re.M)
    # A target may contain one level of parentheses, as in Math.html#addExact(int,int)
    targets = re.findall(r"\]\(((?:[^()\s]|\([^()\s]*\))+)\)", prose) + re.findall(r'href="([^"]+)"', prose)
    for target in targets:
        if target.startswith(("http://", "https://")):
            external.append([url, target, urlsplit(target).netloc])
        elif not target.startswith(("mailto:", "#")):
            resolved = urljoin("https://site" + url, target)
            parts = urlsplit(resolved)
            path = parts.path.removeprefix("/learn")
            links.append([url, path if path.endswith("/") else path + "/", parts.fragment])

write("pages.csv", ["url", "locale", "course", "title", "lines"], pages)
write("links.csv", ["from", "to", "anchor"], links)
write("external_links.csv", ["from", "url", "domain"], external)

# Git history: one row per commit, its parents, and the files it changed
commits, parents, changes = [], [], []
log = git("log", commit, "--reverse", "--no-renames", "--format=@%H|%P|%cI|%s", "--name-only")
for line in log.splitlines():
    if line.startswith("@"):
        sha, parent_list, committed_at, subject = line[1:].split("|", 3)
        commits.append([sha, committed_at, subject])
        parents.extend([sha, p] for p in parent_list.split())
    elif line:
        changes.append([sha, line])

write("commits.csv", ["sha", "committed_at", "subject"], commits)
write("parents.csv", ["child", "parent"], parents)
write("changes.csv", ["sha", "file"], changes)
print(f"{len(pages)} pages, {len(links)} internal links, {len(external)} external links, "
      f"{len(commits)} commits, {len(changes)} file changes")
