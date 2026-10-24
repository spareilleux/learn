---
module_id: cyb-006-bound-retry-feedback-and-workload
department: cybernetics
course: "Borner la rétroaction des nouvelles tentatives avant d'ajouter des workers"
level: intermediate
prerequisites: ["cyb-004-observe-before-correcting-a-feedback-loop", "net-007-separate-dag-readiness-from-admission"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Borner la rétroaction des nouvelles tentatives avant d'ajouter des workers

> **Portée du brouillon.** Code public d'IX à une révision précise, preuves issues de réponses d'outils dans un cadre limité et modèles de probabilité, de charge de travail et d'achèvement différé conçus pour le cours. La revue technique humaine, la relecture par des personnes maîtrisant la langue, les essais avec des apprenants et la vérification du HTML du cours déployé restent à effectuer. Aucun contrôleur réel de nouvelles tentatives, banc d'essai de file d'attente, annulation ni écriture externe n'ont été exécutés.

## La question du projet

Un agent ne voit aucun résultat terminal et lance une nouvelle tentative. Cela peut aider en cas de défaillance transitoire, mais aussi ajouter du travail alors que la première tentative est encore active. L'[article de l'AWS Builders' Library sur les délais d'attente et les nouvelles tentatives](https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/) explique ce risque de rétroaction. Ce cours construit de petits modèles explicites pour pouvoir mettre à l'épreuve une proposition de contrôleur IX avant son installation.

Le [moteur d'exécution public d'IX](https://github.com/GuitarAlchemist/ix/blob/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-agent/src/tools.rs#L408-L450), à la révision `456df065ee837e33b5bbe22a4df0616a4fcb76e5`, lance une étape et s'arrête en cas d'erreur. Le modèle de résultat examiné ne comporte aucun cycle de vie des tentatives. Cette observation limitée du code ne prouve pas qu'aucun autre composant d'IX ne peut réessayer. [NET-007](../../network-science/en/net-007-separate-dag-readiness-from-admission.md) distingue la disponibilité dans le graphe de la capacité ; les nouvelles tentatives consomment aussi cette capacité.

## 1. Compter séparément les tentatives et les requêtes logiques

Le [modèle de nouvelles tentatives conçu pour le cours](../../../../code/streeling/evidence/retry-admission-2026-10-22/retry-load-model.json) suppose des tentatives indépendantes, une probabilité d'échec de 1/2 et au plus 3 tentatives par requête logique. Il énumère huit suites de résultats de longueur 3, prééchantillonnées et équiprobables. Les résultats après le premier succès sont des artifices de dénombrement inutilisés, et non des tentatives supplémentaires exécutées.

Une tentative a toujours lieu. Une deuxième a lieu avec une probabilité de 1/2 ; une troisième avec une probabilité de 1/4. Le travail attendu est donc de `1+1/2+1/4 = 7/4` tentatives. Seuls trois échecs consécutifs épuisent la limite, ce qui donne une probabilité d'échec terminal de 1/8 et de succès de 7/8. Ce sont des valeurs de modèle, et non une fiabilité mesurée de l'outil ou un niveau de confiance dans un artefact réel.

### Exercice 1 : calculer l'amplification des tentatives

Selon les hypothèses déclarées, calculez le nombre attendu de tentatives et la probabilité de succès. Dans la suite prééchantillonnée SFF, combien de tentatives s'exécutent réellement ? Le modèle exécute-t-il les trois résultats pour chaque requête ?

> **Réponse:** Le nombre attendu de tentatives est 7/4 et la probabilité de succès est 7/8. SFF n'exécute que sa première tentative, car elle réussit. Les résultats prééchantillonnés suivants sont ignorés ; l'énumération représente des probabilités et n'impose pas trois exécutions après un succès.

## 2. Comparer la charge offerte à la capacité de traitement des tentatives

Supposons qu'une illustration par modèle fluide en débits moyens reçoive 6 requêtes logiques par seconde et puisse traiter 10 tentatives par seconde. Avec le même modèle indépendant, la demande attendue est de `6*7/4 = 10.5` tentatives par seconde. Elle dépasse la capacité de 0.5 unité de travail de tentative par seconde, soit 15 sur 30 secondes. Cette dernière valeur est un excès moyen de travail offert, et non un échantillon montrant exactement 15 tâches en file d'attente.

Le seuil d'arrivée des requêtes logiques est `10/(7/4) = 40/7` requêtes par seconde. Rester strictement sous ce seuil laisse une capacité disponible en débit moyen dans cette illustration simplifiée. L'égalité ne laisse aucune marge et ne constitue pas une preuve générale de stabilité d'une file stochastique. Les coûts réels, les défaillances corrélées, les tampons finis et l'ordonnancement exigent des mesures réelles.

### Exercice 2 : situer le goulot d'étranglement

Calculez le débit de tentatives offert et le seuil d'arrivée des requêtes logiques. Le fait que 6 soit inférieur à 10 permet-il d'établir une marge de capacité ? Que représente le nombre 15 ici ?

> **Réponse:** La demande offerte est de 10.5 tentatives par seconde et le seuil de 40/7 requêtes logiques par seconde. Comparer directement 6 requêtes logiques à 10 tentatives mélange les unités et ignore les nouvelles tentatives. Le nombre 15 représente l'excès moyen de demande de travail de tentative sur 30 secondes selon les hypothèses du modèle fluide, et non une longueur de file observée.

## 3. Distinguer le lissage et la réduction du travail attendu

La temporisation entre les tentatives modifie le moment où une tentative est proposée ; la gigue répartit les tentatives synchronisées dans le temps. Avec ce modèle fixe à résultats indépendants, modifier seulement les moments des nouvelles tentatives ne change pas les probabilités de 1/2 ou de 1/4 que les tentatives suivantes soient nécessaires. Cela ne change donc pas le nombre attendu de tentatives, 7/4. Dans un système réel dépendant de la charge, retarder une tentative pourrait modifier sa probabilité d'échec ; il s'agit d'un autre modèle, qui exige des preuves.

Le témoin d'échec persistant donne au contraire à chaque tentative une probabilité d'échec de 1. Trois tentatives consomment alors 3 unités sans produire de succès. Réessayer aveuglément après une erreur de validation permanente ne peut pas se justifier par le calcul précédent de défaillance transitoire. Une proposition utile de contrôleur exige une classification des échecs, une politique de tentatives bornée et une comparaison avec la référence plus simple à une seule tentative.

### Exercice 3 : contester une amélioration annoncée

Une proposition ajoute des délais aléatoires entre les tentatives et prétend réduire leur nombre attendu à partir de 7/4 sans modifier le modèle de défaillances indépendantes. Cette conclusion découle-t-elle de ces hypothèses ? Que se passe-t-il avec le témoin d'échec persistant ?

> **Réponse:** Non. Modifier seulement les moments des tentatives laisse inchangés les probabilités fixes et le travail attendu. Une réduction exigerait un modèle de résultats ou une politique modifiés et étayés. Dans le témoin d'échec persistant, la limite permet 3 tentatives échouées et le succès reste à 0.

## 4. Une expiration du délai ne prouve pas que le travail s'est arrêté

La [trace d'achèvement différé conçue pour le cours](../../../../code/streeling/evidence/retry-admission-2026-10-22/delayed-completion-model.json) démarre des tentatives pour une même requête logique aux pas de temps 0, 1 et 2. Chacune dure 3 pas de temps ; elles se terminent donc à 3, 4 et 5. Juste après le troisième démarrage, 3 tentatives sont actives. Un délai d'observation d'un pas de temps était inférieur à la durée du travail ; la première tentative restait active par construction.

Une règle d'admission à deux emplacements empêche le troisième démarrage. Elle conserve les démarrages à 0 et 1, les achèvements à 3 et 4 et un pic de 2 tentatives actives. Accepter le premier résultat à 3 n'annule pas la deuxième tentative dans ce modèle. L'admission selon la capacité, la confirmation d'annulation et la déduplication des effets voulus sont des mécanismes distincts. Aucune tâche distante réelle n'a été arrêtée ou redémarrée pour cet exercice.

### Exercice 4 : suivre la tentative tardive

Donnez les temps d'achèvement et les pics de tentatives actives dans la trace sans limite et celle à deux emplacements. Après avoir accepté le premier résultat au pas de temps 3, le contrôleur peut-il supposer que la deuxième tentative s'est arrêtée ?

> **Réponse:** La première trace se termine à 3, 4 et 5 avec un pic de 3. La trace à deux emplacements se termine à 3 et 4 avec un pic de 2. Il ne peut pas supposer que la deuxième tentative s'est arrêtée : ce modèle ne fournit aucune confirmation d'annulation, et cette tentative reste active jusqu'à 4.

## 5. Rendre la proposition de contrôleur réfutable

Les [essais réels d'IX](../../../../code/streeling/evidence/retry-admission-2026-10-22/execution-tool-probes.json) comprennent une erreur provenant d'un outil volontairement inconnu. Ils ne fournissent aucun dossier complet de résultats partiels. L'absence de ce dossier ne prouve pas l'absence de tout travail antérieur. Un contrôleur externe qui relance un pipeline entier chaque fois que l'agrégat manque pourrait répéter des effets déjà accomplis.

Un contrôleur proposé devrait identifier séparément la requête logique et chaque tentative, observer les débuts et les états terminaux, borner l'admission et le travail des nouvelles tentatives, et préciser son traitement des résultats inconnus. Comparez-le à une référence à une seule tentative en utilisant les résultats acceptés, le nombre total de tentatives, le travail actif et les effets non résolus. Rejetez un gain apparent qui ne fait qu'augmenter les tentatives lancées alors que les résultats acceptés stagnent. Ce sont des critères d'évaluation candidats, et non une nouvelle politique installée dans IX. [PHI-005](../../philosophy/en/phi-005-test-idempotence-beyond-replayed-values.md) examine les preuves nécessaires pour qualifier d'idempotents des effets répétés.

### Exercice 5 : choisir une observation discriminante

Un contrôleur affirme avoir rétabli le fonctionnement parce qu'il a lancé 3 tentatives au lieu de 1. Les résultats logiques acceptés restent à 1, et l'état d'une tentative antérieure est inconnu. Cela prouve-t-il une amélioration ? Nommez deux observations nécessaires avant d'élargir la politique.

> **Réponse:** Non. Les tentatives lancées mesurent l'effort, et non l'amélioration des résultats acceptés. Observez le début et l'état terminal ou la confirmation d'annulation de chaque tentative, puis rapprochez l'effet externe voulu de son identité logique. Comparez aussi le travail total des tentatives et les résultats acceptés à la référence ; un résultat antérieur inconnu ne peut pas être remplacé par un arrêt supposé.

## Travail de l'apprenant avec accès aux sources

Utilisez le [travail préparé](../../../../code/streeling/evidence/retry-admission-2026-10-22/learner-task.md) pour reconstituer l'énumération des probabilités, la charge avec des unités cohérentes et la trace différée. Expliquez un critère de rejet d'une proposition de nouvelles tentatives. Les résultats réels des apprenants, de la revue humaine et du contrôleur à l'exécution restent à recueillir.
