---
title: Gaia — Mission
description: "Gaia est un bus de coordination local et durable, et une usine logicielle qui apporte ses preuves, pour les sessions Claude Code et Codex : six verbes sans privilège, un journal d'événements en ajout seul, et des reçus que personne n'a à croire sur parole. Ce cours explique ce que Gaia cherche à accomplir, pourquoi le privilège y est empêché par son absence plutôt que par une vérification, et ce qui a réellement été mesuré, chaque sortie étant produite sur la révision épinglée."
sidebar:
  label: Mission
  order: 0
---

:::note[Révision étudiée, et ce qui est mesuré ici]
Gaia au commit [`d68e900`](https://github.com/GuitarAlchemist/gaia/tree/d68e90099ae2a6fbbec9d428617bfcd02095aac0) (2026-09-13), la tête de `main`, sous Windows 11 avec [Node.js](https://nodejs.org/en) v24.12.0, le 15 septembre 2026. Gaia n'a **aucune dépendance d'exécution** : chaque commande de ce cours fonctionne donc depuis un clone propre, sans `npm install`.

Chaque sortie citée dans ces leçons a été produite en lançant la commande sur cette révision, dans un répertoire de données jetable, et collée telle quelle, à part le raccourcissement de longs chemins absolus. **Aucune leçon de ce cours ne lance un modèle facturé.** La seule commande qui le fait, `factory:agent`, qui dépense un vrai tour de Claude et un vrai tour de Codex, est décrite à partir de son code, de son document de conception et du schéma de ses reçus, et marquée *à vérifier* là où je ne l'ai pas exécutée.
:::

## Pourquoi j'apprends cela

J'écris maintenant la plus grande partie de mon code avec un agent de code. Le [cours de programmation agentique](../agentic-coding/) traite d'un agent dans un dépôt : la boucle d'outils, les permissions, `CLAUDE.md`, les hooks, MCP. Ce cours-ci porte sur le problème qui apparaît juste après, et qu'aucun travail sur les prompts ne résout.

Deux sessions d'agent, puis quatre, travaillent sur le même ensemble de dépôts. Elles ne se voient pas. Chacune termine et annonce un succès. Et je n'ai aucun moyen de distinguer ces trois phrases :

- « J'ai implémenté la modification et les tests passent. »
- « J'ai implémenté la modification, je n'ai rien exécuté, et la phrase ci-dessus est ce qu'un modèle produit quand une tâche se termine. »
- « Une autre session a modifié ce fichier sous mes pieds, et mon diff porte sur un arbre qui n'existe plus. »

Les trois arrivent sous la forme du même paragraphe assuré. Le message de fin d'un agent est de la **prose**, et la prose n'est pas une preuve. Gaia est ma tentative de construire la couche qui rend la différence vérifiable : une coordination durable, et des résultats accompagnés de reçus que quelqu'un d'autre peut rejouer ou refuser.

## Ce que Gaia cherche à accomplir

La carte d'architecture de Gaia énonce le but en une phrase : *Gaia coordonne une livraison logicielle qui apporte ses preuves, tout en gardant distinctes l'observation, l'acceptation et l'autorité.*

Cette phrase porte beaucoup, alors la voici dépliée en quatre affirmations, autour desquelles ce cours est construit.

**1. La coordination et l'autorité sont deux choses différentes, et ne doivent pas voyager ensemble.** Un message qui dit « merci de fusionner ceci » doit pouvoir atteindre un autre agent sans jamais pouvoir *provoquer* une fusion. Dans Gaia, ce n'est pas une vérification de permission qu'on pourrait contourner : les verbes qui pourraient approuver, fusionner, pousser ou déployer **n'existent pas**. La leçon 2 affiche toute la surface des outils, puis montre un message qui demande l'autorité de fusionner, remis et refusé dans le même souffle.

**2. La fraîcheur, la qualité, l'acceptation et l'autorité sont quatre axes indépendants.** Un artefact frais peut être faux. Un artefact de grande qualité peut être périmé. Un artefact accepté peut n'accorder aucune autorité. La plupart des outils pour agents réduisent tout cela à un seul nombre ou à une seule coche verte ; Gaia les garde séparés à dessein, et refuse même de rapporter un unique scalaire de « confiance ».

**3. Une preuve, c'est ce qu'un autre acteur peut rejouer, pas ce que le producteur affirme.** Chaque changement d'état écrit un reçu qui lie les entrées exactes, les empreintes du contenu, les préconditions et l'autorité réellement dépensée. La leçon 4 lance le traceur de l'usine et lit le reçu qu'il produit, y compris les parties qui disent ce que le reçu ne prouve **pas**.

**4. Une limite sans mesure derrière elle est une préférence, pas une limite.** Gaia prend en charge quatre voies actives par espace de travail. Non parce que quatre est un chiffre rond, mais parce que quatre est le plus grand nombre que quelqu'un ait réellement éprouvé de bout en bout. La leçon 5 lit cette échelle des preuves, et les messages de refus qui nomment ce qui reste non prouvé.

Le mode de défaillance visé par ces quatre affirmations est le même : **un système qui produit une réponse rassurante là où il devrait produire un refus.** Gaia est fermé en cas d'échec : un délai de verrou dépassé, un journal tronqué, une révision périmée ou une identité qui ne correspond pas n'écrivent rien et le disent, au lieu de laisser un résultat partiel qui a l'air correct.

## À qui s'adresse ce cours

Tu écris du C# ou du Java professionnellement, et tu as assez utilisé un agent de code pour t'y être brûlé au moins une fois : une modification que tu n'avais pas demandée, un test qui n'a jamais été lancé, un « terminé » qui ne l'était pas. Tu n'as pas besoin de connaître Node.js : le code source de Gaia est fait de simples modules ES, et ce cours le cite plutôt que de te demander d'en écrire.

Le [cours de programmation agentique](../agentic-coding/) aide, mais n'est pas nécessaire. Là où une notion vient de ce cours, comme la boucle d'outils, MCP ou les modes de permission, celui-ci renvoie à la leçon concernée au lieu de la répéter.

## Le vocabulaire de Gaia en un tableau

Les mots comptent ici plus que d'habitude, parce que toute la conception consiste à les garder séparés. D'après la carte d'architecture :

| Notion | Ce que c'est | Ce que ce n'est **pas** |
|---|---|---|
| Claim (revendication) | réserve ou signale un travail observé | la permission de faire quoi que ce soit |
| Intent (intention) | la mutation proposée exacte, liée à une identité, une génération, une politique et une révision | un effet |
| Effect (effet) | une tentative bornée, par un seul propriétaire nommé | quelque chose qu'un agent peut déclencher en le demandant |
| Receipt (reçu) | préconditions, résultat, révision des preuves, autorité réellement dépensée | la preuve que le résultat est correct |
| Delivery (remise) | accepté pour remise | lu, approuvé ou terminé |
| Acknowledgement (accusé de réception) | la réception d'un message | un accord, une approbation ou un achèvement |
| Handoff (passation) | le transfert d'un travail et de son contexte | le transfert d'un privilège |
| Lane (voie) | une surface d'exécution | une autorité, ou la preuve d'un travail utile |

Si tu ne lis qu'une partie de ce tableau, lis les trois dernières lignes. *Remis*, *accusé de réception* et *passé la main* sont les trois expressions que l'orchestration d'agents emploie d'habitude pour dire « c'est pris en charge », et dans Gaia, toutes les trois sont explicitement définies comme ne voulant pas dire cela.

## À la fin de ce cours, je saurai

- expliquer ce qu'est une usine qui apporte ses preuves, et à quelle question elle répond qu'une coche verte de CI ne règle pas ;
- lancer le bus, enregistrer plusieurs acteurs, et lire le journal en ajout seul qu'ils produisent ;
- dire exactement ce que les six verbes peuvent et ne peuvent pas faire, et *démontrer* le refus plutôt que l'affirmer ;
- rejouer un journal, le vérifier, et distinguer les trois codes de sortie : refusé, fermé en cas d'échec, et ok ;
- lire un reçu de l'usine et dire ce qu'il prouve et ce qu'il laisse comme résidu déclaré ;
- justifier la limite de quatre voies par ses preuves, et dire ce qui permettrait de la relever.

## Plan

| # | Leçon | Tu connais déjà |
|---|---|---|
| 1 | [Le problème : ce que vaut un « terminé »](01-the-problem/) | une revue de code, une suite de tests instable |
| 2 | [Six verbes, et l'autorité absente à dessein](02-six-verbs/) | une file de messages, une ACL |
| 3 | [Le journal d'événements : en ajout seul, rejoué, fermé en cas d'échec](03-event-log-and-replay/) | l'event sourcing, un journal d'écriture anticipée |
| 4 | [L'usine : candidats, relecteurs et reçus](04-factory-and-receipts/) | une pull request, un artefact de build |
| 5 | [Limites, preuves et écosystème](05-limits-and-ecosystem/) | la planification de capacité, une décision d'intégration |
| — | [Journal](journal/) | |

## Prérequis

- [Node.js](https://nodejs.org/en). À la révision étudiée, Gaia épingle une version exacte : `.node-version` et le champ `engines.node` de `package.json` indiquent tous deux `26.8.1`. Rien ne l'impose quand tu appelles `node` directement, et tout ce cours a tourné sur la v24.12.0 sans avertissement ni échec ; mais l'exécution sur la version épinglée est *à vérifier*.
- [Git](https://git-scm.com/), pour les worktrees liés qu'utilise la leçon 4.
- Un terminal. Gaia n'a aucun écouteur réseau, aucune exécution à distance et aucun transport par shell : rien ici n'ouvre de port.

```bash
git clone https://github.com/GuitarAlchemist/gaia
cd gaia
node scripts/gaia-interagent.mjs doctor
```

## Ressources

- [GuitarAlchemist/gaia](https://github.com/GuitarAlchemist/gaia) : le dépôt. `README.md` est le document produit, `ARCHITECTURE.md` la carte de référence des frontières, et `docs/` contient les dossiers de conception et d'exploitation.
- [Principes d'ingénierie et de recherche](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/docs/engineering-and-research-principles.md) : la doctrine que lit la leçon 1, et le document à lire avant de proposer une modification de Gaia.
- [Échelle et voies](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/docs/scale-and-lanes.md) : l'échelle des preuves derrière le nombre quatre.
- [Model Context Protocol](https://modelcontextprotocol.io/) : le protocole que parle le bus sur stdio, traité dans la [leçon 4 de programmation agentique](../agentic-coding/04-mcp/).
- David L. Parnas, [On the Criteria To Be Used in Decomposing Systems into Modules](https://dl.acm.org/doi/10.1145/361598.361623), et Jerome H. Saltzer et Michael D. Schroeder, [The Protection of Information in Computer Systems](https://www.mit.edu/~Saltzer/publications/protection/index.html) : les deux articles que citent les principes de Gaia pour la profondeur des modules et pour le moindre privilège.
