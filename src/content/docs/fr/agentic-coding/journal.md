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
- [x] Un format d'observation pour les exécutions de modèles, de skills et de sous-agents, et sa première observation (2026-09-26)
- [x] Trois observations rétrospectives consignées : les dépassements de délai des hooks (2026-09-26), une reprise après un plantage de wmux et la fusion anticipée de GA #740 (2026-09-27)

## QA

Le logiciel qu'enseigne ce cours, c'est Claude Code, la CLI Codex et, via la leçon sur MCP, le serveur MCP de GuitarAlchemist/ga — les trois ont donné des constats. Quatre d'entre eux sont de la documentation qui ne correspond pas au comportement, ce qui compte plus ici qu'ailleurs : un tutoriel sur les agents est surtout un tutoriel sur la confiance à accorder à ce qu'un outil dit de lui-même. Rien n'a été signalé en amont.

Il n'y a pas de tableau d'expériences : ce journal consigne des surprises et des constats attendu-contre-obtenu, mais aucune entrée n'a posé d'hypothèse avant une mesure, et en rédiger une à rebours d'un résultat est précisément ce que cette section sert à empêcher.

| Attendu | Ce qui se passe | Où | Mesure | État |
|---|---|---|---|---|
| `claude -p` démarre en mode `default`, comme le dit le tableau de la documentation | Il suit le `defaultMode` des réglages de l'utilisateur. Cette machine pose `"defaultMode": "auto"` : un `claude -p` à qui l'on demande de créer un fichier l'a créé sans rien demander | `~/.claude/settings.json` | Un fichier écrit sans approbation demandée | Reproduit ; la documentation et le comportement se contredisent [2026-09-14](#2026-09-14--surprises-dans-claude-code) |
| `--allowedTools` restreint les outils disponibles | Il les pré-approuve. C'est `--tools` qui restreint | CLI Claude Code | Deux options, dont l'une fait dans un script l'inverse de ce que son nom suggère | Reproduit, facile à confondre [2026-09-14](#2026-09-14--surprises-dans-claude-code) |
| `${CLAUDE_PROJECT_DIR}` dans les args de `.mcp.json` se résout aussi pour Claude Code | Il est posé pour le serveur, pas pour Claude Code : le serveur ne démarre donc pas | `.mcp.json` | `CONNECTION_CLOSED` ; `${CLAUDE_PROJECT_DIR:-.}` fonctionne | Documenté ; le mode de panne, non [2026-09-14](#2026-09-14--surprises-dans-claude-code) |
| `AGENTS.md` est relu sur le disque juste après un compactage, comme le dit la documentation | La copie injectée après le compactage était celle du début de la session | Claude Code 2.1.270 | Session démarrée à 20 h 56 UTC, règle versée à 22 h 01, compactage à 22 h 32, et la bonne copie arrivée à 23 h 06 min 49 s — 34 minutes de retard | Reproduit une fois, cause inconnue, non signalé [2026-09-14](#2026-09-14--surprises-dans-claude-code) |
| Un prompt qui commence par `/` parvient au modèle tel qu'écrit | Git Bash le réécrit : `claude -p "/journal-status …"` est arrivé en `C:/Program Files/Git/journal-status …` | Git Bash sous Windows | `MSYS_NO_PATHCONV=1` corrige. Le modèle a ensuite contourné le prompt déformé au lieu de le signaler | Reproduit ; c'est le shell, pas Claude Code [2026-09-14](#2026-09-14--surprises-dans-claude-code) |
| Un sous-agent qui lit un chemin Windows absolu est autorisé en mode `default` | Le `Read` de `/C:/Users/…` par un sous-agent Haiku a été refusé comme « a suspicious Windows path pattern that requires manual approval », deux fois, avant qu'il réessaie en relatif | Claude Code, mode `default` | Deux refus, puis un contournement trouvé seul par le sous-agent | Reproduit [2026-09-14](#2026-09-14--surprises-dans-claude-code) |
| Un agent sait dire d'où vient l'une de ses propres règles | Le parent a affirmé à l'utilisateur que « Key takeaways » ne venait de nulle part, alors que c'était dans la définition du sous-agent — que le parent ne lit jamais | sous-agents de Claude Code | Une attribution fausse et assurée | Reproduit ; une limite qui mérite d'être enseignée [2026-09-14](#2026-09-14--surprises-dans-claude-code) |
| Les réponses JSON-RPC reviennent dans l'ordre où elles ont été demandées | Cinq lignes envoyées d'un coup sont revenues dans le désordre : l'id 4 avant l'id 3 | session MCP brute du cours | Corrigé en attendant chaque réponse plutôt qu'en enchaînant | Reproduit ; le protocole l'autorise, le premier code du cours non [2026-09-14](#2026-09-14--le-serveur-mcp-et-ses-tests) |
| `codex exec` accepte encore `--full-auto`, comme le montrent la plupart des tutoriels | La 0.154.0 le rejette (`unexpected argument '--full-auto'`) ; la politique d'approbation `untrusted` est retirée et `--approve-for-me` est nouvelle | CLI Codex 0.154.0 | Une option retirée, une politique retirée, une option nouvelle | Reproduit ; `codex mcp-server` a disparu aussi, sa page de doc étant devenue un avis de retrait [2026-09-14](#2026-09-14--surprises-dans-codex) |
| `codex mcp list` dit si un serveur fonctionne | Il affiche « enabled » sans vérifier la connexion, à la différence de `claude mcp list`, qui démarre les serveurs qu'il peut | CLI Codex 0.154.0 | Un état qui ne peut pas échouer | Reproduit [2026-09-14](#2026-09-14--surprises-dans-codex) |
| `GetScaleNotes` orthographie les notes selon la tonalité demandée | Il n'écrit qu'avec des dièses, quelle que soit la tonalité | `GaMcpServer/Tools/ScaleTool.cs` 50-80 | « F major » donne la♯ là où la♭ … si♭ est juste | Corrigé en amont par [#681](https://github.com/GuitarAlchemist/ga/pull/681), fusionnée le 2026-09-23, avec des tests [2026-09-14](#2026-09-14--guitaralchemistga-au-commit-a826864), [2026-09-24](#2026-09-24--correctifs-amont) |
| L'outil accepte les orthographes bémolisées que sa propre documentation donne en exemple | Il les refuse : `Unknown root note 'Bb'` | `GaMcpServer/Tools/ScaleTool.cs` | L'exemple de la doc est l'entrée qui échoue | Corrigé en amont par [#681](https://github.com/GuitarAlchemist/ga/pull/681), fusionnée le 2026-09-23, avec des tests [2026-09-14](#2026-09-14--guitaralchemistga-au-commit-a826864), [2026-09-24](#2026-09-24--correctifs-amont) |
| Un mode qui n'est ni majeur ni mineur rend bien ce mode | Tout ce qui ne commence pas par « minor » est traité comme majeur : `D dorian` rend donc ré majeur | `GaMcpServer/Tools/ScaleTool.cs` | Capturé en direct pendant la leçon | Corrigé en amont par [#681](https://github.com/GuitarAlchemist/ga/pull/681), fusionnée le 2026-09-23, avec des tests [2026-09-14](#2026-09-14--guitaralchemistga-au-commit-a826864), [2026-09-24](#2026-09-24--correctifs-amont) |
| Deux outils d'un même serveur orthographient une note de la même façon | `get_key_notes("Key of F")` écrit si♭ tandis que `GetScaleNotes` n'écrit qu'en dièses | serveur MCP de GA | Deux réponses à une question, depuis un seul serveur | Corrigé en amont par [#681](https://github.com/GuitarAlchemist/ga/pull/681), fusionnée le 2026-09-23, avec des tests [2026-09-14](#2026-09-14--guitaralchemistga-au-commit-a826864), [2026-09-24](#2026-09-24--correctifs-amont) |
| Une erreur MCP est rendue comme une erreur | Elle est rendue comme du texte ordinaire | `GaMcpServer/Tools/ScaleTool.cs` | Ni `isError`, ni exception : un client ne peut pas distinguer le succès de l'échec | Reproduit, non signalé [2026-09-14](#2026-09-14--guitaralchemistga-au-commit-a826864) |
| Le `.mcp.json` à la racine d'un dépôt est partageable | Celui de GA contient des chemins absolus propres à une machine | racine du dépôt GA | Des chemins qui ne marchent que sur une machine | Reproduit, non signalé [2026-09-14](#2026-09-14--guitaralchemistga-au-commit-a826864) |

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

## 2026-09-24 — Correctifs amont

- Les quatre lignes `ScaleTool` sont corrigées en amont par [#681](https://github.com/GuitarAlchemist/ga/pull/681), fusionnée le 2026-09-23. `GetScaleNotes` orthographie une lettre par degré : `F major` donne `F G A Bb C D E`, et `Bb major`, l'exemple de sa propre documentation, est accepté et donne `Bb C D Eb F G A`. `D dorian` donne `D E F G A B C`. Chaque cas est un test du `ScaleToolTests.cs` de GA, que j'ai lu sur la branche main de GA sans l'exécuter.
- Les deux outils sont maintenant d'accord. Une session qui corrigeait d'autres constats des cours a appelé `KeyTool.GetKeyNotes` et `ScaleTool.GetScaleNotes` pour les 30 tonalités de `Key.Items`, et ils ont orthographié les mêmes notes pour chacune.

## 2026-09-26 — Un format d'observation pour les modèles, les skills et les sous-agents

Les notes sur les exécutions d'agents dérivent vers l'anecdote : « Opus l'a fait plus vite », « le sous-agent s'est perdu ». Une anecdote mélange trois choses : ce que le modèle a raisonné, ce que le harnais l'a laissé faire, et qui possédait le travail. Le format ci-dessous les sépare, pour que deux observations puissent être comparées, ou déclarées non comparables.

**La fiche.** Une ligne par exécution. Un champ qu'on n'a pas s'écrit *inconnu*, jamais deviné.

| Champ | Ce qu'on y met |
|---|---|
| Date, identifiant d'exécution | Date et heure locales avec leur décalage ; l'identifiant de corrélation ou de session |
| Dépôt | Le SHA exact auquel chaque dépôt a été lu ou modifié |
| Harnais | CLI ou application et sa version (`claude --version`), et le système d'exploitation |
| Modèle, demandé et observé | Ce qui a été demandé, et ce que montre un reçu. Un nom de modèle affiché par une interface ou par l'agent lui-même est *auto-déclaré*, pas un reçu |
| Skill ou sous-agent | Nom et version, ou une empreinte du fichier ; le rôle : parent, sous-agent ou agent pair |
| Tâche et contexte | La tâche en une phrase ; le contexte fourni (fichiers, consignes, mémoire) |
| Permissions | Le mode de permission, et ce qui a été autorisé ou refusé |
| Hypothèse | Écrite avant l'exécution, ou marquée *observation rétrospective* |
| Preuve | La commande, l'artefact, le journal ou le code de sortie qu'un lecteur peut rouvrir |
| Résultat et état | L'un de : soumis, visible, accepté, terminé, vérifié indépendamment |
| Catégorie d'échec | Raisonnement du modèle ; lanceur, outil, authentification, permission ou environnement ; orchestration ou propriété |
| Jetons et coût | Le chiffre et sa provenance : facture du fournisseur, estimation du harnais, ou *inconnu* |
| Confiance et limites | Taille d'échantillon, et ce que l'exécution ne peut pas montrer |
| Reproductibilité | Ce qu'il faut pour une seconde exécution : mêmes entrées, graine, versions |
| Suite | La prochaine vérification, avec son responsable |

**Les états ne sont pas interchangeables.**
- *Soumis* : la demande est partie.
- *Visible* : le destinataire l'affiche.
- *Accepté* : le destinataire en a pris la responsabilité.
- *Terminé* : il dit avoir fini.
- *Vérifié indépendamment* : quelqu'un d'autre a revérifié la preuve.

Un wrapper encore en cours, un processeur occupé ou un message « terminé » ne prouve aucun des deux derniers.

**Les catégories d'échec non plus.**
- Un dépassement de délai dû à un hôte lent est un échec d'environnement, pas un échec du modèle.
- Une affirmation fausse faite alors que tous les outils fonctionnent est un échec de raisonnement.
- Deux agents qui écrivent le même fichier, c'est un échec de propriété, quel que soit le modèle.

**Pas de classement tiré d'anecdotes.** Des tâches, des budgets et des contextes différents ne se classent pas les uns contre les autres. Une comparaison de modèles équitable demande :
- des tâches appariées aux entrées fixes ;
- des exécutions ou des graines répétées là où les résultats varient ;
- des critères fixés et mis à l'aveugle avant les exécutions ;
- une vérification indépendante de chaque résultat ;
- le coût rapporté à côté de la qualité.

Cette comparaison est *proposée, pas réalisée*.

**Première observation : cette délégation, 2026-09-26.** Un coordinateur (Codex) a confié à une session Claude Code quatre consignes de cours et un diagnostic, corrélation `test-quality-courses-20260926` et ses voisines. Seule la preuve dont dispose cette session est consignée.

| Champ | Observation |
|---|---|
| Harnais | Claude Code 2.1.282 (`claude --version`, 13 h 39 EDT). La vérification préalable du coordinateur voyait aussi 2.1.282 installée, alors que le registre npm proposait 2.1.283. Aucune mise à jour ni aucun redémarrage n'a été fait |
| Modèle | Auto-déclaré seulement : l'interface de la session affichait « Opus 5.5 (1M context) », réflexion moyenne, et son prompt système nomme le même modèle. Aucun reçu de fournisseur n'a été vérifié |
| Rôles | Codex comme coordinateur ; cette session comme seul rédacteur dans le worktree de learn ; un sous-agent en lecture seule sur un clone épinglé d'AutoHarness ; un agent pair (Augment) pour un audit statique en lecture seule d'Abide, écrit dans le dossier de passation partagé |
| Bus partagé | Le coordinateur a rapporté que les appels status et inbox du bus de messages partagé renvoyaient « Transport closed ». Rien ne montre que le bus ait accepté une revendication ; la coordination est passée par des fichiers dans un dossier partagé |
| Hypothèses | Écrites avant la mesure pour le seul labo test-quality ([leçon 6 du repository-dogfooding](../../repository-dogfooding-lab/06-mutation-property-testing/)) ; tout le reste ici est *observation rétrospective* |
| Résultats, par état | Labo mesuré et journal écrit : terminé, pas vérifié indépendamment. La note de supervision du coordinateur dit avoir ré-analysé les rapports de mutation et trouvé les mêmes nombres ; c'est une revérification de la preuve consignée, pas une réexécution. Diagnostic des hooks : terminé ; le coordinateur a qualifié sa cause racine d'hypothèse |
| Échecs vus, par catégorie | Raisonnement, attrapé avant la mesure : un générateur d'entrées malformées qui pouvait produire une entrée valide. Usage d'outil, attrapé par un contrôle de hachage : une modification par script a converti en silence un fichier pré-inscrit en CRLF, et elle a été annulée. Lanceur et environnement : un here-document du shell n'a pas pu être analysé, et rien n'a été écrit ; sur l'hôte, lancer un `bash` nu prenait environ 2,8 s pendant le diagnostic des hooks. Orchestration : rien d'observé ; un seul rédacteur par dépôt a tenu |
| Jetons et coût | *Inconnu*. Aucune facture ni aucun reçu d'usage n'a été lu. Aucune API payante n'a été appelée |
| Limites | Une session, un jour, un coordinateur ; ce n'est l'échantillon de rien |

## 2026-09-26 — Trois hooks en dépassement de délai, et un hôte lent

*Observation rétrospective : aucune hypothèse n'a été écrite avant ces mesures.* Les preuves sont locales : un harnais et ses journaux, conservés dans le dossier de passation du coordinateur, pas dans ce dépôt.

**Le symptôme.** À chaque prompt, trois hooks `UserPromptSubmit` dépassaient leur délai, et leur sortie était jetée. Tous trois appartiennent à un même plugin tiers, [claude-octopus](https://github.com/nyldn/claude-octopus) 9.56.1, installé au commit [`cb2677b`](https://github.com/nyldn/claude-octopus/tree/cb2677b2bd442bcc501489cc6110ab54fb14e701). Son [`hooks.json`](https://github.com/nyldn/claude-octopus/blob/cb2677b2bd442bcc501489cc6110ab54fb14e701/hooks/hooks.json#L300-L325) donne 5 s à deux d'entre eux et 8 s au troisième. Les scripts ont été lus avant toute exécution :
- ce sont des injecteurs de contexte consultatifs, pas des contrôles de sécurité ;
- chacun commence par lire stdin avec `timeout 3 cat` ([`done-criteria.sh`, ligne 26](https://github.com/nyldn/claude-octopus/blob/cb2677b2bd442bcc501489cc6110ab54fb14e701/hooks/done-criteria.sh#L26)) ;
- celui qui concerne GitHub n'agit que dans le propre dépôt du plugin.

**La mesure.** Un harnais a lancé chaque hook hors de Claude Code :
- `env -i`, un `HOME` temporaire vide, un prompt synthétique, les seuils d'origine ;
- une exécution chacun, le 2026-09-26 vers 13 h 00 EDT, dans Git Bash sous Windows 11 ;
- aucun appel réseau et aucun fournisseur lancé, et le `HOME` temporaire était toujours vide ensuite.

| Commande | Sortie | Durée réelle |
|---|---|---|
| `bash -c true` | 0 | 2 829 ms |
| `bash -lc true` | 0 | 25 457 ms |
| `timeout 3 cat </dev/null` | 0 | 7 031 ms |
| `python3 -c pass` | 0 | 10 357 ms |
| `python -c pass` | 0 | 1 539 ms |
| `done-criteria.sh` (5 s) | 124, délai dépassé | 9 546 ms, 0 octet en sortie |
| `user-prompt-submit.sh` (5 s) | 124, délai dépassé | 11 690 ms, 0 octet en sortie |
| `github-work-queue-watch.sh` (8 s) | 124, délai dépassé | 15 298 ms, 0 octet en sortie |

**Ce que cela montre.**
- Le symptôme se reproduit hors de Claude Code.
- Ce n'est pas la logique des hooks qui consomme le budget. Le chemin le moins coûteux dans `done-criteria.sh` est un `bash` neuf, puis `timeout 3 cat` sur une entrée déjà arrivée à sa fin. Ces deux étapes seules coûtent 2,8 s + 7,0 s, plus que les 5 s entières.
- Sur cet hôte, à ce moment-là, *lancer n'importe quel processus* prenait des secondes.

**Ce que cela ne montre pas.** La cause est *très probablement* une latence de création de processus sur tout l'hôte, et elle n'est pas isolée. Les candidats sont :
- la charge : environ 40 processus `bash`, 65 `node` et 13 `claude` tournaient ;
- l'analyse antivirus de chaque lancement ;
- un profil de connexion coûteux, si les hooks sont lancés par un shell de connexion. Je n'ai pas vérifié quel mode de shell Claude Code utilise.

Les limites : des mesures uniques, aucune comparaison à un moment calme, et les trois hooks lancés l'un après l'autre alors que Claude Code les lance ensemble. L'écart entre `python3` et `python` repose sur une mesure chacun, sous une charge variable. Dans les termes du [format d'observation ci-dessus](#2026-09-26--un-format-dobservation-pour-les-modèles-les-skills-et-les-sous-agents), c'est un échec d'**environnement**, pas un échec du modèle.

**Rien n'a été modifié.** Le plugin a des interrupteurs (`OCTO_DONE_CRITERIA=off`, `OCTOPUS_GITHUB_WORK_QUEUE=off`) ; les activer est un changement de configuration qui demande l'accord de l'utilisateur. Relever les délais cacherait la latence et ajouterait des secondes à chaque prompt.

Une idée de correctif amont reste un brouillon, non testé et non envoyé :
- lire stdin avec une commande interne de bash ;
- faire un seul appel à `jq` au lieu de plusieurs appels à `python3` ;
- sortir avant de lancer `git` hors du dépôt du plugin.

## 2026-09-27 — Après un plantage de wmux : repris n'est pas livré

*Observation rétrospective.* Les preuves sont la note de reprise du coordinateur, conservée localement, et ce que cette session a vu d'elle-même. Les identifiants de sessions et de surfaces sont omis.

- **Ce qui s'est passé.** Le multiplexeur de terminal qui héberge les panneaux des agents (wmux) a planté. Avec l'autorisation de l'utilisateur, le coordinateur :
  - a relancé la version 1.1.1, qui s'est fermée pendant sa propre mise à jour sans créer d'agent ;
  - a ensuite vu la 2.13.1, que l'utilisateur a installée, répondre et restaurer ses espaces de travail ;
  - a repris six voies (IX, Learn, TARS, Demerzel, Gaia, Music) par leurs conversations historiques exactes.
  Il n'y a eu ni redémarrage, ni remise à zéro de données, ni contournement de permission, ni modification de dépôt, ni redémarrage de serveur, ni appel payant.
- **« Repris » est un état de l'interface, pas une livraison.** La note de reprise consigne, pour chaque voie, ce qui a été observé : un récapitulatif repris, un diff antérieur, un prompt. Sa propre règle est que *« agent labels/running alone are not delivery evidence »* (une étiquette d'agent ou un agent qui tourne ne prouvent pas une livraison). Dans les états du [format d'observation](#2026-09-26--un-format-dobservation-pour-les-modèles-les-skills-et-les-sous-agents), un panneau repris est *visible*. Il devient *accepté* quand la voie accuse réception d'une tâche, et *terminé* seulement avec un reçu.
- **Ce qui a rendu la reprise peu coûteuse.** Chaque voie avait écrit son état dans des fichiers avant le plantage, pas seulement dans sa conversation. Ces fichiers nommaient la checkout exacte, la tête et les chemins non commités, et donnaient l'action suivante.
  - Cette session Learn a repris depuis un tel fichier. Elle a ensuite attendu l'autorité de publication, comme le fichier le disait, au lieu d'agir d'après son récapitulatif.
  - La voie IX a trouvé de la même façon une modification de workflow non commitée, dont le commit et le push avaient été coupés par le plantage. Elle a demandé à l'utilisateur avant de la pousser.
  - Un résumé de conversation ne suffit pas pour cela. Il dit ce qui était prévu, pas quelle commande a réellement tourné.
- **Les identifiants ont changé.** Les identifiants d'espaces de travail et de surfaces étaient nouveaux après le redémarrage, donc tout moniteur devait relire la correspondance avant d'envoyer des touches à un panneau. C'est un échec d'orchestration en puissance, et ici il a été évité.

## 2026-09-27 — GA #740 fusionnée avant sa revue indépendante

*Observation rétrospective*, consignée avec le format d'observation. Les faits publics ont été lus avec `gh`. Le reste vient de reçus locaux — ceux de la voie IX, du coordinateur et de la revue post-fusion — que ce cours a lus sans les réexécuter.

| Champ | Observation |
|---|---|
| Dépôt | [GuitarAlchemist/ga#740](https://github.com/GuitarAlchemist/ga/pull/740), *éditeur de pipelines : thème du système, contrôle des types d'arguments, pipeline d'exemple GA*. Fusionnée le 2026-09-27T02:50:43Z en [`d67d04b`](https://github.com/GuitarAlchemist/ga/commit/d67d04bdb04742ba338518e28197e6035cb80e90). La tête fusionnée, [`984192e`](https://github.com/GuitarAlchemist/ga/commit/984192e970746dbed9e56255616360f56d9eed62), était épinglée avec `--match-head-commit` |
| Rôles | La session d'agent IX en était l'autrice, et elle a fusionné avec les identifiants du propriétaire du dépôt. Codex devait être l'intégrateur, après une revue indépendante de cette tête exacte |
| Ce qui s'est mal passé | Le tour de l'utilisateur « pousse tout ce qui est green » est arrivé en premier à la session autrice, qui l'a lu comme une autorité de fusion pour les PR au vert. Elle a vérifié les commentaires du bot Codex (aucun P0/P1 ouvert à cette tête) et une CI au vert, puis a fusionné. La consigne selon laquelle Codex devait revoir la tête avant toute fusion est arrivée après la fusion |
| Catégorie d'échec | **Orchestration ou propriété** : deux consignes d'autorités différentes ont atteint un même agent dans le mauvais ordre. Aucun outil n'a échoué et aucune étape de raisonnement n'était fausse au vu de ce que l'agent avait vu, mais la barrière n'a pas joué |
| Preuves au moment de la fusion | Publiques : tous les checks GitHub de la PR passent. Rapporté par Codex après la fusion : synchronisation du thème généré vérifiée, et trois suites de tests ciblées, 35 sur 35 réussies. Ce n'est pas une couverture complète HTTP, navigateur, build ou backend |
| Revue post-fusion | En lecture seule, par une session distincte, avec un reçu conservé localement ; ce cours ne l'a pas réexécutée. Elle a confirmé, chaque fois avec un cas d'échec reproduit : les routes de propositions ajoutées par la PR admettent plus que leur plafond quand les corps arrivent tard (29 en attente pour 20, alors que des envois en série le respectent) ; des clics simultanés franchissent le plafond de dépenses du conseiller (8 appels admis là où un seul tenait, API simulée, aucune dépense ; des appels en série le respectent) ; un corps mal formé reçoit un « invalid JSON body » trompeur ; une ligne corrompue du registre lève une exception hors de tout `try`. D'après le source : une proposition sans révision de base est traitée comme à jour. La description de la PR ne mentionne ni l'API payante du conseiller ni les routes de propositions où les agents peuvent écrire. Les barrières manuelles Accept et Run tiennent, et la revue n'indique aucun revert |
| État | La fusion est *terminée*, et la revue aussi. Un correctif des cinq constats sur le code est *soumis* à Codex : une branche locale, non commitée, avec d'abord un test qui échoue pour chacun (5 échecs avant le correctif, et 42 sur 42 réussis après, dans 4 fichiers). Codex a réexécuté ces 4 fichiers : 42 sur 42. Le correctif n'est pas intégré, et il reste sa revue complète, une vérification dans un navigateur et un build complet. Aucun défaut n'est donc encore corrigé sur `main` |
| Réponse | Aucun revert. L'intégration reste à Codex. Les limites que le correctif nomme lui-même restent ouvertes : deux serveurs de développement qui partagent un registre peuvent encore entrer en concurrence, le contrôle de dépense repose sur une estimation et non sur une borne supérieure garantie, et les corps de requête au-delà de la taille limite sont toujours gardés en mémoire, comme avant la PR |
| Suite | La décision de Codex sur le correctif, puis sa PR et sa CI, puis le statut de cette entrée |

## À vérifier

- Appliquer le format d'observation à une seconde délégation indépendante, et faire vérifier une fiche contre sa preuve par quelqu'un d'autre que son auteur.
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
- Les dépassements de délai des hooks : trois exécutions de chaque hook à un moment calme et trois sous charge, les trois hooks lancés ensemble comme Claude Code les lance, et si Claude Code lance les hooks par un shell de connexion.
- GA #740 : si le correctif des cinq constats de la revue sur le code arrive sur `main` avec ses tests de régression, et une vérification de l'éditeur dans un navigateur, que ni la revue ni le correctif n'ont faite.
