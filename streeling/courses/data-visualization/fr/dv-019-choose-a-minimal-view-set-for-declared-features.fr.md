---
module_id: "dv-019-choose-a-minimal-view-set-for-declared-features"
department: "data-visualization"
course: "Choisir un ensemble minimal de vues pour des traits déclarés"
level: "advanced"
prerequisites: ["phi-010-state-what-a-craft-view-cannot-distinguish", "dv-016-compare-paired-silhouette-residuals"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Choisir un ensemble minimal de vues pour des traits déclarés

> Brouillon pour révision technique et linguistique. Le cas est construit, y compris ses entrées numériques, étiquettes et résultats attendus. Il ne constitue ni essai artisanal physique, ni observation [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), ni rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni exécution [ComfyUI](https://github.com/Comfy-Org/ComfyUI), ni résultat d’apprentissage. Toutes les décisions humaines et d’apprentissage restent indécises.

## Question du projet

Une rotation peut produire de nombreuses captures tout en laissant un détail artisanal caché. Le prérequis montre la perte d’information dans une vue ; ce cours choisit une collection minimale à partir d’une table explicite de visibilité. La minimalité dépend des traits exigés et des coûts déclarés, sans fixer un nombre universel de caméras.

Lisez le prérequis déjà commité et le passage de source conservé avant de calculer. Préparez une table distinguant définition de source, hypothèse construite, résultat dérivé et observation future proposée. La révision et le périmètre de lecture figurent dans le paquet. Un paramètre inspecté prouve que la représentation expose ce paramètre ; il ne fournit pas un coefficient matériel, un jugement de visibilité ou un temps de traitement non mesuré. Préservez cette distinction quand un assistant résume la source. La référence primaire ne soutient que le concept et le passage indiqués dans la fiche de lecture.

## Dériver l’opération avant de proposer une automatisation

Chaque caméra représente l’ensemble des identifiants visibles ; combinez les vues par union. Examinez les petits sous-ensembles avant les grands et conservez tous les minima ex æquo. La somme des nombres de traits peut recompter les mêmes identités et ne prouve pas la couverture. Le script de nettoyage expose un nombre d’images sans fournir notre matrice binaire. La documentation Godot situe l’observation selon la caméra, sans établir ces visibilités. Un futur essai devra valider chaque entrée avant la sélection.

## Modèle construit fixe et témoin à entrée modifiée

```json
{
  "values": {
    "required": [
      "A",
      "B",
      "C",
      "D"
    ],
    "views": {
      "front": [
        "A",
        "B"
      ],
      "side": [
        "B",
        "C"
      ],
      "top": [
        "C",
        "D"
      ],
      "back": [
        "A",
        "D"
      ]
    }
  },
  "formula": "For each subset of sorted view names union feature sets; retain subsets covering required; minimize cardinality; return all tied minima in lexicographic order; if impossible return minimum_count=null and covers=[]; uncovered=required-union(all views)",
  "expected": {
    "minimum_count": 2,
    "covers": [
      [
        "back",
        "side"
      ],
      [
        "front",
        "top"
      ]
    ],
    "uncovered": []
  },
  "negative_control": {
    "values": {
      "required": [
        "A",
        "B",
        "C",
        "D"
      ],
      "views": {
        "front": [
          "A",
          "B"
        ],
        "side": [
          "B",
          "C"
        ],
        "top": [
          "C"
        ],
        "back": [
          "A"
        ]
      }
    },
    "expected": {
      "minimum_count": null,
      "covers": [],
      "uncovered": [
        "D"
      ]
    }
  }
}
```

### Exercice 1

Une vue peut-elle couvrir tous les traits exigés ?

<details><summary>Réponse 1</summary>

Non. Chaque vue fournie ne couvre qu’un sous-ensemble strict. Compter ses marques ne crée pas les identités manquantes.

</details>

### Exercice 2

Trouvez toutes les couvertures minimales.

<details><summary>Réponse 2</summary>

Le minimum vaut `2` : `[back,side]` et `[front,top]`. Les deux couvrent l’ensemble exigé.

</details>

### Exercice 3

Choisir une paire ex æquo établit-il un optimum unique ?

<details><summary>Réponse 3</summary>

Non. Conservez les deux paires selon la règle de coût égal. Toute préférence exige un critère supplémentaire déclaré.

</details>

### Exercice 4

Appliquez le témoin où un trait disparaît.

<details><summary>Réponse 4</summary>

Le trait `[D]` reste découvert ; le minimum est `null` et les couvertures sont `[]`. Ajouter davantage de vues de la liste ne le révèle pas.

</details>

### Exercice 5

Qu’apporterait un essai physique ou rendu ?

<details><summary>Réponse 5</summary>

Il validerait la visibilité pour la géométrie, la caméra et la tâche de reconnaissance précisées. Une table construite ne prouve pas qu’un apprenant reconnaît le trait.

</details>

## Travail avec consultation des sources

Dessinez la matrice traits-vues, énumérez les sous-ensembles manuellement et conservez les ex æquo. Inspectez le paramètre d’images du pipeline et identifiez les mesures manquantes. Précisez le refus requis pour un trait inobservable avant d’automatiser la sélection.

Commencez par une référence manuelle directe : fermez les réponses, dessinez le schéma ou la table demandé et calculez les quantités intermédiaires avec leurs unités. Conservez cette première réponse avant de demander de l’aide. Utilisez ensuite la source pour contester une hypothèse précise, en gardant la question, l’emplacement consulté, l’aide reçue et les suggestions rejetées. Comparez le résultat assisté au calcul initial pour la même tâche et les mêmes entrées. Une explication plus courte ne démontre aucun progrès si elle perd une condition aux limites ou invente une observation.

Traitez le témoin structuré comme un cas distinct, sans modifier les entrées principales en place. Consignez changements et invariants, puis précisez si un écart relève du calcul, de l’interprétation ou des hypothèses. Conservez séparément chaque tentative échouée et sa correction. Le paquet prépare un critère pour chaque exercice corrigé ; chaque décision d’apprentissage reste null jusqu’à la conservation et la révision d’une tentative réelle. Consulter une source ou une réponse préparée ne prouve pas que l’apprenant a réalisé la tâche. Aucun nouveau DSL, flux d’agents, adaptateur de scène ni intégration en production n’est nécessaire pour cet exercice sur papier.

## Critère de réfutation annoncé

L’affirmation selon laquelle multiplier les captures répertoriées garantit la couverture est réfutée quand un trait exigé est absent de toutes les vues.

## Sources et périmètre de validation

- [Prérequis déjà commité: phi-010-state-what-a-craft-view-cannot-distinguish](../../philosophy/en/phi-010-state-what-a-craft-view-cannot-distinguish.md)

- [Prérequis déjà commité: dv-016-compare-paired-silhouette-residuals](../../data-visualization/en/dv-016-compare-paired-silhouette-residuals.md)

- [Source de projet conservée](../../../../code/blender/scripts/glb_pipeline.py)

- [Lecture primaire](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html)

- [Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
