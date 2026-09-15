// window.__TAURI__ exists because tauri.conf.json sets app.withGlobalTauri to true
const { invoke, Channel } = window.__TAURI__.core;
const { listen } = window.__TAURI__.event;

const $ = (id) => document.getElementById(id);
const MAX_LISTED = 200;

// Lesson 17: commands

// A rejected invoke gives our CommandError, { kind, message }, or a plain string
// when Tauri itself refuses the call (unknown command, invalid arguments)
function describe(error) {
  return typeof error === "string" ? error : `${error.kind}: ${error.message}`;
}

async function spell(symbol) {
  $("chord-error").textContent = "";
  try {
    const chord = await invoke("spell_chord", { symbol });
    showChord(chord);
  } catch (error) {
    $("chord-output").textContent = "";
    $("chord-error").textContent = describe(error);
  }
}

function showChord(chord) {
  $("chord-input").value = chord.symbol;
  $("chord-output").textContent =
    `${chord.symbol} (${chord.qualityName}): ${chord.notes.join(" ")}  —  ${chord.intervals.join(" ")}`;
}

async function transpose(semitones) {
  try {
    showChord(await invoke("transpose_chord", { symbol: $("chord-input").value, semitones }));
  } catch (error) {
    $("chord-error").textContent = describe(error);
  }
}

async function showKey() {
  const list = $("key-chords");
  list.replaceChildren();
  try {
    const chords = await invoke("diatonic_chords", {
      tonicNote: $("tonic-input").value,
      mode: $("mode-select").value,
    });
    for (const chord of chords) {
      list.append(chip(chord.symbol));
    }
  } catch (error) {
    list.textContent = describe(error);
  }
}

function chip(symbol) {
  const button = document.createElement("button");
  button.type = "button";
  button.textContent = symbol;
  button.addEventListener("click", () => spell(symbol));
  return button;
}

// Lesson 18: state and events

function showFavorites(symbols) {
  const list = $("favorites");
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
    await invoke("toggle_favorite", { symbol: $("chord-input").value });
    // No need to use the result: the favorites-changed event updates the list
  } catch (error) {
    $("chord-error").textContent = describe(error);
  }
}

// Lesson 18: channels

async function search() {
  const list = $("voicings");
  const status = $("search-status");
  list.replaceChildren();
  $("progress").value = 0;
  $("search").disabled = true;
  $("cancel").disabled = false;
  status.textContent = "searching…";

  const onEvent = new Channel();
  onEvent.onmessage = (message) => {
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
        $("progress").value = message.data.done / message.data.total;
        break;
      case "finished": {
        const { found, elapsedMs, cancelled } = message.data;
        const shown = Math.min(found, MAX_LISTED);
        status.textContent = `${found} voicings in ${elapsedMs} ms${cancelled ? " (cancelled)" : ""}, ${shown} shown`;
        break;
      }
    }
  };

  try {
    await invoke("find_voicings", {
      symbol: $("chord-input").value,
      maxSpan: Number($("span-select").value),
      onEvent,
    });
  } catch (error) {
    status.textContent = describe(error);
  } finally {
    $("search").disabled = false;
    $("cancel").disabled = true;
  }
}

async function countOnMainThread() {
  const status = $("search-status");
  status.textContent = "counting on the main thread…";
  const started = performance.now();
  try {
    const found = await invoke("count_voicings_blocking", { symbol: $("chord-input").value });
    status.textContent = `${found} voicings, ${Math.round(performance.now() - started)} ms with the main thread blocked`;
  } catch (error) {
    status.textContent = describe(error);
  }
}

window.addEventListener("DOMContentLoaded", async () => {
  $("chord-form").addEventListener("submit", (event) => {
    event.preventDefault();
    spell($("chord-input").value);
  });
  $("down").addEventListener("click", () => transpose(-1));
  $("up").addEventListener("click", () => transpose(1));
  $("favorite").addEventListener("click", toggleFavorite);
  $("key-form").addEventListener("submit", (event) => {
    event.preventDefault();
    showKey();
  });
  $("search-form").addEventListener("submit", (event) => {
    event.preventDefault();
    search();
  });
  $("cancel").addEventListener("click", () => invoke("cancel_search"));
  $("blocking").addEventListener("click", countOnMainThread);

  // Every window receives favorites-changed, whichever window changed the list
  await listen("favorites-changed", (event) => showFavorites(event.payload));
  showFavorites(await invoke("favorites"));
  const qualities = await invoke("chord_qualities");
  $("qualities").textContent =
    "Qualities: " + qualities.map((q) => `${q.suffix || "(none)"} ${q.name}`).join(", ");
  spell($("chord-input").value);
  showKey();
});
