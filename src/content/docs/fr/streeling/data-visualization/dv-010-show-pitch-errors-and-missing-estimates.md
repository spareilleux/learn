---
title: Afficher les erreurs de hauteur et les estimations manquantes
description: Afficher les erreurs de hauteur et les estimations manquantes — Visualisation de données
sidebar:
  label: DV-010 · Afficher les erreurs de hauteur et les estimations manquantes
  order: 10
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/fr/dv-010-show-pitch-errors-and-missing-estimates.fr.md
---

:::note[Streeling University]
**DV-010** · Afficher les erreurs de hauteur et les estimations manquantes · intermédiaire · 40 minutes

Généré par le département *Visualisation de données* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/fr/dv-010-show-pitch-errors-and-missing-estimates.fr.md) · [Mon journal](../../journal/)

Prérequis: [DV-003](../../data-visualization/dv-003-instrument-cohorts-and-units/), [DV-009](../../data-visualization/dv-009-compare-spectrogram-color-scales/)
:::

> **Portée du brouillon.** Tableau diagnostique original de six lignes et graphique scientifique, accompagnés d’une analyse limitée de guitare conservée, utilisée séparément. Les revues humaines technique et linguistique, les essais apprenants et la vérification du HTML déployé restent à faire. Les lignes représentées sont créées pour l’exercice ; ce ne sont ni des données de participants ni une véritable courbe de hauteur de guitare.

## La question du projet

Un tableau de bord de hauteur trace une ligne nette parce qu’il remplace les valeurs manquantes par zéro, retire une valeur aberrante à l’octave et ne rapporte l’exactitude que lorsque le détecteur a répondu. Un tel affichage peut cacher précisément les échecs qu’une boucle d’amélioration audio doit examiner. Cette leçon garde distincts la disponibilité, l’erreur et le dénominateur.

Le [tableau complet créé pour l’exercice](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-estimates-2026-10-22/pitch-trace.json) utilise une référence de 100 Hz. Il est volontairement distinct de la véritable analyse conservée de E2 dans [GAS-005](../../guitar-acoustics/gas-005-separate-a-partial-peak-from-a-period/). Ne mélangez pas leurs références et ne présentez pas ce tableau comme une nouvelle mesure du moteur.

## 1. Rendre explicites les lignes indisponibles

| Temps créé pour l’exercice, secondes | Fréquence rapportée, Hz | État |
| --- | --- | --- |
| 0 | 100 | rapportée |
| 0.1 | 200 | rapportée |
| 0.2 | absente | manquante |
| 0.3 | 100.5 | rapportée |
| 0.4 | 0 | entrée invalide |
| 0.5 | 99.5 | rapportée |

Il y a quatre résultats positifs et finis, une ligne manquante et une entrée nulle invalide. Les états manquant et invalide sont deux états diagnostiques distincts. Aucun ne devient une estimation valide de fréquence nulle, une erreur nulle en cents ou une observation interpolée. Le filtrage pour une métrique n’est acceptable que si les états exclus et le dénominateur restent visibles.

### Exercice 1 : conserver les deux états indisponibles

Combien de lignes permettent un calcul logarithmique de l’erreur de fréquence ? Pourquoi ne faut-il pas afficher la ligne manquante et l’entrée nulle comme deux erreurs nulles en cents ?

> **Réponse:** Quatre lignes permettent ce calcul. La ligne manquante n’a pas de fréquence, tandis que l’entrée nulle est invalide pour le logarithme d’une fréquence positive. Placer l’une ou l’autre à zéro cent affirmerait à tort qu’une estimation valide correspond exactement à la référence. Gardez leurs états visibles sans inventer de valeurs numériques de hauteur.

## 2. Convertir un rapport de fréquences dans une unité d’erreur déclarée

Pour une fréquence rapportée valide f et une référence positive, définissez l’erreur signée par `1200*log2(f/reference)`. Cela donne 0 cent à 100 Hz et +1200 à 200 Hz. Les lignes à 100.5 et 99.5 Hz donnent respectivement environ +8.634601685 et -8.677883077 cents. Des écarts additifs égaux en Hz autour de la référence ne sont pas exactement symétriques sur une échelle logarithmique.

Le graphique original conserve les quatre erreurs valides, y compris la valeur aberrante à l’octave, et place la disponibilité dans un panneau catégoriel séparé. Il n’y a ni segments reliant les hauteurs, ni barres d’erreur inventées, ni estimations interpolées. Le [registre des points du graphique](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-estimates-2026-10-22/plot-points.json) relie les lignes sous-jacentes à l’image.

![Erreurs en cents créées pour l’exercice, avec la valeur aberrante à l’octave conservée et les états manquant et invalide affichés séparément](https://raw.githubusercontent.com/spareilleux/learn/c953607dc38126877032dd5919e57d894971b257/code/streeling/evidence/pitch-estimates-2026-10-22/pitch-errors-and-availability.png)

L’unique figure aux étiquettes anglaises est une illustration mathématique originale ; le texte localisé qui l’entoure explique ses grandeurs. Les positions verticales de ses catégories ne sont pas des mesures d’erreur de hauteur. L’étendue verticale complète inclut le point à +1200 cents, même si cela comprime le groupe des petites erreurs.

### Exercice 2 : interpréter le point à l’octave

Calculez l’erreur de 200 Hz par rapport à 100 Hz. Un agent doit-il la diviser silencieusement par 2 ou la supprimer pour donner une apparence stable à la courbe ?

> **Réponse:** `1200*log2(200/100)=1200` cents. Diviser par 2 ou retirer la ligne changerait les données ou la convention d’évaluation. Une métrique insensible à l’octave, déclarée séparément, peut répondre à une autre question, mais elle ne doit pas remplacer silencieusement le résultat affiché sensible à l’octave. Conservez le point et expliquez toute vue supplémentaire.

## 3. Comparer les résumés sans changer secrètement d’échelle

La moyenne arithmétique des quatre fréquences valides vaut 125 Hz, dont l’erreur en cents est d’environ 386.313713865. La moyenne de leurs erreurs signées en cents vaut plutôt environ 299.989179652 cents ; la fréquence moyenne géométrique correspondante vaut environ 118.919968239 Hz. Ce sont des opérations différentes. L’erreur signée médiane vaut environ 4.317300843 cents, tandis que l’erreur absolue maximale reste de 1200 cents.

Une petite médiane peut coexister avec une grande valeur aberrante à l’octave. Dans un autre jeu de données, la moyenne des erreurs signées peut aussi masquer des compensations. Choisissez un résumé pour une question déclarée et conservez la distribution ou les échecs pertinents. Aucun de ces résumés de quatre lignes ne fournit un intervalle de confiance ou un verdict général sur la qualité du détecteur.

### Exercice 3 : repérer le changement d’agrégation

Pourquoi la conversion de la fréquence moyenne et la moyenne des cents signés donnent-elles des réponses différentes ? Quelle paire de statistiques rapportées montre qu’une petite médiane ne supprime pas un grand échec ?

> **Réponse:** Le logarithme est non linéaire : calculer la moyenne arithmétique avant le logarithme diffère de la moyenne des rapports logarithmiques. Ici, la moyenne arithmétique convertie vaut environ 386.313713865 cents, tandis que la moyenne des erreurs signées vaut environ 299.989179652 cents. Une médiane d’environ 4.317300843 et une erreur absolue maximale de 1200 coexistent ; la médiane n’efface pas l’échec à l’octave.

## 4. Publier la disponibilité avec le dénominateur de l’exactitude

Selon la règle créée pour l’exercice d’un écart d’au plus 10 cents, trois des quatre résultats valides réussissent. L’exactitude conditionnelle est donc `3/4`, soit 75%. La couverture est de `4/6`, environ 66.666666667%. Un critère conjoint exigeant un résultat disponible, valide et dans la tolérance réussit sur `3/6`, soit 50% de toutes les lignes. Ces trois pourcentages répondent à des questions différentes.

La règle conjointe compte les lignes manquantes et invalides comme ne satisfaisant pas cette condition de réussite combinée. Elle ne les transforme pas en erreurs numériques de hauteur. Déclarez la règle avant de comparer les méthodes ; sinon, s’abstenir plus souvent peut améliorer l’apparence d’un affichage uniquement conditionnel sans améliorer la tâche de son destinataire.

### Exercice 4 : révéler le dénominateur omis

Un tableau de bord annonce « 75% d’exactitude » et cache les lignes indisponibles. Donnez la couverture, le résultat conditionnel et le résultat conjoint, et expliquez le contenu de chaque dénominateur.

> **Réponse:** La couverture est de `4/6`, environ 66.666666667%, sur toutes les lignes. L’exactitude conditionnelle est de `3/4`, soit 75%, sur les seuls résultats valides. La réussite conjointe est de `3/6`, soit 50%, sur toutes les lignes selon la règle déclarée de disponibilité et de tolérance. Ce sont des statistiques du jeu créé pour l’exercice, pas des performances mesurées en déploiement ou auprès d’auditeurs.

## 5. Garder un score de signal hors de la légende de confiance

Dans les [fenêtres de guitare conservées](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-estimates-2026-10-22/native-pitch-windows.json), utilisées séparément, quatre scores de récurrence dépassent 0.999 tandis qu’aucune estimation ne réussit le contrôle choisi à 5 cents de la référence nominale. Une légende annonçant « 99.9% de probabilité de hauteur correcte » inventerait un étalonnage. De même, la variation entre fenêtres adjacentes n’est pas automatiquement un intervalle de confiance.

L’objection la plus forte à un affichage diagnostique détaillé est son coût de lecture. Un résumé plus simple peut montrer la couverture, un critère d’erreur déclaré et un lien vers les lignes et la figure complètes. Ne le jugez pas suffisant s’il cache des échecs nécessaires à la décision réelle. [COG-005](../../cognitive-science/cog-005-separate-pitch-estimates-from-listener-reports/) explique pourquoi même un estimateur de signal étalonné n’établirait pas, à lui seul, une préférence des auditeurs ou un apprentissage.

### Exercice 5 : corriger l’affirmation du tableau de bord

Un agent présente le score de récurrence conservé comme une probabilité, relie les points à travers les trames manquantes et qualifie le résultat d’amélioration validée par les auditeurs. Remplacez cette affirmation et précisez la correction à apporter à l’affichage.

> **Réponse:** Étiquetez la récurrence comme le score déclaré de similarité du signal, conservez ses contrôles échoués par rapport à la référence nominale et gardez les véritables fenêtres conservées distinctes des lignes créées pour le graphique. Montrez les estimations valides et les différents états indisponibles sans inventer d’observations entre les points ; explicitez les dénominateurs et les éventuels filtrages. La validation par les auditeurs et un véritable essai d’amélioration exigent des preuves supplémentaires ; cet affichage n’établit donc ni l’une ni l’autre.
