---
module_id: wml-014-quantize-a-ratio-on-a-declared-octave-division
department: world-music-languages
course: "Quantifier un rapport sur une division déclarée de l’octave"
level: advanced
prerequisites: ["wml-004-preserve-intonation-beyond-pitch-classes"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Quantifier un rapport sur une division déclarée de l’octave

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Un pas entier n’a pas de taille musicale fixe sans division de l’octave. Un transfert de gamme [GA](https://github.com/GuitarAlchemist/ga) qui garde le nombre et perd la grille peut changer l’intervalle voulu. Nous approchons un rapport construit sur des divisions égales et conservons le résidu. La cible, sa représentation et l’erreur restent des grandeurs distinctes.

## Lire les éléments conservés

La source principale définit les cents par un rapport multiplicatif. Le relevé conservé montre déjà une projection discrète effaçant un écart. Ce cours rend la grille d’arrivée variable, sans l’attribuer à une culture ni annoncer sa prise en charge par le moteur.

[Prérequis](../../world-music-languages/en/wml-004-preserve-intonation-beyond-pitch-classes.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lecture principale](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "target_ratio": 1.25,
    "octave_divisions": 19
  },
  "formula": "target_cents=1200*log2(ratio); step=floor(divisions*log2(ratio)+0.5); represented_cents=1200*step/divisions; error_cents=represented_cents-target_cents",
  "expected": {
    "target_cents": 386.3137138648348,
    "step": 6,
    "represented_cents": 378.94736842105266,
    "error_cents": -7.366345443782166
  },
  "negative_control": {
    "values": {
      "target_ratio": 1.25,
      "octave_divisions": 12
    },
    "expected": {
      "target_cents": 386.3137138648348,
      "step": 4,
      "represented_cents": 400,
      "error_cents": 13.686286135165204
    }
  }
}
```

## Séparer approximation et interprétation culturelle

Une division égale de l’octave est une construction mathématique. Son nombre de pas n’identifie à lui seul ni tradition, ni répertoire, ni intonation d’un interprète. Une grille peut bien approcher un rapport choisi et mal représenter d’autres intervalles importants. La choisir sur un petit écart exige donc un objectif déclaré, sans supériorité universelle annoncée.

Le résidu signé sert aussi à indiquer la direction séparant représentation et rapport demandé. Une erreur absolue seule masquerait cette direction. Inversement, conserver le seul résidu sans rapport ni grille ne suffirait pas : le récepteur doit connaître la référence à laquelle s’applique la correction. Gardez ces champs comme grandeurs construites distinctes.

La frontière discrète du catalogue montre pourquoi un relevé consultatif n’est pas une fonction d’exécution prise en charge. Pouvoir stocker un identifiant de grille diffère de pouvoir réaliser ses fréquences sur un instrument. Un manche tempéré ordinaire peut demander une autre technique ou un autre instrument ; une entrée logicielle exige encore une mesure de sortie. La table manuelle suffit à montrer la perte avant de proposer un DSL d’accordage. Une implémentation plus riche ne se justifie qu’après définition de l’usage musical et des exigences mesurables de conservation.

### Exercice 1

Convertissez le rapport cible en cents. La grille d’arrivée modifie-t-elle cette cible ?

<details><summary>Réponse 1</summary>

La valeur cible reste identique dans les cas. Elle décrit le rapport demandé avant quantification, indépendamment de la grille choisie.

</details>

### Exercice 2

Choisissez le pas le plus proche sur la grille principale. Quelle convention intervient en cas d’égalité ?

<details><summary>Réponse 2</summary>

Utilisez le pas affiché. La règle construite arrondit les égalités vers le haut ; même sans égalité ici, elle appartient à un transfert reproductible.

</details>

### Exercice 3

Calculez l’intervalle représenté et l’erreur signée. Que signifie un résidu négatif ?

<details><summary>Réponse 3</summary>

L’intervalle représenté est inférieur à la cible. Le résidu mesure une approximation sur cette grille, et non un guitariste observé jouant trop bas.

</details>

### Exercice 4

Appliquez le témoin sur l’autre grille. Quelles valeurs doivent changer ?

<details><summary>Réponse 4</summary>

Le pas, les cents représentés et le résidu changent ; la cible reste fixe. Comparer les entiers bruts entre grilles mélangerait des unités incompatibles.

</details>

### Exercice 5

Qu’est-ce qui réfute un transfert annoncé fidèle au rapport exact ?

<details><summary>Réponse 5</summary>

Remplacer la cible par le seul pas approché efface son résidu non nul. Conservez rapport et grille ; la pertinence musicale demande encore des preuves et un jugement humains adaptés à la tradition.

</details>

## Travail avec consultation des sources

Construisez la table cible/grille/erreur à la main avant assistance. Examinez la projection conservée, puis proposez un relevé gardant rapport et identité de grille. Rejetez une exactitude annoncée si le résidu disparaît ; l’interprétation culturelle et le support d’accordage restent indécidés.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
