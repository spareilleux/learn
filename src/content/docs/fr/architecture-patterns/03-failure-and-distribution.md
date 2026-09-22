---
title: 3 — Quand une frontière traverse un processus
description: Étudier réponses perdues, reprises concurrentes, extraction de modules et récupération sans attribuer des garanties distribuées à un port.
sidebar:
  order: 3
---

## La réponse perdue

Le professeur clique sur Enregistrer. Le serveur valide la transaction, puis la connexion se ferme avant l'arrivée du reçu. Une nouvelle tentative peut créer un doublon même si toutes les dépendances pointent vers l'intérieur. Le [guide d'Amazon sur les API idempotentes](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/) explique pourquoi l'intention de l'appelant doit garder une identité stable entre tentatives. Notre contrat ci-dessous est une proposition, **à vérifier** dans une implémentation.

Utiliser une clé d'idempotence propre au professeur authentifié et une empreinte du contenu canonique. Stocker la clé, l'empreinte, le plan et le reçu dans la même transaction. Une reprise concurrente doit rencontrer une contrainte d'unicité ou une réservation atomique équivalente, pas une vérification d'existence suivie d'une insertion séparée.

| Événement | Résultat requis | Observation du test |
|---|---|---|
| Réponse perdue après commit | La reprise retourne le reçu enregistré | Un plan ; mêmes identifiant et révision |
| Deux requêtes identiques simultanées | Un commit ; même résultat pour les deux | Une clé et un plan après leur fin |
| Même clé, contenu différent | Conflit, pas de second plan | Empreinte et reçu initiaux inchangés |
| Panne du stockage avant commit | Aucun reçu de succès | La reprise peut encore réussir |
| Révision du catalogue rejetée au commit | Refus typé pour catalogue périmé | Ni plan ni reçu de succès |

Fixer une durée de conservation des clés. Après expiration, la même clé pourrait créer un nouveau plan ; l'idempotence perpétuelle n'est pas implicite. Décider si les refus sont mémorisés. Notre candidate ne mémorise que les commits réussis : on peut donc réessayer après un refus en actualisant le catalogue.

## Un port ne rend pas local un appel distant

Supposons que Catalog passe dans un autre processus. L'appel subit désormais latence, expiration du délai, indisponibilité, authentification et versions de schéma. Un délai expiré signifie que l'appelant n'a pas de résultat ; il ne prouve pas l'échec de l'action distante. Une mémoire empruntée ou une référence d'objet locale ne peut pas servir de contrat réseau.

Le meilleur argument contre l'extraction : notre unique équipe livre encore les deux modules ensemble. L'alternative simple est une API publique de module dans le processus existant. Rejeter l'extraction tant que déploiement indépendant, mise à l'échelle ou isolation ne produisent pas un bénéfice mesuré suffisant pour exploiter un second service.

Si Practice doit vérifier atomiquement le dernier catalogue distant et effectuer son commit local, une requête ordinaire suivie d'une transaction locale ne le garantit pas. Choisir explicitement : accepter un instantané immuable fixé, introduire un protocole coordonné, ou assouplir visiblement la fraîcheur exigée. Pour cette première tranche, nous retenons les instantanés fixés ; changer cette règle exige une décision produit.

## Les notifications ajoutent une transaction

Enregistrer le plan et prévenir l'élève sont deux effets. Appeler un service de notification distant dans une transaction locale ne rend pas les deux commits atomiques. Une conception possible enregistre une notification en attente avec le plan, puis un worker la livre. Les reprises demandent un identifiant de message stable et une déduplication côté destinataire. C'est un exercice d'outbox proposé, pas une garantie de livraison exactement une fois.

Les coûts cachés comprennent files de reprise, messages impossibles à traiter, rapprochement, rétention et outils de support. Si la notification est facultative, afficher le plan enregistré dans l'interface actuelle est l'option initiale la plus simple.

## Exercice — Suivre le crash

Un worker livre la notification, puis plante avant de marquer son enregistrement comme livré. Au redémarrage, il l'envoie de nouveau. Que doit préciser le contrat ? Nommer une mesure utile et un critère de rejet de la fonctionnalité.

<details>
<summary>Corrigé</summary>

Le destinataire doit reconnaître le même identifiant de message ; sinon, les doublons restent possibles et doivent être acceptables pour le produit. Marquer l'enregistrement avant l'envoi transforme simplement le risque en notification perdue. Mesurer l'âge de la plus ancienne notification en attente et compter séparément les effets en double et les tentatives de livraison. Rejeter les notifications automatiques si le destinataire ne peut pas dédupliquer et que les doublons visibles sont inacceptables. Garder le reçu durable du plan indépendant du succès de la notification. Tester les deux fenêtres de crash avant de revendiquer une livraison fiable ; cette leçon ne les a pas exécutées.

</details>
