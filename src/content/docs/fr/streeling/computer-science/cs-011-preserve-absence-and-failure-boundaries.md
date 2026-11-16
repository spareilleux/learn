---
title: Préserver la distinction entre absence et échec
description: Préserver la distinction entre absence et échec — Informatique
sidebar:
  label: CS-011 · Préserver la distinction entre absence et échec
  order: 11
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/fr/cs-011-preserve-absence-and-failure-boundaries.fr.md
---

:::note[Streeling University]
**CS-011** · Préserver la distinction entre absence et échec · intermédiaire · 45 minutes

Généré par le département *Informatique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/fr/cs-011-preserve-absence-and-failure-boundaries.fr.md) · [Mon journal](../../journal/)

Prérequis: [CS-010](../../computer-science/cs-010-compose-fail-fast-ga-computations/)
:::

> **Périmètre du brouillon.** Expérience fondée sur le code source du projet, avec des entrées synthétiques. La revue du contenu par une personne, la révision linguistique par une personne maîtrisant la langue et la revue par un apprenant restent à effectuer ; aucune publication ni vérification publique du cours par relecture n'est revendiquée.

## Objectifs et question pour le projet

Distinguer une valeur manquante, une valeur présente mais invalide et une exception d'infrastructure ; choisir une conversion qui conserve les informations nécessaires pour réparer un flux de travail GA. **Question pour le projet :** comment un pipeline devrait-il signaler « aucun artefact fourni » sans le confondre avec « un artefact a été fourni mais sa validation a échoué » ou « l'opération de stockage a levé une exception » ?

Utilisez le [module GaAsync](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/GaAsync.fs) de GA à la révision fixée. Il définit les cas de `GaError`, dont `DomainError`, `IoError`, `AgentError` et `PartialFailure`, et fournit `ofOption` et `fromAsync`. Ses valeurs utilisent les types standard [option de F#](https://learn.microsoft.com/dotnet/fsharp/language-reference/options) et [result de F#](https://learn.microsoft.com/dotnet/fsharp/language-reference/results). Il ne s'agit pas d'une exécution des implémentations C# distinctes `Option` ou `Try` de GA.

## 1. La présence n'est pas la validité

Une option indique si une valeur est présente : `Some value` ou `None`. `Some 0` est présent même si une règle de domaine ultérieure rejette zéro. Dans ce scénario de test, `ofOption (DomainError "missing-note") (Some 0)` produit `Ok 0` ; le passage par une fonction de validation exigeant un entier positif produit `Error (DomainError "nonpositive-note")`. Les noms d'erreur désignent des actions correctives différentes : fournir l'entrée manquante ou corriger l'entrée fournie.

La règle numérique est un choix pédagogique, pas une règle de théorie musicale. Zéro peut avoir un sens dans une représentation des classes de hauteurs. Avant d'adopter un validateur dans GA, identifiez la représentation réelle du domaine et la plage acceptée. Ce scénario utilise volontairement des entiers pour permettre d'examiner la conversion indépendamment d'un analyseur musical.

### Exercice pratique 1

Pour la règle du scénario fourni, « l'entier doit être positif », classez `None`, `Some 0` et `Some 5` après conversion de l'option et validation. Pourquoi classer chaque zéro comme « manquant » ferait-il perdre de l'information ?

> **Réponse :** `None` devient `DomainError "missing-note"` ; `Some 0` devient `DomainError "nonpositive-note"` après validation ; `Some 5` réussit avec 5. Qualifier zéro de manquant confond une valeur fournie avec l'absence de valeur et peut orienter l'opérateur vers la mauvaise correction. Cela importe aussi la règle du scénario dans des représentations où zéro peut être valide.

## 2. Préciser l'erreur lors de la conversion d'une absence

Le `ofOption` de la révision fixée accepte un argument d'erreur et une option. Il transforme `Some x` en `Ok x` et utilise l'erreur fournie pour `None`. L'option elle-même ne contenait pas de raison. La conversion introduit donc un contexte choisi par l'appelant ; elle ne peut pas récupérer un échec initial dont l'information a déjà été supprimée.

À une frontière envisagée pour la recherche d'artefacts, un artefact absent pourrait devenir `DomainError "missing-artifact"`. C'est un exemple pédagogique, pas la preuve que ce module lit un système de fichiers ou la boîte de réception d'un agent. Une recherche susceptible d'échouer en raison d'un accès refusé ou d'une perte de transport nécessite un résultat plus riche avant la conversion d'option, au risque de masquer la cause de l'échec.

### Exercice pratique 2

Deux recherches renvoient `None` : l'une signifie qu'aucun artefact n'est configuré, l'autre a été obtenue en supprimant une erreur de transport. `ofOption` peut-il déduire ce qui s'est passé ? Que devrait conserver cette frontière ?

> **Réponse :** Non. Il ne voit que `None` et l'erreur fournie par son appelant. Conservez un résultat ou un autre état explicite distinguant l'absence de l'échec du transport avant de supprimer ce détail. Nommer chaque `None` « manquant » dissimulerait le problème de transport.

## 3. Mesurer une projection avec perte d'information

Le programme d'exécution convertit `Error "missing-note"` et `Error "invalid-pitch"` en options F# standard avec `Result.toOption`. Son observation consignée est `[None; None]`. Les deux causes distinctes ont désormais la même représentation. C'est un cas concret de correspondance plusieurs-vers-un : un consommateur ultérieur ne peut pas reconstituer le message qui existait à partir de `None` seul.

Une telle projection peut convenir lorsque le consommateur n'a réellement besoin que de la présence. Elle ne convient pas à une file de réparation dont l'action suivante dépend de la cause. Conserver indéfiniment chaque diagnostic a aussi un coût ; gardez les informations requises par le contrat du consommateur plutôt que d'ériger la journalisation maximale en règle universelle.

### Exercice pratique 3

Un worker de nouvelle tentative ne voit que le `None` projeté de l'une ou l'autre erreur. Peut-il décider de manière sûre de retenter le transport réseau ? Proposez une interface correcte plus simple pour cette décision.

> **Réponse :** Il ne peut déduire de cette option ni un échec de transport ni la possibilité d'une nouvelle tentative. Conservez la catégorie d'erreur initiale et les éléments probants pertinents dans un résultat, puis laissez une politique explicite de nouvelle tentative les examiner. Une décision booléenne de nouvelle tentative pourrait aussi être fournie par une politique en amont, à condition que son périmètre et ses éléments probants restent disponibles pour audit.

## 4. Convertir une exception à une frontière nommée

Le `fromAsync` de GA attend un calcul asynchrone dans un bloc `try` et convertit une exception interceptée en `GaError.IoError`, en conservant son message et `Some ex`. Le laboratoire lève délibérément `System.IO.IOException` avec le message `"fixture-io"` à l'intérieur de cette frontière. L'erreur observée conserve à la fois le message et le type d'exception. Aucune panne de disque n'est provoquée ; il s'agit d'un scénario d'exception intentionnel.

Le nom du cas ne prouve pas que la cause relève des E/S. Une autre exception interceptée par cette enveloppe générale reçoit elle aussi le cas `IoError`. L'appelant doit choisir honnêtement la frontière et examiner la cause conservée. Cette expérience ne revendique aucune garantie de sûreté concernant l'annulation : la transmission de l'annulation et la gestion des exceptions nécessitent leur propre contrat et leurs propres tests.

### Exercice pratique 4

Si une exception de programmation issue d'un calcul est enveloppée par `fromAsync`, le `IoError` résultant prouve-t-il que le stockage est défaillant ? Quelle partie de la valeur renvoyée pourrait aider à distinguer la cause ?

> **Réponse :** Non. L'enveloppe attribue ce cas aux exceptions interceptées, quelle que soit l'origine réelle de l'opération. L'exception conservée et son message peuvent aider à en rechercher la cause. Évitez de diagnostiquer un problème de stockage à partir du seul nom du cas de l'union.

### Exercice pratique 5

Un agent propose de convertir chaque échec en `None` avant de transmettre le travail à un agent de réparation, affirmant qu'un message plus petit est toujours préférable. Indiquez un critère de réfutation et une comparaison minimale utilisant ce scénario.

> **Réponse :** Comparez les décisions de réparation pour `missing-note` et `invalid-pitch` lorsque les deux causes sont connues, puis recommencez après projection vers `[None; None]`. Si la deuxième interface ne peut pas sélectionner les deux corrections requises sans recherche supplémentaire, l'affirmation selon laquelle elle conserve assez d'information est réfutée. Mesurez la taille du message et les recherches supplémentaires par rapport à un résultat contenant la catégorie nécessaire ; une charge utile plus petite ne suffit pas à établir qu'un flux de travail est meilleur.

## Reproduire l'expérience du projet

Utilisez le [laboratoire pédagogique partagé](https://github.com/spareilleux/learn/blob/main/code/streeling/functional-composition/README.md), qui charge une copie inchangée du module de GA à la révision fixée et en conserve la licence MIT. [F# Interactive](https://learn.microsoft.com/dotnet/fsharp/tools/fsharp-interactive/) exécute le laboratoire sans référence à des packages NuGet. Depuis la racine du dépôt Learn, la commande s'écrit de la même façon sous Windows, Linux/WSL et macOS :

```text
dotnet fsi --exec code/streeling/functional-composition/exercise.fsx
```

L'auteur a observé le SDK `10.0.113` sous Windows, un code de sortie 0, aucun avertissement du compilateur et 24 assertions réussies. Les autres systèmes d'exploitation restent à vérifier. Le [compte rendu d'expérience](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/functional-composition-2026-10-22/README.md) distingue la provenance des entrées, l'exécution et la revue. Il s'agit d'entrées synthétiques exécutées par le véritable module à la révision fixée, pas de trafic capturé de l'application GA. Lisez le dossier apprenant avant d'ouvrir le programme d'exécution, qui contient les réponses.

## Éléments probants et prochaine vérification

Le module GA immuable et ses tests existants constituent le cas d'étude fondé sur le code source ; les observations consignées du laboratoire établissent uniquement ses entrées exécutées. Ne comptez pas une revue statique par IA comme une approbation humaine. Une personne chargée de la revue devrait confronter les affirmations au code source de la révision fixée ; un apprenant devrait ensuite tenter de résoudre le dossier séparé avec l'aide du code source avant de consulter les réponses. L'intégration, le déploiement et la vérification publique anonyme par relecture restent des étapes distinctes.
