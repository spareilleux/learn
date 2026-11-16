---
title: Mesurer la latence de lecture du point de vue de l'utilisateur
description: Mesurer la latence de lecture du point de vue de l'utilisateur — Gestion de produit et de projet
sidebar:
  label: PM-007 · Mesurer la latence de lecture du point de vue de l'utilisateur
  order: 7
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/fr/pm-007-measure-playback-latency-at-the-user-boundary.fr.md
---

:::note[Streeling University]
**PM-007** · Mesurer la latence de lecture du point de vue de l'utilisateur · intermédiaire · 45 minutes

Généré par le département *Gestion de produit et de projet* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/fr/pm-007-measure-playback-latency-at-the-user-boundary.fr.md) · [Mon journal](../../journal/)

Prérequis: [PM-005](../../product-management/pm-005-interpret-brutal-coexistence-experiments/), [NET-008](../../network-science/net-008-map-clock-domains-before-ordering-events/)
:::

> **Portée du brouillon.** Relevés pédagogiques d'événements aux limites de mesure, synthèses exactes et lecture de code et de spécifications à une révision précise. Les revues humaines technique, musicale, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun navigateur, guitare, auditeur ou banc d'essai réel de latence n'ont fait l'objet d'un essai.

## La question du projet

Un agent accélère un calcul de lecture. Le guitariste a-t-il entendu la réponse plus tôt ? [PM-005](../../product-management/pm-005-interpret-brutal-coexistence-experiments/) montre pourquoi la vitesse propre du producteur ne suffit pas. Nous utilisons ici un composant concret sélectionné de progression de GA et distinguons les demandes de planification de l'exécution des événements et de l'observation de sortie. [NET-008](../../network-science/net-008-map-clock-domains-before-ordering-events/) fournit les vérifications de domaines d'horloge.

## 1. Un délai de minuterie demandé n'est pas une heure de rappel mesurée

À la révision de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`, le [composant de progression](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Apps/ga-dashboard/src/app/shared/progression.component.ts#L84-L116) utilise [setTimeout](https://html.spec.whatwg.org/multipage/timers-and-user-prompts.html#timers) avec les durées cumulées des accords. La spécification des minuteries HTML ne garantit pas une planification exacte des rappels.

Pour une séquence pédagogique, les positions demandées des rappels sont 0, 1000 et 2000 ms ; les annotations fictives de rappels exécutés sont 12, 1080 et 2015 ms. Ce sont des relevés inventés, et non des traces extraites.

### Exercice 1 — Distinguer échéances et événements

Calculez le retard de chaque rappel et les deux intervalles entre rappels. Demander un espacement de 1000 ms établit-il que les rappels exécutés ou les accords audibles ont cet espacement ?

> **Réponse:** Les retards sont de 12, 80 et 15 ms. Les intervalles de rappels exécutés sont de 1068 et 935 ms malgré les intervalles demandés de 1000 ms. Une demande n'établit ni l'espacement d'exécution ni la sortie audio. Ces différences pédagogiques ne diagnostiquent pas la machine actuelle.

## 2. Un balayage de cordes planifié constitue une autre limite

Le [code de demande audio](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Apps/ga-dashboard/src/app/shared/progression.component.ts#L140-L190) lit une heure du contexte audio lorsque le rappel s'exécute. Il demande chaque corde sonore à cet ancrage plus son indice physique de corde multiplié par 0.03 seconde, avec des indices commençant à zéro. Les cordes étouffées sont ignorées, mais les indices restants ne sont pas compactés.

Pour la liste pédagogique de cases ci-dessous, les indices des cordes jouées sont 1, 3 et 4 :

```text
frets = [-1, 0, -1, 2, 3, -1]
```

### Exercice 2 — Préserver la séquence demandée

Calculez les décalages demandés des cordes sonores et leurs écarts. Attribuer des rangs consécutifs seulement aux cordes sonores préserverait-il les demandes du code ? L'un ou l'autre ensemble de nombres représente-t-il des débuts physiques observés ?

> **Réponse:** Les décalages sont de 0.03, 0.09 et 0.12 seconde, avec des écarts de 0.06 et 0.03 seconde. Compacter en rangs demanderait plutôt 0, 0.03 et 0.06 seconde, modifiant la planification. Aucun ensemble n'est un début physique observé. Le code sélectionné utilise un oscillateur triangulaire et une enveloppe, et non une mesure de guitare réelle.

## 3. Mesurer les limites nommées par la promesse du produit

Le [tableau de traces pédagogique](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/tempo-clocks-2026-10-22/playback-endpoints.json) définit quatre étapes successives sur une même horloge commune posée en millisecondes : de l'action au gestionnaire, du calcul du gestionnaire à l'appel de planification, de l'appel à la limite de sortie demandée, puis de cette limite à une annotation pédagogique de début de sortie. Ces intervalles ne se chevauchent pas dans ce modèle pédagogique.

| Configuration | Déclenchement du gestionnaire, ms | Calcul, ms | Attente planifiée, ms | Sortie au-delà de la limite demandée, ms |
| --- | --- | --- | --- | --- |
| A | 4 | 4 | 72 | 10, 15, 20, 25 |
| B | 4 | 6 | 40 | 10, 15, 20, 25 |

Les valeurs résultantes de l'action à la sortie sont 90, 95, 100 et 105 ms pour A ; 60, 65, 70 et 75 ms pour B. Les annotations de sortie et les origines partagées sont des prémisses pédagogiques, et non des captures acoustiques réelles ou des observations simultanées de deux configurations.

### Exercice 3 — Classer selon la bonne métrique

Calculez les médianes des durées de calcul et de l'action à la sortie pour les deux configurations, ainsi que chaque différence appariée. Quelle configuration est la plus rapide à chaque limite ? Cela établit-il une amélioration causale dans GA ?

> **Réponse:** Le calcul médian est de 4 ms pour A et de 6 ms pour B. La durée médiane de l'action à la sortie est de 97.5 ms pour A et de 67.5 ms pour B ; les quatre différences appariées de bout en bout sont de 30 ms. A calcule plus vite, tandis que B a la plus petite durée pédagogique au point de sortie utilisateur. Cela illustre la dépendance aux limites choisies, et non une amélioration mesurée ou causale de GA. L'attente planifiée délibérée fait partie de cet intervalle défini et doit rester visible.

## 4. Une règle de latence n'est qu'une condition d'approbation

Pour cet exemple inventé, déclarez que chaque valeur enregistrée de l'action à la sortie doit être d'au plus 80 ms. A n'a aucun essai réussi ; B en a quatre. Les deux étendues sont de 15 ms ; B n'a donc pas réduit ce descripteur particulier de dispersion. Quatre essais pédagogiques n'établissent ni un percentile de queue en production ni une acceptabilité perceptive.

### Exercice 4 — Prendre une décision délimitée

Appliquez la règle de 80 ms, comparez les étendues et précisez ce qui manque encore avant de recommander une nouvelle configuration de lecture par défaut aux guitaristes.

> **Réponse:** A réussit 0 essai sur 4 ; B réussit 4 sur 4. Les deux étendues sont de 15 ms. Seule B satisfait la règle déclarée portant uniquement sur la latence sur ces relevés inventés. Une véritable décision de configuration par défaut exige encore des acquisitions réelles appariées, des relevés d'échecs et de sorties absentes, l'état effectif du navigateur et du périphérique, des vérifications de qualité sonore et du balayage de cordes visé, une couverture répétée des charges de travail et une évaluation adaptée par des musiciens ou auditeurs. Ces nombres n'approuvent aucune véritable mise en production.

## 5. Distinguer les estimations d'API d'un résultat utilisateur capturé

Le [brouillon de travail Web Audio 1.1 daté](https://www.w3.org/TR/2026/WD-webaudio-1.1-20260922/) définit des estimations de latence de traitement et de sortie avec des limites précises. Elles ne mesurent pas à elles seules un intervalle de l'action au début acoustique. Le composant de GA examiné demande des démarrages d'oscillateurs et fixe l'étape surlignée ; il ne contient aucune acquisition de début de sortie. Un accord surligné ou une demande de démarrage réussie ne sont pas un relevé de début audible.

### Exercice 5 — Préparer une comparaison susceptible d'échouer

Rédigez un plan délimité d'acquisition réelle pour une modification de lecture proposée. Identifiez les événements de début et de fin, la correspondance d'horloges, le code et le mode effectif, les sorties absentes, les garde-fous temporels et musicaux et un résultat qui rejetterait la modification. Comparez une alternative de mesure plus simple à un nouveau DSL de télémétrie.

> **Réponse:** Fixez la révision du code, le navigateur et le périphérique, le cycle de vie du contexte, le parcours de sortie effectif, le motif et la charge. Définissez une action d'entrée et un début de sortie détecté indépendamment avec une temporisation commune étalonnée ou une correspondance explicite testée ; conservez les seuils de détection, l'incertitude, les relevés bruts et les sorties absentes. Répétez des comparaisons appariées dont l'ordre est contrebalancé avec une règle déclarée avant l'acquisition, et vérifiez le placement temporel du balayage de cordes visé et la qualité sonore. Rejetez une modification qui échoue aux garde-fous déclarés de latence et de qualité ou dont la comparaison repose sur des preuves temporelles invalides. Une expérience en boucle de retour avec horloge commune peut être plus simple qu'un nouveau DSL. Elle exige encore un véritable étalonnage et une validation ; aucun instrument ou contrat de télémétrie n'ont été implémentés ici.

## Travail de l'apprenant avec accès aux sources

Produisez un court relevé de décision contenant les erreurs et intervalles de rappels, les demandes de balayage selon les indices physiques, les deux classements de métriques, les quatre différences appariées et le résultat de la règle de latence. Ajoutez un plan d'acquisition réelle et un cas explicite de rejet. Consignez l'aide et les inconnues. La [grille d'évaluation de la revue](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/tempo-clocks-2026-10-22/reviewer-rubric.json) prépare des critères mais n'enregistre aucun résultat d'apprenant.

Le [relevé des sources](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/tempo-clocks-2026-10-22/primary-readback.json) lie les fichiers examinés. Ce sont des observations délimitées du code d'un démonstrateur et des modèles pédagogiques de limites de mesure, et non une lecture réelle vérifiée, une nouvelle configuration de production par défaut, un bénéfice d'écoute ou du HTML de cours déployé.
