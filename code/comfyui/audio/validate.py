#!/usr/bin/env python3
"""Lesson 15: check API-format audio workflows against node definitions saved from /object_info.

    python validate.py OBJECT_INFO.json WORKFLOW.api.json...

The checks are the ones lesson 3's C# validator makes, in Python so this folder needs nothing but Python:
every node type exists, required inputs are present, links point at an existing node and an output whose
type matches the input, numbers are within their bounds, combo values are among the options (including the
model file names, which is why the saved definitions come from an install that has the models), and the
workflow has an output node. Dynamic combos (SaveAudioAdvanced's `format`) are checked with their sub-inputs,
which the API format writes as `format.quality`. Exit code 1 if any file has an error.
"""
import json
import sys
from pathlib import Path


def is_link(value):
    return isinstance(value, list) and len(value) == 2 and isinstance(value[0], str) and isinstance(value[1], int)


def spec_inputs(definition):
    """name -> [type, options] for required and optional inputs, with dynamic combo sub-inputs flattened."""
    specs = {}
    for group in ("required", "optional"):
        for name, spec in definition.get("input", {}).get(group, {}).items():
            specs[name] = (spec, group == "required")
    return specs


def combo_options(spec):
    kind = spec[0]
    if isinstance(kind, list):
        return kind
    if kind == "COMBO":
        return spec[1].get("options", []) if len(spec) > 1 else []
    return None


def check_value(where, spec, value, inputs, name, errors):
    kind = spec[0]
    options = spec[1] if len(spec) > 1 and isinstance(spec[1], dict) else {}
    choices = combo_options(spec)
    if choices is not None:
        if value not in choices:
            errors.append(f"{where}: {value!r} is not one of {len(choices)} options")
    elif kind == "INT":
        if not isinstance(value, int) or isinstance(value, bool):
            errors.append(f"{where}: {value!r} is not an INT")
        elif ("min" in options and value < options["min"]) or ("max" in options and value > options["max"]):
            errors.append(f"{where}: {value} is outside [{options.get('min')}, {options.get('max')}]")
    elif kind == "FLOAT":
        if not isinstance(value, (int, float)) or isinstance(value, bool):
            errors.append(f"{where}: {value!r} is not a FLOAT")
        elif ("min" in options and value < options["min"]) or ("max" in options and value > options["max"]):
            errors.append(f"{where}: {value} is outside [{options.get('min')}, {options.get('max')}]")
    elif kind == "BOOLEAN":
        if not isinstance(value, bool):
            errors.append(f"{where}: {value!r} is not a BOOLEAN")
    elif kind == "STRING":
        if not isinstance(value, str):
            errors.append(f"{where}: {value!r} is not a STRING")
    elif kind == "COMFY_DYNAMICCOMBO_V3":
        keys = {o["key"]: o for o in options.get("options", [])}
        if value not in keys:
            errors.append(f"{where}: {value!r} is not one of {sorted(keys)}")
            return
        for sub_name, (sub_spec, required) in spec_inputs({"input": keys[value]["inputs"]}).items():
            full = f"{name}.{sub_name}"
            if full in inputs:
                check_value(f"{where.rsplit(' ', 1)[0]} {full}", sub_spec, inputs[full], inputs, full, errors)
            elif required:
                errors.append(f"{where.rsplit(' ', 1)[0]} {full}: required input is missing")
    else:
        errors.append(f"{where}: a {kind} input needs a link, got {value!r}")


def check(workflow, object_info):
    errors = []
    has_output = False
    for node_id, node in workflow.items():
        kind = node.get("class_type")
        definition = object_info.get(kind)
        if definition is None:
            errors.append(f"node {node_id}: unknown node type {kind}")
            continue
        has_output |= bool(definition.get("output_node"))
        inputs = node.get("inputs", {})
        specs = spec_inputs(definition)
        for name, (spec, required) in specs.items():
            where = f"node {node_id} ({kind}) {name}"
            if name not in inputs:
                if required:
                    errors.append(f"{where}: required input is missing")
                continue
            value = inputs[name]
            if is_link(value):
                source = workflow.get(value[0])
                if source is None:
                    errors.append(f"{where}: links to missing node {value[0]}")
                    continue
                outputs = object_info.get(source.get("class_type"), {}).get("output", [])
                if value[1] >= len(outputs):
                    errors.append(f"{where}: node {value[0]} has no output {value[1]}")
                    continue
                wanted = "COMBO" if isinstance(spec[0], list) else spec[0]
                if outputs[value[1]] != wanted and "*" not in (outputs[value[1]], wanted):
                    errors.append(f"{where}: expects {wanted}, node {value[0]} output {value[1]} is {outputs[value[1]]}")
            else:
                check_value(where, spec, value, inputs, name, errors)
        known = set(specs) | {n for n in inputs if "." in n and n.split(".", 1)[0] in specs}
        for name in inputs:
            if name not in known:
                errors.append(f"node {node_id} ({kind}) {name}: not an input of {kind}")
    if not has_output:
        errors.append("the workflow has no output node")
    return errors


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    object_info = json.loads(Path(argv[0]).read_text(encoding="utf-8"))
    status = 0
    for path in argv[1:]:
        errors = check(json.loads(Path(path).read_text(encoding="utf-8")), object_info)
        print(f"{Path(path).name}: {'ok' if not errors else f'{len(errors)} error(s)'}")
        for error in errors:
            print(f"  {error}")
        status |= bool(errors)
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
