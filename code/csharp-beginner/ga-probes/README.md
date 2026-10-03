# Guitar Alchemist probes

Measurements of [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) at commit `5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26`, for lessons 8, 9 and 10 of *C# for beginners*. The journal's 2026-10-02 and 2026-10-03 entries and its Experiments table record the hypotheses, written before measuring, and the results. `check.sh` doesn't run these files: they need a partial GA worktree in `../.ga`, which git ignores.

```
git -C <ga clone> worktree add --no-checkout --detach ../.ga 5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26
git -C ../.ga checkout 5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26 -- Directory.Build.props Directory.Build.targets global.json .editorconfig Common/GA.Domain.Core Common/GA.Core Common/GA.Business.Config
```

## Experiments 2 and 3: `probe.cs`

What `Fret` does with 50 and -2 through its four entry points, and whether `new PositionLocation(5, 3)`, with the string and the fret swapped as plain numbers, compiles. Build it apart, so that the build's warnings stay out of the output, then compare with `results.txt`:

```
dotnet build probe.cs
dotnet run --no-build probe.cs | diff --strip-trailing-cr results.txt -
```

With SDK 10.0.112, the build's only warning is IDE0028 in GA's `ScaleMetadataRegistry.cs`; none is on `probe.cs`.

## Experiment 1: what GA's `NoWarn` hides

`Directory.Build.props` line 21 and `Directory.Build.targets` line 7 both put fifteen nullable warnings in `NoWarn`. `ZzNullableCanary.cs` holds seven nullable mistakes; it shows whether a build reports them.

```
mkdir orig && cp ../.ga/Directory.Build.props ../.ga/Directory.Build.targets orig/
cp ZzNullableCanary.cs ../.ga/Common/GA.Domain.Core/
dotnet build ../.ga/Common/GA.Domain.Core/GA.Domain.Core.csproj -c Debug --no-incremental -tl:off > with-nowarn.log
python lift_nullable_nowarn.py ../.ga orig both
dotnet build ../.ga/Common/GA.Domain.Core/GA.Domain.Core.csproj -c Debug --no-incremental -tl:off > without-nowarn.log
python count_warnings.py with-nowarn.log
python count_warnings.py without-nowarn.log
cp orig/* ../.ga/ && rm ../.ga/Common/GA.Domain.Core/ZzNullableCanary.cs
```

`lift_nullable_nowarn.py` expects the CRLF line endings of a Windows checkout. With SDK 10.0.112: 0 nullable warnings with GA's configuration; 7 without the two lists (CS8600 ×2, CS8602 ×3, CS8618, CS8625), all of them in `ZzNullableCanary.cs`. GA.Domain.Core and GA.Core have none of their own.

## Lesson 9: `artists.cs`

Which artists `MusicalKnowledgeService.GetArtistBreakdown()` keeps with `GetAllArtists().Take(20)`, and in what order its dictionary comes out. This probe needs more of GA than lesson 8's. It is extracted from the commit with `git archive`, which adds no worktree to the GA clone:

```
git -C <ga clone> archive 5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26 Directory.Build.props Directory.Build.targets global.json .editorconfig Common/GA.Domain.Services Common/GA.Business.Config Common/GA.Core Common/GA.Domain.Core Common/GA.Domain.Repositories Common/GA.Business.Core | tar -x -C ../.ga
dotnet build artists.cs
dotnet run --no-build artists.cs | diff --strip-trailing-cr artists-results.txt -
```

With SDK 10.0.112, the build's only warning is IDE0028 in GA's `ScaleMetadataRegistry.cs`. Three of the four services print `Error loading ...` and keep a one-item default, because their YAML file doesn't deserialize; `GetAllArtists()` returns 16 artists, and none is left out. The first line of the output is the machine's culture, which `OrderBy(a => a)` sorts with; it was `en-CA` here.

## Lesson 10: `files.cs`

Where GA looks for its data files, and what it does when it doesn't find them: the four paths of `IconicChordsConfigLoader.FindYamlFile`, `ReloadConfiguration()`, and the resource and fallback file of `ScaleVideoUrlById`. It needs the same extraction as `artists.cs`. It runs three times, in this order: as built; with `--without-yaml`, which deletes the YAML files that the build copied next to the program; then from `../.ga`, the root of the extracted code, where the YAML files are still deleted. A new `dotnet build` copies them back.

```
dotnet build files.cs
dotnet run --no-build files.cs | diff --strip-trailing-cr files-results.txt -
dotnet run --no-build files.cs -- --without-yaml | diff --strip-trailing-cr files-without-yaml.txt -
cd ../.ga && dotnet run --no-build ../ga-probes/files.cs | diff --strip-trailing-cr ../ga-probes/files-from-ga-root.txt -
```

With SDK 10.0.112, the build prints IDE0028 in GA's `ScaleMetadataRegistry.cs` and IL3000 on `files.cs` line 62, its own use of `Assembly.Location`, the call that `ScaleVideoUrlById`'s fallback relies on. GA loads 17 iconic chords as built, 1 default chord without the YAML files, and 17 again from `../.ga`, through `<current directory>/Common/GA.Business.Config`. All three runs print the same `FieldAccessException` for `ReloadConfiguration()`, and find no `scale_video_urls.json`, neither as a resource nor as a file.
