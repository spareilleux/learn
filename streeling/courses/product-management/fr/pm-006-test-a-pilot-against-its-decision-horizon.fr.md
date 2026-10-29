---
module_id: pm-006-test-a-pilot-against-its-decision-horizon
department: product-management
course: "Évaluer un essai pilote selon son horizon de décision"
level: intermediate
prerequisites: ["pm-005-interpret-brutal-coexistence-experiments", "fut-005-value-a-renderer-pilot-before-running-it"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Évaluer un essai pilote selon son horizon de décision

> **Portée du brouillon.** Modèle de perte, de coût et d'horizon conçu pour le cours, arithmétique exacte et lecture de sources à une révision précise. Les revues humaines technique, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucune migration, aucun essai de moteur de rendu, gain de temps d'ingénierie ou déploiement en production n'ont été mesurés.

## La question du projet

Une équipe propose un essai pilote parce que son résultat pourrait aider de nombreuses décisions futures. Combien de décisions peuvent réellement réutiliser cette information, et le changement a-t-il un coût ? [FUT-005](../../futurology/en/fut-005-value-a-renderer-pilot-before-running-it.md) évaluait un canal d'information sans coût de migration. Nous ajoutons ici une charge unique et optimisons à nouveau les actions, au lieu d'ajouter un coût à une ancienne recommandation.

Le [README de BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md) consigne une observation initiale grave de coexistence et un suivi non concluant. [PM-005](pm-005-interpret-brutal-coexistence-experiments.md) explique pourquoi leurs conditions comptent. Ces observations ne mesurent ni l'horizon, ni les charges, ni le modèle de probabilité ci-dessous.

## 1. Déclarer ce qui persiste sur l'horizon

Utilisez la même loi a priori F/U pédagogique de `1/2`, les pertes d'action K de 4 dans chaque condition et S de 0 en F ou de 10 en U, ainsi que les vraisemblances de l'essai pilote `4/5` et `1/5`. Un essai coûte 0.6 point. Son résultat est réutilisé pour N décisions par ailleurs identiques sous la même condition latente stable et le même modèle de conséquences. Ce sont des hypothèses fortes, et non un décompte de tâches futures arbitraires.

Facturez 2 points supplémentaires une seule fois si S est choisie pour l'horizon ; ne facturez aucune migration si K est choisie. Toutes les quantités utilisent la même échelle cardinale pédagogique. Avant un essai pilote, K coûte `4*N` ; S a un coût attendu de `5*N+2`, donc K reste le choix a priori pour N positif. Aucune conversion mesurée ne relie les minutes, l'argent ou les durées d'image à ces points.

### Exercice 1 : inclure la charge unique

Pour N égal à 2, calculez les pertes totales attendues a priori de K et de S, migration comprise. Pourquoi est-il faux de multiplier la charge de migration par N dans ce modèle ?

> **Réponse:** K coûte `4*2=8` ; S coûte `5*2+2=12`. Le modèle facture la migration une seule fois lorsque S est sélectionnée, et non à chaque décision. Une charge par utilisation serait un autre modèle exigeant un autre calcul.

## 2. Recalculer les actions selon le résultat

Après un signal positif, la probabilité a posteriori de F est `4/5`. Comparez le coût K de `4*N` au coût S de `2*N+2`. Après un signal négatif, comparez K à `4*N` et S à `8*N+2`. Les égalités conservent K.

Pour N égal à 1, la branche positive donne une égalité à 4 ; K est donc conservée et aucune charge de migration n'est payée. Pour N égal à 2, la branche positive sélectionne S à 6 plutôt que K à 8 ; la branche négative conserve K à 8 plutôt que S à 18. Ajouter la migration modifie donc ce que l'essai pilote peut justifier, surtout sur des horizons courts.

### Exercice 2 : tester l'horizon court

Quelles actions suivent un signal positif pour N égal à 1 et à 2 ? Quelle charge de migration est réellement payée dans chaque branche sélectionnée ? La recommandation sans migration de FUT-005 se transpose-t-elle sans changement ?

> **Réponse:** Pour N égal à 1, les deux alternatives coûtent 4 et la politique d'égalité conserve K, sans payer de migration. Pour N égal à 2, S coûte 6 contre K à 8 et paie la charge unique de 2. La politique précédente sans migration doit être recalculée avec les nouvelles conséquences.

## 3. Faire la moyenne de la politique d'essai pilote et trouver le seuil de rentabilité

Les deux résultats du signal ont chacun une probabilité de `1/2`. Pour N entier positif, la perte attendue optimisée avant le coût de l'essai pilote est `3*N+1` ; après la charge de 0.6, elle est `3*N+1.6`. Pour N égal à 1, la branche à égalité a la même perte optimale, bien que l'action K choisie ne paie aucune migration. Conservez cette distinction lorsque vous présentez les composantes du coût.

| N | Maintien sans essai pilote | Total attendu avec essai pilote | Gain net |
| --- | --- | --- | --- |
| 1 | 4 | 4.6 | -0.6 |
| 2 | 8 | 7.6 | 0.4 |
| 5 | 20 | 16.6 | 3.4 |
| 10 | 40 | 31.6 | 8.4 |

Le gain modélisé est `N-1.6`, positif lorsque `N>1.6`. Le premier horizon entier donnant un gain positif est 2. C'est un calcul conditionnel de seuil de rentabilité, et non une économie observée ou une justification pour compter des charges de travail sans rapport comme des utilisations identiques.

### Exercice 3 : trouver l'horizon utile

Calculez le gain net pour N égal à 1 et à 2 et identifiez le premier horizon entier donnant un gain positif. Pour N égal à 5, quelle perte totale est prédite avec l'essai pilote ?

> **Réponse:** Les gains sont de -0.6 et de 0.4 point ; le premier horizon entier donnant un gain positif est 2. Pour N égal à 5, la perte totale attendue est `3*5+1.6=16.6`. Tous les résultats reposent sur les hypothèses pédagogiques d'état stable, de signal réutilisable et de pertes comparables.

## 4. Préserver les mêmes coûts dans un plafond d'information

Une information parfaite choisirait S en F avec un coût total de 2 et K en U avec un coût de `4*N`. Sa perte attendue est `2*N+1` pour N entier positif. Par rapport à K a priori à `4*N`, le plafond brut d'information parfaite est `2*N-1`.

Pour N égal à 1, le plafond est de 1 point, inférieur au plafond de 2 points sans migration de FUT-005. L'essai pilote imparfait a une valeur décisionnelle brute nulle à cet horizon avant sa charge d'acquisition, car aucun signal ne change l'action choisie. Un plafond n'est pas la promesse qu'un test bruité disponible l'atteint. Le [cours du MIT sur la valeur de l'information](https://ocw.mit.edu/courses/15-053-optimization-methods-in-management-science-spring-2013/b68f3b255275ffa42099958e373248b1_MIT15_053S13_lec19.pdf#page=7) définit cette valeur par rapport au même problème de décision initial ; changer les coûts change ce problème.

### Exercice 4 : comparer des problèmes équivalents

Pour N égal à 2, calculez la perte attendue avec information parfaite et le plafond avec migration. Peut-on simplement réutiliser le plafond sans migration ? Un plafond de 3 points signifie-t-il que l'essai pilote imparfait vaut 3 points ?

> **Réponse:** La perte attendue avec information parfaite est `2*2+1=5`, contre une référence de 8, donnant un plafond de 3. Réutiliser un plafond qui omet la migration compare des problèmes différents. La valeur brute de l'essai pilote imparfait n'est ici que de `8-7=1` point avant sa charge d'acquisition de 0.6 ; il n'atteint donc pas le plafond d'information parfaite.

## 5. Faire de la réutilisation de l'information une hypothèse réfutable

Le [rapport historique M2](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m2-20261019-235218.md) et le [rapport M3](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m3-20261020-000727.md) nomment des révisions différentes avec des modifications non validées et des contrôles variables. Ils illustrent pourquoi il faut vérifier la comparabilité avant de multiplier un résultat sur un horizon. Ils n'établissent pas une même condition cachée pour chaque scène, pilote graphique ou tâche futurs.

Un relevé proposé d'essai pilote devrait préciser la portée de la décision, les hypothèses de réutilisation, les actions permises, les charges uniques ou par utilisation, les unités de coût, le mode effectif et le déclencheur de péremption des preuves. Une nouvelle scène ou un nouvel hôte peuvent invalider la réutilisation sans prouver que le candidat est mauvais. L'alternative plus simple consiste à conserver la configuration actuelle tout en recueillant le minimum de preuves comparables nécessaires à la décision réelle. Un nouveau DSL est facultatif ; un relevé typé clair peut exprimer ces distinctions.

### Exercice 5 : contester une réutilisation exagérée

Un agent applique le gain de 8.4 points pour N égal à 10 à dix scènes sans rapport sur des hôtes différents. Quelle hypothèse a échoué ? Indiquez un déclencheur de péremption et les preuves nécessaires avant d'affirmer des économies réelles.

> **Réponse:** Dix tâches ne sont pas automatiquement dix décisions identiques sous une même condition latente stable et un signal étalonné. Un changement de scène, de charge de travail, d'hôte, de pilote graphique, de mode effectif ou de protocole de mesure devrait déclencher un réexamen de la réutilisation. Des économies réelles exigent des résultats comparables, des coûts réels d'acquisition et de migration, une échelle de conséquences justifiée et les contrôles requis de qualité et de coexistence ; aucune économie de ce type n'a été mesurée ici.

Le [relevé d'horizon fixé](../../../../code/streeling/evidence/pilot-value-2026-10-22/decision-horizons.json) préserve les politiques exactes des branches, notamment l'égalité pour N égal à 1 et sa charge de migration payée nulle.
