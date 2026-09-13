---
title: 6. Option, Result et ?
description: Ni null ni exceptions — l'absence et l'échec comme valeurs ordinaires.
sidebar:
  order: 6
---

Exemple complet : [`examples/l06_option_result.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l06_option_result.rs) — `cargo run --example l06_option_result`.

## Deux choses que Rust n'a pas

Rust n'a **pas de `null`** et **pas d'exceptions**. Les deux sont remplacés par deux enums de la bibliothèque standard — construites exactement comme celles de la [leçon 5](../05-structs-enums-match/) :

```rust
enum Option<T> {
    Some(T),
    None,
}

enum Result<T, E> {
    Ok(T),
    Err(E),
}
```

| Situation | C# | Java | Rust |
|---|---|---|---|
| Une valeur peut être absente | `null`, `int?`, types référence nullables (avertissements) | `null`, `Optional<T>` | `Option<T>` |
| Une opération peut échouer | exceptions (non vérifiées) | exceptions vérifiées et non vérifiées | `Result<T, E>` |
| Un bug, irrécupérable | `Environment.FailFast`, exception non gérée | `Error`, exception non gérée | `panic!` |

Comme l'absence et l'échec font partie du **type**, vous ne pouvez pas les oublier.

## `Option<T>`

```rust
fn find_user(users: &HashMap<u32, User>, id: u32) -> Option<&User> {
    users.get(&id)
}

match find_user(&users, 3) {
    Some(user) => println!("found {}", user.name),
    None => println!("no user 3"),
}
```

Un `Option<i32>` n'est pas un `i32`, donc vous ne pouvez pas l'utiliser par accident :

```rust
let maybe: Option<i32> = Some(1);
let total = maybe + 1;
```

```text
error[E0369]: cannot add `{integer}` to `Option<i32>`
   --> e06_option_add.rs:3:23
    |
  3 |     let total = maybe + 1;
    |                 ----- ^ - {integer}
    |                 |
    |                 Option<i32>
```

En C#, la `NullReferenceException` équivalente se produirait à l'exécution.

### Combinateurs

Au lieu de `if (x != null)` imbriqués, enchaînez des méthodes — elles se lisent comme `?.` et `??` :

```rust
let name_len = find_user(&users, 2).map(|u| u.name.len()).unwrap_or(0);
```

| Rust | C# | Java `Optional` |
|---|---|---|
| `opt.map(f)` | `x?.F()` | `opt.map(f)` |
| `opt.unwrap_or(v)` | `x ?? v` | `opt.orElse(v)` |
| `opt.unwrap_or_else(f)` | `x ?? F()` | `opt.orElseGet(f)` |
| `opt.and_then(f)` | `x?.F()` où `F` renvoie une valeur nullable | `opt.flatMap(f)` |
| `opt.ok_or(err)` | `x ?? throw …` | `opt.orElseThrow(…)` |
| `opt.is_some()` / `is_none()` | `x != null` | `opt.isPresent()` |

## `Result<T, E>`

Une fonction qui peut échouer le dit dans sa signature — un peu comme une exception vérifiée en Java, mais sous forme de valeur de retour :

```rust
fn sum_csv(line: &str) -> Result<i32, ParseIntError> {
    let mut total = 0;
    for field in line.split(',') {
        total += field.trim().parse::<i32>()?;
    }
    Ok(total)
}

println!("{:?}", sum_csv("1, 2, 3"));     // Ok(6)
println!("{:?}", sum_csv("1, two, 3"));   // Err(ParseIntError { kind: InvalidDigit })
```

Ignorer un `Result` provoque un avertissement, car cela peut masquer une erreur :

```text
warning: unused `Result` that must be used
 --> e06_unused_result.rs:6:5
  |
6 |     save();
  |     ^^^^^^
  |
  = note: this `Result` may be an `Err` variant, which should be handled
```

## L'opérateur `?`

`?` signifie : *si c'est `Ok`/`Some`, extraire la valeur ; sinon, renvoyer immédiatement le `Err`/`None` depuis la fonction courante.* C'est l'équivalent explicite et visible de la propagation d'une exception.

```rust
fn manager_name(users: &HashMap<u32, User>, id: u32) -> Option<&str> {
    let user = find_user(users, id)?;                  // utilisateur inexistant → None
    let manager = find_user(users, user.manager_id?)?; // pas de manager → None
    Some(&manager.name)
}
```

```text
manager of 2: Some("Grace")
manager of 1: None
manager of 9: None
```

`?` ne fonctionne que dans une fonction qui renvoie elle-même un `Result` ou un `Option` :

```text
error[E0277]: the `?` operator can only be used in a function that returns `Result` or `Option` (or another type that implements `FromResidual`)
 --> e06_question_in_main.rs:2:35
  |
1 | fn main() {
  | --------- this function should return `Result` or `Option` to accept `?`
2 |     let port: u16 = "3000".parse()?;
  |                                   ^ cannot use the `?` operator in a function that returns `()`
  |
help: consider adding return type
  |
1 ~ fn main() -> Result<(), Box<dyn std::error::Error>> {
2 |     let port: u16 = "3000".parse()?;
3 |     println!("{port}");
4 +     Ok(())
  |
```

## Vos propres types d'erreur

Une erreur peut être de n'importe quel type ; une `enum` énumère les façons dont une opération peut échouer :

```rust
#[derive(Debug)]
enum ConfigError {
    Missing(&'static str),
    BadNumber { key: &'static str, source: ParseIntError },
}

impl fmt::Display for ConfigError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            ConfigError::Missing(key) => write!(f, "missing key `{key}`"),
            ConfigError::BadNumber { key, source } => write!(f, "`{key}` is not a number: {source}"),
        }
    }
}

impl Error for ConfigError {}

fn read_port(config: &HashMap<&str, &str>) -> Result<u16, ConfigError> {
    let raw = config.get("port").ok_or(ConfigError::Missing("port"))?;
    raw.parse::<u16>().map_err(|source| ConfigError::BadNumber { key: "port", source })
}
```

```text
Err("missing key `port`")
Err("`port` is not a number: invalid digit found in string")
Ok(3000)
```

- `ok_or` transforme un `Option` en `Result` ; `map_err` convertit un type d'erreur en un autre — comme attraper une exception pour l'envelopper.
- `Display` est le message destiné aux utilisateurs, `Debug` les détails destinés aux développeurs.
- Dans les vrais projets, la crate [`thiserror`](https://crates.io/crates/thiserror) génère ce code répétitif pour les bibliothèques, et [`anyhow`](https://crates.io/crates/anyhow) offre un type d'erreur fourre-tout pour les applications.

### `main` peut renvoyer un `Result`

```rust
fn main() -> Result<(), Box<dyn Error>> {
    let port = read_port(&config)?;   // ConfigError se convertit en Box<dyn Error>
    println!("listening on {port}");
    Ok(())
}
```

`Box<dyn Error>` accepte n'importe quel type d'erreur, donc `?` fonctionne avec des erreurs différentes dans la même fonction. Si `main` renvoie `Err`, Rust l'affiche avec son format **`Debug`** et se termine avec le code 1 :

```text
Error: Missing("port")
```

## Quand paniquer

`unwrap()` et `expect("…")` extraient la valeur ou **paniquent** :

```rust
let port: u16 = "http".parse().expect("PORT must be a number");
```

```text
thread 'main' panicked at e06_unwrap_panic.rs:2:36:
PORT must be a number: ParseIntError { kind: InvalidDigit }
```

| Utiliser | Pour |
|---|---|
| `Result` + `?` | tout ce qui peut échouer en fonctionnement normal : E/S, analyse d'entrées utilisateur, réseau |
| `expect("why this cannot fail")` | les invariants que vous avez vérifiés, les tests, les prototypes rapides |
| `unwrap()` | les tests et les exemples ; en code de production, préférez `expect` avec une raison |

Une panique n'est pas un mécanisme de `try/catch` : traitez-la comme un rapport de bug.

## À retenir

- `Option<T>` remplace `null` ; `Result<T, E>` remplace les exceptions ; les deux sont des enums ordinaires.
- Le compilateur refuse d'utiliser un `Option<T>` comme un `T`, et avertit quand un `Result` est ignoré.
- `?` propage `None`/`Err` à l'appelant — explicite, mais aussi concis qu'une exception.
- Modélisez les erreurs avec des enums, convertissez-les avec `map_err`/`From`, et réservez `panic!` aux bugs.

## Exercices

1. Traduisez cette méthode C# et son point d'appel en Rust, en utilisant `Option` et `unwrap_or` :

```csharp
int? FindAge(Dictionary<string, int> ages, string name) =>
    ages.TryGetValue(name, out var age) ? age : null;

var age = FindAge(ages, "Ada") ?? -1;
```

<details>
<summary>Solution</summary>

```rust
use std::collections::HashMap;

fn find_age(ages: &HashMap<&str, u32>, name: &str) -> Option<u32> {
    ages.get(name).copied()
}

let ages = HashMap::from([("Ada", 36)]);
let age = find_age(&ages, "Ada").map(i64::from).unwrap_or(-1);
assert_eq!(age, 36);
assert_eq!(find_age(&ages, "Bob"), None);
```

`get` renvoie `Option<&u32>` ; `.copied()` le transforme en `Option<u32>`. Renvoyer `-1` comme valeur sentinelle exige un type signé — en Rust, on conserverait généralement l'`Option`.

</details>

2. Écrivez `fn parse_point(text: &str) -> Result<(i32, i32), String>` de sorte que `"3,4"` donne `Ok((3, 4))`, `"3"` donne `Err("expected x,y")`, et `"3,z"` donne une erreur qui mentionne l'échec de l'analyse. Utilisez `?`.

<details>
<summary>Solution</summary>

```rust
fn parse_point(text: &str) -> Result<(i32, i32), String> {
    let (x, y) = text.split_once(',').ok_or("expected x,y")?;
    let x = x.trim().parse::<i32>().map_err(|e| format!("bad x: {e}"))?;
    let y = y.trim().parse::<i32>().map_err(|e| format!("bad y: {e}"))?;
    Ok((x, y))
}

assert_eq!(parse_point("3,4"), Ok((3, 4)));
assert_eq!(parse_point("3"), Err(String::from("expected x,y")));
assert_eq!(parse_point("3,z"), Err(String::from("bad y: invalid digit found in string")));
```

`?` convertit aussi le `&str` issu de `ok_or` en `String`, car `String` implémente `From<&str>`.

</details>

3. `let port: u16 = "3000".parse()?;` ne compile pas dans `fn main()`. Donnez deux corrections.

<details>
<summary>Solution</summary>

- Changer la signature en `fn main() -> Result<(), Box<dyn std::error::Error>>` et terminer par `Ok(())`, afin que `?` ait un endroit où renvoyer l'erreur.
- Ou gérer l'erreur localement, par exemple `let port: u16 = "3000".parse().expect("PORT must be a number");` ou un `match`.

</details>

## Sources

- [The Book, ch. 9 — Error Handling](https://doc.rust-lang.org/book/ch09-00-error-handling.html)
- [`Option` — bibliothèque standard](https://doc.rust-lang.org/std/option/enum.Option.html)
- [`Result` — bibliothèque standard](https://doc.rust-lang.org/std/result/enum.Result.html)
- [L'opérateur `?` — Rust Reference](https://doc.rust-lang.org/reference/expressions/operator-expr.html#the-question-mark-operator)
