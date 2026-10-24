---
module_id: net-005-fanout-results-and-dependency-joins
department: network-science
course: "Résultats des branches parallèles et jointures de dépendances"
level: intermediate
prerequisites: ["net-004-semantic-backpressure-and-evidence-dependencies"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Résultats des branches parallèles et jointures de dépendances

> **Périmètre du brouillon.** Expérience fondée sur le code source du projet, avec des entrées synthétiques. La validation par un spécialiste humain, la relecture linguistique et l'évaluation par un apprenant restent à faire ; aucune publication ni vérification de la version publique du cours n'est attestée.

## Objectifs et question pour le projet

Modéliser les calculs des branches et leur jointure sous la forme d'un petit graphe de dépendances, distinguer la conservation des travaux partiels de l'autorisation de diffuser un résultat agrégé, et tester les hypothèses sur les échecs d'une exécution parallèle. **Question pour le projet :** un workflow de GA ou d'agents peut-il conserver des résultats indépendants utiles lorsqu'une branche échoue, tout en empêchant une action qui dépend de toutes les entrées de se déclarer réussie ?

La source exécutable est le [module GaAsync de GA à la révision `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/GaAsync.fs). Ses fonctions `zip` et `fanOutAll` composent des [workflows asynchrones F#](https://learn.microsoft.com/dotnet/fsharp/language-reference/async-expressions). Les [tests existants de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.DSL.Tests/GaClosureAndCeTests.cs) comprennent un cas de conservation des résultats partiels. Le laboratoire commun exécute ce module avec des valeurs de branches synthétiques ; il n'inspecte pas les sessions wmux actuelles et n'implémente pas d'ordonnanceur distribué.

## 1. Dessiner la jointure avant de choisir le combinateur

Considérons des branches indépendantes A, B et C qui alimentent une jointure J. Si un artefact en aval exige les trois branches, J possède une dépendance ET : deux entrées réussies ne suffisent pas. Une autre action en aval peut n'exiger que A ; l'échec de B n'a alors pas à bloquer cette action. Ces dépendances sont définies par le contrat du consommateur, et non par le nombre de branches au vert.

Le laboratoire attribue les sorties 100 et 300 aux branches réussies et `DomainError "missing-branch"` à la branche en échec. Ces entiers sont des identifiants de démonstration, et non des contenus d'artefacts ou des mesures de qualité. La véritable fonction `fanOutAll` renvoie une erreur contenant un `PartialFailure` avec les réussites `[100; 300]` et une erreur. Les valeurs utiles sont conservées, mais le résultat agrégé n'est pas devenu `Ok`.

### Exercice pratique 1

A et C réussissent, tandis que B échoue. Un export exige A, B et C, alors qu'un diagnostic n'a besoin que de A. Avec ces dépendances, quelle action dispose de toutes ses entrées ? `PartialFailure` autorise-t-il à lui seul l'une ou l'autre action externe ?

> **Réponse :** Le diagnostic dispose de l'entrée requise, tandis que la dépendance ET de l'export est incomplète. `PartialFailure` conserve des informations sur les résultats des branches ; il n'accorde aucune autorisation d'action externe. Le consommateur doit également vérifier l'identité des entrées, la validité des révisions et les autorisations.

## 2. Ne pas déduire la collecte partielle de l'exécution parallèle

La fonction `zip` de la révision fixée exécute deux workflows avec `Async.Parallel`. Si les deux renvoient `Ok`, elle renvoie leur paire : le dispositif de test observe `Ok (2, 3)`. Si les deux renvoient des erreurs métier, le code source choisit l'erreur de l'entrée de gauche. Le dispositif observe `Error (DomainError "left")` et consigne séparément que les corps des deux branches ont démarré. Le choix d'une seule erreur ne prouve donc pas qu'une seule branche a été exécutée.

Cette jointure diffère de `bind` : ce dernier n'appelle pas sa fonction dépendante après une erreur, alors que les entrées de zip sont ici des workflows indépendants démarrés ensemble. Une jointure parallèle peut perdre des détails de diagnostic même si les deux côtés ont effectué du travail. L'erreur qui termine en premier n'est pas le critère de sélection utilisé par l'expression de filtrage de cette version de `zip`.

### Exercice pratique 2

Deux branches zip renvoient des erreurs métier nommées `left` et `right`. Un tableau de bord ne signale que `left` et en conclut que la branche de droite n'a jamais démarré. Quelle observation du dispositif de test contredit cette conclusion, et quelle affirmation plus large sur les durées reste à vérifier ?

> **Réponse :** L'ensemble consigné des branches démarrées contient à la fois `left` et `right`, tandis que le résultat choisit l'erreur de gauche. Cela contredit l'idée que l'autre branche n'a pas démarré. L'expérience n'établit ni l'ordre de fin d'exécution en production, ni la latence, ni le débit, ni une garantie d'équité de l'ordonnanceur.

## 3. Interpréter les collections vides et celles où tout échoue

Le laboratoire observe `Ok []` pour une exécution sans branche et `Ok [100; 300]` lorsque toutes les branches réussissent. Pour deux entrées en échec, il observe un `PartialFailure` avec 0 réussite et 2 erreurs, dans l'ordre des entrées des deux erreurs métier. Dans cette implémentation, le nom de cas « partial » n'exige pas qu'au moins une branche ait réussi.

Un calcul vide réussi ne prouve pas qu'un travail requis existait ou a été effectué. Un consommateur qui attend trois sorties de branches doit vérifier explicitement cette couverture. De même, conserver deux valeurs d'erreur ne crée pas d'identifiants de branches. Le code source conserve les valeurs réussies dans une `obj list` ; extraire les valeurs de cet exemple homogène d'entiers est sûr parce que le dispositif de test connaît leur type, mais des éléments de preuve hétérogènes exigent une enveloppe explicitement typée et un contrat d'identité avant tout usage opérationnel.

### Exercice pratique 3

Un export qui exige trois branches reçoit `Ok []`. Peut-il déclarer sa couverture des dépendances complète ? Que vous apprend un `PartialFailure` contenant deux erreurs, et quelles informations manque-t-il ?

> **Réponse :** Non. Une collection vide réussie n'établit pas la présence des trois entrées attendues. Le résultat contenant deux erreurs indique que les deux calculs fournis à cette collection ont renvoyé des erreurs et qu'aucune réussite n'a été conservée ; il ne précise pas à lui seul les branches requises, les révisions sources, la politique de nouvelle tentative ou l'autorisation de diffusion.

## 4. Préciser l'hypothèse sur les exceptions

`fanOutAll` collecte les valeurs `Result` renvoyées, mais n'encadre pas chaque branche d'une conversion des exceptions en résultats. La `System.IO.IOException "unwrapped"` délibérément non enveloppée du laboratoire se propage hors de l'exécution parallèle. Elle ne devient pas un `PartialFailure`. Envelopper cette exception délibérée avec la fonction `fromAsync` du module produit en revanche un `PartialFailure` qui conserve la valeur réussie 1 et un `IoError` avec le message `"wrapped"` et le type d'exception d'origine.

C'est le principal contre-exemple à l'affirmation trop générale selon laquelle « toutes les branches aboutissent toujours à des valeurs ». Convertir des défaillances d'infrastructure connues à une frontière nommée peut rendre le canal d'erreur explicite, mais cette expérience ne prouve ni la sûreté de l'annulation, ni la conservation durable, ni la possibilité de représenter tous les échecs possibles. Une exception qui se propage dans un système distribué peut avoir des conséquences différentes de celles observées dans ce dispositif de test F# exécuté au sein d'un seul processus.

### Exercice pratique 4

Un développeur écrit : « `fanOutAll` conserve toujours les sorties réussies, quoi que fasse une autre branche. » L'expérience de l'exception non enveloppée confirme-t-elle cette affirmation ? Précisez le comportement plus restreint effectivement observé.

> **Réponse :** Non. L'exception non enveloppée se propage au lieu de produire la valeur contenant les résultats partiels. La conservation des réussites est observée pour les branches fournies qui renvoient des résultats, y compris l'exception testée après conversion par `fromAsync`. Ce n'est pas une garantie concernant n'importe quelle exception levée, l'annulation, la perte du processus ou le stockage durable.

## 5. Comparer avec un workflow plus simple

Un DSL pour agents envisagé pourrait proposer séparément la composition dépendante, les jointures exigeant toutes les entrées et la collecte des résultats partiels. Le meilleur contre-argument est qu'une courte fonction explicite accompagnée d'une liste de vérification pour le consommateur peut déjà exprimer ce workflow. Un nouveau DSL ajoute des coûts d'analyse syntaxique, de débogage, de gestion des identités, de reprise et de maintenance des politiques. Gardez cette idée comme candidate tant qu'une comparaison mesurée n'en démontre pas l'intérêt.

Pour un essai délimité, utilisez les mêmes entrées synthétiques de réussite, d'erreur métier et d'exception dans les deux interfaces. Comparez les admissions incorrectes d'actions exigeant toutes les entrées, les catégories d'erreurs perdues, les valeurs utiles des branches conservées et le temps nécessaire à un opérateur pour expliquer le résultat. Rejetez le DSL candidat s'il admet l'export incomplet, masque la distinction avec l'exception qui se propage, ou produit les mêmes décisions avec davantage de maintenance et aucun bénéfice mesuré. Ce cours n'implémente aucun DSL.

### Exercice pratique 5

Proposez un résultat attendu pour une branche renvoyant une erreur métier et un autre pour une exception non enveloppée. Nommez un garde-fou pour évaluer un nouveau DSL face à la composition explicite de fonctions GA.

> **Réponse :** Avec les entrées `ok 100`, l'erreur métier renvoyée et `ok 300`, attendez-vous à un résultat agrégé en échec qui conserve `[100; 300]` et l'erreur. Avec l'exception délibérément non enveloppée, attendez-vous à ce que l'exception se propage au lieu de produire un `PartialFailure`. Un garde-fou adapté consiste à n'admettre aucun export tant qu'une entrée déclarée obligatoire manque. Consignez séparément les diagnostics perdus et le temps d'explication de l'opérateur ; la réussite du dispositif de test n'établit ni un débit de workflow d'agents ni une publication.

## Reproduire l'expérience du projet

Utilisez le [laboratoire pédagogique commun](../../../../code/streeling/functional-composition/README.md), qui charge une copie inchangée du module de GA à la révision fixée et conserve sa licence MIT. [F# Interactive](https://learn.microsoft.com/dotnet/fsharp/tools/fsharp-interactive/) exécute le laboratoire sans référence à un package NuGet. Depuis la racine du dépôt Learn, la même commande s'applique à Windows, Linux/WSL et macOS :

```text
dotnet fsi --exec code/streeling/functional-composition/exercise.fsx
```

L'auteur a observé le SDK `10.0.113` sous Windows, un code de sortie 0, aucun avertissement du compilateur et 24 assertions réussies. Les autres systèmes d'exploitation restent à vérifier. Le [compte rendu de l'expérience](../../../../code/streeling/evidence/functional-composition-2026-10-22/README.md) distingue la provenance des entrées, l'exécution et la revue. Il s'agit d'entrées synthétiques exécutées par le véritable module à la révision fixée, et non de trafic capturé dans l'application GA. Lisez le dossier de l'apprenant avant d'ouvrir le programme d'exécution, qui contient les réponses.

## Éléments de preuve et prochaine vérification

Le module GA immuable et ses tests existants établissent l'étude de cas issue du code source ; les observations consignées du laboratoire ne portent que sur les entrées exécutées. Ne comptez pas une revue statique par IA comme une approbation humaine. Un relecteur devrait vérifier les affirmations dans le code source à la révision fixée, puis un apprenant devrait essayer le dossier distinct qui autorise la consultation du code source avant de lire les réponses. L'intégration, le déploiement et la vérification publique sans authentification restent des étapes distinctes.
