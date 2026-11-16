"""Replay the previous audio tranche's authored cases, never the audio engine."""

import cmath
import json
import math
from pathlib import Path
import statistics
import unittest


DATA = Path(__file__).resolve().parents[2] / "audio-comparison-2026-10-23"


def load(name):
    return json.loads((DATA / name).read_text(encoding="utf-8"))


def rms(values):
    return math.sqrt(sum(x * x for x in values) / len(values))


def observe(code, case, observed, expected):
    print("OBSERVATION " + json.dumps(dict(
        code=code, case=case, observed=observed, expected=expected,
        scope="Previous tranche's authored mathematical case; no engine/listener trial."
    )), flush=True)


class BaselineAudio(unittest.TestCase):
    def test_GAS008_model(self):
        data = load("beating-envelope.json")
        amplitude = data["component_amplitude"]
        damping = data["component_damping_per_s"]
        first, second = data["frequencies_Hz"]
        errors = []
        for point in data["points"]:
            t = point["time_s"]
            summed = amplitude * math.exp(-damping * t) * (
                cmath.exp(2j * math.pi * first * t)
                + cmath.exp(2j * math.pi * second * t)
            )
            errors.append(abs(abs(summed) - point["defined_modulation_envelope"]))
        observe("GAS008", "model", dict(max_envelope_error=max(errors),
                carrier=(first + second) / 2, beat=abs(second - first)),
                dict(max_envelope_error_bound=1e-12, carrier=data["carrier_Hz"], beat=data["beat_Hz"]))
        self.assertLess(max(errors), 1e-12)
        self.assertEqual((first + second) / 2, data["carrier_Hz"])
        self.assertEqual(abs(second - first), data["beat_Hz"])

    def test_GAS008_negative(self):
        data = load("beating-envelope.json")
        row = data["misleading_interval"]
        amplitude = data["component_amplitude"]
        damping = data["component_damping_per_s"]
        difference = abs(data["frequencies_Hz"][1] - data["frequencies_Hz"][0])
        def envelope(t):
            return 2 * amplitude * math.exp(-damping * t) * abs(math.cos(math.pi * difference * t))
        start, end = row["start_s"], row["end_s"]
        apparent = -math.log(envelope(end) / envelope(start)) / (end - start)
        observe("GAS008", "negative", dict(apparent_rate=apparent, component_rate=damping,
                zero_log=data["zero_log_fit"]["log_envelope"]),
                dict(apparent_rate=row["naive_damping_per_s"], component_rate_positive=True, zero_log=None))
        self.assertAlmostEqual(apparent, row["naive_damping_per_s"], places=12)
        self.assertLess(apparent, 0)
        self.assertGreater(damping, 0)
        self.assertIsNone(data["zero_log_fit"]["log_envelope"])
        self.assertTrue(data["same_beat_phase"]["not_asserted_local_maxima"])

    def test_AUD009_model(self):
        data = load("null-comparison.json")
        x, y = data["reference"], data["candidate"]
        n, lag = len(x), data["declared_delay_frames"]
        aligned = y[lag:lag + n]
        gain = sum(a * b for a, b in zip(x, aligned)) / sum(a * a for a in x)
        raw = rms([y[i] - x[i] for i in range(n)])
        unity = rms([aligned[i] - x[i] for i in range(n)])
        fitted = rms([aligned[i] - gain * x[i] for i in range(n)])
        observe("AUD009", "model", dict(gain=gain, raw_rms=raw, unity_rms=unity,
                fitted_rms=fitted, delay_ms=1000 * lag / data["sample_rate_Hz"]),
                dict(gain=data["gain_fit"]["gain"], raw_rms=data["raw_first8"]["residual_rms"],
                unity_rms=data["aligned_unity_gain"]["residual_rms"], fitted_rms=0, delay_ms=.25))
        self.assertEqual(len(aligned), n)
        self.assertEqual(gain, .5)
        self.assertAlmostEqual(raw, data["raw_first8"]["residual_rms"], places=14)
        self.assertAlmostEqual(unity, data["aligned_unity_gain"]["residual_rms"], places=14)
        self.assertEqual(fitted, 0)
        self.assertAlmostEqual(20 * math.log10(gain), data["gain_fit"]["gain_dB"], places=12)
        self.assertEqual(1000 * lag / data["sample_rate_Hz"], data["declared_delay_ms"])
        self.assertEqual(1000 * lag / data["sample_rate_Hz"], .25)

    def test_AUD009_negative(self):
        data = load("null-comparison.json")
        tail = data["tail_control"]
        residual = [y - data["declared_gain"] * x for x, y in zip(data["reference"], tail["aligned_candidate"])]
        prefix = rms(residual[:tail["checked_prefix_frames"]])
        full = rms(residual)
        silence_energy = sum(x * x for x in data["silence_control"]["reference"])
        observe("AUD009", "negative", dict(prefix_rms=prefix, full_rms=full,
                coverage=tail["checked_prefix_frames"] / tail["target_frames"], silence_energy=silence_energy),
                dict(prefix_rms=0, full_rms=tail["full_prescribed_gain_residual_rms"], coverage=.75, silence_energy=0))
        self.assertEqual(prefix, 0)
        self.assertGreater(full, 0)
        self.assertAlmostEqual(full, tail["full_prescribed_gain_residual_rms"], places=14)
        self.assertEqual(tail["target_frames"], len(data["reference"]))
        self.assertEqual(len(tail["aligned_candidate"]), tail["target_frames"])
        self.assertEqual(len(residual), tail["target_frames"])
        self.assertEqual(tail["checked_prefix_frames"] / tail["target_frames"], .75)
        self.assertLess(tail["checked_prefix_frames"], tail["target_frames"])
        self.assertFalse(tail["full_target_equal_after_prescribed_gain"])
        self.assertEqual(silence_energy, 0)
        self.assertIsNone(data["silence_control"]["gain_fit"])

    def test_INF009_model(self):
        data = load("normalized-shape.json")
        normalized = []
        statistics_rows = []
        for key in ["x", "y"]:
            row = data[key]
            mean = statistics.mean(row["samples"])
            sigma = statistics.pstdev(row["samples"])
            normalized.append([(x - mean) / sigma for x in row["samples"]])
            statistics_rows.append(dict(key=key, mean=mean, population_sigma=sigma))
        difference = rms([a - b for a, b in zip(data["x"]["samples"], data["y"]["samples"])])
        observe("INF009", "model", dict(z_x=normalized[0], z_y=normalized[1], difference_rms=difference,
                statistics=statistics_rows), dict(z_equal=True, difference_rms=data["raw_difference_rms"],
                statistics=[dict(key=key, mean=data[key]["mean"], population_sigma=data[key]["population_sigma"])
                            for key in ["x", "y"]]))
        for result, zs in zip(statistics_rows, normalized):
            row = data[result["key"]]
            self.assertEqual(result["mean"], row["mean"])
            self.assertAlmostEqual(result["population_sigma"], row["population_sigma"], places=14)
            for original, z in zip(row["samples"], zs):
                self.assertAlmostEqual(result["mean"] + result["population_sigma"] * z, original, places=14)
        self.assertEqual(normalized[0], normalized[1])
        self.assertGreater(difference, 0)
        self.assertAlmostEqual(difference, data["raw_difference_rms"], places=14)

    def test_INF009_negative(self):
        data = load("normalized-shape.json")
        x = data["x"]["samples"]
        inverted = data["inversion"]["record"]["samples"]
        cx = [a - statistics.mean(x) for a in x]
        cy = [a - statistics.mean(inverted) for a in inverted]
        correlation = sum(a * b for a, b in zip(cx, cy)) / math.sqrt(sum(a*a for a in cx) * sum(b*b for b in cy))
        sigma = statistics.pstdev(data["constant"]["samples"])
        observe("INF009", "negative", dict(signed=correlation, absolute=abs(correlation), constant_sigma=sigma),
                dict(signed=-1, absolute=1, constant_sigma=0))
        self.assertEqual(correlation, -1)
        self.assertEqual(abs(correlation), 1)
        self.assertEqual([a + b for a, b in zip(x, inverted)], [0] * len(x))
        self.assertEqual(sigma, 0)
        self.assertIsNone(data["constant"]["z"])
        self.assertIsNone(data["constant_correlation"])


if __name__ == "__main__":
    unittest.main()
