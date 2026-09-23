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
- [x] Leçons 1 et 2 relancées depuis un export neuf du code du cours : 19 sorties sur 19 identiques
- [x] Un labo jetable pour les leçons 3 à 5 : `code/slashforge/lab/prepare.sh` et `lab/run.sh`, avec un plafond sur chaque exécution
- [ ] Leçon 3 : `/slashforge:setup` face à `/init` — **bloquée, non testée** : le Claude Code du labo n'est pas connecté
- [ ] Leçon 4 : `/slashforge:code`, dix phases et quatre points de contrôle — **bloquée, non testée**, même raison
- [ ] Leçon 5 : `-quick`, `/slashforge:investigate` et `/slashforge:review-pr` — **bloquée, non testée**, même raison
- [ ] Leçon 6 : se l'approprier

## QA

Chaque ligne ci-dessous est reproduite par `check.sh` ou lue dans l'installeur au tag `v4.4.3`. Aucune n'a été signalée en amont : le dépôt n'avait aucune issue ouverte ou fermée le 2026-09-22, et ses tests ne couvrent pas l'exécution à blanc.

| Attendu | Ce qui se passe | Où | Mesure | État |
|---|---|---|---|---|
| `--dry-run` liste ce qu'écrit l'installation | Il liste 21 fichiers ; l'installation en écrit 32. Les neuf skills, `forge-open.sh` et `forge-report-shell.html` manquent | [`bin/install.js#L499-L528`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L499-L528) construit sa propre liste à partir de deux des quatre tableaux | `l01_dry_run_vs_install` : 11 écrits, non annoncés ; 0 annoncé, non écrit | Reproduit, non signalé [2026-09-22](#2026-09-22--linstalleur-lu-et-exécuté) |
| L'exécution à blanc indique pour chaque fichier ce que l'installation en fait | Elle dit `copy` pour chaque guide. Les guides sont rendus depuis la 4.4.1 | mêmes lignes | `l02_global_vs_project` : deux guides diffèrent entre l'installation globale et l'installation de projet, ce qu'une copie ne pourrait pas faire | Reproduit, non signalé [2026-09-22](#2026-09-22--linstalleur-lu-et-exécuté) |
| Le *What gets installed* du README décrit la 4.4.3 | Il décrit trois commandes dans `commands/forge/` ; la 4.4.3 écrit quatre commandes et neuf skills dans `commands/slashforge/` | [`README.md#L103-L112`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/README.md#L103-L112) | `l01_files` | Reproduit, non signalé [2026-09-22](#2026-09-22--linstalleur-lu-et-exécuté) |
| Les commentaires de l'installeur décrivent son code | Trois sont plus anciens que lui : *"the three entry points"* au-dessus d'une liste de quatre ; `'forge/setup.md' -> '/slashforge:setup'` au-dessus de `commandName` ; *"a namespace subdirectory (forge/)"* là où il écrit `slashforge/` | [`#L45-L50`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L45-L50), [`#L182-L183`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L182-L183), [`#L259-L260`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L259-L260) | `l02_installer_functions` : `commandName('slashforge/setup.md')` donne `/slashforge:setup` | Lu ; commentaires seulement, aucun comportement affecté |
| `--yes`, que l'aide associe à *"the update prompt"* (la question de mise à jour), ne répond pas aux autres questions | Quand l'entrée standard n'est pas un terminal, il est actif, et `uninstall` supprime tout sans demander | [`#L628-L633`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L628-L633) | `l01_uninstall` : 15 suppressions, code de sortie 0, aucune question | Reproduit ; documenté en partie |
| Un modèle que Claude Code accepte, l'installeur l'accepte | L'installeur lit le frontmatter ligne par ligne : une `description: >` YAML repliée est refusée, et un `---` de fermeture suivi d'une espace n'est pas trouvé, alors que le délimiteur d'ouverture est nettoyé | [`#L113-L137`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L113-L137) | `l02_installer_functions` : 6 refus sur 7 échantillons | Reproduit ; ne concerne que les modèles que tu ajoutes |
| Le champ `name` qu'exige l'installeur nomme la commande | Claude Code ignore `name` dans un fichier sous `commands/` ; c'est le chemin qui nomme la commande | [Claude Code, skills](https://code.claude.com/docs/en/skills#where-skills-live) | — | Documenté des deux côtés ; un piège au renommage (leçon 2, exercice 1) |

## Expériences

Les leçons 3 à 5 font exécuter les commandes par le modèle, donc chaque exécution a une hypothèse écrite avant elle et un plafond (`lab/run.sh` n'a pas de budget par défaut). Seule la première a tourné. Elle s'est arrêtée avant l'appel au modèle, et les autres lignes sont des hypothèses qui attendent une connexion, pas des résultats.

| Question | Hypothèse (écrite avant l'exécution) | Résultat | Verdict | Entrée, code |
|---|---|---|---|---|
| e0 — Le labo peut-il lancer une commande sans toucher au vrai `~/.claude` ? | Un Claude Code dont le répertoire de configuration est vide n'est pas connecté, et s'arrête avant tout appel au modèle, sans rien dépenser | `Not logged in · Please run /login`, code de sortie 1, 1 tour, 114 ms, 0 token en entrée et en sortie, 0 USD, 0 fichier modifié. Plafond : 0.25 USD, 3 tours | Confirmée : le labo est isolé, et il ne peut pas aller plus loin sans connexion | [2026-09-22](#2026-09-22--le-labo-des-leçons-3-à-5-et-où-il-sarrête), `lab/run.sh` |
| L3 — Qu'écrit `/slashforge:setup` sur un dépôt sans `.claude/`, comparé à `/init` ? | Il écrit `CLAUDE.md` et `.claude/rules/`, et s'arrête à la proposition Graphify (un oui/non) avant de provisionner quoi que ce soit | Non mesuré | Bloquée : pas de connexion | idem |
| L4 — Jusqu'où va `/slashforge:code -quick` sans interface sur un petit changement ? | Il s'arrête au point de contrôle de la phase 3 (confirmer le plan) sans modifier le dépôt, sous 70,000 tokens, le haut de la fourchette du README pour `-quick` | Non mesuré | Bloquée : pas de connexion | idem |
| L5a — `/slashforge:investigate` reste-t-il en lecture seule ? | Il ne modifie aucun fichier suivi et écrit un rapport HTML sous `docs/slashforge/` | Non mesuré | Bloquée : pas de connexion | idem |
| L5b — Que fait `/slashforge:review-pr` sans connexion GitHub ? | Il s'arrête à sa vérification préalable de l'étape 0 et demande `gh auth login`, comme le dit son fichier, sans lancer d'autre commande | Non mesuré | Bloquée : pas de connexion | idem |

## 2026-09-22 — L'installeur, lu et exécuté

SlashForge 4.4.3 (tag `v4.4.3`, commit `bd75a4f`), Node.js 24.12.0 en local et 24.21.0 en CI, Windows 11. L'installeur sur `main` était le même fichier ce jour-là.

Le cours ne laisse pas l'installeur approcher le vrai `~/.claude`. `check.sh` fait pointer `HOME`, et `USERPROFILE` sous Windows, vers `out/home`, pose `SLASHFORGE_NO_UPDATE_CHECK=1` pour que la vérification de version n'atteigne pas npm, et lance chaque commande avec l'entrée standard depuis `/dev/null`, comme la CI. Ce dernier choix révèle un comportement à part entière : sans terminal, l'installeur répond oui à tout, désinstallation comprise.

L'exécution à blanc a été la première surprise. J'ai compté ses lignes à la main et obtenu 23, ce qui était faux : `scripts/dry-run-vs-install.mjs` fait désormais le compte, et dit 21 contre 32. La cause est dans le code plutôt que dans une mise à jour oubliée : l'aperçu est un second chemin dans l'installeur, et le vrai chemin a gagné des ressources en 4.1.0 et des skills en 4.2.0 sans lui. J'ai d'abord écrit que les neuf skills n'étaient *pas installés* ; ils le sont, simplement pas annoncés — la seconde liste du script, *in the dry-run but not written*, est vide.

La leçon 2 appelle les fonctions exportées de l'installeur au lieu de les décrire, ce qui est possible parce que charger `install.js` ne l'exécute pas. Deux mesures viennent de cette leçon : quels fichiers diffèrent entre une installation globale et une installation de projet (neuf : huit nomment un chemin, plus `meta.json`), et les nombres de lignes qui montrent que les quatre commandes sont des répartiteurs vers des guides plus longs.

La vérification du modèle cassé copie le paquet, supprime une ligne `description:`, et lance la copie dans son propre répertoire personnel : code de sortie 1, et aucun fichier écrit.

## 2026-09-22 — Le labo des leçons 3 à 5, et où il s'arrête

Versions : Claude Code 2.1.280, Node.js 24.12.0 en local, SlashForge 4.4.3, Windows 11 avec Git Bash.

**Leçons 1 et 2, relancées.** J'ai exporté `code/slashforge` depuis le commit publié (`cfa14ef`) dans un nouveau dossier, lancé `npm ci` et `bash check.sh` : 19 sorties sur 19 identiques, en 135 s installation comprise. La CI est passée sous Linux, Windows et macOS pour le même commit. Ensuite, le vrai `~/.claude` ne contenait ni dossier `commands/` ni dossier `setup/` : rien de SlashForge.

**Le labo.** `lab/prepare.sh <dir>` crée un répertoire personnel, un répertoire de configuration Claude Code (`CLAUDE_CONFIG_DIR`), un répertoire pour la CLI GitHub (`GH_CONFIG_DIR`) et une configuration git, le tout dans `<dir>`. Il clone SlashForge lui-même au tag `v4.4.3` (public, MIT, sans dépendances) sur une branche `lab`, retire le remote, et ajoute un hook pre-push qui refuse. Puis il installe le kit globalement dans le répertoire personnel du labo. J'ai vérifié ce garde-fou avec un push vers un dépôt bare local : `lab: push refused`, code de sortie 1.

`lab/run.sh <dir> <name> <max-usd> <max-turns> <prompt>` lance `claude -p` dans le dépôt du labo avec `--max-budget-usd`, `--max-turns` et un délai de 900 s. Il accepte les modifications, n'autorise que le git en lecture seule, `ls` et les tests, et refuse `git push`, `gh`, `curl`, le web et les serveurs MCP. Il enregistre le code de sortie, la durée réelle, les tours, les tokens, le coût que calcule Claude Code, les refus de permission, et le nombre de chemins modifiés. Une exécution sans interface s'arrête à la première question que pose le workflow, donc un point de contrôle de SlashForge termine l'exécution. Il n'y est jamais répondu.

**La plus petite expérience, e0** : `/slashforge:investigate` sur la trouvaille de l'exécution à blanc de la leçon 1, avec un plafond de 0.25 USD et 3 tours. Claude Code a répondu `Not logged in · Please run /login` en 114 ms, avec 0 token et 0 USD, et le dépôt du labo n'a pas changé. Son résultat JSON indique `"subtype": "success"` avec `"is_error": true` et `"terminal_reason": "api_error"`, donc un script doit lire `is_error` et non `subtype`.

**Où il s'arrête.** Connecter le labo demande une personne. La connexion passe par le navigateur, pour le compte de l'auteur, et copier les vrais identifiants dans le labo reviendrait à lire `~/.claude`, ce que ce labo existe précisément pour ne pas faire. Les leçons 3 à 5 s'arrêtent donc ici, à l'étape zéro. Les points de contrôle qu'auraient atteints les commandes sont listés ci-dessous, d'après leurs fichiers, pas d'après une exécution :

| Commande | Où elle attend une personne |
|---|---|
| `/slashforge:setup` | la proposition Graphify (oui/non), les questions de clarification, et avant d'écraser un fichier qu'elle a généré dans une version plus ancienne |
| `/slashforge:code` et `-quick` | phase 3 confirmer le plan, phase 4 choix de la branche, phase 8 push et PR, phase 10 nettoyage ; `-quick` garde les quatre |
| `/slashforge:investigate` | seulement quand elle est appelée sans symptôme |
| `/slashforge:review-pr` | étape 0 (`gh` doit être connecté, sinon elle s'arrête), R1 le choix de la PR, R5 avant de publier quoi que ce soit |

Deux d'entre eux demandent une autorité que ce labo n'a pas et ne doit pas recevoir : la phase 8 pousse et ouvre une pull request, et `review-pr` publie sur GitHub.

**Les propres tests de SlashForge, dans le labo.** `node --test` sur le clone a terminé avec le code 0 mais a pris 523 s. Je n'ai pas relevé le nombre de tests réussis, parce que mon filtre attendait des lignes TAP et que le reporter par défaut affiche autre chose. J'ai soupçonné le test de `forge-open.sh`, qui lance `start` sous Git Bash. Lancé seul, il passe en 20 s, et j'en ai d'abord conclu qu'il n'était pas en cause. C'était faux : ici, un test vert ne prouve rien. [`test/install.test.js:527`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/test/install.test.js#L527) appelle le helper avec `/tmp/definitely-does-not-exist-slashforge.html`, et sous Windows [`forge-open.sh`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-open.sh#L37-L40) lance `start`, avale l'erreur et renvoie 0. Le test est donc vert quoi que fasse `start` : c'est un faux positif. Une capture d'écran de l'auteur montre qu'il affiche une boîte de dialogue d'erreur Windows sur le bureau. Les 20 s n'excluent pas non plus le helper comme cause des 523 s. Je n'ai pas relancé le test, puisqu'il ouvre une fenêtre. La cause des 523 s reste à vérifier.

## À vérifier

- Pourquoi le `node --test` de SlashForge prend 523 s sous Windows avec Git Bash, y compris la part du test de `forge-open.sh`. Ne pas relancer ce test dans une session de bureau : il ouvre une boîte de dialogue d'erreur (voir l'entrée du labo).
- Si `--max-budget-usd` arrête une exécution sous une connexion par abonnement, comme il le fait avec une clé d'API (leçon 3 et suivantes).
- Si le modèle trouve `.claude/setup/slashforge/…` quand Claude Code est démarré dans un sous-dossier d'un dépôt avec une installation de projet (leçon 2).
- Le coût en tokens de chaque commande, qu'estime le README, sur un dépôt public (leçons 3 à 5).
- Si un skill écrit comme un fichier dans `commands/` est jamais choisi par le modèle de lui-même, ou seulement quand un guide le nomme.

## Questions ouvertes

- Comment connecter le labo : `claude auth login` avec `CLAUDE_CONFIG_DIR` pointant sur le labo, ou un token de `claude setup-token` dans `CLAUDE_CODE_OAUTH_TOKEN`. Dans les deux cas c'est la décision de l'auteur, tout comme le budget de L3 à L5.
- L'amont accepterait-il une exécution à blanc construite à partir d'`installFiles` lui-même, comme le `-WhatIf` de PowerShell passe par le même `ShouldProcess` que l'action ? Pas proposé : rien ne sort de ce dépôt sans l'accord de l'auteur.
