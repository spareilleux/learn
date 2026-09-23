---
title: "13. Face aux autres formalismes : TLA+, statecharts, algèbres de processus, automates temporisés"
description: Confier les 25 réseaux du cours à TLC et comparer trois nombres par réseau, puis demander ce que disent les statecharts, les algèbres de processus et les automates temporisés qu'un réseau de Petri ne dit pas.
sidebar:
  order: 13
---

La leçon 11 a confié à l'analyseur des fichiers écrits par un autre outil. La leçon 12 lui a confié des réponses calculées par d'autres gens. Cette leçon pose la question qui est sous les deux : **un réseau de Petri est-il seulement le bon langage ?**

Quatre rivaux couvrent l'essentiel de ce qui sert à décrire la concurrence : [TLA+](https://lamport.azurewebsites.net/tla/tla.html), les statecharts, les algèbres de processus et les automates temporisés. Un seul a un vérificateur qui lit un corpus entier de réseaux sans boîte de dialogue de licence, donc un seul est ici **mesuré**. Les autres sont comparés honnêtement, et signalés comme non exécutés.

## Lancer l'expérience

```bash
dotnet run --project code/petri-nets/Examples -c Release -- l13
```

```bash
# Le recoupement. tla2tools.jar n'est pas embarqué dans le dépôt : téléchargez-le d'abord.
dotnet run --project code/petri-nets/Examples -c Release -- tla out/tla
java -cp tla2tools.jar tlc2.TLC -workers 1 -cleanup out/tla/mutual_exclusion.tla
```

Le générateur est [`Tla.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Examples/Tla.cs), la règle de franchissement qu'il instancie est [`tla/PetriNet.tla`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/tla/PetriNet.tla), et tout le bloc ci-dessous est dans [`expected/l13.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l13.txt), comparé ligne à ligne par `check.sh`.

## Le même réseau, écrit deux fois

Une spécification TLA+ est une formule. Ses variables prennent des valeurs ; un comportement est une suite d'affectations. Un réseau de Petri est un graphe ; ses places portent des jetons, et un marquage est une fonction des places vers les entiers naturels. Ces deux phrases se rencontrent exactement une fois : **faites de l'unique variable une fonction des places vers les naturels, et un état TLA+ *est* un marquage.**

La règle de franchissement est donc écrite une fois, à la main, et jamais générée :

```tla
Enabled(t) == \A p \in Places : marking[p] >= Pre[t][p]

Fire(t) ==
    /\ Enabled(t)
    /\ marking' = [p \in Places |-> marking[p] - Pre[t][p] + Post[t][p]]

Init == marking = M0
Next == \E t \in Transitions : Fire(t)
Spec == Init /\ [][Next]_marking
```

Ce qui est généré n'est que le réseau. `Nets.MutualExclusion()` devient :

```tla
---------------------- MODULE mutual_exclusion ----------------------
EXTENDS Naturals

Places == {"idle1", "critical1", "idle2", "critical2", "mutex"}
Transitions == {"enter1", "leave1", "enter2", "leave2"}

PreArcs == {
    [p |-> "idle1", t |-> "enter1", w |-> 1],
    [p |-> "mutex", t |-> "enter1", w |-> 1],
    [p |-> "critical1", t |-> "leave1", w |-> 1],
    [p |-> "idle2", t |-> "enter2", w |-> 1],
    [p |-> "mutex", t |-> "enter2", w |-> 1],
    [p |-> "critical2", t |-> "leave2", w |-> 1]
}

PostArcs == {
    [p |-> "critical1", t |-> "enter1", w |-> 1],
    [p |-> "idle1", t |-> "leave1", w |-> 1],
    [p |-> "mutex", t |-> "leave1", w |-> 1],
    [p |-> "critical2", t |-> "enter2", w |-> 1],
    [p |-> "idle2", t |-> "leave2", w |-> 1],
    [p |-> "mutex", t |-> "leave2", w |-> 1]
}

M0 == [p \in Places |-> IF p \in {"idle1", "idle2", "mutex"} THEN 1 ELSE 0]
\* Every place is bounded by 1 (Invariants.PlaceBounds), so the constraint truncates nothing.
Cap == 1

VARIABLE marking
INSTANCE PetriNet
=============================================================================
```

Garder la sémantique dans un module écrit à la main et les données dans un module généré, c'est la différence entre une traduction qu'on peut relire et une traduction qu'il faut croire. Le générateur fait une centaine de lignes et n'écrit aucune logique.

## Ce qu'il faut dire au model checker

Une ligne de ce module n'est pas dans le réseau du tout : `Cap == 1`.

TLA+ n'a aucune notion de bornitude. Une spécification est un ensemble de comportements, pas un graphe, et `marking[p]` parcourt tout `Nat`. Donné un réseau non borné, TLC énumère jusqu'à épuiser la mémoire, et ne dit jamais *non borné* — il ne dit rien, aussi longtemps qu'on le laisse faire. Le `.cfg` généré porte donc une contrainte d'état :

```
SPECIFICATION Spec
CONSTRAINT Bounded
INVARIANT TypeOK
CHECK_DEADLOCK FALSE
```

avec `Bounded == \A p \in Places : marking[p] =< Cap`.

D'où vient `Cap` ? De [`Invariants.PlaceBounds`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Invariants.cs) — les invariants de places de la leçon 5. **La théorie structurelle fournit le nombre que le model checker ne sait pas dériver.** Pour 21 des 25 réseaux, les invariants prouvent une borne et la contrainte ne tronque rien :

```
  21 of 25 nets carry a cap the place invariants produced.
  The other 4 have no invariant covering every place, so the generated module caps them at 3:
    unbounded-producer
    handshake
    emit-loop
    handshake-started
```

Un plafond choisi à la main serait un danger silencieux. Mettez celui de `queue-5` à 2 — son marquage initial porte cinq jetons dans `room` — et TLC jette l'état initial avant d'explorer quoi que ce soit :

```
Model checking completed. No error has been found.
1 states generated, 0 distinct states found, 0 states left on queue.
```

Rien n'a été vérifié et le verdict annonce un succès. Aucune ligne de cette sortie ne la distingue d'une exécution complète, et c'est pour cela que le nombre vient des invariants et que la leçon imprime quels réseaux ont reçu un plafond qu'elle n'a pas su prouver.

## Trois nombres pour un espace d'états

TLC termine sur une ligne du genre `5 states generated, 3 distinct states found`, plus une profondeur. Trois nombres. Avant de le lancer sur quoi que ce soit, trois paris :

- **états distincts** = les marquages accessibles de l'analyseur ;
- **états engendrés** = les arcs de l'analyseur, plus un pour l'état initial ;
- **profondeur** = le plus long des plus courts chemins de l'analyseur, plus un, parce que TLC compte les états d'un chemin et l'analyseur les pas.

Vingt-cinq modules, vingt-cinq exécutions de TLC :

| réseau | marquages | distincts | arcs + 1 | engendrés | prof. + 1 | TLC |
|---|---|---|---|---|---|---|
| producer-consumer | 12 | 12 | 21 | 21 | 9 | 9 |
| handshake | 1 | 1 | 1 | 1 | 1 | 1 |
| mutual-exclusion | 3 | 3 | 5 | 5 | 2 | 2 |
| two-locks | 4 | 4 | 7 | 7 | 3 | 3 |
| two-locks-ordered | 3 | 3 | 5 | 5 | 2 | 2 |
| start-once | 3 | 3 | 4 | 4 | 3 | 3 |
| connection | 3 | 3 | 5 | 5 | 3 | 3 |
| readers-writers | 5 | 5 | 9 | 9 | 4 | 4 |
| counting-semaphore | 7 | 7 | 19 | 19 | 3 | 3 |
| philosophers-one-fork-3 | 14 | 14 | 28 | 28 | 4 | 4 |
| philosophers-ordered-3 | 12 | 12 | 23 | 23 | 4 | 4 |
| lane-lock-guarded | 7 | 7 | 15 | 15 | 4 | 4 |
| lane-lock-unguarded | 10 | 10 | 19 | 19 | 5 | 5 |
| pipeline-lifecycle | 8 | 8 | 9 | 9 | 5 | 5 |
| queue-5 | 6 | 6 | 11 | 11 | 6 | 6 |
| two-servers | 3 | 3 | 5 | 5 | 2 | 2 |
| order-sound | 6 | 6 | 8 | 8 | 5 | 5 |
| order-and-xor | 10 | 10 | 14 | 14 | 6 | 6 |
| order-xor-and | 5 | 5 | 5 | 5 | 3 | 3 |
| order-rework | 4 | 4 | 5 | 5 | 4 | 4 |
| retry | 8 | 8 | 10 | 10 | 7 | 7 |
| kanban-1 | 160 | 160 | 617 | 617 | 15 | 15 |

**Vingt-deux réseaux, soixante-six nombres, aucun désaccord.** Les trois réseaux laissés de côté — `unbounded-producer`, `emit-loop`, `handshake-started` — n'ont pas de graphe d'accessibilité fini : TLC explore la troncature que définit le plafond et l'analyseur n'explore rien ; ils sont d'accord là-dessus aussi, ce qui n'est pas la même chose qu'être d'accord.

Les trois colonnes méritent qu'on s'y arrête. *États distincts* et *marquages* coïncident parce qu'un état TLA+ et un marquage ont été rendus identiques exprès. *Engendrés* et *arcs* coïncident pour une autre raison, et un réseau a failli la casser.

## Le pas qui aurait dû disparaître

Dans `order-sound`, deux transitions différentes mènent d'un marquage au même marquage : `ship` et `cancel` sortent toutes deux la commande du même état vers le même suivant. C'est la seule paire de ce genre dans les 25 réseaux.

Le graphe d'accessibilité d'un réseau de Petri est **étiqueté** : ce sont deux arcs, parce que deux choses différentes se sont produites. La relation de transition de TLA+ ne l'est pas : `Next` est une disjonction, et ses successeurs forment un ensemble d'états. `order-sound` aurait donc dû afficher `arcs + 1 = 8` contre `engendrés = 7`.

Il affiche 8 contre 8. TLC compte un état engendré **par disjoint qu'il évalue**, pas par successeur qu'il garde — la collision est comptée deux fois puis dédoublonnée dans `distinct`. Le pari était juste par accident, et l'accident contient toute la différence entre les deux formalismes en une ligne : si vous demandez *ce qui peut arriver ensuite*, TLA+ répond par des états ; si vous demandez *ce qui peut arriver*, un réseau de Petri répond par des transitions. C'est la seconde question dont la leçon 7 avait besoin pour parler de famine.

## Un marquage final n'est pas un interblocage

La première exécution de cette leçon était fausse, et fausse d'une manière qui mérite d'être gardée.

Avec la configuration ci-dessus privée de sa dernière ligne, TLC s'est arrêté après **trois** des huit marquages de `retry`, et après six des huit de `pipeline-lifecycle`. Ce n'était pas un bogue de traduction. TLC appelle **interblocage** un état sans successeur et s'arrête là, parce qu'une spécification TLA+ décrit un système qui continue pour toujours ; le bégaiement est permis, l'arrêt non.

Un réseau de Petri ne fait pas cette hypothèse. Le marquage final d'un réseau de workflow est la raison d'être du réseau — la leçon 10 passe sa longueur à définir la solidité comme le fait d'*atteindre* ce marquage. Un marquage mort est quelque chose que ce cours calcule et rapporte, dans `ReachabilityGraph.DeadStates`, pas quelque chose qui interrompt l'exécution.

`CHECK_DEADLOCK FALSE` n'est donc pas un drapeau de confort. C'est l'endroit où les deux formalismes ne s'accordent pas sur ce qu'*est* un système : un processus réactif, ou une procédure qui a une fin.

## Ce qu'un invariant de places prouve, et ce qu'il ne prouve pas

Quatre réseaux n'ont aucun invariant de places couvrant toutes leurs places, et le premier jet de cette leçon le disait ainsi : *les quatre réseaux que les invariants ne bornent pas sont les quatre sans graphe d'accessibilité fini.*

C'est faux, et le test l'a attrapé. `handshake` n'a pas d'invariant de ce genre et a **exactement un marquage accessible**, parce qu'il est mort dès le départ : son `receive` dépose un jeton dans `served` que rien ne reprend, donc aucun multi-ensemble de places n'est conservé et aucun invariant n'existe — et pourtant rien ne peut croître puisque rien ne peut se franchir.

Un invariant de places est une condition **suffisante** de bornitude et jamais une condition nécessaire. Trois des quatre réseaux plafonnés sont vraiment non bornés. Le quatrième est borné pour une raison que les invariants ne voient pas.

## Ce qu'un réseau dit et qu'une spécification ne dit pas

```
  mutual-exclusion            3 place invariants,  3 minimal siphons,  3 minimal traps
  philosophers-one-fork-3     6 place invariants,  7 minimal siphons,  6 minimal traps
  readers-writers             2 place invariants,  2 minimal siphons,  2 minimal traps
```

Aucun de ces neuf nombres n'a besoin d'un état accessible.

Prenez la propriété pour laquelle `mutual-exclusion` existe : deux fils ne sont jamais en section critique en même temps. En TLA+ on l'écrit comme un invariant et TLC la vérifie :

```tla
AtMostOneInCritical == marking["critical1"] + marking["critical2"] =< 1
```

```
Model checking completed. No error has been found.
5 states generated, 3 distinct states found, 0 states left on queue.
```

TLC l'a vérifiée en visitant les trois états. L'analyseur ne visite aucun état : `critical1 + critical2 + mutex = 1` est un invariant de places, calculé depuis la matrice d'incidence par élimination de Farkas, et la propriété en découle pour **tout** marquage accessible, y compris ceux que personne n'a énumérés. Sur trois états la différence est invisible. Sur `Dekker-PT-020` — 11,5 millions de marquages et 1,216 milliard d'arcs, leçon 12 — l'une des deux méthodes répond encore et l'autre épuise un tas de 8 Gio après 158 secondes.

Voilà le résumé honnête de la comparaison : un model checker décide plus de propriétés, et un réseau décide moins de propriétés sans rien regarder.

:::note[Ce bloc n'est pas produit par check.sh]
Les chiffres de TLC ci-dessus viennent d'une exécution manuelle du 2026-09-22 : `tla2tools.jar` 2.19 depuis les [versions de TLA+](https://github.com/tlaplus/tlaplus) (MIT), OpenJDK 25, un seul worker. Le jar n'est pas embarqué, donc `check.sh` lance `l13` sans lui et le bloc de la leçon s'arrête aux trois colonnes de l'analyseur. Les vingt-cinq modules ont pris 20,1 s au chronomètre, dont l'essentiel en vingt-cinq démarrages de JVM ; la passe de l'analyseur sur les mêmes 25 réseaux, siphons et trappes compris, prend 1,8 s.
:::

## Les statecharts

Les [statecharts](https://doi.org/10.1016/0167-6423(87)90035-9) ajoutent trois choses à une machine à états : la **hiérarchie** (un état contient une machine), l'**orthogonalité** (un état contient plusieurs machines qui tournent ensemble) et la **diffusion** (un événement déclenche toutes les transitions qui l'attendent).

L'orthogonalité est celle qui se traduit proprement. Un état ET à deux régions est un produit de deux machines à états, et un produit de deux machines à états, c'est déjà ce que sont deux places marquées en parallèle ; le nombre d'états se multiplie des deux côtés. `lane-lock-guarded` et `lane-lock-unguarded` ont cette forme.

La hiérarchie, non. Un réseau de Petri n'a pas de contenance : pour sortir d'un état composite on dessine une transition par état interne, et le dessin grossit là où le statechart restait petit. La diffusion non plus — une transition de réseau consomme ce qu'elle consomme, et rien d'autre ne réagit. Un modèle avec un événement « tout arrêter » est un statechart ; exprimé comme réseau, il devient un arc depuis chaque place.

Ce qu'un réseau garde et qu'un statechart abandonne : **les jetons sont un compte de ressources**. Un état de statechart est dedans ou dehors. `counting-semaphore` tient deux jetons dans une place et n'a besoin d'aucune seconde région pour cela ; la même chose en statechart, c'est soit deux régions orthogonales, soit une variable entière hors du formalisme, et ni l'une ni l'autre ne vous laisse d'invariant.

## Les algèbres de processus

En [CCS](https://doi.org/10.1007/3-540-10235-3) ou en [CSP](https://www.cs.cmu.edu/~crary/819-f09/Hoare78.pdf), la composition est la primitive. On écrit deux processus, on les met en parallèle, on restreint les canaux qu'ils partagent, et le comportement est *dérivé* par les règles opérationnelles. Il n'y a pas de graphe tant qu'on n'en développe pas un.

Un réseau de Petri fait l'inverse. La structure est la primitive : places, transitions, arcs, dessinés une fois. La composition n'est pas un opérateur — on fusionne des places, à la main, et `Nets.Philosophers(n)` est une boucle qui construit des arcs.

Ce compromis se voit dans tout ce que fait ce cours. L'analyse structurelle a besoin que la structure existe avant d'exécuter quoi que ce soit : siphons, trappes, invariants et la classification en libre choix de la leçon 6 se lisent tous sur les arcs. Dans une algèbre de processus ces objets n'ont pas de domicile — les arcs sont une conséquence, pas une donnée. À l'inverse, une algèbre de processus compose : `P | Q` est un terme, on peut raisonner sur `P` seul et réutiliser le résultat. Fusionner des places ne donne aucun théorème de ce genre, et c'est exactement pourquoi le réseau Kanban de la leçon 12 a dû être rebâti en entier plutôt qu'assemblé à partir de quatre copies d'une cellule.

L'égalité diffère aussi. Deux marquages sont égaux quand ce sont la même fonction. Deux processus sont égaux quand ils sont **bisimilaires**, ce qui est une relation entre comportements et non entre structures. Deux réseaux ayant le même graphe d'accessibilité à l'étiquetage près sont bisimilaires et restent deux réseaux différents — avec des invariants différents, des siphons différents, et des verdicts différents à la leçon 6.

## Les automates temporisés

Un [automate temporisé](https://doi.org/10.1016/0304-3975(94)90010-8) a des horloges à valeurs réelles, des gardes qui les comparent à des constantes, et des remises à zéro sur les transitions. Son espace d'états n'est pas un graphe d'états mais un graphe de **zones** : des ensembles de valuations d'horloges, rendus finis par une construction par régions. [UPPAAL](https://uppaal.org/) est l'outil.

La leçon 9 de ce cours a ajouté le temps à un réseau, et a ajouté l'*autre* sorte : un taux stochastique sur chaque transition, ce qui donne une chaîne de Markov à temps continu et répond à « à quelle fréquence » plutôt qu'à « avant quand ». La sorte déterministe — un intervalle de Merlin `[a, b]` sur une transition — n'a pas de chaîne de Markov derrière elle et demande une construction par classes d'états que l'analyseur n'a pas. [TINA](https://projects.laas.fr/tina/) fait exactement cette construction pour les réseaux de Petri temporels.

*À vérifier.* Rien dans cette section n'a été exécuté. Aucun modèle UPPAAL n'a été construit, aucun graphe de classes d'états TINA n'a été calculé, et aucun nombre de cette leçon ne vient de l'un ou de l'autre. L'affirmation qu'un réseau de Petri temporel demande des classes d'états plutôt qu'une chaîne de Markov est la question ouverte du journal depuis la leçon 9, toujours ouverte ici.

## Où celle-ci s'arrête

- **Seul l'espace d'états a été comparé.** TLC sait vérifier des propriétés temporelles sous équité — `[]<>Enabled(t) => []<>t` est ce que demande vraiment la question de famine de la leçon 7 — et aucun des 25 modules n'en déclare. Le `.cfg` généré a une ligne `INVARIANT` et aucune ligne `PROPERTY`.
- **Pas de PlusCal.** Les modules sont du TLA+ brut parce que le réseau *est* déjà une relation de transition ; une traduction PlusCal ajouterait un algorithme que personne n'a écrit.
- **La traduction est à sens unique.** Rien ici ne relit un module TLA+ vers un réseau, et la direction difficile est celle qui n'est pas faite : une spécification dont les variables ne sont pas un marquage n'a pas de réseau.
- **Trois des quatre réseaux non bornés sont tronqués, pas analysés.** La réponse de TLC pour eux est une affirmation sur le plafond.

## À retenir

- Un état TLA+ et un marquage de réseau de Petri sont le même objet dès que l'unique variable est une fonction des places vers les naturels ; tout le reste de la comparaison découle de ce choix.
- Sur 22 réseaux à espace d'états fini, les *états distincts*, *états engendrés* et *profondeur* de TLC égalent les marquages, les arcs + 1 et le plus long des plus courts chemins + 1 de l'analyseur. Soixante-six nombres, aucun désaccord.
- TLA+ n'a aucune notion de bornitude. Le plafond qui fait terminer TLC vient des invariants de places — la théorie structurelle nourrit le model checker, et pas l'inverse.
- TLC s'arrête sur un état sans successeur et l'appelle interblocage. Le marquage final d'un réseau de workflow est cet état, donc il faut désactiver la vérification ; les deux formalismes ne s'accordent pas sur le fait que les systèmes finissent.
- Un invariant de places prouve la bornitude et ne la réfute jamais : `handshake` n'a pas d'invariant et a un seul marquage.
- Un model checker décide plus de propriétés. Un réseau décide moins de propriétés sans rien énumérer, et c'est le seul genre de réponse qui survit à 1,2 milliard d'arcs.

## Exercices

1. Générez `out/tla/queue_5.tla` et passez `Cap` de 5 à 2 à la main. Lancez TLC. Combien d'états distincts trouve-t-il, et que veut dire ce nombre sur la contrainte ?
2. `philosophers-one-fork-3` a un interblocage. Remettez `CHECK_DEADLOCK TRUE` dans son `.cfg`, lancez TLC, et lisez le contre-exemple qu'il imprime. Comparez-le à `ReachabilityGraph.PathTo` sur l'état mort. Lequel est le plus exploitable ?
3. Ajoutez `AtMostOneInCritical` à `two_locks.tla` comme invariant et lancez TLC. Puis trouvez l'invariant de places qui fait la même affirmation sans énumération, avec `l5`. Lequel survit au remplacement des deux verrous par dix ?
4. `order-sound` est le seul réseau dont le graphe a deux pas entre le même couple de marquages. Construisez un réseau où trois transitions mènent du marquage initial au même successeur, et prédisez les *états engendrés* de TLC avant de le lancer.

<details>
<summary>Corrigés</summary>

1. **Zéro.** `queue-5` démarre avec ses cinq jetons dans `room`, donc le marquage initial lui-même viole un plafond de 2 et TLC le jette avant d'explorer quoi que ce soit :

   ```
   Model checking completed. No error has been found.
   1 states generated, 0 distinct states found, 0 states left on queue.
   ```

   Il n'a rien vérifié et annonce un succès. Un plafond de 4 fait pareil. C'est la réponse à l'exercice et la raison pour laquelle le plafond de cette leçon vient des invariants plutôt que d'un nombre choisi par quelqu'un : une contrainte d'état n'est pas une analyse, et le verdict de TLC se lit à l'identique qu'il ait exploré tout l'espace d'états ou rien du tout. Le drapeau correspondant de l'analyseur, `ReachabilityGraph.IsComplete`, est faux plutôt qu'absent.

2. TLC imprime le plus court comportement menant à l'état mort : chaque pas avec le marquage entier, dans l'ordre. `PathTo` renvoie les noms de transitions et rien d'autre. La trace de TLC est plus facile à lire ; la liste de `PathTo` est plus facile à réinjecter dans le modèle, et la leçon 3 s'en sert exactement pour cela. Ni l'une ni l'autre ne dit *pourquoi* : la raison est structurelle, c'est le siphon `{fork1, fork2, fork3}` qui se vide, et seul `Structure.MinimalSiphons` de la leçon 7 le nomme.

3. TLC visite quatre états et ne signale aucune erreur. `l5` imprime `held1 + free1 = 1` et `held2 + free2 = 1` pour `two-locks`, d'où aucun fil ne tient deux verrous — et les invariants se calculent sur une matrice 4 × 4. À dix verrous, le calcul d'invariants croît comme la matrice et l'espace d'états croît comme 2¹⁰ : l'énumération reste faisable à dix, et cesse de l'être quelque part dans la vingtaine, là où commence le mur de la leçon 12.

4. Le nouveau réseau a 1 marquage initial et 3 arcs qui en sortent, donc l'analyseur annonce 3 pas ; TLC annonce **4 états engendrés, 2 états distincts trouvés**, parce qu'il compte un état engendré par disjoint évalué puis n'en garde qu'un. L'écart entre *engendrés* et *arcs + 1* reste nul, et l'écart entre *engendrés* et *distincts* est l'endroit où sont passées les collisions.

</details>

## Sources

- Leslie Lamport, *Specifying Systems*, Addison-Wesley 2002, disponible depuis la [page d'accueil de TLA+](https://lamport.azurewebsites.net/tla/book.html). La forme `[][Next]_v` et le sens d'une contrainte d'état sont les chapitres 2 et 14.
- [Les outils TLA+](https://github.com/tlaplus/tlaplus) (MIT). `tla2tools.jar` 2.19 est ce qui a produit chaque chiffre de TLC ci-dessus ; il n'est pas embarqué ici.
- David Harel, *Statecharts: A visual formalism for complex systems*, **Science of Computer Programming** 8(3), 1987, pages 231–274, [doi:10.1016/0167-6423(87)90035-9](https://doi.org/10.1016/0167-6423(87)90035-9). La notice est confirmée par Crossref ; l'article est derrière un péage et je ne l'ai pas lu, donc rien de ce qui précède ne repose sur lui seul — hiérarchie, orthogonalité et diffusion sont les trois traits sur lesquels s'accordent toutes les descriptions ultérieures. *À vérifier.*
- Robin Milner, *A Calculus of Communicating Systems*, **LNCS 92**, Springer 1980, [doi:10.1007/3-540-10235-3](https://doi.org/10.1007/3-540-10235-3). Même réserve. *À vérifier.*
- C. A. R. Hoare, *Communicating Sequential Processes*, **Communications of the ACM** 21(8), 1978, [copie de l'auteur](https://www.cs.cmu.edu/~crary/819-f09/Hoare78.pdf). Celui-ci est lisible en entier et c'est la source de l'affirmation que la composition est la primitive.
- Rajeev Alur et David Dill, *A theory of timed automata*, **Theoretical Computer Science** 126(2), 1994, [doi:10.1016/0304-3975(94)90010-8](https://doi.org/10.1016/0304-3975(94)90010-8), [copie des auteurs](https://www.cis.upenn.edu/~alur/TCS94.pdf). Horloges, gardes, remises à zéro et construction par régions.
- [UPPAAL](https://uppaal.org/) et [TINA](https://projects.laas.fr/tina/), les deux outils nommés dans la section temporisée. Aucun des deux n'a été exécuté.
- Tadao Murata, *Petri nets: Properties, analysis and applications*, **Proceedings of the IEEE** 77(4), 1989, [doi:10.1109/5.24143](https://doi.org/10.1109/5.24143), pour la règle de franchissement que le module TLA+ énonce.
