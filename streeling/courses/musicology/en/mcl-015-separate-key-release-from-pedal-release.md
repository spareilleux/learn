---
module_id: mcl-015-separate-key-release-from-pedal-release
department: musicology
course: "Separate Key Release from Pedal Release"
level: advanced
prerequisites: ["mcl-012-merge-ties-without-merging-slurs"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Separate Key Release from Pedal Release

> Authored model and source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening, parser execution, engine render or production adoption is claimed.

A practice accompaniment can keep a note under pedal after its key is released. Treating key release as immediate sound termination shortens the intended scheduler hold; treating every later note as held can extend too much. For a [GA](https://github.com/GuitarAlchemist/ga) accompaniment handoff, we track the release command explicitly and keep the acoustic decay tail outside the model.

## Read the retained evidence

The playback reference distinguishes a damper-pedal setting from a note event. The retained timed-event packet has explicit note endpoints but no pedal-release rule. Our state rule extends that representation as an authored proposal, without changing an importer or claiming piano behavior from a guitar engine.

[Prerequisite](../../musicology/en/mcl-012-merge-ties-without-merging-slurs.md)

[Retained project artifact](../../../../code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Primary reading](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/sound/)

## Fixed case and prepared quantities

```json
{
  "values": {
    "notes": [
      {
        "id": "a",
        "on": 0,
        "key_off": 0.5
      },
      {
        "id": "b",
        "on": 1,
        "key_off": 1.5
      }
    ],
    "pedal_down": 0.25,
    "pedal_up": 2
  },
  "formula": "release_i=pedal_up if pedal_down<=key_off_i<pedal_up else key_off_i; scheduled_hold_i=release_i-on_i",
  "expected": {
    "release_times": [
      2,
      2
    ],
    "scheduled_holds": [
      2,
      1
    ]
  },
  "negative_control": {
    "values": {
      "notes": [
        {
          "id": "a",
          "on": 0,
          "key_off": 0.5
        },
        {
          "id": "b",
          "on": 1,
          "key_off": 1.5
        }
      ],
      "pedal_down": 0.25,
      "pedal_up": 0.75
    },
    "expected": {
      "release_times": [
        0.75,
        1.5
      ],
      "scheduled_holds": [
        0.75,
        0.5
      ]
    }
  }
}
```

## State which boundary the event actually controls

The retained event endpoints describe authored note intervals, not measurements of silence. Introducing pedal state adds another scheduling layer. Key-off says that the key action ended, while the selected rule decides when the damper permits release. The eventual acoustic envelope is another process. A reliable handoff names these boundaries rather than giving all of them a single ambiguous duration field.

This lesson deliberately avoids simultaneous-event precedence and repeated instances of the same pitch. Both become important in a full scheduler. A pedal change coincident with key-off requires an ordering policy, and a repeated pitch requires identities so one event’s release does not terminate another accidentally. The present distinct times and identifiers make those inputs unnecessary for the small calculation; they do not prove that a future implementation handles the excluded cases.

Nor should the damper metaphor be silently transferred to a physical guitar. A player’s release, mute action and string resonance obey different mechanisms from a keyboard pedal. The useful commonality is the need to retain an explicit action boundary. A direct timeline is enough to show why dropping pedal state loses the authored release schedule. Before an agent expands this into a multi-instrument DSL, compare the candidate record with that timeline and list the extra semantics each instrument would actually need.

### Exercise 1

Identify the release-related events for each main note. Are key release and scheduled release identical?

<details><summary>Answer 1</summary>

They are different in the main case. Both key releases occur while the damper is down, so the authored rule holds their release commands until pedal-up.

</details>

### Exercise 2

Compute the main release times and scheduled hold durations.

<details><summary>Answer 2</summary>

The arrays appear above. Subtract each onset from its scheduled release; do not subtract the first onset from every note or replace note identity with pitch alone.

</details>

### Exercise 3

Does a scheduled release mean the acoustic waveform becomes zero at that instant?

<details><summary>Answer 3</summary>

No. It marks a command boundary. An envelope or physical instrument can continue decaying afterward, and no tail was supplied or measured.

</details>

### Exercise 4

Apply the early pedal-up control. Why is the later note not extended?

<details><summary>Answer 4</summary>

Its key release occurs after pedal-up. The first note remains extended to the earlier pedal boundary, while the later note releases at its own key-off.

</details>

### Exercise 5

What rejects an export claiming to preserve the release schedule?

<details><summary>Answer 5</summary>

Omitting the pedal interval or giving the main and control cases identical release arrays loses the required distinction. Actual acoustic fidelity needs another observation.

</details>

## Source-assisted learner task

Draw a state timeline manually for each note and pedal. Inspect the retained endpoint meaning, then propose a separate release-command record. Use the control to challenge an export before suggesting playback automation; leave real decay and sustained guitar technique unassessed.

First retain your unaided derivation before revealing the answers. Then inspect a specific source passage and its revision, record every kind of assistance, and keep the original and corrected responses separately. Use the direct manual result as the baseline for any calculator, DSL or agent proposal. Missing inputs stay unresolved. The fixed packet holds a prepared criterion for each exercise with no learner decision. A correct model answer supports only the declared case; acceptance needs an actual attempt and review. Record a falsifier before choosing an abstraction, then state the additional runtime or human evidence needed at the next boundary.
