---
title: 14. Tests, docs, clippy et fmt
description: L'outillage qualité livré avec Cargo — tests unitaires, d'intégration et de documentation, rustdoc, lints clippy et rustfmt, branchés dans la CI.
sidebar:
  order: 14
---

Exemple complet : [`l14-testing/`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l14-testing) — une petite bibliothèque `pricing` ; lancez `cargo test` depuis ce dossier.

## Tout est fourni

En .NET, vous choisissez [xUnit](https://xunit.net), [NUnit](https://nunit.org) ou [MSTest](https://learn.microsoft.com/dotnet/core/testing/unit-testing-mstest-intro), ajoutez des analyseurs depuis [NuGet](https://www.nuget.org) et configurez [`dotnet format`](https://learn.microsoft.com/dotnet/core/tools/dotnet-format). En Java, vous ajoutez [JUnit](https://junit.org), [Checkstyle](https://checkstyle.org) ou [Error Prone](https://errorprone.info) et un plugin de formatage à [Maven](https://maven.apache.org) ou [Gradle](https://gradle.org). Rust fournit une réponse standard pour chaque besoin, installée avec la chaîne d'outils :

| Tâche | Rust | C# | Java |
|---|---|---|---|
| Lancer les tests | [`cargo test`](https://doc.rust-lang.org/cargo/commands/cargo-test.html) (framework de test intégré) | [`dotnet test`](https://learn.microsoft.com/dotnet/core/tools/dotnet-test) + xUnit/NUnit/MSTest | `mvn test` + JUnit |
| Documentation d'API | [`cargo doc`](https://doc.rust-lang.org/cargo/commands/cargo-doc.html) ([rustdoc](https://doc.rust-lang.org/rustdoc/)) | [commentaires de documentation XML](https://learn.microsoft.com/dotnet/csharp/language-reference/xmldoc/recommended-tags) + [DocFX](https://dotnet.github.io/docfx/) | [Javadoc](https://docs.oracle.com/en/java/javase/25/javadoc/) |
| Lints | [`cargo clippy`](https://doc.rust-lang.org/clippy/usage.html) | [analyseurs Roslyn](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/overview) | Error Prone, [SpotBugs](https://spotbugs.github.io) |
| Formatage | `cargo fmt` ([rustfmt](https://rust-lang.github.io/rustfmt/)) | `dotnet format` | [Spotless](https://github.com/diffplug/spotless), [google-java-format](https://github.com/google/google-java-format) |
| Configuration des lints | [`[lints]`](https://doc.rust-lang.org/cargo/reference/manifest.html#the-lints-section) dans `Cargo.toml` | [`.editorconfig`](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/configuration-files), `<WarningsAsErrors>` | configuration du plugin |

Comme il n'existe qu'un outil de chaque sorte, tous les projets Rust se ressemblent aux yeux d'un nouveau venu : `cargo test`, `cargo clippy` et `cargo fmt` fonctionnent partout.

## Tests unitaires

Les tests unitaires vivent **dans le même fichier** que le code, dans un module enfant compilé uniquement pour les tests ([`l14-testing/src/lib.rs`, lignes 108-169](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/l14-testing/src/lib.rs#L108-L169)) :

```rust
// Tests unitaires : un module enfant, qui peut donc accéder aux éléments privés
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn percent_discount_rounds_down() {
        let cart = cart_with(&[("book", 1, 999)]);
        assert_eq!(cart.total_with(Discount::Percent(10)), 899);
    }

    #[test]
    fn zero_quantity_is_rejected() {
        let mut cart = Cart::new();
        assert_eq!(cart.add("pen", 0, 150), Err(PricingError::ZeroQuantity));
        assert!(cart.lines.is_empty(), "a rejected line must not be stored");   // champ privé
    }

    #[test]
    #[should_panic(expected = "discount above 100%")]
    fn percent_above_100_panics() {
        Cart::new().total_with(Discount::Percent(101));
    }

    // Un test peut renvoyer Result et utiliser `?`
    #[test]
    fn free_item_error_message() -> Result<(), String> {
        let err = Cart::new().add("gift", 1, 0).err().ok_or("expected an error")?;
        assert_eq!(err.to_string(), "`gift` has no price");
        Ok(())
    }

    #[test]
    #[ignore = "slow: run with cargo test -- --ignored"]
    fn many_lines() { /* … */ }
}
```

| Rust | xUnit | JUnit 5 |
|---|---|---|
| `#[test]` | `[Fact]` | `@Test` |
| `assert_eq!(actual, expected)` | `Assert.Equal(expected, actual)` | `assertEquals(expected, actual)` |
| `assert!(cond, "message {x}")` | `Assert.True(cond, "message")` | `assertTrue(cond, "message")` |
| `#[should_panic(expected = "…")]` | `Assert.Throws<T>` | `assertThrows` |
| `#[ignore = "reason"]` | `[Fact(Skip = "reason")]` | `@Disabled("reason")` |
| une fonction utilitaire dans `mod tests` | une méthode utilitaire privée ou une fixture | `@BeforeEach` / méthode utilitaire |

La bibliothèque standard de Rust n'a pas d'attribut pour les tests paramétrés ni pour les fixtures ; une boucle sur un tableau de cas, ou une fonction utilitaire comme `cart_with`, est la réponse habituelle (des crates comme [`rstest`](https://docs.rs/rstest) les ajoutent).

`cargo test` lance trois sortes de tests et rend compte de chacune :

```text
     Running unittests src\lib.rs (target\debug\deps\pricing-2041fb093a55ec20.exe)

running 7 tests
test tests::many_lines ... ignored, slow: run with cargo test -- --ignored
test tests::empty_cart_totals_zero ... ok
test tests::fixed_discount_never_goes_negative ... ok
test tests::free_item_error_message ... ok
test tests::percent_above_100_panics - should panic ... ok
test tests::percent_discount_rounds_down ... ok
test tests::zero_quantity_is_rejected ... ok

test result: ok. 6 passed; 0 failed; 1 ignored; 0 measured; 0 filtered out; finished in 0.00s

     Running tests\checkout.rs (target\debug\deps\checkout-8074f42be2f51ecc.exe)

running 1 test
test checkout_with_discount ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests pricing

running 2 tests
test src\lib.rs - Cart::total_with (line 90) - should panic ... ok
test src\lib.rs - Cart::add (line 59) ... ok

test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.05s
```

Un `assert_eq!` qui échoue affiche les deux côtés :

```text
test tests::percent_discount_rounds_down ... FAILED

failures:

---- tests::percent_discount_rounds_down stdout ----

thread 'tests::percent_discount_rounds_down' (409064) panicked at src\lib.rs:128:9:
assertion `left == right` failed
  left: 899
 right: 900
```

Options utiles :

| Commande | Effet |
|---|---|
| `cargo test discount` | lance uniquement les tests dont le nom contient `discount` |
| `cargo test -- --ignored` | lance uniquement les tests ignorés |
| `cargo test -- --nocapture` | affiche la sortie `println!` des tests qui réussissent (capturée par défaut) |
| `cargo test -- --test-threads=1` | lance les tests un par un — ils s'exécutent **en parallèle** par défaut |

L'exécution parallèle signifie que les tests ne doivent pas partager d'état global mutable, comme un chemin de fichier ou une variable d'environnement, sans se coordonner.

## Tests d'intégration

Les fichiers d'un dossier `tests/` placé à côté de `src/` sont des **tests d'intégration**. Chaque fichier est compilé comme une crate séparée qui dépend de votre bibliothèque ; il ne peut donc utiliser que l'API publique — comme un projet `Pricing.Tests` séparé qui référence l'assembly sans [`InternalsVisibleTo`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.internalsvisibletoattribute) ([`l14-testing/tests/checkout.rs`, lignes 3-13](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/l14-testing/tests/checkout.rs#L3-L13)) :

```rust
// tests/checkout.rs
//! Scénarios de passage en caisse, testés uniquement via l'API publique.

use pricing::{Cart, Discount, PricingError};

#[test]
fn checkout_with_discount() -> Result<(), PricingError> {
    let mut cart = Cart::new();
    cart.add("book", 2, 2_000)?;
    cart.add("pen", 3, 150)?;
    assert_eq!(cart.total_cents(), 4_450);
    assert_eq!(cart.total_with(Discount::Percent(20)), 3_560);
    Ok(())
}
```

Aucun `#[cfg(test)]` n'est nécessaire ici : tout le dossier n'existe que pour les tests. Les tests d'intégration ne peuvent faire `use` que d'une crate **bibliothèque** — il est impossible d'importer des fonctions de `src/main.rs`. C'est l'une des raisons pour lesquelles les binaires gardent l'essentiel de leur logique dans `src/lib.rs`, avec un `src/main.rs` réduit au minimum.

## Documentation et doc tests

`///` documente l'élément qui suit, `//!` documente le module ou la crate qui l'entoure. Le contenu est du Markdown ([`l14-testing/src/lib.rs`, ligne 67](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/l14-testing/src/lib.rs#L67)) :

````rust
/// Ajoute `quantity` articles à `unit_cents` chacun.
///
/// # Errors
///
/// Renvoie [`PricingError::ZeroQuantity`] si `quantity` vaut 0 et
/// [`PricingError::FreeItem`] si `unit_cents` vaut 0.
///
/// # Examples
///
/// ```
/// use pricing::Cart;
///
/// let mut cart = Cart::new();
/// cart.add("pen", 2, 150)?;
/// assert_eq!(cart.total_cents(), 300);
/// # Ok::<(), pricing::PricingError>(())
/// ```
pub fn add(&mut self, name: &str, quantity: u32, unit_cents: u64) -> Result<(), PricingError> {
````

- `# Examples`, `# Errors`, `# Panics` et `# Safety` sont les noms de section conventionnels, comme `<example>` et `<exception>` en C# ou `@throws` en Javadoc.
- `` [`PricingError::ZeroQuantity`] `` est un **[lien intra-doc](https://doc.rust-lang.org/rustdoc/write-documentation/linking-to-items-by-name.html)** (intra-doc link), résolu par le compilateur comme `<see cref="…"/>`.
- Chaque bloc de code est un **doc test** : `cargo test` le compile et l'exécute, si bien que les exemples de la documentation ne peuvent pas se périmer. Une ligne qui commence par `# ` est compilée mais masquée dans la page générée — ici, le `Ok(())` qui permet à l'exemple d'utiliser `?`.
- Les blocs de code acceptent des [attributs](https://doc.rust-lang.org/rustdoc/write-documentation/documentation-tests.html#attributes) : `should_panic`, `no_run` (compilation seulement), `ignore`, et `compile_fail` — l'attribut que ce cours utilise pour chaque extrait « ceci ne compile pas ».

`cargo doc --open` génère la documentation HTML de votre crate et de toutes ses dépendances. Avec `RUSTDOCFLAGS="-D warnings"`, les liens cassés font échouer la construction :

```text
error: unresolved link to `Cart::most_expensive`
   --> src\lib.rs:172:44
    |
172 | /// Name of the most expensive line, see [`Cart::most_expensive`].
    |                                            ^^^^^^^^^^^^^^^^^^^^ the struct `Cart` has no field or associated item named `most_expensive`
    |
    = note: `-D rustdoc::broken-intra-doc-links` implied by `-D warnings`
```

## Clippy

`cargo clippy` exécute plusieurs centaines de lints en plus des avertissements du compilateur lui-même. Avec cette fonction :

```rust
pub fn describe(cart: &Cart) -> String {
    if cart.lines.len() == 0 {
        return String::from("empty");
    }
    let first = cart.lines.first().unwrap();
    return first.0.clone();
}
```

```text
warning: unneeded `return` statement
   --> src\lib.rs:178:5
    |
178 |     return first.0.clone();
    |     ^^^^^^^^^^^^^^^^^^^^^^
    |
    = help: for further information visit https://rust-lang.github.io/rust-clippy/rust-1.94.0/index.html#needless_return
    = note: `#[warn(clippy::needless_return)]` on by default
help: remove `return`
    |
178 -     return first.0.clone();
178 +     first.0.clone()
    |

warning: length comparison to zero
   --> src\lib.rs:174:8
    |
174 |     if cart.lines.len() == 0 {
    |        ^^^^^^^^^^^^^^^^^^^^^ help: using `is_empty` is clearer and more explicit: `cart.lines.is_empty()`

warning: used `unwrap()` on an `Option` value
   --> src\lib.rs:177:17
    |
177 |     let first = cart.lines.first().unwrap();
    |                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^
    |
    = note: if this value is `None`, it will panic
    = help: consider using `expect()` to provide a better panic message
```

Beaucoup de suggestions peuvent être appliquées automatiquement avec `cargo clippy --fix`. Les lints sont organisés en [groupes](https://doc.rust-lang.org/clippy/lints.html) : l'ensemble par défaut (`correctness`, `suspicious`, `style`, `complexity`, `perf`), plus les groupes optionnels `pedantic`, `nursery` et `restriction`. `unwrap_used` ci-dessus appartient à `restriction` : il ne se déclenche donc que parce que le package l'active.

### Configurer les lints

Les niveaux de lint pour tout un package se placent dans `Cargo.toml` — l'équivalent des sévérités dans `.editorconfig` ([`l14-testing/Cargo.toml`, lignes 8-12](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/l14-testing/Cargo.toml#L8-L12)) :

```toml
# Niveaux de lint pour tout le package, au lieu d'attributs #![deny] dans chaque fichier
[lints.rust]
missing_docs = "warn"

[lints.clippy]
unwrap_used = "warn"
```

Dans le code, [`#[allow(lint)]`](https://doc.rust-lang.org/reference/attributes/diagnostics.html#lint-check-attributes) fait taire un lint pour un élément. Préférez [`#[expect(lint, reason = "…")]`](https://doc.rust-lang.org/reference/attributes/diagnostics.html#the-expect-attribute) : il fait lui aussi taire le lint, mais **avertit quand le lint ne se déclenche plus**, si bien que les suppressions obsolètes ne s'accumulent pas (comme un [`#pragma warning disable`](https://learn.microsoft.com/dotnet/csharp/language-reference/preprocessor-directives#pragma-warning) devenu inutile) :

```text
warning: this lint expectation is unfulfilled
   --> src\lib.rs:173:10
    |
173 | #[expect(clippy::len_zero, reason = "comparing with 0 reads better here")]
    |          ^^^^^^^^^^^^^^^^
    |
    = note: comparing with 0 reads better here
    = note: `#[warn(unfulfilled_lint_expectations)]` on by default
```

Certains lints lisent aussi des options dans un fichier [`clippy.toml`](https://doc.rust-lang.org/clippy/configuration.html) (exercice 3).

:::caution[`missing_docs` s'applique aussi aux tests d'intégration]
Avec `missing_docs = "warn"` dans `[lints]`, `cargo clippy --all-targets -- -D warnings` a échoué sur `tests/checkout.rs` : chaque fichier de test d'intégration est sa propre crate, et une crate a besoin d'un commentaire de documentation `//!`. J'ai ajouté une ligne de documentation de crate au fichier de test.
:::

## rustfmt

`cargo fmt` formate tout le package ; `cargo fmt --check` se contente de signaler les différences et échoue, et c'est ce que lance la CI :

```text
Diff in \\?\C:\…\p14\src\lib.rs:178:
     return first.0.clone();
 }
 
-pub fn line_count(cart: &Cart) -> usize { cart.lines.len() }
+pub fn line_count(cart: &Cart) -> usize {
+    cart.lines.len()
+}
```

Il existe un seul style communautaire et presque rien à configurer (un `rustfmt.toml` peut modifier quelques options comme `max_width`). Les débats sur le formatage disparaissent des revues de code.

:::note[Ce cours l'a adopté tardivement]
Le code du cours a traversé douze leçons sans `cargo fmt`. Lancer `cargo fmt --check` pour cette leçon a signalé 30 différences dans les exemples ; ils sont désormais formatés, et la CI vérifie le formatage. Les commentaires de documentation, et donc les extraits `compile_fail`, ne sont pas reformatés.
:::

## L'intégrer à la CI

Le workflow du cours lui-même, [`.github/workflows/rust-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/rust-examples.yml), est un pipeline Rust typique (extrait) ([lignes 36-67](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/rust-examples.yml#L36-L67)) :

```yaml
- name: Formatting
  run: cargo fmt --check
- name: Compile-fail doctests
  run: cargo test --doc
- name: Clippy
  run: cargo clippy --examples -- -D warnings
- name: Lesson 14 crate
  working-directory: code/rust-for-csharp-java/l14-testing
  env:
    RUSTDOCFLAGS: -D warnings
  run: |
    cargo clippy --all-targets -- -D warnings
    cargo test
    cargo test -- --ignored
    cargo doc --no-deps
```

`-D warnings` transforme chaque avertissement en erreur, dans la CI seulement : les constructions locales restent agréables, et rien n'est intégré avec des avertissements.

Au-delà des outils standard, ces crates comblent les manques restants : [`criterion`](https://docs.rs/criterion) pour les benchmarks ([BenchmarkDotNet](https://benchmarkdotnet.org), [JMH](https://github.com/openjdk/jmh)), [`proptest`](https://docs.rs/proptest) pour les tests basés sur les propriétés ([FsCheck](https://fscheck.github.io/FsCheck/), [jqwik](https://jqwik.net)), [`mockall`](https://docs.rs/mockall) pour les mocks ([Moq](https://github.com/devlooped/moq), [Mockito](https://site.mockito.org)), et [`cargo-llvm-cov`](https://github.com/taiki-e/cargo-llvm-cov) pour la couverture de code ([Coverlet](https://github.com/coverlet-coverage/coverlet), [JaCoCo](https://www.jacoco.org/jacoco/)).

## À retenir

- `cargo test`, `cargo doc`, `cargo clippy` et `cargo fmt` sont livrés avec la chaîne d'outils ; il n'y a rien à choisir.
- Les tests unitaires se trouvent à côté du code dans `#[cfg(test)] mod tests` et peuvent tester les éléments privés ; les tests d'intégration dans `tests/` ne voient que l'API publique.
- Chaque exemple de code dans la documentation `///` est compilé et exécuté, donc la documentation reste correcte.
- Configurez les lints dans `[lints]` ; utilisez `#[expect(…, reason = …)]` plutôt que `#[allow]`.
- En CI : `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test`, `RUSTDOCFLAGS="-D warnings" cargo doc`.

## Exercices

1. Écrivez `fn parse_percent(text: &str) -> Result<u8, String>` qui accepte `"15%"` (espaces autour autorisés) et rejette un `%` manquant, ce qui n'est pas un nombre et les valeurs supérieures à 100. Écrivez des tests unitaires pour une entrée valide, pour chaque sorte d'erreur et pour `"300%"` (qui ne tient pas dans un `u8`), dont un test qui renvoie `Result`.

<details>
<summary>Solution</summary>

```rust
pub fn parse_percent(text: &str) -> Result<u8, String> {
    let digits = text
        .trim()
        .strip_suffix('%')
        .ok_or_else(|| format!("`{text}` does not end with %"))?;
    let value: u8 = digits
        .parse()
        .map_err(|e| format!("`{digits}` is not a number: {e}"))?;
    if value > 100 {
        return Err(format!("{value}% is above 100%"));
    }
    Ok(value)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_valid_percentages() {
        assert_eq!(parse_percent("0%"), Ok(0));
        assert_eq!(parse_percent(" 15% "), Ok(15));
        assert_eq!(parse_percent("100%"), Ok(100));
    }

    #[test]
    fn rejects_values_above_100() {
        assert_eq!(parse_percent("150%"), Err("150% is above 100%".to_string()));
    }

    #[test]
    fn rejects_missing_sign_and_garbage() {
        assert!(parse_percent("15").is_err());
        let err = parse_percent("abc%").unwrap_err();
        assert!(err.contains("not a number"), "unexpected message: {err}");
    }

    #[test]
    fn values_that_overflow_u8() -> Result<(), String> {
        let err = parse_percent("300%").err().ok_or("300% should fail")?;
        assert!(err.contains("not a number"), "unexpected message: {err}");
        Ok(())
    }
}
```

`"300%"` échoue dans `parse::<u8>()` avant d'atteindre la vérification `> 100` ; son message est donc celui de « not a number » — un test est le moyen le moins coûteux de le découvrir.

</details>

2. Documentez `parse_percent` avec des sections `# Errors` et `# Examples`. L'exemple doit utiliser `?` plutôt que `unwrap()`. Qu'arrive-t-il à `cargo test` si l'exemple affirme `parse_percent("15%")? == 16` ?

<details>
<summary>Solution</summary>

````rust
/// Analyse un pourcentage comme `"15%"`.
///
/// # Errors
///
/// Renvoie une erreur si le texte ne se termine pas par `%`, n'est pas un nombre
/// ou dépasse 100.
///
/// # Examples
///
/// ```
/// use ex14::parse_percent;
///
/// assert_eq!(parse_percent("15%")?, 15);
/// assert!(parse_percent("150%").is_err());
/// # Ok::<(), String>(())
/// ```
pub fn parse_percent(text: &str) -> Result<u8, String> {
````

La ligne masquée `# Ok::<(), String>(())` fait renvoyer `Result<(), String>` au `main` implicite de l'exemple, ce qui autorise `?`. Si l'exemple affirmait `16`, le doc test paniquerait et `cargo test` échouerait sous `Doc-tests`, en pointant la ligne du commentaire de documentation : une documentation fausse casse la construction.

</details>

3. Faites de `clippy::unwrap_used` une **erreur** pour la bibliothèque, tout en autorisant `unwrap()` dans les tests unitaires. Vérifiez-le avec une fonction qui appelle `unwrap()`.

<details>
<summary>Solution</summary>

```toml
# Cargo.toml
[lints.clippy]
unwrap_used = "deny"
```

```toml
# clippy.toml, à côté de Cargo.toml
allow-unwrap-in-tests = true
```

`cargo clippy --all-targets` ne signale plus que le code de la bibliothèque :

```text
error: used `unwrap()` on a `Result` value
  --> src\lib.rs:35:5
   |
35 |     parse_percent(items[0]).unwrap()
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   |
   = note: if this value is an `Err`, it will panic
   = help: consider using `expect()` to provide a better panic message
```

Sans `clippy.toml`, le `unwrap_err()` de `rejects_missing_sign_and_garbage` est signalé lui aussi (`used unwrap_err() on a Result value`).

</details>

## Sources

- [The Book, ch. 11 — Writing Automated Tests](https://doc.rust-lang.org/book/ch11-00-testing.html)
- [The rustdoc book — Documentation tests](https://doc.rust-lang.org/rustdoc/write-documentation/documentation-tests.html)
- [The Cargo Book — la section `[lints]`](https://doc.rust-lang.org/cargo/reference/manifest.html#the-lints-section)
- [Documentation de Clippy](https://doc.rust-lang.org/clippy/) et la [liste des lints](https://rust-lang.github.io/rust-clippy/master/index.html)
- [The Rust Reference — `#[expect]`](https://doc.rust-lang.org/reference/attributes/diagnostics.html#the-expect-attribute)
- [rustfmt](https://github.com/rust-lang/rustfmt)
