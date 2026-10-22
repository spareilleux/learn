---
module_id: dv-003-instrument-cohorts-and-units
department: data-visualization
course: Comparer les cohortes d'instruments sans masquer leurs effectifs
level: beginner
prerequisites: [dv-002-denominators-and-test-populations]
estimated_duration: "30 minutes"
produced_by: codex-project-pilot
research_cycle: data-visualization-2026-10-11-003
version: "0.1.0"
---

# Comparer les cohortes d'instruments sans masquer leurs effectifs

> **Département de visualisation des données** | Niveau : débutant | Durée estimée : 30 minutes | Statut : brouillon de traduction ; relecture humaine du fond, relecture linguistique par une personne maîtrisant le français et essai par un apprenant en attente

Données pour les exercices hors ligne : [six instantanés GA figés](../../../../code/streeling/fixtures/data-visualization/historical-ga/README.md). Ces données sont historiques ; le comportement actuel du service n'est pas évalué.

## Objectifs

À la fin de ce cours, vous saurez :

- présenter les effectifs des corpus de guitare, de basse et d'ukulélé sans masquer les petits groupes ;
- déterminer si une métrique compte des voicings, des ensembles de classes de hauteurs ou un représentant par instrument ;
- expliquer la portée du résultat de cohérence entre instruments de GA sans en faire une affirmation de qualité par instrument ;
- concevoir une comparaison qui distingue les résultats observés des mesures que GA n'a pas enregistrées.

## La question du projet

L'[instantané d'analyse des voicings GA du 23 juillet 2026](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/voicing-analysis/2026-07-23.json), épinglé au commit [`dc2e74c`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924), indique un corpus de 313,047 voicings et une métrique de cohérence entre instruments de 100%. Une personne qui consulte le tableau de bord demande : « Cela prouve-t-il que les accords sont aussi bien nommés à la guitare, à la basse et à l'ukulélé ? » La réponse dépend de ce que compte chaque nombre.

| Cohorte du corpus | Voicings | Part de tous les voicings |
|---|---:|---:|
| Guitare | 297,910 | 95.16% |
| Basse | 7,795 | 2.49% |
| Ukulélé | 7,342 | 2.35% |
| **Total** | **313,047** | **100.00%** |

Ce sont les effectifs d'un audit historique, et non un catalogue en direct ni une population d'utilisateurs. Les proportions sont calculées à partir des champs `Corpus` de l'instantané et arrondies à deux décimales.

### Exercice

Vérifiez le total et rédigez une légende de graphique qui rende le déséquilibre visible.

> **Réponse :** `297,910 + 7,795 + 7,342 = 313,047`. Une légende défendable serait : « Audit historique des voicings GA : 313,047 voicings générés ; la guitare représente 95.16%, la basse 2.49% et l'ukulélé 2.35%. »

## 1. L'effectif d'une cohorte n'est pas un taux d'erreur

Une cohorte est le groupe que l'on compare. Ici, la section `Corpus` compte les voicings par instrument. Un diagramme en barres peut comparer ces **effectifs**. Il ne peut pas comparer l'exactitude musicale des noms par instrument, car l'instantané ne contient pas, pour chaque voicing, un nom correct jugé indépendamment. Le même fichier indique les valeurs globales `UnknownChordName.Count: 0` et `NullChordName.Count: 0`. Puisque les effectifs des trois instruments partitionnent ce corpus audité, zéro au total implique zéro nom nul ou inconnu dans chaque cohorte pour cette exécution. Cela n'établit pas que chaque nom non nul est musicalement correct.

Si le graphique utilise un axe de pourcentages, précisez s'il montre une part de tous les voicings ou un taux interne à chaque instrument. « Basse : 2.49% » est une part du corpus ; « taux d'erreur de dénomination à la basse : 2.49% » serait une affirmation inventée. Il faut aussi indiquer l'effectif brut d'une petite cohorte à côté de tout taux futur. Une erreur parmi 7,342 voicings d'ukulélé modifierait davantage le taux qu'une erreur parmi 297,910 voicings de guitare.

### Exercice

Un tableau de bord étiquette trois barres « Qualité guitare 95.16%, qualité basse 2.49%, qualité ukulélé 2.35% ». Quel est le problème, et que peuvent légitimement montrer les barres ?

> **Réponse :** Les nombres sont des parts du corpus audité, et non des scores de qualité. Renommez les barres « part des voicings » et indiquez 297,910, 7,795 et 7,342. L'audit permet de conclure à zéro nom nul ou inconnu dans chaque cohorte, mais une affirmation plus large d'exactitude nécessite des étiquettes jugées indépendamment.

## 2. La métrique de cohérence compte des ensembles partagés

Le même instantané indique `CrossInstrumentConsistency.SharedSets: 793` et `Consistent: 793`. Sa valeur de 100% représente `793 / 793` **ensembles de classes de hauteurs partagés**, et non `313,047 / 313,047` voicings. Dans l'[implémentation épinglée de l'audit](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Demos/VoicingAnalysisAudit/Program.cs), l'audit conserve le premier nom canonique d'accord rencontré par instrument pour un masque de classes de hauteurs, sélectionne les masques observés sur au moins deux instruments et vérifie si ces noms conservés concordent. Le code utilise le nom canonique lorsqu'il est disponible, car une basse notée après une barre oblique, propre au voicing, peut légitimement différer selon les instruments.

C'est une **vérification utile de cohérence des noms entre instruments pour les représentants conservés**. Sa portée est plus étroite que « chaque voicing a été nommé correctement » ou « les trois instruments ont le même taux d'erreur ». Un graphique ne doit pas associer le numérateur de 793 ensembles au dénominateur de 313,047 voicings. De plus, le fichier ne répartit pas les 793 ensembles entre les groupes guitare–basse, guitare–ukulélé, basse–ukulélé ou les trois instruments ; on ne peut donc pas en tirer des taux par paire.

### Exercice

Évaluez le titre « 100% des 313,047 voicings concordent entre les trois instruments ». Remplacez-le par une affirmation étayée.

> **Réponse :** Le titre change l'unité et suppose que les trois instruments participent à chaque comparaison. Une affirmation étayée serait : « L'audit a trouvé des noms canoniques conservés concordants pour les 793 ensembles de classes de hauteurs observés sur au moins deux instruments. » Ajoutez qu'il utilise le premier nom rencontré par instrument et ne compare pas tous les voicings deux à deux.

## 3. Donner deux vues et deux dénominateurs

Consacrez une vue à la composition du corpus : une barre horizontale par instrument, avec les nombres exacts de voicings et les parts. Utilisez une autre vue pour le test de cohérence : « 793 / 793 ensembles de classes de hauteurs partagés cohérents (100%) ». Placez la note méthodologique près du second résultat, et non dans une infobulle cachée. Un tableau constitue une solution accessible pour remplacer les deux graphiques.

Évitez un unique badge vert « qualité 100% ». Il mélangerait une vérification de concordance au niveau des ensembles et des métriques de complétude par voicing, et pourrait masquer le rapport d'effectifs de 38 pour 1 entre les corpus de guitare et de basse. Les deux vues répondent à des questions différentes : « Que comprenait l'audit ? » et « Qu'a trouvé cette vérification précise de concordance ? » Aucune ne dit si un voicing est facile à jouer ou si un guitariste aime sa sonorité.

### Exercice

Rédigez une alternative textuelle de deux lignes pour ces vues. Incluez les deux dénominateurs et une limite.

> **Réponse :** « L'audit historique contient 297,910 voicings de guitare, 7,795 de basse et 7,342 d'ukulélé. Les noms conservés concordent pour 793 ensembles de classes de hauteurs sur 793 observés sur au moins deux instruments ; l'instantané ne mesure pas l'exactitude musicale des noms par instrument au moyen d'une relecture indépendante. »

## 4. Concevoir la prochaine mesure utile

Pour comparer équitablement l'**exactitude musicale des noms** par instrument, une évaluation future enregistrerait `instrument`, `voicing_id`, `pitch_class_mask`, `canonical_name`, une étiquette de référence relue indépendamment, un verdict de concordance et la révision de l'audit/du corpus pour chaque résultat évalué. Divisez ensuite les discordances de chaque instrument par son propre nombre de voicings **relus**, et non par tous les voicings générés, sauf s'ils ont tous été relus. Indiquez l'incertitude, ou au moins les nombres exacts pour les petites cohortes. Pour des comparaisons appariées entre instruments, conservez chaque observation pertinente plutôt que le seul premier nom de chaque masque et instrument ; définissez à l'avance si l'unité est un voicing, un ensemble ou une paire d'instruments.

Il s'agit d'un contrat de mesure proposé, et non d'une affirmation que GA produit déjà ces étiquettes relues. Distinguez-le de l'instantané historique. Les nombres globaux nuls de noms nuls/inconnus sont utiles et s'appliquent bien à chaque cohorte de cette partition exhaustive ; ils ne vérifient toujours pas qu'un nom non nul est correct ni qu'un voicing est jouable, utile ou agréable à entendre.

### Exercice

Proposez un champ et un dénominateur nécessaires à un taux de **discordance musicale des noms** propre à la basse. Précisez une question à laquelle ce taux ne répondrait toujours pas.

> **Réponse :** Enregistrez un nom de référence relu et un verdict de concordance pour chaque voicing de basse évalué ; divisez les discordances par le nombre de **voicings de basse relus**. Le corpus historique compte 7,795 voicings de basse, mais ce nombre n'est le dénominateur que si les 7,795 font tous l'objet d'une relecture. Le taux de discordance ne déterminerait pas si les bassistes trouvent ces positions jouables ou utiles.

## À retenir

- Montrez les effectifs des cohortes d'instruments avant de comparer les résultats.
- Nommez l'unité d'analyse près de chaque numérateur et dénominateur.
- `793 / 793` ensembles partagés n'est pas un taux d'exactitude par voicing ou par instrument.
- L'audit conserve un nom canonique par instrument et masque de classes de hauteurs pour cette vérification de cohérence.
- Distinguez les nombres nuls de noms nuls/inconnus déduits de l'exactitude musicale des noms qui n'a pas été mesurée.

## Sources et éléments du projet

- GA : [instantané historique d'analyse des voicings](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/voicing-analysis/2026-07-23.json) et [implémentation épinglée de l'audit](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Demos/VoicingAnalysisAudit/Program.cs).
- [DV-002](dv-002-denominators-and-test-populations.md) pour l'agrégation pondérée et les changements de cohorte.

*Recherche : `data-visualization-2026-10-11-003`. Brouillon de traduction ; relecture humaine du fond, essai par un apprenant, relecture linguistique par une personne maîtrisant le français et vérification publique en attente.*
