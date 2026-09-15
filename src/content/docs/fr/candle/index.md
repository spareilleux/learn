---
title: Candle, l'apprentissage automatique de Hugging Face en Rust — Mission
description: Apprendre Candle, le framework d'apprentissage automatique de Hugging Face en Rust, de ses tenseurs jusqu'au service de modèles — tenseurs, performance sur CPU, autodiff, candle-nn, safetensors et le Hub, transformers, LLM quantifiés, déploiement et interopérabilité avec C# et Java — chaque sortie étant affichée par du code compilé et épinglé.
sidebar:
  label: Mission
  order: 0
---

:::note[Comment ce cours est testé]
Chaque résultat de ce cours est affiché par un programme de [`code/candle`](https://github.com/spareilleux/learn/tree/main/code/candle) : un workspace Cargo qui dépend de `candle-core` et `candle-nn` **0.11.0**, épinglés avec `=`, sur le CPU seulement. `check.sh` exécute `cargo fmt`, `clippy`, les tests (avec un doctest `compile_fail` pour chaque extrait qu'une leçon montre refusé) et chaque exemple, et compare chaque sortie avec le fichier de `expected/`. Les sorties des leçons ont été capturées avec Rust 1.94.0 sous Windows 11 en septembre 2026, et `check.sh` a donné les mêmes sorties sous Linux, dans un conteneur `rust:1.94.0`. Un workflow, `candle-examples.yml`, exécute le même script sous Linux, Windows et macOS ; il n'est pas encore sur GitHub, donc macOS est *à vérifier*.
:::

## Pourquoi j'apprends ça

Le [cours IX](../machine-learning-ix/) a écrit des algorithmes d'apprentissage automatique à la main en Rust, et le [cours sur l'IA de GA](../ga-ai/) a suivi des embeddings calculés en C# par ONNX Runtime. Entre les deux se trouve la question à laquelle ce cours répond : un programme Rust peut-il charger un modèle publié, l'exécuter, et même en entraîner un petit, sans Python et sans runtime natif à côté ?

[Candle](https://github.com/huggingface/candle) est la réponse de Hugging Face. C'est une bibliothèque de tenseurs avec différentiation automatique, un ensemble de couches et des implémentations de modèles connus, de BERT aux LLM quantifiés, le tout compilé dans ton binaire. Je veux savoir ce qu'elle fait sous les tenseurs, ce qu'elle coûte sur un CPU, où sont ses limites, et comment un service C# ou Java s'en servirait.

## À qui s'adresse ce cours

Tu écris du C# ou du Java, et tu connais les bases de Rust grâce au [cours Rust](../rust-for-csharp-java/) : ownership, `Result` et `?`, traits, Cargo. Tu connais les notions d'apprentissage automatique du [cours IX](../machine-learning-ix/) : une perte, un gradient, la descente de gradient, les ensembles d'entraînement et de test. Ce cours ne les réexplique pas ; il renvoie vers elles.

Tu n'as pas besoin de Python ni de PyTorch. Quand la façon de faire de PyTorch aide, une leçon la montre à côté de celle de Candle, puisque la plupart du code de modèles que tu liras est écrit avec.

## Candle, TorchSharp et DJL en un tableau

| | TorchSharp (C#) | DJL (Java) | Candle (Rust) |
|---|---|---|---|
| Un tenseur | `torch.Tensor`, au-dessus de libtorch | `NDArray`, au-dessus du moteur que tu choisis | `candle_core::Tensor`, en Rust pur sur le CPU |
| Une erreur | une exception | une exception | un `Result` pour chaque opération |
| Broadcasting | implicite | implicite | explicite : `broadcast_add` |
| Gradients | `requires_grad`, `.grad` s'accumule | `GradientCollector` | `Var`, `backward` renvoie un nouveau `GradStore` |
| Fichiers de modèle | son propre format, et TorchScript | le format du moteur | `safetensors`, GGUF |
| Ce que tu livres | une app .NET plus les paquets libtorch | une app JVM plus les bibliothèques natives du moteur | un binaire, ou un module WebAssembly |

Sources : [README de TorchSharp](https://github.com/dotnet/TorchSharp/blob/8f4def03b641b6753f18076aa5438f8eaaef2d30/README.md), [README de DJL](https://github.com/deepjavalibrary/djl/blob/f3782179ff48a1bd31382667dbfae1f568891a55/README.md), [README de Candle](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/README.md), et les leçons 1 à 4 pour la colonne Candle.

## Candle, épinglé

Le cours utilise la dernière version publiée sur crates.io, [**0.11.0**](https://crates.io/crates/candle-core/0.11.0), sortie le 26 juin 2026. Ses sources sont le tag `0.11.0`, commit [`31f35b1`](https://github.com/huggingface/candle/tree/31f35b147389700ed2a178ee66a91c3cc25cc80d), et chaque lien vers le code de Candle pointe là, pour que les numéros de ligne restent justes quand `main` avance. [`Cargo.toml`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/Cargo.toml) épingle les crates :

```toml
[workspace.dependencies]
candle-core = "=0.11.0"
candle-nn = "=0.11.0"
```

Quand `main` a déjà corrigé quelque chose que les leçons rencontrent, elles le disent, avec le commit.

## À la fin de ce cours, je saurai

- créer, remodeler, indexer et combiner des tenseurs, et lire les erreurs d'exécution de Candle ;
- distinguer une vue d'une copie, et mesurer et régler ce qu'une opération coûte sur un CPU ;
- calculer des gradients avec `Var` et `backward`, les vérifier, et entraîner un modèle avec ;
- construire et entraîner un réseau avec `candle-nn`, et enregistrer et charger ses poids avec `safetensors` ;
- télécharger un modèle depuis le Hub de Hugging Face à une révision épinglée, calculer des embeddings, et exécuter un LLM quantifié ;
- servir un modèle en HTTP, dans un conteneur et dans le navigateur, et l'appeler depuis C# et Java ;
- porter un petit modèle PyTorch vers Candle et vérifier que les deux donnent les mêmes sorties.

## Plan

| # | Leçon | Si tu connais PyTorch |
|---|---|---|
| 1 | [Pourquoi Candle](01-why-candle/) | `pip install torch`, `torch.cuda.is_available()` |
| 2 | [Tenseurs](02-tensors/) | `torch.tensor`, `view`, indexation, broadcasting |
| 3 | [Calcul et performance sur CPU](03-cpu-performance/) | `contiguous()`, `torch.set_num_threads` |
| 4 | [Différentiation automatique](04-autodiff/) | `requires_grad`, `backward()`, `.grad` |
| 5 | `candle-nn` : modules, couches, optimiseurs, un petit réseau entraîné sur un jeu de données public | `nn.Module`, `nn.Linear`, `torch.optim` |
| 6 | Formats et Hub : `safetensors`, `VarBuilder`, `hf-hub`, le cache, les licences des modèles | `torch.load`, `from_pretrained` |
| 7 | Transformers en inférence : un modèle d'embeddings, les tokenizers, la similarité, comparés aux embeddings de GA | `transformers.AutoModel` |
| 8 | LLM quantifiés : GGUF, tenseurs quantifiés, un petit modèle, l'échantillonnage | `llama.cpp`, `bitsandbytes` |
| 9 | GPU : les features CUDA et Metal, en théorie, *à vérifier* | `.to("cuda")` |
| 10 | Déploiement : un service HTTP avec axum, un binaire autonome, un conteneur, WebAssembly dans le navigateur | TorchServe |
| 11 | Interopérabilité : appeler un modèle Candle depuis C# et depuis Java | TorchSharp, DJL |
| 12 | Écrire son propre modèle : porter un petit modèle PyTorch et comparer les sorties | — |
| — | [Journal](journal/) | |

Les leçons 5 à 12 sont le plan ; il changera à mesure que les premières m'apprendront ce qui compte. La leçon 9 reste théorique parce que le GPU de la machine sur laquelle ce cours est écrit est réservé à d'autres travaux.

## Ressources

- [Candle à `31f35b1`](https://github.com/huggingface/candle/tree/31f35b147389700ed2a178ee66a91c3cc25cc80d), ses [exemples](https://github.com/huggingface/candle/tree/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-examples/examples) et le [livre de Candle](https://huggingface.github.io/candle/)
- Sur docs.rs : [`candle-core`](https://docs.rs/candle-core/0.11.0/candle_core/), [`candle-nn`](https://docs.rs/candle-nn/0.11.0/candle_nn/), [`candle-transformers`](https://docs.rs/candle-transformers/0.11.0/candle_transformers/)
- [Documentation du Hub de Hugging Face](https://huggingface.co/docs/hub/index) et [`safetensors`](https://huggingface.co/docs/safetensors)
- [Documentation de PyTorch](https://docs.pytorch.org/docs/stable/index.html), la référence contre laquelle est écrit la plupart du code de modèles
- Le [cours Rust](../rust-for-csharp-java/) et le [cours IX](../machine-learning-ix/), les prérequis de ce cours
