// Lesson 21: the frontend's calls tested without Rust. mockIPC replaces the IPC layer,
// so these tests check what the page sends and how it reads the answers (texts from lesson 17).
import { clearMocks, mockIPC } from "@tauri-apps/api/mocks";
import type { Channel } from "@tauri-apps/api/core";
import { afterEach, expect, test } from "vitest";
import * as api from "./api";
import type { SearchEvent } from "./bindings/SearchEvent";

afterEach(() => clearMocks());

test("spellChord sends the symbol and returns the command's value", async () => {
  const calls: [string, unknown][] = [];
  mockIPC((cmd, args) => {
    calls.push([cmd, args]);
    return { symbol: "Am7", qualityName: "minor seventh", notes: ["A", "C", "E", "G"], intervals: ["P1", "m3", "P5", "m7"] };
  });

  const chord = await api.spellChord("Am7");

  expect(calls).toEqual([["spell_chord", { symbol: "Am7" }]]);
  expect(chord.notes).toEqual(["A", "C", "E", "G"]);
});

test("a rejected command is a CommandError, a refused call is a string", async () => {
  mockIPC((cmd) => {
    if (cmd === "spell_chord") throw { kind: "unknownQuality", message: "unknown chord quality `m9` in `Cm9`" };
    throw "Command play_chord not found";
  });

  const invalid = await api.spellChord("Cm9").catch((error: unknown) => error);
  const refused = await api.favorites().catch((error: unknown) => error);

  expect(api.describe(invalid)).toBe("unknownQuality: unknown chord quality `m9` in `Cm9`");
  expect(api.describe(refused)).toBe("Command play_chord not found");
});

test("findVoicings passes each channel message to the callback", async () => {
  mockIPC((cmd, args) => {
    if (cmd !== "find_voicings") return;
    const { onEvent, maxSpan } = args as { onEvent: Channel<SearchEvent>; maxSpan: number };
    onEvent.onmessage({ event: "voicings", data: { frets: ["x32010"] } });
    onEvent.onmessage({ event: "finished", data: { found: 1, elapsedMs: 3, cancelled: false } });
    return maxSpan;
  });

  const received: string[] = [];
  const result = await api.findVoicings("C", 4, (message) => received.push(message.event));

  expect(result).toBe(4);
  expect(received).toEqual(["voicings", "finished"]);
});
