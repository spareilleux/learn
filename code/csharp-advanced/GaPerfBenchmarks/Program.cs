// Advanced C#, appendix 2: GA against GaFast2, on a corpus of real voicings. Run one class at a time, on a quiet machine.
// CI only checks that they run: --job Dry, and fails if one of them didn't
using BenchmarkDotNet.Running;

var summaries = BenchmarkSwitcher.FromAssembly(typeof(Program).Assembly).Run(args);
var failed = summaries.Any(s => s.HasCriticalValidationErrors || s.Reports.Any(r => !r.Success));
return failed ? 1 : 0;
