---
module_id: "phy-021-separate-rebound-speed-from-retained-energy"
department: "physics"
course: "Distinguer vitesse de rebond et énergie conservée"
level: "advanced"
prerequisites: ["phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Distinguer vitesse de rebond et énergie conservée

> Brouillon pour révision technique et linguistique. Le cas est construit, y compris ses entrées numériques, étiquettes et résultats attendus. Il ne constitue ni essai artisanal physique, ni observation [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), ni rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni exécution [ComfyUI](https://github.com/Comfy-Org/ComfyUI), ni résultat d’apprentissage. Toutes les décisions humaines et d’apprentissage restent indécises.

## Question du projet

Une perle artisanale rebondit dans une scène proposée avec une fraction de sa vitesse d’approche. Nommer cette fraction énergie conservée confond un rapport linéaire de vitesses et un rapport quadratique d’énergies. Le prérequis fournit les unités de masse ; ce cours ajoute un impact signé et précise le système qui reçoit l’impulsion extérieure.

Lisez le prérequis déjà commité et le passage de source conservé avant de calculer. Préparez une table distinguant définition de source, hypothèse construite, résultat dérivé et observation future proposée. La révision et le périmètre de lecture figurent dans le paquet. Un paramètre inspecté prouve que la représentation expose ce paramètre ; il ne fournit pas un coefficient matériel, un jugement de visibilité ou un temps de traitement non mesuré. Préservez cette distinction quand un assistant résume la source. La référence primaire ne soutient que le concept et le passage indiqués dans la fiche de lecture.

## Dériver l’opération avant de proposer une automatisation

Orientez la vitesse positive en s’éloignant d’une paroi fixe. Inversez le signe incident et multipliez la vitesse par le coefficient de restitution. L’énergie cinétique dépend du carré de la vitesse : elle perd donc la direction, indispensable à l’impulsion. La quantité de mouvement de la perle seule ne se conserve pas, puisque la paroi agit sur elle. [OpenStax](https://openstax.org/books/university-physics-volume-1/pages/9-4-types-of-collisions) précise la frontière du système fermé ; notre paroi idéale reste extérieure au sous-système perle. Atlas définit la géométrie sans mesurer de rebond ni résoudre de contact.

## Modèle construit fixe et témoin à entrée modifiée

```json
{
  "values": {
    "mass_kg": 0.5,
    "incoming_m_s": -4,
    "restitution": 0.5
  },
  "formula": "outgoing=-e*incoming; K_before=mass*incoming**2/2; K_after=mass*outgoing**2/2; retained_fraction=e**2; impulse=mass*(outgoing-incoming)",
  "expected": {
    "outgoing_m_s": 2,
    "K_before_J": 4,
    "K_after_J": 1,
    "retained_fraction": 0.25,
    "impulse_Ns": 3
  },
  "negative_control": {
    "values": {
      "mass_kg": 0.5,
      "incoming_m_s": -4,
      "restitution": 1
    },
    "expected": {
      "outgoing_m_s": 4,
      "K_before_J": 4,
      "K_after_J": 4,
      "retained_fraction": 1,
      "impulse_Ns": 4
    }
  }
}
```

### Exercice 1

Calculez la vitesse après le choc.

<details><summary>Réponse 1</summary>

Elle vaut `2 m/s`, en s’éloignant de la paroi. L’inversion du signe appartient à la règle d’impact déclarée.

</details>

### Exercice 2

Calculez les énergies cinétiques.

<details><summary>Réponse 2</summary>

Elles valent `4 J` avant et `1 J` après. La fraction conservée vaut `0.25`, pas `0.5`.

</details>

### Exercice 3

Calculez l’impulsion sur la pièce.

<details><summary>Réponse 3</summary>

Elle vaut `3 N*s`. Soustraire une quantité de mouvement incidente négative augmente la variation signée.

</details>

### Exercice 4

Appliquez le témoin élastique.

<details><summary>Réponse 4</summary>

La vitesse finale vaut `4 m/s`, la fraction conservée `1` et l’impulsion `4 N*s`. Une énergie cinétique identique n’implique pas une quantité de mouvement inchangée.

</details>

### Exercice 5

Que ne permet pas d’établir la source ?

<details><summary>Réponse 5</summary>

Le helper ne fournit ni étalonnage du coefficient ni comportement du contact. Une affirmation sur la scène exige les paramètres de l’hôte et des observations réelles avec la même frontière de système.

</details>

## Travail avec consultation des sources

Dessinez la paroi et les flèches de vitesse, calculez les énergies manuellement, puis inspectez la géométrie Atlas. Proposez une observation permettant de comparer une trajectoire de perle au modèle idéal ; laissez les champs de mesure vides.

Commencez par une référence manuelle directe : fermez les réponses, dessinez le schéma ou la table demandé et calculez les quantités intermédiaires avec leurs unités. Conservez cette première réponse avant de demander de l’aide. Utilisez ensuite la source pour contester une hypothèse précise, en gardant la question, l’emplacement consulté, l’aide reçue et les suggestions rejetées. Comparez le résultat assisté au calcul initial pour la même tâche et les mêmes entrées. Une explication plus courte ne démontre aucun progrès si elle perd une condition aux limites ou invente une observation.

Traitez le témoin structuré comme un cas distinct, sans modifier les entrées principales en place. Consignez changements et invariants, puis précisez si un écart relève du calcul, de l’interprétation ou des hypothèses. Conservez séparément chaque tentative échouée et sa correction. Le paquet prépare un critère pour chaque exercice corrigé ; chaque décision d’apprentissage reste null jusqu’à la conservation et la révision d’une tentative réelle. Consulter une source ou une réponse préparée ne prouve pas que l’apprenant a réalisé la tâche. Aucun nouveau DSL, flux d’agents, adaptateur de scène ni intégration en production n’est nécessaire pour cet exercice sur papier.

## Critère de réfutation annoncé

L’assimilation du coefficient de restitution à la fraction d’énergie cinétique conservée est réfutée lorsque le coefficient vaut `0.5` et la fraction `0.25`.

## Sources et périmètre de validation

- [Prérequis déjà commité: phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh](../../physics/en/phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh.md)

- [Source de projet conservée](../../../../code/blender/scripts/atlas/kit.py)

- [Lecture primaire](https://openstax.org/books/university-physics-volume-1/pages/9-4-types-of-collisions)

- [Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
