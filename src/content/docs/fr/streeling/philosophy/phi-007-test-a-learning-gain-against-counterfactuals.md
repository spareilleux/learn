---
title: Mettre un gain d'apprentissage à l'épreuve des contrefactuels
description: Mettre un gain d'apprentissage à l'épreuve des contrefactuels — Philosophie
sidebar:
  label: PHI-007 · Mettre un gain d'apprentissage à l'épreuve des contrefactuels
  order: 7
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/philosophy/fr/phi-007-test-a-learning-gain-against-counterfactuals.fr.md
---

:::note[Streeling University]
**PHI-007** · Mettre un gain d'apprentissage à l'épreuve des contrefactuels · intermédiaire · 45 minutes

Généré par le département *Philosophie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/philosophy/fr/phi-007-test-a-learning-gain-against-counterfactuals.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHI-001](../../philosophy/phi-001-how-to-argue-well/), [COG-007](../../cognitive-science/cog-007-separate-unaided-recall-from-assisted-success/)
:::

> **Portée du brouillon.** Résultats binaires pédagogiques, contre-modèles logiques, énumération finie exacte et lecture de sources primaires et de code. Les revues humaines technique, linguistique, musicale et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun participant, intervention, affectation aléatoire ou effet causal d'apprentissage n'ont été observés.

## La question du projet

Un agent améliore un parcours d'entraînement et annonce un score plus élevé au post-test. Quelle prémisse relie ce changement au bénéfice du parcours ? [COG-007](../../cognitive-science/cog-007-separate-unaided-recall-from-assisted-success/) conserve l'aide et les données manquantes avec un critère de résultat. Ce cours pose une autre question, même lorsque tous les résultats sont disponibles : quel score les mêmes unités auraient-elles obtenu au même moment ultérieur d'évaluation, sans l'intervention ?

Le [guide du NIST sur les plans complètement randomisés](https://www.itl.nist.gov/div898/handbook/pri/section3/pri331.htm) traite de l'affectation aléatoire des niveaux de facteurs aux unités expérimentales. Le contenu réel de sa page web a été lu. Les tableaux de résultats potentiels binaires ci-dessous sont notre construction pédagogique, et non des observations du NIST, une étude rapportée ou une taille d'échantillon recommandée.

## 1. Nommer la comparaison non observée

Utilisez une population distincte de huit apprenants fictifs, et non les questions répétées de COG-007. Leurs résultats au prétest sont `[0,0,1,0,1,0,1,1]` ; leurs résultats ultérieurs avec l'intervention sont `[1,1,1,0,1,0,1,1]`. Chaque résultat binaire concerne le même type déclaré d'évaluation. La moyenne pédagogique avant est `4/8`, la moyenne après `6/8`, et leur différence `1/4`.

Notons `Y1` le résultat ultérieur de chaque unité avec l'intervention et `Y0` son résultat ultérieur sans elle. L'effet moyen dans la population finie est la moyenne de `Y1-Y0` sur ces huit unités. Le prétest antérieur est observé à un autre moment. Poser le `Y0` ultérieur égal au prétest exige une hypothèse substantielle sur ce qui changerait autrement.

### Exercice 1 : identifier la prémisse manquante

Calculez la différence avant/après. Quel résultat ultérieur manque lorsque tout le monde reçoit l'intervention, et pourquoi substituer le prétest n'est-il pas une opération arithmétique neutre ?

> **Réponse:** La différence est `6/8-4/8=1/4`. Le `Y0` ultérieur sans intervention de chaque unité est non observé. L'égaler au prétest antérieur suppose l'absence de changement pertinent sans l'intervention ; les données avant/après seules n'établissent pas cette prémisse.

## 2. Construire des mondes qui concordent sur les observations

Conservez les mêmes prétests et résultats ultérieurs avec intervention dans trois mondes pédagogiques. Dans le monde bénéfique, le vecteur ultérieur sans intervention égale le prétest ; l'effet moyen vaut donc `1/4`. Dans le monde sans effet, le vecteur sans intervention égale `Y1` ; l'effet vaut donc 0. Dans le monde défavorable, tous les résultats ultérieurs sans intervention valent 1 ; l'effet vaut donc `6/8-8/8=-1/4`.

Tous les mondes concordent sur chaque observation avant/après fournie. Ils divergent sur le contrefactuel manquant, et donc sur le signe du bénéfice. C'est un témoin logique de non-identification sous ces prémisses sans restriction. Cela n'affirme ni que tous les mondes sont également plausibles ni que le parcours réel aide quelqu'un ou lui nuit.

### Exercice 2 : contester la conclusion causale

Donnez les trois effets moyens. Pourquoi leur accord sur l'amélioration observée ne permet-il pas de les distinguer, et quel type de prémisse ou de preuve supplémentaire serait nécessaire ?

> **Réponse:** Les effets sont `1/4`, 0 et `-1/4`. Leurs prétests et post-tests avec intervention sont identiques ; seuls les résultats ultérieurs sans intervention, non observés, diffèrent. Il faut une hypothèse justifiée sur cette comparaison ou un plan de comparaison adapté. Le changement positif pédagogique ne sélectionne pas un monde.

## 3. Borner ce que permettent les seules données binaires

Il existe 256 vecteurs binaires `Y0` possibles pour huit unités étiquetées. Avec `Y1` fixé à six réussites, le plus petit effet moyen possible est `6/8-1=-1/4` ; le plus grand est `6/8-0=3/4`. Chaque borne peut être atteinte par un vecteur `Y0` complet ; l'intervalle est donc exact pour ce problème fini sans restriction supplémentaire.

Le [relevé contrefactuel](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/counterfactual-gains.json) énumère tous les vecteurs et neuf niveaux d'effet atteignables. Les décomptes de vecteurs ne sont pas une distribution de probabilité sur des mondes réels. L'intervalle n'est pas un intervalle de confiance, et ces huit unités fictives n'estiment pas une future population d'apprenants.

### Exercice 3 : déduire une borne honnête

Déduisez les bornes sans restriction et nommez le vecteur contrefactuel qui atteint chacune. Énumérer 256 possibilités donne-t-il une probabilité à chacune ou rend-il le prétest antérieur sans intérêt pour tous les plans d'étude possibles ?

> **Réponse:** Un `Y0` entièrement composé de uns donne la borne inférieure `-1/4` ; un `Y0` entièrement composé de zéros donne la borne supérieure `3/4`. L'énumération n'attribue aucune probabilité. Les prétests peuvent éclairer un plan d'étude ou un modèle justifié, mais ne contraignent pas le contrefactuel ultérieur dans cette construction sans restriction en l'absence d'une hypothèse supplémentaire.

## 4. Distinguer la moyenne d'un plan d'une affectation particulière

Considérez maintenant un plan futur hypothétique affectant quatre de ces huit apprenants à l'intervention et quatre à la comparaison, uniformément sur 70 répartitions. C'est un schéma hypothétique d'observation différent de l'illustration où tous reçoivent l'intervention. Fixez les résultats potentiels de chaque monde et supposez une intervention bien définie, une observation cohérente avec l'affectation et l'absence d'interférence entre apprenants.

Sur toutes les répartitions, la moyenne du contraste entre moyenne traitée et moyenne témoin égale l'effet moyen du monde dans la population finie : `1/4`, 0 ou `-1/4`. Une répartition particulière peut différer. Dans le monde bénéfique, affecter les apprenants 1, 2, 4 et 6 à l'intervention donne une moyenne traitée de `1/2` ; les résultats sans intervention des unités restantes valent tous 1, donnant une moyenne de comparaison de 1 et un contraste de `-1/2`.

### Exercice 4 : tester une garantie de randomisation

Donnez le nombre de répartitions équilibrées et le contraste moyen sur les répartitions dans le monde bénéfique. Reconstituez le contraste négatif indiqué. Le plan garantit-il que chaque contraste réalisé possède le signe du véritable effet ?

> **Réponse:** Il existe 70 répartitions et leur contraste moyen est `1/4`. Les apprenants 1, 2, 4 et 6 ont les résultats traités 1, 1, 0, 0 ; leur moyenne vaut donc `1/2` ; les témoins 3, 5, 7 et 8 ont chacun un résultat sans intervention de 1, donnant le contraste `-1/2`. L'absence de biais sur les affectations posées ne garantit ni le signe ni la précision d'un résultat particulier. Aucune affectation n'a réellement été exécutée ici.

## 5. Concrétiser l'unité et l'intervention avant d'attribuer un progrès

Si l'intervention est affectée aux apprenants, les réponses répétées d'un apprenant ne sont pas des apprenants supplémentaires affectés indépendamment. Le partage d'indices entre groupes, une visibilité inégale des réponses ou un changement de critère différé peuvent aussi changer la comparaison effectuée. Un futur plan exige des versions explicites de l'intervention et de la comparaison, l'unité et la procédure d'affectation, le calendrier, les règles d'indices et d'aide, la politique de données manquantes et la définition du résultat avant d'interpréter un contraste.

Les [étiquettes de suivi des plans d'entraînement](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/PracticeRoutineTypes.fs#L81-L101) et le [relevé d'évaluation RAG](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Rag/RagEvaluationModels.cs#L3-L31) de GA ne fournissent ni ces affectations hypothétiques d'apprenants ni leurs observations. Cela borne ces définitions examinées ; cela n'affirme pas que tous les sous-systèmes du projet sont dépourvus de preuves plus riches.

### Exercice 5 : corriger le rapport de bénéfice d'un agent

Un agent transforme onze lignes de réponses d'un seul apprenant en « onze participants randomisés » et traite un meilleur post-test comme un bénéfice prouvé. Remplacez cette affirmation et précisez les prochaines preuves nécessaires.

> **Réponse:** Les lignes de réponses sont des tentatives liées à leurs véritables identités d'apprenant et de question, et non des participants randomisés indépendamment. Un changement avant/après décrit son critère enregistré et n'identifie pas un bénéfice sans comparaison contrefactuelle justifiée. Une future affirmation exige une procédure de comparaison et d'affectation implémentée et versionnée, de vrais résultats recueillis aux moments appropriés, des relevés d'aide et de données manquantes ainsi que des vérifications de ses hypothèses. Ni ce dossier fixé ni un champ de plan d'entraînement ne fournissent ces preuves.

Le [travail préparé et sa grille d'évaluation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/learner-task.md) demandent aux apprenants de déduire les contre-modèles. Leur préparation ne constitue ni une revue humaine ni une expérience causale.
