open System

type AgentId = AgentId of Guid
type CorrelationId = CorrelationId of Guid

let describeAgent (AgentId id) = $"agent {id}"

let conversation = CorrelationId(Guid.NewGuid())
printfn "%s" (describeAgent conversation)
