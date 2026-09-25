from __future__ import annotations

import copy
import os
from pathlib import Path
import tempfile
import unittest
from unittest import mock

import demerzel_hexavalent as hx
import typesafe_lab


def live_response(symbol: str, **overrides) -> dict:
    response = hx.mock_response(symbol)
    response["model"] = typesafe_lab.MODEL
    response.update(overrides)
    return response


class DemerzelHexavalentTests(unittest.TestCase):
    def test_plan_is_bounded_and_network_free(self) -> None:
        result = hx.plan()
        self.assertEqual(result["calls"], 2 * result["cases"])
        self.assertEqual(result["retries"], 0)
        self.assertLess(result["input_cost_proxy_usd"], hx.MAX_INPUT_COST_PROXY_USD)
        self.assertFalse(result["actual_billed_cost_guaranteed"])

    def test_arms_differ_only_in_option_order(self) -> None:
        case = hx.load_corpus()["cases"][0]
        canonical = hx.payload(case, "canonical")
        reversed_ = hx.payload(case, "reversed")
        canonical_criteria = canonical["questions"]["truth_value"]["criteria"]
        reversed_criteria = reversed_["questions"]["truth_value"]["criteria"]
        self.assertEqual(canonical_criteria, reversed_criteria)
        self.assertEqual(list(canonical_criteria), list(reversed(list(reversed_criteria))))
        self.assertEqual(canonical["state"], reversed_["state"])

    def test_explicit_definitions_change_only_u_and_c(self) -> None:
        case = hx.load_corpus()["cases"][0]
        base = hx.payload(case, "canonical")
        explicit = hx.payload(case, "canonical", "explicit")
        base_criteria = base["questions"]["truth_value"]["criteria"]
        explicit_criteria = explicit["questions"]["truth_value"]["criteria"]
        changed = {key for key in base_criteria if base_criteria[key] != explicit_criteria[key]}
        self.assertEqual(changed, {"unknown", "contradictory"})
        self.assertEqual(list(base_criteria), list(explicit_criteria))
        self.assertEqual(base["state"], explicit["state"])

    def test_labels_are_not_in_the_state(self) -> None:
        for case in hx.load_corpus()["cases"]:
            state = hx.payload(case, "canonical")["state"]
            self.assertEqual(set(state), {"purpose", "proposition", "evidence"})

    def test_two_decimal_rounding_is_accepted(self) -> None:
        response = live_response("U")
        probabilities = response["answers"]["truth_value"]["probabilities"]
        probabilities.update({key: 0.02 for key in probabilities})
        probabilities["unknown"] = 0.89  # sums to 0.99
        self.assertEqual(hx.validate_response(response, live=True), "U")

    def test_invalid_answers_are_rejected(self) -> None:
        bad_choice = live_response("T")
        bad_choice["answers"]["truth_value"]["choice"] = "maybe"
        not_argmax = live_response("T")
        not_argmax["answers"]["truth_value"]["choice"] = "false"
        wrong_model = live_response("T", model="jev-latest")
        for response in (bad_choice, not_argmax, wrong_model):
            with self.assertRaises(typesafe_lab.ContractError):
                hx.validate_response(response, live=True)

    def test_score_counts_safety_errors_on_agreed_cases_only(self) -> None:
        cases = [
            {"id": "a", "label_author": "U", "label_blind": "U"},
            {"id": "b", "label_author": "P", "label_blind": "P"},
            {"id": "c", "label_author": "C", "label_blind": "F"},
        ]
        result = hx.score({"a": "F", "b": "T", "c": None}, cases)
        self.assertEqual(result["agreed_cases"], 2)
        self.assertEqual(result["correct"], 0)
        self.assertEqual(result["absence_as_refutation"], 1)
        self.assertEqual(result["false_true"], 1)
        self.assertEqual(result["invalid"], 1)

    def test_verdict_bands(self) -> None:
        base = {"agreed_cases": 60, "invalid": 0, "false_true": 0, "absence_as_refutation": 0}
        self.assertEqual(hx.verdict({**base, "correct": 45}), "ADVISORY_USEFUL")
        self.assertEqual(hx.verdict({**base, "correct": 44}), "INCONCLUSIVE")
        self.assertEqual(hx.verdict({**base, "correct": 36}), "INCONCLUSIVE")
        self.assertEqual(hx.verdict({**base, "correct": 35}), "KILL")
        self.assertEqual(hx.verdict({**base, "correct": 60, "false_true": 4}), "KILL")
        self.assertEqual(hx.verdict({**base, "correct": 60, "absence_as_refutation": 2}), "INCONCLUSIVE")
        self.assertEqual(hx.verdict({**base, "correct": 60, "invalid": 4}), "INVALID_ARM")

    def test_mock_scores_perfectly_without_network(self) -> None:
        result = hx.run_mock()
        self.assertFalse(result["provider_called"])
        self.assertEqual(result["score"]["correct"], result["score"]["agreed_cases"])

    def test_live_refuses_without_approval(self) -> None:
        with tempfile.TemporaryDirectory() as directory, mock.patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(SystemExit):
                hx.run_live(Path(directory) / "out.json", send=self.fail)

    def test_live_records_errors_without_retry_and_completes(self) -> None:
        corpus = hx.load_corpus()
        labels = {case["id"]: case["label_author"] for case in corpus["cases"]}
        sent: list[str] = []

        def send(payload_value, api_key):
            case_id = next(c["id"] for c in corpus["cases"] if c["evidence"] == payload_value["state"]["evidence"])
            sent.append(case_id)
            if len(sent) == 1:
                raise RuntimeError("timeout; no automatic retry")
            return live_response(labels[case_id]), 1.0

        env = {hx.APPROVAL_ENV: "YES", "TYPESAFE_API_KEY": "test-key-not-real"}
        with tempfile.TemporaryDirectory() as directory, mock.patch.dict(os.environ, env, clear=True):
            summary = hx.run_live(Path(directory) / "out.json", send=send)
        self.assertEqual(len(sent), 2 * len(corpus["cases"]))
        self.assertEqual(summary["canonical"]["score"]["invalid"], 1)
        self.assertEqual(summary["reversed"]["score"]["invalid"], 0)
        self.assertEqual(summary["overall_verdict"], "ADVISORY_USEFUL")

    def test_live_stops_when_reported_usage_crosses_proxy(self) -> None:
        corpus = hx.load_corpus()
        sent: list[int] = []

        def send(payload_value, api_key):
            sent.append(1)
            response = live_response("U")
            response["usage"] = {"input_tokens": 2_000_000, "output_tokens": 0}
            return response, 1.0

        env = {hx.APPROVAL_ENV: "YES", "TYPESAFE_API_KEY": "test-key-not-real"}
        with tempfile.TemporaryDirectory() as directory, mock.patch.dict(os.environ, env, clear=True):
            with self.assertRaises(SystemExit):
                hx.run_live(Path(directory) / "out.json", send=send)
        self.assertEqual(len(sent), 1)
        self.assertGreater(len(corpus["cases"]), 1)


if __name__ == "__main__":
    unittest.main()
