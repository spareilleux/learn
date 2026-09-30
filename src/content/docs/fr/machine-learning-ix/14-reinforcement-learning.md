---
title: "14. Apprentissage par renforcement : bandits et Q-learning"
description: "Les bandits, le Q-learning et SARSA face à la crate ix-rl d'IX, avec huit prédictions écrites avant la première exécution : sept tiennent et une tient en partie. Les algorithmes se comportent comme le disent les manuels ; les contrats d'IX se trompent sur le départage des égalités, son trait Agent lit la mauvaise ligne et n'apprend jamais, et son échantillonnage de Thompson suppose des récompenses de variance 1."
sidebar:
  order: 14
---

Jusqu'ici, chaque leçon a appris à partir de données recueillies par quelqu'un d'autre. L'apprentissage par renforcement recueille les siennes : un agent choisit une action, le monde répond par une récompense, et le choix suivant tient compte de ce que les récompenses ont appris. La crate [`ix-rl`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl) d'IX, épinglée, contient les deux familles classiques. Les bandits à plusieurs bras (`EpsilonGreedy`, `UCB1`, `ThompsonSampling`) répètent un même choix. Le Q-learning et SARSA tabulaires agissent sur une `GridWorld`, où chaque choix déplace l'agent vers un autre état. Cette leçon reproduit deux expériences de [Sutton et Barto](http://incompleteideas.net/book/the-book-2nd.html) avec les algorithmes d'IX, mesure le regret face à la borne d'Auer et al., et vérifie ce que promet le [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/CONTRACTS.md) d'IX.

Les huit prédictions que teste cette leçon ont été [écrites dans le journal](../journal/#2026-09-30--leçon-14-prédite-avant-de-mesurer) et commitées avant que son code n'existe. [Les résultats](../journal/#2026-09-30--leçon-14-mesurée) les suivent. Les expériences sont dans [`rl.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/rl.rs), un test par prédiction. [`l14_reinforcement.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l14_reinforcement.rs) affiche ce qu'elles mesurent. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recalcule l'itération sur les valeurs, les bras du banc d'essai et la borne du regret avec [numpy](https://numpy.org/doc/stable/).

## 1. Les bandits, à la main

Un bandit a k bras. Le bras a verse une récompense aléatoire dont l'algorithme ne connaît pas la moyenne μₐ. Tirer à chaque fois le meilleur bras rapporterait μ\* par pas ; chaque tirage du bras a fait perdre à la place Δₐ = μ\* − μₐ. Le regret après T tirages est la somme des Δ des bras tirés. C'est le pseudo-regret : il compte le coût attendu de chaque choix et laisse de côté la chance des récompenses.

L'algorithme estime chaque μₐ par la moyenne des récompenses que le bras a a versées. Il n'a pas besoin de les garder : après la n-ième récompense R,

Qₙ = Qₙ₋₁ + (R − Qₙ₋₁) / n

est la moyenne courante. Les trois bandits d'IX se mettent tous à jour ainsi ([`bandit.rs` 39-43](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/bandit.rs#L39-L43)). Ils ne diffèrent que par leur façon de choisir.

## 2. L'ε-glouton et le banc d'essai à 10 bras

L'ε-glouton tire le bras de plus haute estimation, sauf avec une probabilité ε, où il en tire un uniformément au hasard. Le banc d'essai de Sutton et Barto (section 2.3, figure 2.2) compte 2 000 tâches aléatoires. Chacune a 10 bras dont les moyennes sont tirées de N(0, 1) et les récompenses de N(moyenne, 1), et chacune est jouée pendant 1 000 pas. `testbed` dans `rl.rs` y fait tourner l'`EpsilonGreedy` d'IX. Les tirages normaux sont des sommes de douze uniformes moins six. Comme N(0, 1), ils ont une moyenne de 0 et une variance de 1, et ils ne demandent que de l'arithmétique : Windows, Linux et macOS tirent donc les mêmes nombres. La [leçon 12](../12-autodiff/) a montré ce que le `sin` et le `cos` d'une plateforme font aux chiffres affichés. Chaque ε voit les mêmes tâches et le même bruit (P6) :

```text
== The 10-armed testbed: 2000 tasks, 1000 steps, sample averages
  epsilon   optimal arm, steps 1-100 / 401-500 / 901-1000      average reward, steps 1-100 / 401-500 / 901-1000
  0          33.5 %   35.9 %   35.9 %           0.967   1.038   1.042
  0.01       35.1 %   48.8 %   58.7 %           0.981   1.196   1.309
  0.1        42.1 %   74.7 %   80.0 %           1.016   1.346   1.372
  mean over the tasks of the best arm's mean: 1.538
```

Le glouton (ε = 0) s'arrête sur le premier bras qui paie bien et y reste : il tient le meilleur bras dans environ un tiers des tâches, et cette part bouge à peine après les cent premiers pas (de 33,5 % à 35,9 %). ε = 0,1 trouve le meilleur bras 80 % du temps au pas 1 000. ε = 0,01 monte encore. Ce sont les courbes de la figure 2.2, et les intervalles de P6 ont été fixés d'après elle. La moyenne du meilleur bras vaut 1,538 en moyenne sur les tâches. Le maximum attendu de 10 tirages de N(0, 1) est 1,539, et numpy, à partir des mêmes nombres aléatoires, obtient lui aussi 1,538.

## 3. Les égalités, et un NaN

Un argmax a besoin d'une règle pour les égalités. [`CONTRACTS.md` 8 et 14](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/CONTRACTS.md#L8-L14) disent que `EpsilonGreedy` et `QLearning` les départagent « by FIRST occurrence (lowest index) ». Les deux choisissent avec [`Iterator::max_by`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.max_by), dont la documentation dit l'inverse : « If several elements are equally maximum, the last element is returned. » `UCB1` fait de même (P1) :

```text
== Ties
  new EpsilonGreedy, 10 arms, epsilon 0:       arm 9
  new QLearning, 4 actions, epsilon 0:         action 3
  UCB1, 5 arms, after reward 1 from each:      arm 4
  UCB1, 3 arms, the same:                      arm 2
```

Avant toute récompense, chaque estimation vaut 0 : le premier tirage d'un algorithme glouton est donc le dernier bras, pas le premier. Sur le banc d'essai, c'est sans conséquence, puisque le hasard décide quel bras est le meilleur. Un appelant qui se fie au contrat et place un bras par défaut à l'indice 0, en comptant qu'il gagne les égalités, obtient le dernier à la place. Le test a un témoin : avec un maximum unique à l'indice 0, le même appel renvoie 0.

Le même contrat dit, [ligne 24](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/CONTRACTS.md#L24), que « NaN rewards corrupt `q_values` silently ». La branche gloutonne compare les estimations avec `partial_cmp(...).unwrap()`, et `partial_cmp` n'a pas de réponse pour NaN (P2) :

```text
== A NaN reward on arm 0 of 3, then 100 selections
  epsilon 0: Panic("called `Option::unwrap()` on a `None` value")
  epsilon 1: Value
```

La corruption ne reste silencieuse que tant que chaque tirage explore. Le premier choix glouton panique.

## 4. UCB1, et la croissance du regret

L'ε-glouton explore au même rythme pour toujours. Sur les bras 0,9, 0,8 et 0,7 de récompenses de Bernoulli (1 avec probabilité p, sinon 0), un tirage d'exploration coûte (0 + 0,1 + 0,2)/3 = 0,1 en moyenne : ε = 0,1 paie donc 0,01 par pas, et son regret croît linéairement avec T. UCB1 ([Auer, Cesa-Bianchi et Fischer](https://doi.org/10.1023/A:1013689704352)) remplace le hasard par l'optimisme. Il tire le bras de plus haute valeur de

Qₐ + √(2 ln t / nₐ)

où t est le nombre de tirages jusque-là et nₐ ceux du bras a ([`bandit.rs` 62-81](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/bandit.rs#L62-L81)). Un bras rarement tiré a un gros bonus et finit par être essayé. Auer et al. démontrent que son regret attendu reste sous 8 Σ ln T / Δₐ + (1 + π²/3) Σ Δₐ, une borne qui croît comme ln T. `mean_regret` fait la moyenne du pseudo-regret sur 100 exécutions de 10⁴ pas et 20 de 10⁵ (P7) :

```text
== Regret on Bernoulli arms 0.9, 0.8, 0.7 (pseudo-regret, mean over runs)
        T   runs   epsilon-greedy 0.1     UCB1   Thompson (IX)   Auer et al. bound
    10000    100                113.2    146.3            85.4              1106.5
   100000     20               1016.6    278.6           141.9              1382.8
  regret(1e5) / regret(1e4): epsilon-greedy 8.98, UCB1 1.90, Thompson 1.66
```

Les 1 016,6 de l'ε-glouton à 10⁵ sont proches des 1 000 que coûte son exploration en moyenne, le reste venant d'erreurs gloutonnes. Multiplier T par 10 a multiplié son regret par 8,98, et celui d'UCB1 par 1,90, bien sous la borne. Le rapport d'UCB1 dépasse ln 10⁵ / ln 10⁴ = 1,25. Mon interprétation, non mesurée : à 10⁴ pas, le bonus du meilleur bras lui-même est encore assez grand pour masquer une partie des écarts. Deux résultats n'étaient pas prédits. À 10⁴ pas, l'ε-glouton devance UCB1, et seul l'horizon plus long inverse l'ordre. L'échantillonnage de Thompson d'IX, section suivante, a le plus faible regret aux deux horizons.

## 5. L'échantillonnage de Thompson et l'échelle des récompenses

L'échantillonnage de Thompson ([Thompson, 1933](https://doi.org/10.2307/2332286) ; [Agrawal et Goyal](https://proceedings.mlr.press/v23/agrawal12.html)) tire pour chaque bras une moyenne plausible selon ce qu'il croit, puis tire le bras dont la valeur tirée est la plus haute. Un bras qu'il connaît mal a une croyance large et tire parfois haut. La version d'IX tire chaque bras d'une loi normale de moyenne courante et de variance 1/n, et de variance 1 jusqu'au deuxième tirage ([`bandit.rs` 112, 130-132](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/bandit.rs#L112-L132)). La loi normale vient de [`rand_distr`](https://docs.rs/rand_distr/0.5.1/rand_distr/struct.Normal.html). C'est la croyance sur une moyenne après n récompenses de variance 1 sans a priori, avec N(0, 1) avant le premier tirage. [`CONTRACTS.md` 13](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/CONTRACTS.md#L13) l'appelle « a simplified update ». Ce qu'il ne dit pas, c'est que la variance des récompenses est fixée à 1, quelles qu'elles soient. P8 fait payer les mêmes bras soit 0 ou 1, soit 0 ou 100 :

```text
== IX's Thompson sampling, arms paying 0 or 1 and 0 or 100: 100 runs of 10000 steps
  pay   1: one arm over 99 % of the pulls in 0 runs; most-pulled arm not the best in 0 runs
  pay 100: one arm over 99 % of the pulls in 100 runs; most-pulled arm not the best in 67 runs
```

Avec des gains de 0 ou 1, le modèle est à peu près juste, et l'échantillonnage de Thompson d'IX a battu UCB1 à la section 4. Avec des gains de 0 ou 100, le premier bras qui paie prend une moyenne proche de 100p. Les autres tirent toujours de lois normales de variance au plus 1 autour de 0 : ils ne sont plus jamais tirés. L'exécution se fige sur le bras qui a payé le premier, qui est le meilleur environ 0,9 / (0,9 + 0,8 + 0,7) = 37,5 % du temps. C'est arrivé dans 33 exécutions sur 100. Diviser les récompenses par leur échelle avant `update` l'évite.

## 6. Des états : itération sur les valeurs et Q-learning

Avec des états, une action déplace aussi l'agent, et une bonne action maintenant peut mener plus tard à un mauvais endroit. La valeur de l'action a dans l'état s, suivie du meilleur comportement possible, obéit à l'équation de Bellman :

Q\*(s, a) = r(s, a) + γ maxₐ′ Q\*(s′, a′)

où s′ est l'état où mène a, r la récompense, et γ < 1 escompte les récompenses futures. La [`GridWorld`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/env.rs#L10-L77) d'IX est une grille 5 × 5. Chaque pas coûte −1, atteindre le but (4, 4) depuis le départ (0, 0) rapporte +10, et un pas contre un mur laisse l'agent sur place. `value_iteration` dans `rl.rs` résout l'équation à la main. Elle l'applique à chaque état et chaque action, encore et encore, jusqu'à ce que rien ne change. Le plus court chemin prend 8 pas, sept à −1 puis +10, donc V\*(départ) = 10γ⁷ − (1 − γ⁷)/(1 − γ).

Le Q-learning ([Watkins et Dayan](https://doi.org/10.1007/BF00992698)) ne connaît pas les règles. Il apprend les mêmes valeurs à partir de ses propres déplacements, un par un :

Q(s, a) ← Q(s, a) + α (r + γ maxₐ′ Q(s′, a′) − Q(s, a))

C'est l'`update_index` d'IX ([`q_learning.rs` 61-82](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/q_learning.rs#L61-L82)), et `train_gridworld` enchaîne les épisodes avec des déplacements ε-gloutons (P4) :

```text
== Q-learning on the 5 x 5 GridWorld: learning rate 0.1, gamma 0.99, epsilon 0.1, 2000 episodes
  V*(start) by value iteration: 2.527188; 10 g^7 - (1 - g^7)/(1 - g): 2.527188
  max_a Q(start) after training: 2.527188
  |max_a Q(start) - V*(start)| below 1e-3: true
  largest |Q - Q*| over the 96 state-actions outside the goal: 8.484
  mean reward per episode: episodes 1-100 -4.38, 1901-2000 2.13
  greedy walk, rows from state_index:        8 steps
  greedy walk through Agent::select_action:  no path within 100 steps
```

La valeur du départ concorde avec V\* à six décimales, et la marche gloutonne prend les 8 pas. L'itération sur les valeurs de numpy donne le même 2,527188. La table entière, c'est autre chose : une entrée est encore à 8,484 de Q\*. Le théorème de convergence de Watkins et Dayan exige que chaque état et chaque action soient essayés une infinité de fois. Une action que la politique gloutonne évite n'est mise à jour que lorsque l'exploration la choisit, au plus un quart de ε, soit 2,5 % des visites. Les valeurs le long du chemin convergent, et le reste de la table traîne. La dernière ligne relève de la section 8.

## 7. SARSA, le Q-learning et la falaise

La falaise de Sutton et Barto (exemple 6.6) est une grille 4 × 12. Le départ et le but sont aux deux bouts de la rangée du bas, et la falaise entre eux. Chaque pas coûte −1, et un pas dans la falaise coûte −100 et renvoie l'agent au départ. SARSA diffère du Q-learning par un seul terme :

Q(s, a) ← Q(s, a) + α (r + γ Q(s′, a′) − Q(s, a))

où a′ est l'action qu'il prendra vraiment ensuite, explorations comprises. Le Q-learning apprend les valeurs de la politique gloutonne. SARSA apprend celles de la politique ε-gloutonne qu'il suit, et avec elle, longer le bord veut dire tomber de temps en temps. Le `Sarsa` d'IX a `update_index` et `select_action_index`, mais ni boucle d'entraînement ni constructeur. `cliff_sarsa` écrit la boucle et règle les champs publics. Les deux algorithmes tournent avec γ = 1, un pas de 0,5 et ε = 0,1, sur 50 exécutions de 500 épisodes (P5) :

```text
== The cliff: gamma 1, step 0.5, epsilon 0.1, 50 runs of 500 episodes
  greedy path, Q-learning: 13 steps: 50
  greedy path, SARSA:      no path: 12, 17 steps: 34, 19 steps: 3, 21 steps: 1
  mean online return, episodes 101-500: Q-learning -50.3, SARSA -27.5
  SARSA's walks with no path: stays in one cell, against a wall: 9; cycles through 2 cells: 3
```

Le Q-learning a trouvé le chemin de 13 pas le long du bord dans les 50 exécutions. Pendant l'apprentissage, il obtient −50,3 par épisode, parce que ses pas d'exploration au bord de la falaise y tombent. SARSA obtient −27,5. Son chemin glouton prend 17 pas, la longueur du chemin par la rangée du haut, dans 34 exécutions, et davantage dans 4. La figure de l'exemple 6.6 de Sutton et Barto montre le même ordre. Deux des trois parties de P5 ont tenu.

La troisième non : elle disait que le chemin glouton de SARSA dépasse 13 pas dans au moins 40 exécutions. C'est le cas dans 38. Dans les 12 autres, la marche gloutonne lue dans la table finale de SARSA n'atteint jamais le but. Dans 9, elle reste sur une case en marchant contre un mur, et dans 3, elle fait des allers-retours entre deux cases. La prédiction supposait que la table finale décrit un chemin. Avec un pas constant de 0,5, c'est un instantané d'estimations qui continuent de bouger. Mon explication, non mesurée : une chute d'exploration tire l'estimation d'une case voisine à mi-chemin d'une cible proche de −100, ce qui peut faire paraître meilleur, un temps, de marcher contre un mur. La figure de Sutton et Barto porte sur le retour en ligne, et cette partie a tenu. P5 est marquée réfutée en partie. Son test fige les 38 et 12 mesurés, pour que tout changement se voie.

## 8. Le trait Agent

[`traits.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/traits.rs#L16-L27) définit un trait `Agent<E>` qu'une boucle d'entraînement générique pourrait appeler, et `QLearning` l'implémente pour `GridWorld`. `select_action` calcule la ligne comme r × `q_table.ncols()` + c ([`q_learning.rs` 123](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/q_learning.rs#L123)). Les colonnes de la table Q sont les 4 actions, pas les colonnes de la grille. `update` est vide ([`q_learning.rs` 133-142](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/q_learning.rs#L133-L142)). `rows_read` trouve la ligne que lit chaque état en marquant une ligne à la fois (P3) :

```text
== The Agent trait on GridWorld
  5 x 5: states reading another state's row: 20; rows read twice: [4, 8, 12, 16]; rows never read: [21, 22, 23, 24]
  4 x 4: states reading another state's row: 0; rows read twice: []; rows never read: []
  row read by state (r, c) of the 5 x 5 grid:
    r = 0:  0  1  2  3  4
    r = 1:  4  5  6  7  8
    r = 2:  8  9 10 11 12
    r = 3: 12 13 14 15 16
    r = 4: 16 17 18 19 20
  largest |change| of the table after 1000 transitions, Agent::update: 0, exactly
  the same transitions through update_index:                         0.546
```

Sur une grille large de 4 cases, l'erreur est invisible. Sur la grille 5 × 5, l'état (r, c) lit la ligne de l'état situé r places avant lui dans l'ordre de lecture : chaque état sous la première rangée lit celle d'un autre. La table entraînée à la section 6, lue par le trait, n'atteint pas le but en 100 pas. Une boucle générique écrite pour `Agent` obtiendrait un agent qui lit les mauvais états et n'apprend jamais.

## 9. Les prédictions, notées

| | Prédiction, écrite avant la première exécution | Mesure | Verdict |
|---|---|---|---|
| P1 | Les égalités vont au dernier indice : bras 9 sur 10, action 3 sur 4, bras 4 sur 5 pour UCB1 | 9, 3 et 4 | Confirmée |
| P2 | Après une récompense NaN, un choix glouton panique ; avec ε = 1, 100 choix non | Panique à ε = 0, pas à ε = 1 | Confirmée |
| P3 | Par `Agent`, 20 états sur 25 lisent une autre ligne, les lignes 4, 8, 12, 16 deux fois, les lignes 21–24 jamais ; 4 × 4 tout juste ; `update` ne change rien | Comme prédit ; modification de 0, exactement | Confirmée |
| P4 | Q-learning : max Q(départ) à 10⁻³ près de V\*(départ) = 2,5272, chemin glouton de 8 pas | 2,527188 ; 8 pas | Confirmée |
| P5 | Falaise : Q-learning le long du bord dans ≥ 45 exécutions ; SARSA au-delà de 13 pas dans ≥ 40 ; retour en ligne de SARSA supérieur de ≥ 10 | 50 ; **38** ; 22,8 | **Réfutée en partie** |
| P6 | Banc d'essai, pas 901–1 000 : bras optimal 25–45 % à ε = 0, 70–90 % à ε = 0,1, ε = 0,01 entre les deux ; récompenses dans le même ordre | 35,9 %, 80,0 %, 58,7 % ; 1,042 < 1,309 < 1,372 | Confirmée |
| P7 | Regret de l'ε-glouton à 10⁵ dans [990, 1 200], rapport 10⁵/10⁴ dans [6 ; 10,5] ; rapport d'UCB1 dans [1,3 ; 3], sous la borne d'Auer et al. | 1 016,6 et 8,98 ; 1,90, sous la borne aux deux horizons | Confirmée |
| P8 | Avec des gains de 0 ou 100, Thompson donne à un bras > 99 % des tirages dans chaque exécution, pas le meilleur dans 45–75 ; avec 0 ou 1, le meilleur bras le plus tiré dans ≥ 90 | 100 et 67 ; 100 | Confirmée |

Sept ont tenu à la première exécution. P5 a tenu sur deux de ses trois parties, et aucun intervalle n'a été modifié après coup. P1, P2 et P3 ont été écrites en lisant le code et les contrats d'IX, pour attraper un écart entre ce qu'ils disent et ce que fait le code, et chacune en a trouvé un. P6 et P5 ont été fixées d'après les figures de Sutton et Barto, et P4, P7 et P8 par le calcul. Des témoins montrent que chaque vérification peut échouer : un maximum unique gagne bien, une récompense ordinaire ne panique pas, `update_index` modifie bien la table, une table non entraînée ne trouve pas de chemin, et des gains de 0 ou 1 ne figent rien.

## Quoi utiliser pour nos dépôts

- **`EpsilonGreedy` et `UCB1` d'IX :** ils font ce que disent les manuels. Les égalités vont au dernier indice, quoi qu'en dise `CONTRACTS.md` : placez en dernier le bras qui doit gagner les égalités, ou départagez-les avant l'appel. Vérifiez qu'une récompense n'est pas NaN avant `update`.
- **`ThompsonSampling` d'IX :** seulement pour des récompenses de variance proche de 1. Sinon, remettez-les à l'échelle, ou il risque de se figer sur le premier bras qui paie.
- **Horizons longs :** UCB1 ou l'échantillonnage de Thompson. Avec un ε fixe, le regret de l'ε-glouton continue de croître linéairement.
- **`QLearning` d'IX :** `select_action_index`, `update_index` et `train_gridworld` sont justes. N'utilisez pas son implémentation d'`Agent`.
- **SARSA avec IX :** écrivez la boucle vous-même, jugez-le sur son retour en ligne, et vérifiez qu'un chemin glouton lu dans sa table atteint le but avant de vous en servir.

## Exercices

1. Montrez que la mise à jour Qₙ = Qₙ₋₁ + (Rₙ − Qₙ₋₁)/n, à partir de n'importe quel Q₀, donne la moyenne de R₁, …, Rₙ.
2. L'ε-glouton à ε = 0,1 sur les bras 0,9, 0,8 et 0,7 : que coûte l'exploration par pas, et quel regret attendez-vous après 10⁶ pas ?
3. Avec des récompenses de 0 ou 100, pourquoi le premier tirage du `ThompsonSampling` d'IX est-il uniforme sur les bras, et pourquoi le reste-t-il après un échec ? Pourquoi 37,5 % n'est-il qu'une approximation de la probabilité de se figer sur le meilleur bras ?
4. De quoi `Agent::select_action` de `QLearning` aurait-il besoin pour lire la bonne ligne, et pourquoi ne peut-il pas le calculer à partir de ses arguments ?

<details>
<summary>Solutions</summary>

1. La première mise à jour donne Q₁ = Q₀ + (R₁ − Q₀)/1 = R₁, quel que soit Q₀. Ensuite, par récurrence, si Qₙ₋₁ = (R₁ + … + Rₙ₋₁)/(n − 1), alors Qₙ = Qₙ₋₁(1 − 1/n) + Rₙ/n = ((n − 1)Qₙ₋₁ + Rₙ)/n = (R₁ + … + Rₙ)/n.
2. Un tirage d'exploration choisit chaque bras avec probabilité 1/3 : il coûte (0 + 0,1 + 0,2)/3 = 0,1 en moyenne, et ε = 0,1 des tirages explorent, soit 0,01 par pas. Après 10⁶ pas, environ 10 000, plus quelques dizaines d'erreurs gloutonnes ; P7 a mesuré 1 016,6 après 10⁵.
3. Avant tout tirage, chaque bras tire de N(0, 1) : chacun a la même chance de tirer le plus haut. Après un échec, un bras a n = 1 et sa variance reste 1 (IX ne la met à jour que pour n > 1), avec une moyenne de 0 : il tire toujours de N(0, 1). Le premier bras qui paie se fige alors, avec une probabilité proportionnelle à son p tant que chaque tirage est uniforme. Après un deuxième échec sur le même bras, sa variance tombe à 1/2 et il gagne le tirage moins souvent. Il faut pour cela deux échecs de suite avant tout succès : c'est rare, pas impossible.
4. Il lui faudrait la largeur de la grille : la ligne de (r, c) est r × largeur + c. Le trait ne passe que l'état (r, c), et la table Q connaît le nombre d'états et d'actions, pas la forme de la grille : 25 états peuvent être 5 × 5 ou 1 × 25. L'agent devrait retenir la largeur quand on le construit pour une grille, ou le trait devrait recevoir l'environnement.

</details>

## Sources

- IX au commit épinglé `490c395` : [`bandit.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/bandit.rs), [`q_learning.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/q_learning.rs), [`env.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/env.rs), [`traits.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/traits.rs) et [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/CONTRACTS.md).
- R. S. Sutton et A. G. Barto, [*Reinforcement Learning: An Introduction*](http://incompleteideas.net/book/the-book-2nd.html), 2e édition, MIT Press, 2018 : chapitre 2 pour les bandits et le banc d'essai, chapitre 6 pour le Q-learning, SARSA et la falaise.
- P. Auer, N. Cesa-Bianchi et P. Fischer, [« Finite-time analysis of the multiarmed bandit problem »](https://doi.org/10.1023/A:1013689704352), Machine Learning 47, 2002 : UCB1 et sa borne.
- C. J. C. H. Watkins et P. Dayan, [« Q-learning »](https://doi.org/10.1007/BF00992698), Machine Learning 8, 1992.
- W. R. Thompson, [« On the likelihood that one unknown probability exceeds another in view of the evidence of two samples »](https://doi.org/10.2307/2332286), Biometrika 25, 1933.
- S. Agrawal et N. Goyal, [« Analysis of Thompson sampling for the multi-armed bandit problem »](https://proceedings.mlr.press/v23/agrawal12.html), COLT 2012.
- La bibliothèque standard de Rust, [`Iterator::max_by`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.max_by).
