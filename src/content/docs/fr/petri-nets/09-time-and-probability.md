---
title: 9. Temps et probabilités
description: Des taux transforment le graphe d'accessibilité en une chaîne de Markov à temps continu — une file d'attente modélisée en réseau et résolue deux fois, une fois par l'analyseur et une fois par la formule du manuel, puis le débit, la loi de Little, et les transitions immédiates d'un GSPN dont les états évanescents ne contiennent aucun temps.
sidebar:
  order: 9
---

Code complet : [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets). Cette leçon est imprimée par `dotnet run --project Examples -c Release -- l9`, comparée à [`expected/l9.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l9.txt).

Huit leçons de ce cours ont répondu à des questions de la forme *est-ce que cela peut arriver*. Le tampon peut-il déborder, le système peut-il se bloquer, le flux de travail peut-il se terminer. Ce sont les questions auxquelles un test ne répond pas, et elles valent la machinerie.

Ce ne sont pas non plus les questions que l'on pose en premier. Les questions que l'on pose en premier sont *à quelle fréquence* et *combien de temps* : quel débit ceci tient-il, combien de requêtes attendent, quelle proportion est refusée. Les réseaux des leçons 1 à 8 refusent les trois, délibérément — un marquage dit où sont les jetons, et la règle de tir dit quelles transitions *peuvent* tirer, jamais laquelle *va* tirer, ni quand.

Cette leçon ajoute le nombre manquant et garde tout le reste. La structure ne change pas, donc tous les résultats des leçons 3 à 6 tiennent encore ; ce qui change, c'est que chaque transition porte désormais un **taux**, et que le graphe d'accessibilité que vous connaissez devient une **chaîne de Markov à temps continu**.

## Un taux n'est pas un délai

Donnez à chaque transition un délai exponentiel de taux λ : une fois franchissable, elle attend un temps aléatoire de moyenne 1/λ avant de tirer. L'exponentielle n'est pas un choix innocent, et il vaut la peine d'être honnête sur la raison pour laquelle c'est celle qui marche.

C'est la seule loi continue **sans mémoire** : une transition qui a déjà attendu trois secondes est exactement dans l'état où elle était à zéro. C'est ce qui permet à l'avenir de ne dépendre que du marquage — et le marquage seul est toute la raison pour laquelle le graphe d'accessibilité est un objet fini qu'on peut résoudre. Toute autre loi ferait dépendre l'avenir du temps que chaque transition franchissable a déjà passé à attendre, ce qui est une quantité non bornée d'état supplémentaire.

C'est aussi souvent faux. Les temps de service des systèmes réels sont rarement exponentiels ; une lecture disque est plus proche d'une constante, un réessai avec temporisation est délibérément pourvu de mémoire. La section [« Où cela s'arrête »](#où-cela-sarrête) dit quoi faire alors. Le marché est l'habituel : une loi seulement à peu près juste, en échange d'une réponse calculée exactement plutôt qu'échantillonnée.

## La file d'attente, en réseau

Deux places et deux transitions :

```
== A queue with one server and room for 5 ==
net queue-5
places      room jobs
transitions arrive serve
M0          (5, 0) = room:5
arc         room -> arrive
arc         arrive -> jobs
arc         jobs -> serve
arc         serve -> room
reachable markings: 6
```

`room` contient les places libres et `jobs` les travaux en attente ; une arrivée prend une place et fabrique un travail, un service fait l'inverse. C'est le tampon de la [leçon 1](../01-why-petri-nets/) débarrassé du producteur et du consommateur — et la place `room` reste toute la raison pour laquelle rien ne déborde.

Six marquages accessibles, un par longueur de file de 0 à 5. Maintenant les taux :

```
== The same structure, now with a rate on each transition ==
arrive: 3.0000 per unit of time
serve:  4.0000 per unit of time
load:   0.7500
```

Avec une transition d'arrivée, une transition de service et des délais exponentiels, ce réseau **est** une file M/M/1/K — le modèle du manuel, avec des arrivées de Poisson, un serveur exponentiel et une salle d'attente de K. Cela compte pour la section suivante, parce que M/M/1/K est l'un des rares modèles dont la réponse est connue sous forme close.

## Calculé deux fois

L'analyseur construit la chaîne à partir du graphe — le taux de l'état *i* vers l'état *j* est celui de la transition qui les joint — et résout πQ = 0 avec des probabilités qui somment à un. La formule calcule la même distribution à partir de ρ = λ/μ, sans jamais regarder le réseau :

```
== Stationary distribution, computed twice ==
jobs   from the net   from the formula
0      0.3041        0.3041
1      0.2281        0.2281
2      0.1711        0.1711
3      0.1283        0.1283
4      0.0962        0.0962
5      0.0722        0.0722
every state agrees within 1e-12: ok
```

Deux chemins indépendants, six nombres d'accord. C'est la seule raison de faire confiance à l'analyseur sur un réseau dont la réponse n'est *pas* connue sous forme close — c'est-à-dire tous ceux qui vous intéressent vraiment.

:::note[Pourquoi la vérification imprime un verdict et non l'écart]
L'écart entre les deux colonnes vaut 5,6e-17 sur ma machine, et ses chiffres exacts dépendent de l'ordre dans lequel la machine a additionné les flottants. L'imprimer produirait une ligne qui diffère entre Windows, Linux et macOS et ferait échouer la comparaison pour une raison qui n'a rien à voir avec les réseaux de Petri. La vérification imprime donc un verdict par rapport à un seuil. La règle est générale : comparez les nombres avec une tolérance, et n'imprimez que ce que vous acceptez de voir se reproduire à l'identique.
:::

## Ce qu'il vaut la peine de demander à la chaîne

La distribution en elle-même n'est pas la partie intéressante. Celles-ci le sont :

```
== What the chain is worth asking ==
mean jobs in the system:   1.7009
accepted arrivals:         2.7835 per unit of time
completions:               2.7835 per unit of time
arrivals turned away:      0.0722 of the time
server busy:               0.6959 of the time
```

Lisez ces quatre lignes en ingénieur, pas en mathématicien :

- **il s'est présenté 3,0 arrivées mais seulement 2,7835 sont entrées.** Les 0,2165 manquantes, ce sont les 7,22 % du temps où la salle d'attente est pleine. La capacité n'est pas le débit, et le réseau dit de combien elles diffèrent.
- **les fins de service égalent les arrivées acceptées**, jusqu'au dernier chiffre affiché. Rien n'est créé ni détruit ; si ces deux nombres différaient, ce serait le modèle qui aurait tort, pas le système.
- **le serveur est occupé 69,59 % du temps**, pas 75 %. La réponse naïve ρ = 0,75 est le taux d'occupation d'une file à salle d'attente *non bornée*. Perdre des arrivées, c'est aussi perdre du travail.

Ce dernier point est le genre de chose qu'un test de charge vous dit après une semaine de production et qu'un modèle vous dit avant le premier déploiement.

## La loi de Little, gratuitement

Le temps moyen qu'un travail passe dans le système n'est pas quelque chose que la chaîne calcule directement. La [loi de Little](https://en.wikipedia.org/wiki/Little%27s_law) le donne : le nombre moyen dans le système vaut le taux d'arrivée multiplié par le temps moyen qu'on y passe, pour n'importe quel système stable — sans aucune hypothèse sur les lois, l'ordre de service ou l'indépendance.

```
== Little's law, as an independent check ==
mean time in the system:   0.6111
arrivals times that time:  1.7009
mean jobs (above):         1.7009
in and out balance: ok
```

Utilisée dans un sens, c'est une mesure : 1,7009 / 2,7835 = 0,6111 unité de temps par travail. Utilisée dans l'autre, c'est une **vérification du modèle**, et c'est ainsi que la leçon s'en sert — une loi qui vaut pour tout système stable doit valoir ici, donc si ce n'était pas le cas, la chaîne serait fausse.

Vous avez déjà les deux moitiés de cette identité en production : la profondeur de la file sur un tableau de bord et le taux de requêtes. Le troisième nombre suit sans rien instrumenter.

## Le fil du rasoir à charge 1

Rendez le taux d'arrivée égal au taux de service et la file ne se stabilise pas au milieu. Elle ne se stabilise nulle part :

```
== Raising the load to 1 spreads the queue evenly ==
jobs   probability
0      0.1667
1      0.1667
2      0.1667
3      0.1667
4      0.1667
5      0.1667
```

Toutes les longueurs sont également probables. La file est vide un sixième du temps et complètement pleine un sixième du temps, et elle dérive entre les deux sans préférence, parce qu'à ρ = 1 rien ne la rappelle. Un système dimensionné « exactement à la capacité » n'est pas un système qui tourne à sa limite — c'est un système sans aucune tendance, dont la salle d'attente se remplit aussi volontiers qu'elle se vide.

Cette intuition vaut plus que le nombre. C'est aussi la raison pour laquelle la forme close a besoin d'un cas particulier à ρ = 1 : la série géométrique qui donne les autres distributions n'y a pas de somme.

## Un choix qui ne prend aucun temps

Les modèles réels ont des décisions qui ne consomment aucun temps : un routeur qui choisit un serveur, un branchement sur un champ, une limite de réessais atteinte. Leur donner un taux serait un mensonge — il faudrait inventer une durée pour quelque chose d'instantané, et elle apparaîtrait dans la réponse.

Un **réseau de Petri stochastique généralisé** (GSPN) autorise les **transitions immédiates** : elles portent un poids au lieu d'un taux, elles tirent à l'instant où elles deviennent franchissables, et quand plusieurs s'affrontent les poids répartissent le choix. Un travail, deux serveurs, une répartition 70/30 :

```
== A choice that takes no time: immediate transitions ==
net two-servers
places      waiting at-fast at-slow
transitions to-fast to-slow done-fast done-slow
M0          (1, 0, 0) = waiting:1
reachable markings: 3, of which tangible: 2
the job waits (vanishing state): 0.0000 of the time
at the fast server: 0.5385
at the slow server: 0.4615
```

Trois marquages accessibles, mais deux seulement sont **tangibles**. Le troisième — le travail qui attend d'être routé — est **évanescent** : une transition immédiate y est franchissable, donc le réseau le quitte aussitôt et aucun temps n'y passe. Sa probabilité n'est pas petite, elle est exactement nulle, et le solveur le retire avant de résoudre la chaîne plutôt que de le laisser diluer la réponse.

Les deux nombres restants ont une réponse que vous pouvez faire de tête, et c'est pour cela que cet exemple est ici :

```
== The same two numbers by hand ==
at the fast server: 0.5385
at the slow server: 0.4615
```

Sept travaux sur dix vont à un serveur qui prend une demi-unité de temps, trois sur dix à un serveur qui en prend une entière : 0,7 × 0,5 = 0,35 contre 0,3 × 1 = 0,30, normalisés en 0,5385 et 0,4615. Le serveur lent détient 46 % des travaux alors qu'il en reçoit 30 % — la file est là où le temps se passe, pas là où le trafic va.

## Ce que cela coûte

Rien dans cette leçon n'a agrandi l'espace d'états, et tout y a hérité du problème de l'espace d'états. La chaîne a une équation par marquage accessible, donc l'[explosion combinatoire de la leçon 3](../03-the-reachability-graph/) est désormais aussi un problème d'algèbre linéaire : un réseau à un million de marquages demande un million d'inconnues, et l'élimination dense utilisée ici demanderait un million au carré de coefficients.

Les conséquences pratiques :

- **l'analyseur refuse un graphe incomplet.** Si la construction s'est arrêtée à sa limite, les états manquants ne sont pas une erreur d'arrondi — les probabilités seraient normalisées sur le mauvais ensemble et tous les nombres seraient silencieusement faux.
- **il refuse un réseau avec un marquage mort.** Un réseau qui peut s'arrêter n'a pas de distribution stationnaire ; il a un état absorbant qui finit par prendre toute la probabilité. La [leçon 4](../04-properties/) décide le blocage, et cette décision vient d'abord.
- **les vrais outils utilisent des solveurs creux et des méthodes itératives**, parce que la matrice d'une chaîne de Markov est presque vide. Le solveur dense d'ici est honnête sur sa taille : il est fait pour les six états d'une file, pas pour six cent mille.

## Où cela s'arrête

Trois limites, dans l'ordre croissant de la fréquence à laquelle vous les rencontrerez.

**Les délais déterministes cassent la méthode.** Si une transition prend exactement 2 secondes plutôt que 2 en moyenne, l'avenir ne dépend plus du seul marquage, et il n'y a plus de chaîne de Markov à résoudre. Les **réseaux de Petri temporisés** à durées déterministes sont une théorie différente et plus difficile ; les réponses habituelles sont un réseau déterministe et stochastique (DSPN, au plus une transition déterministe franchissable à la fois), une approximation de type phase — plusieurs étapes exponentielles en série, dont la somme varie beaucoup moins qu'une seule exponentielle — ou la simulation.

**Le régime permanent n'est pas toute l'histoire.** Tout ce qui précède décrit le système après un long temps de fonctionnement. Les questions sur la première heure, sur la probabilité de déborder en une journée, sur la distribution d'un transitoire de démarrage, relèvent de l'analyse **transitoire** : la même chaîne, intégrée dans le temps plutôt que résolue à l'équilibre.

**Les moyennes cachent la queue de distribution.** Cette leçon a calculé une longueur de file moyenne et un temps d'attente moyen. Le nombre sur lequel un SLO est écrit est un percentile, et une moyenne dit très peu d'un 99e percentile — deux systèmes de même moyenne peuvent différer d'un ordre de grandeur dans la queue. La distribution sur les états est disponible, donc les questions de queue sur la *longueur de file* ont une réponse ; celles sur le *temps d'attente* demandent la machinerie des temps d'absorption, ou la simulation.

## À retenir

- Un taux ajoute *à quelle fréquence* et *combien de temps* à un modèle qui ne disait que *si*. La structure est intacte, donc les invariants et les résultats de vivacité des leçons précédentes tiennent encore.
- L'exponentielle est choisie parce qu'elle est sans mémoire, et l'absence de mémoire est exactement ce qui permet au marquage d'être tout l'état. C'est une hypothèse de modélisation, pas un fait sur votre système.
- Résolvez le même modèle deux fois par des chemins indépendants chaque fois que l'un d'eux existe. La forme close de la file M/M/1/K vaut plus comme vérification de l'analyseur que comme réponse.
- La loi de Little est gratuite, ne demande aucune hypothèse, et sert aussi de test d'équilibre du modèle.
- Le débit n'est pas la charge offerte, et le taux d'occupation n'est pas ρ, dès que la salle d'attente est finie.
- À charge 1, une file finie ne se tient pas au milieu : toutes les longueurs sont également probables.
- Les transitions immédiates modélisent les décisions qui ne prennent aucun temps. Leurs états sont évanescents, portent une probabilité nulle, et sont éliminés avant la résolution de la chaîne — leur donner un faux taux mettrait une fausse durée dans la réponse.
- La chaîne est aussi grosse que le graphe d'accessibilité. Tout ce qui rendait la leçon 3 coûteuse rend ceci coûteux aussi.

## Exercices

1. La file ci-dessus perd 7,22 % de ses arrivées. Sans rien exécuter, dites ce qui réduit le plus cette perte : doubler la salle d'attente de 5 à 10, ou rendre le serveur 10 % plus rapide. Vérifiez ensuite avec l'analyseur.
2. Ajoutez un second serveur à la file, pour que deux travaux puissent être en service à la fois. Qu'est-ce qui change dans le réseau, et pourquoi la réponse de l'analyseur cesse-t-elle de coïncider avec `QueueFormula` ?
3. L'exemple à deux serveurs met 46 % des travaux sur un serveur qui en reçoit 30 %. Choisissez les poids qui répartissent les travaux de façon que les deux serveurs les détiennent la même fraction du temps.
4. La leçon refuse de résoudre un réseau avec un marquage mort. Dites ce qui sortirait si elle le résolvait quand même, et pourquoi cette réponse serait inutile plutôt que simplement imprécise.

<details>
<summary>Solutions</summary>

**1.** La perte vaut p<sub>K</sub> = p₀ρ<sup>K</sup>, et à ρ = 0,75 chaque place supplémentaire multiplie la perte par 0,75. Cinq places de plus la multiplient par 0,75⁵ ≈ 0,237, donc la perte tombe de 7,22 % à environ 1,8 % — bien plus que de moitié. Rendre le serveur 10 % plus rapide amène ρ à 0,682, et 0,682⁵ contre 0,75⁵ fait une baisse d'environ 40 %, à peu près 4,3 %.

La salle d'attente gagne, et elle gagne parce que la perte décroît géométriquement en la capacité mais seulement polynomialement en le taux. La leçon générale est que lorsque ρ est confortablement sous 1, le tampon est la correction bon marché ; quand ρ approche 1 la décroissance géométrique s'aplatit et le tampon cesse d'aider — à ρ = 1 la section plus haut montrait toutes les longueurs également probables, donc une place de plus n'achète presque rien.

**2.** Ajoutez une place `servers` avec deux jetons, un arc d'elle vers `serve` et un arc de retour. La structure change mais le graphe d'accessibilité ne grossit pas : `servers` est bornée par un invariant de place avec les travaux en service.

La formule cesse de s'appliquer parce que M/M/1/K suppose un seul serveur : avec deux, le taux de service dépend du nombre de travaux présents — il vaut 2μ quand les deux serveurs sont occupés et μ quand un seul l'est. C'est une file M/M/2/K, avec une autre forme close. Le taux d'une transition dans le réseau est une constante, donc modéliser deux serveurs par « une transition, taux doublé » serait faux exactement aux états où cela compte : ceux qui n'ont qu'un seul travail.

C'est le piège habituel avec les taux. Un taux appartient à une transition, pas à un marquage ; si la vitesse dépend du nombre de jetons présents, les jetons doivent être dans le réseau.

**3.** Le temps passé sur un serveur est la part divisée par le taux, donc l'égalité des temps veut dire w<sub>rapide</sub>/2 = w<sub>lent</sub>/1, c'est-à-dire deux fois plus de trafic vers le serveur rapide : des poids 2 et 1, ou n'importe quel multiple. Chacun détient alors exactement 0,5.

Remarquez ce que cela ne dit *pas*. Répartir le trafic proportionnellement à la vitesse égalise le temps passé sur chaque serveur ; cela ne minimise rien en particulier. Tout envoyer au serveur rapide donnerait ici un temps moyen plus faible — les politiques de routage valent la peine d'être modélisées précisément parce que la répartition évidente est rarement la meilleure.

**4.** La chaîne convergerait vers le marquage mort : sa probabilité irait à 1 et celle de tous les autres états à 0. Ce n'est pas une réponse imprécise, c'est la réponse à une autre question — « où ce réseau finit-il » plutôt que « comment ce réseau se comporte-t-il », et la seconde question n'a pas de réponse ici parce que le réseau ne continue pas de tourner. Les nombres seraient parfaitement bien formés et décriraient un système arrêté, ce qui est la raison pour laquelle l'analyseur refuse au lieu de les imprimer. La même distinction mord ailleurs : une longueur de file moyenne calculée sur une période qui inclut une panne n'est pas un nombre plus petit, c'est un nombre qui porte sur un autre système.

</details>

## Sources

- Marsan, Balbo, Conte, Donatelli, Franceschinis, *Modelling with Generalized Stochastic Petri Nets*, Wiley, 1995 — la référence pour les GSPN, les états évanescents et leur élimination. [Librement disponible chez les auteurs](https://www.di.unito.it/~greatspn/GSPN-Wiley/).
- Murata, « Petri Nets: Properties, Analysis and Applications », *Proceedings of the IEEE* 77(4), 1989 — la section sur les extensions temporisées et stochastiques.
- Bolch, Greiner, de Meer, Trivedi, *Queueing Networks and Markov Chains*, 2e édition, Wiley, 2006 — la dérivation de M/M/1/K et les méthodes numériques que les vrais outils emploient à la place de l'élimination dense d'ici.
- La [loi de Little](https://en.wikipedia.org/wiki/Little%27s_law), et la rétrospective de Little lui-même en 2011, *Little's Law as Viewed on Its 50th Anniversary*, *Operations Research* 59(3), sur le peu qu'elle suppose.
- [GreatSPN](https://www.di.unito.it/~greatspn/index.html) et [TimeNET](https://timenet.tu-ilmenau.de/) résolvent ces modèles à une échelle que l'analyseur de ce cours ne vise pas. La leçon 11 y revient.
- L'implémentation que cette leçon imprime : [`Stochastic.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Stochastic.cs), avec la chaîne, l'élimination des états évanescents et la forme close qui lui sert de contrôle.
