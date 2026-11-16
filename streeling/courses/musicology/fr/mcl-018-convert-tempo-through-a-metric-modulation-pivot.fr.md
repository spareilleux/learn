---
module_id: mcl-018-convert-tempo-through-a-metric-modulation-pivot
department: musicology
course: "Convertir le tempo par un pivot de modulation métrique"
level: advanced
prerequisites: ["mcl-006-preserve-meter-grouping-and-tempo-units"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Convertir le tempo par un pivot de modulation métrique

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Un guitariste reçoit un exercice avec une relation métrique et un nouveau tempo. Copier le nombre de pulsations précédent peut rompre la relation même si les symboles sont conservés. Nous déduisons le nouveau débit de noires d’un pivot de durée égale. L’opération relie deux coordonnées locales de tempo ; elle dépasse le simple choix d’unité d’un métronome.

Convertissez d’abord l’ancien pivot en secondes avec la durée de l’ancienne noire. Divisez ensuite cette durée par le nombre de nouvelles noires dans le pivot d’arrivée. Cet ordre rend visible le sens du rapport. Utiliser le rapport inverse ne conserverait pas la durée du pivot. Le cas fixe égalise une ancienne noire pointée et une nouvelle noire : la nouvelle noire dure donc davantage.

Le témoin identité utilise des pivots de même longueur et conserve le débit initial. Il détecte les formules qui changent le tempo dès qu’une relation métrique apparaît. L’élément MusicXML décrit la notation dans ce signe sans prouver son importation ou sa lecture par GA. Une comparaison réelle doit conserver les deux unités, le tempo source et les instants d’événements. L’égalité ne démontre ni accent culturel ni expressivité ni intention de direction. Une chaîne manuelle de durées suffit avant un DSL de modulation métrique.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../musicology/en/mcl-006-preserve-meter-grouping-and-tempo-units.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/music-phrase-2026-10-22/melody-constraints.json)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Lecture primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/metronome-note/)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "old_quarter_bpm": 120,
    "old_pivot_quarters": 1.5,
    "new_pivot_quarters": 1
  },
  "formula": "old_quarter_s=60/old_bpm; pivot_s=old_pivot*old_quarter_s; new_quarter_s=pivot_s/new_pivot; new_bpm=old_bpm*new_pivot/old_pivot",
  "expected": {
    "old_quarter_s": 0.5,
    "pivot_s": 0.75,
    "new_quarter_s": 0.75,
    "new_quarter_bpm": 80
  },
  "negative_control": {
    "values": {
      "old_quarter_bpm": 120,
      "old_pivot_quarters": 1.5,
      "new_pivot_quarters": 1.5
    },
    "expected": {
      "old_quarter_s": 0.5,
      "pivot_s": 0.75,
      "new_quarter_s": 0.5,
      "new_quarter_bpm": 120
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez une égalité instantanée exacte entre les durées des pivots. Chaque longueur utilise sa propre coordonnée de noire. Il n’y a ni rampe, ni expressivité mesurée, ni résultat d’importation exécutée.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Convertissez l’ancienne noire et le pivot en secondes.

<details><summary>Réponse 1</summary>

Utilisez d’abord le débit précédent, puis multipliez par la longueur du pivot en noires anciennes.

</details>

### Exercice 2

Dérivez la durée de la nouvelle noire.

<details><summary>Réponse 2</summary>

Divisez la durée commune du pivot par sa longueur en nouvelles noires.

</details>

### Exercice 3

Dans quel sens change le débit principal ?

<details><summary>Réponse 3</summary>

Il diminue : une nouvelle noire occupe la durée plus longue de l’ancienne noire pointée.

</details>

### Exercice 4

Que démontre le témoin identité ?

<details><summary>Réponse 4</summary>

Des pivots égaux conservent durée et débit de la noire selon cette règle.

</details>

### Exercice 5

Qu’est-ce qui réfute la modulation annoncée ?

<details><summary>Réponse 5</summary>

Si les durées des pivots en secondes diffèrent, l’égalité et le tempo calculé sont incompatibles.

</details>

## Travail avec consultation des sources

Préparez une note à deux horloges pour un import GA proposé. Conservez l’égalité exacte avant de choisir le tempo final.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
