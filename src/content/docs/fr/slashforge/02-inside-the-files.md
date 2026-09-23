---
title: 2. Dans les fichiers — commandes, skills, guides
description: Comment un fichier sous commands/ devient /slashforge:code, à quoi sert le frontmatter quand deux programmes différents le lisent, ce que l'installeur refuse et pourquoi il refuse avant d'écrire quoi que ce soit, comment {{INSTALL_PATH}} rend une installation globale absolue et une installation de projet relative, et comment quatre commandes courtes délèguent à de longs guides.
sidebar:
  order: 2
---

Code : [`code/slashforge/check.sh`](https://github.com/spareilleux/learn/blob/main/code/slashforge/check.sh) et [`scripts/installer-functions.mjs`](https://github.com/spareilleux/learn/blob/main/code/slashforge/scripts/installer-functions.mjs), qui appelle les propres fonctions de l'installeur. Les sorties sont dans [`expected/`](https://github.com/spareilleux/learn/tree/main/code/slashforge/expected).

L'installeur [exporte](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L660-L676) les fonctions dont il est fait, et le charger ne l'exécute pas — son point d'entrée est protégé par [`require.main === module`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L652-L658), l'équivalent Node d'un `Main` qui ne s'exécute que lorsque l'assembly est l'assembly d'entrée. Alors, au lieu de décrire ce qu'il fait, cette leçon l'appelle.

## Un chemin devient un nom

```
# A file path under commands/ becomes the name you type
slashforge/setup.md            /slashforge:setup
slashforge/code.md             /slashforge:code
slashforge/investigate.md      /slashforge:investigate
slashforge/review-pr.md        /slashforge:review-pr
slashforge/brainstorm.md       /slashforge:brainstorm
slashforge/plan.md             /slashforge:plan
slashforge/debug.md            /slashforge:debug
slashforge/tdd.md              /slashforge:tdd
slashforge/verify.md           /slashforge:verify
slashforge/review-feedback.md  /slashforge:review-feedback
slashforge/request-review.md   /slashforge:request-review
slashforge/worktree.md         /slashforge:worktree
slashforge/parallel.md         /slashforge:parallel
```

La fonction [`commandName`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L182-L186) de l'installeur applique la règle que Claude Code documente pour [la façon dont un skill obtient son nom de commande](https://code.claude.com/docs/en/skills#how-a-skill-gets-its-command-name) : pour un fichier dans un sous-répertoire de `commands/`, *"subdirectory path relative to `commands/` with each `/` replaced by `:`, then the file name without extension"* (le chemin du sous-répertoire relatif à `commands/`, chaque `/` remplacé par `:`, puis le nom du fichier sans extension). C'est du routage par dossier, comme une *area* ASP.NET ou un package Java qui transforme un répertoire en préfixe. Rien à l'intérieur du fichier n'y participe. Le préfixe est aussi toute la stratégie contre les collisions : une commande `/code` à toi et `/slashforge:code` peuvent cohabiter.

## Le frontmatter a deux lecteurs

Chaque fichier commence par un bloc de frontmatter entre deux lignes `---`. Voici celui de [`code.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/slashforge/code.md) :

```markdown
---
name: /slashforge:code
description: End-to-end development workflow — gather requirements, plan, confirm, branch, implement, verify, review, push, PR. Pass `-quick` for lean mode on small changes (skips brainstorming, minimal plan, inline self-review instead of the agent review). Uses SlashForge's own skills at each phase — no plugins required.
---
```

Deux programmes lisent ce bloc, pour des raisons différentes. L'installeur le lit pour [refuser un modèle cassé](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L113-L137), et exige `name` et `description`. Claude Code le lit pour configurer la commande — et pour un fichier dans `commands/`, sa documentation dit que le fichier [*"supports the same frontmatter except `name` and `paths`"*](https://code.claude.com/docs/en/skills#where-skills-live) (accepte le même frontmatter, sauf `name` et `paths`). Le seul champ sur lequel l'installeur insiste est un champ que Claude Code n'utilise pas pour ce type de fichier. `name: /slashforge:code` est une étiquette pour les humains et pour la vérification de l'installeur ; le nom de la commande vient du chemin, comme ci-dessus. Renomme le fichier et la commande change de nom ; modifie la ligne `name` et rien ne se passe.

Les deux lecteurs n'analysent pas non plus de la même façon. Claude Code lit du YAML. L'installeur lit [ligne par ligne](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L113-L137) : chaque ligne non vide entre les délimiteurs doit ressembler à `key: value`, avec une clé faite de lettres, de chiffres, de `_` et de `-`. En appelant `parseFrontmatter` sur quelques échantillons :

```
# What the frontmatter check refuses
no opening fence: demo.md: missing opening '---' frontmatter fence
no closing fence: demo.md: missing closing '---' frontmatter fence
no description: demo.md: frontmatter missing required field 'description'
a key with a space: demo.md: invalid frontmatter at line 3: "long description: d"
a closing fence with a trailing space: demo.md: missing closing '---' frontmatter fence
a folded YAML description: demo.md: invalid frontmatter at line 4: "  two lines"
valid: ok {"name":"/demo","description":"d"}
```

La description repliée est du YAML valide, et Claude Code la lirait comme une seule ligne de texte. L'installeur la refuse. Aucun des deux n'a tort dans son propre rôle — l'installeur n'a qu'à accepter les vingt-neuf modèles qu'il livre, et ils utilisent tous des valeurs sur une ligne — mais une vérification plus stricte que le runtime qu'elle protège mérite d'être connue avant d'ajouter un modèle à toi et de te demander pourquoi un fichier que Claude Code accepte refuse de s'installer.

## Refusé avant que rien ne soit écrit

`check.sh` copie le paquet, supprime la ligne `description:` d'un skill, et lance l'installeur de cette copie dans un autre répertoire personnel vide :

```
Template validation failed:
  ✗ slashforge/verify.md: frontmatter missing required field 'description'
Error: Refusing to install with invalid templates.
exit 1
```

puis liste les fichiers de ce répertoire personnel : aucun. La [fonction `install`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L477-L483) valide les quatre listes avant de créer le moindre dossier, et un [commentaire](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L142-L143) en donne la raison : *"a half-installed kit is worse than none"* (un kit à moitié installé est pire que pas de kit du tout). C'est le schéma d'un lot validé en entier avant `SaveChanges`, plutôt qu'enregistré ligne par ligne jusqu'à ce que l'une échoue.

## `{{INSTALL_PATH}}` : absolu dans un mode, relatif dans l'autre

Une commande doit dire au modèle où se trouvent les guides. Les modèles écrivent `{{INSTALL_PATH}}`, et l'installeur [le remplace](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L175-L180) — avec `{{KIT_VERSION}}` et `{{KIT_PACKAGE}}` — quand il écrit le fichier. Ce par quoi il le remplace dépend du mode :

```
# The two install modes
global   guides   /home/ada/.claude/setup/slashforge
global   commands /home/ada/.claude/commands
global   {{INSTALL_PATH}} = /home/ada/.claude/setup/slashforge
project  guides   /src/app/.claude/setup/slashforge
project  commands /src/app/.claude/commands
project  {{INSTALL_PATH}} = .claude/setup/slashforge
```

Dans une installation globale, le chemin est absolu, et toujours écrit avec `/`, Windows compris. Dans une installation de projet, il est relatif au dépôt. Une ligne de `code.md`, telle que livrée et après chaque installation :

```
# template
- **The argument contains `-quick`** → **LEAN MODE.** Read `{{INSTALL_PATH}}/forge-workflow-quick.md` in full, in addition to the workflow files below, and apply its overrides on top of everything in this file. Tell the user: *"Lean mode — skipping brainstorming, minimal plan, inline self-review."*
# global
- **The argument contains `-quick`** → **LEAN MODE.** Read `~/.claude/setup/slashforge/forge-workflow-quick.md` in full, in addition to the workflow files below, and apply its overrides on top of everything in this file. Tell the user: *"Lean mode — skipping brainstorming, minimal plan, inline self-review."*
# project
- **The argument contains `-quick`** → **LEAN MODE.** Read `.claude/setup/slashforge/forge-workflow-quick.md` in full, in addition to the workflow files below, and apply its overrides on top of everything in this file. Tell the user: *"Lean mode — skipping brainstorming, minimal plan, inline self-review."*
# placeholders left in the installed files
global  0
project 0
```

(`check.sh` écrit le répertoire personnel jetable sous la forme `~` ; le fichier installé contient le chemin absolu complet.) Ce chemin relatif est ce qui rend une installation de projet commitable : un chemin absolu contiendrait le nom de celui qui a lancé l'installeur. Cela veut aussi dire que le modèle doit résoudre le chemin à partir de la racine du dépôt. S'il trouve encore les guides quand Claude Code est démarré dans un sous-dossier, c'est *à vérifier* : cela dépend du modèle et de son répertoire de travail, pas de l'installeur.

Comparer les deux installations fichier par fichier montre exactement où les modes diffèrent, avec le nombre de lignes modifiées :

```
  2  ./commands/slashforge/brainstorm.md
  3  ./commands/slashforge/code.md
  2  ./commands/slashforge/investigate.md
  2  ./commands/slashforge/plan.md
  2  ./commands/slashforge/review-pr.md
 18  ./commands/slashforge/setup.md
  3  ./setup/slashforge/forge-workflow-investigation.md
  2  ./setup/slashforge/forge-workflow-review-pr.md
  2  ./setup/slashforge/meta.json
```

Huit fichiers nomment un chemin, et `meta.json` enregistre le mode et l'heure. Les vingt-trois autres sont identiques. Jusqu'à la 4.4.1, les guides étaient copiés et non rendus, si bien qu'un guide ne pouvait pas nommer un autre fichier par son chemin ; le [changelog](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/CHANGELOG.md) consigne cette correction, et les deux guides ci-dessus sont ceux qui en avaient besoin.

Ce tableau est aussi la preuve de ce que la [leçon 1](../01-what-the-installer-writes/#ce-que-lexécution-à-blanc-nannonce-pas) a lu dans le changelog : l'exécution à blanc dit toujours `copy   forge-workflow-review-pr.md`, et un fichier copié ne pourrait pas différer entre les deux modes.

## Commandes courtes, longs guides

Les quatre points d'entrée sont petits. L'essentiel de ce qu'ils font se trouve dans les guides qu'ils envoient lire au modèle :

```
 110  slashforge/setup.md
  70  slashforge/code.md
 165  forge-workflow.md
  46  forge-workflow-agents.md
  94  forge-workflow-quick.md
  51  slashforge/investigate.md
 154  forge-workflow-investigation.md
  67  slashforge/review-pr.md
 302  forge-workflow-review-pr.md
```

`code.md` contient le choix du mode et la question d'entrée, puis dit :

```markdown
## Workflow files

Read the following in full — together they are your complete workflow guide:

- {{INSTALL_PATH}}/forge-workflow.md
- {{INSTALL_PATH}}/forge-workflow-agents.md

You MUST follow every phase in order. Do not skip phases. Do not combine phases.
```

Le changelog appelle cette forme *a dispatcher plus a workflow file* (un répartiteur plus un fichier de workflow). `review-pr.md` faisait 301 lignes jusqu'à ce que la 4.4.1 déplace ses phases dans `forge-workflow-review-pr.md`, et `investigate.md` 143 lignes jusqu'à ce que la 4.4.2 fasse de même, *"so I3 existed twice, in two levels of detail, and the two could drift"* (si bien que I3 existait deux fois, à deux niveaux de détail, et que les deux pouvaient diverger). C'est le même refactoring que sortir la logique d'un contrôleur pour la mettre dans un service : le point d'entrée reste assez petit pour se lire d'un coup d'œil, et chaque règle n'est écrite qu'une fois.

Il y a un coût que le tableau ne montre pas. Un fichier de commande est chargé quand tu le tapes ; un guide est chargé quand le modèle décide de le lire, sous forme d'appel d'outil, et il compte dans la conversation comme n'importe quel fichier qu'il lit. `/slashforge:code` demande 211 lignes de guides avant sa première question.

## Des skills qui sont des fichiers de commande

Les neuf skills sont des fichiers du même type, dans le même dossier. [`verify.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/slashforge/verify.md) commence ainsi :

```markdown
---
name: /slashforge:verify
description: Evidence before claims. Use before stating that anything is done, fixed, passing, or ready — and before committing, opening a PR, or handing off. Requires running the verification command and reading its output first.
---

<!--
Adapted from the `verification-before-completion` skill in superpowers.
Copyright (c) 2025 Jesse Vincent. Licensed under the MIT License.
```

Ils sont adaptés de [superpowers](https://github.com/obra/superpowers), et chacun porte la mention MIT dans un commentaire HTML, parce que les fichiers sont installés loin du dépôt qui contient la licence. Claude Code a deux formats pour cela : un [skill](https://code.claude.com/docs/en/skills) à proprement parler est un dossier avec un `SKILL.md` et de la place pour des fichiers annexes, et un fichier dans `commands/` est *"the older format"* (l'ancien format) qui *"still works"* (fonctionne toujours). SlashForge utilise l'ancien pour ses treize fichiers, ce qui permet à un seul dossier de leur donner un seul préfixe. Le workflow n'attend pas que le modèle choisisse un skill : les guides nomment celui à utiliser à chaque phase — `slashforge:plan` en phase 2, `slashforge:verify` en phase 6, et ainsi de suite.

## À retenir

- Le chemin d'un fichier sous `commands/` est son nom ; le champ `name` d'un fichier de commande est ignoré par Claude Code et exigé par l'installeur de SlashForge.
- La vérification du frontmatter par l'installeur est un analyseur ligne par ligne, plus strict que le YAML que lit Claude Code : une `description: >` repliée est refusée.
- Chaque modèle est validé avant que le premier fichier ne soit écrit, si bien qu'un paquet cassé n'installe rien.
- `{{INSTALL_PATH}}` est absolu dans une installation globale et relatif dans une installation de projet ; huit fichiers l'utilisent, et c'est pourquoi ce sont les seuls qui diffèrent entre les deux modes.
- Les quatre commandes sont des répartiteurs de 51 à 110 lignes ; le workflow lui-même est dans des guides allant jusqu'à 302 lignes, que le modèle lit à la demande.

## Exercices

1. Tu renommes le fichier installé `commands/slashforge/verify.md` en `check.md` sans toucher à son frontmatter. Que tapes-tu maintenant pour le lancer, et que se passe-t-il la prochaine fois que tu lances l'installeur ?
2. L'installeur vérifie quatre listes avant d'écrire. Suppose qu'il valide plutôt chaque fichier juste avant de l'écrire. Que laisserait dans le répertoire personnel l'expérience de la `description` vide ci-dessus ?
3. Dans `l02_global_vs_project`, `setup.md` diffère de 18 lignes et `code.md` de 3. Sans ouvrir les fichiers, qu'est-ce que cela te dit des deux commandes ?

<details>
<summary>Solution</summary>

1. `/slashforge:check` : le nom vient du chemin du fichier, et Claude Code ignore `name` dans un fichier de commande, donc l'ancienne ligne `name: /slashforge:verify` ne change rien. L'installation suivante écrit de nouveau `verify.md`, parce que l'installeur travaille à partir de sa propre liste, pas de ce qu'il y a sur le disque — et tu as alors deux commandes au contenu identique, `/slashforge:check` et `/slashforge:verify`. Les guides envoient toujours le modèle vers `slashforge:verify`, si bien que ta copie renommée est celle que rien n'utilise.
2. Les fichiers écrits avant `verify.md` dans l'ordre de l'installeur : les seize guides, les deux ressources, et les commandes et skills qui le précèdent dans `[...COMMAND_FILES, ...SKILL_FILES]` — `setup`, `code`, `investigate`, `review-pr`, `brainstorm`, `plan`, `debug`, `tdd` — sans `meta.json`, écrit en dernier : 26 fichiers. Un kit auquel manque le skill de sa phase 6, et que [`status`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/bin/install.js#L439-L457) décrirait comme *"unknown (legacy install — no meta.json)"* (inconnu, installation ancienne sans meta.json), puisque le dossier des guides existe mais pas `meta.json`.
3. Que `setup.md` nomme les guides par leur chemin bien plus souvent : c'est la commande qui envoie le modèle vers la plupart d'entre eux — règles, skills, agents, commandes, hooks, mémoire — une ligne chacun, alors que `code.md` en nomme trois. Le nombre de lignes est une carte des guides dont dépend chaque commande, tracée par un `diff`.

</details>
