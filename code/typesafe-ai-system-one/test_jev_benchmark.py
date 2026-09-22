from __future__ import annotations

import copy
import unittest

import jev_benchmark
import typesafe_lab


class JevBenchmarkTests(unittest.TestCase):
    def test_plan_is_bounded_and_network_free(self) -> None:
        result = jev_benchmark.plan()
        self.assertEqual(result["cases"], 12)
        self.assertEqual(result["calls"], 13)
        self.assertEqual(result["retries"], 0)
        self.assertLessEqual(
            result["estimated_input_token_upper_bound"],
            jev_benchmark.MAX_ESTIMATED_INPUT_TOKENS,
        )
        self.assertLessEqual(
            result["estimated_input_cost_upper_bound_usd"],
            jev_benchmark.MAX_ESTIMATED_INPUT_COST_USD,
        )

    def test_mock_exercises_scoring_without_claiming_jev(self) -> None:
        result = jev_benchmark.run_mock()
        self.assertEqual(result["fixture_model"], "mock-jev-benchmark/1")
        self.assertFalse(result["provider_called"])
        self.assertEqual(result["batch"]["accuracy"], 1.0)
        self.assertEqual(result["batch"]["false_supports"], 0)
        self.assertEqual(result["single_to_batch_input_ratio"], 2.4)

    def test_response_rejects_missing_case(self) -> None:
        corpus = jev_benchmark.load_corpus()
        cases = corpus["cases"]
        response = jev_benchmark.mock_response(cases, input_tokens=100)
        del response["answers"][cases[0]["id"]]
        with self.assertRaises(typesafe_lab.ContractError):
            jev_benchmark.validate_response(response, cases, live=False)

    def test_response_rejects_unknown_probability_label(self) -> None:
        case = jev_benchmark.load_corpus()["cases"][0]
        response = jev_benchmark.mock_response([case], input_tokens=100)
        answer = response["answers"][case["id"]]
        answer["probabilities"] = copy.deepcopy(answer["probabilities"])
        answer["probabilities"]["maybe"] = answer["probabilities"].pop("insufficient")
        with self.assertRaises(typesafe_lab.ContractError):
            jev_benchmark.validate_response(response, [case], live=False)

    def test_corpus_contains_a_prompt_injection_counterexample(self) -> None:
        corpus = jev_benchmark.load_corpus()
        injected = next(case for case in corpus["cases"] if case["id"] == "ga_untrusted_passage")
        self.assertEqual(injected["expected"], "contradicted")
        self.assertIn("ignore", injected["evidence"].lower())


if __name__ == "__main__":
    unittest.main()
