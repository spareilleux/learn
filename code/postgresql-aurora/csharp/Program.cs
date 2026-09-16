// Runs one example of the course: dotnet run -- <name>. PG_CONNECTION overrides the connection string.
using Learn.Pg;

var examples = new Dictionary<string, Func<Task>>
{
    ["l04-connect"] = L04.Connect,
    ["l04-parameters"] = L04.Parameters,
    ["l04-pool"] = L04.Pool,
    ["l04-prepare"] = L04.Prepare,
    ["l04-copy"] = L04.Copy,
    ["l04-timings"] = L04.Timings,
    ["l04-too-many"] = L04.TooMany,
    ["l04-efcore"] = L04Ef.Query,
    ["l04-efcore-ga"] = L04Ef.GaModel,
    ["l04-exercise-batch"] = L04.ExerciseBatch,
    ["l04-target"] = L04.Target,
    ["l06-isolation"] = L06.Isolation,
    ["l06-lost-update"] = L06.LostUpdate,
    ["l06-write-skew"] = L06.WriteSkew,
    ["l06-locks"] = L06.Locks,
    ["l06-deadlock"] = L06.Deadlock,
    ["l06-vacuum-horizon"] = L06.VacuumHorizon,
    ["l06-skip-locked"] = L06.SkipLocked,
    ["l08-routines"] = L08.Routines,
    ["l08-trigger-error"] = L08.TriggerError,
};

if (args.Length != 1 || !examples.TryGetValue(args[0], out var example))
{
    Console.Error.WriteLine($"usage: pg <{string.Join('|', examples.Keys)}>");
    return 2;
}

await example();
return 0;
