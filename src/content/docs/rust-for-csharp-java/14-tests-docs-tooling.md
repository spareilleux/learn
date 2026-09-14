---
title: 14. Tests, docs, clippy and fmt
description: The quality toolchain that ships with Cargo — unit, integration and doc tests, rustdoc, clippy lints and rustfmt, wired into CI.
sidebar:
  order: 14
---

Full example: [`l14-testing/`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java/l14-testing) — a small `pricing` library; run `cargo test` from that folder.

## Everything is in the box

In .NET you pick [xUnit](https://xunit.net), [NUnit](https://nunit.org) or [MSTest](https://learn.microsoft.com/dotnet/core/testing/unit-testing-mstest-intro), add analyzers from [NuGet](https://www.nuget.org) and configure [`dotnet format`](https://learn.microsoft.com/dotnet/core/tools/dotnet-format). In Java you add [JUnit](https://junit.org), [Checkstyle](https://checkstyle.org) or [Error Prone](https://errorprone.info) and a formatter plugin to [Maven](https://maven.apache.org) or [Gradle](https://gradle.org). Rust ships one standard answer for each, installed with the toolchain:

| Job | Rust | C# | Java |
|---|---|---|---|
| Run tests | [`cargo test`](https://doc.rust-lang.org/cargo/commands/cargo-test.html) (test framework built in) | [`dotnet test`](https://learn.microsoft.com/dotnet/core/tools/dotnet-test) + xUnit/NUnit/MSTest | `mvn test` + JUnit |
| API docs | [`cargo doc`](https://doc.rust-lang.org/cargo/commands/cargo-doc.html) ([rustdoc](https://doc.rust-lang.org/rustdoc/)) | [XML doc comments](https://learn.microsoft.com/dotnet/csharp/language-reference/xmldoc/recommended-tags) + [DocFX](https://dotnet.github.io/docfx/) | [Javadoc](https://docs.oracle.com/en/java/javase/25/javadoc/) |
| Lints | [`cargo clippy`](https://doc.rust-lang.org/clippy/usage.html) | [Roslyn analyzers](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/overview) | Error Prone, [SpotBugs](https://spotbugs.github.io) |
| Formatting | `cargo fmt` ([rustfmt](https://rust-lang.github.io/rustfmt/)) | `dotnet format` | [Spotless](https://github.com/diffplug/spotless), [google-java-format](https://github.com/google/google-java-format) |
| Lint configuration | [`[lints]`](https://doc.rust-lang.org/cargo/reference/manifest.html#the-lints-section) in `Cargo.toml` | [`.editorconfig`](https://learn.microsoft.com/dotnet/fundamentals/code-analysis/configuration-files), `<WarningsAsErrors>` | plugin configuration |

Because there is one of each, every Rust project looks the same to a newcomer: `cargo test`, `cargo clippy`, `cargo fmt` work everywhere.

## Unit tests

Unit tests live **in the same file** as the code, in a child module compiled only for tests ([`l14-testing/src/lib.rs`, lines 108-169](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/l14-testing/src/lib.rs#L108-L169)):

```rust
// Unit tests: a child module, so it can reach private items
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
        assert!(cart.lines.is_empty(), "a rejected line must not be stored");   // private field
    }

    #[test]
    #[should_panic(expected = "discount above 100%")]
    fn percent_above_100_panics() {
        Cart::new().total_with(Discount::Percent(101));
    }

    // A test can return Result and use `?`
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
| a helper function in `mod tests` | a private helper or fixture | `@BeforeEach` / helper |

Rust has no attribute for parameterised tests or fixtures in the standard library; a loop over a table of cases, or a helper like `cart_with`, is the usual answer (crates such as [`rstest`](https://docs.rs/rstest) add them).

`cargo test` runs three kinds of tests and reports each:

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

A failing `assert_eq!` shows both sides:

```text
test tests::percent_discount_rounds_down ... FAILED

failures:

---- tests::percent_discount_rounds_down stdout ----

thread 'tests::percent_discount_rounds_down' (409064) panicked at src\lib.rs:128:9:
assertion `left == right` failed
  left: 899
 right: 900
```

Useful options:

| Command | Does |
|---|---|
| `cargo test discount` | runs only tests whose name contains `discount` |
| `cargo test -- --ignored` | runs only the ignored tests |
| `cargo test -- --nocapture` | shows `println!` output of passing tests (captured by default) |
| `cargo test -- --test-threads=1` | runs tests one at a time — they run **in parallel** by default |

Parallel execution means tests must not share mutable global state, such as a file path or an environment variable, without coordinating.

## Integration tests

Files in a `tests/` folder next to `src/` are **integration tests**. Each file is compiled as a separate crate that depends on your library, so it can only use the public API — like a separate `Pricing.Tests` project that references the assembly without [`InternalsVisibleTo`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.internalsvisibletoattribute) ([`l14-testing/tests/checkout.rs`, lines 3-13](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/l14-testing/tests/checkout.rs#L3-L13)):

```rust
// tests/checkout.rs
//! Checkout scenarios, exercised through the public API only.

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

No `#[cfg(test)]` is needed there: the whole folder only exists for tests. Integration tests can only `use` a **library** crate — there is no way to import functions from `src/main.rs`. That is one reason why binaries keep most of their logic in `src/lib.rs`, with a thin `src/main.rs`.

## Documentation and doc tests

`///` documents the next item, `//!` documents the enclosing module or crate. The content is Markdown ([`l14-testing/src/lib.rs`, line 67](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/l14-testing/src/lib.rs#L67)):

````rust
/// Adds `quantity` items at `unit_cents` each.
///
/// # Errors
///
/// Returns [`PricingError::ZeroQuantity`] if `quantity` is 0 and
/// [`PricingError::FreeItem`] if `unit_cents` is 0.
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

- `# Examples`, `# Errors`, `# Panics` and `# Safety` are the conventional section names, like `<example>`, `<exception>` in C# or `@throws` in Javadoc.
- `` [`PricingError::ZeroQuantity`] `` is an **[intra-doc link](https://doc.rust-lang.org/rustdoc/write-documentation/linking-to-items-by-name.html)**, resolved by the compiler like `<see cref="…"/>`.
- Every code block is a **doc test**: `cargo test` compiles and runs it, so the examples in the documentation cannot rot. A line starting with `# ` is compiled but hidden in the rendered page — here, the `Ok(())` that lets the example use `?`.
- Code blocks accept [attributes](https://doc.rust-lang.org/rustdoc/write-documentation/documentation-tests.html#attributes): `should_panic`, `no_run` (compile only), `ignore`, and `compile_fail` — the attribute this course uses for every "this does not compile" snippet.

`cargo doc --open` builds the HTML documentation for your crate and all its dependencies. With `RUSTDOCFLAGS="-D warnings"`, broken links fail the build:

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

`cargo clippy` runs several hundred lints on top of the compiler's own warnings. Given this function:

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

Many suggestions can be applied automatically with `cargo clippy --fix`. Lints are organised in [groups](https://doc.rust-lang.org/clippy/lints.html): the default set (`correctness`, `suspicious`, `style`, `complexity`, `perf`), plus opt-in `pedantic`, `nursery` and `restriction` groups. `unwrap_used` above belongs to `restriction`, so it only fires because the package enables it.

### Configuring lints

Lint levels for a whole package go in `Cargo.toml` — the equivalent of severities in `.editorconfig` ([`l14-testing/Cargo.toml`, lines 8-12](https://github.com/spareilleux/learn/blob/93f6f82/code/rust-for-csharp-java/l14-testing/Cargo.toml#L8-L12)):

```toml
# Lint levels for the whole package, instead of #![deny] attributes in every file
[lints.rust]
missing_docs = "warn"

[lints.clippy]
unwrap_used = "warn"
```

In code, [`#[allow(lint)]`](https://doc.rust-lang.org/reference/attributes/diagnostics.html#lint-check-attributes) silences a lint for one item. Prefer [`#[expect(lint, reason = "…")]`](https://doc.rust-lang.org/reference/attributes/diagnostics.html#the-expect-attribute): it silences the lint too, but **warns when the lint no longer fires**, so stale suppressions don't pile up (like an unnecessary [`#pragma warning disable`](https://learn.microsoft.com/dotnet/csharp/language-reference/preprocessor-directives#pragma-warning)):

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

Some lints also read options from a [`clippy.toml`](https://doc.rust-lang.org/clippy/configuration.html) file (exercise 3).

:::caution[`missing_docs` applies to integration tests too]
With `missing_docs = "warn"` in `[lints]`, `cargo clippy --all-targets -- -D warnings` failed on `tests/checkout.rs`: each integration test file is its own crate, and a crate needs a `//!` doc comment. I added one line of crate documentation to the test file.
:::

## rustfmt

`cargo fmt` formats the whole package; `cargo fmt --check` only reports differences and fails, which is what CI runs:

```text
Diff in \\?\C:\…\p14\src\lib.rs:178:
     return first.0.clone();
 }
 
-pub fn line_count(cart: &Cart) -> usize { cart.lines.len() }
+pub fn line_count(cart: &Cart) -> usize {
+    cart.lines.len()
+}
```

There is one community style and almost nothing to configure (a `rustfmt.toml` can change a few options such as `max_width`). Formatting debates disappear from code review.

:::note[This course adopted it late]
The course code went through twelve lessons without `cargo fmt`. Running `cargo fmt --check` for this lesson reported 30 differences in the examples; they are now formatted, and CI checks formatting. Doc comments, and therefore the `compile_fail` snippets, are not reformatted.
:::

## Putting it in CI

The course's own workflow, [`.github/workflows/rust-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/rust-examples.yml), is a typical Rust pipeline (excerpt) ([lines 36-67](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/rust-examples.yml#L36-L67)):

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

`-D warnings` turns every warning into an error in CI only, so local builds stay pleasant while nothing lands with warnings.

Beyond the standard tools, these crates fill the remaining gaps: [`criterion`](https://docs.rs/criterion) for benchmarks ([BenchmarkDotNet](https://benchmarkdotnet.org), [JMH](https://github.com/openjdk/jmh)), [`proptest`](https://docs.rs/proptest) for property-based testing ([FsCheck](https://fscheck.github.io/FsCheck/), [jqwik](https://jqwik.net)), [`mockall`](https://docs.rs/mockall) for mocks ([Moq](https://github.com/devlooped/moq), [Mockito](https://site.mockito.org)), and [`cargo-llvm-cov`](https://github.com/taiki-e/cargo-llvm-cov) for coverage ([Coverlet](https://github.com/coverlet-coverage/coverlet), [JaCoCo](https://www.jacoco.org/jacoco/)).

## Key takeaways

- `cargo test`, `cargo doc`, `cargo clippy` and `cargo fmt` come with the toolchain; there is nothing to choose.
- Unit tests sit next to the code in `#[cfg(test)] mod tests` and can test private items; integration tests in `tests/` see only the public API.
- Every code example in `///` docs is compiled and run, so documentation stays correct.
- Configure lints in `[lints]`; use `#[expect(…, reason = …)]` rather than `#[allow]`.
- In CI: `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test`, `RUSTDOCFLAGS="-D warnings" cargo doc`.

## Exercises

1. Write `fn parse_percent(text: &str) -> Result<u8, String>` that accepts `"15%"` (surrounding spaces allowed), and rejects a missing `%`, non-numbers and values above 100. Write unit tests for valid input, each kind of error, and `"300%"` (which does not fit in a `u8`), including one test that returns `Result`.

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

`"300%"` fails in `parse::<u8>()` before the `> 100` check is reached, so its message is the "not a number" one — a test is the cheapest way to find that out.

</details>

2. Document `parse_percent` with `# Errors` and `# Examples` sections. The example must use `?` rather than `unwrap()`. What happens to `cargo test` if the example asserts `parse_percent("15%")? == 16`?

<details>
<summary>Solution</summary>

````rust
/// Parses a percentage such as `"15%"`.
///
/// # Errors
///
/// Returns an error if the text does not end with `%`, is not a number,
/// or is above 100.
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

The hidden `# Ok::<(), String>(())` line makes the example's implicit `main` return `Result<(), String>`, which is what allows `?`. If the example asserted `16`, the doc test would panic and `cargo test` would fail under `Doc-tests`, pointing at the line in the doc comment: wrong documentation breaks the build.

</details>

3. Make `clippy::unwrap_used` an **error** for the library, while still allowing `unwrap()` in unit tests. Check it with a function that calls `unwrap()`.

<details>
<summary>Solution</summary>

```toml
# Cargo.toml
[lints.clippy]
unwrap_used = "deny"
```

```toml
# clippy.toml, next to Cargo.toml
allow-unwrap-in-tests = true
```

`cargo clippy --all-targets` now reports only the library code:

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

Without `clippy.toml`, the `unwrap_err()` in `rejects_missing_sign_and_garbage` is reported as well (`used unwrap_err() on a Result value`).

</details>

## Sources

- [The Book, ch. 11 — Writing Automated Tests](https://doc.rust-lang.org/book/ch11-00-testing.html)
- [The rustdoc book — Documentation tests](https://doc.rust-lang.org/rustdoc/write-documentation/documentation-tests.html)
- [The Cargo Book — the `[lints]` section](https://doc.rust-lang.org/cargo/reference/manifest.html#the-lints-section)
- [Clippy documentation](https://doc.rust-lang.org/clippy/) and the [lint list](https://rust-lang.github.io/rust-clippy/master/index.html)
- [The Rust Reference — `#[expect]`](https://doc.rust-lang.org/reference/attributes/diagnostics.html#the-expect-attribute)
- [rustfmt](https://github.com/rust-lang/rustfmt)
