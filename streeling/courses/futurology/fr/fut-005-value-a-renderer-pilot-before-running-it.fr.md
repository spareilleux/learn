---
module_id: fut-005-value-a-renderer-pilot-before-running-it
department: futurology
course: "Évaluer l'intérêt d'un essai pilote de moteur de rendu avant de le lancer"
level: intermediate
prerequisites: ["fut-004-scenario-test-an-observatory-renderer", "pm-005-interpret-brutal-coexistence-experiments"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Évaluer l'intérêt d'un essai pilote de moteur de rendu avant de le lancer

> **Portée du brouillon.** Modèles de décision et de signal conçus pour le cours, arithmétique exacte et lecture de sources historiques à une révision précise. Les revues humaines technique, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun essai pilote réel, moteur de rendu, GPU ou basculement en production n'ont été exécutés.

## La question du projet

Un nouvel essai de moteur de rendu changerait-il la décision, ou produirait-il seulement davantage de rapports ? [FUT-004](fut-004-scenario-test-an-observatory-renderer.md) comparait des stratégies selon plusieurs scénarios. Ici, nous évaluons l'information avant de l'obtenir, en examinant les actions qu'elle pourrait modifier.

Le [README de BRUTAL à la révision fixée](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md) conserve un échec initial de coexistence et un suivi non concluant. [PM-005](../../product-management/en/pm-005-interpret-brutal-coexistence-experiments.md) explique ces observations historiques. Elles motivent la question mais ne fournissent aucune des probabilités ou des valeurs de perte ci-dessous. Tous les documents sources du projet utilisent la révision de GA `76efbffd5af82b46c3146957a6bd4504008eeb89` ; aucun binaire historique n'a été reproduit ici.

## 1. Énoncer la décision sans essai pilote

Utilisez deux conditions latentes conçues pour le cours : F, où un candidat convient à l'usage visé, et U, où il ne convient pas. La probabilité a priori de chacune est `1/2`. Les actions sont K, conserver la configuration actuelle, et S, adopter le candidat. Avant de comparer leurs conséquences, supposez ces actions admissibles au regard des contrôles requis de qualité et de coexistence.

| Action | Perte en F | Perte en U |
| --- | --- | --- |
| K | 4 | 4 |
| S | 0 | 10 |

Ces nombres sont des points pédagogiques comparables sur une échelle cardinale, où une perte attendue plus faible est préférée. Ce ne sont ni de l'argent, ni des millisecondes, ni des préférences mesurées. Les pertes attendues a priori sont de 4 pour K et de 5 pour S ; conservez donc K. Si la probabilité de F est p, S a une perte attendue de `10*(1-p)`. Elle ne devient préférable à K que lorsque `p>3/5` ; en cas d'égalité, notre politique déclarée conserve K.

### Exercice 1 : situer le seuil de changement d'action

Calculez les deux pertes attendues a priori. Déterminez le seuil de probabilité à partir duquel S devient préférable. Ce seuil estime-t-il la fréquence à laquelle le candidat réel convient ?

> **Réponse:** K donne 4 ; S donne `(1/2)*0+(1/2)*10=5`. Résoudre `10*(1-p)<4` donne `p>3/5`. Le seuil découle des pertes pédagogiques et de la règle de préférence ; il n'estime pas une probabilité réelle des conditions de l'hôte.

## 2. Modéliser ce que l'essai pilote peut nous apprendre

Posez un essai pilote passif avec les probabilités de résultat positif `P(+|F)=4/5` et `P(+|U)=1/5`. Il ne modifie pas la condition latente. Ses probabilités négatives sont les complémentaires. La [présentation de Bayes par le NIST](https://www.itl.nist.gov/div898/handbook/apr/section2/apr1a.htm) explique la mise à jour d'une loi a priori à l'aide d'une vraisemblance, avec normalisation sur les conditions possibles.

Chaque résultat a une probabilité a priori de `1/2`. Après un résultat positif, `P(F|+)=4/5` ; après un résultat négatif, `P(F|-)=1/5`. Un résultat positif sélectionne donc S avec une perte attendue conditionnelle de 2. Un résultat négatif sélectionne K avec une perte de 4. Ces vraisemblances sont des prémisses explicites, et non un classificateur ajusté ou le taux de réussite des essais historiques de BRUTAL.

### Exercice 2 : inverser le conditionnement

Calculez la probabilité d'un résultat positif et la probabilité a posteriori de F après ce résultat. Quelle action en découle ? `P(+|F)` est-elle automatiquement la même quantité que `P(F|+)` ?

> **Réponse:** `P(+)=(1/2)*(4/5)+(1/2)*(1/5)=1/2`. Puis `P(F|+)=((1/2)*(4/5))/(1/2)=4/5` ; S a une perte attendue de 2 et est sélectionnée. Les probabilités conditionnelles ont par hasard des valeurs égales dans cet exemple symétrique, mais elles sont conditionnées par des événements différents et ne sont généralement pas interchangeables.

## 3. Comparer l'information imparfaite et parfaite

Avant de payer l'essai pilote, faites la moyenne des meilleures décisions selon le résultat : `(1/2)*2+(1/2)*4=3`. La valeur attendue brute de l'information issue de l'essai est la meilleure perte a priori moins cette valeur : `4-3=1` point.

Une information parfaite révélerait F ou U avant d'agir. Choisissez S en F et K en U, donnant la perte attendue `(1/2)*0+(1/2)*4=2`. Sa valeur brute est de `4-2=2` points. Le [cours d'analyse de décision du MIT](https://ocw.mit.edu/courses/15-053-optimization-methods-in-management-science-spring-2013/b68f3b255275ffa42099958e373248b1_MIT15_053S13_lec19.pdf#page=7) distingue l'information initiale, parfaite et imparfaite. Nous utilisons une réduction de perte plutôt que sa convention d'augmentation du gain.

### Exercice 3 : calculer les deux valeurs

Calculez les valeurs brutes de l'information issue de l'essai et de l'information parfaite. Pourquoi traiter cet essai pilote bruité comme parfait exagérerait-il son bénéfice modélisé ?

> **Réponse:** Les valeurs sont respectivement de 1 et 2 points. L'essai pilote bruité donne parfois le signal défavorable pour la condition réelle ; sa perte attendue optimisée est donc de 3 au lieu de la valeur de 2 obtenue avec une information parfaite. Attribuer une exactitude parfaite à cet essai modifie le canal d'information posé.

## 4. Facturer l'acquisition de l'information

Supposons que l'essai pilote coûte 0.6 point sur la même échelle de perte déclarée. La perte attendue totale devient `3+0.6=3.6`, soit une amélioration de `4-3.6=0.4` par rapport au maintien de K sans essai pilote. Un coût de 1 point épuiserait le bénéfice brut de cet essai. Un test parfait hypothétique coûtant 3 points serait lui aussi peu intéressant ici : sa valeur brute n'est que de 2.

La valeur de l'information parfaite est un plafond pour l'information sur cet état sous les mêmes hypothèses d'actions possibles, de pertes et de calendrier. Ce n'est pas un budget pour toute expérience possible : un nouveau test pourrait modifier les actions disponibles, prendre du temps pendant lequel l'état change ou modifier la charge de travail elle-même. Ce sont d'autres modèles de décision.

### Exercice 4 : rejeter un test trop coûteux

Quelle est la valeur nette de l'essai pilote bruité à 0.6 point ? Et celle d'un test parfait coûtant 3 points ? Peut-on ajouter directement des minutes de travail d'ingénierie à ces points de perte ?

> **Réponse:** La valeur nette de l'essai pilote bruité est de 0.4 point. Celle du test parfait est de `2-3=-1` point. Les minutes brutes ne peuvent pas être ajoutées à l'échelle de points sans conversion déclarée ou objectif différent ; aucun temps ou coût réel n'a été mesuré ici.

## 5. Demander si une action peut changer

Si seule K est autorisée, l'information ne peut pas modifier l'action. La loi a posteriori peut changer alors que la valeur décisionnelle brute reste à 0. Plus généralement, l'information peut être ignorée dans ce modèle ; sa valeur brute optimisée est donc positive ou nulle. Elle peut être nulle, et ses coûts d'acquisition peuvent rendre sa valeur nette négative.

Une prochaine investigation utile précise la décision réelle, les actions admissibles, l'échelle des conséquences, le fondement de la loi a priori, l'étalonnage du signal, le calendrier et la règle d'arrêt. Le [rapport historique M3](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m3-20261020-000727.md) comporte des contrôles variables et ses propres limites liées au binaire et à l'état non propre du dépôt. Il n'étalonne pas cet essai pilote passif hypothétique. [CYB-007](../../cybernetics/en/cyb-007-update-beliefs-without-counting-a-trial-twice.md) vérifie si les rapports successifs représentent de nouvelles preuves ; [PM-006](../../product-management/en/pm-006-test-a-pilot-against-its-decision-horizon.md) ajoute les coûts de migration et de réutilisation.

### Exercice 5 : distinguer apprentissage et valeur décisionnelle

Supposez que seule K soit autorisée, mais que l'essai pilote fasse tout de même passer la loi a posteriori de `1/2` à `4/5` après un résultat positif. Quelle est sa valeur décisionnelle brute ? Quelles preuves manquent avant que le résultat initial de 0.4 point puisse justifier un véritable essai de moteur de rendu ?

> **Réponse:** La valeur décisionnelle brute est de 0, car l'action permise reste K. Une décision d'essai réel exige une échelle de conséquences justifiée, des alternatives admissibles, des hypothèses de loi a priori et de vraisemblance étalonnées ou explicitement défendues, des coûts d'acquisition réels, un calendrier et des contrôles de qualité et de coexistence. Le résultat de 0.4 point est un calcul conditionnel, et non une autorisation ou un bénéfice mesuré sur la machine.

Le [relevé de décision fixé](../../../../code/streeling/evidence/pilot-value-2026-10-22/pilot-decision.json) préserve le modèle pédagogique complet et ses valeurs rationnelles exactes.
