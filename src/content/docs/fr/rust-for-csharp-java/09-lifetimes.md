---
title: 9. Durées de vie
description: Comment le compilateur prouve qu'une référence ne survit jamais à sa valeur — annotations, élision, structs qui empruntent et 'static.
sidebar:
  order: 9
---

Exemple complet : [`examples/l09_lifetimes.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-for-csharp-java/examples/l09_lifetimes.rs) — `cargo run --example l09_lifetimes`.

## Le problème que cache un ramasse-miettes

En C# ou en Java, une référence maintient son objet en vie : tant que vous pouvez l'atteindre, le [ramasse-miettes](https://learn.microsoft.com/dotnet/standard/garbage-collection/fundamentals) ne le libère pas. Une [« référence pendante »](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html#dangling-references) ne peut tout simplement pas exister.

Rust n'a pas de ramasse-miettes. Une valeur est libérée quand son propriétaire sort de la portée ([leçon 3](../03-ownership-and-moves/)), donc le compilateur doit prouver qu'aucune référence n'est encore utilisée à ce moment-là ([`src/lib.rs`, lignes 474-479](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L474-L479)) :

```rust
let r;
{
    let s = String::from("hello");
    r = &s;
}
println!("{r}");
```

```text
error[E0597]: `s` does not live long enough
 --> e09_dangling.rs:5:13
  |
4 |         let s = String::from("hello");
  |             - binding `s` declared here
5 |         r = &s;
  |             ^^ borrowed value does not live long enough
6 |     }
  |     - `s` dropped here while still borrowed
7 |     println!("{r}");
  |                - borrow later used here
```

L'intervalle pendant lequel une référence est valide est sa **durée de vie** (lifetime). À l'intérieur d'une seule fonction, le compilateur déduit les durées de vie tout seul — vous comptez dessus depuis la leçon 4. Vous ne les écrivez que lorsqu'une référence franchit une **frontière de fonction ou de struct** et que le compilateur ne peut pas deviner la relation.

:::note[Les durées de vie ne changent en rien le temps que vivent les valeurs]
Une annotation de durée de vie est une *description* que le compilateur vérifie, pas une instruction. Écrire `'a` ne maintient jamais une valeur en vie plus longtemps, contrairement au fait de détenir une référence en C#.
:::

## Annoter une fonction

De quelle entrée le résultat est-il emprunté ?

Extrait de [`src/lib.rs`, lignes 485-487](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L485-L487) :

```rust
fn longest(a: &str, b: &str) -> &str {
    if a.len() >= b.len() { a } else { b }
}
```

```text
error[E0106]: missing lifetime specifier
 --> e09_longest.rs:1:33
  |
1 | fn longest(a: &str, b: &str) -> &str {
  |               ----     ----     ^ expected named lifetime parameter
  |
  = help: this function's return type contains a borrowed value, but the signature does not say whether it is borrowed from `a` or `b`
help: consider introducing a named lifetime parameter
  |
1 | fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
  |           ++++     ++          ++          ++
```

Le compilateur vérifie chaque fonction sur sa **seule signature**, jamais sur son corps — de la même façon qu'un appelant C# ne voit que la déclaration d'une méthode. La signature doit donc le dire ([lignes 2-4](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L2-L4)) :

```rust
fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() >= b.len() { a } else { b }
}
```

Lisez `<'a>` comme un [paramètre générique](https://doc.rust-lang.org/reference/items/generics.html) (il est déclaré au même endroit que `<T>`) : *« pour une certaine durée de vie `'a` pendant laquelle `a` et `b` sont tous deux valides, le résultat est lui aussi valide pendant `'a` »*. En pratique, `'a` devient la **plus courte** des deux, si bien que l'appelant ne peut pas garder le résultat plus longtemps que l'une ou l'autre des entrées ([`src/lib.rs`, lignes 496-502](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L496-L502)) :

```rust
let title = String::from("Rust for C# developers");
let winner;
{
    let subtitle = String::from("ownership");
    winner = longest(&title, &subtitle);
}
println!("{winner}");
```

```text
error[E0597]: `subtitle` does not live long enough
  --> e09_longest_scope.rs:10:34
   |
 9 |         let subtitle = String::from("ownership");
   |             -------- binding `subtitle` declared here
10 |         winner = longest(&title, &subtitle);
   |                                  ^^^^^^^^^ borrowed value does not live long enough
11 |     }
   |     - `subtitle` dropped here while still borrowed
12 |     println!("{winner}");
   |                ------ borrow later used here
```

À l'exécution, `title` est la chaîne la plus longue, donc cela fonctionnerait par hasard — mais la signature ne promet rien sur celle qui est renvoyée, et le compilateur vous tient à la signature.

N'annotez que ce que le résultat emprunte réellement. Ici, le résultat vient de `a` seul, donc `len_from` n'a besoin d'aucune durée de vie et peut être n'importe quoi d'éphémère ([lignes 12-14](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L12-L14)) :

```rust
fn prefix_of<'a>(a: &'a str, len_from: &str) -> &'a str {
    &a[..len_from.len().min(a.len())]
}
```

## L'élision : quand on peut les omettre

La plupart des fonctions ne mentionnent jamais de durée de vie, parce que trois **règles d'élision** les complètent :

1. Chaque paramètre référence reçoit sa propre durée de vie.
2. S'il y a exactement **une** durée de vie en entrée, elle est utilisée pour toutes les références en sortie.
3. Si l'un des paramètres est `&self` ou `&mut self`, c'est **sa** durée de vie qui est utilisée pour les sorties.

Extrait de [`examples/l09_lifetimes.rs`, lignes 7-9](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L7-L9) :

```rust
fn first_word(text: &str) -> &str {     // règle 2 : le résultat emprunte `text`
    text.split_whitespace().next().unwrap_or("")
}
```

`longest` avait besoin d'une annotation parce qu'elle a deux entrées et pas de `self` : aucune règle ne s'applique.

L'élision ne fait jamais compiler un programme incorrect. Quand les règles produisent une durée de vie qui ne convient pas, vous obtenez quand même une erreur — et renvoyer une référence vers une variable locale est toujours une erreur, quelle que soit l'annotation ([`src/lib.rs`, lignes 530-533](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L530-L533)) :

```rust
fn shout(word: &str) -> &str {
    let upper = word.to_uppercase();
    &upper
}
```

```text
error[E0515]: cannot return reference to local variable `upper`
 --> e09_local.rs:3:5
  |
3 |     &upper
  |     ^^^^^^ returns a reference to data owned by the current function
```

La correction est celle de la leçon 4 : renvoyer la [`String`](https://doc.rust-lang.org/std/string/struct.String.html) possédée.

## Des structs qui empruntent

Une struct qui contient une référence doit déclarer la durée de vie, exactement comme un paramètre de type générique ([`src/lib.rs`, lignes 508-510](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L508-L510)) :

```rust
struct Excerpt {
    text: &str,
}
```

```text
error[E0106]: missing lifetime specifier
 --> e09_struct.rs:2:11
  |
2 |     text: &str,
  |           ^ expected named lifetime parameter
  |
help: consider introducing a named lifetime parameter
  |
1 ~ struct Excerpt<'a> {
2 ~     text: &'a str,
  |
```

Extrait de [`examples/l09_lifetimes.rs`, lignes 17-25](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L17-L25), [82-85](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L82-L85) :

```rust
struct Excerpt<'a> {
    text: &'a str,
}

impl Excerpt<'_> {                 // '_ : « une certaine durée de vie, je n'ai pas besoin de son nom »
    fn word_count(&self) -> usize {
        self.text.split_whitespace().count()
    }
}

let novel = String::from("Call me Ishmael. Some years ago, never mind how long precisely...");
let excerpt = Excerpt { text: novel.split('.').next().unwrap_or("") };
// excerpt: "Call me Ishmael" (3 words)
```

`Excerpt<'a>` se lit *« un extrait qui ne peut pas survivre au texte dans lequel il pointe »*. Le compilateur y veille :

```text
error[E0597]: `novel` does not live long enough
  --> e09_struct_outlive.rs:9:35
   |
 8 |         let novel = String::from("Call me Ishmael. Some years ago...");
   |             ----- binding `novel` declared here
 9 |         excerpt = Excerpt { text: novel.split('.').next().unwrap() };
   |                                   ^^^^^ borrowed value does not live long enough
10 |     }
   |     - `novel` dropped here while still borrowed
11 |     println!("{}", excerpt.text);
   |                    ------------ borrow later used here
```

L'équivalent C# le plus proche est une [`ref struct`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/ref-struct) comme [`Span<T>`](https://learn.microsoft.com/dotnet/api/system.span-1) : elle peut pointer dans la mémoire de quelqu'un d'autre, donc le compilateur restreint les endroits où elle peut aller. En Rust, n'importe quelle struct peut être ainsi.

### La durée de vie dans une signature de méthode compte

Un tokenizer qui renvoie des slices de son entrée ([lignes 28-59](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L28-L59)) :

```rust
struct Parser<'a> {
    input: &'a str,
    pos: usize,
}

impl<'a> Parser<'a> {
    fn next_token(&mut self) -> Option<&'a str> {
        // … renvoie &self.input[start..end]
    }
}

fn tokenize(line: &str) -> Vec<&str> {
    let mut parser = Parser::new(line);
    let mut tokens = Vec::new();
    while let Some(token) = parser.next_token() {
        tokens.push(token);
    }
    tokens                          // le parser est libéré, les tokens survivent
}
// tokens: ["let", "x", "=", "42"]
```

Le type de retour indique `&'a str` : un token emprunte le **texte d'entrée**, pas le parser. S'il avait été écrit `Option<&str>`, la règle d'élision 3 lierait chaque token à `&mut self` — et vous ne pourriez pas garder deux tokens à la fois (exercice 3).

## `'static`

`'static` est la durée de vie des données valides pendant toute l'exécution du programme. Les littéraux de chaîne sont stockés dans le binaire, ils l'ont donc ([lignes 62-64](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L62-L64)) :

```rust
fn default_greeting() -> &'static str {
    "hello"
}
```

Vous rencontrerez surtout `'static` comme **contrainte** (bound), par exemple sur `std::thread::spawn` : un nouveau thread peut survivre à la fonction qui l'a démarré, il ne peut donc pas emprunter les variables locales de cette fonction.

Extrait de [`src/lib.rs`, lignes 539-542](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L539-L542) :

```rust
let name = String::from("worker");
let label: &str = &name;
let handle = std::thread::spawn(move || println!("{label}"));
handle.join().unwrap();
```

```text
error[E0597]: `name` does not live long enough
   --> e09_static.rs:4:23
    |
  3 |     let name = String::from("worker");
    |         ---- binding `name` declared here
  4 |     let label: &str = &name;
    |                       ^^^^^ borrowed value does not live long enough
  5 |     let h = thread::spawn(move || println!("{label}"));
    |             ------------------------------------------ argument requires that `name` is borrowed for `'static`
  6 |     h.join().unwrap();
  7 | }
    | - `name` dropped here while still borrowed
    |
note: requirement that the value outlives `'static` introduced here
```

Déplacer la `String` elle-même dans la closure corrige le problème. [`T: 'static`](https://doc.rust-lang.org/reference/trait-bounds.html#lifetime-bounds) ne signifie **pas** « vit pour toujours » : cela signifie « ne contient aucune donnée empruntée susceptible d'expirer » — une `String` possédée remplit la condition. Les threads sont l'objet de la [leçon 12](../12-threads-and-concurrency/).

## Quand les durées de vie gênent : possédez les données

En venant de C#, le réflexe est de stocker des références partout. En Rust, une struct pleine de champs `&'a` propage sa durée de vie à tout ce qui la contient. Une règle pratique pendant l'apprentissage :

| Situation | Utilisez |
|---|---|
| Paramètres de fonction que vous ne faites que lire | [`&str`](https://doc.rust-lang.org/std/primitive.str.html), [`&[T]`](https://doc.rust-lang.org/std/primitive.slice.html), `&T` |
| Vues éphémères sur des données que possède quelqu'un d'autre (parsers, itérateurs, extraits) | une struct avec `'a` |
| Données qu'une struct garde longtemps | `String`, `Vec<T>`, `T` possédés |
| Données partagées par plusieurs propriétaires | [`Rc`](https://doc.rust-lang.org/std/rc/struct.Rc.html)/[`Arc`](https://doc.rust-lang.org/std/sync/struct.Arc.html) — [leçon 11](../11-smart-pointers/) |

Cloner quelques chaînes pour éviter un paramètre de durée de vie est un compromis parfaitement acceptable.

## À retenir

- Une durée de vie est l'intervalle pendant lequel une référence est valide ; le compilateur vérifie qu'aucune référence ne survit à sa valeur.
- Les annotations décrivent les relations entre références dans une **signature** ; elles ne prolongent jamais la vie d'une valeur.
- Trois règles d'élision couvrent la plupart des fonctions ; vous annotez quand il y a plusieurs entrées et pas de `self`.
- Une struct qui contient une référence porte un paramètre de durée de vie et ne peut pas survivre à ce qu'elle emprunte.
- Les données `'static` ne contiennent aucun emprunt qui expire ; des API comme `thread::spawn` l'exigent.
- En cas de doute, possédez les données.

## Exercices

1. Écrivez `fn longest_line(text: &str) -> &str` qui renvoie la ligne la plus longue d'un texte. A-t-elle besoin d'une annotation de durée de vie ? Écrivez ensuite `fn pick(first: &str, second: &str, use_first: bool) -> &str` — de quoi a-t-elle besoin ?

<details>
<summary>Solution</summary>

Extrait de [`src/lib.rs`, lignes 548-556](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L548-L556) :

```rust
fn longest_line(text: &str) -> &str {
    text.lines().max_by_key(|line| line.len()).unwrap_or("")
}

fn pick<'a>(first: &'a str, second: &'a str, use_first: bool) -> &'a str {
    if use_first { first } else { second }
}

let poem = String::from("short\na much longer line\nmid");
assert_eq!(longest_line(&poem), "a much longer line");
assert_eq!(pick("left", "right", false), "right");
```

`longest_line` a une seule référence en entrée, donc la règle d'élision 2 s'applique. `pick` en a deux et peut renvoyer l'une ou l'autre, donc les deux doivent partager `'a` — exactement comme `longest`.

</details>

2. Définissez `struct Highlight<'a> { line: &'a str, column: usize }` et écrivez `find_highlights(text, word)` qui renvoie chaque ligne de `text` contenant `word`. L'appelant doit pouvoir chercher avec une requête `String` temporaire, libérée avant que les résultats soient utilisés.

<details>
<summary>Solution</summary>

Extrait de [`src/lib.rs`, lignes 562-577](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L562-L577) :

```rust
#[derive(Debug, PartialEq)]
struct Highlight<'a> {
    line: &'a str,
    column: usize,
}

fn find_highlights<'a>(text: &'a str, word: &str) -> Vec<Highlight<'a>> {
    text.lines()
        .filter_map(|line| line.find(word).map(|column| Highlight { line, column }))
        .collect()
}

let text = String::from("I like Rust\nC# too\nRust again");
let hits = {
    let query = String::from("Rust");   // libérée à la fin de ce bloc
    find_highlights(&text, &query)
};
assert_eq!(hits, [Highlight { line: "I like Rust", column: 7 }, Highlight { line: "Rust again", column: 0 }]);
```

Les résultats n'empruntent que `text`, donc `word` reçoit sa propre durée de vie (élidée). Écrire `word: &'a str` ferait compiler la fonction mais rejetterait cet appel avec [`E0597`](https://doc.rust-lang.org/error_codes/E0597.html) : le compilateur supposerait alors que les résultats pourraient pointer dans `query`.

</details>

3. Cette version du tokenizer compile, mais `main` non. Expliquez l'erreur et corrigez-la en modifiant une seule ligne.

Extrait de [`src/lib.rs`, lignes 607-618](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/src/lib.rs#L607-L618) :

```rust
impl<'a> Parser<'a> {
    fn next_token(&mut self) -> Option<&str> {
        let start = self.pos;
        self.pos = self.input.len();
        Some(&self.input[start..])
    }
}

let line = String::from("let x = 42");
let mut parser = Parser { input: &line, pos: 0 };
let first = parser.next_token();
let second = parser.next_token();
println!("{first:?} {second:?}");
```

```text
error[E0499]: cannot borrow `parser` as mutable more than once at a time
  --> e09_elided_self.rs:18:18
   |
17 |     let first = parser.next_token();
   |                 ------ first mutable borrow occurs here
18 |     let second = parser.next_token();
   |                  ^^^^^^ second mutable borrow occurs here
19 |     println!("{first:?} {second:?}");
   |                ----- first borrow later used here
```

<details>
<summary>Solution</summary>

Avec `Option<&str>`, la règle d'élision 3 donne au résultat la durée de vie de `&mut self`. Tant que `first` est vivant, `parser` reste emprunté mutablement, donc le second appel est rejeté. Le token pointe en réalité dans l'entrée : dites-le.

Extrait de [`examples/l09_lifetimes.rs`, ligne 38](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/examples/l09_lifetimes.rs#L38) :

```rust
fn next_token(&mut self) -> Option<&'a str> {
```

Désormais, les tokens empruntent `line`, et le parser redevient libre dès que chaque appel se termine.

</details>

## Sources

- [The Book, ch. 10.3 — Validating References with Lifetimes](https://doc.rust-lang.org/book/ch10-03-lifetime-syntax.html)
- [The Rust Reference — Lifetime elision](https://doc.rust-lang.org/reference/lifetime-elision.html)
- [Rust by Example — `'static`](https://doc.rust-lang.org/rust-by-example/scope/lifetime/static_lifetime.html)
- [`std::thread::spawn`](https://doc.rust-lang.org/std/thread/fn.spawn.html)
