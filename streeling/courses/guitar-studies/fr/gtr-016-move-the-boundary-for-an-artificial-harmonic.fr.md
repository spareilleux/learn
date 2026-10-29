---
module_id: gtr-016-move-the-boundary-for-an-artificial-harmonic
department: guitar-studies
course: "Déplacer la limite pour une harmonique artificielle"
level: advanced
prerequisites: ["gtr-012-select-natural-harmonics-with-a-touch-node"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Déplacer la limite pour une harmonique artificielle

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

La position d’une harmonique naturelle ne peut pas rester fixe quand la main crée une nouvelle extrémité vibrante. Une consigne d’harmonique artificielle doit distinguer la note frettée de base, le point de toucher et le son obtenu. Ce cours traduit cette distinction en géométrie relative au chevalet pour un futur schéma [GA](https://github.com/GuitarAlchemist/ga).

## Lire les éléments conservés

La référence de notation distingue harmoniques naturelles et artificielles ainsi que les rôles des hauteurs. La lecture sur les ondes stationnaires justifie les nœuds idéaux. Nous ajoutons une coordonnée explicite ; le champ de fréquence conservé ne simule pas les contacts des doigts.

[Prérequis](../../guitar-studies/en/gtr-012-select-natural-harmonics-with-a-touch-node.md)

[Artefact du projet conservé](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lecture principale](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/harmonic/)

[Lecture principale](https://www.phys.unsw.edu.au/jw/strings.html)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "open_hz": 110,
    "fretted_semitones": 7,
    "touch_mode": 2,
    "fixed_absolute_touch_fraction": 0.5
  },
  "formula": "vibrating_fraction=2^(-fret/12); base_hz=open*2^(fret/12); touch_fraction_from_bridge=vibrating_fraction/mode; sounding_hz=mode*base_hz; fixed_touch_local=fixed_absolute_touch_fraction/vibrating_fraction",
  "expected": {
    "vibrating_fraction": 0.6674199270850172,
    "base_hz": 164.81377845643496,
    "touch_fraction_from_bridge": 0.3337099635425086,
    "sounding_hz": 329.6275569128699,
    "fixed_touch_local": 0.7491535384383408
  },
  "negative_control": {
    "values": {
      "open_hz": 110,
      "fretted_semitones": 0,
      "touch_mode": 2,
      "fixed_absolute_touch_fraction": 0.5
    },
    "expected": {
      "vibrating_fraction": 1,
      "base_hz": 110,
      "touch_fraction_from_bridge": 0.5,
      "sounding_hz": 220,
      "fixed_touch_local": 0.5
    }
  }
}
```

## Séparer position physique et rôles de notation

Le contact qui arrête fermement la corde et celui qui sélectionne légèrement un nœud n’ont pas le même rôle. Leur relation géométrique change quand le contact ferme se déplace. Un schéma donnant seulement une distance de case sans nommer le contact peut donc être ambigu, même avec une note sonore correcte. Gardez l’action et l’origine du repère près de chaque position.

La loi de longueur choisie suppose que le frettage modifie la partie vibrante sans changer la célérité. Un contact réel peut aussi modifier tension et amortissement. Ces effets changeraient la prévision fréquentielle, mais ne justifient pas de reprendre le milieu de la corde entière. Géométrie et approximations acoustiques sont des affirmations distinctes à examiner séparément.

Le vocabulaire de notation est utile parce que hauteur de base, hauteur de toucher et hauteur sonore ne sont pas interchangeables. Ce cas ne prescrit pas une notation universelle du toucher et ne prouve pas son exécution par un lecteur. Un dessin manuel indiquant longueur restante et mode voulu suffit à détecter l’erreur d’origine fixe. Avant de générer des schémas, vérifiez la conservation des relations pour différentes notes frettées, puis recueillez des preuves réelles de contact et de son auprès d’un musicien. Une arithmétique correcte ne garantit pas une position accessible.

### Exercice 1

Calculez la fraction vibrante après frettage. Quelle extrémité reste fixe dans le repère ?

<details><summary>Réponse 1</summary>

La fraction figure ci-dessus et le chevalet reste l’origine. L’extrémité frettée se déplace ; une fraction de la corde initiale n’est pas automatiquement une fraction du segment restant.

</details>

### Exercice 2

Placez le nouveau toucher au milieu et calculez la fréquence de base frettée.

<details><summary>Réponse 2</summary>

Utilisez les résultats principaux. Le toucher est au milieu du segment restant, et la fréquence de base suit la loi de longueur tempérée déclarée.

</details>

### Exercice 3

Donnez la fréquence sonore et distinguez-la des rôles de base et de toucher.

<details><summary>Réponse 3</summary>

La fréquence sonore est le mode choisi multiplié par la fréquence de base. Une position de toucher ou un rôle de hauteur notée ne remplace pas la fréquence du son obtenu.

</details>

### Exercice 4

Appliquez le témoin à vide. Pourquoi détecte-t-il mal une position fixe erronée ?

<details><summary>Réponse 4</summary>

Le segment restant est la corde entière : les constructions du milieu coïncident. Le cas fretté les sépare, puisque le toucher fixe a alors une autre coordonnée locale.

</details>

### Exercice 5

Qu’est-ce qui réfute un schéma conservant le même milieu pour toutes les cases ?

<details><summary>Réponse 5</summary>

Une distance au chevalet qui ne suit pas la longueur restante réfute cette géométrie. L’excitation propre et la technique du guitariste demandent toujours un essai réel.

</details>

## Travail avec consultation des sources

Dessinez les segments à vide et fretté, calculez les positions à la main et repérez les rôles de hauteur dans la notation. Proposez une consigne préservant la relation à la limite mobile. Le milieu initial fixe sert de témoin de réfutation, sans résultat joué revendiqué.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
