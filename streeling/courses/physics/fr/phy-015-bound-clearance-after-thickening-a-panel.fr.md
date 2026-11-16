---
module_id: phy-015-bound-clearance-after-thickening-a-panel
department: physics
course: "Borner le jeu après épaississement d’un panneau"
level: intermediate
prerequisites: ["phy-005-sheet-thickness-and-scene-units", "phy-011-compute-bend-length-on-a-declared-neutral-layer"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Borner le jeu après épaississement d’un panneau

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

Un panneau IX est représenté par une surface de référence, puis reçoit une épaisseur finie dans une scène proposée. Le jeu initial subsiste-t-il ? Une surface médiane, une face intérieure et une face extérieure conduisent à des intervalles occupés différents. Il faut calculer une borne avant de demander à un adaptateur d’afficher le jeu. Cela ne certifie ni mouvement sans collision ni fabricabilité.

[Prérequis: phy-005-sheet-thickness-and-scene-units](../../physics/en/phy-005-sheet-thickness-and-scene-units.md); [Prérequis: phy-011-compute-bend-length-on-a-declared-neutral-layer](../../physics/en/phy-011-compute-bend-length-on-a-declared-neutral-layer.md)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

Utilisez deux sections de panneaux parallèles infinis, mesurées selon une normale commune. Leurs surfaces de référence restent fixes ; les décalages élargissent les intervalles occupés sans rotation. Soustrayez la borne supérieure du panneau inférieur à la borne inférieure du panneau supérieur. Un jeu positif sépare les intervalles dans ce modèle unidimensionnel. Un jeu négatif indique un chevauchement et zéro un contact, selon la convention d’intervalles fermés. Avec des erreurs bornées, retranchez le déplacement intérieur maximal au jeu nominal. Cette borne déterministe ne représente pas une probabilité de contact et n’exige aucune indépendance aléatoire. Le choix de surface de référence dépasse la simple conversion d’unités.

## Cas fixe et hypothèses

```text
zA=0 mm; zB=3 mm; tA=2 mm; tB=2 mm
A=[-1,1] mm; B=[2,4] mm; c=2-1=1 mm
eA=0.3 mm; eB=0.4 mm; c_min=1-0.3-0.4=0.3 mm
tA2=3 mm; tB2=3 mm; c2=3-1.5-1.5=0 mm
A_one_side=[0,2] mm; B_one_side=[3,5] mm; c_one_side=1 mm
```

## Exercices corrigés

### Exercice 1

Trouvez le jeu nominal pour une épaisseur centrée.

> **Réponse:** Les intervalles sont `[-1,1] mm` et `[2,4] mm`, soit `1 mm` de jeu. La distance des surfaces de référence surestime l’espace restant.

### Exercice 2

Appliquez les deux bornes d’erreur vers l’intérieur.

> **Réponse:** Le jeu minimal est `0.3 mm`. On retranche la somme des déplacements défavorables ; aucune distribution ni probabilité de contact n’est déduite.

### Exercice 3

Épaississez les deux panneaux centrés selon la seconde valeur.

> **Réponse:** Le jeu nominal est `0 mm`. Les mêmes erreurs permettent `-0.7 mm` ; l’affirmation d’un jeu garanti positif échoue.

### Exercice 4

Utilisez les intervalles unilatéraux indiqués. Toute convention doit-elle changer ce jeu à épaisseurs égales ?

> **Réponse:** Non : le décalage unilatéral commun donne encore `1 mm`. Ce contrôle empêche de prétendre qu’un changement de référence modifie toujours le jeu. Des décalages inégaux peuvent le modifier.

### Exercice 5

La borne prouve-t-elle un chemin de pliage dégagé ?

> **Réponse:** Non. Elle décrit des intervalles parallèles fixes. Les bords finis, les angles variables, les tolérances hors bornes et le mouvement exigent des données distinctes.

## Tâche assistée par les sources

Repérez surfaces de référence et unités de scène dans le prérequis et le repère figé. Fournissez les intervalles occupés et le jeu défavorable dans un échange IX proposé. Gardez un croquis manuel comme référence. Un déplacement intérieur autorisé rendant le jeu promis non positif réfute la garantie.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](../../../../code/streeling/evidence/scene-frames-2026-10-22/orientation-controls.json)
- [Source primaire](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Space.fs)
- [Dossier de preuves fixes](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
