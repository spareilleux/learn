"""Offline audit of confidence-only gates on labeled Jev benchmark cases.

The synthetic mode is deliberately not a Jev measurement. The record mode
reuses a completed, digest-bound benchmark receipt without making API calls.
Neither mode authorizes a repository action.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

import jev_benchmark
import typesafe_lab


THRESHOLDS = (0.5, 0.75, 0.9, 0.95, 0.99)
SYNTHETIC_ERRORS = {
    "ga_index_rebuild": 0.8,
    "gaia_design_authority": 0.98,
}


def synthetic_response(cases: list[dict[str, Any]]) -> dict[str, Any]:
    """Seed two known wrong supports, including one at very high confidence."""
    response = jev_benchmark.mock_response(cases, input_tokens=1_000)
    response["model"] = "synthetic-gate-stress/1"
    for case_id, confidence in SYNTHETIC_ERRORS.items():
        answer = response["answers"][case_id]
        remainder = (1 - confidence) / 2
        answer["choice"] = "supported"
        answer["confidence"] = confidence
        answer["probabilities"] = {
            "supported": confidence,
            "contradicted": remainder,
            "insufficient": remainder,
        }
    jev_benchmark.validate_response(response, cases, live=False)
    return response


def load_completed_batch(path: Path, cases: list[dict[str, Any]]) -> dict[str, Any]:
    """Read only a complete receipt for the current pinned corpus and payload."""
    record = json.loads(path.read_text(encoding="utf-8"))
    requests = jev_benchmark.requests_for(jev_benchmark.load_corpus())
    expected_requests = [
        {"name": name, "sha256": hashlib.sha256(typesafe_lab.encode_payload(body)).hexdigest()}
        for name, body in requests
    ]
    if record.get("status") != "complete" or record.get("requests") != expected_requests:
        raise ValueError("The receipt is incomplete or is not bound to the current benchmark payloads.")
    completed = record.get("completed")
    if (
        not isinstance(completed, list)
        or len(completed) != len(expected_requests)
        or [item.get("name") for item in completed] != [item["name"] for item in expected_requests]
    ):
        raise ValueError("The receipt does not contain the complete ordered benchmark.")
    response = completed[0]["response"]
    jev_benchmark.validate_response(response, cases, live=True)
    return response


def sweep(response: dict[str, Any], cases: list[dict[str, Any]]) -> dict[str, Any]:
    jev_benchmark.validate_response(response, cases, live=False)
    rows = []
    for threshold in THRESHOLDS:
        accepted = [
            case for case in cases
            if response["answers"][case["id"]]["choice"] == "supported"
            and response["answers"][case["id"]]["confidence"] >= threshold
        ]
        false_supports = sum(case["expected"] != "supported" for case in accepted)
        rows.append({
            "threshold": threshold,
            "accepted_supported": len(accepted),
            "false_supports": false_supports,
            "reviewed": len(cases) - len(accepted),
            "coverage": round(len(accepted) / len(cases), 4),
        })
    return {
        "source_model": response["model"],
        "cases": len(cases),
        "thresholds": rows,
        "authority_granted": False,
        "provider_called": False,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("synthetic", "record"), nargs="?", default="synthetic")
    parser.add_argument("--input", type=Path, help="Completed jev_benchmark.py live receipt; required for record mode")
    args = parser.parse_args()
    if (args.mode == "record") != (args.input is not None):
        parser.error("--input is required exactly in record mode")
    cases = jev_benchmark.load_corpus()["cases"]
    response = synthetic_response(cases) if args.mode == "synthetic" else load_completed_batch(args.input, cases)
    print(json.dumps(sweep(response, cases), indent=2))


if __name__ == "__main__":
    main()
