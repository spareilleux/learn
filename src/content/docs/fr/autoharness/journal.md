---
title: Journal
description: Notes datées du cours AutoHarness — le commit épinglé, une lecture statique du plugin, six fixtures préinscrites exécutées en isolation, les défauts qu'elles ont reproduits, les bugs du harnais lui-même, le verdict et ce qui reste à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] AutoHarness épinglé à `ca39a72`, lu statiquement : événements du cycle de vie, métrique d'usage, propriété, robustesse, autorité, coûts, tests ; 14 hypothèses écrites
- [x] Six fixtures préinscrites, puis exécutées dans des sous-processus isolés sans modèle ni installation : `code/autoharness/fixtures.py`, haché avant la première exécution
- [x] Évaluation écrite, avec les preuves séparées des affirmations : [`evaluation.md`](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/evaluation.md), verdict **ne pas adopter** à `ca39a72`
- [x] Leçon 1 : un labo de fixtures, six promesses testées sans installer
- [ ] Leçon 2 : la boucle et ses frontières d'autorité (H4, H12, H14)
- [ ] Leçon 3 : pourquoi l'usage n'est pas la qualité — compteurs, maturité, capacité (H1, H5)
- [ ] Leçon 4 : plantages, concurrence et historique (H8, H9, H11)
- [ ] Leçon 5 : l'évaluation et une liste de contrôle d'adoption
- [ ] Les fixtures sous Linux et macOS

## QA

Chaque ligne est reproduite par [`fixtures.py`](https://github.com/spareilleux/learn/blob/main/code/autoharness/fixtures.py) ou [`redact_probe.py`](https://github.com/spareilleux/learn/blob/main/code/autoharness/redact_probe.py) au commit `ca39a72` sous Windows 11 avec Python 3.14.2, avec des entrées synthétiques, sauf quand l'état dit *lu*. Rien n'a encore été signalé en amont ; c'est une décision à part.

| Attendu | Ce qui se passe | Où | Mesure | État |
|---|---|---|---|---|
| Les skills écrits à la main ne sont jamais touchés (README, lignes 10, 23 et 229-230) | Un `create` portant le nom d'un skill écrit à la main remplace son corps, ne garde aucune copie et marque le skill comme celui de l'agent. Un `update` du même skill est refusé | [`promoter.py#L51-L53`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/hook/promoter.py#L51-L53), [`#L158`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/hook/promoter.py#L158), [`#L129-L133`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/hook/promoter.py#L129-L133) | F1 : `sentinel_survives: false`, `agent_created_after: true`, `archived_copy: false` ; témoin `self_produced` | Reproduit, non signalé ([2026-09-26](#2026-09-26--six-fixtures-exécutées-en-isolation)) |
| Le balayage de démarrage retire les restes d'AutoHarness | Il supprime tous les `*.tmp` sous le dossier des skills, y compris le `draft.tmp` d'un utilisateur dans un skill écrit à la main, lors d'un vidage à vide | [`skill_store.py#L82-L90`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/skill_store.py#L82-L90) | F5 : `tmp_survives: false`, le témoin `draft.txt` survit | Reproduit, non signalé ([2026-09-26](#2026-09-26--six-fixtures-exécutées-en-isolation)) |
| Une ligne invalide dans la file d'intentions coûte cette ligne | Une seule ligne tronquée fait lever `JSONDecodeError` à chaque vidage avant tout dépôt, et la file n'est jamais vidée | [`intent_queue.py#L29-L33`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/intent_queue.py#L29-L33), [`promoter.py#L231-L240`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/hook/promoter.py#L231-L240) | F2 : 2 vidages, 2 `JSONDecodeError`, 0 intention valide sur 2 déposée, `queue_left: true` ; le témoin en dépose 2 | Reproduit, non signalé ([2026-09-26](#2026-09-26--six-fixtures-exécutées-en-isolation)) |
| Les secrets sont masqués avant qu'une fenêtre n'atteigne le reflector | Une clé écrite en JSON, `{"api_key": "…"}`, et le corps d'une clé privée PEM passent ; `{"password": "…"}` aussi | [`redaction_rules.toml#L10-L11`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/redaction_rules.toml#L10-L11), [`#L25-L27`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/redaction_rules.toml#L25-L27) | F3 : le canari survit dans 2 formes sur 3 ; le témoin `api_key = …` est masqué. Sonde : le `password` JSON survit | Reproduit, non signalé ([2026-09-26](#2026-09-26--six-fixtures-exécutées-en-isolation)) |
| Un masquage dit quelle règle s'est déclenchée | Une étiquette peut être masquée à nouveau par `api_key_assignment`, parce qu'elle contient `secret:` : `[REDACTED:[REDACTED:secret:api_key_assignment]]` | [`redaction_rules.toml#L25-L27`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/redaction_rules.toml#L25-L27) | L'en-tête PEM de F3, et `Bearer …` dans la sonde | Reproduit, exploratoire (non préinscrit) |
| Les identifiants dans une URL sont masqués | Aucune règle ne les vise. Dans `postgres://admin:…@db.example.com/prod`, la règle email retire le mot de passe et l'hôte ensemble, par accident, et garde le nom d'utilisateur | [`redaction_rules.toml#L29-L31`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/redaction_rules.toml#L29-L31) | Sonde : `postgres://admin:[REDACTED:pii:email]/prod` | Reproduit, exploratoire |
| Un skill qu'AutoHarness écrit, il peut le relire | Sous Windows avec une locale cp1252, un corps non ASCII est écrit en UTF-8 et relu avec le codec de la locale : `UnicodeDecodeError` sur l'octet 0x81 | [`atomic.py#L31-L32`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/atomic.py#L31-L32), [`skill_store.py#L26-L28`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/skill_store.py#L26-L28) | F4 : l'exception est levée sans le mode UTF-8 ; le témoin `PYTHONUTF8=1` relit un contenu égal | Reproduit sous Windows seulement, que le badge de plateformes du README ne liste pas |
| Les skills écrits par l'outil portent *« a `self-authored` ledger marker »* (README, lignes 85-86) | La propriété est un `.sidecar.json` avec `"created_by": "agent"` ; le registre (*ledger*) n'est jamais consulté pour cela | [`sidecar.py#L47-L51`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/sidecar.py#L47-L51), [`#L75-L76`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/sidecar.py#L75-L76) | — | Lu dans le source, non exécuté ([2026-09-26](#2026-09-26--lire-le-source-épinglé)) |

## Expériences

Chaque hypothèse a été écrite dans [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/preregistration.md) avant la première exécution. Le fichier a été haché à 15:29:21 EDT (SHA-256 `b9dc7b7d…`), et les modifications faites après l'exécution sont listées à sa fin. Chaque fixture s'est exécutée dans un sous-processus neuf avec un environnement construit à partir de rien et un répertoire personnel jetable ; aucune n'a écrit dans ce répertoire, et le vrai `~/.claude/autoharness` était absent avant et après. La deuxième exécution est identique à la première.

| Question | Hypothèse (écrite avant l'exécution) | Résultat | Verdict | Entrée, code |
|---|---|---|---|---|
| F0 — Le harnais atteint-il le promoteur ? | Un `create` valide sur un nom nouveau est déposé, marqué `created_by: agent` | `ok: true`, `agent_created: true` | Témoin positif réussi | [2026-09-26](#2026-09-26--six-fixtures-exécutées-en-isolation), [`fixtures.py`](https://github.com/spareilleux/learn/blob/main/code/autoharness/fixtures.py) |
| F1 (H2) — `create` s'approprie-t-il un skill écrit à la main du même nom ? | Le contrôle de propriété ne couvre que `update`, `patch`, `remove_file` et `delete`, donc un `create` remplace le corps et s'approprie le skill ; le témoin `update` est refusé | Témoin : refusé, `self_produced`, corps inchangé. `create` : `ok`, sentinelle disparue, sidecar `agent`, aucune archive | Confirmée | [2026-09-26](#2026-09-26--six-fixtures-exécutées-en-isolation), [`fixtures-run.jsonl`](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/fixtures-run.jsonl) |
| F2 (H10) — Une ligne tronquée dans la file bloque-t-elle l'exécution ? | `read` analyse chaque ligne avant de promouvoir et `clear` vient en dernier, donc les deux vidages lèvent une exception et la file reste | Témoin : 2 déposées, puis 0, file vidée. Traitement : `JSONDecodeError` deux fois, 0 déposée, file restante | Confirmée | idem |
| F3 (H13) — Le masqueur attrape-t-il une clé JSON entre guillemets et un corps PEM ? | Non : la règle n'admet aucun guillemet avant les deux-points, et la règle PEM ne reconnaît que l'en-tête | Témoin masqué ; le canari survit dans `json_quoted` et dans `pem` | Confirmée | idem |
| F4 (nouvelle) — Un skill non ASCII survit-il à un aller-retour sous Windows ? | Non : écrit en UTF-8, lu en cp1252, `UnicodeDecodeError` à 0x81 ; le témoin `PYTHONUTF8=1` le relit à l'identique | Exactement cela | Confirmée, Windows seulement | idem |
| F5 (H3) — Le balayage supprime-t-il le `*.tmp` d'un utilisateur ? | Oui : tous les `*.tmp` sous le dossier des skills, quel qu'en soit l'auteur ; le témoin `draft.txt` survit | `draft.tmp` supprimé ; `draft.txt` et `SKILL.md` intacts | Confirmée | idem |

## 2026-09-26 — Lire le source épinglé

Le brief a épinglé [`ca39a72`](https://github.com/tigerless-labs/autoharness/tree/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b), la tête de `main` le 2026-09-25 : 71 fichiers suivis, environ 7 000 lignes, licence MIT. Aucun code n'en a été exécuté pendant cette lecture.

Ce que montre le source, dans l'ordre que suit l'évaluation :
- **La boucle tourne sans personne.**
  - Quatre hooks appellent un même répartiteur.
  - Tous les 50 appels d'outil, et en fin de session, un `claude -p --agent autoharness:reflector --dangerously-skip-permissions` en arrière-plan sur Haiku lit une fenêtre masquée et met des intentions en file par un outil MCP.
  - Le promoteur les dépose après la fin de chaque reflector et à chaque `Stop` de la session principale.
- **La propriété est un simple fichier JSON.** Un `.sidecar.json` avec `"created_by": "agent"` marque un skill comme celui de l'agent. Le README parle d'un marqueur dans le registre ; le registre n'y joue aucun rôle.
- **Aucun verrou nulle part.** Des commentaires de quatre modules les remettent à plus tard.
- **L'index n'est pas borné par les réglages de capacité.** Les skills en période probatoire, et les skills lus mais jamais invoqués, sont hors du groupe plafonné mais reçoivent quand même une ligne d'index.
- **Le masqueur compte dix expressions régulières.** Aucune ne vise les clés `sk-ant-`, les JWT ni les identifiants dans une URL.
- **Le *42% → 78% on CORE-Bench* du README** est attribué à l'[article HAL](https://arxiv.org/abs/2510.11977). Le dépôt ne contient aucun code de benchmark, et son README dit que le projet est validé *« in use, not on a benchmark »* (à l'usage, pas sur un benchmark). Les dossiers `experiments/` et `docs/plans/` que citent le README et des commentaires ne sont pas dans l'arbre à ce commit.

Quatorze hypothèses sont sorties de cette lecture, H1 à H14. Celles qui ne demandent ni modèle ni hook étaient candidates pour des fixtures ; les autres sont listées au §2 de l'évaluation, pour des leçons ultérieures.

Les tests amont n'utilisent ni réseau ni modèle : `claude` y est toujours remplacé par un faux. Deux demandent de la prudence :
- `test_layer.py` lit le vrai répertoire personnel et lance `git` dans le vrai répertoire de travail ;
- `test_spawn.py` a besoin d'un shebang POSIX.

Je n'ai pas exécuté la suite amont.

## 2026-09-26 — Six fixtures, exécutées en isolation

La préinscription a été hachée à 15:29:21 EDT. Deux minutes plus tard, le harnais a exécuté chaque fixture dans son propre sous-processus :
- un environnement construit à partir de rien : `PATH` limité au dossier de l'interpréteur, `PYTHONPATH` sur le clone, et `HOME`, `USERPROFILE`, `TEMP` et `TMP` dans un dossier jetable ;
- des racines de skills explicites pour chaque appel ;
- aucun import du module qui lance `claude`.

L'exécution a pris 14 secondes sous Windows 11 avec Python 3.14.2 (encodage de la locale : cp1252).

Cinq hypothèses ont été **confirmées**, chacune face à un témoin qui s'est comporté comme prévu, et le témoin positif a réussi. Le détail est dans la [leçon 1](../01-fixture-lab/). En bref :
- un `create` s'approprie un skill écrit à la main (F1) ;
- une ligne invalide dans la file arrête la promotion (F2) ;
- les clés JSON et les corps PEM échappent au masqueur (F3) ;
- un skill non ASCII ne peut pas être relu sous Windows (F4) ;
- un vidage à vide supprime le `*.tmp` d'un utilisateur (F5).

**Exploratoire, non préinscrit :**
- Une étiquette de masquage peut être masquée à nouveau, ce qui perd le nom de la règle qui s'est déclenchée en premier.
- Une sonde du masqueur a trouvé que `{"password": "…"}` survit, et qu'un mot de passe dans une URL ne disparaît que parce que la règle email reconnaît par hasard `password@host`.

Les deux sont dans la table QA, marqués exploratoires.

Le harnais avait lui-même le bug de F4. Son stdout redirigé utilisait cp1252, ce qui a déformé une chaîne à l'affichage de la première exécution. C'est corrigé avec `sys.stdout.reconfigure(encoding="utf-8")` et consigné comme modification post-mesure 1. La deuxième exécution se décode en les mêmes huit lignes.

**Verdict : ne pas adopter à `ca39a72`,** ni dans de vraies sessions Claude Code ni dans un vrai répertoire personnel. Les raisons sont mesurées, pas lues : F1 et F5 cassent la promesse centrale, F2 arrête la boucle, et F3 laisse fuir. Les corrections semblent petites :
- une vérification d'existence pour `create` ;
- un balayage limité aux noms temporaires d'AutoHarness ;
- une gestion d'erreur ligne par ligne ;
- les clés entre guillemets dans la règle.

L'[évaluation](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/evaluation.md) liste ce qui changerait le verdict. D'abord une version qui repasse ces fixtures, puis un pilote dans un répertoire personnel jetable avec un reflector factice ou au budget plafonné.

## 2026-09-26 — Un harnais qui sortait avec 0 sans avoir rien mesuré

À 23:20, les commandes du README du code ont été rejouées depuis un clone neuf, comme un lecteur les taperait, avec `--clone autoharness-ca39a72` en chemin relatif. Chaque enfant a échoué avec `ModuleNotFoundError` : `PYTHONPATH` était relatif, et le répertoire de travail de l'enfant est un dossier temporaire. Le parent a affiché les échecs comme des résultats et **est sorti avec 0**.

Les corrections :
- le chemin du clone est rendu absolu ;
- la ligne d'un enfant qui a planté nomme toujours sa fixture ;
- le parent sort avec 1 si un enfant sort avec un code non nul.

`redact_probe.py` a reçu la même correction de chemin. La nouvelle exécution, avec un chemin relatif puis absolu, est identique octet pour octet à la sortie enregistrée. Le chemin d'échec a été vérifié exprès : un clone inexistant donne maintenant `exit: 1`. C'est la modification post-mesure 3. Les résultats n'ont pas changé ; ce qui a changé, c'est qu'une exécution cassée ne peut plus passer pour une mesure.

## 2026-09-27 — Les pages du cours

La mission, la leçon 1 et ce journal ont été écrits en anglais, en français et en espagnol à partir des sorties enregistrées, et le cours a été ajouté à la barre latérale et aux pages d'accueil. `fixtures.py --hashes` a été relancé et a donné les six empreintes préinscrites. `redact_probe.py` règle maintenant `sys.dont_write_bytecode` avant d'importer `fixtures.py`, pour ne plus laisser de dossier `__pycache__` dans le répertoire du cours ; sa nouvelle exécution est identique octet pour octet à `redact-probe.jsonl`. Aucune fixture n'a été relancée, et aucun résultat n'a changé.

## À vérifier

- `fixtures.py` sous Linux et macOS : F0–F3 et F5 devraient donner les mêmes résultats, et F4 devrait relire un contenu égal avec une locale UTF-8.
- F4 sous Windows avec Python 3.15, où la [PEP 686](https://peps.python.org/pep-0686/) fait du mode UTF-8 le défaut.
- Les hypothèses pas encore exécutées :
  - H1 : l'index n'est pas borné par la capacité ;
  - H4 : un dépôt qui livre un `.sidecar.json` rend un skill « géré » ;
  - H5 : un seul sidecar mal formé arrête l'index pour une session ;
  - H8, H9 : une intention perdue entre la lecture et le vidage, et des fenêtres de réflexion qui se chevauchent ;
  - H11 : une seconde archive supprime la première ;
  - H12 : le transporteur *fork* laisse `Bash` disponible ;
  - H14 : un `interactive.jsonl` commité est vidé au premier `Stop`.
- Si `rglob("*.tmp")` descend dans un dossier de skill qui est un lien symbolique, ce qui dépend de la version de Python.
- La suite de tests amont, exécutée en isolation.

## Questions ouvertes

- À quelle fréquence le reflector proposerait-il un `create` dont le nom entre en collision avec un skill existant ? F1 montre que rien ne l'empêche ; seule une exécution avec un modèle, factice ou au budget plafonné, peut dire à quel point c'est probable.
- AutoHarness compte un skill comme *utilisé* quand le modèle appelle l'outil `Skill`, avant que l'appel ne soit autorisé ou exécuté. À quelle distance est-ce d'*utile*, et qu'est-ce que cela fait à un skill de sécurité rarement appelé ?
- Un journal tenu à la main et des skills mis à jour à la main, vérifiés sur des tests mis de côté, feraient-ils aussi bien que la boucle, pour un coût connu ?
- Faut-il signaler ces constats en amont, et sous quelle forme ? Ce n'est pas encore décidé.
