# Test-quality lab: mutation and property testing on GA's `PitchParser`

Lesson: `src/content/docs/repository-dogfooding-lab/06-mutation-property-testing.md`.

- `fetch-ga.sh`: a sparse, blobless checkout of GuitarAlchemist/ga at `aa22f91` into `.ga/` (git-ignored). GA is never modified.
- `PitchParserProperties/`: FsCheck 3.4.0 properties through the public `Pitch.Sharp/Flat.TryParse`. The `NegativeControl` category holds a deliberately false property.
- `stryker-config.baseline.json` (B, GA's tests), `stryker-config.json` (T, GA's tests plus the properties) and `stryker-config.props-only.json` (P, exploratory, the properties only). All three mutate `PitchParser.cs` only, with concurrency 2.
- `results/preregistration.md`: hypotheses written before measuring. The part above "Post-measurement edits" hashes to `fd86962a…` with that section reading "(none yet)".
- `results/B`, `results/T` and `results/P`: raw Stryker reports and logs from 2026-09-26 on Windows 11 with .NET SDK 10.0.112.

```bash
bash fetch-ga.sh
dotnet tool restore
dotnet test PitchParserProperties -c Release --filter "TestCategory!=NegativeControl"
dotnet tool run dotnet-stryker -f stryker-config.json -O out/stryker-T
```

Linux and macOS: to verify. CI: not wired.
