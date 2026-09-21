---
title: 1 — Partir d'un changement, pas d'un diagramme
description: Établir le contrat d'un plan de pratique, les hypothèses et les mesures avant de choisir les frontières architecturales.
sidebar:
  order: 1
---

## Le même petit problème du début à la fin

Un professeur de guitare enregistre le plan de pratique d'un élève avec un formulaire web. Demain, un import par lot pourrait avoir besoin de la même validation. Le plan contient un titre, exactement trois identifiants distincts de positions d'accords et la révision du catalogue consultée. L'enregistrement réussi retourne un identifiant de plan et une révision ; une position inconnue, un doublon ou un catalogue périmé produit un refus typé sans écriture.

Supposons une équipe, un processus déployé, un stockage transactionnel local et un instantané immuable du catalogue. L'identité du professeur est déjà établie, mais le cas d'utilisation doit vérifier qu'il peut modifier le plan de cet élève. Pas encore besoin de facturation, de flux d'événements ni de déploiement indépendant. Ces hypothèses bornent l'exercice ; elles ne décrivent pas un système en production.

Le contrat est plus utile qu'une arborescence :

| Entrée ou événement | Observation requise |
|---|---|
| Trois identifiants connus et distincts, révision courante | Un plan et un reçu durable |
| Identifiant répété | `InvalidPlan` ; aucun plan enregistré |
| Révision du catalogue devenue inacceptable | `StaleCatalog` ; aucune écriture |
| Élève d'un autre professeur | `Forbidden` ; aucune écriture |
| Même identifiant de requête et même contenu réessayés | Même reçu ; pas de second plan |
| Même identifiant de requête, contenu différent | `RequestConflict` ; aucun écrasement |

Les deux dernières exigences seront centrales dans la [leçon 3](../03-failure-and-distribution/). Elles concernent aussi un service web local : le client peut perdre sa connexion après le commit.

## Une première candidate en couches

Le [guide d'architecture de Microsoft](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures) distingue les couches logiques du déploiement. Ici, commençons avec un gestionnaire de requête, une opération applicative et un adaptateur de persistance dans un seul processus. Une couche organise le code ; elle n'impose pas un serveur supplémentaire.

Plaçons la règle des trois positions dans une seule fonction. Le gestionnaire analyse l'entrée ; l'opération vérifie les droits, charge le catalogue accepté, appelle cette fonction et enregistre. Cela peut suffire. Un type de base de données qui fuit dans la règle est une dépendance concrète à examiner, pas la preuve que toute architecture en couches est défectueuse.

## Définir l'expérience avant de mesurer

**Hypothèse :** séparer l'opération d'enregistrement de l'hôte web permettra à l'import par lot de la réutiliser sans copier la validation. **Meilleur contre-argument :** une seule fonction appelée par les deux gestionnaires y suffit déjà ; un projet et un dépôt générique supplémentaires pourraient n'apporter aucune valeur.

Essayons d'abord la fonction simple. Sur une révision et des données fixes, relevons :

| Frontière | Mesure | Critère d'acceptation proposé |
|---|---|---|
| Gestionnaire → opération | Définitions de règles et tests réutilisés par deux appelants | Une implémentation ; mêmes refus |
| Règle → infrastructure | Dépendances d'exécution directes et transitives | Le test de règle ne lance ni hôte ni base |
| Opération → stockage | Fichiers modifiés pour ajouter un stockage de test | Règle inchangée ; mêmes cas contractuels réussis |
| Sortie de compilation → processus actif | Reproduire séparément un verrouillage de fichier | Ne pas prétendre qu'une interface résout les verrous |

Ces seuils décrivent une expérience proposée, **à vérifier**. Compter les changements sémantiques, y compris le câblage et les tests, sans récompenser un nombre arbitrairement faible de fichiers. Mesurer la durée des tests sur la même machine après avoir contrôlé le démarrage et les caches.

## Exercice — Trouver l'hypothèse cachée

La validation accepte un identifiant de position, puis le stockage consulte de nouveau le catalogue le plus récent. Le reçu peut-il indiquer honnêtement quelle révision a été validée ? Proposer la correction minimale et un critère qui réfuterait l'utilité d'un projet de domaine séparé.

<details>
<summary>Corrigé</summary>

Les deux lectures peuvent observer des révisions différentes. Transmettre la révision immuable validée jusqu'à l'enregistrement et la conserver dans le reçu. Si l'acceptation dépend de la révision courante au commit, vérifier cette précondition atomiquement avec l'écriture ; une lecture préalable ne suffit pas. Un projet séparé n'est pas nécessaire pour exprimer ce contrat. Rejeter l'extraction si les deux appelants réutilisent déjà la même règle pure, qu'aucune dépendance interdite n'existe et que le seul effet observé est du travail de compilation ou de conversion supplémentaire. Réexaminer à l'apparition d'un problème concret de dépendance ou de responsabilité.

</details>
