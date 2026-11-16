---
module_id: vc-013-keep-triangle-winding-consistent-with-transforms
department: visual-computing
course: "Maintenir la cohérence entre orientation des triangles et transformations"
level: intermediate
prerequisites: ["sem-006-preserve-orientation-across-scene-frames", "phy-008-keep-surface-normals-perpendicular"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Maintenir la cohérence entre orientation des triangles et transformations

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

SEM-006 montrait une face réfléchie dont les indices inchangés contredisaient la convention extérieure. Cette leçon pose une autre question : qui corrige quand la transformation reste sur un nœud ou est incorporée aux sommets ? Corriger les deux séparément peut annuler la correction. Il s’agit de suivre l’orientation, sans prétendre qu’un exportateur ou un import Godot fonctionne.

[Prérequis: sem-006-preserve-orientation-across-scene-frames](../../semiotics/en/sem-006-preserve-orientation-across-scene-frames.md); [Prérequis: phy-008-keep-surface-normals-perpendicular](../../physics/en/phy-008-keep-surface-normals-perpendicular.md)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

La section glTF sur l’instanciation relie l’orientation au déterminant global. Distinguez cette règle du format de notre politique d’incorporation : après une symétrie incorporée, le produit des arêtes ordonnées doit s’aligner sur la référence extérieure transformée. Calculez le déterminant de toute la chaîne linéaire, pas d’une composante. Deux inversions s’annulent. Une permutation cyclique conserve l’orientation ; l’échange d’une paire l’inverse. La translation ne change ni différences d’arêtes ni parité. Une application singulière exige un contrôle géométrique : le déterminant nul interdit la règle inverse des normales sans imposer l’effondrement de chaque triangle.

## Cas fixe et hypothèses

```text
A=(0,0,0); B=(2,0,0); C=(0,3,0)
(B-A) cross (C-A)=(0,0,6)
M=diag(-2,1,1); det(M)=-2
baked_cross=(0,0,-12); outward_reference=(0,0,1)
after_one_index_swap=(0,0,12)
N=diag(-1,1,1); det(M*N)=+2
Z=diag(0,1,1); triangle_cross_after_Z=(0,0,0)
```

## Exercices corrigés

### Exercice 1

Calculez le produit vectoriel initial et l’aire.

> **Réponse:** Le produit vaut `(0,0,6)` et l’aire `3` unités de coordonnées au carré. La norme du produit est le double de l’aire.

### Exercice 2

Incorporez la première transformation. Quelle opération aligne la référence extérieure ?

> **Réponse:** Le produit incorporé est `(0,0,-12)`. Échangez une paire une fois pour obtenir `(0,0,12)`. C’est la politique déclarée, pas une consigne de dupliquer une correction de nœud.

### Exercice 3

Composez les deux échelles réfléchies. La chaîne inverse-t-elle l’orientation ?

> **Réponse:** Non : le déterminant produit est `+2`. Des échanges aveugles sans suivi de la représentation composée risquent une correction redondante.

### Exercice 4

Appliquez le contrôle d’axe nul. Un échange répare-t-il ce triangle ?

> **Réponse:** Son produit devient `(0,0,0)` et son aire `0`. Réordonner ne restaure pas l’aire. Cette conclusion concerne ce triangle précis.

### Exercice 5

Que doit préciser l’adaptateur au-delà de « symétries gérées » ?

> **Réponse:** Nommez transformations conservées et incorporées, règle d’indices, convention extérieure et règle du consommateur. Indiquez l’étape correctrice ; la visibilité réelle reste inobservée.

## Tâche assistée par les sources

Inspectez l’ancien contrôle et la règle glTF. Préparez deux bilans manuels de la même pièce : nœud conservé et géométrie incorporée. Faites expliquer la responsabilité de correction par une aide, puis vérifiez-la. Une double correction ou une prétendue réparation du triangle effondré réfute l’échange.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](../../../../code/streeling/evidence/scene-frames-2026-10-22/orientation-controls.json)
- [Source primaire](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#instantiation)
- [Dossier de preuves fixes](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
