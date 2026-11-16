---
title: "12. Différentiation automatique : le ruban de Wengert"
description: "Modes direct et inverse écrits à la main, puis le ruban d'ix-autograd d'IX vérifié face aux formes closes, aux différences centrées et à numpy, avec huit prédictions écrites avant la première exécution : les huit ont tenu. Ses gradients concordent avec les formes closes à moins de 10⁻¹², son backward de FFT est juste, et l'exemple d'entraînement d'IX lui-même annonce PASS sur des paramètres que ses données ne permettent pas d'identifier."
sidebar:
  order: 12
---

Les leçons 2, 7 et 8 ont entraîné des modèles avec des gradients dérivés à la main, et la leçon 7 en a trouvé un de faux : le `Dense::backward` d'IX divise deux fois par la taille du lot (constat 15). La différentiation automatique calcule le gradient à partir du programme qui calcule la perte, si bien qu'il n'y a plus rien à dériver. La crate épinglée [`ix-autograd`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd) d'IX le fait avec un ruban de Wengert. Cette leçon écrit à la main les deux modes de la différentiation automatique, lit le ruban d'IX et le vérifie de trois façons : face aux formes closes, face aux différences centrées et face à numpy.

Les huit prédictions que teste cette leçon ont été [écrites dans le journal](../journal/#2026-09-29--leçon-12-prédite-avant-de-mesurer) et commitées avant qu'aucune ligne de son code n'existe. [Les résultats](../journal/#2026-09-30--leçon-12-mesurée) les suivent. Les expériences sont dans [`autodiff.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/autodiff.rs), avec un test par prédiction. [`l12_autodiff.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l12_autodiff.rs) affiche ce qu'elles mesurent. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recalcule avec numpy la régression linéaire, son conditionnement et le gradient de la FFT.

| Méthode | Ce qu'elle donne | Coût pour n entrées et une sortie | Erreur |
|---|---|---|---|
| Symbolique | Une formule de la dérivée | Des expressions qui peuvent devenir bien plus grosses que f | Exacte |
| Différences centrées | (f(x + εeᵢ) − f(x − εeᵢ)) / 2ε | 2n évaluations de f | Troncature et arrondi |
| Mode direct | La dérivée par rapport à une entrée par passe | n passes | Arrondi seulement |
| Mode inverse | Les dérivées par rapport à toutes les entrées | Une passe avant et un parcours arrière | Arrondi seulement |

## 1. Mode direct et mode inverse, à la main

La différentiation automatique découpe un programme en opérations élémentaires, chacune de dérivée connue, et leur applique la règle de dérivation des fonctions composées. La liste de ces opérations, une valeur intermédiaire par ligne, est une liste de Wengert. [Baydin et al.](https://jmlr.org/papers/v18/17-468.html) prennent f(x₁, x₂) = ln(x₁) + x₁x₂ − sin(x₂) en (2, 5) comme exemple suivi : v₁ = ln x₁, v₂ = x₁x₂, v₃ = sin x₂, v₄ = v₁ + v₂, et f = v₄ − v₃.

**Le mode direct** transporte une dérivée à côté de chaque valeur. Un nombre dual v + dε, avec ε² = 0, le fait avec une arithmétique ordinaire : (a + bε)(c + dε) = ac + (ad + bc)ε, donc la partie en ε du résultat est la règle du produit. On part de d = 1 sur x₁ et d = 0 sur x₂, on exécute f, et la partie en ε du résultat vaut ∂f/∂x₁. Obtenir ∂f/∂x₂ demande une seconde passe, graines inversées. `Dual` dans `autodiff.rs` implémente l'addition, la soustraction, la multiplication, `ln` et `sin`.

**Le mode inverse** enregistre d'abord la liste, puis la parcourt à l'envers. Il tient un adjoint v̄ᵢ = ∂f/∂vᵢ par entrée, part de f̄ = 1, et chaque entrée ajoute son adjoint, multiplié par sa dérivée locale, aux adjoints de ses opérandes. Un seul parcours donne la dérivée par rapport à chaque entrée. `Tape` dans `autodiff.rs` le fait pour des scalaires :

```text
== f(x1, x2) = ln(x1) + x1*x2 - sin(x2) at (2, 5)
  forward mode, one pass per input:  f = 11.6521, df/dx1 = 5.5000, df/dx2 = 1.7163
  reverse mode, one backward walk:   f = 11.6521, df/dx1 = 5.5000, df/dx2 = 1.7163
  entry 0: Input      value   2.0000   adjoint  5.5000
  entry 1: Input      value   5.0000   adjoint  1.7163
  entry 2: Ln(0)      value   0.6931   adjoint  1.0000
  entry 3: Mul(0, 1)  value  10.0000   adjoint  1.0000
  entry 4: Sin(1)     value  -0.9589   adjoint -1.0000
  entry 5: Add(2, 3)  value  10.6931   adjoint  1.0000
  entry 6: Sub(5, 4)  value  11.6521   adjoint  1.0000
```

L'entrée 4 reçoit l'adjoint −1 de la soustraction. L'entrée 1, x₂, recueille deux contributions : 1 × x₁ = 2 par le produit, et −1 × cos 5 = −0,2837 par le sinus, soit 1,7163 en tout. Ce sont les valeurs de Baydin et al. : 11,652, 5,5 et 1,716.

Une perte d'entraînement a une sortie et beaucoup d'entrées : c'est le cas pour lequel le mode inverse est fait. Il donne les n dérivées partielles pour un petit multiple constant du coût de f, quel que soit n : c'est le principe du gradient bon marché de Griewank et Walther. Le mode direct demanderait n passes, et les différences centrées 2n évaluations.

## 2. Le ruban d'IX

Dans `ix-autograd`, un `DiffContext` contient un `Tape`, un vecteur de `TapeNode`. Chaque opération calcule sa valeur avec [ndarray](https://docs.rs/ndarray/0.17.2/ndarray/struct.ArrayBase.html), empile un nœud qui garde son nom, les poignées de ses entrées et sa valeur, et renvoie la poignée du nouveau nœud. [`DiffContext::backward`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/ops.rs#L382-L454) parcourt les indices de la sortie jusqu'à 0 et aiguille selon le nom de l'opération. Cet ordre de parcours est valable parce que le ruban ne fait que s'allonger : les entrées d'une opération ont toujours des indices plus petits qu'elle. Les gradients s'accumulent dans une table qui associe un tableau à chaque poignée, avec `+=`, donc une poignée utilisée deux fois recueille les deux contributions.

Les nœuds contiennent des tenseurs entiers, si bien que `LinearRegressionTool::build_graph` en enregistre dix, là où le ruban scalaire ci-dessus demande 265 entrées pour la même perte. Les données sont celles de l'exemple d'entraînement d'IX lui-même, [`minimize_linreg_mse`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/examples/minimize_linreg_mse.rs), reconstruites ligne à ligne : 20 lignes et 3 variables. Les formes closes, avec r = ŷ − y, sont ∂L/∂w = (2/n)xᵀr, ∂L/∂b = (2/n)Σr et ∂L/∂x = (2/n)r wᵀ :

```text
== IX's tape for the linear regression of `minimize_linreg_mse` (20 rows, 3 features)
  10 nodes: input, input, input, input, matmul, add, sub, mul, sum, div_scalar
  ops::variance adds 6: sum, div_scalar, sub, mul, sum, div_scalar
  w = 0, b = 0: loss 0.724417, dL/dw [-0.959694, 0.656138, -0.961510], dL/db -0.032640
    largest difference from the closed forms: w < 1e-12, b < 1e-12, x < 1e-12
    hand-written scalar tape, 265 entries: loss < 1e-12, w < 1e-12, b < 1e-12
  random w, b : loss 0.312636, dL/dw [-0.439221, 0.390372, -0.475970], dL/db -0.662593
    largest difference from the closed forms: w < 1e-12, b < 1e-12, x < 1e-12
    hand-written scalar tape, 265 entries: loss < 1e-12, w < 1e-12, b < 1e-12
```

Le biais b a la forme [1, 1] et `add` le diffuse sur les 20 lignes. Son backward somme le gradient reçu sur l'axe de diffusion, ce que fait `unbroadcast`, donc ∂L/∂b est une somme sur les lignes. Le nœud `mul(residual, residual)` cite deux fois la même poignée, et la table additionne les deux contributions : 2r, comme dans le ruban écrit à la main. Chaque gradient concorde avec sa forme close à moins de 10⁻¹², en w = 0 comme en un point aléatoire (P1, P2).

Les opérations disponibles sont `add`, `sub`, `mul`, `sum`, `matmul`, `div_scalar`, `mean` et `variance`, plus `rfft_magnitude` derrière une feature. Il n'y a encore ni `exp`, ni `log`, ni `tanh`, ni ReLU. À ce commit, le ruban peut entraîner un modèle linéaire sur une erreur quadratique, mais ni une régression logistique ni un réseau avec une non-linéarité.

## 3. Ce que le ruban ne vérifie pas

`Tensor` porte un drapeau `requires_grad`, et sa doc demande aux données cibles de le mettre à false ([`tensor.rs` 28-32](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/tensor.rs#L28-L32)). Aucune opération ni le parcours arrière ne le lit, donc le parcours calcule un gradient pour chaque feuille sur le chemin de la perte (constat 29) :

```text
== What the tape does not check
  y has requires_grad = false, and backward returned a gradient for it; largest difference from -(2/n)r: < 1e-12
  x, also built with requires_grad = false, gets one too: true
  add on [2, 3] and [3, 2]: Panic("called `Result::unwrap()` on an `Err` value: ShapeError/IncompatibleShape: incompatible shapes")
  sub on [2, 3] and [3, 2]: Panic("called `Result::unwrap()` on an `Err` value: ShapeError/IncompatibleShape: incompatible shapes")
  mul on [2, 3] and [3, 2]: Panic("called `Result::unwrap()` on an `Err` value: ShapeError/IncompatibleShape: incompatible shapes")
```

`LinearRegressionTool::backward` écarte le gradient de y à la main, et son commentaire précise que le parcours en calcule un quand même. Un appelant qui utilise directement les opérations les reçoit tous, y compris le gradient 20 × 3 de x, que personne n'entraîne. Dans [PyTorch](https://docs.pytorch.org/docs/stable/notes/autograd.html), le calcul arrière n'est jamais effectué dans les sous-graphes où aucun tenseur ne demande de gradient.

`add`, `sub` et `mul` renvoient un `Result`, et le commentaire d'`add` dit que ndarray « errors if incompatible » ([`ops.rs` 78](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/ops.rs#L78)). Le `&a + &b` de ndarray 0.17 panique au contraire quand les formes ne se diffusent pas, donc ces opérations ne renvoient jamais `ShapeMismatch` (constat 30). Un pipeline ne peut pas intercepter l'erreur par le `Result`. `MseLossTool` l'évite en comparant lui-même les formes avant de construire son graphe ([`mse_loss.rs` 86-92](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/tools/mse_loss.rs#L86-L92)).

## 4. Vérifier un gradient par différences centrées

Une différence centrée (f(x + εe) − f(x − εe))/2ε commet deux erreurs. La troncature, qui vient de la série de Taylor, vaut environ f‴ε²/6. L'arrondi vaut environ u|f|/ε, où u = 1,1 × 10⁻¹⁶ : chaque évaluation de f se trompe de quelques unités sur son dernier chiffre, et la division par ε l'amplifie. Le total est minimal près de ε = (3u|f|/|f‴|)^(1/3), soit environ 10⁻⁵ quand f et f‴ sont de l'ordre de 1 ([Nocedal et Wright](https://doi.org/10.1007/978-0-387-40065-5), section 8.1).

Une quadratique a f‴ = 0, donc il ne reste que l'arrondi (P5). La seconde perte, L = Σ c_k |Y_k| où Y est la FFT d'un signal de 64 échantillons et les c_k des poids aléatoires, a les deux erreurs (P6) :

```text
== Central differences against the tape
  mean squared error at w = 0 (quadratic in w), worst of the 3 components of dL/dw:
    eps 1e-1: < 1e-12
    eps 1e-2: < 1e-12
    eps 1e-3: < 1e-12
    eps 1e-4: < 1e-12
    eps 1e-5: < 1e-12
    eps 1e-6: 6e-11
    eps 1e-7: 8e-10
    eps 1e-8: 2e-8
    eps 1e-9: 7e-8
    eps 1e-10: 6e-7
    eps 1e-11: 7e-6
    eps 1e-12: 6e-5
  L = sum c_k |FFT(x)_k|, 64 samples, worst of the 64 components of dL/dx:
    eps 1e-1: 5e-3
    eps 1e-2: 5e-5
    eps 1e-3: 5e-7
    eps 1e-4: 6e-9
    eps 1e-5: 4e-9
    eps 1e-6: 1e-8 to 1e-7
    eps 1e-7: 1e-7 to 1e-6
    eps 1e-8: 1e-6 to 1e-5
    eps 1e-9: 1e-5 to 1e-4
    eps 1e-10: 1e-4 to 1e-3
  IX's dL/dx, first four components: [-4.429396, -6.277916, -0.459292, -5.058516]
  smallest at eps 1e-5; eps 1e-1 is 1e6 times that; eps 1e-1 and 1e-10 both at least 100 times: true
```

Sur la quadratique, chaque ε de 10⁻¹ à 10⁻⁵ est exact à 10⁻¹² près, et en dessous l'erreur grandit d'environ un facteur dix par décade : c'est l'arrondi seul. Sur la perte FFT, l'erreur baisse d'un facteur cent par décade jusqu'à 10⁻⁴, le ε² de la troncature, et remonte d'un facteur dix par décade sous 10⁻⁵, le 1/ε de l'arrondi. Un ε plus petit n'est pas plus sûr. Les différences centrées de l'erreur quadratique moyenne utilisent une copie de la perte écrite en boucles simples dans un ordre fixe, si bien que le bruit d'arrondi du tableau est le même sur tous les systèmes. Il n'en va pas de même pour la perte FFT : la FFT d'IX prend un `cos` et un `sin` par étage à la bibliothèque mathématique de la plateforme, et à droite du minimum le tableau montre leurs derniers bits. Au premier run de CI, Linux et macOS ont affiché 4e-6, 7e-5 et 4e-4 pour les trois dernières lignes, là où Windows affichait 6e-6, 5e-5 et 5e-4 ([journal](../journal/#2026-09-30--leçon-12-mesurée)). De ce côté, le tableau n'affiche donc que la décade, et les deux conditions de P6 en une seule vérification.

Le vérificateur d'IX lui-même, [`tests/finite_diff.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/tests/finite_diff.rs), prend ε = 10⁻⁶ et teste chaque opération sous `sum`, qui pèse toutes les sorties de la même façon. Un poids aléatoire par sortie, comme les c_k ici, vérifie en plus que le gradient de chaque sortie atteint les bonnes entrées.

## 5. Le backward de la FFT

`rfft_magnitude` renvoie |Y| où Y = FFT(x). Son backward découle de ∂|Y_k|/∂Y_k = Y_k/|Y_k| : le gradient reçu g devient un gradient complexe g_k Y_k/|Y_k| sur le spectre, et la FFT est linéaire, donc ce gradient repasse par une FFT inverse : ∂L/∂x = N · Re(ifft(g ⊙ Y/|Y|)). La doc du module prévient que `ix_signal::fft::rfft` renvoie les N fréquences, et non les N/2 + 1 du [`rfft`](https://numpy.org/doc/stable/reference/routines.fft.html) de numpy, donc aucun repliement hermitien n'est nécessaire ([`ops_fft.rs` 5-15](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/ops_fft.rs#L5-L15)). Dans un demi-spectre, les fréquences 1 à N/2 − 1 valent chacune pour deux, k et N − k, et un backward qui le traverse doit les compter deux fois, sauf la composante continue et la fréquence de Nyquist : c'est le repliement dont parle la doc du module.

La crate garde cette opération derrière la feature `fft-autograd`, désactivée par défaut, « until cross-checked against JAX rfft grad ». Ici, elle est vérifiée face aux différences centrées sur 20 signaux, chacun avec ses propres poids (P7) :

```text
== IX's FFT-magnitude backward (feature fft-autograd)
  20 signals of 64 samples, each with its own weights, eps 1e-5: worst error over 1280 components below 1e-7: true
```

Le pire écart est de 8·10⁻⁹ sous Windows et de 9·10⁻⁹ sous Linux et macOS, encore l'arrondi, si bien que la ligne affiche une borne. La FFT de numpy, par la même formule, donne les mêmes quatre premières composantes, −4,429396, −6,277916, −0,459292 et −5,058516, et concorde avec les différences centrées de numpy à moins de 10⁻⁶. C'est une vérification face aux différences finies et à numpy, pas la comparaison avec JAX que demande la crate. Une fréquence dont la magnitude est inférieure à 10⁻¹⁵ reçoit un gradient nul, un choix valable là où |·| fait un coude ; cette leçon n'a pas testé de signal ayant une telle fréquence.

## 6. L'exemple d'IX, rejoué

`minimize_linreg_mse` construit 20 lignes de 3 variables à partir d'un hachage de l'indice, pose y = x · [0,5 ; −0,3 ; 0,8] + 0,1 + bruit, et entraîne w et b avec [Adam](https://arxiv.org/abs/1412.6980) pendant 200 pas. `ix_example_adam` dans `autodiff.rs` le rejoue ligne à ligne. L'exemple lui-même, compilé depuis le commit épinglé dans un crate de travail, affiche les mêmes nombres : perte 0,010101 au pas 30, sous 0,01 pour la première fois au pas 31, w final [0,64994 ; −0,30000 ; 0,65006], b 0,09832, et « R7 Day 3 go/no-go: PASS ».

```text
== IX's `minimize_linreg_mse`, replayed
  k in the noise -0.01 + k*0.02/32767, rows 0 to 19: 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 2 2 2
  x[i, 2] - x[i, 0] over the 20 rows: min 0.055422, max 0.055483
  least squares: w [0.499818, -0.300000, 0.800182], b 0.089990, w0 + w2 = 1.300000, mean squared error < 1e-12
  Adam step   1: loss 7.24e-1
  Adam step  10: loss 4.97e-2
  Adam step  20: loss 4.70e-2
  Adam step  30: loss 1.01e-2
  Adam step  40: loss 4.38e-3
  Adam step  50: loss 1.26e-3
  Adam step  60: loss 9.15e-4
  Adam step  70: loss 4.99e-5
  Adam step  80: loss 1.38e-4
  Adam step  90: loss 1.07e-5
  Adam step 100: loss 9.91e-6
  Adam step 110: loss 5.94e-6
  Adam step 120: loss 2.67e-7
  Adam step 130: loss 4.22e-7
  Adam step 140: loss 2.88e-7
  Adam step 150: loss 3.74e-8
  Adam step 160: loss 5.52e-9
  Adam step 170: loss 9.65e-9
  Adam step 180: loss 4.55e-9
  Adam step 190: loss 6.52e-10
  Adam step 200: loss 2.35e-11
  after 200 steps: w [0.649940, -0.300002, 0.650065], b 0.098315, w0 + w2 = 1.300005, loss 2.35e-11
  loss below 0.01 first at step 31; the example prints 7500 / 31 = 242x as its speedup over a genetic algorithm
```

**Le bruit est une constante.** L'exemple ajoute un « tiny deterministic noise » pour que la perte finale ne soit pas nulle. Pour les lignes 0 à 19, `(i·7919 + 31) >> 16` vaut 0, 1 ou 2, donc le bruit vaut −0,01 plus au plus 1,2 × 10⁻⁶. L'ordonnée à l'origine l'absorbe : les moindres carrés donnent b = 0,089990 et une erreur quadratique moyenne sous 10⁻¹², et Adam atteint 2,35 × 10⁻¹¹ (P8, constat 32).

**Deux des trois variables n'en font qu'une.** Avancer de deux indices fait progresser le hachage de 2 × 1103515245, soit 33 676,6 × 2¹⁶. Après `>> 16` et `& 0x7fff`, la valeur avance de +908 ou +909, et la division par 32 767 suivie du doublement en fait 0,05542 ou 0,05548. Aucune des 20 lignes ne boucle, donc la colonne 2 vaut la colonne 0 plus 0,0554, à un pas de 6 × 10⁻⁵ près. numpy place la plus petite valeur singulière de [x 1] à 8,9 × 10⁻⁵, soit un conditionnement de 51 251. Les données déterminent w₀ + w₂ = 1,3 et b, et la répartition entre w₀ et w₂ seulement à travers ce petit écart.

- **Les moindres carrés** exploitent ce petit écart et tombent près de la vérité, à [0,499818 ; −0,300000 ; 0,800182].
- **Adam** part de zéro, où les deux colonnes donnent à w₀ et w₂ presque le même gradient à chaque pas. Adam règle le pas de chaque coordonnée sur l'historique de son propre gradient, donc les deux font presque les mêmes pas et finissent à 0,650 chacun.

Les deux atteignent une perte proche de 10⁻¹¹. L'exemple affiche le w final à côté du vrai w, à 0,21 l'un de l'autre, puis « PASS » : son critère est la seule perte (constat 31). L'accélération annoncée vaut 7500 divisé par le nombre de pas, où 7500 est le milieu des « ~5000-10000 fitness evaluations » qu'il faudrait « typically » à un algorithme génétique. L'exemple n'en fait jamais tourner (constat 33).

## 7. Les prédictions, notées

| | Prédiction, écrite avant la première exécution | Mesure | Verdict |
|---|---|---|---|
| P1 | La régression linéaire enregistre 10 nœuds, dans un ordre donné ; `variance` en ajoute 6 | 10 et 6, dans cet ordre | Confirmée |
| P2 | Les gradients égalent les formes closes à 10⁻¹² près, en w = 0 et en un point aléatoire ; le ruban écrit à la main concorde | Moins de 10⁻¹² pour w, b et x, aux deux points | Confirmée |
| P3 | y, avec `requires_grad` à false, reçoit quand même un gradient, égal à −(2/n)r | Oui, à moins de 10⁻¹² | Confirmée |
| P4 | `add`, `sub` et `mul` paniquent sur [2, 3] et [3, 2] | Les trois paniquent | Confirmée |
| P5 | Quadratique : erreur d'au plus 10⁻¹² pour ε = 0,1, d'au moins 10⁻⁹ pour ε = 10⁻¹⁰ | Moins de 10⁻¹² ; 6 × 10⁻⁷ | Confirmée |
| P6 | Perte FFT : le meilleur ε est dans [10⁻⁶ ; 10⁻³], et ε = 10⁻¹ et 10⁻¹⁰ sont chacun au moins 100 fois pires | 10⁻⁵ ; 10⁶ et 10⁵ fois pires | Confirmée |
| P7 | Backward de la FFT à 10⁻⁶ près des différences centrées à ε = 10⁻⁵, sur 20 signaux | 8 × 10⁻⁹ | Confirmée |
| P8 | Moindres carrés sur les données de l'exemple : b dans [0,0899 ; 0,0901], erreur quadratique moyenne sous 10⁻¹¹ | 0,089990 ; sous 10⁻¹² | Confirmée |

Les huit prédictions ont tenu dès la première exécution, et aucune n'a été ajustée ensuite. P3, P4 et P8 ont été écrites pour repérer un écart entre la documentation d'IX et son code, trouvé en le lisant d'abord, et toutes trois en ont trouvé un. Les variables colinéaires, le résultat qui compte le plus ici, n'étaient pas prédites : P8 expliquait l'ordonnée à l'origine et n'a pas vu les poids. Le journal les consigne comme exploratoires.

## Quels usages dans nos dépôts ?

- **Le mode inverse** pour une perte scalaire sur beaucoup de paramètres. **Le mode direct**, avec des nombres duaux, pour peu d'entrées, ou pour vérifier une dérivée directionnelle.
- **`ix-autograd` d'IX :** ses gradients sont exacts pour les opérations qu'il a, qui couvrent les modèles linéaires, les erreurs quadratiques, les variances et les magnitudes de FFT. Ne vous fiez pas à `requires_grad`. Vérifiez les formes avant d'appeler `add`, `sub` ou `mul`, puisqu'un désaccord fait paniquer.
- **Un nouveau backward :** vérifiez-le face aux différences centrées avec ε proche de 10⁻⁵, un poids aléatoire par sortie, en un point éloigné des coudes.
- **Avant de lire des paramètres ajustés,** vérifiez que les données les déterminent : le conditionnement de la matrice de conception, ou deux optimiseurs qui devraient concorder. Une perte faible ne dit rien du minimum trouvé.

## Exercices

1. Exécutez le mode direct à la main sur g(x₁, x₂) = x₁x₂ + sin(x₁) en (0, 3) : écrivez la valeur et la partie en ε de chaque intermédiaire, pour les deux passes.
2. Le parcours arrière d'IX visite les nœuds par indice décroissant. Pourquoi aucun nœud n'est-il visité avant un nœud qui l'utilise ? Qu'est-ce qui casserait si une opération pouvait écraser un nœud existant, comme le fait une mise à jour en place ?
3. À ε = 10⁻¹⁰, l'erreur sur la quadratique vaut 6 × 10⁻⁷. Estimez-la à partir du seul arrondi : la perte vaut 0,724, et chaque évaluation se trompe d'environ une unité sur son dernier chiffre.
4. Écrivez la règle backward d'une opération `exp` pour le ruban d'IX : de quoi a-t-elle besoin de la passe avant, et que renvoie-t-elle ?

<details>
<summary>Solutions</summary>

1. Première passe, graine sur x₁ : x₁ = 0 + 1ε, x₂ = 3 + 0ε, x₁x₂ = 0 + 3ε, sin x₁ = 0 + cos(0)ε = 0 + 1ε, g = 0 + 4ε, donc ∂g/∂x₁ = x₂ + cos x₁ = 4. Seconde passe, graine sur x₂ : x₁x₂ = 0 + 0ε, puisque la partie en ε vaut x₁ × 1 = 0, et sin x₁ = 0 + 0ε, donc ∂g/∂x₂ = x₁ = 0.
2. Le ruban ne fait que s'allonger : une opération est empilée après que ses entrées existent, donc chaque nœud qui utilise un nœud donné a un indice plus grand, et un parcours par indice décroissant les atteint tous d'abord. Une opération en place donnerait à un nœud une nouvelle valeur après que d'autres nœuds ont lu l'ancienne. Leurs règles backward liraient alors la mauvaise valeur, et l'ordre des indices ne correspondrait plus à l'ordre d'utilisation.
3. La différence de deux évaluations de 0,724 est fausse d'environ 2 × 0,724 × 1,1 × 10⁻¹⁶ ≈ 1,6 × 10⁻¹⁶. Divisé par 2ε = 2 × 10⁻¹⁰, cela fait environ 8 × 10⁻⁷, proche des 6 × 10⁻⁷ mesurés.
4. La dérivée de eᵃ est eᵃ, c'est-à-dire la sortie de l'opération elle-même, donc la valeur du nœud est tout ce dont le backward a besoin. Il renvoie g ⊙ valeur pour son unique entrée, sans `unbroadcast`, puisque l'opération garde la forme.

</details>

## Sources

- IX au commit épinglé `490c395` : [`ops.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/ops.rs), [`tape.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/tape.rs), [`tensor.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/tensor.rs), [`ops_fft.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/ops_fft.rs), [`linear_regression.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/src/tools/linear_regression.rs), [`minimize_linreg_mse.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/examples/minimize_linreg_mse.rs) et [`finite_diff.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/tests/finite_diff.rs).
- R. E. Wengert, [« A simple automatic derivative evaluation program »](https://doi.org/10.1145/355586.364791), *Communications of the ACM* 7(8), 1964.
- A. G. Baydin, B. A. Pearlmutter, A. A. Radul et J. M. Siskind, [« Automatic differentiation in machine learning: a survey »](https://jmlr.org/papers/v18/17-468.html), *Journal of Machine Learning Research* 18, 2018 : l'exemple suivi, les modes direct et inverse.
- A. Griewank et A. Walther, [*Evaluating Derivatives*](https://doi.org/10.1137/1.9780898717761), 2ᵉ édition, SIAM, 2008 : le ruban et le principe du gradient bon marché.
- J. Nocedal et S. J. Wright, [*Numerical Optimization*](https://doi.org/10.1007/978-0-387-40065-5), 2ᵉ édition, Springer, 2006, section 8.1 : l'erreur des différences finies.
- D. P. Kingma et J. Ba, [« Adam: a method for stochastic optimization »](https://arxiv.org/abs/1412.6980), ICLR 2015.
