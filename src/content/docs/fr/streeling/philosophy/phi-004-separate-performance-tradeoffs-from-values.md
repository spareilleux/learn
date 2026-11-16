---
title: Distinguer les compromis de performance des valeurs
description: Distinguer les compromis de performance des valeurs — Philosophie
sidebar:
  label: PHI-004 · Distinguer les compromis de performance des valeurs
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/philosophy/fr/phi-004-separate-performance-tradeoffs-from-values.fr.md
---

:::note[Streeling University]
**PHI-004** · Distinguer les compromis de performance des valeurs · intermédiaire · 35 minutes

Généré par le département *Philosophie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/philosophy/fr/phi-004-separate-performance-tradeoffs-from-values.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHI-001](../../philosophy/phi-001-how-to-argue-well/)
:::

> **Périmètre du brouillon.** Tables d’attributs et calculs de décision construits pour le cours, motivés par des rapports du projet figés à une révision précise. La revue technique humaine, la révision linguistique par une personne maîtrisant la langue, les essais apprenants, le recueil des préférences des utilisateurs et la vérification du HTML déployé restent à faire. Aucun score de détail ni aucune latence de cette table ne constitue un résultat produit mesuré.

## La question du projet

Un agent de l’Observatoire affirme que sa politique de rendu la plus rapide ou la plus détaillée est « la meilleure ». Pour qui, selon quelles priorités et sous quelles contraintes ? L’[article sur la théorie de la décision de la Stanford Encyclopedia of Philosophy](https://plato.stanford.edu/entries/decision-theory/) distingue les croyances et les valeurs qui interviennent dans un choix et discute des critères normatifs de décision. Un classement numérique exige des hypothèses sur ce qui compte autant que sur les conséquences. Cette leçon rend visible une de ces hypothèses ; elle n’adopte pas l’utilité espérée comme théorie éthique complète.

L’[évaluation historique de BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md) motive cette question, car un moteur de rendu supplémentaire et une tâche interactive voisine partagent des ressources. L’identité du code source et du rapport historique ne détermine pas la pondération à donner aux intérêts de leurs utilisateurs. Nos exemples ci-dessous sont construits indépendamment ; ce ne sont ni des évaluations extraites de la qualité des images ni des pénalités mesurées.

## 1. Énoncer les attributs avant de les réduire à un score

Considérons quatre réglages hypothétiques. D est un score de détail construit, en points, dont on préfère les valeurs élevées. O est un surcoût construit ajouté à une tâche voisine, en millisecondes, dont on préfère les valeurs faibles. Supposons que ces attributs résument ce que ce calcul prend en compte ; ils ne couvrent pas nécessairement tout ce qui compte pour un utilisateur réel.

| Réglage | D : points de détail | O : surcoût de la tâche voisine en ms |
| --- | --- | --- |
| L | 70 | 2 |
| B | 85 | 5 |
| H | 95 | 12 |
| W | 70 | 8 |

Deux questions sont distinctes. Le travail empirique demanderait quelles conséquences résultent réellement d’un réglage dans des conditions déclarées. Le raisonnement sur les valeurs demanderait quelles conséquences sont acceptables ou préférables et quels intérêts la décision représente. Une mesure future peut améliorer la première réponse sans trancher la seconde.

### Exercice pratique 1 : révéler l’hypothèse manquante

Un agent choisit H uniquement parce que 95 est le score de détail le plus élevé. Quelle préférence suppose-t-il et quel type d’élément probant manque encore dans cette table ?

> **Réponse :** Il considère que le détail suffit à déterminer le choix, en négligeant le coût pour la tâche voisine et d’autres contraintes possibles. La table contient en outre des attributs construits, pas des conséquences réellement mesurées ni des préférences recueillies. Même des mesures exactes ne détermineraient pas à elles seules quelles priorités doivent gouverner la décision.

## 2. Utiliser la dominance pour réduire un ordre partiel

Pour ces deux attributs, une option en domine une autre si elle offre au moins autant de détail et aucun surcoût supplémentaire, avec une amélioration stricte pour au moins un attribut. L domine W : les deux ont 70 points de détail, mais le surcoût est de 2 plutôt que de 8 ms. B domine également W, avec 85 points pour 5 ms. L, B et H restent non dominés, car gagner du détail exige davantage de surcoût.

![Options hypothétiques de détail et de surcoût pour la tâche voisine](https://raw.githubusercontent.com/spareilleux/learn/218a2bffc18fe2251956197e882cb6c7ea5d7962/code/streeling/evidence/observatory-decisions-2026-10-22/two-attribute-options.png)

Le graphique présente les options construites, avec une préférence pour un D élevé et un O faible. Sa frontière en pointillés, à O égal à 6 ms, servira plus loin de contrainte hypothétique. La dominance ne fournit pas de classement total des options restantes et un attribut omis pourrait changer la comparaison avec W.

### Exercice pratique 2 : distinguer l’élimination de la sélection

Quelles options dominent W et quelles options sont non dominées ? Ce résultat sélectionne-t-il de manière unique un réglage pour un utilisateur réel ?

> **Réponse :** L et B dominent W selon les deux attributs énoncés. L, B et H sont non dominés. Cela réduit les options sans choisir de manière unique entre elles ni établir les préférences d’utilisateurs réels. La conclusion se limite aux attributs déclarés et à leurs valeurs construites.

## 3. Expliciter l’unité d’un poids de compromis

Supposons un score linéaire `U=D-lambda*O`. Ici, lambda s’exprime en **points de détail par milliseconde**. Ce choix suppose un taux d’échange constant et traite D comme une échelle cardinale sur laquelle les opérations arithmétiques ont un sens. Une simple note ordinale numérotée ne justifierait pas cette hypothèse.

| Poids en points par ms | Score L | Score B | Score H | Score W | Score le plus élevé |
| --- | --- | --- | --- | --- | --- |
| 0.5 | 69 | 82.5 | 89 | 66 | H |
| 2 | 66 | 75 | 71 | 54 | B |
| 6 | 58 | 55 | 23 | 22 | L |

Rien dans la table des attributs ne sélectionne l’un de ces poids. Selon la règle supposée, H et B sont à égalité pour lambda `10/7` ; B et L sont à égalité pour lambda 5. Ces frontières décrivent le modèle énoncé, pas des priorités objectivement correctes.

### Exercice pratique 3 : révéler une erreur d’unité

Avec lambda égal à 2 points par milliseconde, B l’emporte. Les valeurs de surcoût sont converties en secondes. Quel poids préserve le classement ? Que se passe-t-il si l’agent conserve la valeur numérique 2 sans modifier son unité ?

> **Réponse :** Utilisez 2000 points par seconde pour conserver le même compromis et le score de 75 de B. Garder 2 points par seconde rend la pénalité mille fois plus faible et sélectionne H à la place. C’est une modification du modèle de valeur due à une erreur d’unité, pas une nouvelle preuve que les utilisateurs préfèrent H.

## 4. Maintenir une contrainte stricte hors du score compensatoire

Imposons maintenant une limite construite : le surcoût doit être inférieur ou égal à 6 ms. L et B sont admissibles ; H et W sont exclus avant le calcul des scores. Avec un poids de 0.5, le meilleur score sans contrainte est celui de H, mais le meilleur score admissible est celui de B. Selon cette règle de décision, un gain important de détail ne peut pas compenser le franchissement d’une contrainte stricte.

Cette limite est une nouvelle hypothèse de valeur. Elle ne provient ni du seuil du contrôleur source ni d’une obligation produit existante. [CYB-005](../../cybernetics/cyb-005-stop-render-policy-flapping/) utilise une autre grandeur, le temps GPU par image ; confondre ce capteur avec le surcoût ajouté à la tâche voisine mélangerait à la fois le sens des mesures et la finalité de la décision.

### Exercice pratique 4 : vérifier l’admissibilité avant de classer

Avec la limite stricte hypothétique de 6 ms et le poids de 0.5, quel réglage est sélectionné ? Un agent peut-il réintroduire H en calculant discrètement une moyenne entre son dépassement et d’autres cas satisfaisants ?

> **Réponse :** B est sélectionné parmi les options admissibles L et B. H enfreint la limite stricte et ne peut pas redevenir admissible grâce à son score supérieur ou à la moyenne d’autres cas selon la règle énoncée. Modifier la contrainte exigerait un changement explicite et justifié des hypothèses de décision, pas un ajustement arithmétique caché.

## 5. Distinguer un modèle transparent d’une décision légitime

Un poids explicite rend un compromis examinable. Il ne démontre ni que les utilisateurs concernés l’ont accepté, ni que le score couvre l’accessibilité ou la vie privée, ni que l’agent a autorité pour imposer le résultat. Optimiser une préférence individuelle ne constitue pas automatiquement une allocation acceptable d’une machine partagée. Inversement, l’objection d’une autre partie prenante ne se réduit pas à un bruit de mesure à éliminer par lissage.

L’objection la plus forte à ce modèle simple est l’hypothèse selon laquelle tous les intérêts pertinents peuvent être représentés par deux attributs cardinaux et un taux d’échange constant. Une solution pratique plus simple consiste à demander une plage de fonctionnement acceptable, à comparer un petit ensemble d’options admissibles et à conserver un choix réversible tout en recueillant des éléments pertinents. Rejetez le modèle linéaire si des préoccupations omises ou des choix observés contredisent systématiquement le classement qu’il est censé représenter.

### Exercice pratique 5 : rédiger une recommandation justifiée

Un agent affirme : « le benchmark prouve que B est éthiquement correct ». Remplacez cette affirmation par une recommandation qui énonce ses limites empiriques, ses hypothèses de valeur et ses limites d’autorité.

> **Réponse :** Avec les attributs construits, le score linéaire supposé de poids 2 sélectionne B ; avec la contrainte construite de 6 ms, B est aussi la meilleure option admissible pour un poids de 0.5. Ces calculs n’établissent ni des résultats réels de benchmark ni une obligation éthique. Une recommandation réelle exige des conséquences mesurées, des priorités et contraintes explicites des parties prenantes, la prise en compte des intérêts omis et une autorité appropriée pour effectuer le changement.

Le [relevé de compromis figé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/observatory-decisions-2026-10-22/value-tradeoffs.json) conserve les scores, les égalités, les relations de dominance et le contrôle de l’erreur d’unité. [FUT-004](../../futurology/fut-004-scenario-test-an-observatory-renderer/) fait varier séparément les croyances sur les conditions futures. Aucune des deux leçons ne modifie un moteur de rendu, ne ratifie une politique ni ne consigne les préférences d’un participant.
