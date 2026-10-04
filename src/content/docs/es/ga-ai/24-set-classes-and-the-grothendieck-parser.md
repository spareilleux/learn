---
title: "Lección 24: Las clases de conjuntos y el analizador Grothendieck"
description: "SetTheoryEquivalenceSkill y GrothendieckParseSkill son las dos skills del chatbot de Guitar Alchemist para la teoría de conjuntos y la teoría de categorías: la primera compara dos conjuntos de clases de altura bajo transposición, inversión o ambas, la segunda envía una expresión al analizador F# de GA. La primera nunca lee la relación en la formulación de sus propios prompts de ejemplo, así que una pareja relacionada solo por inversión es equivalente bajo transposición, y lee 0-1-4 como el conjunto 4; el analizador de la segunda falla con la mitad de las formas que nombran sus comentarios, y con Am y G7, y su respuesta nombra el caso y nada de los acordes."
sidebar:
  label: 24. Las clases de conjuntos y el analizador
  order: 24
---

Las lecciones [22](../22-similar-chords/) y [23](../23-harmonic-distance-and-path/) interrogaron a las skills construidas sobre los vectores interválicos. Otras dos skills registradas junto a ellas leen teoría de conjuntos y teoría de categorías ([`GaPlugin.cs` línea 78](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L78), [línea 103](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L103)): `SetTheoryEquivalenceSkill` dice si dos conjuntos de clases de altura son equivalentes bajo transposición, inversión o ambas ([`SetTheoryEquivalenceSkill.cs` líneas 7-25](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L7-L25)), y `GrothendieckParseSkill` envía una expresión al analizador Grothendieck de GA, escrito en F#, y nombra el caso de la operación que recibe de vuelta ([`GrothendieckParseSkill.cs` líneas 8-28](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs#L8-L28)). Ninguna llama a un modelo. El `CanHandle` de la skill de conjuntos prueba sus patrones; el de la skill de análisis siempre dice que no: en el commit fijado, el enrutador no la llama, como mostró la [lección 14](../14-what-the-substitution-skill-answers/).

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que nombran otro. En el `main` de GA en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), las dos skills solo marcan su rechazo con `Declined`, y el analizador y sus tipos no han cambiado; `PitchClassSet` se reescribió en torno a tablas precalculadas, así que `GaMain` vuelve a preguntar. Su salida imprime las mismas tablas que la del commit fijado, bajo títulos que dicen "on main". La salida procede de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l24
dotnet run --project code/ga-ai/GaMain -c Release -- l24
```

## Cómo leen las skills una pregunta

La skill de conjuntos quiere dos conjuntos de cifras unidos por "and", después "equivalent", "the same" u otras pocas palabras y después, opcionalmente, "under" y una relación:

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

La skill de análisis quiere una palabra de anclaje y un elemento de teoría de categorías, y después envía al analizador lo que sigue a la palabra de anclaje:

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

## Las formulaciones de GA

El programa le hace a cada skill sus prompts de ejemplo, le hace los mismos a la otra skill y le pregunta a `DefaultRoutingHintProvider` qué intenciones reforzaría cada uno. Los dos comentarios de documentación y los rechazos repiten los prompts de ejemplo; el mensaje de fallo de la skill de análisis sugiere además `Transpose(Cmaj7)`:

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

- **La skill de conjuntos responde a 4 de sus 5 prompts de ejemplo.** "Are pitch classes 0,2,4 and 1,3,5 transpositionally equivalent" pone "transpositionally" entre el segundo conjunto y "equivalent". Dos de los cuatro a los que responde nombran una relación que no lee, y uno de ellos recibe el veredicto equivocado, como muestra la sección siguiente.
- **La skill de análisis responde a 5 de sus 10.** "parse Cmaj7 + Gmaj7 + Fmaj7", "explain power(Cmaj7)" y "parse Transpose(Cmaj7)", la forma que sugiere su propio mensaje de fallo ([línea 177](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs#L177)), no contienen ninguno de los símbolos y palabras que busca su patrón de superficie; "what is Hom(Cmaj7, Gmaj7)" empieza por "what is", que no es una palabra de anclaje. El analizador rechaza "Transpose(C ⊗ G)", ya que un funtor se aplica a un objeto musical, no a una operación ([`GrothendieckOperationsParser.fs` líneas 321-327](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L321-L327)), y "equalizer Transpose Invert", que no tiene paréntesis.
- **Ninguna de las dos skills responde a los prompts de la otra.** Ninguna regla de pistas nombra a la skill de conjuntos; dos de sus prompts, con "transposition" y "transpositionally", refuerzan a `skill.transpose`, cuya regla acepta cualquier palabra que empiece por "transpos" ([`DefaultRoutingHintProvider.cs` líneas 257-259](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L257-L259)). La regla de la skill de análisis refuerza 6 de sus 10 ([líneas 146-153](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L146-L153)).

## La relación que lee la skill de conjuntos

La skill calcula la clase de conjuntos de los dos conjuntos y responde para la relación que ha leído: "transposition", "inversion", o la clase de conjuntos cuando no ha leído ninguna ([líneas 69-80](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L69-L80)). "Under inversion" significa transposición o inversión, como dice su comentario ([líneas 137-141](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L137-L141)). Se añadió una comprobación de la transposición sola después de que una revisión sorprendiera a la skill llamando equivalentes bajo transposición a {0,1,4} y {0,3,4}, el 2026-05-13 según su comentario ([líneas 97-107](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L97-L107)). El programa pregunta cuatro parejas en diez formulaciones:

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

- **"equivalent under transposition" y "equivalent under inversion" se responden para la clase de conjuntos.** Tras "equivalent", `\s*` se lleva el espacio que necesita `\s+under`, y como ese grupo es opcional, la coincidencia termina sin él. {0,1,3} y {0,2,3} "under transposition", el segundo prompt de ejemplo de la skill, reciben "Yes — they belong to the same set class" (sí, pertenecen a la misma clase de conjuntos), aunque solo una inversión lleva uno al otro.
- **La relación se lee tras "set class", "set" o "class".** "are 0,1,3 and 0,2,3 the same set class under transposition" recibe "No — not equivalent under transposition alone" (no, no son equivalentes bajo la transposición sola), la respuesta para la que se escribió esa comprobación.
- **"related by inversion" también se responde para la clase de conjuntos,** y "transpositionally equivalent" e "is … a transposition of …" se rechazan.

## Todas las parejas de conjuntos de tres y de cuatro notas

El programa pregunta cada pareja ordenada de los 220 conjuntos de tres notas, y después de los 495 de cuatro, en cuatro formulaciones, y compara cada veredicto con su propia prueba de la relación que nombra la pregunta:

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

- **"equivalent under transposition" se equivoca en 2016 de las 48400 parejas de tres notas y en 4032 de las 245025 de cuatro,** todas "yes" para parejas que solo relaciona una inversión. Cuando la skill lee la relación, todos los veredictos son correctos, como lo es toda respuesta sobre conjuntos en relación Z: 1152 parejas de cuatro notas, ninguna de tres.
- **"via either operation" es falso para la mayoría de las parejas de las que se dice.** Una pareja relacionada por transposición, preguntada "under inversion", recibe "Yes — equivalent under inversion (and also under transposition alone; they reduce to the same prime form via either operation)" (sí, equivalentes bajo inversión, y también bajo la transposición sola; se reducen a la misma forma prima por cualquiera de las dos operaciones) ([línea 144](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L144)). Ninguna inversión lleva el primer conjunto al segundo en 2016 de las 2608 parejas de tres notas de las que se dice, ni en 4032 de las 5841 de cuatro: las dos operaciones solo sirven para los conjuntos simétricos por inversión.

## Los conjuntos que lee

El programa escribe {0,1,4} de distintas maneras, da cada escritura al `TryParseSet` privado de la skill y la incluye en una pregunta:

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

- **Se leen comas, espacios, corchetes y llaves,** así como las cifras escritas juntas: `TryParseSet` separa "014" en 0, 1 y 4 ([líneas 218-241](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs#L218-L241)).
- **Un guion solo deja el último número.** El primer conjunto del patrón debe ir seguido de " and", así que empieza tras el último guion: "0-1-4" se pregunta como {4}, y el nombre de Forte "3-3" como {3}. La respuesta muestra `4` y `3` como conjunto A, y los compara como si fueran lo que se preguntó.
- **10 y 11 deben escribirse con cifras.** "t", "T", "A", "0te" y "01t" se rechazan; `TryParseSet` por sí solo descartaría la letra. Los paréntesis y los corchetes angulares se rechazan, y 12 no se puede analizar.

La forma prima que imprime la skill es la menor de las 24 transposiciones e inversiones del conjunto, como bits ([`PitchClassSetId.cs` líneas 123-156](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L123-L156)). El programa la comprueba en los 4096 conjuntos y frente a la propia tabla de GA del catálogo de Forte ([`CanonicalForteCatalog.cs` líneas 3-20](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/CanonicalForteCatalog.cs#L3-L20)):

```text
== The prime forms SetTheoryEquivalenceSkill prints, at the pin
sets 4096, distinct prime forms 224, sets whose 24 transpositions and inversions all give the same prime form 4096
Forte labels CanonicalForteCatalog resolves 224; whose stored set differs from its PrimeForm 0; prime forms no label gives 0
interval-class vectors shared by two prime forms of the same size (Z pairs) 23
```

- **Las formas primas se sostienen:** hay 224, cada una igual para las 24 transposiciones e inversiones de un conjunto, cada una el conjunto que da la tabla de GA para una de las 224 etiquetas que resuelve, y 23 parejas de ellas comparten un vector.

## Las expresiones que lee el analizador

El analizador está escrito con FParsec. Su `str` lee una palabra y los espacios que la siguen ([`GrothendieckOperationsParser.fs` línea 18](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L18)), y muchas de sus formas piden después al menos un espacio más, como hacen los límites:

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

El programa escribe una expresión para cada forma que nombran los comentarios del analizador, con el caso que promete el comentario, se la da al analizador y después le pregunta a la skill "parse" y la expresión:

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

- **25 de las 50 formas se analizan, 21 en el caso que promete su comentario.** Una forma que lee `str` y después `ws1` nunca encuentra su espacio: "limit of", "lim", "colimit of", "colim", "define functor", "natural transformation", "define nat_trans", "define sheaf", "truth_value of", "subobjects of", "glue", y "transpose" seguido de un número en un pullback. "restrict S to U" falla antes: el analizador quiere el nombre del haz antes de "restrict", así que lee "restrict" como ese nombre ([líneas 538-543](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L538-L543)).
- **Una primera alternativa que lee una palabra oculta las demás.** El `choice` de FParsec solo prueba la alternativa siguiente cuando la anterior falla sin leer nada. "C tensor G" falla porque la primera alternativa lee "C" y después quiere ⊗, y lo mismo les ocurre a las otras formas con palabra entre dos objetos; "apply Invert to C" y "compose(Transpose, Invert)" fallan porque la primera alternativa lee "apply" o "compose" como un nombre. "tensor(C, G)", cuya primera alternativa no lee nada, se analiza.
- **"P(C)", "power(C)", "Ω(C)" y "eta(C)" son aplicaciones de funtor.** El analizador prueba los funtores antes que las transformaciones naturales y las operaciones de topos ([líneas 625-633](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L625-L633)), y una aplicación de funtor es un nombre seguido de un objeto entre paréntesis ([líneas 321-327](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L321-L327)).
- **Ninguna de las 50 formas alcanza 9 de los 22 casos:** `Limit`, `Colimit`, `Equalizer`, `Coequalizer`, los dos casos de transformación natural, `PowerObject` y dos de los tres casos de haces. Escritos sin sus espacios, "S|U", "eq(invert,reflect)" y "coeq(invert,reflect)" se analizan y alcanzan tres de ellos: esas formas leen su coma y su "|" con `pstring`, que no salta el espacio que las sigue. "equalizer((invert,reflect)" también se analiza: la línea 426 agrupa como `((str "equalizer" >>. pstring "(") <|> str "eq") >>. pstring "("`, así que "equalizer" necesita dos paréntesis. Las tres expresiones con dos operadores seguidos fallan.
- **La skill responde para 12 formas.** Su patrón de superficie deja pasar ⊗, ⊕, ×, ∘ y algunas palabras, pero no "+", "^" seguido de un espacio, Ω ni "=>", así que "C + G", "C ^ G", "Ω" y "C => G" se rechazan aunque se analizan, igual que las formas escritas como una llamada, como "tensor(C, G)" o "Invert(C)".

## Los acordes que lee el analizador

El programa le pregunta al analizador `<chord> ⊗ G` para acordes escritos de distintas maneras, y después le hace a la skill preguntas formuladas de distintas maneras:

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

- **El analizador solo lee los nombres de cualidad de su lista,** escritos con letras, como "maj7", "min7", "dom7", "min", "dim" o "sus4", y "6/9" ([líneas 53-71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L53-L71)). Am, Cm, G7, C7, Dm7, CM7, C°, C+ y Cm7b5 fallan. Una letra sola es un acorde mayor, ya que la cualidad de un acorde es opcional y los acordes van antes que las notas ([líneas 233-241](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs#L233-L241)).
- **La respuesta no dice nada de los acordes.** Nombra el caso y da una glosa escrita para el caso ([`GrothendieckParseSkill.cs` líneas 146-163](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs#L146-L163), [líneas 244-276](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs#L244-L276)): "parse C ⊗ G" y "parse F# ⊗ Bb" reciben la misma respuesta, salvo la expresión que repiten.

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

- **Solo se quitan una palabra de anclaje inicial y un espacio,** junto con un "mean" o un "do" final. "Parse:", "please parse" y "can you parse" llegan al analizador con la expresión, igual que un "please" final; todas fallan.
- **Una pregunta sobre un concepto se analiza como una expresión.** "explain the tensor product" y "explain natural transformation" reciben "Couldn't parse"; "what is a pullback" y "what is the tensor product of C and G" se rechazan. "parse Am ⊗ G7" y "parse Dm7 ⊕ G7" fallan por los acordes.

## Hasta dónde llega el curso

- **No se ejecuta el enrutador:** necesita los embeddings. La lección les hace a las skills sus propios prompts de ejemplo y las formulaciones que usan sus comentarios.
- **Las tablas solo imprimen cómo respondió la skill de análisis,** no sus mensajes: su respuesta solo da el error del analizador cuando `ASPNETCORE_ENVIRONMENT` vale `Development` ([líneas 37-41](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs#L37-L41)), y el programa no lo define.
- **Las formas primas se comparan con la propia tabla de GA,** no con el libro de Forte, y la lección no juzga la teoría de categorías de las glosas.
- **El programa llama directamente a los métodos de las skills y al analizador,** no a través del chatbot.

## Ejercicios

1. ¿Por qué recibe "Are pitch class sets 0,1,3 and 0,2,3 equivalent under transposition" un "Yes"? ¿Qué formulación obtiene la respuesta correcta?
2. ¿Qué conjunto compara la skill en "are pitch classes 0-1-4 and 0,1,6 equivalent"? ¿Por qué?
3. ¿Por qué nunca se analiza `limit of {C, G}`?
4. ¿Por qué falla "parse Am ⊗ G7"? ¿Cómo habría que escribir los dos acordes?

<details>
<summary>Soluciones</summary>

1. Tras "equivalent", `\s*` se lleva el espacio que necesita el grupo opcional `\s+under`, así que la skill no lee ninguna relación y responde para la clase de conjuntos (línea 73); {0,1,3} y {0,2,3} forman una misma clase de conjuntos, mediante una inversión. "are 0,1,3 and 0,2,3 the same set class under transposition" recibe "No — not equivalent under transposition alone".
2. {4}: el primer conjunto debe ir seguido de " and", así que empieza tras el último guion. La respuesta muestra `4` como conjunto A.
3. `str "limit"` ya ha leído el espacio que sigue a "limit" (línea 18), así que `ws1` no encuentra ninguno (línea 411).
4. La lista de cualidades tiene "min" y "dom7", pero ni "m" ni "7" (líneas 53-71); escritos como lo están Cmin y Cdom7 en la tabla, "Amin" y "Gdom7".

</details>

## Puntos clave

- Un `\s*` voraz antes de un grupo opcional `\s+…` no le deja nada que leer: prueba cada palabra que un patrón dice leer.
- Una corrección a la que no llega ninguna formulación de los prompts de ejemplo no corrige los prompts de ejemplo.
- Un número leído desde el final de un token es otro conjunto: un lector debería rechazar lo que no puede leer entero.
- En un analizador de combinadores, una palabra que se come sus espacios hace fallar cada "después un espacio", y una primera alternativa que lee entrada oculta las demás.
- Una respuesta que nombra la operación y nada de sus operandos le dice poco al usuario sobre sus acordes.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/SetTheoryEquivalenceSkill.cs`, `Common/GA.Business.ML/Agents/Skills/GrothendieckParseSkill.cs`, `Common/GA.Business.DSL/Parsers/GrothendieckOperationsParser.fs`, `Common/GA.Business.DSL/Types/GrammarTypes.fs`, `Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs`, `Common/GA.Domain.Core/Theory/Atonal/CanonicalForteCatalog.cs`, `Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`.
- GuitarAlchemist/ga en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): las mismas skills, con sus rechazos marcados con `Declined`, el mismo analizador y el `PitchClassSet.cs` reescrito.
- Los programas del curso: `code/ga-ai/GaAi/Lesson24.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/SetEquivalenceParseProbe.cs`.
