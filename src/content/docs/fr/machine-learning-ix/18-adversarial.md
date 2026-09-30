---
title: "18. Exemples adverses, empoisonnement et les défenses"
description: "FGSM, PGD, Carlini–Wagner et les perturbations universelles face à un modèle linéaire fixé, puis la détection par le bruit, la compression des caractéristiques, le rayon certifié et les défenses contre l'empoisonnement d'ix-adversarial, avec huit prédictions écrites avant la première exécution, toutes les huit confirmées. PGD déplace les caractéristiques que le gradient ignore, Carlini–Wagner rend l'entrée intacte sous c‖w‖ = 1, le détecteur donne le même score aux 4 000 entrées, la compression garde la moyenne de la perturbation, le rayon certifié se trompe jusqu'à 4,4·10⁻⁴, et la fonction d'influence ignore les étiquettes."
sidebar:
  order: 18
---

Un exemple adverse est une entrée légèrement modifiée, exprès, pour qu'un modèle se trompe. [Goodfellow et al. (2015)](https://arxiv.org/abs/1412.6572) ont soutenu que de telles entrées découlent de la linéarité elle-même : en grande dimension, beaucoup de petits changements s'additionnent en un grand. L'empoisonnement attaque les données d'entraînement plutôt que l'entrée. Le crate épinglé [`ix-adversarial`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial) d'IX a quatre attaques d'évasion, trois défenses, un rayon certifié et trois outils contre l'empoisonnement. Cette leçon les mesure face à un modèle assez simple pour que chaque nombre vérifié par les tests découle d'une formule.

Les huit prédictions que teste cette leçon ont été [écrites dans le journal](../journal/#2026-09-30--leçon-18-prédite-avant-de-mesurer) et commitées avant que son code n'existe. [Les résultats](../journal/#2026-09-30--leçon-18-mesurée) les suivent. Les expériences sont dans [`adversarial.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/adversarial.rs), un test par prédiction, et [`l18_adversarial.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l18_adversarial.rs) affiche ce qu'elles mesurent. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) reconstruit le jeu de test, le chemin de Carlini–Wagner, la compression, le probit et les deux expériences d'empoisonnement avec numpy et SciPy, et trouve les mêmes nombres.

## 1. Un modèle qu'on peut attaquer sur le papier

Les attaques se mesurent d'habitude contre des réseaux entraînés, où le résultat dépend de l'entraînement. Cette leçon fixe plutôt le modèle. Deux classes y = ±1 vivent en 100 dimensions : x = y·μ + n, où chaque coordonnée de μ vaut 0,2 et n est le bruit normal approché du cours, la somme de douze uniformes moins six. Le classifieur est le classifieur linéaire optimal au sens de Bayes pour ce problème, w = μ sans biais : il prédit le signe de z = w·x. La marge m = y·z d'un point est positive quand le point est bien classé, et sa distance à la frontière vaut m/‖w‖₂. Comme m = ‖μ‖² + y·w·n, elle suit 4 + N(0, 4), et l'exactitude sur les entrées propres vaut Φ(2) ≈ 0,977. Chaque caractéristique porte peu de signal, 0,2 face à un bruit d'écart type 1. Le modèle est exact parce qu'il en additionne 100.

```text
== the model under attack
2000 test points, 1000 per class, in 100 dimensions; w = mu = 0.2 everywhere, |w|_2 = 2.000, |w|_1 = 20.000
clean accuracy 0.9780   (Phi(2) = 0.9772)
```

Les attaques qui suivent ont besoin du gradient d'une perte par rapport à l'entrée. Pour la perte logistique log(1 + e^(−m)), il vaut −y·σ(−m)·w, un multiple positif de −y·w : la direction qui fait baisser la marge le plus vite.

## 2. FGSM : chaque caractéristique déplacée un peu

`fgsm` ajoute ε·sign(g) à l'entrée, où g est le gradient de la perte ([`evasion.rs` 5-10](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs#L5-L10)). Face à un modèle linéaire, sign(g) = −y·sign(w) : chaque coordonnée se déplace de ε contre la classe, et la marge baisse de ε·Σ|wⱼ| = ε‖w‖₁ = 20ε. C'est l'explication linéaire de Goodfellow et al. Le changement de chaque caractéristique est petit à côté de son bruit, et les 100 changements s'additionnent. L'exactitude devient Φ(2 − 10ε). P1 attaque les 2 000 points de test à quatre valeurs de ε :

```text
== P1, FGSM: every margin falls by eps |w|_1 = 20 eps
  eps   accuracy   Phi(2 - 10 eps)   changed class   exactly those with 0 < m < 20 eps   margins within 1e-12
  0.0   0.9780     0.9772               0            yes                                 yes
  0.1   0.8460     0.8413             264            yes                                 yes
  0.2   0.4780     0.5000            1000            yes                                 yes
  0.3   0.1470     0.1587            1662            yes                                 yes
```

Chaque marge a baissé de 20ε à 10⁻¹² près. Les points qui ont changé de classe sont exactement les points bien classés dont la marge était sous 20ε. Les exactitudes sont à moins de 0,022 de Φ(2 − 10ε), dans les intervalles prédits. À ε = 0,2, un changement d'un cinquième du bruit sur chaque caractéristique divise l'exactitude par deux. Cet ε est le plus petit changement ℓ∞ qui atteint la frontière depuis la marge moyenne : m/‖w‖₁ = 4/20.

## 3. PGD et le signe de zéro

`pgd` répète le pas de FGSM : α·sign(g) à partir de x, puis une coupure du changement total à [−ε, ε] ([`evasion.rs` 12-33](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs#L12-L33)), d'après [Madry et al. (2018)](https://arxiv.org/abs/1706.06083). IX part de x lui-même, sans départ aléatoire. Une différence plus petite compte davantage ici. `pgd` prend le signe avec [`f64::signum`](https://doc.rust-lang.org/std/primitive.f64.html#method.signum), qui renvoie 1 pour +0.0 et −1 pour −0.0. `fgsm` envoie 0 sur 0, comme le fait [`sign`](https://numpy.org/doc/stable/reference/generated/numpy.sign.html) de NumPy. Une composante du gradient est exactement nulle partout où la perte ne dépend pas de la caractéristique, et son signe vient alors de l'arithmétique. Ici, 0.0 fois −y·σ(−m) est un zéro du signe de −y. `adversarial_training_augment`, documentée comme « via FGSM », appelle `signum` elle aussi ([`defense.rs` 7-20](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/defense.rs#L7-L20)). P2 donne aux deux fonctions un gradient de zéros, puis attaque un modèle qui ignore la moitié de ses caractéristiques, avec wⱼ = 0 pour les 50 dernières :

```text
== P2, PGD and f64::signum (eps 0.2, alpha 0.05, 10 steps), largest distance from the expected point
  gradient +0.0 everywhere: pgd from x +0.2 0.000, adversarial_training_augment from x +0.2 0.000, fgsm from x 0.000
  gradient -0.0 everywhere: pgd from x -0.2 0.000, adversarial_training_augment from x -0.2 0.000, fgsm from x 0.000
  model with w_j = 0 for the last 50 features, over the 2000 points (fewest, most):
    pgd:  features moved (100, 100), perturbation norm (2.0000, 2.0000), accuracy 0.4865
    fgsm: features moved (50, 50), perturbation norm (1.4142, 1.4142), accuracy 0.4865
  control, the full model: largest distance between pgd's point and fgsm's 0.000
```

Avec un gradient nul, `pgd` et `adversarial_training_augment` déplacent chaque caractéristique de tout ε, dans une direction fixée par le signe de zéro, tandis que `fgsm` ne bouge pas. Face au demi-modèle, `pgd` déplace les 100 caractéristiques et `fgsm` seulement les 50 qui comptent. L'exactitude est la même, 0,4865, parce que le modèle ne voit pas les 50 autres. Mais la perturbation de PGD est √2 fois plus longue, 2,0 contre 1,414, et tout ce qui la mesure, comme un budget ℓ₂ ou un détecteur, voit 50 changements qui ne servent à rien. Le contrôle montre que rien d'autre ne diffère : face au modèle complet, dont le gradient n'a aucun zéro, `pgd` tombe exactement sur le point de `fgsm`.

## 4. Carlini–Wagner sans sa recherche sur c

`cw_attack` minimise ‖δ‖₂ + c·perte(x + δ) par descente de gradient sur δ et renvoie l'itéré de plus petit objectif ([`evasion.rs` 35-71](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs#L35-L71)). Son commentaire de doc dit que la descente se fait dans l'espace tanh, mais le code n'a pas de tanh. [Carlini et Wagner (2017)](https://doi.org/10.1109/SP.2017.49) utilisent ce changement de variables pour garder une image dans sa boîte, minimisent la norme au carré, et cherchent sur c la plus petite perturbation qui réussit. IX laisse c à l'appelant et utilise la norme simple.

Avec la perte charnière max(m, 0), on peut suivre la descente à la main. Le gradient de ‖δ‖₂ est δ/‖δ‖, de longueur 1, et le gradient de la perte vaut y·w tant que le point est de son côté. Le chemin file donc droit le long de −y·w. Son premier pas a pour longueur lr·c‖w‖. Les pas suivants ont pour longueur lr·(c‖w‖ − 1) tant que m > 0, et le chemin recule de lr une fois la frontière passée. Si c‖w‖ < 1, chaque pas après le premier revient vers x, et aucun δ n'a un objectif plus bas que x lui-même (exercice 3). Si c‖w‖ > 1, le chemin atteint la frontière, à distance m/‖w‖, et tourne autour. Le point gardé est celui du cycle de plus petit objectif. Il est au-delà de la frontière avec une probabilité 1/2 à c‖w‖ = 2 et 1/3 à c‖w‖ = 1,5, selon l'endroit où la frontière tombe entre deux pas. P3 fait 2 000 pas à lr = 0,01 sur les points bien classés :

```text
== P3, cw_attack with the hinge loss max(m, 0), lr 0.01, 2000 steps, on the correctly classified points
  c = 0.25 (c|w| = 0.5): 1956 points, 1956 returned unchanged, misclassified 0.0000 (predicted every result x), largest | |delta| - m/|w| | 5.8712
  c = 1.00 (c|w| = 2.0): 1956 points, 1 returned unchanged, misclassified 0.5072 (predicted [0.464, 0.536]), largest | |delta| - m/|w| | 0.0050
  c = 0.75 (c|w| = 1.5): 1956 points, 1 returned unchanged, misclassified 0.3522 (predicted [0.299, 0.367]), largest | |delta| - m/|w| | 0.0033
```

À c = 0,25, les 1 956 résultats sont x lui-même. L'attaque ne trouve rien, et un appelant qui y lit de la robustesse a seulement choisi c trop petit. À c = 1 et 0,75, 0,5072 et 0,3522 des résultats sont au-delà de la frontière. Chaque résultat est à moins de 0,005 de la perturbation minimale, plus près que les 0,02 prédits, parce que l'objectif garde le plus proche des points autour de la frontière. Le seul point rendu intact à c = 1 et 0,75 est le plus proche de la frontière : son premier pas la dépasse déjà de plus que la distance gagnée. Le succès se décide point par point, selon l'endroit où la frontière tombe entre deux pas, pas selon le modèle. C'est la recherche sur c de Carlini et Wagner, avec une vérification que chaque résultat est mal classé, qui rend l'attaque fiable. La fonction d'IX ne fait ni l'une ni l'autre. La vérification croisée suit le même chemin comme une récurrence scalaire avec numpy et trouve les mêmes comptes.

## 5. Les perturbations universelles et JSMA

Une perturbation universelle, d'après [Moosavi-Dezfooli et al. (2017)](https://doi.org/10.1109/CVPR.2017.17), est un seul vecteur v qui trompe le modèle sur la plupart des entrées. Pour chaque entrée que v ne trompe pas encore, ils ajoutent le plus petit changement qui envoie x + v sur la frontière, trouvé par DeepFool, puis projettent v dans une boule de rayon ε. Pour un modèle linéaire, le pas de DeepFool est exact : −m·y·w/‖w‖², de longueur m/‖w‖ ([Moosavi-Dezfooli et al. 2016](https://doi.org/10.1109/CVPR.2016.282)). `universal_perturbation` d'IX ajoute plutôt grad·perte/‖grad‖ ([`evasion.rs` 107-144](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs#L107-L144)), un pas le long de `gradient_fn` aussi long que la perte. Le commentaire de doc ne dit pas si `gradient_fn` est le gradient de la perte ou la direction qui trompe le modèle. P4 lui donne un point bien classé à la fois, avec perte = m, dans les deux directions :

```text
== P4, universal_perturbation on one correctly classified point, one iteration, loss = m
  1956 points, largest relative error of the new margin against
    m(1 - |w|) = -m with the fooling direction -y w:   8.8e-14
    m(1 + |w|) = 3m with the loss's gradient +y w:     1.2e-14
    m'(1 - |w|/4) = m'/2 with w/4, m' = m/4:           9.7e-14
  length of the w/4 perturbation against a quarter of the full one: 0.0e0
```

Avec la direction qui trompe, la marge passe de m à −m. Le pas vaut deux fois celui de DeepFool, parce que la perte m vaut ‖w‖ = 2 fois la distance m/‖w‖. Avec le gradient de la perte, la marge triple, et la perturbation aide le modèle. Diviser w par 4 décrit le même classifieur, mais le pas devient quatre fois plus court et s'arrête à mi-chemin de la frontière. La longueur du pas dépend de l'échelle de la perte, ce que celle d'une perturbation minimale ne devrait pas faire.

`jsma`, l'attaque par saillance de [Papernot et al. (2016)](https://arxiv.org/abs/1511.07528), a un écart du même genre : elle prend un argument `_target` et ne le lit jamais ([`evasion.rs` 73-105](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs#L73-L105)). Une vérification exploratoire, non préenregistrée, confirme qu'elle renvoie le même point pour les deux cibles :

```text
== exploratory
  jsma returns the same point for targets 0 and 1: yes
```

## 6. La détection par le bruit

`detect_adversarial` ajoute un bruit gaussien à l'entrée `n_samples` fois, mesure le changement quadratique moyen de la sortie, et signale l'entrée quand il dépasse un seuil ([`defense.rs` 29-60](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/defense.rs#L29-L60)). Son commentaire donne le raisonnement : « High variance suggests the input sits near a decision boundary — a hallmark of adversarial examples. » Deux détails décident de ce qu'elle mesure. Le bruit vient d'un générateur initialisé avec un `seed` fixe, si bien que chaque entrée reçoit les mêmes vecteurs de bruit. Et pour une sortie linéaire (z, −z), le changement vaut (w·n, −w·n), qui ne dépend pas du tout de x. P5 la lance sur les 2 000 points de test propres et leurs versions FGSM à ε = 0,2, avec les sorties (z, −z), puis avec les probabilités (p, 1 − p) :

```text
== P5, detect_adversarial, sigma 0.1, 50 samples, the 2000 clean points and their FGSM versions at eps 0.2
  outputs (z, -z): score of the first input 0.0353 (expectation 0.04); 4000 of 4000 inputs have it to within 1e-12
  flagged at threshold 0.015: 4000; at 0.09: 0
  control, outputs (p, 1 - p): score nearest the boundary 2.16e-3, farthest 2.25e-12; more than 10 times: yes
```

Les 4 000 entrées ont le même score à 10⁻¹² près. Il vaut 0,0353, un tirage autour de son espérance σ²‖w‖² = 0,04. Quel que soit le seuil, le détecteur signale toutes les entrées ou aucune. Avec des probabilités, le score dépend bien de l'entrée : 2,16·10⁻³ au plus près de la frontière contre 2,25·10⁻¹² au plus loin. À quel point il sépare alors les entrées propres des entrées attaquées n'a pas été mesuré ; le journal le liste à vérifier. La fonction ne renvoie qu'un booléen, si bien que la leçon retrouve chaque score par dichotomie sur le seuil, et un appelant qui veut calibrer le seuil doit faire de même.

## 7. La compression des caractéristiques

`feature_squeezing` borne chaque valeur à [0, 1] et l'arrondit à l'un de L + 1 niveaux, L = 2^bits − 1. Elle est documentée comme « eliminating small adversarial perturbations that fall below the quantization resolution » ([`defense.rs` 62-72](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/defense.rs#L62-L72)). L'arrondi n'élimine pas un changement, il le concentre. Une valeur déplacée de ε s'arrondit autrement quand un seuil (k + ½)/L tombe entre l'ancienne et la nouvelle valeur. Pour des valeurs uniformes, cela arrive avec une probabilité Lε, et la valeur arrondie bouge alors d'un niveau entier, 1/L. Le changement absolu moyen reste ε, et sa moyenne quadratique grandit jusqu'à √(ε/L). P6 compresse 100 000 valeurs uniformes, avant et après un changement de ±ε :

```text
== P6, feature_squeezing of 100000 uniform values moved by +-eps
  3 bits, eps 0.05: changed 0.3510, mean |change| 0.05014, root mean square 0.08463   (formula 0.350, 0.05000, 0.08452)
  5 bits, eps 0.01: changed 0.3094, mean |change| 0.00998, root mean square 0.01794   (formula 0.310, 0.01000, 0.01796)
  0 bits: [NaN, NaN, NaN, NaN]
```

À 3 bits, 35 % des changements de 0,05 survivent, chacun comme un saut de 1/7, et le changement moyen après compression vaut 0,0501, le même qu'avant. [Xu et al. (2018)](https://doi.org/10.14722/ndss.2018.23198) n'utilisent pas la compression pour nettoyer les entrées. Ils comparent les sorties du modèle sur une entrée et sur sa version compressée, et signalent l'entrée quand les deux diffèrent. À 0 bit, L = 0 et chaque sortie vaut 0/0.

## 8. Le rayon certifié

Le lissage aléatoire de [Cohen et al. (2019)](https://arxiv.org/abs/1902.02918) classe x selon la classe la plus probable sous x + N(0, σ²I). Si cette classe a une probabilité d'au moins p_A et toute autre d'au plus p_B, la prédiction ne peut pas changer dans un rayon ℓ₂ de σ/2·(Φ⁻¹(p_A) − Φ⁻¹(p_B)). `certified_radius` calcule cette borne à partir des deux plus grandes valeurs de son entrée, que son commentaire de doc appelle des logits, après les avoir bornées à [10⁻¹⁰, 1 − 10⁻¹⁰] ([`robustness.rs` 111-144](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/robustness.rs#L111-L144)). Son `probit` porte l'étiquette « Beasley-Springer-Moro », mais il utilise les constantes de la formule 26.2.23 d'[Abramowitz et Stegun](https://personal.math.ubc.ca/~cbm/aands/page_933.htm), dont l'erreur est sous 4,5·10⁻⁴ ([`robustness.rs` 146-174](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/robustness.rs#L146-L174)). P7 le compare à σ = 1 au rayon exact. Le cours calcule Φ⁻¹ avec l'AS 241 de [Wichura (1988)](https://doi.org/10.2307/2347330), exact à environ 16 chiffres et testé sur des quantiles connus :

```text
== P7, certified_radius at sigma 1 against the exact radius (AS 241)
  p_A = 0.501 to 0.999, p_B = 1 - p_A: largest error 4.44e-4, at p_A = 0.642
  p_A = 0.9: IX 1.281729, exact 1.281552
  logits (2, -1): 6.3609; logits (3, 1): 0.0000
```

La plus grande erreur vaut 4,44·10⁻⁴, à p_A = 0,642, juste sous la borne de la formule. À p_A = 0,9, le rayon d'IX dépasse le rayon exact de 1,8·10⁻⁴ : peu, mais dans le sens dangereux pour un certificat. Les logits sont le piège le plus grand. Les logits (2, −1) sont bornés à 1 − 10⁻¹⁰ et 10⁻¹⁰ et certifient un rayon de 6,36σ, tandis que les logits (3, 1) sont tous deux bornés à 1 − 10⁻¹⁰ et certifient 0. La fonction a besoin de probabilités. Cohen et al. utilisent une borne de confiance inférieure sur p_A, estimée à partir de tirages du bruit, qu'IX laisse à l'appelant.

## 9. L'empoisonnement

L'empoisonnement modifie les données d'entraînement plutôt que l'entrée, et le crate a trois outils contre lui ([`poisoning.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/poisoning.rs)) :

- `detect_label_flips` signale un point dont l'étiquette contredit la majorité de ses k plus proches voisins (lignes 14-61).
- `spectral_signature_defense`, d'après [Tran et al. (2018)](https://arxiv.org/abs/1811.00636), projette chaque classe sur sa première direction principale et signale les points strictement au-dessus du centile donné des projections de la classe (lignes 105-180).
- `influence_function` cite [Koh et Liang (2017)](https://arxiv.org/abs/1703.04730). Leur influence d'un point d'entraînement sur une prédiction de test passe par le gradient de la perte de ce point, donc par son étiquette. La version d'IX ignore `_train_labels` : chaque score vaut (xᵢ·x_test)·(y_test − x̄·x_test)/(n·λ), où x̄ est la ligne d'entraînement moyenne (lignes 63-103).

P8 inverse 100 des 1 000 étiquettes de deux amas autour de (−2, −2) et (2, 2). Il empoisonne ensuite une classe de 100 points en 10 dimensions avec 5 points décalés de 6 sur une caractéristique :

```text
== P8, poisoning
  1000 points in 2 dimensions, 100 labels flipped: influence_function unchanged bit for bit: yes
  detect_label_flips, k = 5: 99 flipped labels found, 11 other points flagged
  spectral_signature_defense, 90th percentile, 100 points per class in 10 dimensions: flagged per class [9, 9]
  with 5 points shifted by 6 added to class 0: flagged per class [10, 9], shifted points among them 5
```

Les scores d'influence ne changent pas quand 10 % des étiquettes changent : ils ne peuvent donc pas désigner les points d'entraînement qu'une étiquette inversée dessert. Le vote des voisins trouve 99 des 100 étiquettes inversées. Un point inversé n'est manqué que si au moins 3 de ses 5 voisins ont aussi été inversés, ce qui a une probabilité de 0,009. Le vote signale aussi 11 points corrects, sous les 17 prédits. La défense spectrale signale 9 points par classe au 90ᵉ centile, pas les 10 que suggère « les 10 % du haut », parce qu'elle signale les scores strictement au-dessus de celui d'indice ⌊0,9·n⌋. Avec les 5 points décalés dans la classe 0, elle en signale 10 là, et les 5 en font partie. La vérification croisée refait le vote et la défense spectrale avec numpy, avec ses propres vecteurs propres, et trouve les mêmes comptes.

## 10. Une constante de Lipschitz par échantillonnage

`lipschitz_estimate` tire des points au hasard dans un rayon et renvoie le plus grand rapport ‖f(x') − f(x)‖/‖x' − x‖ ([`robustness.rs` 72-109](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/robustness.rs#L72-L109)). L'échantillonnage ne peut donner qu'une borne inférieure. Une seconde vérification exploratoire étire la première des 100 coordonnées d'un facteur 10, une application dont la constante de Lipschitz vaut 10 :

```text
== exploratory
  lipschitz_estimate of x -> (10 x_0, x_1, ..., x_99), constant 10, 200 samples, 20 seeds: lowest 2.617, median 3.021, highest 3.838
```

Les estimations vont de 2,6 à 3,8. Une direction unitaire aléatoire u met en moyenne 1/100 de sa longueur au carré sur la première coordonnée, et le rapport vaut √(1 + 99u₀²), environ 1,4 en moyenne. Le plus grand de 200 tirages atteint environ 3. Pour une application linéaire, la constante est la plus grande valeur singulière. Pour un réseau, l'échantillonnage trouve une borne inférieure, et en 100 dimensions une borne lâche.

## 11. Les prédictions, notées

| | Prédiction, écrite avant la première exécution | Mesuré | Verdict |
|---|---|---|---|
| P1 | Chaque marge plus basse de 20ε à 10⁻¹² près ; exactement les points avec 0 < m < 20ε changent de classe ; exactitude dans [0,967, 0,988], [0,815, 0,867], [0,464, 0,536] et [0,133, 0,185] | 0,9780, 0,8460, 0,4780, 0,1470 ; marges et points comme prédit | Confirmée |
| P2 | Gradient nul : `pgd` et `adversarial_training_augment` en x ± 0,2, `fgsm` en x ; demi-modèle : 100 caractéristiques contre 50, normes 2 et 1,414, même exactitude ; contrôle : `pgd` égale `fgsm` | Comme prédit ; exactitude 0,4865 pour les deux | Confirmée |
| P3 | c = 0,25 : chaque résultat vaut x ; c = 1 : ‖δ‖ à moins de 0,02 de m/‖w‖, mal classés dans [0,464, 0,536] ; c = 0,75 : dans [0,299, 0,367] | 1 956 sur 1 956 ; à moins de 0,005, 0,5072 ; 0,3522 | Confirmée |
| P4 | Nouvelle marge −m avec −y·w, 3m avec +y·w, m'/2 et un quart de la longueur avec w/4, à 10⁻¹² près en relatif | Plus grande erreur relative 9,7·10⁻¹⁴ | Confirmée |
| P5 | Tous les scores égaux à 10⁻¹² près, proches de 0,04 ; tout signalé à 0,015, rien à 0,09 ; avec des probabilités, le plus grand plus de 10 fois le plus petit | 4 000 sur 4 000 à 0,0353 ; 4 000 et 0 ; 2,16·10⁻³ contre 2,25·10⁻¹² | Confirmée |
| P6 | 3 bits, ε = 0,05 : 0,350 ± 0,005 changées, moyenne 0,05 et moyenne quadratique 0,0845 à 2 % près ; 5 bits, ε = 0,01 : 0,310, 0,01, 0,0180 ; 0 bit : NaN | 0,3510, 0,05014, 0,08463 ; 0,3094, 0,00998, 0,01794 ; NaN | Confirmée |
| P7 | Plus grande erreur dans [10⁻⁴, 4,5·10⁻⁴] ; logits (2, −1) environ 6,36 ; (3, 1) 0 | 4,44·10⁻⁴ ; 6,3609 ; 0 | Confirmée |
| P8 | Influence identique bit à bit ; au moins 95 des 100 inversions trouvées, au plus 17 autres ; spectrale 9 et 9, puis 10 dans la classe 0 avec les 5 | Identique ; 99 et 11 ; 9 et 9, puis 10 avec les 5 | Confirmée |

Les huit ont tenu à la première exécution, et le code a compilé du premier coup. Aucun intervalle n'a été changé après coup. Un résultat est plus serré que prédit : les résultats de Carlini–Wagner sont à moins de 0,005 de la perturbation minimale, pas 0,02, parce que l'objectif garde le plus proche des points autour de la frontière. La plupart des prédictions venaient de la lecture d'une fonction face à son commentaire, et la plupart ont trouvé un écart entre les deux. Les contrôles montrent que chaque vérification peut échouer : face au modèle complet PGD égale FGSM, avec des probabilités le score du détecteur dépend de l'entrée, et la défense spectrale trouve bien les points décalés.

## Quoi utiliser dans nos dépôts

- **`fgsm` :** exacte sur un modèle linéaire, où chaque marge baisse de ε‖w‖₁. Une bonne première attaque, et un nombre à publier à côté de l'exactitude sur les entrées propres.
- **`pgd` et `adversarial_training_augment` :** elles déplacent de tout ε chaque caractéristique que la perte ignore, dans une direction fixée par le signe de zéro, et aucune valeur finie du gradient ne l'évite, puisque `signum` ne renvoie jamais 0. Remettez ces caractéristiques en place après l'appel, ou bouclez sur `fgsm` avec une coupure.
- **`cw_attack` :** cherchez vous-même sur c, au-dessus de 1/‖∇perte‖, et vérifiez que chaque résultat est mal classé. À c‖w‖ = 2, la moitié ne l'était pas.
- **`universal_perturbation` :** passez la direction qui trompe, pas le gradient de la perte, et attendez-vous à des pas aussi longs que la perte, pas que la distance à la frontière.
- **`detect_adversarial` :** inutile sur une sortie linéaire. Comme elle ne renvoie qu'un booléen, calibrez son seuil sur des entrées propres par dichotomie.
- **`feature_squeezing` :** comparez les sorties du modèle avec et sans elle, comme Xu et al., plutôt que de compter sur elle pour nettoyer une entrée. Utilisez au moins 1 bit.
- **`certified_radius` :** passez une borne inférieure sur p_A, pas des logits. Son probit peut surestimer le rayon jusqu'à 4,4·10⁻⁴σ.
- **L'empoisonnement :** `detect_label_flips` fonctionne sur des amas séparés, avec 99 des 100 inversions trouvées et 11 fausses alertes. `influence_function` ne lit pas les étiquettes, elle ne peut donc pas trouver celles qui sont inversées. `spectral_signature_defense` signale n − ⌊p·n/100⌋ − 1 points par classe.

## Exercices

1. Montrez que FGSM baisse chaque marge d'un modèle linéaire de ε‖w‖₁, et que sur le modèle de cette leçon l'exactitude devient Φ(2 − 10ε).
2. Pour un modèle linéaire, quelles sont les plus petites perturbations ℓ₂ et ℓ∞ qui amènent un point de marge m sur la frontière ? Évaluez-les à m = 4 pour le w de cette leçon.
3. Montrez que pour l'objectif ‖δ‖₂ + c·max(m(x + δ), 0) d'un modèle linéaire, aucun δ n'a un objectif plus bas que δ = 0 quand c‖w‖ ≤ 1.
4. Pour des valeurs uniformes sur [0, 1] arrondies à L + 1 niveaux, trouvez la probabilité qu'un changement de ±ε ≤ 1/(2L) change la valeur arrondie, et la moyenne quadratique du changement après arrondi.
5. Pourquoi `detect_adversarial` donne-t-elle le même score à chaque entrée pour des sorties (z, −z) ? Qu'est-ce qui changerait si chaque appel tirait un bruit neuf ?

<details>
<summary>Solutions</summary>

1. Le gradient est un multiple positif de −y·w, donc x' = x − ε·y·sign(w) et m' = y·w·x' = m − ε·Σ|wⱼ| = m − ε‖w‖₁. Ici m = ‖μ‖² + y·w·n suit N(4, ‖w‖²) = N(4, 4), donc P(m' > 0) = P(N(4, 4) > 20ε) = Φ((4 − 20ε)/2) = Φ(2 − 10ε).
2. La perturbation ℓ₂ vaut −m·y·w/‖w‖₂², de longueur m/‖w‖₂. La perturbation ℓ∞ déplace chaque coordonnée de m/‖w‖₁ contre la classe. Avec ‖w‖₂ = 2, ‖w‖₁ = 20 et m = 4 : 2 et 0,2. Comme tous les wⱼ sont égaux ici, les deux sont le même vecteur : 0,2 contre la classe sur chaque caractéristique, un cinquième du bruit, de longueur ℓ₂ 2 et de longueur ℓ∞ 0,2.
3. Par Cauchy–Schwarz, m(x + δ) ≥ m − ‖w‖‖δ‖. Si ‖δ‖ < m/‖w‖, l'objectif vaut au moins ‖δ‖ + c(m − ‖w‖‖δ‖) = cm + ‖δ‖(1 − c‖w‖) ≥ cm. Sinon, il vaut au moins ‖δ‖ ≥ m/‖w‖ ≥ cm. Dans les deux cas il vaut au moins cm, l'objectif en δ = 0.
4. Les seuils sont en (k + ½)/L pour k = 0, …, L − 1. Un déplacement de +ε franchit un seuil τ quand x est dans (τ − ε, τ), avec une probabilité ε, et au plus un seuil quand ε ≤ 1/(2L). Il en va de même pour −ε, donc la probabilité vaut Lε. Chaque franchissement déplace la valeur arrondie de 1/L, donc le carré moyen vaut Lε/L² = ε/L et la moyenne quadratique √(ε/L).
5. Le changement de la sortie vaut (w·n, −w·n) pour un bruit n, quel que soit x, et le seed fixe donne à chaque entrée les mêmes bruits. Le score vaut Σₖ 2(w·nₖ)²/(2·50), identique pour toutes les entrées. Avec un bruit neuf, les scores varieraient autour de σ²‖w‖², comme un χ² à 50 degrés de liberté mis à l'échelle, mais ne dépendraient toujours pas de x : du bruit, pas de l'information.

</details>

## Sources

- IX au commit épinglé `490c395` : [`evasion.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs), [`defense.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/defense.rs), [`poisoning.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/poisoning.rs), [`robustness.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/robustness.rs).
- I. J. Goodfellow, J. Shlens et C. Szegedy, [« Explaining and harnessing adversarial examples »](https://arxiv.org/abs/1412.6572), ICLR 2015.
- A. Madry, A. Makelov, L. Schmidt, D. Tsipras et A. Vladu, [« Towards deep learning models resistant to adversarial attacks »](https://arxiv.org/abs/1706.06083), ICLR 2018.
- N. Carlini et D. Wagner, [« Towards evaluating the robustness of neural networks »](https://doi.org/10.1109/SP.2017.49), IEEE Symposium on Security and Privacy, 2017.
- N. Papernot, P. McDaniel, S. Jha, M. Fredrikson, Z. B. Celik et A. Swami, [« The limitations of deep learning in adversarial settings »](https://arxiv.org/abs/1511.07528), IEEE European Symposium on Security and Privacy, 2016.
- S.-M. Moosavi-Dezfooli, A. Fawzi et P. Frossard, [« DeepFool: a simple and accurate method to fool deep neural networks »](https://doi.org/10.1109/CVPR.2016.282), CVPR 2016 ; avec O. Fawzi, [« Universal adversarial perturbations »](https://doi.org/10.1109/CVPR.2017.17), CVPR 2017.
- W. Xu, D. Evans et Y. Qi, [« Feature squeezing: detecting adversarial examples in deep neural networks »](https://doi.org/10.14722/ndss.2018.23198), NDSS 2018.
- J. Cohen, E. Rosenfeld et J. Z. Kolter, [« Certified adversarial robustness via randomized smoothing »](https://arxiv.org/abs/1902.02918), ICML 2019.
- M. Abramowitz et I. A. Stegun, *Handbook of Mathematical Functions*, [formule 26.2.23](https://personal.math.ubc.ca/~cbm/aands/page_933.htm). M. J. Wichura, [« Algorithm AS 241: the percentage points of the normal distribution »](https://doi.org/10.2307/2347330), Applied Statistics 37, 1988.
- P. W. Koh et P. Liang, [« Understanding black-box predictions via influence functions »](https://arxiv.org/abs/1703.04730), ICML 2017.
- B. Tran, J. Li et A. Madry, [« Spectral signatures in backdoor attacks »](https://arxiv.org/abs/1811.00636), NeurIPS 2018.
- Rust : [`f64::signum`](https://doc.rust-lang.org/std/primitive.f64.html#method.signum). NumPy : [`sign`](https://numpy.org/doc/stable/reference/generated/numpy.sign.html).
