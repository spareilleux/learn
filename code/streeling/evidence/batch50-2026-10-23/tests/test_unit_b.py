"""Independent checks of Unit B's authored cases; no production execution.

Inputs come from unit-b.json. Expected witnesses below were independently
derived from the course rules, not copied from the packet's expected fields.
The latter are compared only after deriving the result. Controls use separate
stipulated inputs and never mutate canonical data.
"""

from collections import Counter
from fractions import Fraction
from itertools import groupby
import json
from pathlib import Path
import re
import unittest


EVIDENCE = Path(__file__).resolve().parents[1]
ROOT = EVIDENCE.parents[3]
PACKET = json.loads((EVIDENCE / "unit-b.json").read_text(encoding="utf-8"))
COURSES = {course["code"]: course for course in PACKET["courses"]}
SCOPE = "Authored fixed-data calculation or logical witness only; no human, learner or production-runtime acceptance."


def values(code):
    return COURSES[code]["authored_model"]["values"]


def expected_claim(code):
    return COURSES[code]["authored_model"]["expected"]


def rational(value):
    return Fraction(str(value))


def wire(value):
    if isinstance(value, Fraction):
        return str(value)
    if isinstance(value, dict):
        return {key: wire(item) for key, item in value.items()}
    if isinstance(value, (tuple, list)):
        return [wire(item) for item in value]
    return value


def bucket_trace(inputs, refill=None):
    balance = inputs["capacity_tokens"]
    rate = inputs["refill_tokens_per_second"] if refill is None else refill
    last_time = 0
    admitted, remaining = [], []
    for time in inputs["arrivals_seconds"]:
        balance = min(inputs["capacity_tokens"], balance + rate * (time - last_time))
        accepts = balance >= inputs["cost_per_job"]
        if accepts:
            balance -= inputs["cost_per_job"]
        admitted.append(accepts)
        remaining.append(balance)
        last_time = time
    return {"admitted": admitted, "remaining": remaining,
            "admissions": sum(admitted), "denials": len(admitted) - sum(admitted)}


def derivative_trace(samples, inputs, dt=None):
    interval = rational(inputs["dt_seconds"] if dt is None else dt)
    raw = [(rational(b) - rational(a)) / interval for a, b in zip(samples, samples[1:])]
    alpha = rational(inputs["filter_alpha"])
    state = rational(inputs["filter_initial"])
    filtered = []
    for derivative in raw:
        state = alpha * derivative + (1 - alpha) * state
        filtered.append(state)
    return raw, filtered


def integrals(inputs, lower=None, upper=None):
    low = inputs["lower_limit"] if lower is None else lower
    high = inputs["upper_limit"] if upper is None else upper
    naive = conditional = inputs["initial_integral"]
    states, commands, limited_states, limited_commands = [], [], [], []
    for error in inputs["errors"]:
        delta = inputs["gain"] * error * inputs["dt_seconds"]
        naive += delta
        candidate = conditional + delta
        outward = (candidate > high and error > 0) or (candidate < low and error < 0)
        if not outward:
            conditional = candidate
        states.append(naive)
        commands.append(max(low, min(high, naive)))
        limited_states.append(conditional)
        limited_commands.append(max(low, min(high, conditional)))
    return {"naive_integrals": states, "naive_commands": commands,
            "conditional_integrals": limited_states, "conditional_commands": limited_commands}


def fold_history(events, initial):
    revision, approved = None, initial != "unapproved"
    trace = []
    for event in events:
        action, target = event.split(":", 1)
        if action == "edit":
            revision, approved = target, False
        elif action == "approve":
            # A first approval names the initially reviewed revision.
            if revision is None:
                revision = target
            approved = target == revision
        elif action != "note":
            raise ValueError("Unknown event kind: " + action)
        trace.append([revision, approved])
    return {"revision": revision, "approved": approved, "trace": trace}


def earliest_schedule(durations, edges):
    remaining = set(durations)
    finishes, intervals = {}, {}
    while remaining:
        ready = sorted(node for node in remaining
                       if all(a in finishes for a, b in edges if b == node))
        if not ready:
            raise ValueError("Cycle or unknown predecessor")
        for node in ready:
            start = max((finishes[a] for a, b in edges if b == node), default=0)
            finishes[node] = start + durations[node]
            intervals[node] = [start, finishes[node]]
            remaining.remove(node)
    return finishes, intervals


def reachable(edges, start, end):
    visited, frontier = set(), [start]
    while frontier:
        node = frontier.pop()
        if node == end:
            return True
        if node not in visited:
            visited.add(node)
            frontier.extend(b for a, b in edges if a == node)
    return False


def compatibility(producer, consumer):
    matches = {field + "_match": producer[field] == consumer[field]
               for field in ("shape", "orientation", "sample_rate_hz", "scale")}
    matches["sample_rate_match"] = matches.pop("sample_rate_hz_match")
    matches["compatible"] = all(matches.values())
    matches["mismatches"] = sum(producer[key] != consumer[key] for key in producer)
    return matches


def adoption_ratios(inputs):
    return {
        "adoption": Fraction(inputs["enabled_in_cohort"], inputs["eligible_active_cohort"]),
        "attempted_coverage": Fraction(inputs["task_attempted_in_enabled_cohort"], inputs["enabled_in_cohort"]),
        "task_success_fraction": Fraction(inputs["task_success_in_attempted"], inputs["task_attempted_in_enabled_cohort"]),
        "cohort_task_success_rate": Fraction(inputs["task_success_in_attempted"], inputs["eligible_active_cohort"]),
        "downloads_per_cohort_member": Fraction(inputs["download_events"], inputs["eligible_active_cohort"]),
    }


class UnitBClaimTests(unittest.TestCase):
    def observe(self, code, case, observed, expected):
        print("OBSERVATION " + json.dumps({"code": code, "case": case,
              "observed": wire(observed), "expected": wire(expected), "scope": SCOPE}, sort_keys=True), flush=True)
        self.assertEqual(observed, expected)

    def check_packet_fields(self, code, observed):
        # This compares a separately calculated observation with the authored claim.
        claims = expected_claim(code)
        for key, result in observed.items():
            with self.subTest(code=code, claim=key):
                claim = claims[key]
                if isinstance(result, Fraction):
                    self.assertEqual(result, rational(claim))
                else:
                    self.assertEqual(result, claim)

    def test_CS015_first_writer_union_detects_gap(self):
        data = values("CS015")
        seen, owned = set(), []
        for start, end in data["chunks"]:
            fresh = sorted(set(range(start, end)) - seen)
            owned.append([fresh[0], fresh[-1] + 1])
            seen.update(fresh)
        raw = sum(end - start for start, end in data["chunks"])
        result = {"raw_frames": raw, "distinct_frames": len(seen),
                  "duplicate_emissions": raw - len(seen), "owned": owned}
        self.observe("CS015", "model", result, {"raw_frames": 16, "distinct_frames": 12,
                     "duplicate_emissions": 4, "owned": [[0, 6], [6, 10], [10, 12]]})
        self.check_packet_fields("CS015", result)
        self.assertEqual(seen, set(range(*data["target"])))
        gap_union = set(range(0, 6)) | set(range(7, 12))
        missing = sorted(set(range(*data["target"])) - gap_union)
        self.observe("CS015", "negative", {"missing": missing, "complete": not missing},
                     {"missing": [6], "complete": False})

    def test_CS016_request_is_not_terminal_cancellation(self):
        data = values("CS016")
        requested = set(data["requested"])
        cancelled = requested & set(data["acknowledged_cancelled"])
        completed = requested & set(data["completed"])
        unknown = requested - cancelled - completed
        result = {"requests": len(requested), "cancelled": len(cancelled),
                  "completed": len(completed), "unknown": len(unknown),
                  "safe_to_claim_all_cancelled": cancelled == requested}
        self.observe("CS016", "model", result, {"requests": 3, "cancelled": 1,
                     "completed": 1, "unknown": 1, "safe_to_claim_all_cancelled": False})
        self.check_packet_fields("CS016", result)
        self.assertFalse(cancelled & completed)
        self.assertEqual(unknown, set(data["unknown"]))
        self.assertEqual(data["B_effect"], "written")
        terminals = {attempt: "cancelled" if attempt in set() else "unknown" for attempt in requested}
        self.observe("CS016", "negative", terminals, {"A": "unknown", "B": "unknown", "C": "unknown"})
        self.assertNotEqual(set(terminals.values()), {"cancelled"})

    def test_CS017_reordering_and_guard_move_have_witnesses(self):
        data = values("CS017")
        original = [2 * (x + 1) for x in data["inputs"]]
        swapped = [2 * x + 1 for x in data["inputs"]]
        witness = next(x for x in data["inputs"] if (x > 0) != (x + 1 > 0))
        result = {"original": original, "swapped": swapped, "guard_witness": witness,
                  "before": "accept" if witness > 0 else "reject",
                  "after": "accept" if witness + 1 > 0 else "reject"}
        self.observe("CS017", "model", result, {"original": [-2, 2, 6], "swapped": [-3, 1, 5],
                     "guard_witness": 0, "before": "reject", "after": "accept"})
        self.check_packet_fields("CS017", result)
        self.assertEqual([data["f"], data["g"], data["guard"]], ["x+1", "2*x", "x>0"])
        identity = [2 * (x + 1) for x in data["inputs"]]
        self.observe("CS017", "negative", {"unchanged": identity, "mismatch_indices":
                     [i for i, (a, b) in enumerate(zip(original, identity)) if a != b]},
                     {"unchanged": [-2, 2, 6], "mismatch_indices": []})

    def test_CYB009_token_credit_respects_simultaneous_arrivals(self):
        data = values("CYB009")
        result = bucket_trace(data)
        self.observe("CYB009", "model", result, {"admitted": [True, True, True, False, True, False, True],
                     "remaining": [2, 1, 0, 0, 0, 0, 0], "admissions": 5, "denials": 2})
        self.check_packet_fields("CYB009", result)
        control = bucket_trace(data, refill=0)
        self.observe("CYB009", "negative", control, {"admitted": [True, True, True, False, False, False, False],
                     "remaining": [2, 1, 0, 0, 0, 0, 0], "admissions": 3, "denials": 4})

    def test_CYB010_finite_difference_and_initialized_filter(self):
        data = values("CYB010")
        raw, filtered = derivative_trace(data["measurement"], data)
        truth, _ = derivative_trace(data["true_position"], data)
        half, _ = derivative_trace(data["measurement"], data, rational(data["dt_seconds"]) / 2)
        result = {"true_derivative": truth, "raw_derivative": raw,
                  "filtered_derivative": filtered, "half_dt_raw": half}
        self.observe("CYB010", "model", result, {"true_derivative": [0, 0], "raw_derivative": [2, -2],
                     "filtered_derivative": [1, Fraction(-1, 2)], "half_dt_raw": [4, -4]})
        self.check_packet_fields("CYB010", result)
        constant = [data["measurement"][0]] * len(data["measurement"])
        zero_raw, zero_filtered = derivative_trace(constant, data)
        self.observe("CYB010", "negative", {"raw": zero_raw, "filtered": zero_filtered},
                     {"raw": [0, 0], "filtered": [0, 0]})

    def test_CYB011_stored_integral_differs_from_capped_command(self):
        data = values("CYB011")
        result = integrals(data)
        self.observe("CYB011", "model", result, {"naive_integrals": [3, 6, 9, 8],
                     "naive_commands": [2, 2, 2, 2], "conditional_integrals": [0, 0, 0, 0],
                     "conditional_commands": [0, 0, 0, 0]})
        self.check_packet_fields("CYB011", result)
        self.observe("CYB011", "negative", integrals(data, lower=-100, upper=100),
                     {"naive_integrals": [3, 6, 9, 8], "naive_commands": [3, 6, 9, 8],
                      "conditional_integrals": [3, 6, 9, 8], "conditional_commands": [3, 6, 9, 8]})

    def test_COG009_equal_order_weights_remove_stipulated_period_effect(self):
        data = values("COG009")
        a, b, period = data["A_base_seconds"], data["B_base_seconds"], data["second_period_change_seconds"]
        ab, ba = [a, b + period], [b, a + period]
        contrasts = [ab[1] - ab[0], ba[0] - ba[1]]
        result = {"AB_contrast_seconds": contrasts[0], "BA_contrast_seconds": contrasts[1],
                  "balanced_contrast_seconds": Fraction(sum(contrasts), 2),
                  "A_mean_seconds": Fraction(ab[0] + ba[1], 2),
                  "B_mean_seconds": Fraction(ab[1] + ba[0], 2)}
        self.observe("COG009", "model", result, {"AB_contrast_seconds": -20, "BA_contrast_seconds": 0,
                     "balanced_contrast_seconds": -10, "A_mean_seconds": 55, "B_mean_seconds": 45})
        self.check_packet_fields("COG009", result)
        self.assertEqual([ab, ba], [data["AB"], data["BA"]])
        null_contrasts = [(a + period) - a, a - (a + period)]
        self.observe("COG009", "negative", {"contrasts": null_contrasts, "balanced": Fraction(sum(null_contrasts), 2)},
                     {"contrasts": [-10, 10], "balanced": 0})

    def test_COG010_exposure_exclusion_changes_both_eligible_counts(self):
        data = values("COG010")
        rate = lambda row: Fraction(row["correct"], row["observed"])
        correct = data["delayed_novel"]["correct"] - data["novel_exposed_correct"]
        observed = data["delayed_novel"]["observed"] - data["novel_exposed_correct"]
        result = {"immediate_rate": rate(data["immediate_repeated"]),
                  "delayed_repeated_rate": rate(data["delayed_repeated"]),
                  "raw_novel_rate": rate(data["delayed_novel"]),
                  "eligible_novel_correct": correct, "eligible_novel_observed": observed,
                  "eligible_novel_rate_fraction": Fraction(correct, observed),
                  "repeated_rate_change": rate(data["delayed_repeated"]) - rate(data["immediate_repeated"])}
        self.observe("COG010", "model", result, {"immediate_rate": Fraction(4, 5), "delayed_repeated_rate": Fraction(3, 5),
                     "raw_novel_rate": Fraction(3, 8), "eligible_novel_correct": 2, "eligible_novel_observed": 7,
                     "eligible_novel_rate_fraction": Fraction(2, 7), "repeated_rate_change": Fraction(-1, 5)})
        self.check_packet_fields("COG010", result)
        repeated_only = {key: row for key, row in data.items() if key.endswith("repeated")}
        novel_observed = sum(row["observed"] for key, row in repeated_only.items() if "novel" in key)
        self.observe("COG010", "negative", {"novel_observations": novel_observed, "transfer_supported": novel_observed > 0},
                     {"novel_observations": 0, "transfer_supported": False})

    def test_COG011_paired_ratings_preserve_disputed_item_identity(self):
        data = values("COG011")
        pairs = list(zip(data["rater_A"], data["rater_B"], strict=True))
        cells = Counter(pairs)
        n = len(pairs)
        agreed = sum(a == b for a, b in pairs)
        result = {"both_pass": cells[1, 1], "A_only": cells[1, 0], "B_only": cells[0, 1],
                  "both_fail": cells[0, 0], "paired": n, "agreement_fraction": Fraction(agreed, n),
                  "disagreement_fraction": Fraction(n - agreed, n), "disputed_items":
                  [i for i, (a, b) in enumerate(pairs, 1) if a != b], "unanimous_pass_fraction": Fraction(cells[1, 1], n)}
        self.observe("COG011", "model", result, {"both_pass": 2, "A_only": 1, "B_only": 1, "both_fail": 2,
                     "paired": 6, "agreement_fraction": Fraction(2, 3), "disagreement_fraction": Fraction(1, 3),
                     "disputed_items": [2, 4], "unanimous_pass_fraction": Fraction(1, 3)})
        self.check_packet_fields("COG011", result)
        copied = {"ratings": list(data["rater_A"]), "origin": "copied-A"}
        agreement = Fraction(sum(a == b for a, b in zip(data["rater_A"], copied["ratings"])), n)
        self.observe("COG011", "negative", {"agreement": agreement, "independent_second_origin": copied["origin"] == "independent-B"},
                     {"agreement": 1, "independent_second_origin": False})

    def test_INF010_joint_tables_refute_marginal_product(self):
        data = values("INF010")
        rates = []
        totals = []
        for name in ("case_X", "case_Y"):
            cells = data[name]
            totals.append(sum(cells.values()))
            rates.append({"A": Fraction(cells["both_pass"] + cells["A_only"], data["total"]),
                          "B": Fraction(cells["both_pass"] + cells["B_only"], data["total"]),
                          "joint": Fraction(cells["both_pass"], data["total"])})
        product = rates[0]["A"] * rates[0]["B"]
        result = {"A_rate": rates[0]["A"], "B_rate": rates[0]["B"], "X_joint_rate": rates[0]["joint"],
                  "Y_joint_rate": rates[1]["joint"], "independence_product": product,
                  "X_product_error": product - rates[0]["joint"], "Y_product_error": product - rates[1]["joint"]}
        self.observe("INF010", "model", result, {"A_rate": Fraction(3, 5), "B_rate": Fraction(3, 5),
                     "X_joint_rate": Fraction(3, 5), "Y_joint_rate": Fraction(1, 5), "independence_product": Fraction(9, 25),
                     "X_product_error": Fraction(-6, 25), "Y_product_error": Fraction(4, 25)})
        for total in totals:
            self.assertEqual(total, data["total"])
        self.check_packet_fields("INF010", result)
        self.assertEqual([rates[1]["A"], rates[1]["B"]], [Fraction(3, 5), Fraction(3, 5)])
        cells = [9, 6, 6, 4]
        total = sum(cells)
        joint = Fraction(cells[0], total)
        independent_product = Fraction(cells[0] + cells[1], total) * Fraction(cells[0] + cells[2], total)
        self.observe("INF010", "negative", {"joint": joint, "product": independent_product, "equal": joint == independent_product},
                     {"joint": Fraction(9, 25), "product": Fraction(9, 25), "equal": True})

    def test_INF011_reversible_run_lengths_charge_header_and_can_expand(self):
        data = values("INF011")
        def encode(raw):
            return "".join(symbol + str(len(list(run))) for symbol, run in groupby(raw))
        def decode(payload):
            return "".join(payload[i] * int(payload[i + 1]) for i in range(0, len(payload), 2))
        payload = encode(data["raw"])
        stored = data["header_bytes"] + len(payload.encode("ascii"))
        collision = [data["raw"], "ABAAAABB"]
        result = {"stored_bytes": stored, "ratio": Fraction(stored, len(data["raw"].encode("ascii"))),
                  "decoded": decode(payload), "lossy_collision": collision,
                  "alphabet_summary": "".join(sorted(set(data["raw"])))}
        self.observe("INF011", "model", result, {"stored_bytes": 6, "ratio": Fraction(3, 4), "decoded": "AAAAABBB",
                     "lossy_collision": ["AAAAABBB", "ABAAAABB"], "alphabet_summary": "AB"})
        self.check_packet_fields("INF011", result)
        self.assertEqual(payload, data["payload"])
        self.assertEqual(len(data["raw"].encode("ascii")), data["raw_bytes"])
        self.assertEqual(len(payload.encode("ascii")), data["payload_bytes"])
        self.assertNotEqual(*collision)
        self.assertEqual(set(collision[0]), set(collision[1]))
        control_payload = encode(data["control_raw"])
        control_stored = data["header_bytes"] + len(control_payload.encode("ascii"))
        control = {"stored_bytes": control_stored, "ratio": Fraction(control_stored, len(data["control_raw"].encode("ascii"))),
                   "decoded": decode(control_payload), "expanded": control_stored > len(data["control_raw"])}
        self.observe("INF011", "negative", control, {"stored_bytes": 18, "ratio": Fraction(9, 4), "decoded": "ABABABAB", "expanded": True})
        self.assertEqual(control_payload, data["control_payload"])
        self.check_packet_fields("INF011", {"control_stored_bytes": control_stored, "control_ratio": control["ratio"]})

    def test_INF012_ordered_revision_fold_rejects_stale_approval(self):
        data = values("INF012")
        a, b = [fold_history(data[key], data["initial"]) for key in ("history_A", "history_B")]
        counts_a = Counter(event.split(":")[0] for event in data["history_A"])
        counts_b = Counter(event.split(":")[0] for event in data["history_B"])
        result = {"A_final_revision": a["revision"], "A_approved": a["approved"],
                  "B_final_revision": b["revision"], "B_approved": b["approved"],
                  "same_edit_count": counts_a["edit"], "same_approval_count": counts_a["approve"]}
        self.observe("INF012", "model", result, {"A_final_revision": "r2", "A_approved": False,
                     "B_final_revision": "r2", "B_approved": True, "same_edit_count": 1, "same_approval_count": 1})
        self.check_packet_fields("INF012", result)
        self.assertEqual(counts_a, counts_b)
        first = fold_history(data["history_B"] + ["note:x", "note:y"], data["initial"])
        second = fold_history(data["history_B"] + ["note:y", "note:x"], data["initial"])
        stale = fold_history(["edit:r2", "approve:r1"], data["initial"])
        self.observe("INF012", "negative", {"permuted_notes_same_state": [first["revision"], first["approved"]] ==
                     [second["revision"], second["approved"]], "revision": first["revision"], "approved": first["approved"],
                     "wrong_revision_approved": stale["approved"]},
                     {"permuted_notes_same_state": True, "revision": "r2", "approved": True, "wrong_revision_approved": False})

    def test_NET010_resource_serialization_exceeds_dependency_bound(self):
        data = values("NET010")
        finishes, _ = earliest_schedule(data["durations_ticks"], data["edges"])
        first, second = data["shared_resource_jobs"]
        serial_finishes, serial = earliest_schedule(data["durations_ticks"], data["edges"] + [[first, second]])
        reverse_finishes, _ = earliest_schedule(data["durations_ticks"], data["edges"] + [[second, first]])
        result = {"unlimited_earliest_finish": finishes, "dependency_lower_bound": max(finishes.values()),
                  "resource_schedule": serial, "resource_makespan": max(serial_finishes.values()),
                  "alternative_resource_order_makespan": max(reverse_finishes.values())}
        self.observe("NET010", "model", result, {"unlimited_earliest_finish": {"A": 2, "B": 6, "C": 5, "D": 7},
                     "dependency_lower_bound": 7, "resource_schedule": {"A": [0, 2], "B": [2, 6], "C": [6, 9], "D": [9, 10]},
                     "resource_makespan": 10, "alternative_resource_order_makespan": 10})
        self.check_packet_fields("NET010", result)
        self.assertEqual(data["resource_capacity"], 1)
        _, parallel = earliest_schedule(data["durations_ticks"], data["edges"])
        overlap = min(parallel[first][1], parallel[second][1]) - max(parallel[first][0], parallel[second][0])
        self.observe("NET010", "negative", {"finish_without_conflict": max(end for start, end in parallel.values()),
                     "B_C_overlap_ticks": max(0, overlap)}, {"finish_without_conflict": 7, "B_C_overlap_ticks": 3})

    def test_NET011_structural_path_does_not_imply_contract_compatibility(self):
        data = values("NET011")
        result = {"reachable": reachable(data["edges"], "capture", "display"),
                  **compatibility(data["producer"], data["consumer"])}
        self.observe("NET011", "model", result, {"reachable": True, "shape_match": True, "orientation_match": False,
                     "sample_rate_match": True, "scale_match": False, "compatible": False, "mismatches": 2})
        self.check_packet_fields("NET011", result)
        matching = dict(data["consumer"], orientation="frame-major", scale="linear")
        self.observe("NET011", "negative", compatibility(data["producer"], matching),
                     {"shape_match": True, "orientation_match": True, "sample_rate_match": True,
                      "scale_match": True, "compatible": True, "mismatches": 0})

    def test_PM008_review_roles_have_separate_workloads_and_capacities(self):
        data = values("PM008")
        n = data["courses"]
        translations = n * (data["locales"] - 1)
        work = {"subject": n * data["subject_minutes_per_course"],
                "language": translations * data["language_minutes_per_translation"],
                "learner": n * data["learner_minutes_per_course"]}
        days = {role: Fraction(minutes, data[role + "_minutes_per_day"]) for role, minutes in work.items()}
        result = {"sources": n * data["locales"], "localized_answer_pairs": n * data["locales"] * data["exercises_per_course"],
                  "prepared_learner_criteria": n * data["exercises_per_course"],
                  **{role + "_minutes": minutes for role, minutes in work.items()}, "total_minutes": sum(work.values()),
                  **{role + "_days": duration for role, duration in days.items()}, "optimistic_parallel_days": max(days.values())}
        self.observe("PM008", "model", result, {"sources": 150, "localized_answer_pairs": 750, "prepared_learner_criteria": 250,
                     "subject_minutes": 1000, "language_minutes": 1200, "learner_minutes": 1250, "total_minutes": 3450,
                     "subject_days": 10, "language_days": 6, "learner_days": 10, "optimistic_parallel_days": 10})
        self.check_packet_fields("PM008", result)
        self.assertEqual(translations, data["translated_sources"])
        capacity = 0
        finite_finish = Fraction(work["subject"], capacity) if capacity else None
        self.observe("PM008", "negative", {"required_minutes": work["subject"], "capacity": capacity, "finite_finish_days": finite_finish},
                     {"required_minutes": 1000, "capacity": 0, "finite_finish_days": None})

    def test_PM009_adoption_and_task_ratios_ignore_mirror_downloads(self):
        data = values("PM009")
        result = adoption_ratios(data)
        self.observe("PM009", "model", result, {"adoption": Fraction(3, 5), "attempted_coverage": Fraction(3, 5),
                     "task_success_fraction": Fraction(2, 3), "cohort_task_success_rate": Fraction(6, 25),
                     "downloads_per_cohort_member": Fraction(12, 5)})
        self.check_packet_fields("PM009", result)
        self.assertLessEqual(data["task_success_in_attempted"], data["task_attempted_in_enabled_cohort"])
        self.assertLessEqual(data["task_attempted_in_enabled_cohort"], data["enabled_in_cohort"])
        self.assertLessEqual(data["enabled_in_cohort"], data["eligible_active_cohort"])
        mirror = dict(data, download_events=2 * data["download_events"])
        changed = adoption_ratios(mirror)
        unchanged = all(result[key] == changed[key] for key in result if key != "downloads_per_cohort_member")
        self.observe("PM009", "negative", {"download_events": mirror["download_events"], "cohort_ratios_unchanged": unchanged,
                     "downloads_per_cohort_member": changed["downloads_per_cohort_member"]},
                     {"download_events": 240, "cohort_ratios_unchanged": True, "downloads_per_cohort_member": Fraction(24, 5)})

    def test_all_localized_fixed_models_match_actual_typed_packet(self):
        self.assertEqual(len(COURSES), 16)
        for code, course in COURSES.items():
            for locale, relative in course["source_paths"].items():
                with self.subTest(code=code, locale=locale):
                    text = (ROOT / relative).read_text(encoding="utf-8")
                    match = re.search(r"```json\s*(.*?)\s*```", text, re.DOTALL)
                    self.assertIsNotNone(match)
                    self.assertEqual(json.loads(match.group(1)), course["authored_model"])
                    self.assertEqual(len(re.findall(r"<summary>", text)), 5)
            self.assertEqual(len(course["learner_criteria"]), 5)
            self.assertTrue(all(row["decision"] is None for row in course["learner_criteria"]))


if __name__ == "__main__":
    unittest.main()
