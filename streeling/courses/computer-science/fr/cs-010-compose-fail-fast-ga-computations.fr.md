---
module_id: cs-010-compose-fail-fast-ga-computations
department: computer-science
course: "Composer des calculs GA avec arrêt au premier échec"
level: intermediate
prerequisites: ["cs-004-composable-agentic-audio-loop"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Composer des calculs GA avec arrêt au premier échec

> **Périmètre du brouillon.** Expérience fondée sur le code source du projet, avec des entrées synthétiques. La revue du contenu par une personne, la révision linguistique par une personne maîtrisant la langue et la revue par un apprenant restent à effectuer ; aucune publication ni vérification publique du cours par relecture n'est revendiquée.

## Objectifs et question pour le projet

Composer un calcul dépendant avec les véritables opérations `GaAsync` de GA, prévoir quels rappels s'exécutent après une erreur et distinguer la réassociation algébrique de l'autorisation de réordonner les effets. **Question pour le projet :** comment un pipeline de guitare ou d'agents peut-il conserver la raison de l'échec d'un prérequis tout en empêchant le démarrage du travail qui en dépend ?

La source principale est le [module GaAsync de GA à la révision `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/GaAsync.fs). Son type `GaAsync<'T>` est `Async<Result<'T, GaError>>`. Ici, `Result` désigne le [type result de F#](https://learn.microsoft.com/dotnet/fsharp/language-reference/results), et non le type C# distinct `Result<TValue,TError>` de GA. Les [tests de fermetures existants de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.DSL.Tests/GaClosureAndCeTests.cs) vérifient déjà la propagation des erreurs précoces et leur transformation. Cette leçon exécute directement le module F# ; elle ne prétend pas que la suite NUnit complète a été exécutée.

## 1. Distinguer une transformation de valeur d'un calcul dépendant

À la révision fixée, `ok x` crée un résultat asynchrone réussi et `fail e` en crée un en échec. `map f` transforme une valeur réussie avec une fonction ordinaire. `bind f` accepte une fonction qui renvoie un autre calcul `GaAsync` et en propage le résultat. Sur un `Error`, les deux opérations conservent cette erreur et ignorent le rappel fourni. C'est une propriété locale du flux de contrôle d'une composition ; ce n'est pas une politique globale de planification des agents.

Le laboratoire commence avec 5. Sa première fonction liée double la valeur, la deuxième ajoute 1, puis son dernier map met en forme une étiquette. Le résultat observé par le programme d'exécution est `Ok "ready:11"` ; sa trace est `["double"; "increment"]`. Ces valeurs arithmétiques représentent les sorties de prérequis. Ce ne sont ni des fréquences de guitare, ni des scores de qualité, ni des attestations de revue acceptées.

### Exercice pratique 1

Prévoyez le résultat des mêmes fonctions en partant de 8. Quelle étape nécessite `bind`, et laquelle peut utiliser `map` ? Expliquez pourquoi la mise en forme de l'étiquette ne doit pas être confondue avec une approbation du résultat.

> **Réponse :** Le doublement et l'incrémentation donnent 17, donc la mise en forme donne `Ok "ready:17"`. Les fonctions du laboratoire qui renvoient `GaAsync` sont composées avec `bind` ; la fonction ordinaire de mise en forme peut utiliser `map`. Une étiquette mise en forme n'est qu'une valeur. Ni son texte ni la réussite d'un calcul ne confèrent une autorité de revue ou de publication.

## 2. Conserver le premier échec

Le cas interrompu commence par `Error (DomainError "invalid-pitch")`, puis compose les mêmes fonctions liées. Le résultat observé conserve exactement cette erreur de domaine et la trace des rappels est `[]`. Aucune valeur de remplacement réussie n'est insérée. L'action corrective reste ainsi visible, au lieu de convertir un prérequis en échec en un nombre plausible.

Une subtilité de lecture du code source compte : construire un calcul et l'exécuter sont deux opérations différentes. `GaAsync` utilise les [flux de travail asynchrones de F#](https://learn.microsoft.com/dotnet/fsharp/language-reference/async-expressions). Un rappel ignoré par `bind` n'est pas invoqué par ce bind, mais les effets produits avant la construction du pipeline ont déjà eu lieu. La trace mesure ces rappels du scénario de test ; elle ne prouve pas qu'un pipeline quelconque est exempt d'effets externes.

### Exercice pratique 2

Le premier prérequis renvoie `DomainError "missing-artifact"`. Le rappel suivant téléverse un artefact dérivé. Dans cette chaîne de `bind`, ce rappel est-il invoqué ? Un téléversement effectué avant la construction de la chaîne serait-il annulé ?

> **Réponse :** Le rappel est ignoré et l'erreur reste `DomainError "missing-artifact"`. Un téléversement antérieur n'est pas annulé. La composition avec arrêt au premier échec ne fournit ni transaction ni compensation des effets extérieurs au rappel ignoré.

## 3. Vérifier une loi avec une expérience délimitée

Pour des fonctions pures ayant les types indiqués, l'associativité de bind compare `(m |> bind f) |> bind g` à `m |> bind (fun x -> f x |> bind g)`. Les deux expressions conservent l'ordre `f` puis `g` ; la réassociation ne les permute pas. Le laboratoire utilise `validate`, qui rejette les entiers non positifs, et `format`, qui renvoie une étiquette réussie. Pour les entrées 5 et -1, les deux formes s'accordent respectivement sur `Ok "note:5"` et `Error (DomainError "nonpositive-note")`.

Deux exemples constituent des éléments probants pour ces cas, pas une preuve pour toutes les valeurs ou tous les effets de bord. Ils ne peuvent pas non plus établir l'équivalence des délais, de l'annulation, des nouvelles tentatives ou des durées de vie des ressources. Une amélioration utile issue de l'utilisation du projet consiste à formuler une prédiction de contre-exemple avant de modifier la chaîne, puis à conserver une prédiction démentie comme élément probant.

### Exercice pratique 3

Un collègue remplace `validate` puis `format` par `format` puis `validate` en invoquant l'associativité. S'agit-il de la même transformation ? Quelle entrée concrète révèle le problème ?

> **Réponse :** Non. L'associativité modifie le regroupement en préservant l'ordre ; cette proposition permute les opérations et change même leurs types d'entrée. Le cas initial -1 renvoie l'erreur de domaine avant la mise en forme. Une expression réordonnée doit d'abord passer la vérification des types et recevoir sa propre sémantique ; les deux concordances du scénario de test ne la justifient pas.

## 4. Ajouter du contexte sans transformer l'échec en réussite

Le `mapError` du laboratoire transforme `DomainError "invalid-pitch"` en `DomainError "wrapped: DomainError: invalid-pitch"`. Le cas réussi `Ok 42` reste inchangé et n'appelle pas la fonction de transformation d'erreur. Il s'agit d'une transformation explicite du canal d'erreur. Elle doit conserver assez de structure pour permettre l'action corrective suivante ; transformer sans cesse des erreurs structurées en prose peut détruire des champs utiles.

L'enveloppe textuelle de la leçon est volontairement réduite. Un véritable transfert entre agents devrait conserver l'identité de l'artefact, son producteur, sa révision et la catégorie d'erreur lorsque ces informations comptent. C'est une exigence de conception du projet à évaluer à la frontière concernée, pas une fonctionnalité fournie par ce scénario textuel.

### Exercice pratique 4

`mapError` serait-il l'opération appropriée pour renvoyer une hauteur par défaut réussie après une entrée manquante ? Indiquez le comportement observé sur le chemin de réussite et les informations dont une décision de récupération aurait besoin.

> **Réponse :** Non. `mapError` change la valeur de l'erreur tout en conservant le résultat en échec. Dans le laboratoire, son exemple sur le chemin de réussite reste `Ok 42` et la fonction de transformation n'est pas invoquée. La récupération nécessite une politique explicite, une entrée de remplacement justifiée et une trace de l'échec initial ; c'est une opération différente de l'ajout de contexte à une erreur.

### Exercice pratique 5

Écrivez le résultat et la trace attendus pour une chaîne dont le premier résultat est `Error (DomainError "stale-source")` et dont l'unique rappel lié enregistre `"publish"`. Quelle affirmation plus large resterait injustifiée si cette vérification réussissait ?

> **Réponse :** On attend la même erreur et une trace de rappels vide. La réussite de ce cas établirait seulement que ce bind ignore ce rappel pour cette entrée. Elle ne prouverait ni une publication sans courses concurrentes, ni une revue humaine, ni une livraison durable, ni la sûreté de l'annulation, ni l'absence d'effets ailleurs.

## Reproduire l'expérience du projet

Utilisez le [laboratoire pédagogique partagé](../../../../code/streeling/functional-composition/README.md), qui charge une copie inchangée du module de GA à la révision fixée et en conserve la licence MIT. [F# Interactive](https://learn.microsoft.com/dotnet/fsharp/tools/fsharp-interactive/) exécute le laboratoire sans référence à des packages NuGet. Depuis la racine du dépôt Learn, la commande s'écrit de la même façon sous Windows, Linux/WSL et macOS :

```text
dotnet fsi --exec code/streeling/functional-composition/exercise.fsx
```

L'auteur a observé le SDK `10.0.113` sous Windows, un code de sortie 0, aucun avertissement du compilateur et 24 assertions réussies. Les autres systèmes d'exploitation restent à vérifier. Le [compte rendu d'expérience](../../../../code/streeling/evidence/functional-composition-2026-10-22/README.md) distingue la provenance des entrées, l'exécution et la revue. Il s'agit d'entrées synthétiques exécutées par le véritable module à la révision fixée, pas de trafic capturé de l'application GA. Lisez le dossier apprenant avant d'ouvrir le programme d'exécution, qui contient les réponses.

## Éléments probants et prochaine vérification

Le module GA immuable et ses tests existants constituent le cas d'étude fondé sur le code source ; les observations consignées du laboratoire établissent uniquement ses entrées exécutées. Ne comptez pas une revue statique par IA comme une approbation humaine. Une personne chargée de la revue devrait confronter les affirmations au code source de la révision fixée ; un apprenant devrait ensuite tenter de résoudre le dossier séparé avec l'aide du code source avant de consulter les réponses. L'intégration, le déploiement et la vérification publique anonyme par relecture restent des étapes distinctes.
