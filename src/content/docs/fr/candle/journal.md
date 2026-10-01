---
title: Journal
description: Notes d'avancement datées — Candle 0.11.0 épinglé, le code du cours et sa vérification, les mesures, si GA, IX et TARS utilisent Candle, seize constats sur Candle, sa documentation et celle d'IX, et les points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Candle lu au tag `0.11.0`, commit `31f35b1` ; le code du cours dépend de `candle-core` et `candle-nn` 0.11.0
- [x] Code du cours : exemples, sorties `expected/`, sept doctests `compile_fail`, `check.sh`
- [x] Mêmes sorties sous Windows et sous Linux (un conteneur `rust:1.94.0`)
- [ ] CI sur GitHub : le workflow est écrit, pas encore poussé
- [x] Leçon 1 : pourquoi Candle
- [x] Leçon 2 : tenseurs
- [x] Leçon 3 : calcul et performance sur CPU
- [x] Leçon 4 : différentiation automatique
- [ ] Leçons 5 à 12
- [x] Traductions française et espagnole des leçons 1 à 4

## 2026-09-15 — Candle, épinglé

- La dernière version sur crates.io est **0.11.0**, publiée le 26 juin 2026. Ses sources sont le tag `0.11.0`, commit [`31f35b147389700ed2a178ee66a91c3cc25cc80d`](https://github.com/huggingface/candle/commit/31f35b147389700ed2a178ee66a91c3cc25cc80d), cloné à part de ce dépôt. `main` était à [`ddf1b87`](https://github.com/huggingface/candle/commit/ddf1b879dc3a1760cbcb3f3c4a7c6467850cec4a) le même jour.
- Le workspace liste dix membres, dont les exemples WebAssembly, et garde six autres crates à part (les noyaux GPU, `candle-onnx`, le livre) ; `candle-transformers` a 125 entrées sous `models/` et `candle-examples` 111 exemples.
- Le cours épingle `=0.11.0` dans `Cargo.toml` et commite `Cargo.lock`, au lieu de suivre `main` comme le fait le `cargo add --git` du livre de Candle.
- Le code n'utilise que le CPU : aucune feature Cargo n'est activée, aucun modèle n'est téléchargé dans ce lot.

## 2026-09-15 — Le code du cours

- [`code/candle`](https://github.com/spareilleux/learn/tree/c45b150/code/candle) est un workspace avec une seule crate, `candle-course` : 13 exemples, et `src/lib.rs` avec les fonctions utilitaires `show` (arrondit chaque valeur, pour que les trois systèmes affichent les mêmes chiffres), `outcome` et `caught` (affiche le message d'une panique), et les sept doctests `compile_fail`.
- [`check.sh`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/check.sh) exécute `cargo fmt --check`, `clippy --release --all-targets -D warnings`, `cargo test --release`, puis chaque exemple, et compare sa sortie et son code de sortie avec `expected/`. `l01_machine` et `l03_bench` dépendent de la machine : ils s'exécutent sans comparaison.
- `rustdoc` stable vérifie qu'un extrait `compile_fail` échoue, pas avec quelle erreur. Un doctest annonçait d'abord `E0369` pour `Result<Tensor> - f64` ; compiler l'extrait a donné `E0277`. Le workflow ajoute un `cargo test --doc` nightly sous Linux, qui vérifie les codes.
- Le premier build release a compilé 128 crates en 73 secondes avec `-j 4`. 72 des 119 crates derrière `candle-core` viennent de `tokenizers`.
- `data/builds.csv` est une copie du fichier du cours IX, du commit `d9ef7fb`, pour que la leçon 4 entraîne sur les mêmes 52 builds.
- `ix-autograd` vient de Git au commit `490c395` d'IX, celui du cours IX, comme dépendance de développement.
- Sous Linux, `check.sh` a tourné dans Docker Desktop 29.2.1 (`rust:1.94.0`, `--cpus 4`) : chaque sortie comparée était identique à celle de Windows.

## 2026-09-15 — La CI

- `.github/workflows/candle-examples.yml` est écrit : `check.sh` sur `ubuntu-latest`, `windows-latest` et `macos-latest`, un cache du registre Cargo, des checkouts Git et de `target/`, avec `Cargo.lock` pour clé, et l'étape de doctests nightly sous Linux.
- Il n'est pas poussé : le jeton avec lequel cette session pousse ne peut pas créer de fichiers sous `.github/workflows/` sans le scope `workflow`. Tant qu'il n'a pas tourné, macOS (ARM, NEON) est *à vérifier*, en particulier les sommes `f32` de la leçon 4, qui pourraient s'arrondir différemment.

## 2026-09-15 — Les mesures

- Intel Core Ultra 9 285K (24 cœurs, sans hyper-threading), 64 Go, Windows 11 Pro, Rust 1.94.0. La machine faisait tourner d'autres travaux en même temps ; la leçon le dit et considère les écarts de moins de 20 % environ comme du bruit.
- La première version du benchmark de passe avant exécutait les tenseurs simples, puis les `Var`, une fois chacun, et montrait le graphe plus rapide de 35 %. Deux tours alternés ont révélé un effet d'échauffement ; la leçon montre la version alternée et explique pourquoi.
- `target-cpu=native` a compilé en 65 secondes dans un répertoire cible séparé et n'a rien changé au-delà du bruit. `gemm` choisit déjà des noyaux AVX2 et FMA à l'exécution.
- Dans un conteneur limité à 4 CPU, Candle compte toujours 24 cœurs physiques et démarre 24 threads : le petit réseau a pris 168 ms contre 44 ms avec `RAYON_NUM_THREADS=1`.

## 2026-09-15 — GA, IX et TARS

Commits lus : GA [`32f143c`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381), IX [`a7e5fbc`](https://github.com/GuitarAlchemist/ix/tree/a7e5fbce3d4a7a9d15bb9638b3bcba7c08c2941a) (avec `ix-autograd` inchangé depuis `490c395`), TARS [`87464ce`](https://github.com/GuitarAlchemist/tars/tree/87464ce583c42cd11c3d76836e05842377455b24).

- Aucun des trois ne dépend de Candle. GA (C#) et TARS (F#) exécutent leurs modèles avec ONNX Runtime et `Microsoft.ML.Tokenizers`.
- IX a écrit sa propre différentiation automatique, `ix-autograd`, au-dessus de `ndarray`, et garde une place pour un backend Candle. La leçon 4 montre que son gradient et celui de Candle concordent à `1e-9` sur la régression du cours IX.
- Là où Candle pourrait servir : les embeddings de GA (la leçon 7 compare), et un backend pour `ix-autograd` si IX a besoin de plus d'opérations ou d'un GPU. Ce sont des notes pour les leçons suivantes, pas des propositions faites aux projets.

## 2026-09-15 — Constats

Seize choses trouvées par ce lot, chacune montrée par du code compilé du cours sauf mention contraire. Rien n'est déposé en issue ni en pull request.

1. **Un compilateur C pour `candle-core` 0.11.0.** Il dépend de `tokenizers` avec la feature `onig`, qui compile Oniguruma depuis ses sources C, pour un seul fichier, le tokenizer GGUF ([leçon 1](../01-why-candle/)). `main` est passé à `fancy-regex`, en Rust pur ; la prochaine version devrait supprimer cette exigence (*à vérifier*).
2. **`from_vec` et `from_slice` ne vérifient pas le nombre d'éléments** quand la forme n'a pas de trou : cinq valeurs avec une forme `(2, 3)` sont acceptées et paniquent plus tard ([leçon 2](../02-tensors/)). [Issue #3812](https://github.com/huggingface/candle/issues/3812), corrigée sur `main` par [#3813](https://github.com/huggingface/candle/pull/3813) le 13 août 2026, après 0.11.0.
3. **Les fonctions flottantes sur des tenseurs entiers paniquent** avec `todo!("no unary function for u32")` au lieu de renvoyer une erreur ([leçon 2](../02-tensors/)). C'est toujours le cas sur `main` à `ddf1b87` ; aucune issue trouvée à ce sujet.
4. **Le générateur aléatoire du CPU ne peut pas recevoir de graine** : `Device::Cpu.set_seed(42)` renvoie une erreur, donc `rand` et `randn` ne sont pas reproductibles sur le CPU ([leçon 2](../02-tensors/)).
5. **L'aide-mémoire du README ne compile pas** : `tensor.to_dtype(&DType::F16)?` passe une référence là où `to_dtype` prend un `DType` ([leçon 1](../01-why-candle/), un doctest).
6. **`copy()` clone tout le stockage**, pas les éléments de la vue : une ligne de 1000 éléments d'un tenseur de 4 Mo tient toujours 4 Mo après `copy()` ; `force_contiguous` tient 4 Ko ([leçon 3](../03-cpu-performance/)).
7. **Un message déroutant pour un indice de trop** : `m.i((0, 0, 0))` sur une matrice dit "dimension index 0 out of range for shape []" ([leçon 2](../02-tensors/)).
8. **`squeeze` sur une dimension dont la taille n'est pas 1 réussit en silence** et renvoie le tenseur inchangé, comme PyTorch ([leçon 2](../02-tensors/)).
9. **Les gradients vont aussi aux tenseurs simples** qui sont des entrées directes d'opérations enregistrées : la régression de la leçon 4 calcule des gradients pour ses données ([leçon 4](../04-autodiff/)). Correct, mais du travail en plus.
10. **`backward` sur un non-scalaire est amorcé avec des uns sans avertissement**, là où PyTorch refuse ([leçon 4](../04-autodiff/)).
11. **Le nombre de threads par défaut ignore les limites CPU des conteneurs** : 24 threads sous `--cpus 4`, quatre fois plus lent sur un petit réseau qu'un seul thread ([leçon 3](../03-cpu-performance/)).
12. **`target-cpu=native` n'a apporté aucun gain mesurable** pour les produits matriciels, les opérations élément par élément ou un petit réseau sur cette machine ; le `.cargo/config.toml` de Candle l'active pour ses exemples ([leçon 3](../03-cpu-performance/)).
13. **Les produits matriciels `f16` ne sont pas plus rapides que `f32` sur un CPU** : `gemm-f16` convertit en blocs `f32` ([leçon 3](../03-cpu-performance/)).
14. **La documentation d'IX décrit Candle comme utilisant « cuTENSOR »** ([`code-analysis-tools.md`, ligne 129](https://github.com/GuitarAlchemist/ix/blob/a7e5fbce3d4a7a9d15bb9638b3bcba7c08c2941a/docs/guides/code-analysis-tools.md?plain=1#L129)) ; les features CUDA de Candle utilisent cuBLAS, cuBLASLt, cuRAND, NVRTC et, en option, cuDNN ([leçon 1](../01-why-candle/)). Lu dans les sources, pas exécuté.
15. **`hf-hub`** : le workspace de Candle 0.11.0 demande `hf-hub` 0.5.0 alors que la dernière version sur crates.io est 1.0.0. Pour la leçon 6 (*à vérifier* ce qui a changé).
16. **Le livre de Candle installe depuis Git** : `cargo add --git https://github.com/huggingface/candle.git candle-core` suit `main`, donc un exemple du livre peut dépendre de code non publié ([leçon 1](../01-why-candle/)).

## 2026-09-30 — Leçon 5 : prédictions avant la première exécution

Écrites d'après les sources de `candle-nn` 0.11.0, avant que le code de la leçon existe ; l'entrée des résultats confrontera chacune à ce que les programmes impriment. Le jeu de données est Iris, du UCI Machine Learning Repository (Fisher, 1936, [doi:10.24432/C56C76](https://doi.org/10.24432/C56C76), CC BY 4.0), dans sa version corrigée `bezdekIris.data` ; l'archive contient aussi `iris.data`, dont les lignes 35 et 38 diffèrent de l'article de Fisher.

1. **Initialisation.** [`linear`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/linear.rs#L84-L94) tire ses poids d'une loi normale d'écart-type √(2 / in), Kaiming avec le gain de ReLU ([`init.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/init.rs#L105-L109)), et ses biais uniformément dans ±1/√in. Sur une couche 512 → 512, l'écart-type mesuré des poids devrait être à moins de 1 % de 0,0625, soit √6 ≈ 2,45 fois celui de `nn.Linear` par défaut dans PyTorch (uniforme dans ±1/√in, écart-type 1/√(3 · in)), et chaque biais dans ±0,0442, comme dans PyTorch.
2. **Reproductibilité.** Deux `VarMap` remplies par les mêmes appels à `linear` reçoivent des poids différents, parce que le générateur du CPU ne peut pas recevoir de graine (constat 4). Le cours écrasera chaque variable avec les valeurs de son propre générateur à graine.
3. **Entropie croisée.** `loss::cross_entropy` devrait égaler la moyenne de −log softmax à la cible, calculée à la main, à 1e-12 près en `f64`, et rester finie pour des logits de 1000, là où softmax puis log écrits naïvement (sans soustraire le maximum) donnent NaN.
4. **Entropie croisée binaire avec logits.** [`binary_cross_entropy_with_logit`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/loss.rs#L64-L74) prend la sigmoïde, puis les logarithmes de `p` et de `1 − p` : une prédiction sûre et *juste* devrait donc donner NaN. En `f32`, c'est le cas d'un logit de 17 avec la cible 1 (16 reste fini) et d'un logit de −100 avec la cible 0 ; en `f64`, d'un logit de 37 avec la cible 1 (36 reste fini). La forme stable `max(x, 0) − x·y + log(1 + e^−|x|)` reste finie partout. Le [ticket #2561](https://github.com/huggingface/candle/issues/2561) signale cette instabilité depuis 2024.
5. **Optimiseurs.** Un pas de [`SGD`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/optim.rs#L31-L70) égale `θ − lr · g` bit pour bit (il n'y a pas de momentum). Trois pas d'[`AdamW`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/optim.rs#L117-L183) égalent l'algorithme AdamW de PyTorch écrit à la main (décroissance découplée `θ · (1 − lr · λ)`, moments corrigés du biais, ε hors de la racine) à 1e-12 près en `f64`.
6. **Variables entières.** Les deux optimiseurs écartent sans rien dire les variables dont le type n'est pas flottant : un `SGD` construit à partir d'un `Var` `u32` et d'un `Var` `f32` ne garde qu'une variable.
7. **Iris.** Un réseau 4 → 16 → 3 avec ReLU, entraîné sur 120 lignes (40 par espèce, standardisées avec les moyennes et écarts-types du jeu d'entraînement) pendant 300 époques d'`AdamW` sur le lot complet, avec un taux d'apprentissage de 0,01, classe correctement au moins 28 des 30 lignes mises de côté, et ses éventuelles erreurs sont entre versicolor et virginica, aucune sur setosa.
8. **`f32` contre `f64`.** Le même entraînement en `f32` donne les mêmes 30 prédictions de test, et une perte finale d'entraînement à moins de 1e-4 de celle en `f64`.
9. **`SGD` contre `AdamW`.** Le `SGD` simple avec un taux de 0,1, à partir des mêmes poids et pendant les mêmes 300 époques, finit avec une perte d'entraînement plus haute qu'`AdamW` à 0,01.

## À vérifier

- La première exécution du workflow sur les trois systèmes, et les sorties `f32` sur macOS ARM.
- L'exigence d'un compilateur C après la prochaine version de Candle.
- `default_num_threads` sur Apple Silicon, qui ne compte que les cœurs performance.
- `CANDLE_GRAD_DO_NOT_DETACH` et les dérivées secondes.
- Pourquoi les opérations élément par élément contiguës prennent moitié moins de temps sous Linux que sous Windows, sur le même processeur (l'allocation, par hypothèse).
