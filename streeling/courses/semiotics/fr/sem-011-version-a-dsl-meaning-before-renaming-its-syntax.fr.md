---
module_id: sem-011-version-a-dsl-meaning-before-renaming-its-syntax
department: semiotics
course: "Versionner le sens d’un DSL avant de renommer sa syntaxe"
level: intermediate
prerequisites: ["sem-001-signs-in-governance", "cs-014-compose-brutal-scene-descriptions"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Versionner le sens d’un DSL avant de renommer sa syntaxe

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

Un bloc BRUTAL garde son nom familier mais génère une géométrie différente. Une ancienne instruction conserve-t-elle son sens ? À l’inverse, un jeton renommé peut-il désigner la même opération ? Le modèle figé représente explicitement nom et version. Cette leçon utilise une table d’interprétation finie pour distinguer alias et changement sémantique avant de proposer une réécriture des scènes.

[Prérequis: sem-001-signs-in-governance](../../semiotics/en/sem-001-signs-in-governance.md); [Prérequis: cs-014-compose-brutal-scene-descriptions](../../computer-science/en/cs-014-compose-brutal-scene-descriptions.md)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

Dans l’ancien calcul CPU, deux versions de colonne émettent des nombres de boîtes différents pour un même paramètre. La table fournit un témoin sémantique : un résultat dénoté différent réfute le sens inchangé pour cette entrée. Cela ne prouve ni divergence pour toutes les entrées ni équivalence complète des scènes. Un alias syntaxique conserve le lien à la même version ; relier silencieusement l’ancien jeton à une nouvelle version change l’interprétation. Gardez les deux significations accessibles quand la reproductibilité compte. C’est un argument de migration assisté par les sources, pas un langage exécutable ni un théorème de compatibilité.

## Cas fixe et hypothèses

```text
n=4
meaning_v1(n)=3+2*n; result_v1=11
meaning_v2(n)=3+4*n; result_v2=19
difference=19-11=8
old_token="column@1"; alias="pillar@1"
alias_binding="column@1"; alias_result=11
control_n=0; control_v1=3; control_v2=3
```

## Exercices corrigés

### Exercice 1

Évaluez les deux significations pour l’entrée déclarée.

> **Réponse:** Les résultats sont `11` et `19`, soit `8` boîtes d’écart. Ils viennent de l’ancien calcul figé, pas d’une nouvelle exécution du moteur.

### Exercice 2

L’alias préserve-t-il cette signification choisie ?

> **Réponse:** Oui, s’il pointe vers `column@1`, il donne encore `11`. Un autre jeton affiché peut désigner la même opération versionnée.

### Exercice 3

Reliez silencieusement l’ancien jeton au second sens. La syntaxe conservée suffit-elle ?

> **Réponse:** Non. L’ancien jeton donne maintenant `19` au lieu de `11`. Une graphie inchangée ne garantit pas une dénotation inchangée.

### Exercice 4

Qu’établit le contrôle d’entrée nulle ?

> **Réponse:** Les deux formules donnent `3`. L’égalité sur cette entrée manquerait le changement ; choisissez une entrée admissible discriminante avant de conclure à l’équivalence.

### Exercice 5

Un nombre de boîtes égal établit-il l’équivalence complète des scènes ?

> **Réponse:** Non. Positions, dimensions, matériaux, graine et liens sémantiques peuvent différer. Le nombre est un témoin qui peut réfuter l’équivalence, pas une identité complète.

Le contrôle à entrée nulle est uniquement algébrique ; rien n’affirme qu’il s’agisse d’une requête BRUTAL admissible.

## Tâche assistée par les sources

Lisez BlockId et les anciens nombres de boîtes. Préparez un tableau manuel jeton-version-résultat pour un renommage proposé. Demandez un alias à une aide, puis vérifiez son lien plutôt que sa formulation. Une dénotation modifiée pour une ancienne entrée admissible réfute le renommage préservant le sens.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](../../../../code/streeling/evidence/brutal-composition-2026-10-22/composition-calculations.json)
- [Source primaire](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Model.fs)
- [Dossier de preuves fixes](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
