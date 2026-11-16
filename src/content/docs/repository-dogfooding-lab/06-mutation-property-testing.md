---
title: "6. Mutation and property testing on one real parser"
description: A bounded, pre-registered lab on GA's pitch parser. Stryker.NET measures which faults the tests detect; FsCheck properties check the public contract; a negative control proves the harness can fail.
sidebar:
  order: 6
---

:::caution[Scope of the evidence]
One file of one repository, at one pinned commit: [`PitchParser.cs`](https://github.com/GuitarAlchemist/ga/blob/aa22f9101d5bb86800ff2819381f97986fc81fb1/Common/GA.Domain.Core/Primitives/Notes/PitchParser.cs) in GuitarAlchemist/ga at `aa22f91`. Measured on Windows 11 only; Linux and macOS are *to verify*. Nothing here says anything about GA's test quality as a whole.
:::

A green test suite says that the tests you wrote pass. It does not say whether they would notice a bug. Two techniques ask that second question from opposite sides:

- **Mutation testing** changes the production code in small ways (a `<` into `<=`, a `true` into `false`) and reruns the tests. A change the tests notice is *killed*; a change they miss *survives*. [Stryker.NET](https://stryker-mutator.io/docs/stryker-net/introduction/) does this for .NET.
- **Property testing** states a rule that must hold for every input and lets a generator search for a counterexample. [FsCheck](https://fscheck.github.io/FsCheck/) generates the inputs, and when one fails it *shrinks* it to a minimal case.

This lesson runs both on one real function, with the hypotheses written down before any measurement.

## The seam

`PitchParser` is an `internal` class of `GA.Domain.Core`. It turns text like `C#4` or `Bb3` into a pitch. Its only callers are the public [`Pitch.Sharp.TryParse`](https://github.com/GuitarAlchemist/ga/blob/aa22f9101d5bb86800ff2819381f97986fc81fb1/Common/GA.Domain.Core/Primitives/Notes/Pitch.cs#L114) and [`Pitch.Flat.TryParse`](https://github.com/GuitarAlchemist/ga/blob/aa22f9101d5bb86800ff2819381f97986fc81fb1/Common/GA.Domain.Core/Primitives/Notes/Pitch.cs#L285). The lab tests only those two public entry points: no `InternalsVisibleTo`, no reflection, and no change to GA.

The heart of the parser is an anchored regular expression per accidental kind:

```csharp
// PitchParser.cs:7-8 at aa22f91
new(@"\A([A-G])(#?)(-1|[0-9])\z", PcreOptions.Compiled | PcreOptions.IgnoreCase);  // sharp
new(@"\A([A-G])(b?)(-1|[0-9])\z", PcreOptions.Compiled | PcreOptions.IgnoreCase);  // flat
```

After a match, the code checks again that each group is defined and parses each piece, returning `false` on any failure (lines 36–68).

## Pre-register before you measure

The [pre-registration](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/test-quality/results/preregistration.md) was written and hashed before the first build. Its SHA-256 was recorded in a separate file. It fixes:

- **B (baseline):** Stryker with GA's own test project, mutating `PitchParser.cs` only.
- **T (treatment):** the same command, with the lab's property project added.
- **Detection:** only *Killed* counts. Timeouts would be reported apart, never as kills.
- **H1:** B leaves at least one mutant Survived or NoCoverage; the likely candidates are the defensive checks the regex already guarantees.
- **H2:** T kills at least one mutant that B left alive, asserting only what GA's tests already assert.
- **H3:** no input (null, empty, whitespace, arbitrary Unicode) makes either `TryParse` throw, over 10,000 cases per property.
- **Negative control:** a deliberately false property, which must fail, shrink and replay from its seed.
- **Budget:** one file, concurrency 2, 10 minutes per run, no full-solution build.

A correction made after hashing is not hidden: it goes in a *Post-measurement edits* section, with when and why. This lab has three, including one generator bug caught before any run: prepending `b` to `b3` makes `bb3`, a valid flat, so a "malformed" input was not malformed.

## The properties

Valid pitches are built from small integers and booleans, which FsCheck knows how to shrink. The text is derived inside the property:

```csharp
private static Spelling FromParts(Kind kind, byte letter, bool accidental, bool lowerCase, byte octave)
{
    var upper = "ABCDEFG"[letter % 7];
    var octaveValue = octave % 11 - 1;
    var acc = accidental ? Accidental(kind) : "";
    var text = $"{(lowerCase ? char.ToLowerInvariant(upper) : upper)}{acc}{octaveValue}";
    return new Spelling(kind, text, $"{upper}{acc}{octaveValue}");
}
```

The [test file](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/test-quality/PitchParserProperties/PitchParserPropertyTests.cs) holds five properties and one example test:

| Test | Oracle |
|---|---|
| Valid sharp / valid flat | `TryParse` is true and `ToString()` prints the canonical form (`c#4` → `C#4`) |
| Malformed sharp / malformed flat | One edit from a closed list (extra letter, space, digit, octave out of range, the other accidental, a doubled accidental, no octave) makes `TryParse` false |
| Any string | No exception; accepted text parses again to the same text |
| Null, empty, whitespace | Refused without throwing |

## Run it

From `code/repository-dogfooding-lab/test-quality/`, in a POSIX shell (Git Bash on Windows):

```bash
bash fetch-ga.sh                                    # sparse checkout of GA at aa22f91 into .ga/ (12 MB)
dotnet tool restore                                 # dotnet-stryker 5.0.0 from dotnet-tools.json
dotnet test PitchParserProperties -c Release --filter "TestCategory!=NegativeControl"
dotnet test PitchParserProperties -c Release --filter "TestCategory=NegativeControl"   # must fail
dotnet tool run dotnet-stryker -f stryker-config.baseline.json -O out/stryker-B        # B
dotnet tool run dotnet-stryker -f stryker-config.json -O out/stryker-T                 # T
```

## What was measured (2026-09-26, Windows 11, .NET SDK 10.0.112)

| Run | Tests | Killed | Survived | NoCoverage | Ignored | Timeout | Score | Wall time |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| B — GA tests | 706 | 25 | 0 | 5 | 9 | 0 | 83.33 % | 109 s |
| T — GA + properties | 710 in the report | 25 | 0 | 5 | 9 | 0 | 83.33 % | 142 s |
| P — properties only (exploratory) | 6 | 25 | 0 | 5 | 9 | 0 | 83.33 % | 93 s |

Stryker generates 39 mutants in the file. The score is Killed divided by Killed + Survived + NoCoverage, so 25/30. The 9 *Ignored* mutants sit in blocks Stryker had already mutated as a whole.

- **H1 confirmed.** B leaves 5 mutants with no coverage: `return false` turned into `return true` at lines 38, 43, 49, 58 and 67. All five are in the defensive branches after a successful regex match.
- **H2 refuted.** T kills exactly the same 25 mutants. The same 5 remain uncovered, because no input that the public contract describes reaches them.
- **H3 holds for this seed.** 10,000 cases per property, and no exception.
- **Negative control:** `Falsifiable, after 2 tests (2 shrinks)`, shrunk to `a#-1` (the sharp parser accepts it, the flat parser does not), and the identical output on a second run from the seed `(20260926,7)`.

Run **P** was not in the pre-registration. It was declared in the post-measurement section after T and before it ran, and it is reported as exploratory. It answers a question T could not: do the six property tests *alone* detect what GA's 706 tests detect in this file? They do: the same 25 kills. Most first kills come from the two "valid" properties, 20 each.

## Reading the result honestly

Three conclusions are defensible:

1. GA's existing tests already kill every mutant of this file that can be reached from outside.
2. The five uncovered mutants are probably **unreachable** from the public API: the regex refuses the inputs that would make those branches run. For line 58, `FlatAccidental.TryParse` lowercases its input ([FlatAccidental.cs:96](https://github.com/GuitarAlchemist/ga/blob/aa22f9101d5bb86800ff2819381f97986fc81fb1/Common/GA.Domain.Core/Primitives/Notes/FlatAccidental.cs#L96)), so even `CB4` should not reach it. That is read from the code, not run: *to verify*. Unreachable code is a design observation, not a test gap. No test can kill an equivalent mutant.
3. A handful of properties matched a large example suite on this one file. That says nothing about other files. Here the contract is small and the regex does most of the work.

One claim is not defensible: that property tests "improved GA's tests". They did not, here, and the table shows it.

## What this does **not** establish

- Nothing about any other file of GA, or about GA's overall mutation score. Stryker created 4,781 mutants in the project, and 4,439 were ignored by the mutate filter.
- No production code was changed, and no GA issue was filed. Whether the defensive branches should stay is the maintainer's decision.
- Stryker also reported 303 compile-error mutants elsewhere in the project, outside the filter. They do not affect this file's figures.
- The 710 tests in T's report are not reconciled with 706 + 6: *to verify*.
- There has been no CI run and no Linux or macOS run.

## Exercises

1. Make the negative control pass by fixing its claim, not the parser. What is the smallest true statement about sharp and flat parsing that you can write as a property?
2. Add a malformed edit to the closed list: a letter outside `A–G` in place of the note, such as `H4`. Run the malformed properties. Does the score change? Explain why.
3. Remove the restriction on prepend edits (let it prepend `b` or any pitch letter) and run the flat malformed property. What does FsCheck report, and what does it tell you about generators?
4. Find a hand-written input that reaches line 58 through `Pitch.Flat.TryParse`, or argue from the code that none exists.

<details>
<summary>Solutions</summary>

1. For example: "a text that both parsers accept contains no accidental". Both regexes accept a natural pitch, and only one of them accepts each accidental. Write it with `Prop.ForAll(Parts, …)`, and keep it out of the `NegativeControl` category once it is true.
2. The score does not change. The regex already refuses `H`, so the new edit exercises a path the valid properties already kill: the `!match.Success` branch at line 28. A new edit only helps if it reaches a branch no test reaches yet.
3. FsCheck reports a falsified case such as `bb3` or `Ab3` for the flat parser, which are valid flat pitches. The generator, not the parser, was wrong. That is exactly the flaw caught here before the first run. Generators are code too, and a property is only as trustworthy as the domain it samples.
4. The regex lets through `b` or `B` as the flat group. `FlatAccidental.TryParse` lowercases its input and accepts `b`, so it never returns false for what the regex lets through. No input reaches line 58, and the mutant there is equivalent. Check it by running `Pitch.Flat.TryParse("CB4", null, out var p)`: it should be true and print `Cb4`. This lab has not run that check.

</details>

## Sources

- [Stryker.NET documentation](https://stryker-mutator.io/docs/stryker-net/introduction/), and its [configuration reference](https://stryker-mutator.io/docs/stryker-net/configuration/).
- [FsCheck documentation](https://fscheck.github.io/FsCheck/), the [properties guide](https://fscheck.github.io/FsCheck/Properties.html), and [NUnit](https://docs.nunit.org/) for the test runner.
- Lab code and raw results: [`code/repository-dogfooding-lab/test-quality`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab/test-quality). The [journal](../journal/) holds the dated entry.
