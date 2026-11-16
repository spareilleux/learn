"""Check only the two Go courses, then replay examples.json with exact stdout.

    python -B scripts/check-go-courses.py
    python -B scripts/check-go-courses.py go-advanced --content-only

Uses only Python's standard library. --root selects a checkout (also used by the
isolated fixture tests). Content checks do not execute Go or change any files.
Prose counts are informational; the outline check looks for explanatory
paragraphs and exercises, and does not certify teaching or translation quality.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess
from urllib.parse import unquote, urlsplit


COURSES = ("go-for-csharp-java", "go-advanced")
LESSON = re.compile(r"^(\d{2})-[a-z0-9-]+\.md$")
JOURNAL_HEADINGS = {
    "en": ("Progress", "To verify", "Open questions"),
    "fr": ("Progression", "À vérifier", "Questions ouvertes"),
    "es": ("Progreso", "Por verificar", "Preguntas abiertas"),
}
LINK = re.compile(r"(?<!!)\[[^\]]*\]\(\s*(<[^>]+>|[^\s)]+)(?:\s+[^)]*)?\)")


def normalize(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n").strip("\n")


def markdown_parts(text: str, languages=("go", "golang")) -> tuple[str, list[str], bool]:
    prose, snippets, code = [], [], []
    fence, language = "", ""
    for line in text.splitlines(keepends=True):
        if not fence:
            match = re.match(r"^ {0,3}(`{3,}|~{3,})([^\n]*)", line)
            if match:
                fence = match[1]
                language = match[2].strip().split(" ", 1)[0].lower()
                code = []
            else:
                prose.append(line)
        elif re.fullmatch(r" {0,3}" + re.escape(fence[0]) + "{" + str(len(fence)) + r",}\s*", line):
            if language in languages:
                snippets.append("".join(code))
            fence = ""
            prose.append("\n")
        else:
            code.append(line)
    plain = re.sub(r"(`+)(.*?)\1", "", "".join(prose), flags=re.DOTALL)
    return plain, snippets, bool(fence)


def frontmatter(text: str) -> tuple[dict[str, str], str]:
    match = re.match(r"\A---\n(.*?)\n---(?:\n|$)", text, re.DOTALL)
    if not match:
        return {}, text
    fields = {}
    header = match[1]
    for key in ("title", "description"):
        scalar = re.search(rf"^{key}:[ \t]*([^\n]*)", header, re.MULTILINE)
        if scalar:
            value = scalar[1].strip().strip("\"'")
            if value in ("|", ">", "|-", ">-"):
                continuation = header[scalar.end():].splitlines()
                lines = []
                for line in continuation:
                    if line and not line[0].isspace():
                        break
                    lines.append(line.strip())
                value = " ".join(lines).strip()
            fields[key] = value
    sidebar = re.search(r"^sidebar:\s*\n((?:[ \t]+[^\n]*(?:\n|$))+)", header, re.MULTILINE)
    if sidebar:
        order = re.search(r"^\s+order:\s*(\d+)\s*$", sidebar[1], re.MULTILINE)
        if order:
            fields["order"] = order[1]
    return fields, text[match.end():]


def resolve_link(page: Path, href: str) -> Path | None:
    route_base = page.parent if page.stem == "index" else page.with_suffix("")
    for base in (route_base, page.parent):
        target = (base / unquote(href)).resolve()
        candidates = (target, Path(str(target).rstrip("/\\") + ".md"),
                      Path(str(target).rstrip("/\\") + ".mdx"), target / "index.md", target / "index.mdx")
        for candidate in candidates:
            if candidate.is_file():
                return candidate
    return None


def page_links(prose: str) -> list[str]:
    links = LINK.findall(prose)
    definitions = {label.casefold(): href for label, href in re.findall(
        r"^ {0,3}\[([^\]]+)\]:[ \t]*(<[^>]+>|\S+)", prose, re.MULTILINE)}
    for match in re.finditer(r"(?<!!)\[([^\]]+)\](?:\[([^\]]*)\])?(?![(:])", prose):
        key = (match[2] or match[1]).casefold()
        if key in definitions:
            links.append(definitions[key])
    return links


def check_course(root: Path, course: str, content_only: bool) -> list[str]:
    errors = []
    docs = root / "src/content/docs"
    english = docs / course
    module = root / "code" / course
    names = sorted(p.name for p in english.glob("*.md") if LESSON.fullmatch(p.name))
    numbers = [int(LESSON.fullmatch(name)[1]) for name in names]
    if numbers != list(range(1, 15)):
        errors.append(f"{course}: expected 14 numbered lessons (01 through 14), found {names}")
    expected = set(names) | {"index.md", "journal.md"}
    sources = ["\n" + normalize(p.read_text(encoding="utf-8")) + "\n"
               for p in module.rglob("*.go") if p.resolve().is_relative_to(module.resolve())]
    english_orders = {}
    quoted_outputs = {}
    for locale, headings in JOURNAL_HEADINGS.items():
        folder = docs / (locale if locale != "en" else "") / course
        actual = {p.name for p in folder.glob("*.md")}
        if actual != expected:
            errors.append(f"{locale}/{course}: locale parity: missing={sorted(expected - actual)}, extra={sorted(actual - expected)}")
        seen_orders = set()
        for name in sorted(expected & actual):
            path = folder / name
            label = path.relative_to(root).as_posix()
            fields, body = frontmatter(path.read_text(encoding="utf-8"))
            for field in ("title", "description", "order"):
                if not fields.get(field):
                    errors.append(f"{label}: frontmatter {field} must be nonempty" if field != "order" else f"{label}: frontmatter sidebar.order must be a nonnegative integer")
            order = fields.get("order")
            if order in seen_orders:
                errors.append(f"{label}: duplicate sidebar order {order}")
            seen_orders.add(order)
            if locale == "en":
                english_orders[name] = order
            elif order != english_orders.get(name):
                errors.append(f"{label}: sidebar order differs from English")
            lesson = LESSON.fullmatch(name)
            if lesson and order != str(int(lesson[1])):
                errors.append(f"{label}: sidebar order must match lesson number")
            if name == "index.md" and order != "0":
                errors.append(f"{label}: index sidebar order must be 0")
            prose, snippets, unclosed = markdown_parts(body)
            quoted_outputs[locale, name] = markdown_parts(body, ("text",))[1]
            if unclosed:
                errors.append(f"{label}: unclosed code fence")
            if (re.search(r"\b(?:TODO|TBD|FIXME)\b", prose)
                    or re.search(r"\b(?:placeholder|lorem ipsum|coming soon)\b", prose, re.IGNORECASE)):
                errors.append(f"{label}: placeholder content")
            for snippet in snippets:
                needle = "\n" + normalize(snippet) + "\n"
                if not normalize(snippet) or not any(needle in source for source in sources):
                    errors.append(f"{label}: Go snippet is not an exact source excerpt")
            linked = set()
            for href in page_links(prose):
                href = href.strip("<>")
                url = urlsplit(href)
                if url.scheme or url.netloc or not url.path:
                    continue
                target = resolve_link(path, url.path)
                if target is None or url.path.startswith("/"):
                    errors.append(f"{label}: broken local link {href}")
                else:
                    linked.add(target)
            if name == "index.md":
                for lesson_name in names:
                    if (folder / lesson_name).resolve() not in linked:
                        errors.append(f"{label}: index does not link {lesson_name}")
            elif name == "journal.md":
                sections = list(re.finditer(r"^## ([^\n]+)", prose, re.MULTILINE))
                for heading in headings:
                    if not re.search(rf"^##\s+{re.escape(heading)}\s*$", prose, re.MULTILINE):
                        errors.append(f"{label}: missing journal heading {heading}")
                if not re.search(r"^## \d{4}-\d{2}-\d{2}\b", prose, re.MULTILINE):
                    errors.append(f"{label}: missing dated journal entry")
                if not re.search(r"^\s*- \[[ xX]\]", prose, re.MULTILINE):
                    errors.append(f"{label}: missing journal progress checklist")
                titles = [section[1].strip() for section in sections]
                if not titles or titles[0] != headings[0] or titles[-2:] != list(headings[1:]):
                    errors.append(f"{label}: journal must open with {headings[0]} and close with {headings[1]} / {headings[2]}")
                for i, section in enumerate(sections):
                    dated = bool(re.match(r"\d{4}-\d{2}-\d{2}\b", section[1]))
                    if dated or section[1].strip() in headings[1:]:
                        end = sections[i + 1].start() if i + 1 < len(sections) else len(prose)
                        content = prose[section.end():end]
                        if len(re.findall(r"\b\w+\b", content)) < (12 if dated else 3):
                            errors.append(f"{label}: journal section has no substantive content: {section[1]}")
            elif lesson:
                words = len(re.findall(r"\b[\wÀ-ÿ]+\b", re.sub(r"<[^>]*>", "", prose)))
                print(f"{label}: {words} prose words")
                explanation = re.sub(r"<details\b.*?</details>", "", prose, flags=re.DOTALL | re.IGNORECASE)
                paragraphs = [p for p in re.split(r"\n\s*\n", explanation)
                              if p.strip() and not re.match(r"\s*(?:#|[-*|]|\d+\.)", p)
                              and len(re.findall(r"\b\w+\b", p)) >= 20]
                if len(paragraphs) < 3:
                    errors.append(f"{label}: empty outline: expected at least three explanatory paragraphs")
                solutions = re.findall(r"<details\b[^>]*>\s*<summary\b[^>]*>.+?</summary>(.*?)</details>", body, re.DOTALL | re.IGNORECASE)
                if len([s for s in solutions if len(re.sub(r"<[^>]*>", "", s).strip()) >= 20]) < 2:
                    errors.append(f"{label}: expected at least two exercise solutions in details")
                if not re.search(r"^#{2,3} .*(?:Exercises|Exercices|Ejercicios)", prose, re.MULTILINE | re.IGNORECASE):
                    errors.append(f"{label}: missing exercises heading")
                if not snippets:
                    errors.append(f"{label}: missing worked Go example")
    manifest_path = module / "examples.json"
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        errors.append(f"{course}: cannot read examples.json: {exc}")
        return errors
    if not isinstance(manifest, list) or len(manifest) != 14:
        errors.append(f"{course}: examples.json must be an array of 14 examples")
        return errors
    manifest_lessons = []
    for item in manifest:
        if not isinstance(item, dict) or set(item) != {"lesson", "command", "stdout"} or not all(isinstance(value, str) for value in item.values()):
            errors.append(f"{course}: invalid examples.json entry {item!r}")
            continue
        lesson = LESSON.fullmatch(item["lesson"])
        if not lesson or item["lesson"] not in names or item["command"] != f"./cmd/l{lesson[1]}" or not item["stdout"].endswith("\n"):
            errors.append(f"{course}: invalid lesson, command or newline in examples.json entry {item!r}")
            continue
        manifest_lessons.append(item["lesson"])
        for locale in JOURNAL_HEADINGS:
            if item["stdout"] not in quoted_outputs.get((locale, item["lesson"]), []):
                errors.append(f"{locale}/{course}/{item['lesson']}: quoted stdout does not match examples.json")
        if not (module / item["command"]).is_dir():
            errors.append(f"{course}: example command directory missing: {item['command']}")
            continue
        if content_only:
            continue
        command = ["go", "run", item["command"]]
        try:
            result = subprocess.run(command, cwd=module, capture_output=True, timeout=120, check=False)
        except subprocess.TimeoutExpired:
            errors.append(f"{course} {item['command']}: timed out after 120 seconds")
            continue
        except OSError as exc:
            errors.append(f"{course} {item['command']}: cannot execute Go: {exc}")
            continue
        print(f"{course} {item['command']}: exit={result.returncode}")
        if result.returncode:
            errors.append(f"{course} {item['command']}: exit={result.returncode}, stderr={result.stderr!r}")
        elif result.stdout != item["stdout"].encode("utf-8"):
            errors.append(f"{course} {item['command']}: stdout mismatch: expected={item['stdout'].encode('utf-8')!r}, actual={result.stdout!r}")
    if sorted(manifest_lessons) != names:
        errors.append(f"{course}: examples.json must cover every lesson exactly once")
    return errors


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("courses", nargs="*", metavar="COURSE", help="go-for-csharp-java and/or go-advanced; default: both")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--content-only", action="store_true", help="validate content and manifests without executing Go")
    args = parser.parse_args(argv)
    if any(course not in COURSES for course in args.courses):
        parser.error("courses must be go-for-csharp-java or go-advanced")
    errors = []
    for course in dict.fromkeys(args.courses or COURSES):
        errors.extend(check_course(args.root.resolve(), course, args.content_only))
    for error in errors:
        print(f"ERROR: {error}")
    print(f"Go courses: {len(errors)} errors; example execution {'skipped (content-only)' if args.content_only else 'attempted'}")
    return int(bool(errors))


if __name__ == "__main__":
    raise SystemExit(main())
