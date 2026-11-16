---
module_id: phi-008-separate-a-test-oracle-from-a-specification
department: philosophy
course: "Distinguer un oracle de test d’une spécification"
level: intermediate
prerequisites: ["phi-001-how-to-argue-well", "phi-005-test-idempotence-beyond-replayed-values"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguer un oracle de test d’une spécification

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

Un avis Demerzel passe un test de schéma malgré une liste de preuves vide. L’exigence plus large d’un avis justifié est-elle satisfaite ? Le rejeu conservé a réellement consigné cette acceptation pour la révision figée. Il permet de distinguer l’oracle d’un test de la propriété visée par une spécification. Un contrôle vert renseigne seulement sur la condition décidée par son oracle.

[Prérequis: phi-001-how-to-argue-well](../../philosophy/en/phi-001-how-to-argue-well.md); [Prérequis: phi-005-test-idempotence-beyond-replayed-values](../../philosophy/en/phi-005-test-idempotence-beyond-replayed-values.md)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

Définissez une exigence construite : document bien formé et présence d’une référence pertinente liée à une source. Un oracle plus faible ne vérifie que la forme. Ces prédicats servent au tableau pédagogique et ne remplacent pas la gouvernance. Un faux positif est une acceptation alors que l’exigence est fausse ; un faux négatif, un rejet alors qu’elle est vraie. Copier l’implémentation dans la fonction de réponse attendue peut créer un accord en conservant l’erreur commune. Cherchez un contre-exemple indépendant et indiquez l’hypothèse visée. Le contrôle conservé de champ manquant vérifie la forme ; il ne fournit pas le jugement de pertinence absent.

## Cas fixe et hypothèses

```text
cases=["A","B","C","D"]
well_formed=[true,true,false,false]
relevant_evidence=[true,false,true,false]
spec=well_formed AND relevant_evidence
spec_values=[true,false,false,false]
weak_oracle=[true,true,false,false]
true_positive=1; false_positive=1; true_negative=2; false_negative=0
control_missing_required_field: well_formed=false
```

## Exercices corrigés

### Exercice 1

Évaluez la spécification construite pour chaque cas.

> **Réponse:** Le résultat est `[true,false,false,false]`. Des preuves pertinentes ne réparent pas une structure mal formée selon cette conjonction.

### Exercice 2

Repérez le faux positif de l’oracle faible.

> **Réponse:** B respecte la forme mais manque de preuve pertinente. C’est l’unique faux positif ; les autres donnent `1` vrai positif et `2` vrais négatifs.

### Exercice 3

L’acceptation conservée contredit-elle le contrat limité à la forme ?

> **Réponse:** Non. Le schéma autorise le tableau vide. L’erreur consiste à traiter cette acceptation comme preuve suffisante d’un avis justifié au sens plus large.

### Exercice 4

Que teste la suppression d’un champ obligatoire ?

> **Réponse:** Cela fournit un contrôle négatif de forme. Le rejet est attendu, mais ne distingue pas un avis sans preuves d’un avis justifié.

### Exercice 5

Comment un test réussi peut-il partager l’erreur de l’implémentation ?

> **Réponse:** Si les deux utilisent le même prédicat affaibli, l’accord vérifie leur cohérence plutôt que l’exigence visée. Gardez un contre-exemple indépendant et la justification de la spécification.

## Tâche assistée par les sources

Lisez le rejeu et les champs obligatoires. Dressez manuellement un tableau exigence-oracle, en séparant la pertinence inventée des contrôles réels du schéma. Faites justifier le contrôle vert par une aide, puis réfutez toute généralisation avec B. Conservez le résultat étroit qui reste correct.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](../../../../code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Source primaire](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/schemas/advisory-decision.schema.json)
- [Dossier de preuves fixes](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
