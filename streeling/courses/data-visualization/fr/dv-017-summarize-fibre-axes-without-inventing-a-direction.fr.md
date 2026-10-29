---
module_id: "dv-017-summarize-fibre-axes-without-inventing-a-direction"
department: "data-visualization"
course: "Résumer les axes des fibres sans inventer une direction"
level: "advanced"
prerequisites: ["dv-006-position-length-area-comparisons"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Résumer les axes des fibres sans inventer une direction

> Brouillon pour révision technique et linguistique. Le cas est construit, y compris ses entrées numériques, étiquettes et résultats attendus. Il ne constitue ni essai artisanal physique, ni observation [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), ni rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni exécution [ComfyUI](https://github.com/Comfy-Org/ComfyUI), ni résultat d’apprentissage. Toutes les décisions humaines et d’apprentissage restent indécises.

## Question du projet

Un tableau textile moyenne des angles proches de la coupure et dessine un axe moyen perpendiculaire. Un axe ne porte pas de flèche : le retourner conserve son orientation. Les encodages de position ou de longueur ne corrigent pas cette arithmétique. Ce cours dérive un résumé axial avant son affichage dans une scène artisanale proposée.

Lisez le prérequis déjà commité et le passage de source conservé avant de calculer. Préparez une table distinguant définition de source, hypothèse construite, résultat dérivé et observation future proposée. La révision et le périmètre de lecture figurent dans le paquet. Un paramètre inspecté prouve que la représentation expose ce paramètre ; il ne fournit pas un coefficient matériel, un jugement de visibilité ou un temps de traitement non mesuré. Préservez cette distinction quand un assistant résume la source. La référence primaire ne soutient que le concept et le passage indiqués dans la fiche de lecture.

## Dériver l’opération avant de proposer une automatisation

Doubler chaque angle transforme l’équivalence par demi-tour en un tour circulaire complet. Moyennez les vecteurs unitaires obtenus, puis divisez l’angle résultant. La norme détecte la compensation ; si elle s’annule, ne dessinez pas d’axe moyen. [SciPy](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.circmean.html) documente la moyenne circulaire et signale le cas nul ; ce cours choisit explicitement null au lieu d’un angle dépendant de l’implémentation. Atlas contient des directions géométriques, sans fournir d’observations de fibres. Une moyenne seule masque aussi des groupes distincts.

## Modèle construit fixe et témoin à entrée modifiée

```json
{
  "values": {
    "angles_deg": [
      10,
      170
    ],
    "zero_tolerance": 1e-12
  },
  "formula": "C=mean(cos(2*theta*pi/180)); S=mean(sin(2*theta*pi/180)); R=hypot(C,S); axial_mean_deg=(atan2(S,C)*90/pi)%180 if R>tolerance else null; arithmetic_mean=mean(theta); normalize near-180 roundoff to 0",
  "expected": {
    "C": 0.9396926207859084,
    "S": 0,
    "R": 0.9396926207859084,
    "axial_mean_deg": 0,
    "arithmetic_mean_deg": 90
  },
  "negative_control": {
    "values": {
      "angles_deg": [
        0,
        90
      ],
      "zero_tolerance": 1e-12
    },
    "expected": {
      "C": 0,
      "S": 0,
      "R": 0,
      "axial_mean_deg": null,
      "arithmetic_mean_deg": 45
    }
  }
}
```

### Exercice 1

Calculez la moyenne ordinaire des angles.

<details><summary>Réponse 1</summary>

Elle vaut `90` degrés et traverse les axes presque horizontaux au lieu de suivre leur orientation commune.

</details>

### Exercice 2

Calculez le résumé après doublement des angles.

<details><summary>Réponse 2</summary>

La norme résultante vaut `0.9396926207859084` et l’axe moyen `0` degré. L’arrondi à la coupure ne doit pas créer un autre axe.

</details>

### Exercice 3

Appliquez le témoin orthogonal.

<details><summary>Réponse 3</summary>

La norme vaut `0` à la tolérance près et l’axe moyen est `null` ; la moyenne arithmétique vaut `45` degrés.

</details>

### Exercice 4

Une moyenne indéfinie indique-t-elle des observations absentes ?

<details><summary>Réponse 4</summary>

Non. Les observations existent ; leurs orientations axiales équilibrées se compensent. Distinguez résumé indéfini et données sources absentes.

</details>

### Exercice 5

Que faut-il conserver dans la visualisation ?

<details><summary>Réponse 5</summary>

Affichez les axes bruts ou un histogramme d’orientation avec la norme résultante. Précisez la convention par demi-tour et évitez une flèche suggérant un flux orienté.

</details>

## Travail avec consultation des sources

Dessinez les axes, puis les vecteurs aux angles doublés. Inspectez le helper directionnel Atlas et expliquez pourquoi il ne contient pas d’observations de fibres. Proposez des états visuels distincts pour données absentes et résumé compensé.

Commencez par une référence manuelle directe : fermez les réponses, dessinez le schéma ou la table demandé et calculez les quantités intermédiaires avec leurs unités. Conservez cette première réponse avant de demander de l’aide. Utilisez ensuite la source pour contester une hypothèse précise, en gardant la question, l’emplacement consulté, l’aide reçue et les suggestions rejetées. Comparez le résultat assisté au calcul initial pour la même tâche et les mêmes entrées. Une explication plus courte ne démontre aucun progrès si elle perd une condition aux limites ou invente une observation.

Traitez le témoin structuré comme un cas distinct, sans modifier les entrées principales en place. Consignez changements et invariants, puis précisez si un écart relève du calcul, de l’interprétation ou des hypothèses. Conservez séparément chaque tentative échouée et sa correction. Le paquet prépare un critère pour chaque exercice corrigé ; chaque décision d’apprentissage reste null jusqu’à la conservation et la révision d’une tentative réelle. Consulter une source ou une réponse préparée ne prouve pas que l’apprenant a réalisé la tâche. Aucun nouveau DSL, flux d’agents, adaptateur de scène ni intégration en production n’est nécessaire pour cet exercice sur papier.

## Critère de réfutation annoncé

L’affirmation selon laquelle tout échantillon d’orientations non vide possède un axe moyen significatif échoue sur le témoin orthogonal équilibré.

## Sources et périmètre de validation

- [Prérequis déjà commité: dv-006-position-length-area-comparisons](../../data-visualization/en/dv-006-position-length-area-comparisons.md)

- [Source de projet conservée](../../../../code/blender/scripts/atlas/kit.py)

- [Lecture primaire](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.circmean.html)

- [Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
