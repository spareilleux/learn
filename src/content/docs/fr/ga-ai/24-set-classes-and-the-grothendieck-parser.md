---
title: "Leçon 24 : les classes d'ensembles et l'analyseur Grothendieck"
description: "SetTheoryEquivalenceSkill et GrothendieckParseSkill sont les deux skills du chatbot de Guitar Alchemist consacrés à la théorie des ensembles et à la théorie des catégories : le premier compare deux ensembles de classes de hauteurs par transposition, par inversion ou les deux, le second envoie une expression à l'analyseur F# de GA. Le premier ne lit jamais la relation dans la tournure de ses propres prompts d'exemple, si bien qu'une paire liée par la seule inversion est équivalente par transposition, et il lit 0-1-4 comme l'ensemble 4 ; l'analyseur du second échoue sur la moitié des formes que nomment ses commentaires, et sur Am et G7, et sa réponse nomme le cas sans rien dire des accords."
sidebar:
  label: 24. Les classes d'ensembles et l'analyseur
  order: 24
---

Les leçons [22](../22-similar-chords/) et [23](../23-harmonic-distance-and-path/) ont interrogé les skills fondés sur les vecteurs d'intervalles. Deux autres skills enregistrés avec eux lisent la théorie des ensembles et la théorie des catégories ([`GaPlugin.cs` ligne 78](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L78), [ligne 103](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L103)) : `SetTheoryEquivalenceSkill` dit si deux ensembles de classes de hauteurs sont équivalents par transposition, par inversion ou les deux ([`SetTheoryEquivalenceSkill.cs` lignes 7-25](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L7-L25)), et `GrothendieckParseSkill` envoie une expression à l'analyseur Grothendieck de GA, écrit en F#, et nomme le cas de l'opération qu'il reçoit en retour ([`GrothendieckParseSkill.cs` lignes 8-28](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs#L8-L28)). Aucun des deux n'appelle de modèle. Le `CanHandle` du skill des ensembles teste ses expressions, celui du skill d'analyse répond toujours non ; au commit épinglé, le routeur ne l'appelle pas, comme l'a montré la [leçon 14](../14-what-the-substitution-skill-answers/).

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui en nomment un autre. Sur le `main` de GA à [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), les deux skills ne font que marquer leur refus `Declined`, et l'analyseur et ses types sont inchangés ; `PitchClassSet` a été réécrit autour de tables précalculées : `GaMain` repose donc les questions. Sa sortie affiche les mêmes tableaux que celle du commit épinglé, sous des titres qui portent « on main ». Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l24
dotnet run --project code/ga-ai/GaMain -c Release -- l24
```

## Comment les skills lisent une question

Le skill des ensembles veut deux ensembles de chiffres reliés par « and », puis « equivalent », « the same » ou quelques autres mots, puis, facultativement, « under » et une relation :

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

Le skill d'analyse veut un mot d'ancrage et un élément de théorie des catégories, puis envoie à l'analyseur ce qui suit le mot d'ancrage :

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

## Les formulations de GA

Le programme pose à chaque skill ses prompts d'exemple, pose les mêmes à l'autre skill, et demande à `DefaultRoutingHintProvider` quelles intentions chacun favoriserait. Les deux commentaires de documentation et les refus reprennent les prompts d'exemple ; le message d'échec du skill d'analyse suggère en plus `Transpose(Cmaj7)` :

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

- **Le skill des ensembles répond à 4 de ses 5 prompts d'exemple.** « Are pitch classes 0,2,4 and 1,3,5 transpositionally equivalent » place « transpositionally » entre le second ensemble et « equivalent ». Deux des quatre auxquels il répond nomment une relation qu'il ne lit pas, et l'un d'eux reçoit un verdict faux, comme le montre la section suivante.
- **Le skill d'analyse répond à 5 de ses 10.** « parse Cmaj7 + Gmaj7 + Fmaj7 », « explain power(Cmaj7) » et « parse Transpose(Cmaj7) », la forme que suggère son propre message d'échec ([ligne 177](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs#L177)), ne contiennent aucun des symboles ni des mots que cherche son expression de surface ; « what is Hom(Cmaj7, Gmaj7) » commence par « what is », qui n'est pas un mot d'ancrage. L'analyseur rejette « Transpose(C ⊗ G) », car un foncteur s'applique à un objet musical, et non à une opération ([`GrothendieckOperationsParser.fs` lignes 321-327](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L321-L327)), et « equalizer Transpose Invert », qui n'a pas de parenthèses.
- **Aucun des deux skills ne répond aux prompts de l'autre.** Aucune règle d'indice ne nomme le skill des ensembles ; deux de ses prompts, avec « transposition » et « transpositionally », favorisent `skill.transpose`, dont la règle prend tout mot qui commence par « transpos » ([`DefaultRoutingHintProvider.cs` lignes 257-259](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L257-L259)). La règle du skill d'analyse favorise 6 de ses 10 prompts ([lignes 146-153](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L146-L153)).

## La relation que lit le skill des ensembles

Le skill calcule la classe d'ensembles des deux ensembles, puis répond pour la relation qu'il a lue : « transposition », « inversion », ou la classe d'ensembles s'il n'en a lu aucune ([lignes 69-80](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L69-L80)). « Under inversion » signifie transposition ou inversion, comme le dit son commentaire ([lignes 137-141](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L137-L141)). Une vérification de la transposition seule a été ajoutée après qu'une revue eut surpris le skill à déclarer {0,1,4} et {0,3,4} équivalents par transposition, le 2026-05-13 selon son commentaire ([lignes 97-107](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L97-L107)). Le programme pose quatre paires sous dix formulations :

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

- **« equivalent under transposition » et « equivalent under inversion » reçoivent une réponse pour la classe d'ensembles.** Après « equivalent », `\s*` prend l'espace dont `\s+under` a besoin, et comme ce groupe est facultatif, la correspondance s'arrête sans lui. {0,1,3} et {0,2,3} « under transposition », le deuxième prompt d'exemple du skill, reçoivent « Yes — they belong to the same set class », alors que seule une inversion envoie l'un sur l'autre.
- **La relation est lue après « set class », « set » ou « class ».** « are 0,1,3 and 0,2,3 the same set class under transposition » reçoit « No — not equivalent under transposition alone », la réponse pour laquelle cette vérification a été écrite.
- **« related by inversion » reçoit lui aussi une réponse pour la classe d'ensembles,** et « transpositionally equivalent » et « is … a transposition of … » sont déclinés.

## Toutes les paires d'ensembles de trois et de quatre notes

Le programme pose chaque paire ordonnée des 220 ensembles de trois notes, puis des 495 de quatre, sous quatre formulations, et compare chaque verdict à son propre test de la relation que nomme la question :

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

- **« equivalent under transposition » se trompe pour 2016 des 48400 paires de trois notes et 4032 des 245025 de quatre,** toutes des « yes » pour des paires que seule une inversion relie. Quand le skill lit la relation, chaque verdict est juste, comme chaque réponse sur les ensembles en relation Z : 1152 paires de quatre notes, aucune de trois.
- **« via either operation » est faux pour la plupart des paires dont il est dit.** Une paire liée par transposition, posée « under inversion », reçoit « Yes — equivalent under inversion (and also under transposition alone; they reduce to the same prime form via either operation) » ([ligne 144](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L144)). Aucune inversion n'envoie le premier ensemble sur le second pour 2016 des 2608 paires de trois notes dont il est dit, et 4032 des 5841 de quatre : les deux opérations ne marchent que pour les ensembles symétriques par inversion.

## Les ensembles qu'il lit

Le programme écrit {0,1,4} de différentes façons, donne chacune au `TryParseSet` privé du skill et la pose dans une question :

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

- **Les virgules, les espaces, les crochets et les accolades sont lus,** tout comme les chiffres écrits d'un seul tenant : `TryParseSet` découpe « 014 » en 0, 1 et 4 ([lignes 218-241](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L218-L241)).
- **Un tiret ne laisse que le dernier nombre.** Le premier ensemble de l'expression doit être suivi de « and » : il commence donc après le dernier tiret. « 0-1-4 » est posé comme {4}, et le nom de Forte « 3-3 » comme {3}. La réponse affiche `4` et `3` comme ensemble A, et les compare comme s'ils étaient ce qui a été demandé.
- **10 et 11 doivent s'écrire en chiffres.** « t », « T », « A », « 0te » et « 01t » sont déclinés ; `TryParseSet` seul laisserait tomber la lettre. Les parenthèses et les chevrons sont déclinés, et 12 ne peut pas être analysé.

La forme première qu'affiche le skill est la plus petite, en bits, des 24 transpositions et inversions de l'ensemble ([`PitchClassSetId.cs` lignes 123-156](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L123-L156)). Le programme la vérifie sur les 4096 ensembles et la compare à la table du catalogue de Forte que tient GA ([`CanonicalForteCatalog.cs` lignes 3-20](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/CanonicalForteCatalog.cs#L3-L20)) :

```text
== The prime forms SetTheoryEquivalenceSkill prints, at the pin
sets 4096, distinct prime forms 224, sets whose 24 transpositions and inversions all give the same prime form 4096
Forte labels CanonicalForteCatalog resolves 224; whose stored set differs from its PrimeForm 0; prime forms no label gives 0
interval-class vectors shared by two prime forms of the same size (Z pairs) 23
```

- **Les formes premières tiennent :** il y en a 224, chacune identique pour les 24 transpositions et inversions d'un ensemble, chacune égale à l'ensemble que la table de GA donne pour l'une des 224 étiquettes qu'elle résout, et 23 paires d'entre elles partagent un vecteur.

## Les expressions que lit l'analyseur

L'analyseur est écrit avec FParsec. Son `str` lit un mot et les espaces qui le suivent ([`GrothendieckOperationsParser.fs` ligne 18](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L18)), et beaucoup de ses formes exigent ensuite au moins une espace de plus, comme le font les limites :

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

Le programme écrit une expression pour chaque forme que nomment les commentaires de l'analyseur, avec le cas que promet le commentaire, la soumet à l'analyseur, puis pose au skill « parse » suivi de l'expression :

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

- **25 des 50 formes sont analysées, 21 dans le cas que promet leur commentaire.** Une forme qui lit `str` puis `ws1` ne trouve jamais son espace : « limit of », « lim », « colimit of », « colim », « define functor », « natural transformation », « define nat_trans », « define sheaf », « truth_value of », « subobjects of », « glue », et « transpose » suivi d'un nombre dans un pullback. « restrict S to U » échoue plus tôt : l'analyseur veut le nom du faisceau avant « restrict », si bien qu'il lit « restrict » comme ce nom ([lignes 538-543](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L538-L543)).
- **Une première alternative qui lit un mot cache les autres.** Le `choice` de FParsec ne tente l'alternative suivante que si la précédente échoue sans rien avoir lu. « C tensor G » échoue parce que la première alternative lit « C » puis attend ⊗, comme les autres formes où un mot se place entre deux objets ; « apply Invert to C » et « compose(Transpose, Invert) » échouent parce que la première alternative lit « apply » ou « compose » comme un nom. « tensor(C, G) », dont la première alternative ne lit rien, est analysé.
- **« P(C) », « power(C) », « Ω(C) » et « eta(C) » sont des applications de foncteur.** L'analyseur essaie les foncteurs avant les transformations naturelles et les opérations de topos ([lignes 625-633](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L625-L633)), et une application de foncteur est un nom suivi d'un objet entre parenthèses ([lignes 321-327](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L321-L327)).
- **Aucune des 50 formes n'atteint 9 des 22 cas :** `Limit`, `Colimit`, `Equalizer`, `Coequalizer`, les deux cas de transformation naturelle, `PowerObject` et deux des trois cas de faisceau. Écrits sans leurs espaces, « S|U », « eq(invert,reflect) » et « coeq(invert,reflect) » sont analysés et en atteignent trois : ces formes lisent leur virgule et leur « | » avec `pstring`, qui ne saute pas l'espace qui les suit. « equalizer((invert,reflect) » est analysé lui aussi : la ligne 426 se groupe comme `((str "equalizer" >>. pstring "(") <|> str "eq") >>. pstring "("`, si bien que « equalizer » demande deux parenthèses. Les trois expressions qui enchaînent deux opérateurs échouent.
- **Le skill répond pour 12 formes.** Son expression de surface laisse passer ⊗, ⊕, ×, ∘ et quelques mots, mais pas « + », « ^ » suivi d'une espace, Ω ni « => » : « C + G », « C ^ G », « Ω » et « C => G » sont déclinés bien qu'ils soient analysés, tout comme les formes écrites comme un appel, telles que « tensor(C, G) » ou « Invert(C) ».

## Les accords que lit l'analyseur

Le programme soumet à l'analyseur `<chord> ⊗ G` pour des accords écrits de différentes façons, puis pose au skill des questions formulées de différentes façons :

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

- **L'analyseur ne lit que les noms de qualité de sa liste,** écrits en toutes lettres, comme « maj7 », « min7 », « dom7 », « min », « dim » ou « sus4 », et « 6/9 » ([lignes 53-71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L53-L71)). Am, Cm, G7, C7, Dm7, CM7, C°, C+ et Cm7b5 échouent. Une lettre seule est un accord majeur, puisque la qualité d'un accord est facultative et que les accords passent avant les notes ([lignes 233-241](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L233-L241)).
- **La réponse ne dit rien des accords.** Elle nomme le cas et donne une glose écrite pour ce cas ([`GrothendieckParseSkill.cs` lignes 146-163](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs#L146-L163), [lignes 244-276](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs#L244-L276)) : « parse C ⊗ G » et « parse F# ⊗ Bb » reçoivent la même réponse, à l'expression qu'elles répètent près.

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

- **Seuls un mot d'ancrage initial et une espace sont retirés,** avec un « mean » ou un « do » final. « Parse: », « please parse » et « can you parse » partent à l'analyseur avec l'expression, tout comme un « please » final ; tous échouent.
- **Une question sur une notion est analysée comme une expression.** « explain the tensor product » et « explain natural transformation » reçoivent « Couldn't parse » ; « what is a pullback » et « what is the tensor product of C and G » sont déclinés. « parse Am ⊗ G7 » et « parse Dm7 ⊕ G7 » échouent sur les accords.

## Où le cours s'arrête

- **Le routeur n'est pas exécuté :** il a besoin des embeddings. La leçon pose aux skills leurs propres prompts d'exemple et les formulations qu'emploient leurs commentaires.
- **Les tableaux n'affichent que la façon dont le skill d'analyse a répondu,** pas ses messages : sa réponse ne donne l'erreur de l'analyseur que si `ASPNETCORE_ENVIRONMENT` vaut `Development` ([lignes 37-41](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs#L37-L41)), ce que le programme ne règle pas.
- **Les formes premières sont comparées à la table de GA,** et non au livre de Forte, et la leçon ne juge pas la théorie des catégories des gloses.
- **Le programme appelle directement les méthodes des skills et l'analyseur,** et non par le chatbot.

## Signalé en amont

- Signalés après l'écriture de cette leçon, dans le ticket de GA [#806](https://github.com/GuitarAlchemist/ga/issues/806) : la relation que le skill des ensembles ne lit jamais dans la tournure de ses propres prompts d'exemple, « via either operation », les ensembles lus à partir de leur dernier nombre, les formes de l'analyseur que cassent `str` et `choice`, et l'expression de surface étroite et la réponse du skill d'analyse.

## Exercices

1. Pourquoi « Are pitch class sets 0,1,3 and 0,2,3 equivalent under transposition » reçoit-il « Yes » ? Quelle formulation obtient la bonne réponse ?
2. Quel ensemble le skill compare-t-il dans « are pitch classes 0-1-4 and 0,1,6 equivalent » ? Pourquoi ?
3. Pourquoi `limit of {C, G}` n'est-il jamais analysé ?
4. Pourquoi « parse Am ⊗ G7 » échoue-t-il ? Comment faudrait-il écrire les deux accords ?

<details>
<summary>Solutions</summary>

1. Après « equivalent », `\s*` prend l'espace dont le groupe facultatif `\s+under` a besoin : le skill ne lit aucune relation et répond pour la classe d'ensembles (ligne 73) ; {0,1,3} et {0,2,3} forment une seule classe, par une inversion. « are 0,1,3 and 0,2,3 the same set class under transposition » reçoit « No — not equivalent under transposition alone ».
2. {4} : le premier ensemble doit être suivi de « and », il commence donc après le dernier tiret. La réponse affiche `4` comme ensemble A.
3. `str "limit"` a déjà lu l'espace qui suit « limit » (ligne 18), si bien que `ws1` n'en trouve aucune (ligne 411).
4. La liste des qualités contient « min » et « dom7 », mais ni « m » ni « 7 » (lignes 53-71) ; écrits comme le sont Cmin et Cdom7 dans le tableau, « Amin » et « Gdom7 ».

</details>

## À retenir

- Un `\s*` gourmand placé devant un groupe facultatif `\s+…` ne lui laisse rien à lire : testez chaque mot qu'une expression prétend lire.
- Un correctif qu'aucune formulation des prompts d'exemple n'atteint ne corrige pas les prompts d'exemple.
- Un nombre lu à la fin d'un jeton est un autre ensemble : un lecteur devrait refuser ce qu'il ne peut pas lire en entier.
- Dans un analyseur à combinateurs, un mot qui mange ses espaces fait échouer chaque « puis une espace », et une première alternative qui lit l'entrée cache les autres.
- Une réponse qui nomme l'opération sans rien dire de ses opérandes n'apprend pas grand-chose à l'utilisateur sur ses accords.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs`, `Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs`, `Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs`, `Common/GA.Business.DSL/Types/GrammarTypes.fs`, `Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs`, `Common/GA.Domain.Core/Theory/Atonal/CanonicalForteCatalog.cs`, `Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`.
- GuitarAlchemist/ga au commit [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) : les mêmes skills, avec leurs refus marqués `Declined`, le même analyseur, et le `PitchClassSet.cs` réécrit.
- Les programmes du cours : `code/ga-ai/GaAi/Lesson24.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/SetEquivalenceParseProbe.cs`.
