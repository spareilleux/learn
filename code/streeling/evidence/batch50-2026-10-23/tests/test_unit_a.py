"""Independent arithmetic/policy checks of Unit A's authored fixed cases.

These tests read inputs from unit-a.json. Oracles below are manually derived
fractions, truth-table witnesses, or high-precision Decimal computations; no
packet expected field is used to calculate an observed result. This is neither
GA engine execution nor evidence of playing, listening, or learner performance.
"""

import json
import math
from decimal import Decimal, localcontext
from pathlib import Path
import unittest


PACKET_PATH = Path(__file__).resolve().parents[1] / "unit-a.json"
COURSES = {c["code"]: c for c in json.loads(PACKET_PATH.read_text(encoding="utf-8"))["courses"]}
SCOPE = "Authored fixed-data arithmetic/policy case only; no engine, player, listener, or learner execution."


def decimal_cents(numerator, denominator):
    """Separate high-precision oracle for the binary-float log2 calculation."""
    with localcontext() as context:
        context.prec = 50
        return float(Decimal(1200) * (Decimal(numerator) / Decimal(denominator)).ln() / Decimal(2).ln())


def prefix(values):
    starts, total = [], 0
    for value in values:
        starts.append(total)
        total += value
    return starts, total


def barre_conflicts(values):
    return [int(s) for s, fret in values["requested"].items()
            if values["lo"] <= int(s) <= values["hi"] and fret < values["barre_fret"]]


def evaluate(code, case, courses=None):
    """Return independently computed observations, oracle, and claimed outputs."""
    course = (COURSES if courses is None else courses)[code]
    model = course["authored_model"]
    main = model["values"]
    negative = case == "negative"
    fixed = model["negative_control_case"] if negative else model
    values = fixed["values"]
    claimed = fixed["expected"]

    if code == "AUD010":
        left, right = values["L"], values["R"]
        mono = [(l + r) / 2 for l, r in zip(left, right, strict=True)]
        observed = {"mono": mono, "E_mono": sum(x*x for x in mono)}
        oracle = {"mono": [1, -1, 1, -1] if negative else [0, 0, 0, 0], "E_mono": 4 if negative else 0}
        if not negative:
            observed.update(E_L=sum(x*x for x in left), E_R=sum(x*x for x in right), frames=len(left), scalar_samples=len(left)+len(right))
            oracle.update(E_L=4, E_R=4, frames=4, scalar_samples=8)

    elif code == "AUD011":
        n, b = values["N"], values["B"]
        samples = values["samples"] if negative else values["valid_samples"]
        counts = [min(b, n-start) for start in range(0, n, b)]
        capacity = len(counts)*b
        energy = sum(x*x for x in samples)
        observed = {"padding": capacity-n, "rms_valid": math.sqrt(energy/n)}
        if negative:
            observed.update(blocks=len(counts), rms_capacity=math.sqrt(energy/capacity))
            oracle = {"blocks": 2, "padding": 0, "rms_valid": 1, "rms_capacity": 1}
        else:
            observed.update(block_valid_counts=counts, duration_s=n/values["rate_Hz"], rms_padded=math.sqrt(energy/capacity), raw_valid_bytes=n*4,
                            capacity_bytes=capacity*4, capacity_duration_s=capacity/values["rate_Hz"])
            oracle = {"block_valid_counts": [4, 4, 2], "padding": 2, "duration_s": 1/100, "rms_valid": 1,
                      "rms_padded": math.sqrt(5/6), "raw_valid_bytes": 40, "capacity_bytes": 48, "capacity_duration_s": 3/250}

    elif code == "AUD012":
        signal = values["x"]
        linear = [x*w for x, w in zip(signal, main["linear"], strict=True)]
        root = [x*w for x, w in zip(signal, main["root"], strict=True)]
        el, er = sum(x*x for x in linear), sum(x*x for x in root)
        if negative:
            observed = {"linear_output": linear, "root_output": root, "both_energy": el}
            oracle = {"linear_output": [0, 0, 0], "root_output": [0, 0, 0], "both_energy": 0}
            observed["root_energy"] = er
            oracle["root_energy"] = 0
        else:
            original = sum(x*x for x in signal)
            observed = {"E_original": original, "E_linear": el, "E_root": er, "linear_fraction": el/original, "root_fraction": er/original}
            oracle = {"E_original": 3, "E_linear": 5/4, "E_root": 3/2, "linear_fraction": 5/12, "root_fraction": 1/2}

    elif code == "GAS009":
        fs, target = values["Fs_Hz"], values["target_Hz"]
        tolerance = main["tolerance_cents"]
        if negative:
            nearest = round(fs/target)
            frequency = fs/nearest
            cents = 1200*math.log2(frequency/target)
            observed = {"frequency_Hz": frequency, "cents": cents, "passes_5_cents": abs(cents) <= tolerance, "nearest_N": nearest}
            oracle = {"frequency_Hz": 2205/2, "cents": decimal_cents(2205, 2180), "passes_5_cents": False, "nearest_N": 40}
            ineffective = fixed["ineffective_control"]
            observed["ineffective_control_cents"] = 1200*math.log2((fs/round(fs/ineffective["target_Hz"]))/ineffective["target_Hz"])
            oracle["ineffective_control_cents"] = decimal_cents(441, 440)
        else:
            floor, nxt = values["N_floor"], values["N_next"]
            f, g = fs/floor, fs/nxt
            c, d = 1200*math.log2(f/target), 1200*math.log2(g/target)
            observed = {"ideal_delay": fs/target, "floor_Hz": f, "floor_cents": c, "next_Hz": g, "next_cents": d,
                        "passes_floor": abs(c) <= tolerance, "passes_next": abs(d) <= tolerance}
            oracle = {"ideal_delay": 441/10, "floor_Hz": 11025/11, "floor_cents": decimal_cents(441, 440),
                      "next_Hz": 980, "next_cents": decimal_cents(49, 50), "passes_floor": True, "passes_next": False}

    elif code == "GAS010":
        b, fundamental = values["B"], values["f_1_Hz"]
        partials = [n*fundamental*math.sqrt((1+b*n*n)/(1+b)) for n in values["n"]]
        observed = {"partials_Hz": partials}
        if negative:
            oracle = {"partials_Hz": [100, 200, 300]}
        else:
            # Exact squared ratios: (f2/200)^2=104/101, (f3/300)^2=109/101.
            with localcontext() as context:
                context.prec = 50
                oracle = {"partials_Hz": [100, float(Decimal(200)*(Decimal(104)/101).sqrt()), float(Decimal(300)*(Decimal(109)/101).sqrt())],
                          "B_zero_Hz": [100, 200, 300]}
            observed["B_zero_Hz"] = [n*fundamental for n in values["n"]]

    elif code == "GAS011":
        incident = values["incident_mm"]
        reflection = values["reflection"] if negative else values["fixed_reflection"]
        reflected = incident*reflection
        boundary = incident+reflected
        observed = {"reflected_mm": reflected, "boundary_mm": boundary}
        if negative:
            observed["fixed_boundary_satisfied"] = boundary == 0
            oracle = {"reflected_mm": 1/5, "boundary_mm": 2/5, "fixed_boundary_satisfied": False}
        else:
            observed["round_trip"] = values["left"]*values["right"]
            oracle = {"reflected_mm": -1/5, "boundary_mm": 0, "round_trip": 1}

    elif code == "GTR009":
        available = values["gap_beats"]*60000/values["quarter_BPM"]
        # Derive the required time from stage inputs even for the control.
        required = main["release_ms"]+main["distance_frets"]*main["cost_ms_per_fret"]+main["prepare_ms"]
        if negative:
            observed = {"available_ms": available, "deficit_ms": required-available, "fits": available >= required}
            oracle = {"available_ms": 500/3, "deficit_ms": 160/3, "fits": False}
        else:
            observed = {"available_ms": available, "required_ms": required, "slack_ms": available-required,
                        "at_180_slack_ms": values["gap_beats"]*60000/180-required}
            oracle = {"available_ms": 250, "required_ms": 220, "slack_ms": 30, "at_180_slack_ms": -160/3}

    elif code == "GTR010":
        # A symbolic event changes state; it does not measure acoustic amplitude.
        events = [(values["release_beat"], "release")]
        if values["damp_beat"] is not None:
            events.append((values["damp_beat"], "damp"))
        state = "fretted"
        trace = []
        for beat, action in sorted(events):
            state = "muted_in_model" if action == "damp" else "unfretted_not_verified_silent"
            trace.append([beat, state])
        if negative:
            observed = {"state": state, "silence_verified": False, "event_trace": trace}
            oracle = {"state": "unfretted_not_verified_silent", "silence_verified": False,
                      "event_trace": [[1, "unfretted_not_verified_silent"]]}
        else:
            observed = {"possible_open_midi": values["fretted_midi"]-values["fret"],
                        "unverified_interval_beats": values["damp_beat"]-values["release_beat"],
                        "silent_measurement": None, "event_trace": trace}
            oracle = {"possible_open_midi": 64, "unverified_interval_beats": 1/4, "silent_measurement": None,
                      "event_trace": [[1, "unfretted_not_verified_silent"], [1.25, "muted_in_model"]]}

    elif code == "GTR011":
        conflicts = barre_conflicts(values)
        observed = {"conflicts": conflicts}
        if negative:
            observed.update(coverage_check_passes=not conflicts, playability=None)
            oracle = {"conflicts": [], "coverage_check_passes": True, "playability": None}
        else:
            observed["covered"] = list(range(values["lo"], values["hi"]+1))
            oracle = {"covered": [1, 2, 3], "conflicts": [2]}

    elif code == "GAA008":
        due = main["last_day"]+main["interval_days"]
        if negative:
            outcome = values["outcome"]
            updated = None if outcome is None else values["now_day"]+(min(2*main["interval_days"],main["cap_days"]) if outcome else 1)
            observed = {"is_due": values["now_day"] >= due, "updated_due": updated, "missing_branch_witness": outcome is None}
            oracle = {"is_due": False, "updated_due": None, "missing_branch_witness": True}
        else:
            interval = min(2*values["interval_days"], values["cap_days"])
            observed = {"due_day": due, "due_inclusive": values["now_day"] >= due, "success_interval": interval,
                        "success_due": values["now_day"]+interval, "failure_due": values["now_day"]+1, "missing_outcome_next_due": None}
            oracle = {"due_day": 14, "due_inclusive": True, "success_interval": 8, "success_due": 22, "failure_due": 15, "missing_outcome_next_due": None}

    elif code == "GAA009":
        target = [n+main["offset"] for n in main["source"]]
        control = model["negative_control_case"]["values"]
        if negative:
            candidate, octave = values["candidate"], values["octave_candidate"]
            observed = {"candidate_intervals": [n-candidate[0] for n in candidate], "target_pass": candidate == target,
                        "octave_absolute_pass": octave == target, "octave_pitch_class_pass": [n%12 for n in octave] == [n%12 for n in target]}
            oracle = {"candidate_intervals": [0, 3, 7], "target_pass": False, "octave_absolute_pass": False, "octave_pitch_class_pass": True}
        else:
            observed = {"target": target, "intervals": [n-target[0] for n in target], "wrong": control["candidate"], "octave_control": control["octave_candidate"]}
            oracle = {"target": [62, 66, 69], "intervals": [0, 4, 7], "wrong": [62, 65, 69], "octave_control": [74, 78, 81]}

    elif code == "GAA010":
        attempts = main["attempts"]
        strict = [a["id"] for a in attempts if a["notes"] and abs(a["error_ms"]) <= 50 and not a["assisted"]]
        notes = [a["id"] for a in attempts if a["notes"]]
        if negative:
            observed = {"accepted": notes, "count": len(notes), "rate": len(notes)/len(attempts), "matches_declared_endpoint": notes == strict,
                        "false_accept_witnesses": [i for i in notes if i not in strict]}
            oracle = {"accepted": ["A", "B", "D"], "count": 3, "rate": 3/4, "matches_declared_endpoint": False, "false_accept_witnesses": ["B", "D"]}
        else:
            observed = {"passes": strict, "pass_rate": len(strict)/len(attempts), "note_correct_rate": len(notes)/len(attempts)}
            oracle = {"passes": ["A"], "pass_rate": 1/4, "note_correct_rate": 3/4}

    elif code == "MCL009":
        starts, _ = prefix(values["durations_quarters"])
        event = starts[2]+values["local_offset_measure2"]
        if negative:
            correct_starts, _ = prefix(main["durations_quarters"])
            correct_event = correct_starts[2]+main["local_offset_measure2"]
            observed = {"starts_quarters": starts, "event_quarters": event, "error_quarters": event-correct_event,
                        "error_seconds": (event-correct_event)*60/main["quarter_BPM"]}
            oracle = {"starts_quarters": [0, 4, 8], "event_quarters": 9, "error_quarters": 3, "error_seconds": 3/2}
        else:
            observed = {"starts_quarters": starts, "measure2_event_quarters": event, "measure2_event_seconds": event*60/values["quarter_BPM"],
                        "wrong_full_pickup_event_quarters": 4+values["durations_quarters"][1]+values["local_offset_measure2"]}
            oracle = {"starts_quarters": [0, 1, 5], "measure2_event_quarters": 6, "measure2_event_seconds": 3, "wrong_full_pickup_event_quarters": 9}

    elif code == "MCL010":
        beat = 60/values["quarter_BPM"]
        a, b = values["ratio"]
        pair = [beat*a/(a+b), beat*b/(a+b)]
        if negative:
            original_beat = 60/main["quarter_BPM"]
            original = [original_beat*r/sum(main["ratio"]) for r in main["ratio"]]
            observed = {"pair_seconds": pair, "total_seconds": sum(pair), "matches_original": pair == original}
            oracle = {"pair_seconds": [1/2, 1/2], "total_seconds": 1, "matches_original": False}
        else:
            observed = {"beat_seconds": beat, "first_seconds": pair[0], "second_seconds": pair[1], "straight_seconds": [beat/2, beat/2],
                        "at_60_seconds": [r/sum(values["ratio"]) for r in values["ratio"]]}
            oracle = {"beat_seconds": 1/2, "first_seconds": 1/3, "second_seconds": 1/6, "straight_seconds": [1/4, 1/4], "at_60_seconds": [2/3, 1/3]}

    elif code == "MCL011":
        durations = main["durations_quarters"]
        starts, total = prefix([durations[m] for m in main["playback"]])
        if negative:
            shorter = sum(durations[m] for m in values["deduplicated"])
            observed = {"total_quarters": shorter, "lost_quarters": total-shorter}
            oracle = {"total_quarters": 12, "lost_quarters": 8}
        else:
            b_starts = [start for measure, start in zip(values["playback"], starts, strict=True) if measure == "B"]
            observed = {"visit_starts_quarters": starts, "total_quarters": total, "B_visits": len(b_starts), "second_B_start": b_starts[1],
                        "wrong_deduplicated_total": sum(durations[m] for m in dict.fromkeys(values["playback"]))}
            oracle = {"visit_starts_quarters": [0, 4, 8, 12, 16], "total_quarters": 20, "B_visits": 2, "second_B_start": 12, "wrong_deduplicated_total": 12}

    elif code == "WML008":
        if negative:
            naive = [values["drone"]+c for c in values["classes"]]
            observed = {"naive_reconstructed": naive, "matches_original": naive == main["notes"]}
            oracle = {"naive_reconstructed": [67, 67, 67], "matches_original": False}
        else:
            signed = [n-values["drone"] for n in values["notes"]]
            observed = {"signed_semitones": signed, "classes": [n%12 for n in signed], "reconstructed": [values["drone"]+n for n in signed]}
            oracle = {"signed_semitones": [-5, 7, 19], "classes": [7, 7, 7], "reconstructed": [55, 67, 79]}

    elif code == "WML009":
        if negative:
            quarters = values["count"]*values["unit_quarters"]
            seconds = quarters*60/values["quarter_BPM"]
            source = main["count"]*main["source_unit_quarters"]*60/main["quarter_BPM"]
            observed = {"quarters": quarters, "seconds": seconds, "matches_source": seconds == source}
            oracle = {"quarters": 6, "seconds": 3, "matches_source": False}
        else:
            quarters = values["count"]*values["source_unit_quarters"]
            wrong = values["count"]*values["wrong_target_unit_quarters"]
            starts, _ = prefix(values["group_lengths_eighths"])
            alternative, _ = prefix([2, 2, 2])
            observed = {"source_quarters": quarters, "source_seconds": quarters*60/values["quarter_BPM"], "wrong_quarters": wrong,
                        "wrong_seconds": wrong*60/values["quarter_BPM"], "starts_eighths": starts, "alternative_starts": alternative}
            oracle = {"source_quarters": 3, "source_seconds": 3/2, "wrong_quarters": 6, "wrong_seconds": 3, "starts_eighths": [0, 3], "alternative_starts": [0, 2, 4]}

    elif code == "WML010":
        # Explicit two-token application aliases; not Unicode normalization.
        aliases = {"C\u266f4": "C#4", "C#4": "C#4"}
        originals = main["originals"]
        displays = [aliases[token] for token in originals]
        if negative:
            restored = values["reverse_always_musical"]
            observed = {"distinct_displays": len(set(values["display_only"])),
                        "reversible": len(set(values["display_only"])) == len(set(originals)),
                        "exact_restored_rows": sum(a == b for a, b in zip(originals, restored, strict=True)),
                        "failed_row_indices": [i for i,(a,b) in enumerate(zip(originals, restored, strict=True)) if a != b]}
            oracle = {"distinct_displays": 1, "reversible": False, "exact_restored_rows": 1, "failed_row_indices": [1]}
        else:
            receipts = list(zip(originals, displays, strict=True))
            observed = {"displays": displays, "distinct_originals": len(set(originals)), "distinct_displays": len(set(displays)),
                        "roundtrip_originals": [r[0] for r in receipts], "codepoints": [ord(token[1]) for token in originals]}
            oracle = {"displays": ["C#4", "C#4"], "distinct_originals": 2, "distinct_displays": 1,
                      "roundtrip_originals": ["C\u266f4", "C#4"], "codepoints": [9839, 35]}
    else:
        raise ValueError("Unknown course: " + code)
    return observed, oracle, claimed


class UnitAClaimTests(unittest.TestCase):
    def assert_equivalent(self, observed, expected, path="result"):
        if isinstance(expected, dict):
            self.assertIsInstance(observed, dict, path)
            for key, value in expected.items():
                self.assertIn(key, observed, path)
                self.assert_equivalent(observed[key], value, path+"."+key)
        elif isinstance(expected, list):
            self.assertEqual(len(observed), len(expected), path)
            for i, (actual, wanted) in enumerate(zip(observed, expected, strict=True)):
                self.assert_equivalent(actual, wanted, path+"["+str(i)+"]")
        elif isinstance(expected, bool) or expected is None:
            self.assertIs(observed, expected, path)
        elif isinstance(expected, (int, float)):
            self.assertFalse(isinstance(observed, bool), path)
            self.assertTrue(math.isclose(observed, expected, rel_tol=1e-12, abs_tol=1e-10),
                            f"{path}: {observed!r} != {expected!r}")
        else:
            self.assertEqual(observed, expected, path)

    def check_case(self, code, case):
        observed, oracle, claimed = evaluate(code, case)
        print("OBSERVATION " + json.dumps({"code": code, "case": case, "observed": observed,
                                         "expected": oracle, "scope": SCOPE}, ensure_ascii=True), flush=True)
        self.assert_equivalent(observed, oracle)
        # The published packet's output claims must agree with the independent result too.
        self.assert_equivalent(observed, claimed, "packet.expected")


DESCRIPTIONS = {
    "AUD010": "downmix_channel_cancellation", "AUD011": "partial_block_support",
    "AUD012": "finite_fade_energy", "GAS009": "integer_delay_cents",
    "GAS010": "normalized_stiff_partials", "GAS011": "signed_fixed_boundary",
    "GTR009": "sequential_shift_time_budget", "GTR010": "release_and_damping_state_witness",
    "GTR011": "continuous_barre_contact_witness", "GAA008": "inclusive_due_rule_and_missing_outcome",
    "GAA009": "absolute_transposition_and_register", "GAA010": "conjunctive_pass_truth_table",
    "MCL009": "pickup_prefix_coordinates", "MCL010": "ratio_vs_beat_clock",
    "MCL011": "written_identity_vs_visit", "WML008": "signed_drone_distance",
    "WML009": "counted_unit_and_group_boundary", "WML010": "original_token_restoration_witness",
}


def make_case_test(code, case):
    def test(self):
        self.check_case(code, case)
    return test


for _code, _description in DESCRIPTIONS.items():
    for _case in ("model", "negative"):
        setattr(UnitAClaimTests, f"test_{_code}_{_case}_{_description}", make_case_test(_code, _case))


if __name__ == "__main__":
    unittest.main()
