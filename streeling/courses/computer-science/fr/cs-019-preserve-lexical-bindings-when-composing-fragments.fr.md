---
module_id: "cs-019-preserve-lexical-bindings-when-composing-fragments"
department: "computer-science"
course: "Préserver les liaisons lexicales lors de la composition de fragments"
level: "intermediate"
prerequisites: ["cs-006-ixql-pipeline-composition"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Préserver les liaisons lexicales lors de la composition de fragments

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Un collègue propose de composer des fragments de pipeline d’agent en concaténant leur texte. Les deux emploient le même nom temporaire pratique. Le résultat reste lisible, mais une référence libre peut accidentellement désigner la nouvelle liaison locale. Le prérequis suit les dépendances entre étapes ; ce cours suit l’identité des liaisons dans une étape. Le problème peut précéder toute exécution : un exemple arithmétique réussi ne prouve donc pas la sûreté de la composition.

Notre fragment explicatif ajoute un argument incrémenté à une valeur provenant de son contexte. Le même nom imprimé existe localement et dans ce contexte. La référence libre voulue doit conserver sa liaison d’origine. Une substitution textuelle naïve lui fait lire la valeur locale et produit une autre réponse. Renommer la liaison locale et toutes ses occurrences liées préserve le sens voulu ; modifier toutes les occurrences du même mot peut aussi changer des références libres.

L’exemple de portée lexicale du guide [Racket](https://docs.racket-lang.org/guide/pattern-macros.html) montre pourquoi les identifiants introduits exigent une discipline de liaison. Nous utilisons ce concept sans prétendre qu’IXQL soit un langage de macros Racket. L’utilitaire [F#](https://learn.microsoft.com/dotnet/fsharp/) conservé reçoit des fonctions avec des paramètres lexicaux et transmet les valeurs réussies aux callbacks. Il n’implémente aucun développement textuel de fragments. Examiner la portée de ses paramètres aide précisément à distinguer les obligations de la composition de fonctions et de la concaténation de texte.

Le contrôle rend volontairement la valeur externe égale à la valeur locale. Les calculs concordent alors malgré des structures de liaison différentes. Ce succès trompeur masque la capture. Une proposition de DSL devrait conserver les ensembles de variables libres et les identités des liaisons, puis essayer des valeurs inégales. Pour répondre, on peut tracer sur papier les liens entre occurrences et définitions, sans créer de parseur.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: cs-006-ixql-pipeline-composition](../../computer-science/en/cs-006-ixql-pipeline-composition.md)

[Artefact conservé du projet](../../../../code/streeling/functional-composition/vendor/GaAsync.fs)

[Lecture primaire: Racket Guide, section 16.1.2, read 2026-10-24](https://docs.racket-lang.org/guide/pattern-macros.html)

[Lecture primaire: Microsoft F# documentation, read 2026-10-24](https://learn.microsoft.com/dotnet/fsharp/)

## Modèle fixé et contrôle

```json
{
  "values": {
    "outer_x": 10,
    "argument": 3,
    "local_name": "x",
    "local_increment": 1
  },
  "formula": "local=argument+local_increment; lexical_result=local+outer_x; captured_result=local+local; renamed_result=local+outer_x, renaming only the bound local identifier.",
  "expected": {
    "lexical_result": 14,
    "captured_result": 8,
    "renamed_result": 14
  },
  "negative_control": {
    "values": {
      "outer_x": 4,
      "argument": 3,
      "local_name": "x",
      "local_increment": 1
    },
    "expected": {
      "lexical_result": 8,
      "captured_result": 8,
      "renamed_result": 8
    },
    "why": "Coincidental equal values hide capture; one agreeing execution is not proof of hygiene."
  },
  "assumptions": [
    "One local binding and one intended free outer reference.",
    "Exact integers and pure expressions; this is explanatory notation, not IXQL syntax."
  ],
  "limits": "No parser, macro expander or GA DSL change is supplied; capture must be reasoned about by binding identity."
}
```

### Exercice 1

Calculez la valeur locale et le résultat lexical voulu dans le cas principal.

<details><summary>Réponse 1</summary>

La valeur locale vaut `4` ; le résultat voulu vaut `14`. La contribution externe reste `10`, puisque la référence libre garde sa liaison dans le contexte. L’argument n’est pas la valeur externe.

</details>

### Exercice 2

Quel résultat donne l’interprétation avec capture, et pourquoi ?

<details><summary>Réponse 2</summary>

Elle donne `8`, en ajoutant deux fois la valeur locale `4`. L’arithmétique est cohérente, mais la référence désigne la mauvaise liaison. L’écart numérique révèle une erreur sémantique plutôt qu’une erreur de calcul.

</details>

### Exercice 3

Que doit modifier un renommage alpha valide ?

<details><summary>Réponse 3</summary>

Il modifie le nom local lié et uniquement les occurrences liées par cette définition. Il préserve la référence externe libre et donne `14`. Un remplacement global du mot ne prouve pas cette relation.

</details>

### Exercice 4

Appliquez le contrôle. Pourquoi l’accord ne prouve-t-il pas une composition sûre ?

<details><summary>Réponse 4</summary>

Les deux interprétations donnent `8` lorsque la valeur externe vaut `4`. L’égalité des valeurs masque des liaisons différentes. Ce piège d’accord exige une analyse structurelle de la portée en plus du contre-exemple principal.

</details>

### Exercice 5

Que doit conserver un assistant proposant un fragment réutilisable ?

<details><summary>Réponse 5</summary>

Il doit conserver les entrées, les identifiants libres, les identités des liaisons locales et le contexte source voulu. Rejetez la proposition si le renommage change une référence libre ou si ce tableau est présenté comme preuve d’un DSL hygiénique implémenté.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
