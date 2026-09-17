"""Peak memory while a prompt runs, sampled from GET /system_stats.

Method: a thread polls /system_stats every `interval` seconds from just before the prompt is submitted until its
outputs are listed, and keeps the lowest ram_free and vram_free seen. Peak used = total - lowest free.

Limits, written into results.json with the numbers:
- a sample every 0.5 s misses shorter spikes, such as a VAE decode that allocates and frees in 200 ms;
- ram_free is the whole machine's available memory: other programs count too, so compare with the baseline;
- vram_free is torch.cuda.mem_get_info's free memory plus what PyTorch reserved but doesn't use (ComfyUI's
  get_free_memory), for the whole device: other processes count too;
- the server answers from its event loop while the prompt runs in another thread; a busy GIL can delay answers,
  so the number of samples is recorded too.
"""
import threading
import time

from .comfy import ServerDown


class Poller:
    def __init__(self, comfy, interval=0.5):
        self.comfy = comfy
        self.interval = interval
        self.samples = 0
        self.errors = 0
        self.ram_total = self.vram_total = None
        self.ram_min = self.vram_min = None
        self.baseline = None
        self._stop = threading.Event()
        self._thread = None

    def _sample(self):
        try:
            stats = self.comfy.system_stats()
        except ServerDown:
            self.errors += 1
            return None
        system = stats.get("system", {})
        devices = stats.get("devices") or [{}]
        ram_free, vram_free = system.get("ram_free"), devices[0].get("vram_free")
        self.ram_total, self.vram_total = system.get("ram_total"), devices[0].get("vram_total")
        if ram_free is not None:
            self.ram_min = ram_free if self.ram_min is None else min(self.ram_min, ram_free)
        if vram_free is not None:
            self.vram_min = vram_free if self.vram_min is None else min(self.vram_min, vram_free)
        self.samples += 1
        return ram_free, vram_free

    def start(self):
        first = self._sample()
        if first:
            self.baseline = {"ram_used_bytes": _used(self.ram_total, first[0]),
                             "vram_used_bytes": _used(self.vram_total, first[1])}
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def _run(self):
        while not self._stop.wait(self.interval):
            self._sample()

    def stop(self):
        self._stop.set()
        if self._thread:
            self._thread.join(timeout=self.interval * 4 + 30)
        return {
            "method": "min free memory over GET /system_stats polls; see runner/stats.py for the limits",
            "interval_s": self.interval,
            "samples": self.samples,
            "failed_samples": self.errors,
            "baseline": self.baseline,
            "peak_ram_used_bytes": _used(self.ram_total, self.ram_min),
            "peak_vram_used_bytes": _used(self.vram_total, self.vram_min),
            "ram_total_bytes": self.ram_total,
            "vram_total_bytes": self.vram_total,
        }


def _used(total, free):
    return None if total is None or free is None else total - free
