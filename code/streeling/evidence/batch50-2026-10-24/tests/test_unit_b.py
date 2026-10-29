"""Independent finite-case checks for the actual batch50 unit B packet.

Only stdlib is used. Fixed expectations below were derived independently;
the packet's expected fields are an additional consistency check.
"""
import cmath
import copy
from fractions import Fraction as F
import itertools
import json
import math
from pathlib import Path
import sys
import unittest

PACKET = Path(__file__).resolve().parents[1] / "unit-b.json"


def rational(value):
    return F(str(value))


def serial(value):
    if isinstance(value, F):
        return int(value) if value.denominator == 1 else float(value)
    if isinstance(value, dict):
        return {k: serial(v) for k, v in value.items()}
    if isinstance(value, (tuple, list)):
        return [serial(v) for v in value]
    return value


def merge(left, right):
    return {k: left.get(k, set()) | right.get(k, set())
            for k in left.keys() | right.keys()}


def message_state(messages):
    state = {}
    for item in messages:
        state = merge(state, {item["id"]: {item["value"]}})
    return state


def before(a, b):
    return all(x <= y for x, y in zip(a, b)) and a != b


def compute(code, v):
    """Evaluate the declared operation from inputs, never from expected output."""
    if code == "CS018":
        state = merge({k: {x} for k, x in v["initial"].items()}, message_state(v["messages"]))
        conflict = any(len(values) > 1 for values in state.values())
        return dict(unique_count=len(state), sum=None if conflict else sum(next(iter(x)) for x in state.values()), conflict=conflict)
    if code == "CS019":
        local = v["argument"] + v["local_increment"]
        return dict(lexical_result=local + v["outer_x"], captured_result=2 * local, renamed_result=local + v["outer_x"])
    if code == "CS020":
        pairs = [(a, b) for a in v["left"] for b in v["right"] if a["artifact"] == b["artifact"]]
        counts = {}
        for a, _ in pairs:
            counts[a["artifact"]] = counts.get(a["artifact"], 0) + 1
        return dict(joined_rows=len(pairs), distinct_artifacts=len(counts), rows_per_artifact=counts)
    if code == "CYB012":
        g = rational(v["gain"])
        old, current = rational(v["initial_previous"]), rational(v["initial_current"])
        trace = [current]
        for _ in range(v["steps"]):
            old, current = current, current - g * old
            trace.append(current)
        roots = [(1 + sign * cmath.sqrt(1 - 4 * float(g))) / 2 for sign in [-1, 1]]
        modulus = max(abs(root) for root in roots)
        return serial(dict(trace_from_k0=trace, root_modulus=modulus, asymptotically_stable=modulus < 1 - 1e-12))
    if code == "CYB013":
        age = rational(v["now_seconds"]) - rational(v["observed_at_seconds"])
        radius = rational(v["max_change_per_second"]) * age
        low, high = rational(v["observed_value"]) - radius, rational(v["observed_value"]) + radius
        return serial(dict(age_seconds=age, radius=radius, interval=[low, high], safe_certified=high <= rational(v["upper_limit"])))
    if code == "CYB014":
        x, step, band = (rational(v[k]) for k in ["initial_error", "action_step", "deadband"])
        trace, actions = [x], 0
        for _ in range(v["updates"]):
            if abs(x) > band:
                x -= step * (1 if x > 0 else -1)
                actions += 1
            trace.append(x)
        return serial(dict(trace=trace, final_error=x, action_count=actions))
    if code == "COG012":
        tp, fn, fp, tn = (v[k] for k in ["true_positive", "false_negative", "false_positive", "true_negative"])
        n = tp + fn + fp + tn
        hit, false = F(tp, tp + fn), F(fp, fp + tn)
        return serial(dict(hit_rate=hit, false_alarm_rate=false, alert_rate=F(tp + fp, n), accuracy=F(tp + tn, n), separation=hit - false))
    if code == "COG013":
        manual, assisted = v["manual_miss"], v["assisted_miss"]
        pairs = list(zip(v["item_ids"], manual, assisted))
        n = len(pairs)
        return serial(dict(manual_miss_rate=F(sum(manual), n), assisted_miss_rate=F(sum(assisted), n), paired_excess=F(sum(assisted) - sum(manual), n), assisted_only_misses=[i for i, m, a in pairs if a and not m], manual_only_misses=[i for i, m, a in pairs if m and not a]))
    if code == "COG014":
        indices = [i for i, confidence in enumerate(v["confidence"]) if confidence >= v["threshold"]]
        errors = sum(1 - v["correct"][i] for i in indices)
        return serial(dict(accepted_indices=indices, accepted=len(indices), errors=errors, coverage=F(len(indices), len(v["confidence"])), risk=F(errors, len(indices)) if indices else None))
    if code == "INF013":
        groups = {}
        for probability, outcome in zip(v["probabilities"], v["probe_outcomes"]):
            groups.setdefault(outcome, []).append(rational(probability))
        def entropy(ps):
            return -sum(float(p) * math.log2(float(p)) for p in ps if p)
        prior = entropy([rational(p) for p in v["probabilities"]])
        posterior = sum(float(sum(ps)) * entropy([p / sum(ps) for p in ps]) for ps in groups.values())
        return serial(dict(prior_bits=prior, expected_posterior_bits=posterior, information_gain_bits=prior - posterior, outcome_probabilities={k: sum(ps) for k, ps in groups.items()}))
    if code == "INF014":
        intended = [v["codebooks"][v["sent_version"]][str(t)] for t in v["tags"]]
        received = [v["codebooks"][v["decoded_version"]][str(t)] for t in v["tags"]]
        return dict(intended=intended, received=received, mismatches=sum(a != b for a, b in zip(intended, received)))
    if code == "INF015":
        weights = [1 / rational(p) for p in v["inclusion_probabilities"]]
        total = sum(weights)
        failures = sum(w * f for w, f in zip(weights, v["sampled_failures"]))
        return serial(dict(weights=weights, adjusted_total=total, adjusted_failures=failures, weighted_ratio=failures / total, raw_rate=F(sum(v["sampled_failures"]), len(weights))))
    if code == "NET012":
        s, a, b = (rational(v[k]) for k in ["shared_success", "branch_a_success_given_shared", "branch_b_success_given_shared"])
        # Disjoint conditional cases: A succeeds, or A fails and B succeeds.
        union = a + (1 - a) * b
        ma, mb = s * a, s * b
        return serial(dict(conditional_branch_union=union, success=s * union, marginal_a=ma, marginal_b=mb, naive_independent=ma + (1 - ma) * mb))
    if code == "NET013":
        a, b = v["a"], v["b"]
        receive = [max(x, y) for x, y in zip(v["receiver_local"], v["incoming"])]
        receive[v["receiver_index"]] += 1
        ab, ba = before(a, b), before(b, a)
        return dict(a_before_b=ab, b_before_a=ba, concurrent=not ab and not ba and a != b, receive_clock=receive, a_before_receive=before(a, receive))
    if code == "PM010":
        rates = [F(f, n) for f, n in zip(v["failures"], v["attempts"])]
        return serial(dict(stratum_rates=rates, pooled_rate=F(sum(v["failures"]), sum(v["attempts"])), standardized_rate=sum(rational(w) * r for w, r in zip(v["target_weights"], rates))))
    if code == "PM011":
        n = v["items"]
        per_item = rational(v["draft_minutes_per_item"]) + rational(v["review_minutes_per_item"]) + rational(v["correction_probability"]) * rational(v["correction_minutes_if_needed"])
        manual = rational(v["manual_minutes_per_item"]) * n
        automated = rational(v["setup_minutes"]) + per_item * n
        saving_per_item = rational(v["manual_minutes_per_item"]) - per_item
        equality = rational(v["setup_minutes"]) / saving_per_item if saving_per_item > 0 else None
        return serial(dict(automated_minutes_per_item=per_item, manual_total_minutes=manual, automated_total_minutes=automated, net_saved_minutes=manual - automated, equal_cost_items=equality, minimum_integer_items_for_strict_saving=math.floor(equality) + 1 if equality is not None else None))
    raise ValueError(code)


# Literals are fixed independent calculations, including the negative controls.
FIXED = {
    "CS018": [dict(unique_count=2, sum=8, conflict=False), dict(unique_count=2, sum=None, conflict=True)],
    "CS019": [dict(lexical_result=14, captured_result=8, renamed_result=14), dict(lexical_result=8, captured_result=8, renamed_result=8)],
    "CS020": [dict(joined_rows=5, distinct_artifacts=2, rows_per_artifact={"a": 4, "b": 1}), dict(joined_rows=3, distinct_artifacts=2, rows_per_artifact={"a": 2, "b": 1})],
    "CYB012": [dict(trace_from_k0=[1, .5, 0, -.25, -.25, -.125, 0], root_modulus=math.sqrt(.5), asymptotically_stable=True), dict(trace_from_k0=[1, 0, -1, -1, 0, 1, 1], root_modulus=1, asymptotically_stable=False)],
    "CYB013": [dict(age_seconds=4, radius=2, interval=[2, 6], safe_certified=False), dict(age_seconds=1, radius=.5, interval=[3.5, 4.5], safe_certified=True)],
    "CYB014": [dict(trace=[.6, -.4, -.4, -.4, -.4], final_error=-.4, action_count=1), dict(trace=[.6, -.4, .6, -.4, .6], final_error=.6, action_count=4)],
    "COG012": [dict(hit_rate=.8, false_alarm_rate=.4, alert_rate=.6, accuracy=.7, separation=.4), dict(hit_rate=1, false_alarm_rate=1, alert_rate=1, accuracy=.5, separation=0)],
    "COG013": [dict(manual_miss_rate=.25, assisted_miss_rate=.75, paired_excess=.5, assisted_only_misses=["b", "c"], manual_only_misses=[]), dict(manual_miss_rate=.25, assisted_miss_rate=.25, paired_excess=0, assisted_only_misses=[], manual_only_misses=[])],
    "COG014": [dict(accepted_indices=[0, 1, 2], accepted=3, errors=1, coverage=.6, risk=1/3), dict(accepted_indices=[], accepted=0, errors=0, coverage=0, risk=None)],
    "INF013": [dict(prior_bits=2, expected_posterior_bits=1, information_gain_bits=1, outcome_probabilities={"left": .5, "right": .5}), dict(prior_bits=2, expected_posterior_bits=2, information_gain_bits=0, outcome_probabilities={"same": 1})],
    "INF014": [dict(intended=["fail", "pass", "pass"], received=["pass", "fail", "fail"], mismatches=3), dict(intended=["fail", "pass", "pass"], received=["fail", "pass", "pass"], mismatches=0)],
    "INF015": [dict(weights=[2, 4, 4], adjusted_total=10, adjusted_failures=2, weighted_ratio=.2, raw_rate=1/3), dict(weights=[1, 1, 1], adjusted_total=3, adjusted_failures=1, weighted_ratio=1/3, raw_rate=1/3)],
    "NET012": [dict(conditional_branch_union=.98, success=.931, marginal_a=.76, marginal_b=.855, naive_independent=.9652), dict(conditional_branch_union=.98, success=.49, marginal_a=.4, marginal_b=.45, naive_independent=.67)],
    "NET013": [dict(a_before_b=False, b_before_a=False, concurrent=True, receive_clock=[2, 4], a_before_receive=True), dict(a_before_b=True, b_before_a=False, concurrent=False, receive_clock=[3, 2], a_before_receive=True)],
    "PM010": [dict(stratum_rates=[.1, .4], pooled_rate=.175, standardized_rate=.13), dict(stratum_rates=[.1, .4], pooled_rate=.13, standardized_rate=.13)],
    "PM011": [dict(automated_minutes_per_item=10, manual_total_minutes=480, automated_total_minutes=460, net_saved_minutes=20, equal_cost_items=30, minimum_integer_items_for_strict_saving=31), dict(automated_minutes_per_item=12, manual_total_minutes=480, automated_total_minutes=540, net_saved_minutes=-60, equal_cost_items=None, minimum_integer_items_for_strict_saving=None)],
}

SCOPES = {
    "CS018": "Authored three-message identity merge, pointwise payload-set union; no transport execution.",
    "CS019": "One stipulated local binding/free outer reference; arithmetic is not a parser or hygiene proof.",
    "CS020": "Authored equality inner join with bag semantics and simplified artifact key.",
    "CYB012": "Six updates with exactly one-update delay and exact rational state; roots of the specified scalar linear recurrence, not fleet stability.",
    "CYB013": "Exact sample on one monotonic clock and assumed absolute rate bound; certificate is not a measurement.",
    "CYB014": "Four noiseless fixed-step actions with exact decimals and strict deadband comparison.",
    "COG012": "Authored external-key confusion counts; conditional rates are not psychological sensitivity.",
    "COG013": "Four paired invented catch items with retained identities; no participant or causal effect.",
    "COG014": "Five fixed eligible items, inclusive confidence threshold, null empty conditional risk.",
    "INF013": "Four uniform authored hypotheses, deterministic error-free probe partition; bits are not utility.",
    "INF014": "Two stipulated bijective codebooks, three ordered tags and no channel errors.",
    "INF015": "Three retained events with supplied positive inclusion probabilities; estimated ratio not exact population rate.",
    "NET012": "Two conditionally independent branches and one necessary shared dependency; invented probabilities.",
    "NET013": "Two-component clocks under complete modeled communication and stable node ordering.",
    "PM010": "Two authored task strata with fixed target weights; no observed user distribution.",
    "PM011": "Invented expected active-work minutes with mandatory review and one setup charge; comparable quality assumed.",
}


def assert_matches(observed, expected, path="result"):
    if isinstance(expected, dict):
        assert isinstance(observed, dict) and observed.keys() == expected.keys(), path
        for key in expected:
            assert_matches(observed[key], expected[key], path + "." + key)
    elif isinstance(expected, list):
        assert isinstance(observed, list) and len(observed) == len(expected), path
        for i, (a, b) in enumerate(zip(observed, expected)):
            assert_matches(a, b, f"{path}[{i}]")
    elif isinstance(expected, bool) or expected is None:
        assert observed is expected, (path, observed, expected)
    elif isinstance(expected, (int, float)):
        assert not isinstance(observed, bool) and math.isclose(observed, expected, rel_tol=1e-12, abs_tol=1e-12), (path, observed, expected)
    else:
        assert observed == expected, (path, observed, expected)


def check_course(code, course):
    model = course["authored_model"]
    for index, (case, data) in enumerate([("model", model), ("negative", model["negative_control"])]):
        observation = compute(code, data["values"])
        print("OBSERVATION " + json.dumps(dict(code=code, case=case, observed=observation, expected=FIXED[code][index], scope=SCOPES[code]), sort_keys=True), flush=True)
        assert_matches(observation, FIXED[code][index])
        assert_matches(observation, data["expected"])
    if code == "CS018":
        for data in [model, model["negative_control"]]:
            parts = [message_state([m]) for m in data["values"]["messages"]]
            a, b, c = parts
            assert merge(merge(a, b), c) == merge(a, merge(b, c))
            state = message_state(data["values"]["messages"])
            assert merge(state, state) == state
            for order in itertools.permutations(parts):
                assert merge(merge(order[0], order[1]), order[2]) == state
            if data is model["negative_control"]:
                assert merge(state, a)["a"] == {3, 4}
    if code == "CYB012":
        assert model["values"]["delay_updates"] == 1
        assert model["negative_control"]["values"]["delay_updates"] == 1
        # Boundary/branch examples audit the newly stated analytical interval;
        # this finite list is not a proof over arbitrary gains.
        for gain, stable in [(0, False), (.1, True), (.25, True), (.5, True), (1, False), (1.6, False), (-.1, False)]:
            roots = [(1 + sign * cmath.sqrt(1 - 4 * gain)) / 2 for sign in [-1, 1]]
            assert (max(map(abs, roots)) < 1 - 1e-12) is stable
    if code == "COG014":
        lower = copy.deepcopy(model["values"])
        lower["threshold"] = .4
        assert_matches(compute(code, lower), dict(accepted_indices=[0, 1, 2, 3, 4], accepted=5, errors=2, coverage=1, risk=.4))


class UnitB(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.courses = {c["code"]: c for c in json.loads(PACKET.read_text(encoding="utf-8"))["courses"]}


def make_test(code):
    def test(self):
        check_course(code, self.courses[code])
    return test


for course_code in FIXED:
    setattr(UnitB, "test_" + course_code.lower(), make_test(course_code))


def mutation_probe():
    courses = {c["code"]: c for c in json.loads(PACKET.read_text(encoding="utf-8"))["courses"]}
    altered = copy.deepcopy(courses["COG012"])
    altered["authored_model"]["values"]["false_positive"] = 0
    try:
        check_course("COG012", altered)
    except AssertionError as exc:
        print("MUTATION_REJECTED " + json.dumps(dict(code="COG012", mutation="false_positive 4 -> 0 in a deep copy; fixed expected fields retained", reason=str(exc), canonical_packet_unchanged=True)), flush=True)
        return
    raise AssertionError("Substantive incorrect in-memory input was accepted")


if __name__ == "__main__":
    if "--mutation-probe" in sys.argv:
        mutation_probe()
    else:
        unittest.main(verbosity=2)
