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
- [x] Leçon 6 : continuité bornée, réconciliation exacte du wake et chaîne de reçu Gaia vers Demerzel
- [ ] `factory:agent` exécuté de bout en bout avec de vrais tours de Claude et de Codex
- [x] Versions française et espagnole
- [ ] Une leçon sur la pompe hébergée, le côté GitHub Actions, que `main` a fait grandir et que ce cours ne couvre pas

## QA

Constats faits en exécutant la pompe hébergée de Gaia sur son propre dépôt, observés à `main` [`8ed4dfc`](https://github.com/GuitarAlchemist/gaia/tree/8ed4dfca865696f6b54cb37ce077b0d10ece35df).

| Attendu | Ce qui se passe | Où | Mesure | Statut |
|---|---|---|---|---|
| Une issue labellisée peut devenir une Draft | L'intake exige exactement une branche portant les trailers de preuve de l'issue, et rien ne la produisait ; zéro branche est refusé comme deux, en `HeadIdentityAmbiguous` | [`src/hosted-draft-collector.mjs:319`](https://github.com/GuitarAlchemist/gaia/blob/8ed4dfca865696f6b54cb37ce077b0d10ece35df/src/hosted-draft-collector.mjs#L319) | 2 branches sur 79 portaient les trailers, toutes deux faites à la main ; l'intake planifié renvoyait `EXPECTED_NONE` depuis des jours | Correctif proposé dans [gaia#155](https://github.com/GuitarAlchemist/gaia/pull/155), puis observé en fonctionnement réel [2026-09-25](#2026-09-25--la-pompe-hébergée-de-bout-en-bout-jusquà-la-draft) |
| Une opération de Draft ambiguë est réconciliée | L'opération de l'issue 127 reste `EFFECT_AMBIGUOUS` et est sautée à chaque passage planifié ; elle ne bloque pas la file, mais rien ne la règle | [`src/hosted-draft-pump.mjs:310`](https://github.com/GuitarAlchemist/gaia/blob/8ed4dfca865696f6b54cb37ce077b0d10ece35df/src/hosted-draft-pump.mjs#L310) | Présente dans chaque reçu d'intake du 2026-09-15 au 2026-09-24 | Reproduit, non signalé |
| Un seeder qui a écrit une branche le dit | Une connexion interrompue pendant la relecture le faisait sortir en fail-closed alors que la branche existait | [`src/evidence-head-seeder.mjs:147`](https://github.com/GuitarAlchemist/gaia/blob/49d5fb3d6e4f5aa9e82cac0fb018d2c118c2958c/src/evidence-head-seeder.mjs#L147) (après correction) | 1 occurrence, sur l'issue 106 | Corrigé dans [gaia#155](https://github.com/GuitarAlchemist/gaia/pull/155) (`49d5fb3`) |
| Une issue dont le travail est livré est fermée | L'issue 108 était ouverte alors que sa porte de contrôle était sur `main` ; le worker de l'usine n'a rien modifié | [`tests/hexagonal-direction.test.mjs`](https://github.com/GuitarAlchemist/gaia/blob/8ed4dfca865696f6b54cb37ce077b0d10ece35df/tests/hexagonal-direction.test.mjs) | 0 modification, 1 exécution de l'usine dépensée | Reproduit, non signalé |
| Un job de l'usine se termine après son worker | Le job de l'issue 108 était encore `STARTED` une dizaine d'heures après la fin de son worker, occupant l'unique place de l'hôte | `C:/Gaia/state`, `portfolio:autonomous status` | Worker terminé à 00:25 heure locale, job `STARTED` à 10:00 | *À vérifier* |

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

## 2026-09-20 — Candidat de continuité de l'issue 76

- Le Design Receipt v7.4 a reçu une revue indépendante avant implémentation. Le candidat est borné à une identité, un slot et un remplacement génération 0 vers 1.
- Gaia isolé : **2 261 tests, 2 259 réussis, 0 échec, 2 omis**; régression ciblée **87/87**; `verify` **37 réussites, 0 échec**; vérificateur d'architecture réussi.
- Demerzel isolé : **787 tests Python avec 1 omission** et **10/10 contrôles IXQL**, validation en lecture seule des schémas/fixtures Gaia vendorés.
- La revue/intégration a corrigé l'import direct de la persistance, la décision avant preuve du wake livré, le replay d'une entrée différente sous la même clé et un test sans sidecar. Une passe de simplification a supprimé des scans et allocations évitables.
- Ce sont des mesures de worktrees candidats, pas une preuve de publication, fusion ou release. Le reçu de revue formelle, les gates du commit final et les PR restaient en attente.

## 2026-09-25 — La pompe hébergée, de bout en bout jusqu'à la Draft

- **Pourquoi rien ne sortait.** `hosted-draft-intake.yml` tournait toutes les 6 h, avec succès, et renvoyait `EXPECTED_NONE` depuis des jours. Deux causes, toutes deux côté Gaia : aucune issue ouverte ne portait `ready-for-agent`, et le collecteur exige exactement une branche dont la pointe porte `Gaia-Issue: N` et `Gaia-Ready-Receipt: <hash de l'événement de label>`. **Aucun code ne produisait cette branche.** Les deux seules qui aient existé avaient été faites à la main, et zéro branche est refusé de la même façon que deux (`HeadIdentityAmbiguous`, car le test est `matching.length !== 1`). Les automations Augment Cosmos étaient une fausse piste : la pompe n'en a jamais dépendu.
- **La réparation**, [gaia#155](https://github.com/GuitarAlchemist/gaia/pull/155) : `npm run draft:seed-evidence -- --issue N --apply` crée `gaia/issue-N-ready-K`, un commit qui réutilise l'arbre de la branche par défaut, donc sans aucun fichier modifié. Il calcule le reçu avec la fonction même du collecteur, extraite plutôt que recopiée, ne pose jamais le label, et laisse la relecture décider du résultat.
- **Observé en direct sur l'issue 108 :** label → seed `CREATED` → intake `ADMIT` → Draft [gaia#156](https://github.com/GuitarAlchemist/gaia/pull/156) → l'usine locale (`portfolio:autonomous watch`, activée une fois avec un budget de 20 exécutions) l'a prise en moins d'une minute. La même chaîne a produit [gaia#158](https://github.com/GuitarAlchemist/gaia/pull/158) pour l'issue 104.
- **Deux refus qui étaient justes :** l'issue 148 est revenue en `StaleRevision`, parce que la pompe l'avait déjà mise en Draft le 2026-09-13 (#149) : une seule Draft par unité de travail. Le worker de l'usine sur 108 n'a fait **aucune modification**, car `tests/hexagonal-direction.test.mjs` était déjà sur `main` : l'issue était restée ouverte après la livraison de son travail.
- **Un défaut trouvé en l'exécutant :** une connexion interrompue pendant la relecture, après une écriture réussie, faisait sortir le seeder en fail-closed, ce qui laissait croire que rien n'avait été écrit, alors que la branche existait bien. Il répond désormais `AMBIGUOUS`, et une relance répond `PRESENT`.
- **Ce que la pompe ne fait pas, par conception :** décider de ce qui est prêt. `ready-for-agent` est l'acte d'autorité de l'opérateur. Un alimenteur qui choisissait et labellisait son propre travail a été refusé par le classifieur de permissions de l'agent comme agent dangereux, la même ligne que le « rien ne s'auto-autorise » de Gaia. À la place, un classement en lecture seule ([gaia#157](https://github.com/GuitarAlchemist/gaia/pull/157)). Aujourd'hui il trouve **une** candidate parmi 38 issues ouvertes, parce que 34 portent encore `needs-triage` : le goulot, c'est le grooming, pas la pompe.

## À vérifier

- **Le job de l'usine sur l'issue 108.** Son worker a terminé à 00:25 heure locale, mais le job était encore `STARTED` une dizaine d'heures plus tard, occupant l'unique place de l'hôte, donc la Draft de l'issue 104 attend. Établir si le processus `watch` s'est arrêté ou si l'étape de relecture n'a jamais démarré, et quelle réconciliation fait un redémarrage.
- **`factory:agent` de bout en bout.** Il dépense un vrai tour de Claude et un vrai tour de Codex sur les abonnements installés. La leçon 4 le décrit à partir de `src/factory-agent.mjs`, de son document de conception et du schéma de ses reçus ; aucune affirmation de cette leçon ne vient d'une exécution observée. Ce qu'il faudra capturer quand il tournera : la forme du reçu avec et sans réparation, les lignes de progression `(not an ETA)`, et si la vérification des modifications faites par le relecteur se déclenche en pratique sur des fichiers ignorés.
- **Node 26.8.1**, la version épinglée. Tout ici a tourné sur la 24.12.0.
- **Linux et macOS.** Le protocole de commit est écrit et testé d'abord pour Windows, et le dépôt dit que Linux relève de l'exploration plutôt que d'une condition bloquante. L'approche par répertoire de verrou devrait se comporter de la même façon ; les nouvelles tentatives de libération propres à Windows ne seraient simplement pas exercées.
- **Une seconde voie concurrente sur le même répertoire de données.** Toutes les sorties de ces leçons viennent d'appels séquentiels dans un seul shell. L'unicité des identifiants entre processus est ce qu'affirme la suite de tests, pas ce que j'ai observé.
- **L'indicateur `authority-language-detected`.** Je l'ai vu se déclencher sur « Please merge this. » Je n'ai pas regardé ce qu'il reconnaît, et le taux de faux négatifs d'une heuristique est le nombre intéressant.
- **L'issue 76 après revue finale.** Relancer les gates Gaia et Demerzel sur les commits exacts, publier par des PR normales et remplacer les preuves candidates par des liens immuables.

## Questions ouvertes

- Le bus sérialise les écritures et n'a **aucune authentification** : la confiance est positionnelle, donc tout processus capable de lancer le serveur peut s'enregistrer comme n'importe quel acteur. La leçon 5 montre que c'est l'un des deux obstacles nommés à l'intégration avec IX. Quel est le plus petit mécanisme d'identité des acteurs qui ne transformerait pas le bus en coffre à identifiants ?
- Le rejeu est en O(événements × acteurs) sur un journal qui n'est jamais compacté, et `inbox` écrit un événement. Une voie qui interroge sa boîte régulièrement ralentit donc chaque appel suivant. Existe-t-il un chemin de lecture qui garde `inbox.polled` comme preuve sans le payer à chaque rejeu, par exemple un instantané suivi de la fin du journal, comme le suggère le document sur l'échelle ?
- Le nombre de quatre voies admet honnêtement ne pas avoir été répliqué avec de vrais clients. Lancer cette sonde exige quatre vraies voies d'agent simultanées, ce qui coûte de vrais tours de modèle. Quelle est l'expérience la moins chère qui permettrait réellement de trancher ? Et un mélange d'une vraie voie et de trois voies synthétiques prouverait-il quelque chose, ou serait-ce la sonde à workers Node, avec des étapes en plus ?
