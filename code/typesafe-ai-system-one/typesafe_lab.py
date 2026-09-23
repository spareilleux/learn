"""Offline-first TypeSafe AI experiment with one bounded optional live call."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import tempfile
import time
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import HTTPRedirectHandler, Request, build_opener


API_URL = "https://api.typesafe.ai/v1/systemone"
MODEL = "jev-1.13.0"
INPUT_PRICE_PER_MILLION_USD = 0.042
MAX_PAYLOAD_UTF8_BYTES = 2_500
MAX_INPUT_COST_PROXY_USD = 0.000105
TIMEOUT_SECONDS = 20
DEFAULT_LIVE_RESULT_PATH = Path(__file__).with_name("live-result.json")

STATE = {
    "repository": "GuitarAlchemist/gaia",
    "issue": 76,
    "evidence": [
        "A design receipt exists but implementation authority is not present.",
        "The proposed change adds one successor slot and one bounded replacement.",
        "Exact replay and independent review are required before dispatch."
    ],
}

QUESTIONS = {
    "next_step": {
        "type": "choice",
        "instructions": "Which next lifecycle step is supported by the supplied evidence?",
        "criteria": {
            "design_review": "Review the design; implementation authority is absent or evidence is incomplete.",
            "bounded_implementation": "Implement one bounded tracer only when design and authority evidence are explicit.",
            "reject": "The proposal contradicts a hard constraint or cannot fail closed."
        },
    },
    "delivery_risk": {
        "type": "score",
        "instructions": "How difficult would the proposed effect be to reverse?",
        "criteria": [
            "Low and reversible",
            "Moderate or compensatable",
            "High or hard to reverse",
        ],
    },
    "authority_present": {
        "type": "noul",
        "instructions": "Does the state contain explicit, bounded implementation authority?",
    },
}


class ContractError(ValueError):
    """Raised when a response does not match the subset this lab consumes."""


class RejectRedirects(HTTPRedirectHandler):
    """Keep the bearer token bound to the configured API origin."""

    def redirect_request(self, request, file_pointer, code, message, headers, new_url):
        return None


def _is_number(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def _probabilities(answer: dict[str, Any], expected_keys: set[str]) -> None:
    values = answer.get("probabilities")
    if not isinstance(values, dict) or not values:
        raise ContractError("probabilities must be a non-empty object")
    if set(values) != expected_keys:
        raise ContractError("probability option keys must exactly match the request")
    if any(not _is_number(value) or not 0 <= value <= 1 for value in values.values()):
        raise ContractError("each probability must be between 0 and 1")
    if not math.isclose(sum(values.values()), 1.0, abs_tol=1e-6):
        raise ContractError("probabilities must sum to 1")


def validate_response(response: dict[str, Any]) -> None:
    if not isinstance(response.get("model"), str) or not response["model"]:
        raise ContractError("model must be a non-empty string")
    answers = response.get("answers")
    if not isinstance(answers, dict) or set(answers) != set(QUESTIONS):
        raise ContractError("answers must exactly match the requested question ids")

    choice = answers["next_step"]
    if choice.get("type") != "choice" or choice.get("choice") not in QUESTIONS["next_step"]["criteria"]:
        raise ContractError("next_step is not a valid Choice answer")
    _probabilities(choice, set(QUESTIONS["next_step"]["criteria"]))
    if choice["probabilities"][choice["choice"]] != max(choice["probabilities"].values()):
        raise ContractError("Choice must name an option with maximum probability")

    score = answers["delivery_risk"]
    if (
        score.get("type") != "score"
        or not _is_number(score.get("score"))
        or not 0 <= score["score"] <= len(QUESTIONS["delivery_risk"]["criteria"]) - 1
    ):
        raise ContractError("delivery_risk is not a valid Score answer")
    _probabilities(
        score,
        {str(index) for index in range(len(QUESTIONS["delivery_risk"]["criteria"]))},
    )
    expected_legend = {
        str(index): label
        for index, label in enumerate(QUESTIONS["delivery_risk"]["criteria"])
    }
    if score.get("legend") != expected_legend:
        raise ContractError("Score legend must exactly match the request")
    weighted_score = sum(
        int(level) * probability
        for level, probability in score["probabilities"].items()
    )
    if not math.isclose(score["score"], weighted_score, abs_tol=1e-6):
        raise ContractError("Score must equal its probability-weighted levels")

    noul = answers["authority_present"]
    if noul.get("type") != "noul" or not _is_number(noul.get("noul")) or not 0 <= noul["noul"] <= 1:
        raise ContractError("authority_present is not a valid Noul answer")

    for name in ("next_step", "delivery_risk"):
        confidence = answers[name].get("confidence")
        if not _is_number(confidence) or not 0 <= confidence <= 1:
            raise ContractError(f"{name}.confidence must be between 0 and 1")

    usage = response.get("usage")
    if not isinstance(usage, dict) or set(usage) != {"input_tokens", "output_tokens"}:
        raise ContractError("usage must contain exactly input_tokens and output_tokens")
    if any(
        not isinstance(value, int) or isinstance(value, bool) or value < 0
        for value in usage.values()
    ):
        raise ContractError("usage token counts must be non-negative integers")


def validate_live_response(response: dict[str, Any]) -> None:
    validate_response(response)
    if response["model"] != MODEL:
        raise ContractError(f"live response model must be the pinned {MODEL}")


def route(response: dict[str, Any], *, authority_verified: bool) -> str:
    """Keep authority in code: model output can recommend, never grant it."""
    validate_response(response)
    answers = response["answers"]
    if not authority_verified:
        return "human_review:no_explicit_authority"
    if answers["authority_present"]["noul"] < 0.9:
        return "human_review:model_did_not_observe_authority"
    if answers["next_step"]["confidence"] < 0.75:
        return "human_review:uncertain_next_step"
    if answers["delivery_risk"]["score"] > 1.0:
        return "human_review:risk_above_bound"
    if answers["next_step"]["choice"] == "bounded_implementation":
        return "eligible_for_bounded_dispatch"
    return f"no_dispatch:{answers['next_step']['choice']}"


def request_payload() -> dict[str, Any]:
    return {"state": STATE, "model": MODEL, "questions": QUESTIONS}


def encode_payload(payload: dict[str, Any]) -> bytes:
    return json.dumps(
        payload,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")


def estimated_budget(payload: dict[str, Any]) -> tuple[int, float]:
    encoded = encode_payload(payload)
    payload_bytes = len(encoded)
    cost_proxy = payload_bytes / 1_000_000 * INPUT_PRICE_PER_MILLION_USD
    return payload_bytes, cost_proxy


def run_mock() -> dict[str, Any]:
    response = json.loads(Path(__file__).with_name("mock-response.json").read_text(encoding="utf-8"))
    validate_response(response)
    return {
        "mode": "mock",
        "model": response["model"],
        "decision": route(response, authority_verified=False),
        "request_sha256": hashlib.sha256(encode_payload(request_payload())).hexdigest(),
    }


def open_once(request: Request):
    return build_opener(RejectRedirects()).open(request, timeout=TIMEOUT_SECONDS)


def reserve_output(out_path: Path, reservation: dict[str, Any]) -> None:
    if not out_path.parent.is_dir():
        raise SystemExit("Refusing live probe: output parent directory does not exist.")
    try:
        with out_path.open("x", encoding="utf-8") as reserved:
            json.dump(reservation, reserved, indent=2)
            reserved.write("\n")
            reserved.flush()
            os.fsync(reserved.fileno())
    except FileExistsError as error:
        raise SystemExit("Refusing live probe: output path already exists.") from error


def publish_result(out_path: Path, record: dict[str, Any]) -> None:
    temp_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=out_path.parent,
            prefix=f".{out_path.name}.",
            suffix=".tmp",
            delete=False,
        ) as temporary:
            temp_path = Path(temporary.name)
            json.dump(record, temporary, indent=2)
            temporary.write("\n")
            temporary.flush()
            os.fsync(temporary.fileno())
        os.replace(temp_path, out_path)
    except OSError as error:
        raise SystemExit(
            "Live response received but evidence publication failed; the call may have been charged. Do not retry automatically."
        ) from error
    finally:
        if temp_path is not None and temp_path.exists():
            temp_path.unlink()


def run_live(out_path: Path, *, open_request=open_once) -> dict[str, Any]:
    if out_path.exists():
        raise SystemExit("Refusing live probe: output path already exists.")
    if not out_path.parent.is_dir():
        raise SystemExit("Refusing live probe: output parent directory does not exist.")
    api_key = os.environ.get("TYPESAFE_API_KEY")
    if not api_key:
        raise SystemExit("Refusing live probe: TYPESAFE_API_KEY is not set.")

    payload = request_payload()
    payload_bytes, cost_proxy = estimated_budget(payload)
    if payload_bytes > MAX_PAYLOAD_UTF8_BYTES or cost_proxy > MAX_INPUT_COST_PROXY_USD:
        raise SystemExit("Refusing live probe: local byte/cost proxy limit exceeded.")

    body = encode_payload(payload)
    request_digest = hashlib.sha256(body).hexdigest()
    reservation = {
        "status": "reserved-before-call",
        "model": MODEL,
        "payload_utf8_bytes_before_call": payload_bytes,
        "input_cost_proxy_usd_before_call": cost_proxy,
        "request_sha256": request_digest,
    }
    reserve_output(out_path, reservation)
    request = Request(
        API_URL,
        data=body,
        method="POST",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
    )
    started = time.perf_counter()
    try:
        with open_request(request) as result:
            response = json.load(result)
    except HTTPError as error:
        code = error.code
        error.close()
        raise SystemExit(f"Live probe failed with HTTP {code}; no automatic retry.") from error
    except URLError as error:
        raise SystemExit(f"Live probe failed before a response: {error.reason}; no automatic retry.") from error
    except TimeoutError as error:
        raise SystemExit(f"Live probe timed out: {error}; no automatic retry.") from error
    elapsed_ms = round((time.perf_counter() - started) * 1_000, 1)

    validate_live_response(response)
    record = {
        "mode": "live",
        "tested_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "model": response["model"],
        "decision": route(response, authority_verified=False),
        "elapsed_ms": elapsed_ms,
        "usage": response.get("usage"),
        "payload_utf8_bytes_before_call": payload_bytes,
        "input_cost_proxy_usd_before_call": cost_proxy,
        "request_sha256": request_digest,
    }
    publish_result(out_path, record)
    return record


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("mock", "live"), nargs="?", default="mock")
    parser.add_argument("--out", type=Path, default=DEFAULT_LIVE_RESULT_PATH)
    args = parser.parse_args()
    result = run_mock() if args.mode == "mock" else run_live(args.out)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
