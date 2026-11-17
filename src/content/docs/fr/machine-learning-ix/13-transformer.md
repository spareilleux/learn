---
title: "13. Attention, normalisation de couche et bloc transformeur"
description: "L'attention et la normalisation de couche écrites à la main, puis le bloc transformeur de la crate ix-nn d'IX vérifié face aux formules, aux différences centrées et à numpy, avec neuf prédictions écrites avant la première exécution : toutes les neuf tiennent. La passe avant est exacte ; le backward met à jour les LayerNorm du bloc avec le gradient entier et ses autres poids avec le dixième."
sidebar:
  order: 13
---

La leçon 7 a trouvé que `Dense::backward` d'IX divise une seconde fois par la taille du batch (constat 15), et la leçon 12 a montré comment un ruban calcule des gradients sans que personne ne les dérive. Un transformeur réunit les deux questions : il a plus de couches que le réseau de la leçon 7, chacune avec un backward écrit à la main. La crate [`ix-nn`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn) d'IX, au commit épinglé, en fournit les pièces : l'attention par produit scalaire mis à l'échelle et l'attention multi-têtes, la normalisation de couche, un réseau feed-forward, et un bloc qui les empile avec des connexions résiduelles. Cette leçon écrit l'attention et la normalisation de couche à la main, leur confronte les versions d'IX, puis vérifie ce que le backward d'IX fait à chaque poids.

Les neuf prédictions que teste cette leçon ont été [écrites dans le journal](../journal/#2026-09-30--leçon-13-prédite-avant-de-mesurer) et commitées avant que son code n'existe. [Les résultats](../journal/#2026-09-30--leçon-13-mesurée) les suivent. Les expériences sont dans [`transformer.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/transformer.rs), un test par prédiction. [`l13_transformer.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l13_transformer.rs) affiche ce qu'elles mesurent. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recalcule l'attention, la normalisation et le tableau de mise à l'échelle avec [numpy](https://numpy.org/doc/stable/).

## 1. L'attention, à la main

Chaque jeton d'une séquence pose une question, une requête q, et chaque jeton offre une clé k et une valeur v. La similarité de la requête avec chaque clé, mise à l'échelle puis passée dans un softmax, devient un poids, et la sortie du jeton est la moyenne des valeurs pondérée par ces poids ([Vaswani et al.](https://arxiv.org/abs/1706.03762), section 3.2.1) :

Attention(Q, K, V) = softmax(QKᵀ / √d_k) V

où chaque ligne de Q, K et V est un jeton et d_k la longueur d'une requête. `attention_by_hand`, dans `transformer.rs`, la calcule par des boucles simples. [`scaled_dot_product_attention`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L45-L92) d'IX la calcule par des produits de matrices, un élément du batch à la fois (P1) :

```text
== Attention by hand and in IX
  Q, K, V of shape (2, 4, 3), uniform in [-1, 1)
  weights of batch 0, query 0: [0.255277, 0.255466, 0.217414, 0.271842]
  output of batch 0, query 0:  [-0.338191, -0.187914, 0.504304]
  largest difference from softmax(QK^T/sqrt(d_k))V by hand: output < 1e-12, weights < 1e-12
  largest |row sum of the weights - 1|: < 1e-12
```

Les quatre poids valent chacun à peu près un quart, car des requêtes et des clés aléatoires de longueur 3 ne ressemblent guère plus à une clé qu'à une autre. numpy, à partir des mêmes nombres aléatoires, affiche les mêmes poids et la même sortie.

## 2. Pourquoi diviser par √d_k

Si les composantes de q et de k sont indépendantes, de moyenne 0 et de variance 1, alors q·k est une somme de d_k produits de variance 1 chacun, et sa variance vaut d_k. Sans la mise à l'échelle, les scores s'étalent à mesure que les vecteurs s'allongent, et le softmax donne presque tout le poids au plus grand :

```text
== Why divide by sqrt(d_k)
  components of q and k with variance 1, 16 keys, 2000 queries
     d   var(q.k)   largest weight, unscaled   scaled
     4        4.0                      0.413    0.226
    16       15.7                      0.679    0.238
    64       63.8                      0.847    0.247
   256      259.7                      0.925    0.247
```

À d_k = 256, le softmax sans mise à l'échelle met 0,925 du poids sur une seule clé parmi 16, là où le gradient d'un softmax est presque nul. Divisés par √d_k, les scores gardent une variance de 1 à toute longueur, et le plus grand poids reste proche d'un quart. Vaswani et al. donnent cet argument dans leur note 4.

## 3. La normalisation de couche

Une normalisation de couche ([Ba et al.](https://arxiv.org/abs/1607.06450)) remet chaque jeton à l'échelle séparément : on retranche la moyenne de ses composantes, on divise par leur écart type, puis on multiplie par un γ appris et on ajoute un β appris, un de chaque par composante. Elle utilise la variance de la population, et un ε sous la racine évite de diviser par zéro pour un jeton constant. Une normalisation par batch fait la même chose composante par composante, à travers les jetons d'un batch : c'est pourquoi elle dépend du batch, et la normalisation de couche non.

```text
== Layer normalization
  token 0:             [2.951819, 3.736748, -0.556086, 2.897718, 3.615376, 3.820285]
  normalized by IX:    [0.136528, 0.652960, -2.171448, 0.100933, 0.573105, 0.707922]
  largest difference from (x - mean)/sqrt(var + 1e-5) by hand: < 1e-12
  mean of each token after: [0.000000, 0.000000], variance: [0.999996, 0.999997]
```

La variance après normalisation ne vaut pas 1 mais var/(var + ε), avec l'ε = 10⁻⁵ d'IX ([`norm.rs` 36-46](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/norm.rs#L36-L46)). γ part de 1 et β de 0 : une normalisation de couche neuve ne fait que normaliser.

## 4. Le bloc, le masque et l'ordre

Le [`TransformerBlock`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs#L190-L287) d'IX est un bloc pré-normalisé. Chaque sous-couche lit une copie normalisée de son entrée et ajoute son résultat à l'entrée non normalisée :

h = x + Attention(LN₁(x)),   sortie = h + FFN(LN₂(h))

L'attention est multi-têtes : les requêtes, les clés et les valeurs sont projetées par w_q, w_k et w_v, découpées en têtes de d_model / n_heads colonnes chacune, traitées séparément, remises côte à côte et projetées par w_o. Le réseau feed-forward, FFN, est formé de deux couches linéaires séparées par une [GELU](https://arxiv.org/abs/1606.08415), appliquées à chaque jeton isolément. Le transformeur d'origine normalisait après chaque addition résiduelle. Normaliser avant, comme ici, garde de la sortie à l'entrée un chemin qu'aucune normalisation ne remet à l'échelle, ce qui, montrent [Xiong et al.](https://arxiv.org/abs/2002.04745), stabilise l'apprentissage sans phase d'échauffement du pas d'apprentissage.

**Le masque causal.** Un modèle qui prédit le jeton suivant ne doit pas voir les jetons qui viennent après. [`causal_mask`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L37-L43) ajoute −10⁹ à chaque score au-dessus de la diagonale. Une fois que le softmax a retranché le maximum de la ligne, l'exponentielle d'environ −10⁹ est inférieure au plus petit double positif : ces poids valent exactement 0, et un poids de exactement 0 ajoute exactement 0 à la sortie. L'attention est le seul endroit où un bloc mélange les jetons, donc les lignes qui précèdent un changement ne peuvent pas bouger du tout (P2) :

```text
== The causal mask
  block with d_model 8, 2 heads, d_ff 16; 2 sequences of 5 tokens; tokens 3 and 4 redrawn
  largest change in output rows 0 to 2: 0, exactly
  largest change in output rows 3 and 4: 1.777
```

**L'ordre.** Sans masque, rien dans le bloc ne dépend de la place d'un jeton : les projections, les normalisations et le FFN traitent chaque jeton de la même façon, et l'attention fait une somme pondérée sur tous. Réordonner l'entrée réordonne la sortie de la même manière (P9). Un encodage de position rompt cette symétrie. L'[encodage sinusoïdal](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/positional.rs#L20-L34) de Vaswani et al. ajoute un vecteur fixe à chaque position, avant le bloc :

```text
== Order
  tokens reordered 3, 0, 4, 1, 2, no positional encoding: largest difference < 1e-12
  the same with a sinusoidal encoding added to the input: 1.894
```

## 5. Le backward, et le pas qu'il fait

Les couches d'IX n'ont pas de ruban : chacune écrit son backward à la main. [`attention_backward`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L94-L161) renvoie les gradients de Q, K et V, et ils concordent avec les différences centrées de la leçon 12 (P3) :

```text
== IX's attention backward against central differences
  Q, K, V of shape (2, 4, 3), L = sum c * output, eps 1e-5: worst error over 72 components below 1e-7: true
```

Les couches au-dessus font plus que renvoyer des gradients : `multi_head_attention_backward`, `FeedForward::backward`, `LayerNorm::backward` et `TransformerBlock::backward` prennent chacune un pas d'apprentissage et mettent à jour leurs propres poids. Le cours mesure ce qu'elles appliquent. Il appelle chaque backward avec un pas de 1, si bien que la modification d'un poids est le pas lui-même, et la compare au gradient de la même perte par différences centrées : modification = r × gradient (P4 et P5) :

```text
== What backward applies at learning rate 1, batch 2, seq 5 (batch x seq = 10)
  change / central-difference gradient, by least squares
  multi_head_attention_backward, d_model 8, 2 heads:
    w_q          0.1000   within 1e-6 of 0.1: true
    w_k          0.1000   within 1e-6 of 0.1: true
    w_v          0.1000   within 1e-6 of 0.1: true
    w_o          0.1000   within 1e-6 of 0.1: true
    input gradient within 1e-6 of central differences: true
  TransformerBlock::backward, d_model 8, 2 heads, d_ff 16, parameters in the order it updates them:
    ffn.w2       0.1000   within 1e-6 of 0.1: true
    ffn.b2       0.1000   within 1e-6 of 0.1: true
    ffn.w1       0.1000   within 1e-6 of 0.1: true
    ffn.b1       0.1000   within 1e-6 of 0.1: true
    norm2.gamma  1.0000   within 1e-6 of 1.0: true
    norm2.beta   1.0000   within 1e-6 of 1.0: true
    w_o          0.1000   within 1e-6 of 0.1: true
    w_q          0.1000   within 1e-6 of 0.1: true
    w_k          0.1000   within 1e-6 of 0.1: true
    w_v          0.1000   within 1e-6 of 0.1: true
    norm1.gamma  1.0000   within 1e-6 of 1.0: true
    norm1.beta   1.0000   within 1e-6 of 1.0: true
    input gradient within 1e-6 of central differences: true
```

Chaque gradient que calcule IX est juste : les gradients de l'entrée concordent, et chaque modification est exactement proportionnelle à son gradient. Le facteur, lui, n'est pas le même partout. Les projections de l'attention ([`attention.rs` 212, 254-257](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L212)) et les poids du feed-forward ([`transformer.rs` 153-157](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs#L153-L157)) divisent leur gradient par batch × seq avant de faire le pas. Les deux normalisations de couche ne le font pas ([`norm.rs` 104-128](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/norm.rs#L104-L128)). Aucune perte n'a ces pas pour pas de gradient, quel que soit le gradient transmis :

- **La perte est une somme sur les jetons.** Les normalisations font le bon pas, et tous les autres poids un pas batch × seq fois trop petit.
- **La perte est une moyenne.** Le `TransformerClassifier` et le `TransformerRegressor` d'IX transmettent ce gradient : ils divisent par la taille du batch, puis par la longueur de la séquence ([`classifier.rs` 316, 336](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/classifier.rs#L316-L343), et 541, 559 pour le régresseur). Les normalisations ont encore raison, et les autres poids divisent une seconde fois par batch × seq. Avec le batch complet par défaut, 100 exemples de 4 jetons chacun feraient bouger les poids de l'attention et du feed-forward 400 fois moins que la tête du classifieur et ses normalisations, au même pas d'apprentissage. C'est le constat 15 de la leçon 7, trouvé dans `Dense`, répété dans deux couches de plus.

Le commentaire de documentation de `multi_head_attention_backward` annonce aussi qu'elle renvoie le gradient de l'entrée et les quatre matrices mises à jour ([`attention.rs` 177-178](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L177-L178)). Elle ne renvoie que le gradient de l'entrée, et met à jour les matrices par les références `&mut` qu'on lui passe.

## 6. L'initialisation

[Glorot et Bengio](https://proceedings.mlr.press/v9/glorot10a.html) initialisent une couche à fan_in entrées et fan_out sorties dans U(−a, a) avec a = √(6 / (fan_in + fan_out)), de variance a²/3 = 2 / (fan_in + fan_out). [`FeedForward::new`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs#L38-L50) annonce « Xavier init » et calcule cet écart type, √(2 / (fan_in + fan_out)), mais s'en sert ensuite comme borne a. `TransformerBlock::new` fait de même avec √(1/d_model) pour les projections ([`transformer.rs` 235-238](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs#L235-L238)). La dispersion obtenue est √3 fois plus petite que celle de la formule qu'il nomme (P6) :

```text
== Initial spread
  FeedForward::new(64, 256): std of w1 and w2 / sqrt(2/(64 + 256)) = 0.5767
  TransformerBlock::new(64, 4, 256): std of w_q, w_k, w_v, w_o / sqrt(1/64) = 0.5763
  U(-a, a) has std a/sqrt(3) = 0.5774 a; Glorot and Bengio's U(-sqrt(3) s, sqrt(3) s) has std s
```

Dans un bloc pré-normalisé, la dispersion devrait compter moins que dans l'empilement simple de la leçon 7, puisque chaque sous-couche lit une entrée normalisée et que le chemin résiduel porte le signal quels que soient les poids ; cette leçon n'a pas entraîné de bloc pour le mesurer. La couche de sortie du classifieur, elle, est tirée d'une loi normale avec le bon écart type ([`classifier.rs` 180-189](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/classifier.rs#L180-L189)). La loi U(−1, 1) de numpy lui-même, sur un million de tirages, donne 0,5776 pour 1/√3 = 0,5774.

## 7. Deux cas limites

**Des têtes qui ne divisent pas d_model.** L'attention multi-têtes découpe d_model en n_heads têtes de d_model / n_heads colonnes, par division entière et sans vérification ([`attention.rs` 377](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L377)). Avec 10 dimensions et 3 têtes, chaque tête reçoit 3 colonnes et la colonne 9 ne va nulle part (P7) :

```text
== Ten dimensions over three heads
  change when column 9 of w_q, w_k, w_v and row 9 of w_o are redrawn: 0, exactly
  the same for column 8: 1.327
```

Le bloc s'exécute et ne signale aucune erreur. À la même lecture de `multi_head_attention_backward`, les poids de la colonne 9 reçoivent aussi un gradient nul, puisque rien n'écrit cette colonne des gradients des projections ; le cours ne l'a pas mesuré.

**SwiGLU sur une longueur impaire.** [`swiglu`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs#L180-L188) ([Shazeer](https://arxiv.org/abs/2002.05202)) coupe son entrée à len / 2 en une porte et une valeur, et les multiplie. Sur 5 valeurs, la porte en a 2 et la valeur 3 (P8) :

```text
== SwiGLU
  4 values: Value
  5 values: Panic("called `Result::unwrap()` on an `Err` value: ShapeError/IncompatibleShape: incompatible shapes")
```

## 8. Les prédictions, notées

| | Prédiction, écrite avant la première exécution | Mesure | Verdict |
|---|---|---|---|
| P1 | `scaled_dot_product_attention` égale la formule à la main à 10⁻¹² près, et ses lignes somment à 1 | Sous 10⁻¹² pour les deux | Confirmée |
| P2 | Avec le masque causal, tirer à nouveau les jetons 3 et 4 modifie les lignes 0 à 2 de la sortie d'exactement 0 | 0 ; les lignes 3 et 4 changent de 1,777 | Confirmée |
| P3 | `attention_backward` à 10⁻⁷ près des différences centrées à ε = 10⁻⁵ | Sous 10⁻⁷ sur les 72 composantes | Confirmée |
| P4 | `multi_head_attention_backward` fait faire aux projections un pas d'un dixième de leur gradient à batch 2, seq 5, et renvoie le gradient de l'entrée lui-même | 0,1000 pour les quatre ; gradient de l'entrée à 10⁻⁶ près | Confirmée |
| P5 | Dans `TransformerBlock::backward`, les LayerNorm font un pas du gradient entier et tous les autres poids un pas du dixième | 1,0000 pour les quatre paramètres de normalisation, 0,1000 pour les huit autres | Confirmée |
| P6 | La dispersion « Xavier » vaut 1/√3 de celle qu'elle nomme : rapport dans [0,56 ; 0,60] | 0,5767 et 0,5763 | Confirmée |
| P7 | 10 dimensions sur 3 têtes : tirer à nouveau la colonne 9 modifie la sortie d'exactement 0 | 0 ; la colonne 8 la modifie de 1,327 | Confirmée |
| P8 | `swiglu` panique sur 5 valeurs | Elle panique | Confirmée |
| P9 | Sans positions, réordonner les jetons réordonne la sortie à 10⁻¹² près | Sous 10⁻¹² ; 1,894 avec un encodage sinusoïdal | Confirmée |

Les neuf ont tenu à la première exécution, et aucune n'a été ajustée après coup. P4 à P8 ont été écrites à la lecture du code d'IX, pour attraper un écart entre ce qu'il annonce et ce qu'il fait, et chacune en a trouvé un. P2, P7 et P9 ont chacune un témoin qui montre que la vérification peut échouer : les lignes après le changement bougent bien, la colonne 8 compte bien, et un encodage de position rompt bien la symétrie.

## Quoi utiliser dans nos dépôts

- **Les passes avant de l'attention et de la normalisation de couche d'IX :** exactes, et le masque causal l'est aussi. Vérifiez que n_heads divise d_model avant de construire un bloc, car rien d'autre ne le fera.
- **Entraîner avec les méthodes backward d'`ix-nn` :** le pas de chaque poids est son gradient multiplié par le pas d'apprentissage, divisé par batch × seq sauf dans les normalisations de couche. Choisissez le pas d'apprentissage des poids de l'attention et du feed-forward en le sachant, ou mettez à l'échelle le gradient que vous transmettez. Pour entraîner une nouvelle couche, le ruban de la leçon 12 est plus sûr qu'un backward écrit à la main.
- **Avant de se fier à un backward écrit à la main,** mesurez le pas qu'il applique, pas seulement le gradient qu'il renvoie : les gradients d'IX sont tous justes, ses pas ne le sont pas.
- **`swiglu` :** longueurs paires uniquement.

## Exercices

1. Montrez que si les composantes de q et de k sont indépendantes, de moyenne 0 et de variance 1, alors q·k a une moyenne de 0 et une variance de d_k.
2. Après normalisation, la variance du premier jeton s'affiche 0,999996. Sans regarder le jeton, quelle était sa variance avant ?
3. `TransformerClassifier` s'entraîne sur 100 exemples de 4 jetons chacun, en un seul batch. Au pas d'apprentissage η, de combien bouge w_q, comparé à un pas de gradient sur la perte moyenne du classifieur ? Que changeriez-vous dans IX pour qu'un pas d'apprentissage donne une seule taille de pas ?
4. `rope_rotate` ([`positional.rs` 36-66](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/positional.rs#L36-L66), [Su et al.](https://arxiv.org/abs/2104.09864)) fait tourner chaque paire de composantes (2i, 2i + 1) du jeton à la position m de l'angle m·θᵢ. Montrez que le produit scalaire d'une requête tournée à la position m et d'une clé tournée à la position n dépend de m − n, et non de m et n séparément.

<details>
<summary>Solutions</summary>

1. q·k = Σᵢ qᵢkᵢ. Chaque produit a pour moyenne E[qᵢ]E[kᵢ] = 0 et pour variance E[qᵢ²]E[kᵢ²] − 0 = 1. Les d_k produits sont indépendants, donc leurs variances s'additionnent : d_k.
2. La variance après vaut var/(var + 10⁻⁵) = 0,999996, à 5 × 10⁻⁷ près à cause de l'arrondi, donc var = 10⁻⁵ × 0,999996/(1 − 0,999996) ≈ 2,5, quelque part entre 2,2 et 2,9. La variance du jeton était 2,31.
3. Le gradient du classifieur est déjà divisé par les 100 exemples et les 4 positions, et l'attention le divise encore par batch × seq = 400 : w_q bouge de η/400 fois son gradient, là où la tête et les normalisations de couche bougent de η fois le leur. Retirer la division de `multi_head_attention_backward` et de `FeedForward::backward` ferait faire à chaque couche un pas de η fois le gradient de la perte que l'appelant dérive, comme le fait déjà `LayerNorm::backward`.
4. Sur une paire, la rotation d'angle α est la matrice 2 × 2 R(α), et R(α)ᵀR(β) = R(β − α). Donc (R(mθᵢ)q)·(R(nθᵢ)k) = qᵀR(mθᵢ)ᵀR(nθᵢ)k = qᵀR((n − m)θᵢ)k, qui ne dépend que de n − m. Le produit scalaire est la somme de ces termes sur les paires.

</details>

## Sources

- IX au commit épinglé `490c395` : [`attention.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs), [`norm.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/norm.rs), [`transformer.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs), [`positional.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/positional.rs) et [`classifier.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/classifier.rs).
- A. Vaswani et al., [« Attention is all you need »](https://arxiv.org/abs/1706.03762), NeurIPS 2017 : l'attention, la mise à l'échelle, l'attention multi-têtes, l'encodage sinusoïdal.
- J. L. Ba, J. R. Kiros et G. E. Hinton, [« Layer normalization »](https://arxiv.org/abs/1607.06450), 2016.
- R. Xiong et al., [« On layer normalization in the transformer architecture »](https://arxiv.org/abs/2002.04745), ICML 2020 : pré- et post-normalisation.
- X. Glorot et Y. Bengio, [« Understanding the difficulty of training deep feedforward neural networks »](https://proceedings.mlr.press/v9/glorot10a.html), AISTATS 2010 : l'initialisation.
- D. Hendrycks et K. Gimpel, [« Gaussian error linear units (GELUs) »](https://arxiv.org/abs/1606.08415), 2016.
- N. Shazeer, [« GLU variants improve transformer »](https://arxiv.org/abs/2002.05202), 2020 : SwiGLU.
- J. Su et al., [« RoFormer: enhanced transformer with rotary position embedding »](https://arxiv.org/abs/2104.09864), 2021.
