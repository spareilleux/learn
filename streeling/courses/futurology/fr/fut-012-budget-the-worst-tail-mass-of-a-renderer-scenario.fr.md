---
module_id: "fut-012-budget-the-worst-tail-mass-of-a-renderer-scenario"
department: "futurology"
course: "Budgéter la masse de queue défavorable d’un scénario de rendu"
level: "advanced"
prerequisites: ["fut-004-scenario-test-an-observatory-renderer", "dv-012-compute-quantiles-before-combining-latency-cohorts"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Budgéter la masse de queue défavorable d’un scénario de rendu

> Brouillon pour révision technique et linguistique. Le cas est construit, y compris ses entrées numériques, étiquettes et résultats attendus. Il ne constitue ni essai artisanal physique, ni observation [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), ni rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni exécution [ComfyUI](https://github.com/Comfy-Org/ComfyUI), ni résultat d’apprentissage. Toutes les décisions humaines et d’apprentissage restent indécises.

## Question du projet

Un futur moteur artisanal peut avoir une perte moyenne favorable et une issue rare très défavorable. Un quantile situe le début de la queue sans en décrire la gravité. Le prérequis traite déjà le regret maximal ; ce cours utilise une distribution déclarée pour moyenner exactement la masse de queue, y compris une fraction d’atome à la frontière.

Lisez le prérequis déjà commité et le passage de source conservé avant de calculer. Préparez une table distinguant définition de source, hypothèse construite, résultat dérivé et observation future proposée. La révision et le périmètre de lecture figurent dans le paquet. Un paramètre inspecté prouve que la représentation expose ce paramètre ; il ne fournit pas un coefficient matériel, un jugement de visibilité ou un temps de traitement non mesuré. Préservez cette distinction quand un assistant résume la source. La référence primaire ne soutient que le concept et le passage indiqués dans la fiche de lecture.

## Dériver l’opération avant de proposer une automatisation

Classez les pertes par gravité et remplissez la probabilité de queue en partant du pire. Si le dernier scénario dépasse la masse demandée, n’en prenez que la fraction nécessaire. Ce calcul diffère de la moyenne de tous les scénarios au-dessus du quantile ou égaux à lui. L’article primaire fournit la minimisation par partie positive et l’approximation finie ; notre construction pondérée est explicitement inventée. Le pipeline fournit des contrôles de capture, sans probabilités, étalonnage des pertes ni nouvelles observations de rendu.

## Modèle construit fixe et témoin à entrée modifiée

```json
{
  "values": {
    "losses_a": [
      1,
      2,
      3,
      20
    ],
    "probabilities": [
      0.4,
      0.3,
      0.2,
      0.1
    ],
    "losses_b": [
      4,
      4,
      4,
      4
    ],
    "alpha": 0.8
  },
  "formula": "mean=sum(p_i*loss_i); VaR=smallest loss with cumulative probability>=alpha; tail_mean=min_t(t+sum(p_i*max(loss_i-t,0))/(1-alpha)); integrate exactly the worst 1-alpha probability mass, splitting a cutoff atom; compare lower means and tail means",
  "expected": {
    "mean_a": 3.6,
    "mean_b": 4,
    "var_a": 3,
    "tail_a": 11.5,
    "tail_b": 4,
    "mean_choice": "A",
    "tail_choice": "B"
  },
  "negative_control": {
    "values": {
      "losses_a": [
        1,
        2,
        3,
        4
      ],
      "probabilities": [
        0.4,
        0.3,
        0.2,
        0.1
      ],
      "losses_b": [
        4,
        4,
        4,
        4
      ],
      "alpha": 0.8
    },
    "expected": {
      "mean_a": 2,
      "mean_b": 4,
      "var_a": 3,
      "tail_a": 3.5,
      "tail_b": 4,
      "mean_choice": "A",
      "tail_choice": "A"
    }
  }
}
```

### Exercice 1

Comparez les espérances de perte.

<details><summary>Réponse 1</summary>

Les moyennes valent `3.6` pour A et `4` pour B ; ce critère choisit `A`. Il s’agit de points de perte construits.

</details>

### Exercice 2

Trouvez le quantile et calculez la queue.

<details><summary>Réponse 2</summary>

Le quantile de A vaut `3`. La masse défavorable `0.2` contient une masse `0.1` à perte `20` et une masse `0.1` à perte `3`, soit une moyenne de `11.5`.

</details>

### Exercice 3

Comparez la décision fondée sur la queue.

<details><summary>Réponse 3</summary>

La moyenne de queue de B vaut `4` ; ce critère choisit donc `B`. Le désaccord vient des critères déclarés, pas d’une incohérence arithmétique.

</details>

### Exercice 4

Appliquez le témoin à perte extrême réduite.

<details><summary>Réponse 4</summary>

A a une moyenne de `2`, un quantile de `3` et une moyenne de queue de `3.5` ; les critères choisissent désormais `A`. Le quantile inchangé masque l’amélioration de queue.

</details>

### Exercice 5

Cela justifie-t-il une recommandation en production ?

<details><summary>Réponse 5</summary>

Non. Probabilités, pertes, horizon et stratégies admissibles exigent des preuves. Ce cas fini pose une question de planification plutôt qu’une prévision.

</details>

## Travail avec consultation des sources

Remplissez manuellement la queue sur une barre de probabilité en conservant l’atome fractionné. Inspectez les contrôles de capture et identifiez les preuves de scénario manquantes. Comparez moyenne, quantile et queue avant de proposer un planificateur.

Commencez par une référence manuelle directe : fermez les réponses, dessinez le schéma ou la table demandé et calculez les quantités intermédiaires avec leurs unités. Conservez cette première réponse avant de demander de l’aide. Utilisez ensuite la source pour contester une hypothèse précise, en gardant la question, l’emplacement consulté, l’aide reçue et les suggestions rejetées. Comparez le résultat assisté au calcul initial pour la même tâche et les mêmes entrées. Une explication plus courte ne démontre aucun progrès si elle perd une condition aux limites ou invente une observation.

Traitez le témoin structuré comme un cas distinct, sans modifier les entrées principales en place. Consignez changements et invariants, puis précisez si un écart relève du calcul, de l’interprétation ou des hypothèses. Conservez séparément chaque tentative échouée et sa correction. Le paquet prépare un critère pour chaque exercice corrigé ; chaque décision d’apprentissage reste null jusqu’à la conservation et la révision d’une tentative réelle. Consulter une source ou une réponse préparée ne prouve pas que l’apprenant a réalisé la tâche. Aucun nouveau DSL, flux d’agents, adaptateur de scène ni intégration en production n’est nécessaire pour cet exercice sur papier.

## Critère de réfutation annoncé

Le témoin conserve le quantile mais modifie la moyenne de queue : il réfute l’idée qu’un quantile inchangé implique une gravité de queue inchangée.

## Sources et périmètre de validation

- [Prérequis déjà commité: fut-004-scenario-test-an-observatory-renderer](../../futurology/en/fut-004-scenario-test-an-observatory-renderer.md)

- [Prérequis déjà commité: dv-012-compute-quantiles-before-combining-latency-cohorts](../../data-visualization/en/dv-012-compute-quantiles-before-combining-latency-cohorts.md)

- [Source de projet conservée](../../../../code/blender/scripts/glb_pipeline.py)

- [Lecture primaire](https://sites.math.washington.edu/~rtr/papers/rtr179-CVaR1.pdf)

- [Paquet construit fixe](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
