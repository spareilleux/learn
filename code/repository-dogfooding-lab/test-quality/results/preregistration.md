# Pre-registration: property tests on `PitchParser.TryParse`, measured with Stryker.NET

Written 2026-09-26, before any build, test run or mutation run of this lab. The user confirmed the seam (only `PitchParser.TryParse`, through its public callers; valid inputs, malformed inputs, no exceptions; no production change). Its SHA-256 is recorded in the coordinator's host progress file at the time of writing. If this text is edited after measuring, the edit is marked as such below.

## Code under test

- GuitarAlchemist/ga at `aa22f9101d5bb86800ff2819381f97986fc81fb1` (origin/main on 2026-09-26), unchanged.
- The file is [`Common/GA.Domain.Core/Primitives/Notes/PitchParser.cs`](https://github.com/GuitarAlchemist/ga/blob/aa22f9101d5bb86800ff2819381f97986fc81fb1/Common/GA.Domain.Core/Primitives/Notes/PitchParser.cs). The class is `internal`. Its only callers are the public `Pitch.Sharp.TryParse` and `Pitch.Flat.TryParse` ([`Pitch.cs:114`](https://github.com/GuitarAlchemist/ga/blob/aa22f9101d5bb86800ff2819381f97986fc81fb1/Common/GA.Domain.Core/Primitives/Notes/Pitch.cs#L114), [`:285`](https://github.com/GuitarAlchemist/ga/blob/aa22f9101d5bb86800ff2819381f97986fc81fb1/Common/GA.Domain.Core/Primitives/Notes/Pitch.cs#L285)). The lab tests only these public entry points. There is no `InternalsVisibleTo`, and no reflection.

## Question

Do GA's existing deterministic tests leave mutants of `PitchParser.cs` alive, and if so, does one small generative test through the public API kill any of them? The test checks three things:
- valid pitches parse and print canonically;
- malformed strings are refused;
- no input throws.

## Baseline and treatment

- **Baseline (B):** Stryker.NET with GA's own test project `Tests/GA.Domain.Core.Tests`, unchanged, mutating `**/Primitives/Notes/PitchParser.cs` only.
- **Treatment (T):** the same command and the same mutate filter, with the lab's test project added as a second `--test-project`. GA's tests are not edited.

## Detection criterion

- Stryker's per-mutant status on `PitchParser.cs`: Killed, Survived, NoCoverage, Timeout, CompileError, Ignored.
- A mutant counts as detected only if it is **Killed**. Timeouts are reported separately and not counted as kills.
- The denominator is every mutant Stryker generates in the file, with each status shown.

## Hypotheses, written before measuring

- **H1:** B leaves at least one mutant of `PitchParser.cs` Survived or NoCoverage. Expected candidates are the defensive checks the regex already guarantees (`!noteGroup.IsDefined`, `!octaveGroup.IsDefined`, `int.TryParse` of a matched octave). Those may be equivalent mutants, which no test can kill.
- **H2:** T kills at least one mutant that B left alive, without asserting anything beyond the public contract GA's existing tests already state:
  - the result of `TryParse`;
  - `ToString()` of the parsed pitch, canonical form "C#4" / "Bb3";
  - case-insensitivity of the letter;
  - octave range -1..9;
  - one accidental of the parser's own kind.
- **H3:** no generated input, including null, empty, whitespace and arbitrary Unicode, makes either `TryParse` throw, over 10,000 cases per property. A counterexample would be preserved and reported, not fixed.

## Generators and oracles (public contract only)

- **Valid:**
  - letter A–G, random case;
  - optionally the parser's accidental, `#` for Sharp and `b` for Flat (only the letter's case is varied; the accidental's case is not stated by GA's tests);
  - octave from -1 to 9.
  - Oracle: `TryParse` is true, and `ToString()` equals the upper-case letter, then the accidental, then the octave.
- **Malformed:** a valid string broken by one edit from a closed list, each invalid by construction:
  - prepend or append a character that cannot extend a pitch (a letter, a space, another accidental, a digit after a two-digit form);
  - octave outside -1..9;
  - the other parser's accidental;
  - a doubled accidental;
  - no octave.
  - Oracle: `TryParse` is false.
- **Any string:** FsCheck's default string generator, plus null.
  - Oracle: no exception.
  - Also: if `TryParse` is true, parsing `ToString()` again is true and prints the same text.
- **Seed:** FsCheck `Replay` fixed at the seed printed in the results; 10,000 cases per property (`MaxTest = 10000`). A failing run prints its seed and shrunk counterexample.
- **Negative control:** an isolated property, in its own test category and excluded from the Stryker run, that asserts something false. The claim is that Sharp and Flat accept exactly the same strings. It must fail, shrink to a short counterexample, and replay to the same counterexample from the printed seed. It shows that the harness can fail; it is not a finding about GA.

## Tool versions

- .NET SDK: whatever `global.json` (10.0.104, latestFeature) resolves on the machine; the resolved version is recorded.
- dotnet-stryker 5.0.0, as a local tool manifest.
- FsCheck 3.4.0 and FsCheck.NUnit 3.4.0.
- NUnit and the test SDK at the versions GA's test project already uses (NUnit 4.2.2, Microsoft.NET.Test.Sdk 17.12.0, NUnit3TestAdapter 4.6.0).

## Resource ceiling and stop conditions

- Only the two test projects and their references are built; never the full solution. Builds use `-m:1`, under the shared heavy lock.
- Stryker: `--concurrency 2`, one file, a wall-clock budget of **10 minutes per run**. A run past 10 minutes is stopped and reported as inconclusive.
- **Stop, and report as blocked or inconclusive, never as a passing result, if:**
  - the baseline build fails;
  - GA's deterministic tests do not pass at the pinned revision;
  - Stryker's initial test run fails;
  - any tool would need a dependency upgrade in GA to run.
- No production change. No paid calls. No download beyond the NuGet packages above and the GA sparse checkout.

## Post-measurement edits

Everything above this heading is unchanged since the SHA-256 recorded at writing (`fd86962a…`). The notes below were added afterwards and say when.

1. **Generator clarification, after hashing, before any measurement.** Prepending `b` or a pitch letter can create a valid flat (`bb3`, `Ab3`), so the malformed generator's prepend edits are restricted to the letters `xzH` and to `#`. This narrows the closed list above; it does not change any hypothesis.
2. **Negative-control mechanism, after the first property run.** FsCheck.NUnit's `[Property]` ignored NUnit's `[Explicit]`, so the control ran with the other properties. It now sits in the `NegativeControl` category, excluded by `--filter` and by Stryker's `test-case-filter`.
3. **Exploratory run P, not pre-registered, after B and T.** Because T killed nothing more than B, a third run mutates the same file with the lab's properties only (`stryker-config.props-only.json`). It asks whether the properties, alone, detect what GA's tests detect. It is reported as exploratory.
