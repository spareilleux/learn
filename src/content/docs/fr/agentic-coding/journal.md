---
title: Journal
description: Notes de progression datées du cours de programmation agentique — les versions de Claude Code, de Codex et du SDK MCP, les captures et ce qu'elles ont coûté, les surprises dans les deux agents et dans le serveur MCP de GuitarAlchemist/ga, et les points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Claude Code et la CLI Codex installés sous Windows ; versions notées ci-dessous
- [x] CI : le hook, le serveur MCP (client du SDK et sessions brutes dans les deux époques du protocole) et les fichiers de configuration, sous Linux, Windows et macOS, sans agent ni clé d'API
- [x] Leçon 1 : agents, outils et permissions
- [x] Leçon 2 : contexte du projet, `CLAUDE.md`, `AGENTS.md`, mémoire et compaction
- [x] Leçon 3 : hooks, skills et sous-agents
- [x] Leçon 4 : MCP, un serveur C# pour les deux agents
- [x] Leçon 5 : skills de Matt Pocock et workflow en tracer bullets
- [x] Leçon 6 : labo d’isolation Sandcastle borné
- [x] Leçon 7 : cycle Compound Engineering et apprentissage durable
- [ ] Sessions Codex : chaque capture qui a besoin du modèle (limite d'utilisation jusqu'au 2026-09-19)
- [ ] Leçon 8 : travailler sur GuitarAlchemist/ga

## 2026-09-14 — Versions et installation

- **Claude Code** : installeur natif, `~/.local/bin/claude`. La session a démarré sur la **2.1.270** ; `claude doctor` a ensuite indiqué « Last update attempt: success → 2.1.271 (2026-09-14) », et les nouvelles sessions lancées à partir d'environ 22:14 UTC tournaient en **2.1.271**. La session en cours reste sur sa version jusqu'à son redémarrage, donc les captures d'avant et d'après cette heure diffèrent de version. Chaque capture des leçons nomme la sienne.
- **CLI Codex** : **0.154.0**, installée avec `npm install -g @openai/codex` (Node.js 24.12.0). L'installeur PowerShell de la documentation n'a pas été essayé.
- **.NET** : `code/agentic-coding/global.json` fixe le SDK 10.0.100 avec `rollForward: latestFeature` ; en local, cela sélectionne la 10.0.112, alors que la racine du dépôt, sans `global.json`, obtient une préversion 11.0. La CI utilise `actions/setup-dotnet` avec le même `global.json`.
- **ModelContextProtocol** 2.2.0 et Microsoft.Extensions.Hosting 10.0.12 pour le serveur ; GuitarAlchemist/ga utilise ModelContextProtocol 1.3.0.
- **La documentation déménage** : `docs.anthropic.com/en/docs/claude-code/…` redirige (301) vers `code.claude.com/docs/en/…` ; la documentation de Codex est sur `learn.chatgpt.com/docs/…`. Les deux sites servent chaque page en Markdown avec un suffixe `.md`, et c'est ainsi que les affirmations des leçons ont été vérifiées, page par page.
- Aucune `ANTHROPIC_API_KEY` sur la machine ni en CI : chaque capture a utilisé l'abonnement.

## 2026-09-14 — Les captures et leur coût

Chaque sortie d'agent dans les leçons est une capture, avec son heure UTC. Ce que `claude -p` a indiqué :

| Capture | Leçon | Tours | Coût indiqué |
|---|---|---|---|
| Éléments non cochés dans les journaux, 22:10 | 1 | 3 | 0,34 $ |
| Serveur MCP, `D dorian`, `Gb major`, `ladybugdb`, 22:11 | 4 | 5 | 0,36 $ |
| `${CLAUDE_PROJECT_DIR}` dans `.mcp.json`, premier essai, 22:15 | 4 | 4 | 0,39 $ |
| Hook bloquant `git push --prune`, 22:18 | 3 | 2 | |
| Écriture refusée en mode `default`, 22:22 | 1 | 2 | |
| Skill, 22:24 et 22:25 | 3 | 6 et 2 | |
| Expérience `CLAUDE.md` / `AGENTS.md`, 22:37 | 2 | 1 chacune | |
| Sous-agent `lesson-checker`, 22:48 | 3 | 4 | 0,49 $, dont 0,04 $ pour le sous-agent Haiku |
| Trois variantes de `.mcp.json`, 22:54 | 4 | 4 | 0,34 $ |

Le « coût » est ce qu'indique la sortie JSON ; sur un abonnement, il est décompté des limites d'utilisation plutôt que facturé.

`codex exec` sur la même question que la première capture s'est arrêté avec l'erreur citée dans la [leçon 1](../01-agents-and-permissions/) : la limite d'utilisation, jusqu'au « Sep 19th, 2026 9:42 AM ». Les commandes Codex qui n'appellent pas de modèle ont fonctionné : `codex --help`, `codex exec --help`, `codex mcp add`, `codex mcp list`, `codex mcp get`, avec un `CODEX_HOME` temporaire.

## 2026-09-14 — Surprises dans Claude Code

- **`claude -p` suit le `defaultMode` des paramètres utilisateur.** Le `~/.claude/settings.json` de cette machine fixe `"defaultMode": "auto"`, donc un `claude -p` à qui l'on a demandé de créer un fichier l'a créé sans demander. Le tableau de la documentation dit que `claude -p` démarre en `default`, mais les paramètres passent avant dans l'ordre qu'elle donne. La leçon 1 passe `--permission-mode default` pour la capture d'un refus.
- **`--allowedTools` ne restreint pas la liste des outils**, il pré-approuve ; `--tools` restreint. Facile à confondre dans les scripts.
- **Git Bash réécrit un prompt qui commence par `/`.** `claude -p "/journal-status …"` est arrivé sous la forme `C:/Program Files/Git/journal-status …`. `MSYS_NO_PATHCONV=1` corrige le problème. Le modèle a ensuite contourné la commande manquante en lisant lui-même `SKILL.md`.
- **Un `Read` d'un sous-agent Haiku avec le chemin `/C:/Users/…`** a été refusé comme « a suspicious Windows path pattern that requires manual approval », en mode `default`, deux fois, avant qu'il ne réessaie avec des chemins relatifs. Les refus apparaissent dans le `permission_denials` du parent.
- **L'agent parent a mal attribué une règle** : il a dit à l'utilisateur que « Key takeaways » ne venait de nulle part, alors que la règle était dans la propre définition du sous-agent, que le parent ne lit jamais.
- **Les hooks d'un dossier non approuvé s'exécutent en mode `-p`**, alors que ses règles allow sont ignorées avec un avertissement. Documenté sous [confiance de l'espace de travail](https://code.claude.com/docs/en/hooks#workspace-trust), et cela mérite une ligne dans tout script du genre « cloner et lancer ».
- **`${CLAUDE_PROJECT_DIR}` dans les args de `.mcp.json` échoue sans valeur par défaut** (`CONNECTION_CLOSED`), et c'est documenté : la variable est définie pour le serveur, pas pour Claude Code. `${CLAUDE_PROJECT_DIR:-.}` fonctionne. `claude mcp list` affiche cette entrée comme `${CLAUDE_PROJECT_DIR}/server/LearnMcp.dll`, sans le `:-.` : une bizarrerie d'affichage, le serveur s'est bien connecté.
- **L'AGENTS.md injecté après la compaction était celui du début de la session.** La session de ce cours a démarré à 20:56 UTC ; la règle Mermaid a été commitée dans `AGENTS.md` à 22:01 ; la session a compacté à 22:32. La transcription de la session montre les fichiers d'instructions injectés après la compaction sans la règle Mermaid, alors que le fichier sur disque la contenait et que la documentation dit que le `CLAUDE.md` à la racine du projet est « réinjecté depuis le disque ». La copie à jour est arrivée à 23:06:49 UTC, attachée au message entrant suivant, sous la forme « Instruction files were re-read after the conversation was compacted; these differ from their earlier copies » : pendant 34 minutes, pendant que les leçons 1 à 4 étaient écrites, les instructions en contexte n'avaient pas la règle (les leçons ont quand même utilisé Mermaid, d'après le résumé de la conversation). Ici, `CLAUDE.md` ne contient que `@AGENTS.md` : l'import joue peut-être un rôle. Observé une fois, sur 2.1.270, cause inconnue.
- **Le hook git de la machine a bloqué mes commandes deux fois** : des expressions régulières comme `push .*--delete` correspondaient à du texte à l'intérieur de here-documents et de données de test JSON. Écrire les fichiers avec un outil d'édition plutôt qu'avec un here-document shell l'a évité. Le même hook laisse passer `git push --prune`. C'est la motivation du hook de la leçon 3, qui analyse la commande.
- **La recherche d'outils est activée** : les outils MCP ne sont pas dans le contexte du modèle au démarrage ; le premier appel de chaque capture MCP est `ToolSearch`.

## 2026-09-14 — Surprises dans Codex

- `codex mcp-server` a disparu ; la page de documentation qui le décrivait est désormais un avis de suppression qui renvoie vers le serveur d'application expérimental.
- `--full-auto` est rejeté par `codex exec` 0.154.0 (`unexpected argument '--full-auto'`), la politique d'approbation `untrusted` est retirée, et `--approve-for-me` est nouveau. Beaucoup de tutoriels utilisent encore les anciennes options.
- Sous Windows, les commandes de hook s'exécutent avec `%COMSPEC%` ou `cmd.exe /C` ([source](https://github.com/openai/codex/blob/60e35765c3e43e152bf5b382a38a0628efd70842/codex-rs/hooks/src/engine/command_runner.rs#L435-L441)) : la forme documentée `$(git rev-parse --show-toplevel)` a besoin d'un remplacement `command_windows`.
- Cette machine a des hooks à la fois dans `~/.codex/hooks.json` et dans `~/.codex/config.toml` ; chaque `codex exec` avertit « prefer a single representation for this layer ».
- `codex mcp add` avec un `CODEX_HOME` sous le dossier temporaire avertit qu'il refuse d'y créer des alias PATH, et continue.
- `codex mcp list` affiche « enabled », sans vérifier la connexion ; `claude mcp list` vérifie les serveurs qu'il peut démarrer.

## 2026-09-14 — Le serveur MCP et ses tests

- Le premier test brut envoyait cinq lignes JSON d'un coup dans le pipe : les réponses sont revenues dans le désordre (id 4 avant id 3). Le mode brut attend désormais chaque réponse avant d'envoyer la requête suivante.
- `server/discover` sans `_meta` répond `-32602`, « requires per-request metadata declaring a supported protocol version ».
- Le SDK renvoie un `string[]` sous forme de texte JSON avec `"` échappé en `\u0022`, et les caractères non ASCII échappés aussi : `course_outline` renvoie donc une seule chaîne, pour qu'un tiret cadratin dans un titre reste lisible.
- La console Windows affichait ce tiret cadratin comme `-` jusqu'à ce que le client de vérification règle `Console.OutputEncoding` sur UTF-8 ; les fichiers attendus sont identiques sur les trois systèmes d'exploitation.
- Un `Console.WriteLine` à l'intérieur d'un outil casse les sessions brutes mais **pas** la sortie du client du SDK, qui a ignoré la ligne non JSON : le client du SDK est un test tolérant.
- Premier `dotnet run guard-git-push.cs` : environ 13 s de compilation ; les exécutions suivantes, 0,24 s grâce au cache de build. Les enregistrements du hook utilisent un délai d'expiration de 120 s.
- L'exécution de CI [34904115148](https://github.com/spareilleux/learn/actions/runs/34904115148) a réussi dès le premier push sous Linux, Windows et macOS.

## 2026-09-14 — GuitarAlchemist/ga, au commit `a826864`

Constats à l'intention de l'auteur de ga ; ce cours n'écrit pas dans ga, et rien n'a été signalé en amont.

- **`GaMcpServer/Tools/ScaleTool.cs`, `GetScaleNotes`** ([lignes 50-80](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/ScaleTool.cs#L50-L80)) :
  - n'écrit qu'avec des dièses : `F major` donne `A#` au lieu de `Bb` ;
  - la description du paramètre donne `'Bb major'` en exemple, et l'outil rejette `Bb` (« Unknown root note 'Bb'. Use sharps… ») ;
  - les erreurs sont renvoyées comme des résultats texte ordinaires, pas avec `isError: true` ni une exception ;
  - tout mode qui ne commence pas par « minor » est traité comme majeur : `D dorian` renvoie ré majeur ;
  - `get_key_notes("Key of F")` écrit `Bb`, donc deux outils du même serveur se contredisent.
  Observé via un build local de ga le 2026-09-14 vers 22:57 UTC ; le code source à `a826864` a la même logique.
- **Le `.mcp.json` à la racine de ga** contient des chemins absolus propres à une machine : il ne fonctionne que sur la machine de son auteur. Des chemins relatifs, ou `${VAR:-default}`, le rendraient partageable.
- **ModelContextProtocol 1.3.0** dans `GaMcpServer.csproj`, passé de 1.1.0 parce que le paquet compagnon de gouvernance dépend de `>= 1.3.0` ; la version stable actuelle est la 2.2.0, qui parle la révision 2026-07-28.
- **`Scripts/sync-agents-md.ps1`** : son aide dit qu'un avertissement « do not edit » est « appended at the top », alors que le code remplace la ligne de note ; sans conséquence, mais le commentaire n'est plus à jour. `CLAUDE.md` nomme aussi la version `2.1.126` de l'extension Claude Code, 145 versions de correctif en retard.

## 2026-09-20 — Tutoriels de workflow agentique

- Versions épinglées : skills de Matt Pocock `c55ee460`, Sandcastle `e99f832f` (package 0.12.0) et Compound Engineering `6be0932b` (plugin 3.27.0).
- Leçons 5 à 7 ajoutées en anglais, français et espagnol à partir des sources upstream primaires.
- Aucun plugin, identifiant ou fournisseur payant n’a été utilisé. Les exécutions Sandcastle et celles avec modèle restent des expériences manuelles.
- Le conflit upstream entre l’ancienne documentation Sandcastle en `config.json` et les templates TypeScript actuels est consigné au lieu d’être tranché silencieusement.

## À vérifier

- Les commandes d'installation de la leçon 1 sous Linux, WSL et macOS, pour les deux agents, et l'installeur PowerShell de Codex.
- Une session Codex qui répond à la première question de la leçon 1, et la même expérience `AGENTS.md` que dans la leçon 2.
- Hooks de Codex : si l'exemple `config.toml` de la leçon 3 s'exécute sous Windows avec `command_windows`, et si son chemin relatif fonctionne quand Codex démarre dans un sous-répertoire ; le processus d'approbation dans `/hooks`.
- Skills de Codex : si `$ARGUMENTS`, `argument-hint` et `allowed-tools` ont un sens pour Codex, et l'invocation de `$journal-status`.
- Agent personnalisé Codex `lesson_checker` : le chargement, et `sandbox_mode = "read-only"` en pratique.
- MCP dans Codex : une session qui appelle `scale_notes` et `course_outline` ; le répertoire de travail par rapport auquel les `args` relatifs sont résolus sans `cwd` ; `default_tools_approval_mode = "approve"`.
- Si `project_doc_fallback_filenames` est accepté dans le `.codex/config.toml` d'un projet.
- Si Codex développe les imports `@path` dans `AGENTS.md` (sa documentation n'en parle pas).
- Si Claude Code et Codex tolèrent une ligne non JSON sur le stdout d'un serveur, comme le fait le client du SDK.
- Pourquoi l'`AGENTS.md` relu n'a atteint la session qu'avec le message entrant suivant la compaction : recommencer avec un `CLAUDE.md` simple, sans import, sur 2.1.271.
- `codex exec -o` : si le fichier est écrit par la CLI hors du bac à sable en mode `read-only`.
- Une capture d’installation jetable pour chaque workflow, sans installer des suites qui se chevauchent dans le même fixture.
- Une exécution Sandcastle avec Docker, branche explicite, une itération, aucun merge et des preuves de test contrôlées par le host.
