---
title: "20. Sur le GPU : les shaders WGSL d'IX, leurs limites et leurs accélérations"
description: "ix-gpu d'IX exécute des compute shaders WGSL avec wgpu 28, testés par huit prédictions écrites avant la première exécution ; les huit ont tenu. naga rejette le shader du produit scalaire pour un mot réservé, et la fonction panique. Le shader kNN garde un candidat par thread et perd des voisins dans 135 requêtes sur 1 000, près des 125 que prédit un décompte de type anniversaire. Les fonctions cosinus utilisent deux seuils différents, et similarity_matrix rend 1 sur le CPU là où elle rend 0 sur le GPU. Les limites par défaut font paniquer l'exemple même du guide. Le produit matriciel du GPU égale la boucle du CPU une fois les multiplications-additions fusionnées. Il bat les accélérations du guide aux grandes tailles et perd à 64³."
sidebar:
  order: 20
---

Un GPU exécute un même petit programme, un *compute shader*, sur des milliers de threads à la fois. Le crate [`ix-gpu`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu) d'IX, au commit épinglé, écrit ses shaders en [WGSL](https://www.w3.org/TR/WGSL/), le langage de shaders de WebGPU. Il les exécute avec [wgpu](https://wgpu.rs/) 28, qui vérifie chacun avec le frontal et le validateur de [naga](https://docs.rs/naga/28.0.0/naga/) avant de le passer à Vulkan, DX12 ou Metal.

Quelques termes d'abord :
- les threads vont par *workgroups*, ici de 256 ;
- un workgroup peut partager une petite mémoire déclarée `var<workgroup>` ;
- un *dispatch* lance une grille de workgroups ;
- les données entrent et sortent par des *storage buffers*.

Chaque fonction GPU du crate prend un `GpuContext`, qui contient le device et la queue de wgpu. La plupart des fonctions ont un jumeau CPU. `ix-nn` s'appuie sur l'une d'elles : son attention appelle `matmul_gpu` pour ses deux produits matriciels quand on lui donne un contexte ([`attention.rs` 419-494](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L419-L494)). C'est l'attention du transformer que la [leçon 13](../13-transformer/) a étudiée sur le CPU.

Les huit prédictions que teste cette leçon ont été [écrites dans le journal](../journal/#2026-09-30--leçon-20-prédite-avant-de-mesurer) et commitées avant que son code n'existe. [Les résultats](../journal/#2026-09-30--leçon-20-mesurée) les suivent.

Les runners de la CI n'ont pas de GPU sur lequel le cours peut compter, donc le code se divise en deux :
- **Tourne partout.** [`gpu.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/gpu.rs) contient cette partie : naga sur les cinq shaders, un portage de la boucle du shader kNN, les seuils et les limites. Les shaders sont copiés octet pour octet depuis le commit épinglé dans [`shaders.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/gpu/shaders.rs). [`l20_wgsl.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l20_wgsl.rs) affiche les résultats, et la CI compare sa sortie sous Windows, Linux et macOS.
- **Demande un adaptateur.** La CI n'exécute pas [`l20_on_gpu.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/bin/l20_on_gpu.rs). La leçon cite une exécution sur la machine de l'auteur, conservée dans [`local/l20_on_gpu.txt`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/local/l20_on_gpu.txt). Les tests ignorés de [`tests/l20_gpu.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/tests/l20_gpu.rs) vérifient les mêmes prédictions : `cargo test --release --test l20_gpu -- --ignored --test-threads=1`.

[`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) rejoue la boucle kNN, les seuils et les limites en float32 avec [NumPy](https://numpy.org/doc/stable/), et trouve les mêmes nombres.

## 1. Ce qui tourne où

`GpuContext::new()` demande à wgpu un adaptateur haute performance, puis un device avec `Limits::default()` ([`context.rs` 24-58](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/context.rs#L24-L58)). Le programme affiche ce qu'il a obtenu :

```text
== the adapter
  NVIDIA GeForce RTX 5080 (Vulkan); GpuContext::new() took 532 ms
```

Le guide français d'IX dit que `GpuContext::new()` prend 10 à 100 ms ([`introduction-calcul-gpu.md` 166](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/introduction-calcul-gpu.md?plain=1#L166)). Il a pris 532 ms dans cette exécution, et 1 316 ms dans la première. Après la première exécution, le programme a été modifié pour créer trois contextes de plus dans le même processus, et leur temps médian a été de 274 ms. Le conseil du guide tient : créez un contexte et gardez-le. Mais prévoyez pour lui un quart de seconde ou plus, pas un dixième.

## 2. Un mot réservé

`dot_product_gpu` réduit un produit dans une mémoire de workgroup déclarée `var<workgroup> shared: array<f32, 256>;` ([`similarity.rs` 81](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/similarity.rs#L81)). `shared` est l'un des [mots réservés](https://www.w3.org/TR/WGSL/#reserved-words) de WGSL : la spécification le garde pour un usage futur, donc un shader ne peut rien nommer `shared`. La leçon donne les cinq shaders du crate qu'elle étudie au frontal WGSL de naga, puis à son validateur, et compte les variables dans l'espace d'adressage du workgroup :

```text
== P1, naga 28 on five shaders of ix-gpu, copied from the pinned commit
  cosine: parses; validates: yes; workgroup variables: 3
  dot product: parse error: name `shared` is a reserved keyword
  dot product, `shared` renamed: parses; validates: yes; workgroup variables: 1
  distance matrix: parses; validates: yes; workgroup variables: 0
  kNN: parses; validates: yes; workgroup variables: 0
  matrix product: parses; validates: yes; workgroup variables: 0
```

Le shader du cosinus est la même réduction sous d'autres noms, et il passe. Renommé, le produit scalaire passe aussi.

Sur un GPU, l'erreur d'analyse apparaît quand `create_shader_module` s'exécute. wgpu passe une erreur que personne n'a capturée à un gestionnaire par défaut, et ce gestionnaire provoque une panique ([`wgpu_core.rs` 694-697](https://docs.rs/wgpu/28.0.0/src/wgpu/backend/wgpu_core.rs.html#694-697)). `ix-gpu` n'en capture aucune. Ses `GpuError::ShaderCompilation` et `GpuError::BufferMapping` sont déclarées et jamais construites ([`context.rs` 158-163](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/context.rs#L158-L163)). Une panique dans un appel de bibliothèque emporte le thread de l'appelant avec elle. C'est pourquoi le programme fait chaque appel qui peut paniquer dans un processus enfant à part, `l20_on_gpu probe …`, lancé avec [`std::process::Command`](https://doc.rust-lang.org/std/process/struct.Command.html) :

```text
== P1 on the GPU
  dot_product_gpu, in a process of its own: returns: no; message starts with "wgpu error": yes; contains naga's "name `shared` is a reserved keyword": yes
  cosine_similarity_gpu against cosine_similarity_cpu, 1000 components: gap 3.7e-9
```

Donc à ce commit, avec wgpu 28, `dot_product_gpu` ne peut pas rendre la main. Les propres tests du crate n'atteignent pas non plus le GPU : les tests GPU de `knn.rs` et de `distance.rs` sont commentés, sous « GPU tests require hardware » ([`knn.rs` 367-376](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/knn.rs#L367-L376), [`distance.rs` 242](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/distance.rs#L242)).

La dernière ligne de la sortie de naga contredit un commentaire de documentation. `matmul.rs` dit que son shader « Uses tiled approach with shared memory for better cache behavior » ([`matmul.rs` 11](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs#L11)). Mais le module ne déclare aucune variable de workgroup : chaque thread calcule un élément du résultat directement depuis la mémoire globale. Le guide du produit matriciel le reconnaît et appelle le shader actuel une approche simple par élément ([`multiplication-matricielle-gpu.md` 226](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/multiplication-matricielle-gpu.md?plain=1#L226)). Le guide de la similarité envoie pourtant encore son lecteur vers « le compute shader tuilé sous le capot » ([`recherche-de-similarite.md` 231](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/recherche-de-similarite.md?plain=1#L231)). Un autre commentaire de documentation se trompe : celui d'`euclidean_distance_cpu` dit « Euclidean distance on GPU (via compute shader) » ([`similarity.rs` 249](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/similarity.rs#L249)).

## 3. Un candidat par thread

`batch_knn_gpu` lance un workgroup de 256 threads par requête ([`knn.rs` 34-229](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/knn.rs#L34-L229)) :
1. Le thread t parcourt les références t, t + 256, t + 512, … et ne garde que la plus proche.
2. Le CPU trie les 256 candidats et garde les k premiers.

Le commentaire de documentation décrit autre chose : « a parallel selection of the k smallest », avec « k limited to 32 (stored in shared memory per thread) » ([`knn.rs` 27-33](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/knn.rs#L27-L33)). Le shader n'a aucune variable de workgroup, et k n'est pas limité.

Appelons *classe t* les références dont l'indice est congru à t modulo 256. Les k plus proches sortent justes si et seulement si elles tombent dans k classes différentes. Si deux d'entre elles partagent une classe, le thread de cette classe n'en garde qu'une, et une référence plus lointaine prend la place de celle qui est perdue.

Pour des références et une requête indépendantes et identiquement distribuées, l'ensemble des indices des k plus proches est un sous-ensemble de taille k uniforme de {0, …, N − 1}. Donc P(juste) = e_k(s₀, …, s₂₅₅)/C(N, k), où s_t est la taille de la classe t et e_k le k-ième polynôme symétrique élémentaire. C'est le problème des anniversaires avec des classes de tailles inégales. Avec N = 1 000, il y a 232 classes de 4 et 24 de 3, et pour k = 10 la formule donne P(faux) = 0,1253. La prédiction était de 90 à 160 requêtes fausses sur 1 000, autour de 125,3 avec un écart type de 10,5.

`knn_shader_port` porte la boucle en Rust, en f32, dans le même ordre d'opérations. Ce programme la compare avec `batch_knn_cpu`, le jumeau CPU d'IX, qui trie toutes les références :

```text
== P2, the kNN shader's loop ported to Rust: 1000 references and 1000 queries uniform in [0, 1)^8, k = 10
  P(two of the 10 nearest share a class modulo 256) = 1 - e_10(class sizes) / C(1000, 10) = 0.1253
  queries whose 10 nearest differ from batch_knn_cpu's: 135; with k = 1: 0; with the first 256 references: 0
  true neighbours the port returns: 9855 of 10000
```

Le portage perd des voisins dans 135 requêtes : 145 des 10 000 vrais voisins, donc quelques requêtes en perdent deux. Il n'échoue jamais pour k = 1, ni quand chaque classe ne contient qu'une référence. Un test unitaire ajoute le contrôle : avec au plus 256 références, le portage égale `batch_knn_cpu` pour k = 1, 5, 200 et 250. Le rejeu en float32 de NumPy trouve les mêmes 135 et les mêmes 9 855.

Le portage ne tient lieu du shader que si le GPU fait la même chose, et P6 le vérifie sur l'adaptateur de l'auteur :

```text
== P6, batch_knn_gpu on P2's data, k = 10
  queries whose 10 indices equal the port's, in order: 1000 of 1000; largest distance gap 1.2e-7
  queries whose 10 nearest differ from batch_knn_cpu's: GPU 135, port 135
  the first 256 of the 1000 references: equal to batch_knn_cpu's, in order, for 1000 of 1000
```

La perte ne diminue pas avec plus de données. Après la première exécution, la formule a aussi été évaluée à d'autres tailles :

```text
== exploratory
  P(some of the 10 nearest lost): N = 2000 0.1444, N = 10000 0.1593; N = 1000 with k = 5 0.0291, with k = 20 0.4371
```

Quand N grandit, les classes s'égalisent, et P(faux) tend vers le simple problème des anniversaires à 256 jours, 1 − (256 · 255 ⋯ 247)/256¹⁰ ≈ 0,1631. Elle croît vite avec k. Une sélection exacte des k plus proches sur un GPU garde k candidats par thread, puis les fusionne. [Johnson, Douze et Jégou (2021)](https://doi.org/10.1109/TBDATA.2019.2921572) décrivent comment Faiss le fait dans les registres.

## 4. Deux seuils et une diagonale

Trois fonctions décident de deux façons différentes quand une norme est trop petite pour un cosinus :
- `cosine_similarity_cpu` rend 0 quand l'une des normes est sous 10⁻¹⁰ ([`similarity.rs` 235-247](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/similarity.rs#L235-L247)) ;
- `similarity_matrix_gpu` et `batch_top_k` rendent 0 quand le produit des deux normes est au plus 10⁻¹⁰ ([`batch.rs` 73](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs#L73), [157](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs#L157)).

À part, `similarity_matrix_cpu` écrit 1 sur la diagonale sans la calculer ([`batch.rs` 23-37](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs#L23-L37)). Deux vecteurs a et b = 2a pointent dans la même direction, avec des normes de 3·10⁻⁶ et 6·10⁻⁶ :

```text
== P3, a = (1e-6, 2e-6, 2e-6), b = 2a, z = 0, in f32
  cosine_similarity_cpu(a, b) 1.000000; similarity_matrix(None, [a, b])[0][1] 1.000000; batch_top_k(None, [a], [b], 1) 0.000000
  similarity_matrix(None, [z, b])[0][0] 1.000000; cosine_similarity_cpu(z, z) 0.000000
```

`batch_top_k` leur donne une similarité de 0 : le produit de leurs normes, 1,8·10⁻¹¹, est sous son seuil. Le vecteur nul z est pleinement similaire à lui-même dans la matrice, et pas du tout dans `cosine_similarity_cpu`.

Après la première exécution, les mêmes vecteurs sont passés par `similarity_matrix` avec un contexte :

```text
  P3's vectors with a context: similarity_matrix(Some(&ctx), [a, b])[0][1] 0.000000; similarity_matrix(Some(&ctx), [z, b])[0][0] 0.000000
```

Le commentaire de documentation de `similarity_matrix` dit « Uses GPU if context is provided, otherwise CPU fallback » ([`batch.rs` 12](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs#L12)). Le repli ne calcule pas la même chose. Un vecteur nul est une donnée ordinaire (un document vide, une ligne de remplissage), et il obtient 1 ou 0 selon qu'un GPU a été trouvé ou non.

## 5. Les imports de la skill

La page de la skill `ix-gpu` montre trois imports : `use ix_gpu::similarity::GpuCosineSimilarity;`, `use ix_gpu::matmul::GpuMatMul;` et `use ix_gpu::distance::GpuDistanceMatrix;` ([`SKILL.md` 28-31](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/.claude/skills/ix-gpu/SKILL.md?plain=1#L28-L31)). La seule struct publique du crate est `GpuContext`, et ses modules exportent des fonctions. P4 garde chacune des trois lignes comme doctest `compile_fail`, qui échoue avec E0432, import non résolu. La quatrième ligne de la page, `use ix_gpu::context::GpuContext;`, est gardée comme doctest qui compile.

## 6. Les limites

`Limits::default()` autorise ceci ([`limits.rs` 363-396](https://docs.rs/wgpu-types/28.0.0/src/wgpu_types/limits.rs.html#363-396)) :
- des liaisons de stockage d'au plus 128 Mio ;
- des buffers d'au plus 256 Mio ;
- au plus 65 535 workgroups par dimension d'un dispatch.

wgpu les décrit comme les limites « guaranteed to work on all modern backends » ([`limits.rs` 93-94](https://docs.rs/wgpu-types/28.0.0/src/wgpu_types/limits.rs.html#93-94)). Un adaptateur peut offrir davantage, mais `ix-gpu` ne demande jamais davantage. `similarity_matrix_gpu` lie le résultat n × n de `matmul_gpu` comme un seul storage buffer ([`batch.rs` 43-82](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs#L43-L82)). `batch_knn_gpu` lance un workgroup par requête le long d'une seule dimension. L'arithmétique tourne sur la CI :

```text
== P5, wgpu::Limits::default()
  max_storage_buffer_binding_size 134217728, max_buffer_size 268435456, max_compute_workgroups_per_dimension 65535
  largest n whose n x n f32 matrix fits in one binding: 5792 (134189056 bytes); 5793 needs 134235396
  the guide's 10000 embeddings compared pairwise: 400000000 bytes, above max_buffer_size: yes
```

Le côté GPU fait chaque appel dans un processus à part :

```text
== P5 on the GPU, each call in a process of its own
  similarity_matrix, 5792 vectors of dimension 8: returned
  similarity_matrix, 5793 vectors of dimension 8: panics; "wgpu error": yes; last line: Buffer binding 2 range 134235396 exceeds `max_*_buffer_binding_size` limit 134217728
  similarity_matrix, 10000 vectors of dimension 768: panics; "wgpu error": yes; last line: Buffer size 400000000 is greater than the maximum buffer size (268435456)
  batch_knn_gpu, 65535 queries: returned
  batch_knn_gpu, 65536 queries: panics; "wgpu error": yes; last line: Each current dispatch group size dimension ([65536, 1, 1]) must be less or equal to 65535
```

L'exemple d'ouverture du guide, 10 000 embeddings de dimension 768 ([`introduction-calcul-gpu.md` 5](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/introduction-calcul-gpu.md?plain=1#L5)), ne rend pas la main : il panique. De même pour la ligne « 10 000+ » du guide de la similarité, qui promet une accélération de 10-100x ([`recherche-de-similarite.md` 197](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/recherche-de-similarite.md?plain=1#L197)). L'erreur est une panique, pas un `Result`, donc un appelant ne peut même pas se replier sur le CPU.

À la lecture du code, pas par une exécution : `batch_top_k` fait lui aussi passer son produit requêtes × corpus par `matmul_gpu`. Les mêmes 128 Mio bornent donc requêtes × corpus × 4 octets.

## 7. Les mêmes sommes, presque

`matmul_gpu` et `matmul_cpu` additionnent leurs K produits dans le même ordre ([`matmul.rs` 36-41](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs#L36-L41), [141-156](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs#L141-L156)). `pairwise_distance_gpu` et `pairwise_distance_cpu` aussi, sur les dimensions ([`distance.rs` 46-53](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/distance.rs#L46-L53), [133-153](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/distance.rs#L133-L153)). Le même ordre ne veut pas dire le même arrondi :
- WGSL permet à une implémentation de fusionner une multiplication et une addition en une seule opération avec un seul arrondi, quand le résultat est au moins aussi précis ([§ 15.7.5](https://www.w3.org/TR/WGSL/#reassociation-and-fusion)) ;
- WGSL tire la précision de `sqrt` de celle de `1.0 / inverseSqrt(x)` ([§ 15.7.4.1](https://www.w3.org/TR/WGSL/#concrete-float-accuracy)) ;
- Rust arrondit chaque opération.

Deux produits de matrices 256 × 256 à coefficients dans [−1, 1), et les distances entre les 1 000 références de P2 :

```text
== P7, the GPU's sums against the CPU's
  matmul 256 x 256 x 256: elements that differ 53438 of 65536, largest gap 5.7e-6
  pairwise distances of the 1000 references: elements that differ 264496 of 1000000, largest gap 2.4e-7, zero diagonal: yes
```

82 % des éléments du produit diffèrent, tous dans les derniers bits. Les coefficients ont un écart type d'environ 5,3, donc un écart de 5,7·10⁻⁶ fait environ un millionième.

Après la première exécution, le programme a aussi exécuté les deux boucles CPU avec [`f32::mul_add`](https://doc.rust-lang.org/std/primitive.f32.html#method.mul_add), qui fusionne chaque multiplication-addition en un seul arrondi :

```text
  P7's loops on the CPU with fused multiply-adds: matmul elements that differ from the GPU 0 of 65536; distances 168810 of 1000000
```

Le produit matriciel concorde alors bit pour bit : ce pilote a fusionné chaque multiplication-addition du shader. Pour les distances, la fusion fait passer le compte de 264 496 à 168 810, et le reste n'est pas expliqué ici. Un candidat est la racine carrée, dont WGSL n'impose pas l'arrondi correct, mais cette leçon ne le teste pas. Un autre adaptateur ou un autre backend peut fusionner autrement, donc comparez un résultat GPU à un résultat CPU avec une tolérance, jamais bit pour bit.

## 8. Les accélérations promises

Le guide du produit matriciel donne un tableau du gain à attendre pour quatre tailles ([`multiplication-matricielle-gpu.md` 180-184](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/multiplication-matricielle-gpu.md?plain=1#L180-L184)) :

| Taille | Gain que promet le guide |
|---|---|
| 10 × 10 × 10 | aucun |
| 64 × 64 × 64 | marginal |
| 256 × 768 × 1024 | 5-20x |
| 1024 × 1024 × 1024 | 20-100x |

P8 n'a prédit que les deux extrêmes. Les deux tailles du milieu ont été mesurées sans prédiction. Chaque temps est la médiane de 5 appels après un échauffement non chronométré, avec un seul contexte du début à la fin :

```text
== P8, matmul_cpu against matmul_gpu, median of 5 calls after a warm-up
  10 x 10 x 10: cpu 0.001 ms, gpu 0.490 ms, gpu faster by 0.0x
  64 x 64 x 64: cpu 0.086 ms, gpu 0.448 ms, gpu faster by 0.2x
  256 x 768 x 1024: cpu 179.753 ms, gpu 2.908 ms, gpu faster by 61.8x
  1024 x 1024 x 1024: cpu 2133.655 ms, gpu 8.722 ms, gpu faster by 244.6x
```

La première exécution a donné 54,0x et 137,1x aux deux grandes tailles. Le temps du GPU à 1024³ a à peine bougé entre les exécutions, de 8,456 à 8,722 ms. Celui du CPU est passé de 1 160 à 2 134 ms, et la leçon ne sait pas pourquoi.

Les deux exécutions battent le guide aux grandes tailles. Les deux perdent à 64³, où le gain « marginal » est en fait un GPU cinq fois plus lent. Trois choses expliquent ce profil :
- **La référence CPU est faible.** `matmul_cpu` est la triple boucle des manuels, sur un seul thread et sans SIMD, ce que le guide dit lui-même ([`multiplication-matricielle-gpu.md` 191](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/multiplication-matricielle-gpu.md?plain=1#L191)). À 1024³, elle prend 1 à 2 ns par produit. Les accélérations mesurent donc cette boucle autant que le GPU. Un produit CPU par blocs, vectorisé ou multithread les réduirait ; la leçon n'en a pas mesuré.
- **Le GPU fait bien moins qu'il ne pourrait.** 2 × 1024³ opérations en 8,7 ms font environ 250 GFLOP/s, avec un shader sans tuiles. [Volkov et Demmel (2008)](https://doi.org/10.1109/SC.2008.5214359) montrent ce qu'apportent des tuiles en mémoire de workgroup.
- **Chaque appel GPU paie un coût fixe.** Jusqu'à 64³, un appel coûte environ une demi-milliseconde quelle que soit sa taille. `matmul_gpu` crée ses buffers, son module de shader et son pipeline à chaque appel ([`matmul.rs` 60-138](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs#L60-L138)), puis soumet et relit. Le guide indique un coût d'initialisation d'environ 1 ms, « premier appel : compilation shader » ([`multiplication-matricielle-gpu.md` 192](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/multiplication-matricielle-gpu.md?plain=1#L192)). Le guide de la similarité ajoute que les appels suivants réutilisent le pipeline compilé ([`recherche-de-similarite.md` 223](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/recherche-de-similarite.md?plain=1#L223)). Rien dans `ix-gpu` ne garde un pipeline d'un appel à l'autre. Le pilote met peut-être en cache le shader compilé, mais cette leçon ne le mesure pas.

Le guide d'introduction place le point de croisement entre 1 000 et 10 000 éléments ([`introduction-calcul-gpu.md` 149](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/introduction-calcul-gpu.md?plain=1#L149)). Une matrice 64 × 64 contient 4 096 éléments, dans cet intervalle, et le GPU y est cinq fois plus lent.

## 9. Les prédictions, notées

| | Prédiction, écrite avant la première exécution | Mesuré | Verdict |
|---|---|---|---|
| P1 | naga rejette le produit scalaire avec « name `shared` is a reserved keyword », le valide une fois renommé et valide les quatre autres ; aucune variable de workgroup dans le produit matriciel ; sur le GPU, `dot_product_gpu` panique avec « wgpu error » et le message de naga, et le cosinus concorde à 10⁻⁶ près | Comme prédit ; écart du cosinus 3,7·10⁻⁹ | Confirmée |
| P2 | Les 10 plus proches du portage diffèrent de ceux de `batch_knn_cpu` pour 90 à 160 requêtes sur 1 000 ; pour aucune avec k = 1 ou avec les 256 premières références | 135 ; 0 et 0 | Confirmée |
| P3 | `cosine_similarity_cpu(a, b)` et le [0][1] de la matrice égaux à 1 à 10⁻⁶ près, `batch_top_k` 0 ; diagonale du vecteur nul à 1 ; `cosine_similarity_cpu(z, z)` 0 | 1, 1 et 0 ; 1 ; 0 | Confirmée |
| P4 | Les trois imports de la skill échouent avec E0432 ; `use ix_gpu::context::GpuContext;` compile | Comme prédit | Confirmée |
| P5 | 5 792 vecteurs tiennent et 5 793 non ; l'exemple du guide demande 400 000 000 octets, au-dessus de la limite des buffers ; sur le GPU, 5 792 rend la main, 5 793 et 10 000 × 768 paniquent, 65 535 requêtes rendent la main, 65 536 paniquent | Comme prédit | Confirmée |
| P6 | Le GPU rend les indices du portage, dans l'ordre, pour 1 000 requêtes sur 1 000, distances à 10⁻⁶ près ; avec les 256 premières références, ceux de `batch_knn_cpu` pour chaque requête | 1 000 ; 1,2·10⁻⁷ ; 1 000 | Confirmée |
| P7 | `matmul_gpu` diffère de `matmul_cpu` en au moins un élément et d'au plus 10⁻⁴ ; distances à 10⁻⁵ près, diagonale nulle | 53 438 éléments, 5,7·10⁻⁶ ; 2,4·10⁻⁷, nulle | Confirmée |
| P8 | À 1024³, `matmul_gpu` au moins 20 fois plus rapide ; à 10³, `matmul_cpu` plus rapide | 244,6x (137,1x à la première exécution) ; 0,001 contre 0,490 ms | Confirmée |

Les huit ont tenu à la première exécution, et aucun intervalle n'a été changé après coup. Certains intervalles étaient larges : 10⁻⁴ dans P7 et 20x dans P8 laissent de la marge, et une prédiction qui peut difficilement échouer apprend moins. Les contrôles montrent que les vérifications peuvent échouer :
- le produit scalaire renommé est validé, donc la vérification par naga ne rejette pas tout ;
- le portage égale `batch_knn_cpu` dès que chaque classe contient une seule référence ;
- 5 792 vecteurs et 65 535 requêtes rendent bien la main.

Tout ce que la leçon présente comme venant après la première exécution a été choisi après avoir vu son résultat : les boucles fusionnées, `similarity_matrix` avec un contexte, les contextes supplémentaires et la formule à d'autres tailles.

## Quoi utiliser dans nos dépôts

- **Les erreurs.** Le device d'un `GpuContext` est public. Pour qu'une erreur de wgpu ne provoque pas de panique, entourez les appels de [`Device::push_error_scope`](https://docs.rs/wgpu/28.0.0/wgpu/struct.Device.html#method.push_error_scope), ou installez [`Device::on_uncaptured_error`](https://docs.rs/wgpu/28.0.0/wgpu/struct.Device.html#method.on_uncaptured_error), et repliez-vous sur le jumeau CPU. La leçon n'a testé ni l'un ni l'autre ; *à vérifier*.
- **`dot_product_gpu` :** il ne peut pas s'exécuter. Reprenez le schéma de `cosine_similarity_gpu`, ou utilisez le CPU.
- **`batch_knn_gpu` :** ne l'utilisez que si une requête peut se permettre de perdre des voisins : avec 1 000 références, 13 % des requêtes en perdent à k = 10 et 44 % à k = 20. Pour des voisins exacts, utilisez `batch_knn_cpu`, ou, jusqu'à 256 références, le GPU.
- **`similarity_matrix` :** ne vous fiez pas à son résultat sur un vecteur nul ou sur des vecteurs de norme minuscule. Normalisez les vecteurs vous-même et traitez le vecteur nul explicitement, de la même façon sur les deux chemins. Au-delà de 5 792 vecteurs, découpez la matrice en blocs.
- **`batch_knn_gpu` au-delà de 65 535 requêtes :** découpez le lot.
- **`matmul_gpu` :** rentable à 256 × 768 × 1024 et au-dessus sur cette machine, pas à 64³. Comparez ses résultats avec une tolérance.
- **La skill `ix-gpu` :** importez des fonctions, comme `use ix_gpu::matmul::matmul_gpu;`, et `ix_gpu::context::GpuContext`.

## Exercices

1. Calculez P(faux) pour k = 2 et N = 1 000 à la main, puis expliquez pourquoi elle vaut exactement 0 pour k = 1.
2. Pourquoi P(faux) tend-elle vers 1 − (256 · 255 ⋯ 247)/256¹⁰ quand N grandit, pour k = 10 ?
3. Modifiez le shader kNN pour qu'il rende les k plus proches exacts pour k ≤ 16. Que garde chaque thread, et qu'en fait le CPU ?
4. Réécrivez les seuils de `cosine_similarity_cpu` et de `batch_top_k` pour qu'ils donnent la même réponse pour les a et b de la section 4, et pour tous leurs multiples positifs. Que devrait obtenir le vecteur nul ?
5. Avec `Limits::default()`, comment calculeriez-vous les similarités des 10 000 embeddings de dimension 768 du guide avec `matmul_gpu`, sans un seul appel qui panique ?

<details>
<summary>Solutions</summary>

1. Avec k = 2, la réponse est fausse exactement quand les 2 plus proches partagent une classe. Cela fait Σ C(s_t, 2)/C(1 000, 2) = (232 × 6 + 24 × 3)/499 500 = 1 464/499 500 ≈ 0,00293, soit environ 3 requêtes sur 1 000. Pour k = 1, la référence la plus proche est la plus proche de sa propre classe, donc son thread la garde, et elle est la plus petite des 256 candidates.
2. Quand N grandit, chaque classe contient environ N/256 références, et les 10 plus proches forment un sous-ensemble uniforme de taille 10. Chaque indice tombe dans une classe avec une probabilité proche de 1/256, indépendamment des autres, puisque tirer sans remise dans de grandes classes se comporte comme tirer avec remise. Ils tombent dans 10 classes différentes avec la probabilité (256/256) · (255/256) ⋯ (247/256) : le problème des anniversaires avec 256 jours et 10 personnes.
3. Chaque thread garde ses k plus proches dans un petit tableau trié, dans les registres, en insérant chaque nouvelle distance par décalage des plus grandes. Le CPU, ou une seconde passe sur le GPU, fusionne ensuite les 256 listes triées et garde les k premiers. Les vrais k plus proches sont parmi eux, car chacun est parmi les k plus proches de sa propre classe. C'est le schéma de Johnson, Douze et Jégou, avec une fusion à la place de leur tri au niveau du warp.
4. Le cosinus ne change pas quand on multiplie un vecteur par un facteur positif, donc un seuil fixe sur une norme, ou sur un produit de normes, ne peut pas être juste à toutes les échelles. Comparez les normes à zéro, `norm_a > 0.0 && norm_b > 0.0`, et divisez par chaque norme séparément, `dot / norm_a / norm_b`, pour que le produit de deux petites normes ne puisse pas sous-déborder en f32. Le vecteur nul n'a pas de direction, donc son cosinus n'est pas défini. Rendez 0, ou `None`, sur les deux chemins, et jamais un 1 écrit en dur sur la diagonale.
5. Normalisez d'abord les vecteurs sur le CPU, pour qu'un produit scalaire soit un cosinus. Découpez ensuite les 10 000 vecteurs en blocs d'au plus 5 792 lignes, par exemple deux blocs de 5 000. Chaque produit d'un bloc par la transposée d'un autre fait 5 000 × 5 000 × 4 = 100 000 000 octets, sous la limite de liaison de 128 Mio. Quatre produits donnent la matrice entière, et trois suffisent, puisqu'elle est symétrique. Les entrées doivent aussi tenir : 5 000 × 768 × 4 = 15 360 000 octets par bloc.

</details>

## Sources

- IX au commit épinglé `490c395` : [`similarity.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/similarity.rs), [`knn.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/knn.rs), [`batch.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs), [`matmul.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs), [`distance.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/distance.rs), [`context.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/context.rs), [la skill `ix-gpu`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/.claude/skills/ix-gpu/SKILL.md), et les guides français [`introduction-calcul-gpu.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/introduction-calcul-gpu.md), [`multiplication-matricielle-gpu.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/multiplication-matricielle-gpu.md) et [`recherche-de-similarite.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/recherche-de-similarite.md).
- W3C, [WebGPU Shading Language](https://www.w3.org/TR/WGSL/) : [mots réservés](https://www.w3.org/TR/WGSL/#reserved-words), [réassociation et fusion](https://www.w3.org/TR/WGSL/#reassociation-and-fusion), [précision des expressions flottantes concrètes](https://www.w3.org/TR/WGSL/#concrete-float-accuracy).
- [wgpu](https://wgpu.rs/) 28 : [`Limits::default`](https://docs.rs/wgpu-types/28.0.0/src/wgpu_types/limits.rs.html#363-396), [le gestionnaire d'erreurs par défaut](https://docs.rs/wgpu/28.0.0/src/wgpu/backend/wgpu_core.rs.html#694-697), [`Device`](https://docs.rs/wgpu/28.0.0/wgpu/struct.Device.html). [naga](https://docs.rs/naga/28.0.0/naga/) 28 : [la vérification des mots réservés](https://docs.rs/naga/28.0.0/src/naga/front/wgsl/parse/lexer.rs.html#495-497).
- V. Garcia, E. Debreuve et M. Barlaud, [« Fast k nearest neighbor search using GPU »](https://doi.org/10.1109/CVPRW.2008.4563100), CVPR Workshops, 2008.
- J. Johnson, M. Douze et H. Jégou, [« Billion-scale similarity search with GPUs »](https://doi.org/10.1109/TBDATA.2019.2921572), IEEE Transactions on Big Data 7, 2021.
- V. Volkov et J. W. Demmel, [« Benchmarking GPUs to tune dense linear algebra »](https://doi.org/10.1109/SC.2008.5214359), SC 2008.
- Rust : [`f32::mul_add`](https://doc.rust-lang.org/std/primitive.f32.html#method.mul_add), [`std::process::Command`](https://doc.rust-lang.org/std/process/struct.Command.html). [NumPy](https://numpy.org/doc/stable/).
