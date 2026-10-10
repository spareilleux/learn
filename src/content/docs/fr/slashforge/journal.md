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
- [x] Leçons 3 à 5 testées dans le labo, sans interface, chacune jusqu'à son premier point de contrôle : six exécutions, 1.83 USD en tout (voir Expériences)
- [x] Page de la leçon 3 : `/slashforge:setup` face à `/init`
- [x] Page de la leçon 4 : `/slashforge:code`, dix phases et quatre points de contrôle, avec `-quick`
- [x] Page de la leçon 5 : `/slashforge:investigate` et `/slashforge:review-pr`
- [x] Leçon 6 : se l'approprier — règles, vérification, installation d'équipe ; `check.sh` compare désormais 20 sorties
- [x] Leçon 7 : contribuer en amont, et un retest de 4.5.0 sous Windows
- [x] SlashForge 5.2.1 revérifié sous Windows : installeur, contrôle de taille de setup et tests du kit ; trois issues ouvertes en amont

## QA

Chaque ligne ci-dessous est reproduite par `check.sh` ou lue dans l'installeur au tag `v4.4.3`. Aucune n'a été signalée en amont : le dépôt n'avait aucune issue ouverte ou fermée le 2026-09-22, et ses tests ne couvrent pas l'exécution à blanc. Le 2026-09-26, l'auteur a reconnu ces constats et annoncé des correctifs ([entrée](#2026-09-26--la-réponse-de-lauteur-et-comment-vérifier-une-release)), et la release 4.5.0 corrige les huit lignes sur l'installeur et les guides, retestées sous Windows ([retest](#2026-09-26--retest-sur-slashforge-450)). Le 2026-10-09, la release 5.2.1 a été revérifiée ; les trois dernières lignes en viennent et ont été signalées en amont ([entrée](#2026-10-09--slashforge-521-revérifié)).

| Attendu | Ce qui se passe | Où | Mesure | État |
|---|---|---|---|---|
| `--dry-run` liste ce qu'écrit l'installation | Il liste 21 fichiers ; l'installation en écrit 32. Les neuf skills, `forge-open.sh` et `forge-report-shell.html` manquent | [`bin/install.js#L499-L528`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L499-L528) construit sa propre liste à partir de deux des quatre tableaux | `l01_dry_run_vs_install` : 11 écrits, non annoncés ; 0 annoncé, non écrit | Reproduit, non signalé [2026-09-22](#2026-09-22--linstalleur-lu-et-exécuté) · Corrigé dans v4.5.0, retesté sous Windows ([2026-09-26](#2026-09-26--retest-sur-slashforge-450)) |
| L'exécution à blanc indique pour chaque fichier ce que l'installation en fait | Elle dit `copy` pour chaque guide. Les guides sont rendus depuis la 4.4.1 | mêmes lignes | `l02_global_vs_project` : deux guides diffèrent entre l'installation globale et l'installation de projet, ce qu'une copie ne pourrait pas faire | Reproduit, non signalé [2026-09-22](#2026-09-22--linstalleur-lu-et-exécuté) · Corrigé dans v4.5.0, retesté sous Windows ([2026-09-26](#2026-09-26--retest-sur-slashforge-450)) |
| Le *What gets installed* du README décrit la 4.4.3 | Il décrit trois commandes dans `commands/forge/` ; la 4.4.3 écrit quatre commandes et neuf skills dans `commands/slashforge/` | [`README.md#L103-L112`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/README.md#L103-L112) | `l01_files` | Reproduit, non signalé [2026-09-22](#2026-09-22--linstalleur-lu-et-exécuté) · Corrigé dans v4.5.0, retesté sous Windows ([2026-09-26](#2026-09-26--retest-sur-slashforge-450)) |
| Les commentaires de l'installeur décrivent son code | Trois sont plus anciens que lui : *"the three entry points"* au-dessus d'une liste de quatre ; `'forge/setup.md' -> '/slashforge:setup'` au-dessus de `commandName` ; *"a namespace subdirectory (forge/)"* là où il écrit `slashforge/` | [`#L45-L50`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L45-L50), [`#L182-L183`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L182-L183), [`#L259-L260`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L259-L260) | `l02_installer_functions` : `commandName('slashforge/setup.md')` donne `/slashforge:setup` | Lu ; commentaires seulement, aucun comportement affecté · Corrigé dans v4.5.0, retesté sous Windows ([2026-09-26](#2026-09-26--retest-sur-slashforge-450)) |
| `--yes`, que l'aide associe à *"the update prompt"* (la question de mise à jour), ne répond pas aux autres questions | Quand l'entrée standard n'est pas un terminal, il est actif, et `uninstall` supprime tout sans demander | [`#L628-L633`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L628-L633) | `l01_uninstall` : 15 suppressions, code de sortie 0, aucune question | Reproduit ; documenté en partie · Corrigé dans v4.5.0, retesté sous Windows ([2026-09-26](#2026-09-26--retest-sur-slashforge-450)) |
| Un modèle que Claude Code accepte, l'installeur l'accepte | L'installeur lit le frontmatter ligne par ligne : une `description: >` YAML repliée est refusée, et un `---` de fermeture suivi d'une espace n'est pas trouvé, alors que le délimiteur d'ouverture est nettoyé | [`#L113-L137`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L113-L137) | `l02_installer_functions` : 6 refus sur 7 échantillons | Reproduit ; ne concerne que les modèles que tu ajoutes · Corrigé dans v4.5.0, retesté sous Windows ([2026-09-26](#2026-09-26--retest-sur-slashforge-450)) |
| Le champ `name` qu'exige l'installeur nomme la commande | Claude Code ignore `name` dans un fichier sous `commands/` ; c'est le chemin qui nomme la commande | [Claude Code, skills](https://code.claude.com/docs/en/skills#where-skills-live) | — | Documenté des deux côtés ; un piège au renommage (leçon 2, exercice 1) |
| Les guides du kit s'accordent sur l'emplacement d'un skill et sur sa longueur maximale | `forge-instructions.md` dit `.claude/skills/*.md` et *"Every `.md` file … under 200 lines"* ; `forge-skills.md` dit un dossier avec `SKILL.md`, sous 500 lignes. La documentation de Claude Code ne liste que la forme en dossier | [`forge-instructions.md#L14-L34`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-instructions.md#L14-L34), [`forge-skills.md#L27-L51`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-skills.md#L27-L51) | Deux contradictions dans des guides que le modèle lit au cours d'une même exécution | Lu, non signalé [2026-09-22](#2026-09-22--leçon-6--deux-règlements-et-quelle-copie-sexécute) · Corrigé dans v4.5.0, retesté sous Windows ([2026-09-26](#2026-09-26--retest-sur-slashforge-450)) |
| L'étape de vérification de setup repère un fichier de plus de 200 lignes | `wc -l CLAUDE.md .claude/**/*.md` en bash sans `globstar` s'arrête à un dossier de profondeur, donc le `SKILL.md` d'un skill n'est jamais compté | [`forge-instructions.md` Step 9](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-instructions.md#L126-L139) | `l06_verify_glob` : un `SKILL.md` de 300 lignes absent du compte, sous Linux, Windows et macOS | Reproduit, non signalé [2026-09-22](#2026-09-22--leçon-6--deux-règlements-et-quelle-copie-sexécute) · Corrigé dans v4.5.0, retesté sous Windows ([2026-09-26](#2026-09-26--retest-sur-slashforge-450)) |
| Le correctif 4.5.0 du test de l'assistant d'ouverture retire l'assertion qui lance le vrai ouvreur | Le test simulé a été ajouté à côté de l'ancien, qui lance toujours l'assistant sur un fichier absent sans `SSH_CONNECTION` : `start` sous Windows, `xdg-open` sur un bureau Linux, `open` sous macOS | [`test/install.test.js#L570`](https://github.com/rajdeepratan/SlashForge/blob/7e0e26a78bdfe7e9375a27a17b441d44280325ac/test/install.test.js#L570), ligne 526 à [`v4.5.0`](https://github.com/rajdeepratan/SlashForge/blob/10d3d916b30323598515aa27aef43a8527e7e967/test/install.test.js#L526) | Lu à `v4.5.0` et `v5.2.1`, pas exécuté, parce qu'il ouvre une boîte de dialogue. Invalide la phrase du retest du 2026-09-26, « Windows n'a donc plus de boîte de dialogue » | Lu ; signalé comme [#104](https://github.com/rajdeepratan/SlashForge/issues/104) [2026-10-09](#2026-10-09--slashforge-521-revérifié) |
| Là où l'hôte la respecte, les commandes du kit portent `disable-model-invocation: true` | Depuis 5.0.0, les huit commandes la portent sous Cursor et Codex. Aucun des 17 fichiers de `~/.claude/commands/` ne la porte, alors que le propre guide du kit la dit *« critical for commands with side effects »* et que Claude Code laisse par défaut le modèle invoquer une commande | [`bin/install.js#L618`](https://github.com/rajdeepratan/SlashForge/blob/7e0e26a78bdfe7e9375a27a17b441d44280325ac/bin/install.js#L618), [`templates/slashforge-commands.md#L127`](https://github.com/rajdeepratan/SlashForge/blob/7e0e26a78bdfe7e9375a27a17b441d44280325ac/templates/slashforge-commands.md#L127), [Claude Code, skills](https://code.claude.com/docs/en/skills) | Frontmatter d'une installation globale 5.2.1 dans un répertoire personnel jetable : 0 sur 17. Pas exécuté avec un modèle | Lu et installé ; signalé comme [#105](https://github.com/rajdeepratan/SlashForge/issues/105) [2026-10-09](#2026-10-09--slashforge-521-revérifié) |
| Le message de fin d'installation liste les commandes | Il liste six commandes et `-quick`. `/slashforge-test` et `/slashforge-refactor`, ajoutées en 5.2.0, manquent, alors que `status` en liste huit | [`bin/install.js#L1199-L1209`](https://github.com/rajdeepratan/SlashForge/blob/7e0e26a78bdfe7e9375a27a17b441d44280325ac/bin/install.js#L1199-L1209) | Sortie de l'installation, globale et `--project` | Reproduit ; signalé comme [#106](https://github.com/rajdeepratan/SlashForge/issues/106) [2026-10-09](#2026-10-09--slashforge-521-revérifié) |

## Expériences

Les leçons 3 à 5 font exécuter les commandes par le modèle, donc chaque exécution a une hypothèse écrite avant elle et un plafond (`lab/run.sh` n'a pas de budget par défaut). Les hypothèses de L3 à L5 ont été écrites quand le labo n'était pas encore connecté ; les exécutions sont venues après que l'auteur a connecté le labo. Chaque exécution est sans interface et se termine à la première question que pose le workflow. Les coûts sont ceux que calcule Claude Code pour le modèle qu'il a utilisé, `claude-opus-5-5[1m]`, celui du compte par défaut : ils seraient plus bas avec un modèle plus petit. Ce sont des exécutions uniques, pas des moyennes.

| Question | Hypothèse (écrite avant l'exécution) | Résultat | Verdict | Entrée, code |
|---|---|---|---|---|
| e0 — Le labo peut-il lancer une commande sans toucher au vrai `~/.claude` ? | Un Claude Code dont le répertoire de configuration est vide n'est pas connecté, et s'arrête avant tout appel au modèle, sans rien dépenser | `Not logged in · Please run /login`, code de sortie 1, 1 tour, 114 ms, 0 token en entrée et en sortie, 0 USD, 0 fichier modifié. Plafond : 0.25 USD, 3 tours | Confirmée : le labo est isolé, et il ne peut pas aller plus loin sans connexion | [2026-09-22](#2026-09-22--le-labo-des-leçons-3-à-5-et-où-il-sarrête), `lab/run.sh` |
| L3 — Qu'écrit `/slashforge:setup` sur un dépôt sans `.claude/`, comparé à `/init` ? | Il écrit `CLAUDE.md` et `.claude/rules/`, et s'arrête à la proposition Graphify (un oui/non) avant de provisionner quoi que ce soit | e2 : rien d'écrit. Graphify sauté sans demander (sous son seuil de 70%) ; arrêt sur six questions de clarification. 6 tours, 56 s, 0.27 USD. e2b, `/init` sur le même clone : un `CLAUDE.md` de 50 lignes écrit d'emblée, sans question, 9 tours, 92 s, 0.32 USD | Réfutée : setup demande avant d'écrire, et le point de contrôle Graphify ne s'est jamais déclenché | [2026-09-22](#2026-09-22--les-leçons-3-à-5-exécutées-dans-le-labo), `lab/run.sh` |
| L4 — Jusqu'où va `/slashforge:code -quick` sans interface sur un petit changement ? | Il s'arrête au point de contrôle de la phase 3 (confirmer le plan) sans modifier le dépôt, sous 70,000 tokens, le haut de la fourchette du README pour `-quick` | e3 : un plan sobre (un `plannedWrites` exporté, un test qui le compare à `installFiles`), puis un arrêt, aucun fichier modifié. Il a posé les questions des phases 3 et 4 (branche) dans un seul message. 6 tours, 57 s, 0.25 USD ; 1,720 tokens en entrée et en sortie, 23,433 écrits dans le cache, 158,847 lus depuis le cache | Confirmée pour le point de contrôle et pour « aucune modification » ; la partie tokens dépend de ce qu'on compte : les lectures du cache seules dépassent 70,000 | [2026-09-22](#2026-09-22--les-leçons-3-à-5-exécutées-dans-le-labo) |
| L5a — `/slashforge:investigate` reste-t-il en lecture seule ? | Il ne modifie aucun fichier suivi et écrit un rapport HTML sous `docs/slashforge/` | e1 et e1b : aucun fichier modifié dans le dépôt, la bonne cause racine, et pas de rapport, parce que le construire demande du code `node` que le labo refuse. Dans e1, où le labo pré-approuvait `Write`, le modèle a écrit son générateur de rapport dans `%TEMP%` à la place. e1 : 15 tours, 0.45 USD ; e1b : arrêté par la limite de tours à 11, 0.38 USD | Confirmée pour le dépôt ; la moitié rapport n'est pas testée ; et un `Write` pré-approuvé n'est pas confiné au dépôt | [2026-09-22](#2026-09-22--les-leçons-3-à-5-exécutées-dans-le-labo) |
| L5b — Que fait `/slashforge:review-pr` sans connexion GitHub ? | Il s'arrête à sa vérification préalable de l'étape 0 et demande `gh auth login`, comme le dit son fichier, sans lancer d'autre commande | e4 : `gh auth status` a échoué, la commande s'est arrêtée et a dit à l'utilisateur de lancer `gh auth login` ; rien de lu ni d'écrit sur GitHub. 4 tours, 35 s, 0.17 USD | Confirmée | [2026-09-22](#2026-09-22--les-leçons-3-à-5-exécutées-dans-le-labo) |
| e5 — Quand une commande existe à la fois dans `~/.claude` et dans le projet, laquelle s'exécute ? | La personnelle, comme le dit la documentation de Claude Code (*"personal over project"*) | e5b : `GLOBAL`, 1 tour, 0.09 USD. e5, avec un plafond de 0.10 USD, s'est arrêtée avec `error_max_budget_usd` à 0.103 USD avant que sa réponse ne soit renvoyée | Confirmée ; et le plafond fonctionne sous une connexion par abonnement, vérifié après chaque appel | [2026-09-22](#2026-09-22--leçon-6--deux-règlements-et-quelle-copie-sexécute) |

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

## 2026-09-22 — Les leçons 3 à 5, exécutées dans le labo

L'auteur a connecté le répertoire de configuration propre au labo avec `claude auth login` (abonnement, pas de facturation à l'API), dans son propre terminal : la page de connexion donne un code à coller, ce qu'une tâche en arrière-plan ne peut pas faire. `claude auth status` dans le labo a ensuite répondu `"loggedIn": true, "authMethod": "claude.ai"`, et le vrai `~/.claude` n'a pas été concerné.

Versions : Claude Code 2.1.280, modèle `claude-opus-5-5[1m]` (celui par défaut ; aucun `--model` n'a été passé), SlashForge 4.4.3 sur son propre dépôt au tag `v4.4.3`. Six exécutions, chacune avec son plafond, une à la fois :

| Exécution | Prompt | Plafond | Tours | Durée | Coût | Arrêtée à |
|---|---|---|---|---|---|---|
| e1 | `/slashforge:investigate` sur la trouvaille de l'exécution à blanc | 0.50 USD, 10 tours | 15 | 76 s | 0.45 USD | l'étape du rapport, refusée (voir plus bas) |
| e2 | `/slashforge:setup` | 0.75 USD, 20 tours | 6 | 56 s | 0.27 USD | six questions de clarification |
| e2b | `/init` | 0.50 USD, 20 tours | 9 | 92 s | 0.32 USD | terminé : `CLAUDE.md` écrit |
| e3 | `/slashforge:code -quick` + la correction de l'exécution à blanc | 0.75 USD, 20 tours | 6 | 57 s | 0.25 USD | phases 3 et 4 ensemble |
| e4 | `/slashforge:review-pr` | 0.25 USD, 5 tours | 4 | 35 s | 0.17 USD | étape 0 : `gh` non connecté |
| e1b | e1 à nouveau, avec le labo corrigé | 0.50 USD, 10 tours | 11 | 58 s | 0.38 USD | la limite de tours |

Total : 1.83 USD. Aucune exécution n'a atteint son plafond en dollars. Après e2b, le dépôt du labo a été restauré (son `CLAUDE.md` est conservé avec les fichiers de l'exécution) ; toutes les autres exécutions l'ont laissé inchangé.

**Ce qu'a trouvé l'investigation.** Les deux exécutions ont donné la cause racine que donne la leçon 1 : l'exécution à blanc construit sa propre liste à partir de `GUIDE_FILES` et `COMMAND_FILES`, et `installFiles` écrit aussi `ASSET_FILES` et `SKILL_FILES`, 21 + 2 + 9 = 32. e1 a ajouté deux choses que le cours n'avait pas écrites : que les guides sont étiquetés `copy` bien que rendus (la leçon 1 le dit), et que l'exécution à blanc ne mentionne pas les `REMOVED_GUIDE_FILES` périmés qu'elle supprime. Il a proposé la correction que suggère la leçon 1, une seule fonction de planification partagée par les deux chemins, avec un test qui les compare.

**Une écriture sortie du dépôt.** Dans e1, `lab/run.sh` listait `Edit` et `Write` parmi les outils autorisés. Cela les pré-approuve partout, pas seulement dans le répertoire de travail, et le modèle s'en est servi : `node` lui étant refusé pour le rapport, il a écrit un script de 4,175 octets dans `%TEMP%\sf-splice.js` et a dit à l'utilisateur de le lancer. Le fichier est conservé avec l'exécution, et le labo est corrigé. `Edit` et `Write` ne sont plus listés, donc `acceptEdits` n'accepte les modifications qu'à l'intérieur du dépôt, et `run.sh` liste tout fichier qui apparaît dans le dossier temporaire pendant une exécution. e1b et e2 à e4 n'ont rien écrit à l'extérieur ; le seul fichier listé après e2b était une image écrite par un autre programme.

**`/init` face à `/slashforge:setup`.** `/init` a écrit un `CLAUDE.md` de 50 lignes d'emblée, et a trouvé de lui-même l'écart du README que liste le tableau QA de ce cours ("Known drift: the README's *What gets installed* table still shows `commands/forge/`"). Setup a lu davantage et n'a rien écrit : il a proposé quatre agents, posé des questions sur les hooks, les commandes, les règles de release et l'organisation, et dit qu'il écrirait `CLAUDE.md` en dernier. La proposition Graphify, que l'hypothèse attendait comme premier point de contrôle, n'est pas apparue : l'essentiel du dépôt est du Markdown et du `.astro`, sous le seuil de langage de 70% de Graphify, et setup le saute alors en silence, comme le dit son fichier.

**Les points de contrôle.** Chaque commande s'est arrêtée là où son fichier dit qu'une personne décide, et aucune n'en a franchi un. Un écart : `/slashforge:code -quick` a demandé le plan (phase 3) et la branche (phase 4) dans le même message, alors que `code.md` dit *"Do not combine phases"*.

**Limites.** Une exécution par commande, un dépôt, un modèle. Les coûts sont calculés par Claude Code pour la session d'abonnement, ce ne sont pas des montants facturés. La comparaison des tokens de `-quick` avec le README est approximative, parce que le README ne dit pas si sa fourchette compte l'entrée en cache. La limite de tours s'est comportée différemment dans deux exécutions : e1 a indiqué 15 tours avec `--max-turns 10` et s'est terminée normalement, et e1b s'est arrêtée à 11 avec `error_max_turns`. La cause reste à vérifier.

## 2026-09-22 — Leçon 6 : deux règlements, et quelle copie s'exécute

L'essentiel de la leçon 6 est de la lecture, et deux constats en sont sortis. Les deux guides que le modèle lit pendant setup ne sont pas d'accord : `forge-instructions.md` range les skills sous `.claude/skills/*.md` avec une règle d'or de 200 lignes, et `forge-skills.md` demande un dossier avec un `SKILL.md` sous 500 lignes. Et l'étape de vérification à la fin de setup, `wc -l CLAUDE.md .claude/**/*.md`, ne regarde pas dans les dossiers de skills dans le mode par défaut de bash. `check.sh` construit désormais un petit dépôt avec un `SKILL.md` de 300 lignes et compare les deux listes de fichiers (`l06_verify_glob`), pour que la CI le montre sur les trois systèmes ; en zsh, où `**` est récursif par défaut, la même ligne verrait le fichier.

Une exécution du modèle, pour trancher ce que veut dire une installation d'équipe. L'hypothèse, écrite à partir de la documentation de Claude Code avant l'exécution : avec `/lab:which` à la fois dans le `commands/` personnel du labo et dans le `.claude/commands/` du dépôt, c'est la personnelle qui s'exécute. e5, avec un plafond de 0.10 USD, a été arrêtée avec `error_max_budget_usd` à 0.103 USD : le plafond fonctionne sous une connexion par abonnement, et il est vérifié après l'appel, pas avant. e5b, avec 0.30 USD, a répondu `GLOBAL` pour 0.09 USD. Les deux fichiers de sonde sont conservés avec l'exécution, et le labo a été restauré. Un coéquipier avec une installation globale exécute donc sa propre version de `/slashforge:code`, pas celle que l'équipe a commitée.

Limite : le comportement de setup à une nouvelle exécution — rafraîchir, demander ou laisser tel quel selon le marqueur `generated_by` — est décrit d'après le guide, pas testé ; le tester suppose de mener setup au-delà de ses questions deux fois.

## 2026-09-26 — La réponse de l'auteur, et comment vérifier une release

Une réponse attribuée à l'auteur de SlashForge, [Rajdeep Singh Ratan](https://www.linkedin.com/in/rajdeepratan/), a été publiée sur LinkedIn et collée dans les notes de travail de ce cours le 2026-09-26. Le lien permanent et la date de publication du message n'ont pas été vérifiés ; le lien ci-dessus mène au profil de l'auteur, pas au message. En bref, l'auteur a parcouru les constats de ce journal, s'est dit d'accord, et a annoncé qu'ils nourriront les prochaines releases, notamment un manifeste partagé par l'exécution à blanc et l'installation, et des guides et des vérifications cohérents entre eux.

Statut au moment où cette entrée a été écrite : **reconnaissance de l'auteur, correctifs annoncés, ni corrigés ni retestés.** Plus tard le même jour, ce cours a constaté que la release 4.5.0 livrait déjà les correctifs, et l'a retestée : voir l'[entrée suivante](#2026-09-26--retest-sur-slashforge-450). Rien ci-dessous ne change un résultat mesuré. Chaque ligne décrit toujours `v4.4.3` à `bd75a4f`, et ne devient *corrigée* qu'après l'exécution, sur une release nommée, de la liste de vérification qui suit.

| Ce que l'auteur a reconnu | Où ce journal l'a mesuré |
|---|---|
| L'exécution à blanc liste 21 fichiers, l'installation en écrit 32 | QA, première ligne (`l01_dry_run_vs_install`) |
| L'aperçu dit que les guides sont copiés alors qu'ils sont générés | QA, deuxième ligne (`l02_global_vs_project`) |
| Le README est périmé après le renommage | QA, troisième ligne |
| Des commentaires de l'installeur sont périmés | QA, quatrième ligne (lu, commentaires seulement) |
| Le oui automatique non interactif couvre aussi `uninstall` | QA, cinquième ligne (`l01_uninstall`) |
| La validation des modèles est plus stricte que les règles de Claude Code | QA, sixième ligne (`l02_installer_functions`) |
| Deux guides se contredisent sur l'emplacement et la longueur d'un skill | QA, ligne des deux guides ([entrée de la leçon 6](#2026-09-22--leçon-6--deux-règlements-et-quelle-copie-sexécute)) |
| La vérification bash des 200 lignes rate les skills imbriqués | QA, ligne de l'étape de vérification (`l06_verify_glob`) |
| Un test Windows passe quoi qu'il arrive et ouvre une boîte de dialogue d'erreur | [Entrée du labo](#2026-09-22--le-labo-des-leçons-3-à-5-et-où-il-sarrête) et *À vérifier* |
| Générer le rapport avec du `node` en ligne est difficile à autoriser sans risque | Expérience L5a, et « Une écriture sortie du dépôt » dans l'[entrée des leçons 3 à 5](#2026-09-22--les-leçons-3-à-5-exécutées-dans-le-labo) |
| Chaque commande coûte de l'argent avant son premier point de contrôle | Expériences L3 à L5b : 0,17 à 0,45 USD par exécution, calculés par Claude Code, non facturés |
| Il est ambigu de savoir si l'entrée en cache compte dans les jetons annoncés | Expérience L4 : les seules lectures du cache dépassent les 70 000 du README |
| Une copie globale périmée l'emporte en silence sur le kit versionné dans le projet | Expérience e5 : `GLOBAL` |

**Liste de vérification d'une release.** À exécuter sur la première release qui annonce ces correctifs, avant qu'une ligne ne change de statut :

1. Nommer la release : son tag et le SHA exact du commit qu'il désigne, lus dans le dépôt, pas dans un changelog.
2. Relancer les mêmes reproductions (`check.sh`, les vérifications `l01`, `l02` et `l06`) à ce commit, sur chaque système que la release revendique : Linux, Windows et macOS.
3. Comparer la liste de l'exécution à blanc avec les fichiers que l'installation écrit réellement, fichier par fichier, et consigner les deux codes de sortie.
4. Garder les témoins négatifs. Une vérification qui ne trouve rien sur l'ancien commit ne prouve rien sur le nouveau : exécuter donc aussi chaque vérification sur `bd75a4f` et confirmer qu'elle y échoue toujours.
5. Avec une entrée standard qui n'est pas un terminal, vérifier que `uninstall` ne supprime plus de fichiers sans confirmation ou option explicite, et que `--yes` est documenté comme le couvrant s'il le fait encore.
6. Lire comment le README définit désormais le coût par commande et si l'entrée en cache compte. Relancer une commande avec un plafond en dollars pour comparer.
7. Relancer e5 avec une copie personnelle et une copie de projet, noter laquelle s'exécute, et si le kit prévient désormais.
8. Mettre à jour chaque ligne de QA : *corrigé dans `<tag>`, retesté sous `<liste des OS>`*, ou *toujours ouvert dans `<tag>`*. Garder dans la ligne la mesure d'origine et sa date.

Aucune démarche de ce cours auprès de l'amont : rien n'a été publié, déposé ni envoyé.

## 2026-09-26 — Retest sur SlashForge 4.5.0

Vérifier l'amont avant de déclarer quoi que ce soit ouvert a révélé une release que le cours n'avait pas vue : le tag `v4.5.0` à `10d3d916b30323598515aa27aef43a8527e7e967`, daté du 2026-09-25. Son [CHANGELOG](https://github.com/rajdeepratan/SlashForge/blob/10d3d916b30323598515aa27aef43a8527e7e967/CHANGELOG.md) annonce un correctif pour chaque ligne du tableau QA concernant l'installeur et les guides, ainsi que pour le test Windows de l'assistant d'ouverture et les rapports en `node` en ligne. Il ajoute un avertissement quand une installation globale masque une installation de projet, et il crédite ce cours.

`code/slashforge/retest/retest.sh` installe une release donnée dans un dossier jetable et relance `check.sh` contre les attentes de 4.4.3. Exécuté sous Windows 11 avec Git Bash et Node 24.12.0 :

| | 4.4.3 (témoin négatif) | 4.5.0 |
|---|---|---|
| `check.sh` contre les attentes de 4.4.3 | exit 0, 20/20 | exit 1, 16 diffèrent : les attentes sont celles de 4.4.3 |
| Exécution à blanc contre installation | 21 listés, 32 écrits, 11 manquants | 34 et 34, aucun manquant |
| Libellés de l'exécution à blanc | 16 `copy`, 4 `render` | 29 `render`, 4 `copy` |
| `uninstall` sans terminal | 15 suppressions, exit 0 | refusé, exit 1 |
| YAML plié, clôture suivie d'une espace | les deux refusés | les deux acceptés ; 4 vraies erreurs toujours refusées |
| Avertissement de masquage avec `--project` | aucun | affiché |
| Modèles avec `node -e '` en ligne | 4 | 0 |
| Étape 9 sur trois dépôts jetables (`verify-step9.sh`) | le glob ne voit aucun fichier de skill | un `SKILL.md` de 600 lignes et un fichier imbriqué de 250 lignes signalés ; un `SKILL.md` de 300 lignes passe |

Lu, pas exécuté :
- le README et les guides concordent désormais ;
- les trois commentaires périmés ont disparu ;
- le paquet npm 4.5.0 est identique au `bin/` et au `templates/` du tag, aux fins de ligne près ;
- le nouveau test de l'assistant simule les ouvreurs sous Linux et macOS et s'arrête tout de suite sous Windows. Windows n'a donc plus de boîte de dialogue, mais plus d'assertion non plus. **Faux, corrigé le 2026-10-09 :** l'ancien test est toujours là, à côté du nouveau, et lance toujours `start` sous Windows ([entrée](#2026-10-09--slashforge-521-revérifié)).

Le README précise désormais que ses fourchettes de jetons ne séparent pas les lectures du cache de l'entrée fraîche : une clarification, pas une séparation.

Verdict : les huit lignes sur l'installeur et les guides sont **corrigées dans 4.5.0, retestées sous Windows**. Chaque ligne garde sa mesure de 4.4.3. Non retesté :
- Linux, macOS et WSL ;
- aucune exécution avec modèle sur 4.5.0.

Les leçons décrivent toujours 4.4.3, et la CI l'épingle toujours. La [leçon 7](../07-contributing-back/) raconte l'histoire et liste ce qui reste ouvert.

## 2026-10-09 — SlashForge 5.2.1, revérifié

Après la release 5.2.1, l'auteur a demandé un avis sur le [site de documentation](https://www.rajdeepratan.com/slashforge/) et invité à ouvrir des issues. Les entrées du 2026-09-26 ne l'avaient pas vu : l'auteur avait ouvert les issues [#69](https://github.com/rajdeepratan/SlashForge/issues/69) à [#87](https://github.com/rajdeepratan/SlashForge/issues/87) à partir de ce journal, le 2026-09-25, chacune en citant le cours. Douze, de #69 à #80, ont été fermées comme corrigées par 4.5.0 ; #81 a été fermée comme non prévue (c'est Claude Code, pas le kit, qui nomme une commande) ; #82 a été fermée le même jour, et son correctif est sorti en 5.0.0 d'après le changelog ; #83 à #87 sont ouvertes. Entre-temps, le kit est passé à huit commandes, nommées `/slashforge-name`, et une seule installation sert Claude Code, Cursor et Codex.

Versions : tag `v5.2.1` à `7e0e26a`, daté du 2026-10-09 ; Windows 11, Git Bash, Node.js 24.12.0. Le paquet npm est identique aux `bin/` et `templates/` du tag, aux fins de ligne près. L'installeur a tourné depuis le paquet npm dans un répertoire personnel jetable, stdin n'étant pas un terminal, comme dans `check.sh` :

| Vérification | Résultat sur 5.2.1 |
|---|---|
| Exécution à blanc contre installation | 133 annoncés, 133 écrits, aucun écart dans un sens ni dans l'autre |
| Où vont les fichiers | 47 sous `~/.claude` et 86 sous `~/.agents` pour Cursor et Codex. Aucune option ne permet d'installer pour un seul hôte |
| `uninstall` sans terminal | Refusé, exit 1. Avec `--yes`, un fichier à moi dans `setup/slashforge/` est conservé (#82) |
| Un fichier à moi dans un dossier de skill du kit, sous `~/.agents/skills/` | Supprimé avec le dossier |
| `description: >` YAML repliée, dans une copie du paquet | Acceptée, exit 0 |
| Contrôle de taille de setup (étape 9) sur un dépôt jetable | Signale un `SKILL.md` de 600 lignes, une règle de 250 lignes et une commande à moi de 210 lignes ; ignore les fichiers du kit ; exit 1 |
| Avertissement de masquage avec `--project` | Affiché, avec un second pour `~/.agents` |
| Message de fin d'installation | Six commandes et `-quick` ; `status` en liste huit |
| `disable-model-invocation` dans les 17 fichiers Claude Code | Aucun ; les huit commandes de Cursor et Codex l'ont |

**Les propres tests de SlashForge sous Windows.** `node --test` à `v5.2.1` a exécuté 278 tests en 15.5 s : 269 réussis, 2 échecs, 7 sautés, le plus lent en 0.6 s. C'était un clone avec `core.autocrlf=false`. Avec le réglage par défaut de Git for Windows, `core.autocrlf=true`, les templates sont extraits avec des fins de ligne CRLF et deux tests de plus échouent : ils comparent les templates rendus octet par octet et ligne par ligne (11.6 s, 267 réussis, 4 échecs). Les quatre échecs viennent des tests, pas de l'installeur : CRLF deux fois, des barres obliques inverses de `path.join` comparées aux chemins documentés avec `/`, et `fs.symlinkSync` refusé sans le mode développeur. Les deux exécutions fixaient `SSH_CONNECTION`, pour la raison donnée au paragraphe suivant. 5.2.1 ne reproduit donc pas les 523 s. Leur cause sur 4.4.3 reste inconnue, parce que 4.4.3 n'a pas été relancé.

**Une correction.** Le retest du 2026-09-26 dit que Windows n'a plus de boîte de dialogue. C'est faux. 4.5.0 a ajouté un test simulé qui s'arrête tout de suite sous Windows, mais a gardé l'ancien à côté. [`test/install.test.js#L570`](https://github.com/rajdeepratan/SlashForge/blob/7e0e26a78bdfe7e9375a27a17b441d44280325ac/test/install.test.js#L570) (ligne 526 à `v4.5.0`) lance toujours l'assistant sur un fichier absent sans `SSH_CONNECTION`, ce qui appelle `start` sous Windows. C'est lu, pas exécuté, parce que le test ouvre la boîte de dialogue. La phrase du retest reste, marquée ; le tableau de QA a une ligne.

**Le site**, lu comme texte et comme arbre d'accessibilité, pas comme image : aucune capture n'a pu être prise, parce que le panneau wmux était masqué et que Chromium sans interface a planté. Les remarques, pour une réponse privée à l'auteur :

- La démo *Shipping a feature* montre un point de contrôle, la phase 3, avant *PR opened* ; le README en garde quatre (plan, branche, PR, nettoyage). Le point de contrôle de la branche et celui du push avec PR, une ligne chacun, montreraient ce que le kit vend.
- *What it costs* a six tuiles pour huit commandes, et omet la phrase du README selon laquelle les chiffres ne séparent pas les lectures du cache des entrées fraîches. L'expérience L4 montre pourquoi cette phrase compte : sur 4.4.3, `-quick` jusqu'à son premier point de contrôle a utilisé 1,720 jetons frais en entrée et en sortie, et en a lu 158,847 dans le cache.
- *« It empowers people to do their finest work every single time »* est la seule affirmation de la page que personne ne peut vérifier. Le *« Nothing ships that was not planned, gated, verified and reviewed »* du README le dit dans le ton du reste de la page.
- *« Ten phases from plan to merged PR »* : le workflow ouvre la pull request, et c'est une personne qui la fusionne.
- Une question plutôt qu'un défaut : sans option pour choisir l'hôte, un utilisateur de Claude Code reçoit 133 fichiers, dont 86 sous `~/.agents`.

**Les issues du dépôt de SlashForge.** L'auteur a ouvert #69 à #87 à partir de ce journal. Le 2026-10-09, à l'invitation de l'auteur, ce cours a ouvert #104 à #106 et a ajouté les temps sous Windows à #83 dans un [commentaire](https://github.com/rajdeepratan/SlashForge/issues/83#issuecomment-6084208546). L'état de chaque issue le 2026-10-09, et ce que montre la revérification de 5.2.1 :

| Issue | Ouverte par | Sujet | État le 2026-10-09 | Sur 5.2.1 |
|---|---|---|---|---|
| [#69](https://github.com/rajdeepratan/SlashForge/issues/69) | l'auteur | L'exécution à blanc annonce 21 fichiers, l'installation en écrit 32 | fermée, corrigée en 4.5.0 | Tient : 133 annoncés, 133 écrits |
| [#70](https://github.com/rajdeepratan/SlashForge/issues/70) | l'auteur | L'exécution à blanc étiquette `copy` des guides rendus | fermée, corrigée en 4.5.0 | Tient : guides `render`, ressources `copy` |
| [#71](https://github.com/rajdeepratan/SlashForge/issues/71) | l'auteur | Le *What gets installed* du README montre l'ancienne disposition | fermée, corrigée en 4.5.0 | Tient, lu : huit commandes et neuf skills par hôte |
| [#72](https://github.com/rajdeepratan/SlashForge/issues/72) | l'auteur | Des commentaires de l'installeur décrivent du code plus ancien | fermée, corrigée en 4.5.0 | Un nouveau commentaire périmé, *« The four commands »* : #106 |
| [#73](https://github.com/rajdeepratan/SlashForge/issues/73) | l'auteur | `uninstall` sans terminal retire le kit sans demander | fermée, corrigée en 4.5.0 | Tient : refusé, exit 1 |
| [#74](https://github.com/rajdeepratan/SlashForge/issues/74) | l'auteur | Le contrôle du frontmatter refuse ce que Claude Code accepte | fermée, corrigée en 4.5.0 | Tient : une description repliée et une clôture suivie d'un espace sont toutes deux acceptées |
| [#75](https://github.com/rajdeepratan/SlashForge/issues/75) | l'auteur | Le contrôle des 200 lignes de setup ne compte jamais un `SKILL.md` | fermée, corrigée en 4.5.0 | Tient : un `SKILL.md` de 600 lignes, une règle de 250 lignes et une commande de 210 lignes sont signalés |
| [#76](https://github.com/rajdeepratan/SlashForge/issues/76) | l'auteur | Deux guides se contredisent sur la disposition et la longueur d'un skill | fermée, corrigée en 4.5.0 | Tient, lu : `<name>/SKILL.md`, 200 lignes, 500 pour un `SKILL.md` |
| [#77](https://github.com/rajdeepratan/SlashForge/issues/77) | l'auteur | Le test de `forge-open.sh` ne peut pas échouer et ouvre une fenêtre | fermée, corrigée en 4.5.0 | À moitié : l'ancienne assertion est toujours là, #104 |
| [#78](https://github.com/rajdeepratan/SlashForge/issues/78) | l'auteur | Construire un rapport demande un `node -e` en ligne | fermée, corrigée en 4.5.0 | Tient : 0 template avec `node -e '` |
| [#79](https://github.com/rajdeepratan/SlashForge/issues/79) | l'auteur | Une installation globale masque sans le dire celle du projet | fermée, corrigée en 4.5.0 | Tient : l'avertissement est affiché |
| [#80](https://github.com/rajdeepratan/SlashForge/issues/80) | l'auteur | Les chiffres de jetons du README ne disent pas si les lectures du cache comptent | fermée, corrigée en 4.5.0 | Tient dans le README ; la section des coûts du site omet la phrase |
| [#81](https://github.com/rajdeepratan/SlashForge/issues/81) | l'auteur | Claude Code ignore le champ `name` qu'exige l'installeur | fermée, non prévue | — |
| [#82](https://github.com/rajdeepratan/SlashForge/issues/82) | l'auteur | `uninstall` supprime `setup/slashforge/` avec les fichiers de l'utilisateur | fermée ; correctif en 5.0.0 | Tient là ; un fichier à moi dans un dossier de skill du kit sous `~/.agents/skills/` part avec le dossier |
| [#83](https://github.com/rajdeepratan/SlashForge/issues/83) | l'auteur | `node --test` prend 523 s sous Windows | ouverte | 15.5 s ; quatre échecs Windows dans les tests ([commentaire](https://github.com/rajdeepratan/SlashForge/issues/83#issuecomment-6084208546)) |
| [#84](https://github.com/rajdeepratan/SlashForge/issues/84) | l'auteur | Le test de l'assistant d'ouverture saute Windows | ouverte | Toujours sauté ([`#L1853`](https://github.com/rajdeepratan/SlashForge/blob/7e0e26a78bdfe7e9375a27a17b441d44280325ac/test/install.test.js#L1853)) |
| [#85](https://github.com/rajdeepratan/SlashForge/issues/85) | l'auteur | Les points de contrôle du workflow sont des instructions, pas une contrainte | ouverte | Pas revérifié : il faut une exécution avec modèle |
| [#86](https://github.com/rajdeepratan/SlashForge/issues/86) | l'auteur | Une installation de projet quand Claude Code démarre dans un sous-dossier | ouverte | Pas revérifié : il faut une exécution avec modèle |
| [#87](https://github.com/rajdeepratan/SlashForge/issues/87) | l'auteur | La nouvelle exécution de setup et les marqueurs `generated_by` | ouverte | Pas revérifié : il faut une exécution avec modèle |
| [#104](https://github.com/rajdeepratan/SlashForge/issues/104) | ce cours | L'ancienne assertion de l'assistant d'ouverture lance toujours le vrai ouvreur | ouverte | Lu à `v4.5.0` et `v5.2.1`, pas exécuté |
| [#105](https://github.com/rajdeepratan/SlashForge/issues/105) | ce cours | Les fichiers de commande de Claude Code n'ont pas `disable-model-invocation` | ouverte | 0 fichier sur 17 ; la conséquence vient de la documentation, pas d'une exécution avec modèle |
| [#106](https://github.com/rajdeepratan/SlashForge/issues/106) | ce cours | Des listes de commandes qui s'arrêtent à six | ouverte | Le message d'installation, un commentaire, le site |

Limites : Windows seulement. Aucune exécution avec modèle sur 5.x : rien ici ne dit ce que coûtent les commandes, si les points de contrôle tiennent, ni si Claude Code lance une commande de lui-même.

## À vérifier

- Relancer `retest/retest.sh 4.5.0` sous Linux et macOS, et dans WSL ; seul Windows 11 a été retesté.
- Relancer une commande avec modèle sur 4.5.0 (coûts, portes, quelle copie s'exécute) avant de dire quoi que ce soit du comportement à l'exécution après les correctifs.
- Exécuter la liste de vérification de l'entrée du 2026-09-26 sur la première release qui annonce les correctifs, avant de changer un statut de QA.
- Pourquoi le `node --test` de SlashForge a pris 523 s sur 4.4.3 sous Windows. 5.2.1 s'exécute en 15.5 s ([2026-10-09](#2026-10-09--slashforge-521-revérifié)). 4.4.3 n'a pas été relancé : son test de l'ouvreur ouvre une boîte de dialogue d'erreur (voir l'entrée du labo), et 5.2.1 a encore cette assertion (#104), donc toute exécution de la suite sous Windows doit fixer `SSH_CONNECTION`.
- Si Claude Code lance `/slashforge-code` de lui-même quand une demande correspond à sa description, comme sa documentation le permet : 5.2.1 n'y met pas `disable-model-invocation` (#105). Il faut une exécution avec modèle, avec un plafond.
- Les vérifications de 5.2.1 sous Linux et macOS.
- Pourquoi e1 a indiqué 15 tours sous `--max-turns 10` et s'est terminée normalement, alors que e1b s'est arrêtée à 11.
- Si le modèle trouve `.claude/setup/slashforge/…` quand Claude Code est démarré dans un sous-dossier d'un dépôt avec une installation de projet (leçon 2).
- Le coût d'un workflow complet au-delà de ses points de contrôle. Le labo s'arrête au premier point de contrôle par conception ; aller plus loin suppose d'y répondre, ce qui est la décision de l'auteur.
- Si un skill écrit comme un fichier dans `commands/` est jamais choisi par le modèle de lui-même, ou seulement quand un guide le nomme.

## Questions ouvertes

- La nouvelle exécution de setup respecte-t-elle les marqueurs `generated_by` comme le dit son guide : rafraîchir les fichiers de la version actuelle, poser la question pour les plus anciens, laisser tranquilles ceux qui ont été modifiés ?
- L'amont accepterait-il une exécution à blanc construite à partir d'`installFiles` lui-même, comme le `-WhatIf` de PowerShell passe par le même `ShouldProcess` que l'action ? Pas proposé : rien ne sort de ce dépôt sans l'accord de l'auteur.
