---
title: 8. Expressions de calcul — un parseur pour un DSL
description: Comprendre les expressions seq, async et task, puis construire une expression de calcul de parsing où let! enchaîne la grammaire d'un DSL de notes et Result transporte les erreurs.
sidebar:
  order: 8
---

Code : [`examples/l08_parser_ce.fsx`](https://github.com/spareilleux/learn/blob/main/code/fsharp/examples/l08_parser_ce.fsx), exécuté par le harness du cours.

## Une syntaxe, plusieurs calculs

Une [expression de calcul](https://learn.microsoft.com/dotnet/fsharp/language-reference/computation-expressions) F# a la forme `builder { ... }`. Le builder décide de la signification de `let!`, `do!`, `return`, `yield` et des autres mots-clés.

| Expression | Calcul décrit | Équivalent approximatif en C#/Java |
|---|---|---|
| `seq { yield value }` | séquence paresseuse | itérateur / `IEnumerable`, `Stream` |
| `async { let! value = work }` | workflow asynchrone F# | composition de futures |
| `task { let! value = work }` | `Task` .NET | `async`/`await`, `CompletableFuture` |
| `parser { let! value = rule }` | parseur qui consomme du texte ou échoue | pipeline de combinators de parsing |

Cette syntaxe est pilotée par des méthodes ordinaires. Ainsi :

```fsharp
parser {
    let! value = rule
    return transform value
}
```

est conceptuellement traduit en :

```fsharp
parser.Bind(rule, fun value -> parser.Return(transform value))
```

`let!` n'est donc ni une affectation ni forcément une opération asynchrone. Il extrait le contexte choisi par le builder. `and!` représente des calculs indépendants et demande notamment `MergeSources` ; notre parseur reste séquentiel, car chaque règle consomme le reste laissé par la précédente.

## Le type de calcul

L'exemple représente un parseur par une fonction qui reçoit le texte restant et renvoie soit une valeur avec le reste, soit une erreur :

```fsharp
type Parser<'value> =
    private
    | Parser of (string -> Result<'value * string, string>)
```

`bind` exécute le premier parseur. En cas d'échec, il conserve l'erreur ; en cas de succès, il transmet la valeur à la fonction qui construit le parseur suivant, puis l'exécute sur le texte restant :

```fsharp
let bind next parser =
    Parser(fun input ->
        match run parser input with
        | Error error -> Error error
        | Ok(value, rest) -> run (next value) rest)
```

Le builder n'a besoin que de trois membres pour la syntaxe utilisée ici :

```fsharp
type ParserBuilder() =
    member _.Bind(parser, next) = Parser.bind next parser
    member _.Return(value) = Parser.result value
    member _.ReturnFrom(parser) = parser

let parser = ParserBuilder()
```

Ajouter `Delay`, `Combine`, `TryWith`, `Using`, `While` ou `MergeSources` activerait d'autres constructions. Ne les ajoutez pas par réflexe : les méthodes du builder constituent sa grammaire publique.

## Le DSL de notes

Le script complet définit de petites règles pour un littéral, un caractère satisfaisant un prédicat, une altération facultative et la fin du texte. La grammaire exprime alors directement son intention :

```fsharp
let noteParser =
    parser {
        let! _ = Parser.literal "note "
        let! letter = Parser.satisfy "note letter A-G" (fun value -> value >= 'A' && value <= 'G')
        let! accidental = Parser.optionalChar [ '#'; 'b' ]
        let! octave = Parser.satisfy "octave 0-9" Char.IsDigit
        do! Parser.endOfInput

        let name =
            match accidental with
            | Some symbol -> $"{letter}{symbol}"
            | None -> string letter

        return { Name = name; Octave = int (string octave) }
    }
```

Sortie mesurée :

```text
OK note C#4      -> C#4
OK note Eb3      -> Eb3
ERROR note H2    -> expected note letter A-G, got 'H'
ERROR note C#4 tail -> expected end of input, got " tail"
```

`do! Parser.endOfInput` est essentiel. Sans lui, `note C#4 tail` réussirait en ignorant silencieusement le suffixe — exactement la classe de bug DSL relevée dans le parseur d'accords de GA dans le [journal](../journal/#2026-09-15--dogfooding-guitar-alchemist).

## Jusqu'où le construire soi-même

Ce parseur pédagogique ne suit ni ligne ni colonne, ne distingue pas une divergence récupérable d'un échec engagé et n'implémente pas de backtracking contrôlé. Pour une grammaire de production, utilisez une bibliothèque éprouvée comme [FParsec](https://www.quanttec.com/fparsec/) ou un parseur de projet offrant les mêmes garanties. L'expression de calcul reste utile : elle rend explicite la politique d'enchaînement et sépare la grammaire de la propagation des erreurs.

## Exercice

Écrivez un parseur pour `octave 4`. Réutilisez `literal`, `satisfy` et `endOfInput`, puis renvoyez l'octave comme `int`. Vérifiez que `octave 42` échoue parce qu'il reste du texte.

<details>
<summary>Solution</summary>

```fsharp
let octaveParser =
    parser {
        let! _ = Parser.literal "octave "
        let! digit = Parser.satisfy "octave 0-9" Char.IsDigit
        do! Parser.endOfInput
        return int (string digit)
    }
```

La règle à un chiffre est volontaire. Accepter plusieurs chiffres est une nouvelle décision de grammaire, pas une raison de retirer le contrôle de fin.

</details>

## À retenir

- Une expression de calcul est une syntaxe pilotée par un builder, pas un synonyme d'asynchronisme.
- `let!` appelle `Bind` ; `return` appelle `Return` ; le builder définit leur effet.
- Un builder de parsing réutilise l'enchaînement et la propagation des erreurs sans masquer la grammaire.
- Une règle explicite de fin empêche un préfixe valide d'accepter une commande DSL invalide.
