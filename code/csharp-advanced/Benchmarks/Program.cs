// Advanced C#: the benchmarks of lessons 2 to 5 and 9. Run one class at a time, on a quiet machine:
//   dotnet run -c Release --project Benchmarks -- --filter "*AllocationBenchmarks*"
// CI only checks that they run: --job Dry (one iteration, no statistics), and fails if one of them didn't
using BenchmarkDotNet.Running;

var summaries = BenchmarkSwitcher.FromAssembly(typeof(Program).Assembly).Run(args);
var failed = summaries.Any(s => s.HasCriticalValidationErrors || s.Reports.Any(r => !r.Success));
return failed ? 1 : 0;
