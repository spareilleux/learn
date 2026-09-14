"""Word timings of the pre-generated narration MP3s, for the narration player to follow the audio on the page.

The player highlights the sentence and the word being said and starts from any section: it matches these words
to the words of the page. Whisper transcribes each MP3 with word timestamps (the words don't need to be exact).

Run it with the Whisper environment of the TTS workspace (GPU), e.g. on Windows:

    %TTS_LAB%\\asr-venv\\Scripts\\python.exe scripts\\audio-timings.py

Options:
    --audio DIR   local copy of the MP3s, mirroring their URL paths (default: $TTS_LAB/learn-audio, TTS_LAB defaults to ~/tts-lab)
    --model NAME  Whisper model (default: turbo)
    --force       redo pages whose timings already match the manifest's hash

Writes src/data/audio-timings/<locale>/<slug>.json = { hash, words: [[centiseconds, word], ...] }.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MANIFEST = REPO / "src/data/audio-manifest.json"
OUT = REPO / "src/data/audio-timings"
BASE_URL = "https://spareilleux.github.io/learn-audio/"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    lab = Path(os.environ.get("TTS_LAB", Path.home() / "tts-lab"))
    ap.add_argument("--audio", type=Path, default=lab / "learn-audio")
    ap.add_argument("--model", default="turbo")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    model = None
    for key, entry in manifest.items():
        out = OUT / f"{key}.json"
        if not args.force and out.exists() and json.loads(out.read_text(encoding="utf-8")).get("hash") == entry["hash"]:
            continue
        mp3 = args.audio / entry["src"].removeprefix(BASE_URL)
        if not mp3.exists():
            print(f"{key}: missing {mp3}", file=sys.stderr)
            continue
        if model is None:
            import whisper

            model = whisper.load_model(args.model)
        result = model.transcribe(str(mp3), language=key.split("/")[0], word_timestamps=True, condition_on_previous_text=False)
        words = [[round(w["start"] * 100), w["word"].strip()] for s in result["segments"] for w in s.get("words", []) if w["word"].strip()]
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps({"hash": entry["hash"], "words": words}, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
        print(f"{key}: {len(words)} words", flush=True)


if __name__ == "__main__":
    sys.exit(main())
