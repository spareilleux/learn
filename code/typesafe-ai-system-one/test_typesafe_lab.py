import copy
from http.server import BaseHTTPRequestHandler, HTTPServer
import io
import json
import os
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch
from urllib.error import HTTPError, URLError
from urllib.request import Request, build_opener

import typesafe_lab


class TypeSafeLabTests(unittest.TestCase):
    def setUp(self) -> None:
        self.response = json.loads(
            Path(__file__).with_name("mock-response.json").read_text(encoding="utf-8")
        )

    def assert_reservation(self, output: Path) -> None:
        payload = typesafe_lab.request_payload()
        estimated_tokens, estimated_cost = typesafe_lab.estimated_budget(payload)
        self.assertEqual(
            {
                "status": "reserved-before-call",
                "model": typesafe_lab.MODEL,
                "estimated_input_tokens_before_call": estimated_tokens,
                "estimated_input_cost_usd_before_call": estimated_cost,
                "request_sha256": typesafe_lab.run_mock()["request_sha256"],
            },
            json.loads(output.read_text(encoding="utf-8")),
        )

    def test_mock_fixture_is_valid_and_cannot_dispatch_without_authority(self) -> None:
        typesafe_lab.validate_response(self.response)
        self.assertEqual(
            "human_review:no_explicit_authority",
            typesafe_lab.route(self.response, authority_verified=False),
        )

    def test_model_cannot_grant_authority(self) -> None:
        response = copy.deepcopy(self.response)
        response["answers"]["authority_present"]["noul"] = 0.99
        response["answers"]["next_step"]["choice"] = "bounded_implementation"
        response["answers"]["next_step"]["confidence"] = 0.99
        response["answers"]["next_step"]["probabilities"] = {
            "design_review": 0.1,
            "bounded_implementation": 0.88,
            "reject": 0.02,
        }
        response["answers"]["delivery_risk"]["score"] = 0.0
        response["answers"]["delivery_risk"]["probabilities"] = {
            "0": 1.0,
            "1": 0.0,
            "2": 0.0,
        }
        self.assertEqual(
            "human_review:no_explicit_authority",
            typesafe_lab.route(response, authority_verified=False),
        )

    def test_verified_authority_still_obeys_every_model_policy_branch(self) -> None:
        response = copy.deepcopy(self.response)
        self.assertEqual(
            "human_review:model_did_not_observe_authority",
            typesafe_lab.route(response, authority_verified=True),
        )

        response["answers"]["authority_present"]["noul"] = 0.99
        response["answers"]["next_step"]["confidence"] = 0.5
        self.assertEqual(
            "human_review:uncertain_next_step",
            typesafe_lab.route(response, authority_verified=True),
        )

        response["answers"]["next_step"]["confidence"] = 0.99
        self.assertEqual(
            "human_review:risk_above_bound",
            typesafe_lab.route(response, authority_verified=True),
        )

        response["answers"]["delivery_risk"]["score"] = 0.0
        response["answers"]["delivery_risk"]["probabilities"] = {
            "0": 1.0,
            "1": 0.0,
            "2": 0.0,
        }
        response["answers"]["next_step"]["choice"] = "bounded_implementation"
        response["answers"]["next_step"]["probabilities"] = {
            "design_review": 0.1,
            "bounded_implementation": 0.88,
            "reject": 0.02,
        }
        self.assertEqual(
            "eligible_for_bounded_dispatch",
            typesafe_lab.route(response, authority_verified=True),
        )

    def test_unknown_choice_is_rejected(self) -> None:
        response = copy.deepcopy(self.response)
        response["answers"]["next_step"]["choice"] = "merge_now"
        with self.assertRaisesRegex(typesafe_lab.ContractError, "valid Choice"):
            typesafe_lab.validate_response(response)

    def test_probabilities_must_sum_to_one(self) -> None:
        response = copy.deepcopy(self.response)
        response["answers"]["next_step"]["probabilities"]["reject"] = 0.2
        with self.assertRaisesRegex(typesafe_lab.ContractError, "sum to 1"):
            typesafe_lab.validate_response(response)

    def test_response_types_and_choice_probability_keys_are_strict(self) -> None:
        response = copy.deepcopy(self.response)
        response["answers"]["authority_present"]["noul"] = True
        with self.assertRaisesRegex(typesafe_lab.ContractError, "Noul"):
            typesafe_lab.validate_response(response)

        response = copy.deepcopy(self.response)
        response["answers"]["next_step"]["probabilities"] = {
            "bounded_implementation": 0.5,
            "design_review": 0.5,
            "invented": 0.0,
        }
        with self.assertRaisesRegex(typesafe_lab.ContractError, "option keys"):
            typesafe_lab.validate_response(response)

        response = copy.deepcopy(self.response)
        response["answers"]["delivery_risk"]["score"] = 3.0
        with self.assertRaisesRegex(typesafe_lab.ContractError, "Score"):
            typesafe_lab.validate_response(response)

    def test_score_must_match_legend_and_probability_weighting(self) -> None:
        response = copy.deepcopy(self.response)
        response["answers"]["delivery_risk"]["score"] = 0.0
        with self.assertRaisesRegex(typesafe_lab.ContractError, "probability-weighted"):
            typesafe_lab.validate_response(response)

        response = copy.deepcopy(self.response)
        response["answers"]["delivery_risk"]["legend"]["2"] = "Invented"
        with self.assertRaisesRegex(typesafe_lab.ContractError, "legend"):
            typesafe_lab.validate_response(response)

    def test_usage_is_required_and_strict(self) -> None:
        response = copy.deepcopy(self.response)
        del response["usage"]
        with self.assertRaisesRegex(typesafe_lab.ContractError, "usage"):
            typesafe_lab.validate_response(response)

        response = copy.deepcopy(self.response)
        response["usage"]["input_tokens"] = 0.5
        with self.assertRaisesRegex(typesafe_lab.ContractError, "non-negative integers"):
            typesafe_lab.validate_response(response)

    def test_estimated_budget_is_below_the_hard_ceiling(self) -> None:
        tokens, cost = typesafe_lab.estimated_budget(typesafe_lab.request_payload())
        self.assertLessEqual(tokens, typesafe_lab.MAX_ESTIMATED_INPUT_TOKENS)
        self.assertLessEqual(cost, typesafe_lab.MAX_ESTIMATED_INPUT_COST_USD)

    def test_live_path_rejects_model_substitution_before_writing(self) -> None:
        response = copy.deepcopy(self.response)
        response["model"] = "substituted-model"

        def fake_open(_request):
            return io.StringIO(json.dumps(response))

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "result.json"
            with patch.dict(os.environ, {"TYPESAFE_API_KEY": "test-only"}):
                with self.assertRaisesRegex(typesafe_lab.ContractError, "pinned"):
                    typesafe_lab.run_live(output, open_request=fake_open)
            self.assert_reservation(output)

    def test_live_path_reuses_mock_request_identity_and_never_overwrites(self) -> None:
        response = copy.deepcopy(self.response)
        response["model"] = typesafe_lab.MODEL
        calls = 0

        def fake_open(_request):
            nonlocal calls
            calls += 1
            return io.StringIO(json.dumps(response))

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "result.json"
            with patch.dict(os.environ, {"TYPESAFE_API_KEY": "test-only"}):
                live = typesafe_lab.run_live(output, open_request=fake_open)
                with self.assertRaisesRegex(SystemExit, "already exists"):
                    typesafe_lab.run_live(output, open_request=fake_open)
            self.assertEqual(typesafe_lab.run_mock()["request_sha256"], live["request_sha256"])
            self.assertEqual("human_review:no_explicit_authority", live["decision"])
            self.assertNotIn("response", json.loads(output.read_text(encoding="utf-8")))
            self.assertEqual(1, calls)

    def test_redirect_is_rejected_before_authorization_reaches_second_origin(self) -> None:
        observed_authorization: list[str | None] = []

        class RedirectTarget(BaseHTTPRequestHandler):
            def do_GET(self):
                observed_authorization.append(self.headers.get("Authorization"))
                self.send_response(200)
                self.end_headers()

            def log_message(self, *_args):
                return

        target = HTTPServer(("127.0.0.1", 0), RedirectTarget)
        target_thread = threading.Thread(target=target.handle_request, daemon=True)
        target_thread.start()

        class RedirectSource(BaseHTTPRequestHandler):
            def do_GET(self):
                host, port = target.server_address
                self.send_response(302)
                self.send_header("Location", f"http://{host}:{port}/target")
                self.end_headers()

            def log_message(self, *_args):
                return

        source = HTTPServer(("127.0.0.1", 0), RedirectSource)
        source_thread = threading.Thread(target=source.handle_request, daemon=True)
        source_thread.start()
        host, port = source.server_address
        request = Request(
            f"http://{host}:{port}/start",
            headers={"Authorization": "Bearer test-only"},
        )
        try:
            with self.assertRaises(HTTPError) as raised:
                build_opener(typesafe_lab.RejectRedirects()).open(request, timeout=2)
            self.assertEqual(302, raised.exception.code)
            raised.exception.close()
            self.assertEqual([], observed_authorization)
        finally:
            source.server_close()
            target.server_close()

    def test_publication_failure_preserves_reservation_and_does_not_retry(self) -> None:
        response = copy.deepcopy(self.response)
        response["model"] = typesafe_lab.MODEL
        calls = 0

        def fake_open(_request):
            nonlocal calls
            calls += 1
            return io.StringIO(json.dumps(response))

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "result.json"
            with patch.dict(os.environ, {"TYPESAFE_API_KEY": "test-only"}):
                with patch.object(typesafe_lab.os, "replace", side_effect=OSError("disk")):
                    with self.assertRaisesRegex(SystemExit, "may have been charged"):
                        typesafe_lab.run_live(output, open_request=fake_open)
            self.assert_reservation(output)
            self.assertEqual([], list(Path(directory).glob("*.tmp")))
            self.assertEqual(1, calls)

    def test_network_errors_make_one_attempt_and_preserve_reservation(self) -> None:
        error_factories = (
            lambda: HTTPError(typesafe_lab.API_URL, 529, "busy", {}, None),
            lambda: URLError("offline"),
            lambda: TimeoutError("slow"),
        )
        for index, error_factory in enumerate(error_factories):
            error = error_factory()
            with self.subTest(error=type(error).__name__), tempfile.TemporaryDirectory() as directory:
                output = Path(directory) / f"result-{index}.json"
                calls = 0

                def fake_open(_request):
                    nonlocal calls
                    calls += 1
                    raise error

                with patch.dict(os.environ, {"TYPESAFE_API_KEY": "test-only"}):
                    with self.assertRaises(SystemExit):
                        typesafe_lab.run_live(output, open_request=fake_open)
                self.assertEqual(1, calls)
                self.assert_reservation(output)


if __name__ == "__main__":
    unittest.main()
