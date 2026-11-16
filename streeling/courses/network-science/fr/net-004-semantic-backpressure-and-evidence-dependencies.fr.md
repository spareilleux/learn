---
module_id: net-004-semantic-backpressure-and-evidence-dependencies
department: network-science
course: "Tester la contre-pression sémantique à l’aide de dépendances de preuves"
level: intermediate
prerequisites: [net-003-worker-lane-coverage-and-fragility]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
research_cycle: network-science-2026-10-12-004
version: "0.1.0"
---

# Tester la contre-pression sémantique à l'aide de dépendances de preuves

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](../../../../code/streeling/evidence/agentic-composition-2026-10-22/README.md) décrit l’importation actuelle et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département de science des réseaux** | Intermédiaire | 40 minutes | Brouillon français d'une leçon fondée sur une hypothèse ; révision et publication en attente

## Objectifs et question du projet

Après cette leçon, vous saurez distinguer une coupure liée à la capacité ou au mode d'un prérequis de preuve non satisfait, dessiner les dépendances entre pièces justificatives d'une action proposée, évaluer une petite règle de composition sans confondre preuve manquante et refus d'autorité, et préciser quand cette nouvelle règle devrait être rejetée. **Question du projet :** des dépendances de preuves propres à chaque action pourraient-elles permettre au travail indépendant de progresser tout en empêchant qu'un brouillon Streeling soit qualifié de révisé ou de publié avant que les pièces requises existent ? Il s'agit d'une hypothèse de conception, pas d'un contrôleur déployé dans Demerzel, Gaia ou Learn.

## 1. Partir du contrôle existant

[NET-003](net-003-worker-lane-coverage-and-fragility.md) modélise le graphe de Demerzel reliant workers et classes de travail. Sa [politique de lanes](https://github.com/GuitarAlchemist/Demerzel/blob/ecdc6c27559bb1a11343cfad33687465893e9891/state/driver/aiw-worker-lanes.json) et son [sélecteur consultatif](https://github.com/GuitarAlchemist/Demerzel/blob/ecdc6c27559bb1a11343cfad33687465893e9891/scripts/aiw_lane_selector.py) figés coupent les chemins assignés lorsqu'un mode de fanout bloque leur classe de travail. Une classe bloquée reçoit `SYSTEM.BACKPRESSURE_HIGH`. Le sélecteur vérifie aussi les rôles interdits et assignés, mais n'examine ni les preuves de révision disciplinaire d'un cours, ni un SHA source Learn, ni le résultat d'un apprenant. Son code de sortie 0 signifie que l'évaluation a eu lieu ; la décision figure dans les données JSON. Ce sont des observations du code à `ecdc6c27559bb1a11343cfad33687465893e9891`, pas un état des lieux des workers actuels.

Ne qualifiez la contre-pression de **sémantique** que si elle dépend d'une propriété déclarée du *résultat demandé* et de ses preuves. Par exemple, une règle de mode peut reporter toute nouvelle fonctionnalité pendant DRAINING. Une règle proposée de publication de cours reporterait plutôt `publish(NET-003)` lorsqu'une révision humaine requise pour la même révision source manque, tout en permettant l'analyse d'une fixture audio indépendante. Aucune des deux règles ne crée de réviseur humain ni n'accorde le droit de fusionner. Un simple indicateur de révision peut déjà suffire ; la formulation par dépendances ne justifie sa complexité que si elle améliore les décisions dans une comparaison mesurée.

### Exercice pratique 1 : identifier la source de contre-pression

En mode DRAINING, le sélecteur figé de Demerzel bloque le rôle principal `builder_fixer` de `claude` parce que `net_new_feature` est bloqué par le mode, mais recommande son rôle secondaire `test_author` parce que `fix` reste autorisé. Par ailleurs, un cours porte `review.completed=false`. Quelle condition est une coupure de mode, laquelle pourrait devenir un prérequis de preuve non satisfait, et l'une ou l'autre autorise-t-elle la publication du cours ?

> **Réponse :** Les deux décisions de lane sont des décisions de mode et de rôle du sélecteur. L'absence de révision du cours pourrait laisser un prérequis de publication *proposé* non satisfait si le contrat de publication exige cette révision. Aucune ne donne l'autorité de publier. La recommandation d'un rôle d'auteur de tests ne remplace pas une révision disciplinaire manquante et ne transforme pas un brouillon en cours approuvé.

## 2. Dessiner les dépendances entre action et pièces justificatives

Représentez une action candidate `a` et ses preuves requises par un graphe orienté de dépendances comportant un nœud `all(a)` explicite. Chaque arête `receipt r -> all(a)` fournit un prérequis ; `all(a) -> a` n'active l'action que lorsque chaque pièce requise est présente, valide pour le périmètre déclaré et liée à la même révision source. Cette flèche est un prérequis, pas une commande de création d'une pièce. Pour `publish(NET-003)`, envisagez trois prérequis candidats : une révision de cours commitée `S`, un build Learn issu de `S` et un verdict humain disciplinaire sur `S`. Un essai d'apprenant peut provenir d'un pilote accessible avant publication ; sinon, il constitue un résultat pédagogique après publication, pas un prérequis pour rendre le cours accessible. C'est un **contrat pédagogique** à évaluer, pas la politique de déploiement implémentée du site actuel. L'autorisation et la révision des traductions par des personnes maîtrisant les langues constitueraient des conditions supplémentaires et distinctes pour une véritable publication.

Définissez `ready(a,S)` comme la conjonction des prédicats de pièces justificatives déclarés pour l'action. Un verdict humain absent est `unknown` ou `not supplied`, pas `false expertise` ; une révision différente invalide le rattachement, même si un réviseur a apprécié une version antérieure. Ne transformez pas un décompte tel que « deux pièces sur trois » en autorisation partielle. Gardez l'entrée non satisfaite visible. Le graphe devrait aussi contenir une action indépendante, telle que `analyze(AUD-003 fixture)`, avec ses propres entrées ; une révision NET-003 manquante ne devrait pas la bloquer automatiquement.

### Exercice pratique 2 : évaluer une dépendance ET

Supposons que la source du cours et un build Learn correspondant existent pour `S`, mais que le verdict disciplinaire soit absent. L'analyse de la fixture audio dispose de sa pièce d'entrée requise. Quel prérequis n'est pas satisfait et que peut-on encore exécuter ?

> **Réponse :** L'entrée de verdict disciplinaire de `all(publish)` n'est pas satisfaite ; le nœud `all` ne peut donc pas activer `publish(NET-003,S)` selon le contrat pédagogique énoncé. Il s'agit d'un prérequis ET, pas d'une coupure d'une seule arête : les entrées source et build restent présentes. `analyze(AUD-003 fixture)` reste exécutable grâce à ses entrées indépendantes, et le brouillon peut encore être révisé. Le résultat est « prérequis de publication incomplets », pas « tout le système d'agents est arrêté ».

## 3. Composer une règle sans inventer un moteur d'exécution

Ce qui suit est une **esquisse de notation**, pas un DSL ni une API implémentés :

```text
publish(course, S) <- all(
  committed(course, S),
  build_from(S),
  human_subject_review(course, S)
)
```

`all` est une conjonction pure de vérifications typées de pièces justificatives. Chaque vérification renvoie un verdict délimité et l'identité de la preuve examinée. Une recherche infructueuse doit fournir un motif tel que `missing`, `stale_revision` ou `invalid_scope` ; réduire ces motifs à un seul bit faux masquerait l'action corrective. Une vérification ultérieure d'autorisation n'est pas une autre preuve factuelle qu'un agent pourrait fabriquer. Cette esquisse compose des prédicats au niveau d'une action et de ses obligations de preuve, plutôt que de demander aux agents d'échanger des appels d'API de bas niveau. Elle ne spécifie ni analyseur, ni exécuteur d'effets, ni protocole de verrouillage, ni autorité de gouvernance.

### Exercice pratique 3 : détecter la dérive de révision

Un verdict humain nomme le SHA source `S0`, tandis que le build et la publication proposée nomment `S1`. Les trois *types* de pièces sont présents. Que renvoie l'esquisse et pourquoi serait-il erroné de vérifier uniquement leur nombre ?

> **Réponse :** `human_subject_review(course,S1)` n'est pas satisfait, car le verdict est rattaché à `S0` ; `publish(course,S1)` est donc reporté selon l'esquisse. Trois fichiers ne constituent pas trois preuves valides pour une même révision. L'opérateur doit obtenir une nouvelle révision de `S1` ou une décision documentée du réviseur couvrant explicitement son diff ; la notation elle-même ne peut pas décider de l'équivalence de fond.

## 4. Chercher à réfuter le mécanisme supplémentaire

Le contre-argument le plus fort est que les indicateurs existants `review.completed` et `publish.completed`, une protection sur le SHA source et des contrôles CI ordinaires peuvent exprimer ce cas plus simplement. Un graphe et un DSL pourraient dupliquer la politique, produire des dépendances obsolètes ou circulaires, bloquer du travail utile par un faux positif, augmenter le délai de révision et créer un séduisant indicateur « vert » sans autorité. Une pièce peut être présente syntaxiquement tout en étant erronée sur le fond. Une règle de prérequis sémantique peut donc être moins bonne qu'une checklist manuelle claire.

Comparez le candidat à cette référence plus simple sur un ensemble fini de changements de cours réels, expurgés des données sensibles, et de pièces volontairement altérées. Avant les tests, définissez les résultats : l'admission erronée d'une publication non révisée ou liée à une source obsolète doit rester à zéro ; comptez les blocages inutiles de travail indépendant ; mesurez le temps de décision ; et consignez si les réviseurs peuvent expliquer chaque décision. Rejetez le candidat s'il n'apporte aucun bénéfice observable de précision ou de débit par rapport aux simples indicateurs, s'il masque une décision humaine requise ou si ses obligations de preuve ne peuvent être maintenues au rythme réel des changements source. Une révision contradictoire indépendante doit examiner la règle avant qu'elle devienne normative.

### Exercice pratique 4 : repérer un faux positif

Une condition globale bloque toutes les tâches Demerzel tant que NET-003 ne possède pas de verdict humain disciplinaire. L'équipe doit aussi relancer une fixture de signal IX indépendante dont les entrées et l'autorité sont déjà disponibles. Quelle métrique révélerait l'erreur et quelle est la correction la plus simple ?

> **Réponse :** Comptez ce cas comme un blocage inutile de travail indépendant. Limitez la condition de révision à `publish(NET-003,S)` et à ses actions dépendantes, sans toucher au chemin de la fixture IX. Une checklist par action pourrait apporter la même correction sans nouveau DSL ; le graphe de dépendances ne se justifie que s'il traite mieux des cas supplémentaires.

## 5. Appliquer l'hypothèse à un enregistrement de projet figé

Au commit source Demerzel [`29e83e0`](https://github.com/GuitarAlchemist/Demerzel/blob/29e83e08120cba99452020c54c31680c28b32c3e/state/streeling/course-productions/cp-network-science-2026-10-11-003.json), l'enregistrement de production de NET-003 porte `review.completed=false` et `publish.completed=false`. Le cours anglais possède une [pièce de rejeu local du sélecteur](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/reviews/net-003-selector-replay-2026-10-12.json), mais elle prouve uniquement l'expérience délimitée sur le sélecteur consultatif. Ce n'est ni un verdict humain disciplinaire, ni un résultat d'apprenant, ni une preuve de déploiement Learn. La [protection de synchronisation Learn](https://github.com/spareilleux/learn/blob/3f4de745f56e81f237159997473253546d7f6d64/scripts/sync-streeling.mjs), distincte, rejette une copie source Demerzel modifiée lorsqu'on prétend utiliser son HEAD comme provenance ; elle n'approuve pas le contenu des cours. L'enregistrement et la protection sont des artefacts concrets du projet, tandis que la règle proposée de dépendance aux preuves reste non implémentée.

### Exercice pratique 5 : écrire une décision limitée aux preuves

À partir de ces seuls artefacts figés, écrivez l'état de `publish(NET-003,S)` et une prochaine action. Nommez une observation qui réfuterait l'affirmation selon laquelle une future règle de contre-pression sémantique aurait amélioré ce workflow.

> **Réponse :** La publication n'est pas admissible selon le contrat pédagogique : l'enregistrement laisse explicitement les indicateurs de révision et de publication à faux, et le rejeu du sélecteur n'est pas un verdict disciplinaire. Poursuivez la préparation de la source et de la révision ; obtenez un verdict humain disciplinaire lié à la révision acceptée avant de réexaminer la publication. Un essai d'apprenant peut être recueilli dans un pilote accessible avant publication ou évalué comme résultat pédagogique après publication. Si une règle testée admet une publication sans ses prérequis déclarés, elle enfreint la protection imposant zéro admission erronée. Si elle prend exactement les mêmes décisions que les indicateurs existants en ajoutant délai et maintenance, son bénéfice annoncé est également réfuté. L'enregistrement figé ne prouve pas qu'une telle règle est déployée.

## Preuves et limites

- Le sélecteur et la politique Demerzel figés établissent uniquement le comportement de mode et de rôle. Le rejeu NET-003 est une expérience à blanc sur le code source ; il n'observe pas les lanes actives.
- L'enregistrement de production NET-003 figé établit les indicateurs de phase du brouillon à une révision donnée. Une modification ultérieure peut les changer ; relisez donc la source exacte et les preuves de révision avant d'agir.
- `semantic backpressure`, le graphe de dépendances, la notation et le benchmark sont des concepts proposés. Ils exigent une véritable comparaison de référence, des limites d'autorité explicites, des essais d'apprenants, une traduction, un aperçu Learn et une consultation publique avant toute approbation opérationnelle ou pédagogique. Lors du cycle source anglais antérieur, la traduction faisait encore partie des travaux à réaliser ; ce brouillon français attend l'approbation d'une personne maîtrisant le français. Une révision contradictoire indépendante par IA a identifié et provoqué des corrections aux hypothèses du graphe et du pilote ; elle ne remplace pas une révision humaine disciplinaire.
