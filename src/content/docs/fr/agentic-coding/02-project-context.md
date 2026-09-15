---
title: "2. Le contexte du projet : CLAUDE.md, AGENTS.md, mémoire et compaction"
description: Ce qu'un agent sait de ton dépôt avant son premier appel d'outil — CLAUDE.md pour Claude Code, AGENTS.md pour Codex, et comment un même dépôt sert les deux — puis la mémoire automatique, la compaction, et pourquoi un fichier d'instructions guide le modèle sans rien imposer. Avec l'historique réel de l'AGENTS.md de ce site et le script de synchronisation de GuitarAlchemist/ga.
sidebar:
  order: 2
---

Chaque session commence avec une fenêtre de contexte vide : le modèle ne se souvient de rien de la veille. Ce qu'il sait de ton projet avant son premier appel d'outil vient de fichiers que le programme de l'agent charge pour lui. Dans une solution .NET, tu as déjà de tels fichiers pour des outils : `.editorconfig` pour le formateur, `Directory.Build.props` pour MSBuild. La différence, c'est que ceux-là sont analysés et appliqués ; un fichier d'instructions pour un agent est **du texte donné à un modèle**.

## Deux noms de fichier, une même convention

- [Claude Code](https://code.claude.com/docs/en/memory) lit `CLAUDE.md`, dans le répertoire de travail et dans chaque répertoire au-dessus, plus `CLAUDE.local.md` pour des notes personnelles que tu ne commites pas, et `~/.claude/CLAUDE.md` pour tous tes projets. Les fichiers des sous-répertoires se chargent plus tard, quand Claude y lit des fichiers.
- [Codex](https://learn.chatgpt.com/docs/agent-configuration/agents-md) lit `AGENTS.md` : d'abord `~/.codex/AGENTS.md`, puis un fichier par répertoire, de la racine du projet (en général la racine Git) jusqu'au répertoire de travail, `AGENTS.override.md` ayant la priorité dans son répertoire. Il les concatène, la racine en premier, et « cesse d'ajouter des fichiers une fois que la taille cumulée atteint la limite définie par `project_doc_max_bytes` (32 Kio par défaut) ».

Les deux concatènent au lieu de remplacer : le fichier le plus proche de l'endroit où tu as démarré vient en dernier, et le modèle est censé lui donner la priorité. Rien ne garantit qu'il le fasse.

La documentation est explicite sur ce décalage : « Claude Code lit `CLAUDE.md`, pas `AGENTS.md`. » Pour un dépôt utilisé avec les deux agents, elle suggère un `CLAUDE.md` qui importe `AGENTS.md` :

```markdown
@AGENTS.md
```

Les imports `@path` sont développés au démarrage de la session, relativement au fichier qui importe, jusqu'à quatre niveaux de profondeur. Un lien symbolique fonctionne aussi sous Linux et macOS ; « sous Windows, créer un lien symbolique demande les droits d'administrateur ou le mode développeur : utilise plutôt l'import `@AGENTS.md` ».

### Une expérience : Claude Code lit-il AGENTS.md ?

Deux répertoires vides, chacun avec le même `AGENTS.md` :

```markdown
# Project rules

- The release codename of this project is HEDGEHOG-42.
```

Le second a aussi un `CLAUDE.md` qui ne contient que `@AGENTS.md`. La même question dans les deux, avec tous les outils retirés (`--tools ""`) pour que le modèle ne puisse pas aller lire le fichier lui-même, le 2026-09-14 à 22:37 UTC, Claude Code 2.1.271 :

```bash
claude -p "What is the release codename of this project? Answer with the codename only, or UNKNOWN if your instructions don't say." --tools "" --output-format json
```

| Répertoire | `result` | `num_turns` |
|---|---|---|
| `AGENTS.md` seul | `UNKNOWN` | 1 |
| `AGENTS.md` et `CLAUDE.md` = `@AGENTS.md` | `HEDGEHOG-42` | 1 |

Un tour chacun : aucun appel d'outil, la réponse vient de ce qui était chargé avant le premier tour. Avec des outils, le premier modèle aurait pu trouver `AGENTS.md` en listant le répertoire ; ce serait un fichier qu'il a lu, pas une instruction qu'on lui a donnée, et cela n'arriverait que si le modèle pensait à regarder. Le côté Codex de l'expérience, le même `AGENTS.md` sans `CLAUDE.md`, est *à vérifier* : le compte a atteint sa limite d'utilisation (voir la [leçon 1](../01-agents-and-permissions/)).

## Un cas réel : l'AGENTS.md de ce site

Ce dépôt a un `AGENTS.md` de 38 lignes (4 696 octets, bien en dessous des 32 Kio de Codex) et un `CLAUDE.md` de 11 octets : `@AGENTS.md`. Son historique est celui des erreurs que les agents ont commises ici. `git log --format="%h %ad %s" --date=short -- AGENTS.md` :

```text
1b108b9 2026-09-14 Render Mermaid diagrams, first one in LadybugDB lesson 8 (en, fr, es)
d32b186 2026-09-13 Java lessons 5-8 and a Spanish locale for the whole site
9849105 2026-09-13 Rust course: lessons 13-15, OS tabs, reference links, French mirror
1faa32e 2026-09-13 Add an Artifacts page listing shared Claude artifacts
6145ed7 2026-09-13 Split Software Engineering into sub-areas
95a42da 2026-09-13 Group courses under a Software Engineering area
a79c0bc 2026-09-13 Add Rust for C#/Java developers course, lessons 1-4
f43ba7e 2026-09-13 Import Streeling University modules from Demerzel
eda2608 2026-09-13 Initial learn site: Starlight, bilingual en/fr, WSL containers course
```

Lis les règles comme des rapports de bug :

- [Ligne 8](https://github.com/spareilleux/learn/blob/1b108b961b0975b51b00c7fa2e75672c96190d7f/AGENTS.md?plain=1#L8), depuis `f43ba7e` : les pages Streeling sont générées, « ne les modifie jamais à la main ; change plutôt le script ». Un agent à qui l'on demande de corriger une coquille corrige le fichier qu'il a sous les yeux ; la synchronisation suivante l'annulerait sans bruit.
- [Ligne 13](https://github.com/spareilleux/learn/blob/1b108b961b0975b51b00c7fa2e75672c96190d7f/AGENTS.md?plain=1#L13), depuis `1faa32e` : pas de `{`, `}` ou `<` nus dans la prose `.mdx`. MDX les analyse comme du JSX et le build échoue.
- [Ligne 15](https://github.com/spareilleux/learn/blob/1b108b961b0975b51b00c7fa2e75672c96190d7f/AGENTS.md?plain=1#L15), depuis `1faa32e` : « Ce dépôt est partagé par plusieurs sessions : n'indexe que des chemins explicites, juste avant de commiter ». Plusieurs sessions d'agent travaillent ici en parallèle ; un `git add -A` dans l'une d'elles commite la leçon à moitié écrite d'une autre session.
- La [ligne 5](https://github.com/spareilleux/learn/blob/1b108b961b0975b51b00c7fa2e75672c96190d7f/AGENTS.md?plain=1#L5) a changé trois fois en deux jours (`95a42da`, `6145ed7`, `d32b186`), à chaque changement de structure du site. Un fichier d'instructions décrit une base de code ; quand la base de code bouge, le fichier doit bouger avec elle, sinon il induit en erreur.

Deux pratiques en découlent. Écris des règles qui disent **pourquoi** en quelques mots, pour que le modèle puisse les appliquer à un cas que tu n'as pas prévu. Et garde le fichier court : « vise moins de 200 lignes par fichier CLAUDE.md. Les fichiers plus longs consomment plus de contexte et réduisent l'adhésion » ([mémoire](https://code.claude.com/docs/en/memory)). Les lignes 17 à 38, sur le serveur de développement Astro et les liens de documentation, sont arrivées avec le commit initial et n'ont jamais changé.

## Une autre stratégie : GuitarAlchemist/ga copie

[GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) fait le choix inverse : `CLAUDE.md` est la source, 192 lignes et 15 773 octets, et `AGENTS.md` est une copie générée. [`Scripts/sync-agents-md.ps1`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Scripts/sync-agents-md.ps1#L38-L41) remplace le titre et la note qui indique quel fichier modifier :

```powershell
$agentsContent = $claudeContent `
    -replace '^# CLAUDE\.md', '# AGENTS.md' `
    -replace 'Edit `CLAUDE\.md`; never edit `AGENTS\.md` directly\.', 'Source of truth is `CLAUDE.md`. This file is auto-generated — do not edit directly.'
```

Le [hook Git pre-commit](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.githooks/pre-commit.ps1#L196-L229) le lance avant chaque commit, réindexe `AGENTS.md` s'il a changé, et saute la synchronisation pendant un merge, un rebase ou un cherry-pick, pour ne pas écraser une résolution de conflit. Le script a aussi une option `-CheckOnly` pour la CI.

| | Ce site : import `@AGENTS.md` | ga : copie générée |
|---|---|---|
| Source de vérité | `AGENTS.md` | `CLAUDE.md` |
| Octets dupliqués | aucun | le fichier entier |
| Peut diverger | non | oui, si le hook Git n'est pas installé (`pwsh Scripts/install-git-hooks.ps1`) |
| Imports `@path` | seulement dans `CLAUDE.md`, que Codex ne lit pas | n'atteindraient que Claude : la documentation de Codex ne décrit pas les imports (*à vérifier*) |
| Un agent modifie le mauvais fichier | une règle ajoutée à `CLAUDE.md` n'atteint que Claude | une règle ajoutée à `AGENTS.md` est écrasée au commit suivant |

La lecture du `CLAUDE.md` de ga montre deux autres choses. Il nomme la version de l'extension Claude Code qu'utilisait son auteur, [`anthropic.claude-code-2.1.126`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/CLAUDE.md?plain=1#L68), 145 versions de correctif avant celle de cette leçon : les faits des fichiers d'instructions vieillissent. Et sa section [*Session-learned rules*](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/CLAUDE.md?plain=1#L134-L152) est complétée par une commande personnalisée `/correct` quand l'utilisateur corrige l'agent, chaque règle avec un **Why** et un **How to apply**, et les corrections encadrées dans des blocs `untrusted-correction` : le fichier est à la fois des instructions et un journal.

## La mémoire automatique

Claude Code a un second mécanisme, la [mémoire automatique](https://code.claude.com/docs/en/memory#auto-memory) (*auto memory*) : des notes que **Claude** écrit quand tu le corriges ou quand il apprend quelque chose que le code ne dit pas, dans `~/.claude/projects/<project>/memory/`, un répertoire par dépôt Git, partagé par ses worktrees, jamais partagé entre machines. « Les 200 premières lignes de `MEMORY.md`, ou ses 25 premiers Ko, selon la limite atteinte en premier, sont chargées au début de chaque conversation » ; `MEMORY.md` est un index qui pointe vers des fichiers thématiques que Claude lit au besoin. `/memory` ouvre ces fichiers ; ce sont de simples fichiers Markdown que tu peux modifier ou supprimer.

| | `CLAUDE.md` / `AGENTS.md` | Mémoire automatique |
|---|---|---|
| Écrit par | toi, relu dans les pull requests | l'agent |
| Partagé | avec tous ceux qui clonent le dépôt | non, local à ta machine |
| Bon pour | les règles que toute l'équipe doit suivre | tes préférences, ce que tu as corrigé |

Codex a un équivalent, [Memories](https://learn.chatgpt.com/docs/customization/memories), expérimental et désactivé par défaut dans sa référence de configuration, avec le même conseil : « Garde les consignes d'équipe obligatoires dans `AGENTS.md` ou dans une documentation versionnée. Traite les mémoires comme une couche de rappel utile, pas comme la seule source des règles qui doivent toujours s'appliquer. »

## La compaction

Une longue session remplit la fenêtre de contexte. Les deux agents **compactent** alors : ils remplacent la conversation par un résumé écrit par le modèle, automatiquement près de la limite ou quand tu tapes `/compact` ([Claude Code](https://code.claude.com/docs/en/context-window#what-survives-compaction), [Codex](https://learn.chatgpt.com/docs/developer-commands)). `/compact focus on the failing test` indique à Claude ce que le résumé doit garder.

Ce qui survit dans Claude Code, d'après sa documentation :

| Contenu | Après la compaction |
|---|---|
| `CLAUDE.md` à la racine du projet, règles sans portée, mémoire automatique | réinjectés depuis le disque |
| Fichiers `CLAUDE.md` imbriqués et règles limitées à des chemins | rechargés quand Claude lit un fichier correspondant |
| Fichiers que Claude a lus ou modifiés | jusqu'à cinq relus, les plus récemment modifiés d'abord |
| Skills invoqués | réinjectés, jusqu'à 5 000 tokens chacun et 25 000 au total |
| Instructions que tu as tapées dans la conversation | seulement ce que le résumé a gardé |

La dernière ligne est la plus concrète : **une règle donnée dans le chat peut disparaître à la compaction ; une règle dans `CLAUDE.md` revient.**

Cette leçon a été écrite dans une session qui a compacté, à 22:32 UTC le 2026-09-14, sur Claude Code 2.1.270 (la mise à jour en 2.1.271 s'applique au démarrage suivant). La transcription de la session, un fichier JSONL sous `~/.claude/projects/`, montre que le résumé avait des sections nommées comme le dit la documentation : les demandes, les concepts techniques clés, les fichiers et le code, les erreurs et leurs corrections, les tâches en attente, le travail en cours. Elle montre aussi une chose à laquelle le tableau ci-dessus ne prépare pas. Les instructions injectées juste après la compaction étaient **l'`AGENTS.md` du début de la session, à 20:56 UTC, sans la règle Mermaid commitée à 22:01**, alors que le fichier sur disque la contenait. Le fichier à jour est bien arrivé, mais 34 minutes plus tard, à 23:06 UTC, avec le message suivant que la session a reçu, sous forme d'un rappel indiquant que « instruction files were re-read after the conversation was compacted; these differ from their earlier copies ». Entre-temps, les instructions présentes dans le contexte de l'agent n'avaient pas la règle. Pourquoi la relecture est arrivée tard, et si l'import `@AGENTS.md` y joue un rôle, est *à vérifier* ; le [journal](../journal/) garde les détails. La leçon ne dépend pas de la cause : après une longue session, ne suppose pas que l'agent a vu une modification de ses fichiers d'instructions. Démarre une nouvelle session.

`/context` montre ce qui remplit la fenêtre à cet instant, y compris quels fichiers de mémoire ont été chargés ; `/clear` repart de zéro entre des tâches sans rapport, ce qui vaut souvent mieux que compacter.

## Guider n'est pas imposer

Chaque mécanisme de cette leçon est du texte dans la fenêtre de contexte. La documentation de Claude Code le dit clairement : « Claude les traite comme du contexte, pas comme une configuration imposée. Pour bloquer une action quoi que décide Claude, utilise plutôt un hook PreToolUse », et `CLAUDE.md` « est transmis comme un message utilisateur après le prompt système », sans « aucune garantie de respect strict ».

La ligne 15 de l'`AGENTS.md` de ce site demande aux agents d'indexer des chemins explicites. C'est une bonne instruction, et les agents d'ici la suivent la plupart du temps. Mais la machine sur laquelle ce site est écrit a aussi un hook qui refuse les commandes `git push` dangereuses avant qu'elles ne s'exécutent, quoi qu'ait décidé le modèle. Les instructions réduisent la fréquence à laquelle l'agent tente quelque chose ; les hooks, les permissions et la CI décident de ce qui se passe quand il le fait. La [leçon 3](../03-hooks-skills-subagents/) en écrit un.

Une règle empirique pour chaque instruction que tu t'apprêtes à ajouter :

| Si enfreindre la règle… | Mets-la dans |
|---|---|
| dégrade le résultat mais est sans danger | `CLAUDE.md` / `AGENTS.md` |
| ne doit jamais arriver | une règle de permission, un hook ou le bac à sable, et la raison dans `AGENTS.md` |
| peut être détecté après coup | la CI, et la commande pour la lancer en local dans `AGENTS.md` |

## À retenir

- Claude Code lit `CLAUDE.md` ; Codex lit `AGENTS.md`. Un `CLAUDE.md` contenant `@AGENTS.md` sert les deux à partir d'un seul fichier ; une copie générée fonctionne aussi, si quelque chose la garde synchronisée.
- Les fichiers d'instructions sont concaténés de la racine vers le bas, chargés avant le premier tour, et Codex s'arrête à 32 Kio par défaut.
- Traite ton fichier d'instructions comme du code : court, relu, avec la raison de chaque règle, et mis à jour quand le projet change.
- La mémoire automatique est locale et écrite par l'agent ; les règles d'équipe ont leur place dans le dépôt.
- La compaction garde les fichiers d'instructions et résume la conversation : mets les instructions durables dans des fichiers, et démarre une nouvelle session après les avoir modifiés.
- Les instructions guident ; les permissions, les hooks, les bacs à sable et la CI imposent.

## Exercices

1. Le dépôt d'un collègue n'a qu'un `CLAUDE.md` de 300 lignes, et il veut maintenant essayer Codex sans rien renommer. Quel est le plus petit changement, et quels deux problèmes restent ?

<details>
<summary>Solution</summary>

Dans `~/.codex/config.toml`, ajoute `project_doc_fallback_filenames = ["CLAUDE.md"]` : Codex vérifie alors `AGENTS.override.md`, `AGENTS.md`, puis `CLAUDE.md` dans chaque répertoire, au plus un fichier par répertoire ([AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)). Deux problèmes restent. Si le `CLAUDE.md` utilise des imports `@path`, la documentation de Codex ne dit rien de leur développement : attends-toi à ce que Codex voie le texte littéral `@docs/testing.md` (*à vérifier*). Et le paramètre se trouve dans la configuration de chaque utilisateur, donc chaque collègue doit le répéter (si le `.codex/config.toml` d'un projet l'accepte est *à vérifier*). Un `AGENTS.md` commité, avec `CLAUDE.md` réduit à `@AGENTS.md`, évite les deux, et 300 lignes sont de toute façon le signe que le fichier devrait être découpé.

</details>

2. Classe ces instructions de l'`AGENTS.md` de ce site en « fichier d'instructions », « imposer » ou « détecter en CI », et dis avec quoi : (a) « utilise des liens relatifs en Markdown, jamais de liens absolus depuis la racine `/…` » ; (b) « n'indexe que des chemins explicites » ; (c) « ne modifie jamais `streeling/` à la main » ; (d) « Relie la première mention, dans chaque leçon, d'un outil … à sa documentation officielle ».

<details>
<summary>Solution</summary>

(a) Détecter : un vérificateur de liens sur le site généré, ou un `grep` de `](/` dans `src/content/docs` en CI. (b) Imposer, en partie : un hook PreToolUse peut refuser `git add -A`, `git add .` et `git commit -a`, mais il ne peut pas savoir quels chemins appartiennent à une autre session ; l'instruction reste. (c) Détecter : la CI lance `npm run sync:streeling` et échoue si `git diff` n'est pas vide ; un hook refusant `Edit` sur `src/content/docs/**/streeling/**` fonctionnerait aussi, avec une règle deny `Edit(./src/content/docs/**/streeling/**)` comme option la plus simple. (d) Fichier d'instructions : « la première mention d'un outil » est un jugement qu'un script ne peut pas porter de façon fiable ; une vérification en CI peut au moins contrôler que les liens aboutissent.

</details>

3. Dans une longue session, tu as dit à l'agent « désormais, lance `dotnet test --filter Category!=Slow` au lieu de `dotnet test` ». Deux heures plus tard, il relance toute la suite. Donne deux explications et un correctif pour chacune.

<details>
<summary>Solution</summary>

La session a compacté et le résumé n'a pas gardé ta phrase : les instructions données seulement dans la conversation sont résumées avec tout le reste. Correctif : mets-la dans `CLAUDE.md` ou `AGENTS.md`, qui reviennent après la compaction, ou dans un fichier `.claude/rules/`. Ou bien le modèle l'a vue et ne l'a pas suivie, par exemple parce que le fichier d'instructions dit « lance `dotnet test` avant de commiter » et que les deux se contredisent : corrige le fichier pour qu'il n'y ait qu'une règle. Si lancer les tests lents est vraiment nuisible, aucun des deux correctifs n'est une garantie : un hook PreToolUse qui refuse `dotnet test` sans `--filter`, si.

</details>

## Sources

- Claude Code : [mémoire](https://code.claude.com/docs/en/memory), [fenêtre de contexte](https://code.claude.com/docs/en/context-window), [comment fonctionne Claude Code](https://code.claude.com/docs/en/how-claude-code-works)
- Codex : [AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md), [configuration avancée](https://learn.chatgpt.com/docs/config-file/config-advanced), [mémoires](https://learn.chatgpt.com/docs/customization/memories), [commandes slash](https://learn.chatgpt.com/docs/developer-commands)
- [agents.md](https://agents.md/), le site de la convention `AGENTS.md`
