from __future__ import annotations

import copy
import unittest

import dogfood


class DogfoodRegistryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.data = dogfood.load_registry()

    def test_registry_is_valid(self) -> None:
        self.assertEqual([], dogfood.validate(self.data))

    def test_generated_matrices_are_current(self) -> None:
        self.assertEqual(dogfood.render(self.data), dogfood.MATRICES.read_text(encoding="utf-8"))

    def test_course_mirrors_and_journal_structure_are_current(self) -> None:
        self.assertEqual([], dogfood.validate_course_mirrors())

    def test_promoted_candidate_requires_evidence(self) -> None:
        changed = copy.deepcopy(self.data)
        changed["opportunities"][0]["status"] = "incubating"
        changed["opportunities"][0]["artifacts"] = []
        self.assertTrue(any("requires evidence" in error for error in dogfood.validate(changed)))

    def test_adoption_requires_confirmed_verdict(self) -> None:
        changed = copy.deepcopy(self.data)
        changed["opportunities"][0]["status"] = "adopted"
        self.assertTrue(any("confirmed verdict" in error for error in dogfood.validate(changed)))

    def test_score_does_not_order_the_promotion_table(self) -> None:
        """The score ranks investigation. A reader must not meet it again in the promotion table.

        Replacing the earlier test, which asserted that a pure sum did not mutate its argument -
        true by construction, and so no evidence of anything.
        """
        best = max(self.data["opportunities"], key=dogfood.opportunity_score)
        rendered = dogfood.render(self.data)
        promotion = rendered.split("## Promotion state", 1)[1].split("## Results", 1)[0]
        # The separator line starts with "|-", so only the header has to be dropped here.
        rows = [line for line in promotion.splitlines() if line.startswith("| ")][1:]
        first = sorted(self.data["opportunities"], key=dogfood.by_status)[0]
        self.assertTrue(rows[0].startswith(f"| {first['technique']} |"))
        if best["id"] != first["id"]:
            self.assertFalse(rows[0].startswith(f"| {best['technique']} |"))

    # The two entries below were built by an independent adversarial review (Codex, 2026-09-23).
    # Both passed every gate before this commit: the registry checked that keys were present,
    # never that they said anything.

    FABRICATED = {
        "id": "malicious-fabricated-adoption",
        "technique": "Self-certified adoption",
        "course": "repository-dogfooding-lab",
        "axis": "both",
        "repositories": ["learn"],
        "observed_pain": "x",
        "hypothesis": "x",
        "baseline": "",
        "success_metric": "",
        "falsifier": "",
        "simpler_alternative": "",
        "status": "adopted",
        "scores": {k: 0 for k in dogfood.SCORE_KEYS},
        "authority": "",
        "next_gate": "",
        "result": "",
        "verdict": "confirmed",
        "artifacts": ["does-not-exist.txt"],
        "revisit": "",
    }

    def test_fabricated_adoption_is_refused(self) -> None:
        changed = copy.deepcopy(self.data)
        changed["opportunities"].append(copy.deepcopy(self.FABRICATED))
        errors = dogfood.validate(changed)
        self.assertTrue(any("must not be blank" in error for error in errors), errors)
        self.assertTrue(any("does not exist" in error for error in errors), errors)

    def test_rejection_without_evidence_is_refused(self) -> None:
        changed = copy.deepcopy(self.data)
        vacuous = copy.deepcopy(self.FABRICATED)
        vacuous.update(id="vacuous-rejection", technique="Rejected with nothing recorded",
                       status="rejected", verdict="refuted", artifacts=[])
        changed["opportunities"].append(vacuous)
        errors = dogfood.validate(changed)
        self.assertTrue(any("requires evidence artifacts" in error for error in errors), errors)

    def test_evidence_cannot_be_links_alone(self) -> None:
        changed = copy.deepcopy(self.data)
        item = changed["opportunities"][0]
        item["status"] = "incubating"
        item["artifacts"] = ["https://example.invalid/nothing-here"]
        self.assertTrue(any("not links alone" in error for error in dogfood.validate(changed)))


if __name__ == "__main__":
    unittest.main()
