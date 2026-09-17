#!/usr/bin/env python3
"""Lesson 15: queue an audio workflow on ComfyUI, download what it saves, then normalize and encode it with ffmpeg.

    python pipeline.py run SERVER WORKFLOW [--set NODE.INPUT=VALUE]... [--out DIR]
                       [--lufs -16] [--bitrate 96k] [--timeout 1200] [--poll 1]
    python pipeline.py batch SERVER RUNS.json [--out DIR]   each run: {"name", "workflow", "set": [...]}
    python pipeline.py loudness FILE          prints the integrated loudness that ffmpeg measures
    python pipeline.py encode IN OUT          normalizes IN to --lufs and encodes OUT (.opus or .mp3)

Standard library only, plus ffmpeg for the audio steps (FFMPEG, or ffmpeg on the PATH). The client polls
/history instead of opening the WebSocket of lesson 4: Python's standard library has no WebSocket client, and for jobs that
take seconds to minutes, polling once a second costs nothing.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path


def parse_set(assignment):
    """'94.tags=acoustic guitar' -> ('94', 'tags', 'acoustic guitar'); a value that parses as JSON is used as JSON."""
    target, sep, raw = assignment.partition("=")
    node, dot, name = target.partition(".")
    if not sep or not dot or not node or not name:
        raise ValueError(f"expected NODE.INPUT=VALUE, got {assignment!r}")
    try:
        value = json.loads(raw)
    except json.JSONDecodeError:
        value = raw
    return node, name, value


def apply_sets(workflow, assignments):
    for assignment in assignments:
        node, name, value = parse_set(assignment)
        if node not in workflow:
            raise ValueError(f"node {node} is not in the workflow")
        workflow[node]["inputs"][name] = value
    return workflow


class Comfy:
    def __init__(self, server, timeout=30):
        self.base = server.rstrip("/") + "/"
        self.timeout = timeout

    def _request(self, method, path, body=None):
        data = None if body is None else json.dumps(body).encode()
        request = urllib.request.Request(urllib.parse.urljoin(self.base, path), data=data, method=method,
                                         headers={"Content-Type": "application/json"} if data else {})
        with urllib.request.urlopen(request, timeout=self.timeout) as response:
            return response.read()

    def queue(self, workflow, client_id):
        prompt_id = str(uuid.uuid4())
        try:
            answer = json.loads(self._request("POST", "prompt",
                                              {"prompt": workflow, "client_id": client_id, "prompt_id": prompt_id}))
        except urllib.error.HTTPError as error:
            # A workflow that doesn't validate comes back as 400 with "error" and "node_errors".
            with error:
                body = json.loads(error.read() or b"{}")
            raise PromptRejected(body) from None
        return answer.get("prompt_id", prompt_id)

    def history(self, prompt_id):
        return json.loads(self._request("GET", f"history/{prompt_id}")).get(prompt_id)

    def view(self, item):
        query = urllib.parse.urlencode({k: item.get(k, "") for k in ("filename", "subfolder", "type")})
        return self._request("GET", f"view?{query}")


class PromptRejected(Exception):
    def __init__(self, body):
        super().__init__(body.get("error", {}).get("message", "prompt rejected"))
        self.body = body


def wait(comfy, prompt_id, timeout, poll, log):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        entry = comfy.history(prompt_id)
        if entry is not None:
            status = entry.get("status", {})
            if status.get("completed") or status.get("status_str") in ("success", "error"):
                for name, data in status.get("messages", []):
                    if name in ("execution_error", "execution_interrupted"):
                        log(f"{name}: node {data.get('node_id')} {data.get('exception_message', '').strip()}")
                return entry
        time.sleep(poll)
    raise TimeoutError(f"prompt {prompt_id} not finished after {timeout} s")


def saved_files(entry):
    """The files the output nodes wrote, in node id order: SaveAudio* nodes report them under 'audio'."""
    files = []
    for node_id in sorted(entry.get("outputs", {}), key=lambda k: (len(k), k)):
        for kind, items in entry["outputs"][node_id].items():
            if kind in ("audio", "images", "video") and isinstance(items, list):
                files += [(node_id, item) for item in items if isinstance(item, dict) and "filename" in item]
    return files


def ffmpeg():
    """The FFMPEG environment variable, or ffmpeg on the PATH."""
    exe = os.environ.get("FFMPEG") or shutil.which("ffmpeg")
    if exe is None:
        raise FileNotFoundError("set FFMPEG or put ffmpeg on the PATH")
    return exe


def loudnorm_pass(path, lufs, true_peak=-1.5, lra=11):
    """First pass of ffmpeg's loudnorm filter: measures, writes nothing, returns the JSON it prints."""
    result = subprocess.run([ffmpeg(), "-hide_banner", "-nostats", "-i", str(path), "-af",
                             f"loudnorm=I={lufs}:TP={true_peak}:LRA={lra}:print_format=json", "-f", "null", "-"],
                            capture_output=True, text=True, check=True)
    blocks = re.findall(r"\{[^{}]*\}", result.stderr)
    if not blocks:
        raise RuntimeError("loudnorm printed no measurement")
    return json.loads(blocks[-1])


def loudness(path):
    return float(loudnorm_pass(path, -16)["input_i"])


def encode(source, target, lufs=-16.0, bitrate="96k", true_peak=-1.5, lra=11):
    """Two-pass loudnorm to `lufs`, then Opus (.opus) or MP3 (.mp3) at `bitrate`."""
    m = loudnorm_pass(source, lufs, true_peak, lra)
    target = Path(target)
    codec = {".opus": ["-c:a", "libopus", "-ar", "48000"], ".mp3": ["-c:a", "libmp3lame", "-ar", "44100"]}[target.suffix]
    audio_filter = (f"loudnorm=I={lufs}:TP={true_peak}:LRA={lra}:measured_I={m['input_i']}:measured_TP={m['input_tp']}"
                    f":measured_LRA={m['input_lra']}:measured_thresh={m['input_thresh']}:offset={m['target_offset']}"
                    ":linear=true")
    subprocess.run([ffmpeg(), "-hide_banner", "-nostats", "-loglevel", "error", "-y", "-i", str(source),
                    "-af", audio_filter, *codec, "-b:a", bitrate, "-map_metadata", "-1", str(target)], check=True)
    return float(m["input_i"]), loudness(target)


def run(args, log=print):
    workflow = apply_sets(json.loads(Path(args.workflow).read_text(encoding="utf-8")), args.set)
    comfy = Comfy(args.server)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    try:
        prompt_id = comfy.queue(workflow, client_id=uuid.uuid4().hex)
    except PromptRejected as rejected:
        log(f"rejected: {rejected}")
        for node_id, errors in sorted(rejected.body.get("node_errors", {}).items()):
            for error in errors.get("errors", []):
                log(f"  node {node_id} ({errors.get('class_type')}): {error.get('message')}: {error.get('details')}")
        return 2
    log("queued")
    started = time.monotonic()
    entry = wait(comfy, prompt_id, args.timeout, args.poll, log)
    status = entry.get("status", {}).get("status_str")
    log(f"{status} after {time.monotonic() - started:.1f} s")
    if status != "success":
        return 1
    for node_id, item in saved_files(entry):
        name = Path(item["filename"]).name
        (out / name).write_bytes(comfy.view(item))
        log(f"node {node_id}: {item.get('subfolder', '')}/{item['filename']} -> {out / name}")
        if args.bitrate and Path(name).suffix in (".flac", ".wav", ".mp3", ".opus"):
            target = out / (Path(name).stem + ".opus")
            before, after = encode(out / name, target, args.lufs, args.bitrate)
            log(f"  {before:.1f} LUFS -> {target.name}, {after:.1f} LUFS, {target.stat().st_size} bytes")
    return 0


def batch(args, log=print):
    """Runs a list of workflows one after the other, each into its own folder, and says how long each took."""
    runs = json.loads(Path(args.runs).read_text(encoding="utf-8"))
    base = Path(args.runs).parent
    status = 0
    for item in runs:
        log(f"== {item['name']}")
        started = time.monotonic()
        code = run(argparse.Namespace(server=args.server, workflow=str(base / item["workflow"]), set=item.get("set", []),
                                      out=str(Path(args.out) / item["name"]), lufs=args.lufs, bitrate=args.bitrate,
                                      timeout=args.timeout, poll=args.poll), log)
        log(f"   exit {code}, {time.monotonic() - started:.1f} s with the download")
        status |= code
    return status


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    r = sub.add_parser("run")
    r.add_argument("server")
    r.add_argument("workflow")
    r.add_argument("--set", action="append", default=[])
    r.add_argument("--out", default="out")
    r.add_argument("--lufs", type=float, default=-16.0)
    r.add_argument("--bitrate", default="96k", help="Opus bit rate; empty to skip ffmpeg")
    r.add_argument("--timeout", type=float, default=1200)
    r.add_argument("--poll", type=float, default=1.0)
    b = sub.add_parser("batch")
    b.add_argument("server")
    b.add_argument("runs")
    b.add_argument("--out", default="out")
    b.add_argument("--lufs", type=float, default=-16.0)
    b.add_argument("--bitrate", default="")
    b.add_argument("--timeout", type=float, default=1200)
    b.add_argument("--poll", type=float, default=1.0)
    l = sub.add_parser("loudness")
    l.add_argument("file")
    e = sub.add_parser("encode")
    e.add_argument("source")
    e.add_argument("target")
    e.add_argument("--lufs", type=float, default=-16.0)
    e.add_argument("--bitrate", default="96k")
    args = parser.parse_args(argv)
    if args.command == "run":
        return run(args)
    if args.command == "batch":
        return batch(args)
    if args.command == "loudness":
        print(f"{loudness(args.file):.1f} LUFS")
        return 0
    before, after = encode(args.source, args.target, args.lufs, args.bitrate)
    print(f"{before:.1f} LUFS -> {after:.1f} LUFS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
