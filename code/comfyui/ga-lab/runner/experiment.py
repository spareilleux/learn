"""Experiment files: a hypothesis, a prediction, a base workflow, a parameter grid and seeds.

    id: 02-controlnet-strength
    title: ...
    written: 2026-09-16            # the date the hypothesis and prediction were written, before any run
    hypothesis: ...
    prediction: ...
    workflow: ../workflows/ga-chord-neck.api.json
    seeds: [42, 43]
    seed_paths: ["3.seed"]         # every KSampler seed input that takes the item's seed
    fixed: {"18.chord": "F"}       # set on every item
    axes:                          # the grid is the cartesian product of the axes, then the seeds
      - name: strength
        path: "22.strength"        # simple axis: one input, the value is the label
        values: [0.2, 0.4]
      - name: chord                # compound axis: each value sets several inputs, and may switch workflow
        values:
          - {label: C, set: {"18.chord": "C"}}
          - {label: F, set: {"18.chord": "F"}, workflow: ../workflows/other.api.json, seed_paths: ["8.seed"]}
    prepare:                       # input images made before the run, uploaded when a value says {input: name}
      - {name: bracelet, kind: svg, src: ../../../../src/assets/music-theory-ga/l2-bracelet-major.svg, size: 1024}
    extra_memory_gb: 0             # added to the memory rule's margin (video latents, for example)
    analysis: [...]                # what `python -m runner analyze` computes to check the prediction

A path is "node_id.input_name". The input must already exist in the workflow, so a typo fails early.
"""
import copy
import hashlib
import itertools
import json
import os

REQUIRED = ("id", "title", "written", "hypothesis", "prediction", "workflow", "seeds", "seed_paths")


class ExperimentError(Exception):
    pass


def load_file(path):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    if path.endswith(".json"):
        return json.loads(text)
    try:
        import yaml
    except ImportError as e:
        raise ExperimentError("reading a .yaml experiment needs PyYAML (pip install pyyaml), or use .json") from e
    return yaml.safe_load(text)


def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def canonical(obj):
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


class Experiment:
    def __init__(self, path):
        self.path = os.path.abspath(path)
        self.dir = os.path.dirname(self.path)
        data = load_file(self.path)
        if not isinstance(data, dict):
            raise ExperimentError(f"{path}: not a mapping")
        missing = [k for k in REQUIRED if (data.get(k) is None if k == "seed_paths" else not data.get(k))]
        if missing:
            raise ExperimentError(f"{path}: missing {', '.join(missing)}")
        self.data = data
        self.id = str(data["id"])
        self.seeds = list(data["seeds"])
        self.seed_paths = list(data["seed_paths"])
        self.fixed = dict(data.get("fixed") or {})
        self.axes = list(data.get("axes") or [])
        self.prepare = list(data.get("prepare") or [])
        self.extra_memory_gb = float(data.get("extra_memory_gb") or 0)
        self.workflows = {}
        for axis in self.axes:
            if "name" not in axis or "values" not in axis:
                raise ExperimentError(f"{path}: each axis needs a name and values")
        with open(self.path, "rb") as f:
            self.sha256 = sha256_bytes(f.read())

    def resolve(self, relative):
        return os.path.normpath(os.path.join(self.dir, relative))

    def workflow(self, relative):
        full = self.resolve(relative)
        if full not in self.workflows:
            try:
                with open(full, encoding="utf-8") as f:
                    self.workflows[full] = json.load(f)
            except OSError as e:
                raise ExperimentError(f"{self.path}: workflow {relative}: {e}") from e
        return full, self.workflows[full]

    def items(self):
        """Every (labels, sets, workflow path, seed), axes first, seeds last."""
        choices = []
        for axis in self.axes:
            options = []
            for value in axis["values"]:
                if isinstance(value, dict) and ("set" in value or "workflow" in value):
                    options.append((str(value.get("label")), dict(value.get("set") or {}), value.get("workflow"),
                                    value.get("seed_paths")))
                else:
                    if "path" not in axis:
                        raise ExperimentError(f"{self.path}: axis {axis['name']} has plain values but no path")
                    options.append((str(value), {axis["path"]: value}, None, None))
            choices.append(options)
        result = []
        for combo in itertools.product(*choices):
            labels, sets, workflow, seed_paths = {}, dict(self.fixed), self.data["workflow"], self.seed_paths
            for axis, (label, axis_sets, axis_workflow, axis_seed_paths) in zip(self.axes, combo):
                labels[axis["name"]] = label
                sets.update(axis_sets)
                if axis_workflow:
                    workflow = axis_workflow
                if axis_seed_paths:
                    seed_paths = axis_seed_paths
            for seed in self.seeds:
                item_sets = dict(sets)
                for p in seed_paths:
                    item_sets[p] = seed
                result.append({"labels": dict(labels), "sets": item_sets, "workflow": workflow, "seed": seed})
        return result


def apply_sets(workflow, sets, workflow_name="workflow"):
    """A copy of an API-format workflow with each "node.input" set; the node and the input must exist."""
    prompt = copy.deepcopy(workflow)
    for path, value in sets.items():
        node, sep, name = str(path).partition(".")
        if not sep or node not in prompt:
            raise ExperimentError(f"{workflow_name}: no node {node!r} for {path!r}")
        inputs = prompt[node].setdefault("inputs", {})
        if name not in inputs:
            raise ExperimentError(f"{workflow_name}: node {node} ({prompt[node].get('class_type')}) has no input {name!r}")
        inputs[name] = value
    return prompt


def input_references(sets):
    """The prepared inputs an item uses: values written {input: name}."""
    return {path: v["input"] for path, v in sets.items() if isinstance(v, dict) and "input" in v}


def item_key(prompt_with_input_hashes):
    """Hash of the final prompt, with uploaded file names replaced by their content hash."""
    return sha256_bytes(canonical(prompt_with_input_hashes).encode())[:16]
