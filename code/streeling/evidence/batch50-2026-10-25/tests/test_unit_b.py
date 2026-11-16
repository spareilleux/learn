"""Independent exact finite-case characterization; no application behavior changes.

Evaluate packet values, compare to independently derived literals, then compare
to the packet. These checks do not observe a production system or learner.
"""
import copy
from fractions import Fraction as Q
import itertools
import json
import math
from pathlib import Path
import sys
import unittest

PACKET = Path(__file__).resolve().parents[1] / "unit-b.json"


def require(condition, diagnostic):
    if not condition:
        print("DIAGNOSTIC " + json.dumps(diagnostic, ensure_ascii=False), flush=True)
        raise AssertionError(diagnostic)


def q(value):
    require(type(value) in (int, float) and math.isfinite(value), {"invalid_finite_number": value})
    return Q(str(value))


def serial(value):
    if isinstance(value, Q):
        return int(value) if value.denominator == 1 else float(value)
    if isinstance(value, dict):
        return {k: serial(v) for k, v in value.items()}
    if isinstance(value, (tuple, list)):
        return [serial(v) for v in value]
    return value


def graph(v, capacity=False):
    nodes, edges = v["nodes"], v["edges"]
    require(isinstance(nodes, list) and len(nodes) == len(set(nodes)), {"unique_nodes_required": nodes})
    require(all(isinstance(n, str) for n in nodes), {"string_nodes_required": nodes})
    size = 3 if capacity else 2
    require(all(isinstance(e, list) and len(e) == size for e in edges), {"edge_width_required": size, "edges": edges})
    require(all(e[0] in nodes and e[1] in nodes for e in edges), {"unknown_edge_endpoint": edges})
    require(len({tuple(e[:2]) for e in edges}) == len(edges), {"unique_edges_required": edges})
    return nodes, edges


def compute(code, v):
    if code == "CS021":
        require(all(type(v[k]) is int for k in ("sample_rate_hz", "channels", "frames")), {"integer_fields_required": v})
        errors = []
        if v["sample_rate_hz"] <= 0:
            errors.append("sample_rate_hz")
        if v["channels"] not in (1, 2):
            errors.append("channels")
        if v["frames"] < 0:
            errors.append("frames")
        return dict(errors=errors, error_count=len(errors), accepted=not errors)
    if code == "CS022":
        a, b = v["a"], v["b"]
        require(all(isinstance(stage[k], list) and all(isinstance(x, str) for x in stage[k]) for stage in (a, b) for k in ("reads", "writes")), {"resource_name_sets_required": v})
        ra, wa, rb, wb = (set(stage[k]) for stage, k in ((a, "reads"), (a, "writes"), (b, "reads"), (b, "writes")))
        conflicts = sorted((wa & (rb | wb)) | (wb & (ra | wa)))
        return dict(conflicts=conflicts, independent=not conflicts)
    if code == "CS023":
        resources = v["resources"]
        require(isinstance(resources, list) and len(set(resources)) == len(resources) and all(isinstance(x, str) for x in resources), {"unique_resource_list_required": resources})
        require(v["fail_acquire"] is None or v["fail_acquire"] in resources, {"unknown_failed_acquisition": v["fail_acquire"]})
        require(type(v["work_error"]) is bool, {"boolean_work_error_required": v})
        acquired = []
        for resource in resources:
            if resource == v["fail_acquire"]:
                outcome = "acquire_error"
                break
            acquired.append(resource)
        else:
            outcome = "work_error" if v["work_error"] else "ok"
        return dict(acquired=acquired, released=acquired[::-1], outcome=outcome)
    if code == "CYB015":
        cov = v["error_covariance"]
        require(isinstance(cov, list) and len(cov) == 2 and all(isinstance(row, list) and len(row) == 2 for row in cov), {"covariance_shape_required": "2x2", "observed": cov})
        c = [[q(x) for x in row] for row in cov]
        require(c[0][1] == c[1][0] and c[0][0] >= 0 and c[1][1] >= 0 and c[0][0]*c[1][1] >= c[0][1]**2, {"symmetric_psd_covariance_required": cov})
        alpha = q(v["alpha"])
        require(0 < alpha <= 1, {"alpha_out_of_range": v["alpha"]})
        weights = [alpha*(1-alpha), alpha]
        expected = sum(weights)*q(v["true_level"]) + (1-alpha)**2*q(v["initial"])
        variance = sum(weights[i]*c[i][j]*weights[j] for i in range(2) for j in range(2))
        return serial(dict(weights=weights, expected_level=expected, bias=expected-q(v["true_level"]), variance=variance))
    if code == "CYB016":
        target, gain, disturbance, measured, assumed = (q(v[k]) for k in ("target", "plant_gain", "disturbance", "measured_disturbance", "assumed_gain"))
        require(gain > 0 and assumed > 0, {"positive_gains_required": v})
        baseline, command = target/assumed, (target-measured)/assumed
        baseline_output, output = gain*baseline+disturbance, gain*command+disturbance
        return serial(dict(baseline_command=baseline, baseline_output=baseline_output, baseline_error=baseline_output-target, command=command, output=output, error=output-target))
    if code == "CYB017":
        lower, upper, prev, rate, dt = (q(v[k]) for k in ("lower", "upper", "initial_command", "rate_per_second", "dt_seconds"))
        require(lower <= prev <= upper and rate >= 0 and dt > 0, {"invalid_command_bounds_or_time": v})
        require(isinstance(v["requests"], list) and bool(v["requests"]), {"nonempty_request_list_required": v})
        amplitudes, commands, deltas = [], [], []
        for request in v["requests"]:
            amplitude = min(upper, max(lower, q(request)))
            command = min(prev+rate*dt, max(prev-rate*dt, amplitude))
            amplitudes.append(amplitude)
            commands.append(command)
            deltas.append(command-prev)
            prev = command
        return serial(dict(amplitude_only=amplitudes, commands=commands, deltas=deltas, final=prev))
    if code == "COG015":
        n = v["items"]
        prevalence, hit, false = (q(v[k]) for k in ("prevalence", "hit_rate", "false_alarm_rate"))
        require(type(n) is int and n > 0 and all(0 <= x <= 1 for x in (prevalence, hit, false)), {"invalid_population_or_probability": v})
        tp, fp = n*prevalence*hit, n*(1-prevalence)*false
        require(tp+fp > 0, {"undefined_empty_alert_precision": v})
        return serial(dict(true_positives=tp, false_positives=fp, alerts=tp+fp, precision=tp/(tp+fp)))
    if code == "COG016":
        n, successes, missing, cs, cn = (v[k] for k in ("offered", "observed_successes", "missing", "comparison_successes", "comparison_offered"))
        require(all(type(x) is int for x in (n, successes, missing, cs, cn)) and n > 0 and cn > 0 and 0 <= missing <= n and 0 <= successes <= n-missing and 0 <= cs <= cn, {"invalid_offer_counts": v})
        comparison = Q(cs, cn)
        feasible = [k for k in range(missing+1) if Q(successes+k, n) > comparison]
        return serial(dict(lower=Q(successes, n), upper=Q(successes+missing, n), comparison_rate=comparison, minimum_missing_successes_for_strict_superiority=min(feasible) if feasible else None, identified_strict_superiority=Q(successes, n) > comparison))
    if code == "COG017":
        ab, aa, cb, ca = (q(v[k]) for k in ("assisted_before", "assisted_after", "comparison_before", "comparison_after"))
        require(all(0 <= x <= 1 for x in (ab, aa, cb, ca)), {"proportions_required": v})
        return serial(dict(assisted_change=aa-ab, comparison_change=ca-cb, contrast=(aa-ab)-(ca-cb)))
    if code == "INF016":
        require(all(type(v[k]) is int for k in ("sender_base", "target", "receiver_base")), {"exact_integer_states_required": v})
        require(all(isinstance(v[k], str) for k in ("sender_base_id", "receiver_base_id")), {"base_id_strings_required": v})
        accepted = v["sender_base_id"] == v["receiver_base_id"]
        require(not accepted or v["sender_base"] == v["receiver_base"], {"trusted_immutable_identity_premise_violated": v})
        delta = v["target"]-v["sender_base"]
        naive = v["receiver_base"]+delta
        return dict(delta=delta, naive_reconstruction=naive, accepted=accepted, guarded_reconstruction=naive if accepted else None)
    if code == "INF017":
        partitions = v["partitions"]
        require(isinstance(partitions, list) and all(isinstance(p, list) for p in partitions), {"nested_partitions_required": partitions})
        summaries = [[sum((q(x) for x in p), Q(0)), len(p)] for p in partitions]
        total, count = sum(p[0] for p in summaries), sum(p[1] for p in summaries)
        means = [s/Q(n) for s, n in summaries if n]
        return serial(dict(summaries=summaries, merged=[total, count], mean=total/count if count else None, naive_mean=sum(means)/len(means) if means else None))
    if code == "INF018":
        messages, lengths = v["messages"], v["declared_lengths"]
        require(isinstance(messages, list) and isinstance(lengths, list) and len(messages) == len(lengths), {"paired_length_mismatch": [len(messages), len(lengths)]})
        require(all(isinstance(s, str) for s in messages) and all(type(n) is int and n >= 0 for n in lengths), {"invalid_framing_types": v})
        actual = [len(s.encode("utf-8")) for s in messages]
        valid = lengths == actual
        frame = "".join(str(lengths[i])+":"+messages[i] for i in range(len(messages))) if valid else None
        return dict(actual_lengths=actual, valid=valid, frame=frame, naive_delimited="|".join(messages))
    if code == "NET014":
        nodes, edges = graph(v, capacity=True)
        source, sink = v["source"], v["sink"]
        require(source in nodes and sink in nodes and source != sink, {"invalid_terminals": v})
        require(all(type(e[2]) is int and e[2] >= 0 for e in edges), {"finite_integer_capacity_case_required": edges})
        require(not any(b == source or a == sink for a, b, _ in edges), {"finite_case_terminal_orientation": edges})
        middle = [n for n in nodes if n not in (source, sink)]
        feasible = []
        for flow in itertools.product(*(range(e[2]+1) for e in edges)):
            balances = {n: 0 for n in nodes}
            for i, (a, b, _) in enumerate(edges):
                balances[a] -= flow[i]
                balances[b] += flow[i]
            if all(balances[n] == 0 for n in middle):
                feasible.append(-balances[source])
        cuts = []
        for bits in itertools.product((False, True), repeat=len(middle)):
            left = {source} | {middle[i] for i in range(len(middle)) if bits[i]}
            cuts.append(sum(cap for a, b, cap in edges if a in left and b not in left))
        def routes(node, visited):
            if node == sink:
                return 1
            return sum(routes(b, visited | {b}) for a, b, _ in edges if a == node and b not in visited)
        # Feasible integer flow plus equal cut also proves this divisible-flow bound.
        require(max(feasible) == min(cuts), {"flow_cut_disagreement": [max(feasible), min(cuts)]})
        return dict(maximum_flow=max(feasible), minimum_cut_capacity=min(cuts), sink_cut_capacity=sum(cap for _, b, cap in edges if b == sink), simple_path_count=routes(source, {source}))
    if code == "NET015":
        nodes, edges = graph(v)
        require(all(len(n) == 1 for n in nodes), {"single_letter_component_labels_required": nodes})
        reach = {(a, b): a == b or [a, b] in edges for a in nodes for b in nodes}
        for k in nodes:
            for a in nodes:
                for b in nodes:
                    reach[a, b] = reach[a, b] or (reach[a, k] and reach[k, b])
        components = sorted({tuple(sorted(b for b in nodes if reach[a, b] and reach[b, a])) for a in nodes})
        label = {n: "".join(group) for group in components for n in group}
        condensed = sorted({(label[a], label[b]) for a, b in edges if label[a] != label[b]})
        return serial(dict(components=components, component_count=len(components), condensed_edges=condensed, condensed_edge_count=len(condensed)))
    if code == "PM012":
        jobs, durations, weights, baseline = (v[k] for k in ("jobs", "duration_ticks", "weight_per_tick", "baseline_order"))
        require(isinstance(jobs, list) and bool(jobs) and len(set(jobs)) == len(jobs) and all(isinstance(j, str) for j in jobs), {"unique_jobs_required": jobs})
        require(set(durations) == set(weights) == set(jobs) and len(baseline) == len(jobs) and set(baseline) == set(jobs), {"job_keys_or_permutation_mismatch": v})
        require(all(type(durations[j]) is int and durations[j] > 0 and q(weights[j]) >= 0 for j in jobs), {"invalid_duration_or_weight": v})
        def score(order):
            elapsed, completion, cost = 0, {}, Q(0)
            for job in order:
                elapsed += durations[job]
                completion[job] = elapsed
                cost += q(weights[job])*elapsed
            return cost, completion, elapsed
        order = min(itertools.permutations(jobs), key=lambda o: (score(o)[0], o))
        cost, completion, makespan = score(order)
        return serial(dict(optimal_order=order, optimal_completion=completion, optimal_cost=cost, baseline_cost=score(baseline)[0], makespan=makespan))
    if code == "PM013":
        followup, flags, horizon = v["followup_days"], v["event"], q(v["horizon_days"])
        require(isinstance(followup, list) and isinstance(flags, list) and len(followup) == len(flags) and bool(followup), {"followup_event_length_mismatch": [len(followup), len(flags)]})
        times = [q(t) for t in followup]
        require(horizon > 0 and all(t > 0 for t in times) and all(type(e) is int and e in (0, 1) for e in flags), {"invalid_followup_or_event": v})
        events = [times[i] for i in range(len(times)) if flags[i]]
        require(len(events) == len(set(events)), {"distinct_event_times_required": followup})
        event_times = sorted(t for t in events if t <= horizon)
        risks, survivals, survival = [], [], Q(1)
        for t in event_times:
            risk = sum(x >= t for x in times)
            failures = sum(times[i] == t and flags[i] == 1 for i in range(len(times)))
            survival *= Q(risk-failures, risk)
            risks.append(risk)
            survivals.append(survival)
        return serial(dict(event_times=event_times, risk_sets=risks, survival=survivals, cumulative_first_use=1-survival, raw_event_fraction=Q(sum(flags), len(flags))))
    raise ValueError(code)


# Independent oracles: exact arithmetic by hand, exhaustive cuts/orders or
# mutual-reachability classes. Packet fields are never used to produce these.
FIXED = {
    "CS021": [dict(errors=["sample_rate_hz", "channels", "frames"], error_count=3, accepted=False), dict(errors=[], error_count=0, accepted=True)],
    "CS022": [dict(conflicts=["manifest"], independent=False), dict(conflicts=[], independent=True)],
    "CS023": [dict(acquired=["input", "output"], released=["output", "input"], outcome="work_error"), dict(acquired=["input"], released=["input"], outcome="acquire_error")],
    "CYB015": [dict(weights=[.25, .5], expected_level=3, bias=-1, variance=1.75), dict(weights=[.25, .5], expected_level=3, bias=-1, variance=1.25)],
    "CYB016": [dict(baseline_command=5, baseline_output=14, baseline_error=4, command=3.5, output=11, error=1), dict(baseline_command=5, baseline_output=14, baseline_error=4, command=0, output=4, error=-6)],
    "CYB017": [dict(amplitude_only=[4,4,0], commands=[1,2,1], deltas=[1,1,-1], final=1), dict(amplitude_only=[4,4,0], commands=[4,4,0], deltas=[4,0,-4], final=0)],
    "COG015": [dict(true_positives=80, false_positives=90, alerts=170, precision=8/17), dict(true_positives=400, false_positives=50, alerts=450, precision=8/9)],
    "COG016": [dict(lower=.6, upper=1, comparison_rate=.7, minimum_missing_successes_for_strict_superiority=2, identified_strict_superiority=False), dict(lower=.6, upper=.6, comparison_rate=.7, minimum_missing_successes_for_strict_superiority=None, identified_strict_superiority=False)],
    "COG017": [dict(assisted_change=.3, comparison_change=.1, contrast=.2), dict(assisted_change=.3, comparison_change=.3, contrast=0)],
    "INF016": [dict(delta=3, naive_reconstruction=13, accepted=True, guarded_reconstruction=13), dict(delta=3, naive_reconstruction=23, accepted=False, guarded_reconstruction=None)],
    "INF017": [dict(summaries=[[2,1],[18,3]], merged=[20,4], mean=5, naive_mean=4), dict(summaries=[[6,2],[14,2]], merged=[20,4], mean=5, naive_mean=5)],
    "INF018": [dict(actual_lengths=[2,3], valid=True, frame="2:é3:A|B", naive_delimited="é|A|B"), dict(actual_lengths=[2,3], valid=False, frame=None, naive_delimited="é|A|B")],
    "NET014": [dict(maximum_flow=4, minimum_cut_capacity=4, sink_cut_capacity=4, simple_path_count=3), dict(maximum_flow=3, minimum_cut_capacity=3, sink_cut_capacity=3, simple_path_count=3)],
    "NET015": [dict(components=[["a","b"],["c","d"],["e"]], component_count=3, condensed_edges=[["ab","cd"],["cd","e"]], condensed_edge_count=2), dict(components=[["a","b","c","d","e"]], component_count=1, condensed_edges=[], condensed_edge_count=0)],
    "PM012": [dict(optimal_order=["B","A","C"], optimal_completion={"B":1,"A":5,"C":7}, optimal_cost=30, baseline_cost=38, makespan=7), dict(optimal_order=["A","B","C"], optimal_completion={"A":4,"B":5,"C":7}, optimal_cost=44, baseline_cost=44, makespan=7)],
    "PM013": [dict(event_times=[1,3], risk_sets=[4,2], survival=[.75,.375], cumulative_first_use=.625, raw_event_fraction=.5), dict(event_times=[1,3], risk_sets=[4,3], survival=[.75,.5], cumulative_first_use=.5, raw_event_fraction=.5)],
}

SCOPES = {
    "CS021": "Three pure independent integer field checks, ordered errors; no decoder effects.",
    "CS022": "Complete symbolic resource footprints, deterministic stages and no hidden effects.",
    "CS023": "Two nested symbolic acquisitions; successful cleanup, no rollback or crash recovery.",
    "CYB015": "Two initialized EWMA updates, zero-mean errors and stipulated symmetric PSD covariance; no feedback.",
    "CYB016": "Static scalar additive plant, separate estimate and actual disturbance; no feedback or tuning guarantee.",
    "CYB017": "Three commands, uniform time interval and independent amplitude/rate bounds; no actuator.",
    "COG015": "Expected class counts with fixed threshold and transported conditional rates; no observed reviewer.",
    "COG016": "Binary missing completions enumerated with strict crossing; descriptive sensitivity, no probability or causal effect.",
    "COG017": "Two-group two-period arithmetic; untreated parallel trends and causal benefit unverified.",
    "INF016": "Exact scalar delta with trusted immutable base identities; no authenticity or update authority.",
    "INF017": "Disjoint authored partitions, exact sum/count arithmetic; no median or population estimate.",
    "INF018": "Two valid Unicode payloads with declared UTF-8 byte lengths; no arbitrary-stream decoder.",
    "NET014": "Four-node directed finite capacity graph; feasible flow and matching cut, no actual worker throughput.",
    "NET015": "Five-node mutual reachability and condensation view; no resolved internal execution schedule.",
    "PM012": "Three available nonpreemptive jobs, one reviewer, all six orders; fictional cardinal delay weights.",
    "PM013": "Four exact first-use/censor histories and finite product limits; population censoring premise unverified.",
}


def assert_matches(observed, expected, path="result"):
    if isinstance(expected, dict):
        assert isinstance(observed, dict) and observed.keys() == expected.keys(), (path, observed, expected)
        for key in expected:
            assert_matches(observed[key], expected[key], path+"."+key)
    elif isinstance(expected, list):
        assert isinstance(observed, list) and len(observed) == len(expected), (path, observed, expected)
        for i in range(len(expected)):
            assert_matches(observed[i], expected[i], f"{path}[{i}]")
    elif isinstance(expected, bool) or expected is None:
        assert observed is expected, (path, observed, expected)
    elif isinstance(expected, (int, float)):
        assert type(observed) in (int, float) and math.isclose(observed, expected, rel_tol=1e-12, abs_tol=1e-12), (path, observed, expected)
    else:
        assert observed == expected, (path, observed, expected)


def check_course(code, course):
    model = course["authored_model"]
    for i, (case, data) in enumerate((("model", model), ("negative", model["negative_control"]))):
        observed = compute(code, data["values"])
        print("\nOBSERVATION " + json.dumps(dict(code=code, case=case, observed=observed, expected=FIXED[code][i], scope=SCOPES[code]), ensure_ascii=False, sort_keys=True), flush=True)
        assert_matches(observed, FIXED[code][i])
        assert_matches(observed, data["expected"])


class UnitB(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        rows = json.loads(PACKET.read_text(encoding="utf-8"))["courses"]
        require(len(rows) == len(FIXED) and len({c["code"] for c in rows}) == len(rows), {"assigned_course_count_or_identity_mismatch": len(rows)})
        cls.courses = {c["code"]: c for c in rows}
        require(set(cls.courses) == set(FIXED), {"assigned_course_codes_mismatch": sorted(cls.courses)})


def make_test(code):
    def test(self):
        check_course(code, self.courses[code])
    return test


for course_code in FIXED:
    setattr(UnitB, "test_"+course_code.lower(), make_test(course_code))


def mutation_probe():
    rows = json.loads(PACKET.read_text(encoding="utf-8"))["courses"]
    course = copy.deepcopy(next(c for c in rows if c["code"] == "CYB015"))
    before = copy.deepcopy(course["authored_model"])
    # Remove a substantial covariance contribution and tamper with the packet
    # expectation too. The independent 7/4 oracle must still reject it.
    course["authored_model"]["values"]["error_covariance"] = [[4,0],[0,4]]
    course["authored_model"]["expected"]["variance"] = 1.25
    print("MUTATION_INPUT " + json.dumps(dict(code="CYB015", before=before, after=course["authored_model"], canonical_mutated=False), ensure_ascii=False), flush=True)
    try:
        check_course("CYB015", course)
    except AssertionError as exc:
        print("MUTATION_REJECTED " + json.dumps(dict(code="CYB015", reason=str(exc), expectation_also_mutated=True, canonical_mutated=False)), flush=True)
        return
    raise AssertionError("Wrong covariance input and altered packet expectation were accepted")


if __name__ == "__main__":
    if "--mutation-probe" in sys.argv:
        mutation_probe()
    else:
        unittest.main(verbosity=2)
