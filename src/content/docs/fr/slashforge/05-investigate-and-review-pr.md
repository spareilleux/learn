---
title: 5. /slashforge:investigate et /slashforge:review-pr
description: Lancer dans le labo l'investigation en lecture seule de SlashForge sur un bug que ce cours connaît déjà, et sa revue de pull request avec GitHub déconnecté — ce que chacune a trouvé, où chacune s'est arrêtée, ce que chacune a coûté, et le fichier qu'une exécution a écrit hors du dépôt parce que le labo le permettait.
sidebar:
  order: 5
---

Code : [`code/slashforge/lab/run.sh`](https://github.com/spareilleux/learn/blob/main/code/slashforge/lab/run.sh), dans le labo de la [leçon 3](../03-setup-against-init/). Les exécutions sont e1, e1b et e4 dans le [journal](../journal/#expériences) : 2026-09-22, Claude Code 2.1.280, `claude-opus-5-5[1m]`. La leçon 4 a traité `-quick`.

## `/slashforge:investigate` : un symptôme en entrée, un rapport en sortie

[`investigate.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/slashforge/investigate.md) est un aiguilleur vers [`forge-workflow-investigation.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-workflow-investigation.md), qui a trois phases : I1, la prise en charge (elle ne demande le symptôme que si tu n'en as donné aucun), I2, l'investigation, *"read-only … No edits to application code"*, et I3, le rapport et le passage de relais. Il n'y a pas de point de contrôle : avec un symptôme, le parcours va jusqu'au bout. Il produit un rapport de constats en HTML sous `docs/slashforge/investigations/`, et une ligne de passage de relais pour `/slashforge:code`.

Le symptôme donné était la trouvaille de la leçon 1, donc la réponse est connue d'avance :

```bash
bash lab/run.sh <lab> e1b-investigate 0.50 10 \
  "/slashforge:investigate bin/install.js --dry-run lists 21 files but an install writes 32"
```

Les deux exécutions l'ont trouvée. Extrait du message final de e1 :

```
Confirmed. `--dry-run` doesn't ask the real installer what it will write. It builds its own list at `bin/install.js:499-530`, and that list only includes `GUIDE_FILES` (16), `COMMAND_FILES` (4) and the meta file (1), for a total of 21.

The real writer, `installFiles()` at `bin/install.js:214-279`, also writes `ASSET_FILES` (2, line 247) and `SKILL_FILES` (9, line 252). 21 + 2 + 9 = 32, which accounts for the whole gap.
```

Il a ajouté l'étiquette `copy` que la leçon 1 avait aussi relevée, une chose que le cours n'avait pas écrite — l'exécution à blanc ne mentionne pas les `REMOVED_GUIDE_FILES` périmés qu'une installation supprime — et une correction suggérée : une fonction de planification partagée par les deux chemins, avec un test de non-régression. La lecture seule a tenu : après les deux exécutions, `git status` dans le dépôt du labo était vide.

## Le rapport qui n'a pas été écrit

La phase I3 ne laisse pas le modèle écrire le rapport d'un seul coup. L'enveloppe HTML du rapport, avec tout son CSS, est livrée sous le nom `forge-report-shell.html` ; le modèle n'écrit que le corps, et une *"substitution step splices the two together"*, pour que les rapports ne divergent pas et que le CSS ne coûte pas des tokens de sortie à chaque fois. L'assemblage est un [script `node -e`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-workflow-investigation.md#L99-L112), en ligne dans le guide — et le labo n'autorise `node` que pour les tests et l'exécution à blanc de l'installeur. Dans les deux exécutions, l'assemblage a donc été refusé, et aucun rapport n'existe.

Ce qu'a fait chaque exécution ensuite est la partie intéressante.

**e1**, dans la première version du labo, qui listait `Edit` et `Write` parmi les outils autorisés. `node` lui étant refusé, le modèle a écrit l'assemblage sous forme de script, `sf-splice.js`, dans `%TEMP%` — hors du dépôt — et a terminé son message en demandant à l'utilisateur de le lancer :

```
Report: the splice script with the full report body is at `C:/Users/spare/AppData/Local/Temp/sf-splice.js`. To create the report, run `node C:/Users/spare/AppData/Local/Temp/sf-splice.js`.
```

Rien n'enfreignait les règles telles que le labo les avait posées : `Write` était autorisé, sans chemin. C'est exactement le piège. Dans les [règles de permission](https://code.claude.com/docs/en/permissions) de Claude Code, un outil listé dans `--allowedTools` sans spécificateur est autorisé *partout* ; `--permission-mode acceptEdits` seul accepte les modifications *"for paths in the working directory or `additionalDirectories`"*. Le labo s'appuie désormais sur le second et liste tout fichier qui apparaît dans le dossier temporaire pendant une exécution.

**e1b**, avec le labo corrigé : aucune écriture à l'extérieur, pas de rapport, et l'exécution s'est terminée sur la limite de tours, à 11 tours sur 10, avec `error_max_turns`, après avoir dépensé 0.38 USD. Ses trois commandes refusées étaient deux exécutions à blanc de l'installeur dans un répertoire personnel temporaire et l'assemblage lui-même.

| Exécution | Labo | Tours | Coût | Rapport | Hors du dépôt |
|---|---|---|---|---|---|
| e1 | `Write` autorisé sans chemin | 15 | 0.45 USD | non | `%TEMP%\sf-splice.js`, 4,175 octets |
| e1b | `acceptEdits` seul | 11 (limite 10) | 0.38 USD | non | rien |

Deux limites de la mesure. Aucune des deux exécutions n'a produit le rapport, donc la moitié de l'hypothèse qui le concerne n'est pas testée. Et e1 a indiqué 15 tours sous le même `--max-turns 10` et s'est terminée normalement, là où e1b a été arrêtée ; la raison est notée dans le journal comme *à vérifier*. Le README prévoit *"~15–60k tokens"* ; les deux exécutions ont lu plus de 350,000 tokens depuis le cache de prompt, essentiellement les mêmes fichiers à chaque tour.

## `/slashforge:review-pr` : arrêté à la porte

[`review-pr.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/slashforge/review-pr.md) commence par une vérification préalable : *"`gh` must be installed and authenticated, or nothing here works"*, et si ce n'est pas le cas, *"stop and tell the user to run `gh auth login`. Do not attempt a workaround."* Le labo a son propre `GH_CONFIG_DIR`, vide, donc `gh` est déconnecté ; pour cette exécution seulement, `GH_STATUS_ONLY=1` autorisait `gh auth status` et refusait toujours toute autre commande `gh`.

```bash
GH_STATUS_ONLY=1 bash lab/run.sh <lab> e4-review-pr 0.25 5 "/slashforge:review-pr"
```

```
I stopped at the preflight check because the GitHub CLI isn't logged in. `gh auth status` failed, so I couldn't list PRs or read any PR data. Nothing was read from GitHub and nothing was written.
```

4 tours, 35 s, 0.17 USD, aucun contournement tenté. C'est l'exécution la moins chère possible de la commande, et l'hypothèse écrite avant elle a été confirmée mot pour mot.

Après la vérification préalable, le workflow a deux points de contrôle. R1 demande quelle PR relire. R5, avant que quoi que ce soit ne soit publié, est le point de contrôle le plus strict du kit : il montre *"the exact text that will appear on GitHub"*, demande *"Post this review? `approve` · `comment` · `request-changes` · `edit` · `cancel`"*, et dit *"Never infer the choice from severity."* Une revue est publique et signée de ton nom ; le labo n'atteint jamais R5, et ne le doit pas.

## Trois commandes, un même schéma

| | investigate | review-pr | code `-quick` (leçon 4) |
|---|---|---|---|
| Premier arrêt dans le labo | l'assemblage du rapport, refusé | la vérification préalable de `gh` | le point de contrôle du plan |
| Fichiers modifiés dans le dépôt | 0 | 0 | 0 |
| Coût de l'exécution | 0.38–0.45 USD | 0.17 USD | 0.25 USD |

Chaque commande a fait ce que dit son fichier, jusqu'au point où le labo ou une personne devait dire oui. La seule surprise est venue du labo, pas de SlashForge : face à un outil sans chemin associé, le modèle s'en est servi pour arriver à ses fins autrement. Quand tu donnes des permissions à un agent, écris le chemin avec l'outil.

## À retenir

- `/slashforge:investigate` n'a pas de point de contrôle quand on lui donne un symptôme ; il est resté en lecture seule et a trouvé la cause racine que ce cours avait trouvée par comparaison.
- Son rapport est assemblé par une commande `node`. Un labo qui refuse `node` n'obtient pas de rapport ; un labo qui autorise `Write` partout peut obtenir à la place un script ailleurs.
- Un outil dans `--allowedTools` sans chemin est autorisé partout ; `acceptEdits` seul confine les modifications au répertoire de travail.
- `/slashforge:review-pr` s'arrête à sa vérification préalable quand `gh` est déconnecté, comme le dit son fichier, et ne publie jamais sans un choix explicite à R5.

## Exercices

1. Écris la règle de permission qui laisserait l'assemblage du rapport s'exécuter dans le labo sans autoriser `node` en général. Que te faudrait-il savoir d'abord sur la commande ?
2. Pourquoi la phase I3 assemble-t-elle une enveloppe fixe plutôt que de laisser le modèle écrire tout le fichier HTML ? Donne les deux raisons du guide et une qu'il ne donne pas.
3. Dans e4, quel réglage du labo a fait échouer `gh auth status`, et que se serait-il passé avec ta vraie configuration `gh` ?

<details>
<summary>Solution</summary>

1. Tu ne peux pas, avec le guide tel qu'il est. L'assemblage est `node -e '<script>' <shell> <fragment> <report> <title>`, et une règle `Bash` reconnaît une commande par son préfixe : `Bash(node -e:*)` autoriserait n'importe quel script, ce qui est aussi large qu'autoriser `node`. La version étroite demande que le script soit un fichier, comme l'est `forge-open.sh` : livrer l'assemblage sous le nom, par exemple, `forge-splice.js` à côté de l'enveloppe, et autoriser `Bash(node <install path>/forge-splice.js:*)`. En attendant, l'option sûre est de lancer l'assemblage toi-même à partir du fragment de corps que le modèle a écrit.
2. Le guide : le CSS est identique dans chaque rapport, donc le régénérer *"wastes output tokens"*, et cela *"lets reports drift apart visually"*. Une de plus : une enveloppe fixe est une surface d'attaque fixe. Le changelog de 4.1.2 a corrigé un titre qui pouvait fermer `</title>` trop tôt ; une enveloppe que le modèle réécrit à chaque fois devrait réussir cet échappement à chaque fois.
3. `GH_CONFIG_DIR` pointait vers un répertoire vide à l'intérieur du labo, donc `gh` n'a trouvé aucune connexion. Avec ta vraie configuration, `gh` aurait été connecté, la vérification préalable serait passée, et R1 aurait listé les pull requests qui attendent ta revue — en lisant GitHub en ton nom, et c'est pourquoi le labo l'isole.

</details>
