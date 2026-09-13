---
title: Journal
description: Notes de progression datées du cours Rust — essais, surprises et points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Leçon 1 — Chaîne d'outils et Cargo
- [x] Leçon 2 — Types, mutabilité et expressions
- [x] Leçon 3 — Possession et déplacements
- [x] Leçon 4 — Emprunts et chaînes
- [ ] Leçon 5 — Structs, enums et pattern matching
- [ ] Leçon 6 — `Option`, `Result` et `?`
- [ ] Leçon 7 — Traits et génériques
- [ ] Leçon 8 — Collections et itérateurs
- [ ] Leçon 9 — Durées de vie (lifetimes)
- [ ] Leçon 10 — Modules, crates et workspaces
- [ ] Leçon 11 — `Box`, `Rc`, `Arc`, `RefCell`
- [ ] Leçon 12 — Threads, `Send`/`Sync`, `Mutex`, rayon
- [ ] Leçon 13 — `async` et tokio
- [ ] Leçon 14 — Tests, docs, clippy, fmt
- [ ] Leçon 15 — Macros, `unsafe` et FFI

## 2026-09-13 — Leçons 1 à 4

- Chaîne d'outils sur ma machine : `rustc 1.94.0`, `cargo 1.94.0`, édition 2024 par défaut pour `cargo new`.
- Chaque extrait a été compilé avant d'être intégré à une leçon ; les erreurs du compilateur sont copiées depuis la sortie réelle de `rustc` (seules les longues notes « other types implement this trait » ont été raccourcies).
- Le code du cours se trouve dans [`code/rust-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java) : des `examples/` exécutables et des doctests `compile_fail` dans `src/lib.rs`, vérifiés par le workflow GitHub *Rust course examples*.

**Surprises en venant de C# :**

- Le dépassement d'entier **panique** dans les builds debug mais **reboucle** dans les builds release — vérifié avec `255u8 + 1` compilé des deux façons. C# reboucle dans les deux cas, sauf avec `checked`.
- Clippy a signalé `let scores = vec![90, 72, 85, 60];` comme `useless_vec`, car le vecteur n'était jamais lu que comme une slice — un tableau suffirait.
- L'erreur du borrow checker pour « push pendant l'itération » est la version à la compilation de `InvalidOperationException: Collection was modified`.

**Réponse : `compile_fail,E0382` vérifie-t-il le code d'erreur ?** Pas en stable. Un doctest marqué `compile_fail,E0999` autour d'une utilisation après déplacement (en réalité `E0382`) passe quand même avec `cargo test --doc` en 1.94.0 — la version stable vérifie seulement que la compilation échoue. Le workflow CI lance désormais aussi `cargo +nightly test --doc`, qui compare les codes.

## Questions ouvertes

- Comment `rust-analyzer` dans RustRover se compare-t-il à VS Code pour ces exercices ?
