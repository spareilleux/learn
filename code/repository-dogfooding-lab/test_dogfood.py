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

    def test_score_does_not_mutate_authority_or_status(self) -> None:
        item = copy.deepcopy(self.data["opportunities"][0])
        before = (item["status"], item["authority"])
        self.assertIsInstance(dogfood.opportunity_score(item), int)
        self.assertEqual(before, (item["status"], item["authority"]))


if __name__ == "__main__":
    unittest.main()
