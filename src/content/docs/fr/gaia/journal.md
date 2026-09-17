---
title: Journal
description: "Notes d'avancement datées du cours Gaia : la révision épinglée et la façon dont elle a été exécutée, ce que la suite de tests et le vérificateur ont réellement rapporté, les surprises (un refus qui est lui-même un événement, un verify qui affichait autrefois une coche rouge et sortait avec 0), et la liste de ce qui reste à vérifier, à commencer par l'exécution de l'usine qui dépense de vrais tours de modèle."
sidebar:
  order: 99
---

## Avancement

- [x] Révision épinglée choisie et extraite proprement ; chaque commande relancée sur elle
- [x] Leçon 1 : le problème, les quatre axes, la doctrine
- [x] Leçon 2 : les six verbes, avec un vrai échange entre trois acteurs
- [x] Leçon 3 : le journal d'événements, le protocole de commit, `verify`
- [x] Leçon 4 : le traceur de coordination, l'usine d'agents, les reçus et l'empreinte de l'arbre
- [x] Leçon 5 : l'échelle des voies et les verdicts sur l'écosystème
- [ ] `factory:agent` exécuté de bout en bout avec de vrais tours de Claude et de Codex
- [ ] Versions française et espagnole
- [ ] Une leçon sur la pompe hébergée, le côté GitHub Actions, que `main` a fait grandir et que ce cours ne couvre pas

## 2026-09-15 — Installation et versions

- **Gaia** au commit [`d68e900`](https://github.com/GuitarAlchemist/gaia/tree/d68e90099ae2a6fbbec9d428617bfcd02095aac0), la tête de `main` le 13 septembre 2026. Extrait dans un worktree lié détaché, pour que l'arbre soit propre et que rien de local ne fuie dans une sortie.
- **Node.js** v24.12.0 sous Windows 11. Gaia épingle une version exacte, `.node-version` et `engines.node` indiquant tous deux **26.8.1**, et rien ne l'impose quand tu appelles `node` toi-même : tout ce qui figure dans ces leçons a donc tourné sur la 24.12.0, sans avertissement ni échec. L'exécution sur la version épinglée est *à vérifier* ; le chemin de CI est Windows avec cette version, et Ubuntu y est décrit comme une exploration de la portabilité plutôt que comme une condition bloquante.
- **Aucune dépendance** : pas de `npm install` avant tout cela, et pas de `node_modules` dans un clone propre. Ce n'est pas un argument marketing : `package.json` n'a ni clé `dependencies` ni clé `devDependencies`, et le lanceur de tests est `node --test`.
- Chaque commande du bus a tourné sur un répertoire de données jetable, via `GAIA_INTERAGENT_DATA_DIR`, pour que rien ne touche un vrai espace de travail. Les sorties sont collées telles quelles, à part les chemins absolus raccourcis en `…`.

## 2026-09-15 — Ce que les commandes ont réellement rapporté

| Commande | Résultat |
|---|---|
| `doctor`, répertoire vide | `ok: true`, code de sortie 0, `supportedMaxLiveLanes: 4`, et une note qui invite à lancer `initialize --apply` |
| `initialize` | à blanc par défaut ; `--apply` a ajouté exactement un `actor.registered` |
| `bus-cli tools` | exactement 6 : `register`, `send`, `inbox`, `ack`, `heartbeat`, `handoff` |
| `verify` | **37 vérifications réussies, 0 en échec**, en 8 sections, `evidenceGatesResult: false` |
| `node --test` | **2 075 tests, 2 074 réussis, 0 en échec, 1 ignoré**, en 38,9 s |
| `factory:smoke` | `completed`, point fixe du journal de preuves `sha256:256a51d2…` sur 15 événements et 6 315 octets, `evidenceGatesResult: true` |
| `inventory-digest` | 323 fichiers, 5 937 493 octets, `ordinal-path-bytes-sha256/1 dccabe8f…` |

L'échange complet entre trois acteurs de la leçon 2 a occupé **10 événements et 3 617 octets** sur disque. Ce nombre mérite d'être gardé en tête à côté du modèle de coût de la leçon 5 : le rejeu est en O(événements × acteurs), et une vraie session de coordination à plusieurs est minuscule.

## 2026-09-15 — Surprises

**Un refus est un événement.** S'adresser à un nom d'acteur ambigu renvoie `ok: false`, sort avec 1, et ajoute `command.rejected` au journal. Je m'attendais à ce que le refus soit une valeur de retour, sans plus. C'est le détail qui permet au journal de répondre à « qu'est-ce que cette session a tenté ? » et pas seulement à « qu'a-t-elle accompli ? », et une fois qu'on l'a vu, il devient difficile d'accepter un système qui ne consigne que les succès.

**`verify` affichait autrefois une coche rouge et sortait avec 0.** Le README consigne la correction : `doctor` et `verify` sortaient tous deux avec 0 sur un journal dont une passation avait transféré de l'autorité, *alors que `verify` affichait sa propre coche rouge qui disait le contraire*. Un lecteur qui se fiait au code de sortie, ou à `ok`, y voyait une réussite. Un outil qui signale un échec et renvoie un succès, c'est exactement le mode de défaillance dont parle la leçon 1, trouvé à l'intérieur du vérificateur ; c'est un bon argument pour les contrôles négatifs, qui sont désormais toujours bloquants.

**Les vérifications de preuves se répartissent en deux régimes, et c'est voulu.** Cinq d'entre elles, à savoir trois acteurs, plus d'une sorte d'acteur, un fil corrélé, un accusé de réception et une passation, sont légitimement fausses sur un espace de travail vide et correct : elles font donc un rapport sans bloquer, sauf si l'appelant affirme que le journal *est* une preuve. J'avais supposé qu'un vérificateur vérifie quelque chose ou ne le vérifie pas. Que la charnière soit l'affirmation de l'appelant plutôt que l'opinion de l'outil est une meilleure conception que chacune des deux options.

**`resolveLaneLimit` prend un objet d'options.** Appelée avec un argument positionnel, elle renvoie la valeur par défaut en silence, et c'est ainsi que je l'ai d'abord mal mesurée. `resolveLaneLimit({ requested: 6 })` lève une exception avec l'énoncé complet des preuves ; `resolveLaneLimit(6)` renvoie `{ limit: 4 }`. C'est à noter, puisque tout l'argument du module est que le plafonnement silencieux est l'erreur : le refus est réel, mais seulement avec la forme d'appel documentée.

**Les résidus sont publiés, pas enterrés.** Le document de conception de l'usine indique qu'on ne peut pas prouver qu'un worker tournant sous l'utilisateur de l'hôte a évité le réseau, les secrets ou des écritures ailleurs, et qu'un reçu qui affirmerait ce confinement exigerait une frontière séparée au niveau du système d'exploitation. La plupart des projets auraient écrit « exécute les agents dans un espace de travail isolé ». Celui-ci nomme la lacune et la capacité qui la comblerait.

**`main` a largement dépassé ce que couvre ce cours.** La pompe Draft hébergée sur GitHub Actions, le réseau de Petri de vidange, la salle de contrôle, la recherche hybride, la sonde de capacités des runners, les cycles gérés de livraison de PR, la réception des observations de tests : `docs/` contient une cinquantaine de dossiers de conception à la révision épinglée. Les cinq leçons couvrent le bus, le journal, l'usine et les limites. C'est une tranche délibérée, en balle traçante, pas une carte complète.

## 2026-09-15 — Corrections faites pendant la rédaction

- J'avais d'abord cité le fichier `AGENTS.md` du dépôt pour la règle « le privilège est empêché par l'absence ». **Ce fichier n'existe pas au commit `d68e900`** : c'était un fichier non suivi dans un clone local d'une branche plus ancienne. La citation a été remplacée par l'énoncé du `README.md` et par l'en-tête du module opérateur lui-même, tous deux vérifiés présents à la révision épinglée. Toutes les autres citations ont été revérifiées sur l'arbre épinglé pour la même raison.
- La copie de travail locale dont je suis parti était sur une branche du 29 août 2026, dont le `README.md` différait de celui de `main`, et qui n'avait ni `ARCHITECTURE.md` ni `CONTEXT.md`. Partir d'un worktree épinglé et propre, plutôt que du clone qui se trouvait ouvert, est l'habitude qui l'a détecté.

## À vérifier

- **`factory:agent` de bout en bout.** Il dépense un vrai tour de Claude et un vrai tour de Codex sur les abonnements installés. La leçon 4 le décrit à partir de `src/factory-agent.mjs`, de son document de conception et du schéma de ses reçus ; aucune affirmation de cette leçon ne vient d'une exécution observée. Ce qu'il faudra capturer quand il tournera : la forme du reçu avec et sans réparation, les lignes de progression `(not an ETA)`, et si la vérification des modifications faites par le relecteur se déclenche en pratique sur des fichiers ignorés.
- **Node 26.8.1**, la version épinglée. Tout ici a tourné sur la 24.12.0.
- **Linux et macOS.** Le protocole de commit est écrit et testé d'abord pour Windows, et le dépôt dit que Linux relève de l'exploration plutôt que d'une condition bloquante. L'approche par répertoire de verrou devrait se comporter de la même façon ; les nouvelles tentatives de libération propres à Windows ne seraient simplement pas exercées.
- **Une seconde voie concurrente sur le même répertoire de données.** Toutes les sorties de ces leçons viennent d'appels séquentiels dans un seul shell. L'unicité des identifiants entre processus est ce qu'affirme la suite de tests, pas ce que j'ai observé.
- **L'indicateur `authority-language-detected`.** Je l'ai vu se déclencher sur « Please merge this. » Je n'ai pas regardé ce qu'il reconnaît, et le taux de faux négatifs d'une heuristique est le nombre intéressant.

## Questions ouvertes

- Le bus sérialise les écritures et n'a **aucune authentification** : la confiance est positionnelle, donc tout processus capable de lancer le serveur peut s'enregistrer comme n'importe quel acteur. La leçon 5 montre que c'est l'un des deux obstacles nommés à l'intégration avec IX. Quel est le plus petit mécanisme d'identité des acteurs qui ne transformerait pas le bus en coffre à identifiants ?
- Le rejeu est en O(événements × acteurs) sur un journal qui n'est jamais compacté, et `inbox` écrit un événement. Une voie qui interroge sa boîte régulièrement ralentit donc chaque appel suivant. Existe-t-il un chemin de lecture qui garde `inbox.polled` comme preuve sans le payer à chaque rejeu, par exemple un instantané suivi de la fin du journal, comme le suggère le document sur l'échelle ?
- Le nombre de quatre voies admet honnêtement ne pas avoir été répliqué avec de vrais clients. Lancer cette sonde exige quatre vraies voies d'agent simultanées, ce qui coûte de vrais tours de modèle. Quelle est l'expérience la moins chère qui permettrait réellement de trancher ? Et un mélange d'une vraie voie et de trois voies synthétiques prouverait-il quelque chose, ou serait-ce la sonde à workers Node, avec des étapes en plus ?
