---
title: Répéter un remplacement d’agent sans perdre les preuves
description: Répéter un remplacement d’agent sans perdre les preuves — Futurologie
sidebar:
  label: FUT-003 · Répéter un remplacement d’agent sans perdre les preuves
  order: 3
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/futurology/fr/fut-003-agent-substitution-readiness-drill.fr.md
---

:::note[Streeling University]
**FUT-003** · Répéter un remplacement d’agent sans perdre les preuves · early-intermediate · 35 minutes

Généré par le département *Futurologie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/futurology/fr/fut-003-agent-substitution-readiness-drill.fr.md) · [Mon journal](../../journal/)

Prérequis: [FUT-002](../../futurology/fut-002-routing-embedder-revisit-triggers/)
:::

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques de traductions encore à rédiger, d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/representation-release-2026-10-22/README.md) décrit les brouillons de traduction actuels, l’importation et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Périmètre de l'outillage historique.** La PR Learn #170 a été fermée sans fusion le 2026-10-21. Son expérience d'utilitaire de reçus est absente de l'outillage Learn actuel. La rédaction actuelle des cours EN/FR/ES se fait dans Learn `streeling/courses/`. L'expérience historique ne fournit que des preuves dans les sources ; elle n'établit ni révision humaine, ni résultat d'apprenant, ni pipeline actuel de reçus.

> **Département de futurologie** | Niveau début intermédiaire | 35 minutes | Brouillon français ; révision humaine du contenu, essai par un apprenant et révision par une personne maîtrisant le français en attente

## Objectifs et question du projet

Vous apprendrez à définir un petit contrat de capacités, à évaluer un exercice synthétique de remplacement d'agent et à rédiger un déclencheur mesurable de réexamen du dispositif actuel. **Question du projet :** si un agent ou un outil plus capable apparaît pendant la période pré-AGI, comment GA et Streeling peuvent-ils l'essayer sans perdre les preuves qui rendent son travail révisable et publiable ? Cette leçon ne prédit pas l'arrivée d'un tel système. Elle traite un nouvel agent comme une implémentation candidate d'un workflow aux sorties observables.

Le [guide GA d'ingénierie agentique au commit `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/methodology/agentic-engineering.md) recommande d'améliorer le harness, de garder des frontières claires entre modules, d'utiliser des files bornées et de rendre la révision efficace. Ce sont des choix de conception du projet, pas la preuve que les agents sont aujourd'hui interchangeables. [FUT-002](../../futurology/fut-002-routing-embedder-revisit-triggers/) demande quand GA devrait rouvrir une décision sur son embedder de routage. Ici, nous élargissons la question à *l'agent qui effectue une tâche de cours* et aux preuves qu'il doit transmettre à l'étape suivante. La décision reste réversible : comparer un candidat sur un petit ensemble représentatif de tâches avant de changer la lane habituelle.

## 1. Définir ce qui doit survivre au remplacement

Imaginez qu'un agent rédige ou modifie une leçon Streeling. La personne ou l'agent suivant doit savoir exactement quelles sources ont été vérifiées, quels tests ont été exécutés, ce qu'un humain a révisé et ce que le site public sert réellement. Le [générateur de candidats à la révision au commit Demerzel `74d425d`](https://github.com/GuitarAlchemist/Demerzel/blob/74d425dcd2ad92b4712160e3f5df7b2472c12b97/scripts/streeling_review_candidates.py), à l'état de brouillon, indexe les blobs Git des sources pour le triage ; sa sortie ne donne explicitement aucune approbation humaine. L'[expérience historique de reçus Learn au commit `02fc08c`](https://github.com/spareilleux/learn/tree/02fc08c8f73e017412d1a623415ac4ab08645eb0) explorait la transmission de l'identité exacte des sources aux pages rendues. Aucune des deux expériences ne prouve une transmission de bout en bout en production.

Une interface **proposée** utile entre les étapes est :

```text
Draft(source_revision, artifact)
  -> Checked(same_source_revision, named_checks)
  -> HumanReviewed(same_source_revision, reviewer_verdict)
  -> PublicReadback(same_source_revision, URL, observation)
```

Cette notation est une esquisse pédagogique, **pas un DSL implémenté ni une garantie fournie par les noms de types**. Une véritable frontière exige une provenance authentifiée et des vérifications rejouables. L'agent rédacteur ne peut pas produire `HumanReviewed` simplement en émettant ce mot ; le réviseur et le verdict doivent provenir d'un processus humain autorisé. `PublicReadback` exige de récupérer la page déployée à la révision visée. Si une leçon change après révision, l'ancien verdict ne s'applique pas automatiquement aux nouveaux octets.

Pour un essai de portée limitée, exigez au moins ces observations par tâche : identité des sources d'entrée ; identités de sortie et de cible de révision ; compilation et vérifications ciblées nommées ; résultat d'une révision humaine ; relecture publique anonyme ; durée écoulée ; corrections nécessaires. Ce sont des champs candidats d'acceptation, pas des affirmations selon lesquelles les agents ou le site actuels les enregistrent déjà tous. Un modèle plus puissant peut encore nécessiter un autre prompt ou adaptateur d'outil. Le contrat porte sur un comportement vérifiable à la frontière, pas sur un raisonnement interne identique.

### Exercice pratique 1

La sortie indique `fixture-A-v2`, tandis que l'entrée et la cible de révision synthétique indiquent `fixture-A-v1`. La compilation réussit. L'ancien verdict peut-il autoriser la publication de cette sortie ? Que doit-il se passer ensuite ?

> **Réponse :** Non. Les identités des sources révisées et produites diffèrent ; l'ancien verdict ne couvre donc pas la sortie modifiée. Examinez la modification et obtenez un verdict lié aux nouvelles sources exactes avant publication. Une compilation réussie vérifie une autre propriété.

## 2. Exécuter un exercice synthétique volontairement petit

La [fixture et l'évaluateur figés au commit Demerzel `7892390`](https://github.com/GuitarAlchemist/Demerzel/tree/789239053dfeca9f044d2f893a3f277cb4ed9d8d/state/streeling/fixtures/futurology/fut-003) contiennent quatre adaptateurs imaginaires et les mêmes trois cas étiquetés `A`, `B` et `C`. Chaque ligne comporte des étiquettes pour les sources, la sortie et la cible de révision, un verdict, trois vérifications nommées, une durée en minutes et un nombre de corrections. Toutes les chaînes `approved` sont des **valeurs fictives de fixture**, pas des reçus de révision humaine. La chaîne `public_readback` est elle aussi une vérification de fixture, pas une récupération du site. Exécutez `python state/streeling/fixtures/futurology/fut-003/evaluate_drill.py` depuis la racine Demerzel pour reproduire le tableau.

| Adaptateur synthétique | Cas admissibles | Minutes médianes, seulement si tous les cas passent | Corrections, seulement si tous les cas passent | Raison de conserver ou rejeter |
|---|---:|---:|---:|---|
| `current` | 3/3 | 40 | 2 | Référence de comparaison |
| `portable` | 3/3 | 32 | 2 | Candidat à un essai plus vaste |
| `fast` | 1/3 | non rapportées | non rapportées | A change l'identité des sources ; B n'a pas de relecture publique |
| `shortcut` | 0/3 | non rapportées | non rapportées | Les trois verdicts de révision sont en attente |

L'évaluateur traite l'identité des sources, le résultat de révision et les vérifications requises comme des **contrôles impératifs**. Il ne rapporte une médiane que pour un adaptateur qui réussit tous les cas comparables. Cela évite de valoriser une exécution rapide qui a sauté la partie coûteuse de la livraison. Les mêmes cas et les mêmes contrôles rendent la comparaison synthétique cohérente en interne, mais trois tâches inventées ne disent rien de la fiabilité réelle des modèles, du coût des outils, de la valeur pour les apprenants ou des gains de temps attendus. L'écart calculé, `40 - 32 = 8` minutes, n'est qu'un résultat de fixture.

### Exercice pratique 2

L'adaptateur `fast` termine le cas B en 16 minutes. Ses étiquettes de sources concordent et son verdict synthétique indique `approved`. Pourquoi B est-il rejeté, et combien des trois cas de `fast` sont admissibles ?

> **Réponse :** Il manque au cas B la vérification requise `public_readback`. Le cas A a une incohérence d'identité des sources ; seul C passe. `fast` est donc admissible à hauteur de 1/3. La fixture ne prouve qu'une véritable page est publique dans aucun cas, même C.

### Exercice pratique 3

Calculez les médianes de `current` (`40, 44, 39`) et de `portable` (`31, 32, 34`). Quel est leur écart, et quelle affirmation de performance resterait injustifiée ?

> **Réponse :** Les valeurs triées sont `39, 40, 44` et `31, 32, 34`, soit des médianes de 40 et 32 minutes. L'écart est de huit minutes synthétiques. Il serait injustifié d'annoncer un gain réel de huit minutes, un coût monétaire inférieur ou une meilleure fiabilité sans exécuter des cas réels comparables et consigner toute la chaîne de preuves.

## 3. Choisir un déclencheur et un critère de réfutation avant de changer

Un **déclencheur si/alors** est plus utile que « changer quand l'IA devient meilleure ». Par exemple : *si un adaptateur candidat passe les mêmes contrôles de sources, de révision, de vérification et de relecture publique sur un ensemble annoncé à l'avance de tâches GA/Streeling réelles, alors lancer une comparaison limitée ; n'élargir que si les résultats publics acceptés et l'effort de révision s'améliorent sans hausse du taux de correction.* Le seuil et le mélange de tâches doivent être choisis avant d'examiner les résultats. On pourrait commencer par autant de tâches audio, DSL et de publication de cours, mais cette répartition est une proposition de protocole d'essai, pas une taille d'échantillon validée.

Le contre-argument le plus fort est qu'une interface commune peut masquer des différences importantes. Un agent peut avoir besoin d'un autre contexte, d'autres permissions ou d'autres prompts ; imposer des instructions identiques peut le handicaper. L'essai devrait garder des **contrôles de résultat identiques** tout en autorisant une préparation propre à chaque adaptateur et documentée. Consignez le temps consacré à la préparation, à la révision humaine, aux nouvelles tentatives et aux réparations. Si un gain de vitesse apparent disparaît une fois ces coûts inclus, le remplacement n'est pas une amélioration opérationnelle. Si un nouvel agent peut rédiger davantage de cours, mais que les verdicts humains et les relectures publiques correctes stagnent, l'objectif de cours de bout en bout n'a pas accéléré.

L'alternative la plus simple est de garder l'agent actuel et d'améliorer un vérificateur ou un dossier de révision. Rejetez l'hypothèse de remplacement si un essai comparable échoue à un contrôle impératif, augmente le taux de correction ou n'apporte aucun gain durable de travaux correctement révisés et relus publiquement. L'échec d'une tâche peut appeler un diagnostic plutôt qu'une exclusion définitive ; une sortie non révisée ne peut pas être promue en la moyennant avec des tâches réussies. Le relevé de décision devrait inclure le commit et le blob des sources, la classe de tâche, la version de l'évaluateur, l'identité du réviseur, la relecture du site, l'environnement et la durée écoulée. Le coût et la latence sont des mesures à ajouter, pas des valeurs à inventer.

### Exercice pratique 4

Supposez qu'un véritable agent de remplacement rédige 20 leçons là où l'agent actuel en rédige 10 pendant la même période, mais que les approbations humaines et les relectures publiques correctes restent toutes deux à quatre. Quelle mesure s'est améliorée, quel résultat n'a pas changé et quel travail pourrait aider d'abord ?

> **Réponse :** Le débit de brouillons a doublé. Les approbations authentifiées et les relectures publiques correctes restent à quatre ; cette observation ne montre donc pas une livraison plus rapide de cours utilisables. Examinez la charge de révision, les dossiers liés aux sources, la publication et la relecture avant d'ajouter de la capacité de rédaction. Comparez les corrections et les résultats des apprenants comme garde-fous.

### Exercice pratique 5

Rédigez une courte décision pour l'adaptateur synthétique `portable` : que peut étayer la fixture, qu'est-ce qui déclencherait un véritable essai, et quel résultat réfuterait un changement ?

> **Réponse :** La fixture n'étaye que le fait que `portable` passe les trois cas *simulés* à contrôles impératifs et présente une médiane de 32 minutes synthétiques contre 40 pour `current`. Un véritable essai est déclenché par un candidat disponible capable de produire les preuves requises sur un ensemble représentatif de tâches annoncé à l'avance, avec les mêmes contrôles de résultat. L'absence de préservation de l'identité exacte des sources ou des preuves humaines/publiques, ou l'absence de gain durable de sorties acceptées après prise en compte du temps de préparation et de correction, réfuterait un changement. La fixture seule n'autorise aucune modification de production.

## Sources, limites et prochaine vérification

Le contexte du projet provient du [guide GA du harness et des files](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/methodology/agentic-engineering.md) figé, du [générateur de triage Demerzel](https://github.com/GuitarAlchemist/Demerzel/blob/74d425dcd2ad92b4712160e3f5df7b2472c12b97/scripts/streeling_review_candidates.py) et de l'[expérience historique de reçus Learn liés aux sources exactes](https://github.com/spareilleux/learn/tree/02fc08c8f73e017412d1a623415ac4ab08645eb0). Les [entrées, évaluateur et résultats](https://github.com/GuitarAlchemist/Demerzel/tree/789239053dfeca9f044d2f893a3f277cb4ed9d8d/state/streeling/fixtures/futurology/fut-003) sont synthétiques et reproductibles au commit `789239053dfeca9f044d2f893a3f277cb4ed9d8d`. L'esquisse est un contrat composable proposé, pas un DSL déployé. Aucune exécution réelle d'un autre agent, aucun verdict humain authentifié, essai d'apprenant, changement de production ou relecture publique du cours n'a été effectué pour FUT-003. Dans le cycle anglais d'origine, la prochaine vérification était une révision humaine du scénario et un essai à l'aveugle par un apprenant avant localisation ou publication. Ce brouillon français attend ces révisions et une révision linguistique humaine avant publication.
