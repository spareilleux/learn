---
title: Journal
description: Notes de progression datées du cours SlashForge — la version étudiée, ce qu'écrit l'installeur et où son exécution à blanc, son README et ses commentaires le contredisent, où sa vérification du frontmatter contredit Claude Code, et les points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] SlashForge 4.4.3 fixé dans `code/slashforge/package.json` ; `check.sh` lance l'installeur dans un répertoire personnel jetable et dans un dépôt jetable
- [x] CI : `check.sh` sous Linux, Windows et macOS, sans Claude Code et sans clé d'API
- [x] Leçon 1 : ce qu'écrit l'installeur
- [x] Leçon 2 : dans les fichiers — commandes, skills, guides
- [ ] Leçon 3 : `/slashforge:setup` face à `/init`, sur un dépôt public
- [ ] Leçon 4 : `/slashforge:code`, dix phases et quatre points de contrôle
- [ ] Leçon 5 : `-quick`, `/slashforge:investigate` et `/slashforge:review-pr`
- [ ] Leçon 6 : se l'approprier

## QA

Chaque ligne ci-dessous est reproduite par `check.sh` ou lue dans l'installeur au tag `v4.4.3`. Aucune n'a été signalée en amont : le dépôt n'avait aucune issue ouverte ou fermée le 2026-09-22, et ses tests ne couvrent pas l'exécution à blanc.

Il n'y a pas encore de tableau d'expériences : rien ici n'a été mesuré face à une hypothèse écrite à l'avance. Les leçons 3 à 5, qui font exécuter les commandes par le modèle, sont celles où cela changera.

| Attendu | Ce qui se passe | Où | Mesure | État |
|---|---|---|---|---|
| `--dry-run` liste ce qu'écrit l'installation | Il liste 21 fichiers ; l'installation en écrit 32. Les neuf skills, `forge-open.sh` et `forge-report-shell.html` manquent | [`bin/install.js#L499-L528`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L499-L528) construit sa propre liste à partir de deux des quatre tableaux | `l01_dry_run_vs_install` : 11 écrits, non annoncés ; 0 annoncé, non écrit | Reproduit, non signalé [2026-09-22](#2026-09-22--linstalleur-lu-et-exécuté) |
| L'exécution à blanc indique pour chaque fichier ce que l'installation en fait | Elle dit `copy` pour chaque guide. Les guides sont rendus depuis la 4.4.1 | mêmes lignes | `l02_global_vs_project` : deux guides diffèrent entre l'installation globale et l'installation de projet, ce qu'une copie ne pourrait pas faire | Reproduit, non signalé [2026-09-22](#2026-09-22--linstalleur-lu-et-exécuté) |
| Le *What gets installed* du README décrit la 4.4.3 | Il décrit trois commandes dans `commands/forge/` ; la 4.4.3 écrit quatre commandes et neuf skills dans `commands/slashforge/` | [`README.md#L103-L112`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/README.md#L103-L112) | `l01_files` | Reproduit, non signalé [2026-09-22](#2026-09-22--linstalleur-lu-et-exécuté) |
| Les commentaires de l'installeur décrivent son code | Trois sont plus anciens que lui : *"the three entry points"* au-dessus d'une liste de quatre ; `'forge/setup.md' -> '/slashforge:setup'` au-dessus de `commandName` ; *"a namespace subdirectory (forge/)"* là où il écrit `slashforge/` | [`#L45-L50`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L45-L50), [`#L182-L183`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L182-L183), [`#L259-L260`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L259-L260) | `l02_installer_functions` : `commandName('slashforge/setup.md')` donne `/slashforge:setup` | Lu ; commentaires seulement, aucun comportement affecté |
| `--yes`, que l'aide associe à *"the update prompt"* (la question de mise à jour), ne répond pas aux autres questions | Quand l'entrée standard n'est pas un terminal, il est actif, et `uninstall` supprime tout sans demander | [`#L628-L633`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L628-L633) | `l01_uninstall` : 15 suppressions, code de sortie 0, aucune question | Reproduit ; documenté en partie |
| Un modèle que Claude Code accepte, l'installeur l'accepte | L'installeur lit le frontmatter ligne par ligne : une `description: >` YAML repliée est refusée, et un `---` de fermeture suivi d'une espace n'est pas trouvé, alors que le délimiteur d'ouverture est nettoyé | [`#L113-L137`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L113-L137) | `l02_installer_functions` : 6 refus sur 7 échantillons | Reproduit ; ne concerne que les modèles que tu ajoutes |
| Le champ `name` qu'exige l'installeur nomme la commande | Claude Code ignore `name` dans un fichier sous `commands/` ; c'est le chemin qui nomme la commande | [Claude Code, skills](https://code.claude.com/docs/en/skills#where-skills-live) | — | Documenté des deux côtés ; un piège au renommage (leçon 2, exercice 1) |

## 2026-09-22 — L'installeur, lu et exécuté

SlashForge 4.4.3 (tag `v4.4.3`, commit `bd75a4f`), Node.js 24.21.0, Windows 11. L'installeur sur `main` était le même fichier ce jour-là.

Le cours ne laisse pas l'installeur approcher le vrai `~/.claude`. `check.sh` fait pointer `HOME`, et `USERPROFILE` sous Windows, vers `out/home`, pose `SLASHFORGE_NO_UPDATE_CHECK=1` pour que la vérification de version n'atteigne pas npm, et lance chaque commande avec l'entrée standard depuis `/dev/null`, comme la CI. Ce dernier choix révèle un comportement à part entière : sans terminal, l'installeur répond oui à tout, désinstallation comprise.

L'exécution à blanc a été la première surprise. J'ai compté ses lignes à la main et obtenu 23, ce qui était faux : `scripts/dry-run-vs-install.mjs` fait désormais le compte, et dit 21 contre 32. La cause est dans le code plutôt que dans une mise à jour oubliée : l'aperçu est un second chemin dans l'installeur, et le vrai chemin a gagné des ressources en 4.1.0 et des skills en 4.2.0 sans lui. J'ai d'abord écrit que les neuf skills n'étaient *pas installés* ; ils le sont, simplement pas annoncés — la seconde liste du script, *in the dry-run but not written*, est vide.

La leçon 2 appelle les fonctions exportées de l'installeur au lieu de les décrire, ce qui est possible parce que charger `install.js` ne l'exécute pas. Deux mesures viennent de cette leçon : quels fichiers diffèrent entre une installation globale et une installation de projet (neuf : huit nomment un chemin, plus `meta.json`), et les nombres de lignes qui montrent que les quatre commandes sont des répartiteurs vers des guides plus longs.

La vérification du modèle cassé copie le paquet, supprime une ligne `description:`, et lance la copie dans son propre répertoire personnel : code de sortie 1, et aucun fichier écrit.

## À vérifier

- Si le modèle trouve `.claude/setup/slashforge/…` quand Claude Code est démarré dans un sous-dossier d'un dépôt avec une installation de projet (leçon 2).
- Le coût en tokens de chaque commande, qu'estime le README, sur un dépôt public (leçons 3 à 5).
- Si un skill écrit comme un fichier dans `commands/` est jamais choisi par le modèle de lui-même, ou seulement quand un guide le nomme.

## Questions ouvertes

- L'amont accepterait-il une exécution à blanc construite à partir d'`installFiles` lui-même, comme le `-WhatIf` de PowerShell passe par le même `ShouldProcess` que l'action ? Pas proposé : rien ne sort de ce dépôt sans l'accord de l'auteur.
