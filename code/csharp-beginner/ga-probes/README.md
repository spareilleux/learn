# Guitar Alchemist probes

Measurements of [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) at commit `5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26`, for lessons 8 to 12 of *C# for beginners*. The journal's 2026-10-02 and 2026-10-03 entries and its Experiments table record the hypotheses, written before measuring, and the results. `check.sh` doesn't run these files: they need a partial GA worktree in `../.ga`, which git ignores.

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

## Lesson 11: `knowledge-tests`

What GA's own tests of its music knowledge services report while three of their four YAML files don't load, and whether the `[SetUpFixture]` of their test project runs. `knowledge-tests/KnowledgeTests.csproj` compiles four files of GA.Business.Core.Tests unchanged, with the NUnit package versions of that project; `ProbeTests.cs` is its only own file. It needs the extraction of `artists.cs`, plus these four files:

```
git -C <ga clone> archive 5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26 Tests/Common/GA.Business.Core.Tests/Configuration/MusicalKnowledgeServiceTests.cs Tests/Common/GA.Business.Core.Tests/TestBootstrap/TestEnvironment.cs Tests/Common/GA.Business.Core.Tests/GlobalUsings.cs Tests/Common/GA.Business.Core.Tests/AssemblyInfo.cs | tar -x -C ../.ga
dotnet build knowledge-tests
dotnet test knowledge-tests --no-build --logger "console;verbosity=detailed"
```

`knowledge-results.txt` holds the output of that run, with the course folder shortened to `<code/csharp-beginner>`; the order of the tests and their durations change from run to run. With SDK 10.0.112, the build's only warning is IDE0028 in GA's `ScaleMetadataRegistry.cs`. Of the 9 tests, 6 pass, GA's 5 and the probe's, and 3 are skipped by `[Ignore]`. The probe's test prints `GA_TEST_MODE: (not set)` and `Current directory is the test's bin folder: True`: GA's `TestEnvironment`, alone in its namespace, didn't run.

## Lesson 12: `lesson12_counts.py` and three builds

`lesson12_counts.py` reads the pinned commit with `git show`, `git ls-tree` and `git grep`, without a checkout: the project files on disk and in `AllProjects.slnx`, the test projects outside the solution and whether a workflow names them, the packages declared with several versions, the `PackageReference Update` items of `Directory.Build.props` against the declared versions, the blocking waits on tasks, and the GaCLI commands that throw `NotImplementedException`. `lesson12-results.txt` holds its output:

```
python lesson12_counts.py <ga clone> > lesson12-results.txt
```

The script lists every match of `.Result`, `.Wait()` and `GetAwaiter().GetResult()`; the journal sorts them by hand. Four are `SemaphoreSlim.Wait()`, not tasks, seven read `.Result` after `await Task.WhenAll`, and five of the sixteen others are in files that their project removes with `<Compile Remove>`.

**A test project outside the solution.** It needs the extraction of `Tests/Common/GA.Business.Core.Graphiti.Tests`:

```
git -C <ga clone> archive 5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26 Tests/Common/GA.Business.Core.Graphiti.Tests | tar -x -C ../.ga
dotnet build ../.ga/Tests/Common/GA.Business.Core.Graphiti.Tests
```

With SDK 10.0.112 the build fails with 5 errors: CS0234 on lines 7 and 8 of `GraphitiServiceTests.cs`, `using GA.Business.Graphiti.Models;` and `using GA.Business.Graphiti.Services;`, and CS0246 for `GraphitiService` and `GraphitiOptions`. The project has no `ProjectReference`. Its restore still runs: `obj/project.assets.json` resolves `Microsoft.Extensions.Http` to 9.0.10, the version of the project file, and not to the 10.0.0 of the `PackageReference Update` in `Directory.Build.props`. In a copy of the same files with the same `Update` line added to `Directory.Build.targets`, the restore resolves `Microsoft.Extensions.Http` to 10.0.0, while `Microsoft.Extensions.Options`, updated in `Directory.Build.props` only, stays at 9.0.10.

**GaCLI.** It needs the extraction of the 18 projects of its `ProjectReference` graph:

```
git -C <ga clone> archive 5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26 AllProjects.ServiceDefaults Common/GA.Business.AI Common/GA.Business.Analytics Common/GA.Business.Assets Common/GA.Business.Config Common/GA.Business.Core Common/GA.Business.DSL Common/GA.Business.Intelligence Common/GA.Business.ML Common/GA.Core Common/GA.Domain.Core Common/GA.Domain.Repositories Common/GA.Domain.Services Common/GA.Providers.Anthropic GA.Data.MongoDB GA.Data.SemanticKernel.Embeddings GaCLI GuitarAlchemist.Registry | tar -x -C ../.ga
dotnet build ../.ga/GaCLI/GaCLI.csproj
```

The build succeeds with 21 warnings. Then, on Windows:

- `GaCLI.exe` with no argument, started from a folder without `appsettings.yaml`, prints its list of commands.
- `GaCLI.exe sync-mongodb`, from that folder or from `bin/Debug/net10.0`, prints `Starting MongoDB sync with embeddings...` and `Error during sync: Unable to resolve service for type 'GA.Data.MongoDB.Services.MusicalObjectsService' while attempting to activate 'GaCLI.Commands.Runner'.`, then a stack trace, and exits with code 0.
- `GaCLI.exe benchmark-quality --limit 50`, the command of GA's *Quality Check* workflow, ends with `Unhandled exception. System.NotImplementedException: The method or operation is not implemented.` and exit code -532462766, the Windows code of an unhandled .NET exception. In GA's own run 37167745677 of that workflow, on Linux, the step ends with exit code 134 and the run succeeds, because of `continue-on-error: true`.
