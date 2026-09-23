---
title: 4. /slashforge:code — dix phases et quatre points de contrôle
description: Lire les dix phases du workflow de développement de SlashForge et les quatre endroits où il attend une personne, puis lancer son mode sobre sans interface sur une vraie correction dans le labo et regarder où il s'arrête — une exécution capturée, avec son coût, et la seule règle qu'il a pliée.
sidebar:
  order: 4
---

Code : [`code/slashforge/lab/run.sh`](https://github.com/spareilleux/learn/blob/main/code/slashforge/lab/run.sh), dans le labo que construit la [leçon 3](../03-setup-against-init/). L'exécution est e3 dans le [journal](../journal/#expériences) : une exécution le 2026-09-22, Claude Code 2.1.280, `claude-opus-5-5[1m]`.

## Dix phases, quatre points de contrôle

[`forge-workflow.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-workflow.md) est le guide que `/slashforge:code` envoie lire au modèle. Il a dix phases ; quatre d'entre elles sont marquées *(Gate)*, ce qui signifie que le modèle demande et attend :

| Phase | Ce qui se passe | Point de contrôle |
|---|---|---|
| 1 Prise en charge libre | la demande ; `slashforge:brainstorm` écrit une spec de conception, sauf si le changement est trivial | |
| 2 Proposer le plan | `slashforge:plan` écrit le plan | |
| 3 Confirmer le plan | | **oui** |
| 4 Choix de la branche | | **oui** |
| 5 Implémenter | TDD, débogage, sous-agents en parallèle au besoin | |
| 6 Vérifier (lint, tests, build) | `slashforge:verify` : *"no success claims without evidence"* | |
| 7 Revue de code | un agent `code-reviewer` | |
| 8 Push et PR | | **oui** |
| 9 Retours de revue de la PR | `slashforge:review-feedback` | |
| 10 Nettoyage après le merge | | **oui** |

En termes .NET ou Java, les points de contrôle 3 et 4 sont ce qu'une équipe règle dans un ticket et dans une politique de nommage des branches, et le point de contrôle 8 est la pull request elle-même. La différence qui compte est celle que relève la [page de mission](../) : une politique de branche est appliquée par le serveur, et un point de contrôle est une phrase à laquelle on demande au modèle d'obéir. [`code.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/slashforge/code.md) insiste — *"You MUST follow every phase in order. Do not skip phases. Do not combine phases."* — et une instruction, si insistante soit-elle, n'est toujours qu'une instruction.

## Le mode sobre

`-quick` charge en plus [`forge-workflow-quick.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-workflow-quick.md), qui remplace des phases dans un tableau : la phase 1 est sautée, le plan ne garde que *Changes* et *Test strategy*, la phase 5 utilise au plus un skill, et la revue par agent de la phase 7 devient une checklist en ligne. Les quatre points de contrôle sont tous marqués **KEEP**, tout comme la phase 6. Le README donne au mode sobre *"~40–70k tokens per change"*, contre 100–250k pour le workflow complet.

## L'exécution : une vraie correction, jusqu'au premier point de contrôle

Le changement demandé est celui que ce cours a trouvé dans la leçon 1 et que `/slashforge:investigate` a diagnostiqué dans la [leçon 5](../05-investigate-and-review-pr/) : faire lister à l'exécution à blanc tout ce qu'écrit l'installation.

```bash
bash lab/run.sh <lab> e3-code-quick 0.75 20 \
  "/slashforge:code -quick make bin/install.js --dry-run list every file that installFiles writes, including the skills and the two assets"
```

```
exit:      0
wall:      57 s
turns:     6
tokens:    in 10, cache write 23433, cache read 158847, out 1710
cost:      0.2534734 USD (as computed by Claude Code)
denials:   0
changed:   0 path(s) in the lab repository
```

Il a lu l'installeur et ses tests, écrit un plan sobre et s'est arrêté :

```
Plan (lean)

Changes — `bin/install.js` only:
- Add an exported `plannedWrites(target, { guideFiles, assetFiles, commandFiles, skillFiles })` that returns `{ kind, src, dest }` entries in the same order `installFiles` writes them: guides (rendered), the 2 assets (copied), commands + skills (rendered), then `meta.json`.
- Replace the inline list in the `--dry-run` branch (`bin/install.js:499-527`) with a call to `plannedWrites`. …

Test strategy (TDD, `test/install.test.js`):
- Install into a temp dir and check that the `dest` list from `plannedWrites` equals the list `installFiles` returns. This keeps the two from drifting apart again.
- …

Two things I need from you before I start:
1. Plan: OK as written?
2. Branch: you're on `lab`. Should I work here, or create a new branch (for example `fix/dry-run-lists-all-writes` off `lab`)?
```

Le plan est le bon. C'est la correction que la leçon 1 suggérait par comparaison avec le `ShouldProcess` de PowerShell : une seule liste, utilisée par l'aperçu et par l'action, et un test qui les compare pour qu'elles ne puissent plus diverger. Et aucun fichier n'a changé : le point de contrôle a tenu.

Il a tenu sous une forme un peu différente de celle du guide, cependant. L'exécution a posé la question de la phase 3 et celle de la phase 4 dans un seul message, là où `code.md` dit *"Do not combine phases"*. Ici, cela ne coûte rien — les deux réponses sont nécessaires avant toute modification, et une exécution sans interface se serait arrêtée à la première de toute façon. Mais cela montre que l'ordre des phases est quelque chose que le modèle interprète, pas quelque chose d'appliqué. Si l'ordre compte pour toi, il doit vivre quelque part où il est appliqué, comme un hook ou une règle côté serveur ; le [cours de programmation agentique](../../agentic-coding/03-hooks-skills-subagents/) trace cette ligne.

## Ce qu'a coûté l'exécution, et ce qu'elle n'a pas mesuré

L'exécution s'est arrêtée après la phase 2, elle mesure donc le coût fixe pour arriver à la première décision : 0.25 USD, 57 s. Face aux *"~40–70k tokens"* du README, la réponse dépend de ce qu'on compte : 1,720 tokens d'entrée neuve et de sortie, 23,433 écrits dans le cache de prompt, 158,847 lus depuis celui-ci. L'essentiel de ce que lit le modèle, ce sont les mêmes guides et les mêmes fichiers à chaque tour, ce que le cache rend bon marché mais pas gratuit.

Au-delà des points de contrôle, le labo ne peut pas aller. La phase 5 modifierait les fichiers et lancerait les tests, ce que le labo autorise. La phase 8 pousserait et ouvrirait une pull request, ce que le labo refuse, puisque le clone n'a pas de remote et que `gh` est bloqué, et doit refuser : c'est une décision qui porte ton nom. Répondre aux points de contrôle un par un, avec `claude -p --resume` et un plafond pour chaque réponse, est la façon de mesurer la suite ; le journal la liste comme une décision de l'auteur, avec son budget.

## À retenir

- `/slashforge:code` a dix phases ; la 3 (plan), la 4 (branche), la 8 (push et PR) et la 10 (nettoyage) attendent une personne, et `-quick` garde les quatre.
- Un point de contrôle est une instruction donnée au modèle. L'exécution a respecté le point de contrôle et plié l'ordre des phases, en posant deux points de contrôle dans un seul message.
- Sans interface, le workflow s'arrête à son premier point de contrôle sans aucun fichier modifié. Ici, cela a pris 6 tours, 57 s et 0.25 USD.
- Les fourchettes de tokens du README ne disent pas comment elles comptent l'entrée en cache, qui représente ici l'essentiel de l'entrée.

## Exercices

1. Le plan propose un `plannedWrites` exporté plutôt qu'un drapeau sur `installFiles` qui sauterait les écritures. Donne un argument pour chaque conception.
2. Réponds aux deux questions de l'exécution avec `claude -p --resume`, une à la fois, chacune avec son propre plafond. Quelle phase arrête ensuite l'exécution, et le labo la laisse-t-il passer ?
3. Le README dit que le mode sobre ne monte pas en gamme de lui-même : *"if the plan reveals more than 2 files or a new abstraction, it stops and tells you to restart with `/slashforge:code`"*. Ce plan est-il concerné ?

<details>
<summary>Solution</summary>

1. Un `plannedWrites` séparé est une fonction pure de la cible et des quatre listes : facile à tester, et l'exécution à blanc comme l'installation l'appellent, donc elles partagent une seule liste par construction. Un drapeau `dryRun` dans `installFiles` partage encore davantage — la même boucle décide et agit — mais mélange affichage et écriture dans une seule fonction, et chaque nouveau type de fichier demande les deux branches. Le test du plan, qui compare la liste prévue avec ce que renvoie `installFiles`, protège la première conception contre la divergence.
2. Après *"OK"* et *"work here on `lab`"*, la phase 5 modifie `bin/install.js` et `test/install.test.js` et lance `npm test`, ce que le labo autorise (un `git commit` n'est pas dans sa liste autorisée, donc tout commit est refusé) ; la phase 6 vérifie ; la revue en ligne de la phase 7 suit ; la phase 8 est le point de contrôle suivant, et le push est refusé par le labo. Note le coût de chaque exécution reprise.
3. Le plan touche deux fichiers, `bin/install.js` et `test/install.test.js`, ce qui n'est pas *plus de 2*, et ajoute une fonction exportée. Qu'une fonction qui remplace une liste en ligne compte comme une *nouvelle abstraction* relève du jugement du modèle ; dans cette exécution, il a jugé que non et il est resté en mode sobre.

</details>
