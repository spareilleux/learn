---
title: "16. Interopérabilité : préserver le comportement, pas seulement le dessin"
description: Un modèle PNML d'admission d'agents écrit à la main, lu, analysé, écrit et relu, puis comparé sur ce qu'il fait plutôt que sur son apparence ; le même modèle avec sa libération oubliée ; deux fichiers malformés ; et un arc inhibiteur que le lecteur avalait sans un mot.
sidebar:
  order: 16
---

Code complet : [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets). Cette leçon est imprimée par `dotnet run --project Examples -c Release -- l16`, comparée à [`expected/l16.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l16.txt). Ses fichiers d'entrée, et les prédictions écrites avant la première exécution, sont dans [`interop/`](https://github.com/spareilleux/learn/tree/main/code/petri-nets/interop).

La [leçon 11](../11-tools-and-interoperability/) a montré deux choses :
- PNML est une syntaxe plus une URI de type ;
- chaque réseau du cours survit à un aller-retour par l'écrivain et le lecteur, octet pour octet.

Cela testait l'écrivain contre son propre lecteur. Cette leçon pose la question que soulève un second outil : une fois qu'un réseau est passé par un fichier, **fait**-il toujours la même chose ? Le dessin peut bouger. Le comportement, non.

## Trois sortes de fichiers, trois sortes de promesses

Les fichiers qui « contiennent un réseau de Petri » contiennent trois choses différentes, et une seule peut être vérifiée sur son comportement.

| Sorte | Ce qu'il contient | Ce qu'il peut vous dire | Format d'exemple |
|---|---|---|---|
| Un modèle | places, transitions, arcs et leurs poids, marquage initial | toutes les exécutions que le réseau permet | [PNML](https://www.pnml.org/) de type P/T, le `.net` de [TINA](https://projects.laas.fr/tina/manuals/tina.html) |
| Un journal d'événements | des cas et les événements qui s'y sont produits, dans l'ordre | les exécutions **observées**, pas celles qui étaient possibles | XES, qu'écrit le [`write_xes` de pm4py](https://processintelligence.solutions/app/static/api/2.7.17/api/pm4py.write.html) |
| Un export visuel | nœuds, arêtes, positions, étiquettes | l'image | [DOT](https://graphviz.org/doc/info/lang.html), le langage de Graphviz |

- **Un journal est une preuve sur certaines exécutions.** On peut en extraire un modèle, c'est le process mining de la [leçon 10](../10-workflows/). Le journal ne contient pas le modèle : une exécution qui n'a jamais eu lieu n'y figure pas.
- **La grammaire de DOT définit des nœuds, des arêtes, des graphes, des sous-graphes et des clusters, avec des attributs.** Un nombre de jetons écrit dans un fichier DOT est une étiquette ; rien ne le lit comme un marquage.

**PNML est typé, et le type n'est pas une promesse.** L'URI de type dit au lecteur dans quel langage est le fichier. Elle ne promet pas que le lecteur implémente chaque extension qu'un outil peut ajouter par-dessus.

Deux sources primaires montrent à quel point l'échange dépend de l'outil :
- **Le manuel de TINA** dit que `tina` lit un réseau sous forme textuelle (`.net`, `.pnml`, `.tpn`) ou graphique (`.ndr`, ou `.pnml` avec graphismes). Il a une option, `-inh`, qui *« retire les arcs inhibiteurs et de lecture du réseau d'entrée »*. Là-bas, abandonner une partie de la sémantique est une option que l'utilisateur demande par son nom.
- **Le `write_pnml` de pm4py** prend un marquage initial **et un marquage final**. Il écrit la vue « réseau de workflow » de la leçon 10, qu'un simple réseau P/T n'a pas.

## Le modèle

Deux jobs d'agent partagent une étape d'admission qu'un seul peut tenir à la fois. Un job a besoin d'un candidat testé avant d'être admis, et rend sa capacité quand il termine.

| Place | Initial | Sens |
|---|---|---|
| `waiting` | 2 | jobs dont le candidat n'a pas encore été testé |
| `tested` | 0 | jobs dont le candidat a passé ses tests : le prérequis de l'admission |
| `capacity` | 2 | places libres ; un job en demande 2, donc un seul job tourne à la fois |
| `running` | 0 | jobs admis |
| `done` | 0 | jobs terminés |

| Transition | Consomme | Produit |
|---|---|---|
| `test` | `waiting` | `tested` |
| `admit` | `tested`, `capacity` ×2 | `running` |
| `finish` | `running` | `done`, `capacity` ×2 : la libération |

[`admission.pnml`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/interop/admission.pnml) a été écrit à la main, pas par l'écrivain de ce cours. Il est écrit comme l'écrirait un outil de dessin : une position `<graphics>` sur chaque nœud, et le nom du réseau sur la `<page>`.

Contrairement aux leçons précédentes du cours, les prédictions ont été enregistrées dans un fichier avant la première exécution : [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/interop/preregistration.md), haché à 10:54 EDT le 2026-09-27. Toutes se sont vérifiées.

## E1 : lire, analyser, écrire, relire

Le programme calcule ce que le réseau **signifie**, sous forme de lignes comparables. Il le fait après la première lecture, puis de nouveau après avoir écrit le réseau et l'avoir relu :

```text
== E1: the admission net, read, written and read again ==
places:      waiting tested capacity running done
transitions: test admit finish
initial:     waiting=2 tested=0 capacity=2 running=0 done=0
arcs:        waiting->test, test->tested, tested->admit, capacity->admit x2, admit->running, running->finish, finish->done, finish->capacity x2
enabled:     test
states:      9
dead:        waiting=0 tested=0 capacity=2 running=0 done=2  after test test admit finish admit finish
bounds:      waiting<=2 tested<=2 capacity<=2 running<=1 done<=2
capacity + 2*running = 2 in every state: yes
after the round trip, same meaning: yes
second write identical to the first: yes
positions in the input: 9, in the output: 0
```

- **Ce qui survit :**
  - les identifiants ;
  - le marquage ;
  - les deux poids de 2 ;
  - l'ensemble des transitions franchissables ;
  - les 9 marquages accessibles ;
  - l'unique marquage mort ;
  - les bornes.
- **Le marquage mort est la fin prévue :** les deux jobs sont terminés et la capacité est revenue à 2.
- **`running<=1` est la propriété pour laquelle le modèle existe.** Il n'y a jamais de double admission. La somme conservée `capacity + 2·running = 2` est le même fait écrit comme un invariant ([leçon 5](../05-invariants/)).
- **Les 9 positions ont disparu,** parce que l'écrivain abandonne la mise en page (leçon 11). Ce n'est pas un échec : rien dans la comparaison ne dépend de l'endroit où une place est dessinée.

Ce que couvre cette comparaison, c'est le **comportement accessible borné** : les 9 marquages sont énumérés, aucun n'est laissé de côté. Ce n'est pas une exécution de vrais jobs. Ce n'est pas non plus une preuve d'équité : le graphe dit qu'un job en attente *peut* terminer, pas qu'un ordonnanceur le laissera faire ([leçon 4](../04-properties/)).

## E2 : la libération oubliée

[`admission-no-release.pnml`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/interop/admission-no-release.pnml) est le même réseau, avec un `finish` qui ne produit que `done` :

```text
== E2: the same net with the release forgotten ==
states:      7
dead:        waiting=0 tested=1 capacity=0 running=0 done=1  after test test admit finish
bounds:      waiting<=2 tested<=2 capacity<=2 running<=1 done<=1
```

- **Le marquage mort n'est pas une fin.** Un job est testé et ne sera jamais admis, parce que la capacité qu'il attend n'a jamais été rendue.
- **Le chemin est la partie utile : `test test admit finish`.** C'est un contre-exemple que chacun peut rejouer, dans cet analyseur ou dans un autre outil, et il désigne la transition qui a oublié quelque chose.

## E3 : des fichiers faux

```text
malformed-arc.pnml      refused: ArgumentException: Arc finish -> finished does not join a place and a transition. (Parameter 'arcs')
malformed-marking.pnml  refused: FormatException: The input string 'two' was not in a correct format.
```

- **Les deux fichiers sont refusés, comme prévu :** un arc vers un nœud qui n'existe pas, et un marquage initial écrit `two`.
- **Le second message est celui d'`int.Parse`.** Il ne dit pas quelle place était fausse. C'est observé et laissé tel quel : le refus est correct, seule sa formulation est pauvre.

## E4 : une fonctionnalité que le lecteur ne modélise pas

Un arc inhibiteur ne laisse une transition se franchir que lorsqu'une place est **vide** ([leçon 15](../15-limits-and-what-comes-next/)). Il ne fait pas partie de la grammaire P/T.

[`inhibitor-arc.pnml`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/interop/inhibitor-arc.pnml) remplace la place de capacité par un tel arc, de `running` vers `admit`. L'arc porte un enfant `<type>`, comme le font les outils qui modélisent plus que les réseaux P/T pour marquer la sorte d'un arc :

```xml
<arc id="r-inhibits-admit" source="running" target="admit">
  <type value="inhibitor"/>
</arc>
```

Avant cette leçon, le lecteur acceptait le fichier :

```text
inhibitor-arc.pnml      READ: 3 states, dead: waiting=0 tested=2 running=0 done=0
```

**C'est un autre réseau.** Le lecteur a pris l'arc inhibiteur pour un arc ordinaire qui consomme. `admit` exigeait donc un job déjà en cours, aucun job n'était jamais admis, et le réseau s'arrêtait avec les deux jobs testés.

Il n'y avait ni erreur ni avertissement. C'est la pire issue possible d'un échange : un fichier qui se lit, et qui veut dire autre chose.

Le lecteur refuse désormais tout arc dont le type n'est pas `normal`, et dit pourquoi ([`Pnml.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Pnml.cs)) :

```csharp
var kind = (string?)element.Element(ns + "type")?.Attribute("value");
if (kind is not null && kind != "normal")
    throw new NotSupportedException($"Arc {(string?)element.Attribute("id") ?? $"{source} -> {target}"} is of type {kind}; the P/T reader reads ordinary arcs only.");
```

```text
inhibitor-arc.pnml      refused: NotSupportedException: Arc r-inhibits-admit is of type inhibitor; the P/T reader reads ordinary arcs only.
```

Un test unitaire, `An_arc_the_reader_does_not_model_is_refused_not_read_as_an_ordinary_arc`, fixe la correction :
- il échouait avant la correction (1 des 5 tests PNML) ;
- il passe après (5 sur 5), et tout le cours aussi (92 tests, 19 sorties comparées).

Un arc typé `normal` est toujours lu : il dit que l'arc est ordinaire, et le test le vérifie comme contrôle.

## Ce qui n'a pas été exécuté ici

**TINA n'est pas installé sur cette machine, pm4py et Graphviz non plus.** L'étape suivante est une recette, pas un résultat :

```bash
# En attente : TINA n'est pas installé sur cette machine. Cette commande n'a pas été exécutée.
tina -R interop/admission.pnml
```

- **Ce qu'elle vérifierait.** `-R` construit le graphe des marquages accessibles. Ses comptes devraient correspondre à ceux d'E1 : 9 marquages, un marquage mort, celui où les deux jobs sont terminés.
- **Ce qui serait aussi un résultat :**
  - `inhibitor-arc.pnml` lu par TINA, qui modélise les arcs inhibiteurs ;
  - le même fichier avec `-inh`.
- **En attente également :**
  - un journal XES d'exécutions simulées, comparé au modèle ;
  - une image DOT, qui ne vérifierait rien du comportement.

## À retenir

- **Comparez ce qu'un réseau signifie, pas l'allure de son fichier :** identifiants, marquage, poids, transitions franchissables, marquages accessibles, marquages morts et bornes.
- **Un journal enregistre des exécutions, un dessin des positions ; seul un modèle enregistre un comportement.**
- **Le pire échec est silencieux.** Un réseau qui se lit et veut dire autre chose est pire qu'un refus. Refusez ce que vous ne modélisez pas, et dites ce que c'était.
- **Un marquage mort avec son chemin est un contre-exemple que l'on peut rejouer.** Un espace d'états n'est ni une exécution ni une preuve d'équité.

## Exercices

1. Donnez trois jobs au modèle (`waiting` = 3). Prédisez le nombre de marquages accessibles avant de l'exécuter, puis vérifiez.
2. E1 a un marquage mort, et personne ne l'appelle un interblocage. Pourquoi, et qu'est-ce qui rendrait la différence explicite ?
3. Un arc typé `<type value="reset"/>` vide sa place. Que fait le lecteur de cet arc maintenant, et qu'en aurait-il fait avant cette leçon ?
4. Lequel de ces éléments prouve que deux outils sont d'accord sur un réseau ? Un texte PNML identique ; un DOT identique ; des nombres d'états identiques ; des graphes d'accessibilité identiques au renommage des marquages près.

<details>
<summary>Solutions</summary>

**1.** Seize. Au plus un job tourne, parce que `running<=1`.
- Avec `running = 0`, les trois jobs se répartissent entre `waiting`, `tested` et `done` : C(5, 2) = 10 façons.
- Avec `running = 1`, les deux autres se répartissent de la même façon : C(4, 2) = 6 façons.

Exécuté sur une copie d'`interop/` avec `waiting` mis à 3 :

```text
initial:     waiting=3 tested=0 capacity=2 running=0 done=0
states:      16
dead:        waiting=0 tested=0 capacity=2 running=0 done=3  after test test test admit finish admit finish admit finish
bounds:      waiting<=3 tested<=3 capacity<=2 running<=1 done<=3
capacity + 2*running = 2 in every state: yes
```

**2.** Le marquage mort d'E1 est la fin voulue : chaque job est terminé et la capacité est revenue. Un interblocage est un marquage mort qui n'est **pas** la fin voulue, comme celui d'E2.

Le réseau seul ne peut pas les distinguer. Un **marquage final** le peut : c'est ce qu'ajoute un réseau de workflow (leçon 10), et c'est pourquoi `pm4py.write_pnml` en demande un.

**3.** Il est refusé :

```text
inhibitor-arc.pnml      refused: NotSupportedException: Arc r-inhibits-admit is of type reset; the P/T reader reads ordinary arcs only.
```

Avant la correction, le lecteur ne lisait que `source`, `target` et `inscription`. Il aurait pris l'arc pour un arc ordinaire, qui consomme un jeton au lieu de vider la place. C'est le même changement silencieux que pour l'arc inhibiteur.

**4.** Seulement le dernier.
- **Le texte** n'est ni nécessaire ni suffisant. La mise en page, les identifiants et l'ordre des éléments peuvent différer pour un même réseau. Et deux lecteurs peuvent lire différemment le même texte, comme ce lecteur l'a fait avec E4 avant la correction.
- **DOT** ne dit rien du comportement.
- **Des nombres égaux** sont nécessaires, pas suffisants.
- **Des graphes d'accessibilité identiques au renommage près**, avec les transitions étiquetées, sont l'énoncé comportemental pour un réseau borné.

</details>

## Sources

- [PNML](https://www.pnml.org/), le site du format, et ISO/IEC 15909-2:2011, cité à la leçon 11.
- [Manuel de TINA](https://projects.laas.fr/tina/manuals/tina.html), LAAS-CNRS : formats d'entrée, `-R`, `-inh`. Lu le 2026-09-27 ; TINA lui-même non exécuté.
- [pm4py 2.7.17, `pm4py.write`](https://processintelligence.solutions/app/static/api/2.7.17/api/pm4py.write.html) : les signatures de `write_pnml` (marquage initial et final) et de `write_xes`. Lu le 2026-09-27 ; pm4py non exécuté.
- [Le langage DOT](https://graphviz.org/doc/info/lang.html), Graphviz : une grammaire abstraite pour les nœuds, arêtes, graphes, sous-graphes et clusters.
