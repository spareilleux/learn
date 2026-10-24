#load "vendor/GaAsync.fs"

open System
open System.IO
open System.Text.Json
open GA.Business.DSL.Closures.GaAsync

let run m = Async.RunSynchronously(m, timeout = 5000)
let ensure name expected actual =
    if actual <> expected then failwithf "%s expected %A, got %A" name expected actual
let rows = ResizeArray<obj>()
let record id expected actual =
    ensure id expected actual
    rows.Add(box {| id = id; observed = sprintf "%A" actual; passed = true |})

let failInt e : GaAsync<int> = fail e

let trace = ResizeArray<string>()
let double x = trace.Add("double"); ok (x * 2)
let increment x = trace.Add("increment"); ok (x + 1)
let success = ok 5 |> bind double |> bind increment |> map (fun x -> $"ready:{x}") |> run
record "bind-success" (Ok "ready:11") success
record "bind-success-trace" ["double"; "increment"] (List.ofSeq trace)
trace.Clear()
let stopped = failInt (GaError.DomainError "invalid-pitch") |> bind double |> bind increment |> run
record "bind-error" (Error (GaError.DomainError "invalid-pitch")) stopped
record "bind-error-trace" [] (List.ofSeq trace)

let validate x = if x > 0 then ok x else fail (GaError.DomainError "nonpositive-note")
let format x = ok ($"note:{x}")
for value in [5; -1] do
    let left = ok value |> bind validate |> bind format |> run
    let right = ok value |> bind (fun x -> validate x |> bind format) |> run
    record ($"bind-associativity-{value}") left right
record "map-error" (Error (GaError.DomainError "wrapped: DomainError: invalid-pitch"))
    (failInt (GaError.DomainError "invalid-pitch") |> mapError (fun e -> GaError.DomainError ($"wrapped: {e}")) |> run)
record "map-error-success" (Ok 42)
    (ok 42 |> mapError (fun _ -> failwith "must not run") |> run)
record "option-present-zero" (Ok 0) (ofOption (GaError.DomainError "missing-note") (Some 0) |> run)
record "option-absent" (Error (GaError.DomainError "missing-note"))
    (ofOption (GaError.DomainError "missing-note") None |> run : Result<int, GaError>)
record "option-present-invalid" (Error (GaError.DomainError "nonpositive-note"))
    (ofOption (GaError.DomainError "missing-note") (Some 0) |> bind validate |> run)
let lostA : int option = Result.toOption (Error "missing-note")
let lostB : int option = Result.toOption (Error "invalid-pitch")
record "erased-errors" [None; None] [lostA; lostB]
let captured = fromAsync (async { return raise (IOException "fixture-io") }) |> run : Result<int, GaError>
match captured with
| Error (GaError.IoError (message, Some ex)) -> record "captured-io" ["fixture-io"; "System.IO.IOException"] [message; ex.GetType().FullName]
| other -> failwithf "Expected retained IOException, got %A" other

record "fanout-empty" (Ok []) (fanOutAll ([] : GaAsync<int> list) |> run)
record "fanout-all-success" (Ok [100; 300]) (fanOutAll [ok 100; ok 300] |> run)
let partial = fanOutAll [ok 100; fail (GaError.DomainError "missing-branch"); ok 300] |> run
match partial with
| Error (GaError.PartialFailure (successes, errors)) ->
    record "fanout-partial-successes" [100; 300] (successes |> List.map unbox<int>)
    record "fanout-partial-errors" [GaError.DomainError "missing-branch"] errors
| other -> failwithf "Expected PartialFailure, got %A" other
let allFailed = fanOutAll [failInt (GaError.DomainError "left"); failInt (GaError.DomainError "right")] |> run
match allFailed with
| Error (GaError.PartialFailure (successes, errors)) ->
    record "fanout-all-failed-counts" [0; 2] [successes.Length; errors.Length]
    record "fanout-all-failed-order" [GaError.DomainError "left"; GaError.DomainError "right"] errors
| other -> failwithf "Expected all-failed PartialFailure, got %A" other

let started = System.Collections.Concurrent.ConcurrentQueue<string>()
let branch name : GaAsync<int> = async { started.Enqueue name; return Error (GaError.DomainError name) }
record "zip-both-failed" (Error (GaError.DomainError "left")) (zip (branch "left") (branch "right") |> run)
record "zip-started-branches" ["left"; "right"] (started.ToArray() |> Array.sort |> Array.toList)
record "zip-both-success" (Ok (2, 3)) (zip (ok 2) (ok 3) |> run)
let mutable escaped = false
let wrapped = fanOutAll [fromAsync (async { return raise (IOException "wrapped") }); ok 1] |> run
match wrapped with
| Error (GaError.PartialFailure (successes, [GaError.IoError (message, Some ex)])) ->
    record "fanout-wrapped-exception" ([1], "wrapped", "System.IO.IOException")
        (successes |> List.map unbox<int>, message, ex.GetType().FullName)
| other -> failwithf "Expected wrapped PartialFailure, got %A" other
try
    fanOutAll [async { return raise (IOException "unwrapped") }; ok 1] |> run |> Microsoft.FSharp.Core.Operators.ignore
with :? IOException as ex -> escaped <- (ex.Message = "unwrapped")
record "fanout-unwrapped-exception-escapes" true escaped

let output = {| scope = "Pinned GaAsync source executed in F# Interactive; synthetic inputs, no GA host or agent fleet."; assertion_count = rows.Count; assertions = rows |}
printfn "%s" (JsonSerializer.Serialize(output, JsonSerializerOptions(WriteIndented = true)))
