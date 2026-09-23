---
title: 11. Outils et interopérabilité
description: PNML est la seule chose sur laquelle tous les outils de réseaux de Petri s'accordent — ce que l'analyseur écrit, ce qu'un aller-retour garde et perd, ce qui s'est passé quand on lui a donné seize fichiers écrits par un autre outil, le défaut que cela a trouvé, et ce que TINA, LoLA, CPN Tools, GreatSPN, TAPAAL et ProM font que ce cours ne fait pas.
sidebar:
  order: 11
---

Code complet : [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets). Cette leçon est imprimée par `dotnet run --project Examples -c Release -- l11`, comparée à [`expected/l11.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l11.txt).

Dix leçons ont été écrites contre un analyseur que j'ai écrit, sur des réseaux que j'ai écrits aussi. C'est une boucle fermée, et une boucle fermée est la façon dont un cours enseigne discrètement ses propres bogues.

La sortie de cette boucle s'appelle [PNML](https://www.pnml.org/), le Petri Net Markup Language — un format XML normalisé sous [ISO/IEC 15909-2:2011](https://www.iso.org/standard/43538.html) et la seule chose sur laquelle les outils de ce domaine s'accordent. Un réseau écrit ici peut être vérifié par un model checker écrit par quelqu'un d'autre, et un réseau venu d'un banc d'essai publié peut passer dans l'analyseur de ce cours.

Cette leçon fait les deux sens et raconte ce qui a cassé.

## Ce que l'écrivain produit

```
== What the writer emits ==
<?xml version="1.0" encoding="utf-8"?>
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
  <net id="n1" type="http://www.pnml.org/version-2009/grammar/ptnet">
    <name>
      <text>queue-2</text>
    </name>
    <page id="page1">
      <place id="room">
        <name>
          <text>room</text>
        </name>
        <initialMarking>
          <text>2</text>
        </initialMarking>
      </place>
      <place id="jobs">
        <name>
          <text>jobs</text>
        </name>
      </place>
      <transition id="arrive">
        <name>
          <text>arrive</text>
        </name>
      </transition>
      <transition id="serve">
        <name>
          <text>serve</text>
        </name>
      </transition>
      <arc id="a1" source="room" target="arrive" />
      <arc id="a2" source="arrive" target="jobs" />
      <arc id="a3" source="jobs" target="serve" />
      <arc id="a4" source="serve" target="room" />
    </page>
  </net>
</pnml>
```

Quatre choses dans ce fichier méritent d'être nommées, parce que chacune est un endroit où les outils divergent.

- **l'attribut `type`** est une URI, et c'est tout le contrat. `…/grammar/ptnet` veut dire réseau place/transition : jetons indiscernables, arcs à poids entiers. Une autre URI est un autre langage dans la même syntaxe, et le lecteur doit refuser plutôt que deviner.
- **`<page>`** existe parce que PNML modélise un *dessin*, et qu'un dessin a des pages. L'analyseur n'a aucun usage des pages et en écrit exactement une ; un fichier qui en apporte plusieurs est aplati.
- **toute valeur est enveloppée dans `<text>`**, parce que la norme autorise une valeur à porter des graphiques, une police, une annotation propre à un outil et un décalage d'étiquette à côté de son contenu. Le nombre n'est jamais le texte propre de l'élément.
- **l'absence vaut la valeur par défaut.** `jobs` n'a pas d'`<initialMarking>` et contient zéro ; les arcs n'ont pas d'`<inscription>` et pèsent un. Les écrire serait légal et plus bruyant.

## Relire ce que nous avons écrit

L'interopérabilité commence chez soi. Si le lecteur et l'écrivain divergent, aucun autre outil ne compte :

```
== Every net of the course, written and read back ==
24 nets written, parsed and written again
identical text and identical reachability graph: all of them
```

Vingt-quatre réseaux, chacun écrit en PNML, relu, puis réécrit. Les deux textes sont identiques à l'octet près et le graphe d'accessibilité a le même nombre d'états. `check.sh` le vérifie à chaque commit, ce qui fait des fichiers PNML de [`nets/`](https://github.com/spareilleux/learn/tree/main/code/petri-nets/nets) les mêmes objets que les définitions C#, et non une copie qui dérive.

Un aller-retour n'est pas sans perte, et le dire explicitement est le sujet :

```
== What a round trip drops ==
kept:    place and transition ids and names, arc weights, the initial marking
dropped: <graphics> positions and offsets, <toolspecific> blocks, page structure
refused: any <net type> that is not the P/T net type
```

Tout ce qui est perdu concerne le *dessin* du réseau, pas ce qu'il fait. Lisez un fichier venu d'un éditeur graphique, analysez-le, réécrivez-le : la mise en page a disparu, le réseau est le même réseau et l'image est à refaire. C'est le coût honnête d'un outil qui modélise les mathématiques et pas le diagramme.

## Lire un fichier écrit par quelqu'un d'autre

Le vrai test. [ePNK](http://www2.imm.dtu.dk/~eki/projects/ePNK/) est un outil PNML sous Eclipse d'Ekkart Kindler, l'un des auteurs de la norme ; son lot d'exemples embarque l'exemple de réseau P/T de la norme ISO/IEC 15909-2 elle-même, plus quinze réseaux de haut niveau. Seize fichiers, aucun de moi :

```
== Reading another tool ==
ConsensusInNetworks.pnml              refused: Net type highlevelnet is not the P/T net type ptnet.
Echo.pnml                             refused: Net type highlevelnet is not the P/T net type ptnet.
MinDistance.pnml                      refused: Net type highlevelnet is not the P/T net type ptnet.
SimpleTransmissionProtocol.pnml       refused: Net type highlevelnet is not the P/T net type ptnet.
TransmissionProtocolLossyChannel.pnml refused: Net type highlevelnet is not the P/T net type ptnet.
factorize.pnml                        refused: Net type highlevelnet is not the P/T net type ptnet.
factorize2.pnml                       refused: Net type highlevelnet is not the P/T net type ptnet.
lists.pnml                            refused: Net type highlevelnet is not the P/T net type ptnet.
prime-factors.pnml                    refused: Net type highlevelnet is not the P/T net type ptnet.
runtimeValueEval.pnml                 refused: Net type highlevelnet is not the P/T net type ptnet.
samplePTnet.pnml                      read: 1 places, 1 transitions, "An example P/T-net"
samplePTnetAdjustedPositions.pnml     read: 1 places, 1 transitions, "An example P/T-net"
sampleSNPrio.pnml                     refused: Net type symmetricnet is not the P/T net type ptnet.
sampleSNPrioDeclarationsOnPage.pnml   refused: Net type symmetricnet is not the P/T net type ptnet.
sampleSNPrioFixedNames.pnml           refused: Net type symmetricnet is not the P/T net type ptnet.
simple-dot-net.pnml                   refused: Net type pt-hlpng is not the P/T net type ptnet.
```

:::note[Ce bloc n'est pas produit par `check.sh`]
Les exemples de l'ePNK sont sous [EPL-1.0](https://www.eclipse.org/legal/epl-v10.html) et ne sont pas embarqués dans ce dépôt, donc `check.sh` lance `l11` sans eux et la section imprime un renvoi à la place. Pour reproduire : téléchargez [`ePNK-1.0.0-examples.zip`](http://www2.imm.dtu.dk/~eki/projects/ePNK/downloads/ePNK-1.0.0-examples.zip), décompressez les fichiers `.pnml` dans un dossier, et lancez `dotnet run --project Examples -c Release -- l11 <ce dossier>`. Le listing ci-dessus vient de cette exécution le 2026-09-22.
:::

Deux acceptés, quatorze refusés, et les deux moitiés sont le résultat.

**Les refus sont corrects, et le dernier est le plus intéressant.** `simple-dot-net.pnml` est un *réseau P/T* — un seul type de jeton, pas de donnée — écrit dans la grammaire de haut niveau avec l'ensemble de couleurs `dot`, qui a exactement une valeur. Il se comporte comme tous les réseaux de ce cours et il est illisible pour un lecteur qui vérifie l'URI de type. Trois des refus sont des réseaux symétriques, c'est-à-dire les réseaux colorés restreints que nommait la [leçon 8](../08-coloured-nets/). La morale est que « PNML » n'est pas un format : c'est une syntaxe plus une URI de type, et un outil parle certains de ces types.

**Les acceptations ont trouvé un défaut.** Le fichier d'exemple de l'ISO, tel que l'ePNK l'écrit, est fait exprès pour être piégeux :

```xml
<net type="http://www.pnml.org/version-2009/grammar/ptnet" id="n1">
  <page id="top-level">
    <name><text>An example P/T-net</text></name>
    <place id="p1">
      <name><graphics><offset y="-10.0"/></graphics><text>ready</text></name>
      <initialMarking>
        <toolspecific tool="org.pnml.tool" version="1.0">…</toolspecific>
        <text>3</text>
      </initialMarking>
    </place>
    <transition id="t1"><graphics><position x="60.0" y="20.0"/></graphics></transition>
    <arc id="a1" source="p1" target="t1">
      <inscription><graphics><offset y="5.0"/></graphics><text>2</text></inscription>
    </arc>
  </page>
</net>
```

Quatre pièges, et le lecteur en a survécu trois. Le marquage vaut 3 bien qu'un bloc `<toolspecific>` vienne d'abord ; le poids de l'arc vaut 2 bien qu'un `<graphics>` vienne d'abord ; la transition n'a pas de `<name>` du tout et retombe sur son identifiant.

Le quatrième l'a eu. **Le nom est porté par la `<page>`, pas par le `<net>`**, et le lecteur ne regardait que le réseau — le fichier revenait donc appelé `n1`, son identifiant. La norme autorise le nom sur l'un ou l'autre, les outils diffèrent, et l'analyseur en avait silencieusement choisi un. Trois lignes ont corrigé cela, un test unitaire porte désormais toute la forme piégeuse, et le listing ci-dessus est postérieur à la correction.

C'est le seul défaut que cette leçon a trouvé, et il a été trouvé par la seule méthode qui trouve cette classe de défauts : lire un fichier que personne dans ce dépôt n'a écrit.

## À quoi servent les autres outils

L'analyseur de ce cours est un instrument pédagogique. Il construit un graphe d'accessibilité en mémoire avec une limite dure, énumère les siphons par force brute sur les sous-ensembles de places, et résout une chaîne de Markov par élimination de Gauss dense. Chacun de ces choix est le mauvais algorithme à l'échelle, délibérément, parce que chacun est assez court pour être lu.

Voici les outils qui le font correctement. Aucun n'est requis par ce cours ; tous parlent PNML, la plupart parlent aussi leur format natif.

| Outil | À quoi il sert | Format natif |
|---|---|---|
| [TINA](https://projects.laas.fr/tina/) | réseaux de Petri temporels au sens de Merlin, classes d'états, model checking LTL/CTL | `.net`, `.ndr`, lit PNML |
| [LoLA](https://theo.informatik.uni-rostock.de/theo-forschung/tools/lola/) | accessibilité et CTL\* très rapides sur d'énormes réseaux P/T, avec ensembles obstinés et symétries | format propre, lit PNML |
| [CPN Tools](https://cpntools.org/) | réseaux colorés à inscriptions CPN ML, simulation, espace d'états avec symétries | `.cpn`, exporte PNML |
| [GreatSPN](https://www.di.unito.it/~greatspn/index.html) | GSPN et analyse stochastique, les modèles de la [leçon 9](../09-time-and-probability/) à l'échelle | format propre, lit PNML |
| [TAPAAL](https://www.tapaal.net/) | réseaux à arcs temporisés, vérification par traduction en automates temporisés | `.tapn`, lit PNML |
| [Snoopy](https://www-dssz.informatik.tu-cottbus.de/DSSZ/Software/Snoopy) | dessin et simulation de plusieurs classes de réseaux, fort en biologie des systèmes | format propre, exporte PNML |
| [PIPE](https://github.com/sarahtattersall/PIPE) | un éditeur et analyseur Java, celui dont le code est le plus facile à lire | PNML nativement |
| [ePNK](http://www2.imm.dtu.dk/~eki/projects/ePNK/) | l'implémentation de référence du métamodèle de la norme | PNML nativement |
| [ProM](https://promtools.org/) | process mining, l'autre sens de la [leçon 10](../10-workflows/) | journaux XES, réseaux PNML |

L'endroit où les voir les uns contre les autres est le [Model Checking Contest](https://mcc.lip6.fr/), qui les fait tourner chaque année sur une collection publique de réseaux, en PNML, avec des résultats publiés. Cette collection est aussi la réponse honnête à « mon analyseur est-il rapide ? » — il ne l'est pas, et le concours dit de combien. *À vérifier : je n'y ai rien soumis, ni fait tourner son jeu de bancs d'essai.*

## Où cela s'arrête

- **Une syntaxe partagée n'est pas une sémantique partagée.** Tous les fichiers ci-dessus se lisent comme du XML. Quatorze restaient illisibles, parce que l'URI de type nomme un autre langage. PNML rend l'échange *possible* entre des outils qui implémentent le même type ; il ne rend pas tout réseau portable.
- **La norme a trois parties et la plus utile coûte de l'argent.** La [partie 1](https://www.iso.org/standard/67235.html) donne les concepts, la [partie 2](https://www.iso.org/standard/43538.html) le format de transfert, la [partie 3](https://www.iso.org/standard/81504.html) les extensions. Les grammaires sont libres sur [pnml.org](https://www.pnml.org/) — mais seulement le modèle de base et celles qui ne dépendent pas du type ; la grammaire P/T ne fait pas partie des `.rng` publiés, donc la sortie de l'analyseur n'a jamais été validée contre un schéma. *À vérifier.*
- **Personne ne s'accorde sur l'endroit où vit la mise en page.** Les positions sont dans `<graphics>` et sont optionnelles, donc un réseau échangé entre deux éditeurs arrive en général en tas. Chaque outil a son bloc `<toolspecific>`, que par conception personne d'autre ne lit.
- **Lire est plus difficile qu'être lu.** Écrire du PNML qu'un autre outil accepte est la moitié facile, parce que la syntaxe est petite. Lire ce que les autres écrivent est là où le travail se trouve : noms à des endroits inattendus, pages multiples, arcs entre arcs dans les extensions, et inscriptions qui sont des expressions plutôt que des nombres.

## À retenir

- **PNML est une syntaxe plus une URI de type.** L'URI est le contrat ; un lecteur qui l'ignore lira volontiers un réseau coloré comme un réseau P/T.
- L'analyseur fait **l'aller-retour des 24 réseaux du cours** à l'octet près, et `check.sh` le vérifie à chaque commit, de sorte que les fichiers `.pnml` et les définitions C# ne peuvent pas diverger.
- Un aller-retour **garde le réseau et perd l'image**. C'est un choix de conception, et il veut dire qu'un éditeur graphique et un analyseur ne sont pas interchangeables.
- **Lisez un fichier que personne de votre côté n'a écrit.** Seize fichiers d'un autre outil ont trouvé un vrai défaut en trois minutes ; dix leçons de sortie cohérente avec elle-même n'en avaient trouvé aucun.
- Le défaut était un **nom sur la `<page>` au lieu du `<net>`** — le genre de chose qu'une norme permet, que les outils tranchent différemment, et que seul un fichier étranger révèle.
- Un réseau P/T peut être écrit dans la **grammaire de haut niveau** avec un ensemble de couleurs à une valeur, et devient alors illisible pour un lecteur P/T. Même réseau, autre langage.
- Les vrais outils sont **TINA, LoLA, CPN Tools, GreatSPN, TAPAAL, Snoopy, PIPE, ePNK et ProM**. L'analyseur de ce cours n'en est pas un et n'essaie pas de l'être.

## Exercices

1. Prenez `nets/queue-5.pnml`, changez l'URI de `type` pour celle des réseaux symétriques, et prédisez ce que fait le lecteur avant de l'exécuter.
2. L'aller-retour perd les `<graphics>`. Dites ce qu'il faudrait changer dans `PetriNet` pour les garder, et si vous le feriez.
3. Écrivez à la main le plus petit fichier PNML que le lecteur accepte, et dites quels éléments vous avez omis et pourquoi c'est légal.
4. L'analyseur aplatit plusieurs `<page>` en une. Nommez un réseau pour lequel cela perd une information qui compte, et un pour lequel non.

<details>
<summary>Solutions</summary>

**1.** Il lève `NotSupportedException` avec le message `Net type symmetricnet is not the P/T net type ptnet.` — et c'est exactement le comportement qu'un test unitaire de `PnmlTests` épingle, en faisant cette substitution sur le réseau `handshake`. Le fichier reste du PNML valide et se lit toujours comme du XML ; seul le lecteur refuse. Remarquez ce qui se passerait sans ce contrôle : les places d'un réseau symétrique portent une déclaration d'ensemble de couleurs et ses arcs portent des expressions plutôt que des entiers, donc l'analyse échouerait plus tard, dans `int.Parse`, avec un message sur une chaîne qui n'est pas un nombre — une pire erreur à propos d'un vrai problème.

**2.** `Place` et `Transition` auraient besoin d'une position, `Arc` d'une liste de points intermédiaires, et chaque nom d'un décalage ; l'écrivain les émettrait et le lecteur les garderait. Cela fait peut-être quarante lignes.

Je ne le ferais pas. L'analyseur ne dessine jamais rien — la [leçon 1](../01-why-petri-nets/) confie le dessin à Mermaid, qui place le graphe lui-même — donc les coordonnées seraient trimballées dans tout le programme sans jamais être lues. Le bon endroit pour ces données est un outil dont le métier est l'image, et la bonne chose à faire pour celui-ci est de dire clairement qu'il les jette.

**3.** Un réseau à une place, une transition et un arc, sans noms, sans marquage, sans inscription :

```xml
<pnml xmlns="http://www.pnml.org/version-2009/grammar/pnml">
  <net id="n" type="http://www.pnml.org/version-2009/grammar/ptnet">
    <page id="p">
      <place id="p1"/>
      <transition id="t1"/>
      <arc id="a1" source="p1" target="t1"/>
    </page>
  </net>
</pnml>
```

Les noms sont omis parce qu'un identifiant est obligatoire et un nom non, donc le lecteur retombe sur l'identifiant — ce qui est arrivé à `t1` dans l'exemple de l'ISO. Le marquage est omis parce qu'absent veut dire zéro, et l'inscription parce qu'absente veut dire un. Ce qu'on ne peut pas omettre, c'est l'attribut `type`, les identifiants, et le `source` et le `target` de l'arc : c'est cela, le réseau.

**4.** Cela compte pour un réseau dont les pages sont une *décomposition* — une page par sous-système, jointes par des nœuds de référence, ce qui est la façon dont un gros modèle industriel reste lisible. L'aplatir garde les mathématiques et détruit la seule structure par laquelle un humain pouvait s'y repérer. Cela ne compte pas pour un réseau dont les pages sont une pagination : le même réseau plat coupé sur deux feuilles pour l'impression. L'analyseur ne sait pas distinguer les deux, ce qui est l'argument pour dire qu'il aplatit plutôt que faire semblant de préserver.

</details>

## Sources

- [PNML](https://www.pnml.org/), le site du format, avec les [grammaires RELAX NG](http://www.pnml.org/version-2009/grammar/pnmlcoremodel.rng) libres du modèle de base.
- [ISO/IEC 15909-2:2011](https://www.iso.org/standard/43538.html), *Systems and software engineering — High-level Petri nets — Part 2: Transfer format*, avec la [partie 1](https://www.iso.org/standard/67235.html) pour les concepts et la [partie 3](https://www.iso.org/standard/81504.html) pour les extensions. Les notices ont été vérifiées sur iso.org ; les normes sont payantes et je ne les ai pas lues. *À vérifier.*
- Hillah, Kordon, Petrucci et Trèves, « PNML Framework: An Extendable Reference Implementation of the Petri Net Markup Language », dans *Applications and Theory of Petri Nets 2010*, Springer LNCS 6128, [doi:10.1007/978-3-642-13675-7_20](https://doi.org/10.1007/978-3-642-13675-7_20). Notice confirmée via Crossref ; non lu. *À vérifier.*
- [ePNK](http://www2.imm.dtu.dk/~eki/projects/ePNK/), dont le [lot d'exemples](http://www2.imm.dtu.dk/~eki/projects/ePNK/downloads/ePNK-1.0.0-examples.zip) a fourni les seize fichiers étrangers, sous [EPL-1.0](https://www.eclipse.org/legal/epl-v10.html).
- Le [Model Checking Contest](https://mcc.lip6.fr/), qui fait tourner ces outils les uns contre les autres chaque année sur une collection PNML publique.
- L'implémentation que cette leçon imprime : [`Pnml.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Pnml.cs), avec le lecteur, l'écrivain et les tests, dont celui qui porte la forme piégeuse de l'exemple ISO.
