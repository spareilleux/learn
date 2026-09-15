# /// script
# requires-python = ">=3.14"
# dependencies = [
#     "jsonschema==4.26.0",
# ]
# ///
# scripts/l01_ex2_validate.py
import jsonschema

schema = {
    "type": "object",
    "required": ["name", "partitions"],
    "properties": {
        "name": {"type": "string"},
        "partitions": {"type": "array", "items": {"type": "string"}, "minItems": 1},
    },
}
artifacts = {
    "good.json": {"name": "optick-sae", "partitions": ["ROOT", "STRUCTURE"]},
    "bad.json": {"name": "optick-sae", "partitions": []},
}
for name, artifact in artifacts.items():
    try:
        jsonschema.validate(artifact, schema)
        print(f"PASS {name}")
    except jsonschema.ValidationError as e:
        print(f"FAIL {name}: {e.message}")
