using PetriNets;

namespace Examples;

/// <summary>
/// A deliberately wrong model and a guarded model for a Jev advisory result.
/// These nets specify the authority boundary; they do not call Jev or Gaia.
/// </summary>
public static class JevEvidenceGate
{
    public static PetriNet Unsafe() => new(
        "jev-advisory-as-authority-unsafe",
        [new Place("pending", "pending"), new Place("advisory", "advisory"),
         new Place("effect", "effect")],
        [new Transition("classify", "classify"),
         new Transition("authorize_from_advisory", "authorize_from_advisory")],
        [new Arc("pending", "classify"), new Arc("classify", "advisory"),
         new Arc("advisory", "authorize_from_advisory"),
         new Arc("authorize_from_advisory", "effect")],
        new Marking(1, 0, 0));

    public static PetriNet Guarded(bool verifiedEvidence, bool implementationAuthority) => new(
        "jev-advisory-needs-independent-proof",
        [new Place("pending", "pending"), new Place("advisory", "advisory"),
         new Place("review", "review"), new Place("confirmed", "confirmed"),
         new Place("verified_evidence", "verified_evidence"),
         new Place("implementation_authority", "implementation_authority"),
         new Place("effect", "effect"), new Place("rejected", "rejected")],
        [new Transition("classify", "classify"), new Transition("route_review", "route_review"),
         new Transition("reject", "reject"), new Transition("confirm", "confirm"),
         new Transition("authorize", "authorize")],
        [new Arc("pending", "classify"), new Arc("classify", "advisory"),
         new Arc("advisory", "route_review"), new Arc("route_review", "review"),
         new Arc("review", "reject"), new Arc("reject", "rejected"),
         new Arc("review", "confirm"), new Arc("verified_evidence", "confirm"),
         new Arc("confirm", "confirmed"),
         new Arc("confirmed", "authorize"),
         new Arc("implementation_authority", "authorize"),
         new Arc("authorize", "effect")],
        new Marking(1, 0, 0, 0, verifiedEvidence ? 1 : 0,
                    implementationAuthority ? 1 : 0, 0, 0));
}
