#!/usr/bin/env python3
"""Lesson 15: word error rate of a speech clip, from a Whisper transcription.

    python wer.py --model DIR --lang fr --text "expected sentence" FILE
    python wer.py --pairs pairs.json --model DIR     [{"file": ..., "lang": ..., "text": ...}, ...]

WER = (substitutions + deletions + insertions) / words in the reference, after lowercasing, removing
punctuation, turning typographic apostrophes into plain ones, and splitting on spaces. Whisper's own mistakes count
too, so a WER is an upper bound on what the TTS got wrong: listen to the clips before concluding.
"""
import argparse
import json
import re
import sys
import unicodedata


def normalize(text):
    text = unicodedata.normalize("NFC", text).lower().replace("’", "'")
    text = re.sub(r"[^\w\s']", " ", text)
    text = text.replace("'", "' ")
    return text.split()


def word_errors(reference, hypothesis):
    """Levenshtein distance on words: returns (errors, reference length)."""
    ref, hyp = normalize(reference), normalize(hypothesis)
    previous = list(range(len(hyp) + 1))
    for i, r in enumerate(ref, 1):
        current = [i]
        for j, h in enumerate(hyp, 1):
            current.append(min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + (r != h)))
        previous = current
    return previous[-1], len(ref)


def wer(reference, hypothesis):
    errors, words = word_errors(reference, hypothesis)
    return errors / max(words, 1)


def transcribe(model, path, lang):
    segments, _ = model.transcribe(path, language=lang, beam_size=5, temperature=0.0, vad_filter=False)
    return " ".join(s.text.strip() for s in segments)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("file", nargs="?")
    parser.add_argument("--text")
    parser.add_argument("--lang")
    parser.add_argument("--pairs")
    parser.add_argument("--model", required=True, help="a faster-whisper model folder")
    parser.add_argument("--device", default="cpu")
    args = parser.parse_args(argv)
    from faster_whisper import WhisperModel
    model = WhisperModel(args.model, device=args.device, compute_type="int8" if args.device == "cpu" else "float16")
    pairs = json.load(open(args.pairs, encoding="utf-8")) if args.pairs else [
        {"file": args.file, "lang": args.lang, "text": args.text}]
    for pair in pairs:
        heard = transcribe(model, pair["file"], pair["lang"])
        errors, words = word_errors(pair["text"], heard)
        print(json.dumps({"file": pair["file"], "lang": pair["lang"], "wer": round(errors / max(words, 1), 3),
                          "errors": errors, "words": words, "heard": heard}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
