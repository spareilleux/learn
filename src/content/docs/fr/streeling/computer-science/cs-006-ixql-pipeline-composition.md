---
title: Composer des étapes IXQL avec des limites de preuve explicites
description: Composer des étapes IXQL avec des limites de preuve explicites — Informatique
sidebar:
  label: CS-006 · Composer des étapes IXQL avec des limites de preuve explicites
  order: 6
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/fr/cs-006-ixql-pipeline-composition.fr.md
---

:::note[Streeling University]
**CS-006** · Composer des étapes IXQL avec des limites de preuve explicites · intermédiaire · 35 minutes

Généré par le département *Informatique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/fr/cs-006-ixql-pipeline-composition.fr.md) · [Mon journal](../../journal/)

Prérequis: [CS-005](../../computer-science/cs-005-agent-handoff-evidence-contract/)
:::

> **Périmètre du brouillon et des traductions.** Le texte technique ci-dessous est un brouillon daté. Les mentions historiques de traductions, d’intégration dans Learn ou de vérifications de publication encore à faire concernent cette étape antérieure ; ce [dossier de traduction](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/locale-completion-2026-10-22/README.md) recense les brouillons actuels et les contrôles effectués. Les essais en conditions réelles encore non réalisés le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département d'informatique** | Niveau intermédiaire | 35 minutes | Brouillon français ; révision du contenu, essai par un apprenant et révision linguistique humaine en attente

## Objectifs

Vous apprendrez à lire un pipeline IXQL versionné comme une séquence de contrats d'étape, à nommer l'entrée, la sortie et l'éventuel effet externe de chaque étape et à proposer une vérification réfutable à la frontière d'une branche. La question du projet est pratique : **comment des agents GA, Demerzel, IX et TARS peuvent-ils discuter d'un même workflow allant de la recherche au cours sans confondre une étape déclarée avec un résultat exécuté ?**

## 1. Lire la composition existante

La [grammaire IXQL de Demerzel au commit `0220ca8`](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/grammars/sci-ml-pipelines.ebnf) décrit les étapes et le flux des pipelines. Dans sa section d'orchestration MCP, `identifier <- mcp_step` lie un résultat, `→` enchaîne les étapes, `parallel(...)` regroupe des appels d'outils et `when` introduit une garde. Sa section d'entrées-sorties nomme des opérations telles que `ix.io.read`, `ix.io.write` et `ix.io.append`. Ce sont des constructions du langage source ; elles n'établissent pas qu'un pipeline particulier a été exécuté.

L'[exemple figé allant de la recherche au cours](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/examples/ixql/research-to-course.ixql) commence par lire les départements et les poids, sélectionne un département, charge le contexte, échantillonne une question, mène une investigation, évalue une conclusion et écrit conditionnellement un cours. Il écrit ensuite un journal de cycle de recherche et décrit la capitalisation des acquis. Lisez les flèches comme un **flux de dépendances prévu** : l'étape suivante exige un résultat de la précédente. Lisez `ix.io.read(...)`, `write(...)` et `ix.io.append(...)` comme des effets déclarés aux frontières. Un échantillonnage de grammaire, une réponse de modèle ou une écriture de fichier pourrait échouer ; la notation seule ne montre pas le résultat.

Pour la discussion humaine, annotons trois lignes réelles de l'exemple :

```ixql
departments <- ix.io.read("state/streeling/departments/*.department.json")
question <- dept_context
  → tars.grammar.sample(grammar: dept_context.grammar, weights: dept_context.weights, pattern: "investigation")
  → tars.formulate_question(research_area: department.research_areas)
course <- when conclusion.conclude == "confirm":
  investigation → tars.produce_course(...) → tars.validate_schema(...) → write(...)
```

Les arguments abrégés ci-dessus constituent un **extrait explicatif**, pas un remplacement exécutable du fichier versionné. La première ligne déclare une lecture de fichiers. La chaîne centrale déclare une question dérivée du contexte chargé. La dernière branche déclare la production d'un cours uniquement pour une conclusion `confirm`, avec une écriture après validation. L'exemple précise lui-même le chemin et le schéma du cours ; consultez ses lignes complètes pour connaître ces valeurs exactes.

### Exercice pratique 1

Dans la première ligne, qu'est-ce qui est lié à `departments`, et quelles preuves établiraient la réussite de la lecture lors d'une véritable exécution ? La ligne fournit-elle elle-même ces preuves ?

> **Réponse :** Elle lie le résultat déclaré de la lecture des fichiers JSON de départements correspondant au chemin. Une véritable exécution exigerait une trace ou un reçu montrant les chemins résolus, les révisions ou empreintes d'entrée, la réussite ou l'échec et la structure renvoyée. La ligne décrit la lecture, mais ne fournit aucune de ces preuves d'exécution.

## 2. Donner une entrée et une sortie à chaque étape

Une transmission entre agents est plus claire lorsqu'elle contient une petite fiche d'étape. Le tableau ci-dessous est une **annotation pédagogique de l'exemple**, pas un nouveau système de types ou une nouvelle syntaxe IXQL :

| Étape | Entrée requise | Sortie proposée à examiner | Effet déclaré ou incertitude |
|---|---|---|---|
| Sélection du département | fichiers de départements et de poids | département sélectionné et entrées du calcul de score | lectures de fichiers ; la sélection peut échouer si les fichiers sont absents ou mal formés |
| Formation de la question | grammaire du département, poids, liste des cours existants | question accompagnée de son contexte source | lectures du contexte et appels TARS ; l'évitement des doublons est déclaré, pas prouvé |
| Investigation | question | constats des sources et résultat de validation croisée | appels de modèles/MCP ; toute source indisponible doit être consignée |
| Conclusion | preuves d'investigation | `conclude`, croyance, confiance | décision de branche ; les seuils de cet exemple sont des propositions à examiner |
| Production du cours | conclusion confirmative et investigation | brouillon de cours validé | écriture conditionnelle dans Streeling ; aucune révision ou publication ne suit automatiquement |
| Enregistrement du cycle | conclusion, réflexion, cours, proposition de grammaire | JSON du cycle de recherche | écriture de fichier ; une chaîne de chemin n'est pas un reçu persisté |

Cette annotation donne un vocabulaire partagé aux agents qui coopèrent. Le producteur peut dire « j'ai produit une question à partir de ces entrées » et renvoyer à ses preuves. Le destinataire peut vérifier que question, contexte et révision correspondent avant de lancer l'investigation. Les inconnues explicites lui permettent de s'arrêter à la frontière en échec au lieu de répéter toutes les étapes antérieures. Pour toute étape, consignez **révision des sources, identité de l'entrée, identité de la sortie, statut, effets tentés et prochaine action**. Il s'agit d'une enveloppe de communication suggérée, en prose ordinaire ou dans un reçu ; la grammaire examinée ne définit pas ces champs comme une construction IXQL.

### Exercice pratique 2

L'exemple versionné utilise `dept_context <- parallel(...)` pour lire un fichier de département, les poids, la grammaire et les cours anglais existants. Peut-on considérer `question <- dept_context → tars.grammar.sample(...)` comme achevé indépendamment si la lecture de la grammaire a échoué ?

> **Réponse :** Non. L'étape de question nomme `dept_context.grammar` comme entrée. Une lecture de grammaire échouée laisse une entrée requise indisponible. Signalez l'échec de lecture et laissez la question non résolue, ou relancez depuis un contexte vérifié. Ne déduisez pas un échantillonnage valide de la présence de la ligne `question <-`.

### Exercice pratique 3

Classez ces opérations de l'exemple comme effets observables de l'extérieur ou transformations proposées : `ix.io.read`, `tars.grammar.sample`, `tars.cross_validate`, `write(course path, markdown)` et `ix.io.append(grammar path, new_production)`. Lesquelles peuvent modifier les octets du dépôt ?

> **Réponse :** `ix.io.read` est un effet externe de lecture ; `tars.grammar.sample` et `tars.cross_validate` sont des appels d'outils ou de modèles dont le comportement et les sorties nécessitent des observations : cette leçon ne les qualifie donc pas de purs. `write` et `ix.io.append` sont des effets d'écriture déclarés qui peuvent modifier les octets du dépôt. Un échantillonnage ou une validation réussis n'impliquent aucune des deux écritures.

## 3. Placer un critère de réfutation à la branche

L'exemple indique `course <- when conclusion.conclude == "confirm": ... → write(...)`. Voici une **fixture fixe de raisonnement**, pas le compte rendu d'une véritable exécution IXQL :

```text
input: conclusion = { conclude: "refute", belief: "F", confidence: 0.81 }
pre-run course path: absent
expected stage result: no course draft produced; no course-path write
observable check for a test harness: compare file existence and write trace before/after
```

Cette fixture rend l'affirmation de branche réfutable. Si le harness enregistre une écriture au chemin du cours pour cette entrée, la règle de branche ou son implémentation a échoué. Si aucun fichier n'apparaît, cela n'étaye que ce cas ; cela n'établit pas que la confirmation, la validation, la traduction ou la révision fonctionne. Conservez l'entrée et la trace des effets pour qu'un second agent reproduise la conclusion. Le seuil `confirm` et la qualité du cours généré sont des questions distinctes.

### Exercice pratique 4

Pour la fixture `refute` fixe, donnez la sortie attendue et une observation qui réfuterait la règle de branche. Une variable de cours vide prouverait-elle à elle seule que l'écriture n'a pas eu lieu ?

> **Réponse :** Résultat attendu : aucun cours produit et aucune écriture au chemin du cours. Une trace montrant un appel à `write(...)`, ou un nouveau fichier à ce chemin attribuable à l'exécution, réfuterait la règle. Une variable vide seule ne suffit pas, car un effet pourrait avoir précédé un échec ultérieur ; examinez la trace d'écriture et l'état du système de fichiers.

## 4. Communiquer ce qui a été vérifié

Le [validateur JavaScript figé](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/scripts/ixql-validate.js) du dépôt se présente comme un validateur structurel minimal, pas un analyseur complet. Il découpe les fichiers de `pipelines/` en tokens, recueille les liaisons et les noms des contrôles, puis signale les problèmes. Un rapport de validation sans problème peut étayer une affirmation limitée sur la structure des sources. Il ne peut pas prouver qu'un appel TARS a abouti, qu'un cours a été écrit ou que ce cours a passé une révision avec un apprenant. La [spécification de composition de l'interface IXQL](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/docs/ixql-ui-composition-spec.md) est marquée comme issue d'une réflexion et prête à être implémentée ; cette leçon ne revendique aucune exécution d'éditeur ou d'interface.

Lors de la transmission du pipeline à un autre agent, envoyez une fiche d'étape comprenant le fichier et la révision figés, l'étape exacte, l'identité des artefacts d'entrée, le résultat observé ou l'inconnue explicite, tout reçu d'écriture et une prochaine action de portée limitée. [CS-005](../../computer-science/cs-005-agent-handoff-evidence-contract/) développe le contrat général de transmission. La discipline supplémentaire consiste ici à garder visibles dépendances et effets à chaque étape IXQL. Un exemple source, un résultat d'analyse syntaxique, une trace d'exécution, une leçon révisée et une page publiée sont des artefacts différents avec des exigences de preuve différentes.

### Exercice pratique 5

Un agent annonce : « `research-to-course.ixql` a passé `scripts/ixql-validate.js`, donc la nouvelle leçon Streeling est publiée. » Corrigez l'affirmation et nommez les deux prochaines vérifications.

> **Réponse :** L'affirmation étayée est au plus que le validateur n'a trouvé aucun problème structurel dans les fichiers parcourus. Son script parcourt `pipelines/`, alors que `research-to-course.ixql` se trouve dans `examples/ixql/` ; cette commande n'établit donc même pas la vérification de cet exemple, sauf si un autre appel explicite l'a fait. Vérifiez ensuite l'exemple exact avec un analyseur ou test adapté et une révision figée ; puis examinez un véritable reçu d'exécution et les relevés de révision et de publication de la production du cours avant d'annoncer une livraison. Une déclaration source ne peut pas remplir ces relevés.

## Sources et limites

La grammaire, l'exemple, le validateur et la spécification d'interface sont figés au commit Demerzel `0220ca84a25f59973bd6b9236cc00b7f68631a50`. Cette leçon vérifie leur texte source et utilise une fixture synthétique de branche ; elle n'exécute pas IXQL, ne teste pas d'éditeur IX, n'observe pas l'exécuteur IX et ne valide pas l'exemple comme exécutable. Le parcours de traduction en cinq langues et d'écriture automatique du cours décrit dans l'exemple est un flux prévu ; il ne prouve pas que ce brouillon CS-006 a été traduit, révisé ou publié. L'exactitude du contenu, la réussite de la tâche par un apprenant et la révision linguistique humaine de ce brouillon français restent ouvertes.
