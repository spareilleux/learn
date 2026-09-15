open System

// Single-case unions give an identifier its own type, as TARS does in v2/src/Tars.Core/Primitives.fs
type AgentId = AgentId of Guid
type CorrelationId = CorrelationId of Guid

let describeAgent (AgentId id) = $"agent {id}" // the parameter unwraps the Guid

let guid = Guid.Parse "7d9e2c1a-0b6f-4c3e-9a51-2f8d4e6b1c07"
let agent = AgentId guid
let conversation = CorrelationId guid

printfn "%s" (describeAgent agent)
printfn "%A" conversation
