---
module_id: "dv-023-compress-signed-clearance-with-an-invertible-log-scale"
department: "data-visualization"
course: "Comprimer les jeux signés avec une échelle logarithmique inversible"
level: "advanced"
prerequisites: ["dv-014-plot-signed-craft-clearance"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Comprimer les jeux signés avec une échelle logarithmique inversible

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Un diagnostic artisanal dans [Godot](https://docs.godotengine.org/en/stable/classes/class_transform3d.html) peut contenir des chevauchements et des jeux d’amplitudes très différentes. Le logarithme ordinaire ne représente ni zéro ni les valeurs négatives. On construit ici un logarithme signé de la magnitude réduite augmentée de l’unité, avec son inverse. Ce n’est pas la transformation symlog par morceaux de Matplotlib. Des écarts visuels égaux ne sont pas des différences égales en millimètres. Gardez les valeurs brutes et l’échelle avec chaque point ; changer l’échelle déplace les points sans modifier la géométrie.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "clearance": [
      -3,
      -1,
      0,
      1,
      3
    ],
    "scale": 1
  },
  "formula": "y=sign(x)*log(1+abs(x)/scale), sign(0)=0; inverse=sign(y)*scale*(exp(abs(y))-1)",
  "expected": {
    "positions": [
      -1.3862943611198906,
      -0.6931471805599453,
      0,
      0.6931471805599453,
      1.3862943611198906
    ],
    "roundtrip": [
      -3,
      -1,
      0,
      1,
      3
    ]
  },
  "negative_control": {
    "values": {
      "clearance": [
        -3,
        -1,
        0,
        1,
        3
      ],
      "scale": 3
    },
    "expected": {
      "positions": [
        -0.6931471805599453,
        -0.28768207245178085,
        0,
        0.28768207245178085,
        0.6931471805599453
      ],
      "roundtrip": [
        -3,
        -1,
        0,
        1,
        3
      ]
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** Utilisez les entrées signées et une échelle positive ; conservez l’ordre et les unités.

</details>

### Exercice 2

Quelles valeurs signées l’inverse doit-il retrouver à partir des positions principales affichées ?

<details><summary>Réponse 2</summary>

> **Réponse:** Les positions affichées sont les résultats logarithmiques ; l’inverse retrouve `[-3,-1,0,1,3]` à la tolérance numérique près.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** Un jeu comprimé à l’écran n’est pas physiquement plus petit ; des pas visuels égaux n’impliquent pas des écarts bruts égaux.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** Le contrôle place les extrêmes vers `-0.6931471805599453` et `0.6931471805599453`, sans changer le retour aux valeurs brutes.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** Aucun essai de collision ou de perception n’a été réalisé ; séparez géométrie, unités et politique d’affichage.

</details>

## Tâche avec sources et référence manuelle directe

Dessinez les jeux signés d’une annotation de croisement Atlas, inversez la transformation puis comparez l’autre échelle.

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

- [Prérequis versionné: dv-014-plot-signed-craft-clearance](../../data-visualization/en/dv-014-plot-signed-craft-clearance.md)
- [Artefact local conservé](../../../../code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://docs.python.org/3/library/math.html)
- [Dossier du cas construit](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
