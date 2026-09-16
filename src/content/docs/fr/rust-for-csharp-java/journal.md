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
- [x] Leçon 5 — Structs, enums et pattern matching
- [x] Leçon 6 — `Option`, `Result` et `?`
- [x] Leçon 7 — Traits et génériques
- [x] Leçon 8 — Collections et itérateurs
- [x] Leçon 9 — Durées de vie (lifetimes)
- [x] Leçon 10 — Modules, crates et workspaces
- [x] Leçon 11 — `Box`, `Rc`, `Arc`, `RefCell`
- [x] Leçon 12 — Threads, `Send`/`Sync`, `Mutex`, rayon
- [x] Leçon 13 — `async` et tokio
- [x] Leçon 14 — Tests, docs, clippy, fmt
- [x] Leçon 15 — Macros, `unsafe` et FFI
- [x] Leçon 16 — Interfaces de bureau en Rust, puis Tauri
- [x] Leçon 17 — Commandes Tauri
- [x] Leçon 18 — État, événements et canaux
- [ ] Leçon 19 — Le frontend : Vite, TypeScript et types générés
- [ ] Leçon 20 — Sécurité : capabilities, CSP et plugins
- [ ] Leçon 21 — Tests et packaging

## 2026-09-13 — Leçons 1 à 4

- Chaîne d'outils sur ma machine : `rustc 1.94.0`, `cargo 1.94.0`, édition 2024 par défaut pour `cargo new`.
- Chaque extrait a été compilé avant d'être intégré à une leçon ; les erreurs du compilateur sont copiées depuis la sortie réelle de `rustc` (seules les longues notes « other types implement this trait » ont été raccourcies).
- Le code du cours se trouve dans [`code/rust-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/rust-for-csharp-java) : des `examples/` exécutables et des doctests `compile_fail` dans `src/lib.rs`, vérifiés par le workflow GitHub *Rust course examples*.

**Surprises en venant de C# :**

- Le dépassement d'entier **panique** dans les builds debug mais **reboucle** dans les builds release — vérifié avec `255u8 + 1` compilé des deux façons. C# reboucle dans les deux cas, sauf avec `checked`.
- Clippy a signalé `let scores = vec![90, 72, 85, 60];` comme `useless_vec`, car le vecteur n'était jamais lu que comme une slice — un tableau suffirait.
- L'erreur du borrow checker pour « push pendant l'itération » est la version à la compilation de `InvalidOperationException: Collection was modified`.

**Réponse : `compile_fail,E0382` vérifie-t-il le code d'erreur ?** Pas en stable. Un doctest marqué `compile_fail,E0999` autour d'une utilisation après déplacement (en réalité `E0382`) passe quand même avec `cargo test --doc` en 1.94.0 — la version stable vérifie seulement que la compilation échoue. Le workflow CI lance désormais aussi `cargo +nightly test --doc`, qui compare les codes.

## 2026-09-13 — Leçons 5 à 8

Chaque solution d'exercice est désormais aussi un doctest : 41 doctests au total (extraits compile-fail et solutions), tous au vert en 1.94.0.

**Erreurs attrapées par les tests avant publication :**

- J'ai d'abord écrit `prices.sort_by(|a, b| a.total_cmp(b))` sur `vec![19.99, 5.0, 12.5]`. Cela ne compile pas : les littéraux sont encore un `{float}` non déterminé au moment où la closure est vérifiée (`E0599: no method named total_cmp found for reference &{float}`). Annoter `Vec<f64>` corrige le problème — la leçon 8 l'explique désormais.
- Dans la leçon 7, j'affirmais que `cheapest` pouvait prendre un `Vec<Box<dyn Priced>>` avec une contrainte `T: Priced + ?Sized`. Faux : `&[T]` exige `T: Sized`. La version qui fonctionne implémente `Priced` pour `Box<dyn Priced>`, et c'est ce que l'exercice montre (et teste) désormais.
- Clippy a rejeté `(1..=5).fold(1, |acc, n| acc * n)` au profit de `.product()` (`unnecessary_fold`) ; l'exemple de `fold` calcule donc plutôt une paire min/max — ce qu'aucun adaptateur seul ne fait.

**Surprises en venant de C# :**

- Quand `main` renvoie `Err`, Rust affiche l'erreur avec son format `Debug` (`Error: Missing("port")`), et non `Display`, puis se termine avec le code 1.
- `Vec<f64>::sort()` ne compile pas du tout (`f64` n'est pas `Ord`), là où C# et Java trient les doubles en silence.
- Le message `E0004` pour une nouvelle variante d'enum nomme exactement le motif manquant (`&Payment::Crypto { .. } not covered`) — mieux que tous les avertissements d'analyseur C# que je connais.

## 2026-09-13 — Leçons 9 à 12

76 doctests désormais (stable et nightly), plus un vrai workspace de deux crates pour la leçon 10 (`code/rust-for-csharp-java/l10-workspace`) que la CI teste, analyse (lint) et exécute. La crate du cours a gagné sa première dépendance : `rayon`, en dev-dependency.

**Ce que j'ai d'abord mal fait :**

- Dans l'exemple de la leçon 9, j'utilisais `drop(parser)` pour montrer que les tokens survivent au parser. Clippy l'a refusé (`drop_non_drop`) : appeler `drop` sur un type sans implémentation de `Drop` ne sert à rien. Une fonction `tokenize` dont le parser local meurt à la fin fait mieux la démonstration.
- Clippy m'a aussi appris `u64::is_multiple_of` (`manual_is_multiple_of`) au lieu de `n % d != 0`.
- Je pensais qu'un `map` rayon qui modifie un compteur capturé échouerait avec une erreur `Send`/`Sync`. Il échoue plus tôt : les closures de rayon sont `Fn`, donc c'est `E0594: cannot assign to a captured variable in a Fn closure`.

**Surprises :**

- Le message de panique de `RefCell` en 1.94 est simplement `RefCell already borrowed` ; des supports plus anciens citent `already borrowed: BorrowMutError`.
- Écrire `&str` au lieu de `&'a str` comme type de retour d'une méthode compile sans problème — l'erreur n'apparaît qu'au site d'appel, quand on essaie de garder deux tokens (`E0499`). L'élision a choisi la durée de vie de `&mut self`.
- Un enum récursif sans `Box` donne `E0391` (un cycle dans la requête « needs drop » du compilateur) en plus de `E0072`.
- rayon sur cette machine (Core Ultra 9 285K, 24 cœurs) : compter les nombres premiers inférieurs à 5 000 000 est passé de ~775 ms à ~41 ms, environ 18×.

## 2026-09-13 — Leçons 13 à 15, et trois systèmes d'exploitation

Le cœur du cours est terminé. Le code a désormais tokio en dev-dependency, deux petites crates de plus (`l14-testing`, et `l15-ffi` avec un client .NET 10), et la CI exécute tout sous **Windows, Ubuntu et macOS**. Le programme C# appelle la bibliothèque Rust avec succès sur les trois.

**Ce que j'ai d'abord mal fait :**

- Le test FFI de la leçon 15 affirmait `pricing_sum([19.99, 5.0, 12.5]) == 37.49`. La vraie somme en `f64` vaut `37.489999999999995` ; C# n'avait affiché `37.49` qu'à cause de son format `F2`.
- Un commentaire XML du `.csproj` contenait `--release` : MSBuild refuse de charger un projet dont un commentaire contient `--`.
- J'avais écrit que `[LibraryImport]` marshale par défaut un `bool` comme un `BOOL` de 4 octets. Il n'a en fait aucun comportement par défaut : le build échoue avec `SYSLIB1051` tant qu'on n'ajoute pas `[MarshalAs]`. C'était le comportement de `[DllImport]`.
- `cargo fmt --check --manifest-path …` fonctionnait sur ma machine (Cargo 1.94) mais échouait sur les runners de CI (Cargo 1.98.1) avec `Failed to find targets`. La CI lance désormais `cargo fmt --check` depuis le dossier de chaque crate.
- `missing_docs = "warn"` dans `[lints]` s'applique aussi aux tests d'intégration : chaque fichier de `tests/` est sa propre crate et a besoin d'une ligne `//!`.
- Un doctest de la leçon 13 affirmait que trois attentes concurrentes se terminent en moins de 290 ms. C'est vrai sur ma machine, mais une assertion de durée donne un test instable (flaky) sur des runners de CI partagés ; le test ne vérifie donc plus que les résultats.
- Même sans assertion de durée, un délai reste une course : sur un runner macOS chargé, une tentative de 200 ms a « réussi » malgré un `timeout` de 50 ms (quand le runtime se réveille après les deux échéances, `timeout` interroge d'abord le future, déjà prêt). Les tentatives lentes de l'exercice 2 durent maintenant 5 secondes : le test reste rapide, car elles sont abandonnées après 50 ms.

**Surprises :**

- En Rust asynchrone, un `.await` oublié signifie que le code **ne s'exécute jamais** — l'inverse de C#, où la tâche démarre quand même.
- L'erreur « future cannot be sent between threads safely » n'a pas de code `E` : elle vient de la contrainte `Send` de `tokio::spawn`, pas du langage.
- L'édition 2024 exige `unsafe extern "C"` et `#[unsafe(no_mangle)]` ; une bonne partie des supports FFI plus anciens ne compile plus tels quels.
- `cargo fmt` n'avait jamais été lancé sur ce cours : 30 différences de formatage dans les exemples de douze leçons.
- Hello world en mode release : environ 130 Ko sous Windows, 430–460 Ko sous Linux et macOS (runners de CI, Cargo 1.98.1).

## 2026-09-15 — Leçons 16 à 18 : applications de bureau avec Tauri

La partie 2 commence. Le cours construit maintenant un explorateur d'accords avec Tauri 2.11.5 dans `l16-tauri`, un workspace séparé avec ses propres `Cargo.lock` et `package-lock.json`. La CI le compile, l'analyse et le teste sous Windows, Ubuntu et macOS, avec un build release sur chacun ; la fenêtre elle-même n'a été lancée que sous Windows.

**Ce que j'ai d'abord mal fait :**

- Le premier `cargo test` de l'application Tauri a compilé, puis chaque exécutable de test est mort avec `STATUS_ENTRYPOINT_NOT_FOUND` avant d'exécuter un test. `tauri-build` n'embarque le manifeste Common Controls v6 que dans les binaires ([tauri#13419](https://github.com/tauri-apps/tauri/issues/13419), ouvert depuis mai 2025). La correction dans `build.rs` passe le même manifeste à l'éditeur de liens pour les cibles de test avec `cargo:rustc-link-arg-tests`.
- La page affichait `undefined: undefined` pour certaines erreurs : quand Tauri refuse lui-même un appel (commande inconnue, arguments invalides), la promesse se rejette avec une **chaîne**, pas avec l'objet d'erreur de la commande.
- Mon premier script pour piloter la fenêtre par le protocole DevTools se connectait à `127.0.0.1:9222`, où un autre programme de cette machine écoutait déjà ; l'instance WebView2 était sur `[::1]:9222`. Rien n'a été envoyé à la mauvaise cible ; le script désigne maintenant `[::1]`, et les exécutions suivantes ont utilisé un autre port.
- Mon script d'enrobage de `tauri dev` attendait la ligne ``Running ` ``, qui ne correspondait jamais parce que Cargo colore sa sortie : l'attente doit retirer les codes d'échappement.
- Les tests en runtime mock envoyaient `http://tauri.localhost` comme URL de la page. Ce n'est l'origine que sous Windows et Android ; macOS et Linux utilisent `tauri://localhost`, si bien qu'au premier passage de la CI, les capabilities y ont refusé chaque appel avec `not allowed. Plugin not found`. Les tests choisissent maintenant l'origine selon la plateforme (commit `2253508`).

**Surprises :**

- Une commande synchrone s'exécute sur le thread principal. Pendant une recherche d'une seconde, les timers JavaScript de la page continuaient de tourner (la webview est un autre processus), mais la fenêtre native n'a pas répondu à `WM_NULL` pendant 945 ms, et toutes les autres commandes attendaient.
- Oublier `.manage()` compile ; l'appel est rejeté à l'exécution avec `state not managed for field …`. Le guide Tauri dit qu'un type `State` qui ne correspond pas provoque une panique : en 2.11.5, une commande se rejette à la place, et seul `Manager::state` panique.
- `#[tauri::command]` transforme des erreurs en erreurs de compilation inhabituelles : `blocking_kind … IpcResponse` pour un type de retour sans `Serialize`, `E0255 __cmd__…` pour une commande `pub` à la racine de la crate, `AsyncCommandMustReturnResult` pour une commande `async` qui emprunte.
- L'exécutable release pèse 4,2 Mo, contre 385 Mo pour un Electron 44.3.0 décompressé ; fenêtre ouverte, le processus Rust utilise 5,6 Mo de mémoire privée et les six processus de WebView2 environ 170 Mo.
- `create-tauri-app` 4.7.4 affiche `npm run tauri android init` comme première étape d'un projet de bureau, et son modèle utilise l'édition 2021 et `"csp": null`.

**Trouvé dans la documentation de Tauri** (tauri-docs à `a6b59b7`) : l'exemple d'erreur de la page *Calling Rust*, `Ok(format!(value))`, ne compile pas ; son exemple `AppHandle` utilise des API de Tauri 1 (`GlobalShortcutManager`, `app_dir`) ; la panique à l'exécution pour un type qui ne correspond pas, sur la page *State management*, ci-dessus.

**Dogfooding d'IX** (`crates/ix-demo` à `a7e5fbc`, lu, pas modifié) : chaque calcul s'exécute dans le `ui` d'egui, sur le thread de dessin (58 gestionnaires `clicked()`, aucun thread ni canal) ; l'onglet *Neural Network (ix-nn)* entraîne son propre réseau `ndarray` au lieu d'appeler `ix-nn` ; la liste de couches saisie par l'utilisateur ignore silencieusement les entrées invalides ; `eframe = "0.31"` alors que la 0.36.2 est la version actuelle, sans `Cargo.lock` commité.

## Questions ouvertes

- La fenêtre de l'explorateur s'ouvre-t-elle et fonctionne-t-elle sous WSLg, sur Ubuntu avec WebKitGTK 4.1, et sur macOS ? La CI prouve qu'il s'y compile et que ses tests passent, pas que la fenêtre marche (*à vérifier*).
- Le `tauri-runtime-cef` de Tauri 3 change-t-il assez les chiffres de taille et de mémoire pour compter ? C'est une alpha au 2026-09-13.
- Comment `rust-analyzer` dans RustRover se compare-t-il à VS Code pour ces exercices ?
