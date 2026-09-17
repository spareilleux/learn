---
title: "7. Réseaux de neurones, et les différences finies comme juge"
description: "Une couche affine et la rétropropagation écrites à la main puis vérifiées par différences centrées, ensuite ix_nn — le gradient que Dense applique vraiment, qui est le vrai divisé par la taille du lot, la perte dont le gradient se trompe du nombre de colonnes de sortie, des poids tirés sans graine, et un Sequential de couches Dense qui reste une seule application affine parce que le crate n'a aucune couche d'activation."
sidebar:
  order: 7
---

Chaque modèle jusqu'ici avait une forme choisie d'avance : une droite, une frontière, un arbre. Un **réseau de neurones** n'a presque pas de forme. C'est une pile de deux sortes d'étapes — une application affine `y = xW + b`, et une fonction non linéaire fixe appliquée à chaque nombre — et ce qu'il peut représenter ne dépend que du nombre d'étapes empilées.

La partie qui mérite d'être apprise à la main n'est pas l'empilement. C'est la **rétropropagation** : la règle de dérivation en chaîne appliquée à rebours à travers la pile, qui transforme une perte en un gradient pour chaque poids. C'est aussi la partie facile à se tromper subtilement et difficile à remarquer, d'où l'appui de cette leçon sur le seul outil qui tranche ce genre de débat — les **différences finies**, qui ne savent rien de la règle en chaîne et ne peuvent que mesurer.

| | ML.NET | Tribuo | PyTorch | IX |
|---|---|---|---|---|
| Une couche | — | [`Layer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/interop/tensorflow/package-summary.html) via TensorFlow | `nn.Linear` | `ix_nn::layer::Dense` |
| Une pile | — | — | `nn.Sequential` | `ix_nn::network::Sequential` |
| Activations | — | — | `nn.ReLU`, `nn.Sigmoid`… | aucune n'implémentant `Layer` |
| Pertes | — | — | `nn.MSELoss` | `mse_loss`, `binary_cross_entropy` |
| Gradients automatiques | — | — | autograd | `ix-autograd`, un crate séparé avec son propre ruban |

Le programme est [`examples/l07_networks.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l07_networks.rs), sur les 65 builds de la leçon 2, les deux colonnes centrées-réduites.

## Une couche, et ses trois gradients

Pour `y = xW + b`, la règle en chaîne donne trois choses d'un coup. Notons `g = dL/dy`, le gradient que la couche reçoit d'en haut :

```text
dL/dW = xᵀ g          dL/db = Σ rows of g          dL/dx = g Wᵀ
```

Les deux premiers mettent cette couche à jour ; le troisième est le message passé à la couche en dessous. La version à la main renvoie les trois et n'en applique aucun ([`src/net.rs`, lignes 40-55](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/src/net.rs#L40-L55)) :

```rust
pub fn backward(&self, x: &Array2<f64>, grad_output: &Array2<f64>) -> LinearGrads {
    LinearGrads {
        weights: x.t().dot(grad_output),
        bias: grad_output.sum_axis(Axis(0)),
        input: grad_output.dot(&self.weights.t()),
    }
}
```

Aucune division par la taille du lot n'apparaît, et aucune ne devrait : la moyenne que veut la perte est déjà dans `g`. Si la perte est une moyenne sur `n` lignes, son propre gradient porte le `1/n`.

Le juge est d'accord :

```text
== the hand layer, judged by finite differences
  analytic -0.534895701, numeric -0.534895701, gap 4.35e-11
```

La valeur numérique vient de la différence centrée `(f(w + h) - f(w - h)) / 2h` avec `h = 1e-6`, dont l'erreur est d'ordre `h²`, environ `1e-12`, plus l'arrondi. Un écart de `4e-11` est une réussite. Toute vraie erreur dans `backward` — une transposée manquante, un facteur oublié — se voit comme un écart d'ordre 1, pas d'ordre `1e-11`.

## Le gradient que `Dense` applique vraiment

`ix_nn::layer::Dense` ne renvoie pas ses gradients ; `backward` met lui-même les poids à jour et ne renvoie que le message pour la couche du dessous ([`layer.rs`, lignes 40-52](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/layer.rs#L40-L52)) :

```rust
let grad_weights = input.t().dot(grad_output) / n;
let grad_bias = grad_output.mean_axis(ndarray::Axis(0)).unwrap();
let grad_input = grad_output.dot(&self.weights.t());
self.weights = &self.weights - &(learning_rate * &grad_weights);
```

La question « que soustrait `Dense` ? » peut donc se trancher par l'expérience plutôt que par la lecture : fixer les poids à la main, appeler `backward` avec un taux d'apprentissage de 1, et regarder de combien ils ont bougé. À côté, mesurer le gradient d'`ix_nn::loss::mse_loss` lui-même par différences centrées.

```text
== ix_nn::layer::Dense, one output column
  gradient of mse_loss, measured: -0.534895701
  what backward subtracts:        -0.008229165
  ratio: 65.0000, and the batch has 65 rows
```

Exactement 65 : le nombre de lignes. `grad_output` porte déjà le `1/n` que `mse_gradient` y a mis, et `backward` divise par `n` une seconde fois. La direction est bonne, donc l'entraînement fonctionne encore — mais le taux d'apprentissage que vous passez n'est pas celui que vous obtenez. Sur ces 65 lignes, `learning_rate = 0.1` se comporte comme 0,0015 ; sur un lot de 10 000 il se comporterait comme `1e-5`, et un réseau qui s'entraîne bien sur un petit jeu paraîtrait figé sur un grand. Rien d'autre ne change, puisque chaque `Dense` divise par le même `n`, si bien que les couches restent proportionnées entre elles.

## Une perte et un gradient qui ne s'accordent pas

`mse_loss` moyenne sur chaque case de la matrice, lignes *et* colonnes. `mse_gradient` ne divise que par les lignes ([`loss.rs`, lignes 6-16](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/loss.rs#L6-L16)) :

```rust
pub fn mse_loss(predicted: &Array2<f64>, target: &Array2<f64>) -> f64 {
    let diff = predicted - target;
    diff.mapv(|v| v * v).mean().unwrap()
}

pub fn mse_gradient(predicted: &Array2<f64>, target: &Array2<f64>) -> Array2<f64> {
    let n = predicted.nrows() as f64;
    2.0 * (predicted - target) / n
}
```

Avec une seule colonne de sortie les deux s'accordent. Avec `m` colonnes, `mse_gradient` vaut `m` fois le vrai gradient de `mse_loss`, et les deux effets se composent :

```text
== the same layer with two output columns
  measured gradient [-0.267448, -1.234896]
  backward subtracts [-0.008229, -0.037997]
  ratios [32.5000, 32.5000]
```

32,5 vaut `65 / 2` : divisé par 65 lignes par `Dense`, multiplié par 2 colonnes par `mse_gradient`. L'exercice pousse le rapport jusqu'à quatre colonnes et obtient 1, 2, 3, 4 exactement. Tout réseau d'IX à plus d'une sortie est donc entraîné à un taux d'apprentissage mis à l'échelle par le nombre de sorties, ce qui est le genre de chose qui transforme « on a réglé le taux d'apprentissage » en folklore.

## Des poids que personne ne peut reproduire

`Dense::new` tire ses poids d'une loi normale sans la moindre graine en vue ([`layer.rs`, ligne 27](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/layer.rs#L27)) :

```rust
weights: Array2::random((input_size, output_size), Normal::new(0.0, std).unwrap()),
```

`ndarray_rand::RandomExt::random` tire du générateur du fil d'exécution, donc deux couches construites dans la même exécution diffèrent déjà, et deux exécutions du même programme diffèrent aussi :

```text
== Dense::new(3, 2) twice in the same run
  the two weight matrices are equal: false
  all zero biases: true, weights are public, so a course can overwrite them
```

Tous les autres algorithmes aléatoires d'IX prennent une graine — `KMeans::with_seed`, `RandomForest::with_seed`, `Dropout::new(p, seed)`, `transformer::FeedForward::new(d_model, d_ff, seed)`. `Dense` est l'exception, et la conséquence est qu'aucun résultat de `Sequential` ne peut être reproduit ni testé contre les régressions. La sortie de secours est que `weights` et `bias` sont des champs publics : construire la couche, puis les écraser, ce que cette leçon fait partout.

## Ce qu'une pile de couches `Dense` peut représenter

Deux applications affines à la suite n'en font qu'une : `(xA + a)B + b = x(AB) + (aB + b)`. Un réseau ne devient plus qu'une droite que si quelque chose de non linéaire s'intercale entre ses couches.

`ix-nn` a un trait `Layer` avec `forward` et `backward`, et exactement un type l'implémente : `Dense`. Il n'y a pas de couche `ReLU`, pas de couche `Sigmoid`, rien que `Sequential::push` pourrait accepter entre deux applications affines. (Le crate a bien un GELU — `transformer::gelu` — mais il vit à l'intérieur de `FeedForward`, travaille sur `Array3` et n'est pas un `Layer`.)

Le **ou exclusif** est le plus petit problème qui montre ce que cela coûte. Quatre points, et aucune droite ne sépare les deux classes :

```text
== exclusive or
  hand, two affine layers with a sigmoid between them: loss 0.35722182 -> 0.00000000
  predictions [0.0000, 1.0000, 1.0000, 0.0000]
  ix_nn, two Dense layers and nothing between them: loss 0.34500000 -> 0.25000000
  predictions [0.5000, 0.5000, 0.5000, 0.5000]
  f(0,0) + f(1,1) - f(0,1) - f(1,0) = 0.00e0: the stack is one affine map
```

Le réseau à la main — même taille, même taux d'apprentissage, mêmes 50 000 époques, une sigmoïde entre les couches — le résout exactement. La pile IX converge vers 0,25 et prédit 0,5 partout : 0,25 est la variance des quatre cibles, le mieux qu'une constante puisse faire, et une constante est le mieux qu'une application affine puisse faire ici.

La dernière ligne est la preuve plutôt que le symptôme. Pour toute `f` affine, `f(0,0) + f(1,1) = f(0,1) + f(1,0)`, parce que les deux membres valent `2f` évaluée au même centre. La pile entraînée le satisfait au dernier bit, après 50 000 époques d'entraînement, à toute profondeur. Elle n'est pas sous-entraînée ; elle ne peut pas représenter la fonction.

Rien de tout cela ne rend `ix-nn` fautif — l'attention, la normalisation de couche, RoPE, ALiBi et les blocs transformeurs du même crate sont là où est son vrai travail, et ceux-là ont bien leurs non-linéarités. Mais `Sequential` plus `Dense` est la partie qui ressemble à une API de réseau de neurones pour débutants, et c'est la partie qui ne peut ajuster que des droites.

## À retenir

- La passe arrière d'une couche affine donne trois gradients, `xᵀ g`, la somme des lignes de `g` et `g Wᵀ`. Les différences centrées les vérifient à environ `1e-11` près, et toute vraie erreur apparaît comme un écart de l'ordre de 1.
- `Dense::backward` divise une deuxième fois par la taille du lot : le taux d'apprentissage que tu passes rétrécit avec le nombre de lignes.
- `mse_loss` fait la moyenne sur toutes les cellules mais `mse_gradient` ne divise que par les lignes : avec `m` colonnes de sortie, le gradient vaut `m` fois le vrai.
- `Dense::new` tire ses poids sans graine ; écrase les champs publics `weights` et `bias` pour rendre un résultat reproductible.
- Deux applications affines à la suite n'en font qu'une. Faute de couche d'activation, un `Sequential` de couches `Dense` d'IX prédit 0.5 partout sur le ou exclusif, là où une sigmoïde entre les couches le résout.

## Exercices

1. Choisissez un taux d'apprentissage qui fasse atterrir un pas de `Dense` exactement là où atterrit un pas de la couche à la main.
2. Mesurez `mse_gradient` contre le vrai gradient de `mse_loss` pour une à quatre colonnes de sortie.
3. Quelle largeur faut-il à la couche cachée avant que le réseau à la main résolve le ou exclusif ?

<details>
<summary>Solutions</summary>

Elles sont dans [`examples/l07_exercises.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l07_exercises.rs).

**1.** Multipliez par le nombre de lignes, le facteur mesuré plus haut :

```text
== matching one step of the hand layer with one step of Dense
  hand weight after one step at rate 0.5      0.667447851
  Dense weight after one step at rate 0.5 x 65  0.667447851
  gap 0.00e0
```

Non pas approximativement — bit pour bit, parce que la seule différence entre les deux chemins de code est une multiplication. Le point d'arrivée mérite un second regard : 0,667447851 est la pente des moindres carrés en forme close de la leçon 2. Les deux colonnes étant centrées-réduites, la perte vaut `w² - 2rw + 1`, dont le gradient est `2w - 2r`, si bien qu'un pas de taux 0,5 depuis n'importe quel point de départ atterrit exactement sur `r`. Un pas, aucune itération.

**2.** Le rapport est le nombre de colonnes de sortie :

```text
== ix_nn::loss::mse_gradient divided by the true gradient of mse_loss
  1 column(s): ratio [1.0000], and mse_loss = 0.626042
  2 column(s): ratio [2.0000], and mse_loss = 1.859063
  3 column(s): ratio [3.0000], and mse_loss = 3.758750
  4 column(s): ratio [4.0000], and mse_loss = 6.325104
```

**3.** Deux unités sigmoïdes suffisent, et une ne suffit pas :

```text
== width of the hidden layer against what it can learn (exclusive or)
  hidden 1: final loss 0.166788, corners right 3 of 4
  hidden 2: final loss 0.000000, corners right 4 of 4
  hidden 3: final loss 0.000000, corners right 4 of 4
  hidden 4: final loss 0.000000, corners right 4 of 4
```

Une unité sigmoïde trace une frontière, et le ou exclusif en demande deux ; elle obtient trois coins justes et se stabilise à 0,167, mieux que le 0,25 d'une constante mais sans être une solution. Deux unités tracent deux frontières, et la couche de sortie les combine. C'est le plus petit exemple du résultat général — une seule couche cachée de largeur suffisante peut approcher toute fonction continue — et de sa moitié inutile : le théorème dit qu'une largeur existe, pas laquelle.

</details>

## Sources

- Rumelhart, Hinton et Williams, *[Learning representations by back-propagating errors](https://www.nature.com/articles/323533a0)*, 1986
- Goodfellow, Bengio, Courville, *[Deep Learning](https://www.deeplearningbook.org/)*, chapitre 6, y compris la vérification du gradient par différences finies
- Nielsen, *[Neural Networks and Deep Learning](http://neuralnetworksanddeeplearning.com/chap2.html)*, chapitre 2, pour la rétropropagation pas à pas
- [PyTorch : `torch.autograd.gradcheck`](https://docs.pytorch.org/docs/stable/generated/torch.autograd.gradcheck.html), le même test sous forme de fonction de bibliothèque
- IX en `490c395` : [`ix-nn/src/layer.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/layer.rs), [`ix-nn/src/network.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/network.rs), [`ix-nn/src/loss.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/loss.rs), [`ix-nn/src/transformer.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/transformer.rs)
