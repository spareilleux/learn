"""Exercise the Go course checker against isolated, deliberately damaged courses."""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "check-go-courses.py"
SPEC = importlib.util.spec_from_file_location("check_go_courses", SCRIPT)
checker = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(checker)

COURSE = "go-for-csharp-java"
SOURCE = 'package main\n\nimport "fmt"\n\nfunc main() {\n\tfmt.Println("hello")\n}\n'
PARAGRAPHS = {
    "en": "A Go value has a concrete type and a lifetime determined by its uses. Compare this example with a C# local or a Java variable before deciding which representation expresses the ownership of the data. ",
    "fr": "Une valeur Go possède un type concret et une durée de vie déterminée par ses usages. Comparez cet exemple avec une variable locale C# ou Java avant de choisir une représentation qui exprime la propriété des données. ",
    "es": "Un valor Go tiene un tipo concreto y una duración determinada por sus usos. Compare este ejemplo con una variable local de C# o Java antes de elegir una representación que exprese la propiedad de los datos. ",
}
HEADINGS = {
    "en": ("Progress", "To verify", "Open questions", "Exercises", "Solution"),
    "fr": ("Progression", "À vérifier", "Questions ouvertes", "Exercices", "Solution"),
    "es": ("Progreso", "Por verificar", "Preguntas abiertas", "Ejercicios", "Solución"),
}


def page(title, order, body):
    return f"---\ntitle: {title}\ndescription: A useful course page\nsidebar:\n  order: {order}\n---\n\n{body}\n"


class CourseCheckerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        module = self.root / "code" / COURSE
        module.mkdir(parents=True)
        (module / "go.mod").write_text(f"module example.com/learn/{COURSE}\n\ngo 1.27.0\n", encoding="utf-8")
        self.names = [f"{i:02}-topic.md" for i in range(1, 15)]
        manifest = []
        for i, name in enumerate(self.names, 1):
            command = module / "cmd" / f"l{i:02}"
            command.mkdir(parents=True)
            (command / "main.go").write_text(SOURCE, encoding="utf-8")
            manifest.append({"lesson": name, "command": f"./cmd/l{i:02}", "stdout": "hello\n"})
        (module / "examples.json").write_text(json.dumps(manifest), encoding="utf-8")
        for locale in HEADINGS:
            folder = self.folder(locale)
            folder.mkdir(parents=True)
            progress, verify, questions, exercises, solution = HEADINGS[locale]
            links = "\n".join(f"- [Lesson {i}]({Path(name).stem}/)" for i, name in enumerate(self.names, 1))
            (folder / "index.md").write_text(page("Course", 0, links), encoding="utf-8")
            journal = f"## {progress}\n\n- [ ] Lessons\n\n## 2026-11-07 — Work\n\nThe course draft connects each lesson to its own runnable example. Execution and publication remain pending until the coordinating agent records actual checks.\n\n## {verify}\n\nRun examples on each supported operating system.\n\n## {questions}\n\nWhich representation communicates ownership most clearly to a new reader?"
            (folder / "journal.md").write_text(page("Journal", 99, journal), encoding="utf-8")
            for i, name in enumerate(self.names, 1):
                paragraphs = "\n\n".join(PARAGRAPHS[locale] for _ in range(3))
                body = f"## Values\n\n{paragraphs}\n\n```go\n{SOURCE}```\n\n## {exercises}\n\n"
                body += f"Change the output and explain the result.\n\n<details><summary>{solution} 1</summary>\n\nUse fmt.Println to print the new value and keep the newline.\n\n</details>\n\n"
                body += f"Explain who owns the value.\n\n<details><summary>{solution} 2</summary>\n\nThe local variable belongs to this function and remains usable until its last reference.\n\n</details>\n\n"
                body += "[Mission](../) [Official fragment](https://go.dev/ref/spec#Types)\n\n`[illustration](missing-inline/)`\n\n```text\n[illustration](missing-code/)\n```"
                (folder / name).write_text(page("Values", i, body), encoding="utf-8")

    def folder(self, locale="en"):
        return self.root / "src/content/docs" / (locale if locale != "en" else "") / COURSE

    def check(self, content_only=True):
        args = ["--root", str(self.root), COURSE]
        if content_only:
            args.append("--content-only")
        output = io.StringIO()
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
            status = checker.main(args)
        return status, output.getvalue()

    def replace(self, name, old, new, locale="en"):
        path = self.folder(locale) / name
        path.write_text(path.read_text(encoding="utf-8").replace(old, new), encoding="utf-8")

    def test_valid_translated_course_and_exact_excerpt_pass(self):
        self.replace(self.names[0], SOURCE, 'func main() {\n\tfmt.Println("hello")\n}\n', "fr")
        status, output = self.check()
        self.assertEqual(status, 0, output)
        self.assertIn("prose words", output)

    def test_missing_locale_lesson_reports_parity(self):
        (self.folder("es") / self.names[3]).unlink()
        status, output = self.check()
        self.assertNotEqual(status, 0)
        self.assertIn("locale parity", output)
        self.assertIn(self.names[3], output)

    def test_missing_locale_reports_parity(self):
        for path in self.folder("fr").glob("*.md"):
            path.unlink()
        status, output = self.check()
        self.assertNotEqual(status, 0)
        self.assertIn("fr/go-for-csharp-java: locale parity", output)

    def test_missing_english_lesson_reports_fourteen_required(self):
        (self.folder() / self.names[4]).unlink()
        status, output = self.check()
        self.assertNotEqual(status, 0)
        self.assertIn("14 numbered lessons", output)

    def test_broken_lesson_link_fails_but_code_and_official_urls_are_ignored(self):
        self.replace(self.names[0], "[Mission](../)", "[Missing](../missing-page/)")
        status, output = self.check()
        self.assertNotEqual(status, 0)
        self.assertIn("broken local link", output)
        self.assertIn("missing-page", output)
        self.assertNotIn("missing-code", output)
        self.assertNotIn("missing-inline", output)

    def test_invented_or_reindented_go_snippet_fails(self):
        self.replace(self.names[0], '\tfmt.Println("hello")', '    fmt.Println("invented")')
        status, output = self.check()
        self.assertNotEqual(status, 0)
        self.assertIn("Go snippet is not an exact source excerpt", output)

    def test_indentation_alone_is_not_normalized(self):
        self.replace(self.names[0], '\tfmt.Println("hello")', '    fmt.Println("hello")')
        status, output = self.check()
        self.assertNotEqual(status, 0)
        self.assertIn("Go snippet is not an exact source excerpt", output)

    def test_reference_style_links_are_validated(self):
        self.replace(self.names[0], "[Mission](../)", "[Mission][home]\n\n[home]: ../missing-reference/")
        status, output = self.check()
        self.assertNotEqual(status, 0)
        self.assertIn("broken local link ../missing-reference/", output)

    def test_reference_style_index_links_cover_lessons(self):
        self.replace("index.md", "[Lesson 1](01-topic/)", "[Lesson 1][first]\n\n[first]: 01-topic/")
        status, output = self.check()
        self.assertEqual(status, 0, output)

    def test_exercise_solution_and_journal_omissions_fail(self):
        self.replace(self.names[0], "<details>", "<removed>")
        self.replace("journal.md", "## À vérifier", "## Autre", "fr")
        status, output = self.check()
        self.assertNotEqual(status, 0)
        self.assertIn("two exercise solutions", output)
        self.assertIn("journal heading", output)

    def test_journal_headings_without_meaningful_entries_fail(self):
        path = self.folder() / "journal.md"
        path.write_text(page("Journal", 99, "## Progress\n\n- [ ] Lessons\n\n## 2026-11-07 — Work\n\n## To verify\n\n## Open questions"), encoding="utf-8")
        status, output = self.check()
        self.assertNotEqual(status, 0)
        self.assertIn("journal section has no substantive content", output)

    def test_empty_outline_and_placeholder_fail(self):
        self.replace(self.names[0], PARAGRAPHS["en"], "TODO\n")
        status, output = self.check()
        self.assertNotEqual(status, 0)
        self.assertIn("placeholder", output)
        self.assertIn("explanatory paragraphs", output)

    def test_spanish_todo_is_normal_prose(self):
        self.replace(self.names[0], PARAGRAPHS["es"],
                     PARAGRAPHS["es"] + "Compruebe todo antes de continuar. ", "es")
        status, output = self.check()
        self.assertEqual(status, 0, output)

    def test_frontmatter_and_index_coverage_fail(self):
        self.replace(self.names[0], "description: A useful course page", "description:")
        self.replace("index.md", "- [Lesson 1](01-topic/)", "")
        status, output = self.check()
        self.assertNotEqual(status, 0)
        self.assertIn("frontmatter description", output)
        self.assertIn("index does not link", output)

    @patch.object(checker.subprocess, "run")
    def test_runner_compares_exact_stdout_and_reports_exit_status(self, run):
        run.return_value = subprocess.CompletedProcess([], 0, b"hello\n", b"")
        status, output = self.check(content_only=False)
        self.assertEqual(status, 0, output)
        self.assertEqual(run.call_count, 14)
        run.return_value = subprocess.CompletedProcess([], 0, b"hello\r\n", b"")
        status, output = self.check(content_only=False)
        self.assertNotEqual(status, 0)
        self.assertIn("stdout mismatch", output)
        run.return_value = subprocess.CompletedProcess([], 3, b"", b"program failed")
        status, output = self.check(content_only=False)
        self.assertNotEqual(status, 0)
        self.assertIn("exit=3", output)

    @patch.object(checker.subprocess, "run", side_effect=subprocess.TimeoutExpired("go", 120))
    def test_runner_timeout_is_a_failure(self, run):
        status, output = self.check(content_only=False)
        self.assertNotEqual(status, 0)
        self.assertIn("timed out", output)


if __name__ == "__main__":
    unittest.main()
