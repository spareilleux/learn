---
title: "Lesson 24: Set classes and the Grothendieck parser"
description: "SetTheoryEquivalenceSkill and GrothendieckParseSkill are the Guitar Alchemist chatbot's two skills for set theory and category theory: the first compares two pitch-class sets under transposition, inversion or both, the second sends an expression to GA's F# parser. The first never reads the relation in its own example prompts' wording, so a pair related only by inversion is equivalent under transposition, and it reads 0-1-4 as the set 4; the second's parser fails on half the forms its comments name and on Am and G7, and its answer names the case and nothing of the chords."
sidebar:
  label: 24. Set classes and the parser
  order: 24
---

Lessons [22](../22-similar-chords/) and [23](../23-harmonic-distance-and-path/) asked the skills built on interval-class vectors. Two more skills registered with them read set theory and category theory ([`GaPlugin.cs` line 78](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L78), [line 103](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L103)): `SetTheoryEquivalenceSkill` says whether two pitch-class sets are equivalent under transposition, inversion or both ([`SetTheoryEquivalenceSkill.cs` lines 7-25](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L7-L25)), and `GrothendieckParseSkill` sends an expression to GA's F# Grothendieck parser and names the case of the operation it gets back ([`GrothendieckParseSkill.cs` lines 8-28](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs#L8-L28)). Neither calls a model. The set skill's `CanHandle` tests its patterns, the parse skill's always says no; at the pin, the router doesn't call it, as [lesson 14](../14-what-the-substitution-skill-answers/) showed.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), the course's pin, unless they name another. On GA's `main` at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), both skills only mark their refusal `Declined`, and the parser and its types are unchanged; `PitchClassSet` was rewritten around precomputed tables, so `GaMain` asks again. Its output prints the same tables as the pin's, under titles that say "on main". The output comes from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l24
dotnet run --project code/ga-ai/GaMain -c Release -- l24
```

## How the skills read a question

The set skill wants two sets of digits joined by "and", then "equivalent", "the same" or a few other words, then, optionally, "under" and a relation:

```csharp
    // Triggers on "are pitch class(es) X and Y <equiv|same> [under <relation>]"
    // OR "are X and Y same set class" etc. The two PC-set captures accept any
    // mix of comma-separated digits or bracket notation.
    private static readonly Regex EquivalencePattern =
        new(@"\b(?:pitch\s+class(?:es)?(?:\s+sets?)?\s+|sets?\s+)?(?<a>[\[\{]?\d[\d,\s]*[\]\}]?)\s+and\s+(?<b>[\[\{]?\d[\d,\s]*[\]\}]?)\s+(?:are\s+)?(?:equivalent|same|equal|related|the\s+same|belong\s+to\s+the\s+same)\s*(?:set\s*class|set|class)?(?:\s+under\s+(?<rel>transposition|inversion|t-i|both|transposition\s+(?:and|or)\s+inversion))?",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    // Alternate phrasing: "do X and Y belong to the same set class"
    private static readonly Regex SetClassPattern =
        new(@"\bdo\s+(?<a>[\[\{]?\d[\d,\s]*[\]\}]?)\s+and\s+(?<b>[\[\{]?\d[\d,\s]*[\]\}]?)\s+belong\s+to\s+the\s+same\s+set\s*class",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

The parse skill wants an anchor word and a piece of category theory, then sends what follows the anchor to the parser:

```csharp
    private static readonly Regex GrothendieckSurface =
        new(@"(⊗|⊕|×\s*[A-Z]|∘|η\(|\^[A-Z]|" +
            @"\b(?:functor|pullback|pushout|equalizer|coequalizer|coproduct|tensor[\s-]+product|direct[\s-]+sum|natural[\s-]+transformation|subobject|power[\s-]+object|sheaf)\b|" +
            @"Hom\s*\()",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    private static readonly Regex AnchorPattern =
        new(@"\b(?:parse|what\s+does|explain|interpret|meaning\s+of)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    public Task<AgentResponse> ExecuteAsync(string message, CancellationToken cancellationToken = default)
    {
        var msg = message ?? string.Empty;
        if (!AnchorPattern.IsMatch(msg) || !GrothendieckSurface.IsMatch(msg))
            return Task.FromResult(CannotHandle());

        // Extract the expression — heuristic: everything after the anchor token.
        // Users typically say "parse C ⊗ G" or "what does Transpose(C ⊗ G) mean".
        // We strip the anchor tokens and trim, then send to the parser.
        var expr = ExtractExpression(msg);
        if (string.IsNullOrWhiteSpace(expr))
            return Task.FromResult(CannotHandle());

        return Task.FromResult(ParseAndAnswer(expr));
    }

    private static string ExtractExpression(string msg)
    {
        // Cheap heuristic: drop leading anchor phrase, drop trailing "mean".
        var stripped = Regex.Replace(msg,
            @"^\s*(?:parse|what\s+does|explain|interpret|meaning\s+of)\s+",
            string.Empty,
            RegexOptions.IgnoreCase);
        stripped = Regex.Replace(stripped, @"\s+(?:mean|do)\s*\??$", string.Empty, RegexOptions.IgnoreCase);
        return stripped.Trim().Trim('?', '.');
    }
```

## GA's phrasings

The program asks each skill its example prompts, asks the other skill the same, and asks `DefaultRoutingHintProvider` which intents each one would boost. The two doc comments and the refusals repeat the example prompts; the parse skill's failure message also suggests `Transpose(Cmaj7)`:

```text
== SetTheoryEquivalenceSkill's and GrothendieckParseSkill's example prompts, at the pin
prompt                                                                   skill  its answer         the other's    routing hints, +0.06 each
Are pitch classes 0,1,4 and 0,1,6 equivalent under inversion             sets   no, TI             declined       none
Are pitch class sets 0,1,3 and 0,2,3 equivalent under transposition      sets   yes, TI            declined       skill.transpose
Are 0,1,4 and 0,3,4 the same set class                                   sets   yes, TI            declined       none
Do 0146 and 0137 belong to the same set class                            sets   no, TI             declined       none
Are pitch classes 0,2,4 and 1,3,5 transpositionally equivalent           sets   declined           declined       skill.transpose
parse C ⊗ G                                                              parse  TensorProduct      declined       skill.grothendieckparse
what does Transpose(C ⊗ G) mean                                          parse  can't parse        declined       skill.grothendieckparse, skill.transpose
parse Transpose ∘ Invert                                                 parse  ComposeFunctors    declined       skill.grothendieckparse, skill.transpose
parse pullback(Cmaj7, Transpose, Gmaj7)                                  parse  Pullback           declined       skill.grothendieckparse, skill.transpose
parse Cmaj7 + Gmaj7 + Fmaj7                                              parse  declined           declined       none
parse functor Transpose: Chords -> Chords                                parse  DefineFunctor      declined       skill.transpose
what is Hom(Cmaj7, Gmaj7)                                                parse  declined           declined       skill.grothendieckparse
explain power(Cmaj7)                                                     parse  declined           declined       none
parse equalizer Transpose Invert                                         parse  can't parse        declined       skill.transpose
parse Cmaj7 ⊕ Gmaj7                                                      parse  DirectSum          declined       skill.grothendieckparse
parse Transpose(Cmaj7)                                                   parse  declined           declined       skill.transpose
SetTheoryEquivalenceSkill: anchors 5, answered 4, hinted toward skill.settheoryequivalence 0; the other skill answers 0 of them; CanHandle accepts 4
GrothendieckParseSkill: anchors 10, answered 5, hinted toward skill.grothendieckparse 6; the other skill answers 0 of them; CanHandle accepts 0
```

- **The set skill answers 4 of its 5 example prompts.** "Are pitch classes 0,2,4 and 1,3,5 transpositionally equivalent" puts "transpositionally" between the second set and "equivalent". Two of the four it answers name a relation it doesn't read, and one of them gets the wrong verdict, as the next section shows.
- **The parse skill answers 5 of its 10.** "parse Cmaj7 + Gmaj7 + Fmaj7", "explain power(Cmaj7)" and "parse Transpose(Cmaj7)", the form its own failure message suggests ([line 177](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs#L177)), hold none of the symbols and words its surface pattern looks for; "what is Hom(Cmaj7, Gmaj7)" starts with "what is", not an anchor. The parser rejects "Transpose(C ⊗ G)", since a functor applies to one musical object, not to an operation ([`GrothendieckOperationsParser.fs` lines 321-327](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L321-L327)), and "equalizer Transpose Invert", which has no parentheses.
- **Neither skill answers the other's prompts.** No hint rule names the set skill; two of its prompts, with "transposition" and "transpositionally", boost `skill.transpose`, whose rule takes any word that starts with "transpos" ([`DefaultRoutingHintProvider.cs` lines 257-259](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L257-L259)). The parse skill's rule boosts 6 of its 10 ([lines 146-153](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L146-L153)).

## The relation the set skill reads

The skill computes the set class of both sets, then answers for the relation it read: "transposition", "inversion", or the set class when it read none ([lines 69-80](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L69-L80)). "Under inversion" means transposition or inversion, as its comment says ([lines 137-141](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L137-L141)). A check for transposition alone was added after a review caught the skill calling {0,1,4} and {0,3,4} equivalent under transposition, on 2026-05-13 according to its comment ([lines 97-107](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L97-L107)). The program asks four pairs in ten wordings:

```text
== The relation SetTheoryEquivalenceSkill reads, at the pin
a pair's cell: the verdict, the relation it applies (T, I or TI), and "wrong" when the verdict
is wrong for the relation the question names
question                                                       asks 0,1,3 | 0,2,3        0,1,4 | 1,2,5        0,1,4,6 | 0,1,3,7    0,1,4 | 0,1,6
                                                                    inversion only       transposition        Z-related            different
are pitch classes {a} and {b} equivalent under transposition   T    yes, TI, wrong       yes, TI              no, TI               no, TI
are pitch classes {a} and {b} equivalent under inversion       I    yes, TI              yes, TI              no, TI               no, TI
are pitch classes {a} and {b} equivalent                       TI   yes, TI              yes, TI              no, TI               no, TI
are {a} and {b} equivalent under transposition or inversion    TI   yes, TI              yes, TI              no, TI               no, TI
are {a} and {b} the same set class under transposition         T    no, T                yes, T               no, T                no, T
are {a} and {b} the same set class under inversion             I    yes, I               yes, I               no, I                no, I
are {a} and {b} the same set class                             TI   yes, TI              yes, TI              no, TI               no, TI
are {a} and {b} related by inversion                           I    yes, TI              yes, TI              no, TI               no, TI
are {a} and {b} transpositionally equivalent                   T    declined             declined             declined             declined
is {a} a transposition of {b}                                  T    declined             declined             declined             declined
```

- **"equivalent under transposition" and "equivalent under inversion" are answered for the set class.** After "equivalent", `\s*` takes the space that `\s+under` needs, and since that group is optional, the match ends without it. {0,1,3} and {0,2,3} "under transposition", the skill's second example prompt, get "Yes — they belong to the same set class", though only an inversion maps one onto the other.
- **The relation is read after "set class", "set" or "class".** "are 0,1,3 and 0,2,3 the same set class under transposition" gets "No — not equivalent under transposition alone", the answer the check was written for.
- **"related by inversion" is answered for the set class too,** and "transpositionally equivalent" and "is … a transposition of …" are declined.

## Every pair of three-note and four-note sets

The program asks every ordered pair of the 220 sets of three notes, then of the 495 of four, in four wordings, and checks each verdict against its own test for the relation the question names:

```text
== Every ordered pair of three-note and of four-note sets, asked of SetTheoryEquivalenceSkill, at the pin
question                                                     size  pairs   right   wrong  what the wrong ones are
are pitch classes {a} and {b} equivalent under transposition 3     48400   46384   2016   yes for an inversion only 2016
are {a} and {b} the same set class under transposition       3     48400   48400   0      none
are {a} and {b} the same set class under inversion           3     48400   48400   0      none
  "via either operation": said for 2608 pairs, of which no inversion maps the first set onto the second for 2016
are {a} and {b} the same set class                           3     48400   48400   0      none
  Z-related pairs: the answer says so for 0, the vectors give 0
are pitch classes {a} and {b} equivalent under transposition 4     245025  240993  4032   yes for an inversion only 4032
are {a} and {b} the same set class under transposition       4     245025  245025  0      none
are {a} and {b} the same set class under inversion           4     245025  245025  0      none
  "via either operation": said for 5841 pairs, of which no inversion maps the first set onto the second for 4032
are {a} and {b} the same set class                           4     245025  245025  0      none
  Z-related pairs: the answer says so for 1152, the vectors give 1152
```

- **"equivalent under transposition" is wrong for 2016 of the 48400 pairs of three notes and 4032 of the 245025 of four,** all "yes" for pairs only an inversion relates. When the skill reads the relation, every verdict is right, and so is every answer about Z-related sets: 1152 pairs of four notes, none of three.
- **"via either operation" is wrong for most of the pairs it is said of.** A pair related by transposition, asked "under inversion", gets "Yes — equivalent under inversion (and also under transposition alone; they reduce to the same prime form via either operation)" ([line 144](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L144)). No inversion maps the first set onto the second for 2016 of the 2608 pairs of three notes it is said of, and 4032 of the 5841 of four: only for sets symmetric under inversion does either operation work.

## The sets it reads

The program writes {0,1,4} in different ways, gives each to the skill's private `TryParseSet` and asks it in a question:

```text
== The sets SetTheoryEquivalenceSkill reads, at the pin
written    TryParseSet        in a question          the answer's set A and its prime form
0,1,4      {0,1,4}            answered               `0,1,4` {0,1,4}
0, 1, 4    {0,1,4}            answered               `0, 1, 4` {0,1,4}
0 1 4      {0,1,4}            answered               `0 1 4` {0,1,4}
014        {0,1,4}            answered               `014` {0,1,4}
[0,1,4]    {0,1,4}            answered               `0,1,4` {0,1,4}
{0,1,4}    {0,1,4}            answered               `0,1,4` {0,1,4}
(0,1,4)    {0,1,4}            declined
<0,1,4>    {0,1,4}            declined
0-1-4      {0,1,4}            answered               `4` {0}
0,1,10     {0,1,10}           answered               `0,1,10` {0,1,3}
0,10,11    {0,10,11}          answered               `0,10,11` {0,1,2}
0,1,t      {0,1}              declined
0,1,T      {0,1}              declined
0,1,A      {0,1}              declined
0te        {0}                declined
01t        {0,1}              declined
0,1,12     (none)             can't parse
0,4,7,4    {0,4,7}            answered               `0,4,7,4` {0,3,7}
3-3        {3}                answered               `3` {0}
C,E,G      (none)             declined
```

- **Commas, spaces, brackets and braces are read,** and so are digits written together: `TryParseSet` splits "014" into 0, 1 and 4 ([lines 218-241](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L218-L241)).
- **A dash leaves only the last number.** The pattern's first set must be followed by " and", so it starts after the last dash: "0-1-4" is asked as {4}, and the Forte name "3-3" as {3}. The answer shows `4` and `3` as set A, and compares them as if they were what was asked.
- **10 and 11 must be written in digits.** "t", "T", "A", "0te" and "01t" are declined; `TryParseSet` alone would drop the letter. Parentheses and angle brackets are declined, and 12 can't be parsed.

The prime form the skill prints is the smallest of the 24 transpositions and inversions of the set, as bits ([`PitchClassSetId.cs` lines 123-156](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L123-L156)). The program checks it on all 4096 sets and against GA's own table of Forte's catalog ([`CanonicalForteCatalog.cs` lines 3-20](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/CanonicalForteCatalog.cs#L3-L20)):

```text
== The prime forms SetTheoryEquivalenceSkill prints, at the pin
sets 4096, distinct prime forms 224, sets whose 24 transpositions and inversions all give the same prime form 4096
Forte labels CanonicalForteCatalog resolves 224; whose stored set differs from its PrimeForm 0; prime forms no label gives 0
interval-class vectors shared by two prime forms of the same size (Z pairs) 23
```

- **The prime forms hold:** there are 224, each the same for all 24 transpositions and inversions of a set, each the set GA's table gives for one of the 224 labels it resolves, and 23 pairs of them share a vector.

## The expressions the parser reads

The parser is written with FParsec. Its `str` reads a word and the spaces after it ([`GrothendieckOperationsParser.fs` line 18](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L18)), and many of its forms then ask for at least one more space, as the limits do:

```fsharp
    /// Parse limit operation
    let limitOperation: Parser<GrothendieckOperation, unit> =
        choice
            [
              // limit of diagram
              str "limit" >>. ws1 >>. str "of" >>. ws1 >>. diagramSpec |>> Limit
              // lim diagram
              str "lim" >>. ws1 >>. diagramSpec |>> Limit
              // pullback(obj1, morphism, obj2)
              pipe5
                  (str "pullback" >>. ch '(')
                  musicalObject
                  (ch ',' >>. morphismExpression)
                  (ch ',' >>. musicalObject)
                  (ch ')')
                  (fun _ obj1 morph obj2 _ -> Pullback(obj1, morph, obj2))
              // obj pullback morphism
              pipe3 musicalObject (str "pullback") morphismExpression (fun obj _ morph -> Pullback(obj, morph, obj))
              // equalizer(morph1, morph2)
              pipe5
                  (str "equalizer" >>. pstring "(" <|> str "eq" >>. pstring "(")
                  morphismExpression
                  (pstring ",")
                  morphismExpression
                  (pstring ")")
                  (fun _ m1 _ m2 _ -> Equalizer(m1, m2)) ]
```

The program writes one expression for each form the parser's comments name, with the case the comment promises, asks the parser, then asks the skill "parse" and the expression:

```text
== The expressions GrothendieckParseSkill reads, at the pin
expression                                       the comment's case   the parser gives     "parse <expression>" gets
C ⊗ G                                            TensorProduct        TensorProduct        TensorProduct
C tensor G                                       TensorProduct        fails                declined
tensor(C, G)                                     TensorProduct        TensorProduct        declined
C ⊕ G                                            DirectSum            DirectSum            DirectSum
C direct_sum G                                   DirectSum            fails                declined
direct_sum(C, G)                                 DirectSum            DirectSum            declined
C × G                                            Product              Product              Product
C product G                                      Product              fails                declined
product(C, G, F)                                 Product              Product              declined
C + G                                            Coproduct            Coproduct            declined
C coproduct G                                    Coproduct            fails                can't parse
coproduct(C, G, F)                               Coproduct            Coproduct            Coproduct
C ^ G                                            Exponential          Exponential          declined
exp(C, G)                                        Exponential          Exponential          declined
functor Transpose: Chords -> Chords              DefineFunctor        DefineFunctor        DefineFunctor
define functor Transpose { a -> invert }         DefineFunctor        fails                can't parse
Invert(C)                                        ApplyFunctor         ApplyFunctor         declined
apply Invert to C                                ApplyFunctor         fails                declined
Transpose ∘ Invert                               ComposeFunctors      ComposeFunctors      ComposeFunctors
Transpose compose Invert                         ComposeFunctors      fails                declined
compose(Transpose, Invert)                       ComposeFunctors      fails                declined
natural transformation eta: Transpose => Invert  DefineNatTrans       fails                can't parse
define nat_trans eta { C -> invert }             DefineNatTrans       fails                declined
eta(C)                                           ApplyNatTrans        ApplyFunctor         declined
limit of {C, G}                                  Limit                fails                declined
lim {C, G}                                       Limit                fails                declined
pullback(C, invert, G)                           Pullback             Pullback             Pullback
pullback(C, transpose 7, G)                      Pullback             fails                can't parse
C pullback invert                                Pullback             Pullback             Pullback
equalizer(invert, reflect)                       Equalizer            fails                can't parse
eq(invert, reflect)                              Equalizer            fails                declined
colimit of {C, G}                                Colimit              fails                declined
colim {C, G}                                     Colimit              fails                declined
pushout(C, invert, G)                            Pushout              Pushout              Pushout
C pushout invert                                 Pushout              Pushout              Pushout
coequalizer(invert, reflect)                     Coequalizer          fails                can't parse
coeq(invert, reflect)                            Coequalizer          fails                declined
Ω                                                SubobjectClassifier  SubobjectClassifier  declined
Ω(C)                                             SubobjectClassifier  ApplyFunctor         declined
truth_value of C                                 SubobjectClassifier  fails                declined
P(C)                                             PowerObject          ApplyFunctor         declined
power(C)                                         PowerObject          ApplyFunctor         declined
subobjects of C                                  PowerObject          fails                declined
Hom(C, G)                                        InternalHom          InternalHom          InternalHom
C => G                                           InternalHom          InternalHom          declined
sheaf S on fretboard                             DefineSheaf          DefineSheaf          DefineSheaf
define sheaf S { U -> C }                        DefineSheaf          fails                can't parse
S | U                                            SheafRestriction     fails                declined
restrict S to U                                  SheafRestriction     fails                declined
glue { C, G }                                    SheafGluing          fails                declined
the operation's cases 22; forms 50, parsed 25, of which as their comment says 21; "parse <expression>" answered for 12
cases no form reaches through the parser: ApplyNatTrans, Coequalizer, Colimit, DefineNatTrans, Equalizer, Limit, PowerObject, SheafGluing, SheafRestriction
cases no form reaches through the skill: ApplyFunctor, ApplyNatTrans, Coequalizer, Colimit, DefineNatTrans, Equalizer, Exponential, Limit, PowerObject, SheafGluing, SheafRestriction, SubobjectClassifier
written without spaces: S|U SheafRestriction, eq(invert,reflect) Equalizer, equalizer((invert,reflect) Equalizer, coeq(invert,reflect) Coequalizer
two operators in a row: C + G + F fails, C ⊗ G ⊗ F fails, Cmaj7 ⊕ Gmaj7 ⊕ Fmaj7 fails
```

- **25 of the 50 forms parse, 21 into the case their comment promises.** A form that reads `str` and then `ws1` never finds its space: "limit of", "lim", "colimit of", "colim", "define functor", "natural transformation", "define nat_trans", "define sheaf", "truth_value of", "subobjects of", "glue", and "transpose" with a number in a pullback. "restrict S to U" fails sooner: the parser wants the sheaf's name before "restrict", so it reads "restrict" as that name ([lines 538-543](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L538-L543)).
- **A first alternative that reads a word hides the others.** FParsec's `choice` tries the next alternative only when the one before fails without reading anything. "C tensor G" fails because the first alternative reads "C" and then wants ⊗, and so do the other word forms between two objects; "apply Invert to C" and "compose(Transpose, Invert)" fail because the first alternative reads "apply" or "compose" as a name. "tensor(C, G)", whose first alternative reads nothing, parses.
- **"P(C)", "power(C)", "Ω(C)" and "eta(C)" are functor applications.** The parser tries functors before natural transformations and topos operations ([lines 625-633](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L625-L633)), and a functor application is a name followed by an object in parentheses ([lines 321-327](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L321-L327)).
- **None of the 50 forms reaches 9 of the 22 cases:** `Limit`, `Colimit`, `Equalizer`, `Coequalizer`, both natural-transformation cases, `PowerObject` and two of the three sheaf cases. Written without their spaces, "S|U", "eq(invert,reflect)" and "coeq(invert,reflect)" parse and reach three of them: those forms read their comma and their "|" with `pstring`, which doesn't skip the space after them. "equalizer((invert,reflect)" parses too: line 426 groups as `((str "equalizer" >>. pstring "(") <|> str "eq") >>. pstring "("`, so "equalizer" needs two parentheses. The three expressions with two operators in a row fail.
- **The skill answers for 12 forms.** Its surface pattern lets through ⊗, ⊕, ×, ∘ and a few words, but not "+", "^" followed by a space, Ω or "=>", so "C + G", "C ^ G", "Ω" and "C => G" are declined though they parse, and so are the forms written as a call, such as "tensor(C, G)" or "Invert(C)".

## The chords the parser reads

The program asks the parser `<chord> ⊗ G` for chords written in different ways, then asks the skill questions worded in different ways:

```text
== The chords GA's Grothendieck parser reads, at the pin
written      what "<written> ⊗ G" parses into, on the left of ⊗
C            chord C Major
Bb           chord Bb Major
F#           chord F# Major
Am           fails
Cm           fails
G7           fails
C7           fails
Dm7          fails
Cmaj7        chord C Major7
CM7          fails
Cmin7        chord C Minor7
Cdom7        chord C Dominant7
Cmaj         chord C Major
Cmin         chord C Minor
Cdim         chord C Diminished
Cdim7        chord C Diminished7
C°           fails
Caug         chord C Augmented
C+           fails
Csus4        chord C Sus4
Cadd9        chord C Add9
C6/9         chord C Custom "6/9"
Cm7b5        fails
Gmaj9        chord G Major9
C major      scale C major
PC{0,4,7}    set class [0,4,7]
"parse C ⊗ G" and "parse F# ⊗ Bb" give the same answer apart from the expression they repeat: yes
```

- **The parser reads only the quality names in its list,** spelled out, such as "maj7", "min7", "dom7", "min", "dim" or "sus4", and "6/9" ([lines 53-71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L53-L71)). Am, Cm, G7, C7, Dm7, CM7, C°, C+ and Cm7b5 fail. A letter alone is a major chord, since a chord's quality is optional and chords come before notes ([lines 233-241](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L233-L241)).
- **The answer says nothing of the chords.** It names the case and gives a gloss written for the case ([`GrothendieckParseSkill.cs` lines 146-163](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs#L146-L163), [lines 244-276](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs#L244-L276)): "parse C ⊗ G" and "parse F# ⊗ Bb" get the same answer, apart from the expression they repeat.

```text
== The questions GrothendieckParseSkill reads, at the pin
question                                 the skill says       the expression it parses
parse C ⊗ G                              TensorProduct        C ⊗ G
Parse: C ⊗ G                             can't parse          Parse: C ⊗ G
please parse C ⊗ G                       can't parse          please parse C ⊗ G
can you parse C ⊗ G                      can't parse          can you parse C ⊗ G
parse C ⊗ G please                       can't parse          C ⊗ G please
what does C ⊗ G mean?                    TensorProduct        C ⊗ G
explain C ⊗ G                            TensorProduct        C ⊗ G
interpret Cmaj7 ⊕ Gmaj7                  DirectSum            Cmaj7 ⊕ Gmaj7
meaning of C ⊗ G                         TensorProduct        C ⊗ G
parse Am ⊗ G7                            can't parse          Am ⊗ G7
parse Dm7 ⊕ G7                           can't parse          Dm7 ⊕ G7
parse C + G                              declined
parse C × G                              Product              C × G
parse C ^ G                              declined
parse Ω                                  declined
explain the tensor product               can't parse          the tensor product
explain natural transformation           can't parse          natural transformation
what is a pullback                       declined
what is the tensor product of C and G    declined
```

- **Only a leading anchor and a space are removed,** with a final "mean" or "do". "Parse:", "please parse" and "can you parse" go to the parser with the expression, and so does a final "please"; all fail.
- **A question about a concept is parsed as an expression.** "explain the tensor product" and "explain natural transformation" get "Couldn't parse"; "what is a pullback" and "what is the tensor product of C and G" are declined. "parse Am ⊗ G7" and "parse Dm7 ⊕ G7" fail on the chords.

## Where the course stops

- **The router isn't run:** it needs the embeddings. The lesson asks the skills their own example prompts and the wordings their comments use.
- **The tables print only how the parse skill answered,** not its messages: its answer gives the parser's error only when `ASPNETCORE_ENVIRONMENT` is `Development` ([lines 37-41](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs#L37-L41)), which the program doesn't set.
- **The prime forms are checked against GA's own table,** not against Forte's book, and the lesson doesn't judge the glosses' category theory.
- **The program calls the skills' methods and the parser directly,** not through the chatbot.

## Reported upstream

- Reported after this lesson was written, in GA issue [#806](https://github.com/GuitarAlchemist/ga/issues/806): the relation the set skill never reads in its own example prompts' wording, "via either operation", the sets read from their last number, the parser forms that `str` and `choice` break, and the parse skill's narrow surface pattern and answer.

## Exercises

1. Why does "Are pitch class sets 0,1,3 and 0,2,3 equivalent under transposition" get "Yes"? Which wording gets the right answer?
2. Which set does the skill compare in "are pitch classes 0-1-4 and 0,1,6 equivalent"? Why?
3. Why does `limit of {C, G}` never parse?
4. Why does "parse Am ⊗ G7" fail? How would the two chords have to be written?

<details>
<summary>Solutions</summary>

1. After "equivalent", `\s*` takes the space that the optional `\s+under` group needs, so the skill reads no relation and answers for the set class (line 73); {0,1,3} and {0,2,3} are one set class, through an inversion. "are 0,1,3 and 0,2,3 the same set class under transposition" gets "No — not equivalent under transposition alone".
2. {4}: the first set must be followed by " and", so it starts after the last dash. The answer shows `4` as set A.
3. `str "limit"` has already read the space after "limit" (line 18), so `ws1` finds none (line 411).
4. The quality list has "min" and "dom7" but neither "m" nor "7" (lines 53-71); written as the table's Cmin and Cdom7 are, "Amin" and "Gdom7".

</details>

## Key takeaways

- A greedy `\s*` before an optional `\s+…` group leaves it nothing to match: test every word a pattern claims to read.
- A fix that no wording of the example prompts reaches doesn't fix the example prompts.
- A number read from the end of a token is another set: a reader should refuse what it can't read whole.
- In a combinator parser, a word that eats its spaces makes every "then a space" fail, and a first alternative that reads input hides the others.
- An answer that names the operation and nothing of its operands tells the user little about their chords.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs`, `Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs`, `Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs`, `Common/GA.Business.DSL/Types/GrammarTypes.fs`, `Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs`, `Common/GA.Domain.Core/Theory/Atonal/CanonicalForteCatalog.cs`, `Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`.
- GuitarAlchemist/ga at [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): the same skills, with their refusals marked `Declined`, the same parser, and the rewritten `PitchClassSet.cs`.
- The course's programs: `code/ga-ai/GaAi/Lesson24.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/SetEquivalenceParseProbe.cs`.
