from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent
REPOSITORY_ROOT = ROOT.parents[1]
REGISTRY = ROOT / "opportunities.json"
MATRICES = ROOT / "matrices.md"
STATUSES = {"discovered", "experimenting", "incubating", "integrating", "adopted", "rejected", "retired"}
VERDICTS = {"promising", "confirmed", "refuted", "inconclusive"}
SCORE_KEYS = {"pain", "fit", "expected_value", "evidence", "reversibility", "cost", "risk"}
# A rejection has to carry its evidence too, or the registry cannot stop anyone repeating the
# idea: lesson 1 promises exactly that, so "rejected" belongs with the promoted states here.
EVIDENCE_STATUSES = {"incubating", "integrating", "adopted", "rejected"}
# The order the promotion and result tables are read in. Deliberately not the score: the score
# ranks investigation, and a reader who meets the best-scored row first in a promotion table is
# being told something the data does not say.
STATUS_ORDER = ["adopted", "integrating", "incubating", "experimenting", "discovered", "rejected", "retired"]


def artifact_is_present(artifact: str) -> bool:
    """A link is taken on trust; a path in this repository has to be on disk."""
    if artifact.startswith(("http://", "https://")):
        return True
    return (ROOT / artifact).exists()


def load_registry(path: Path = REGISTRY) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def validate(data: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    opportunities = data.get("opportunities")
    if not isinstance(opportunities, list) or not opportunities:
        return ["opportunities must be a non-empty array"]

    seen: set[str] = set()
    required = {
        "id", "technique", "course", "axis", "repositories", "observed_pain", "hypothesis",
        "baseline", "success_metric", "falsifier", "simpler_alternative", "status", "scores",
        "authority", "next_gate", "result", "verdict", "artifacts", "revisit",
    }
    for index, item in enumerate(opportunities):
        prefix = f"opportunities[{index}]"
        if not isinstance(item, dict):
            errors.append(f"{prefix} must be an object")
            continue
        missing = sorted(required - item.keys())
        if missing:
            errors.append(f"{prefix} missing: {', '.join(missing)}")
            continue
        identifier = item["id"]
        if identifier in seen:
            errors.append(f"duplicate id: {identifier}")
        seen.add(identifier)
        if item["status"] not in STATUSES:
            errors.append(f"{identifier}: invalid status {item['status']}")
        if item["verdict"] not in VERDICTS:
            errors.append(f"{identifier}: invalid verdict {item['verdict']}")
        if not item["repositories"]:
            errors.append(f"{identifier}: repositories must not be empty")
        scores = item["scores"]
        if set(scores) != SCORE_KEYS:
            errors.append(f"{identifier}: scores must contain exactly {sorted(SCORE_KEYS)}")
        elif any(type(value) is not int or not 0 <= value <= 5 for value in scores.values()):
            errors.append(f"{identifier}: every score must be an integer from 0 to 5")
        # Presence of a key proves nothing: an entry whose evidence fields are empty strings
        # used to pass every gate below and reach "adopted".
        blank = sorted(key for key in required if isinstance(item[key], str) and not item[key].strip())
        if blank:
            errors.append(f"{identifier}: these fields must not be blank: {', '.join(blank)}")

        artifacts = item["artifacts"]
        if not isinstance(artifacts, list) or any(
            not isinstance(artifact, str) or not artifact.strip() for artifact in artifacts
        ):
            errors.append(f"{identifier}: artifacts must be a list of non-blank strings")
        else:
            absent = [a for a in artifacts if not artifact_is_present(a)]
            if absent:
                errors.append(f"{identifier}: artifact does not exist: {', '.join(absent)}")
            if item["status"] in EVIDENCE_STATUSES:
                if not artifacts:
                    errors.append(f"{identifier}: status {item['status']} requires evidence artifacts")
                elif all(a.startswith(("http://", "https://")) for a in artifacts):
                    errors.append(
                        f"{identifier}: status {item['status']} needs at least one artifact in this "
                        "repository, not links alone"
                    )
        if item["status"] == "adopted" and item["verdict"] != "confirmed":
            errors.append(f"{identifier}: adopted status requires a confirmed verdict")
        if item["status"] == "rejected" and item["verdict"] not in {"refuted", "inconclusive"}:
            errors.append(f"{identifier}: rejected status requires a refuted or inconclusive verdict")

    checks = data.get("method_checks")
    if not isinstance(checks, list) or not checks:
        errors.append("method_checks must be a non-empty array")
    return errors


def opportunity_score(item: dict[str, Any]) -> int:
    scores = item["scores"]
    return sum(scores[key] for key in ("pain", "fit", "expected_value", "evidence", "reversibility")) - scores["cost"] - scores["risk"]


def validate_course_mirrors(courses: tuple[str, ...] = ("repository-dogfooding-lab", "typesafe-ai-system-one")) -> list[str]:
    docs = REPOSITORY_ROOT / "src" / "content" / "docs"
    errors: list[str] = []
    required_journal_headings = {
        "en": ("## Experiments", "## To verify", "## Open questions"),
        "fr": ("## Expériences", "## À vérifier", "## Questions ouvertes"),
        "es": ("## Experimentos", "## Por verificar", "## Preguntas abiertas"),
    }
    for course in courses:
        roots = {"en": docs / course, "fr": docs / "fr" / course, "es": docs / "es" / course}
        file_sets = {locale: {path.name for path in root.glob("*.md")} for locale, root in roots.items()}
        if not file_sets["en"]:
            errors.append(f"{course}: English source has no Markdown files")
            continue
        for locale in ("fr", "es"):
            if file_sets[locale] != file_sets["en"]:
                missing = sorted(file_sets["en"] - file_sets[locale])
                extra = sorted(file_sets[locale] - file_sets["en"])
                errors.append(f"{course}/{locale}: mirror mismatch missing={missing} extra={extra}")
        for locale, root in roots.items():
            journal = (root / "journal.md").read_text(encoding="utf-8")
            for heading in required_journal_headings[locale]:
                if heading not in journal:
                    errors.append(f"{course}/{locale}/journal.md: missing {heading}")
    return errors


def by_status(item: dict[str, Any]) -> tuple[int, str]:
    order = STATUS_ORDER.index(item["status"]) if item["status"] in STATUS_ORDER else len(STATUS_ORDER)
    return order, item["id"]


def render(data: dict[str, Any]) -> str:
    items = sorted(data["opportunities"], key=lambda item: (-opportunity_score(item), item["id"]))
    # The tables about promotion are read in promotion order. Sorting them by score too would
    # put the best-scored candidate first everywhere, which is the same authority the score is
    # not supposed to have - exercised on the reader's attention instead of on the data.
    staged = sorted(data["opportunities"], key=by_status)
    lines = [
        "# Generated dogfooding opportunity matrices",
        "",
        "> Generated from `opportunities.json` by `dogfood.py`; do not edit this file directly.",
        "",
        "## Course × repository coverage",
        "",
        "| Opportunity | Course | Axis | Repositories |",
        "|---|---|---|---|",
    ]
    for item in items:
        lines.append(f"| {item['technique']} | `{item['course']}` | {item['axis']} | {', '.join(item['repositories'])} |")

    lines += [
        "",
        "## Opportunity score",
        "",
        "The score orders investigation only. It never authorizes incubation or integration.",
        "",
        "| Opportunity | Pain | Fit | Value | Evidence | Reversible | Cost | Risk | Score |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for item in items:
        score = item["scores"]
        lines.append(
            f"| {item['technique']} | {score['pain']} | {score['fit']} | {score['expected_value']} | "
            f"{score['evidence']} | {score['reversibility']} | {score['cost']} | {score['risk']} | {opportunity_score(item)} |"
        )

    lines += [
        "",
        "## Promotion state",
        "",
        "Ordered by promotion state, not by score.",
        "",
        "| Opportunity | Status | Verdict | Next gate | Accountable authority |",
        "|---|---|---|---|---|",
    ]
    for item in staged:
        lines.append(f"| {item['technique']} | {item['status']} | {item['verdict']} | {item['next_gate']} | {item['authority']} |")

    lines += [
        "",
        "## Results and evidence",
        "",
        "Every path listed here is checked to exist; links are taken on trust.",
        "",
        "| Opportunity | Result | Evidence artifacts | Revisit |",
        "|---|---|---|---|",
    ]
    for item in staged:
        artifacts = ", ".join(f"`{artifact}`" for artifact in item["artifacts"]) or "none yet"
        lines.append(f"| {item['technique']} | {item['result']} | {artifacts} | {item['revisit']} |")

    lines += [
        "",
        "## Course-method dogfooding",
        "",
        "| Dimension | Baseline | Target | Current | Next test |",
        "|---|---|---|---|---|",
    ]
    for check in data["method_checks"]:
        lines.append(f"| {check['dimension']} | {check['baseline']} | {check['target']} | {check['current']} | {check['next_test']} |")
    lines.append("")
    return "\n".join(lines)


def main(arguments: list[str]) -> int:
    data = load_registry()
    errors = validate(data)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    output = render(data)
    if arguments == ["check"]:
        mirror_errors = validate_course_mirrors()
        if mirror_errors:
            print("\n".join(mirror_errors), file=sys.stderr)
            return 1
        if not MATRICES.exists() or MATRICES.read_text(encoding="utf-8") != output:
            print("matrices.md is stale; run: python dogfood.py write", file=sys.stderr)
            return 1
        print(f"validated={len(data['opportunities'])} matrices=current mirrors=current")
        return 0
    if arguments == ["write"]:
        MATRICES.write_text(output, encoding="utf-8", newline="\n")
        print(f"validated={len(data['opportunities'])} wrote={MATRICES.name}")
        return 0
    print(output, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
