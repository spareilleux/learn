// The chord explorer in TypeScript, bundled by Vite (lessons 19 to 21).
// Same commands and events as ui/main.js, which lessons 16 to 18 use without a bundler.
import { listen } from "@tauri-apps/api/event";
import { save } from "@tauri-apps/plugin-dialog";
import { writeTextFile } from "@tauri-apps/plugin-fs";
import * as api from "./api";
import type { ChordView } from "./bindings/ChordView";
import type { ScaleMode } from "./bindings/ScaleMode";
import "./styles.css";

const MAX_LISTED = 200;

function element<T extends HTMLElement>(id: string): T {
  const found = document.getElementById(id);
  if (!found) throw new Error(`#${id} is missing from index.html`);
  return found as T;
}

const chordInput = element<HTMLInputElement>("chord-input");
const chordOutput = element("chord-output");
const chordError = element("chord-error");

async function spell(symbol: string) {
  chordError.textContent = "";
  try {
    showChord(await api.spellChord(symbol));
  } catch (error) {
    chordOutput.textContent = "";
    chordError.textContent = api.describe(error);
  }
}

function showChord(chord: ChordView) {
  chordInput.value = chord.symbol;
  chordOutput.textContent = `${chord.symbol} (${chord.qualityName}): ${chord.notes.join(" ")}  —  ${chord.intervals.join(" ")}`;
}

async function transpose(semitones: number) {
  try {
    showChord(await api.transposeChord(chordInput.value, semitones));
  } catch (error) {
    chordError.textContent = api.describe(error);
  }
}

async function showKey() {
  const list = element("key-chords");
  list.replaceChildren();
  try {
    const mode = element<HTMLSelectElement>("mode-select").value as ScaleMode;
    const chords = await api.diatonicChords(element<HTMLInputElement>("tonic-input").value, mode);
    list.append(...chords.map((chord) => chip(chord.symbol)));
  } catch (error) {
    list.textContent = api.describe(error);
  }
}

function chip(symbol: string) {
  const button = document.createElement("button");
  button.type = "button";
  button.textContent = symbol;
  button.addEventListener("click", () => spell(symbol));
  return button;
}

function showFavorites(symbols: string[]) {
  const list = element("favorites");
  if (symbols.length === 0) {
    const none = document.createElement("span");
    none.className = "muted";
    none.textContent = "none yet";
    list.replaceChildren(none);
  } else {
    list.replaceChildren(...symbols.map(chip));
  }
}

async function toggleFavorite() {
  try {
    await api.toggleFavorite(chordInput.value);
  } catch (error) {
    chordError.textContent = api.describe(error);
  }
}

// Lesson 20: the dialog and fs plugins, allowed by capabilities/export.json
async function exportFavorites() {
  const status = element("export-status");
  try {
    const path = await save({
      defaultPath: "favorites.txt",
      filters: [{ name: "Text", extensions: ["txt"] }],
    });
    if (path === null) {
      status.textContent = "export cancelled";
      return;
    }
    const symbols = await api.favorites();
    await writeTextFile(path, symbols.join("\n") + "\n");
    status.textContent = `${symbols.length} favorites written to ${path}`;
  } catch (error) {
    status.textContent = api.describe(error);
  }
}

async function search() {
  const list = element("voicings");
  const status = element("search-status");
  const progress = element<HTMLProgressElement>("progress");
  list.replaceChildren();
  progress.value = 0;
  element<HTMLButtonElement>("search").disabled = true;
  element<HTMLButtonElement>("cancel").disabled = false;
  status.textContent = "searching…";

  try {
    const span = Number(element<HTMLSelectElement>("span-select").value);
    await api.findVoicings(chordInput.value, span, (message) => {
      // SearchEvent is a union discriminated by `event`: each case narrows `data`
      switch (message.event) {
        case "voicings":
          for (const frets of message.data.frets) {
            if (list.children.length < MAX_LISTED) {
              const item = document.createElement("li");
              item.textContent = frets;
              list.append(item);
            }
          }
          break;
        case "progress":
          progress.value = message.data.done / message.data.total;
          break;
        case "finished": {
          const { found, elapsedMs, cancelled } = message.data;
          const shown = Math.min(found, MAX_LISTED);
          status.textContent = `${found} voicings in ${elapsedMs} ms${cancelled ? " (cancelled)" : ""}, ${shown} shown`;
          break;
        }
      }
    });
  } catch (error) {
    status.textContent = api.describe(error);
  } finally {
    element<HTMLButtonElement>("search").disabled = false;
    element<HTMLButtonElement>("cancel").disabled = true;
  }
}

window.addEventListener("DOMContentLoaded", async () => {
  element("chord-form").addEventListener("submit", (event) => {
    event.preventDefault();
    spell(chordInput.value);
  });
  element("down").addEventListener("click", () => transpose(-1));
  element("up").addEventListener("click", () => transpose(1));
  element("favorite").addEventListener("click", toggleFavorite);
  element("export").addEventListener("click", exportFavorites);
  element("key-form").addEventListener("submit", (event) => {
    event.preventDefault();
    showKey();
  });
  element("search-form").addEventListener("submit", (event) => {
    event.preventDefault();
    search();
  });
  element("cancel").addEventListener("click", () => api.cancelSearch());

  await listen<string[]>("favorites-changed", (event) => showFavorites(event.payload));
  showFavorites(await api.favorites());
  const qualities = await api.chordQualities();
  element("qualities").textContent =
    "Qualities: " + qualities.map((q) => `${q.suffix || "(none)"} ${q.name}`).join(", ");
  spell(chordInput.value);
  showKey();
});
