---
module_id: "dv-018-show-overlapping-craft-defects-as-a-union"
department: "data-visualization"
course: "Afficher les défauts artisanaux superposés par leur union"
level: "advanced"
prerequisites: ["dv-015-map-missing-stitches-without-inventing-holes"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Afficher les défauts artisanaux superposés par leur union

> Brouillon pour révision technique et linguistique. Le cas est construit, y compris ses entrées numériques, étiquettes et résultats attendus. Il ne constitue ni essai artisanal physique, ni observation [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), ni rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni exécution [ComfyUI](https://github.com/Comfy-Org/ComfyUI), ni résultat d’apprentissage. Toutes les décisions humaines et d’apprentissage restent indécises.

## Question du projet

Un rapport de texture signale une erreur de couture et une erreur de couleur sur des régions qui se recouvrent. Additionner leurs aires compte deux fois la zone commune et peut exagérer la surface touchée. Le prérequis distingue absence et observation indisponible. Ici, toutes les aires sont connues ; la difficulté vient du recouvrement des catégories.

Lisez le prérequis déjà commité et le passage de source conservé avant de calculer. Préparez une table distinguant définition de source, hypothèse construite, résultat dérivé et observation future proposée. La révision et le périmètre de lecture figurent dans le paquet. Un paramètre inspecté prouve que la représentation expose ce paramètre ; il ne fournit pas un coefficient matériel, un jugement de visibilité ou un temps de traitement non mesuré. Préservez cette distinction quand un assistant résume la source. La référence primaire ne soutient que le concept et le passage indiqués dans la fiche de lecture.

## Dériver l’opération avant de proposer une automatisation

Partitionnez le canevas en catégories exclusives avant de dessiner un graphique empilé : premier masque seul, second seul, les deux et aucun. Leurs aires couvrent le canevas une seule fois. Le [W3C](https://www.w3.org/TR/2024/CRD-compositing-1-20240321/) décrit des combinaisons sensibles au recouvrement ; nos masques binaires restent un modèle ensembliste construit, pas des valeurs alpha ni des défauts rendus. Le helper ComfyUI renvoie des octets sans prouver quelles régions sont défectueuses. Un exemple disjoint réussi ne valide donc pas le résumé de défauts superposés.

## Modèle construit fixe et témoin à entrée modifiée

```json
{
  "values": {
    "canvas_area": 100,
    "mask_a_area": 30,
    "mask_b_area": 25,
    "intersection_area": 10
  },
  "formula": "a_only=A-I; b_only=B-I; both=I; union=A+B-I; neither=canvas-union; naive_sum=A+B",
  "expected": {
    "a_only": 20,
    "b_only": 15,
    "both": 10,
    "union": 45,
    "neither": 55,
    "naive_sum": 55
  },
  "negative_control": {
    "values": {
      "canvas_area": 100,
      "mask_a_area": 30,
      "mask_b_area": 25,
      "intersection_area": 0
    },
    "expected": {
      "a_only": 30,
      "b_only": 25,
      "both": 0,
      "union": 55,
      "neither": 45,
      "naive_sum": 55
    }
  }
}
```

### Exercice 1

Trouvez les aires touchées exclusives.

<details><summary>Réponse 1</summary>

Le premier seul vaut `20`, le second seul `15` et les deux `10` unités d’aire. Séparez le sens des catégories du choix de couleur.

</details>

### Exercice 2

Calculez les aires touchée unique et intacte.

<details><summary>Réponse 2</summary>

Elles valent `45` et `55`. La partition exclusive totalise `100`.

</details>

### Exercice 3

Quantifiez l’erreur de la somme naïve.

<details><summary>Réponse 3</summary>

La somme vaut `55` et dépasse l’union de `10`, soit exactement l’intersection comptée une seconde fois.

</details>

### Exercice 4

Appliquez le témoin disjoint.

<details><summary>Réponse 4</summary>

L’union devient `55` et la zone intacte `45`. L’addition naïve convient alors, car l’intersection vaut `0`.

</details>

### Exercice 5

Les seules aires d’entrée déterminent-elles l’union ?

<details><summary>Réponse 5</summary>

Non. L’intersection apporte une information supplémentaire. Si elle manque, donnez des bornes plutôt qu’une aire unique inventée.

</details>

## Travail avec consultation des sources

Dessinez manuellement le recouvrement et la table des aires exclusives. Inspectez la récupération des images, puis proposez un affichage séparant la zone commune et le cas d’une intersection inconnue.

Commencez par une référence manuelle directe : fermez les réponses, dessinez le schéma ou la table demandé et calculez les quantités intermédiaires avec leurs unités. Conservez cette première réponse avant de demander de l’aide. Utilisez ensuite la source pour contester une hypothèse précise, en gardant la question, l’emplacement consulté, l’aide reçue et les suggestions rejetées. Comparez le résultat assisté au calcul initial pour la même tâche et les mêmes entrées. Une explication plus courte ne démontre aucun progrès si elle perd une condition aux limites ou invente une observation.

Traitez le témoin structuré comme un cas distinct, sans modifier les entrées principales en place. Consignez changements et invariants, puis précisez si un écart relève du calcul, de l’interprétation ou des hypothèses. Conservez séparément chaque tentative échouée et sa correction. Le paquet prépare un critère pour chaque exercice corrigé ; chaque décision d’apprentissage reste null jusqu’à la conservation et la révision d’une tentative réelle. Consulter une source ou une réponse préparée ne prouve pas que l’apprenant a réalisé la tâche. Aucun nouveau DSL, flux d’agents, adaptateur de scène ni intégration en production n’est nécessaire pour cet exercice sur papier.

## Critère de réfutation annoncé

Le cas avec recouvrement réfute l’addition systématique des aires de catégories, même si cette règle réussit sur le témoin disjoint.

## Sources et périmètre de validation

- [Prérequis déjà commité: dv-015-map-missing-stitches-without-inventing-holes](../../data-visualization/en/dv-015-map-missing-stitches-without-inventing-holes.md)

- [Source de projet conservée](../../../../code/comfyui/ga-lab/runner/comfy.py)

- [Lecture primaire](https://www.w3.org/TR/2024/CRD-compositing-1-20240321/)

- [Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
