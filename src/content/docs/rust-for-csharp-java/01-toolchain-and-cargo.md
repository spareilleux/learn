---
title: 1. Toolchain and Cargo
description: rustup, cargo and crates.io, mapped to the dotnet CLI, NuGet and Maven.
sidebar:
  order: 1
---

## The three tools

| Rust | Role | C# | Java |
|---|---|---|---|
| `rustup` | installs and updates toolchains | .NET SDK installer / `global.json` | SDKMAN!, JDK installers |
| `cargo` | build, run, test, add dependencies | `dotnet` CLI | Maven / Gradle |
| crates.io | public package registry | NuGet | Maven Central |
| `rustc` | the compiler (Cargo calls it for you) | Roslyn (`csc`) | `javac` |

Install from [rustup.rs](https://rustup.rs). On Windows the default toolchain targets MSVC, so you also need the **Visual Studio C++ Build Tools** (the linker).

```powershell
rustc --version   # rustc 1.94.0 (4a4ef493e 2026-03-02)
cargo --version   # cargo 1.94.0 (85eff7c80 2026-01-15)
rustup update     # upgrade to the latest stable
```

:::note[No runtime to install]
Rust compiles to a native executable. There is no CLR or JVM to ship: the release build of "Hello, world!" is a single ~130 KB `.exe` on Windows.
:::

## Creating a project

```powershell
cargo new hello
cd hello
cargo run
```

```text
    Creating binary (application) `hello` package
   Compiling hello v0.1.0 (…\hello)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 1.01s
     Running `target\debug\hello.exe`
Hello, world!
```

`cargo new` also runs `git init` and writes a `.gitignore`. The layout:

```text
hello/
├── Cargo.toml      ← like .csproj or pom.xml
├── src/
│   └── main.rs     ← entry point (a library would have src/lib.rs)
└── .gitignore
```

```toml
# Cargo.toml
[package]
name = "hello"
version = "0.1.0"
edition = "2024"

[dependencies]
```

```rust
// src/main.rs
fn main() {
    println!("Hello, world!");
}
```

- `println!` ends with `!` because it is a **macro**, not a function (it checks the format string at compile time).
- The **edition** (`2024`) is like `<LangVersion>` or `--release`: it opts into language changes without breaking older crates, which keep compiling with their own edition.

## Everyday commands

| Task | Cargo | dotnet | Maven |
|---|---|---|---|
| New app | `cargo new app` | `dotnet new console` | `mvn archetype:generate` |
| New library | `cargo new --lib lib` | `dotnet new classlib` | — |
| Fast type-check | `cargo check` | — | — |
| Build (debug) | `cargo build` | `dotnet build` | `mvn compile` |
| Build (release) | `cargo build --release` | `dotnet build -c Release` | `mvn package` |
| Run | `cargo run` | `dotnet run` | `mvn exec:java` |
| Test | `cargo test` | `dotnet test` | `mvn test` |
| Add dependency | `cargo add rand` | `dotnet add package` | edit `pom.xml` |
| Format | `cargo fmt` | `dotnet format` | Spotless plugin |
| Lint | `cargo clippy` | Roslyn analyzers | Error Prone, SpotBugs |
| API docs | `cargo doc --open` | XML docs + DocFX | `javadoc` |

:::tip[Use `cargo check` constantly]
`cargo check` runs the whole type and borrow checker but skips code generation. It is much faster than a build, and it is what your editor (rust-analyzer) does on every keystroke.
:::

## Dependencies

```powershell
cargo add rand
```

```toml
[dependencies]
rand = "0.10.2"
```

- `"0.10.2"` means **compatible with 0.10.2** (SemVer caret), not "exactly 0.10.2".
- The exact resolved versions are written to `Cargo.lock` — like `packages.lock.json` or a Gradle lockfile. Commit it for applications.
- Debug and release builds land in `target/debug` and `target/release` (like `bin/Debug` and `bin/Release`).

## Key takeaways

- `rustup` manages compilers, `cargo` does everything else, crates.io hosts packages.
- `Cargo.toml` + `Cargo.lock` ≈ `.csproj` + lockfile / `pom.xml`.
- `cargo check` for fast feedback, `cargo build --release` for optimized binaries.

## Exercises

1. Create a project called `dice`, add the `rand` crate, and find in `Cargo.lock` which version was actually resolved.

<details>
<summary>Solution</summary>

```powershell
cargo new dice
cd dice
cargo add rand
cargo build
Select-String -Path Cargo.lock -Pattern 'name = "rand"' -Context 0,1
```

`Cargo.toml` holds the requirement you asked for; `Cargo.lock` holds the exact version (and every transitive dependency) that was chosen.

</details>

2. What is the difference between `cargo check` and `cargo build`, and when would you use each?

<details>
<summary>Solution</summary>

`cargo check` type-checks and borrow-checks without producing a binary, so it is fast — use it while editing. `cargo build` also generates machine code — use it when you need to run the program, and `cargo build --release` for an optimized version.

</details>

## Sources

- [The Book, ch. 1 — Getting Started](https://doc.rust-lang.org/book/ch01-00-getting-started.html)
- [The Cargo Book — Specifying dependencies](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html)
- [The Rust Edition Guide](https://doc.rust-lang.org/edition-guide/)
