---
module_id: phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh
department: physics
course: "Préserver les hypothèses de masse lors du redimensionnement d’un maillage"
level: intermediate
prerequisites: ["phy-005-sheet-thickness-and-scene-units"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Préserver les hypothèses de masse lors du redimensionnement d’un maillage

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

Une scène artisanale double en largeur et en hauteur. Sa masse doit-elle doubler, quadrupler ou être multipliée par huit ? Cela dépend du redimensionnement de l’épaisseur et du maintien de la densité ou de la masse totale. Le modèle BRUTAL inspecté décrit boîtes, transformations et surfaces ; ce ne sont pas des mesures de densité. Cette leçon ajoute un bilan de masse au raisonnement géométrique sans transformer un nom de matériau visuel en spécification physique.

[Prérequis: phy-005-sheet-thickness-and-scene-units](../../physics/en/phy-005-sheet-thickness-and-scene-units.md)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

Supposons une feuille rectangulaire homogène, sans trou, d’épaisseur constante et de densité uniforme stipulée. Son volume est le produit des dimensions et sa masse le produit de la densité par le volume. Multiplier toutes les dimensions par un même facteur élève ce facteur au cube pour le volume. Agrandir seulement les dimensions planes l’élève au carré. Ce sont des modèles alternatifs d’une modification du maillage, pas des observations concurrentes. Une troisième règle peut conserver la masse totale, mais la densité implicite change alors si le volume change. Le dossier expose cette incompatibilité avant de proposer le transfert de paramètres physiques.

## Cas fixe et hypothèses

```text
w=0.20 m; h=0.10 m; t=0.001 m; rho=800 kg/m^3
V=w*h*t=0.00002 m^3; m=rho*V=0.016 kg
s=2
V_all=s^3*V=0.00016 m^3; m_all=0.128 kg
V_planar=s^2*V=0.00008 m^3; m_planar=0.064 kg
rho_fixed_mass=0.016/0.00016=100 kg/m^3
```

## Exercices corrigés

### Exercice 1

Calculez la masse initiale.

> **Réponse:** Le volume est `0.00002 m^3` ; la densité donne `0.016 kg`, soit `16 g`. Les valeurs matérielles sont stipulées.

### Exercice 2

Redimensionnez toutes les dimensions. Quel est le rapport des masses ?

> **Réponse:** Le rapport est `8` ; la masse devient `0.128 kg`. L’épaisseur participe à cet agrandissement géométrique.

### Exercice 3

Conservez l’épaisseur de la feuille en agrandissant son plan.

> **Réponse:** La masse est multipliée par `4` et atteint `0.064 kg`. Ce contrôle négatif réfute l’emploi automatique du facteur cubique.

### Exercice 4

Conservez la masse après agrandissement complet. Quelle densité en découle ?

> **Réponse:** Cela implique `100 kg/m^3`, soit un huitième de la densité initiale. Densité fixe et masse fixe sont incompatibles avec ce changement de volume.

### Exercice 5

Le nom de surface pierre justifie-t-il la densité ?

> **Réponse:** Non. Le descripteur fournit une catégorie de rendu. La densité numérique est une hypothèse rédigée ; une affirmation physique exige une justification matérielle distincte.

## Tâche assistée par les sources

Inspectez les définitions de taille et de surface du modèle figé. Annotez une scène agrandie avec une règle d’épaisseur choisie et une hypothèse de densité distincte. Comparez le bilan manuel de volume à un résumé d’agent. Rejetez celui-ci s’il conserve à la fois densité et masse totale malgré l’augmentation du volume.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](../../../../code/streeling/evidence/brutal-composition-2026-10-22/composition-calculations.json)
- [Source primaire](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Model.fs)
- [Dossier de preuves fixes](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
