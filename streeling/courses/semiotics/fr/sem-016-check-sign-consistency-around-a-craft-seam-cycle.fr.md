---
module_id: "sem-016-check-sign-consistency-around-a-craft-seam-cycle"
department: "semiotics"
course: "Vérifier la cohérence des signes autour d’un cycle de coutures"
level: "advanced"
prerequisites: ["sem-013-align-two-motif-periods-at-a-textile-seam", "net-009-detect-global-cycles-in-a-panel-stack"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Vérifier la cohérence des signes autour d’un cycle de coutures

> Brouillon pour révision technique et linguistique. Le cas est construit, y compris ses entrées numériques, étiquettes et résultats attendus. Il ne constitue ni essai artisanal physique, ni observation [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), ni rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni exécution [ComfyUI](https://github.com/Comfy-Org/ComfyUI), ni résultat d’apprentissage. Toutes les décisions humaines et d’apprentissage restent indécises.

## Question du projet

Une composition artisanale peut contenir un cycle de coutures sans contradiction. Le sens de chaque lien est déterminant. Le prérequis sur les piles interdit les cycles d’ordre strict en hauteur ; ce cours utilise des contraintes binaires non orientées, identiques ou opposées, dont certains cycles sont cohérents. Un refus générique de cycle rejetterait des compositions valides.

Lisez le prérequis déjà commité et le passage de source conservé avant de calculer. Préparez une table distinguant définition de source, hypothèse construite, résultat dérivé et observation future proposée. La révision et le périmètre de lecture figurent dans le paquet. Un paramètre inspecté prouve que la représentation expose ce paramètre ; il ne fournit pas un coefficient matériel, un jugement de visibilité ou un temps de traitement non mesuré. Préservez cette distinction quand un assistant résume la source. La référence primaire ne soutient que le concept et le passage indiqués dans la fiche de lecture.

## Dériver l’opération avant de proposer une automatisation

Fixez le bit d’un patch, puis propagez chaque égalité ou différence. Le retour au patch initial doit retrouver son bit. Sur le triangle déclaré, le ou exclusif des étiquettes doit s’annuler. Le guide logique définit xor et satisfiabilité, sans imposer ce codage à la couture. Le parentage Atlas constitue une autre relation et ne fournit pas de solution. Complémenter tous les bits conserve les contraintes : cela explique les solutions appariées et l’absence d’ancrage absolu.

## Modèle construit fixe et témoin à entrée modifiée

```json
{
  "values": {
    "nodes": [
      "A",
      "B",
      "C"
    ],
    "edges": [
      [
        "A",
        "B",
        1
      ],
      [
        "B",
        "C",
        1
      ],
      [
        "C",
        "A",
        0
      ]
    ]
  },
  "formula": "Enumerate bit assignments in node order, require bit[u] XOR bit[v] == edge parity for every edge; return assignments lexicographically; cycle_parity=XOR of the three supplied edge bits",
  "expected": {
    "assignments": [
      [
        0,
        1,
        0
      ],
      [
        1,
        0,
        1
      ]
    ],
    "cycle_parity": 0,
    "consistent": true
  },
  "negative_control": {
    "values": {
      "nodes": [
        "A",
        "B",
        "C"
      ],
      "edges": [
        [
          "A",
          "B",
          1
        ],
        [
          "B",
          "C",
          1
        ],
        [
          "C",
          "A",
          1
        ]
      ]
    },
    "expected": {
      "assignments": [],
      "cycle_parity": 1,
      "consistent": false
    }
  }
}
```

### Exercice 1

Résolvez les contraintes principales.

<details><summary>Réponse 1</summary>

Les affectations sont `[0,1,0]` et `[1,0,1]` dans l’ordre des nœuds. Toutes deux satisfont chaque lien.

</details>

### Exercice 2

Pourquoi le cycle ne commande-t-il pas le refus ?

<details><summary>Réponse 2</summary>

Sa parité vaut `0`. Les liens signifient identique ou opposé, pas strictement au-dessus ; le théorème d’empilement concerne une autre relation.

</details>

### Exercice 3

Appliquez le lien de fermeture modifié.

<details><summary>Réponse 3</summary>

La parité devient `1`, les affectations sont `[]` et `consistent=false`. Chaque lien reste localement satisfiable, mais l’ensemble ne l’est plus.

</details>

### Exercice 4

Une solution fixe-t-elle une orientation absolue ?

<details><summary>Réponse 4</summary>

Non. Complémenter tous les bits donne une autre solution. Un patch de référence externe permettrait de lever cette liberté.

</details>

### Exercice 5

Que doit conserver un agent en composant les coutures ?

<details><summary>Réponse 5</summary>

Conservez les identités des nœuds, le type de relation, la convention de parité et l’ancrage éventuel. Ne transformez pas un graphe de signes en graphe de hauteur orienté.

</details>

## Travail avec consultation des sources

Propagez les bits sur le triangle à la main, puis inspectez les liens parents Atlas et expliquez pourquoi ils ne sont pas des contraintes de parité. Conservez un parcours fermé contradictoire comme témoin de refus.

Commencez par une référence manuelle directe : fermez les réponses, dessinez le schéma ou la table demandé et calculez les quantités intermédiaires avec leurs unités. Conservez cette première réponse avant de demander de l’aide. Utilisez ensuite la source pour contester une hypothèse précise, en gardant la question, l’emplacement consulté, l’aide reçue et les suggestions rejetées. Comparez le résultat assisté au calcul initial pour la même tâche et les mêmes entrées. Une explication plus courte ne démontre aucun progrès si elle perd une condition aux limites ou invente une observation.

Traitez le témoin structuré comme un cas distinct, sans modifier les entrées principales en place. Consignez changements et invariants, puis précisez si un écart relève du calcul, de l’interprétation ou des hypothèses. Conservez séparément chaque tentative échouée et sa correction. Le paquet prépare un critère pour chaque exercice corrigé ; chaque décision d’apprentissage reste null jusqu’à la conservation et la révision d’une tentative réelle. Consulter une source ou une réponse préparée ne prouve pas que l’apprenant a réalisé la tâche. Aucun nouveau DSL, flux d’agents, adaptateur de scène ni intégration en production n’est nécessaire pour cet exercice sur papier.

## Critère de réfutation annoncé

Le cycle principal cohérent réfute le refus de tout cycle ; le témoin réfute l’affirmation inverse selon laquelle des coutures localement valides se composent toujours.

## Sources et périmètre de validation

- [Prérequis déjà commité: sem-013-align-two-motif-periods-at-a-textile-seam](../../semiotics/en/sem-013-align-two-motif-periods-at-a-textile-seam.md)

- [Prérequis déjà commité: net-009-detect-global-cycles-in-a-panel-stack](../../network-science/en/net-009-detect-global-cycles-in-a-panel-stack.md)

- [Source de projet conservée](../../../../code/blender/scripts/atlas/kit.py)

- [Lecture primaire](https://microsoft.github.io/z3guide/docs/logic/propositional-logic/)

- [Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
