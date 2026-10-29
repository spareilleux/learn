---
module_id: gaa-011-diagnose-interval-errors-with-a-confusion-table
department: guitar-alchemist-academy
course: "Diagnostiquer les erreurs d’intervalle avec une table de confusion"
level: intermediate
prerequisites: ["gaa-010-define-a-practice-pass-before-counting-success"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Diagnostiquer les erreurs d’intervalle avec une table de confusion

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Un score indique combien de réponses correspondent au corrigé, mais peut masquer les intervalles confondus. Cette distinction change la prochaine question utile que GA devrait proposer. Nous construisons une petite table dont lignes et colonnes restent explicites. Elle diagnostique un motif de réponses inventé, sans prouver qu’une personne a progressé. Le prérequis définissait la réussite d’un essai ; cette leçon conserve le type et le sens des erreurs avant de proposer un travail.

## Lire les preuves conservées

Lire les corrigés ciblés et les règles d’indices du dossier de pratique. Une forme exacte et une famille d’accords y ont des critères différents : la correction dépend de la tâche. La définition factorielle NIST motive la conservation des conditions avant agrégation. Notre table d’intervalles est construite séparément, pas extraite de ce dossier ni observée chez un participant.

[Prérequis](../../guitar-alchemist-academy/en/gaa-010-define-a-practice-pass-before-counting-success.md)

[Artefact de projet conservé](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Dossier construit fixe](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lecture primaire](https://www.itl.nist.gov/div898/handbook/pri/section3/pri333.htm)

### Exercice 1

Les lignes désignent les vraies catégories et les colonnes les réponses, dans l’ordre `[major,minor]`. Les comptes sont `[[3,1],[2,4]]`. La case supérieure droite signifie majeur répondu mineur ; l’inférieure gauche, l’inverse. Afficher l’orientation évite qu’un agent inverse le diagnostic tout en conservant les mêmes nombres.

Combien d’erreurs dans chaque sens ?

<details><summary>Réponse 1</summary>

Il y a `1` erreur majeur vers mineur et `2` erreurs mineur vers majeur. Leur sens dépend de la convention de lignes et colonnes déclarée.

</details>

### Exercice 2

La table contient `10` essais, dont `7` sur la diagonale. L’exactitude vaut `7/10=0.7`. Le dénominateur comprend les essais complets déclarés. Absences, reprises et aides demanderaient des champs séparés ; rien de tel n’est ajouté discrètement. Ce résumé scalaire perd toutefois la distinction entre les directions d’erreur.

Quels sont le total, le nombre correct et l’exactitude ?

<details><summary>Réponse 2</summary>

Ils valent `10`, `7` et `0.7`. Ce sont des descriptions synthétiques, pas la preuve d’un gain d’apprentissage observé.

</details>

### Exercice 3

Les vrais majeurs sont `4`, donnant `3/4=0.75` de rappel. Les vrais mineurs sont `6`, donnant `4/6=2/3`. Répondre toujours la catégorie vraie la plus fréquente donnerait `6/10=0.6`. Dépasser cette référence locale ne prouve ni compétence transférable ni bénéfice causal de la pratique.

Quelle catégorie a le rappel inférieur et quelle est la référence majoritaire ?

<details><summary>Réponse 3</summary>

Le mineur a un rappel de `2/3`, contre `0.75` pour le majeur. La référence majoritaire vaut `0.6` et dépend des effectifs inégaux.

</details>

### Exercice 4

Le contrôle négatif échange le sens des colonnes de réponse, produisant `[[1,3],[4,2]]`. Le total reste `10`, mais les réponses correctes deviennent `3` et l’exactitude `0.3`. Vérifier seulement les effectifs manquerait un dictionnaire de réponses corrompu. Conserver étiquettes et révision du dictionnaire avec le diagnostic de l’agent.

Que change l’échange des étiquettes de réponse ?

<details><summary>Réponse 4</summary>

L’exactitude devient `0.3`, avec rappels `[0.25,1/3]`. Le même nombre d’essais ne certifie pas l’interprétation correcte des colonnes.

</details>

### Exercice 5

La prochaine pratique pourrait cibler la confusion fréquente tout en équilibrant les futurs items et en cachant les indices de réponse. Son intérêt reste une hypothèse à éprouver. Répéter exactement les mêmes sons peut mesurer la mémoire des exemples plutôt que le transfert. Conserver réponses avant retour, aides et conditions d’items nouveaux.

Qu’est-ce qui réfuterait un diagnostic conservant prétendument le sens des erreurs ?

<details><summary>Réponse 5</summary>

Inverser les deux cases hors diagonale ou garder la même exactitude pour le contrôle contredit la table. Un meilleur score futur demanderait encore des conditions comparables avant toute conclusion d’apprentissage.

</details>

## Tâche avec consultation des sources

Construire la table étiquetée à la main, puis calculer exactitude, rappels et référence majoritaire. Inspecter les règles d’indices du dossier et expliquer comment une réponse visible invaliderait un test de rappel. Proposer un prochain item ciblé, son réfutateur et les preuves distinguant reconnaissance d’intervalle et mémorisation d’exemples. Cette fiche n’évalue aucun apprenant réel.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
