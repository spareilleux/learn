---
title: Vérifier le contraste d’une annotation avec la luminance linéaire
description: Vérifier le contraste d’une annotation avec la luminance linéaire — Visualisation de données
sidebar:
  label: DV-025 · Vérifier le contraste d’une annotation avec la luminance linéaire
  order: 25
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/fr/dv-025-check-overlay-contrast-from-linear-luminance.fr.md
---

:::note[Streeling University]
**DV-025** · Vérifier le contraste d’une annotation avec la luminance linéaire · avancé · 50 minutes

Généré par le département *Visualisation de données* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/fr/dv-025-check-overlay-contrast-from-linear-luminance.fr.md) · [Mon journal](../../journal/)

Prérequis: [DV-006](../../data-visualization/dv-006-position-length-area-comparisons/), [VC-001](../../visual-computing/vc-001-accessible-fretboard-paths/)
:::

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Une annotation de broderie proposée dans [Godot](https://docs.godotengine.org/en/stable/classes/class_transform3d.html) paraît claire sur une capture, mais cette impression ne fournit pas un calcul de contraste. À partir de luminances relatives déjà linéaires, appliquez le rapport [WCAG](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) et le seuil de texte déclaré. La valeur la plus claire va au numérateur, quelle que soit son étiquette premier plan ou arrière-plan. Les canaux RGB encodés ne sont pas ces luminances. Le calcul vérifie uniquement la paire opaque indiquée ; il ne certifie ni une scène rendue ni toute son accessibilité.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "foreground_luminance": 0.2,
    "background_luminance": 1,
    "threshold": 4.5
  },
  "formula": "ratio=(max(foreground_luminance,background_luminance)+0.05)/(min(foreground_luminance,background_luminance)+0.05); passes=ratio>=threshold",
  "expected": {
    "ratio": 4.2,
    "passes": false
  },
  "negative_control": {
    "values": {
      "foreground_luminance": 0.1,
      "background_luminance": 1,
      "threshold": 4.5
    },
    "expected": {
      "ratio": 7,
      "passes": true
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** Les entrées sont des luminances relatives linéaires et un seuil explicite, pas des octets RGB.

</details>

### Exercice 2

Calculez le rapport de contraste et la décision au seuil déclaré.

<details><summary>Réponse 2</summary>

> **Réponse:** Le rapport vaut `4.2`, inférieur à `4.5` ; la paire indiquée échoue à ce critère.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** Une impression visuelle ou un test clavier ne remplace pas le calcul sur les luminances indiquées.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** Le premier plan modifié donne un rapport de `7` et franchit le même seuil.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** La composition rendue, les variations du fond et les autres critères d’accessibilité exigent des observations distinctes.

</details>

## Tâche avec sources et référence manuelle directe

Préparez une note de couleurs opaques pour une annotation Atlas avec les luminances linéaires fournies.

En masquant les réponses, dessinez un tableau ou un schéma propre à l’opération, puis calculez le résultat principal à la main. Cette première tentative conservée constitue la référence manuelle directe. Indiquez les entrées, les intermédiaires, la règle de chaque étape et la raison de tout refus ou résultat indéterminé. Énoncez le critère de réfutation avant de demander à un assistant de simplifier le travail. Un tableau ordinaire peut suffire au projet ; un DSL composable ou un nœud agentique doit apporter un bénéfice supplémentaire démontré.

Consultez ensuite l’artefact local et le passage primaire liés. Notez l’emplacement, la révision, la définition utilisée et ce qu’elle ne permet pas d’établir. Demandez à un assistant de contester une hypothèse et conservez la question et sa réponse. Déclarez comme aide tout usage de calculatrice, de traduction ou de recherche documentaire. Comparez le résultat aidé à la référence initiale avec les mêmes entrées. Rejetez une explication plus courte si elle supprime une identité, une condition ou la distinction entre exemple construit et observation du projet.

Traitez le contrôle négatif comme un enregistrement séparé. Prédisez son résultat avant de lire la correction, puis comparez les champs modifiés et les invariants. En cas de désaccord, distinguez erreur de calcul, erreur de sens et limite des hypothèses. Conservez l’échec, son diagnostic, sa correction et sa reprise ; n’effacez pas la première tentative. Remettez ces traces avec l’explication documentée et les incertitudes restantes. Cette petite boucle d’amélioration pourra servir au dogfooding, mais aucune amélioration réelle d’apprentissage ou d’exécution n’a été mesurée ici.

Le dossier prépare un critère par exercice sans remplir les décisions pédagogiques. La réponse réelle, l’historique d’aide, la correction personnelle et la décision restent vides tant qu’aucune tentative n’existe. Revue technique, revue linguistique, exécution dans le moteur, validation matérielle, adoption et publication nécessitent des preuves distinctes. Le calcul fini n’établit que la relation annoncée sous ses hypothèses. Avant de l’utiliser dans une scène ou un outil de pratique, précisez l’observation supplémentaire et son seuil de rejet ; un corrigé préparé ne vaut pas acceptation.

## Critère prospectif de réfutation

Une réponse proposée est rejetée si l’application de l’opération affichée à une entrée conservée contredit le résultat attendu, ou si son explication présente ce cas construit comme une observation déjà réalisée dans le projet.

## Critères préparés pour l’apprenant

- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 1, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 2, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 3, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 4, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 5, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.

## Sources et portée des affirmations

- [Prérequis versionné: dv-006-position-length-area-comparisons](../../data-visualization/dv-006-position-length-area-comparisons/)
- [Prérequis versionné: vc-001-accessible-fretboard-paths](../../visual-computing/vc-001-accessible-fretboard-paths/)
- [Artefact local conservé](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
- [Dossier du cas construit](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
