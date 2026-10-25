---
module_id: "phy-019-test-sliding-before-calling-a-sculpture-stable"
department: "physics"
course: "Vérifier le glissement avant de déclarer une sculpture stable"
level: "advanced"
prerequisites: ["phy-018-locate-a-sculpture-mass-projection"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Vérifier le glissement avant de déclarer une sculpture stable

> Brouillon pour révision technique et linguistique. Le cas est construit, y compris ses entrées numériques, étiquettes et résultats attendus. Il ne constitue ni essai artisanal physique, ni observation [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), ni rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni exécution [ComfyUI](https://github.com/Comfy-Org/ComfyUI), ni résultat d’apprentissage. Toutes les décisions humaines et d’apprentissage restent indécises.

## Question du projet

Le centre de masse projeté peut se trouver dans la zone d’appui d’une sculpture alors que celle-ci glisse sur un présentoir incliné. Le calcul précédent traite le basculement selon ses propres hypothèses. Ce cours ajoute une inégalité de forces à une proposition de transfert artisanal de Blender vers Godot. Une capture apparemment stable ne fournit ni force de contact ni coefficient de frottement mesuré.

Lisez le prérequis déjà commité et le passage de source conservé avant de calculer. Préparez une table distinguant définition de source, hypothèse construite, résultat dérivé et observation future proposée. La révision et le périmètre de lecture figurent dans le paquet. Un paramètre inspecté prouve que la représentation expose ce paramètre ; il ne fournit pas un coefficient matériel, un jugement de visibilité ou un temps de traitement non mesuré. Préservez cette distinction quand un assistant résume la source. La référence primaire ne soutient que le concept et le passage indiqués dans la fiche de lecture.

## Dériver l’opération avant de proposer une automatisation

Décomposez le poids selon la pente et sa normale. Le frottement statique s’adapte à l’effort tangentiel demandé, jusqu’à sa limite ; il n’est pas systématiquement égal à cette limite. Une réserve positive signifie que cette inégalité idéale admet l’équilibre. Elle ne prouve ni le coefficient réel, ni la résistance au basculement, ni l’arrêt après une perturbation. Le helper Atlas inspecté définit le placement des objets et leurs matériaux, sans fixer ces paramètres de contact.

## Modèle construit fixe et témoin à entrée modifiée

```json
{
  "values": {
    "mass_kg": 2,
    "g_m_s2": 10,
    "sin_theta": 0.6,
    "cos_theta": 0.8,
    "mu_static": 0.8
  },
  "formula": "normal_N=m*g*cos_theta; demand_N=m*g*sin_theta; capacity_N=mu_static*normal_N; reserve_N=capacity_N-demand_N; static_feasible=reserve_N>=0",
  "expected": {
    "normal_N": 16,
    "demand_N": 12,
    "capacity_N": 12.8,
    "reserve_N": 0.8,
    "static_feasible": true
  },
  "negative_control": {
    "values": {
      "mass_kg": 2,
      "g_m_s2": 10,
      "sin_theta": 0.6,
      "cos_theta": 0.8,
      "mu_static": 0.5
    },
    "expected": {
      "normal_N": 16,
      "demand_N": 12,
      "capacity_N": 8,
      "reserve_N": -4,
      "static_feasible": false
    }
  }
}
```

### Exercice 1

Calculez la réaction normale et la force descendante.

<details><summary>Réponse 1</summary>

Elles valent `16 N` et `12 N`. Elles reposent sur la même pesanteur et la même masse déclarées ; leur direction respective compte.

</details>

### Exercice 2

Calculez la limite et la réserve.

<details><summary>Réponse 2</summary>

La limite vaut `12.8 N` et la réserve `0.8 N`. Le frottement statique nécessaire vaut `12 N`, donc reste sous la limite.

</details>

### Exercice 3

Doubler la masse peut-il corriger une inégalité non satisfaite ?

<details><summary>Réponse 3</summary>

Non. Demande et capacité augmentent dans la même proportion : le signe de la réserve reste inchangé pour une masse positive avec ces hypothèses.

</details>

### Exercice 4

Appliquez le coefficient modifié.

<details><summary>Réponse 4</summary>

La capacité devient `8 N`, la réserve `-4 N` et `static_feasible=false`. Le résultat relatif au basculement ne corrige pas cet échec.

</details>

### Exercice 5

Que faut-il pour justifier une propriété du contact dans la scène ?

<details><summary>Réponse 5</summary>

Consignez le repère de la pente, le modèle de contact, la provenance du coefficient et les autres charges. Vérifiez le glissement séparément de la projection et identifiez la version du moteur avant toute comparaison.

</details>

## Travail avec consultation des sources

Dessinez le bilan des forces avant de consulter les réponses. Repérez le placement des objets dans Atlas et indiquez où un futur contrat de contact serait nécessaire. Comparez manuellement les coefficients initial et modifié ; conservez une exigence distincte pour le basculement.

Commencez par une référence manuelle directe : fermez les réponses, dessinez le schéma ou la table demandé et calculez les quantités intermédiaires avec leurs unités. Conservez cette première réponse avant de demander de l’aide. Utilisez ensuite la source pour contester une hypothèse précise, en gardant la question, l’emplacement consulté, l’aide reçue et les suggestions rejetées. Comparez le résultat assisté au calcul initial pour la même tâche et les mêmes entrées. Une explication plus courte ne démontre aucun progrès si elle perd une condition aux limites ou invente une observation.

Traitez le témoin structuré comme un cas distinct, sans modifier les entrées principales en place. Consignez changements et invariants, puis précisez si un écart relève du calcul, de l’interprétation ou des hypothèses. Conservez séparément chaque tentative échouée et sa correction. Le paquet prépare un critère pour chaque exercice corrigé ; chaque décision d’apprentissage reste null jusqu’à la conservation et la révision d’une tentative réelle. Consulter une source ou une réponse préparée ne prouve pas que l’apprenant a réalisé la tâche. Aucun nouveau DSL, flux d’agents, adaptateur de scène ni intégration en production n’est nécessaire pour cet exercice sur papier.

## Critère de réfutation annoncé

L’affirmation selon laquelle la projection suffit à prouver la stabilité statique est réfutée par le témoin : la géométrie d’appui reste identique alors que l’inégalité de frottement échoue.

## Sources et périmètre de validation

- [Prérequis déjà commité: phy-018-locate-a-sculpture-mass-projection](../../physics/en/phy-018-locate-a-sculpture-mass-projection.md)

- [Source de projet conservée](../../../../code/blender/scripts/atlas/kit.py)

- [Lecture primaire](https://openstax.org/books/university-physics-volume-1/pages/6-2-friction)

- [Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
