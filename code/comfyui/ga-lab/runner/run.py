"""Runs an experiment against a ComfyUI server that someone else started, one prompt at a time.

Exit codes: 0 every item done or recorded as could_not_run for a missing model; 2 bad experiment or arguments;
3 the server is unreachable or went away (rerun to resume); 4 the memory rule refused an item (the run stops there);
5 at least one item failed on the server (execution_error or rejected prompt).
"""
import datetime
import json
import os
import socket
import time
import uuid

from . import glb, memory, models, prepare, sheet
from .comfy import Comfy, PromptRejected, ServerDown
from .experiment import Experiment, ExperimentError, apply_sets, canonical, input_references, item_key, sha256_bytes, \
    sha256_file
from .stats import Poller
from .wsclient import WebSocket, WebSocketClosed

# ComfyUI releases and their commits: /system_stats reports the version, not the commit.
KNOWN_COMMITS = {"0.36.0": "ee71d5c4993f29086b27fde1629a945ae48425bf"}


def relative(path, start):
    """path relative to start with forward slashes, or absolute when they are on different Windows drives."""
    try:
        return os.path.relpath(path, start).replace("\\", "/")
    except ValueError:
        return os.path.abspath(path).replace("\\", "/")


def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")


def log(message):
    print(message, flush=True)


class Run:
    def __init__(self, args):
        self.args = args
        self.experiment = Experiment(args.experiment)
        lab = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        self.out = os.path.abspath(args.out or os.path.join(lab, "results", self.experiment.id))
        self.images_dir = args.images or os.path.join(self.out, "images")
        self.meshes_dir = getattr(args, "meshes", None) or os.path.join(self.out, "meshes")
        self.accepted = set(getattr(args, "accept_licence", None) or [])
        self.results_path = os.path.join(self.out, "results.json")
        self.comfy = Comfy(args.server, timeout=args.http_timeout)
        self.models_dirs = [os.path.abspath(d) for d in (args.models_dir or [])]
        self.hashes = models.HashCache(args.hash_cache or os.path.join(os.path.dirname(self.out), ".model-sha256.json"))
        self.loaded = set()
        self.last_models = None
        self.server_models = {}
        self.ws = None
        self.client_id = str(uuid.uuid4())
        self.results = None

    # ---------- results.json ----------
    def load_results(self):
        if os.path.isfile(self.results_path):
            with open(self.results_path, encoding="utf-8") as f:
                return json.load(f)
        return None

    def save(self):
        os.makedirs(self.out, exist_ok=True)
        tmp = self.results_path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(self.results, f, indent=1, ensure_ascii=False)
            f.write("\n")
        os.replace(tmp, self.results_path)

    # ---------- steps ----------
    def connect(self):
        try:
            stats = self.comfy.system_stats()
        except ServerDown as e:
            raise ServerDown(f"no ComfyUI server answers at {self.args.server} ({e}). This runner never starts one: "
                             f"start it yourself (see the report), then run the same command again.") from e
        system = stats.get("system", {})
        version = system.get("comfyui_version")
        return {
            "url": self.args.server,
            "comfyui_version": version,
            "comfyui_commit": self.args.comfyui_commit or KNOWN_COMMITS.get(version),
            "pytorch_version": system.get("pytorch_version"),
            "python_version": (system.get("python_version") or "").split(" ")[0],
            "os": system.get("os"),
            "devices": [{"name": d.get("name"), "type": d.get("type"), "vram_total": d.get("vram_total")}
                        for d in stats.get("devices") or []],
            "ram_total": system.get("ram_total"),
        }

    def prepare_inputs(self):
        prepared = {}
        for step in self.experiment.prepare:
            path = prepare.prepare(self.experiment, step, self.out)
            prepared[step["name"]] = {"path": path, "sha256": sha256_file(path)}
        return prepared

    def build(self, item, prepared):
        wf_path, workflow = self.experiment.workflow(item["workflow"])
        refs = input_references(item["sets"])
        hashed_sets, upload_sets = dict(item["sets"]), dict(item["sets"])
        for path, name in refs.items():
            if name not in prepared:
                raise ExperimentError(f"{self.experiment.path}: input {name!r} is not prepared")
            hashed_sets[path] = "sha256:" + prepared[name]["sha256"]
            upload_sets[path] = f"galab-{prepared[name]['sha256'][:16]}.png"
        rel = relative(wf_path, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        key = item_key({"prompt": apply_sets(workflow, hashed_sets, rel)})
        prompt = apply_sets(workflow, upload_sets, rel)
        return key, rel, prompt, refs

    def server_has(self, folder, name):
        if folder not in self.server_models:
            listed = self.comfy.models(folder)
            self.server_models[folder] = set(listed) if listed is not None else None
        listed = self.server_models[folder]
        return listed is None or name in listed

    def licence_block(self, prompt):
        """The licences this prompt's models need and the run was not told to accept (--accept-licence ID)."""
        names = {name for _, name in models.referenced_models(prompt)}
        return [lic for lic in self.experiment.licences
                if lic.get("requires_acceptance", True) and names & set(lic["models"]) and lic["id"] not in self.accepted]

    def fetch(self, v):
        """An output's bytes: from --comfyui-output when the server's output folder is on this machine, else /view."""
        local_root = getattr(self.args, "comfyui_output", None)
        if local_root and v.get("type", "output") == "output":
            path = os.path.join(local_root, v.get("subfolder", ""), v["filename"])
            if os.path.isfile(path):
                with open(path, "rb") as f:
                    return f.read(), "located"
        return self.comfy.view(v["filename"], v.get("subfolder", ""), v.get("type", "output")), "downloaded"

    def ensure_ws(self):
        """Opens the WebSocket before submitting, so no message of the prompt is missed."""
        if self.ws is None:
            try:
                self.ws = WebSocket(self.comfy.ws_url(self.client_id), timeout=self.args.http_timeout)
            except (WebSocketClosed, OSError) as e:
                raise ServerDown(f"websocket: {e}") from e

    def wait_for(self, prompt_id, timeout):
        """Follows the WebSocket until the prompt finishes. Returns (status, error, cached nodes, progress)."""
        deadline = time.monotonic() + timeout
        cached, progress, last_check = [], 0, time.monotonic()
        while True:
            if time.monotonic() > deadline:
                return "failed", f"no end of execution after {timeout} s", cached, progress
            try:
                if self.ws is None:
                    self.ws = WebSocket(self.comfy.ws_url(self.client_id), timeout=self.args.http_timeout)
                self.ws.settimeout(1.0)
                opcode, payload = self.ws.recv()
            except socket.timeout:
                if time.monotonic() - last_check > 5:
                    last_check = time.monotonic()
                    entry = self.comfy.history(prompt_id)  # raises ServerDown when the server is gone
                    if entry and entry.get("status", {}).get("completed") is not None:
                        status = entry["status"]
                        if status.get("status_str") == "error" or status.get("completed") is False:
                            return "failed", "the server reports an error (history)", cached, progress
                        return "done", None, cached, progress
                continue
            except (WebSocketClosed, ConnectionError, OSError) as e:
                self.ws = None
                self.comfy.system_stats()  # raises ServerDown if the server went away, else reconnect
                log(f"  websocket closed ({e}), reconnecting")
                continue
            if opcode != 1:
                continue  # binary previews
            message = json.loads(payload)
            data = message.get("data") or {}
            if data.get("prompt_id") not in (None, prompt_id):
                continue
            kind = message.get("type")
            if kind == "execution_cached":
                cached = data.get("nodes") or []
            elif kind == "progress":
                progress = max(progress, int(data.get("value") or 0))
            elif kind == "execution_error":
                return "failed", f"{data.get('node_type')} (node {data.get('node_id')}): " \
                                 f"{data.get('exception_type')}: {data.get('exception_message')}", cached, progress
            elif kind == "execution_interrupted":
                return "failed", "interrupted on the server", cached, progress
            elif kind == "execution_success":
                return "done", None, cached, progress
            elif kind == "executing" and data.get("node") is None and data.get("prompt_id") == prompt_id:
                return "done", None, cached, progress

    def download(self, prompt_id, key):
        entry = self.comfy.history(prompt_id) or {}
        outputs, texts = [], {}
        for node_id, out in sorted((entry.get("outputs") or {}).items()):
            for field, values in out.items():
                if field == "text":
                    texts[node_id] = values
                    continue
                if not isinstance(values, list):
                    continue
                for i, v in enumerate(values):
                    if not isinstance(v, dict) or "filename" not in v:
                        continue
                    data, how = self.fetch(v)
                    ext = os.path.splitext(v["filename"])[1] or ".png"
                    is_mesh = ext.lower() == ".glb"
                    local = os.path.join(self.meshes_dir if is_mesh else self.images_dir, f"{key}-{node_id}-{i}{ext}")
                    os.makedirs(os.path.dirname(local), exist_ok=True)
                    with open(local, "wb") as f:
                        f.write(data)
                    record = {"node": node_id, "server_filename": v["filename"], "subfolder": v.get("subfolder", ""),
                              "type": v.get("type", "output"), "file": local, "sha256": sha256_bytes(data),
                              "bytes": len(data), "fetched": how}
                    if is_mesh:
                        try:
                            record["glb"] = glb.inspect_bytes(data)
                            thumb_rel = f"thumbs/{key}-{node_id}-{i}.webp"
                            os.makedirs(os.path.join(self.out, "thumbs"), exist_ok=True)
                            glb.preview(data, os.path.join(self.out, thumb_rel))
                            record["thumb"] = thumb_rel
                        except (ValueError, KeyError, IndexError, TypeError) as e:  # GlbError is a ValueError
                            record["note"] = f"not a readable .glb: {e}"
                        outputs.append(record)
                        continue
                    try:
                        record.update(sheet.image_stats(local))
                        thumb_rel = f"thumbs/{key}-{node_id}-{i}.webp"
                        sheet.thumbnail(local, os.path.join(self.out, thumb_rel))
                        record["thumb"] = thumb_rel
                    except OSError as e:  # not an image Pillow reads (a video container, for example)
                        record["note"] = f"no thumbnail: {e}"
                    outputs.append(record)
        return outputs, texts

    # ---------- main loop ----------
    def execute(self):
        exp = self.experiment
        previous = self.load_results()
        server = self.connect()
        items = exp.items()
        log(f"{exp.id}: {len(items)} items, server {server['url']} ComfyUI {server['comfyui_version']}")
        prepared = self.prepare_inputs()
        by_key = {i["key"]: i for i in (previous or {}).get("items", [])}
        self.results = {
            "experiment": {"id": exp.id, "title": exp.data["title"], "written": str(exp.data["written"]),
                           "hypothesis": exp.data["hypothesis"], "prediction": exp.data["prediction"],
                           "file": os.path.basename(exp.path), "sha256": exp.sha256},
            "axes": exp.axes,
            "server": server,
            "memory_rule": {"margin_gb": self.args.margin_gb, "extra_gb": exp.extra_memory_gb,
                            "min_free_vram_gb": self.args.min_free_vram_gb,
                            "method": "see runner/memory.py"},
            "licences": exp.licences,
            "inputs": {k: {"file": relative(v["path"], self.out), "sha256": v["sha256"]}
                       for k, v in prepared.items()},
            "runs": (previous or {}).get("runs", []),
            "items": [],
        }
        run_record = {"started": now(), "server": server, "argv_models_dirs": self.models_dirs,
                      "accepted_licences": sorted(self.accepted), "meshes_dir": self.meshes_dir}
        self.results["runs"].append(run_record)
        plan = []
        for item in items:
            key, rel, prompt, refs = self.build(item, prepared)
            old = by_key.get(key)
            record = old if old and old.get("status") == "done" else {
                "key": key, "labels": item["labels"], "seed": item["seed"], "workflow": rel,
                "params": item["sets"], "status": "pending"}
            self.results["items"].append(record)
            plan.append((record, prompt, refs))
        self.save()

        exit_code, uploaded = 0, {}
        done_before = sum(1 for r, _, _ in plan if r["status"] == "done")
        if done_before:
            log(f"  resuming: {done_before} item(s) already done, skipped")
        count = 0
        try:
            for record, prompt, refs in plan:
                if record["status"] == "done":
                    continue
                if self.args.limit and count >= self.args.limit:
                    break
                count += 1
                label = ", ".join(f"{k}={v}" for k, v in record["labels"].items()) + f", seed={record['seed']}"
                log(f"- {record['key']} {label}")
                blocked = self.licence_block(prompt)
                if blocked:
                    record.update(status="could_not_run", error="licence not accepted: " + "; ".join(
                        f"{lic['id']} ({lic.get('name', '')}, {lic.get('url', '')}): read it, then pass "
                        f"--accept-licence {lic['id']}" for lic in blocked))
                    log(f"  could not run: {record['error']}")
                    self.save()
                    continue
                described = models.describe(prompt, self.models_dirs, self.hashes)
                record["models"] = [{k: m[k] for k in ("folder", "name", "bytes", "sha256")} for m in described]
                missing = [m for m in described if not m["path"]] + \
                          [m for m in described if m["path"] and not self.server_has(m["folder"], m["name"])]
                if missing:
                    names = ", ".join(sorted({f"{m['folder']}/{m['name']}" for m in missing}))
                    where = "under --models-dir" if any(not m["path"] for m in missing) else "on the server"
                    record.update(status="could_not_run", error=f"model file not found {where}: {names}")
                    log(f"  could not run: {record['error']}")
                    self.save()
                    continue
                needed = {(m["folder"], m["name"]) for m in described}
                if self.last_models is not None and needed != self.last_models and not self.args.no_free:
                    self.comfy.free()
                    self.loaded = set()
                    time.sleep(self.args.free_wait)
                decision = memory.check(described, self.comfy.system_stats(), self.loaded, self.args.margin_gb,
                                        self.experiment.extra_memory_gb, self.args.min_free_vram_gb)
                record["memory_check"] = decision
                if not decision["ok"]:
                    record.update(status="could_not_run", error="; ".join(decision["reasons"]))
                    log(f"  refused: {record['error']}")
                    self.save()
                    exit_code = 4
                    break
                for path, name in refs.items():
                    sha = self.results["inputs"][name]["sha256"]
                    if sha not in uploaded:
                        uploaded[sha] = self.comfy.upload_image(os.path.join(self.out, self.results["inputs"][name]["file"]),
                                                                f"galab-{sha[:16]}.png")
                prompt_id = str(uuid.uuid4())
                poller = Poller(self.comfy, self.args.poll_interval)
                record.update(status="running", prompt_id=prompt_id, started_at=now())
                self.save()
                self.ensure_ws()
                poller.start()
                t0 = time.perf_counter()
                try:
                    try:
                        self.comfy.submit(prompt, self.client_id, prompt_id)
                    except PromptRejected as e:
                        record.update(status="failed", error=f"prompt rejected: {e}")
                        exit_code = 5
                        self.save()
                        continue
                    status, error, cached, progress = self.wait_for(prompt_id, self.args.item_timeout)
                    wall = time.perf_counter() - t0
                finally:
                    record["memory"] = poller.stop()
                record.update(wall_time_s=round(wall, 3), cached_nodes=cached, steps_seen=progress)
                if status != "done":
                    record.update(status="failed", error=error)
                    exit_code = 5
                    self.save()
                    continue
                outputs, texts = self.download(prompt_id, record["key"])
                record.update(status="done", outputs=outputs, texts=texts, finished_at=now(), error=None)
                for o in outputs:
                    o["file"] = relative(o["file"], self.out) \
                        if os.path.abspath(o["file"]).startswith(self.out + os.sep) else o["file"]
                self.loaded |= needed
                self.last_models = needed
                log(f"  done in {wall:.2f} s, {len(outputs)} output(s)")
                self.save()
        except ServerDown as e:
            for record, _, _ in plan:
                if record["status"] == "running":
                    record.update(status="interrupted", error=f"server went away: {e}")
            log(f"server went away: {e}\nNothing more is submitted. Start the server again and rerun the same "
                f"command: done items are skipped.")
            exit_code = 3
        finally:
            if self.ws:
                self.ws.close()
            run_record["finished"] = now()
            run_record["exit_code"] = exit_code
            self.save()
            try:
                sheet.contact_sheet(self.results, self.out, os.path.join(self.out, "sheet.webp"))
            except OSError as e:
                log(f"contact sheet not written: {e}")
        states = {}
        for r in self.results["items"]:
            states[r["status"]] = states.get(r["status"], 0) + 1
        log(f"{exp.id}: " + ", ".join(f"{v} {k}" for k, v in sorted(states.items())) + f" -> {self.results_path}")
        return exit_code


def run(args):
    try:
        return Run(args).execute()
    except ExperimentError as e:
        log(f"error: {e}")
        return 2
    except ServerDown as e:
        log(str(e))
        return 3
