"""Builds the two procedural models of `scripts/atlas/` and reads their .glb files back, for CI.

The models — a metronome with a swinging pendulum, a gramophone with a turning record — are modelled in `bpy`
rather than generated from an image. They are the comparison point of the journal entry on procedural modelling
against image-to-3D. The scripts come from the orchestrator's agent; this file runs them and reports.
"""
import os
import runpy
import sys

sys.path.insert(0, os.path.dirname(__file__))
from common import Report, out_dir  # noqa: E402

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "atlas"))
import verify  # noqa: E402

r = Report("atlas_check")
work = os.path.abspath(os.path.join(out_dir(), "atlas"))
os.makedirs(work, exist_ok=True)

for name in ("metronome", "gramophone"):
    path = os.path.join(work, name + ".glb")
    os.environ["ATLAS_OUT"] = path
    r(f"== {name}")
    runpy.run_path(os.path.join(os.path.dirname(__file__), "atlas", f"build_{name}.py"), run_name="__main__")
    verify.report(path, r)
    r("")
r.save()
