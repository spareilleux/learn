---
title: Preuves pour un pont d’observatoire entre Godot et React
description: Preuves pour un pont d’observatoire entre Godot et React — Informatique visuelle
sidebar:
  label: VC-002 · Preuves pour un pont d’observatoire entre Godot et React
  order: 2
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/fr/vc-002-godot-react-bridge-evidence.fr.md
---

:::note[Streeling University]
**VC-002** · Preuves pour un pont d’observatoire entre Godot et React · intermédiaire · 35 minutes

Généré par le département *Informatique visuelle* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/fr/vc-002-godot-react-bridge-evidence.fr.md) · [Mon journal](../../journal/)

Prérequis: [VC-001](../../visual-computing/vc-001-accessible-fretboard-paths/)
:::

> **Périmètre du brouillon et des traductions.** Le texte technique ci-dessous est un brouillon daté. Les mentions historiques de traductions, d’intégration dans Learn ou de vérifications de publication encore à faire concernent cette étape antérieure ; ce [dossier de traduction](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/locale-completion-2026-10-22/README.md) recense les brouillons actuels et les contrôles effectués. Les essais en conditions réelles encore non réalisés le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département d'informatique visuelle** | Niveau : intermédiaire | Durée estimée : 35 minutes | Statut : brouillon français ; révision du contenu, essai par un apprenant, révision linguistique humaine et révision avant publication en attente

## Objectifs

Après cette leçon, vous saurez :

- Distinguer un hôte d'iframe React, une scène Godot planifiée et un observatoire 3D dont l'exécution est vérifiée.
- Suivre les messages `godot:ready` et `godot:node-clicked` à travers le contrôle de source et les callbacks de l'hôte.
- Rédiger un contrat mesurable de disponibilité et de source des clics avec une fixture fixe et une future vérification en direct.
- Préciser exactement ce que la lecture des sources peut et ne peut pas prouver concernant un export web ou une technologie de rendu.

## La question du projet

Une carte d'observatoire dans GA propose une vue Godot 3D. Un collègue dit : « Le pont React est versionné, donc la scène Godot est prête ; le parcours de clic 3D fonctionne. » Quelles preuves justifieraient cette affirmation ?

À la révision GA [`dc2e74c`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924), [`GodotScene.tsx`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/GodotScene.tsx) implémente un hôte React avec des vues iframe en panneau et en plein écran. Son `src` par défaut est `/godot/index.html`. Il déclare des types TypeScript de messages, écoute les événements navigateur `message`, traite `godot:ready` et `godot:node-clicked` et expose des callbacks. Le [plan d'intégration Godot versionné](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/parked/2026-03-28-feat-godot-integration-plan.md) coche le travail de pont et d'intégration de Phase 1, mais laisse non cochés la scène Godot de gravité constitutionnelle et l'export web WASM. Le plan est rangé sous `docs/plans/parked/` malgré son ancien en-tête « actif » ; aucune de ces étiquettes n'est une preuve d'exécution.

Une recherche dans les chemins suivis de cet arbre GA figé n'a trouvé ni scène `.gd` ou `.tscn`, ni `godot/index.html`, ni export `.wasm`, ni fichier nommé pour DLSS. C'est un constat limité au dépôt, pas une preuve sur d'autres branches, la machine d'un développeur, des ressources déployées ou tous les noms possibles d'implémentation. Un parcours de rendu DLSS dérivé d'un fork est hors du pont examiné et reste non vérifié. L'iframe du composant et son texte de repli n'établissent pas qu'un export Godot existe ou s'exécute.

### Exercice pratique 1 : classer les preuves

Classez chaque affirmation comme **étayée par les sources**, **planifiée ou non vérifiée** ou **nécessitant une exécution en direct** : (a) React déclare une iframe dont la valeur par défaut est `/godot/index.html` ; (b) la scène de gravité Godot rend des nœuds de politique ; (c) cliquer sur un véritable nœud Godot sélectionne l'enregistrement React correspondant ; (d) le DLSS dérivé d'un fork améliore l'image de l'observatoire.

> **Réponse :** (a) est étayée par le composant React figé. (b) est une scène planifiée avec du travail non coché dans le plan figé. (c) exige une véritable scène ou un export et une trace observée des callbacks ; la déclaration de l'hôte seule ne peut pas le prouver. (d) n'est pas vérifiée dans l'arbre examiné et exige une implémentation identifiée séparément et une mesure.

## 1. Définir un petit contrat de pont

L'union TypeScript de messages sortants de l'hôte comprend `{ type: 'godot:ready' }` et `{ type: 'godot:node-clicked', nodeId: string }`. Son gestionnaire de messages compare `ev.source` au `contentWindow` de l'iframe montée **lorsque la ref de l'iframe existe**. Il vérifie ensuite que `ev.data.type` est une chaîne et choisit une branche selon les deux types de messages. Un `godot:ready` de source correspondante active une ref interne de disponibilité, efface l'état de chargement et appelle `onReady`. Un `godot:node-clicked` de source correspondante appelle `onNodeClick` avec `msg.nodeId`.

Ce sont des comportements décrits dans les sources, pas un contrat complet de confiance ou de disponibilité. Le gestionnaire ne compare pas `ev.origin`, ne valide pas `nodeId` à l'exécution et n'exige pas l'état prêt avant d'accepter un clic. Si la ref de l'iframe est absente, la comparaison de source est sautée. L'assertion TypeScript `as GodotOutboundMessage` ne valide pas un événement navigateur entrant. Les messages sortants utilisent `postMessage(msg, '*')` ; un futur déploiement entre origines exige un choix explicite d'origine cible. Pour la fixture de cette leçon, supposons l'iframe montée et les deux callbacks installés, de sorte que la comparaison de source s'applique.

### Exercice pratique 2 : vérifier l'expéditeur

Une fenêtre autre que l'iframe montée émet `{ type: 'godot:ready' }`. L'iframe montée émet ensuite le même message. Lequel appelle `onReady` selon les hypothèses de la fixture ? Une correspondance de `ev.source` suffit-elle à établir la validité de la charge utile ou le rendu de la scène ?

> **Réponse :** Le message de la fenêtre étrangère est rejeté par la comparaison de source du gestionnaire. Le message de l'iframe montée active la ref de disponibilité et appelle `onReady`. L'égalité de source n'est qu'un contrôle : le gestionnaire n'examine pas l'origine et ne valide pas les champs de la charge utile à l'exécution, et un message prêt ne prouve pas que la scène a rendu une image.

## 2. Suivre une fixture synthétique fixe de messages

C'est une **fixture de raisonnement**, pas un test navigateur ou une exécution Godot observée. Soit `F` le `contentWindow` de l'iframe montée et `X` une autre fenêtre. Commencez avec `readyRef = false`, `loading = true` et les compteurs de callbacks à zéro. Fournissez ces événements au gestionnaire de l'hôte dans cet ordre :

| Étape | Source | Événement ou horloge | Ce que fait le gestionnaire figé |
|---|---|---|---|
| 1 | X | `{ type: 'godot:ready' }` | L'ignore, car la source diffère de F |
| 2 | F | `{ type: 'godot:node-clicked', nodeId: 'belief-7' }` | Appelle `onNodeClick('belief-7')` même avant l'état prêt |
| 3 | F | `{ type: 'godot:ready' }` | Active l'état prêt, efface le chargement, appelle `onReady` |
| 4 | F | `{ type: 'godot:ready' }` à nouveau | Appelle encore `onReady` ; aucune déduplication n'est codée |
| 5 | F | `{ type: 'godot:node-clicked', nodeId: 'belief-8' }` | Appelle `onNodeClick('belief-8')` |
| 6 | horloge | Le délai de quinze secondes expire | Trouve l'état prêt à vrai et ne change rien au repli |

La fixture prédit **deux callbacks de disponibilité et deux callbacks de clic**, dont un clic avant l'état prêt. Elle n'affirme pas que Godot a effectivement émis l'un de ces messages. Si aucun message prêt n'arrive, le délai masque l'indicateur de chargement après 15 secondes sans activer la ref de disponibilité ni signaler d'erreur ; « indicateur disparu » ne signifie pas « scène prête ». Le mode panneau de l'hôte affiche initialement l'onglet Builder ; l'iframe peut donc ne pas être montée avant la sélection de l'onglet Viewer.

### Exercice pratique 3 : compter les callbacks

À partir du seul tableau et du gestionnaire figé, énumérez la séquence des callbacks. Que devrait éviter de déduire un tableau de bord d'observatoire de l'étape 6 ?

> **Réponse :** Les callbacks sont `onNodeClick('belief-7')`, `onReady()`, `onReady()`, puis `onNodeClick('belief-8')`. L'étape 1 n'en produit aucun. Le délai de l'étape 6 n'en produit aucun, car l'état prêt est déjà vrai. Dans une exécution sans événement prêt, le délai peut tout de même supprimer l'indicateur ; un tableau de bord ne doit donc pas déduire la disponibilité de sa disparition.

## 3. Rendre le comportement souhaité mesurable

Un futur contrat produit peut être plus strict que le gestionnaire actuel. Pour une iframe montée et une génération de chargement, proposez : n'accepter l'état prêt que de la source attendue et d'une origine autorisée, avec une charge utile valide ; compter **une** transition de disponibilité ; n'accepter un clic qu'après cette transition, depuis la même source et la même origine, avec un `nodeId` connu non vide ; transmettre chaque clic intentionnel à React **exactement une fois**. Un rechargement commence une nouvelle génération et remet les compteurs à zéro. C'est une règle d'acceptation proposée, pas une description du code actuel. Les étapes 2 et 4 de la fixture synthétique échoueraient à ses conditions de clic avant disponibilité et de disponibilité répétée.

Après l'existence d'une véritable scène Godot et d'un export web, une vérification en direct du pont pourrait utiliser un **hôte de test dédié qui garde l'iframe montée pendant une génération de chargement**. Consignez le SHA de compilation et le navigateur, attendez un événement prêt, effectuez **20 clics de nœuds connus** et comparez les 20 identifiants attendus aux 20 identifiants de callbacks dans l'ordre, sans doublons. Le [parent Prime Radiant figé](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx) passe au détail après un clic reconnu dans le panneau et ferme la vue plein écran après son callback de clic ; une exécution de 20 clics dans cet hôte produit exigerait une réouverture et une nouvelle étape de disponibilité pour chaque clic. Injectez des messages synthétiques de source étrangère et antérieurs à la disponibilité dans le harness dédié et exigez **zéro callback de source étrangère** et **zéro callback de clic avant disponibilité** ; renvoyez le message prêt et exigez l'absence de seconde transition. Consignez la source du message, son origine, le résultat de validation de la charge utile, le nombre de callbacks et une observation de rendu d'image ou une capture d'écran. Une capture seule ne peut pas prouver le routage des clics ; une trace de callbacks seule ne peut pas prouver que la scène Godot s'est rendue correctement. Tant que ces observations n'existent pas, le contrat reste une proposition de test.

### Exercice pratique 4 : tester la disponibilité

Un essai en direct indique que l'indicateur de chargement a disparu après 15 secondes, mais ne consigne aucun message `godot:ready`. Peut-il compter la scène comme prête ? Nommez une observation supplémentaire nécessaire.

> **Réponse :** Non. Le délai de l'hôte efface le chargement sans activer la disponibilité. Consignez un événement prêt valide issu de l'iframe montée selon les règles d'origine et de charge utile choisies, et observez une image rendue ou un autre signal explicite de disponibilité de la scène avant d'affirmer que la vue 3D fonctionne.

### Exercice pratique 5 : fixer une condition de réussite

Un futur test avec hôte dédié envoie 20 clics connus après disponibilité, reçoit 19 callbacks React correspondants et obtient un callback d'une fenêtre étrangère. Passe-t-il le contrat proposé ? Donnez les nombres attendus et observés, et nommez un artefact nécessaire avant de l'exécuter.

> **Réponse :** Non. Le contrat exige 20/20 callbacks ordonnés, exactement une fois chacun, et zéro callback de source étrangère ; l'essai comporte 19/20 callbacks connus et un callback de source étrangère. Une scène Godot versionnée et un export web servi à l'URL de l'iframe sont nécessaires avant que cela puisse être un test de scène en direct. Conservez le SHA de compilation et la trace des événements pour diagnostiquer les callbacks manquants et étrangers.

## Points à retenir

- Un hôte React versionné prouve l'existence d'un hôte et d'un gestionnaire, pas celle d'une scène Godot en cours d'exécution.
- Messages prêts, indicateurs de chargement, images rendues et callbacks de clic sont des observations distinctes.
- Source, origine, structure de charge utile, génération de chargement et nombres de callbacks ont leur place dans un contrat de pont mesurable.
- Le gestionnaire actuel accepte les clics avant disponibilité et les messages prêts répétés dans la fixture fixe de raisonnement ; une règle produit plus stricte exige une implémentation et des tests en direct.
- Une phase de plan non cochée ou un fichier absent d'un arbre figé limite l'affirmation ; ce n'est pas une déclaration universelle sur tous les environnements.

## Preuves du projet et limites

- GA figé : [`GodotScene.tsx`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/GodotScene.tsx), [parent Prime Radiant](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx) et [plan d'intégration Godot mis en attente](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/parked/2026-03-28-feat-godot-integration-plan.md). L'examen des sources portait sur cet arbre figé ; il n'a pas exécuté la scène ni audité de déploiement.
- [VC-001](../../visual-computing/vc-001-accessible-fretboard-paths/) traite d'une exigence distincte : une vue 3D doit préserver les informations utiles et les actions disponibles par pointeur, clavier et lecteur d'écran. Le contrat de pont présenté ici n'achève pas cette vérification d'accessibilité.
- La fixture en six étapes et le seuil d'acceptation de 20 clics sont des artefacts pédagogiques et de proposition de test. Aucun environnement d'exécution Godot, export WASM, implémentation DLSS dérivée d'un fork, révision du contenu, essai d'apprenant, localisation ou relecture publique n'a été vérifié pour cette leçon.

*Recherche : `visual-computing-2026-10-11-002`. Brouillon français uniquement ; révisions humaine du contenu, linguistique et par un apprenant, ainsi que publication, en attente.*
