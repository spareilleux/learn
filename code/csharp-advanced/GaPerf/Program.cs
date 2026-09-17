// Advanced C#, appendix 2: GA's voicing-analysis path, profiled, proved and measured.
// Lines starting with "# " depend on the machine; check.sh prints them without comparing them.
using GaPerf;

if (args is not ["a2"])
{
    Console.Error.WriteLine("usage: GaPerf a2");
    return 2;
}

Console.WriteLine($"# a2 on .NET {Environment.Version}, {System.Runtime.InteropServices.RuntimeInformation.OSDescription}, {System.Runtime.InteropServices.RuntimeInformation.ProcessArchitecture}");
Appendix2.Run();
return 0;
