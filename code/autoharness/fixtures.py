"""AutoHarness course: pre-registered fixtures against tigerless-labs/autoharness, pinned, with no LLM and no host.

Each fixture runs in its own Python subprocess with a minimal environment built here (no inherited variables, so no
credentials and no AUTOHARNESS_* knobs), HOME/USERPROFILE/TEMP pointing into a disposable directory, the working
directory inside it, and PYTHONPATH on the pinned clone's src/. Every call passes explicit `roots`, so no path is
derived from the real home or the current repository. Nothing spawns `claude`: only the promoter, the intent queue,
the skill store and the redactor are imported.

    python fixtures.py --hashes                      # print the input hash of each fixture, imports nothing
    python fixtures.py --clone <path to the clone>   # run F0..F5, print one JSON line per fixture

The clone must be at the pinned commit; the script refuses otherwise.
"""
import argparse
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

PIN = "ca39a72e4353ebef11b7de13c1fc7fa5f4df421b"

# A skill body that passes the promoter's gates (the same shape as upstream's tests/test_promoter.py GOOD_BODY).
GOOD = "---\nname: {name}\ndescription: Use when formatting a date as ISO.\n---\n# {title}\nUse strftime.\n"
HAND = "---\nname: notes\ndescription: Use when I review my own release notes.\n---\n# Notes\nHAND-WRITTEN SENTINEL 7f3a\n"
CANARY = "CANARYabcdefghij0123456789"
PEM_BODY = "MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC" + CANARY

FIXTURES = {
    # F0 positive control: the harness can land a create at all.
    "F0": {"create": {"action": "create", "name": "fresh", "level": "project",
                      "body": GOOD.format(name="fresh", title="Fresh"), "reason": "r", "evidence": "e"}},
    # F1 (H2): a create over a hand-written skill of the same name; negative control: an update on it.
    "F1": {"hand_body": HAND,
           "update": {"action": "update", "name": "notes", "body": GOOD.format(name="notes", title="Notes"),
                      "reason": "r", "evidence": "e"},
           "create": {"action": "create", "name": "notes", "level": "project",
                      "body": GOOD.format(name="notes", title="Notes"), "reason": "r", "evidence": "e"}},
    # F2 (H10): one truncated line in the intent queue; control: the same queue without it.
    "F2": {"good": [{"action": "create", "name": n, "level": "project", "body": GOOD.format(name=n, title=n),
                     "reason": "r", "evidence": "e"} for n in ("alpha", "beta")],
           "bad_line": '{"action": "create", "name": "gam'},
    # F3 (H13): secrets the redactor should catch; the first is the control its own rule targets.
    "F3": {"inputs": {"assignment": f"api_key = {CANARY}",
                      "json_quoted": json.dumps({"api_key": CANARY}),
                      "pem": f"-----BEGIN PRIVATE KEY-----\n{PEM_BODY}\n-----END PRIVATE KEY-----"}},
    # F4 (new, Windows): a non-ASCII body written by the promoter and read back by the skill store.
    "F4": {"create": {"action": "create", "name": "accents", "level": "project",
                      "body": GOOD.format(name="accents", title="Café Á"), "reason": "r", "evidence": "e"}},
    # F5 (H3): a user's *.tmp inside a hand-written skill folder, and an empty drain; control: a *.txt next to it.
    "F5": {"hand_body": HAND, "tmp": "draft.tmp", "control": "draft.txt", "content": "my unfinished draft\n"},
}


def input_hash(fid):
    return hashlib.sha256(json.dumps(FIXTURES[fid], sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()


# --- child side: runs inside the isolated subprocess -------------------------------------------------------------

def child(fid, work):
    from autoharness.hook import promoter
    from autoharness.lib import intent_queue, layer, redact, sidecar, skill_store

    fx = FIXTURES[fid]
    roots = {"global": work / "g", "project": work / "p"}
    proot = roots["project"]
    out = {"fixture": fid}

    if fid == "F0":
        v = promoter.promote(fx["create"], roots=roots)
        out.update(ok=v["ok"], findings=v["findings"],
                   agent_created=sidecar.is_agent_created("project", "fresh", proot))

    elif fid == "F1":
        skill_store.write_body("project", "notes", fx["hand_body"], proot)
        vu = promoter.promote(fx["update"], roots=roots)
        out["control_update"] = {"ok": vu["ok"], "findings": [f[0] for f in vu["findings"]],
                                 "body_unchanged": skill_store.read_body("project", "notes", proot) == fx["hand_body"]}
        vc = promoter.promote(fx["create"], roots=roots)
        body = skill_store.read_body("project", "notes", proot)
        out["create"] = {"ok": vc["ok"], "findings": [f[0] for f in vc["findings"]],
                         "sentinel_survives": "HAND-WRITTEN SENTINEL 7f3a" in body,
                         "agent_created_after": sidecar.is_agent_created("project", "notes", proot),
                         "archived_copy": any(layer.archive_dir("project", proot).rglob("*"))
                         if layer.archive_dir("project", proot).exists() else False}

    elif fid == "F2":
        def run(run_id, lines):
            for line in lines:
                p = layer.state_dir(layer.PROJECT, proot) / "intents" / f"{run_id}.jsonl"
                p.parent.mkdir(parents=True, exist_ok=True)
                with p.open("a", encoding="utf-8") as f:
                    f.write(line + "\n")
            attempts = []
            for _ in range(2):
                try:
                    vs = promoter.drain(run_id, roots=roots)
                    attempts.append({"raised": None, "landed": sum(v["ok"] for v in vs)})
                except Exception as exc:  # noqa: BLE001 - the exception type is the measurement
                    attempts.append({"raised": type(exc).__name__})
            return {"attempts": attempts, "queue_left": run_id in intent_queue.orphans(proot)}
        good = [json.dumps(i) for i in fx["good"]]
        out["control"] = run("ctl", good)
        # the good intents use other names in the treatment run, so the control's landings cannot mask it
        treat = [json.dumps({**i, "name": i["name"] + "2", "body": i["body"].replace(i["name"], i["name"] + "2")})
                 for i in fx["good"]]
        out["treatment"] = run("poison", [treat[0], fx["bad_line"], treat[1]])
        out["treatment"]["landed_names"] = sorted(n for n in ("alpha2", "beta2")
                                                  if skill_store.exists("project", n, proot))

    elif fid == "F3":
        out["results"] = {k: {"canary_survives": CANARY in redact.redact(v), "redacted": redact.redact(v)}
                          for k, v in fx["inputs"].items()}

    elif fid == "F4":
        v = promoter.promote(fx["create"], roots=roots)
        raw = skill_store.skill_path("project", "accents", proot).read_bytes()
        try:
            back = skill_store.read_body("project", "accents", proot)
            out["read_back"] = {"raised": None, "equal": back == fx["create"]["body"],
                                "title_line": back.splitlines()[4]}
        except UnicodeDecodeError as exc:
            out["read_back"] = {"raised": "UnicodeDecodeError", "detail": str(exc)[:120]}
        out.update(ok=v["ok"], bytes_are_utf8=raw == fx["create"]["body"].encode("utf-8"),
                   utf8_mode=sys.flags.utf8_mode)

    elif fid == "F5":
        skill_store.write_body("project", "notes", fx["hand_body"], proot)
        sdir = layer.symbol_dir("project", "notes", proot)
        (sdir / fx["tmp"]).write_text(fx["content"], encoding="utf-8")
        (sdir / fx["control"]).write_text(fx["content"], encoding="utf-8")
        promoter.drain("empty", roots=roots)
        out.update(tmp_survives=(sdir / fx["tmp"]).exists(), control_survives=(sdir / fx["control"]).exists(),
                   skill_survives=skill_store.read_body("project", "notes", proot) == fx["hand_body"])

    print(json.dumps(out, ensure_ascii=False))


# --- parent side ---------------------------------------------------------------------------------------------------

def minimal_env(clone, home, utf8):
    env = {"PATH": str(Path(sys.executable).parent), "PYTHONPATH": str(Path(clone) / "src"),
           "HOME": str(home), "USERPROFILE": str(home), "TEMP": str(home), "TMP": str(home),
           "PYTHONDONTWRITEBYTECODE": "1", "PYTHONIOENCODING": "utf-8"}
    if os.name == "nt":
        env["SYSTEMROOT"] = os.environ.get("SYSTEMROOT", r"C:\Windows")  # the interpreter cannot start without it
    if utf8 is not None:
        env["PYTHONUTF8"] = utf8
    return env


def run_fixture(clone, fid, utf8=None):
    with tempfile.TemporaryDirectory(prefix=f"ah-{fid}-") as tmp:
        tmp = Path(tmp)
        home, work = tmp / "home", tmp / "work"
        home.mkdir()
        work.mkdir()
        proc = subprocess.run([sys.executable, str(Path(__file__).resolve()), "--child", fid, "--work", str(work)],
                              cwd=work, env=minimal_env(clone, home, utf8), capture_output=True, text=True,
                              encoding="utf-8", timeout=60)
        home_left = sorted(str(p.relative_to(home)) for p in home.rglob("*"))
    line = proc.stdout.strip().splitlines()[-1] if proc.stdout.strip() else "{}"
    result = {"fixture": fid, **json.loads(line)}  # a child that crashed still names its fixture
    result.update(exit=proc.returncode, stderr_tail=proc.stderr.strip()[-300:], home_writes=home_left,
                  pythonutf8=utf8, input_sha256=input_hash(fid))
    return result


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--hashes", action="store_true")
    ap.add_argument("--clone")
    ap.add_argument("--child")
    ap.add_argument("--work")
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")  # a redirected stdout would otherwise use the locale encoding (see F4)
    if a.hashes:
        for fid in FIXTURES:
            print(fid, input_hash(fid))
        return 0
    if a.child:
        child(a.child, Path(a.work))
        return 0
    head = subprocess.run(["git", "-C", a.clone, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    if head != PIN:
        print(f"refusing: clone is at {head or '?'}, expected {PIN}", file=sys.stderr)
        return 2
    clone = str(Path(a.clone).resolve())  # the child's cwd is a temp dir: a relative PYTHONPATH would not resolve
    real = Path.home() / ".claude" / "autoharness"
    before = real.exists()
    results = [run_fixture(clone, fid) for fid in FIXTURES]
    results.append(run_fixture(clone, "F4", utf8="1"))  # F4's control: UTF-8 mode
    for r in results:
        print(json.dumps(r, ensure_ascii=False))
    print(json.dumps({"real_state_dir_existed_before": before, "exists_after": real.exists()}))
    return 1 if any(r["exit"] for r in results) else 0  # a crashed fixture is not a result


if __name__ == "__main__":
    sys.exit(main())
